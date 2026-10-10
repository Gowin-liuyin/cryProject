# 普通参考重复性远端管理准备

2026-10-10，固定两批管理器、140项源清单及142文件上传辅助完成限定独立审查，最终管理源SHA-256为`857d30a018662251cfdba7e9070a5dd1c9aa6132be1f2a86cee7b218a31e6ae7`。纯内存检查通过，真实manager、上传、Linux资格及collector均未执行；本模块新增完整密码算法调用为0。之前Mac普通/动态各4/4及132次功能算法调用属于[采集工具准备](../preparation/README.md)，不再计入本模块或冒充Linux结果。

[管理合同](REMOTE_CONTRACT.md)与[实际管理源](remote_run.py)固定E1两配置各五项CTest、六ELF及三collector，E2核对E1旧快照/source/同boot/六ELF后复用普通产物、再三collector，不重复编译或资格。300秒软预算从管理入口计入前置核验，并以剩余量约束每条命令；每collector15秒加2秒强制结束、管理最多20秒，清理未确认不冻结清单/归档。只用Cry物理子目录及普通用户自身设置，环境/缓存纳入新树、HOME保留，Linux动态仅ASan/UBSan、detect_leaks=0，不声称LSan。

## 原问题与修复

初版`40b74f05…`的[深入审查](REMOTE_STATIC_REVIEW.md)要求修复两项：未取得批次目录归属的调用仍可能写另一运行的收尾文件；封存前把已经接受的原值摘要改为当前值，且未复核分析表/摘要。另[高层审查](REMOTE_INTERFACE_REVIEW.md)要求显式固定生成器。原代码快照和评语保持，不追改为当时已通过。

修复版`00ba8794…`在信号屏蔽区独占mkdir成功后才取得归属，未取得归属只回传失败、不写batch或归档；四份accepted原件的长度和SHA保留，终检须物理普通文件且身份不变，否则禁止manifest/tar；配置显式Unix Makefiles。见[深入最终复审](REMOTE_FINAL_REVIEW.md)及[高层最终复审](REMOTE_INTERFACE_FINAL_REVIEW.md)。随后`857d30a0…`仅把前置核验移入同一预算起点，timer使用剩余量，前置已耗尽时在mkdir/child之前停止，见[预算增量审查](REMOTE_BUDGET_FINAL_REVIEW.md)。所有修复均在上传前，没有增加采集次数。

这些是静态与纯逻辑审查，不冒称真实并发、信号、文件损坏或Linux恢复演练。软期限也不是阻塞文件系统调用的硬实时保证；SSH观察超时不等于实际工作终止。未知状态、回收核对及原件保全的运行资格仍须真实执行证明。

## 上传载体和证据入口

[SOURCE_MANIFEST.json](SOURCE_MANIFEST.json)固定140个源/库/测试/向量/配置/计划，SHA-256为`c95d924d31e0c085724f89a97c5808c7706bcae22ec1bd683c5b45b8495f6552`；加清单自身及管理器共142文件，避免自引用。[候选tar](source-candidate-857d30a0.tar)为2140160字节，SHA-256为`2b5378377c012c291412e7e022bd142de24419e4843d7877b75c6a71faba53a2`，142安全唯一普通成员与各源字节核对一致。[候选绑定](source-candidate-857d30a0.json)明确仍需提交后Git逐字绑定，尚未上传；不能拿候选包当远端成功回执。

| 对象 | 原件 |
|---|---|
| 初版合同审查 | [意见](REMOTE_CONTRACT_REVIEW.md)、[绑定](REMOTE_CONTRACT_REVIEW.json)，对应原合同6082289a时点；后续两操作口径已补入当前合同ccb0ec97 |
| 初版深入审查与源码 | [报告](REMOTE_STATIC_REVIEW.md)、[JSON](REMOTE_STATIC_REVIEW.json)、[40b74原快照](remote_run-reviewed-initial.py) |
| 修复后深入复审 | [报告](REMOTE_FINAL_REVIEW.md)、[JSON](REMOTE_FINAL_REVIEW.json)、[00ba原快照](remote_run-reviewed-00ba8794.py) |
| 最终预算增量 | [报告](REMOTE_BUDGET_FINAL_REVIEW.md)、[JSON](REMOTE_BUDGET_FINAL_REVIEW.json) |
| 高层接口原审/补审 | [原审](REMOTE_INTERFACE_REVIEW.md)、[原绑定](REMOTE_INTERFACE_REVIEW.json)、[最终补审](REMOTE_INTERFACE_FINAL_REVIEW.md)、[最终绑定](REMOTE_INTERFACE_FINAL_REVIEW.json)、[一次00ba纯自检回执](REMOTE_INTERFACE_FINAL_SELFCHECK.json) |
| 上传辅助 | [helper](upload-helper.py)、[限定审查](UPLOAD_REVIEW.md)、[JSON](UPLOAD_REVIEW.json)、[20内存负例](UPLOAD_MEMORY_CHECKS.json) |
| 本地准备范围与最终源 | [PREPARATION_VERIFICATION](PREPARATION_VERIFICATION.json)、[SHA256SUMS](SHA256SUMS) |

上传helper先完整检查不超过8MiB的载体摘要、142唯一普通路径、固定140项长度/SHA和管理器摘要，再独占创建Cry内carrier/root，逐项写后复核，不使用extractall。原AST的纯内存验证段正例及20负例通过；测试使用明确runner替身，不执行stdin、物理路径探测、mkdir/open写入或SSH。两次测试架子准备错误及修复记录保留，不冒称真实上传或抗并发路径替换证明。

作者报告四次开发纯自检（初版两次、修复两次，其中作者最新为00ba）；独立深入审查实际执行初版/00ba各一次，高层补审实际执行00ba一次，根实际执行00ba及最终857各一次。版本和直接观察范围在原回执与PREPARATION_VERIFICATION中分别说明，不把作者handoff当独立执行，也不把旧版检查自动继承给新版本。预算增量另核五个纯数值边界，未重复真实manager。纯自检“零文件/时钟/算法”指其业务逻辑，不含解释器装载程序的固有活动。

审查均为同模型内部代理；外部Codex MCP不可用，保持pending。E1归档必须先由本机下载核验、结束回收并实际断连重认才启动E2；E2当前manifest做全树覆盖，旧E1清单只核旧快照字节。真实Linux及全部原值复核尚待，R02/R04不签收，旧证据和封存包不改写。
