# 阅读措辞修正后的确切补充件独立审查

2026-10-08。结论：**passed_for_exact_reading_precision_final_zip**。逐项依据见 [新核验JSON](review-reading-precision-final.json)，26项检查全部通过。

本次审查针对同一路径下的新ZIP，不把上一候选包的PASS回填到新版本。上一候选的审查文件与JSON保持原字节，其签收对象仍仅为 `a41b58ed328a8d72f94edb9926602d52c9a11d8da2b3356db4a4fac2dba0f485`；该旧候选及旁置资料现在完整保留于 `build/aris-cost-report-20261008/supplement-before-reading-precision`，只作为差分基线。

## 确切版本与差分

| 项目 | 独立核对结果 |
|---|---|
| 当前ZIP | `deliverables/support/CACR2026EA16XZ-aris-cost-20261008/CACR2026EA16XZ-研究报告与数学成本解释补充件.zip` |
| 当前SHA256 | `59b858391d21392e3725e01791b8b877f942599ccce46d323aacc22d109cf9ee` |
| 字节数及条目数 | 15090897字节，594项 |
| CRC、路径、唯一性及闭包 | 全部通过 |
| 与当前载荷逐字节比对 | 594项全部一致 |
| 旁置匿名DOCX、PDF、manifest | 全部与包内对应件一致 |
| 上一a41候选 | 摘要及CRC正确，仍为594项 |
| 两版本差分 | 仅下述4项变化，另外590项全部逐字节相同 |

四个变化条目是 `data/M01_UPDATE_COST/UPDATE_COST_RESULTS.md`、对应 `.html`、`manifest.json` 与 `SHA256SUMS`。两份阅读视图均只包含两处精确的措辞替换，所有数字序列和其余文字保持；manifest只有这两份阅读视图的记录更新，其余590份记录中的材料、报告、原数据、输入、资格、合同及原审查文字均未修改，manifest其他顶层字段也未改变。

592份分发件的摘要与长度全部一致；578项可定位原件的摘要与长度一致，14项仍明确为无原件摘要的生成材料。SHA256SUMS覆盖包含manifest在内的593份文件，全部摘要正确。检查结束时当前和上一候选ZIP摘要仍各自保持。

## 两处措辞的依据

第一处将“main的SOURCE…该提交”改为明确的匿名后台来源别名。新措辞与未变的qualification一致：`SOURCE-MATH-COST-01` 的类型是 `anonymous_background_source_identity_not_git_commit`，新增观察器在运行时未提交。它没有把匿名别名升级为Git号、旧版本包含新增实现的证明、封存身份或外部时间证明。

第二处明确时钟门槛为“时钟分辨率与空窗中位值中较大者的100倍”。冻结合同原文是 `max(标称分辨率,空窗中位值)的100倍`；只读核对的C实现为 `100.0L * fmaxl((long double)context->clock_resolution_ns, empty_median_ns)`。未变的资格摘要记录分辨率1000ns、空窗中位值0、门槛100000ns，原final-state.meta仍记录 `minimum_algorithm_window_ns=100000.000`。这是对既有规则的准确表述，没有重算校准、换门槛或筛选时间记录。

原终态 `artifact_mechanism_review=pending_external`、当前审查的独立范围、未提交来源角色、两个重复全零任务及R02/R04未闭合继续保留。此次措辞没有新增速度、统计有效性、恒时或竞赛完成声明。

## 阅读闭包与审查范围

全部649个本地链接继续可定位，54个外部链接仍为文献引用。22份HTML、116个原生MathML对象保持，没有脚本、事件处理属性、主动嵌入内容或远程运行资源。变化后的阅读视图和manifest没有命中已知项目账号、私有路径或登录地址；另外590项与原已审字节完全相同，包括42页匿名报告及其隐藏属性。

本记录为同模型独立只读差分与包审查。没有执行源码、重算统计、运行实验、调用密码代码或重新渲染；没有编辑载荷、原件或旧审查记录。仅对上述确切新包的字节、阅读和声明闭包签收，不签收完整研究目标、R02/R04、外部时间证明或人员审批。外侧verification可以引用此新记录恢复本包审查状态，不能据此改写包内历史字段或旧a41审查的适用对象。
