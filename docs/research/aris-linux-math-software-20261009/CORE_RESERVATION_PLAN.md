# 单物理核的短窗口预留方案

2026-10-09。用户提出只用少量CPU即可，不把整机独占当作继续研究的前提。实际拓扑中CPU2和18属于同一物理核心，可按这一核心准备短窗口预留，其余30个逻辑CPU继续工作。

当前Linux6.17/cgroup v2支持cpuset机制，但本机systemd255没有较新CPUSetPartition管理属性。普通会话没有cpuset委派或频率文件写权限；账号sudo策略允许正常管理，sudo免密码测试失败的原因只是需要密码认证，不代表无管理员权限。

按本机现有管理接口，候选由systemd临时建立独立顶层实验slice，AllowedCPUs仅2,18；采集线程只运行在CPU2，CPU18留空。其他顶层单位的原CPU限制与其余CPU集合取交集。先保存实际运行时属性、有效集合及现有线程的亲和性，检查其他单位或线程是否仅允许2/18、取交集是否为空；有冲突就不实施，不停止其他人的作业，也不改其显式亲和性。实施后普通任务可能由调度器转到其余CPU，这是预留的实际影响。

预留前后枚举实际顶层单位和根组普通任务，核对实验与其他普通任务的有效集合无重叠，不能只看实验进程的taskset。期间若发现新增单位、CPU上下线、有效集合变化或无法确认的缺口，停止该轮采集并保留失败记录；轮询不能证明两次观察之间绝无变化。结束及异常退出按原配置恢复并回读，同时准备独立于采集会话的恢复路径。不得直接在systemd拥有的根层写自造cgroup或使用本版本不存在的属性。

这是普通任务的CPU预留，不称内核isolated partition，也不承诺零干扰。硬件中断、每核内核活动、共享缓存/内存带宽及功率温度仍需记录；其他任务临时少一物理核，影响通常有限但不能由低负载断言为零。单独taskset只限自己的位置，不能排除别人。

本次仅完成权限与机制只读核查，尚未修改运行配置。正式采集前仍需检查实际冲突、正常管理认证、预留有效性和完整恢复；频率控制另按原候选，不改全机boost、SMT或IRQ。预留一个核不能代替R04的目标、真值和有效统计依据。

依据为[Linux6.17 cpuset文档](https://docs.kernel.org/6.17/admin-guide/cgroup-v2.html#cpuset)、[systemd v255管理接口源码](https://raw.githubusercontent.com/systemd/systemd/v255/src/core/dbus-cgroup.c)与[systemd委派说明](https://systemd.io/CGROUP_DELEGATION/)。实际只读结果见[核查记录](../../evidence/aris-core-reservation-20261009/feasibility.json)。
