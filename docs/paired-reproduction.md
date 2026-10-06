# 配对数据复算与独立执行说明

复算入口仅读封存数据，不重新采集，不依赖旧二进制目录，不覆盖报告。
本轮可封存的主示例是C生成的20对合成软件夹具，明示software_fixture；它验证数学和
完整性，不是原生实验，也不是受控改进证据。正式开发/确认目录目前不存在。

```sh
cmake -S . -B build/paired-replay -DBUILD_TESTING=OFF -DCMAKE_BUILD_TYPE=RelWithDebInfo
cmake --build build/paired-replay --target analyze_paired --parallel
sh tools/replay_paired.sh build/paired-replay/analyze_paired \
    docs/evidence/paired-software-20261006/synthetic-cohort /absolute/new-report.txt
```

先校验封存目录SHA-256，再由C分析器核对每份CSV/meta/cost的SHA3-256、配对、输入流身份、
调用与窗口计数、完成状态和预算，使用规约的固定种子与端点规则。
不能靠删记录、修改源值、加epsilon或放宽资格重现好结果。
运行级浮点值跨平台可能因long double和libm有差异；区间重复次数/种子及状态应一致，
本轮同平台新检出目录采用逐字比较。其他平台若超出已解释精度，保留差异，不自动加容差。

本轮作者将用独立临时检出、固定源码、新构建及封存数据复算，日志单列。
这是作者自复现，不能称为非原作者复现。交给其他成员时记录：

| 项目 | 执行者填写 |
|---|---|
| 执行者/是否参与实现 | 姓名、职责、是否原作者 |
| 固定源码与数据摘要 | 完整提交、封存目录清单摘要 |
| 真实平台与执行方式 | OS/CPU、宿主/虚拟化/翻译说明 |
| 实际命令与退出码 | 构建、检查、复算；重采另列 |
| 主指标及资格 | median/MAD/S、比值/区间、成本、中心和最终状态 |
| 与归档差异 | 数值、精度、工具链及原因，保留原始输出 |
| 重采状态 | 未执行或在指定目标设备上执行的实际编号 |

没有真实非原作者日志，R11仍保留缺口。交接源码可以使用Git bundle恢复固定历史；
不得把作者换目录测试或合成数学结果当作指定设备重采。
