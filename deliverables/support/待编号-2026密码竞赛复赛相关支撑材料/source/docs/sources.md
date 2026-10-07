# 来源与构建口径

参考实现：<https://github.com/pq-code-package/mlkem-native>
固定提交：`b3ba7b32773e657dd37f6f87bce82528459ad8a4`（2026-09-21）。
`vendor/mlkem-native/mlkem/` 原样复制该提交的完整库目录；`LICENSE` 原样保留。
库代码按 Apache-2.0 OR ISC OR MIT 提供，文档 CC-BY-4.0；各文件版权及 SPDX 以原件为准。
本项目采用便携 C 后端、ML-KEM-768，禁用上游随机 API，由后续封装管理系统随机源。
标准口径为 2024-08-13 FIPS 203：<https://csrc.nist.gov/pubs/fips/203/final>。
功能测试通过不表示取得 FIPS 模块认证。

机制依据：<https://github.com/antoonpurnal/clangover>
核查提交：`7f4d5dc162b77c362a34a0d52949f7a3e1b16d81`。
其 README 指向旧 Kyber `b628ba78711bc28327dc7d2d5c074a00f061884e` 的
poly_frommsg 编译器生成秘密相关分支，列举 x86、Clang 15–18、-Os/-O1 等条件。
历史案例不能直接冒称本机已复现，也不能将旧 Kyber 身份换成当前 ML-KEM。
已在当前库上单独维护最小机制回归补丁，并核验实际采集产物的机器码。

当前实机：macOS Darwin 25.6.0 arm64，Apple Clang 21.0.0
(clang-2100.3.34.2)，当前 CMake 默认 RelWithDebInfo（本机 `-O2 -g -DNDEBUG`）、C11、严格警告、无 LTO。
另在 Apple Silicon 主机的 linux/arm64 容器（Ubuntu 24.04、GNU GCC 13.3.0）完成 Linux 与
GNU GCC 的功能与产物验证，见 [验证记录](validation.md)；该容器时钟分辨率为 1ms，不产出时序证据。
x86_64 Linux 实机验证尚未执行。

模块一建立两个独立静态库构建目标；从模块三开始，vulnerable 对构建目录副本
应用独立消息编码补丁，参考版继续编译原始快照。后续增加的 hardened 变体同样只作用于
自己的构建目录副本，使用与 vulnerable 相同的函数级优化控制。三个程序不在同一进程混合链接。
具体机制及本次验证边界见 [缺陷说明](defect.md)、[防护说明](mitigation.md) 和
[验证记录](validation.md)；统计方法见 [统计说明](statistics.md)。
