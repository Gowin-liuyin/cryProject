# R12 创新对照 (a)：锁频 vs 不锁频（族外，2026-10-16）

**定位**：这是**方法学对照**，用来量化"锁频控制器 + 冻结 PLAN 的测量协议"相对"只绑核不锁频"的收益。
它**不进任何 Holm 家族**、不改变 M1/M5 的既有结论，也不构成新的泄漏声明。

## 1. 为什么做

本平台的核心主张之一是"高精度时间测量需要受控频率"。要证明这一点，需要一个**同机同产物的 A/B**：
同一批采集件、同一类对、同样本量、同样的 `taskset` 绑核，**唯一的差别是有没有写频率**。
如果锁频确实降低了方差，那么在**相同样本量**下它应当给出更窄的 CI、更小的 MDE；
反过来，不锁频臂在真阴性对象（M5）上应当更容易出现假阳性。

## 2. 对照设计

| 臂 | 频率管理 | 绑核 | 说明 |
|---|---|---|---|
| **locked** | 经 `tools/platform_control/controller.py`：`boost=0`、governor/EPP=`performance`、目标 policy `min=max=4300000 kHz`；沉降 1.0 s 后 20×50 ms 放行探针须全部在 ±2% 且跨度 ≤50000 kHz | `taskset -c 2`（s1/s2）、`-c 6`（s3），由控制器建立 | 全流程可核对 `restore_match=yes` |
| **unlocked** | **不写任何 sysfs**：Boost、governor、EPP、min/max 全部保持系统默认（采前实测 `boost=1`、`powersave`、`min=2982259`、`max=5756452`、`epp=balance_performance`） | 同样 `taskset -c 2`（s1/s2）、`-c 6`（s3） | 因为**没有改动任何配置**，所以不存在"恢复"这一步；改为在每次运行前后各做一次**全 32 policy + global boost 的独立快照**，要求逐字相同 |

除频率管理外，**采集件、类对、样本量、预热、窗口定义、种子、CPU、统计方法全部相同**。

## 3. 对象与固定件

| 臂 | 采集件 | sha256 |
|---|---|---|
| M1 未修 | `Cry/liboqs010-historical-20261015-86131c2/build/historical-clangover/historical/measure` | `bd84ee9c2a44993fb5c6b43c4fb37027a168d265b4ca027eba3c3026798a0f78` |
| M1 已修 | `Cry/liboqs010-historical-20261015-86131c2/build/historical-fixed-982c762/historical/measure` | `1849821eca3039872cf5f103e3928141978b8846792a8da4e7c790ce96c2b5e9` |
| M5 参考 | `Cry/platform-m5-20261016-30efdf66eb26/build-v2-ordinary/reference/measure` | `4ff0956ac79550bc62caa0ea8d88968d3de8a926aebace9535481cb232145fa8` |

- 类对：**主类对 `message-zero` vs `message-ones`**（与各模块冻结 PLAN 一致）。
- 每类 **10000** 次，预热 100 在窗口外；`measure` 用法 `measure RUN_ID SEED SAMPLES CSV META`。
- 三次运行：s1 = 31337 / CPU2；s2 = 424242 / CPU2；s3 = 7 / CPU6。
- 总运行数：**3 臂 × 2 条件 × 3 次 = 18 次**（locked 9 次经控制器、unlocked 9 次直接 `taskset`）。

## 4. 要回答的三个问题

1. **方差比**：对每个臂、每个种子，比较 locked 与 unlocked 的每类 SD；给出 SD 之比与 bootstrap CI，
   以及把三次运行的样本合并后的 SD 比。
2. **达到检出所需样本量**：用实测 SD 与观测到的 Δ，按
   `n_per_class = 2·(z_{1−α/2}+z_{1−β})²·σ²/Δ²`（α=0.05 双侧、功效 80%）算每类所需 n；
   locked 与 unlocked 各算一份，给出比值。**Δ 取该臂在 locked 条件下的观测值**（作为待检出的目标效应），
   这样两条件的差别只来自 σ。
3. **M5 假阳性率**：M5 是已知阴性对象。统计 3 次 locked 与 3 次 unlocked 里
   **原始 p < 0.05** 的次数（每次运行一个主类对检验）。样本量很小（3 vs 3），
   所以只作**描述性**报告，**不得**据此给出"假阳性率 = x%"这类总体结论。

## 5. 预期与如实报告

- 若 locked 的 SD 明显更小：如实写数值与比值，并在报告里说明这是**本机该 CPU 上**的观察。
- 若两者差别不大、甚至 unlocked 更小：**如实写**，并解释可能原因（例如目标核本就长期处在高负载、
  `powersave` 在持续负载下已贴到高频上限、或后台服务噪声主导）。
- **不得**为了让锁频看起来更好而筛选种子、增减样本或换类对。
- 不锁频臂在报告与包内必须**明确标注**为"对照组：不锁频"，不能与正式采数结果混列。

## 6. 有效性与停止规则

- locked 臂：`controller_exit=0`、`reason=worker_finished`、`worker_exit_code=0`、`restore_match=yes`、
  放行探针 20/20 在带内 —— 缺一即无效，归档后重跑。
- unlocked 臂：进程返回 0、CSV 行数与类数正确、**运行前后全量频率快照逐字相同**（证明没有意外改动配置）
  —— 缺一即无效，归档后重跑。
- 任一运行失败先整体归档到 `failed/<run-name>-attempt<n>/` 再重跑，最多 3 次。

## 7. 边界

本对照只说明**频率管理与绑核**对测量方差/可检测性的影响，**不是**恒时证明、不是物理误差界，
也不能外推到其它机器、其它负载或远程场景。unlocked 臂的"未改动配置"只证明采集进程没有写 sysfs，
不证明系统频率是恒定的（恰恰相反：它就是不恒定的那一臂）。
