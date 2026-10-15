#define _POSIX_C_SOURCE 200809L

#include "compare.h"
#include "inputs.h"

#include <inttypes.h>
#include <stdatomic.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>

#if defined(__linux__)
#define M4_CLOCK_ID CLOCK_MONOTONIC_RAW
#define M4_CLOCK_NAME "CLOCK_MONOTONIC_RAW"
#else
#define M4_CLOCK_ID CLOCK_MONOTONIC
#define M4_CLOCK_NAME "CLOCK_MONOTONIC"
#endif

/* 平台 measure 协议要求的固定预热：正式窗口之前两类交替各 50 次，不计时也不写 CSV。 */
#define M4_WARMUP_CALLS 100U

static volatile unsigned observed_result;

static int read_nanoseconds(uint64_t *timestamp_nanoseconds)
{
    struct timespec timestamp;
    if (clock_gettime(M4_CLOCK_ID, &timestamp) != 0 || timestamp.tv_sec < 0 ||
        timestamp.tv_nsec < 0 || timestamp.tv_nsec >= 1000000000L ||
        (uint64_t)timestamp.tv_sec >
            (UINT64_MAX - (uint64_t)timestamp.tv_nsec) / UINT64_C(1000000000)) {
        return 1;
    }
    *timestamp_nanoseconds =
        (uint64_t)timestamp.tv_sec * UINT64_C(1000000000) + (uint64_t)timestamp.tv_nsec;
    return 0;
}

static int has_valid_run_id(const char *run_id)
{
    size_t run_id_bytes = strlen(run_id);
    if (run_id_bytes == 0U || run_id_bytes > 63U) {
        return 0;
    }
    for (size_t character_index = 0U; character_index < run_id_bytes; character_index++) {
        char character = run_id[character_index];
        if (!((character >= 'a' && character <= 'z') || (character >= 'A' && character <= 'Z') ||
                (character >= '0' && character <= '9') || character == '-' || character == '_')) {
            return 0;
        }
    }
    return 1;
}

static int print_usage(void)
{
    fputs("usage: m4_measure --describe | --collect NEW.csv CALLS_PER_CLASS SEED RUN_ID "
          "[--compare-bytes 1..32]\n",
        stderr);
    return 2;
}

/* 截断臂的预期结果：mismatch-last 的差异固定在第 31 字节，一旦被比较前缀短于 32 字节就落在
 * 窗口之外，内核必然返回相等。主路径（32 字节）仍保持原先「两类都必须不等」的判据。 */
static int expected_is_equal(uint8_t class_label, size_t compare_length_bytes)
{
    if (class_label == 0U || compare_length_bytes == PLATFORM_M4_INPUT_BYTES) {
        return 0;
    }
    return 1;
}

/* 主路径保持原窗口：完整 m4_compare_checked（含入参校验）。
 * 截断臂不能改夹具的密码语义，因此直接计内核 m4_compare_bytes，窗口仍是「一次比较」。 */
static int compare_once(const uint8_t *secret_bytes,
    const uint8_t *candidate_bytes,
    size_t compare_length_bytes,
    int *is_equal)
{
    if (compare_length_bytes == PLATFORM_M4_INPUT_BYTES) {
        return m4_compare_checked(secret_bytes,
            PLATFORM_M4_INPUT_BYTES,
            candidate_bytes,
            PLATFORM_M4_INPUT_BYTES,
            is_equal);
    }
    *is_equal = m4_compare_bytes(secret_bytes, candidate_bytes, compare_length_bytes);
    return 0;
}

int main(int argument_count, char **argument_values)
{
    if (argument_count == 2 && strcmp(argument_values[1], "--describe") == 0) {
        puts("module=M4 case=artificial_compare boundary=complete_checked_compare bytes=32 "
             "classes=mismatch-first,mismatch-last timing_collection=not_run "
             "compare_bytes_default=32 compare_bytes_range=1..32 abi_bytes=32 warmup_calls=100 "
             "truncation_rule=mismatch-last:equal_when_compare_bytes_lt_32");
        return 0;
    }
    uint64_t calls_per_class;
    uint64_t order_seed;
    uint64_t compare_bytes_value = PLATFORM_M4_INPUT_BYTES;
    if ((argument_count != 6 && argument_count != 8) ||
        strcmp(argument_values[1], "--collect") != 0 ||
        m4_parse_unsigned(argument_values[3], 2U, 1000000U, &calls_per_class) != 0 ||
        m4_parse_unsigned(argument_values[4], 1U, UINT64_MAX, &order_seed) != 0 ||
        !has_valid_run_id(argument_values[5])) {
        return print_usage();
    }
    if (argument_count == 8 &&
        (strcmp(argument_values[6], "--compare-bytes") != 0 ||
            m4_parse_unsigned(argument_values[7], 1U, PLATFORM_M4_INPUT_BYTES,
                &compare_bytes_value) != 0)) {
        return print_usage();
    }
    size_t compare_length_bytes = (size_t)compare_bytes_value;
    size_t call_count = (size_t)calls_per_class * 2U;
    uint8_t *class_order = malloc(call_count);
    uint64_t *elapsed_nanoseconds = calloc(call_count, sizeof(*elapsed_nanoseconds));
    uint8_t secret_inputs[2][PLATFORM_M4_INPUT_BYTES];
    uint8_t candidate_inputs[2][PLATFORM_M4_INPUT_BYTES];
    uint64_t order_state = order_seed;
    if (class_order == NULL || elapsed_nanoseconds == NULL ||
        m4_prepare_class_order(class_order, call_count, &order_state) != 0 ||
        m4_prepare_case(0U, secret_inputs[0], candidate_inputs[0]) != 0 ||
        m4_prepare_case(1U, secret_inputs[1], candidate_inputs[1]) != 0) {
        free(class_order);
        free(elapsed_nanoseconds);
        return 1;
    }
    char metadata_path[4096];
    int path_bytes = snprintf(metadata_path, sizeof(metadata_path), "%s.meta", argument_values[2]);
    if (path_bytes < 0 || (size_t)path_bytes >= sizeof(metadata_path)) {
        free(class_order);
        free(elapsed_nanoseconds);
        return 2;
    }
    FILE *raw_file = fopen(argument_values[2], "wx");
    FILE *metadata_file = fopen(metadata_path, "wx");
    if (raw_file == NULL || metadata_file == NULL) {
        if (raw_file != NULL) {
            fclose(raw_file);
        }
        if (metadata_file != NULL) {
            fclose(metadata_file);
        }
        free(class_order);
        free(elapsed_nanoseconds);
        return 1;
    }
    int collection_status = 0;
    size_t completed_calls = 0U;
    size_t observed_equal_counts[2] = {0U, 0U};
    size_t expected_equal_counts[2] = {0U, 0U};
    uint8_t working_secret[PLATFORM_M4_INPUT_BYTES];
    /* 固定 100 次预热：两类交替各 50 次，不读钟、不写 CSV，也不消耗 order_state。 */
    for (size_t warmup_index = 0U; warmup_index < M4_WARMUP_CALLS; warmup_index++) {
        uint8_t warmup_class = (uint8_t)(warmup_index % 2U);
        memcpy(working_secret, secret_inputs[warmup_class], sizeof(working_secret));
        int warmup_is_equal = 0;
        if (compare_once(working_secret, candidate_inputs[0], compare_length_bytes,
                &warmup_is_equal) != 0) {
            collection_status = 1;
            break;
        }
        observed_result ^= (unsigned)warmup_is_equal;
    }
    for (size_t sample_index = 0U; collection_status == 0 && sample_index < call_count;
        sample_index++) {
        uint8_t class_label = class_order[sample_index];
        int expected_equal = expected_is_equal(class_label, compare_length_bytes);
        memcpy(working_secret, secret_inputs[class_label], sizeof(working_secret));
        int is_equal = 0;
        uint64_t start_nanoseconds;
        uint64_t finish_nanoseconds;
        atomic_signal_fence(memory_order_seq_cst);
        if (read_nanoseconds(&start_nanoseconds) != 0) {
            collection_status = 1;
            break;
        }
        int compare_status = compare_once(working_secret, candidate_inputs[0],
            compare_length_bytes, &is_equal);
        atomic_signal_fence(memory_order_seq_cst);
        if (read_nanoseconds(&finish_nanoseconds) != 0 || finish_nanoseconds < start_nanoseconds) {
            collection_status = 1;
            break;
        }
        elapsed_nanoseconds[sample_index] = finish_nanoseconds - start_nanoseconds;
        completed_calls++;
        observed_equal_counts[class_label] += (size_t)(is_equal != 0);
        expected_equal_counts[class_label] += (size_t)(expected_equal != 0);
        observed_result ^= (unsigned)is_equal;
        /* 只有「实际结果偏离本臂预期」才算失败；截断臂的预期相等不是失败。 */
        if (compare_status != 0 || is_equal != expected_equal) {
            collection_status = 1;
            break;
        }
    }
    int output_status = fputs("run_id,implementation,input_category,sample_index,"
                              "elapsed_nanoseconds,time_unit\n",
                            raw_file) < 0;
    for (size_t sample_index = 0U; sample_index < completed_calls; sample_index++) {
        if (fprintf(raw_file,
                "%s,m4-%s,%s,%zu,%" PRIu64 ",ns\n",
                argument_values[5],
                M4_VARIANT_NAME,
                class_order[sample_index] == 0U ? "mismatch-first" : "mismatch-last",
                sample_index,
                elapsed_nanoseconds[sample_index]) < 0) {
            output_status = 1;
        }
    }
    /* 默认路径的 boundary 取值保持原字面；只有截断臂换成它真正计量的窗口名。 */
    const char *boundary_name = compare_length_bytes == PLATFORM_M4_INPUT_BYTES
        ? "complete_checked_compare"
        : "truncated_compare_bytes";
    const char *mismatch_last_expectation =
        compare_length_bytes == PLATFORM_M4_INPUT_BYTES ? "unequal" : "equal";
    if (fprintf(metadata_file,
            "module=M4\ncase=artificial_compare\nboundary=%s\n"
            "variant=%s\nclock=%s\nunit=ns\norder=balanced_adjacent_pair_splitmix64\n"
            "seed=%" PRIu64 "\nrequested_calls=%zu\ncompleted_calls=%zu\n"
            "collection_status=%d\nfrequency_control=external_controller_required\n"
            "compare_bytes=%zu\nabi_bytes=%u\nwarmup_calls=%u\n"
            "expected_equal_count_mismatch_first=%zu\n"
            "expected_equal_count_mismatch_last=%zu\n"
            "observed_equal_count_mismatch_first=%zu\n"
            "observed_equal_count_mismatch_last=%zu\n"
            "expected_result=mismatch-first:unequal,mismatch-last:%s\n",
            boundary_name,
            M4_VARIANT_NAME,
            M4_CLOCK_NAME,
            order_seed,
            call_count,
            completed_calls,
            collection_status,
            compare_length_bytes,
            PLATFORM_M4_INPUT_BYTES,
            M4_WARMUP_CALLS,
            expected_equal_counts[0],
            expected_equal_counts[1],
            observed_equal_counts[0],
            observed_equal_counts[1],
            mismatch_last_expectation) < 0) {
        output_status = 1;
    }
    output_status |= fclose(raw_file) != 0;
    output_status |= fclose(metadata_file) != 0;
    free(class_order);
    free(elapsed_nanoseconds);
    return collection_status || output_status;
}
