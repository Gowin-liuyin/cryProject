# CPU2/18 固件计数器映射独立复核

复核日期：2026-10-10。结论：通过“已保存固件表中的静态计数器声明映射”这一限定子项。未执行 AML、C 程序或 SSH；本次只读取既有本机文件、在内存中检查字节与文本，并核对官方源码。未修改 preparation 或原始证据。

## 证据身份与处理状态

本次实际读取的解码产物是 [SSDT3.dsl](/Users/yin/code/cryProject/build/frequency-reader-20261010/SSDT3.dsl:1) 和 [iasl.log](/Users/yin/code/cryProject/build/frequency-reader-20261010/iasl.log:1)。DSL 为 482653 字节，SHA-256 为 `6528830e0f5d7b5e7933aaf653370f8e7c7754e641916a81c5426ed60b6d5bc7`；日志 SHA-256 为 `baec1fc955c750dbaaed680266cf8d28962430f51f94e61927a0270940b4fc82`。日志第 3–56 行列出唯一目标 SSDT3 和其他 13 张 external 表，第 57–63 行记录目标解析与反编译完成，第 66 行标明工具版本 20230628。该日志未见 Error、Warning、AE_ALREADY_EXISTS 或 unresolved 诊断。S01 实机退出码 0 来自主线程提供的执行结果；本次没有重新运行解码器或独立读取远端退出状态。

原表来自 [feedback-mapping-20261010-62ce88b02a82.tar](/Users/yin/code/cryProject/build/frequency-reader-20261010/feedback-mapping-20261010-62ce88b02a82.tar)，归档 SHA-256 为 `5de3dd6af737bca1e8a47a9aa6729313be084612e788eab287fb968ebbaef431`。独立逐项重算其中 14 张表的长度、SHA-256 和 ACPI 校验和，均与归档内 metadata.json 一致；总长 282915 字节，校验和均为 0。SSDT3.dat 为 39854 字节，SHA-256 为 `c86cb418348be1995a4b743eb43b42c936c647d1c3531a4b71245d137e811e0b`。S01 工作副本保持上述原字节的执行收据由主线程归档，本复核不将本机原表校验冒称为再次读取了远端副本。

S01 是事前登记的独立进程单目标诊断，见 [STATIC_DECODER_SUPPLEMENT.md](/Users/yin/code/cryProject/docs/research/aris-frequency-reader-20261010/STATIC_DECODER_SUPPLEMENT.md:1)。原 F01 全体 `-da` 退出 255 的事实保持；本次不回填“14 张表全部反编译成功”。

## Linux CPU 与 ACPI 对象对应

[firmware-nodes.json](/Users/yin/code/cryProject/docs/evidence/frequency-reader-20261010/preparation/firmware-nodes.json:5) 第 5–15 行记录 Linux CPU2 → `\_SB_.PLTF.C004`、UID 4、HID ACPI0007；第 17–27 行记录 CPU18 → `\_SB_.PLTF.C005`、UID 5、HID ACPI0007。该文件 SHA-256 为 `e8ee937e927b14c545af15ff47f0cc66a060cc7fae3c75b5396f6e22309b6132`；原表归档的 metadata.json 也记录相同对应关系。不能按 Linux CPU 编号推定 C002/C018。DSL 的 `_SB` 与 sysfs 的 `_SB_` 是同一 ACPI NameSeg 的显示写法。

SSDT3.dsl 第 2004 行进入 C004 Scope，第 2307 行声明 `Name (_CPC, Package (0x17))`；第 2491 行进入 C005 Scope，第 2794 行声明相同对象。两者均处于顶层 Scope，都是静态 Name Package，NumEntries 为 23、Revision 为 3。独立按包的顶层分隔符枚举，两包恰有 23 项，去掉空白与注释后逐项完全相同。

## 关键字段逐项核对

以下 package 索引均从 0 开始，包含 NumEntries 和 Revision；不能与 Linux `cpc_regs[]` 索引混用。GAS 元组依次为 `(address_space_id, bit_width, bit_offset, access_size, address)`，数字除地址外均为十进制。

| package 索引 | 含义／静态值 | C004 DSL 起始行 | C005 DSL 起始行 |
| --- | --- | --- | --- |
| 0 | NumEntries = `0x17` = 23 | 2309 | 2796 |
| 1 | Revision = `0x03` = 3 | 2310 | 2797 |
| 3 | Nominal Performance：FFixedHW `(127, 8, 16, 4, 0xC00102B0)` | 2321 | 2808 |
| 12 | Counter Wraparound Time：SystemMemory 空资源 `(0, 0, 0, 0, 0)` | 2408 | 2895 |
| 13 | Reference Performance Counter：FFixedHW `(127, 64, 0, 4, 0xE7)` | 2417 | 2904 |
| 14 | Delivered Performance Counter：FFixedHW `(127, 64, 0, 4, 0xE8)` | 2427 | 2914 |
| 20 | Reference Performance：SystemMemory 空资源 `(0, 0, 0, 0, 0)` | 2477 | 2964 |
| 21 | Lowest Frequency：整数 `0x258` = 600 MHz | 2486 | 2973 |
| 22 | Nominal Frequency：整数 `0x10CC` = 4300 MHz | 2487 | 2974 |

另核对 `_PSS[0][0]`：C004 第 2026–2030 行、C005 第 2513–2517 行均声明 `0x10CC` = 4300 MHz。它是固件声明的首个性能状态频率，不是此次测得的运行频率。ACPI 对 `_PSS` 的排序与 CoreFrequency 单位有明确定义。[ACPI 6.5 §8.4.5.2](https://uefi.org/specs/ACPI/6.5/08_Processor_Configuration_and_Control.html#pss-performance-supported-states)

还直接检查了归档 SSDT3.dat 中对应 NameOp 的 AML 字节，偏移分别为 `0x1680`、`0x1b4a`。只解码字面量 Package、整数和 Buffer 长度／GAS 字节，没有解释执行操作码。两包均有 23 项，其关键 GAS 元组与上表相同；因此 DSL 中省略的空资源 access_size 也已由原字节确认是 0，而非仅凭显示省略猜测。原表含 32 个 `Name(_CPC, Package)` 字节模式；DSL 有 32 个静态 `_CPC` Name、0 个 `_CPC` Method。其他 13 张原表均未出现 `_CPC` 名称字节。

两个目标的包内容均由整数与固定 ResourceTemplate 构成，无返回分支、方法调用、对象引用或动态构包；与这些描述符值相关的静态依赖已闭合。DSL 第 23–54 行的 External 仅为 CPU DeviceObj Scope 声明，没有待解析的 `_CPC` 控制方法。该结论针对所保存表中的描述符，不扩大为整个运行时 namespace 永远不可变。

## Linux 默认语义与可用主张

Linux v6.17 先取 package[0]/[1]，随后将 package[k] 保存到 `cpc_regs[k-2]`。结合枚举，package[13]/[14] 分别是 REFERENCE_CTR/DELIVERED_CTR，package[12]/[20] 分别是 CTR_WRAP_TIME/REFERENCE_PERF。[解析源码](https://github.com/torvalds/linux/blob/v6.17/drivers/acpi/cppc_acpi.c#L671-L791)、[枚举定义](https://github.com/torvalds/linux/blob/v6.17/include/acpi/cppc_acpi.h#L77-L100)

空资源必须同时满足 SystemMemory、地址 0、宽度 0、偏移 0、access_width 0；上表两项符合 `IS_NULL_REG`，因此为不支持的可选字段。`cppc_get_perf_ctrs` 将不支持的 Reference Performance 回退到 Nominal Performance，并对不支持的 Wraparound Time 返回 U64_MAX。故 reference_perf 来自读取 `0xC00102B0[23:16]`，不是 `_CPC` 中一个独立的常量 124；`18446744073709551615` 则是内核默认语义，不是实测回绕周期，也不是任意长度采集都不会发生回绕／重置的实验保证。[空资源判断](https://github.com/torvalds/linux/blob/v6.17/drivers/acpi/cppc_acpi.c#L111-L120)、[回退实现](https://github.com/torvalds/linux/blob/v6.17/drivers/acpi/cppc_acpi.c#L1378-L1439)

对于 FFH，x86 实现按描述符地址在目标 CPU 读取 MSR，再按位宽与偏移提取值。因此，本次静态声明与该实现共同支持：这两个 ACPI 对象的参考／交付计数器绑定到完整 64 位 E7／E8。[x86 FFH 读取](https://github.com/torvalds/linux/blob/v6.17/arch/x86/kernel/acpi/cppc.c#L44-L57)

ACPI 将不支持的 Reference Performance 回退到 nominal，计数器反馈需要区间首尾差分；其 Lowest/Nominal Frequency 是报告用频率锚点，不保证精确物理对应。[ACPI 6.5 §8.4.6.1.1.3、§8.4.6.1.1.7、§8.4.6.1.3.1](https://uefi.org/specs/ACPI/6.5/08_Processor_Configuration_and_Control.html#cpc-continuous-performance-control)

本次没有直接转储 Ubuntu 当前内核缓存的 `cpc_desc_ptr`，也没有再次求值 `_CPC`；不能声称“内核缓存 dump 已证实”。固件 `_PSS` 首状态和 nominal_freq 均为 4300，只提供一致的静态频率声明，不能由此断言 TSC 等于 P0 参考率或实测精度。未采集活动区间差分、验证频率带或运行参考性能负载；R02/R04 仍为部分签收。以上官方材料只核读所引字段、解析与读取路径，未声称全文精读 Linux／ACPI 文档。
