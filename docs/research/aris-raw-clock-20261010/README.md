# 同路径RAW空窗口校准候选

本模块测量同一线程相邻两次`CLOCK_MONOTONIC_RAW`读取的空窗口，并提供[严格C11离线描述](ANALYSIS_CONTRACT.md)。
collector不链接密码实现，不读取MSR，不写调频、cgroup或其他全局配置。Linux/x86_64
的普通`--collect`入口仅设置自身CPU2亲和性；不要求root，不替其他进程设置亲和性。
macOS仅用于纯软件核验，普通入口明确返回2，不产生Linux采样。

读钟结构与五个helper逐字复用
`docs/research/aris-frequency-window-20261010/frequency_workload.c`的固定G2版本：
提交`c0e5990bd4d764fbb08ff6857a2cf6cf21c9b8a2`，全文件SHA-256
`520bdc1bbcc1bbd805674a39c639e1cbcd13e66ae0b44dba78688115f02ef7f0`。
自有原件归本项目；此处不是第三方上游复制。沿用的对象是`struct clock_reading`及
`timespec_to_nanoseconds`、`clock_span_is_valid`、`check_clock_order`、
`read_clock_timespec`、`convert_clock_reading`；原G2文件保持不变。

`record_empty_pair`对应G2的`record_call`计时顺序：第一次`read_clock_timespec`成功后，
执行两道`atomic_signal_fence(memory_order_seq_cst)`，中间无被测函数，然后第二次读取。
两次纳秒转换和顺序核对都在第二次读取以后，未替换为带转换的两次`read_clock`。
这些是编译器信号栅栏，不是硬件串行化指令。新程序的数据布局、调用上下文及运行环境
仍与G2不同；本结果只能描述该空窗口，不能作为逐调用开销修正、物理误差上界或恒频证明。

一次进程固定保存1000个预热pair及100000个主pair，顺序固定，不提供数量、时长、CPU
或输入选项。采样前预分配101000条记录并触及每页；采样期间不分配、输出、读文件、
查询亲和性或插入额外预算时钟。无sleep、空转、噪声注入或密码调用。元数据读取在采样
前后，记录原亲和性、设置结果、前后亲和性及`getcpu`、RAW的`clock_getres`、当前
clocksource、PID、UID和uname。前后CPU2核对不能证明每个pair均获得CPU执行资源。
前后clocksource/getres变化或元数据失败均使本进程失败，不隐藏已采记录。

第一读失败时立即停止新pair，保留失败尝试，第二读明确标记未尝试；第二读失败、转换
失败或逆序均保留原始timespec及已有纳秒值，然后停止新采样。有效零增量允许。所有
普通长尾保留；只按固定索引区分预热和主阶段，不按观测值重分组。正常完成后或可报告
失败后才输出：stdout为固定15列CSV，stderr为一行JSON元数据。

```text
index,phase,before_attempted,before_has_timespec,before_seconds,before_fractional_ns,before_ns,before_errno,after_attempted,after_has_timespec,after_seconds,after_fractional_ns,after_ns,after_errno,elapsed_ns
```

已知整数为十进制，不套字符串；未知字段为字面`null`。未尝试读取的errno是`null`，
不会伪造为成功的0；成功读取但转换失败仍保留原seconds及fractional_ns。逆序纳秒值
保留并标记ERANGE，elapsed_ns为null。JSON记录计划与实际有效数量、尝试记录数、
停止原因、errno及`partial_unknown`；只有退出0且CSV/JSON完整一致的进程才可作为完整
样本。输出写入、刷新或关闭错误返回1；信号终止可能来不及输出任何元数据。

记录在输出前只存在内存；SIGTERM、SIGKILL、崩溃、断电、截断或输出失败均可能使已发生
pair不可知，必须登记为`partial_unknown`，不能以空文件补记零pair。固定次数不提供
硬实时上界；外部每个进程必须限时10秒并在逾期2秒后强制结束，限时涵盖输出。实际部署
由外部固定协议控制，不能用本模块的固定循环替代生命周期限制。程序退出会销毁自身
线程的亲和性状态，无需修改其他进程或全局配置来恢复。

本机软件资格只通过CMake/CTest执行：

```sh
cmake -S docs/research/aris-raw-clock-20261010 -B build/raw-clock-normal
cmake --build build/raw-clock-normal --parallel 4
ctest --test-dir build/raw-clock-normal --output-on-failure
```

默认RelWithDebInfo采用普通`-O2 -g -DNDEBUG`、严格警告、C11、禁用LTO并导出
`compile_commands.json`；两个目标均不链接密码实现。动态核验使用新目录及
`-DRAW_CLOCK_SANITIZERS=ON`，其测量不得用于正式校准。macOS的ASan核验由执行环境设置
`ASAN_OPTIONS=detect_leaks=0`，源码不覆盖环境。纯`--selfcheck`仅检验手算fixture：负
timespec、纳秒边界、uint64溢出、有效零、逆序/缺失、CSV原值及未尝试状态、容量/阶段
边界、JSON转义和短缓冲区；不调用实际clock、文件、亲和性或密码函数。第二项CTest核对分析器的严格解析、分位/MAD及整数守恒手算夹具。

显式指定clang-format 21路径后可运行本模块`format-check`目标。实际Linux预检、正式
采集、产物摘要、编译命令和反汇编仍由外部证据记录确认，本README不声称已经执行。
云端源码、构建、临时目录、缓存、CSV、JSON及其他项目文件全部只能位于
`/home/nss-marker/yhr/Cry`及其物理子目录，不通过符号链接越界；不新建`/tmp`或`/run`
项目文件。每次进程与每轮证据使用新目录，原G2证据和封存包不改写。
