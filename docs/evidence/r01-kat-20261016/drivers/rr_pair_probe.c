/*
 * T06 修复语义等价探针：同一份公开输入在两版实现上的逐字节输出比较。
 *
 * 覆盖：
 *   1) 全部公开向量（--format rsp 为官方 round3 KAT，--format txt 为 mlkem768.txt 的 decap 例）；
 *   2) --extra N 个由公开确定性测试种子派生的随机密文与逐字节篡改密文；
 *   3) 隐式拒绝语义：拒绝例的共享密钥必须等于规范定义的拒绝值
 *      （RR_REJECTION_STYLE=1 为 FIPS 203 §7.3 的 J(z||c)；
 *       RR_REJECTION_STYLE=2 为 Kyber round3 §1.4 的 KDF(z||H(c))）。
 *
 * 只写“逐例摘要文件 + 计数”，不打印共享密钥、不打印内部验证位、不打印任何验证结果字节。
 * 两版分别运行同一驱动，摘要文件必须逐字节相同（由外部 cmp 判定）。
 */

#include "inputs.h"
#include "mlkem.h"

#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#ifndef RR_IMPL_NAME
#define RR_IMPL_NAME "unknown"
#endif
#ifndef RR_HASH_STYLE
#define RR_HASH_STYLE 3
#endif
#ifndef RR_REJECTION_STYLE
#define RR_REJECTION_STYLE 1
#endif

#if RR_HASH_STYLE == 1
/* liboqs 0.10.0 内部 SHA3 符号（src/common/sha3/sha3.h 的公开原型）。 */
extern void OQS_SHA3_shake256(uint8_t *output, size_t outlen, const uint8_t *input, size_t inplen);
extern void OQS_SHA3_sha3_256(uint8_t *output, const uint8_t *input, size_t inplen);
static void rr_shake256(uint8_t *output, size_t output_byte_count, const uint8_t *input, size_t input_byte_count)
{
    OQS_SHA3_shake256(output, output_byte_count, input, input_byte_count);
}
static void rr_sha3_256(uint8_t output[32], const uint8_t *input, size_t input_byte_count)
{
    OQS_SHA3_sha3_256(output, input, input_byte_count);
}
#elif RR_HASH_STYLE == 2
extern void pqcrystals_kyber_fips202_ref_shake256(uint8_t *output,
    size_t output_byte_count,
    const uint8_t *input,
    size_t input_byte_count);
extern void pqcrystals_kyber_fips202_ref_sha3_256(uint8_t *output,
    const uint8_t *input,
    size_t input_byte_count);
static void rr_shake256(uint8_t *output, size_t output_byte_count, const uint8_t *input, size_t input_byte_count)
{
    pqcrystals_kyber_fips202_ref_shake256(output, output_byte_count, input, input_byte_count);
}
static void rr_sha3_256(uint8_t output[32], const uint8_t *input, size_t input_byte_count)
{
    pqcrystals_kyber_fips202_ref_sha3_256(output, input, input_byte_count);
}
#else
extern void baseline_native_shake256(uint8_t *output,
    size_t output_byte_count,
    const uint8_t *input,
    size_t input_byte_count);
extern void baseline_native_sha3_256(uint8_t output[32], const uint8_t *input, size_t input_byte_count);
static void rr_shake256(uint8_t *output, size_t output_byte_count, const uint8_t *input, size_t input_byte_count)
{
    baseline_native_shake256(output, output_byte_count, input, input_byte_count);
}
static void rr_sha3_256(uint8_t output[32], const uint8_t *input, size_t input_byte_count)
{
    baseline_native_sha3_256(output, input, input_byte_count);
}
#endif

#define RR_TAG_PUBLIC 0x51u
#define RR_TAG_EXTRA 0x45u
#define RR_TAG_KEYPAIR_ENCAP 0x4bu
#define RR_TAG_BYTES 1u
#define RR_INDEX_BYTES 8u
#define RR_DIGEST_BYTES 32u

static unsigned long long public_case_count;
static unsigned long long public_expected_match;
static unsigned long long public_rejection_case_count;
static unsigned long long public_rejection_agree;
static unsigned long long extra_case_count;
static unsigned long long extra_rejected_count;
static unsigned long long extra_unexpected_accept_count;
static unsigned long long failure_count;

static void rejection_value(uint8_t rejection_secret[RR_DIGEST_BYTES],
    const uint8_t *decapsulation_key,
    const uint8_t *ciphertext)
{
    uint8_t pre_key_input[RR_DIGEST_BYTES + MLKEM_CIPHERTEXT_BYTES];
    memcpy(pre_key_input,
        decapsulation_key + MLKEM_DECAPSULATION_KEY_BYTES - RR_DIGEST_BYTES,
        RR_DIGEST_BYTES);
#if RR_REJECTION_STYLE == 2
    uint8_t ciphertext_hash[RR_DIGEST_BYTES];
    rr_sha3_256(ciphertext_hash, ciphertext, MLKEM_CIPHERTEXT_BYTES);
    memcpy(pre_key_input + RR_DIGEST_BYTES, ciphertext_hash, RR_DIGEST_BYTES);
    rr_shake256(rejection_secret, RR_DIGEST_BYTES, pre_key_input, 2u * RR_DIGEST_BYTES);
#else
    memcpy(pre_key_input + RR_DIGEST_BYTES, ciphertext, MLKEM_CIPHERTEXT_BYTES);
    rr_shake256(rejection_secret, RR_DIGEST_BYTES, pre_key_input, sizeof(pre_key_input));
#endif
}

static void probe_case(FILE *digest_file,
    unsigned tag,
    unsigned long long case_index,
    const uint8_t *decapsulation_key,
    const uint8_t *ciphertext,
    const uint8_t *expected_shared_secret)
{
    uint8_t shared_secret[MLKEM_SHARED_SECRET_BYTES];
    uint8_t rejection_secret[RR_DIGEST_BYTES];
    uint8_t transcript[RR_TAG_BYTES + RR_INDEX_BYTES + MLKEM_CIPHERTEXT_BYTES + MLKEM_SHARED_SECRET_BYTES];
    uint8_t digest[RR_DIGEST_BYTES];

    if (mlkem_decapsulate(shared_secret,
            sizeof(shared_secret),
            ciphertext,
            MLKEM_CIPHERTEXT_BYTES,
            decapsulation_key,
            MLKEM_DECAPSULATION_KEY_BYTES) != 0) {
        ++failure_count;
        return;
    }
    rejection_value(rejection_secret, decapsulation_key, ciphertext);
    int is_rejection = memcmp(shared_secret, rejection_secret, RR_DIGEST_BYTES) == 0;

    if (expected_shared_secret != NULL) {
        ++public_case_count;
        if (memcmp(shared_secret, expected_shared_secret, MLKEM_SHARED_SECRET_BYTES) == 0) {
            ++public_expected_match;
        }
        int expected_is_rejection =
            memcmp(expected_shared_secret, rejection_secret, RR_DIGEST_BYTES) == 0;
        if (expected_is_rejection) {
            ++public_rejection_case_count;
        }
        if (expected_is_rejection == is_rejection) {
            ++public_rejection_agree;
        }
    } else {
        ++extra_case_count;
        if (is_rejection) {
            ++extra_rejected_count;
        } else {
            ++extra_unexpected_accept_count;
        }
    }

    transcript[0] = (uint8_t)tag;
    for (unsigned byte_index = 0u; byte_index < RR_INDEX_BYTES; ++byte_index) {
        transcript[RR_TAG_BYTES + byte_index] =
            (uint8_t)(case_index >> (8u * (RR_INDEX_BYTES - 1u - byte_index)));
    }
    memcpy(transcript + RR_TAG_BYTES + RR_INDEX_BYTES, ciphertext, MLKEM_CIPHERTEXT_BYTES);
    memcpy(transcript + RR_TAG_BYTES + RR_INDEX_BYTES + MLKEM_CIPHERTEXT_BYTES,
        shared_secret,
        MLKEM_SHARED_SECRET_BYTES);
    rr_shake256(digest, RR_DIGEST_BYTES, transcript, sizeof(transcript));
    if (fwrite(digest, 1u, RR_DIGEST_BYTES, digest_file) != RR_DIGEST_BYTES) {
        ++failure_count;
    }
}

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

static int decode_hex_text(const char *encoded, uint8_t *output, size_t output_byte_count)
{
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

/* mlkem768.txt：只取 decap 例；其余操作按格式跳过，不参与比较。 */
static int run_text_vectors(const char *vector_path,
    FILE *digest_file,
    unsigned long long *skipped_case_count)
{
    FILE *vector_file = fopen(vector_path, "r");
    if (vector_file == NULL) {
        return 1;
    }
    uint8_t decapsulation_key[MLKEM_DECAPSULATION_KEY_BYTES];
    uint8_t ciphertext[MLKEM_CIPHERTEXT_BYTES];
    uint8_t expected_shared_secret[MLKEM_SHARED_SECRET_BYTES];
    uint8_t scratch_encapsulation_key[MLKEM_ENCAPSULATION_KEY_BYTES];
    uint8_t scratch_seed[MLKEM_KEY_SEED_BYTES];

    char operation_name[16];
    char case_number_text[21];
    unsigned long long decap_index = 0u;
    while (fscanf(vector_file, "%15s %20s", operation_name, case_number_text) == 2) {
        if (strcmp(operation_name, "decap") == 0) {
            if (read_hex_field(vector_file, decapsulation_key, sizeof(decapsulation_key)) != 0 ||
                read_hex_field(vector_file, ciphertext, sizeof(ciphertext)) != 0 ||
                read_hex_field(vector_file, expected_shared_secret, sizeof(expected_shared_secret)) != 0) {
                fclose(vector_file);
                return 1;
            }
            probe_case(digest_file, RR_TAG_PUBLIC, decap_index, decapsulation_key, ciphertext, expected_shared_secret);
            ++decap_index;
        } else if (strcmp(operation_name, "keygen") == 0) {
            if (read_hex_field(vector_file, scratch_seed, sizeof(scratch_seed)) != 0 ||
                read_hex_field(vector_file, scratch_encapsulation_key, sizeof(scratch_encapsulation_key)) != 0 ||
                read_hex_field(vector_file, decapsulation_key, sizeof(decapsulation_key)) != 0) {
                fclose(vector_file);
                return 1;
            }
            ++(*skipped_case_count);
        } else if (strcmp(operation_name, "encap") == 0) {
            if (read_hex_field(vector_file, scratch_encapsulation_key, sizeof(scratch_encapsulation_key)) != 0 ||
                read_hex_field(vector_file, scratch_seed, MLKEM_ENCAPSULATION_SEED_BYTES) != 0 ||
                read_hex_field(vector_file, ciphertext, sizeof(ciphertext)) != 0 ||
                read_hex_field(vector_file, expected_shared_secret, sizeof(expected_shared_secret)) != 0) {
                fclose(vector_file);
                return 1;
            }
            ++(*skipped_case_count);
        } else if (strcmp(operation_name, "ekcheck") == 0) {
            unsigned expected_validity = 0u;
            if (read_hex_field(vector_file, scratch_encapsulation_key, sizeof(scratch_encapsulation_key)) != 0 ||
                fscanf(vector_file, "%u", &expected_validity) != 1) {
                fclose(vector_file);
                return 1;
            }
            ++(*skipped_case_count);
        } else if (strcmp(operation_name, "dkcheck") == 0) {
            unsigned expected_validity = 0u;
            if (read_hex_field(vector_file, decapsulation_key, sizeof(decapsulation_key)) != 0 ||
                fscanf(vector_file, "%u", &expected_validity) != 1) {
                fclose(vector_file);
                return 1;
            }
            ++(*skipped_case_count);
        } else {
            fclose(vector_file);
            return 1;
        }
    }
    int truncated = !feof(vector_file) || ferror(vector_file);
    if (fclose(vector_file) != 0 || truncated) {
        return 1;
    }
    return 0;
}

/* 官方 round3 KAT .rsp：count/seed/pk/sk/ct/ss 六行一组。 */
static int run_rsp_vectors(const char *vector_path,
    FILE *digest_file,
    unsigned long long *skipped_case_count)
{
    FILE *vector_file = fopen(vector_path, "r");
    if (vector_file == NULL) {
        return 1;
    }
    char line[MLKEM_DECAPSULATION_KEY_BYTES * 2u + 64u];
    uint8_t decapsulation_key[MLKEM_DECAPSULATION_KEY_BYTES];
    uint8_t ciphertext[MLKEM_CIPHERTEXT_BYTES];
    uint8_t expected_shared_secret[MLKEM_SHARED_SECRET_BYTES];
    int have_decapsulation_key = 0;
    int have_ciphertext = 0;
    unsigned long long case_index = 0u;

    while (fgets(line, (int)sizeof(line), vector_file) != NULL) {
        size_t line_byte_count = strcspn(line, "\r\n");
        line[line_byte_count] = '\0';
        if (line_byte_count == 0u || line[0] == '#') {
            continue;
        }
        char *separator = strpbrk(line, "= ");
        if (separator == NULL) {
            fclose(vector_file);
            return 1;
        }
        *separator = '\0';
        const char *value_text = separator + 1;
        while (*value_text == ' ' || *value_text == '=') {
            ++value_text;
        }
        if (strcmp(line, "sk") == 0) {
            if (decode_hex_text(value_text, decapsulation_key, sizeof(decapsulation_key)) != 0) {
                fclose(vector_file);
                return 1;
            }
            have_decapsulation_key = 1;
        } else if (strcmp(line, "ct") == 0) {
            if (decode_hex_text(value_text, ciphertext, sizeof(ciphertext)) != 0) {
                fclose(vector_file);
                return 1;
            }
            have_ciphertext = 1;
        } else if (strcmp(line, "ss") == 0) {
            if (decode_hex_text(value_text, expected_shared_secret, sizeof(expected_shared_secret)) != 0) {
                fclose(vector_file);
                return 1;
            }
            if (have_decapsulation_key == 0 || have_ciphertext == 0) {
                fclose(vector_file);
                return 1;
            }
            probe_case(digest_file,
                RR_TAG_PUBLIC,
                case_index,
                decapsulation_key,
                ciphertext,
                expected_shared_secret);
            ++case_index;
            have_decapsulation_key = 0;
            have_ciphertext = 0;
        } else {
            ++(*skipped_case_count);
        }
    }
    int truncated = !feof(vector_file) || ferror(vector_file);
    if (fclose(vector_file) != 0 || truncated) {
        return 1;
    }
    return 0;
}

/* 公开确定性种子派生的密钥对/封装可观测输出摘要（仅写摘要，不写密钥字节）。 */
static void write_keypair_encap_digest(FILE *digest_file,
    unsigned long long case_index,
    const uint8_t *encapsulation_key,
    const uint8_t *decapsulation_key,
    const uint8_t *ciphertext)
{
    uint8_t transcript[RR_TAG_BYTES + RR_INDEX_BYTES + MLKEM_ENCAPSULATION_KEY_BYTES +
        MLKEM_DECAPSULATION_KEY_BYTES + MLKEM_CIPHERTEXT_BYTES];
    uint8_t digest[RR_DIGEST_BYTES];
    transcript[0] = (uint8_t)RR_TAG_KEYPAIR_ENCAP;
    for (unsigned byte_index = 0u; byte_index < RR_INDEX_BYTES; ++byte_index) {
        transcript[RR_TAG_BYTES + byte_index] =
            (uint8_t)(case_index >> (8u * (RR_INDEX_BYTES - 1u - byte_index)));
    }
    size_t offset = RR_TAG_BYTES + RR_INDEX_BYTES;
    memcpy(transcript + offset, encapsulation_key, MLKEM_ENCAPSULATION_KEY_BYTES);
    offset += MLKEM_ENCAPSULATION_KEY_BYTES;
    memcpy(transcript + offset, decapsulation_key, MLKEM_DECAPSULATION_KEY_BYTES);
    offset += MLKEM_DECAPSULATION_KEY_BYTES;
    memcpy(transcript + offset, ciphertext, MLKEM_CIPHERTEXT_BYTES);
    rr_shake256(digest, RR_DIGEST_BYTES, transcript, sizeof(transcript));
    if (fwrite(digest, 1u, RR_DIGEST_BYTES, digest_file) != RR_DIGEST_BYTES) {
        ++failure_count;
    }
}

/* 公开确定性种子派生的额外输入：一半随机密文，一半逐字节篡改密文。 */
static int run_extra_cases(unsigned long long extra_case_count_requested, FILE *digest_file)
{
    uint8_t encapsulation_key[MLKEM_ENCAPSULATION_KEY_BYTES];
    uint8_t decapsulation_key[MLKEM_DECAPSULATION_KEY_BYTES];
    uint8_t ciphertext[MLKEM_CIPHERTEXT_BYTES];
    uint8_t valid_ciphertext[MLKEM_CIPHERTEXT_BYTES];
    for (unsigned long long case_index = 0u; case_index < extra_case_count_requested; ++case_index) {
        enum input_category category =
            (case_index % 2u == 0u) ? INPUT_RANDOM : INPUT_BIT_FLIPPED;
        if (generate_test_key_pair(case_index, encapsulation_key, decapsulation_key) != 0 ||
            generate_test_ciphertext(INPUT_VALID,
                case_index,
                case_index,
                encapsulation_key,
                valid_ciphertext) != 0) {
            ++failure_count;
            return 1;
        }
        write_keypair_encap_digest(digest_file,
            case_index,
            encapsulation_key,
            decapsulation_key,
            valid_ciphertext);
        if (generate_test_ciphertext(category, case_index, case_index, encapsulation_key, ciphertext) != 0) {
            ++failure_count;
            return 1;
        }
        probe_case(digest_file, RR_TAG_EXTRA, case_index, decapsulation_key, ciphertext, NULL);
    }
    return 0;
}

int main(int argument_count, char **argument_values)
{
    const char *vector_path = NULL;
    const char *format_name = NULL;
    const char *digest_path = NULL;
    unsigned long long extra_cases = 0u;
    for (int argument_index = 1; argument_index < argument_count; ++argument_index) {
        if (strcmp(argument_values[argument_index], "--vectors") == 0 && argument_index + 1 < argument_count) {
            vector_path = argument_values[++argument_index];
        } else if (strcmp(argument_values[argument_index], "--format") == 0 && argument_index + 1 < argument_count) {
            format_name = argument_values[++argument_index];
        } else if (strcmp(argument_values[argument_index], "--extra") == 0 && argument_index + 1 < argument_count) {
            extra_cases = strtoull(argument_values[++argument_index], NULL, 10);
        } else if (strcmp(argument_values[argument_index], "--digest") == 0 && argument_index + 1 < argument_count) {
            digest_path = argument_values[++argument_index];
        } else {
            fputs("usage: rr_pair_probe --vectors <file> --format <rsp|txt> --extra <n> --digest <file>\n", stderr);
            return 2;
        }
    }
    if (vector_path == NULL || format_name == NULL || digest_path == NULL) {
        fputs("usage: rr_pair_probe --vectors <file> --format <rsp|txt> --extra <n> --digest <file>\n", stderr);
        return 2;
    }
    FILE *digest_file = fopen(digest_path, "wb");
    if (digest_file == NULL) {
        fputs("cannot open digest file\n", stderr);
        return 2;
    }

    unsigned long long skipped_case_count = 0u;
    int status = 0;
    if (strcmp(format_name, "txt") == 0) {
        status = run_text_vectors(vector_path, digest_file, &skipped_case_count);
    } else if (strcmp(format_name, "rsp") == 0) {
        status = run_rsp_vectors(vector_path, digest_file, &skipped_case_count);
    } else {
        fputs("unknown vector format\n", stderr);
        status = 2;
    }
    if (status == 0 && extra_cases > 0u) {
        status = run_extra_cases(extra_cases, digest_file);
    }
    if (fflush(digest_file) != 0 || fclose(digest_file) != 0) {
        status = 1;
    }

    int rejection_semantics_ok = (public_rejection_agree == public_case_count) &&
        (extra_unexpected_accept_count == 0ull) && (extra_rejected_count == extra_case_count);
    int expected_match_ok = (public_expected_match == public_case_count) && public_case_count > 0ull;
    printf("impl=%s hash_style=%d rejection_style=%d public_cases=%llu public_expected_match=%llu "
           "public_rejection_cases=%llu public_rejection_agree=%llu extra_cases=%llu extra_rejected=%llu "
           "extra_unexpected_accept=%llu skipped_lines=%llu failures=%llu expected_match_ok=%d "
           "rejection_semantics_ok=%d\n",
        RR_IMPL_NAME,
        RR_HASH_STYLE,
        RR_REJECTION_STYLE,
        public_case_count,
        public_expected_match,
        public_rejection_case_count,
        public_rejection_agree,
        extra_case_count,
        extra_rejected_count,
        extra_unexpected_accept_count,
        skipped_case_count,
        failure_count,
        expected_match_ok,
        rejection_semantics_ok);
    if (status != 0 || failure_count != 0ull || expected_match_ok == 0 || rejection_semantics_ok == 0) {
        fputs("rr_pair_probe failed\n", stderr);
        return 1;
    }
    return 0;
}
