# 3.6 节冻结抽签下的 C04 重算

规则来自已冻结的 `docs/research/v4-protocol-20261013/PROTOCOL.md` 第 9 节，种子 `20261013`。块 `b=1..6` 的初始状态是 `20261013+b` 经过一次 splitmix64，再对 3000 条记录无放回抽取 24 个下标，按抽取顺序组成 12 对。差是偶数次抽出的耗时减去下一次抽出的耗时。4096 种标签、含等值的上尾和分母 4096 沿用 C04：候选走 `compute_controlled_result`，独立核验走同一绝对和的排序秩。两边不一致时程序失败。本次 `candidate_oracle_mismatches=0`。

入口是提交 `c51200ef1490e9fa2d72bc8fe86f90ab3a297d1b` 的 `calibrate_controlled --reference-labels-redraw`。输入是 `docs/evidence/native-final-20261007/performance` 的六份普通参考 CSV、meta 和 cost。两次运行的 `conclusion.txt`、`selected.csv` 和 `raw.csv` 逐字节相同。新解封装调用为 0。这是对已封存时间的离线重算，不是新的 x86_64 Linux 计时。

| 参考运行块 | 本规则条件拒绝数 / 4096 | 条件概率 |
|---|---:|---:|
| 1 | 38 | 0.009277343750 |
| 2 | 38 | 0.009277343750 |
| 3 | 38 | 0.009277343750 |
| 4 | 36 | 0.008789062500 |
| 5 | 40 | 0.009765625000 |
| 6 | 40 | 0.009765625000 |

`raw.csv` 共 24576 行标签。`raw_digest=2773075970a58203136017c02bd018cdd932938dd6ce7bf58d8caae0de48dfe1`。

旧规则“取原序 0..23”的六行条件拒绝数仍是 40、40、40、38、40、38，文件在 `docs/evidence/reference-label-control-20261007`，本次没有改那些字节。两套数字都是给定时间对上的后赋标签条件计数，分母是 4096，不是真实密文总体的误报率，也不关闭 R02 或 R04。

确认采集停在覆盖率门，会话数不足。会话效应的 QQ 图、Shapiro-Wilk 和会话内滞后 1 自相关没有按这项重算产生。
