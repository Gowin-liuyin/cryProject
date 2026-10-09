# G1实机请求与恢复原件

2026-10-10，结果边界见[研究说明](../../../research/aris-frequency-control-20261010/RESULTS.md)。这是空任务预演的新原件，不改写原单核分区证据或准备件。

- `core-frequency-20261010-d05b4396f082.tar`：68唯一常规成员，SHA-256 `3c4951ac57b905b9fa232858f2bf017ef93daaf5f522d8d9a38126e53a7da122`。root私有原件全部逐字节回读一致；`originals/`为同一内容的长期阅读副本。
- `source-991f154.tar`：三项必要冻结源/合同及目录，SHA-256 `51631f225bdcedb44440897d06192d3138dad3baa9b95ff59319fd1d5d7042cd`。原执行源全文、摘要另在 `originals/source.json`，与Git对象991f154相同。
- `linux-check/`：真实Linux CMake/CTest原日志及结果，管理自检1/1、16类通过，无真实频率/cgroup写入。root正式case另行执行，不以软件检查替代。
- `tool-receipts/root-run.*`、`root-postcheck.*`：实际返回字段与原输出；post重新比较32策略/global、六PID终止、根cpuset、锁及68原件/tar相同。`orchestration-source/`保存精确Linux软件及post执行源；post内嵌冻结管理源，仅调用读取/核验，不启动新的管理case。
- [独立实物审查](ARTIFACT_REVIEW.md)、[验证器](verify_run.py)及[结果](verification.json)分别给出独立语义核查和可复核结构检查。SHA清单冻结本目录内容，不能替代实际配置或进程身份读取。

每case均有8个写前intent与8个visible回执：只policy2/18 min/max，四次请求4300000、四次恢复原请求。active完整32策略对象只有四个value字段不同；restored及observer完整对象与baseline相同。pending通过intent/visible链重建归零，不虚构一次内存状态转储。

normal controller0/release，parent-loss controller-9/EOF，两guard均实际pidfd终止。true每次已实际迁入2/18、退出0并被回收，parent-loss在此后触发；不代表长worker取消/整会话终止或guard自身死亡恢复。root-post的六个原PID均不存在，自有cgroup已删除、CPU0—31归还、隔离集合空、锁可取且已释放。

源码/构建/临时/缓存及root原件均在 `/home/nss-marker/yhr/Cry` 及子目录；未创建/run或/tmp项目文件。主连接已关闭，认证内容未写入材料。原值与负面边界均保留：可见恢复不证明隐藏QoS逐位原状或内核work严格排空；请求等值不证明硬件恒频。G1签收，G2和R02/R04不升级。
