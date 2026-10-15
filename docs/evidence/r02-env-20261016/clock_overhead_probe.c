/* T07 读钟开销实测：连续两次 clock_gettime 的空窗口耗时分布。
 *
 * 放在文档中的原样副本；远端实际编译源即在 Cry/r02-env-20261016-<12hex>/clock_overhead_probe.c。
 * 与 raw_clock_calibration.c 的空 pair 语义一致：只测「读钟 → 空窗口 → 读钟」。
 * 不用 rdtsc，不做亲和性写入（外层 taskset 决定），不写任何配置。
 */
#define _GNU_SOURCE
#define _POSIX_C_SOURCE 200809L

#include <errno.h>
#include <inttypes.h>
#include <sched.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>
#include <unistd.h>

#define SAMPLE_COUNT 100000U
#define NANOSECONDS_PER_SECOND UINT64_C(1000000000)

static int compare_u64(const void *left, const void *right)
{
    uint64_t left_value = *(const uint64_t *)left;
    uint64_t right_value = *(const uint64_t *)right;
    return (left_value > right_value) - (left_value < right_value);
}

static double percentile_of(const uint64_t *sorted_values, size_t count, double fraction)
{
    if (count == 0U) {
        return 0.0;
    }
    double position = fraction * (double)(count - 1U);
    size_t lower_index = (size_t)position;
    size_t upper_index = (lower_index + 1U < count) ? lower_index + 1U : lower_index;
    double weight = position - (double)lower_index;
    return (double)sorted_values[lower_index] * (1.0 - weight) +
        (double)sorted_values[upper_index] * weight;
}

static int probe_clock(const char *clock_name, clockid_t clock_id)
{
    struct timespec resolution = {0, 0};
    if (clock_getres(clock_id, &resolution) != 0) {
        fprintf(stderr, "clock_getres failed: %s\n", strerror(errno));
        return 1;
    }

    uint64_t *samples = calloc(SAMPLE_COUNT, sizeof(uint64_t));
    if (samples == NULL) {
        fprintf(stderr, "calloc failed\n");
        return 1;
    }

    uint64_t failure_count = 0;
    for (size_t sample_index = 0; sample_index < SAMPLE_COUNT; ++sample_index) {
        struct timespec before = {0, 0};
        struct timespec after = {0, 0};
        if (clock_gettime(clock_id, &before) != 0 || clock_gettime(clock_id, &after) != 0) {
            failure_count += 1U;
            samples[sample_index] = 0U;
            continue;
        }
        uint64_t elapsed_ns = (uint64_t)(after.tv_sec - before.tv_sec) * NANOSECONDS_PER_SECOND +
            (uint64_t)(after.tv_nsec - before.tv_nsec);
        samples[sample_index] = elapsed_ns;
    }

    uint64_t total_ns = 0U;
    for (size_t sample_index = 0; sample_index < SAMPLE_COUNT; ++sample_index) {
        total_ns += samples[sample_index];
    }
    qsort(samples, SAMPLE_COUNT, sizeof(uint64_t), compare_u64);

    printf("SERIES %s\n", clock_name);
    printf("  clock_getres_ns=%" PRId64 "\n",
        (int64_t)resolution.tv_sec * (int64_t)NANOSECONDS_PER_SECOND + (int64_t)resolution.tv_nsec);
    printf("  n=%u failures=%" PRIu64 "\n", SAMPLE_COUNT, failure_count);
    printf("  min_ns=%" PRIu64 "\n", samples[0]);
    printf("  max_ns=%" PRIu64 "\n", samples[SAMPLE_COUNT - 1U]);
    printf("  mean_ns=%.6f\n", (double)total_ns / (double)SAMPLE_COUNT);
    printf("  p50_ns=%.1f\n", percentile_of(samples, SAMPLE_COUNT, 0.50));
    printf("  p90_ns=%.1f\n", percentile_of(samples, SAMPLE_COUNT, 0.90));
    printf("  p99_ns=%.1f\n", percentile_of(samples, SAMPLE_COUNT, 0.99));
    printf("  p999_ns=%.1f\n", percentile_of(samples, SAMPLE_COUNT, 0.999));

    free(samples);
    return 0;
}

int main(void)
{
    cpu_set_t allowed = {0};
    int cpu_result = sched_getcpu();
    printf("observed_cpu=%d\n", cpu_result);
    if (sched_getaffinity(0, sizeof(allowed), &allowed) == 0) {
        printf("affinity_cpus=");
        for (int cpu_index = 0; cpu_index < CPU_SETSIZE; ++cpu_index) {
            if (CPU_ISSET(cpu_index, &allowed)) {
                printf("%d,", cpu_index);
            }
        }
        printf("\n");
    }
    printf("clocksource_hint=see /sys/devices/system/clocksource/clocksource0/current_clocksource\n");

    if (probe_clock("CLOCK_MONOTONIC", CLOCK_MONOTONIC) != 0) {
        return 1;
    }
    if (probe_clock("CLOCK_MONOTONIC_RAW", CLOCK_MONOTONIC_RAW) != 0) {
        return 1;
    }
    return 0;
}
