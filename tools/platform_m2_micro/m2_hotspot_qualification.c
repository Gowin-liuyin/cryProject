/* M2 除法热点微基准的独立功能资格。
   目标：证明微基准窗口里调用的热点，其输入与输出都与"采集件同源码构建"的对照实现逐字节一致。
   手段：链接期 --wrap=pqcrystals_kyber768_ref_poly_tomsg 抓住 vendor indcpa_dec /
   mlkem_decapsulate 真实调用热点时的多项式，与微基准自己推导的热点输入逐字节比较；
   另有公开 KAT 条目与冻结采集件 meta 的输入序列摘要两路交叉核对。
   本文件不参与计时；它只做功能资格，"通过"不构成任何计时或泄漏结论。 */
#define _POSIX_C_SOURCE 200809L

#include "collector_inputs.h"

#include "indcpa.h"
#include "inputs.h"
#include "mlkem.h"
#include "platform_m2.h"
#include "poly.h"
#include "polyvec.h"

#include <inttypes.h>
#include <stdarg.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#define M2_MICRO_MESSAGE_BYTES ((size_t)KYBER_INDCPA_MSGBYTES)
#define M2_MICRO_QUALIFICATION_CLASS_COUNT 2U
#define M2_MICRO_EXPECTED_HOTSPOT_SYMBOL "pqcrystals_kyber768_ref_poly_tomsg"
#define M2_MICRO_MAXIMUM_PATH_BYTES 4096U

/* poly 是纯 int16_t 系数数组：无填充字节，按字节比较与摘要都成立。 */
_Static_assert(sizeof(poly) == 2U * KYBER_N, "poly layout must be packed coefficients");

#define M2_MICRO_STRINGIFY_INNER(text) #text
#define M2_MICRO_STRINGIFY(text) M2_MICRO_STRINGIFY_INNER(text)

/* --wrap 只在链接期生效：vendor 目标文件对 poly_tomsg 的未定义引用改指到 __wrap_*，
   真实函数仍可经 __real_* 调用。vendor 源文件保持只读。 */
void __real_pqcrystals_kyber768_ref_poly_tomsg(uint8_t msg[KYBER_INDCPA_MSGBYTES],
    const poly *a);
void __wrap_pqcrystals_kyber768_ref_poly_tomsg(uint8_t msg[KYBER_INDCPA_MSGBYTES],
    const poly *a);

static poly captured_hotspot_input;
static uint64_t captured_hotspot_call_count;

void __wrap_pqcrystals_kyber768_ref_poly_tomsg(uint8_t msg[KYBER_INDCPA_MSGBYTES],
    const poly *a)
{
    captured_hotspot_input = *a;
    captured_hotspot_call_count += 1U;
    __real_pqcrystals_kyber768_ref_poly_tomsg(msg, a);
}

struct qualification_options {
    const char *public_key_path;
    const char *secret_key_path;
    const char *kat_response_path;
    const char *collector_meta_path;
    const char *transcript_path;
};

struct check_state {
    unsigned pass_count;
    unsigned fail_count;
    unsigned skip_count;
    FILE *transcript;
};

static void report_check(struct check_state *state,
    const char *check_name,
    int passed,
    const char *detail_format,
    ...)
{
    va_list arguments;
    if (passed) {
        state->pass_count += 1U;
    } else {
        state->fail_count += 1U;
    }
    printf("check=%s status=%s ", check_name, passed ? "PASS" : "FAIL");
    va_start(arguments, detail_format);
    (void)vprintf(detail_format, arguments);
    va_end(arguments);
    fputc('\n', stdout);
    (void)fflush(stdout);
}

static void report_skip(struct check_state *state, const char *check_name, const char *reason)
{
    state->skip_count += 1U;
    printf("check=%s status=SKIPPED reason=%s\n", check_name, reason);
    (void)fflush(stdout);
}

static void write_hex_line(struct check_state *state, const char *name, const uint8_t *bytes,
    size_t byte_count)
{
    if (state->transcript == NULL) {
        return;
    }
    if (fprintf(state->transcript, "%s=", name) < 0) {
        state->fail_count += 1U;
        return;
    }
    for (size_t byte_index = 0; byte_index < byte_count; ++byte_index) {
        if (fprintf(state->transcript, "%02x", bytes[byte_index]) < 0) {
            state->fail_count += 1U;
            return;
        }
    }
    if (fputc('\n', state->transcript) == EOF) {
        state->fail_count += 1U;
    }
}

static void digest_of(const uint8_t *bytes, size_t byte_count, uint8_t digest[32])
{
    platform_m2_sha3_256(digest, bytes, byte_count);
}

static void write_digest_line(struct check_state *state, const char *name, const uint8_t *bytes,
    size_t byte_count)
{
    uint8_t digest[32];
    digest_of(bytes, byte_count, digest);
    write_hex_line(state, name, digest, sizeof(digest));
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

/* 与微基准同源的热点输入推导：vendor indcpa_dec 的前缀逐调用一致。 */
static void derive_hotspot_input(poly *hotspot_input,
    const uint8_t *ciphertext,
    const uint8_t *secret_key)
{
    polyvec decompressed_vector;
    poly decompressed_scalar;
    polyvec secret_vector;
    polyvec_decompress(&decompressed_vector, ciphertext);
    poly_decompress(&decompressed_scalar, ciphertext + KYBER_POLYVECCOMPRESSEDBYTES);
    polyvec_frombytes(&secret_vector, secret_key);
    polyvec_ntt(&decompressed_vector);
    polyvec_basemul_acc_montgomery(hotspot_input, &secret_vector, &decompressed_vector);
    poly_invntt_tomont(hotspot_input);
    poly_sub(hotspot_input, &decompressed_scalar, hotspot_input);
    poly_reduce(hotspot_input);
    erase_secret_bytes(&secret_vector, sizeof(secret_vector));
}

static uint8_t expected_message_byte(enum m2_collector_class class_index)
{
    return class_index == M2_COLLECTOR_MESSAGE_ZERO ? 0x00U : 0xFFU;
}

/* 抓取一次完整 mlkem_decapsulate 里热点收到的多项式；同时核对解密路径只调用热点一次。 */
static int capture_decapsulation_hotspot_input(const uint8_t *ciphertext,
    const uint8_t *secret_key,
    poly *captured,
    uint64_t *call_count,
    uint8_t *shared_secret)
{
    uint64_t before_count = captured_hotspot_call_count;
    if (mlkem_decapsulate(shared_secret,
            MLKEM_SHARED_SECRET_BYTES,
            ciphertext,
            MLKEM_CIPHERTEXT_BYTES,
            secret_key,
            MLKEM_DECAPSULATION_KEY_BYTES) != 0) {
        return 1;
    }
    *call_count = captured_hotspot_call_count - before_count;
    *captured = captured_hotspot_input;
    return 0;
}

static int hex_value(int character)
{
    if (character >= '0' && character <= '9') {
        return character - '0';
    }
    if (character >= 'a' && character <= 'f') {
        return character - 'a' + 10;
    }
    if (character >= 'A' && character <= 'F') {
        return character - 'A' + 10;
    }
    return -1;
}

/* 从 "key = HEX" 行解出固定长度字节串。 */
enum hex_field_result {
    HEX_FIELD_OTHER = 0,
    HEX_FIELD_OK = 1,
    HEX_FIELD_BAD = -1
};

static enum hex_field_result parse_hex_field(const char *line,
    const char *key,
    uint8_t *output,
    size_t expected_byte_count)
{
    size_t key_byte_count = strlen(key);
    const char *cursor;
    if (strncmp(line, key, key_byte_count) != 0) {
        return HEX_FIELD_OTHER;
    }
    cursor = line + key_byte_count;
    while (*cursor == ' ' || *cursor == '\t') {
        cursor += 1;
    }
    if (*cursor != '=') {
        return HEX_FIELD_OTHER;
    }
    cursor += 1;
    while (*cursor == ' ' || *cursor == '\t') {
        cursor += 1;
    }
    for (size_t byte_index = 0; byte_index < expected_byte_count; ++byte_index) {
        int high = hex_value(cursor[0]);
        int low = hex_value(cursor[1]);
        if (high < 0 || low < 0) {
            return HEX_FIELD_BAD;
        }
        output[byte_index] = (uint8_t)((high << 4) | low);
        cursor += 2;
    }
    while (*cursor == ' ' || *cursor == '\t' || *cursor == '\n' || *cursor == '\r') {
        cursor += 1;
    }
    return *cursor == '\0' ? HEX_FIELD_OK : HEX_FIELD_BAD;
}

/* 读公开 KAT .rsp 的第一条 count = 0 记录（pk/sk/ct/ss 全部十六进制原文）。 */
static int load_first_kat_entry(const char *path,
    uint8_t *public_key,
    uint8_t *secret_key,
    uint8_t *ciphertext,
    uint8_t *expected_secret)
{
    char line[8192];
    FILE *file = fopen(path, "r");
    int found_public_key = 0;
    int found_secret_key = 0;
    int found_ciphertext = 0;
    int found_shared_secret = 0;
    int operation_status = 1;
    if (file == NULL) {
        return 1;
    }
    while (fgets(line, sizeof(line), file) != NULL) {
        enum hex_field_result field_result;
        field_result = parse_hex_field(line, "pk", public_key, MLKEM_ENCAPSULATION_KEY_BYTES);
        if (field_result == HEX_FIELD_BAD) {
            goto cleanup;
        }
        found_public_key = field_result == HEX_FIELD_OK ? 1 : found_public_key;
        field_result = parse_hex_field(line, "sk", secret_key, MLKEM_DECAPSULATION_KEY_BYTES);
        if (field_result == HEX_FIELD_BAD) {
            goto cleanup;
        }
        found_secret_key = field_result == HEX_FIELD_OK ? 1 : found_secret_key;
        field_result = parse_hex_field(line, "ct", ciphertext, MLKEM_CIPHERTEXT_BYTES);
        if (field_result == HEX_FIELD_BAD) {
            goto cleanup;
        }
        found_ciphertext = field_result == HEX_FIELD_OK ? 1 : found_ciphertext;
        field_result = parse_hex_field(line, "ss", expected_secret, MLKEM_SHARED_SECRET_BYTES);
        if (field_result == HEX_FIELD_BAD) {
            goto cleanup;
        }
        found_shared_secret = field_result == HEX_FIELD_OK ? 1 : found_shared_secret;
        if (found_public_key != 0 && found_secret_key != 0 && found_ciphertext != 0 &&
            found_shared_secret != 0) {
            operation_status = 0;
            break;
        }
    }
cleanup:
    if (fclose(file) != 0) {
        operation_status = 1;
    }
    return operation_status;
}

struct collector_meta {
    uint64_t test_seed;
    uint64_t samples_per_class;
    enum m2_collector_class class_list[M2_COLLECTOR_MAXIMUM_CLASSES];
    size_t class_count;
    uint8_t input_sequence_digest[32];
};

static int parse_decimal(const char *text, uint64_t *value)
{
    return parse_unsigned_integer(text, value);
}

static int parse_class_list_text(const char *text,
    enum m2_collector_class *class_list,
    size_t *class_count)
{
    char class_buffer[160];
    size_t parsed_count = 0;
    if (text == NULL || strlen(text) >= sizeof(class_buffer)) {
        return 1;
    }
    memcpy(class_buffer, text, strlen(text) + 1U);
    char *field_start = class_buffer;
    while (field_start != NULL) {
        char *field_end = strchr(field_start, ',');
        enum m2_collector_class parsed_class;
        if (field_end != NULL) {
            *field_end = '\0';
        }
        if (*field_start == '\0' || parsed_count >= M2_COLLECTOR_MAXIMUM_CLASSES ||
            m2_collector_parse_class(field_start, &parsed_class) != 0) {
            return 1;
        }
        class_list[parsed_count] = parsed_class;
        parsed_count += 1U;
        field_start = field_end == NULL ? NULL : field_end + 1;
    }
    *class_count = parsed_count;
    return 0;
}

static int read_collector_meta(const char *path, struct collector_meta *meta)
{
    char line[4096];
    FILE *file = fopen(path, "r");
    int has_seed = 0;
    int has_samples = 0;
    int has_classes = 0;
    int has_digest = 0;
    int operation_status = 1;
    if (file == NULL) {
        return 1;
    }
    while (fgets(line, sizeof(line), file) != NULL) {
        char *newline = strchr(line, '\n');
        if (newline != NULL) {
            *newline = '\0';
        }
        if (strncmp(line, "test_seed=", 10) == 0) {
            has_seed = parse_decimal(line + 10, &meta->test_seed) == 0 ? 1 : -1;
        } else if (strncmp(line, "samples_per_class=", 18) == 0) {
            has_samples = parse_decimal(line + 18, &meta->samples_per_class) == 0 ? 1 : -1;
        } else if (strncmp(line, "class_list=", 11) == 0) {
            has_classes = parse_class_list_text(line + 11, meta->class_list, &meta->class_count) == 0
                ? 1
                : -1;
        } else if (strncmp(line, "input_sequence_digest=", 22) == 0) {
            const char *cursor = line + 22;
            int valid = 1;
            for (size_t byte_index = 0; byte_index < 32U; ++byte_index) {
                int high = hex_value(cursor[0]);
                int low = hex_value(cursor[1]);
                if (high < 0 || low < 0) {
                    valid = 0;
                    break;
                }
                meta->input_sequence_digest[byte_index] = (uint8_t)((high << 4) | low);
                cursor += 2;
            }
            has_digest = valid ? 1 : -1;
        }
    }
    if (has_seed == 1 && has_samples == 1 && has_classes == 1 && has_digest == 1) {
        operation_status = 0;
    }
    if (fclose(file) != 0) {
        operation_status = 1;
    }
    return operation_status;
}

/* 用微基准同一份 collector_inputs.c 重算行序密文序列摘要，与冻结采集件 meta 逐字节比较。 */
static int recompute_collector_input_digest(const struct collector_meta *meta,
    const uint8_t *public_key,
    uint8_t digest[32])
{
    uint8_t *class_ciphertexts = NULL;
    uint8_t *ordered_ciphertexts = NULL;
    enum m2_collector_class *row_classes = NULL;
    uint8_t expected_secret[MLKEM_SHARED_SECRET_BYTES];
    size_t row_count = meta->class_count * (size_t)meta->samples_per_class;
    int operation_status = 1;
    class_ciphertexts = malloc((size_t)M2_COLLECTOR_CLASS_COUNT * MLKEM_CIPHERTEXT_BYTES);
    ordered_ciphertexts = malloc(row_count * (size_t)MLKEM_CIPHERTEXT_BYTES);
    row_classes = malloc(row_count * sizeof(*row_classes));
    if (class_ciphertexts == NULL || ordered_ciphertexts == NULL || row_classes == NULL) {
        goto cleanup;
    }
    for (size_t class_slot = 0; class_slot < meta->class_count; ++class_slot) {
        enum m2_collector_class class_index = meta->class_list[class_slot];
        uint8_t *class_ciphertext =
            class_ciphertexts + (size_t)class_index * MLKEM_CIPHERTEXT_BYTES;
        if (m2_collector_build_ciphertext(class_index, public_key, class_ciphertext,
                m2_collector_class_is_malformed(class_index) ? NULL : expected_secret) != 0) {
            goto cleanup;
        }
    }
    if (m2_collector_build_schedule(meta->class_list,
            meta->class_count,
            meta->samples_per_class,
            meta->test_seed,
            row_classes) != 0) {
        goto cleanup;
    }
    for (size_t row_index = 0; row_index < row_count; ++row_index) {
        memcpy(ordered_ciphertexts + row_index * MLKEM_CIPHERTEXT_BYTES,
            class_ciphertexts + (size_t)row_classes[row_index] * MLKEM_CIPHERTEXT_BYTES,
            MLKEM_CIPHERTEXT_BYTES);
    }
    if (m2_collector_digest_ciphertexts(ordered_ciphertexts, row_count, digest) != 0) {
        goto cleanup;
    }
    operation_status = 0;
cleanup:
    erase_secret_bytes(expected_secret, sizeof(expected_secret));
    free(class_ciphertexts);
    free(ordered_ciphertexts);
    free(row_classes);
    return operation_status;
}

static int parse_options(int argument_count, char **argument_values,
    struct qualification_options *options)
{
    memset(options, 0, sizeof(*options));
    for (int argument_index = 1; argument_index < argument_count; ++argument_index) {
        const char *option_name = argument_values[argument_index];
        const char *option_value =
            argument_index + 1 < argument_count ? argument_values[argument_index + 1] : NULL;
        if (option_value == NULL) {
            return 1;
        }
        argument_index += 1;
        if (strcmp(option_name, "--public-key") == 0) {
            options->public_key_path = option_value;
        } else if (strcmp(option_name, "--secret-key") == 0) {
            options->secret_key_path = option_value;
        } else if (strcmp(option_name, "--kat-response") == 0) {
            options->kat_response_path = option_value;
        } else if (strcmp(option_name, "--collector-meta") == 0) {
            options->collector_meta_path = option_value;
        } else if (strcmp(option_name, "--transcript") == 0) {
            options->transcript_path = option_value;
        } else {
            return 1;
        }
    }
    return options->public_key_path == NULL || options->secret_key_path == NULL ? 1 : 0;
}

int main(int argument_count, char **argument_values)
{
    struct qualification_options options;
    struct check_state state;
    uint8_t *public_key = NULL;
    uint8_t *secret_key = NULL;
    uint8_t *class_ciphertexts = NULL;
    poly hotspot_inputs[M2_MICRO_QUALIFICATION_CLASS_COUNT];
    uint8_t hotspot_messages[M2_MICRO_QUALIFICATION_CLASS_COUNT][KYBER_INDCPA_MSGBYTES];
    poly decapsulated_inputs[M2_MICRO_QUALIFICATION_CLASS_COUNT];
    uint8_t decapsulated_messages[M2_MICRO_QUALIFICATION_CLASS_COUNT][KYBER_INDCPA_MSGBYTES];
    static const enum m2_collector_class qualification_classes[M2_MICRO_QUALIFICATION_CLASS_COUNT] = {
        M2_COLLECTOR_MESSAGE_ZERO,
        M2_COLLECTOR_MESSAGE_ONES};
    int operation_status = 1;
    memset(&state, 0, sizeof(state));
    if (argument_count < 2) {
        fputs("usage: m2_hotspot_qualification --public-key <file> --secret-key <file>\n"
              "         [--kat-response <PQCkemKAT_2400.rsp>] [--collector-meta <meta>]\n"
              "         [--transcript <new file>]\n",
            stderr);
        return 2;
    }
    if (parse_options(argument_count, argument_values, &options) != 0) {
        fputs("invalid arguments\n", stderr);
        return 2;
    }
    if (options.transcript_path != NULL) {
        state.transcript = fopen(options.transcript_path, "wx");
        if (state.transcript == NULL) {
            fputs("transcript path must not exist\n", stderr);
            return 2;
        }
    }
    public_key = malloc(MLKEM_ENCAPSULATION_KEY_BYTES);
    secret_key = malloc(MLKEM_DECAPSULATION_KEY_BYTES);
    class_ciphertexts = malloc(M2_MICRO_QUALIFICATION_CLASS_COUNT * MLKEM_CIPHERTEXT_BYTES);
    if (public_key == NULL || secret_key == NULL || class_ciphertexts == NULL) {
        fputs("allocation failed\n", stderr);
        goto cleanup;
    }
    if (read_fixed_file(options.public_key_path, public_key, MLKEM_ENCAPSULATION_KEY_BYTES) != 0 ||
        read_fixed_file(options.secret_key_path, secret_key, MLKEM_DECAPSULATION_KEY_BYTES) != 0) {
        fputs("key files must hold exactly the ML-KEM-768 fixture lengths\n", stderr);
        goto cleanup;
    }
    report_check(&state,
        "hotspot_symbol",
        strcmp(M2_MICRO_STRINGIFY(poly_tomsg), M2_MICRO_EXPECTED_HOTSPOT_SYMBOL) == 0,
        "namespaced_symbol=%s expected=%s",
        M2_MICRO_STRINGIFY(poly_tomsg),
        M2_MICRO_EXPECTED_HOTSPOT_SYMBOL);
    for (size_t class_slot = 0; class_slot < M2_MICRO_QUALIFICATION_CLASS_COUNT; ++class_slot) {
        enum m2_collector_class class_index = qualification_classes[class_slot];
        uint8_t *class_ciphertext = class_ciphertexts + class_slot * MLKEM_CIPHERTEXT_BYTES;
        uint8_t expected_secret[MLKEM_SHARED_SECRET_BYTES];
        uint8_t shared_secret[MLKEM_SHARED_SECRET_BYTES];
        uint64_t hotspot_calls = 0;
        if (m2_collector_build_ciphertext(class_index, public_key, class_ciphertext,
                expected_secret) != 0) {
            fputs("ciphertext construction failed\n", stderr);
            goto cleanup;
        }
        erase_secret_bytes(expected_secret, sizeof(expected_secret));
        derive_hotspot_input(&hotspot_inputs[class_slot], class_ciphertext, secret_key);
        __real_pqcrystals_kyber768_ref_poly_tomsg(hotspot_messages[class_slot],
            &hotspot_inputs[class_slot]);
        /* 对照实现：同源码的 vendor indcpa_dec 输出，即真实解密路径上的热点输出。 */
        indcpa_dec(decapsulated_messages[class_slot], class_ciphertext, secret_key);
        if (capture_decapsulation_hotspot_input(class_ciphertext,
                secret_key,
                &decapsulated_inputs[class_slot],
                &hotspot_calls,
                shared_secret) != 0) {
            fputs("decapsulation failed\n", stderr);
            goto cleanup;
        }
        erase_secret_bytes(shared_secret, sizeof(shared_secret));
        report_check(&state,
            "hotspot_input_matches_decapsulation",
            memcmp(&decapsulated_inputs[class_slot], &hotspot_inputs[class_slot], sizeof(poly)) ==
                0,
            "class=%s bytes=%zu",
            m2_collector_class_name(class_index),
            sizeof(poly));
        report_check(&state,
            "decapsulation_calls_hotspot_once",
            hotspot_calls == 1U,
            "class=%s calls_per_decapsulation=%" PRIu64,
            m2_collector_class_name(class_index),
            hotspot_calls);
        report_check(&state,
            "hotspot_output_matches_decapsulation",
            memcmp(hotspot_messages[class_slot],
                decapsulated_messages[class_slot],
                M2_MICRO_MESSAGE_BYTES) == 0,
            "class=%s bytes=%zu",
            m2_collector_class_name(class_index),
            M2_MICRO_MESSAGE_BYTES);
        {
            uint8_t expected_messages[KYBER_INDCPA_MSGBYTES];
            memset(expected_messages, expected_message_byte(class_index), sizeof(expected_messages));
            report_check(&state,
                "hotspot_output_matches_chosen_message",
                memcmp(hotspot_messages[class_slot], expected_messages, sizeof(expected_messages)) ==
                    0,
                "class=%s expected_byte=0x%02x",
                m2_collector_class_name(class_index),
                (unsigned)expected_message_byte(class_index));
        }
        if (state.transcript != NULL) {
            fprintf(state.transcript, "class=%s\n", m2_collector_class_name(class_index));
            write_digest_line(&state,
                "hotspot_input_sha3_256",
                (const uint8_t *)&hotspot_inputs[class_slot],
                sizeof(poly));
            write_digest_line(&state,
                "decapsulation_hotspot_input_sha3_256",
                (const uint8_t *)&decapsulated_inputs[class_slot],
                sizeof(poly));
            write_hex_line(&state, "hotspot_output_hex", hotspot_messages[class_slot],
                M2_MICRO_MESSAGE_BYTES);
            write_hex_line(&state, "decapsulation_output_hex", decapsulated_messages[class_slot],
                M2_MICRO_MESSAGE_BYTES);
        }
    }
    if (options.kat_response_path != NULL) {
        uint8_t *kat_public_key = malloc(MLKEM_ENCAPSULATION_KEY_BYTES);
        uint8_t *kat_secret_key = malloc(MLKEM_DECAPSULATION_KEY_BYTES);
        uint8_t *kat_ciphertext = malloc(MLKEM_CIPHERTEXT_BYTES);
        uint8_t *kat_expected_secret = malloc(MLKEM_SHARED_SECRET_BYTES);
        uint8_t kat_shared_secret[MLKEM_SHARED_SECRET_BYTES];
        poly kat_derived_input;
        poly kat_captured_input;
        uint64_t kat_hotspot_calls = 0;
        if (kat_public_key == NULL || kat_secret_key == NULL || kat_ciphertext == NULL ||
            kat_expected_secret == NULL) {
            fputs("allocation failed\n", stderr);
            goto cleanup;
        }
        if (load_first_kat_entry(options.kat_response_path,
                kat_public_key,
                kat_secret_key,
                kat_ciphertext,
                kat_expected_secret) != 0) {
            report_check(&state, "kat_entry_parsed", 0, "path=%s", options.kat_response_path);
        } else {
            report_check(&state, "kat_entry_parsed", 1, "path=%s first_entry=count0",
                options.kat_response_path);
            derive_hotspot_input(&kat_derived_input, kat_ciphertext, kat_secret_key);
            indcpa_dec(decapsulated_messages[0], kat_ciphertext, kat_secret_key);
            if (capture_decapsulation_hotspot_input(kat_ciphertext, kat_secret_key,
                    &kat_captured_input, &kat_hotspot_calls, kat_shared_secret) != 0) {
                report_check(&state, "kat_decapsulation_succeeds", 0, "return=nonzero");
            } else {
                report_check(&state, "kat_decapsulation_succeeds", 1, "calls_per_decapsulation=%" PRIu64,
                    kat_hotspot_calls);
                report_check(&state,
                    "kat_shared_secret_matches_vector",
                    memcmp(kat_shared_secret, kat_expected_secret, MLKEM_SHARED_SECRET_BYTES) == 0,
                    "bytes=%u",
                    (unsigned)MLKEM_SHARED_SECRET_BYTES);
                report_check(&state,
                    "kat_hotspot_input_matches_decapsulation",
                    memcmp(&kat_captured_input, &kat_derived_input, sizeof(poly)) == 0,
                    "bytes=%zu",
                    sizeof(poly));
                if (state.transcript != NULL) {
                    write_digest_line(&state, "kat_hotspot_input_sha3_256",
                        (const uint8_t *)&kat_derived_input, sizeof(poly));
                    write_hex_line(&state, "kat_shared_secret_hex", kat_shared_secret,
                        MLKEM_SHARED_SECRET_BYTES);
                    write_hex_line(&state, "kat_expected_secret_hex", kat_expected_secret,
                        MLKEM_SHARED_SECRET_BYTES);
                }
            }
            erase_secret_bytes(kat_shared_secret, sizeof(kat_shared_secret));
        }
        erase_secret_bytes(kat_secret_key, MLKEM_DECAPSULATION_KEY_BYTES);
        free(kat_public_key);
        free(kat_secret_key);
        free(kat_ciphertext);
        free(kat_expected_secret);
    } else {
        report_skip(&state, "kat_entry_parsed", "no_kat_response_argument");
    }
    if (options.collector_meta_path != NULL) {
        struct collector_meta meta;
        uint8_t recomputed_digest[32];
        memset(&meta, 0, sizeof(meta));
        if (read_collector_meta(options.collector_meta_path, &meta) != 0) {
            report_check(&state, "collector_meta_parsed", 0, "path=%s",
                options.collector_meta_path);
        } else {
            report_check(&state, "collector_meta_parsed", 1,
                "path=%s seed=%" PRIu64 " samples=%" PRIu64 " classes=%zu",
                options.collector_meta_path,
                meta.test_seed,
                meta.samples_per_class,
                meta.class_count);
            if (recompute_collector_input_digest(&meta, public_key, recomputed_digest) != 0) {
                report_check(&state, "collector_input_sequence_digest", 0, "recompute_failed");
            } else {
                report_check(&state,
                    "collector_input_sequence_digest",
                    memcmp(recomputed_digest, meta.input_sequence_digest, 32) == 0,
                    "seed=%" PRIu64 " samples_per_class=%" PRIu64,
                    meta.test_seed,
                    meta.samples_per_class);
                if (state.transcript != NULL) {
                    write_hex_line(&state, "collector_input_sequence_digest",
                        recomputed_digest, sizeof(recomputed_digest));
                }
            }
        }
    } else {
        report_skip(&state, "collector_meta_parsed", "no_collector_meta_argument");
    }
    printf("qualification_pass_count=%u qualification_fail_count=%u qualification_skip_count=%u\n",
        state.pass_count,
        state.fail_count,
        state.skip_count);
    operation_status = state.fail_count == 0 ? 0 : 1;
cleanup:
    if (state.transcript != NULL) {
        if (fclose(state.transcript) != 0) {
            operation_status = 1;
        }
        state.transcript = NULL;
    }
    erase_secret_bytes(hotspot_inputs, sizeof(hotspot_inputs));
    erase_secret_bytes(decapsulated_inputs, sizeof(decapsulated_inputs));
    erase_secret_bytes(decapsulated_messages, sizeof(decapsulated_messages));
    if (secret_key != NULL) {
        erase_secret_bytes(secret_key, MLKEM_DECAPSULATION_KEY_BYTES);
    }
    free(public_key);
    free(secret_key);
    free(class_ciphertexts);
    return operation_status;
}
