# 精确复算效率确认冻结

2026-10-07、功能源码62674a00f71dff6668b5d8e5ce7173c09961a74d。
原合同controlled-comparison-v1及依赖更正保持有效；本文件在确认分析前提交。
开发2个固定文件、12个实际进程复算已完成，C与SciPy尾计数逐项一致；仅支持开发。
此前同2文件的单次接口兼容检查也保留，不作效率主结果；其单独进程墙钟未采集，
所以完整研发墙钟不闭合。确认指标仅为规定的完整复算进程，不改口称全研发成本。

确认任务8份，各20对，种子202610071001..1008，场景依次null/effect/ties/drift/null/effect/ties/drift。
数据在controlled-comparison-20261007/confirmation-data由C生成，原始字节及计划在本提交冻结。
每个任务两方法各3次，方法顺序按(task零基序号+repetition零基序号)奇偶交替。
完整2^20个交换、abs(sum)上尾含等值、alpha0.01、SciPy1.16.3/NumPy2.3.5、
vectorized=True及batch4096固定。OPENBLAS_NUM_THREADS和OMP_NUM_THREADS均1。
输出新目录confirmation-results；300秒运行限额；开发14.05秒纳入总运行预算，
确认可用余额285.95秒；若确认超过余额，虽单次入口允许300秒，也不能支持本合同结果。
不增加任务、调种子、改变统计量或挑有利重复。

平台为Apple M5/ARM64 macOS、Apple Clang21；本次是离线复算比较，不冒称Linux密码性能。
原生普通数据另有9d9554b身份。候选及外部对照脚本摘要见frozen-source-and-binaries.sha256；
source函数未改变；正式后不回填未来文档提交为被测代码。
源码/二进制摘要与数据摘要、48次进程退出、精确尾计数与分母、逐次CLOCK_MONOTONIC墙钟
共同接受验收。结果仍按原合同逐份最大候选<最小基线及中位比值≤0.5，资格失败即收口。
本地提交只支持作者仓库内顺序，没有第三方时间戳或非原作者签收。
