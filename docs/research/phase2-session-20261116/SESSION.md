# P2（R0b + R0a 软件部分）会话报告（2026-11-16）

## 1. 开工自检（原文）

```text
$ cd ~/cryProject-work && git branch --show-current && git status --porcelain | head -5
main
（git status 无输出）

$ git log --oneline -2
63cd051e test(platform-stats): 既有 M1 数据形状检验回放与证据落盘
302f749f feat(platform-stats): 新增 shape_stats 三检验与合成数据自检

$ /home/ubuntu/miniconda3/envs/cry/bin/clang --version | head -1
clang version 18.1.8 (https://github.com/conda-forge/clangdev-feedstock 3c15221e001c9fe87fcc807876aa06d599616b01)

$ objdump --version | head -1
GNU objdump (GNU Binutils) 2.45.1

$ python3 --version
Python 3.13.12
```

取件（`sh tools/fetch_all_vendors.sh`）自校验输出尾部：

```text
=== 取件完成：四棵 vendor 树的 SHA-256 全部一致 ===
  vendor/liboqs-0.10.0             d3322945483983b45c60406127790107865706523c4e83a15e27c7211c776cdd
  vendor/liboqs-0.10.0-982c762     e27e55e5bdb59e89bfe26c8f82ddf8b162346537333c8b18b9e61c9d91093f14
  vendor/kyber-kyberslash-unfixed  1898b727ed24e014cb731442b9a83cd4d82fc49e06899f9ab2d9364ecd60397f
  vendor/kyber-kyberslash-fixed    8503134f538461c03820e13a0936024a46fff5d85ba334fb0a365f6378a49976
```

《任务书》§4 复述：T2.1 产出 vendor 泄露面扫描器与 HITS/hits.json；T2.2 产出三份值屏障
候选补丁、反汇编判定脚本与三候选判定证据；T2.3 产出修复臂 KAT/等价日志与摘要；T2.4 产出
复测采集冻结 PLAN（不执行采集）。

## 2. 每任务状态与关键数字

### 提交 1｜T2.1 vendor 泄露面扫描 —— 完成

- `scripts/scan_vendor_leak_surface.py`（Python3 标准库，`--config` 固定清单）。
- 官方扫描：固定清单 **5 棵 vendor 树 / 22 个文件 / 6298 行，命中 0 行**；`HITS.md` + `hits.json`
  落盘 `docs/evidence/r0b-vendor-surface-20261116/`；同级 `grep -c` 逐文件交叉核对全为 0。
- 因官方命中为 0，无法做"命中行抽查 10 行"；用只存在于 `build/`（不提交）的正对照
  配置把已知含 `abort/errno` 的 `vendor/kyber-kyberslash-fixed/ref/randombytes.c` 加入清单，
  同一扫描器输出 **10 行命中**，`sed` 逐行核对 10/10 与 `hits.json` 文本一致、函数名为
  `randombytes`，证明计数与函数定位可用。
- 主树 `ctest --preset baseline-wsl` **57/57**、format-check 通过。

### 提交 2｜T2.2 三候选补丁与产物判定 —— 完成（前置门通过）

- 第 0 步前置门：用 clang **18.1.8**、按证据口径
  `-O2 -g -DNDEBUG -Oz -g -fno-vectorize -fno-slp-vectorize -DKYBER_K=3
  -Drandombytes=platform_m2_randombytes -std=c11` 复刻未打补丁的
  `vendor/kyber-kyberslash-fixed/ref`，链接一次 keygen/encaps/decaps 驱动；
  `objdump -d --disassemble=pqcrystals_kyber768_ref_poly_frommsg` 得到
  `bt → jae → mov $0x681`，判定 `secret_conditional_jumps=1`、退出 1 ——
  **18.1.8 能复现证据机 18.1.3 的 bt/jae 形态**，前置门通过。
- 三候选判定（`tests/check_m2_frommsg_branchless.sh --elf <elf>`）：

| 候选 | secret_conditional_jumps | verdict | exit |
|---|---:|---|---:|
| baseline 未修 | 1 | secret_branch_present | 1 |
| `m2-frommsg-barrier-asm.patch`（主候选） | 0 | branchless | 0 |
| `m2-frommsg-barrier-volatile.patch` | 0 | branchless | 0 |
| `m2-frommsg-ctselect.patch` | 0 | branchless | 0 |

- 选定 asm 屏障为主候选（三候选均达标，侵入最小）。证据：
  `docs/evidence/r0a-branch-fix-20261116/{SANDBOX.md,RESULT.md,disasm/,judgements/,...}`。

### 提交 3｜T2.3 修复臂 KAT 与等价 —— 完成

- 方案 B：临时把主候选补丁应用到 `vendor/kyber-kyberslash-fixed`
  （改前树摘要 `8503134f…` → 改后 `88facaeb…`），用 clang 18.1.8 重建平台树。
- M2 CTest **7/7 通过**：functional×2、random_failure×2、semantic_equivalence（160 例）、
  public_kat×2；两臂 KAT 各 **100/100**。
- 额外等价（`equivalence/equiv_driver.c`，确定性固定 seed/消息）：
  **500 随机往返 + 500 逐字节篡改**；两臂 transcript 各 1001 行、SHA-256 同为
  `adc4113ae505935091250f55f1aaaa912e1a828ca63f2d778506b020117ea5f2`、`diff -u` 全空；
  SUMMARY `random_cases=500 random_roundtrips=500 tampered_cases=500 implicit_rejections=500`。
- vendor 恢复：树摘要回到 **8503134f…**（与改前一致）；恢复后重建通过，
  fixed 臂反汇编重新出现 `bt/jae`（`secret_conditional_jumps=1`），KAT 100/100、M2 7/7。

### 提交 4｜T2.4 复测 PLAN —— 完成（纯文档，未执行任何采集）

`docs/research/r0a-recap-20261116/PLAN.md` 冻结：三臂（未修 / 上游已修 / 自研修复）×
主类对 × 3 种子（31337/CPU2、424242/CPU2、31337/CPU6）× 每类 10000 + 预热 100；
家族 `m2_branchfix_end_to_end_v1`（m=9）、α=0.05；判据=产物层 0 秘密条件跳转、
定位层 Memcheck 上下文数 1/1/0、统计层 9 成员 Holm + CI 如实报告；含采集命令模板、
控制器计划校验、远端目录约定（`Cry/r0a-branchfix-20261116-<nonce>/`）。

## 3. 四个提交（本地 main，作者/提交者 `Gowin-liuyin`，未 push）

| hash | 信息 |
|---|---|
| `f3965a08` | `feat(scan): vendor 防护链泄露面扫描器与命中表` |
| `59d202c6` | `fix(m2): poly_frommsg 值屏障修复三候选与产物判定` |
| `2e8e33e4` | `test(m2): 修复臂 KAT 与等价验证` |
| 本文件所在提交 | `docs(r0a): 复测采集冻结计划`（hash 见 `git log -1`，文件无法自引用） |

## 4. 偏离项及理由

1. **平台树编译器**：`cmake/PlatformM2.cmake` 仅在 Clang 下启用 M2 目标，而 `baseline-wsl`
   预设钉的是 conda gcc；为了让 M2 用例可构建，重建的 `build/cmake-platform` 用
   `-DCMAKE_C_COMPILER=/home/ubuntu/miniconda3/envs/cry/bin/clang`（clang 18.1.8）配置，
   其余（RelWithDebInfo、BUILD_TESTING、BASELINE_SANITIZERS=OFF、format 钉版）保持。
   详见 `docs/evidence/r0a-branch-fix-20261116/KAT_EQUIV.md`。`build/` 仅构建产物。
2. **vendor 恢复路径展开**：取件脚本在"M2 只有一臂就绪"时拒绝继续；按提示词
   `rm -rf fixed && sh tools/fetch_all_vendors.sh` 会直接失败。实际做法：先把未修臂
   临时移出 `vendor/`（未删除、核对树摘要与重取结果一致后再删除副本），再整体取件；
   过程记录在 `docs/evidence/r0a-branch-fix-20261116/PATCH_RESTORE.md`。
3. **T2.1 官方 0 命中与 10 行抽查**：固定清单 22 文件确实 0 命中（独立 grep 复核），
   无法对官方命中做 10 行抽查；改用 `build/` 内正对照（randombytes.c，不在官方清单）
   做 10/10 逐行核对，并在 RESULT.md 明确这是工具灵敏度验证、不计入官方结果。
4. **额外等价口径**：跨臂逐字节可比要求确定性，故"500 随机"是固定公式伪随机消息
   （公开固定种子），不是 OS 随机源；500 个篡改用例按用例序号翻转不同字节位置。
5. **工具环境限制**：WSL 仓库内既有文件经 `\\wsl.localhost` 编辑时 `write/edit` 工具报
   `GetFileSecurityW EIO`，对既有文件改用"Windows 临时文件 + `cp`/追加"落地，
   以 `git diff` 核对为纯新增/纯追加；未绕过评审、未改动既有内容。
6. `SESSION.md` 无法写入自身所在提交的 hash（自引用），最终会话消息给出完整四个 hash。

## 5. 卡点

- 无阻塞性卡点。边界提醒：T2.2/T2.3 是产物与功能/等价层证据，**不是计时、恒时或
  零泄露证明**；T2.1 的 0 命中只覆盖固定清单；R0a 裸金属复测（含 9 成员 Holm 与
  Memcheck 1/1/0）**未执行，留待主控**按 PLAN 采集。
