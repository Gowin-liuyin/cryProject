# P7（对象扩展与威胁模型 v2）会话报告（2026-11-16）

## 1. 开工自检（原文）

```text
$ cd ~/cryProject-work && git branch --show-current
main
$ git status --porcelain | head -5
（无输出）
$ git log --oneline -2
cef0eab5 docs(l2l3): M3×R19 恢复计划与 L3 提纲
05026055 test(adaptive): M4 失配位置恢复演示（两臂对照）

$ which valgrind || echo ABSENT
ABSENT
$ df -h ~
Filesystem      Size  Used Avail Use% Mounted on
/dev/sdd       1007G   70G  887G   8% /
```

《任务书》§9 复述：T7.1 R17 向量化对象反汇编层审计（三对象构建 + 六类扫描表 + Memcheck 待办）；
T7.2 R23 优化矩阵本地补格（gcc/clang 缺格/M2 全格，产物判定 + 裸金属 PLAN）；
T7.3 R24 Binsec 扩面 harness/cfg + 执行 PLAN；T7.4 R25 威胁模型 v2（七维树 + L0–L4 分级）。
vendor 在 P2 已取件且摘要与钉版一致（`fetch_all_vendors.sh` 幂等校验；本阶段只读使用，未再改动）。

## 2. 每任务状态与关键数字

### 提交 1｜T7.1 R17 —— 完成（反汇编层；动态待裸金属）

- 三对象构建（全部在 `build/p7/`，vendor 只读）：
  - `liboqs-avx2-dist`：`OQS_DIST_BUILD=ON OQS_OPT_TARGET=avx2`，avx2 变体编译旗标
    `-mavx2 -mbmi2 -mpopcnt` 实读；`liboqs.a` SHA-256 `9d839d1f…`；**AVX2 产物指令确认**
    （`vpshufd/vpsllvd/vpshufb`），运行期 dispatch 在 AVX2+BMI2+POPCNT 时选 avx2 函数指针；
    独立 roundtrip selftest **100/100**，`OQS_CPU_has_extension(AVX2)=1`。
  - `kyber round3 avx2` 两臂：Makefile 实旗标 `-mavx2 -mbmi2 -mpopcnt -maes -march=native -O3`；
    ELF 摘要 unfixed `ce6051c3…`、fixed `32858b08…`；自带 `test_kyber768` **两臂退出 0**。
  - `mlkem-native-native`：按自带文档 monolithic（`mlkem_native.c` + `mlkem_native_asm.S` +
    native 后端 config），clang 18.1.8 `-O3 -mavx2 …`；ELF `a2119b56…`；
    deterministic roundtrip 通过；**vendor 无自带 KAT 入口 → KAT 未检查（原因已记）**。
- 六类扫描（frommsg/tomsg/compress 系/verify/cmov/KDF）：三对象 frommsg/tomsg/compress
  **无秘密条件跳转候选、无 div、无秘密下标缩放访存、无 abort/assert/exit**；
  verify/cmov 的条件跳转均定位到公开长度/循环（`shr $0x5; je`、`cmp %rsi,%rax; jne`）；
  AVX2 对象里 frommsg 为向量掩码序列（与 R09 ref `bt/jae` 形态不同，但**不能**写"泄漏消失"）。
- 产出 `docs/R17-向量化排查表-20261116.md` 与 `docs/research/phase7-session-20261116/A_LINE_BUNDLE.md`
  （Memcheck/KAT 待裸金属 A-R17-01..04）。

### 提交 2｜T7.2 R23 —— 完成（24 格本地产物判定）

- 24 格：gcc O0/O2/O3/Os × M1 两臂（8）；clang-18 O1/Oz/Og × M1 两臂（6）；
  clang-18 O0/O1/Oz/Og × M2 两臂（8）。判定位复刻 R09 `tools/platform_optlevel/judge_cells.py`
  的五预注册位（clangover_bt_jae / per_bit_test_jcc / secret_division / setcc / cmov）。
- 结果：M1 clang 未修 O1/Oz/Og **3/3 复现 bt+jae**；M1 已修同级别走 `setcc`（3/3，无 jae）；
  M1 gcc 四级别全组**无** clangover/per-bit-test 形态；M2 两臂 O1/Oz/Og 都保留 `bt/jae`
  （与 R05 M2-c 一致）；M2 未修 `poly_compress/poly_tomsg` 的 `div` 仅在 O0/Oz 出现
  （O1/Og 消失），fixed 全 0。24/24 本地格有判定，无"未检查"格。
- 产出 `docs/research/r23-optlevel-ext-20261116/{RESULT.md,cells.tsv,BARE_METAL_PLAN.md}`；
  Memcheck 与锁频计时写裸金属 PLAN 并汇入 A_LINE_BUNDLE（A-R23-01/02）。

### 提交 3｜T7.3 R24 —— 完成（harness/cfg/PLAN，不执行）

- `tools/platform_m4/binsec_harness_cmov.c`（抽 `mlk_ct_cmov_zero`/`mlk_ct_sel_uint8` 路径）、
  `binsec_harness_kdf.c`（KDF absorb rate 边界循环）+ 同名 `.cfg`（r14 体例：entry/halt、
  secret/public globals、concrete stack pointer、explore all）。
- 本地 `clang -fsyntax-only -ffreestanding -std=c11` **语法级检查通过**；未链接、未执行 Binsec。
- `docs/research/r24-binsec-ext-20261116/PLAN.md` 冻结裸金属构建/执行命令、判据
  （有界分析、unknown/pending/超时/装载失败如实保留、不凭退出码 0 写 secure）与产物约定。

### 提交 4｜T7.4 R25 —— 完成

- `docs/evidence/r25-threat-v2-20261116/THREAT_MODEL_V2.md`：骨架 = 测评总树 §1 七维树；
  A.2 观测量按 L0–L4 分级（L0/L1 已有实证；L2=M4 演示 vulnerable **15/20**、ct **1/20 未检出**，
  M3×R19 为计划；L3/L4=边界与授权条款，逐字引用《任务书》§2 T0.3 拟替换的 AGENTS 分级文本，
  并注明 AGENTS.md 正式修订待主控）；含 P0–P6 全部新证据目录索引与逐节点"未执行一句话边界"。
  R11 原件不改。
- 台账追加一行；本 SESSION 落盘。

## 3. 四个提交（本地 main，作者/提交者 `Gowin-liuyin`，未 push）

| hash | 信息 |
|---|---|
| `b7a686b2` | `feat(audit): 向量化对象构建与反汇编层排查表` |
| `c3c63ea6` | `test(optlevel): 优化矩阵本地补格与裸金属计划` |
| `996c104f` | `build(binsec): 扩面 harness 与执行计划` |
| 本文件所在提交 | `docs(threat): 威胁模型 v2 树状化与分级实证表`（hash 见 `git log -1`） |

## 4. 偏离项及理由

1. **R09 判定脚本复用方式**：`tools/platform_optlevel/judge_cells.py` 依赖 R09 冻结树路径，
   不能在当前 WSL 直接复跑；本地 `build/p7/r23.py` **按其文档字符串冻结的五个预注册位**
   复刻实现（clangover_bt_jae/per_bit_test_jcc/secret_division/setcc/cmov），并在 RESULT 引用原脚本。
2. **gcc 旗标映射**：gcc 无 `-fno-vectorize/-fno-slp-vectorize`，改用等价
   `-fno-tree-vectorize -fno-tree-slp-vectorize`；M2 clang 四级固定为 `-O0/-O1/-Oz/-Og`
   （理由写进 RESULT：覆盖最小/基础/历史 `-Oz`/调试优化，O2/O3 已有 R09 M1 系列）。
3. **R17 KAT/动态层**：liboqs 官方 KAT 套件未随库构建运行（改为独立 roundtrip selftest）；
   mlkem-native vendor 树无自带 KAT 入口（KAT 未检查，原因写明）；全部对象 Memcheck 因本机
   `valgrind` ABSENT 未做，统一进 A_LINE_BUNDLE，不装包。
4. **构建脚本位置**：R17/R23 的扫描与矩阵脚本、原始反汇编在 `build/p7/`（gitignored），
   未新开工具目录（白名单不含）；表内以指令片段作证据。
5. **并行工作区改动**：本阶段执行期间，工作区出现了**另一并行任务**的未提交改动
   （`CMakeLists.txt`、`cmake/PlatformM2.cmake`、`cmake/PlatformM3.cmake` 的修改，以及
   `tools/platform_observers/victim_backend*`、`victim_wrapper.c`、`run_pair.sh`、
   `scripts/platform_stats/join_observer_classes.py`、`tests/test_observer_pair_mock.sh` 等新增文件，
   并注册了 `test_observer_pair_mock`）。这些文件**不属于本阶段**，我未修改/未暂存/未提交；
   它们使全量 ctest 变为 67 项且该外部用例一度失败。本阶段按"P0–P6 既有套件"口径复核：
   `ctest --preset baseline-wsl -E test_observer_pair_mock` 为 **66/66**，format-check 通过；
   最终提交后全量复跑该 66 项仍全绿。
6. **工具环境限制**：WSL 既有文件编辑仍受 `GetFileSecurityW EIO` 限制，配置/脚本修订用
   "Windows 临时文件 + cp"/`sed -i` 落地；`git diff` 核对为预期新增。

## 5. 卡点

- **无本阶段阻塞性卡点**；四项交付按白名单齐备。
- **工作区最终不干净**：并行任务的未提交改动（见 §4.5）仍在工作区，需主控处置后一次性提交；
  本阶段 4 个提交均只含白名单路径，未触碰这些文件。
- 边界：R17/R23/R24 的动态执行（Memcheck、锁频计时、Binsec）、R18/R19 pilot 与 L2/L3 执行
  均留给主控；本阶段全部结论只到反汇编层或计划层，不改变既有签收。
