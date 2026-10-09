# 频率控制执行跟踪

| 编号 | 必做对象 | 当前状态 | 证据入口 |
|---|---|---|---|
| G00 | 真实资源与32策略只读预检 | 实际成功，无频率写入 | 本轮preflight原值待归档 |
| G01 | 新频率helper及部分失败恢复软件检查 | 本机和Linux各1/1、16类，独立审查通过 | [固定源及原日志](../../evidence/frequency-control-20261010/preparation/README.md) |
| G02 | normal可见请求及恢复 | 实机controller0/release，两目标四字段4300000、全32恢复 | [68原件及独立回读](RESULTS.md) |
| G03 | controller单进程SIGKILL后的EOF恢复 | 实机controller-9/EOF；true先已回收，完整恢复与guard终止 | [同次原件](RESULTS.md)，不冒称guard死亡恢复 |
| G04 | 普通reference缓冲窗口工具 | Mac/Linux普通/动态各2/2、原源/ELF独立核对；普通入口未运行 | [真实Linux软件记录](../../evidence/frequency-window-20261010/linux-7e93048/README.md) |
| G05 | 长worker生命周期衔接及G2真实窗口 | 未执行，需G1通过和衔接复核 | 后续另定冻结执行合同 |

工程预演、普通负载观察、正式统计与竞赛验收分别登记。R02/R04保持部分签收。
