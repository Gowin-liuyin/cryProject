# 术语及引文核对

2026-10-11。依据用户要求，对旧稿中的工程简称和不直观表达作全文修改。中文表述采用通行概念并解释含义；下表不声称每个中文译名都是原文给出的唯一译法。没有公认专名的内容使用普通中文描述。

| 旧表述或易混淆内容 | 修订处理 | 权威来源与核对范围 |
|---|---|---|
| 恒时等于每次读数一样 | 常数时间是秘密与可观察执行行为之间的性质；测量波动另论 | [Almeida等，USENIX Security 2016](https://www.usenix.org/conference/usenixsecurity16/technical-sessions/presentation/almeida)，会议原站及论文 |
| 数据资格、统计资格 | 分别写数据完整性检查与统计适用条件，不包装成新统计术语 | [Hemerik与Goeman，TEST 2018](https://link.springer.com/article/10.1007/s11749-017-0571-1)，期刊全文中的变换群及分布不变性 |
| 精确复算 | 数学方法写精确置换检验；重新生成归档结果写结果复现 | TEST论文；[Stodden等，Science 2016](https://www.stodden.net/papers/ERCM2016-STODDEN.pdf)，作者保存的出版全文 |
| 弱均值 | 目标写平均时间差；假设写弱零假设；标准化写学生化并解释 | [Wu与Ding，JASA 2021](https://www.tandfonline.com/doi/abs/10.1080/01621459.2020.1750415?needAccess=true)，出版社摘要及[作者文章公开本](https://par.nsf.gov/servlets/purl/10167780) |
| 反事实主导比例 | 潜在结果采用既有术语；η直接解释为最大平方项占总和的比例，不另造专名 | [Imai，Statistics in Medicine 2008](https://imai.fas.harvard.edu/research/files/matched-pair.pdf)，作者保存的出版全文 |
| 成本边界 | 写计时范围，说明包含和不包含哪些步骤 | [Kalibera与Jones，ISMM 2013](https://kar.kent.ac.uk/33611/45/p63-kaliber.pdf)，作者存档修订版；页码63–74由原件确认 |
| 重复调用等于独立实验 | 分开说明调用、进程和构建的重复层次 | ISMM 2013原文；不声称本作品已完整实施其精度分配方法 |
| 运行变化均归因算法 | 讨论实验设置造成的测量偏差及比较混杂 | [Mytkowicz等，ASPLOS 2009](https://sape.inf.usi.ch/publications/asplos09.html)，作者研究组摘要及书目信息 |
| MAD未解释 | 中位数绝对偏差；明确本文不乘正态一致性系数，偶数按上中位数 | [Rousseeuw与Croux，JASA 1993](https://wis.kuleuven.be/stat/robust/papers/publications-1993/rousseeuwcroux-alternativestomedianad-jasa-1993.pdf)，作者机构保存的出版论文；不把本文取值约定冒称该文唯一约定 |
| 后赋标签控制 | 固定时间记录的置换检验校验；明确随机性来自采集后标签 | TEST方法说明；没有改称具有额外假设与用途的条件随机化检验，也不改变旧数据的产生机制 |
| 几何覆盖、主pair | 观测窗口覆盖率、相邻快照区间；用文字明确定义计算量 | 本研究的直接描述指标，不冠以文献不存在的方法名称，不与置信覆盖率混同 |
| SciPy函数名称充当正文方法 | 正文使用统计方法名，软件引用改为正式期刊论文 | [Virtanen等，Nature Methods 2020](https://www.nature.com/articles/s41592-019-0686-2)及[官方引用说明](https://scipy.org/citing-scipy/)，实际实验版本仍记1.16.3；并不称2020文章已定义后续版本的具体置换接口 |

参考文献[3]补齐DATE 2017正式论文、页码和DOI，作者论文列表及机构出版库确认；[22]补充Mann–Whitney原论文书目。Project Euclid正文下载在本轮不可用，故不声称本轮完成该文全文审读；原稿已使用的秩检验定义和数值未变。新增引文均用于方法与术语，不把文献保证直接套给本作品未验证的实际前提。

原[1]标准、[2]固定软件说明和[15]内核资料仍用于明确被测实现或计数解释。[7]及[16]维持原预印本身份，不冒充正式会议期刊，也不以它们建立新造中文术语。有限样本界保留原推导及其条件，没有改变理论常数或增加认证声明。
