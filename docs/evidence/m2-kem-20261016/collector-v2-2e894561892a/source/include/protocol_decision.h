#ifndef BASELINE_PROTOCOL_DECISION_H
#define BASELINE_PROTOCOL_DECISION_H

#include <stddef.h>
#include <stdint.h>
#include <stdio.h>

#define PROTOCOL_ID_CAPACITY 80u
#define PROTOCOL_COMPARISON_CAPACITY 8u
#define PROTOCOL_SEED_CAPACITY 8u

struct protocol_comparison {
    char left_category[32];
    char right_category[32];
};

struct frozen_protocol {
    char protocol_id[PROTOCOL_ID_CAPACITY];
    double alpha_family;
    char alpha_control[16];
    char analysis_unit[16];
    struct protocol_comparison comparisons[PROTOCOL_COMPARISON_CAPACITY];
    size_t comparison_count;
    char primary_left[32];
    char primary_right[32];
    char effect_direction[16];
    char effect_estimator[40];
    uint64_t sample_budget_per_class;
    uint64_t session_budget;
    uint64_t block_lengths[4];
    size_t block_length_count;
    double autocorrelation_abs_limit;
    char anomaly_rule[64];
    char interval_name[16];
    char stop_rule[32];
    uint64_t development_seeds[PROTOCOL_SEED_CAPACITY];
    size_t development_seed_count;
    uint64_t confirmation_seeds[PROTOCOL_SEED_CAPACITY];
    size_t confirmation_seed_count;
    int iid_upgrade_allowed;
    int constant_time_upgrade_allowed;
};

struct session_effect {
    char session_id[64];
    char left_category[32];
    char right_category[32];
    double mean_difference_counts;
    size_t left_sample_count;
    size_t right_sample_count;
    double lag1_autocorrelation;
    int autocorrelation_defined;
    double repeat_rate_left;
    double repeat_rate_right;
};

struct protocol_decision {
    double primary_mean_difference_counts;
    double primary_t_statistic;
    double primary_p_value;
    int primary_p_defined;
    int holm_rejected_primary;
    int zero_variance;
    double wald_low_counts;
    double wald_high_counts;
    double drift_last_minus_first;
    double block_mean_difference[4];
    size_t block_length_count;
    char iid_upgrade[24];
    char constant_time_upgrade[24];
    char thresholds_chosen_after_data[8];
};

int protocol_load(const char *path, struct frozen_protocol *protocol);
int protocol_decide(const struct frozen_protocol *protocol,
    const char *csv_path,
    const char *phase,
    uint64_t seed,
    struct protocol_decision *decision,
    struct session_effect *session_effects,
    size_t session_capacity,
    size_t *session_count);
double protocol_student_t_two_sided(double t_statistic, unsigned degrees_of_freedom);
void protocol_holm(const double *p_values,
    size_t comparison_count,
    double alpha_family,
    int *rejected);
int protocol_write_report(FILE *output,
    const char *phase,
    const struct protocol_decision *decision,
    const struct session_effect *session_effects,
    size_t session_count);

#endif
