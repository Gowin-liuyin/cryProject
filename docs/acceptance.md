# 第一阶段完成验收

验收范围来自最初的 A1-13 第一阶段实现要求，以及后续“CMake 一定要写好”的要求。
范围仍是 C11、ML-KEM-768 单机基线，不包含完整统计检测平台、最终防护、密钥恢复或 STM32。
本次逐项核对当前源码、测试实际覆盖、Git 历史、原始数据和实际机器码，不仅使用测试通过状态。

最终功能源码提交：`203eb253941e7d2b69c421d9d9f9eae79d186089`。
该提交在干净工作区、全新 build/completion 目录使用 CMake/Ninja/RelWithDebInfo 构建。
后续验收归档提交只增加证据和文档。原 Make 和早期 CMake 的证据保持原身份，未套用于新产物。

| 原始要求 | 当前证据与结论 |
|---|---|
| 仓库、main、保留修改、正确身份、模块提交、不 push | 本仓库初始远端为空；当前 main；Git 历史含六模块及有说明的修复/构建迁移提交。所有作者和提交者均为 Gowin-liuyin、用户确认的 yinhaoran0808@outlook.com；只设置本地配置。未强制重置或改写历史，未 push。 |
| 开工检查及只读参考边界 | 已读取适用 AGENTS 和项目计划；代码知识图谱工具未提供，回退文件检查；工程位于独立目标仓库，项目镜像 sources 未修改。环境在每次采集 meta 中记录。 |
| C、命名、注释和最小结构 | 系统运行、输入生成、随机源、计时、密码检查和数据记录校验为 C11；自有标识符使用明确名称。短脚本只承担构建身份、向量格式转换和测试命令编排，无 Python/Rust/C++ 系统实现。vendor 保留原命名及许可证。 |
| 固定实现来源、许可、规范和参数 | docs/sources.md 固定 mlkem-native 完整提交和 FIPS203 口径；本次再次比对 vendor 与该上游快照，内容相同。主参数仅 768。 |
| 功能正确与独立测试答案 | tests/test_mlkem.c 逐字节比较原始 NIST 输入/独立预期：25 keygen、25 encaps、10 decaps、20 key checks，每版 80 组；解封装含 5 个标准隐式拒绝。JSON、转换方式、摘要完整保存。 |
| 系统随机源及错误处理 | src/random.c 使用系统 /dev/urandom，处理 EINTR/短读/失败；普通 API 不接受测试种子。两版真实文件描述符耗尽测试确认随机源错误传播及恢复；临时秘密种子清理。 |
| 包装层边界及不泄露状态 | src/mlkem.c 对各公开指针和精确长度先检查；tests/test_mlkem.c 覆盖空指针及错误长度。正确长度无效密文不返回内部重加密结果；普通 CLI 不打印私钥、共享密钥或内部标志。 |
| 单一机制回归、密码语义保持 | 独立 message-branch.patch 只替换消息编码函数；为保留分支使用该函数的优化控制。没有延迟/空转/越界/固定拒绝密钥；源码和补丁确认重加密比较、J(z||c)、隐式拒绝未改。 |
| 两版本功能等价和链接隔离 | 两个独立静态库与可执行文件；CMake 编译命令确认缺陷内核使用派生副本。64 个固定种子 × 有效/位翻转/随机三类 = 192 次差分检查，另核对拒绝输出 J(z||c)。 |
| 源码秘密依赖与实际二进制机制 | docs/defect.md 解释 m' 从私钥解密到重加密编码的依赖。completion/vulnerable-path-arm64.txt 核对实际完整调用链及消息位控制 tbz；reference 编码使用局部算术选择，不将局部结果当作全库恒时证明。 |
| CLI、自检、输入生成及可复现 | 参考/缺陷入口分别可执行；自检和 demo 使用安全随机源；generate-test 与 decapsulate-test 明确使用公开测试种子。五类输入、文件长度、种子错误、拒绝覆盖均有集成检查；非法 run_id 现明确报错并返回 2。 |
| 标签来源和机制构造边界 | valid/bit-flipped/random/message-zero/message-ones 均由生成器登记，不读取内部验证标志；机制类来自 Encaps_Internal 的已知消息，仅作审计，不宣称未知密钥攻击。 |
| 完整 C 计时、窗口边界、结果保留 | src/measure.c 预分配并生成全部输入；CLOCK_MONOTONIC + C11 屏障计时完整包装层调用；窗口外消费输出，整批结束写文件。最终反汇编确认解封装调用未删除、结果消费在终点后。 |
| 随机顺序、原始值、单位及追溯 | 五类等量，SHAKE/Fisher–Yates 顺序可复现；全部原始值保留；meta 记录纳秒单位、1000ns 时钟分辨率、真实 CPU、种子、编译器/选项、干净源码版本、输入摘要及实际二进制摘要。独立 OpenSSL 摘要与 meta 一致。 |
| CMake、干净构建与动态检查 | CMake 是唯一规则来源，Make 仅转发。当前干净构建的 8 项 CTest 全通过；修复后的独立 ASan/UBSan 同样通过。此前 Makefiles/Ninja/多配置及补丁增量检查证据保存在 evidence/cmake。 |
| 文档和后续入口 | README 给出构建、自检、选择实现、生成输入、采集命令；sources/defect/timing/validation 分别说明来源、机制、计时和检查。后续检测读取 CSV/meta；后续防护针对独立编码补丁重新验证。 |

## 最终证据入口

[evidence/completion](evidence/completion/README.md) 保存本次干净 CMake 构建日志、测试结果、
两版各 500 条原始时间、运行元数据、独立摘要核对和反汇编。此前各 5000 条数据属于原 Make
产物，保留在 evidence/final，不能混入当前配置统计。

功能验证通过、目标源码/机器码机制存在、原始时序已采集是分别核实的三个结论。
未宣称已观察到可靠时间差异，未进行正式统计确认，未证明参考版完全无泄露。

## 环境允许的交接项

原始要求明确允许当前仅有 macOS/其他架构时完成可移植代码和功能验证，并如实记录目标环境缺口。
因此真实 x86_64 Linux、GCC 产物分支及受控主机正式统计属于已说明的后续验证，不伪装成本次实测。
当前第一阶段软件交付与本机验收已完成；这些环境边界不改变原定范围，也不代表整个竞赛已完成。

## 追加验收：统计确认、恒时对照与 Linux/GCC

以上逐项核对对应第一阶段交付，结论按当时的证据成立，不因后续工作改写。
按用户后续的推进要求，又完成三件事，均按同一标准逐项留证：

| 追加要求 | 当前证据与结论 |
|---|---|
| 从 CSV/元数据接入统计检测 | 新增只读取 CSV 的 C 程序 `analyze`：比较族、显著性水平和统计量全部写死在源码中，采集前即固定；报告含每类分位点、每个比较的 Welch t 与并列修正 Mann-Whitney U、Bonferroni 校正结果和被分析 CSV 的 SHA3-256。CTest 用解析上可算出答案的合成数据检查实现，并覆盖畸形输入拒绝。见 [statistics.md](statistics.md)。 |
| 正式统计确认 | 两个公开种子各采集两版、每版 25000 条：参考版两次 0/10 显著，缺陷版两次 7/10 显著，主效应为恒定消息类与变化消息类之间的 711–800ns、效应量 0.819–0.844。证据 [evidence/statistics](evidence/statistics/README.md)。 |
| 从独立编码补丁接入防护 | 新增 hardened 变体与独立恒时补丁，保留与缺陷版相同的函数级优化控制和循环结构，只去掉分支；三变体同种子同顺序各 25000 条：缺陷版 6/10 显著、防护版与参考版各 0/10，防护版类别均值极差已小于参考版自身。功能上 hardened 通过同一组 NIST KAT、随机源失败和与参考版逐字节等价检查。证据 [evidence/mitigation](evidence/mitigation/README.md)。 |
| Linux 与真实 GNU GCC | 在 linux/arm64 容器用 GCC 13.3.0 对干净提交实测：零警告构建、13 项 CTest 通过、两个补丁的 GNU 分支与 `/proc` 代码路径首次执行、三变体 GCC 产物反汇编确认机制形态。容器时钟分辨率 1ms，不产出时序证据。证据 [evidence/linux-gcc](evidence/linux-gcc/README.md)。 |

追加部分仍然不含：真实 x86_64 Linux 主机实测、未知密钥攻击、密钥恢复、完整统计平台、
GUI、网络攻击、STM32 或多算法框架。防护版是对照实验用的最小补丁，不是可交付的加固实现。
下一阶段入口：在真实 x86_64 Linux 主机上重跑同一组功能检查、采集与固定检验，
并对打开优化后的恒时编码逐个反汇编确认。

## 追加验收：四模块收尾（可部署变体、x86_64 产物形态、多种子预注册、检查补齐）

以上各节记录各自当时的状态，**本节只追加，不改写它们**。本轮按先写定的设计契约
串行执行四个模块（模块零预注册入库 → 模块一 → 二 → 三 → 四），本节逐项给出要求、
证据入口与结论，并把仍不包含的内容单列。

### 预注册凭证与其强度边界

**模块零提交**：`adf9db9d2734837de11274343d3828d49d0f2444`
（`docs: pre-register the four-module design and its reviews`，diff 只含
`docs/tasks/four-module-design.md` 一个文件）。本轮四个模块的目标、可执行验收标准、
证据清单、诚实性边界，以及模块三第二轮的假设文本、统计形式、显著性水平、种子清单与样本量，
全部由该提交固定在 [四模块设计](tasks/four-module-design.md)；该文件自模块零提交起不再修改。

下面这段是设计文件篇首规定的定型文字，三处落点措辞必须一致，此处为其中一处（另两处为
`evidence/statistics-multiseed/README.md` 与本节「最终报告」的「未闭合项」单列）：

> 第二轮假设在新种子采集开始之前已以文字形式固定并入库（提交
> `adf9db9d2734837de11274343d3828d49d0f2444`）。
> 本仓库是**本地仓库**：从未 push，`origin/main` 实测为 `gone`，没有任何第三方时间戳，
> 提交日期可由作者设置。因此这是**作者自证的顺序**，只支持「这份假设文本的入库早于
> 任何第二轮采集提交」这一本仓库历史内的相对关系，**不是可向第三方证明的预注册**。
> 更强的凭证需要公开推送或外部时间戳服务，属本阶段范围之外，按 0.5 记为未闭合项。

`68ba0c3` 是模块零之前的**修订前草稿**提交（当时仍带全部阻断发现，并在文内自我声明
不构成预注册凭证），引用凭证时不要指向它。

### 来源引用的限制

第一、二轮设计评审的**原文件已被后续轮次写在同一路径上覆盖、不可恢复**，
只以 [四模块设计](tasks/four-module-design.md) 第 7、8 节的逐条摘要形式留存，无法再逐字复核。
`docs/tasks/design-review.{md,json}` 的内容是**第三轮**设计评审，自模块零提交起冻结。

设计 0.1 规定模块零之后各轮评审产物写入互不覆盖的
`docs/tasks/review-m<模块号>-r<轮次>.{md,json}`。**实际落点与该规定不同，照实记录**：
本轮四个模块的评审产物由评审环节写在未跟踪目录
`.agents/tasks/four-module-review/review-m{0,1,2,3}.{md,json}`，`.agents/` 全程未提交，
因此它们**不是仓库内的可追溯产物**。四份评审的判定均为 `APPROVED`、无阻断发现
（模块零 3 NIT、模块一 1 MEDIUM + 6 NIT、模块二 5 NIT、模块三 7 NIT），
但这一结论只能由作者转述，按 0.5 记为未闭合项。

### 逐项核对

| 本轮要求 | 当前证据与结论 |
|---|---|
| 模块一：不带函数级优化控制的掩码编码在正常优化下还剩不剩分支 | 新增第四个变体 `deployable` 与独立的 [值屏障掩码补丁](patches/message-value-barrier.patch)：在防护版写法上去掉 `optnone`/`O0`，交由 `-O2`。实测它被**内联进 `mlk_indcpa_enc`**，因此结论对象是调用者里的内联段而不是独立符号；该内联段只剩一条按系数计数器的循环回边，没有消息位相关分支。功能上通过同一组 80 组 NIST KAT（含 5 组隐式拒绝）、随机源失败传播、64 种子 × 三类与参考版逐字节等价、五类 CLI 测试密文逐字节一致。同一次采集会话内 hardened 的 `optnone` 代价（本次 238ns）在 deployable 上消失；第一轮固定族 0/10 显著。证据 [evidence/deployable](evidence/deployable/README.md)。 |
| 模块二：x86_64 指令集下的产物形态（明确不是时序证据） | 在 **QEMU 模拟的 `linux/amd64`** 容器用真实 GNU GCC 13.3.0 对干净提交实测：零警告构建（严格警告 + `-Werror`）、16 项 CTest 全部通过、三个补丁在 GNU patch 2.7.6 下无 fuzz 应用。缺陷变体的秘密相关分支在 x86_64 下表达为 `and $0x1` + `test` + `je`，与 ARM64 GCC 的 `cmp` + `b.eq`、ARM64 Clang 的 `tbz` 并列记录；hardened 与 deployable 的 x86_64 产物同样只剩循环边界分支（`jbe` / `jne`）；deployable 在 GCC 13.3.0 / `-O2` 下**同样被内联**，是独立于 ARM64 的第二次实测。证据 [evidence/linux-amd64](evidence/linux-amd64/README.md)。 |
| 模块三：诚实处理第一轮主比较的失败 + 第二轮预注册 + 多种子稳健性 | 第一轮预注册的主比较 `message-zero:message-ones` 在五个全新公开种子上**并未稳定成立**：缺陷版仅 4/5 显著、均值差 −11.4 至 −81.4ns，约为第二轮主效应的十分之一量级。该失败照实记录，没有改阈值、没有换种子重来。新增独立程序 `analyze_groups` 执行第二轮单比较（方向恒定组 vs 方向变化组，水平 1e-3），不改动第一轮族；五个新种子 × 四个变体各 25000 条的结果：缺陷版 **5/5 显著**（−663 至 −776ns）、参考版与可部署版各 **5/5 不显著**、防护版 **4/5 不显著、1/5 显著**（残差 −30 至 −13ns、方向一致）。种子 777 的原口头复核在本仓库不可复现，另做可复现的动机复采并列呈现、不替换原值、不进任何计数。证据 [evidence/statistics-multiseed](evidence/statistics-multiseed/README.md) 与 [statistics.md](statistics.md) 的多种子章节。 |
| 模块四：新增自有代码的检查补齐 | 全新构建目录 `build/review-four-module`（Ninja / RelWithDebInfo）干净重新构建，零警告；`ctest -N` 实测 **18 项**、全部通过；独立 sanitize preset 同样 **18 项**全部通过，无 ASan/UBSan 报告。Apple Clang 21 静态分析首次覆盖 `src/analyze.c`、`src/analyze_groups.c`、`src/timing_statistics.c`，并首次覆盖 `-DBASELINE_HARDENED=1` 与 `-DBASELINE_DEPLOYABLE=1` 两个宏设置，四次调用全部 `exit=0` 且无诊断，因此**没有产生修复提交**。`format-check`、`cmake-format 0.6.13 --check`、全部 `tests/*.sh` 与 `tools/*.sh` 的 `sh -n` 均通过。四个变体 `measure` 自报的 `executable_digest` 与独立 OpenSSL SHA3-256 逐个一致。证据 [evidence/review-four-module](evidence/review-four-module/README.md)。 |

### 最终报告

本小节是本轮的最终报告，按设计第 5 节的固定排列给出，六类分开写，不合并成「验证通过」。

**1. 功能正确。** `ctest -N` 实测 **18 项**，在 `build/review-four-module`
（Ninja / RelWithDebInfo）与 `sanitize` preset（Unix Makefiles / Debug / ASan+UBSan）
两套配置下各全部通过。覆盖四个变体的 80 组 NIST KAT（25 keygen、25 encaps、10 decaps、
20 密钥校验，解封装含 5 组标准隐式拒绝）、四个变体的随机源失败传播与恢复、
三组对参考版的差分等价（各 64 种子 × 三类输入，拒绝样本另核对 J(z∥c)）、
CLI 五类输入与错误边界、采集记录校验、两轮统计程序的合成数据与畸形输入拒绝、
第一轮归档报告的逐字重放、向量读取与向量完整性。
预期答案不由被测实现生成。证据：`evidence/review-four-module/ctest.log`、
`evidence/review-four-module/sanitize-ctest.log`。

**2. 源码秘密依赖。** 解封装路径是 `dec → indcpa_enc`（隐式拒绝所需的重加密）
`→ poly_frommsg`，编码函数的输入消息 `m'` 来自私钥参与的解密，因此缺陷变体按消息位执行的
`if/else` 分支条件具有秘密依赖。该依赖是**源码层面**的事实，机制说明见
[defect.md](defect.md)。上游 `mlk_poly_frommsg` 本来就是无分支实现（值屏障 + 恒时选择），
所以防护版与可部署版都不是「修复」，也不比参考版更安全。

**3. 产物机制。** 分两类，各自注明证据粒度：

- **ARM64 实测**（Apple Clang 21 / `-O2` / Ninja / RelWithDebInfo）：reference、vulnerable、
  hardened 的结论对象是**独立符号**的反汇编；deployable 被内联，结论对象是
  **调用者内联段**的反汇编，调用者层级取 `indcpa_enc`（`mlk_poly_frommsg` 在全 vendor 的
  唯一调用点在 `mlk_indcpa_enc` 内）。证据 `evidence/deployable/`、`evidence/final/`。
- **模拟 amd64**（GNU GCC 13.3.0 / `-O2` / 容器内默认 Unix Makefiles）：同样是 reference、
  vulnerable、hardened 为独立符号，deployable 为 `baseline_native_indcpa_enc` 里的内联段，
  调用者层级同为 `indcpa_enc`。证据 `evidence/linux-amd64/`。
  这是 **QEMU 模拟**，解释器实测为 `/usr/bin/qemu-x86_64`，不是真实 x86_64 主机。

两类都确认：缺陷变体保留消息位相关条件分支（ARM64 Clang `tbz`、ARM64 GCC `cmp`+`b.eq`、
x86_64 GCC `and $0x1`+`test`+`je`），hardened 与 deployable 只剩循环边界分支。
地址与反汇编结论不跨构建复用。

**4. 原始数据。** 本轮新增两批，都用 `CLOCK_MONOTONIC`、单位纳秒、本机时钟报告分辨率
1000ns，全部原始值保留、普通长尾未删：

- 模块一：四个变体各 25000 条（每类 5000），种子 `20260930`，`build/deployable`（Ninja /
  RelWithDebInfo），存 `evidence/deployable/{variant}.csv` 与 `.meta`。
- 模块三：四个变体 × 五个预注册公开种子（`31337`、`90210`、`8675309`、`20261111`、
  `141421356`）各 25000 条，共 20 份；另有四份种子 777 动机复采各 10000 条，
  标 `prespecified=no`、不进计数。存 `evidence/statistics-multiseed/`。

模块二的容器采集只保留 `.meta` 作为平台记录，CSV 与报告不归档、`analyze` 未运行。
模块四的小样本 `measure`（每类 50）只用于摘要对照，明确不作为统计材料，CSV 与报告不归档。

**5. 观察差异（描述性）。** 第二轮分组比较下，缺陷版方向恒定组比方向变化组快
**663–776ns**（五个新种子），与归档两次采集的 711–800ns / 690–824ns 同量级；
效应量 `effect_size_first_greater` 0.1557–0.2481。防护版残差 **−30 至 −13ns**、方向一致；
可部署版 −13.8 至 +52.3ns，无一致方向。同一次采集会话内 hardened 的 `optnone` 代价为
238ns，deployable 上消失。以上是描述性数值，不是攻击成功率。

**6. 正式统计确认。** 分三部分，不混为一句：

- **第一轮族（含其预注册主比较的失败）**：10 个类别对、族水平 0.001、单比较 1e-4。
  归档采集上参考版 0/10、缺陷版 6–7/10 显著。但**预注册的主比较
  `message-zero:message-ones` 本身未稳定成立**：五个新种子上缺陷版仅 4/5 显著、
  均值差 −11.4 至 −81.4ns。该失败如实保留。
- **第二轮预注册结果**：单比较、水平 1e-3，假设与种子清单由模块零提交固定。
  缺陷版 5/5 显著，参考版与可部署版各 5/5 不显著，防护版 4/5 不显著、1/5 显著。
- **多种子稳健性**：第一轮族在五个新种子上，参考版与可部署版 5/5 都是 0/10；
  防护版 4/5 为 0/10、1/5 为 1/10。两轮的阈值宽严相差 10 倍、假设也不同，
  **不得**把第二轮成立读成对第一轮同一假设的更强证实。

#### 本次新确立的结论（逐条附证据路径）

1. 掩码写法在**不带函数级优化控制**时，经 `-O2` 编译后实际执行的代码里没有消息位相关条件
   分支——代价是它会被内联，证据粒度降为调用者内联段。`evidence/deployable/README.md`
2. hardened 相对参考版的整体速度代价来自保留的 `optnone`，去掉它即消失（同一会话 238ns）。
   `evidence/deployable/README.md`
3. 目标机制在 x86_64 指令集下同样保留，并给出 GCC 的 `and`+`test`+`je` 与 ARM64 两种印法的
   对照。`evidence/linux-amd64/README.md`
4. 第一轮预注册的主比较不是稳定效应；把差异归到「消息位方向恒定 vs 方向变化」比归到
   「全 0 vs 全 1 两条分支」更稳定。`evidence/statistics-multiseed/README.md`
5. 防护版残差不是随运行随机摆动，而是五个种子方向一致、量级十几到三十纳秒的小残差，
   其中一个种子越过第二轮阈值；可部署版在这五个种子上没有该残差。
   `evidence/statistics-multiseed/README.md`
6. 新增的三个自有源文件与两个首次使用的变体宏在 Apple Clang 静态分析下无报告。
   `evidence/review-four-module/static-analysis.txt`

#### 本次未闭合的项

1. **真实 x86_64 Linux 主机时序实测仍未执行。** 本轮的两次容器验证（真实 GCC 的
   `linux/arm64`、QEMU 模拟的 `linux/amd64`）时钟分辨率都是 1ms，都不产出时序证据。
   QEMU 模拟、容器、交叉编译、macOS/ARM 一律不得表述为真实 x86_64 Linux 实测。
2. **第二轮预注册只有本地顺序凭证、无第三方时间戳。** 定型文字逐字如下：

   > 第二轮假设在新种子采集开始之前已以文字形式固定并入库（提交
   > `adf9db9d2734837de11274343d3828d49d0f2444`）。
   > 本仓库是**本地仓库**：从未 push，`origin/main` 实测为 `gone`，没有任何第三方时间戳，
   > 提交日期可由作者设置。因此这是**作者自证的顺序**，只支持「这份假设文本的入库早于
   > 任何第二轮采集提交」这一本仓库历史内的相对关系，**不是可向第三方证明的预注册**。
   > 更强的凭证需要公开推送或外部时间戳服务，属本阶段范围之外，按 0.5 记为未闭合项。

3. **本轮四个模块的评审产物未进仓库**，落在未跟踪的 `.agents/tasks/four-module-review/`，
   与设计 0.1 规定的 `docs/tasks/review-m<模块号>-r<轮次>.{md,json}` 不一致；
   「四份判定均为 APPROVED、无阻断发现」只能由作者转述，不可从仓库逐字复核。
4. **第一、二轮设计评审原文件不可恢复**，只剩设计文件第 7、8 节的逐条摘要。
5. 防护版残差的**机制归因**未做分离实验；`read_cpu_model` 在真实 x86_64 Linux 上的
   `model name` 解析路径未被覆盖（模块二的 `/proc/cpuinfo` 是宿主 ARM64 内容）。

#### 新增提交数与 `ctest -N` 实测项数

本轮新增 **7 个**提交（模块零 1、模块一 2、模块二 1、模块三 2、模块四 1），
落在设计预计的 7–9 个区间内；模块四无需修复提交与格式提交，因此取下界。
`ctest -N` 实测 **18 项**，与设计「模块三后 18」的预期一致，未触发模块间依赖降级规则。

#### 每个模块提交的分支/作者/提交者/邮箱/hash 核对结果

全部在 `main`，作者与提交者均为 `Gowin-liuyin <yinhaoran0808@outlook.com>`，
`git config --local` 两项复核一致，未改写历史、未 `--amend`、未 push。
逐字输出见 `evidence/review-four-module/git-log.txt`。

| 模块 | 提交 | hash | 分支 | 作者／提交者 |
|---|---|---|---|---|
| 零（预注册凭证） | `docs: pre-register the four-module design and its reviews` | `adf9db9d2734837de11274343d3828d49d0f2444` | main | 均为 Gowin-liuyin `<yinhaoran0808@outlook.com>` |
| 一（A，代码） | `feat: add the deployable constant-time encoder variant` | `0cba2c70893f433eb6a17d798660c0f407a7f6db` | main | 同上 |
| 一（B，证据） | `docs: record the deployable variant evidence under normal optimization` | `343a6cb5934bf1241106e4f9742a74c3dae1e5a7` | main | 同上 |
| 二（证据） | `docs: verify the x86_64 artifact shape in an emulated container` | `c1ea9cac653ba16e55521864ab7e2c4fae09412f` | main | 同上 |
| 三（A，代码） | `feat: add the round-two pre-registered group test as a separate tool` | `268bab838d5cf8a4b0c9c8b6f5f8b144557de219` | main | 同上 |
| 三（B，证据） | `docs: record the multi-seed robustness and the round-two result` | `4ce21336e756bb9a1018e99819b4ae50440b0e78` | main | 同上 |
| 四（检查与收尾） | 本节所属提交 | 见 `evidence/review-four-module/git-log.txt` 与 `git log -1` | main | 同上 |

模块零之后本设计文件未被修订，因此不存在「预注册凭证提交 + 修订提交」并列的情形；
3.2 的第二轮假设内容自模块零提交起未被触及。

**未 push 的凭证**：`origin` 指向 `https://github.com/Gowin-liuyin/cryProject.git`，
但本地没有 `origin/main` 跟踪引用（`git branch -vv` 实测 `[origin/main: gone]`，
`git rev-parse --verify origin/main` 实测 `fatal: Needed a single revision`、`exit=128`），
因此本轮提交只存在于本地。本轮未执行 `git fetch`、未执行 `git push`。
更强的「远端没有这些提交」证据需要联网查询，超出本阶段范围，按 0.5 记为缺口。

#### 来源引用的限制（与本节首部同一句）

第一、二轮设计评审原文件已被覆盖、不可逐字复核，只以设计文件第 7、8 节摘要留存；
`docs/tasks/design-review.{md,json}` 是第三轮设计评审，自模块零提交起冻结。

### 仍不包含的内容与下一阶段入口

本轮之后仍然不含：真实 x86_64 Linux 主机时序实测、未知密钥攻击、密钥恢复、
完整统计检测平台、GUI、网络攻击、STM32 或多算法框架。
防护版与可部署版都是对照实验材料，**不是可交付的加固实现**；上游该函数本来无分支，
两者都不构成「修复」。「全部检查通过」只等于检查通过，不等于结论成立——
功能正确、源码秘密依赖、产物机制、原始数据、观察差异、正式统计确认是六个分别核实的结论，
每条仍绑定自己的证据目录。

下一阶段入口：在真实 x86_64 Linux 主机上重跑同一组功能检查、两批采集与两轮固定检验，
并对该主机上的四个变体重新定位机器码（deployable 预期仍需按内联段取证）；
若需要可向第三方证明的预注册，则需要公开推送或外部时间戳服务。
