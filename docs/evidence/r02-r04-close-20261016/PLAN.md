# R02 与 R04 关闭验证实验计划（PLAN.md）

日期：2026-10-16  
主机：`nss-m`（AMD Ryzen 9 9950X，Ubuntu 24.04.4 LTS，Linux 6.17.0-35-generic，x86_64）  
编译器：Ubuntu Clang 18.1.3，选项 `-Os -fno-vectorize`  
目标对象：Open Quantum Safe `liboqs 0.10.0` 历史阳性（GHSA-f2v9-5498-2vpp，未修）与官方补丁 `982c762`（已修）  
事前约定：本文件在运行任何新数据采集前冻结并提交；检验族构成、显著性水平 $\alpha$、判定阈值在采集后绝不修改。

---

## 1. 假设检验族与多重比较校正设计（第 1 步）

### 1.1 族显著性水平（FWER）
全族总显著性水平设为：
$$\alpha_{\text{family}} = 0.05$$
采用 **Holm–Bonferroni（下称 Holm）逐步法** 控制全族一类错误率（FWER $\le 0.05$）。

### 1.2 假设检验族构成（$m = 8$）
本轮检验族覆盖主类对（`message-zero` vs `message-ones`）以及辅助对照类对（`valid` vs `random`、`valid` vs `bit-flipped`），分别针对未修与已修版本：

| 假设编号 | 检验名称 | 变体 | 类对 | 检验方法 | 原假设 $H_0$ |
|---|---|---|---|---|---|
| $H_{0, 1}$ | `unfixed_ci_zero_vs_ones` | 未修 (vulnerable) | message-zero vs message-ones | Welch t / 正态近似 CI | 两类均值无差异 ($\mu_0 = \mu_1$) |
| $H_{0, 2}$ | `fixed_ci_zero_vs_ones` | 已修 (fixed) | message-zero vs message-ones | Welch t / 正态近似 CI | 两类均值无差异 ($\mu_0 = \mu_1$) |
| $H_{0, 3}$ | `unfixed_dudect_zero_vs_ones` | 未修 (vulnerable) | message-zero vs message-ones | dudect Welch t (rdtsc) | 两类周期分布均值无差异 |
| $H_{0, 4}$ | `fixed_dudect_zero_vs_ones` | 已修 (fixed) | message-zero vs message-ones | dudect Welch t (rdtsc) | 两类周期分布均值无差异 |
| $H_{0, 5}$ | `unfixed_ci_valid_vs_random` | 未修 (vulnerable) | valid vs random | Welch t / 正态近似 CI | 两类均值无差异 |
| $H_{0, 6}$ | `fixed_ci_valid_vs_random` | 已修 (fixed) | valid vs random | Welch t / 正态近似 CI | 两类均值无差异 |
| $H_{0, 7}$ | `unfixed_ci_valid_vs_bitflip` | 未修 (vulnerable) | valid vs bit-flipped | Welch t / 正态近似 CI | 两类均值无差异 |
| $H_{0, 8}$ | `fixed_ci_valid_vs_bitflip` | 已修 (fixed) | valid vs bit-flipped | Welch t / 正态近似 CI | 两类均值无差异 |

### 1.3 p 值计算与工具换算规则
1. **正态近似 CI 与 Welch t 检验**：
   - 效应量 $\Delta = \bar{X}_1 - \bar{X}_2$，标准误 $SE = \sqrt{s_1^2/n_1 + s_2^2/n_2}$。
   - 检验统计量 $t = \Delta / SE$。在每类样本量 $n=10000$ 条件下，自由度 $df \approx 19998$，统计量渐近标准正态分布 $\mathcal{N}(0, 1)$。
   - 双侧 p 值：$p = 2 \times (1 - \Phi(|t|)) = \text{erfc}(|t| / \sqrt{2})$。
2. **dudect Welch t 检验**：
   - dudect 在丢弃第一批后累计最多 200,000 次测量（每批 10000 次，最多 21 批），报告最大 t 统计量。
   - 大样本下双侧 p 值：$p = \text{erfc}(|t_{\text{max}}| / \sqrt{2})$。当 $|t| > 10$ 时，$p < 1.0 \times 10^{-16}$；当 $|t| \approx 1.15$ 时，$p \approx 0.250$。
3. **RTLF 非参数自助检验的定位与说明**：
   - RTLF 使用 10,000 次 Bootstrap 检验 9 个十分位点（Deciles 10%–90%）的差值，预设名义水平 $\alpha_{\text{RTLF}} = 0.01$（各十分位 $\alpha/9$）。
   - RTLF 本身输出二值判决（`difference_detected: true/false`）及显著分位，不直接输出全谱连续 p 值。
   - 本研究中，RTLF 作为**独立的非参数多点分布交叉验证工具**并行列出。在生成 `holm.csv` 时，以具备严格连续分布推导的检验构建族；若将 RTLF 纳入族内，按保守经验界（未修显著记 $p \le 0.0001$，已修未显著记 $p = 1.0$）进行对照说明。

### 1.4 Holm–Bonferroni 算法执行规则
1. 对族内 $m$ 个假设的原始 p 值进行升序排列：$p_{(1)} \le p_{(2)} \le \dots \le p_{(m)}$。
2. 对第 $k$ 项（$k = 1, \dots, m$），计算阈值 $\alpha_k = \frac{\alpha_{\text{family}}}{m - k + 1}$。
3. 判定规则：从 $k=1$ 开始：
   - 若 $p_{(k)} \le \alpha_k$，拒绝原假设 $H_{0, (k)}$，继续检验 $k+1$；
   - 若 $p_{(k)} > \alpha_k$，接受原假设 $H_{0, (k)}$，并停止检验，后续所有 $k' \ge k$ 均接受原假设。
4. **期望通过准则**：未修版本的 `message-zero vs message-ones`（CI 与 dudect）在经过 Holm 校正后依然显著拒绝原假设；已修版本的对应检验均不拒绝原假设。

---

## 2. v4 测量口径与执行规范（第 2 步）

根据对仓库历史文件 `docs/research/v4-protocol-20261013/PROTOCOL.md` 及 `20261014/PROTOCOL.md` 的审计：
1. **v4 原生目标**：原系针对人工 `message-branch` 夹具设计的 16 密钥 ABBA 分组测量及频率保持规程。因该人工夹具非真实 CVE，且其 0.99 覆盖率门在当时动态调节下发生阻断，工程于 2026-10-15 全面转向真实 CVE **liboqs 0.10.0**。
2. **本轮吸纳的 v4 高精度测量口径**：
   - **单调用解封装计时**：计时窗口仅包围一次 `mlkem_decapsulate`，密钥生成、密文构造、预热、结果消费、日志与文件 I/O 均严格置于计时窗口之外；
   - **内存屏障保护**：计时前后必须插入原子信号屏障 `atomic_signal_fence(memory_order_seq_cst)`，防止编译器重排跨越计时点；
   - **预热机制**：正式采集前执行不少于 100 次解封装预热，确保指令与缓存状态进入稳定态；
   - **时钟前置自检**：执行 10,000 次时钟读取步进检查，确认单调性与高分辨率（ns 级）；
   - **异常值与全量样本保存**：不执行任何人为的主观离群值剔除或中位数截断，完整保留包括普通长尾在内的 10,000 条逐次原始纳秒测量值；
   - **频率严格受控**：测量前后必须记录全部 CPU 及全局 boost 的完整快照，并在退出时自动恢复和校验。

---

## 3. 独立复测设计与复现性判定标准（第 3 步）

为彻底排除单次实验的随机偶然性与特定核心/种子的偶合性，在保持锁频（4.30 GHz）、Clang 18 `-Os -fno-vectorize`、关闭 AVX2 分发的前提下，执行两轮独立复测：

### 3.1 复测组 1：换独立种子（种子 = `424242`）
- **核心**：CPU 2（taskset -c 2）
- **频率配置**：全局 boost=0，CPU2 governor=performance，EPP=performance，min=max=4300000 kHz。
- **样本量**：未修与已修各 10000 次/类（全 5 类共 50,000 次调用/变体）。
- **测量工具**：
  1. `measure`：单次解封装 `CLOCK_MONOTONIC` 计时，输出 samples.csv；
  2. `RTLF`：$\alpha=0.01$，对 `message-zero` 与 `message-ones` 各运行 2 次；
  3. `dudect`：`HISTORICAL_DUDECT_SEED=424242`，每批 10,000 次，上限 21 批。

### 3.2 复测组 2：换物理核心（核心 = CPU 6，种子 = `31337`）
- **核心**：CPU 6（taskset -c 6）
- **频率配置**：全局 boost=0，CPU6 governor=performance，EPP=performance，min=max=4300000 kHz。
- **样本量**：未修与已修各 10000 次/类。
- **测量工具**：
  1. `measure`：taskset -c 6，输出 samples.csv；
  2. `RTLF`：$\alpha=0.01$，各运行 2 次；
  3. `dudect`：taskset -c 6，运行 dudect。

### 3.3 复现性判定标准（在跑数据前冻结）
必须同时满足以下条件方可判定为“可复现”：
1. **未修版本**：
   - 在基准（31337@CPU2）、复测1（424242@CPU2）、复测2（31337@CPU6）三次独立实验中，主类对（`message-zero` vs `message-ones`）的 95% 置信区间**均不包含 0**；
   - 效应量方向必须恒定一致（$\Delta > 0$，即 `message-zero` 均值耗时大于 `message-ones`）；
   - dudect 均检出明显时序差异（$t > 10$，状态为 `Probably not constant time`）；
   - RTLF 均检出显著差异（`difference_detected: true`，退出码 11）。
2. **已修版本**：
   - 在基准、复测1、复测2 三次独立实验中，主类对的 95% 置信区间**均包含 0**；
   - dudect 均未达到拒绝门限（$t \le 10$，跑满预算，状态为 `maybe constant time`）；
   - RTLF 均未检出显著差异（`difference_detected: false`，退出码 10）。
3. **违背处理**：只要有任何一项复测不满足上述一致性标准，绝不能主张“可复现”，必须如实记录并在报告中深入分析偏离原因。

---

## 4. R02 与 R04 闭合判定标准（第 4 步）

在完成上述全部测量、统计校正与独立复测后，依据题面原文要求逐条判定：
- **R02 判定**：若高精度框架完备、环境描述完整、CPU 锁频与恢复经过双向校验、长尾保留无主观修剪、且在不同种子与不同物理核心上均获得稳定可重复的高精度测量，则判定 R02 达到**关闭**条件；若仍存在未受控干扰或复现性缺陷，则如实列出差距并保持开放。
- **R04 判定**：若不同输入类别差异在充分样本下经过描述统计、置信区间、多工具印证以及 Holm 多重比较校正后依然稳健拒绝原假设（已修版本不拒绝），且通过独立跨核心/跨种子复测验证，则判定 R04 达到**关闭**条件；若校正后不显著或复测不一致，则保持开放。
- **科学边界统一步调**：
  - 本研究不做任何密钥恢复攻击；
  - 已修版本的“不可区分 / maybe constant time”仅代表统计检验在当前样本量与分辨率下未拒绝零假设，不等于全平台全指令级恒时证明；
  - 所有结论严格界定在 `x86_64`、`Clang 18.1.3`、`-Os -fno-vectorize` 的 portable C `*_ref` 解封装实现范围。
