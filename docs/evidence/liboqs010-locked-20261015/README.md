# liboqs 0.10.0 锁频复测（2026-10-15，nss-m）

## 复现时不要只关 OQS_DIST_BUILD

只设 `OQS_DIST_BUILD=OFF` 时，这台具备 AVX2、BMI2 和 POPCNT 的 Ryzen 仍会编译 AVX2，并在运行时把解封装分发过去。clangover 的对象是 portable C `*_ref` 的 `poly_frommsg`。两次构建都另外传入了：

- `-DOQS_USE_AVX2_INSTRUCTIONS=OFF`
- `-DOQS_ENABLE_KEM_ml_kem_768_ipd_avx2=OFF`
- `-DOQS_OPT_TARGET=generic`
- 各配置的 `CMAKE_C_FLAGS_*` 为 `-Os -fno-vectorize`

两边的 `oqsconfig.h` 里 AVX2 宏都是未定义，构建树里没有 avx2 对象。`poly.c` 的 `C_FLAGS` 都是 `-Os -fno-vectorize` 重复一次，后面没有另一个 `-O`。对应说明在 `docs/historical-liboqs-0.10.0.md`，CMake 改动是 `7a998a0cbe9b68b2a541c5a5a153840b132b4e87`。

## 这次跑了什么

工作根 `/home/nss-marker/yhr/Cry/liboqs010-historical-20261015-86131c2`。主机 `nss-m`，x86_64 裸金属，Clang 18.1.3。

- 未修复：已有的 `historical-clangover`，`measure` SHA-256 `bd84ee9c2a44993fb5c6b43c4fb37027a168d265b4ca027eba3c3026798a0f78`。`poly_frommsg` 含 `bt` / `jae`，成立时写入 `0x681`。
- 修复：`982c762c242ef549c914891b47bf6e0ed6321f91` 整份补丁打在副本 `liboqs-0.10.0-982c762/` 上，`patch` 退出码 0。版本文本仍是 `0.10.0`。通过 `-DLIBOQS010_SOURCE_DIR=` 重链进 historical。`measure` SHA-256 `1849821eca3039872cf5f103e3928141978b8846792a8da4e7c790ce96c2b5e9`。`poly_frommsg` 改为 `bt` / `setb` 再调用 `cmov_int16`。钉住的 `vendor/liboqs-0.10.0/` 没有 `cmov_int16`。
- 自检：修复构建的 `historical_selftest` 1/1，`baseline selftest` 通过。
- 导出清单摘要 `f7ce993e1fb33cf9c4e4a79219bcc2eac05fc8e249893101d70670a9479c0e0b`。

规程写在采集之前，见 `logs/stage-d-protocol.txt`。种子 `31337`，每类 10000 次，外部 `taskset -c 2`。主比较只有 `message-zero` 减 `message-ones`。区间是事先写明的正态近似，z=1.96，方差除数 n-1。没有 Holm，也没有另选阈值。

## 频率

请求：全局 boost 写成 0，CPU2 governor 与 EPP 写成 `performance`，min 与 max 都写成 4300000 kHz。其余 CPU 的 governor、min、max、EPP 未改。

第一组 20 次当前频率里有一次仍是 2841814 kHz，未落在请求值的 2% 以内。按规程把 min/max 再写成这组的中位 4300000 kHz。第二组 20 次是 4300000–4335324 kHz，跨度 35324 kHz，接受。

采集中 CPU2 当前频率：

- 未修复：94 次，4300000–4338728 kHz，中位 4309283
- 修复：95 次，4299390–4339301 kHz，中位 4307689

结束后快照与进入时一致：boost 1，CPU2 min 2982259、max 5756452、governor `powersave`、EPP `balance_performance`。程序元数据里的 `frequency_control=not_configured` 仍是源码固定字符串。

## 解封装

| 构建 | 类别 | n | 均值 ns | 中位数 ns | 总体标准差 ns |
|---|---|---:|---:|---:|---:|
| 未修复 | valid | 10000 | 57657.958 | 57599 | 585.636 |
| 未修复 | bit-flipped | 10000 | 57678.999 | 57608 | 693.664 |
| 未修复 | random | 10000 | 57668.016 | 57608 | 650.760 |
| 未修复 | message-zero | 10000 | 56889.226 | 56837 | 673.165 |
| 未修复 | message-ones | 10000 | 56849.889 | 56807 | 600.339 |
| 修复 | valid | 10000 | 57815.507 | 57739 | 787.345 |
| 修复 | bit-flipped | 10000 | 57814.257 | 57739 | 851.999 |
| 修复 | random | 10000 | 57803.637 | 57739 | 700.209 |
| 修复 | message-zero | 10000 | 57797.567 | 57739 | 719.578 |
| 修复 | message-ones | 10000 | 57810.776 | 57739 | 725.495 |

主比较，`message-zero` 减 `message-ones`：

- 未修复：39.337 ns，标准误 9.020，95% 区间 21.658 到 57.017，不含 0
- 修复：−13.209 ns，标准误 10.219，95% 区间 −33.238 到 6.820，含 0

未修复的主区间不含 0，所以按规程没有再跑 `poly_frommsg` 微基准。日志里那一行无条件的 `buried=yes` 没有参与这个判断；决定行是 `decaps_buried=no`。

## 边界

这是同一台机器、同一个种子、同一次频率请求下的前后对比。未修复主区间离开了 0，整包重链后的同一区间含 0。它不是 Holm 确认，不是全体密文的检出率，也不是密钥恢复或 FIPS 203 结论。采集中的当前频率仍有约 40 MHz 的读数跨度。R02 与 R04 不因此关闭。
