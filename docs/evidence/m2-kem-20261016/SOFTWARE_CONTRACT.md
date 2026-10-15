# M2 完整历史 KEM 软件合同

本轮是完整功能接线和采数前资格，不执行任何 `measure` 采数命令，不写调频或隔离配置。
统计家族、锁频批次和样本量须由主控另立 PLAN 并提交后执行；dudect 不进入 Holm 家族。

## 不变对象

- 未修 `pq-crystals/kyber`：`a621b8dde405cc507cbcfc5f794570a4f98d69cc`。
- KyberSlash1/2 已修对照：`272125f6acc8e8b6850fd68ceb901a660ff48196`。
- 独立 `vendor/kyber-kyberslash-{unfixed,fixed}/ref`，原件只读，不改 M1 vendor 或历史证据。
- `KYBER_K=3`、历史 **Kyber768 round3 SHAKE 版本**，非 Kyber768-90s，非 FIPS 203。
- 新 CMake 模块只向根构建注册独立库、CLI 和测试；没有 AVX2 分发或跨变体链接。

## 接口及随机源

`src/platform_m2_adapter.c` 实现已有 `mlkem.h` ABI，长度和空指针检查先于固定长度内核。
密文格式正确长度但重加密验证失败时，保留原 `kem.c` 隐式拒绝和返回 0，不输出内部验证结果。
调用者仍须遵守该 ABI 的缓冲区不重叠约定。

普通 keygen/encap 分别先以 `system_random_bytes` 取得 64/32 字节。读取失败即返回随机源错误、
清理输入随机量并清零整份输出，不进入上游算法。上游 `randombytes` 在构建时单独重命名为
`platform_m2_randombytes`，仅从线程局部的已取得随机量中消费；结束核对消费量并清理上下文。
普通生产CLI和内核不链接 NIST DRBG 或 OpenSSL；公开KAT测试二进制单独使用二者。

`platform_m2_test_*` 与 `inputs.h` 的确定性入口只接受明确的公开测试输入。
测试所用 keygen 64 字节是两次上游随机请求的拼接；复算 NIST KAT 时，DRBG 仍按
32+32+32 三次独立请求更新，不能用一次 64 字节 Generate 替代前两次。

## 输入类

`valid` 和 `bit-flipped` 使用固定公开种子、sample_index 的域分离 SHAKE256 测试随机量，
经过上游原 `crypto_kem_enc`，后者先对其 32 字节随机输入做 H。
`bit-flipped` 再确定性翻转一位；`random` 是公开测试种子生成的完整随机形态密文。

`message-zero` 与 `message-ones` 直接选择实际解密消息 00/FF，通过
`G(message || H(public_key))` 导出原算法的 coins，调用未修改的 `indcpa_enc`，
随后按原版 `SHAKE256(prekey || H(ciphertext))` 导出共享秘密。
这是显式测试入口：不能把原 `crypto_kem_enc` 的全零随机输入误称为全零消息，因为原版会先 H。
固定 key 下这两类各只有一份确定性密文；这限制后续统计推广范围。

## 资格门

1. 官方 round3 完整 `.rsp` 100 例，每版逐字核对公钥、私钥、密文和共享秘密，并检查解封装。
2. 普通安全随机 roundtrip，错误长度/空指针先验，系统随机源失败路径。
3. 五类各 32 例，验证选择消息实际解密为 00/FF，64 例篡改/随机密文符合原拒绝公式。
4. 未修/已修分别生成公开测试 transcript，核对 key 字节与 160 个类例全部一致。
5. 普通与 ASan/UBSan 构建分别跑相同资格；动态检查产物不用于正式采数。
6. 主控接入 `main.c` 与 `measure.c` 的 M2 宏分支，CLI 版本须明确非 FIPS 203；只编译 measure。

源答案与原始许可说明见 `tests/vectors/kyber768_round3/SOURCE.md`，不由本工程自产 expected。
KAT 全部匹配仍不构成恒时证明，已有热点 varlat 结论也不能直接升级为完整解封装统计阳性。

## 提交日期口径补充

旧版本审计中将 fixed 日期简写为 2023-12-29；其原始 Git 元数据实际是作者日期 12-29、
提交者日期 12-30，官方库状态页也列补丁日 12-30。此处区分两种日期，不改写旧证据原件。
