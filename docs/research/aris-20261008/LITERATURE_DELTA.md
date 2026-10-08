# 文献查新与贡献定位

核验日期：2026-10-08。本轮复用[29 项原书目](../../../deliverables/research/mlkem-literature-20261008/references.json)，补充遗漏的最近先验工作和 2026 年保证范围资料。搜索用于发现，结论依赖标准机构、出版方、作者或维护者原始材料。不同版本不重复计为独立成果；定向查新不冒称穷尽检索。

## 最接近的工作及实际差异

| 来源 | 已有结果与阅读范围 | 本项目的实际差异及允许定位 |
|---|---|---|
| [Diaconis 与 Holmes，Gray codes for randomization procedures，Statistics and Computing 1994，4:287–302](https://link.springer.com/article/10.1007/BF00156752) | 出版元数据及摘要已核；完整枚举、Gray 局部变化和增量更新加速已有明确工作，未取得付费正文 | C11 的有界整数实现、固定交换任务数值核验及完整流程成本；不得称 Gray 方法或加速思想首创 |
| [Hemerik 与 Goeman，TEST 2018](https://link.springer.com/article/10.1007/s11749-017-0571-1) | 正文 §2、定理 1 及含并列讨论已核；变换群与分布不变性决定检验资格 | 本项目给出固定标签模型的特化和独立计算验证；精确算术不能代替模型前提 |
| [RTLF，USENIX Security 2024](https://www.usenix.org/conference/usenixsecurity24/presentation/dunsche)及[正式勘误](https://www.usenix.org/system/files/sec24_errata_dunsche.pdf) | 方法与 iid 条件见原书目；勘误收回由 NSS 差异推出攻击的判断 | 防御审计应将时间观察、秘密机制与可利用性分开；不能用一个 t 检验构造弱基线 |
| [SILENT，arXiv 2504.19821v1，2025](https://arxiv.org/html/2504.19821v1) | 正文假设 1、定理 1–3 和限制已核；严格平稳、有限范围依赖；明确的连续情形 bootstrap 保证为渐近界 | 本项目未实现同等依赖推断；不得称依赖处理首创，不能把连续定理直接套到整数并列时间 |
| [Brumley，SoK The Constant Time Model，WOOT 2026](https://www.usenix.org/conference/woot26/presentation/brumley) | 正式会议记录和[作者摘要](https://arxiv.org/abs/2606.13000)已核；研究模型与原语之外边界。只采用防御性模型定位，未审计全部案例 | 增补观测、信任前提、接口、加载和部署范围表；不借其第三方发现为本项目确认漏洞 |
| [On timing side channels in constant time implementations，2026](https://link.springer.com/article/10.1007/s13389-026-00394-y) | 出版方确认 2026-05-26 发表；对象是 Xtensa/X25519 的源码与低层编译行为 | 用作跨层保证背景，不能转成 x86_64/ML-KEM 固定产物的漏洞证据 |
| [mlkem-libjade 开发者说明](https://github.com/pq-code-package/mlkem-libjade/tree/c2380886a0d644266661e702d5000027df095a2b) | 项目说明含恒时、推测恒时及功能正确性保证，同时保留 SHA-3 等假设和当时的验证覆盖限制；本轮固定读取版本 | 比较保证对象与覆盖，不把其证明移交给本项目便携 C 封装，不引入新的算法框架 |
| [LLVM PR 166702](https://github.com/llvm/llvm-project/pull/166702) | 2026-10-08 REST 核验 Open、merged=false，head=c7a4df2f；新恒时选择语义属于尚在推进的工具链工作 | 不称当前 Clang 18/21 已有该保证，不为追新改动固定构建 |

Gray 编码是效率贡献最直接的先验工作，应该位于方法依据旁边，而非只出现在展望。正式报告中应让读者看见“已有计算原理→本作品专用实现→独立计数核对→固定任务实测成本”的完整关系。

SILENT 引入容许阈值的问题方向是检出超过预定阈值的差异；不拒绝其零假设也不等于已经证明差异落在界内。若报告要声称实质等价，需要另设等价问题及覆盖有效的置信界。当前六对探索 bootstrap 或低自相关诊断都不能补出该结论。

## 标准口径

[FIPS 203](https://csrc.nist.gov/pubs/fips/203/final)为 2024-08-13 最终版；官方页面另有 2025-11-17 潜在勘误说明。发布页及问题存在已核，具体 XLSX 条目的适用性尚待成功读取，不称已经全部关闭。当前代码保持固定快照和独立公开向量，旧 Kyber 历史资料不能代称最终 ML-KEM。

[SP 800-227](https://csrc.nist.gov/pubs/sp/800/227/final)已于 2025-09-18 正式发布，应引用最终版而非初稿。[NIST FAQ](https://csrc.nist.gov/Projects/post-quantum-cryptography/faqs)的 2026-06-16 答复允许种子密钥格式，但要求组合实现输出与标准算法一致；这一更新不要求本作品改变现有扩展密钥接口。算法标准、功能验证、工程实现保证和模块认证分别说明。

## 新颖性判断

| 可能的创新说法 | 判断 | 最小修订 |
|---|---|---|
| 首次 Gray 精确枚举或首次随机化分析 | 不成立 | 引用直接先验；写专用整数实现与固定成本结果 |
| 首次处理依赖或统计误报 | 不成立 | 对照 RTLF/SILENT；本项目只核定实际适用条件 |
| 掩码/屏障首次修复当前上游 | 不成立 | 上游该处本来无分支；人工回归按案例呈现 |
| 固定任务统计复算工程效率提高 | 范围内成立 | C/SciPy 对齐统计量、空间、尾部和成本，八任务独立列出 |
| 资格校验能自动证明推断有效 | 不成立 | 写成部分可检查字段与解释限制；未证假设保留 |
| 证据组织使本作品可追溯复核 | 范围内成立 | 用真实复算记录、输入资格拒绝和来源映射支持，不称首次或可用性胜出 |

## 检索限制及后续引用

独立 Codex MCP、Zotero 和 Obsidian 接口未开放。三名独立子代理可直接读取仓库进行交叉审查，但它们不是独立模型或外部同行评审。来源未取得全文的条目保持摘要级，不把检索条数当系统综述覆盖率。可变上游的本次读取身份和 PR 状态另存 [source-status.json](source-status.json)，不将以后页面状态回填为本次核验。

最近六个月窗口为 2026-04-08 至 2026-10-08。本轮只完成相关来源定向核查，未完成完整数据库检索、逐月覆盖或系统综述；发现 2026 年材料不等于整个窗口查新完成。

[2026 年 RIC 作者预印本](https://eprint.iacr.org/2026/924)的摘要说明其防御改变失败率，与本仓库保持密码语义的合同不直接相容；无需为前沿性引入。没有把新攻击流程、漏洞复现或密钥恢复纳入本轮研究。已确认来源 URL 和元数据足以支撑上述定位，未从记忆编造新的 BibTeX。
