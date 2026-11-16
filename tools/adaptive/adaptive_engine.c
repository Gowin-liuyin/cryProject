/* 自适应引擎（T6.3）：M4 人工校准臂上的本地 L2 自攻击演示（不做真实臂恢复）。
 *
 * 冻结的算法常量（本文件头 #define，运行期不可改；冻结的是算法参数而非输入日程）：
 *   REPEATS_CAL = 1000    每个候选失配位置的校准样本数（位置交错采样，抵消慢漂移）
 *   REPEATS_TEST = 1000   每次恢复运行的判读样本数
 *   INNER_REPEATS = 1024  每个样本 = 连续 INNER_REPEATS 次完整比较的均值纳秒
 *   DEMO_RUNS = 20        独立恢复次数（位置由固定种子 LCG 生成）
 *   DECISION_RULE = 最近中位参考：校准位置中位数与恢复样本中位数差最小者。
 * 每个样本的计时窗口只包含 m4_compare_checked 的重复调用，无 I/O/日志/malloc；
 * 输入构造、分配、结果写出全部在窗口外。
 *
 * 用法：
 *   adaptive_engine --output <csv> --meta <txt> --run-id <id> [--cpu 0]
 *   adaptive_engine --sanity <position 0..31> [--cpu 0]
 * 退出码：0 成功；1 用法；2 数据。
 */

#define _POSIX_C_SOURCE 200809L
#define _GNU_SOURCE

#include "compare.h"

#include <sched.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>

#define REPEATS_CAL 1000u
#define REPEATS_TEST 1000u
#define INNER_REPEATS 1024u
#define DEMO_RUNS 20u
#define POSITION_COUNT 32u
#define DEMO_SEED UINT32_C(20261116)
#define DEMO_LCG_MULTIPLIER UINT32_C(1664525)
#define DEMO_LCG_INCREMENT UINT32_C(1013904223)
#define ADAPTIVE_EXIT_USAGE 1
#define ADAPTIVE_EXIT_DATA 2
#define ADAPTIVE_SANITY_SAMPLE_COUNT 100u
#define ADAPTIVE_PATH_CAPACITY_BYTES 4096u
#define ADAPTIVE_RUN_ID_CAPACITY_BYTES 64u

int craft_input_pair(unsigned position_bytes,
    uint8_t secret_input[M4_COMPARE_BYTES],
    uint8_t candidate_input[M4_COMPARE_BYTES]);
unsigned craft_first_difference(const uint8_t secret_input[M4_COMPARE_BYTES],
    const uint8_t candidate_input[M4_COMPARE_BYTES]);

struct adaptive_options {
    const char *output_path;
    const char *meta_path;
    const char *run_id;
    unsigned cpu_index;
    int sanity_position;
    int has_sanity;
};

static volatile int observed_equality;

static void print_usage(void)
{
    fputs("usage: adaptive_engine --output <csv> --meta <txt> --run-id <id> [--cpu 0]\n"
          "       adaptive_engine --sanity <0..31> [--cpu 0]\n",
        stderr);
}

static uint64_t now_nanoseconds(void)
{
    struct timespec timestamp;
    if (clock_gettime(CLOCK_MONOTONIC_RAW, &timestamp) != 0) {
        return 0u;
    }
    return (uint64_t)timestamp.tv_sec * UINT64_C(1000000000) + (uint64_t)timestamp.tv_nsec;
}

static int compare_double(const void *left_value, const void *right_value)
{
    double left = *(const double *)left_value;
    double right = *(const double *)right_value;
    return (left > right) - (left < right);
}

static double median_of(double *values, size_t value_count)
{
    qsort(values, value_count, sizeof(double), compare_double);
    if (value_count % 2u == 1u) {
        return values[value_count / 2u];
    }
    return (values[value_count / 2u - 1u] + values[value_count / 2u]) / 2.0;
}

static int has_valid_run_id(const char *run_id)
{
    size_t run_id_bytes = strlen(run_id);
    if (run_id_bytes == 0u || run_id_bytes >= ADAPTIVE_RUN_ID_CAPACITY_BYTES) {
        return 0;
    }
    for (size_t character_index = 0u; character_index < run_id_bytes; ++character_index) {
        char character = run_id[character_index];
        if (!((character >= 'a' && character <= 'z') || (character >= 'A' && character <= 'Z') ||
                (character >= '0' && character <= '9') || character == '-' || character == '_')) {
            return 0;
        }
    }
    return 1;
}

static int bind_cpu(unsigned cpu_index)
{
    if (cpu_index >= (unsigned)CPU_SETSIZE) {
        return -1;
    }
    cpu_set_t cpu_set;
    CPU_ZERO(&cpu_set);
#pragma GCC diagnostic push
#pragma GCC diagnostic ignored "-Wsign-conversion"
    CPU_SET((int)cpu_index, &cpu_set);
#pragma GCC diagnostic pop
    return sched_setaffinity(0, sizeof(cpu_set), &cpu_set);
}

/* 一个样本 = INNER_REPEATS 次完整 m4_compare_checked 的均值纳秒；窗口内无 I/O/分配。 */
static double measure_sample(const uint8_t secret_input[M4_COMPARE_BYTES],
    const uint8_t candidate_input[M4_COMPARE_BYTES])
{
    int comparison_equal = 0;
    uint64_t start_nanoseconds = now_nanoseconds();
    for (unsigned inner_index = 0u; inner_index < INNER_REPEATS; ++inner_index) {
        if (m4_compare_checked(secret_input,
                M4_COMPARE_BYTES,
                candidate_input,
                M4_COMPARE_BYTES,
                &comparison_equal) != 0) {
            return 0.0;
        }
    }
    uint64_t end_nanoseconds = now_nanoseconds();
    observed_equality = comparison_equal;
    if (end_nanoseconds <= start_nanoseconds) {
        return 0.0;
    }
    return (double)(end_nanoseconds - start_nanoseconds) / (double)INNER_REPEATS;
}

static const char *arm_name(void)
{
#if defined(ADAPTIVE_ARM_VULNERABLE)
    return "vulnerable-early-exit";
#else
    return "ct-or-accumulate";
#endif
}

static int take_argument_value(int argument_count,
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

static int parse_unsigned(const char *text, unsigned maximum, unsigned *value)
{
    if (text == NULL || text[0] == '\0') {
        return 1;
    }
    for (const char *cursor = text; *cursor != '\0'; ++cursor) {
        if (*cursor < '0' || *cursor > '9') {
            return 1;
        }
    }
    char *end = NULL;
    unsigned long parsed_value = strtoul(text, &end, 10);
    if (end == text || *end != '\0' || parsed_value > maximum) {
        return 1;
    }
    *value = (unsigned)parsed_value;
    return 0;
}

static int
parse_options(int argument_count, char **argument_values, struct adaptive_options *options)
{
    options->output_path = NULL;
    options->meta_path = NULL;
    options->run_id = NULL;
    options->cpu_index = 0u;
    options->sanity_position = 0;
    options->has_sanity = 0;
    for (int argument_index = 1; argument_index < argument_count; ++argument_index) {
        const char *value = NULL;
        int taken = take_argument_value(argument_count,
            argument_values,
            &argument_index,
            "--output",
            &value);
        if (taken == 0) {
            options->output_path = value;
            continue;
        }
        taken =
            take_argument_value(argument_count, argument_values, &argument_index, "--meta", &value);
        if (taken == 0) {
            options->meta_path = value;
            continue;
        }
        taken = take_argument_value(argument_count,
            argument_values,
            &argument_index,
            "--run-id",
            &value);
        if (taken == 0) {
            options->run_id = value;
            continue;
        }
        taken =
            take_argument_value(argument_count, argument_values, &argument_index, "--cpu", &value);
        if (taken == 0) {
            unsigned parsed_value = 0u;
            if (parse_unsigned(value, 4095u, &parsed_value) != 0) {
                return 2;
            }
            options->cpu_index = parsed_value;
            continue;
        }
        taken = take_argument_value(argument_count,
            argument_values,
            &argument_index,
            "--sanity",
            &value);
        if (taken == 0) {
            unsigned parsed_value = 0u;
            if (parse_unsigned(value, POSITION_COUNT - 1u, &parsed_value) != 0) {
                return 2;
            }
            options->sanity_position = (int)parsed_value;
            options->has_sanity = 1;
            continue;
        }
        return 2;
    }
    if (options->has_sanity != 0) {
        return 0;
    }
    if (options->output_path == NULL || options->meta_path == NULL || options->run_id == NULL ||
        !has_valid_run_id(options->run_id)) {
        return 2;
    }
    return 0;
}

static int run_sanity(const struct adaptive_options *options)
{
    if (bind_cpu(options->cpu_index) != 0) {
        fprintf(stderr, "error: cannot bind to CPU %u\n", options->cpu_index);
        return ADAPTIVE_EXIT_DATA;
    }
    uint8_t secret_input[M4_COMPARE_BYTES];
    uint8_t candidate_input[M4_COMPARE_BYTES];
    if (craft_input_pair((unsigned)options->sanity_position, secret_input, candidate_input) != 0) {
        return ADAPTIVE_EXIT_DATA;
    }
    double samples[ADAPTIVE_SANITY_SAMPLE_COUNT];
    for (unsigned warmup_index = 0u; warmup_index < 100u; ++warmup_index) {
        samples[0] = measure_sample(secret_input, candidate_input);
    }
    for (unsigned sample_index = 0u; sample_index < ADAPTIVE_SANITY_SAMPLE_COUNT; ++sample_index) {
        samples[sample_index] = measure_sample(secret_input, candidate_input);
    }
    double sanity_median = median_of(samples, ADAPTIVE_SANITY_SAMPLE_COUNT);
    printf("adaptive_engine sanity: arm=%s cpu=%u position=%d samples=%u inner_repeats=%u "
           "median_nanoseconds=%.3f first_difference=%u equality_sink=%d\n",
        arm_name(),
        options->cpu_index,
        options->sanity_position,
        (unsigned)ADAPTIVE_SANITY_SAMPLE_COUNT,
        (unsigned)INNER_REPEATS,
        sanity_median,
        craft_first_difference(secret_input, candidate_input),
        observed_equality);
    return 0;
}

static int write_demo_outputs(const struct adaptive_options *options,
    const double *calibration_medians,
    const unsigned *true_positions,
    const unsigned *predicted_positions,
    const double *recovery_medians,
    unsigned correct_count)
{
    FILE *csv_file = fopen(options->output_path, "w");
    if (csv_file == NULL) {
        fprintf(stderr, "error: cannot create %s\n", options->output_path);
        return ADAPTIVE_EXIT_DATA;
    }
    if (fputs("run_id,true_position,predicted_position,sample_median_ns\n", csv_file) < 0) {
        (void)fclose(csv_file);
        return ADAPTIVE_EXIT_DATA;
    }
    int status = 0;
    for (unsigned run_index = 0u; run_index < DEMO_RUNS; ++run_index) {
        if (fprintf(csv_file,
                "%s,%u,%u,%.3f\n",
                options->run_id,
                true_positions[run_index],
                predicted_positions[run_index],
                recovery_medians[run_index]) < 0) {
            status = ADAPTIVE_EXIT_DATA;
            break;
        }
    }
    if (fclose(csv_file) != 0) {
        status = ADAPTIVE_EXIT_DATA;
    }
    if (status != 0) {
        return status;
    }
    FILE *meta_file = fopen(options->meta_path, "w");
    if (meta_file == NULL) {
        fprintf(stderr, "error: cannot create %s\n", options->meta_path);
        return ADAPTIVE_EXIT_DATA;
    }
    if (fprintf(meta_file, "run_id=%s\n", options->run_id) < 0 ||
        fprintf(meta_file, "arm=%s\n", arm_name()) < 0 ||
        fprintf(meta_file, "repeats_cal=%u\n", (unsigned)REPEATS_CAL) < 0 ||
        fprintf(meta_file, "repeats_test=%u\n", (unsigned)REPEATS_TEST) < 0 ||
        fprintf(meta_file, "inner_repeats=%u\n", (unsigned)INNER_REPEATS) < 0 ||
        fprintf(meta_file, "demo_runs=%u\n", (unsigned)DEMO_RUNS) < 0 ||
        fprintf(meta_file, "position_count=%u\n", (unsigned)POSITION_COUNT) < 0 ||
        fprintf(meta_file, "demo_seed=%u\n", (unsigned)DEMO_SEED) < 0 ||
        fprintf(meta_file, "decision_rule=nearest_median_reference\n") < 0 ||
        fprintf(meta_file, "frozen_note=冻结的是算法参数而非输入日程\n") < 0 ||
        fprintf(meta_file, "environment=local_wsl_unlocked_frequency_l2_selfattack_demo\n") < 0 ||
        fprintf(meta_file, "correct_runs=%u\n", correct_count) < 0 ||
        fprintf(meta_file, "clock=CLOCK_MONOTONIC_RAW\n") < 0 ||
        fprintf(meta_file, "sample_unit=nanoseconds_per_compare\n") < 0) {
        status = ADAPTIVE_EXIT_DATA;
    }
    for (unsigned position_index = 0u; status == 0 && position_index < POSITION_COUNT;
        ++position_index) {
        if (fprintf(meta_file,
                "calibration_median_position_%02u_nanoseconds=%.6f\n",
                position_index,
                calibration_medians[position_index]) < 0) {
            status = ADAPTIVE_EXIT_DATA;
        }
    }
    if (fclose(meta_file) != 0) {
        status = ADAPTIVE_EXIT_DATA;
    }
    return status;
}

static int run_demo(const struct adaptive_options *options)
{
    if (bind_cpu(options->cpu_index) != 0) {
        fprintf(stderr, "error: cannot bind to CPU %u\n", options->cpu_index);
        return ADAPTIVE_EXIT_DATA;
    }
    static double calibration_samples[POSITION_COUNT][REPEATS_CAL];
    double calibration_medians[POSITION_COUNT];
    uint8_t secrets[POSITION_COUNT][M4_COMPARE_BYTES];
    uint8_t candidates[POSITION_COUNT][M4_COMPARE_BYTES];
    for (unsigned position_index = 0u; position_index < POSITION_COUNT; ++position_index) {
        if (craft_input_pair(position_index, secrets[position_index], candidates[position_index]) !=
            0) {
            fprintf(stderr, "error: cannot craft position %u\n", position_index);
            return ADAPTIVE_EXIT_DATA;
        }
        for (unsigned warmup_index = 0u; warmup_index < 100u; ++warmup_index) {
            calibration_samples[position_index][0] =
                measure_sample(secrets[position_index], candidates[position_index]);
        }
    }
    /* 位置交错采样：每轮对 32 个位置各取一个样本，抵消慢漂移。 */
    for (unsigned round_index = 0u; round_index < REPEATS_CAL; ++round_index) {
        for (unsigned position_index = 0u; position_index < POSITION_COUNT; ++position_index) {
            calibration_samples[position_index][round_index] =
                measure_sample(secrets[position_index], candidates[position_index]);
        }
    }
    for (unsigned position_index = 0u; position_index < POSITION_COUNT; ++position_index) {
        calibration_medians[position_index] =
            median_of(calibration_samples[position_index], REPEATS_CAL);
    }

    unsigned true_positions[DEMO_RUNS];
    unsigned predicted_positions[DEMO_RUNS];
    double recovery_medians[DEMO_RUNS];
    double recovery_samples[REPEATS_TEST];
    uint32_t lcg_state = DEMO_SEED;
    unsigned correct_count = 0u;
    for (unsigned run_index = 0u; run_index < DEMO_RUNS; ++run_index) {
        lcg_state = lcg_state * DEMO_LCG_MULTIPLIER + DEMO_LCG_INCREMENT;
        unsigned true_position = (unsigned)(lcg_state % POSITION_COUNT);
        true_positions[run_index] = true_position;
        uint8_t secret_input[M4_COMPARE_BYTES];
        uint8_t candidate_input[M4_COMPARE_BYTES];
        if (craft_input_pair(true_position, secret_input, candidate_input) != 0) {
            return ADAPTIVE_EXIT_DATA;
        }
        for (unsigned sample_index = 0u; sample_index < REPEATS_TEST; ++sample_index) {
            recovery_samples[sample_index] = measure_sample(secret_input, candidate_input);
        }
        double recovery_median = median_of(recovery_samples, REPEATS_TEST);
        recovery_medians[run_index] = recovery_median;
        unsigned predicted_position = 0u;
        double best_distance = -1.0;
        for (unsigned position_index = 0u; position_index < POSITION_COUNT; ++position_index) {
            double distance = recovery_median - calibration_medians[position_index];
            if (distance < 0.0) {
                distance = -distance;
            }
            if (best_distance < 0.0 || distance < best_distance) {
                best_distance = distance;
                predicted_position = position_index;
            }
        }
        predicted_positions[run_index] = predicted_position;
        if (predicted_position == true_position) {
            ++correct_count;
        }
    }
    int status = write_demo_outputs(options,
        calibration_medians,
        true_positions,
        predicted_positions,
        recovery_medians,
        correct_count);
    if (status == 0) {
        printf("adaptive_engine: arm=%s runs=%u correct=%u/%u cpu=%u output=%s\n",
            arm_name(),
            (unsigned)DEMO_RUNS,
            correct_count,
            (unsigned)DEMO_RUNS,
            options->cpu_index,
            options->output_path);
    }
    return status;
}

int main(int argument_count, char **argument_values)
{
    struct adaptive_options options;
    if (parse_options(argument_count, argument_values, &options) != 0) {
        print_usage();
        return ADAPTIVE_EXIT_USAGE;
    }
    if (options.has_sanity != 0) {
        return run_sanity(&options);
    }
    return run_demo(&options);
}
