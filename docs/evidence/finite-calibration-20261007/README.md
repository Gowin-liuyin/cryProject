# 无秘密有限模型校准

合同fdf3bb1在新数据生成前固定；C产物及数据源62dbe4cfb4a8c0d8480c7271e9214f74697f8f86。
外部SciPy审计源4a82b5c（追加依赖导入前的60秒预算边界，不改统计量、样本或参数）。
原生Ubuntu/x86_64/KVM、4vCPU、GCC13.3执行C校准，全部40964份数据及双实现计数在model/raw.csv。
单位是合成ns，不是密码采集时间。核心校准任务430655423ns，120秒预算内；最终摘要及状态
写入在该窗口外。ML-KEM解封装调用为0，不占用或重开旧批次合同。普通与动态测试分时执行。

| 预定效应delta（合成ns） | equal原始拒绝/4096 | graded原始拒绝/4096 |
|---|---:|---:|
| 0 | 26 | 38 |
| 1 | 794 | 48 |
| 2 | 4096 | 91 |
| 4 | 4096 | 353 |
| 12 | 4096 | 4096 |

delta=0的有限模型误拒绝概率分别0.006347656250和0.009277343750，都不超过固定alpha=0.01。
equal的26/4096与独立二项式手算一致。delta>0表示各固定模型的检出概率，差异明显；
graded在delta=4仍只有353/4096，保留这个低检出结果，不用equal结果替代。
equal/delta=1的一份全零数据未删除，计入4096分母并单列。没有Monte Carlo误差或总体置信区间。

两个共同符号模型仅各有2个等概率结果，零效应却在盲用独立4096交换规则时各2/2拒绝。
实际controlled_stats对这4份明示依赖的CSV/plan均返回evidence_insufficient；这属于拒绝签收，
不能称已把误报降到零。有限模型证明该依赖结构不能沿用独立交换规则，不证明真实平台的
依赖结构已识别或已消除。

全部40964份C候选/整数分布卷积尾计数一致，原始记录含两份计数；卷积不使用Gray更新。
按合同选定的44份SciPy1.16.3/NumPy2.3.5审计全部一致，见scipy-audit.report。审计读取同一
原生原始CSV，在本地Apple M5运行；开始/结束UTC为04:36:20/04:36:21，脚本60秒限额覆盖
依赖导入及全部审计，不把这一秒级记录当精确进程成本或跨平台速度比较。

软件检查：Mac普通/ASan+UBSan各33项通过（功能源a3e691b加随后元数据字段命名修订），
原生固定62dbe4c的GCC普通及Clang18动态各33项通过；Oracle手算及工作流新目录拒绝覆盖。
之前32项固定快照仍按其原版本解释。实际源码、编译条件、二进制摘要与环境分别保存。

复算与验证：

```sh
cmake --preset baseline
cmake --build --preset baseline --parallel 4
build/cmake/audit calibrate runs/new-finite-calibration
build/cmake/controlled_stats analyze runs/new-finite-calibration/common_equal-0.csv runs/new-finite-calibration/common_equal-0.plan runs/new-finite-calibration/common_equal-0.report
```

新结果的raw.csv应与本档案原字节相同，摘要及任务耗时不要求相同；源码身份按新构建如实记录。
外部44份审计命令为固定依赖环境执行tools/check_calibration_scipy.py 原始raw.csv 新审计.report。
不混用一般成对CSV与完整人口记录格式。原两套旧分析器、阈值、历史数据及效率确认集合未改。

此项补齐两种有限模型的精确错误/检出及依赖拒绝核验，仍缺真实密码总体校准、序列依赖
识别、秘密归因、受控防护前后及真实非原作者执行。没有超越dudect/RTLF检测能力的证据，
没有新的密码安全增益；R04/R12整体状态不升级，整个Goal未完成。
