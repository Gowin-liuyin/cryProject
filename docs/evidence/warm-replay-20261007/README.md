# 预导入成本边界复核 C03

合同42206a8b9c69a3c4488ad81dfac5c35cbaa1ff43先冻结；实现及正式运行源码
56373cbe74fea98fdaca2a3ff15bdff1a1b39aca。旧合同、确认集合、历史阈值及报告未改。
只执行一次正式补充；每任务两方法三次，48次全部完成。C计时与整数计数资格核对。

| 指标 | C观察器结果 |
|---|---:|
| SciPy就绪后24窗口合计 | 49.704188 s |
| C完整24进程合计 | 0.079016 s |
| 基线24次导入就绪合计，另列 | 6.559904 s |
| 比较观察窗口，含就绪及管理 | 56.349633 s |
| 24对应窗口比值中位数 | 0.001562070 |
| 比值范围 | 0.001274786–0.001925128 |
| 每任务C最大小于SciPy最小 | 8/8 |
| 精确尾计数/2^20分母逐项一致 | 48次 |

全部八份既有合成文件及plan保持原字节；inputs-before/after逐字一致。
正式环境Apple M5/ARM64、10逻辑CPU、macOS26.6.2；Apple Clang21；Python3.12.14、
SciPy1.16.3/NumPy2.3.5。负载与机器身份在environment.log，不宣称CPU隔离或总体速度区间。
不是新的独立确认数据，也不是原生Linux密码性能测量。

基线先导入全部模块、核验版本，再SIGSTOP。C通过waitpid核对该停止原因，读钟后SIGCONT；
此前没有任务文件读取、摘要、解析或统计。基线窗口包含此后的调度、读取、解析、全部交换、
报告写入及退出。候选仍是原完整C CLI窗口，含自身fork/exec成本，故不能称纯内核比较。
启动准备独立保留，比较观察窗口未将其隐藏。该窗口从账本创建后到总报告输出前；
初始建目录、最终总报告写入及关闭没有另采端到端墙钟，不将此字段冒称整个观察器进程。
每次新进程，不复用预计算或缓存的尾计数。
完整进程旧试验和本次窗口不能相减来估算导入成本：它们是不同时间执行的观察。

符合冻结有限效率条件，继续支持限定精确复算流程的工程增量。既有随机化与Gray更新不是
本作品新理论；不升级为密码加速、误报/检出胜出、秘密归因、防护有效或全部参赛要求达标。
此前接口开发及材料制作完整研发成本未采集，本表只闭合所规定的比较执行成本。

Mac普通和ASan/UBSan各33项通过，format-check通过。固定代码导出在原生Ubuntu/KVM
GCC普通及Clang18动态各33项通过；这些是功能检查，不合并入ARM的正式计时。
首次原生导出漏了两组旧复算资源，32项通过、analysis_round1_replay失败，原日志保留。
补入同一源码提交的四个原始CSV/report后更新导出身份、重建，33项通过；未改数据或检查。
原生执行仍由作者代理完成，不替代真实非原作者复现。

复核需要冻结版本的外部SciPy环境；C作品本身重建精确判定不依赖Python。

```sh
cmake --preset baseline
cmake --build --preset baseline --parallel 4
build/cmake/compare_replay "$PWD/build/cmake/controlled_stats" \
  /absolute/path/to/python tools/scipy_exact_baseline.py \
  docs/evidence/controlled-comparison-20261007/confirmation-data \
  runs/new-preimported-comparison preimported
```

Python和脚本路径由观察器execv调用，建议均传绝对路径；必要时用PYTHONPATH指向已经
准备的固定版本依赖。新输出目录须不存在。失败账本不覆盖；不得为取得更快数字反复采集。
