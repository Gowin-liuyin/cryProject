# 普通参考运行间描述合同最终补审

2026-10-10。**原条件审查的两项问题均已闭合，最终合同在本次限定设计范围通过。**本文件是新增补审，保留原`CONTRACT_REVIEW.md/.json`的条件结论和原字节，不倒改旧审查。最终合同SHA-256为`90ced1f1d1157f80997f5af3e2afaeb83c7bf8a488c00c229ac77d55d7cd70ec`。

本代理只读最终合同、准备参照回执、实际Mac资格回执及日志，另作文件摘要比对；未SSH、未执行C或CTest、未重新计算SHAKE参照、未采集、未改源码/docs、未commit。仅为核查有效样例标签，定向读取了公开fixture比较helper、原封装及上游拒绝输出形式，不冒称全面collector/analyzer/管理实现审查或外部同行评审。

## 两项条件的闭合证据

原“三份新原值”已改为“六份新原值”。最终合同的两批×三进程、每进程25000预热+25000主、六份完整原序数据、36行描述相互一致；次数、预算和统计单位没有因此变化。

有效性依据已明确拆开：VAL分组不分类；原NIST expected与公开拒绝输出`J(z||c)`不同；新reference完整输出仍须与外部NIST答案32字节相同，不能仅凭return0。新的`public-fixture-acceptance-qualification.json`保存一次公开字节外部SHAKE参照的结果，绑定`kem.c`、`symmetric.h`、`src/mlkem.c`及NIST原件摘要。其公开拒绝值SHA-256为`77e3410e3d8a9f969d59200acd8064921c8003817a3f8481fb95dc059bfd48a3`，外部expected SHA-256为`ca4b36ac6565fbe8993b8cd84495a09f7104201008f529f3bc3f57a5c13727d2`，回执明确不相等。本代理核对了绑定文件摘要及源码中从dk末32字节和ciphertext构造J、在比较通过时选择重建结果的形式，未把该静态参照写成完整ML-KEM执行。

随后实际`qualification-initial`的ordinary和sanitize日志分别显示fixture-check退出通过、`operation_status=0`及`output_matches_fixture=true`。定向阅读helper确认这一布尔值来自完整`mlkem_decapsulate`后与外部数组的32字节`memcmp`，不是只检查返回值。fixture数组身份沿用前次已逐字核对的原JSON→转换向量→头数组关系。因此，针对本固定公开输入及同一参考源码，“有效密文”的现有依据闭合；它不形成运行时秘密类别标签或任何时间差结论。

## 真实资格回执的范围

本机为macOS/ARM。ordinary和ASan/UBSan各实际4/4通过，均含两项纯软件夹具、单次fixture-check和原NIST80/公共边界/随机往返。读到的两份verbose CTest日志均显示四项实际执行及100%通过；两份清单分别登记同一四项。该轮资格回执中十条配置/构建/清单/CTest/格式命令退出均0。源、合同和六个Mach-O当前摘要与该轮回执一致。

按前次已独立核对的路径账，每配置27keygen+27encap+12decap=66次完整算法调用；本机两配置实际完成路径共132次，计时解封装0、硬件采集0。额外直接密钥检查、公共参数拒绝及测试SHAKE保持单列。准备阶段的外部公开SHAKE是一次独立算术参照，不属于完整keygen/encap/decap计数，也不是本代理重新执行。

Mac动态资格使用`detect_leaks=0`，不声称LSan；Mac fixture输出的`process_dumping_disabled=null`准确表示Linux特有检查未执行。上述成功没有倒填为Linux五项CTest、Linux ELF身份、CPU2亲和性/RAW采集或远端生命周期资格。若后续源字节变化，初次资格仍保留其原身份，新源需按合同另行核验。

## 继续保留的边界

原设计判断保持：六个新进程分别描述，两个SSH连接批次不是独立环境；不池化大量调用冒充独立重复，不预设事后接近阈值，不扣20ns空窗，不以恒频/FPR/TPR为本实验新增硬门。计划remote总完整算法调用300138、其中decap300030、正式计时调用300000及采样读钟600000尚是计划，不能由Mac资格认领为执行。

原审查提出的管理实现要求仍有效：每批300秒工作软预算必须收紧各子命令剩余deadline，清理未知不当结束，失败不补采，Cry物理边界涵盖缓存/临时/归档。该管理实现尚不在本补审范围。

本补审支持冻结修正后的研究合同并继续其既定实现/资格流程，不证明六次采集已经发生或全部软件正确。Linux资格、真实普通采集、完整原值/整数账、生命周期及结果到声明仍须真实执行和独立核验。整体R02/R04保持partial。
