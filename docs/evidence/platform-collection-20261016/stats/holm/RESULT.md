# platform_holm 结果

Holm 家族按预注册 m 计算；RTLF 与 dudect 一律族外，最大 t 不得转伪 p。

族水平 alpha = 0.05；adjusted_p 单调不减，一旦某项不拒绝，其后全部不拒绝。

## Holm 逐步检验

| family_id | member_id | raw_p | rank | threshold | adjusted_p | reject |
| --- | --- | --- | --- | --- | --- | --- |
| m2_end_to_end_full_decaps_v1 | m2-r02-unfixed | 0.0496696 | 1 | 0.00833333 | 0.298017 | no |
| m2_end_to_end_full_decaps_v1 | m2-r03-fixed | 0.0639603 | 2 | 0.01 | 0.319802 | no |
| m2_end_to_end_full_decaps_v1 | m2-r03-unfixed | 0.159185 | 3 | 0.0125 | 0.636738 | no |
| m2_end_to_end_full_decaps_v1 | m2-r01-unfixed | 0.22273 | 4 | 0.0166667 | 0.668191 | no |
| m2_end_to_end_full_decaps_v1 | m2-r02-fixed | 0.246885 | 5 | 0.025 | 0.668191 | no |
| m2_end_to_end_full_decaps_v1 | m2-r01-fixed | 0.261211 | 6 | 0.05 | 0.668191 | no |
| m5_reference_end_to_end_v1 | m5-r03-reference | 0.24949 | 1 | 0.0166667 | 0.748469 | no |
| m5_reference_end_to_end_v1 | m5-r01-reference | 0.410131 | 2 | 0.025 | 0.820263 | no |
| m5_reference_end_to_end_v1 | m5-r02-reference | 0.427476 | 3 | 0.05 | 0.820263 | no |
| m3_lut_arm_end_to_end_v1 | m3-r03-on | 0.188582 | 1 | 0.00833333 | 1 | no |
| m3_lut_arm_end_to_end_v1 | m3-r01-on | 0.268181 | 2 | 0.01 | 1 | no |
| m3_lut_arm_end_to_end_v1 | m3-r02-on | 0.315457 | 3 | 0.0125 | 1 | no |
| m3_lut_arm_end_to_end_v1 | m3-r02-off | 0.375494 | 4 | 0.0166667 | 1 | no |
| m3_lut_arm_end_to_end_v1 | m3-r03-off | 0.457489 | 5 | 0.025 | 1 | no |
| m3_lut_arm_end_to_end_v1 | m3-r01-off | 0.479523 | 6 | 0.05 | 1 | no |
| m4_compare_arm_session_v1 | m4-r01-vulnerable | 0 | 1 | 0.00833333 | 0 | yes |
| m4_compare_arm_session_v1 | m4-r02-vulnerable | 9.22952e-25 | 2 | 0.01 | 4.61476e-24 | yes |
| m4_compare_arm_session_v1 | m4-r03-vulnerable | 3.14072e-22 | 3 | 0.0125 | 1.25629e-21 | yes |
| m4_compare_arm_session_v1 | m4-r01-ct | 0.385638 | 4 | 0.0166667 | 1 | no |
| m4_compare_arm_session_v1 | m4-r03-ct | 0.399093 | 5 | 0.025 | 1 | no |
| m4_compare_arm_session_v1 | m4-r02-ct | 0.437836 | 6 | 0.05 | 1 | no |

## 固定效应合并

theta = mean0 - mean1；se = sqrt(sd0^2/n0 + sd1^2/n1)；w = 1/se^2；
pooled = sum(w*theta)/sum(w)；pooled_se = 1/sqrt(sum(w))；ci95 = pooled +- 1.96*pooled_se；
Q = sum(w*(theta-pooled)^2)；df = m-1；I2 = (Q > df) ? (Q-df)/Q*100 : 0。

| family_id | m | pooled_effect_ns | pooled_se_ns | ci95_low_ns | ci95_high_ns | q_statistic | df | i2_percent |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| m2_end_to_end_full_decaps_v1 | 6 | 4.584702 | 3.91100321 | -3.0808643 | 12.2502683 | 11.9818065 | 5 | 58.2700656 |
| m5_reference_end_to_end_v1 | 3 | -5.30430047 | 3.29991839 | -11.7721405 | 1.16353958 | 0.0505025202 | 2 | 0 |
| m3_lut_arm_end_to_end_v1 | 6 | -0.733360321 | 2.46473636 | -5.56424358 | 4.09752294 | 5.71122265 | 5 | 12.4530717 |
| m4_compare_arm_session_v1 | 6 | -3.74473363 | 0.0615650747 | -3.86540118 | -3.62406608 | 350.527014 | 5 | 98.5735764 |

数值护栏：se == 0、n0 == 0 或 n1 == 0 一律报错退出码 2，不跳过也不除零。
并列 p 值按输入出现顺序作为次级键，排名稳定。
