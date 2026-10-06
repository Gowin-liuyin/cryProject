#include "paired_statistics.h"

#include <math.h>
#include <stdlib.h>
#include <string.h>

const char *paired_result_label(const struct paired_statistics *statistics,
    long double worst_cost_ratio,
    int qualification_valid)
{
    if (statistics == NULL || !isfinite(worst_cost_ratio) || worst_cost_ratio <= 0.0L) {
        return "software_check_failed";
    }
    if (!qualification_valid || !statistics->has_interval) {
        return "comparison_evidence_insufficient";
    }
    return statistics->interval_upper < 0.8L && worst_cost_ratio <= 1.05L &&
            fabsl(statistics->candidate.median_nanoseconds -
                statistics->baseline.median_nanoseconds) <=
                0.05L * statistics->baseline.median_nanoseconds
        ? "supports_this_measurement_quality_improvement"
        : "improvement_conditions_not_met";
}

static int compare_values(const void *left, const void *right)
{
    long double left_value = *(const long double *)left;
    long double right_value = *(const long double *)right;
    return left_value < right_value ? -1 : left_value > right_value ? 1 : 0;
}

static long double ordinary_median(long double *values, size_t value_count)
{
    qsort(values, value_count, sizeof(*values), compare_values);
    return value_count % 2u == 0
        ? values[value_count / 2u - 1u] / 2.0L + values[value_count / 2u] / 2.0L
        : values[value_count / 2u];
}

static int
compute_location(const long double *values, size_t value_count, struct run_stability *result)
{
    long double working_values[MAXIMUM_RUN_PAIRS];
    if (values == NULL || result == NULL || value_count < 2u || value_count > MAXIMUM_RUN_PAIRS) {
        return 1;
    }
    for (size_t value_index = 0; value_index < value_count; ++value_index) {
        if (!isfinite(values[value_index]) || values[value_index] <= 0.0L) {
            return 1;
        }
        working_values[value_index] = values[value_index];
    }
    result->median_nanoseconds = ordinary_median(working_values, value_count);
    for (size_t value_index = 0; value_index < value_count; ++value_index) {
        working_values[value_index] = fabsl(values[value_index] - result->median_nanoseconds);
    }
    result->mad_nanoseconds = ordinary_median(working_values, value_count);
    result->relative_dispersion = result->mad_nanoseconds / result->median_nanoseconds;
    return isfinite(result->relative_dispersion) ? 0 : 1;
}

int compute_run_stability(const long double *run_means,
    size_t run_count,
    struct run_stability *result)
{
    if (compute_location(run_means, run_count, result) != 0) {
        return 1;
    }
    long double previous_mean = 0.0L;
    long double next_mean = 0.0L;
    for (size_t run_index = 0; run_index + 1u < run_count; ++run_index) {
        previous_mean += run_means[run_index] / (long double)(run_count - 1u);
        next_mean += run_means[run_index + 1u] / (long double)(run_count - 1u);
    }
    long double covariance = 0.0L;
    long double previous_variation = 0.0L;
    long double next_variation = 0.0L;
    long double first_half_total = 0.0L;
    long double second_half_total = 0.0L;
    size_t first_half_count = run_count / 2u;
    for (size_t run_index = 0; run_index < run_count; ++run_index) {
        if (run_index < first_half_count) {
            first_half_total += run_means[run_index];
        } else {
            second_half_total += run_means[run_index];
        }
        if (run_index + 1u < run_count) {
            long double previous_deviation = run_means[run_index] - previous_mean;
            long double next_deviation = run_means[run_index + 1u] - next_mean;
            covariance += previous_deviation * next_deviation;
            previous_variation += previous_deviation * previous_deviation;
            next_variation += next_deviation * next_deviation;
        }
    }
    result->has_lag1_correlation = previous_variation > 0.0L && next_variation > 0.0L;
    result->lag1_correlation = result->has_lag1_correlation
        ? covariance / sqrtl(previous_variation * next_variation)
        : 0.0L;
    result->half_mean_relative_change =
        fabsl(second_half_total / (long double)(run_count - first_half_count) -
            first_half_total / (long double)first_half_count) /
        result->median_nanoseconds;
    return isfinite(result->half_mean_relative_change) && isfinite(result->lag1_correlation) ? 0
                                                                                             : 1;
}

static uint64_t splitmix64_word(uint64_t *random_state)
{
    *random_state += UINT64_C(0x9e3779b97f4a7c15);
    uint64_t mixed_value = *random_state;
    mixed_value = (mixed_value ^ (mixed_value >> 30u)) * UINT64_C(0xbf58476d1ce4e5b9);
    mixed_value = (mixed_value ^ (mixed_value >> 27u)) * UINT64_C(0x94d049bb133111eb);
    return mixed_value ^ (mixed_value >> 31u);
}

int draw_paired_index(uint64_t *random_state, size_t upper_bound, size_t *selected_index)
{
    if (random_state == NULL || selected_index == NULL || upper_bound == 0 ||
        upper_bound > MAXIMUM_RUN_PAIRS) {
        return 1;
    }
    uint64_t bound = (uint64_t)upper_bound;
    uint64_t threshold = (UINT64_C(0) - bound) % bound;
    uint64_t random_value;
    do {
        random_value = splitmix64_word(random_state);
    } while (random_value < threshold);
    *selected_index = (size_t)(random_value % bound);
    return 0;
}

static long double interval_endpoint(const long double *sorted_ratios, long double fraction)
{
    long double position = fraction * (long double)(PAIRED_BOOTSTRAP_COUNT - 1u);
    size_t lower_index = (size_t)floorl(position);
    long double remainder = position - (long double)lower_index;
    return sorted_ratios[lower_index] * (1.0L - remainder) +
        sorted_ratios[lower_index + 1u] * remainder;
}

int compute_paired_statistics(const long double *baseline_means,
    const long double *candidate_means,
    size_t pair_count,
    struct paired_statistics *result)
{
    if (result == NULL) {
        return 1;
    }
    memset(result, 0, sizeof(*result));
    if (compute_run_stability(baseline_means, pair_count, &result->baseline) != 0 ||
        compute_run_stability(candidate_means, pair_count, &result->candidate) != 0) {
        return 1;
    }
    result->center_relative_change =
        fabsl(result->candidate.median_nanoseconds / result->baseline.median_nanoseconds - 1.0L);
    if (result->baseline.mad_nanoseconds == 0.0L) {
        return 0;
    }
    result->has_point_ratio = 1;
    result->dispersion_ratio =
        result->candidate.relative_dispersion / result->baseline.relative_dispersion;
    long double *ratios = malloc(PAIRED_BOOTSTRAP_COUNT * sizeof(*ratios));
    if (ratios == NULL) {
        return 1;
    }
    uint64_t random_state = PAIRED_ANALYSIS_SEED;
    for (size_t replicate_index = 0; replicate_index < PAIRED_BOOTSTRAP_COUNT; ++replicate_index) {
        long double resampled_baseline[MAXIMUM_RUN_PAIRS];
        long double resampled_candidate[MAXIMUM_RUN_PAIRS];
        for (size_t pair_index = 0; pair_index < pair_count; ++pair_index) {
            size_t selected_index;
            if (draw_paired_index(&random_state, pair_count, &selected_index) != 0) {
                free(ratios);
                return 1;
            }
            resampled_baseline[pair_index] = baseline_means[selected_index];
            resampled_candidate[pair_index] = candidate_means[selected_index];
        }
        struct run_stability baseline_replicate = {0};
        struct run_stability candidate_replicate = {0};
        if (compute_location(resampled_baseline, pair_count, &baseline_replicate) != 0 ||
            compute_location(resampled_candidate, pair_count, &candidate_replicate) != 0) {
            free(ratios);
            return 1;
        }
        if (baseline_replicate.mad_nanoseconds == 0.0L) {
            ++result->degenerate_replicates;
            ratios[replicate_index] = NAN;
        } else {
            ratios[replicate_index] =
                candidate_replicate.relative_dispersion / baseline_replicate.relative_dispersion;
        }
    }
    if (result->degenerate_replicates == 0) {
        qsort(ratios, PAIRED_BOOTSTRAP_COUNT, sizeof(*ratios), compare_values);
        result->interval_lower = interval_endpoint(ratios, 0.005L);
        result->interval_upper = interval_endpoint(ratios, 0.995L);
        result->has_interval = 1;
    }
    free(ratios);
    return 0;
}
