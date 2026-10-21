# WSL2 跨环境复现结果（队友机器）

- 执行人：豆包 AI 复现执行员（陈凯峰机器）/ 日期：2026-10-16
- 仓库提交：`04baad45ebb5ea4dba8d143d64c5031c906503d2`（origin/main，与文档基线一致）
- 环境一句话：Windows 10.0.26200.9457 / WSL2 内核 6.18.33.2-microsoft-standard-WSL2 / Ubuntu 26.04 LTS / Intel Core(TM) 5 320（6 核 6 线程，名义 1500 MHz）/ clang 18.1.8 / 电源接电（BatteryStatus=2）/ 采集期间电脑未跑其他大程序
- 频率管理：**未锁频**（WSL2 无 cpufreq 接口，`/sys/.../cpufreq` 不存在），绑核 `taskset -c 5`（vCPU，非物理核）；计时源 `tsc`，CLOCK_MONOTONIC

## 1. 正确性

| 构建 | CTest 通过/总数 | 备注 |
|---|---|---|
| 平台（M2–M5 + 统计工具 + KAT） | 88/88，0 failed | 已取 M2 vendor 与 dudect |
| M1 未修 `-Os` | 61/61，0 failed | |
| M1 已修 `-Os` | 61/61，0 failed | |

## 2. 采集与统计（摘自 stats/SUMMARY.md；SAMPLES=20000/类，SEEDS=31337/424242/7，REPEATS=3，逆方差固定效应合并）

| 项 | 结果 | 与裸金属（nss-marker）方向是否一致 | 备注 |
|---|---|---|---|
| P0 M1 `-Os` 未修 | 合并 Δ=+140.4 ns [−696.8, +977.6]，z=0.33，同号 +6/−3；dudect 最后 max t=+10.25（state=0） | 符号随构建变化（文档 9.3：r09 重建为负、冻结 ELF 为正），本 WSL 合并 Δ≈0、CI 含 0，**不比较符号** | 确定性证据（下）才是跨环境主结论 |
| P0 M1 `-Os` 已修（982c762） | 合并 Δ=−165.9 ns [−1332.6, +1000.8]，z=−0.28；dudect max t=+1.84 | CI 含 0，无证据 | 与预期一致：修复后无泄漏 |
| P0 M5（阴性对照，-O2 默认） | 合并 Δ=−199.2 ns [−816.8, +418.4]，z=−0.63；dudect max t=+2.43 | 各级合并 CI 均含 0 | 阴性对照成立 |
| P1 四级反汇编/Memcheck（确定性） | 未修 `-Os`：bt=1 jae=1 setb=0 cmov_call=0，Memcheck 512 errors / **1 context**；已修 `-Os`：bt=1 setb=1 cmov_call=1，Memcheck **0/0**；未修 `-O2`=**8 contexts**、`-O3`=**15 contexts**；`-O0` 两版均 0/0；已修 `-O2/-O3` 均 0/0 | **与 nss-marker 逐项一致**（文档 9.4：未修 -Os 为 bt+jae、已修为 bt+setb+call cmov_int16；O2=8、O3=15、O0=0） | 这是 WSL 上最有价值的跨环境证据 |
| P1 四级计时 | M1 两版 × O0/O2/O3/Os 合并 Δ 全部 CI 含 0（|z|≤1.42）；M5 各级同样含 0 | 不比较符号；WSL 单次 SE 约数百 ns，噪声底限掩盖了裸金属 25–40 ns 的效应 | 文档 9.2 预期内：未检出 ≠ 安全 |
| P1 性能 | decaps：未修均值 57636 ns，已修 57488 ns；防护开销均值 −0.258%（bootstrap 95% CI [−1.834%, +1.287%]） | 不解读为"修复带来加速"（文档 9.7） | 不锁频 + 二进制布局差异所致 |
| P2 M4 vulnerable / ct（**人工构造校准**） | vulnerable：合并 Δ=−7.13 ns [−7.19, −7.07]，z=−236，dudect max t=+609.47（online_leakage_found）；ct：合并 Δ=0.00 ns [−0.02, +0.02]，dudect max t=+1.47（no_evidence_yet） | 方向与裸金属一致：vulnerable 臂提前退出更快（负），ct 臂为 0 | 证明采数管线在有真实效应时能检出；M4 仅作校准 |
| P2 M2 KyberSlash | 未修合并 Δ=−129.6 ns [−797.3, +538.1]，已修 −126.0 [−804.0, +552.0]，均 CI 含 0 | WSL 噪声下不可区分 | |

## 3. 未完成项与错误（照抄 ERRORS.tsv 并说明）

`out/ERRORS.tsv` **不存在**（全程 0 错误）。

执行环境备注（不影响结果，按文档要求记录）：
1. 发行版为 **Ubuntu 26.04 LTS**（非文档推荐的 24.04）；apt 源自带 `clang-18=18.1.8`，无需 llvm.sh。
2. WSL 默认无法直连 github.com（连接超时）。经 Windows 侧 Clash（127.0.0.1:7897）做 `netsh portproxy 0.0.0.0:17897 → 127.0.0.1:7897` 并加防火墙入站规则后，WSL 以 `http://<宿主网关>:17897` 作为 HTTP(S) 代理完成所有 git/curl 取件。
3. 修复脚本一处阻塞 bug：原 `grep -m1 clock_resolution_ns "$OUT"/raw/*.meta` 在尚无 .meta 文件时因 nullglob 展开为空，grep 读 stdin 永久阻塞。已在该行加 `</dev/null`（仅在 WSL 家目录副本 `~/wsl_repro.sh`，未改仓库源码、未改随发脚本本体）。
4. 未安装 R/tidyverse（RTLF 统计电池按文档默认不可用，不推断结果）。
5. `.wslconfig` 未定制（默认 6 vCPU / 7.4 GB，实测 `nproc=6`）。

## 4. 口径声明
不锁频虚拟化环境下的结果只作跨环境描述，不进任何 Holm 家族；未检出不等于常数时间；不与裸金属数据合并。M1–M5 判定以主报告（nss-marker 锁频数据）为准。
