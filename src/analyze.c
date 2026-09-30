#include "inputs.h"
#include "src/fips202/fips202.h"

#include <inttypes.h>
#include <math.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

/* 预先规定的固定检验族：比较对、统计量和显著性水平都写在源码里，不按数据调整。 */
#define ANALYSIS_FAMILY_ALPHA 0.001
#define ANALYSIS_MAXIMUM_RECORDS 200000u
#define ANALYSIS_MAXIMUM_CSV_BYTES 67108864
#define ANALYSIS_LINE_CAPACITY 256u
#define ANALYSIS_RUN_ID_CAPACITY 65u
#define ANALYSIS_IMPLEMENTATION_CAPACITY 33u
#define ANALYSIS_INITIAL_RECORD_CAPACITY 1024u
#define ANALYSIS_CSV_HEADER                                                                        \
    "run_id,implementation,input_category,sample_index,elapsed_nanoseconds,time_unit\n"

struct measurement_record {
    uint64_t elapsed_nanoseconds;
    unsigned category_index;
};

struct measurement_set {
    struct measurement_record *records;
    size_t record_count;
    size_t capacity_records;
    char run_id[ANALYSIS_RUN_ID_CAPACITY];
    char implementation[ANALYSIS_IMPLEMENTATION_CAPACITY];
};

/* 按类别排序后，每个类别的样本在记录数组中连续，序列只保存区间视图。 */
struct sample_series {
    const struct measurement_record *records;
    size_t sample_count;
};

struct ranked_sample {
    uint64_t elapsed_nanoseconds;
    unsigned group_index;
};

struct comparison_pair {
    enum input_category first_category;
    enum input_category second_category;
    int is_primary;
};

struct comparison_result {
    double median_difference_nanoseconds;
    double mean_difference_nanoseconds;
    double welch_t_statistic;
    double welch_degrees_of_freedom;
    double welch_p_value;
    double rank_u_statistic;
    double rank_z_score;
    double rank_p_value;
    double effect_size_first_greater;
    int has_location_test;
    int has_rank_test;
};

/* 主比较是解密消息位全 0 与全 1 的分支方向对照；其余比较同族报告并统一校正。 */
static const struct comparison_pair prespecified_comparisons[] = {
    {INPUT_MESSAGE_ZERO, INPUT_MESSAGE_ONES, 1},
    {INPUT_VALID, INPUT_BIT_FLIPPED, 0},
    {INPUT_VALID, INPUT_RANDOM, 0},
    {INPUT_VALID, INPUT_MESSAGE_ZERO, 0},
    {INPUT_VALID, INPUT_MESSAGE_ONES, 0},
    {INPUT_BIT_FLIPPED, INPUT_RANDOM, 0},
    {INPUT_BIT_FLIPPED, INPUT_MESSAGE_ZERO, 0},
    {INPUT_BIT_FLIPPED, INPUT_MESSAGE_ONES, 0},
    {INPUT_RANDOM, INPUT_MESSAGE_ZERO, 0},
    {INPUT_RANDOM, INPUT_MESSAGE_ONES, 0}};

#define ANALYSIS_COMPARISON_COUNT                                                                  \
    (sizeof(prespecified_comparisons) / sizeof(prespecified_comparisons[0]))

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

static uint64_t series_value(const struct sample_series *series, size_t sample_index)
{
    return series->records[sample_index].elapsed_nanoseconds;
}

/* 排序后按最近秩取分位点，不做插值，也不删除长尾。 */
static uint64_t series_quantile(const struct sample_series *series, double fraction)
{
    double position = fraction * (double)(series->sample_count - 1u);
    size_t sample_index = (size_t)(position + 0.5);
    if (sample_index >= series->sample_count) {
        sample_index = series->sample_count - 1u;
    }
    return series_value(series, sample_index);
}

static void series_moments(const struct sample_series *series,
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

static size_t series_distinct_values(const struct sample_series *series)
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

static int compare_series(const struct sample_series *first_series,
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

static int load_measurement_set(const char *csv_path, struct measurement_set *set)
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

static void build_series(const struct measurement_set *set,
    struct sample_series series[INPUT_CATEGORY_COUNT])
{
    size_t record_index = 0;
    for (unsigned category_index = 0; category_index < INPUT_CATEGORY_COUNT; ++category_index) {
        size_t span_start = record_index;
        while (record_index < set->record_count &&
            set->records[record_index].category_index == category_index) {
            ++record_index;
        }
        series[category_index].records = &set->records[span_start];
        series[category_index].sample_count = record_index - span_start;
    }
}

static int hash_csv_file(const char *csv_path, uint8_t csv_digest[32])
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

static const char *comparison_result_label(const struct comparison_result *result,
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

static int write_report_header(FILE *report_file,
    const char *csv_path,
    const struct measurement_set *set,
    const uint8_t csv_digest[32],
    double alpha_per_comparison)
{
    int operation_status = 0;
    if (fprintf(report_file,
            "analysis_tool=fixed_prespecified_tests\nanalysis_version=1\ncsv_path=%s\n"
            "csv_digest_algorithm=SHA3-256\ncsv_digest=",
            csv_path) < 0) {
        operation_status = 1;
    }
    for (size_t byte_index = 0; byte_index < 32u; ++byte_index) {
        if (fprintf(report_file, "%02x", csv_digest[byte_index]) < 0) {
            operation_status = 1;
        }
    }
    if (fprintf(report_file,
            "\nrun_id=%s\nimplementation=%s\nrecord_count=%zu\ntime_unit=ns\n"
            "location_test=welch_t_normal_approximation\n"
            "rank_test=mann_whitney_u_tie_corrected_normal_approximation\n"
            "quantile_rule=nearest_rank_no_interpolation\noutlier_removal=none\n"
            "alpha_family=%.6f\ncomparison_count=%zu\nmultiplicity_correction=bonferroni\n"
            "alpha_per_comparison=%.8f\n",
            set->run_id,
            set->implementation,
            set->record_count,
            ANALYSIS_FAMILY_ALPHA,
            (size_t)ANALYSIS_COMPARISON_COUNT,
            alpha_per_comparison) < 0) {
        operation_status = 1;
    }
    return operation_status;
}

static int write_category_lines(FILE *report_file,
    const struct sample_series series[INPUT_CATEGORY_COUNT])
{
    int operation_status = 0;
    for (unsigned category_index = 0; category_index < INPUT_CATEGORY_COUNT; ++category_index) {
        const struct sample_series *category_series = &series[category_index];
        const char *category_name = input_category_name((enum input_category)category_index);
        double mean_nanoseconds;
        double variance_nanoseconds_squared;
        if (category_series->sample_count == 0) {
            if (fprintf(report_file, "category=%s count=0\n", category_name) < 0) {
                operation_status = 1;
            }
            continue;
        }
        series_moments(category_series, &mean_nanoseconds, &variance_nanoseconds_squared);
        if (fprintf(report_file,
                "category=%s count=%zu min=%" PRIu64 " p25=%" PRIu64 " median=%" PRIu64
                " p75=%" PRIu64 " p99=%" PRIu64 " max=%" PRIu64
                " mean=%.3f stddev=%.3f distinct_values=%zu\n",
                category_name,
                category_series->sample_count,
                series_value(category_series, 0),
                series_quantile(category_series, 0.25),
                series_quantile(category_series, 0.5),
                series_quantile(category_series, 0.75),
                series_quantile(category_series, 0.99),
                series_value(category_series, category_series->sample_count - 1u),
                mean_nanoseconds,
                sqrt(variance_nanoseconds_squared),
                series_distinct_values(category_series)) < 0) {
            operation_status = 1;
        }
    }
    return operation_status;
}

static int write_comparison_line(FILE *report_file,
    const struct comparison_pair *pair,
    const struct sample_series series[INPUT_CATEGORY_COUNT],
    const struct comparison_result *result,
    const char *result_label)
{
    if (fprintf(report_file,
            "comparison=%s:%s primary=%s n1=%zu n2=%zu",
            input_category_name(pair->first_category),
            input_category_name(pair->second_category),
            pair->is_primary ? "yes" : "no",
            series[pair->first_category].sample_count,
            series[pair->second_category].sample_count) < 0) {
        return 1;
    }
    if (strcmp(result_label, "insufficient_samples") != 0) {
        if (fprintf(report_file,
                " median_difference_ns=%.1f mean_difference_ns=%.3f",
                result->median_difference_nanoseconds,
                result->mean_difference_nanoseconds) < 0) {
            return 1;
        }
        if (result->has_location_test &&
            fprintf(report_file,
                " welch_t=%.4f welch_df=%.1f welch_p=%.6g",
                result->welch_t_statistic,
                result->welch_degrees_of_freedom,
                result->welch_p_value) < 0) {
            return 1;
        }
        if (result->has_rank_test &&
            fprintf(report_file,
                " rank_u1=%.1f rank_z=%.4f rank_p=%.6g effect_size_first_greater=%.6f",
                result->rank_u_statistic,
                result->rank_z_score,
                result->rank_p_value,
                result->effect_size_first_greater) < 0) {
            return 1;
        }
    }
    return fprintf(report_file, " result=%s\n", result_label) < 0 ? 1 : 0;
}

static int write_comparisons(FILE *report_file,
    const struct sample_series series[INPUT_CATEGORY_COUNT],
    double alpha_per_comparison,
    size_t *significant_comparison_count,
    const char **primary_label,
    double *primary_rank_p_value)
{
    int operation_status = 0;
    for (size_t comparison_index = 0; comparison_index < ANALYSIS_COMPARISON_COUNT;
        ++comparison_index) {
        const struct comparison_pair *pair = &prespecified_comparisons[comparison_index];
        struct comparison_result result;
        const char *result_label;
        int comparison_status =
            compare_series(&series[pair->first_category], &series[pair->second_category], &result);
        if (comparison_status == 2) {
            return 1;
        }
        result_label = comparison_result_label(&result, comparison_status, alpha_per_comparison);
        if (strcmp(result_label, "significant") == 0) {
            ++*significant_comparison_count;
        }
        if (write_comparison_line(report_file, pair, series, &result, result_label) != 0) {
            operation_status = 1;
        }
        if (pair->is_primary) {
            *primary_label = result_label;
            *primary_rank_p_value = result.has_rank_test ? result.rank_p_value : 1.0;
        }
    }
    return operation_status;
}

int main(int argument_count, char **argument_values)
{
    struct measurement_set set;
    struct sample_series series[INPUT_CATEGORY_COUNT];
    uint8_t csv_digest[32];
    FILE *report_file = NULL;
    const char *primary_label = "insufficient_samples";
    double primary_rank_p_value = 1.0;
    double alpha_per_comparison = ANALYSIS_FAMILY_ALPHA / (double)ANALYSIS_COMPARISON_COUNT;
    size_t significant_comparison_count = 0;
    int operation_status;
    if (argument_count != 3) {
        fputs("Usage: analyze CSV_FILE REPORT_FILE\n"
              "Reads one raw timing CSV and writes a fixed pre-specified statistical report.\n"
              "A statistical difference is not a key-recovery or exploitability claim.\n",
            stderr);
        return 2;
    }
    memset(&set, 0, sizeof(set));
    memset(series, 0, sizeof(series));
    if (hash_csv_file(argument_values[1], csv_digest) != 0) {
        fputs("cannot read timing CSV for digest\n", stderr);
        return 1;
    }
    if (load_measurement_set(argument_values[1], &set) != 0) {
        free(set.records);
        fputs("invalid timing CSV: check header, fields, sample order and units\n", stderr);
        return 1;
    }
    qsort(set.records, set.record_count, sizeof(*set.records), compare_measurement_record);
    build_series(&set, series);
    report_file = fopen(argument_values[2], "wx");
    if (report_file == NULL) {
        free(set.records);
        fputs("cannot create report file (destination must be new)\n", stderr);
        return 1;
    }
    operation_status = write_report_header(report_file,
        argument_values[1],
        &set,
        csv_digest,
        alpha_per_comparison);
    if (write_category_lines(report_file, series) != 0) {
        operation_status = 1;
    }
    if (write_comparisons(report_file,
            series,
            alpha_per_comparison,
            &significant_comparison_count,
            &primary_label,
            &primary_rank_p_value) != 0) {
        operation_status = 1;
    }
    if (fprintf(report_file,
            "significant_comparison_count=%zu\n"
            "note=statistical_difference_only_no_exploitability_claim\n",
            significant_comparison_count) < 0) {
        operation_status = 1;
    }
    if (fclose(report_file) != 0) {
        operation_status = 1;
    }
    if (operation_status != 0) {
        free(set.records);
        fputs("analysis failed; use a new report path and a complete CSV\n", stderr);
        return 1;
    }
    printf("%s: analyzed %zu records; %zu of %zu pre-specified comparisons significant; "
           "primary %s:%s rank p=%.3g (%s); statistical result only\n",
        set.implementation,
        set.record_count,
        significant_comparison_count,
        (size_t)ANALYSIS_COMPARISON_COUNT,
        input_category_name(prespecified_comparisons[0].first_category),
        input_category_name(prespecified_comparisons[0].second_category),
        primary_rank_p_value,
        primary_label);
    free(set.records);
    return 0;
}
