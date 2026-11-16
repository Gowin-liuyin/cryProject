/* T2.3 额外等价驱动：500 个固定公式消息的封装/解封装 + 500 个逐字节篡改的隐式拒绝。
 * 只使用公开固定测试种子与确定性消息（无 OS 随机源），不作计时；
 * 两臂各跑同一驱动、逐行输出共享密钥十六进制，由外层 diff 比较（要求全空）。
 * 用法：equiv_driver（无参数；stdout 为 transcript，失败时 stderr 报错并退出 1）。 */

#include "inputs.h"
#include "platform_m2.h"

#include "fips202.h"

#include <stddef.h>
#include <stdint.h>
#include <stdio.h>
#include <string.h>

#define EQUIV_TEST_SEED UINT64_C(20261016)
#define RANDOM_CASE_COUNT 500u
#define TAMPERED_CASE_COUNT 500u

/* 与 tests/test_platform_m2.c 相同的隐式拒绝密钥口径：z || H(ct) 再 SHAKE256。 */
static void rejection_secret(uint8_t output[MLKEM_SHARED_SECRET_BYTES],
    const uint8_t ciphertext[MLKEM_CIPHERTEXT_BYTES],
    const uint8_t decapsulation_key[MLKEM_DECAPSULATION_KEY_BYTES])
{
    uint8_t rejection_material[2U * MLKEM_SHARED_SECRET_BYTES];
    memcpy(rejection_material,
        decapsulation_key + MLKEM_DECAPSULATION_KEY_BYTES - MLKEM_SHARED_SECRET_BYTES,
        MLKEM_SHARED_SECRET_BYTES);
    sha3_256(rejection_material + MLKEM_SHARED_SECRET_BYTES, ciphertext, MLKEM_CIPHERTEXT_BYTES);
    shake256(output, MLKEM_SHARED_SECRET_BYTES, rejection_material, sizeof(rejection_material));
    erase_secret_bytes(rejection_material, sizeof(rejection_material));
}

static void fill_deterministic_message(uint8_t message[MLKEM_SHARED_SECRET_BYTES],
    unsigned case_index)
{
    for (size_t byte_index = 0u; byte_index < MLKEM_SHARED_SECRET_BYTES; ++byte_index) {
        message[byte_index] =
            (uint8_t)((case_index * 131u + (unsigned)byte_index * 17u + 7u) & 0xffu);
    }
}

static void print_case_secret(const char *case_kind, unsigned case_index,
    const uint8_t secret[MLKEM_SHARED_SECRET_BYTES])
{
    printf("%s_%u=", case_kind, case_index);
    for (size_t byte_index = 0u; byte_index < MLKEM_SHARED_SECRET_BYTES; ++byte_index) {
        printf("%02x", secret[byte_index]);
    }
    putchar('\n');
}

int main(void)
{
    uint8_t encapsulation_key[MLKEM_ENCAPSULATION_KEY_BYTES];
    uint8_t decapsulation_key[MLKEM_DECAPSULATION_KEY_BYTES];
    uint8_t ciphertext[MLKEM_CIPHERTEXT_BYTES];
    uint8_t tampered_ciphertext[MLKEM_CIPHERTEXT_BYTES];
    uint8_t message[MLKEM_SHARED_SECRET_BYTES];
    uint8_t expected_secret[MLKEM_SHARED_SECRET_BYTES];
    uint8_t decapsulated_secret[MLKEM_SHARED_SECRET_BYTES];
    uint8_t expected_rejection[MLKEM_SHARED_SECRET_BYTES];
    unsigned random_roundtrip_count = 0u;
    unsigned implicit_rejection_count = 0u;

    if (generate_test_key_pair(EQUIV_TEST_SEED, encapsulation_key, decapsulation_key) != 0) {
        fprintf(stderr, "deterministic keypair failed\n");
        return 1;
    }
    for (unsigned case_index = 0u; case_index < RANDOM_CASE_COUNT; ++case_index) {
        fill_deterministic_message(message, case_index);
        if (platform_m2_test_message(ciphertext, expected_secret, encapsulation_key, message) !=
            0) {
            fprintf(stderr, "test message construction failed at case %u\n", case_index);
            return 1;
        }
        if (mlkem_decapsulate(decapsulated_secret,
                sizeof(decapsulated_secret),
                ciphertext,
                sizeof(ciphertext),
                decapsulation_key,
                sizeof(decapsulation_key)) != 0) {
            fprintf(stderr, "decapsulation failed at random case %u\n", case_index);
            return 1;
        }
        if (memcmp(decapsulated_secret, expected_secret, sizeof(expected_secret)) != 0) {
            fprintf(stderr, "roundtrip mismatch at random case %u\n", case_index);
            return 1;
        }
        print_case_secret("random_shared_secret", case_index, decapsulated_secret);
        ++random_roundtrip_count;
    }
    for (unsigned case_index = 0u; case_index < TAMPERED_CASE_COUNT; ++case_index) {
        fill_deterministic_message(message, case_index);
        if (platform_m2_test_message(ciphertext, expected_secret, encapsulation_key, message) !=
            0) {
            fprintf(stderr, "test message construction failed at tampered case %u\n", case_index);
            return 1;
        }
        memcpy(tampered_ciphertext, ciphertext, sizeof(tampered_ciphertext));
        tampered_ciphertext[case_index % MLKEM_CIPHERTEXT_BYTES] ^= 1u;
        if (mlkem_decapsulate(decapsulated_secret,
                sizeof(decapsulated_secret),
                tampered_ciphertext,
                sizeof(tampered_ciphertext),
                decapsulation_key,
                sizeof(decapsulation_key)) != 0) {
            fprintf(stderr, "decapsulation errored at tampered case %u\n", case_index);
            return 1;
        }
        rejection_secret(expected_rejection, tampered_ciphertext, decapsulation_key);
        if (memcmp(decapsulated_secret, expected_rejection, sizeof(expected_rejection)) != 0) {
            fprintf(stderr, "implicit rejection mismatch at tampered case %u\n", case_index);
            return 1;
        }
        if (memcmp(decapsulated_secret, expected_secret, sizeof(expected_secret)) == 0) {
            fprintf(stderr, "tampered ciphertext accepted at case %u\n", case_index);
            return 1;
        }
        print_case_secret("tampered_rejection_secret", case_index, decapsulated_secret);
        ++implicit_rejection_count;
    }
    printf("SUMMARY random_cases=%u random_roundtrips=%u tampered_cases=%u "
           "implicit_rejections=%u\n",
        RANDOM_CASE_COUNT,
        random_roundtrip_count,
        TAMPERED_CASE_COUNT,
        implicit_rejection_count);
    erase_secret_bytes(decapsulation_key, sizeof(decapsulation_key));
    erase_secret_bytes(message, sizeof(message));
    erase_secret_bytes(expected_secret, sizeof(expected_secret));
    erase_secret_bytes(decapsulated_secret, sizeof(decapsulated_secret));
    erase_secret_bytes(expected_rejection, sizeof(expected_rejection));
    return 0;
}
