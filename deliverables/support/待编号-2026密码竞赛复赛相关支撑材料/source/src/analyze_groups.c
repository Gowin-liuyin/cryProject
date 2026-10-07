#include "inputs.h"
#include "timing_statistics.h"

#include <inttypes.h>
#include <math.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

/*
 * 第二轮预注册的单比较族：方向恒定类（message-zero、message-ones）对
 * 方向变化类（valid、bit-flipped、random）。假设、统计形式与阈值在采集之前
 * 已由设计文件固定；这是在看过第一轮数据之后提出的第二轮预注册。
 * 第一轮的十个比较由 analyze 独立保留，本程序一个字也不改动它。
 */
#define GROUP_FAMILY_ALPHA 0.001
#define GROUP_COMPARISON_COUNT 1u
/* 第一轮主比较的单比较阈值，只作常量并列披露，不参与本轮判定。 */
#define GROUP_ROUND1_ALPHA_PER_COMPARISON 0.0001

/* 分组按类别索引切连续区间，因此类别枚举的取值顺序是本程序的硬依赖。 */
_Static_assert(INPUT_VALID == 0, "direction-varying group starts at category index 0");
_Static_assert(INPUT_BIT_FLIPPED == 1, "direction-varying group must stay contiguous");
_Static_assert(INPUT_RANDOM == 2, "direction-varying group must end at category index 2");
_Static_assert(INPUT_MESSAGE_ZERO == 3, "direction-constant group starts at category index 3");
_Static_assert(INPUT_MESSAGE_ONES == 4, "direction-constant group must end at category index 4");
_Static_assert(INPUT_CATEGORY_COUNT == 5u, "the two groups must cover exactly five categories");

#define GROUP_VARYING_CATEGORY_COUNT 3u
#define GROUP_CONSTANT_CATEGORY_COUNT 2u

struct group_span {
    const char *group_name;
    const char *member_names;
    struct sample_series series;
};

/*
 * 第 3 步：五类必须全部出现、每类样本数相等、每组样本数不少于 2。
 * 必须在整份数组已按类别排序之后调用，否则类别计数本身就不可信。
 */
static int count_sorted_categories(const struct measurement_set *set,
    size_t category_sample_counts[INPUT_CATEGORY_COUNT])
{
    size_t record_index = 0;
    for (unsigned category_index = 0; category_index < INPUT_CATEGORY_COUNT; ++category_index) {
        size_t span_start = record_index;
        while (record_index < set->record_count &&
            set->records[record_index].category_index == category_index) {
            ++record_index;
        }
        category_sample_counts[category_index] = record_index - span_start;
    }
    if (record_index != set->record_count) {
        return 1;
    }
    for (unsigned category_index = 0; category_index < INPUT_CATEGORY_COUNT; ++category_index) {
        if (category_sample_counts[category_index] == 0 ||
            category_sample_counts[category_index] != category_sample_counts[0]) {
            return 1;
        }
    }
    return 0;
}

static int write_report_header(FILE *report_file,
    const char *csv_path,
    const struct measurement_set *set,
    const uint8_t csv_digest[32])
{
    int operation_status = 0;
    if (fprintf(report_file,
            "analysis_tool=fixed_prespecified_group_test\nanalysis_version=1\nanalysis_round=2\n"
            "prespecified_after_round1_data=yes\n"
            "hypothesis=direction_constant_vs_direction_varying\ncsv_path=%s\n"
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
            "\nrun_id=%s\nimplementation=%s\nrecord_count=%zu\ntime_unit=ns\n",
            set->run_id,
            set->implementation,
            set->record_count) < 0) {
        operation_status = 1;
    }
    return operation_status;
}

static int write_group_line(FILE *report_file, const struct group_span *group)
{
    const struct sample_series *group_series = &group->series;
    double mean_nanoseconds;
    double variance_nanoseconds_squared;
    series_moments(group_series, &mean_nanoseconds, &variance_nanoseconds_squared);
    return fprintf(report_file,
               "group=%s members=%s count=%zu min=%" PRIu64 " p25=%" PRIu64 " median=%" PRIu64
               " p75=%" PRIu64 " p99=%" PRIu64 " max=%" PRIu64
               " mean=%.3f stddev=%.3f distinct_values=%zu\n",
               group->group_name,
               group->member_names,
               group_series->sample_count,
               series_value(group_series, 0),
               series_quantile(group_series, 0.25),
               series_quantile(group_series, 0.5),
               series_quantile(group_series, 0.75),
               series_quantile(group_series, 0.99),
               series_value(group_series, group_series->sample_count - 1u),
               mean_nanoseconds,
               sqrt(variance_nanoseconds_squared),
               series_distinct_values(group_series)) < 0
        ? 1
        : 0;
}

static int write_method_lines(FILE *report_file, double alpha_per_comparison)
{
    return fprintf(report_file,
               "location_test=welch_t_normal_approximation\n"
               "rank_test=mann_whitney_u_tie_corrected_normal_approximation\n"
               "quantile_rule=nearest_rank_no_interpolation\noutlier_removal=none\n"
               "alpha_family=%.6f\ncomparison_count=%zu\n"
               "multiplicity_correction=none_single_prespecified_comparison\n"
               "alpha_per_comparison=%.8f\nround1_alpha_per_comparison_for_reference=%.8f\n",
               GROUP_FAMILY_ALPHA,
               (size_t)GROUP_COMPARISON_COUNT,
               alpha_per_comparison,
               GROUP_ROUND1_ALPHA_PER_COMPARISON) < 0
        ? 1
        : 0;
}

/* 字段存在性规则与第一轮 write_comparison_line 相同，便于两份报告并列核对。 */
static int write_comparison_line(FILE *report_file,
    const struct group_span *first_group,
    const struct group_span *second_group,
    const struct comparison_result *result,
    const char *result_label)
{
    if (fprintf(report_file,
            "comparison=%s:%s primary=yes n1=%zu n2=%zu",
            first_group->group_name,
            second_group->group_name,
            first_group->series.sample_count,
            second_group->series.sample_count) < 0) {
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

int main(int argument_count, char **argument_values)
{
    struct measurement_set set;
    size_t category_sample_counts[INPUT_CATEGORY_COUNT];
    struct group_span varying_group;
    struct group_span constant_group;
    struct comparison_result result;
    const char *result_label;
    uint8_t csv_digest[32];
    FILE *report_file = NULL;
    size_t samples_per_category;
    size_t constant_span_start;
    double alpha_per_comparison = GROUP_FAMILY_ALPHA / (double)GROUP_COMPARISON_COUNT;
    int comparison_status;
    int operation_status;
    if (argument_count != 3) {
        fputs("Usage: analyze_groups CSV_FILE REPORT_FILE\n"
              "Reads one raw timing CSV and writes the round-two pre-specified group report.\n"
              "A statistical difference is not a key-recovery or exploitability claim.\n",
            stderr);
        return 2;
    }
    memset(&set, 0, sizeof(set));
    if (hash_csv_file(argument_values[1], csv_digest) != 0) {
        fputs("cannot read timing CSV for digest\n", stderr);
        return 1;
    }
    /* 第 1 步：加载并校验。加载函数本身不排序。 */
    if (load_measurement_set(argument_values[1], &set) != 0) {
        free(set.records);
        fputs("invalid timing CSV: check header, fields, sample order and units\n", stderr);
        return 1;
    }
    /* 第 2 步：整份记录按类别再按耗时排序，这是第 3 步能按下标切组的唯一前提。 */
    sort_records_by_category_then_duration(set.records, set.record_count);
    /* 第 3 步：类别齐全且每类等量。 */
    if (count_sorted_categories(&set, category_sample_counts) != 0) {
        free(set.records);
        fputs("invalid timing CSV: all five categories must appear with equal sample counts\n",
            stderr);
        return 1;
    }
    /* 第 4 步：记录两组的样本数与各自区间的起止下标。 */
    samples_per_category = category_sample_counts[0];
    constant_span_start = samples_per_category * GROUP_VARYING_CATEGORY_COUNT;
    varying_group.group_name = "direction-varying";
    varying_group.member_names = "valid,bit-flipped,random";
    varying_group.series.records = &set.records[0];
    varying_group.series.sample_count = constant_span_start;
    constant_group.group_name = "direction-constant";
    constant_group.member_names = "message-zero,message-ones";
    constant_group.series.records = &set.records[constant_span_start];
    constant_group.series.sample_count = samples_per_category * GROUP_CONSTANT_CATEGORY_COUNT;
    if (varying_group.series.sample_count < 2u || constant_group.series.sample_count < 2u) {
        free(set.records);
        fputs("invalid timing CSV: each group needs at least two samples\n", stderr);
        return 1;
    }
    /*
     * 第 5 步：才对两个组区间各按耗时重排一次。这是对共享数组的原地改写，
     * 之后组内不再有类别分段，因此本程序此后不按类别取任何视图。
     */
    sort_range_by_duration(&set.records[0], varying_group.series.sample_count);
    sort_range_by_duration(&set.records[constant_span_start], constant_group.series.sample_count);
    /* 第 6 步：计算分位点/矩与比较，写报告。 */
    comparison_status = compare_series(&constant_group.series, &varying_group.series, &result);
    if (comparison_status == 2) {
        free(set.records);
        fputs("cannot allocate the rank test working set\n", stderr);
        return 1;
    }
    result_label = comparison_result_label(&result, comparison_status, alpha_per_comparison);
    report_file = fopen(argument_values[2], "wx");
    if (report_file == NULL) {
        free(set.records);
        fputs("cannot create report file (destination must be new)\n", stderr);
        return 1;
    }
    operation_status = write_report_header(report_file, argument_values[1], &set, csv_digest);
    if (write_group_line(report_file, &constant_group) != 0 ||
        write_group_line(report_file, &varying_group) != 0) {
        operation_status = 1;
    }
    if (write_method_lines(report_file, alpha_per_comparison) != 0) {
        operation_status = 1;
    }
    if (write_comparison_line(report_file,
            &constant_group,
            &varying_group,
            &result,
            result_label) != 0) {
        operation_status = 1;
    }
    if (fprintf(report_file,
            "significant_comparison_count=%d\n"
            "note=statistical_difference_only_no_exploitability_claim\n"
            "sample_independence_note=direction_constant_group_reuses_two_fixed_ciphertexts_"
            "under_one_key\n",
            strcmp(result_label, "significant") == 0 ? 1 : 0) < 0) {
        operation_status = 1;
    }
    if (fclose(report_file) != 0) {
        operation_status = 1;
    }
    if (operation_status != 0) {
        free(set.records);
        fputs("group analysis failed; use a new report path and a complete CSV\n", stderr);
        return 1;
    }
    printf("%s: analyzed %zu records; round-two group comparison %s:%s rank p=%.3g (%s); "
           "statistical result only\n",
        set.implementation,
        set.record_count,
        constant_group.group_name,
        varying_group.group_name,
        result.has_rank_test ? result.rank_p_value : 1.0,
        result_label);
    free(set.records);
    return 0;
}
