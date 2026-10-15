# R09 优化级别对照结论（T24 交付，2026-10-16）

**族外探索。** 本文件把 T22 的 12 格产物判定（反汇编 / Memcheck，见 [BUILD.md](BUILD.md)）
与 T23 的锁频实测（[PLAN.md](PLAN.md) §5–§6）合成一张表，并回答三个问题。
**本组数据不进任何 Holm 家族**，不做多重比较校正，也不改动 M1/M5 的既有家族判定。

> 口径限制（先写在最前面）：
> 1. **优化级别是族外探索**，不是预注册的家族检验；本表任何"未检出"都**不等于该级别安全**。
> 2. M1 未修版在 `-O0` 没有秘密相关分支，是**"该级别下这个机制没有出现"**（源码级算术掩码被原样保留），
>    不是"这份源码安全"；换编译器、换级别、换 `-march` 都不在本结论范围内。
> 3. 计时只说明**开销/可观测差异**，不说明安全性；反汇编与 Memcheck 只说明**产物形态与动态命中**。
>    三类证据分列，互不替代，也都不构成恒时证明。

---

## 1. 数据来源与完整性（只读已采集数据）

| 项 | 值 |
|---|---|
| 合同 | [PLAN.md](PLAN.md)，sha256 `732e07c88bf228f21a7be92bb5a4ee5d3a924ae0b6e63e8c7207f663ca40a6115`（与文件头声明的 `732e07c8…` 一致，本次实读） |
| 计时数据 | `remote/R09/<run-name>/<run-name>.csv.gz`（36 个运行 = 12 格 × 3 种子）+ 同名 `.meta` |
| 判定数据 | [`disasm/CELLS.tsv`](disasm/CELLS.tsv)、[`disasm/CELLS.sha256`](disasm/CELLS.sha256)、[`memcheck/SUMMARY.tsv`](memcheck/SUMMARY.tsv)（T22 产出） |
| 计算工具 | `tools/platform_optlevel/analyze_r09_optlevel.py`（本仓库，可复跑） |
| 机读结果 | [`result.csv`](result.csv)（每次运行一行，36 行）、[`result.csv.cells.csv`](result.csv.cells.csv)（每格一行，12 行） |
| 图 | [`figures/r09_delta_by_optlevel.pdf`](figures/r09_delta_by_optlevel.pdf)（矢量）、[`figures/r09_delta_by_optlevel.png`](figures/r09_delta_by_optlevel.png)（预览） |

**已执行且未计入的无效运行（如实列出，不隐藏）**

| run-name | 归档路径 | 判据 | 处理 |
|---|---|---|---|
| `r09-os-m1unfixed-s2`（第 1 次尝试） | `remote/R09/failed/r09-os-m1unfixed-s2-attempt1/` | `terminal.json`：`reason=frequency_probe_rejected`；`restore_match=yes`、`worker_drained=true`，**worker 未启动、无 CSV** | 不计入；换名 `r09-os-m1unfixed-s2r2` 重跑并计入 |

该次被拒的直接数字（`failed/.../controller/entry-probes.json`，20 次 50 ms 采样）：
`cur_khz` 最小 4282032、最大 4336661、**跨度 54629 kHz > 合同允许的 50000 kHz**；
20 个值**都在** ±2% 带（4214000–4386000）内，是**跨度**判据触发拒绝。

**本次能核到与不能核到**：归档里 36 个有效 run 只有 CSV + meta，**没有** controller 目录，
因此 `terminal.json` 的 `reason/worker_exit_code/worker_drained/restore_match` 四判据
**无法从已拉回副本核对**（PLAN §6 要求这四条同时成立才计入）；本文件按"主控判定有效后归档"使用，
并把这条缺口写明。R08 同一情况。

**产物一致性（可核的部分）**：12 格的 3 个种子各自使用**同一份** `measure` 二进制
（meta `executable_digest` 按 SHA3-256，每格 3 个种子逐字相同），因此同格三种子可合并。
T22 判定产物在 `disasm/CELLS.sha256` 里记的是 **sha256**，与 meta 自报的 **SHA3-256**
**算法不同**，两者只能并列记录，**不能断言"计时用的就是被判定那一个二进制"**——
本表按"同一格子构建产物"使用，这一条属于口径缺口，不掩盖。

---

## 2. 合并表：产物判定 + 锁频实测

**判定列**（T22，逐字取自 `disasm/CELLS.tsv`）：`bt_jae` = 函数体内 `bt` 后 4 条内条件跳转；
`per_bit_test_jcc` = `testb $imm,(内存)` 后 2 条内条件跳转；`div` = `div/idiv` 计数；
`cmov/setcc` = 掩码物化指令计数；`helper_*` = M1 已修版未内联的 `…_ref_cmov_int16` 辅助函数；
Memcheck = 唯一错误位置数 / 动态报错次数（[`memcheck/SUMMARY.tsv`](memcheck/SUMMARY.tsv)）。

**计时列**（T23，本工具计算）：主类对 `message-zero` vs `message-ones`，
Δ = mean(zero) - mean(ones)（**Δ<0 表示 zero 更快**），每种子 10000 次/类；
`Δ̄` = 3 个种子 Δ 的均值，CI = 对 3 个种子 Δ 做 10000 次 bootstrap 的 95% 区间（刻画种子间离散，
3 个重复下区间会很窄，见 §4）；`逐种子` = 3 个 Δ，`CI⊄0 的种子数` = 该种子自身
Welch 正态近似 95% CI 不含 0 的个数。

| 格 | 模块/版本 | 级别 | 秘密相关分支? | 掩码/cmov? | `div`? | Memcheck 命中（位置/动态） | n/类 | 逐种子 Δ (ns) | Δ̄ (ns) | 95% CI (ns) | CI⊄0 的种子数 |
|---|---|---|---|---|---|---|---|---|---|---|---|
| `m1unfixed-O0` | M1 未修 | `-O0` | **无**（`movzbl;sar;and $1;xor;sub;and $0x681`） | 算术掩码，无 `set*`/`cmov` | 0 | **0 / 0** | 10000 | +3.04 / +86.47 / +23.27 | **+37.59** | [**+3.04, +86.47**] | 0 / 3 |
| `m1unfixed-O2` | M1 未修 | `-O2` | **有**：`testb $0x1,(%rsi,%rax)` + `je`，每比特一条（8 处） | 无掩码选择（走分支） | 0 | **8 / 512** | 10000 | -22.41 / +0.20 / -11.85 | **-11.35** | [-22.41, +0.20] | 0 / 3 |
| `m1unfixed-O3` | M1 未修 | `-O3` | **有**：同上形态（15 处） | 无掩码选择（走分支） | 0 | **15 / 512** | 10000 | +2.68 / -17.64 / -5.33 | **-6.76** | [-17.64, +2.68] | 1 / 3 |
| `m1unfixed-Os` | M1 未修 | `-Os` | **有**：`bt %ecx,%r8d` + **`jae`**（教科书 clangover 形态） | 无掩码选择（走分支） | 0 | **1 / 512** | 10000 | -20.70 / -12.51 / -53.47 | **-28.90** | [**-53.47, -12.51**] | **2 / 3** |
| `m1fixed-O0` | M1 已修 `982c762` | `-O0` | **无** | 掩码：`call cmov_int16`（体内 `xor;sub;and;xor`） | 0 | **0 / 0** | 10000 | -39.36 / -19.10 / -16.16 | **-24.87** | [-39.36, -16.16] | 0 / 3 |
| `m1fixed-O2` | M1 已修 | `-O2` | **无** | 掩码：`call cmov_int16`（体内 `neg;xor;and;xor`） | 0 | **0 / 0** | 10000 | -4.55 / +18.00 / -15.94 | **-0.83** | [-15.94, +18.00] | 0 / 3 |
| `m1fixed-O3` | M1 已修 | `-O3` | **无** | 同上 | 0 | **0 / 0** | 10000 | -0.25 / -10.56 / -13.12 | **-7.98** | [-13.12, -0.25] | 0 / 3 |
| `m1fixed-Os` | M1 已修 | `-Os` | **无**：同一个 `bt` 后接 **`setb %dl`**，不是 `jae` | `bt`→`setb`→`call cmov_int16` | 0 | **0 / 0** | 10000 | -6.89 / -10.88 / +3.56 | **-4.74** | [-10.88, +3.56] | 0 / 3 |
| `m5ref-O0` | M5 `b3ba7b3` reference | `-O0` | **无** | 掩码 + `call mlk_value_barrier_u8` | 0 | **0 / 0** | 10000 | +2.56 / -24.09 / +14.64 | **-2.30** | [-24.09, +14.64] | 0 / 3 |
| `m5ref-O2` | M5 reference | `-O2` | **无** | 掩码：`and;movzbl;neg;shr $0x10;and $0x681` | 0 | **0 / 0** | 10000 | -1.61 / +0.84 / +0.12 | **-0.22** | [-1.61, +0.84] | 0 / 3 |
| `m5ref-O3` | M5 reference | `-O3` | **无** | 同上 | 0 | **0 / 0** | 10000 | -2.00 / -1.33 / -3.93 | **-2.42** | [-3.93, -1.33] | 0 / 3 |
| `m5ref-Os` | M5 reference | `-Os` | **无** | 同上 | 0 | **0 / 0** | 10000 | +4.85 / -18.89 / -0.83 | **-4.95** | [-18.89, +4.85] | 1 / 3 |

**逐次运行明细（含每类的绝对均值、Welch 原始 p、CI、CPU）**：[`result.csv`](result.csv)。
**12 格没有一格出现 `div`/`idiv`**，也没有 x86 `cmov` 指令（M1 修复版的 "cmov" 是**函数名**，
不是 `cmov` 指令）；这两点与 [BUILD.md](BUILD.md) §0/§3 一致。

**CPU 分配**（PLAN §5.2）：每格 `s1`/`s2` 在 **CPU2**，`s3` 在 **CPU6**。
因此"由 3 个种子合并的 Δ̄"混了两个物理核，**不是同核重复**；表里的 CI 已把这一离散含进去，
但把它读成"同一核上的重复测量精度"是错的。

### 2.1 产物溯源（两种摘要算法并列，不做等式断言）

| 格 | 判定产物 sha256（T22 `disasm/CELLS.sha256`） | 计时产物 digest（T23 meta，自报 SHA3-256） |
|---|---|---|
| `m1unfixed-O0` | `9642e3778aa838d8cfe4bdeba021493efaf31d7df82a55aa7a0563680eb4fe6b` | `b80a98bce6f8d97d52d405ef0f26c8abddf54dc399300fc56d95597a6b59fd29` |
| `m1unfixed-O2` | `9828434d041d2992368ce0d79ace23e19e1733806c254b15717dfcdd57f642e2` | `2d1bfe9357b25e03e0284f2e0aaa2f832cbf40636f1a41c7729a04c0af6db55c` |
| `m1unfixed-O3` | `6a310b551f0895cef9f60611a3b9ac70d26d1154eab535b579d8e25c7c506beb` | `2fad3c57d38b2180c7d9aff4154c95083750862628d38f1f7c71444bf98a3fcf` |
| `m1unfixed-Os` | `f16ebba0dbf6bf1d9d71c4abc511399fbef59acfb78079f2c1678cb2ae3d19f1` | `b71073a65ad99a71aa6d7e9a916cdcf4b9d7d45a5ffffa818c24fb4786514a1c` |
| `m1fixed-O0` | `2bab5bce3504e0bf91081630d83a2a9f5f21db1028b9a47178ad216707bf9631` | `4a37aaecd2294f4f5240fe228ac18e302ae4fb2f5eede7dcdb041c7476cdb61d` |
| `m1fixed-O2` | `2993af04337711d57539e4b1dcd10c5cb7bae7fc02df7919eab173913cf561f8` | `3f4833744c44592690a54b99a8db5582e00c5201702a0ca9e205fabc7fcd34a1` |
| `m1fixed-O3` | `b2c1fa33ff89d83efb91940f99118b63494bb9508cbdcde1ac67753b2b4204c0` | `ed15cb896554dd982c75d7439abb48083597e5860a8d869f7ecc0eff2934d300` |
| `m1fixed-Os` | `c77c2685b13d47b372f723db0d14958b9b11322fc4856b0f92b299257c178b56` | `2e9de8fd63147746a68d52aa94e8739b97af68e474b5cb7e5815b0a90d233759` |
| `m5ref-O0` | `9a58c8a8bac46ef147be11410c12e52233e3733fa5322548348ee2ffbff89960` | `c2a39b2f510e2f062f16a3c9a7827733fc28f2e83f007f404a7c8db1400a8954` |
| `m5ref-O2` | `455ceac593a47c5d87cfc91b2f551a00b384d0608363bc52a0503b5c914d82d6` | `3366ab6d80a45c8761d8972f4f4d9c91f6da6103c19cd2eec2d6e8be3eab9445` |
| `m5ref-O3` | `d5acbc523ce8847850021fa0cae92872afa9c921fb97fe021b9bae11384f3f01` | `1568d1251cac8e7218a5d8b8b57fa9ed1bfae94979a8b999d947356f4122a499` |
| `m5ref-Os` | `cf49b17e88cfe3c1aa1cc11a0b531d287e5a0f906ccf933fa36011b1d444c1c7` | `47db4c668f0b65850748ad79eafb9b501d42b75052dcc1317baad3316b6e2504` |

同格 3 个种子的 `executable_digest` 逐字相同（本工具已断言），因此"同格三种子"用的是同一份二进制；
但 T22 判定产物记的是 **sha256**、meta 自报 **SHA3-256**，**算法不同**，
本表**只并列记录，不断言"计时用的就是被判定那一个二进制"**。

### 2.2 逐次运行清单（36 次有效运行，每次指回原始 CSV）

| 格 | run-name | 种子 | CPU | zero 均值 ns | ones 均值 ns | Δ ns | 原始 CSV（相对仓库根） |
|---|---|---:|---|---:|---:|---:|---|
| `m1unfixed-O0` | `r09-o0-m1unfixed-s1` | 1 | cpu2 | 175,187.72 | 175,184.69 | +3.035 | `docs/evidence/r09-optlevel-20261016/remote/R09/r09-o0-m1unfixed-s1/r09-o0-m1unfixed-s1.csv.gz` |
| `m1unfixed-O0` | `r09-o0-m1unfixed-s2` | 2 | cpu2 | 175,033.95 | 174,947.48 | +86.471 | `docs/evidence/r09-optlevel-20261016/remote/R09/r09-o0-m1unfixed-s2/r09-o0-m1unfixed-s2.csv.gz` |
| `m1unfixed-O0` | `r09-o0-m1unfixed-s3` | 3 | cpu6 | 174,764.31 | 174,741.04 | +23.265 | `docs/evidence/r09-optlevel-20261016/remote/R09/r09-o0-m1unfixed-s3/r09-o0-m1unfixed-s3.csv.gz` |
| `m1unfixed-O2` | `r09-o2-m1unfixed-s1` | 1 | cpu2 | 52,343.81 | 52,366.22 | -22.409 | `docs/evidence/r09-optlevel-20261016/remote/R09/r09-o2-m1unfixed-s1/r09-o2-m1unfixed-s1.csv.gz` |
| `m1unfixed-O2` | `r09-o2-m1unfixed-s2` | 2 | cpu2 | 52,545.12 | 52,544.92 | +0.198 | `docs/evidence/r09-optlevel-20261016/remote/R09/r09-o2-m1unfixed-s2/r09-o2-m1unfixed-s2.csv.gz` |
| `m1unfixed-O2` | `r09-o2-m1unfixed-s3` | 3 | cpu6 | 52,049.63 | 52,061.48 | -11.850 | `docs/evidence/r09-optlevel-20261016/remote/R09/r09-o2-m1unfixed-s3/r09-o2-m1unfixed-s3.csv.gz` |
| `m1unfixed-O3` | `r09-o3-m1unfixed-s1` | 1 | cpu2 | 51,775.28 | 51,772.61 | +2.677 | `docs/evidence/r09-optlevel-20261016/remote/R09/r09-o3-m1unfixed-s1/r09-o3-m1unfixed-s1.csv.gz` |
| `m1unfixed-O3` | `r09-o3-m1unfixed-s2` | 2 | cpu2 | 51,422.90 | 51,440.54 | -17.645 | `docs/evidence/r09-optlevel-20261016/remote/R09/r09-o3-m1unfixed-s2/r09-o3-m1unfixed-s2.csv.gz` |
| `m1unfixed-O3` | `r09-o3-m1unfixed-s3` | 3 | cpu6 | 51,725.39 | 51,730.71 | -5.326 | `docs/evidence/r09-optlevel-20261016/remote/R09/r09-o3-m1unfixed-s3/r09-o3-m1unfixed-s3.csv.gz` |
| `m1unfixed-Os` | `r09-os-m1unfixed-s1` | 1 | cpu2 | 55,527.77 | 55,548.48 | -20.704 | `docs/evidence/r09-optlevel-20261016/remote/R09/r09-os-m1unfixed-s1/r09-os-m1unfixed-s1.csv.gz` |
| `m1unfixed-Os` | `r09-os-m1unfixed-s2r2` | 2 | cpu2 | 55,481.70 | 55,494.22 | -12.512 | `docs/evidence/r09-optlevel-20261016/remote/R09/r09-os-m1unfixed-s2r2/r09-os-m1unfixed-s2r2.csv.gz` |
| `m1unfixed-Os` | `r09-os-m1unfixed-s3` | 3 | cpu6 | 55,673.11 | 55,726.57 | -53.469 | `docs/evidence/r09-optlevel-20261016/remote/R09/r09-os-m1unfixed-s3/r09-os-m1unfixed-s3.csv.gz` |
| `m1fixed-O0` | `r09-o0-m1fixed-s1` | 1 | cpu2 | 178,436.95 | 178,476.31 | -39.361 | `docs/evidence/r09-optlevel-20261016/remote/R09/r09-o0-m1fixed-s1/r09-o0-m1fixed-s1.csv.gz` |
| `m1fixed-O0` | `r09-o0-m1fixed-s2` | 2 | cpu2 | 179,289.24 | 179,308.34 | -19.097 | `docs/evidence/r09-optlevel-20261016/remote/R09/r09-o0-m1fixed-s2/r09-o0-m1fixed-s2.csv.gz` |
| `m1fixed-O0` | `r09-o0-m1fixed-s3` | 3 | cpu6 | 179,906.42 | 179,922.58 | -16.164 | `docs/evidence/r09-optlevel-20261016/remote/R09/r09-o0-m1fixed-s3/r09-o0-m1fixed-s3.csv.gz` |
| `m1fixed-O2` | `r09-o2-m1fixed-s1` | 1 | cpu2 | 53,258.97 | 53,263.52 | -4.552 | `docs/evidence/r09-optlevel-20261016/remote/R09/r09-o2-m1fixed-s1/r09-o2-m1fixed-s1.csv.gz` |
| `m1fixed-O2` | `r09-o2-m1fixed-s2` | 2 | cpu2 | 53,252.83 | 53,234.82 | +18.000 | `docs/evidence/r09-optlevel-20261016/remote/R09/r09-o2-m1fixed-s2/r09-o2-m1fixed-s2.csv.gz` |
| `m1fixed-O2` | `r09-o2-m1fixed-s3` | 3 | cpu6 | 53,490.78 | 53,506.72 | -15.941 | `docs/evidence/r09-optlevel-20261016/remote/R09/r09-o2-m1fixed-s3/r09-o2-m1fixed-s3.csv.gz` |
| `m1fixed-O3` | `r09-o3-m1fixed-s1` | 1 | cpu2 | 51,931.68 | 51,931.93 | -0.253 | `docs/evidence/r09-optlevel-20261016/remote/R09/r09-o3-m1fixed-s1/r09-o3-m1fixed-s1.csv.gz` |
| `m1fixed-O3` | `r09-o3-m1fixed-s2` | 2 | cpu2 | 51,987.15 | 51,997.71 | -10.558 | `docs/evidence/r09-optlevel-20261016/remote/R09/r09-o3-m1fixed-s2/r09-o3-m1fixed-s2.csv.gz` |
| `m1fixed-O3` | `r09-o3-m1fixed-s3` | 3 | cpu6 | 52,061.89 | 52,075.01 | -13.123 | `docs/evidence/r09-optlevel-20261016/remote/R09/r09-o3-m1fixed-s3/r09-o3-m1fixed-s3.csv.gz` |
| `m1fixed-Os` | `r09-os-m1fixed-s1` | 1 | cpu2 | 56,261.33 | 56,268.23 | -6.894 | `docs/evidence/r09-optlevel-20261016/remote/R09/r09-os-m1fixed-s1/r09-os-m1fixed-s1.csv.gz` |
| `m1fixed-Os` | `r09-os-m1fixed-s2` | 2 | cpu2 | 56,372.38 | 56,383.26 | -10.876 | `docs/evidence/r09-optlevel-20261016/remote/R09/r09-os-m1fixed-s2/r09-os-m1fixed-s2.csv.gz` |
| `m1fixed-Os` | `r09-os-m1fixed-s3` | 3 | cpu6 | 56,223.80 | 56,220.24 | +3.563 | `docs/evidence/r09-optlevel-20261016/remote/R09/r09-os-m1fixed-s3/r09-os-m1fixed-s3.csv.gz` |
| `m5ref-O0` | `r09-o0-m5ref-s1` | 1 | cpu2 | 148,402.60 | 148,400.04 | +2.555 | `docs/evidence/r09-optlevel-20261016/remote/R09/r09-o0-m5ref-s1/r09-o0-m5ref-s1.csv.gz` |
| `m5ref-O0` | `r09-o0-m5ref-s2` | 2 | cpu2 | 148,544.00 | 148,568.09 | -24.085 | `docs/evidence/r09-optlevel-20261016/remote/R09/r09-o0-m5ref-s2/r09-o0-m5ref-s2.csv.gz` |
| `m5ref-O0` | `r09-o0-m5ref-s3` | 3 | cpu6 | 148,244.94 | 148,230.30 | +14.638 | `docs/evidence/r09-optlevel-20261016/remote/R09/r09-o0-m5ref-s3/r09-o0-m5ref-s3.csv.gz` |
| `m5ref-O2` | `r09-o2-m5ref-s1` | 1 | cpu2 | 29,390.30 | 29,391.91 | -1.609 | `docs/evidence/r09-optlevel-20261016/remote/R09/r09-o2-m5ref-s1/r09-o2-m5ref-s1.csv.gz` |
| `m5ref-O2` | `r09-o2-m5ref-s2` | 2 | cpu2 | 29,341.36 | 29,340.52 | +0.842 | `docs/evidence/r09-optlevel-20261016/remote/R09/r09-o2-m5ref-s2/r09-o2-m5ref-s2.csv.gz` |
| `m5ref-O2` | `r09-o2-m5ref-s3` | 3 | cpu6 | 29,349.54 | 29,349.42 | +0.120 | `docs/evidence/r09-optlevel-20261016/remote/R09/r09-o2-m5ref-s3/r09-o2-m5ref-s3.csv.gz` |
| `m5ref-O3` | `r09-o3-m5ref-s1` | 1 | cpu2 | 26,159.60 | 26,161.60 | -1.996 | `docs/evidence/r09-optlevel-20261016/remote/R09/r09-o3-m5ref-s1/r09-o3-m5ref-s1.csv.gz` |
| `m5ref-O3` | `r09-o3-m5ref-s2` | 2 | cpu2 | 26,172.00 | 26,173.33 | -1.332 | `docs/evidence/r09-optlevel-20261016/remote/R09/r09-o3-m5ref-s2/r09-o3-m5ref-s2.csv.gz` |
| `m5ref-O3` | `r09-o3-m5ref-s3` | 3 | cpu6 | 26,165.46 | 26,169.40 | -3.932 | `docs/evidence/r09-optlevel-20261016/remote/R09/r09-o3-m5ref-s3/r09-o3-m5ref-s3.csv.gz` |
| `m5ref-Os` | `r09-os-m5ref-s1` | 1 | cpu2 | 35,192.09 | 35,187.24 | +4.853 | `docs/evidence/r09-optlevel-20261016/remote/R09/r09-os-m5ref-s1/r09-os-m5ref-s1.csv.gz` |
| `m5ref-Os` | `r09-os-m5ref-s2` | 2 | cpu2 | 35,264.78 | 35,283.66 | -18.888 | `docs/evidence/r09-optlevel-20261016/remote/R09/r09-os-m5ref-s2/r09-os-m5ref-s2.csv.gz` |
| `m5ref-Os` | `r09-os-m5ref-s3` | 3 | cpu6 | 35,291.11 | 35,291.94 | -0.828 | `docs/evidence/r09-optlevel-20261016/remote/R09/r09-os-m5ref-s3/r09-os-m5ref-s3.csv.gz` |

---

## 3. 三个问题的答案（只用数据说话）

### 问题 1：哪些优化级别上 M1 未修版出现数据相关分支？端到端哪些级别可区分、哪些不可区分？

**产物侧（已判定，T22）**：教科书式 `bt` + `jae` **只在 `-Os`** 出现；
`-O2`/`-O3` **同样有秘密相关分支**，形态是每比特一条 `testb $imm,(内存)` + 条件跳转
（Memcheck 唯一位置数 8 / 15，比 `-Os` 的 1 更多）；`-O0` 该级别下**没有**秘密相关分支
（源码级算术掩码被原样保留）。

**端到端侧（本次实测）**，按"3 个种子里有几种子自身 95% CI 不含 0"分档：

| 级别 | 逐种子 Δ | Δ̄ [CI] | 判定（只描述本次可观测性） |
|---|---|---|---|
| `-O0` | +3.04 / +86.47 / +23.27 | +37.59 [+3.04, +86.47] | **不可区分**：3 个种子全部含 0，且方向与分支代价模型相反（该级别没有分支，符号散乱） |
| `-O2` | -22.41 / +0.20 / -11.85 | -11.35 [-22.41, +0.20] | **不可区分**：3 个种子全部含 0；均值方向为负但区间跨 0 |
| `-O3` | +2.68 / -17.64 / -5.33 | -6.76 [-17.64, +2.68] | **不可区分（边缘）**：只有 1/3 种子 CI 不含 0，区间上界 +2.68 紧贴 0 |
| `-Os` | -20.70 / -12.51 / -53.47 | **-28.90 [-53.47, -12.51]** | **可区分**：3 个种子**方向一致为负**，2/3 种子自身 CI 不含 0，合并 CI 不含 0 |

**符号方向与机制自洽**：`-Os` 的分支在 bit=0 时跳过那次 2 字节存储（`mov %dx,(%rdi,%rcx,2)`），
所以消息全 0 比全 1 快的方向（Δ<0）与产物形态一致；同一方向在 `-O2`（-11.35）也出现，
但**在本次样本量下不足以判定可区分**。

**必须写明的两点**：
1. **`-O2`/`-O3` 的"未检出"不等于安全**——这两级的产物**有**秘密相关分支、Memcheck **有**命中
   （8 / 15 处），本次只是**端到端计时没把它们分辨出来**。
2. **本次方法的可观测下限**：能定性的最小效应量级约 **25–30 ns**（`-Os` 的 Δ̄ ≈ -28.9 ns，
   相对 5.55×10⁴ ns 的解封装均值是 **约 0.05%**），即远小于此的效应在本次设置下**分辨不出**。
   `-O0` 的 Δ̄ 更大（+37.6 ns）却判为"不可区分"，原因是**符号不稳定 + 种子间散布大**，
   不是效应更大就更可信。

### 问题 2：`982c762` 的修复在四个级别上是否都成立？

**成立（按产物 + 动态 + 计时三类证据）**：

- **产物**：四级都**没有秘密相关分支**（`-Os` 把同一个 `bt` 接到 `setb`，不接 `jae`；
  `-O2/-O3` 走未内联的 `cmov_int16`；`-O0` 走 `xor;sub;and`），`helper_bt_jae` 四格全 `no`。
- **动态**：四级 Memcheck 命中 **0 / 0**（位置/动态），与未修版 `-Os` 的 1 / 512、`-O2` 的 8 / 512、
  `-O3` 的 15 / 512 相对照。
- **计时**：四级 Δ̄ 分别为 -24.87 / -0.83 / -7.98 / -4.74 ns，量级都在 ±25 ns 内，
  逐种子方向不一致（`-O2` s2 为正 +18.00，`-Os` s3 为正 +3.56），**没有一级出现未修 `-Os` 那种
  三种子同向且合并 CI 不含 0 的形态**。

**如实记录的边界观察（不夸大、也不隐去）**：
- `m1fixed-O0` 的合并 CI **不含 0**（[-39.36, -16.16]）且三种子同向；
  但 3 个种子各自的 Welch CI **都含 0**，所以这条按**边缘观察**记，不据此宣称修复版有真实差异。
- `m1fixed-O3` 的 CI 上界 -0.25 ns 紧贴 0，同列边缘观察。
- **对照水平**：判为"安全"的 M5 参考路径在 `-O3` 也给出 -2.42 [-3.93, -1.33]、在 `-Os` 给出
  -4.95 [-18.89, +4.85]，`m5ref-Os` 有 1/3 种子 CI 不含 0。也就是说 **±5 ns 量级的"显著"在本次设置里
  同样出现在没有该机制的格子上**，属于本实验的残余水平，不能单独当作机制证据。

### 问题 3：M5 在四个级别上是否都未检出？

**是，四级都未检出**（口径：本固定产物、本探针输入、本工具能力、本次采样量）：

- **产物**：四级 `bt_jae` / `per_bit_test_jcc` / `div` 全为 0；`-O2/-O3/-Os` 是
  `movzbl;and;neg;shr $0x10;and $0x681` 一类掩码选择，`-O0` 另有 `mlk_value_barrier_u8` 值屏障。
- **动态**：四级 Memcheck 命中 **0 / 0**。
- **计时**：Δ̄ = -2.30 / -0.22 / -2.42 / -4.95 ns，全部落在 ±5 ns 内；只有 `m5ref-Os` 的 1/3 种子
  自身 CI 不含 0（-18.89 ns，p=0.0027）。按上一条的对照口径，这属于**残余水平**，
  不作为"检出数据相关行为"的结论。

**"未检出"的正确读法**：M5 探针同时标记了 indcpa 私钥与拒绝秘密 `z`，命中数不能与 M1
直接互比大小（[BUILD.md](BUILD.md) §6.3）；且**无命中不等于恒时**。本项只覆盖
`poly_frommsg` 这一个机制在 clang-18 / x86_64 / 这台 Ryzen 9 9950X 上的**该输入**表现。

---

## 4. 统计口径（可复算，族外）

1. **主类对**：`message-zero` vs `message-ones`，每类每次运行 10000 次完整 `mlkem_decapsulate`。
2. **每次运行**：Δ = mean(zero) - mean(ones)；95% CI 用 PLAN §5.3 的**大样本正态近似**；
   Welch 双侧原始 p 由本工具同式复算（`erfc` 形式）。
3. **每格**：Δ̄ = 3 个种子 Δ 的算术平均；95% CI 用 **bootstrap 10000 次**重采样这 3 个 Δ。
   **3 个重复下这个区间会很窄**（这也是"CI⊄0 的种子数"要并排给出的原因）。
4. **不做 Holm、不做任何多重比较校正**；12 格之间**不排序**，结论只写"该级别下机制是否存在"
   与"修复在该级别是否仍然成立"。
5. 长尾保留、不截尾、不扣读钟开销（与 `docs/timing.md` 一致）；`time_unit=ns`，
   计时源 `CLOCK_MONOTONIC`（meta 自报，见每格 meta）。
6. 图 [figures/r09_delta_by_optlevel.pdf](figures/r09_delta_by_optlevel.pdf)：x = 优化级别，
   y = Δ̄ ± 95% CI，按臂分色，零线参考；绘图脚本 `tools/platform_optlevel/plot_r09_optlevel.py`。

---

## 5. 边界与不做的事

1. **族外探索**：本组不进任何 Holm 家族；不改变 M1/M5 既有判定；不把"某级别未检出"写成"安全"。
2. **不跨环境外推**：只覆盖 clang-18 18.1.3 / x86_64 / Ryzen 9 9950X；**gcc 未做**（理由见 PLAN §1）。
3. **混合级别差异**：冻结 M1 是混合级别（liboqs `-Os` + 封装层/采集件 `-O2`），本轮 12 格是
   **整树同一级别**；`m1unfixed-Os` 与冻结 M1 只在封装层/采集件级别上不同（PLAN §2.2 预先写明）。
4. **两个物理核**：`s1`/`s2` 在 CPU2、`s3` 在 CPU6，跨核差异混在种子离散里。
5. **频率合同的核对缺口**：36 个有效 run 的副本里没有 controller 目录，
   `restore_match`/`worker_exit_code` 等四条判据**本次无法从副本复核**；不计入的 1 次
   `frequency_probe_rejected` 已如实列出。
6. **产物摘要算法不同**：计时用的 meta 记 SHA3-256，T22 判定记 sha256，二者不可直接比较。
7. **未执行的项**：gcc 对照未做；`-O1`/`-Oz`/`-Og` 未做；其它架构未做——
   这些是"未执行"，不是"已执行且未检出"。
