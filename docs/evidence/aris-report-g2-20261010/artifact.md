# G2报告的模板保真合同

基准为本仓库deliverables/research/aris-report-weak-mean-20261010中已审47页匿名DOCX，
SHA256 9a2b7e92cebc8dc7b4aca677728a7ebb5d2b29c90b265e82d14b926bdb360c3a；
PDF SHA256 671d059c0b39924bc7120900154fe2c206892aca50b97664f5a7202de1262a8c。
此前全47页实际PNG及视觉记录在docs/evidence/aris-report-weak-mean-20261010封存；本次复用
该基准实际QA及包部件清单，最终新版全部页面须再经实际渲染与团队100%页面检查。

## 模板模式

四分节均为A4纵向11906×16838twips，单栏；封面/简介页四边1134twips；目录及正文
左右1417、上下1361twips。正文末节header737/footer680，其他header851/footer992。
Roman前置页与正文decimal从1起的分页规则、所有原页眉页脚和节XML保留。
RWBody：SimSun/Times New Roman，12pt，精确22pt行距，后4pt，首行480twips；
RWSection：SimHei/Times New Roman，14pt粗体，前12/后8pt，20pt行距，keepNext/keepLines；
RWChapter：16pt黑体，强制新页；RWCaption：11pt宋体，17pt行距，后9pt；
RWTOC1/2：12/11.5pt，18pt行距，右页码点引导。标题、日期、简介表和正文沿用原格式，
不换通用模板，不重建封面。原模板三线表黑色规则优先于通用浅灰格线默认。

## 可编辑位置

- 作品摘要TABLE1/BODY25/row5/cell1/p2/CA140001：只追加G2一句，所有原run保持。
- 原直接P217后：加旧KVM环境与G2分界一句。
- 新5.9位于bookmarkEnd87与bookmarkEnd88之间，独立新bookmark，章5内且旧5.8外；
  新目录行位于旧P61后，链接新bookmark，目录42变43项，最终页码由实际PDF确定。
- 新表5.11克隆原TABLE8环境表，宽8957twips=15.8cm，列2948/6009；短指标/数值两列；
  11pt、至少行高、不拆行、重复表头，新增表体取消跨全表keepNext链。原22表只允许摘要
  表的上述追加使XML变化，其余21表按原序原字节保留。
- 新OMML式5-5/5-6克隆原式5-1的段落框架，结构化下标、上标和分式；原62个math按序不变。
- 新图5.8克隆既有图片段落，宽5688000EMU=15.8cm，按2100×1380比例；仅新增一个
  media部件及一个image relationship，唯一docPr ID，alt描述中不含本机路径。
- P305概括已在实验章节和原表完整保留的重复历史指标，并在其后加G2成果段，避免总结溢出为孤立尾页；
  不删除实验章节、原表、摘要或历史原件中的数字。P310后加适用精度和统计边界；P338仅把旧Ryzen宽泛缺证据句限定日期；
- P311为截图/暂定题名/签署等流程备注，从科学正文移出以避免孤立尾页；原全文与原XML摘要
  保留作者日志，真实画面和本人审批签章缺口移到交付README，不据此增加题名审批门或签收全目标。
  P339只把原PowerPoint图源范围与新G2静态图源分开；P345后加匿名G2来源索引。
- 参考文献在14后加固定Linux v6.17源码背景条目15，不虚构发布日期或AMD全文阅读。

## 保存与核验

保存全部原styles/theme/numbering/headers/footers/customXml等部件原字节。允许document.xml、
app.xml页数缓存、document关系追加、settings仅加updateFields=true及新增PNG部件改变。
43个静态TOC缓存按真实渲染回填，不用LibreOffice保存改写原件；再次渲染检查页码与正文。
原18图、62math及4节按序一致；所有非目标原直接段落按序字节一致；表1变化须仅允许摘要
指定段追加。列出每个实际编辑、包部件差分及源/新文件摘要。旧基准文件始终原字节。
目标正文不泄露用户名、主机、IP、根目录或自有提交号；公开来源版本和系统作品编号保留。
逐页目视没有裁切、重叠、缺字、图表孤立或页码错误后，才授权交付与新匿名包组装。
