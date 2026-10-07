# 官方模板执行契约

参考文件：docs/reference/official-2026/report-template-original.docx，用户新提供文件与其SHA256均为4f81348bf085527f7ebe5de2787fd91ba05e5b5531754916badb005fcfb512c2。原件只读。

三个分节原样保留：A4 11906×16838 twip，四边1134 twip，页眉851、页脚992、单栏间隔425；headers/footers、样式、theme、字号及页码字段不重建。

正文主标题克隆原正文28（华文楷体15pt，源pPr/rPr完整）；二级标题克隆32（黑体中文、Times New Roman西文14pt）。正文、表内自有数据和图表说明克隆33的完整pPr/rPr（楷体_GB2312中文，西文Times New Roman14pt，固定行距480twip=24pt）。不再把数据表或图注缩成11pt。新数据表仅增加必要列宽和重复表头，字体/段落按正文角色。

基本信息表复制原表对应行的文字和段落属性，15pt保持，不能只保留pPr而丢rPr；标签与内容按其原模板角色。摘要空段是填写槽，可按实际内容填入，不保留无内容的多页空白。编号及题名仍占位，审批/签署不改。

封面原布局、主标题及logo保留。作品题目标签按原楷体14pt，题名填入原华文中宋14pt空白内容run。删除原件中明确要求提交时删除的匿名提示，不增个人身份。

源6页旧字体回退渲染已检视；加入本机已有Office字体目录后，参考可渲染为4页。参考与最终采用完全相同的任务级fontconfig。原DOCX字体名不替换，运行映射楷体_GB2312至已安装KaiTi，华文楷体至Kaiti SC，华文中宋至STZhongsong；在PDF字体清单记录，不能冒称机器另有原GB字体文件。字体不加入分发包。

三幅图以可编辑PPT原生对象绘制。字体字号按报告正文14pt，工作画布6×3.375in（576×324 CSSpx），无商业装饰。内容为工程流程、全部18运行均值、限定精确复算进程成本；所有数值仅读既有C报告，CSV和统计参数不改。图2非零纵轴和图3对数刻度明确标注，不以改变展示比例强化科学结论。

包保护：word/styles.xml、word/theme/*、numbering、fontTable、原headers/footers、原logo、section属性和原template relationships保留。可修改word/document.xml、docProps/core.xml匿名属性、word/settings.xml更新字段、已有自有a113图像及新增PPT导出图片。禁止LO保存DOCX更新字段；只用读取/转PDF并视觉复核。

验收：按角色逐个pPr/rPr比对，所有非空实际text run符合原属性；三个section同源，保护parts逐字一致；表和图数字比对C报告；PPT对象可编辑并最终原生导出；逐页图像审查，无裁切、覆盖、错字号。所有偏差登记，整体项目科学和非原作者缺口不因排版升级。
