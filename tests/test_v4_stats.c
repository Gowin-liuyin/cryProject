#include "v4_stats.h"

#include "protocol_decision.h"

#include <math.h>
#include <stdio.h>
#include <string.h>

static int fail(const char *message)
{
    fprintf(stderr, "v4 stats test failed: %s\n", message);
    return 1;
}

int main(void)
{
    double constant_effects[8];
    double zero_effects[8];
    double mixed_effects[4];
    double empty_medians[8];
    double coverages[8];
    double branch_effects[5] = {10.0, 10.0, 10.0, 10.0, 10.0};
    double mask_effects[5] = {1.0, 1.0, 1.0, 1.0, 1.0};
    double flipped_branch[5] = {10.0, -10.0, 10.0, -10.0, 10.0};
    struct v4_power_plan plan;
    struct v4_confirm_result confirm;
    struct v4_paired_result paired;
    uint32_t first_draw[V4_LABEL_DRAW_COUNT];
    uint32_t second_draw[V4_LABEL_DRAW_COUNT];
    uint64_t times[10];
    uint64_t inside[10];
    uint64_t mixed[10];
    double fraction = 0.0;
    double critical;
    int seen[V4_LABEL_POPULATION];
    for (size_t index = 0; index < 8u; ++index) {
        constant_effects[index] = 10.0;
        zero_effects[index] = 0.0;
        empty_medians[index] = 20.0 + (double)index;
        coverages[index] = 1.0;
    }
    v4_power_plan(constant_effects, 8u, 1, &plan);
    if (!plan.exported || plan.session_count != V4_SESSION_MIN || plan.repeat_count != 2u ||
        plan.power_at_exported != 1.0 || strcmp(plan.status, "exported") != 0) {
        return fail("zero variance export");
    }
    v4_power_plan(zero_effects, 8u, 1, &plan);
    if (plan.exported || strcmp(plan.status, "stopped_no_stable_group_effect") != 0) {
        return fail("zero mean stop");
    }
    v4_power_plan(constant_effects, 7u, 1, &plan);
    if (strcmp(plan.status, "stopped_incomplete_development") != 0) {
        return fail("development count");
    }
    for (unsigned session_count = V4_SESSION_MIN; session_count < V4_SESSION_MAX; ++session_count) {
        double low = v4_student_power(3.0, 1.0, session_count);
        double high = v4_student_power(3.0, 1.0, session_count + 1u);
        if (!(high + 1e-9 >= low)) {
            return fail("power is not monotone");
        }
    }
    critical = v4_central_t_critical(0.01, 1u);
    if (!isfinite(critical) || fabs(protocol_student_t_two_sided(critical, 1u) - 0.01) > 1e-8) {
        return fail("t critical");
    }
    v4_confirm(constant_effects, empty_medians, coverages, 8u, 1, &confirm);
    if (strcmp(confirm.primary_token, "rejected_direction_consistent") != 0 ||
        fabs(confirm.unadjusted_mean_counts - confirm.covariate_intercept_counts) > 1e-12 ||
        confirm.holm_rejected == 0) {
        return fail("constant confirm");
    }
    mixed_effects[0] = 30.0;
    mixed_effects[1] = 30.0;
    mixed_effects[2] = 30.0;
    mixed_effects[3] = -1.0;
    v4_confirm(mixed_effects, empty_medians, coverages, 4u, 1, &confirm);
    if (confirm.holm_rejected && confirm.direction_consistent == 0 &&
        strcmp(confirm.primary_token, "rejected_direction_inconsistent") != 0) {
        return fail("inconsistent token");
    }
    if (!confirm.holm_rejected && strcmp(confirm.primary_token, "not_rejected") != 0) {
        return fail("not rejected token");
    }
    coverages[0] = 0.5;
    v4_confirm(constant_effects, empty_medians, coverages, 8u, 1, &confirm);
    if (strcmp(confirm.status, "stopped_window_coverage") != 0 ||
        strcmp(confirm.primary_token, "not_run") != 0) {
        return fail("coverage gate");
    }
    v4_paired(branch_effects, mask_effects, 5u, &paired);
    if (strcmp(paired.verdict, "protection_causality") != 0) {
        return fail("paired protection");
    }
    v4_paired(flipped_branch, mask_effects, 5u, &paired);
    if (strcmp(paired.verdict, "environment_drift_dominant") != 0) {
        return fail("paired drift");
    }
    v4_paired(branch_effects, mask_effects, 4u, &paired);
    if (strcmp(paired.verdict, "not_run") != 0) {
        return fail("paired count");
    }
    for (size_t index = 0; index < 10u; ++index) {
        times[index] = index * UINT64_C(1000000);
        inside[index] = 4300000u;
        mixed[index] = 4300000u;
    }
    mixed[0] = 1000000u;
    if (v4_coverage_fraction(inside, times, 10u, &fraction) != 0 || fraction != 1.0) {
        return fail("full coverage");
    }
    if (v4_coverage_fraction(mixed, times, 10u, &fraction) != 0 || fraction != 8.0 / 9.0) {
        return fail("partial coverage");
    }
    memset(seen, 0, sizeof(seen));
    if (v4_label_draw(1u, first_draw) != 0 || v4_label_draw(1u, second_draw) != 0) {
        return fail("label draw");
    }
    for (size_t index = 0; index < V4_LABEL_DRAW_COUNT; ++index) {
        if (first_draw[index] != second_draw[index] || first_draw[index] >= V4_LABEL_POPULATION ||
            seen[first_draw[index]] != 0) {
            return fail("label indices");
        }
        seen[first_draw[index]] = 1;
    }
    if (v4_round_measures_branch_first(1u) != v4_round_measures_branch_first(1u)) {
        return fail("round order");
    }
    if (v4_development_seed(1u) != UINT64_C(20261013001) ||
        v4_confirmation_seed(1u) != UINT64_C(20261014001) ||
        v4_alternating_seed(1u) != UINT64_C(20261015001)) {
        return fail("seeds");
    }
    return 0;
}
