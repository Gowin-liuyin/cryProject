#include <errno.h>
#include <inttypes.h>
#include <limits.h>
#include <stdbool.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#define LINE_CAPACITY 8192U
#define DEPTH_CAPACITY 8U
#define CALL_CAPACITY 250000U
#define SNAPSHOT_CAPACITY 512U
#define CHECKPOINT_CAPACITY 3907U
#define INPUT_COUNT 8U
#define SAMPLE_PERIOD_NS UINT64_C(20000000)
#define WARMUP_NS UINT64_C(1000000000)
#define MAIN_NS UINT64_C(4000000000)
#define SOFT_LIMIT_NS UINT64_C(6000000000)
#define MAX_GAP_NS UINT64_C(40000000)
#define MAX_TRIPLE_NS UINT64_C(1000000)
#define TIMING_QUARTER_COUNT 4U
#define TIMING_ROW_COUNT ((2U + TIMING_QUARTER_COUNT) * (INPUT_COUNT + 1U))

enum phase {
    PHASE_WARMUP,
    PHASE_MAIN
};

enum frame_kind {
    FRAME_START,
    FRAME_PERIODIC,
    FRAME_BOUNDARY,
    FRAME_END
};

enum band_class {
    BAND_UNAVAILABLE,
    BAND_IN,
    BAND_OVERLAP,
    BAND_LOW,
    BAND_HIGH
};

enum window_flag {
    FLAG_CLOCK = 1U << 0,
    FLAG_READ = 1U << 1,
    FLAG_DECREASE = 1U << 2,
    FLAG_ZERO_DENOMINATOR = 1U << 3,
    FLAG_OVERFLOW = 1U << 4,
    FLAG_TRIPLE_SPAN = 1U << 5,
    FLAG_GAP = 1U << 6,
    FLAG_LOW_ACTIVITY = 1U << 7,
    FLAG_CALL_FAILURE = 1U << 8,
    FLAG_CADENCE = 1U << 9,
    FLAG_TIME_OVERLAP = 1U << 10
};

struct optional_u64 {
    uint64_t value;
    bool present;
};

struct clock_value {
    struct optional_u64 ns;
    int error_number;
    bool has_raw_timespec;
    int64_t raw_seconds;
    int64_t raw_fractional_ns;
};

struct counter_value {
    struct optional_u64 value;
    struct clock_value before;
    struct clock_value after;
    int64_t bytes_read;
    int error_number;
};

struct frame {
    struct clock_value raw_before;
    struct clock_value raw_after;
    struct clock_value thread_before;
    struct clock_value thread_after;
    struct counter_value counters[2][3];
    struct optional_u64 deadline;
    uint64_t missed_deadlines;
    size_t call_record_count;
    enum phase phase;
    enum frame_kind kind;
    bool declared_valid;
};

struct checkpoint {
    struct clock_value raw;
    size_t call_record_count;
    enum phase phase;
};

struct call {
    struct clock_value before;
    struct clock_value after;
    struct optional_u64 elapsed;
    enum phase phase;
    int operation_status;
    bool operation_performed;
};

struct device {
    char status[32];
    uint64_t owner_uid;
    uint64_t major_number;
    uint64_t minor_number;
    int error_number;
    int close_error_number;
    bool has_metadata;
};

struct summary {
    char status[40];
    size_t call_record_count;
    size_t frame_count;
    size_t checkpoint_count;
    size_t prepared_input_count;
    int input_operation_status;
    int affinity_error_number;
    int allocation_errors[3];
    bool affinity_verified;
    bool valid_final_snapshot;
    struct optional_u64 warmup_start;
    struct optional_u64 main_start;
};

struct input_data {
    struct frame *frames;
    struct checkpoint *checkpoints;
    struct call *calls;
    struct device devices[2];
    struct summary summary;
    char input_digests[INPUT_COUNT][65];
    size_t frame_count;
    size_t checkpoint_count;
    size_t call_record_count;
    size_t device_count;
    size_t input_count;
    size_t line_count;
    unsigned int last_group;
    bool has_contract;
    bool has_summary;
};

struct parser {
    const char *text;
    size_t cursor;
    unsigned int depth;
    const char *error;
};

struct window_result {
    struct optional_u64 aperf_delta;
    struct optional_u64 reference_lower;
    struct optional_u64 reference_upper;
    struct optional_u64 activity_cpu_lower;
    struct optional_u64 activity_wall_upper;
    struct optional_u64 previous_triple_ns;
    struct optional_u64 next_triple_ns;
    struct optional_u64 gap_upper_ns;
    uint64_t pure_wall_ns;
    size_t pure_call_records;
    unsigned int flags;
    enum band_class band;
    bool straddles_main_start;
    bool activity_pass;
    bool rules_pass;
};

struct coverage {
    uint64_t geometric_wall_ns;
    uint64_t passing_wall_ns;
    uint64_t head_blind_ns;
    uint64_t tail_blind_ns;
    uint64_t blind_overlap_ns;
    uint64_t other_blind_ns;
    size_t geometric_call_records;
    size_t passing_call_records;
    size_t main_call_records;
    size_t main_performed_calls;
    size_t main_pairs;
    size_t passing_pairs;
    size_t boundary_pairs;
    bool all_pairs_pass;
    bool producer_completed;
    bool geometry_available;
    bool engineering_diagnostic;
    bool clock_sequence_anomaly;
    struct optional_u64 main_end;
    struct optional_u64 main_wall;
};

struct timing_row {
    enum phase phase;
    size_t quarter_index;
    size_t input_index;
    size_t count;
    uint64_t sum_elapsed_ns;
    uint64_t minimum_ns;
    uint64_t p50_ns;
    uint64_t p90_ns;
    uint64_t p99_ns;
    uint64_t maximum_ns;
    uint64_t mad_ns;
};

struct timing_description {
    struct timing_row rows[TIMING_ROW_COUNT];
    size_t row_count;
    size_t warmup_call_records;
    size_t main_call_records;
    size_t snapshot_phase_counts[2];
    size_t checkpoint_phase_counts[2];
    size_t main_snapshot_position_counts[3];
    size_t main_checkpoint_position_counts[3];
    uint64_t main_start_ns;
    uint64_t main_end_ns;
    uint64_t main_wall_ns;
    uint64_t main_call_elapsed_sum_ns;
    uint64_t main_outside_call_windows_ns;
    uint64_t main_head_outside_ns;
    uint64_t main_intercall_gap_sum_ns;
    uint64_t main_tail_outside_ns;
};

static bool reject(struct parser *parser, const char *reason)
{
    if (parser->error == NULL) {
        parser->error = reason;
    }
    return false;
}

static void skip_space(struct parser *parser)
{
    while (parser->text[parser->cursor] == ' ' || parser->text[parser->cursor] == '\t') {
        ++parser->cursor;
    }
}

static bool punctuation(struct parser *parser, char expected)
{
    skip_space(parser);
    if (parser->text[parser->cursor] != expected) {
        return reject(parser, "punctuation_or_truncation");
    }
    ++parser->cursor;
    if (expected == '{' || expected == '[') {
        if (++parser->depth > DEPTH_CAPACITY) {
            return reject(parser, "depth_limit");
        }
    } else if (expected == '}' || expected == ']') {
        if (parser->depth == 0) {
            return reject(parser, "unbalanced_container");
        }
        --parser->depth;
    }
    return true;
}

static bool string_value(struct parser *parser, char *output, size_t capacity)
{
    skip_space(parser);
    if (parser->text[parser->cursor++] != '"') {
        return reject(parser, "expected_ascii_string");
    }
    size_t count = 0;
    while (parser->text[parser->cursor] != '"') {
        unsigned char character = (unsigned char)parser->text[parser->cursor];
        if (character < 0x20U || character > 0x7eU || character == '\\') {
            return reject(parser, "unsupported_string_or_escape");
        }
        if (count + 1U >= capacity) {
            return reject(parser, "string_limit");
        }
        output[count++] = (char)character;
        ++parser->cursor;
    }
    ++parser->cursor;
    output[count] = '\0';
    return true;
}

static bool unsigned_digits(const char *text, uint64_t *value)
{
    if (*text == '\0' || (text[0] == '0' && text[1] != '\0')) {
        return false;
    }
    uint64_t result = 0;
    for (const char *character = text; *character != '\0'; ++character) {
        if (*character < '0' || *character > '9') {
            return false;
        }
        unsigned int digit = (unsigned int)(*character - '0');
        if (result > (UINT64_MAX - digit) / 10U) {
            return false;
        }
        result = result * 10U + digit;
    }
    *value = result;
    return true;
}

static bool unsigned_number(struct parser *parser, uint64_t *value)
{
    skip_space(parser);
    char digits[32];
    size_t count = 0;
    while (parser->text[parser->cursor] >= '0' && parser->text[parser->cursor] <= '9') {
        if (count + 1U >= sizeof(digits)) {
            return reject(parser, "integer_overflow");
        }
        digits[count++] = parser->text[parser->cursor++];
    }
    digits[count] = '\0';
    return unsigned_digits(digits, value) || reject(parser, "unsigned_integer_or_overflow");
}

static bool signed_digits(const char *text, int64_t *value)
{
    bool negative = *text == '-';
    uint64_t magnitude = 0;
    if (!unsigned_digits(text + (negative ? 1U : 0U), &magnitude) || (negative && magnitude == 0) ||
        magnitude > (uint64_t)INT64_MAX + (negative ? 1U : 0U)) {
        return false;
    }
    if (negative && magnitude == (uint64_t)INT64_MAX + 1U) {
        *value = INT64_MIN;
    } else {
        *value = negative ? -(int64_t)magnitude : (int64_t)magnitude;
    }
    return true;
}

static bool signed_number(struct parser *parser, int64_t *value)
{
    skip_space(parser);
    char digits[32];
    size_t count = 0;
    if (parser->text[parser->cursor] == '-') {
        digits[count++] = parser->text[parser->cursor++];
    }
    while (parser->text[parser->cursor] >= '0' && parser->text[parser->cursor] <= '9') {
        if (count + 1U >= sizeof(digits)) {
            return reject(parser, "integer_overflow");
        }
        digits[count++] = parser->text[parser->cursor++];
    }
    digits[count] = '\0';
    return signed_digits(digits, value) || reject(parser, "signed_integer_or_overflow");
}

static bool literal(struct parser *parser, const char *expected)
{
    skip_space(parser);
    size_t length = strlen(expected);
    if (strncmp(parser->text + parser->cursor, expected, length) != 0) {
        return reject(parser, "literal_mismatch");
    }
    parser->cursor += length;
    return true;
}

static bool boolean_value(struct parser *parser, bool *value)
{
    skip_space(parser);
    if (parser->text[parser->cursor] == 't') {
        *value = true;
        return literal(parser, "true");
    }
    *value = false;
    return literal(parser, "false");
}

static bool key(struct parser *parser, const char *expected, bool first)
{
    char actual[80];
    if ((!first && !punctuation(parser, ',')) || !string_value(parser, actual, sizeof(actual)) ||
        strcmp(actual, expected) != 0 || !punctuation(parser, ':')) {
        return reject(parser, "unknown_duplicate_or_out_of_order_key");
    }
    return true;
}

static bool optional_unsigned(struct parser *parser, struct optional_u64 *value)
{
    skip_space(parser);
    if (parser->text[parser->cursor] == 'n') {
        value->present = false;
        return literal(parser, "null");
    }
    char digits[32];
    if (!string_value(parser, digits, sizeof(digits)) || !unsigned_digits(digits, &value->value)) {
        return reject(parser, "uint64_string_or_overflow");
    }
    value->present = true;
    return true;
}

static bool error_value(struct parser *parser, int *error_number)
{
    skip_space(parser);
    if (parser->text[parser->cursor] == 'n') {
        *error_number = 0;
        return literal(parser, "null");
    }
    uint64_t number = 0;
    if (!unsigned_number(parser, &number) || number == 0 || number > INT_MAX) {
        return reject(parser, "errno_range");
    }
    *error_number = (int)number;
    return true;
}

static bool integer_value(struct parser *parser, int *value)
{
    int64_t number = 0;
    if (!signed_number(parser, &number) || number < INT_MIN || number > INT_MAX) {
        return reject(parser, "int_range");
    }
    *value = (int)number;
    return true;
}

static bool count_field(struct parser *parser, const char *name, size_t limit, size_t *value)
{
    uint64_t number = 0;
    if (!key(parser, name, false) || !unsigned_number(parser, &number) || number > limit) {
        return reject(parser, "count_limit");
    }
    *value = (size_t)number;
    return true;
}

static bool text_field(struct parser *parser, const char *name, char *value, size_t capacity)
{
    return key(parser, name, false) && string_value(parser, value, capacity);
}

static bool constant_text(struct parser *parser, const char *name, const char *expected)
{
    char value[80];
    return (text_field(parser, name, value, sizeof(value)) && strcmp(value, expected) == 0) ||
        reject(parser, "contract_text_mismatch");
}

static bool constant_number(struct parser *parser, const char *name, uint64_t expected)
{
    uint64_t value = 0;
    return (key(parser, name, false) && unsigned_number(parser, &value) && value == expected) ||
        reject(parser, "contract_number_mismatch");
}

static bool constant_bool(struct parser *parser, const char *name, bool expected)
{
    bool value = false;
    return (key(parser, name, false) && boolean_value(parser, &value) && value == expected) ||
        reject(parser, "contract_boolean_mismatch");
}

static bool phase_field(struct parser *parser, enum phase *phase)
{
    char value[16];
    if (!text_field(parser, "phase", value, sizeof(value))) {
        return false;
    }
    if (strcmp(value, "warmup") == 0) {
        *phase = PHASE_WARMUP;
    } else if (strcmp(value, "main") == 0) {
        *phase = PHASE_MAIN;
    } else {
        return reject(parser, "unknown_phase");
    }
    return true;
}

static bool clock_value(struct parser *parser, struct clock_value *clock)
{
    if (!punctuation(parser, '{') || !key(parser, "ns", true) ||
        !optional_unsigned(parser, &clock->ns) || !key(parser, "errno", false) ||
        !error_value(parser, &clock->error_number)) {
        return false;
    }
    skip_space(parser);
    if (parser->text[parser->cursor] == ',') {
        char seconds[32];
        if (clock->ns.present || clock->error_number == 0 ||
            !text_field(parser, "raw_seconds", seconds, sizeof(seconds)) ||
            !signed_digits(seconds, &clock->raw_seconds) ||
            !key(parser, "raw_fractional_ns", false) ||
            !signed_number(parser, &clock->raw_fractional_ns)) {
            return reject(parser, "raw_timespec_fields");
        }
        clock->has_raw_timespec = true;
        bool invalid_timespec = clock->raw_seconds < 0 || clock->raw_fractional_ns < 0 ||
            clock->raw_fractional_ns >= INT64_C(1000000000);
        if (!invalid_timespec) {
            uint64_t seconds_u64 = (uint64_t)clock->raw_seconds;
            invalid_timespec = seconds_u64 > UINT64_MAX / UINT64_C(1000000000) ||
                (seconds_u64 <= UINT64_MAX / UINT64_C(1000000000) &&
                    (uint64_t)clock->raw_fractional_ns >
                        UINT64_MAX - seconds_u64 * UINT64_C(1000000000));
        }
        if (!invalid_timespec) {
            return reject(parser, "unnecessary_raw_timespec_fields");
        }
    }
    return punctuation(parser, '}');
}

static bool clock_field(struct parser *parser, const char *name, struct clock_value *clock)
{
    return key(parser, name, false) && clock_value(parser, clock);
}

static bool clock_valid(const struct clock_value *clock)
{
    return clock->ns.present && clock->error_number == 0 && !clock->has_raw_timespec;
}

static bool clock_span(const struct clock_value *before, const struct clock_value *after)
{
    return clock_valid(before) && clock_valid(after) && after->ns.value >= before->ns.value;
}

static bool counter_value(struct parser *parser, struct counter_value *counter, unsigned int index)
{
    char register_name[16];
    if (!punctuation(parser, '{') || !key(parser, "register", true) ||
        !string_value(parser, register_name, sizeof(register_name)) ||
        strcmp(register_name, index == 1U ? "0xe8" : "0xe7") != 0 ||
        !key(parser, "bytes_read", false) || !signed_number(parser, &counter->bytes_read) ||
        !key(parser, "errno", false) || !error_value(parser, &counter->error_number) ||
        !key(parser, "value_u64", false) || !optional_unsigned(parser, &counter->value) ||
        !clock_field(parser, "before", &counter->before) ||
        !clock_field(parser, "after", &counter->after) || !punctuation(parser, '}')) {
        return reject(parser, "counter_fields");
    }
    if (counter->bytes_read < -1 || counter->bytes_read > 8 ||
        counter->value.present != (counter->bytes_read == 8) ||
        ((counter->bytes_read < 0) != (counter->error_number != 0))) {
        return reject(parser, "counter_result_inconsistent");
    }
    return true;
}

static bool parse_contract(struct parser *parser)
{
    return constant_number(parser, "schema_version", 1) &&
        constant_text(parser, "implementation", "reference") &&
        constant_text(parser, "clock", "CLOCK_MONOTONIC_RAW") &&
        constant_text(parser, "thread_clock", "CLOCK_THREAD_CPUTIME_ID") &&
        constant_number(parser, "workload_cpu", 2) &&
        constant_number(parser, "observation_cpu", 18) &&
        constant_number(parser, "input_count", 8) &&
        constant_text(parser, "input_order", "index_modulo_8") &&
        constant_bool(parser, "iid_claimed", false) &&
        constant_text(parser, "warmup_target_ns", "1000000000") &&
        constant_text(parser, "main_target_ns", "4000000000") &&
        constant_text(parser, "soft_run_limit_ns", "6000000000") &&
        constant_text(parser, "sample_period_ns", "20000000") &&
        constant_number(parser, "check_call_period", 64) &&
        constant_number(parser, "call_capacity", CALL_CAPACITY) &&
        constant_number(parser, "snapshot_capacity", SNAPSHOT_CAPACITY) &&
        constant_bool(parser, "frequency_converted", false) &&
        constant_number(parser, "configuration_writes", 0) &&
        constant_bool(parser, "r02_signed_off", false);
}

static bool parse_device(struct parser *parser, struct device *device, size_t device_index)
{
    if (!constant_number(parser, "cpu_index", device_index == 0 ? 2 : 18) ||
        !text_field(parser, "status", device->status, sizeof(device->status)) ||
        !key(parser, "errno", false) || !error_value(parser, &device->error_number) ||
        !key(parser, "close_errno", false) || !error_value(parser, &device->close_error_number)) {
        return false;
    }
    skip_space(parser);
    if (parser->text[parser->cursor] == ',') {
        struct optional_u64 owner = {0};
        if (!key(parser, "owner_uid", false) || !optional_unsigned(parser, &owner) ||
            !owner.present || !key(parser, "major", false) ||
            !unsigned_number(parser, &device->major_number) || !key(parser, "minor", false) ||
            !unsigned_number(parser, &device->minor_number) || device->major_number > UINT_MAX ||
            device->minor_number > UINT_MAX) {
            return reject(parser, "device_metadata");
        }
        device->owner_uid = owner.value;
        device->has_metadata = true;
    }
    static const char *const statuses[] =
        {"not_opened", "path_error", "open_error", "fstat_error", "device_rejected", "ok"};
    bool known = false;
    for (size_t status_index = 0; status_index < sizeof(statuses) / sizeof(statuses[0]);
        ++status_index) {
        known = known || strcmp(device->status, statuses[status_index]) == 0;
    }
    return known || reject(parser, "unknown_device_status");
}

static bool parse_public_input(struct parser *parser, struct input_data *data)
{
    if (!constant_number(parser, "input_index", data->input_count) ||
        !text_field(parser, "ciphertext_sha3_256", data->input_digests[data->input_count], 65)) {
        return false;
    }
    const char *digest = data->input_digests[data->input_count];
    if (strlen(digest) != 64 || strspn(digest, "0123456789abcdef") != 64) {
        return reject(parser, "public_digest_format");
    }
    return true;
}

static bool parse_frame(struct parser *parser, struct frame *frame, size_t frame_index)
{
    char kind[32];
    if (!constant_number(parser, "index", frame_index) ||
        !text_field(parser, "kind", kind, sizeof(kind)) || !phase_field(parser, &frame->phase) ||
        !count_field(parser, "call_records", CALL_CAPACITY, &frame->call_record_count) ||
        !key(parser, "valid_reads_and_clocks", false) ||
        !boolean_value(parser, &frame->declared_valid) ||
        !key(parser, "scheduled_deadline_ns", false) ||
        !optional_unsigned(parser, &frame->deadline) || !key(parser, "missed_deadlines", false)) {
        return false;
    }
    struct optional_u64 missed = {0};
    if (!optional_unsigned(parser, &missed) || !missed.present ||
        !clock_field(parser, "raw_before", &frame->raw_before) ||
        !clock_field(parser, "thread_cpu_before", &frame->thread_before) ||
        !clock_field(parser, "thread_cpu_after", &frame->thread_after) ||
        !clock_field(parser, "raw_after", &frame->raw_after) || !key(parser, "cpu_reads", false) ||
        !punctuation(parser, '[')) {
        return false;
    }
    frame->missed_deadlines = missed.value;
    if (strcmp(kind, "start") == 0) {
        frame->kind = FRAME_START;
    } else if (strcmp(kind, "periodic") == 0) {
        frame->kind = FRAME_PERIODIC;
    } else if (strcmp(kind, "warmup_to_main") == 0) {
        frame->kind = FRAME_BOUNDARY;
    } else if (strcmp(kind, "end") == 0) {
        frame->kind = FRAME_END;
    } else {
        return reject(parser, "unknown_frame_kind");
    }
    if (frame->deadline.present != (frame->kind == FRAME_PERIODIC) ||
        (!frame->deadline.present && frame->missed_deadlines != 0)) {
        return reject(parser, "frame_deadline_fields");
    }
    for (unsigned int cpu_index = 0; cpu_index < 2U; ++cpu_index) {
        if ((cpu_index != 0 && !punctuation(parser, ',')) || !punctuation(parser, '{') ||
            !key(parser, "cpu_index", true)) {
            return false;
        }
        uint64_t cpu_number = 0;
        if (!unsigned_number(parser, &cpu_number) || cpu_number != (cpu_index == 0 ? 2U : 18U) ||
            !key(parser, "reads", false) || !punctuation(parser, '[')) {
            return reject(parser, "cpu_read_identity");
        }
        for (unsigned int read_index = 0; read_index < 3U; ++read_index) {
            if ((read_index != 0 && !punctuation(parser, ',')) ||
                !counter_value(parser, &frame->counters[cpu_index][read_index], read_index)) {
                return false;
            }
        }
        if (!punctuation(parser, ']') || !punctuation(parser, '}')) {
            return false;
        }
    }
    return punctuation(parser, ']');
}

static bool parse_checkpoint(struct parser *parser, struct checkpoint *checkpoint, size_t index)
{
    return constant_number(parser, "index", index) && phase_field(parser, &checkpoint->phase) &&
        count_field(parser, "call_records", CALL_CAPACITY, &checkpoint->call_record_count) &&
        clock_field(parser, "raw", &checkpoint->raw);
}

static bool parse_call(struct parser *parser, struct call *call, size_t index)
{
    if (!constant_number(parser, "index", index) || !phase_field(parser, &call->phase) ||
        !constant_number(parser, "input_index", index % INPUT_COUNT) ||
        !key(parser, "operation_performed", false) ||
        !boolean_value(parser, &call->operation_performed) ||
        !key(parser, "operation_status", false)) {
        return false;
    }
    if (call->operation_performed) {
        if (!integer_value(parser, &call->operation_status)) {
            return false;
        }
    } else if (!literal(parser, "null")) {
        return false;
    }
    if (!clock_field(parser, "before", &call->before) ||
        !clock_field(parser, "after", &call->after) || !key(parser, "elapsed_ns", false) ||
        !optional_unsigned(parser, &call->elapsed)) {
        return false;
    }
    bool valid = clock_span(&call->before, &call->after);
    if (valid != call->elapsed.present ||
        (valid && call->elapsed.value != call->after.ns.value - call->before.ns.value) ||
        (!call->operation_performed &&
            (clock_valid(&call->before) || call->after.ns.present ||
                call->after.error_number != 0 || call->after.has_raw_timespec))) {
        return reject(parser, "decap_clock_or_status_inconsistent");
    }
    return true;
}

static bool parse_summary(struct parser *parser, struct summary *summary)
{
    if (!text_field(parser, "status", summary->status, sizeof(summary->status)) ||
        !count_field(parser, "call_records", CALL_CAPACITY, &summary->call_record_count) ||
        !count_field(parser, "snapshot_records", SNAPSHOT_CAPACITY, &summary->frame_count) ||
        !count_field(parser,
            "checkpoint_records",
            CHECKPOINT_CAPACITY,
            &summary->checkpoint_count) ||
        !count_field(parser, "prepared_input_count", INPUT_COUNT, &summary->prepared_input_count) ||
        !key(parser, "input_operation_status", false) ||
        !integer_value(parser, &summary->input_operation_status) ||
        !key(parser, "affinity_verified", false) ||
        !boolean_value(parser, &summary->affinity_verified) ||
        !key(parser, "affinity_errno", false) ||
        !error_value(parser, &summary->affinity_error_number) ||
        !key(parser, "allocation_errnos", false) || !punctuation(parser, '[')) {
        return false;
    }
    for (unsigned int allocation_index = 0; allocation_index < 3U; ++allocation_index) {
        if ((allocation_index != 0 && !punctuation(parser, ',')) ||
            !error_value(parser, &summary->allocation_errors[allocation_index])) {
            return false;
        }
    }
    return punctuation(parser, ']') && key(parser, "warmup_start_ns", false) &&
        optional_unsigned(parser, &summary->warmup_start) && key(parser, "main_start_ns", false) &&
        optional_unsigned(parser, &summary->main_start) &&
        key(parser, "valid_final_snapshot", false) &&
        boolean_value(parser, &summary->valid_final_snapshot) &&
        constant_bool(parser, "r02_signed_off", false);
}

static bool
parse_line(struct input_data *data, const char *text, const char **error, size_t *column)
{
    struct parser parser = {.text = text};
    char type[32];
    bool valid = punctuation(&parser, '{') && key(&parser, "type", true) &&
        string_value(&parser, type, sizeof(type));
    unsigned int group = 7U;
    if (valid) {
        if (strcmp(type, "contract") == 0) {
            group = 0;
            valid = !data->has_contract && parse_contract(&parser);
            data->has_contract = valid;
        } else if (strcmp(type, "device") == 0) {
            group = 1;
            valid = data->device_count < 2U &&
                parse_device(&parser, &data->devices[data->device_count], data->device_count);
            data->device_count += valid ? 1U : 0U;
        } else if (strcmp(type, "public_input") == 0) {
            group = 2;
            valid = data->input_count < INPUT_COUNT && parse_public_input(&parser, data);
            data->input_count += valid ? 1U : 0U;
        } else if (strcmp(type, "snapshot") == 0) {
            group = 3;
            valid = data->frame_count < SNAPSHOT_CAPACITY &&
                parse_frame(&parser, &data->frames[data->frame_count], data->frame_count);
            data->frame_count += valid ? 1U : 0U;
        } else if (strcmp(type, "checkpoint") == 0) {
            group = 4;
            valid = data->checkpoint_count < CHECKPOINT_CAPACITY &&
                parse_checkpoint(&parser,
                    &data->checkpoints[data->checkpoint_count],
                    data->checkpoint_count);
            data->checkpoint_count += valid ? 1U : 0U;
        } else if (strcmp(type, "decap") == 0) {
            group = 5;
            valid = data->call_record_count < CALL_CAPACITY &&
                parse_call(&parser, &data->calls[data->call_record_count], data->call_record_count);
            data->call_record_count += valid ? 1U : 0U;
        } else if (strcmp(type, "summary") == 0) {
            group = 6;
            valid = !data->has_summary && parse_summary(&parser, &data->summary);
            data->has_summary = valid;
        }
    }
    if (group > 6U || group < data->last_group || (group != 0U && !data->has_contract) ||
        (group > 1U && data->device_count != 2U) || data->last_group == 6U) {
        valid = reject(&parser, "record_group_order_or_duplicate");
    }
    if (valid) {
        valid = punctuation(&parser, '}');
        skip_space(&parser);
        valid = valid && parser.depth == 0 && parser.text[parser.cursor] == '\0';
    }
    if (!valid && parser.error == NULL) {
        parser.error = "record_limit_or_incomplete_fields";
    }
    data->last_group = group;
    *error = parser.error;
    *column = parser.cursor + 1U;
    return valid;
}

static bool finish_input_line(char *line, const char **error)
{
    size_t length = strlen(line);
    if (length == 0 || length >= LINE_CAPACITY || line[length - 1U] != '\n') {
        *error = "line_length_or_missing_newline";
        return false;
    }
    line[length - 1U] = '\0';
    return true;
}

static bool checked_multiply(uint64_t value, uint64_t multiplier, uint64_t *product)
{
    if (multiplier != 0 && value > UINT64_MAX / multiplier) {
        return false;
    }
    *product = value * multiplier;
    return true;
}

static bool checked_add(uint64_t left, uint64_t right, uint64_t *sum)
{
    if (right > UINT64_MAX - left) {
        return false;
    }
    *sum = left + right;
    return true;
}

static enum band_class
exact_band(uint64_t aperf_delta, uint64_t reference_lower, uint64_t reference_upper, bool *overflow)
{
    uint64_t scaled_aperf = 0;
    uint64_t low_upper = 0;
    uint64_t high_lower = 0;
    uint64_t low_lower = 0;
    uint64_t high_upper = 0;
    if (!checked_multiply(aperf_delta, 100, &scaled_aperf) ||
        !checked_multiply(reference_upper, 99, &low_upper) ||
        !checked_multiply(reference_lower, 101, &high_lower) ||
        !checked_multiply(reference_lower, 99, &low_lower) ||
        !checked_multiply(reference_upper, 101, &high_upper)) {
        *overflow = true;
        return BAND_UNAVAILABLE;
    }
    if (scaled_aperf >= low_upper && scaled_aperf <= high_lower) {
        return BAND_IN;
    }
    if (scaled_aperf < low_lower) {
        return BAND_LOW;
    }
    if (scaled_aperf > high_upper) {
        return BAND_HIGH;
    }
    return BAND_OVERLAP;
}

static bool frame_local_valid(const struct frame *frame)
{
    bool valid = clock_span(&frame->raw_before, &frame->raw_after) &&
        clock_span(&frame->thread_before, &frame->thread_after);
    for (unsigned int cpu_index = 0; cpu_index < 2U; ++cpu_index) {
        for (unsigned int read_index = 0; read_index < 3U; ++read_index) {
            const struct counter_value *counter = &frame->counters[cpu_index][read_index];
            valid = counter->value.present && counter->error_number == 0 &&
                clock_span(&counter->before, &counter->after) && valid;
        }
    }
    return valid;
}

static bool
advance_clock(const struct clock_value *clock, struct optional_u64 *previous, bool *anomaly)
{
    if (!clock_valid(clock)) {
        *anomaly = true;
        return true;
    }
    if (previous->present && clock->ns.value < previous->value) {
        *anomaly = true;
    }
    *previous = clock->ns;
    return true;
}

static void frame_clock_order(const struct frame *frame,
    struct optional_u64 *previous_raw,
    struct optional_u64 *previous_thread,
    bool *anomaly)
{
    (void)advance_clock(&frame->raw_before, previous_raw, anomaly);
    (void)advance_clock(&frame->thread_before, previous_thread, anomaly);
    for (unsigned int cpu_index = 0; cpu_index < 2U; ++cpu_index) {
        for (unsigned int read_index = 0; read_index < 3U; ++read_index) {
            (void)advance_clock(&frame->counters[cpu_index][read_index].before,
                previous_raw,
                anomaly);
            (void)advance_clock(&frame->counters[cpu_index][read_index].after,
                previous_raw,
                anomaly);
        }
    }
    (void)advance_clock(&frame->thread_after, previous_thread, anomaly);
    (void)advance_clock(&frame->raw_after, previous_raw, anomaly);
}

static bool known_stop_status(const char *status)
{
    static const char *const statuses[] = {"not_started",
        "completed",
        "allocation_failed",
        "reference_identity_failed",
        "affinity_failed",
        "device_failed",
        "input_preparation_failed",
        "clock_failed",
        "counter_failed",
        "decapsulation_failed",
        "call_capacity",
        "snapshot_capacity",
        "checkpoint_capacity",
        "soft_timeout"};
    for (size_t status_index = 0; status_index < sizeof(statuses) / sizeof(statuses[0]);
        ++status_index) {
        if (strcmp(status, statuses[status_index]) == 0) {
            return true;
        }
    }
    return false;
}

static bool validate_integrity(const struct input_data *data,
    const char **error,
    size_t *boundary_index,
    bool *clock_anomaly,
    bool *producer_completed)
{
    const struct summary *summary = &data->summary;
    if (!data->has_contract || data->device_count != 2U || !data->has_summary ||
        summary->call_record_count != data->call_record_count ||
        summary->frame_count != data->frame_count ||
        summary->checkpoint_count != data->checkpoint_count ||
        summary->prepared_input_count != data->input_count || !known_stop_status(summary->status)) {
        *error = "missing_summary_or_count_mismatch";
        return false;
    }
    *boundary_index = SIZE_MAX;
    size_t boundary_calls = SIZE_MAX;
    bool has_end = false;
    for (size_t frame_index = 0; frame_index < data->frame_count; ++frame_index) {
        const struct frame *frame = &data->frames[frame_index];
        if (frame->call_record_count > data->call_record_count ||
            frame->declared_valid != frame_local_valid(frame) ||
            (frame_index == 0 &&
                (frame->kind != FRAME_START || frame->call_record_count != 0 ||
                    frame->phase != PHASE_WARMUP)) ||
            (frame_index != 0 && frame->kind == FRAME_START) || has_end ||
            (frame_index != 0 &&
                frame->call_record_count < data->frames[frame_index - 1U].call_record_count)) {
            *error = "snapshot_structure_or_validity_mismatch";
            return false;
        }
        if (frame->kind == FRAME_BOUNDARY) {
            if (*boundary_index != SIZE_MAX || frame->phase != PHASE_WARMUP) {
                *error = "duplicate_or_misphased_boundary";
                return false;
            }
            *boundary_index = frame_index;
            if (frame->declared_valid) {
                boundary_calls = frame->call_record_count;
            }
        } else if (frame->phase != (boundary_calls == SIZE_MAX ? PHASE_WARMUP : PHASE_MAIN)) {
            *error = "snapshot_phase_order";
            return false;
        }
        if ((!frame->declared_valid || frame->kind == FRAME_END) &&
            (frame_index + 1U != data->frame_count ||
                frame->call_record_count != data->call_record_count)) {
            *error = "continued_after_failed_snapshot";
            return false;
        }
        has_end = frame->kind == FRAME_END;
    }
    bool valid_end = has_end && data->frames[data->frame_count - 1U].declared_valid;
    if (data->frame_count != 0 && data->frames[data->frame_count - 1U].declared_valid && !has_end) {
        *error = "missing_terminal_snapshot";
        return false;
    }
    if (summary->valid_final_snapshot != valid_end ||
        summary->warmup_start.present !=
            (data->frame_count != 0 && data->frames[0].declared_valid) ||
        (summary->warmup_start.present &&
            summary->warmup_start.value != data->frames[0].raw_after.ns.value) ||
        summary->main_start.present != (boundary_calls != SIZE_MAX) ||
        (summary->main_start.present &&
            summary->main_start.value != data->frames[*boundary_index].raw_after.ns.value)) {
        *error = "summary_boundary_mismatch";
        return false;
    }
    size_t checkpoint_index = 0;
    size_t frame_index = 0;
    struct optional_u64 previous_raw = {0};
    struct optional_u64 previous_thread = {0};
    bool every_call_good = true;
    bool every_checkpoint_good = true;
    for (size_t call_boundary = 0; call_boundary <= data->call_record_count; ++call_boundary) {
        if (call_boundary != 0) {
            const struct call *call = &data->calls[call_boundary - 1U];
            enum phase expected = call_boundary - 1U < boundary_calls ? PHASE_WARMUP : PHASE_MAIN;
            if (call->phase != expected) {
                *error = "decap_phase_order";
                return false;
            }
            bool good = call->operation_performed && call->operation_status == 0 &&
                clock_span(&call->before, &call->after);
            if (!good && call_boundary != data->call_record_count) {
                *error = "continued_after_failed_decap";
                return false;
            }
            every_call_good = every_call_good && good;
            (void)advance_clock(&call->before, &previous_raw, clock_anomaly);
            if (call->operation_performed) {
                (void)advance_clock(&call->after, &previous_raw, clock_anomaly);
            }
        }
        if (checkpoint_index < data->checkpoint_count &&
            data->checkpoints[checkpoint_index].call_record_count == call_boundary) {
            const struct checkpoint *checkpoint = &data->checkpoints[checkpoint_index];
            if (call_boundary == 0 || call_boundary % 64U != 0 ||
                checkpoint_index + 1U != call_boundary / 64U ||
                checkpoint->phase !=
                    (call_boundary <= boundary_calls ? PHASE_WARMUP : PHASE_MAIN)) {
                *error = "checkpoint_index_or_phase";
                return false;
            }
            every_checkpoint_good = every_checkpoint_good && clock_valid(&checkpoint->raw);
            (void)advance_clock(&checkpoint->raw, &previous_raw, clock_anomaly);
            ++checkpoint_index;
        } else if (call_boundary != 0 && call_boundary % 64U == 0 && every_call_good &&
            call_boundary < data->call_record_count) {
            *error = "missing_checkpoint";
            return false;
        }
        while (frame_index < data->frame_count &&
            data->frames[frame_index].call_record_count == call_boundary) {
            frame_clock_order(&data->frames[frame_index],
                &previous_raw,
                &previous_thread,
                clock_anomaly);
            ++frame_index;
        }
    }
    if (checkpoint_index != data->checkpoint_count || frame_index != data->frame_count) {
        *error = "unreachable_checkpoint_or_snapshot";
        return false;
    }
    bool devices_good = true;
    for (size_t device_index = 0; device_index < 2U; ++device_index) {
        const struct device *device = &data->devices[device_index];
        devices_good = devices_good && strcmp(device->status, "ok") == 0 && device->has_metadata &&
            device->owner_uid == 0 && device->major_number == 202 &&
            device->minor_number == (device_index == 0 ? 2U : 18U) && device->error_number == 0 &&
            device->close_error_number == 0;
    }
    bool allocation_good = summary->allocation_errors[0] == 0 &&
        summary->allocation_errors[1] == 0 && summary->allocation_errors[2] == 0;
    *producer_completed = strcmp(summary->status, "completed") == 0 && devices_good &&
        allocation_good && summary->affinity_verified && summary->affinity_error_number == 0 &&
        data->input_count == INPUT_COUNT && summary->input_operation_status == 0 &&
        every_call_good && every_checkpoint_good && valid_end && summary->main_start.present &&
        !*clock_anomaly;
    if (strcmp(summary->status, "completed") == 0 && !*producer_completed) {
        *error = "completed_summary_inconsistent";
        return false;
    }
    return true;
}

static bool validate_schedule(const struct input_data *data, const char **error)
{
    if (!data->summary.warmup_start.present) {
        return data->checkpoint_count == 0 || (*error = "checkpoints_without_start", false);
    }
    uint64_t phase_start = data->summary.warmup_start.value;
    uint64_t deadline = 0;
    if (!checked_add(phase_start, SAMPLE_PERIOD_NS, &deadline)) {
        return strcmp(data->summary.status, "completed") != 0;
    }
    enum phase phase = PHASE_WARMUP;
    size_t next_frame = 1;
    for (size_t checkpoint_index = 0; checkpoint_index < data->checkpoint_count;
        ++checkpoint_index) {
        const struct checkpoint *checkpoint = &data->checkpoints[checkpoint_index];
        const struct frame *frame = next_frame < data->frame_count &&
                data->frames[next_frame].call_record_count == checkpoint->call_record_count
            ? &data->frames[next_frame]
            : NULL;
        if (!clock_valid(&checkpoint->raw)) {
            continue;
        }
        uint64_t current = checkpoint->raw.ns.value;
        if (current < phase_start || current < data->summary.warmup_start.value) {
            continue;
        }
        uint64_t duration = phase == PHASE_WARMUP ? WARMUP_NS : MAIN_NS;
        enum frame_kind expected_kind = FRAME_START;
        if (current - data->summary.warmup_start.value >= SOFT_LIMIT_NS) {
            expected_kind = FRAME_END;
        } else if (current - phase_start >= duration) {
            expected_kind = phase == PHASE_WARMUP ? FRAME_BOUNDARY : FRAME_END;
        } else if (current >= deadline) {
            expected_kind = FRAME_PERIODIC;
        }
        if (expected_kind == FRAME_START) {
            if (frame != NULL) {
                *error = "unexpected_early_snapshot";
                return false;
            }
            continue;
        }
        if (frame == NULL ||
            (frame->kind != expected_kind &&
                !(frame->kind == FRAME_END &&
                    strcmp(data->summary.status, "snapshot_capacity") == 0))) {
            *error = "missing_or_unexpected_scheduled_snapshot";
            return false;
        }
        ++next_frame;
        if (frame->kind == FRAME_PERIODIC) {
            uint64_t missed = (current - deadline) / SAMPLE_PERIOD_NS;
            uint64_t advance = 0;
            if (!frame->deadline.present || frame->deadline.value != deadline ||
                frame->missed_deadlines != missed || !checked_add(missed, 1, &advance) ||
                !checked_multiply(advance, SAMPLE_PERIOD_NS, &advance) ||
                !checked_add(deadline, advance, &deadline)) {
                *error = "scheduled_deadline_mismatch_or_overflow";
                return false;
            }
        } else if (frame->kind == FRAME_BOUNDARY && frame->declared_valid) {
            phase = PHASE_MAIN;
            phase_start = frame->raw_after.ns.value;
            if (!checked_add(phase_start, SAMPLE_PERIOD_NS, &deadline)) {
                return strcmp(data->summary.status, "completed") != 0;
            }
        }
    }
    if (strcmp(data->summary.status, "completed") == 0) {
        if (data->checkpoint_count == 0 || !data->summary.main_start.present) {
            *error = "completed_without_phase_checkpoint";
            return false;
        }
        uint64_t last = data->checkpoints[data->checkpoint_count - 1U].raw.ns.value;
        if (last < data->summary.main_start.value ||
            last - data->summary.main_start.value < MAIN_NS) {
            *error = "completed_before_main_target";
            return false;
        }
    }
    return true;
}

static uint64_t pure_segment(const struct frame *previous,
    const struct frame *next,
    unsigned int cpu_index,
    uint64_t main_start,
    uint64_t main_end,
    bool *straddles,
    bool *overlap)
{
    const struct counter_value *previous_aperf = &previous->counters[cpu_index][1];
    const struct counter_value *next_aperf = &next->counters[cpu_index][1];
    if (clock_valid(&previous_aperf->before)) {
        *straddles = previous_aperf->before.ns.value < main_start;
    }
    if (!clock_span(&previous_aperf->before, &previous_aperf->after) ||
        !clock_span(&next_aperf->before, &next_aperf->after) ||
        !clock_span(&previous->raw_before, &previous->raw_after) ||
        !clock_span(&next->raw_before, &next->raw_after)) {
        return 0;
    }
    *straddles = previous_aperf->before.ns.value < main_start;
    *overlap = previous_aperf->after.ns.value > next_aperf->before.ns.value;
    if (*straddles || *overlap || next_aperf->after.ns.value > main_end) {
        return 0;
    }
    uint64_t start =
        previous_aperf->after.ns.value > main_start ? previous_aperf->after.ns.value : main_start;
    uint64_t end = next_aperf->before.ns.value < main_end ? next_aperf->before.ns.value : main_end;
    return end > start ? end - start : 0;
}

static struct window_result calculate_window(const struct input_data *data,
    const struct frame *previous,
    const struct frame *next,
    unsigned int cpu_index,
    uint64_t main_start,
    uint64_t main_end)
{
    struct window_result result = {0};
    const struct counter_value *previous_reads = previous->counters[cpu_index];
    const struct counter_value *next_reads = next->counters[cpu_index];
    bool raw_valid = clock_span(&previous->raw_before, &previous->raw_after) &&
        clock_span(&next->raw_before, &next->raw_after) &&
        next->raw_after.ns.value >= previous->raw_before.ns.value;
    bool read_values_valid = true;
    bool read_clocks_valid = true;
    for (unsigned int read_index = 0; read_index < 3U; ++read_index) {
        read_values_valid = read_values_valid && previous_reads[read_index].value.present &&
            next_reads[read_index].value.present && previous_reads[read_index].error_number == 0 &&
            next_reads[read_index].error_number == 0;
        read_clocks_valid = read_clocks_valid &&
            clock_span(&previous_reads[read_index].before, &previous_reads[read_index].after) &&
            clock_span(&next_reads[read_index].before, &next_reads[read_index].after);
    }
    if (!raw_valid || !read_clocks_valid) {
        result.flags |= FLAG_CLOCK;
    }
    if (!read_values_valid) {
        result.flags |= FLAG_READ;
    } else if (previous_reads[2].value.value < previous_reads[0].value.value ||
        next_reads[2].value.value < next_reads[0].value.value ||
        next_reads[0].value.value < previous_reads[2].value.value ||
        next_reads[1].value.value < previous_reads[1].value.value) {
        result.flags |= FLAG_DECREASE;
    } else {
        result.aperf_delta =
            (struct optional_u64){next_reads[1].value.value - previous_reads[1].value.value, true};
        result.reference_lower =
            (struct optional_u64){next_reads[0].value.value - previous_reads[2].value.value, true};
        result.reference_upper =
            (struct optional_u64){next_reads[2].value.value - previous_reads[0].value.value, true};
        if (result.reference_lower.value == 0 || result.reference_upper.value == 0) {
            result.flags |= FLAG_ZERO_DENOMINATOR;
        } else if (raw_valid && read_clocks_valid) {
            bool overflow = false;
            result.band = exact_band(result.aperf_delta.value,
                result.reference_lower.value,
                result.reference_upper.value,
                &overflow);
            if (overflow) {
                result.flags |= FLAG_OVERFLOW;
            }
        }
    }
    if (clock_span(&previous_reads[0].before, &previous_reads[2].after)) {
        result.previous_triple_ns = (struct optional_u64){previous_reads[2].after.ns.value -
                previous_reads[0].before.ns.value,
            true};
    }
    if (clock_span(&next_reads[0].before, &next_reads[2].after)) {
        result.next_triple_ns =
            (struct optional_u64){next_reads[2].after.ns.value - next_reads[0].before.ns.value,
                true};
    }
    if (!result.previous_triple_ns.present || !result.next_triple_ns.present ||
        result.previous_triple_ns.value > MAX_TRIPLE_NS ||
        result.next_triple_ns.value > MAX_TRIPLE_NS) {
        result.flags |= FLAG_TRIPLE_SPAN;
    }
    if (raw_valid) {
        result.gap_upper_ns =
            (struct optional_u64){next->raw_after.ns.value - previous->raw_before.ns.value, true};
        if (result.gap_upper_ns.value == 0 || result.gap_upper_ns.value > MAX_GAP_NS) {
            result.flags |= FLAG_GAP;
        }
    }
    if (previous->kind == FRAME_PERIODIC && previous->missed_deadlines != 0) {
        result.flags |= FLAG_CADENCE;
    }
    if (next->kind == FRAME_PERIODIC && next->missed_deadlines != 0) {
        result.flags |= FLAG_CADENCE;
    }
    if (cpu_index == 0U) {
        if (!clock_span(&previous->thread_before, &previous->thread_after) ||
            !clock_span(&next->thread_before, &next->thread_after) ||
            next->thread_before.ns.value < previous->thread_after.ns.value || !raw_valid) {
            result.flags |= FLAG_CLOCK;
        } else {
            result.activity_cpu_lower = (struct optional_u64){next->thread_before.ns.value -
                    previous->thread_after.ns.value,
                true};
            result.activity_wall_upper = result.gap_upper_ns;
            uint64_t scaled_cpu = 0;
            uint64_t scaled_wall = 0;
            if (!checked_multiply(result.activity_cpu_lower.value, 5, &scaled_cpu) ||
                !checked_multiply(result.activity_wall_upper.value, 4, &scaled_wall)) {
                result.flags |= FLAG_OVERFLOW;
            } else {
                result.activity_pass = result.activity_wall_upper.value != 0 &&
                    scaled_cpu >= scaled_wall &&
                    result.activity_cpu_lower.value <= result.activity_wall_upper.value;
                if (!result.activity_pass) {
                    result.flags |= FLAG_LOW_ACTIVITY;
                }
            }
        }
    }
    bool overlap = false;
    result.pure_wall_ns = pure_segment(previous,
        next,
        cpu_index,
        main_start,
        main_end,
        &result.straddles_main_start,
        &overlap);
    if (overlap) {
        result.flags |= FLAG_TIME_OVERLAP;
    }
    if (raw_valid && next->raw_before.ns.value < previous->raw_after.ns.value) {
        result.flags |= FLAG_TIME_OVERLAP;
        result.pure_wall_ns = 0;
    }
    if (!raw_valid || !read_clocks_valid || result.band == BAND_UNAVAILABLE) {
        result.pure_wall_ns = 0;
    }
    if (next->call_record_count < previous->call_record_count) {
        result.flags |= FLAG_CALL_FAILURE;
    } else if (data != NULL) {
        for (size_t call_index = previous->call_record_count; call_index < next->call_record_count;
            ++call_index) {
            const struct call *call = &data->calls[call_index];
            if (call->phase != PHASE_MAIN || !call->operation_performed ||
                call->operation_status != 0 || !clock_span(&call->before, &call->after)) {
                result.flags |= FLAG_CALL_FAILURE;
            } else if (result.pure_wall_ns != 0 && !result.straddles_main_start && !overlap &&
                clock_valid(&previous_reads[1].after) && clock_valid(&next_reads[1].before) &&
                call->before.ns.value >= previous_reads[1].after.ns.value &&
                call->after.ns.value <= next_reads[1].before.ns.value &&
                call->before.ns.value >= main_start && call->after.ns.value <= main_end) {
                ++result.pure_call_records;
            }
        }
    }
    result.rules_pass =
        result.flags == 0 && result.band == BAND_IN && (cpu_index != 0U || result.activity_pass);
    return result;
}

static const char *band_name(enum band_class band)
{
    static const char *const names[] = {"unavailable",
        "in_band",
        "boundary_overlap",
        "below_band",
        "above_band"};
    return names[band];
}

static void print_optional_csv(struct optional_u64 value)
{
    if (value.present) {
        printf("%" PRIu64, value.value);
    } else {
        printf("null");
    }
}

static void print_flags(unsigned int flags)
{
    static const char *const names[] = {"clock",
        "read",
        "counter_decrease",
        "zero_denominator",
        "integer_overflow",
        "triple_span",
        "gap",
        "low_activity_proxy",
        "call_failure",
        "cadence_gap",
        "time_overlap"};
    if (flags == 0) {
        printf("none");
    }
    bool has_previous = false;
    for (unsigned int flag_index = 0; flag_index < sizeof(names) / sizeof(names[0]); ++flag_index) {
        if ((flags & (1U << flag_index)) != 0) {
            printf("%s%s", has_previous ? ";" : "", names[flag_index]);
            has_previous = true;
        }
    }
}

static void print_window(size_t window_index,
    size_t previous_index,
    const struct frame *previous,
    const struct frame *next,
    unsigned int cpu_index,
    const struct window_result *result)
{
    printf("%zu,%u,%zu,%zu,%s,%s,%zu,%zu,",
        window_index,
        cpu_index == 0 ? 2U : 18U,
        previous_index,
        previous_index + 1U,
        cpu_index == 0 ? "primary" : "context_only",
        result->straddles_main_start ? "true" : "false",
        previous->call_record_count,
        next->call_record_count);
    for (unsigned int frame_number = 0; frame_number < 2U; ++frame_number) {
        const struct frame *frame = frame_number == 0 ? previous : next;
        for (unsigned int read_index = 0; read_index < 3U; ++read_index) {
            print_optional_csv(frame->counters[cpu_index][read_index].value);
            printf(",");
        }
    }
    print_optional_csv(result->aperf_delta);
    printf(",");
    print_optional_csv(result->reference_lower);
    printf(",");
    print_optional_csv(result->reference_upper);
    printf(",");
    if (result->band != BAND_UNAVAILABLE && result->aperf_delta.present &&
        result->reference_lower.present && result->reference_lower.value != 0 &&
        result->reference_upper.present && result->reference_upper.value != 0) {
        printf("%.6Lf,%.6Lf",
            4300.0L * (long double)result->aperf_delta.value /
                (long double)result->reference_upper.value,
            4300.0L * (long double)result->aperf_delta.value /
                (long double)result->reference_lower.value);
    } else {
        printf("null,null");
    }
    printf(",%s,", band_name(result->band));
    print_optional_csv(result->activity_cpu_lower);
    printf(",");
    print_optional_csv(result->activity_wall_upper);
    printf(",%s,", cpu_index == 0 ? (result->activity_pass ? "true" : "false") : "not_applicable");
    print_optional_csv(result->previous_triple_ns);
    printf(",");
    print_optional_csv(result->next_triple_ns);
    printf(",");
    print_optional_csv(result->gap_upper_ns);
    printf(",%" PRIu64 ",%zu,%s,",
        result->pure_wall_ns,
        result->pure_call_records,
        cpu_index == 0 ? (result->rules_pass ? "true" : "false") : "not_applicable");
    print_flags(result->flags);
    printf("\n");
}

static bool diagnostic_decision(bool producer_completed, size_t pair_count, bool all_pairs_pass)
{
    return producer_completed && pair_count != 0 && all_pairs_pass;
}

static bool analyze_data(const struct input_data *data,
    size_t boundary_index,
    bool producer_completed,
    struct coverage *coverage)
{
    coverage->producer_completed = producer_completed;
    coverage->all_pairs_pass = true;
    for (size_t call_index = 0; call_index < data->call_record_count; ++call_index) {
        if (data->calls[call_index].phase == PHASE_MAIN) {
            ++coverage->main_call_records;
            coverage->main_performed_calls += data->calls[call_index].operation_performed ? 1U : 0U;
        }
    }
    if (data->summary.main_start.present && data->frame_count != 0) {
        const struct frame *last = &data->frames[data->frame_count - 1U];
        if (clock_valid(&last->raw_after) &&
            last->raw_after.ns.value >= data->summary.main_start.value) {
            coverage->main_end = last->raw_after.ns;
            coverage->geometry_available = last->kind == FRAME_END;
            if (coverage->geometry_available) {
                coverage->main_wall =
                    (struct optional_u64){last->raw_after.ns.value - data->summary.main_start.value,
                        true};
            }
        }
    }
    if (boundary_index == SIZE_MAX || !data->summary.main_start.present) {
        coverage->engineering_diagnostic = false;
        return true;
    }
    uint64_t main_start = data->summary.main_start.value;
    uint64_t main_end = coverage->main_end.present ? coverage->main_end.value : UINT64_MAX;
    bool has_pure_support = false;
    uint64_t last_support_end = 0;
    for (size_t previous_index = boundary_index; previous_index + 1U < data->frame_count;
        ++previous_index) {
        const struct frame *previous = &data->frames[previous_index];
        const struct frame *next = &data->frames[previous_index + 1U];
        struct window_result primary =
            calculate_window(data, previous, next, 0, main_start, main_end);
        ++coverage->main_pairs;
        coverage->boundary_pairs += primary.straddles_main_start ? 1U : 0U;
        coverage->passing_pairs += primary.rules_pass ? 1U : 0U;
        coverage->all_pairs_pass = coverage->all_pairs_pass && primary.rules_pass;
        if (!checked_add(coverage->geometric_wall_ns,
                primary.pure_wall_ns,
                &coverage->geometric_wall_ns) ||
            (primary.rules_pass &&
                !checked_add(coverage->passing_wall_ns,
                    primary.pure_wall_ns,
                    &coverage->passing_wall_ns))) {
            return false;
        }
        coverage->geometric_call_records += primary.pure_call_records;
        coverage->passing_call_records += primary.rules_pass ? primary.pure_call_records : 0U;
        if (primary.pure_wall_ns != 0) {
            uint64_t support_start = previous->counters[0][1].after.ns.value;
            uint64_t support_end = next->counters[0][1].before.ns.value;
            if (has_pure_support && support_start < last_support_end) {
                return false;
            }
            if (!has_pure_support) {
                has_pure_support = true;
            }
            last_support_end = support_end;
        }
    }
    if (coverage->main_wall.present) {
        if (coverage->geometric_wall_ns > coverage->main_wall.value ||
            coverage->geometric_call_records > coverage->main_call_records) {
            return false;
        }
        struct optional_u64 head_end = {0};
        struct optional_u64 tail_start = {0};
        for (size_t frame_index = boundary_index + 1U; frame_index < data->frame_count;
            ++frame_index) {
            const struct counter_value *aperf = &data->frames[frame_index].counters[0][1];
            if (!head_end.present && clock_valid(&aperf->after) &&
                aperf->after.ns.value >= main_start) {
                head_end = (struct optional_u64){
                    aperf->after.ns.value < main_end ? aperf->after.ns.value : main_end,
                    true};
            }
            if (clock_valid(&aperf->before) && aperf->before.ns.value <= main_end) {
                tail_start = (struct optional_u64){
                    aperf->before.ns.value > main_start ? aperf->before.ns.value : main_start,
                    true};
            }
        }
        coverage->head_blind_ns = head_end.present ? head_end.value - main_start : 0;
        coverage->tail_blind_ns = tail_start.present ? main_end - tail_start.value : 0;
        if (head_end.present && tail_start.present && head_end.value > tail_start.value) {
            coverage->blind_overlap_ns = head_end.value - tail_start.value;
        }
        uint64_t blind_union = 0;
        uint64_t assigned = 0;
        if (!checked_add(coverage->head_blind_ns, coverage->tail_blind_ns, &blind_union) ||
            blind_union < coverage->blind_overlap_ns) {
            return false;
        }
        blind_union -= coverage->blind_overlap_ns;
        if (!checked_add(coverage->geometric_wall_ns, blind_union, &assigned) ||
            assigned > coverage->main_wall.value) {
            return false;
        }
        coverage->other_blind_ns = coverage->main_wall.value - assigned;
    }
    coverage->engineering_diagnostic =
        diagnostic_decision(producer_completed, coverage->main_pairs, coverage->all_pairs_pass);
    return true;
}

static void print_analysis_csv(const struct input_data *data,
    size_t boundary_index,
    const struct coverage *coverage)
{
    printf(
        "window_index,cpu_index,previous_snapshot,next_snapshot,role,straddles_main_start,"
        "call_record_begin,call_record_end,previous_mperf_minus,previous_aperf,previous_mperf_plus,"
        "next_mperf_minus,next_aperf,next_mperf_plus,aperf_delta,mperf_L,mperf_H,"
        "frequency_low_mhz_display,frequency_high_mhz_display,exact_band,"
        "thread_cpu_delta_lower_ns,raw_delta_upper_ns,activity_proxy_at_least_80pct,"
        "previous_triple_ns,next_triple_ns,gap_upper_ns,pure_main_wall_ns,pure_main_call_records,"
        "primary_rules_and_band_pass,flags\n");
    if (boundary_index == SIZE_MAX || !data->summary.main_start.present) {
        return;
    }
    size_t window_index = 0;
    for (size_t previous_index = boundary_index; previous_index + 1U < data->frame_count;
        ++previous_index) {
        const struct frame *previous = &data->frames[previous_index];
        const struct frame *next = &data->frames[previous_index + 1U];
        for (unsigned int cpu_index = 0; cpu_index < 2U; ++cpu_index) {
            struct window_result result = calculate_window(data,
                previous,
                next,
                cpu_index,
                data->summary.main_start.value,
                coverage->main_end.present ? coverage->main_end.value : UINT64_MAX);
            print_window(window_index, previous_index, previous, next, cpu_index, &result);
        }
        ++window_index;
    }
}

static void print_optional_json(struct optional_u64 value)
{
    if (value.present) {
        fprintf(stderr, "\"%" PRIu64 "\"", value.value);
    } else {
        fprintf(stderr, "null");
    }
}

static size_t clock_failure_count(const struct clock_value *clock)
{
    return clock_valid(clock) ? 0U : 1U;
}

static void print_analysis_summary(const struct input_data *data, const struct coverage *coverage)
{
    size_t failed_calls = 0;
    size_t unperformed_calls = 0;
    size_t failed_frames = 0;
    size_t failed_clocks = 0;
    size_t read_errors = 0;
    size_t short_reads = 0;
    size_t zero_counter_values = 0;
    for (size_t call_index = 0; call_index < data->call_record_count; ++call_index) {
        const struct call *call = &data->calls[call_index];
        failed_calls += !call->operation_performed || call->operation_status != 0 ||
                !clock_span(&call->before, &call->after)
            ? 1U
            : 0U;
        unperformed_calls += call->operation_performed ? 0U : 1U;
        failed_clocks += clock_failure_count(&call->before);
        if (call->operation_performed) {
            failed_clocks += clock_failure_count(&call->after);
        }
    }
    for (size_t checkpoint_index = 0; checkpoint_index < data->checkpoint_count;
        ++checkpoint_index) {
        failed_clocks += clock_failure_count(&data->checkpoints[checkpoint_index].raw);
    }
    for (size_t frame_index = 0; frame_index < data->frame_count; ++frame_index) {
        const struct frame *frame = &data->frames[frame_index];
        failed_frames += frame->declared_valid ? 0U : 1U;
        failed_clocks += clock_failure_count(&frame->raw_before) +
            clock_failure_count(&frame->raw_after) + clock_failure_count(&frame->thread_before) +
            clock_failure_count(&frame->thread_after);
        for (unsigned int cpu_index = 0; cpu_index < 2U; ++cpu_index) {
            for (unsigned int read_index = 0; read_index < 3U; ++read_index) {
                const struct counter_value *counter = &frame->counters[cpu_index][read_index];
                failed_clocks +=
                    clock_failure_count(&counter->before) + clock_failure_count(&counter->after);
                read_errors += counter->bytes_read < 0 ? 1U : 0U;
                short_reads += counter->bytes_read >= 0 && counter->bytes_read < 8 ? 1U : 0U;
                zero_counter_values +=
                    counter->value.present && counter->value.value == 0 ? 1U : 0U;
            }
        }
    }
    fprintf(stderr,
        "{\"validation\":\"passed\",\"producer_status\":\"%s\",\"producer_completed\":%s,"
        "\"input_lines\":%zu,\"call_records\":%zu,\"snapshot_records\":%zu,\"checkpoint_records\":%"
        "zu,"
        "\"main_call_records\":%zu,\"main_performed_calls\":%zu,\"observed_main_pairs\":%zu,"
        "\"passing_main_pairs\":%zu,\"boundary_straddle_pairs\":%zu,\"observed_main_windows_all_"
        "pass\":%s,"
        "\"engineering_diagnostic\":\"%s\",\"main_wall_ns\":",
        data->summary.status,
        coverage->producer_completed ? "true" : "false",
        data->line_count,
        data->call_record_count,
        data->frame_count,
        data->checkpoint_count,
        coverage->main_call_records,
        coverage->main_performed_calls,
        coverage->main_pairs,
        coverage->passing_pairs,
        coverage->boundary_pairs,
        coverage->main_pairs != 0 && coverage->all_pairs_pass ? "true" : "false",
        coverage->engineering_diagnostic ? "yes" : "no");
    print_optional_json(coverage->main_wall);
    fprintf(stderr,
        ",\"all_phase_failure_ledger\":{\"failed_call_records\":%zu,"
        "\"unperformed_call_records\":%zu,\"failed_snapshot_records\":%zu,\"failed_clock_reads\":%"
        "zu,"
        "\"counter_read_errors\":%zu,\"counter_short_reads\":%zu,\"valid_zero_counter_values\":%zu}"
        ","
        "\"clock_sequence_anomaly\":%s",
        failed_calls,
        unperformed_calls,
        failed_frames,
        failed_clocks,
        read_errors,
        short_reads,
        zero_counter_values,
        coverage->clock_sequence_anomaly ? "true" : "false");
    fprintf(stderr,
        ",\"pure_main_coverage_fraction\":{\"numerator_ns\":\"%" PRIu64 "\",\"denominator_ns\":",
        coverage->geometric_wall_ns);
    print_optional_json(coverage->main_wall);
    fprintf(stderr,
        "},\"pure_main_call_coverage_fraction\":{\"numerator\":%zu,\"denominator\":%zu},"
        "\"pure_main_coverage_wall_numerator_ns\":\"%" PRIu64 "\",",
        coverage->geometric_call_records,
        coverage->main_call_records,
        coverage->geometric_wall_ns);
    fprintf(stderr,
        "\"passing_pure_main_wall_ns\":\"%" PRIu64 "\",\"pure_main_coverage_call_numerator\":%zu,"
        "\"passing_pure_main_call_records\":%zu,\"head_boundary_blind_ns\":\"%" PRIu64 "\","
        "\"tail_frame_blind_ns\":\"%" PRIu64 "\",\"interior_bracket_or_uncovered_ns\":\"%" PRIu64
        "\",\"head_tail_blind_overlap_ns\":\"%" PRIu64 "\","
        "\"coverage_denominator_complete\":%s,\"full_main_coverage_certified\":false,"
        "\"frequency_interval_is_ci\":false,\"physical_precision_certified\":false,"
        "\"cpu18_independent_sample\":false,\"r02_signed_off\":false,\"r04_signed_off\":false}\n",
        coverage->passing_wall_ns,
        coverage->geometric_call_records,
        coverage->passing_call_records,
        coverage->head_blind_ns,
        coverage->tail_blind_ns,
        coverage->other_blind_ns,
        coverage->blind_overlap_ns,
        coverage->geometry_available ? "true" : "false");
}

static int compare_elapsed_ns(const void *left, const void *right)
{
    uint64_t left_ns = *(const uint64_t *)left;
    uint64_t right_ns = *(const uint64_t *)right;
    return (left_ns > right_ns) - (left_ns < right_ns);
}

static uint64_t timing_quantile(const uint64_t *sorted_ns, size_t count, unsigned int percentile)
{
    /* 与series_quantile同用最近秩；固定容量内的整数索引不引入浮点边界。 */
    size_t sample_index = ((count - 1U) * percentile + 50U) / 100U;
    return sorted_ns[sample_index];
}

static bool timing_series_statistics(uint64_t *elapsed_ns,
    size_t count,
    uint64_t *deviation_ns,
    struct timing_row *row)
{
    if (count == 0 || count > CALL_CAPACITY) {
        return false;
    }
    row->count = count;
    row->sum_elapsed_ns = 0;
    for (size_t sample_index = 0; sample_index < count; ++sample_index) {
        if (!checked_add(row->sum_elapsed_ns, elapsed_ns[sample_index], &row->sum_elapsed_ns)) {
            return false;
        }
    }
    qsort(elapsed_ns, count, sizeof(*elapsed_ns), compare_elapsed_ns);
    row->minimum_ns = elapsed_ns[0];
    row->p50_ns = timing_quantile(elapsed_ns, count, 50U);
    row->p90_ns = timing_quantile(elapsed_ns, count, 90U);
    row->p99_ns = timing_quantile(elapsed_ns, count, 99U);
    row->maximum_ns = elapsed_ns[count - 1U];
    for (size_t sample_index = 0; sample_index < count; ++sample_index) {
        uint64_t sample_ns = elapsed_ns[sample_index];
        deviation_ns[sample_index] =
            sample_ns >= row->p50_ns ? sample_ns - row->p50_ns : row->p50_ns - sample_ns;
    }
    qsort(deviation_ns, count, sizeof(*deviation_ns), compare_elapsed_ns);
    row->mad_ns = timing_quantile(deviation_ns, count, 50U);
    return true;
}

static bool append_timing_rows(const struct input_data *data,
    size_t call_begin,
    size_t call_end,
    enum phase phase,
    size_t quarter_index,
    uint64_t *elapsed_ns,
    uint64_t *deviation_ns,
    struct timing_description *description)
{
    for (size_t group_index = 0; group_index <= INPUT_COUNT; ++group_index) {
        if (description->row_count >= TIMING_ROW_COUNT) {
            return false;
        }
        struct timing_row *row = &description->rows[description->row_count];
        row->phase = phase;
        row->quarter_index = quarter_index;
        row->input_index = group_index == 0 ? SIZE_MAX : group_index - 1U;
        size_t sample_count = 0;
        for (size_t call_index = call_begin; call_index < call_end; ++call_index) {
            if (row->input_index == SIZE_MAX || call_index % INPUT_COUNT == row->input_index) {
                elapsed_ns[sample_count++] = data->calls[call_index].elapsed.value;
            }
        }
        if (!timing_series_statistics(elapsed_ns, sample_count, deviation_ns, row)) {
            return false;
        }
        ++description->row_count;
    }
    return true;
}

static size_t timing_quarter_boundary(size_t main_call_count, size_t quarter_boundary)
{
    return (main_call_count / TIMING_QUARTER_COUNT) * quarter_boundary +
        ((main_call_count % TIMING_QUARTER_COUNT) * quarter_boundary) / TIMING_QUARTER_COUNT;
}

static bool timing_main_ledger(const struct input_data *data,
    size_t main_call_begin,
    struct timing_description *description)
{
    if (main_call_begin >= data->call_record_count ||
        description->main_call_records != data->call_record_count - main_call_begin) {
        return false;
    }
    uint64_t previous_after_ns = description->main_start_ns;
    for (size_t call_index = main_call_begin; call_index < data->call_record_count; ++call_index) {
        const struct call *call = &data->calls[call_index];
        if (!call->operation_performed || call->operation_status != 0 || !call->elapsed.present ||
            !clock_span(&call->before, &call->after) ||
            call->elapsed.value != call->after.ns.value - call->before.ns.value ||
            call->before.ns.value < previous_after_ns ||
            call->after.ns.value > description->main_end_ns ||
            !checked_add(description->main_call_elapsed_sum_ns,
                call->elapsed.value,
                &description->main_call_elapsed_sum_ns)) {
            return false;
        }
        uint64_t gap_ns = call->before.ns.value - previous_after_ns;
        if (call_index == main_call_begin) {
            description->main_head_outside_ns = gap_ns;
        } else if (!checked_add(description->main_intercall_gap_sum_ns,
                       gap_ns,
                       &description->main_intercall_gap_sum_ns)) {
            return false;
        }
        previous_after_ns = call->after.ns.value;
    }
    if (description->main_call_records == 0 ||
        description->main_end_ns < description->main_start_ns ||
        previous_after_ns > description->main_end_ns ||
        description->main_wall_ns != description->main_end_ns - description->main_start_ns ||
        description->main_call_elapsed_sum_ns > description->main_wall_ns) {
        return false;
    }
    description->main_tail_outside_ns = description->main_end_ns - previous_after_ns;
    description->main_outside_call_windows_ns =
        description->main_wall_ns - description->main_call_elapsed_sum_ns;
    uint64_t outside_sum_ns = 0;
    uint64_t wall_sum_ns = 0;
    return checked_add(description->main_head_outside_ns,
               description->main_intercall_gap_sum_ns,
               &outside_sum_ns) &&
        checked_add(outside_sum_ns, description->main_tail_outside_ns, &outside_sum_ns) &&
        outside_sum_ns == description->main_outside_call_windows_ns &&
        checked_add(description->main_call_elapsed_sum_ns, outside_sum_ns, &wall_sum_ns) &&
        wall_sum_ns == description->main_wall_ns;
}

static void timing_record_position(size_t call_boundary,
    size_t main_call_begin,
    size_t call_record_count,
    size_t counts[3])
{
    if (call_boundary == main_call_begin) {
        ++counts[0];
    } else if (call_boundary > main_call_begin && call_boundary < call_record_count) {
        ++counts[1];
    } else if (call_boundary == call_record_count) {
        ++counts[2];
    }
}

static bool analyze_timing_description(const struct input_data *data,
    size_t boundary_index,
    const struct coverage *coverage,
    struct timing_description *description,
    const char **error)
{
    if (!coverage->producer_completed || coverage->clock_sequence_anomaly ||
        !data->summary.main_start.present || !coverage->main_end.present ||
        !coverage->main_wall.present || boundary_index >= data->frame_count ||
        data->call_record_count > CALL_CAPACITY) {
        *error = "timing_requires_complete_successful_original_values";
        return false;
    }
    size_t main_call_begin = data->frames[boundary_index].call_record_count;
    if (main_call_begin == 0 || main_call_begin >= data->call_record_count ||
        coverage->main_call_records != data->call_record_count - main_call_begin) {
        *error = "timing_phase_count_mismatch";
        return false;
    }
    description->warmup_call_records = main_call_begin;
    description->main_call_records = data->call_record_count - main_call_begin;
    description->main_start_ns = data->summary.main_start.value;
    description->main_end_ns = coverage->main_end.value;
    description->main_wall_ns = coverage->main_wall.value;
    for (size_t call_index = 0; call_index < data->call_record_count; ++call_index) {
        const struct call *call = &data->calls[call_index];
        enum phase expected_phase = call_index < main_call_begin ? PHASE_WARMUP : PHASE_MAIN;
        if (call->phase != expected_phase || !call->operation_performed ||
            call->operation_status != 0 || !call->elapsed.present ||
            !clock_span(&call->before, &call->after) ||
            call->elapsed.value != call->after.ns.value - call->before.ns.value) {
            *error = "timing_call_or_clock_failure";
            return false;
        }
    }
    if (!timing_main_ledger(data, main_call_begin, description)) {
        *error = "timing_main_boundary_or_conservation_failure";
        return false;
    }
    for (size_t frame_index = 0; frame_index < data->frame_count; ++frame_index) {
        const struct frame *frame = &data->frames[frame_index];
        ++description->snapshot_phase_counts[frame->phase];
        if (frame->phase == PHASE_MAIN) {
            timing_record_position(frame->call_record_count,
                main_call_begin,
                data->call_record_count,
                description->main_snapshot_position_counts);
        }
    }
    for (size_t checkpoint_index = 0; checkpoint_index < data->checkpoint_count;
        ++checkpoint_index) {
        const struct checkpoint *checkpoint = &data->checkpoints[checkpoint_index];
        ++description->checkpoint_phase_counts[checkpoint->phase];
        if (checkpoint->phase == PHASE_MAIN) {
            timing_record_position(checkpoint->call_record_count,
                main_call_begin,
                data->call_record_count,
                description->main_checkpoint_position_counts);
        }
    }
    size_t assigned_snapshots = description->main_snapshot_position_counts[0] +
        description->main_snapshot_position_counts[1] +
        description->main_snapshot_position_counts[2];
    size_t assigned_checkpoints = description->main_checkpoint_position_counts[0] +
        description->main_checkpoint_position_counts[1] +
        description->main_checkpoint_position_counts[2];
    if (assigned_snapshots != description->snapshot_phase_counts[PHASE_MAIN] ||
        assigned_checkpoints != description->checkpoint_phase_counts[PHASE_MAIN]) {
        *error = "timing_record_position_count_mismatch";
        return false;
    }
    uint64_t *elapsed_ns = calloc(CALL_CAPACITY, sizeof(*elapsed_ns));
    uint64_t *deviation_ns = calloc(CALL_CAPACITY, sizeof(*deviation_ns));
    bool passed = elapsed_ns != NULL && deviation_ns != NULL;
    if (!passed) {
        *error = "timing_allocation_failed";
    } else {
        passed = append_timing_rows(data,
                     0,
                     main_call_begin,
                     PHASE_WARMUP,
                     SIZE_MAX,
                     elapsed_ns,
                     deviation_ns,
                     description) &&
            append_timing_rows(data,
                main_call_begin,
                data->call_record_count,
                PHASE_MAIN,
                SIZE_MAX,
                elapsed_ns,
                deviation_ns,
                description);
        for (size_t quarter_index = 0; passed && quarter_index < TIMING_QUARTER_COUNT;
            ++quarter_index) {
            size_t call_begin = main_call_begin +
                timing_quarter_boundary(description->main_call_records, quarter_index);
            size_t call_end = main_call_begin +
                timing_quarter_boundary(description->main_call_records, quarter_index + 1U);
            passed = append_timing_rows(data,
                call_begin,
                call_end,
                PHASE_MAIN,
                quarter_index,
                elapsed_ns,
                deviation_ns,
                description);
        }
        passed = passed && description->row_count == TIMING_ROW_COUNT &&
            description->rows[INPUT_COUNT + 1U].sum_elapsed_ns ==
                description->main_call_elapsed_sum_ns;
        if (!passed) {
            *error = "timing_empty_group_or_sum_overflow";
        }
    }
    free(deviation_ns);
    free(elapsed_ns);
    return passed;
}

static void print_timing_csv(const struct timing_description *description)
{
    printf("scope,phase,quarter_index,input_index,count,sum_elapsed_ns,mean_ns,min_ns,"
           "p50_ns,p90_ns,p99_ns,max_ns,mad_ns\n");
    for (size_t row_index = 0; row_index < description->row_count; ++row_index) {
        const struct timing_row *row = &description->rows[row_index];
        printf("%s,%s,",
            row->quarter_index == SIZE_MAX ? "whole_phase" : "main_quarter",
            row->phase == PHASE_WARMUP ? "warmup" : "main");
        if (row->quarter_index == SIZE_MAX) {
            printf("all,");
        } else {
            printf("%zu,", row->quarter_index);
        }
        if (row->input_index == SIZE_MAX) {
            printf("all,");
        } else {
            printf("%zu,", row->input_index);
        }
        printf("%zu,%" PRIu64 ",%.12Lf,%" PRIu64 ",%" PRIu64 ",%" PRIu64 ",%" PRIu64 ",%" PRIu64
               ",%" PRIu64 "\n",
            row->count,
            row->sum_elapsed_ns,
            (long double)row->sum_elapsed_ns / (long double)row->count,
            row->minimum_ns,
            row->p50_ns,
            row->p90_ns,
            row->p99_ns,
            row->maximum_ns,
            row->mad_ns);
    }
}

static void print_timing_summary(const struct input_data *data,
    const struct timing_description *description)
{
    fprintf(stderr,
        "{\"validation\":\"passed\",\"mode\":\"timing_description\",\"descriptive_only\":true,"
        "\"producer_completed\":true,\"timing_rows\":%zu,\"call_records\":%zu,"
        "\"warmup_call_records\":%zu,\"main_call_records\":%zu,"
        "\"main_start_ns\":\"%" PRIu64 "\",\"main_end_ns\":\"%" PRIu64
        "\",\"main_wall_ns\":\"%" PRIu64 "\",\"main_call_elapsed_sum_ns\":\"%" PRIu64
        "\",\"main_outside_call_windows_ns\":\"%" PRIu64 "\","
        "\"main_head_outside_ns\":\"%" PRIu64 "\",\"main_intercall_gap_sum_ns\":\"%" PRIu64
        "\",\"main_tail_outside_ns\":\"%" PRIu64 "\",\"main_intercall_gap_count\":%zu,"
        "\"main_wall_conservation_exact\":true,",
        description->row_count,
        data->call_record_count,
        description->warmup_call_records,
        description->main_call_records,
        description->main_start_ns,
        description->main_end_ns,
        description->main_wall_ns,
        description->main_call_elapsed_sum_ns,
        description->main_outside_call_windows_ns,
        description->main_head_outside_ns,
        description->main_intercall_gap_sum_ns,
        description->main_tail_outside_ns,
        description->main_call_records - 1U);
    fprintf(stderr,
        "\"record_position_counts\":{\"snapshots\":{\"all\":%zu,\"warmup_phase\":%zu,"
        "\"main_phase\":%zu,\"main_head\":%zu,\"main_interior\":%zu,\"main_tail\":%zu},"
        "\"checkpoints\":{\"all\":%zu,\"warmup_phase\":%zu,\"main_phase\":%zu,"
        "\"main_head\":%zu,\"main_interior\":%zu,\"main_tail\":%zu}},"
        "\"record_positions_are_call_boundary_allocations_only\":true,"
        "\"causal_overhead_identified\":false,\"long_tails_removed\":0,"
        "\"quantile_rule\":\"floor(percentile*(count-1)/100+1/2),no_interpolation\","
        "\"mad_rule\":\"same_p50_of_absolute_deviations_from_p50\","
        "\"mean_decimal_places\":12,\"mean_is_display_only\":true,"
        "\"iid_asserted\":false,\"stationarity_asserted\":false,"
        "\"physical_precision_certified\":false,\"r02_signed_off\":false,"
        "\"r04_signed_off\":false}\n",
        data->frame_count,
        description->snapshot_phase_counts[PHASE_WARMUP],
        description->snapshot_phase_counts[PHASE_MAIN],
        description->main_snapshot_position_counts[0],
        description->main_snapshot_position_counts[1],
        description->main_snapshot_position_counts[2],
        data->checkpoint_count,
        description->checkpoint_phase_counts[PHASE_WARMUP],
        description->checkpoint_phase_counts[PHASE_MAIN],
        description->main_checkpoint_position_counts[0],
        description->main_checkpoint_position_counts[1],
        description->main_checkpoint_position_counts[2]);
}

static struct frame fixture_frame(uint64_t origin_ns, uint64_t count, uint64_t cpu_ns)
{
    struct frame frame = {0};
    frame.raw_before.ns = (struct optional_u64){origin_ns, true};
    frame.raw_after.ns = (struct optional_u64){origin_ns + 10U, true};
    frame.thread_before.ns = (struct optional_u64){cpu_ns, true};
    frame.thread_after.ns = (struct optional_u64){cpu_ns + 10U, true};
    for (unsigned int cpu_index = 0; cpu_index < 2U; ++cpu_index) {
        for (unsigned int read_index = 0; read_index < 3U; ++read_index) {
            frame.counters[cpu_index][read_index].value = (struct optional_u64){count, true};
            frame.counters[cpu_index][read_index].before.ns =
                (struct optional_u64){origin_ns + 2U, true};
            frame.counters[cpu_index][read_index].after.ns =
                (struct optional_u64){origin_ns + 3U, true};
        }
    }
    frame.declared_valid = true;
    return frame;
}

static bool fixture_append_count(int written, size_t *used)
{
    if (written < 0 || (size_t)written >= LINE_CAPACITY - *used) {
        return false;
    }
    *used += (size_t)written;
    return true;
}

static bool fixture_snapshot_line(char *line,
    size_t index,
    const char *kind,
    const char *phase,
    size_t call_count,
    uint64_t origin_ns,
    uint64_t count,
    bool invalid_final_clock)
{
    size_t used = 0;
    char raw_after[100];
    if (invalid_final_clock) {
        (void)snprintf(raw_after, sizeof(raw_after), "{\"ns\":null,\"errno\":5}");
    } else {
        (void)snprintf(raw_after,
            sizeof(raw_after),
            "{\"ns\":\"%" PRIu64 "\",\"errno\":null}",
            origin_ns + 20U);
    }
    int written = snprintf(line,
        LINE_CAPACITY,
        "{\"type\":\"snapshot\",\"index\":%zu,\"kind\":\"%s\",\"phase\":\"%s\","
        "\"call_records\":%zu,\"valid_reads_and_clocks\":%s,\"scheduled_deadline_ns\":null,"
        "\"missed_deadlines\":\"0\",\"raw_before\":{\"ns\":\"%" PRIu64 "\",\"errno\":null},"
        "\"thread_cpu_before\":{\"ns\":\"%" PRIu64 "\",\"errno\":null},"
        "\"thread_cpu_after\":{\"ns\":\"%" PRIu64 "\",\"errno\":null},"
        "\"raw_after\":%s,\"cpu_reads\":[",
        index,
        kind,
        phase,
        call_count,
        invalid_final_clock ? "false" : "true",
        origin_ns,
        origin_ns + 1U,
        origin_ns + 19U,
        raw_after);
    if (!fixture_append_count(written, &used)) {
        return false;
    }
    for (unsigned int cpu_index = 0; cpu_index < 2U; ++cpu_index) {
        written = snprintf(line + used,
            LINE_CAPACITY - used,
            "%s{\"cpu_index\":%u,\"reads\":[",
            cpu_index == 0 ? "" : ",",
            cpu_index == 0 ? 2U : 18U);
        if (!fixture_append_count(written, &used)) {
            return false;
        }
        for (unsigned int read_index = 0; read_index < 3U; ++read_index) {
            uint64_t before_ns = origin_ns + 2U + cpu_index * 6U + read_index * 2U;
            written = snprintf(line + used,
                LINE_CAPACITY - used,
                "%s{\"register\":\"%s\",\"bytes_read\":8,\"errno\":null,\"value_u64\":\"%" PRIu64
                "\",\"before\":{\"ns\":\"%" PRIu64 "\",\"errno\":null},"
                "\"after\":{\"ns\":\"%" PRIu64 "\",\"errno\":null}}",
                read_index == 0 ? "" : ",",
                read_index == 1U ? "0xe8" : "0xe7",
                cpu_index == 0 ? count : 0,
                before_ns,
                before_ns + 1U);
            if (!fixture_append_count(written, &used)) {
                return false;
            }
        }
        written = snprintf(line + used, LINE_CAPACITY - used, "]}");
        if (!fixture_append_count(written, &used)) {
            return false;
        }
    }
    written = snprintf(line + used, LINE_CAPACITY - used, "]}");
    return fixture_append_count(written, &used);
}

static bool fixture_parse(struct input_data *data, const char *line)
{
    const char *error = NULL;
    size_t column = 0;
    return parse_line(data, line, &error, &column);
}

static bool whole_fixture(unsigned int failure_mode)
{
    struct input_data data = {0};
    data.frames = calloc(SNAPSHOT_CAPACITY, sizeof(*data.frames));
    data.checkpoints = calloc(CHECKPOINT_CAPACITY, sizeof(*data.checkpoints));
    data.calls = calloc(CALL_CAPACITY, sizeof(*data.calls));
    bool passed = false;
    if (data.frames == NULL || data.checkpoints == NULL || data.calls == NULL) {
        goto cleanup;
    }
    static const char contract[] =
        "{\"type\":\"contract\",\"schema_version\":1,\"implementation\":\"reference\","
        "\"clock\":\"CLOCK_MONOTONIC_RAW\",\"thread_clock\":\"CLOCK_THREAD_CPUTIME_ID\","
        "\"workload_cpu\":2,\"observation_cpu\":18,\"input_count\":8,\"input_order\":\"index_"
        "modulo_8\","
        "\"iid_claimed\":false,\"warmup_target_ns\":\"1000000000\",\"main_target_ns\":"
        "\"4000000000\","
        "\"soft_run_limit_ns\":\"6000000000\",\"sample_period_ns\":\"20000000\",\"check_call_"
        "period\":64,"
        "\"call_capacity\":250000,\"snapshot_capacity\":512,\"frequency_converted\":false,"
        "\"configuration_writes\":0,\"r02_signed_off\":false}";
    if (!fixture_parse(&data, contract) ||
        !fixture_parse(&data,
            "{\"type\":\"device\",\"cpu_index\":2,\"status\":\"ok\",\"errno\":null,\"close_errno\":"
            "null,\"owner_uid\":\"0\",\"major\":202,\"minor\":2}") ||
        !fixture_parse(&data,
            "{\"type\":\"device\",\"cpu_index\":18,\"status\":\"ok\",\"errno\":null,\"close_"
            "errno\":null,\"owner_uid\":\"0\",\"major\":202,\"minor\":18}")) {
        goto cleanup;
    }
    char line[LINE_CAPACITY];
    for (unsigned int input_index = 0; input_index < INPUT_COUNT; ++input_index) {
        (void)snprintf(line,
            sizeof(line),
            "{\"type\":\"public_input\",\"input_index\":%u,\"ciphertext_sha3_256\":"
            "\"0000000000000000000000000000000000000000000000000000000000000000\"}",
            input_index);
        if (!fixture_parse(&data, line)) {
            goto cleanup;
        }
    }
    uint64_t warmup_start = 20;
    uint64_t warmup_checkpoint = warmup_start + WARMUP_NS;
    uint64_t main_start = warmup_checkpoint + 21U;
    uint64_t main_checkpoint = main_start + MAIN_NS;
    if (!fixture_snapshot_line(line, 0, "start", "warmup", 0, 0, 1000, false) ||
        !fixture_parse(&data, line) ||
        !fixture_snapshot_line(line,
            1,
            "warmup_to_main",
            "warmup",
            64,
            warmup_checkpoint + 1U,
            1000001000,
            false) ||
        !fixture_parse(&data, line) ||
        !fixture_snapshot_line(line,
            2,
            "end",
            "main",
            128,
            main_checkpoint + 1U,
            5000001000,
            failure_mode == 4U) ||
        !fixture_parse(&data, line)) {
        goto cleanup;
    }
    for (unsigned int checkpoint_index = 0; checkpoint_index < 2U; ++checkpoint_index) {
        (void)snprintf(line,
            sizeof(line),
            "{\"type\":\"checkpoint\",\"index\":%u,\"phase\":\"%s\",\"call_records\":%u,\"raw\":{"
            "\"ns\":\"%" PRIu64 "\",\"errno\":null}}",
            checkpoint_index,
            checkpoint_index == 0 ? "warmup" : "main",
            (checkpoint_index + 1U) * 64U,
            checkpoint_index == 0 ? warmup_checkpoint : main_checkpoint);
        if (!fixture_parse(&data, line)) {
            goto cleanup;
        }
    }
    for (size_t call_index = 0; call_index < 128U; ++call_index) {
        bool main_phase = call_index >= 64U;
        uint64_t before_ns = (main_phase ? main_start : warmup_start) + 100U +
            (call_index % 64U) * (main_phase ? UINT64_C(62500000) : UINT64_C(15625000));
        (void)snprintf(line,
            sizeof(line),
            "{\"type\":\"decap\",\"index\":%zu,\"phase\":\"%s\",\"input_index\":%zu,"
            "\"operation_performed\":true,\"operation_status\":0,\"before\":{\"ns\":\"%" PRIu64
            "\",\"errno\":null},\"after\":{\"ns\":\"%" PRIu64
            "\",\"errno\":null},\"elapsed_ns\":\"10\"}",
            call_index,
            main_phase ? "main" : "warmup",
            call_index % INPUT_COUNT,
            before_ns,
            before_ns + 10U);
        if (!fixture_parse(&data, line)) {
            goto cleanup;
        }
    }
    const char *error = NULL;
    size_t boundary_index = SIZE_MAX;
    bool clock_anomaly = false;
    bool producer_completed = false;
    if (failure_mode == 3U) {
        passed = !validate_integrity(&data,
            &error,
            &boundary_index,
            &clock_anomaly,
            &producer_completed);
        goto cleanup;
    }
    (void)snprintf(line,
        sizeof(line),
        "{\"type\":\"summary\",\"status\":\"%s\",\"call_records\":128,\"snapshot_records\":"
        "3,"
        "\"checkpoint_records\":2,\"prepared_input_count\":8,\"input_operation_status\":0,"
        "\"affinity_verified\":true,"
        "\"affinity_errno\":null,\"allocation_errnos\":[null,null,null],\"warmup_start_ns\":"
        "\"%" PRIu64 "\",\"main_start_ns\":\"%" PRIu64
        "\",\"valid_final_snapshot\":%s,\"r02_signed_off\":false}",
        failure_mode == 4U ? "clock_failed" : "completed",
        warmup_start,
        main_start,
        failure_mode == 4U ? "false" : "true");
    if (failure_mode == 1U) {
        line[strlen(line) - 1U] = '\0';
        passed = !fixture_parse(&data, line);
        goto cleanup;
    }
    if (!fixture_parse(&data, line)) {
        goto cleanup;
    }
    if (failure_mode == 2U) {
        passed = !fixture_parse(&data, line);
        goto cleanup;
    }
    struct coverage coverage = {0};
    if (!validate_integrity(&data, &error, &boundary_index, &clock_anomaly, &producer_completed) ||
        !validate_schedule(&data, &error) ||
        !analyze_data(&data, boundary_index, producer_completed, &coverage)) {
        goto cleanup;
    }
    struct window_result window = calculate_window(&data,
        &data.frames[1],
        &data.frames[2],
        0,
        main_start,
        main_checkpoint + 21U);
    if (failure_mode == 4U) {
        passed = !producer_completed && clock_anomaly && coverage.main_pairs == 1U &&
            !coverage.main_wall.present && !coverage.engineering_diagnostic &&
            (window.flags & FLAG_CLOCK) != 0 && window.band == BAND_UNAVAILABLE &&
            window.straddles_main_start;
        goto cleanup;
    }
    passed = producer_completed && !clock_anomaly && boundary_index == 1U &&
        coverage.main_pairs == 1U && coverage.main_call_records == 64U &&
        coverage.main_performed_calls == 64U && window.band == BAND_IN &&
        (window.flags & FLAG_GAP) != 0 && window.straddles_main_start &&
        coverage.geometric_wall_ns == 0 && coverage.blind_overlap_ns == 1U &&
        !coverage.engineering_diagnostic &&
        coverage.head_blind_ns + coverage.tail_blind_ns - coverage.blind_overlap_ns ==
            coverage.main_wall.value;
cleanup:
    free(data.calls);
    free(data.checkpoints);
    free(data.frames);
    return passed;
}

static bool selfcheck(void)
{
    bool overflow = false;
    if (exact_band(100, 100, 100, &overflow) != BAND_IN || overflow ||
        exact_band(99, 100, 100, &overflow) != BAND_IN ||
        exact_band(101, 100, 100, &overflow) != BAND_IN ||
        exact_band(100, 99, 102, &overflow) != BAND_OVERLAP ||
        exact_band(98, 100, 100, &overflow) != BAND_LOW ||
        exact_band(102, 100, 100, &overflow) != BAND_HIGH ||
        exact_band(UINT64_MAX, 100, 100, &overflow) != BAND_UNAVAILABLE || !overflow) {
        return false;
    }
    struct frame previous = fixture_frame(100, 1000, 100);
    struct frame next = fixture_frame(10000100, 2000, 10000100);
    struct window_result result = calculate_window(NULL, &previous, &next, 0, 0, 20000000);
    if (!result.rules_pass || result.band != BAND_IN) {
        return false;
    }
    next.counters[0][0].value.value = 1000;
    result = calculate_window(NULL, &previous, &next, 0, 0, 20000000);
    if ((result.flags & FLAG_ZERO_DENOMINATOR) == 0) {
        return false;
    }
    next = fixture_frame(10000100, 999, 10000100);
    result = calculate_window(NULL, &previous, &next, 0, 0, 20000000);
    if ((result.flags & FLAG_DECREASE) == 0) {
        return false;
    }
    next = fixture_frame(10000100, 2000, 1000);
    result = calculate_window(NULL, &previous, &next, 0, 0, 20000000);
    if ((result.flags & FLAG_LOW_ACTIVITY) == 0) {
        return false;
    }
    next = fixture_frame(50000100, 2000, 50000100);
    result = calculate_window(NULL, &previous, &next, 0, 0, 60000000);
    if ((result.flags & FLAG_GAP) == 0) {
        return false;
    }
    next = fixture_frame(10000100, 2000, 10000100);
    next.counters[0][2].after.ns.value += MAX_TRIPLE_NS;
    result = calculate_window(NULL, &previous, &next, 0, 0, 20000000);
    if ((result.flags & FLAG_TRIPLE_SPAN) == 0) {
        return false;
    }
    next = fixture_frame(10000100, 2000, 10000100);
    next.counters[0][1].before.error_number = 34;
    result = calculate_window(NULL, &previous, &next, 0, 0, 20000000);
    if ((result.flags & FLAG_CLOCK) == 0 || diagnostic_decision(true, 0, true)) {
        return false;
    }
    next = fixture_frame(10000100, 2000, 10000100);
    next.counters[0][1].value.present = false;
    next.counters[0][1].bytes_read = 7;
    result = calculate_window(NULL, &previous, &next, 0, 0, 20000000);
    if ((result.flags & FLAG_READ) == 0 || result.band != BAND_UNAVAILABLE) {
        return false;
    }
    next = fixture_frame(10000100, 2000, 10000100);
    next.kind = FRAME_PERIODIC;
    next.missed_deadlines = 1;
    result = calculate_window(NULL, &previous, &next, 0, 0, 20000000);
    if ((result.flags & FLAG_CADENCE) == 0) {
        return false;
    }
    previous = fixture_frame(95, 1000, 95);
    next = fixture_frame(200, 2000, 200);
    bool straddles = false;
    bool overlap = false;
    if (pure_segment(&previous, &next, 0, 100, 320, &straddles, &overlap) != 0 || !straddles) {
        return false;
    }
    previous = fixture_frame(200, 1000, 200);
    next = fixture_frame(300, 2000, 300);
    if (pure_segment(&previous, &next, 0, 100, 320, &straddles, &overlap) != 99 || overlap ||
        straddles || 320U - next.counters[0][1].before.ns.value != 18U) {
        return false;
    }
    previous.counters[0][1].after.ns.value = 305;
    if (pure_segment(&previous, &next, 0, 100, 320, &straddles, &overlap) != 0 || !overlap) {
        return false;
    }
    struct clock_value parsed_clock = {0};
    struct parser parser = {.text = "{\"ns\":\"0\",\"errno\":null}"};
    if (!clock_value(&parser, &parsed_clock) || !clock_valid(&parsed_clock) ||
        parsed_clock.ns.value != 0) {
        return false;
    }
    parser = (struct parser){.text = "{\"ns\":\"1\",\"ns\":\"2\",\"errno\":null}"};
    parsed_clock = (struct clock_value){0};
    if (clock_value(&parser, &parsed_clock)) {
        return false;
    }
    parser = (struct parser){.text = "{\"ns\":\"1\",\"errno\":"};
    parsed_clock = (struct clock_value){0};
    if (clock_value(&parser, &parsed_clock)) {
        return false;
    }
    uint64_t number = 0;
    if (unsigned_digits("18446744073709551616", &number) || unsigned_digits("01", &number)) {
        return false;
    }
    parser = (struct parser){.text = "{\"ns\":\"1\",\"unknown\":null}"};
    parsed_clock = (struct clock_value){0};
    if (clock_value(&parser, &parsed_clock)) {
        return false;
    }
    parser = (struct parser){.text = "\"\\u0031\""};
    char parsed_string[16];
    if (string_value(&parser, parsed_string, sizeof(parsed_string))) {
        return false;
    }
    parser = (struct parser){.text = "{", .depth = DEPTH_CAPACITY};
    if (punctuation(&parser, '{')) {
        return false;
    }
    char line_limit_fixture[LINE_CAPACITY];
    memset(line_limit_fixture, ' ', sizeof(line_limit_fixture));
    line_limit_fixture[sizeof(line_limit_fixture) - 1U] = '\0';
    const char *line_error = NULL;
    if (finish_input_line(line_limit_fixture, &line_error) || line_error == NULL) {
        return false;
    }
    struct counter_value parsed_counter = {0};
    parser = (struct parser){
        .text =
            "{\"register\":\"0xe7\",\"bytes_read\":7,\"errno\":null,\"value_u64\":null,\"before\":{"
            "\"ns\":\"1\",\"errno\":null},\"after\":{\"ns\":\"2\",\"errno\":null}}"};
    if (!counter_value(&parser, &parsed_counter, 0) || parsed_counter.value.present ||
        parsed_counter.bytes_read != 7) {
        return false;
    }
    struct input_data data = {0};
    const char *error = NULL;
    size_t boundary_index = 0;
    bool anomaly = false;
    bool completed = false;
    return !validate_integrity(&data, &error, &boundary_index, &anomaly, &completed) &&
        error != NULL && !diagnostic_decision(false, 1, true) &&
        !diagnostic_decision(true, 1, false) && whole_fixture(0) && whole_fixture(1) &&
        whole_fixture(2) && whole_fixture(3) && whole_fixture(4);
}

static bool timing_fixture(void)
{
    struct call calls[40] = {0};
    struct frame frames[4] = {0};
    struct checkpoint checkpoints[3] = {0};
    struct input_data data = {.calls = calls,
        .frames = frames,
        .checkpoints = checkpoints,
        .call_record_count = 40,
        .frame_count = 4,
        .checkpoint_count = 3};
    data.summary.main_start = (struct optional_u64){200, true};
    frames[0].phase = PHASE_WARMUP;
    frames[1].phase = PHASE_WARMUP;
    frames[1].call_record_count = 8;
    frames[2].phase = PHASE_MAIN;
    frames[2].call_record_count = 24;
    frames[3].phase = PHASE_MAIN;
    frames[3].call_record_count = 40;
    checkpoints[0].phase = PHASE_WARMUP;
    checkpoints[0].call_record_count = 8;
    checkpoints[1].phase = PHASE_MAIN;
    checkpoints[1].call_record_count = 24;
    checkpoints[2].phase = PHASE_MAIN;
    checkpoints[2].call_record_count = 40;
    for (size_t call_index = 0; call_index < data.call_record_count; ++call_index) {
        struct call *call = &calls[call_index];
        bool main_phase = call_index >= 8U;
        uint64_t before_ns = main_phase ? 203U + (call_index - 8U) * 11U : 20U + call_index * 10U;
        uint64_t elapsed_ns = call_index % INPUT_COUNT + 1U;
        call->phase = main_phase ? PHASE_MAIN : PHASE_WARMUP;
        call->operation_performed = true;
        call->before.ns = (struct optional_u64){before_ns, true};
        call->after.ns = (struct optional_u64){before_ns + elapsed_ns, true};
        call->elapsed = (struct optional_u64){elapsed_ns, true};
    }
    struct coverage coverage = {.producer_completed = true,
        .main_call_records = 32,
        .main_end = {560, true},
        .main_wall = {360, true}};
    struct timing_description description = {0};
    const char *error = NULL;
    if (!analyze_timing_description(&data, 1, &coverage, &description, &error) || error != NULL ||
        description.row_count != 54U || description.warmup_call_records != 8U ||
        description.main_call_records != 32U || description.main_call_elapsed_sum_ns != 144U ||
        description.main_outside_call_windows_ns != 216U ||
        description.main_head_outside_ns != 3U || description.main_intercall_gap_sum_ns != 205U ||
        description.main_tail_outside_ns != 8U || description.snapshot_phase_counts[0] != 2U ||
        description.snapshot_phase_counts[1] != 2U ||
        description.checkpoint_phase_counts[0] != 1U ||
        description.checkpoint_phase_counts[1] != 2U ||
        description.main_snapshot_position_counts[0] != 0 ||
        description.main_snapshot_position_counts[1] != 1U ||
        description.main_snapshot_position_counts[2] != 1U ||
        description.main_checkpoint_position_counts[0] != 0 ||
        description.main_checkpoint_position_counts[1] != 1U ||
        description.main_checkpoint_position_counts[2] != 1U) {
        return false;
    }
    for (size_t block_index = 0; block_index < 6U; ++block_index) {
        size_t row_begin = block_index * (INPUT_COUNT + 1U);
        const struct timing_row *all = &description.rows[row_begin];
        size_t repetitions = block_index == 1U ? 4U : 1U;
        if (all->input_index != SIZE_MAX || all->count != INPUT_COUNT * repetitions ||
            all->sum_elapsed_ns != 36U * repetitions || all->minimum_ns != 1U ||
            all->p50_ns != 5U || all->p90_ns != (repetitions == 4U ? 8U : 7U) ||
            all->p99_ns != 8U || all->maximum_ns != 8U || all->mad_ns != 2U ||
            all->phase != (block_index == 0 ? PHASE_WARMUP : PHASE_MAIN) ||
            all->quarter_index != (block_index < 2U ? SIZE_MAX : block_index - 2U)) {
            return false;
        }
        for (size_t input_index = 0; input_index < INPUT_COUNT; ++input_index) {
            const struct timing_row *row = &description.rows[row_begin + input_index + 1U];
            uint64_t duration_ns = input_index + 1U;
            if (row->input_index != input_index || row->count != repetitions ||
                row->sum_elapsed_ns != duration_ns * repetitions ||
                row->minimum_ns != duration_ns || row->p50_ns != duration_ns ||
                row->p90_ns != duration_ns || row->p99_ns != duration_ns ||
                row->maximum_ns != duration_ns || row->mad_ns != 0) {
                return false;
            }
        }
    }
    description = (struct timing_description){0};
    calls[0].before.error_number = EIO;
    if (analyze_timing_description(&data, 1, &coverage, &description, &error)) {
        return false;
    }
    calls[0].before.error_number = 0;
    description = (struct timing_description){0};
    calls[39].operation_status = 1;
    if (analyze_timing_description(&data, 1, &coverage, &description, &error)) {
        return false;
    }
    calls[39].operation_status = 0;
    description = (struct timing_description){0};
    coverage.clock_sequence_anomaly = true;
    if (analyze_timing_description(&data, 1, &coverage, &description, &error)) {
        return false;
    }
    coverage.clock_sequence_anomaly = false;
    description = (struct timing_description){0};
    coverage.main_end.value = 551;
    coverage.main_wall.value = 351;
    if (analyze_timing_description(&data, 1, &coverage, &description, &error)) {
        return false;
    }
    coverage.main_end.value = 560;
    coverage.main_wall.value = 359;
    description = (struct timing_description){0};
    if (analyze_timing_description(&data, 1, &coverage, &description, &error)) {
        return false;
    }
    coverage.main_wall.value = 360;
    coverage.producer_completed = false;
    description = (struct timing_description){0};
    if (analyze_timing_description(&data, 1, &coverage, &description, &error)) {
        return false;
    }
    description = (struct timing_description){.main_call_records = 32,
        .main_start_ns = 204,
        .main_end_ns = 560,
        .main_wall_ns = 356};
    if (timing_main_ledger(&data, 8, &description)) {
        return false;
    }
    description = (struct timing_description){.main_call_records = 32,
        .main_start_ns = 200,
        .main_end_ns = 560,
        .main_wall_ns = 360};
    calls[9].before.ns.value = calls[8].after.ns.value - 1U;
    calls[9].elapsed.value = calls[9].after.ns.value - calls[9].before.ns.value;
    return !timing_main_ledger(&data, 8, &description);
}

static bool timing_selfcheck(void)
{
    uint64_t odd_ns[] = {9, 1, 7, 1, 3};
    uint64_t even_ns[] = {10, 2, 8, 4};
    uint64_t single_ns[] = {UINT64_MAX};
    uint64_t extremes_ns[] = {0, UINT64_MAX};
    uint64_t overflowing_ns[] = {UINT64_MAX, 1};
    uint64_t deviation_ns[5] = {0};
    struct timing_row row = {0};
    if (!timing_series_statistics(odd_ns, 5, deviation_ns, &row) || row.sum_elapsed_ns != 21U ||
        row.minimum_ns != 1U || row.p50_ns != 3U || row.p90_ns != 9U || row.p99_ns != 9U ||
        row.maximum_ns != 9U || row.mad_ns != 2U ||
        !timing_series_statistics(even_ns, 4, deviation_ns, &row) || row.sum_elapsed_ns != 24U ||
        row.minimum_ns != 2U || row.p50_ns != 8U || row.p90_ns != 10U || row.p99_ns != 10U ||
        row.maximum_ns != 10U || row.mad_ns != 4U ||
        !timing_series_statistics(single_ns, 1, deviation_ns, &row) ||
        row.sum_elapsed_ns != UINT64_MAX || row.p50_ns != UINT64_MAX || row.mad_ns != 0 ||
        !timing_series_statistics(extremes_ns, 2, deviation_ns, &row) ||
        row.sum_elapsed_ns != UINT64_MAX || row.p50_ns != UINT64_MAX || row.mad_ns != UINT64_MAX ||
        timing_series_statistics(overflowing_ns, 2, deviation_ns, &row) ||
        timing_series_statistics(single_ns, 0, deviation_ns, &row)) {
        return false;
    }
    static const size_t expected_boundaries[] = {0, 2, 5, 8, 11};
    for (size_t boundary_index = 0; boundary_index <= TIMING_QUARTER_COUNT; ++boundary_index) {
        if (timing_quarter_boundary(11, boundary_index) != expected_boundaries[boundary_index]) {
            return false;
        }
    }
    size_t positions[3] = {0};
    timing_record_position(8, 8, 40, positions);
    timing_record_position(24, 8, 40, positions);
    timing_record_position(40, 8, 40, positions);
    return positions[0] == 1U && positions[1] == 1U && positions[2] == 1U && timing_fixture();
}

int main(int argument_count, char **arguments)
{
    if (argument_count == 2 && strcmp(arguments[1], "--selfcheck") == 0) {
        bool valid = selfcheck();
        printf("{\"selfcheck\":\"%s\",\"fixture_only\":true,\"hardware_data_analyzed\":false}\n",
            valid ? "passed" : "failed");
        return valid && fflush(stdout) == 0 && !ferror(stdout) ? 0 : 1;
    }
    if (argument_count == 2 && strcmp(arguments[1], "--timing-selfcheck") == 0) {
        bool valid = selfcheck() && timing_selfcheck();
        printf("{\"timing_selfcheck\":\"%s\",\"fixture_only\":true,"
               "\"hardware_data_analyzed\":false}\n",
            valid ? "passed" : "failed");
        return valid && fflush(stdout) == 0 && !ferror(stdout) ? 0 : 1;
    }
    bool timing_mode = argument_count == 3 && strcmp(arguments[1], "--timing-description") == 0;
    if ((argument_count != 2 && !timing_mode) ||
        (argument_count == 2 && strcmp(arguments[1], "--timing-description") == 0)) {
        fprintf(stderr,
            "usage: analyze_windows INPUT.jsonl | --timing-description INPUT.jsonl | "
            "--selfcheck | --timing-selfcheck\n");
        return 2;
    }
    struct input_data data = {0};
    data.frames = calloc(SNAPSHOT_CAPACITY, sizeof(*data.frames));
    data.checkpoints = calloc(CHECKPOINT_CAPACITY, sizeof(*data.checkpoints));
    data.calls = calloc(CALL_CAPACITY, sizeof(*data.calls));
    FILE *input = NULL;
    const char *error = NULL;
    size_t column = 0;
    if (data.frames == NULL || data.checkpoints == NULL || data.calls == NULL) {
        error = "allocation_failed";
    } else {
        input = fopen(arguments[timing_mode ? 2 : 1], "rb");
        if (input == NULL) {
            error = "input_open_failed";
        }
    }
    char line[LINE_CAPACITY];
    while (error == NULL && fgets(line, sizeof(line), input) != NULL) {
        ++data.line_count;
        if (!finish_input_line(line, &error)) {
            break;
        }
        if (!parse_line(&data, line, &error, &column)) {
            break;
        }
    }
    if (input != NULL) {
        if (ferror(input) && error == NULL) {
            error = "input_read_failed";
        }
        if (fclose(input) != 0 && error == NULL) {
            error = "input_close_failed";
        }
    }
    size_t boundary_index = SIZE_MAX;
    bool clock_anomaly = false;
    bool producer_completed = false;
    if (error == NULL &&
        !validate_integrity(&data, &error, &boundary_index, &clock_anomaly, &producer_completed)) {
        if (error == NULL) {
            error = "integrity_failed";
        }
    }
    if (error == NULL && !validate_schedule(&data, &error)) {
        if (error == NULL) {
            error = "schedule_failed";
        }
    }
    struct coverage coverage = {0};
    if (error == NULL && !analyze_data(&data, boundary_index, producer_completed, &coverage)) {
        error = "coverage_arithmetic_or_overlap";
    }
    coverage.clock_sequence_anomaly = clock_anomaly;
    struct timing_description description = {0};
    if (error == NULL && timing_mode &&
        !analyze_timing_description(&data, boundary_index, &coverage, &description, &error)) {
        if (error == NULL) {
            error = "timing_description_failed";
        }
    }
    if (error == NULL) {
        if (timing_mode) {
            print_timing_csv(&description);
            print_timing_summary(&data, &description);
        } else {
            print_analysis_csv(&data, boundary_index, &coverage);
            print_analysis_summary(&data, &coverage);
        }
    } else if (timing_mode) {
        fprintf(stderr,
            "{\"validation\":\"failed\",\"mode\":\"timing_description\",\"reason\":\"%s\","
            "\"line\":%zu,\"column\":%zu,\"timing_description\":\"unknown\","
            "\"partial_or_unknown\":true,\"r02_signed_off\":false,\"r04_signed_off\":false}\n",
            error,
            data.line_count,
            column);
    } else {
        fprintf(stderr,
            "{\"validation\":\"failed\",\"reason\":\"%s\",\"line\":%zu,\"column\":%zu,"
            "\"engineering_diagnostic\":\"no\",\"r02_signed_off\":false,\"r04_signed_off\":false}"
            "\n",
            error,
            data.line_count,
            column);
    }
    bool output_failed =
        fflush(stdout) != 0 || ferror(stdout) || fflush(stderr) != 0 || ferror(stderr);
    free(data.calls);
    free(data.checkpoints);
    free(data.frames);
    return error == NULL && !output_failed ? 0 : 1;
}
