# 普通参考窗口工具本机准备

2026-10-10。保存本机Apple Silicon/macOS、AppleClang21的普通及ASan/UBSan两套实际CTest原日志、CMake缓存和六项编译命令。每套2/2通过：纯软件自检及原NIST/接口/随机往返KAT；没有普通工作负载、硬件读取或密码计时执行。

独立子代理 `/root/cpu_isolation_review` 只读审查最终C SHA-256 `ead1029864025047ca0df2bf1d7bea179040f151313589389c043e3a7b9ef68a`、CMake和原日志，给出允许继续Linux纯软件预检的限定通过。核对完整调用围栏、转换/消费在停止取时之后、记录容量和结束槽、六读不短路、原错误与精确整数保留、没有采样间I/O或秘密输出；没有执行入口、SSH或改文件。

本机普通入口明确unsupported/2；非法参数2、只读stdout的selfcheck失败1，格式通过。源码准备阶段补入了与现有采集器一致的C11围栏，并改正内部记录数量命名；最终两套原日志是在此后重新取得的真实通过。

周期/边界快照失败时保留该失败快照，不额外重试end，summary标valid_final_snapshot=false并非零退出；说明已修正。未验证真实Linux普通分支、长期worker生命周期或受控窗口，不能把本目录当作G2执行或R02/R04签收。
