# 单物理核的短窗口预留方案

2026-10-09。用户提出只用少量CPU即可，不把整机独占当作继续研究的前提。实际拓扑中CPU2和18属于同一物理核心，可按这一核心准备短窗口预留，其余30个逻辑CPU继续工作。

当前Linux6.17/cgroup v2支持cpuset机制，但本机systemd255没有较新CPUSetPartition管理属性。普通会话没有cpuset委派或频率文件写权限；账号sudo策略允许正常管理，sudo免密码测试失败的原因只是需要密码认证，不代表无管理员权限。

按本机现有管理接口，候选由systemd临时建立独立顶层实验slice，AllowedCPUs仅2,18；采集线程只运行在CPU2，CPU18留空。其他顶层单位的原CPU限制与其余CPU集合取交集。先保存实际运行时属性、有效集合及现有线程的亲和性，检查其他单位或线程是否仅允许2/18、取交集是否为空；有冲突就不实施，不停止其他人的作业，也不改其显式亲和性。实施后普通任务可能由调度器转到其余CPU，这是预留的实际影响。

预留前后枚举实际顶层单位和根组普通任务，核对实验与其他普通任务的有效集合无重叠，不能只看实验进程的taskset。期间若发现新增单位、CPU上下线、有效集合变化或无法确认的缺口，停止该轮采集并保留失败记录；轮询不能证明两次观察之间绝无变化。结束及异常退出按原配置恢复并回读，同时准备独立于采集会话的恢复路径。不得直接在systemd拥有的根层写自造cgroup或使用本版本不存在的属性。

这是普通任务的CPU预留，不称内核isolated partition，也不承诺零干扰。硬件中断、每核内核活动、共享缓存/内存带宽及功率温度仍需记录；其他任务临时少一物理核，影响通常有限但不能由低负载断言为零。单独taskset只限自己的位置，不能排除别人。

本次仅完成权限与机制只读核查，尚未修改运行配置。正式采集前仍需检查实际冲突、正常管理认证、预留有效性和完整恢复；频率控制另按原候选，不改全机boost、SMT或IRQ。预留一个核不能代替R04的目标、真值和有效统计依据。

依据为[Linux6.17 cpuset文档](https://docs.kernel.org/6.17/admin-guide/cgroup-v2.html#cpuset)、[systemd v255管理接口源码](https://raw.githubusercontent.com/systemd/systemd/v255/src/core/dbus-cgroup.c)与[systemd委派说明](https://systemd.io/CGROUP_DELEGATION/)。实际只读结果见[核查记录](../../evidence/aris-core-reservation-20261009/feasibility.json)。

同日继续实际只读核查：第一版枚举127个控制组、1232个普通线程，未记录到亲和性或原始请求完全限于2/18以及未映射普通线程的情形；独立复核发现它不覆盖完整祖先交集。保留第一版并补正清单后，新第二版枚举122个控制组、1054个普通线程，已记录祖先交集/亲和性交集、读取和身份变化列表均为空。两版只是各自顺序读取时点，请求投影未验证partition，ready_to_apply_reservation仍为false，不能把它们作为已经实施或完整准入的证明。正常sudo认证已成功，实际有效UID为0；turbostat的版本及列举接口可用，但尚未采样硬件频率。新[核查原件与边界](../../evidence/aris-core-conflict-20261009/README.md)保留全部版本和回执，不改原先未认证的时点记录。

独立实施审查补充：恢复时还须保存本次属性对应运行时覆盖文件的存在状态、原字节和元数据，不能仅把AllowedCPUs改回同值；systemd v255的set-property可能创建50-AllowedCPUs.conf。各级控制器启用状态也须前后核对。恢复计时器先停止本次控制器，再执行幂等恢复，防止恢复后仍有迟到写入；计时器须先用不改CPU配置的标记验证。空闲子组的显式限制也检查，不能仅检查当前线程。有同期第三方配置变化时保留差异并停止，不盲目覆盖。下一实施限一次/bin/true管理预演，不包含正式计时；上述快照不替代实施前的新检查。[v255写设置源码](https://raw.githubusercontent.com/systemd/systemd/v255/src/core/unit.c)及[Linux6.17亲和性源码](https://raw.githubusercontent.com/torvalds/linux/v6.17/kernel/sched/core.c)支持这些边界。
