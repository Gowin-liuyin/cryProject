/* collector-v2 的类语义与类顺序资格；正常模式跑检查，--transcript 输出版本无关转录用于跨版本比对。 */
#define _POSIX_C_SOURCE 200809L

#include "collector_inputs.h"

#include "fips202.h"
#include "indcpa.h"
#include "inputs.h"
#include "mlkem.h"
#include "platform_m2.h"

#include <inttypes.h>
#include <stdio.h>
#include <string.h>

#define CHECK(condition)                                                                           \
    do {                                                                                           \
        if (!(condition)) {                                                                        \
            fprintf(stderr, "M2 collector selftest failed at line %d: %s\n", __LINE__, #condition); \
            return 1;                                                                              \
        }                                                                                          \
    } while (0)

#define SELFTEST_KEY_SEED 20261016U
#define SELFTEST_TRANSCRIPT_ROWS 8U

struct selftest_state {
    uint8_t encapsulation_key[MLKEM_ENCAPSULATION_KEY_BYTES];
    uint8_t decapsulation_key[MLKEM_DECAPSULATION_KEY_BYTES];
    uint8_t ciphertexts[M2_COLLECTOR_CLASS_COUNT][MLKEM_CIPHERTEXT_BYTES];
    uint8_t expected_secrets[2][MLKEM_SHARED_SECRET_BYTES];
    uint8_t decapsulated_secrets[M2_COLLECTOR_CLASS_COUNT][MLKEM_SHARED_SECRET_BYTES];
};

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

static int build_state(struct selftest_state *state)
{
    if (generate_test_key_pair(SELFTEST_KEY_SEED,
            state->encapsulation_key,
            state->decapsulation_key) != 0) {
        return 1;
    }
    for (size_t class_index = 0; class_index < M2_COLLECTOR_CLASS_COUNT; ++class_index) {
        uint8_t *expected_secret = NULL;
        if (class_index == M2_COLLECTOR_MESSAGE_ZERO) {
            expected_secret = state->expected_secrets[0];
        } else if (class_index == M2_COLLECTOR_MESSAGE_ONES) {
            expected_secret = state->expected_secrets[1];
        }
        if (m2_collector_build_ciphertext((enum m2_collector_class)class_index,
                state->encapsulation_key,
                state->ciphertexts[class_index],
                expected_secret) != 0) {
            return 1;
        }
    }
    for (size_t class_index = 0; class_index < M2_COLLECTOR_CLASS_COUNT; ++class_index) {
        if (mlkem_decapsulate(state->decapsulated_secrets[class_index],
                MLKEM_SHARED_SECRET_BYTES,
                state->ciphertexts[class_index],
                MLKEM_CIPHERTEXT_BYTES,
                state->decapsulation_key,
                MLKEM_DECAPSULATION_KEY_BYTES) != 0) {
            return 1;
        }
    }
    return 0;
}

static int check_chosen_message_classes(const struct selftest_state *state)
{
    uint8_t message[MLKEM_SHARED_SECRET_BYTES];
    CHECK(memcmp(state->ciphertexts[M2_COLLECTOR_MESSAGE_ZERO],
              state->ciphertexts[M2_COLLECTOR_MESSAGE_ONES],
              MLKEM_CIPHERTEXT_BYTES) != 0);
    indcpa_dec(message, state->ciphertexts[M2_COLLECTOR_MESSAGE_ZERO], state->decapsulation_key);
    for (size_t byte_index = 0; byte_index < MLKEM_SHARED_SECRET_BYTES; ++byte_index) {
        CHECK(message[byte_index] == 0x00);
    }
    indcpa_dec(message, state->ciphertexts[M2_COLLECTOR_MESSAGE_ONES], state->decapsulation_key);
    for (size_t byte_index = 0; byte_index < MLKEM_SHARED_SECRET_BYTES; ++byte_index) {
        CHECK(message[byte_index] == 0xFF);
    }
    erase_secret_bytes(message, sizeof(message));
    CHECK(memcmp(state->decapsulated_secrets[M2_COLLECTOR_MESSAGE_ZERO],
              state->expected_secrets[0],
              MLKEM_SHARED_SECRET_BYTES) == 0);
    CHECK(memcmp(state->decapsulated_secrets[M2_COLLECTOR_MESSAGE_ONES],
              state->expected_secrets[1],
              MLKEM_SHARED_SECRET_BYTES) == 0);
    return 0;
}

static int check_malformed_ciphertexts(const struct selftest_state *state)
{
    uint8_t expected_rejection[MLKEM_SHARED_SECRET_BYTES];
    const uint8_t *base_ciphertext = state->ciphertexts[M2_COLLECTOR_MESSAGE_ZERO];
    CHECK(!m2_collector_class_is_malformed(M2_COLLECTOR_MESSAGE_ZERO));
    CHECK(m2_collector_class_is_malformed(M2_COLLECTOR_MALFORMED_ZERO_TAIL));
    CHECK(m2_collector_class_is_malformed(M2_COLLECTOR_MALFORMED_FF_TAIL));
    for (size_t class_index = 2U; class_index < M2_COLLECTOR_CLASS_COUNT; ++class_index) {
        const uint8_t *ciphertext = state->ciphertexts[class_index];
        uint8_t expected_tail =
            class_index == M2_COLLECTOR_MALFORMED_ZERO_TAIL ? 0x00 : 0xFF;
        /* 与基准密文只在尾部固定 32 字节不同，长度保持合法。 */
        CHECK(memcmp(ciphertext,
                  base_ciphertext,
                  MLKEM_CIPHERTEXT_BYTES - M2_COLLECTOR_TAIL_BYTES) == 0);
        for (size_t byte_index = MLKEM_CIPHERTEXT_BYTES - M2_COLLECTOR_TAIL_BYTES;
             byte_index < MLKEM_CIPHERTEXT_BYTES;
             ++byte_index) {
            CHECK(ciphertext[byte_index] == expected_tail);
        }
        rejection_secret(expected_rejection, ciphertext, state->decapsulation_key);
        CHECK(memcmp(state->decapsulated_secrets[class_index],
                  expected_rejection,
                  MLKEM_SHARED_SECRET_BYTES) == 0);
        CHECK(memcmp(state->decapsulated_secrets[class_index],
                  state->expected_secrets[0],
                  MLKEM_SHARED_SECRET_BYTES) != 0);
    }
    CHECK(memcmp(state->decapsulated_secrets[M2_COLLECTOR_MALFORMED_ZERO_TAIL],
              state->decapsulated_secrets[M2_COLLECTOR_MALFORMED_FF_TAIL],
              MLKEM_SHARED_SECRET_BYTES) != 0);
    erase_secret_bytes(expected_rejection, sizeof(expected_rejection));
    return 0;
}

static int check_schedule_replay(void)
{
    enum m2_collector_class all_classes[M2_COLLECTOR_CLASS_COUNT];
    enum m2_collector_class first_schedule[4U * SELFTEST_TRANSCRIPT_ROWS];
    enum m2_collector_class second_schedule[4U * SELFTEST_TRANSCRIPT_ROWS];
    enum m2_collector_class other_schedule[4U * SELFTEST_TRANSCRIPT_ROWS];
    size_t class_row_counts[M2_COLLECTOR_CLASS_COUNT];
    size_t row_count = (size_t)M2_COLLECTOR_CLASS_COUNT * SELFTEST_TRANSCRIPT_ROWS;
    for (size_t class_index = 0; class_index < M2_COLLECTOR_CLASS_COUNT; ++class_index) {
        all_classes[class_index] = (enum m2_collector_class)class_index;
    }
    CHECK(m2_collector_build_schedule(all_classes,
              M2_COLLECTOR_CLASS_COUNT,
              SELFTEST_TRANSCRIPT_ROWS,
              31337U,
              first_schedule) == 0);
    CHECK(m2_collector_build_schedule(all_classes,
              M2_COLLECTOR_CLASS_COUNT,
              SELFTEST_TRANSCRIPT_ROWS,
              31337U,
              second_schedule) == 0);
    CHECK(memcmp(first_schedule, second_schedule, row_count * sizeof(first_schedule[0])) == 0);
    CHECK(m2_collector_build_schedule(all_classes,
              M2_COLLECTOR_CLASS_COUNT,
              SELFTEST_TRANSCRIPT_ROWS,
              424242U,
              other_schedule) == 0);
    CHECK(memcmp(first_schedule, other_schedule, row_count * sizeof(first_schedule[0])) != 0);
    for (size_t class_index = 0; class_index < M2_COLLECTOR_CLASS_COUNT; ++class_index) {
        class_row_counts[class_index] = 0;
    }
    for (size_t row_index = 0; row_index < row_count; ++row_index) {
        class_row_counts[(size_t)first_schedule[row_index]] += 1U;
        class_row_counts[(size_t)other_schedule[row_index]] += 1U;
    }
    for (size_t class_index = 0; class_index < M2_COLLECTOR_CLASS_COUNT; ++class_index) {
        CHECK(class_row_counts[class_index] == 2U * SELFTEST_TRANSCRIPT_ROWS);
    }
    /* 非法规模必须被拒绝。 */
    CHECK(m2_collector_build_schedule(all_classes, 0, 1U, 1U, first_schedule) != 0);
    CHECK(m2_collector_build_schedule(all_classes, M2_COLLECTOR_CLASS_COUNT, 0, 1U, first_schedule) !=
          0);
    CHECK(m2_collector_build_schedule(all_classes,
              M2_COLLECTOR_CLASS_COUNT,
              (uint64_t)M2_COLLECTOR_MAXIMUM_SAMPLES_PER_CLASS + 1U,
              1U,
              first_schedule) != 0);
    CHECK(m2_collector_build_schedule(all_classes,
              M2_COLLECTOR_MAXIMUM_CLASSES + 1U,
              1U,
              1U,
              first_schedule) != 0);
    return 0;
}

static void schedule_digest(uint64_t test_seed,
    const enum m2_collector_class *class_list,
    size_t class_count,
    uint64_t samples_per_class,
    uint8_t digest[32])
{
    enum m2_collector_class row_classes[M2_COLLECTOR_MAXIMUM_CLASSES *
                                         (size_t)SELFTEST_TRANSCRIPT_ROWS];
    uint8_t label_bytes[M2_COLLECTOR_MAXIMUM_CLASSES * SELFTEST_TRANSCRIPT_ROWS];
    size_t row_count = class_count * (size_t)samples_per_class;
    if (m2_collector_build_schedule(class_list,
            class_count,
            samples_per_class,
            test_seed,
            row_classes) != 0) {
        memset(digest, 0, 32U);
        return;
    }
    for (size_t row_index = 0; row_index < row_count; ++row_index) {
        label_bytes[row_index] = (uint8_t)row_classes[row_index];
    }
    platform_m2_sha3_256(digest, label_bytes, row_count);
}

static void transcript_line(FILE *stream, const char *label, const uint8_t *bytes, size_t byte_count)
{
    fprintf(stream, "%s=", label);
    for (size_t byte_index = 0; byte_index < byte_count; ++byte_index) {
        fprintf(stream, "%02x", bytes[byte_index]);
    }
    fputc('\n', stream);
}

static int write_transcript(const struct selftest_state *state)
{
    uint8_t key_pair_material[MLKEM_ENCAPSULATION_KEY_BYTES + MLKEM_DECAPSULATION_KEY_BYTES];
    uint8_t digest[32];
    uint8_t decrypted_message[MLKEM_SHARED_SECRET_BYTES];
    enum m2_collector_class all_classes[M2_COLLECTOR_CLASS_COUNT];
    enum m2_collector_class main_pair[2] = {
        M2_COLLECTOR_MESSAGE_ZERO,
        M2_COLLECTOR_MESSAGE_ONES};
    puts("selftest_format=m2_collector_selftest_v1");
    fprintf(stdout, "key_seed=%u\n", (unsigned)SELFTEST_KEY_SEED);
    memcpy(key_pair_material, state->encapsulation_key, MLKEM_ENCAPSULATION_KEY_BYTES);
    memcpy(key_pair_material + MLKEM_ENCAPSULATION_KEY_BYTES,
        state->decapsulation_key,
        MLKEM_DECAPSULATION_KEY_BYTES);
    platform_m2_sha3_256(digest, key_pair_material, sizeof(key_pair_material));
    transcript_line(stdout, "key_pair_sha3_256", digest, sizeof(digest));
    for (size_t class_index = 0; class_index < M2_COLLECTOR_CLASS_COUNT; ++class_index) {
        fprintf(stdout, "class=%s\n", m2_collector_class_name((enum m2_collector_class)class_index));
        platform_m2_sha3_256(digest, state->ciphertexts[class_index], MLKEM_CIPHERTEXT_BYTES);
        transcript_line(stdout, "  ciphertext_sha3_256", digest, sizeof(digest));
        platform_m2_sha3_256(digest,
            state->decapsulated_secrets[class_index],
            MLKEM_SHARED_SECRET_BYTES);
        transcript_line(stdout, "  shared_secret_sha3_256", digest, sizeof(digest));
        if (class_index == M2_COLLECTOR_MESSAGE_ZERO || class_index == M2_COLLECTOR_MESSAGE_ONES) {
            indcpa_dec(decrypted_message,
                state->ciphertexts[class_index],
                state->decapsulation_key);
            platform_m2_sha3_256(digest, decrypted_message, MLKEM_SHARED_SECRET_BYTES);
            transcript_line(stdout, "  decrypted_message_sha3_256", digest, sizeof(digest));
        }
    }
    for (size_t class_index = 0; class_index < M2_COLLECTOR_CLASS_COUNT; ++class_index) {
        all_classes[class_index] = (enum m2_collector_class)class_index;
    }
    schedule_digest(31337U, all_classes, M2_COLLECTOR_CLASS_COUNT, SELFTEST_TRANSCRIPT_ROWS, digest);
    fprintf(stdout, "schedule seed=31337 classes=all samples=%u\n", (unsigned)SELFTEST_TRANSCRIPT_ROWS);
    transcript_line(stdout, "  schedule_sha3_256", digest, sizeof(digest));
    schedule_digest(424242U, main_pair, 2U, SELFTEST_TRANSCRIPT_ROWS, digest);
    fprintf(stdout,
        "schedule seed=424242 classes=message-zero,message-ones samples=%u\n",
        (unsigned)SELFTEST_TRANSCRIPT_ROWS);
    transcript_line(stdout, "  schedule_sha3_256", digest, sizeof(digest));
    return 0;
}

int main(int argument_count, char **argument_values)
{
    static struct selftest_state state;
    int is_transcript = argument_count == 2 && strcmp(argument_values[1], "--transcript") == 0;
    if (argument_count != 1 && !is_transcript) {
        fputs("usage: m2_collector_selftest [--transcript]\n", stderr);
        return 2;
    }
    CHECK(build_state(&state) == 0);
    CHECK(check_chosen_message_classes(&state) == 0);
    CHECK(check_malformed_ciphertexts(&state) == 0);
    CHECK(check_schedule_replay() == 0);
    if (is_transcript) {
        CHECK(write_transcript(&state) == 0);
    } else {
        puts("M2 collector selftest: chosen-message accept, malformed implicit rejection, "
             "schedule replay passed");
    }
    return 0;
}
