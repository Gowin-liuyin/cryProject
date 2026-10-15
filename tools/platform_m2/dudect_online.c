/* M2 online dudect：上游 dudect_main 每批 10000 次完整 mlkem_decapsulate。
   首批只供上游预热/分位阈值，不计入 t 检验；原始 tick 与类标签在测量窗口外落盘。
   两臂各一个 ELF，标签按公开 seed 与批次序号生成平衡且可复现的乱序。 */
#define _POSIX_C_SOURCE 200809L

#include "collector_inputs.h"

#include "inputs.h"
#include "mlkem.h"
#include "platform_m2.h"

#include <inttypes.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#define DUDECT_IMPLEMENTATION
#include "dudect.h"

#define M2_DUDECT_BATCH_CALLS 10000U
#define M2_DUDECT_MINIMUM_BATCHES 2U
#define M2_DUDECT_MAXIMUM_BATCHES 64U
/* 与 collector 的 tag=4 区分开，避免复用同一条随机流。 */
#define M2_DUDECT_ORDER_TAG 6U

/* dudect 回调没有用户上下文，必要状态放在文件作用域；进程内单线程。 */
static uint8_t m2_dudect_secret_key[MLKEM_DECAPSULATION_KEY_BYTES];
static uint8_t m2_dudect_class_ciphertexts[2][MLKEM_CIPHERTEXT_BYTES];
static uint64_t m2_dudect_order_seed;
static uint64_t m2_dudect_order_counter;
static volatile uint8_t m2_dudect_result_sink;

uint8_t do_one_computation(uint8_t *data)
{
    uint8_t shared_secret[MLKEM_SHARED_SECRET_BYTES];
    if (mlkem_decapsulate(shared_secret,
            sizeof(shared_secret),
            data,
            MLKEM_CIPHERTEXT_BYTES,
            m2_dudect_secret_key,
            sizeof(m2_dudect_secret_key)) != 0) {
        abort();
    }
    /* 窗口内只做一次常量工作量的消费，避免结果被整体删除。 */
    m2_dudect_result_sink ^= shared_secret[0];
    return 0;
}

static uint64_t m2_dudect_draw(uint64_t upper_bound)
{
    uint64_t random_value;
    uint64_t rejection_threshold = (UINT64_C(0) - upper_bound) % upper_bound;
    do {
        uint8_t random_bytes[8];
        expand_test_seed(random_bytes,
            sizeof(random_bytes),
            m2_dudect_order_seed,
            m2_dudect_order_counter++,
            M2_DUDECT_ORDER_TAG);
        random_value = 0;
        for (unsigned byte_index = 0; byte_index < 8U; ++byte_index) {
            random_value |= (uint64_t)random_bytes[byte_index] << (8U * byte_index);
        }
    } while (random_value < rejection_threshold);
    return random_value % upper_bound;
}

void prepare_inputs(dudect_config_t *configuration, uint8_t *input_data, uint8_t *classes)
{
    if (configuration == NULL || input_data == NULL || classes == NULL ||
        configuration->chunk_size != MLKEM_CIPHERTEXT_BYTES ||
        configuration->number_measurements < 2U ||
        configuration->number_measurements % 2U != 0U) {
        abort();
    }
    /* 两臂严格平衡，再用 SHAKE256 随机流洗牌；同 seed 的批次序列逐项可复现。 */
    for (size_t input_index = 0; input_index < configuration->number_measurements; ++input_index) {
        classes[input_index] = (uint8_t)(input_index % 2U);
    }
    for (size_t remaining_count = configuration->number_measurements; remaining_count > 1U;
        --remaining_count) {
        size_t selected_index = (size_t)m2_dudect_draw((uint64_t)remaining_count);
        uint8_t selected_class = classes[selected_index];
        classes[selected_index] = classes[remaining_count - 1U];
        classes[remaining_count - 1U] = selected_class;
    }
    for (size_t input_index = 0; input_index < configuration->number_measurements; ++input_index) {
        memcpy(input_data + input_index * configuration->chunk_size,
            m2_dudect_class_ciphertexts[classes[input_index]],
            MLKEM_CIPHERTEXT_BYTES);
    }
}

static void print_usage(FILE *stream)
{
    fputs("usage: m2_dudect --describe\n"
          "       m2_dudect --collect <new-raw.csv> <batches> <seed> <public-key> <secret-key>\n"
          "                      [--stop-on-positive]\n"
          "  batches is 2..64; batch 0 is the upstream warmup/percentile batch\n"
          "  raw rows are written outside the measurement window; existing files fail\n",
        stream);
}

static int read_fixed_file(const char *path, uint8_t *buffer, size_t expected_byte_count)
{
    FILE *file;
    size_t read_byte_count;
    int operation_status = 0;
    if (path == NULL || buffer == NULL || expected_byte_count == 0) {
        return 1;
    }
    file = fopen(path, "rb");
    if (file == NULL) {
        return 1;
    }
    read_byte_count = fread(buffer, 1, expected_byte_count, file);
    if (read_byte_count != expected_byte_count || fgetc(file) != EOF || ferror(file)) {
        operation_status = 1;
    }
    if (fclose(file) != 0) {
        operation_status = 1;
    }
    return operation_status;
}

int main(int argument_count, char **argument_values)
{
    uint8_t public_key[MLKEM_ENCAPSULATION_KEY_BYTES];
    uint8_t expected_secret[MLKEM_SHARED_SECRET_BYTES];
    uint64_t requested_batches;
    uint64_t order_seed;
    uint64_t completed_batches = 0;
    uint64_t first_positive_batch = 0;
    int has_leakage_evidence = 0;
    int has_positive_batch = 0;
    int stop_on_positive = 0;
    int argument_limit = argument_count;
    int output_status = 0;
    FILE *raw_file = NULL;
    dudect_ctx_t context = {0};
    if (argument_count == 2 && strcmp(argument_values[1], "--describe") == 0) {
        printf("module=M2 variant=%s mode=upstream_dudect_online unit=tsc_ticks holm_member=0 "
               "timing_collection=not_run batch_calls=%u classes=message-zero,message-ones\n",
            mlkem_implementation_name(),
            (unsigned)M2_DUDECT_BATCH_CALLS);
        return 0;
    }
    if (argument_limit > 0 &&
        strcmp(argument_values[argument_limit - 1], "--stop-on-positive") == 0) {
        stop_on_positive = 1;
        argument_limit -= 1;
    }
    if (argument_limit != 7 || strcmp(argument_values[1], "--collect") != 0 ||
        parse_unsigned_integer(argument_values[3], &requested_batches) != 0 ||
        requested_batches < M2_DUDECT_MINIMUM_BATCHES ||
        requested_batches > M2_DUDECT_MAXIMUM_BATCHES ||
        parse_unsigned_integer(argument_values[4], &order_seed) != 0) {
        print_usage(stderr);
        return 2;
    }
    if (read_fixed_file(argument_values[5], public_key, MLKEM_ENCAPSULATION_KEY_BYTES) != 0 ||
        read_fixed_file(argument_values[6], m2_dudect_secret_key, MLKEM_DECAPSULATION_KEY_BYTES) !=
            0) {
        fputs("public/secret key files must hold exactly the MLKEM key sizes\n", stderr);
        return 1;
    }
    if (m2_collector_build_ciphertext(M2_COLLECTOR_MESSAGE_ZERO,
            public_key,
            m2_dudect_class_ciphertexts[0],
            expected_secret) != 0 ||
        m2_collector_build_ciphertext(M2_COLLECTOR_MESSAGE_ONES,
            public_key,
            m2_dudect_class_ciphertexts[1],
            expected_secret) != 0) {
        fputs("dudect ciphertext construction failed\n", stderr);
        return 1;
    }
    erase_secret_bytes(expected_secret, sizeof(expected_secret));
    raw_file = fopen(argument_values[2], "wx");
    if (raw_file == NULL) {
        fputs("raw output exists or is not writable; use a new path\n", stderr);
        return 1;
    }
    if (fputs("batch_index,batch_role,sample_index,class_label,start_tsc,finish_tsc,"
              "elapsed_tsc_ticks\n",
            raw_file) == EOF) {
        output_status = 1;
    }
    dudect_config_t configuration = {MLKEM_CIPHERTEXT_BYTES, M2_DUDECT_BATCH_CALLS};
    if (dudect_init(&context, &configuration) != 0) {
        (void)fclose(raw_file);
        return 1;
    }
    m2_dudect_order_seed = order_seed;
    m2_dudect_order_counter = 0;
    printf("module=M2 variant=%s case=chosen_message_prefix mode=upstream_dudect_online "
           "unit=tsc_ticks holm_member=0 seed=%" PRIu64 " batch_calls=%u requested_batches=%" PRIu64
           "\n",
        mlkem_implementation_name(),
        order_seed,
        (unsigned)M2_DUDECT_BATCH_CALLS,
        requested_batches);
    for (uint64_t batch_index = 0; batch_index < requested_batches; ++batch_index) {
        dudect_state_t batch_state = dudect_main(&context);
        completed_batches += 1U;
        if (batch_state == DUDECT_LEAKAGE_FOUND) {
            has_leakage_evidence = 1;
            if (!has_positive_batch) {
                has_positive_batch = 1;
                first_positive_batch = batch_index;
            }
        }
        /* 测量窗口已结束：这里才落盘原始 tick，并保留上游丢弃的端点与相邻读数。 */
        for (size_t sample_index = 0;
            sample_index + 1U < configuration.number_measurements;
            ++sample_index) {
            uint64_t start_ticks = (uint64_t)context.ticks[sample_index];
            uint64_t finish_ticks = (uint64_t)context.ticks[sample_index + 1U];
            int has_backward_ticks = finish_ticks < start_ticks;
            uint64_t interval_ticks =
                has_backward_ticks ? start_ticks - finish_ticks : finish_ticks - start_ticks;
            if (fprintf(raw_file,
                    "%" PRIu64 ",%s,%zu,%u,%" PRIu64 ",%" PRIu64 ",%s%" PRIu64 "\n",
                    batch_index,
                    batch_index == 0 ? "warmup_upstream" : "measurement",
                    sample_index,
                    (unsigned)context.classes[sample_index],
                    start_ticks,
                    finish_ticks,
                    has_backward_ticks ? "-" : "",
                    interval_ticks) < 0) {
                output_status = 1;
            }
        }
        if (stop_on_positive && has_leakage_evidence) {
            break;
        }
    }
    printf("battery_dudect_status=%s\n"
           "completed_batches=%" PRIu64 " total_calls=%" PRIu64 " warmup_batches=1 "
           "measurement_batches=%" PRIu64 " first_positive_batch=%s stop_on_positive=%d "
           "endpoint_discarded_per_update=11\n",
        has_leakage_evidence ? "online_leakage_found" : "online_no_evidence_yet",
        completed_batches,
        completed_batches * (uint64_t)M2_DUDECT_BATCH_CALLS,
        completed_batches > 0U ? completed_batches - 1U : 0U,
        has_positive_batch ? "yes" : "none",
        stop_on_positive);
    output_status |= dudect_free(&context) != 0;
    if (fflush(raw_file) != 0) {
        output_status = 1;
    }
    if (fclose(raw_file) != 0) {
        output_status = 1;
    }
    erase_secret_bytes(m2_dudect_secret_key, sizeof(m2_dudect_secret_key));
    erase_secret_bytes(expected_secret, sizeof(expected_secret));
    output_status |= ferror(stdout) != 0;
    return output_status;
}
