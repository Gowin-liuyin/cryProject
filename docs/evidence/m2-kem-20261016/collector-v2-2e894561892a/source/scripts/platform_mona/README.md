# Mona 离线对照适配

本目录调用固定 `mona-timing-report@4c74fb7e629b4d057b2d5d4accdb120d920774b7`
的原始 `StatisticEvaluation.calibrationPhase()`，包含最优箱体搜索、最小子集搜索、
批次验证及原始 CSV 导出。适配器继承 `PlotPool` 以关闭绘图回调；不修改统计实现，
也不需要安装 Ant、gnuplot、TeX 或 Python 2。没有网络采集或密码算法计时。

要求 JDK 11 或更新版本与 CMake 3.21。构建仍由 CMake 定义：

```sh
cmake -S scripts/platform_mona -B build/platform-mona -DBUILD_TESTING=ON
cmake --build build/platform-mona --target platform_mona
ctest --test-dir build/platform-mona --output-on-failure
sh scripts/platform_mona/run.sh --input input.csv --output-dir NEW_RESULT \
    --class-dir build/platform-mona/platform-mona/classes
```

根构建可用 `include(cmake/PlatformMona.cmake)`，默认关闭，配置
`-DPLATFORM_ENABLE_MONA=ON` 后显式构建 `platform_mona`。主控负责此唯一根入口。
`PLATFORM_MONA_UPSTREAM_DIR` 可指定未修改的固定上游目录。

脚本输入为 S5 的 `V1,V2` + `X`/`Y`/整数时间长表，或两列带不同合法类别名的时间
宽表。值必须是非负整数纳秒，每类至少 100 个；类内顺序完整保留，上游自行排序
及构造连续子集。全部数据进入适配器，无过滤、抽样或截尾。输出目录必须不存在。

输出 `mona.json`、`mona.csv`、`mona.md`、原始 `box-results.csv`，以及输入、源码、
依赖、字节码摘要、版本和日志。状态分别为 `validated_box_separation` 或
`no_validated_box_separation`；异常用非零退出码，保留失败日志。

上游列名 `Confidence Interval` 实际是批次成功百分比，不是校准的 p 值、覆盖区间
或显著性控制。自适应扫描可产生假阳性，不加入 Holm 家族；阴性不证明恒时。
本接口是“调用上游统计类的离线适配”，不称完整上游 PDF 报告程序运行。

许可证记录见本轮 `docs/evidence/mona-wire-20261016/PLAN.md`。本体没有明确许可，
仓库不提交上游源码或 JAR；第三方声明保留原目录。没有修改或重新授权上游内容。
