#define _GNU_SOURCE
#define _POSIX_C_SOURCE 200809L

#include <errno.h>
#include <inttypes.h>
#include <stdatomic.h>
#include <stdbool.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/types.h>
#include <sys/utsname.h>
#include <time.h>
#include <unistd.h>

#if defined(__linux__) && defined(__x86_64__)
#include <sched.h>
#define HAS_RAW_CALIBRATION 1
#else
#define HAS_RAW_CALIBRATION 0
#endif

#define NANOSECONDS_PER_SECOND UINT64_C(1000000000)
#define WARMUP_PAIR_COUNT 1000U
#define MAIN_PAIR_COUNT 100000U
#define PAIR_CAPACITY (WARMUP_PAIR_COUNT + MAIN_PAIR_COUNT)
#define TARGET_CPU 2U
#define CLOCKSOURCE_CAPACITY 256U
#define JSON_TEXT_CAPACITY (6U * CLOCKSOURCE_CAPACITY + 3U)
#define CSV_ROW_CAPACITY 512U

/* 以下时钟结构和五个helper沿用固定G2源，保持读后转换的边界。 */
struct clock_reading {
    bool has_timespec;
    bool has_value;
    uint64_t value_ns;
    time_t seconds;
    long fractional_ns;
    int error_number;
};

struct pair_record {
    struct clock_reading before;
    struct clock_reading after;
    bool before_attempted;
    bool after_attempted;
};

_Static_assert(PAIR_CAPACITY <= SIZE_MAX / sizeof(struct pair_record), "pair allocation fits");

static bool timespec_to_nanoseconds(time_t seconds, long fractional_ns, uint64_t *value_ns)
{
    if (seconds < 0 || fractional_ns < 0 || fractional_ns >= (long)NANOSECONDS_PER_SECOND ||
        (uintmax_t)seconds > UINT64_MAX / NANOSECONDS_PER_SECOND) {
        return false;
    }
    uint64_t seconds_ns = (uint64_t)seconds * NANOSECONDS_PER_SECOND;
    if ((uint64_t)fractional_ns > UINT64_MAX - seconds_ns) {
        return false;
    }
    *value_ns = seconds_ns + (uint64_t)fractional_ns;
    return true;
}

static bool clock_span_is_valid(const struct clock_reading *before,
    const struct clock_reading *after)
{
    return before->has_value && after->has_value && before->error_number == 0 &&
        after->error_number == 0 && after->value_ns >= before->value_ns;
}

static void check_clock_order(struct clock_reading *current, struct clock_reading *previous)
{
    if (current->has_value) {
        if (previous->has_value && current->value_ns < previous->value_ns) {
            current->error_number = ERANGE;
        }
        *previous = *current;
    }
}

#if HAS_RAW_CALIBRATION
static struct clock_reading read_clock_timespec(clockid_t clock_id)
{
    struct clock_reading result = {0};
    struct timespec clock_value = {0};
    if (clock_gettime(clock_id, &clock_value) != 0) {
        result.error_number = errno;
        return result;
    }
    result.has_timespec = true;
    result.seconds = clock_value.tv_sec;
    result.fractional_ns = clock_value.tv_nsec;
    return result;
}
#endif

static void convert_clock_reading(struct clock_reading *result)
{
    if (result->has_timespec) {
        result->has_value =
            timespec_to_nanoseconds(result->seconds, result->fractional_ns, &result->value_ns);
        if (!result->has_value) {
            result->error_number = EOVERFLOW;
        }
    }
}

static bool has_pair_space(size_t record_count)
{
    return record_count < PAIR_CAPACITY;
}

static const char *phase_for_pair(size_t record_index)
{
    return record_index < WARMUP_PAIR_COUNT ? "warmup" : "main";
}

static bool format_clock_csv(char *output,
    size_t capacity,
    bool was_attempted,
    const struct clock_reading *reading)
{
    int written;
    if (!was_attempted) {
        written = snprintf(output, capacity, "0,0,null,null,null,null");
    } else if (!reading->has_timespec) {
        written = snprintf(output, capacity, "1,0,null,null,null,%d", reading->error_number);
    } else if (!reading->has_value) {
        written = snprintf(output,
            capacity,
            "1,1,%jd,%ld,null,%d",
            (intmax_t)reading->seconds,
            reading->fractional_ns,
            reading->error_number);
    } else {
        written = snprintf(output,
            capacity,
            "1,1,%jd,%ld,%" PRIu64 ",%d",
            (intmax_t)reading->seconds,
            reading->fractional_ns,
            reading->value_ns,
            reading->error_number);
    }
    return written >= 0 && (size_t)written < capacity;
}

static bool format_pair_csv(char *output,
    size_t capacity,
    size_t record_index,
    const struct pair_record *record)
{
    char before_text[192];
    char after_text[192];
    char elapsed_text[24] = "null";
    if (!format_clock_csv(before_text,
            sizeof(before_text),
            record->before_attempted,
            &record->before) ||
        !format_clock_csv(after_text,
            sizeof(after_text),
            record->after_attempted,
            &record->after)) {
        return false;
    }
    if (record->before_attempted && record->after_attempted &&
        clock_span_is_valid(&record->before, &record->after)) {
        int written = snprintf(elapsed_text,
            sizeof(elapsed_text),
            "%" PRIu64,
            record->after.value_ns - record->before.value_ns);
        if (written < 0 || (size_t)written >= sizeof(elapsed_text)) {
            return false;
        }
    }
    int written = snprintf(output,
        capacity,
        "%zu,%s,%s,%s,%s\n",
        record_index,
        phase_for_pair(record_index),
        before_text,
        after_text,
        elapsed_text);
    return written >= 0 && (size_t)written < capacity;
}

static bool format_json_string(char *output, size_t capacity, const char *input)
{
    static const char hex_digits[] = "0123456789abcdef";
    size_t output_count = 0;
    if (capacity < 3U) {
        return false;
    }
    output[output_count++] = '"';
    for (size_t input_index = 0; input[input_index] != '\0'; ++input_index) {
        unsigned char character = (unsigned char)input[input_index];
        size_t encoded_size =
            character < 0x20U ? 6U : (character == '"' || character == '\\' ? 2U : 1U);
        if (encoded_size > capacity - output_count - 2U) {
            return false;
        }
        if (character < 0x20U) {
            output[output_count++] = '\\';
            output[output_count++] = 'u';
            output[output_count++] = '0';
            output[output_count++] = '0';
            output[output_count++] = hex_digits[character >> 4];
            output[output_count++] = hex_digits[character & 0x0fU];
        } else {
            if (character == '"' || character == '\\') {
                output[output_count++] = '\\';
            }
            output[output_count++] = (char)character;
        }
    }
    output[output_count++] = '"';
    output[output_count] = '\0';
    return true;
}

#if HAS_RAW_CALIBRATION
struct environment_snapshot {
    struct clock_reading resolution;
    char clocksource[CLOCKSOURCE_CAPACITY];
    cpu_set_t affinity;
    int clocksource_error_number;
    int affinity_error_number;
    int cpu_error_number;
    int observed_cpu;
    bool was_attempted;
    bool has_clocksource;
    bool has_affinity;
    bool has_cpu;
};

struct calibration_state {
    struct pair_record *records;
    struct clock_reading previous_raw_clock;
    struct environment_snapshot before;
    struct environment_snapshot after;
    struct utsname system_identity;
    cpu_set_t original_affinity;
    size_t record_count;
    size_t valid_warmup_count;
    size_t valid_main_count;
    const char *stop_reason;
    int stop_error_number;
    int uname_error_number;
    int original_affinity_error_number;
    int set_affinity_error_number;
    bool has_system_identity;
    bool has_original_affinity;
};

static void stop_collection(struct calibration_state *state, const char *reason, int error_number)
{
    if (strcmp(state->stop_reason, "not_started") == 0 ||
        strcmp(state->stop_reason, "completed") == 0) {
        state->stop_reason = reason;
        state->stop_error_number = error_number;
    }
}

static void read_clocksource(struct environment_snapshot *snapshot)
{
    FILE *source_file =
        fopen("/sys/devices/system/clocksource/clocksource0/current_clocksource", "r");
    if (source_file == NULL) {
        snapshot->clocksource_error_number = errno;
        return;
    }
    size_t byte_count =
        fread(snapshot->clocksource, 1U, sizeof(snapshot->clocksource), source_file);
    int saved_error_number = ferror(source_file) ? (errno == 0 ? EIO : errno) : 0;
    if (fclose(source_file) != 0 && saved_error_number == 0) {
        saved_error_number = errno == 0 ? EIO : errno;
    }
    if (byte_count == 0U || byte_count == sizeof(snapshot->clocksource)) {
        snapshot->clocksource_error_number = saved_error_number != 0 ? saved_error_number : EIO;
        return;
    }
    if (snapshot->clocksource[byte_count - 1U] == '\n') {
        --byte_count;
    }
    if (saved_error_number != 0 || byte_count == 0U ||
        memchr(snapshot->clocksource, '\0', byte_count) != NULL) {
        snapshot->clocksource_error_number = saved_error_number != 0 ? saved_error_number : EIO;
        return;
    }
    snapshot->clocksource[byte_count] = '\0';
    snapshot->has_clocksource = true;
}

static void capture_environment(struct environment_snapshot *snapshot)
{
    snapshot->was_attempted = true;
    read_clocksource(snapshot);
    struct timespec resolution = {0};
    if (clock_getres(CLOCK_MONOTONIC_RAW, &resolution) != 0) {
        snapshot->resolution.error_number = errno;
    } else {
        snapshot->resolution.has_timespec = true;
        snapshot->resolution.seconds = resolution.tv_sec;
        snapshot->resolution.fractional_ns = resolution.tv_nsec;
        convert_clock_reading(&snapshot->resolution);
    }
    CPU_ZERO(&snapshot->affinity);
    if (sched_getaffinity(0, sizeof(snapshot->affinity), &snapshot->affinity) != 0) {
        snapshot->affinity_error_number = errno;
    } else {
        snapshot->has_affinity = true;
    }
    snapshot->observed_cpu = sched_getcpu();
    if (snapshot->observed_cpu < 0) {
        snapshot->cpu_error_number = errno;
    } else {
        snapshot->has_cpu = true;
    }
}

static bool target_cpu_is_verified(const struct environment_snapshot *snapshot)
{
    return snapshot->has_affinity && CPU_COUNT(&snapshot->affinity) == 1 &&
        CPU_ISSET(TARGET_CPU, &snapshot->affinity) && snapshot->has_cpu &&
        snapshot->observed_cpu == (int)TARGET_CPU;
}

static bool environment_is_valid(const struct environment_snapshot *snapshot)
{
    return snapshot->has_clocksource && snapshot->resolution.has_value &&
        snapshot->resolution.error_number == 0 && target_cpu_is_verified(snapshot);
}

static int environment_error_number(const struct environment_snapshot *snapshot)
{
    if (snapshot->clocksource_error_number != 0) {
        return snapshot->clocksource_error_number;
    }
    if (snapshot->resolution.error_number != 0) {
        return snapshot->resolution.error_number;
    }
    if (snapshot->affinity_error_number != 0) {
        return snapshot->affinity_error_number;
    }
    if (snapshot->cpu_error_number != 0) {
        return snapshot->cpu_error_number;
    }
    return EXDEV;
}

static bool prepare_collection(struct calibration_state *state)
{
    if (uname(&state->system_identity) != 0) {
        state->uname_error_number = errno;
        stop_collection(state, "uname_error", state->uname_error_number);
        return false;
    }
    state->has_system_identity = true;
    CPU_ZERO(&state->original_affinity);
    if (sched_getaffinity(0, sizeof(state->original_affinity), &state->original_affinity) != 0) {
        state->original_affinity_error_number = errno;
        stop_collection(state, "original_affinity_error", state->original_affinity_error_number);
        return false;
    }
    state->has_original_affinity = true;
    cpu_set_t requested;
    CPU_ZERO(&requested);
    CPU_SET(TARGET_CPU, &requested);
    if (sched_setaffinity(0, sizeof(requested), &requested) != 0) {
        state->set_affinity_error_number = errno;
        stop_collection(state, "set_affinity_error", state->set_affinity_error_number);
        return false;
    }
    state->records = calloc(PAIR_CAPACITY, sizeof(*state->records));
    if (state->records == NULL) {
        stop_collection(state, "allocation_error", errno == 0 ? ENOMEM : errno);
        return false;
    }
    errno = 0;
    long page_size = sysconf(_SC_PAGESIZE);
    if (page_size <= 0) {
        stop_collection(state, "page_size_error", errno == 0 ? EIO : errno);
        return false;
    }
    size_t allocation_bytes = (size_t)PAIR_CAPACITY * sizeof(*state->records);
    volatile unsigned char *record_bytes = (volatile unsigned char *)state->records;
    for (size_t byte_offset = 0; byte_offset < allocation_bytes; byte_offset += (size_t)page_size) {
        record_bytes[byte_offset] = 0;
    }
    record_bytes[allocation_bytes - 1U] = 0;
    capture_environment(&state->before);
    if (!environment_is_valid(&state->before)) {
        stop_collection(state,
            "before_environment_error",
            environment_error_number(&state->before));
        return false;
    }
    return true;
}

static bool record_empty_pair(struct calibration_state *state)
{
    if (!has_pair_space(state->record_count)) {
        stop_collection(state, "pair_capacity_error", EOVERFLOW);
        return false;
    }
    struct pair_record *record = &state->records[state->record_count++];
    record->before_attempted = true;
    record->before = read_clock_timespec(CLOCK_MONOTONIC_RAW);
    if (!record->before.has_timespec) {
        stop_collection(state, "before_clock_error", record->before.error_number);
        return false;
    }
    atomic_signal_fence(memory_order_seq_cst);
    atomic_signal_fence(memory_order_seq_cst);
    record->after = read_clock_timespec(CLOCK_MONOTONIC_RAW);
    record->after_attempted = true;
    convert_clock_reading(&record->before);
    convert_clock_reading(&record->after);
    check_clock_order(&record->before, &state->previous_raw_clock);
    check_clock_order(&record->after, &state->previous_raw_clock);
    if (!clock_span_is_valid(&record->before, &record->after)) {
        stop_collection(state,
            "clock_span_error",
            record->before.error_number != 0 ? record->before.error_number
                                             : record->after.error_number);
        return false;
    }
    if (state->record_count <= WARMUP_PAIR_COUNT) {
        ++state->valid_warmup_count;
    } else {
        ++state->valid_main_count;
    }
    return true;
}

static void collect_pairs(struct calibration_state *state)
{
    if (prepare_collection(state)) {
        while (has_pair_space(state->record_count)) {
            if (!record_empty_pair(state)) {
                break;
            }
        }
        if (state->valid_warmup_count == WARMUP_PAIR_COUNT &&
            state->valid_main_count == MAIN_PAIR_COUNT) {
            state->stop_reason = "completed";
        }
    }
    capture_environment(&state->after);
    if (!environment_is_valid(&state->after)) {
        stop_collection(state, "after_environment_error", environment_error_number(&state->after));
    } else if (state->before.has_clocksource &&
        (strcmp(state->before.clocksource, state->after.clocksource) != 0 ||
            state->before.resolution.has_value != state->after.resolution.has_value ||
            state->before.resolution.value_ns != state->after.resolution.value_ns)) {
        stop_collection(state, "environment_changed", EXDEV);
    }
}

static bool output_affinity(bool has_affinity, const cpu_set_t *affinity)
{
    if (!has_affinity) {
        return fputs("null", stderr) >= 0;
    }
    if (fputc('[', stderr) == EOF) {
        return false;
    }
    bool has_cpu_output = false;
    for (unsigned int cpu_index = 0; cpu_index < CPU_SETSIZE; ++cpu_index) {
        if (CPU_ISSET(cpu_index, affinity)) {
            if (fprintf(stderr, "%s%u", has_cpu_output ? "," : "", cpu_index) < 0) {
                return false;
            }
            has_cpu_output = true;
        }
    }
    return fputc(']', stderr) != EOF;
}

static bool output_environment(const struct environment_snapshot *snapshot)
{
    if (!snapshot->was_attempted) {
        return fputs("null", stderr) >= 0;
    }
    char clocksource_text[JSON_TEXT_CAPACITY];
    if (snapshot->has_clocksource &&
        !format_json_string(clocksource_text, sizeof(clocksource_text), snapshot->clocksource)) {
        return false;
    }
    if (fprintf(stderr,
            "{\"clocksource\":%s,\"clocksource_errno\":%d,\"resolution_has_timespec\":%s,"
            "\"resolution_seconds\":",
            snapshot->has_clocksource ? clocksource_text : "null",
            snapshot->clocksource_error_number,
            snapshot->resolution.has_timespec ? "true" : "false") < 0) {
        return false;
    }
    if (snapshot->resolution.has_timespec) {
        if (fprintf(stderr,
                "%jd,\"resolution_fractional_ns\":%ld,\"resolution_ns\":",
                (intmax_t)snapshot->resolution.seconds,
                snapshot->resolution.fractional_ns) < 0) {
            return false;
        }
    } else if (fputs("null,\"resolution_fractional_ns\":null,\"resolution_ns\":", stderr) < 0) {
        return false;
    }
    if (snapshot->resolution.has_value) {
        if (fprintf(stderr, "%" PRIu64, snapshot->resolution.value_ns) < 0) {
            return false;
        }
    } else if (fputs("null", stderr) < 0) {
        return false;
    }
    if (fprintf(stderr,
            ",\"resolution_errno\":%d,\"affinity\":",
            snapshot->resolution.error_number) < 0 ||
        !output_affinity(snapshot->has_affinity, &snapshot->affinity) ||
        fprintf(stderr,
            ",\"affinity_errno\":%d,\"observed_cpu\":",
            snapshot->affinity_error_number) < 0) {
        return false;
    }
    if (snapshot->has_cpu) {
        if (fprintf(stderr, "%d", snapshot->observed_cpu) < 0) {
            return false;
        }
    } else if (fputs("null", stderr) < 0) {
        return false;
    }
    return fprintf(stderr,
               ",\"cpu_errno\":%d,\"cpu2_check\":%s}",
               snapshot->cpu_error_number,
               target_cpu_is_verified(snapshot) ? "true" : "false") >= 0;
}

static bool output_metadata(const struct calibration_state *state)
{
    char sysname_text[JSON_TEXT_CAPACITY];
    char nodename_text[JSON_TEXT_CAPACITY];
    char release_text[JSON_TEXT_CAPACITY];
    char version_text[JSON_TEXT_CAPACITY];
    char machine_text[JSON_TEXT_CAPACITY];
    if (!format_json_string(sysname_text, sizeof(sysname_text), state->system_identity.sysname) ||
        !format_json_string(nodename_text,
            sizeof(nodename_text),
            state->system_identity.nodename) ||
        !format_json_string(release_text, sizeof(release_text), state->system_identity.release) ||
        !format_json_string(version_text, sizeof(version_text), state->system_identity.version) ||
        !format_json_string(machine_text, sizeof(machine_text), state->system_identity.machine)) {
        return false;
    }
    bool completed = strcmp(state->stop_reason, "completed") == 0;
    if (fprintf(stderr,
            "{\"contract\":\"raw-empty-pair-v1\",\"clock\":\"CLOCK_MONOTONIC_RAW\","
            "\"pid\":%jd,\"uid\":%ju,\"effective_uid\":%ju,\"uname\":",
            (intmax_t)getpid(),
            (uintmax_t)getuid(),
            (uintmax_t)geteuid()) < 0) {
        return false;
    }
    if (state->has_system_identity) {
        if (fprintf(stderr,
                "{\"sysname\":%s,\"nodename\":%s,\"release\":%s,\"version\":%s,\"machine\":%s}",
                sysname_text,
                nodename_text,
                release_text,
                version_text,
                machine_text) < 0) {
            return false;
        }
    } else if (fputs("null", stderr) < 0) {
        return false;
    }
    if (fprintf(stderr,
            ",\"uname_errno\":%d,\"target_cpu\":%u,\"original_affinity\":",
            state->uname_error_number,
            TARGET_CPU) < 0 ||
        !output_affinity(state->has_original_affinity, &state->original_affinity) ||
        fprintf(stderr,
            ",\"original_affinity_errno\":%d,\"set_affinity_errno\":%d,\"before\":",
            state->original_affinity_error_number,
            state->set_affinity_error_number) < 0 ||
        !output_environment(&state->before) || fputs(",\"after\":", stderr) < 0 ||
        !output_environment(&state->after)) {
        return false;
    }
    return fprintf(stderr,
               ",\"planned_warmup_pairs\":%u,\"planned_main_pairs\":%u,\"record_count\":%zu,"
               "\"valid_warmup_pairs\":%zu,\"valid_main_pairs\":%zu,\"stop_reason\":\"%s\","
               "\"stop_errno\":%d,\"partial_unknown\":%s,\"configuration_writes\":0,"
               "\"self_affinity_set\":%s}\n",
               WARMUP_PAIR_COUNT,
               MAIN_PAIR_COUNT,
               state->record_count,
               state->valid_warmup_count,
               state->valid_main_count,
               state->stop_reason,
               state->stop_error_number,
               completed ? "false" : "true",
               state->has_original_affinity && state->set_affinity_error_number == 0
                   ? "true"
                   : "false") >= 0 &&
        fflush(stderr) == 0 && !ferror(stderr);
}

static bool output_records(struct calibration_state *state)
{
    bool output_ok =
        fputs("index,phase,before_attempted,before_has_timespec,before_seconds,"
              "before_fractional_ns,before_ns,before_errno,after_attempted,"
              "after_has_timespec,after_seconds,after_fractional_ns,after_ns,after_errno,"
              "elapsed_ns\n",
            stdout) >= 0;
    char row_text[CSV_ROW_CAPACITY];
    for (size_t record_index = 0; output_ok && record_index < state->record_count; ++record_index) {
        if (!format_pair_csv(row_text,
                sizeof(row_text),
                record_index,
                &state->records[record_index])) {
            stop_collection(state, "csv_format_error", EOVERFLOW);
            output_ok = false;
        } else if (fputs(row_text, stdout) < 0) {
            stop_collection(state, "stdout_error", errno == 0 ? EIO : errno);
            output_ok = false;
        }
    }
    if (fflush(stdout) != 0 || ferror(stdout)) {
        stop_collection(state, "stdout_error", errno == 0 ? EIO : errno);
        output_ok = false;
    }
    if (fclose(stdout) != 0) {
        stop_collection(state, "stdout_close_error", errno == 0 ? EIO : errno);
        output_ok = false;
    }
    if (!output_ok) {
        stop_collection(state, "stdout_error", EIO);
    }
    return output_ok;
}

static int run_collection(void)
{
    struct calibration_state state = {.stop_reason = "not_started"};
    collect_pairs(&state);
    bool records_ok = output_records(&state);
    bool metadata_ok = output_metadata(&state);
    if (fclose(stderr) != 0) {
        metadata_ok = false;
    }
    bool completed = strcmp(state.stop_reason, "completed") == 0;
    free(state.records);
    return records_ok && metadata_ok && completed ? 0 : 1;
}
#endif

static bool selfcheck(void)
{
    uint64_t value_ns = UINT64_C(123);
    if (!timespec_to_nanoseconds(0, 0, &value_ns) || value_ns != 0 ||
        !timespec_to_nanoseconds(1, 999999999L, &value_ns) || value_ns != UINT64_C(1999999999) ||
        timespec_to_nanoseconds(-1, 0, &value_ns) || timespec_to_nanoseconds(0, -1, &value_ns) ||
        timespec_to_nanoseconds(0, 1000000000L, &value_ns)) {
        return false;
    }
    time_t limit_seconds = (time_t)(UINT64_MAX / NANOSECONDS_PER_SECOND);
    long limit_fractional_ns = (long)(UINT64_MAX % NANOSECONDS_PER_SECOND);
    if (!timespec_to_nanoseconds(limit_seconds, limit_fractional_ns, &value_ns) ||
        value_ns != UINT64_MAX ||
        timespec_to_nanoseconds(limit_seconds, limit_fractional_ns + 1L, &value_ns) ||
        timespec_to_nanoseconds(limit_seconds + 1, 0, &value_ns)) {
        return false;
    }
    struct clock_reading before = {.has_timespec = true, .has_value = true, .value_ns = 1};
    struct clock_reading after = {.has_timespec = true, .has_value = true, .value_ns = 2};
    if (!clock_span_is_valid(&before, &after) || clock_span_is_valid(&after, &before) ||
        !clock_span_is_valid(&before, &before)) {
        return false;
    }
    after.has_value = false;
    if (clock_span_is_valid(&before, &after)) {
        return false;
    }
    after.has_value = true;
    after.error_number = EIO;
    if (clock_span_is_valid(&before, &after)) {
        return false;
    }
    after.error_number = 0;
    struct clock_reading previous = after;
    check_clock_order(&before, &previous);
    if (before.error_number != ERANGE || before.value_ns != 1 || previous.value_ns != 1 ||
        clock_span_is_valid(&before, &after)) {
        return false;
    }
    struct clock_reading converted = {.has_timespec = true, .seconds = 1, .fractional_ns = 2};
    convert_clock_reading(&converted);
    if (!converted.has_value || converted.value_ns != UINT64_C(1000000002) ||
        converted.error_number != 0) {
        return false;
    }
    converted = (struct clock_reading){.has_timespec = true, .seconds = -1, .fractional_ns = 0};
    convert_clock_reading(&converted);
    if (converted.has_value || converted.error_number != EOVERFLOW || converted.seconds != -1 ||
        converted.fractional_ns != 0) {
        return false;
    }
    converted = (struct clock_reading){.error_number = EIO};
    convert_clock_reading(&converted);
    if (converted.has_value || converted.has_timespec || converted.error_number != EIO ||
        !has_pair_space(PAIR_CAPACITY - 1U) || has_pair_space(PAIR_CAPACITY) ||
        has_pair_space(SIZE_MAX) || strcmp(phase_for_pair(0), "warmup") != 0 ||
        strcmp(phase_for_pair(WARMUP_PAIR_COUNT - 1U), "warmup") != 0 ||
        strcmp(phase_for_pair(WARMUP_PAIR_COUNT), "main") != 0 ||
        strcmp(phase_for_pair(PAIR_CAPACITY - 1U), "main") != 0) {
        return false;
    }
    char row_text[CSV_ROW_CAPACITY];
    struct pair_record record = {.before = {.error_number = 71}, .before_attempted = true};
    if (!format_pair_csv(row_text, sizeof(row_text), 0, &record) ||
        strcmp(row_text, "0,warmup,1,0,null,null,null,71,0,0,null,null,null,null,null\n") != 0) {
        return false;
    }
    record = (struct pair_record){.before = {.has_timespec = true, .has_value = true},
        .after = {.has_timespec = true, .has_value = true},
        .before_attempted = true,
        .after_attempted = true};
    if (!format_pair_csv(row_text, sizeof(row_text), WARMUP_PAIR_COUNT, &record) ||
        strcmp(row_text, "1000,main,1,1,0,0,0,0,1,1,0,0,0,0,0\n") != 0) {
        return false;
    }
    record.before = (struct clock_reading){.has_timespec = true,
        .seconds = -1,
        .fractional_ns = 7,
        .error_number = 71};
    record.after = (struct clock_reading){.error_number = 72};
    if (!format_pair_csv(row_text, sizeof(row_text), 1, &record) ||
        strcmp(row_text, "1,warmup,1,1,-1,7,null,71,1,0,null,null,null,72,null\n") != 0 ||
        format_pair_csv(row_text, 1U, 1, &record)) {
        return false;
    }
    char escaped_text[64];
    if (!format_json_string(escaped_text, sizeof(escaped_text), "a\"\\\n\t") ||
        strcmp(escaped_text, "\"a\\\"\\\\\\u000a\\u0009\"") != 0 ||
        format_json_string(escaped_text, 2U, "") || format_json_string(escaped_text, 3U, "a")) {
        return false;
    }
    return true;
}

int main(int argument_count, char **arguments)
{
    if (argument_count != 2) {
        return fputs("usage: raw_clock_calibration --selfcheck|--collect\n", stderr) >= 0 ? 2 : 1;
    }
    if (strcmp(arguments[1], "--selfcheck") == 0) {
        bool passed = selfcheck();
        if (fputs(passed ? "raw_clock_calibration selfcheck: passed\n"
                         : "raw_clock_calibration selfcheck: failed\n",
                stdout) < 0 ||
            fflush(stdout) != 0 || ferror(stdout)) {
            return 1;
        }
        return passed ? 0 : 1;
    }
    if (strcmp(arguments[1], "--collect") != 0) {
        return fputs("unsupported argument\n", stderr) >= 0 ? 2 : 1;
    }
#if HAS_RAW_CALIBRATION
    return run_collection();
#else
    return fputs("unsupported: collection requires Linux/x86_64\n", stderr) >= 0 ? 2 : 1;
#endif
}
