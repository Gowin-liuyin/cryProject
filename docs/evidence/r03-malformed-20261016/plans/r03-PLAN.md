# R03 格式破损 / 截断输入对照计划（族外，2026-10-16）

**定位：本计划是族外对照，不属于任何已冻结的 Holm 家族，也不改动 `efca8a1` 冻结的四份采数 PLAN。**
它只验证一件事：**异常输入（格式破损、长度不足）不会引出额外的可区分路径。**

## 1. 为什么它不进主检验

ML-KEM 的**隐式拒绝**在设计上就会对任何解封装失败的密文走**完整重加密 + 常数时间比较**路径：
`m' = Dec(c)` → `(K', c') = Re-enc(pk, m')` → `c' != c` → `K = J(z || c)`。
也就是说，"密文被破坏"本身**不应该**改变控制流长度——这正是隐式拒绝的设计目标。
因此：

- 这条对照衡量的不是"秘密相关的泄漏"，而是"**异常输入是否被均匀处理**"；
- 把它并入按秘密依赖组织的 Holm 家族，会用一条"分支存在性/输入合法性"的项去污染
  全族 α=0.05 的 FWER 解释；
- 所以它只作**族外描述**：只给原始 p、Δ 与 95% CI，外加族外 dudect，**不进入 Holm**，
  也**不改变** M1/M5 既有的家族判定。

`truncated` 类走的是封装层的**长度检查**，在进入 KEM 之前就返回；它的耗时会显著低于完整解封装，
这一差异**是接口语义的一部分，不是泄漏**——本计划如实记录该路径与耗时，并把它与
`malformed`（走完整隐式拒绝）分开报告。

## 2. 固定对象

| 臂 | 实现 | 采集 ELF | sha256 |
|---|---|---|---|
| M1 未修 | liboqs 0.10.0，Clang 18 + `-Os -fno-vectorize`，关 AVX2 分发 | `Cry/r03-malformed-20261016-29ea2774da23/build/m1unfixed/r03_malformed_measure` | `a3c94bc0048fd32b6e66a23a4113d3b80a363ea00c53d566fdc83c8b60586998` |
| M1 已修 | 同上 + 官方修复 `982c762`（`setb` + `cmov_int16`） | `Cry/r03-malformed-20261016-29ea2774da23/build/m1fixed/r03_malformed_measure` | `a93c2f60adaecc6458386594e028e2525c429d5d495d9f13a4f040fd742fecc8` |
| M5 | mlkem-native `b3ba7b3` 参考路径 | `Cry/r03-malformed-20261016-29ea2774da23/build/m5ref/r03_malformed_measure` | `772cf099d240754d5781f231b89464543d5ccb6f98901c8385c241c306ec2934` |

三个臂共用同一份 C 源（sha256 `0b442b995fd263ddc180fc9ebaaeeada9a695a4fe56ab4676a6cd82d437134bd`），
各自链接本树的实现：M1 两臂分别链接 `build/historical-clangover/historical/libmlkem.a` 与
`build/historical-fixed-982c762/historical/libmlkem.a`（均含各自的 `liboqs.a`），
M5 链接 `build-v2-ordinary/reference/libmlkem.a`（`ed9a6581…`）。该源**不修改**任何既有交付路径，
也不改动 `src/measure.c` 的 5 类协议。

绑定（三臂共同源码，两棵树 `include/{mlkem.h,inputs.h}` 逐字节相同，源内零后端条件编译）：

| 项 | 值 |
|---|---|
| 构建 | Ubuntu clang 18.1.3；工具自身 `-std=c11 -O2 -g -DNDEBUG -Wall -Wextra -Wpedantic -Wshadow -Wconversion -Wstrict-prototypes -Werror` |
| M1 实现侧 | `-Os -fno-vectorize -g -DNDEBUG`、`OQS_DIST_BUILD=OFF`、`OQS_OPT_TARGET=generic` |
| M5 实现侧 | `reference/libmlkem.a` 与 `m5-completion-PLAN.md` §1.3 一致 |

族外 online dudect 入口：
M5 用冻结树既有 `platform_m5_dudect`（`3be8772155774ad7cbcdc3ca1633d282f6209bfc5a6964eb60d7d705f902f77d`）；
M1 两臂用新根内以仓库 `tools/historical_dudect.c` + 钉版 `third_party/dudect/src/dudect.h`
重建的等价入口：未修 `3dfbab6e8b0da0a895d7d8eeae40f3d90aba8d21c4870a0b49802ccb2c3b96f2`、
已修 `525c1766483c14cc2d9ddb26d00a59afa3c50fe52f73fa32629e54940de657bf`。
该入口的种子是编译期常量，换种子须在启动时设 `HISTORICAL_DUDECT_SEED`。

## 3. 输入类（每类内部为同一份输入的重复）

| 类名 | 构造 | 预期路径 |
|---|---|---|
| `valid` | 一份固定的合法 ML-KEM-768 密文（1088 字节，确定性封装种子） | 完整解封装，接受分支 |
| `malformed` | 同一份密文，u 压缩字段（前 960 字节）置 `0xFF`、v 压缩字段（后 128 字节）置 `0x00`，**长度仍 1088** | 完整解封装，**隐式拒绝**（含完整重加密与比较） |
| `truncated` | 同一份密文，**只喂 1087 字节** | 封装层**长度检查**直接拒绝 |

**每类 10000 次是同一份输入的重复**，这是刻意的：让三个类的唯一差别就是密文内容/长度，
避免"两类输入分布不同"这种与机制无关的混淆。三类输入的摘要写进 meta。

## 4. 对照类对与运行表

两个对照类对，**都族外**：

- **A：合法 vs 格式破损** —— `valid` vs `malformed`
- **B：合法 vs 截断** —— `valid` vs `truncated`

三个种子，一次运行采三类（同一份 CSV 内三个类），每类 10000 次、预热 100 在窗口外：

| run | seed | CPU | 臂 |
|---|---:|---:|---|
| s1 | 31337 | 2 | M1 未修 / M1 已修 / M5 |
| s2 | 424242 | 2 | 同上 |
| s3 | 7 | 6 | 同上 |

共 3 臂 × 3 run = **9 次控制器运行**（另加族外 dudect）。

## 5. 统计（只给原始量，不做多重比较）

- 每个（臂，run，对照类对）给：两类均值差 **Δ**、**95% 大样本正态近似 CI**、
  **双侧 Welch 原始 p**。**不做 Holm、不做任何多重比较校正**，因为它不进任何家族。
- **族外 online dudect**：每臂一次，报告每批 `max |t|` 与最终状态；**最大 t 不得转成伪 p**。
- RTLF 可选，若跑则同样只作族外二值描述。

## 6. 频率与恢复（与主合同一致）

`boost=0`、目标 policy governor/EPP=`performance`、`min=max=4300000 kHz`、`taskset -c 2|6`；
写入回读完成后固定沉降 1.0 s，再取 20×50 ms `scaling_cur_freq`，全部落在 ±2% 且跨度 ≤50000 kHz
才放行；进入 / 运行中 / 退出三处频率快照都由控制器落盘，**`restore_match=yes` 才算有效**。

## 7. 停止与失败归档

任一次运行若 `restore_match!=yes` 或 worker 非 0 退出，先把原件整体归档到
`failed/<run-name>-attempt<n>/` 再重跑；失败运行**不计入**结果，也不从 RESULT 里消失。

## 8. 边界

人工构造输入，**不是上游 CVE**。本对照的"未检出"只说明该机、该编译产物、该类对、
该样本预算下异常输入没有引出额外的可区分路径；**不构成恒时证明**，
也不改变 M1/M5 的任何既有统计结论。不做密钥恢复，不运行 exploit demo。
