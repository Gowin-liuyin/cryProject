# RAW实际Linux原件与生命周期审查

结论：**本次归档、版本、两配置软件检查、三个普通空窗口进程的管理接受记录，在下述范围内通过；无阻断发现。** 外部OS对原PID的结束后核查与最终SSH关闭不在本次已查原件内，保持待补。R02/R04不因此签收。

审查直接读取实际`remote-originals.tar.gz`，不是只采信执行摘要；未运行C程序、SSH或重新计算六行分布。审查者没有编写`remote_run.py`，但参与了分析器编写和本机软件资格；此为实际远端实物与管理记录复核，不能代替另一实现的独立算术核对。可机读结果见同目录`verification.json`。

## 实物与版本

归档为4454198字节，SHA-256为`e6dfd03f03e1e2e4e28a4eb0c251a8f7d684745980727843263e4ad8ff1870e6`。完整读尽gzip流，CRC32为`7dac6e63`，CRC与ISIZE均匹配；tar头校验通过。496成员全部为常规文件，成员名唯一且规范、相对，无绝对路径、上跳、反斜杠或控制字符。tar没有逐文件CRC，此处逐文件完整性由SHA-256核验。

`manifest.json`恰绑定其余495成员，长度和SHA逐项匹配，无遗漏或额外载荷。下载后的`originals/`恰有同一496份文件、没有符号链接，与tar中每一份原件逐字相同。这里没有修改原件或旧封存目录。

四份上传源与本地Git提交`aa437714e023e2aef8301a925c33949647790517`中的相应文件逐字一致；四成员92160字节`source.tar`也与实际远端源逐字一致，其SHA为`ed7d049f6fe304b791b6d74aa16fcca78c4d4c92aa7bc6af3119f004872689de`。远端未保存Git对象，提交号在远端是部署标识；本次本地Git字节复核补足这一对应关系。

| 文件 | SHA-256 |
|---|---|
| `source/raw_clock_calibration.c` | `ed538f4322fba985aea9cfa78e0b2109f79caed49064e68eaa3884b4fa10f0dd` |
| `source/analyze_raw_clock.c` | `c67d1dbd89034a75600d3d13a28aa5c7fb4a163b5649fa910c7eea624c7544e0` |
| `source/CMakeLists.txt` | `28d264a993558d1aad66dd6ffd2671c0a3ea18054fda6d6ec91b06a7c312816e` |
| `source/remote_run.py` | `bf34389f2cb39348ac1baa2a3c2b159ad69cb473414ff3b6b7b97850d0431d04` |

运行状态绑定的计划SHA为`7499b60b7a32b0a5e82e2acbc07144b6b0062b5d1f344aeb4af9ff4208e6927a`，与该Git提交的计划正文一致。远端终端实际捕获两行事件：开始认领、最终`completed/archived`回执；后一行的归档路径与上述归档SHA相符。树内`archive_status=see_supervisor_stdout`没有冒充自指归档摘要。

## 构建、测试与正式产物

版本日志为Ubuntu GCC 13.3.0、CMake 3.28.3。普通与动态配置的`compile_commands.json`分别恰有两个目标：普通为`-O2 -g -DNDEBUG -std=c11`及固定严格警告；动态在同组基础参数后有生效的`-O1 -fsanitize=address,undefined -fno-omit-frame-pointer`。两者均无LTO。CMakeCache、链接命令、编译器配置及实际构建日志均保留。

每配置CTest库存恰为`raw_clock_calibration_selfcheck`和`raw_clock_analysis_selfcheck`，实际stdout、JUnit及`LastTest.log`共同记录2/2通过、0失败。动态CTest实际环境为`ASAN_OPTIONS=detect_leaks=1:halt_on_error=1`和`UBSAN_OPTIONS=halt_on_error=1:print_stacktrace=1`；结论限于这两个内存selfcheck，没有以动态数据作正式空窗口测量。

独立解析四份ELF头和动态段：均为ELF64、小端、x86_64、PIE。普通两份仅依赖`libc.so.6`；动态两份另依赖`libasan.so.8`、`libubsan.so.1`。实际字节SHA均与运行状态绑定值一致。

| 实际ELF | SHA-256 |
|---|---|
| `build-ordinary/raw_clock_calibration` | `f3f873a5b7d333cee70b2128107ed73a4f178e6bb1f966bc7a20253a368d6cd3` |
| `build-ordinary/analyze_raw_clock` | `257b046f44a3a2613ea23f5a0943f02f293117a7d28013245063970479538b07` |
| `build-sanitize/raw_clock_calibration` | `82251c29ea65ccce81263a1c4b5c04fda2eb500a5f0a30ccea0a674bc924e27d` |
| `build-sanitize/analyze_raw_clock` | `7991ef1a3f8bda8b65a640ad7f87b12a1ca386de2e913c27f1687f0879834e4b` |

P1/P2/P3的命令逐项确认使用`build-ordinary/raw_clock_calibration --collect`；三个分析命令也使用普通分析器。命令环境保留了ASAN_OPTIONS，但它不使没有sanitizer依赖和插桩的普通ELF变成动态检查产物。

普通collector的实际objdump中，采样路径内联到`run_collection`：`0x2155`和`0x219f`分别调用`clock_gettime@plt`，传入clock ID 4；第一次成功检查之后才到第二次读取。两份转换分别在第二次读取之后的分支`0x2a07`与`0x2a15`调用`0x1710 <convert_clock_reading.part.0>`，随后才处理读钟顺序。这支持本次普通ELF的可见读后转换顺序，不倒证旧G2产物或旧运行。编译器信号栅栏没有被冒称硬件串行化指令。

## 三个实际进程与管理接受

三份collector元数据均为完整单行JSON：Linux 6.17.0-35-generic、nss-m、x86_64，UID与有效UID均1000，原亲和性CPU0—31，自身设置CPU2成功，前后亲和性均`[2]`且观察CPU为2。前后clocksource为`tsc`，RAW声明`getres=1ns`，相关errno均0。

| case | GNU timeout外层PID | collector PID | 原CSV数据行 | 管理记录 |
|---|---:|---:|---:|---|
| P1 | 3675336 | 3675337 | 101000 | accepted |
| P2 | 3675339 | 3675340 | 101000 | accepted |
| P3 | 3675342 | 3675343 | 101000 | accepted |

三个collector PID互异；每份声明1000预热和100000主pair均有效，`stop_reason=completed`、`stop_errno=0`、`partial_unknown=false`。三个原CSV均有完整LF结尾、101001行含header，CSV与元数据SHA和case回执一致。管理程序记录三份完整进程，共接受303000pair；本审查没有以这些计数代替逐字段算术校验或重算分位数。

每case的collector退出、stderr完整元数据和后续普通C分析均实际成功后才变为`accepted`。分析器原summary仍保留`collector_stderr_checked=false`、`collector_exit_checked=false`和`complete_metadata_acceptance=false`，管理接受在case另记，没有篡改分析器的证据边界。实际三次没有失败、超时或取消case；unknown路径只可按代码及既有软件检查描述，不能声称本轮硬件实际演练过这些路径。

`tsc`是clocksource回读名称，1ns是API声明分辨率；二者不证明本次每次libc调用究竟走vDSO或系统调用，不证明硬件刻度、绝对精度、恒频或确定性误差界。该普通ELF导入`clock_gettime@GLIBC_2.17`并调用PLT的事实也不等于实际解析路径跟踪。CPU2前后回读不证明整段独占、SMT同胞空闲或每pair持续获得执行资源。

## 生命周期、路径与未核事项

29条命令日志的stdout/stderr摘要均逐项匹配，实际退出均0，时序顺序完整，每条记录均为`leader_reaped=true`、`process_group_gone=true`、`cleanup_unconfirmed=false`。外层leader PID、清理PID和PGID对应一致；collector PID与GNU timeout外层PID区分保存。runner源码对这些记录的含义是wait回收自有leader，并以signal 0观察原自有组不存在；不在leader回收后向旧PGID发送终止信号。

管理进程开始认领的PID为3675161，`/proc`启动tick为343006206，run-claim、run-state与本地SSH捕获的开始事件一致。开始事件明确`collector_processes_started=null`，不把文件存在或外层启动当作collector完成。状态保存工作截止为2026-10-10 10:44:26.573065 UTC，记录的工作阶段耗时约1.339秒，之后的环境和归档导出另行保存。这里的内部正常回收记录不能代替root后续对实际原PID的OS核查；最终SSH控制连接关闭也须使用随后真实记录，不提前签收。

云端物理项目根为`/home/nss-marker/yhr/Cry/raw-clock-aa43771-fe4ffb3f92f3630e`。实际归档路径为其Cry内同级`.tar.gz`，上传包也在Cry内。固定runner在进入与阶段边界检查物理根、拒绝符号链接及特殊项目文件，项目临时、缓存环境全部指向新根内。129份频率可见文件（32策略各governor/min/max/EPP与boost）前后原值一致，管理亲和性前后均CPU0—31；这只是两个时点的只读上下文，不能作为整段恒频、全局配置持锁或隐藏状态逐位一致证明。

初始上传退出255，stderr为认证拒绝，发生于远端helper执行前；随后密码登录后的上传退出0，实际远端工作仅有这一轮三case。初次认证失败应登记为前置部署失败，不能算一次失败采样或补记0pair。项目写入边界结论来自固定源路径、实际环境、树和归档清单核对；没有进行全机写系统调用跟踪，因此不把清单推成未记录位置绝无写入的独立证明。只读`/proc`、`/sys`和HOME字符串不作为项目文件的存放例外。

本审查没有连接旧KVM、修改原件、运行新硬件样本或执行C复算。仍待外部结束后原PID核查、最终SSH关闭，以及独立算术审查；科学结论只允许三个近期空窗口进程的有限描述，不能外推完整解封装的重复性、统计前提或R02/R04完整验收。
