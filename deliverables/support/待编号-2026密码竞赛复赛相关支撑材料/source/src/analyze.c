#include "inputs.h"
#include "timing_statistics.h"

#include <inttypes.h>
#include <math.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

/* 预先规定的固定检验族：比较对、统计量和显著性水平都写在源码里，不按数据调整。 */
#define ANALYSIS_FAMILY_ALPHA 0.001

struct comparison_pair {
    enum input_category first_category;
    enum input_category second_category;
    int is_primary;
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
    sort_records_by_category_then_duration(set.records, set.record_count);
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
