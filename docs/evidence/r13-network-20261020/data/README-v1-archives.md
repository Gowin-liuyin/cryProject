# v1 副本：口径改写前的原件（按 `holm.m8.csv` 的同一做法留存）

2026-10-21 第 9 轮独立复核指出：本目录里有三个文件在复核过程中被**就地改写**了，
而旧字节只留在 git 历史里，树内没有另存——与 `docs/evidence/r02-r04-close-20261016/`
对事前族做的事（`holm.csv` 原样保留、事前族另存 `holm.m8.csv`）不一致。

这里按同一做法补上旧版副本：

| 现行文件 | v1 副本 | 改写内容 | 旧版出处 |
|---|---|---|---|
| `detection-budget.csv` | `detection-budget.v1.csv` | `required_n_per_class_for_reference_effect` 整列口径由旧公式改为 `n = 2·(1.96·SD/|效应|)²`（原始测量列未动） | `1fedceb2^` |
| `class-comparison.csv` | `class-comparison.v1.csv` | `p_value` 列浮点末 1–2 位重算（mean / SE / CI / pooled_sd / mde 未动） | `1fedceb2^` |
| `recovery-check/*.txt` | `recovery-check.v1/` | 用**收紧后的** `find -maxdepth 2` 判据复跑，原件被替换（`after_cur_freq_khz` 5662410 → 5607841；/tmp 判据文字更严） | `357b2cbe^` |
| `analysis.json` | `analysis.v1.json` | 采集期原样：`runs_root` 写的是**云端绝对路径**（已脱敏为相对 `runs`），另补了 `reference_local_effect_ns` / `required_n_convention` 两个口径字段 | `1fedceb2^` |

**口径改写本身是必要的**（旧口径与正文不一致），问题只在于没留旧版。
这些 v1 副本只作留痕，**不作为结论依据**；结论一律以现行文件与
`docs/evidence/r13-network-20261020/RESULT.md` 为准。
