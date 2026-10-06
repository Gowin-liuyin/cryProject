# 历史数据离线审计：2026-10-06

对应 [口径审计](../../statistical-audit.md)。43份历史CSV、826300条记录均通过复用的C加载器，
记录数与meta一致；所有已有报告中的CSV SHA3-256与原件一致。
`dataset-inventory.json` 逐份列来源、HEAD、种子、时钟、时间戳、顺序四段和全体摘要；
`reports/` 是 `inspect_timing` 的新描述报告，每份绑定原CSV SHA3-256。
输入原件、归档报告和冻结设计未改写，未增加采样或显著性告警。

`build-directories.json` 区分普通和动态检查新目录，源码仍为起始HEAD
`a07bbc197d7bcee75be6d21942db88b6844b9ea4` 加当时未提交内容。
`tested-source.sha256` 固定实际被测文件，功能新增文件随本轮交付。
最终 `*-ctest-final.log` 各为2/2（`timing_diagnostics`、`analysis_round1_replay`）；
格式及四个统计相关归档目录完整摘要通过，见对应日志。
最初未配置目标尝试、macOS声明和一次格式检查失败全部保留；最终日志单独命名，
没有覆盖失败记录。其余CMake测试未在本模块执行。

核验：

```sh
shasum -a 256 -c docs/evidence/statistical-audit-20261006/SHA256SUMS
shasum -a 256 -c docs/evidence/statistical-audit-20261006/tested-source.sha256
```

单个报告：`build/<本目录release目录>/inspect_timing 原CSV 新报告路径`。
原始顺序数组不排序，只排序副本。报告不读取或改写meta；运行完整性和实验单位须按
审计表并读元数据与日志，不能仅靠严格CSV解析判断所有历史尝试是否完整保留。
