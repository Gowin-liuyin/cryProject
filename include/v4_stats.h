#ifndef BASELINE_V4_STATS_H
#define BASELINE_V4_STATS_H

#include <stddef.h>
#include <stdint.h>

#define V4_PROTOCOL_ID "v4_group_confirmation_20261013"
#define V4_KEY_COUNT 16u
#define V4_DEVELOPMENT_SESSIONS 8u
#define V4_DEVELOPMENT_REPEATS 2u
#define V4_SESSION_MIN 4u
#define V4_SESSION_MAX 40u
#define V4_FAMILY_ALPHA 0.01
#define V4_POWER_TARGET 0.9
#define V4_COVERAGE_THRESHOLD 0.99
#define V4_BAND_LOW_KHZ 4257000ull
#define V4_BAND_HIGH_KHZ 4343000ull
#define V4_ALTERNATING_ROUNDS 5u
#define V4_ORDER_SEED UINT64_C(2026101307)
#define V4_LABEL_SEED UINT64_C(20261013)
#define V4_LABEL_POPULATION 3000u
#define V4_LABEL_DRAW_COUNT 24u
#define V4_EMPTY_WINDOW_COUNT 256u

struct v4_power_plan {
    const char *status;
    unsigned session_count;
    unsigned repeat_count;
    double development_mean_counts;
    double development_sd_counts;
    double power_at_exported;
    double power_at_previous;
    int exported;
};

struct v4_confirm_result {
    const char *status;
    const char *primary_token;
    int holm_rejected;
    int direction_consistent;
    double unadjusted_mean_counts;
    double covariate_intercept_counts;
    double covariate_slope_counts;
    double covariate_slope_p_value;
    int covariate_slope_defined;
    unsigned session_count;
};

struct v4_paired_result {
    const char *verdict;
    int holm_rejected;
    double mean_absolute_gap_counts;
    int branch_direction_consistent;
    unsigned round_count;
};

uint64_t v4_development_seed(unsigned session_number);
uint64_t v4_confirmation_seed(unsigned session_number);
uint64_t v4_alternating_seed(unsigned round_number);
uint64_t v4_splitmix64(uint64_t *state);
int v4_round_measures_branch_first(unsigned round_number);

int v4_mean_sd(const double *values, size_t count, double *mean_counts, double *sample_sd_counts);
int v4_one_sample_t(const double *values,
    size_t count,
    double *mean_counts,
    double *t_statistic,
    double *p_value,
    int *zero_variance);
int v4_direction_consistent(const double *values, size_t count);
double v4_central_t_critical(double two_sided_alpha, unsigned degrees_of_freedom);
double v4_student_power(double mean_counts, double sample_sd_counts, unsigned session_count);
int v4_power_plan(const double *effects,
    size_t count,
    int require_development_count,
    struct v4_power_plan *plan);

int v4_confirm(const double *effects,
    const double *empty_medians,
    const double *coverages,
    size_t count,
    int enforce_coverage,
    struct v4_confirm_result *result);
int v4_centered_slope(const double *effects,
    const double *covariate,
    size_t count,
    double *intercept_counts,
    double *slope_counts,
    double *slope_p_value,
    int *slope_defined);

int v4_paired(const double *branch_effects,
    const double *mask_effects,
    size_t round_count,
    struct v4_paired_result *result);

int v4_coverage_fraction(const uint64_t *frequency_khz,
    const uint64_t *time_ns,
    size_t sample_count,
    double *fraction);
double v4_even_median(const uint64_t *values, size_t count);

int v4_shapiro_wilk(const double *values, size_t count, double *w_statistic, double *p_value);
int v4_lag1_autocorrelation(const double *values, size_t count, double *autocorrelation);
int v4_blom_quantile(size_t order_index, size_t count, double *quantile);
int v4_label_draw(unsigned block_number, uint32_t indices[V4_LABEL_DRAW_COUNT]);

#endif
