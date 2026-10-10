# G2 实际窗口、注册取消与恢复原件

2026-10-10，normal和parent-loss各执行一次，无重跑。研究结果见
[RESULTS](../../../research/aris-frequency-window-20261010/RESULTS.md)，判定范围见
[RESULT_TO_CLAIM](../../../research/aris-frequency-window-20261010/RESULT_TO_CLAIM.md)。

- [完整实际归档](core-window-20261010-51d37af52b90.tar)：30607360字节、87个唯一常规成员，
  SHA-256 `7c902223592dfc0705bfb28c2e7352b42febf15075528091ed9dc45a887c8191`。
- 云端root私有原件在`/home/nss-marker/yhr/Cry/core-window-20261010-51d37af52b90/`，
  同级同名`.tar`为可读导出；[originals](originals/run.json)是本机原字节阅读副本，不改写原档。
- `source.json`的完整冻结源码、两份bootstrap解压内容均为Git0ba4cd7、SHA8616a074。
  两个受保护`worker.bin`均等正式普通Linux ELF023f5646；普通入口执行前的源码、KAT、
  动态检查和管理准备分别在先前c0e及g2-preparation中封存。
- [实际工具返回](tool-results.json)、[实际post源码](root-postcheck-source.py)及
  [便于阅读的post对象](postcheck.json)分别保留原工具字段、执行文本和派生视图。
  SCP完成的外层工具返回没有另行封存；实际完整文件摘要及87份原件一致性已独立核对，
  不用补造的工具回执填补这一记录范围。

normal controller／worker均0，原JSONL29266316字节、126528调用、251快照、1977检查点；
parent-loss controller／worker均-9，guard记录实际运行中注册取消和waitpid回收，输出0字节
明确记作partial_or_unknown。两路径均独立观察guard和worker的pidfd退出，每case各8个
写前intent及8个visible，原请求明确重发并核对全部32策略/global可见原值。

实际root post核对87份私有原件与tar逐字节相同、六个原PID不存在、CPU0—31归还、隔离空、
自有组不存在、锁取得并释放。post先读取snapshot再取锁，故是同次后检观测，不称跨全段
原子快照；运行内observer的完整回读在父端持锁期间完成。隐藏QoS逐位状态不由这些接口证明。

[analysis](analysis/provenance.json)保存固定C程序、实际Mac/ARM离线分析产物和编译参数，
两份原C输出、输入／输出摘要及实际退出状态；不混同Linux采集与本机算术分析。
normal验证0且200个主pair全部通过；parent-loss缺summary被明确拒绝1，不输出统计CSV。
纯主平均窗口几何覆盖99.4948%，剩余缺口和完整失败台账均保留，full-main／物理精度／R02／R04
始终false。

[verify_run.py](verify_run.py)可复核87原件、冻结源、后检视图、C输出绑定及缺口守恒，
结果见[verification.json](verification.json)；它不替代独立的实际配置／pidfd观测。
[行政原件审查](ARTIFACT_REVIEW.md)、[全量科学核对](SCIENTIFIC_REVIEW.md)及
[结果图复核](FIGURE_REVIEW.md)由本地不同代理独立完成，范围各自说明；外部Codex审查仍pending。
图与原C输出一致，不把200窗写成200个独立重复，也不将CPU18的宽context区间当成第二独立样本。

所有实际云端项目文件均在Cry内；原件保留，不覆盖旧证据。主SSH已关闭，见[实际回执](ssh-close.json)。本次并未执行guard自身死亡、
整机故障、真实磁盘耗尽或人工恢复，不扩展恢复保证；R02/R04和完整竞赛验收仍部分完成。
