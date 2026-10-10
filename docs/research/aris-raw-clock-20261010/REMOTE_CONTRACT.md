# RAW工具单次远端行政合同

`remote_run.py`仅管理本研究冻结的两个C11工具，不计算分布或统计量，不接受任意命令、
构建选项、CPU或次数。它不实现SSH、保存凭据、发送消息、设置全局频率或分区；主机身份
检查与实际密码提示由本地操作者处理。旧KVM不在本轮流程内。

根目录参数必须为物理路径
`/home/nss-marker/yhr/Cry/raw-clock-<提交前缀>-<8至32位十六进制nonce>`，提交参数为完整
40位小写十六进制且与目录前缀一致。预上传树只包含`source/`和其中四个常规文件：
`raw_clock_calibration.c`、`analyze_raw_clock.c`、`CMakeLists.txt`、`remote_run.py`。
前三份源码以冻结SHA-256校验；第四份记录自身摘要。源码提交是本地提供的部署标识，
远端没有Git对象时不声称已经独立解析过该提交。计划摘要固定为
`7499b60b7a32b0a5e82e2acbc07144b6b0062b5d1f344aeb4af9ff4208e6927a`。

已有任何运行状态、构建、输出、额外文件或同名归档都拒绝；不覆盖、删除、迁移或重跑。
根、祖先及子树拒绝符号链接和特殊项目文件，阶段边界再次核对物理根、常规文件、
固定源码与已生成ELF摘要。普通Linux/x86_64用户、CPU2在允许mask内、空闲空间至少1GiB
才进入运行。没有root入口、调频、MSR、cgroup或他人进程枚举。

子命令只使用固定`/usr/bin`工具及本树固定ELF。环境不继承SSH/凭据或外部缓存变量；
TMPDIR/TMP/TEMP、XDG_CACHE_HOME、CCACHE_DIR和CLANG_MODULE_CACHE_PATH都指向
本树新目录；HOME保留登录环境原值，不另作工作或缓存目录。固定C/CMake流程不向其写项目文件。
管理进程及子进程core限制均为0，子进程单文件输出上限64MiB。
记录gcc/cmake/timeout版本、完整命令和所设环境、UTC、实际退出与自身进程组PID。
只读环境前后记录uname、UID、允许mask、CPU信息、clocksource、32策略的governor、
min/max/EPP和全局boost、loadavg及proc/stat；不可读项保存errno，不补原值。

普通与ASan/UBSan各一次：configure和build共同限60秒，CTest限30秒；先核CTest库存
恰为两个冻结selfcheck，随后执行全部两项。Linux ASan固定
`detect_leaks=1:halt_on_error=1`，UBSan固定`halt_on_error=1:print_stacktrace=1`；任一失败即
停止依赖步骤，没有静默降级。四份实际ELF摘要、compile_commands及objdump/readelf/nm
结果保留，动态产物不用于正式采集。

只有两配置全部通过才启动P1、P2、P3，各顺序一次普通collector；每份CSV及JSON使用
独占创建，GNU timeout限10秒、逾期2秒强杀，管理等待最多15秒。每条命令另有自己的
进程组；管理超时或可捕捉终止信号仅在原leader的`Popen.poll()`仍为None、原PID尚未回收
时向其自有组发送SIGKILL。leader一旦回收，绝不再向旧PGID发终止信号，只以signal 0
只读检查组是否消失；不按名称扫描或杀他人任务。每条命令结束后最多5秒核对leader已
回收且进程组消失，回收期间暂屏蔽ALRM/TERM/INT/HUP，先记录已知或unknown状态再恢复
原mask。leader退出仍可能留下未确认成员，包括不可中断状态；未确认就停止新工作。
异常终止、空输出、解析或预算失败都停止后续进程，不补跑。三个不同collector PID、
真实UID、完成退出、完整单行元数据、101000/1000/100000计数、前后CPU2及source/getres
一致均由管理程序单独核对。随后普通C分析器每CSV一次、限30秒，保存六行CSV和原summary。
分析器自身的`collector_stderr_checked=false`等字段保持原样；管理接受结果另记在case中。

开始工作时独占保存run-claim.json，并输出一行supervisor_started事件，给出本管理进程的
真实PID及/proc启动tick；这不是collector启动或数据完成证明。连接观察中断时，操作者可
按该PID/tick核查实际存活，不凭文件存在就宣布仍在运行。终端最后一行才是最终归档回执。

计划collector数、实际启动GNUtimeout supervisor数、元数据确认完成数和通过分析的实际
pair数分别记录。`launched_supervisors`及`supervisor_started`只说明外层已经启动；缺少
完整collector元数据时，实际collector开始/完成字段为null，不能补记0。元数据确认完成
单记事实，case的`partial_unknown`直到C分析和管理接受全部通过后才为false；分析失败
保留unknown。计划303000不会冒称实测。行政程序不做Python统计或替代C校验。
整个工作阶段限300秒，各阶段核树内载荷不超过256MiB及空间至少1GiB；达到预算即停工。
256MiB是阶段边界预算，单文件64MiB的RLIMIT为硬限；它不是全局文件系统硬quota。
超时的自有进程回收最多5秒，结束后只允许额外30秒有限证据导出，不继续编译或采样。

成功与失败都通过finally保存运行状态、命令和后环境。仅当全部自有leader及进程组
确认终止才冻结全常规文件manifest，然后尝试
生成Cry下同级新`.tar.gz`，成员名均相对本树且拒绝符号链接。manifest不包含自身；
写入归档时也限制树与归档合计不超过256MiB。已冻结manifest绑定的文件不在归档后改写，
因此最终归档SHA及实际`archived/not_archived`状态由终端compact JSON返回；本地操作者
必须捕获该返回。树内run-state明确`archive_status=see_supervisor_stdout`，不会自指归档
摘要。预算不足或归档中断明确返回not_archived，原件和可能的部分归档均保留，不抹除。
`cleanup_unconfirmed`时记录原自有PID/PGID及已知状态，不生成manifest或tar，返回
not_archived并保留仍可能变化的工作树；不把尚未确认静止的目录包装成冻结证据。
参数/主机/预上传完整性拒绝发生在认领工作树之前，只返回失败，不在不可信路径写证据。

`--selfcheck`只在内存检验路径、参数和元数据schema的正反例，不调用时钟、文件、外部
命令或SSH。它只验证行政条件逻辑，不冒充Linux工具资格、真实采集、调频恢复或测时精度。
本文件与runner属于准备材料；执行、独立实包核验及结果到主张另行记证。
