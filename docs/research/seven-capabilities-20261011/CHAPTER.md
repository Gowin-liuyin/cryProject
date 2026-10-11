# 时间侧信道检测、定位与跨环境验证

本章使用固定便携 C 的 ML-KEM-768。五类输入仍是有效、翻位、随机、全 0 硬币和全 1 硬币生成的 1088 字节密文。全 0 与全 1 在同一密钥下各只产生一条密文，`ryzen-vulnerable` 的 s1 元数据写明 `message-zero_unique_ciphertexts=1`。确认协议在看到确认样本之前冻结：族内 α 为 0.01，Holm 控制，分析单位是会话，预算是 6 个会话、每类 1000 次，停止规则是固定预算。开发种子与确认种子不同。确认种子是 `20261111`。两台机器的样本不合并。

## X.1 本地高精度计时与明显时间泄露检测

计时窗口只包住一次完整解封装。输入生成、预热、结果消费和 CSV 都在窗口外。读钟使用 `CLOCK_MONOTONIC`，记录的是该时钟的整数计数。元数据写明这不是 1 纳秒的物理精度。

Ryzen 9 9950X 上 `ryzen-vulnerable` 的 s1 记录 `resolution_counts=1`，256 次同路径空窗的最大计数是 40。Apple Silicon 上 `apple-v` 的对应记录是分辨率 1000、空窗最大 1000。空窗长尾被保留，没有拿空窗去减正式样本。

| run_id | resolution_counts | empty_window_max | sessions × per class | primary mean | p | Holm | Wald |
|---|---:|---:|---|---:|---:|---|---|
| `ryzen-vulnerable` | 1 | 40 | 6 × 1000 | 15.44 | 0.419 | no | −18.96, 49.85 |
| `apple-v` | 1000 | 1000 | 6 × 1000 | −297.67 | 0.627 | no | −1424.51, 829.17 |
| `v2-vulnerable` | 1 | 60 | 20 × 5000 | 1.40 | 0.852 | no | −13.13, 15.93 |

确认集上，人工消息分支的主比较是全 0 类均值减去全 1 类均值。`ryzen-vulnerable` 六个会话的主效应均值是 15.44 个时钟计数，t 为 0.880，双侧 p 为 0.419，Holm 没有拒绝。95% Wald 区间是 −18.96 到 49.85，跨过 0。把六个会话的调用摊开看，全 0 类 6000 次均值 29747.28、标准差 1281.62、P50 为 29635；全 1 类均值 29731.84、标准差 1041.21、P50 为 29636。类别差小于空窗里已经出现的 40 计数长尾。`apple-v` 的主效应均值是 −297.67，t 为 −0.518，p 为 0.627，Wald 区间 −1424.51 到 829.17，同样没有拒绝。在这条冻结规则下，两台机器都没有检出明显时间泄露。

## X.2 解封装过程的函数级插桩与时序分析

诊断构建是单独的目标。它不改正式 deployable，也不把 sanitizer 计时写进矩阵。编译器对七个阶段包装函数插入进入和退出钩子。比较、拒绝密钥派生和选择在上游是宏或 static inline，钩子到达的是包装函数，摘要里写了对应的内联映射。事件只有样本编号、模块相对函数编号、进入或退出、时间戳和完整性状态。

`ryzen-vulnerable` 的诊断排名列出七个阶段，`uncovered_count=0`。重加密、比较和解密位列前三，但端到端检测没有成立，所以输出是 `single_root_cause=not_forced`。诊断样本上重加密的排他差只有 24 个计数，不能把它写成根因。

| mode | raw file | quantity | counts |
|---|---|---|---:|
| 无插桩 | `trace-overhead/plain.csv`，run_id `overhead-plain` | 全部样本均值 | 24000 |
| 只记账 | `trace-overhead/account-summary.txt` | 有效类外层均值 | 25500 |
| 完整计时钩子 | `trace-overhead/timing-summary.txt` | 有效类外层均值 | 43500 |

三组都写 `hook_cost_not_subtracted=yes`。没有用一个常数去减钩子开销，再把剩下的数叫做无扰动函数时间。

## X.3 时间差异的统计显著性与检测能力分析

新入口只读冻结协议，不改历史 `analyze` 的检验定义。历史回放测试 `analysis_round1_replay` 仍然通过。主比较和三条次比较组成一个族，用 Holm 在 α=0.01 上一起控制。推断单位是会话均值差，不是把相关调用堆成一组后的 Welch 检验。

构造的无类别效应夹具给出主效应 15、t 统计量 3。自由度为 1 时，这就是柯西分布，双侧 p 等于 `1-2*atan(3)/π`。程序输出与这个独立计算一致，并且没有拒绝主比较。协议禁止把阈值写成看过确认数据之后才选定。两台机器的确认输出都是 `thresholds_chosen_after_data=no`。

`ryzen-vulnerable` 六个会话的主效应（全 0 减全 1，时钟计数）是：

| session | s1 | s2 | s3 | s4 | s5 | s6 |
|---|---:|---:|---:|---:|---:|---:|
| difference | 4.70 | 87.11 | −43.85 | 30.85 | 13.78 | 0.07 |

会话均值 15.44，Wald 区间跨过 0。全 0 和全 1 的重复率不是 0，会话内自相关也没有被证明可以忽略，因此 `iid_upgrade=refused`。协议本身禁止恒时升级，输出是 `constant_time_upgrade=refused`。等长分块后再取均值，块均值的平均与总会话均值相同，所以三档块长给出同一个主效应；这是均值估计量的性质，不是另一次显著。确认预算用完即停。没有因为 p 值不够小而追加样本。

## X.4 潜在泄露源的自动化定位与防护验证

排名器只读候选表里的阶段、函数、源码位置、包含差和排他差。表头若出现 ground truth、目标名、补丁名或预置目标名，程序退出码为 2。两个固定夹具的最大排他差分别落在重加密和比较上，两次运行的 Top-1 不同。这只说明排序不是写死的三个位置，不是本次硬件上的检出。

| run_id | primary mean | p | Holm | 说明 |
|---|---:|---:|---|---|
| `ryzen-vulnerable` | 15.44 | 0.419 | no | 检测未成立，`single_root_cause=not_forced` |
| `ryzen-hardened` | 29.90 | 0.066 | no | 不能写成差异消失 |
| `ryzen-rollback` | −18.17 | 0.258 | no | 不能写成差异恢复 |

打印出的 v1 Top-3 是重加密、比较、解密，`uncovered_count=0`，但检出会话是 0/6，定位成功分母是 0。v2 用计划起点 20×5000 和新种子 `8675309`，在采集前冻结。`v2-vulnerable` 主效应 1.40，p=0.852，Holm 仍不拒绝。`v2-hardened` 是 4.28，p=0.261；`v2-rollback` 是 −5.00，p=0.034，也都没有拒绝。检出会话是 0/20。排名器对 v2 仍输出 `single_root_cause=not_forced`。重加密出现在打印的 Top-3 里，但检测没有成立，这 0/20 不算定位成功，也不能把掩码或回滚写成差异消失或恢复。`ryzen-vulnerable` 的端到端 Holm 没有拒绝，排名器因此不给唯一根因。同优化掩码 `ryzen-hardened` 的主效应均值是 29.90，p 为 0.066，Wald 区间 4.85 到 54.94，Holm 仍未拒绝。新目录重新构建的 `ryzen-rollback` 主效应均值是 −18.17，p 为 0.258，区间跨过 0。三条确认都没有达到检测条件，所以不能把掩码写成“差异消失”，也不能把回滚写成“差异恢复”。vulnerable 与 hardened 的公开 KAT 在这台机器上通过，包含隐式拒绝向量。Apple Silicon 的 `apple-v` 与 `apple-h` 同样没有拒绝主比较。检测没有成立时，定位成功的分母是 0。

## X.5 网络噪声环境下的时间侧信道检测

测试端点的请求是固定长度密文，应答是 32 字节固定确认。应答不包含共享秘密、接受或拒绝标志，也不包含服务端耗时。本机回环测试里，有效密文和翻位密文的应答正文相同，服务端完成次数等于请求次数。

| run_id | requests | server completed | mean RTT (µs) | 设置 |
|---|---:|---:|---:|---|
| `network-jitter-low` | 80 | 80 | 152.7 | 单向 100 µs，抖动 20 µs |
| `network-jitter-mid` | 80 | 80 | 1081.6 | 单向 1 ms，抖动 200 µs |
| `network-jitter-high` | 80 | 80 | 10308.4 | 单向 10 ms，抖动 2 ms |
| `mac-to-ryzen-18012` | 0 | — | — | 直接连接失败，没有 RTT 文件 |

veth 三档不是 Mac 到 Ryzen 的路径。Ryzen 上的三档噪声没有使用管理网卡。进程网络命名空间里的 veth 两端是 10.88.11.1 和 10.88.11.2，netem 加在密码窗口之外。结束后 veth 已删除。`network-jitter-low`、`network-jitter-mid`、`network-jitter-high` 各有 80 条客户端 RTT，服务端完成次数都是 80。均值分别是 152.7、1081.6 和 10308.4 微秒，与单向 100 微秒、1 毫秒和 10 毫秒的设置同量级。这些 RTT 比本地大约 30 微秒的解封装大得多。在这个预算下，网络观测没有被用来宣布检出或宣布不存在远程泄露。

Mac 到 `10.144.144.5:18012` 的直接连接没有形成。Ryzen 监听 `0.0.0.0:18012`，本机探测退出码为 1。run_id `mac-to-ryzen-18012` 没有 RTT 文件。没有用 SSH 隧道代替这条路径。

## X.6 编译器优化对时序行为及防护效果的影响

| variant | compiler | opt | status | compile | link | run_id |
|---|---|---|---|---|---|---|
| reference | gcc | O0 | qualified | -O0 | -O0 | `matrix-reference-gcc-O0` |
| reference | gcc | O1 | qualified | -O1 | -O1 | `matrix-reference-gcc-O1` |
| reference | gcc | O2 | qualified | -O2 | -O2 | `matrix-reference-gcc-O2` |
| reference | gcc | O3 | qualified | -O3 | -O3 | `matrix-reference-gcc-O3` |
| reference | gcc | O2LTO | qualified | -O2 -flto | -flto | `matrix-reference-gcc-O2LTO` |
| reference | clang | O0 | qualified | -O0 | -O0 | `matrix-reference-clang-O0` |
| reference | clang | O1 | qualified | -O1 | -O1 | `matrix-reference-clang-O1` |
| reference | clang | O2 | qualified | -O2 | -O2 | `matrix-reference-clang-O2` |
| reference | clang | O3 | qualified | -O3 | -O3 | `matrix-reference-clang-O3` |
| reference | clang | O2LTO | qualified | -O2 -flto | -flto | `matrix-reference-clang-O2LTO` |
| deployable | gcc | O0 | qualified | -O0 | -O0 | `matrix-deployable-gcc-O0` |
| deployable | gcc | O1 | qualified | -O1 | -O1 | `matrix-deployable-gcc-O1` |
| deployable | gcc | O2 | qualified | -O2 | -O2 | `matrix-deployable-gcc-O2` |
| deployable | gcc | O3 | qualified | -O3 | -O3 | `matrix-deployable-gcc-O3` |
| deployable | gcc | O2LTO | qualified | -O2 -flto | -flto | `matrix-deployable-gcc-O2LTO` |
| deployable | clang | O0 | qualified | -O0 | -O0 | `matrix-deployable-clang-O0` |
| deployable | clang | O1 | qualified | -O1 | -O1 | `matrix-deployable-clang-O1` |
| deployable | clang | O2 | qualified | -O2 | -O2 | `matrix-deployable-clang-O2` |
| deployable | clang | O3 | qualified | -O3 | -O3 | `matrix-deployable-clang-O3` |
| deployable | clang | O2LTO | qualified | -O2 -flto | -flto | `matrix-deployable-clang-O2LTO` |
| vulnerable | gcc | O2 | qualified | -O2 | -O2 | `matrix-vulnerable-gcc-O2` |
| vulnerable | clang | O2 | qualified | -O2 | -O2 | `matrix-vulnerable-clang-O2` |
| hardened | gcc | O2 | qualified | -O2 | -O2 | `matrix-hardened-gcc-O2` |
| hardened | clang | O2 | qualified | -O2 | -O2 | `matrix-hardened-clang-O2` |

24 格全部 `status=qualified`。O0 编译行没有另一个 `-O2`。O2+LTO 的链接行含 `-flto`。reference 和 deployable 各有 GCC 与 Clang 的 O0、O1、O2、O3 和 O2+LTO。vulnerable 和 hardened 只有外层 O2，函数级的 O0 或 optnone 约束仍在补丁里，不能写成对目标函数做了 O3 测试。每个格子都有公开 KAT、实际编译行、链接行，以及每类 20 次的基础计时。sanitizer 没有进入这些计时。

`matrix-reference-gcc-O0` 的编译行在配置标志之后是 `-O0`，其中没有另一个 `-O2`。`matrix-reference-gcc-O2LTO` 的链接行包含 `-flto`。`matrix-reference-gcc-O2` 的基础计时里，有效类 20 次均值是 29887.9 个计数，全 0 类是 29958.1，全 1 类是 30007.7。这是每类 20 次的范围观察，不是确认协议的 1000 次会话检验。优化改变了编译和链接行；在未做逐格确认检验之前，不能把某一格的均值差写成防护失效或防护成立。

## X.7 不同处理器平台上的检测与防护稳定性

| platform | run_id | resolution | empty max | primary mean | p | Holm |
|---|---|---:|---:|---:|---:|---|
| Ryzen 9 9950X | `ryzen-vulnerable` | 1 | 40 | 15.44 | 0.419 | no |
| Apple Silicon | `apple-v` | 1000 | 1000 | −297.67 | 0.627 | no |

两行来自同一确认种子 `20261111` 和 v1 的 6×1000，样本没有合并。两边的主比较都没有被 Holm 拒绝。Ryzen 上 `ryzen-vulnerable` 的主效应是 15.44 个计数，空窗最大是 40。Apple 上 `apple-v` 的主效应是 −297.67，时钟分辨率和空窗最大都是 1000。两边的绝对纳秒差不能相减后叫做防护效果变化。

两台机器同时改变了处理器、操作系统和工具链。这个记录支持的是同协议跨环境复测，不是“只换了 CPU”。直接的 Mac 到 Ryzen 网络路径没有连通，因此平台比较不包括那条远程 RTT。没有第三台机器。没有把历史 KVM 的旧样本并进来凑检出。

## 边界

软件能够采集、插桩、按冻结协议做会话检验、对候选排序，并完成回环、三档 veth 噪声和 24 格构建。冻结确认没有检出人工分支，自动定位因此不声称根因。这不证明实现恒时，也不证明网络上不可区分。R02 与 R04 仍按原验收表保持部分签收。
