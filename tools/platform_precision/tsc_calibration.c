/*
 * 计时基准与频率自校准工具（TSC / rdtsc / CLOCK_MONOTONIC）。
 *
 * 目的：把「物理精度与逐调用恒频」这个此前只登记为「未认证」的问题，拆成
 * **可实测的几项**，实测并给出带参数的结论；同时明确哪些仍然不可主张。
 *
 * 测四项：
 *
 *  1. TSC 速率：连续 N 秒读 TSC 与 CLOCK_MONOTONIC，算出 TSC 每秒的计数，
 *     并与内核报告的瞬时频率、cpuinfo_max_freq 对照。
 *  2. TSC 与 CLOCK_MONOTONIC 的比值漂移：反复取**短区间**（默认 1 ms）的
 *     TSC 增量与 CLOCK_MONOTONIC 增量，算出每个短区间隐含的频率，给出
 *     分布。这是「逐调用（或逐短区间）频率是否恒定」的**工程观测**，
 *     不是物理证明。
 *  3. rdtsc 分辨率：连续两次 rdtsc 的最小间隔分布（自校准的下界）。
 *  4. 内核瞬时频率采样：测量期间读 scaling_cur_freq，记录分布。
 *
 * 口径：
 *   * 全部用 CLOCK_MONOTONIC 做墙钟，TSC 用 RDTSC（序列化由编译器插入）。
 *   * 不加 sleep、不做空转填充；区间长度用墙钟实测，不是固定拍数。
 *   * 原始逐区间值全部落盘，不删长尾。
 *   * 不写任何 cpufreq 节点；只读。
 */
#define _POSIX_C_SOURCE 200809L

#include <math.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>
#include <unistd.h>

#if defined(__x86_64__) || defined(__i386__)
#include <x86intrin.h>
#define PRECISION_HAS_TSC 1
#else
#define PRECISION_HAS_TSC 0
#endif

#define DEFAULT_SECONDS 60u
#define DEFAULT_SHORT_INTERVAL_NANOS 1000000u /* 1 ms */
#define DEFAULT_SAMPLE_COUNT 2000u
#define MAX_SAMPLE_COUNT 200000u

static int parse_unsigned_integer(const char *text, uint64_t *value)
{
    uint64_t parsed = 0;
    if (text == NULL || *text == '\0') {
        return 1;
    }
    for (const char *cursor = text; *cursor != '\0'; ++cursor) {
        if (*cursor < '0' || *cursor > '9') {
            return 1;
        }
        if (parsed > (UINT64_MAX - (uint64_t)(*cursor - '0')) / 10u) {
            return 1;
        }
        parsed = parsed * 10u + (uint64_t)(*cursor - '0');
    }
    *value = parsed;
    return 0;
}

static uint64_t read_monotonic_nanoseconds(void)
{
    struct timespec timestamp;
    if (clock_gettime(CLOCK_MONOTONIC, &timestamp) != 0) {
        return 0;
    }
    return (uint64_t)timestamp.tv_sec * UINT64_C(1000000000) + (uint64_t)timestamp.tv_nsec;
}

#if PRECISION_HAS_TSC
static uint64_t read_tsc(void)
{
    return (uint64_t)__rdtsc();
}
#else
static uint64_t read_tsc(void)
{
    return 0;
}
#endif

static uint64_t read_kernel_frequency_kilohertz(void)
{
    static const char *const paths[] = {
        "/sys/devices/system/cpu/cpu0/cpufreq/scaling_cur_freq",
        "/sys/devices/system/cpu/cpu0/cpufreq/cpuinfo_max_freq",
    };
    for (size_t index = 0; index < sizeof(paths) / sizeof(paths[0]); ++index) {
        FILE *handle = fopen(paths[index], "r");
        if (handle == NULL) {
            continue;
        }
        unsigned long long value = 0;
        int matched = fscanf(handle, "%llu", &value);
        fclose(handle);
        if (matched == 1) {
            return (uint64_t)value;
        }
    }
    return 0;
}

static int compare_u64(const void *left, const void *right)
{
    uint64_t first = *(const uint64_t *)left;
    uint64_t second = *(const uint64_t *)right;
    if (first < second) {
        return -1;
    }
    if (first > second) {
        return 1;
    }
    return 0;
}

static double mean_of(const uint64_t *values, size_t count)
{
    if (count == 0) {
        return 0.0;
    }
    /* 先算总和的量级，避免大数相加溢出。 */
    long double total = 0.0L;
    for (size_t index = 0; index < count; ++index) {
        total += (long double)values[index];
    }
    return (double)(total / (long double)count);
}

static double standard_deviation_of(const uint64_t *values, size_t count)
{
    if (count < 2) {
        return 0.0;
    }
    double mean = mean_of(values, count);
    long double total = 0.0L;
    for (size_t index = 0; index < count; ++index) {
        long double difference = (long double)values[index] - (long double)mean;
        total += difference * difference;
    }
    return (double)sqrt((double)(total / (long double)(count - 1)));
}

static uint64_t percentile_of(const uint64_t *sorted, size_t count, double fraction)
{
    if (count == 0) {
        return 0;
    }
    double position = fraction * (double)(count - 1) + 0.5;
    size_t index = (size_t)position;
    if (index >= count) {
        index = count - 1;
    }
    return sorted[index];
}

static void write_summary(FILE *output,
    const char *label,
    const uint64_t *values,
    size_t count,
    double *mean_out,
    double *deviation_out)
{
    uint64_t *sorted = malloc(count * sizeof(uint64_t));
    if (sorted == NULL) {
        fprintf(stderr, "out of memory\n");
        exit(1);
    }
    memcpy(sorted, values, count * sizeof(uint64_t));
    qsort(sorted, count, sizeof(uint64_t), compare_u64);
    double mean = mean_of(values, count);
    double deviation = standard_deviation_of(values, count);
    if (mean_out != NULL) {
        *mean_out = mean;
    }
    if (deviation_out != NULL) {
        *deviation_out = deviation;
    }
    fprintf(output, "%s,n=%zu,min=%llu,p10=%llu,p50=%llu,p90=%llu,p99=%llu,max=%llu,mean=%.4f,sd=%.4f\n",
        label, count,
        (unsigned long long)sorted[0],
        (unsigned long long)percentile_of(sorted, count, 0.10),
        (unsigned long long)percentile_of(sorted, count, 0.50),
        (unsigned long long)percentile_of(sorted, count, 0.90),
        (unsigned long long)percentile_of(sorted, count, 0.99),
        (unsigned long long)sorted[count - 1],
        mean, deviation);
    free(sorted);
}

int main(int argument_count, char **argument_values)
{
    uint64_t seconds = DEFAULT_SECONDS;
    uint64_t interval_nanoseconds = DEFAULT_SHORT_INTERVAL_NANOS;
    uint64_t sample_count = DEFAULT_SAMPLE_COUNT;
    const char *interval_path = NULL;
    const char *summary_path = NULL;

    if (argument_count != 6) {
        fputs("usage: tsc_calibration SECONDS SHORT_INTERVAL_NS SAMPLE_COUNT INTERVAL_CSV SUMMARY_TXT\n",
            stderr);
        return 1;
    }
    if (parse_unsigned_integer(argument_values[1], &seconds) != 0 || seconds == 0u ||
        parse_unsigned_integer(argument_values[2], &interval_nanoseconds) != 0 ||
        interval_nanoseconds == 0u ||
        parse_unsigned_integer(argument_values[3], &sample_count) != 0 ||
        sample_count == 0u || sample_count > MAX_SAMPLE_COUNT) {
        fputs("usage: tsc_calibration SECONDS SHORT_INTERVAL_NS SAMPLE_COUNT INTERVAL_CSV SUMMARY_TXT\n",
            stderr);
        return 1;
    }
    interval_path = argument_values[4];
    summary_path = argument_values[5];

    if (!PRECISION_HAS_TSC) {
        fputs("this tool requires x86 rdtsc\n", stderr);
        return 1;
    }

    FILE *interval_file = fopen(interval_path, "w");
    if (interval_file == NULL) {
        fprintf(stderr, "cannot open %s\n", interval_path);
        return 1;
    }
    FILE *summary_file = stdout;
    if (summary_path != NULL) {
        summary_file = fopen(summary_path, "w");
        if (summary_file == NULL) {
            fprintf(stderr, "cannot open %s\n", summary_path);
            fclose(interval_file);
            return 1;
        }
    }

    fprintf(interval_file, "index,tsc_delta,monotonic_delta_nanoseconds,kernel_frequency_kilohertz\n");

    /* —— 第 1 项：TSC 速率（与墙钟对照）—— */
    uint64_t wall_start = read_monotonic_nanoseconds();
    uint64_t tsc_start = read_tsc();
    /* 区间长度用墙钟控制，不做固定拍数空转。 */
    uint64_t wall_deadline = wall_start + seconds * UINT64_C(1000000000);
    uint64_t wall_now = wall_start;
    uint64_t tsc_end = tsc_start;
    while (wall_now < wall_deadline) {
        wall_now = read_monotonic_nanoseconds();
        tsc_end = read_tsc();
    }
    uint64_t wall_elapsed = wall_now - wall_start;
    uint64_t tsc_elapsed = tsc_end - tsc_start;
    double tsc_hertz = (wall_elapsed > 0u)
        ? ((double)tsc_elapsed * 1.0e9 / (double)wall_elapsed)
        : 0.0;
    double tsc_kilohertz = tsc_hertz / 1.0e3;
    uint64_t kernel_frequency = read_kernel_frequency_kilohertz();

    fprintf(summary_file, "tsc_rate_khz=%.3f\n", tsc_kilohertz);
    fprintf(summary_file, "tsc_rate_hz=%.0f\n", tsc_hertz);
    fprintf(summary_file, "wall_elapsed_nanoseconds=%llu\n", (unsigned long long)wall_elapsed);
    fprintf(summary_file, "tsc_elapsed_counts=%llu\n", (unsigned long long)tsc_elapsed);
    fprintf(summary_file, "kernel_scaling_cur_freq_khz=%llu\n",
        (unsigned long long)kernel_frequency);
    if (kernel_frequency > 0u) {
        fprintf(summary_file, "tsc_rate_over_kernel_ratio=%.6f\n",
            tsc_kilohertz / (double)kernel_frequency);
    }
    fprintf(summary_file, "has_tsc=1\n");

    /* —— 第 3 项：rdtsc 分辨率（连续两次读数的最小间隔）—— */
    size_t resolution_count = 4096;
    uint64_t *resolution_values = malloc(resolution_count * sizeof(uint64_t));
    if (resolution_values == NULL) {
        fputs("out of memory\n", stderr);
        fclose(interval_file);
        return 1;
    }
    for (size_t index = 0; index < resolution_count; ++index) {
        uint64_t first = read_tsc();
        uint64_t second = read_tsc();
        resolution_values[index] = second - first;
    }
    write_summary(summary_file, "rdtsc_resolution_counts", resolution_values, resolution_count,
        NULL, NULL);
    free(resolution_values);

    /* —— 第 2 项：短区间的隐含频率 —— */
    size_t total = (size_t)sample_count;
    uint64_t *implied_kilohertz = malloc(total * sizeof(uint64_t));
    uint64_t *kernel_readings = malloc(total * sizeof(uint64_t));
    if (implied_kilohertz == NULL || kernel_readings == NULL) {
        fputs("out of memory\n", stderr);
        fclose(interval_file);
        return 1;
    }
    size_t filled = 0;
    for (uint64_t index = 0; index < sample_count; ++index) {
        uint64_t tsc_before = read_tsc();
        uint64_t wall_before = read_monotonic_nanoseconds();
        uint64_t wall_after = wall_before;
        while (wall_after - wall_before < interval_nanoseconds) {
            wall_after = read_monotonic_nanoseconds();
        }
        uint64_t tsc_after = read_tsc();
        uint64_t wall_delta = wall_after - wall_before;
        uint64_t tsc_delta = tsc_after - tsc_before;
        uint64_t kernel_reading = read_kernel_frequency_kilohertz();
        implied_kilohertz[filled] = (wall_delta > 0u)
            ? (tsc_delta * UINT64_C(1000000) / wall_delta)
            : 0u;
        kernel_readings[filled] = kernel_reading;
        ++filled;
        fprintf(interval_file, "%llu,%llu,%llu,%llu\n",
            (unsigned long long)index,
            (unsigned long long)tsc_delta,
            (unsigned long long)wall_delta,
            (unsigned long long)kernel_reading);
    }
    double implied_mean = 0.0;
    double implied_deviation = 0.0;
    write_summary(summary_file, "short_interval_implied_frequency_khz", implied_kilohertz, filled,
        &implied_mean, &implied_deviation);
    uint64_t *implied_sorted = malloc(filled * sizeof(uint64_t));
    if (implied_sorted != NULL) {
        memcpy(implied_sorted, implied_kilohertz, filled * sizeof(uint64_t));
        qsort(implied_sorted, filled, sizeof(uint64_t), compare_u64);
        fprintf(summary_file, "short_interval_implied_frequency_span_khz=%llu\n",
            (unsigned long long)(implied_sorted[filled - 1] - implied_sorted[0]));
        fprintf(summary_file, "short_interval_implied_frequency_relative_span=%.6f\n",
            implied_mean > 0.0
                ? ((double)(implied_sorted[filled - 1] - implied_sorted[0]) / implied_mean)
                : 0.0);
        free(implied_sorted);
    }
    if (filled > 0 && implied_mean > 0.0) {
        fprintf(summary_file, "short_interval_implied_frequency_relative_sd=%.6f\n",
            implied_deviation / implied_mean);
    }

    /* —— 第 4 项：内核瞬时频率采样 —— */
    size_t kernel_count = 0;
    for (size_t index = 0; index < filled; ++index) {
        if (kernel_readings[index] > 0u) {
            ++kernel_count;
        }
    }
    if (kernel_count > 0) {
        uint64_t *kernel_values = malloc(kernel_count * sizeof(uint64_t));
        if (kernel_values != NULL) {
            size_t cursor = 0;
            for (size_t index = 0; index < filled; ++index) {
                if (kernel_readings[index] > 0u) {
                    kernel_values[cursor++] = kernel_readings[index];
                }
            }
            write_summary(summary_file, "kernel_scaling_cur_freq_khz", kernel_values, kernel_count,
                NULL, NULL);
            free(kernel_values);
        }
    }

    fprintf(summary_file, "interval_target_nanoseconds=%llu\n", (unsigned long long)interval_nanoseconds);
    fprintf(summary_file, "sample_count=%zu\n", filled);
    fprintf(summary_file, "interval_csv=%s\n", interval_path);
    fprintf(summary_file, "clock_source=CLOCK_MONOTONIC\n");
    fprintf(summary_file, "tsc_source=RDTSC\n");

    fclose(interval_file);
    if (summary_file != stdout) {
        fclose(summary_file);
    }
    free(implied_kilohertz);
    free(kernel_readings);
    return 0;
}
