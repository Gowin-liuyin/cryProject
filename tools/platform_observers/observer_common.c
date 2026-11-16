#define _POSIX_C_SOURCE 200809L
#define _GNU_SOURCE

#include "observer_common.h"

#include "sync_flag.h"

#include <errno.h>
#include <sched.h>
#include <stdarg.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>
#include <unistd.h>

int observer_take_value(int argument_count,
    char **argument_values,
    int *argument_index,
    const char *name,
    const char **value)
{
    const char *argument = argument_values[*argument_index];
    size_t name_bytes = strlen(name);
    if (strncmp(argument, name, name_bytes) != 0) {
        return 1;
    }
    if (argument[name_bytes] == '=') {
        *value = argument + name_bytes + 1u;
        return 0;
    }
    if (argument[name_bytes] != '\0') {
        return 1;
    }
    if (*argument_index + 1 >= argument_count) {
        return 2;
    }
    ++(*argument_index);
    *value = argument_values[*argument_index];
    return 0;
}

int observer_parse_unsigned(const char *text,
    unsigned long long minimum,
    unsigned long long maximum,
    unsigned long long *value)
{
    if (text == NULL || text[0] == '\0') {
        return 1;
    }
    for (const char *cursor = text; *cursor != '\0'; ++cursor) {
        if (*cursor < '0' || *cursor > '9') {
            return 1;
        }
    }
    errno = 0;
    char *end = NULL;
    unsigned long long parsed_value = strtoull(text, &end, 10);
    if (errno != 0 || end == text || *end != '\0' || parsed_value < minimum ||
        parsed_value > maximum) {
        return 1;
    }
    *value = parsed_value;
    return 0;
}

uint64_t observer_now_nanoseconds(void)
{
    struct timespec current_time;
    if (clock_gettime(CLOCK_MONOTONIC_RAW, &current_time) != 0) {
        return 0u;
    }
    return (uint64_t)current_time.tv_sec * 1000000000ull + (uint64_t)current_time.tv_nsec;
}

int observer_bind_cpu(unsigned cpu_index)
{
    if (cpu_index >= (unsigned)CPU_SETSIZE) {
        return -1;
    }
    cpu_set_t cpu_set;
    CPU_ZERO(&cpu_set);
    /* glibc 的 CPU_SET 宏在 -Wconversion 下会产生 int/size_t 符号转换告警；
     * 这里只对宏展开做局部抑制，CPU 编号本身已在调用方约束为 0..4095。 */
#pragma GCC diagnostic push
#pragma GCC diagnostic ignored "-Wsign-conversion"
    CPU_SET((int)cpu_index, &cpu_set);
#pragma GCC diagnostic pop
    return sched_setaffinity(0, sizeof(cpu_set), &cpu_set);
}

int observer_append_text(char *buffer, size_t capacity, size_t *used, const char *format, ...)
{
    if (*used >= capacity) {
        return 1;
    }
    va_list arguments;
    va_start(arguments, format);
    int written = vsnprintf(buffer + *used, capacity - *used, format, arguments);
    va_end(arguments);
    if (written < 0 || (size_t)written >= capacity - *used) {
        return 1;
    }
    *used += (size_t)written;
    return 0;
}

int observer_write_text(const char *path, const char *text)
{
    FILE *output_stream = fopen(path, "w");
    if (output_stream == NULL) {
        fprintf(stderr, "error: cannot create %s: %s\n", path, strerror(errno));
        return 1;
    }
    size_t text_bytes = strlen(text);
    int status = 0;
    if (fwrite(text, 1u, text_bytes, output_stream) != text_bytes) {
        fprintf(stderr, "error: cannot write %s\n", path);
        status = 1;
    }
    if (fclose(output_stream) != 0) {
        fprintf(stderr, "error: cannot close %s\n", path);
        status = 1;
    }
    return status;
}

int observer_self_check_output_path(char *buffer, size_t capacity, const char *file_name)
{
    const char *temporary_root = getenv("A113_TEST_TMPDIR");
    if (temporary_root == NULL || temporary_root[0] == '\0') {
        fprintf(stderr, "error: A113_TEST_TMPDIR is required for observer self-check\n");
        return -1;
    }
    int written = snprintf(buffer,
        capacity,
        "%s/observer-%s-%ld.csv",
        temporary_root,
        file_name,
        (long)getpid());
    if (written < 0 || (size_t)written >= capacity) {
        fprintf(stderr, "error: self-check path too long\n");
        return -1;
    }
    return 0;
}

int observer_validate_csv(const char *path, const char *expected_header, unsigned expected_rows)
{
    FILE *input_stream = fopen(path, "r");
    if (input_stream == NULL) {
        fprintf(stderr, "error: cannot read self-check CSV %s\n", path);
        return 1;
    }
    char line[1024];
    if (fgets(line, (int)sizeof(line), input_stream) == NULL) {
        fprintf(stderr, "error: self-check CSV is empty\n");
        (void)fclose(input_stream);
        return 1;
    }
    size_t header_bytes = strlen(line);
    if (header_bytes > 0u && line[header_bytes - 1u] == '\n') {
        line[header_bytes - 1u] = '\0';
    }
    if (strcmp(line, expected_header) != 0) {
        fprintf(stderr, "error: unexpected self-check header: %s\n", line);
        (void)fclose(input_stream);
        return 1;
    }
    size_t header_field_count = 1u;
    for (const char *cursor = line; *cursor != '\0'; ++cursor) {
        if (*cursor == ',') {
            ++header_field_count;
        }
    }
    unsigned row_count = 0u;
    int status = 0;
    while (fgets(line, (int)sizeof(line), input_stream) != NULL) {
        size_t line_bytes = strlen(line);
        if (line_bytes > 0u && line[line_bytes - 1u] == '\n') {
            line[line_bytes - 1u] = '\0';
        }
        size_t field_count = 1u;
        for (const char *cursor = line; *cursor != '\0'; ++cursor) {
            if (*cursor == ',') {
                ++field_count;
            }
        }
        if (field_count != header_field_count) {
            fprintf(stderr, "error: self-check row %u has %zu fields\n", row_count, field_count);
            status = 1;
            break;
        }
        ++row_count;
    }
    (void)fclose(input_stream);
    if (status == 0 && row_count != expected_rows) {
        fprintf(stderr,
            "error: self-check CSV has %u rows, expected %u\n",
            row_count,
            expected_rows);
        status = 1;
    }
    return status;
}

int observer_wait_sequence(struct sync_flag *flag, uint64_t target_sequence)
{
    for (;;) {
        if (sync_flag_current_sequence(flag) >= target_sequence) {
            return 0;
        }
        if (sync_flag_wait_turn(flag) != 0) {
            return -1;
        }
    }
}
