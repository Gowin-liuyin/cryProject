#include "timing_statistics.h"

#include <errno.h>
#include <inttypes.h>
#include <math.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#define MAXIMUM_RECORDS 2000000u
#define LINE_CAPACITY 1024u
#define MAXIMUM_EXACT_DOUBLE_INTEGER UINT64_C(9007199254740991)

struct csv_input {
    struct measurement_record *records;
    size_t record_count;
    size_t class_counts[2];
    size_t excluded_count;
    char run_id[LINE_CAPACITY];
    char implementation[LINE_CAPACITY];
};

static int parse_nanoseconds(const char *text, uint64_t *value)
{
    if (*text == '\0') {
        return 1;
    }
    for (const char *character = text; *character != '\0'; ++character) {
        if (*character < '0' || *character > '9') {
            return 1;
        }
    }
    char *end;
    errno = 0;
    unsigned long long parsed_value = strtoull(text, &end, 10);
    if (errno != 0 || *end != '\0' || parsed_value > MAXIMUM_EXACT_DOUBLE_INTEGER) {
        return 1;
    }
    *value = (uint64_t)parsed_value;
    return 0;
}

static size_t split_fields(char *line, char **fields, size_t capacity)
{
    size_t field_count = 1u;
    fields[0] = line;
    for (char *character = line; *character != '\0'; ++character) {
        if (*character == '"' || *character == '\r') {
            return 0u;
        }
        if (*character == ',') {
            *character = '\0';
            if (field_count == capacity) {
                return 0u;
            }
            fields[field_count++] = character + 1;
        }
    }
    return field_count;
}

static int append_value(struct csv_input *input, unsigned class_index, const char *text)
{
    uint64_t elapsed_nanoseconds;
    if (input->record_count == MAXIMUM_RECORDS ||
        parse_nanoseconds(text, &elapsed_nanoseconds) != 0) {
        return 1;
    }
    input->records[input->record_count].category_index = class_index;
    input->records[input->record_count].elapsed_nanoseconds = elapsed_nanoseconds;
    ++input->record_count;
    ++input->class_counts[class_index];
    return 0;
}

static int load_input(FILE *source,
    const char *format,
    const char *first_class,
    const char *second_class,
    struct csv_input *input)
{
    char line[LINE_CAPACITY];
    char *fields[6];
    int is_wide = strcmp(format, "wide") == 0;
    if (fgets(line, sizeof(line), source) == NULL) {
        return 1;
    }
    if ((is_wide && strcmp(line, "class0_ns,class1_ns\n") != 0) ||
        (!is_wide &&
            strcmp(line,
                "run_id,implementation,input_category,sample_index,elapsed_nanoseconds,"
                "time_unit\n") != 0)) {
        return 1;
    }
    while (fgets(line, sizeof(line), source) != NULL) {
        size_t line_length = strlen(line);
        if (line_length == 0u || line[line_length - 1u] != '\n') {
            return 1;
        }
        line[line_length - 1u] = '\0';
        size_t field_count = split_fields(line, fields, 6u);
        if (is_wide) {
            if (field_count != 2u || append_value(input, 0u, fields[0]) != 0 ||
                append_value(input, 1u, fields[1]) != 0) {
                return 1;
            }
        } else {
            uint64_t sample_index;
            if (field_count != 6u || *fields[0] == '\0' || *fields[1] == '\0' ||
                *fields[2] == '\0' || parse_nanoseconds(fields[3], &sample_index) != 0 ||
                strcmp(fields[5], "ns") != 0) {
                return 1;
            }
            if (*input->run_id == '\0') {
                strcpy(input->run_id, fields[0]);
                strcpy(input->implementation, fields[1]);
            }
            if (strcmp(input->run_id, fields[0]) != 0 ||
                strcmp(input->implementation, fields[1]) != 0) {
                return 1;
            }
            unsigned class_index;
            if (strcmp(fields[2], first_class) == 0) {
                class_index = 0u;
            } else if (strcmp(fields[2], second_class) == 0) {
                class_index = 1u;
            } else {
                uint64_t excluded_nanoseconds;
                if (parse_nanoseconds(fields[4], &excluded_nanoseconds) != 0) {
                    return 1;
                }
                ++input->excluded_count;
                continue;
            }
            if (append_value(input, class_index, fields[4]) != 0) {
                return 1;
            }
        }
    }
    return ferror(source) || input->class_counts[0] < 2u || input->class_counts[1] < 2u;
}

static FILE *open_output(const char *directory, const char *name)
{
    char path[4096];
    int path_length = snprintf(path, sizeof(path), "%s/%s", directory, name);
    if (path_length < 0 || (size_t)path_length >= sizeof(path)) {
        return NULL;
    }
    return fopen(path, "wx");
}

static int write_normalized(const struct csv_input *input, const char *directory)
{
    FILE *normalized = open_output(directory, "normalized.csv");
    if (normalized == NULL) {
        return 1;
    }
    fputs("V1,V2\n", normalized);
    for (size_t record_index = 0; record_index < input->record_count; ++record_index) {
        const struct measurement_record *record = &input->records[record_index];
        fprintf(normalized,
            "%c,%" PRIu64 "\n",
            record->category_index == 0u ? 'X' : 'Y',
            record->elapsed_nanoseconds);
    }
    int write_failed = ferror(normalized);
    return fclose(normalized) != 0 || write_failed;
}

static int write_statistics(struct csv_input *input, const char *directory)
{
    sort_records_by_category_then_duration(input->records, input->record_count);
    struct sample_series first_series = {input->records, input->class_counts[0]};
    struct sample_series second_series = {input->records + input->class_counts[0],
        input->class_counts[1]};
    struct comparison_result comparison;
    if (compare_series(&first_series, &second_series, &comparison) != 0) {
        return 1;
    }
    double first_mean_nanoseconds;
    double first_variance;
    double second_mean_nanoseconds;
    double second_variance;
    series_moments(&first_series, &first_mean_nanoseconds, &first_variance);
    series_moments(&second_series, &second_mean_nanoseconds, &second_variance);
    double standard_error_nanoseconds = sqrt(first_variance / (double)first_series.sample_count +
        second_variance / (double)second_series.sample_count);
    FILE *summary = open_output(directory, "ci_welch.json");
    if (summary == NULL) {
        return 1;
    }
    fprintf(summary,
        "{\n  \"status\": \"%s\",\n  \"unit\": \"ns\",\n"
        "  \"class0_count\": %zu,\n  \"class1_count\": %zu,\n"
        "  \"excluded_other_category_count\": %zu,\n  \"dropped_tail_count\": 0,\n"
        "  \"mean_difference_class0_minus_class1_ns\": %.17g,\n"
        "  \"standard_error_ns\": %.17g,\n"
        "  \"ci95_normal_lower_ns\": %.17g,\n  \"ci95_normal_upper_ns\": %.17g,\n"
        "  \"welch_t\": ",
        comparison.has_location_test ? "ok" : "degenerate_zero_variance",
        first_series.sample_count,
        second_series.sample_count,
        input->excluded_count,
        comparison.mean_difference_nanoseconds,
        standard_error_nanoseconds,
        comparison.mean_difference_nanoseconds - 1.959963984540054 * standard_error_nanoseconds,
        comparison.mean_difference_nanoseconds + 1.959963984540054 * standard_error_nanoseconds);
    if (comparison.has_location_test) {
        fprintf(summary,
            "%.17g,\n  \"welch_degrees_of_freedom\": %.17g,\n"
            "  \"p_two_sided_normal_approximation\": %.17g,\n",
            comparison.welch_t_statistic,
            comparison.welch_degrees_of_freedom,
            comparison.welch_p_value);
    } else {
        fputs("null,\n  \"welch_degrees_of_freedom\": null,\n"
              "  \"p_two_sided_normal_approximation\": null,\n",
            summary);
    }
    fputs("  \"holm\": \"not_applied_requires_preregistered_family\",\n"
          "  \"interpretation\": \"descriptive_normal_approximation_not_exact_student_t\"\n}\n",
        summary);
    int write_failed = ferror(summary);
    return fclose(summary) != 0 || write_failed;
}

int main(int argument_count, char **arguments)
{
    if (argument_count != 6 ||
        (strcmp(arguments[2], "wide") != 0 && strcmp(arguments[2], "measure") != 0) ||
        strcmp(arguments[3], arguments[4]) == 0) {
        fputs("usage: platform_stats INPUT wide|measure CLASS0 CLASS1 OUTPUT_DIRECTORY\n", stderr);
        return 2;
    }
    FILE *source = fopen(arguments[1], "r");
    if (source == NULL) {
        perror("input");
        return 1;
    }
    struct csv_input input = {0};
    input.records = calloc(MAXIMUM_RECORDS, sizeof(*input.records));
    if (input.records == NULL) {
        fclose(source);
        return 1;
    }
    int status = load_input(source, arguments[2], arguments[3], arguments[4], &input);
    status |= fclose(source) != 0;
    if (status == 0) {
        status = write_normalized(&input, arguments[5]);
    }
    if (status == 0) {
        status = write_statistics(&input, arguments[5]);
    }
    free(input.records);
    if (status != 0) {
        fputs("invalid CSV, mixed run/implementation, unsupported unit, or output failure\n",
            stderr);
    }
    return status;
}
