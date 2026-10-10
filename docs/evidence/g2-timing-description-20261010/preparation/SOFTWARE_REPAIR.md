# 首轮动态检查的环境修正

2026-10-10，真实新描述入口尚未执行。首轮软件原件在本机 `build/aris-g2-timing-description-20261010/software/run-20261010T040826Z/`：普通配置与构建成功、CTest2/2通过；动态配置与构建成功，但测试环境误设 `ASAN_OPTIONS=detect_leaks=1`，macOS运行库在测试体执行前以 `detect_leaks is not supported on this platform` 拒绝。不能把该次动态CTest记成通过，也不能据此归因于被测C代码。

修正只把该平台不支持的泄漏检测关为 `detect_leaks=0`，保留ASan/UBSan及错误即停；不改C、CMake、数值合同或正式数据。用同一个已构建动态产物，在新日志目录重试一次CTest；不重新构建、不再跑已通过的普通CTest。该次为明确失败后的环境修复检查，区别于冻结计划的一次常规动态执行；新增预算60秒，仍不启动密码、硬件或SSH。继续尚未运行的普通旧模式normal/parent-loss兼容回归，各一次。

本轮不宣称LSan覆盖；只接受实际测试与退出日志。若修正后仍失败，保留结果再定位，不循环重跑。原输入和首次失败记录保持，正式普通描述仍限后续一次新执行。
