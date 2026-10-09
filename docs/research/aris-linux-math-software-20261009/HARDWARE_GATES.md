# 裸金属恢复后的最小硬件门槛

日期：2026-10-09；未连接服务器、运行实验或修改硬件。依据：[当前协议](../aris-replication-20261009/NEXT_VALIDATION_PROTOCOL.md)、[恢复原记录](../../evidence/aris-access-restored-20261009/access-check.json)、[验收表](../../full-work-acceptance.md)。

已证明密码认证成功、`nss-m`、Linux/x86_64、虚拟化检测 `none`、32线程及约定根目录存在。只有一次 `powersave` 观察，频率控制仍为 `NOT_VERIFIED`；不能推定CPU空闲、目录可写或sudo可用。

| 最小只读集合 | 留证与判定边界 |
|---|---|
| 机器/可用性 | UTC、内核/系统、CPU型号、在线CPU、可用内存/磁盘；本会话 `Cpus_allowed_list`、自身cgroup有效cpuset/CPU配额；`cpu*/topology/{core_id,physical_package_id,thread_siblings_list}`。两次带时间戳的 `/proc/stat` CPU计数、`/proc/loadavg`、`/proc/pressure/cpu`；低负载不证独占，不收集他人进程列表。 |
| 源/产物 | 源码/输入摘要、提交及源码目录修改摘要；编译器/CMake版本、真实编译/链接选项与对象、二进制摘要、目标机器码。普通/动态检查分开；仅既定未修改参考任务或纯数学软件核验，不启动历史活跃变体。 |
| 频率/温度 | 相关 `cpufreq/policy*/` 的驱动、governor、`related_cpus`、频率上下限/可用值/EPP/当前值；`amd_pstate/status`、全局及存在的每策略 `boost`。已标明CPU传感器的 `hwmon` 名称、温度标签/原值/单位及可读电源/温控状态。缺文件或读失败留状态，不填默认值。 |
| 时钟/期间 | `clocksource0/current_clocksource` 及可用源；后续登记执行取得实际时钟名/单位、C中 `clock_getres`、原始空窗/校准/完整函数值、自身实际亲和性及前后/期间环境记录。静态预检不能代替期间证据。 |

`scaling_cur_freq` 可能反映请求值；瞬时值或上下限相等不证期间实际锁频。AMD主动模式还依赖固件/EPP/功率/温度。governor名称不独立决定锁频；分辨率不等于准确度。[CPUFreq文档](https://docs.kernel.org/admin-guide/pm/cpufreq.html)、[AMD文档](https://docs.kernel.org/admin-guide/pm/amd-pstate.html)支持这些区别，文件以该机内核为准。

已有研究/重跑/登录授权，以上只读核验及约定目录内新成果无需再许可。共享状态、可预留核心/SMT同胞、控制窗口及管理权限仍未知。自身亲和性可按冻结合同实施，但不证独占。改governor/boost、驱动模式、IRQ或系统隔离前确认影响范围和控制授权；已有可信授权不重复询问。先形成可审方案：实际支持的文件/原值/拟改值、受影响任务、窗口、失败停止及逐项恢复核对。本页不指定虚构频率或自动写入。

本页补R02资源/配置的可识别性，不签收R02。精度目标、允许频率带、预算及期间观察须事前冻结，不搬用M02门槛。R04仍缺用例、容许差异、有效真值/假设、随机化及功效依据；纯数学Linux兼容性不能补这些证据。
