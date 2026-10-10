# 固定普通参考任务的离线频率窗口复核

这是 `aris-frequency-window-20261010/frequency_workload.c` schema 1 的独立 C11 分析候选，
在真实 G2 数据产生前固定规则。它不连接远端、执行密码负载或控制资源；不修改输入文件，
不根据未来结果调整窗口或阈值。生产者源码、二进制、机器身份、管理恢复和输入摘要须由
父端另行绑定；仅有 JSONL 格式不能证明来源真实。

解析器专用于该生产者的固定字段顺序和按类型分组顺序：contract、两个 device、0—8 个
public_input、snapshot、checkpoint、全部 decap、唯一末尾 summary。正常完成须有八个
公共输入摘要。它只接收 ASCII、无转义字符串、规范十进制整数／uint64 字符串、布尔值和
null；拒绝未知、重复、乱序字段及记录、非规范数字、溢出、截断或缺末换行。行缓冲上限
8192 字节（含结尾 NUL），容器深度上限 8，调用／快照／检查点上限为 250000／512／3907。
没有通用 JSON 树或外部解析依赖。

先读取整个原文件，核对连续索引、两 CPU／E7-E8-E7 身份、摘要格式、全部调用返回和
时钟原值、phase／边界／计数对应、原 elapsed_ns、快照有效标志、调度期限及完整 summary，
再输出。合法的失败记录保留并使诊断不能签收；它们不是待删除的“坏样本”。格式或完整性
拒绝时不输出统计 CSV，stderr 返回失败原因／行号，原文件保持不变。缺失完整 summary、
缺帧或空窗口集合都不能得到 yes。生产者进程安全拒绝的独立短输出不属于完整 schema，
会被明确拒绝，不补成普通任务。

CPU2 是唯一主分析对象；CPU18 逐窗口另列 context_only，不当作第二个独立物理核样本，
也不使用 CPU2 线程时钟替 CPU18 判断活动资格。每对快照的计数为 `(M-, A, M+)`。
在同一计数时期、单调且无回绕／重置的条件下，使用：

`L = M_next_minus - M_previous_plus`，`H = M_next_plus - M_previous_minus`。

仅 L、H 为正且读取与时钟有效时，条件读取对齐区间为
`[4300 * delta_A / H, 4300 * delta_A / L] MHz`。4300 是既有固件 P0／nominal 声明标尺。
这不是置信区间、物理精度证明、瞬时频率或每次短调用的频率界；未假定 TSC 等于 P0。
所有计数下降均记不可计算，不自动模运算消除回绕，也不把固件 U64_MAX 默认当作
“不可能重置”的实测证据。

冻结工程规则：频率带 `[4257, 4343] MHz`；每个端点 CPU2 三读的 RAW 跨度不超过 1 ms；
相邻快照 RAW 最大跨度不超过 40 ms；无漏过的周期期限。80% 是调度活动代理阈值：
分子下界为 `next.thread_cpu_before - previous.thread_cpu_after`，分母上界为
`next.raw_after - previous.raw_before`，并要求分子不大于分母。代理不是精确 C0 比例。
上述条件是事前工程诊断选择，不是 AMD 计量精度标准或正式 C2 的 delta_min。

入带只用 checked uint64 的 `100*delta_A >= 99*H` 和 `100*delta_A <= 101*L`；
带外与跨边界也用整数判定。活动门槛使用 `5*delta_CPU >= 4*delta_RAW`。乘法、减法、
覆盖累计溢出或零分母均不获得资格。CSV 中浮点 MHz 只供显示，不参与边界判断。

主观察起点取 `warmup_to_main.raw_after`，终点取实际末 end 快照的 raw_after；没有 end
快照或其有效 raw_after 时钟就不认证墙钟分母。所有与主阶段相交的实际计数 pair 都分类，首个 straddle 也
参与 `observed_main_windows_all_pass`，不跳过不利边界。`engineering_diagnostic=yes` 只表示
生产者完整、实际主 pair 非空、全部观测 pair 满足工程规则和入带；它不表示整段主过程合格。

纯主阶段覆盖采用各 CPU2 APERF 的 `previous.after -> next.before` 保守保证区间。
首 straddle 的计数平均包含 pre-main 成分，故整对不计入 main-only 频率覆盖。其他区间
须在主观察内且读取括号不重叠。墙钟分母包含全部主观察时间；调用分母包含全部主阶段
调用记录，另列实际执行数。只有完整落在纯保证区间的正常主调用计入覆盖分子。
摘要分别输出几何覆盖、达标覆盖、首边界盲区、尾 frame 盲区及中间读取括号／缺口；
首尾盲区相交时另列相交长度，按并集记账，不重复累计。失败末 frame 仍逐窗分类，
但缺少有效 end 时钟时墙钟分母为 null。全阶段失败台账保留调用、时钟、短读和读取错误数。
不把已知几何盲区补齐为 100%。`full_main_coverage_certified`、物理精度及 R02/R04 签收
始终为 false。

从仓库根目录构建并运行纯软件手算 fixture：

```sh
cmake -S docs/research/aris-frequency-window-analysis-20261010 -B build/frequency-analysis-normal
cmake --build build/frequency-analysis-normal --parallel 4
ctest --test-dir build/frequency-analysis-normal --output-on-failure
```

动态检查另建目录，使用 `-DFREQUENCY_ANALYSIS_SANITIZERS=ON`。自检仅含明确的手算
入带端点、跨边界、带外、L=0、计数下降、整数溢出、时钟／跨度／活动／gap、零 pair、
首 straddle、尾 frame、括号重叠，以及解析截断、重复字段和缺 summary 反例。
fixture 不是 Linux 硬件数据，不用于证明工程目标已经达到。
完整内存 fixture 另独立手填 start、1 秒 boundary、5 秒 end、64 次预热／64 次主调用、
两检查点和全部 schema 记录，走完整解析／完整性／调度／分析链；预期因 4 秒 gap 得到 no。
同一链还核对截断、缺失 summary 及重复末记录的拒绝。
另有完整失败末时钟 fixture：保留最后主 pair、标为不可计算、墙钟分母为 null，不能变成
空集合通过。所有 fixture 都只在 C 内存中构造，不生成伪硬件输入文件。

真实运行接口为 `analyze_windows INPUT.jsonl`。stdout 是逐窗口 CSV，stderr 是单行 JSON
摘要；由父端重定向到明确的新路径并保存退出状态。成功解析和输出返回 0；验证／I/O
失败返回 1；参数错误返回 2。工程诊断 no 也可返回 0，必须读取摘要判断。
必须同时核对退出码、CSV 与摘要完整性。云端所有输入、构建、临时文件和结果仍只能
放在 `/home/nss-marker/yhr/Cry` 内。本模块没有产生真实频率或统计结果。

2026-10-10 本机软件核验：Apple Silicon/macOS、AppleClang 21；普通与 ASan/UBSan 构建
各 CTest 1/1 通过（含完整 schema 链及全部手算反例），clang-format 21 检查通过。
缺失输入文件返回验证失败／退出 1，未输出统计 CSV。未读取或分析真实 G2 数据，未执行
Linux 密码／计数器负载；这些软件检查不是资源资格签收。
