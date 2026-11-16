# L2 M4 失配位置恢复演示结果（本地 WSL，未锁频）

- 日期：2026-11-16（Asia/Shanghai）
- 任务号：T6.3（P6 自适应引擎 L1/L2）
- 环境：WSL2 `Linux 6.6.114.1-microsoft-standard-WSL2`，AMD Ryzen AI 9 HX 370（24 逻辑 CPU），
  gcc 14.3.0（conda）主树 RelWithDebInfo；本地**未锁频、未独占 CPU**，只把当前进程绑到 CPU0。
  详见 `environment.txt`、`commands.txt`。
- 对象：`fixtures/early_reject_memcmp/` 的**人工校准**比较夹具——
  `compare_early.c`（vulnerable 早退臂）与 `compare_ct.c`（ct OR 累积臂）。**不是真实密码实现**。

## 1. 冻结的算法常量（运行期不可改）

| 常量 | 值 | 说明 |
|---|---|---|
| `REPEATS_CAL` | 1000 | 每个候选失配位置的校准样本数 |
| `REPEATS_TEST` | 1000 | 每次恢复运行的判读样本数 |
| `INNER_REPEATS` | 1024 | 每个样本 = 1024 次完整 `m4_compare_checked` 的均值纳秒 |
| `DEMO_RUNS` | 20 | 独立恢复次数，位置由固定 LCG（seed `20261116`）生成 |
| `DECISION_RULE` | 最近中位参考 | 校准位置中位数与恢复样本中位数差最小者 |
| `TESTER_ALPHA` | 0.05 | `bit_hypothesis_tester` 二项精确检验用（本演示未做二次筛选） |

meta 中写明 `frozen_note=冻结的是算法参数而非输入日程`；两个 meta 见
`vulnerable-recovery.meta.txt` 与 `ct-recovery.meta.txt`（含 32 个校准位置中位数）。

## 2. 快速 sanity（100 样本/位置，确认信号方向）

| 臂 | position=0 | position=15 | position=31 |
|---|---:|---:|---:|
| vulnerable-early-exit（中位 ns/比较） | 4.480 | 9.432 | 19.812 |
| ct-or-accumulate | 31.853 | — | 20.978 |

vulnerable 臂随失配位置后移单调变慢（早退循环多走字节），信号方向确认；ct 臂无此方向。

## 3. 既有 M4 measure 两臂 sanity（固定 mismatch-first / mismatch-last 类，500 调用/类）

`--describe` 与测量结果见 `measure-sanity.txt`；两臂 CSV 原件在 `measure/`。

| 臂 | mismatch-first 中位 ns | mismatch-last 中位 ns |
|---|---:|---:|
| measure-vulnerable | 50.0 | 80.0 |
| measure-ct | 60.0 | 60.0 |

既有 measure 只有 first/last 两个固定类，因此 32 位置恢复由 `craft_inputs` + 同一夹具内核
在引擎内按相同窗口口径（一次完整 `m4_compare_checked`、`CLOCK_MONOTONIC_RAW`、窗口内无 I/O）
驱动；measure 两臂用于产物可构建与方向 sanity。

## 4. 全量恢复结果（20 次独立恢复）

### 4.1 vulnerable 臂：**15/20（75%）——未达 20/20 目标**

| run | true | predicted | sample_median_ns |
|---:|---:|---:|---:|
| 1 | 11 | 8 | 8.454 |
| 2 | 14 | 14 | 11.408 |
| 3 | 21 | 21 | 14.853 |
| 4 | 16 | 14 | 11.232 |
| 5 | 15 | 15 | 11.907 |
| 6 | 2 | 1 | 5.470 |
| 7 | 25 | 31 | 23.516 |
| 8 | 4 | 4 | 6.457 |
| 9 | 19 | 19 | 13.874 |
| 10 | 22 | 22 | 15.391 |
| 11 | 29 | 29 | 18.834 |
| 12 | 24 | 24 | 16.369 |
| 13 | 23 | 23 | 15.860 |
| 14 | 10 | 10 | 9.432 |
| 15 | 1 | 0 | 4.980 |
| 16 | 12 | 12 | 10.420 |
| 17 | 27 | 27 | 17.855 |
| 18 | 30 | 30 | 19.305 |
| 19 | 5 | 5 | 6.956 |
| 20 | 0 | 0 | 4.481 |

- 正确率 15/20；5 个错误均为**相邻或近邻位置**（11→8、16→14、2→1、25→31、1→0），
  恢复中位值与真实位置在校准中位值上的差约 1 个位置级。
- 全部 20 个样本中位值与 true position 的单调关系仍成立，但校准相位与恢复相位之间存在
  系统漂移（本地未锁频 + WSL 调度）：例如 true=11 的恢复中位 8.454 ns 更接近校准位置 8 的中位，
  说明相位间整体偏移约 1 个位置级，而不是单点噪声。

### 4.2 ct 臂：**1/20（5%）——随机水平，按“未检出”登记**

- 32 位置随机猜测期望 1/32 = 3.125%，1/20 与随机一致；ct 臂校准中位在 20.9–21.0 ns 附近
  几乎不分位置（见 `ct-recovery.meta.txt`），恢复中位 20.958–35.242 ns，预测位置集中在 0/1。
- 结论：**ct 臂未检出失配位置**（不做“不可能恢复”的更强声明）。

## 5. 未达标时的预算估计（mde_budget.py，pilot 预研）

`pilot-adjacent.csv` 用与引擎相同的样本定义采集位置 0/1 各 1000 个样本（build 内探针，
不参与判定），`mde-budget.txt` 输出：

- pooled SD = 3.9229 ns；相邻位置目标效应 Δ = 0.49 ns（校准中位数相邻差）；
- **所需每类样本量 = 1007**（α=0.05 双侧、power=0.8），已接近 `REPEATS_TEST=1000` 的边界；
  32 位置分类还需多类比较预算，实际需求更高；
- 由于常量已冻结，本阶段**不调参重跑凑数**：如实登记 15/20，并把“提高预算/锁频/相位内重校准”
  作为主控后续决策项（本次失败主因是相位漂移而非单纯样本量，单独加预算不一定消除）。

## 6. 边界与口径

- 这是 **M4 人工校准臂**上的本地（未锁频 WSL）**L2 自攻击演示**，攻击对象是平台自有夹具与
  固定测试输入；不涉及真实实现、真实密钥或网络目标。
- 不写“可利用”、不主张恒时/泄漏因果；vulnerable 15/20 与 ct 1/20 只描述本机本预算结果。
- 引擎窗口内只做完整比较与读钟，无 I/O/日志/malloc；输入构造、分配与结果写出均在窗口外。
- 规律：`REPEATS_TEST=1000` 处于 MDE 边界附近，且两相位（校准/恢复）间存在系统性频率/调度漂移；
  后续如需 20/20，应由主控冻结新的预算与相位校准规则后重跑，本结果不改写、不挑选。

## 7. 文件清单

| 文件 | 内容 |
|---|---|
| `vulnerable-recovery.csv` / `.meta.txt` | vulnerable 臂 20 次恢复长表与冻结参数/校准中位数 |
| `ct-recovery.csv` / `.meta.txt` | ct 臂 20 次恢复长表与冻结参数/校准中位数 |
| `pilot-adjacent.csv` / `mde-budget.txt` | 未达标 MDE 预算估计输入与输出 |
| `measure/measure-{vulnerable,ct}.csv` / `.meta` | 既有 M4 measure 两臂 500 调用/类 sanity 原件 |
| `measure-sanity.txt` | measure `--describe` 与两类中位数 |
| `environment.txt` / `commands.txt` | 环境与复跑命令 |
