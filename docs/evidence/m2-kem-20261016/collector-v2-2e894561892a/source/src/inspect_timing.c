#include "timing_statistics.h"

#include <inttypes.h>
#include <stdlib.h>
#include <string.h>

static uint64_t greatest_common_divisor(uint64_t first_value, uint64_t second_value)
{
    while (second_value != 0) {
        uint64_t remainder = first_value % second_value;
        first_value = second_value;
        second_value = remainder;
    }
    return first_value;
}

static int write_series(FILE *report, const char *label, const struct sample_series *series)
{
    double mean_nanoseconds;
    double variance_nanoseconds_squared;
    long double tied_ordered_pairs = 0.0L;
    size_t value_start = 0;
    series_moments(series, &mean_nanoseconds, &variance_nanoseconds_squared);
    while (value_start < series->sample_count) {
        size_t value_end = value_start + 1u;
        while (value_end < series->sample_count &&
            series_value(series, value_end) == series_value(series, value_start)) {
            ++value_end;
        }
        long double repetition_count = (long double)(value_end - value_start);
        tied_ordered_pairs += repetition_count * (repetition_count - 1.0L);
        value_start = value_end;
    }
    long double possible_ordered_pairs =
        (long double)series->sample_count * (long double)(series->sample_count - 1u);
    return fprintf(report,
               "series=%s count=%zu mean_ns=%.6f p50_ns=%" PRIu64 " p90_ns=%" PRIu64
               " p99_ns=%" PRIu64 " min_ns=%" PRIu64 " max_ns=%" PRIu64
               " distinct_durations=%zu tied_pair_fraction=%.9Lf\n",
               label,
               series->sample_count,
               mean_nanoseconds,
               series_quantile(series, 0.5),
               series_quantile(series, 0.9),
               series_quantile(series, 0.99),
               series_value(series, 0),
               series_value(series, series->sample_count - 1u),
               series_distinct_values(series),
               possible_ordered_pairs > 0 ? tied_ordered_pairs / possible_ordered_pairs : 0.0L) < 0;
}

static int write_diagnostics(FILE *report,
    const struct measurement_set *set,
    struct measurement_record *sorted_records,
    const uint8_t csv_digest[32])
{
    uint64_t duration_grid_nanoseconds = 0;
    size_t adjacent_equal_count = 0;
    if (fprintf(report,
            "format=timing_diagnostics_v1\nrun_id=%s\nimplementation=%s\nrecord_count=%zu\n"
            "time_unit=ns\nquantile_rule=rounded_zero_based_index_half_up_no_interpolation\n"
            "quantile_index=floor(p*(n-1)+0.5)\nraw_order=preserved\noutlier_removal=none\n"
            "inference=descriptive_only\ncsv_digest_algorithm=SHA3-256\ncsv_digest=",
            set->run_id,
            set->implementation,
            set->record_count) < 0) {
        return 1;
    }
    for (size_t byte_index = 0; byte_index < 32u; ++byte_index) {
        if (fprintf(report, "%02x", csv_digest[byte_index]) < 0) {
            return 1;
        }
    }
    if (fputc('\n', report) == EOF) {
        return 1;
    }
    for (size_t record_index = 0; record_index < set->record_count; ++record_index) {
        uint64_t duration_nanoseconds = set->records[record_index].elapsed_nanoseconds;
        duration_grid_nanoseconds =
            greatest_common_divisor(duration_grid_nanoseconds, duration_nanoseconds);
        if (record_index > 0 &&
            duration_nanoseconds == set->records[record_index - 1u].elapsed_nanoseconds) {
            ++adjacent_equal_count;
        }
    }
    if (fprintf(report,
            "observed_duration_grid_ns=%" PRIu64 "\nadjacent_equal_fraction=%.9f\n",
            duration_grid_nanoseconds,
            (double)adjacent_equal_count / (double)(set->record_count - 1u)) < 0) {
        return 1;
    }
    /* 按原始顺序切四段；这些描述值不构成漂移检验。 */
    for (size_t block_index = 0; block_index < 4u; ++block_index) {
        size_t block_start = block_index * set->record_count / 4u;
        size_t block_end = (block_index + 1u) * set->record_count / 4u;
        long double duration_total = 0.0L;
        for (size_t record_index = block_start; record_index < block_end; ++record_index) {
            duration_total += (long double)set->records[record_index].elapsed_nanoseconds;
        }
        if (block_end > block_start &&
            fprintf(report,
                "order_block=%zu first_index=%zu count=%zu mean_ns=%.6Lf\n",
                block_index,
                block_start,
                block_end - block_start,
                duration_total / (long double)(block_end - block_start)) < 0) {
            return 1;
        }
    }
    struct sample_series all_series = {sorted_records, set->record_count};
    sort_range_by_duration(sorted_records, set->record_count);
    if (write_series(report, "all", &all_series) != 0) {
        return 1;
    }
    sort_records_by_category_then_duration(sorted_records, set->record_count);
    size_t category_start = 0;
    while (category_start < set->record_count) {
        unsigned category_index = sorted_records[category_start].category_index;
        size_t category_end = category_start + 1u;
        while (category_end < set->record_count &&
            sorted_records[category_end].category_index == category_index) {
            ++category_end;
        }
        struct sample_series category_series = {sorted_records + category_start,
            category_end - category_start};
        if (write_series(report,
                input_category_name((enum input_category)category_index),
                &category_series) != 0) {
            return 1;
        }
        category_start = category_end;
    }
    return fputs("report_status=complete\n", report) == EOF;
}

int main(int argument_count, char **argument_values)
{
    struct measurement_set set = {0};
    uint8_t csv_digest[32];
    struct measurement_record *sorted_records = NULL;
    FILE *report = NULL;
    int operation_status = 1;
    if (argument_count != 3) {
        fputs("Usage: inspect_timing CSV_FILE REPORT_FILE\n", stderr);
        return 2;
    }
    if (load_measurement_set(argument_values[1], &set) != 0 ||
        hash_csv_file(argument_values[1], csv_digest) != 0) {
        goto cleanup;
    }
    sorted_records = malloc(set.record_count * sizeof(*sorted_records));
    if (sorted_records == NULL) {
        goto cleanup;
    }
    memcpy(sorted_records, set.records, set.record_count * sizeof(*sorted_records));
    report = fopen(argument_values[2], "wx");
    if (report == NULL) {
        goto cleanup;
    }
    operation_status = write_diagnostics(report, &set, sorted_records, csv_digest);
    if (fclose(report) != 0) {
        operation_status = 1;
    }
cleanup:
    free(sorted_records);
    free(set.records);
    if (operation_status != 0) {
        fputs("timing diagnostics failed; discard any partial report\n", stderr);
    }
    return operation_status;
}
