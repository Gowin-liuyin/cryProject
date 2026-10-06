# 2026-10-06 参考版复核证据

对应 [参考版复核记录](../../reference-recheck.md)。本轮仅核验参考功能，不构建其他变体或
计时程序，不重新验证历史时序数据、机器码机制或统计结论。

源码基点为 `a07bbc197d7bcee75be6d21942db88b6844b9ea4`。实测时存在未提交改动：
`tested-source.diff` 保存实际被测的 CMake 与两个测试脚本差异，`tested-source.sha256`
固定这些文件、自有 C / 头文件 / C 测试及独立向量的实际内容。
运行代码、上游快照和固定向量均未改动。文档后续整理不改变这些被测构建和测试文件。
用户原有未跟踪 `.agents/` 仅记录状态，未读取或修改其内容。

## 构建与测试记录

| 配置 | 原始构建目录 | 日志 |
|---|---|---|
| Unix Makefiles / RelWithDebInfo | `build/reference-recheck.zU5HSL` | `configure.log`、`ctest.log`、`ctest-verbose.log` |
| Unix Makefiles / Debug / ASan+UBSan | `build/reference-sanitize-recheck.vvMgT8` | `sanitize-configure.log`、`sanitize-ctest.log` |
| Ninja Multi-Config / Debug | `build/reference-multiconfig-recheck.IghHAq` | `multiconfig-configure.log`、`multiconfig-ctest.log` |

三套配置各执行带 `reference` 标签的 5 项检查，均通过。动态检查无 sanitizer 报告，
其产物与普通构建分开；所有日志中的耗时仅为测试运行信息，不是解封装采集数据。
`test-registration.json` 记录当前注册的 20 个测试名，不表示这 20 项均在本轮执行。
原有全范围 `cli` / `vector_parser` 的改后入口本轮未执行，不能引用本目录为其背书。

`build-identity.txt`、`sanitize-build-identity.txt`、`multiconfig-build-identity.txt`
分别是当时由原构建身份脚本生成的快照，含提交、未提交差异摘要、编译配置和输入清单。
它们保留各自生成时的状态，不伪装成后续文档完成时的干净工作区。
`reference-compile-commands.json` 从普通构建的原命令清单中提取本轮参考库和三个程序的
7 条编译命令。`target-inventory.log` 确认三个全新目录只生成参考功能程序，
`binaries.sha256` 对实际构建目录内的程序和参考库取摘要；没有把二进制副本放进仓库。

`environment.txt` 记录真实 ARM64 macOS 机器、工具链、起始提交、分支和整理时工作区状态。
它不证明真实 x86_64 Linux 执行，也不证明 GitHub 邮箱已验证。

## 来源和开发检查

- `vendor-source-check.log`：上游固定提交的归档内容与库目录、许可证逐文件一致。
  归档 SHA-256 是本次下载字节的记录，来源身份以完整提交和逐文件比较为准。
- `vector-source-check.log`：四份 NIST JSON 与上游固定版本逐字节一致；原转换脚本在
  临时目录重跑，转换文件与固定向量逐字节一致，没有改写预期答案。
- `format-check.log`：clang-format 21 检查通过。
- `development-checks.log`：cmake-format 0.6.13、修改脚本语法、diff 空白检查通过；
  两个脚本均拒绝未知测试范围并返回 2。

在仓库根目录核验：

```sh
shasum -a 256 -c docs/evidence/reference-recheck-20261006/SHA256SUMS
shasum -a 256 -c docs/evidence/reference-recheck-20261006/tested-source.sha256
shasum -a 256 -c docs/evidence/reference-recheck-20261006/binaries.sha256
```

第一条核对本目录内容；第二条要求源码与向量仍保持实测内容；第三条要求原构建目录仍存在且
产物未改变。二进制摘要不保证它可以由其他工具链逐字节复现。
本目录不新增时序样本、观察差异、正式统计确认或全库恒时证明。
