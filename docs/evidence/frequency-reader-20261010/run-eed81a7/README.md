# 反馈来源与实际读取原件

日期2026-10-10，主张边界见[结果说明](../../../research/aris-frequency-reader-20261010/RESULTS.md)。本目录是新证据，不改写先前准备件或已封存材料。

| 原归档 | SHA-256 | 内容 |
|---|---|---|
| `feedback-mapping-20261010-62ce88b02a82.tar` | `5de3dd6af737bca1e8a47a9aa6729313be084612e788eab287fb968ebbaef431` | root原件14张ACPI表及metadata，282915字节表数据 |
| `feedback-counter-20261010-16ec7cf0d5fb.tar` | `3457b6f8c729eac6209316f08f353486d5027eb17bc33489af84a8dc9ac2a601` | root执行的原ELF、stdout/stderr、真实执行metadata，4成员 |
| `feedback-reader-eed81a7-results.tar` | `b187de98505e70f555d583be9e88add9e7cd603b9d5cf896e95be5862079382a` | 476常规成员，475载荷及完整清单；全部构建、源归档、包/许可证、失败与S01、原归档副本及结束状态 |

便于阅读的长期副本：

- [目标静态DSL](selected/decode-s01/SSDT3.dsl)、[原14表metadata](selected/decode/metadata.json)、[S01完整日志](selected/decode-s01/iasl.log)与[实际结果](selected/decode-s01/result.json)。独立映射复核记录中的build路径是核查现场；本目录副本与对应原件逐字节一致，后续清理本地build不影响这些证据。
- [实际六读](counter/stdout.json)、[执行身份](counter/execution.json)与空stderr。原ELF在counter归档内，与完整导出的normal ELF相同；只有这一次真实读取，不重跑取更好数值。
- [原解码失败日志](selected/iasl-disassemble.log)及[退出255](selected/iasl-disassemble-result.json)。外层build工具返回1的完整原始envelope未另存，`orchestration-provenance.json`明确标为事后说明；逐步骤原日志和真实结果均在导出中，不冒称外层回执完整。
- [普通CTest](selected/build-normal/Testing/Temporary/LastTest.log)、[动态CTest](selected/build-sanitize/Testing/Temporary/LastTest.log)、编译/链接参数及配置日志；每套只检查本读取模块一项软件自检。
- `orchestration-source/` 保存精确执行源；`tool-receipts/` 保存实际捕获的工具输出与返回字段；`artifact-static/` 是本机对原Linux ELF的反汇编和动态符号静态读取，没有在Mac执行它。
- [固件字段独立复核](FIRMWARE_MAPPING_REVIEW.md)、[实物独立核验](ARTIFACT_REVIEW.md)、[验证器](verify_evidence.py)及[结果](verification.json)。验证器核对归档、源/ELF/原值与选取副本，不能替代独立语义复核或频率资格。

固件collector和root读取封装均经修正后审查，在执行前闭合目录身份、预算、原件回读、源ELF物理路径和进程身份读取异常等问题。源码固定声明零配置写入；执行中没有调频、cgroup、boost、SMT或IRQ写入。真实程序退出0、六读各8字节、无超时；未构造活动频率窗口、运行密码负载或确认统计结论。

CPU2/18分别对应C004/C005。保存表中的静态GAS映射为E7/E8，参考性能与回绕字段为空资源；默认解释及4300MHz声明均附边界。它们不等于运行时内核缓存直接转储、恒频或时钟精度证明。F1静态声明子项及F2/F3读取能力通过，R02/R04仍部分签收。

所有云端项目原件在Cry及子目录，结束状态见[回读](selected/final-visible-state.json)：根CPU0—31可用、隔离集合为空，目标策略与预检相同。主SSH连接退出0关闭。旧KVM本轮未访问，身份核验和迁移仍待可信确认；认证内容未写入证据。
