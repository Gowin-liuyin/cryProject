#define _POSIX_C_SOURCE 200809L

#include "build_identity.h"
#include "controlled_statistics.h"
#include "paired_data.h"
#include "v4_stats.h"

#include <inttypes.h>
#include <stdarg.h>
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

static int compare_unsigned_sums(const void *first_value, const void *second_value)
{
    uint64_t first_sum = *(const uint64_t *)first_value;
    uint64_t second_sum = *(const uint64_t *)second_value;
    return first_sum < second_sum ? -1 : first_sum > second_sum ? 1 : 0;
}

static int independent_distribution(const int64_t *differences_ns,
    size_t pair_count,
    uint64_t sorted_sums[CALIBRATION_ASSIGNMENTS])
{
    if (pair_count < 4u || pair_count > CALIBRATION_PAIRS) {
        return 1;
    }
    for (size_t pair_index = 0; pair_index < pair_count; ++pair_index) {
        if (differences_ns[pair_index] < -CONTROLLED_MAXIMUM_DIFFERENCE_NS ||
            differences_ns[pair_index] > CONTROLLED_MAXIMUM_DIFFERENCE_NS) {
            return 1;
        }
    }
    size_t assignment_count = (size_t)1u << pair_count;
    for (size_t assignment_index = 0; assignment_index < assignment_count; ++assignment_index) {
        int64_t signed_sum = 0;
        for (size_t pair_index = 0; pair_index < pair_count; ++pair_index) {
            signed_sum += (assignment_index >> pair_index) & 1u ? differences_ns[pair_index]
                                                                : -differences_ns[pair_index];
        }
        sorted_sums[assignment_index] = (uint64_t)(signed_sum < 0 ? -signed_sum : signed_sum);
    }
    qsort(sorted_sums, assignment_count, sizeof(*sorted_sums), compare_unsigned_sums);
    return 0;
}

static uint64_t
distribution_tail(const uint64_t *sorted_sums, size_t assignment_count, int64_t observed_sum)
{
    uint64_t observed_absolute = (uint64_t)(observed_sum < 0 ? -observed_sum : observed_sum);
    size_t lower_index = 0;
    size_t upper_index = assignment_count;
    while (lower_index < upper_index) {
        size_t middle_index = lower_index + (upper_index - lower_index) / 2u;
        if (sorted_sums[middle_index] < observed_absolute) {
            lower_index = middle_index + 1u;
        } else {
            upper_index = middle_index;
        }
    }
    return (uint64_t)(assignment_count - lower_index);
}

static int self_test(void)
{
    const int64_t separated[4] = {1, 1, 1, 1};
    const int64_t balanced[4] = {1, -1, 1, -1};
    const int64_t mixed_zero[4] = {2, -1, 0, 3};
    const int64_t maximum_difference[4] = {CONTROLLED_MAXIMUM_DIFFERENCE_NS,
        CONTROLLED_MAXIMUM_DIFFERENCE_NS,
        CONTROLLED_MAXIMUM_DIFFERENCE_NS,
        CONTROLLED_MAXIMUM_DIFFERENCE_NS};
    const int64_t invalid_difference[4] = {CONTROLLED_MAXIMUM_DIFFERENCE_NS + 1, 0, 0, 0};
    int64_t almost_separated[CALIBRATION_PAIRS];
    int64_t maximum_span[CALIBRATION_PAIRS];
    int64_t excessive_span[CALIBRATION_PAIRS];
    for (size_t pair_index = 0; pair_index < CALIBRATION_PAIRS; ++pair_index) {
        almost_separated[pair_index] = pair_index == 0 ? -1 : 1;
        maximum_span[pair_index] = (int64_t)pair_index + 13;
        excessive_span[pair_index] = CALIBRATION_MAXIMUM_SUM_NS;
    }
    uint64_t tail_count;
    uint64_t sorted_sums[CALIBRATION_ASSIGNMENTS];
    if (convolution_tail(separated, 4, &tail_count) != 0 || tail_count != 2u ||
        convolution_tail(balanced, 4, &tail_count) != 0 || tail_count != 16u ||
        convolution_tail(mixed_zero, 4, &tail_count) != 0 || tail_count != 8u ||
        convolution_tail(almost_separated, CALIBRATION_PAIRS, &tail_count) != 0 ||
        tail_count != 26u || convolution_tail(maximum_span, CALIBRATION_PAIRS, &tail_count) != 0 ||
        tail_count != 2u || convolution_tail(excessive_span, CALIBRATION_PAIRS, &tail_count) == 0) {
        return 1;
    }
    if (independent_distribution(separated, 4, sorted_sums) != 0 ||
        distribution_tail(sorted_sums, 16, 4) != 2u ||
        distribution_tail(sorted_sums, 16, 2) != 10u ||
        distribution_tail(sorted_sums, 16, 0) != 16u ||
        independent_distribution(mixed_zero, 4, sorted_sums) != 0 ||
        distribution_tail(sorted_sums, 16, 4) != 8u ||
        independent_distribution(maximum_difference, 4, sorted_sums) != 0 ||
        distribution_tail(sorted_sums, 16, 4 * CONTROLLED_MAXIMUM_DIFFERENCE_NS) != 2u ||
        independent_distribution(invalid_difference, 4, sorted_sums) == 0) {
        return 1;
    }
    return 0;
}

static int write_controlled_record(FILE *records,
    const char *model,
    int64_t effect_ns,
    uint64_t model_assignment_count,
    uint64_t assignment_index,
    const int64_t differences_ns[CALIBRATION_PAIRS],
    const struct controlled_result *result,
    uint64_t oracle_tail)
{
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
    return fprintf(records,
               ",%" PRIu64 ",%" PRIu64 ",%" PRIu64 ",%d,%d\n",
               result->tail_count,
               oracle_tail,
               result->assignment_count,
               !result->has_variation,
               result->tail_count * 100u <= CALIBRATION_ASSIGNMENTS) < 0 ||
        result->assignment_count != CALIBRATION_ASSIGNMENTS || result->tail_count != oracle_tail;
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
        if (write_controlled_record(records,
                model,
                effect_ns,
                model_assignment_count,
                assignment_index,
                differences_ns,
                &result,
                oracle_tail) != 0 ||
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

static int run_reference_block(FILE *records,
    FILE *summary,
    FILE *selected_records,
    const char *input_directory,
    size_t block_index,
    uint64_t start_ns)
{
    char paths[3][4096];
    char name[128];
    char run_id[65];
    char original_digests[3][65];
    const char *suffixes[3] = {"csv", "meta", "csv.cost"};
    (void)snprintf(run_id, sizeof(run_id), "ordinary-reference-block%zu", block_index);
    for (size_t file_index = 0; file_index < 3u; ++file_index) {
        (void)snprintf(name, sizeof(name), "%s.%s", run_id, suffixes[file_index]);
        if (paired_data_path(paths[file_index], sizeof(paths[file_index]), input_directory, name) !=
                0 ||
            paired_digest_file(paths[file_index], original_digests[file_index]) != 0) {
            return 1;
        }
    }
    struct ordinary_dataset dataset;
    if (load_ordinary_dataset(paths[0], paths[1], &dataset) != 0) {
        return 1;
    }
    struct measurement_set source_set = dataset.measurements;
    if (source_set.record_count != 3000u || strcmp(source_set.implementation, "reference") != 0 ||
        strcmp(source_set.run_id, run_id) != 0) {
        free(source_set.records);
        return 1;
    }
    int64_t original_differences[CALIBRATION_PAIRS];
    for (size_t sample_index = 0; sample_index < 2u * CALIBRATION_PAIRS; ++sample_index) {
        uint64_t elapsed_ns = source_set.records[sample_index].elapsed_nanoseconds;
        if (elapsed_ns > (uint64_t)CONTROLLED_MAXIMUM_DIFFERENCE_NS ||
            fprintf(selected_records, "%s,%zu,%" PRIu64 ",ns\n", run_id, sample_index, elapsed_ns) <
                0) {
            free(source_set.records);
            return 1;
        }
    }
    for (size_t pair_index = 0; pair_index < CALIBRATION_PAIRS; ++pair_index) {
        original_differences[pair_index] =
            (int64_t)source_set.records[2u * pair_index].elapsed_nanoseconds -
            (int64_t)source_set.records[2u * pair_index + 1u].elapsed_nanoseconds;
    }
    free(source_set.records);
    uint64_t sorted_sums[CALIBRATION_ASSIGNMENTS];
    if (independent_distribution(original_differences, CALIBRATION_PAIRS, sorted_sums) != 0) {
        return 1;
    }
    uint64_t raw_rejections = 0;
    uint64_t zero_datasets = 0;
    for (uint64_t assignment_index = 0; assignment_index < CALIBRATION_ASSIGNMENTS;
        ++assignment_index) {
        if (!within_budget(start_ns)) {
            return 1;
        }
        int64_t differences_ns[CALIBRATION_PAIRS];
        int64_t observed_sum = 0;
        for (size_t pair_index = 0; pair_index < CALIBRATION_PAIRS; ++pair_index) {
            differences_ns[pair_index] = (assignment_index >> pair_index) & 1u
                ? original_differences[pair_index]
                : -original_differences[pair_index];
            observed_sum += differences_ns[pair_index];
        }
        struct controlled_result result;
        uint64_t oracle_tail =
            distribution_tail(sorted_sums, (size_t)CALIBRATION_ASSIGNMENTS, observed_sum);
        if (compute_controlled_result(differences_ns, CALIBRATION_PAIRS, 0, &result) != 0 ||
            write_controlled_record(records,
                run_id,
                0,
                CALIBRATION_ASSIGNMENTS,
                assignment_index,
                differences_ns,
                &result,
                oracle_tail) != 0) {
            return 1;
        }
        raw_rejections += (uint64_t)(result.tail_count * 100u <= CALIBRATION_ASSIGNMENTS);
        zero_datasets += (uint64_t)!result.has_variation;
    }
    for (size_t file_index = 0; file_index < 3u; ++file_index) {
        char final_digest[65];
        if (paired_digest_file(paths[file_index], final_digest) != 0 ||
            strcmp(final_digest, original_digests[file_index]) != 0) {
            return 1;
        }
    }
    return raw_rejections > 40u ||
        fprintf(summary,
            "source_run=%s csv_digest=%s meta_digest=%s cost_digest=%s source_records=3000 "
            "selected_indices=0..23 assignment_count=4096 raw_rejections=%" PRIu64
            " conditional_probability=%.12Lf all_zero=%" PRIu64 "\n",
            run_id,
            original_digests[0],
            original_digests[1],
            original_digests[2],
            raw_rejections,
            (long double)raw_rejections / (long double)CALIBRATION_ASSIGNMENTS,
            zero_datasets) < 0;
}

static int emit_line(FILE *conclusion, const char *format, ...)
{
    va_list first_args;
    va_list second_args;
    va_start(first_args, format);
    va_copy(second_args, first_args);
    int file_status = vfprintf(conclusion, format, first_args);
    int stdout_status = vfprintf(stdout, format, second_args);
    va_end(second_args);
    va_end(first_args);
    return file_status < 0 || stdout_status < 0;
}

static int run_redraw_block(FILE *records,
    FILE *conclusion,
    FILE *selected_records,
    const char *input_directory,
    unsigned block_number,
    uint64_t start_ns)
{
    char paths[3][4096];
    char name[128];
    char run_id[65];
    char original_digests[3][65];
    const char *suffixes[3] = {"csv", "meta", "csv.cost"};
    uint32_t indices[V4_LABEL_DRAW_COUNT];
    uint8_t index_seen[V4_LABEL_POPULATION];
    (void)snprintf(run_id, sizeof(run_id), "ordinary-reference-block%u", block_number);
    for (size_t file_index = 0; file_index < 3u; ++file_index) {
        (void)snprintf(name, sizeof(name), "%s.%s", run_id, suffixes[file_index]);
        if (paired_data_path(paths[file_index], sizeof(paths[file_index]), input_directory, name) !=
                0 ||
            paired_digest_file(paths[file_index], original_digests[file_index]) != 0) {
            return 1;
        }
    }
    struct ordinary_dataset dataset;
    if (load_ordinary_dataset(paths[0], paths[1], &dataset) != 0) {
        return 1;
    }
    struct measurement_set source_set = dataset.measurements;
    if (source_set.record_count != V4_LABEL_POPULATION ||
        strcmp(source_set.implementation, "reference") != 0 ||
        strcmp(source_set.run_id, run_id) != 0 || v4_label_draw(block_number, indices) != 0) {
        free(source_set.records);
        return 1;
    }
    memset(index_seen, 0, sizeof(index_seen));
    int64_t original_differences[CALIBRATION_PAIRS];
    for (size_t draw_index = 0; draw_index < V4_LABEL_DRAW_COUNT; ++draw_index) {
        uint32_t sample_index = indices[draw_index];
        if (sample_index >= V4_LABEL_POPULATION || index_seen[sample_index] != 0) {
            free(source_set.records);
            return 1;
        }
        index_seen[sample_index] = 1;
        uint64_t elapsed_ns = source_set.records[sample_index].elapsed_nanoseconds;
        if (elapsed_ns > (uint64_t)CONTROLLED_MAXIMUM_DIFFERENCE_NS ||
            fprintf(selected_records,
                "%s,%zu,%" PRIu32 ",%" PRIu64 ",ns\n",
                run_id,
                draw_index,
                sample_index,
                elapsed_ns) < 0) {
            free(source_set.records);
            return 1;
        }
    }
    for (size_t pair_index = 0; pair_index < CALIBRATION_PAIRS; ++pair_index) {
        uint32_t first_index = indices[2u * pair_index];
        uint32_t second_index = indices[2u * pair_index + 1u];
        original_differences[pair_index] =
            (int64_t)source_set.records[first_index].elapsed_nanoseconds -
            (int64_t)source_set.records[second_index].elapsed_nanoseconds;
    }
    free(source_set.records);
    uint64_t sorted_sums[CALIBRATION_ASSIGNMENTS];
    if (independent_distribution(original_differences, CALIBRATION_PAIRS, sorted_sums) != 0) {
        return 1;
    }
    uint64_t raw_rejections = 0;
    for (uint64_t assignment_index = 0; assignment_index < CALIBRATION_ASSIGNMENTS;
        ++assignment_index) {
        if (!within_budget(start_ns)) {
            return 1;
        }
        int64_t differences_ns[CALIBRATION_PAIRS];
        int64_t observed_sum = 0;
        for (size_t pair_index = 0; pair_index < CALIBRATION_PAIRS; ++pair_index) {
            differences_ns[pair_index] = (assignment_index >> pair_index) & 1u
                ? original_differences[pair_index]
                : -original_differences[pair_index];
            observed_sum += differences_ns[pair_index];
        }
        struct controlled_result result;
        uint64_t oracle_tail =
            distribution_tail(sorted_sums, (size_t)CALIBRATION_ASSIGNMENTS, observed_sum);
        if (compute_controlled_result(differences_ns, CALIBRATION_PAIRS, 0, &result) != 0 ||
            write_controlled_record(records,
                run_id,
                0,
                CALIBRATION_ASSIGNMENTS,
                assignment_index,
                differences_ns,
                &result,
                oracle_tail) != 0) {
            return 1;
        }
        raw_rejections += (uint64_t)(result.tail_count * 100u <= CALIBRATION_ASSIGNMENTS);
    }
    for (size_t file_index = 0; file_index < 3u; ++file_index) {
        char final_digest[65];
        if (paired_digest_file(paths[file_index], final_digest) != 0 ||
            strcmp(final_digest, original_digests[file_index]) != 0) {
            return 1;
        }
    }
    char index_text[512];
    size_t used_bytes = 0;
    for (size_t draw_index = 0; draw_index < V4_LABEL_DRAW_COUNT; ++draw_index) {
        int written = snprintf(index_text + used_bytes,
            sizeof(index_text) - used_bytes,
            "%s%" PRIu32,
            draw_index == 0u ? "" : ",",
            indices[draw_index]);
        if (written < 0 || (size_t)written >= sizeof(index_text) - used_bytes) {
            return 1;
        }
        used_bytes += (size_t)written;
    }
    /* 旧路径把拒绝数高于 40 当成固定原序的失败。重抽只复述同一统计量。 */
    return emit_line(conclusion, "block=%u\n", block_number) ||
        emit_line(conclusion, "csv_digest=%s\n", original_digests[0]) ||
        emit_line(conclusion, "meta_digest=%s\n", original_digests[1]) ||
        emit_line(conclusion, "cost_digest=%s\n", original_digests[2]) ||
        emit_line(conclusion, "raw_rejections=%" PRIu64 "\n", raw_rejections) ||
        emit_line(conclusion,
            "conditional_probability=%.12Lf\n",
            (long double)raw_rejections / (long double)CALIBRATION_ASSIGNMENTS) ||
        emit_line(conclusion, "indices=%s\n", index_text);
}

static int run_label_redraw(const char *input_directory, const char *output_directory)
{
    uint64_t start_ns;
    if (read_clock_ns(&start_ns) != 0 || mkdir(output_directory, 0700) != 0) {
        return 1;
    }
    char records_path[4096];
    char selected_path[4096];
    char conclusion_path[4096];
    if (paired_data_path(records_path, sizeof(records_path), output_directory, "raw.csv") != 0 ||
        paired_data_path(selected_path, sizeof(selected_path), output_directory, "selected.csv") !=
            0 ||
        paired_data_path(conclusion_path,
            sizeof(conclusion_path),
            output_directory,
            "conclusion.txt") != 0) {
        return 1;
    }
    FILE *records = fopen(records_path, "wx");
    FILE *selected_records = fopen(selected_path, "wx");
    FILE *conclusion = fopen(conclusion_path, "wx");
    int operation_status = 1;
    if (records == NULL || selected_records == NULL || conclusion == NULL) {
        goto cleanup;
    }
    if (fputs("model,effect_ns,model_assignment_count,assignment_index", records) == EOF) {
        goto cleanup;
    }
    for (size_t pair_index = 0; pair_index < CALIBRATION_PAIRS; ++pair_index) {
        if (fprintf(records, ",difference_%zu_ns", pair_index) < 0) {
            goto cleanup;
        }
    }
    if (fputs(",tail_count,oracle_tail_count,permutation_count,all_zero,raw_reject\n", records) ==
            EOF ||
        fputs("source_run,draw_order,sample_index,elapsed_nanoseconds,time_unit\n",
            selected_records) == EOF ||
        emit_line(conclusion, "rule_id=v4_label_redraw_20261013\n") ||
        emit_line(conclusion, "label_seed=%" PRIu64 "\n", V4_LABEL_SEED) ||
        emit_line(conclusion, "generator=splitmix64\n") ||
        emit_line(conclusion, "population=%u\n", V4_LABEL_POPULATION) ||
        emit_line(conclusion, "draw_count=%u\n", V4_LABEL_DRAW_COUNT) ||
        emit_line(conclusion, "pair_count=%u\n", CALIBRATION_PAIRS) ||
        emit_line(conclusion, "pairing=draw_order\n") ||
        emit_line(conclusion, "pair_definition=even_draw_minus_next_draw\n") ||
        emit_line(conclusion, "assignment_count=%" PRIu64 "\n", CALIBRATION_ASSIGNMENTS) ||
        emit_line(conclusion, "tail=upper_including_ties\n") ||
        emit_line(conclusion, "denominator=4096\n") || emit_line(conclusion, "alpha=0.01\n") ||
        emit_line(conclusion, "statistic=c04_abs_sum\n") ||
        emit_line(conclusion, "old_rule=original_order_0..23\n") ||
        emit_line(conclusion, "old_table=docs/evidence/reference-label-control-20261007\n") ||
        emit_line(conclusion, "mlkem_decapsulation_calls=0\n")) {
        goto cleanup;
    }
    for (unsigned block_number = 1u; block_number <= 6u; ++block_number) {
        if (run_redraw_block(records,
                conclusion,
                selected_records,
                input_directory,
                block_number,
                start_ns) != 0) {
            goto cleanup;
        }
    }
    char raw_digest[65];
    int records_close_status = fclose(records);
    records = NULL;
    int selected_close_status = fclose(selected_records);
    selected_records = NULL;
    if (records_close_status != 0 || selected_close_status != 0 ||
        paired_digest_file(records_path, raw_digest) != 0 ||
        emit_line(conclusion, "candidate_oracle_mismatches=0\n") ||
        emit_line(conclusion, "raw_digest=%s\n", raw_digest) ||
        emit_line(conclusion, "status=complete\n")) {
        goto cleanup;
    }
    if (fclose(conclusion) != 0) {
        conclusion = NULL;
        goto cleanup;
    }
    conclusion = NULL;
    operation_status = 0;
cleanup:
    if (selected_records != NULL && fclose(selected_records) != 0) {
        operation_status = 1;
    }
    if (records != NULL && fclose(records) != 0) {
        operation_status = 1;
    }
    if (conclusion != NULL && fclose(conclusion) != 0) {
        operation_status = 1;
    }
    return operation_status;
}

int main(int argument_count, char **argument_values)
{
    if (argument_count == 2 && strcmp(argument_values[1], "--self-test") == 0) {
        return self_test();
    }
    if (argument_count == 4 && strcmp(argument_values[1], "--reference-labels-redraw") == 0) {
        return run_label_redraw(argument_values[2], argument_values[3]) == 0 ? 0 : 1;
    }
    int is_reference_control =
        argument_count == 4 && strcmp(argument_values[1], "--reference-labels") == 0;
    if (argument_count != 2 && !is_reference_control) {
        fputs("Usage: calibrate_controlled NEW_DIRECTORY\n"
              "       calibrate_controlled --reference-labels ORDINARY_DIRECTORY NEW_DIRECTORY\n"
              "       calibrate_controlled --reference-labels-redraw ORDINARY_DIRECTORY "
              "NEW_DIRECTORY\n",
            stderr);
        return 2;
    }
    const char *output_directory = is_reference_control ? argument_values[3] : argument_values[1];
    uint64_t start_ns;
    if (read_clock_ns(&start_ns) != 0 || mkdir(output_directory, 0700) != 0) {
        return 1;
    }
    char records_path[4096];
    char summary_path[4096];
    if (paired_data_path(records_path, sizeof(records_path), output_directory, "raw.csv") != 0 ||
        paired_data_path(summary_path, sizeof(summary_path), output_directory, "summary.partial") !=
            0) {
        return 1;
    }
    FILE *records = fopen(records_path, "wx");
    FILE *summary = fopen(summary_path, "wx");
    FILE *selected_records = NULL;
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
    if (fprintf(summary,
            "format=%s\nsource_kind=%s\n"
            "pair_count=12\nalpha=0.01\ninterval_status=unavailable\nmlkem_decapsulation_calls=0\n"
            "task_budget_ns=120000000000\n",
            is_reference_control ? "reference_label_control_v1"
                                 : "finite_controlled_calibration_v1",
            is_reference_control ? "archived_reference_posthoc_labels" : "no_secret_finite_model") <
            0 ||
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
    if (is_reference_control) {
        if (fputs("label_law=independent_equiprobable_posthoc_swaps\n"
                  "pairing=original_adjacent_records_0..23\nmeasurement_iid=not_assessed\n"
                  "added_effect_ns=0\nsource_input_files_unchanged=checked_per_block\n",
                summary) == EOF) {
            goto cleanup;
        }
        char selected_path[4096];
        if (paired_data_path(selected_path,
                sizeof(selected_path),
                output_directory,
                "selected.csv") != 0) {
            goto cleanup;
        }
        selected_records = fopen(selected_path, "wx");
        if (selected_records == NULL ||
            fputs("source_run,sample_index,elapsed_nanoseconds,time_unit\n", selected_records) ==
                EOF) {
            goto cleanup;
        }
        for (size_t block_index = 1; block_index <= 6u; ++block_index) {
            if (run_reference_block(records,
                    summary,
                    selected_records,
                    argument_values[2],
                    block_index,
                    start_ns) != 0) {
                goto cleanup;
            }
        }
        int selected_close_status = fclose(selected_records);
        selected_records = NULL;
        if (selected_close_status != 0) {
            goto cleanup;
        }
    } else {
        const int64_t effects_ns[5] = {0, 1, 2, 4, 12};
        for (size_t profile_index = 0; profile_index < 2u; ++profile_index) {
            for (size_t effect_index = 0; effect_index < 5u; ++effect_index) {
                if (run_model(records,
                        summary,
                        output_directory,
                        profile_index,
                        effects_ns[effect_index],
                        0,
                        start_ns) != 0) {
                    goto cleanup;
                }
            }
            if (run_model(records, summary, output_directory, profile_index, 0, 1, start_ns) != 0) {
                goto cleanup;
            }
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
            "datasets=%u\noracle_mismatches=0\nraw_digest=%s\ntask_wall_ns=%" PRIu64
            "\nfinal_digest_and_status_write=outside_task_wall\n"
            "result_scope=%s\nsecret_attribution=not_assessed\n"
            "report_status=complete\n",
            is_reference_control ? 24576u : 40964u,
            raw_digest,
            finish_ns - start_ns,
            is_reference_control ? "conditional_posthoc_label_model_only" : "finite_model_only") <
            0) {
        goto cleanup;
    }
    int summary_close_status = fclose(summary);
    summary = NULL;
    char final_path[4096];
    if (summary_close_status != 0 ||
        paired_data_path(final_path, sizeof(final_path), output_directory, "summary.report") != 0 ||
        link(summary_path, final_path) != 0) {
        goto cleanup;
    }
    (void)unlink(summary_path);
    operation_status = 0;
cleanup:
    if (selected_records != NULL && fclose(selected_records) != 0) {
        operation_status = 1;
    }
    if (records != NULL && fclose(records) != 0) {
        operation_status = 1;
    }
    if (summary != NULL && fclose(summary) != 0) {
        operation_status = 1;
    }
    return operation_status;
}
