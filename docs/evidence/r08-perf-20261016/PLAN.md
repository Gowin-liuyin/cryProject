# R08 性能开销采数计划（族外，2026-10-16）

**定位：本计划只报告"每个版本跑一次完整调用要多少时间"，是族外开销描述。**
它**不进入任何已冻结的 Holm 家族**，不改动 `efca8a1` 冻结的四份采数 PLAN，
不改变 M1–M5 的任何既有统计判定，也不把"更快/更慢"当作"是否恒时"的证据。

> 本文件与同目录 `RUNS.sh` 是 T19 的交付物。**先提交、后采集**：
> 主控把本文件上传到 `Cry` 后，用 `sha256sum` 核对与 `RUNS.sh` 里写死的摘要一致，
> 再执行控制器命令。摘要不一致时不得开跑（控制器本身也会用 `--plan-sha256` 拒绝）。
>
> 性能数据**不是**秘密依赖性证据：它既不能证明恒时，也不能证明不恒时。

---

## 1. 覆盖矩阵

| 臂组 | 模块 | 版本 A | 版本 B | 采集件 | 是否完整 KEM |
|---|---|---|---|---|---|
| P1 | M1（liboqs 0.10.0 historical-clangover） | `m1unfixed` 未修 | `m1fixed` = + 官方 `982c762` | 本计划 §2.2 的 `perf_measure` | 是 |
| P2 | M2（KyberSlash） | `m2unfixed` = `a621b8d` | `m2fixed` = `272125f` | 同上 | 是 |
| P3 | M3（内存访问变体） | `m3on` = 变体开 | `m3off` = 变体关 | 同上 | 是 |
| P4 | M4（早退比较夹具） | `m4vul` = `compare_early.c` | `m4ct` = `compare_ct.c` | M4 自己的冻结 `platform_m4_measure_*`（见 §2.3） | **否** |
| P5 | M5（mlkem-native `b3ba7b3` portable reference） | `m5ref` = 唯一臂 | — | 本计划 §2.2 的 `perf_measure` | 是 |

**M4 的"不适用"与理由（写清楚，不用近似量冒充）**：
M4 不是完整 KEM。它的两臂是 `fixtures/early_reject_memcmp/` 里的**比较步夹具**
（`compare_early.c` 提前退出 / `compare_ct.c` 恒时意图），可执行入口只有
`m4_compare_bytes` / `m4_compare_checked`，**没有 `mlkem_generate_key_pair` /
`mlkem_encapsulate` / `mlkem_decapsulate`**。因此：

- **完整 decaps 不适用**：M4 层上没有"完整解封装"这个对象，硬套一个 100000 次的
  "完整 decaps"预算只能落在别的实现上，那是另一件事，本计划不做。
- **keygen / encaps 不适用**：M4 层上没有这两个入口。
- M4 改为在**它自己那一层**上采：一次 `m4_compare_bytes` 比较步调用作为窗口，
  每类 20000 次 × 6 块 × 2 臂 = 每臂每类 120000 次，**明确标注窗口只包比较步**，
  数值**不与完整 decaps 混排比较**。

M3 是完整 KEM（`mlkem_*` 三个入口都在），所以 M3 的 keygen/encaps **照做**，
不写"不适用"。

---

## 2. 固定对象

### 2.1 采集件源码与构建

| 项 | 值 |
|---|---|
| 采集件源码 | `tools/platform_perf/perf_measure.c`（本仓库） |
| 构建脚本 | `tools/platform_perf/build_perf_arms.sh`（本仓库） |
| 构建根 | `/home/nss-marker/yhr/Cry/r08-perf-20261016-85e46c952887/` |
| 编译器 | `/usr/bin/clang-18`（Ubuntu clang 18.1.3） |
| 采集件自身标志 | `-std=c11 -O2 -g -DNDEBUG -Wall -Wextra -Wpedantic -Wshadow -Wconversion -Wstrict-prototypes -Werror` |
| 链接 | 各臂链接**各自冻结树**的实现静态库；未重编任何实现 |

### 2.2 七个 `perf_measure` 臂（实读 sha256）

`<R08>` = `/home/nss-marker/yhr/Cry/r08-perf-20261016-85e46c952887`

| 臂 | 实现 | 绝对路径 | sha256 |
|---|---|---|---|
| `m1unfixed` | liboqs 0.10.0 historical-clangover | `<R08>/build/m1unfixed/perf_measure` | `067bd4bdd86fb2c5221f44d20aaa2d795007d141b9ef755c7d8aee9f8374d1d6` |
| `m1fixed` | 同上 + `982c762` | `<R08>/build/m1fixed/perf_measure` | `f53b3d4c552795d349d4e6a89d550eef37dfb5eab45ced70380d55d795b7447f` |
| `m2unfixed` | KyberSlash 未修 | `<R08>/build/m2unfixed/perf_measure` | `3623c656d40f66af7f58bf3c5aefab8db1dde16404310a9a48947fcd98e673a0` |
| `m2fixed` | KyberSlash 已修 | `<R08>/build/m2fixed/perf_measure` | `6216b92d516eb8f619ee9a4b2daaeb966144ab4eda2329d0ef42955460faf970` |
| `m3on` | M3 变体开 | `<R08>/build/m3on/perf_measure` | `31eef1d51271dc23e7cc66c63b49efe61c34de2ec5dc9607a1efc3692f3ee633` |
| `m3off` | M3 变体关 | `<R08>/build/m3off/perf_measure` | `7eebc1c6afba0e4cb8386547d83bf17d328ab87c3cb88bf07294f3ce30b14550` |
| `m5ref` | mlkem-native `b3ba7b3` reference | `<R08>/build/m5ref/perf_measure` | `f5cece7b4eb90ce6b6374bbcd161de902fd117a2734c8e5ca085d1db1506c25d` |

源码摘要 `perf_measure.c` = `fbf1ca82cea528fa3e9c263263e5883fad449db008293d02b0bec6c450c3e812`
（`<R08>/src/perf_measure.c`，与仓库内同名文件逐字节相同）。

### 2.3 两个 M4 臂（冻结 ELF，未重建）

| 臂 | 绝对路径 | sha256（`m4-completion-20261016/PLAN.md` §1.3 实读值） |
|---|---|---|
| `m4vul` | `Cry/platform-m4-20261016-6hRHRUxH/build-software-v3/platform_m4_measure_vulnerable` | `2686907893706372538855fa778bc7133cbed8fa0a8115c3dc57b124119b36c5` |
| `m4ct` | `Cry/platform-m4-20261016-6hRHRUxH/build-software-v3/platform_m4_measure_ct` | `90740bdf99125a2c37465c239617b6dadb344401e89b1830d24da88bd70be035` |

采集前主控必须重新 `sha256sum` 核对；不一致就停下，不许改摘要继续。

---

## 3. 采集件的参数与输出格式

### 3.1 参数含义（`perf_measure`）

```
perf_measure --run-id ID --seed N --raw NEW.csv [--meta NEW.meta]
             [--warmup W] [--decaps-samples D] [--keygen-samples K]
             [--encaps-samples E] [--arm NAME]
             [--block-index B] [--block-count C] [--order-seed S] | --describe
```

| 参数 | 含义 |
|---|---|
| `--run-id` | 写进 CSV 第一列；只允许 `[A-Za-z0-9_-]`，长度 1..64 |
| `--seed` | 固定测试密钥与固定合法密文的派生种子（本次全部用 `31337`） |
| `--raw` / `--meta` | **必须不存在**的全新文件；以 `wx` 新建，已存在即失败并退出非 0 |
| `--warmup` | 每个操作在**计时窗口外**的预热次数（本次 100） |
| `--decaps-samples` / `--keygen-samples` / `--encaps-samples` | 三类操作各自的**计时调用次数**；上限 400000 |
| `--arm` | 只写进 meta 的臂名（CSV 的可比性靠 run-name 与 meta） |
| `--block-index` / `--block-count` | 块号与块总数（从 0 开始），只写进 meta |
| `--order-seed` | 三个操作**计时顺序**的乱序种子（同一值在任何臂上给出同一顺序） |
| `--describe` | 打印工具自述、操作定义、CSV 表头后退出，**不采数** |

### 3.2 CSV 列名（与冻结 `--format measure` 完全同形）

```
run_id,implementation,input_category,sample_index,elapsed_nanoseconds,time_unit
```

- `input_category` 取 `decaps` / `keygen` / `encaps`（是**操作名**，不是秘密类）。
- `sample_index` 是**该操作内部**从 0 开始的序号。
- `elapsed_nanoseconds` 是十进制整数 ns；`time_unit` 恒为 `ns`。
- 一份 CSV 只有**一个** `run_id` 与**一个** `implementation`（列在文件内恒定），
  因此它能被 `scripts/run_stats_battery.sh --format measure` 解析。
  **但 T21 的性能表用独立解析**：`--format measure` 输出的是"两类之差"，
  对"逐操作均值/分位数"没有意义，不作性能量使用。
- 注意：CSV 的 `implementation` 列是各实现的自报名（M1 两臂都报 `historical`，
  M5 报 `reference`）。**臂身份以 run-name 与 meta 的 `arm=` 为准**，不要靠这一列分辨臂。

### 3.3 meta 关键字段

`tool`、`schema`、`run_id`、`arm`、`implementation`、`build_flags`、`test_seed`、
`warmup_calls_per_operation`、`operation=<名> samples=<n> window=<窗口定义>`、
`block_index`、`block_count`、`order_seed`、`operation_order`、
`encapsulation_key_sha256`、`ciphertext_sha256`、`time_unit=ns`、
`timer_source=clock_gettime(CLOCK_MONOTONIC)`、`timer_resolution_ns`、
`clock_overhead_subtracted=no`、`long_tail_trimmed=no`、
`zero_elapsed_count`、`run_status=complete`、`cpu_affinity=not_pinned`、
`frequency_control=not_configured`、`executable_sha256`。

`cpu_affinity=not_pinned` / `frequency_control=not_configured` 是刻意的：亲和性与
频率全部由外层控制器负责，采集件自身不写任何全局配置。**正式采数只在控制器窗口内进行。**

---

## 4. 计时窗口、单位与周期换算

**窗口只包一次完整调用**，逐次计时：

```
clock_gettime(CLOCK_MONOTONIC) → atomic_signal_fence(seq_cst)
    → 一次完整调用（decaps / keygen / encaps）
    → atomic_signal_fence(seq_cst) → clock_gettime(CLOCK_MONOTONIC)
```

| 操作 | 窗口内到底是什么 |
|---|---|
| `decaps` | 一次完整 `mlkem_decapsulate`，输入是固定合法密文（接受路径），密钥是固定测试密钥 |
| `keygen` | 一次完整 `mlkem_generate_key_pair` |
| `encaps` | 一次完整 `mlkem_encapsulate`，公钥是固定测试公钥 |

**窗口外**：固定密钥/密文的派生、摘要、预热（每操作 100 次）、结果消费、CSV/meta 写盘、
ELF 自哈希、内存分配、`--describe`。进程不 fork、不 daemonize、不 setsid、
不写自身 CPU 亲和性、不写频率、不写给定路径以外的文件。

**单位**：纳秒（ns）。不扣读钟开销、不换算周期、不裁剪长尾，全部原始值逐行落盘。

**周期换算的基础频率来源**（写进 T21 的口径，这里先固定）：
频率合同把目标 CPU 的 `scaling_min_freq = scaling_max_freq = 4300000 kHz`
（控制器写死的 `TARGET_KHZ`），且入窗放行要求 20 次 `scaling_cur_freq` 全部落在
±2%（4214000–4386000 kHz）且跨度 ≤50000 kHz。因此：

- 主口径：`cycles = ns × 4.3`，基频取**名义锁定频率 4300000 kHz**，来源是控制器的
  `TARGET_KHZ` 与每次运行 `entry-probes.json` / `during.json` 里的 `cur_khz` 记录；
- 核对口径：同时给出用该次运行 `during.json` 的 `cur_khz` 中位数换算的数值。
  **两套都写出来**；两者不一致时以名义锁定频率为主口径并注明偏差。

**已知且不隐藏的一点**：`keygen` 与 `encaps` 的窗口内包含公开 API 自身的
`system_random_bytes` 调用（这是完整调用的一部分），因此这两类操作的方差里含
内核随机源的开销；`decaps` 不含。这不是缺陷，是接口事实，如实记录。

---

## 5. 交错顺序（ABBA 配对块）、块大小与种子

两版交错**在运行层面**做：每一"块"是一次独立的控制器运行，块内只跑一个臂。
配对规则：**每两块为一个单元，第一个单元先 A 后 B，第二个单元先 B 后 A**，
再重复。6 个块的执行顺序是

```
A B | B A | A B | B A | A B | B A
```

即 A、B 各占 3 次"先跑"与 3 次"后跑"，线性漂移在一阶上被抵消。
（两版不能链进同一个进程：同名符号冲突，且文件级 `wx` 语义要求每次运行独立落盘。）

| 项 | 值 |
|---|---|
| 块数 | 每臂 **6** 块（P5 的 M5 单臂同样 6 块，用于块间漂移自检） |
| 每块 decaps 调用 | **25000** |
| 每块 keygen / encaps 调用 | 各 **5000** |
| 每臂累计 decaps | **150000**（预算 ≥100000，余量 50%） |
| 每臂累计 keygen / encaps | 各 **30000**（预算 ≥20000，余量 50%） |
| 每块预热 | 每操作 100 次（窗口外） |
| 输入种子 `--seed` | **31337**（所有臂、所有块相同 → 比较的是同一份工作负载） |
| 顺序种子 `--order-seed` | **20261016**（所有臂、所有块相同 → 同一操作顺序） |
| M4 每块 | 每类 20000 次比较步调用，`--compare-bytes 32`，种子 31337 |
| M4 每臂累计 | 每类 120000 次 |

**为什么输入种子不逐块变化**：这是性能对比，不是两类输入的对照。所有臂在**同一份**
固定密钥/密文、同一个操作顺序下运行，块间唯一变化的是时间与 A/B 的先后。

**qualification（非采数，已在本轮完成）**：七个臂各跑 `--describe` 与一次小样本
（decaps 200 / keygen 50 / encaps 50、预热 5、不锁频、不写频率），确认退出码 0、
CSV 表头与行数正确、`time_unit` 全为 `ns`、`run_status=complete`、
`zero_elapsed_count=0`。原始输出在 `Cry/r08-perf-20261016-85e46c952887/qualification/`，
摘要见同目录 `summary.txt`。

---

## 6. 频率合同（与主合同一致）

- `boost=0`；目标 policy 的 governor 与 EPP = `performance`；
  `scaling_min_freq = scaling_max_freq = 4300000 kHz`。
- 由唯一入口 `tools/platform_control/controller.py`
  （sha256 `4a0cf57a00c6802ff86ed410d2518bc56cc8e694422cbc4ea7a24a3f1cdd701`）执行；
  控制根 `Cry/platform-control-20261016-53929b406f0d`。
  **若主控本轮另建控制根，以主控给的为准**，本计划只要求：控制根名匹配控制器自身的
  命名规则、由 root 持有锁、且控制器源码摘要与上面一致。
- CPU：`taskset -c 2`（控制器用 `--cpu 2`）。**本轮 T20 全部用 CPU2**，
  不复测 CPU6（CPU6 的复测属于 T23 的 `r09` 计划）。
- 入窗放行：写入并回读完成后固定沉降 1.0 s，再取 20×50 ms `scaling_cur_freq`，
  全部落在 ±2% 且跨度 ≤50000 kHz 才放行；否则该次运行判为无效。
- 进入 / 运行中 / 退出三处频率快照由控制器落盘。
- **有效判据**：`terminal.json` 的 `reason=worker_finished`、
  `worker_exit_code=0`、`worker_drained=true`、`restore_match=yes` **同时**成立。
  **`restore_match=yes` 才算有效**；任何一条不成立，该次运行不计入结果。

---

## 7. 停止与失败归档

1. 任一次运行 `restore_match != yes`、或 `worker_exit_code != 0`、
   或放行探针越界：**立即停止后续采集**，先把该 run 的控制器原件整体归档到
   `<COLLECT>/R08/<run-name>/controller/` 与 `<COLLECT>/R08/failed/<run-name>-attempt<n>/`，
   再决定重跑。失败运行**不计入**结果，也不从记录里消失。
2. 同一 run-name 不得复用：控制器的运行目录用 `mkdir` 新建，已存在即失败；
   重跑必须用**新 run-name**（`-a2`、`-a3` 后缀），并在失败归档里保留原件的 sha256。
3. CSK/CSV 用 `wx` 新建；若目标文件已存在，采集件自身退出非 0，按失败处理并换名重跑。
4. 连续两次同类失败：停止整组采集，写 `BLOCKERS`（内容：run-name、判据、
   原件路径、已尝试次数），交主控决定。
5. 采集中途任一 run 出现频率探针越界，后续所有 run 一律不跑，先恢复并核验
   `restore_match`。

---

## 8. 统计口径（族外，不进 Holm）

- **性能数据不进任何 Holm 家族。**它只作开销报告：每个（臂，操作）给
  n、均值 ± 95% CI（bootstrap 10000）、中位数、p90、p99，单位 ns 与周期两套，
  以及相对同组对照臂的开销百分比与它的 bootstrap CI。T21 负责算，本节只固定口径。
- 不做任何多重比较校正，也不与 M1–M5 的秘密依赖性 p 值合并。
- **不夸大**：某一臂更快**不等于**它更安全；某一臂更慢**不等于**它泄漏。
  开销差异与恒时性是两个不同的问题，报告里分节写。
- 块间一致性作为描述量报告：同一臂 6 个块的块内中位数散布（极差与 IQR），
  用来显示漂移有没有被 ABBA 抵消掉；不做假设检验。
- 长尾全部保留（与 `docs/timing.md` 第 34 行一致），不做截尾。

---

## 9. 与其它交付的关系

- 本计划的采数由主控按 `RUNS.sh` 串行执行；本计划的作者**没有**运行任何锁频采集。
- 优化级别那一组（`-O0/-O2/-O3/-Os`）在 `docs/evidence/r09-optlevel-20261016/PLAN.md`，
  与本计划分开：本计划的 M1/M2/M3/M5 采集件都是各自冻结树的既有构建，
  **不随优化级别变化**。
- 采集件源码 `tools/platform_perf/perf_measure.c` 与构建脚本
  `tools/platform_perf/build_perf_arms.sh` 已在仓库内，可复跑。
