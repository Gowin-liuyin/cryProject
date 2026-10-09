# G2 执行登记

2026-10-10；执行合同为 [EXPERIMENT_PLAN.md](EXPERIMENT_PLAN.md)。状态依据原件登记，
没有把实现、自检、实机执行及结论签收合并。

| 项目 | 状态 | 来源或下一门槛 |
|---|---|---|
| C11 普通候选及转储限制 | 已提交 | `c0e5990bd4d764fbb08ff6857a2cf6cf21c9b8a2` |
| 本机普通／ASan软件检查 | 各2/2通过 | macOS/ARM，不代替 Linux 分支 |
| 真实 Linux 普通／ASan软件检查 | 各3/3通过 | [linux-c0e5990](../../evidence/frequency-window-20261010/linux-c0e5990/README.md) |
| 固定正式 ELF | 已取得 | Cry/window-source-c0e5990/build-normal/frequency_workload；SHA-256 `023f56460a8dc4971e8132a22c5734ca0844314d3d71b8bc3b129a424e9ee69b` |
| 新管理生命周期与存储降级 | 实现及复核中 | 不能由 G1 的 true 预演替代 |
| 管理源提交与摘要 | 待冻结 | 首次实际资源写入前登记 |
| normal 实际路径 | 未运行 | 最多一次，不以频率结果追加 |
| parent-loss 实际路径 | 未运行 | 最多一次，需 normal 终止及恢复先核实 |
| C11 原始窗口分析 | 候选及软件检查中 | 规则在真实数据前冻结 |
| ARIS 结果到主张 | 尚无 G2 结果 | 外部 Codex MCP 不可用，须标注待该复核 |
| R02、R04 总体 | 部分签收不变 | 窗口工程诊断不能代替科学及统计前提 |
