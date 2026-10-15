# 开源检测器对照（2026-10-15，nss-m）

规程在出结果之前写入 `PROTOCOL.md`，提交 `877c5f4`。样本类对是锁频证据里的 `message-zero` 与 `message-ones`。未锁频试点没有并进来。两边构建都额外关掉了 AVX2 分发；只关 `OQS_DIST_BUILD` 仍会在这台 Ryzen 上走到 AVX2。

## 对照

| 工具 | 未修 | 已修 | 路径 | 与锁频 CI |
|---|---|---|---|---|
| 锁频正态近似，z=1.96 | 均值差 39.337 ns，区间 21.658 到 57.017，不含 0 | 均值差 −13.209 ns，区间 −33.238 到 6.820，含 0 | `docs/evidence/liboqs010-locked-20261015/` | 基准 |
| RTLF α=0.01，两次 | 两次都是 significant，退出码 11，显著分位 10/20/30/50/60/70/80/90 | 两次都是 no significant difference，退出码 10，显著分位空 | `rtlf/` | 一致 |
| dudect，上游 t>10，`rdtsc`，`taskset -c 2`，boost 0，CPU2 min=max=4300000 kHz | 第 4 批停下，`state=0`（`DUDECT_LEAKAGE_FOUND`），max t +26.41，Probably not constant time | 跑满 21 批，`state=1`（尚未发现泄漏），max t 约 +1.15，maybe constant time | `dudect/` | 一致。计时器是 rdtsc，不是 CI 的 `CLOCK_MONOTONIC` |
| Valgrind 3.22，只标记 indcpa 私钥前 1152 字节 | 1 个条件跳转上下文：`poly_frommsg` `poly.c:179` | 条件跳转上下文 0 个，没有 `poly_frommsg` | `valgrind-ct/*.log` | 定位一致。这不是端到端时序检验 |
| 反汇编 | `bt` / `jae`，写入 `0x681` | `bt` / `setb`，重定位目标 `pqcrystals_ml_kem_768_ipd_ref_cmov_int16`，没有 `jae` | 未修：`liboqs010-locked-20261015/logs/locked-poly-frommsg-vulnerable.s`；已修带重定位：`logs/poly-frommsg-fixed-reloc.s` | 与 Valgrind 的 `poly_frommsg` 命中一致 |

整段私钥都被标记时，未修和已修都会在 `rej_uniform` 报条件跳转。解封装私钥后部是公开封装密钥，`gen_at` 用的是其中的公开种子。收窄到 indcpa 私钥之后，`rej_uniform` 不再出现，未修只剩 `poly_frommsg`。完整标记的日志留在 `vulnerable-full-key.log` 与 `fixed-full-key.log`。

ctgrind `ca93f4f` 的补丁针对 Valgrind SVN r11097。这台机器是 Valgrind 3.22.0，没有对应的 `mc_main.c`，补丁没有打上。秘密跟踪用的是发行版 memcheck 的 `VALGRIND_MAKE_MEM_UNDEFINED`。

Microwalk 跳过：`pin` 不在 `PATH` 里。

dudect 采集中 CPU2 当前频率：未修 21 次，4300000–4335723 kHz；已修 106 次，4300000–4337281 kHz。结束后快照与进入时一致。

## 三句结论

1. 泄漏位置在未修 portable C `poly_frommsg` 的消息位条件分支：反汇编是 `bt`/`jae`，Valgrind 在 `poly.c:179` 报秘密相关条件跳转；官方 `982c762` 重链后该跳转消失，变成 `setb` 加 `cmov_int16`。
2. 同一锁频类对上，正态近似区间、RTLF（α=0.01）和 dudect（预算见规程，阈值仍是上游 t>10）在未修都指向可区分，在已修都不再给出同向的稳定可区分。
3. 没有恢复密钥，也没有跑 clangover 或 KyberSlash 的密钥恢复。已修的“maybe constant time”不是恒时证明。R02 与 R04 不因此关闭。
