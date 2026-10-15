# Kyber768 第 3 轮公开 KAT 来源

此目录保存上游公开已有答案，未运行本仓库密码实现生成或改写预期值。
`PQCkemKAT_2400.rsp` 和 `.req` 是下列官方提交包成员的原始完整字节。

- 上游说明页：<https://pq-crystals.org/kyber/resources.shtml>，其 “NIST Submission Package for round 3” 链接说明提交包包含参考实现与测试向量。
- 下载地址：<https://pq-crystals.org/kyber/data/kyber-submission-nist-round3.zip>。
- 获取日期：2026-10-16（Asia/Shanghai）；HTTP 响应日期为 2026-10-15 17:32:32 UTC。
- 压缩包大小：7365066 字节。
- 压缩包 SHA-256：`3e5bc2254cb6b5e4f3085e1ccfad1574a5cb2e4ac864a59145a0d32ac0994eaa`。
- 原始下载及核对用源码暂存在仓库的 `build/platform-s4/kat-fetch/`，该构建目录不是封存证据。

## 原始成员及摘要

下列成员路径均相对于压缩包根 `NIST-PQ-Submission-Kyber-20201001/`。
本目录文件的 SHA-256 另列于 `SHA256SUMS`。

| 本目录文件 | 上游压缩包成员 | 字节数 | SHA-256 |
| --- | --- | ---: | --- |
| `PQCkemKAT_2400.rsp` | `KAT/kyber768/PQCkemKAT_2400.rsp` | 954802 | `a1e122cad3c24bc51622e4c242d8b8acbcd3f618fee4220400605ca8f9ea02c2` |
| `PQCkemKAT_2400.req` | `KAT/kyber768/PQCkemKAT_2400.req` | 13590 | `36c27b6089b8910733a01fea1136469769b3ca3c35f2b375cfcc592f2112cfaa` |
| `LICENSE.package-clean` | `Additional_Implementations/clean/crypto_kem/kyber768/LICENSE` | 375 | `f05027deb2fc00f33209a5f4ee0f425e95c745219f43cd69edbe3684fe0a22bb` |

`.rsp` 首行为 `# Kyber768`，保留 count 0 至 99 的 100 例完整答案。
每例包含 `seed` 48 字节、`pk` 1184 字节、`sk` 2400 字节、`ct` 1088 字节和 `ss` 32 字节。
count 0 的种子为：

```text
061550234D158C5EC95595FE04EF7A25767F2E24CC2BC479D09D86DC9ABCFDE7056A8C266F9EF97ED08541DBD2E1FFA1
```

## 算法版本映射

这是 2020-10-01 第 3 轮提交的 **Kyber768（SHAKE 版本）**，不是 Kyber768-90s，也不是 FIPS 203 ML-KEM-768。
文件名中的 2400 是历史 Kyber768 私钥序列化长度，不是安全参数。
S4 对应的两个候选上游快照为：

- `pq-crystals/kyber`，`a621b8dde405cc507cbcfc5f794570a4f98d69cc`（KyberSlash 修复前）。
- `pq-crystals/kyber`，`272125f6acc8e8b6850fd68ceb901a660ff48196`（本项目固定的 round3 修复后快照）。

上述映射只说明历史算法及测试目标，不能代替两个实际链接产物各自通过本公开 KAT 的检查。
本次资料获取没有执行密码算法、计时或远端任务。

## NIST DRBG 调用契约

契约直接读取同一提交包中 `Reference_Implementation/crypto_kem/kyber768/` 的公开源码；没有运行它生成答案：

1. `PQCgenKAT_kem.c` 对每例调用 `randombytes_init(seed, NULL, 256)`，然后依次调用 `crypto_kem_keypair`、`crypto_kem_enc` 和 `crypto_kem_dec`。
2. `indcpa.c` 的 `indcpa_keypair` 调用一次 `randombytes(..., 32)`，随后以 `hash_g` 展开该 32 字节输入。
3. `kem.c` 的 `crypto_kem_keypair` 在上述操作后再调用一次 `randombytes(..., 32)`，用于隐式拒绝的 `z`。
4. `kem.c` 的 `crypto_kem_enc` 再调用一次 `randombytes(..., 32)`，然后先对该输入做 `hash_h`。解封装不取随机数。
5. `rng.c` 使用 NIST AES-256 CTR DRBG：初始化时 Key/V 全零，把 48 字节种子作为 Update 的输入；每次 Generate 完成后调用 `AES256_CTR_DRBG_Update(NULL, ...)` 并递增 reseed counter。V 是 16 字节大端加一，Update 生成三块并更新 32 字节 Key 和 16 字节 V。

因此本例熵请求边界必须保留为 **32 + 32 + 32 字节三次请求**。
不能将 keypair 的两次请求合并为 64 字节，也不能把 `.rsp` 的 48 字节种子直接当作算法的 32 字节输入。

供核对的公开源文件 SHA-256：

| 源码文件 | SHA-256 |
| --- | --- |
| `PQCgenKAT_kem.c` | `21f5cdc7b53fb06fd5a3ae8228b6f4fc6a6a9692aaa688adadcf4d6f887538cc` |
| `rng.c` | `cb3c077ef360f1004336600e125a0b8db5d91b0dfd99034116d2fd1f4235cbf5` |
| `kem.c` | `7ad59b9d164055aa1a2f1699523ae65d3c2efd49e6e23b0f4ec1ddf3fb95d04d` |
| `indcpa.c` | `631a5b641ad89564576bbfca8a2717113e802e46d46221dece3b291ac802b1cf` |

## 来源和许可记录

这是 CRYSTALS 团队自行发布的 NIST 第 3 轮提交材料，不是由本项目产生的测试集。
原始 KAT 文件没有单独许可证头，提交包也没有总根目录 LICENSE；不把其他子目录的许可冒称为 KAT 单独授权。
为保留包内已有许可说明，原样附带同包 Kyber768 clean 实现的 `LICENSE.package-clean`，其中声明 Public Domain 并列出作者。

另保存目标上游提交 `272125f6acc8e8b6850fd68ceb901a660ff48196` 的原始仓库许可证为 `LICENSE.upstream-272125f6`：
<https://raw.githubusercontent.com/pq-crystals/kyber/272125f6acc8e8b6850fd68ceb901a660ff48196/LICENSE>。
它声明 Public Domain（CC0）或 Apache 2.0；SHA-256 为 `53681bce13fd98721b4cabcd0b6184c6a92d9de813a02536161cc706e4ea9f2e`。
这份相关源码许可证与提交包中的许可记录分别保留。

## 获取与静态核对

使用 HTTPS `curl --fail --location` 下载压缩包，随后用 `unzip -p` 原样提取上述三个成员；未转换换行或裁剪向量。
已用 `cmp` 将保存文件与再次从同包提取的字节比较，并检查 100 例编号连续、字段齐全、十六进制字符和固定长度。
这些完整性检查不表示两个目标实现已经通过 KAT。
