# 平台统计电池

该入口只分析已有 CSV，不启动硬件计时或频率控制。先冻结模块 PLAN，再由独占采数任务生成原始输入。
不能将合成测试结果当作 M2/M5 或真实 x86 Linux 证据。

## 构建与调用

根 CMake include `cmake/PlatformStats.cmake` 后：

```sh
cmake -S . -B build/cmake -DBASELINE_ENABLE_PLATFORM=ON
cmake --build build/cmake --target platform_stats
ctest --test-dir build/cmake -R '^platform_stats_battery$' --output-on-failure
scripts/run_stats_battery.sh --input times.csv --output-dir build/stats-new \
    --format wide --stats-bin build/cmake/platform_stats
```

两列宽表的固定表头是 `class0_ns,class1_ns`，每行两个非负整数纳秒值；至少每类两个值。
这两列是两组观测，不按配对检验处理。归一化时按每行 class0/class1 交错写出，
因此宽表离线 dudect 的顺序是适配器构造的顺序，不代表原始采集顺序。

measure 长表的固定表头是
`run_id,implementation,input_category,sample_index,elapsed_nanoseconds,time_unit`。
仅接受单一 run_id、implementation 与 `ns` 单位，防止把多次运行静默合并：

```sh
scripts/run_stats_battery.sh --input raw.csv --format measure \
    --classes message-zero message-ones --output-dir build/stats-measure \
    --stats-bin build/cmake/platform_stats
```

选择的类别保留原顺序；其他类别的行明确记入 excluded_other_category_count，原 CSV 全量保存。
不接受引号字段、CRLF、空行、截断行、负数、小数、NaN、额外列；
数值不超过 2^53-1 纳秒，最多 2000000 条入选记录。sample_index 只校验非负整数，
不把它当作独立性或唯一性证明。输入上下文仍须由模块 PLAN/ENV 审查。

## 统计口径

`ci_welch.json` 复用 `src/timing_statistics.c` 的两组样本均值、样本方差、Welch t 与自由度。
95% 区间为差值 ±1.959963984540054×SE，p 为 erfc(|t|/sqrt(2)) 的大样本正态近似，
并非有限样本的精确 Student t p 值；极大 |t| 的浮点 p 可能下溢为 0，须同时看 t，不能称数学 p 恰为 0。零方差时不伪造 p，输出 null 与 degenerate 状态。
不删普通长尾，不对原值做截尾、Winsorize 或扣除时钟开销。
每一份 CSV 仅产出单项摘要；外层必须按已提交 PLAN 的假设族另做 Holm。

RTLF 直接执行审查过的上游 `rtlf.R`（`third_party/REPOS.md` 钉版），α=0.01，
bootstrap 固定种子 2026101605。调用前只检查 R 包，不自动安装；
原退出码 10/11 分别为未检出/检出，其他码或缺结果记失败。
完整日志与原上游 JSON 保留。没有 Rscript/依赖时状态为 unavailable，不能当作未检出。
钉版上游每类少于 100 条时状态为 insufficient_measurements（其错误文本实际门槛为 100）；
钉版上游会过滤 0 ns，因此遇到入选零值时不执行 RTLF，明确输出 blocked_upstream_zero_filter；CI 与原 CSV 保留零值。
RTLF 的二值结果不转换成伪连续 p 值。

`platform_dudect_replay` 仅在 x86_64 且上游 header 存在时构建：

```sh
cmake --build build/cmake --target platform_dudect_replay
scripts/run_stats_battery.sh --input raw.csv --format measure \
    --output-dir build/stats-with-replay --stats-bin build/cmake/platform_stats \
    --dudect-replay-bin build/cmake/platform_dudect_replay
```

它包含原版 `dudect.h`，调用原 `prepare_percentiles`、`update_statistics`、`report`，
不调用 `measure`、`dudect_main` 或 `rdtsc`；待计时回调若被误调即 abort。
每 10000 行一批，首批用于原上游分位阈值，后续批次按上游丢弃开头 10 行与末行，
完整原 CSV/归一化 CSV 始终保留。记录预热、端点和末尾不足一批的数量。
原上游 100 个裁剪检验及二阶检验仅作为其自有辅助流程，主 CI/RTLF 不裁剪。
两类 raw 累计都超过 10000 后才报告判决，任一已评估完整批次触发泄漏即保留该状态；
数据不足明确写 insufficient_measurements。它是既有 ns 数据的上游统计内核离线回放，
不能充当新的独立在线 dudect/rdtsc 采集。ARM 不构建它，不能把缺失写成通过。

`--dudect-log PATH` 只保全既有在线工具原日志，标 imported_unverified_provenance；
在线采集的 ELF、频率、CPU、种子、类对与预算须另行核验。两种 dudect 都不进入 Holm。
本脚本没有把普通 Welch t 冒称 dudect，也不会在分析阶段追加采数。

`--no-external` 仅供合成夹具自检，所有外部工具显式 skipped。
输出目录必须不存在；失败保留现场，复跑请给新目录。运行中的临时目录固定在输出树内。
configuration.txt/summary.json 记录输入格式、所选类别、各工具路径与运行机；
tools.sha256 记录统计 ELF、编排脚本及可用外部脚本/离线 ELF 摘要，input.sha256 记录原输入。
