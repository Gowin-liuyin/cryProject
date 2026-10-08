# 裸金属全流程记录

这是 2026-10-08 在一台裸金属上按现有入口跑出的原始记录。数字以旁边的 CSV 和报告为准。本目录不并入 `docs/evidence/r07-linux-20261008`，也不并入封存的 v3 包。

## 使用这些数字的条件

主机是 Ubuntu 24.04.4，Linux 6.17.0-35-generic，x86_64，`systemd-detect-virt` 为 `none`，CPU 信息中没有 hypervisor。处理器是 AMD Ryzen 9 9950X，16 核 32 线程。源码提交 `a5340330f4d647c850f15329ef6bb7615c7d88ea`。

调速器在采集前和采集后都是 `powersave`，没有改。`preflight.log` 写着 `boost=1`、`cur_khz=2982259`、`min_khz=2982259`、`max_khz=5756452`。`frequency-after.log` 仍是 `governor=powersave`、`cur_khz=2982259`。这不是频率锁定。

时钟是 `CLOCK_MONOTONIC`，单位 ns。普通性能 meta 与机制 meta 都写着 `frequency_control=not_configured` 和 `cpu_affinity=not_pinned`。外部 `taskset -c 2` 只出现在记录了它的命令里：`performance.command` 和每个 `measure-*.command`。`collect.command` 没有绑定 CPU。

## 原始文件

普通性能 18 次运行在 [performance](performance/)：每种实现 6 个块的 CSV、meta、`csv.cost` 和 log，以及 [performance.report](performance/performance.report)、[attempts.tsv](performance/attempts.tsv)。每份 CSV 3000 条正式记录。报告中的探索区间是掩码相对参考 53.755111111–272.396055556 ns，正常优化相对参考 22.683222222–103.365777778 ns。`interval_scope=exploratory_iid_run_pair_bootstrap_only`，`formal_completed_calls=54000`，`warmup_completed_calls=1800`，`report_status=complete`。这不是独立同分布证明。

机制计时 20 次在 [mechanism](mechanism/)：reference、vulnerable、hardened、deployable，种子 31337、90210、20261111、8675309、141421356。每份 CSV 25000 条，旁边是 meta 和 analyze 报告。这次没有另写 groups 报告。

短演示在 [collect](collect/)，`data.csv` 60 条。有限模型在 [calibrate](calibrate/)，`raw.csv` 40964 条数据。后赋标签在 [reference-label-control](reference-label-control/)，`raw.csv` 24576 条数据。

[replay](replay/) 是对封存历史五类记录的重分析，40 份报告。其中 `*.groups.report` 是这次归档重放，不是本机新做的分组检验。

逐步命令、日志、[step-exits.tsv](step-exits.tsv)、[preflight.log](preflight.log) 和 [frequency-after.log](frequency-after.log) 都在本目录。

## 仍失败的构建

`sanitize-build` 退出码是 2，其余记录步骤退出码是 0。日志在 [sanitize-build.log](sanitize-build.log)。GCC 在 `-Werror=sign-conversion` 停下：vulnerable 的 `compress.c:709` 和 hardened 的 `compress.c:710`，都在 `baseline_native_poly_frommsg`。参考实现和正常优化形态编过了。这里不把这次失败改写成通过。

这些记录不是频率锁定、恒时证明或竞赛签收。
