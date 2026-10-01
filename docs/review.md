# 代码审查与风格统一记录

本轮审查覆盖自有 C 接口、随机源、输入生成、CLI、计时、测试校验器、CMake、构建身份脚本及 README。
逐个阅读调用路径和错误分支，并用实际错误输入复现问题；没有把代码格式检查当作正确性审查。
第三方原始源码仅检查接入边界、快照一致性和独立缺陷补丁，不声称重新审计整个上游密码库。

## 已修正的问题

| 问题 | 复现与影响 | 修正及验证 |
|---|---|---|
| CSV 数字解析过宽 | 旧校验器的无符号 scanf 接受 `-1`，也未拒绝尾随字段或跨行运行编号变化；负数原始时间可被误判为有效。 | 严格拆分六列，复用十进制整数解析，检查整列、溢出、运行编号和完整行；加入负数、溢出、尾随文本、混入运行的回归输入。 |
| KAT 尾部截断未被拒绝 | 在完整 80 组向量后追加单独 `keygen`，旧程序仍返回成功；十六进制单字节读取也允许部分解析。 | 每条记录必须读到全部起始字段，编号必须是正十进制数，十六进制字符逐个验证；增加双版本 malformed-vector 检查。 |
| 读取失败后继续读流 | 静态分析发现 fread 失败或短读后仍无条件 fgetc，错误路径会继续操作已失败的流。 | 仅在完整读取密文后探测多余字节；仍统一关闭文件。目录读取、短文件、长文件测试通过，重新静态分析无报告。 |

上述问题分别涉及验收程序的严格性和异常 I/O 路径，没有发现或声称新增密码算法漏洞。
独立修复提交为 `de523be` 和 `b9a758f`；风格提交为 `6a9bd8d`，没有改写已有历史。

## 风格结果

已统一自有 C 文件及头文件的缩进、大括号、换行、include 分组、单变量声明和必要命名。
CMake 的生成元数据移到独立模板，主构建逻辑按固定格式整理；Shell 条件分支不再压缩到一行。
固定 `.clang-format`、`.cmake-format.json`、`.editorconfig` 并提供 `format` / `format-check` 目标。
详细规则与工具版本见 [style.md](style.md)。vendor、固定向量、历史证据均保持原样。

## 验证范围

- 当前功能源码提交：`b9a758fc3f16b9b7292543abd3c2ae6967c21f2a`。
- 从干净工作区新建 build/review，用 CMake/Ninja/RelWithDebInfo 构建：9 项 CTest 全部通过。
- 独立 sanitizer 配置：同一功能代码的 9 项 CTest 全部通过，无 ASan/UBSan 报告。
- clang-format 21 检查、cmake-format 0.6.13 检查、Shell 语法检查均通过。
- Apple Clang 静态分析覆盖 src/main.c、mlkem.c、random.c、inputs.c、measure.c；修复后无报告。
- 两版采集程序各重新采集 100 次；CSV 校验、独立文件摘要和实际缺陷分支均重新核对。

实际平台仍为 Apple M5 / ARM64 macOS。证据见 [evidence/review](evidence/review/README.md)。
这是对当前范围的代码审查和实测，不是无缺陷保证或整库恒时证明；真实 Linux/GCC 和正式时序统计仍未完成。
（本节记录审查当时的状态。此后已完成固定统计确认、恒时编码对照和 Linux 加 GNU GCC 的功能验证，
见 [validation.md](validation.md)；真实 x86_64 Linux 主机实测仍未执行。）
README 已重写为从环境、构建、运行到数据解释和开发检查的使用入口；示例命令在本地执行验证。

## 追加：四模块新增代码的检查补齐（模块四）

上一节记录的是当时的审查状态，**本节只追加，不改写它**。本轮的检查范围是四模块新增的
自有代码与配置，不重新审计 `vendor/`，也不重复上一节已完成的逐函数阅读。

**本轮检查对象**：`src/analyze.c`（第一轮固定族，上一节成文时尚不存在）、
`src/analyze_groups.c` 与 `include/timing_statistics.h` / `src/timing_statistics.c`
（模块三新增的第二轮分组检验与抽出的共用统计例程）、
`docs/patches/message-value-barrier.patch` 与 `src/mlkem.c` 的 `BASELINE_DEPLOYABLE` 分支
（模块一新增的第四个变体），以及它们在 `CMakeLists.txt`、四个 `tests/*.sh` 里的注册。

**修正项**：**无。** 四次静态分析调用（8 个自有源文件 × 默认／`BASELINE_VULNERABLE`／
`BASELINE_HARDENED`／`BASELINE_DEPLOYABLE`）全部 `exit=0` 且无诊断，
格式与脚本语法检查一次通过，因此本轮**没有产生 `fix:` 或 `style:` 提交**。
其中 `src/analyze.c`、`src/analyze_groups.c`、`src/timing_statistics.c` 三个文件
以及 `-DBASELINE_HARDENED=1`、`-DBASELINE_DEPLOYABLE=1` 两个宏设置都是**首次**被静态分析覆盖；
上一节记录的那次只覆盖五个源文件和 `-DBASELINE_VULNERABLE=1`。

**实测平台与结果**：Apple M5 / ARM64 macOS、Apple Clang 21.0.0、CMake 4.3.2。
全新构建目录 `build/review-four-module`（Ninja / RelWithDebInfo、严格警告 + `-Werror`）
零告警构建；`ctest -N` 实测 **18 项**、全部通过；独立 `sanitize` preset（Unix Makefiles /
Debug / ASan+UBSan）同样 18 项全部通过，日志中无 ASan/UBSan/Leak 报告。
`format-check`、`cmake-format 0.6.13 --check`、`tests/*.sh` 与 `tools/*.sh` 的 `sh -n` 均通过
（上一轮评审指出的「`format-check` 结果未归档」本轮已逐字归档）。
四个变体 `measure` 自报的 `executable_digest` 与独立 OpenSSL SHA3-256 逐个一致。
逐字日志见 [evidence/review-four-module](evidence/review-four-module/README.md)。

**边界**：静态分析是范围内的封装／运行／分析代码检查，不是正确性证明、不是恒时证明，
也不是对上游密码库的重新审计。「全部检查通过」只等于检查通过，不等于结论成立。
本节不产出任何时序、产物形态或统计结论；真实 x86_64 Linux 主机时序实测仍未执行，
模块二的 QEMU 模拟不改变这一条。
本轮四个模块的评审产物落在未跟踪目录 `.agents/tasks/four-module-review/`、未进仓库，
因此「四份判定均为 APPROVED、无阻断发现」只能由作者转述，不可从仓库逐字复核。
本轮四模块的逐项验收结论与最终报告见 [acceptance.md](acceptance.md) 的追加章节。
