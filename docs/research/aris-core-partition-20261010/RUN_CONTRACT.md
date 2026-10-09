# CPU分区管理预演合同

2026-10-10。与[候选方案](CONCEPT.md)同一资源目标，具体实现及结果分别留证。本合同不是正式测量或R02/R04签收。

唯一机器为nss-m、真实Linux6.17/x86_64。仅使用CPU2/18这一物理核的本地isolated分区；其余30个逻辑CPU由根分区保留。所有实际项目文件落盘Cry，内核状态仅经虚拟cgroup接口调整，不新建systemd单位或/run项目文件。

预演只包含两个串行case，各执行一次/usr/bin/true：

1. normal：独立guard就绪，observer取得guard pidfd后才发ARM；probe实际迁入/回读后执行空任务，active后controller发送RELEASE。
2. parent-loss：相同步骤，active后observer对仍为自己未回收子进程的controller发送SIGKILL；guard因寿命pipe EOF恢复。验证范围为controller单进程死亡，不冒称整段SSH会话被杀的实测。

同一guard是唯一内核写者，必须迁出SSH会话cgroup、持有Cry内独占锁，并确认root身份、housekeeping集合和恢复去向。controller、observer及空任务不持有多余寿命pipe写端。ready/active是阶段记录，terminal回执也不能单独证明进程已退出；下一case前须pidfd确认guard终止并独立回读恢复状态。

开始每case前重新核对命名空间、所有相关分区、CPU拓扑、请求集合、root可用及隔离集合，拒绝已有非默认分配或读取缺口。新组使用唯一名字并保存inode；未知成员、子组、身份变化或同期设置改变均停止签收，不能删除或杀死未知对象。只操作自有进程及新组，不写其他服务属性或线程亲和性。

管理等待采用20秒软截止，空任务等待不超过2秒；恢复与观察也须有有限等待，超时留下真实进程句柄和部分状态，不启动替代guard或自动重跑。操作系统阻塞可越过这些软预算，不能宣称硬实时回退。两个case各最多一次实际尝试，失败原件不覆盖。

恢复按自有任务回收、probe退为member、原CPU集合回读及空组删除、guard迁回已确认位置和自有组清理执行。单步失败继续其他安全恢复步骤；最后核对请求设置及原有效CPU。保存root私有快照、日志、冻结源码摘要、实际PID/退出状态、每阶段回读及独立人工恢复入口。

guard自身SIGKILL、OOM、整机故障及其他管理员干预不享有自动恢复保证；人工恢复须先证实原guard和controller终止并取得锁，核对自有组身份，仅处理空组，拒绝未知成员。

不改变频率、boost、SMT、IRQ或持久配置，不运行密码算法、变体或计时。isolated分区仍不消除绑定内核线程、IRQ和共享硬件干扰。成功最多支持这次资源预留及两种恢复路径，不证明锁频、测量精度、统计适用或全项目完成。
