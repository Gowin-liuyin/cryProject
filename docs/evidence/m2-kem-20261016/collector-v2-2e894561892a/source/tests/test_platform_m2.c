#include "inputs.h"
#include "platform_m2.h"

#include "fips202.h"
#include "indcpa.h"

#include <stdio.h>
#include <string.h>

#define CHECK(condition)                                                                           \
    do {                                                                                           \
        if (!(condition)) {                                                                        \
            fprintf(stderr, "M2 check failed at line %d: %s\n", __LINE__, #condition);             \
            return 1;                                                                              \
        }                                                                                          \
    } while (0)

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

static int check_arguments(void)
{
    uint8_t sentinel = 0x5a;
    const size_t key_lengths[] = {0,
        MLKEM_ENCAPSULATION_KEY_BYTES - 1U,
        MLKEM_ENCAPSULATION_KEY_BYTES + 1U,
        SIZE_MAX};
    const size_t secret_key_lengths[] = {0,
        MLKEM_DECAPSULATION_KEY_BYTES - 1U,
        MLKEM_DECAPSULATION_KEY_BYTES + 1U,
        SIZE_MAX};
    const size_t ciphertext_lengths[] = {0,
        MLKEM_CIPHERTEXT_BYTES - 1U,
        MLKEM_CIPHERTEXT_BYTES + 1U,
        SIZE_MAX};
    const size_t secret_lengths[] = {0,
        MLKEM_SHARED_SECRET_BYTES - 1U,
        MLKEM_SHARED_SECRET_BYTES + 1U,
        SIZE_MAX};
    for (size_t length_index = 0; length_index < 4U; length_index++) {
        CHECK(mlkem_generate_key_pair(&sentinel,
                  key_lengths[length_index],
                  &sentinel,
                  MLKEM_DECAPSULATION_KEY_BYTES) == MLKEM_ERROR_ARGUMENT);
        CHECK(mlkem_generate_key_pair(&sentinel,
                  MLKEM_ENCAPSULATION_KEY_BYTES,
                  &sentinel,
                  secret_key_lengths[length_index]) == MLKEM_ERROR_ARGUMENT);
        CHECK(mlkem_encapsulate(&sentinel,
                  ciphertext_lengths[length_index],
                  &sentinel,
                  MLKEM_SHARED_SECRET_BYTES,
                  &sentinel,
                  MLKEM_ENCAPSULATION_KEY_BYTES) == MLKEM_ERROR_ARGUMENT);
        CHECK(mlkem_encapsulate(&sentinel,
                  MLKEM_CIPHERTEXT_BYTES,
                  &sentinel,
                  secret_lengths[length_index],
                  &sentinel,
                  MLKEM_ENCAPSULATION_KEY_BYTES) == MLKEM_ERROR_ARGUMENT);
        CHECK(mlkem_encapsulate(&sentinel,
                  MLKEM_CIPHERTEXT_BYTES,
                  &sentinel,
                  MLKEM_SHARED_SECRET_BYTES,
                  &sentinel,
                  key_lengths[length_index]) == MLKEM_ERROR_ARGUMENT);
        CHECK(mlkem_decapsulate(&sentinel,
                  secret_lengths[length_index],
                  &sentinel,
                  MLKEM_CIPHERTEXT_BYTES,
                  &sentinel,
                  MLKEM_DECAPSULATION_KEY_BYTES) == MLKEM_ERROR_ARGUMENT);
        CHECK(mlkem_decapsulate(&sentinel,
                  MLKEM_SHARED_SECRET_BYTES,
                  &sentinel,
                  ciphertext_lengths[length_index],
                  &sentinel,
                  MLKEM_DECAPSULATION_KEY_BYTES) == MLKEM_ERROR_ARGUMENT);
        CHECK(mlkem_decapsulate(&sentinel,
                  MLKEM_SHARED_SECRET_BYTES,
                  &sentinel,
                  MLKEM_CIPHERTEXT_BYTES,
                  &sentinel,
                  secret_key_lengths[length_index]) == MLKEM_ERROR_ARGUMENT);
        CHECK(sentinel == 0x5a);
    }
    CHECK(mlkem_generate_key_pair(NULL,
              MLKEM_ENCAPSULATION_KEY_BYTES,
              &sentinel,
              MLKEM_DECAPSULATION_KEY_BYTES) == MLKEM_ERROR_ARGUMENT);
    CHECK(mlkem_generate_key_pair(&sentinel,
              MLKEM_ENCAPSULATION_KEY_BYTES,
              NULL,
              MLKEM_DECAPSULATION_KEY_BYTES) == MLKEM_ERROR_ARGUMENT);
    for (unsigned pointer_index = 0; pointer_index < 3U; pointer_index++) {
        CHECK(mlkem_encapsulate(pointer_index == 0 ? NULL : &sentinel,
                  MLKEM_CIPHERTEXT_BYTES,
                  pointer_index == 1 ? NULL : &sentinel,
                  MLKEM_SHARED_SECRET_BYTES,
                  pointer_index == 2 ? NULL : &sentinel,
                  MLKEM_ENCAPSULATION_KEY_BYTES) == MLKEM_ERROR_ARGUMENT);
        CHECK(mlkem_decapsulate(pointer_index == 0 ? NULL : &sentinel,
                  MLKEM_SHARED_SECRET_BYTES,
                  pointer_index == 1 ? NULL : &sentinel,
                  MLKEM_CIPHERTEXT_BYTES,
                  pointer_index == 2 ? NULL : &sentinel,
                  MLKEM_DECAPSULATION_KEY_BYTES) == MLKEM_ERROR_ARGUMENT);
    }
    return 0;
}

int main(int argument_count, char **argument_values)
{
    uint8_t encapsulation_key[MLKEM_ENCAPSULATION_KEY_BYTES];
    uint8_t decapsulation_key[MLKEM_DECAPSULATION_KEY_BYTES];
    uint8_t repeated_key[MLKEM_ENCAPSULATION_KEY_BYTES];
    uint8_t repeated_secret_key[MLKEM_DECAPSULATION_KEY_BYTES];
    uint8_t ciphertext[MLKEM_CIPHERTEXT_BYTES];
    uint8_t shared_secret[MLKEM_SHARED_SECRET_BYTES];
    uint8_t expected_secret[MLKEM_SHARED_SECRET_BYTES];
    uint8_t message[MLKEM_SHARED_SECRET_BYTES];
    uint8_t transcript_digest[32];
    int is_transcript = argument_count == 2 && strcmp(argument_values[1], "--transcript") == 0;
    CHECK(argument_count == 1 || is_transcript);
    CHECK(check_arguments() == 0);
    CHECK(mlkem_self_test() == 0);
    CHECK(generate_test_key_pair(20261016U, encapsulation_key, decapsulation_key) == 0);
    CHECK(generate_test_key_pair(20261016U, repeated_key, repeated_secret_key) == 0);
    CHECK(memcmp(encapsulation_key, repeated_key, sizeof(encapsulation_key)) == 0);
    CHECK(memcmp(decapsulation_key, repeated_secret_key, sizeof(decapsulation_key)) == 0);
    keccak_state transcript;
    shake256_init(&transcript);
    shake256_absorb(&transcript, encapsulation_key, sizeof(encapsulation_key));
    shake256_absorb(&transcript, decapsulation_key, sizeof(decapsulation_key));
    for (unsigned category_index = 0; category_index < INPUT_CATEGORY_COUNT; category_index++) {
        for (uint64_t sample_index = 0; sample_index < 32U; sample_index++) {
            enum input_category category = (enum input_category)category_index;
            CHECK(generate_test_ciphertext(category,
                      20261016U,
                      sample_index,
                      encapsulation_key,
                      ciphertext) == 0);
            CHECK(mlkem_decapsulate(shared_secret,
                      sizeof(shared_secret),
                      ciphertext,
                      sizeof(ciphertext),
                      decapsulation_key,
                      sizeof(decapsulation_key)) == 0);
            if (category == INPUT_MESSAGE_ZERO || category == INPUT_MESSAGE_ONES) {
                indcpa_dec(message, ciphertext, decapsulation_key);
                for (size_t byte_index = 0; byte_index < sizeof(message); byte_index++) {
                    CHECK(message[byte_index] == (category == INPUT_MESSAGE_ZERO ? 0 : 255));
                }
                CHECK(platform_m2_test_message(ciphertext,
                          expected_secret,
                          encapsulation_key,
                          message) == 0);
                CHECK(memcmp(shared_secret, expected_secret, sizeof(shared_secret)) == 0);
            } else if (category == INPUT_RANDOM || category == INPUT_BIT_FLIPPED) {
                rejection_secret(expected_secret, ciphertext, decapsulation_key);
                CHECK(memcmp(shared_secret, expected_secret, sizeof(shared_secret)) == 0);
            }
            shake256_absorb(&transcript, ciphertext, sizeof(ciphertext));
            shake256_absorb(&transcript, shared_secret, sizeof(shared_secret));
        }
    }
    shake256_finalize(&transcript);
    shake256_squeeze(transcript_digest, sizeof(transcript_digest), &transcript);
    if (is_transcript) {
        for (size_t byte_index = 0; byte_index < sizeof(transcript_digest); byte_index++) {
            printf("%02x", transcript_digest[byte_index]);
        }
        putchar('\n');
    } else {
        puts("M2: random roundtrip, boundary guards, chosen messages and 64 implicit rejections "
             "passed");
    }
    erase_secret_bytes(decapsulation_key, sizeof(decapsulation_key));
    erase_secret_bytes(repeated_secret_key, sizeof(repeated_secret_key));
    erase_secret_bytes(shared_secret, sizeof(shared_secret));
    erase_secret_bytes(expected_secret, sizeof(expected_secret));
    erase_secret_bytes(&transcript, sizeof(transcript));
    return 0;
}
