# 远端管理器高层接口最终补审

2026-10-10。最终管理器SHA-256 `00ba8794453f462d4a398b70692049db8e63dcd886f19c27a74b53159794f1a9`，管理合同`ccb0ec975d52bcbfda5acec69784cdde6604b9114533976d37c284d1fe315fc2`，计划`90ced1f1...`、manifest`c95d924d...`。本文件为新增补审，保留原40b74源码快照、原两项待修意见以及608合同审查原字节。

**原高层审查I1/I2均闭合，新增批次归属修复在本次高层接口范围一致；该限定范围通过。**本代理以原40b74快照对最终源作静态差分，未修改源码/docs、未commit，也未执行真实部署、run_once、C/CTest、SSH、采集或文件删除/替换故障。生命周期完整竞态/信号审查仍由主代理及另一代理的单独意见承担，不由本结论替代。

## I1闭合：接受身份一直保留至冻结

每个accepted case现保存CSV、metadata、analysis和summary的接受SHA及长度，原接受摘要不再被最终观察覆盖。新增`current_output_pin`核对真实物理路径、普通文件、实际长度和摘要；缺失/读取失败给不合格观察。`accepted_pins_match`要求四项完整集合、物理普通状态、类型正确的原长度和精确摘要相同。

最终冻结前，对四输出逐项比较；任何不匹配会记录`accepted_output_pins_unchanged=false`并抛出明确错误，进入`final_pin_failure`，将总状态置failed，随后拒绝manifest/archive。不再出现“原文件缺失置None、state仍completed并冻结新清单”的旧高层缺口。非accepted case的最终可见摘要单列为`current_visible_outputs`，没有覆盖历史接受身份。

这项闭合是静态控制流及纯谓词检查的结论，不称已在Linux真的删除/替换过输出，也不声称任意并发文件系统对手下的原子完整性保证。

## I2闭合：明确生成器

普通/动态configure argv现均带`-G "Unix Makefiles"`，与后续读取固定Make布局的link.txt及合同一致。CMake、collector、analyzer、fixture和固定140源字节没有因此修改；无需为管理argv变更新增密码资格或采样。

## 新增归属门的高层一致性

`batch_directory_owned`初值false；SIGNALS阻塞区间内独占mkdir成功以后才置true并写state标志，随后恢复信号mask。最终阶段首先检查归属；未取得归属时仅取消自身timer、stdout报告failed/withheld_no_batch_ownership并退出1，先于after环境、commands/state/manifest或归档写出。所有子命令启动都在取得归属后，因此该noowner支路不把已有批次当作自己树来收尾写入。

`ownership_allows_freeze`再要求实际bool true归属和原cleanup确认门；false、None及整数1不会被当成已取得归属。这是本次定向接口检查，不扩大为所有内核故障、父目录并发替换或guard恢复保证。

## 唯一新增执行：原纯selfcheck

本代理额外执行一次最终源原`--selfcheck`分支，使用Python的`-B`禁止字节码生成；没有执行run_once。退出0、stderr为空，stdout为`selfcheck=true`，其业务计数real_clock_reads/file_reads/ssh_calls/crypto_calls均0，前后source SHA相同。完整argv/输出/源绑定在`REMOTE_INTERFACE_FINAL_SELFCHECK.json`，SHA-256 `b47e3f66c4e5497907d5eda3cdf362b0726400966d362f161d9923a27a21519d`。

该分支新增检查四文件缺失/physical false/长度和SHA变化的字典负例，以及未取得归属的逻辑负例。它们不是实际文件故障或真实管理进程回收。读源、解释器启动和本地审查回执属于外层行政操作，不把分支的`file_reads=0`扩大为本次审查完全没有读取源文件。

上传辅助源仍为原审查的83777169版本；没有重跑20内存负例，也没有真实上传。最终runner身份将由上传参数和本机Git142字节另绑定，先前runner替身内存正例不冒称验证了此真实runner。原上传审查范围继续保持。

## 保持的边界

E1两配置各五项及六个ELF、E2同ELF零新资格、每批三个50000+1 collector、两批计划300138完整算法/300030decap/600000采样读钟、实际getres、129频率快照、300秒剩余deadline及E1/E2清单语义均无本次增量变化。它们仍是待真实Linux执行和核验的协议，不能由纯selfcheck认领已经完成。

主代理可结合另一代理生命周期审查及真实准备回执固定新部署提交，再按既定合同推进；本报告仅确认本次两项问题及新增归属门的高层闭合。外部同行评审、Linux资格、六次完整采集、结束回收和原值统计仍未由本代理完成，R02/R04保持partial。
