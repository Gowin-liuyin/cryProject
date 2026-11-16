# R20 形状/方差检验探索性回放

日期：2026-11-16  
输入：`docs/evidence/r02-r04-close-20261016/raw/*/csv/*.csv`（4 个 M1 两列宽表，各 10000 对调用）  
工具：`platform_shape_stats`（brown_forsythe / ks_two_sample / within_class_second_order_zero / within_class_second_order_ones）  
口径：alpha=0.05；p<0.05 记 flag，否则 clear；全部为族外探索性结果，不进 Holm。

| 输入文件 | Brown–Forsythe p / flag | KS p / flag | 类内二阶 zero p / flag | 类内二阶 ones p / flag |
|---|---|---|---|---|
| `docs/evidence/r02-r04-close-20261016/raw/cpu-6/csv/fixed-message-zero-ones.csv` | 0.393069640795225 / clear | 1 / clear | 1.42887125949079e-13 / flag | 4.31795230244806e-18 / flag |
| `docs/evidence/r02-r04-close-20261016/raw/cpu-6/csv/vulnerable-message-zero-ones.csv` | 0.467155903341311 / clear | 7.08693366864507e-60 / flag | 9.94638887798774e-07 / flag | 2.90884437477541e-10 / flag |
| `docs/evidence/r02-r04-close-20261016/raw/seed-424242/csv/fixed-message-zero-ones.csv` | 0.657621560001214 / clear | 0.237294612425776 / clear | 2.50645140874741e-22 / flag | 2.9640806573204e-23 / flag |
| `docs/evidence/r02-r04-close-20261016/raw/seed-424242/csv/vulnerable-message-zero-ones.csv` | 0.568669950575159 / clear | 8.55689895749391e-61 / flag | 0.0925268085399121 / clear | 0.055027625309015 / clear |

本目录为探索性族外回放，不进 Holm、不改任何既有判定。
