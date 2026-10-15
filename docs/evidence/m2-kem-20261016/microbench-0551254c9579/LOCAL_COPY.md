# 本地证据副本说明（microbench-0551254c9579）

本目录是远端
`/home/nss-marker/yhr/Cry/platform-m2micro-20261016-0551254c9579/` 的本地证据副本，
外加 lead 拉回并统计后的少量本地产物。两份清单都可用：

```sh
cd docs/evidence/m2-kem-20261016/microbench-0551254c9579
shasum -a 256 -c EVIDENCE.sha256     # 239/239 通过（含 6 份原始 CSV 与 6 份 meta）
cd source && shasum -a 256 -c ../MICRO_ADDITIONS.sha256   # 8/8 通过（新增源文件）
```

## 内容对应

| 本地路径 | 来源 | 说明 |
|---|---|---|
| `README.md` `COMMANDS.md` `NOTE-poly_tomsg-minus2497.txt` `run_controller_microbench.sh` `verify_completed_micro_runs.sh` | 作者（微基准任务） | 仪表说明、命令清单、机制登记、运行后核对 |
| `source/tools/platform_m2_micro/` `source/cmake/PlatformM2Micro.cmake` | 作者新增源 | 与远端逐字节相同；与冻结源清单的区别见 `MICRO_ADDITIONS.sha256`（8 条） |
| `disasm/` | 远端 | 6 个 ELF 的 `div` 计数、热点/窗口/`main` 反汇编、操作码直方图、符号与 `ldd` |
| `qualification-ordinary/` `qualification-smoke/` `failed/` `*-build-*.log` `micro-qualification.log` | 远端 | 两臂功能资格与转录、解锁冒烟与 `--format measure` 兼容性、失败归档、构建与 CTest 日志 |
| `elf/` | 远端 | 6 个 ELF 原件（本地核对用；`ELF.sha256` 给出远端相对路径摘要） |
| `runs/<run-name>/<arm>-main.csv` `.meta` | 远端 | 六个预注册 run 的**原始逐次数据**（lead 执行，作者独立核对） |
| `RUNS.sha256` `micro-runs-verification.log` | 远端 | 原始数据摘要；`micro_run_verification_status=PASS`（6/6、0 失败检查） |
| `SOURCE_TREE.frozen.sha256` `source-tree-verify.log` | 远端 | 冻结 `SOURCE_TREE.sha256` 的原样副本与其复核日志（592 通过 / 2 陈旧，陈旧项在冻结原件上同样失败） |
| `RESULT.md` `analysis-local/` `controller/` `analysis/` | **lead 拉回并统计** | 微基准层统计结论、battery 产物、控制器逐写回执；不在远端清单内，作者未改动 |
| `runs/*/*.csv.gz` | **lead 拉回** | 同一批原始 CSV 的压缩副本；作者已核对解压后与远端摘要逐份一致（6/6） |

## 边界

- `EVIDENCE.sha256` 的路径是**远端树相对路径**，本地按同构目录摆放，因此可直接 `-c` 校验。
- 本地独有的 lead 产物（`RESULT.md`、`analysis-local/`、`controller/`、`runs/*.csv.gz`）
  不带本文件的摘要校验，它们由 lead 自己维护；作者只做只读核对。
- 远端树内另有 `tmp/`：一次性诊断探针与自检现场的临时目录，**不属于证据**，
  也未纳入 `EVIDENCE.sha256`。
