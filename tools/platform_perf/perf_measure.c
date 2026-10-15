/*
 * T20 性能采集件：对**完整 KEM 调用**逐次计时（keygen / encaps / decaps）。
 *
 * 与 r03/m5 的"同类输入重复"采集件不同，本件的观察量是**每类操作的开销**，
 * 不是两个秘密类之间的耗时差：
 *   - keygen : 一次完整 mlkem_generate_key_pair
 *   - encaps : 一次完整 mlkem_encapsulate
 *   - decaps : 一次完整 mlkem_decapsulate（固定合法密文，走接受路径）
 * 因此 CSV 的 input_category 列写的是操作名，而不是输入秘密类。
 *
 * 计时窗口只包**一次**完整调用；预热、密钥/密文准备、结果消费、CSV/meta 写盘、
 * ELF 自哈希全部在窗口外。keygen 与 encaps 的窗口内包含公开 API 自身的
 * `system_random_bytes` 调用——这是完整调用的一部分，如实记录在 meta。
 *
 * 本文件只用两棵树共同的 include/mlkem.h 与 include/inputs.h，按目标树的实现
 * 静态库链接即可，源内零后端条件编译。
 *
 * 不 fork、不 daemonize、不 setsid、不写亲和性、不写频率、不写本进程之外的路径；
 * CSV 与 meta 一律用 "wx" 新建，绝不覆盖既有文件。
 */
#define _POSIX_C_SOURCE 200809L

#include "inputs.h"
#include "mlkem.h"

#include <inttypes.h>
#include <stdatomic.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/utsname.h>
#include <time.h>
#include <unistd.h>

#ifndef PERF_ARM_NAME
#define PERF_ARM_NAME "unspecified-arm"
#endif
#ifndef PERF_BUILD_FLAGS
#define PERF_BUILD_FLAGS "unspecified-build-flags"
#endif

#define PERF_TOOL_NAME "perf_measure"
#define PERF_TOOL_SCHEMA "perf_measure_v1"
#define PERF_OPERATION_COUNT 3u
#define PERF_MAXIMUM_SAMPLES_PER_OPERATION 400000u
#define PERF_MAXIMUM_WARMUP_CALLS 10000u
#define PERF_DEFAULT_WARMUP_CALLS 100u
#define PERF_DECAPS_OPERATION 0u
#define PERF_KEYGEN_OPERATION 1u
#define PERF_ENCAPS_OPERATION 2u

static const char *const perf_operation_names[PERF_OPERATION_COUNT] = {
    "decaps", "keygen", "encaps"};
static const char *const perf_operation_descriptions[PERF_OPERATION_COUNT] = {
    "one_complete_mlkem_decapsulate_on_fixed_valid_ciphertext",
    "one_complete_mlkem_generate_key_pair",
    "one_complete_mlkem_encapsulate_with_fixed_encapsulation_key"};

/* ============================== SHA-256（自足，不依赖目标树） ============================== */

struct perf_sha256_context {
    uint32_t state_words[8];
    uint64_t total_byte_count;
    size_t buffered_byte_count;
    uint8_t buffer[64];
};

static const uint32_t perf_sha256_round_constants[64] = {0x428a2f98u, 0x71374491u, 0xb5c0fbcfu,
    0xe9b5dba5u, 0x3956c25bu, 0x59f111f1u, 0x923f82a4u, 0xab1c5ed5u, 0xd807aa98u, 0x12835b01u,
    0x243185beu, 0x550c7dc3u, 0x72be5d74u, 0x80deb1feu, 0x9bdc06a7u, 0xc19bf174u, 0xe49b69c1u,
    0xefbe4786u, 0x0fc19dc6u, 0x240ca1ccu, 0x2de92c6fu, 0x4a7484aau, 0x5cb0a9dcu, 0x76f988dau,
    0x983e5152u, 0xa831c66du, 0xb00327c8u, 0xbf597fc7u, 0xc6e00bf3u, 0xd5a79147u, 0x06ca6351u,
    0x14292967u, 0x27b70a85u, 0x2e1b2138u, 0x4d2c6dfcu, 0x53380d13u, 0x650a7354u, 0x766a0abbu,
    0x81c2c92eu, 0x92722c85u, 0xa2bfe8a1u, 0xa81a664bu, 0xc24b8b70u, 0xc76c51a3u, 0xd192e819u,
    0xd6990624u, 0xf40e3585u, 0x106aa070u, 0x19a4c116u, 0x1e376c08u, 0x2748774cu, 0x34b0bcb5u,
    0x391c0cb3u, 0x4ed8aa4au, 0x5b9cca4fu, 0x682e6ff3u, 0x748f82eeu, 0x78a5636fu, 0x84c87814u,
    0x8cc70208u, 0x90befffau, 0xa4506cebu, 0xbef9a3f7u, 0xc67178f2u};

static uint32_t perf_rotate_right_32(uint32_t value, unsigned shift_count)
{
    return (value >> shift_count) | (value << (32u - shift_count));
}

static void perf_sha256_compress(struct perf_sha256_context *context, const uint8_t block[64])
{
    uint32_t schedule[64];
    uint32_t working[8];
    for (unsigned word_index = 0; word_index < 16u; ++word_index) {
        uint32_t word_value = 0;
        for (unsigned byte_index = 0; byte_index < 4u; ++byte_index) {
            word_value = (word_value << 8u) | (uint32_t)block[word_index * 4u + byte_index];
        }
        schedule[word_index] = word_value;
    }
    for (unsigned word_index = 16u; word_index < 64u; ++word_index) {
        uint32_t previous_15 = schedule[word_index - 15u];
        uint32_t previous_2 = schedule[word_index - 2u];
        uint32_t sigma_0 = perf_rotate_right_32(previous_15, 7u) ^
            perf_rotate_right_32(previous_15, 18u) ^ (previous_15 >> 3u);
        uint32_t sigma_1 = perf_rotate_right_32(previous_2, 17u) ^
            perf_rotate_right_32(previous_2, 19u) ^ (previous_2 >> 10u);
        schedule[word_index] = schedule[word_index - 16u] + sigma_0 +
            schedule[word_index - 7u] + sigma_1;
    }
    for (unsigned word_index = 0; word_index < 8u; ++word_index) {
        working[word_index] = context->state_words[word_index];
    }
    for (unsigned round_index = 0; round_index < 64u; ++round_index) {
        uint32_t big_sigma_1 = perf_rotate_right_32(working[4], 6u) ^
            perf_rotate_right_32(working[4], 11u) ^ perf_rotate_right_32(working[4], 25u);
        uint32_t choose = (working[4] & working[5]) ^ ((~working[4]) & working[6]);
        uint32_t temporary_1 = working[7] + big_sigma_1 + choose +
            perf_sha256_round_constants[round_index] + schedule[round_index];
        uint32_t big_sigma_0 = perf_rotate_right_32(working[0], 2u) ^
            perf_rotate_right_32(working[0], 13u) ^ perf_rotate_right_32(working[0], 22u);
        uint32_t majority = (working[0] & working[1]) ^ (working[0] & working[2]) ^
            (working[1] & working[2]);
        uint32_t temporary_2 = big_sigma_0 + majority;
        working[7] = working[6];
        working[6] = working[5];
        working[5] = working[4];
        working[4] = working[3] + temporary_1;
        working[3] = working[2];
        working[2] = working[1];
        working[1] = working[0];
        working[0] = temporary_1 + temporary_2;
    }
    for (unsigned word_index = 0; word_index < 8u; ++word_index) {
        context->state_words[word_index] += working[word_index];
    }
}

static void perf_sha256_initialize(struct perf_sha256_context *context)
{
    static const uint32_t initial_state[8] = {0x6a09e667u, 0xbb67ae85u, 0x3c6ef372u,
        0xa54ff53au, 0x510e527fu, 0x9b05688cu, 0x1f83d9abu, 0x5be0cd19u};
    for (unsigned word_index = 0; word_index < 8u; ++word_index) {
        context->state_words[word_index] = initial_state[word_index];
    }
    context->total_byte_count = 0u;
    context->buffered_byte_count = 0u;
    memset(context->buffer, 0, sizeof(context->buffer));
}

static void perf_sha256_update(struct perf_sha256_context *context,
    const uint8_t *input_bytes,
    size_t input_byte_count)
{
    context->total_byte_count += (uint64_t)input_byte_count;
    for (size_t byte_index = 0; byte_index < input_byte_count; ++byte_index) {
        context->buffer[context->buffered_byte_count] = input_bytes[byte_index];
        context->buffered_byte_count += 1u;
        if (context->buffered_byte_count == 64u) {
            perf_sha256_compress(context, context->buffer);
            context->buffered_byte_count = 0u;
        }
    }
}

static void perf_sha256_finalize(struct perf_sha256_context *context, uint8_t digest_bytes[32])
{
    uint64_t total_bit_count = context->total_byte_count * UINT64_C(8);
    uint8_t padding_byte = 0x80u;
    perf_sha256_update(context, &padding_byte, 1u);
    uint8_t zero_byte = 0u;
    while (context->buffered_byte_count != 56u) {
        perf_sha256_update(context, &zero_byte, 1u);
    }
    uint8_t length_bytes[8];
    for (unsigned byte_index = 0; byte_index < 8u; ++byte_index) {
        length_bytes[byte_index] =
            (uint8_t)((total_bit_count >> (56u - 8u * byte_index)) & UINT64_C(0xff));
    }
    perf_sha256_update(context, length_bytes, 8u);
    for (unsigned word_index = 0; word_index < 8u; ++word_index) {
        digest_bytes[word_index * 4u] = (uint8_t)(context->state_words[word_index] >> 24u);
        digest_bytes[word_index * 4u + 1u] = (uint8_t)(context->state_words[word_index] >> 16u);
        digest_bytes[word_index * 4u + 2u] = (uint8_t)(context->state_words[word_index] >> 8u);
        digest_bytes[word_index * 4u + 3u] = (uint8_t)context->state_words[word_index];
    }
}

static void perf_sha256_digest(uint8_t digest_bytes[32],
    const uint8_t *input_bytes,
    size_t input_byte_count)
{
    struct perf_sha256_context context;
    perf_sha256_initialize(&context);
    perf_sha256_update(&context, input_bytes, input_byte_count);
    perf_sha256_finalize(&context, digest_bytes);
}

/* ============================== 基础工具 ============================== */

static int perf_parse_unsigned(const char *text, uint64_t *integer_value)
{
    if (text == NULL || *text == '\0') {
        return 1;
    }
    uint64_t accumulated = 0u;
    for (const char *character = text; *character != '\0'; ++character) {
        if (*character < '0' || *character > '9') {
            return 1;
        }
        if (accumulated > (UINT64_MAX - (uint64_t)(*character - '0')) / 10u) {
            return 1;
        }
        accumulated = accumulated * 10u + (uint64_t)(*character - '0');
    }
    *integer_value = accumulated;
    return 0;
}

static uint64_t perf_splitmix64(uint64_t *state_value)
{
    *state_value += UINT64_C(0x9e3779b97f4a7c15);
    uint64_t mixed = *state_value;
    mixed = (mixed ^ (mixed >> 30u)) * UINT64_C(0xbf58476d1ce4e5b9);
    mixed = (mixed ^ (mixed >> 27u)) * UINT64_C(0x94d049bb133111eb);
    return mixed ^ (mixed >> 31u);
}

static int perf_read_monotonic_nanoseconds(uint64_t *timestamp_nanoseconds)
{
    struct timespec timestamp;
    if (clock_gettime(CLOCK_MONOTONIC, &timestamp) != 0) {
        return 1;
    }
    if (timestamp.tv_sec < 0 || timestamp.tv_nsec < 0 || timestamp.tv_nsec >= 1000000000L) {
        return 1;
    }
    if ((uint64_t)timestamp.tv_sec > (UINT64_MAX - (uint64_t)timestamp.tv_nsec) / UINT64_C(1000000000)) {
        return 1;
    }
    *timestamp_nanoseconds =
        (uint64_t)timestamp.tv_sec * UINT64_C(1000000000) + (uint64_t)timestamp.tv_nsec;
    return 0;
}

static int perf_check_timer(uint64_t *resolution_nanoseconds)
{
    struct timespec resolution;
    if (clock_getres(CLOCK_MONOTONIC, &resolution) != 0) {
        return 1;
    }
    if (resolution.tv_sec < 0 || resolution.tv_nsec < 0) {
        return 1;
    }
    *resolution_nanoseconds =
        (uint64_t)resolution.tv_sec * UINT64_C(1000000000) + (uint64_t)resolution.tv_nsec;
    uint64_t previous_timestamp = 0u;
    if (perf_read_monotonic_nanoseconds(&previous_timestamp) != 0) {
        return 1;
    }
    for (unsigned probe_index = 0; probe_index < 16u; ++probe_index) {
        uint64_t current_timestamp = 0u;
        if (perf_read_monotonic_nanoseconds(&current_timestamp) != 0 ||
            current_timestamp < previous_timestamp) {
            return 1;
        }
        previous_timestamp = current_timestamp;
    }
    return 0;
}

static void perf_read_cpu_model(char *cpu_model, size_t cpu_model_capacity_bytes)
{
    strncpy(cpu_model, "unavailable", cpu_model_capacity_bytes - 1u);
    cpu_model[cpu_model_capacity_bytes - 1u] = '\0';
    FILE *model_file = fopen("/proc/cpuinfo", "r");
    if (model_file == NULL) {
        return;
    }
    char line_buffer[512];
    while (fgets(line_buffer, sizeof(line_buffer), model_file) != NULL) {
        if (strncmp(line_buffer, "model name", 10u) != 0) {
            continue;
        }
        const char *separator = strchr(line_buffer, ':');
        if (separator == NULL) {
            continue;
        }
        ++separator;
        while (*separator == ' ' || *separator == '\t') {
            ++separator;
        }
        size_t length = strlen(separator);
        while (length > 0u &&
            (separator[length - 1u] == '\n' || separator[length - 1u] == '\r')) {
            --length;
        }
        if (length >= cpu_model_capacity_bytes) {
            length = cpu_model_capacity_bytes - 1u;
        }
        memcpy(cpu_model, separator, length);
        cpu_model[length] = '\0';
        break;
    }
    fclose(model_file);
}

static int perf_hash_running_executable(uint8_t sha256_digest[32], int *digest_available)
{
    *digest_available = 0;
    FILE *executable_file = fopen("/proc/self/exe", "rb");
    if (executable_file == NULL) {
        return 0;
    }
    struct perf_sha256_context context;
    perf_sha256_initialize(&context);
    uint8_t chunk[65536];
    size_t read_byte_count;
    while ((read_byte_count = fread(chunk, 1u, sizeof(chunk), executable_file)) > 0u) {
        perf_sha256_update(&context, chunk, read_byte_count);
    }
    int read_error = ferror(executable_file);
    fclose(executable_file);
    if (read_error) {
        return 1;
    }
    perf_sha256_finalize(&context, sha256_digest);
    *digest_available = 1;
    return 0;
}

/* ============================== 采样 ============================== */

struct perf_options {
    const char *run_id;
    const char *raw_path;
    const char *meta_path;
    const char *arm_name;
    uint64_t test_seed;
    uint64_t warmup_calls;
    uint64_t samples_per_operation[PERF_OPERATION_COUNT];
    uint64_t block_index;
    uint64_t block_count;
    uint64_t order_seed;
    int describe_only;
};

static void perf_print_usage(void)
{
    fputs("usage: perf_measure --run-id ID --seed N --raw NEW.csv [--meta NEW.meta]\n"
          "                    [--warmup W] [--decaps-samples D] [--keygen-samples K]\n"
          "                    [--encaps-samples E] [--arm NAME] [--block-index B]\n"
          "                    [--block-count C] [--order-seed S] | --describe\n",
        stderr);
}

static int perf_parse_arguments(int argument_count, char **argument_values,
    struct perf_options *options)
{
    memset(options, 0, sizeof(*options));
    options->warmup_calls = PERF_DEFAULT_WARMUP_CALLS;
    options->block_index = 0u;
    options->block_count = 1u;
    options->order_seed = 20261016u;
    options->arm_name = PERF_ARM_NAME;
    for (int argument_index = 1; argument_index < argument_count; ++argument_index) {
        const char *option = argument_values[argument_index];
        if (strcmp(option, "--describe") == 0) {
            options->describe_only = 1;
            continue;
        }
        if (argument_index + 1 >= argument_count) {
            return 1;
        }
        const char *value = argument_values[argument_index + 1];
        ++argument_index;
        if (strcmp(option, "--run-id") == 0) {
            options->run_id = value;
        } else if (strcmp(option, "--raw") == 0) {
            options->raw_path = value;
        } else if (strcmp(option, "--meta") == 0) {
            options->meta_path = value;
        } else if (strcmp(option, "--arm") == 0) {
            options->arm_name = value;
        } else if (strcmp(option, "--seed") == 0) {
            if (perf_parse_unsigned(value, &options->test_seed) != 0) {
                return 1;
            }
        } else if (strcmp(option, "--warmup") == 0) {
            if (perf_parse_unsigned(value, &options->warmup_calls) != 0 ||
                options->warmup_calls > PERF_MAXIMUM_WARMUP_CALLS) {
                return 1;
            }
        } else if (strcmp(option, "--decaps-samples") == 0) {
            if (perf_parse_unsigned(value, &options->samples_per_operation[PERF_DECAPS_OPERATION]) !=
                    0 ||
                options->samples_per_operation[PERF_DECAPS_OPERATION] >
                    PERF_MAXIMUM_SAMPLES_PER_OPERATION) {
                return 1;
            }
        } else if (strcmp(option, "--keygen-samples") == 0) {
            if (perf_parse_unsigned(value, &options->samples_per_operation[PERF_KEYGEN_OPERATION]) !=
                    0 ||
                options->samples_per_operation[PERF_KEYGEN_OPERATION] >
                    PERF_MAXIMUM_SAMPLES_PER_OPERATION) {
                return 1;
            }
        } else if (strcmp(option, "--encaps-samples") == 0) {
            if (perf_parse_unsigned(value, &options->samples_per_operation[PERF_ENCAPS_OPERATION]) !=
                    0 ||
                options->samples_per_operation[PERF_ENCAPS_OPERATION] >
                    PERF_MAXIMUM_SAMPLES_PER_OPERATION) {
                return 1;
            }
        } else if (strcmp(option, "--block-index") == 0) {
            if (perf_parse_unsigned(value, &options->block_index) != 0) {
                return 1;
            }
        } else if (strcmp(option, "--block-count") == 0) {
            if (perf_parse_unsigned(value, &options->block_count) != 0 ||
                options->block_count == 0u) {
                return 1;
            }
        } else if (strcmp(option, "--order-seed") == 0) {
            if (perf_parse_unsigned(value, &options->order_seed) != 0) {
                return 1;
            }
        } else {
            return 1;
        }
    }
    if (options->describe_only) {
        return 0;
    }
    if (options->run_id == NULL || *options->run_id == '\0' || strlen(options->run_id) > 64u ||
        options->raw_path == NULL || *options->raw_path == '\0') {
        return 1;
    }
    for (const char *character = options->run_id; *character != '\0'; ++character) {
        if (!((*character >= 'a' && *character <= 'z') ||
                (*character >= 'A' && *character <= 'Z') ||
                (*character >= '0' && *character <= '9') || *character == '_' ||
                *character == '-')) {
            return 1;
        }
    }
    uint64_t total_samples = 0u;
    for (unsigned operation_index = 0; operation_index < PERF_OPERATION_COUNT;
        ++operation_index) {
        total_samples += options->samples_per_operation[operation_index];
    }
    if (total_samples == 0u || options->block_index >= options->block_count) {
        return 1;
    }
    return 0;
}

static void perf_describe(void)
{
    printf("tool=%s\nschema=%s\n", PERF_TOOL_NAME, PERF_TOOL_SCHEMA);
    printf("operations=");
    for (unsigned operation_index = 0; operation_index < PERF_OPERATION_COUNT;
        ++operation_index) {
        printf("%s%s", operation_index == 0u ? "" : ",",
            perf_operation_names[operation_index]);
    }
    printf("\noperation_scopes=");
    for (unsigned operation_index = 0; operation_index < PERF_OPERATION_COUNT;
        ++operation_index) {
        printf("%s%s", operation_index == 0u ? "" : ",",
            perf_operation_descriptions[operation_index]);
    }
    printf("\nimplementation=%s\nbuild_flags=%s\n", mlkem_implementation_name(),
        PERF_BUILD_FLAGS);
    printf("timer_source=clock_gettime(CLOCK_MONOTONIC)\ntime_unit=ns\n");
    printf("maximum_samples_per_operation=%u\nmaximum_warmup_calls=%u\n",
        PERF_MAXIMUM_SAMPLES_PER_OPERATION, PERF_MAXIMUM_WARMUP_CALLS);
    printf("csv_header=run_id,implementation,input_category,sample_index,"
           "elapsed_nanoseconds,time_unit\n");
}

static volatile uint8_t perf_result_sink;

static void perf_decapsulate_once(const uint8_t *ciphertext,
    const uint8_t *decapsulation_key,
    uint8_t *shared_secret,
    int *operation_status)
{
    *operation_status = mlkem_decapsulate(shared_secret,
        MLKEM_SHARED_SECRET_BYTES,
        ciphertext,
        MLKEM_CIPHERTEXT_BYTES,
        decapsulation_key,
        MLKEM_DECAPSULATION_KEY_BYTES);
}

static void perf_generate_key_pair_once(uint8_t *encapsulation_key,
    uint8_t *decapsulation_key,
    int *operation_status)
{
    *operation_status = mlkem_generate_key_pair(encapsulation_key,
        MLKEM_ENCAPSULATION_KEY_BYTES,
        decapsulation_key,
        MLKEM_DECAPSULATION_KEY_BYTES);
}

static void perf_encapsulate_once(const uint8_t *encapsulation_key,
    uint8_t *ciphertext,
    uint8_t *shared_secret,
    int *operation_status)
{
    *operation_status = mlkem_encapsulate(ciphertext,
        MLKEM_CIPHERTEXT_BYTES,
        shared_secret,
        MLKEM_SHARED_SECRET_BYTES,
        encapsulation_key,
        MLKEM_ENCAPSULATION_KEY_BYTES);
}

int main(int argument_count, char **argument_values)
{
    struct perf_options options;
    uint8_t encapsulation_key[MLKEM_ENCAPSULATION_KEY_BYTES];
    uint8_t decapsulation_key[MLKEM_DECAPSULATION_KEY_BYTES];
    uint8_t warmup_encapsulation_key[MLKEM_ENCAPSULATION_KEY_BYTES];
    uint8_t warmup_decapsulation_key[MLKEM_DECAPSULATION_KEY_BYTES];
    uint8_t ciphertext[MLKEM_CIPHERTEXT_BYTES];
    uint8_t shared_secret[MLKEM_SHARED_SECRET_BYTES];
    uint8_t encapsulation_key_digest[32];
    uint8_t ciphertext_digest[32];
    uint8_t executable_digest[32];
    uint64_t timer_resolution_nanoseconds = 0u;
    uint64_t zero_elapsed_count = 0u;
    uint64_t preparation_nanoseconds = 0u;
    uint64_t run_start_nanoseconds = 0u;
    uint64_t run_end_nanoseconds = 0u;
    int executable_digest_available = 0;
    int operation_status = 1;
    unsigned operation_order[PERF_OPERATION_COUNT] = {0u, 1u, 2u};
    uint64_t *elapsed_samples[PERF_OPERATION_COUNT] = {NULL, NULL, NULL};
    uint64_t completed_samples[PERF_OPERATION_COUNT] = {0u, 0u, 0u};
    char cpu_model[256];
    struct utsname system_information;
    FILE *csv_file = NULL;

    if (perf_parse_arguments(argument_count, argument_values, &options) != 0) {
        perf_print_usage();
        return 2;
    }
    if (options.describe_only) {
        perf_describe();
        return 0;
    }
    if (perf_check_timer(&timer_resolution_nanoseconds) != 0) {
        fputs("timer check failed\n", stderr);
        return 1;
    }

    /* 可复现的操作顺序乱序：同一 order-seed 在任何臂上给出同一排列。 */
    for (unsigned remaining_count = PERF_OPERATION_COUNT; remaining_count > 1u;
        --remaining_count) {
        uint64_t draw_state = options.order_seed + remaining_count;
        uint64_t draw_value = perf_splitmix64(&draw_state) % (uint64_t)remaining_count;
        unsigned selected_index = (unsigned)draw_value;
        unsigned swapped = operation_order[selected_index];
        operation_order[selected_index] = operation_order[remaining_count - 1u];
        operation_order[remaining_count - 1u] = swapped;
    }

    if (perf_read_monotonic_nanoseconds(&preparation_nanoseconds) != 0 ||
        generate_test_key_pair(options.test_seed, encapsulation_key, decapsulation_key) != 0 ||
        generate_test_ciphertext(
            INPUT_VALID, options.test_seed, 0u, encapsulation_key, ciphertext) != 0 ||
        generate_test_key_pair(
            options.test_seed + UINT64_C(1), warmup_encapsulation_key, warmup_decapsulation_key) !=
            0) {
        fputs("input preparation failed\n", stderr);
        return 1;
    }
    perf_sha256_digest(encapsulation_key_digest, encapsulation_key, sizeof(encapsulation_key));
    perf_sha256_digest(ciphertext_digest, ciphertext, sizeof(ciphertext));

    /* 预热：每个操作各 W 次，全部在计时窗口之外。 */
    for (uint64_t warmup_index = 0; warmup_index < options.warmup_calls; ++warmup_index) {
        int warmup_status = 0;
        perf_decapsulate_once(ciphertext, decapsulation_key, shared_secret, &warmup_status);
        if (warmup_status != 0) {
            fputs("decapsulation warmup failed\n", stderr);
            return 1;
        }
        perf_result_sink ^= shared_secret[0];
        perf_generate_key_pair_once(
            warmup_encapsulation_key, warmup_decapsulation_key, &warmup_status);
        if (warmup_status != 0) {
            fputs("key generation warmup failed\n", stderr);
            return 1;
        }
        perf_result_sink ^= warmup_encapsulation_key[0];
        perf_encapsulate_once(
            encapsulation_key, ciphertext, shared_secret, &warmup_status);
        if (warmup_status != 0) {
            fputs("encapsulation warmup failed\n", stderr);
            return 1;
        }
        perf_result_sink ^= shared_secret[0];
    }

    for (unsigned operation_index = 0; operation_index < PERF_OPERATION_COUNT;
        ++operation_index) {
        uint64_t sample_count = options.samples_per_operation[operation_index];
        if (sample_count == 0u) {
            continue;
        }
        elapsed_samples[operation_index] = calloc((size_t)sample_count, sizeof(uint64_t));
        if (elapsed_samples[operation_index] == NULL) {
            fputs("sample allocation failed\n", stderr);
            goto cleanup;
        }
    }

    if (perf_read_monotonic_nanoseconds(&run_start_nanoseconds) != 0) {
        goto cleanup;
    }
    for (unsigned order_index = 0; order_index < PERF_OPERATION_COUNT; ++order_index) {
        unsigned operation_index = operation_order[order_index];
        uint64_t sample_count = options.samples_per_operation[operation_index];
        for (uint64_t sample_index = 0; sample_index < sample_count; ++sample_index) {
            uint64_t start_nanoseconds = 0u;
            uint64_t end_nanoseconds = 0u;
            int call_status = 0;
            if (perf_read_monotonic_nanoseconds(&start_nanoseconds) != 0) {
                goto cleanup;
            }
            atomic_signal_fence(memory_order_seq_cst);
            if (operation_index == PERF_DECAPS_OPERATION) {
                perf_decapsulate_once(
                    ciphertext, decapsulation_key, shared_secret, &call_status);
            } else if (operation_index == PERF_KEYGEN_OPERATION) {
                perf_generate_key_pair_once(
                    encapsulation_key, decapsulation_key, &call_status);
            } else {
                perf_encapsulate_once(
                    encapsulation_key, ciphertext, shared_secret, &call_status);
            }
            atomic_signal_fence(memory_order_seq_cst);
            if (perf_read_monotonic_nanoseconds(&end_nanoseconds) != 0) {
                goto cleanup;
            }
            if (call_status != 0 || end_nanoseconds < start_nanoseconds) {
                fputs("measured call failed\n", stderr);
                goto cleanup;
            }
            perf_result_sink ^= shared_secret[0];
            elapsed_samples[operation_index][sample_index] =
                end_nanoseconds - start_nanoseconds;
            if (end_nanoseconds == start_nanoseconds) {
                ++zero_elapsed_count;
            }
            completed_samples[operation_index] += 1u;
        }
    }
    if (perf_read_monotonic_nanoseconds(&run_end_nanoseconds) != 0) {
        goto cleanup;
    }

    csv_file = fopen(options.raw_path, "wx");
    if (csv_file == NULL) {
        fputs("cannot create CSV (must not exist)\n", stderr);
        goto cleanup;
    }
    if (fprintf(csv_file,
            "run_id,implementation,input_category,sample_index,elapsed_nanoseconds,time_unit\n") <
        0) {
        goto cleanup;
    }
    for (unsigned operation_index = 0; operation_index < PERF_OPERATION_COUNT;
        ++operation_index) {
        for (uint64_t sample_index = 0; sample_index < completed_samples[operation_index];
            ++sample_index) {
            if (fprintf(csv_file,
                    "%s,%s,%s,%" PRIu64 ",%" PRIu64 ",ns\n",
                    options.run_id,
                    mlkem_implementation_name(),
                    perf_operation_names[operation_index],
                    sample_index,
                    elapsed_samples[operation_index][sample_index]) < 0) {
                goto cleanup;
            }
        }
    }
    if (fflush(csv_file) != 0 || fclose(csv_file) != 0) {
        csv_file = NULL;
        goto cleanup;
    }
    csv_file = NULL;

    if (options.meta_path != NULL) {
        FILE *meta_file = fopen(options.meta_path, "wx");
        if (meta_file == NULL) {
            fputs("cannot create meta (must not exist)\n", stderr);
            goto cleanup;
        }
        uname(&system_information);
        perf_read_cpu_model(cpu_model, sizeof(cpu_model));
        executable_digest_available = 0;
        if (perf_hash_running_executable(executable_digest, &executable_digest_available) != 0) {
            fclose(meta_file);
            goto cleanup;
        }
        fprintf(meta_file, "tool=%s\nschema=%s\n", PERF_TOOL_NAME, PERF_TOOL_SCHEMA);
        fprintf(meta_file, "run_id=%s\n", options.run_id);
        fprintf(meta_file, "arm=%s\n", options.arm_name);
        fprintf(meta_file, "implementation=%s\n", mlkem_implementation_name());
        fprintf(meta_file, "build_flags=%s\n", PERF_BUILD_FLAGS);
        fprintf(meta_file, "test_seed=%" PRIu64 "\n", options.test_seed);
        fprintf(meta_file, "warmup_calls_per_operation=%" PRIu64 "\n", options.warmup_calls);
        for (unsigned operation_index = 0; operation_index < PERF_OPERATION_COUNT;
            ++operation_index) {
            fprintf(meta_file,
                "operation=%s samples=%" PRIu64 " window=%s\n",
                perf_operation_names[operation_index],
                completed_samples[operation_index],
                perf_operation_descriptions[operation_index]);
        }
        fprintf(meta_file, "block_index=%" PRIu64 "\nblock_count=%" PRIu64 "\n",
            options.block_index, options.block_count);
        fprintf(meta_file, "order_seed=%" PRIu64 "\noperation_order=", options.order_seed);
        for (unsigned order_index = 0; order_index < PERF_OPERATION_COUNT; ++order_index) {
            fprintf(meta_file, "%s%s", order_index == 0u ? "" : ",",
                perf_operation_names[operation_order[order_index]]);
        }
        fprintf(meta_file, "\n");
        fprintf(meta_file, "decaps_input=fixed_valid_ciphertext_seed_%" PRIu64
                           "_index_0_accept_path\n",
            options.test_seed);
        fprintf(meta_file, "encapsulation_key_source=fixed_test_key_pair_seed_%" PRIu64 "\n",
            options.test_seed);
        fprintf(meta_file, "encapsulation_key_sha256=");
        for (size_t byte_index = 0; byte_index < sizeof(encapsulation_key_digest); ++byte_index) {
            fprintf(meta_file, "%02x", encapsulation_key_digest[byte_index]);
        }
        fprintf(meta_file, "\nciphertext_sha256=");
        for (size_t byte_index = 0; byte_index < sizeof(ciphertext_digest); ++byte_index) {
            fprintf(meta_file, "%02x", ciphertext_digest[byte_index]);
        }
        fprintf(meta_file, "\n");
        fprintf(meta_file, "time_unit=ns\ntimer_source=clock_gettime(CLOCK_MONOTONIC)\n");
        fprintf(meta_file, "timer_resolution_ns=%" PRIu64 "\n", timer_resolution_nanoseconds);
        fprintf(meta_file, "clock_overhead_subtracted=no\nlong_tail_trimmed=no\n");
        fprintf(meta_file, "preparation_start_ns=%" PRIu64 "\n", preparation_nanoseconds);
        fprintf(meta_file, "timed_window_start_ns=%" PRIu64 "\n", run_start_nanoseconds);
        fprintf(meta_file, "timed_window_end_ns=%" PRIu64 "\n", run_end_nanoseconds);
        fprintf(meta_file, "zero_elapsed_count=%" PRIu64 "\n", zero_elapsed_count);
        fprintf(meta_file, "run_status=complete\n");
        fprintf(meta_file, "cpu_model=%s\n", cpu_model);
        fprintf(meta_file, "uname_sysname=%s\nuname_release=%s\nuname_machine=%s\n",
            system_information.sysname,
            system_information.release,
            system_information.machine);
        fprintf(meta_file, "cpu_affinity=not_pinned\nfrequency_control=not_configured\n");
        fprintf(meta_file, "csv_header=run_id,implementation,input_category,sample_index,"
                           "elapsed_nanoseconds,time_unit\n");
        if (executable_digest_available) {
            fprintf(meta_file, "executable_sha256=");
            for (size_t byte_index = 0; byte_index < sizeof(executable_digest); ++byte_index) {
                fprintf(meta_file, "%02x", executable_digest[byte_index]);
            }
            fprintf(meta_file, "\n");
        } else {
            fprintf(meta_file, "executable_sha256=unavailable\n");
        }
        if (fflush(meta_file) != 0 || fclose(meta_file) != 0) {
            goto cleanup;
        }
    }

    operation_status = 0;
    printf("%s: arm=%s implementation=%s decaps=%" PRIu64 " keygen=%" PRIu64
           " encaps=%" PRIu64 " raw_times_in_ns\n",
        PERF_TOOL_NAME,
        options.arm_name,
        mlkem_implementation_name(),
        completed_samples[PERF_DECAPS_OPERATION],
        completed_samples[PERF_KEYGEN_OPERATION],
        completed_samples[PERF_ENCAPS_OPERATION]);

cleanup:
    if (csv_file != NULL) {
        fclose(csv_file);
    }
    for (unsigned operation_index = 0; operation_index < PERF_OPERATION_COUNT;
        ++operation_index) {
        free(elapsed_samples[operation_index]);
    }
    return operation_status;
}
