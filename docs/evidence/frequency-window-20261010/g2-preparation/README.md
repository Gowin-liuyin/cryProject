# G2 长工作进程及离线分析的冻结准备

2026-10-10。本目录只登记实际路径执行以前的准备，不改旧 G1、7e 或 c0e 软件证据。
两个真实 case 尚未运行，执行合同见 [固定计划](../../../research/aris-frequency-window-20261010/EXPERIMENT_PLAN.md)。

| 对象 | 固定来源及状态 |
|---|---|
| C11 普通 worker | 源 c0e5990，正式 Linux ELF `023f56460a8dc4971e8132a22c5734ca0844314d3d71b8bc3b129a424e9ee69b`；普通／ASan各3/3及原件已单独封存 |
| 管理器 | 提交 `0ba4cd7c1f41c700a7fdef2b277cbf7f39e74bac`，源码 SHA-256 `8616a0747d7a8e3b28e5af6da86bfdee5b2bf2f84821989c163136ec09479af4` |
| C11 分析器 | 提交 `dd67390f1e41d76624bf3a8854feacacfb8d1f85`，C SHA-256 `5c028abf419df5b5459c167469f44724faba12542b446799c5c5fc6b02d5a9f4`；规则在真实数据前冻结 |
| 本机检查 | 管理CTest1/1，分析普通／ASan各1/1；原LastTest及工具返回见local-checks与local-check-tool-results.json |
| 真实Linux检查 | Python3.12，GNU13.3；管理1/1、分析普通／ASan各1/1，配置／构建／测试共8步全部0；没有真实guard、密码负载或硬件数据分析 |

完整 [Linux软件原档](window-management-0ba4cd7-software.tar) SHA-256 为
`f8d495de5318e46241dbaa6190ac58114e0cae627c94e6cf4085cfc7fbdf6a32`，609个唯一常规成员，
608项清单载荷全部重算一致，六份源文件与Git 0ba4cd7及解包文件相同。
两分析器ELF为x86_64，普通摘要 `f25d556a44065b794b967b9e7604a46beb340acc4dcb2c2e3036ad2aa3f06d43`，
动态摘要 `23950d6fe8660436a703416eea84c5ada93a1920523c0af970ae981ea2c8e5c3`。
原件在 `/home/nss-marker/yhr/Cry/window-management-0ba4cd7/`，同级同名 `-software.tar` 是导出。
临时与缓存均在新树内；[编排源](linux-orchestration-source.py) 是此次实际发送的原文本，执行时尚未提交。
[linux-check](linux-check/run.json)保留八步、临时环境与原日志；[核对结果](linux-software-verification.json)单独登记。

新管理器保留原入口，新增固定ELF保护复制、W放行、实际exe身份核对、worker与guard双pidfd，
正常结束及运行中EOF分别登记。先终止并回收自己的child，才能恢复配置；输出配额只加在child。
ENOSPC/EDQUOT例外只允许持有精确case路径、原值授权及已知状态的恢复，缺日志使证据不完整。
本机及Linux自检只用良性替身，覆盖提前EOF和至少0.25秒后的注册EOF、R、超时、失败、日志及
输出失败回收、磁盘日志边界与旧回归；没有故意填满实机磁盘。单个CTest中有多个边界分组，
不把分组数量写成独立CTest数。

分析器从完整schema核对到逐窗口整数判定，手算完整128调用fixture因4秒gap明确得到no，
并核对缺／截断summary、重复记录及失败末时钟等反例；这些fixture不是伪硬件结果。
独立分析源码复核通过，只修正README末时钟分母措辞，冻结C程序及阈值未据真实结果调整。

[产物边界检查](BINARY_REVIEW.md)及[独立准备审查](G2_PREPARATION_REVIEW.md)支持固定普通ELF的
入口和计时顺序、管理生命周期及存储回退范围；同模型独立代理不冒称外部Codex或跨模型审查。
真实root只读预检确认初始user/mount/PID namespace、CAP_SYS_PTRACE和两个root MSR字符设备，
CPU0—31可用且隔离为空、Cry可用空间超过2GiB；[实际源](root-precheck-source.py)及
[实际返回](root-precheck-tool-results.json)不含认证内容，未读取MSR或写配置。

上述准备不证明真实长worker曾运行、取消路径曾触发、硬件频率达标、每次调用恒频或R02/R04
已签收。后续真实原件须另建目录，保留全部负面结果，不能回写本准备记录为已完成实验。
