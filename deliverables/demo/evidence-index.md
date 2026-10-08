# 结论与证据索引

核验日期：2026-10-07，A03补于2026-10-08。E01/E02/H01/C01–C04稳定编号保持；A01保留旧展示R01别名，
避免与官方R01混淆。U01/D01/N01/A02为本轮索引。A03是所有者授权的封存v3重跑，计入R11。
I01仍记录截图与审批签署缺口。历史34项和旧复算仍按原执行解释。

每项结论按八个字段直接链接原资料、数据、版本、日志、退出、成本与复算方法。
不同源码/平台/性质不拼成一次实验。链接是实际仓库相对路径；匿名副本转换路径前缀
与已记录身份字段，数字CSV保持原字节，内部原件保留，摘要清单另行核验。

公开资料→当前适用性→代码/产物→实际运行→统计观察→防护效果是不同证据等级。
当前为提交候选版。R11执行项见A03。R07新完整受控链、实际截图和审批签署仍缺，不宣称全部验收。


## U01 · 上游公开资料核查

状态：本轮资料审阅，不等于漏洞复现。

**对应要求：** R05/R06/R10；支撑实施依据与版本判断。

**结论与范围：** 有范围的公开检索，漏洞、一般缺陷、预防性加固、证明覆盖和使用限制分别记录。

**公开依据及适用性：** [逐条原链接、维护者确认、发布/修复/查阅日期与未知条件](../../docs/upstream-security-review.md)；无法读取的页面记访问限制。

**源码、构建与产物：** 固定b3ba7b32773e657dd37f6f87bce82528459ad8a4、ML-KEM-768便携C；[固定库/标准/许可证](../../docs/sources.md)；[当前版本审查](../../docs/current-version-defense-review.md)；上游main不能回填固定版本。

**机器、时间与执行者：** 资料审阅日期2026-10-07；执行者为作者代理。文献不是实际工程运行。

**原数据、日志与退出：** [集中检索记录](../../docs/upstream-security-review.md)；无新增密码计时或攻击原数据。

**分析与复算入口：** 回到公告、已关闭Issue/合并PR和更正核实；每条线索接D01适用性，不整理触发载荷/利用脚本。

**当前证据缺口：** 公开检索不证明找全问题；访问限制与未确认条件保留。

## D01 · 当前固定版本防护审查

状态：当前配置判断，不等于完整安全效果。

**对应要求：** R01/R05/R06/R10；编译与测量前提关联R02。

**结论与范围：** 接口、隐式拒绝、比较/选择、屏障、后端、随机源失败、日志/错误、清理及证明覆盖分类审查。

**公开依据及适用性：** [A–E适用性结论、代码依据及问题分类](../../docs/current-version-defense-review.md)；[公开原来源](../../docs/upstream-security-review.md)。未证明安全不等于确认漏洞。

**源码、构建与产物：** [固定库/标准/许可证](../../docs/sources.md)；[当前版本审查](../../docs/current-version-defense-review.md)；[实际封装](../../src/mlkem.c)；[便携配置](../../include/baseline_config.h)；[CMake配置](../../CMakeLists.txt)；实际链接/摘要见N01。

**机器、时间与执行者：** 本轮作者代理代码审阅；本地审查与真实Linux产物核验分开。

**原数据、日志与退出：** [实际修复/预防性加固与检查范围](../../docs/current-version-defense-review.md)；没有降级依赖或移除防护构造展示。

**分析与复算入口：** 必要修复用新提交，独立向量、接口、随机源失败及适用动态检查见N01；原件保留。

**当前证据缺口：** 局部代码/产物符合检查不推出全库恒时或防护有效；R07按H01缺口判定。

## E01 · 历史原生参考前置

状态：9000条普通参考记录。

**对应要求：** R01/R02/R03/R09。

**结论与范围：** 三次各3000普通记录、功能和动态检查；既有原生前置，非本轮新增。

**公开依据及适用性：** [固定库/标准/许可证](../../docs/sources.md)；[当前版本审查](../../docs/current-version-defense-review.md)；未改便携参考，人工机制材料不混入。

**源码、构建与产物：** 固定9d9554b；[实际编译命令](../../docs/evidence/native-reference-20261007/compile_commands.json)；[二进制摘要](../../docs/evidence/native-reference-20261007/binaries.sha256)。

**机器、时间与执行者：** Ubuntu24.04.4/x86_64、4vCPU KVM，作者代理；[环境](../../docs/evidence/native-reference-20261007/environment.log)；[资源/控制限制](../../docs/evidence/native-reference-20261007/execution-note.txt)。原时点见meta/外部日志，未记录的采集起止不补造。

**原数据、日志与退出：** [原CSV](../../docs/evidence/native-reference-20261007/20261006.csv)；[meta](../../docs/evidence/native-reference-20261007/20261006.meta)；[阶段成本](../../docs/evidence/native-reference-20261007/20261006.csv.cost)；[逐步退出](../../docs/evidence/native-reference-20261007/step-exits.tsv)；[全部三次摘要](../../docs/evidence/native-reference-20261007/SHA256SUMS)。

**分析与复算入口：** [原描述报告](../../docs/evidence/native-reference-20261007/20261006.summary)；audit inspect 原CSV 新描述.report。

**当前证据缺口：** 宿主频率/调度不可控；前置不证明防护、裸金属或192个可用核心。

## E02 · 历史同负载普通性能

状态：6块×3形态；54000正式记录。

**对应要求：** R02/R08/R09；普通负载开销与分位数。

**结论与范围：** 18次各3000正式+100预热；掩码对照均值差+101.959333333ns，正常优化−30.100666667ns；两个99%探索区间跨零。

**公开依据及适用性：** [固定库/标准/许可证](../../docs/sources.md)；[当前版本审查](../../docs/current-version-defense-review.md)；三种普通无分支形态，未采人工回归，不与旧ARM时间拼接防护前后。

**源码、构建与产物：** 固定0e8be6df6a0aafeb465f848dcd963505142fa96f；GCC13.3/O2/非sanitizer；[编译命令](../../docs/evidence/native-final-20261007/compile_commands.json)；[产物身份](../../docs/evidence/native-final-20261007/artifact-and-environment.log)；[真实反汇编](../../docs/evidence/native-final-20261007/reference-disassembly.txt)。

**机器、时间与执行者：** Ubuntu24.04.4/x86_64、4vCPU KVM、外部CPU2亲和性，作者代理；[外部采集日志](../../docs/evidence/native-final-20261007/performance-outer.log)。宿主频率/调度不可控；原时点保持，不补填记录。

**原数据、日志与退出：** [18次账本/退出](../../docs/evidence/native-final-20261007/performance/attempts.tsv)；[参考原CSV](../../docs/evidence/native-final-20261007/performance/ordinary-reference-block1.csv)；[meta](../../docs/evidence/native-final-20261007/performance/ordinary-reference-block1.meta)；[成本](../../docs/evidence/native-final-20261007/performance/ordinary-reference-block1.csv.cost)；[全部18套摘要](../../docs/evidence/native-final-20261007/SHA256SUMS)；普通长尾保留。

**分析与复算入口：** [全部均值/P50/P90/P99/区间/成本](../../docs/evidence/native-final-20261007/performance/performance.report)；audit performance-replay docs/evidence/native-final-20261007/performance 新报告；[方法与窗口](../../docs/product-workflow.md)。

**当前证据缺口：** 6对iid未证明，区间只探索；优化形态差别不全部归于防护代价，不判显著加速或安全有效。

## H01 · 历史人工防护案例

状态：正面观察、H1失败与残差并列。

**对应要求：** R04/R05/R06/R07/R10；本地白盒人工消息编码回归。

**结论与范围：** 单次族回归6/10显著、掩码0/10；后续H1仅4/5显著；H2回归5/5显著，掩码4/5未检出、1/5残差显著。仅展示单次正面结果不足。

**公开依据及适用性：** [历史来源和旧Kyber/FIPS203边界](../../docs/defensive-case.md)；[本轮资料审计与R07清单](../../docs/defense-evidence-gap.md)；上游目标原已无分支，是人工案例，非新部署漏洞。

**源码、构建与产物：** 单次源e8f55e763dbec41801a8d7c1e9fd4e10477ee816，多种子268bab838d5cf8a4b0c9c8b6f5f8b144557de219；[单次产物摘要](../../docs/evidence/mitigation/binaries.sha256)；[多种子产物摘要](../../docs/evidence/statistics-multiseed/binaries.sha256)；[实际编译命令](../../docs/evidence/statistics-multiseed/compile_commands.json)。

**机器、时间与执行者：** Apple M5/ARM64、Darwin25.6.0、Clang21，1000ns标称分辨率，无亲和性/频率控制；作者代理。meta只有整批保存Unix秒，实际采集起止UTC及全部历史逐步退出不齐。

**原数据、日志与退出：** [回归原CSV](../../docs/evidence/mitigation/vulnerable.csv)；[掩码原CSV](../../docs/evidence/mitigation/hardened.csv)；[残差原CSV](../../docs/evidence/statistics-multiseed/hardened-seed141421356.csv)；[残差meta](../../docs/evidence/statistics-multiseed/hardened-seed141421356.meta)；[功能日志](../../docs/evidence/mitigation/ctest.log)；[全原材料摘要](../../docs/evidence/statistics-multiseed/SHA256SUMS)；历史成本/尝试缺失保留。

**分析与复算入口：** [单次回归报告](../../docs/evidence/mitigation/vulnerable.report)；[掩码报告](../../docs/evidence/mitigation/hardened.report)；[H1失败报告](../../docs/evidence/statistics-multiseed/vulnerable-seed31337.report)；[H2残差报告](../../docs/evidence/statistics-multiseed/hardened-seed141421356.groups.report)；[全部20运行表](../../docs/evidence/statistics-multiseed/multiseed-summary.tsv)；audit replay只读重建40报告。残差p=1.42602e-05，优势概率effect_size_first_greater=0.488950，非Cliff差。

**当前证据缺口：** [R07可接受材料与具体缺口](../../docs/defense-evidence-gap.md)；相同顺序不证明微状态相同，重复密文不自动独立，并列修正不处理序列依赖；不显著不是恒时证明。

## C01 · 固定任务精确复算确认

状态：8任务48进程；尾计数一致。

**对应要求：** R04/R11/R12；统计检测与复现环节的专用复算成本。

**结论与范围：** 相同完整2^20交换、输入、统计量及整数尾计数；完整进程比值中位数0.001388504，仅固定任务流程效率。

**公开依据及适用性：** [SciPy强对照、条件与合同](../../docs/controlled-comparison-v1.md)；Gray更新及随机化数学是既有方法。

**源码、构建与产物：** 功能62674a0、冻结39e7e3e之后确认；[源码/真实程序摘要](../../docs/evidence/controlled-comparison-20261007/frozen-source-and-binaries.sha256)；[冻结清单](../../docs/evidence/controlled-comparison-20261007/pre-confirmation.SHA256SUMS)；SciPy1.16.3/NumPy2.3.5、vectorized、batch4096。

**机器、时间与执行者：** Apple M5/ARM64 macOS、Clang21，作者代理；[确认外部日志](../../docs/evidence/controlled-comparison-20261007/confirmation-outer.log)；完整研发起止未记录，不写闭合。

**原数据、日志与退出：** [任务原CSV](../../docs/evidence/controlled-comparison-20261007/confirmation-data/task-1.csv)；[任务计划](../../docs/evidence/controlled-comparison-20261007/confirmation-data/task-1.plan)；[全8输入与计划冻结摘要](../../docs/evidence/controlled-comparison-20261007/pre-confirmation.SHA256SUMS)；[48次时间/退出/计数账本](../../docs/evidence/controlled-comparison-20261007/confirmation-results/attempts.tsv)。

**分析与复算入口：** [原确认主报告](../../docs/evidence/controlled-comparison-20261007/confirmation-results/comparison.report)；audit analyze-pairs 任务.csv 任务.plan 新报告。每方法3次变化不是总体置信区间。

**当前证据缺口：** 不支持ML-KEM/纯内核加速、真实误报/检出优势或防护有效；R12整体仍部分。

## C02 · 有限合成模型校准

状态：40964份枚举；44份外部审计。

**对应要求：** R04/R11；有限统计模型与实现核验。

**结论与范围：** 零效应26/4096、38/4096；graded/delta4低检出353/4096；共同符号盲用2/2拒绝，实际CLI4/4证据不足。合成ns非密码时间。

**公开依据及适用性：** [有限人口与预算合同](../../docs/finite-calibration-v1.md)；不估计真实密码总体。

**源码、构建与产物：** 实际C源62dbe4cfb4a8c0d8480c7271e9214f74697f8f86；[源码/构建元数据](../../docs/evidence/finite-calibration-20261007/model/summary.report)；[实际产物摘要](../../docs/evidence/finite-calibration-20261007/binaries.sha256)；外部审计源4a82b5c。

**机器、时间与执行者：** C在Ubuntu/x86_64/4vCPU KVM，SciPy核验在Apple M5，作者代理；平台不合并速度；[开始UTC](../../docs/evidence/finite-calibration-20261007/calibration-start-utc.txt)；[结束UTC](../../docs/evidence/finite-calibration-20261007/calibration-finish-utc.txt)；[环境](../../docs/evidence/finite-calibration-20261007/environment.log)。

**原数据、日志与退出：** [全部原枚举行](../../docs/evidence/finite-calibration-20261007/model/raw.csv)；[C任务日志](../../docs/evidence/finite-calibration-20261007/calibration.log)；[阶段退出（pending是当时值）](../../docs/evidence/finite-calibration-20261007/status.meta)；[最终核验](../../docs/evidence/finite-calibration-20261007/verification.json)；[摘要](../../docs/evidence/finite-calibration-20261007/SHA256SUMS)。

**分析与复算入口：** [模型主报告](../../docs/evidence/finite-calibration-20261007/model/summary.report)；[44份审计报告](../../docs/evidence/finite-calibration-20261007/scipy-audit.report)；audit calibrate 新目录，原枚举行可逐字比较，任务时间与新源身份不要求相同。

**当前证据缺口：** 有限模型无Monte Carlo误差，不代表真实密码总体；拒绝签收不是误报降零。序列依赖、秘密归因和R07仍缺。

## C03 · 基线预导入成本复核

状态：既有8任务48次；中位比值0.001562070。

**对应要求：** R04/R11/R12；C01成本边界敏感性补充。

**结论与范围：** 基线就绪后24窗口49.704188s，C完整24进程0.079016s；导入就绪6.559904s另列；计数相同，非新独立确认。

**公开依据及适用性：** [预导入窗口合同](../../docs/warm-replay-supplement-v1.md)；C仍含自身启动，不外推纯内核/密码速度。

**源码、构建与产物：** 合同42206a8先冻结，源56373cbe74fea98fdaca2a3ff15bdff1a1b39aca；[源身份](../../docs/evidence/warm-replay-20261007/source-commit.txt)；[真实程序摘要](../../docs/evidence/warm-replay-20261007/programs.sha256)；[构建缓存](../../docs/evidence/warm-replay-20261007/CMakeCache.txt)。

**机器、时间与执行者：** Apple M5/ARM64、10逻辑CPU、macOS26.6.2、Clang21，作者代理；[环境](../../docs/evidence/warm-replay-20261007/environment.log)；[实际任务日志](../../docs/evidence/warm-replay-20261007/formal.log)；未隔离CPU。

**原数据、日志与退出：** [48次窗口/退出/计数账本](../../docs/evidence/warm-replay-20261007/formal/attempts.tsv)；[输入前摘要](../../docs/evidence/warm-replay-20261007/inputs-before.sha256)；[输入后摘要](../../docs/evidence/warm-replay-20261007/inputs-after.sha256)；[完整摘要](../../docs/evidence/warm-replay-20261007/SHA256SUMS)；原数据仍C01八份文件。

**分析与复算入口：** [预导入主报告](../../docs/evidence/warm-replay-20261007/formal/comparison.report)；精确判定同C01入口；窗口复测按合同固定依赖/新目录，不反复挑更快结果。

**当前证据缺口：** 两轮不能相减估导入；窗口非完整观察器端到端，完整研发成本未闭合。

## C04 · 真实参考时间后赋标签控制

状态：24576枚举；24份外部审计。

**对应要求：** R04/R11；固定参考时间的条件标签模型和资格工程。

**结论与范围：** 六块各4096标签，拒绝40/40/40/38/40/38，保留144原时间，无新密码调用；非原密文类别检验。

**公开依据及适用性：** [后赋标签合同](../../docs/reference-label-control-v1.md)；采集后标签不能倒填为原采集随机化。

**源码、构建与产物：** 合同2e00f39先冻结，正式采用ef20a33的导出；[完整导出/配置身份](../../docs/evidence/reference-label-control-20261007/qualified/control/summary.report)；[实际产物摘要](../../docs/evidence/reference-label-control-20261007/qualified/programs.sha256)；source_commit兼容字段是导出摘要前缀，非Git。

**机器、时间与执行者：** 正式C控制Ubuntu/x86_64/4vCPU KVM；外部数值核验Apple M5；作者代理；[实际环境](../../docs/evidence/reference-label-control-20261007/qualified/environment.log)；[任务日志](../../docs/evidence/reference-label-control-20261007/qualified/control.log)；E02原时间身份不改。

**原数据、日志与退出：** [24576原枚举行](../../docs/evidence/reference-label-control-20261007/qualified/control/raw.csv)；[144原时间/序号](../../docs/evidence/reference-label-control-20261007/qualified/control/selected.csv)；[最终数值/输入核验](../../docs/evidence/reference-label-control-20261007/verification.json)；[初版成本资格失败退出1](../../docs/evidence/reference-label-control-20261007/prototype/qualification-guard.exit)；[失败日志](../../docs/evidence/reference-label-control-20261007/prototype/qualification-guard.log)。

**分析与复算入口：** [条件主报告](../../docs/evidence/reference-label-control-20261007/qualified/control/summary.report)；[24份审计](../../docs/evidence/reference-label-control-20261007/scipy-audit.report)；audit reference-label-control docs/evidence/native-final-20261007/performance 新目录；[完整摘要](../../docs/evidence/reference-label-control-20261007/SHA256SUMS)。

**当前证据缺口：** 固定时间不要求iid，但仅后赋独立标签模型；不识别原依赖或密文关系、不补防护复测；初版失败保留。

## A01 · 历史作者新检出复算

状态：旧展示R01别名，不是官方R01。

**对应要求：** R11；旧R01展示标签现映射A01，官方R01仍为功能要求。

**结论与范围：** 固定fe68961新检出32项、40历史/普通/精确主表逐字一致；旧执行，不写成本轮重跑。

**公开依据及适用性：** [复算与源身份说明](../../docs/product-workflow.md)；原数据分别属于H01/E02/C01，不把复算器回填为被测源。

**源码、构建与产物：** [源码/执行类别](../../docs/evidence/final-self-reproduction-20261007/result.meta)；[新检出日志](../../docs/evidence/final-self-reproduction-20261007/clone.log)；[全部材料摘要](../../docs/evidence/final-self-reproduction-20261007/SHA256SUMS)。

**机器、时间与执行者：** author_proxy_clean_checkout；[原构建/平台配置](../../docs/evidence/final-self-reproduction-20261007/configure.log)；未记录的实际起止不补造。

**原数据、日志与退出：** [功能日志](../../docs/evidence/final-self-reproduction-20261007/tests.log)；[40报告重放](../../docs/evidence/final-self-reproduction-20261007/archive-replay.log)；[资格状态](../../docs/evidence/final-self-reproduction-20261007/guard.meta)。

**分析与复算入口：** [普通性能主表](../../docs/evidence/final-self-reproduction-20261007/performance.report)；[精确主表](../../docs/evidence/final-self-reproduction-20261007/exact.report)；audit replay、performance-replay、analyze-pairs各用原输入/新输出。

**当前证据缺口：** 这是当时的作者复算。后续新目录执行见A03。

## N01 · 本轮真实Linux工程验证

状态：GCC/Clang动态各34项；普通数据与工程身份已归档。

**对应要求：** R01/R02/R06/R08/R09/R11；工程、产物及普通负载事实。

**结论与范围：** 真实新目录GCC34项、Clang18 ASan/UBSan34项；23主步骤及1配置交叉核对退出0。普通18运行54000正式+1800预热，均值差+380.801722222/+504.065388889ns；两探索区间跨零，与E02旧图分开。

**公开依据及适用性：** [公开依据](../../docs/upstream-security-review.md)；[当前配置适用性](../../docs/current-version-defense-review.md)；工程通过不推出防护效果。

**源码、构建与产物：** origin_git_commit=2e94648d502a5441b4f042abd8f420a91146d7b7，source_export_manifest=da42366ce5912ebd1d2d87913c17d238c9f325c6ae178456a1b8d37bca6fcba3；[实际源码/产物摘要](../../docs/evidence/candidate-round-20261007/native/artifact-identity.log)；[构建选项](../../docs/evidence/candidate-round-20261007/native/build-configuration.txt)；[编译命令](../../docs/evidence/candidate-round-20261007/native/compile_commands.json)。

**机器、时间与执行者：** [实际系统/资源/限制](../../docs/evidence/candidate-round-20261007/native/environment.log)；Ubuntu24.04.4/x86_64/KVM、4vCPU、7993503744B RAM，作者代理、授权SSH。主要运行2026-10-07T16:18:45Z–16:19:13Z，配置交叉核对16:22:32Z；普通采集16:19:07Z–11Z，KVM不是裸金属。

**原数据、日志与退出：** [命令/UTC/退出账本](../../docs/evidence/candidate-round-20261007/native/step-exits.tsv)；[普通检查](../../docs/evidence/candidate-round-20261007/native/release-tests.log)；[动态检查](../../docs/evidence/candidate-round-20261007/native/sanitizer-tests.log)；[普通原CSV](../../docs/evidence/candidate-round-20261007/native/perf/ordinary-reference-block1.csv)；[meta](../../docs/evidence/candidate-round-20261007/native/perf/ordinary-reference-block1.meta)；[成本](../../docs/evidence/candidate-round-20261007/native/perf/ordinary-reference-block1.csv.cost)。

**分析与复算入口：** [本轮普通性能主表](../../docs/evidence/candidate-round-20261007/native/perf/performance.report)；[实际执行命令记录](../../docs/evidence/candidate-round-20261007/native-execution.sh)；与旧E02分别保存。

**当前证据缺口：** 宿主频率/调度不可控，6对iid未证明，普通性能只是探索；源码不含其后帮助与展示改动，新包另有源身份；无新时序触发/利用/恢复。

## A02 · 本轮作者代理旧数据复算

状态：40报告与四类主结果逐字一致；作者代理。

**对应要求：** R04/R08/R11；原数据可复算性。

**结论与范围：** 40历史报告、E02旧普通主表及精确主表逐字一致；40964有限模型、24576后标签原枚举行及144原时间逐字一致。只复算旧材料，非新独立确认。

**公开依据及适用性：** [原方法与入口](../../docs/product-workflow.md)；C02合成、C04后标签、E02普通用途不改。

**源码、构建与产物：** [本轮源码/产物](../../docs/evidence/candidate-round-20261007/native/artifact-identity.log)；[N01完整输入清单](../../docs/evidence/candidate-product-20261007/N01-source-inputs.sha256)；原被测身份由对应旧条目保留，复算器不替代它。

**机器、时间与执行者：** [Linux环境](../../docs/evidence/candidate-round-20261007/native/environment.log)；[真实起止/退出](../../docs/evidence/candidate-round-20261007/native/step-exits.tsv)；作者代理。

**原数据、日志与退出：** [本轮逐项数量/字节匹配核验](../../docs/evidence/candidate-round-20261007/native/verification.json)；[本轮匹配状态](../../docs/evidence/candidate-round-20261007/native/result.meta)；[有限模型原行重建](../../docs/evidence/candidate-round-20261007/native/model/raw.csv)；[后标签原行重建](../../docs/evidence/candidate-round-20261007/native/reference-control/raw.csv)；[144时间重建](../../docs/evidence/candidate-round-20261007/native/reference-control/selected.csv)。

**分析与复算入口：** [旧普通主表复算](../../docs/evidence/candidate-round-20261007/native/performance-old.report)；[精确主表复算](../../docs/evidence/candidate-round-20261007/native/exact.report)；[历史H2一份复算](../../docs/evidence/candidate-round-20261007/native/history/vulnerable-seed31337.groups.report)；只读旧资料。

**当前证据缺口：** 成功只支持已列旧材料可复算，不补真实防护效果或总体模型；2026-10-08的新目录重跑见A03。

## A03 · 封存 v3 授权代理重跑

状态：26步退出0；GCC与Clang动态各34项；五类主结果逐字一致。所有者指示计入R11。

**对应要求：** R11。评测人员可按同一封存包复现。

**结论与范围：** 包58d6a604、源清单601a1020共206项。历史报告、普通性能、精确主表、40964模型、24576后赋标签和144个原时间与封存原件逐字节一致。60条短演示只验证入口。

**公开依据及适用性：** [使用入口](../../docs/product-workflow.md)；方法与封存输入不改。不把短演示或复算成功写成防护效果。

**源码、构建与产物：** [版本](../../docs/evidence/author-proxy-v3-20261008/results/version.log) 标明 verified_source_export；[产物](../../docs/evidence/author-proxy-v3-20261008/results/artifact-identity.log)；[执行脚本](../../docs/evidence/author-proxy-v3-20261008/native-execution.sh)。

**机器、时间与执行者：** Ubuntu 24.04.4 / x86_64 / KVM / 4 vCPU，[预检](../../docs/evidence/author-proxy-v3-20261008/preflight.log)。2026-10-08T03:22:50Z–03:23:18Z。执行者是所有者授权的代理。

**原数据、日志与退出：** [26步账本](../../docs/evidence/author-proxy-v3-20261008/results/step-exits.tsv)；[GCC 34项](../../docs/evidence/author-proxy-v3-20261008/results/gcc-tests.log)；[Clang动态34项](../../docs/evidence/author-proxy-v3-20261008/results/clang-sanitize-tests.log)；[短演示CSV](../../docs/evidence/author-proxy-v3-20261008/results/live/data.csv)。

**分析与复算入口：** [执行记录](../../docs/evidence/author-proxy-v3-20261008/执行记录.md)；[说明](../../docs/evidence/author-proxy-v3-20261008/README.md)。比较日志为空表示与封存原件一致。

**当前证据缺口：** 运行当时的 result.meta 仍写 independent_human_execution=not_obtained，未回改。没有界面截图，没有新的R07采集，KVM不是裸金属。

## I01 · 截图及审批签署

状态：执行记录已计入A03。截图、审批意见、盖章和回执仍缺。

**对应要求：** 提交材料中的画面与审批。R11执行项不再放在这里。

**结论与范围：** 所有者授权的固定包执行见A03。实际界面截图和审批页签署没有新材料。

**公开依据及适用性：** [官方基础/项目附加尺度](../../docs/round-requirements-review.md)；[执行记录](../../docs/evidence/author-proxy-v3-20261008/执行记录.md)。

**源码、构建与产物：** 与A03相同的封存包和源清单。截图不改变产物身份。

**机器、时间与执行者：** 执行窗口和平台见A03。审批签署仍由所有者本人处理，本次没有代写意见或盖章。

**原数据、日志与退出：** [演示与截图说明](演示说明.md)。当前没有合格截图，不链接假画面。

**分析与复算入口：** A03的构建、34项检查、封存复算和60条短演示。

**当前证据缺口：** 不绘制假终端。编号已另有CACR2026EA16XZ报告；贡献、签名、意见、盖章及提交回执仍由所有者完成。

## 图源与交付入口

[完整要求状态](../../docs/full-work-acceptance.md) · [R07缺口](../../docs/defense-evidence-gap.md) ·
[原生可编辑PPT图源](figures/论文图源.pptx) · [实际演示说明](演示说明.md) · [支撑包入口](../support/README.md)。

native-performance.png是E02的18个真实运行均值数据图；replay-efficiency.png是C01/C03
成本边界数据图。两图来自原生PPT对象/工作簿及原C报告，非实际界面截图，不能填补R07。

## H01 · 真实原分布摘要

H01单次历史分布摘要，直接读取原报告category字段，不新增统计计算或合成曲线；两份各25000记录/每类5000，ns单位、1000ns标称分辨率。恒定消息两类各反复一个密文，次数不是独立密文数；普通长尾保留。源e8f55e763dbec41801a8d7c1e9fd4e10477ee816，Apple M5/ARM64。此表不能替代后续H1失败与掩码残差，也不关闭R07。

[回归原报告](../../docs/evidence/mitigation/vulnerable.report)；[掩码原报告](../../docs/evidence/mitigation/hardened.report)；[回归原始分布CSV](../../docs/evidence/mitigation/vulnerable.csv)；[掩码原始分布CSV](../../docs/evidence/mitigation/hardened.csv)；[旧分位数名称更正及依赖边界](../../docs/statistical-audit.md)。

| 历史形态 | 输入类别 | 记录数 | 中位数ns | P99 ns | 均值ns |
|---|---|---|---|---|---|
| 人工回归 | valid | 5000 | 15000 | 19000 | 15369.400 |
| 人工回归 | bit-flipped | 5000 | 15000 | 20000 | 15405.200 |
| 人工回归 | random | 5000 | 15000 | 20000 | 15355.200 |
| 人工回归 | message-zero | 5000 | 14000 | 19000 | 14581.000 |
| 人工回归 | message-ones | 5000 | 14000 | 19000 | 14665.200 |
| 掩码对照 | valid | 5000 | 14000 | 20000 | 14547.000 |
| 掩码对照 | bit-flipped | 5000 | 14000 | 20000 | 14537.000 |
| 掩码对照 | random | 5000 | 14000 | 20000 | 14550.400 |
| 掩码对照 | message-zero | 5000 | 14000 | 20000 | 14531.400 |
| 掩码对照 | message-ones | 5000 | 14000 | 20000 | 14552.400 |

## E02 · 全部18套原始记录

每格直接打开CSV、meta、阶段cost和日志；6块×3形态，各3000正式+100预热，不将单次调用当独立运行。

[全部均值/分位数/区间/成本主报告](../../docs/evidence/native-final-20261007/performance/performance.report)；[18次退出/父进程成本账本](../../docs/evidence/native-final-20261007/performance/attempts.tsv)；[实际环境/产物身份](../../docs/evidence/native-final-20261007/artifact-and-environment.log)。

| 块 | reference | hardened | deployable |
|---|---|---|---|
| 1 | [CSV](../../docs/evidence/native-final-20261007/performance/ordinary-reference-block1.csv) / [meta](../../docs/evidence/native-final-20261007/performance/ordinary-reference-block1.meta) / [cost](../../docs/evidence/native-final-20261007/performance/ordinary-reference-block1.csv.cost) / [日志](../../docs/evidence/native-final-20261007/performance/ordinary-reference-block1.log) | [CSV](../../docs/evidence/native-final-20261007/performance/ordinary-hardened-block1.csv) / [meta](../../docs/evidence/native-final-20261007/performance/ordinary-hardened-block1.meta) / [cost](../../docs/evidence/native-final-20261007/performance/ordinary-hardened-block1.csv.cost) / [日志](../../docs/evidence/native-final-20261007/performance/ordinary-hardened-block1.log) | [CSV](../../docs/evidence/native-final-20261007/performance/ordinary-deployable-block1.csv) / [meta](../../docs/evidence/native-final-20261007/performance/ordinary-deployable-block1.meta) / [cost](../../docs/evidence/native-final-20261007/performance/ordinary-deployable-block1.csv.cost) / [日志](../../docs/evidence/native-final-20261007/performance/ordinary-deployable-block1.log) |
| 2 | [CSV](../../docs/evidence/native-final-20261007/performance/ordinary-reference-block2.csv) / [meta](../../docs/evidence/native-final-20261007/performance/ordinary-reference-block2.meta) / [cost](../../docs/evidence/native-final-20261007/performance/ordinary-reference-block2.csv.cost) / [日志](../../docs/evidence/native-final-20261007/performance/ordinary-reference-block2.log) | [CSV](../../docs/evidence/native-final-20261007/performance/ordinary-hardened-block2.csv) / [meta](../../docs/evidence/native-final-20261007/performance/ordinary-hardened-block2.meta) / [cost](../../docs/evidence/native-final-20261007/performance/ordinary-hardened-block2.csv.cost) / [日志](../../docs/evidence/native-final-20261007/performance/ordinary-hardened-block2.log) | [CSV](../../docs/evidence/native-final-20261007/performance/ordinary-deployable-block2.csv) / [meta](../../docs/evidence/native-final-20261007/performance/ordinary-deployable-block2.meta) / [cost](../../docs/evidence/native-final-20261007/performance/ordinary-deployable-block2.csv.cost) / [日志](../../docs/evidence/native-final-20261007/performance/ordinary-deployable-block2.log) |
| 3 | [CSV](../../docs/evidence/native-final-20261007/performance/ordinary-reference-block3.csv) / [meta](../../docs/evidence/native-final-20261007/performance/ordinary-reference-block3.meta) / [cost](../../docs/evidence/native-final-20261007/performance/ordinary-reference-block3.csv.cost) / [日志](../../docs/evidence/native-final-20261007/performance/ordinary-reference-block3.log) | [CSV](../../docs/evidence/native-final-20261007/performance/ordinary-hardened-block3.csv) / [meta](../../docs/evidence/native-final-20261007/performance/ordinary-hardened-block3.meta) / [cost](../../docs/evidence/native-final-20261007/performance/ordinary-hardened-block3.csv.cost) / [日志](../../docs/evidence/native-final-20261007/performance/ordinary-hardened-block3.log) | [CSV](../../docs/evidence/native-final-20261007/performance/ordinary-deployable-block3.csv) / [meta](../../docs/evidence/native-final-20261007/performance/ordinary-deployable-block3.meta) / [cost](../../docs/evidence/native-final-20261007/performance/ordinary-deployable-block3.csv.cost) / [日志](../../docs/evidence/native-final-20261007/performance/ordinary-deployable-block3.log) |
| 4 | [CSV](../../docs/evidence/native-final-20261007/performance/ordinary-reference-block4.csv) / [meta](../../docs/evidence/native-final-20261007/performance/ordinary-reference-block4.meta) / [cost](../../docs/evidence/native-final-20261007/performance/ordinary-reference-block4.csv.cost) / [日志](../../docs/evidence/native-final-20261007/performance/ordinary-reference-block4.log) | [CSV](../../docs/evidence/native-final-20261007/performance/ordinary-hardened-block4.csv) / [meta](../../docs/evidence/native-final-20261007/performance/ordinary-hardened-block4.meta) / [cost](../../docs/evidence/native-final-20261007/performance/ordinary-hardened-block4.csv.cost) / [日志](../../docs/evidence/native-final-20261007/performance/ordinary-hardened-block4.log) | [CSV](../../docs/evidence/native-final-20261007/performance/ordinary-deployable-block4.csv) / [meta](../../docs/evidence/native-final-20261007/performance/ordinary-deployable-block4.meta) / [cost](../../docs/evidence/native-final-20261007/performance/ordinary-deployable-block4.csv.cost) / [日志](../../docs/evidence/native-final-20261007/performance/ordinary-deployable-block4.log) |
| 5 | [CSV](../../docs/evidence/native-final-20261007/performance/ordinary-reference-block5.csv) / [meta](../../docs/evidence/native-final-20261007/performance/ordinary-reference-block5.meta) / [cost](../../docs/evidence/native-final-20261007/performance/ordinary-reference-block5.csv.cost) / [日志](../../docs/evidence/native-final-20261007/performance/ordinary-reference-block5.log) | [CSV](../../docs/evidence/native-final-20261007/performance/ordinary-hardened-block5.csv) / [meta](../../docs/evidence/native-final-20261007/performance/ordinary-hardened-block5.meta) / [cost](../../docs/evidence/native-final-20261007/performance/ordinary-hardened-block5.csv.cost) / [日志](../../docs/evidence/native-final-20261007/performance/ordinary-hardened-block5.log) | [CSV](../../docs/evidence/native-final-20261007/performance/ordinary-deployable-block5.csv) / [meta](../../docs/evidence/native-final-20261007/performance/ordinary-deployable-block5.meta) / [cost](../../docs/evidence/native-final-20261007/performance/ordinary-deployable-block5.csv.cost) / [日志](../../docs/evidence/native-final-20261007/performance/ordinary-deployable-block5.log) |
| 6 | [CSV](../../docs/evidence/native-final-20261007/performance/ordinary-reference-block6.csv) / [meta](../../docs/evidence/native-final-20261007/performance/ordinary-reference-block6.meta) / [cost](../../docs/evidence/native-final-20261007/performance/ordinary-reference-block6.csv.cost) / [日志](../../docs/evidence/native-final-20261007/performance/ordinary-reference-block6.log) | [CSV](../../docs/evidence/native-final-20261007/performance/ordinary-hardened-block6.csv) / [meta](../../docs/evidence/native-final-20261007/performance/ordinary-hardened-block6.meta) / [cost](../../docs/evidence/native-final-20261007/performance/ordinary-hardened-block6.csv.cost) / [日志](../../docs/evidence/native-final-20261007/performance/ordinary-hardened-block6.log) | [CSV](../../docs/evidence/native-final-20261007/performance/ordinary-deployable-block6.csv) / [meta](../../docs/evidence/native-final-20261007/performance/ordinary-deployable-block6.meta) / [cost](../../docs/evidence/native-final-20261007/performance/ordinary-deployable-block6.csv.cost) / [日志](../../docs/evidence/native-final-20261007/performance/ordinary-deployable-block6.log) |

## N01 · 全部18套原始记录

每格直接打开CSV、meta、阶段cost和日志；6块×3形态，各3000正式+100预热，不将单次调用当独立运行。

[全部均值/分位数/区间/成本主报告](../../docs/evidence/candidate-round-20261007/native/perf/performance.report)；[18次退出/父进程成本账本](../../docs/evidence/candidate-round-20261007/native/perf/attempts.tsv)；[实际环境/产物身份](../../docs/evidence/candidate-round-20261007/native/artifact-identity.log)。

| 块 | reference | hardened | deployable |
|---|---|---|---|
| 1 | [CSV](../../docs/evidence/candidate-round-20261007/native/perf/ordinary-reference-block1.csv) / [meta](../../docs/evidence/candidate-round-20261007/native/perf/ordinary-reference-block1.meta) / [cost](../../docs/evidence/candidate-round-20261007/native/perf/ordinary-reference-block1.csv.cost) / [日志](../../docs/evidence/candidate-round-20261007/native/perf/ordinary-reference-block1.log) | [CSV](../../docs/evidence/candidate-round-20261007/native/perf/ordinary-hardened-block1.csv) / [meta](../../docs/evidence/candidate-round-20261007/native/perf/ordinary-hardened-block1.meta) / [cost](../../docs/evidence/candidate-round-20261007/native/perf/ordinary-hardened-block1.csv.cost) / [日志](../../docs/evidence/candidate-round-20261007/native/perf/ordinary-hardened-block1.log) | [CSV](../../docs/evidence/candidate-round-20261007/native/perf/ordinary-deployable-block1.csv) / [meta](../../docs/evidence/candidate-round-20261007/native/perf/ordinary-deployable-block1.meta) / [cost](../../docs/evidence/candidate-round-20261007/native/perf/ordinary-deployable-block1.csv.cost) / [日志](../../docs/evidence/candidate-round-20261007/native/perf/ordinary-deployable-block1.log) |
| 2 | [CSV](../../docs/evidence/candidate-round-20261007/native/perf/ordinary-reference-block2.csv) / [meta](../../docs/evidence/candidate-round-20261007/native/perf/ordinary-reference-block2.meta) / [cost](../../docs/evidence/candidate-round-20261007/native/perf/ordinary-reference-block2.csv.cost) / [日志](../../docs/evidence/candidate-round-20261007/native/perf/ordinary-reference-block2.log) | [CSV](../../docs/evidence/candidate-round-20261007/native/perf/ordinary-hardened-block2.csv) / [meta](../../docs/evidence/candidate-round-20261007/native/perf/ordinary-hardened-block2.meta) / [cost](../../docs/evidence/candidate-round-20261007/native/perf/ordinary-hardened-block2.csv.cost) / [日志](../../docs/evidence/candidate-round-20261007/native/perf/ordinary-hardened-block2.log) | [CSV](../../docs/evidence/candidate-round-20261007/native/perf/ordinary-deployable-block2.csv) / [meta](../../docs/evidence/candidate-round-20261007/native/perf/ordinary-deployable-block2.meta) / [cost](../../docs/evidence/candidate-round-20261007/native/perf/ordinary-deployable-block2.csv.cost) / [日志](../../docs/evidence/candidate-round-20261007/native/perf/ordinary-deployable-block2.log) |
| 3 | [CSV](../../docs/evidence/candidate-round-20261007/native/perf/ordinary-reference-block3.csv) / [meta](../../docs/evidence/candidate-round-20261007/native/perf/ordinary-reference-block3.meta) / [cost](../../docs/evidence/candidate-round-20261007/native/perf/ordinary-reference-block3.csv.cost) / [日志](../../docs/evidence/candidate-round-20261007/native/perf/ordinary-reference-block3.log) | [CSV](../../docs/evidence/candidate-round-20261007/native/perf/ordinary-hardened-block3.csv) / [meta](../../docs/evidence/candidate-round-20261007/native/perf/ordinary-hardened-block3.meta) / [cost](../../docs/evidence/candidate-round-20261007/native/perf/ordinary-hardened-block3.csv.cost) / [日志](../../docs/evidence/candidate-round-20261007/native/perf/ordinary-hardened-block3.log) | [CSV](../../docs/evidence/candidate-round-20261007/native/perf/ordinary-deployable-block3.csv) / [meta](../../docs/evidence/candidate-round-20261007/native/perf/ordinary-deployable-block3.meta) / [cost](../../docs/evidence/candidate-round-20261007/native/perf/ordinary-deployable-block3.csv.cost) / [日志](../../docs/evidence/candidate-round-20261007/native/perf/ordinary-deployable-block3.log) |
| 4 | [CSV](../../docs/evidence/candidate-round-20261007/native/perf/ordinary-reference-block4.csv) / [meta](../../docs/evidence/candidate-round-20261007/native/perf/ordinary-reference-block4.meta) / [cost](../../docs/evidence/candidate-round-20261007/native/perf/ordinary-reference-block4.csv.cost) / [日志](../../docs/evidence/candidate-round-20261007/native/perf/ordinary-reference-block4.log) | [CSV](../../docs/evidence/candidate-round-20261007/native/perf/ordinary-hardened-block4.csv) / [meta](../../docs/evidence/candidate-round-20261007/native/perf/ordinary-hardened-block4.meta) / [cost](../../docs/evidence/candidate-round-20261007/native/perf/ordinary-hardened-block4.csv.cost) / [日志](../../docs/evidence/candidate-round-20261007/native/perf/ordinary-hardened-block4.log) | [CSV](../../docs/evidence/candidate-round-20261007/native/perf/ordinary-deployable-block4.csv) / [meta](../../docs/evidence/candidate-round-20261007/native/perf/ordinary-deployable-block4.meta) / [cost](../../docs/evidence/candidate-round-20261007/native/perf/ordinary-deployable-block4.csv.cost) / [日志](../../docs/evidence/candidate-round-20261007/native/perf/ordinary-deployable-block4.log) |
| 5 | [CSV](../../docs/evidence/candidate-round-20261007/native/perf/ordinary-reference-block5.csv) / [meta](../../docs/evidence/candidate-round-20261007/native/perf/ordinary-reference-block5.meta) / [cost](../../docs/evidence/candidate-round-20261007/native/perf/ordinary-reference-block5.csv.cost) / [日志](../../docs/evidence/candidate-round-20261007/native/perf/ordinary-reference-block5.log) | [CSV](../../docs/evidence/candidate-round-20261007/native/perf/ordinary-hardened-block5.csv) / [meta](../../docs/evidence/candidate-round-20261007/native/perf/ordinary-hardened-block5.meta) / [cost](../../docs/evidence/candidate-round-20261007/native/perf/ordinary-hardened-block5.csv.cost) / [日志](../../docs/evidence/candidate-round-20261007/native/perf/ordinary-hardened-block5.log) | [CSV](../../docs/evidence/candidate-round-20261007/native/perf/ordinary-deployable-block5.csv) / [meta](../../docs/evidence/candidate-round-20261007/native/perf/ordinary-deployable-block5.meta) / [cost](../../docs/evidence/candidate-round-20261007/native/perf/ordinary-deployable-block5.csv.cost) / [日志](../../docs/evidence/candidate-round-20261007/native/perf/ordinary-deployable-block5.log) |
| 6 | [CSV](../../docs/evidence/candidate-round-20261007/native/perf/ordinary-reference-block6.csv) / [meta](../../docs/evidence/candidate-round-20261007/native/perf/ordinary-reference-block6.meta) / [cost](../../docs/evidence/candidate-round-20261007/native/perf/ordinary-reference-block6.csv.cost) / [日志](../../docs/evidence/candidate-round-20261007/native/perf/ordinary-reference-block6.log) | [CSV](../../docs/evidence/candidate-round-20261007/native/perf/ordinary-hardened-block6.csv) / [meta](../../docs/evidence/candidate-round-20261007/native/perf/ordinary-hardened-block6.meta) / [cost](../../docs/evidence/candidate-round-20261007/native/perf/ordinary-hardened-block6.csv.cost) / [日志](../../docs/evidence/candidate-round-20261007/native/perf/ordinary-hardened-block6.log) | [CSV](../../docs/evidence/candidate-round-20261007/native/perf/ordinary-deployable-block6.csv) / [meta](../../docs/evidence/candidate-round-20261007/native/perf/ordinary-deployable-block6.meta) / [cost](../../docs/evidence/candidate-round-20261007/native/perf/ordinary-deployable-block6.csv.cost) / [日志](../../docs/evidence/candidate-round-20261007/native/perf/ordinary-deployable-block6.log) |

## 最新匿名成品验收

[候选终版v2](../support/candidate-round-20261007-v2/README.md)使用独立源清单601a1020…，
同一成品在Linux新目录GCC与Clang ASan/UBSan各34项、25步骤全部0。五类旧主结果
逐字复算一致、60条真实普通短演示单列；[身份与结果](../../docs/evidence/candidate-package-20261007/final-archive-identity.json)、
[原始退出账本](../../docs/evidence/candidate-package-20261007/native/results/step-exits.tsv)、
[新源逐项差异](../../docs/evidence/candidate-package-20261007/N01-distribution-differences.json)。
该段v2验收当时的执行者记录保持原样，不回填成A03。当前包不回填N01旧正式产物身份，不升级R07。

最新完整资料链[v3](../support/submission-v3-20261007/README.md)保持601a构建输入，
补齐全部自有Markdown链接，原摘要/匿名摘要与C04事前冻结/分发清单分角色。243原CSV
字节保持；[v3真实25步](../../docs/evidence/submission-package-v3-20261007/native/results/step-exits.tsv)
和[新身份](../../docs/evidence/submission-package-v3-20261007/final-archive-identity.json)单列。
原vendor12处外部示例/开发引用按原快照说明范围，不是当前本地证据；旧报告在新包history。
源相同、检查通过和页面完整均不关闭R07或截图、审批签署。2026-10-08的计入执行见A03，不改v3原账本。
