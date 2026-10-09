# R02 反馈读取证据实物独立复核

2026-10-10。结论：本轮保存固件的目标静态描述映射、Linux 软件自检和指定 MSR 一次读取能力可以限定签收。未发现阻断这三个子项的实物矛盾；恒频资格、R02 与 R04 均不升级。

本复核只在本机读取已保存文件和 Git 对象，在内存中解析归档、ELF 头与 JSON。没有 SSH、运行 ELF、执行 AML、重新解码固件或改写已有证据。除另行运行已有 `verify_evidence.py` 外，独立直接核对了实际归档成员、全部运行清单载荷、源码提交对象、原始测试日志、编译链接选项、目标 DSL 字段和原始读取输出，未仅以验证器的 passed 字段作结论。

## 归档与源码身份

三份原始 tar 均重算 SHA-256，与工具收据和验证器固定值相同。

| 归档 | SHA-256 | 实际内容 |
| --- | --- | --- |
| `feedback-mapping-20261010-62ce88b02a82.tar` | `5de3dd6af737bca1e8a47a9aa6729313be084612e788eab287fb968ebbaef431` | 14 张原表及 metadata.json，共 15 成员 |
| `feedback-counter-20261010-16ec7cf0d5fb.tar` | `3457b6f8c729eac6209316f08f353486d5027eb17bc33489af84a8dc9ac2a601` | normal ELF、stdout.json、stderr.log、execution.json，共 4 成员 |
| `feedback-reader-eed81a7-results.tar` | `b187de98505e70f555d583be9e88add9e7cd603b9d5cf896e95be5862079382a` | 475 个清单载荷及 export-manifest.json，共 476 成员 |

运行归档的 476 个成员均为唯一常规文件；475 个清单载荷的名称集合、字节长度与 SHA-256 逐个吻合。固件 14 表共 282915 字节，保存字节与头部声明长度、metadata 长度及摘要一致，ACPI 校验和均为 0；S01 的 14 份输入逐份保持这些原字节。

源归档 SHA-256 为 `78572cc80804f2b5d44b0308a8e46ce027f0cb0d70331962568e6dfcdcffdb1c`。其中 C 源、CMakeLists.txt、EXPERIMENT_PLAN.md、capture_firmware.py 均直接与 Git 提交 `eed81a7620a1c929c52e96acb203104917ec3b5d` 的对应对象比较，字节相同。C 源 SHA-256 为 `6d21bf4e1d9c93956a9a4e5d25b07f0f4339a2d2b5e3df465ae663bd85170c66`。

保存的 root 执行封装 SHA-256 为 `39e50972d7d4ac5ec15be38d46b47c32e1f34f76873c2c6648c4266b3e3c0f26`，与事前审查版本及提交 `acbbd699a4e4e4606a4150ed75e448e0eb688124` 中对象相同。collector 为已审查的 `4868344851c38a40116d3cdd8cf51151d00c08b1ddcc10146530348ff8ea6025`。`orchestration-provenance.json` 明确保留 build/S01 包装代码执行时尚未提交、随后提交的事实；原 build 外层退出 1 的完整工具返回 envelope 未保存，现有外层说明属于回顾记录，不能冒称完整原件。逐步骤原始日志、进程结果及失败解码结果已在运行 tar 中保存，该局限不影响下述逐步骤结论。

## 软件自检与实际读取

normal 和 sanitize 的 configure、build、test 六份结果均退出 0。直接读取两份 LastTest.log，均为唯一 `msr_counter_snapshot_selfcheck` 通过，输出 `hardware_read_performed=false`；普通与动态检查各 1/1，不表示运行了硬件读取或项目全部测试。

实际编译和链接记录使用 `/usr/bin/cc`、C11、严格警告及 `-Werror`；sanitize 的编译与链接均带 `-fsanitize=address,undefined`，并启用 `-fno-omit-frame-pointer`。两个真实产物的头均为 ELF64、小端、机器号 62、类型 3。normal ELF 为 28688 字节、SHA-256 `acfa346972dd79dc614927e89697632fe71c3d68b5e2829522faeaa93cc422a7`；sanitize ELF 为 76760 字节、SHA-256 `3e9083f1fa57dd30e2b78e67dde54bcd41360f8a3f9803412959b9c732af7b60`。root 归档内执行副本与 normal ELF 逐字节相同。

执行记录为 Linux `nss-m`、`6.17.0-35-generic`、x86_64、euid 0，PID 3662422、启动 ticks `338295146`；退出 0，未触及注册执行期限，stderr 为空。源码固定一次启动无参 C 程序，保存输出含两 CPU、各 MPERF-before／APERF／MPERF-after 三读。六读均返回 8 字节，各 read/clock/close 错误字段为空；原值保持十进制字符串，时间前后顺序成立。

| CPU | MPERF-before，E7 | APERF，E8 | MPERF-after，E7 |
| --- | --- | --- | --- |
| 2 | `86900763512423` | `76477214044314` | `86900763566216` |
| 18 | `15248241157683` | `14848371467216` | `15248241188342` |

这些是一次累计快照，不能将表中 APERF 除以累计 MPERF 当作本轮有效活动区间频率；本复核未作该换算。

## 静态解码与可见结束状态

初始全体 `-da` 的原始退出码是 255，日志确有 `AE_ALREADY_EXISTS`；仅 DSDT.dsl 的产生不能签收全体 14 表反编译成功。独立进程 S01 以 13 张原表作 external、单独 SSDT3 为目标，结果退出 0，日志没有 Error/Warning/unresolved，目标 DSL 为 482653 字节、SHA-256 `6528830e0f5d7b5e7933aaf653370f8e7c7754e641916a81c5426ed60b6d5bc7`。这是保留原失败后的限定目标诊断，并未覆盖原失败。

直接抽核保存 metadata 的 CPU2→C004/UID4、CPU18→C005/UID5，并读取目标 DSL 中两个 Scope 的 `_CPC` 静态 Name Package：两者均声明 23 项、修订 3，参考／交付计数器为 FFixedHW、64 位、偏移 0、地址 E7／E8；nominal 描述为 C00102B0 的 8 位、偏移 16；频率声明为 600/4300 MHz。此处签收保存固件中的静态描述对应关系，Linux 默认语义和原 AML 字节细项见同目录 FIRMWARE_MAPPING_REVIEW.md；没有转储当前内核的 cpc_desc 缓存或执行 `_CPC`。

最终可见状态采集时间为 `2026-10-09T21:40:47.195091+00:00`。两目标策略均为 powersave、min/max 为 2982259/5756452 kHz、EPP 为 balance_performance、per-policy boost 为 1；全局 amd-pstate 为 active、boost 为 1，根 cpuset 有效 CPU0—31、isolated 为空。这与本轮只读封装及所保存结束状态一致；它不是持续监控，也不表示当前仍独占或频率已固定。SSH 关闭收据在 provenance 中记录，复核没有重新连接。

## 签收边界

可以签收：这组原始表与目标静态映射的可追溯性、指定 C11 软件自检、固定 normal 产物对 CPU2/18 E7/E8 的一次成功只读能力和完整原值保存。

不能签收：活动区间参考率及精度、频率容差带或恒频、普通参考密码负载的正式采集、真实总体误报率／检出率、R02 或 R04 完成。未运行密码算法负载、主动缺陷变体或统计比较，也不把静态映射和读入口成功升级为这些证据。

文档维护建议：FIRMWARE_MAPPING_REVIEW.md 开头仍含本机 `build/frequency-reader-20261010` 中 DSL、日志和 tar 的链接；已存在本目录 `selected/decode-s01` 和原始 tar 的持久副本，后续说明优先指向这些保存副本，避免清理 build 后断链。此问题不改变已重算的原始字节与结论。
