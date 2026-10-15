/*
 * r03 族外对照采集件：格式破损输入对照（valid / malformed / truncated）。
 *
 * 三个臂共用本文件，各臂各自链接自己的实现：
 *   - m1-historical-unfixed : liboqs 0.10.0 historical-clangover（未打 982c762）
 *   - m1-historical-fixed   : liboqs 0.10.0 + 官方修复 982c762
 *   - m5-native-reference   : mlkem-native b3ba7b3 portable reference（未打补丁）
 *
 * 本文件只使用两棵树共同稳定的 include/mlkem.h 与 include/inputs.h，因此不含任何
 * 后端条件编译；derand 封装符号用弱声明在链接期按实际链接的静态库解析，用来把
 * "valid 类解出的共享密钥" 与 "同一密文封装侧的共享密钥" 逐字节对上。
 *
 * 三类输入刻意是同一份密文的三种形态（每类内部重复同一份输入）：
 *   valid      : 固定测试种子下 generate_test_ciphertext(VALID, seed, 0, ek) 的 1088 字节密文
 *   malformed  : 同一份密文，u 压缩字段（前 960 字节）整体 0xFF、v 压缩字段（后 128 字节）整体 0x00
 *   truncated  : 同一份密文，只喂 1087 字节（长度不足 1 字节）
 * 计时窗口只包一次 mlkem_decapsulate 调用；truncated 的窗口只包封装层长度检查那一次调用。
 *
 * 本程序不 fork、不 daemonize、不 setsid、不写亲和性、不写频率、不产生临时文件；
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
#ifdef __APPLE__
#include <mach-o/dyld.h>
#endif

#ifndef R03_ARM_NAME
#define R03_ARM_NAME "unspecified-arm"
#endif
#ifndef R03_LINKED_IMPLEMENTATION
#define R03_LINKED_IMPLEMENTATION "unspecified-implementation"
#endif
#ifndef R03_BUILD_FLAGS
#define R03_BUILD_FLAGS "unspecified-build-flags"
#endif

#define R03_TOOL_NAME "r03_malformed_measure"
#define R03_TOOL_SCHEMA "r03_malformed_measure_v1"
#define R03_MAXIMUM_SAMPLES_PER_CLASS 20000u
#define R03_MAXIMUM_WARMUP_CALLS 10000u
#define R03_CLASS_COUNT 3u
#define R03_DEFAULT_DESCRIBE_SEED 31337u
#define R03_ORDER_PURPOSE_TAG 4u
#define R03_ENUMERATION_SEED_PURPOSE_TAG 2u

static const char *const r03_class_names[R03_CLASS_COUNT] = {"valid", "malformed", "truncated"};
static const char *const r03_class_paths[R03_CLASS_COUNT] = {"full_decapsulation",
    "full_decapsulation",
    "length_rejection"};
static const char *const r03_class_constructions[R03_CLASS_COUNT] = {
    "fixed_valid_ciphertext_1088_bytes",
    "same_ciphertext_u_ff_v_00_1088_bytes",
    "same_ciphertext_first_1087_bytes"};

/* ============================ 摘要实现（自足，不依赖两棵树） ============================ */

struct r03_sha256_context {
    uint32_t state_words[8];
    uint64_t total_byte_count;
    size_t buffered_byte_count;
    uint8_t buffer[64];
};

static const uint32_t r03_sha256_round_constants[64] = {0x428a2f98u, 0x71374491u, 0xb5c0fbcfu,
    0xe9b5dba5u, 0x3956c25bu, 0x59f111f1u, 0x923f82a4u, 0xab1c5ed5u, 0xd807aa98u, 0x12835b01u,
    0x243185beu, 0x550c7dc3u, 0x72be5d74u, 0x80deb1feu, 0x9bdc06a7u, 0xc19bf174u, 0xe49b69c1u,
    0xefbe4786u, 0x0fc19dc6u, 0x240ca1ccu, 0x2de92c6fu, 0x4a7484aau, 0x5cb0a9dcu, 0x76f988dau,
    0x983e5152u, 0xa831c66du, 0xb00327c8u, 0xbf597fc7u, 0xc6e00bf3u, 0xd5a79147u, 0x06ca6351u,
    0x14292967u, 0x27b70a85u, 0x2e1b2138u, 0x4d2c6dfcu, 0x53380d13u, 0x650a7354u, 0x766a0abbu,
    0x81c2c92eu, 0x92722c85u, 0xa2bfe8a1u, 0xa81a664bu, 0xc24b8b70u, 0xc76c51a3u, 0xd192e819u,
    0xd6990624u, 0xf40e3585u, 0x106aa070u, 0x19a4c116u, 0x1e376c08u, 0x2748774cu, 0x34b0bcb5u,
    0x391c0cb3u, 0x4ed8aa4au, 0x5b9cca4fu, 0x682e6ff3u, 0x748f82eeu, 0x78a5636fu, 0x84c87814u,
    0x8cc70208u, 0x90befffau, 0xa4506cebu, 0xbef9a3f7u, 0xc67178f2u};

static uint32_t r03_rotate_right_32(uint32_t value, unsigned shift_count)
{
    return (value >> shift_count) | (value << (32u - shift_count));
}

static void r03_sha256_compress(struct r03_sha256_context *context, const uint8_t block[64])
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
        uint32_t sigma_0 = r03_rotate_right_32(previous_15, 7u) ^
            r03_rotate_right_32(previous_15, 18u) ^ (previous_15 >> 3u);
        uint32_t sigma_1 = r03_rotate_right_32(previous_2, 17u) ^
            r03_rotate_right_32(previous_2, 19u) ^ (previous_2 >> 10u);
        schedule[word_index] = schedule[word_index - 16u] + sigma_0 + schedule[word_index - 7u] +
            sigma_1;
    }
    for (unsigned word_index = 0; word_index < 8u; ++word_index) {
        working[word_index] = context->state_words[word_index];
    }
    for (unsigned round_index = 0; round_index < 64u; ++round_index) {
        uint32_t big_sigma_1 = r03_rotate_right_32(working[4], 6u) ^
            r03_rotate_right_32(working[4], 11u) ^ r03_rotate_right_32(working[4], 25u);
        uint32_t choose = (working[4] & working[5]) ^ ((~working[4]) & working[6]);
        uint32_t temporary_1 = working[7] + big_sigma_1 + choose +
            r03_sha256_round_constants[round_index] + schedule[round_index];
        uint32_t big_sigma_0 = r03_rotate_right_32(working[0], 2u) ^
            r03_rotate_right_32(working[0], 13u) ^ r03_rotate_right_32(working[0], 22u);
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

static void r03_sha256_initialize(struct r03_sha256_context *context)
{
    static const uint32_t initial_state_words[8] = {0x6a09e667u, 0xbb67ae85u, 0x3c6ef372u,
        0xa54ff53au, 0x510e527fu, 0x9b05688cu, 0x1f83d9abu, 0x5be0cd19u};
    for (unsigned word_index = 0; word_index < 8u; ++word_index) {
        context->state_words[word_index] = initial_state_words[word_index];
    }
    context->total_byte_count = 0;
    context->buffered_byte_count = 0;
}

static void r03_sha256_update(struct r03_sha256_context *context,
    const uint8_t *input_bytes,
    size_t input_byte_count)
{
    context->total_byte_count += (uint64_t)input_byte_count;
    size_t consumed_byte_count = 0;
    while (consumed_byte_count < input_byte_count) {
        size_t free_byte_count = 64u - context->buffered_byte_count;
        size_t take_byte_count = input_byte_count - consumed_byte_count;
        if (take_byte_count > free_byte_count) {
            take_byte_count = free_byte_count;
        }
        memcpy(context->buffer + context->buffered_byte_count,
            input_bytes + consumed_byte_count,
            take_byte_count);
        context->buffered_byte_count += take_byte_count;
        consumed_byte_count += take_byte_count;
        if (context->buffered_byte_count == 64u) {
            r03_sha256_compress(context, context->buffer);
            context->buffered_byte_count = 0;
        }
    }
}

static void r03_sha256_finalize(struct r03_sha256_context *context, uint8_t digest_bytes[32])
{
    uint64_t total_bit_count = context->total_byte_count * UINT64_C(8);
    uint8_t padding_byte = 0x80u;
    r03_sha256_update(context, &padding_byte, 1u);
    uint8_t zero_byte = 0x00u;
    while (context->buffered_byte_count != 56u) {
        r03_sha256_update(context, &zero_byte, 1u);
    }
    uint8_t length_bytes[8];
    for (unsigned byte_index = 0; byte_index < 8u; ++byte_index) {
        length_bytes[byte_index] = (uint8_t)(total_bit_count >> (8u * (7u - byte_index)));
    }
    /* 长度字段不参与 total_byte_count 记账，直接压入缓冲并压缩。 */
    memcpy(context->buffer + context->buffered_byte_count, length_bytes, 8u);
    r03_sha256_compress(context, context->buffer);
    context->buffered_byte_count = 0;
    for (unsigned word_index = 0; word_index < 8u; ++word_index) {
        for (unsigned byte_index = 0; byte_index < 4u; ++byte_index) {
            digest_bytes[word_index * 4u + byte_index] =
                (uint8_t)(context->state_words[word_index] >> (8u * (3u - byte_index)));
        }
    }
}

static void r03_sha256_digest(uint8_t digest_bytes[32],
    const uint8_t *input_bytes,
    size_t input_byte_count)
{
    struct r03_sha256_context context;
    r03_sha256_initialize(&context);
    r03_sha256_update(&context, input_bytes, input_byte_count);
    r03_sha256_finalize(&context, digest_bytes);
}

static const uint64_t r03_keccak_round_constants[24] = {UINT64_C(0x0000000000000001),
    UINT64_C(0x0000000000008082), UINT64_C(0x800000000000808a), UINT64_C(0x8000000080008000),
    UINT64_C(0x000000000000808b), UINT64_C(0x0000000080000001), UINT64_C(0x8000000080008081),
    UINT64_C(0x8000000000008009), UINT64_C(0x000000000000008a), UINT64_C(0x0000000000000088),
    UINT64_C(0x0000000080008009), UINT64_C(0x000000008000000a), UINT64_C(0x000000008000808b),
    UINT64_C(0x800000000000008b), UINT64_C(0x8000000000008089), UINT64_C(0x8000000000008003),
    UINT64_C(0x8000000000008002), UINT64_C(0x8000000000000080), UINT64_C(0x000000000000800a),
    UINT64_C(0x800000008000000a), UINT64_C(0x8000000080008081), UINT64_C(0x8000000000008080),
    UINT64_C(0x0000000080000001), UINT64_C(0x8000000080008008)};

/* r[x + 5*y]，Keccak-f[1600] 的 rho 旋转量。 */
static const unsigned r03_keccak_rotation_offsets[25] = {0u, 1u, 62u, 28u, 27u, 36u, 44u, 6u, 55u,
    20u, 3u, 10u, 43u, 25u, 39u, 41u, 45u, 15u, 21u, 8u, 18u, 2u, 61u, 56u, 14u};

static uint64_t r03_rotate_left_64(uint64_t value, unsigned shift_count)
{
    if (shift_count == 0u) {
        return value;
    }
    return (value << shift_count) | (value >> (64u - shift_count));
}

static void r03_keccak_permute(uint64_t state_lanes[25])
{
    for (unsigned round_index = 0; round_index < 24u; ++round_index) {
        uint64_t column_parity[5];
        for (unsigned column_index = 0; column_index < 5u; ++column_index) {
            column_parity[column_index] = state_lanes[column_index] ^ state_lanes[column_index + 5u] ^
                state_lanes[column_index + 10u] ^ state_lanes[column_index + 15u] ^
                state_lanes[column_index + 20u];
        }
        for (unsigned column_index = 0; column_index < 5u; ++column_index) {
            uint64_t theta_delta = column_parity[(column_index + 4u) % 5u] ^
                r03_rotate_left_64(column_parity[(column_index + 1u) % 5u], 1u);
            for (unsigned row_index = 0; row_index < 5u; ++row_index) {
                state_lanes[column_index + 5u * row_index] ^= theta_delta;
            }
        }
        uint64_t permuted_lanes[25];
        for (unsigned column_index = 0; column_index < 5u; ++column_index) {
            for (unsigned row_index = 0; row_index < 5u; ++row_index) {
                unsigned source_index = column_index + 5u * row_index;
                unsigned target_column = row_index;
                unsigned target_row = (2u * column_index + 3u * row_index) % 5u;
                permuted_lanes[target_column + 5u * target_row] =
                    r03_rotate_left_64(state_lanes[source_index],
                        r03_keccak_rotation_offsets[source_index]);
            }
        }
        for (unsigned column_index = 0; column_index < 5u; ++column_index) {
            for (unsigned row_index = 0; row_index < 5u; ++row_index) {
                uint64_t current_lane = permuted_lanes[column_index + 5u * row_index];
                uint64_t next_lane = permuted_lanes[(column_index + 1u) % 5u + 5u * row_index];
                uint64_t following_lane = permuted_lanes[(column_index + 2u) % 5u + 5u * row_index];
                state_lanes[column_index + 5u * row_index] =
                    current_lane ^ ((~next_lane) & following_lane);
            }
        }
        state_lanes[0] ^= r03_keccak_round_constants[round_index];
    }
}

struct r03_keccak_context {
    uint64_t state_lanes[25];
    size_t rate_byte_count;
    uint8_t domain_byte;
    size_t buffered_byte_count;
    uint8_t buffer[136];
};

static void r03_keccak_absorb_block(struct r03_keccak_context *context, const uint8_t block[136])
{
    size_t lane_count = context->rate_byte_count / 8u;
    for (size_t lane_index = 0; lane_index < lane_count; ++lane_index) {
        uint64_t lane_value = 0;
        for (unsigned byte_index = 0; byte_index < 8u; ++byte_index) {
            lane_value |= (uint64_t)block[lane_index * 8u + byte_index] << (8u * byte_index);
        }
        context->state_lanes[lane_index] ^= lane_value;
    }
    r03_keccak_permute(context->state_lanes);
}

static void r03_keccak_initialize(struct r03_keccak_context *context,
    size_t rate_byte_count,
    uint8_t domain_byte)
{
    memset(context->state_lanes, 0, sizeof(context->state_lanes));
    context->rate_byte_count = rate_byte_count;
    context->domain_byte = domain_byte;
    context->buffered_byte_count = 0;
}

static void r03_keccak_update(struct r03_keccak_context *context,
    const uint8_t *input_bytes,
    size_t input_byte_count)
{
    size_t consumed_byte_count = 0;
    while (consumed_byte_count < input_byte_count) {
        size_t free_byte_count = context->rate_byte_count - context->buffered_byte_count;
        size_t take_byte_count = input_byte_count - consumed_byte_count;
        if (take_byte_count > free_byte_count) {
            take_byte_count = free_byte_count;
        }
        memcpy(context->buffer + context->buffered_byte_count,
            input_bytes + consumed_byte_count,
            take_byte_count);
        context->buffered_byte_count += take_byte_count;
        consumed_byte_count += take_byte_count;
        if (context->buffered_byte_count == context->rate_byte_count) {
            r03_keccak_absorb_block(context, context->buffer);
            context->buffered_byte_count = 0;
        }
    }
}

static void r03_keccak_pad(struct r03_keccak_context *context)
{
    memset(context->buffer + context->buffered_byte_count,
        0,
        context->rate_byte_count - context->buffered_byte_count);
    context->buffer[context->buffered_byte_count] = context->domain_byte;
    context->buffer[context->rate_byte_count - 1u] |= 0x80u;
    r03_keccak_absorb_block(context, context->buffer);
    context->buffered_byte_count = 0;
}

static void r03_keccak_squeeze(struct r03_keccak_context *context,
    uint8_t *output_bytes,
    size_t output_byte_count)
{
    size_t produced_byte_count = 0;
    while (produced_byte_count < output_byte_count) {
        size_t take_byte_count = output_byte_count - produced_byte_count;
        if (take_byte_count > context->rate_byte_count) {
            take_byte_count = context->rate_byte_count;
        }
        for (size_t byte_index = 0; byte_index < take_byte_count; ++byte_index) {
            size_t lane_index = byte_index / 8u;
            unsigned lane_byte_index = (unsigned)(byte_index % 8u);
            output_bytes[produced_byte_count + byte_index] =
                (uint8_t)(context->state_lanes[lane_index] >> (8u * lane_byte_index));
        }
        produced_byte_count += take_byte_count;
        if (produced_byte_count < output_byte_count) {
            r03_keccak_permute(context->state_lanes);
        }
    }
}

static void r03_sha3_256_digest(uint8_t digest_bytes[32],
    const uint8_t *input_bytes,
    size_t input_byte_count)
{
    struct r03_keccak_context context;
    r03_keccak_initialize(&context, 136u, 0x06u);
    r03_keccak_update(&context, input_bytes, input_byte_count);
    r03_keccak_pad(&context);
    r03_keccak_squeeze(&context, digest_bytes, 32u);
}

static void r03_shake256_digest(uint8_t *output_bytes,
    size_t output_byte_count,
    const uint8_t *input_bytes,
    size_t input_byte_count)
{
    struct r03_keccak_context context;
    r03_keccak_initialize(&context, 136u, 0x1fu);
    r03_keccak_update(&context, input_bytes, input_byte_count);
    r03_keccak_pad(&context);
    r03_keccak_squeeze(&context, output_bytes, output_byte_count);
}

/* 与两棵树 expand_test_seed 相同的域编码（tag || seed_le64 || index_le64），
 * 但用本文件自带的 SHAKE256，保证行序只由 seed 决定、与所链接的实现无关。 */
static void r03_expand_order_bytes(uint8_t *output_bytes,
    size_t output_byte_count,
    uint64_t test_seed,
    uint64_t order_index,
    uint8_t purpose_tag)
{
    uint8_t domain_input[17];
    domain_input[0] = purpose_tag;
    for (unsigned byte_index = 0; byte_index < 8u; ++byte_index) {
        domain_input[1u + byte_index] = (uint8_t)(test_seed >> (8u * byte_index));
        domain_input[9u + byte_index] = (uint8_t)(order_index >> (8u * byte_index));
    }
    r03_shake256_digest(output_bytes, output_byte_count, domain_input, sizeof(domain_input));
}

static int r03_digest_self_check(void)
{
    static const uint8_t empty_input[1] = {0};
    static const uint8_t abc_input[3] = {'a', 'b', 'c'};
    uint8_t digest_bytes[32];
    static const uint8_t expected_sha256_empty[32] = {0xe3u, 0xb0u, 0xc4u, 0x42u, 0x98u, 0xfcu,
        0x1cu, 0x14u, 0x9au, 0xfbu, 0xf4u, 0xc8u, 0x99u, 0x6fu, 0xb9u, 0x24u, 0x27u, 0xaeu, 0x41u,
        0xe4u, 0x64u, 0x9bu, 0x93u, 0x4cu, 0xa4u, 0x95u, 0x99u, 0x1bu, 0x78u, 0x52u, 0xb8u, 0x55u};
    static const uint8_t expected_sha256_abc[32] = {0xbau, 0x78u, 0x16u, 0xbfu, 0x8fu, 0x01u,
        0xcfu, 0xeau, 0x41u, 0x41u, 0x40u, 0xdeu, 0x5du, 0xaeu, 0x22u, 0x23u, 0xb0u, 0x03u, 0x61u,
        0xa3u, 0x96u, 0x17u, 0x7au, 0x9cu, 0xb4u, 0x10u, 0xffu, 0x61u, 0xf2u, 0x00u, 0x15u, 0xadu};
    static const uint8_t expected_sha3_empty[32] = {0xa7u, 0xffu, 0xc6u, 0xf8u, 0xbfu, 0x1eu,
        0xd7u, 0x66u, 0x51u, 0xc1u, 0x47u, 0x56u, 0xa0u, 0x61u, 0xd6u, 0x62u, 0xf5u, 0x80u, 0xffu,
        0x4du, 0xe4u, 0x3bu, 0x49u, 0xfau, 0x82u, 0xd8u, 0x0au, 0x4bu, 0x80u, 0xf8u, 0x43u, 0x4au};
    static const uint8_t expected_sha3_abc[32] = {0x3au, 0x98u, 0x5du, 0xa7u, 0x4fu, 0xe2u, 0x25u,
        0xb2u, 0x04u, 0x5cu, 0x17u, 0x2du, 0x6bu, 0xd3u, 0x90u, 0xbdu, 0x85u, 0x5fu, 0x08u, 0x6eu,
        0x3eu, 0x9du, 0x52u, 0x5bu, 0x46u, 0xbfu, 0xe2u, 0x45u, 0x11u, 0x43u, 0x15u, 0x32u};
    static const uint8_t expected_shake_empty[32] = {0x46u, 0xb9u, 0xddu, 0x2bu, 0x0bu, 0xa8u,
        0x8du, 0x13u, 0x23u, 0x3bu, 0x3fu, 0xebu, 0x74u, 0x3eu, 0xebu, 0x24u, 0x3fu, 0xcdu, 0x52u,
        0xeau, 0x62u, 0xb8u, 0x1bu, 0x82u, 0xb5u, 0x0cu, 0x27u, 0x64u, 0x6eu, 0xd5u, 0x76u, 0x2fu};
    r03_sha256_digest(digest_bytes, empty_input, 0u);
    if (memcmp(digest_bytes, expected_sha256_empty, 32u) != 0) {
        return 1;
    }
    r03_sha256_digest(digest_bytes, abc_input, 3u);
    if (memcmp(digest_bytes, expected_sha256_abc, 32u) != 0) {
        return 1;
    }
    r03_sha3_256_digest(digest_bytes, empty_input, 0u);
    if (memcmp(digest_bytes, expected_sha3_empty, 32u) != 0) {
        return 1;
    }
    r03_sha3_256_digest(digest_bytes, abc_input, 3u);
    if (memcmp(digest_bytes, expected_sha3_abc, 32u) != 0) {
        return 1;
    }
    r03_shake256_digest(digest_bytes, 32u, empty_input, 0u);
    if (memcmp(digest_bytes, expected_shake_empty, 32u) != 0) {
        return 1;
    }
    return 0;
}

/* ============================ 工具函数 ============================ */

static void r03_write_hex(FILE *output_stream, const uint8_t *bytes, size_t byte_count)
{
    for (size_t byte_index = 0; byte_index < byte_count; ++byte_index) {
        (void)fprintf(output_stream, "%02x", bytes[byte_index]);
    }
}

static void r03_print_hex(const uint8_t *bytes, size_t byte_count)
{
    r03_write_hex(stdout, bytes, byte_count);
}

static int r03_parse_unsigned(const char *text, uint64_t *value)
{
    char *end_position;
    unsigned long long parsed_value;
    if (text == NULL || *text == '\0') {
        return 1;
    }
    for (const char *character = text; *character != '\0'; ++character) {
        if (*character < '0' || *character > '9') {
            return 1;
        }
    }
    parsed_value = strtoull(text, &end_position, 10);
    if (*end_position != '\0') {
        return 1;
    }
    *value = (uint64_t)parsed_value;
    return 0;
}

static int r03_read_monotonic_nanoseconds(uint64_t *timestamp_nanoseconds)
{
    struct timespec timestamp;
    if (clock_gettime(CLOCK_MONOTONIC, &timestamp) != 0 || timestamp.tv_sec < 0 ||
        timestamp.tv_nsec < 0 || timestamp.tv_nsec >= 1000000000L) {
        return 1;
    }
    if ((uint64_t)timestamp.tv_sec >
        (UINT64_MAX - (uint64_t)timestamp.tv_nsec) / UINT64_C(1000000000)) {
        return 1;
    }
    *timestamp_nanoseconds =
        (uint64_t)timestamp.tv_sec * UINT64_C(1000000000) + (uint64_t)timestamp.tv_nsec;
    return 0;
}

static int r03_check_timer(uint64_t *resolution_nanoseconds)
{
    struct timespec clock_resolution;
    uint64_t previous_nanoseconds;
    uint64_t current_nanoseconds;
    int has_clock_progress = 0;
    if (clock_getres(CLOCK_MONOTONIC, &clock_resolution) != 0 || clock_resolution.tv_sec < 0 ||
        clock_resolution.tv_nsec < 0) {
        return 1;
    }
    *resolution_nanoseconds = (uint64_t)clock_resolution.tv_sec * UINT64_C(1000000000) +
        (uint64_t)clock_resolution.tv_nsec;
    if (*resolution_nanoseconds == 0 || r03_read_monotonic_nanoseconds(&previous_nanoseconds) != 0) {
        return 1;
    }
    for (unsigned check_index = 0; check_index < 10000u; ++check_index) {
        if (r03_read_monotonic_nanoseconds(&current_nanoseconds) != 0 ||
            current_nanoseconds < previous_nanoseconds) {
            return 1;
        }
        if (current_nanoseconds > previous_nanoseconds) {
            has_clock_progress = 1;
        }
        previous_nanoseconds = current_nanoseconds;
    }
    return has_clock_progress ? 0 : 1;
}

static void r03_read_cpu_model(char *cpu_model, size_t cpu_model_capacity_bytes)
{
    FILE *cpu_file;
    char information_line[256];
    (void)snprintf(cpu_model, cpu_model_capacity_bytes, "unavailable");
    cpu_file = fopen("/proc/cpuinfo", "r");
    if (cpu_file == NULL) {
        return;
    }
    while (fgets(information_line, sizeof(information_line), cpu_file) != NULL) {
        if (strncmp(information_line, "model name", 10) == 0) {
            const char *model_value = strchr(information_line, ':');
            if (model_value != NULL) {
                (void)snprintf(cpu_model, cpu_model_capacity_bytes, "%s", model_value + 1);
                cpu_model[strcspn(cpu_model, "\r\n")] = '\0';
            }
            break;
        }
    }
    (void)fclose(cpu_file);
}

static int r03_hash_file(const char *file_path,
    uint8_t sha256_digest[32],
    uint8_t sha3_256_digest[32])
{
    static uint8_t file_bytes[65536];
    struct r03_sha256_context sha256_context;
    struct r03_keccak_context keccak_context;
    FILE *input_file = fopen(file_path, "rb");
    size_t read_byte_count;
    if (input_file == NULL) {
        return 1;
    }
    r03_sha256_initialize(&sha256_context);
    r03_keccak_initialize(&keccak_context, 136u, 0x06u);
    while ((read_byte_count = fread(file_bytes, 1u, sizeof(file_bytes), input_file)) > 0u) {
        r03_sha256_update(&sha256_context, file_bytes, read_byte_count);
        r03_keccak_update(&keccak_context, file_bytes, read_byte_count);
    }
    if (ferror(input_file)) {
        (void)fclose(input_file);
        return 1;
    }
    if (fclose(input_file) != 0) {
        return 1;
    }
    r03_sha256_finalize(&sha256_context, sha256_digest);
    r03_keccak_pad(&keccak_context);
    r03_keccak_squeeze(&keccak_context, sha3_256_digest, 32u);
    return 0;
}

static int r03_hash_running_executable(uint8_t sha256_digest[32], uint8_t sha3_256_digest[32])
{
    char executable_path[4096];
#ifdef __APPLE__
    uint32_t executable_path_capacity_bytes = (uint32_t)sizeof(executable_path);
    if (_NSGetExecutablePath(executable_path, &executable_path_capacity_bytes) != 0) {
        return 1;
    }
#else
    ssize_t path_byte_count = readlink("/proc/self/exe", executable_path, sizeof(executable_path) - 1u);
    if (path_byte_count <= 0 || (size_t)path_byte_count >= sizeof(executable_path) - 1u) {
        return 1;
    }
    executable_path[path_byte_count] = '\0';
#endif
    return r03_hash_file(executable_path, sha256_digest, sha3_256_digest);
}

/* ============================ 弱声明的 derand 封装 ============================ */
/*
 * 两个符号都按弱声明引用：M1 两臂由 liboqs.a 提供 pqcrystals_* ，M5 参考臂由
 * libmlkem.a 提供 baseline_native_*；另一个在链接期保持未定义（弱引用不拉成员）。
 * 用它在资格期把 valid 类的解封装结果与封装侧共享密钥逐字节对齐。
 */
extern int baseline_native_enc_derand(uint8_t *ciphertext,
    uint8_t *shared_secret,
    const uint8_t *encapsulation_key,
    const uint8_t *coins) __attribute__((weak));
extern int pqcrystals_ml_kem_768_ipd_ref_enc_derand(uint8_t *ciphertext,
    uint8_t *shared_secret,
    const uint8_t *encapsulation_key,
    const uint8_t *coins) __attribute__((weak));

static int r03_derand_encapsulate(uint8_t *ciphertext,
    uint8_t *shared_secret,
    const uint8_t *encapsulation_key,
    const uint8_t *coins)
{
    if (baseline_native_enc_derand != NULL) {
        return baseline_native_enc_derand(ciphertext, shared_secret, encapsulation_key, coins);
    }
    if (pqcrystals_ml_kem_768_ipd_ref_enc_derand != NULL) {
        return pqcrystals_ml_kem_768_ipd_ref_enc_derand(ciphertext,
            shared_secret,
            encapsulation_key,
            coins);
    }
    return 1;
}

/* 与两棵树 generate_test_ciphertext(VALID, seed, 0, ek) 内部完全同一条路径：
 * 域编码 tag=2/index=0 展开 32 字节封装种子，再做确定性封装，因此得到的密文
 * 与 measure 的 valid 类首样本一致，共享密钥就是 valid 类应当解出的那一个。 */
static int r03_expected_valid_secret(uint64_t test_seed,
    const uint8_t *encapsulation_key,
    uint8_t *valid_ciphertext,
    uint8_t *expected_shared_secret)
{
    uint8_t encapsulation_seed[MLKEM_ENCAPSULATION_SEED_BYTES];
    int derand_status;
    expand_test_seed(encapsulation_seed,
        sizeof(encapsulation_seed),
        test_seed,
        0u,
        R03_ENUMERATION_SEED_PURPOSE_TAG);
    derand_status = r03_derand_encapsulate(valid_ciphertext,
        expected_shared_secret,
        encapsulation_key,
        encapsulation_seed);
    erase_secret_bytes(encapsulation_seed, sizeof(encapsulation_seed));
    return derand_status;
}

/* ============================ 三类固定输入 ============================ */

struct r03_class_input {
    uint8_t ciphertext[MLKEM_CIPHERTEXT_BYTES];
    size_t ciphertext_byte_count;
};

static void r03_build_class_inputs(const uint8_t *valid_ciphertext,
    struct r03_class_input class_inputs[R03_CLASS_COUNT])
{
    memset(&class_inputs[0], 0, sizeof(struct r03_class_input));
    memset(&class_inputs[1], 0, sizeof(struct r03_class_input));
    memset(&class_inputs[2], 0, sizeof(struct r03_class_input));
    memcpy(class_inputs[0].ciphertext, valid_ciphertext, MLKEM_CIPHERTEXT_BYTES);
    class_inputs[0].ciphertext_byte_count = MLKEM_CIPHERTEXT_BYTES;
    memcpy(class_inputs[1].ciphertext, valid_ciphertext, MLKEM_CIPHERTEXT_BYTES);
    /* ML-KEM-768 密文 = c1(u, 10 位×256 = 960 字节) || c2(v, 4 位×256 = 128 字节)。 */
    memset(class_inputs[1].ciphertext, 0xffu, 960u);
    memset(class_inputs[1].ciphertext + 960u, 0x00u, 128u);
    class_inputs[1].ciphertext_byte_count = MLKEM_CIPHERTEXT_BYTES;
    memcpy(class_inputs[2].ciphertext, valid_ciphertext, MLKEM_CIPHERTEXT_BYTES - 1u);
    class_inputs[2].ciphertext[MLKEM_CIPHERTEXT_BYTES - 1u] = 0x00u;
    class_inputs[2].ciphertext_byte_count = MLKEM_CIPHERTEXT_BYTES - 1u;
}

/* ============================ 命令行解析 ============================ */

struct r03_options {
    int describe_mode;
    int class_present[R03_CLASS_COUNT];
    uint64_t samples_per_class;
    uint64_t test_seed;
    uint64_t warmup_call_count;
    const char *raw_path;
    const char *metadata_path;
    const char *run_id;
    const char *public_key_path;
    const char *secret_key_path;
    int has_seed;
    int has_public_key;
    int has_secret_key;
};

static int r03_parse_class_list(const char *class_list, struct r03_options *options)
{
    const char *cursor = class_list;
    size_t parsed_class_count = 0;
    if (class_list == NULL || *class_list == '\0') {
        return 1;
    }
    while (*cursor != '\0') {
        const char *separator = strchr(cursor, ',');
        size_t token_byte_count = separator == NULL ? strlen(cursor) : (size_t)(separator - cursor);
        int matched_class_index = -1;
        if (token_byte_count == 0u) {
            return 1;
        }
        for (unsigned class_index = 0; class_index < R03_CLASS_COUNT; ++class_index) {
            if (strlen(r03_class_names[class_index]) == token_byte_count &&
                strncmp(cursor, r03_class_names[class_index], token_byte_count) == 0) {
                matched_class_index = (int)class_index;
            }
        }
        if (matched_class_index < 0 || options->class_present[matched_class_index] != 0) {
            return 1;
        }
        options->class_present[matched_class_index] = 1;
        ++parsed_class_count;
        if (separator == NULL) {
            break;
        }
        cursor = separator + 1;
    }
    return parsed_class_count == 0u ? 1 : 0;
}

static int r03_parse_arguments(int argument_count, char **argument_values, struct r03_options *options)
{
    int has_raw_path = 0;
    int has_metadata_path = 0;
    int has_run_id = 0;
    int has_class_list = 0;
    int has_samples = 0;
    int has_warmup = 0;
    int describe_mode = 0;
    memset(options, 0, sizeof(*options));
    options->test_seed = R03_DEFAULT_DESCRIBE_SEED;
    for (int argument_index = 1; argument_index < argument_count; ++argument_index) {
        const char *option_name = argument_values[argument_index];
        const char *option_value = NULL;
        int requires_value = strcmp(option_name, "--describe") != 0;
        if (requires_value) {
            if (argument_index + 1 >= argument_count) {
                return 1;
            }
            option_value = argument_values[++argument_index];
        }
        if (strcmp(option_name, "--describe") == 0) {
            if (describe_mode != 0) {
                return 1;
            }
            describe_mode = 1;
        } else if (strcmp(option_name, "--class") == 0) {
            if (has_class_list != 0 || r03_parse_class_list(option_value, options) != 0) {
                return 1;
            }
            has_class_list = 1;
        } else if (strcmp(option_name, "--samples") == 0) {
            if (has_samples != 0 ||
                r03_parse_unsigned(option_value, &options->samples_per_class) != 0 ||
                options->samples_per_class == 0 ||
                options->samples_per_class > R03_MAXIMUM_SAMPLES_PER_CLASS) {
                return 1;
            }
            has_samples = 1;
        } else if (strcmp(option_name, "--seed") == 0) {
            if (options->has_seed != 0 || r03_parse_unsigned(option_value, &options->test_seed) != 0) {
                return 1;
            }
            options->has_seed = 1;
        } else if (strcmp(option_name, "--warmup") == 0) {
            if (has_warmup != 0 ||
                r03_parse_unsigned(option_value, &options->warmup_call_count) != 0 ||
                options->warmup_call_count == 0 ||
                options->warmup_call_count > R03_MAXIMUM_WARMUP_CALLS) {
                return 1;
            }
            has_warmup = 1;
        } else if (strcmp(option_name, "--raw") == 0) {
            if (has_raw_path != 0 || *option_value == '\0') {
                return 1;
            }
            options->raw_path = option_value;
            has_raw_path = 1;
        } else if (strcmp(option_name, "--meta") == 0) {
            if (has_metadata_path != 0 || *option_value == '\0') {
                return 1;
            }
            options->metadata_path = option_value;
            has_metadata_path = 1;
        } else if (strcmp(option_name, "--run-id") == 0) {
            size_t run_id_byte_count = strlen(option_value);
            if (has_run_id != 0 || run_id_byte_count == 0u || run_id_byte_count > 64u) {
                return 1;
            }
            for (size_t byte_index = 0; byte_index < run_id_byte_count; ++byte_index) {
                char character = option_value[byte_index];
                if (!((character >= 'a' && character <= 'z') ||
                        (character >= 'A' && character <= 'Z') ||
                        (character >= '0' && character <= '9') || character == '_' ||
                        character == '-')) {
                    return 1;
                }
            }
            options->run_id = option_value;
            has_run_id = 1;
        } else if (strcmp(option_name, "--public-key") == 0) {
            if (options->has_public_key != 0 || *option_value == '\0') {
                return 1;
            }
            options->public_key_path = option_value;
            options->has_public_key = 1;
        } else if (strcmp(option_name, "--secret-key") == 0) {
            if (options->has_secret_key != 0 || *option_value == '\0') {
                return 1;
            }
            options->secret_key_path = option_value;
            options->has_secret_key = 1;
        } else {
            return 1;
        }
    }
    options->describe_mode = describe_mode;
    if (describe_mode != 0) {
        if (has_class_list != 0 || has_samples != 0 || has_warmup != 0 || has_raw_path != 0 ||
            has_metadata_path != 0 || has_run_id != 0) {
            return 1;
        }
        if (options->has_public_key != options->has_secret_key) {
            return 1;
        }
        return 0;
    }
    if (has_class_list == 0 || has_samples == 0 || has_warmup == 0 || has_raw_path == 0 ||
        has_metadata_path == 0 || has_run_id == 0 || options->has_seed == 0) {
        return 1;
    }
    if (options->has_public_key != options->has_secret_key) {
        return 1;
    }
    if (strcmp(options->raw_path, options->metadata_path) == 0) {
        return 1;
    }
    return 0;
}

static void r03_print_usage(void)
{
    (void)fputs("usage: " R03_TOOL_NAME " --describe [--seed N] [--public-key F --secret-key F]\n"
                "       " R03_TOOL_NAME
                " --class valid,malformed,truncated --samples N --seed N --warmup N\n"
                "           --raw NEW.csv --meta NEW.meta --run-id ID"
                " [--public-key F --secret-key F]\n"
                "  --samples 1..20000 per class; --warmup 1..10000; output files must not exist\n",
        stderr);
}

/* ============================ 密钥装载 ============================ */

static int r03_read_exact_file(const char *file_path, uint8_t *output_bytes, size_t expected_byte_count)
{
    FILE *input_file = fopen(file_path, "rb");
    int operation_status;
    if (input_file == NULL) {
        return 1;
    }
    operation_status = fread(output_bytes, 1u, expected_byte_count, input_file) ==
            expected_byte_count
        ? 0
        : 1;
    if (operation_status == 0 && (fgetc(input_file) != EOF || ferror(input_file))) {
        operation_status = 1;
    }
    if (fclose(input_file) != 0) {
        operation_status = 1;
    }
    return operation_status;
}

/* ============================ 资格期单次调用探针 ============================ */

struct r03_probe_result {
    int operation_status;
    int shared_secret_written;
    uint8_t shared_secret_digest[32];
};

static void r03_probe_one_call(const struct r03_class_input *class_input,
    const uint8_t *decapsulation_key,
    struct r03_probe_result *probe_result)
{
    uint8_t shared_secret[MLKEM_SHARED_SECRET_BYTES];
    memset(shared_secret, 0xa5u, sizeof(shared_secret));
    probe_result->operation_status = mlkem_decapsulate(shared_secret,
        sizeof(shared_secret),
        class_input->ciphertext,
        class_input->ciphertext_byte_count,
        decapsulation_key,
        MLKEM_DECAPSULATION_KEY_BYTES);
    probe_result->shared_secret_written = 0;
    for (size_t byte_index = 0; byte_index < sizeof(shared_secret); ++byte_index) {
        if (shared_secret[byte_index] != 0xa5u) {
            probe_result->shared_secret_written = 1;
        }
    }
    r03_sha3_256_digest(probe_result->shared_secret_digest, shared_secret, sizeof(shared_secret));
    erase_secret_bytes(shared_secret, sizeof(shared_secret));
}

/* ============================ 采集 ============================ */

struct r03_sample {
    size_t class_index;
    uint64_t elapsed_nanoseconds;
    int operation_status;
};

static volatile uint8_t r03_result_sink;

static uint64_t r03_draw_order_value(uint64_t test_seed, uint64_t *draw_index, uint64_t upper_bound)
{
    uint64_t rejection_threshold = (UINT64_C(0) - upper_bound) % upper_bound;
    uint64_t random_value;
    do {
        uint8_t random_bytes[8];
        uint64_t byte_index;
        r03_expand_order_bytes(random_bytes,
            sizeof(random_bytes),
            test_seed,
            (*draw_index)++,
            R03_ORDER_PURPOSE_TAG);
        random_value = 0;
        for (byte_index = 0; byte_index < 8u; ++byte_index) {
            random_value |= (uint64_t)random_bytes[byte_index] << (8u * byte_index);
        }
    } while (random_value < rejection_threshold);
    return random_value % upper_bound;
}

static size_t r03_present_class_count(const struct r03_options *options)
{
    size_t present_class_count = 0;
    for (unsigned class_index = 0; class_index < R03_CLASS_COUNT; ++class_index) {
        if (options->class_present[class_index] != 0) {
            ++present_class_count;
        }
    }
    return present_class_count;
}

static int r03_run_measurement(const struct r03_options *options)
{
    static const uint8_t truncated_sentinel = 0xa5u;
    uint8_t encapsulation_key[MLKEM_ENCAPSULATION_KEY_BYTES];
    uint8_t decapsulation_key[MLKEM_DECAPSULATION_KEY_BYTES];
    uint8_t valid_ciphertext[MLKEM_CIPHERTEXT_BYTES];
    uint8_t encapsulation_seed[MLKEM_ENCAPSULATION_SEED_BYTES];
    uint8_t expected_shared_secret[MLKEM_SHARED_SECRET_BYTES];
    uint8_t shared_secret[MLKEM_SHARED_SECRET_BYTES];
    uint8_t class_sha256_digest[R03_CLASS_COUNT][32];
    uint8_t class_sha3_256_digest[R03_CLASS_COUNT][32];
    uint8_t executable_sha256_digest[32];
    uint8_t executable_sha3_256_digest[32];
    uint8_t public_key_digest[32];
    uint8_t secret_key_digest[32];
    struct r03_class_input class_inputs[R03_CLASS_COUNT];
    struct r03_probe_result class_probes[R03_CLASS_COUNT];
    struct r03_sample *samples = NULL;
    struct utsname machine_information;
    char cpu_model[256];
    time_t wall_clock_seconds;
    uint64_t resolution_nanoseconds = 0;
    uint64_t warmup_start_nanoseconds = 0;
    uint64_t warmup_end_nanoseconds = 0;
    uint64_t observed_status_counts[R03_CLASS_COUNT][4];
    size_t present_class_count = r03_present_class_count(options);
    size_t sample_count = present_class_count * (size_t)options->samples_per_class;
    size_t warmup_calls_by_class[R03_CLASS_COUNT];
    size_t zero_elapsed_by_class[R03_CLASS_COUNT];
    int valid_roundtrip_state; /* 0 通过, 1 不可用, 2 失败 */
    int key_source_is_external = options->has_public_key != 0;
    int raw_created_by_tool = 0;
    int metadata_created_by_tool = 0;
    FILE *csv_file = NULL;
    FILE *metadata_file = NULL;
    int operation_status = 1;
    static const int expected_status_by_class[R03_CLASS_COUNT] = {0, 0, MLKEM_ERROR_ARGUMENT};

    memset(observed_status_counts, 0, sizeof(observed_status_counts));
    memset(warmup_calls_by_class, 0, sizeof(warmup_calls_by_class));
    memset(zero_elapsed_by_class, 0, sizeof(zero_elapsed_by_class));
    memset(class_sha256_digest, 0, sizeof(class_sha256_digest));
    memset(class_sha3_256_digest, 0, sizeof(class_sha3_256_digest));
    memset(public_key_digest, 0, sizeof(public_key_digest));
    memset(secret_key_digest, 0, sizeof(secret_key_digest));

    if (r03_check_timer(&resolution_nanoseconds) != 0) {
        (void)fputs("monotonic clock check failed\n", stderr);
        return 1;
    }
    if (r03_hash_running_executable(executable_sha256_digest, executable_sha3_256_digest) != 0) {
        (void)fputs("executable identity check failed\n", stderr);
        return 1;
    }
    if (key_source_is_external) {
        if (r03_read_exact_file(options->public_key_path,
                encapsulation_key,
                sizeof(encapsulation_key)) != 0 ||
            r03_read_exact_file(options->secret_key_path,
                decapsulation_key,
                sizeof(decapsulation_key)) != 0) {
            (void)fputs("external key file rejected: require 1184-byte public and 2400-byte secret\n",
                stderr);
            return 1;
        }
    } else if (generate_test_key_pair(options->test_seed, encapsulation_key, decapsulation_key) !=
        0) {
        (void)fputs("deterministic test key generation failed\n", stderr);
        return 1;
    }
    r03_sha3_256_digest(public_key_digest, encapsulation_key, sizeof(encapsulation_key));
    r03_sha3_256_digest(secret_key_digest, decapsulation_key, sizeof(decapsulation_key));

    if (generate_test_ciphertext(INPUT_VALID,
            options->test_seed,
            0u,
            encapsulation_key,
            valid_ciphertext) != 0) {
        (void)fputs("valid ciphertext generation failed\n", stderr);
        goto cleanup;
    }
    r03_build_class_inputs(valid_ciphertext, class_inputs);

    /* valid 类必须真是"同一密文、同一密钥"的成功解封装：用弱声明解析到的
     * derand 封装重算共享密钥并逐字节比对；符号不可用时如实记录 not_available。 */
    valid_roundtrip_state = 1;
    if (r03_expected_valid_secret(options->test_seed,
            encapsulation_key,
            valid_ciphertext,
            expected_shared_secret) == 0 &&
        memcmp(valid_ciphertext, class_inputs[0].ciphertext, MLKEM_CIPHERTEXT_BYTES) == 0) {
        int decapsulation_status = mlkem_decapsulate(shared_secret,
            sizeof(shared_secret),
            class_inputs[0].ciphertext,
            class_inputs[0].ciphertext_byte_count,
            decapsulation_key,
            sizeof(decapsulation_key));
        valid_roundtrip_state =
            decapsulation_status == 0 && memcmp(shared_secret, expected_shared_secret, 32u) == 0 ? 0
                                                                                                : 2;
        erase_secret_bytes(shared_secret, sizeof(shared_secret));
    }
    erase_secret_bytes(expected_shared_secret, sizeof(expected_shared_secret));
    erase_secret_bytes(encapsulation_seed, sizeof(encapsulation_seed));
    if (valid_roundtrip_state == 2) {
        (void)fputs("valid-class decapsulation does not match deterministic encapsulation\n", stderr);
        goto cleanup;
    }

    for (unsigned class_index = 0; class_index < R03_CLASS_COUNT; ++class_index) {
        r03_sha256_digest(class_sha256_digest[class_index],
            class_inputs[class_index].ciphertext,
            class_inputs[class_index].ciphertext_byte_count);
        r03_sha3_256_digest(class_sha3_256_digest[class_index],
            class_inputs[class_index].ciphertext,
            class_inputs[class_index].ciphertext_byte_count);
        r03_probe_one_call(&class_inputs[class_index], decapsulation_key,
            &class_probes[class_index]);
        if (class_probes[class_index].operation_status != expected_status_by_class[class_index]) {
            (void)fprintf(stderr,
                "class %s returned %d, expected %d; refusing to measure\n",
                r03_class_names[class_index],
                class_probes[class_index].operation_status,
                expected_status_by_class[class_index]);
            goto cleanup;
        }
        if (class_index == 2u && class_probes[class_index].shared_secret_written != 0) {
            (void)fputs("truncated class wrote a shared secret; length check is not first\n", stderr);
            goto cleanup;
        }
    }

    /* 行序只由 seed 与每类样本数决定：先在"三类齐全"的规范索引空间里做降序
     * Fisher–Yates，再按出现的类压缩；因此 --class 的书写顺序和取哪几类都不影响
     * 相对行序，子集运行就是全集运行的逐行子序列。 */
    {
        size_t full_sample_count = R03_CLASS_COUNT * (size_t)options->samples_per_class;
        size_t write_index = 0;
        uint64_t order_draw_index = 0;
        samples = calloc(full_sample_count, sizeof(*samples));
        if (samples == NULL) {
            (void)fputs("sample allocation failed\n", stderr);
            goto cleanup;
        }
        for (size_t sample_index = 0; sample_index < full_sample_count; ++sample_index) {
            samples[sample_index].class_index = sample_index % R03_CLASS_COUNT;
        }
        for (size_t remaining_count = full_sample_count; remaining_count > 1u; --remaining_count) {
            size_t selected_index =
                (size_t)r03_draw_order_value(options->test_seed, &order_draw_index, remaining_count);
            struct r03_sample selected_sample = samples[selected_index];
            samples[selected_index] = samples[remaining_count - 1u];
            samples[remaining_count - 1u] = selected_sample;
        }
        for (size_t sample_index = 0; sample_index < full_sample_count; ++sample_index) {
            if (options->class_present[samples[sample_index].class_index] != 0) {
                samples[write_index] = samples[sample_index];
                ++write_index;
            }
        }
        if (write_index != sample_count) {
            (void)fputs("sample plan compaction mismatch\n", stderr);
            goto cleanup;
        }
    }

    csv_file = fopen(options->raw_path, "wx");
    if (csv_file == NULL) {
        (void)fprintf(stderr, "refusing to overwrite raw path: %s\n", options->raw_path);
        goto cleanup;
    }
    raw_created_by_tool = 1;
    metadata_file = fopen(options->metadata_path, "wx");
    if (metadata_file == NULL) {
        (void)fprintf(stderr, "refusing to overwrite meta path: %s\n", options->metadata_path);
        (void)fclose(csv_file);
        csv_file = NULL;
        goto cleanup;
    }
    metadata_created_by_tool = 1;

    if (r03_read_monotonic_nanoseconds(&warmup_start_nanoseconds) != 0) {
        goto cleanup;
    }
    for (uint64_t warmup_index = 0; warmup_index < options->warmup_call_count; ++warmup_index) {
        size_t warmup_class_index = 0;
        size_t selection_index = (size_t)(warmup_index % (uint64_t)present_class_count) + 1u;
        for (unsigned class_index = 0; class_index < R03_CLASS_COUNT; ++class_index) {
            if (options->class_present[class_index] != 0) {
                --selection_index;
                if (selection_index == 0u) {
                    warmup_class_index = class_index;
                    break;
                }
            }
        }
        ++warmup_calls_by_class[warmup_class_index];
        if (mlkem_decapsulate(shared_secret,
                sizeof(shared_secret),
                class_inputs[warmup_class_index].ciphertext,
                class_inputs[warmup_class_index].ciphertext_byte_count,
                decapsulation_key,
                sizeof(decapsulation_key)) != expected_status_by_class[warmup_class_index]) {
            (void)fputs("warmup call returned an unexpected status\n", stderr);
            goto cleanup;
        }
        r03_result_sink ^= shared_secret[warmup_index % sizeof(shared_secret)];
    }
    if (r03_read_monotonic_nanoseconds(&warmup_end_nanoseconds) != 0) {
        goto cleanup;
    }

    for (size_t sample_index = 0; sample_index < sample_count; ++sample_index) {
        uint64_t start_nanoseconds;
        uint64_t end_nanoseconds;
        size_t class_index = samples[sample_index].class_index;
        const struct r03_class_input *class_input = &class_inputs[class_index];
        if (class_index == 2u) {
            /* 哨兵复位在窗口外；用来证明长度拒绝没有写共享密钥缓冲区。 */
            memset(shared_secret, truncated_sentinel, sizeof(shared_secret));
        }
        if (r03_read_monotonic_nanoseconds(&start_nanoseconds) != 0) {
            goto cleanup;
        }
        atomic_signal_fence(memory_order_seq_cst);
        samples[sample_index].operation_status = mlkem_decapsulate(shared_secret,
            sizeof(shared_secret),
            class_input->ciphertext,
            class_input->ciphertext_byte_count,
            decapsulation_key,
            sizeof(decapsulation_key));
        atomic_signal_fence(memory_order_seq_cst);
        if (r03_read_monotonic_nanoseconds(&end_nanoseconds) != 0 ||
            end_nanoseconds < start_nanoseconds) {
            goto cleanup;
        }
        samples[sample_index].elapsed_nanoseconds = end_nanoseconds - start_nanoseconds;
        /* 结果消费在窗口外；truncated 的哨兵值保持不变也在这里核对。 */
        if (samples[sample_index].operation_status == 0) {
            r03_result_sink ^= shared_secret[sample_index % sizeof(shared_secret)];
        } else if (class_index == 2u) {
            for (size_t byte_index = 0; byte_index < sizeof(shared_secret); ++byte_index) {
                if (shared_secret[byte_index] != truncated_sentinel) {
                    (void)fputs("truncated class wrote a shared secret during measurement\n", stderr);
                    goto cleanup;
                }
            }
        }
        if (samples[sample_index].elapsed_nanoseconds == 0) {
            ++zero_elapsed_by_class[class_index];
        }
        {
            unsigned status_bucket = 0;
            if (samples[sample_index].operation_status == 0) {
                status_bucket = 0;
            } else if (samples[sample_index].operation_status == MLKEM_ERROR_ARGUMENT) {
                status_bucket = 1;
            } else if (samples[sample_index].operation_status == -1) {
                status_bucket = 2;
            } else {
                status_bucket = 3;
            }
            ++observed_status_counts[class_index][status_bucket];
        }
    }

    /* 每类必须恰好 samples_per_class 行、且状态与预期一致，否则整轮作废。 */
    for (unsigned class_index = 0; class_index < R03_CLASS_COUNT; ++class_index) {
        uint64_t expected_row_count;
        if (options->class_present[class_index] == 0) {
            continue;
        }
        expected_row_count = options->samples_per_class;
        if (observed_status_counts[class_index][0] + observed_status_counts[class_index][1] +
                observed_status_counts[class_index][2] + observed_status_counts[class_index][3] !=
            expected_row_count) {
            (void)fputs("row count per class mismatch\n", stderr);
            goto cleanup;
        }
        if (class_index == 2u && observed_status_counts[2][1] != expected_row_count) {
            (void)fputs("truncated class did not stay on the length-rejection path\n", stderr);
            goto cleanup;
        }
        if (class_index != 2u && observed_status_counts[class_index][0] != expected_row_count) {
            (void)fputs("full-decapsulation class did not stay on the success path\n", stderr);
            goto cleanup;
        }
    }
    if (uname(&machine_information) != 0 ||
        (wall_clock_seconds = time(NULL)) == (time_t)-1) {
        goto cleanup;
    }
    r03_read_cpu_model(cpu_model, sizeof(cpu_model));

    if (fputs("run_id,implementation,input_category,sample_index,elapsed_nanoseconds,time_unit\n",
            csv_file) == EOF) {
        goto cleanup;
    }
    for (size_t sample_index = 0; sample_index < sample_count; ++sample_index) {
        if (fprintf(csv_file,
                "%s,%s,%s,%zu,%" PRIu64 ",ns\n",
                options->run_id,
                R03_ARM_NAME,
                r03_class_names[samples[sample_index].class_index],
                sample_index,
                samples[sample_index].elapsed_nanoseconds) < 0) {
            goto cleanup;
        }
    }

    if (fprintf(metadata_file,
            "run_id=%s\ntool=" R03_TOOL_NAME "\ntool_schema=" R03_TOOL_SCHEMA
            "\narm=" R03_ARM_NAME "\nlinked_implementation=" R03_LINKED_IMPLEMENTATION
            "\ntree_implementation_name=%s\nbuild_compiler=" __VERSION__
            "\nbuild_flags=" R03_BUILD_FLAGS "\nparameter_set=ML-KEM-768\nciphertext_bytes=%u\n"
            "test_seed=%" PRIu64 "\nclass_list=valid,malformed,truncated\n"
            "class_count_run=%zu\nsamples_per_class=%" PRIu64 "\nsample_count=%zu\n"
            "warmup_decapsulations=%" PRIu64 "\nwarmup_included_in_csv=no\n"
            "identical_input_per_class=yes\n"
            "input_repetition_rule=single_fixed_input_repeated_within_each_class\n"
            "row_order_rule=seed_only_over_canonical_full_class_space\n"
            "order_algorithm=descending_fisher_yates_sha3_256_purpose_tag_4\n"
            "clock=CLOCK_MONOTONIC\ntime_unit=ns\nclock_resolution_ns=%" PRIu64 "\n"
            "timer_monotonicity=passed\nwindow_scope=one_mlkem_decapsulate_call\n"
            "fences=atomic_signal_fence_seq_cst_both_sides\n"
            "result_consumption=outside_window\nwarmup_window=outside_timed_window\n"
            "warmup_elapsed_nanoseconds=%" PRIu64 "\n"
            "shared_secret_digest_rule=sha3_256_of_output_buffer_after_one_call_"
            "sentinel_0xa5_means_untouched\n",
            options->run_id,
            mlkem_implementation_name(),
            (unsigned)MLKEM_CIPHERTEXT_BYTES,
            options->test_seed,
            present_class_count,
            options->samples_per_class,
            sample_count,
            options->warmup_call_count,
            resolution_nanoseconds,
            warmup_end_nanoseconds - warmup_start_nanoseconds) < 0) {
        goto cleanup;
    }
    for (unsigned class_index = 0; class_index < R03_CLASS_COUNT; ++class_index) {
        if (options->class_present[class_index] == 0) {
            continue;
        }
        if (fprintf(metadata_file,
                "class_%s_construction=%s\nclass_%s_input_bytes=%zu\nclass_%s_path=%s\n"
                "class_%s_expected_status=%d\nclass_%s_observed_status=%d\n"
                "class_%s_shared_secret_written=%s\nclass_%s_shared_secret_sha3_256=",
                r03_class_names[class_index],
                r03_class_constructions[class_index],
                r03_class_names[class_index],
                class_inputs[class_index].ciphertext_byte_count,
                r03_class_names[class_index],
                r03_class_paths[class_index],
                r03_class_names[class_index],
                expected_status_by_class[class_index],
                r03_class_names[class_index],
                class_probes[class_index].operation_status,
                r03_class_names[class_index],
                class_probes[class_index].shared_secret_written != 0 ? "yes" : "no",
                r03_class_names[class_index]) < 0) {
            goto cleanup;
        }
        r03_write_hex(metadata_file, class_probes[class_index].shared_secret_digest, 32u);
        if (fprintf(metadata_file,
                "\nclass_%s_sha3_256=",
                r03_class_names[class_index]) < 0) {
            goto cleanup;
        }
        r03_write_hex(metadata_file, class_sha3_256_digest[class_index], 32u);
        if (fprintf(metadata_file, "\nclass_%s_sha256=", r03_class_names[class_index]) < 0) {
            goto cleanup;
        }
        r03_write_hex(metadata_file, class_sha256_digest[class_index], 32u);
        if (fprintf(metadata_file,
                "\nclass_%s_warmup_calls=%zu\nclass_%s_zero_elapsed_rows=%zu\n"
                "class_%s_status_zero_rows=%" PRIu64 "\nclass_%s_status_argument_rows=%" PRIu64
                "\nclass_%s_status_minus_one_rows=%" PRIu64 "\nclass_%s_status_other_rows=%" PRIu64
                "\n",
                r03_class_names[class_index],
                warmup_calls_by_class[class_index],
                r03_class_names[class_index],
                zero_elapsed_by_class[class_index],
                r03_class_names[class_index],
                observed_status_counts[class_index][0],
                r03_class_names[class_index],
                observed_status_counts[class_index][1],
                r03_class_names[class_index],
                observed_status_counts[class_index][2],
                r03_class_names[class_index],
                observed_status_counts[class_index][3]) < 0) {
            goto cleanup;
        }
    }
    if (fprintf(metadata_file,
            "valid_roundtrip_check=%s\n"
            "valid_roundtrip_check_rule=derand_encapsulation_secret_equals_decapsulation_secret\n"
            "derand_symbol_baseline_native_enc_derand=%s\n"
            "derand_symbol_pqcrystals_ml_kem_768_ipd_ref_enc_derand=%s\n"
            "key_source=%s\nkey_seed_domain=expand_test_seed_purpose_tag_2_index_0\n"
            "public_key_sha3_256=",
            valid_roundtrip_state == 0 ? "passed"
                                       : (valid_roundtrip_state == 1 ? "not_available" : "failed"),
            baseline_native_enc_derand != NULL ? "linked" : "absent",
            pqcrystals_ml_kem_768_ipd_ref_enc_derand != NULL ? "linked" : "absent",
            key_source_is_external ? "external_key_files" : "tree_deterministic_fixture_key") < 0) {
        goto cleanup;
    }
    r03_write_hex(metadata_file, public_key_digest, 32u);
    if (fputs("\nsecret_key_sha3_256=", metadata_file) == EOF) {
        goto cleanup;
    }
    r03_write_hex(metadata_file, secret_key_digest, 32u);
    if (fputs("\nexecutable_digest_algorithm=SHA-256,SHA3-256\nexecutable_sha256=", metadata_file) ==
        EOF) {
        goto cleanup;
    }
    r03_write_hex(metadata_file, executable_sha256_digest, 32u);
    if (fputs("\nexecutable_sha3_256=", metadata_file) == EOF) {
        goto cleanup;
    }
    r03_write_hex(metadata_file, executable_sha3_256_digest, 32u);
    if (fprintf(metadata_file,
            "\ncpu_affinity=set_externally_by_taskset\nfrequency_control=not_configured_by_program\n"
            "virtualization=not_verified_by_program_see_environment_log\n"
            "wall_clock_unix_seconds=%jd\nos=%s %s\narchitecture=%s\ncpu_model=%s\n"
            "result_sink=%u\nrun_status=%s\n",
            (intmax_t)wall_clock_seconds,
            machine_information.sysname,
            machine_information.release,
            machine_information.machine,
            cpu_model,
            (unsigned)r03_result_sink,
            "complete") < 0) {
        goto cleanup;
    }
    operation_status = 0;

cleanup:
    if (csv_file != NULL && fclose(csv_file) != 0) {
        operation_status = 1;
    }
    if (metadata_file != NULL && fclose(metadata_file) != 0) {
        operation_status = 1;
    }
    if (operation_status != 0) {
        /* 失败不留半成品：只删本程序自己用 "wx" 建出来的文件，
         * 预先存在的路径一律原样保留。 */
        if (raw_created_by_tool != 0 && options->raw_path != NULL) {
            (void)remove(options->raw_path);
        }
        if (metadata_created_by_tool != 0 && options->metadata_path != NULL) {
            (void)remove(options->metadata_path);
        }
        (void)fputs("measurement failed; no output kept; use new output paths\n", stderr);
    }
    erase_secret_bytes(decapsulation_key, sizeof(decapsulation_key));
    erase_secret_bytes(shared_secret, sizeof(shared_secret));
    erase_secret_bytes(valid_ciphertext, sizeof(valid_ciphertext));
    free(samples);
    return operation_status;
}

/* ============================ --describe ============================ */

static int r03_describe(const struct r03_options *options)
{
    uint8_t encapsulation_key[MLKEM_ENCAPSULATION_KEY_BYTES];
    uint8_t decapsulation_key[MLKEM_DECAPSULATION_KEY_BYTES];
    uint8_t valid_ciphertext[MLKEM_CIPHERTEXT_BYTES];
    uint8_t encapsulation_seed[MLKEM_ENCAPSULATION_SEED_BYTES];
    uint8_t expected_shared_secret[MLKEM_SHARED_SECRET_BYTES];
    uint8_t shared_secret[MLKEM_SHARED_SECRET_BYTES];
    struct r03_class_input class_inputs[R03_CLASS_COUNT];
    struct r03_probe_result class_probes[R03_CLASS_COUNT];
    uint8_t executable_sha256_digest[32];
    uint8_t executable_sha3_256_digest[32];
    int valid_roundtrip_state = 1;
    int key_source_is_external = options->has_public_key != 0;

    if (r03_digest_self_check() != 0) {
        (void)fputs("digest self-check failed\n", stderr);
        return 1;
    }
    if (key_source_is_external) {
        if (r03_read_exact_file(options->public_key_path, encapsulation_key,
                sizeof(encapsulation_key)) != 0 ||
            r03_read_exact_file(options->secret_key_path, decapsulation_key,
                sizeof(decapsulation_key)) != 0) {
            (void)fputs("external key file rejected\n", stderr);
            return 1;
        }
    } else if (generate_test_key_pair(options->test_seed, encapsulation_key, decapsulation_key) !=
        0) {
        (void)fputs("deterministic test key generation failed\n", stderr);
        return 1;
    }
    if (generate_test_ciphertext(INPUT_VALID, options->test_seed, 0u, encapsulation_key,
            valid_ciphertext) != 0) {
        (void)fputs("valid ciphertext generation failed\n", stderr);
        return 1;
    }
    r03_build_class_inputs(valid_ciphertext, class_inputs);
    for (unsigned class_index = 0; class_index < R03_CLASS_COUNT; ++class_index) {
        r03_probe_one_call(&class_inputs[class_index], decapsulation_key,
            &class_probes[class_index]);
    }
    if (r03_expected_valid_secret(options->test_seed,
            encapsulation_key,
            valid_ciphertext,
            expected_shared_secret) == 0) {
        int decapsulation_status = mlkem_decapsulate(shared_secret,
            sizeof(shared_secret),
            class_inputs[0].ciphertext,
            class_inputs[0].ciphertext_byte_count,
            decapsulation_key,
            sizeof(decapsulation_key));
        valid_roundtrip_state =
            decapsulation_status == 0 && memcmp(shared_secret, expected_shared_secret, 32u) == 0 ? 0
                                                                                                : 2;
        erase_secret_bytes(shared_secret, sizeof(shared_secret));
    }
    erase_secret_bytes(expected_shared_secret, sizeof(expected_shared_secret));
    erase_secret_bytes(encapsulation_seed, sizeof(encapsulation_seed));
    if (r03_hash_running_executable(executable_sha256_digest, executable_sha3_256_digest) != 0) {
        memset(executable_sha256_digest, 0, sizeof(executable_sha256_digest));
        memset(executable_sha3_256_digest, 0, sizeof(executable_sha3_256_digest));
    }

    (void)printf("tool=" R03_TOOL_NAME "\ntool_schema=" R03_TOOL_SCHEMA
                 "\narm=" R03_ARM_NAME "\nlinked_implementation=" R03_LINKED_IMPLEMENTATION
                 "\ntree_implementation_name=%s\nbuild_compiler=" __VERSION__
                 "\nbuild_flags=" R03_BUILD_FLAGS "\ndescribe_seed=%" PRIu64
                 "\nkey_source=%s\nparameter_set=ML-KEM-768\nciphertext_bytes=%u\n"
                 "shared_secret_bytes=%u\nclass_count=%u\n"
                 "csv_header=run_id,implementation,input_category,sample_index,"
                 "elapsed_nanoseconds,time_unit\ntime_unit=ns\nclock=CLOCK_MONOTONIC\n"
                 "window_scope=one_mlkem_decapsulate_call\n"
                 "fences=atomic_signal_fence_seq_cst_both_sides\n"
                 "warmup_window=outside_timed_window\nidentical_input_per_class=yes\n"
                 "row_order_rule=seed_only_over_canonical_full_class_space\n"
                 "digest_selfcheck=passed\nvalid_roundtrip_check=%s\n"
                 "derand_symbol_baseline_native_enc_derand=%s\n"
                 "derand_symbol_pqcrystals_ml_kem_768_ipd_ref_enc_derand=%s\n"
                 "executable_sha256=",
        mlkem_implementation_name(),
        options->test_seed,
        key_source_is_external ? "external_key_files" : "tree_deterministic_fixture_key",
        (unsigned)MLKEM_CIPHERTEXT_BYTES,
        (unsigned)MLKEM_SHARED_SECRET_BYTES,
        (unsigned)R03_CLASS_COUNT,
        valid_roundtrip_state == 0 ? "passed"
                                   : (valid_roundtrip_state == 1 ? "not_available" : "failed"),
        baseline_native_enc_derand != NULL ? "linked" : "absent",
        pqcrystals_ml_kem_768_ipd_ref_enc_derand != NULL ? "linked" : "absent");
    r03_print_hex(executable_sha256_digest, 32u);
    (void)printf("\nexecutable_sha3_256=");
    r03_print_hex(executable_sha3_256_digest, 32u);
    (void)printf("\n");
    for (unsigned class_index = 0; class_index < R03_CLASS_COUNT; ++class_index) {
        uint8_t sha256_digest[32];
        uint8_t sha3_256_digest[32];
        r03_sha256_digest(sha256_digest,
            class_inputs[class_index].ciphertext,
            class_inputs[class_index].ciphertext_byte_count);
        r03_sha3_256_digest(sha3_256_digest,
            class_inputs[class_index].ciphertext,
            class_inputs[class_index].ciphertext_byte_count);
        (void)printf("class_%u_name=%s\nclass_%u_construction=%s\nclass_%u_input_bytes=%zu\n"
                     "class_%u_path=%s\nclass_%u_expected_status=%d\n"
                     "class_%u_observed_status=%d\nclass_%u_shared_secret_written=%s\n"
                     "class_%u_shared_secret_sha3_256=",
            class_index,
            r03_class_names[class_index],
            class_index,
            r03_class_constructions[class_index],
            class_index,
            class_inputs[class_index].ciphertext_byte_count,
            class_index,
            r03_class_paths[class_index],
            class_index,
            class_index == 2u ? MLKEM_ERROR_ARGUMENT : 0,
            class_index,
            class_probes[class_index].operation_status,
            class_index,
            class_probes[class_index].shared_secret_written != 0 ? "yes" : "no",
            class_index);
        r03_print_hex(class_probes[class_index].shared_secret_digest, 32u);
        (void)printf("\nclass_%u_sha3_256=", class_index);
        r03_print_hex(sha3_256_digest, 32u);
        (void)printf("\nclass_%u_sha256=", class_index);
        r03_print_hex(sha256_digest, 32u);
        (void)printf("\n");
    }
    (void)printf("valid_equals_malformed_secret=%s\n"
                 "malformed_implicit_rejection_observed=%s\n"
                 "truncated_shared_secret_untouched=%s\n"
                 "length_rejection_layer=mlkem_decapsulate_wrapper_argument_check\n"
                 "no_fork=yes\nno_daemonize=yes\nno_setsid=yes\nno_affinity_write=yes\n"
                 "no_frequency_write=yes\noutput_open_mode=wx\nno_temporary_files=yes\n",
        memcmp(class_probes[0].shared_secret_digest, class_probes[1].shared_secret_digest, 32u) == 0
            ? "yes"
            : "no",
        class_probes[1].operation_status == 0 &&
                memcmp(class_probes[0].shared_secret_digest,
                    class_probes[1].shared_secret_digest,
                    32u) != 0
            ? "yes"
            : "no",
        class_probes[2].shared_secret_written == 0 ? "yes" : "no");
    erase_secret_bytes(decapsulation_key, sizeof(decapsulation_key));
    erase_secret_bytes(shared_secret, sizeof(shared_secret));
    erase_secret_bytes(valid_ciphertext, sizeof(valid_ciphertext));
    return valid_roundtrip_state == 2 ? 1 : 0;
}

int main(int argument_count, char **argument_values)
{
    struct r03_options options;
    if (r03_parse_arguments(argument_count, argument_values, &options) != 0) {
        r03_print_usage();
        return 2;
    }
    if (options.describe_mode != 0) {
        return r03_describe(&options);
    }
    return r03_run_measurement(&options);
}
