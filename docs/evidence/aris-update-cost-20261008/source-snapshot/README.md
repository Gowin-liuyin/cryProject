# 固定整数更新成本消融实现

本目录落实上级[冻结合同](../UPDATE_COST_CONTRACT.md)。这里只有纯 C 数学源码、严格加载和成本观察器；不链接或调用 ML-KEM、缺陷变体、vendor、散列实现或秘密输入。当前只完成软件检查和产物准备，**未执行正式比较**。根任务须独立审查后执行合同规定的一次正式运行。

## 固定源码及构建

`snapshots/controlled_snapshot.c` 与当前 `src/controlled_statistics.c` 逐字相同，SHA256 为 `a6dfcecab1035da729ce1cd4c2e54a24553b375b65b29857bac91b1e7a76ceb6`。`snapshots/paired_statistics_snapshot.c` 和两个头文件也逐字保存自有生产源码。副本未格式化。

朴素副本 `snapshots/naive_snapshot.c` 的 SHA256 为 `59b4b3323fe36926e3019412ad83a3c65b4e1128fdeceebda37ace3c3d76c537`。唯一算法差分是替换 Gray 状态的增量和值块：每个状态从零重新遍历所有差值，并移除只服务增量更新的前态变量。输入检查、初始化、Gray 顺序、绝对值、含等值上尾、结果及可选区间代码保留；函数名由各翻译单元的编译宏分别映射。完整差分见 [checks/baseline-naive.diff](checks/baseline-naive.diff)。

独立 CMake/CTest 是本目录唯一构建和测试配置；根工程配置没有改动。普通与 sanitizer 构建目录分离，sanitizer 产物拒绝正式运行。两个统计函数分别编译，均为 C11、同一编译器、`-O2`、`-fno-lto`。没有 `volatile`、函数级优化控制或人工延迟；允许自然向量化。数学随机索引依赖保留在独立自有源码副本，不在本次 `compute_interval=0` 路径执行。

```sh
cmake -S docs/research/aris-20261008/update-cost \
  -B build/aris-research-20261008/update-cost-normal \
  -DBUILD_TESTING=ON -DUPDATE_COST_SANITIZERS=OFF
cmake --build build/aris-research-20261008/update-cost-normal --verbose
ctest --test-dir build/aris-research-20261008/update-cost-normal --output-on-failure
cmake --build build/aris-research-20261008/update-cost-normal --target format-check

cmake -S docs/research/aris-20261008/update-cost \
  -B build/aris-research-20261008/update-cost-sanitize \
  -DBUILD_TESTING=ON -DUPDATE_COST_SANITIZERS=ON
cmake --build build/aris-research-20261008/update-cost-sanitize --verbose
ctest --test-dir build/aris-research-20261008/update-cost-sanitize --output-on-failure
```

当前环境为 Apple Silicon/macOS、Apple Clang 21。普通和 ASan/UBSan 各 3/3 通过，最终检查见 `checks/*tests-final.log`。第一项检查两方法各六组独立手算，包括 2/16、16/16、8/16、最大负整数边界及全零；另查空指针、对数上下界、范围外整数、额外行、截断、非法数字和溢出。第二项严格读取 24 份归档文件，核对字段、来源、SciPy/NumPy 版本、计数及十进制 p 值，错任务声明/报告共 16 次拒绝，未执行 20 对统计函数或计时比较。第三项软件检查普通入口的缺输入失败、零调用/消费终态及已有目录不覆盖，动态构建则检查正式入口拒绝；该项未执行统计窗口。测试预期不由候选程序生成。

`checks/normal-build.log` 保留第一次编译失败：元数据打印遗漏校验和参数。后续修复与最终成功日志另存，没有删去失败。失败留证修订时的重复声明编译错误同样保留在 `checks/clock-failure-revision-build-failed.log`，最终修复构建另存。`checks/compile_commands.json`、`checks/link.txt`、`checks/source-manifest.txt` 和 `checks/source-and-binaries.sha256` 固定当前构建事实。后二进制摘要分别指普通和动态检查产物。

## 观察器边界

正式入口仅为 `update_cost INPUT_EVIDENCE_ROOT NEW_OUTPUT_DIRECTORY`。证据根固定按 `confirmation-data/task-1.csv` 至 `task-8.csv`、对应 plan，以及 `confirmation-results/task-1-r1-baseline.report` 至 `task-8-r1-baseline.report` 读取。CSV 每份须恰为 20 对、四列、连续索引、`call_count=1`，总值及差值满足生产边界；字段、额外行、无换行末行和嵌入 NUL 均拒绝。计划的场景、来源、种子、交换声明及 iid 声明按原八任务核对，不将声明当成真实总体证明。

计数期待直接加载归档独立 SciPy 报告，同时核对合同八个尾数和分母。每方法每任务只预热一次；每任务十对正式调用，按重复编号交替先执行的方法，每方法五次先执行。读钟、校验、结果消费和日志均位于函数窗口外。无 LTO 保持完整统计函数的独立边界；窗口包含验证、初始化、完整枚举及结果整理，不能解释成纯加法内循环。

主程序入口读取 `CLOCK_MONOTONIC`，30 秒预算包含其后的输出初始化、加载/保存、256 连续读钟步长、256 空窗口、预热、正式统计、原始记录写入、输入字节复查、配对摘要及原输出关闭。每次调用前后检查预算；已完成的原窗口照实保存，不扣读钟开销。末尾的状态发布另记录起止采样边界，并明示最后边界行与关闭不在该采样内；该管理窗口不是外部整个进程墙钟。系统摘要和构建/反汇编同样在管理窗口外。

所有成功结果逐次核对期待尾数、分母、均值、p 值、变异标志及零区间，然后纳入可观察校验和与消费数。全部输入的原字节保存在输出 `inputs/`，正式后重新读取原 24 份文件逐字比较。C 观察器不计算散列、不宣称自行验证 plan 的摘要；外层启动记录必须核对原封存 SHA256，再固定输入/源/产物摘要，并在运行后复核摘要。这项分工避免额外引入密码依赖。

校准中途失败会在窗口外保存已完成的校准缓冲。函数读钟失败行保留已知起止和返回结果，缺失的时间明确为 `unavailable`，不纳入有效正式/消费/配对计数。原时间写入 `raw-times.csv`，全部 512 个读钟校准原值写入 `raw-clock.csv`；`pairs.csv` 和 `summary.csv` 给出每任务十个对应比值、中位数及范围，没有置信区间或总体推断。失败写入 `failures.csv` 和终态，保留部分文件。状态先写入 `final-state.pending`；写入及关闭成功后，通过不会覆盖目标的原子硬链接发布 `final-state.meta`，准备文件保留为发布过程证据；单独的准备文件不能作为发布成功事实。原零任务 3/7 字节重复、均为全零，保留八任务而不冒称八种不同 CSV；零任务始终标记 `zero_vector_no_per_state_claim`。非零任务也只标为等待外部产物审查，不能由计数一致自动获准机制解释。

## 正式启动前与之后

以下是根任务的执行规范，本实现任务未运行正式入口。先在仓库根核对封存清单，退出必须为 0：

```sh
shasum -a 256 -c docs/evidence/controlled-comparison-20261007/SHA256SUMS
```

在一个新的外围留证目录保存该核对日志；记录源版本、未提交摘要、合同/本目录完整源码摘要、实际编译及链接命令、普通产物摘要、机器与工具链。针对指定的 8 CSV、8 plan、8 `r1-baseline.report` 生成本轮 SHA256 清单。不要只给任意替换输入记录新摘要，必须先核对原封存清单。原档案和已提交证据不得改写。

审阅 [增量函数反汇编](checks/incremental-assembly.txt)、[朴素函数反汇编](checks/naive-assembly.txt) 和[链接符号](checks/linked-symbols.txt)。当前静态阅读见增量 changed-bit 定位及单项更新，朴素函数自然 NEON 向量化后仍逐 Gray 状态载入并求和；零阈值处没有发现整循环直接返回的捷径。最终资格由根任务独立审查，不由这段实现说明代签。

正式输出必须是尚不存在的新子目录，外围留证目录可以已建立；不要预建传给观察器的输出目录。启动一次：

```sh
build/aris-research-20261008/update-cost-normal/update_cost \
  /Users/yin/code/cryProject/docs/evidence/controlled-comparison-20261007 \
  /absolute/new/evidence/directory/run
```

保存真实退出码。成功应有 16 个预热、160 个正式窗口、176 次结果消费、512 个校准原值，以及 80 个对应比值；`final-state.meta` 记录管理窗、预算、校验和、字节核对、发布边界与平台。运行后复核原 24 文件摘要，并核对输出原输入副本摘要。输出封存前再核对二进制和实际源文件没有改变。

每个算法窗口只有达到 `100 × max(标称分辨率, 空窗中位值)` 才支持该窗口成本解释；太短时仍保存原值但资格记不足。产物折叠、计数不符、输入改变、写入/读钟失败或预算耗尽均停止，不换编译器、任务或重复次数挽回结果。已有失败和当前软件检查没有代表正式比较已经成功。

时钟与磁盘故障未作动态注入；有关失败边界经过独立源码审查，不能写成动态故障测试通过。本实现未检查整个产品或真实密码统计前提，未运行正式比较；这些结果不能关闭 R02/R04 或替代最终报告、匿名包及人员审批。
