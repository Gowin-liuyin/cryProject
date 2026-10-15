# 开源工具接入规程（写在出结果之前）

日期：2026-10-15。样本只来自已提交的锁频采集 `docs/evidence/liboqs010-locked-20261015/`，不并入未锁频试点。

## 共同口径

- 主机：`nss-m`，x86_64 裸金属，Clang 18.1.3。
- 未修二进制：`build/historical-clangover/historical/measure`，SHA-256 `bd84ee9c2a44993fb5c6b43c4fb37027a168d265b4ca027eba3c3026798a0f78`。
- 已修二进制：`build/historical-fixed-982c762/historical/measure`，SHA-256 `1849821eca3039872cf5f103e3928141978b8846792a8da4e7c790ce96c2b5e9`。
- 两类：`message-zero` 与 `message-ones`。种子 `31337`。每类 10000 次的锁频 CSV 是 RTLF 的输入。
- AVX2：两边都关了 `OQS_USE_AVX2_INSTRUCTIONS` 和 `OQS_ENABLE_KEM_ml_kem_768_ipd_avx2`。只关 `OQS_DIST_BUILD` 不够。
- 不做密钥恢复。不改 `vendor/liboqs-0.10.0/`。

## RTLF

- 上游 `third_party/RTLF`，提交 `2497d660e4b23fc9acd21b077a35e82178fcd728`。
- α = 0.01。命令使用 `-a 0.01`。不使用默认 0.09。
- 输入是两列 `message-zero,message-ones`，按锁频 CSV 中的出现顺序抽出，不重排。
- 未修、已修各跑两次。两次决策必须相同才采用。

## dudect

- 上游 `third_party/dudect`，提交 `dc269651fb2567e46755cfb2a13d3875592968b5`。统计量来自该头文件里的 Welch 实现，阈值仍是上游的 `t > 10`。
- 入口是 `tools/historical_dudect.c` 调用 `mlkem_decapsulate`。类 0 为 message-zero，类 1 为 message-ones，密钥种子 `31337`。
- 预算：每批 `number_measurements=10000`，最多 21 批。dudect 丢掉第 1 批，因此进入统计的上限是 200000 次。一旦上游返回 `DUDECT_LEAKAGE_FOUND` 就停，不再加预算。
- 外部 `taskset -c 2`。频率请求与锁频证据相同：全局 boost 0，CPU2 governor 与 EPP 为 performance，min=max=4300000 kHz。接受规则也相同：20 次当前频率跨度不超过 50000 kHz。
- 计时用的是 dudect 自己的 `rdtsc`，不是 measure 的 `CLOCK_MONOTONIC`。这个差别要写进结果，不把它说成同一条 CI。

## Valgrind

- ctgrind 提交 `ca93f4f6f97b0249682c3291ddc241be56e22760`。它的补丁针对旧 Valgrind。若打不上，保存失败日志，并改用发行版 memcheck 的 `VALGRIND_MAKE_MEM_UNDEFINED` 标记解封装私钥。
- `tools/historical_poison.c` 对 message-zero 与 message-ones 各解封装一次。不把这段计时并入锁频 CI。
- 关心的是 “Conditional jump or move depends on uninitialised value” 是否落在未修的 `poly_frommsg`，以及已修的对应项。

## 不做

- Microwalk：先查 Pin。没有就记跳过。
- 不跑 clangover 或 KyberSlash 的密钥恢复。
