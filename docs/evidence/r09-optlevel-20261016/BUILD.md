# R09 优化级别：12 格构建与产物判定（T22 交付，2026-10-16）

**族外描述。** 本文件只回答"**该级别下 `poly_frommsg` 的机制是否仍然存在**"，
不进入任何 Holm 家族，不改动 M1/M5 既有判定，也不把"某个级别分支消失"写成"泄漏消失"。
合同见 [PLAN.md](PLAN.md)。所有原始反汇编在 [`disasm/`](disasm/)，
所有原始 valgrind 全文在 [`memcheck/`](memcheck/)。

---

## 0. 一句话结论

- **M1 未修版的"秘密相关分支"在四个级别都存在，但形态随级别变化**：
  `-O0` 是**无分支的算术掩码**（源码本来就写成掩码，未优化时保持掩码），
  `-O2/-O3` 被展开成**每比特一次 `testb $imm,(内存)` + 条件跳转**（比 `-Os` 更多条），
  `-Os` 才是教科书形态的 **`bt` + `jae`**。
  **Memcheck 命中数与之一致：`-O0` 0 条，`-O2` 8 条，`-O3` 15 条，`-Os` 1 条**
  （每条约对应 512 次动态命中）。
- **M1 已修版（`982c762`）在四个级别都成立**：`-Os` 把同一个 `bt` 接到 **`setb`** 而不是
  条件跳转，`-O2/-O3` 直接调用 `cmov_int16`（函数体内 `neg;xor;and;xor`），
  `-O0` 是 `xor;sub;and` 掩码；**四个级别 Memcheck 命中数全为 0**。
- **M5 参考路径四个级别都未检出**：`-O2/-O3/-Os` 是
  `movzbl;and;neg;shr $0x10;and $0x681` 的掩码选择，`-O0` 走
  `mlk_value_barrier_u8`；4 格 Memcheck 命中数全为 0。
- **12 格里没有一格出现 `div`/`idiv`**。本项研究的机制（clangover）与 KyberSlash 的除法
  是两回事；"某级别下 `div` 消失"这类跨环境观察在本表里没有出现，也就没有可写的
  跨环境结论。
- **gcc：未做。** 理由见 PLAN §1（clangover 是 Clang 15–18 的代码生成选择，
  GCC 不产生这条路径，做出来不是同一个问题）。

---

## 1. 12 格判定表

`<R>` = `/home/nss-marker/yhr/Cry/r09-optlevel-20261016-85e46c952887`。
"编译命令"列给出**该格实现侧最关键翻译单元**的命令（`poly.c` / `kernel.c`），
完整逐条命令（含封装层、采集件、探针、链接）在每格的
`<R>/build/<cell>/build.log`（M1 的 liboqs 部分另有 `<R>/build/<cell>/liboqs-build.log`）；
同内容的取证副本见 [`disasm/IMPLEMENTATION-COMPILE-COMMANDS.txt`](disasm/IMPLEMENTATION-COMPILE-COMMANDS.txt)。
**除 `-O*` 一个 token 外，其余标志逐字来自冻结树的 `compile_commands.json`。**

| 格 | 模块 | 版本 | 级别 | 实现侧编译命令（要点） | 秘密相关分支? | 掩码 / cmov? | `div`? | Memcheck 命中（唯一位置 / 动态） | ELF sha256 |
|---|---|---|---|---|---|---|---|---|---|
| `m1unfixed-O0` | M1 | liboqs 0.10.0 clangover 未修 | `-O0` | `clang … -O0 -fno-vectorize … -DKYBER_K=3 -c poly.c` | **无**（`movzbl;sar;and $1;xor;sub;and $0x681`） | 算术掩码（`and $0x681`），无 `set*`/`cmov` | 无 | **0 / 0** | `9642e3778aa838d8cfe4bdeba021493efaf31d7df82a55aa7a0563680eb4fe6b` |
| `m1unfixed-O2` | M1 | 同上 | `-O2` | `clang … -O2 -fno-vectorize …` | **有**：`testb $0x1,(%rsi,%rax)` + `je`，每比特一条（8 处） | 无掩码选择（走分支） | 无 | **8 / 512** | `9828434d041d2992368ce0d79ace23e19e1733806c254b15717dfcdd57f642e2` |
| `m1unfixed-O3` | M1 | 同上 | `-O3` | `clang … -O3 -fno-vectorize …` | **有**：同上形态（15 处，含跳转表尾巴） | 无掩码选择（走分支） | 无 | **15 / 512** | `6a310b551f0895cef9f60611a3b9ac70d26d1154eab535b579d8e25c7c506beb` |
| `m1unfixed-Os` | M1 | 同上 | `-Os` | `clang … -Os -fno-vectorize …` | **有**：`bt %ecx,%r8d` + **`jae`**（教科书 clangover 形态） | 无掩码选择（走分支）；分支臂内 `mov $0x681` | 无 | **1 / 512** | `f16ebba0dbf6bf1d9d71c4abc511399fbef59acfb78079f2c1678cb2ae3d19f1` |
| `m1fixed-O0` | M1 | 同上 + `982c762` | `-O0` | `clang … -O0 -fno-vectorize …` | **无** | 掩码：`call cmov_int16`，其体内 `xor;sub;and;xor`（无分支） | 无 | **0 / 0** | `2bab5bce3504e0bf91081630d83a2a9f5f21db1028b9a47178ad216707bf9631` |
| `m1fixed-O2` | M1 | 同上 + `982c762` | `-O2` | `clang … -O2 -fno-vectorize …` | **无** | 掩码：`call cmov_int16`，其体内 `neg;xor;and;xor` | 无 | **0 / 0** | `2993af04337711d57539e4b1dcd10c5cb7bae7fc02df7919eab173913cf561f8` |
| `m1fixed-O3` | M1 | 同上 + `982c762` | `-O3` | `clang … -O3 -fno-vectorize …` | **无** | 掩码：`call cmov_int16`，其体内 `neg;xor;and;xor` | 无 | **0 / 0** | `b2c1fa33ff89d83efb91940f99118b63494bb9508cbdcde1ac67753b2b4204c0` |
| `m1fixed-Os` | M1 | 同上 + `982c762` | `-Os` | `clang … -Os -fno-vectorize …` | **无**：同一个 `bt` 之后接 **`setb %dl`**，不是 `jae` | 掩码：`bt`→`setb`→`call cmov_int16`（体内 `neg` 形式） | 无 | **0 / 0** | `c77c2685b13d47b372f723db0d14958b9b11322fc4856b0f92b299257c178b56` |
| `m5ref-O0` | M5 | mlkem-native `b3ba7b3` reference | `-O0` | `clang-18 … -O0 … -DMLK_CONFIG_FILE="baseline_config.h" -c kernel.c` | **无** | 掩码 + `call mlk_value_barrier_u8`（防优化器把掩码变回分支） | 无 | **0 / 0** | `9a58c8a8bac46ef147be11410c12e52233e3733fa5322548348ee2ffbff89960` |
| `m5ref-O2` | M5 | 同上 | `-O2` | `clang-18 … -O2 …` | **无** | 掩码：`and;movzbl;neg;shr $0x10;and $0x681` | 无 | **0 / 0** | `455ceac593a47c5d87cfc91b2f551a00b384d0608363bc52a0503b5c914d82d6` |
| `m5ref-O3` | M5 | 同上 | `-O3` | `clang-18 … -O3 …` | **无** | 同上 | 无 | **0 / 0** | `d5acbc523ce8847850021fa0cae92872afa9c921fb97fe021b9bae11384f3f01` |
| `m5ref-Os` | M5 | 同上 | `-Os` | `clang-18 … -Os …` | **无** | 同上 | 无 | **0 / 0** | `cf49b17e88cfe3c1aa1cc11a0b531d287e5a0f906ccf933fa36011b1d444c1c7` |

机器可读版：[`disasm/CELLS.tsv`](disasm/CELLS.tsv)（含每个判定的指令级证据串），
逐格详情 [`disasm/CELLS.tsv.details.txt`](disasm/CELLS.tsv.details.txt)，
产物摘要 [`disasm/CELLS.sha256`](disasm/CELLS.sha256)，
Memcheck 汇总 [`memcheck/SUMMARY.tsv`](memcheck/SUMMARY.tsv)。

---

## 2. 构建溯源

| 项 | 值 |
|---|---|
| 新根（唯一写入位置） | `<R>` = `Cry/r09-optlevel-20261016-85e46c952887/` |
| 构建驱动 | `tools/platform_optlevel/build_optlevel_cells.py`，sha256 见每格 `<cell>/generated/build_identity.h` 的 `cell_build_script_sha256` |
| liboqs 归档重建 | `tools/platform_optlevel/build_liboqs_cell.py`（按成员对象摘要映射回冻结编译命令） |
| 判定器 | `tools/platform_optlevel/judge_cells.py`：实现 PLAN §4 的**五个预注册判定位**，外加一个**补充描述列** `mask_neg_and`（不在 PLAN 的预注册规则内，见 §6.2） |
| 编译器 | `/usr/bin/clang-18` = Ubuntu clang 18.1.3 (1ubuntu1)，x86_64 |
| 冻结树（只读） | M1 `Cry/liboqs010-historical-20261015-86131c2/`；M5 `Cry/platform-m5-20261016-30efdf66eb26/source-v2/` |
| 临时目录 | `TMPDIR/TMP/TEMP=<R>/tmp`、`XDG_CACHE_HOME=<R>/cache`（`/tmp` 零落盘） |
| 唯一变量 | 每个翻译单元的 `-O*` 一个 token；其余标志逐字沿用冻结 `compile_commands.json` |

**与冻结树构建的口径差别（写清楚）**：冻结 M1 是**混合级别**（liboqs `-Os`，
封装层与采集件 `-O2`）；本轮 12 格是**整树同一级别**。所以 `m1unfixed-Os` 与冻结 M1
只在封装层/采集件的级别上不同（`-O2`→`-Os`），实现侧 liboqs 对象级别相同；
`m1fixed-Os` 同理。这一差别在 PLAN §2.2 里已预先写明。

**冻结树未被改写**：本轮的 `build_identity.h` 生成在 `<cell>/generated/`，
只通过 `-I` 前置覆盖冻结树的那一份；冻结树的源码、对象、归档与 `build_identity.h`
逐字节未动（`<R>/source/`、`<R>/build/` 之外的路径只有读操作）。

**M1 liboqs 归档重建的映射口径**：`ar` 归档里 `kem.c.o` 这类同名成员出现两次，
用 `ar p <name>` 只会取到第一份；本脚本直接按 `ar` 头解析、逐成员按 **sha256**
匹配回 `compile_commands.json` 的条目，保证 24 个成员不重不漏
（每格 `liboqs-build.log` 里 `member_count=24`，且给出归档自身的 sha256）。

**gcc 未做的理由**：见 §0 与 PLAN §1。

---

## 3. 反汇编逐格说明（关键指令序列）

以下片段逐字取自 [`disasm/`](disasm/) 的原始 `objdump -d` 输出（`--no-show-raw-insn`
与带机器码两份都在）。

### 3.1 M1 未修：同一段源码，四个级别四种形态

```
-O0  (and $0x681,无分支)            -Os  (bt + jae,教科书 clangover)
  5fe9: mov -0x18(%rbp),%ecx          39ba: bt  %ecx,%r8d
  5fec: sar %cl,%eax                  39be: jae 39c5 <...>
  5fee: and $0x1,%eax                 39c0: mov $0x681,%edx
  5ff6: sub %ecx,%eax                 39c5: mov %dx,(%rdi,%rcx,2)
  6000: and $0x681,%eax

-O2  (testb $imm,(mem) + je,每比特一条)  -O3 (同形态,展开更多)
  4794: testb $0x1,(%rsi,%rax,1)          4b14: testb $0x1,(%rsi,%rax,1)
  4798: mov $0x0,%ecx                     4b18: mov $0x0,%ecx
  479d: je 47a4 <...>                     4b1d: jne 4bb0 <...>
  479f: mov $0x681,%ecx                   4b23: mov %cx,-0xe(%rdi)
  47a4: mov %cx,-0xe(%rdi)                ...
```

**要点**：`-O0` 之所以"没有泄漏"是因为**未优化时源码级的算术掩码被原样保留**；
一旦开启优化，Clang 反而把它选成了分支。这不是"级别越高越安全"，
也不是"低级别安全"——**同一份源码在 `-O0` 与 `-O2/-O3/-Os` 下的安全性由代码生成决定**。

### 3.2 M1 已修：`bt` 之后接 `setb`，不再接条件跳转

```
-Os（同一个 bt，跳转换成 setb）
  39e9: bt   %r13d,%eax
  39ed: setb %dl
  39f3: mov  $0x681,%esi
  39f8: call 276d <...cmov_int16>

cmov_int16（-O2/-O3/-Os 未内联；函数名里的 "cmov" 是名字，不是 x86 cmov 指令）
  2ef4: neg  %edx
  2ef6: movzwl (%rdi),%eax
  2ef9: xor  %eax,%esi
  2efb: and  %edx,%esi
  2efd: xor  %eax,%esi
  2eff: mov  %si,(%rdi)
```

**要点**：12 格里 `cmov` 指令计数**全为 0**。"是否为 `setb`/`cmov` 掩码形式"的答案
必须按实际指令写：修复版是 **`setb` + 算术掩码（`neg`/`xor`/`and`）**，
以及 `-O2/-O3` 下对 `cmov_int16` 的调用；它**不含** x86 `cmov` 指令，
但**不含任何秘密相关条件跳转**——这正是修复要保证的性质。

### 3.3 M5 参考：四级都是掩码，`-O0` 另有值屏障

```
-O2  256c: and (%rsi,%rax,1),%cl         -Os  2048: mov $0x1,%edx
     2578: movzbl %cl,%ecx                    204d: shl %cl,%edx
     2578: neg %ecx                           204f: and (%rsi,%rax,1),%dl
     257a: shr $0x10,%ecx                     2055: neg %edx
     257d: and $0x681,%ecx                    2057: shr $0x10,%edx
     2583: mov %cx,-0xe(%rdi)                 205a: and $0x681,%edx
```

`-O0` 走 `call mlk_value_barrier_u8`（上游刻意插入的值屏障，防止优化器把掩码改写成
分支）。四级 `conditional_jumps` 计数只剩 1–2 条**循环计数**跳转，无秘密相关跳转。

---

## 3.1 采集件资格（12/12 通过，非采数）

12 格的 `measure` 各跑一次小样本（`31337`、每类 5 次、不锁频、不写频率）：

| 判据 | 结果 |
|---|---|
| 退出码 | 12/12 = 0 |
| CSV 表头逐字一致 | 12/12 = yes |
| CSV 行数 = 1 + 5×5 | 12/12 = 26 |
| meta `sample_count` | 12/12 = 25（= 5 类 × 5） |
| meta `time_unit` | 12/12 = `ns` |

逐格原始 CSV/meta 与汇总在 [`qualification/`](qualification/)
（`SUMMARY.tsv` 为一行一格的判定）。这份资格只证明采集件能跑、格式正确，
**不是采数、不含频率合同、也不构成任何统计结论**。

---

## 4. Memcheck 秘密标记逐格结果

| 项 | 值 |
|---|---|
| 工具 | Valgrind 3.22.0（`/usr/bin/valgrind`） |
| 命令 | `valgrind --tool=memcheck --error-exitcode=0 --num-callers=24 --track-origins=no <probe>` |
| M1 探针 | 冻结树既有 `tools/historical_poison.c` 编到该格级别：把 `sk` 前 1152 字节（indcpa 私钥）标为未初始化；公开封装密钥与公开密文不标 |
| M5 探针 | 冻结树既有 `tools/platform_m5/poison.c` 编到该格级别（`--poison`）：indcpa 私钥 1152 字节 + 拒绝秘密 `z`（偏移 2368，32 字节） |
| 统计 | `Conditional jump or move depends on uninitialised value(s)` 与 `Use of uninitialised value` 两类；报**唯一错误位置数（contexts）**与**动态报错次数（errors）** |

| 格 | 命中（唯一位置） | 动态次数 | 报错位置（valgrind 栈顶函数） |
|---|---:|---:|---|
| `m1unfixed-O0` | 0 | 0 | — |
| `m1unfixed-O2` | 8 | 512 | `pqcrystals_ml_kem_768_ipd_ref_poly_frommsg`（`poly.c:179`） |
| `m1unfixed-O3` | 15 | 512 | 同上 |
| `m1unfixed-Os` | 1 | 512 | 同上 |
| `m1fixed-O0/O2/O3/Os` | 0 | 0 | — |
| `m5ref-O0/O2/O3/Os` | 0 | 0 | — |

**命中数是"唯一错误位置数"，不是动态执行次数**；两者都列出来。
动态次数 512 的来源可核对：`poly_frommsg` 每次调用 32 字节 × 8 比特 = 256 次位判定，
探针跑 2 次完整解封装（`message-zero` / `message-ones`）→ 256 × 2 = 512。

`-O2` 的 8 个唯一位置是展开后的 8 条 `je`（每字节一条，尾字节复用同一段循环），
`-O3` 的 15 条来自额外展开。原始全文：
[`memcheck/m1unfixed-O2.valgrind.txt`](memcheck/m1unfixed-O2.valgrind.txt)、
[`memcheck/m1unfixed-O3.valgrind.txt`](memcheck/m1unfixed-O3.valgrind.txt)、
[`memcheck/m1unfixed-Os.valgrind.txt`](memcheck/m1unfixed-Os.valgrind.txt)；
其余各格同名 `.valgrind.txt`。汇总：[`memcheck/SUMMARY.tsv`](memcheck/SUMMARY.tsv)。

**口径限制（不夸大）**：动态检查只覆盖本固定产物、本探针输入、本工具能力。
**"0 命中"不等于恒时**；`-O0` 的 0 命中恰恰是因为那个级别下掩码没被改写成分支，
而不是"秘密依赖不存在"。

---

## 5. 结论（只写"机制在该级别是否存在"）

1. **clangover 机制（`bt` + `jae` 分支式 `poly_frommsg`）只在 M1 未修版的 `-Os`
   出现**（`bt_jae=yes`）。
2. **同一份未修源码在 `-O2/-O3` 下也是不安全的，只是形态不同**：
   被展开成每比特一条 `testb $imm,(内存)` + 条件跳转，Memcheck 唯一位置数反而更多
   （8 / 15 对 `-Os` 的 1）。把"clangover 只在 `-Os` 出现"读成"`-O2/-O3` 安全"
   是**错的**；本表按判据分开写，合起来看。
3. **M1 未修版在 `-O0` 下没有秘密相关分支**（源码级掩码被保留），
   所以"未修版一定泄漏"也不成立——**必须按级别与产物说**。
4. **`982c762` 修复在四个级别都成立**：`-Os` 同一处 `bt` 改为 `setb`，
   `-O2/-O3` 走 `cmov_int16`，`-O0` 走 `xor;sub;and`；四级 Memcheck 命中均为 0。
5. **M5 参考路径在四个级别都未检出**，四级都是掩码选择（`-O0` 另有值屏障）。
6. **12 格无 `div`/`idiv`**。本项没有出现"某级别下除法消失"的情形，
   因此不产生跨环境结论；若将来把 M2 的除法纳入同表，某个级别下 `div` 消失
   只说明编译器在该级别换了实现，要按跨环境结论如实写，不写成"泄漏消失"。

---

## 6. 已知限制

1. 只覆盖 **clang-18 18.1.3 / x86_64 / 这台 Ryzen 9 9950X**；别的编译器、架构、
   `-march` 都在结论范围之外。**gcc 未做**（理由见 §0）。
2. 反汇编判定看的是**产物里的指令形态**。`mask_neg_and`（"先取负再 `and`"计数）
   **不是 PLAN §4 的预注册判据**，而是判定脚本额外输出的一列描述量，
   用于给"掩码形式"提供机器可读线索；结论只建立在 PLAN §4 的五个判定位
   （`bt_jae` / `per_bit_test_jcc` / `secret_division` / `setcc`+`cmov` / `conditional_jumps`）
   与 §4.2 的 Memcheck 口径上。该补充列还有一个已知的漏报：
   `-O0` 会插入栈上存取往返，把 `and` 推出 5 条指令的搜索窗口而计成 0
   （`m1fixed-O0` 的辅助函数正是这种情况），此时以 §3 的原始指令序列为准，
   **不把这一列的 0 当作"没有掩码"**。
3. Memcheck 的命中数受"探针标了什么"限制：M1 只标 indcpa 私钥（不标 `z`），
   M5 同时标 indcpa 私钥与 `z`。两臂的命中数**不能直接互比大小**，只能各自与
   同一臂的其他级别比，或与同级别另一版本比。
4. 本文件**不含任何计时数据**；优化级别的锁频计时由 T23 采、T24 出结论。

---

## 7. 与 T23 的衔接

T23 用每格自己的 `measure`（同一份 `src/measure.c` 在该级别编译）采主类对
`message-zero` vs `message-ones` 各 10000 次 × 3 种子（s1/s2 = CPU2，s3 = CPU6），
共 36 次控制器运行，命令见 [RUNS.sh](RUNS.sh)，预算与停止规则见 [PLAN.md](PLAN.md) §6–§7。
**T23 的计时数据同样族外、不进 Holm**，也不得用来给上面 §5 的机制判定"加分"。
