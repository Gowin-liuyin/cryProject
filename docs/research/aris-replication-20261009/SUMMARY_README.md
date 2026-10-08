# M02三份汇总的专用C复核

本程序只读取新合同指定的三份 `summary.csv`，不执行观察器、统计枚举或密码调用。构建和测试由本目录CMake/CTest统一配置，C11、`-O2`、无LTO；普通和ASan/UBSan分目录。

```sh
cmake -S docs/research/aris-replication-20261009 -B build/aris-replication-20261009/summary-normal -DBUILD_TESTING=ON -DSUMMARY_SANITIZERS=OFF
cmake --build build/aris-replication-20261009/summary-normal --parallel 2
ctest --test-dir build/aris-replication-20261009/summary-normal --output-on-failure
cmake --build build/aris-replication-20261009/summary-normal --target format-check
```

正式记录全部完成且逐进程独立C核验后，入口为：

```text
process_summary M02_EVIDENCE_ROOT NEW_REPORT_FILE
```

它固定读取根下的 `run-1/summary.csv`、`run-2/summary.csv`、`run-3/summary.csv`，只在三份输入全部合格后以新建方式输出JSON，拒绝覆盖已有文件。每表须严格原表头、8行且任务依次1至8；非零数须为20，任务3/7须为0；每任务十对；时钟合格对数允许0至10。比值须为正的有限数，沿用观察器的12位小数格式，且最小值≤中位数≤最大值。字段、scope、额外行、截断末行和嵌入NUL不合格即拒绝。

输出保存24项原表中位比、范围和资格。`summary_direction_supported` 只在六非零任务的18个报告中位比均小于1时为真；任务3/7的全零比值不参与方向判定。`summary_clock_qualification_complete` 要求三表全部240个对应对都合格。二者共同组成 `summary_pattern_supported`。

中位比等于或大于1，以及合格对数小于10，属于有效的负面或资格不足结果，输出照实保存且退出0；它们不是解析失败。JSON的整体主张字段在条件符合时仍为 `awaiting_independent_process_audits_and_artifact_checks`，不替代根的逐进程原值、状态、进程身份、机器码和摘要核对。旧独立审计器仍保持Darwin/arm64及全时钟合格条件，没有因本汇总而放宽。

手写夹具采用三份非零中位0.50/0.75/0.90及已知范围，全零中位1.5；期待18方向支持、240合格对。等于1的单项给出17支持；单项合格数9给出239。另查表头、任务、非零数、重复数、资格数、非有限/负数、范围、scope、精度、溢出、多列、少/多行、末行截断和NUL。输出手写检查另核对正例等待独立核验、负例不支持、24行及来源/总体限制字段。软件检查不生成真实成本数据，也不加载固定旧M01路径；传入目录的真实新进程身份须由根另核对。
