# platform_holm 结果

Holm 家族按预注册 m 计算；RTLF 与 dudect 一律族外，最大 t 不得转伪 p。

族水平 alpha = 0.05；adjusted_p 单调不减，一旦某项不拒绝，其后全部不拒绝。

## Holm 逐步检验

| family_id | member_id | raw_p | rank | threshold | adjusted_p | reject |
| --- | --- | --- | --- | --- | --- | --- |
| m2_div_hotspot_microbench_v1 | m2-micro-r01-unfixed | 0.0415807 | 1 | 0.00833333 | 0.249484 | no |
| m2_div_hotspot_microbench_v1 | m2-micro-r01-fixed | 0.0667048 | 2 | 0.01 | 0.333524 | no |
| m2_div_hotspot_microbench_v1 | m2-micro-r03-unfixed | 0.0975906 | 3 | 0.0125 | 0.390362 | no |
| m2_div_hotspot_microbench_v1 | m2-micro-r02-unfixed | 0.102982 | 4 | 0.0166667 | 0.390362 | no |
| m2_div_hotspot_microbench_v1 | m2-micro-r03-fixed | 0.121362 | 5 | 0.025 | 0.390362 | no |
| m2_div_hotspot_microbench_v1 | m2-micro-r02-fixed | 0.41398 | 6 | 0.05 | 0.41398 | no |

## 固定效应合并

theta = mean0 - mean1；se = sqrt(sd0^2/n0 + sd1^2/n1)；w = 1/se^2；
pooled = sum(w*theta)/sum(w)；pooled_se = 1/sqrt(sum(w))；ci95 = pooled +- 1.96*pooled_se；
Q = sum(w*(theta-pooled)^2)；df = m-1；I2 = (Q > df) ? (Q-df)/Q*100 : 0。

| family_id | m | pooled_effect_ns | pooled_se_ns | ci95_low_ns | ci95_high_ns | q_statistic | df | i2_percent |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| m2_div_hotspot_microbench_v1 | 6 | 0.0436999258 | 0.241597947 | -0.42983205 | 0.517231902 | 15.9520133 | 5 | 68.655994 |

数值护栏：se == 0、n0 == 0 或 n1 == 0 一律报错退出码 2，不跳过也不除零。
并列 p 值按输入出现顺序作为次级键，排名稳定。
