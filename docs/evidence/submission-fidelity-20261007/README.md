# 报告事实限定与历史别名修正核验

客户端日期：2026-10-07；执行者为作者代理。此目录新增本次报告修正的原始核验记录，
不修改已封存candidate v2、candidate-report旧证据、历史原始数据或实际执行账本。

修正仅作用于当前[设计报告DOCX](../../../deliverables/report/待编号-2026密码竞赛复赛作品设计报告.docx)
及[对应PDF](../../../deliverables/report/待编号-2026密码竞赛复赛作品设计报告.pdf)：

- 将N01的UTC 16:18:45–16:19:13明确为主要执行窗口；配置交叉核对于UTC 16:22:32另列，与[原步骤账本](../candidate-round-20261007/native/step-exits.tsv)一致。
- 区分内部保留的运行原件与支撑包`source/docs/evidence/candidate-round-20261007/native`中具转换记录的匿名副本；原数值CSV仍保持，未改统计结果。
- 旧作者复现编号统一为A01，注明旧别名R01，避免与题目要求R01混淆；原历史材料和旧编号记录不回写。

## 实际核验

[文字补丁记录](text-patch-verification.json)保存修正前后全文及实际DOCX摘要：只修改两个
已有段落的文字节点，未重建模板，ZIP内仅`word/document.xml`变化。

[结构核验](structure-verification.json)及[实际输出](structure-verification.log)确认三个
分节和23个模板保护parts原样；239个文字段落角色完整pPr/rPr符合官方模板。相对修正前，
全部非document parts、既有表格和绘图XML逐字不变，内容JSON与正文逐段一致。

[图表及数据核验](chart-and-data-verification.json)与[实际输出](chart-and-data-verification.log)
重新读取当前文件：三页可编辑PPT、两张图、两份工作簿保持；18均值及4成本值匹配C报告，
两份48行原进程账本求和匹配，四张报告数据表18/6/5/6行全部一致。没有新密码采集或防护数据。

[最终渲染原始日志](render-final.log)记录bundled Python与bundled LibreOffice只读转PDF，
继续使用既有`runs/template-fidelity-20261007/fonts.conf`，没有调用用户安装的LibreOffice，
没有用LibreOffice保存DOCX。最终仍为14页，没有缩减字体、字号或行距。
[14页视觉记录](visual-page-review.json)逐页记录PNG摘要；全部PNG以原分辨率打开核对，
未见裁切、覆盖、缺字或错位。PNG位于`runs/submission-fidelity-20261007/render-final`，
交付PDF为该目录PDF的逐字副本，文档渲染不称为实际运行截图。
[PDF字体对象记录](pdf-font-verification.json)确认嵌入字体流，DOCX原字体名保持，不分发字体文件。

本次渲染、文字、结构与数字核验均成功；[本目录摘要](SHA256SUMS)和
[交付目录摘要](../../../deliverables/report/SHA256SUMS)可核对。审批及签字DOCX/PDF未改，
科学证据、R07、真实非原作者、实际截图和本人签署缺口不变。新包的源码/ZIP身份及干净
验收由分发模块另记，此处不预先为新的ZIP签收，也不回填旧v2记录。
