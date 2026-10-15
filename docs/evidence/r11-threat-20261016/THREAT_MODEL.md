# T28 威胁模型章（R11，2026-10-16）

本页是报告「威胁模型」章的独立稿，供整合 agent 直接并入 `deliverables/research/multi-leakage-platform-20261016/report.tex`；
配套 LaTeX 片段见同目录 [threat-model.tex](threat-model.tex)。本页**只读**已有证据，不重新采集、不改动任何既有文件、不做密钥恢复。

## 0. 阅读约定

- 每条结论后面给**证据路径**（相对仓库根）。本页出现的数字全部来自这些文件，未从任何其它来源引入。
- 三个尺度标签**不可互相冒充**：`已执行且检出` / `已执行且未检出` / `未执行`（定义见第 D 节）。
- 人工夹具（M3 秘密下标 LUT、M4 提前退出比较）一律标注**人工构造校准**；R03 的两个对照与 R12 的锁频对照一律标注**族外、不进 Holm**。
- 本页**不做密钥恢复**，不运行 exploit demo；**不把「未检出」写成恒时证明**，也不给出物理误差界或总体误报率。

---

## A. 攻击者模型

### A.1 攻击者可控输入

| 输入 | 说明 | 证据 |
|---|---|---|
| **密文（长度与内容）** | 攻击者可控的全部密码学输入。长度可控到字节级：合法 1088 B、同长度但 u/v 字段被整体改写的「格式破损」1088 B、少 1 字节的「截断」1087 B | `docs/evidence/r03-malformed-20261016/RESULT.md` §2「三个输入类」 |
| **公开公钥 / 封装接口** | keygen、encaps 与公钥材料是公开面；各臂都能独立跑通完整 keygen 与 encaps，并由公开向量逐例核对 | `docs/evidence/r01-kat-20261016/README.md`「内容」与「复现」；`docs/evidence/m2-kem-20261016/RESULT.md` 第 1 节资格表 |
| **类别与重复次数** | 攻击者可以选择把同一份密文重复喂入多少次（本轮每类 10000 次 + 预热 100 次），但**看不到**逐样本时间之外的任何东西 | `docs/evidence/platform-collection-20261016/README.md` §1；`docs/evidence/r03-malformed-20261016/RESULT.md` §1 |

**不含私钥。** 解封装私钥 `sk`（PKE 秘密 1152 B）与拒绝种子（32 B）在全部测量里都是**被保护的秘密**，密文本身被显式声明为 `public`：

```console
mode=valgrind_secret_marked pke_secret_bytes=1152 rejection_secret_bytes=32 ciphertext=public
```

证据：`docs/evidence/r05-locate-20261016/RESULT.md` §4.1（原文引用 `remote-tree/m2-ctgrind/` 的 stdout 末行）。
即：本平台从不假设攻击者持有解封装私钥。

需要写清的一条边界：**采集件自身必须持有一份密钥对**才能驱动解封装——它通过 `--public-key` / `--secret-key` 读取资格夹具里的**固定测试密钥对**
（`qualification-ordinary/fixtures/{pk.bin,sk.bin}`）。这份测试密钥是资格夹具的一部分、可由公开材料复现，**不是**任何真实受害者的私钥；
被秘密标记的正是这份测试私钥在解密链内的使用，而密文与公钥始终处于公开面。
证据：`docs/evidence/m2-kem-20261016/COLLECTOR_CONTRACT.md` §7；`docs/evidence/m3-completion-20261016/RESULT.md`（「公开测试私钥」口径）。

**不含物理接触。** 全部实验是本机进程级实验（`taskset` 绑核 + 控制器写频），攻击者没有接触机器、没有接探头、没有换硬件：

- 环境与边界登记：`docs/evidence/r02-env-20261016/ENV_TABLE.md` §9（`taskset` 亲和性 + 控制器写频不是内核级 CPU 隔离）。
- 采集条件：`docs/evidence/platform-collection-20261016/README.md` §1（`taskset -c 2` 或 `-c 6`，控制器写 `boost=0`、`performance`、`min=max=4300000 kHz`）。

### A.2 攻击者可观测量

**可观测量只有「一次完整调用（或夹具调用）的单次耗时」。** 逐样本原始值全部落盘，不做主观剔除：

| 对象 | 计时窗口 | 证据 |
|---|---|---|
| M1 / M2 / M3 / M5 / R03 | 一次**完整解封装**（`clock_gettime` → 调用 → `clock_gettime`，中间只有 `atomic_signal_fence`） | `docs/evidence/r02-env-20261016/ENV_TABLE.md` §4.1 表；`docs/evidence/m2-kem-20261016/COLLECTOR_CONTRACT.md` |
| **M4（人工构造校准）** | 一次**完整受检比较**（32 字节），`.meta` 写 `boundary=complete_checked_compare`；**不是**完整解封装 | `docs/evidence/r02-env-20261016/ENV_TABLE.md` §4.1 逐字 `.meta` 抽样 |
| **M3（人工构造校准）** | 一次完整解封装，重加密路径里挂了人工秘密下标 LUT | `docs/evidence/m3-completion-20261016/RESULT.md` §1「实现与资格」 |

**窗口外的一切都不属于观测量**：输入生成、内存分配、结果消费、日志与 I/O 都在窗口外；窗口内没有 I/O、日志或分配：

- `docs/evidence/r06-noleak-20261016/AUDIT.md` §0「计时窗口 I/O」行与 §4（7 个 fence-to-fence 窗口按白名单核对）。
- 逐类 `zero_elapsed_rows` 全为 0、`window_scope=one_mlkem_decapsulate_call`：`docs/evidence/r03-malformed-20261016/RESULT.md` §2。

**「返回值以外的内部状态」不构成本轮的攻击者可观测量**（负面对照，不等于零泄露）：

| 可观察面 | 本轮检查结果 | 证据 |
|---|---|---|
| stdout / stderr / 退出码 | 7 种输入模式（1 合法 + 6 隐式拒绝）各 120 次，退出码唯一值均为 `0`，stdout/stderr **逐字节一致**，`diff -u` 0 个差异块 | `docs/evidence/r06-noleak-20261016/AUDIT.md` §0、§2 |
| 秘密内容（`ss`/`sk`/`z`/`m'`） | 静态 122 个接触秘密标识符的调用点逐条判定，**0 条**把秘密字节写进 stdout/stderr/返回码/errno；Memcheck syscall 参数检查 0 命中 | `docs/evidence/r06-noleak-20261016/AUDIT.md` §0、§1、§3 |
| API 错误码 | `mlkem_*` 返回码只表示参数/长度/空指针/随机源错误，**不表示**重加密比较结果 | `docs/evidence/r06-noleak-20261016/AUDIT.md` §6 第 6 条（引 `include/mlkem.h`） |
| 采集件功能门（F1，低危，已登记） | `tools/platform_m2/collector.c` 在门失败时把 `accept_mismatch_count` / `failed_decapsulation_count` **按批汇总**写进 stderr、进程退出码与 meta 的 `run_status`；正常路径 rc 恒 0、stderr 恒空，因此正常采集不触发 | `docs/evidence/r06-noleak-20261016/AUDIT.md` §1.3 F1、§2.3 |

F1 是本页**如实保留**的一条：它是批级汇总、不是逐调用比较位，但它说明「同一批输入在不同实现/构建下退出码不同」本身仍是一个可观察的接受-拒绝信号。本威胁模型把攻击者的可观测量限定在 A.2 第一段，F1 作为**已知边界**登记，不改写为「无泄露」。

### A.3 测量条件：本地同机、单核绑核、锁频控制器

攻击者看到的耗时，是在下列**工程条件**下取到的：

| 项 | 值 | 证据 |
|---|---|---|
| 机器 | 裸金属 `nss-m`，AMD Ryzen 9 9950X，16 核 × 2 SMT = 32 线程，单 socket 单 NUMA | `docs/evidence/r02-env-20261016/ENV_TABLE.md` §1.4、§1.6 |
| 内核 / 发行版 | Linux 6.17.0-35-generic，Ubuntu 24.04.4，x86_64 | `docs/evidence/r02-env-20261016/ENV_TABLE.md` §1.1、§1.2 |
| 绑核 | `taskset -c 2`（r1/r2、基准）或 `-c 6`（r3、跨物理核复测）；**单核**，不是独占物理核 | `docs/evidence/platform-collection-20261016/README.md` §1 |
| 频率控制 | 唯一控制器写 `boost=0`、governor/EPP=`performance`、`min=max=4300000 kHz`；沉降 1.0 s 后取 20×50 ms `scaling_cur_freq`，全部落在 ±2% 且跨度 ≤50000 kHz | `docs/evidence/platform-collection-20261016/README.md` §1；`docs/evidence/platform-control-qualification-20261016/QUALIFICATION.md` |
| 有效性 | 54 次正式运行全部 `controller_exit=0`、`worker_exit_code=0`、`restore_match=yes` | `docs/evidence/platform-collection-20261016/README.md` §2 |

**必须写明的一条口径**：这是**本地同机、单核绑核、锁频控制器下的工程观测**，
**`scaling_cur_freq` 不是示波器测量**——它是内核暴露的请求/反馈观测量，
不主张逐调用物理恒频，也不给出物理误差界：

- `docs/evidence/platform-collection-20261016/README.md` §6 第 1 条（原文：「频率锁定是**工程控制观测**：`scaling_cur_freq` 不是示波器测量」）。
- `docs/evidence/platform-control-qualification-20261016/QUALIFICATION.md`（第 77 行同一条）。
- `docs/evidence/r02-env-20261016/ENV_TABLE.md` §7「`scaling_cur_freq` 不是示波器测量；本页不主张逐调用物理恒频，也不给物理误差界」与 §9。

### A.4 攻击者能力

**具备：**

1. **本地同机可执行**：能在被观测机器上跑自己的进程、绑到同一逻辑 CPU、重复发起解封装。
   证据：`docs/evidence/r03-malformed-20261016/RESULT.md` §1（9 次 measure + 9 次 dudect 全部 `taskset -c 2|6`）。
2. **可重复发起**：每类 10000 次 × 3 次独立运行（换种子、换物理核），可自行加样本量。
   证据：`docs/evidence/platform-collection-20261016/README.md` §1；`docs/evidence/r02-r04-close-20261016/RESULT.md` §2.1。
3. **可与自己的参考实现做差分**：实现是公开的固定提交，公开 KAT（NIST/ACVP 与 round-3 官方向量）可独立复算，
   攻击者可以拿自己的实现跑同一批输入做逐字节与逐样本对照。
   证据：`docs/evidence/r01-kat-20261016/README.md`、`docs/evidence/r01-kat-20261016/VECTORS.md`、`docs/evidence/r01-kat-20261016/EQUIV.md`；
   差分运行实例见 `docs/evidence/r06-noleak-20261016/AUDIT.md` §2（本机 macOS/ARM 与远端 x86_64 Linux 两次独立运行）。

**不具备（本威胁模型不假设）：**

1. **不假设能读进程内存**：不假设读取被测进程的地址空间、core dump 或 `/proc/<pid>/maps`。
   本轮**没有**检查这些面，因此它们既不是已排除的通道，也不是本模型授予攻击者的能力。
   证据：`docs/evidence/r06-noleak-20261016/AUDIT.md` §6 第 5 条（明确列出未检查的进程可观察面：`cmdline`、fd、`maps`、core dump、`wait4`、信号、`/proc/<pid>/stat`、文件名与 mtime）。
2. **不假设能读测量进程的内部状态**：观测面就是 A.2 列出的那些。
3. **不假设侧信道之外的物理通道**：没有功耗、电磁、声、温度、供电抖动等采集通道。
   证据：`docs/evidence/r02-env-20261016/ENV_TABLE.md` §9；第 B 节第 2 条。
4. **不假设能改机器配置**：写频率文件、改隔离、装卸内核模块都不是本模型授予的能力（那属于环境配置，不属于攻击者）。

---

## B. 不在范围内

以下五条**明确排除**，每条给一句理由。

| # | 不在范围内的内容 | 为什么 |
|---|---|---|
| B1 | **密钥恢复与 exploit demo** | 本平台不做，也不作为交付：全部结论停留在「类间耗时是否可区分」与「差异对应哪段源码/产物」，没有恢复 `sk`、`m'` 或 `ss` 的步骤，也不给可利用性结论。证据：`docs/evidence/r04-stats-20261016/POWER.md` §6；`docs/R05-全流程排查表.md` §7 第 6 条。 |
| B2 | **物理侧信道（功耗 / 电磁 / 缓存抢占的交叉核攻击）** | 本平台只有软件计时一条通道，没有功耗或电磁采集设备；SMT 兄弟线程未隔离，但本轮**没有**把跨核缓存抢占建模为攻击通道，也没有做抢占实验。证据：`docs/evidence/r02-env-20261016/ENV_TABLE.md` §5.1（SMT 开启、只固定线程）、§9。 |
| B3 | **远程网络时序** | 本轮只有同机场景，可选的同机网络对照（计划 T25）**未执行**，没有任何网络采集产物；同机锁频结果不能外推网络。证据：`docs/evidence/r06-noleak-20261016/AUDIT.md` §6 第 2 条（「未执行网络路径的端到端差分」）；计划条目见 `docs/全量收尾计划与提示词-20261016.md` 第 2 节 T25。详见第 C.6 节。 |
| B4 | **编译器 / 操作系统之外的微架构特性建模（如 SMT 抢占的定量模型）** | 本平台没有 SMT 抢占的定量模型：SMT 只作为**环境事实**登记（`SMT active=1`、兄弟线程未排除），没有任何抢占率、抢占代价或占用模型进入统计。证据：`docs/evidence/r02-env-20261016/ENV_TABLE.md` §5.1；`docs/evidence/platform-collection-20261016/README.md` §6 末条（「整机独占不是本页的主张」）。 |
| B5 | **对上游库未固定版本的结论外推** | 所有结论都绑定到固定提交、固定编译器与选项、固定产物；换版本、换优化级别、换 ISA 分发后结论不适用。证据：`docs/evidence/m2-kem-20261016/RESULT.md`（历史 Kyber768 不冒称 FIPS 203）；`docs/R05-全流程排查表.md` §7 第 4 条（「换优化级别重建后的结论不适用」）；`docs/evidence/platform-collection-20261016/README.md` §6。 |

---

## C. 本地高精度与远程的边界

### C.1 读钟开销

| 串 | n | 均值 | 中位数 | p99 | min | `clock_getres` | 证据 |
|---|---:|---:|---:|---:|---:|---:|---|
| `CLOCK_MONOTONIC`（新探针，CPU8） | 100000 | **17.423 ns** | **20 ns** | **40 ns** | 10 ns | 1 ns | `docs/evidence/r02-env-20261016/ENV_TABLE.md` §4.3 |
| `CLOCK_MONOTONIC_RAW`（新探针，CPU8） | 100000 | 16.195 ns | 20 ns | 21 ns | 10 ns | 1 ns | 同上 |
| `CLOCK_MONOTONIC_RAW`（既有归档复算，绑 CPU2） | 300000 | **17.50 ns** | 20 ns | 21 ns | 10 ns | — | `docs/evidence/r02-env-20261016/ENV_TABLE.md` §4.4 |

要点：

- **读钟开销与被测窗口同量级**：均值 ~17 ns、中位数 20 ns、p99 40 ns（`CLOCK_MONOTONIC`，新探针）。
  这正是 M4 夹具（20–30 ns）出现大量并列值的原因。证据：`docs/evidence/r02-env-20261016/ENV_TABLE.md` §4.3 第 3 点、§4.3 注释。
- **不能把新探针的数值当成采集窗口的读钟开销**：§4.3 跑在 CPU8（`taskset -c 8`），与采集用的 CPU2/CPU6 不是同一物理核；
  绑 CPU2 的复算是 §4.4（n=300000，均值 17.50 ns、中位数 20 ns、p99 21 ns）。证据：同上 §4.3 第 1 点、§4.4。
- 两个 CLOCK 的中位数都是 20 ns，但 `CLOCK_MONOTONIC` 的 p99（40 ns）明显高于 `CLOCK_MONOTONIC_RAW`（21 ns）；
  M4 用的正是 `CLOCK_MONOTONIC_RAW`。证据：同上 §4.3 第 2 点、§4.1 表。
- 这是**软件观测**，不是硬件时间戳单元的精度界。证据：同上 §9。

### C.2 量化尺度

- 本机 `clock_gettime` 的实际最小步进是 **10 ns 量级**，**不是** `clock_getres` 报的 1 ns。
  证据：`docs/evidence/r02-env-20261016/ENV_TABLE.md` §4.3 第 3 点。
- 把每个主类对的两类取值合起来看，**相邻不同取值的间隔中位数是 9 ns**（各主类对范围 **9–10 ns**），最小间隔 1 ns；
  即本批数据的**有效计时量化尺度约 10 ns**：均值可以靠 n=10000 平均出 1 ns 以下的差异，但**分位数只能落在约 10 ns 的格点上**。
  证据：`docs/evidence/r04-stats-20261016/QUANTILE_CI.md` §4.4（41 个主类对汇总）。
- 这条直接解释了两类现象：分位差恰为 0（63 条）、以及分位/秩方法与均值方法判定翻转——**格点跳一格就是 ±10 ns**，
  翻转是「均值型检验与位置型检验的功效差」或「1 ns 量化下秩方法失效」，**不是新的泄漏证据**。
  证据：`docs/evidence/r04-stats-20261016/QUANTILE_CI.md` §4.4；`docs/evidence/r02-env-20261016/ROBUSTNESS.md` §0、§6.1。

### C.3 同机干扰面（为什么「本地高精度」不等于「理想实验室」）

| 事实 | 值 | 证据 |
|---|---|---|
| SMT | **开启**（`SMT active=1`、`control=on`）；`taskset` 只固定线程，**没有**排除同核兄弟线程（CPU2↔CPU18、CPU6↔CPU22 一类） | `docs/evidence/r02-env-20261016/ENV_TABLE.md` §5.1 |
| `isolcpus` | **没有**：`/sys/devices/system/cpu/isolated` 为空、内核命令行无 `isolcpus=`/`nohz_full=`/`rcu_nocbs=` | `docs/evidence/r02-env-20261016/ENV_TABLE.md` §1.3、§5.2 |
| CPU2 / CPU6 IRQ | **都不是零中断**：CPU2 累计 `nvme1q3` 1984127 次、`amdgpu` 86152 次、`nvme0q3` 96 次；CPU6 累计 `nvme1q7` 357101 次、`nvme0q7` 3 次、`PCIe PME` 1 次。这些是**开机以来累计计数**，不是采集窗口内计数；但本页不主张采集窗口内零中断 | `docs/evidence/r02-env-20261016/ENV_TABLE.md` §5.3 |
| `irqbalance` | `inactive`，`default_smp_affinity=ffffffff`（32 个 CPU 全在掩码里） | `docs/evidence/r02-env-20261016/ENV_TABLE.md` §5.3 |
| 常驻服务 | **39 个 running service**（`docker`、`gdm`、`containerd`、`codex-mihomo` 等） | `docs/evidence/r02-env-20261016/ENV_TABLE.md` §6（覆盖清单第 25 项） |
| 结论 | **整机独占、零中断、物理核独占都不是本平台的主张** | `docs/evidence/r02-env-20261016/ENV_TABLE.md` §9 |

统计侧同样要读这条：M2 家族虽未拒绝，但两个臂的描述性合并**方向相反**（unfixed +12.35 ns、fixed −11.20 ns），
这与未受控漂移一致，**不据此作任一方向的泄漏结论**。证据：`docs/evidence/platform-collection-20261016/README.md` §5。

### C.4 功效 / MDE：「未检出」的确切含义

对每个主类对，用**实测 SD** 与 n 计算 α=0.05（以及 Holm 后的有效 α）、功效 80% 下的最小可检测效应：

> **M2/M3/M5「端到端未检出」的确切含义是：在本机、本编译产物、本类对与本次样本预算下，观测到的类间均值差
> 小于本设计的最小可检测效应 MDE（M2 约 25–67 ns、M3 约 18–34 ns、M5 约 14–28 ns），
> 所以这套预算分辨不出任何小于该量级的效应；「未检出」= 观测效应 < MDE，不等于零效应，
> 也不构成恒时证明或物理泄漏界。**

证据：`docs/evidence/r04-stats-20261016/POWER.md` §2（一句话结论）、§5.1（逐模块数值读法）、§5.2（「未检出」不推出的四条）。

补充口径：

- MDE 是**统计可检测性**（给定 n 与实测 SD、80% 功效能分辨的最小均值差），**不是物理泄漏阈值**，也不是密钥恢复门槛。
  证据：`docs/evidence/r04-stats-20261016/POWER.md` §1.3、§6。
- MDE 用**本次实测 SD**，属**事后（post hoc）功效描述**，不改变任何已提交的 Holm 判定。
  证据：`docs/evidence/r04-stats-20261016/POWER.md` §6。
- 端到端未检出**不覆盖定位层**：M2 的定位层是阳性（未修链三个热点各含 1 个 `div`、已修链 0 个），
  那是指令与数据流层面的结论，**不是本机测到的物理时差**，两层互不冒充。
  证据：`docs/evidence/r04-stats-20261016/POWER.md` §5.1；`docs/evidence/m2-kyberslash-20261016/RESULT.md`。

### C.5 锁频与不锁频：锁频的价值是固定工作点，不是「必然降低方差」

R12 的族外对照在 M1 未修 / M1 已修 / M5 三个臂上各做 locked（控制器写 `boost=0`、`performance`、`min=max=4300000`）
与 unlocked（**完全不写 sysfs**，默认 `boost=1`、`powersave`、`min=2982259`、`max=5756452`、EPP=`balance_performance`）
各 9 次运行。频率归一后的变异系数 CV = SD/mean：

| 臂 | locked CV | unlocked CV | unlocked / locked |
|---|---:|---:|---:|
| M1 未修 | 0.011725 | 0.011302 | 0.964 |
| M1 已修 | 0.013044 | 0.013127 | **1.006** |
| M5 | 0.014603 | 0.015897 | **1.089** |

**结论（必须写进报告的一条）**：在本机、本体、本负载下，「锁到 4.30 GHz」与「默认 powersave+boost」的**相对变异基本相等**
（比值 0.96 / 1.01 / 1.09，跨臂方向不一致）。ns 尺度上不锁频看起来「更稳」，主要是**频率更高、每次调用耗时更短**造成的机械效应，
**不是噪声真的更小**。因此**锁频控制器的价值应当表述为确定性、可核对与可恢复的固定工作点**
（`boost=0`、固定 `min=max`、进出快照 + `restore_match=yes`），**而不是「必然降低测量方差」**。

证据：`docs/evidence/r12-innovation-20261016/RESULT_LOCKED_VS_UNLOCKED.md` §4、§5、§7（第 2 条）、§8。

边界（同一文件）：该结论限定本机、本体、本负载，不能外推到其它 CPU、其它 governor 或远程场景；
unlocked 臂「未改动配置」只证明采集进程没有写 sysfs，**不证明**系统频率恒定——恰恰相反，它就是不恒定的那一臂；
本对照**族外、不进 Holm**，不改变 M1/M5 的任何既有判定。

### C.6 远程网络时序：**未执行**

- 本轮**没有**做任何网络采集：没有回环 TCP、没有 `netns`+`veth`+`netem`、没有任何网络产物目录（仓库内不存在 `docs/evidence/r09-network-20261016/`）。
- 计划中的同机网络场景（T25，**可选**）在任务表中登记为「做不了就写 BLOCKERS 并跳过」，本轮**未执行**，因此本页写「未执行」而不写「未检出」。
  证据：`docs/全量收尾计划与提示词-20261016.md` 第 2 节 T25 行、第 5.2 节第 5 条、第 7 节风险表。
- 已有证据里明确登记「网络路径未做端到端差分」：`docs/evidence/r06-noleak-20261016/AUDIT.md` §6 第 2 条（`src/network_server.c` / `src/network_client.c` 的端到端差分未执行）。
- **不能外推**：本页第 C.1–C.5 节的全部数值都是**本地同机、单核绑核、锁频控制器**下的观测；
  远程网络会引入排队、协议栈、链路抖动与对端调度等本机不存在的量，同机结果**不能**用来推断远程可检出性。
  若后续执行 T25，引用时必须标注「**同机模拟、非真实远程**」，并保留该标注。
- 附带说明：被测实现里存在网络入口（`src/network_server.c` / `src/network_client.c`），
  但它们**不在本轮的采集与结论范围内**（同上 R06 §6 第 2 条）。

---

## D. 结论等级表

本平台把结论分三档，逐档给实例与证据路径。三档互不冒充：**「未执行」不写成阴性，「未检出」不写成恒时**。

### D1　已执行且检出

| 实例 | 数值 | 证据 |
|---|---|---|
| **M1 未修端到端**（真实历史案例） | Δ = **+39.337 ns**、95% CI **[+21.658, +57.017]（不含 0）**、dudect 最大 t = **+26.41**；换种子（424242）与换物理核（CPU6）两次独立复测方向一致（+31.117、+22.337） | `docs/evidence/r02-r04-close-20261016/RESULT.md` §2.1；原始件 `docs/evidence/liboqs010-locked-20261015/README.md` |
| **M4 vulnerable 臂**（**人工构造校准**） | 家族 Holm 拒绝 **3/3**（原始 p = 0、9.23e−25、3.14e−22）；**分臂**描述性合并 Δ = **−4.089 ns**、95% CI **[−4.215, −3.963]**；同批 ct 臂 0/3 拒绝（+0.055 ns、[−0.363, +0.473]） | `docs/evidence/platform-collection-20261016/stats/holm/RESULT.md`「Holm 逐步检验」；`docs/evidence/platform-collection-20261016/README.md` §5；`docs/evidence/r04-stats-20261016/POWER.md` §3、§5.1 |

引用注意：M4 **只引分臂数值**，不引家族窗口合并 Δ（家族 I²=98.6% 是把泄漏臂与不泄漏臂混在一起造成的）；
M4 的「insecure」只针对人工提前退出夹具，**不是**新增上游 CVE。
证据：`docs/evidence/platform-collection-20261016/README.md` §5、§6；`docs/evidence/m4-completion-20261016/FORMAL_RESULT.md`。

### D2　已执行且未检出

| 实例 | 数值 | 证据 |
|---|---|---|
| **M2 端到端**（真实历史案例） | 家族 `m2_end_to_end_full_decaps_v1`（m=6）Holm 拒绝 **0**；合并 Δ **+4.58 ns**、95% CI **[−3.08, +12.25]**（含 0）、I²=58.3%；MDE(Holm) 24.7–67.1 ns | `docs/evidence/platform-collection-20261016/stats/holm/RESULT.md`；`docs/evidence/platform-collection-20261016/README.md` §5；`docs/evidence/r04-stats-20261016/POWER.md` §2、§5.1 |
| **M3 端到端**（**人工构造校准**） | 家族（m=6）Holm 拒绝 **0**；合并 Δ **−0.73 ns**、95% CI **[−5.56, +4.10]**、I²=12.5%；MDE(Holm) 17.7–33.7 ns | 同上三处 |
| **M5 端到端**（阴性对照候选） | 家族（m=3）Holm 拒绝 **0**；合并 Δ **−5.30 ns**、95% CI **[−11.77, +1.16]**、I²=0%；MDE(Holm) 13.5–28.3 ns | 同上三处 |
| **R03 对照 A：合法 vs 格式破损**（**族外、不进 Holm**） | 3 臂 × 3 种子 = 9 个组合：Δ 全落在 **±10 ns** 内、**9/9 的 95% CI 含 0**、**9/9 原始 p ≥ 0.28**；方向在两臂之间来回摆动 | `docs/evidence/r03-malformed-20261016/RESULT.md` §3；`docs/evidence/r04-stats-20261016/POWER.md` §3 第 24/26/28…行、§5.1 |

「未检出」的确切措辞只能是「观测效应 < MDE」，并附工具、输入范围与调用边界；
它**不**推出零效应、物理恒时、不可利用、或换机器/换产物后仍成立。证据：`docs/evidence/r04-stats-20261016/POWER.md` §5.2。

对照条目（同批的阳性侧，防止把 D2 误读成「平台测不出东西」）：R03 的**对照 B（合法 vs 截断）** 的 Δ ≈ **29–55 µs**，
比该对比的 MDE（约 7–21 ns）大 3–4 个数量级；`truncated` 耗时与臂无关（三臂都是 **23.1–23.4 ns**），
走的是封装层长度检查，属于**公开长度检查的接口语义**，不是秘密相关泄漏，同样**族外**。
证据：`docs/evidence/r03-malformed-20261016/RESULT.md` §0、§4；`docs/evidence/r04-stats-20261016/POWER.md` §5.1。

### D3　未执行

| 实例 | 状态 | 证据 |
|---|---|---|
| **R05 排查表里标注 unknown 的格**：M5 重加密步骤的 Binsec `checkct` | **unknown（带参数）**，不写「不存在」。三条已实测的阻塞：Binsec 0.11.3 无法解码 x86-64（`Can not resolve decoder for x86-64`）；`checkct` 缺显式 `secret global` 时在 0 路径上仍打印 `secure`，把输入声明成 `public` 时甚至对 M4 的已知脆弱内核给出假阴性；M5 重加密消息为 32 字节自由值，路径数 2^256 量级，有界模型内必然 `unknown` | `docs/evidence/r05-locate-20261016/RESULT.md` §5；`docs/R05-全流程排查表.md` §4.4 与 §7 第 8 条；命令与产物 `docs/evidence/r05-locate-20261016/remote-tree/binsec-m5/` |
| **可选网络场景（T25）** | **未执行**：本轮没有任何网络采集产物，仓库内不存在 `docs/evidence/r09-network-20261016/`；网络路径的端到端差分亦登记为未执行 | `docs/全量收尾计划与提示词-20261016.md` 第 2 节 T25 行；`docs/evidence/r06-noleak-20261016/AUDIT.md` §6 第 2 条；详见本页第 C.6 节 |
| （相关登记）R05 的 90 格里 **「未检查」= 0 格**；表内「存在 5 / 不存在 75 / 不适用 10」，另有 1 项按 unknown 登记 | 已执行且已更新 | `docs/R05-全流程排查表.md` §4.1–§4.3 |

---

## E. 遗留与边界

1. **本页不做密钥恢复**，不运行 exploit demo，不给总体误报率/检出率，不给物理误差界；「未检出」一律不得改写为恒时证明。
   证据口径：`docs/evidence/r04-stats-20261016/POWER.md` §6；`docs/evidence/platform-collection-20261016/README.md` §6。
2. **人工夹具标注**：M3（秘密下标 LUT）与 M4（提前退出比较）是**人工构造校准**，阳性只能检验检测器能否识别目标机制，
   不计为新的真实 CVE。证据：`docs/platform/ARCHITECTURE.md` §1；`docs/evidence/m4-completion-20261016/RESULT.md`「边界」。
3. **族外标注**：R03 的两个对照（A 格式破损、B 截断）与 R12 的锁频对照一律**族外、不进 Holm**，不改变任何已冻结家族判定；
   dudect 的最大 t 与 RTLF 的二值结果同样族外，**不转伪 p**。证据：`docs/evidence/r03-malformed-20261016/RESULT.md` 开头与 §6；
   `docs/evidence/r12-innovation-20261016/RESULT_LOCKED_VS_UNLOCKED.md` §1、§8；`docs/evidence/platform-collection-20261016/README.md` §1.0、§6。
4. **待整合 agent 处理的两处**（本页不擅自改写）：
   - **网络段落**：本页第 C.6 节按「T25 未执行」写。若后续执行 T25，需要把该节改写为引用 + 明确标注「同机模拟、非真实远程」，
     并删去「未执行」措辞；在 T25 数据出现前，D3 表的第二行也保持「未执行」。
   - **M1 的 Holm 家族口径**：`docs/evidence/r04-stats-20261016/POWER.md` §5.1 写「M1 主类对**没有**预注册 Holm 家族」（族外、单次运行），
     而 `docs/evidence/r02-r04-close-20261016/RESULT.md` §3 写参数检验族保留 m=6 项端到端 Welch 检验。
     本页 D1 只引用 M1 的**检出事实与数值**（Δ、CI、dudect t、三次独立复测方向一致），
     **不断言** M1 的 Holm 确认状态；整合时若要在报告中写 M1 的 Holm 口径，需先由主控在两份证据之间定口径。
5. **观测量边界**：本页 A.2 把攻击者的可观测量限定为单次调用耗时；R06 的 F1（M2 采集件批级接受/拒绝汇总进退出码/stderr/meta）
   与 R06 §6 第 5 条列出的未检查进程可观察面（`cmdline`、fd、`maps`、core dump、`wait4`、信号、`/proc/<pid>/stat`、文件名与 mtime）
   都**不在**本威胁模型的观测面内，本轮也**未执行**对这些面的检查。证据：`docs/evidence/r06-noleak-20261016/AUDIT.md` §1.3 F1、§6 第 5 条。
6. **本页的性质**：只读复述与登记，不是新的采集、不是新的统计、不是验收结论；所有数字以被引用文件为准，冲突时以被引用文件为准。

---

## F. 本页引用的证据路径清单

**只读引用，共 27 条**（26 个文件 + 1 个目录）；本目录未写入、未改动这些路径下的任何内容：

| # | 路径 | 用到的位置 |
|---:|---|---|
| 1 | `docs/evidence/r02-env-20261016/ENV_TABLE.md` | §1.1–§1.6、§4.1–§4.4、§5.1–§5.3、§6、§7、§9 |
| 2 | `docs/evidence/r02-env-20261016/ROBUSTNESS.md` | §0、§6.1 |
| 3 | `docs/evidence/r04-stats-20261016/POWER.md` | §1.3、§2、§3、§5.1、§5.2、§6 |
| 4 | `docs/evidence/r04-stats-20261016/QUANTILE_CI.md` | §4.4 |
| 5 | `docs/evidence/r12-innovation-20261016/RESULT_LOCKED_VS_UNLOCKED.md` | §1、§4、§5、§7、§8 |
| 6 | `docs/evidence/r03-malformed-20261016/RESULT.md` | §0–§6 |
| 7 | `docs/evidence/r05-locate-20261016/RESULT.md` | §4.1、§5 |
| 8 | `docs/R05-全流程排查表.md` | §4.1–§4.4、§7 |
| 9 | `docs/evidence/r05-locate-20261016/remote-tree/binsec-m5/`（目录） | M5 Binsec 阻塞实验 A/B/B2/B3/B4/C 的产物 |
| 10 | `docs/evidence/r06-noleak-20261016/AUDIT.md` | §0、§1.3 F1、§2、§3、§4、§6 |
| 11 | `docs/evidence/r01-kat-20261016/README.md` | 「内容」「复现」 |
| 12 | `docs/evidence/r01-kat-20261016/VECTORS.md` | 向量来源总表 |
| 13 | `docs/evidence/r01-kat-20261016/EQUIV.md` | 修复语义等价总表 |
| 14 | `docs/evidence/platform-collection-20261016/README.md` | §1、§1.0、§2、§5、§6、§7 |
| 15 | `docs/evidence/platform-collection-20261016/stats/holm/RESULT.md` | Holm 逐步检验与固定效应合并表 |
| 16 | `docs/evidence/platform-control-qualification-20261016/QUALIFICATION.md` | 控制器资格与 `scaling_cur_freq` 口径 |
| 17 | `docs/evidence/m2-kem-20261016/RESULT.md` | 资格表、热点 div 判定 |
| 18 | `docs/evidence/m2-kem-20261016/COLLECTOR_CONTRACT.md` | 计时窗口与调用边界 |
| 19 | `docs/evidence/m2-kyberslash-20261016/RESULT.md` | 定位层阳性 |
| 20 | `docs/evidence/m3-completion-20261016/RESULT.md` | 人工 LUT 完整解封装 |
| 21 | `docs/evidence/m4-completion-20261016/RESULT.md` | 人工提前退出比较夹具 |
| 22 | `docs/evidence/m4-completion-20261016/FORMAL_RESULT.md` | Binsec 有界验证 |
| 23 | `docs/evidence/m5-completion-20261016/RESULT.md` | M5 参考臂 |
| 24 | `docs/evidence/r02-r04-close-20261016/RESULT.md` | §2.1、§3 |
| 25 | `docs/evidence/liboqs010-locked-20261015/README.md` | M1 锁频原始件与复测 |
| 26 | `docs/platform/ARCHITECTURE.md` | §1 模块与独立边界 |
| 27 | `docs/全量收尾计划与提示词-20261016.md` | 第 2 节 T25 行、第 5.2/7 节 |
