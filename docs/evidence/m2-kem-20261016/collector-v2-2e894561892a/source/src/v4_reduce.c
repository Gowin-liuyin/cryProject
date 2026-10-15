#include "v4_reduce.h"

#include "v4_stats.h"

#include <math.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#define V4_RAW_LINE 2048u
#define V4_RAW_MAX_ROWS (V4_KEY_COUNT * 8u * 4u)
#define V4_RAW_MAX_REPEATS 8u

int sha256_bytes(const uint8_t *bytes, size_t byte_count, char hex_out[65]);

struct v4_raw_call {
    unsigned key_index;
    unsigned repeat_index;
    unsigned slot_index;
    int message_zero;
    uint64_t elapsed_counts;
    char ciphertext_sha256_hex[65];
};

struct v4_hash_count {
    char hex[65];
    unsigned count;
};

static int join_path(char *destination, size_t capacity, const char *directory, const char *name)
{
    return snprintf(destination, capacity, "%s/%s", directory, name) >= (int)capacity;
}

static int meta_value(const char *path, const char *key, char *output, size_t capacity)
{
    FILE *file = fopen(path, "r");
    char line[V4_RAW_LINE];
    size_t key_length = strlen(key);
    if (file == NULL) {
        return 1;
    }
    while (fgets(line, sizeof(line), file) != NULL) {
        if (strncmp(line, key, key_length) == 0 && line[key_length] == '=') {
            char *value = line + key_length + 1u;
            size_t length;
            value[strcspn(value, "\r\n")] = '\0';
            length = strlen(value);
            if (length + 1u > capacity) {
                (void)fclose(file);
                return 1;
            }
            memcpy(output, value, length + 1u);
            return fclose(file) == 0 ? 0 : 1;
        }
    }
    (void)fclose(file);
    return 1;
}

static int hex_is_sha256(const char *text)
{
    if (strlen(text) != 64u) {
        return 0;
    }
    for (size_t index = 0; index < 64u; ++index) {
        char character = text[index];
        if (!((character >= '0' && character <= '9') || (character >= 'a' && character <= 'f'))) {
            return 0;
        }
    }
    return 1;
}

static int split_ten_fields(char *line, char **fields)
{
    size_t count = 1u;
    line[strcspn(line, "\r\n")] = '\0';
    fields[0] = line;
    for (char *cursor = line; *cursor != '\0'; ++cursor) {
        if (*cursor == ',') {
            if (count >= 10u) {
                return 1;
            }
            *cursor = '\0';
            fields[count] = cursor + 1;
            count += 1u;
        }
    }
    return count == 10u ? 0 : 1;
}

static int parse_bounded_unsigned(const char *text, unsigned limit, unsigned *value)
{
    char *end = NULL;
    unsigned long parsed;
    if (text == NULL || text[0] == '\0') {
        return 1;
    }
    parsed = strtoul(text, &end, 10);
    if (end == text || *end != '\0' || parsed >= (unsigned long)limit) {
        return 1;
    }
    *value = (unsigned)parsed;
    return 0;
}

static int note_hash(struct v4_hash_count *hashes, unsigned *unique_count, const char *hex)
{
    for (unsigned index = 0; index < *unique_count; ++index) {
        if (strcmp(hashes[index].hex, hex) == 0) {
            hashes[index].count += 1u;
            return 0;
        }
    }
    if (*unique_count >= V4_KEY_COUNT) {
        return 1;
    }
    memcpy(hashes[*unique_count].hex, hex, 65u);
    hashes[*unique_count].count = 1u;
    *unique_count += 1u;
    return 0;
}

static int counts_are_equal(const struct v4_hash_count *hashes, unsigned unique_count)
{
    if (unique_count != V4_KEY_COUNT || hashes[0].count == 0u) {
        return 0;
    }
    for (unsigned index = 1u; index < unique_count; ++index) {
        if (hashes[index].count != hashes[0].count) {
            return 0;
        }
    }
    return 1;
}

static int
slot_matches_abba(unsigned key_index, unsigned repeat_index, unsigned slot_index, int message_zero)
{
    int zero_slot = slot_index == 0u || slot_index == 3u;
    if (((key_index + repeat_index) % 2u) != 0u) {
        zero_slot = !zero_slot;
    }
    return message_zero == zero_slot;
}

static int reduce_one_session(const char *session_directory,
    int require_binary_digest,
    int require_coverage,
    double *effect_counts,
    double *empty_median_counts,
    double *coverage_fraction,
    const char **stop_status)
{
    char calls_path[768];
    char empty_path[768];
    char meta_path[768];
    char coverage_path[768];
    char binary_path[768];
    char repeat_text[32];
    char key_count_text[32];
    char input_sha256[80];
    char executable_sha256[80];
    char computed_sha256[65];
    char line[V4_RAW_LINE];
    unsigned repeat_count = 0u;
    unsigned key_count = 0u;
    unsigned char slot_seen[V4_KEY_COUNT][V4_RAW_MAX_REPEATS][4];
    struct v4_hash_count zero_hashes[V4_KEY_COUNT];
    struct v4_hash_count ones_hashes[V4_KEY_COUNT];
    unsigned zero_unique = 0u;
    unsigned ones_unique = 0u;
    double zero_sum = 0.0;
    double ones_sum = 0.0;
    unsigned zero_calls = 0u;
    unsigned ones_calls = 0u;
    struct v4_raw_call *calls = NULL;
    uint8_t *schedule_bytes = NULL;
    size_t call_count = 0u;
    size_t expected_calls;
    FILE *file;
    int failed = 0;
    *stop_status = NULL;
    memset(slot_seen, 0, sizeof(slot_seen));
    if (join_path(calls_path, sizeof(calls_path), session_directory, "calls.csv") != 0 ||
        join_path(empty_path, sizeof(empty_path), session_directory, "empty.csv") != 0 ||
        join_path(meta_path, sizeof(meta_path), session_directory, "meta.txt") != 0 ||
        join_path(coverage_path, sizeof(coverage_path), session_directory, "coverage.txt") != 0 ||
        join_path(binary_path, sizeof(binary_path), session_directory, "binary.sha256") != 0 ||
        meta_value(meta_path, "repeat_count", repeat_text, sizeof(repeat_text)) != 0 ||
        meta_value(meta_path, "key_count", key_count_text, sizeof(key_count_text)) != 0 ||
        meta_value(meta_path, "input_sha256", input_sha256, sizeof(input_sha256)) != 0 ||
        meta_value(meta_path, "executable_sha256", executable_sha256, sizeof(executable_sha256)) !=
            0 ||
        parse_bounded_unsigned(repeat_text, V4_RAW_MAX_REPEATS + 1u, &repeat_count) != 0 ||
        parse_bounded_unsigned(key_count_text, V4_KEY_COUNT + 1u, &key_count) != 0 ||
        repeat_count == 0u || key_count != V4_KEY_COUNT || !hex_is_sha256(input_sha256)) {
        *stop_status = "stopped_incomplete_session";
        return 0;
    }
    expected_calls = (size_t)V4_KEY_COUNT * (size_t)repeat_count * 4u;
    calls = calloc(expected_calls, sizeof(*calls));
    file = fopen(calls_path, "r");
    if (calls == NULL || file == NULL || fgets(line, sizeof(line), file) == NULL ||
        strstr(line, "ciphertext_sha256_hex") == NULL) {
        failed = 1;
        *stop_status = "stopped_incomplete_session";
    }
    while (!failed && fgets(line, sizeof(line), file) != NULL) {
        char *fields[10];
        unsigned key_index = 0u;
        unsigned repeat_index = 0u;
        unsigned slot_index = 0u;
        char *elapsed_end = NULL;
        int message_zero;
        if (line[0] == '\n' || line[0] == '\0') {
            continue;
        }
        if (call_count >= expected_calls || split_ten_fields(line, fields) != 0 ||
            strcmp(fields[0], "v4_group_session_v1") != 0 ||
            parse_bounded_unsigned(fields[3], V4_KEY_COUNT, &key_index) != 0 ||
            parse_bounded_unsigned(fields[4], repeat_count, &repeat_index) != 0 ||
            parse_bounded_unsigned(fields[5], 4u, &slot_index) != 0 ||
            strcmp(fields[8], "CLOCK_MONOTONIC") != 0 || !hex_is_sha256(fields[9])) {
            failed = 1;
            *stop_status = "stopped_input_digest";
            break;
        }
        if (strcmp(fields[6], "message-zero") == 0) {
            message_zero = 1;
        } else if (strcmp(fields[6], "message-ones") == 0) {
            message_zero = 0;
        } else {
            failed = 1;
            *stop_status = "stopped_input_digest";
            break;
        }
        if (!slot_matches_abba(key_index, repeat_index, slot_index, message_zero) ||
            slot_seen[key_index][repeat_index][slot_index] != 0u) {
            failed = 1;
            *stop_status = "stopped_input_digest";
            break;
        }
        slot_seen[key_index][repeat_index][slot_index] = 1u;
        calls[call_count].key_index = key_index;
        calls[call_count].repeat_index = repeat_index;
        calls[call_count].slot_index = slot_index;
        calls[call_count].message_zero = message_zero;
        calls[call_count].elapsed_counts = strtoull(fields[7], &elapsed_end, 10);
        if (elapsed_end == fields[7] || *elapsed_end != '\0') {
            failed = 1;
            *stop_status = "stopped_incomplete_session";
            break;
        }
        memcpy(calls[call_count].ciphertext_sha256_hex, fields[9], 65u);
        call_count += 1u;
    }
    if (file != NULL && (ferror(file) || fclose(file) != 0)) {
        failed = 1;
        *stop_status = "stopped_incomplete_session";
    }
    if (!failed && call_count != expected_calls) {
        failed = 1;
        *stop_status = "stopped_incomplete_session";
    }
    if (!failed) {
        for (unsigned key_index = 0; key_index < V4_KEY_COUNT; ++key_index) {
            for (unsigned repeat_index = 0; repeat_index < repeat_count; ++repeat_index) {
                for (unsigned slot_index = 0; slot_index < 4u; ++slot_index) {
                    if (slot_seen[key_index][repeat_index][slot_index] == 0u) {
                        failed = 1;
                        *stop_status = "stopped_incomplete_session";
                    }
                }
            }
        }
    }
    schedule_bytes = failed ? NULL : malloc(call_count * 64u);
    if (!failed && schedule_bytes == NULL) {
        failed = 1;
        *stop_status = "stopped_incomplete_session";
    }
    if (!failed) {
        for (size_t index = 0; index < call_count; ++index) {
            memcpy(schedule_bytes + index * 64u, calls[index].ciphertext_sha256_hex, 64u);
            if (calls[index].message_zero) {
                zero_sum += (double)calls[index].elapsed_counts;
                zero_calls += 1u;
                if (note_hash(zero_hashes, &zero_unique, calls[index].ciphertext_sha256_hex) != 0) {
                    failed = 1;
                    *stop_status = "stopped_ciphertext_collision";
                }
            } else {
                ones_sum += (double)calls[index].elapsed_counts;
                ones_calls += 1u;
                if (note_hash(ones_hashes, &ones_unique, calls[index].ciphertext_sha256_hex) != 0) {
                    failed = 1;
                    *stop_status = "stopped_ciphertext_collision";
                }
            }
        }
    }
    if (!failed &&
        (sha256_bytes(schedule_bytes, call_count * 64u, computed_sha256) != 0 ||
            strcmp(computed_sha256, input_sha256) != 0)) {
        failed = 1;
        *stop_status = "stopped_input_digest";
    }
    if (!failed &&
        (!counts_are_equal(zero_hashes, zero_unique) ||
            !counts_are_equal(ones_hashes, ones_unique) || zero_calls != ones_calls ||
            zero_calls == 0u)) {
        failed = 1;
        *stop_status = "stopped_ciphertext_collision";
    }
    if (!failed) {
        FILE *binary_file = fopen(binary_path, "r");
        char recorded[80];
        if (binary_file == NULL) {
            if (require_binary_digest) {
                failed = 1;
                *stop_status = "stopped_binary_digest";
            }
        } else if (fgets(recorded, sizeof(recorded), binary_file) == NULL) {
            failed = 1;
            *stop_status = "stopped_binary_digest";
            (void)fclose(binary_file);
        } else {
            recorded[strcspn(recorded, "\r\n")] = '\0';
            if (strcmp(recorded, executable_sha256) != 0 || !hex_is_sha256(recorded)) {
                failed = 1;
                *stop_status = "stopped_binary_digest";
            }
            if (fclose(binary_file) != 0) {
                failed = 1;
                *stop_status = "stopped_binary_digest";
            }
        }
    }
    if (!failed) {
        uint64_t empty_values[V4_EMPTY_WINDOW_COUNT];
        size_t empty_count = 0u;
        FILE *empty_file = fopen(empty_path, "r");
        if (empty_file == NULL || fgets(line, sizeof(line), empty_file) == NULL ||
            strstr(line, "elapsed_clock_counts") == NULL) {
            failed = 1;
            *stop_status = "stopped_incomplete_session";
        }
        while (!failed && empty_file != NULL && fgets(line, sizeof(line), empty_file) != NULL) {
            char *cursor = line;
            char *end = NULL;
            if (line[0] == '\n' || line[0] == '\0') {
                continue;
            }
            (void)strtoul(cursor, &cursor, 10);
            if (*cursor != ',' || empty_count >= V4_EMPTY_WINDOW_COUNT) {
                failed = 1;
                *stop_status = "stopped_incomplete_session";
                break;
            }
            empty_values[empty_count] = strtoull(cursor + 1, &end, 10);
            if (end == cursor + 1) {
                failed = 1;
                *stop_status = "stopped_incomplete_session";
                break;
            }
            empty_count += 1u;
        }
        if (empty_file != NULL && (ferror(empty_file) || fclose(empty_file) != 0)) {
            failed = 1;
            *stop_status = "stopped_incomplete_session";
        }
        if (!failed && empty_count != V4_EMPTY_WINDOW_COUNT) {
            failed = 1;
            *stop_status = "stopped_incomplete_session";
        }
        if (!failed) {
            *empty_median_counts = v4_even_median(empty_values, empty_count);
            if (!isfinite(*empty_median_counts)) {
                failed = 1;
                *stop_status = "stopped_incomplete_session";
            }
        }
    }
    if (!failed && require_coverage) {
        char coverage_text[64];
        char *end = NULL;
        if (meta_value(coverage_path, "coverage_fraction", coverage_text, sizeof(coverage_text)) !=
            0) {
            failed = 1;
            *stop_status = "stopped_window_coverage";
        } else {
            *coverage_fraction = strtod(coverage_text, &end);
            if (end == coverage_text || !isfinite(*coverage_fraction)) {
                failed = 1;
                *stop_status = "stopped_window_coverage";
            }
        }
    } else if (!failed) {
        *coverage_fraction = nan("");
    }
    if (!failed) {
        *effect_counts = (zero_sum / (double)zero_calls) - (ones_sum / (double)ones_calls);
    }
    free(schedule_bytes);
    free(calls);
    return 0;
}

int v4_reduce_manifest(const char *manifest_path,
    int require_binary_digest,
    int require_coverage,
    double *effects,
    double *empty_medians,
    double *coverages,
    size_t capacity,
    size_t *session_count,
    const char **stop_status)
{
    FILE *manifest = fopen(manifest_path, "r");
    char directories[V4_SESSION_MAX][768];
    char line[V4_RAW_LINE];
    size_t directory_count = 0u;
    *session_count = 0u;
    *stop_status = NULL;
    if (manifest == NULL) {
        *stop_status = "stopped_incomplete_session";
        return 0;
    }
    while (fgets(line, sizeof(line), manifest) != NULL) {
        size_t length;
        line[strcspn(line, "\r\n")] = '\0';
        length = strlen(line);
        if (length == 0u) {
            continue;
        }
        if (directory_count >= V4_SESSION_MAX || directory_count >= capacity ||
            length >= sizeof(directories[0])) {
            *stop_status = "stopped_session_count";
            (void)fclose(manifest);
            return 0;
        }
        memcpy(directories[directory_count], line, length + 1u);
        directory_count += 1u;
    }
    if (ferror(manifest) || fclose(manifest) != 0) {
        *stop_status = "stopped_incomplete_session";
        return 0;
    }
    if (directory_count == 0u) {
        *stop_status = "stopped_session_count";
        return 0;
    }
    for (size_t index = 0; index < directory_count; ++index) {
        const char *session_stop = NULL;
        if (reduce_one_session(directories[index],
                require_binary_digest,
                require_coverage,
                &effects[index],
                &empty_medians[index],
                &coverages[index],
                &session_stop) != 0 ||
            session_stop != NULL) {
            *session_count = directory_count;
            *stop_status = session_stop == NULL ? "stopped_incomplete_session" : session_stop;
            return 0;
        }
    }
    *session_count = directory_count;
    return 0;
}
