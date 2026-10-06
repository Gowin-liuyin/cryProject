# 作者新检出复算（2026-10-06）

固定源码 `ff1d9602e4e3d9cf52c137927d293e92ec88bbf4`，从本仓库另克隆到新的临时目录，
分离检出该提交，新的CMake/Ninja/RelWithDebInfo、BUILD_TESTING=OFF构建分析器。
不使用原二进制目录，不重新采样，也没有修改封存源数据。

全部命令和退出码见日志；C复算器先核验封存SHA-256，再核对每份数据/清单及完成状态。
同一ARM64 macOS工具链下，重新生成的报告与封存expected.report逐字相同。
这是合成软件夹具的可复算性检查，不是数学独立正确性证明，也不是平台收益或独立确认。
执行者仍是原作者代理，不能叫非原作者复现；没有第三方日志或目标设备重采。

`identity.txt`保留实际固定提交、检出目录与范围；没有把日志HEAD替换为此后提交。
核验本目录：

```sh
shasum -a 256 -c docs/evidence/paired-self-reproduction-20261006/SHA256SUMS
```
