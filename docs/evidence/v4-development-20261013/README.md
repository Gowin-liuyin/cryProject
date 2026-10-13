# v4 开发采集与功效导出

2026-10-13 在裸金属 `nss-m`（`10.144.144.5`，Linux 6.17.0-35-generic，x86_64，`systemd-detect-virt=none`，32 线程）完成协议 `v4_group_confirmation_20261013` 的开发阶段。工作根是 `/home/nss-marker/yhr/Cry/v4-development-8709dfe`，`readlink -f` 与该路径相同。没有写 governor、boost、EPP、min/max 或其他 CPU。CPU2 的 governor 保持 `powersave`，`scaling_min_freq=2982259`，`scaling_max_freq=5756452`；当前频率前后不同，是读数本身在变。

源码提交是 `8709dfe09955f44bf0e79311d9975f733069b752`。协议冻结提交仍是 `9cf0be4c10ccc2a957bd123b7ab884ee5641d5e6`，协议文件 SHA-256 见 `log/protocol-sha256.txt`，与冻结提交中的 `PROTOCOL.md` 相同。源包 SHA-256 为 `81a8e732aae0db11d86954919233c647452a6c9f71c62e45391a686a33067460`。`SOURCE_EXPORT.sha256` 在远端 `shasum -a 256 -c` 通过，清单摘要 `d8e46827f10a62fd6701799eebdbeebdc82de3bdb8f2ff821351506618259508`。早先提交 `9cf0be4` 的干净配置漏链 libm，失败树留在 `/home/nss-marker/yhr/Cry/v4-development-9cf0be4`，本次不覆盖。

GCC 13.3.0，CMake 3.28.3，preset `baseline`。`encoder_branch/v4_collect` 的链接行以 `-lm` 结束。独立 `sha256sum` 与八份 `meta.txt`、`binary.sha256` 都是 `cc571992df7858cceb5013df440374c5b8c316a73c7cdc6e715956d7e5303924`。`v4_analyze` 摘要是 `b68af2f4db19664409066d309c2fdf8a4a976fd6c0f3919d842497b5119c2b20`。构建身份按源导出清单记录，不是 git 提交号；git 提交号写在 `log/environment.txt`。

八个会话种子 `20261013001`–`20261013008`，`R=2`，每会话 128 次正式解封装、256 次空窗，进程亲和 CPU2，退出码都是 0，唯一密文检查 `passed`。正式调用共 1024 次。`date` 的起止都是 `2026-10-13T03:28:30Z`，分辨率是 1 秒。失败会话没有出现，因此没有补抽。

`v4_analyze reduce-effects` 与两次 `power` 都在这台机器的同一二进制上运行，两份 `conclusion.txt` 逐字节相同。状态 `exported`，族水平 0.01，目标把握度 0.9，导出 `S=40`、`R=2`。八个会话效应均值 `-133.376953125` 个 `CLOCK_MONOTONIC` 计数，样本标准差 `207.06945898045791`（除数 7）。`S=40` 的把握度 `0.90698063131748807`，`S=39` 为 `0.89775065852090041`。八个效应并不全同号：`s04` 为 `195.890625`，其余七个为负。开发导出不要求方向一致；方向一致只在确认阶段作门。这不是确认结论，也不是恒频或 R02/R04 签收。

本机 Apple 上的同一源码 `v4_analyze` 重算效应表与远端逐字节相同，两次功效输出彼此相同，并且同样导出 `S=40`、`R=2`。把握度末位与远端 glibc 不同（`0.9069806313174873` 与 `0.8977506585209013`），阈值两侧的判断不变。留档计算以远端结论为准。
