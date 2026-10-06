# 原生目标准备检查

状态：准备完成、尚未执行。入口见 `tools/run_native_reference.sh`，说明见
[准备包](../../native-linux-reference.md)。没有用户提供的目标连接，未访问或创建目标主机。

本机POSIX `sh -n`通过；macOS平台拒绝测试返回2且没有创建输出目录，见 `platform-guard.log`。
相同CMake目标及普通负载流程已经在本轮ARM64证据中运行；本目录没有Linux构建、功能或
时序结果，不能充作原生目标证据。完整固定源码提交以本轮模块提交及验收记录为准。

```sh
shasum -a 256 -c docs/evidence/native-linux-preparation-20261006/SHA256SUMS
```
