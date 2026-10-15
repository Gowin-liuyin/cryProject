# 来源与构建口径

## 角色（2026-10-15）

- **主阳性（历史第三方）**：[liboqs 0.10.0](https://github.com/open-quantum-safe/liboqs/releases/tag/0.10.0)，提交 `36be57445d8ca53f7095160fde548efe82ace09d`，告警 [GHSA-f2v9-5498-2vpp](https://github.com/open-quantum-safe/liboqs/security/advisories/GHSA-f2v9-5498-2vpp)。接入说明见 [historical-liboqs-0.10.0.md](historical-liboqs-0.10.0.md)；销钉文件 [`vendor/liboqs-0.10.0.PIN.md`](../vendor/liboqs-0.10.0.PIN.md)。
- **附录阴性（当前主实现）**：下文 mlkem-native 固定提交；用于正确性主线与「最硬实现上不显著」的诚实对照。
- **开发夹具**：人工 `message-branch` 等补丁只作用于构建目录副本，不改 `vendor/mlkem-native` 原件。

参考实现：<https://github.com/pq-code-package/mlkem-native>
固定提交：`b3ba7b32773e657dd37f6f87bce82528459ad8a4`。
[上游提交记录](https://github.com/pq-code-package/mlkem-native/commit/b3ba7b32773e657dd37f6f87bce82528459ad8a4)
的作者时间为 2026-09-21 07:50:12 UTC，提交者时间为 2026-09-22 03:22:27 UTC。
本轮将原先仅写作者日期的来源记录补齐，两者不是库版本差异或上游漏洞。
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
已在当前库上单独维护最小机制回归补丁，并核验实际采集产物的机器码；该补丁现降为开发夹具，主阳性改为 liboqs 0.10.0（见上）。

早期记录（保留当时时点）：macOS Darwin 25.6.0 arm64，Apple Clang 21.0.0
(clang-2100.3.34.2)，当前 CMake 默认 RelWithDebInfo（本机 `-O2 -g -DNDEBUG`）、C11、严格警告、无 LTO。
另在 Apple Silicon 主机的 linux/arm64 容器（Ubuntu 24.04、GNU GCC 13.3.0）完成 Linux 与
GNU GCC 的功能与产物验证，见 [验证记录](validation.md)；该容器时钟分辨率为 1ms，不产出时序证据。
上述早期阶段尚未执行 x86_64 Linux 实机验证；它不是当前状态。
后续已在授权的 Ubuntu 24.04.4/x86_64/KVM、4 vCPU 云实例完成
[E01 参考验收](evidence/native-reference-20261007/README.md)和
[E02 三种形态普通性能](evidence/native-final-20261007/README.md)，
源码分别为记录中固定的 `9d9554b` 与 `0e8be6d`。
它们是已有实际记录，不属于本轮重新执行；普通性能不构成完整秘密机制防护闭环。
本轮公开来源与版本关系见[集中审查](upstream-security-review.md)。

模块一建立两个独立静态库构建目标；从模块三开始，vulnerable 对构建目录副本
应用独立消息编码补丁，参考版继续编译原始快照。后续增加的 hardened 变体同样只作用于
自己的构建目录副本，使用与 vulnerable 相同的函数级优化控制。三个程序不在同一进程混合链接。
具体机制及本次验证边界见 [缺陷说明](defect.md)、[防护说明](mitigation.md) 和
[验证记录](validation.md)；统计方法见 [统计说明](statistics.md)。
