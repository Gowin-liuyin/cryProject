# T20 性能采集件（`perf_measure`）

2026-10-16。本目录只有三个文件，用于 R08 性能开销采数的**工具与构建**部分；
正式采集由主控经唯一锁频控制器串行执行（命令清单见
`docs/evidence/r08-perf-20261016/RUNS.sh`）。

| 文件 | 作用 | 不做什么 |
|---|---|---|
| `perf_measure.c` | 逐次计时**一次完整调用**（`keygen` / `encaps` / `decaps`），按采集件协议落 CSV/meta | 不做统计、不写频率、不写亲和性、不判有效 |
| `build_perf_arms.sh` | 七个完整 KEM 臂各编一份普通 ELF（M1 两版、M2 两版、M3 开/关、M5） | 不重编任何实现，只链接各冻结树既有静态库 |
| `run_perf_qualification.sh` | 资格检查：`--describe` + 小样本试跑 + CSV/meta 格式核对 | **不锁频、不用 sudo、不写任何全局配置** |

## 1. 命令行

```
perf_measure --run-id ID --seed N --raw NEW.csv [--meta NEW.meta]
             [--warmup W] [--decaps-samples D] [--keygen-samples K]
             [--encaps-samples E] [--arm NAME]
             [--block-index B] [--block-count C] [--order-seed S] | --describe
```

| 参数 | 含义 |
|---|---|
| `--run-id` | CSV 第一列；`[A-Za-z0-9_-]`、长度 1..64 |
| `--seed` | 固定测试密钥与固定合法密文的派生种子 |
| `--raw` / `--meta` | **必须不存在**的文件，以 `wx` 新建；已存在即失败 |
| `--warmup` | 每个操作在窗口外的预热次数（默认 100，上限 10000） |
| `--decaps-samples` / `--keygen-samples` / `--encaps-samples` | 三类操作的计时调用次数（各上限 400000；三者不能全为 0） |
| `--arm` | 只写进 meta 的臂名（编译期默认值可用 `-DPERF_ARM_NAME=...` 覆盖） |
| `--block-index` / `--block-count` | 块号（从 0 开始）与块总数，只写进 meta |
| `--order-seed` | 三个操作**计时顺序**的乱序种子；同一值在任何臂上给出同一顺序 |
| `--describe` | 打印工具自述、操作定义、CSV 表头后退出，不采数 |

## 2. 计时窗口

```
clock_gettime(CLOCK_MONOTONIC) → atomic_signal_fence(seq_cst)
    → 一次完整调用（decaps / keygen / encaps）
    → atomic_signal_fence(seq_cst) → clock_gettime(CLOCK_MONOTONIC)
```

窗口外：密钥/密文派生与摘要、预热、内存分配、结果消费、CSV/meta 写盘、ELF 自哈希。
单位 ns，不扣读钟开销、不裁剪长尾。`keygen` 与 `encaps` 的窗口内包含公开 API 自身的
`system_random_bytes`（完整调用的一部分），这一点写进 meta 与 PLAN。

## 3. CSV 列名（与冻结 `--format measure` 同形）

```
run_id,implementation,input_category,sample_index,elapsed_nanoseconds,time_unit
```

- `input_category` ∈ {`decaps`, `keygen`, `encaps`}（是**操作名**）。
- 一份 CSV 只有一个 `run_id` 与一个 `implementation`，`time_unit` 恒为 `ns`，
  因此 `scripts/run_stats_battery.sh --format measure` 能直接解析。
- **但性能表用独立解析**：`--format measure` 输出的是"两类之差"，
  对"逐操作均值/分位数"没有意义。逐操作汇总示例：

```sh
awk -F, 'NR>1{n[$3]++;s[$3]+=$5} END{for(k in n) printf "%s n=%d mean_ns=%.1f\n",k,n[k],s[k]/n[k]}' run.csv
```

## 4. 臂与冻结库

| 臂 | 链接 |
|---|---|
| `m1unfixed` | `<M1>/build/historical-clangover/historical/libmlkem.a` + `liboqs010-install/lib/liboqs.a` |
| `m1fixed` | `<M1>/build/historical-fixed-982c762/…` 同上两份 |
| `m2unfixed` / `m2fixed` | `<M2>/build-ordinary/libplatform_m2_{unfixed,fixed}[_vendor].a` |
| `m3on` / `m3off` | `<M3>/build-ordinary/platform-m3/{on,off}/libmlkem.a` |
| `m5ref` | `<M5>/build-v2-ordinary/reference/libmlkem.a` |

M4 两臂**不在本采集件覆盖内**：M4 是早退比较夹具，没有 `mlkem_*` 三个入口，
直接用它自己的冻结 `platform_m4_measure_{vulnerable,ct}`（窗口只包比较步），
理由写在 `docs/evidence/r08-perf-20261016/PLAN.md` §1。

## 5. 边界

- 采集件不 fork、不 daemonize、不 setsid、不改 HOME、不写自身 CPU 亲和性、
  不写频率、不写给定路径以外的文件；meta 记 `cpu_affinity=not_pinned`、
  `frequency_control=not_configured`。
- 性能数据**不进任何 Holm 家族**，只作开销报告；更快不等于更安全。
