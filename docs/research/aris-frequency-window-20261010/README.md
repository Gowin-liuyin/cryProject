# 普通参考负载的频率原始窗口工具

本模块是下一阶段的独立 C11 候选工具，只链接仓库原有参考 `kernel.c`、`mlkem.c`、
`random.c`、固定 `baseline_config.h` 和 vendor 原件；不创建内核副本或补丁构建。
普通模式仅支持 Linux/x86_64，固定当前线程亲和性为 CPU2，核对结果仅含该 CPU。
外部管理者负责频率请求、物理核分区、生命周期、恢复和文件保存。本模块不写调频或
cgroup 配置，不提供部署流程；本轮不得接入真实长 worker，须先完成父端生命周期审查。

开始前预分配全部记录，打开 CPU2/18 的 MSR 只读设备并核对 root 所有、字符设备、
major 202、minor 对应 CPU、最终组件非符号链接。该核对并不表示只有 root 进程才能运行，
Linux 设备还要求相应权限。生成一个 OS 随机密钥对和八个各用 OS 随机数正常封装的密文，
逐个往返核对。随后固定以 `call_index % 8` 循环这些密文，不声称独立同分布或代表真实密文总体。

预热目标 1 秒，主观察目标 4 秒。每次完整 `mlkem_decapsulate` 的 RAW 前后纳秒值、
通用返回状态和输入索引均保留；输入生成、分配、结果消费及日志不在该调用窗口内。
调用记录上限 250000，快照上限 512，检查点上限 3907。调用数包含预热与主观察；
时钟失败前未真正调用的尝试会保留 `operation_performed=false`，不冒充完成调用。
不删除普通长尾，不因效果不佳追加调用，也不使用 sleep、空转或额外占用 SMT 同胞的负载。

每 64 次调用之后另读 RAW 时钟并保存检查点，按每阶段起点的 20 ms 绝对期限取样；
晚到记录 `missed_deadlines`，不突发补采。开始、预热至主观察边界、结束均取快照，
阶段起点为相应快照的 `raw_after`。跨阶段边界快照标记 `warmup_to_main`，其调用索引
是预热结束和主观察开始的共同边界。实际阶段时长可超过目标，原始时间为准。
6 秒总软预算同样只在 64 调用检查点判断，不中断完整解封装，也不是硬实时截止；
MSR 调用或输出阻塞仍须由外部生命周期协议处理。

每个快照在每 CPU 上紧邻执行 E7/E8/E7，每读各有 RAW 前后括号、精确 uint64、
字节数及立即保存的 errno。两个 CPU 的三读按顺序执行，并不同时发生。
快照另保存当前负载线程 `CLOCK_THREAD_CPUTIME_ID` 前后值；它是调度活动代理，
不换算精确 C0 占比。MSR 读取可能扰动负载或唤醒 CPU18；这些开销和间隔均保留。
工具不关闭中断，不计算频率、计数差分、频率带、物理精度或恒频结论。
读取、时钟、调用或容量失败会停止新负载，保留已经发生的原值；失败快照不伪装有效。
周期采样保留一个终止快照槽。周期或阶段边界快照本身失败时，最后保留该失败快照，
不重试生成额外end；summary明确valid_final_snapshot=false并非零退出。采样阶段无
stdout/stderr、文件日志或外部程序调用。

完成或失败后才向 stdout 输出 JSON Lines：contract、device、public_input、snapshot、
checkpoint、decap、summary。按类型分组输出，组内保持采集顺序；snapshot/checkpoint
中的 `call_records` 可还原与调用流的对应关系。计数和纳秒值均为十进制字符串，失败值
为 null，有效零为 `"0"`；无效 timespec 的原 seconds/nanoseconds 也保留。
同类时钟出现逆序时保留原纳秒值并标记 ERANGE，停止负载，不裁成零或静默继续。
仅输出密文 SHA3-256 摘要，不输出私钥、随机种子、共享秘密或结果消费累积值。
记录缓冲为固定容量，完整输出可能达到数十 MiB，外部保存预算须按上限准备。
这些记录在输出前只在内存中；SIGKILL、崩溃或断电会失去尚未输出的部分，不能由本工具
声称已持久保存。父端恢复成功也不能补出被终止 worker 的原始数据。
退出码 0 仅表示目标阶段、读取与输出合同完成；1 为失败或提前停止，2 为参数／平台
不支持。即使 JSON summary 已输出，仍必须检查进程退出码与文件完整性。
`configuration_writes=0` 仅指本源码无调频／cgroup 配置写入；当前线程亲和性由本程序设置。

本机 macOS/ARM 只允许软件验证，普通入口明确返回 unsupported；它不产生 Linux 数据。
在仓库根目录构建：

```sh
cmake -S docs/research/aris-frequency-window-20261010 -B build/frequency-window-normal
cmake --build build/frequency-window-normal --parallel 4
ctest --test-dir build/frequency-window-normal --output-on-failure
```

独立 CTest 包含纯软件 `--selfcheck`（不读时钟、设备或随机源、不运行密码负载）及
复用现有测试和固定 NIST 向量的 reference KAT、公共参数边界、OS 随机往返。
KAT 单独链接原 `inputs.c` 仅为已有向量解析，不进入普通负载程序。
动态检查另建目录并启用 `-DFREQUENCY_WINDOW_SANITIZERS=ON`；其数据不得混入正式性能数据。
所有远端源码、构建、临时文件和输出必须位于 `/home/nss-marker/yhr/Cry` 内。

2026-10-10 本机候选核验：Apple Silicon/macOS、AppleClang 21，普通与 ASan/UBSan
各 CTest 2/2 通过；clang-format 21 检查通过。普通入口返回 2／unsupported，非法参数
返回 2，向只读 stdout 描述符运行纯 selfcheck 返回 1。未执行密码计时或硬件采集。
本机 Docker 服务未运行，没有完整编译或执行 Linux 普通分支；真实 Linux 编译、软件
检查、产物身份和长 worker 生命周期均仍须另行核验，不能用以上本机结果替代。

4300 MHz 的固件声明和 E7/E8 的静态映射见先前只读复核。本工具不证明当前内核缓存、
每次调用瞬时频率、测时精度或真实统计前提；R02/R04 保持部分签收。
