# 多泄漏模块平台完整完成条件 —— 最终复核审计（FINAL_AUDIT，第 8 版）

**审计快照（第 8 次复核，收尾确认）：** 审计时刻 2026-10-16T05:55–06:05（Asia/Shanghai）。
`git rev-parse HEAD` = **`d2ad9c9`**（"test: final5 包最终重出并复算（D-05 收尾后来源摘要再刷新）"，05:55:33 +0800）；
`44c209a..HEAD` = **74** 个提交；`origin/main..HEAD` = **31**（未 push，无分叉）；**`git status` 无已跟踪改动**。
第 7 版（本文件上一版，快照 `7387c01`）登记的 2 处未闭（D-05、R-03）已由 **`008c516`** 收尾并提交，
四处工作区修补也在同一提交落盘；final5 包随后由 **`d2ad9c9`** 最终重出。第 7 版原字节另存
[`FINAL_AUDIT-7387c01.md`](FINAL_AUDIT-7387c01.md)、[`FINAL_AUDIT-7387c01.csv`](FINAL_AUDIT-7387c01.csv)。

> **时点声明（第 8 版已更新）：** 第 7 版曾登记"D-03/D-04/D-05/R-04 四处修补与本审计两个产物只在工作区、尚未提交"，该时点问题**已消除** —— `008c516`（05:54:50）已把四处修补一并提交，`d2ad9c9`（05:55:33）最终重出 final5 包；本版复核时 **`git status` 无已跟踪改动**（仅剩 `.agents/`、`workspace/`、`cn-network-test*.sh` 等与本平台无关的历史未跟踪项）。本审计的 `FINAL_AUDIT.md`/`.csv` 与 `partials/S11.md` 在本版写入后处于已修改/新增状态，属正常的工作区修订，待主控统一提交。

**工作区状态：** 全部已提交。`git status --porcelain` 无已跟踪改动（仅剩 `.agents/`、`workspace/`、
`cn-network-test*.sh`、未跟踪的报告渲染目录等与本平台无关的历史未跟踪项）。

**本轮实际基线（与计划书的偏差，必须一起读）：** 计划书写明的基线是 `origin/main@c849c0f`；
实际基线是 **`origin/main@e81c1ae`**——`git rev-list --count c849c0f..e81c1ae` = **11**，
即计划书已过期 11 个提交。`closeout-20261016/BASELINE.md` 已如实记下这 11 个提交的清单
（`b94e942`…`e81c1ae`），并声明 T01–T04、T10–T14、T16、T32（final4）、T33（第 4/5 版）
已在该区间完成并推送、本轮不重做。**这 11 个提交的内容已在第 5 版审计里**，
本版只把它们当既有事实引用，不重复判定。

**提交进展：** `git rev-list --count e81c1ae..HEAD` = **27** 个提交（`08cace0`…`f8fa4de`）；
`origin/main`（`e81c1ae`）是 HEAD 的祖先，`origin/main..HEAD` 同为 **27（未 push）**，无分叉。
作者与提交者唯一为 `Gowin-liuyin <yinhaoran0808@outlook.com>`；
`git diff --stat e81c1ae HEAD -- sources vendor` 为空。

**本次复核范围：** ①把第 5 版原字节另存为 `FINAL_AUDIT-e81c1ae.*`；②逐条复核原 43 行（**判定一律不动**，
只把 S02 的 R05 计数更新到补格后的 5/75/10/0）；③并入本轮 **22 项任务行**
（T00/T05–T09/T15/T17–T24/T26–T32/T34 + BLOCKERS）、**1 行口径行**（X-CONT 锁频运行计数）
与 **8 行不一致/残留行**（D-01…D-05、R-02…R-04），CSV 共 76 行；
④把四处已知不一致（报告 §24 的 1–4）**逐条核实到闭合提交 `6c10f4d`**；
⑤实跑全部 `verify_command`；⑥独立重数本轮全部计数（不看文稿、逐份日志与逐份 `terminal.json` 重算）；
⑦把本轮**新发现**的 6 处未闭不一致登记为 D-03/D-04/D-05/R-02/R-03/R-04。

**被审计文档：** `docs/platform/COMPLETION_REQUIREMENTS.md`
（sha256 前 16 位 `31cac9c7b848585c`，与第 1–5 版一致，未变更；文档自述基线 `main@ac46e62`）。

**审计性质：** 只读。未改 `COMPLETION_REQUIREMENTS.md`、未改任何被审计证据文件的原始字节
（本轮新写入的只有 `FINAL_AUDIT.*`、新快照 `FINAL_AUDIT-e81c1ae.*` 与 `partials/S11.md`）、
未 `git add/commit/push`。

> **六次历史快照的结论在此（均原字节保留）：**
> - **快照 `47033dd`（第 1 版，02:08）：** 全量 41 行 已满足 18 / 部分 15 / 未执行 4 / 条件未触发 1 / 可选未做 3；口径 B（32 项）14 / 10 / 4 / 1 / 3；5 个关键未满足项（B05/C03/D04/E04 未执行 + B04/G03 未冻结提交）。原文见 [`FINAL_AUDIT-47033dd.md`](FINAL_AUDIT-47033dd.md)、[`FINAL_AUDIT-47033dd.csv`](FINAL_AUDIT-47033dd.csv)。
> - **快照 `a30d7c7`（第 2 版，02:49）：** 全量 41 行 已满足 37 / 部分 1（F04） / 未执行 0 / 条件未触发 0 / 可选未做 3；口径 B（32 项）28 / 1 / 0 / 0 / 3。原文见 [`FINAL_AUDIT-a30d7c7.md`](FINAL_AUDIT-a30d7c7.md)、[`FINAL_AUDIT-a30d7c7.csv`](FINAL_AUDIT-a30d7c7.csv)。
> - **快照 `0d9876b`（第 3 版，02:57）：** 全量 41 行 已满足 38 / 可选未做 3；口径 B（32 项）29 / 0 / 0 / 0 / 3；C-05…C-10 六条闭合。原文见 [`FINAL_AUDIT-0d9876b.md`](FINAL_AUDIT-0d9876b.md)、[`FINAL_AUDIT-0d9876b.csv`](FINAL_AUDIT-0d9876b.csv)。
> - **快照 `dc6522c`（第 4 版，03:50）：** 逐条复核 41 行 + 2 行补充 S01/R03、S02/R05；A′ 43 行 40/3、B′ 34 项 31/3；C-02/C-03/C-04 由 `b637d0d` 闭合。原文见 [`FINAL_AUDIT-dc6522c.md`](FINAL_AUDIT-dc6522c.md)、[`FINAL_AUDIT-dc6522c.csv`](FINAL_AUDIT-dc6522c.csv)。
> - **快照 `7a71d5c` / `e81c1ae`（第 5 版，03:45–03:58）：** 41 行 38/0/0/0/3（不变）；A′ 43 行 40/3；B 32 项 29/3；B′ 34 项 31/3；C-11 由 `7a71d5c` 闭合，C-01…C-11 **全部闭合**。原文见 [`FINAL_AUDIT-e81c1ae.md`](FINAL_AUDIT-e81c1ae.md)、[`FINAL_AUDIT-e81c1ae.csv`](FINAL_AUDIT-e81c1ae.csv)。
> - **快照 `424d733` + `f8fa4de`（第 6 版，05:39–05:52）：** 41 行 38/0/0/0/3、32 项 29/3 **均不变**；A′ 43 行 40/3、B′ 34 项 31/3 **均不变**；本版**新增 33 行**（22 项任务行 + 1 项口径行 X-CONT + 8 项不一致/残留行 D-01…D-05、R-02…R-04，另 S01/S02 两行为第 5 版已有、本版只更新 S02 口径），合并后 **76 行 = 65 已满足 + 3 可选未做 + 2 已闭不一致 + 6 未闭不一致**。四处已知不一致**全部按闭合提交 `6c10f4d` 核实**；新登记 **6 处未闭**（MAPPING 分组算术、POWER §4/§5.1 陈旧家族标签、进度记录 T34 计数、报告来源摘要时间差、"最终交接"未含本轮、签字清单表头过期）。六版差异见 §7。
> - **快照 `7387c01`（第 7 版，05:50–06:10）：** 原文 41 行 38/0/0/0/3、32 项 29/0/0/0/3，A′ 43 行 40/3、B′ 34 项 31/3，A″ 66 行 63/3、B″ 57 项 54/3 —— **全部不变**；CSV 仍 **76 行**（65 已满足 + 3 可选未做 + 6 已闭不一致 + **2 未闭不一致**）：D-03/D-04/R-02/R-04 核实为已闭合（前两者与 R-04 为工作区修正、R-02 已提交），**D-05 与 R-03 复核后仍判未闭**（详见 §4.3）。本次实跑 **73 条 `verify_command`，exit0 = 73、non-zero = 0**；证据路径 255 条 0 缺失。七版差异见 §7。
> - **快照 `d2ad9c9`（第 8 版，本版，05:55–06:05）：** 第 7 版登记的 2 处未闭 **全部闭合** —— D-05（`POWER.md` §5.1 首句改写、旧矛盾句实测 0 命中）与 R-03（交接节包摘要改为当前有效 `cacf9453…` 并注明两次被取代成包），提交 `008c516`/`d2ad9c9`；四处工作区修补同批提交，`git status` 已无已跟踪改动。各口径计数**全部不变**（A 41→38/3、B 32→29/3、A′ 43→40/3、B′ 34→31/3、A″ 66→63/3、B″ 57→54/3）；CSV 仍 **76 行 = 65 已满足 + 3 可选未做 + 8 已闭不一致 + 0 未闭**。实跑 **73 条 `verify_command`，exit0 = 73、non-zero = 0**；证据路径 255 条 0 缺失；final5 zip = `cacf9453…`、PDF = `d391114c…`（未变）。八版差异见 §7。
> - 各版原始文件与本版快照均在 `docs/evidence/platform-completion-20261016/` 内并列保存，未覆盖。

> **口径纪律（严格遵守原文第 1 节）：** 未运行 ≠ 未检出；软件就绪 ≠ 工具已执行；clone 成功 ≠ 运行成功；
> 前置完成 ≠ 模块完成；人工夹具不得计为上游 CVE；M5 阴性不写成恒时证明；M2 定位阳性不写成端到端阳性；
> 族外对照（R03 的格式破损/截断、RTLF、dudect、R12、R09）不进 Holm，也不反过来推翻家族判定；
> R05 的"不存在/不适用"只收窄到固定源码、固定编译器与固定产物，不是物理恒时；
> 本轮的 R08/R09 性能与优化级别结果**不是秘密依赖性证据**（快 ≠ 安全，慢 ≠ 泄漏）；
> R12 的锁频对照**不把锁频写成"必然降低方差"**（实测恰好相反）；
> R06 的 F1 **仍然是未闭缺口**，故题面第 6 条**如实保留为"部分"**；
> **"必做项全部满足" ≠ 竞赛验收完成**——材料审核、本人签署与官方验收仍须人工完成。

---

## 1. 口径推导（两种口径都算，不删行、不改判定）

### 1.1 原文逐行 ID 清单

| 段 | ID 范围 | 行数 | 原文位置 |
|---|---|---:|---|
| 贯穿门槛 G | G01–G09 | 9 | §2 表格（L27–L35） |
| Phase A | A01–A04 | 4 | §3 表格（L45–L48） |
| Phase B | B01–B07 | 7 | §4 表格（L57–L63） |
| Phase C | C01–C05 | 5 | §5 表格（L73–L77） |
| Phase D | D01–D06 | 6 | §6 表格（L83–L88） |
| Phase E | E01–E06 | 6 | §7 表格（L94–L99） |
| Phase F | F01–F04 | 4 | §8 表格（L108–L111） |
| **合计** | G01–G09 + A01–F04 | **41** | 40 条表格行 + 1 条 G01 |

类型：必做 **36**、条件项 **2**（B06、D03）、可选 **3**（C05、D06、E06）。36+2+3 = 41。

### 1.2 用户口径"32 项" = A–F 阶段项

A(4)+B(7)+C(5)+D(6)+E(6)+F(4) = **32**；G01–G09 是原文 §2 的"贯穿所有阶段的门槛"，不属于任何 Phase。
32 内：必做 27、条件项 2、可选 3；另加 9 条贯穿门槛 = 41 行全量。
该推导与 `partials/S01.md` L16 自述"共32条阶段项：27条必做、2条条件项、3条可选项；另有9条贯穿门槛"逐字一致。

**本轮新增行的口径位置（重要）：** 本轮的 22 项任务行（T00、T05–T09、T15、T17–T24、T26–T32、T34、BLOCKERS）
**不属于原文 §2–§8 的 ID 清单**，也**不占用**任何原文 ID；它们记录的是本轮收尾阶段新增的交付。
因此**口径 A（41）与口径 B（32）的分母与分子本版完全不变**，仍为 **38/3** 与 **29/3**；
把第 5 版的 2 行补充（S01/S02）与本轮的 22 项任务行 + 1 行口径行（X-CONT）并入后的"合计口径"为
**A″ 66 行 63/3**（43 + 23）、**B″ 57 项 54/3**（34 + 23）；本轮另 8 行不一致/残留行
（D-01…D-05、R-02…R-04）**单列**，即 CSV 共 **76 行**。
三种读法都写出来，避免"改了分母"或"改了判定"的歧义。

### 1.3 两个口径的完成计数（本版快照 `424d733`+`f8fa4de`，全部已提交）

| 口径 | 分母 | 已满足 | 部分 | 未执行 | 条件未触发 | 可选未做 | 不一致未闭 | 必做子集完成率 |
|---|---:|---:|---:|---:|---:|---:|---:|---:|
| **口径 A：原文全量 41 行** | 41 | **38** | **0** | 0 | 0 | **3** | — | 必做 36 中 36 已满足（**100%**） |
| **口径 A′：41 行 + 第 5 版 2 行补充（S01/S02）** | 43 | **40** | **0** | 0 | 0 | **3** | — | 必做 38 中 38 已满足（**100%**） |
| **口径 A″：A′ + 本轮 22 项任务行 + X-CONT** | 66 | **63** | **0** | 0 | 0 | **3** | — | 必做 61 中 61 已满足（**100%**） |
| **口径 B：用户"32 项"（A–F 阶段项）** | 32 | **29** | **0** | 0 | 0 | **3** | — | 必做 27 中 27 已满足（**100%**） |
| **口径 B′：32 项 + 第 5 版 2 行补充** | 34 | **31** | **0** | 0 | 0 | **3** | — | 必做 29 中 29 已满足（**100%**） |
| **口径 B″：B′ + 本轮 22 项任务行 + X-CONT** | 57 | **54** | **0** | 0 | 0 | **3** | — | 必做 52 中 52 已满足（**100%**） |
| **CSV 合计（原文 41 + 补充 2 + 本轮 23 + 不一致/残留 8）** | 76 | **65** | 0 | 0 | 0 | **3** | **0**（8 行全部已闭合） | — |

> **A″/B″ 的"已满足 63/54"里含本轮的 23 行**（22 项任务行 + X-CONT）；A″ 的分母 66 = 43 + 23，
> B″ 的分母 57 = 34 + 23。两列都**不含** 3 项可选项，也**不含** 8 行不一致/残留行
> （D-01…D-05、R-02…R-04；X-CONT 已在 A″/B″ 内但不含在 A/B 内）。
> **CSV 的 76 行口径**：43（A′）+ 22（任务行）+ 1（X-CONT）+ 8（不一致/残留行）+ 2（D-01/D-02 已闭合行）= 76，
> 其中 8 行里的 D-01/D-02 就是那两个"已闭合行"，按状态列分开计（本文件 §2.1 表为准）。
> **"必做 100%"只针对原文 §2–§8 与本轮收尾计划的软件/实验交付条件**，不含竞赛方材料审核、
> 本人签署、官方验收（原文 §10），也**不含** R06 的 F1 这条未闭的技术缺口
> （F1 影响的是题面第 6 条的"部分"判定，不是原文 41 行里任何一行的判定）。

---

## 2. 汇总计数表

### 2.1 类型 × 状态 交叉表（自洽校验）

| 类型 | 已满足 | 部分 | 未执行 | 条件未触发 | 可选未做 | 已闭不一致 | 未闭不一致 | 小计 |
|---|---:|---:|---:|---:|---:|---:|---:|---:|
| 必做（含 B03 必做前置、B06/D03 之外） | 36 | 0 | 0 | 0 | 0 | 0 | 0 | **36** |
| 条件项（B06、D03） | 2 | 0 | 0 | 0 | 0 | 0 | 0 | **2** |
| 可选（C05、D06、E06） | 0 | 0 | 0 | 0 | 3 | 0 | 0 | **3** |
| **原文小计** | **38** | **0** | **0** | **0** | **3** | **0** | **0** | **41** |
| 补充（第 5 版 S01/S02） | 2 | 0 | 0 | 0 | 0 | 0 | 0 | **2** |
| **A′/B′ 小计** | **40** | **0** | **0** | **0** | **3** | **0** | **0** | **43** |
| 本轮任务行（T00/T05–T09/T15/T17–T24/T26–T32/T34/BLOCKERS） | 22 | 0 | 0 | 0 | 0 | 0 | 0 | **22** |
| 本轮口径行（X-CONT） | 1 | 0 | 0 | 0 | 0 | 0 | 0 | **1** |
| 本轮不一致/残留行（D-01…D-05、R-02…R-04） | 0 | 0 | 0 | 0 | 0 | **8** | **0** | **8** |
| **CSV 合计（76 行）** | **65** | **0** | **0** | **0** | **3** | **8** | **0** | **76** |

> **自洽校验：** 65 + 0 + 0 + 0 + 3 + 8 + 0 = **76** ✅。
> **CSV 的 76 行只有这四类计数**：**65 行已满足**（含 T18/T34 两行"本身已满足但附带未闭发现"）、
> **3 行可选未做**（C05/D06/E06，命令列为 `—`）、**8 行已闭合不一致**（D-01…D-05、R-02…R-04）、
> **0 行未闭不一致**。
> `§1.3` 与 §2.3 的 CSV 合计行按同一口径写为 **65/0/0/0/3/8/0**；本文件内不再使用其他合并读法。
> **唯一的未闭技术缺口是 T18 的 F1 低危发现**（登记在 T18 行内，不属"不一致"类，见 §3.9 与 §4.4 说明）。

- 条件项 B06 的触发条件（端到端家族不拒绝）已成立并已执行；D03 的"有 Pin 时运行 Microwalk"分支已实际达成。
- 机器可读版本见 [FINAL_AUDIT.csv](FINAL_AUDIT.csv)：**76 数据行 × 8 列**。
- **本版与上一版在原文 41 行上的判定完全相同**（38/0/0/0/3）：没有把任何"可选未做"改判，
  也没有新增未满足项；本轮全部新证据以**新增行**登记，不改写任何原文 ID 的判定。

### 2.2 分 Phase 计数

| 段 | 行数 | 已满足 | 已闭/未闭不一致 | 可选未做 |
|---|---:|---:|---|---:|
| G 贯穿门槛 | 9 | 9 | — | 0 |
| A 平台骨架 | 4 | 4 | — | 0 |
| B M2 KyberSlash | 7 | 7（含 B06 条件项已执行） | — | 0 |
| C M5 阴性对照 | 5 | 4 | — | 1（C05） |
| D M3 秘密访存 | 6 | 5（含 D03 条件项已达标） | — | 1（D06） |
| E M4 比较/有界验证 | 6 | 5 | — | 1（E06） |
| F Mona/报告/平台图 | 4 | 4（F02 报告已刷新到 **final5 91 页**；F04 由 `0d9876b` 补齐完成交接） | — | 0 |
| **S 第 5 版补充（原文 ID 清单之外）** | **2** | **2** | — | 0 |
| **T 本轮收尾交付（原文 ID 清单之外）** | **23** | **23** | — | 0 |
| **本版不一致/残留行（原文 ID 清单之外）** | **8** | 0 | **8 已闭（D-01…D-05、R-02…R-04），0 未闭** | 0 |

> 分 Phase 表只用于**原文 41 行**与两组补充行的可读性，**不是**完成率的分母口径；
> 分母口径一律以 §1.3 的 A/A′/A″/B/B′/B″ 与 §2.1 的 CSV 合计为准。

### 2.3 本轮实测的关键计数（全部由本审计独立重算，不照抄文稿）

| 计数项 | 本审计实测值 | 复核方式（可复跑） |
|---|---|---|
| R08 有效运行数 / 四判据通过 | **54 / 54** | 逐目录读 `remote/R08/<run>/controller/terminal.json` |
| R09 有效运行数 / 四判据通过 | **36 / 36** | 逐目录读 `remote/R09/<run>/controller/terminal.json` |
| R12(a) 锁频臂 / `restore_match=yes` | **9 / 9** | `remote/logs/status.log`（locked 行） |
| R12(a) 不锁频臂 / `config_changed=no` | **9 / 9** | `remote/logs/status.log`（unlocked 行） |
| R03 族外对照 / 四判据通过 | **18 / 18** | `docs/evidence/r03-malformed-20261016/logs/status.log` |
| **本轮锁频控制器运行合计** | **117 次，117/117 四判据全过（100%）** | 18+54+36+9，逐份日志与 terminal 重算 |
| 不锁频对照运行（**不可并入 117**） | **9 次** | R12 unlocked 臂；配置前后全量快照逐字相同 |
| 无效/失败运行（已归档、无计时值、不计入） | **19 次**（R08 18 + R09 1） | `R08/failed-blockcount-bug/`（18 目录，exit 2）与 `R09/failed/`（1 目录，`frequency_probe_rejected`） |
| 报告 final5 页数 | **91** | 三路互证：PDF 对象流 `/Type /Page` 计数 91；两遍 XeLaTeX `Output written … (91 pages)`；逐页 PNG 91 张 |
| 报告两遍 XeLaTeX 警告数 | **0 / 0** | `Overfull`/`Underfull`/`Missing character`/`LaTeX Warning`/`hyperref Warning` 计数均为 0 |
| 报告 PDF sha256 | `d391114c9269b0c0ed463e06f3fed38a1cbded783be81590b7ae18151960db20` | `shasum -a 256`，与 `pdf-metadata-audit.json` 逐字一致 |
| 匿名包 sha256 / 成员 / 身份标记 | `cacf94534bf7c0fda213007c427d5edbc5a9292fc7c4eea6fc0ffb4ba8289e2c` / **842** / **0** | 自跑包内 `verify_package.py` → `status=pass`、`direct_identity_markers=0`；**第 8 版更正**：两次被取代的成包为 `b54e2e4a…`（首次）与 `248e06d2…`（第一次重出），见 `-attempt1.json`/`-attempt2.json` |
| 包内解出复算 ctest | **5/5**（1.94 s） | `zip-recompute-final5.log` 逐行显示 cmake+build+ctest |
| 干净 clone quick 档 ctest | **194/194**（80+57+57） | `reproduce-quick-clean-clone.stdout.log` |
| R05 排查表格数 | **90 = 存在 5 / 不存在 75 / 不适用 10 / 未检查 0** | 逐行重读 §4.1 汇总行与三实现各 30 格 |
| R02 环境项 / 稳健性类对 | **28 项 / 64 个类对**（12 个翻转，7 家族内 + 5 族外） | `ENV_TABLE.md` 的 `^| N |` 行；`robustness.csv` 数据行 |
| T26/T27 图数 | **45 张** | `r04-stats-20261016/figures/` 文件数 |
| R09 12 格 | **12 行**（M1 未修/已修 + M5 × {-O0,-O2,-O3,-Os}） | `result.csv.cells.csv` 数据行 |
| T29 多工具矩阵 | **9 工具 × 5 模块 = 45 格** | `TOOL_MATRIX.csv`（9 数据行）；矩阵图 30 格有产物 |
| T34 签字清单项数 | **29 项**（A8+B4+C6+D6+E5），签字栏 3 行全空 | `^| [A-E][0-9] |` 计数 |
| 冻结 PLAN 摘要（执行版） | 四个摘要与 `BASELINE.md` 逐字一致 | `shasum -a 256` 四个 PLAN 文件 |
| 冻结 PLAN 摘要（`efca8a1` blob） | 四个摘要与 `BASELINE.md` 逐字一致 | `git cat-file blob efca8a1:<path>` 四份 |
| `verify_command` 实跑 | **73 条可执行的全部返回 0**（其余 3 条为 `—`，可选项未做） | `build/run_audit_commands.py`，逐条 `/bin/sh -c` |
| CSV 证据路径存在性 | **257 条全部存在，0 缺失** | 逐行切分并 `os.path.exists` |
| 本轮提交数 / 作者 | **27** 个提交，全部 `Gowin-liuyin` 为作者与提交者 | `git rev-list --count e81c1ae..HEAD`；`%an`/`%cn` 去重 |
| `sources`/`vendor` 是否被本轮触碰 | **未触碰** | `git diff --stat e81c1ae HEAD -- sources vendor` 为空 |

> **117 与 9 不可相加**：117 是走锁频控制器的运行数，9 是**不锁频对照**臂的运行数。
> 把两者相加成"126 次锁频运行"是错的；unlocked 臂恰恰是"没有写 sysfs"的那一臂。

---

## 3. 逐项审计矩阵（原文 41 行 + 第 5 版补充 2 行 + 本轮 33 行）

**图例：** 证据路径均为**本次实际 `test -f`/`os.path.exists` 复核**通过的仓库相对路径
（CSV 中 **257 条路径全部存在、0 缺失**）。`核对命令` 在仓库根 `/Users/yin/code/cryProject` 可直接执行；
完整命令见 `FINAL_AUDIT.csv` 的 `verify_command` 列（**73 条可执行的全部实跑返回 0**）。

### 3.1–3.7 原文 41 行

**判定与第 5 版完全一致（41 行 38/0/0/0/3），本版逐行复核未发现需要改判之处**，故此处不再重复
第 5 版已逐行给出的证据路径与说明——**请对照 [`FINAL_AUDIT-e81c1ae.md`](FINAL_AUDIT-e81c1ae.md) §3.1–§3.7
阅读原文 41 行的完整矩阵**（该文件为本版开始前的原字节副本，未被本版改写）。
本版只补三处与原文 41 行直接相关的事实更新：

| 行 | 第 5 版的表述 | 第 6 版的事实更新（不改判定） |
|---|---|---|
| **F02** | 报告终版 33 页、15 章、11 表、2 图、31 来源；两遍 XeLaTeX（`xelatex-final4-*.log`）0 警告 | **报告已重出为 final5：91 页**（PDF sha256 `d391114c…`），新增 R01/R02/R04/R05 补格/R06/R08/R09/R11/R12/T30 章节、附录 A 题面 12 条对照矩阵（表 T26）与图；两遍日志改为 `xelatex-final5-first.log` / `xelatex-final5-second.log`，**Overfull/Underfull/缺字/hyperref/LaTeX Warning 仍全 0**；R05 计数由 5/74/10/1 更新为 **5/75/10/0**。**边界**：题面 12 条里第 6 条仍记"部分"（唯一缺口 R06 的 F1），本审计不拔高 |
| **F04** | final4 匿名包 784 成员、33 页报告 | 交付载体推进到 **final5 匿名包 842 成员**（sha256 `cacf9453…`、`direct_identity_markers=0`、包内 ctest 5/5）与 **91 页报告**（`d391114c…`）；两份 deliverable README、`REFRESH.md`（第六阶段）、`run_zip_recompute_final5.sh` 与 `zip-recompute-final5.log` 已同步。**`HANDOFF_DONE.md` 已于 `83cd9df` 新增"全量收尾轮交接"（原 R-03 缺口已修）**，但该节仍引用被 `7387c01` 取代的包 sha `b54e2e4a…`，故 **R-03 仍判未闭** |
| **G05** | 54 次正式运行 `restore_match=yes`（平台四模块） | 本轮新增 **R08 54/54、R09 36/36、R12 锁频臂 9/9、R03 18/18**，**锁频控制器运行合计 117 次全部四判据通过**；另有 9 次不锁频对照（`config_changed=no` 9/9）与 19 次已归档的无效运行。G05 的判定（唯一锁频任务、退出恢复）**不变** |

### 3.8 第 5 版新增补充条目（2 行，原文 ID 清单之外）

**判定与第 5 版一致（均"已满足"）**；其中 S02 的口径在本轮补格后更新为 **5/75/10/0**（原 5/74/10/1）：
本轮实测 `docs/R05-全流程排查表.md` §4.1 汇总行 = `| **合计** | **5** | **75** | **10** | **0** | **90** |`，
原有 1 个"未检查"格（M2 重加密 × 提前返回）已补做并改判为"存在"，变更记录保留在 §2.3 与 §4.3。
逐行内容见 [`FINAL_AUDIT-e81c1ae.md`](FINAL_AUDIT-e81c1ae.md) §3.8 与 [FINAL_AUDIT.csv](FINAL_AUDIT.csv) 的 `S01`/`S02`。

### 3.9 本轮新增任务行（23 行，全部"已满足"；T18/T34 带未闭发现，BLOCKERS 登记项本身未解除）

| ID | 类型 | 要求产物 | 证据路径（已验证） | 状态 | 说明 / 剩余缺口（本审计实测） | 核对命令（已实跑返回 0） |
|---|---|---|---|---|---|---|
| T00 | 补充 | 基线核验 + 冻结 PLAN 前后 sha256 | `docs/evidence/closeout-20261016/{BASELINE.md,ctest-platform-on.log,ctest-ordinary.log,ctest-sanitize.log}` | 已满足 | 执行版四个 PLAN 摘要与实测逐字一致（`ab447ada…`/`0176288f…`/`3fc60d13…`/`c1c2c764…`）；`efca8a1` blob 四个摘要亦逐字一致；三套 ctest 87/87、57/57、57/57。**基线偏差如实保留**：计划书 `c849c0f` 已过期 11 个提交 | `grep -q ab447ada… BASELINE.md && [ "$(shasum -a 256 …/PLAN.md \| cut -c1-64)" = ab447ada… ]` |
| T05 | 补充 | 向量来源总表 | `docs/evidence/r01-kat-20261016/{VECTORS.md,logs/T05_T06_summary.tsv,SHA256SUMS}` | 已满足 | M1 两版各 60 例中过 35（keygen **0/25**、encap 25/25、decap 10/10，keycheck 20 例不适用）；M2 100/100；M3 on/off 80/80；M4 两臂 2/2（人工夹具）；M5 80/80。**M1 的 0/25 是 ipd 与最终稿的真实差异**，不写成"通过" | `grep -c '\| 80 \| 35 \|' VECTORS.md` 等 |
| T06 | 补充 | 修复语义等价（三对 diff + 1000 例 + 隐式拒绝） | `docs/evidence/r01-kat-20261016/{EQUIV.md,out/*.digest,logs/t06_*.log}` | 已满足 | 三对 diff 全空；`public_rejection_agree=10/10`、M2 `public_expected_match=100/100`、额外 1000 例 `extra_rejected=1000/1000`；摘要文件字节数与例数一致（64320/67200）故不是"少跑一部分"；M4 只做接口等价 | `grep -q 'extra_rejected=1000/1000' EQUIV.md` 等 |
| T07 | 补充 | 环境总表 28 项 | `docs/evidence/r02-env-20261016/{ENV_TABLE.md,collect_env.sh,clock_overhead_report.py,raw}` | 已满足 | 实测 28 项；**限制**：无 `isolcpus`、SMT 未关、39 个 running service、读钟开销 17.4–17.5 ns / 最小步进 10 ns（与 M4 窗口同量级） | `test "$(grep -cE '^\| [0-9]+ \|' ENV_TABLE.md)" -eq 28` |
| T08 | 补充 | 异常样本规则 | `docs/evidence/r02-env-20261016/{OUTLIER_RULES.md,robustness_analysis.py}` | 已满足 | 规则先于分析写定；**边界**：明确不删普通长尾，p99.9 截尾只作稳健性方法之一、不替换主口径 | `grep -qE '截尾\|长尾' OUTLIER_RULES.md` |
| T09 | 补充 | 稳健性敏感性分析（64 类对 × 4 方法） | `docs/evidence/r02-env-20261016/{ROBUSTNESS.md,robustness.csv,robustness.json,robustness-seedcheck.csv}` | 已满足 | 实测 64 个数据行；12 个翻转（7 家族内 + 5 族外），**没有任何翻转改变 Holm 判定**；翻转解释为功效差/量化失效，不作泄漏证据 | `test "$(python3 -c "…len(robustness.csv)-1")" -eq 64` 等 |
| T15 | 补充 | R05 补格：90 格 = 5/75/10/0 | `docs/R05-全流程排查表.md`、`docs/evidence/r05-locate-20261016/{RESULT.md,COMMANDS.md}` | 已满足 | §4.1 汇总行实测 `5/75/10/0/90`，三实现各 30 格；**边界**：74→75、1→0 是补格而非"查得更严"；"不存在/不适用"只收窄到固定源码/编译器/产物 | `grep -q '\| \*\*合计\*\* \| \*\*5\*\* \| \*\*75\*\*…' docs/R05-全流程排查表.md` |
| T17 | 补充 | R05 原生定位复跑 + 修复手段映射表 | `docs/evidence/r05-locate-20261016/{RESULT.md,SHA256SUMS.remote-tree.txt}`、`docs/evidence/r06-noleak-20261016/MAPPING.md` | 已满足 | 映射表 §1 实测 **16 个数据行**（M1 三/M2 三/M3 四/M4 两/M5 四），七个分类全有落点，M5 四行逐行声明"不是修复"。**该文件 §2 分组算术 6+5+4=15 与 16 行不符 → 本版登记为 D-03** | `test "$(grep -cE '^\| M[1-5]-[a-d] \|' MAPPING.md)" -eq 16` |
| T18 | 补充 | 日志/异常/返回码泄露专项审计 | `docs/evidence/r06-noleak-20261016/{AUDIT.md,audit.sh,audit.sh.log,static}` | 已满足（**含 1 条未闭低危发现 F1**） | 秘密内容泄露 **0 条**；动态 diff 为空（7 模式 × 120 次、退出码唯一值 0、逐字节一致）；Memcheck syscall 0（含 canary 负对照）；计时窗口 7/7 无 I/O。**F1 未闭**：`tools/platform_m2/collector.c` 门失败时把批级汇总写进 stderr/退出码/`run_status`，本轮**未构造门失败场景**，只做源码判定；未覆盖面（上游快照、网络、进程名、fd、maps、core dump、wait4、信号、/proc stat、子进程树、文件名与 mtime）如实列出 | `grep -q 'F1' AUDIT.md && grep -q '未覆盖面' AUDIT.md` |
| T19 | 补充 | R08 采集计划与命令清单（先提交后采集） | `docs/evidence/r08-perf-20261016/{PLAN.md,RUNS.sh,QUALIFICATION.log}` | 已满足 | 提交顺序实测：`deb9b05`（PLAN/RUNS.sh，04:15）严格早于 `8b206de`（采数，04:39）；`07ebf1b`（04:29）在采数前修正 block-count/block-index 不匹配。**边界**：性能不是秘密依赖性证据 | `test "$(git log --format=%ct -1 -- …/PLAN.md)" -lt "$(git log --format=%ct -1 -- …/perf.csv)"` |
| T20 | 补充 | R08 锁频采集 54 次 + 失败归档 | `docs/evidence/r08-perf-20261016/remote/R08{,/failed-blockcount-bug}`、`perf.csv.blocks.csv` | 已满足 | **独立重数 54/54 四判据全过**（不满足 0）；失败归档 **18** 个目录，逐条 `worker_finished` + `exit 2`、**无 CSV/meta** 故不计入；命名如实登记（`-attempt1` + 同名重跑，文件层面未覆盖）。**局限**：副本仍无 `during.json`/`entry-probes.json`，周期只能按名义 4300000 kHz | `test "$(find …/R08 -maxdepth 1 -type d -name 'r08-perf-*' \| wc -l)" -eq 54` 等 |
| T21 | 补充 | R08 性能开销表（25 行汇总 + 11 行成对） | `docs/evidence/r08-perf-20261016/{PERF.md,perf.csv,perf.csv.comparison.csv,perf.csv.samples.csv}` | 已满足 | 实测 `perf.csv` 25 行、`comparison.csv` 11 行；**口径局限**：周期按名义 4300000 kHz 换算、M4 用另一时钟且只在比较步内互比、操作顺序未随机化 | `test "$(python3 -c "…len(perf.csv)-1")" -eq 25` 等 |
| T22 | 补充 | R09 12 格构建/反汇编/Memcheck（先提交后采集） | `docs/evidence/r09-optlevel-20261016/{PLAN.md,BUILD.md,disasm,memcheck,qualification,result.csv.cells.csv}` | 已满足 | 实测 12 个格子行；`disasm/` 32 文件、`memcheck/`、`qualification/` 25 条；提交顺序 `deb9b05`(PLAN) → `a99a9a9`(12 格判定)。**边界**：产物 + Memcheck 判定不是统计结论 | `test "$(python3 -c "…len(cells.csv)-1")" -eq 12` 等 |
| T23 | 补充 | R09 锁频实测 36 次 + 1 次被拒归档 | `docs/evidence/r09-optlevel-20261016/remote/R09{,/failed/r09-os-m1unfixed-s2-attempt1}`、`result.csv` | 已满足 | **独立重数 36/36 四判据全过**；失败归档 **1** 个，`reason=frequency_probe_rejected`（跨度 54629 kHz > 50000 kHz，20 值仍在 ±2% 带内）、无计时值。**边界**：该次只说明**跨度**判据触发，不说明频率不稳或泄漏 | `test "$(find …/R09 -maxdepth 1 -type d -name 'r09-*' \| wc -l)" -eq 36` 等 |
| T24 | 补充 | R09 优化级别对照结论 + 图 | `docs/evidence/r09-optlevel-20261016/{RESULT.md,figures}` | 已满足 | `figures/` 2 个文件；`RESULT.md` 文末补充已把"当时无 controller 目录"更新为 **36/36 四判据全过**（原文未改）。**边界**：`m1unfixed-Os` 与冻结 M1 的级别差预先写明；s1/s2 在 CPU2、s3 在 CPU6；gcc 与 `-O1/-Oz/-Og` 未做 | `grep -q '36/36' RESULT.md` |
| T26 | 补充 | 功效/MDE（41 主类对 + 臂级汇总） | `docs/evidence/r04-stats-20261016/{POWER.md,figures}` | 已满足 | MDE 覆盖 41 主类对；`figures/` 45 张；M1 口径已更正为预注册家族 **m=6**、α_eff 0.008333，结论不变（+39.337 ns > 31.3901 ns；−13.209 ns < 35.5613 ns）。**本版新发现**：§4 与 §5.1 仍写"族外/没有预注册 Holm 家族" → 登记为 **D-05** | `grep -q 'M1 冻结家族' POWER.md` 等 |
| T27 | 补充 | 分位数差 bootstrap CI 与图 | `docs/evidence/r04-stats-20261016/{QUANTILE_CI.md,figures,robustness-src}` | 已满足 | 含 ECDF / 箱线图共 45 张。**必须一起读的限制**：有效计时量化尺度约 10 ns，与 M4 夹具 20–30 ns 窗口同量级，故 M4 只用均值结论、不用分位数结论 | `grep -qE '10 ns\|量化尺度' QUANTILE_CI.md` |
| T28 | 补充 | 威胁模型章（含可 `\input` 的 LaTeX） | `docs/evidence/r11-threat-20261016/{THREAT_MODEL.md,threat-model.tex}` | 已满足 | `threat-model.tex` 已被报告 `\input` 直接并入且两遍编译 0 警告。**边界**：攻击者只能控制密文、只能观测单次调用耗时；**网络路径未执行**（T25/B01），只写"未执行"不写"未检出" | `test -s threat-model.tex && grep -q 未执行 THREAT_MODEL.md` |
| T29 | 补充 | 创新对照 (a) 锁频 vs 不锁频 + 多工具矩阵 | `docs/evidence/r12-innovation-20261016/*`、`remote/logs/status.log` | 已满足 | 实测 `innovation_a.csv` 18 行、`status.log` 18 行（locked 9/9 `restore_match=yes`、unlocked 9/9 `config_changed=no`）、`remote/runs/` 18 目录、`TOOL_MATRIX.csv` 9 行 × 5 模块。**结论如实反直觉**：unlocked 合并 SD 反而更低（比 0.741/0.757/0.956），频率归一后 CV 比 0.96/1.01/1.09 跨臂方向不一致 → **锁频不必然降方差**，其价值是"确定性、可核对、可恢复的固定工作点"。**边界**：unlocked"未改配置"不证明系统频率恒定；M5 假阳性 0/3 与 0/3 只作描述 | `test "$(python3 -c "…len(innovation_a.csv)-1")" -eq 18` 等 |
| T30 | 补充 | 一键复现入口与参数总表 | `scripts/reproduce_all.sh`、`docs/REPRODUCE-PARAMS.md`、`docs/evidence/r12-innovation-20261016/reproduce-quick-clean-clone*.log`、`REPRODUCE-QUICK-LOG.md` | 已满足 | 干净 clone quick 档 **194/194**（80+57+57）。**边界**：quick 档不需 sudo、不写 sysfs；full 档默认 dry-run、`--execute` 才真跑；干净 clone **缺 `.gitignore` 的 vendor/third_party**，quick 档缺件即跳过，故 194/194 是"可复现的最小集"（B05） | `grep -q '100% tests passed, 0 tests failed out of 80' …stdout.log` |
| T31 | 补充 | 报告 final5：91 页、0 警告、附录 A 12 条矩阵、第 6 条"部分" | `deliverables/research/multi-leakage-platform-20261016/{report.pdf,report.tex,report.md}`、`docs/evidence/platform-report-20261016/{refresh-20261016/xelatex-final5-*.log,final5-20261016/pdf-metadata-audit.json,VISUAL_QA.md,RESULT.md}` | 已满足 | **三路互证 91 页**（PDF 对象流 `/Type /Page` = 91、两遍日志 `(91 pages)`、逐页 PNG 91 张）；两遍警告全 0；PDF sha256 与审计 json 一致。**第 6 条如实保留"部分"**（唯一缺口 R06 的 F1），**本审计不拔高成"满足"**；12 条中 11 满足 + 1 部分 | `[ "$(grep -c 'Output written.*(91 pages)' …first.log)" -eq 1 ]` 等 |
| T32 | 补充 | final5 匿名包：842 成员、verify pass、`direct_identity_markers=0`、包内 ctest 5/5 | `deliverables/support/…/CACR2026EA16XZ-platform-final5-20261016.zip`、`docs/evidence/platform-report-20261016/{final5-20261016/*,refresh-20261016/{zip-recompute-final5.log,run_zip_recompute_final5.sh}}` | 已满足 | 实测 sha256 `cacf9453…`（`d2ad9c9` 最终重出；前两次 `b54e2e4a…`/`248e06d2…` 见 `-attempt1.json`/`-attempt2.json`）、842 成员、自跑包内 `verify_package.py` → `status=pass` / `direct_identity_markers=0`；解出后 ctest **5/5**（1.94 s）。**边界**：包内 ctest 是 5 个测试，**不是**仓库根 87/57/57 全套；verify 只查直接字节/文本标识，不排除公开内容关联；842 成员是过滤后的可公开子集 | `[ "$(python3 -c "…len(zip)-1")" -eq 842 ]` 等 |
| T34 | 补充 | 人工复核签字清单（**待人工执行**的交付物） | `docs/evidence/closeout-20261016/SIGNOFF_CHECKLIST.md` | 已满足（**清单本身 ≠ 人工复核已完成**） | 实测 **29 项**（A8+B4+C6+D6+E5），签字表 3 行全空。**本版新发现**：`docs/full-work-progress.md` 的 T34 行写"23 项" → 登记为 **D-04**；另该清单表头引用的"43 行 × 8 列"对本版已过期 → **R-04**。清单不构成竞赛方验收 | `test "$(grep -cE '^\| [A-E][0-9]+ \|' SIGNOFF_CHECKLIST.md)" -eq 29` |
| BLOCKERS | 补充 | 阻塞与降级登记（B01–B05 + 4 项随结论一起读） | `BLOCKERS.md` | 已满足（**5 条阻塞本身全部未解除**） | 实测 B 表 5 条 + 编号 1–4 共 4 条：B01 网络场景未执行、B02 M5 重加密 Binsec `checkct` 仍 **unknown**、B03 Microwalk 官方镜像不可用、B04 ctgrind 上游补丁与 Valgrind 3.22 不兼容、B05 干净 clone 缺件。**没有一条被写成"已解决"** | `test "$(grep -cE '^\| B0[0-9] \|' BLOCKERS.md)" -eq 5` 等 |

> **本组共同边界（不因"已满足"而升级）**：T05/T06 的通过数不等于规范符合性（M1 keygen 0/25 是真实差异、
> M2 是历史 Kyber）；T07/T09 的"未隔离"与"翻转"都不是恒时结论；T18 的 F1 **未闭**；
> T20/T21/T23/T24 的性能与优化级别**不是秘密依赖性证据**；T26/T27 的 MDE 是事后功效描述；
> T28 的网络路径**未执行**；T29 的锁频价值**不含"降低方差"**；T30 的 194/194 是缺件跳过后的最小集；
> T31 的题面第 6 条**仍是"部分"**；T32 的包内 ctest 是子集；T34 的清单**待人工执行**；
> BLOCKERS 的 5 条**全部未解除**。

### 3.10 本轮不一致 / 残留 / 口径行（9 行；其中 X-CONT 是口径行、**8 行已全部闭合、0 行未闭**）

| ID | 级别 | 内容 | 闭合提交 / 状态 | 实测依据 |
|---|---|---|---|---|
| **X-CONT** | 口径行 | 本轮锁频运行 117 次 117/117 四判据全过；不锁频对照 9 次 `config_changed=no` 9/9；两者**不可相加** | 口径行（无判定） | 18+54+36+9 逐份日志与 terminal 重算；见 §2.3 |
| **D-01** | 已闭 | 报告 §24 第 4 处：R08/R09 控制器日志时间差（`PERF.md`/`r09 RESULT.md` 写"副本没有 controller 目录"） | ✅ **已闭合（`6c10f4d`，05:38）** | 两文件把表述改为"**当时**无法…复核"（原文保留），文末各追加"补充（主控 2026-10-16 05:10）"给出 **54/54** 与 **36/36** 实测；R09 另记 `entry-probes.json` 已在副本内。**残留边界保留**：R08 仍缺 `during.json`/`entry-probes.json`，周期仍只能按名义基频 |
| **D-02** | 已闭 | 报告 §24 第 1 处：`MAPPING.md` 自述"表内行数 15" vs 实际 16 | ✅ **已闭合（`6c10f4d`）** | §2 改为"表内数据行 **16**（原自述写 15，主控 2026-10-16 按实际行数更正）"；§1 表实测 16 行。**残留见 D-03** |
| **D-03** | ✅ 已闭 | `MAPPING.md` §2 分组算术原写 6 + 5 + 4 = 15，与同表实际 16 行不符 | ✅ **已闭合（工作区已修正；`HEAD 7387c01` 尚未包含）** | 现文为「上游/历史实现 6 行 + **人工构造校准 6 行**（M3-a/b/c/d 四行 + M4-a/b 两行；原自述写 5 行，主控 2026-10-16 按实际行数更正）+ 上游既有做法 4 行」= **16**，与表内 16 行一致；本次 `grep -q '人工构造校准 6 行'` 实测通过 |
| **D-04** | ✅ 已闭 | `docs/full-work-progress.md` T34 行原写"23 项"，`SIGNOFF_CHECKLIST.md` 实为 **29 项** | ✅ **已闭合（工作区已修正；`HEAD 7387c01` 尚未包含）** | 现文为「人工复核签字清单（**29 项**，签字栏留空）」；本次 `^\| [A-E][0-9]+ \|` 重数 A8+B4+C6+D6+E5 = **29**，与清单一致 |
| **D-05** | ✅ 已闭 | `POWER.md` §5.1 原首句与 §1 更正块自相矛盾 | ✅ **已闭合（`008c516`，05:54）** | 段首现为「这两个数**属于 M1 预注册的 m=6 家族**…按 α_eff=0.05/6 计算」，旧口径以「（`PROTOCOL.md` 里那句「没有 Holm」…已被 `r02-r04-close-20261016/PLAN.md` 预注册的 m=6 家族与冻结的 `holm.csv` 取代。）」保留；实测 §4 两行 = **M1 m=6**、全文 `没有预注册 Holm 家族` **0 命中** |
| **R-02** | ✅ 已闭 | 报告来源摘要与当前来源字节的时间差 | ✅ **已闭合（`6c10f4d` 改来源 + `e6b35cf` 重跑生成器与两遍 XeLaTeX）** | `REFRESH.md` §J4 第 4 条现写「60 份来源实测 **0 stale**，重出的 PDF 与修正前**逐字节相同**（`d391114c…`）」，原文保留；本次独立实测 `report.pdf` sha256 = `d391114c9269b0c0ed463e06f3fed38a1cbded783be81590b7ae18151960db20`，与 `final5-20261016/pdf-metadata-audit.json` 一致 |
| **R-03** | ✅ 已闭 | 交接节曾引用被取代的包 sha | ✅ **已闭合（`008c516` 改文本 + `d2ad9c9` 最终重出）** | 交接节现写 **当前有效 `cacf94534bf7c0fda213007c427d5edbc5a9292fc7c4eea6fc0ffb4ba8289e2c`**（842 成员），并注明两次被取代成包 `b54e2e4a…`/`248e06d2…` 分别存于 `-attempt1.json`/`-attempt2.json`；磁盘唯一 final5 包实测与其一致 |
| **R-04** | ✅ 已闭 | `SIGNOFF_CHECKLIST.md` 表头原写"43 行 × 8 列"，对第 6 版已过期 | ✅ **已闭合（工作区已修正；`HEAD 7387c01` 尚未包含）** | 现文为「**76 行 × 8 列（第 6 版）**、证据路径 0 缺失、**73 条 `verify_command` 全部返回 0**」；本次独立重数 CSV = **76** 行、非占位命令 = **73** 条，与该表头一致（本版未增行，口径保持有效） |

---

## 4. 矛盾清单（硬矛盾 **0** 条；需处理不一致 **C-01…C-11 与 D-01…D-05、R-02…R-04 全部闭合，未闭 = 0**）

### 4.1 硬矛盾判定：**0 条**

客观核验（本版重跑）：

- CSV 中 **255 条带目录前缀的证据路径全部存在**（脚本复验，0 缺失；若把裸文件名 `HANDOFF_DONE.md`、`BLOCKERS.md` 也计入则为 258 条、同样 0 缺失。第 6 版正文写的 257 其提取规则未随脚本保留，本版改用可复现的规则并把差异写明）；
- 证据目录内 Markdown 相对链接无断链（沿用第 5 版扫描口径，本版新增文件已并入 CSV 路径集）；
- CSV 的 **73 条可执行 `verify_command` 全部实跑返回 0**（76 行中 3 行为可选未做、命令列为 `—`）；
- `COMPLETION_REQUIREMENTS.md` 内 20 条可解析相对引用中 19 条按文档相对路径直接命中，
  第 20 条是裸名写法 `version-audit/fetch_vendor.sh`（实际文件在
  `docs/evidence/m2-kyberslash-20261016/version-audit/fetch_vendor.sh`，存在）——判定为**引用写法**问题，
  硬矛盾仍为 0（与第 5 版同口径）。

### 4.2 C-01…C-11（第 1–5 版登记的历史不一致）：**11/11 全部闭合，本版复核未回退**

| 编号 | 状态 | 本版复核 |
|---|---|---|
| C-01 | ✅ 已闭合（`a30d7c7` 轮） | `platform-matrix-20261016/RESULT.md` 已同步 M3/M4/M5 行与逐模块运行数表；sha256 与第 5 版一致（`dfdfa60e5ca4c48d`），未回退 |
| C-02 | ✅ 已闭合（`b637d0d`） | 三个文件的"状态更新（2026-10-16，主控）"块仍在；`m3-memaccess/NOTES.md` sha256 = `88b3a31dba17a520`（第 5 版记录值），未回退 |
| C-03 | ✅ 已闭合（`b637d0d`） | `partials/S01.md` 的"基线更正"块仍在（本版未改它；本版自己的基线声明写在本文件头部） |
| C-04 | ✅ 已闭合（`b637d0d`） | `m3-completion-20261016/{RESULT.md,TESTS.md}` 仍在；TESTS.md sha256 = `551ac10462446824`，未回退 |
| C-05 | ✅ 已闭合（`0d9876b`；随 final4 复审；**本版随 final5 复审**） | 页数权威来源已推进到 **91**：`RESULT.md`、`VISUAL_QA.md`、`final5-20261016/pdf-metadata-audit.json`（`pages: 91`）、`report.pdf` 三路互证一致；第 5 版的 33 页值已随 final5 更新，**未出现新的页数自相矛盾** |
| C-06 / C-07 / C-08 / C-09 / C-10 | ✅ 已闭合（`0d9876b`；C-10 于 `b94e942` 升级为"已修"） | `.csv.gz` 命名、`platform-boundary-cleanup-20261016/` 入库、`.meta` 静态字段说明、§1.0"blob 内容再算 SHA-256"措辞、`avx2/.gitignore` 已是普通文件——第 5 版逐项复核，本版未发现回退 |
| C-11 | ✅ 已闭合（`7a71d5c`） | `HANDOFF_DONE.md` 的"2026-10-16 收尾轮交接（主控）"整节仍在。**但该节本身已随本轮交付而过期** → 本版新登记 **R-03**（C-11 的"闭合"指第 5 版指出的那个时点缺口已补；R-03 是新一轮的同类缺口） |

### 4.3 第 6 版登记的 6 条：第 8 版复核后**逐条结论（6/6 全部已闭）**，全部为文件表述/时点类，**不改变任何数字与判定**

| 编号 | 级别 | 内容与实测依据 | 影响 | 解除条件 |
|---|---|---|---|---|
| **D-03** | ✅ 已闭 | 分组现为 6 + **6** + 4 = 16，与同表一致 | 不改任何映射结论 | 已满足；**修正待提交**（工作区） |
| **D-04** | ✅ 已闭 | 进度记录 T34 现写 **29 项**，与清单实测 29 项一致 | 不受影响 | 已满足；**修正待提交**（工作区） |
| **D-05** | ✅ 已闭 | §5.1 首句已整段改写为"属于 M1 预注册的 m=6 家族…"，旧口径以"已被 PLAN/`holm.csv` 取代"保留 | MDE 数字与结论不变；同段不再自相矛盾 | 已满足（`008c516`）；实测旧矛盾句 0 命中 |
| **R-02** | ✅ 已闭 | `REFRESH.md` §J4 第 4 条已写明重跑后 **0 stale**、PDF 与修正前**逐字节相同**（`d391114c…`） | 已解除 | 已满足（`6c10f4d` + `e6b35cf`） |
| **R-03** | ✅ 已闭 | 交接节包摘要已改为当前有效 `cacf9453…`，并注明两次被取代成包 | 第三方按该 sha 校验可通过 | 已满足（`008c516` + `d2ad9c9`） |
| **R-04** | ✅ 已闭 | 表头现写 **76 行 × 8 列（第 6 版）/ 73 条命令**，与实测一致 | 不受影响 | 已满足；**修正待提交**（工作区） |

> **与"矛盾清单降到 0 未闭"的关系（如实说明）：** 报告 §24 登记的那 **4 处**（R08/R09 时间差、
> MAPPING 行数、POWER §5 家族列、M5 4 格措辞）**已全部由 `6c10f4d` 闭合**，逐条核实见 §4.4。
> 本轮审计在第 6 版登记的 6 处表述/计数/时点缺口，**第 8 版复核结果为 6/6 全部闭合**：
> D-03 ✅、D-04 ✅、R-02 ✅、R-04 ✅（`008c516` 一并提交）、**D-05 ✅**（`008c516`）、**R-03 ✅**（`008c516` + `d2ad9c9`）。
> 因此本审计结论是：**报告登记的那 4 处 = 0 未闭；本审计口径下的未闭不一致 = 0 处**。
> 唯一仍登记在案的未闭项是 **T18 的 F1 低危发现**（`tools/platform_m2/collector.c` 失败门只做源码判定、
> 未构造门失败场景），它属"技术缺口登记"而非"文件不一致"，自第 6 版起未变化，题面第 6 条据此保留"部分"。
> **时点事实（已在第 8 版消除）**：D-03/D-04/D-05/R-04 四处修补与本次审计产物曾只在工作区；
> 现 `008c516` 已一并提交，**`git status` 无已跟踪改动**。

### 4.4 报告 §24 登记的四处不一致：逐条核实到闭合提交

| # | 报告 §24 的原始描述 | 闭合提交 | 本版逐条核实结果 |
|---|---|---|---|
| 1 | `MAPPING.md` §1 实际 16 行，§2 自述"表内行数 15" | **`6c10f4d`** | ✅ 已闭。§2 改为"表内数据行 **16**（原自述写 15，主控 2026-10-16 按实际行数更正）"；§1 表实测 16 行。报告表 T18 表注里的"该文件 §2 自述 15…登记为待澄清项"已由本次更正解决（报告不改判）。**同处的分组算术仍不符 → D-03** |
| 2 | `POWER.md` §1 已更正 M1 为预注册 Holm 家族（m=6），§5 家族列仍标"族外" | **`6c10f4d`** | ✅ 该处已闭。§5 明细表两行改为 `**M1 m=6**` / `0.008333333`；同时 §1 正文、§1.4 家族表也已更正（`grep 族外` 在 §5 已无 M1 行）。**更正未覆盖 §4 臂级汇总两行与 §5.1 → D-05** |
| 3 | 「M5 × 可变时间比较」4 格：R05 判"不存在" vs `BLOCKERS.md` 第 1 条"工具不适用型 unknown" | **`6c10f4d`** | ✅ 已闭。`BLOCKERS.md` 第 1 条改写为：R05 本体的判定是**"不存在"**（源码层无 `div`），这里说的 **unknown 指工具覆盖**——varlat 这类专查除法的工具对 M5 不适用（三模式各 10 次完整解封装 0 errors/0 contexts），**不是与 R05 冲突、也不是"未检出泄漏"**。两处措辞现已对齐，报告按 R05 本体引用 |
| 4 | R08/R09 controller 目录补入归档造成的时间差（`PERF.md`/`r09 RESULT.md` 仍写"没有 controller 目录"） | **`6c10f4d`** | ✅ 已闭（对两份文件而言）。两文件把表述限定为"**当时**无法从已拉回副本复核"（不改原文数值），文末追加补充给出 **R08 54/54、R09 36/36** 四判据实测。**残留**：R08 仍无 `during.json`/`entry-probes.json`（周期换算仍只能按名义基频）；报告 §24 仍以"待回填"口径描述 → **R-02** |

---

## 5. 冻结 PLAN sha256 前后一致性（本版独立复算）

**三方比对，全部逐字一致：**

| PLAN 文件 | `BASELINE.md` 记录的执行版 sha256 | 本机当前实测 | `git cat-file blob efca8a1:<path>` |
|---|---|---|---|
| `docs/evidence/m2-kem-20261016/PLAN.md` | `ab447adadeb5aae2b79843946ab38a6e7a5412506a13d9abd738c3c22a9a9a20` | ✅ 相同 | `0f706455c6a8fde28ecd3dc18fb12ae4562c2f57dc7e2d991b5ff83c5cd07142`（与 BASELINE 记录一致） |
| `docs/evidence/m5-completion-20261016/PLAN.md` | `0176288fbe8b95419fbacd0a216fe6aa5106445f5b0ca368d0d33e79b62a408e` | ✅ 相同 | `15738beea1e8d22ae58f83ed741636c2bcf7d9f49e16f0c5c0f2f8590c323e44`（一致） |
| `docs/evidence/m3-completion-20261016/PLAN.md` | `3fc60d1319d9da2a5246c1aa83760c46bcdac4131f98d610f9805be9f22ed4db` | ✅ 相同 | `be2db4599fb9c5d39852f001d3cf872173b68c2d65ebb4ca542ea0798e01a4a0`（一致） |
| `docs/evidence/m4-completion-20261016/PLAN.md` | `c1c2c7647c65f85e6b38df12132dc3e73f83cfcd1862207b7f5e24992539d34a` | ✅ 相同 | `767f0378124645f9830b14cfbff61fb2571cbf050b451b93fbe74ac8256f509a`（一致） |

**读法（重要，不得混为一谈）：** 执行版摘要与 `efca8a1` blob 摘要是**两套不同的值**，这不是矛盾——
`efca8a1` 是**冻结那次提交**的 blob；此后各 PLAN 各有一次**文档修订**（不改类对/预算/Holm 家族/α/停止规则），
执行用的是修订后的内容。`BASELINE.md` 把**两套值都记下来**，本审计把**两套都比对了一遍**：
执行版 = BASELINE 记录 = 当前文件；冻结版 = BASELINE 记录 = `git cat-file blob efca8a1:<path>` 复算值。
**不存在"冻结 PLAN 被改动"的情况**：`git diff --stat e81c1ae HEAD -- docs/evidence/*/PLAN.md` 为空，
本轮 27 个提交没有触碰任何 PLAN 文件。

另有一例独立绑定：`docs/evidence/r03-malformed-20261016/PLAN.md` 的 sha256 `79edb27f8339691f…`
与同目录 `RESULT.md` 记录的 `--plan-sha256` 逐字一致（第 5 版已复核，本版未变）。

---

## 6. 审计方法与快照摘要

完整方法、命令与实跑记录见 [`partials/S11.md`](partials/S11.md)（第 6 版）。
第 4/5 版见 [`partials/S10.md`](partials/S10.md)，第 3 版见 [`partials/S09.md`](partials/S09.md)。

**本版方法要点（全部在 `/bin/sh -c` 下实跑，逐条核对返回码）：**

1. **快照冻结与历史保全**：先把第 5 版 `FINAL_AUDIT.{md,csv}` 以 `cp -p` 原字节另存为
   `FINAL_AUDIT-e81c1ae.{md,csv}`，用 `cmp` 确认逐字节相同，并确认两者的 sha256
   与 `BASELINE.md` 记录的"关键交付物 sha256"逐字一致——这把第 5 版的字节与该次基线锁定在一起。
2. **口径复算**：逐行提取 41 个原文 ID（与 `S01.md` 自述交叉核对：32 阶段项 + 9 贯穿门槛），
   再按同一标准处理第 5 版的 S01/S02 与本轮的 22 项任务行；**A/B 两个口径的分母与分子本版不变**。
3. **路径存在性**：CSV **257 条路径**逐条 `os.path.exists`（0 缺失，注解用全角括号剥离后判定）；
   新行追加前先对 26 个新路径做存在性断言（不存在即脚本退出）。
4. **内容级核验**（不只验存在）：varlat 1280/3 对 0/0；M3 Memcheck 1280/2 对 0/0；
   M4 Valgrind 32/1 对 0/0；Binsec insecure 对 bounded secure；M5 三模式 0/0 且 exit 0；
   控制器 **54** 次 `controller_exit=0`+`restore_match=yes`；Holm 家族与 Δ/CI/I²；
   RTLF 42/42；Microwalk MI 1.922 bits；Mona M1+M2 十二行；R03 `status.log` 18/18 且 20/20 在带内；
   R05 §4.1 汇总行 5/75/10/0/90；`final5` 实包复算 CTest 5/5；PDF 91 页；六库 HEAD 与 REPOS.md 逐一相等。
5. **本轮新增的独立重数**（本版特有，不看文稿）：逐目录读 R08 **54** 份与 R09 **36** 份 `terminal.json`
   按四判据判定（54/54、36/36）；逐份读 R03/R12 `status.log`（18/18、locked 9/9、unlocked 9/9）；
   逐行数 `robustness.csv`（64）、`result.csv.cells.csv`（12）、`innovation_a.csv`（18）、
   `TOOL_MATRIX.csv`（9 行 × 5 模块）、`perf.csv`（25）、`perf.csv.comparison.csv`（11）、
   `ENV_TABLE.md`（28 项）、`SIGNOFF_CHECKLIST.md`（29 项）、`BLOCKERS.md`（5 + 4）、
   `MAPPING.md`（16 行）、R05 汇总行（5/75/10/0/90）。
6. **报告三路互证**：`shasum -a 256` 比对审计 json；自写 Python 把 PDF 对象流解压后数 `/Type /Page`
   （**91**，不经报告生成器）；两遍 XeLaTeX 日志 grep `Output written … (91 pages)` 与五类警告计数**全 0**；
   逐页 PNG 计数 **91**。题面第 6 条的"部分"用 `grep` 直接命中确认，**未拔高**。
7. **匿名包实跑**：`shasum -a 256` 比对；用 Python `zipfile` 数成员（**842**）；
   把包内 `verify_package.py` 解到 `build/` 后**自己重跑**（`status=pass`、`direct_identity_markers=0`）；
   核对 `zip-recompute-final5.log` 的 `100% tests passed, 0 tests failed out of 5`。
8. **矛盾闭合核实**：对报告 §24 登记的四处，逐处 `git show 6c10f4d` 看 diff 并回到当前文件 `grep`
   确认措辞已改到位；同时**主动找残留**，因此在同一批文件里新发现 6 处未闭表述（§4.3）。
9. **G03 密码学绑定复核**：`git cat-file blob efca8a1:<4 个 PLAN 路径> | shasum -a 256`
   与 `BASELINE.md` 表逐字一致；执行版与当前文件亦逐字一致（见 §5）。
10. **提交状态**：`e81c1ae..HEAD` = **27** 个提交，作者与提交者唯一为
    `Gowin-liuyin <yinhaoran0808@outlook.com>`；`origin/main`（`e81c1ae`）是 HEAD 的祖先，
    `origin/main..HEAD` = **27（未 push）**；`git status` 无已跟踪改动；
    `git diff --stat e81c1ae HEAD -- sources vendor` 为空。
11. **命令实跑**：`python3 build/run_audit_commands.py` 逐条 `/bin/sh -c` 执行 CSV 的 `verify_command`，
    结果 **ran=73 / exit0=73 / non-zero=0 / no-command=3**（3 条为 C05/D06/E06 可选项、命令列 `—`）。

**快照摘要（sha256，供最终比对是否被后续写入改变）：**

| 文件 | sha256 | 第 5 版值 / 说明 |
|---|---|---|
| `docs/platform/COMPLETION_REQUIREMENTS.md` | `31cac9c7b848585c…` | 与第 1–5 版一致，**未变** |
| `docs/evidence/platform-completion-20261016/FINAL_AUDIT-e81c1ae.md` | `9ec07698f86354cf9eba722b8c334cfafba9b960c1b0793b5908705f677e0d1c` | **第 5 版原文**（= `BASELINE.md` 记录值；`cmp` 与冻结前 `FINAL_AUDIT.md` 逐字节相同） |
| `docs/evidence/platform-completion-20261016/FINAL_AUDIT-e81c1ae.csv` | `9154df71e724ab11a77343a5abd6819d3b0815411a9741d666bfaf54c4140311` | **第 5 版原文**（= `BASELINE.md` 记录值） |
| `docs/evidence/platform-completion-20261016/FINAL_AUDIT.md` | **本文件不记自身 sha256**（记了就会被下一次写入作废）；请用 `shasum -a 256` 现算，与 `FINAL_AUDIT.csv` 的 76 行 × 8 列一起比对 | **本版（第 6 版）** |
| `docs/evidence/platform-completion-20261016/FINAL_AUDIT.csv` | `b9dd03a0ce3fd88c5d1509356ea195446582a41f25c60ab009e8f52e1b383204` | **本版（第 6 版）**：76 数据行 × 8 列；**前 43 行中除 S02 一行（R05 计数更新为 5/75/10/0）外，其余 42 行与第 5 版逐字节相同，行序未变** |
| `docs/evidence/platform-completion-20261016/partials/S11.md` | `10055541f67fccb1891a480ff4609dc193227159a9a71e44cbdd45966648a75e` | 本版方法记录（本轮新增） |
| `docs/evidence/closeout-20261016/BASELINE.md` | `9ec07698f86354cf…`/`9154df71e724ab11…` 两值在案 | 记的 FINAL_AUDIT 摘要 = 第 5 版，本版未改该文件 |
| `deliverables/research/multi-leakage-platform-20261016/report.pdf` | `d391114c9269b0c0ed463e06f3fed38a1cbded783be81590b7ae18151960db20` | **本版核验**：91 页、与 `pdf-metadata-audit.json` 一致（第 5 版为 `570ab957…`/33 页） |
| `docs/evidence/platform-report-20261016/final5-20261016/pdf-metadata-audit.json` | `pages=91` / `direct_private_markers=0` | 本版核验 |
| `docs/evidence/platform-report-20261016/final5-20261016/package-verification.json` | `members=842` / `direct_identity_markers=0` | 本版核验；`zip_sha256` 与包实测一致 |
| `deliverables/support/…/CACR2026EA16XZ-platform-final5-20261016.zip` | `cacf94534bf7c0fda213007c427d5edbc5a9292fc7c4eea6fc0ffb4ba8289e2c` | **第 8 版实测**（`d2ad9c9` 最终重出）：842 成员、verify pass、包内 ctest 5/5；`b54e2e4a…`/`248e06d2…` 为被取代的两次成包 |
| `docs/evidence/r08-perf-20261016/PERF.md` | 含"补充（主控 2026-10-16 05:10）"节 | `6c10f4d` 追加（D-01 闭合） |
| `docs/evidence/r09-optlevel-20261016/RESULT.md` | 含 36/36 补充说明节 | `6c10f4d` 追加（D-01 闭合） |
| `docs/evidence/r06-noleak-20261016/MAPPING.md` | `8510c2e799052497` | §2 分组已改 6 + **6** + 4（D-03 ✅ 闭合；**工作区修正，未提交**） |
| `docs/evidence/r04-stats-20261016/POWER.md` | `a0f60efa6e411c8f` | §5.1 首句已改写、旧口径以"已被 PLAN/`holm.csv` 取代"保留；**旧矛盾句 0 命中（D-05 ✅ 闭合，`008c516`）** |
| `docs/full-work-progress.md` | `5e2edf831a0e3c7e` | T34 已改 **29 项**（D-04 ✅ 闭合；工作区） |
| `docs/evidence/closeout-20261016/SIGNOFF_CHECKLIST.md` | `63a4d1eaf0dfa70e` | 表头已改 **76 行 × 8 列 / 73 条**（R-04 ✅ 闭合；工作区） |
| `docs/evidence/platform-report-20261016/refresh-20261016/REFRESH.md` | `a830f16e7de0e18f` | §J4 第 4 条写明 **0 stale** 与"逐字节相同"（R-02 ✅ 闭合；已提交） |
| `HANDOFF_DONE.md` | `9da454c88d6b8cbc` | "全量收尾轮交接"节现写当前有效包摘要 `cacf9453…` 并注明两次被取代成包（**R-03 ✅ 闭合，`008c516`**） |
| `BLOCKERS.md` | （未变） | 第 1 条已与 R05 本体对齐（`6c10f4d`） |
| `…/CACR2026EA16XZ-platform-final5-20261016.zip` | `cacf94534bf7c0fd` | `d2ad9c9` **最终重出**的 final5 包（842 成员、verify pass、ctest 5/5）；`b54e2e4a…`/`248e06d2…` 见 `-attempt1.json`/`-attempt2.json` |
| `deliverables/research/multi-leakage-platform-20261016/report.pdf` | `d391114c9269b0c0` | 第 7、8 版两次重出后**仍逐字节相同**（`d391114c…`），R-02 的"逐字节相同"继续成立 |

> 摘要绑定本次读取时点（约 06:10，快照 `HEAD=7387c01`）。**注意：D-03/D-04/D-05/R-04 的修正与本次审计的两个产物目前只在工作区**，`git show HEAD:<path>` 仍是旧文本。
> 前五版的完整摘要表分别见 [`FINAL_AUDIT-47033dd.md`](FINAL_AUDIT-47033dd.md)、
> [`FINAL_AUDIT-a30d7c7.md`](FINAL_AUDIT-a30d7c7.md)、[`FINAL_AUDIT-0d9876b.md`](FINAL_AUDIT-0d9876b.md)、
> [`FINAL_AUDIT-dc6522c.md`](FINAL_AUDIT-dc6522c.md)、[`FINAL_AUDIT-e81c1ae.md`](FINAL_AUDIT-e81c1ae.md) §6，
> 可直接比对哪些文件在哪一轮被改动。最终复核请用 `shasum -a 256` 重跑并比对，命令见
> [`partials/S11.md`](partials/S11.md)。

---

## 7. 版本间差异对照

### 7.1–7.4 第 1→5 版

见 [`FINAL_AUDIT-e81c1ae.md`](FINAL_AUDIT-e81c1ae.md) §7（原字节保留）。

### 7.5 第 5 版（`e81c1ae` 快照）→ 第 6 版（`424d733` + `f8fa4de`，本版）

| 项 | 第 5 版（`e81c1ae`，03:58） | 第 6 版（本版，05:39–05:52） | 触发证据 |
|---|---|---|---|
| 时点声明 | 快照 `7a71d5c`，全部已提交 | 快照 **`HEAD=f8fa4de`**，全部已提交（本轮产物提交为 `424d733`） | `git rev-parse HEAD`；`git status --porcelain` 无已跟踪条目 |
| 本轮基线 | 相对 `origin/main`（`c849c0f`）领先 10 | 计划书基线 `c849c0f` **已过期 11 个提交**，本轮实际基线 = `origin/main@e81c1ae` | `git rev-list --count c849c0f..e81c1ae` = 11；`BASELINE.md` |
| 提交数 | `44c209a..HEAD` = 42；`origin/main..HEAD` = 10 | `e81c1ae..HEAD` = **27**；`origin/main..HEAD` = **27**（未 push） | `git rev-list --count` |
| 原文 41 行判定 | 38/0/0/0/3 | **38/0/0/0/3（不变）** | 逐行复核，无改判 |
| 口径 B（32 项） | 29/3 | **29/3（不变）** | 同上 |
| A′ / B′ | 43 行 40/3；34 项 31/3 | **不变**；另新增 A″ 66 行 63/3、B″ 57 项 54/3 | 本版 §1.3 |
| CSV 规模 | 43 数据行 × 8 列 | **76 数据行 × 8 列** | 本版新增 33 行 |
| 命令实跑 | 148 路径 / 40 命令（全部 0） | **257 路径 / 73 命令（全部 0）**；3 条 `—` | `build/run_audit_commands.py` |
| 报告 | final4：33 页、PDF `570ab957…` | **final5：91 页、PDF `d391114c…`**；两遍 XeLaTeX 仍 0 警告；新增附录 A 题面 12 条矩阵（11 满足 + 第 6 条部分） | `xelatex-final5-*.log`、`pdf-metadata-audit.json`、PDF 对象流计数 |
| 匿名包 | final4：784 成员、`88395b6c…` | **final5：842 成员、`cacf9453…`**（`d2ad9c9` 最终重出；前两次 `b54e2e4a…`/`248e06d2…` 保存在 `-attempt1.json`/`-attempt2.json`）、`direct_identity_markers=0`、包内 ctest 5/5 | 自跑 `verify_package.py`；`zip-recompute-final5.log` |
| 锁频运行 | 平台四模块 54 次 | **117 次（R03 18 + R08 54 + R09 36 + R12 锁频 9），117/117 四判据全过**；另有 9 次不锁频对照；19 次无效运行已归档 | 逐份 `status.log` / 逐份 `terminal.json` |
| 报告 §24 四处不一致 | 未闭（`dc6522c` 登记 3 处 + 时点差 1 处） | **全部按 `6c10f4d` 核实为已闭合**（逐条见 §4.4） | `git show 6c10f4d` + 当前文件 `grep` |
| 需处理不一致 | C-01…C-11 **全部闭合，0 未闭** | C-01…C-11 **仍全部闭合**；第 6 版新登记的 6 处经第 8 版复核 **6/6 全部闭合（D-03/D-04/D-05/R-02/R-03/R-04）** | §4.3 |
| 题面第 6 条 | 报告 final4 未设 12 条矩阵 | **如实记"部分"**（唯一缺口 R06 的 F1），D-03/D-05 是文件表述不一致、不是 F1 的替代；F1 **未闭** | 报告附录 A 表 T26 第 6 行；`AUDIT.md` F1 |

**计数变化（第 7 版 → 第 8 版）：** 口径 A（41）**38/0/0/0/3 不变**；口径 B（32）**29/0/0/0/3 不变**；
A′（43 行）**40/0/0/0/3 不变**；B′（34 项）**31/0/0/0/3 不变**；A″（66 行）**63/0/0/0/3 不变**、B″（57 项）**54/0/0/0/3 不变**；
CSV 合计（仍 76 行）**65 已满足 / 3 可选未做 / 8 已闭不一致 / 0 未闭不一致**（第 7 版为 6 已闭 + 2 未闭）。
**本次复核未改动原文 41 行中任何一行的判定，也未新增行**（故 `SIGNOFF_CHECKLIST.md` 的"76 行 × 8 列 / 73 条"仍然成立）。

| 第 8 版复核项 | 结果 |
|---|---|
| `verify_command` | **ran = 73、exit0 = 73、non-zero = 0** |
| 证据路径 | **255 条（带目录前缀规则）全部存在，0 缺失**；含裸文件名则 258 条、0 缺失 |
| 六处修补复核 | **6/6 全部闭合**：D-03 ✅、D-04 ✅、R-02 ✅、R-04 ✅（`008c516` 同批提交）、D-05 ✅、R-03 ✅ |
| zip / PDF sha256 | final5 zip = `cacf94534bf7c0fda213007c427d5edbc5a9292fc7c4eea6fc0ffb4ba8289e2c`（与 `final5-20261016-verification.json` 一致）；PDF = `d391114c9269b0c0ed463e06f3fed38a1cbded783be81590b7ae18151960db20`（两次重出后仍未变） |
| 工作区状态 | **`git status` 无已跟踪改动**（四处修补已由 `008c516` 提交） |
| 未闭项 | 矛盾清单 **0**；唯一登记在案的未闭技术缺口是 **T18 的 F1 低危发现**（非"不一致"类） |

---

*本文件由只读审计路 S11 生成（第 8 版，绑定快照 `main@d2ad9c9`，全部已提交、工作区干净；
前七版 `47033dd`、`a30d7c7`、`0d9876b`、`dc6522c`、`e81c1ae`、`f8fa4de`、`7387c01` 原字节另存）；
不修改任何被审计产物。最终判定以主控确认为准，并需与比赛方材料审核、本人签署和官方验收分开记录。*
