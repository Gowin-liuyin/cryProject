#include "paired_data.h"
#include "paired_statistics.h"

#include <inttypes.h>
#include <math.h>
#include <stdlib.h>
#include <string.h>

struct cohort_context {
    char values[22][PAIRED_TEXT_CAPACITY];
    uint64_t expected_pairs;
    uint64_t shared_calls_upper;
    uint64_t shared_wall_lower;
    uint64_t shared_wall_upper;
    uint64_t prior_development_calls[2];
    uint64_t prior_auxiliary_calls[2];
    uint64_t prior_wall_nanoseconds[2];
    uint64_t selected_batch_size;
};

static const char *const context_names[] = {"cohort_format",
    "phase",
    "expected_pairs",
    "shared_calls_upper",
    "shared_wall_lower_ns",
    "shared_wall_upper_ns",
    "prior_baseline_development_calls",
    "prior_candidate_development_calls",
    "prior_baseline_auxiliary_calls",
    "prior_candidate_auxiliary_calls",
    "prior_baseline_wall_ns",
    "prior_candidate_wall_ns",
    "platform_review",
    "dependency_review",
    "cost_closure",
    "source_commit",
    "baseline_executable_digest",
    "candidate_executable_digest",
    "cohort_manifest_digest",
    "selected_batch_size",
    "protocol_commit",
    "cohort_status"};

static int load_context(const char *directory, struct cohort_context *context)
{
    char context_path[4096];
    struct paired_text_field fields[22];
    if (paired_data_path(context_path, sizeof(context_path), directory, "cohort.meta") != 0) {
        return 1;
    }
    for (size_t field_index = 0; field_index < 22u; ++field_index) {
        fields[field_index] = (struct paired_text_field){context_names[field_index],
            context->values[field_index],
            PAIRED_TEXT_CAPACITY,
            0};
    }
    if (read_paired_fields(context_path, fields, 22) != 0 ||
        strcmp(context->values[0], "paired_cohort_v1") != 0 ||
        (strcmp(context->values[1], "software_fixture") != 0 &&
            strcmp(context->values[1], "development") != 0 &&
            strcmp(context->values[1], "confirmation") != 0) ||
        !is_paired_hex(context->values[15], 40) || !is_paired_hex(context->values[16], 64) ||
        !is_paired_hex(context->values[17], 64) || !is_paired_hex(context->values[18], 64) ||
        strcmp(context->values[20], "064e99c4ce6ecb0375b2f799105312fce18b46d9") != 0 ||
        strcmp(context->values[21], "complete") != 0 ||
        (strcmp(context->values[14], "exact") != 0 && strcmp(context->values[14], "bounded") != 0 &&
            strcmp(context->values[14], "unclosed") != 0) ||
        (strcmp(context->values[12], "accepted") != 0 &&
            strcmp(context->values[12], "pending") != 0 &&
            strcmp(context->values[12], "rejected") != 0) ||
        (strcmp(context->values[13], "accepted") != 0 &&
            strcmp(context->values[13], "pending") != 0 &&
            strcmp(context->values[13], "rejected") != 0)) {
        return 1;
    }
    uint64_t numbers[10];
    for (size_t number_index = 0; number_index < 10u; ++number_index) {
        if (parse_unsigned_integer(context->values[number_index + 2u], &numbers[number_index]) !=
            0) {
            return 1;
        }
    }
    if (numbers[0] < 2u || numbers[0] > MAXIMUM_RUN_PAIRS || numbers[3] < numbers[2] ||
        numbers[1] > 80000u || numbers[3] > UINT64_C(3600000000000) ||
        parse_unsigned_integer(context->values[19], &context->selected_batch_size) != 0 ||
        (context->selected_batch_size != 1u && context->selected_batch_size != 4u &&
            context->selected_batch_size != 16u)) {
        return 1;
    }
    context->expected_pairs = numbers[0];
    context->shared_calls_upper = numbers[1];
    context->shared_wall_lower = numbers[2];
    context->shared_wall_upper = numbers[3];
    for (size_t method_index = 0; method_index < 2u; ++method_index) {
        context->prior_development_calls[method_index] = numbers[4u + method_index];
        context->prior_auxiliary_calls[method_index] = numbers[6u + method_index];
        context->prior_wall_nanoseconds[method_index] = numbers[8u + method_index];
        if (context->prior_development_calls[method_index] > 40000u ||
            context->prior_auxiliary_calls[method_index] > 40000u ||
            context->prior_wall_nanoseconds[method_index] > UINT64_C(1800000000000)) {
            return 1;
        }
    }
    return 0;
}

static int is_excluded_workload_seed(uint64_t seed)
{
    static const uint64_t excluded_seeds[] = {777,
        31337,
        90210,
        8675309,
        20260926,
        20260930,
        20261006,
        20261007,
        20261008,
        20261029,
        20261111,
        141421356};
    if (seed <= 63u || (seed >= UINT64_C(2026120101) && seed <= UINT64_C(2026120105)) ||
        (seed >= UINT64_C(2026120201) && seed <= UINT64_C(2026120205))) {
        return 1;
    }
    for (size_t seed_index = 0; seed_index < sizeof(excluded_seeds) / sizeof(excluded_seeds[0]);
        ++seed_index) {
        if (seed == excluded_seeds[seed_index]) {
            return 1;
        }
    }
    return 0;
}

static int digest_matches(const char *path, const char *expected_digest)
{
    char actual_digest[65];
    return !is_paired_hex(expected_digest, 64) || paired_digest_file(path, actual_digest) != 0 ||
        strcmp(actual_digest, expected_digest) != 0;
}

int main(int argument_count, char **argument_values)
{
    struct cohort_context context = {0};
    struct paired_run runs[2] = {0};
    char cohort_path[4096];
    FILE *cohort_file = NULL;
    FILE *report_file = NULL;
    int operation_status = 1;
    long double run_means[2][MAXIMUM_RUN_PAIRS];
    uint64_t run_totals[2][MAXIMUM_RUN_PAIRS];
    uint64_t run_calls[2][MAXIMUM_RUN_PAIRS];
    size_t run_windows[2][MAXIMUM_RUN_PAIRS];
    uint64_t call_totals[2] = {0};
    uint64_t wall_totals[2] = {0};
    uint64_t seeds[MAXIMUM_RUN_PAIRS];
    char block_ids[MAXIMUM_RUN_PAIRS][65];
    char cohort_build_environment[5][PAIRED_TEXT_CAPACITY];
    uint64_t prior_block_finish_nanoseconds = 0;
    size_t pair_count = 0;
    size_t baseline_first_count = 0;
    int all_native_release = 1;
    int formal_shape_valid = 1;
    unsigned confirmation_order[20];
    for (size_t order_index = 0; order_index < 20u; ++order_index) {
        confirmation_order[order_index] = order_index < 10u ? 0u : 1u;
    }
    uint64_t order_random_state = UINT64_C(20261030);
    for (size_t remaining_count = 20; remaining_count > 1u; --remaining_count) {
        size_t selected_index;
        if (draw_paired_index(&order_random_state, remaining_count, &selected_index) != 0) {
            return 1;
        }
        unsigned selected_order = confirmation_order[selected_index];
        confirmation_order[selected_index] = confirmation_order[remaining_count - 1u];
        confirmation_order[remaining_count - 1u] = selected_order;
    }
    if (argument_count != 3) {
        fputs("Usage: analyze_paired COHORT_DIRECTORY NEW_REPORT_FILE\n", stderr);
        return 2;
    }
    if (load_context(argument_values[1], &context) != 0 ||
        paired_data_path(cohort_path, sizeof(cohort_path), argument_values[1], "cohort.csv") != 0 ||
        digest_matches(cohort_path, context.values[18]) != 0) {
        goto cleanup;
    }
    cohort_file = fopen(cohort_path, "r");
    char line[4096];
    if (cohort_file == NULL || fgets(line, sizeof(line), cohort_file) == NULL ||
        strcmp(line, PAIRED_COHORT_HEADER) != 0) {
        goto cleanup;
    }
    while (fgets(line, sizeof(line), cohort_file) != NULL) {
        char *fields[14];
        char data_paths[4][4096];
        if (pair_count >= context.expected_pairs || split_paired_csv(line, fields, 14) != 0 ||
            !is_paired_identifier(fields[0]) ||
            (strcmp(fields[1], "baseline") != 0 && strcmp(fields[1], "candidate") != 0)) {
            goto cleanup;
        }
        for (size_t path_index = 0; path_index < 4u; ++path_index) {
            if (paired_data_path(data_paths[path_index],
                    sizeof(data_paths[path_index]),
                    argument_values[1],
                    fields[path_index + 2u]) != 0) {
                goto cleanup;
            }
        }
        for (size_t method_index = 0; method_index < 2u; ++method_index) {
            char cost_path[4096];
            int cost_path_bytes =
                snprintf(cost_path, sizeof(cost_path), "%s.cost", data_paths[2u * method_index]);
            if (cost_path_bytes < 0 || (size_t)cost_path_bytes >= sizeof(cost_path) ||
                digest_matches(data_paths[2u * method_index], fields[6u + 3u * method_index]) !=
                    0 ||
                digest_matches(data_paths[2u * method_index + 1u],
                    fields[7u + 3u * method_index]) != 0 ||
                digest_matches(cost_path, fields[8u + 3u * method_index]) != 0 ||
                load_paired_run(data_paths[2u * method_index],
                    data_paths[2u * method_index + 1u],
                    &runs[method_index]) != 0 ||
                strcmp(runs[method_index].run_id, fields[0]) != 0 ||
                strcmp(runs[method_index].source_commit, context.values[15]) != 0 ||
                strcmp(runs[method_index].executable_digest, context.values[16u + method_index]) !=
                    0) {
                goto cleanup;
            }
            uint64_t parent_wall_nanoseconds;
            if (parse_unsigned_integer(fields[12u + method_index], &parent_wall_nanoseconds) != 0 ||
                parent_wall_nanoseconds < runs[method_index].child_wall_nanoseconds ||
                parent_wall_nanoseconds > UINT64_C(1800000000000)) {
                goto cleanup;
            }
            run_means[method_index][pair_count] =
                (long double)runs[method_index].total_nanoseconds /
                (long double)runs[method_index].call_count;
            run_totals[method_index][pair_count] = runs[method_index].total_nanoseconds;
            run_calls[method_index][pair_count] = runs[method_index].call_count;
            run_windows[method_index][pair_count] = runs[method_index].window_count;
            call_totals[method_index] += runs[method_index].call_count;
            wall_totals[method_index] += parent_wall_nanoseconds;
            all_native_release &= strcmp(runs[method_index].architecture, "x86_64") == 0 &&
                strncmp(runs[method_index].operating_system, "Linux ", 6) == 0 &&
                strcmp(runs[method_index].sanitizers, "OFF") == 0;
            formal_shape_valid &= runs[method_index].call_count == 6000u;
        }
        if (validate_paired_runs(&runs[0], &runs[1]) != 0 ||
            runs[1].batch_size != context.selected_batch_size) {
            goto cleanup;
        }
        const char *run_build_environment[] = {runs[0].compiler_flags,
            runs[0].compile_options,
            runs[0].architecture,
            runs[0].operating_system,
            runs[0].sanitizers};
        for (size_t environment_index = 0; environment_index < 5u; ++environment_index) {
            if (pair_count == 0) {
                memcpy(cohort_build_environment[environment_index],
                    run_build_environment[environment_index],
                    strlen(run_build_environment[environment_index]) + 1u);
            } else if (strcmp(cohort_build_environment[environment_index],
                           run_build_environment[environment_index]) != 0) {
                goto cleanup;
            }
        }
        unsigned first_method = strcmp(fields[1], "baseline") == 0 ? 0u : 1u;
        if (strcmp(context.values[1], "confirmation") == 0) {
            formal_shape_valid &= first_method == confirmation_order[pair_count] &&
                !is_excluded_workload_seed(runs[0].test_seed) &&
                (context.selected_batch_size == 4u || context.selected_batch_size == 16u);
        }
        if (runs[first_method].child_finish_nanoseconds >=
                runs[1u - first_method].child_start_nanoseconds ||
            runs[first_method].child_start_nanoseconds < prior_block_finish_nanoseconds) {
            goto cleanup;
        }
        prior_block_finish_nanoseconds = runs[1u - first_method].child_finish_nanoseconds;
        baseline_first_count += first_method == 0u ? 1u : 0u;
        for (size_t prior_index = 0; prior_index < pair_count; ++prior_index) {
            if (strcmp(block_ids[prior_index], fields[0]) == 0 ||
                seeds[prior_index] == runs[0].test_seed) {
                goto cleanup;
            }
        }
        memcpy(block_ids[pair_count], fields[0], strlen(fields[0]) + 1u);
        seeds[pair_count] = runs[0].test_seed;
        ++pair_count;
        release_paired_run(&runs[0]);
        release_paired_run(&runs[1]);
    }
    if (ferror(cohort_file) || pair_count < 2u) {
        goto cleanup;
    }
    if (fclose(cohort_file) != 0) {
        cohort_file = NULL;
        goto cleanup;
    }
    cohort_file = NULL;
    struct paired_statistics statistics;
    if (compute_paired_statistics(run_means[0], run_means[1], pair_count, &statistics) != 0) {
        goto cleanup;
    }
    uint64_t shared_calls_per_method = (context.shared_calls_upper + 1u) / 2u;
    int budget_valid = 1;
    long double cost_lower[2];
    long double cost_upper[2];
    for (size_t method_index = 0; method_index < 2u; ++method_index) {
        uint64_t auxiliary_calls = context.prior_auxiliary_calls[method_index] + 100u * pair_count +
            shared_calls_per_method;
        uint64_t development_calls = context.prior_development_calls[method_index] +
            (strcmp(context.values[1], "development") == 0 ? call_totals[method_index] : 0u);
        uint64_t confirmation_calls =
            strcmp(context.values[1], "confirmation") == 0 ? call_totals[method_index] : 0u;
        cost_lower[method_index] = (long double)wall_totals[method_index] +
            (long double)context.prior_wall_nanoseconds[method_index] +
            (long double)context.shared_wall_lower / 2.0L;
        cost_upper[method_index] = (long double)wall_totals[method_index] +
            (long double)context.prior_wall_nanoseconds[method_index] +
            (long double)context.shared_wall_upper / 2.0L;
        budget_valid &= auxiliary_calls <= 40000u && development_calls <= 40000u &&
            confirmation_calls <= 120000u &&
            auxiliary_calls + development_calls + confirmation_calls <= 200000u &&
            cost_upper[method_index] <= 1800000000000.0L;
    }
    long double ratio_at_shared_lower = cost_lower[1] / cost_lower[0];
    long double ratio_at_shared_upper = cost_upper[1] / cost_upper[0];
    long double worst_cost_ratio = fmaxl(ratio_at_shared_lower, ratio_at_shared_upper);
    int dependence_valid = strcmp(context.values[13], "accepted") == 0 &&
        (!statistics.baseline.has_lag1_correlation ||
            fabsl(statistics.baseline.lag1_correlation) < 0.5L) &&
        (!statistics.candidate.has_lag1_correlation ||
            fabsl(statistics.candidate.lag1_correlation) < 0.5L) &&
        statistics.baseline.half_mean_relative_change <= 0.05L &&
        statistics.candidate.half_mean_relative_change <= 0.05L;
    int qualification_valid = strcmp(context.values[1], "confirmation") == 0 && pair_count == 20u &&
        pair_count == context.expected_pairs && baseline_first_count == 10u && formal_shape_valid &&
        all_native_release && strcmp(context.values[12], "accepted") == 0 &&
        strcmp(context.values[14], "unclosed") != 0 && dependence_valid && budget_valid;
    const char *result_label =
        paired_result_label(&statistics, worst_cost_ratio, qualification_valid);
    report_file = fopen(argument_values[2], "wx");
    if (report_file == NULL) {
        goto cleanup;
    }
    if (fprintf(report_file,
            "format=paired_stability_report_v1\nphase=%s\nsource_commit=%s\npaired_unit=complete_"
            "run_block\n"
            "pair_count=%zu\nexpected_pairs=%" PRIu64 "\nbatch_size=%" PRIu64
            "\nbaseline_first_count=%zu\ncohort_manifest_digest=%s\n"
            "median_rule=even_middle_two_average\nmad_rule=median_absolute_deviation\n"
            "bootstrap=paired_splitmix64_rejection_sampling\nbootstrap_seed=20261029\n"
            "bootstrap_replicates=10000\nbootstrap_interval=type7_percentile_0.005_0.995\n"
            "bootstrap_resampled_pair_count=%zu\n"
            "bootstrap_degenerate_replicates=%zu\ninterval_available=%s\n"
            "baseline_calls=%" PRIu64 "\ncandidate_calls=%" PRIu64 "\n"
            "baseline_run_median_ns=%.17Lg\nbaseline_run_mad_ns=%.17Lg\nbaseline_s=%.17Lg\n"
            "candidate_run_median_ns=%.17Lg\ncandidate_run_mad_ns=%.17Lg\ncandidate_s=%.17Lg\n"
            "center_relative_change=%.17Lg\ncenter_limit=0.05\n"
            "baseline_cost_lower_ns=%.17Lg\nbaseline_cost_upper_ns=%.17Lg\n"
            "candidate_cost_lower_ns=%.17Lg\ncandidate_cost_upper_ns=%.17Lg\n"
            "cost_ratio_worst_case=%.17Lg\nbudget_valid=%s\ndependency_review_valid=%s\n"
            "inference_qualification=%s\nresult=%s\n"
            "candidate_single_call_p99=unavailable\ncategory_times=unavailable_for_mixed_windows\n",
            context.values[1],
            context.values[15],
            pair_count,
            context.expected_pairs,
            context.selected_batch_size,
            baseline_first_count,
            context.values[18],
            pair_count,
            statistics.degenerate_replicates,
            statistics.has_interval ? "yes" : "no",
            call_totals[0],
            call_totals[1],
            statistics.baseline.median_nanoseconds,
            statistics.baseline.mad_nanoseconds,
            statistics.baseline.relative_dispersion,
            statistics.candidate.median_nanoseconds,
            statistics.candidate.mad_nanoseconds,
            statistics.candidate.relative_dispersion,
            statistics.center_relative_change,
            cost_lower[0],
            cost_upper[0],
            cost_lower[1],
            cost_upper[1],
            worst_cost_ratio,
            budget_valid ? "yes" : "no",
            dependence_valid ? "yes" : "no",
            qualification_valid ? "eligible_under_frozen_assumptions" : "insufficient",
            result_label) < 0) {
        goto cleanup;
    }
    if (statistics.has_point_ratio &&
        fprintf(report_file, "s_ratio=%.17Lg\n", statistics.dispersion_ratio) < 0) {
        goto cleanup;
    }
    if (statistics.has_interval &&
        fprintf(report_file,
            "interval_lower=%.17Lg\ninterval_upper=%.17Lg\n",
            statistics.interval_lower,
            statistics.interval_upper) < 0) {
        goto cleanup;
    }
    if (fprintf(report_file,
            "baseline_lag1=%.17Lg\ncandidate_lag1=%.17Lg\n"
            "baseline_lag1_available=%s\ncandidate_lag1_available=%s\n"
            "baseline_half_mean_change=%.17Lg\ncandidate_half_mean_change=%.17Lg\n"
            "shared_calls_upper=%" PRIu64 "\nshared_wall_lower_ns=%" PRIu64
            "\nshared_wall_upper_ns=%" PRIu64 "\nprior_baseline_development_calls=%" PRIu64
            "\nprior_candidate_development_calls=%" PRIu64
            "\nprior_baseline_auxiliary_calls=%" PRIu64 "\nprior_candidate_auxiliary_calls=%" PRIu64
            "\n",
            statistics.baseline.lag1_correlation,
            statistics.candidate.lag1_correlation,
            statistics.baseline.has_lag1_correlation ? "yes" : "no",
            statistics.candidate.has_lag1_correlation ? "yes" : "no",
            statistics.baseline.half_mean_relative_change,
            statistics.candidate.half_mean_relative_change,
            context.shared_calls_upper,
            context.shared_wall_lower,
            context.shared_wall_upper,
            context.prior_development_calls[0],
            context.prior_development_calls[1],
            context.prior_auxiliary_calls[0],
            context.prior_auxiliary_calls[1]) < 0) {
        goto cleanup;
    }
    for (size_t pair_index = 0; pair_index < pair_count; ++pair_index) {
        if (fprintf(report_file,
                "block=%s baseline_total_ns=%" PRIu64 " baseline_calls=%" PRIu64
                " baseline_windows=%zu baseline_run_mean_ns=%.17Lg candidate_total_ns=%" PRIu64
                " candidate_calls=%" PRIu64 " candidate_windows=%zu candidate_run_mean_ns=%.17Lg\n",
                block_ids[pair_index],
                run_totals[0][pair_index],
                run_calls[0][pair_index],
                run_windows[0][pair_index],
                run_means[0][pair_index],
                run_totals[1][pair_index],
                run_calls[1][pair_index],
                run_windows[1][pair_index],
                run_means[1][pair_index]) < 0) {
            goto cleanup;
        }
    }
    if (fputs("report_status=complete\n", report_file) == EOF) {
        goto cleanup;
    }
    operation_status = 0;
cleanup:
    release_paired_run(&runs[0]);
    release_paired_run(&runs[1]);
    if (cohort_file != NULL && fclose(cohort_file) != 0) {
        operation_status = 1;
    }
    if (report_file != NULL && fclose(report_file) != 0) {
        operation_status = 1;
    }
    if (operation_status != 0) {
        fputs("software_check_failed: paired data/report validation failed; preserve partial "
              "output\n",
            stderr);
    }
    return operation_status;
}
