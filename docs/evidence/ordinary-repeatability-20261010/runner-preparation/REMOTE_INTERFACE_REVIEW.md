# 远端管理器高层接口独立审查

2026-10-10。被审管理器SHA-256 `40b74f05bf8ec9d29e80d5788a9c7fe447c771bdd35c97c542c3abd649088938`；原字节另保存为`remote-interface-reviewed-40b74f05.py`，只作只读审查快照，未执行。绑定最终管理合同`ccb0ec975d52bcbfda5acec69784cdde6604b9114533976d37c284d1fe315fc2`、计划`90ced1f1...`与manifest`c95d924d...`。本报告独立新增，不改原608合同审查。

本代理静态阅读入口、接受谓词、E1/E2执行/归档接口和selfcheck内容，未运行真实或内存manager、自检、C/CTest、SSH、新算法或文件故障模拟，未改docs/实现、未commit。生命周期的逐指令竞态/信号深审由另一独立代理及主代理承担，本报告不代替它。

**需修两项再冻结该管理器。**其余本次检查的高层接口、计数和E1/E2语义与合同一致；实际执行和全面源码正确性仍未认证。问题已即时反馈。

## I1：接受后的原值/分析输出没有维持最终身份

在原管理器629行，collector接受时记录CSV及metadata SHA；642行又在分析后确认两者不变；644行接受case并存analysis/summary SHA。可是693—695行最终阶段不比较旧身份，而重算覆盖CSV/metadata SHA，缺文件还设为None。之后只固定source/ELF和E1旧树，当前batch已接受的四份输出没有最终身份核验。

因此，最终阶段不能证明已接受原值和对应分析仍保持；它可把变化后的hash重新记入state/manifest，或者在某已接受文件缺失时仍保持`status=completed`和accepted计数。这里没有真的删除/替换文件，也没有做第三方攻击，只指出接受条件与最终完整成功回执的逻辑缺口。

建议对每个accepted case的CSV、metadata、analysis、summary逐项核对仍是预定物理普通文件、仍存在且当前SHA等于原接受SHA。不得覆盖原接受摘要；变化/缺失应记录明确失败并禁止完整成功回执。失败case若需新增最终观察摘要应单列，不用它代替早先已接受身份。修复不需要新增密码调用、采样或修改C程序。

## I2：配置未明确生成器

合同要求明确生成器，后续实现还固定读取Make布局的`CMakeFiles/<tool>.dir/link.txt`，但538—540行的configure argv没有`-G`。虽然清空环境通常令该Linux选择默认Make，仍是隐式依赖，与合同文字不一致。

建议显式固定`-G "Unix Makefiles"`，并保留真实CMake缓存/链接记录。这个修复只涉及管理接口，不改变冻结CMake或被测源，也不应触发额外密码资格重跑。

## 检查通过的高层部分

入口限制Cry固定根/commit前缀/e1或e2、普通Linux/x86_64；source布局精确140固定文件+manifest+runner，逐字节核对及物理路径检查，六类临时/cache变量在新批次树、HOME保留。环境白名单排除旧构建覆盖变量，普通/动态分树；六ELF要求固定源和编译/链接、普通无sanitizer/动态address+undefined、无LTO或变体宏。动态`detect_leaks=0`与合同一致，不执行LSan或放宽dumpable。

E1库存精确五项，实际verbose及JUnit另验，完整两配置按真实成功路径计132完整算法/24decap，不将库存当执行。E2不进入qualify_configuration，只复用同六ELF，并核对E1完整state、三case、同boot、source/runner/manifest及原manifest字节；每collector自身setup仍执行且计账。

每批P1—P3各一次，每个50000计时+1setup；supervisor启动、由元数据确认的collector完成、分析接受分别计数。两批成功总300138完整算法、300030decap、300000计时调用、600000采样读钟，与计划相同。未知case保留unknown，失败停止不自动补跑。metadata/summary字段名称与冻结C接口相合，bool与int分开，RAW分辨率按实际合法值而非必为1ns，C原范围false标志不改。

频率路径实际为32策略×4+boost=129，clocksource另列，只作前后快照。管理remaining deadline收紧每条子命令，工作300秒与导出30秒分开；core0、64MiB逐文件和阶段树/空间核对属于不同预算。本报告只读这一接口，未运行cleanup或证明其所有信号路径。

E2创建前用E1 manifest核对当时冻结全树；E2输出后只核对旧E1列出的成员字节、旧manifest和旧archive身份，当前E2 manifest再覆盖新全树，符合修正合同的两层语义。真正E1下载核验/断连/密码重认来自本机操作证据，remote状态不替代它。archive独占建在ROOT外Cry内，清单不含自身、tar含清单、hash外返，避免递归和自引用。

## 继续条件与范围

I1/I2修复后需要单独绑定新runner SHA和增量复核，不能倒改这份40b74版本结论。主代理/另一代理还须完成生命周期深审和纯管理自检，再固定部署提交并进行实际Linux资格与两批采集。本报告没有认领真实上传、Linux资格、结束回收、长期稳定或完整R02/R04；它们仍待对应证据。
