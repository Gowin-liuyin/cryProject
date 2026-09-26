#include "inputs.h"
#include <stdio.h>
#include <string.h>

struct measurement_record {
    char run_id[65];
    enum input_category category;
    uint64_t sample_index;
    uint64_t elapsed_nanoseconds;
};

static int read_measurement_record(char *record_line, const char *expected_implementation,
    struct measurement_record *record)
{
    char *fields[6];
    size_t line_byte_count = strlen(record_line);
    if (line_byte_count == 0 || record_line[line_byte_count - 1u] != '\n') return 1;
    record_line[line_byte_count - 1u] = '\0';
    fields[0] = record_line;
    for (size_t field_index = 0; field_index < 5u; ++field_index) {
        char *field_separator = strchr(fields[field_index], ',');
        if (field_separator == NULL || field_separator == fields[field_index]) return 1;
        *field_separator = '\0';
        fields[field_index + 1u] = field_separator + 1;
    }
    if (strlen(fields[0]) >= sizeof(record->run_id) ||
        strcmp(fields[1], expected_implementation) != 0 ||
        parse_input_category(fields[2], &record->category) != 0 ||
        parse_unsigned_integer(fields[3], &record->sample_index) != 0 ||
        parse_unsigned_integer(fields[4], &record->elapsed_nanoseconds) != 0 ||
        record->elapsed_nanoseconds == 0 || strcmp(fields[5], "ns") != 0) return 1;
    memcpy(record->run_id, fields[0], strlen(fields[0]) + 1u);
    return 0;
}

int main(int argument_count, char **argument_values)
{
    FILE *reference_file = NULL;
    FILE *vulnerable_file = NULL;
    char reference_line[256];
    char vulnerable_line[256];
    char reference_run_id[65] = "";
    char vulnerable_run_id[65] = "";
    size_t category_counts[INPUT_CATEGORY_COUNT] = {0};
    size_t row_count = 0;
    uint64_t samples_per_category;
    int operation_status = 1;
    if (argument_count != 4 || parse_unsigned_integer(argument_values[3], &samples_per_category) != 0 ||
        samples_per_category == 0 || samples_per_category > 20000u) goto cleanup;
    reference_file = fopen(argument_values[1], "r");
    vulnerable_file = fopen(argument_values[2], "r");
    if (reference_file == NULL || vulnerable_file == NULL) goto cleanup;
    if (fgets(reference_line, sizeof(reference_line), reference_file) == NULL ||
        fgets(vulnerable_line, sizeof(vulnerable_line), vulnerable_file) == NULL ||
        strcmp(reference_line, "run_id,implementation,input_category,sample_index,elapsed_nanoseconds,time_unit\n") != 0 ||
        strcmp(reference_line, vulnerable_line) != 0) goto cleanup;
    while (fgets(reference_line, sizeof(reference_line), reference_file) != NULL) {
        struct measurement_record reference_record;
        struct measurement_record vulnerable_record;
        if (fgets(vulnerable_line, sizeof(vulnerable_line), vulnerable_file) == NULL ||
            read_measurement_record(reference_line, "reference", &reference_record) != 0 ||
            read_measurement_record(vulnerable_line, "vulnerable", &vulnerable_record) != 0 ||
            reference_record.sample_index != row_count || vulnerable_record.sample_index != row_count ||
            reference_record.category != vulnerable_record.category) goto cleanup;
        if (row_count == 0) {
            memcpy(reference_run_id, reference_record.run_id, strlen(reference_record.run_id) + 1u);
            memcpy(vulnerable_run_id, vulnerable_record.run_id, strlen(vulnerable_record.run_id) + 1u);
        }
        if (strcmp(reference_record.run_id, reference_run_id) != 0 ||
            strcmp(vulnerable_record.run_id, vulnerable_run_id) != 0) goto cleanup;
        ++category_counts[reference_record.category];
        ++row_count;
    }
    if (fgetc(vulnerable_file) != EOF || ferror(reference_file) || ferror(vulnerable_file) ||
        row_count != samples_per_category * INPUT_CATEGORY_COUNT) goto cleanup;
    for (unsigned category_index = 0; category_index < INPUT_CATEGORY_COUNT; ++category_index)
        if (category_counts[category_index] != samples_per_category) goto cleanup;
    operation_status = 0;
cleanup:
    if (reference_file != NULL && fclose(reference_file) != 0) operation_status = 1;
    if (vulnerable_file != NULL && fclose(vulnerable_file) != 0) operation_status = 1;
    if (operation_status != 0) {
        fputs("invalid measurement CSV or mismatched run records\n", stderr);
    } else {
        printf("CSV counts, units, values, run IDs and category order passed: %zu rows per version\n", row_count);
    }
    return operation_status;
}
