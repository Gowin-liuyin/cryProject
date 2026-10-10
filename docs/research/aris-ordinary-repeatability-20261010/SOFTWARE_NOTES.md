# 普通参考重复性软件资格

本页保留采集前Mac资格及准备时点；其后Linux资格与六进程已经完成，当前实测见[RESULTS](RESULTS.md)，下文未执行状态不追改为当时已取得。

2026-10-10，真实采集前的本机普通及ASan/UBSan配置各4/4项CTest通过，初次执行没有修复重跑。实际平台为macOS/ARM、Apple Clang21、CMake4.3.2；这不替代Linux/x86_64资格或实际采集。完整源、构建、六个Mach-O、编译命令、CTest库存及verbose日志见[准备证据](../../evidence/ordinary-repeatability-20261010/preparation/README.md)。

## 固定源和测试范围

| 对象 | SHA-256 |
|---|---|
| collector | `a895575cc8c58856df7dab19ea204338f3af073df698e0f3f73f3eb75a0de1a1` |
| analyzer | `f9fd89c8641d56a9f279ef397e11df11a3f4ab9d44a8f62c2644914ded12e6bc` |
| 公开NIST派生头 | `9226f4016239ca54cca800f80d73850abcfb2e89d38cc6b5e7cc86e4d105657a` |
| CMake | `403c99108fe604b0e2a4a584dd9b503c475ac909e75526bee53ae04606b6c2ab` |
| 冻结实验合同 | `90ced1f1d1157f80997f5af3e2afaeb83c7bf8a488c00c229ac77d55d7cd70ec` |

测试时基线为main提交`22a7b9065984cb1f2c6361c4553b23589f88d1fb`，新模块当时未提交，以上逐文件摘要绑定实际被测版本；不能把它记成旧提交已经包含本模块。原src、vendor、tests及旧G2/RAW工具不改。五个读钟helper及结构与固定G2保持正文一致；统计排序/分位/MAD/整数守恒复用旧RAW实现，新增操作状态严格资格及50000行合同由独立静态审查覆盖。

| CTest | 实际范围 |
|---|---|
| `reference_repeatability_selfcheck` | 纯内存timespec/溢出/零值/逆序、阶段/容量、十八列失败及null/操作状态/输出匹配格式、JSON和短缓冲区；零算法、零真实读钟 |
| `reference_repeatability_analysis_selfcheck` | 严格字段解析、操作未执行/失败/输出不匹配拒绝、固定分位/MAD、阶段内与边界整数守恒；零算法、零真实读钟 |
| `reference_repeatability_fixture_check` | 一次完整公共reference解封装，与独立NIST全32字节答案相符；不是计时采集 |
| `reference_repeatability_nist_kat` | 原NIST80用例、18参数拒绝及系统随机往返；27keygen+27encap+11decap共65完整算法调用，辅助检查另列 |

因此本机两配置按实际完成的测试路径合计132次完整算法调用（54keygen、54encap、24decap），另40直接密钥校验、36参数拒绝和20公开拒绝答案SHAKE参照；不是300000次正式计时的组成部分。Linux第五项自身进程转储回读尚未执行，Mac的fixture日志中`process_dumping_disabled=null`如实保留。Mac动态设置`detect_leaks=0`，不声称LSan或Linux采样循环已被动态执行。

普通产物为`-O2 -g -DNDEBUG`、严格C11警告、无LTO；动态产物独立加ASan/UBSan、最终O1，不用于正式时长。两配置各五条实际管理命令（configure/build/库存/CTest/format-check），全部退出0。模块clang-format21及根format-check通过；公开固定向量保持字节，不就地重排。

## 输入资格和真实资源预检

三份公开fixture数组与原prompt/expected JSON及转换向量逐字相同。初次提取按文本行查找遇到向量跨行而拒绝，没有创建头或执行算法；随后以唯一operation/tcId token定位，并对原JSON字节核对后生成头，失败过程另记。NIST的VAL分组本身不证明有效密文。独立公开SHAKE参照确认expected不等于`J(z||c)`，结合固定拒绝输出源码及两配置实际完整输出匹配，支持此固定样例为有效密文；不以返回0分类，不输出内部接受状态。

指定主机的新密码只读预检确认nss-m/Linux x86_64、CPU2在可用mask内、Cry真实根可写、所需工具和空间可用；未写远端项目文件、未运行算法或采样，SSH随后退出0、控制socket消失。第一次本机控制socket路径过长导致SSH退出255，没有远端helper；改用build内短socket后预检完成。这个历史快照不当作存活实验或正式环境资格。

## 下一执行门

独立合同和静态代码审查通过，外部Codex MCP不可用，保持同模型内部审查身份。真实Linux链接/ELF、普通/动态各5项CTest、受限管理器、六个collector与原值核验均尚待执行。远端管理器须另绑定源/输入清单、剩余总deadline、普通ELF复用、每case未知与清理状态、两个实际连接批次及Cry路径，再固定部署提交；不能直接拿旧RAW管理器的四文件/101000行接受规则启动新工具。

本模块没有参数化样本量、变体、秘密类别、通用统计接口或同ELF空窗选项。软件通过不签收R02/R04，原49页报告、925项包及旧数据保持原身份。
