# 固定源码重建与只读主表复算

普通重建只需C11/CMake依赖，不用旧构建目录或Python。默认31项源S02的原生采集与后续增加
只读复算的32项交付修订源分开；源角色及内部完整提交在交接身份表保存。匿名源以导出摘要
记录身份，不包含.git或内部bundle。

```sh
cmake --preset baseline
cmake --build --preset baseline --parallel 4
build/cmake/audit version
build/cmake/audit check
mkdir -p runs
build/cmake/audit replay "$PWD" "$PWD/runs/new-history"
build/cmake/audit performance-replay docs/evidence/native-final-20261007/performance runs/new-performance.report
build/cmake/audit analyze-pairs docs/evidence/controlled-comparison-20261007/confirmation-data/task-2.csv \
    docs/evidence/controlled-comparison-20261007/confirmation-data/task-2.plan runs/new-exact.report
```

先核对封存清单；audit replay会在分析前校验旧数据清单，随后40份报告逐字比对。
性能复算从18份逐次CSV/meta计算，不重新采集或要求旧二进制存在；新报告应与C原报告在
预定格式/精度一致。成对报告核对数据及计划SHA3-256，保留alpha、排列数、等值规则与区间前提。
跨工具链若数值精度有差异，保留新输出及差异，不自行增加容差或改写来源。

重新采集入口只提供普通参考负载：`audit collect RUN_ID SEED SAMPLES_PER_CATEGORY NEW_DIRECTORY`。
真实Linux需先核实实际设备、编译条件、CPU控制及源/产物；所有输出新建，保存退出码、
成本和原始值。短演示不能代替正式规约。旧人工机制数据只重分析，不启动新漏洞复现。

本轮source-role-replay的新检出作者普通/ASan+UBSan各32项通过，40份历史报告、普通性能主表及确认
成对报告逐字一致；匿名源新构建同样32项及复算通过。都是作者代理执行，非原作者签收仍缺。
实际独立执行模板在deliverables/demo，不能用代理换目录/机器的日志填成独立确认。
