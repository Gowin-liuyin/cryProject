#include "paired_statistics.h"

#include <assert.h>
#include <math.h>
#include <string.h>

int main(void)
{
    const long double four_values[] = {1, 2, 3, 4};
    struct run_stability summary = {0};
    assert(compute_run_stability(four_values, 4, &summary) == 0);
    assert(summary.median_nanoseconds == 2.5L);
    assert(summary.mad_nanoseconds == 1.0L);
    assert(summary.relative_dispersion == 0.4L);
    const long double three_values[] = {1, 4, 8};
    assert(compute_run_stability(three_values, 3, &summary) == 0);
    assert(summary.median_nanoseconds == 4.0L && summary.mad_nanoseconds == 3.0L);
    long double baseline[20];
    long double candidate[20];
    for (size_t pair_index = 0; pair_index < 20u; ++pair_index) {
        baseline[pair_index] = 920.0L + 8.0L * (long double)pair_index;
        candidate[pair_index] = 2.0L * baseline[pair_index];
    }
    struct paired_statistics result;
    assert(compute_paired_statistics(baseline, candidate, 20, &result) == 0);
    /* 同索引重采样时整体倍乘不改变S；独立重采样两组会破坏这个恒等式。 */
    assert(result.has_interval && result.dispersion_ratio == 1.0L);
    assert(result.interval_lower == 1.0L && result.interval_upper == 1.0L);
    struct paired_statistics repeated_result;
    assert(compute_paired_statistics(baseline, candidate, 20, &repeated_result) == 0);
    assert(result.interval_lower == repeated_result.interval_lower);
    assert(result.interval_upper == repeated_result.interval_upper);
    assert(result.degenerate_replicates == 0);
    for (size_t pair_index = 0; pair_index < 20u; ++pair_index) {
        candidate[pair_index] = 1000.0L + (baseline[pair_index] - 1000.0L) / 4.0L;
    }
    assert(compute_paired_statistics(baseline, candidate, 20, &result) == 0);
    assert(result.has_interval && result.interval_upper < 0.8L);
    assert(strcmp(paired_result_label(&result, 1.0L, 1),
               "supports_this_measurement_quality_improvement") == 0);
    assert(strcmp(paired_result_label(&result, 1.06L, 1), "improvement_conditions_not_met") == 0);
    assert(strcmp(paired_result_label(&result, 1.0L, 0), "comparison_evidence_insufficient") == 0);
    /* 包含恰好5%的中心边界，不用比值减1的舍入误差改变判定。 */
    for (size_t pair_index = 0; pair_index < 20u; ++pair_index) {
        baseline[pair_index] = 924.0L + 8.0L * (long double)pair_index;
        candidate[pair_index] = 1050.0L + (baseline[pair_index] - 1000.0L) / 4.0L;
    }
    assert(compute_paired_statistics(baseline, candidate, 20, &result) == 0);
    assert(result.baseline.median_nanoseconds == 1000.0L);
    assert(result.candidate.median_nanoseconds == 1050.0L);
    assert(strcmp(paired_result_label(&result, 1.0L, 1),
               "supports_this_measurement_quality_improvement") == 0);
    for (size_t pair_index = 0; pair_index < 20u; ++pair_index) {
        candidate[pair_index] += 1.0L;
    }
    assert(compute_paired_statistics(baseline, candidate, 20, &result) == 0);
    assert(strcmp(paired_result_label(&result, 1.0L, 1), "improvement_conditions_not_met") == 0);
    for (size_t pair_index = 0; pair_index < 20u; ++pair_index) {
        candidate[pair_index] = 950.0L + (baseline[pair_index] - 1000.0L) / 4.0L;
    }
    assert(compute_paired_statistics(baseline, candidate, 20, &result) == 0);
    assert(strcmp(paired_result_label(&result, 1.0L, 1),
               "supports_this_measurement_quality_improvement") == 0);
    for (size_t pair_index = 0; pair_index < 20u; ++pair_index) {
        candidate[pair_index] -= 1.0L;
    }
    assert(compute_paired_statistics(baseline, candidate, 20, &result) == 0);
    assert(strcmp(paired_result_label(&result, 1.0L, 1), "improvement_conditions_not_met") == 0);
    for (size_t pair_index = 0; pair_index < 20u; ++pair_index) {
        candidate[pair_index] = 1000.0L + (baseline[pair_index] - 1000.0L) * 4.0L;
    }
    assert(compute_paired_statistics(baseline, candidate, 20, &result) == 0);
    assert(result.has_interval && result.interval_upper > 0.8L);
    assert(strcmp(paired_result_label(&result, 1.0L, 1), "improvement_conditions_not_met") == 0);
    for (size_t pair_index = 0; pair_index < 20u; ++pair_index) {
        baseline[pair_index] = 1000;
    }
    assert(compute_paired_statistics(baseline, candidate, 20, &result) == 0);
    assert(!result.has_point_ratio && !result.has_interval);
    assert(strcmp(paired_result_label(&result, NAN, 1), "software_check_failed") == 0);
    /* 两点有放回抽样必然出现分母退化，不得删掉这些重采样再给区间。 */
    const long double two_values[] = {1, 2};
    assert(compute_paired_statistics(two_values, two_values, 2, &result) == 0);
    assert(result.has_point_ratio && !result.has_interval && result.degenerate_replicates > 0);
    long double invalid_values[] = {1, NAN};
    assert(compute_run_stability(invalid_values, 2, &summary) == 1);
    invalid_values[1] = INFINITY;
    assert(compute_run_stability(invalid_values, 2, &summary) == 1);
    invalid_values[1] = 0;
    assert(compute_run_stability(invalid_values, 2, &summary) == 1);
    uint64_t random_state = PAIRED_ANALYSIS_SEED;
    size_t selected_index;
    assert(draw_paired_index(&random_state, 0, &selected_index) == 1);
    for (size_t draw_index = 0; draw_index < 100u; ++draw_index) {
        assert(draw_paired_index(&random_state, 20, &selected_index) == 0);
        assert(selected_index < 20u);
    }
    return 0;
}
