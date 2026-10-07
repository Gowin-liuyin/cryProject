# 防护前后资料审计与R07缺口

本轮核验日期：2026-10-07。只读检查仓库已有历史防御材料，不重新采集时序、不补填事前
声明，不改封存原件。此记录配合[稳定结论索引](../deliverables/demo/evidence-index.md)H01使用。

## 已取得的材料与身份

| 材料 | 源码、产物和环境身份 | 实际支持范围 |
|---|---|---|
| 单次历史前后对照 | `e8f55e763dbec41801a8d7c1e9fd4e10477ee816`；[编译命令](evidence/mitigation/compile_commands.json)、[产物摘要](evidence/mitigation/binaries.sha256)；Apple M5/ARM64、Darwin25.6.0、Clang21、Ninja、RelWithDebInfo；meta仅有整批保存时Unix秒，实际采集起止UTC缺失 | 同一历史配置的人工消息编码回归与掩码对照；不是新上游漏洞修复 |
| 多种子历史前后 | `268bab838d5cf8a4b0c9c8b6f5f8b144557de219`；[编译命令](evidence/statistics-multiseed/compile_commands.json)、[产物摘要](evidence/statistics-multiseed/binaries.sha256)及各CSV/meta；同一Apple M5平台，1000ns标称时钟分辨率，无亲和性/频率控制 | 20个预定运行，各25000记录；固定密钥下恒定消息组反复两个密文，记录数不等于独立密码样本数 |
| 功能与归档重放 | [历史功能检查](evidence/mitigation/ctest.log)、[多种子功能检查](evidence/statistics-multiseed/ctest.log)、[40份只读重放](evidence/defensive-case-20261007/replay-40-reports.log) | 独立向量、差分及隐式拒绝功能保持；归档报告可按原模型复算，作者代理执行 |
| 新Linux静态与普通性能E02 | `0e8be6df6a0aafeb465f848dcd963505142fa96f`；[环境/产物](evidence/native-final-20261007/artifact-and-environment.log)、[编译命令](evidence/native-final-20261007/compile_commands.json)、[普通运行账本](evidence/native-final-20261007/performance/attempts.tsv)；Ubuntu24.04.4/x86_64、4vCPU KVM | 18次三形态普通测量及真实Linux产物核验；没有人工回归时序，不能与旧ARM数据拼成防护前后 |

旧单次对照的[原始回归CSV](evidence/mitigation/vulnerable.csv)及[掩码CSV](evidence/mitigation/hardened.csv)
各有其[回归meta](evidence/mitigation/vulnerable.meta)/[掩码meta](evidence/mitigation/hardened.meta)、
[回归报告](evidence/mitigation/vulnerable.report)/[掩码报告](evidence/mitigation/hardened.report)。
来源、补丁及数学语义见[历史案例](defensive-case.md)、[定位边界](defect.md)、
[掩码补丁](patches/message-constant-time.patch)、[值屏障补丁](patches/message-value-barrier.patch)。
上游固定实现目标原本无分支，人工回归及两个对照不能称新发现或新修复的上游漏洞。

## 成功、失败与残差并列

| 原模型下的观察 | 数据入口 | 解释限制 |
|---|---|---|
| 单次历史族：人工回归6/10显著，掩码0/10显著，参考0/10显著 | [单次回归报告](evidence/mitigation/vulnerable.report)、[单次掩码报告](evidence/mitigation/hardened.report) | 单比较1e-4；“不显著”不能替代恒时证明，旧归因措辞以统计审计更正为准 |
| 多种子H1：人工回归仅4/5显著，31337未成立 | [31337原报告](evidence/statistics-multiseed/vulnerable-seed31337.report)、[全表](evidence/statistics-multiseed/multiseed-summary.tsv) | 全0与全1主假设没有稳定通过，不用H2较宽阈值替代H1 |
| 多种子H2：人工回归5/5显著，均值差约−663至−776ns；参考与正常优化各5/5未检出 | [回归H2](evidence/statistics-multiseed/vulnerable-seed31337.groups.report)、[全表](evidence/statistics-multiseed/multiseed-summary.tsv) | H2单比较1e-3；既有机制统计量，不是未知密钥攻击成功率 |
| 掩码H2：4/5未检出、1/5显著；五次均值差约−30至−13ns，方向一致 | [141421356原CSV](evidence/statistics-multiseed/hardened-seed141421356.csv)、[meta](evidence/statistics-multiseed/hardened-seed141421356.meta)、[H2报告](evidence/statistics-multiseed/hardened-seed141421356.groups.report) | 显著残差p=1.42602e-05、优势概率effect_size_first_greater=0.488950（非Cliff差）；没有受控机制归因，不能隐藏或写成归零 |

人工回归H2部分p字段为0来自数值下溢，不能读成精确零。完整原分布在各CSV中保留；
当前展示不新造示意分布、合成防护效果图或用E02普通性能图替代防护效果图。
历史分析方法和单位说明见[统计审计](statistical-audit.md)，原假设及冻结顺序见
[四模块设计](tasks/four-module-design.md)。本地提交只证明作者仓库内顺序，无第三方时间凭证。

## 必要前提的核验结果

| 条件 | 现有材料判断 | 未闭合部分 |
|---|---|---|
| 实际运行与身份 | 原始CSV、meta自报源/产物及编译记录可对照；封存摘要、后续逐字复算有记录 | 完整历史所有尝试及逐步外部退出凭证不齐；来源链不是独立人员签收 |
| 同一或等价环境 | 历史前后声明同机同构建，输入类别顺序相同 | 相同顺序不证明缓存、预测器、调度/频率相同；新的受控因果分离和充分环境等价依据缺失 |
| 输入/样本/方法 | 白盒公开种子、两个重复恒定密文、原两族阈值明确，长尾保留 | 并列修正不能消除序列依赖；真实密码总体的模型资格未证明 |
| 功能保持 | 独立向量/隐式拒绝/差分记录存在，新工程另有功能回归 | 新工程功能通过不能替历史防护时间补充新产物安全结论 |
| 计划、成本和失败 | 原模块零、H1失败、掩码残差、批次准备失败及共同预算保留 | 历史成本和未归档动机值有明确缺失，不能补成新完整事前确认 |
| 结论范围 | 原模型名义观察可复算，源码秘密依赖与产物形态分别解释 | 尚无新的完整受控防护效果链；R07继续部分签收 |

C02有限合成模型、C04后赋标签控制及E02普通性能各保持原用途。它们分别支持模型内数值
核验、固定时间上的条件标签控制和普通负载成本，不能替代真实防护前后分布或关闭R07。

## 可接受的缺口材料清单

项目组补证时需提供已授权取得的真实材料，而非仅一张结果图：

1. 前后完整源码/独立补丁与许可证、固定构建条件、实际二进制摘要及后端身份；两个对象保持
   同一标准密码语义和隐式拒绝，功能检查使用独立公开向量。
2. 同一或充分说明等价的实际环境、分配资源、虚拟化、可控与不可控条件；真实时间、执行者
   身份类别、命令及全部退出状态，动态检查产物与正式产物分离。
3. 输入类别依据、密钥/密文/运行/单次记录的样本单位、完整原始分布、未删长尾及数据摘要。
4. 可追溯的原计划、方法/阈值、执行顺序、成本窗口、预算、失败和停止记录；不得给旧数据
   新补一份事前声明后称新确认。
5. 合适模型下的效应量、统计结果、前后分布和性能代价，可从原始文件复算；未达到预期、
   不可识别、残差与不适用条件一起呈现，并说明能支持哪一级结论。

本轮没有这些新材料，因此没有新增防护时序或秘密归因结论。资料缺口只阻止依赖它的验收，
其他功能、产物、普通性能、只读复算和交付工作继续进行。
