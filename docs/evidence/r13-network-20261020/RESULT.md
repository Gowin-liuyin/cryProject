# R13：T25 同机网络场景三档真实采集结果

**结论先行**：题面第 9 条的可选加分项「本地与网络场景」，此前登记为「未执行」
（`BLOCKERS.md` B01）。本轮**已执行**：在真实 x86_64 Linux 裸金属上，用匿名网络
命名空间 + 自有 veth + 内核 netem 建立了**真实两端**的 TCP 场景，采了
**本地直调 / 回环 / 三档抖动**共五档、**3 臂 × 2 次独立运行**的客户端 RTT 原始值。

**核心结论**：在**锁频**（与 R02/R08/R09 同一控制器口径）条件下、**同一台机器的 veth 两端**（下同「**同机模拟、非真实远程**」）
* **本地直调档**：M1 未修臂的 message-zero 与 message-ones 差异在 2 次运行里
  **一次可分辨（+37.1 ns，CI [20.4, 53.8]）、一次未检出（−7.9 ns，CI [−25.0, 9.2]）**——
  效应量级与 R09 的 `m1unfixed-Os` 格合并 Δ_pool（−26.16 ns，CI [−37.51, −14.81]）同量级，
  但**跨运行的可分辨性不稳定**。
* **全部网络档（回环 / low / mid / high）× 全部臂 × 两次运行**：**一律未检出**。
* **检测预算**：分辨那个量级的差异，每类所需样本数是——本地直调 13 098、
  回环 38 417、low 档 64 636 555、mid 档 1 003 153 317、high 档 97 586 175 893。
  本轮的网络各档每类 2000 个样本，**回环差约 1.3 个数量级、low 差约 4.5 个、
  mid 差约 5.7 个（≈6）、high 差约 7.7 个数量级**。

**结论上限**：本轮只支持「在上述预算下未检出」。**不支持**「不存在远程侧信道」，
**不支持**「远程攻击不可行」。网络未检出**不改变**任何既有判定，也不进任何 Holm 家族。

---

## 1. 口径

采集合同见同目录 [PLAN.md](PLAN.md)（采集前冻结、提交在先）。

| 项 | 口径 |
|---|---|
| 拓扑 | **同机**（同一台机器的两端）的匿名进程网络命名空间（`unshare --net`，**不建 `/run/netns` 具名句柄**）+ 自有 veth `10.88.13.1/30 ↔ 10.88.13.2/30` |
| 抖动 | 内核 `tc qdisc netem`，挂在 veth **两端**（单向 100 µs/20 µs、1 ms/200 µs、10 ms/2 ms），**不在算法里加 sleep 或随机延迟** |
| 五档 | `direct`（本地直调，不走 socket）/ `loopback`（veth+TCP 无抖动）/ `low` / `mid` / `high` |
| 角色 | 服务端 = 控制器 worker（`taskset` 绑到锁频 CPU2，在匿名 netns 内）；客户端在宿主网络命名空间，绑核 0,1,3（不占 CPU2/CPU6） |
| 频率 | 与 R02/R08/R09 同一控制器口径：boost=0、governor/EPP=performance、min=max=4300000 kHz、进入/采中/退出快照、`restore_match` 核对 |
| 测量量 | **客户端 RTT**（`CLOCK_MONOTONIC`，从 `connect` 后到 `recv` 完整应答后）是网络结论的**唯一依据**；服务端内部状态不参与分析 |
| 输入 | 客户端按 `request_index % 5` 轮转五类（valid / bit-flipped / random / message-zero / message-ones）；主类对 = message-zero vs message-ones |
| 预算 | 本地直调每类 10000 样本；网络各档每类 2000 样本（总请求 10000），每档 2 次独立运行。**种子**：r1 = `20261111`，r2 = `20261222`（两次运行用不同种子，故两次的密文集合不同）。**注意：种子是采集脚本的入参，采集当时的逐档台账没有把它写进文件**（写台账的改动发生在采集之后），因此种子目前**只有本文件与 PLAN-DEV-01 的文字登记、无归档原件可核** |
| 统计 | 族外 Welch + 正态近似 95% CI，**不做 Holm**；超时/丢失单列删失（本轮六次运行零丢失：客户端 RTT 行数与服务端 `completed_decapsulations` 逐档相等） |

**与冻结 PLAN 的偏离**：请求预算、网段、netem 位置、频率写入四项与
[PLAN.md](PLAN.md) 的冻结值不同，**已另开更正文件 [PLAN-DEV-01.md](PLAN-DEV-01.md)**
逐条登记偏离与理由（PLAN 本身按其要求未改写）。

**为什么本地直调档用 10000/类、网络档用 2000/类**：先在锁频条件下做标定
（每类 2000 → 10000），确认 M1 未修臂的效应是几十纳秒量级、2000/类不足以分辨，
于是把本地直调档的预算提到 10000/类；网络各档的 RTT 噪声比本地高两到三个数量级
（见 §3.3），2000/类已足以给出「未检出」并算出所需预算，继续加样本不改变结论、
只拉长采集时间。

## 2. 机制判定：三套臂的产物形态

三套臂与 R09 的 12 格**同源**：M1 两臂复用远端冻结树
`liboqs010-historical-20261015-86131c2` 的 `build/historical-clangover`（未修）与
`build/historical-fixed-982c762`（已修），按对象 sha256 把 `liboqs.a` 的归档成员映射回
编译条目、用同一组参数编译客户端/服务端并与 `liboqs.a` 一起链接——**判定的二进制
与计时的二进制来自同一次构建**。

反汇编核对（`objdump -d`）：

| 臂 | `poly_frommsg` 的形态 | 判定 |
|---|---|---|
| `m1unfixed` | `bt %ecx,%r8d` + `jae` | **秘密相关的条件跳转**（教科书形态） |
| `m1fixed` | `bt` + `setb` + `call cmov_int16` | 无秘密相关分支（仅循环回边，官方修复形态） |
| `m5ref` | 掩码选择（`and` + `neg` + `shr $0x10` + `and $0x681`），**仅循环界跳转** | 无秘密相关分支 |

三套臂的产物身份（路径与 SHA-256）见 `data/arms.json`。

**可核性边界**：本仓库**未归档**本轮三个 `network_server` 的 ELF 与反汇编原件
（产物在远端裸金属上），上表的形态由**同一上游源码**的既有证据旁证：
`docs/evidence/liboqs010-historical-20261015/logs/poly_frommsg_ref.s`（`bt`+`jae`）
与 `logs/fix/poly_frommsg_fixed.s` + `logs/fix/cmov_int16.s`（`bt`+`setb`+`call cmov_int16`）；
M5 参考路径的 x86-64 形态见
`docs/evidence/r09-optlevel-20261016/disasm/m5ref-O2-baseline_native_poly_frommsg.txt`。
**这不是本轮产物的直接核对**，引用时按旁证对待。

## 3. 结果

### 3.1 逐（臂, 运行, 档）的主类对差异

单位 ns；`CI` 是正态近似 95% 置信区间；判定以 **CI 是否含 0** 为准。完整表见
`data/class-comparison.csv`。

| 臂 / 运行 | direct（本地直调） | loopback | low | mid | high |
|---|---|---|---|---|---|
| `m1unfixed` r1 | **+37.1** [20.4, 53.8] **可分辨** | +63.1 [−0.9, 127.0] 未检出 | −801.3 未检出 | +6 515.5 未检出 | +39 569.7 未检出 |
| `m1unfixed` r2 | −7.9 [−25.0, 9.2] 未检出 | −12.4 未检出 | +263.0 未检出 | −1 863.5 未检出 | −51 509.7 未检出 |
| `m1fixed` r1 | +11.9 未检出 | −52.3 未检出 | +736.4 未检出 | −3 151.9 未检出 | +72 863.2 未检出 |
| `m1fixed` r2 | +7.0 未检出 | +5.9 未检出 | −942.0 未检出 | −6 885.7 未检出 | +39 109.8 未检出 |
| `m5ref` r1 | −11.3 未检出 | −52.8 未检出 | −665.1 未检出 | +2 861.4 未检出 | −30 649.4 未检出 |
| `m5ref` r2 | +2.7 未检出 | −57.7 未检出 | −455.4 未检出 | +654.6 未检出 | −61 629.6 未检出 |

> **表格口径**：`direct` 与 `loopback` 两列**可**给出 CI（本表只对 `m1unfixed` 两行列出，
> 其余行与 `low`/`mid`/`high` 三列的 CI 为版面省略，**逐格 CI 见 `data/class-comparison.csv`**）。本表是 CSV 的**节选排版**，
> 不是逐字副本（CSV 用 ASCII 负号与原始浮点，本表用排版负号与四舍五入）。
> 「未检出」一律等价于 **CI 含 0**。

### 3.2 三点必须如实说的事

1. **本地直调档的可分辨性跨运行不稳定。** M1 未修臂两次运行给出 +37.1 ns（可分辨）
   与 −7.9 ns（未检出）。两次的 SE 都在 8.5 ns 左右（噪声水平一致），**差别来自效应本身
   在两次运行之间的变动**，不是样本量或噪声水平的问题。合并两次的参照效应是
   **+14.6 ns**（量级与 R09 该格的 −26.16 ns 同阶）。**方向符号与 R09 相反**；本轮两次运行
  之间的符号也不一致（+37.1 与 −7.9），说明该效应在本预算下不稳定——本轮**不**为符号差异
  给出因果解释。
   本轮**不**把本地直调档写成「稳定可分辨」。

2. **网络各档一律未检出**，包括回环档（无抖动、协议开销最小的那一档）。这不是
   「没有差异」，而是**预算不够**（§3.3）。

3. **零丢失、零删失。** 六次运行 × 四个网络档，客户端 RTT 行数与服务端
   `completed_decapsulations` 逐档相等，没有超时、没有丢包、没有静默删除。

### 3.3 检测预算：需要多少样本才能分辨那个量级

参照效应取本地直调档实测的 M1 未修差异（两次运行合并，**+14.6 ns**）。
**该参照效应由一次可分辨（+37.1 ns）、一次未检出（−7.9 ns）的两次运行合并而来，
其本身 CI 含 0，因此只作「量级参照」，不是被确证的效应值。**

按与 MDE 列**同一套口径**计算：Welch 的 SE = SD·√(2/n)，故分辨 |效应| 所需
`n = 2·(1.96·SD/|效应|)²`（脚本 `analyze_network_rtt.py` 的
`required_n_per_class_for_reference_effect` 列）。

下表取 **m1unfixed r1**（单次运行）的值；r2 的对应值在
`data/detection-budget.csv` 里（direct 档 required 13 762、ratio 0.73，与 r1 同阶）。
**SD / MDE / required 三列都是单次运行的值，只有参照效应是两次合并的。**

| 档 | 类间合并 SD（ns，本行取 m1unfixed r1 单次运行） | 本预算的 MDE（ns） | 分辨 14.6 ns 所需每类样本数 | 本轮实际 | 实际/所需 |
|---|---|---|---|---|---|
| direct（本地直调） | 602.6 | 16.7 | **13 098** | 10 000 | 0.76× |
| loopback | 1 032.1 | 64.0 | **38 417** | 2 000 | 0.052× |
| low（单向 100 µs ± 20 µs） | 42 334.1 | 2 623.8 | **64 636 555** | 2 000 | 3.1e-5 |
| mid（单向 1 ms ± 200 µs） | 166 776.6 | 10 336.7 | **1 003 153 317** | 2 000 | 2.0e-6 |
| high（单向 10 ms ± 2 ms） | 1 644 923.0 | 101 951.5 | **97 586 175 893** | 2 000 | 2.1e-8 |

读法（**注意与上一版的差别**）：

- 本地直调档的预算**并不足以保证**分辨 14.6 ns 的参照效应：MDE 16.7 ns > 14.6 ns，
  实际/所需 = 0.76。r1 那次之所以能分辨，是因为**该次运行的效应（+37.1 ns）本身
  远大于参照效应**，不是预算充足；r2 的效应（−7.9 ns）就没能分辨。**这正是
  §3.2-1 所说的「跨运行可分辨性不稳定」的量化解释。**
- 回环档差约 1.3 个数量级（0.052×）；low 差约 4.5 个；mid 差约 5.7 个（≈6）；high 差约 7.7 个。
- **high 档要分辨几十纳秒的差异需要每类约 9.8e10 个样本**——这不是「再跑久一点」的
  问题，而是**这个量级的差异在带抖动的链路 RTT 上不可用**。

### 3.4 RTT 分布

逐（臂, 运行, 档）的 min / p10 / p50 / p90 / p99 / max / 均值 / 标准差见
`data/rtt-summary.csv`。典型量级：回环档 p50 在几十微秒，low 档百微秒，
mid 档毫秒，high 档十毫秒——与 netem 的设定一致，说明**抖动确实生效**。
更准确地说：三档的 RTT 分布**形状相同、尺度按 10×/100× 变化**（与 netem 参数
成比例：sd/mean 恒在 0.068–0.113，(p90−p50) 逐档 ×10、×100），
即噪声随注入延迟**线性放大**，不是同分布的随机重标度。

## 4. 恢复合同与运行核对

- 空任务恢复验证 **8/8 通过**（建/删 veth、qdisc 清理、命名空间进程回收、
  `/run/netns` 无项目具名句柄、链接与 qdisc 计数复原、cpufreq 策略项逐字不变、
  临时文件全在 Cry 之下；`/tmp` 一项的判据为「顶层与二层内、名字含本任务前缀
  （`cry13` / `r13-network`）且含隐藏项的条目不存在」——**不是**「`/tmp` 下没有任何本任务
  文件」的全称断言）。原件与逐条检查见采集根
  `runs/recovery-check/`。
- 每个**成功**的控制器 run（6 次运行 × 5 档 = 30 份逐档副本）的 `terminal.json` 均为
  `{"reason":"worker_finished", "restore_match":"yes", "worker_drained":true, "worker_exit_code":0}`，
  副本在 `data/runs/<run>/<档>-terminal.json`；**失败**的 5 次另见
  `data/failed-attempts/`（其 `reason` 为 `frequency_probe_rejected`，无 `worker_exit_code`）。
- **失败尝试分两类，如实分开登记**：
  (1) **控制器判据拒绝**共 **5 次**，终态归档在 `data/failed-attempts/`（每次一个目录，
  含 `terminal.json` 与 `entry-probes.json`），原因都是 `frequency_probe_rejected`
  ——控制器自带的 20 次频率探针跨度判据（≤ 50 000 kHz）拒绝了这些 run；5 份
  `entry-probes.json` 的实测跨度为 50 014 / 50 859 / 58 463 / 53 823 / 58 416 kHz，
  全部 > 50 000 kHz，与该原因一致；5 次都是 `restore_match=yes` / `worker_drained=true`，
  即**拒绝后频率已恢复**。其中 **2 次**可在 `data/runs/*/controller-runs.txt` 里对上，
  **3 次**只能靠各目录 `source.txt` 记录的控制根名关联；其中 1 个**尝试目录名**
  （`r13-low-620566`）**不符合本脚本的运行名规则**（缺 `-a<尝试序号>` 后缀），来源待考。
  （5 份 `source.txt` 记录的控制根名有 4 个不同取值；其中 `bbbbccccdddd` 与 `aaaabbbbcccc`
  形似占位串、无法与任何归档件对应，按**来源待考**登记。）
  (2) **臂级失败**另有 **2 次**「客户端程序缺失」（参考臂产物路径少一层 `cmake/`）：
  脚本在程序检查处直接退出，**没有创建控制器 run、因此没有终态可归档**。
  另：`data/collection.log` 里出现的 2 次「等待服务端监听超时」**不是额外事件**，
  而是上述 5 次控制器拒绝中 2 次的客户端侧表现（`r13-mid-277362-a1`、
  `r13-loopback-945984-a1`），已计入，不另计。
  逐档台账（退出码、尝试序号）见 `data/runs/*/scenarios.txt` 与
  `data/runs/*/controller-runs.txt`。
  脚本口径是：档与档之间加 20 秒固定冷却（**排程间隔**，不改控制器任何判据）；
  某次尝试若退出码非零或缺少 `worker_exit_code`，则**该档整体重跑**，最多 3 次，
  每次尝试都记进台账。**已经采到数的档不重跑、不择优。**
  （采集脚本每次尝试都写同名 `*-terminal.json`，成功会覆盖失败的那一份；因此失败
  终态是从**控制根的逐 run 目录**里取回归档的，不是从输出目录。）

## 5. 能支持什么 / 不能支持什么

### 5.1 支持

1. 题面第 9 条的「本地与网络场景」这一项**已执行**，产出真实两端的客户端 RTT 原始值
   （六次运行 × 四档 × 10 000 行，gzip 后在 `data/runs/`），以及本地直调档的逐样本
   原始值（每类 10 000 × 5 类）。
2. **在上述预算下，网络各档未检出**；并给出**可分辨该效应所需的样本数**（§3.3）。
3. 本地直调档上，M1 未修臂的效应量级与 R09 一致（几十纳秒），但**跨运行的可分辨性
   不稳定**——这一点是新信息，如实登记。

### 5.2 不支持、也不主张

1. **不是「没有远程泄露」**：本轮只能写「本预算下未检出」。任何「远程攻击不可行」、
   「不存在远程侧信道」的表述都超出本轮证据。
2. **不是真实远程**：这是**同机**网络模拟（同一台机器的 veth 两端），必须标注
   「同机模拟、非真实远程」；真实公网/跨主机的链路还叠加了真实网络的排队与丢包。
3. **不覆盖进程级/系统级可观察面**：只测了客户端 RTT 一个观测量；服务端内部状态、
   共享内存、缓存状态等不在本轮范围。
4. **不改任何既有判定**：M1–M5 的结论、四个 Holm 家族、R09 的可分辨性结论全部不变。
   本结果是**新增的、族外的**一层证据。

## 6. 目录内容

| 路径 | 内容 |
|---|---|
| `PLAN.md` | 采集前冻结的合同（三档、双基线、恢复合同、验收判据、结论上限） |
| `data/rtt-summary.csv` | 逐（臂, 运行, 档）的 RTT 分布（30 行） |
| `data/class-comparison.csv` | 逐（臂, 运行, 档）的主类对 Welch 对比（30 行，含 SE / CI / p / MDE） |
| `data/detection-budget.csv` | 逐（臂, 运行, 档）的检测预算（SD / MDE / 所需样本数 / 实际与所需之比） |
| `data/analysis.json` | 机器可读汇总 |
| `data/arms.json` | 三套臂的产物路径与 SHA-256 |
| `data/collection.log` | 采集器调用的逐次台账（**三段调用记录**；已完成的运行显示为「已完成，跳过」，逐档细节在 `data/runs/*/scenarios.txt`）。**台账缺口**：`m1unfixed` r2 的采集过程在本文件里没有记录（只出现「已完成，跳过」），其采集记录不在归档内 |
| `data/runs/<run>/` | 每档的客户端 RTT 原始值（gzip）、服务端摘要、控制器 `terminal.json` / `during.json` / `entry-probes.json`、逐档台账 |
| `data/recovery-check/` | 恢复合同验证的原件（`before.txt` / `after.txt` / `checks.txt` / `summary.txt` / `during.txt` / `console.txt` / `status.txt`），8/8 通过 |
| `data/failed-attempts/` | 5 次未采到数的失败尝试的控制器终态（`terminal.json` / `entry-probes.json` / `source.txt`），原因均为 `frequency_probe_rejected` |
| `data/precision/` | 同批次的计时基准与频率自校准数据（见 [R16](r16-precision-20261021/RESULT.md)） |

## 7. 复现

```sh
# 1) 构建三套臂（复用远端冻结树，M1 两版按对象 sha256 映射回编译条目）
python3 tools/platform_network/build_network_arms.py \
    --cry-root /home/nss-marker/yhr/Cry \
    --source-root <source_root> --output-root <runs_root>/arms
# 2) 恢复合同验证（必须先过）
sh tools/platform_network/verify_network_recovery.sh <runs_root>/recovery-check
# 3) 采集（每档一个控制器 run）
bash tools/platform_network/run_network_controlled.sh \
    <arm_build_dir> <out_dir> <seed> 10000 2000 <port> 2 <control_root>
# 4) 复算（脚本支持 .csv 与 .csv.gz 两种输入）
python3 tools/platform_network/analyze_network_rtt.py --runs-root <runs_root>
```

**在归档副本上复算**：本目录 `data/` 是压缩归档，布局与采集时的 `runs/` 不同。
复算前需还原：`data/runs/net-*` → `<work>/runs/net-*`，`data/arms.json` →
`<work>/runs/arms/arms.json`，再跑上面的第 4 步。脚本对 `.csv` 与 `.csv.gz`
两种输入都支持（网络档优先读 `<档>-rtt.csv`，没有则读 `<档>-rtt.csv.gz`）。
**`data/detection-budget.csv` 的来源**：它是上面第 4 步
`analyze_network_rtt.py --runs-root <runs_root>` 在归档副本上的输出，**每一行对应
（臂, 运行, 档）**；`required_n_per_class_for_reference_effect` 用的是
`analysis.json` 里 `required_n_convention` 声明的口径
`n = 2·(1.96·SD/|参考效应|)²`（参考效应取 `reference_local_effect_ns`，
即本地直调档 M1 未修臂的实测差），`achieved_budget_ratio` 是「实际每类样本数 ÷
所需样本数」，<1 表示**该预算下未检出**。

**口径改写留痕**：复核过程中本目录的 `detection-budget.csv`（`required_n` 整列口径
由旧公式改为 `n = 2·(1.96·SD/|效应|)²`）、`class-comparison.csv`（`p_value` 浮点末位
重算）与 `recovery-check/`（用收紧后的 `find -maxdepth 2` 判据复跑）曾被就地改写。
旧版已按 `holm.m8.csv` 的同一做法另存为 `data/detection-budget.v1.csv`、
`data/class-comparison.v1.csv`、`data/analysis.v1.json`、`data/recovery-check.v1/`，
说明见 `data/README-v1-archives.md`——**只作留痕，不作为结论依据**。

**`data/analysis.json` 的 `runs_root` 是相对路径**（值为 `runs`）：脚本把它记成
相对于**分析输出目录**的相对路径，因此归档副本里它指向 `data/runs/`，
而不是采集时的远端绝对路径——这是为了让归档不携带远端绝对路径而定的口径，
不是采集时的实际目录。复算时把 `data/runs/` 放到任何目录下都一样。

`data/analysis.json`、`data/class-comparison.csv`、`data/detection-budget.csv`、
`data/rtt-summary.csv` 是**现行脚本**在归档副本上的输出（**数值与本文表格一致，排版非逐字**——
CSV 用 ASCII 负号与原始浮点，本表用排版负号与四舍五入；完整逐格 CI 见
`data/class-comparison.csv`）。

云端工作根：`/home/nss-marker/yhr/Cry/r13-network-20261020/`
（`source-3f94f228/`、`runs/arms/`、`runs/net-<arm>-<run>/`、`runs/precision/`）。
