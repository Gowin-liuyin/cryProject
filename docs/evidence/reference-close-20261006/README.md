# 参考验收收口：2026-10-06

新运行承接 `../reference-recheck-20261006/`，不替换上一轮。源码 HEAD 为
`a07bbc197d7bcee75be6d21942db88b6844b9ea4` 加 `tested-source.diff` 中未提交改动；
`tested-source.sha256` 固定被测文件。Apple M5/ARM64 macOS 26.6.2，Apple Clang 21，
CMake 4.3.2；具体目录见 `build-directories.json`。`.agents/` 仅列状态，未读取或暂存。

| 配置 | 实际执行 | 结果 |
|---|---|---|
| release / Unix Makefiles / RelWithDebInfo | 参考 5 项 + 公共 11 项 | 16/16 |
| sanitize / Unix Makefiles / Debug / ASan+UBSan | 参考 5 项 + 公共 11 项 | 16/16，无动态检查报告 |
| multi / Ninja Multi-Config / Debug | 参考 5 项 | 5/5 |

参考 5 项：`reference_kat`、`reference_random_failure`、`reference_cli`、
`reference_vector_parser`、`vector_integrity`。
公共 11 项：`vulnerable_kat`、`vulnerable_random_failure`、`hardened_kat`、
`hardened_random_failure`、`deployable_kat`、`deployable_random_failure`、
`equivalence_vulnerable`、`equivalence_hardened`、`equivalence_deployable`、`cli`、`vector_parser`。
所有命令及返回码见日志首尾。不运行 `measurement` 或统计集成入口。

`*-reference-only-inventory.txt` 与 `*-reference-identity.txt` 保存公共构建之前的状态，
随后公共构建的身份单独保存。源码、独立向量、运行代码没有本轮功能修改。
三套格式检查、CMake 格式、修改脚本语法、未知范围返回 2、diff 检查通过。
旧证据目录摘要及被测文件摘要均逐项通过，见 `previous-*-check.log`。
二进制摘要指向构建目录，没有归档二进制副本，也不表示跨工具链逐字节可复现。

在仓库根目录核验本目录及被测身份：

```sh
shasum -a 256 -c docs/evidence/reference-close-20261006/SHA256SUMS
shasum -a 256 -c docs/evidence/reference-close-20261006/tested-source.sha256
shasum -a 256 -c docs/evidence/reference-close-20261006/binaries.sha256
```

后两条要求被测源码和构建目录未变；后续修改后的不匹配不代表历史证据被重写。
本目录提供功能验收，不产出性能、秘密归因或真实 x86_64 Linux 结果。
