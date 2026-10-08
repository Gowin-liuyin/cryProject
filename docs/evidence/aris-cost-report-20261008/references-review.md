# 新增编译边界与勘误引用的独立核验

2026-10-08，同模型独立、只读科学引用审查。结论为 **bounded_reference_additions_supported**：当前新增段落及两处书目调整有实际来源支持，未发现科学必要修订。本记录不修改或替代此前绑定初版的 `scientific-review.md`，不为其他库的发现向本作品ML-KEM产物签署漏洞结论，也不覆盖页码、缓存、版面或最终分发包。

## 实际对象与阅读深度

直接读取 `deliverables/submission/CACR2026EA16XZ/aris-cost-20261008/CACR2026EA16XZ-作品设计报告-同语言验证版.docx`，当前SHA256为 `4d39cae7dc3d4224dea6016bf5af27d775f08f4bc6df0b7f65ea9bea96382375`。核验对象为第1.2节新增Breaking Bad／RTLF勘误段落、参考文献[11]及参考文献[4]追加的官方勘误URL。

本轮实际读取了ETH作者出版页及其摘要、arXiv作者摘要与版本信息、USENIX官方单页勘误的全部文字，并请求公开Crossref DOI元数据核对正式书目。DOI出版方页面返回403，未取得或重新精读Breaking Bad全文；不把摘要和元数据核验写成全文阅读。没有运行实验、密码程序或漏洞复现，没有修改原始证据。

## 三处核验

1. 新增段落写Breaking Bad系统研究编译优化破坏源码恒时防御，进而要求工具链与实际产物共同检查。ETH作者出版页和arXiv摘要明确以编译优化对高层恒时防护的影响为研究对象，支持该非操作性的高层归纳。报告没有复述攻击实现，也没有称某种源码写法或本地编译产物已自动获得恒时保证。[作者出版页](https://syssec.ethz.ch/publications/2025-09-02-breaking-bad-how-compilers-break-constant-time-implementations-20-500-11850-783304/)、[作者摘要](https://arxiv.org/abs/2410.13489)。

2. 同段写RTLF正式勘误更正一项NSS时间差异的可利用性判断。官方单页确实保留所观察的时间差异，却撤回原有对应可利用性判断；这一事实支持将观测差异与可利用性分别报告。现文进一步明确其他库的发现不是本作品固定ML-KEM产物的漏洞证据，限定正确。未据此否认全部时序问题或撤回该论文的整个方法。[USENIX官方勘误](https://www.usenix.org/system/files/sec24_errata_dunsche.pdf)。

3. 参考文献[11]的作者前三名Schneider、Lain、Puddu、题名、ASIA CCS、2025年和DOI均与ETH作者书目及arXiv关联DOI相符。公开Crossref返回的出版社为ACM，文献类型为proceedings-article，会议为Proceedings of the 20th ACM Asia Conference on Computer and Communications Security，页码为1690–1706；当前“2025:1690–1706”准确。[公开DOI元数据](https://api.crossref.org/works/10.1145/3708821.3733909)。参考文献[4]追加URL为所读取的USENIX正式勘误地址，未误链至第三方摘要。

## 解释与后续范围

当前文字仅使用跨层检查和观测／可利用性区分两项高层依据，阅读深度与所支持的主张相称。若后续增加特定编译转换、库版本、攻击条件或实验机制细节，应先核对相应全文与具体证据，不得由本记录升级为已完成全文精读或本地漏洞验证。

先前同语言成本的科学审查仍按其记录的初版对象与范围解释；本次只为这三处引用增补提供独立依据。后续目录页码及版面调整应另记最终文件摘要和限定差分。本记录为内部可核查的引用审查材料，没有人员签署或第三方评审认证。
