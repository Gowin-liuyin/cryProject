# G1频率请求与恢复的实机结果

2026-10-10。G1空任务两条注册路径实际通过，原件与独立核验见[执行记录](../../evidence/frequency-control-20261010/run-991f154/README.md)。该结果关闭本轮可见请求及恢复前置项；G2长工作进程和频率窗口没有执行，R02/R04仍部分签收。

冻结源提交 `991f1546c7ee3a7999d6e0b7118d35211a501dfe`，单文件SHA-256 `b7057c2af9a32ac93491815756eaaf0d964745f56ef4f9c05b59c84ba36c7661`。源码沿用同一guard、寿命pipe、pidfd、root私有Store和管理锁，默认run范围保持；新run-frequency只写两个目标策略的min/max。Mac与真实Linux各一项管理自检通过，包含16类检查。初版独立审查发现的异步pending取消、取消失败不得发布restored、manual核对probe终止均在实际执行前修正。

| 实际case | active可见请求 | controller与guard观察 | 结束核对 |
|---|---|---|---|
| normal | policy2/18四字段均4300000kHz，其他30策略及global不变；true已归属2/18并退出0 | controller退出0；reason=release；observer见guard pidfd终止 | 八次dirty intent及八次visible回执，四次申请、四次明确重发原请求；完整32策略/global等于基线 |
| parent-loss | 同一可见请求与已回收true | observer只杀自己的controller，退出-9；guard reason=controller_eof；pidfd终止 | 同样八次intent/visible，原请求撤销链闭合、完整配置恢复 |

parent-loss发生于true已经回收之后，不证明运行中长worker或整段SSH会话终止的恢复。guard自身SIGKILL/OOM、断电也不在实测范围；manual恢复仅有软件覆盖，未伪造一次人工实机执行。

独立root结束读取重新比较全部32策略/global与两case基线，并核对六个原PID均不存在、根CPU0—31可用、隔离集合为空、自有组不存在、锁可取得并释放。68份root原件逐字节等于可读tar，本机取得的tar摘要也相同：`3c4951ac57b905b9fa232858f2bf017ef93daaf5f522d8d9a38126e53a7da122`。完整快照已在observer/恢复原件保存；post工具输出是实际比较结果，不冒称另一次全量policy转储。

当前目标可见范围回到2982259—5756452kHz，active/powersave/EPP balance_performance/boost保持。只证明原请求已明确重发、可见配置在结束核验时恢复；不证明隐藏QoS初始请求逐位相同、内核work严格排空、固件状态全部复原或硬件恒频。系统工作仍可能与不守管理锁的管理员产生不可原子化的竞争。

新增云端内容全部在Cry：源码/软件检查为 `frequency-source-991f154/`，root私有原件为 `core-frequency-20261010-d05b4396f082/`，可读tar为同级同名文件。两case结束后没有继续占用独立核心，SSH主连接已关闭；临时/缓存路径在源码树内，原件保留。

后续工具已另以冻结 `7e93048` 候选在Linux完成纯软件编译及检查，见[窗口工具Linux软件记录](../../evidence/frequency-window-20261010/linux-7e93048/README.md)。该检查没有调用普通采集入口或读取MSR。下一步须补长worker运行时EOF/取消/期限与先回收再恢复的衔接合同，再用事前工程窗口规则获取新原值；本次不以空任务的等值请求回读替代它。
