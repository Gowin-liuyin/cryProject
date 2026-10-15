# S3 管理器审计与软件检查

日期：2026-10-16。真实频率写入/空任务资格/密码采数均未执行。

图谱 `cryProject_audit_20261015` 对 frequency/restore/lock 仅返回 `src/v4_window.c` 的读取函数，不含管理脚本；按约定回退读取脚本/config。只读审计 M1 20261015 的 `run-locked-31337.sh` 和 20261010 的 `rehearse_partition.py`，不修改或复跑旧原件。

旧 M1 脚本不直接复用的理由：没有共用 flock；只注册 EXIT trap，不能覆盖 controller 单进程 SIGKILL；恢复前先置 restored=1；没有 worker 组 deadline/回收；由用户目录中的 Python 恢复文件配合环境口令执行；频率失败时会重新选择目标。新入口不沿用口令环境变量或自动重新选频。

新管理器采用寿命pipe、独立 root guardian、降权独立组 worker、共同锁、root恢复原件、写前持久化intent、原值重发、全快照restore_match和跨运行active阻断。内部第二路只读审计发现并已修正：继承 SIGCHLD=SIG_IGN 会破坏未回收leader前提；恢复顺序的首次max读取异常会短路其余字段；recover须核对root原件/NOFOLLOW/目录身份；恢复失败后必须有跨控制根阻断，不能把残留值当新baseline；worker启动前须持久化spawn意图，若guard死亡留下“可能启动但未登记身份”，recover拒绝清除active，不能把缺worker.json当作无worker。

本机 macOS/ARM、Python3.13，独立CMake/CTest当前1/1通过。9组模拟：正常设置/恢复；第二次写已生效但报错；恢复一个字段报错而继续其余字段；未知并发值拒绝覆盖；恢复顺序首次读失败仍恢复其他字段；日志满仍重发原请求但不签成功；寿命取消发生于首写之前；证据拒绝覆盖；单独子进程组TERM及继承SIGCHLD恢复检查。全部模拟主机频率写入为0。

上述测试不证明Linux root可信目录、真实guardian寿命、真实taskset、实际频率回读或跨会话恢复，均待 `PLAN.md` 冻结后的真实空任务资格。guardian自身SIGKILL/OOM/主机故障与SSH会话cgroup整体清理明确不享自动恢复承诺；worker只能是已审的不fork原生C入口。M1旧结论及旧证据未更动。
