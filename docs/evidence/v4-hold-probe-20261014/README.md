# 频率保持探测停止

2026-10-13 在 `nss-m`（`systemd-detect-virt=none`）上执行规则 `v4_frequency_hold_20261014` 的空转探测。规则文本是 `docs/research/v4-protocol-20261014/PROTOCOL.md`，冻结提交 `41f0665a6d0e7f76505bb24e34128f1b09dd9268`。窗口实现提交 `bf79558f59205add06053821f7179680b3aae401`，GCC pedantic 修正是 `1060947c02b5ace0af32b0cecfbe3fb23a464c40`。`20261013` 的协议文件没有修改。

远端目录是 `/home/nss-marker/yhr/Cry/v4-hold-probe-bf79558`。目录名用的是上传时的提交，实际编译的 `src/v4_window.c` SHA-256 是 `71139957840cad4afeade53a9220886fa0134bf242d1c20e3a600b8e6f514ae7`，与本地 `1060947` 的该文件一致。`v4_window` SHA-256 是 `49667d7ed233f86f6d2add856769ff0571ddb52ecbd23313591c167d026ff1fc`，`v4_hold_spin` SHA-256 是 `2f559ba0f68ea6d2c5cfeffff11b34b72aabc40fb123e80e7cea46cc1013bf28`。

探测只空转，没有解封装，没有使用确认种子。请求是：全局 boost 写 `0`，CPU2 和兄弟 CPU18 的 governor 与 EPP 写 `performance`，min 与 max 写 `4300000` kHz。带仍是 `4257000..4343000` kHz，阈值仍是 `0.99`。连续 3 次带内读数之后才启动 40 ms 空转。

前 3 次覆盖率是 1。第 4 次覆盖率是 `0.66671003122281247`。四次读数是 4300000、4346969、4310980、4330207 kHz，其中 4346969 高于带的上沿。按冻结规则停在这里，第 5 至第 12 次没有做。`probe_pass=no`。

进入和退出时，32 路 CPU 的 governor、EPP、min、max 以及全局 boost 逐项相同：boost 为 `1`，governor 为 `powersave`，EPP 为 `balance_performance`，min 为 `2982259`，max 为 `5756452`。`policy_match=yes`。

这次没有 Holm 判定，没有方向检验，没有交替对照，也没有 QQ、Shapiro-Wilk 或会话内自相关的数值。不放宽 0.99，不放宽带，不改请求后再探。R02 与 R04 仍不因此关闭。
