/* BTB 观测者（T5.4 骨架）：循环执行固定间接跳转阵列并测批时延，骨架同 SMT 观测者。
 * 计时窗口只包含间接跳转阵列：窗口内无 I/O、无日志、无 malloc；结果缓冲在窗口外写出。
 * 同步协议（--sync-file，可选）：wait_turn -> 执行一批间接跳转并读钟 -> signal_turn。
 * --self-check 不绑核、不需要受害者，进程内自模拟并校验 CSV 格式（判据最低）。 */

#define _POSIX_C_SOURCE 200809L
#define _GNU_SOURCE

#include "observer_common.h"
#include "sync_flag.h"

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#define BTB_DEFAULT_BATCH_COUNT 200u
#define BTB_DEFAULT_ITERATION_COUNT 4096u
#define BTB_MAXIMUM_BATCH_COUNT 100000u
#define BTB_MAXIMUM_ITERATION_COUNT 1000000u
#define BTB_SELF_CHECK_BATCH_COUNT 8u
#define BTB_SELF_CHECK_ITERATION_COUNT 64u
#define BTB_TARGET_COUNT 8u
#define BTB_CSV_HEADER "batch_index,victim_run_id,batch_elapsed_nanoseconds"
#define BTB_USAGE                                                                                  \
    "usage: btb_observer --cpu <n> --output <csv> --victim-run-id <id>\n"                          \
    "       [--batches 200] [--iterations 4096] [--sync-file <path>] [--self-check]\n"

struct btb_options {
    unsigned cpu_index;
    unsigned batch_count;
    unsigned iteration_count;
    const char *output_path;
    const char *victim_run_id;
    const char *sync_path;
    int self_check;
    int has_cpu;
};

static void print_usage(void)
{
    fputs(BTB_USAGE, stderr);
}

typedef unsigned (*btb_target_function)(unsigned);

static unsigned btb_target_0(unsigned value)
{
    return value + 1u;
}

static unsigned btb_target_1(unsigned value)
{
    return value ^ 0x9e3779b9u;
}

static unsigned btb_target_2(unsigned value)
{
    return value + 3u;
}

static unsigned btb_target_3(unsigned value)
{
    return value * 3u + 1u;
}

static unsigned btb_target_4(unsigned value)
{
    return value ^ 0x85ebca6bu;
}

static unsigned btb_target_5(unsigned value)
{
    return value + 5u;
}

static unsigned btb_target_6(unsigned value)
{
    return value ^ 0xc2b2ae35u;
}

static unsigned btb_target_7(unsigned value)
{
    return value + 7u;
}

static const btb_target_function btb_targets[BTB_TARGET_COUNT] = {
    btb_target_0,
    btb_target_1,
    btb_target_2,
    btb_target_3,
    btb_target_4,
    btb_target_5,
    btb_target_6,
    btb_target_7,
};

/* 间接调用阵列：每一轮通过函数指针跳转，本身不做秘密相关操作。 */
static unsigned btb_indirect_work(unsigned iteration_count)
{
    unsigned value = 0u;
    for (unsigned iteration_index = 0u; iteration_index < iteration_count; ++iteration_index) {
        value = btb_targets[value & (BTB_TARGET_COUNT - 1u)](value);
    }
    return value;
}

static int parse_options(int argument_count, char **argument_values, struct btb_options *options)
{
    options->cpu_index = 0u;
    options->batch_count = BTB_DEFAULT_BATCH_COUNT;
    options->iteration_count = BTB_DEFAULT_ITERATION_COUNT;
    options->output_path = NULL;
    options->victim_run_id = NULL;
    options->sync_path = NULL;
    options->self_check = 0;
    options->has_cpu = 0;
    for (int argument_index = 1; argument_index < argument_count; ++argument_index) {
        if (strcmp(argument_values[argument_index], "--self-check") == 0) {
            options->self_check = 1;
            continue;
        }
        const char *value = NULL;
        int taken =
            observer_take_value(argument_count, argument_values, &argument_index, "--cpu", &value);
        if (taken == 0) {
            unsigned long long parsed_value = 0u;
            if (observer_parse_unsigned(value, 0u, 4095u, &parsed_value) != 0) {
                return 2;
            }
            options->cpu_index = (unsigned)parsed_value;
            options->has_cpu = 1;
            continue;
        }
        taken = observer_take_value(argument_count,
            argument_values,
            &argument_index,
            "--batches",
            &value);
        if (taken == 0) {
            unsigned long long parsed_value = 0u;
            if (observer_parse_unsigned(value, 1u, BTB_MAXIMUM_BATCH_COUNT, &parsed_value) != 0) {
                return 2;
            }
            options->batch_count = (unsigned)parsed_value;
            continue;
        }
        taken = observer_take_value(argument_count,
            argument_values,
            &argument_index,
            "--iterations",
            &value);
        if (taken == 0) {
            unsigned long long parsed_value = 0u;
            if (observer_parse_unsigned(value, 1u, BTB_MAXIMUM_ITERATION_COUNT, &parsed_value) !=
                0) {
                return 2;
            }
            options->iteration_count = (unsigned)parsed_value;
            continue;
        }
        taken = observer_take_value(argument_count,
            argument_values,
            &argument_index,
            "--output",
            &value);
        if (taken == 0) {
            options->output_path = value;
            continue;
        }
        taken = observer_take_value(argument_count,
            argument_values,
            &argument_index,
            "--victim-run-id",
            &value);
        if (taken == 0) {
            options->victim_run_id = value;
            continue;
        }
        taken = observer_take_value(argument_count,
            argument_values,
            &argument_index,
            "--sync-file",
            &value);
        if (taken == 0) {
            options->sync_path = value;
            continue;
        }
        return 2;
    }
    if (options->self_check) {
        return 0;
    }
    if (options->has_cpu == 0 || options->output_path == NULL || options->victim_run_id == NULL) {
        return 2;
    }
    return 0;
}

static int write_batch_csv(const struct btb_options *options, const unsigned *batch_elapsed)
{
    size_t text_capacity = 128u * ((size_t)options->batch_count + 1u) + 64u;
    char *csv_text = malloc(text_capacity);
    if (csv_text == NULL) {
        fprintf(stderr, "error: cannot allocate CSV buffer\n");
        return 1;
    }
    size_t used_bytes = 0u;
    int status = observer_append_text(csv_text, text_capacity, &used_bytes, "%s\n", BTB_CSV_HEADER);
    for (unsigned batch_index = 0u; status == 0 && batch_index < options->batch_count;
        ++batch_index) {
        status = observer_append_text(csv_text,
            text_capacity,
            &used_bytes,
            "%u,%s,%u\n",
            batch_index,
            options->victim_run_id,
            batch_elapsed[batch_index]);
    }
    if (status == 0) {
        status = observer_write_text(options->output_path, csv_text);
    }
    free(csv_text);
    return status;
}

static int run_self_check(void)
{
    struct btb_options invalid_options;
    char *missing_arguments[] = {"platform_observer_btb"};
    char *invalid_iteration_arguments[] = {"platform_observer_btb",
        "--iterations",
        "0",
        "--cpu",
        "0",
        "--output",
        "o",
        "--victim-run-id",
        "v"};
    if (parse_options(1, missing_arguments, &invalid_options) != 2 ||
        parse_options(7, invalid_iteration_arguments, &invalid_options) != 2) {
        fprintf(stderr, "error: self-check invalid-argument paths did not return 2\n");
        return 1;
    }
    struct btb_options self_check_options;
    memset(&self_check_options, 0, sizeof(self_check_options));
    self_check_options.batch_count = BTB_SELF_CHECK_BATCH_COUNT;
    self_check_options.iteration_count = BTB_SELF_CHECK_ITERATION_COUNT;
    unsigned *batch_elapsed = malloc((size_t)self_check_options.batch_count * sizeof(unsigned));
    if (batch_elapsed == NULL) {
        fprintf(stderr, "error: self-check allocation failed\n");
        return 1;
    }
    unsigned sink = 0u;
    for (unsigned batch_index = 0u; batch_index < self_check_options.batch_count; ++batch_index) {
        uint64_t start_nanoseconds = observer_now_nanoseconds();
        sink += btb_indirect_work(self_check_options.iteration_count);
        uint64_t end_nanoseconds = observer_now_nanoseconds();
        if (start_nanoseconds == 0u || end_nanoseconds <= start_nanoseconds) {
            fprintf(stderr, "error: self-check clock did not advance\n");
            free(batch_elapsed);
            return 1;
        }
        batch_elapsed[batch_index] = (unsigned)(end_nanoseconds - start_nanoseconds);
    }
    if (sink == 0xffffffffu) {
        fprintf(stderr, "error: self-check indirect work produced a degenerate result\n");
        free(batch_elapsed);
        return 1;
    }
    char output_path[OBSERVER_PATH_CAPACITY_BYTES];
    if (observer_self_check_output_path(output_path, sizeof(output_path), "btb") != 0) {
        free(batch_elapsed);
        return 1;
    }
    self_check_options.output_path = output_path;
    self_check_options.victim_run_id = "self-check";
    int status = write_batch_csv(&self_check_options, batch_elapsed);
    if (status == 0) {
        status = observer_validate_csv(output_path, BTB_CSV_HEADER, self_check_options.batch_count);
    }
    (void)remove(output_path);
    free(batch_elapsed);
    if (status != 0) {
        return 1;
    }
    printf("btb_observer self-check: batches=%u iterations=%u csv=ok\n",
        self_check_options.batch_count,
        self_check_options.iteration_count);
    return 0;
}

static int run_observer(const struct btb_options *options)
{
    if (observer_bind_cpu(options->cpu_index) != 0) {
        fprintf(stderr, "error: cannot bind observer to CPU %u\n", options->cpu_index);
        return 2;
    }
    struct sync_flag *sync_flag = NULL;
    if (options->sync_path != NULL) {
        sync_flag = sync_flag_open_named(options->sync_path);
        if (sync_flag == NULL) {
            return 2;
        }
    }
    unsigned *batch_elapsed = malloc((size_t)options->batch_count * sizeof(unsigned));
    if (batch_elapsed == NULL) {
        fprintf(stderr, "error: cannot allocate observer buffer\n");
        sync_flag_destroy(sync_flag);
        return 2;
    }
    unsigned sink = 0u;
    int status = 0;
    for (unsigned batch_index = 0u; batch_index < options->batch_count; ++batch_index) {
        if (sync_flag != NULL && sync_flag_wait_turn(sync_flag) != 0) {
            fprintf(stderr, "error: sync flag closed while waiting for victim turn\n");
            status = 1;
            break;
        }
        uint64_t start_nanoseconds = observer_now_nanoseconds();
        sink += btb_indirect_work(options->iteration_count);
        uint64_t end_nanoseconds = observer_now_nanoseconds();
        if (start_nanoseconds == 0u || end_nanoseconds <= start_nanoseconds) {
            fprintf(stderr, "error: clock did not advance in batch %u\n", batch_index);
            status = 1;
            break;
        }
        batch_elapsed[batch_index] = (unsigned)(end_nanoseconds - start_nanoseconds);
        if (sync_flag != NULL) {
            sync_flag_signal_turn(sync_flag);
        }
    }
    if (status == 0) {
        status = write_batch_csv(options, batch_elapsed);
    }
    if (status == 0) {
        printf("btb_observer: cpu=%u batches=%u iterations=%u sink=%u output=%s\n",
            options->cpu_index,
            options->batch_count,
            options->iteration_count,
            sink,
            options->output_path);
    }
    free(batch_elapsed);
    sync_flag_destroy(sync_flag);
    return status == 0 ? 0 : 1;
}

int main(int argument_count, char **argument_values)
{
    struct btb_options options;
    if (parse_options(argument_count, argument_values, &options) != 0) {
        print_usage();
        return 2;
    }
    if (options.self_check != 0) {
        return run_self_check();
    }
    return run_observer(&options);
}
