# R0b vendor 防护链泄露面扫描结果（r0b-vendor-surface-20261116）

- 日期：2026-11-16
- 执行环境：WSL Ubuntu-22.04.5，Python 3.13.12（标准库，无三方依赖）
- 扫描器：`scripts/scan_vendor_leak_surface.py`（SHA-256 `3779db16e28b1916b669288a46eecd05fb09d5372182dfdfce1d5eb7ae378fe8`）
- 固定清单：本目录 `scan-config.json`（5 棵 vendor 树 / 22 个文件；不扫全树；SHA-256 `1efd8ba9ef940fb431fe929773102365c2033152c85f0244f645cab5747edf8d`）
- 规则（逐行正则，任务书 §4 T2.1 原文）：`abort\s*\(|assert\s*\(|fprintf\s*\(|printf\s*\(|perror\s*\(|errno|exit\s*\(`
- 取件校验：`sh tools/fetch_all_vendors.sh` 四棵 vendor 树摘要全部与脚本钉版一致（尾部输出见
  `docs/research/phase2-session-20261116/SESSION.md`）

## 1. 官方扫描结果

```sh
cd ~/cryProject-work
python3 scripts/scan_vendor_leak_surface.py \
    --config docs/evidence/r0b-vendor-surface-20261116/scan-config.json
```

```text
vendor surface scan: files=22 lines=6298 hits=0
  ... 22 个文件逐项 0 ...
outputs: docs/evidence/r0b-vendor-surface-20261116/HITS.md
         docs/evidence/r0b-vendor-surface-20261116/hits.json
```

- 清单 **22 个文件、6298 行，命中 0 行**；`HITS.md` 的范围/摘要表完整，逐行命中表为空（如实记录）。
- 独立交叉核对：对同一 22 个文件用 `grep -c -E` 统计同一 ERE，逐文件全部为 **0**
  （命令见 §3），与 `hits.json` 的 `hit_count=0` 一致。
- 口径结论：固定清单内的 vendor 防护链文件（pq-crystals/liboqs 的 poly/indcpa/kem/verify/fips202
  与 mlkem-native 的 verify/kem/fips202）没有 abort/assert/日志/errno/exit 文本面。
  该结论**只覆盖清单内文件**，不外推到上游其它文件，也不是恒时或"零泄露"证明。

产物摘要：

| 文件 | 说明 | SHA-256 |
|---|---|---|
| `scan-config.json` | 固定扫描清单（本次固化） | `1efd8ba9ef940fb431fe929773102365c2033152c85f0244f645cab5747edf8d` |
| `HITS.md` | 范围/摘要 + 逐行命中表（0 行） | `48dda07af93c2517903e80ebb3ba65085a34511d9862aa8a58bcbd8e4540f97c` |
| `hits.json` | 机器可读命中与逐文件摘要（0 条） | `7efe1a9dfe59feb7ab38679062876878714060091e380dd61e431d25873ca766` |

## 2. 人工抽查与扫描器正对照（因官方命中为 0）

官方清单命中 0 行，无法直接做"命中行抽查 10 行"；为避免"0 命中"掩盖扫描器失效，
用**仅存在于 `build/`（gitignored，不提交）**的临时正对照配置验证同一规则与函数名提取：

- 临时配置在清单中只放 `vendor/kyber-kyberslash-fixed/ref/randombytes.c`
  （该文件含已知 `abort()` 与 `errno`，但**不在**任务书固定清单内，故不计入官方结果）。
- 命令：

```sh
python3 scripts/scan_vendor_leak_surface.py \
    --config build/r0b-selftest/config.json --output-dir build/r0b-selftest/out
```

```text
vendor surface scan: files=1 lines=80 hits=10
  vendor/kyber-kyberslash-fixed/ref/randombytes.c: 10
```

- 用 `sed -n '11p;27p;32p;39p;47p;50p;63p;66p;71p;74p' ...randombytes.c` 逐行核对，
  10/10 行文本与 `hits.json` 的 `text` 字段逐字一致，函数名提取正确（命中位于
  `randombytes()` 内；`#include <errno.h>` 行按 `(file_scope)` 登记）。
- 结论：扫描器计数与函数定位可用；官方清单的 0 命中是清单元数据的真实结果，不是工具漏扫。

## 3. 独立交叉核对命令

对固定清单 22 个文件逐个执行（片段）：

```sh
grep -c -E 'abort[[:space:]]*\(|assert[[:space:]]*\(|fprintf[[:space:]]*\(|printf[[:space:]]*\(|perror[[:space:]]*\(|errno|exit[[:space:]]*\(' \
    vendor/liboqs-0.10.0/src/kem/ml_kem/pqcrystals-kyber-standard_ml-kem-768-ipd_ref/{poly,indcpa,kem,verify}.c \
    vendor/liboqs-0.10.0-982c762/src/kem/ml_kem/pqcrystals-kyber-standard_ml-kem-768-ipd_ref/{poly,indcpa,kem,verify}.c \
    vendor/kyber-kyberslash-unfixed/ref/{poly,indcpa,kem,verify,fips202}.c \
    vendor/kyber-kyberslash-fixed/ref/{poly,indcpa,kem,verify,fips202}.c \
    vendor/mlkem-native/mlkem/src/{verify.h,verify.c,kem.c,fips202/fips202.c}
```

全部 22 项输出 `0`。

## 4. 边界

- 扫描器按任务书写死规则**逐行正则**命中，不剥离注释/字符串再分类；是否构成泄露须人工复核，
  本目录不做自动定性。
- 不扫全树、不扫 `src/`/`tools/`/`tests/` 自有实现（R06 另有审计）；不修改 vendor 任何文件。
- 本目录为软件侧扫描证据，不进入 Holm 家族、不改任何既有判定，也不构成计时或防护因果结论。
