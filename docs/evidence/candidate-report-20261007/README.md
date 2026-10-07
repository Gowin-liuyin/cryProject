# 本轮候选官方报告同步核验 D02

客户端日历：2026-10-07。操作者为作者代理；没有新增时序漏洞实验或真人签署。

实际交付为[设计报告 DOCX](../../../deliverables/report/待编号-2026密码竞赛复赛作品设计报告.docx)
及[对应 PDF](../../../deliverables/report/待编号-2026密码竞赛复赛作品设计报告.pdf)。本轮正文补充
U01/D01公开来源与固定适用性、DEF-F01构建记录修正及[N01/A02服务器核验](../candidate-round-20261007/README.md)，
单列新普通性能，仍按旧E02/C01—C04数据解释原图表。没有回填历史34项记录或重开已停止批次。

## 结构、数字和视觉结果

- [文本补丁与包保护核验](text-patch-verification.json)：仅`word/document.xml`变化；上一已核报告所有其他part、既有表格和绘图XML保持。
- [模板结构核验](structure-verification.json)：原三分节及23个保护parts逐字相同；239个正文/表中文字角色的完整pPr/rPr符合原模板，既有表注和文献对齐扩展保持。报告与内容JSON逐段一致。
- [图表与原始数据核验](chart-and-data-verification.json)：三页原生可编辑PPT、两张原生数据图、两份内嵌工作簿；18个均值、4个成本值与22项缓存/工作簿数据一致。两份48行进程账本求和匹配C01/C03。报告四张数据表分别18/6/5/6行全部匹配C报告。[实际检查输出](chart-and-data-verification.log)。
- [全部页面视觉记录](visual-page-review.json)：最终渲染14页，每页PNG以原分辨率打开；未见裁切、覆盖、缺字或错位。比先前13页自然增加1页，没有缩字体、字号或行距。PNG属于文档渲染检查，不是运行截图。
- [实际PDF字体对象](pdf-font-verification.json)：使用bundled pypdf读取字体对象，字体流均嵌入。DOCX原字体名不替换，仍使用既有fontconfig的KaiTi/Kaiti SC等映射；不分发字体文件。
- [文件摘要](SHA256SUMS)与[交付目录摘要](../../../deliverables/report/SHA256SUMS)可复核；审批与签字DOCX/PDF原件未改。

渲染工具为bundled Python及LibreOfficeDev 26.8.0.0.alpha0（2c87e51eeaa2b413ff4ae097b2705eea1995d8e5），
使用`runs/template-fidelity-20261007/fonts.conf`，没有调用用户安装的LibreOffice，也没有用其保存DOCX。
最终转换实际命令、输出及成功返回由[最终渲染日志](render-final-v2.log)记录；早期
[首版](render-v1.log)及[最终稿初次](render-final.log)转换也成功保留。最后一次14页PNG位于
仓库`runs/candidate-report-20261007/render-final-v2`，交付PDF是其逐字副本；PNG摘要逐页记录在视觉JSON。
中间稿不是最终交付，只对最终14页签收视觉检查。

失败尝试：第一次图表读取假设标准`ppt/charts`路径不符，随后依据真实relationships读取
`ppt/slides/charts`，未出现数据矛盾。bundled PATH没有`pdffonts`，该尝试退出127；字体核验
改用同一bundled Python的PDF对象读取，并保留[尝试日志](pdf-fonts.log)与明确失败状态。
没有修改数据以使检查通过。

原始转换日志保留内部执行路径；匿名副本应按分发转换记录处理，内部原件保持。匿名包的
新源码身份和干净验收另列；本报告N01绑定此前固定导出，不替后来的产品帮助或包源码背书。

研究边界不变：公开资料、适用性、代码/产物、功能/动态检查、普通性能、既有数据复算
分别报告。新完整受控防护前后、真实非原作者执行、实际运行截图和本人签署仍缺，状态为
供团队审阅修改的提交候选版，不称全部验收或正式签署完成。
