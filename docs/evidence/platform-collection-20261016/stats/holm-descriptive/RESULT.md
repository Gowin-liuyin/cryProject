# platform_holm 结果

Holm 家族按预注册 m 计算；RTLF 与 dudect 一律族外，最大 t 不得转伪 p。

族水平 alpha = 0.05；adjusted_p 单调不减，一旦某项不拒绝，其后全部不拒绝。

## Holm 逐步检验

| family_id | member_id | raw_p | rank | threshold | adjusted_p | reject |
| --- | --- | --- | --- | --- | --- | --- |
| m2_unfixed_arm(desc) | m2-m2-s2-unfixed-main | 0.0496696 | 1 | 0.0166667 | 0.149009 | no |
| m2_unfixed_arm(desc) | m2-m2-s3-unfixed-main | 0.159185 | 2 | 0.025 | 0.318369 | no |
| m2_unfixed_arm(desc) | m2-m2-s1-unfixed-main | 0.22273 | 3 | 0.05 | 0.318369 | no |
| m2_fixed_arm(desc) | m2-m2-s3-fixed-main | 0.0639603 | 1 | 0.0166667 | 0.191881 | no |
| m2_fixed_arm(desc) | m2-m2-s2-fixed-main | 0.246885 | 2 | 0.025 | 0.493771 | no |
| m2_fixed_arm(desc) | m2-m2-s1-fixed-main | 0.261211 | 3 | 0.05 | 0.493771 | no |
| m3_on_arm(desc) | m3-m3-s3-on-main | 0.188582 | 1 | 0.0166667 | 0.565747 | no |
| m3_on_arm(desc) | m3-m3-s1-on-main | 0.268181 | 2 | 0.025 | 0.565747 | no |
| m3_on_arm(desc) | m3-m3-s2-on-main | 0.315457 | 3 | 0.05 | 0.565747 | no |
| m3_off_arm(desc) | m3-m3-s2-off-main | 0.375494 | 1 | 0.0166667 | 1 | no |
| m3_off_arm(desc) | m3-m3-s3-off-main | 0.457489 | 2 | 0.025 | 1 | no |
| m3_off_arm(desc) | m3-m3-s1-off-main | 0.479523 | 3 | 0.05 | 1 | no |
| m4_vulnerable_arm(desc) | m4-m4-s1-vuln-main | 0 | 1 | 0.0166667 | 0 | yes |
| m4_vulnerable_arm(desc) | m4-m4-s2-vuln-main | 9.22952e-25 | 2 | 0.025 | 1.8459e-24 | yes |
| m4_vulnerable_arm(desc) | m4-m4-s3-vuln-main | 3.14072e-22 | 3 | 0.05 | 3.14072e-22 | yes |
| m4_ct_arm(desc) | m4-m4-s1-ct-main | 0.385638 | 1 | 0.0166667 | 1 | no |
| m4_ct_arm(desc) | m4-m4-s3-ct-main | 0.399093 | 2 | 0.025 | 1 | no |
| m4_ct_arm(desc) | m4-m4-s2-ct-main | 0.437836 | 3 | 0.05 | 1 | no |
| m2_control_pair(desc) | m2-m2-s3-fixed-control | 0.229849 | 1 | 0.00833333 | 1 | no |
| m2_control_pair(desc) | m2-m2-s1-fixed-control | 0.604176 | 2 | 0.01 | 1 | no |
| m2_control_pair(desc) | m2-m2-s2-unfixed-control | 0.605034 | 3 | 0.0125 | 1 | no |
| m2_control_pair(desc) | m2-m2-s3-unfixed-control | 0.614605 | 4 | 0.0166667 | 1 | no |
| m2_control_pair(desc) | m2-m2-s2-fixed-control | 0.709624 | 5 | 0.025 | 1 | no |
| m2_control_pair(desc) | m2-m2-s1-unfixed-control | 0.785498 | 6 | 0.05 | 1 | no |
| m5_control_pair(desc) | m5-m5-s1-control | 0.0199551 | 1 | 0.0166667 | 0.0598652 | no |
| m5_control_pair(desc) | m5-m5-s3-control | 0.239854 | 2 | 0.025 | 0.479707 | no |
| m5_control_pair(desc) | m5-m5-s2-control | 0.474851 | 3 | 0.05 | 0.479707 | no |
| m3_control_pair(desc) | m3-m3-s3-off-control | 0.161823 | 1 | 0.00833333 | 0.970941 | no |
| m3_control_pair(desc) | m3-m3-s1-on-control | 0.462088 | 2 | 0.01 | 1 | no |
| m3_control_pair(desc) | m3-m3-s2-on-control | 0.586895 | 3 | 0.0125 | 1 | no |
| m3_control_pair(desc) | m3-m3-s3-on-control | 0.683805 | 4 | 0.0166667 | 1 | no |
| m3_control_pair(desc) | m3-m3-s1-off-control | 0.687446 | 5 | 0.025 | 1 | no |
| m3_control_pair(desc) | m3-m3-s2-off-control | 0.734888 | 6 | 0.05 | 1 | no |
| m4_trunc_control(desc) | m4-m4-c1-vuln-control | 6.25171e-202 | 1 | 0.00833333 | 3.75103e-201 | yes |
| m4_trunc_control(desc) | m4-m4-c3-vuln-control | 4.44223e-177 | 2 | 0.01 | 2.22112e-176 | yes |
| m4_trunc_control(desc) | m4-m4-c2-vuln-control | 0.00563462 | 3 | 0.0125 | 0.0225385 | yes |
| m4_trunc_control(desc) | m4-m4-c3-ct-control | 0.272785 | 4 | 0.0166667 | 0.818356 | no |
| m4_trunc_control(desc) | m4-m4-c1-ct-control | 0.275455 | 5 | 0.025 | 0.818356 | no |
| m4_trunc_control(desc) | m4-m4-c2-ct-control | 0.300731 | 6 | 0.05 | 0.818356 | no |

## 固定效应合并

theta = mean0 - mean1；se = sqrt(sd0^2/n0 + sd1^2/n1)；w = 1/se^2；
pooled = sum(w*theta)/sum(w)；pooled_se = 1/sqrt(sum(w))；ci95 = pooled +- 1.96*pooled_se；
Q = sum(w*(theta-pooled)^2)；df = m-1；I2 = (Q > df) ? (Q-df)/Q*100 : 0。

| family_id | m | pooled_effect_ns | pooled_se_ns | ci95_low_ns | ci95_high_ns | q_statistic | df | i2_percent |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| m2_unfixed_arm(desc) | 3 | 12.3471432 | 4.77661077 | 2.98498608 | 21.7093003 | 0.639430214 | 2 | 0 |
| m2_fixed_arm(desc) | 3 | -11.2042431 | 6.81235465 | -24.5564582 | 2.14797204 | 3.32974626 | 2 | 39.9353632 |
| m3_on_arm(desc) | 3 | -0.620936719 | 3.65046205 | -7.77584233 | 6.5339689 | 3.93343819 | 2 | 49.1538978 |
| m3_off_arm(desc) | 3 | -0.827550074 | 3.34134191 | -7.37658022 | 5.72148007 | 1.77604137 | 2 | 0 |
| m4_vulnerable_arm(desc) | 3 | -4.0894642 | 0.0642971362 | -4.21548659 | -3.96344182 | 2.92790771 | 2 | 31.6918361 |
| m4_ct_arm(desc) | 3 | 0.0550844305 | 0.213468172 | -0.363313186 | 0.473482047 | 1.99906765 | 2 | 0 |
| m2_control_pair(desc) | 6 | -1.60025394 | 4.03896193 | -9.51661932 | 6.31611144 | 2.28728005 | 5 | 0 |
| m5_control_pair(desc) | 3 | -1.82699467 | 3.32832442 | -8.35051054 | 4.69652121 | 7.00662118 | 2 | 71.4555711 |
| m3_control_pair(desc) | 6 | -1.65521731 | 2.45398939 | -6.46503652 | 3.15460189 | 2.78061238 | 5 | 0 |
| m4_trunc_control(desc) | 6 | -1.85482796 | 0.0458114339 | -1.94461837 | -1.76503755 | 96.1118369 | 5 | 94.7977271 |

数值护栏：se == 0、n0 == 0 或 n1 == 0 一律报错退出码 2，不跳过也不除零。
并列 p 值按输入出现顺序作为次级键，排名稳定。
