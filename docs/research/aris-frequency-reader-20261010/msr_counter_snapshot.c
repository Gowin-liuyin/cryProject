#define _POSIX_C_SOURCE 200809L

#include <errno.h>
#include <fcntl.h>
#include <inttypes.h>
#include <stdbool.h>
#include <stdint.h>
#include <stdio.h>
#include <string.h>
#include <sys/stat.h>
#include <sys/types.h>
#include <time.h>
#include <unistd.h>

#if defined(__linux__) && defined(__x86_64__)
#include <sys/sysmacros.h>
#define HAS_MSR_READER 1
#else
#define HAS_MSR_READER 0
#endif

#define NANOSECONDS_PER_SECOND UINT64_C(1000000000)
#define MSR_MPERF_OFFSET UINT32_C(0xe7)
#define MSR_APERF_OFFSET UINT32_C(0xe8)
#define MSR_DEVICE_MAJOR 202U

struct clock_reading {
    bool has_value;
    uint64_t value_ns;
    int error_number;
};

struct counter_reading {
    bool has_value;
    uint64_t value_u64;
    ssize_t byte_count;
    int error_number;
    struct clock_reading before;
    struct clock_reading after;
};

static bool timespec_to_nanoseconds(const struct timespec *clock_value, uint64_t *value_ns)
{
    if (clock_value->tv_sec < 0 || clock_value->tv_nsec < 0 ||
        clock_value->tv_nsec >= (long)NANOSECONDS_PER_SECOND) {
        return false;
    }
    if ((uintmax_t)clock_value->tv_sec > UINT64_MAX / NANOSECONDS_PER_SECOND) {
        return false;
    }
    uint64_t seconds_ns = (uint64_t)clock_value->tv_sec * NANOSECONDS_PER_SECOND;
    uint64_t remaining_ns = (uint64_t)clock_value->tv_nsec;
    if (remaining_ns > UINT64_MAX - seconds_ns) {
        return false;
    }
    *value_ns = seconds_ns + remaining_ns;
    return true;
}

static struct clock_reading read_clock(void)
{
    struct clock_reading result = {0};
#if HAS_MSR_READER
    struct timespec clock_value;
    if (clock_gettime(CLOCK_MONOTONIC_RAW, &clock_value) != 0) {
        result.error_number = errno;
        return result;
    }
    if (!timespec_to_nanoseconds(&clock_value, &result.value_ns)) {
        result.error_number = EOVERFLOW;
        return result;
    }
    result.has_value = true;
#else
    result.error_number = ENOTSUP;
#endif
    return result;
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

static struct counter_reading read_counter(int device_descriptor, uint32_t register_offset)
{
    struct counter_reading result = {0};
    uint64_t value_u64 = 0;
    result.before = read_clock();
    ssize_t byte_count =
        pread(device_descriptor, &value_u64, sizeof(value_u64), (off_t)register_offset);
    int saved_error_number = byte_count < 0 ? errno : 0;
    result.after = read_clock();
    classify_counter_reading(&result, byte_count, saved_error_number, value_u64);
    return result;
}

#if HAS_MSR_READER
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
    if (error_number != 0) {
        printf("%d", error_number);
    } else {
        printf("null");
    }
}

static bool print_counter(int device_descriptor, const char *read_name, uint32_t register_offset)
{
    struct counter_reading result = read_counter(device_descriptor, register_offset);
    const char *read_status =
        result.has_value ? "ok" : (result.byte_count < 0 ? "read_error" : "short_read");
    printf("{\"read_name\":\"%s\",\"register_offset\":\"0x%02" PRIx32
           "\",\"read_status\":\"%s\",\"bytes_read\":%jd,\"read_errno\":",
        read_name,
        register_offset,
        read_status,
        (intmax_t)result.byte_count);
    print_optional_error(result.error_number);
    printf(",\"counter_value_u64\":");
    print_optional_u64(result.has_value, result.value_u64);
    printf(",\"clock_before_ns\":");
    print_optional_u64(result.before.has_value, result.before.value_ns);
    printf(",\"clock_before_errno\":");
    print_optional_error(result.before.error_number);
    printf(",\"clock_after_ns\":");
    print_optional_u64(result.after.has_value, result.after.value_ns);
    printf(",\"clock_after_errno\":");
    print_optional_error(result.after.error_number);
    printf("}");
    return result.has_value && result.before.has_value && result.after.has_value &&
        result.after.value_ns >= result.before.value_ns;
}

static bool print_cpu_snapshot(unsigned int cpu_index)
{
    char device_path[64];
    int path_length = snprintf(device_path, sizeof(device_path), "/dev/cpu/%u/msr", cpu_index);
    if (path_length < 0 || (size_t)path_length >= sizeof(device_path)) {
        return false;
    }
    int device_descriptor = open(device_path, O_RDONLY | O_CLOEXEC | O_NOFOLLOW);
    int device_error_number = device_descriptor < 0 ? errno : 0;
    const char *device_status = device_descriptor < 0 ? "open_error" : "ok";
    struct stat device_metadata = {0};
    bool device_is_valid = false;
    if (device_descriptor >= 0) {
        if (fstat(device_descriptor, &device_metadata) != 0) {
            device_error_number = errno;
            device_status = "fstat_error";
        } else if (!S_ISCHR(device_metadata.st_mode) || device_metadata.st_uid != 0 ||
            major(device_metadata.st_rdev) != MSR_DEVICE_MAJOR ||
            minor(device_metadata.st_rdev) != cpu_index) {
            device_status = "device_rejected";
        } else {
            device_is_valid = true;
        }
    }
    printf("{\"cpu_index\":%u,\"device_path\":\"%s\",\"device_status\":\"%s\","
           "\"device_errno\":",
        cpu_index,
        device_path,
        device_status);
    print_optional_error(device_error_number);
    printf(",\"reads\":[");
    bool has_success = device_is_valid;
    if (device_is_valid) {
        has_success =
            print_counter(device_descriptor, "mperf_before", MSR_MPERF_OFFSET) && has_success;
        printf(",");
        has_success = print_counter(device_descriptor, "aperf", MSR_APERF_OFFSET) && has_success;
        printf(",");
        has_success =
            print_counter(device_descriptor, "mperf_after", MSR_MPERF_OFFSET) && has_success;
    }
    printf("],\"close_errno\":");
    int close_error_number = 0;
    if (device_descriptor >= 0 && close(device_descriptor) != 0) {
        close_error_number = errno;
        has_success = false;
    }
    print_optional_error(close_error_number);
    printf("}");
    return has_success;
}
#endif

static bool selfcheck(void)
{
    struct counter_reading result = {0};
    classify_counter_reading(&result, 8, EIO, UINT64_MAX);
    if (!result.has_value || result.value_u64 != UINT64_MAX || result.error_number != 0) {
        return false;
    }
    classify_counter_reading(&result, 8, EIO, 0);
    if (!result.has_value || result.value_u64 != 0) {
        return false;
    }
    for (ssize_t byte_count = 0; byte_count < 8; ++byte_count) {
        classify_counter_reading(&result, byte_count, EIO, UINT64_MAX);
        if (result.has_value || result.byte_count != byte_count || result.error_number != 0) {
            return false;
        }
    }
    result = read_counter(-1, MSR_MPERF_OFFSET);
    if (result.has_value || result.byte_count != -1 || result.error_number != EBADF) {
        return false;
    }
    uint64_t value_ns = 0;
    struct timespec clock_value = {0, 0};
    if (!timespec_to_nanoseconds(&clock_value, &value_ns) || value_ns != 0) {
        return false;
    }
    clock_value.tv_sec = 1;
    clock_value.tv_nsec = 999999999L;
    if (!timespec_to_nanoseconds(&clock_value, &value_ns) || value_ns != UINT64_C(1999999999)) {
        return false;
    }
    clock_value.tv_sec = -1;
    if (timespec_to_nanoseconds(&clock_value, &value_ns)) {
        return false;
    }
    clock_value.tv_sec = 0;
    clock_value.tv_nsec = -1;
    if (timespec_to_nanoseconds(&clock_value, &value_ns)) {
        return false;
    }
    clock_value.tv_nsec = 1000000000L;
    if (timespec_to_nanoseconds(&clock_value, &value_ns)) {
        return false;
    }
    clock_value.tv_sec = (time_t)(UINT64_MAX / NANOSECONDS_PER_SECOND);
    clock_value.tv_nsec = (long)(UINT64_MAX % NANOSECONDS_PER_SECOND);
    if (!timespec_to_nanoseconds(&clock_value, &value_ns) || value_ns != UINT64_MAX) {
        return false;
    }
    ++clock_value.tv_nsec;
    if (timespec_to_nanoseconds(&clock_value, &value_ns)) {
        return false;
    }
    ++clock_value.tv_sec;
    clock_value.tv_nsec = 0;
    return !timespec_to_nanoseconds(&clock_value, &value_ns);
}

int main(int argument_count, char **arguments)
{
    if (argument_count == 2 && strcmp(arguments[1], "--selfcheck") == 0) {
        bool has_success = selfcheck();
        printf("{\"selfcheck\":\"%s\",\"hardware_read_performed\":false}\n",
            has_success ? "passed" : "failed");
        if (fflush(stdout) != 0 || ferror(stdout)) {
            return 1;
        }
        return has_success ? 0 : 1;
    }
    if (argument_count != 1) {
        fprintf(stderr, "usage: msr_counter_snapshot [--selfcheck]\n");
        return 2;
    }
#if HAS_MSR_READER
    printf("{\"schema_version\":1,\"platform\":\"linux_x86_64\","
           "\"clock\":\"CLOCK_MONOTONIC_RAW\",\"configuration_writes\":0,"
           "\"frequency_converted\":false,\"cpu_snapshots\":[");
    bool has_success = print_cpu_snapshot(2U);
    printf(",");
    has_success = print_cpu_snapshot(18U) && has_success;
    printf("],\"status\":\"%s\",\"r02_signed_off\":false}\n",
        has_success ? "readable_snapshot" : "failed_snapshot");
    if (fflush(stdout) != 0 || ferror(stdout)) {
        return 1;
    }
    return has_success ? 0 : 1;
#else
    printf("{\"status\":\"unsupported_platform\",\"hardware_read_performed\":false,"
           "\"r02_signed_off\":false}\n");
    if (fflush(stdout) != 0 || ferror(stdout)) {
        return 1;
    }
    return 2;
#endif
}
