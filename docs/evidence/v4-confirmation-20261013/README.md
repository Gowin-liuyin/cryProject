# v4 确认采集在覆盖率门停止

2026-10-13 在裸金属 `nss-m`（Linux 6.17.0-35-generic，x86_64，`systemd-detect-virt=none`）按开发阶段导出的 `S=40`、`R=2` 启动确认采集。工作根是 `/home/nss-marker/yhr/Cry/v4-confirmation-8709dfe`。采集程序来自提交 `8709dfe09955f44bf0e79311d9975f733069b752`，摘要 `d2103bcec9385c423b5f52775806c736457bc1ac16862c3c6384ea784ba3adf6`。窗口程序在读回重试提交 `612ad4e05486cfab00fa04375731085891f8d15c` 之后重编，摘要 `819beac18380a8d854588314f23130f620ecd67d367e29dc325a11e760cad1f7`。协议文本仍是 `9cf0be4c10ccc2a957bd123b7ab884ee5641d5e6`。

窗口只把 CPU2 和 SMT 兄弟 CPU18 的 `scaling_min_freq` 与 `scaling_max_freq` 请求为 4300000 kHz，不改 governor、boost、EPP 或其他 CPU。兄弟列表是 `2,18`。进入时 32 个逻辑 CPU 都是 `powersave`、min `2982259`、max `5756452`。每次窗口退出后这 32 行策略与进入时相同。

两秒、绑在 CPU2 上的空载忙等试运行覆盖率是 `0.91304875329565227`（旧窗口二进制，当时读回过快，退出码 4，但随后的全机策略已回到基线）和 `0.88888173607387222`（重试读回后的窗口，退出码 0）。两次都低于协议阈值 0.99。这不是 2026-10-10 的 APERF 几何覆盖，也不关闭 R02 或 R04。

正式确认只跑了种子 `20261014001` 的会话 `s01`。采集进程退出码 0，唯一密文检查通过，128 行正式调用，空窗中位数 20，亲和 `cpu2`。两次 `scaling_cur_freq` 采样是 3341588 kHz 和 2179456 kHz，都在带外，`coverage_fraction=0`。按预先写好的停止规则，没有继续 `s02`–`s40`，也没有换种子补抽。SMT 起止快照在 `sessions/s01/smt-sibling-stat.txt`。

`v4_analyze confirm-sessions` 跑了两次，结论逐字节相同：`status=stopped_session_count`，`primary_token=not_run`，会话数 1。会话数检查先于覆盖率检查，所以分析令牌写的是会话数停止；现场停止原因是覆盖率 0，见 `log/confirm-exits.txt`。效应表里这一次的组效应是 `-131.53125` 个计数，不构成 Holm 检验。结论里的 `holm_rejected=no` 和 `direction_consistent=no` 是停止路径的输出，不是方向判定。

交替对照没有开始。同一窗口下，短解封装会话的采样覆盖率是 0，两秒忙等也低于 0.99。
