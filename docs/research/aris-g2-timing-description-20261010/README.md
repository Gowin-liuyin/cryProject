# G2原调用时长的有界离线描述增量

本增量复用现有`aris-frequency-window-analysis-20261010/analyze_windows.c`的严格schema 1
解析器及完整性、调度和窗口分析链，在其后新增`--timing-description INPUT.jsonl`入口。
无旗标的逐窗口CSV、摘要和`--selfcheck`入口仍保留原口径。这里的工作副本是新版本，
不能冒用旧分析源`dd67390f1e41d76624bf3a8854feacacfb8d1f85`及其C源摘要
`5c028abf419df5b5459c167469f44724faba12542b446799c5c5fc6b02d5a9f4`。
旧匿名包、封存源码、原始输入、既有结果和报告均不改写。

只有完整成功生产者记录、全部调用和时钟原值有效、主阶段边界可用时，才先完成全部
计算并输出。合法失败、缺失、空输入或算术溢出都返回1，stdout不输出描述CSV，stderr
为一行失败JSON并保留`timing_description=unknown`、`partial_or_unknown=true`。
parent-loss的空输出因此仍为未知，不能解释成零调用。文件以只读方式打开；不能删除
失败记录或长尾后换取通过。检测到输出写入或刷新错误时返回1；管道信号等异常终止也须按失败处理，使用者同时核对退出码、行数和摘要。

成功时stdout为一个表头和54行：预热全阶段、主全阶段各有全部调用及input0—7共9行；
主阶段按原调用顺序分为四段，每段也有9行。设主调用数为N，零基段号q为0—3，段界为
`floor(q*N/4)`至`floor((q+1)*N/4)`，右端不包含；这是调用数量分段，不能称等墙钟时间段。
输入编号始终取原全局调用索引模8，先分连续原序列再分输入，不能先按输入排序后切段。
`scope`为`whole_phase`或`main_quarter`；全阶段`quarter_index=all`，每组总行
`input_index=all`。表头固定为：

```text
scope,phase,quarter_index,input_index,count,sum_elapsed_ns,mean_ns,min_ns,p50_ns,p90_ns,p99_ns,max_ns,mad_ns
```

`sum_elapsed_ns`是checked uint64整数总和。均值由该总和除以count，保留12位小数仅供
显示，不表示12位物理精度；精确均值仍以两个整数字段的比值为准。分位点沿用
`src/timing_statistics.c`中`series_quantile`的最近秩规则：排序后取零基索引
`floor(p*(count-1)+0.5)`，本入口对p=0.50／0.90／0.99用精确整数索引计算，无插值。
偶数样本的p50取上中位数；MAD以这个p50为中心，计算全部绝对偏差后再用相同p50规则。
不进行长尾裁剪、开销扣除、GCD推断、p值、置信区间或独立／平稳假设认证。

stderr的一行成功JSON另保留全／预热／主调用计数，主起点、终点、墙钟和全部主调用
计时窗口之和。主墙钟端点沿用原分析：边界快照raw_after至末end快照raw_after；调用
窗口沿用原before至after。原主序列必须单调且窗口无重叠，并逐项checked记账：

```text
main_wall_ns = main_call_elapsed_sum_ns + main_outside_call_windows_ns
main_outside_call_windows_ns = main_head_outside_ns
                            + main_intercall_gap_sum_ns
                            + main_tail_outside_ns
```

首项为主起点至首调用before，尾项为末调用after至主终点；中间项为每对相邻主调用的
after至下一before之差，零长度间隙也计入`main_intercall_gap_count=N-1`。这些量是原记录
上的时间账，不识别调度、cache、读钟、管理或记录写入各自的开销与原因。

`record_position_counts`只列snapshot／checkpoint原记录数及原phase分配。对原phase为
main的记录，再按其call_records等于主首调用索引、严格在首尾之间、等于主末边界，
分配到`main_head`／`main_interior`／`main_tail`。这是调用边界上的位置计数，没有给
记录分配间隙时长，也不从邻近关系推出因果；warmup_to_main及同调用边界的预热checkpoint
保持warmup原phase，不转算main。计数不增加独立重复数。

唯一构建与测试来源仍为原模块CMake。冻结合同后从仓库根目录在新目录中执行：

```sh
cmake -S docs/research/aris-frequency-window-analysis-20261010 \
    -B build/g2-timing-description-normal
cmake --build build/g2-timing-description-normal --parallel 4
ctest --test-dir build/g2-timing-description-normal --output-on-failure
build/g2-timing-description-normal/analyze_windows \
    --timing-description /absolute/path/to/INPUT.jsonl
```

`frequency_timing_description_selfcheck`注册`--timing-selfcheck`，先走已有软件自检，再核对
手算奇／偶样本、单值、uint64最大值与总和溢出、最近秩和MAD、非整除四段界、54行
逐输入分配、主墙钟首／尾／相邻间隙守恒，以及调用／时钟失败、主端点越界和窗口重叠
的拒绝。新增8次预热／32次主调用的fixture只核对内部描述运算，不作为完整schema
fixture；完整解析／完整性／调度／原窗口链由已有128调用自检另行覆盖。fixture只在C
内存中构造，不能作硬件输入；测试注册不等于测试已经通过。
动态检查须另建目录并使用`-DFREQUENCY_ANALYSIS_SANITIZERS=ON`。

软件资格已完成：普通与ASan/UBSan各2/2、旧normal/parent-loss四输出逐字保持，以及只读stdout失败检查。
动态首轮在测试体前因macOS不支持的detect_leaks=1失败，原件保留；同一动态产物仅改detect_leaks=0后通过，不宣称LSan覆盖。
完整[准备证据](../../evidence/g2-timing-description-20261010/preparation/README.md)分别保存源、合同、产物及失败/修复日志。
真实新描述入口仍未执行，随后须另绑定提交源、普通二进制和实际输出。新增描述不会证明短调用精度、恒频、总体误报率
或检出率；R02/R04不因此签收。若在云端执行，源码、输入、构建、缓存、临时文件和输出的
真实路径全部只能位于`/home/nss-marker/yhr/Cry`或其子目录，不能用符号链接越出。
