# 同语言数学更新成本留证

本目录对应[冻结合同](../../research/aris-20261008/UPDATE_COST_CONTRACT.md)和[结果说明](../../research/aris-20261008/UPDATE_COST_RESULTS.md)，只使用固定整数输入，不调用密码实现。一次正式执行退出0，C终态complete；[独立C原始行复核](result-review.md)通过，全部[核验读数](verification.json)与原始输出一致。这些评审来自同模型独立代理，不是外部同行评审。

启动前[资源检查](compute-preflight.json)与[环境](environment.json)确认本机macOS/ARM可用。原C01封存清单153项及本轮源/产物清单11项核对通过，记录在sealed-input-preflight.log和source-binary-preflight.log。源码、合同、普通产物及软件检查日志另存，普通与ASan/UBSan各3项，格式检查通过；第一次编译失败及修复日志保留。

source-snapshot/README保留启动前说明的原字节，其中“未执行正式比较”描述冻结当时；当前状态以本页及原始终态为准。其四个相对检查链接所需的同字节副本另放source-snapshot/checks，原说明未改写。

[启动记录](launch.json)在唯一正式调用前写入；[退出记录](execution-result.json)记真实退出0。[原始输出](run/final-state.meta)给出16次预热、160个正式窗口、176次结果消费、512个校准原值和30秒管理预算。raw-times.csv、raw-clock.csv、pairs.csv、summary.csv及空的失败账本全部保留，没有删长尾或改写原始行。

[运行后复核](postflight.json)确认24份输入和副本、源码及产物保持。本目录的工具等待时长不是独立完整进程成本。管理窗、函数窗和最终状态发布分别记录，不能混称端到端。

两个重复全零任务保留但不支持逐状态机制归因；主张只覆盖固定六份非零向量、当前产物与平台。这里没有新总体统计确认、恒时证明或竞赛签收，也未并入旧封存证据或v2匿名补充件。

[执行前代码审查](code-review.md)保留原始结论。独立审计器使用单独CMake/CTest，1/1通过。随后仅将其新CMake配置按仓库固定工具格式化，未改审计C源码、冻结观察器或原始输出；[格式检查](audit-source/cmake-format-check.json)和[纯格式差分](audit-source/cmake-format-only.diff)保留首个失败及修复后的通过记录。
