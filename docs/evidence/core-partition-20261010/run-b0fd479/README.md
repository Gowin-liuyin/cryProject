# 单核分区与恢复的真实预演结果

2026-10-10北京时间。机器nss-m、Linux6.17.0-35-generic、x86_64。源码固定b0fd4797d44d5d79cd0aec84b3996cc5473c190a，实际内存冻结SHA256为9a2d926c2df40bc03f0d81195190f256bd208457725e9c7358e854109ed7be10；原始source.json完整字节与该提交源码一致。Linux非root CMake/CTest自检1/1通过。

两个case已真实执行：normal的controller退出0，guard收到release；parent-loss的自有controller被SIGKILL并退出-9，guard收到寿命pipe EOF。两次guard均先迁出SSH到自有housekeeping组，observer在ARM前取得pidfd；空任务在启动屏障后迁入probe，实际可用CPU为2/18，退出0。两次probe均读到有效isolated、排他集合2/18，其余普通分支保留30个逻辑CPU。

两次都恢复根有效CPU0—31、isolated为空，并清除自有guard/probe组；observer记录真实guard pidfd退出，不仅依赖terminal文件。随后独立root只读核查确认四个原guard/controller进程全部不存在、全局锁可取得、自有内核组为空，CPU已归还。32个root私有原文件全部SHA256与取回字节一致，原文件UID0/mode0600。

云端原件根为`/home/nss-marker/yhr/Cry/core-partition-20261010-44fee52e576a`，可读归档为同级同名tar；两份固定源码上传/构建分别为Cry/partition-source-c4bb88a和Cry/partition-source-b0fd479，均保留。全部项目实际落盘都在Cry，只有自有虚拟cgroup资源对象临时建立并已清除，无systemd单位或/run项目文件。SSH连接已关闭，无当前后台预演任务。

首次c4bb入口因CPU列表换行在资源修改前退出，原负结果及独立空状态留在相邻admission-c4bb88a；没有覆盖为成功。新版本补内核文本边界后才完成本次两个case。

本证据最多支持这次一个物理核的普通任务分区和controller单进程死亡后的恢复。没有实际杀整个SSH会话、没有杀guard或模拟OOM/停机，没有实机执行人工恢复入口；这些均不宣称已验证。未配置频率、boost、IRQ，未运行密码、变体、计时或统计确认。IRQ、绑定内核线程和共享硬件干扰仍在，R02/R04仍部分签收。

主要核对入口为original/{normal,parent-loss}中的ready、probe-before-exec、active、terminal和observer记录；[独立回读](independent-readback.json)绑定32份原件摘要，[本地核验](local-verification.json)保留两个退出路径。引导和读取源码单独保存，不包含口令。

独立同模型代理只读复核通过：从Git分别重算b0fd与c4bb源码，32原件和41项清单一致；两个case的时间先后、80普通分支集合、实际退出与恢复证据吻合。代理没有连接远端或运行管理模式；内部独立复核不冒称外部同行评审。
