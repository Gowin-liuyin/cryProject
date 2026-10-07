#define _POSIX_C_SOURCE 200809L

#include "build_identity.h"
#include "controlled_statistics.h"
#include "paired_data.h"

#include <inttypes.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/stat.h>
#include <time.h>
#include <unistd.h>

#define CALIBRATION_PAIRS 12u
#define CALIBRATION_ASSIGNMENTS UINT64_C(4096)
#define CALIBRATION_MAXIMUM_SUM_NS INT64_C(222)
#define CALIBRATION_DISTRIBUTION_SIZE 445u
#define CALIBRATION_BUDGET_NS UINT64_C(120000000000)

static int read_clock_ns(uint64_t *time_ns)
{
    struct timespec reading;
    if (clock_gettime(CLOCK_MONOTONIC, &reading) != 0) {
        return 1;
    }
    *time_ns = (uint64_t)reading.tv_sec * UINT64_C(1000000000) + (uint64_t)reading.tv_nsec;
    return 0;
}

static int within_budget(uint64_t start_ns)
{
    uint64_t current_ns;
    return read_clock_ns(&current_ns) == 0 && current_ns >= start_ns &&
        current_ns - start_ns <= CALIBRATION_BUDGET_NS;
}

static int convolution_tail(const int64_t *differences_ns, size_t pair_count, uint64_t *tail_count)
{
    uint64_t distribution[CALIBRATION_DISTRIBUTION_SIZE] = {0};
    uint64_t next_distribution[CALIBRATION_DISTRIBUTION_SIZE];
    int64_t absolute_total_ns = 0;
    int64_t observed_sum_ns = 0;
    for (size_t pair_index = 0; pair_index < pair_count; ++pair_index) {
        int64_t difference_ns = differences_ns[pair_index];
        if (difference_ns < -CALIBRATION_MAXIMUM_SUM_NS ||
            difference_ns > CALIBRATION_MAXIMUM_SUM_NS) {
            return 1;
        }
        absolute_total_ns += difference_ns < 0 ? -difference_ns : difference_ns;
        observed_sum_ns += difference_ns;
    }
    if (absolute_total_ns > CALIBRATION_MAXIMUM_SUM_NS) {
        return 1;
    }
    // 分布卷积不沿用候选的Gray枚举，零幅度也保留两种标签的重数。
    distribution[(size_t)CALIBRATION_MAXIMUM_SUM_NS] = 1;
    for (size_t pair_index = 0; pair_index < pair_count; ++pair_index) {
        memset(next_distribution, 0, sizeof(next_distribution));
        int64_t magnitude_ns = differences_ns[pair_index] < 0 ? -differences_ns[pair_index]
                                                              : differences_ns[pair_index];
        for (size_t sum_index = 0; sum_index < CALIBRATION_DISTRIBUTION_SIZE; ++sum_index) {
            if (distribution[sum_index] == 0) {
                continue;
            }
            int64_t centered_sum_ns = (int64_t)sum_index - CALIBRATION_MAXIMUM_SUM_NS;
            size_t positive_index =
                (size_t)(centered_sum_ns + magnitude_ns + CALIBRATION_MAXIMUM_SUM_NS);
            size_t negative_index =
                (size_t)(centered_sum_ns - magnitude_ns + CALIBRATION_MAXIMUM_SUM_NS);
            next_distribution[positive_index] += distribution[sum_index];
            next_distribution[negative_index] += distribution[sum_index];
        }
        memcpy(distribution, next_distribution, sizeof(distribution));
    }
    int64_t observed_absolute_ns = observed_sum_ns < 0 ? -observed_sum_ns : observed_sum_ns;
    *tail_count = 0;
    uint64_t total_count = 0;
    for (size_t sum_index = 0; sum_index < CALIBRATION_DISTRIBUTION_SIZE; ++sum_index) {
        int64_t centered_sum_ns = (int64_t)sum_index - CALIBRATION_MAXIMUM_SUM_NS;
        int64_t absolute_sum_ns = centered_sum_ns < 0 ? -centered_sum_ns : centered_sum_ns;
        total_count += distribution[sum_index];
        if (absolute_sum_ns >= observed_absolute_ns) {
            *tail_count += distribution[sum_index];
        }
    }
    return total_count != (UINT64_C(1) << pair_count);
}

static int self_test(void)
{
    const int64_t separated[4] = {1, 1, 1, 1};
    const int64_t balanced[4] = {1, -1, 1, -1};
    const int64_t mixed_zero[4] = {2, -1, 0, 3};
    int64_t almost_separated[CALIBRATION_PAIRS];
    for (size_t pair_index = 0; pair_index < CALIBRATION_PAIRS; ++pair_index) {
        almost_separated[pair_index] = pair_index == 0 ? -1 : 1;
    }
    uint64_t tail_count;
    if (convolution_tail(separated, 4, &tail_count) != 0 || tail_count != 2u ||
        convolution_tail(balanced, 4, &tail_count) != 0 || tail_count != 16u ||
        convolution_tail(mixed_zero, 4, &tail_count) != 0 || tail_count != 8u ||
        convolution_tail(almost_separated, CALIBRATION_PAIRS, &tail_count) != 0 ||
        tail_count != 26u) {
        return 1;
    }
    return 0;
}

static int write_dependent_case(const char *directory,
    const char *model,
    uint64_t assignment_index,
    const int64_t differences_ns[CALIBRATION_PAIRS])
{
    char csv_path[4096];
    char plan_path[4096];
    int csv_bytes = snprintf(csv_path,
        sizeof(csv_path),
        "%s/%s-%" PRIu64 ".csv",
        directory,
        model,
        assignment_index);
    int plan_bytes = snprintf(plan_path,
        sizeof(plan_path),
        "%s/%s-%" PRIu64 ".plan",
        directory,
        model,
        assignment_index);
    if (csv_bytes < 0 || (size_t)csv_bytes >= sizeof(csv_path) || plan_bytes < 0 ||
        (size_t)plan_bytes >= sizeof(plan_path)) {
        return 1;
    }
    FILE *csv_file = fopen(csv_path, "wx");
    if (csv_file == NULL) {
        return 1;
    }
    int operation_status =
        fputs("pair_index,first_total_ns,second_total_ns,call_count\n", csv_file) == EOF;
    for (size_t pair_index = 0; pair_index < CALIBRATION_PAIRS && !operation_status; ++pair_index) {
        operation_status = fprintf(csv_file,
                               "%zu,%" PRId64 ",500,1\n",
                               pair_index,
                               INT64_C(500) + differences_ns[pair_index]) < 0;
    }
    if (fclose(csv_file) != 0 || operation_status) {
        return 1;
    }
    char digest[65];
    if (paired_digest_file(csv_path, digest) != 0) {
        return 1;
    }
    FILE *plan_file = fopen(plan_path, "wx");
    if (plan_file == NULL) {
        return 1;
    }
    operation_status =
        fprintf(plan_file,
            "format=controlled_plan_v1\nsource_kind=no_secret_synthetic\nrandomization=unverified\n"
            "no_carryover=verified\ninterval_iid=unverified\ndata_digest=%s\n"
            "source_csv_digest=none_synthetic\ngenerator_seed=0\n"
            "generator_kind=finite_common_sign\nassignment_index=%" PRIu64 "\n",
            digest,
            assignment_index) < 0;
    if (fclose(plan_file) != 0) {
        operation_status = 1;
    }
    return operation_status;
}

static int run_model(FILE *records,
    FILE *summary,
    const char *directory,
    size_t profile_index,
    int64_t effect_ns,
    int shared_sign,
    uint64_t start_ns)
{
    const char *model = profile_index == 0 ? (shared_sign ? "common_equal" : "independent_equal")
        : shared_sign                      ? "common_graded"
                                           : "independent_graded";
    uint64_t model_assignment_count = shared_sign ? 2u : CALIBRATION_ASSIGNMENTS;
    uint64_t raw_rejections = 0;
    uint64_t zero_datasets = 0;
    for (uint64_t assignment_index = 0; assignment_index < model_assignment_count;
        ++assignment_index) {
        if (!within_budget(start_ns)) {
            return 1;
        }
        int64_t differences_ns[CALIBRATION_PAIRS];
        for (size_t pair_index = 0; pair_index < CALIBRATION_PAIRS; ++pair_index) {
            int64_t magnitude_ns = profile_index == 0 ? 1 : (int64_t)pair_index + 1;
            uint64_t sign_bit =
                shared_sign ? assignment_index : (assignment_index >> pair_index) & 1u;
            differences_ns[pair_index] = effect_ns + (sign_bit ? magnitude_ns : -magnitude_ns);
        }
        struct controlled_result result;
        uint64_t oracle_tail;
        if (compute_controlled_result(differences_ns, CALIBRATION_PAIRS, 0, &result) != 0 ||
            convolution_tail(differences_ns, CALIBRATION_PAIRS, &oracle_tail) != 0) {
            return 1;
        }
        int raw_reject = result.tail_count * 100u <= CALIBRATION_ASSIGNMENTS;
        raw_rejections += (uint64_t)raw_reject;
        zero_datasets += (uint64_t)!result.has_variation;
        if (fprintf(records,
                "%s,%" PRId64 ",%" PRIu64 ",%" PRIu64,
                model,
                effect_ns,
                model_assignment_count,
                assignment_index) < 0) {
            return 1;
        }
        for (size_t pair_index = 0; pair_index < CALIBRATION_PAIRS; ++pair_index) {
            if (fprintf(records, ",%" PRId64, differences_ns[pair_index]) < 0) {
                return 1;
            }
        }
        if (fprintf(records,
                ",%" PRIu64 ",%" PRIu64 ",%" PRIu64 ",%d,%d\n",
                result.tail_count,
                oracle_tail,
                result.assignment_count,
                !result.has_variation,
                raw_reject) < 0 ||
            result.assignment_count != CALIBRATION_ASSIGNMENTS ||
            result.tail_count != oracle_tail ||
            (shared_sign &&
                write_dependent_case(directory, model, assignment_index, differences_ns) != 0)) {
            return 1;
        }
    }
    if ((!shared_sign && effect_ns == 0 && raw_rejections * 100u > model_assignment_count) ||
        (!shared_sign && profile_index == 0 && effect_ns == 0 && raw_rejections != 26u)) {
        return 1;
    }
    return fprintf(summary,
               "model=%s effect_ns=%" PRId64 " population=%" PRIu64 " raw_rejections=%" PRIu64
               " raw_probability=%.12Lf all_zero=%" PRIu64 " randomization_qualification=%s\n",
               model,
               effect_ns,
               model_assignment_count,
               raw_rejections,
               (long double)raw_rejections / (long double)model_assignment_count,
               zero_datasets,
               shared_sign ? "insufficient" : "finite_independent_model_only") < 0;
}

int main(int argument_count, char **argument_values)
{
    if (argument_count == 2 && strcmp(argument_values[1], "--self-test") == 0) {
        return self_test();
    }
    if (argument_count != 2) {
        fputs("Usage: calibrate_controlled NEW_DIRECTORY\n", stderr);
        return 2;
    }
    uint64_t start_ns;
    if (read_clock_ns(&start_ns) != 0 || mkdir(argument_values[1], 0700) != 0) {
        return 1;
    }
    char records_path[4096];
    char summary_path[4096];
    if (paired_data_path(records_path, sizeof(records_path), argument_values[1], "raw.csv") != 0 ||
        paired_data_path(summary_path,
            sizeof(summary_path),
            argument_values[1],
            "summary.partial") != 0) {
        return 1;
    }
    FILE *records = fopen(records_path, "wx");
    FILE *summary = fopen(summary_path, "wx");
    int operation_status = 1;
    if (records == NULL || summary == NULL) {
        goto cleanup;
    }
    for (size_t line_index = 0;
        line_index < sizeof(build_identity_lines) / sizeof(build_identity_lines[0]);
        ++line_index) {
        if (fputs(build_identity_lines[line_index], summary) == EOF) {
            goto cleanup;
        }
    }
    if (fputs(
            "format=finite_controlled_calibration_v1\nsource_kind=no_secret_finite_model\n"
            "pair_count=12\nalpha=0.01\ninterval_status=unavailable\nmlkem_decapsulation_calls=0\n"
            "task_budget_ns=120000000000\n",
            summary) == EOF ||
        fputs("model,effect_ns,model_assignment_count,assignment_index", records) == EOF) {
        goto cleanup;
    }
    for (size_t pair_index = 0; pair_index < CALIBRATION_PAIRS; ++pair_index) {
        if (fprintf(records, ",difference_%zu_ns", pair_index) < 0) {
            goto cleanup;
        }
    }
    if (fputs(",tail_count,oracle_tail_count,permutation_count,all_zero,raw_reject\n", records) ==
        EOF) {
        goto cleanup;
    }
    const int64_t effects_ns[5] = {0, 1, 2, 4, 12};
    for (size_t profile_index = 0; profile_index < 2u; ++profile_index) {
        for (size_t effect_index = 0; effect_index < 5u; ++effect_index) {
            if (run_model(records,
                    summary,
                    argument_values[1],
                    profile_index,
                    effects_ns[effect_index],
                    0,
                    start_ns) != 0) {
                goto cleanup;
            }
        }
        if (run_model(records, summary, argument_values[1], profile_index, 0, 1, start_ns) != 0) {
            goto cleanup;
        }
    }
    int records_close_status = fclose(records);
    records = NULL;
    uint64_t finish_ns;
    char raw_digest[65];
    if (records_close_status != 0 || read_clock_ns(&finish_ns) != 0 || finish_ns < start_ns ||
        finish_ns - start_ns > CALIBRATION_BUDGET_NS ||
        paired_digest_file(records_path, raw_digest) != 0 ||
        fprintf(summary,
            "datasets=40964\noracle_mismatches=0\nraw_digest=%s\ntask_wall_ns=%" PRIu64
            "\nfinal_digest_and_status_write=outside_task_wall\n"
            "result_scope=finite_model_only\nsecret_attribution=not_assessed\n"
            "report_status=complete\n",
            raw_digest,
            finish_ns - start_ns) < 0) {
        goto cleanup;
    }
    int summary_close_status = fclose(summary);
    summary = NULL;
    char final_path[4096];
    if (summary_close_status != 0 ||
        paired_data_path(final_path, sizeof(final_path), argument_values[1], "summary.report") !=
            0 ||
        link(summary_path, final_path) != 0) {
        goto cleanup;
    }
    (void)unlink(summary_path);
    operation_status = 0;
cleanup:
    if (records != NULL && fclose(records) != 0) {
        operation_status = 1;
    }
    if (summary != NULL && fclose(summary) != 0) {
        operation_status = 1;
    }
    return operation_status;
}
