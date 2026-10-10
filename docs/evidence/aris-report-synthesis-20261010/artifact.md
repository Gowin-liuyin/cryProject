# 四项后续研究整合稿的保真合同

参考文件为本仓库 deliverables/research/aris-report-g2-20261010 中49页匿名DOCX，
SHA-256 96e2de8af1238518f8d754cd9f969a4e82499d8b89552e143128aeba8da861e6；
对应PDF d5b65e65f66cd3ade42fee58502112be34ab97716b587657e41e2d246a1e60a4。
参考包路径、各部件大小/摘要、原生公式/图/表/节、全部角色样式XML见同目录
template-inventory.json。原49页实际全页视觉证据复用 docs/evidence/aris-report-g2-20261010
中的 page-images.zip 及 visual-review-*.json；不把旧47页当作本次参考，不假称本轮重新目视旧49页。

四节均为A4纵向11906×16838twips。封面/简介页四边1134；目录/正文左右1417、
上下1361；正文header737/footer680，其他851/992；Roman前置、decimal正文1起规则不改。
RWBody宋体/Times New Roman12pt，精确22pt行距，后4pt，首行480twips；RWChapter16pt
黑体强制新页；RWSection14pt黑体、前12后8pt、20pt行距、keepNext/keepLines；
RWCaption11pt宋体17pt行距；RWTOC1/2为12/11.5pt、18pt行距、右对齐点线页码。
不改变封面、题名、类别、恰五关键词、字体、页眉页脚、节与已有图文版式。

可编辑位置按原word/document.xml/body零基直接子索引及paraId双重绑定，并记录原XML：
B24摘要表CA140001缩写重复效率数字并补四项成果，保留全部原文于编辑日志；
B90/98/131/144/153/185/200/249/274/415/416/422/423更新对象、当前事实与边界；
B257旧4.5顺移4.6，原式4-4仅改外部编号4-9，不改数学节点；
在旧4.5书签前插入新4.5（原区间、固定潜在数组、有限F2与短证明骨架），新增5个OMML公式；
B384后、G2书签结束前插入旧原件耗时表5.12和完整时间账式5-7；
G2书签结束后、章5书签结束前插入5.10，分列RAW空窗表5.13与六进程表5.14；
B398补一段测量与理论层次，不增图；B442后加固定Tyurin v1书目[16]；
B448表A.1只追加四索引行，原各行XML保留；B469后另加四研究身份说明。
两个新增TOC链接、旧4.5链接标题、全部静态页码按真实PDF回填；原43变45项。

新表均克隆原环境表的三线样式、11pt、至少行高、不拆行与重复表头，宽8957twips。
7列网格1397+6×1260，6列1657+5×1460；三张新短表仅在最后行取消keepNext，保持整表，不缩字塞页。
公式沿用原居中式号段框架，以原生OMML分式/根号/上下标/重音/定界符构造。
无新图，保留原19drawings、64math按顺序完全相同，23原表除摘要与索引表外按序相同。

仅word/document.xml、docProps/app.xml页数缓存可改。原settings已updateFields=true，
保留原字节；所有关系、styles/theme/numbering/header/footer/customXml/media/core等其他部件
原字节保留。没有文档正文TOC/REF等动态域；页眉页脚PAGE域保持原结构。Word刷新不可用，
不使用LO保存回写DOCX。所有修改/新增/包差分/源与候选摘要保存，非目标body子元素完全相同。

正文只说明已经封存的四研究；新版匿名支撑闭包尚待独立模块组装，不预填目录/数量/摘要。
作者侧实际云路径、用户、IP、自有提交号不进入正文；第三方来源/系统编号保留。
无新增采集、C复算、算法或SSH。用bundled Python及headless LibreOffice渲染；禁止桌面LO。
最终必须核对全部45目录页码、公式/表数据、匿名性、保真，以及全部最终PNG实际100%目视。
