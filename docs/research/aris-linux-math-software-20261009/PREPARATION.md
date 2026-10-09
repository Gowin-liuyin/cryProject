# Linux数学软件复核准备交接

2026-10-09。状态为`READY_FOR_ROOT_REVIEW_AND_DEPLOYMENT`，没有执行Linux矩阵。

部署件在本仓库`build/aris-linux-math-software-20261009/linux-math-software-stage.tar.gz`，
大小194086字节，SHA256为`6b3ba2c6ed62d80ee4ec39824f18e1430185652e9a94c9b979c12703f234d0fc`。
解包后顶层是`stage/`，共264个文件，清单覆盖263项摘要，路径清单包含全部264项。
[目标文件清单](STAGE_FILE_LIST.json)记录每项大小和摘要；原源码包123项及固定汇总C/配置没有修改。
部署件只有源码、既有记录和编排，不含新二进制、口令、私钥或新计时记录。

主代理应先审核并提交本模块合同和编排，再将stage解包到约定裸金属工作根下的新目录。
核对机器、实际GCC13/Clang18与CPU资源后，用stage中`verification/remote-run.sh`的两个参数
指定stage物理路径和不存在的输出根。公开入口总是经过595秒超时和5秒终止宽限，
四个单元按事前顺序执行，首个失败停止本单元，其他单元仍保留事前运行机会。
没有重试、频率修改、正式统计计时或密码算法调用。

本地使用既有macOS/ARM独立审计与汇总C二进制，只读编排的4项CTest全部通过，
四份新JSON与封存参考逐字节一致。已验证拒绝覆盖既有输出且原JSON摘要不变、
拒绝相对路径、完整stage路径/摘要一致，以及两份shell语法与新CMake格式。
非约定根的本地尝试在macOS realpath不支持GNU --e处先退出，原失败日志保留；
固定根拒绝分支目前只有静态审查，不能计为本地已执行通过，Linux执行前应另核验。
[机器可读本地核验](LOCAL_PRECHECK.json)明确标记`linux_matrix_executed=false`。
实际本地日志保留在`build/aris-linux-math-software-20261009/local-*.log`。

独立编排审查先发现四项问题：CTest未在首败时停止、输出可能进入stage、继承变量可绕过超时、
失败产物的链接/符号记录太晚。四项已修正；第二次审查通过。最后的绝对路径限制和五项预检
失败即停止也经过复查，264项路径与263项摘要一致。审查属于本会话代理的独立代码检查，
没有外部同行评议、远程操作或新观察器统计运行。

第一遍本地装配误以为每个M02目录有32项，实际还有`input-records.tsv`，共33项；
失败的部分stage保留在build下`stage-incomplete-file-count/`，未进入部署件。
修正文件集合后从干净stage重新装配；三个目录各33项均保持原字节，没有丢掉附加原记录。

本准备件不能签收Linux软件、Linux时间、跨平台效率、R02/R04或真实总体误报/检出率。
真实Linux执行结果、所有失败日志和产物身份由主代理另存新证据目录并进行最终审查。
