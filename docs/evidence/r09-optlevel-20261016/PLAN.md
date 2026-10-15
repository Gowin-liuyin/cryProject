# R09 优化级别对照计划（族外，2026-10-16）

**定位：本计划回答两个问题，都属于族外，不进任何 Holm 家族。**

1. **T22（构建 + 反汇编 + 动态检查）**：M1 两版与 M5 在 clang-18 的
   `-O0 / -O2 / -O3 / -Os` 四个级别下，`poly_frommsg` 这个机制**在该级别下是否仍然存在**
   （数据相关分支 / 掩码形式 / 数据相关除法），以及 Memcheck 秘密标记在该级别下报不报。
2. **T23（锁频计时，预算见 §6）**：在同样 12 个格子上，用各格自己的采集件采主类对
   `message-zero` vs `message-ones`，每类 10000 次 × 3 个种子。

> **先提交、后采集。** 主控把本文件上传到 `Cry` 后，用 `sha256sum` 核对与 `RUNS.sh`
> 里写死的摘要一致，再执行控制器命令；不一致不得开跑（控制器也会用 `--plan-sha256` 拒绝）。
>
> 本计划**不修改任何冻结树**：12 个格子全部在 `Cry/r09-optlevel-20261016-85e46c952887/`
> 内新建，只**引用**冻结树的源码与既有构建元数据。
>
> **本计划的判定与计时段都是族外**：不改变 M1/M5 的既有 Holm 判定，
> 也不把"某个级别下分支消失/出现"写成"泄漏消失/出现"的因果结论。

---

## 1. 覆盖矩阵与格子定义

| 臂 | 实现 | 版本口径 | 符号 |
|---|---|---|---|
| `m1unfixed` | liboqs 0.10.0 `historical-clangover`（未打修复） | 上游 `36be5744…`（0.10.0），AVX2 分发关 | `pqcrystals_ml_kem_768_ipd_ref_poly_frommsg` |
| `m1fixed` | 同上 + 官方修复 `982c762`（`cmov_int16` + `setb`） | 同版本副本 `liboqs-0.10.0-982c762` | 同上（另有 `…_ref_cmov_int16`） |
| `m5ref` | mlkem-native `b3ba7b32773e657dd37f6f87bce82528459ad8a4`，portable reference | 未打任何人工补丁变体 | `baseline_native_poly_frommsg` |

格子 = 臂 × 级别，共 **12 格**：`m1unfixed-{O0,O2,O3,Os}`、`m1fixed-{O0,O2,O3,Os}`、
`m5ref-{O0,O2,O3,Os}`。格子编号（T23 的 run-name 用）写成小写：
`o0`、`o2`、`o3`、`os`。

**gcc：未做。** 理由（如实写，不用"机时不足"一句话敷衍）：本项的机制是
**Clang 15–18 在 `-Os/-O1` 下的代码生成选择**（把源码里本来就无分支的
`-((msg>>j)&1) & 0x681` 选成 `bt` + 条件跳转）。GCC 不产生这条 clangover 路径，
做 gcc 只会得到"另一套编译器下的另一组数字"，与"该级别下 clangover 是否仍然存在"
不是同一个问题。若后续需要 gcc 对照，应作为独立计划另立，不与本计划的 12 格混排。

---

## 2. 构建口径：只有优化级别在变

### 2.1 关键条件（全部保留）

| 条件 | 取值 | 来源 |
|---|---|---|
| 编译器 | `/usr/bin/clang-18`（Ubuntu clang 18.1.3） | 冻结树 `CMakeCache.txt` 的 `CMAKE_C_COMPILER` |
| M1 liboqs 分发 | `OQS_DIST_BUILD=OFF`、`OQS_OPT_TARGET=generic`、`OQS_USE_AVX2_INSTRUCTIONS=OFF`、`OQS_ENABLE_KEM_ml_kem_768_ipd_avx2=OFF`、`OQS_MINIMAL_BUILD=KEM_ml_kem_768_ipd` | 冻结树 `cmake/Liboqs010Historical.cmake`，是构建期条件，**不在替换范围内** |
| M1 额外 C 标志 | `-fno-vectorize`（冻结 clangover 配方的一部分） | `CMakeCache.txt` 的 `LIBOQS010_C_FLAGS=-Os -fno-vectorize` |
| M1 其余 | `-g -DNDEBUG -std=gnu11 -fPIC -fvisibility=hidden -Wa,--noexecstack -g3 -fno-omit-frame-pointer` 以及每条命令自带的 `-D/-I` | 冻结 `compile_commands.json` 逐字 |
| M5 | `-DMLK_CONFIG_FILE="baseline_config.h"`、`-std=c11 -Wall -Wextra -Wpedantic -Wshadow -Wconversion -Wstrict-prototypes -Werror`、`-g -DNDEBUG` | 冻结 `compile_commands.json` 逐字 |

**唯一被替换的 token 是 `-O*` 那一个。**替换实现是
`tools/platform_optlevel/build_optlevel_cells.py`：它按
`CMakeFiles/<target>.dir/<source>.o` 唯一定位每个翻译单元的冻结编译命令，
用 `shlex` 切词，只把形如 `-O0/-O1/-O2/-O3/-Os/-Oz/-Og/-Ofast` 的那个 token 换成目标级别，
其余 token 原样重排后执行，并把**实际执行的完整命令**逐条写进
`<cell>/build.log`。因此"只有优化级别变化"是可逐字核对的，不是口头声明。

### 2.2 每个格子里哪些东西跟着级别变

**该臂的全部 C 源用同一个 `-O<级别>` 编译**：实现（M1 的 liboqs 对象 / M5 的
kernel·mlkem·random·inputs）、封装层、采集件 `src/measure.c`、Memcheck 探针，全部同级别。

| 与冻结构建的差别（写清楚，不假装一样） |
|---|
| 冻结 M1 的实测构建是**混合级别**：liboqs 在 `-Os`、封装层与采集件在 `-O2`；本轮 12 格是**整树同一级别**。因此本轮的 `m1unfixed-Os` 与冻结树的 M1 只在封装层/采集件的级别上有别（`-O2` → `-Os`），实现侧的 liboqs 对象级别相同。BUILD.md 会单独给一行"冻结混合级别参照"，但那一行**不重建**、不计入 12 格。 |
| 冻结 M5 是 `-O2 -g -DNDEBUG`；本轮 `m5ref-O2` 与它在级别上一致，差别只在 `build_identity.h` 由本计划诚实重写（见 §2.3）。 |

### 2.3 `build_identity.h` 的处理

冻结树的 `measure.c` 会 `#include "build_identity.h"` 并把里面的行写进 CSV 的 meta。
冻结树自带的那个头文件写死了 `configuration=RelWithDebInfo`、`compiler_flags=-O2 …`，
对本轮的 `-O0/-O3/-Os` 格**是不实描述**。因此每个格子在
`<cell>/generated/build_identity.h` 重新生成一份诚实的身份头，并用
`-I <cell>/generated` **放在包含路径最前面**覆盖冻结树的那一份。新头文件逐字记录：
格子名、臂、优化级别、冻结树路径、冻结 `SOURCE_EXPORT.sha256` 的摘要、
编译器路径、本构建脚本的摘要、以及
`project_cmake_configuration=not_used_cell_built_from_frozen_compile_commands`。
**冻结树本身不被改写。**

### 2.4 M1 liboqs 对象的重建

M1 的 liboqs 归档由 `tools/platform_optlevel/build_liboqs_cell.py` 重建：
它**按成员对象 sha256** 把冻结 `liboqs.a` 的 24 个成员一一映射回
冻结 `liboqs010-build/compile_commands.json` 的条目（同名成员 `kem.c.o` 在归档里出现两次，
按名字匹配会取错或漏取，所以按内容摘要匹配），再逐条替换 `-O*` 后重新编译、重新归档。
归档成员顺序、数量与逐成员摘要都记在 `<cell>/liboqs-build.log` 与
`<cell>/liboqs.a` 的 sha256 里。

---

## 3. 每格的产物与资格

每格产出（均在 `<root>/build/<cell>/` 内）：

| 产物 | 说明 |
|---|---|
| `measure` | **普通**（非 sanitizer）可执行采集件，供 T23 计时；sha256 记入 BUILD.md |
| `liboqs.a` / `libmlkem_cell.a` | 该格级别的实现静态库（重建产物，不是冻结库） |
| `platform_m5_poison_cell` / `historical_poison_cell` | 该格级别的 Memcheck 秘密标记探针 |
| `build.log` | 逐条**实际执行的完整编译命令**与退出码 |
| `generated/build_identity.h` | 诚实的格子身份头 |

**资格检查（构建后、采数前，本地即可做，不需要锁频）**：
`--describe` 退出 0；小样本试跑退出 0 且 `run_status=complete`、
`zero_elapsed_count=0`、CSV 表头与 `--format measure` 期望逐字一致。
资格失败就不进入 T23。

---

## 4. T22 判定规则（预注册，不按结果改）

对每个格子的 `measure`：

### 4.1 反汇编判定

用 `/usr/bin/objdump -d --no-show-raw-insn --disassemble=<符号>` 取**函数体**
（同时保留带机器码的 `.raw.txt` 原文，便于逐字节复核）。

| 判定位 | 规则 |
|---|---|
| `bt_jae`（clangover 形态） | 函数体内存在 `bt`，且其后 **4 条指令内**紧跟 `ja/jae/jb/jbe/jc/jnc` |
| `per_bit_test_jcc`（另一条分支形态） | 函数体内存在 `testb $imm,<内存操作数>`，且其后 **2 条指令内**紧跟任一条件跳转 |
| `secret_division` | 出现 `div` / `idiv`（数据相关除法，Kyberslash 形态）；计数 |
| `setcc` / `cmov` | `set*` / `cmov*` 指令计数（掩码物化形式的证据） |
| `conditional_jumps` | 函数体内条件跳转总数（含循环计数跳转，只作对照，不单独构成结论） |

**M1 两版额外看 `pqcrystals_ml_kem_768_ipd_ref_cmov_int16`**：修复版的掩码逻辑在
`-O2/-O3` 下是一个**未内联的独立函数**，只看 `poly_frommsg` 的函数体会把
`cmov` 数成 0，那是误读。因此 M1 每格同时导出该辅助函数的反汇编与判定
（BUILD.md 用 `helper_cmov`/`helper_setcc`/`helper_bt_jae` 三列）。

判定实现：`tools/platform_optlevel/judge_cells.py`（与本节的规则逐条对应）。

### 4.2 Memcheck 秘密标记

| 臂 | 探针 | 标记什么 | 命令 |
|---|---|---|---|
| `m1unfixed` / `m1fixed` | 冻结树既有 `tools/historical_poison.c`（仓库的 ctgrind/poison 路线） | `sk` 前 1152 字节（indcpa 私钥多项式）标为未初始化；公开封装密钥与公开密文不标 | `valgrind --tool=memcheck --error-exitcode=0 --num-callers=24 --track-origins=no <probe>` |
| `m5ref` | 冻结树既有 `tools/platform_m5/poison.c`（`platform_m5_poison --poison`） | indcpa 私钥 1152 字节 + 拒绝秘密 `z`（偏移 2368，32 字节） | 同上 |

统计口径：**两类报错**——`Conditional jump or move depends on uninitialised value(s)`
与 `Use of uninitialised value`。报**两个数**：唯一错误上下文条数（valgrind 的
`from M contexts`）与动态报错次数（`N errors`）。
**命中数是"唯一错误位置数"，不是动态执行次数**；两者都写进 BUILD.md，
原始 valgrind 全文放 `memcheck/<cell>.valgrind.txt`，不做删减。

**动态检查只覆盖本固定产物、本输入种子、本工具能力；无命中不等于恒时。**

---

## 5. T23 采集件、参数与统计口径

### 5.1 采集件

T23 **不新写 harness**：直接用每个格子自己的 `measure`
（就是该树的 `src/measure.c` 在该级别下编译出来的普通采集件）。
CLI 与冻结合同一致（位置参数，无 `--`）：

```
measure RUN_ID SEED SAMPLES_PER_CATEGORY CSV_FILE META_FILE
```

- `SAMPLES_PER_CATEGORY` 上限 20000。
- 一次运行采集**五个类**各 N 次：`valid` / `bit-flipped` / `random` /
  `message-zero` / `message-ones`。**主类对是 `message-zero` vs `message-ones`**；
  另外三类作为上下文数据完整保留，不进入本计划的结论。
- CSV 表头与 `scripts/run_stats_battery.sh --format measure` 期望逐字一致，
  可直接用 `--classes message-zero message-ones` 解析。
- 输出 CSV/meta 用 `wx` 新建，已存在即失败。

### 5.2 运行表（每格 3 次）

| run 后缀 | 种子 | CPU |
|---|---|---|
| `s1` | 31337 | CPU2 |
| `s2` | 424242 | CPU2 |
| `s3` | 7 | CPU6 |

12 格 × 3 = **36 次控制器运行**，run-name 为 `r09-<level>-<arm>-s<n>`。
`--samples 10000`（**每类** 10000），主类对每次运行各 10000 次。

### 5.3 统计口径（族外，不进 Holm）

- 每格每次运行：主类对 `mean(message-zero) − mean(message-ones)`、双侧 Welch 原始 p、
  95% 大样本正态近似 CI；**不做 Holm，不做任何多重比较校正**，
  因为这一组是族外描述，不是家族检验。
- **优化级别的计时数据不进任何 Holm 家族**；既不与 M1/M5 既有家族合并，
  也不在这 12 格之间做"哪一级更安全"的排序。
- 结论措辞只允许写"**该级别下机制是否仍然存在**"（分支形态 / 掩码形态 / 除法形态），
  以及"修复在该级别下是否仍然成立"。**不写**"某个级别更安全"或"开销差即泄漏差"。
- 若某个级别下 `div`（或其他机制）消失，那是**跨环境结论**（编译器在该级别换了实现），
  如实写"该级别下该形态消失"，不写成"泄漏消失"。
- RTLF（α=0.01）可选；若跑，同为族外二值描述。
- 长尾全部保留，不截尾（与 `docs/timing.md` 第 34 行一致）。

---

## 6. T23 的锁频预算与频率合同

- 预算：**每格**主类对 10000 × 3 种子；**每格**1 次 `--samples 10000` 的运行
  实采 5 类 × 10000 = 50000 次完整 `mlkem_decapsulate`（其中主类对 2 × 10000）。
  12 格合计 36 次运行、60 万次主类对调用。
- 频率合同与主合同一致：`boost=0`、目标 policy 的 governor/EPP=`performance`、
  `scaling_min_freq = scaling_max_freq = 4300000 kHz`、`taskset -c 2|6`
  （由 `controller.py --cpu` 施加）；沉降 1.0 s 后 20×50 ms 放行探针全部落在
  ±2% 且跨度 ≤50000 kHz 才放行。
- 控制器：`tools/platform_control/controller.py`，sha256
  `4a0cf57a00c6802ff86ed410d2518bc56cc8e694422cbc4ea7a24a3f1cdd701`；
  控制根 `Cry/platform-control-20261016-53929b406f0d`（**若主控本轮另建控制根，
  以主控给的为准**）。
- **有效判据**：`terminal.json` 的 `reason=worker_finished`、
  `worker_exit_code=0`、`worker_drained=true`、`restore_match=yes` 同时成立。
  **`restore_match=yes` 才算有效。**
- 进入 / 运行中 / 退出三处频率快照由控制器落盘。
- `--timeout-seconds 900`（`-O0` 格最慢，留足余量；控制器上限 1800）。

---

## 7. 停止与失败归档

1. 任一次运行 `restore_match != yes`、`worker_exit_code != 0`、或放行探针越界：
   **立即停止后续采集**，先把该 run 的控制器原件整体归档到
   `Cry/r09-optlevel-20261016-85e46c952887/failed/<run-name>-attempt<n>/`，
   再决定重跑。失败运行不计入结果，也不从记录里消失。
2. 同一 run-name 不复用（控制器用 `mkdir` 新建运行目录，已存在即失败）；
   重跑用新 run-name（`-a2`、`-a3` 后缀）。
3. 采集件对已存在文件返回非 0：按失败处理并换名重跑。
4. 连续两次同类失败：停止整组，写 `BLOCKERS`（run-name、判据、原件路径、已试次数），
   交主控决定。
5. 采集中途出现频率探针越界：后续 run 一律不跑，先恢复并核验 `restore_match`。
6. 构建/判定阶段若发现某格无法构建或符号缺失：**该格如实写"未执行 + 原因"**，
   不跳过不提，也不改判定规则去迁就结果。

---

## 8. 交付物

| 路径 | 内容 |
|---|---|
| `docs/evidence/r09-optlevel-20261016/PLAN.md` | 本文件 |
| `docs/evidence/r09-optlevel-20261016/BUILD.md` | 12 格一行：模块 / 版本 / 级别 / 实际编译命令（或命令日志路径）/ 分支? / cmov? / div? / Memcheck 命中 / ELF sha256 |
| `docs/evidence/r09-optlevel-20261016/disasm/` | 每格 `poly_frommsg` 的原始 `objdump`（含 `cmov_int16`），逐字节可复核 |
| `docs/evidence/r09-optlevel-20261016/memcheck/` | 每格原始 valgrind 全文与计数摘要 |
| `docs/evidence/r09-optlevel-20261016/RUNS.sh` | 36 条可直接复制的控制器命令（主控串行执行） |
| `tools/platform_optlevel/` | 可复跑的构建、判定与探针脚本 |

配套工具（全部在仓库内，可复跑）：

| 文件 | 作用 |
|---|---|
| `tools/platform_optlevel/build_optlevel_cells.py` | 12 格的构建驱动（替换 `-O*`、生成诚实的 `build_identity.h`） |
| `tools/platform_optlevel/build_liboqs_cell.py` | 按成员摘要映射并重建 liboqs 归档 |
| `tools/platform_optlevel/judge_cells.py` | §4 的反汇编判定 + Memcheck 计数，输出 `CELLS.tsv` |

---

## 9. 边界（不夸大）

- 12 格只覆盖 **clang-18 18.1.3 / x86_64 / 这台 Ryzen 9 9950X**。别的编译器版本、
  别的架构、别的 `-march` 都不在结论范围内。
- 反汇编判定看的是**产物里有没有那个指令形态**；Memcheck 看的是**该产物在该输入上
  有没有把秘密带进条件跳转**。两者是不同层次的证据，缺一不可，也都不等于恒时证明。
- 计时差异只说明**开销**，不说明安全性；反过来也一样。
- 本计划不重新判定 M1/M5 的既有 Holm 家族结论。
