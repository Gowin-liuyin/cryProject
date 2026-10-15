# M3 平台自检结果（独立摘录）

本文件把 M3 的 **6/6** 平台自检结果从构建日志里**独立摘出**，附日志文件名与行号，
供第三方不必打开大日志即可核对。它取代此前在
[`RESULT.md`](RESULT.md) 第 40 行把"原生各 6/6"归到 `native-8b6f2d91/` 目录的表述——
该目录里**没有**独立的 ctest 日志，6/6 的原始行实际在两份 `build-*.log` 内（见下）。

## 1. 本机普通构建

日志：[`build-ordinary.log`](build-ordinary.log)

| 序号 | 测试名 | 结果 | 耗时 | 行号 |
|---|---|---|---|---|
| 1/6 | `platform_m3_on_kat` | Passed | 0.41 s | [68](build-ordinary.log#L68) |
| 2/6 | `platform_m3_on_random_failure` | Passed | 0.35 s | [70](build-ordinary.log#L70) |
| 3/6 | `platform_m3_off_kat` | Passed | 0.34 s | [72](build-ordinary.log#L72) |
| 4/6 | `platform_m3_off_random_failure` | Passed | 0.35 s | [74](build-ordinary.log#L74) |
| 5/6 | `platform_m3_full_output_equivalence` | Passed | 1.11 s | [76](build-ordinary.log#L76) |
| 6/6 | `platform_m3_patch_dry_run` | Passed | 0.03 s | [78](build-ordinary.log#L78) |

汇总行（逐字）：`100% tests passed, 0 tests failed out of 6` ——
[`build-ordinary.log:80`](build-ordinary.log#L80)。

## 2. 本机 ASan/UBSan 构建

日志：[`build-sanitize.log`](build-sanitize.log)

| 序号 | 测试名 | 结果 | 耗时 | 行号 |
|---|---|---|---|---|
| 1/6 | `platform_m3_on_kat` | Passed | 0.57 s | [68](build-sanitize.log#L68) |
| 2/6 | `platform_m3_on_random_failure` | Passed | 0.61 s | [70](build-sanitize.log#L70) |
| 3/6 | `platform_m3_off_kat` | Passed | 0.67 s | [72](build-sanitize.log#L72) |
| 4/6 | `platform_m3_off_random_failure` | Passed | 0.66 s | [74](build-sanitize.log#L74) |
| 5/6 | `platform_m3_full_output_equivalence` | Passed | 1.66 s | [76](build-sanitize.log#L76) |
| 6/6 | `platform_m3_patch_dry_run` | Passed | 0.03 s | [78](build-sanitize.log#L78) |

汇总行（逐字）：`100% tests passed, 0 tests failed out of 6` ——
[`build-sanitize.log:80`](build-sanitize.log#L80)。

## 3. 原生 x86_64 采数树

采数树是 `Cry/platform-m3-locate-20261016-4b102a339cc8`，其 **CTest 6/6** 与四组合 Memcheck
记录在 [`LOCATE_RESULT.md`](LOCATE_RESULT.md) §1 与 §3（本轮定位复验那份），
两臂 measure 的实读摘要为
`a371ed089e857d92069dbd670afab2f0de546e0042be869bba7c9c5da680a1f7`（on）与
`8daaea28ffe97cb71800195e6113245080205f3d044859709834c22d99b4425d`（off）。
本文件只摘录**本机**两份构建日志的 6/6；原生那 6/6 的原始输出在远端新根内，
本地副本见 `locate-v2/`。

## 4. 该怎么引用

- 引用本机普通/ASan+UBSan 的 6/6 时，请指向本文件的第 1、2 节（带日志行号）。
- 引用原生采数树的 6/6 时，请指向 [`LOCATE_RESULT.md`](LOCATE_RESULT.md)，并注明其原始输出在
  `locate-v2/`，**不要**指向 `native-8b6f2d91/`（那里没有独立 ctest 日志）。

> 更正说明（2026-10-16，主控）：本文件用于闭合末次审计的不一致项 **C-04**。
> [`RESULT.md`](RESULT.md) 与 `LOCATE_RESULT.md` 的原文未改写；本文件是对其引用入口的补充与更正。
