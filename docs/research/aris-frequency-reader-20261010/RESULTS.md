# 固件反馈映射与实际读取结果

2026-10-10。已完成本轮F1的静态声明子项及F2/F3的C11软件、实际读取能力核查；R02整体和R04仍部分签收。原件及独立复核见[执行证据](../../evidence/frequency-reader-20261010/run-eed81a7/README.md)。

## 现在可以确认的事实

| Linux CPU | 固件缓存设备定位 | 保存表中的参考／交付描述 | 实际只读结果 |
|---|---|---|---|
| 2 | `\_SB_.PLTF.C004`，UID4 | `_CPC[13]/[14]` 为FFixedHW，位宽64、偏移0、访问大小4，地址E7/E8 | MPERF前值、APERF、MPERF后值三读成功，均8字节，时钟与读取错误均为空 |
| 18 | `\_SB_.PLTF.C005`，UID5 | 同一组完整GAS字段 | 同上；两CPU依次读取，非同时或独立物理核 |

映射不是由Linux编号推算。它来自本机缓存firmware_node的path/uid/hid、14张原始DSDT/SSDT和目标表的静态声明。独立复核对DSL与原AML字面量字节交叉核对，两目标均为23项的静态Name Package，没有相关动态返回分支或未解析方法依赖。未直接转储内核的 `cpc_desc_ptr`，也未再次执行 `_CPC`；静态描述闭合不等于运行时内核缓存已经直接验证。

两目标的nominal_freq及 `_PSS[0][0]` 均声明4300MHz。Reference Performance与Wraparound字段都是SystemMemory零宽、零偏移、零访问大小、零地址的空资源。按上游Linux v6.17，前者回退到nominal，后者返回U64_MAX；这与既有sysfs的124和 `18446744073709551615` 相符。该解释没有逐行验证Ubuntu发行版补丁，不将默认值说成实测回绕周期。完整字段与官方依据见[独立映射复核](../../evidence/frequency-reader-20261010/run-eed81a7/FIRMWARE_MAPPING_REVIEW.md)。

## 软件与执行身份

固定C源提交为 `eed81a7620a1c929c52e96acb203104917ec3b5d`，源归档SHA-256 `78572cc80804f2b5d44b0308a8e46ce027f0cb0d70331962568e6dfcdcffdb1c`。本地AppleClang/macOS及真实Linux/GCC的普通、ASan/UBSan配置各通过一个专用软件自检；这不是整个仓库测试通过，也不是用Mac运行Linux分支。Linux的实际编译、链接参数和完整单项CTest原日志已取回。

真实执行只使用普通Linux产物，SHA-256 `acfa346972dd79dc614927e89697632fe71c3d68b5e2829522faeaa93cc422a7`，先校验并复制到Cry内root私有目录。封装源已冻结于 `acbbd699a4e4e4606a4150ed75e448e0eb688124`。一次C进程实际退出0，六读均成功，无超时，stderr为空。原计数及单调时间以精确十进制字符串保存，没有计算累计值比或频率。取回的执行ELF与普通构建ELF逐字节相同；本机仅对该ELF作静态反汇编，核对八字节pread调用及E7/E8/E7常数，不把这说成在Mac执行Linux产物。

此能力工具在三次读取之间输出JSON，因此读取间隔包含序列化及可能的stdout阻塞；两核也不是同步读取。它验证访问及保留原值，不能直接作为低偏斜频率采样器。`configuration_writes=0`由源码行为审查支持，不是动态写入审计计数。

## 保留的解码失败与新诊断

官方Ubuntu noble的acpica-tools20230628-1包及提取的iasl均固定摘要，原许可证保留，未安装系统包。原一次 `-da` 对14表处理退出255，只生成DSDT.dsl；此后重复加载external表时报告GF01/CPNV的 `AE_ALREADY_EXISTS`。外层流水线退出1，保留原日志、参数、PID/启动ticks及实际退出状态，没有将这个结果改写成全体成功。

事前补充S01使用新的普通用户工作目录及一个独立iasl进程，唯一目标SSDT3，另外13张表全部作为external。14张输入逐项保持原字节，新的目标解码实际退出0，未见错误、警告或未解析方法诊断。原解码失败与跨目标namespace残留的[版本源码路径](https://github.com/open-acpica/acpica/blob/R06_28_23/source/compiler/aslmain.c#L234-L277)一致，是原因推断；不认定为已确认固件问题或ACPICA缺陷。新目标成功不回填原14表全体反编译成功。

## 存放、回读与下一门槛

云端全部新增项目内容位于 `/home/nss-marker/yhr/Cry`：`feedback-reader-eed81a7/` 保存源码、工具、两套构建、原解码失败与S01；`feedback-mapping-20261010-62ce88b02a82/`、`feedback-counter-20261010-16ec7cf0d5fb/` 为root私有原件，同名tar为可读归档；完整导出为 `feedback-reader-eed81a7-results.tar`。原件不删除或改写，认证内容不入材料。

本地独立核验三份tar、14表长度/摘要/校验和、476个唯一常规成员及475项载荷清单、执行源和ELF、六读及逐次时间完整性均通过。完整导出载荷约5.19MB，树中无符号链接；本轮临时/缓存路径均指向Cry。结束时CPU2/18可见策略仍为powersave、原min/max及EPP/boost，全局active/boost保持，根分区可用0—31、隔离集合为空。SSH已关闭，没有仍在等待的本轮任务。

下一步仍须给受控普通参考负载固定有效活动窗口、参考率解释、允许带、覆盖率、读取误差和失败处理，再审仅目标策略的范围请求及恢复合同。单个累计快照、默认U64_MAX、固件4300MHz声明或读数接口成功，都不能替代恒频、物理精度或完整函数测量资格。本轮没有密码算法负载、主动缺陷测量、统计确认或新的正式报告/匿名包签收；旧KVM身份核验和真人材料保持待办，完整目标继续。
