# G2 结果到主张

2026-10-10，依据[冻结合同](EXPERIMENT_PLAN.md)、[实际原件](../../evidence/frequency-window-20261010/run-0ba4cd7/README.md)
及[独立全量科学核对](../../evidence/frequency-window-20261010/run-0ba4cd7/SCIENTIFIC_REVIEW.md)。
采用ARIS result-to-claim；外部Codex MCP未提供，状态为 **[pending Codex review]**。
下述判断由主线程和本地独立代理基于同一原件完成，不冒称外部或跨模型审查。

- **claim_supported：yes（仅窄工程声明）；完整研究：partial。**
- **what_results_support：** 固定普通reference负载在指定裸金属上完成一次采集；200个CPU2
  主观察pair的条件读取对齐区间与事前工程规则全部通过。另一次注册运行中controller丢失
  实际触发EOF、child终止回收，两个case的配置可见恢复、进程退出及原件保全均可独立核查。
- **what_results_dont_support：** 几何覆盖只为3981985286/4002203951ns，且平均窗口不能推出
  区间内逐时或逐调用恒频。4300MHz是固件来源标尺，区间不是CI或完整物理误差界。
  单进程200窗不是200个独立重复；CPU18宽context区间不是第二样本或真实高频证据。
  中断输出为空不等于零调用。R02/R04、真实密文总体和漏洞可利用性均未由本次签收。
- **missing_evidence：** 短调用时钟精度、物理标尺校准及适用稳定性；真实统计目标、独立真值、
  事前容许界、功效和有效赋值／依赖条件；guard自身死亡及人工恢复的真实验证；KVM身份核验
  迁移与真人提交材料。软件ENOSPC替身不替代真实磁盘故障验证。
- **suggested_claim_revision：** “在指定机器、固定普通参考负载的一次4秒主观察中，全部200个
  观测窗口满足预先规定的反馈工程诊断；纯主平均窗口的几何覆盖为99.4948%。注册取消及
  可见资源恢复另有真实路径证据。” 保留单次、条件区间及未覆盖范围，不写恒时或完整验收。
- **next_experiments_needed：** 不因本次工程结果良好追加同类窗口。只有在新的明确科学问题、
  适用精度／统计门槛及完整事前预算确定后，才进入相应后续验证；现有数据不改作A/B、
  真实总体或SILENT适用性证据。先把新证据及限制整合进报告，保持R02/R04 partial。
- **confidence：high（原件一致性、此次执行及窄工程判定）；更宽推广未获证据。**
