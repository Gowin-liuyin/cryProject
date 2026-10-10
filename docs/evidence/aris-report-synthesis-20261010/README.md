# 四项研究整合报告核验

2026-10-10；基线main `c38523c8e9177bd052a02c53de67d9ffd3c709f7`。
成品见[交付目录](../../../deliverables/research/aris-report-synthesis-20261010/README.md)。
本目录为含作者侧路径的内部核验原件，不能直接当匿名分发件。

## 科学与官方要求

`OUTLINE_REVIEW.md`、`REQUIREMENTS_AUDIT.md`及`NEW_EVIDENCE_FACT_CHECK.md`分别核对结构、官方材料和108行C描述。
原G2耗时仅分析旧126528条调用；弱均值F2仅给原区间的条件有限下界；RAW共303000空pair；完整参考共300000计时调用。
它们各自绑定源、产物及数据，不池化为独立总体样本，不把约30.7/39.3微秒写成加速，不从调用扣20 ns，不把40 ns观察范围当精度。
数学前提不能由文件资格自动认证；R02/R04保持partial，按实际最终主张评价，未增加题面没有规定的物理恒频或总体错误率硬门。

保留软件/系统作品设计报告的功能、实现、测试及复现主线。核对的[官方复赛通知](https://chinacodes.com.cn/news/lookAllNews.do)包含报告/支撑/审批分开上传、匿名及真实运行/测试截图等要求。
官方留存原件与阅读范围见要求审计；未将研究笔记代替可运行作品，未把文献摘要筛选称作全文精读。

## 保真和核验

`artifact.md`、`template-inventory.json`以原49页DOCX `96e2de8a…`为参考，不误用旧47页合同。
实际编辑、原句和XML摘要见`authoring-edits.json`。原64个数学子树、19图、四节、21非目标表、索引旧11行、417个非目标且非目录直接body元素原字节保留。
43个旧目录段仅回填缓存数字，原4.5标题顺移4.6；新增两项后45个链接目标完整。新三表逐格与冻结C输出一致。
保留42个包成员，除document.xml和app.xml页数缓存外原字节不变；未使用LibreOffice保存回写DOCX。

`ROUND1_CONTENT_REVIEW.*`绑定首轮db7a稿，修正共同转储保护层级和交叉引用；`ROUND2_CONTENT_REVIEW.*`绑定07c7稿；`FINAL_CONTENT_DELTA_REVIEW.*`再核最终95ff稿仅精简新增附录说明及分页缓存。
`delivery-candidate-verification.json`最终120/120通过；`toc-final-check.json`按最终真实PDF逐项验证45个页码。
原49页视觉QA在原封存目录复用；最终54页全部重新逐张调用view_image(original)实际观看，分工回执和PNG摘要见`visual-review-final-*.json`及`visual-qa.json`，完整PNG见`page-images.zip`。
界面显示存在适配缩放提示已如实记录，没有用缩略图、XML或哈希替代实际观看。三张新表完整；附录孤尾已消除。

只使用workspace bundled Python/Node与隔离headless LibreOffice，未用桌面LibreOffice。详细环境见`render-environment.json`。
作者脚本路径只支持仓库内工作副本；不得在本封存目录直接运行并改写原件。重渲染会改变PDF元数据与摘要，必须生成新身份再审。

## 失败、边界和下步

初稿作者脚本复用ZipInfo导致内存偏移改变、后置ZIP读取核验失败，参考DOCX字节未损坏；随后修正读写次序。首轮目录书签丢失和短表跨页真实存在，已修复。
独立验证器曾因脱离根的命名空间比较误拒B144，旧误拒及脚本保留，再用字面XML比较核对。两轮附录精简中第一次仍有两行孤尾，实际重渲后再次精简才闭合。
`attempts.json`与`review-before-orphan-fix/`保留失败/旧通过范围；不将旧55页视觉回执冒充新54页签收。

本模块无SSH、新硬件采集、C执行或密码算法调用。原49页、925项包和四研究证据未改。
内部同模型复核不是外部Codex、跨模型或同行评审。新版匿名支撑闭包、真实截图、本人审批和平台回执尚未完成；不得据本报告模块宣布完整目标已达成。
用户原有两处文档修改及.agents保持未暂存；只提交本模块新增物料与进度追加。
