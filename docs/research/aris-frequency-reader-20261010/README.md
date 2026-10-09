# 只读 MSR 计数快照

本模块只发现硬件计数读取能力，不控制频率、执行负载或签收 R02。实际读取入口只支持
Linux/x86_64；macOS/ARM 可编译和运行软件自检，普通入口明确拒绝。

程序固定读取 Linux CPU2 和 CPU18。设备以 `O_RDONLY | O_CLOEXEC | O_NOFOLLOW` 打开，
核对 `fstat` 为 root 所有的 MSR 字符设备（major 202，minor 对应目标 CPU）。每个 CPU
依次执行三次独立的八字节 `pread`：MPERF（0xE7）、APERF（0xE8）、MPERF（0xE7）。
每次读取前后各保存一次 `CLOCK_MONOTONIC_RAW` 纳秒值，保留读取错误和短读长度。
设备打开或身份检查失败时，该 CPU 的读取数组为空，错误状态明确输出。

stdout 是一个 JSON 对象。计数及纳秒数以十进制字符串保存，避免消费端丢失 uint64 精度；
失败值为 `null`，有效的零值为 `"0"`。读取错误和时钟错误分别记录。退出码 0 只表示六次
读取及时间记录成功，1 表示读取、设备、时钟或输出失败，2 表示参数或平台不支持。
`configuration_writes=0` 是源码行为声明，不是动态写入监视器。

三次读取不是原子计数对，两个 CPU 也不同时读取；读取本身有开销。单次累计快照不提供
活动区间、计数差分、频率换算、时钟精度、恒频或统计资格结论。CPU2/18 是同一物理核的
SMT 同胞，不能当作两个独立物理频率样本。源代码不调用等待、配置写入或外部程序。
当前能力快照的三次读取之间包含 JSON 输出，stdout 还可能阻塞；不得把它当作低偏斜的
紧邻硬件三连读或正式频率采样器。设备权限由 Linux 的 CAP_SYS_RAWIO 等检查决定。

在仓库根目录使用独立 CMake/CTest 构建，自检不创建文件，也不打开硬件设备：

```sh
cmake -S docs/research/aris-frequency-reader-20261010 -B build/frequency-reader-check
cmake --build build/frequency-reader-check
ctest --test-dir build/frequency-reader-check --output-on-failure
```

动态检查使用新的构建目录和 `-DMSR_READER_SANITIZERS=ON`。自检覆盖成功的最大值与零值、
0—7 字节短读、真实无效描述符的错误保存，以及纳秒转换的非法输入和 uint64 边界。
远端源码、构建、临时文件及原件均须位于 `/home/nss-marker/yhr/Cry`；本模块不提供部署或
远端执行流程。实机执行、来源冻结和原件归档由主线程另行处理。

设备编号和读取粒度依据 Linux v6.17 的
[MSR 设备实现](https://raw.githubusercontent.com/torvalds/linux/v6.17/arch/x86/kernel/msr.c)及
[major 编号](https://raw.githubusercontent.com/torvalds/linux/v6.17/include/uapi/linux/major.h)。
