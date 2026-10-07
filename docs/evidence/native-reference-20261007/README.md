# 原生 x86_64 Linux 参考验收

实际固定源码9d9554b6f977e0b1afd9ff7a9ae6c8a0083c0c24，由本机main的完整bundle传送，
独立源码检出及新构建目录；无GitHub最新内容假设。先前76e6c1b配对准备及7090dc9普通验收
失败另存，未覆盖其内容。这里不是批次重试、开发或确认数据。

Ubuntu24.04.4、Linux6.8.0-138/x86_64、GCC13.3.0、CMake3.28.3、
RelWithDebInfo/-O2 -g -DNDEBUG/C11/无LTO/非sanitizer。
KVM全虚拟化，实例实际4vCPU，CPU型号字符串AMD EPYC 9K65 192-Core Processor；
不是裸金属或192个可用核心。ELF工具链、CPUID/lscpu、KVM检测及实际执行共同支持原生身份，
没有QEMU用户态仿真调用。物理宿主型号、频率与调度不能从来宾独立核实。

外部taskset -c 2绑定CPU2，environment.log的Cpus_allowed_list=2；子进程继承。
meta内not_pinned表示采集程序没有自己调用亲和性API，不能覆盖外部控制记录。
guest频率控制未开放，宿主频率/后台负载不受控；项目安装、编译、动态检查及正式测量串行。

普通及独立ASan/UBSan各执行reference标签5项加release/sanitize-test中的9项，共14个不同
CTest：reference_kat、reference_random_failure、reference_cli、reference_vector_parser、
vector_integrity、reference_benchmark、timing_diagnostics、batch_measurement、paired_statistics、
paired_data、paired_rejections、paired_runner、paired_prepare、native_digest，全部通过。
registered-tests.json仅列29项注册，不是29项全执行；不运行主动机制计时集成测试。

三类valid/bit-flipped/random各1000、固定1:1:1；种子20261006/07/08是输入编号，
全部在2026-10-07采集，每次100预热。3次×3000条=9000条原始记录；每步退出0、meta完成。
CLOCK_MONOTONIC、纳秒单位、clock_getres=1ns，观察最小正读钟增量19ns；不等于1ns精度。
10000读钟增量和1000空窗原值每次完整保留，不扣开销、不删长尾、不平滑。

| 输入种子 | 混合均值ns | P50ns | P90ns | P99ns |
|---|---:|---:|---:|---:|
| 20261006 | 47075.037000 | 46818 | 46999 | 52108 |
| 20261007 | 46237.526000 | 45980 | 46129 | 51449 |
| 20261008 | 46121.980667 | 45879 | 46039 | 51060 |

类别表、最大值及原序描述见三份summary；分位数是floor(p*(n-1)+0.5)零基下标。
三次运行范围是描述不确定性；尚无原生防护前后受控区间，不和macOS时间合并。
实际benchmark SHA3-256为705b89cfd38d4c8cdf94c0b9edbda8cb5daf38c9e43902003b72b28d2127f9ce，
三份meta均与独立OpenSSL吻合。完整编译命令、源身份和正式反汇编另存。

disassembly.log实际路径核验：0x3f81起点读钟，0x3fa9完整mlkem_decapsulate，0x3fb7终点读钟，
0x400c保存记录，0x4017–0x4026消费输出；包装层0x95f4到真实内核0x8570。
这些地址仅属于本目录摘要产物。动态检查二进制不用于表中时间或产物结论。
源码层窗口与该实际产物一致，不由普通类别差异推导秘密泄露或全库恒时。

original-run.SHA256SUMS保留目标绝对路径的原清单字节；本地SHA256SUMS另绑定复制后的文件。
binaries.sha256也是原目标路径产物身份，二进制与构建缓存留在目标，不复制进Git。
从固定源码重建是另一项操作，不要求重建文件摘要必然相同。
