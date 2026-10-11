# 确认协议 v3（种子 31415926）

协议在采集前冻结，提交 `4a27aeda95a0961e1e58340ecd41ebc7082e1313`，SHA-256 `77e81746aa0f7c8768c71edd053ff2648f2cf68c46465708e75ddef1a7d0df2a`。预算是计划起点 20 个会话、每类 5000 次，α=0.01，Holm。v1 与 v2 的未拒绝记录不在这里重分析。

远端目录 `/home/nss-marker/yhr/Cry/seven-capabilities-20261011/run-confirm-31415926/`。主机 `nss-m`，`taskset -c 2`。决策文件的本地 SHA-256 与远端一致。

| run_id | 主效应 | p | Holm | Wald |
|---|---:|---:|---|---|
| `v3-vulnerable` | −5.467 | 0.00287 | yes | −8.60 到 −2.33 |
| `v3-hardened` | −1.535 | 0.197 | no | −3.78 到 0.71 |
| `v3-rollback` | −2.976 | 0.026 | no | −5.39 到 −0.56 |

`v3-vulnerable` 的 s1 元数据：`resolution_counts=1`，`empty_window_max_counts=110`，`message-zero_unique_ciphertexts=1`。全表 500001 行留在远端，没有拉回仓库。

检测成立之后，同一确认种子的诊断追踪 `trace-rank.txt` 给出 `single_root_cause=not_asserted`。Top-1 是 `baseline_stage_reencrypt`，Top-2 是 `baseline_stage_reencrypt_message`，Top-3 是 decrypt。真阶段在 Top-3 内。这是 1 次追踪，分母是 1，不是 20 个会话。

同一 Holm 门下，掩码构建不再拒绝，主效应绝对值从 5.47 降到 1.54。随后新目录 `build-v3-rollback` 重新构建的 vulnerable 没有恢复 Holm 拒绝。回滚恢复不成立。`iid_upgrade=refused`，`constant_time_upgrade=refused`。这三份二进制没有在本轮重跑公开 KAT。R02、R04 不因此升级。
