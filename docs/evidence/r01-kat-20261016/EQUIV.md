# T06 修复语义等价（r01-kat-20261016）

对每一对"未修 / 已修"实现，用同一份驱动、同一份公开输入在两版上分别运行，比较**逐例输出摘要文件**：

- 公开向量：按各模块自己的公开向量文件取解封装例（M2 另含 100 例官方 round3 KAT 全例）。
- 额外输入：**1000 例**，由公开确定性测试种子派生，**一半随机密文（`INPUT_RANDOM`）一半逐字节篡改密文（`INPUT_BIT_FLIPPED`）**；
  每例还额外记录一次"公开种子密钥对 + 合法封装"的可观测摘要（ek/dk/合法 ct），用来覆盖 keygen/encap 的可观测输出。
- 隐式拒绝：拒绝例返回的共享密钥必须等于规范定义的拒绝值，检查全部在驱动内部完成，
  **只输出计数与布尔，不打印任何共享密钥、密钥字节或内部验证位**。
- 摘要文件由驱动逐例写入 32 字节 SHAKE256 转录；两版文件用 `cmp` 逐字节比较，**diff 为空才算通过**。

驱动源码：`drivers/rr_pair_probe.c`（远端同路径 `/home/nss-marker/yhr/Cry/r01-kat-20261016-2ff55778bc52/drivers/`），
构建与运行脚本：`drivers/run_remote.sh`，完整运行记录：`logs/run_remote.out`。

## 总表

| 模块 | 向量数 | 随机/篡改数 | diff 结果 | 隐式拒绝检查结果 | 日志路径 |
| --- | ---: | ---: | --- | --- | --- |
| M1 liboqs 0.10.0：`historical-clangover` vs `historical-fixed-982c762` | 公开 10 例（mlkem768.txt 的 decap，其中 5 例为拒绝例） | 1000（500 随机 + 500 逐字节篡改） | **空**：`cmp` 退出 0，差异字节 0；两版摘要文件 SHA-256 均为 `f4dbc5f4777247ef8930cd78dcafaa3e327e9d3d92aa2056aa465b55f4310b9d` | 通过：公开例 `public_rejection_agree=10/10`，额外 1000 例 `extra_rejected=1000/1000`、`extra_unexpected_accept=0`；按 FIPS 203 §7.3 的 `J(z‖c)` 判定 | `logs/t06_m1_cmp.log`、`logs/t06_m1_clangover.log`、`logs/t06_m1_fixed.log` |
| M2 pq-crystals kyber768：`a621b8d` vs `272125f` | 公开 100 例（官方 round3 KAT 全例） | 1000（500 随机 + 500 逐字节篡改） | **空**：`cmp` 退出 0，差异字节 0；两版摘要文件 SHA-256 均为 `3af51d3605554f53461a288e1663aa5db50b176ed1df5feecf83c95c0f4ed0a2` | 通过：公开例 `public_expected_match=100/100`、分类一致 `100/100`（round3 KAT 全为接受例）；额外 1000 例 `extra_rejected=1000/1000`；按 Kyber round3 §1.4 的 `KDF(z‖H(c))` 判定（该历史算法不是 FIPS 203，见下） | `logs/t06_m2_cmp.log`、`logs/t06_m2_unfixed.log`、`logs/t06_m2_fixed.log` |
| M3 LUT-on vs LUT-off（人工构造校准） | 公开 10 例（mlkem768.txt 的 decap，其中 5 例为拒绝例） | 1000（500 随机 + 500 逐字节篡改） | **空**：`cmp` 退出 0，差异字节 0；两版摘要文件 SHA-256 均为 `43c1fb206230284b98d89719894c2cc64867b043b508e200dcb7967626c528e3` | 通过：`public_rejection_agree=10/10`，额外 1000 例 `extra_rejected=1000/1000`；按 FIPS 203 §7.3 的 `J(z‖c)` 判定 | `logs/t06_m3_cmp.log`、`logs/t06_m3_on.log`、`logs/t06_m3_off.log` |
| M4 vulnerable vs ct（人工构造校准，仅接口等价） | 不适用（无共享密钥的无密码夹具） | 不适用 | 接口等价：两版 `--describe` 输出逐字节相同（`describe_cmp_exit_status=0`），输入自检输出逐字节相同（`inputs_cmp_exit_status=0`） | 不适用：夹具不做解封装，没有隐式拒绝语义 | `logs/t06_m4_interface_cmp.log`、`logs/t05_m4_vulnerable_describe.log`、`logs/t05_m4_ct_describe.log` |

三对摘要文件都在 `out/`：`m1_clangover.digest`、`m1_fixed.digest`（各 64320 字节）、
`m2_unfixed.digest`、`m2_fixed.digest`（各 67200 字节）、`m3_on.digest`、`m3_off.digest`（各 64320 字节）。

## 摘要文件结构与例数核对

| 模块 | 公开例 × 32B | 额外例 × 64B | 合计字节 |
| --- | ---: | ---: | ---: |
| M1 | 10 × 32 = 320 | 1000 × 64 = 64000 | 64320 |
| M2 | 100 × 32 = 3200 | 1000 × 64 = 64000 | 67200 |
| M3 | 10 × 32 = 320 | 1000 × 64 = 64000 | 64320 |

`out/` 中实际文件大小与上表完全一致（`logs/run_remote.out` 也有同样记录），说明每版都跑满了公开例与 1000 例额外输入，
不是"少跑一部分所以看起来相同"。每例摘要输入为 `tag ‖ index ‖ 密文 ‖ 共享密钥`（公开例）或
`tag ‖ index ‖ 密文 ‖ 共享密钥`（额外例的解封装部分）与 `tag ‖ index ‖ ek ‖ dk ‖ 合法 ct`（额外例的密钥对/封装部分），
经 SHAKE256-256bit 压缩后落盘：既能逐字节比较，也不把共享密钥写进证据。

## 隐式拒绝判定的口径

- **M1（liboqs 0.10.0 ML-KEM-768-ipd）与 M3（本仓库 ML-KEM-768 路径）**：按 FIPS 203 §7.3，
  拒绝值为 `J(z‖c)`，`J = SHAKE256(·, 32)`，`z` 取 `dk` 末 32 字节。判定条件为
  `ss == SHAKE256(z‖ct, 32)`，并且它与"该例是否本该被拒绝"一致。
- **M2（pq-crystals kyber768 round3）**：这是**历史 Kyber 第 3 轮**，不是 FIPS 203，
  其规范拒绝值为 `KDF(z‖H(c))`，即 `SHAKE256(z‖SHA3-256(ct), 32)`
  （上游 `ref/kem.c` 的 `hash_h(kr+KYBER_SYMBYTES, ct, …)` + `kdf(ss, kr, 2*KYBER_SYMBYTES)`）。
  本表按 round3 定义判定，并在 `logs/t06_m2_*.log` 中记录 `rejection_style=2`。
  不把 round3 的拒绝公式冒称 FIPS 203 附录口径。
- 两版实现的隐式拒绝值在 1000 例上都是"精确等于规范拒绝值"而不是"固定拒绝密钥"：
  若某一版返回固定值或常量，`extra_rejected` 不会同时满足 1000/1000（随机密文各不相同）。

## M4 接口等价的边界

M4 是人工构造的 `early_reject_memcmp` 比较夹具，只有 32 字节比较与两类错位位置，**没有密码算法和共享密钥**。
因此这里只能做接口等价说明：两版暴露相同的 ABI/边界参数（`compare_bytes_default=32`、
`compare_bytes_range=1..32`、`abi_bytes=32`、`warmup_calls=100`、`truncation_rule=mismatch-last:…`），
两版在两类输入上的可观测判定相同。该夹具的时序差异是**故意保留的实验缺陷**，本轮不采集计时，也不做统计结论。

## 必须如实报告的两点

1. **M1 的 keygen 0/25 不影响本表的 diff 结论**，但必须与 T06 一起读：
   两版都接的是 liboqs 0.10.0 的 `ML-KEM-768-ipd`，与最终稿 FIPS 203 的 keygen 不同（见 `VECTORS.md`）。
   本表的"公开 10 例"用的是 `mlkem768.txt` 的 decap 例（用向量给定的 dk/ct），两版都能复现期望值，
   所以这 10 例的等价比较是有效的；额外 1000 例覆盖了两版各自的 keygen+encap 输出摘要，也逐字节相同。
2. **M2 的公开 100 例全部是接受例**（官方 round3 KAT 的 `ss` 就是接受路径的共享密钥），
   所以 round3 的拒绝路径只由额外 1000 例覆盖；这一点在表中直接写明，不假装公开向量覆盖了拒绝分支。

## 复核方式

```sh
# 远端（只读复核，不需要 root）
cd /home/nss-marker/yhr/Cry/r01-kat-20261016-2ff55778bc52
cat logs/T05_T06_summary.tsv
sha256sum -c logs/remote-manifest.sha256
cmp out/m1_clangover.digest out/m1_fixed.digest && echo m1-identical
cmp out/m2_unfixed.digest   out/m2_fixed.digest   && echo m2-identical
cmp out/m3_on.digest        out/m3_off.digest     && echo m3-identical
```

本目录 `logs/remote-manifest.sha256` 固定了远端 `logs/`、`out/`、`drivers/`、`build/` 全部 44 个文件的 SHA-256；
`logs/` 与 `out/` 已原样拉回本目录，可用 `shasum -a 256 -c` 复核（本机只需比对 `logs/`、`out/` 前缀的行）。
