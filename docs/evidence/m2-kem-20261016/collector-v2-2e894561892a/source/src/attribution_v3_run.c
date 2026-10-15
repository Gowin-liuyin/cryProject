#include "protocol_decision.h"

#include <ctype.h>
#include <math.h>
#include <stdarg.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/stat.h>

#define RULE_ID "v3_attribution_20261013"
#define RULE_SOURCE "docs/research/v3-attribution-20261013/DECISION_RULES.md"
#define ALPHA_FAMILY 0.01
#define RECOMPUTE_ABSOLUTE_TOLERANCE 1e-6
#define SESSION_CAPACITY 24u
#define MANIFEST_CAPACITY 64u
#define QUARTILE_COUNT 4u
#define EMPTY_WINDOW_COUNT 256u
#define RUN_COUNT 5u

enum run_index {
    RUN_V1 = 0,
    RUN_V2 = 1,
    RUN_V3 = 2,
    RUN_DEV_BEFORE = 3,
    RUN_DEV_MESSAGE = 4
};

struct manifest_entry {
    char hash_hex[65];
    char role[64];
    char path[512];
};

struct session_point {
    int session_number;
    int has_decision;
    int has_csv;
    int has_empty;
    double decision_difference_counts;
    double csv_difference_counts;
    size_t zero_count;
    size_t ones_count;
    int quartile_defined[QUARTILE_COUNT];
    double quartile_difference_counts[QUARTILE_COUNT];
    int segment_defined;
    double segment_drift_counts;
    int clock_defined;
    double clock_predicted_counts;
    double clock_residual_counts;
    double empty_median_counts;
    int meta_seen;
};

struct linear_fit {
    int defined;
    double intercept_counts;
    double time_slope_counts;
    double p_intercept;
    double p_time;
    int holm_reject_intercept;
    int holm_reject_time;
};

struct run_record {
    const char *name;
    int present;
    size_t session_count;
    struct session_point sessions[SESSION_CAPACITY];
    int has_decision_mean;
    double decision_mean_counts;
    int empty_max_defined;
    unsigned long long empty_max_counts;
    int meta_session_number;
    struct linear_fit trend;
    int half_stable;
    const char *token;
    int segment_test_defined;
    double segment_mean_counts;
    double segment_p_value;
    int segment_reject;
    int clock_test_defined;
    double clock_predicted_mean_counts;
    double clock_residual_mean_counts;
    double clock_residual_p_value;
    const char *clock_explains;
    int empty_series_defined;
    double empty_time_slope_counts;
    int empty_association_defined;
    double empty_association_p_value;
    int empty_association_reject;
};

struct analysis_failure {
    int exit_code;
    const char *status;
    char path[512];
    char detail[160];
    char expected_hash[65];
    char actual_hash[65];
};

struct timing_row {
    uint32_t sample_index;
    uint64_t elapsed_counts;
    char category[32];
};

int sha256_file(const char *path, char hex_out[65]);
int sha256_self_check(void);

static void set_failure(struct analysis_failure *failure,
    int exit_code,
    const char *status,
    const char *path,
    const char *detail)
{
    failure->exit_code = exit_code;
    failure->status = status;
    failure->path[0] = '\0';
    failure->detail[0] = '\0';
    if (path != NULL) {
        (void)snprintf(failure->path, sizeof(failure->path), "%s", path);
    }
    if (detail != NULL) {
        (void)snprintf(failure->detail, sizeof(failure->detail), "%s", detail);
    }
}

static int write_both(FILE *primary, FILE *secondary, const char *format, ...)
{
    va_list primary_args;
    va_list secondary_args;
    int written;
    va_start(primary_args, format);
    va_copy(secondary_args, primary_args);
    written = vfprintf(primary, format, primary_args);
    if (written >= 0) {
        written = vfprintf(secondary, format, secondary_args);
    }
    va_end(secondary_args);
    va_end(primary_args);
    return written < 0 ? 1 : 0;
}

static const char *yes_no(int value)
{
    return value != 0 ? "yes" : "no";
}

static int sign_of(double value)
{
    if (value > 0.0) {
        return 1;
    }
    if (value < 0.0) {
        return -1;
    }
    return 0;
}

static double session_difference(const struct session_point *session)
{
    if (session->has_decision) {
        return session->decision_difference_counts;
    }
    return session->csv_difference_counts;
}

static int parse_session_number(const char *session_id, int *session_number)
{
    char *end = NULL;
    long value;
    if (session_id == NULL || session_id[0] != 's' || isdigit((unsigned char)session_id[1]) == 0) {
        return 1;
    }
    value = strtol(session_id + 1, &end, 10);
    if (end == session_id + 1 || *end != '\0' || value <= 0 || value > 1000) {
        return 1;
    }
    *session_number = (int)value;
    return 0;
}

static int session_number_from_path(const char *path, int *session_number)
{
    const char *base = path;
    const char *scan;
    int found = 0;
    for (scan = path; *scan != '\0'; ++scan) {
        if (*scan == '/') {
            base = scan + 1;
        }
    }
    for (scan = base; *scan != '\0'; ++scan) {
        char *end = NULL;
        long value;
        if (scan[0] != '-' || scan[1] != 's' || isdigit((unsigned char)scan[2]) == 0) {
            continue;
        }
        value = strtol(scan + 2, &end, 10);
        if (end != scan + 2 && *end == '.' && value > 0 && value <= 1000) {
            *session_number = (int)value;
            found = 1;
        }
    }
    return found;
}

static void strip_line(char *line)
{
    size_t length = strlen(line);
    if (length > 0u && line[length - 1u] == '\n') {
        line[length - 1u] = '\0';
        length -= 1u;
    }
    if (length > 0u && line[length - 1u] == '\r') {
        line[length - 1u] = '\0';
    }
}

static int file_has_exact_line(const char *path, const char *expected)
{
    FILE *file = fopen(path, "r");
    char line[512];
    if (file == NULL) {
        return 0;
    }
    while (fgets(line, sizeof(line), file) != NULL) {
        if (strchr(line, '\n') == NULL && feof(file) == 0) {
            (void)fclose(file);
            return 0;
        }
        strip_line(line);
        if (strcmp(line, expected) == 0) {
            (void)fclose(file);
            return 1;
        }
    }
    (void)fclose(file);
    return 0;
}

static int read_keyed_ull(const char *path, const char *key, unsigned long long *value)
{
    FILE *file = fopen(path, "r");
    char line[512];
    size_t key_length = strlen(key);
    if (file == NULL) {
        return 1;
    }
    while (fgets(line, sizeof(line), file) != NULL) {
        char *end = NULL;
        if (strchr(line, '\n') == NULL && feof(file) == 0) {
            (void)fclose(file);
            return 1;
        }
        strip_line(line);
        if (strncmp(line, key, key_length) != 0 || line[key_length] != '=') {
            continue;
        }
        *value = strtoull(line + key_length + 1u, &end, 10);
        if (end == line + key_length + 1u || *end != '\0') {
            (void)fclose(file);
            return 1;
        }
        (void)fclose(file);
        return 0;
    }
    (void)fclose(file);
    return 1;
}

static int split_fields(char *line, char **fields, size_t field_count)
{
    size_t found = 0u;
    fields[0] = line;
    for (char *cursor = line; *cursor != '\0'; ++cursor) {
        if (*cursor == ',') {
            *cursor = '\0';
            found += 1u;
            if (found >= field_count) {
                return 1;
            }
            fields[found] = cursor + 1;
        }
    }
    return found + 1u == field_count ? 0 : 1;
}

static int hash_is_lower_hex(const char *hash)
{
    if (strlen(hash) != 64u) {
        return 0;
    }
    for (size_t index = 0; index < 64u; ++index) {
        unsigned char character = (unsigned char)hash[index];
        if (isxdigit(character) == 0 || isupper(character) != 0) {
            return 0;
        }
    }
    return 1;
}

static int role_run(const char *role, int *run_index)
{
    if (strcmp(role, "decision:v1") == 0 || strcmp(role, "csv:v1") == 0 ||
        strcmp(role, "empty:v1") == 0 || strcmp(role, "meta:v1") == 0 ||
        strcmp(role, "protocol:v1") == 0) {
        *run_index = RUN_V1;
        return 0;
    }
    if (strcmp(role, "decision:v2") == 0 || strcmp(role, "protocol:v2") == 0) {
        *run_index = RUN_V2;
        return 0;
    }
    if (strcmp(role, "decision:v3") == 0 || strcmp(role, "protocol:v3") == 0 ||
        strcmp(role, "meta:v3") == 0) {
        *run_index = RUN_V3;
        return 0;
    }
    if (strcmp(role, "csv:dev_before") == 0 || strcmp(role, "meta:dev_before") == 0) {
        *run_index = RUN_DEV_BEFORE;
        return 0;
    }
    if (strcmp(role, "csv:dev_message") == 0 || strcmp(role, "meta:dev_message") == 0) {
        *run_index = RUN_DEV_MESSAGE;
        return 0;
    }
    return 1;
}

static int role_allowed(const char *role)
{
    int ignored = 0;
    return role_run(role, &ignored) == 0;
}

static size_t count_role(const struct manifest_entry *entries, size_t entry_count, const char *role)
{
    size_t count = 0u;
    for (size_t index = 0; index < entry_count; ++index) {
        if (strcmp(entries[index].role, role) == 0) {
            count += 1u;
        }
    }
    return count;
}

static int load_manifest(const char *path,
    struct manifest_entry *entries,
    size_t *entry_count,
    struct analysis_failure *failure)
{
    FILE *file = fopen(path, "r");
    char line[1200];
    if (file == NULL) {
        set_failure(failure, 1, "stopped_io", path, "manifest_unreadable");
        return 1;
    }
    *entry_count = 0u;
    while (fgets(line, sizeof(line), file) != NULL) {
        char *hash = NULL;
        char *role = NULL;
        char *entry_path = NULL;
        char *cursor = line;
        if (strchr(line, '\n') == NULL && feof(file) == 0) {
            (void)fclose(file);
            set_failure(failure, 1, "stopped_io", path, "manifest_line_truncated");
            return 1;
        }
        strip_line(line);
        if (line[0] == '\0' || line[0] == '#') {
            continue;
        }
        while (*cursor == ' ') {
            cursor += 1;
        }
        hash = cursor;
        while (*cursor != '\0' && *cursor != ' ') {
            cursor += 1;
        }
        if (*cursor != ' ') {
            (void)fclose(file);
            set_failure(failure, 3, "stopped_identity_mismatch", path, "manifest_field_count");
            return 1;
        }
        *cursor = '\0';
        cursor += 1;
        role = cursor;
        while (*cursor != '\0' && *cursor != ' ') {
            cursor += 1;
        }
        if (*cursor != ' ') {
            (void)fclose(file);
            set_failure(failure, 3, "stopped_identity_mismatch", path, "manifest_field_count");
            return 1;
        }
        *cursor = '\0';
        cursor += 1;
        entry_path = cursor;
        if (entry_path[0] == '\0' || strchr(entry_path, ' ') != NULL ||
            hash_is_lower_hex(hash) == 0 || role_allowed(role) == 0) {
            (void)fclose(file);
            set_failure(failure, 3, "stopped_identity_mismatch", path, "manifest_field");
            return 1;
        }
        if (*entry_count >= MANIFEST_CAPACITY) {
            (void)fclose(file);
            set_failure(failure, 3, "stopped_identity_mismatch", path, "manifest_capacity");
            return 1;
        }
        (void)snprintf(entries[*entry_count].hash_hex,
            sizeof(entries[*entry_count].hash_hex),
            "%s",
            hash);
        (void)snprintf(entries[*entry_count].role, sizeof(entries[*entry_count].role), "%s", role);
        (void)snprintf(entries[*entry_count].path,
            sizeof(entries[*entry_count].path),
            "%s",
            entry_path);
        *entry_count += 1u;
    }
    (void)fclose(file);
    if (*entry_count == 0u) {
        set_failure(failure, 3, "stopped_identity_mismatch", path, "manifest_empty");
        return 1;
    }
    for (size_t left = 0; left < *entry_count; ++left) {
        for (size_t right = left + 1u; right < *entry_count; ++right) {
            if (strcmp(entries[left].path, entries[right].path) == 0) {
                set_failure(failure,
                    3,
                    "stopped_identity_mismatch",
                    entries[left].path,
                    "duplicate_path");
                return 1;
            }
        }
    }
    return 0;
}

static int verify_hashes(const struct manifest_entry *entries,
    size_t entry_count,
    struct analysis_failure *failure)
{
    for (size_t index = 0; index < entry_count; ++index) {
        char actual[65];
        if (sha256_file(entries[index].path, actual) != 0) {
            set_failure(failure, 1, "stopped_io", entries[index].path, "unreadable_input");
            return 1;
        }
        if (strcmp(actual, entries[index].hash_hex) != 0) {
            set_failure(failure,
                2,
                "stopped_digest_mismatch",
                entries[index].path,
                "hash_mismatch");
            (void)snprintf(failure->expected_hash,
                sizeof(failure->expected_hash),
                "%s",
                entries[index].hash_hex);
            (void)snprintf(failure->actual_hash, sizeof(failure->actual_hash), "%s", actual);
            return 1;
        }
    }
    return 0;
}

static int check_sealed_roles(const struct manifest_entry *entries,
    size_t entry_count,
    struct analysis_failure *failure)
{
    static const struct {
        const char *role;
        size_t count;
    } requirements[] = {{"decision:v1", 1u},
        {"decision:v2", 1u},
        {"decision:v3", 1u},
        {"protocol:v2", 1u},
        {"protocol:v3", 1u},
        {"csv:v1", 6u},
        {"empty:v1", 6u},
        {"meta:v1", 6u},
        {"meta:v3", 1u},
        {"csv:dev_before", 1u},
        {"meta:dev_before", 1u},
        {"csv:dev_message", 1u},
        {"meta:dev_message", 1u}};

    size_t required_total = 0u;
    for (size_t index = 0; index < sizeof(requirements) / sizeof(requirements[0]); ++index) {
        size_t actual = count_role(entries, entry_count, requirements[index].role);
        required_total += requirements[index].count;
        if (actual != requirements[index].count) {
            set_failure(failure,
                3,
                "stopped_identity_mismatch",
                requirements[index].role,
                "role_count");
            return 1;
        }
    }
    if (entry_count != required_total || count_role(entries, entry_count, "csv:v2") != 0u ||
        count_role(entries, entry_count, "csv:v3") != 0u) {
        set_failure(failure, 3, "stopped_identity_mismatch", "manifest", "role_count");
        return 1;
    }
    return 0;
}

static struct session_point *add_session(struct run_record *run,
    int session_number,
    struct analysis_failure *failure,
    const char *path)
{
    for (size_t index = 0; index < run->session_count; ++index) {
        if (run->sessions[index].session_number == session_number) {
            return &run->sessions[index];
        }
    }
    if (run->session_count >= SESSION_CAPACITY) {
        set_failure(failure, 3, "stopped_identity_mismatch", path, "session_capacity");
        return NULL;
    }
    memset(&run->sessions[run->session_count], 0, sizeof(run->sessions[run->session_count]));
    run->sessions[run->session_count].session_number = session_number;
    run->session_count += 1u;
    run->present = 1;
    return &run->sessions[run->session_count - 1u];
}

static void sort_sessions(struct run_record *run)
{
    for (size_t index = 1u; index < run->session_count; ++index) {
        struct session_point key = run->sessions[index];
        size_t hole = index;
        while (hole > 0u && run->sessions[hole - 1u].session_number > key.session_number) {
            run->sessions[hole] = run->sessions[hole - 1u];
            hole -= 1u;
        }
        run->sessions[hole] = key;
    }
}

static int ensure_contiguous(struct run_record *runs, struct analysis_failure *failure)
{
    for (int run_index = 0; run_index < (int)RUN_COUNT; ++run_index) {
        struct run_record *run = &runs[run_index];
        sort_sessions(run);
        for (size_t index = 0; index < run->session_count; ++index) {
            if (run->sessions[index].session_number != (int)index + 1) {
                set_failure(failure,
                    3,
                    "stopped_identity_mismatch",
                    run->name,
                    "session_not_contiguous");
                return 1;
            }
        }
    }
    return 0;
}

static int require_lines(const char *path,
    const char *const *lines,
    size_t line_count,
    struct analysis_failure *failure)
{
    for (size_t index = 0; index < line_count; ++index) {
        if (file_has_exact_line(path, lines[index]) == 0) {
            set_failure(failure, 3, "stopped_identity_mismatch", path, "missing_anchor_line");
            return 1;
        }
    }
    return 0;
}

static int load_decision(struct run_record *run, const char *path, struct analysis_failure *failure)
{
    FILE *file = fopen(path, "r");
    char line[512];
    int saw_primary = 0;
    double primary = 0.0;
    if (file == NULL) {
        set_failure(failure, 1, "stopped_io", path, "unreadable_input");
        return 1;
    }
    while (fgets(line, sizeof(line), file) != NULL) {
        char session_id[32];
        char value_text[64];
        if (strchr(line, '\n') == NULL && feof(file) == 0) {
            (void)fclose(file);
            set_failure(failure, 3, "stopped_identity_mismatch", path, "truncated_line");
            return 1;
        }
        strip_line(line);
        if (strncmp(line, "primary_mean_difference_counts=", 31) == 0) {
            char *end = NULL;
            if (saw_primary != 0) {
                (void)fclose(file);
                set_failure(failure, 3, "stopped_identity_mismatch", path, "duplicate_primary");
                return 1;
            }
            primary = strtod(line + 31, &end);
            if (end == line + 31 || *end != '\0') {
                (void)fclose(file);
                set_failure(failure, 3, "stopped_identity_mismatch", path, "primary_mean");
                return 1;
            }
            saw_primary = 1;
            continue;
        }
        if (sscanf(line,
                "session_effect session_id=%31s difference=%63s",
                session_id,
                value_text) == 2) {
            char *end = NULL;
            int session_number = 0;
            struct session_point *session;
            double difference = strtod(value_text, &end);
            if (end == value_text || *end != '\0' ||
                parse_session_number(session_id, &session_number) != 0) {
                (void)fclose(file);
                set_failure(failure, 3, "stopped_identity_mismatch", path, "session_effect_line");
                return 1;
            }
            session = add_session(run, session_number, failure, path);
            if (session == NULL) {
                (void)fclose(file);
                return 1;
            }
            if (session->has_decision != 0) {
                (void)fclose(file);
                set_failure(failure, 3, "stopped_identity_mismatch", path, "duplicate_session");
                return 1;
            }
            session->has_decision = 1;
            session->decision_difference_counts = difference;
        }
    }
    (void)fclose(file);
    if (saw_primary == 0 || run->session_count == 0u) {
        set_failure(failure, 3, "stopped_identity_mismatch", path, "decision_incomplete");
        return 1;
    }
    run->has_decision_mean = 1;
    run->decision_mean_counts = primary;
    run->present = 1;
    return 0;
}

static int load_protocol(const char *path, const char *seed_line, struct analysis_failure *failure)
{
    if (file_has_exact_line(path, seed_line) == 0) {
        set_failure(failure, 3, "stopped_identity_mismatch", path, "confirmation_seed");
        return 1;
    }
    return 0;
}

static int load_meta(struct run_record *run,
    const char *path,
    const char *const *anchors,
    size_t anchor_count,
    int require_filename_session,
    struct analysis_failure *failure)
{
    int session_number = 0;
    int filename_number = 0;
    struct session_point *session;
    if (require_lines(path, anchors, anchor_count, failure) != 0) {
        return 1;
    }
    {
        FILE *file = fopen(path, "r");
        char line[512];
        int found = 0;
        if (file == NULL) {
            set_failure(failure, 1, "stopped_io", path, "unreadable_input");
            return 1;
        }
        while (fgets(line, sizeof(line), file) != NULL) {
            strip_line(line);
            if (strncmp(line, "session_id=", 11) == 0) {
                if (parse_session_number(line + 11, &session_number) != 0) {
                    (void)fclose(file);
                    set_failure(failure, 3, "stopped_identity_mismatch", path, "session_id");
                    return 1;
                }
                found = 1;
            }
        }
        (void)fclose(file);
        if (found == 0) {
            set_failure(failure, 3, "stopped_identity_mismatch", path, "session_id");
            return 1;
        }
    }
    if (session_number_from_path(path, &filename_number) != 0 &&
        filename_number != session_number) {
        set_failure(failure, 3, "stopped_identity_mismatch", path, "filename_session");
        return 1;
    }
    if (require_filename_session != 0 && session_number_from_path(path, &filename_number) == 0) {
        set_failure(failure, 3, "stopped_identity_mismatch", path, "filename_session");
        return 1;
    }
    if (strcmp(run->name, "v3") == 0) {
        if (read_keyed_ull(path, "empty_window_max_counts", &run->empty_max_counts) != 0) {
            set_failure(failure, 3, "stopped_identity_mismatch", path, "empty_window_max");
            return 1;
        }
        run->empty_max_defined = 1;
    }
    run->meta_session_number = session_number;
    if (require_filename_session != 0) {
        session = add_session(run, session_number, failure, path);
        if (session == NULL) {
            return 1;
        }
        if (session->has_decision == 0) {
            set_failure(failure, 3, "stopped_identity_mismatch", path, "meta_without_decision");
            return 1;
        }
        session->meta_seen = 1;
    }
    run->present = 1;
    return 0;
}

static int compare_u64(const void *left_void, const void *right_void)
{
    uint64_t left = *(const uint64_t *)left_void;
    uint64_t right = *(const uint64_t *)right_void;
    if (left < right) {
        return -1;
    }
    if (left > right) {
        return 1;
    }
    return 0;
}

static int load_empty(struct run_record *run, const char *path, struct analysis_failure *failure)
{
    FILE *file = fopen(path, "r");
    char line[256];
    uint64_t values[EMPTY_WINDOW_COUNT];
    size_t count = 0u;
    int session_number = 0;
    struct session_point *session;
    if (file == NULL) {
        set_failure(failure, 1, "stopped_io", path, "unreadable_input");
        return 1;
    }
    if (fgets(line, sizeof(line), file) == NULL) {
        (void)fclose(file);
        set_failure(failure, 3, "stopped_identity_mismatch", path, "empty_header");
        return 1;
    }
    strip_line(line);
    if (strcmp(line, "window_index,elapsed_clock_counts,clock_path") != 0) {
        (void)fclose(file);
        set_failure(failure, 3, "stopped_identity_mismatch", path, "empty_header");
        return 1;
    }
    while (fgets(line, sizeof(line), file) != NULL) {
        char *fields[3];
        char *end = NULL;
        if (count >= EMPTY_WINDOW_COUNT) {
            (void)fclose(file);
            set_failure(failure, 3, "stopped_identity_mismatch", path, "empty_count");
            return 1;
        }
        strip_line(line);
        if (line[0] == '\0') {
            continue;
        }
        if (split_fields(line, fields, 3u) != 0) {
            (void)fclose(file);
            set_failure(failure, 3, "stopped_identity_mismatch", path, "empty_fields");
            return 1;
        }
        values[count] = strtoull(fields[1], &end, 10);
        if (end == fields[1] || *end != '\0') {
            (void)fclose(file);
            set_failure(failure, 3, "stopped_identity_mismatch", path, "empty_elapsed");
            return 1;
        }
        count += 1u;
    }
    (void)fclose(file);
    if (count != EMPTY_WINDOW_COUNT || session_number_from_path(path, &session_number) == 0) {
        set_failure(failure, 3, "stopped_identity_mismatch", path, "empty_count");
        return 1;
    }
    session = add_session(run, session_number, failure, path);
    if (session == NULL) {
        return 1;
    }
    if (session->has_empty != 0) {
        set_failure(failure, 3, "stopped_identity_mismatch", path, "duplicate_empty");
        return 1;
    }
    qsort(values, count, sizeof(values[0]), compare_u64);
    session->empty_median_counts =
        ((double)values[count / 2u - 1u] + (double)values[count / 2u]) / 2.0;
    session->has_empty = 1;
    return 0;
}

static int load_csv(struct run_record *run,
    const char *path,
    int require_filename_session,
    struct analysis_failure *failure)
{
    static const char *header =
        "schema,run_id,session_id,block_id,key_id,sample_index,predecessor_category,"
        "category,generator_label,elapsed_clock_counts,clock_path,ciphertext_sha256_hex";
    FILE *file = fopen(path, "r");
    char line[1024];
    struct timing_row *rows = NULL;
    size_t row_count = 0u;
    size_t row_capacity = 0u;
    int session_number = 0;
    int filename_number = 0;
    struct session_point *session;
    double zero_total = 0.0;
    double ones_total = 0.0;
    size_t zero_count = 0u;
    size_t ones_count = 0u;
    double zero_index = 0.0;
    double ones_index = 0.0;
    double sum_x = 0.0;
    double sum_y = 0.0;
    double sum_xx = 0.0;
    double sum_xy = 0.0;
    double quartile_zero[QUARTILE_COUNT] = {0.0, 0.0, 0.0, 0.0};
    double quartile_ones[QUARTILE_COUNT] = {0.0, 0.0, 0.0, 0.0};
    size_t quartile_zero_count[QUARTILE_COUNT] = {0u, 0u, 0u, 0u};
    size_t quartile_ones_count[QUARTILE_COUNT] = {0u, 0u, 0u, 0u};
    double denominator;
    double clock_slope;
    double position_gap;
    if (file == NULL) {
        set_failure(failure, 1, "stopped_io", path, "unreadable_input");
        return 1;
    }
    if (fgets(line, sizeof(line), file) == NULL) {
        (void)fclose(file);
        set_failure(failure, 3, "stopped_identity_mismatch", path, "csv_header");
        return 1;
    }
    strip_line(line);
    if (strcmp(line, header) != 0) {
        (void)fclose(file);
        set_failure(failure, 3, "stopped_identity_mismatch", path, "csv_header");
        return 1;
    }
    while (fgets(line, sizeof(line), file) != NULL) {
        char *fields[12];
        char *end = NULL;
        struct timing_row *row;
        unsigned long sample_index;
        if (strchr(line, '\n') == NULL && feof(file) == 0) {
            free(rows);
            (void)fclose(file);
            set_failure(failure, 3, "stopped_identity_mismatch", path, "truncated_line");
            return 1;
        }
        strip_line(line);
        if (line[0] == '\0') {
            continue;
        }
        if (split_fields(line, fields, 12u) != 0 ||
            strcmp(fields[0], "session_decapsulation_v1") != 0) {
            free(rows);
            (void)fclose(file);
            set_failure(failure, 3, "stopped_identity_mismatch", path, "csv_fields");
            return 1;
        }
        if (row_count == 0u) {
            if (parse_session_number(fields[2], &session_number) != 0) {
                free(rows);
                (void)fclose(file);
                set_failure(failure, 3, "stopped_identity_mismatch", path, "session_id");
                return 1;
            }
        } else {
            int row_session = 0;
            if (parse_session_number(fields[2], &row_session) != 0 ||
                row_session != session_number) {
                free(rows);
                (void)fclose(file);
                set_failure(failure, 3, "stopped_identity_mismatch", path, "mixed_session");
                return 1;
            }
        }
        sample_index = strtoul(fields[5], &end, 10);
        if (end == fields[5] || *end != '\0' || sample_index > 4294967295ul) {
            free(rows);
            (void)fclose(file);
            set_failure(failure, 3, "stopped_identity_mismatch", path, "sample_index");
            return 1;
        }
        end = NULL;
        if (row_count == row_capacity) {
            size_t new_capacity = row_capacity == 0u ? 64u : row_capacity * 2u;
            struct timing_row *grown = realloc(rows, new_capacity * sizeof(*rows));
            if (grown == NULL) {
                free(rows);
                (void)fclose(file);
                set_failure(failure, 1, "stopped_io", path, "out_of_memory");
                return 1;
            }
            rows = grown;
            row_capacity = new_capacity;
        }
        row = &rows[row_count];
        row->sample_index = (uint32_t)sample_index;
        row->elapsed_counts = strtoull(fields[9], &end, 10);
        if (end == fields[9] || *end != '\0') {
            free(rows);
            (void)fclose(file);
            set_failure(failure, 3, "stopped_identity_mismatch", path, "elapsed");
            return 1;
        }
        if (snprintf(row->category, sizeof(row->category), "%s", fields[7]) >=
            (int)sizeof(row->category)) {
            free(rows);
            (void)fclose(file);
            set_failure(failure, 3, "stopped_identity_mismatch", path, "category");
            return 1;
        }
        row_count += 1u;
    }
    (void)fclose(file);
    if (row_count == 0u) {
        free(rows);
        set_failure(failure, 3, "stopped_identity_mismatch", path, "csv_empty");
        return 1;
    }
    if (session_number_from_path(path, &filename_number) != 0 &&
        filename_number != session_number) {
        free(rows);
        set_failure(failure, 3, "stopped_identity_mismatch", path, "filename_session");
        return 1;
    }
    if (require_filename_session != 0 && session_number_from_path(path, &filename_number) == 0) {
        free(rows);
        set_failure(failure, 3, "stopped_identity_mismatch", path, "filename_session");
        return 1;
    }
    for (size_t index = 0; index < row_count; ++index) {
        uint64_t bin = ((uint64_t)rows[index].sample_index * 4u) / (uint64_t)row_count;
        double elapsed = (double)rows[index].elapsed_counts;
        double sample = (double)rows[index].sample_index;
        if (bin >= QUARTILE_COUNT) {
            free(rows);
            set_failure(failure, 3, "stopped_identity_mismatch", path, "sample_index_range");
            return 1;
        }
        sum_x += sample;
        sum_y += elapsed;
        sum_xx += sample * sample;
        sum_xy += sample * elapsed;
        if (strcmp(rows[index].category, "message-zero") == 0) {
            zero_total += elapsed;
            zero_index += sample;
            zero_count += 1u;
            quartile_zero[bin] += elapsed;
            quartile_zero_count[bin] += 1u;
        } else if (strcmp(rows[index].category, "message-ones") == 0) {
            ones_total += elapsed;
            ones_index += sample;
            ones_count += 1u;
            quartile_ones[bin] += elapsed;
            quartile_ones_count[bin] += 1u;
        }
    }
    free(rows);
    if (zero_count == 0u || ones_count == 0u) {
        set_failure(failure, 3, "stopped_identity_mismatch", path, "missing_class");
        return 1;
    }
    session = add_session(run, session_number, failure, path);
    if (session == NULL) {
        return 1;
    }
    if (session->has_csv != 0) {
        set_failure(failure, 3, "stopped_identity_mismatch", path, "duplicate_csv");
        return 1;
    }
    session->has_csv = 1;
    session->zero_count = zero_count;
    session->ones_count = ones_count;
    session->csv_difference_counts =
        zero_total / (double)zero_count - ones_total / (double)ones_count;
    for (size_t bin = 0; bin < QUARTILE_COUNT; ++bin) {
        if (quartile_zero_count[bin] > 0u && quartile_ones_count[bin] > 0u) {
            session->quartile_defined[bin] = 1;
            session->quartile_difference_counts[bin] =
                quartile_zero[bin] / (double)quartile_zero_count[bin] -
                quartile_ones[bin] / (double)quartile_ones_count[bin];
        }
    }
    if (session->quartile_defined[0] != 0 && session->quartile_defined[3] != 0) {
        session->segment_defined = 1;
        session->segment_drift_counts =
            session->quartile_difference_counts[3] - session->quartile_difference_counts[0];
    }
    denominator = (double)row_count * sum_xx - sum_x * sum_x;
    if (denominator != 0.0) {
        clock_slope = ((double)row_count * sum_xy - sum_x * sum_y) / denominator;
        position_gap = zero_index / (double)zero_count - ones_index / (double)ones_count;
        session->clock_defined = 1;
        session->clock_predicted_counts = clock_slope * position_gap;
        session->clock_residual_counts =
            session->csv_difference_counts - session->clock_predicted_counts;
    }
    run->present = 1;
    return 0;
}

static int cross_check(struct run_record *runs, struct analysis_failure *failure)
{
    for (int run_index = 0; run_index < (int)RUN_COUNT; ++run_index) {
        struct run_record *run = &runs[run_index];
        double total = 0.0;
        int saw_csv = 0;
        if (run->present == 0) {
            continue;
        }
        for (size_t index = 0; index < run->session_count; ++index) {
            if (run->sessions[index].has_csv != 0) {
                saw_csv = 1;
            }
        }
        if (run->has_decision_mean != 0) {
            for (size_t index = 0; index < run->session_count; ++index) {
                struct session_point *session = &run->sessions[index];
                if (session->has_decision == 0) {
                    set_failure(failure,
                        3,
                        "stopped_recompute_mismatch",
                        run->name,
                        "session_without_decision");
                    return 1;
                }
                total += session->decision_difference_counts;
                if (session->has_csv != 0 &&
                    fabs(session->csv_difference_counts - session->decision_difference_counts) >
                        RECOMPUTE_ABSOLUTE_TOLERANCE) {
                    set_failure(failure,
                        3,
                        "stopped_recompute_mismatch",
                        run->name,
                        "csv_decision_gap");
                    return 1;
                }
                if (saw_csv != 0 && session->has_csv == 0) {
                    set_failure(failure,
                        3,
                        "stopped_recompute_mismatch",
                        run->name,
                        "csv_missing_session");
                    return 1;
                }
            }
            if (fabs(total / (double)run->session_count - run->decision_mean_counts) >
                RECOMPUTE_ABSOLUTE_TOLERANCE) {
                set_failure(failure,
                    3,
                    "stopped_recompute_mismatch",
                    run->name,
                    "primary_mean_gap");
                return 1;
            }
        }
        if (run->meta_session_number != 0 && run->session_count == 1u &&
            run->sessions[0].session_number != run->meta_session_number) {
            set_failure(failure, 3, "stopped_identity_mismatch", run->name, "meta_session");
            return 1;
        }
    }
    return 0;
}

static int check_sealed_population(struct run_record *runs, struct analysis_failure *failure)
{
    if (runs[RUN_V1].session_count != 6u || runs[RUN_V2].session_count != 20u ||
        runs[RUN_V3].session_count != 20u || runs[RUN_DEV_BEFORE].session_count != 1u ||
        runs[RUN_DEV_MESSAGE].session_count != 1u || runs[RUN_V3].empty_max_defined == 0) {
        set_failure(failure, 3, "stopped_identity_mismatch", "population", "session_count");
        return 1;
    }
    for (size_t index = 0; index < runs[RUN_V1].session_count; ++index) {
        struct session_point *session = &runs[RUN_V1].sessions[index];
        if (session->zero_count != 1000u || session->ones_count != 1000u ||
            session->has_empty == 0 || session->meta_seen == 0) {
            set_failure(failure, 3, "stopped_identity_mismatch", "v1", "sample_count");
            return 1;
        }
    }
    for (size_t index = 0; index < runs[RUN_DEV_BEFORE].session_count; ++index) {
        if (runs[RUN_DEV_BEFORE].sessions[index].zero_count != 200u ||
            runs[RUN_DEV_BEFORE].sessions[index].ones_count != 200u) {
            set_failure(failure, 3, "stopped_identity_mismatch", "dev_before", "sample_count");
            return 1;
        }
    }
    for (size_t index = 0; index < runs[RUN_DEV_MESSAGE].session_count; ++index) {
        if (runs[RUN_DEV_MESSAGE].sessions[index].zero_count != 200u ||
            runs[RUN_DEV_MESSAGE].sessions[index].ones_count != 200u) {
            set_failure(failure, 3, "stopped_identity_mismatch", "dev_message", "sample_count");
            return 1;
        }
    }
    return 0;
}

static int
mean_test(const double *values, size_t count, double *mean_out, double *t_out, double *p_out)
{
    double mean = 0.0;
    double variance = 0.0;
    if (count < 2u) {
        return 1;
    }
    for (size_t index = 0; index < count; ++index) {
        mean += values[index];
    }
    mean /= (double)count;
    for (size_t index = 0; index < count; ++index) {
        double delta = values[index] - mean;
        variance += delta * delta;
    }
    variance /= (double)(count - 1u);
    *mean_out = mean;
    if (variance == 0.0) {
        if (mean == 0.0) {
            *t_out = 0.0;
            *p_out = 1.0;
        } else {
            *t_out = copysign(INFINITY, mean);
            *p_out = 0.0;
        }
        return 0;
    }
    *t_out = mean / sqrt(variance / (double)count);
    *p_out = protocol_student_t_two_sided(*t_out, (unsigned)(count - 1u));
    return 0;
}

static void coefficient_test(double coefficient,
    double standard_error,
    unsigned degrees_of_freedom,
    double *t_out,
    double *p_out)
{
    if (standard_error == 0.0) {
        if (coefficient == 0.0) {
            *t_out = 0.0;
            *p_out = 1.0;
        } else {
            *t_out = copysign(INFINITY, coefficient);
            *p_out = 0.0;
        }
        return;
    }
    *t_out = coefficient / standard_error;
    *p_out = protocol_student_t_two_sided(*t_out, degrees_of_freedom);
}

static void fit_time(const double *differences, size_t count, struct linear_fit *fit)
{
    double mean = 0.0;
    double sum_u2 = 0.0;
    double sum_ud = 0.0;
    double sse = 0.0;
    double slope;
    double t_intercept = 0.0;
    double t_slope = 0.0;
    unsigned degrees;
    memset(fit, 0, sizeof(*fit));
    if (count < 3u) {
        return;
    }
    for (size_t index = 0; index < count; ++index) {
        mean += differences[index];
    }
    mean /= (double)count;
    for (size_t index = 0; index < count; ++index) {
        double u = (double)index / (double)(count - 1u) - 0.5;
        sum_u2 += u * u;
        sum_ud += u * (differences[index] - mean);
    }
    if (sum_u2 == 0.0) {
        return;
    }
    slope = sum_ud / sum_u2;
    for (size_t index = 0; index < count; ++index) {
        double u = (double)index / (double)(count - 1u) - 0.5;
        double residual = differences[index] - mean - slope * u;
        sse += residual * residual;
    }
    degrees = (unsigned)(count - 2u);
    fit->defined = 1;
    fit->intercept_counts = mean;
    fit->time_slope_counts = slope;
    if (sse == 0.0) {
        coefficient_test(mean, 0.0, degrees, &t_intercept, &fit->p_intercept);
        coefficient_test(slope, 0.0, degrees, &t_slope, &fit->p_time);
    } else {
        double sigma2 = sse / (double)degrees;
        coefficient_test(mean,
            sqrt(sigma2 / (double)count),
            degrees,
            &t_intercept,
            &fit->p_intercept);
        coefficient_test(slope, sqrt(sigma2 / sum_u2), degrees, &t_slope, &fit->p_time);
    }
    (void)t_intercept;
    (void)t_slope;
    {
        double p_values[2] = {fit->p_intercept, fit->p_time};
        int rejected[2] = {0, 0};
        protocol_holm(p_values, 2u, ALPHA_FAMILY, rejected);
        fit->holm_reject_intercept = rejected[0];
        fit->holm_reject_time = rejected[1];
    }
}

static int halves_are_stable(const struct run_record *run)
{
    size_t half;
    double first[SESSION_CAPACITY];
    double second[SESSION_CAPACITY];
    double first_mean = 0.0;
    double second_mean = 0.0;
    double full_mean;
    double ignored_t = 0.0;
    double first_p = 1.0;
    double second_p = 1.0;
    int rejected[2] = {0, 0};
    double p_values[2];
    int full_sign;
    if (run->session_count < 4u || (run->session_count % 2u) != 0u) {
        return -1;
    }
    half = run->session_count / 2u;
    for (size_t index = 0; index < half; ++index) {
        first[index] = session_difference(&run->sessions[index]);
        second[index] = session_difference(&run->sessions[index + half]);
    }
    if (mean_test(first, half, &first_mean, &ignored_t, &first_p) != 0 ||
        mean_test(second, half, &second_mean, &ignored_t, &second_p) != 0) {
        return 0;
    }
    p_values[0] = first_p;
    p_values[1] = second_p;
    protocol_holm(p_values, 2u, ALPHA_FAMILY, rejected);
    full_mean = run->has_decision_mean ? run->decision_mean_counts : run->trend.intercept_counts;
    full_sign = sign_of(full_mean);
    if (rejected[0] != 0 && rejected[1] != 0 && sign_of(first_mean) == full_sign &&
        sign_of(second_mean) == full_sign && full_sign != 0) {
        return 1;
    }
    return 0;
}

static const char *effect_token(const struct linear_fit *fit, int half_stable)
{
    if (fit->defined == 0) {
        return "not_run";
    }
    if (fit->holm_reject_intercept == 0 && fit->holm_reject_time != 0) {
        return "yes_pure_trend";
    }
    if (half_stable < 0) {
        return "not_run";
    }
    if (fit->holm_reject_intercept != 0 && half_stable == 1) {
        return "no";
    }
    if (fit->holm_reject_intercept != 0 && half_stable == 0 && fit->holm_reject_time != 0) {
        return "partial";
    }
    if (fit->holm_reject_intercept != 0 && half_stable == 0 && fit->holm_reject_time == 0) {
        return "not_linear";
    }
    if (fit->holm_reject_intercept == 0 && fit->holm_reject_time == 0) {
        return "inconclusive";
    }
    return "not_run";
}

static void assess_segments(struct run_record *run)
{
    double values[SESSION_CAPACITY];
    double ignored_t = 0.0;
    int complete = 1;
    run->segment_test_defined = 0;
    run->segment_reject = 0;
    if (run->session_count < 6u) {
        return;
    }
    for (size_t index = 0; index < run->session_count; ++index) {
        if (run->sessions[index].segment_defined == 0) {
            complete = 0;
        }
        values[index] = run->sessions[index].segment_drift_counts;
    }
    if (complete == 0) {
        return;
    }
    if (mean_test(values,
            run->session_count,
            &run->segment_mean_counts,
            &ignored_t,
            &run->segment_p_value) != 0) {
        return;
    }
    run->segment_test_defined = 1;
    run->segment_reject = run->segment_p_value <= ALPHA_FAMILY ? 1 : 0;
}

static void assess_clock(struct run_record *run)
{
    double raw[SESSION_CAPACITY];
    double residual[SESSION_CAPACITY];
    double raw_mean = 0.0;
    double ignored_t = 0.0;
    double raw_p = 1.0;
    int saw_csv = 0;
    int complete = 1;
    run->clock_explains = "not_applicable";
    run->clock_test_defined = 0;
    for (size_t index = 0; index < run->session_count; ++index) {
        if (run->sessions[index].has_csv != 0) {
            saw_csv = 1;
        }
        if (run->sessions[index].clock_defined == 0) {
            complete = 0;
        }
        raw[index] = session_difference(&run->sessions[index]);
        residual[index] = run->sessions[index].clock_residual_counts;
    }
    if (saw_csv == 0) {
        run->clock_explains = "not_in_sealed_tree";
        return;
    }
    if (complete == 0 || run->session_count < 6u) {
        return;
    }
    if (mean_test(raw, run->session_count, &raw_mean, &ignored_t, &raw_p) != 0 ||
        mean_test(residual,
            run->session_count,
            &run->clock_residual_mean_counts,
            &ignored_t,
            &run->clock_residual_p_value) != 0) {
        return;
    }
    run->clock_test_defined = 1;
    run->clock_predicted_mean_counts = raw_mean - run->clock_residual_mean_counts;
    if (raw_p <= ALPHA_FAMILY && run->clock_residual_p_value > ALPHA_FAMILY) {
        run->clock_explains = "yes";
    } else {
        run->clock_explains = "no";
    }
}

static void assess_empty(struct run_record *run)
{
    double medians[SESSION_CAPACITY];
    double differences[SESSION_CAPACITY];
    struct linear_fit empty_trend;
    double mean_median = 0.0;
    double sum_u2 = 0.0;
    double sum_m2 = 0.0;
    double sum_um = 0.0;
    double sum_ud = 0.0;
    double sum_md = 0.0;
    double determinant;
    double gamma;
    double sse = 0.0;
    int complete = 1;
    run->empty_series_defined = 0;
    run->empty_association_defined = 0;
    run->empty_association_reject = 0;
    if (run->session_count < 4u) {
        return;
    }
    for (size_t index = 0; index < run->session_count; ++index) {
        if (run->sessions[index].has_empty == 0) {
            complete = 0;
        }
        medians[index] = run->sessions[index].empty_median_counts;
        differences[index] = session_difference(&run->sessions[index]);
    }
    if (complete == 0) {
        return;
    }
    fit_time(medians, run->session_count, &empty_trend);
    if (empty_trend.defined == 0) {
        return;
    }
    run->empty_series_defined = 1;
    run->empty_time_slope_counts = empty_trend.time_slope_counts;
    for (size_t index = 0; index < run->session_count; ++index) {
        mean_median += medians[index];
    }
    mean_median /= (double)run->session_count;
    for (size_t index = 0; index < run->session_count; ++index) {
        double u = (double)index / (double)(run->session_count - 1u) - 0.5;
        double centered_median = medians[index] - mean_median;
        double centered_difference = differences[index] - run->trend.intercept_counts;
        sum_u2 += u * u;
        sum_m2 += centered_median * centered_median;
        sum_um += u * centered_median;
        sum_ud += u * centered_difference;
        sum_md += centered_median * centered_difference;
    }
    determinant = sum_u2 * sum_m2 - sum_um * sum_um;
    if (fabs(determinant) <= 1e-12 * (fabs(sum_u2 * sum_m2) + 1.0)) {
        return;
    }
    gamma = (sum_u2 * sum_md - sum_um * sum_ud) / determinant;
    {
        double beta = (sum_m2 * sum_ud - sum_um * sum_md) / determinant;
        unsigned degrees = (unsigned)(run->session_count - 3u);
        double t_value = 0.0;
        for (size_t index = 0; index < run->session_count; ++index) {
            double u = (double)index / (double)(run->session_count - 1u) - 0.5;
            double centered_median = medians[index] - mean_median;
            double residual = differences[index] - run->trend.intercept_counts - beta * u -
                gamma * centered_median;
            sse += residual * residual;
        }
        if (degrees == 0u) {
            return;
        }
        if (sse == 0.0) {
            coefficient_test(gamma, 0.0, degrees, &t_value, &run->empty_association_p_value);
        } else {
            double inverse_gamma = sum_u2 / determinant;
            double standard_error = sqrt((sse / (double)degrees) * inverse_gamma);
            coefficient_test(gamma,
                standard_error,
                degrees,
                &t_value,
                &run->empty_association_p_value);
        }
        (void)t_value;
        run->empty_association_defined = 1;
        run->empty_association_reject = run->empty_association_p_value <= ALPHA_FAMILY ? 1 : 0;
    }
}

static void analyze_run(struct run_record *run)
{
    double differences[SESSION_CAPACITY];
    run->token = "not_run";
    run->half_stable = -1;
    run->clock_explains = "not_applicable";
    if (run->present == 0 || run->session_count == 0u) {
        return;
    }
    for (size_t index = 0; index < run->session_count; ++index) {
        differences[index] = session_difference(&run->sessions[index]);
    }
    fit_time(differences, run->session_count, &run->trend);
    run->half_stable = halves_are_stable(run);
    run->token = effect_token(&run->trend, run->half_stable);
    assess_segments(run);
    assess_clock(run);
    assess_empty(run);
}

static int
print_optional(FILE *primary, FILE *secondary, const char *key, int defined, double value)
{
    if (defined == 0) {
        return write_both(primary, secondary, "%s=na\n", key);
    }
    return write_both(primary, secondary, "%s=%.17g\n", key, value);
}

static const char *recompute_label(const struct run_record *run)
{
    int saw_csv = 0;
    if (run->present == 0) {
        return "absent";
    }
    for (size_t index = 0; index < run->session_count; ++index) {
        if (run->sessions[index].has_csv != 0) {
            saw_csv = 1;
        }
    }
    if (saw_csv == 0) {
        return "not_checked";
    }
    if (run->has_decision_mean == 0) {
        return "csv_only";
    }
    return "matched";
}

static const char *half_label(int half_stable)
{
    if (half_stable < 0) {
        return "not_applicable";
    }
    return half_stable != 0 ? "yes" : "no";
}

static int write_run_block(FILE *primary, FILE *secondary, const struct run_record *run)
{
    if (write_both(primary, secondary, "run=%s\n", run->name) != 0 ||
        write_both(primary, secondary, "present=%s\n", yes_no(run->present)) != 0 ||
        write_both(primary, secondary, "session_count=%zu\n", run->session_count) != 0 ||
        write_both(primary, secondary, "recompute=%s\n", recompute_label(run)) != 0 ||
        write_both(primary, secondary, "context_token=%s\n", run->token) != 0 ||
        write_both(primary, secondary, "half_stable=%s\n", half_label(run->half_stable)) != 0 ||
        write_both(primary, secondary, "clock_explains=%s\n", run->clock_explains) != 0) {
        return 1;
    }
    if (print_optional(primary,
            secondary,
            "intercept_counts",
            run->trend.defined,
            run->trend.intercept_counts) != 0 ||
        print_optional(primary,
            secondary,
            "time_slope_counts",
            run->trend.defined,
            run->trend.time_slope_counts) != 0 ||
        print_optional(primary,
            secondary,
            "p_intercept",
            run->trend.defined,
            run->trend.p_intercept) != 0 ||
        print_optional(primary, secondary, "p_time", run->trend.defined, run->trend.p_time) != 0) {
        return 1;
    }
    if (run->trend.defined != 0) {
        if (write_both(primary,
                secondary,
                "holm_reject_intercept=%s\n",
                yes_no(run->trend.holm_reject_intercept)) != 0 ||
            write_both(primary,
                secondary,
                "holm_reject_time=%s\n",
                yes_no(run->trend.holm_reject_time)) != 0) {
            return 1;
        }
    } else if (write_both(primary, secondary, "holm_reject_intercept=na\nholm_reject_time=na\n") !=
        0) {
        return 1;
    }
    if (print_optional(primary,
            secondary,
            "segment_mean_counts",
            run->segment_test_defined,
            run->segment_mean_counts) != 0 ||
        print_optional(primary,
            secondary,
            "segment_p_value",
            run->segment_test_defined,
            run->segment_p_value) != 0 ||
        print_optional(primary,
            secondary,
            "clock_residual_mean_counts",
            run->clock_test_defined,
            run->clock_residual_mean_counts) != 0 ||
        print_optional(primary,
            secondary,
            "clock_residual_p_value",
            run->clock_test_defined,
            run->clock_residual_p_value) != 0 ||
        print_optional(primary,
            secondary,
            "empty_time_slope_counts",
            run->empty_series_defined,
            run->empty_time_slope_counts) != 0 ||
        print_optional(primary,
            secondary,
            "empty_association_p_value",
            run->empty_association_defined,
            run->empty_association_p_value) != 0) {
        return 1;
    }
    return 0;
}

static int write_session_table(const char *directory, const struct run_record *run)
{
    char path[1024];
    FILE *file;
    if (run->present == 0) {
        return 0;
    }
    if (snprintf(path, sizeof(path), "%s/sessions-%s.csv", directory, run->name) >=
        (int)sizeof(path)) {
        return 1;
    }
    file = fopen(path, "w");
    if (file == NULL) {
        return 1;
    }
    if (fputs("session_number,difference_counts,fitted_counts,segment_drift_counts,"
              "empty_median_counts,clock_predicted_counts,clock_residual_counts,"
              "quartile_1_counts,quartile_2_counts,quartile_3_counts,quartile_4_counts\n",
            file) < 0) {
        (void)fclose(file);
        return 1;
    }
    for (size_t index = 0; index < run->session_count; ++index) {
        const struct session_point *session = &run->sessions[index];
        double difference = session_difference(session);
        if (fprintf(file, "%d,%.17g,", session->session_number, difference) < 0) {
            (void)fclose(file);
            return 1;
        }
        if (run->trend.defined != 0 && run->session_count > 1u) {
            double u = (double)index / (double)(run->session_count - 1u) - 0.5;
            if (fprintf(file,
                    "%.17g,",
                    run->trend.intercept_counts + run->trend.time_slope_counts * u) < 0) {
                (void)fclose(file);
                return 1;
            }
        } else if (fputs("na,", file) < 0) {
            (void)fclose(file);
            return 1;
        }
        if (session->segment_defined != 0) {
            if (fprintf(file, "%.17g,", session->segment_drift_counts) < 0) {
                (void)fclose(file);
                return 1;
            }
        } else if (fputs("na,", file) < 0) {
            (void)fclose(file);
            return 1;
        }
        if (session->has_empty != 0) {
            if (fprintf(file, "%.17g,", session->empty_median_counts) < 0) {
                (void)fclose(file);
                return 1;
            }
        } else if (fputs("na,", file) < 0) {
            (void)fclose(file);
            return 1;
        }
        if (session->clock_defined != 0) {
            if (fprintf(file,
                    "%.17g,%.17g,",
                    session->clock_predicted_counts,
                    session->clock_residual_counts) < 0) {
                (void)fclose(file);
                return 1;
            }
        } else if (fputs("na,na,", file) < 0) {
            (void)fclose(file);
            return 1;
        }
        for (size_t bin = 0; bin < QUARTILE_COUNT; ++bin) {
            const char *separator = bin + 1u == QUARTILE_COUNT ? "\n" : ",";
            if (session->quartile_defined[bin] != 0) {
                if (fprintf(file, "%.17g%s", session->quartile_difference_counts[bin], separator) <
                    0) {
                    (void)fclose(file);
                    return 1;
                }
            } else if (fprintf(file, "na%s", separator) < 0) {
                (void)fclose(file);
                return 1;
            }
        }
    }
    return fclose(file) == 0 ? 0 : 1;
}

static int scale_y(double value, double low, double high)
{
    double span = high - low;
    double fraction;
    if (span == 0.0) {
        return 180;
    }
    fraction = (high - value) / span;
    if (fraction < 0.0) {
        fraction = 0.0;
    }
    if (fraction > 1.0) {
        fraction = 1.0;
    }
    return 40 + (int)(fraction * 280.0 + 0.5);
}

static int write_svg(const char *directory, const struct run_record *run)
{
    char path[1024];
    FILE *file;
    double low;
    double high;
    if (run->present == 0 || run->session_count == 0u) {
        return 0;
    }
    if (snprintf(path, sizeof(path), "%s/trend-%s.svg", directory, run->name) >=
        (int)sizeof(path)) {
        return 1;
    }
    file = fopen(path, "w");
    if (file == NULL) {
        return 1;
    }
    low = session_difference(&run->sessions[0]);
    high = low;
    for (size_t index = 0; index < run->session_count; ++index) {
        double value = session_difference(&run->sessions[index]);
        if (value < low) {
            low = value;
        }
        if (value > high) {
            high = value;
        }
    }
    if (fputs("<svg xmlns=\"http://www.w3.org/2000/svg\" width=\"640\" height=\"360\">\n"
              "<rect width=\"640\" height=\"360\" fill=\"white\"/>\n",
            file) < 0) {
        (void)fclose(file);
        return 1;
    }
    if (run->trend.defined != 0 && run->session_count > 1u) {
        if (fputs("<polyline fill=\"none\" stroke=\"#1d4e89\" stroke-width=\"2\" points=\"", file) <
            0) {
            (void)fclose(file);
            return 1;
        }
        for (size_t index = 0; index < run->session_count; ++index) {
            double u = (double)index / (double)(run->session_count - 1u) - 0.5;
            double fitted = run->trend.intercept_counts + run->trend.time_slope_counts * u;
            int x = 80 + (int)((double)index * 480.0 / (double)(run->session_count - 1u));
            int y = scale_y(fitted, low, high);
            if (fprintf(file, "%d,%d ", x, y) < 0) {
                (void)fclose(file);
                return 1;
            }
        }
        if (fputs("\"/>\n", file) < 0) {
            (void)fclose(file);
            return 1;
        }
    }
    for (size_t index = 0; index < run->session_count; ++index) {
        int x = 80;
        int y = scale_y(session_difference(&run->sessions[index]), low, high);
        if (run->session_count > 1u) {
            x = 80 + (int)((double)index * 480.0 / (double)(run->session_count - 1u));
        }
        if (fprintf(file, "<circle cx=\"%d\" cy=\"%d\" r=\"4\" fill=\"#c44900\"/>\n", x, y) < 0) {
            (void)fclose(file);
            return 1;
        }
    }
    if (fputs("</svg>\n", file) < 0) {
        (void)fclose(file);
        return 1;
    }
    return fclose(file) == 0 ? 0 : 1;
}

static int write_report(const char *directory,
    const struct run_record *runs,
    const char *whether,
    const char *sign_label,
    const char *span_label)
{
    char path[1024];
    FILE *file;
    const struct run_record *v3 = &runs[RUN_V3];
    if (snprintf(path, sizeof(path), "%s/report.md", directory) >= (int)sizeof(path)) {
        return 1;
    }
    file = fopen(path, "w");
    if (file == NULL) {
        return 1;
    }
    if (fprintf(file,
            "# v3 事后归因\n\n规则 `%s`。判定令牌 `%s`。"
            "引用值核对 `%s`。\n\n",
            RULE_ID,
            v3->present != 0 ? v3->token : "not_run",
            whether) < 0) {
        (void)fclose(file);
        return 1;
    }
    if (v3->present != 0 && v3->trend.defined != 0) {
        if (fprintf(file,
                "v3 密封主效应 %.17g 计数。线性截距 %.17g，斜率 %.17g。"
                "截距 Holm 拒绝 %s，斜率 Holm 拒绝 %s，前后半稳定 %s。\n\n",
                v3->has_decision_mean != 0 ? v3->decision_mean_counts : v3->trend.intercept_counts,
                v3->trend.intercept_counts,
                v3->trend.time_slope_counts,
                yes_no(v3->trend.holm_reject_intercept),
                yes_no(v3->trend.holm_reject_time),
                half_label(v3->half_stable)) < 0) {
            (void)fclose(file);
            return 1;
        }
    }
    if (strcmp(whether, "no") == 0) {
        if (fputs("v3 的会话均值差是稳定水平。前半与后半会话在预先声明的 Holm 族"
                  "（水平 0.01）中与全样本同号拒绝。居中的会话序号线性项不改变该均值估计。"
                  "按本规则，密封主效应不能由会话序号上的线性环境漂移解释。\n\n",
                file) < 0) {
            (void)fclose(file);
            return 1;
        }
    } else if (strcmp(whether, "partial") == 0) {
        if (fputs("v3 的前后半会话没有形成同号稳定拒绝，同时线性斜率在 Holm 族中被拒绝。"
                  "密封主效应里有一部分随会话序号变化。这是预先声明的部分漂移。\n\n",
                file) < 0) {
            (void)fclose(file);
            return 1;
        }
    } else if (strcmp(whether, "not_linear") == 0) {
        if (fputs("v3 的前后半会话没有形成同号稳定拒绝，线性斜率未被拒绝。"
                  "会话效应不稳定，线性时间趋势本身也不成立。\n\n",
                file) < 0) {
            (void)fclose(file);
            return 1;
        }
    } else if (strcmp(whether, "yes_pure_trend") == 0) {
        if (fputs("v3 的全样本均值与零兼容，线性斜率被拒绝。"
                  "密封主效应与一条均值接近零的会话序号趋势相容。\n\n",
                file) < 0) {
            (void)fclose(file);
            return 1;
        }
    } else if (strcmp(whether, "inconclusive") == 0) {
        if (fputs("v3 的均值检验与斜率检验在 Holm 族中都未拒绝。"
                  "本规则不把该密封主效应判成漂移，也不判成稳定水平。\n\n",
                file) < 0) {
            (void)fclose(file);
            return 1;
        }
    } else if (fputs("v3 主判定没有形成密封运行上的科学令牌。\n\n", file) < 0) {
        (void)fclose(file);
        return 1;
    }
    {
        const struct run_record *v1 = &runs[RUN_V1];
        const struct run_record *message = &runs[RUN_DEV_MESSAGE];
        double v1_mean = 0.0;
        double message_difference = 0.0;
        int v1_mean_defined = 0;
        int message_defined = 0;
        const char *v1_slope_reject = "na";
        const char *v3_slope_reject = "na";
        if (v1->present != 0 && v1->has_decision_mean != 0) {
            v1_mean = v1->decision_mean_counts;
            v1_mean_defined = 1;
        } else if (v1->present != 0 && v1->trend.defined != 0) {
            v1_mean = v1->trend.intercept_counts;
            v1_mean_defined = 1;
        }
        if (message->present != 0 && message->session_count > 0u) {
            message_difference = session_difference(&message->sessions[0]);
            message_defined = 1;
        }
        if (v1->trend.defined != 0) {
            v1_slope_reject = yes_no(v1->trend.holm_reject_time);
        }
        if (v3->trend.defined != 0) {
            v3_slope_reject = yes_no(v3->trend.holm_reject_time);
        }
        if (fprintf(file,
                "v2 与 v3 的逐次原始表和空窗序列不在封存目录中。"
                "会话内分段、调用序号上的时钟斜率，以及空窗中位数回归只对本地封存了原始表的"
                " v1 和 90210 计算。缺失不记为漂移成立，也不记为漂移排除。"
                "v3 的会话内时钟状态是 `%s`。\n\n"
                "方向反转 `sign_reversal=%s`。它比较 v1 决策主效应、90210 message 单会话效应"
                "与 v3 决策主效应的符号。线性跨度 `reversal_within_run_span=%s`。"
                "该比较只看两条斜率绝对值之和是否盖住两个截距之差，不是斜率的显著性检验，"
                "也不改写 v3 的主判定令牌。v1 斜率 Holm 拒绝 %s，v3 斜率 Holm 拒绝 %s。\n\n",
                v3->clock_explains,
                sign_label,
                span_label,
                v1_slope_reject,
                v3_slope_reject) < 0) {
            (void)fclose(file);
            return 1;
        }
        if (v1_mean_defined != 0) {
            if (fprintf(file,
                    "v1 的上下文令牌是 `%s`，决策主效应 %.17g 计数，重算标记 `%s`，"
                    "会话内时钟 `%s`。\n\n",
                    v1->token,
                    v1_mean,
                    recompute_label(v1),
                    v1->clock_explains) < 0) {
                (void)fclose(file);
                return 1;
            }
        }
        if (message_defined != 0) {
            if (fprintf(file,
                    "90210 message 窗口只有一个会话，单会话效应 %.17g 计数，"
                    "重算标记 `%s`。这一窗不做会话序号回归。\n",
                    message_difference,
                    recompute_label(message)) < 0) {
                (void)fclose(file);
                return 1;
            }
        }
    }
    return fclose(file) == 0 ? 0 : 1;
}

static int write_stopped(const char *directory, const struct analysis_failure *failure)
{
    char path[1024];
    FILE *file;
    if (snprintf(path, sizeof(path), "%s/conclusion.txt", directory) >= (int)sizeof(path)) {
        return 1;
    }
    file = fopen(path, "w");
    if (file == NULL) {
        return 1;
    }
    if (write_both(file,
            stdout,
            "rule_id=%s\nrule_source=%s\nstatus=%s\nfailure_path=%s\n"
            "failure_detail=%s\n",
            RULE_ID,
            RULE_SOURCE,
            failure->status,
            failure->path,
            failure->detail) != 0) {
        (void)fclose(file);
        return 1;
    }
    if (failure->exit_code == 2) {
        if (write_both(file,
                stdout,
                "digest_expected=%s\ndigest_actual=%s\n",
                failure->expected_hash,
                failure->actual_hash) != 0) {
            (void)fclose(file);
            return 1;
        }
    }
    if (write_both(file,
            stdout,
            "v3_effect_explained_by_drift=not_run\n"
            "whether_minus_5_467_explained_by_drift=not_decided\n") != 0) {
        (void)fclose(file);
        return 1;
    }
    if (fclose(file) != 0) {
        return 1;
    }
    return 0;
}

static int write_success(const char *directory,
    const char *manifest_path,
    size_t entry_count,
    struct run_record *runs)
{
    char path[1024];
    FILE *file;
    const struct run_record *v3 = &runs[RUN_V3];
    const char *token = v3->present != 0 ? v3->token : "not_run";
    const char *whether = token;
    char rounded[64];
    double v3_mean = 0.0;
    int span_defined = 0;
    const char *span_label = "not_applicable";
    const char *sign_label = "not_applicable";
    if (snprintf(path, sizeof(path), "%s/conclusion.txt", directory) >= (int)sizeof(path)) {
        return 1;
    }
    file = fopen(path, "w");
    if (file == NULL) {
        return 1;
    }
    if (v3->present == 0 || strcmp(token, "not_run") == 0) {
        whether = "not_decided";
    }
    if (v3->present != 0 && v3->trend.defined != 0) {
        v3_mean =
            v3->has_decision_mean != 0 ? v3->decision_mean_counts : v3->trend.intercept_counts;
        if (snprintf(rounded, sizeof(rounded), "%.3f", v3_mean) < 0) {
            (void)fclose(file);
            return 1;
        }
        if (strcmp(rounded, "-5.467") != 0) {
            whether = "citation_not_matched";
        }
    } else if (strcmp(whether, "not_decided") != 0) {
        whether = "citation_not_matched";
    }
    if (runs[RUN_V1].present != 0 && runs[RUN_DEV_MESSAGE].present != 0 && v3->present != 0) {
        double message_mean = session_difference(&runs[RUN_DEV_MESSAGE].sessions[0]);
        double v1_mean = runs[RUN_V1].has_decision_mean ? runs[RUN_V1].decision_mean_counts
                                                        : runs[RUN_V1].trend.intercept_counts;
        int sign_v1 = sign_of(v1_mean);
        int sign_message = sign_of(message_mean);
        int sign_v3 = sign_of(v3_mean);
        sign_label = (sign_v1 == sign_message && sign_message == sign_v3) ? "no" : "yes";
    }
    if (runs[RUN_V1].trend.defined != 0 && v3->trend.defined != 0) {
        double span =
            fabs(runs[RUN_V1].trend.time_slope_counts) + fabs(v3->trend.time_slope_counts);
        double gap = fabs(runs[RUN_V1].trend.intercept_counts - v3->trend.intercept_counts);
        span_defined = 1;
        span_label = span >= gap ? "yes" : "no";
    }
    if (write_both(file,
            stdout,
            "rule_id=%s\nrule_source=%s\nstatus=ok\nmanifest=%s\ninput_count=%zu\n"
            "alpha_family=0.01\nalpha_control=holm\n"
            "holm_family=v3_intercept_and_time_slope\n"
            "stability_family=v3_first_half_and_second_half\n"
            "analysis_unit=session\n"
            "effect_definition=message_zero_mean_minus_message_ones_mean_clock_counts\n"
            "time_index=centered_unit_span\n",
            RULE_ID,
            RULE_SOURCE,
            manifest_path,
            entry_count) != 0) {
        (void)fclose(file);
        return 1;
    }
    if (write_both(file,
            stdout,
            "v3_effect_explained_by_drift=%s\n"
            "whether_minus_5_467_explained_by_drift=%s\n",
            token,
            whether) != 0) {
        (void)fclose(file);
        return 1;
    }
    if (v3->present != 0 && v3->trend.defined != 0) {
        if (write_both(file,
                stdout,
                "v3_primary_mean_counts=%.17g\nv3_intercept_counts=%.17g\n"
                "v3_time_slope_counts=%.17g\nv3_half_stable=%s\n",
                v3_mean,
                v3->trend.intercept_counts,
                v3->trend.time_slope_counts,
                half_label(v3->half_stable)) != 0) {
            (void)fclose(file);
            return 1;
        }
    }
    if (runs[RUN_V3].empty_max_defined != 0) {
        if (write_both(file,
                stdout,
                "v3_empty_window_max_counts=%llu\n"
                "v3_empty_window_series=absent\n",
                runs[RUN_V3].empty_max_counts) != 0) {
            (void)fclose(file);
            return 1;
        }
    }
    if (write_both(file,
            stdout,
            "v3_within_session_clock=%s\nsign_reversal=%s\n"
            "reversal_within_run_span=%s\n",
            v3->clock_explains,
            sign_label,
            span_defined != 0 ? span_label : "not_applicable") != 0) {
        (void)fclose(file);
        return 1;
    }
    for (int run_index = 0; run_index < (int)RUN_COUNT; ++run_index) {
        if (write_run_block(file, stdout, &runs[run_index]) != 0) {
            (void)fclose(file);
            return 1;
        }
        if (write_session_table(directory, &runs[run_index]) != 0 ||
            write_svg(directory, &runs[run_index]) != 0) {
            (void)fclose(file);
            return 1;
        }
    }
    if (write_report(directory,
            runs,
            whether,
            sign_label,
            span_defined != 0 ? span_label : "not_applicable") != 0 ||
        fclose(file) != 0) {
        return 1;
    }
    return 0;
}

static void initialize_runs(struct run_record *runs)
{
    memset(runs, 0, sizeof(struct run_record) * RUN_COUNT);
    runs[RUN_V1].name = "v1";
    runs[RUN_V2].name = "v2";
    runs[RUN_V3].name = "v3";
    runs[RUN_DEV_BEFORE].name = "dev_before";
    runs[RUN_DEV_MESSAGE].name = "dev_message";
    for (int run_index = 0; run_index < (int)RUN_COUNT; ++run_index) {
        runs[run_index].token = "not_run";
        runs[run_index].clock_explains = "not_applicable";
        runs[run_index].half_stable = -1;
    }
}

static int dispatch_entry(struct run_record *runs,
    const struct manifest_entry *entry,
    struct analysis_failure *failure)
{
    int run_index = 0;
    if (role_run(entry->role, &run_index) != 0) {
        set_failure(failure, 3, "stopped_identity_mismatch", entry->path, "role");
        return 1;
    }
    if (strncmp(entry->role, "decision:", 9) == 0) {
        return load_decision(&runs[run_index], entry->path, failure);
    }
    if (strcmp(entry->role, "protocol:v2") == 0) {
        return load_protocol(entry->path, "confirmation_seeds=8675309", failure);
    }
    if (strcmp(entry->role, "protocol:v3") == 0) {
        return load_protocol(entry->path, "confirmation_seeds=31415926", failure);
    }
    if (strcmp(entry->role, "csv:v1") == 0) {
        return load_csv(&runs[run_index], entry->path, 1, failure);
    }
    if (strncmp(entry->role, "csv:", 4) == 0) {
        return load_csv(&runs[run_index], entry->path, 0, failure);
    }
    if (strncmp(entry->role, "empty:", 6) == 0) {
        return load_empty(&runs[run_index], entry->path, failure);
    }
    if (strcmp(entry->role, "meta:v1") == 0) {
        const char *anchors[] = {"seed=20261111",
            "run_id=ryzen-vulnerable",
            "message-zero_count=1000",
            "message-ones_count=1000",
            "empty_window_count=256"};
        return load_meta(&runs[run_index], entry->path, anchors, 5u, 1, failure);
    }
    if (strcmp(entry->role, "meta:v3") == 0) {
        const char *anchors[] = {"seed=31415926",
            "run_id=v3-vulnerable",
            "empty_window_count=256",
            "message-zero_count=5000",
            "message-ones_count=5000",
            "message-zero_unique_ciphertexts=1",
            "message-ones_unique_ciphertexts=1"};
        return load_meta(&runs[run_index], entry->path, anchors, 7u, 1, failure);
    }
    if (strcmp(entry->role, "meta:dev_before") == 0) {
        const char *anchors[] = {"seed=90210",
            "run_id=dev-window-90210",
            "message-zero_count=200",
            "message-ones_count=200"};
        return load_meta(&runs[run_index], entry->path, anchors, 4u, 0, failure);
    }
    if (strcmp(entry->role, "meta:dev_message") == 0) {
        const char *anchors[] = {"seed=90210",
            "run_id=dev-window-90210-message",
            "message-zero_count=200",
            "message-ones_count=200"};
        return load_meta(&runs[run_index], entry->path, anchors, 4u, 0, failure);
    }
    set_failure(failure, 3, "stopped_identity_mismatch", entry->path, "role");
    return 1;
}

int main(int argc, char **argv)
{
    int expect_sealed = 0;
    const char *manifest_path;
    const char *output_directory;
    struct manifest_entry entries[MANIFEST_CAPACITY];
    size_t entry_count = 0u;
    struct run_record runs[RUN_COUNT];
    struct analysis_failure failure;
    struct stat directory_info;
    memset(&failure, 0, sizeof(failure));
    failure.status = "ok";
    if (argc == 2 && strcmp(argv[1], "--self-check") == 0) {
        return sha256_self_check();
    }
    if (argc == 4 && strcmp(argv[1], "--expect-sealed") == 0) {
        expect_sealed = 1;
        manifest_path = argv[2];
        output_directory = argv[3];
    } else if (argc == 3) {
        manifest_path = argv[1];
        output_directory = argv[2];
    } else {
        fputs("usage: attribution_v3 --self-check\n"
              "       attribution_v3 [--expect-sealed] MANIFEST OUTPUT_DIR\n",
            stderr);
        return 1;
    }
    if (stat(output_directory, &directory_info) != 0 || S_ISDIR(directory_info.st_mode) == 0) {
        fputs("output directory is missing\n", stderr);
        return 1;
    }
    initialize_runs(runs);
    if (load_manifest(manifest_path, entries, &entry_count, &failure) != 0 ||
        verify_hashes(entries, entry_count, &failure) != 0 ||
        (expect_sealed != 0 && check_sealed_roles(entries, entry_count, &failure) != 0)) {
        return write_stopped(output_directory, &failure) == 0 ? failure.exit_code : 1;
    }
    for (size_t index = 0; index < entry_count; ++index) {
        if (strncmp(entries[index].role, "decision:", 9) == 0 &&
            dispatch_entry(runs, &entries[index], &failure) != 0) {
            return write_stopped(output_directory, &failure) == 0 ? failure.exit_code : 1;
        }
    }
    for (size_t index = 0; index < entry_count; ++index) {
        if (strncmp(entries[index].role, "decision:", 9) != 0 &&
            dispatch_entry(runs, &entries[index], &failure) != 0) {
            return write_stopped(output_directory, &failure) == 0 ? failure.exit_code : 1;
        }
    }
    if (ensure_contiguous(runs, &failure) != 0 || cross_check(runs, &failure) != 0 ||
        (expect_sealed != 0 && check_sealed_population(runs, &failure) != 0)) {
        return write_stopped(output_directory, &failure) == 0 ? failure.exit_code : 1;
    }
    for (int run_index = 0; run_index < (int)RUN_COUNT; ++run_index) {
        analyze_run(&runs[run_index]);
    }
    if (write_success(output_directory, manifest_path, entry_count, runs) != 0) {
        return 1;
    }
    return 0;
}
