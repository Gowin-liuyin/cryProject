/* SMT 争用观测者：在指定 CPU 上按批执行固定次数 uint64/uint32 除法并测批时延。
 * 计时窗口只包含除法批：窗口内无 I/O、无日志、无 malloc；结果缓冲在窗口外写出。
 * 同步协议（与 wrapper/受害者侧共享同一 sync_flag 文件）：
 *   观测者 wait_turn -> 执行一批除法并读钟 -> signal_turn，循环 --batch-count 次。
 * 自检模式 --self-check 不绑核、不需要受害者与同步文件，进程内自模拟并校验 CSV。 */

#define _POSIX_C_SOURCE 200809L
#define _GNU_SOURCE

#include "observer_common.h"
#include "sync_flag.h"

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#define SMT_DEFAULT_DIV_BATCH 4096u
#define SMT_DEFAULT_BATCH_COUNT 200u
#define SMT_MAXIMUM_DIV_BATCH 1000000u
#define SMT_MAXIMUM_BATCH_COUNT 100000u
#define SMT_SELF_CHECK_DIV_BATCH 64u
#define SMT_SELF_CHECK_BATCH_COUNT 8u
#define SMT_CSV_HEADER "batch_index,victim_run_id,batch_elapsed_nanoseconds"
#define SMT_USAGE                                                                                  \
    "usage: smt_contention_observer --cpu <n> --output <csv> --victim-run-id <id>\n"               \
    "       [--div-batch 4096] [--batches 200] [--sync-file <path>] [--self-check]\n"

struct smt_options {
    unsigned cpu_index;
    unsigned div_batch;
    unsigned batch_count;
    const char *output_path;
    const char *victim_run_id;
    const char *sync_path;
    int self_check;
    int has_cpu;
};

static void print_usage(void)
{
    fputs(SMT_USAGE, stderr);
}

static unsigned smt_div_work(const uint64_t *dividends, const uint32_t *divisors, unsigned count)
{
    uint64_t accumulator = 0u;
    for (unsigned item_index = 0u; item_index < count; ++item_index) {
        accumulator += dividends[item_index] / (uint64_t)divisors[item_index];
    }
    return (unsigned)(accumulator & 0xffffffffu);
}

static void fill_division_operands(uint64_t *dividends, uint32_t *divisors, unsigned count)
{
    for (unsigned item_index = 0u; item_index < count; ++item_index) {
        dividends[item_index] = UINT64_C(0x100000000) + (uint64_t)item_index * UINT64_C(2654435761);
        divisors[item_index] = (uint32_t)(3u + (item_index * 40503u) % 65521u);
    }
}

static int parse_options(int argument_count, char **argument_values, struct smt_options *options)
{
    options->div_batch = SMT_DEFAULT_DIV_BATCH;
    options->batch_count = SMT_DEFAULT_BATCH_COUNT;
    options->output_path = NULL;
    options->victim_run_id = NULL;
    options->sync_path = NULL;
    options->cpu_index = 0u;
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
            "--div-batch",
            &value);
        if (taken == 0) {
            unsigned long long parsed_value = 0u;
            if (observer_parse_unsigned(value, 1u, SMT_MAXIMUM_DIV_BATCH, &parsed_value) != 0) {
                return 2;
            }
            options->div_batch = (unsigned)parsed_value;
            continue;
        }
        taken = observer_take_value(argument_count,
            argument_values,
            &argument_index,
            "--batches",
            &value);
        if (taken == 0) {
            unsigned long long parsed_value = 0u;
            if (observer_parse_unsigned(value, 1u, SMT_MAXIMUM_BATCH_COUNT, &parsed_value) != 0) {
                return 2;
            }
            options->batch_count = (unsigned)parsed_value;
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

static int run_self_check(void)
{
    struct smt_options invalid_options;
    char *missing_arguments[] = {"platform_observer_smt_contention"};
    char *invalid_cpu_arguments[] = {"platform_observer_smt_contention", "--cpu", "not-a-cpu"};
    char *invalid_div_arguments[] = {"platform_observer_smt_contention",
        "--div-batch",
        "0",
        "--cpu",
        "0",
        "--output",
        "unused.csv",
        "--victim-run-id",
        "self-check"};
    if (parse_options(1, missing_arguments, &invalid_options) != 2 ||
        parse_options(3, invalid_cpu_arguments, &invalid_options) != 2 ||
        parse_options(9, invalid_div_arguments, &invalid_options) != 2) {
        fprintf(stderr, "error: self-check invalid-argument paths did not return 2\n");
        return 1;
    }

    unsigned div_batch = SMT_SELF_CHECK_DIV_BATCH;
    unsigned batch_count = SMT_SELF_CHECK_BATCH_COUNT;
    uint64_t *dividends = malloc((size_t)div_batch * sizeof(uint64_t));
    uint32_t *divisors = malloc((size_t)div_batch * sizeof(uint32_t));
    uint64_t *batch_elapsed = malloc((size_t)batch_count * sizeof(uint64_t));
    if (dividends == NULL || divisors == NULL || batch_elapsed == NULL) {
        fprintf(stderr, "error: self-check allocation failed\n");
        free(dividends);
        free(divisors);
        free(batch_elapsed);
        return 1;
    }
    fill_division_operands(dividends, divisors, div_batch);
    unsigned accumulator = 0u;
    for (unsigned batch_index = 0u; batch_index < batch_count; ++batch_index) {
        uint64_t start_nanoseconds = observer_now_nanoseconds();
        accumulator += smt_div_work(dividends, divisors, div_batch);
        uint64_t end_nanoseconds = observer_now_nanoseconds();
        if (start_nanoseconds == 0u || end_nanoseconds <= start_nanoseconds) {
            fprintf(stderr, "error: self-check clock did not advance\n");
            free(dividends);
            free(divisors);
            free(batch_elapsed);
            return 1;
        }
        batch_elapsed[batch_index] = end_nanoseconds - start_nanoseconds;
    }
    if (accumulator == 0u) {
        fprintf(stderr, "error: self-check division work was optimized away\n");
        free(dividends);
        free(divisors);
        free(batch_elapsed);
        return 1;
    }

    char output_path[OBSERVER_PATH_CAPACITY_BYTES];
    if (observer_self_check_output_path(output_path, sizeof(output_path), "smt") != 0) {
        free(dividends);
        free(divisors);
        free(batch_elapsed);
        return 1;
    }
    size_t text_capacity = 128u * ((size_t)batch_count + 1u) + 64u;
    char *csv_text = malloc(text_capacity);
    if (csv_text == NULL) {
        fprintf(stderr, "error: self-check CSV buffer allocation failed\n");
        free(dividends);
        free(divisors);
        free(batch_elapsed);
        return 1;
    }
    size_t used_bytes = 0u;
    int status = observer_append_text(csv_text, text_capacity, &used_bytes, "%s\n", SMT_CSV_HEADER);
    for (unsigned batch_index = 0u; status == 0 && batch_index < batch_count; ++batch_index) {
        status = observer_append_text(csv_text,
            text_capacity,
            &used_bytes,
            "%u,self-check,%llu\n",
            batch_index,
            (unsigned long long)batch_elapsed[batch_index]);
    }
    if (status == 0) {
        status = observer_write_text(output_path, csv_text);
    }
    if (status == 0) {
        status = observer_validate_csv(output_path, SMT_CSV_HEADER, batch_count);
    }
    (void)remove(output_path);
    free(csv_text);
    free(dividends);
    free(divisors);
    free(batch_elapsed);
    if (status != 0) {
        return 1;
    }
    printf("smt_contention_observer self-check: batches=%u div-batch=%u csv=ok\n",
        batch_count,
        div_batch);
    return 0;
}

static int write_batch_csv(const struct smt_options *options, const uint64_t *batch_elapsed)
{
    size_t text_capacity = 128u * ((size_t)options->batch_count + 1u) + 64u;
    char *csv_text = malloc(text_capacity);
    if (csv_text == NULL) {
        fprintf(stderr, "error: cannot allocate CSV buffer\n");
        return 1;
    }
    size_t used_bytes = 0u;
    int status = observer_append_text(csv_text, text_capacity, &used_bytes, "%s\n", SMT_CSV_HEADER);
    for (unsigned batch_index = 0u; status == 0 && batch_index < options->batch_count;
        ++batch_index) {
        status = observer_append_text(csv_text,
            text_capacity,
            &used_bytes,
            "%u,%s,%llu\n",
            batch_index,
            options->victim_run_id,
            (unsigned long long)batch_elapsed[batch_index]);
    }
    if (status == 0) {
        status = observer_write_text(options->output_path, csv_text);
    }
    free(csv_text);
    return status;
}

static int run_observer(const struct smt_options *options)
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
    uint64_t *dividends = malloc((size_t)options->div_batch * sizeof(uint64_t));
    uint32_t *divisors = malloc((size_t)options->div_batch * sizeof(uint32_t));
    uint64_t *batch_elapsed = malloc((size_t)options->batch_count * sizeof(uint64_t));
    if (dividends == NULL || divisors == NULL || batch_elapsed == NULL) {
        fprintf(stderr, "error: cannot allocate observer buffers\n");
        free(dividends);
        free(divisors);
        free(batch_elapsed);
        sync_flag_destroy(sync_flag);
        return 2;
    }
    fill_division_operands(dividends, divisors, options->div_batch);
    unsigned accumulator = 0u;
    int status = 0;
    for (unsigned batch_index = 0u; batch_index < options->batch_count; ++batch_index) {
        if (sync_flag != NULL && sync_flag_wait_turn(sync_flag) != 0) {
            fprintf(stderr, "error: sync flag closed while waiting for victim turn\n");
            status = 1;
            break;
        }
        uint64_t start_nanoseconds = observer_now_nanoseconds();
        accumulator += smt_div_work(dividends, divisors, options->div_batch);
        uint64_t end_nanoseconds = observer_now_nanoseconds();
        if (start_nanoseconds == 0u || end_nanoseconds <= start_nanoseconds) {
            fprintf(stderr, "error: clock did not advance in batch %u\n", batch_index);
            status = 1;
            break;
        }
        batch_elapsed[batch_index] = end_nanoseconds - start_nanoseconds;
        if (sync_flag != NULL) {
            sync_flag_signal_turn(sync_flag);
        }
    }
    if (status == 0) {
        status = write_batch_csv(options, batch_elapsed);
    }
    if (status == 0) {
        uint64_t total_nanoseconds = 0u;
        uint64_t minimum_nanoseconds = batch_elapsed[0];
        uint64_t maximum_nanoseconds = batch_elapsed[0];
        for (unsigned batch_index = 0u; batch_index < options->batch_count; ++batch_index) {
            total_nanoseconds += batch_elapsed[batch_index];
            if (batch_elapsed[batch_index] < minimum_nanoseconds) {
                minimum_nanoseconds = batch_elapsed[batch_index];
            }
            if (batch_elapsed[batch_index] > maximum_nanoseconds) {
                maximum_nanoseconds = batch_elapsed[batch_index];
            }
        }
        printf("smt_contention_observer: cpu=%u batches=%u div-batch=%u mean_nanoseconds=%llu "
               "min_nanoseconds=%llu max_nanoseconds=%llu sink=%u output=%s\n",
            options->cpu_index,
            options->batch_count,
            options->div_batch,
            (unsigned long long)(total_nanoseconds / options->batch_count),
            (unsigned long long)minimum_nanoseconds,
            (unsigned long long)maximum_nanoseconds,
            accumulator,
            options->output_path);
    }
    free(dividends);
    free(divisors);
    free(batch_elapsed);
    sync_flag_destroy(sync_flag);
    return status == 0 ? 0 : 1;
}

int main(int argument_count, char **argument_values)
{
    struct smt_options options;
    if (parse_options(argument_count, argument_values, &options) != 0) {
        print_usage();
        return 2;
    }
    if (options.self_check != 0) {
        return run_self_check();
    }
    return run_observer(&options);
}
