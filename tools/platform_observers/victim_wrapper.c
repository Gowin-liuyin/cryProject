/* victim_wrapper：观测者 pilot 的受害者侧驱动（R18/R19 冻结 PLAN §2 的 wrapper 变体，
 * run manifest 记 sync_mode=wrapper_hook）。
 *
 * 协议与两个观测者逐拍咬合（sync_flag 的 wait_turn 是"序号有变化即返回"，可能吞掉
 * 自己的 signal，因此 wrapper 一律用绝对序号目标轮询）：
 *   smt  每批：wrapper signal（序号 +1，观测者开始除法批）-> [计时窗口] ->
 *              观测者 signal（+1）-> wrapper 等序号达到 起点+2
 *   cache 每个(样本,行)：wrapper signal（+1，观测者 clflush）-> [计时窗口] ->
 *              wrapper signal（+1，观测者 reload 计时）-> 观测者 signal（+1）->
 *              wrapper 等序号达到 起点+3
 *
 * 纪律：所有 flag 读写、CSV 记录与 I/O 都在计时窗口之外；窗口内只有读钟、
 * atomic_signal_fence 与一次解封装；类别按批/样本序号交替（schedule=alternating，
 * 写入 meta）。计时用 CLOCK_MONOTONIC（与 collector 合同一致）。
 *
 * 启动次序：本程序先创建同步文件，再等 --startup-grace-ms（默认 800）后才开始
 * 第一个 turn——观测者必须在宽限期内完成 sync_flag_open_named（open 时把
 * last_seen 初始化为当前序号，晚于首个 signal 打开会被吞掉首个信号）。 */

#define _POSIX_C_SOURCE 200809L

#include "observer_common.h"
#include "sync_flag.h"
#include "victim_backend.h"

#include <signal.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>
#include <unistd.h>

#define VICTIM_USAGE_TEXT                                                             \
    "usage: victim_wrapper --sync-file <path> --protocol smt|cache --batches <n>"      \
    " --run-id <id>\n"                                                                 \
    "       --victim-csv <path> --victim-meta <path> --classes-csv <path> --seed <n>"  \
    "\n"                                                                               \
    "       [--line-count 2] [--startup-grace-ms 800] [--cpu <n>]\n"

#define VICTIM_ROW_TEXT_CAPACITY_BYTES 96u
#define VICTIM_CSV_HEADER \
    "run_id,implementation,input_category,sample_index,elapsed_nanoseconds,time_unit\n"

static uint64_t victim_now_nanoseconds(void)
{
    struct timespec now;
    if (clock_gettime(CLOCK_MONOTONIC, &now) != 0) {
        return UINT64_C(0);
    }
    return (uint64_t)now.tv_sec * UINT64_C(1000000000) + (uint64_t)now.tv_nsec;
}

/* 轮询直到共享序号达到绝对目标；观测者关闭同步页时返回 -1。
 * 逐次走 wait_turn 以复用其 sched_yield，目标未达则继续等。 */
static int victim_wait_sequence(struct sync_flag *flag, uint64_t target_sequence)
{
    for (;;) {
        if (sync_flag_current_sequence(flag) >= target_sequence) {
            return 0;
        }
        if (sync_flag_wait_turn(flag) != 0) {
            return -1;
        }
    }
}

int main(int argument_count, char **argument_values)
{
    const char *sync_file_path = NULL;
    const char *protocol_text = NULL;
    const char *run_id = NULL;
    const char *victim_csv_path = NULL;
    const char *victim_meta_path = NULL;
    const char *classes_csv_path = NULL;
    unsigned long long batch_count = 0u;
    unsigned long long seed_value = 0u;
    unsigned long long line_count = 2u;
    unsigned long long startup_grace_milliseconds = 800u;
    unsigned long long cpu_index = 0u;
    int cpu_requested = 0;
    for (int argument_index = 1; argument_index < argument_count; ++argument_index) {
        const char *argument = argument_values[argument_index];
        const char *value = NULL;
        if (strcmp(argument, "--sync-file") == 0 &&
            observer_take_value(argument_count, argument_values, &argument_index, "--sync-file", &value) == 0) {
            sync_file_path = value;
        } else if (strcmp(argument, "--protocol") == 0 &&
            observer_take_value(argument_count, argument_values, &argument_index, "--protocol", &value) == 0) {
            protocol_text = value;
        } else if (strcmp(argument, "--run-id") == 0 &&
            observer_take_value(argument_count, argument_values, &argument_index, "--run-id", &value) == 0) {
            run_id = value;
        } else if (strcmp(argument, "--victim-csv") == 0 &&
            observer_take_value(argument_count, argument_values, &argument_index, "--victim-csv", &value) == 0) {
            victim_csv_path = value;
        } else if (strcmp(argument, "--victim-meta") == 0 &&
            observer_take_value(argument_count, argument_values, &argument_index, "--victim-meta", &value) == 0) {
            victim_meta_path = value;
        } else if (strcmp(argument, "--classes-csv") == 0 &&
            observer_take_value(argument_count, argument_values, &argument_index, "--classes-csv", &value) == 0) {
            classes_csv_path = value;
        } else if (strcmp(argument, "--batches") == 0 &&
            observer_take_value(argument_count, argument_values, &argument_index, "--batches", &value) == 0 &&
            observer_parse_unsigned(value, 1u, 1000000u, &batch_count) == 0) {
            continue;
        } else if (strcmp(argument, "--seed") == 0 &&
            observer_take_value(argument_count, argument_values, &argument_index, "--seed", &value) == 0 &&
            observer_parse_unsigned(value, 0u, UINT64_MAX, &seed_value) == 0) {
            continue;
        } else if (strcmp(argument, "--line-count") == 0 &&
            observer_take_value(argument_count, argument_values, &argument_index, "--line-count", &value) == 0 &&
            observer_parse_unsigned(value, 1u, 64u, &line_count) == 0) {
            continue;
        } else if (strcmp(argument, "--startup-grace-ms") == 0 &&
            observer_take_value(argument_count, argument_values, &argument_index, "--startup-grace-ms", &value) == 0 &&
            observer_parse_unsigned(value, 0u, 60000u, &startup_grace_milliseconds) == 0) {
            continue;
        } else if (strcmp(argument, "--cpu") == 0 &&
            observer_take_value(argument_count, argument_values, &argument_index, "--cpu", &value) == 0 &&
            observer_parse_unsigned(value, 0u, 1023u, &cpu_index) == 0) {
            cpu_requested = 1;
            continue;
        } else {
            fputs(VICTIM_USAGE_TEXT, stderr);
            return 1;
        }
    }
    int is_cache_protocol = (protocol_text != NULL && strcmp(protocol_text, "cache") == 0);
    int is_smt_protocol = (protocol_text != NULL && strcmp(protocol_text, "smt") == 0);
    if (sync_file_path == NULL || (!is_cache_protocol && !is_smt_protocol) || batch_count == 0u ||
        run_id == NULL || victim_csv_path == NULL || victim_meta_path == NULL ||
        classes_csv_path == NULL) {
        fputs(VICTIM_USAGE_TEXT, stderr);
        return 1;
    }
    if (is_smt_protocol) {
        line_count = 1u;
    }

    if (cpu_requested && observer_bind_cpu((unsigned)cpu_index) != 0) {
        fprintf(stderr, "error: cannot bind cpu %llu\n", cpu_index);
        return 2;
    }
    if (victim_backend_prepare((uint64_t)seed_value) != 0) {
        fprintf(stderr, "error: backend prepare failed\n");
        return 2;
    }

    struct sync_flag *flag = sync_flag_create_named(sync_file_path);
    if (flag == NULL) {
        return 2;
    }
    struct timespec grace = {(time_t)(startup_grace_milliseconds / 1000u),
        (long)((startup_grace_milliseconds % 1000u) * 1000000u)};
    (void)nanosleep(&grace, NULL);

    unsigned long long window_count = batch_count * line_count;
    uint64_t *elapsed_nanoseconds = malloc(sizeof(uint64_t) * (size_t)window_count);
    if (elapsed_nanoseconds == NULL) {
        sync_flag_destroy(flag);
        return 2;
    }
    unsigned long long watchdog_seconds = window_count / 8u + 60u;
    if (watchdog_seconds > 3600u) {
        watchdog_seconds = 3600u;
    }
    (void)alarm((unsigned)watchdog_seconds);

    for (unsigned long long batch_index = 0u; batch_index < batch_count; ++batch_index) {
        int class_is_ones = (int)(batch_index % 2u);
        uint8_t shared_secret[VICTIM_SHARED_SECRET_BYTES];
        for (unsigned long long line_index = 0u; line_index < line_count; ++line_index) {
            uint64_t batch_start_sequence = sync_flag_current_sequence(flag);
            sync_flag_signal_turn(flag);
            uint64_t start_nanoseconds = victim_now_nanoseconds();
            __atomic_signal_fence(__ATOMIC_SEQ_CST);
            int decapsulation_status = victim_backend_decapsulate_once(class_is_ones, shared_secret);
            __atomic_signal_fence(__ATOMIC_SEQ_CST);
            uint64_t finish_nanoseconds = victim_now_nanoseconds();
            if (decapsulation_status != 0) {
                fprintf(stderr,
                    "error: backend decapsulation failed at batch %llu\n",
                    batch_index);
                sync_flag_destroy(flag);
                return 2;
            }
            uint64_t done_target_sequence;
            if (is_cache_protocol) {
                sync_flag_signal_turn(flag);
                done_target_sequence = batch_start_sequence + 3u;
            } else {
                done_target_sequence = batch_start_sequence + 2u;
            }
            if (victim_wait_sequence(flag, done_target_sequence) != 0) {
                fprintf(stderr, "error: sync flag closed at batch %llu\n", batch_index);
                sync_flag_destroy(flag);
                return 3;
            }
            elapsed_nanoseconds[batch_index * line_count + line_index] =
                finish_nanoseconds - start_nanoseconds;
        }
    }
    (void)alarm(0u);
    sync_flag_destroy(flag);

    const char *backend_name = victim_backend_name();
    size_t csv_capacity =
        (size_t)window_count * VICTIM_ROW_TEXT_CAPACITY_BYTES + strlen(VICTIM_CSV_HEADER) + 1u;
    char *csv_text = malloc(csv_capacity);
    size_t classes_capacity = (size_t)batch_count * 32u + 64u;
    char *classes_text = malloc(classes_capacity);
    char meta_text[4096];
    if (csv_text == NULL || classes_text == NULL) {
        free(csv_text);
        free(classes_text);
        free(elapsed_nanoseconds);
        return 2;
    }
    size_t csv_used = 0u;
    observer_append_text(csv_text, csv_capacity, &csv_used, "%s", VICTIM_CSV_HEADER);
    for (unsigned long long window_index = 0u; window_index < window_count; ++window_index) {
        unsigned long long batch_index = window_index / line_count;
        int class_is_ones = (int)(batch_index % 2u);
        observer_append_text(csv_text,
            csv_capacity,
            &csv_used,
            "%s,%s,%s,%llu,%llu,ns\n",
            run_id,
            backend_name,
            class_is_ones != 0 ? "message-ones" : "message-zero",
            window_index,
            (unsigned long long)elapsed_nanoseconds[window_index]);
    }
    size_t classes_used = 0u;
    if (is_cache_protocol) {
        observer_append_text(classes_text, classes_capacity, &classes_used, "sample_index,class_label\n");
    } else {
        observer_append_text(classes_text, classes_capacity, &classes_used, "batch_index,class_label\n");
    }
    for (unsigned long long batch_index = 0u; batch_index < batch_count; ++batch_index) {
        observer_append_text(classes_text,
            classes_capacity,
            &classes_used,
            "%llu,%s\n",
            batch_index,
            (batch_index % 2u) != 0u ? "message-ones" : "message-zero");
    }
    size_t meta_used = 0u;
    observer_append_text(meta_text,
        sizeof(meta_text),
        &meta_used,
        "run_id=%s\nbackend=%s\nprotocol=%s\nsync_mode=wrapper_hook\nschedule=alternating\n"
        "seed=%llu\nbatches=%llu\nline_count=%llu\nclock=CLOCK_MONOTONIC\n"
        "class_zero=message-zero\nclass_ones=message-ones\nvictim_rows=%llu\n"
        "classes_rows=%llu\nstartup_grace_ms=%llu\nsync_file=%s\n",
        run_id,
        backend_name,
        is_cache_protocol ? "cache" : "smt",
        seed_value,
        batch_count,
        line_count,
        window_count,
        batch_count,
        startup_grace_milliseconds,
        sync_file_path);
    if (observer_write_text(victim_csv_path, csv_text) != 0 ||
        observer_write_text(classes_csv_path, classes_text) != 0 ||
        observer_write_text(victim_meta_path, meta_text) != 0) {
        free(csv_text);
        free(classes_text);
        free(elapsed_nanoseconds);
        return 2;
    }
    free(csv_text);
    free(classes_text);
    free(elapsed_nanoseconds);
    return 0;
}
