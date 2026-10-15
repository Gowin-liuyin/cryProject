#ifndef BASELINE_TIMING_STATISTICS_H
#define BASELINE_TIMING_STATISTICS_H

#include "inputs.h"

#include <stdint.h>
#include <stdio.h>

/* 标识字段的容量同时决定结构体布局，因此放在头文件里。 */
#define ANALYSIS_RUN_ID_CAPACITY 65u
#define ANALYSIS_IMPLEMENTATION_CAPACITY 33u

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

/* 排序后同一类别的样本在记录数组中连续，序列只保存区间视图，不拥有数据。 */
struct sample_series {
    const struct measurement_record *records;
    size_t sample_count;
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

/* 读取并严格校验原始计时 CSV；本函数不排序，排序由调用方显式完成。 */
int load_measurement_set(const char *csv_path, struct measurement_set *set);

int hash_csv_file(const char *csv_path, uint8_t csv_digest[32]);

/* 对整份记录数组按「先类别索引、后耗时」排序；按类别切连续区间的唯一前提。 */
void sort_records_by_category_then_duration(struct measurement_record *records,
    size_t record_count);

/* 对给定的一段连续区间只按耗时排序，不看类别；原地改写该区间。 */
void sort_range_by_duration(struct measurement_record *records, size_t record_count);

uint64_t series_value(const struct sample_series *series, size_t sample_index);

uint64_t series_quantile(const struct sample_series *series, double fraction);

void series_moments(const struct sample_series *series,
    double *mean_nanoseconds,
    double *variance_nanoseconds_squared);

size_t series_distinct_values(const struct sample_series *series);

int compare_series(const struct sample_series *first_series,
    const struct sample_series *second_series,
    struct comparison_result *result);

const char *comparison_result_label(const struct comparison_result *result,
    int comparison_status,
    double alpha_per_comparison);

#endif
