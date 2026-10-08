# 作品使用入口

作品以C11的audit组合现有组件。不存在一个总的“绝对安全”状态；功能、记录、名义检测、
秘密归因、防护及复现分别判断。普通实时采集、历史重分析和无秘密合成夹具分别标注。

```sh
cmake --preset baseline
cmake --build --preset baseline --parallel 4
build/cmake/audit help
build/cmake/audit version
build/cmake/audit check
build/cmake/audit case
mkdir -p runs
build/cmake/audit collect demonstration 2026100703 20 runs/new-demonstration
```

新目录内有逐次CSV、meta、成本、退出日志、描述报告和index.html。短演示的60条记录只验证
入口，不代替正式样本。打开HTML查看数据及来源；缺CSV/meta/cost、坏记录、partial、动态产物或
输出已存在均拒绝签收。HTML通过临时文件、完成写入及独占发布，不用部分页面显示成功。
原始I/O失败保留部分文件；新路径不意味着可以绕过正式合同的旧成本。

指定数据复算：

```sh
build/cmake/audit inspect 数据.csv 新描述.report
build/cmake/audit analyze 历史五类.csv 新名义报告.report
build/cmake/audit analyze-pairs 成对.csv 计划.plan 新报告.report
build/cmake/audit replay "$PWD" "$PWD/runs/new-archived-replay"
```

replay只读20份旧五种子四版本CSV，重新生成40份报告并逐字核对，不重新采集。
跨平台若出现数值精度差异会失败并保留输出，不自行增加容差。原两套名义分析器、
alpha、旧分位数名称兼容字段及其审计限制保持有效；新成对工具不覆盖旧随机化合同。

普通性能入口：

```sh
build/cmake/audit performance runs/new-safe-performance
build/cmake/audit performance-replay 已封存性能目录 新性能.report
```

只运行reference/hardened/deployable普通三类，6个固定运行块、全部6种方法排列、
每个运行3000正式+100预热，共55800次完整解封装，上限180秒。
同一运行块三种实现必须共享输入种子及有序公开输入摘要，源身份一致，各meta的实际
可执行文件SHA3-256逐个核验。报告保留逐次原始值、每运行均值及P50/P90/P99、
相对参考的差值与允许负数的开销、运行级99%成对bootstrap描述区间。
6个云运行块的iid条件未证明，该区间只作探索；没有将其提升为安全结论。
子程序阶段成本及父进程完整启动/读写/退出窗口均保存；共同构建及文档制作不在该进程指标中。
它不执行新的人工秘密机制时序，不代替缺陷前后的受控复测。Linux正式性能需固定源码和新目录，
按原生说明外部taskset控制；不要把本地ARM结果与Linux混合比较。
performance-replay仅读18套逐次CSV、meta及阶段cost，核对运行身份、CLOCK_MONOTONIC/ns、
ordinary格式、正式/预热调用及结果消费数，并要求阶段时间有序、总墙钟等于首尾差值、
采集窗口足以容纳逐次时间总和；成本缺失或矛盾拒绝完整报告。再核对每块输入、种子、版本和一致产物
身份，从原始记录重建全部分位数、运行差值及同规则区间。先核对封存SHA清单，再使用此入口；
报告路径新建，失败保留部分报告且不写complete。它不要求旧二进制目录存在，也不重新采集。

匿名源导出包含SOURCE_EXPORT.sha256，构建时核对清单；source_identity_kind明确为
verified_source_export。兼容source_commit字段是导出清单摘要前40位，并有说明字段，
不是Git提交。未封存的新源变化会使导出构建失败。正常仓库仍使用真实Git身份。
标准构建和复算不需要SciPy；它仅用于合同限定的外部强对照，版本/来源/命令另见
[固定比较](controlled-comparison-v1.md)及[结果](evidence/controlled-comparison-20261007/README.md)。

默认A113_ARCHIVED_CASE_ONLY保持人工机制为归档案例，旧五类measure及三个主动机制集成
测试不进入默认构建/注册；算法、CLI功能、旧分析器和归档规则均保持有效。已有旧构建目录
可能保留先前可执行文件，正式验收须使用新构建目录。check仍显式排除这三个旧测试名，并使用
CTest的无测试报错选项。测试注册清单与真实执行日志分别保存。
部署、上传、签名、盖章、作品编号和真实非原作者执行不由入口自动代办。

有限模型校准另有入口：`build/cmake/audit calibrate 新目录`，固定12对、两种幅度和五种效应，
完整枚举40964份无秘密模型数据，保存每份差值及独立卷积核对。它不采集密码时间，
不估计真实密码总体的误报/检出率，不重新解释旧档案。外部44份SciPy审计及预算规则见
[校准合同](finite-calibration-v1.md)；共同符号模型应由成对CLI判证据不足。

真实参考时间的后赋标签控制使用
`build/cmake/audit reference-label-control 封存普通性能目录 新目录`。它完整读取六份参考
CSV/meta/cost并验证资格，再取每块原序0..23作独立后赋标签的有限控制；保存24576份
差值、双实现尾计数及144个原时间。不重新采集，不修改原时间，不比较原密文类别。
此项条件错误控制不替代真实密码总体或防护复测，见[合同](reference-label-control-v1.md)。

本轮结论使用稳定编号，入口为[离线页面](../deliverables/demo/index.html)及
[逐项证据索引](../deliverables/demo/evidence-index.md)。每条可直接打开原数据、源/产物、环境、
日志/退出、分析和缺口；公开核查与固定配置适用性单列。新N01普通性能和旧E02图源保持
各自身份；A02复算为作者代理。A03是2026-10-08所有者授权的封存v3重跑，计入R11；截图与审批签署仍见I01。帮助命令help/--help/-h退出0，
未知命令退出2并显示格式。新输出须不存在；短现场运行与读取封存结果分别标注。
