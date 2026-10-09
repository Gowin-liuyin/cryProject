# 单核频率请求、恢复与后续窗口验证

2026-10-10，采用ARIS的主张—原件—独立复核流程。本计划是R02的资源准备与运行合同，正式统计仍受[下一验证协议](../aris-replication-20261009/NEXT_VALIDATION_PROTOCOL.md)约束；不改写已有报告、匿名包和已封存证据。

## 主张与最小证据

| 编号 | 本阶段主张 | 最低证据与限制 |
|---|---|---|
| G1 频率请求可控且可见恢复 | 同一guard、同一锁，仅向policy2/18四个min/max字段请求4300000kHz，正常及controller单进程SIGKILL两路径恢复基线可见配置 | 全32策略/全局原快照、目录身份、每次写前intent与回读、实际空任务归属/回收、guard pidfd终止和独立结束回读；不是硬件恒频或隐藏QoS状态完全恢复 |
| G2 普通负载中的窗口观测可审计 | 下一阶段在未修改reference良性工作负载中记录缓冲的E7/E8/E7、逐次时间、调度活动代理及工程诊断分类 | 先另审长worker的取消/EOF/回收协议；本轮前置G1仍只运行true，不以它替代有负载的G2 |

已完成的[静态映射与六读](../aris-frequency-reader-20261010/RESULTS.md)提供CPU2/18→C004/C005、固定64位E7/E8及4300MHz声明的来源。当前重新只读预检显示32个singleton策略，目标min/max为2982259/5756452kHz，active/powersave/EPP balance_performance/boost1，根CPU0—31可用且隔离集合为空；实际root运行仍须重新验证，旧成功记录不作为当前准入。

4300000kHz选择为固件nominal及首个_PSS频率声明，位于原范围内。上游v6.17的 `freq_to_perf` 计算 `ceil(freq × nominal_perf / nominal_freq)` 并夹限，因而本值对应124；不使用231或166替代参考性能。此为[指定版本驱动语义](https://raw.githubusercontent.com/torvalds/linux/v6.17/drivers/cpufreq/amd-pstate.c)，未逐行核对Ubuntu补丁，也不声称请求成功等于物理Hz已校准。

## G1的固定顺序

1. 复用既有单文件冻结执行源、root私有Store、`partition-admin.lock`、host namespace检查、独立guard session/housekeeping cgroup与observer pidfd。既有 `run` 仍只操作cgroup；新 `run-frequency` 另建 `Cry/core-frequency-20261010-<nonce>`，不重用旧根。
2. 在任何频率写入前，原子保存32策略的稳定控制字段、global模式/boost/prefcore、目标实际policy映射及身份。只允许policy2/18的 `scaling_min_freq` 与 `scaling_max_freq`；不写global boost、governor、EPP、SMT、IRQ、驱动模式或其他30策略。
3. guard取得local isolated分区2/18后，分别按min=4300000、max=4300000请求，逐步有界回读。每次写尝试前先持久化dirty intent；部分成功、超时或写异常均进入恢复。完整等值回读后才能放行唯一空任务true；active仅表示可见请求与空任务通过。
4. normal在空任务已回收的active状态后RELEASE；parent-loss在同一状态杀自己的controller，guard监听寿命pipe EOF。每case最多一次，顺序执行；前一case未核验终止/恢复不启动后一case。
5. guard确认空任务已回收、probe无未知成员/子组，再恢复本轮修改的目标字段：每policy先原min、再原max。每项先核对当前值属于事务记录的已知状态；只有不存在待撤销写意图、或已有该字段原请求重发及可见回读确认时，才可对当前原值跳过。曾尝试但尚未确认撤销的目标请求，即使现在仍显示原值，也必须明确重发原请求，以避免异步工作稍后应用旧目标。未知值或身份/固定控制条件变化则报告冲突并拒绝覆盖。独立清理步骤继续，频率冲突不抹去cgroup清理结果。
6. 成功需目标可见原值、其他30策略与global固定字段相同、自有cgroup删除、根CPU0—31归还且隔离空、observer实际见guard pidfd退出。terminal文件单独不够。保存全部原值、失败、源摘要、PID/ticks、写入/恢复记录并独立取回核查。

合作方共用锁不能阻止不守锁的管理员；读取和写入之间也不是原子比较交换。上述拒绝未知状态是保护边界，不承诺任意并发管理下绝不覆盖。成功支持原请求已经明确重发及可见sysfs配置恢复；单凭这些接口不能证明内核work严格排空，也不代表QoS内部请求或固件状态逐位复原。

每case原guard管理期限20秒，频率字段回读各有有限预算，observer沿用25/35秒软观察期限；内核阻塞可能越过软预算。超时保存原句柄和部分状态，不自动换guard重跑。guard自身SIGKILL、OOM、整机故障不享自动恢复保证；人工恢复沿用锁、nonce、inode和进程终止检查，新入口也必须理解频率intent。项目文件及恢复快照全部实际落在Cry内，不创建/run或/tmp项目文件。

## G2的后续固定工程口径

准备C11工具只链接未修改reference内核，OS安全随机源生成8个正常有效输入并预先往返验证；固定循环的重复输入明确记录，不称iid或真实密文总体。工作进程仅CPU2，CPU18空闲保留，不补空转负载。采集均在C中，预热1秒、主观察4秒，总调用上限250000、快照容量512；每64次完整调用后检查20ms采样期限，漏过期限不突发补采。每次完整调用原值、硬件快照、失败和成本保留，采样间无stdout或磁盘I/O。

工程诊断带事前定为4300MHz标尺的±1%，即4257—4343MHz；它不代表安全差异、单调用误差或计量精度。CPU2线程CPU时间/RAW时长低于80%记低调度活动代理，非精确C0占比；任一三读跨度超过1ms记超限，相邻快照超过40ms记节奏缺口。失败、计数下降、零分母、读钟异常和未覆盖边界全部保留并分类。CPU18不强制通过活动要求。

对同一有效时期单调未回绕的快照 `(M_minus, A, M_plus)`，相邻点记 `L=M_next_minus-M_prev_plus`、`H=M_next_plus-M_prev_minus`。仅L>0时可报告 `4300 × delta_A / H` 到 `4300 × delta_A / L` 的读取对齐区间；这不是置信区间或完整误差界。区间完全入带、边界不确定和带外分别登记，覆盖分母包含全部主观察时间及调用。不能用MPERF绝对增量除以标称频率和时长宣称精确C0占比。[AMD计数语义](https://docs.amd.com/api/khub/documents/sD1_QL~h4Afq2_tvzxqqSQ/content)仅定义活动计数比的架构解释。

G2须先完成工作进程与guard的长期生命周期衔接：运行时监听EOF/取消/期限，先关gate、终止并回收自己的child，再恢复频率与分区；正常observer等工作完成再RELEASE。当前空任务预演没有验证该衔接，不能直接替换worker后运行。全工程目标即使通过，也不签收R02总体、R04统计或每次短调用恒频。

## 本轮预算与登记

本轮G1最多normal和parent-loss各一次实际case；软件检查与准入失败分别计账。新云端文件预算30MiB，只导出本管理模块必要源与日志；C11窗口工具本轮只做实现及软件检查，不进入G2真实采集。G2的新源码、功能向量、Linux产物、具体执行合同及磁盘/调用预算在衔接审查后冻结，不在这里预填成功结果。
