# 普通参考完整调用研究的准备证据

2026-10-10，新C11专用collector/analyzer、公开NIST fixture及[实验合同](../../../research/aris-ordinary-repeatability-20261010/EXPERIMENT_PLAN.md)完成实施与独立审查。本机macOS/ARM普通及ASan/UBSan各4/4项CTest通过，初次执行没有修复重跑；实际计时调用为0、Linux资格及六进程采集均未启动。见[软件说明](../../../research/aris-ordinary-repeatability-20261010/SOFTWARE_NOTES.md)及[tracker](../../../research/aris-ordinary-repeatability-20261010/EXPERIMENT_TRACKER.md)。

[qualification-originals.zip](qualification-originals.zip)保留527个原始构建/日志成员，1120265字节，SHA-256为`77b6cbb65412f08a466f9db24ac30be3cfce38a30570b8c48373374f946d333d`；ZIP CRC、唯一成员及全部成员原字节核对通过。包含两配置、六个真实Mach-O、静态库、编译命令和完整CTest记录。可直接读[qualification.json](qualification.json)、[普通verbose](logs/ordinary-ctest.stdout)、[动态verbose](logs/sanitize-ctest.stdout)、[普通库存](logs/ordinary-inventory.stdout)及[动态库存](logs/sanitize-inventory.stdout)；`tested-source/`保留实际被测四个源/配置及事前合同原字节。

测试基线为main的`22a7b9065984cb1f2c6361c4553b23589f88d1fb`，新模块当时未提交，逐文件源和六产物摘要绑定真实资格，不冒称基线已包含新工具。两配置实际完成路径合计132次完整算法调用、零计时/硬件采集；18参数拒绝、20密钥校验和10测试SHAKE为每次原KAT的单列辅助量。Mac动态`detect_leaks=0`，Linux采样分支及转储回读未被本机执行。原src/vendor/tests及旧工具不改。

| 准备对象 | 原件入口 |
|---|---|
| 最小复用路线 | [只读调查](code-survey.md)、[依赖清单135项](candidate-dependencies.json) |
| 初设计及合同问题 | [设计意见](design-review.md)、[原条件审查](CONTRACT_REVIEW.md)、[原绑定](CONTRACT_REVIEW.json) |
| 两项问题闭合及实际Mac资格回执 | [最终补审](CONTRACT_FINAL_REVIEW.md)、[机读绑定](CONTRACT_FINAL_REVIEW.json)；原条件评语不追改 |
| 独立静态代码审查 | [意见](STATIC_CODE_REVIEW.md)、[机读绑定](STATIC_CODE_REVIEW.json)；形成时实际资格仍pending，后续回执单列 |
| 原JSON到头文件映射 | [提取记录](fixture-extraction.json)，三数组2400/1088/32字节均与原件相同 |
| 公开有效样例的资格依据 | [公开拒绝参照及源码绑定](public-fixture-acceptance-qualification.json)，该外部算术步骤不执行完整算法；后续两fixture-check真实完整输出相符另见verbose |
| 指定Linux只读资源预检 | [完整回执](COMPUTE_PREFLIGHT.json)、[原stdout](compute-preflight.stdout)、[关闭stderr](preflight-close.stderr) |
| 本地封存核验 | [PREPARATION_VERIFICATION](PREPARATION_VERIFICATION.json)、[SHA256SUMS](SHA256SUMS) |

资源预检只读确认Linux/x86_64、CPU2、物理Cry可写及工具/空间；远端项目写入、算法、采样均为0。首次长控制socket触发本机Unix路径限制后退出255，没有remote helper，短socket密码重认成功后完成预检并关闭；口令没有保存。这里只记录实际资源快照，不当作实验存活证据；云端新源、构建或数据尚不存在，后续仍只允许Cry物理子目录。

独立审查为同模型内部代理，不是跨模型或外部同行评审，外部Codex MCP仍pending。软件资格和输入完整性不等于目标量级精度、长期稳定或统计前提，R02/R04未签收。原报告、支撑包和旧证据不改写。
