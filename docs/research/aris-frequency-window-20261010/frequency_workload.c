#define _GNU_SOURCE
#define _POSIX_C_SOURCE 200809L

#include "mlkem.h"
#include "src/fips202/fips202.h"

#include <errno.h>
#include <fcntl.h>
#include <inttypes.h>
#include <stdatomic.h>
#include <stdbool.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/stat.h>
#include <sys/types.h>
#include <time.h>
#include <unistd.h>

#if defined(__linux__) && defined(__x86_64__)
#include <sched.h>
#include <sys/prctl.h>
#include <sys/sysmacros.h>
#define HAS_FREQUENCY_WORKLOAD 1
#else
#define HAS_FREQUENCY_WORKLOAD 0
#endif

#if HAS_FREQUENCY_WORKLOAD
static bool disable_process_dumping(int *error_number)
{
    if (prctl(PR_SET_DUMPABLE, 0L, 0L, 0L, 0L) != 0) {
        *error_number = errno;
        return false;
    }
    int dumpable = prctl(PR_GET_DUMPABLE, 0L, 0L, 0L, 0L);
    if (dumpable != 0) {
        *error_number = dumpable < 0 ? errno : EIO;
        return false;
    }
    *error_number = 0;
    return true;
}
#endif

#define NANOSECONDS_PER_SECOND UINT64_C(1000000000)
#define WARMUP_DURATION_NS NANOSECONDS_PER_SECOND
#define MAIN_DURATION_NS (UINT64_C(4) * NANOSECONDS_PER_SECOND)
#define SOFT_RUN_LIMIT_NS (UINT64_C(6) * NANOSECONDS_PER_SECOND)
#define SAMPLE_PERIOD_NS UINT64_C(20000000)
#define CHECK_CALL_PERIOD 64U
#define INPUT_COUNT 8U
#define CALL_CAPACITY 250000U
#define SNAPSHOT_CAPACITY 512U
#define CHECKPOINT_CAPACITY (CALL_CAPACITY / CHECK_CALL_PERIOD + 1U)
#define TARGET_CPU 2U
#define OBSERVATION_CPU 18U
#define MSR_DEVICE_MAJOR 202U
#define MSR_MPERF_OFFSET UINT32_C(0xe7)
#define MSR_APERF_OFFSET UINT32_C(0xe8)
#define PUBLIC_DIGEST_BYTES 32U

enum workload_phase {
    PHASE_WARMUP,
    PHASE_MAIN
};

enum stop_reason {
    STOP_NOT_STARTED,
    STOP_COMPLETED,
    STOP_ALLOCATION,
    STOP_REFERENCE_IDENTITY,
    STOP_AFFINITY,
    STOP_DEVICE,
    STOP_INPUT,
    STOP_CLOCK,
    STOP_COUNTER,
    STOP_DECAPSULATION,
    STOP_CALL_CAPACITY,
    STOP_SNAPSHOT_CAPACITY,
    STOP_CHECKPOINT_CAPACITY,
    STOP_SOFT_TIMEOUT
};

struct clock_reading {
    bool has_timespec;
    bool has_value;
    uint64_t value_ns;
    time_t seconds;
    long fractional_ns;
    int error_number;
};

struct counter_reading {
    struct clock_reading before;
    struct clock_reading after;
    uint64_t value_u64;
    ssize_t byte_count;
    int error_number;
    bool has_value;
};

struct call_record {
    struct clock_reading before;
    struct clock_reading after;
    unsigned int input_index;
    enum workload_phase phase;
    int operation_status;
    bool operation_performed;
};

struct checkpoint_record {
    struct clock_reading clock;
    size_t call_record_count;
    enum workload_phase phase;
};

struct snapshot_record {
    struct clock_reading raw_before;
    struct clock_reading raw_after;
    struct clock_reading thread_before;
    struct clock_reading thread_after;
    struct counter_reading counters[2][3];
    size_t call_record_count;
    enum workload_phase phase;
    const char *kind;
    uint64_t scheduled_deadline_ns;
    uint64_t missed_deadlines;
    bool has_deadline;
    bool is_valid;
};

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

static void classify_counter_reading(struct counter_reading *result,
    ssize_t byte_count,
    int saved_error_number,
    uint64_t value_u64)
{
    result->byte_count = byte_count;
    result->error_number = byte_count < 0 ? saved_error_number : 0;
    result->has_value = byte_count == (ssize_t)sizeof(value_u64);
    result->value_u64 = result->has_value ? value_u64 : 0;
}

static bool next_sample_deadline(uint64_t current_ns,
    uint64_t deadline_ns,
    uint64_t *next_deadline_ns,
    uint64_t *missed_deadlines)
{
    if (current_ns < deadline_ns) {
        return false;
    }
    uint64_t elapsed_periods = (current_ns - deadline_ns) / SAMPLE_PERIOD_NS;
    if (elapsed_periods == UINT64_MAX ||
        elapsed_periods + 1U > (UINT64_MAX - deadline_ns) / SAMPLE_PERIOD_NS) {
        return false;
    }
    *missed_deadlines = elapsed_periods;
    *next_deadline_ns = deadline_ns + (elapsed_periods + 1U) * SAMPLE_PERIOD_NS;
    return true;
}

static bool has_record_space(size_t count, size_t capacity)
{
    return count < capacity;
}

static bool device_identity_is_valid(bool is_character,
    uintmax_t owner_uid,
    unsigned int major_number,
    unsigned int minor_number,
    unsigned int cpu_index)
{
    return is_character && owner_uid == 0 && major_number == MSR_DEVICE_MAJOR &&
        minor_number == cpu_index;
}

static bool selfcheck(void)
{
    uint64_t value_ns = 0;
    if (!timespec_to_nanoseconds(1, 999999999L, &value_ns) || value_ns != UINT64_C(1999999999) ||
        timespec_to_nanoseconds(-1, 0, &value_ns) || timespec_to_nanoseconds(0, -1, &value_ns) ||
        timespec_to_nanoseconds(0, 1000000000L, &value_ns)) {
        return false;
    }
    time_t limit_seconds = (time_t)(UINT64_MAX / NANOSECONDS_PER_SECOND);
    long limit_fractional_ns = (long)(UINT64_MAX % NANOSECONDS_PER_SECOND);
    if (!timespec_to_nanoseconds(limit_seconds, limit_fractional_ns, &value_ns) ||
        value_ns != UINT64_MAX ||
        timespec_to_nanoseconds(limit_seconds, limit_fractional_ns + 1, &value_ns) ||
        timespec_to_nanoseconds(limit_seconds + 1, 0, &value_ns)) {
        return false;
    }
    struct counter_reading counter = {0};
    classify_counter_reading(&counter, 8, EIO, UINT64_MAX);
    if (!counter.has_value || counter.value_u64 != UINT64_MAX || counter.error_number != 0) {
        return false;
    }
    classify_counter_reading(&counter, 8, EIO, 0);
    if (!counter.has_value || counter.value_u64 != 0) {
        return false;
    }
    for (ssize_t byte_count = 0; byte_count < 8; ++byte_count) {
        classify_counter_reading(&counter, byte_count, EIO, UINT64_MAX);
        if (counter.has_value || counter.byte_count != byte_count || counter.error_number != 0) {
            return false;
        }
    }
    classify_counter_reading(&counter, -1, EBADF, UINT64_MAX);
    if (counter.has_value || counter.byte_count != -1 || counter.error_number != EBADF) {
        return false;
    }
    struct clock_reading before = {.has_value = true, .value_ns = 1};
    struct clock_reading after = {.has_value = true, .value_ns = 2};
    if (!clock_span_is_valid(&before, &after) || clock_span_is_valid(&after, &before)) {
        return false;
    }
    struct clock_reading previous = after;
    check_clock_order(&before, &previous);
    if (before.error_number != ERANGE || before.value_ns != 1 ||
        clock_span_is_valid(&before, &after)) {
        return false;
    }
    after.has_value = false;
    if (clock_span_is_valid(&before, &after) ||
        !has_record_space(CALL_CAPACITY - 1U, CALL_CAPACITY) ||
        has_record_space(CALL_CAPACITY, CALL_CAPACITY) ||
        !has_record_space(SNAPSHOT_CAPACITY - 1U, SNAPSHOT_CAPACITY) ||
        has_record_space(SNAPSHOT_CAPACITY, SNAPSHOT_CAPACITY)) {
        return false;
    }
    uint64_t next_deadline_ns = 0;
    uint64_t missed_deadlines = 0;
    if (!next_sample_deadline(3U * SAMPLE_PERIOD_NS,
            SAMPLE_PERIOD_NS,
            &next_deadline_ns,
            &missed_deadlines) ||
        next_deadline_ns != 4U * SAMPLE_PERIOD_NS || missed_deadlines != 2U ||
        next_sample_deadline(0, SAMPLE_PERIOD_NS, &next_deadline_ns, &missed_deadlines) ||
        next_sample_deadline(UINT64_MAX, UINT64_MAX, &next_deadline_ns, &missed_deadlines)) {
        return false;
    }
    return device_identity_is_valid(true, 0, 202, 2, 2) &&
        !device_identity_is_valid(false, 0, 202, 2, 2) &&
        !device_identity_is_valid(true, 1000, 202, 2, 2) &&
        !device_identity_is_valid(true, 0, 203, 2, 2) &&
        !device_identity_is_valid(true, 0, 202, 18, 2) &&
        strcmp(mlkem_implementation_name(), "reference") == 0;
}

#if HAS_FREQUENCY_WORKLOAD
struct device_record {
    int descriptor;
    int error_number;
    int close_error_number;
    unsigned int cpu_index;
    unsigned int major_number;
    unsigned int minor_number;
    uintmax_t owner_uid;
    bool has_metadata;
    bool is_valid;
    const char *status;
};

struct ordinary_input {
    uint8_t ciphertext[MLKEM_CIPHERTEXT_BYTES];
    uint8_t public_digest[PUBLIC_DIGEST_BYTES];
};

struct workload_state {
    struct call_record *calls;
    struct checkpoint_record *checkpoints;
    struct snapshot_record *snapshots;
    struct device_record devices[2];
    struct ordinary_input inputs[INPUT_COUNT];
    uint8_t decapsulation_key[MLKEM_DECAPSULATION_KEY_BYTES];
    size_t call_count;
    size_t checkpoint_count;
    size_t snapshot_count;
    unsigned int prepared_input_count;
    enum stop_reason stop_reason;
    enum workload_phase phase;
    int affinity_error_number;
    int input_operation_status;
    int allocation_error_numbers[3];
    bool affinity_verified;
    bool has_start;
    bool has_main_start;
    bool has_final_snapshot;
    uint64_t warmup_start_ns;
    uint64_t main_start_ns;
    uint64_t next_deadline_ns;
};

static volatile uint8_t secret_result_sink;
static struct clock_reading previous_raw_clock;
static struct clock_reading previous_thread_clock;

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

static struct clock_reading read_clock(clockid_t clock_id)
{
    struct clock_reading result = read_clock_timespec(clock_id);
    convert_clock_reading(&result);
    check_clock_order(&result,
        clock_id == CLOCK_MONOTONIC_RAW ? &previous_raw_clock : &previous_thread_clock);
    return result;
}

static struct counter_reading read_counter(int descriptor, uint32_t register_offset)
{
    struct counter_reading result = {0};
    uint64_t value_u64 = 0;
    result.before = read_clock(CLOCK_MONOTONIC_RAW);
    ssize_t byte_count = pread(descriptor, &value_u64, sizeof(value_u64), (off_t)register_offset);
    int saved_error_number = byte_count < 0 ? errno : 0;
    result.after = read_clock(CLOCK_MONOTONIC_RAW);
    classify_counter_reading(&result, byte_count, saved_error_number, value_u64);
    return result;
}

static void open_device(struct device_record *device, unsigned int cpu_index)
{
    char device_path[64];
    device->cpu_index = cpu_index;
    device->descriptor = -1;
    device->status = "path_error";
    int path_length = snprintf(device_path, sizeof(device_path), "/dev/cpu/%u/msr", cpu_index);
    if (path_length < 0 || (size_t)path_length >= sizeof(device_path)) {
        return;
    }
    device->descriptor = open(device_path, O_RDONLY | O_CLOEXEC | O_NOFOLLOW);
    if (device->descriptor < 0) {
        device->status = "open_error";
        device->error_number = errno;
        return;
    }
    struct stat metadata = {0};
    if (fstat(device->descriptor, &metadata) != 0) {
        device->status = "fstat_error";
        device->error_number = errno;
        return;
    }
    device->has_metadata = true;
    device->owner_uid = (uintmax_t)metadata.st_uid;
    device->major_number = major(metadata.st_rdev);
    device->minor_number = minor(metadata.st_rdev);
    device->is_valid = device_identity_is_valid(S_ISCHR(metadata.st_mode),
        device->owner_uid,
        device->major_number,
        device->minor_number,
        cpu_index);
    device->status = device->is_valid ? "ok" : "device_rejected";
}

static bool set_workload_affinity(struct workload_state *state)
{
    cpu_set_t requested;
    CPU_ZERO(&requested);
    CPU_SET(TARGET_CPU, &requested);
    if (sched_setaffinity(0, sizeof(requested), &requested) != 0) {
        state->affinity_error_number = errno;
        return false;
    }
    cpu_set_t observed;
    CPU_ZERO(&observed);
    if (sched_getaffinity(0, sizeof(observed), &observed) != 0) {
        state->affinity_error_number = errno;
        return false;
    }
    state->affinity_verified = CPU_COUNT(&observed) == 1 && CPU_ISSET(TARGET_CPU, &observed);
    return state->affinity_verified;
}

static bool prepare_inputs(struct workload_state *state)
{
    uint8_t encapsulation_key[MLKEM_ENCAPSULATION_KEY_BYTES];
    uint8_t expected_secret[MLKEM_SHARED_SECRET_BYTES];
    uint8_t observed_secret[MLKEM_SHARED_SECRET_BYTES];
    state->input_operation_status = mlkem_generate_key_pair(encapsulation_key,
        sizeof(encapsulation_key),
        state->decapsulation_key,
        sizeof(state->decapsulation_key));
    for (unsigned int input_index = 0;
        input_index < INPUT_COUNT && state->input_operation_status == 0;
        ++input_index) {
        state->input_operation_status = mlkem_encapsulate(state->inputs[input_index].ciphertext,
            sizeof(state->inputs[input_index].ciphertext),
            expected_secret,
            sizeof(expected_secret),
            encapsulation_key,
            sizeof(encapsulation_key));
        if (state->input_operation_status == 0) {
            state->input_operation_status = mlkem_decapsulate(observed_secret,
                sizeof(observed_secret),
                state->inputs[input_index].ciphertext,
                sizeof(state->inputs[input_index].ciphertext),
                state->decapsulation_key,
                sizeof(state->decapsulation_key));
        }
        if (state->input_operation_status == 0 &&
            memcmp(expected_secret, observed_secret, sizeof(expected_secret)) != 0) {
            state->input_operation_status = -1;
        }
        if (state->input_operation_status == 0) {
            mlk_sha3_256(state->inputs[input_index].public_digest,
                state->inputs[input_index].ciphertext,
                sizeof(state->inputs[input_index].ciphertext));
            ++state->prepared_input_count;
        }
    }
    erase_secret_bytes(expected_secret, sizeof(expected_secret));
    erase_secret_bytes(observed_secret, sizeof(observed_secret));
    return state->input_operation_status == 0 && state->prepared_input_count == INPUT_COUNT;
}

static bool capture_snapshot(struct workload_state *state,
    const char *kind,
    bool has_deadline,
    uint64_t deadline_ns,
    uint64_t missed_deadlines)
{
    if (!has_record_space(state->snapshot_count, SNAPSHOT_CAPACITY)) {
        state->stop_reason = STOP_SNAPSHOT_CAPACITY;
        return false;
    }
    struct snapshot_record *snapshot = &state->snapshots[state->snapshot_count++];
    snapshot->kind = kind;
    snapshot->call_record_count = state->call_count;
    snapshot->phase = state->phase;
    snapshot->has_deadline = has_deadline;
    snapshot->scheduled_deadline_ns = deadline_ns;
    snapshot->missed_deadlines = missed_deadlines;
    snapshot->raw_before = read_clock(CLOCK_MONOTONIC_RAW);
    snapshot->thread_before = read_clock(CLOCK_THREAD_CPUTIME_ID);
    bool counters_valid = true;
    bool clocks_valid = true;
    for (unsigned int device_index = 0; device_index < 2U; ++device_index) {
        for (unsigned int read_index = 0; read_index < 3U; ++read_index) {
            uint32_t register_offset = read_index == 1U ? MSR_APERF_OFFSET : MSR_MPERF_OFFSET;
            struct counter_reading *counter = &snapshot->counters[device_index][read_index];
            *counter = read_counter(state->devices[device_index].descriptor, register_offset);
            counters_valid = counter->has_value && counters_valid;
            clocks_valid = clock_span_is_valid(&counter->before, &counter->after) && clocks_valid;
        }
    }
    snapshot->thread_after = read_clock(CLOCK_THREAD_CPUTIME_ID);
    snapshot->raw_after = read_clock(CLOCK_MONOTONIC_RAW);
    clocks_valid = clock_span_is_valid(&snapshot->raw_before, &snapshot->raw_after) &&
        clock_span_is_valid(&snapshot->thread_before, &snapshot->thread_after) && clocks_valid;
    snapshot->is_valid = counters_valid && clocks_valid;
    if (!snapshot->is_valid) {
        state->stop_reason = clocks_valid ? STOP_COUNTER : STOP_CLOCK;
    }
    return snapshot->is_valid;
}

static void capture_final_snapshot(struct workload_state *state)
{
    enum stop_reason original_reason = state->stop_reason;
    state->has_final_snapshot = capture_snapshot(state, "end", false, 0, 0);
    if (original_reason != STOP_COMPLETED && original_reason != STOP_NOT_STARTED) {
        state->stop_reason = original_reason;
    }
}

static bool record_call(struct workload_state *state)
{
    if (!has_record_space(state->call_count, CALL_CAPACITY)) {
        state->stop_reason = STOP_CALL_CAPACITY;
        return false;
    }
    struct call_record *record = &state->calls[state->call_count];
    record->input_index = (unsigned int)(state->call_count % INPUT_COUNT);
    record->phase = state->phase;
    uint8_t shared_secret[MLKEM_SHARED_SECRET_BYTES];
    ++state->call_count;
    record->before = read_clock_timespec(CLOCK_MONOTONIC_RAW);
    if (!record->before.has_timespec) {
        state->stop_reason = STOP_CLOCK;
        return false;
    }
    atomic_signal_fence(memory_order_seq_cst);
    int operation_status = mlkem_decapsulate(shared_secret,
        sizeof(shared_secret),
        state->inputs[record->input_index].ciphertext,
        sizeof(state->inputs[record->input_index].ciphertext),
        state->decapsulation_key,
        sizeof(state->decapsulation_key));
    atomic_signal_fence(memory_order_seq_cst);
    record->after = read_clock_timespec(CLOCK_MONOTONIC_RAW);
    convert_clock_reading(&record->before);
    convert_clock_reading(&record->after);
    check_clock_order(&record->before, &previous_raw_clock);
    check_clock_order(&record->after, &previous_raw_clock);
    record->operation_performed = true;
    record->operation_status = operation_status;
    if (record->operation_status == 0) {
        secret_result_sink ^= shared_secret[0];
    }
    erase_secret_bytes(shared_secret, sizeof(shared_secret));
    if (!clock_span_is_valid(&record->before, &record->after)) {
        state->stop_reason = STOP_CLOCK;
        return false;
    }
    if (record->operation_status != 0) {
        state->stop_reason = STOP_DECAPSULATION;
        return false;
    }
    return true;
}

static bool record_checkpoint(struct workload_state *state, struct clock_reading *clock)
{
    if (!has_record_space(state->checkpoint_count, CHECKPOINT_CAPACITY)) {
        state->stop_reason = STOP_CHECKPOINT_CAPACITY;
        return false;
    }
    struct checkpoint_record *checkpoint = &state->checkpoints[state->checkpoint_count++];
    checkpoint->call_record_count = state->call_count;
    checkpoint->phase = state->phase;
    checkpoint->clock = read_clock(CLOCK_MONOTONIC_RAW);
    *clock = checkpoint->clock;
    if (!clock->has_value || clock->error_number != 0 || clock->value_ns < state->warmup_start_ns) {
        state->stop_reason = STOP_CLOCK;
        return false;
    }
    return true;
}

static void collect_workload(struct workload_state *state)
{
    state->phase = PHASE_WARMUP;
    if (!capture_snapshot(state, "start", false, 0, 0)) {
        return;
    }
    state->has_start = true;
    state->warmup_start_ns = state->snapshots[0].raw_after.value_ns;
    if (state->warmup_start_ns > UINT64_MAX - SOFT_RUN_LIMIT_NS) {
        state->stop_reason = STOP_CLOCK;
        capture_final_snapshot(state);
        return;
    }
    state->next_deadline_ns = state->warmup_start_ns + SAMPLE_PERIOD_NS;
    for (;;) {
        if (!record_call(state)) {
            capture_final_snapshot(state);
            return;
        }
        if (state->call_count % CHECK_CALL_PERIOD != 0U) {
            continue;
        }
        struct clock_reading checkpoint_clock;
        if (!record_checkpoint(state, &checkpoint_clock)) {
            capture_final_snapshot(state);
            return;
        }
        if (checkpoint_clock.value_ns - state->warmup_start_ns >= SOFT_RUN_LIMIT_NS) {
            state->stop_reason = STOP_SOFT_TIMEOUT;
            capture_final_snapshot(state);
            return;
        }
        uint64_t phase_start_ns =
            state->phase == PHASE_WARMUP ? state->warmup_start_ns : state->main_start_ns;
        uint64_t phase_duration_ns =
            state->phase == PHASE_WARMUP ? WARMUP_DURATION_NS : MAIN_DURATION_NS;
        if (checkpoint_clock.value_ns < phase_start_ns) {
            state->stop_reason = STOP_CLOCK;
            capture_final_snapshot(state);
            return;
        }
        if (checkpoint_clock.value_ns - phase_start_ns >= phase_duration_ns) {
            if (state->phase == PHASE_MAIN) {
                state->stop_reason = STOP_COMPLETED;
                capture_final_snapshot(state);
                return;
            }
            if (state->snapshot_count >= SNAPSHOT_CAPACITY - 1U) {
                state->stop_reason = STOP_SNAPSHOT_CAPACITY;
                capture_final_snapshot(state);
                return;
            }
            if (!capture_snapshot(state, "warmup_to_main", false, 0, 0)) {
                return;
            }
            state->main_start_ns = state->snapshots[state->snapshot_count - 1U].raw_after.value_ns;
            state->has_main_start = true;
            state->phase = PHASE_MAIN;
            if (state->main_start_ns > UINT64_MAX - MAIN_DURATION_NS) {
                state->stop_reason = STOP_CLOCK;
                capture_final_snapshot(state);
                return;
            }
            state->next_deadline_ns = state->main_start_ns + SAMPLE_PERIOD_NS;
        } else if (checkpoint_clock.value_ns >= state->next_deadline_ns) {
            if (state->snapshot_count >= SNAPSHOT_CAPACITY - 1U) {
                state->stop_reason = STOP_SNAPSHOT_CAPACITY;
                capture_final_snapshot(state);
                return;
            }
            uint64_t next_deadline_ns = 0;
            uint64_t missed_deadlines = 0;
            if (!next_sample_deadline(checkpoint_clock.value_ns,
                    state->next_deadline_ns,
                    &next_deadline_ns,
                    &missed_deadlines)) {
                state->stop_reason = STOP_CLOCK;
                capture_final_snapshot(state);
                return;
            }
            if (!capture_snapshot(state,
                    "periodic",
                    true,
                    state->next_deadline_ns,
                    missed_deadlines)) {
                return;
            }
            state->next_deadline_ns = next_deadline_ns;
        }
    }
}

static void print_optional_u64(bool has_value, uint64_t value_u64)
{
    if (has_value) {
        printf("\"%" PRIu64 "\"", value_u64);
    } else {
        printf("null");
    }
}

static void print_optional_error(int error_number)
{
    if (error_number == 0) {
        printf("null");
    } else {
        printf("%d", error_number);
    }
}

static void print_clock(const struct clock_reading *clock)
{
    printf("{\"ns\":");
    print_optional_u64(clock->has_value, clock->value_ns);
    printf(",\"errno\":");
    print_optional_error(clock->error_number);
    if (clock->has_timespec && !clock->has_value) {
        printf(",\"raw_seconds\":\"%jd\",\"raw_fractional_ns\":%ld",
            (intmax_t)clock->seconds,
            clock->fractional_ns);
    }
    printf("}");
}

static const char *phase_name(enum workload_phase phase)
{
    return phase == PHASE_MAIN ? "main" : "warmup";
}

static const char *stop_reason_name(enum stop_reason reason)
{
    static const char *const names[] = {"not_started",
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
    return names[reason];
}

static void print_device(const struct device_record *device)
{
    printf("{\"type\":\"device\",\"cpu_index\":%u,\"status\":\"%s\",\"errno\":",
        device->cpu_index,
        device->status);
    print_optional_error(device->error_number);
    printf(",\"close_errno\":");
    print_optional_error(device->close_error_number);
    if (device->has_metadata) {
        printf(",\"owner_uid\":\"%ju\",\"major\":%u,\"minor\":%u",
            device->owner_uid,
            device->major_number,
            device->minor_number);
    }
    printf("}\n");
}

static void print_snapshot(const struct snapshot_record *snapshot, size_t snapshot_index)
{
    printf("{\"type\":\"snapshot\",\"index\":%zu,\"kind\":\"%s\",\"phase\":\"%s\","
           "\"call_records\":%zu,\"valid_reads_and_clocks\":%s,\"scheduled_deadline_ns\":",
        snapshot_index,
        snapshot->kind,
        phase_name(snapshot->phase),
        snapshot->call_record_count,
        snapshot->is_valid ? "true" : "false");
    print_optional_u64(snapshot->has_deadline, snapshot->scheduled_deadline_ns);
    printf(",\"missed_deadlines\":\"%" PRIu64 "\",\"raw_before\":", snapshot->missed_deadlines);
    print_clock(&snapshot->raw_before);
    printf(",\"thread_cpu_before\":");
    print_clock(&snapshot->thread_before);
    printf(",\"thread_cpu_after\":");
    print_clock(&snapshot->thread_after);
    printf(",\"raw_after\":");
    print_clock(&snapshot->raw_after);
    printf(",\"cpu_reads\":[");
    for (unsigned int device_index = 0; device_index < 2U; ++device_index) {
        if (device_index != 0U) {
            printf(",");
        }
        printf("{\"cpu_index\":%u,\"reads\":[", device_index == 0U ? TARGET_CPU : OBSERVATION_CPU);
        for (unsigned int read_index = 0; read_index < 3U; ++read_index) {
            const struct counter_reading *counter = &snapshot->counters[device_index][read_index];
            if (read_index != 0U) {
                printf(",");
            }
            printf("{\"register\":\"%s\",\"bytes_read\":%jd,\"errno\":",
                read_index == 1U ? "0xe8" : "0xe7",
                (intmax_t)counter->byte_count);
            print_optional_error(counter->error_number);
            printf(",\"value_u64\":");
            print_optional_u64(counter->has_value, counter->value_u64);
            printf(",\"before\":");
            print_clock(&counter->before);
            printf(",\"after\":");
            print_clock(&counter->after);
            printf("}");
        }
        printf("]}");
    }
    printf("]}\n");
}

static void print_records(const struct workload_state *state)
{
    printf("{\"type\":\"contract\",\"schema_version\":1,\"implementation\":\"reference\","
           "\"clock\":\"CLOCK_MONOTONIC_RAW\",\"thread_clock\":\"CLOCK_THREAD_CPUTIME_ID\","
           "\"workload_cpu\":2,\"observation_cpu\":18,\"input_count\":8,"
           "\"input_order\":\"index_modulo_8\",\"iid_claimed\":false,"
           "\"warmup_target_ns\":\"1000000000\",\"main_target_ns\":\"4000000000\","
           "\"soft_run_limit_ns\":\"6000000000\",\"sample_period_ns\":\"20000000\","
           "\"check_call_period\":64,\"call_capacity\":250000,\"snapshot_capacity\":512,"
           "\"frequency_converted\":false,\"configuration_writes\":0,"
           "\"r02_signed_off\":false}\n");
    for (unsigned int device_index = 0; device_index < 2U; ++device_index) {
        print_device(&state->devices[device_index]);
    }
    for (unsigned int input_index = 0; input_index < state->prepared_input_count; ++input_index) {
        printf("{\"type\":\"public_input\",\"input_index\":%u,\"ciphertext_sha3_256\":\"",
            input_index);
        for (unsigned int digest_index = 0; digest_index < PUBLIC_DIGEST_BYTES; ++digest_index) {
            printf("%02x", (unsigned int)state->inputs[input_index].public_digest[digest_index]);
        }
        printf("\"}\n");
    }
    for (size_t snapshot_index = 0; snapshot_index < state->snapshot_count; ++snapshot_index) {
        print_snapshot(&state->snapshots[snapshot_index], snapshot_index);
    }
    for (size_t checkpoint_index = 0; checkpoint_index < state->checkpoint_count;
        ++checkpoint_index) {
        const struct checkpoint_record *checkpoint = &state->checkpoints[checkpoint_index];
        printf(
            "{\"type\":\"checkpoint\",\"index\":%zu,\"phase\":\"%s\",\"call_records\":%zu,\"raw\":",
            checkpoint_index,
            phase_name(checkpoint->phase),
            checkpoint->call_record_count);
        print_clock(&checkpoint->clock);
        printf("}\n");
    }
    for (size_t call_index = 0; call_index < state->call_count; ++call_index) {
        const struct call_record *record = &state->calls[call_index];
        printf("{\"type\":\"decap\",\"index\":%zu,\"phase\":\"%s\",\"input_index\":%u,"
               "\"operation_performed\":%s,\"operation_status\":",
            call_index,
            phase_name(record->phase),
            record->input_index,
            record->operation_performed ? "true" : "false");
        if (record->operation_performed) {
            printf("%d", record->operation_status);
        } else {
            printf("null");
        }
        printf(",\"before\":");
        print_clock(&record->before);
        printf(",\"after\":");
        print_clock(&record->after);
        printf(",\"elapsed_ns\":");
        print_optional_u64(clock_span_is_valid(&record->before, &record->after),
            record->after.value_ns - record->before.value_ns);
        printf("}\n");
    }
    printf("{\"type\":\"summary\",\"status\":\"%s\",\"call_records\":%zu,"
           "\"snapshot_records\":%zu,\"checkpoint_records\":%zu,\"prepared_input_count\":%u,"
           "\"input_operation_status\":%d,\"affinity_verified\":%s,\"affinity_errno\":",
        stop_reason_name(state->stop_reason),
        state->call_count,
        state->snapshot_count,
        state->checkpoint_count,
        state->prepared_input_count,
        state->input_operation_status,
        state->affinity_verified ? "true" : "false");
    print_optional_error(state->affinity_error_number);
    printf(",\"allocation_errnos\":[");
    for (unsigned int allocation_index = 0; allocation_index < 3U; ++allocation_index) {
        if (allocation_index != 0U) {
            printf(",");
        }
        print_optional_error(state->allocation_error_numbers[allocation_index]);
    }
    printf("],\"warmup_start_ns\":");
    print_optional_u64(state->has_start, state->warmup_start_ns);
    printf(",\"main_start_ns\":");
    print_optional_u64(state->has_main_start, state->main_start_ns);
    printf(",\"valid_final_snapshot\":%s,\"r02_signed_off\":false}\n",
        state->has_final_snapshot ? "true" : "false");
}

static int run_workload(void)
{
    struct workload_state state = {0};
    state.devices[0].descriptor = -1;
    state.devices[0].cpu_index = TARGET_CPU;
    state.devices[0].status = "not_opened";
    state.devices[1].descriptor = -1;
    state.devices[1].cpu_index = OBSERVATION_CPU;
    state.devices[1].status = "not_opened";
    state.calls = calloc(CALL_CAPACITY, sizeof(*state.calls));
    state.allocation_error_numbers[0] = state.calls == NULL ? errno : 0;
    state.snapshots = calloc(SNAPSHOT_CAPACITY, sizeof(*state.snapshots));
    state.allocation_error_numbers[1] = state.snapshots == NULL ? errno : 0;
    state.checkpoints = calloc(CHECKPOINT_CAPACITY, sizeof(*state.checkpoints));
    state.allocation_error_numbers[2] = state.checkpoints == NULL ? errno : 0;
    if (state.calls == NULL || state.snapshots == NULL || state.checkpoints == NULL) {
        state.stop_reason = STOP_ALLOCATION;
    } else if (strcmp(mlkem_implementation_name(), "reference") != 0) {
        state.stop_reason = STOP_REFERENCE_IDENTITY;
    } else if (!set_workload_affinity(&state)) {
        state.stop_reason = STOP_AFFINITY;
    } else {
        open_device(&state.devices[0], TARGET_CPU);
        open_device(&state.devices[1], OBSERVATION_CPU);
        if (!state.devices[0].is_valid || !state.devices[1].is_valid) {
            state.stop_reason = STOP_DEVICE;
        } else if (!prepare_inputs(&state)) {
            state.stop_reason = STOP_INPUT;
        } else {
            collect_workload(&state);
        }
    }
    for (unsigned int device_index = 0; device_index < 2U; ++device_index) {
        struct device_record *device = &state.devices[device_index];
        if (device->descriptor >= 0 && close(device->descriptor) != 0) {
            device->close_error_number = errno;
            if (state.stop_reason == STOP_COMPLETED) {
                state.stop_reason = STOP_DEVICE;
            }
        }
    }
    erase_secret_bytes(state.decapsulation_key, sizeof(state.decapsulation_key));
    secret_result_sink = 0;
    print_records(&state);
    bool output_failed = fflush(stdout) != 0 || ferror(stdout);
    free(state.checkpoints);
    free(state.snapshots);
    free(state.calls);
    return !output_failed && state.stop_reason == STOP_COMPLETED && state.has_final_snapshot ? 0
                                                                                             : 1;
}
#endif

int main(int argument_count, char **arguments)
{
    if (argument_count == 2 && strcmp(arguments[1], "--selfcheck") == 0) {
        bool has_success = selfcheck();
        printf("{\"selfcheck\":\"%s\",\"hardware_read_performed\":false,"
               "\"crypto_workload_performed\":false}\n",
            has_success ? "passed" : "failed");
        if (fflush(stdout) != 0 || ferror(stdout)) {
            return 1;
        }
        return has_success ? 0 : 1;
    }
    bool process_safety_check =
        argument_count == 2 && strcmp(arguments[1], "--process-safety-check") == 0;
    if (argument_count != 1 && !process_safety_check) {
        fprintf(stderr, "usage: frequency_workload [--selfcheck|--process-safety-check]\n");
        return 2;
    }
#if HAS_FREQUENCY_WORKLOAD
    // exec会重置此状态，必须在生成秘密和分配采集记录前设置。
    int process_safety_error = 0;
    bool process_dumping_disabled = disable_process_dumping(&process_safety_error);
    if (process_safety_check || !process_dumping_disabled) {
        printf("{\"type\":\"%s\",\"process_dumping_disabled\":%s,\"errno\":%d,"
               "\"hardware_read_performed\":false,\"crypto_workload_performed\":false}\n",
            process_safety_check ? "process_safety_check" : "process_safety_failure",
            process_dumping_disabled ? "true" : "false",
            process_safety_error);
        if (fflush(stdout) != 0 || ferror(stdout)) {
            return 1;
        }
        return process_dumping_disabled ? 0 : 1;
    }
    return run_workload();
#else
    printf("{\"status\":\"unsupported_platform\",\"hardware_read_performed\":false,"
           "\"crypto_workload_performed\":false,\"r02_signed_off\":false}\n");
    if (fflush(stdout) != 0 || ferror(stdout)) {
        return 1;
    }
    return 2;
#endif
}
