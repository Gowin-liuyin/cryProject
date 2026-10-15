# liboqs 0.10.0 历史分支核对（2026-10-15，nss-m）

裸金属 `nss-m`（`systemd-detect-virt=none`，x86_64，AMD Ryzen 9 9950X）上的 Clang 18.1.3 构建。工作根是 `/home/nss-marker/yhr/Cry/liboqs010-historical-20261015-86131c2`。源码快照来自 `86131c26af1d4bd0c16a933f6b07e930e33536d4`，另加 `beeb4476b589c424e60039c51c79c0ba38da5786` 中的 `cmake/Liboqs010Historical.cmake`：关闭 AVX2 分发，并把 `-Os -fno-vectorize` 写入各配置的 `CMAKE_C_FLAGS_*`。远端该文件摘要为 `b1a258c2bf4e49ac792fe99a2cd7de6bdd7f92039ec446363ab3811a6dd7a042`，与该提交中的文件一致。

这是 GHSA-f2v9-5498-2vpp / clangover 的历史实现核对。对象是 liboqs 0.10.0 的 ML-KEM-768-ipd portable C `*_ref`。它不是最终 FIPS 203 模块，也没有做密钥恢复。

## 身份

- 归档 URL 的独立下载 SHA-256：`2b7b4436be9825dd0adaf000ee4f322f06551e638a8a9c8d54eda48ed40e40a9`，与 `vendor/liboqs-0.10.0.PIN.md` 一致。
- `OQS_VERSION_TEXT` 为 `0.10.0`。钉住的 `vendor/liboqs-0.10.0/` 没有打补丁。
- `SOURCE_EXPORT.sha256` 的摘要是 `480784f1ae747856f226837b8312aa0fb979cd564379c7bedcff5fbdcc2019a1`。二进制里的 `source_commit` 是这个摘要的前 40 个十六进制字符，不是 Git 提交号。
- 编译器：Ubuntu clang 18.1.3，目标 `x86_64-pc-linux-gnu`。
- 进入时频率：governor `powersave`，boost 为 1，EPP `balance_performance`，CPU0 的 min/max 为 2982259 / 5756452 kHz。`frequency_control=not_configured`。

## 构建与后端

preset `historical-clangover`。`historical_selftest` 1/1 通过，`historical/baseline selftest` 打印 roundtrip passed。

`oqsconfig.h` 打开 `OQS_ENABLE_KEM_ml_kem_768_ipd`，`OQS_ENABLE_KEM_ml_kem_768_ipd_avx2` 与 `OQS_USE_AVX2_INSTRUCTIONS` 均为未定义。构建树里没有 avx2 对象。符号是 `pqcrystals_ml_kem_768_ipd_ref_poly_frommsg`。

该目标的 `flags.make` 中 `C_FLAGS` 为：

`-Os -fno-vectorize -Os -fno-vectorize -g -DNDEBUG -std=gnu11 -fPIC -fvisibility=hidden -Wa,--noexecstack -g3 -fno-omit-frame-pointer -DKYBER_K=3`

测量程序自己的身份头仍写着外层 RelWithDebInfo 的 `-O2 -g -DNDEBUG`。那一行描述的是 `measure.c` 这一翻译单元，不是 `poly.c`。

二进制 SHA-256：

- `historical/baseline` `e656a77959492f4c04f12770219c18e0d8476b3dd1fb2052493a323426cb7e9e`
- `historical/measure` `bd84ee9c2a44993fb5c6b43c4fb37027a168d265b4ca027eba3c3026798a0f78`
- `historical/test_selftest` `764d6a39553f464bfdbeee6b4278e5aa774d42f69cfeef2d160ef6aa69d3b98f`
- `liboqs.a` `2f130502b8c1e53b15406ec2f06952528a49fc17abe7577a7500c5722338caa6`

## 分支定位

`logs/poly_frommsg_ref.s` 是上述 ref 目标文件里的 `poly_frommsg`。内层对消息位执行 `bt`，然后 `jae` 决定是否写入 `0x681`（1665，即 `(q+1)/2`）。另外两条 `jne` 比较的是循环界 8 和 32。

官方修复提交 `982c762c242ef549c914891b47bf6e0ed6321f91` 只应用到工作根里的副本 `fix-982c762/`，用同一组 `C_FLAGS` 重编 `poly.c` 与 `verify.c`。修后的 `poly_frommsg` 先写入 0，再用 `bt` / `setb` 取出条件位并调用 `cmov_int16`。`cmov_int16` 是 `neg`、`xor`、`and`、`xor`，没有条件跳转。循环界上的 `jne` 还在。

## 解封装计时试点

协议写在采集之前：种子 `31337`，每类 1000 次，共 5000 行，外部 `taskset -c 2`，主比较是 `message-zero` 减 `message-ones`。没有预先设定阈值，也没有跑 Holm。

采集前把 CPU2 的 `scaling_min_freq` 与 `scaling_max_freq` 都写成 2982259 kHz，读回一致。采集中的 19 次 `scaling_cur_freq` 为 2844764–5625657 kHz，中位 5612452 kHz。请求没有把频率保持住。结束后 CPU2 回到 min 2982259、max 5756452、governor `powersave`、EPP `balance_performance`。程序元数据里的 `cpu_affinity=not_pinned` 和 `frequency_control=not_configured` 是源码里的固定字符串；外部绑核见本记录。

描述性均值（纳秒）：

| 类别 | n | 均值 | 中位数 | 总体标准差 |
|---|---:|---:|---:|---:|
| valid | 1000 | 44457.626 | 44353 | 606.794 |
| bit-flipped | 1000 | 44443.591 | 44353 | 553.170 |
| random | 1000 | 44436.885 | 44343 | 501.138 |
| message-zero | 1000 | 43835.264 | 43752 | 438.964 |
| message-ones | 1000 | 43800.853 | 43722 | 396.879 |

`message-zero` 减 `message-ones` 的均值差是 34.411 ns。类内标准差约 400–600 ns，频率也在动。这次试点不作为时序阳性，也不作为正式统计确认。

## 边界

软件上，历史变体已在这台 x86_64 上接上 ref 后端，分支位置和官方 `cmov_int16` 副本的机器码都有记录。实验上，完整解封装计时只有这一次未稳住频率的试点。假设「端到端可区分」这次没有成立。竞赛验收不因此改变，R02 与 R04 仍不关闭。
