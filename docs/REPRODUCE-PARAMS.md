# 复现参数总表（2026-10-16）

本页是 T30 的参数总表：每个模块**实际用过的**编译选项、种子、样本数、核与频率管理、
统计脚本/工具、计划文件与证据目录。**每一行的链接都指向仓库内真实存在的文件**；
没有落盘依据的参数不写进来。

配套入口是 [`scripts/reproduce_all.sh`](../scripts/reproduce_all.sh)：`quick` 档在无 sudo
环境跑配置/构建/CTest 与小样本统计演练，`full` 档按本页的四份 PLAN 生成完整采集命令
（默认 dry-run，`--execute` 才真跑，锁频部分需 sudo 且串行）。

口径提醒：
- 四份模块 PLAN 在提交 `efca8a1` 冻结后才执行采集，之后的文档修订摘要与执行版不同；
  控制器校验的是**执行版**摘要，逐一列在
  [platform-collection-20261016/README.md](evidence/platform-collection-20261016/README.md)。
- 固定第三方身份见 [tooling-strengthen-20261015/REPOS.md](evidence/tooling-strengthen-20261015/REPOS.md)
  与各模块 PLAN；`third_party/`、`vendor/liboqs-0.10.0/`、`vendor/kyber-kyberslash-*` 都在
  `.gitignore` 内，干净 clone 需要先按下面的取件入口补齐。

## 0. 公共入口与工具身份

| 项 | 值 | 依据文件 |
|---|---|---|
| 构建与测试唯一来源 | CMake；根 `Makefile` 只做兼容转发 | [CMakeLists.txt](../CMakeLists.txt)、[CMakePresets.json](../CMakePresets.json)、[Makefile](../Makefile) |
| 平台开关 | `-DBASELINE_ENABLE_PLATFORM=ON -DA113_ARCHIVED_CASE_ONLY=OFF` | [CMakeLists.txt](../CMakeLists.txt)（第 32-33 行）、[cmake/PlatformM5.cmake](../cmake/PlatformM5.cmake)、[cmake/PlatformStats.cmake](../cmake/PlatformStats.cmake)、[cmake/PlatformM2.cmake](../cmake/PlatformM2.cmake)、[cmake/PlatformM3.cmake](../cmake/PlatformM3.cmake)、[cmake/PlatformM4.cmake](../cmake/PlatformM4.cmake)、[cmake/PlatformMona.cmake](../cmake/PlatformMona.cmake) |
| sanitizer 配置 | `-DBASELINE_SANITIZERS=ON -DCMAKE_BUILD_TYPE=Debug`（`-O1 -g -fsanitize=address,undefined`） | [CMakeLists.txt](../CMakeLists.txt)（第 91-96 行）、[CMakePresets.json](../CMakePresets.json) |
| 锁频控制器 | `tools/platform_control/controller.py`，sha256 `4a0cf57a00c6802ff86ed410bd2518bc56cc8e694422cbc4ea7a24a3f1cdd701`（提交 `a3c9ca1`） | [tools/platform_control/controller.py](../tools/platform_control/controller.py)、[tools/platform_control/README.md](../tools/platform_control/README.md)、[platform-collection-20261016/README.md](evidence/platform-collection-20261016/README.md) |
| 控制器资格 | 五条空任务全过（normal / failure / timeout / controller-loss） | [platform-control-qualification-20261016/QUALIFICATION.md](evidence/platform-control-qualification-20261016/QUALIFICATION.md) |
| 统计电池（Welch + 调度族外工具） | `scripts/run_stats_battery.sh` | [scripts/run_stats_battery.sh](../scripts/run_stats_battery.sh)、[scripts/platform_stats/stats_csv.c](../scripts/platform_stats/stats_csv.c) |
| Holm + 固定效应合并 | `platform_holm --input <members.csv> --output-dir <NEW_DIR> --alpha 0.05` | [tools/platform_stats/holm.c](../tools/platform_stats/holm.c)、[cmake/PlatformStats.cmake](../cmake/PlatformStats.cmake)、[platform-stats-holm-20261016/README.md](evidence/platform-stats-holm-20261016/README.md) |
| RTLF（族外） | 上游 `rtlf.R`，α=0.01，bootstrap 种子 `2026101605`；二值结论，不进 Holm | [tooling-strengthen-20261015/REPOS.md](evidence/tooling-strengthen-20261015/REPOS.md)、[platform-rtlf-20261016/RTLF_RESULT.md](evidence/platform-rtlf-20261016/RTLF_RESULT.md) |
| dudect（族外） | 上游单头库，阈值 `t > 10`；在线入口 `platform_m5_dudect --collect --seed N --raw NEW.csv` | [tooling-strengthen-20261015/REPOS.md](evidence/tooling-strengthen-20261015/REPOS.md)、[m5-completion-20261016/PLAN.md](evidence/m5-completion-20261016/PLAN.md)（§1.4） |
| Binsec checkct（形式层） | `-sse -checkct -checkct-features control-flow,memory-access -smt-solver z3`，分析 120 s / 单查询 5 s / 额外墙钟 180 s | [m4-completion-20261016/RESULT.md](evidence/m4-completion-20261016/RESULT.md)（第 23 行）、[runtime-logs/binsec-version.log](evidence/m4-completion-20261016/runtime/runtime-logs/binsec-version.log) |
| Microwalk（定位层） | 源码自建的 Microwalk 3.x master + 自建 Pin 3.28；官方镜像未拉取 | [m3-completion-20261016/LOCATE_RESULT.md](evidence/m3-completion-20261016/LOCATE_RESULT.md)（§2.6、§2.7） |
| Mona（族外统计对照） | `mona-timing-report@4c74fb7e629b4d057b2d5d4accdb120d920774b7`，离线回放，`holm_member=false` | [mona-wire-20261016/RESULT.md](evidence/mona-wire-20261016/RESULT.md) |
| 一键复现入口 | `scripts/reproduce_all.sh quick` / `full` | [scripts/reproduce_all.sh](../scripts/reproduce_all.sh) |

## 1. M1：liboqs 0.10.0 历史 CVE（真实历史阳性）

| 阶段 / 工具 | 编译选项 | 种子 | 样本数 | 核与频率 | 统计脚本或工具 | 计划 / 规程 | 证据目录 |
|---|---|---|---|---|---|---|---|
| 锁频端到端采集 | Clang 18.1.3；`-Os -fno-vectorize`；`-DOQS_USE_AVX2_INSTRUCTIONS=OFF -DOQS_ENABLE_KEM_ml_kem_768_ipd_avx2=OFF -DOQS_OPT_TARGET=generic` | `31337` | 10000 / 类 × 5 类（valid、bit-flipped、random、message-zero、message-ones） | `taskset -c 2`；boost=0、governor/EPP=performance、min=max=4300000 kHz | 事先写明的正态近似 z=1.96（无 Holm） | [liboqs010-locked-20261015/README.md](evidence/liboqs010-locked-20261015/README.md)、[logs/stage-d-protocol.txt](evidence/liboqs010-locked-20261015/logs/stage-d-protocol.txt)、[logs/run-locked-31337.sh](evidence/liboqs010-locked-20261015/logs/run-locked-31337.sh) | [liboqs010-locked-20261015/](evidence/liboqs010-locked-20261015/README.md) |
| 三次独立复测 + Holm | 同上（同一对 measure ELF：未修 `bd84ee9c…`、已修 `1849821e…`） | `31337` / `424242` / `31337` | 10000 / 类 | CPU2 / CPU2 / CPU6；同一次频率请求 | Welch 95% CI + Holm m=6（`holm.csv`）+ 固定效应合并 | [r02-r04-close-20261016/PLAN.md](evidence/r02-r04-close-20261016/PLAN.md)、[RESULT.md](evidence/r02-r04-close-20261016/RESULT.md) | [r02-r04-close-20261016/](evidence/r02-r04-close-20261016/RESULT.md)（`holm.csv`、`replication.csv`、`raw/`） |
| RTLF α=0.01（族外） | 不适用（只读 CSV） | 输入为锁频 CSV 的原类内顺序 | 10000 / 类 | 统计在 `nss-m` 上跑，无绑核要求 | RTLF 两次，两次决策必须相同 | [tooling-strengthen-20261015/PROTOCOL.md](evidence/tooling-strengthen-20261015/PROTOCOL.md) | [tooling-strengthen-20261015/rtlf/](evidence/tooling-strengthen-20261015/rtlf/command.txt) |
| dudect（族外） | Clang 18.1.3，同未修/已修两 ELF | 密钥种子 `31337`；类 0/1 = message-zero / message-ones | 每批 10000，最多 21 批（上游丢弃第 1 批） | `taskset -c 2`；boost=0、CPU2 performance、min=max=4300000 kHz | 上游 dudect Welch，阈值 `t > 10`；计时用 rdtsc | [tooling-strengthen-20261015/PROTOCOL.md](evidence/tooling-strengthen-20261015/PROTOCOL.md) | [tooling-strengthen-20261015/dudect/](evidence/tooling-strengthen-20261015/dudect/status.txt) |
| Memcheck 秘密标记 | Valgrind 3.22.0；只标记 indcpa 私钥前 1152 字节 | 不适用 | 每类解封装一次 | 不适用 | 发行版 memcheck 的 `VALGRIND_MAKE_MEM_UNDEFINED`；ctgrind 补丁打不上 | [tooling-strengthen-20261015/PROTOCOL.md](evidence/tooling-strengthen-20261015/PROTOCOL.md)、[RESULT.md](evidence/tooling-strengthen-20261015/RESULT.md) | [tooling-strengthen-20261015/valgrind-ct/](evidence/tooling-strengthen-20261015/valgrind-ct/vulnerable.log) |
| Mona 离线回放（族外） | 不适用（Java 报告侧） | 无（无重采样） | 六份输入各 10000 值/类 | `taskset -c 0,1`；不占 CPU2/6、不调频 | 上游 `StatisticEvaluation.calibrationPhase()`；`holm_member=false` | [mona-wire-20261016/RESULT.md](evidence/mona-wire-20261016/RESULT.md) | [mona-wire-20261016/native-v2/run/m1/](evidence/mona-wire-20261016/RESULT.md) |
| 反汇编 | 同上两 ELF | 不适用 | 不适用 | 不适用 | `objdump` 逐函数 | [liboqs010-locked-20261015/README.md](evidence/liboqs010-locked-20261015/README.md) | [logs/locked-poly-frommsg-vulnerable.s](evidence/liboqs010-locked-20261015/logs/locked-poly-frommsg-vulnerable.s)、[logs/locked-poly-frommsg-fixed.s](evidence/liboqs010-locked-20261015/logs/locked-poly-frommsg-fixed.s) |

## 2. M2：秘密相关除法（真实 KyberSlash 历史路径）

| 阶段 / 工具 | 编译选项 | 种子 | 样本数 | 核与频率 | 统计脚本或工具 | 计划 / 规程 | 证据目录 |
|---|---|---|---|---|---|---|---|
| 端到端采集（collector-v2） | 上游 vendor 单独 `-Oz -g -fno-vectorize -fno-slp-vectorize`；适配层走仓库告警口径 | `31337` / `424242` / `31337` | 10000 / 类（主类对与对照类对各 10000）+ 预热 100（窗口外） | CPU2 / CPU2 / CPU6；boost=0、performance、min=max=4300000 kHz | Welch + Holm（族 `m2_end_to_end_full_decaps_v1`，m=6） | [m2-kem-20261016/PLAN.md](evidence/m2-kem-20261016/PLAN.md)、[COLLECTOR_CONTRACT.md](evidence/m2-kem-20261016/COLLECTOR_CONTRACT.md)、[STATISTICAL_PLAN.md](evidence/m2-kem-20261016/STATISTICAL_PLAN.md) | [platform-collection-20261016/README.md](evidence/platform-collection-20261016/README.md)、[stats/m2-m2-s1-unfixed-main/](evidence/platform-collection-20261016/stats/m2-m2-s1-unfixed-main/ci_welch.json) |
| 除法热点微基准 | 同上；窗口只含 `pqcrystals_kyber768_ref_poly_tomsg` | 六个预注册运行：`31337`/`424242`/`31337` × 两臂 | 10000 / 类 + 预热 100 | CPU2 / CPU2 / CPU6，全部经锁频控制器 | Welch + Holm（族 `m2_div_hotspot_microbench_v1`，m=6） | [microbench-0551254c9579/README.md](evidence/m2-kem-20261016/microbench-0551254c9579/README.md)、[RESULT.md](evidence/m2-kem-20261016/microbench-0551254c9579/RESULT.md) | [microbench-0551254c9579/](evidence/m2-kem-20261016/microbench-0551254c9579/RESULT.md)（`analysis-local/`、`controller/`） |
| online dudect（族外） | 同 ELF 身份由 `m2_dudect --describe` 记录 | 同上三次运行的种子 | 每批 10000，最多 21 批 = 每臂 210000 次 | 同上（6 次控制器运行） | 上游 dudect，阈值 `t > 10`；`--stop-on-positive` 可选 | [m2-kem-20261016/PLAN.md](evidence/m2-kem-20261016/PLAN.md)（§2.3） | [platform-collection-20261016/M2/m2-s1-dud-unfixed/](evidence/platform-collection-20261016/M2/m2-s1-dud-unfixed/controller/worker.stdout) |
| RTLF α=0.01（族外） | 不适用 | bootstrap 种子 `2026101605` | 每数据集 10000 vs 10000 | 统计机 `nss-m` | RTLF 二值结论 | [platform-rtlf-20261016/RTLF_RESULT.md](evidence/platform-rtlf-20261016/RTLF_RESULT.md) | [platform-rtlf-20261016/results/](evidence/platform-rtlf-20261016/results/m2-m2-s1-unfixed-main/rtlf.json) |
| KyberSlash varlat（定位层） | Valgrind 3.25.1 + 20250805 补丁；`--command-line-only=yes --tool=memcheck --track-origins=yes --vgdb=no --error-exitcode=99 --variable-latency-errors=yes` | 不适用（公开人工多项式夹具） | 每探针一次 | 不适用 | varlat（可变延迟指令） | [m2-kyberslash-20261016/VERSION_AUDIT.md](evidence/m2-kyberslash-20261016/VERSION_AUDIT.md) | [version-audit/](evidence/m2-kyberslash-20261016/version-audit/varlat-unfixed.log)、[varlat-tool/](evidence/m2-kyberslash-20261016/varlat-tool/README.md) |
| Mona 离线回放（族外） | 不适用 | 无 | 六份 measure 长表各 10000/类 | `taskset -c 0,1` | 上游自适应箱体搜索；`holm_member=false` | [mona-wire-20261016/RESULT.md](evidence/mona-wire-20261016/RESULT.md)（M2 追加节） | [native-v2/run/m2/](evidence/mona-wire-20261016/RESULT.md) |
| 反汇编 | 同 `-Oz` 探针 ELF | 不适用 | 不适用 | 不适用 | `objdump` | [m2-kyberslash-20261016/VERSION_AUDIT.md](evidence/m2-kyberslash-20261016/VERSION_AUDIT.md) | [disasm/](evidence/m2-kyberslash-20261016/disasm/linux-clang18-oz-unfixed-poly_tomsg.asm)、[native-qualification/](evidence/m2-kem-20261016/native-qualification/unfixed-pqcrystals_kyber768_ref_poly_tomsg.asm) |

取件入口（干净 clone 必需）：`vendor/kyber-kyberslash-{unfixed,fixed}/` 按同级 `PIN.md` 重取，
脚本与合同见 [version-audit/fetch_vendor.sh](evidence/m2-kyberslash-20261016/VERSION_AUDIT.md)。

## 3. M3：人工构造秘密下标 LUT（人工构造校准阳性，定位层）

| 阶段 / 工具 | 编译选项 | 种子 | 样本数 | 核与频率 | 统计脚本或工具 | 计划 / 规程 | 证据目录 |
|---|---|---|---|---|---|---|---|
| on/off 端到端采集 | Clang 18.1.3；`RelWithDebInfo`、`-O2 -g -DNDEBUG -std=c11`、`-Wall -Wextra -Wpedantic -Wshadow -Wconversion -Wstrict-prototypes -Werror`；补丁 `docs/patches/m3-mem-lut-toggle.patch` | `31337` / `424242` / `31337` | 10000 / 类 + 预热 100 | CPU2 / CPU2 / CPU6（12 次控制器运行：2 臂 × 3 次 × (measure + dudect)） | Welch + Holm（族 `m3_lut_arm_end_to_end_v1`，m=6） | [m3-completion-20261016/PLAN.md](evidence/m3-completion-20261016/PLAN.md)、[STATISTICAL_PLAN.md](evidence/m3-completion-20261016/STATISTICAL_PLAN.md)、[TESTS.md](evidence/m3-completion-20261016/TESTS.md) | [platform-collection-20261016/README.md](evidence/platform-collection-20261016/README.md)、[stats/m3-m3-s1-on-main/](evidence/platform-collection-20261016/stats/m3-m3-s1-on-main/ci_welch.json) |
| Memcheck 秘密标记 | 同上的原生普通构建；驱动 `tools/platform_m3/ctgrind_probe.c` | 固定公开种子，每版五类解封装各一次 | 每类一次（完整解封装） | 不适用 | 发行版 Memcheck 标准 client requests（不是 varlat） | [m3-completion-20261016/ENV.md](evidence/m3-completion-20261016/ENV.md)、[LOCATE_RESULT.md](evidence/m3-completion-20261016/LOCATE_RESULT.md) | [native-8b6f2d91/](evidence/m3-completion-20261016/native-8b6f2d91/on-secret.memcheck.log)（on/off × secret/defined 四组） |
| Microwalk 轨迹 | 同一份 overlay 编成 `libm3{on,off}.so`；Microwalk 模板 `main.c` + `m3mwtarget.c` | 固定公开种子 `20261016` | 5 个公开 testcase，无重复 | 不适用 | Microwalk 内存访问互信息 + 控制流泄漏 | [LOCATE_RESULT.md](evidence/m3-completion-20261016/LOCATE_RESULT.md)（§2.6） | [locate-v2/remote/microwalk-probe/](evidence/m3-completion-20261016/locate-v2/remote/microwalk-probe/m3mw/work3-on/persist/target-m3-on/results-memory/mutual-information.txt) |
| online dudect（族外） | M5 系 dudect 在本树重建；实现名守卫放宽到 `platform-m3-lut-on/off` | 同三次运行种子 | 每批 10000 | 同三次运行 | 上游 dudect；该版本无 `--raw`，不产出逐样本 CSV | [m3-completion-20261016/RESULT.md](evidence/m3-completion-20261016/RESULT.md)（第 70-76 行） | [platform-collection-20261016/M3/m3-s1-dud-on/](evidence/platform-collection-20261016/M3/m3-s1-dud-on/controller/worker.stdout) |
| RTLF α=0.01（族外） | 不适用 | bootstrap 种子 `2026101605` | 12 个数据集各 10000 vs 10000 | 统计机 `nss-m` | RTLF 二值结论 | [platform-rtlf-20261016/RTLF_RESULT.md](evidence/platform-rtlf-20261016/RTLF_RESULT.md) | [platform-rtlf-20261016/results/](evidence/platform-rtlf-20261016/results/m3-m3-s1-on-main/rtlf.json) |
| 反汇编 | 同上原生 ELF | 不适用 | 不适用 | 不适用 | `objdump` + 源码行对照 | [LOCATE_RESULT.md](evidence/m3-completion-20261016/LOCATE_RESULT.md) | [native-lut-load-excerpt.txt](evidence/m3-completion-20261016/native-lut-load-excerpt.txt)、[native-probe-identity.txt](evidence/m3-completion-20261016/native-probe-identity.txt)、[native-8b6f2d91/on.measure.disasm](evidence/m3-completion-20261016/native-8b6f2d91/on.measure.disasm) |

## 4. M4：人工提前退出比较（人工构造校准阳性，端到端 vulnerable 臂阳性）

| 阶段 / 工具 | 编译选项 | 种子 | 样本数 | 核与频率 | 统计脚本或工具 | 计划 / 规程 | 证据目录 |
|---|---|---|---|---|---|---|---|
| 主路径端到端采集 | `-O2 -g -DNDEBUG -std=c11 -Wall -Wextra -Wpedantic -Wshadow -Wconversion -Wstrict-prototypes -Werror`；夹具 `fixtures/early_reject_memcmp/` | `31337` / `424242` / `31337` | 10000 / 类 + 预热 100；CLI `m4_measure --collect NEW.csv CALLS_PER_CLASS SEED RUN_ID [--compare-bytes 1..32]` | CPU2 / CPU2 / CPU6（18 次控制器运行，含截断对照与 dudect） | Welch + Holm（族 `m4_compare_arm_session_v1`，m=6） | [m4-completion-20261016/PLAN.md](evidence/m4-completion-20261016/PLAN.md)、[STATISTICAL_PLAN_DRAFT.md](evidence/m4-completion-20261016/STATISTICAL_PLAN_DRAFT.md)、[MEASURE_V2.md](evidence/m4-completion-20261016/MEASURE_V2.md) | [platform-collection-20261016/README.md](evidence/platform-collection-20261016/README.md)、[stats/m4-m4-s1-vuln-main/](evidence/platform-collection-20261016/stats/m4-m4-s1-vuln-main/ci_welch.json) |
| 截断对照臂 | 同上，`--compare-bytes 16` | 同上 | 10000 / 类 | CPU2 / CPU2 / CPU6 | 族外对照（不进 Holm） | [m4-completion-20261016/RESULT.md](evidence/m4-completion-20261016/RESULT.md)（第 57-58、60-63 行） | [platform-collection-20261016/M4/](evidence/platform-collection-20261016/M4/m4-c1-vuln/)、[platform-rtlf-20261016/results/](evidence/platform-rtlf-20261016/results/m4-m4-c1-vuln-control/rtlf.json) |
| Binsec checkct（形式层） | i386 抽取内核；`-sse -checkct -checkct-features control-flow,memory-access -smt-solver z3`；`-sse-depth 10000`（截断对照降到 5） | 不适用 | 公开长度 1–16，秘密 16 字节全标 | 不适用 | Binsec 0.11.3 + Z3 4.15.3 | [m4-completion-20261016/FORMAL_RESULT.md](evidence/m4-completion-20261016/FORMAL_RESULT.md)、[formal-v1/vulnerable-1-16/checkct.toml](evidence/m4-completion-20261016/formal-v1/vulnerable-1-16/checkct.toml) | [formal-v1/](evidence/m4-completion-20261016/formal-v1/vulnerable-1-16/stdout.txt)、[formal-v2/](evidence/m4-completion-20261016/formal-v2/vulnerable-1-16/status.txt)、[runtime/](evidence/m4-completion-20261016/runtime/runtime-logs/binsec-version.log) |
| Memcheck 秘密标记 | Valgrind 3.22.0；poison 驱动 `tools/platform_m4/` | 不适用 | `--probe` 一次比较 | 不适用 | 发行版 Memcheck 秘密标记 | [m4-compare-20261016/RESULT.md](evidence/m4-compare-20261016/RESULT.md)（第 5 行） | [linux-run-250f424b/valgrind-vulnerable.log](evidence/m4-compare-20261016/linux-run-250f424b/valgrind-vulnerable.log)、[valgrind-ct.log](evidence/m4-compare-20261016/linux-run-250f424b/valgrind-ct.log) |
| online dudect（族外） | `platform_m4_dudect_{vulnerable,ct} --collect NEW_CYCLES.csv BATCHES SEED` | 同三次运行种子 | 每批固定预算（见 PLAN） | 同三次运行 | 上游 dudect，阈值 `t > 10` | [m4-completion-20261016/RESULT.md](evidence/m4-completion-20261016/RESULT.md)（第 55-56 行） | [platform-collection-20261016/M4/m4-s1-dud-vuln/](evidence/platform-collection-20261016/M4/m4-s1-dud-vuln/controller/worker.stdout) |
| RTLF α=0.01（族外） | 不适用 | bootstrap 种子 `2026101605` | 12 个数据集各 10000 vs 10000 | 统计机 `nss-m` | RTLF 二值结论 | [platform-rtlf-20261016/RTLF_RESULT.md](evidence/platform-rtlf-20261016/RTLF_RESULT.md) | [platform-rtlf-20261016/results/](evidence/platform-rtlf-20261016/results/m4-m4-s1-vuln-main/rtlf.json) |
| 反汇编 | 与 Binsec 同一对 ELF | 不适用 | 不适用 | 不适用 | `objdump` | [FORMAL_RESULT.md](evidence/m4-completion-20261016/FORMAL_RESULT.md)（§6.1） | [formal-v2/analysis/disasm-vulnerable.txt](evidence/m4-completion-20261016/formal-v2/analysis/disasm-vulnerable.txt)、[formal-v2/analysis/disasm-ct.txt](evidence/m4-completion-20261016/formal-v2/analysis/disasm-ct.txt) |

## 5. M5：mlkem-native 参考（阴性对照）

| 阶段 / 工具 | 编译选项 | 种子 | 样本数 | 核与频率 | 统计脚本或工具 | 计划 / 规程 | 证据目录 |
|---|---|---|---|---|---|---|---|
| 端到端采集 | Ubuntu Clang 18.1.3；`RelWithDebInfo`、`-O2 -g -DNDEBUG -std=c11`、`-Wall -Wextra -Wpedantic -Wshadow -Wconversion -Wstrict-prototypes -Werror`；portable reference | `31337` / `424242` / `31337` | 10000 / 类 + 预热 100；CLI `measure RUN_ID SEED SAMPLES CSV META` | CPU2 / CPU2 / CPU6；boost=0、performance、min=max=4300000 kHz | Welch + Holm（族 `m5_reference_end_to_end_v1`，m=3） | [m5-completion-20261016/PLAN.md](evidence/m5-completion-20261016/PLAN.md)、[REQUIREMENTS.md](evidence/m5-completion-20261016/REQUIREMENTS.md)、[ENV.md](evidence/m5-completion-20261016/ENV.md) | [platform-collection-20261016/README.md](evidence/platform-collection-20261016/README.md)、[stats/m5-m5-s1-main/](evidence/platform-collection-20261016/stats/m5-m5-s1-main/ci_welch.json) |
| online dudect（族外） | 同参考库；`platform_m5_dudect --collect --seed N --raw NEW.csv`；ELF sha256 `3be87721…` | 同上三次运行种子 | 每批 10000，最多 21 批 | 同三次运行 | 上游 dudect，阈值 `t > 10`；族外不入 Holm | [m5-completion-20261016/PLAN.md](evidence/m5-completion-20261016/PLAN.md)（§1.4、§2.3） | [platform-collection-20261016/M5/m5-s1-dud/](evidence/platform-collection-20261016/M5/m5-s1-dud/controller/worker.stdout) |
| Memcheck 秘密标记 | Valgrind 3.22.0（system）与 3.25.1 + varlat 补丁两模式；标记 PKE 秘密 1152 字节与拒绝 z 32 字节 | 不适用 | 10 次标记完整调用 | 不适用 | Memcheck / varlat=no / varlat=yes 三模式 | [m5-completion-20261016/RESULT.md](evidence/m5-completion-20261016/RESULT.md)、[PLAN.md](evidence/m5-completion-20261016/PLAN.md)（§1.4） | [software-dynamic-evidence.tar.gz](evidence/m5-completion-20261016/software-dynamic-evidence.tar.gz) 内 `logs-v2/{system,varlat-no,varlat-yes}.valgrind.log`（本地解出核对，归档外无散件） |
| RTLF α=0.01（族外） | 不适用 | bootstrap 种子 `2026101605` | 6 个数据集各 10000 vs 10000 | 统计机 `nss-m` | RTLF 二值结论 | [platform-rtlf-20261016/RTLF_RESULT.md](evidence/platform-rtlf-20261016/RTLF_RESULT.md) | [platform-rtlf-20261016/results/](evidence/platform-rtlf-20261016/results/m5-m5-s1-main/rtlf.json) |
| 反汇编 | 同 `build-v2-ordinary` 产物 | 不适用 | 不适用 | 不适用 | `objdump`，调用链确认 | [m5-completion-20261016/RESULT.md](evidence/m5-completion-20261016/RESULT.md) | [software-dynamic-evidence.tar.gz](evidence/m5-completion-20261016/software-dynamic-evidence.tar.gz) 内 `logs-v2/poison.disasm`；已解出副本 [m5-mlkem-native-20261016/measure-call-disasm.txt](evidence/m5-mlkem-native-20261016/measure-call-disasm.txt)、[decapsulation-wrapper-disasm.txt](evidence/m5-mlkem-native-20261016/decapsulation-wrapper-disasm.txt) |

## 6. `scripts/reproduce_all.sh` 两档参数

| 档 | 参数 | 默认 | 说明 |
|---|---|---|---|
| quick | `--configs` | `platform,ordinary,sanitize` | 三个配置全跑；也可只跑其中一个。platform 用 `-DBASELINE_ENABLE_PLATFORM=ON -DA113_ARCHIVED_CASE_ONLY=OFF`，sanitize 用 `-DBASELINE_SANITIZERS=ON -DCMAKE_BUILD_TYPE=Debug` |
| quick | `--samples` | `1000` | 每类样本数，范围 1..20000（与 `measure` 的 CLI 上限一致） |
| quick | `--runs` | `3` | 统计演练的重复运行数；种子沿用冻结 PLAN 的 `31337 / 424242 / 31337` |
| quick | `--jobs` | CPU 数，最多 8 | 只影响 `cmake --build --parallel` |
| quick | `--work-dir` | `<仓库>/build/reproduce-quick` | 日志在 `<work-dir>/logs/`，汇总在 `quick-summary.tsv`，演练产物在 `rehearsal/` |
| quick | `--skip-stats` / `--keep-going` | 关 | 前者只做配置/构建/CTest；后者单个配置失败仍继续 |
| full | `--execute` | 关（dry-run） | 打开后需要 `--control-root` 且必须是 `<...>/Cry` 下的控制根；需要 sudo、必须串行 |
| full | `--modules` | `M2,M3,M4,M5` | 与四份 PLAN 一一对应 |
| full | `--samples` / `--timeout-seconds` | `10000` / `1800` | 与冻结 PLAN 的每类样本数一致；超时是控制器参数 |
| full | `--plan` | 各模块 `PLAN.md` | 真跑必须换成与执行版逐字节一致的 PLAN 副本 |

quick 档不写任何 sysfs 节点、不调用 sudo、不绑核；核与频率管理只出现在 full 档的
控制器调用点。full 档的每条命令形态与模块 PLAN §7 的执行入口一致，例如
[m5-completion-20261016/PLAN.md](evidence/m5-completion-20261016/PLAN.md)（第 235-240 行）
与 [m4-completion-20261016/PLAN.md](evidence/m4-completion-20261016/PLAN.md)（第 330-334 行）。

## 7. 干净 clone 复现记录

在 `/tmp` 下的干净 clone（`git clone` 自本仓库，HEAD 见日志）里跑
`sh scripts/reproduce_all.sh quick --samples 1000 --runs 3`：

- 三个配置的配置、构建、CTest 与演练结果写在
  [r12-innovation-20261016/REPRODUCE-QUICK-LOG.md](evidence/r12-innovation-20261016/REPRODUCE-QUICK-LOG.md)。
- 干净 clone 里缺 `vendor/liboqs-0.10.0/`、`vendor/kyber-kyberslash-*/`、`third_party/`，
  因此 M2 臂不参与演练（脚本打印跳过原因），M1 历史阳性对照不在 quick 档内。
