# 种子 31415926 的 20 次会话诊断

远端目录 `/home/nss-marker/yhr/Cry/seven-capabilities-20261011/trace20-31415926/`。对象是已经 Holm 拒绝的 vulnerable 确认，协议 v3，种子 `31415926`。每个会话一次 `diagnostic_trace --timing`，200 个样本。排名器的输入只有 `end_to_end_detected=yes`，没有补丁名，也没有真值列。

`summary.txt` 写明 `session_count=20`、`denominator=20`。重加密进入 Top-3 是 20/20，`baseline_stage_reencrypt_message` 进入 Top-3 是 20/20，两者同时进入也是 20/20。20 个会话的 `single_root_cause` 都是排名器输出的 `not_asserted`。逐会话 Top-3 在 `summary.txt`，排名原文在 `sessions/s01` 到 `sessions/s20` 的 `rank.txt`。`events.csv` 留在远端。

早先那一次追踪仍在 `ryzen-confirm-v3/trace-rank.txt`，不改。书面分母以这 20 个会话为准。`iid_upgrade=refused`，`constant_time_upgrade=refused`。R02、R04 不因此升级。
