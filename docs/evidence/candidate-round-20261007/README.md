# 本轮候选源码的真实Linux工程验证 N01/A02

本轮用户日期2026-10-07。真实主要执行窗口为2026-10-07 16:18:45–16:19:13 UTC；后续
只读配置交叉核对单列于[步骤账本](native/step-exits.tsv)。操作者是作者代理，不是非原作者。

固定导出所用Git为2e94648d502a5441b4f042abd8f420a91146d7b7；[导出身份](export-identity.json)
绑定源码清单da42366ce5912ebd1d2d87913c17d238c9f325c6ae178456a1b8d37bca6fcba3。
构建身份为verified_source_export，兼容source_commit前缀不是Git提交。后续产品帮助与报告
变化不回填到本轮被测源码；最终匿名包会以另一个导出身份独立重新构建。

[预检](preflight.log)与[实际环境](native/environment.log)：Ubuntu24.04.4、Linux6.8.0-138、
x86_64、4vCPU、7993503744字节RAM、KVM实例；CPU型号的192-Core不代表分配资源。
新独立目录/tmp/cryproject-candidate.ZzfLRh。未读取、打印或传输私钥，未修改系统安全策略。

## 本轮真正执行的检查

| 类别 | 实际结果 | 可直接打开的原件 |
|---|---|---|
| 固定源码/正式构建 | 源清单通过；GCC13.3、Ninja、RelWithDebInfo、-O2、无LTO | [源码清单输出](native/source-manifest.log)、[正式配置](native/release-configure.log)、[构建](native/release-build.log)、[版本](native/release-version.log) |
| 独立功能、接口、随机失败和软件回归 | 默认34项全部通过，含四版独立NIST/隐式拒绝、边界、差分；随机失败实测为open失败 | [正式CTest](native/release-tests.log)；不能由往返替代独立向量，read/close故障注入未执行 |
| 动态内存/UB检查 | Clang18.1.3、Debug、ASan/UBSan，另目录34项全部通过 | [动态构建](native/sanitizer-build.log)、[动态CTest](native/sanitizer-tests.log)；动态产物不进入性能 |
| 配置与产物 | 四版包含路径与实际编译一致；有效便携C/FIPS202、ASM值屏障；int为4字节，ELF GNU_STACK为RW | [构建配置](native/build-configuration.txt)、[编译命令](native/compile_commands.json)、[真实链接](native/actual-build-and-link.log)、[交叉核验](native/configuration-cross-check.log)、[有效宏](native/effective-macros.txt)、[产物摘要/ELF/符号](native/artifact-identity.log) |
| 正式普通性能 | 18运行退出0，54000正式+1800预热；CPU2；完整父进程窗口合计4.162436263s | [运行账本](native/perf/attempts.tsv)、[C报告](native/perf/performance.report)、[参考原始CSV示例](native/perf/ordinary-reference-block1.csv)、[meta](native/perf/ordinary-reference-block1.meta)、[成本](native/perf/ordinary-reference-block1.csv.cost) |
| 旧材料作者代理复算 A02 | 40历史报告、E02性能、固定精确任务、40964模型、24576后赋标签及144原时间全部逐字一致 | [历史重放](native/history-replay.log)、[性能复算](native/performance-old.report)、[精确](native/exact.report)、[模型原始行](native/model/raw.csv)、[标签原始行](native/reference-control/raw.csv)、[原时间](native/reference-control/selected.csv)、[比较退出](native/step-exits.tsv) |

完整反汇编：[参考](native/disassembly-reference.log)、[掩码对照](native/disassembly-hardened.log)、
[正常优化形态](native/disassembly-deployable.log)。只覆盖这些产物，不证明硬件恒时或新防护有效。
原SCU宏在清理后不再完整显示；有效防护宏以使用实际compile_commands参数预处理verify.h
的[精确命令](native/preprocessor-command.txt)为准，不从缺失宏误判未启用防护。

## 普通性能支持范围

hardened相对reference均值差380.801722222ns，开销0.8245988%，探索99%区间
−769.376722222至1518.392333333ns；deployable差504.065388889ns，开销1.0915174%，
区间−806.366888889至1730.791333333ns。两者跨零，6块iid未证明；长尾全部保留，不挑运行。
与旧E02分开，不能把旧图的数值当成这份新源码结果，也不能把普通开销视为防护效果。

[执行脚本](native-execution.sh)、逐项.command/.log及[验证摘要](native/verification.json)记录本轮
23个主要步骤与1个额外交叉核对，全部退出0；未执行新漏洞触发、受控防护时序、泄露利用、
密钥恢复、上游全形式证明、真人签收或实际截图。新控制运行仅为只读数据复算，密码调用为0。
R07/R11真实材料缺口仍保留，材料状态为提交候选版，非全部验收。
