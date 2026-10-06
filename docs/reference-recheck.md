# 参考版独立验收复核

本次复核日期为 2026-10-06。原始第一阶段的六个模块已经存在，继续复用其 C11、
ML-KEM-768、CMake/CTest 实现。本轮增加 `check-reference` 目标、两个带参考版标签的
CTest 入口，并复用原 CLI / 向量解析测试脚本，不另建一套构建规则。
CLI 检查增加了版本标识断言、同种子重复生成一致性、具体错误退出码及拒绝覆盖后的内容核对。

本轮未修改密码算法、随机源、输入生成器或计时逻辑。独立入口仅检查参考版的普通
`valid`、`bit-flipped`、`random` 三类测试输入，不执行其他变体、机制输入或时序采集。

## 来源与规范口径

- 库来源为 [mlkem-native](https://github.com/pq-code-package/mlkem-native)，固定提交
  `b3ba7b32773e657dd37f6f87bce82528459ad8a4`。从该提交获取上游归档，逐文件比较确认
  `vendor/mlkem-native/mlkem/` 与许可证原件相同。作者时间为 2026-09-21，提交者时间为
  2026-09-22；完整标识优先于日期。库许可证为 Apache-2.0 OR ISC OR MIT。
- 独立答案来自 [NIST ACVP-Server 固定提交](https://github.com/usnistgov/ACVP-Server/tree/975de31eb83d87039ec88934fdc47d8c312b892d/gen-val/json-files)
  `975de31eb83d87039ec88934fdc47d8c312b892d`。在线重新获取四份 JSON 原件并逐字节比较，
  在临时目录运行原转换脚本，再与固定 `mlkem768.txt` 比较，全部一致。固定向量未写入或修改。
- 规范为 [2024-08-13 FIPS 203](https://csrc.nist.gov/pubs/fips/203/final)，参数为 ML-KEM-768。
  NIST 页面另有 2025-11-17 的潜在勘误提示。本轮仅验证固定向量和封装边界，
  不据此宣称已覆盖全部标准条文、勘误或获得 FIPS 模块认证。
- 长度分别为封装公钥 1184 字节、解封装私钥 2400 字节、密文 1088 字节、共享密钥 32 字节。
  仓库另有明确标注的人工机制回归及对照材料；本轮参考版结果不为它们提供新的验证结论。

## 可执行命令

在仓库根目录执行：

```sh
cmake --preset baseline
cmake --build --preset baseline --target check-reference --parallel
cmake --build --preset baseline --target format-check
build/cmake/reference/baseline version
build/cmake/reference/baseline selftest
build/cmake/reference/baseline demo

cmake --preset sanitize
cmake --build --preset sanitize --target check-reference --parallel
```

如需单独重复已构建的五项检查，使用 `ctest --preset baseline -L reference`。
`check-reference` 本身会构建所需产物，不要求先执行全量构建。

普通测试输入使用公开测试种子，输出路径必须是新路径：

```sh
mkdir -p runs
reference_input_directory=$(mktemp -d runs/reference-input.XXXXXX)
build/cmake/reference/baseline generate-test valid 42 "$reference_input_directory/input.bin"
build/cmake/reference/baseline decapsulate-test 42 "$reference_input_directory/input.bin"
```

同一入口也接受 `bit-flipped` 和 `random`。这些种子仅供测试，不用于真实秘密。
短文件、超长文件和读取错误在调用固定长度内核前拒绝；正确长度的无效密文不公开内部验证结果。

## 本轮实测

实际机器是 Apple M5 / ARM64 macOS 26.6.2（Darwin 25.6.0），Apple Clang 21.0.0，
CMake 4.3.2。普通与动态检查使用两个全新目录；另用第三个全新目录核验多配置目标。

| 构建或检查 | 结果与覆盖 |
|---|---|
| Unix Makefiles / RelWithDebInfo | 严格警告含 `-Werror`，参考版 5/5 CTest 通过 |
| Unix Makefiles / Debug / ASan+UBSan | 参考版 5/5 通过，无 sanitizer 报告 |
| Ninja Multi-Config / Debug | `check-reference` 正确选择 Debug，参考版 5/5 通过 |
| NIST KAT 与公开参数 | 25 keygen、25 encaps、10 decaps（含 5 隐式拒绝）、20 密钥校验；空指针和错误长度检查通过 |
| 随机源失败 | `/dev/urandom` 打开失败被传播，恢复文件描述符限制后系统随机往返通过 |
| CLI 与向量解析 | 三类普通输入、公开种子可复现、错误种子、拒绝覆盖、短/长/目录输入；截断向量、非法编号、非法十六进制均被拒绝 |
| 格式和脚本 | clang-format 21、cmake-format 0.6.13、两个修改脚本的 `sh -n`、`git diff --check` 通过 |

当前注册 20 项 CTest；本轮仅执行上述带 `reference` 标签的 5 项。
原有全范围的 `cli` 和 `vector_parser` 入口继续保留，但本轮未重新执行它们。
全新目录中只生成参考版 CLI、KAT 程序、随机源失败程序及参考库，没有其他变体或计时可执行文件。
日志、构建输入身份、实际二进制摘要和精确被测差异见
[本轮证据](evidence/reference-recheck-20261006/README.md)。

## Git 历史与范围

开工提交为 `a07bbc197d7bcee75be6d21942db88b6844b9ea4`，分支为 `main`。
当次 `git ls-remote origin HEAD refs/heads/main` 成功但无输出；没有自动 push 或修改历史。
用户原有 `.agents/` 未跟踪目录保留。本轮检查使用有未提交改动的工作区，
因此证据以开工提交加 `tested-source.diff` 和逐文件摘要标识，不写成干净提交测试。

原始六模块提交按顺序为：

| 模块 | 已有完整提交 |
|---|---|
| 工程骨架、来源、构建 | `1496366564726c9688e3a53ec0ce5b9585a15871e` |
| 参考功能 | `bf983daa543b5dac4d8f63b4f357fca253451175` |
| 历史实验变体 | `d25a0217bb98979777e747d000f3b06e4c039b46` |
| CLI 与输入 | `e021da456b32cc9ad4eab974050de5cc01cd7a14` |
| 基础采集 | `b83592d386e2d91b77c6020037254de2d84c66fd` |
| 集成验收 | `e519d941ddcf8a4dfb9e92f5b9343db53fc36064` |

这些是已有历史，不是本轮重新实现或重新验收的六个模块。
本轮不产出目标缺陷机制、原始时间、观察差异或正式统计确认的新结论，也不是整库恒时证明。
真实 x86_64 Linux 功能验收仍须在真实目标机器执行。
下一阶段的参考功能验证可直接使用同一 `check-reference` 目标；动态检查结果不作为性能数据。

## 追加：本轮验收收口（2026-10-06）

上文及 `reference-recheck-20261006/` 保留首轮身份，不改写其日志。本次以相同源码基点
`a07bbc197d7bcee75be6d21942db88b6844b9ea4` 加未提交参考入口差异重新构建，
新记录存于 [reference-close-20261006](evidence/reference-close-20261006/README.md)。
旧目录 `SHA256SUMS` 与 `tested-source.sha256` 全部通过核对。

普通 RelWithDebInfo 与独立 Debug/ASan+UBSan 各执行 `check-reference` 的 5 项，
再执行 `vulnerable/hardened/deployable` 各自 KAT、随机源失败、三组等价、公共 `cli`
和 `vector_parser` 共 11 项：每个配置覆盖 16 个不同测试，全部通过。
Ninja Multi-Config/Debug 另执行参考 5 项，正确选择 Debug 路径。
两脚本不传范围参数仍检查四版五类，未知范围返回 2；其默认入口现有本轮执行证据。

独立入口的依赖仍只有参考 CLI、KAT、随机失败程序和参考库；三套全新目录在执行公共
构建前的产物清单证明没有其他变体或 `measure`。本次没有执行 `measurement`、`analysis`、
`analysis_groups`、`analysis_round1_replay`，也没有新时序采集。
三套 `format-check`、CMake 格式、修改脚本语法、差异空白检查通过。
源码差异与逐文件摘要、分阶段构建身份和二进制摘要保留实际检查时的状态；
之后的提交号不能替换这些日志中的旧 HEAD。
