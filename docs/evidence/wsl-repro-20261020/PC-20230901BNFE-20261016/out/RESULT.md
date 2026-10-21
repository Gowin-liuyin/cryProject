# WSL2 跨环境复现结果（队友机器）

- 执行人 / 日期：2026-10-16（豆包助手代跑，本机 WSL2 自动化复现）
- 仓库提交：本地快照 HEAD a9f23fce（内容树 = 上游提交 04baad45 的 tarball 快照，Q1 兜底；见第 3 节）
- 环境一句话：Windows 10 Pro (19045.6456) / WSL2 内核 5.15.167.4 / Ubuntu 20.04.6 LTS / Intel Xeon E5-2676 v3 @ 2.40GHz（12 核 24 线程，X99 平台）/ clang 18.1.8 / 电源模式高性能 / 台式机插电
- 频率管理：**未锁频**（WSL2 无 cpufreq 接口），绑核 taskset -c 23（vCPU，非物理核）

## 1. 正确性
| 构建 | CTest 通过/总数 | 备注 |
|---|---|---|
| 平台 | 90 / 90 | KAT 全过 |
| M1 unfixed（-Os） | 61 / 61 | 全过 |
| M1 fixed（-Os） | 61 / 61 | 全过 |

## 2. 采集与统计（摘自 stats/SUMMARY.md）
| 项 | 结果 | 与裸金属（nss-marker）方向是否一致 | 备注 |
|---|---|---|---|
| P0 M1 -Os 未修 | 计时合并 Δ=+67.8ns [-59.4, +195.0]（z=1.04，不显著）；Memcheck 512 错误/1 context；dudect max t=+8.79（未过阈值） | 一致 | Memcheck 1 context 与 nss-marker 相同；WSL 计时噪声大，计时未检出属预期，以确定性证据为准 |
| P0 M1 -Os 已修 | Memcheck 0/0；dudect max t=+1.87；计时合并 Δ=-114.6ns [-240.9, +11.7]（不显著） | 一致 | 与裸金属修复效果一致 |
| P0 M5 | 五个 -O 级别合并 Δ 的 95% CI 全部含 0（O0 -183[-500,133]，O2 -21[-103,61]，O2default +9.6[-73,92]，O3 +23.8[-58,105]，Os +61[-32,154]）；dudect max t=+3.68 | 一致（阴性对照干净） | 未见假阳性 |
| P1 四级反汇编/Memcheck | 未修：O0 0/0、O2 512/8、O3 512/15、Os 512/1；已修：四级全部 0/0；反汇编：未修 Os = bt+jae、已修 Os = setb+cmov_call（bt 共存）；未修 O2 cond_jumps=9 / O3=16，已修 O2/O3 cmov_call=8、cond_jumps=1 | 一致 | 与 nss-marker 逐项一致（1/8/15 context） |
| P1 四级计时 | 未修/已修各四级合并 Δ 的 95% CI 全部含 0（噪声主导） | — | 不锁频虚拟化，计时未检出属预期 |
| P1 性能 | M1 decaps：已修较未修快 1.42%（bootstrap 95% CI [1.28%, 1.57%]） | 方向一致 | 裸金属 Debian13 约 7%，本机 1.4%（不锁频，幅度不同） |
| P2 M4 vulnerable / ct（人工构造校准） | vulnerable Δ=-22.37ns [-23.57, -21.17]（z=-36.60，9/9 同号），dudect max t=+929.91（检出泄漏）；ct Δ=-0.70ns [-1.72, +0.32]（z=-1.35，不显著），dudect max t=+1.11 | 一致 | 校准有效：已知漏洞可检出、已知安全不可检出 |
| P2 M2 | fixed Δ=+279.20ns [141.76, 416.64]（z=3.98，9/9 同号）；unfixed Δ=-51.08ns [-194.40, 92.25]（z=-0.70，不显著） | 结果如实记录，待分析角色解读 | 平台 measure 臂输入为有效密文（非 KyberSlash 原始无效密文场景），且为不锁频虚拟化环境 |

## 3. 未完成项与错误（如实；照抄 ERRORS.tsv 并说明）
ERRORS.tsv 共 2 条历史错误，均为正式全量第一次启动时 git clone 网络中断（GnuTLS TLS 传输被重置，瞬时网络问题；同仓库在 QUICK 阶段曾克隆成功）：

1. 2026-10-16T13:30:19 —— git clone https://github.com/Gowin-liuyin/cryProject.git 失败（RPC failed; curl 56 GnuTLS recv error）
2. 2026-10-16T13:38:33 —— 重试 clone 再次超时（HTTP/1.1 亦无效）

处理（文档 Q1 兜底路径）：改用 codeload tarball 下载上游提交 04baad45… 的归档（592MB，下载成功），解压后 git init 建本地快照（HEAD a9f23fce），并让 fetch 阶段在无该提交对象时以快照内容为准。此后全流程零新增错误（检查 p0m1/p0m5/p1opt/p1perf/p2m4/p2m2/verify 全部 stamp 完成，退出码 0）。

环境适配（Ubuntu 20.04 无官方 clang-18/cmake preset，属文档 Q2/Q9 授权范围）：
- clang-18.1.8 经 apt.llvm.org 安装；cmake 4.4.4 经 pip 安装（focal 自带 3.16 不支持 --preset）；
- memcheck / dudect 链接增加 -lpthread（glibc 2.31 需显式链接 libpthread）；
- verify 检查适配现代 CTest 汇总行格式（"100% tests passed out of N" 不含 "0 tests failed" 子串）。

## 4. 口径声明
不锁频虚拟化环境下的结果只作跨环境描述，不进任何 Holm 家族；未检出不等于常数时间；不与裸金属数据合并。
