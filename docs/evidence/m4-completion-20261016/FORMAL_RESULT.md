# M4 有界形式验证实跑结果（formal-v2）

本文件记录 **本轮真实执行** 的 Binsec `-sse -checkct` 结果。全部工具在 Cry 内新根重新安装（逐件 sha256 校验），全部分析在新根重新实跑；
`formal-v1/` 原字节不动，新原件在 `formal-v2/`。本文件只给有界结论，不外推到完整 KEM、任意长度或硬件恒时。

## 0. 结论速览

| # | 运行 | 内核 | 长度模型 | 判定 | 依据 |
|---|---|---|---|---|---|
| 1 | `vulnerable-1-16` | 提前退出 `compare_early.c` | `0 < m4_public_length < 17` | **insecure** | 反例：`0x8049047` 控制流泄漏，模型见 §4 |
| 2 | `ct-1-16` | 归约 `compare_ct.c` | `0 < m4_public_length < 17` | **secure（有界）** | 完整探索 16/16 路径，无 pending / 截断 / solver unknown |
| 3 | `vulnerable-fixed16` | 提前退出 | `m4_public_length = 16` | **insecure** | 反例：同一地址 `0x8049047` |
| 4 | `ct-fixed16` | 归约 | `m4_public_length = 16` | **secure（有界）** | 完整探索 1/1 路径，无 pending / 截断 / solver unknown |

四次主/补运行都自然完成，**没有任何一次落入 unknown / 截断**。另做一次**故意截断对照**（§6.4）：把 `-sse-depth` 降到 5，Binsec 报 `unknown`，
证明该流水线能区分「完整探索的 secure」与「截断的 unknown」，本轮的 secure 不是截断静默造成的。

> 退出码陷阱：四次主运行和那次截断对照**进程退出码都是 0**。所以本条结论不依赖退出码，而依赖 §5 的完整探索闸门。

## 1. 工具实际版本与安装

新根：`/home/nss-marker/yhr/Cry/platform-m4-binsec-20261016-73f14add5392`（旧根 `platform-m4-20261016-6hRHRUxH` 未改动、未覆盖）。

| 组件 | 实际版本 | sha256 | 安装方式 |
|---|---|---|---|
| opam | 2.6.1 | `b533d393a6967150d6ef41cb3d71e147e93ecbabeb59e921aa412c0ae79ebe3d` | `install_binsec.sh` 下载并校验（钉版） |
| OCaml switch | 4.14.3 | — | `opam switch create . ocaml-base-compiler.4.14.3` |
| Binsec | `Binsec version 0.11.3` | `8b11a6f8054b96f97e2ba4697952c88eef20094933889591cb3f18c2a73b1279` | 由钉版 `binsec-0.11.3.tbz`（`93f6fe43…`）在新根编译安装 |
| Z3 | `Z3 version 4.15.3 - 64 bit` | `80ee070b8ffc2fa964b0b879250b2110c47f84c1256a1f9ab76fc7cf95e46292` | 钉版 `z3-4.15.3-x64-glibc-2.39.zip`（`94549c5e…`）解包 |
| 编译器 | gcc 13.3.0 | — | 系统（Ubuntu 24.04，x86_64，Ryzen 9 9950X） |

安装使用仓库脚本 `tools/platform_m4/install_binsec.sh`（未修改，脚本内 5 件 sha256 校验全过），未使用 sudo、未用系统包、未绕过校验。
复用情况如实记录：5 件钉版下载复用旧根同 URL 同版本的下载缓存、opam 源包复用旧根 `opam/download-cache`（只为省时），
两者**仍然逐件通过脚本内 sha256 校验**；`OPAMROOT`、`TMPDIR`、`XDG_CACHE_HOME`、`CURL_HOME`、opam switch 与全部产物都落在**新根内**，
旧根只读不改。原件：

- 完整安装日志 [install-run.log](formal-v2/identity/install-run.log)（含 Binsec 编译与末尾 `binsec -version` / `z3 --version` / sha256）
- [versions.txt](formal-v2/identity/versions.txt)、[opam-installed.txt](formal-v2/identity/opam-installed.txt)、[binsec-switch.export](formal-v2/identity/binsec-switch.export)
- 环境与全部源码摘要 [environment-and-source-sha256.txt](formal-v2/identity/environment-and-source-sha256.txt)

说明：Binsec 是源码重建，其二进制 sha256 与旧根不同（OCaml 产物内嵌构建路径），Z3 是同一预编译产物、sha256 与旧根一致。
两者版本串一致。判定依据是**版本串 + 二进制 sha256 + 本次实跑日志**，不是与旧根比 hash。

## 2. 被分析产物与源码身份

同一 harness（`tools/platform_m4/binsec_harness.c`）分别链接两个内核，用仓库自己的 CMake（`cmake/PlatformM4.cmake`）构建：

```
cmake -S <root>/source/tools/platform_m4 -B <root>/build-formal -DBUILD_TESTING=OFF -DCMAKE_BUILD_TYPE=RelWithDebInfo
cmake --build <root>/build-formal --target platform_m4_formal_vulnerable platform_m4_formal_ct
```

| 产物 | 说明 | sha256 | BuildID |
|---|---|---|---|
| `platform_m4_formal_vulnerable` | i386、`-O1 -g -ffreestanding -fno-pie -fno-stack-protector -fno-builtin`，`-nostdlib -no-pie -Wl,-e,m4_entry`，含调试信息 | `c06425dab680a5b57cd058f83e73cba9ba5b42bafc709272003d98eca81dde90` | `6db2092d…` |
| `platform_m4_formal_ct` | 同上 | `c2bd25b740d8c04e5bf12c9fa083466f00af4ad7d0bf906b6e6e032b6e0d9472` | `d5e19c37…` |

源码身份：仓库 `main`。**提取源码子集时** HEAD = `47033dd864cab5544d2d2cc82d1ed0cf03b30f83`；此后 main 前进到
`a3c9ca1e6f9b9dedc45545e4ce2f0f1a01b8aa65`（另一路控制器提交，与 M4 路径无关）。
核对：`git log 47033dd..a3c9ca1 -- tools/platform_m4 fixtures/early_reject_memcmp cmake/PlatformM4.cmake` 输出为空，
且上表 sha256 在 a3c9ca1 工作树上复算一致 —— 本轮分析对应的源码在提交前后未变。上传的源码子集 tar sha256 `16a0f6d1387fc4278e7f8bb0489cc3e567c4f32524cd09c6269da7c4c564c56b`
（[m4-source-subset.tar.gz](formal-v2/identity/m4-source-subset.tar.gz)）。关键文件 sha256：

| 文件 | sha256 |
|---|---|
| `tools/platform_m4/binsec_harness.c`（正式目标真正使用的 harness） | `3040ae805c8a5d4641c22edbe2bd1bd331265ac4e5f0a790b5bf537a45b0f144` |
| `fixtures/early_reject_memcmp/compare_early.c` | `36637faafef6fdd2a121c8c292c263c40e59f776eda375367e5808264154d2cb` |
| `fixtures/early_reject_memcmp/compare_ct.c` | `a2cbce6fca0d38d99002aa6cc5bbdf4ccc19716c08e747ac821c92b6c278d8e6` |
| `tools/platform_m4/checkct_1_16.cfg` | `ed11c9391bedf3ad07ca94277109f47d55de8873ff9400bcc8c709be0ee38f2f` |
| `tools/platform_m4/checkct_fixed16.cfg` | `291fc6e627b97eed8f420277f5e31a77e16b204ff1b1b893e635f6831d5b8e6e` |
| `tools/platform_m4/run_checkct.sh` | `0a5fb45eae4f3fb2e8721669de4c86cc2190f2156c359f287615ca72ca24708e` |

上传后逐件复算，与本地工作树一致（见 §1 的环境摘要）。正式目标用的是 `tools/platform_m4/binsec_harness.c`；
`fixtures/early_reject_memcmp/binsec_harness.c` 是夹具自带的另一份（`090ecd93…`），**不参与**本轮形式目标，避免混淆。

## 3. 形式模型与命令行（bound）

**入口/终点：** 入口符号 `m4_entry`（`-Wl,-e,m4_entry`），分析在 `<m4_halt>` 入口结束；`m4_halt` 只把比较结果写进全局并 `__builtin_trap()`，
即**允许比较返回值公开**，分析在消费该值之前停止。

**秘密 / 公开模型（两次运行相同，仅长度约束不同）：**

```
secret global m4_secret_input                 # 16 字节全秘密
public global m4_public_input, m4_public_length
with concrete stack pointer
explore all
halt at <m4_halt>
```

- `vulnerable-1-16` / `ct-1-16`：`assume 0 < m4_public_length < 17`
- `vulnerable-fixed16` / `ct-fixed16`：`assume m4_public_length = 16`

**分析参数（`run_checkct.sh` 固定，未改）：**

```
binsec -sse -checkct -smt-solver z3 -sse-script <cfg> \
       -sse-depth 10000 -sse-timeout 120 -smt-timeout 5 \
       -checkct-features control-flow,memory-access \
       -checkct-stats-file checkct.toml <elf>
```

- 亲和性 `taskset -c 0,1`；墙钟上限 180 秒（`timeout --signal=TERM --kill-after=15`）。
- `sse-depth` 上限 10000、单查询 `smt-timeout` 5 秒、整段分析 `sse-timeout` 120 秒。
- 未设置 `-checkct-no-cv` / `-checkct-no-relse` / `-checkct-no-taint`，即**默认三件套全开**：chosen-value sampling、关系符号引擎、污点分析。
- `-checkct-leak-info` 用默认 `instr`（泄漏指令只报一次）。
- `-checkct-features` 只开 `control-flow,memory-access`；**未开** multiplication / dividend / divisor（Binsec 标注 experimental）。

## 4. 两次主运行的原日志与退出码

### 4.1 `vulnerable-1-16`（提前退出内核，长度 1–16）

```
[checkct:result] Instruction 0x8049047 has control flow leak (0.033s)
[checkct:result] Program status is : insecure (0.207)
[checkct:info] 32 visited paths covering 32 instructions
[checkct:info] 49 / 50 control flow checks pass
[checkct:info] 235 / 235 memory access checks pass
```

- 退出码 `0`；墙钟 `0.246 s`（`status.txt` / `elapsed.txt`）；`stderr` 0 字节。
- SMT：预处理 65 全 sat；可满足性查询 **total 35 / sat 33 / unsat 2 / unknown 0**。
- 探索：total paths 32，completed/cut 32，**pending 0 / discontinued 0**，failed assertions 0，max path depth 134，unrolled 335，static 32。
- TOML：`insecure = ["0x8049047"]`，`unknown = []`；`paths.completed.halt = 32`，`cut = 0`，`assertion_failure = 0`，
  `discontinued` 五项（`enumeration_limit`/`error`/`max_depth`/`non_executable_code`/`unresolved_formula`）**全 0**；`time = 0.206979036331`。

**反例（原文见 [checkct.toml](formal-v2/vulnerable-1-16/checkct.toml)）：**

| 量 | 值 |
|---|---|
| 泄漏指令 | `0x8049047`（`compare_early.c:9` 的提前返回分支） |
| `m4_public_length` | `0x00000010`（= 16） |
| `m4_public_input` | `0x00000000000000000000000000000000`（16 字节全 0） |
| `m4_secret_input`（secret1） | `0x000000000000000000000000000000ff` → 小端即 `byte[0] = 0xff`，其余 0 |
| `m4_secret_input`（secret2） | `0x00000000000000000000000000000000`（全 0） |
| 公开模型附带寄存器 | `ebx = 0x1a1a87fa`、`esi = 0x0d2edbc1` |

语义：同一公开输入下，`secret1[0] != public[0]` 走提前返回，`secret2 == public` 走完整循环 —— 两条执行在 `0x8049047` 分流，故为控制流泄漏。

### 4.2 `ct-1-16`（归约内核，长度 1–16）

```
[checkct:result] Program status is : secure (0.092)
[checkct:info] 16 visited paths covering 36 instructions
[checkct:info] 33 / 33 control flow checks pass
[checkct:info] 141 / 141 memory access checks pass
```

- 退出码 `0`；墙钟 `0.137 s`；`stderr` 0 字节。
- SMT：预处理 33 全 sat；可满足性查询 **total 18 / sat 16 / unsat 2 / unknown 0**。
- 探索：total paths 16，completed/cut 16，**pending 0 / discontinued 0**，max path depth 139，unrolled 289，static 36。
- TOML：`insecure = []`，`unknown = []`；`paths.completed.halt = 16`，`cut = 0`；`discontinued` 五项全 0；`time = 0.091845035553`。

原日志：[vulnerable-1-16](formal-v2/vulnerable-1-16/stdout.txt)、[ct-1-16](formal-v2/ct-1-16/stdout.txt)、
[status](formal-v2/vulnerable-1-16/status.txt)、[TOML](formal-v2/ct-1-16/checkct.toml)、[model.cfg](formal-v2/vulnerable-1-16/model.cfg)、
[disasm](formal-v2/vulnerable-1-16/disasm.txt)、[identity](formal-v2/vulnerable-1-16/identity.txt)、每次目录内另有 `key-facts.txt` 汇总。

### 4.3 补充第二 bound（固定长度 16）

| 运行 | 判定 | 控制流检查 | 访存检查 | 路径 / 到达 halt | pending | discontinued | SMT total/sat/unsat/unknown | max depth | 退出码 | 墙钟 |
|---|---|---|---|---|---|---|---|---|---|---|
| `vulnerable-fixed16` | **insecure** `0x8049047` | 34/35 | 175/175 | 17 / 17 | 0 | 全 0 | 18/18/0/0 | 134 | 0 | 0.134 s |
| `ct-fixed16` | **secure** | 18/18 | 51/51 | 1 / 1 | 0 | 全 0 | 1/1/0/0 | 139 | 0 | 0.062 s |

固定长度下 `vulnerable` 得 17 条路径（在 index 0…15 各提前退出一次 + 走完整循环一次），与 `length+1` 一致；
`ct` 只剩 1 条路径，说明该内核没有数据相关分支。这两次是本轮补充，主合同仍是 §4.1/§4.2 的 1–16 模型。

## 5. 三分类判据（本轮实际使用的规则）

1. **insecure**：Binsec 打出 `[checkct:result] Program status is : insecure`，且 TOML 的 `"Insecurity models"` 给出可复算的公开/两个秘密取值，
   且 `Instructions status.insecure` 非空。→ §4.1、§4.3 的两次 vulnerable。
2. **secure（有界）**：状态为 `secure` **且** 同时满足完整探索闸门——`paths.pending = 0`、`paths.discontinued` 五项全 0、
   `Instructions status.unknown = []`、SMT `unknown = 0`、`paths.completed.halt` 等于 `paths.total`、无 `sse-timeout` / `smt-timeout` / 深度截断、
   进程退出码 0。→ §4.2、§4.3 的两次 ct。
3. **unknown / 截断**：状态为 `unknown`，或上述闸门任一项不成立，或装载失败、墙钟超时。→ 本轮**主运行无此项**；§6.4 的故意截断对照属于此项。

**不得**仅凭退出码 0 判 secure：§6.4 的截断对照退出码同样是 0，但状态是 `unknown`。

## 6. 独立交叉验证

### 6.1 静态：泄漏地址与指令语义对得上

`formal-v2/analysis/disasm-*.txt` 是从被分析 ELF 直接反汇编的原件：

```
vulnerable (compare_early.c):
 8049042: movzbl (%edx),%ebx        # 取公开字节
 8049045: cmp    %bl,(%eax)         # 与秘密字节比较
 8049047: jne    8049061            # ← Binsec 报的泄漏点，数据相关分支
 8049051: jne    8049042            # 循环回边，只依赖索引/长度

ct (compare_ct.c):
 804904a: movzbl (%esi,%edx,1),%eax
 804904e: xor    (%edi,%edx,1),%al
 8049051: movzbl %al,%eax
 8049054: or     %eax,%ecx          # 累积差异，无数据相关分支
 8049059: cmp    %edx,%ebx
 804905b: jne    804904a            # 仅循环回边
 804905f: sete   %al                # 结果用 sete 无分支产生
```

vulnerable 内核里 3 个条件跳转中只有 `0x8049047` 依赖数据；ct 内核 2 个条件跳转都只依赖公开长度/索引。反汇编与 Binsec 的报点一致。

### 6.2 动态复算反例（补充，非形式结论）

用 TOML 反例的同一组取值，在本机原生 x86-64 重编同一份内核源码，调用 10000 次，用 Valgrind 计数（
[replay-results.txt](formal-v2/replay/replay-results.txt)，驱动 [replay_driver.c](formal-v2/replay/replay_driver.c)）：

| 内核 | 秘密 | 进程指令数（lackey） | 内核内指令数（callgrind `--toggle-collect=m4_compare_bytes`） |
|---|---|---|---|
| vulnerable | `byte[0]=0xff`（提前退出） | 375,112 | **90,000** |
| vulnerable | 全 0（与公开相等，走满循环） | 1,305,100 | **1,020,000** |
| ct | `byte[0]=0xff` | 1,495,221 | **1,210,000** |
| ct | 全 0 | 1,495,209 | **1,210,000** |

公开输入固定 16 字节全 0、长度 16。vulnerable 的内核内指令数相差 **930,000**（10.33×），动态确认秘密相关路径；
ct 两次**完全相等**（121 指令/次 × 10000），动态确认无秘密相关路径。逐次重复计数可复现（同输入三次同值）。
进程级那 12 条残差落在内核之外（格式化/装载），因此用 `--toggle-collect` 定位到内核。
这是**补充**证据，判定仍以 §4 的 Binsec 结果为准。

### 6.3 模型非空（对照有效）

同一 harness、同一配置、同一 bound，只是换内核，就得到 `insecure` + 具体反例；说明该模型能检测泄漏，
所以 ct 的 `secure` 不是模型过抽象/空转造成的假阴性。两次主运行的控制流检查数（50 / 33）与访存检查数（235 / 141）
也说明检查点确实覆盖了内核体。

### 6.4 截断敏感性对照（故意把 bound 调不足）

用同一 Binsec / Z3 / ELF / 配置，只把 `-sse-depth` 从 10000 降到 5（命令原文见
[command.txt](formal-v2/control-truncation-depth5/command.txt)）：

```
[checkct:result] Program status is : unknown (0.024)
[checkct:info] 0 visited path covering 33 instructions
pending paths 0 / discontinued paths 1 / max path depth 15
TOML: paths.completed.halt = 0，paths.discontinued.max_depth = 1
```

状态是 **unknown**，且 `halt = 0`、`discontinued.max_depth = 1`，**进程退出码仍是 0**。这既证明工具会在 bound 不足时如实报 unknown，
也证明本轮主运行的 `secure` 不是同类截断被静默吞掉的结果。

## 7. 与 formal-v1 的关系

- 本轮**不依赖**旧根：新根重新执行钉版校验安装、重新构建、重新实跑，`formal-v1/` 未改动。
- 两次主运行的判定与计数与 formal-v1 逐项一致（insecure `0x8049047`、49/50、235/235、32 路径；secure、33/33、141/141、16 路径）。
- 整文件 hash 不同（`308190a7…` vs `c06425da…`、`7f34c876…` vs `c2bd25b7…`）来自调试信息里内嵌的构建路径。逐节核对：
  两个内核的 `.text` 在 v1 与 v2 之间**逐字节相同**（vulnerable `9810b135…`，ct `b52fb771…`，见
  [text-section-comparison.txt](formal-v2/analysis/text-section-comparison.txt)）。因此 v2 是在**代码同一**的产物上独立复现了 v1 的结论。
- 本轮新增（v1 没有的）：新根 sha256 校验安装的完整日志、实际墙钟耗时、固定长度 16 的第二 bound、截断敏感性对照、
  反汇编与源码行对应、以及 6.2 的动态复算。

## 8. 局限（不得外推）

- **有界**：结论只覆盖上述 i386 `-O1` 抽取内核、16 字节数组、公开长度 `1..16` 或 `=16`、具体栈指针、`sse-depth ≤ 10000`、
  Binsec 0.11.3 + Z3 4.15.3、`control-flow`+`memory-access` 两类检查点。超出即无效。
- **不覆盖**：32 字节普通采集 ELF、任意长度、其他编译器/优化级别/对齐、完整 ML-KEM 或任何 KEM 端到端、
  乘法/除法检查点（未开）、以及**硬件层的恒时**——缓存、分支预测、推测执行、端口竞争等 µarch 效应都不在 `-checkct` 语义内。
- `secure` 的准确含义是：**在声明的模型与 bound 内，完整探索且未发现控制流/访存泄漏**；它不等于物理恒时，
  也不等于「无任何旁路」。反例存在时给出的是**判定性**结论（insecure），不需要 bound 之外的前提。
- 本文件不声称统计、实测或 `--collect` 的任何结论；M4 采集与统计仍由主控另行冻结执行。
- 本轮未触碰 `vendor/`、未改夹具密码语义、未 `git add/commit/push`。

## 9. 原件清单与复现

- 根目录：[formal-v2/](formal-v2/)，共 74 个受校验文件（另有校验清单自身，合计 75 个），清单 [MANIFEST.sha256](formal-v2/MANIFEST.sha256)（本地与远端同一份，`sha256sum -c` 0 失败）。
- 运行命令原文：[run-commands.txt](formal-v2/run-commands.txt)（每次运行的 date / 工具绝对路径 / ELF / 配置 / 完整命令行）。
- 每个运行目录含 `identity.txt`、`model.cfg`、`disasm.txt`、`stdout.txt`、`stderr.txt`、`status.txt`、`checkct.toml`、`elapsed.txt`、`key-facts.txt`。
- 被分析产物本身也在证据内：[artifacts/](formal-v2/artifacts/)（可直接用同一 Binsec 复跑）。
- 远端原件根：`/home/nss-marker/yhr/Cry/platform-m4-binsec-20261016-73f14add5392/`（`formal-v2/`、`build-formal/`、`runtime/`、`runtime-logs/`、`source/`、`download/` 均在 Cry 内，未覆盖旧根）。

复现（在 Cry 内新目录）：

```sh
sh <root>/source/tools/platform_m4/install_binsec.sh <NEW_CRY_ROOT>
cmake -S <root>/source/tools/platform_m4 -B <root>/build-formal -DBUILD_TESTING=OFF -DCMAKE_BUILD_TYPE=RelWithDebInfo
cmake --build <root>/build-formal --target platform_m4_formal_vulnerable platform_m4_formal_ct
sh <root>/source/tools/platform_m4/run_checkct.sh \
   <NEW_CRY_ROOT>/runtime/binsec-0.11.3/_opam/bin/binsec \
   <NEW_CRY_ROOT>/runtime/bin/z3 \
   <NEW_CRY_ROOT>/build-formal/platform_m4_formal_vulnerable \
   <root>/source/tools/platform_m4/checkct_1_16.cfg \
   <NEW_CRY_ROOT>/formal-v2/<新目录名>
```
