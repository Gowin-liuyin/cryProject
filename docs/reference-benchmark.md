# 参考版普通工作负载与测量自检

`reference/benchmark` 由同一 `src/measure.c` 编译，只链接未修改的参考库。
`BASELINE_ORDINARY_WORKLOAD` 仅选择三类普通测试输入并增加读钟诊断；旧四版 `measure`
继续使用五类、原命令和原 CSV/meta 契约。本轮不采集其他变体或固定消息机制类。

```sh
cmake -S . -B build/reference-performance -DCMAKE_BUILD_TYPE=RelWithDebInfo \
    -DBUILD_TESTING=ON -DBASELINE_SANITIZERS=OFF
cmake --build build/reference-performance --target check-reference reference_benchmark \
    inspect_timing test_reference_benchmark test_timing_diagnostics --parallel
ctest --test-dir build/reference-performance --output-on-failure \
    -R '^(reference_benchmark|timing_diagnostics)$'
reference_run_directory=$(mktemp -d runs/reference-ordinary.XXXXXX)
build/reference-performance/reference/benchmark ordinary-example 20261006 1000 \
    "$reference_run_directory/raw.csv" "$reference_run_directory/run.meta"
build/reference-performance/inspect_timing "$reference_run_directory/raw.csv" \
    "$reference_run_directory/summary.txt"
```

先创建 `runs/`，并记录每条命令的返回码。`check-reference` 仍仅执行功能 5 项；
新增性能接口测试另行选择，动态检查构建只作正确性验证。`BUILD_TESTING=OFF` 时可构建
`reference_benchmark` 和 `inspect_timing`，不提供测试目标。

## 采集前固定的本轮本地计划

运行顺序为 `ordinary-local-20261006`、`ordinary-local-20261007`、`ordinary-local-20261008`，
公开种子分别为 20261006、20261007、20261008；每次三类各 1000 条、合计 3000 条。
混合比例固定 1:1:1，同一测试密钥下按类别内索引生成输入，再用原 SHAKE/Fisher–Yates
乱序。每次 100 次预热不入 CSV；不根据结果补采、删尾或改变规则。
三次顺序运行是描述性性能记录，不是三个独立主机、独立确认数据或新的显著性实验。
同索引 valid 与 bit-flipped 来源相同并有配对关系，不宣称随机总体中的独立抽样。

## 自检、窗口与记录

`CLOCK_MONOTONIC` 以 ns 表示；先检查 10001 次读取形成的 10000 个增量无倒退且有进展，
再记录 1000 次带相同读钟和编译屏障的空窗口。每个增量和空窗口均按原顺序写入 meta。
零增量保留，不能把它解释为零开销。`clock_getres`、实际最小正增量和空窗口均值分别报告；
最小正增量是这次有限观察值，不是对真实时钟粒度的证明。
正式窗口覆盖完整 `mlkem_decapsulate`，生成、分配、输出消费、状态检查和 I/O 在窗口外。
不扣空窗口均值，不插值。正式优化产物须保存反汇编，核对计时窗口仍调用完整解封装路径。

CSV 仍为六列逐次原始值，只有三类；meta 增加 `measurement_format=reference_ordinary_v1`、
负载比例、自检及 `run_status`。以**退出码 0、完整 CSV、meta complete 和摘要匹配共同**认定
完整运行：meta 的 fclose 本身可能失败，单独看 complete 不够。非零退出的部分文件必须
保留并排除；外部 `step-exits` 是失败识别的依据。不公开内部密文验证结果。

`inspect_timing` 复用严格 CSV 加载器、SHA3-256 和摘要函数，保留加载数组的原始顺序，
只排序副本；四段顺序均值用于查看变化，不给显著性告警。
P50/P90/P99 明确使用 `floor(p*(n-1)+0.5)` 的零基下标，不插值。
并列比例是随机选取两个不同记录位置、耗时相同的成对比例；distinct 是耗时取值数，
不是不同密文数。`observed_duration_grid_ns` 是耗时整数的最大公约数，不是读钟精度。
普通 CSV 的有效解封装耗时必须非零；空窗口零值独立留在 meta，不传旧 CSV 加载器。

记录来源见 [本地证据](evidence/reference-benchmark-20261006/README.md)。亲和性、频率和后台
负载若未配置就如实标注。均值和分位点均为运行内描述值，缺乏受控重复主机和独立确认，
不把输入类别差异叫作秘密泄露，也不将本机结果外推为真实 x86_64 Linux 性能。
