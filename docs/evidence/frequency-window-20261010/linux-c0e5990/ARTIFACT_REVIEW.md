# c0e5990 真实 Linux 软件与转储限制实物独立复核

2026-10-10。结论：本次固定候选的 Linux 编译、两套软件资格及自身转储限制检查通过；可以将下述普通 ELF 作为后续 G2 的固定候选。尚未执行普通无参入口或真实窗口，不签收 G2、恒频、R02 总体或 R04。

本复核仅在本机读取原 tar、选取副本和 Git 对象，在内存中逐项重算与解析；没有 SSH、运行 ELF、重跑测试或执行硬件读取。源码及实物审查由本地独立代理完成，不冒称外部 Codex MCP 或跨模型复核。

## 原档、源码及选取副本

完整软件 tar 的 SHA-256 重算为 `f487f59544aaab302303944463cd32daa99963725cef54eded4d220c578202e7`。618 个成员均为唯一常规文件，路径无绝对或上级成分，逐个读取长度与 tar 声明相同。617 个清单载荷的名称集合、长度和 SHA-256 全部与实际成员一致；所有 selected 副本逐字节对应原 tar 成员。本复核独立执行这些文件比较，没有仅查看 verification.json 或执行其验证器代替实物检查。

内部源 tar 的重算 SHA-256 为 `9f9803943f6ae724f895c57cd60c41828d0cba6a71d9deb7eb6f78907d95a8f5`。成员类型仅目录和常规文件，名称唯一且都在 source 前缀内。138 个实际源文件逐个直接与 Git 提交 `c0e5990bd4d764fbb08ff6857a2cf6cf21c9b8a2` 的 blob 比较，同时与导出树相同路径比较，均为原字节。

C 候选 SHA-256 为 `520bdc1bbcc1bbd805674a39c639e1cbcd13e66ae0b44dba78688115f02ef7f0`。与旧 `7e93048` 中同路径对象比较，已有文件仅本模块 C、CMakeLists.txt、README.md 不同，另有后来加入的 LINUX_SOFTWARE_CHECK.md；参考内核、vendor、固定配置和公开向量未改。C 入口先 SET_DUMPABLE=0、GET 核对，失败在分配采集记录、生成秘密及读取 MSR 前退出；成功普通路径仍使用原记录协议和完成判定。该源码补丁此前的独立只读审查没有未解决阻断项。

## 真实编译与原始测试

run.json 记录 Linux、nss-m、6.17.0-35-generic、x86_64；两配置的 CMake 原编译器记录均为 GNU 13.3.0。configure/build/test 六份实际结果均退出 0。普通与动态配置各有六条编译命令，均使用 C11、严格警告、Werror 和 baseline_config.h，没有缺陷变体宏或补丁路径。ASan/UBSan 仅在动态配置的编译与链接中启用；普通 worker 链接原 reference 静态库。

直接读取两份 LastTest 原日志，均为 3/3：原纯软件自检、自进程转储限制检查、参考 NIST KAT。两份进程检查实际输出 process_dumping_disabled=true、errno=0，并明确该入口没有硬件读或密码工作负载。KAT 则实际验证 25 keygen、25 encaps、10 decaps，以及公钥/私钥校验、接口边界和系统随机往返；这些功能操作不被混写成普通 G2 采集。两份测试日志均保留各自的实际命令、工作目录和通过结果。

## 四份实际 ELF

四份原始 ELF 的头均为 ELF64、小端、机器号 62；实际长度及重算摘要与 artifact-digests.json 相同。

| 配置与程序 | 字节数 | SHA-256 |
| --- | --- | --- |
| normal / frequency_workload | 225384 | `023f56460a8dc4971e8132a22c5734ca0844314d3d71b8bc3b129a424e9ee69b` |
| normal / frequency_reference_kat | 207496 | `c61afe0eb01ae45355e53ff84d43dd25b0cdc5b60a980124cfde5efcc3429a57` |
| sanitize / frequency_workload | 571976 | `ba9b0861a0669b86f5f6f59f008f0a1d07023746a9e9ec56694c9ca0a050b509` |
| sanitize / frequency_reference_kat | 475864 | `f2229d30a2c104773613cd17f8ec0c0b39089adf4f5bf8deabeb860bb79e6d8f` |

后续管理器只能 pin 本次 normal worker 的路径、摘要和受保护副本；不得继续使用旧 7e worker 或将动态产物用作正式计时证据。本次只解析 ELF 头、摘要和编译记录，没有在 Mac 执行 Linux ELF，也不把这些静态检查称为二进制形式化等价证明。

## 可用范围与来源限制

实际编排记录将普通入口、MSR 读取标为 false，将独立 process-safety 入口标为已测试；临时和缓存环境均指向 Cry/window-source-c0e5990 的子目录。orchestration-source.py 是保存的当时编排源，重算摘要为 `27edcdba51c64f4204adf7c3fba8919041a303aafed384d9516fb8805c0a5a46`；按原说明它执行时尚未提交，不以之后的报告提交回填其来源。

转储限制测试证明普通 Linux 进程入口中的自设置及 GET 核对成功，不证明已经运行 reference 长负载；该保护从 C 入口设置成功时生效，不覆盖动态加载器及进入 C 以前的崩溃。guard 的 gate/pidfd、活进程取消、输出配额、ENOSPC 恢复及窗口分析仍需单独完成并核查原件。这里没有实测频率、差异显著性或统计总体结论，R02/R04 均保持未由本次证据签收。
