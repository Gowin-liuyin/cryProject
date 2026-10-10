# G2 实际采集、取消与恢复原件独立复核

2026-10-10。结论：这次注册的 normal 完成采集、parent-loss 活进程取消和两次可见配置恢复均有一致的实际原件支持，行政与生命周期子项通过。真实频率带、窗口覆盖及科学主张由后续离线分析另行审查，本复核没有将执行成功升级为恒频或 R02/R04 完成。

本次仅在本机读取实际 tar、originals、工具返回、SOURCE_TEXT 与 Git 对象，在内存中解析、重算和比较。没有 SSH、运行 ELF、重跑密码负载、改写原数据或修改先前封存材料；只新增本报告。

## 来源、原档和保护副本

`core-window-20261010-51d37af52b90.tar` 实际为 30607360 字节，重算 SHA-256 为 `7c902223592dfc0705bfb28c2e7352b42febf15075528091ed9dc45a887c8191`。87 个成员均为唯一常规文件，无绝对或上级路径成分；逐项实际长度与 tar 头相同。本机 originals 文件集合恰为这 87 项，全部逐字节相同，不只是与一个清单旗标比较。

source.json 内完整源重算为 `8616a0747d7a8e3b28e5af6da86bfdee5b2bf2f84821989c163136ec09479af4`，与 Git `0ba4cd7` 中已独立审查的管理源对象逐字节相同。分别对 root-execution-bootstrap.py 与 root-postcheck-source.py 内的压缩 SOURCE_TEXT 作有界解码，两份都等于同一完整源；未执行这两份程序。执行 bootstrap 明确固定 run-window，实际主执行工具退出 0。

两个 case 的 worker.bin 都与固定 c0e5990 普通 Linux ELF 摘要 `023f56460a8dc4971e8132a22c5734ca0844314d3d71b8bc3b129a424e9ee69b` 相同。worker-binary、probe-before-exec、worker-ready、observer-worker 的执行对象与身份关联一致；root 后检源码还逐份核对原件为 root 常规文件、保护 ELF 为 0500、字节摘要相同。这里比较内容及已记录身份，不把归档头的保存权限冒称为原文件全部元数据的逐位副本。

## 两条实际路径

| case | controller PID／退出 | guard PID | worker PID／退出 | 实际结束 |
| --- | --- | --- | --- | --- |
| normal | 3666381／0 | 3666382 | 3666393／0 | 完成、回收后 release |
| parent-loss | 3666404／−9 | 3666405 | 3666414／−9 | 活进程 controller_eof、kill/reap |

两 case 的 observer 均记录 ARM 前已打开 guard pidfd、W 前已打开 worker pidfd；guard/worker 的 PID 与 ticks 在对应记录间一致。worker-ready 与 probe-before-exec 相同，均在本 nonce 的 probe 中且亲和性仅 CPU2。running 记录包含正确保护 ELF 的执行对象、实际执行观察及当时未退出的确认，没有仅拿 started 文件当作存活证据。

normal 的 worker-exit 为 reaped=true、exit=0、measurement_complete=true、data_role=complete；对应 terminal 的 worker 字段与它一致，reason=release。parent-loss 的 observer-cancel 距本次 worker-released 单调时刻为约 0.255407 秒，满足注册的 0.25 秒；worker-exit 为 −9、reaped=true、cancel_while_running=true、registered_cancel=true，terminal reason=controller_eof。此故障路径确实覆盖已放行的活进程取消，不是先前 true 回收后的空任务 EOF，也没有把自然退出竞态当作成功。

两 case 均有 guard_pidfd_exit_observed=true 和 worker_pidfd_exit_observed=true；terminal 与 observer 均 success=true，terminal 与 worker 均 evidence_complete=true，行政与恢复错误列表为空。guard/controller 日志和 worker stderr 均为空。源码中的实际 waitpid 回收先于恢复；observer 又独立观察同一 worker pidfd 终止，没有只凭恢复回执断言 child 已死亡。

## 输出原件的完整性

normal stdout 为 29266316 字节，独立重算 SHA-256 `c29a9ca0e28ffad53aaeb0e0c0097fd560d048f5eee4803885cb56850a989028`，与 worker-exit 和 root 后检记录一致。逐行解析并只核计记录类型：1 contract、2 device、8 public_input、251 snapshot、1977 checkpoint、126528 decap、1 summary；三类主记录数量与末尾 summary 完全一致。summary 为 completed、valid_final_snapshot=true。这里核查保存与完成包络，没有替代独立 C 分析器的全协议验证、读取对齐区间或频率分类。

parent-loss stdout/stderr 均为 0 字节，measurement_complete=false、data_role=partial_or_unknown、summary=null。该进程采用后置缓冲输出，取消后没有保存缓冲区内容；0 字节不等于执行了零次调用，也不证明进入或没有进入主观察。不得重建或补造它的调用数、计数快照、测量值或阶段证据。

## 请求、撤销与可见恢复

每 case 的完整 active.frequency 相对 frequency-baseline 只有 policy2/18 的四个 min/max value 改为 4300000 kHz；其他 30 策略、global、目标非写入字段及各属性身份相同。预存恢复 plan 的 case 路径、profile、baseline 摘要及原值对应本次真实目录。

每 case 恰有八份连续 dirty intent 和八份匹配 visible 收据。独立重建其 before_pair→after_pair 链：policy2/18 依次 min=target、max=target，然后各自 min=2982259、max=5756452。仅四个注册字段出现写意图；按固定源语义从原值确认收据重建 pending，两个集合均归零。没有 unlogged 恢复收据，实际 evidence_complete=true，本次没有将缺盘例外或不完整恢复包装成完整成功。

每 case 的 frequency-restored 完整 snapshot 以及独立 observer.frequency_readback 都与自己的 baseline 完整对象相同，覆盖全部 32 策略、global、CPU links 和属性身份。根 effective 回读均为 CPU0—31、isolated=[]，自有 cgroup 已移除；这些是可见配置恢复，不是隐藏 QoS 状态或内核工作排空的证明。

## 实际 root 后检

直接核读实际 postcheck 工具退出 0 的原输出，解析所得对象与 postcheck.json 相同。六个原 controller/guard/worker 的 PID 和 ticks 逐项关联到 tar，实际均记录 absent，未把 PID 复用或仅“已终止”分支冒称不存在。root 后检还记录 87 份 root 私有原件与 tar 相同、同一完整 tar 摘要、两 case 全 32 策略/global 等于基线、根 CPU0—31、隔离空、自有组不存在、管理锁已取得释放。

已独立读其检查源码，相关通过旗标确实在全对象比较、文件集合/字节/身份检查及 pidfd 核查之后生成。该后检先取 cgroup/frequency snapshot，再取得管理锁，因此这些是同次后检的独立观测，不称跨整段原子快照；运行内的 observer 完整结束回读另在父端持锁期间完成。以上均不代表后续远端状态的持续监控，本复核没有重新连接检查当前主机。

可以签收的是这次固定普通产物的实际输出保全、注册活进程取消、自己的进程终止及两次可见资源恢复。normal 的频率带与覆盖、科学有效性、每次短调用恒频、真实密文总体统计以及 R02/R04 完成仍未由本行政复核证明；不因后续频率结果追加或筛选这两次运行。
