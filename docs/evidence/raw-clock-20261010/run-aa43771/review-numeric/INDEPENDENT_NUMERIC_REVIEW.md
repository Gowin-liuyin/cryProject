# RAW空窗口独立全量数值复核

2026-10-10。结论：**全部核对值一致，无数值不一致。** 独立代理使用Python标准库整数、Fraction、sorted和median_high，直接完整读取三份Linux原始CSV及全部C输出；没有导入或调用主程序函数，没有重新执行C分析、collector、远端管理器或SSH。外部算术参照在本机离线执行一次，实际退出0，角色是一次性核对材料，不是产品统计入口。没有新增真实采样或密码调用，也没有改写原件。

## 核对范围与独立性

- 每进程101000条、每条15字段：共303000条、4545000字段，对应已有606000次采样读钟。连续index、固定phase、两个attempt/has_timespec、立即errno、秒/纳秒余数与uint64转换、差分、pair内及跨pair完整非降序逐条核对；有效零值不删除。warmup/main边界也在原序核对范围内。
- 三份六行C结果的标签与18行全部180个数值字段逐项一致。外部实现用任意精度整数计算总和并另检查uint64范围，以标准库排序替代C原地堆排序；用Fraction位置加1/2后下取整得到预定P50/P90/P99，不调用C百分位函数。每行还核对0%与100%端点，上中位数由median_high独立计算，MAD由全部绝对偏差的median_high得到。
- 两阶段的pair内、pair间、组合增量分别核对；阶段边界间隔单列，不能插入阶段内序列。三份C summary的全部22个字段及真假类型均一致，包括保留的精度、iid、metadata验收和R02/R04未签收字段。
- 三份collector元数据各为完整单行：不同PID、实际Linux/x86_64机器字段、UID1000、原mask0—31、前后CPU2/affinity=[2]、tsc、RAW声明分辨率1ns、各101000/1000/100000计数、完成状态及无错误均核对。普通collector和普通C分析的六条对应命令回执、原件摘要与case完成/接受事实相互绑定。未把C分析器自己的metadata检查false字段改成true；这是外部复核另行验证。
- 本次核对26份数值相关原件的SHA256，25份有对应manifest条目，manifest自身只绑定其文件摘要；原件复核前后摘要保持一致。原tar实际大小及摘要另行计算绑定。完整归档成员、生命周期与路径审查由独立归档审查记录负责，本页不冒充已重新检查全部496成员或当前远端存活状态。

## 实际描述值

三个主阶段均100000个pair，空窗口P50=20ns、P90=20ns、P99=21ns；pair内最小及经验最小正增量均10ns，MAD均0，零增量均0。主pair总和分别1752142、1750080、1748048ns，按总和/100000的精确算术均值分别17.52142、17.50080、17.48048ns；数字表示位数不代表物理有效精度。全部最大值分别2004、1603、501ns，未删除长尾。

三进程前后接口声明的resolution=1ns、经验最小正增量10ns和上述空窗分布是三个不同对象。MAD=0也不表示没有波动：这些序列同时保留更大增量及长尾。以下为完整18行复核结果，单位ns；count/zero为数量。

| 进程 | 阶段 | series | count | zero | sum | min | min positive | P50 | P90 | P99 | max | MAD |
|---|---|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| P1 | warmup | within_pair_ns | 1000 | 0 | 17621 | 10 | 10 | 20 | 20 | 21 | 50 | 0 |
| P1 | warmup | between_pairs_ns | 999 | 0 | 23145 | 20 | 20 | 20 | 30 | 31 | 131 | 0 |
| P1 | warmup | combined_ordered_read_increment_ns | 1999 | 0 | 40766 | 10 | 10 | 20 | 30 | 31 | 131 | 0 |
| P1 | main | within_pair_ns | 100000 | 0 | 1752142 | 10 | 10 | 20 | 20 | 21 | 2004 | 0 |
| P1 | main | between_pairs_ns | 99999 | 0 | 2299670 | 20 | 20 | 20 | 30 | 31 | 1623 | 0 |
| P1 | main | combined_ordered_read_increment_ns | 199999 | 0 | 4051812 | 10 | 10 | 20 | 30 | 30 | 2004 | 0 |
| P2 | warmup | within_pair_ns | 1000 | 0 | 17523 | 10 | 10 | 20 | 20 | 21 | 50 | 0 |
| P2 | warmup | between_pairs_ns | 999 | 0 | 23194 | 20 | 20 | 20 | 30 | 31 | 341 | 0 |
| P2 | warmup | combined_ordered_read_increment_ns | 1999 | 0 | 40717 | 10 | 10 | 20 | 30 | 30 | 341 | 0 |
| P2 | main | within_pair_ns | 100000 | 0 | 1750080 | 10 | 10 | 20 | 20 | 21 | 1603 | 0 |
| P2 | main | between_pairs_ns | 99999 | 0 | 2296451 | 20 | 20 | 20 | 30 | 31 | 2185 | 0 |
| P2 | main | combined_ordered_read_increment_ns | 199999 | 0 | 4046531 | 10 | 10 | 20 | 30 | 30 | 2185 | 0 |
| P3 | warmup | within_pair_ns | 1000 | 0 | 17672 | 10 | 10 | 20 | 20 | 21 | 50 | 0 |
| P3 | warmup | between_pairs_ns | 999 | 0 | 22723 | 20 | 20 | 20 | 30 | 31 | 130 | 0 |
| P3 | warmup | combined_ordered_read_increment_ns | 1999 | 0 | 40395 | 10 | 10 | 20 | 30 | 30 | 130 | 0 |
| P3 | main | within_pair_ns | 100000 | 0 | 1748048 | 10 | 10 | 20 | 20 | 21 | 501 | 0 |
| P3 | main | between_pairs_ns | 99999 | 0 | 2305287 | 20 | 20 | 20 | 30 | 31 | 2415 | 0 |
| P3 | main | combined_ordered_read_increment_ns | 199999 | 0 | 4053335 | 10 | 10 | 20 | 30 | 30 | 2415 | 0 |

组合序列复用pair内与pair间的同一批读数，六行不构成六次实验或新增独立样本。所有18行零计数均0，是本次所见原值的事实，不推广为时钟不会返回相等读数。

## 整数时间账

- P1主阶段：`1752142 + 2299670 = 4051812` ns；全采样原序：`40766 + 20 + 4051812 = 4092598` ns。
- P2主阶段：`1750080 + 2296451 = 4046531` ns；全采样原序：`40717 + 20 + 4046531 = 4087268` ns。
- P3主阶段：`1748048 + 2305287 = 4053335` ns；全采样原序：`40395 + 20 + 4053335 = 4093750` ns。

每个阶段的组合增量和也等于对应阶段墙钟。三个阶段边界均20ns，分别只记一次。全采样原序墙钟包含阶段内pair间间隙，不是仅两次读钟函数的总成本，也不是整个进程或编译/输出/分析的管理墙钟。每进程是1000次预热pair和100000次主pair，并非G2的一秒预热/四秒负载。

## 来源与字节绑定

原tar：`remote-originals.tar.gz`，4454198字节，SHA256 `e6dfd03f03e1e2e4e28a4eb0c251a8f7d684745980727843263e4ad8ff1870e6`。部署源码标识为 `aa437714e023e2aef8301a925c33949647790517`，冻结计划 `7499b60b7a32b0a5e82e2acbc07144b6b0062b5d1f344aeb4af9ff4208e6927a`。

原collector C摘要 `ed538f4322fba985aea9cfa78e0b2109f79caed49064e68eaa3884b4fa10f0dd`；原analyzer C摘要 `c67d1dbd89034a75600d3d13a28aa5c7fb4a163b5649fa910c7eea624c7544e0`；CMake摘要 `28d264a993558d1aad66dd6ffd2671c0a3ea18054fda6d6ec91b06a7c312816e`；runner摘要 `bf34389f2cb39348ac1baa2a3c2b159ad69cb473414ff3b6b7b97850d0431d04`。四份实际普通/动态ELF摘要已与run-state和所见文件逐一核对，完整映射、每行位置索引、精确均值Fraction及所有输入摘要见本目录verification.json。

| 原件 | 字节 | SHA256 |
|---|---:|---|
| `output/P1.csv` | 9688106 | `a157354aa86196cea2bd24e03f66aca8e5b9511a7d9b92bfc62f3b9366fa58ad` |
| `output/P1.json` | 1232 | `5c410cc0ad671d123722be383494ad9cf3447e7348e5453c4aa7c238c4a23738` |
| `output/P1-analysis.csv` | 481 | `ddc8aa6dcc0b11e57b29103eb325a5e233303718bf3d08dd3fb3273fad835a9d` |
| `output/P1-summary.json` | 606 | `5150686b09bb91e3a1893a44939adfcbcf6046ea8215d60e241acadeec138adf` |
| `output/P2.csv` | 9688108 | `48937d520c06009da5ca5d6be79b8c33f0056107a91f1dbbd5fe73bab31a79c8` |
| `output/P2.json` | 1232 | `82ff2d47cc1bbcb7273d3f19272bf6e368089ec2c8ffc1e35f095078d3f524a1` |
| `output/P2-analysis.csv` | 481 | `72144a55a14f722b904892b687276bd43f54fc6497708b498fb9e6bba4faf0eb` |
| `output/P2-summary.json` | 606 | `ba93f53c9f90f63e1c9cf79316ff357a217ce4fb1369f76f54594677e5cec9a1` |
| `output/P3.csv` | 9688102 | `d43ca663205c3353c37413e1c9d61b4fef5def5acc6307992fbd5758583d5a0e` |
| `output/P3.json` | 1232 | `e4f7bbec42ff6cc27aad732d424a51515b21e13e449ea6c9a6f5c2e2aed6edb4` |
| `output/P3-analysis.csv` | 480 | `a0884ba24f5b482368a8d97a5753a0251c319800a321efccfac31918ced73926` |
| `output/P3-summary.json` | 606 | `f22cd27b0b3bde671c838e49a57c14c3132a3db8d639ea8616245d7524a01a22` |

一次性外部算术参照为本目录independent_numeric_oracle.py，其自身摘要与执行平台写入verification.json。源文件与核对输出应一并保存。没有将本参照加入CMake、CLI、产品资格或正式统计入口。

## 结果到主张的边界

本次支持三份原始读钟记录、18行C结果和整数时间账在冻结算法口径下可独立复算，及元数据原件与实际普通产物/回执一致。三次近时顺序进程只作有限描述，不能从接近的中位数推出跨会话稳定、iid、旧G2产物实路径相同或完整解封装的进程重复性。

不从空窗扣减G2调用耗时，不把经验最小正值称硬件刻度，不给出绝对物理误差上界、恒频、vDSO/系统调用动态路径、安全容许界或总体错误率结论。`clock_precision_certified`、`iid_claimed`、R02/R04签收保持false。独立全量数值一致不替代这些科学前提。
