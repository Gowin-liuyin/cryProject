# M2 历史 Kyber768 未修快照

- 来源：<https://github.com/pq-crystals/kyber>
- 完整提交：`a621b8dde405cc507cbcfc5f794570a4f98d69cc`，2023-05-09；无对应 exact tag。
- 选择：KyberSlash1 官方修复 `dda29cc63af721981ee2c831cf00822e69be3220` 的直接父提交。
- 取得：`git archive --format=tar <commit>`；原 tar SHA-256 `509548a1741473cab69fe403eb685282419bc2a42554d358f16b9e991c88ac08`。
- 许可证：原 `LICENSE` 为 CC0/Public Domain 或 Apache-2.0；Keccak/AES 作者与公共领域说明保留在上游文件。完整原许可证随快照保留。
- 仅使用 `ref/`，`KYBER_K=3`。这是历史 Kyber768，不能称为 FIPS 203 ML-KEM-768。
- 快照不修改。完整上游归档保留符号链接，例如 `avx2/.gitignore -> ../ref/.gitignore`；不解引用、不格式化 vendor。检出树由根 `.gitignore` 排除，固定获取脚本和摘要入库。
- 重取：[fetch_vendor.sh](../docs/evidence/m2-kyberslash-20261016/version-audit/fetch_vendor.sh)，只接受目标目录均不存在的情况，拒绝覆盖。
- 审计：[VERSION_AUDIT.md](../docs/evidence/m2-kyberslash-20261016/VERSION_AUDIT.md)。Linux Clang18 `-Oz` 目标三函数各含一个 `div`，不把源码除法直接等同于产物指令。
