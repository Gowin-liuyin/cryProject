# G2 生命周期与固定产物的独立准备复核

2026-10-10。结论：下述固定管理源码的生命周期、恢复边界及既有软件证据通过限定准备复核，没有尚未解决的阻断项。可以继续冻结来源、完成父端独立检查及真实 Linux 管理自检；这不表示 G2 已运行或窗口结果已经合格。

本复核由本地独立代理完成。只读取当前源码、原始软件日志、已取回 ELF、反汇编及只读预检收据，并在本机内存中解析、重算和编译源码语法；没有 SSH、运行 ELF、重跑软件测试、采集密码时间或写内核。没有修改已封存 linux-c0e5990 证据，不冒称外部 Codex MCP 或跨模型审查。

## 固定对象与运行门槛

管理源为 `rehearse_partition.py`，SHA-256 `8616a0747d7a8e3b28e5af6da86bfdee5b2bf2f84821989c163136ec09479af4`，UTF-8 共 99770 字节。直接重算冻结 controller 的 Python `-c` 参数为 104481 字节（含 NUL），低于本源码的 Linux 单参数门槛；源码也检查 UTF-8 字节数，并有超长 Unicode 负例。内存语法编译通过，未执行其入口。

普通 worker 固定为 c0e5990 的 `Cry/window-source-c0e5990/build-normal/frequency_workload`，225384 字节，SHA-256 `023f56460a8dc4971e8132a22c5734ca0844314d3d71b8bc3b129a424e9ee69b`。该 Linux 原件的 618 成员、617 清单载荷、138 Git blob、编译链接选项、四 ELF 及两套 3/3 原测试已独立核查，见已封存的 linux-c0e5990/ARTIFACT_REVIEW.md。新管理源的路径和摘要确实使用此普通产物，没有沿用旧 7e 候选或 ASan 产物。

已直接核读 root-precheck-source.py 及实际工具返回字段。完成返回退出 0，记录 euid=0、初始 user/mnt/pid namespace 与 init 相同、有效 CAP_SYS_PTRACE、两 MSR 设备为 root 所有的 202:2/18 字符设备、0600、根 CPU0—31、隔离空、Cry 可用 375096610816 字节。该源只读取属性和设备元数据，记录 configuration_writes=0、msr_read_performed=false。它是一次准入时点收据，不代替实际 run-window 内再次检查基线，也没有通过读取 MSR 获得窗口数据。

## 生命周期与恢复边界

同一 guard 仍是频率与 cgroup 的唯一写者，沿用同一管理锁、root 私有 Store、冻结源码、独立 session/housekeeping 分区。root 保护副本的准备早于任何 cgroup/频率写入：源 FD 物理路径、身份、稳定尺寸/时间和固定摘要核对后复制为 root 私有 0500 ELF，再用 FD exec；没有接受任意命令接口。

worker 出生后先在 gate 阻塞，核对 probe 归属、CPU2 亲和性和 PID/ticks。observer 在 W 前打开并核对 worker pidfd；W 后 guard 核对 `/proc/PID/exe` 的实际 inode/device/path，并再次 waitpid 未退出，才保存 running。running 文件本身没有被当作持续存活证明。

normal 等待实际 waitpid 回收和输出处理形成 worker-exit，再由 observer 发 R。parent-loss 在放行至少 0.25 秒后再次核对 pidfd、启动 ticks、cgroup、CPU2 亲和性及执行对象，再只杀自己的 controller。guard 收到 EOF 仍重新 WNOHANG 检查 child 存活；签收此取消路径还要求已观察执行、满足注册年龄、实际 SIGKILL 退出并回收。自然退出竞态不签收、不补跑。两路径结束后 observer 都另行确认原 worker pidfd 已退出，并关联 terminal 的同一 PID/reaped；不会仅凭恢复文件断言 child 已终止。

常见放行、归属、监测、输出与收据异常均进入统一 child 清理，先关闭 gate、kill/waitpid 自己的 child，再允许频率与分区恢复。未回收 child、未知 cgroup 成员或身份不符时拒绝完整恢复签收。measurement_complete、restoration_visible、evidence_complete 分开；取消、期限、部分输出及恢复证据缺失不被登记为完整测量。

child 的单输出文件限制为 120 MiB，case 为 256 MiB；只在 child 设置 CORE=0、FSIZE 限制和忽略 SIGXFSZ。输出至 Cry 内独占创建的 root 文件。child 放行后至多 12 秒、guard 运行 20 秒及独立 6 秒恢复均为软预算，不承诺内核阻塞下硬实时终止。缺盘不能跳过 child 回收。

ENOSPC/EDQUOT 例外只在原值恢复时使用，且必须有首写前保存的恢复 plan；精确核对 core-window case 路径、profile、baseline 摘要、四个原值及当前身份/global/事务已知状态。apply、EACCES/EIO、错误 plan、未知状态均不能使用该例外。日志未分配、已发布后报错和 visible 收据缺盘分别处理，原值确认后在内存清理 pending 并继续其他恢复；任何此类缺证据均令 evidence_complete=false，不假签完整成功。manual 的缺失 intent 恢复只扩展可由已记录状态投影得到的原值恢复状态，不放开任意值。旧 run/run-frequency 无该 plan，保留原有日志与拒绝规则。

## 软件检查证据

直接核读实现者最新 CMake/CTest 的 LastTest 原日志，1/1 通过、1.52 秒，包含旧管理回归及新的良性 gated child 路径。源码中的新检查实际 fork 并 kill/reap 良性替身，涵盖 normal、早 EOF、注册 EOF、R、期限、退出失败、收据失败及输出超限，没有运行密码算法或读 MSR。

特意补核注册 EOF 正例：monitor 读取本次真实保存的放行 monotonic 值，在至少 0.26 秒后关闭 writer，断言 EOF、cancel_while_running=true、registered_cancel=true、实际 −9 和已回收；早 EOF 则断言 registered_cancel=false。恢复模拟还覆盖不可见但已接受的目标请求、取消失败不得发布恢复收据、dirty/visible/部分发布 ENOSPC、缺失 intent 重建，以及 EACCES/EIO/apply 不得 fallback。父端独立 CMake 与真实 Linux 管理自检仍属于后续门槛，未由这份本机原日志冒称完成。

## 指定 ELF 的静态边界抽核

直接读取本目录两份原 objdump 文本，并从封存普通 ELF 解析 PT_LOAD 映射，独立核对 11 处实际指令字节。SET_DUMPABLE 的 operation=4 位于 0x132a、调用在 0x132f；GET_DUMPABLE 的 operation=3 位于 0x13aa、调用在 0x13b1。普通成功分支 0x13cf 才跳至 run_workload 的 0x1e90，三个 calloc 在 0x1f41/0x1f6d/0x1f8d。错误分支不进入负载。

采集循环保留 RAW clock_gettime 0x2d9e → 完整 mlkem_decapsulate 0x2e01 → RAW clock_gettime 0x2e1a；输入准备的另一解封装为 0x2c2b，未混作逐次采集。两条反汇编工具返回 0，随后远端摘要回读仍为同一 023f… 普通 ELF。该抽核支持指定产物的入口与调用边界，不是编译器正确性、恒时或动态计量精度证明。

SET/GET 在 exec 后的 C 入口实施，保护从设置成功起生效；exec 会重置 dumpable，故单在 preexec 设置不够，进入 C 前的加载器仍在边界外。相关系统语义见 [execve](https://man7.org/linux/man-pages/man2/execve.2.html) 和 [PR_SET_DUMPABLE](https://man7.org/linux/man-pages/man2/PR_SET_DUMPABLE.2const.html)。当前 root 预检排除了明显缺少 ptrace capability 的情况；运行时若 `/proc/exe` 核验被拒绝，源码仍取消并清理，没有弱化身份门槛。

## 本次通过的范围

通过的是固定源码与软件原件的准备资格、生命周期设计及受约束的恢复路径。尚未签收真实 normal 五秒负载、实际活进程 parent-loss、频率窗口分类或任何正式统计结论；完整 producer 协议与分析器的独立手工 fixture 也由其对应审查承担。只在其余运行前门槛完成后按冻结合同各执行一次，保留负结果和部分输出；G2 未由准备复核冒称完成，R02/R04 仍不升级。
