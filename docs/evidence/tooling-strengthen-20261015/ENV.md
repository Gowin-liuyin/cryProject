# 环境

- 统计样本主机：`nss-m`，`systemd-detect-virt=none`，x86_64，AMD Ryzen 9 9950X，Clang 18.1.3。
- 锁频证据：`docs/evidence/liboqs010-locked-20261015/`。未修 `message-zero` 减 `message-ones` 的 95% 区间是 21.658 到 57.017 ns，不含 0。已修是 −33.238 到 6.820 ns，含 0。未锁频试点不并入。
- 未修 measure SHA-256 `bd84ee9c2a44993fb5c6b43c4fb37027a168d265b4ca027eba3c3026798a0f78`。
- 已修 measure SHA-256 `1849821eca3039872cf5f103e3928141978b8846792a8da4e7c790ce96c2b5e9`。
- 两边 `C_FLAGS` 含 `-Os -fno-vectorize`，`OQS_USE_AVX2_INSTRUCTIONS` 与 `OQS_ENABLE_KEM_ml_kem_768_ipd_avx2` 未定义。只关 `OQS_DIST_BUILD` 仍会在这台 Ryzen 上走到 AVX2。
- 钉住的 `vendor/liboqs-0.10.0/` 没有为了这次检测而修改。
- 工具运行机仍是 `nss-m`。Rscript 4.3.3，Valgrind 3.22.0。`pin` 不在 PATH。
- dudect 当次频率：boost 0，CPU2 performance，min=max=4300000 kHz；接受探针跨度 40410 kHz。结束后快照与进入时一致。
