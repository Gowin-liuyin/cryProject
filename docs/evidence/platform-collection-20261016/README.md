# 平台锁频采数原件与统计（2026-10-16）

本目录是本轮 M2/M5/M3/M4 四个模块**真实锁频采数**的原件与统计出口。
采集合同为 `efca8a1` 冻结的四份 PLAN：
[M2](../m2-kem-20261016/PLAN.md)、[M5](../m5-completion-20261016/PLAN.md)、
[M3](../m3-completion-20261016/PLAN.md)、[M4](../m4-completion-20261016/PLAN.md)。

## 1. 采集条件（全部经唯一锁频控制器）

### 1.0 冻结计划与实际执行版本

四份 PLAN 在**采数之前**由一次提交 `efca8a1` 冻结。控制器对每次运行校验
`--plan-sha256`，下面四个值就是**实际通过校验并在采集日志里逐字记录**的摘要
（等于 `git show efca8a1:<该路径>` 的 blob 摘要）：

| 模块 | 计划路径 | 执行用 sha256 |
|---|---|---|
| M2 | `docs/evidence/m2-kem-20261016/PLAN.md` | `0f706455c6a8fde28ecd3dc18fb12ae4562c2f57dc7e2d991b5ff83c5cd07142` |
| M5 | `docs/evidence/m5-completion-20261016/PLAN.md` | `15738beea1e8d22ae58f83ed741636c2bcf7d9f49e16f0c5c0f2f8590c323e44` |
| M3 | `docs/evidence/m3-completion-20261016/PLAN.md` | `be2db4599fb9c5d39852f001d3cf872173b68c2d65ebb4ca542ea0798e01a4a0` |
| M4 | `docs/evidence/m4-completion-20261016/PLAN.md` | `767f0378124645f9830b14cfbff61fb2571cbf050b451b93fbe74ac8256f509a` |

冻结之后四份 PLAN 各经过一次**文档修订**（补录实读摘要、把执行入口换成绝对路径、
同步交付语义、修正正文与已填值的不一致）；修订**没有**改变类对、样本预算、
Holm 家族与 m、α、停止规则或频率恢复合同，但确实改动了 M2 在线 dudect 的措辞
（修订版写"固定 20 批"，执行版写"最多 21 批，首批为上游预热/分位阶段"）。
**实际执行按执行版**：M2 每臂 21 批 = 1 个预热批 + 20 个检验批 = 210000 次完整解封装。
每份 PLAN 顶部都有对应的版本说明。

| 项 | 值 |
|---|---|
| 控制器源码 | `tools/platform_control/controller.py`，sha256 `4a0cf57a00c6802ff86ed410bd2518bc56cc8e694422cbc4ea7a24a3f1cdd701`（提交 `a3c9ca1`） |
| 控制器资格 | 五条空任务全过，见 [QUALIFICATION.md](../platform-control-qualification-20261016/QUALIFICATION.md) |
| 采数控制根 | `Cry/platform-control-20261016-c011ec7a5e01` |
| 采数根 | `Cry/platform-collect-20261016-c011ec7a5e01` |
| 目标频率 | `boost=0`、governor/EPP=`performance`、`min=max=4300000 kHz`、`taskset -c 2` 或 `-c 6` |
| 放行门 | 写入回读完成后固定沉降 1.0 s，再取 20×50 ms `scaling_cur_freq`；全部在 4300000 ±2% 且跨度 ≤50000 kHz |
| 三次运行 | r1 = seed 31337 / CPU2；r2 = seed 424242 / CPU2；r3 = seed 31337 / CPU6 |
| 每类样本 | 10000（预热 100，窗口外） |
| 主机 | `nss-m`，Linux 6.17.0-35-generic，x86_64，AMD Ryzen 9 9950X，`boot_id=1d5a4300-d997-4a45-a9d6-95165d68dcd9` |

## 2. 运行结果

**54 次正式运行全部成功**：`controller_exit=0`、`reason=worker_finished`、
`worker_exit_code=0`、`restore_match=yes`，且每次的 20 个放行探针全部落在 ±2% 带内
（逐条见 `status.log`；每次运行的探针摘要、`terminal.json`、`guardian.json`、`worker.json`、
`baseline.json`、`during.json`、`0020-restored.json` 与逐写 intent/visible 序列都在
`<模块>/<run>/controller/` 下）。

| 模块 | 控制器运行数 | 组成 |
|---|---:|---|
| M5 | 6 | 3 次运行 ×（measure 1 + online dudect 1） |
| M3 | 12 | 3 次运行 × 2 臂 ×（measure 1 + online dudect 1） |
| M4 | 18 | 3 次运行 × 2 臂 ×（主路径 1 + 截断对照 1 + dudect 1） |
| M2 | 18 | 3 次运行 × 2 臂 ×（主类对 1 + 对照类对 1）+ 3 次运行 × 2 臂 dudect |

**进入 / 运行中 / 退出三处频率证据**：`<run>/entry-snapshot.txt`（主控独立读取的 32 个 policy
+ `global boost`）、`<run>/controller/baseline.json` 与 `entry-probes.json`（进入）、
`<run>/controller/during.json`（运行中，50 ms 间隔采样）、`<run>/controller/0020-restored.json`
与 `<run>/exit-snapshot.txt`（退出）。每次运行的前后全量快照逐字相同。

采数期间另有两批**未产生测量值**的失败尝试，原因是主控脚本自身的缺陷，不是测量或控制器故障，
原件完整保留在远端 `Cry/platform-collect-20261016-c011ec7a5e01/harness-bug-archive/`：
(a) 快照助手把 heredoc 通过 `sudo -S` 管道，导致 Python 收到口令而非脚本；
(b) 控制根路径写成含 `..` 的相对形式，被控制器规范化检查拒绝；
(c) M2 采集树变量未设置，worker 路径解析越出 Cry。
三者都不属于家族的失败成员，也不从结果里消失。

## 3. 数据格式与存储

- `measure` 产出为标准长表：`run_id,implementation,input_category,sample_index,elapsed_nanoseconds,time_unit`，
  单位 ns，`CLOCK_MONOTONIC`，5 个类别（M2 为 4 个：message-zero / message-ones /
  malformed-zero-tail / malformed-ff-tail）。
- **所有 `.csv` 以 gzip 存放**（`.csv.gz`）以控制仓库体积；解压后与采集时逐字节相同，
  其 sha256 记录在同目录 `<name>.meta` 与 `stats/<dataset>/input.sha256` 里。
  例：`gzip -dk M2/m2-s1-unfixed/unfixed-main.csv.gz`。
- `controller/` 下的 JSON 未压缩，保持原字节。

## 4. 统计出口

`stats/<dataset>/` 为逐数据集统计电池产物（`ci_welch.json`、`RESULT.md`、`configuration.txt`、
`input.sha256`、`tools.sha256`、`input.csv.gz`、`normalized.csv.gz`）；电池以
`--format measure --classes <c0> <c1> --no-external` 运行，**不做 Holm**。

`stats/members/members.csv` 是预注册家族的成员表，`stats/holm/` 是 `platform_holm`
（提交见 `tools/platform_stats/holm.c`）的输出：`holm.csv`、`pooled.csv`、
`holm_summary.json`、`RESULT.md`。每个模块一个家族，α（全族）= 0.05。

`stats/members/members-descriptive.csv` 与 `stats/holm-descriptive/` 是**描述性分层**
（按臂合并、对照类对合并），**不是独立家族，不改变任何 Holm 判定**，只用于读数。

## 5. 结论（详见各模块 RESULT.md）

| 模块 | 家族 / m | Holm 拒绝数 | 家族内合并效应 Δ（ns）与 95% CI | I² |
|---|---|---:|---|---:|
| M2 | `m2_end_to_end_full_decaps_v1` / 6 | 0 | +4.58 [−3.08, +12.25] | 58.3% |
| M5 | `m5_reference_end_to_end_v1` / 3 | 0 | −5.30 [−11.77, +1.16] | 0% |
| M3 | `m3_lut_arm_end_to_end_v1` / 6 | 0 | −0.73 [−5.56, +4.10] | 12.5% |
| M4 | `m4_compare_arm_session_v1` / 6 | **3** | −3.74 [−3.87, −3.62] | 98.6% |

M4 的三次拒绝全部来自 vulnerable 臂（原始 p = 0、9.23e−25、3.14e−22），
ct 臂三次均不拒绝（p = 0.386、0.438、0.399）。家族合并的 I²=98.6% 正是"泄漏臂 + 不泄漏臂"
混合造成，因此按臂的描述性合并更可读：vulnerable −4.089 [−4.215, −3.963]、
ct +0.055 [−0.363, +0.473]。

M2 的家族未拒绝，但两个臂的描述性合并方向相反（unfixed +12.35 [2.98, 21.71]，
fixed −11.20 [−24.56, 2.15]）——这是**臂间漂移**而非可归因泄漏的证据，
预注册家族判定不受影响，也不据此新增声明。

## 6. 边界

- 频率锁定是**工程控制观测**：`scaling_cur_freq` 不是示波器测量，本页不主张逐调用物理恒频，
  也不给出物理误差界。
- 未检出不等于恒时证明；M2/M3/M5 的"未拒绝"只覆盖本机、本编译产物、本类对、本样本预算。
- M3/M4 是**人工构造校准**，不是新增上游 CVE；M4 的"insecure"只针对人工提前退出夹具。
- RTLF（α=0.01）与 online dudect 一律**族外**，dudect 的最大 t 不得转成伪 p 参与 Holm。
- 采数期间机器上仍运行着与本项目无关的常驻服务；这一点不改变单核绑核与频率门的记录，
  但意味着"整机独占"不是本页的主张。
