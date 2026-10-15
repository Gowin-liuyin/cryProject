# 多泄漏模块平台完整完成条件

审计基线：`main@ac46e62`，2026-10-16。本文把
[平台计划](../多泄漏模块平台工程计划-20261016.md)的 Phase A–F 转为可核对的交付条件。
这是完整目标的验收清单，不是新的采数 PLAN，也不授权并行锁频。
上一轮 [HANDOFF](../../HANDOFF_DONE.md)的“8 路工作项完成”只覆盖启动分工；
M2 定位收口、M3/M4 独立夹具和 M5 接线不能替代完整平台完成。
新运行必须写入新证据目录；本文不改写任何已提交的旧证据或 M1 结论。

## 1. 状态与完成口径

- **已满足**：已有对应实际产物、命令与结果，可按链接核对。
- **部分**：存在前置实现或局部证据，但本行要求的运行/整合尚缺。
- **未满足**：没有该交付的实际结果，不能写“未检出”或“通过”。
- **条件项**：必须先检查触发条件；允许的降级要有实际阻塞证据与剩余交付，不能只写“可选”跳过。
- **可选**：计划明确允许不做；不作为完整必做目标的停止条件。

软件就绪、工具运行、定位成立、统计完成和竞赛验收分别记录。“统计完成”表示按冻结合同
执行和诚实解释，不要求每个真实历史实现都在这台 x86_64 上检出阳性。
M2 可以定位阳性、微基准阳性而完整解封装未检出；“未运行”始终不同于“未检出”。
M5 的阴性仅是有限输入、样本预算与产物范围内未检出，不证明恒时或总体误报率为零。

## 2. 贯穿所有阶段的门槛

| ID | 必须保留的合同 | 过关证据 | 当前情况与缺口 |
|---|---|---|---|
| G01 | 不做密钥恢复，不跑 exploit demo；真实案例和人工校准分列 | 各 RESULT 三句结论、运行入口及原日志 | 上轮保持；后续继续 |
| G02 | M1 vendor 与已有 liboqs010/tooling/r02-r04 结论只读，sources 只读 | 相对基线的保护路径 diff 为空；新证据新目录 | 上轮已满足；新提交继续核对 |
| G03 | 正式采数前冻结并本地提交 PLAN | 完整 PLAN commit、类对/预算/停止规则/家族及先后顺序 | M2 只有定位 PLAN；M2/M3/M4/M5 的时序 PLAN 均待新增 |
| G04 | 计时输入与目标功能成立 | 适用独立公开 KAT、边界/篡改/等价检查、普通与 sanitizer 分开 | M5 有功能资格；M2 完整 KEM 资格待做；M3/M4 挂载后须重验语义 |
| G05 | 唯一锁频任务，退出恢复 | boost=0、performance、约4300000kHz、taskset、进入/采中/退出日志、restore_match | 上轮无锁频运行；新模块逐次验，不能直接继承 M1 旧快照 |
| G06 | 原始计时可追溯 | 全量 CSV、乱序/种子/单位/时钟、源/工作区/ELF 摘要、ENV、调用边界、命令 | 新模块 raw 尚缺；普通长尾不删，工具派生输入另存 |
| G07 | 参数检验族与交叉工具分开 | PLAN 的 family_id/成员/α、有效参数 p 与 Holm 表；RTLF/dudect 独立列 | 统计软件已就绪；新模块尚无实际参数族与运行结果 |
| G08 | 远端 Cry 唯一物理边界 | 源、构建、缓存、临时、归档、工具存储与链接目标核查 | 旧定位轮已留证；新 SDK/opam/Docker 安装和新运行需重新核查 |
| G09 | main 本地模块提交，不 push | 必要检查、format-check、diff、模块 commit；身份按仓库约定 | 主控统一执行；本路不 stage/commit |

CPU2/CPU6 的锁频采数只能由主控串行调度。M3/M4 的人工挂载只能改变明确标注的目标机制，
保持密码输出语义和隐式拒绝；不能靠秘密输出、空转、随机延迟、跳过验证等取得阳性。
动态检查产物不能充当普通计时产物。

## 3. Phase A：平台骨架

| ID / 类型 | 明确产物与验收 | 命令入口 | 基线证据 / 状态 | 仍需做什么 |
|---|---|---|---|---|
| A01 必做 | 计划与架构可引用，标明模块、CSV、工具和证据边界 | CMD01 | [架构](ARCHITECTURE.md)、原计划，已满足 | 后续接口有变时同步当前架构，不改旧执行源 |
| A02 必做 | 六工具 clone、完整 commit/tree、获取与许可状态 | CMD02 | [REPOS](../../third_party/REPOS.md)，六库6/6，已满足获取层 | 工具实际运行分别由后续项验，不能用 clone 成功替代 |
| A03 必做 | 两类 CSV 经统一入口输出 CI/Welch、RTLF α=.01、明确 dudect 摘要；错误/缺依赖不伪成功 | CMD03 | [统计说明](../../scripts/platform_stats/README.md)、[S05](../evidence/platform-matrix-20261016/partials/S05.md)，软件接口已满足 | 原生在线 dudect 是模块后续交叉实验；CSV 离线回放不等于在线采集 |
| A04 必做 | 模块模板与平台矩阵；定位/统计/边界三句及明确未知状态 | CMD01 | [模板](../../templates/MODULE_RESULT.md)、[矩阵](../evidence/platform-matrix-20261016/RESULT.md)，已满足 | 最终结果逐模块填完，由主控更新新汇总 |

Mona 在 A03 可作为可选输出行；但完整计划的 Phase F 明确要求对照结果，见 F01。
A 阶段的“可选接线”不能作为跳过 F 阶段的理由。

## 4. Phase B：M2 KyberSlash

| ID / 类型 | 明确产物与验收 | 命令入口 | 基线证据 / 状态 | 真实缺口 |
|---|---|---|---|---|
| B01 必做，允许既定替代 | 未修/完整已修固定源码、许可证、PIN、秘密路径与实际 div/idiv 对照 | CMD04 | [VERSION_AUDIT](../evidence/m2-kyberslash-20261016/VERSION_AUDIT.md)，已满足定位钉版；使用允许的 pq-crystals 路线 | 无须为凑 liboqs tag 重建已有效的历史路线 |
| B02 必做 | 原20250805补丁工具真实可用；同组秘密标记产物未修报警、已修对应消失；普通 Memcheck 对照 | CMD05 | [工具](../evidence/m2-kyberslash-20261016/varlat-tool/README.md)、[RESULT](../evidence/m2-kyberslash-20261016/RESULT.md)，已满足热点层 | 后续完整 KEM 若换 ELF，重新绑定工具与秘密范围，不能搬用旧日志 |
| B03 必做前置 | 完整历史 Kyber768 解封装接入同一测量协议；适用功能资格、合法输入/拒绝语义及实际链接核验 | CMD06 | 现探针仅直接调用三个热点，未满足 | 完整 KEM 适配/公开输入生成、独立资格、普通与动态构建、源/ELF/后端身份 |
| B04 必做 | 新正式 PLAN 固定主类对、预算、α、停止/复测及家族，先提交再启动 | CMD07 | 旧 PLAN 明确 m=0 且不采时间，未满足时序合同 | 不能把旧定位 PLAN 倒写成新采数合同 |
| B05 必做 | 未修/已修完整解封装锁频采集与 CI/Welch+Holm、RTLF、原生在线 dudect 对照 | CMD08/CMD09 | 没有 M2 时间 CSV，未满足 | 新 raw/ENV/频率恢复/工具输出、参数族与复测；不能用合成数据或离线回放替代 |
| B06 条件项 | 若完整调用不区分，按合同补热点微基准，保留完整调用结果并分层 | CMD08/CMD09 | 未运行，条件尚未触发 | 若启动须先冻结窗口/类对/预算；不事后只挑显著热点，也不强求微基准一定阳性 |
| B07 必做 | 新 M2 REQUIREMENTS/PLAN/ENV/RESULT/raw/disasm/日志；适用时 holm/replication；平台行与报告同步 | CMD01/CMD10 | 旧目录只收口定位，部分 | 新结果目录完成整套交付；定位旧原件保持原字节 |

当前确定事实：未修 `a621b8d…`、完整已修 `272125f…`；Clang18/-Oz 三热点各有/无 div，
varlat=yes 为1280 errors/3 contexts 对0/0，no时两版0/0。默认报警PC不是实际 div 的精确地址。
这些事实支持固定热点定位，不支持这台处理器已经出现物理时差或完整 KEM 统计阳性。

## 5. Phase C：M5 阴性对照

| ID / 类型 | 明确产物与验收 | 命令入口 | 基线证据 / 状态 | 真实缺口 |
|---|---|---|---|---|
| C01 必做 | 固定 mlkem-native、完整 reference/measure 调用链、适用独立功能资格 | CMD06 | [PIN](../../vendor/mlkem-native/PIN.md)、[RESULT](../evidence/m5-mlkem-native-20261016/RESULT.md)，已满足前置 | 保留普通参考路径，不能误选人工补丁变体 |
| C02 必做 | x86_64 原生反汇编、秘密标记分支/地址检查，以及已就绪 varlat | CMD05 | 仅本机调用链、动态工具未运行，未满足 | 新原生产物与标记范围；公开依赖/工具命中逐项解释 |
| C03 必做 | 与 M1 同规程/主类对的锁频原值、CI/Holm、RTLF、原生在线 dudect | CMD07/CMD08/CMD09 | 未运行 | 冻结 PLAN，串行采数、预算内阴性或异常解释，进出恢复与复测 |
| C04 必做 | 三句 RESULT 判断有限范围内是否符合阴性预期；若阳性完成原因调查 | CMD10 | 当前只写前置，部分 | 主CI含0、Holm不拒绝、工具结果等必须来自真实运行；不能预填“通过” |
| C05 可选 | 修后 liboqs ref 作为第二阴性 | CMD06/CMD09 | 不是 M5 必做前置 | 主 mlkem-native 完成后再决定，无须为完成主目标强行新增 |

## 6. Phase D：M3 秘密访存校准

| ID / 类型 | 明确产物与验收 | 命令入口 | 基线证据 / 状态 | 真实缺口 |
|---|---|---|---|---|
| D01 必做 | 人工 LUT 开/关夹具，功能等价与边界；按模块原文挂载到解封装路径，保留“人工构造” | CMD06 | [现夹具](../../fixtures/mem_lut_leak/README.md)与[定位](../evidence/m3-memaccess-20261016/RESULT.md)仅独立字节变换，部分 | 现有独立夹具不能冒称 KEM 端到端；需自有挂载层及保持密码语义的等价资格 |
| D02 必做 | ctgrind/Memcheck秘密下标定位与产物检查，开/关实际日志 | CMD05 | 独立夹具地址32/1对0/0已满足局部定位 | 挂载后换产物须重验；旧固定输入一次检查不覆盖新路径 |
| D03 条件优先，可降级 | 有可用 Pin 时运行 Microwalk定位；无 Pin 时尝试满足Cry边界的可行路径，仍受阻可降级 | CMD11 | [NOTES](../evidence/m3-memaccess-20261016/NOTES.md)记录缺Pin/.NET，部分 | 保留探测、安装/运行状态、具体阻塞；降级至少保留ctgrind+人工夹具统计，不能填Microwalk成功 |
| D04 必做 | 冻结类对后开/关的同类输入锁频统计电池与复测；不能比较两个版本总成本冒称泄漏 | CMD07/CMD08/CMD09 | 无原始时间数据，未满足 | 选择能校准秘密地址机制的类对；若未检出如实解释并按计划审查是否需修正夹具/预算 |
| D05 必做 | 新 RESULT/ENV/raw/定位/家族等与平台行，人工校准独立于真实案例 | CMD10 | 上轮只写前置，部分 | 补完整运行包；不计为第三个上游CVE |
| D06 可选 | 有公告/固定提交的真实历史访存例 | CMD04 | 无，无须硬凑 | 不作为人工校准完成条件 |

## 7. Phase E：M4 比较/拒绝校准与有界验证

| ID / 类型 | 明确产物与验收 | 命令入口 | 基线证据 / 状态 | 真实缺口 |
|---|---|---|---|---|
| E01 必做 | 人工提前退出与恒时意图比较；相等性等价、封装边界与产物 | CMD06 | [夹具](../../fixtures/early_reject_memcmp/README.md)、[RESULT](../evidence/m4-compare-20261016/RESULT.md)，独立夹具已满足 | 若挂载KEM，另验隐式拒绝与完整语义；不宣称标准memcmp排序语义 |
| E02 必做 | ctgrind/Memcheck定位非恒时比较，关版对照与源码/ELF/日志关联 | CMD05 | Linux分支32/1对0/0，已满足局部定位 | 新入口/编译产物改变后重新核验 |
| E03 必做 | Binsec对抽出的compare/verify实际执行；保存入口/秘密模型/bound/退出/原日志，比较有反例与有界完整探索的对照 | CMD12 | [NOTES](../evidence/m4-compare-20261016/NOTES.md)仅环境探测与配置，未满足 | 缺工具不算完成；先小边界实跑。装载失败/超时/unknown仍是验证缺口，不写secure |
| E04 必做 | 定义端到端调用边界与两类输入，冻结后采数并跑统计电池与复测 | CMD07/CMD08/CMD09 | 未运行 | 若仅完整夹具调用须明确，不冒称完整KEM；若声称KEM端到端则必须实际接入并验密码语义 |
| E05 必做 | 新结果包与总表、报告的校准/有界结论，保留局限 | CMD10 | 上轮只写前置，部分 | 统计、形式化与定位各自分列，不互相替代 |
| E06 可选 | 将Binsec扩大到完整解封装，或增加真实TLS/KEM历史案例 | CMD12/CMD04 | 不作为小函数有界验证完成门槛 | 路径爆炸只限制扩大范围，不能免除E03小边界实跑 |

M4 “secure”必须同时说明入口、长度、秘密/公开模型、探索边界与求解器状态。
它不是任意长度、完整算法或所有编译器/微架构上的恒时证明。

## 8. Phase F：Mona、报告与平台图

| ID / 类型 | 明确产物与验收 | 命令入口 | 基线证据 / 状态 | 真实缺口 |
|---|---|---|---|---|
| F01 必做于完整Phase F | Mona对M1与M2主CSV给独立对照行，记录库/报告提交、输入、算法设置、原输出与摘要 | CMD13 | 仅clone，未满足 | 实际适配与执行；M2 raw须先完成B05。不能把工具缺失写阴性或把RTLF结果改名Mona |
| F02 必做 | 新正式报告版本含“检测—定位—修复—复测”章，实测表/图与证据一一对应 | CMD10/CMD14 | 旧正式报告封存；本路仅准备待填大纲，未满足最终正文 | M2–M5实测后填数、整合当前正式载体并审核；不覆盖旧DOCX/PDF |
| F03 必做 | 平台矩阵图与可重建源，分真实案例/人工校准/阴性和各层状态 | CMD14 | 旧架构/文字矩阵已有；本路新增基线状态SVG图源与预览，部分 | 最终据新结果更新图与图注，不能用基线状态图伪装全目标完成图 |
| F04 必做 | 当前deliverables入口、进度、平台总表及最终交接同步；复算路径/边界可读 | CMD10/CMD14 | 上轮交接只覆盖启动分工，部分 | 主控更新当前入口；旧交接保留历史时点，新增完成交接与本地提交清单 |

Constantine 属于计划明确的防护探索选项，不替代上游官方修复，也不是完整平台的必做门槛。
全套工具对所有模块做无差别形式化/轨迹验证并非原计划要求；按上表的机制与工具适用范围执行。

## 9. 命令索引与执行边界

本节是验收命令合同，不表示本路已运行。已存在的入口给出可核对命令；新增入口尚未实现时
使用占位符并明确不得照抄执行，最终模块 PLAN 必须换成固定实际路径/参数/摘要。
远端一切工作/临时/缓存路径均位于 `/home/nss-marker/yhr/Cry/<new-run>`。

| 编号 | 命令/检查合同 | 成功判断 |
|---|---|---|
| CMD01 | 文档链接/模板/当前矩阵与`git diff --check`；保护路径diff | 引用可达、状态有证据、旧结论未改；Markdown本身不算实验 |
| CMD02 | 每库`git -C third_party/<repo> rev-parse HEAD`、`status --porcelain`、`fsck --full --no-reflogs` | 完整身份与获取日志；许可证状态如实，不将未知许可代码直接打入新分发包 |
| CMD03 | `cmake -S . -B build/platform-completion -DBASELINE_ENABLE_PLATFORM=ON -DA113_ARCHIVED_CASE_ONLY=OFF`；build `platform_stats`；CTest `^platform_stats_battery$` | 合成手算、非法值/覆盖拒绝、真实上游正负接口校准；不能代替模块采数 |
| CMD04 | `version-audit/fetch_vendor.sh`与该目录CMake，固定clang-18；目标反汇编+PIN核对 | 完整上游快照/许可/实际secret-div数据流，不修改M1树 |
| CMD05 | 补丁Valgrind显式`--variable-latency-errors=yes/no`，或Memcheck secret harness；实际命令以模块PLAN为准 | 原始退出/命中栈/秘密标记/源及ELF摘要；无能力时不静默降级 |
| CMD06 | `cmake --build <new-build> --target <module-target>`；`ctest --test-dir <new-build> -R <module-tests>`，普通/动态隔离 | 目标/测试名在实现后冻结；未有目标不虚构构建成功 |
| CMD07 | `git show <PLAN_COMMIT>:<PLAN_PATH>`与冻结清单核对 | 主控先提交类对、预算、假设族及样本/复测规则；旧m=0计划不覆盖新采数 |
| CMD08 | `<reviewed-lock-runner> <fixed-collector> ...` | 占位命令，不可直接执行；先核定当前硬件与恢复，单任务，进出restore_match |
| CMD09 | `scripts/run_stats_battery.sh --input <raw.csv> --format measure --classes <class0> <class1> --output-dir <new-output> --stats-bin <fixed-ELF> --dudect-log <online-log>`；按PLAN另做Holm | raw/派生/工具身份一致；dudect日志另核在线来源；RTLF α=.01，dudect不进族 |
| CMD10 | 新目录各`RESULT/ENV/PLAN/REQUIREMENTS`与适用`raw/holm/replication/disasm/logs`；逐项对账 | 未运行/未知/失败与真实数值分开；每模块三句结论 |
| CMD11 | 固定Microwalk/Pin环境探测、`<reviewed-microwalk-wrapper>` | 占位命令；成功给轨迹站点与原输出，否则按D03保存可复核降级 |
| CMD12 | `binsec -sse -checkct -sse-script fixtures/early_reject_memcmp/checkct.cfg -sse-depth 10000 -sse-timeout 120 ... <fixed-ELF>` | 实际装载/模型/边界/原日志；完整探索与截断/unknown明确分开 |
| CMD13 | `<fixed-mona-adapter> <module-main.csv> ...` | 占位命令；以工具原生接口冻结，保留源CSV到Mona输入映射和原始报告 |
| CMD14 | 新报告本地引用/数值/匿名/图源复建、实际载体渲染核对与最终索引 | 大纲不当最终章稿，计划图不当结果图；不改旧封存载体 |

不要求重跑已经有效的M1实验来制造“本轮全新”；若Mona新增分析M1，只读其固定主CSV，
新分析另存目录。R02/R04 旧限定结论只引用，不外推到尚未采数的新模块。

## 10. 完整完成判定

Phase A 的四项已具备软件骨架证据；B/C/D/E/F 仍有上述明确必做缺口。
完整完成至少要求：B03–B05/B07、C02–C04、D01挂载/D04–D05、E03–E05、F01–F04
有对应产物与真实执行；D03按触发条件完成Microwalk或可复核降级，B06按真实结果决定。
所有新运行同时满足G01–G09。可选项未做不阻止这一定义下的完整完成。

最终矩阵应把“已执行且未检出”和“未执行”分开，把正式统计与工具定位分开。
即便全部软件/实验交付完成，也不能自动替代比赛方的材料审核、本人签署或官方验收。
本轮S1的报告准备见
[证据驱动大纲](../../deliverables/research/platform-completion-20261016/REPORT_OUTLINE.md)。
