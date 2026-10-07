# 公开来源检索记录（本轮新增）

查阅日：客户端 2026-10-07。来源时间保留 UTC；检索执行者为作者代理 Agent。此目录没有漏洞触发、利用运行或人员独立复现证据。

- [全量公开 Issues/PR 元数据](issues-and-pr-metadata.ndjson)：只读 GitHub REST API `repos/pq-code-package/mlkem-native/issues?state=all&per_page=100`，逐页到结束；1926 项，573 Issues、1353 PRs、1811 closed、1040 merged。仅保留标题/链接/状态/时间/标签，不保存正文或附件。
- [类别筛选元数据](selected-metadata.json)：标题中的 timing/CT/UB/zeroize/barrier/soundness/random/error/secret 等及 security/soundness/bug/CT 标签筛选。标题筛选不是漏洞认定，也不是完整正文审读。
- [21 项重点身份](selected-pr-identities.json)：读取 Issue/PR 公开元数据；合并 hash 对固定 b3ba 比较，保存 status/ahead_by/behind_by/total_commits/exit_code。去除讨论正文。
- [7 次发布](release-metadata.ndjson)：只读 release API 的标签、时间、链接。
- [8 份文档身份](document-identities.json)：固定 b3ba 和本轮 main 身份 6b12c8cd 的 SECURITY、README、SOUNDNESS、RELEASE，读取 exit_code=0；保留公开链接、blob SHA、字节数及 SHA-256。仅摘要，不复制整篇文档。
- [文件摘要](SHA256SUMS)：本目录上述元数据与本说明的摘要。集中判断正文见 [公开审查](../../upstream-security-review.md)。

已读取的原始网页和正文来自 GitHub、NIST、pqc-forum、IACR 和维护者/作者官方说明。完整标题、来源和适用范围列在集中记录 U01–U19；来源页面链接需要网络，离线可打开本地判断和元数据。未把在线链接冒称离线原件。

失败和限制：

1. 首次元数据尝试错误组合 `gh api --slurp --jq`，工具退出 1（选项不兼容）；改为逐行 JSON 分页，成功。未用失败输出计算条目数。
2. 首次文档摘要记录脚本出现参数语法错误，退出 1；修正后取得 8 份身份，全部退出 0。未改动上游文件。
3. NIST FIPS 203 正文网页可读并链 potential errata XLSX；网页工具打开 XLSX 报 Internal Error，普通 HTTP 读取正文返回 403，脚本退出 1。没有读取具体勘误、不绕访问限制。
4. KyberSlash 作者站首页网页工具报 Internal Error；IACR 原始论文元数据与修订日期可读。未宣称核查不可读的作者网站更正。
5. GitHub 网页有动态加载错误提示；需要的原始正文和身份经公开只读 REST API 补核。未收集私人报告或登录社区；没有在 Discord 发言或读取其内部资料。

本目录是本轮公开资料检索新增记录，既有人工时序案例、普通性能和复算数据不放入此目录重新冒称新实验。
