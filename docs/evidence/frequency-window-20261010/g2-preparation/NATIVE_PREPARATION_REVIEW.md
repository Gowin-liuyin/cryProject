# G2 管理器与分析器的真实 Linux 软件原件复核

2026-10-10。结论：本次真实 Linux 软件准备门槛通过，没有发现阻断已冻结 G2 两条一次性路径的原件问题。此记录补齐 G2_PREPARATION_REVIEW.md 当时尚待完成的 native 管理与分析软件检查，不表示 G2 已运行或真实窗口已经合格。

复核仅在本机读取新软件 tar、linux-check 选取副本和 Git 对象，在内存中重算、解析及逐字节比较；没有 SSH、执行 ELF、重跑测试或改动先前封存的软件证据。

完整 `window-management-0ba4cd7-software.tar` 的 SHA-256 独立重算为 `f8d495de5318e46241dbaa6190ac58114e0cae627c94e6cf4085cfc7fbdf6a32`。609 个成员均为唯一常规文件，路径安全，实际长度与 tar 声明一致；608 个清单载荷的名称集合、字节长度及 SHA-256 逐项符合。所有 linux-check 选取副本与相应原 tar 成员逐字节相同，没有仅以已有 verification 旗标作结论。

内部源 tar 的六个实际文件逐个与 Git 提交 `0ba4cd7c1f41c700a7fdef2b277cbf7f39e74bac` 的 blob 及导出源树比较，均相同：管理源及其 CMake、G2 冻结合同、分析器 C 源及其 CMake/README。管理源重算 SHA-256 为 `8616a0747d7a8e3b28e5af6da86bfdee5b2bf2f84821989c163136ec09479af4`，就是已独立审查的最终版本，没有用另一个 native 源替代该版本。

run.json 记录实际 `nss-m`、Linux `6.17.0-35-generic`、x86_64、Python 3.12.3；八个 configure/build/test 步骤均退出 0。直接读取三份 LastTest 原日志，管理器 1/1、普通分析器 1/1、ASan/UBSan 分析器 1/1 通过。管理器输出含 registered_eof 正例及既有管理/故障模拟检查，并明确 kernel_writes=none、crypto_workload=none；两个分析器检查均输出 fixture_only=true、hardware_data_analyzed=false。它们是软件与良性替身检查，没有被当作真实管理预演或硬件数据分析。

两套分析器的原 CMake 编译器记录均为 GNU 13.3.0。实际 flags.make 使用 C11、严格警告和 Werror；动态配置编译及链接均含 address/undefined sanitizer，普通配置均不含。两个完整产物均为 ELF64、小端、机器号 62，长度及重算摘要与 run.json 产物记录相同：

| 分析器 | 字节数 | SHA-256 |
| --- | --- | --- |
| normal | 153568 | `f25d556a44065b794b967b9e7604a46beb340acc4dcb2c2e3036ad2aa3f06d43` |
| sanitize | 638944 | `23950d6fe8660436a703416eea84c5ada93a1920523c0af970ae981ea2c8e5c3` |

run.json 明确 real_guard_run=false、crypto_workload_performed=false、hardware_data_analyzed=false、configuration_writes=0；临时与缓存目录均为 Cry/window-management-0ba4cd7 的子目录。正常 worker 仍是单独已核验的 c0e5990 普通 ELF，不能用这里的分析器或 sanitizer 产物替代。

本次通过支持在现有来源、合同、生命周期与分析器对应独立审查基础上，按冻结合同执行 normal 和 parent-loss 各一次，实际准入仍由 run-window 当时的检查承担。真实退出、原始 JSONL、取消与恢复、频率带及覆盖结果必须由后续实际原件证明；负结果、竞态和部分输出照实保留，不补跑。恒频、R02 总体及 R04 均未由这些软件原件签收。
