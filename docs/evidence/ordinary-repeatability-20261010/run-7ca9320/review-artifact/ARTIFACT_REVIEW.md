# 普通参考运行间研究的实际原件与生命周期独立审查

2026-10-10。**两批实际归档、源/产物身份、软件资格、六进程管理接受及结束回执，在下述核查范围内通过。** 审查发现本地可变deployment sidecar残留一个预启动零值；其原字节已保留、勘误已核对闭合，不是实验失败或追加采样。没有其他阻断发现。R02/R04不因此完整签收。

本审查直接读取实际tar.gz、全部原件及回执，不只采信摘要。审查者先前审过源码/管理器，但未参与实现；此为同模型内部独立实物审查，外部Codex MCP不可用、pending，不称跨模型、外部同行或独立实验室验证。本次没有SSH、执行collector/analyzer/产品CLI或CTest，没有新的完整密码算法调用或采样，也没有修改远端原件、封存证据或提交。

## 归档和历史清单

| 对象 | E1 | E2 |
|---|---|---|
| 实际压缩字节 | 5377139 | 8278790 |
| SHA256 | `f53d0a8e22cc7b9c27d5390ef31ec98ae333a4404afda3bb6c1c4f4ec2d763d1` | `58dad05265dc0c4c3d02285060dc344518d44366ffe3c45118a0023610d5ac28` |
| gzip CRC32 | `12ac336b` | `f3e2b53b` |
| 解压完整tar字节 | 28559360 | 44830720 |
| 安全唯一普通成员 | 708 | 732 |
| 成员有效载荷字节 | 27237675 | 43460892 |
| 当前manifest记录 | 707 | 731 |
| 含PAX的物理tar头校验数 | 1416 | 1464 |

完整读尽两gzip流，CRC32及ISIZE相符；逐个tar头校验和通过，末尾只有零填充。逻辑成员名均为规范相对路径，无上跳、反斜杠、控制字符、链接、目录或特殊载荷。PAX头只负责格式元数据，不与上表的普通文件数混计。两份manifest各恰覆盖除自身外的全部成员，所有长度/SHA逐项匹配；对应解包树成员集合相同且每份原字节与tar相同。

E2中的全部708份E1旧原件与E1 tar逐字相同，包括旧manifest；旧E1 archive的SHA又由E2依赖及最终回读绑定。E2自己的manifest覆盖当前732成员，包含旧E1 manifest；旧manifest仍只描述原707项快照。没有把合法E2新增文件误判为旧清单缺失，也没有追改旧E1清单或归档。

## 源身份、构建和实际ELF

实际部署为`7ca9320f6aeb525daba6169ffb0135be0c31779a`。完整140项SOURCE_MANIFEST的长度/SHA与实际源相符；加清单和管理器共142个文件。每份远端归档源与本地该Git对象逐字相同，142成员source.tar也逐字对应，上传载体SHA为`2b5378377c012c291412e7e022bd142de24419e4843d7877b75c6a71faba53a2`。远端无.git，提交号是部署标识，本地逐字核对补足Git对应关系。

collector源为`a895575cc8c58856df7dab19ea204338f3af073df698e0f3f73f3eb75a0de1a1`，analyzer为`f9fd89c8641d56a9f279ef397e11df11a3f4ab9d44a8f62c2644914ded12e6bc`，公开fixture头为`9226f4016239ca54cca800f80d73850abcfb2e89d38cc6b5e7cc86e4d105657a`，CMake为`403c99108fe604b0e2a4a584dd9b503c475ac909e75526bee53ae04606b6c2ab`。实际管理器为最终`857d30a018662251cfdba7e9070a5dd1c9aa6132be1f2a86cee7b218a31e6ae7`，manifest为`c95d924d31e0c085724f89a97c5808c7706bcae22ec1bd683c5b45b8495f6552`，计划为`90ced1f1d1157f80997f5af3e2afaeb83c7bf8a488c00c229ac77d55d7cd70ec`。

自行解析六份实际ELF头、节表和动态项，均为ELF64、小端、x86_64、PIE。普通三份只直接依赖libc.so.6；动态三份另依赖libasan.so.8和libubsan.so.1。全部实际字节摘要与两批before/after/state及E2依赖相同：

| 实际产物 | SHA256 |
|---|---|
| 普通collector | `9324a4369a17818ed3d69c93cd8fc18856518e8f983a07834c511464e244e47c` |
| 普通analyzer | `6757778a301e3a0aaa49d3ee4507ab1fb39a75eb8220daeda35eab1cfa341230` |
| 普通KAT | `a93c5eb509678c84c4900c0344e4d34b3cf4c4f5891bd388630643fd4ace95a3` |
| 动态collector | `a9cd010b240861dee98f3f8c5f951e80fe9887af31098ff12cf99c31836062f2` |
| 动态analyzer | `cc47215b976e2cfedf5ac1f64daa883a6630cb1985625325cb505588eb1b8e04` |
| 动态KAT | `0632edd8362c40781bf4e738d02e34e29eec8481bf1162ff9b349b6a2821aa4a` |

14条编译命令为/usr/bin/gcc、严格C11、固定baseline配置，无变体宏或LTO；普通O2，动态在O2后生效O1及address/undefined。六条link命令绑定对应配置，collector/KAT链接实际reference静态库；生成器固定Unix Makefiles，CMakeCache、编译和link原件保存。实际版本日志为Ubuntu GCC13.3.0及CMake3.28.3。

普通collector机器码的采样路径内联到run_collection：`0x2b32 clock_gettime@plt → 0x2b97 mlkem_decapsulate → 0x2baf clock_gettime@plt`，两读参数为RAW的4。完整wrapper在`0x3b60`检查NULL及32/1088/2400长度，随后在`0x3b94`跳至`0x7bf0 baseline_native_dec`。两份转换仅由第二读之后的分支到`0x33f8/0x3406`调用`0x1c80 convert_clock_reading.part.0`。输出的32字节比较、volatile sink消费`0x2d08…`与擦除`0x2d29`也在后读之后。源码/产物证据支持本新ELF的窗口顺序，不识别每次动态libc/vDSO/系统调用解析路径；编译器栅栏不冒称硬件串行化或物理精度证明。

## 实际软件检查和六个完成进程

E1普通与ASan/UBSan库存均恰五项，JUnit各tests5/failures0，无跳过；verbose共同确认五项实际通过。两纯内存selfcheck没有算法/真实读钟；fixture-check分别完整匹配NIST答案且reference身份、Linux dumpable禁止均true；原NIST80/18参数拒绝/随机往返成功；process-safety检查回读dumpable0、错误0、crypto_calls0。动态配置仅作资格，正式collector和C分析都调用普通产物。命令环境明确detect_leaks=0，不声称LSan。

E1有35条命令，E2只有版本读取三条、collector三条及analysis三条，共9条，没有重新构建、CTest或额外fixture资格。44条命令实际全部exit0；每条leader PID/starttick明确、leader已回收、自有组消失且cleanup_unconfirmed=false，88份stdout/stderr的长度/SHA均与所见文件相符。新目录实际拥有标志true，接受后的四原件长度/SHA全部保留并在封存前一致；本审查再次逐项核对24份case文件，没有用新摘要覆盖旧接受摘要。

| 批次/case | 普通collector PID | 保存计时调用 | setup调用 | 管理结果 |
|---|---:|---:|---:|---|
| E1/P1 | 3676354 | 50000 | 1 | accepted |
| E1/P2 | 3676357 | 50000 | 1 | accepted |
| E1/P3 | 3676360 | 50000 | 1 | accepted |
| E2/P1 | 3676537 | 50000 | 1 | accepted |
| E2/P2 | 3676540 | 50000 | 1 | accepted |
| E2/P3 | 3676543 | 50000 | 1 | accepted |

六PID互异，与GNUtimeout supervisor和管理PID分开。每份原CSV恰50000行、十八列头、完整LF；元数据均单行、Linux/x86_64、UID/eUID1000、fixture tg5/tc86及固定来源、reference身份true、setup1/status0/verifiedtrue、valid/planned warmup和main各25000、attempted/verified各50000、completed且partial_unknown=false。自身CPU2亲和性设置及前后精确mask/观察CPU、dumpable set/readback0/错误0均相符。前后clocksource=tsc，声明getres=1ns；这只是记录值，非绝对误差认证。

C摘要保留metadata/exit/complete接受false以及precision/iid/R02/R04 false，管理层另完成退出/元数据及C接受；两层没有合并或改写原JSON。数值代理另对300000行、5400000字段、600000份读钟值、36行360数值及六完整摘要全量核对一致。本审查只读该核验的范围/身份，没有重新排序、计算分位数或冒称再次执行全量数值oracle。

按固定源与真实成功测试路径，Linux资格两配置为54keygen+54encap+24decap=132完整算法；六collector有300000计时+6setup解封装。因此本研究本轮Linux实际完整算法为300138，其中解封装300030。另40直接密钥校验、36参数拒绝、20公开测试SHAKE单列。总量由完成路径和原记录证明，不是动态逐算法调用插桩；管理/元数据时钟读数不计入600000次采样读钟，也不把先前Mac132次资格混入Linux账。

## E1依赖、新认证及结束回读

E2依赖的E1 state/manifest/archive摘要、六ELF与boot_id逐项匹配实际E1原件，两批均同boot `1d5a4300-d997-4a45-a9d6-95165d68dcd9`。本机E1下载核验、第一次关闭、第二次新控制连接认证及E2调用的回执顺序一致；e1/e2使用不同socket，E1旧socket已不存在，E2本地记录实际新密码提示，口令未保存。本审查核对的是本机控制回执，没有再次SSH或独立服务器认证日志取证。

两份remote stdout均恰开始认领及最终completed/archived两事件，与调用记录逐项相同。树内archive_status仍指向外部stdout，归档SHA没有自引用。E1先回读39原PID/35组均不存在；最终精确集合为两个管理PID+44不同命令leader+6不同collector，共52个，44组恰为已登记自有PGID。全部/proc不存在、tick为null，44组均absent；null没有补造退出tick。两个管理starttick343618578/343653938及44命令starttick另由开始记录绑定。

最终原stdout与postcheck.json所有远端payload字段相同，query_exit0是控制器另外保存的退出状态。调用者亲和性0—31，root/carrier/E1archive/E2archive四路径存在、非链接、物理路径等于Cry内记录；root732普通文件、非普通列表为空，两个archive SHA未变。每批129份可见频率文件前后相同仅为快照，未写全局配置，不证明独占、隐藏状态不变或连续恒频。两SSH关闭exit0、控制socket不存在。该结束结论仅覆盖上述登记PID/自有组和路径，不泛化为全机无其他任务或任意异常恢复路径已演练。

remote query UTC与local close UTC来自不同机器，不能直接排序或估计同步精度。例如最后remote query为12:35:46.883575而local close为12:35:46.037361；真实先查后关依据控制器先完成query exit0再调用关闭的流程回执。批间采样间隙使用同boot的RAW原值边界，数值代理记录346446211228ns，不从跨机UTC推算，不把SSH重连当独立环境。

## 审查发现的行政sidecar勘误

初读deployment.json已标两批完成，但remote_collectors_started仍为预启动0。root保留初读完整字节为deployment-before-count-correction.json（SHA256 `25615f25359170c8ec0aa0b65986167cdd6c42337cf74a1822c83f07393426b5`），按两原state的3+3修正为6。修正后SHA为`a24df713d6630c7c711510eac3f1515a8ee309655e54185539d1e2b54e9031ab`；补充correction回执绑定两版本与来源，并新增完成管理调用数2及说明字段，其他原字段不变。本审查逐字摘要和实际差异已核对闭合。该文件是可变本地部署摘要；远端state/raw/两tar均未改，不把修正算为实验失败、再次启动或额外采样。

结论仅支持本次有限工作流的实物、完整接受与正常结束记录。源静态审查、实际软件资格、原始数据、独立数值和正式统计前提仍各有范围；精度、独立性、长期稳定、总体错误率或R02/R04签收不能由本页自动推出。详细机读绑定见本目录verification.json及三份检查明细。
