# r01-kat-20261016 证据目录

T05（向量来源总表）与 T06（修复语义等价）的原始日志、逐例摘要与驱动源码。

## 内容

| 路径 | 说明 |
| --- | --- |
| `VECTORS.md` | T05 总表：模块 × 版本 × 向量来源/commit/SHA-256 × 例数 × 通过数 × 日志路径 |
| `EQUIV.md` | T06 总表：每对的公开向量数、随机/篡改数、diff 结果、隐式拒绝检查结果、日志路径 |
| `drivers/m1_kat.c` | M1 公开 KAT 最小驱动（读 `mlkem768.txt`，期望值全部来自该公开向量文件） |
| `drivers/rr_pair_probe.c` | T06 探针：公开向量 + 1000 例随机/篡改输入 + 隐式拒绝判定，只写摘要与计数 |
| `drivers/run_remote.sh` | 远端构建与运行脚本（编译、跑 KAT、跑探针、`cmp`、生成汇总） |
| `logs/` | 原始日志、`T05_T06_summary.tsv`、`run_remote.out`（环境 + 全部编译命令行 + 全量输出） |
| `logs/remote-manifest.sha256` | 远端新根 `logs/`、`out/`、`drivers/`、`build/` 全部 43 个文件的 SHA-256 |
| `remote-files.sha256` | 上表里已拉回本机部分（`logs/`、`out/`、`drivers/` 共 35 行）的校验清单，`shasum -a 256 -c` 全通过 |
| `out/*.digest` | 两版各自的逐例摘要文件（`cmp` 逐字节比较的输入） |
| `SHA256SUMS` | 本目录全部文件的 SHA-256 |

## 远端位置与运行环境

- 远端唯一可写根：`/home/nss-marker/yhr/Cry/r01-kat-20261016-2ff55778bc52/`（新根，未被复用）。
- 其余远端路径全部只读引用：`liboqs010-historical-20261015-86131c2/`、
  `platform-m2kem-20261016-d75a4019/`、`platform-m3-locate-20261016-4b102a339cc8/`、
  `platform-m4-20261016-6hRHRUxH/`、`platform-m5-20261016-30efdf66eb26/`。
- 运行机器 `nss-m`（x86_64，Ryzen 9 9950X，32 线程），`cc 13.3.0`；未使用 root/sudo，
  未改任何已冻结树或证据，未在远端 `/tmp` 落文件（`TMPDIR`/`TMP`/`TEMP`/`A113_TEST_TMPDIR` 全部指向新根 `tmp/`）。
- 本轮没有做计时采集，也没有改远端调频、隔离或 MSR 配置；未在 CPU2/CPU6 上做任何长时绑定负载。

## 复现

```sh
# 远端（只读复核）
cd /home/nss-marker/yhr/Cry/r01-kat-20261016-2ff55778bc52
cat logs/T05_T06_summary.tsv
sha256sum -c logs/remote-manifest.sha256
# 重新构建并重跑（会覆盖本新根内的 build/logs/out，不动其他树）
sh drivers/run_remote.sh
```

```sh
# 本机
cd docs/evidence/r01-kat-20261016
shasum -a 256 -c remote-files.sha256
shasum -a 256 -c SHA256SUMS
```

## 不声称的内容

- 不构成常数时间、频率锁定、统计显著性或竞赛签收结论；M3/M4 一律是**人工构造校准**夹具。
- M1 的 `keygen 0/25` 是 liboqs 0.10.0 `ML-KEM-768-ipd` 与最终稿 FIPS 203 keygen 的真实差异，
  已在 `VECTORS.md` 用只读源码行号说明，不把它写成"实现失败"或"向量装载错误"。
- 没有做密钥恢复、没有写 exploit、没有打印任何实际运行密钥。
