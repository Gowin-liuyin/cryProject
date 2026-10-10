# 六进程普通参考完整调用证据

2026-10-10，固定提交`7ca9320f6aeb525daba6169ffb0135be0c31779a`在指定Linux/x86_64完成E1/E2两次近邻连接批次，各三个普通collector、每份25000预热+25000主调用。共300000计时调用、600000采样读钟，Linux资格另计132完整算法及六setup，总Linux完整算法300138。六原CSV/36行C描述及六摘要独立全量一致；两次SSH已关闭。见[实际结果](../../../research/aris-ordinary-repeatability-20261010/RESULTS.md)及[声明判定](../../../research/aris-ordinary-repeatability-20261010/RESULT_TO_CLAIM.md)。

## 完整原归档与可读子集

| 原归档 | 字节数 | SHA-256 | 普通成员及清单 |
|---|---:|---|---|
| [E1](e1-originals.tar.gz) | 5377139 | `f53d0a8e22cc7b9c27d5390ef31ec98ae333a4404afda3bb6c1c4f4ec2d763d1` | 708成员/707载荷记录 |
| [E2](e2-originals.tar.gz) | 8278790 | `58dad05265dc0c4c3d02285060dc344518d44366ffe3c45118a0023610d5ac28` | 732成员/731载荷记录 |

gzip CRC32分别为12ac336b/f3e2b53b，完整tar头及末尾、唯一安全普通成员、全部长度/SHA及解包字节独立核对通过。E2包括全部708份同字节旧E1文件，不能当作新增六份采集；旧E1清单只覆盖旧快照，新E2清单覆盖当前全树，两压缩包均保留不改。每包清单排除自身，但归档包含清单。

全部六份原CSV在完整归档内，路径为`batches/e1/output/P1.csv`至`P3.csv`及`batches/e2/output/P1.csv`至`P3.csv`。`selected-originals/`只保存从E2提取的123项同字节可读子集，包含统计/元数据、两个快照的清单和命令、环境、检查日志、编译/link/反汇编及关键源；不冒充完整732文件树。子集每项的归档名、长度和摘要见[SELECTED_ORIGINALS](SELECTED_ORIGINALS.json)。本证据是保留真实机器/路径的内部原件，不是匿名发行视图。

## 直接阅读入口

| 对象 | 入口 |
|---|---|
| E1三份原C表 | [P1](selected-originals/batches/e1/output/P1-analysis.csv)、[P2](selected-originals/batches/e1/output/P2-analysis.csv)、[P3](selected-originals/batches/e1/output/P3-analysis.csv) |
| E2三份原C表 | [P1](selected-originals/batches/e2/output/P1-analysis.csv)、[P2](selected-originals/batches/e2/output/P2-analysis.csv)、[P3](selected-originals/batches/e2/output/P3-analysis.csv) |
| E1元数据及摘要 | [P1 meta](selected-originals/batches/e1/output/P1.json)、[P2 meta](selected-originals/batches/e1/output/P2.json)、[P3 meta](selected-originals/batches/e1/output/P3.json)；[P1 summary](selected-originals/batches/e1/output/P1-summary.json)、[P2](selected-originals/batches/e1/output/P2-summary.json)、[P3](selected-originals/batches/e1/output/P3-summary.json) |
| E2元数据及摘要 | [P1 meta](selected-originals/batches/e2/output/P1.json)、[P2 meta](selected-originals/batches/e2/output/P2.json)、[P3 meta](selected-originals/batches/e2/output/P3.json)；[P1 summary](selected-originals/batches/e2/output/P1-summary.json)、[P2](selected-originals/batches/e2/output/P2-summary.json)、[P3](selected-originals/batches/e2/output/P3-summary.json) |
| 实际接受与命令 | [E1 state](selected-originals/batches/e1/run-state.json)、[35 commands](selected-originals/batches/e1/commands.json)、[E2 state](selected-originals/batches/e2/run-state.json)、[9 commands](selected-originals/batches/e2/commands.json) |
| 原始环境 | [E1 before](selected-originals/batches/e1/before-environment.json)、[after](selected-originals/batches/e1/after-environment.json)、[E2 before](selected-originals/batches/e2/before-environment.json)、[after](selected-originals/batches/e2/after-environment.json) |
| Linux实际资格 | [普通verbose5/5](selected-originals/batches/e1/logs/ordinary-ctest.stdout)、[动态verbose5/5](selected-originals/batches/e1/logs/sanitize-ctest.stdout)、[普通JUnit](selected-originals/build-ordinary/tests.xml)、[动态JUnit](selected-originals/build-sanitize/tests.xml) |
| 构建与机制 | [普通compile](selected-originals/build-ordinary/compile_commands.json)、[动态compile](selected-originals/build-sanitize/compile_commands.json)、[普通collector反汇编](selected-originals/batches/e1/logs/ordinary-reference_repeatability-objdump.stdout)、[完整ELF审查](review-artifact/elf-build-check.json) |
| 全量独立整数复核 | [报告](review-numeric/INDEPENDENT_NUMERIC_REVIEW.md)、[verification](review-numeric/verification.json)、[冻结外部oracle](review-numeric/independent_numeric_oracle.py) |
| 独立实物与生命周期 | [报告](review-artifact/ARTIFACT_REVIEW.md)、[verification](review-artifact/verification.json)、[归档与源](review-artifact/archive-source-check.json)、[命令/元数据/结束](review-artifact/lifecycle-meta-check.json) |
| 独立结果到声明 | [报告](review-claims/RESULT_TO_CLAIM_REVIEW.md)、[verification](review-claims/verification.json) |

独立数学参照核对300000行、5400000字段、600000读钟值、36行360数值及六完整摘要，差异为空；核心产品统计仍为固定C程序。归档/Git/ELF/JUnit/全部命令/52PID由另一审查负责，不混称一次审查重复执行了全部算法。三个审查均为同模型内部独立代理，外部Codex MCP不可用、pending，不称外部同行评审。

## 两次连接及结束回执

E1的[调用](transport/e1-invocation.json)、[最终stdout](transport/e1-remote.stdout)、[下载字节核验](transport/e1-download-verification.json)、[39PID/35组后查](transport/e1-postcheck.json)及[关闭](transport/e1-close.json)先完成。随后[新认证与资源回读](transport/e2-login.json)及[E2调用](transport/e2-invocation.json)使用不同控制socket、同源同boot同六ELF，不重复资格；[E2下载核验](transport/e2-download-verification.json)再次确认708旧E1字节保持。

最后[原后查stdout](transport/final-postcheck.stdout)与[后查JSON](transport/final-postcheck.json)精确覆盖2管理PID+44命令leader+6collector共52个不同原PID，全不存在；44个自有组全部absent、调用者mask0—31。[最终E2关闭回执](transport/e2-close.json)退出0、控制socket不存在。后查为根代理真实查询，独立审查只读其原件，没有再次SSH。远端query UTC与本机close UTC来自不同时间域，不能直接排序；先查成功再关闭由控制器调用顺序证明，采样间隙使用同boot RAW边界。

全部云端源/构建/结果/缓存/临时树为`/home/nss-marker/yhr/Cry/reference-repeatability-7ca9320-8509a8fb4e43b880/`；同级`.upload.tar`、`.e1.tar.gz`和`.e2.tar.gz`也在Cry内。四路径物理位置已核对，ROOT732普通文件且无链接，两个archive SHA未变。仅自身CPU2亲和性/转储设置，129频率文件前后相同为快照，不证明独占或连续恒频；不泛化为全机无其他任务。

## 行政勘误与证据范围

可变本地[deployment原摘要](transport/deployment-before-count-correction.json)在最终stage更新后残留初始化的`remote_collectors_started=0`。独立审查指出后保留该完整字节，依据两原state的3+3改为6，见[勘误及前后SHA](transport/deployment-sidecar-correction.json)和[当前sidecar](transport/deployment.json)。远端原值/state/两tar完全未改，这不构成一次实验失败、再次启动或额外采样。

C摘要中的collector元数据、退出、完整接受三个false标志保持原样，管理层另核接受；软件正确、原件完整、观察范围、物理精度及正式统计前提各有边界。六个主中位数跨度40ns不作误差界，不扣空窗、不比较旧G2成算法提升，不由此签收R02/R04。准备原件见[采集工具](../preparation/README.md)及[管理工具](../runner-preparation/README.md)；新封存清单为[SHA256SUMS](SHA256SUMS)。旧证据、49页报告及925项包保持原身份。
