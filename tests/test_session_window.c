#define _POSIX_C_SOURCE 200809L

#include "inputs.h"

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/wait.h>
#include <unistd.h>

static int window_is_decapsulation_only(const char *source_text)
{
    const char *function_start = strstr(source_text, "static int time_one_decapsulation");
    const char *function_end;
    const char *forbidden[] = {"generate_", "fopen", "fprintf", "fwrite", "printf", "fputs", "csv"};
    if (function_start == NULL) {
        return 1;
    }
    function_end = strstr(function_start, "\nstatic int time_empty_window");
    if (function_end == NULL || strstr(function_start, "mlkem_decapsulate") == NULL ||
        strstr(function_start, "mlkem_decapsulate") > function_end) {
        return 1;
    }
    for (size_t forbidden_index = 0; forbidden_index < sizeof(forbidden) / sizeof(forbidden[0]);
        ++forbidden_index) {
        const char *found = strstr(function_start, forbidden[forbidden_index]);
        if (found != NULL && found < function_end) {
            return 1;
        }
    }
    return 0;
}

static int field_count(char *line)
{
    int count = 1;
    if (line == NULL || line[0] == '\0') {
        return 0;
    }
    for (char *cursor = line; *cursor != '\0'; ++cursor) {
        if (*cursor == ',') {
            count += 1;
        }
    }
    return count;
}

int main(int argc, char **argv)
{
    const char *temp_root = getenv("A113_TEST_TMPDIR");
    char source_path[512];
    char csv_path[512];
    char meta_path[512];
    char empty_path[512];
    char command[2048];
    FILE *source_file;
    FILE *csv_file;
    FILE *meta_file;
    FILE *empty_file;
    char *source_text;
    long source_bytes;
    char line[2048];
    size_t data_rows = 0u;
    size_t empty_rows = 0u;
    int saw_resolution = 0;
    int saw_not_physical = 0;
    int saw_repeat = 0;
    int saw_generator = 0;
    int status;
    if (argc != 3 || temp_root == NULL || temp_root[0] != '/') {
        return 1;
    }
    if (snprintf(source_path, sizeof(source_path), "%s", argv[2]) >= (int)sizeof(source_path) ||
        snprintf(csv_path, sizeof(csv_path), "%s/session-window.csv", temp_root) >=
            (int)sizeof(csv_path) ||
        snprintf(meta_path, sizeof(meta_path), "%s/session-window.meta", temp_root) >=
            (int)sizeof(meta_path) ||
        snprintf(empty_path, sizeof(empty_path), "%s/session-window.empty", temp_root) >=
            (int)sizeof(empty_path)) {
        return 1;
    }
    (void)remove(csv_path);
    (void)remove(meta_path);
    (void)remove(empty_path);
    source_file = fopen(source_path, "rb");
    if (source_file == NULL || fseek(source_file, 0, SEEK_END) != 0) {
        return 1;
    }
    source_bytes = ftell(source_file);
    if (source_bytes <= 0 || source_bytes > 2000000) {
        return 1;
    }
    if (fseek(source_file, 0, SEEK_SET) != 0) {
        return 1;
    }
    source_text = calloc((size_t)source_bytes + 1u, 1u);
    if (source_text == NULL ||
        fread(source_text, 1, (size_t)source_bytes, source_file) != (size_t)source_bytes) {
        return 1;
    }
    (void)fclose(source_file);
    if (window_is_decapsulation_only(source_text) != 0) {
        free(source_text);
        return 1;
    }
    free(source_text);
    if (snprintf(command,
            sizeof(command),
            "'%s' window-run session-1 key-7 31337 4 2 '%s' '%s' '%s'",
            argv[1],
            csv_path,
            meta_path,
            empty_path) >= (int)sizeof(command)) {
        return 1;
    }
    status = system(command);
    if (status != 0) {
        return 1;
    }
    csv_file = fopen(csv_path, "r");
    if (csv_file == NULL || fgets(line, sizeof(line), csv_file) == NULL) {
        return 1;
    }
    if (strcmp(line,
            "schema,run_id,session_id,block_id,key_id,sample_index,predecessor_category,"
            "category,generator_label,elapsed_clock_counts,clock_path,"
            "ciphertext_sha256_hex\n") != 0) {
        return 1;
    }
    while (fgets(line, sizeof(line), csv_file) != NULL) {
        if (field_count(line) != 12 || strstr(line, "session_decapsulation_v1,") != line ||
            strstr(line, ",session-1,") == NULL || strstr(line, ",key-7,") == NULL ||
            strstr(line, ",CLOCK_MONOTONIC,") == NULL ||
            strstr(line, "generate_test_ciphertext:") == NULL) {
            return 1;
        }
        saw_generator = 1;
        data_rows += 1u;
    }
    (void)fclose(csv_file);
    if (data_rows != 20u || !saw_generator) {
        return 1;
    }
    meta_file = fopen(meta_path, "r");
    if (meta_file == NULL) {
        return 1;
    }
    while (fgets(line, sizeof(line), meta_file) != NULL) {
        if (strncmp(line, "resolution_counts=", 18) == 0) {
            saw_resolution = 1;
        }
        if (strcmp(line, "physical_nanosecond_accuracy=not_claimed\n") == 0) {
            saw_not_physical = 1;
        }
        if (strcmp(line, "message-zero_unique_ciphertexts=1\n") == 0 ||
            strcmp(line, "message-ones_unique_ciphertexts=1\n") == 0 ||
            strcmp(line, "message-zero_repeat_numerator=3\n") == 0 ||
            strcmp(line, "message-ones_repeat_denominator=4\n") == 0) {
            saw_repeat += 1;
        }
    }
    (void)fclose(meta_file);
    empty_file = fopen(empty_path, "r");
    if (empty_file == NULL || fgets(line, sizeof(line), empty_file) == NULL) {
        return 1;
    }
    while (fgets(line, sizeof(line), empty_file) != NULL) {
        empty_rows += 1u;
    }
    (void)fclose(empty_file);
    if (!saw_resolution || !saw_not_physical || saw_repeat != 4 || empty_rows != 256u) {
        return 1;
    }
    return 0;
}
