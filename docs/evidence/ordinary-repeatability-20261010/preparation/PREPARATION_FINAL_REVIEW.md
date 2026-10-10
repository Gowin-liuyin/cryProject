# 普通参考重复性准备封存独立实物复核

2026-10-10。**本次软件准备封存及当前说明在所查范围通过，无阻断发现。** 实际证明为macOS/ARM普通与ASan/UBSan各4/4软件资格、固定公开输入一致性及原件完整性；Linux资格、Linux采样循环和六进程计时均未执行。本页为同模型内部独立审查，外部Codex MCP仍不可用、pending，不称外部同行或跨模型审查。

本审查只读已有本机实物，使用ZIP/CRC/SHA、JSON、Mach-O结构与字节比较，不执行C、CMake、CTest、SSH、collector或完整密码算法，也没有更改docs、原评语或提交。前次`STATIC_CODE_REVIEW`形成时的测试pending保留其原时点；本页以新增记录核对随后取得的实际资格。

## 完整归档和源身份

直接完整读取`qualification-originals.zip`：1120265字节，SHA256 `77b6cbb65412f08a466f9db24ac30be3cfce38a30570b8c48373374f946d333d`。527成员全部唯一、安全相对路径、普通文件载荷，无目录或符号链接；未压缩载荷3576381字节。ZIP读取CRC及另算CRC32逐项匹配，全部527成员与`qualification-initial`实际树的成员集合及每份原字节相同。

`tested-source`五份副本与qualification固定摘要、当前模块及前次独立静态审查的相应固定对象一致。另核对依赖清单135项（其中125项vendor文件），每份长度/SHA和当前文件相同，且逐字等于基线Git提交`22a7b9065984cb1f2c6361c4553b23589f88d1fb`。新模块当时未提交，只以逐文件摘要绑定实际被测版本；没有冒称该基线已含新模块。原src/vendor/tests与旧工具没有因本次资格改变。

六份产物逐一从完整ZIP读出，与资格回执SHA相符；自行解析Mach-O头均为64位arm64可执行文件。普通三份仅导入libSystem；动态三份另导入ASan运行库，并保留ASan和UBSan处理符号。两配置的14条编译记录均为严格C11、arm64、固定baseline配置，没有变体宏或LTO；动态生效O1且有address/undefined sanitizer，普通无此插桩。实际机器代码采样顺序及Linux ELF尚不在本次实物中，不能由Mach-O身份代替。

## 实际测试及调用账

十条已记录命令均exit0，顺序为每配置各configure、build、库存、verbose CTest、format-check；没有修复重跑。两份库存都恰登记collector纯selfcheck、analyzer纯selfcheck、单fixture和原NIST KAT四项，没有collect或Linux process-safety项。两份verbose完整记录四项实际执行且100%通过、0失败。

两份fixture日志均为tg5/tc86、reference身份、一次完整解封装、status0及32字节外部答案匹配true；Mac的`process_dumping_disabled=null`原样保留。前次审查已将头数组逐字绑定原NIST JSON及转换向量，并独立确认公开expected不等于固定拒绝输出。与当前完整fixture匹配合在一起，支持该固定公开样例有效的条件资格；VAL标签和返回0均未被单独当作接受依据。

纯collector selfcheck明确报告crypto_calls0/real_clock_reads0；analyzer selfcheck仅执行内存解析/统计夹具。源控制流与前次静态审查一致，没有在纯selfcheck中隐含完整算法。原NIST日志分别确认25keygen+25encap+10decap、20密钥验证、公共参数边界及随机往返均成功。

结合已核对的实际成功测试路径，每配置KAT为27keygen+27encap+11decap=65次完整算法调用，加单fixture的1decap为66次；两配置共132次，即54keygen、54encap、24decap。另40直接密钥校验、36参数拒绝、20公开测试SHAKE参照单列。这个账来自固定源码与成功入口路径，不是动态逐调用计数器，也不把核心内部SHA3/NTT次数算成额外完整调用。资格中计时调用及硬件采集均为0。

Mac动态回执记录`asan_detect_leaks=0`，当前说明不声称LSan；已查Mach-O、编译和CTest实物支持ASan/UBSan的软件资格范围。归档没有单独保存每条子命令的环境转储，本页不声称从子进程独立观测到该环境变量，也不扩大到Linux路径或所有正式采样路径的动态检查。

## 资源预检与文档

`compute-preflight.stdout`解析后与COMPUTE_PREFLIGHT的actual_context逐项相同：nss-m/Linux x86_64、调用者0—31包含CPU2、Cry物理根等于记录路径且可写、工具及空间可用。回执明确项目写入/算法/采样为0；初次过长控制socket的本机失败保留，成功预检后关闭exit0、socket不存在，原关闭stderr相符。本审查没有再次SSH或全机写系统调用追踪，只核对已保存的只读操作及结束记录，不把预检快照当成当前存活实验或正式环境资格。

已通读新增SOFTWARE_NOTES、tracker、README、当前状态的新准备入口及证据README。来源摘要、4/4、132账、平台限制、零计时、Linux待执行、两连接不独立、R02/R04未签收等表述与上述实物一致。五文档共69个本地Markdown目标已逐个解析；只有证据README的SHA256SUMS按既定最终封存顺序等待纳入本页后生成。这是明确的封存顺序，不列为未闭合审查问题；最终清单仍须在全部文件复制后核对。

原静态意见和机读记录与build原件逐字相同；当时pending没有被追改。新资料仍独立交付，不改49页报告、925项包或旧数据。完整ZIP成员/每份源、六Mach-O、文档SHA和具体检查范围见`PREPARATION_FINAL_REVIEW.json`。

结论仅通过本次准备实物。后续仍须独立审查受限管理器、固定部署身份并取得真实Linux资格、普通ELF/完整元数据、六份原值及生命周期证据，才能评价本合同的有限测量主张。
