#include <inttypes.h>
#include <stdbool.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#define NANOSECONDS_PER_SECOND UINT64_C(1000000000)
#define WARMUP_PAIR_COUNT 1000U
#define MAIN_PAIR_COUNT 100000U
#define RECORD_CAPACITY (WARMUP_PAIR_COUNT + MAIN_PAIR_COUNT)
#define INCREMENT_CAPACITY (2U * MAIN_PAIR_COUNT - 1U)
#define CSV_FIELD_COUNT 15U
#define INPUT_LINE_CAPACITY 1024U
#define OUTPUT_CAPACITY 4096U
#define SUMMARY_CAPACITY 2048U
#define STATISTIC_ROW_COUNT 6U

static const char input_header[] =
    "index,phase,before_attempted,before_has_timespec,before_seconds,before_fractional_ns,"
    "before_ns,before_errno,after_attempted,after_has_timespec,after_seconds,"
    "after_fractional_ns,after_ns,after_errno,elapsed_ns";

static const char output_header[] =
    "phase,series,count,zero_count,sum_ns,min_ns,min_positive_ns,p50_ns,p90_ns,p99_ns,max_ns,"
    "mad_ns\n";

struct clock_pair {
    uint64_t before_ns;
    uint64_t after_ns;
};

struct statistics {
    size_t count;
    size_t zero_count;
    uint64_t sum_ns;
    uint64_t minimum_ns;
    uint64_t minimum_positive_ns;
    uint64_t p50_ns;
    uint64_t p90_ns;
    uint64_t p99_ns;
    uint64_t maximum_ns;
    uint64_t mad_ns;
    bool has_positive_value;
};

struct phase_geometry {
    uint64_t first_before_ns;
    uint64_t last_after_ns;
    uint64_t wall_ns;
    uint64_t within_sum_ns;
    uint64_t between_sum_ns;
};

enum line_status {
    LINE_VALID,
    LINE_END,
    LINE_INVALID,
    LINE_READ_ERROR
};

_Static_assert(sizeof(struct clock_pair) * RECORD_CAPACITY +
            sizeof(uint64_t) * INCREMENT_CAPACITY * 2U + OUTPUT_CAPACITY + SUMMARY_CAPACITY +
            INPUT_LINE_CAPACITY + sizeof(struct statistics) * STATISTIC_ROW_COUNT <
        16U * 1024U * 1024U,
    "The explicit analysis working storage must remain below 16 MiB");

static bool add_nanoseconds(uint64_t left_ns, uint64_t right_ns, uint64_t *sum_ns)
{
    if (right_ns > UINT64_MAX - left_ns) {
        return false;
    }
    *sum_ns = left_ns + right_ns;
    return true;
}

static bool parse_unsigned_decimal(const char *text, uint64_t *value)
{
    uint64_t parsed_value = 0;
    if (text[0] == '\0') {
        return false;
    }
    for (size_t character_index = 0; text[character_index] != '\0'; ++character_index) {
        unsigned char character = (unsigned char)text[character_index];
        if (character < (unsigned char)'0' || character > (unsigned char)'9') {
            return false;
        }
        uint64_t digit = (uint64_t)(character - (unsigned char)'0');
        if (parsed_value > (UINT64_MAX - digit) / UINT64_C(10)) {
            return false;
        }
        parsed_value = parsed_value * UINT64_C(10) + digit;
    }
    *value = parsed_value;
    return true;
}

static bool normalize_input_line(char *line, size_t capacity)
{
    size_t terminator_index = capacity;
    for (size_t byte_index = 0; byte_index < capacity; ++byte_index) {
        if (line[byte_index] == '\0') {
            terminator_index = byte_index;
        }
    }
    if (terminator_index == capacity || terminator_index == 0U ||
        memchr(line, '\0', terminator_index) != NULL || line[terminator_index - 1U] != '\n') {
        return false;
    }
    line[terminator_index - 1U] = '\0';
    return true;
}

static enum line_status read_input_line(FILE *input_file, char *line, size_t capacity)
{
    /* 末尾自动NUL与输入内嵌NUL分别检查，不让strlen截断非法输入。 */
    memset(line, 0xff, capacity);
    if (fgets(line, (int)capacity, input_file) == NULL) {
        return ferror(input_file) ? LINE_READ_ERROR : LINE_END;
    }
    return normalize_input_line(line, capacity) ? LINE_VALID : LINE_INVALID;
}

static bool split_csv_fields(char *line, char **fields)
{
    char *field_start = line;
    for (size_t field_index = 0; field_index < CSV_FIELD_COUNT; ++field_index) {
        fields[field_index] = field_start;
        char *separator = strchr(field_start, ',');
        if (field_index + 1U < CSV_FIELD_COUNT) {
            if (separator == NULL) {
                return false;
            }
            *separator = '\0';
            field_start = separator + 1;
        } else if (separator != NULL) {
            return false;
        }
        if (fields[field_index][0] == '\0') {
            return false;
        }
    }
    return true;
}

static bool parse_successful_clock(char **fields, size_t first_field, uint64_t *clock_ns)
{
    uint64_t seconds;
    uint64_t fractional_ns;
    uint64_t recorded_ns;
    uint64_t error_number;
    if (strcmp(fields[first_field], "1") != 0 || strcmp(fields[first_field + 1U], "1") != 0 ||
        !parse_unsigned_decimal(fields[first_field + 2U], &seconds) ||
        !parse_unsigned_decimal(fields[first_field + 3U], &fractional_ns) ||
        !parse_unsigned_decimal(fields[first_field + 4U], &recorded_ns) ||
        !parse_unsigned_decimal(fields[first_field + 5U], &error_number) || error_number != 0 ||
        fractional_ns >= NANOSECONDS_PER_SECOND || seconds > UINT64_MAX / NANOSECONDS_PER_SECOND) {
        return false;
    }
    uint64_t converted_ns;
    if (!add_nanoseconds(seconds * NANOSECONDS_PER_SECOND, fractional_ns, &converted_ns) ||
        converted_ns != recorded_ns) {
        return false;
    }
    *clock_ns = recorded_ns;
    return true;
}

static bool parse_pair_record(char *line,
    size_t expected_index,
    const struct clock_pair *previous,
    struct clock_pair *record)
{
    char *fields[CSV_FIELD_COUNT];
    uint64_t recorded_index;
    uint64_t elapsed_ns;
    if (!split_csv_fields(line, fields) || !parse_unsigned_decimal(fields[0], &recorded_index) ||
        recorded_index != expected_index ||
        strcmp(fields[1], expected_index < WARMUP_PAIR_COUNT ? "warmup" : "main") != 0 ||
        !parse_successful_clock(fields, 2U, &record->before_ns) ||
        !parse_successful_clock(fields, 8U, &record->after_ns) ||
        !parse_unsigned_decimal(fields[14], &elapsed_ns) || record->after_ns < record->before_ns ||
        elapsed_ns != record->after_ns - record->before_ns ||
        (previous != NULL && record->before_ns < previous->after_ns)) {
        return false;
    }
    return true;
}

static const char *load_records(FILE *input_file, struct clock_pair *records)
{
    char line[INPUT_LINE_CAPACITY];
    enum line_status status = read_input_line(input_file, line, sizeof(line));
    if (status != LINE_VALID || strcmp(line, input_header) != 0) {
        return status == LINE_READ_ERROR ? "input_read_error" : "invalid_header";
    }
    for (size_t record_index = 0; record_index < RECORD_CAPACITY; ++record_index) {
        status = read_input_line(input_file, line, sizeof(line));
        if (status != LINE_VALID) {
            if (status == LINE_END) {
                return "insufficient_records";
            }
            return status == LINE_READ_ERROR ? "input_read_error" : "invalid_input_line";
        }
        const struct clock_pair *previous = record_index == 0U ? NULL : &records[record_index - 1U];
        if (!parse_pair_record(line, record_index, previous, &records[record_index])) {
            return "invalid_record";
        }
    }
    status = read_input_line(input_file, line, sizeof(line));
    if (status != LINE_END) {
        return status == LINE_READ_ERROR ? "input_read_error" : "extra_input";
    }
    return NULL;
}

static void sift_down(uint64_t *values, size_t root_index, size_t value_count)
{
    while (root_index < value_count / 2U) {
        size_t child_index = root_index * 2U + 1U;
        if (child_index + 1U < value_count && values[child_index + 1U] > values[child_index]) {
            ++child_index;
        }
        if (values[root_index] >= values[child_index]) {
            return;
        }
        uint64_t exchanged_value = values[root_index];
        values[root_index] = values[child_index];
        values[child_index] = exchanged_value;
        root_index = child_index;
    }
}

static void sort_values(uint64_t *values, size_t value_count)
{
    for (size_t parent_count = value_count / 2U; parent_count > 0U; --parent_count) {
        sift_down(values, parent_count - 1U, value_count);
    }
    for (size_t unsorted_count = value_count; unsorted_count > 1U; --unsorted_count) {
        uint64_t exchanged_value = values[0];
        values[0] = values[unsorted_count - 1U];
        values[unsorted_count - 1U] = exchanged_value;
        sift_down(values, 0U, unsorted_count - 1U);
    }
}

static size_t percentile_index(size_t value_count, size_t percentile)
{
    return ((value_count - 1U) * percentile + 50U) / 100U;
}

static bool summarize_values(uint64_t *values,
    size_t value_count,
    uint64_t *absolute_deviations,
    struct statistics *result)
{
    *result = (struct statistics){0};
    if (value_count == 0U || value_count > INCREMENT_CAPACITY) {
        return false;
    }
    result->count = value_count;
    for (size_t value_index = 0; value_index < value_count; ++value_index) {
        if (!add_nanoseconds(result->sum_ns, values[value_index], &result->sum_ns)) {
            return false;
        }
        if (values[value_index] == 0U) {
            ++result->zero_count;
        }
    }
    sort_values(values, value_count);
    result->minimum_ns = values[0];
    result->maximum_ns = values[value_count - 1U];
    result->p50_ns = values[percentile_index(value_count, 50U)];
    result->p90_ns = values[percentile_index(value_count, 90U)];
    result->p99_ns = values[percentile_index(value_count, 99U)];
    if (result->zero_count < value_count) {
        result->has_positive_value = true;
        result->minimum_positive_ns = values[result->zero_count];
    }
    uint64_t median_ns = values[value_count / 2U];
    for (size_t value_index = 0; value_index < value_count; ++value_index) {
        absolute_deviations[value_index] = values[value_index] >= median_ns
            ? values[value_index] - median_ns
            : median_ns - values[value_index];
    }
    sort_values(absolute_deviations, value_count);
    result->mad_ns = absolute_deviations[value_count / 2U];
    return true;
}

static bool summarize_phase(const struct clock_pair *records,
    size_t record_count,
    uint64_t *increments,
    uint64_t *absolute_deviations,
    struct statistics *results,
    struct phase_geometry *geometry)
{
    if (record_count < 2U || record_count > MAIN_PAIR_COUNT) {
        return false;
    }
    for (size_t record_index = 0; record_index < record_count; ++record_index) {
        if (records[record_index].after_ns < records[record_index].before_ns ||
            (record_index > 0U &&
                records[record_index].before_ns < records[record_index - 1U].after_ns)) {
            return false;
        }
        increments[record_index] = records[record_index].after_ns - records[record_index].before_ns;
    }
    if (!summarize_values(increments, record_count, absolute_deviations, &results[0])) {
        return false;
    }
    for (size_t record_index = 1U; record_index < record_count; ++record_index) {
        increments[record_index - 1U] =
            records[record_index].before_ns - records[record_index - 1U].after_ns;
    }
    if (!summarize_values(increments, record_count - 1U, absolute_deviations, &results[1])) {
        return false;
    }
    for (size_t record_index = 0; record_index < record_count; ++record_index) {
        increments[record_index * 2U] =
            records[record_index].after_ns - records[record_index].before_ns;
        if (record_index > 0U) {
            increments[record_index * 2U - 1U] =
                records[record_index].before_ns - records[record_index - 1U].after_ns;
        }
    }
    if (!summarize_values(increments, record_count * 2U - 1U, absolute_deviations, &results[2])) {
        return false;
    }
    geometry->first_before_ns = records[0].before_ns;
    geometry->last_after_ns = records[record_count - 1U].after_ns;
    geometry->wall_ns = geometry->last_after_ns - geometry->first_before_ns;
    geometry->within_sum_ns = results[0].sum_ns;
    geometry->between_sum_ns = results[1].sum_ns;
    uint64_t conserved_ns;
    return add_nanoseconds(geometry->within_sum_ns, geometry->between_sum_ns, &conserved_ns) &&
        conserved_ns == geometry->wall_ns && results[2].sum_ns == geometry->wall_ns;
}

static bool phase_boundary_is_conserved(const struct phase_geometry *warmup,
    const struct phase_geometry *main_phase,
    uint64_t *boundary_gap_ns)
{
    if (main_phase->first_before_ns < warmup->last_after_ns) {
        return false;
    }
    *boundary_gap_ns = main_phase->first_before_ns - warmup->last_after_ns;
    uint64_t conserved_ns;
    return add_nanoseconds(warmup->wall_ns, *boundary_gap_ns, &conserved_ns) &&
        add_nanoseconds(conserved_ns, main_phase->wall_ns, &conserved_ns) &&
        conserved_ns == main_phase->last_after_ns - warmup->first_before_ns;
}

static bool format_csv(char *output, size_t capacity, const struct statistics *results)
{
    static const char *const series_names[] = {"within_pair_ns",
        "between_pairs_ns",
        "combined_ordered_read_increment_ns"};
    size_t output_count = strlen(output_header);
    if (output_count >= capacity) {
        return false;
    }
    memcpy(output, output_header, output_count + 1U);
    for (size_t result_index = 0; result_index < STATISTIC_ROW_COUNT; ++result_index) {
        const struct statistics *result = &results[result_index];
        char minimum_positive_text[32] = "null";
        if (result->has_positive_value) {
            int written = snprintf(minimum_positive_text,
                sizeof(minimum_positive_text),
                "%" PRIu64,
                result->minimum_positive_ns);
            if (written < 0 || (size_t)written >= sizeof(minimum_positive_text)) {
                return false;
            }
        }
        int written = snprintf(output + output_count,
            capacity - output_count,
            "%s,%s,%zu,%zu,%" PRIu64 ",%" PRIu64 ",%s,%" PRIu64 ",%" PRIu64 ",%" PRIu64 ",%" PRIu64
            ",%" PRIu64 "\n",
            result_index < 3U ? "warmup" : "main",
            series_names[result_index % 3U],
            result->count,
            result->zero_count,
            result->sum_ns,
            result->minimum_ns,
            minimum_positive_text,
            result->p50_ns,
            result->p90_ns,
            result->p99_ns,
            result->maximum_ns,
            result->mad_ns);
        if (written < 0 || (size_t)written >= capacity - output_count) {
            return false;
        }
        output_count += (size_t)written;
    }
    return true;
}

static bool format_summary(char *output,
    size_t capacity,
    const struct phase_geometry *warmup,
    const struct phase_geometry *main_phase,
    uint64_t boundary_gap_ns)
{
    int written = snprintf(output,
        capacity,
        "{\"status\":\"descriptive_only\",\"schema\":\"raw-clock-analysis-v1\","
        "\"units\":\"ns\",\"record_count\":%u,\"warmup_pair_count\":%u,\"main_pair_count\":%u,"
        "\"phase_boundary_gap_ns\":%" PRIu64 ",\"warmup_wall_ns\":%" PRIu64
        ",\"main_wall_ns\":%" PRIu64 ",\"warmup_pair_sum_ns\":%" PRIu64
        ",\"warmup_between_sum_ns\":%" PRIu64 ",\"main_pair_sum_ns\":%" PRIu64
        ",\"main_between_sum_ns\":%" PRIu64 ",\"phase_conservation_valid\":true,"
        "\"cross_phase_conservation_valid\":true,\"clock_precision_certified\":false,"
        "\"iid_claimed\":false,\"collector_stderr_checked\":false,"
        "\"collector_exit_checked\":false,\"complete_metadata_acceptance\":false,"
        "\"r02_signed_off\":false,\"r04_signed_off\":false}\n",
        RECORD_CAPACITY,
        WARMUP_PAIR_COUNT,
        MAIN_PAIR_COUNT,
        boundary_gap_ns,
        warmup->wall_ns,
        main_phase->wall_ns,
        warmup->within_sum_ns,
        warmup->between_sum_ns,
        main_phase->within_sum_ns,
        main_phase->between_sum_ns);
    return written >= 0 && (size_t)written < capacity;
}

static int report_unknown(const char *reason)
{
    (void)fprintf(stderr,
        "{\"status\":\"unknown\",\"schema\":\"raw-clock-analysis-v1\",\"reason\":\"%s\","
        "\"clock_precision_certified\":false,\"r02_signed_off\":false,"
        "\"r04_signed_off\":false}\n",
        reason);
    (void)fflush(stderr);
    return 1;
}

static bool selfcheck_statistics(void)
{
    uint64_t deviations[4];
    struct statistics result;
    uint64_t odd_values[] = {10U, 0U, 4U};
    if (!summarize_values(odd_values, 3U, deviations, &result) || result.count != 3U ||
        result.zero_count != 1U || result.sum_ns != 14U || result.minimum_ns != 0U ||
        !result.has_positive_value || result.minimum_positive_ns != 4U || result.p50_ns != 4U ||
        result.p90_ns != 10U || result.p99_ns != 10U || result.maximum_ns != 10U ||
        result.mad_ns != 4U) {
        return false;
    }
    uint64_t even_values[] = {8U, 0U, 2U, 0U};
    if (!summarize_values(even_values, 4U, deviations, &result) || result.count != 4U ||
        result.zero_count != 2U || result.sum_ns != 10U || result.minimum_ns != 0U ||
        !result.has_positive_value || result.minimum_positive_ns != 2U || result.p50_ns != 2U ||
        result.p90_ns != 8U || result.p99_ns != 8U || result.maximum_ns != 8U ||
        result.mad_ns != 2U) {
        return false;
    }
    uint64_t zero_values[] = {0U, 0U};
    if (!summarize_values(zero_values, 2U, deviations, &result) || result.zero_count != 2U ||
        result.sum_ns != 0U || result.has_positive_value || result.p50_ns != 0U ||
        result.p90_ns != 0U || result.p99_ns != 0U || result.maximum_ns != 0U ||
        result.mad_ns != 0U) {
        return false;
    }
    uint64_t overflowing_values[] = {UINT64_MAX, 1U};
    uint64_t maximum_sum;
    return !summarize_values(overflowing_values, 2U, deviations, &result) &&
        !summarize_values(zero_values, 0U, deviations, &result) &&
        add_nanoseconds(UINT64_MAX, 0U, &maximum_sum) && maximum_sum == UINT64_MAX &&
        !add_nanoseconds(UINT64_MAX, 1U, &maximum_sum) && percentile_index(1U, 50U) == 0U &&
        percentile_index(2U, 50U) == 1U && percentile_index(3U, 50U) == 1U &&
        percentile_index(6U, 90U) == 5U && percentile_index(101U, 99U) == 99U;
}

struct parsing_fixture {
    const char *csv;
    size_t expected_index;
    bool is_accepted;
};

static bool selfcheck_parsing(void)
{
    static const struct parsing_fixture fixtures[] = {
        {"0,warmup,1,1,1,0,1000000000,0,1,1,1,10,1000000010,0,10", 0U, true},
        {"1000,main,1,1,1,0,1000000000,0,1,1,1,0,1000000000,0,0", 1000U, true},
        {"0,warmup,1,1,18446744073,709551615,18446744073709551615,0,1,1,18446744073,"
         "709551615,18446744073709551615,0,0",
            0U,
            true},
        {"0,warmup,1,1,1,0,1000000000,0,1,1,1,10,1000000010,0,10,extra", 0U, false},
        {"0,warmup,1,1,1,0,1000000000,0,1,1,1,10,1000000010,0", 0U, false},
        {"0,warmup,1,1,1,0,1000000000,0,1,1,1,10,1000000010,0,", 0U, false},
        {"1,warmup,1,1,1,0,1000000000,0,1,1,1,10,1000000010,0,10", 0U, false},
        {"1000,warmup,1,1,1,0,1000000000,0,1,1,1,10,1000000010,0,10", 1000U, false},
        {"0,warmup,0,0,null,null,null,null,1,1,1,10,1000000010,0,null", 0U, false},
        {"0,warmup,1,0,null,null,null,5,1,1,1,10,1000000010,0,null", 0U, false},
        {"0,warmup,1,1,1,0,null,75,1,1,1,10,1000000010,0,null", 0U, false},
        {"0,warmup,1,1,1,0,1000000000,34,1,1,1,10,1000000010,0,10", 0U, false},
        {"0,warmup,1,1,-1,0,1000000000,0,1,1,1,10,1000000010,0,10", 0U, false},
        {"0,warmup,1,1,1,1000000000,2000000000,0,1,1,2,10,2000000010,0,10", 0U, false},
        {"0,warmup,1,1,18446744073,709551616,18446744073709551615,0,1,1,18446744073,"
         "709551616,18446744073709551615,0,0",
            0U,
            false},
        {"0,warmup,1,1,1,0,1000000001,0,1,1,1,10,1000000010,0,9", 0U, false},
        {"0,warmup,1,1,1,10,1000000010,0,1,1,1,0,1000000000,0,0", 0U, false},
        {"0,warmup,1,1,1,0,1000000000,0,1,1,1,10,1000000010,0,11", 0U, false},
        {"0,warmup,1,1,1,0,1000000000,0,1,1,1,10,1000000010,0,18446744073709551616", 0U, false},
        {"0,warmup,1,1,1,0,1000000000,0,1,1,1,10,1000000010,0, 10", 0U, false}};
    for (size_t fixture_index = 0; fixture_index < sizeof(fixtures) / sizeof(fixtures[0]);
        ++fixture_index) {
        char line[INPUT_LINE_CAPACITY];
        size_t fixture_size = strlen(fixtures[fixture_index].csv) + 1U;
        if (fixture_size > sizeof(line)) {
            return false;
        }
        memcpy(line, fixtures[fixture_index].csv, fixture_size);
        struct clock_pair record;
        if (parse_pair_record(line, fixtures[fixture_index].expected_index, NULL, &record) !=
            fixtures[fixture_index].is_accepted) {
            return false;
        }
    }
    uint64_t parsed_value;
    if (!parse_unsigned_decimal("18446744073709551615", &parsed_value) ||
        parsed_value != UINT64_MAX ||
        parse_unsigned_decimal("18446744073709551616", &parsed_value) ||
        parse_unsigned_decimal("+1", &parsed_value) || parse_unsigned_decimal("", &parsed_value)) {
        return false;
    }
    struct clock_pair previous = {1000000000U, 1000000010U};
    struct clock_pair record;
    char equal_order[] = "1,warmup,1,1,1,10,1000000010,0,1,1,1,10,1000000010,0,0";
    char reversed_order[] = "1,warmup,1,1,1,9,1000000009,0,1,1,1,10,1000000010,0,1";
    if (!parse_pair_record(equal_order, 1U, &previous, &record) ||
        parse_pair_record(reversed_order, 1U, &previous, &record)) {
        return false;
    }
    char line[16];
    memset(line, 0xff, sizeof(line));
    memcpy(line, "valid\n", 7U);
    if (!normalize_input_line(line, sizeof(line)) || strcmp(line, "valid") != 0) {
        return false;
    }
    memset(line, 0xff, sizeof(line));
    memcpy(line, "bad\0data\n", 10U);
    if (normalize_input_line(line, sizeof(line))) {
        return false;
    }
    memset(line, 0xff, sizeof(line));
    memcpy(line, "no_newline", 11U);
    return !normalize_input_line(line, sizeof(line));
}

static bool selfcheck_phase_geometry(void)
{
    static const struct clock_pair records[] = {{10U, 12U},
        {12U, 15U},
        {20U, 20U},
        {21U, 25U},
        {30U, 31U}};
    uint64_t increments[5];
    uint64_t deviations[5];
    struct statistics results[STATISTIC_ROW_COUNT];
    struct phase_geometry warmup;
    struct phase_geometry main_phase;
    uint64_t boundary_gap_ns;
    if (!summarize_phase(records, 2U, increments, deviations, &results[0], &warmup) ||
        !summarize_phase(records + 2U, 3U, increments, deviations, &results[3], &main_phase) ||
        !phase_boundary_is_conserved(&warmup, &main_phase, &boundary_gap_ns) ||
        warmup.wall_ns != 5U || warmup.within_sum_ns != 5U || warmup.between_sum_ns != 0U ||
        main_phase.wall_ns != 11U || main_phase.within_sum_ns != 5U ||
        main_phase.between_sum_ns != 6U || boundary_gap_ns != 5U || results[0].count != 2U ||
        results[0].p50_ns != 3U || results[0].mad_ns != 1U || results[1].count != 1U ||
        results[1].zero_count != 1U || results[1].has_positive_value || results[2].count != 3U ||
        results[2].sum_ns != 5U || results[2].p50_ns != 2U || results[2].mad_ns != 1U ||
        results[3].count != 3U || results[3].p50_ns != 1U || results[3].mad_ns != 1U ||
        results[4].count != 2U || results[4].p50_ns != 5U || results[4].mad_ns != 4U ||
        results[5].count != 5U || results[5].sum_ns != 11U || results[5].p50_ns != 1U ||
        results[5].mad_ns != 1U) {
        return false;
    }
    char csv[OUTPUT_CAPACITY];
    char summary[SUMMARY_CAPACITY];
    if (!format_csv(csv, sizeof(csv), results) ||
        strstr(csv, "warmup,between_pairs_ns,1,1,0,0,null,0,0,0,0,0\n") == NULL ||
        !format_summary(summary, sizeof(summary), &warmup, &main_phase, boundary_gap_ns) ||
        strstr(summary, "\"phase_boundary_gap_ns\":5") == NULL) {
        return false;
    }
    main_phase.first_before_ns = 14U;
    return !phase_boundary_is_conserved(&warmup, &main_phase, &boundary_gap_ns);
}

static int run_selfcheck(void)
{
    if (!selfcheck_statistics() || !selfcheck_parsing() || !selfcheck_phase_geometry()) {
        return report_unknown("selfcheck_failed");
    }
    if (fputs("{\"status\":\"selfcheck_passed\",\"schema\":\"raw-clock-analysis-v1\","
              "\"real_clock_reads\":0,\"clock_precision_certified\":false,"
              "\"r02_signed_off\":false,\"r04_signed_off\":false}\n",
            stderr) == EOF ||
        fflush(stderr) != 0) {
        return 1;
    }
    return 0;
}

int main(int argument_count, char **arguments)
{
    if (argument_count != 2) {
        return report_unknown("expected_input_path_or_selfcheck");
    }
    if (strcmp(arguments[1], "--selfcheck") == 0) {
        return run_selfcheck();
    }
    FILE *input_file = fopen(arguments[1], "rb");
    if (input_file == NULL) {
        return report_unknown("input_open_error");
    }
    struct clock_pair *records = calloc(RECORD_CAPACITY, sizeof(*records));
    uint64_t *increments = malloc(INCREMENT_CAPACITY * sizeof(*increments));
    uint64_t *absolute_deviations = malloc(INCREMENT_CAPACITY * sizeof(*absolute_deviations));
    const char *failure_reason = NULL;
    if (records == NULL || increments == NULL || absolute_deviations == NULL) {
        failure_reason = "allocation_error";
    } else {
        failure_reason = load_records(input_file, records);
    }
    if (fclose(input_file) != 0 && failure_reason == NULL) {
        failure_reason = "input_close_error";
    }
    struct statistics results[STATISTIC_ROW_COUNT];
    struct phase_geometry warmup;
    struct phase_geometry main_phase;
    uint64_t boundary_gap_ns = 0;
    if (failure_reason == NULL &&
        (!summarize_phase(records,
             WARMUP_PAIR_COUNT,
             increments,
             absolute_deviations,
             &results[0],
             &warmup) ||
            !summarize_phase(records + WARMUP_PAIR_COUNT,
                MAIN_PAIR_COUNT,
                increments,
                absolute_deviations,
                &results[3],
                &main_phase) ||
            !phase_boundary_is_conserved(&warmup, &main_phase, &boundary_gap_ns))) {
        failure_reason = "statistics_or_conservation_error";
    }
    char output[OUTPUT_CAPACITY];
    char summary[SUMMARY_CAPACITY];
    if (failure_reason == NULL &&
        (!format_csv(output, sizeof(output), results) ||
            !format_summary(summary, sizeof(summary), &warmup, &main_phase, boundary_gap_ns))) {
        failure_reason = "output_format_error";
    }
    free(absolute_deviations);
    free(increments);
    free(records);
    if (failure_reason != NULL) {
        return report_unknown(failure_reason);
    }
    /* 全部校验、统计与格式化完成后才发布，不输出失败输入的幸存摘要。 */
    if (fputs(output, stdout) == EOF || fflush(stdout) != 0) {
        return report_unknown("stdout_write_error");
    }
    if (fputs(summary, stderr) == EOF || fflush(stderr) != 0) {
        return 1;
    }
    return 0;
}
