/*
 * R06 专项审计用最小"可观察面"探针（新增件，不属于正式采集件）。
 *
 * 目的：对同一实现、同一密钥对，分别用"合法密文"与"隐式拒绝密文"各驱动
 * 一次完整解封装调用链，逐次记录进程返回码与 stdout/stderr 逐字节内容，
 * 用于判断进程可观察面是否携带"验证是否通过"这一内部结果或秘密。
 *
 * 约束：
 *  - 只调用公开入口 mlkem_decapsulate / generate_test_key_pair / generate_test_ciphertext；
 *  - 不打印共享密钥、私钥、验证位或内部消息 m'；
 *  - 结果只累加到 volatile sink（防优化），不参与输出；
 *  - 输出语句不含任何与 category 相关的分支文本，使合法/拒绝两条路径的
 *    可观察面在源码层面完全对称，从而让差异（若有）只能来自实现本身。
 */

#define _POSIX_C_SOURCE 200809L

#include "inputs.h"
#include "mlkem.h"

#include <errno.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

/* 与 M2 采集件同口径的对照类：message-zero 密文的末 32 字节改写为常量。 */
#define PROBE_MALFORMED_TAIL_BYTES 32u

static volatile uint8_t probe_result_sink;

static int probe_parse_mode(const char *text, enum input_category *category, int *is_malformed)
{
    if (strcmp(text, "malformed-zero-tail") == 0) {
        *category = INPUT_MESSAGE_ZERO;
        *is_malformed = 1;
        return 0;
    }
    if (strcmp(text, "malformed-ff-tail") == 0) {
        *category = INPUT_MESSAGE_ZERO;
        *is_malformed = 1;
        return 0;
    }
    *is_malformed = 0;
    return parse_input_category(text, category);
}

static int parse_iteration_count(const char *text, uint64_t *value)
{
    char *end = NULL;
    errno = 0;
    unsigned long long parsed = strtoull(text, &end, 10);
    if (errno != 0 || end == text || *end != '\0' || parsed == 0 || parsed > 1000000ull) {
        return 1;
    }
    *value = (uint64_t)parsed;
    return 0;
}

int main(int argument_count, char **argument_values)
{
    uint64_t test_seed;
    uint64_t iteration_count;
    uint8_t encapsulation_key[MLKEM_ENCAPSULATION_KEY_BYTES];
    uint8_t decapsulation_key[MLKEM_DECAPSULATION_KEY_BYTES];
    uint8_t ciphertext[MLKEM_CIPHERTEXT_BYTES];
    uint8_t shared_secret[MLKEM_SHARED_SECRET_BYTES];
    enum input_category category;
    int is_malformed = 0;
    uint8_t malformed_tail_byte = 0u;
    uint64_t nonzero_result_count = 0;
    uint64_t completed_count = 0;

    if (argument_count != 4) {
        fputs("usage: r06_observable_probe MODE ITERATIONS SEED\n", stderr);
        return 2;
    }
    if (probe_parse_mode(argument_values[1], &category, &is_malformed) != 0) {
        fputs("invalid mode\n", stderr);
        return 2;
    }
    if (is_malformed) {
        malformed_tail_byte = strcmp(argument_values[1], "malformed-ff-tail") == 0 ? 0xFFu : 0x00u;
    }
    if (parse_iteration_count(argument_values[2], &iteration_count) != 0 ||
        parse_unsigned_integer(argument_values[3], &test_seed) != 0) {
        fputs("invalid numeric argument\n", stderr);
        return 2;
    }
    /* 只允许固定长度公开测试向量；短缓冲区不得进入固定长度内核。 */
    if (generate_test_key_pair(test_seed, encapsulation_key, decapsulation_key) != 0) {
        fputs("key pair generation failed\n", stderr);
        return 1;
    }
    for (uint64_t iteration_index = 0; iteration_index < iteration_count; ++iteration_index) {
        int operation_status;
        if (generate_test_ciphertext(category,
                test_seed,
                iteration_index,
                encapsulation_key,
                ciphertext) != 0) {
            fputs("ciphertext generation failed\n", stderr);
            return 1;
        }
        if (is_malformed) {
            memset(ciphertext + sizeof(ciphertext) - PROBE_MALFORMED_TAIL_BYTES,
                malformed_tail_byte,
                PROBE_MALFORMED_TAIL_BYTES);
        }
        operation_status = mlkem_decapsulate(shared_secret,
            sizeof(shared_secret),
            ciphertext,
            sizeof(ciphertext),
            decapsulation_key,
            sizeof(decapsulation_key));
        if (operation_status != 0) {
            /* 包装层参数/随机源错误才走这里；密文重加密比较结果不体现在返回码。 */
            ++nonzero_result_count;
        }
        probe_result_sink ^= shared_secret[iteration_index % sizeof(shared_secret)];
        ++completed_count;
    }
    erase_secret_bytes(decapsulation_key, sizeof(decapsulation_key));
    erase_secret_bytes(shared_secret, sizeof(shared_secret));
    if (nonzero_result_count != 0) {
        fputs("decapsulation call failed\n", stderr);
        return 1;
    }
    printf("calls_completed=%llu\n", (unsigned long long)completed_count);
    return 0;
}
