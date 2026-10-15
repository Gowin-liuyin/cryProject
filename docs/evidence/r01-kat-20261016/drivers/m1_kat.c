/*
 * M1 公开 KAT 检查驱动：liboqs 0.10.0 ML-KEM-768-ipd 历史构建（未修 / 982c762 已修）。
 *
 * 期望值全部来自仓库固定文件 tests/vectors/mlkem768.txt（ACVP FIPS203 转换件），
 * 本程序不生成、不修改任何预期答案。keygen/encap 使用 liboqs 0.10.0 树内
 * ml-kem-768-ipd_ref 的 derand 入口（与 src/inputs_liboqs010.c 相同的公开符号），
 * decap 走实现自身的 mlkem_decapsulate。
 *
 * 只打印计数与布尔；不打印任何密钥、共享密钥或内部验证结果。
 */

#include "mlkem.h"

#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

/* liboqs 0.10.0 内部 SHA3 符号（src/common/sha3/sha3.h 的公开原型）。 */
extern void OQS_SHA3_shake256(uint8_t *output, size_t outlen, const uint8_t *input, size_t inplen);

extern int pqcrystals_ml_kem_768_ipd_ref_keypair_derand(uint8_t *public_key,
    uint8_t *secret_key,
    const uint8_t *coins);
extern int pqcrystals_ml_kem_768_ipd_ref_enc_derand(uint8_t *ciphertext,
    uint8_t *shared_secret,
    const uint8_t *public_key,
    const uint8_t *coins);

#ifndef RR_IMPL_NAME
#define RR_IMPL_NAME "unknown"
#endif

static int read_hex_field(FILE *vector_file, uint8_t *output, size_t output_byte_count)
{
    char encoded[MLKEM_DECAPSULATION_KEY_BYTES * 2u + 1u];
    if (fscanf(vector_file, "%4800s", encoded) != 1) {
        return 1;
    }
    if (strlen(encoded) != output_byte_count * 2u) {
        return 1;
    }
    for (size_t byte_index = 0; byte_index < output_byte_count; ++byte_index) {
        unsigned decoded_byte = 0u;
        if (sscanf(encoded + byte_index * 2u, "%2x", &decoded_byte) != 1) {
            return 1;
        }
        output[byte_index] = (uint8_t)decoded_byte;
    }
    return 0;
}

int main(int argument_count, char **argument_values)
{
    if (argument_count != 2) {
        fputs("usage: m1_kat <mlkem768.txt>\n", stderr);
        return 2;
    }
    FILE *vector_file = fopen(argument_values[1], "r");
    if (vector_file == NULL) {
        fputs("cannot open vector file\n", stderr);
        return 2;
    }

    uint8_t key_seed[MLKEM_KEY_SEED_BYTES];
    uint8_t encapsulation_key[MLKEM_ENCAPSULATION_KEY_BYTES];
    uint8_t decapsulation_key[MLKEM_DECAPSULATION_KEY_BYTES];
    uint8_t ciphertext[MLKEM_CIPHERTEXT_BYTES];
    uint8_t shared_secret[MLKEM_SHARED_SECRET_BYTES];
    uint8_t expected_encapsulation_key[MLKEM_ENCAPSULATION_KEY_BYTES];
    uint8_t expected_decapsulation_key[MLKEM_DECAPSULATION_KEY_BYTES];
    uint8_t expected_ciphertext[MLKEM_CIPHERTEXT_BYTES];
    uint8_t expected_shared_secret[MLKEM_SHARED_SECRET_BYTES];
    uint8_t rejection_input[MLKEM_SHARED_SECRET_BYTES + MLKEM_CIPHERTEXT_BYTES];
    uint8_t rejection_secret[MLKEM_SHARED_SECRET_BYTES];

    unsigned keygen_cases = 0u;
    unsigned keygen_passed = 0u;
    unsigned encap_cases = 0u;
    unsigned encap_passed = 0u;
    unsigned decap_cases = 0u;
    unsigned decap_passed = 0u;
    unsigned decap_rejections = 0u;
    unsigned keycheck_cases = 0u;

    char operation_name[16];
    char case_number_text[21];
    while (fscanf(vector_file, "%15s %20s", operation_name, case_number_text) == 2) {
        if (strcmp(operation_name, "keygen") == 0) {
            unsigned long long case_number = strtoull(case_number_text, NULL, 10);
            if (case_number == 0ull || read_hex_field(vector_file, key_seed, sizeof(key_seed)) != 0 ||
                read_hex_field(vector_file,
                    expected_encapsulation_key,
                    sizeof(expected_encapsulation_key)) != 0 ||
                read_hex_field(vector_file, expected_decapsulation_key, sizeof(expected_decapsulation_key)) !=
                    0) {
                fputs("malformed keygen case\n", stderr);
                return 1;
            }
            if (pqcrystals_ml_kem_768_ipd_ref_keypair_derand(encapsulation_key,
                    decapsulation_key,
                    key_seed) != 0) {
                fputs("keypair_derand failed\n", stderr);
                return 1;
            }
            ++keygen_cases;
            if (memcmp(encapsulation_key, expected_encapsulation_key, sizeof(encapsulation_key)) == 0 &&
                memcmp(decapsulation_key, expected_decapsulation_key, sizeof(decapsulation_key)) == 0) {
                ++keygen_passed;
            }
        } else if (strcmp(operation_name, "encap") == 0) {
            unsigned long long case_number = strtoull(case_number_text, NULL, 10);
            if (case_number == 0ull ||
                read_hex_field(vector_file, encapsulation_key, sizeof(encapsulation_key)) != 0 ||
                read_hex_field(vector_file, key_seed, MLKEM_ENCAPSULATION_SEED_BYTES) != 0 ||
                read_hex_field(vector_file, expected_ciphertext, sizeof(expected_ciphertext)) != 0 ||
                read_hex_field(vector_file, expected_shared_secret, sizeof(expected_shared_secret)) != 0) {
                fputs("malformed encap case\n", stderr);
                return 1;
            }
            if (pqcrystals_ml_kem_768_ipd_ref_enc_derand(ciphertext,
                    shared_secret,
                    encapsulation_key,
                    key_seed) != 0) {
                fputs("enc_derand failed\n", stderr);
                return 1;
            }
            ++encap_cases;
            if (memcmp(ciphertext, expected_ciphertext, sizeof(ciphertext)) == 0 &&
                memcmp(shared_secret, expected_shared_secret, sizeof(shared_secret)) == 0) {
                ++encap_passed;
            }
        } else if (strcmp(operation_name, "decap") == 0) {
            unsigned long long case_number = strtoull(case_number_text, NULL, 10);
            if (case_number == 0ull ||
                read_hex_field(vector_file, decapsulation_key, sizeof(decapsulation_key)) != 0 ||
                read_hex_field(vector_file, ciphertext, sizeof(ciphertext)) != 0 ||
                read_hex_field(vector_file, expected_shared_secret, sizeof(expected_shared_secret)) != 0) {
                fputs("malformed decap case\n", stderr);
                return 1;
            }
            if (mlkem_decapsulate(shared_secret,
                    sizeof(shared_secret),
                    ciphertext,
                    sizeof(ciphertext),
                    decapsulation_key,
                    sizeof(decapsulation_key)) != 0) {
                fputs("decapsulate failed\n", stderr);
                return 1;
            }
            ++decap_cases;
            if (memcmp(shared_secret, expected_shared_secret, sizeof(shared_secret)) == 0) {
                ++decap_passed;
            }
            memcpy(rejection_input,
                decapsulation_key + MLKEM_DECAPSULATION_KEY_BYTES - MLKEM_SHARED_SECRET_BYTES,
                MLKEM_SHARED_SECRET_BYTES);
            memcpy(rejection_input + MLKEM_SHARED_SECRET_BYTES, ciphertext, sizeof(ciphertext));
            OQS_SHA3_shake256(rejection_secret, sizeof(rejection_secret), rejection_input, sizeof(rejection_input));
            if (memcmp(rejection_secret, expected_shared_secret, sizeof(rejection_secret)) == 0) {
                ++decap_rejections;
            }
        } else if (strcmp(operation_name, "ekcheck") == 0) {
            if (read_hex_field(vector_file, encapsulation_key, sizeof(encapsulation_key)) != 0) {
                fputs("malformed ekcheck case\n", stderr);
                return 1;
            }
            unsigned expected_validity = 0u;
            if (fscanf(vector_file, "%u", &expected_validity) != 1) {
                fputs("malformed ekcheck validity\n", stderr);
                return 1;
            }
            ++keycheck_cases;
        } else if (strcmp(operation_name, "dkcheck") == 0) {
            if (read_hex_field(vector_file, decapsulation_key, sizeof(decapsulation_key)) != 0) {
                fputs("malformed dkcheck case\n", stderr);
                return 1;
            }
            unsigned expected_validity = 0u;
            if (fscanf(vector_file, "%u", &expected_validity) != 1) {
                fputs("malformed dkcheck validity\n", stderr);
                return 1;
            }
            ++keycheck_cases;
        } else {
            fputs("unknown operation\n", stderr);
            return 1;
        }
    }
    if (!feof(vector_file) || ferror(vector_file)) {
        fputs("vector file read error\n", stderr);
        return 1;
    }
    if (fclose(vector_file) != 0) {
        return 1;
    }

    printf("impl=%s keygen=%u/%u encap=%u/%u decap=%u/%u decap_rejections=%u keycheck=not_applicable(%u)\n",
        RR_IMPL_NAME,
        keygen_passed,
        keygen_cases,
        encap_passed,
        encap_cases,
        decap_passed,
        decap_cases,
        decap_rejections,
        keycheck_cases);
    if (keygen_passed != keygen_cases || encap_passed != encap_cases || decap_passed != decap_cases) {
        fputs("M1 public KAT mismatch\n", stderr);
        return 1;
    }
    return 0;
}
