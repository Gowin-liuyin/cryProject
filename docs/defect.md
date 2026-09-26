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
最终 CLI/计时产物将在模块六重新检查并单独记录，不能沿用该测试产物的地址。
整体编译 `-O2 -g`，无 LTO，Apple Clang 21.0.0，C 后端。

## 功能和时序分别支持什么

两版本各通过 60 组 NIST FIPS203 KAT（解封装含 5 接受、5 隐式拒绝）。
另用 64 个公开确定性种子，各测试有效、位翻转和随机密文，共 192 次解封装，
比较含完整密钥、密文及输出的 SHA3-256 摘要；篡改和随机样本均核对 J(z||c)。
这属于功能等价证据，不是时序统计检验。
本模块尚未采集时序；x86_64 Linux 分支和实测仍待验证。
