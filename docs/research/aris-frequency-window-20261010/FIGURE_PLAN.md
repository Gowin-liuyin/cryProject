# G2 结果图表计划

依据已冻结合同及实际 `run-0ba4cd7` 的 C 输出绘图，不增加、平滑或筛选测量。

| 图 | 内容 | 数据 | 范围 |
|---|---|---|---|
| G2-1 | 上：全部200个CPU2窗口的读取对齐区间与事前±1%工程带；首straddle为空心标记。下：纯主阶段几何覆盖与剩余缺口的合计比例 | analysis/normal-windows.csv、normal-summary.json | 一个完成进程；图不表达独立重复、CI、点态恒频或物理精度 |

采用ARIS paper-figure流程：矢量PDF、300dpi PNG、无图内标题、轴和单位明确、保留复现脚本，
生成后目视核对。外部Codex MCP不可用，标为待该审查；本地独立代理可复核图与原C输出。
CPU18仍保存在原CSV中，预先定义为context_only；不画成第二独立测量样本。
