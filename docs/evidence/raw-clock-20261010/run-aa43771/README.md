# RAW空窗口实际采集证据

2026-10-10，部署提交`aa437714e023e2aef8301a925c33949647790517`在指定裸金属顺序执行三个普通C11进程，各1000预热及100000主pair，合计303000pair、606000次采样读钟。三次均完整接受，没有密码算法调用或追加采样。结果为[新空窗口有限描述](../../../research/aris-raw-clock-20261010/RESULTS.md)，不认证绝对精度、恒频、iid、完整调用重复性或R02/R04。

## 原件保存范围

[remote-originals.tar.gz](remote-originals.tar.gz)是云端原归档的同字节副本，4454198字节，SHA-256为`e6dfd03f03e1e2e4e28a4eb0c251a8f7d684745980727843263e4ad8ff1870e6`。包含496个安全、唯一、普通文件成员，495项清单记录及清单自身；所有成员载荷共32404397字节。gzip CRC、tar头校验、全部成员长度/SHA及解包字节经独立核对。该压缩包保留完整源、普通/动态构建及四ELF、日志、三份原始CSV和输出。三份大CSV的成员名及摘要为：

| 成员 | 字节数 | SHA-256 |
|---|---:|---|
| `output/P1.csv` | 9688106 | `a157354aa86196cea2bd24e03f66aca8e5b9511a7d9b92bfc62f3b9366fa58ad` |
| `output/P2.csv` | 9688108 | `48937d520c06009da5ca5d6be79b8c33f0056107a91f1dbbd5fe73bab31a79c8` |
| `output/P3.csv` | 9688102 | `d43ca663205c3353c37413e1c9d61b4fef5def5acc6307992fbd5758583d5a0e` |

`selected-originals/`仅为71份可直接阅读的同字节子集，不是完整解包树。其[映射清单](SELECTED_ORIGINALS.json)列出每个成员、原名、长度和摘要；完整495项载荷清单见[原manifest](selected-originals/manifest.json)，原值CSV仍完整位于压缩包中。该证据尚非匿名发行视图，真实机器、用户及云端路径有意保留。

## 阅读入口

| 对象 | 直接入口 |
|---|---|
| 三个原C统计表与摘要 | [P1表](selected-originals/output/P1-analysis.csv)、[P2表](selected-originals/output/P2-analysis.csv)、[P3表](selected-originals/output/P3-analysis.csv)；[P1摘要](selected-originals/output/P1-summary.json)、[P2摘要](selected-originals/output/P2-summary.json)、[P3摘要](selected-originals/output/P3-summary.json) |
| collector完整元数据 | [P1](selected-originals/output/P1.json)、[P2](selected-originals/output/P2.json)、[P3](selected-originals/output/P3.json) |
| 运行接受与实际步骤 | [run-state](selected-originals/run-state.json)、[29条commands](selected-originals/commands.json)、[启动声明](selected-originals/run-claim.json) |
| 前后真实环境 | [before](selected-originals/before-environment.json)、[after](selected-originals/after-environment.json) |
| Linux普通及动态CTest | [普通2/2](selected-originals/logs/ordinary-ctest.stdout)、[ASan/UBSan2/2](selected-originals/logs/sanitize-ctest.stdout)；两配置库存及LastTest也保留 |
| 编译和产物机制 | [普通编译命令](selected-originals/build-ordinary/compile_commands.json)、[动态命令](selected-originals/build-sanitize/compile_commands.json)、[普通collector反汇编](selected-originals/logs/ordinary-raw_clock_calibration-objdump.stdout)、[ELF核验](review-artifact/verification.json) |
| 全量独立整数复核 | [审查意见](review-numeric/INDEPENDENT_NUMERIC_REVIEW.md)、[核验JSON](review-numeric/verification.json)、[外部算术参照](review-numeric/independent_numeric_oracle.py) |
| 独立产物与结束补审 | [原产物审查](review-artifact/ARTIFACT_REVIEW.md)、[后续结束补审](review-artifact/POSTCHECK_REVIEW.md)、[补审JSON](review-artifact/postcheck-verification.json) |
| 独立结果到声明审查 | [意见](review-claims/RESULT_TO_CLAIM_REVIEW.md)、[核验JSON](review-claims/verification.json) |
| 认证失败及后续成功 | [部署记录](transport/deployment.json)、[首次失败stderr](transport/upload.stderr)、[重新认证后上传回执](transport/upload-reauth.stdout) |
| 归档回执与本地下载 | [remote stdout](transport/remote.stdout)、[实际调用及退出](transport/remote-invocation.json)、[download](transport/download.json)、[字节核验](transport/archive-byte-verification.json) |
| 最终只读检查及SSH关闭 | [postcheck](transport/postcheck.json)、[原stdout](transport/postcheck.stdout)、[SSH关闭回执](transport/ssh-close.json) |

C分析器只读CSV，其原摘要的`collector_stderr_checked`、`collector_exit_checked`、`complete_metadata_acceptance`均保持false；管理层分别核对退出、元数据和C输出后才接受完整case，不篡改C原摘要。独立算术参照核对303000行/4545000字段/606000读钟值、18行180数值及三份完整摘要，全部一致；它不取代产品C入口。三个审查均为同模型内部独立代理，外部Codex MCP不可用、pending，不称外部同行评审。原产物审查形成时postcheck尚待，其后新增补审单独关闭该项，不追改旧评语时点。

## 云端位置与结束范围

源码/构建/结果/缓存/临时文件均在`/home/nss-marker/yhr/Cry/raw-clock-aa43771-fe4ffb3f92f3630e/`，上传载体和完整归档分别为同级同名`.upload.tar`、`.tar.gz`。三个路径的实际物理位置均等于记录路径且无符号链接，云端原件保留。本轮只普通用户自身CPU2亲和性，没有调频、隔离、MSR、root或其他全局配置写入；前后129个可见频率文件相等不证明隐藏状态或整段恒频。

首次复用连接过期使上传在远端helper执行前退出255；实际密码认证后上传0、远端管理0，只启动既定三次采样。口令不入证据、参数或文件。管理程序29个leader已回收、对应组均确认消失；结束回执逐一核对监督者1、命令leader29和collector3共33个不同原PID均不存在，调用者亲和性0—31，云端归档SHA保持。SSH关闭退出0、本地控制套接字消失。后查没有独立记录精确查询UTC，保留现有回执范围，不补造时间。独立补审读取的是根代理真实后查原件，没有额外SSH。

准备记录分别在[采集器资格](../preparation/README.md)和[单次管理资格](../runner-preparation/README.md)。本目录的新封存清单为[SHA256SUMS](SHA256SUMS)，排除清单自身。旧G2、旧证据、49页报告及925项包保持原字节。
