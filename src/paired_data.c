#include "paired_data.h"

#include <inttypes.h>
#include <stdlib.h>
#include <string.h>

int is_paired_hex(const char *text, size_t character_count)
{
    if (strlen(text) != character_count) {
        return 0;
    }
    for (size_t character_index = 0; character_index < character_count; ++character_index) {
        if (!((text[character_index] >= '0' && text[character_index] <= '9') ||
                (text[character_index] >= 'a' && text[character_index] <= 'f'))) {
            return 0;
        }
    }
    return 1;
}

int is_paired_identifier(const char *text)
{
    size_t character_count = strlen(text);
    if (character_count == 0 || character_count > 64u) {
        return 0;
    }
    for (size_t character_index = 0; character_index < character_count; ++character_index) {
        char character = text[character_index];
        if (!((character >= 'a' && character <= 'z') || (character >= 'A' && character <= 'Z') ||
                (character >= '0' && character <= '9') || character == '_' || character == '-')) {
            return 0;
        }
    }
    return 1;
}

int paired_data_path(char *path, size_t capacity, const char *directory, const char *filename)
{
    if (*filename == '\0' || *filename == '.' || strlen(filename) > 192u) {
        return 1;
    }
    for (const char *character = filename; *character != '\0'; ++character) {
        if (!((*character >= 'a' && *character <= 'z') ||
                (*character >= 'A' && *character <= 'Z') ||
                (*character >= '0' && *character <= '9') || *character == '_' ||
                *character == '-' || *character == '.')) {
            return 1;
        }
    }
    int path_bytes = snprintf(path, capacity, "%s/%s", directory, filename);
    return path_bytes < 0 || (size_t)path_bytes >= capacity;
}

int read_paired_fields(const char *path, struct paired_text_field *fields, size_t field_count)
{
    FILE *input_file = fopen(path, "r");
    char line[4096];
    if (input_file == NULL) {
        return 1;
    }
    int operation_status = 0;
    for (size_t field_index = 0; field_index < field_count; ++field_index) {
        fields[field_index].found = 0;
    }
    while (fgets(line, sizeof(line), input_file) != NULL) {
        size_t line_bytes = strlen(line);
        if (line_bytes == 0 || line[line_bytes - 1u] != '\n') {
            operation_status = 1;
            break;
        }
        line[line_bytes - 1u] = '\0';
        char *separator = strchr(line, '=');
        if (separator == NULL) {
            continue;
        }
        *separator = '\0';
        for (size_t field_index = 0; field_index < field_count; ++field_index) {
            struct paired_text_field *field = &fields[field_index];
            if (strcmp(field->name, line) == 0) {
                size_t value_bytes = strlen(separator + 1);
                if (field->found || value_bytes == 0 || value_bytes >= field->capacity) {
                    operation_status = 1;
                } else {
                    memcpy(field->value, separator + 1, value_bytes + 1u);
                    field->found = 1;
                }
            }
        }
    }
    for (size_t field_index = 0; field_index < field_count; ++field_index) {
        if (!fields[field_index].found) {
            operation_status = 1;
        }
    }
    if (ferror(input_file)) {
        operation_status = 1;
    }
    if (fclose(input_file) != 0) {
        operation_status = 1;
    }
    return operation_status;
}

int split_paired_csv(char *line, char **fields, size_t field_count)
{
    size_t line_bytes = strlen(line);
    if (line_bytes == 0 || line[line_bytes - 1u] != '\n') {
        return 1;
    }
    line[line_bytes - 1u] = '\0';
    fields[0] = line;
    for (size_t field_index = 0; field_index < field_count; ++field_index) {
        char *separator = strchr(fields[field_index], ',');
        if ((field_index + 1u < field_count) != (separator != NULL)) {
            return 1;
        }
        if (separator != NULL) {
            *separator = '\0';
            fields[field_index + 1u] = separator + 1;
        }
        if (*fields[field_index] == '\0') {
            return 1;
        }
    }
    return 0;
}

int paired_digest_file(const char *path, char digest[65])
{
    uint8_t digest_bytes[32];
    if (hash_csv_file(path, digest_bytes) != 0) {
        return 1;
    }
    for (size_t byte_index = 0; byte_index < 32u; ++byte_index) {
        (void)snprintf(digest + 2u * byte_index, 3, "%02x", digest_bytes[byte_index]);
    }
    return 0;
}

static int add_checked(uint64_t *total, uint64_t value)
{
    if (*total > UINT64_MAX - value) {
        return 1;
    }
    *total += value;
    return 0;
}

static int load_batch_csv(const char *csv_path, struct paired_run *run)
{
    static const char header[] = "run_id,block_id,method,window_index,input_start,input_end,"
                                 "call_count,valid_count,bit_flipped_count,random_count,elapsed_"
                                 "nanoseconds,time_unit,status\n";
    FILE *csv_file = fopen(csv_path, "r");
    char line[1024];
    uint64_t input_count = 0;
    uint64_t category_totals[3] = {0};
    int operation_status = 1;
    if (csv_file == NULL) {
        return 1;
    }
    run->batch_records = calloc((size_t)run->call_count, sizeof(*run->batch_records));
    if (run->batch_records == NULL || fgets(line, sizeof(line), csv_file) == NULL ||
        strcmp(line, header) != 0) {
        goto cleanup;
    }
    while (fgets(line, sizeof(line), csv_file) != NULL) {
        char *fields[13];
        uint64_t numbers[8];
        if (run->window_count >= run->call_count || split_paired_csv(line, fields, 13) != 0 ||
            strcmp(fields[0], run->run_id) != 0 || strcmp(fields[1], run->run_id) != 0 ||
            strcmp(fields[2], "candidate") != 0 || strcmp(fields[11], "ns") != 0 ||
            strcmp(fields[12], "complete") != 0) {
            goto cleanup;
        }
        for (size_t number_index = 0; number_index < 8u; ++number_index) {
            if (parse_unsigned_integer(fields[number_index + 3u], &numbers[number_index]) != 0) {
                goto cleanup;
            }
        }
        uint64_t expected_calls = run->call_count - input_count < run->batch_size
            ? run->call_count - input_count
            : run->batch_size;
        if (numbers[0] != run->window_count || numbers[1] != input_count ||
            numbers[3] != expected_calls || expected_calls == 0 ||
            numbers[2] != input_count + expected_calls || numbers[7] == 0 ||
            numbers[4] > expected_calls || numbers[5] > expected_calls ||
            numbers[6] > expected_calls || numbers[4] + numbers[5] + numbers[6] != expected_calls ||
            add_checked(&run->total_nanoseconds, numbers[7]) != 0) {
            goto cleanup;
        }
        struct batch_record *record = &run->batch_records[run->window_count++];
        record->first_input_index = input_count;
        record->call_count = expected_calls;
        record->elapsed_nanoseconds = numbers[7];
        for (size_t category_index = 0; category_index < 3u; ++category_index) {
            record->category_counts[category_index] = numbers[4u + category_index];
            category_totals[category_index] += numbers[4u + category_index];
        }
        input_count += expected_calls;
    }
    if (input_count == run->call_count && category_totals[0] == run->call_count / 3u &&
        category_totals[1] == run->call_count / 3u && category_totals[2] == run->call_count / 3u &&
        !ferror(csv_file)) {
        operation_status = 0;
    }
cleanup:
    if (fclose(csv_file) != 0) {
        operation_status = 1;
    }
    return operation_status;
}

static int load_cost(const char *csv_path, struct paired_run *run)
{
    static const char *const names[] = {"cost_format",
        "final_state",
        "start_ns",
        "preparation_end_ns",
        "warmup_end_ns",
        "collection_end_ns",
        "finish_ns",
        "child_total_wall_ns",
        "warmup_attempted_calls",
        "warmup_completed_calls",
        "formal_attempted_calls",
        "formal_completed_calls",
        "outputs_consumed"};
    char values[13][128];
    struct paired_text_field fields[13];
    char cost_path[4096];
    int path_bytes = snprintf(cost_path, sizeof(cost_path), "%s.cost", csv_path);
    if (path_bytes < 0 || (size_t)path_bytes >= sizeof(cost_path)) {
        return 1;
    }
    for (size_t field_index = 0; field_index < 13u; ++field_index) {
        fields[field_index] =
            (struct paired_text_field){names[field_index], values[field_index], 128, 0};
    }
    if (read_paired_fields(cost_path, fields, 13) != 0 ||
        strcmp(values[0], "measurement_cost_v1") != 0 || strcmp(values[1], "complete") != 0) {
        return 1;
    }
    uint64_t numbers[11];
    for (size_t number_index = 0; number_index < 11u; ++number_index) {
        if (parse_unsigned_integer(values[number_index + 2u], &numbers[number_index]) != 0) {
            return 1;
        }
    }
    if (numbers[0] == 0 || numbers[1] < numbers[0] || numbers[2] < numbers[1] ||
        numbers[3] < numbers[2] || numbers[4] < numbers[3] ||
        numbers[5] != numbers[4] - numbers[0] || numbers[5] < run->total_nanoseconds ||
        numbers[3] - numbers[2] < run->total_nanoseconds || numbers[6] != 100u ||
        numbers[7] != 100u || numbers[8] != run->call_count || numbers[9] != run->call_count ||
        numbers[10] != run->call_count + 100u) {
        return 1;
    }
    run->child_wall_nanoseconds = numbers[5];
    run->child_start_nanoseconds = numbers[0];
    run->child_finish_nanoseconds = numbers[4];
    run->warmup_calls = numbers[7];
    return 0;
}

int load_paired_run(const char *csv_path, const char *metadata_path, struct paired_run *run)
{
    static const char *const names[] = {"run_id",
        "method",
        "ordered_input_digest",
        "executable_digest",
        "source_commit",
        "compiler_flags",
        "compile_options",
        "architecture",
        "os",
        "sanitizers",
        "test_seed",
        "sample_count",
        "batch_size",
        "formal_attempted_calls",
        "formal_completed_calls",
        "outputs_consumed",
        "warmup_attempted_calls",
        "warmup_completed_calls",
        "valid_count",
        "bit_flipped_count",
        "random_count",
        "run_status",
        "paired_metadata_version",
        "parameter_set",
        "input_rule",
        "upstream_commit",
        "measurement_format",
        "clock",
        "time_unit"};
    char values[29][PAIRED_TEXT_CAPACITY];
    struct paired_text_field fields[29];
    memset(run, 0, sizeof(*run));
    for (size_t field_index = 0; field_index < 29u; ++field_index) {
        fields[field_index] = (struct paired_text_field){names[field_index],
            values[field_index],
            PAIRED_TEXT_CAPACITY,
            0};
    }
    if (read_paired_fields(metadata_path, fields, 29) != 0 || !is_paired_identifier(values[0]) ||
        (strcmp(values[1], "baseline") != 0 && strcmp(values[1], "candidate") != 0) ||
        !is_paired_hex(values[2], 64) || !is_paired_hex(values[3], 64) ||
        !is_paired_hex(values[4], 40) || strcmp(values[21], "complete") != 0 ||
        strcmp(values[22], "paired_workload_v1") != 0 || strcmp(values[23], "ML-KEM-768") != 0 ||
        strcmp(values[24], "ordinary_input_stream_v1") != 0 ||
        strcmp(values[25], "b3ba7b32773e657dd37f6f87bce82528459ad8a4") != 0 ||
        strcmp(values[27], "CLOCK_MONOTONIC") != 0 || strcmp(values[28], "ns") != 0) {
        return 1;
    }
    uint64_t numbers[11];
    for (size_t number_index = 0; number_index < 11u; ++number_index) {
        if (parse_unsigned_integer(values[number_index + 10u], &numbers[number_index]) != 0) {
            return 1;
        }
    }
    if (numbers[1] == 0 || numbers[1] > PAIRED_MAXIMUM_CALLS || numbers[1] % 3u != 0 ||
        (numbers[2] != 1u && numbers[2] != 4u && numbers[2] != 16u) || numbers[3] != numbers[1] ||
        numbers[4] != numbers[1] || numbers[5] != numbers[1] + 100u || numbers[6] != 100u ||
        numbers[7] != 100u || numbers[8] != numbers[1] / 3u || numbers[9] != numbers[1] / 3u ||
        numbers[10] != numbers[1] / 3u) {
        return 1;
    }
    if (strlen(values[7]) >= sizeof(run->architecture) ||
        strlen(values[8]) >= sizeof(run->operating_system) ||
        strlen(values[9]) >= sizeof(run->sanitizers)) {
        return 1;
    }
    memcpy(run->run_id, values[0], strlen(values[0]) + 1u);
    memcpy(run->method, values[1], strlen(values[1]) + 1u);
    memcpy(run->ordered_input_digest, values[2], strlen(values[2]) + 1u);
    memcpy(run->executable_digest, values[3], strlen(values[3]) + 1u);
    memcpy(run->source_commit, values[4], strlen(values[4]) + 1u);
    memcpy(run->compiler_flags, values[5], strlen(values[5]) + 1u);
    memcpy(run->compile_options, values[6], strlen(values[6]) + 1u);
    memcpy(run->architecture, values[7], strlen(values[7]) + 1u);
    memcpy(run->operating_system, values[8], strlen(values[8]) + 1u);
    memcpy(run->sanitizers, values[9], strlen(values[9]) + 1u);
    run->test_seed = numbers[0];
    run->call_count = numbers[1];
    run->batch_size = numbers[2];
    if (strcmp(run->method, "baseline") == 0) {
        if (run->batch_size != 1u || strcmp(values[26], "reference_ordinary_v1") != 0 ||
            load_measurement_set(csv_path, &run->baseline_sequence) != 0 ||
            strcmp(run->baseline_sequence.run_id, run->run_id) != 0 ||
            strcmp(run->baseline_sequence.implementation, "reference") != 0 ||
            run->baseline_sequence.record_count != run->call_count) {
            return 1;
        }
        uint64_t category_counts[3] = {0};
        for (size_t record_index = 0; record_index < run->baseline_sequence.record_count;
            ++record_index) {
            const struct measurement_record *record = &run->baseline_sequence.records[record_index];
            if (record->category_index >= 3u ||
                add_checked(&run->total_nanoseconds, record->elapsed_nanoseconds) != 0) {
                return 1;
            }
            ++category_counts[record->category_index];
        }
        if (category_counts[0] != run->call_count / 3u ||
            category_counts[1] != run->call_count / 3u ||
            category_counts[2] != run->call_count / 3u) {
            return 1;
        }
        run->window_count = run->baseline_sequence.record_count;
    } else if (strcmp(values[26], "reference_batch_v1") != 0 ||
        load_batch_csv(csv_path, run) != 0) {
        return 1;
    }
    return load_cost(csv_path, run);
}

int validate_paired_runs(const struct paired_run *baseline, const struct paired_run *candidate)
{
    if (strcmp(baseline->method, "baseline") != 0 || strcmp(candidate->method, "candidate") != 0 ||
        strcmp(baseline->run_id, candidate->run_id) != 0 ||
        baseline->test_seed != candidate->test_seed ||
        baseline->call_count != candidate->call_count ||
        strcmp(baseline->ordered_input_digest, candidate->ordered_input_digest) != 0 ||
        strcmp(baseline->source_commit, candidate->source_commit) != 0 ||
        strcmp(baseline->compiler_flags, candidate->compiler_flags) != 0 ||
        strcmp(baseline->compile_options, candidate->compile_options) != 0 ||
        strcmp(baseline->architecture, candidate->architecture) != 0 ||
        strcmp(baseline->operating_system, candidate->operating_system) != 0 ||
        strcmp(baseline->sanitizers, candidate->sanitizers) != 0) {
        return 1;
    }
    for (size_t window_index = 0; window_index < candidate->window_count; ++window_index) {
        const struct batch_record *window = &candidate->batch_records[window_index];
        uint64_t expected_categories[3] = {0};
        for (uint64_t call_index = 0; call_index < window->call_count; ++call_index) {
            unsigned category_index =
                baseline->baseline_sequence.records[window->first_input_index + call_index]
                    .category_index;
            ++expected_categories[category_index];
        }
        for (size_t category_index = 0; category_index < 3u; ++category_index) {
            if (expected_categories[category_index] != window->category_counts[category_index]) {
                return 1;
            }
        }
    }
    return 0;
}

void release_paired_run(struct paired_run *run)
{
    free(run->baseline_sequence.records);
    free(run->batch_records);
    memset(run, 0, sizeof(*run));
}
