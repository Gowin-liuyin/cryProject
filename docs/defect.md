# 消息编码秘密相关分支：人工机制回归

本项目的 vulnerable 是当前 mlkem-native 的人工回归变体，不是新发现的部署漏洞，
也不是历史 clangover 构建的原样复现。公开机制来源见 [来源](sources.md)。
唯一库行为补丁为 [message-branch.patch](patches/message-branch.patch)，只作用于构建目录副本，vendor 原件不修改。

## 源码支持什么

`mlk_poly_frommsg` 实现 Decompress_1：每个消息位映射到系数 0 或 1665。
参考版通过值屏障和常数时间选择实现；回归版用 if/else。
解封装调用链是 `mlkem_decapsulate → baseline_native_dec → mlk_indcpa_dec`
得到秘密相关消息 m'，然后在重加密 `mlk_indcpa_enc → mlk_poly_frommsg` 中按 m' 分支。
输入密文公开，但 m' 来自私钥参与的解密，不能把分支条件当作公开输入。
封装也调用同一编码函数；两版数学输出相同。重加密比较、J(z||c) 和常数时间选择保持原样。

为在本机明确保留分支，回归版只对此函数使用 Clang `optnone,noinline`，
GCC 使用 `optimize("O0"),noinline`。这属于公开标注的人工构建控制，不是声称 Clang 21
在默认 -O2 自动重现历史问题。没有延迟、空转、额外秘密日志或改变拒绝行为。
该函数优化级别不同，因此两版本整体速度差不能单独当成秘密泄露证据。

## 编译产物支持什么

模块三 ARM64 实测的 test_mlkem 反汇编和 SHA-256 在 evidence/module3。
编码函数内 `ldrb → lsr → tbz w8,#0` 显式按消息位选择两条存储路径，
分支位于函数 +0x48；循环边界分支不能作为秘密相关证据。
模块六已检查实际采集程序的完整调用路径，见 evidence/final；CMake 迁移验证另见 evidence/cmake。
这些目录各自绑定独立的二进制摘要，不能跨构建沿用地址。
原 Make 构建为 `-O2 -g`；当前 CMake 默认另有 `-DNDEBUG`，均为无 LTO、C 后端。

## 功能和时序分别支持什么

两版本各通过 60 组 NIST FIPS203 KAT（解封装含 5 接受、5 隐式拒绝），另通过 20 组 NIST 密钥校验。
另用 64 个公开确定性种子，各测试有效、位翻转和随机密文，共 192 次解封装，
比较含完整密钥、密文及输出的 SHA3-256 摘要；篡改和随机样本均核对 J(z||c)。
这属于功能等价证据，不是时序统计检验。
原 Make 产物两版各已采集 5000 条原始时间，CMake 产物也已完成采集验证。
本机已用固定预先规定检验完成统计确认：缺陷版 7/10 比较显著、参考版 0/10，
主效应在恒定消息类与变化消息类之间，见 [统计说明](statistics.md)。
该确认限于 Apple M5 / ARM64 macOS；x86_64 Linux 分支和实测仍待验证。

## 生成器与机制输入

CLI 的 `generate-test` / `decapsulate-test` 明确使用公开测试种子。
生成器先以 SHAKE256(tag || seed_le64 || index_le64) 派生材料，tag=1 为测试密钥种子，
tag=2 为封装消息，tag=3 为随机密文；普通 demo/selftest 使用系统随机源。
`valid` 正常封装；`bit-flipped` 在 valid 上翻转 index 对应字节和位；
`random` 生成正确长度字节串。这些类别由生成器登记，不读取内部验证标志。

`message-zero` / `message-ones` 直接使用当前 FIPS203 Encaps_Internal 的全 0 / 全 1 消息 m，
生成两种有效密文。解封装重加密会编码相应 m'，分别走目标分支的两侧。
这是由消息编码机制导出的最小审计构造，不复制 clangover 的密钥恢复攻击。
测试密钥来自公开种子；生成这两类密文本身只需公钥，但实验没有证明未知密钥攻击能力。
固定密钥下这两类每次重复同一密文，不能声称是独立随机密文总体的样本。
本机统计确认显示：主要时间差异出现在这两类（分支方向恒定）与 valid/bit-flipped/random
（分支方向逐位变化）之间，而这两类彼此之间只有次级差异；这与分支可预测性的解释一致，
但实验没有分离分支预测、指令缓存和前端取指各自的贡献。
有效/篡改/随机输入间的差异在两版均不显著，也不能自动归因为秘密泄露。
