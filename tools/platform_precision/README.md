# 计时基准与频率自校准（platform_precision）

这个目录回答一个此前只登记为「未认证」的问题：**物理精度与逐调用恒频**。

工具只做四件事，全部可复算：

| 测项 | 做法 | 产物 |
|---|---|---|
| TSC 速率 | 连续 N 秒读 TSC 与 `CLOCK_MONOTONIC`，算出每秒计数，与内核 `scaling_cur_freq` 对照 | 摘要里的 `tsc_rate_khz` 与 `tsc_rate_over_kernel_ratio` |
| 短区间隐含频率 | 反复取**短区间**（默认 1 ms）的 TSC 增量与墙钟增量，算出每个短区间隐含的频率，给出分布与跨度 | 摘要里的 `short_interval_implied_frequency_*` |
| rdtsc 分辨率 | 连续两次 `rdtsc` 的最小间隔分布 | 摘要里的 `rdtsc_resolution_counts` |
| 内核瞬时频率 | 测量期间读 `scaling_cur_freq` | 摘要里的 `kernel_scaling_cur_freq_khz` |

## 口径与边界

- **只读**：不写任何 cpufreq 节点，不改频率，不加 sleep，不做固定拍数空转；
  区间长度用墙钟实测控制。
- 原始逐区间值全部落盘（`intervals.csv`），不删长尾；摘要只给分布统计。
- 时钟源是 `CLOCK_MONOTONIC`，TSC 源是 `RDTSC`（编译器插入序列化）。
- 平台要求 x86（需要 `rdtsc`）。非 x86 上工具**明确拒绝并返回非零**，
  不写出任何产物；该拒绝行为本身有回归项覆盖。
- 短区间隐含频率是**工程观测**，不是物理证明：它给出的是「在本次测量里，
  短区间两端读数隐含的频率有多分散」，不构成「逐调用物理恒频」的认证。

## 构建与自检

```sh
cmake -S tools/platform_precision -B build/platform-precision -DCMAKE_BUILD_TYPE=RelWithDebInfo
cmake --build build/platform-precision
ctest --test-dir build/platform-precision --output-on-failure
```

## 运行

```sh
./build/platform-precision/tsc_calibration 60 1000000 2000 intervals.csv summary.txt
```

参数依次是：测量秒数、短区间目标纳秒数、样本数、逐区间 CSV 路径、摘要路径。
