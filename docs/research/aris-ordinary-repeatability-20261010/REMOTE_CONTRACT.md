# 普通参考重复性远端管理合同

本入口仅执行[事前实验合同](EXPERIMENT_PLAN.md)的两次连接批次。collector、analyzer、公开fixture及CMake已在提交`f1410f8aae139ec2d114e23b4a143447ec6753ab`完成本机资格；其冻结SHA保持不变。本管理器不计算统计量、不产生输入、不修改算法或系统配置，仅管理固定程序、退出/元数据接受和封存。本合同形成时尚未上传或启动Linux资格、E1/E2采集。

## 唯一入口与源布局

入口固定为`remote_run.py ROOT SOURCE_COMMIT e1|e2`，或纯内存`--selfcheck`。ROOT必须是`/home/nss-marker/yhr/Cry/reference-repeatability-<提交前缀>-<nonce>`，提交参数为40位小写十六进制且与前缀相符。根及所有父级物理位置逐项核对，不接受符号链接、越界或模糊路径。普通用户运行，拒绝root；不使用sudo、MSR、调频、cgroup、IRQ或其他全局配置写入。

`ROOT/source/`保持仓库相对布局。固定[SOURCE_MANIFEST.json](SOURCE_MANIFEST.json)的SHA-256为`c95d924d31e0c085724f89a97c5808c7706bcae22ec1bd683c5b45b8495f6552`，列140项源/依赖/配置/向量/计划的长度及SHA；管理器与清单自身为另外两文件，共142个普通文件。拒绝额外、缺失、非普通文件或字节不符；每次批次前后都核对。管理器自身SHA及source_commit另录，避免自引用。实际部署前由本机Git逐字验证完整142文件，远端无.git，不声称其独立解析Git提交。

E1新建`ROOT/batches/e1/`，E2新建`ROOT/batches/e2/`，已有批次或case一律拒绝覆盖，不自动恢复、续采或补跑。普通/动态公共构建树固定为`ROOT/build-ordinary/`和`ROOT/build-sanitize/`，E1要求新树，E2只复用、核对其原字节。全部项目源、构建、输入、输出、日志、缓存、临时文件和归档均在Cry物理边界内，不新建/tmp或/run项目文件。

## E1资格与三进程

启动前读取Linux/x86_64、UID/eUID、可用mask含CPU2、实际工具、boot_id、UTC和可用空间；记录/proc负载/CPU上下文、clocksource及129份可见频率文件。ROOT实际supervisor PID、`/proc`starttick及源身份同时写新启动声明并通过stdout回传；声明中的collector启动数为未知，不能把文件或计划当作已采样证据。

在新普通/动态树用`/usr/bin/gcc`、RelWithDebInfo、C11、明确生成器构建三个目标；source/CMake固定无变体宏或LTO。清除子命令环境中能覆盖本次构建的旧CFLAGS/CPPFLAGS/LDFLAGS/生成器变量，保留真实编译命令和link/cache。普通不得带sanitizer，动态明确address/undefined；六个ELF分别保存摘要及objdump/readelf/nm，动态产物只作软件资格。

每配置CTest库存必须恰五项：collector纯内存夹具、analyzer纯内存夹具、单次公开fixture检查、原NIST80/参数边界/随机往返及自身转储安全回读。实际verbose退出和测试记录另验，不以库存代替执行。Linux子命令固定`ASAN_OPTIONS=detect_leaks=0:halt_on_error=1`、`UBSAN_OPTIONS=halt_on_error=1`；只称ASan/UBSan，不称LSan，不为工具改回collector的dumpable状态。两个配置各完整通过时，按成功测试路径推导132次完整算法调用，辅助密钥/参数/SHAKE检查单列；失败时只报已证明数量或未知，不补齐计划值。

只调用普通collector的P1、P2、P3各一次，每份25000warmup+25000main及一次setup。stdout为十八列原CSV，stderr必须一份完整单行元数据。对应普通C analyzer读取原CSV，输出六行统计及原summary。收集和分析分开保存，开始前case为partial_unknown；正常timeout supervisor启动数、由完整元数据确认的collector启动数、完成数和接受数分别记录。

## E2依赖与相同产物

E2只允许在E1完整completed、三个case全部accepted、清理已确认后运行。源提交、manifest、管理器及全部六ELF须与E1记录相同，boot_id须相同；任一不符停止，不重建新产物补上。E2重新记录真实环境及产物/源摘要，执行同样三个普通collector和C分析，不重新CTest或在其外额外调用fixture。每collector自己的setup一次仍计账。

本机完成E1归档下载与字节核验、确认结束回收、断开控制连接并重新密码认证后才调用E2；这些前置任一不明则停止E2。实际连接和认证留独立回执，远端E1状态、batch参数或两个目录不能单独证明上述本机步骤，SSH重连也不等于独立环境。实际采样时间及间隙由原RAW边界、boot_id和UTC共同说明，不插等待制造独立性。E2保持E1旧文件、摘要、归档和已冻结清单字节，不改其状态为后来事实。

## 完整接受条件

collector退出0且原JSON合同为`ordinary-reference-repeatability-v1`、stop为completed、partial_unknown为false。必须为普通UID、fixture tg5/tc86及固定来源摘要、reference身份true、setup_call_count1/status0/verifiedtrue、record_count50000、valid及planned warmup/main均25000、attempted与verified_output计数均50000。转储设置已尝试且成功、回读0、相关错误0；自身CPU2亲和性设置成功，前后mask/观察CPU、clocksource与RAW getres合法且一致。声明分辨率只接受实际合法值，不预设本轮必为1ns。

C summary合同为`reference-repeatability-analysis-v1`，record50000、warmup/main各25000，两项整数守恒true，collector退出/元数据/完整接受三个标志仍为false；无物理精度/iid/R02/R04签收。stdout必须完整六行和固定表头，输出文件摘要保存。管理层完成这些独立核对后才将case改accepted并累计真实计数，不篡改C原JSON。

三case全部接受才记本批150000计时调用、150003含setup完整解封装和300000次采样读钟。E1另列132资格完整算法，E2为0新资格调用；两批完全成功时Linux共300138完整算法，其中300030解封装。不将启动监督者、空输出、已丢内存或不完整元数据补成确定次数。

## 时间、空间与生命周期

每批300秒工作软期限，以同一管理monotonic剩余预算收紧每条子命令timeout；每构建最大60秒、CTest30秒、C分析30秒。collector用GNUtimeout15秒、TERM后最多2秒KILL，管理等待最大20秒且受剩余预算约束。固定次数和外部期限共同限制，任何超时/截断/失败停止依赖采集，不补进程、不改次数。没有根据时长或p值提前察看追加。

每个子命令新session并记录实际leader PID/starttick。timeout/信号只向登记且仍存活的自有leader组操作，回收leader，再以只读killpg0核对组消失；至多五秒核查，不能确认则cleanup_unconfirmed、保持未知并停止。SIGTERM/SIGINT/SIGHUP及期限进入同一收尾路径，不把SSH观察结束当作远端工作已停止。SIGKILL、断电或回执缺失不承诺完整导出，先核对同一实际句柄，不自动重启。

子命令core上限0、单文件64MiB硬限；阶段边界核对ROOT普通文件总量不超256MiB并且可用至少1GiB，后者不是全局硬quota。TMPDIR/TMP/TEMP/XDG_CACHE_HOME/CCACHE_DIR/CLANG_MODULE_CACHE_PATH分别在本批新树内，HOME保持原值。记录每条实际argv、开始结束UTC、退出、leader/组回收、输出长度/SHA和明确环境配置；口令只在实际SSH提示输入，不写文件、参数、环境或日志。

## 冻结与导出

仅当全部已登记工作回收、组消失且源/产物前后核对明确时，保存本批最终state、commands、环境和固定摘要，生成本批manifest。manifest覆盖完整ROOT普通文件树，排除它自己，保存每成员长度/SHA；不把清单自身算为载荷记录。先冻结这些字节，再在另30秒导出期限内独占创建同级`ROOT.e1.tar.gz`或`ROOT.e2.tar.gz`，归档在ROOT外避免递归，但物理位置仍在Cry。

归档包括清单，外部最终stdout另回传root、archive、archive_sha256、status和archive_status，避免压缩包内自引用。E2归档可以包含E1旧manifest及原件，不能改写E1归档。E2当前manifest核对完整成员覆盖；其中E1旧manifest只核对旧快照的成员字节，不能把E2合法新增文件当作E1快照缺陷。归档失败或清理未知保留实际状态，不能发布完整成功回执；用户可据实际路径核查，不能因观察超时重采。

本机随后下载同字节原归档，检查gzip/tar、唯一安全普通成员、全部manifest与原字节、固定源码/ELF/日志/元数据，再独立全量复核统计。结束后只读核对实际登记PID及源/数据/归档物理位置、当前调用者mask，关闭SSH。全部通过也只支持有限重复性描述；精度/独立性/总体错误率及R02/R04仍按对应证据判断。

## 纯内存管理自检

`--selfcheck`只运行字符串、字典和逻辑谓词，不读文件或真实时钟，不启动子进程/SSH，不执行密码算法。核对固定root/commit/batch、元数据整数与bool区分、50000/25000计数、setup/转储/操作资格、summary标志、E2完整依赖及cleanup门；它不替代Linux生命周期实际执行或故障恢复证明。
