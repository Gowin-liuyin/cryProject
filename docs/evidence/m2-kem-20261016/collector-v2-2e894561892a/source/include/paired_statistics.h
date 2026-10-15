#ifndef BASELINE_PAIRED_STATISTICS_H
#define BASELINE_PAIRED_STATISTICS_H

#include <stddef.h>
#include <stdint.h>

#define MAXIMUM_RUN_PAIRS 20u
#define PAIRED_BOOTSTRAP_COUNT 10000u
#define PAIRED_ANALYSIS_SEED UINT64_C(20261029)

struct run_stability {
    long double median_nanoseconds;
    long double mad_nanoseconds;
    long double relative_dispersion;
    long double lag1_correlation;
    long double half_mean_relative_change;
    int has_lag1_correlation;
};

struct paired_statistics {
    struct run_stability baseline;
    struct run_stability candidate;
    long double dispersion_ratio;
    long double interval_lower;
    long double interval_upper;
    long double center_relative_change;
    size_t degenerate_replicates;
    int has_point_ratio;
    int has_interval;
};

int compute_run_stability(const long double *run_means,
    size_t run_count,
    struct run_stability *result);
int compute_paired_statistics(const long double *baseline_means,
    const long double *candidate_means,
    size_t pair_count,
    struct paired_statistics *result);
int draw_paired_index(uint64_t *random_state, size_t upper_bound, size_t *selected_index);
const char *paired_result_label(const struct paired_statistics *statistics,
    long double worst_cost_ratio,
    int qualification_valid);

#endif
