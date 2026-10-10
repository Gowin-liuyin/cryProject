# RAW空窗离线描述合同

本工具只描述固定采集器导出的读钟序列，不估计密码实现差异，不执行真实读钟、调频、隔离或远端操作。入口为 `analyze_raw_clock <input.csv>`，或只运行内存手算夹具的 `analyze_raw_clock --selfcheck`；没有参数化样本量、统计阈值或自动选模型入口。

## 输入与拒绝规则

输入文件以只读方式打开，首行须逐字等于下列字段，且每行均以LF结束。只接受无引号、无空白、无额外字段的15字段CSV。输入行缓冲上限1024字节，含自动终止NUL；嵌入NUL、缺LF、超长行、CRLF、读取或关闭失败均拒绝。纯数字字段为无符号十进制，允许前导零，不接受符号、指数或空白。

```text
index,phase,before_attempted,before_has_timespec,before_seconds,before_fractional_ns,before_ns,before_errno,after_attempted,after_has_timespec,after_seconds,after_fractional_ns,after_ns,after_errno,elapsed_ns
```

恰须101000条记录，`index`逐条为0—100999；前1000条`phase=warmup`，后100000条`phase=main`。读到不足、额外记录或尾部空行均拒绝。两个读钟都必须为`attempted=1`、`has_timespec=1`和`errno=0`。因此采集器表示未知的字面量`null`及未尝试、无效、失败的时钟均拒绝，不删除失败记录再给成功部分计算摘要。

每次成功读钟要求秒数非负、纳秒余数在0—999999999内，`seconds×1000000000+fractional_ns`不溢出`uint64_t`，且逐字数字解析后的值等于相应`ns`。每对要求`after_ns≥before_ns`，`elapsed_ns=after_ns−before_ns`；每条`before_ns≥前一条after_ns`，包括warmup/main边界。相等是有效观察，零增量保留。

输入校验、统计和完整输出格式化在发布前完成。上述拒绝时stdout为空，stderr尽力输出一行`status=unknown`的JSON并退出1；未知摘要不包含幸存统计。输出写入或刷新失败同样不能记作成功，此时已写出的stdout可能不完整，stderr自身故障也无法保证错误行落盘。默认SIGPIPE可由操作系统终止进程，不声称它一定退出1；外部运行管理必须把非正常退出、非零退出和输出不完整都记为未知。

## 六行描述统计

stdout首行固定为：

```text
phase,series,count,zero_count,sum_ns,min_ns,min_positive_ns,p50_ns,p90_ns,p99_ns,max_ns,mad_ns
```

随后依次输出warmup三行、main三行，每阶段有以下序列。设阶段内第j对为`(B_j,A_j)`，阶段内有N对：

| series | 原始顺序定义 | count |
|---|---|---:|
| `within_pair_ns` | `A_j−B_j`，j=0…N−1 | N |
| `between_pairs_ns` | `B_j−A_(j−1)`，j=1…N−1 | N−1 |
| `combined_ordered_read_increment_ns` | `A_0−B_0, B_1−A_0, A_1−B_1, …, A_(N−1)−B_(N−1)` | 2N−1 |

三者分别保留全部增量，不删零值、长尾或其记录；第三行与前两行共享同一原始序列，不能视为新增样本或独立重复。warmup计数为1000、999、1999，main为100000、99999、199999。所有时间与和均为整数纳秒，`sum_ns`逐项检查`uint64_t`溢出。`min_positive_ns`是本次序列中观察到的最小严格正值，没有正值时写`null`，不以0替代，也不称时钟分辨率或精度。

对升序数组`x[0…n−1]`，百分位P取索引`floor(P×(n−1)/100+1/2)`，实现为`((n−1)×P+50)/100`的整数除法。P50在偶数样本时为上中位数，MAD为围绕该上中位数的绝对偏差之上中位数，不作正态缩放。P90、P99同样按此固定索引，不插值、不用浮点。

每阶段另核对整数守恒：`last_after_ns−first_before_ns=within_pair_sum_ns+between_pair_sum_ns=combined_increment_sum_ns`。`phase_boundary_gap_ns=首main before_ns−末warmup after_ns`只单独进入stderr，不放进任一阶段内部的between或combined序列，并核对`总墙钟=warmup墙钟+阶段边界间隔+main墙钟`。

## 成功回执与适用边界

成功退出0时stderr恰为一行JSON，`schema=raw-clock-analysis-v1`、`status=descriptive_only`，包含固定记录数、两阶段墙钟与内外和、单独的阶段边界间隔，以及两项整数守恒结果。其声明始终为`clock_precision_certified=false`、`iid_claimed=false`、`collector_stderr_checked=false`、`collector_exit_checked=false`、`complete_metadata_acceptance=false`、`r02_signed_off=false`、`r04_signed_off=false`。

本程序没有读取或验证采集器stderr、完成状态或退出码，也不校验CPU、亲和性、clocksource、分辨率回读、机器身份和普通/动态构建身份。完整运行验收必须由运行管理另行绑定这些原件与本输入摘要。完整CSV通过只能证明所见读钟记录满足本合同；不能反推出采集器正常结束、实际CPU路径相同、物理频率恒定、时钟误差界、目标量级测量精度或独立同分布前提。它不扣除空窗，不给出p值、误报率、检出率或因果分摊。

## 空间与内存自检

预分配101000条紧凑时钟对，另有两个各199999项的`uint64_t`数组；只重用这两个数组计算六行。排序为原地堆排序，不额外复制、不依赖排序库的临时堆分配。三数组合计4815984字节，含固定输出、行缓冲和结果结构的显式工作空间在源码中以静态断言限定为小于16MiB。此为程序显式工作存储边界，不声称完整进程RSS或C运行库占用有该上限。

`--selfcheck`不打开文件、不读取真实时钟，也不产生CSV；只对内存常量检查奇偶样本、零值、无正值、上中位数/MAD、百分位索引、整数边界和溢出、20条短CSV有效/无效记录、前后读钟非降、LF与嵌入NUL，以及两阶段内部和边界守恒。手算几何夹具为`(10,12),(12,15) | (20,20),(21,25),(30,31)`：两个阶段墙钟分别5与11ns，内部对和均5ns，阶段内间隔和分别0与6ns，单独阶段边界5ns，总跨度21ns；这些数字仅为软件夹具。

本合同及自检不冒充真实硬件校准结果或完整验收记录。正式构建、CTest、自检执行、输入摘要与运行状态由集成方另行记录。
