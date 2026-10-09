# G1 频率请求与可见恢复实物独立复核

2026-10-10。结论：实际归档支持 G1 的两个注册空任务路径通过；未发现阻断该限定结论的实物矛盾。G2 未运行，恒频、R02 总体与 R04 均不升级。

本次直接读取本机收到的 `core-frequency-20261010-d05b4396f082.tar`，重算 SHA-256 为 `3c4951ac57b905b9fa232858f2bf017ef93daaf5f522d8d9a38126e53a7da122`。68 个成员均为唯一常规文件，无绝对路径或上级路径成分，实际读取长度与成员声明长度逐一相同。核查使用独立的内存解析与断言，没有仅依赖主线程的结果摘要；未 SSH、执行程序、写内核或修改其他证据。

## 源码与执行身份

`source.json` 内完整 SOURCE_TEXT 的重算摘要与其登记值同为 `b7057c2af9a32ac93491815756eaaf0d964745f56ef4f9c05b59c84ba36c7661`，字节与 Git 提交 `991f154` 的 `rehearse_partition.py` 对象相同。这是事前审查的同一版本，空任务固定为 `/usr/bin/true`，没有长 worker 或密码算法负载。

另外直接读取 linux-check 的 configure/test 结果及 LastTest 原日志：真实 Linux 的独立 CMake/CTest 检查退出 0、1/1 通过，含 16 类管理与故障模拟检查，明确 `kernel_writes=none`。这是运行前的软件检查，未将该检查计作频率实测。

| case | controller PID／退出 | guard PID／结束原因 | probe PID／退出 |
| --- | --- | --- | --- |
| normal | 3663687／0 | 3663688／release | 3663698／0 |
| parent-loss | 3663707／−9 | 3663709／controller_eof | 3663720／0 |

两份 terminal 均记录 active_observed=true、errors=[]、success=true；observer 的退出状态与表格一致。`observer-guard.json` 均记录 ARM 前取得 pidfd，保存 identity 与 guard.json、observer-final.json 完全一致；ready 和 terminal 也指向同一 guard PID。observer 均实际记录 guard pidfd 已退出，observer-final 的角色为 terminal_snapshot，没有以单独 terminal 文件冒充进程终止。

两份 probe-before-exec 均记录目标 nonce 的 probe cgroup 和 allowed_cpus=[2,18]；probe-exit 的 PID 与之前记录相同，退出 0。已审源码只有 waitpid 回收后才保存成功退出收据，再形成 active 状态，因此本次 parent-loss 是空任务回收后的 controller 单进程 SIGKILL，不能解释为长 worker 运行中的取消测试。两组 controller.log、guard.log 均为空，无隐藏在日志中的错误。

## 四个字段的请求与恢复链

每 case 的 frequency-baseline 包含全部 32 个 singleton policy、目标 CPU 映射及 global 状态。两目标原 min/max 均为 2982259/5756452 kHz；governor=powersave、EPP=balance_performance、local boost=1。global 为 amd-pstate active、boost=1、prefcore=enabled。

active.frequency 与 baseline 的完整对象只在 policy2/18 各自的 scaling_min_freq、scaling_max_freq 四个 value 上不同，均为 4300000。其余 30 个 policy、global 字段、目标非可写字段及各属性身份全部一致；active 的 probe effective 为 2,18，根 effective 为其余 30 个 CPU，isolated 为 [2,18]。

每 case 恰有连续编号 0000—0007 的八份 dirty intent 和对应八份 visible 收据，逐项核对 sequence、policy、field、before_pair、after_pair 及 limits_khz，链条为：

1. policy2 原 pair → min=4300000 → max=4300000。
2. policy18 原 pair → min=4300000 → max=4300000。
3. policy2 固定 pair → min=2982259 → max=5756452。
4. policy18 固定 pair → min=2982259 → max=5756452。

只涉及四个注册字段，未出现写其他 policy 或控制项的 intent。写前持久化顺序来自已审且原样封存的 SOURCE_TEXT；实际收据链与该控制流相符。按照该源码的 pending_fields 语义，从 intent 和原值对应 visible 收据独立重建，两个目标的 pending 集合在恢复后均为空；归档没有直接保存内存 pending 变量，本复核没有虚构该字段。

每 case 均只有一份 frequency-restored-0008 收据，其 snapshot 与本 case baseline 的完整 JSON 数据对象相同，包括全部 32 policy、global、CPU links 和策略集合，而非只检查四个数值。两 case baseline 的规范化 JSON SHA-256 均为 `847ecd57c25c4a343c0ef3fd630a15ff5fd739ff4cade1f54dbf6f268e9a39d0`；这里比较的是完整数据对象，不把带不同外层时间字段的 JSON 文件称作原始文件字节相同。

## 独立结束回读与边界

两份 observer.frequency_readback 都再次与对应 baseline 完整相同；terminal 与 observer 的 cgroup 回读均为根 CPU0—31、isolated=[]，top_names 与原 cgroup baseline 一致。两份 observer.success 均为 true，根 run.json 也为 success=true、errors=[]、hardware_frequency_qualified=false。normal 完成并经 observer 核验后才开始 parent-loss，与注册顺序相符。

补充实物核验已直接读取 tool-receipts/root-postcheck.log、实际工具返回字段 JSON 和 orchestration-source/postcheck.py，工具退出 0。该检查时间为 `2026-10-09T22:38:46.471832+00:00`，normal 与 parent-loss 的上述全部六个 PID 均走 pidfd 的 ProcessLookupError 分支，记录 original_absent=true；没有把 PID 复用分支冒称为 PID 不存在。根 effective 为完整 CPU0—31、isolated=[]，自有 nonce cgroup 均不存在，管理锁取得后已关闭释放，configuration_writes=0。

postcheck.py 内嵌冻结源重算仍为 b7057c2…，其本身 SHA-256 为 `0c62bedc2092ea2835c165eeb286aba12323e2ffe759876238bf4c73b637511c`。直接审查该检查源码可见：它先读取完整 frequency_snapshot 并与两个 case 的完整 baseline 对象比较，之后才生成 all_32_policies_and_global_equal_baseline=true；随后独立比较 root 私有原件与 tar 各成员，并实际取得、释放同一管理锁。原 post 输出保存了这些比较结果和两目标原 min/max，没有转储另一份全量 policy 对象，本复核没有将结果旗标冒称为逐字段原始转储；完整最终频率对象已由上述 observer 保存。

同目录持久 tar 的重算摘要仍为 3c4951ac…；本机 originals 的文件集合恰为该 tar 的 68 个成员，每份实际字节逐一相同。root-post 原输出也记录 private_original_files_equal_archive=68 和同一完整 tar 摘要，与本机独立比较相符。因此 root-post、原件保全和软件日志已纳入本次实物核验范围；本复核始终没有重新连接远端，也不把该时点回读称为持续监控或当前远端保证。

可签收范围仅为这台机器上、本源码版本的 normal 与 active 后 controller 单进程 SIGKILL 两次空任务管理预演：四个频率限制请求可见、事务取消链闭合、原可见配置与分区恢复、自己的空任务已回收、guard 终止已观察。没有活动区间 E7/E8 采样、真实频率带判定、长 worker 的 EOF/取消衔接或密码负载测量。也不证明隐藏 QoS 请求逐位复原、guard 自身 SIGKILL/OOM 自动恢复或任意并发管理员场景安全；G2、恒频及 R02/R04 完成均未由本归档证明。
