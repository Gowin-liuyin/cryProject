# 固定上游公开依据与安全审查记录

本轮查阅日按客户端日期记为 **2026-10-07**；上游发布日期、合并日期和 API 时间均保留 UTC 原口径。对象为 `mlkem-native b3ba7b32773e657dd37f6f87bce82528459ad8a4`、ML-KEM-768、便携 C 算术及随库 C FIPS-202 后端。该提交的作者时间为 2026-09-21 07:50:12 UTC，提交者时间为 2026-09-22 03:22:27 UTC；原来源文档的单一日期已补齐，属于来源一致性更正。

本记录核查公开事实与版本关系；实际代码、构建和产物判断见 [当前版本适用性审查](current-version-defense-review.md)。它不构成新漏洞发现、漏洞复现或防护效果确认。R02/R03/R05/R06 的来源和防护审查得到补充，R07 仍需要适用的实际防护前后证据。

## 范围、方法与记录

在约 20 分钟的限定资料工作内，先读固定提交与当前主干的 SECURITY、README、SOUNDNESS、RELEASE，再遍历上游公开 Issues/PR 元数据，按问题类别回到相关维护者原始记录。后续检查标准、维护者邮件、作者材料和实际相关集成。没有执行页面或附件中的命令，没有联系维护者或对外发布。

GitHub REST API `issues?state=all&per_page=100` 分页得到 **1926 项**：573 个 Issue、1353 个 PR；1811 项关闭，1040 个 PR 有合并时间。该数字是本轮可见的公开条目数量，不是漏洞数量。先筛标题和标签，再精读相关来源；未逐字阅读全部 1926 个讨论。关闭和未合并条目也保留，不以关闭等同修复。

可离线打开 [全量标题与状态元数据](evidence/upstream-security-review-20261007/issues-and-pr-metadata.ndjson)、[筛选元数据](evidence/upstream-security-review-20261007/selected-metadata.json)、[21 项重点 Issue/PR 身份及祖先比较](evidence/upstream-security-review-20261007/selected-pr-identities.json)、[7 次发布元数据](evidence/upstream-security-review-20261007/release-metadata.ndjson)、[固定及主干文档摘要](evidence/upstream-security-review-20261007/document-identities.json)、[读取范围与失败记录](evidence/upstream-security-review-20261007/README.md)。存档仅含标题、链接、状态、时间、版本身份与摘要，不存讨论正文、载荷或攻击脚本。

本轮主干观察身份为 `6b12c8cd67e1edd07c43f581386449a6b064e6e2`（提交者时间 2026-10-06 04:36:07 UTC）。文档摘要同时固定该主干身份，避免将未来 main 内容当作本轮材料。固定提交已包含 v2.0.0 发布的接口和证明调整；固定身份不是 v1.x。发布列表为 alpha（2024-12-03）、beta（2025-03-03）、v1.0.0（2025-06-04）、v1.1.0（2026-03-14）、v1.2.0（2026-06-20）、v1.3.0（2026-08-03）、v2.0.0（2026-08-07）。[上游发布页](https://github.com/pq-code-package/mlkem-native/releases)、[固定 RELEASE](https://github.com/pq-code-package/mlkem-native/blob/b3ba7b32773e657dd37f6f87bce82528459ad8a4/RELEASE.md)。

API compare 中，以修复合并提交为 base、固定提交为 head，`ahead` 且 `behind_by=0` 说明修复在固定提交祖先内；仍需核对实际代码，不能仅凭时间推断。相关完整合并 hash 和原始比较结果放在重点身份记录中。

## 有效线索与判断边界

下列每条均于 2026-10-07 查阅。A 为当前配置排除；B 为固定版本已有对应防护；C 为自有代码真实缺陷；D 为预防性加固机会；E 为资料或验证不足。此处列出处与初步关系，最终适用性及排除代码依据以相同 U 编号的适用表为准。

### U01 标准与潜在勘误

[FIPS 203 最终版](https://csrc.nist.gov/pubs/fips/203/final)发布于 2024-08-13；官方在 2025-11-17 标注 future revision 的 potential errata。最终标准、旧 Kyber 和草案须分开。正文页面可读，所链 XLSX 经网页工具读取失败，普通 HTTP 读取正文返回 403；本轮未读取具体勘误条目，不能据此调整标准语义或认定固定实现受影响（E）。维持当前 FIPS 203 口径与独立向量，具体勘误适用性待取得可合法读取的官方材料。

### U02 安全政策和公开公告

[固定 SECURITY](https://github.com/pq-code-package/mlkem-native/blob/b3ba7b32773e657dd37f6f87bce82528459ad8a4/SECURITY.md)和[当前 SECURITY](https://github.com/pq-code-package/mlkem-native/blob/main/SECURITY.md)均指定私下漏洞报告渠道；文档未列支持版本安全承诺。[公开公告页](https://github.com/pq-code-package/mlkem-native/security/advisories)本轮显示没有已发布公告。这仅说明该页面的可见记录，不能证明没有漏洞或私人报告。未向其报告或联系；无需为满足题目制造新漏洞。

### U03 证明与硬件保证覆盖

[固定 README](https://github.com/pq-code-package/mlkem-native/blob/b3ba7b32773e657dd37f6f87bce82528459ad8a4/README.md)及[固定 SOUNDNESS](https://github.com/pq-code-package/mlkem-native/blob/b3ba7b32773e657dd37f6f87bce82528459ad8a4/SOUNDNESS.md)明确区分 C 的内存/类型安全证明与 AArch64/x86 汇编的功能、内存和秘密无关执行证明。SOUNDNESS 于 [#1582](https://github.com/pq-code-package/mlkem-native/pull/1582) 2026-03-02 合并。C 层功能正确性与恒时未形式证明；证明配置、C/HOL 契约衔接、重汇编产物一致性、真实硬件和模型外效应仍有边界。它属于证明覆盖限制（E），并非已确认部署漏洞。本作品使用便携 C，不能借用未链接的汇编证明签收自身恒时；本轮不会声称重新运行上游形式证明。

### U04 早期编译器分支防护与 LTO 加固

[#55](https://github.com/pq-code-package/mlkem-native/pull/55)创建于 2024-06-12、2024-06-13 合并，维护者关联旧 Kyber 消息编码分支修复；[#460](https://github.com/pq-code-package/mlkem-native/pull/460)创建于 2024-11-29、2024-12-01 合并，采用值屏障提高比较/条件操作对内联优化的稳健性。前者是早期实现问题，后者为编译防护加固；均在固定祖先内（B）。防护原则是保持标准计算和隐式拒绝并检查真实编译产物；原先特定编译条件不能自动推广到当前编译器、CPU 或所有后端。

### U05 值屏障 volatile

[#1342 Make value barrier volatile](https://github.com/pq-code-package/mlkem-native/pull/1342)创建于 2025-12-05、2025-12-29 合并。维护者明确称添加 volatile 是预防措施，没有观察到原屏障被不安全优化的编译实例。合并提交 `d10fee2e16533feae5e1343692fb77f6bb2e411d` 已是固定祖先；本地固定 `verify.h` 的 GCC/Clang 屏障实际为 `__asm__ volatile`（B，原变更性质为预防性）。不能将此 PR 改写成当前库有已确认漏洞。编译器范围、硬件前提及最终产物仍需分开核查。

### U06 零化与分配失败清理

[#1328](https://github.com/pq-code-package/mlkem-native/pull/1328)于 2025-12-01 创建/合并，维护者补齐中间多项式向量清理；[#1402](https://github.com/pq-code-package/mlkem-native/pull/1402)于 2025-12-17 创建/合并，修复自定义分配失败时的清理空指针问题；[#1559](https://github.com/pq-code-package/mlkem-native/pull/1559)于 2026-02-10 创建/合并，在 keygen PCT 失败时清理输出降低 API 误用风险。分别属于清理缺陷、条件性内存缺陷与防御性 API 加固，均已在固定祖先内（B）；当前未启用自定义分配（相关 #1402 条件另为 A）。清理应使用受支持的 zeroize，不能用普通 memset 证明敏感信息一定消失；调用者拥有的密钥和系统物理内存生命周期不自动由库保证。

### U07 x86 汇编采样越界读

[#1615](https://github.com/pq-code-package/mlkem-native/pull/1615)于 2026-03-07 创建/合并，维护者在证明工作中纠正 x86 rejection-sampling 汇编的 4 字节超出名义缓冲区读取；额外内容位于栈帧内且未被消费。它是边界安全缺陷，修复已包含（B）；本作品不启用该汇编后端（A）。不将此记录推演为密钥泄露或本作品已复现越界。

### U08 16 位 int 平台的未定义移位

[#1727](https://github.com/pq-code-package/mlkem-native/pull/1727)于 2026-06-07 创建/合并，修复便携采样/解码在 16 位 int 目标上的有符号移位 UB 并增加对应检查。它是平台条件性一般缺陷，修复已在固定祖先内（B）；本轮 macOS arm64 与授权 x86_64 Linux 编译器的 int 宽度另经工程验证，不冒充 AVR 证据（当前平台 A）。未扩展到硬件分支。

### U09 RISC-V RVV 防护

[#1732](https://github.com/pq-code-package/mlkem-native/pull/1732)创建于 2026-06-07、2026-06-08 合并；[v1.2 发布说明](https://github.com/pq-code-package/mlkem-native/releases/tag/v1.2.0)归为 RISC-V 小缺陷修复及秘密相关时序加固。此变更已在固定祖先内，但当前不编译 RVV（A/B）。不能将某架构的操作条件套用到便携 C 或声称 RISC-V 完成与 x86/AArch64 相同的证明覆盖。

### U10 证明工具健全性与量词边界

[#1694](https://github.com/pq-code-package/mlkem-native/pull/1694)创建于 2026-05-15、2026-05-16 合并，明确 CBMC forall/exists 的 4 GiB 边界；[#1745](https://github.com/pq-code-package/mlkem-native/pull/1745)创建于 2026-06-14、2026-06-20 合并，绕开 Z3 健全性问题；[#1762](https://github.com/pq-code-package/mlkem-native/pull/1762)于 2026-06-26 创建/合并，使用 CBMC 6.10.0 正式版本。维护者确认的是证明基础设施和适用假设，不是 ML-KEM 内核新增密码漏洞。调整已在固定祖先（B），但本仓仅保留库快照，未重新取得 CBMC/Z3 证明执行记录（E）；CTest 不能替代该证明。

### U11 禁用随机 API 构建、错误输出契约与错误码

[#1816](https://github.com/pq-code-package/mlkem-native/pull/1816)创建于 2026-07-26、2026-08-02 合并，修正 NO_RANDOMIZED_API 测试等构建；[#1850](https://github.com/pq-code-package/mlkem-native/pull/1850)创建于 2026-08-05、2026-08-06 合并，加强失败输出不变或零化的 CBMC 契约；[#1852](https://github.com/pq-code-package/mlkem-native/pull/1852)创建于 2026-08-05、2026-08-07 合并，区分公开密钥检查、秘密密钥格式检查、PCT 及平台失败码。它们分别为构建缺陷、证明强化、API 澄清；固定均已包含（B）。本项目封装仍须按统一约定处理失败，不能把密文隐式拒绝内部结果暴露给调用者；系统随机失败传播属于自有边界检查。

### U12 同一编译单元的配置加载顺序

[#1919](https://github.com/pq-code-package/mlkem-native/issues/1919)与修复 [#1920](https://github.com/pq-code-package/mlkem-native/pull/1920)创建于 2026-09-25，后者 2026-09-26 合并。维护者确认带 build-only 条件区段的配置在同一编译单元先含公开头再含源码时可能被 include guard 跳过。修复合并在固定之后，固定尚未含此改动；但本仓配置平坦、自有 kernel 编译单元未先含公开头，封装为另一个编译单元（A，需实际构建链核验）。这是集成配置一般缺陷，不能仅因固定早于修复就认定当前配置受到影响。

### U13 空汇编单元的 GNU 栈标记

[#1923](https://github.com/pq-code-package/mlkem-native/pull/1923)创建于 2026-09-25、2026-09-27 合并；维护者确认即便 C-only，若仍组装空 `mlkem_native_asm.S`，缺少 GNU-stack note 可令特定 GNU 链接产物带可执行栈。固定未含该修复；本仓没有编译该汇编单元，需服务器 ELF 栈权限和链接来源共同排除（A）。它是构建防护缺陷，不能只凭目录中有 `.S` 文件判断执行路径。

### U14 汇编长度参数 ABI 与证明衔接

[#1926](https://github.com/pq-code-package/mlkem-native/pull/1926)创建于 2026-09-25、2026-09-27 合并；维护者将 x86/AArch64 采样长度 C 原型改为与汇编及 HOL 规范一致的 64 位参数。原 32 位参数的高位 ABI 前提不被证明覆盖。属于调用接口/证明衔接缺陷，固定未含此后续修复；便携 C 不经过该汇编接口（A）。不能把证明覆盖缺口本身称为已证实泄露，后续更换后端时需重新审查。

### U15 便携 C 乘法的目标平台前提

[#1921](https://github.com/pq-code-package/mlkem-native/issues/1921)于 2026-09-25 创建，仍开放；它镜像维护者的 [mldsa-native #1436](https://github.com/pq-code-package/mldsa-native/issues/1436)。原讨论指出便携 C 中秘密值乘法需要目标乘法/编译辅助实现满足恒时前提，并提议文档或目标限制。该镜像没有单独确认某个 ML-KEM-768/x86 产物泄露，也未提供普适防护结论。当前平台需记录编译器、指令和硬件使用限制；未测试平台恒时性写 E，不能以普通性能或无分支反汇编关闭这一前提。

### U16 对外缓冲区的中间写入审查

[#1909](https://github.com/pq-code-package/mlkem-native/issues/1909)于 2026-09-20 创建且开放，镜像维护者在 2026-05-08 提出的 [mldsa-native #1108](https://github.com/pq-code-package/mldsa-native/issues/1108)。原讨论是枚举临时外部缓冲区写入和完善接口约定的预防任务，并未确认当前 ML-KEM 有同样的泄露。当前自有调用在进程内独占缓冲、函数返回后消费，但仍须核对上游约定和写入生命周期（D/E）。不能将 ML-DSA 签名草稿或 shared-buffer 场景直接套成 ML-KEM 已确认漏洞。

### U17 clangover 作者与邮件、集成维护者公告

[作者仓库](https://github.com/antoonpurnal/clangover)及[2024-06-03 原始 pqc-forum 讨论](https://groups.google.com/a/list.nist.gov/g/pqc-forum/c/hqbtIGFKIpU/m/H14H0wOlBgAJ)记录旧 Kyber 参考消息编码在特定编译条件下的问题及编译屏障讨论。[liboqs GHSA-f2v9-5498-2vpp](https://github.com/open-quantum-safe/liboqs/security/advisories/GHSA-f2v9-5498-2vpp)于 2024-06-07 发布，明确其受影响范围至 0.10.0、0.10.1 起修正。它支持历史机制来源，不证明当前最终 FIPS 203 固定作品有漏洞。上游相关 #55/#460/#1342 与实际屏障分别核查（A/B）；本仓现有人工回归仍为人工案例，不升级为新发现。

### U18 KyberSlash 原论文与修订

[IACR ePrint 2024/1049](https://eprint.iacr.org/2024/1049)收到于 2024-06-28、修订于 2025-01-15，元数据标为 TCHES 2025 论文的 minor revision。作者包括 mlkem-native 维护者；公开研究支持检查秘密相关变延迟算术、采用有依据的修复及保持产物检查。受影响对象是论文所核旧 Kyber 实现和目标条件，不等于最终 ML-KEM 算法存在新弱点或本作品已复现。作者站本轮工具读取报错，未声称核对其后续网页更正；只读可访问的原论文元数据、摘要和版本信息，未执行或整理利用方法（A/E）。

### U19 集成关系与边界

[liboqs 0.13.0 发布记录](https://github.com/open-quantum-safe/liboqs/releases/tag/0.13.0)（2025-04-16）引入默认 mlkem-native；[Amazon 原始集成说明](https://www.amazon.science/blog/verifying-and-optimizing-post-quantum-cryptography-at-amazon)说明 AWS-LC 可替换 FIPS-202、随机源及清理函数，因此集成的保证和缺陷不能直接归于独立便携库。相关 [liboqs #2437](https://github.com/open-quantum-safe/liboqs/issues/2437)于 2026-05-19 提出错误码归一及派生入口后端问题；维护者 [#2521](https://github.com/open-quantum-safe/liboqs/pull/2521)于 2026-08-10 提出、2026-09-03 合并，明确只部分解决该 Issue，错误归一在集成 glue 中处理。它是集成 API 问题，cryProject 不链接 liboqs/AWS-LC（A）。本轮也读其公告列表，所列 HQC、LMS、XMSS、X.509、AES-CCM 等不属于本作品算法或依赖，未强归 mlkem-native；列表不构成所有集成均无 ML-KEM 问题的证明。

## 依赖与收口

实际参考目标依赖随库 C FIPS-202 和系统 C 运行时，普通随机源由自有封装接系统接口；未使用 liboqs、AWS-LC、自定义 FIPS-202、自定义分配、第三方 RNG、原上游开发 Makefile/测试下载脚本。CBMC、HOL Light、Z3、s2n-bignum 是上游证明/开发依赖，不能与本工程运行依赖混同。具体自有随机源、零化、错误处理和链接对象见适用性记录与本轮服务器证据。

预定类别已覆盖：标准/语义、编译器屏障、比较与选择、长度/内存、零化/分配、随机失败、接口/配置、架构/ABI、证明工具与硬件前提、集成误归及历史研究。资料跨检索已主要归入上述类别，进入工程核验，不继续扩展到无关算法或寻找漏洞数量。检索不覆盖非公开报告、需登录社区和不可读勘误，不能宣称找全漏洞。

公开社区入口中，pqc-forum 原始线程可读；未加入、登录或读取 PQCA Discord 的内部讨论。GitHub 部分动态区块出现加载提示，涉及的标题、正文及合并日期通过只读 REST API 交叉核对。NIST XLSX 和作者站的访问失败原样保留。检索结果仍需匹配固定源码、实际配置、机器及产物，前述来源审查不自动推出功能正确、硬件恒时或 R07 实际防护有效。
