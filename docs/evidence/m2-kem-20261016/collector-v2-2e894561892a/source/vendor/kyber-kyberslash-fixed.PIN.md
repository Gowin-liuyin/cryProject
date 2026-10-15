# M2 历史 Kyber768 已修快照

- 来源：<https://github.com/pq-crystals/kyber>
- 完整提交：`272125f6acc8e8b6850fd68ceb901a660ff48196`，提交元数据 2023-12-29；官方 libraries 页列补丁日 2023-12-30；无对应 exact tag。
- 选择：直接承接 KyberSlash1 修复 `dda29cc63af721981ee2c831cf00822e69be3220`，并修复 `poly_compress`、`polyvec_compress` 的 KyberSlash2。不能把 dda29cc 单独视为二者均修复。
- 取得：`git archive --format=tar <commit>`；原 tar SHA-256 `e3d020a78c59fc7248f64a4ca774db5ca8c6bc537e8c682a9fd0049a09180803`。
- 许可证：原 `LICENSE` 为 CC0/Public Domain 或 Apache-2.0；Keccak/AES 作者与公共领域说明保留在上游文件。完整原许可证随快照保留。
- 仅使用 `ref/`，`KYBER_K=3`。这是历史 Kyber768，不能称为 FIPS 203 ML-KEM-768；本钉版也不表示后续其他问题均不存在。
- 快照不修改。完整上游归档保留符号链接，例如 `avx2/.gitignore -> ../ref/.gitignore`；不解引用、不格式化 vendor。检出树由根 `.gitignore` 排除，固定获取脚本和摘要入库。
- 重取：[fetch_vendor.sh](../docs/evidence/m2-kyberslash-20261016/version-audit/fetch_vendor.sh)，只接受目标目录均不存在的情况，拒绝覆盖。
- 审计：[VERSION_AUDIT.md](../docs/evidence/m2-kyberslash-20261016/VERSION_AUDIT.md)。Linux Clang18 `-Oz` 对照三函数的 `div` 消失，仅限定这组产物与路径。
