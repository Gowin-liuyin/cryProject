# 作品使用入口

作品以C11的audit组合现有组件。不存在一个总的“绝对安全”状态；功能、记录、名义检测、
秘密归因、防护及复现分别判断。普通实时采集、历史重分析和无秘密合成夹具分别标注。

```sh
cmake --preset baseline
cmake --build --preset baseline --parallel 4
build/cmake/audit version
build/cmake/audit check
build/cmake/audit case
mkdir -p runs
build/cmake/audit collect demonstration 2026100703 20 runs/new-demonstration
```

新目录内有逐次CSV、meta、成本、退出日志、描述报告和index.html。短演示的60条记录只验证
入口，不代替正式样本。打开HTML查看数据及来源；缺文件、坏记录、meta partial、动态产物或
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

匿名源导出包含SOURCE_EXPORT.sha256，构建时核对清单；source_identity_kind明确为
verified_source_export。兼容source_commit字段是导出清单摘要前40位，并有说明字段，
不是Git提交。未封存的新源变化会使导出构建失败。正常仓库仍使用真实Git身份。
标准构建和复算不需要SciPy；它仅用于合同限定的外部强对照，版本/来源/命令另见
[固定比较](controlled-comparison-v1.md)及[结果](evidence/controlled-comparison-20261007/README.md)。

check实际运行全部相关功能/软件测试，排除measurement、analysis、analysis_groups三个
主动机制计时集成入口，并使用CTest的无测试报错选项。测试注册清单与真实执行日志分别保存。
部署、上传、签名、盖章、作品编号和真实非原作者执行不由入口自动代办。
