#include "timing_statistics.h"

#include "src/fips202/fips202.h"

#include <math.h>
#include <stdlib.h>
#include <string.h>

/* 两个固定检验程序共用的加载、校验、分位点与比较实现；这里不定义任何比较族。 */
#define ANALYSIS_MAXIMUM_RECORDS 200000u
#define ANALYSIS_MAXIMUM_CSV_BYTES 67108864
#define ANALYSIS_LINE_CAPACITY 256u
#define ANALYSIS_INITIAL_RECORD_CAPACITY 1024u
#define ANALYSIS_CSV_HEADER                                                                        \
    "run_id,implementation,input_category,sample_index,elapsed_nanoseconds,time_unit\n"

struct ranked_sample {
    uint64_t elapsed_nanoseconds;
    unsigned group_index;
};

static int compare_measurement_record(const void *left, const void *right)
{
    const struct measurement_record *left_record = left;
    const struct measurement_record *right_record = right;
    if (left_record->category_index != right_record->category_index) {
        return left_record->category_index < right_record->category_index ? -1 : 1;
    }
    if (left_record->elapsed_nanoseconds < right_record->elapsed_nanoseconds) {
        return -1;
    }
    return left_record->elapsed_nanoseconds > right_record->elapsed_nanoseconds ? 1 : 0;
}

static int compare_measurement_duration(const void *left, const void *right)
{
    const struct measurement_record *left_record = left;
    const struct measurement_record *right_record = right;
    if (left_record->elapsed_nanoseconds < right_record->elapsed_nanoseconds) {
        return -1;
    }
    return left_record->elapsed_nanoseconds > right_record->elapsed_nanoseconds ? 1 : 0;
}

void sort_records_by_category_then_duration(struct measurement_record *records, size_t record_count)
{
    qsort(records, record_count, sizeof(*records), compare_measurement_record);
}

void sort_range_by_duration(struct measurement_record *records, size_t record_count)
{
    qsort(records, record_count, sizeof(*records), compare_measurement_duration);
}

static int compare_ranked_sample(const void *left, const void *right)
{
    const struct ranked_sample *left_sample = left;
    const struct ranked_sample *right_sample = right;
    if (left_sample->elapsed_nanoseconds < right_sample->elapsed_nanoseconds) {
        return -1;
    }
    return left_sample->elapsed_nanoseconds > right_sample->elapsed_nanoseconds ? 1 : 0;
}

static int
append_record(struct measurement_set *set, unsigned category_index, uint64_t elapsed_nanoseconds)
{
    if (set->record_count == set->capacity_records) {
        size_t grown_capacity_records = set->capacity_records == 0
            ? ANALYSIS_INITIAL_RECORD_CAPACITY
            : set->capacity_records * 2u;
        struct measurement_record *grown_records =
            realloc(set->records, grown_capacity_records * sizeof(*grown_records));
        if (grown_records == NULL) {
            return 1;
        }
        set->records = grown_records;
        set->capacity_records = grown_capacity_records;
    }
    set->records[set->record_count].elapsed_nanoseconds = elapsed_nanoseconds;
    set->records[set->record_count].category_index = category_index;
    ++set->record_count;
    return 0;
}

uint64_t series_value(const struct sample_series *series, size_t sample_index)
{
    return series->records[sample_index].elapsed_nanoseconds;
}

/* 排序后按最近秩取分位点，不做插值，也不删除长尾。 */
uint64_t series_quantile(const struct sample_series *series, double fraction)
{
    double position = fraction * (double)(series->sample_count - 1u);
    size_t sample_index = (size_t)(position + 0.5);
    if (sample_index >= series->sample_count) {
        sample_index = series->sample_count - 1u;
    }
    return series_value(series, sample_index);
}

void series_moments(const struct sample_series *series,
    double *mean_nanoseconds,
    double *variance_nanoseconds_squared)
{
    double value_total = 0.0;
    double squared_deviation_total = 0.0;
    for (size_t sample_index = 0; sample_index < series->sample_count; ++sample_index) {
        value_total += (double)series_value(series, sample_index);
    }
    *mean_nanoseconds = value_total / (double)series->sample_count;
    for (size_t sample_index = 0; sample_index < series->sample_count; ++sample_index) {
        double deviation = (double)series_value(series, sample_index) - *mean_nanoseconds;
        squared_deviation_total += deviation * deviation;
    }
    *variance_nanoseconds_squared = series->sample_count > 1u
        ? squared_deviation_total / (double)(series->sample_count - 1u)
        : 0.0;
}

size_t series_distinct_values(const struct sample_series *series)
{
    size_t distinct_count = series->sample_count == 0 ? 0u : 1u;
    for (size_t sample_index = 1; sample_index < series->sample_count; ++sample_index) {
        if (series_value(series, sample_index) != series_value(series, sample_index - 1u)) {
            ++distinct_count;
        }
    }
    return distinct_count;
}

/* 大样本正态近似的双侧 p 值；|z| 超过约 38 时结果会下溢为 0，应同时看 z。 */
static double two_sided_normal_p_value(double standard_score)
{
    return erfc(fabs(standard_score) / sqrt(2.0));
}

static int welch_location_test(const struct sample_series *first_series,
    const struct sample_series *second_series,
    struct comparison_result *result)
{
    double first_mean_nanoseconds;
    double first_variance;
    double second_mean_nanoseconds;
    double second_variance;
    double first_squared_error;
    double second_squared_error;
    double standard_error;
    double degrees_of_freedom_denominator;
    series_moments(first_series, &first_mean_nanoseconds, &first_variance);
    series_moments(second_series, &second_mean_nanoseconds, &second_variance);
    result->mean_difference_nanoseconds = first_mean_nanoseconds - second_mean_nanoseconds;
    first_squared_error = first_variance / (double)first_series->sample_count;
    second_squared_error = second_variance / (double)second_series->sample_count;
    standard_error = sqrt(first_squared_error + second_squared_error);
    if (!(standard_error > 0.0)) {
        return 1;
    }
    result->welch_t_statistic = result->mean_difference_nanoseconds / standard_error;
    degrees_of_freedom_denominator =
        first_squared_error * first_squared_error / (double)(first_series->sample_count - 1u) +
        second_squared_error * second_squared_error / (double)(second_series->sample_count - 1u);
    result->welch_degrees_of_freedom = degrees_of_freedom_denominator > 0.0
        ? (first_squared_error + second_squared_error) *
            (first_squared_error + second_squared_error) / degrees_of_freedom_denominator
        : 0.0;
    result->welch_p_value = two_sided_normal_p_value(result->welch_t_statistic);
    return 0;
}

/* Mann-Whitney U：并合排序取平均秩，按并列修正方差，连续性校正后用正态近似。 */
static int rank_sum_test(const struct sample_series *first_series,
    const struct sample_series *second_series,
    struct comparison_result *result)
{
    size_t combined_count = first_series->sample_count + second_series->sample_count;
    struct ranked_sample *combined_samples = calloc(combined_count, sizeof(*combined_samples));
    double first_rank_total = 0.0;
    double tie_correction = 0.0;
    double pair_count = (double)first_series->sample_count * (double)second_series->sample_count;
    double expected_u_statistic = pair_count / 2.0;
    double u_variance;
    double absolute_deviation;
    if (combined_samples == NULL) {
        return 2;
    }
    for (size_t sample_index = 0; sample_index < first_series->sample_count; ++sample_index) {
        combined_samples[sample_index].elapsed_nanoseconds =
            series_value(first_series, sample_index);
        combined_samples[sample_index].group_index = 0u;
    }
    for (size_t sample_index = 0; sample_index < second_series->sample_count; ++sample_index) {
        size_t combined_index = first_series->sample_count + sample_index;
        combined_samples[combined_index].elapsed_nanoseconds =
            series_value(second_series, sample_index);
        combined_samples[combined_index].group_index = 1u;
    }
    qsort(combined_samples, combined_count, sizeof(*combined_samples), compare_ranked_sample);
    for (size_t run_start = 0; run_start < combined_count;) {
        size_t run_end = run_start + 1u;
        double tie_length;
        double average_rank;
        while (run_end < combined_count &&
            combined_samples[run_end].elapsed_nanoseconds ==
                combined_samples[run_start].elapsed_nanoseconds) {
            ++run_end;
        }
        tie_length = (double)(run_end - run_start);
        average_rank = (double)run_start + 1.0 + (tie_length - 1.0) / 2.0;
        for (size_t sample_index = run_start; sample_index < run_end; ++sample_index) {
            if (combined_samples[sample_index].group_index == 0u) {
                first_rank_total += average_rank;
            }
        }
        tie_correction += tie_length * tie_length * tie_length - tie_length;
        run_start = run_end;
    }
    free(combined_samples);
    result->rank_u_statistic = first_rank_total -
        (double)first_series->sample_count * ((double)first_series->sample_count + 1.0) / 2.0;
    result->effect_size_first_greater = result->rank_u_statistic / pair_count;
    u_variance = pair_count / 12.0 *
        ((double)combined_count + 1.0 -
            tie_correction / ((double)combined_count * ((double)combined_count - 1.0)));
    if (!(u_variance > 0.0)) {
        return 1;
    }
    absolute_deviation = fabs(result->rank_u_statistic - expected_u_statistic) - 0.5;
    if (absolute_deviation < 0.0) {
        absolute_deviation = 0.0;
    }
    result->rank_z_score = result->rank_u_statistic >= expected_u_statistic
        ? absolute_deviation / sqrt(u_variance)
        : -absolute_deviation / sqrt(u_variance);
    result->rank_p_value = two_sided_normal_p_value(result->rank_z_score);
    return 0;
}

int compare_series(const struct sample_series *first_series,
    const struct sample_series *second_series,
    struct comparison_result *result)
{
    int rank_status;
    memset(result, 0, sizeof(*result));
    if (first_series->sample_count < 2u || second_series->sample_count < 2u) {
        return 1;
    }
    result->median_difference_nanoseconds =
        (double)series_quantile(first_series, 0.5) - (double)series_quantile(second_series, 0.5);
    result->has_location_test = welch_location_test(first_series, second_series, result) == 0;
    rank_status = rank_sum_test(first_series, second_series, result);
    if (rank_status == 2) {
        return 2;
    }
    result->has_rank_test = rank_status == 0;
    return 0;
}

static int is_valid_run_id(const char *run_id)
{
    if (*run_id == '\0') {
        return 0;
    }
    for (const char *character = run_id; *character != '\0'; ++character) {
        if (!((*character >= 'a' && *character <= 'z') ||
                (*character >= 'A' && *character <= 'Z') ||
                (*character >= '0' && *character <= '9') || *character == '_' ||
                *character == '-')) {
            return 0;
        }
    }
    return 1;
}

static int is_valid_implementation_name(const char *implementation)
{
    if (*implementation == '\0') {
        return 0;
    }
    for (const char *character = implementation; *character != '\0'; ++character) {
        if (!((*character >= 'a' && *character <= 'z') || *character == '-')) {
            return 0;
        }
    }
    return 1;
}

static int split_record_fields(char *record_line, char *fields[6])
{
    size_t line_byte_count = strlen(record_line);
    if (line_byte_count == 0 || record_line[line_byte_count - 1u] != '\n') {
        return 1;
    }
    record_line[line_byte_count - 1u] = '\0';
    fields[0] = record_line;
    for (size_t field_index = 0; field_index < 5u; ++field_index) {
        char *field_separator = strchr(fields[field_index], ',');
        if (field_separator == NULL || field_separator == fields[field_index]) {
            return 1;
        }
        *field_separator = '\0';
        fields[field_index + 1u] = field_separator + 1;
    }
    return 0;
}

int load_measurement_set(const char *csv_path, struct measurement_set *set)
{
    FILE *csv_file = fopen(csv_path, "r");
    char record_line[ANALYSIS_LINE_CAPACITY];
    /* 标识字段先收在局部缓冲区，整份文件校验通过后才写入结果结构。 */
    char run_id[ANALYSIS_RUN_ID_CAPACITY] = "";
    char implementation[ANALYSIS_IMPLEMENTATION_CAPACITY] = "";
    int operation_status = 1;
    if (csv_file == NULL) {
        return 1;
    }
    if (fgets(record_line, sizeof(record_line), csv_file) == NULL ||
        strcmp(record_line, ANALYSIS_CSV_HEADER) != 0) {
        goto cleanup;
    }
    while (fgets(record_line, sizeof(record_line), csv_file) != NULL) {
        char *fields[6];
        enum input_category category;
        uint64_t sample_index;
        uint64_t elapsed_nanoseconds;
        if (split_record_fields(record_line, fields) != 0) {
            goto cleanup;
        }
        if (strlen(fields[0]) >= sizeof(run_id) || !is_valid_run_id(fields[0]) ||
            strlen(fields[1]) >= sizeof(implementation) ||
            !is_valid_implementation_name(fields[1]) ||
            parse_input_category(fields[2], &category) != 0 ||
            parse_unsigned_integer(fields[3], &sample_index) != 0 ||
            parse_unsigned_integer(fields[4], &elapsed_nanoseconds) != 0 ||
            elapsed_nanoseconds == 0 || strcmp(fields[5], "ns") != 0) {
            goto cleanup;
        }
        if (set->record_count == 0) {
            memcpy(run_id, fields[0], strlen(fields[0]) + 1u);
            memcpy(implementation, fields[1], strlen(fields[1]) + 1u);
        } else if (strcmp(fields[0], run_id) != 0 || strcmp(fields[1], implementation) != 0) {
            goto cleanup;
        }
        if (sample_index != (uint64_t)set->record_count ||
            set->record_count >= ANALYSIS_MAXIMUM_RECORDS) {
            goto cleanup;
        }
        if (append_record(set, (unsigned)category, elapsed_nanoseconds) != 0) {
            goto cleanup;
        }
    }
    if (ferror(csv_file) || set->record_count < 2u) {
        goto cleanup;
    }
    memcpy(set->run_id, run_id, sizeof(set->run_id));
    memcpy(set->implementation, implementation, sizeof(set->implementation));
    operation_status = 0;
cleanup:
    if (fclose(csv_file) != 0) {
        operation_status = 1;
    }
    return operation_status;
}

int hash_csv_file(const char *csv_path, uint8_t csv_digest[32])
{
    FILE *csv_file = fopen(csv_path, "rb");
    uint8_t *csv_bytes = NULL;
    size_t csv_byte_count;
    long file_byte_count;
    int operation_status = 1;
    if (csv_file == NULL) {
        return 1;
    }
    if (fseek(csv_file, 0, SEEK_END) != 0) {
        goto cleanup;
    }
    file_byte_count = ftell(csv_file);
    if (file_byte_count <= 0 || file_byte_count > ANALYSIS_MAXIMUM_CSV_BYTES ||
        fseek(csv_file, 0, SEEK_SET) != 0) {
        goto cleanup;
    }
    csv_byte_count = (size_t)file_byte_count;
    csv_bytes = malloc(csv_byte_count);
    if (csv_bytes == NULL) {
        goto cleanup;
    }
    if (fread(csv_bytes, 1, csv_byte_count, csv_file) != csv_byte_count || ferror(csv_file)) {
        goto cleanup;
    }
    mlk_sha3_256(csv_digest, csv_bytes, csv_byte_count);
    operation_status = 0;
cleanup:
    free(csv_bytes);
    if (fclose(csv_file) != 0) {
        operation_status = 1;
    }
    return operation_status;
}

const char *comparison_result_label(const struct comparison_result *result,
    int comparison_status,
    double alpha_per_comparison)
{
    if (comparison_status != 0) {
        return "insufficient_samples";
    }
    if (!result->has_rank_test) {
        return "degenerate_no_variation";
    }
    return result->rank_p_value < alpha_per_comparison ? "significant" : "not_significant";
}
