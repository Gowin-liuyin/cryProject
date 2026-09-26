#include "mlkem.h"
#include "mlkem_native.h"
#include "src/fips202/fips202.h"
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#define CHECK(condition) do { if (!(condition)) { \
    fprintf(stderr, "check failed at line %d: %s\n", __LINE__, #condition); return 1; } } while (0)

static int read_hex_bytes(FILE *vector_file, uint8_t *output, size_t output_byte_count)
{
    char encoded_bytes[MLKEM_DECAPSULATION_KEY_BYTES * 2u + 1u];
    if (fscanf(vector_file, "%4800s", encoded_bytes) != 1 ||
        strlen(encoded_bytes) != output_byte_count * 2u) return 1;
    for (size_t byte_index = 0; byte_index < output_byte_count; ++byte_index) {
        unsigned decoded_byte;
        if (sscanf(encoded_bytes + byte_index * 2u, "%2x", &decoded_byte) != 1) return 1;
        output[byte_index] = (uint8_t)decoded_byte;
    }
    return 0;
}

static int check_vectors(const char *vector_path)
{
    FILE *vector_file = fopen(vector_path, "r");
    char operation_name[16];
    unsigned case_number;
    unsigned keygen_count = 0, encapsulation_count = 0, decapsulation_count = 0;
    unsigned rejection_count = 0;
    unsigned encapsulation_key_check_count = 0, decapsulation_key_check_count = 0;
    uint8_t rejection_input[MLKEM_SHARED_SECRET_BYTES + MLKEM_CIPHERTEXT_BYTES];
    uint8_t rejection_secret[MLKEM_SHARED_SECRET_BYTES];
    uint8_t key_seed[MLKEM_KEY_SEED_BYTES], encapsulation_seed[MLKEM_ENCAPSULATION_SEED_BYTES];
    uint8_t encapsulation_key[MLKEM_ENCAPSULATION_KEY_BYTES], expected_encapsulation_key[MLKEM_ENCAPSULATION_KEY_BYTES];
    uint8_t decapsulation_key[MLKEM_DECAPSULATION_KEY_BYTES], expected_decapsulation_key[MLKEM_DECAPSULATION_KEY_BYTES];
    uint8_t ciphertext[MLKEM_CIPHERTEXT_BYTES], expected_ciphertext[MLKEM_CIPHERTEXT_BYTES];
    uint8_t shared_secret[MLKEM_SHARED_SECRET_BYTES], expected_shared_secret[MLKEM_SHARED_SECRET_BYTES];
    CHECK(vector_file != NULL);
    while (fscanf(vector_file, "%15s %u", operation_name, &case_number) == 2) {
        if (strcmp(operation_name, "keygen") == 0) {
            CHECK(read_hex_bytes(vector_file, key_seed, sizeof(key_seed)) == 0);
            CHECK(read_hex_bytes(vector_file, expected_encapsulation_key, sizeof(expected_encapsulation_key)) == 0);
            CHECK(read_hex_bytes(vector_file, expected_decapsulation_key, sizeof(expected_decapsulation_key)) == 0);
            CHECK(baseline_native_keypair_derand(encapsulation_key, decapsulation_key, key_seed) == 0);
            CHECK(memcmp(encapsulation_key, expected_encapsulation_key, sizeof(encapsulation_key)) == 0);
            CHECK(memcmp(decapsulation_key, expected_decapsulation_key, sizeof(decapsulation_key)) == 0);
            ++keygen_count;
        } else if (strcmp(operation_name, "encap") == 0) {
            CHECK(read_hex_bytes(vector_file, encapsulation_key, sizeof(encapsulation_key)) == 0);
            CHECK(read_hex_bytes(vector_file, encapsulation_seed, sizeof(encapsulation_seed)) == 0);
            CHECK(read_hex_bytes(vector_file, expected_ciphertext, sizeof(expected_ciphertext)) == 0);
            CHECK(read_hex_bytes(vector_file, expected_shared_secret, sizeof(expected_shared_secret)) == 0);
            CHECK(baseline_native_enc_derand(ciphertext, shared_secret, encapsulation_key, encapsulation_seed) == 0);
            CHECK(memcmp(ciphertext, expected_ciphertext, sizeof(ciphertext)) == 0);
            CHECK(memcmp(shared_secret, expected_shared_secret, sizeof(shared_secret)) == 0);
            ++encapsulation_count;
        } else if (strcmp(operation_name, "decap") == 0) {
            CHECK(read_hex_bytes(vector_file, decapsulation_key, sizeof(decapsulation_key)) == 0);
            CHECK(read_hex_bytes(vector_file, ciphertext, sizeof(ciphertext)) == 0);
            CHECK(read_hex_bytes(vector_file, expected_shared_secret, sizeof(expected_shared_secret)) == 0);
            CHECK(mlkem_decapsulate(shared_secret, sizeof(shared_secret), ciphertext, sizeof(ciphertext),
                decapsulation_key, sizeof(decapsulation_key)) == 0);
            CHECK(memcmp(shared_secret, expected_shared_secret, sizeof(shared_secret)) == 0);
            memcpy(rejection_input, decapsulation_key + MLKEM_DECAPSULATION_KEY_BYTES - MLKEM_SHARED_SECRET_BYTES, MLKEM_SHARED_SECRET_BYTES);
            memcpy(rejection_input + MLKEM_SHARED_SECRET_BYTES, ciphertext, sizeof(ciphertext));
            mlk_shake256(rejection_secret, sizeof(rejection_secret), rejection_input, sizeof(rejection_input));
            if (memcmp(rejection_secret, expected_shared_secret, sizeof(rejection_secret)) == 0) ++rejection_count;
            ++decapsulation_count;
        } else if (strcmp(operation_name, "ekcheck") == 0) {
            unsigned expected_validity;
            CHECK(read_hex_bytes(vector_file, encapsulation_key, sizeof(encapsulation_key)) == 0);
            CHECK(fscanf(vector_file, "%u", &expected_validity) == 1);
            CHECK((baseline_native_check_pk(encapsulation_key) == 0) == (expected_validity != 0));
            ++encapsulation_key_check_count;
        } else if (strcmp(operation_name, "dkcheck") == 0) {
            unsigned expected_validity;
            CHECK(read_hex_bytes(vector_file, decapsulation_key, sizeof(decapsulation_key)) == 0);
            CHECK(fscanf(vector_file, "%u", &expected_validity) == 1);
            CHECK((baseline_native_check_sk(decapsulation_key) == 0) == (expected_validity != 0));
            ++decapsulation_key_check_count;
        } else {
            CHECK(0);
        }
    }
    CHECK(feof(vector_file) && !ferror(vector_file));
    CHECK(fclose(vector_file) == 0);
    CHECK(keygen_count == 25 && encapsulation_count == 25 && decapsulation_count == 10);
    CHECK(encapsulation_key_check_count == 10 && decapsulation_key_check_count == 10);
    CHECK(rejection_count > 0 && rejection_count < decapsulation_count);
    printf("NIST decaps vectors: %u implicit rejections, %u accepted ciphertexts\n", rejection_count, decapsulation_count - rejection_count);
    printf("%s: NIST FIPS203 KAT 25 keygen + 25 encaps + 10 decaps passed\n", mlkem_implementation_name());
    puts("NIST 10 encapsulation-key + 10 decapsulation-key validation cases passed");
    return 0;
}

static int check_public_arguments(void)
{
    uint8_t encapsulation_key[MLKEM_ENCAPSULATION_KEY_BYTES];
    uint8_t decapsulation_key[MLKEM_DECAPSULATION_KEY_BYTES];
    uint8_t ciphertext[MLKEM_CIPHERTEXT_BYTES];
    uint8_t shared_secret[MLKEM_SHARED_SECRET_BYTES];
    CHECK(mlkem_generate_key_pair(encapsulation_key, sizeof(encapsulation_key), decapsulation_key, sizeof(decapsulation_key)) == 0);
    CHECK(mlkem_encapsulate(ciphertext, sizeof(ciphertext), shared_secret, sizeof(shared_secret), encapsulation_key, sizeof(encapsulation_key)) == 0);
    for (size_t bad_length_index = 0; bad_length_index < 3; ++bad_length_index) {
        const size_t invalid_ciphertext_lengths[] = {0, MLKEM_CIPHERTEXT_BYTES - 1u, MLKEM_CIPHERTEXT_BYTES + 1u};
        CHECK(mlkem_decapsulate(shared_secret, sizeof(shared_secret), ciphertext, invalid_ciphertext_lengths[bad_length_index],
            decapsulation_key, sizeof(decapsulation_key)) == MLKEM_ERROR_ARGUMENT);
    }
    CHECK(mlkem_decapsulate(NULL, sizeof(shared_secret), ciphertext, sizeof(ciphertext), decapsulation_key, sizeof(decapsulation_key)) == MLKEM_ERROR_ARGUMENT);
    CHECK(mlkem_decapsulate(shared_secret, sizeof(shared_secret), NULL, sizeof(ciphertext), decapsulation_key, sizeof(decapsulation_key)) == MLKEM_ERROR_ARGUMENT);
    CHECK(mlkem_decapsulate(shared_secret, sizeof(shared_secret), ciphertext, sizeof(ciphertext), NULL, sizeof(decapsulation_key)) == MLKEM_ERROR_ARGUMENT);
    CHECK(mlkem_decapsulate(shared_secret, 0, ciphertext, sizeof(ciphertext), decapsulation_key, sizeof(decapsulation_key)) == MLKEM_ERROR_ARGUMENT);
    CHECK(mlkem_decapsulate(shared_secret, sizeof(shared_secret), ciphertext, sizeof(ciphertext), decapsulation_key, 0) == MLKEM_ERROR_ARGUMENT);
    CHECK(mlkem_generate_key_pair(NULL, sizeof(encapsulation_key), decapsulation_key, sizeof(decapsulation_key)) == MLKEM_ERROR_ARGUMENT);
    CHECK(mlkem_generate_key_pair(encapsulation_key, sizeof(encapsulation_key), NULL, sizeof(decapsulation_key)) == MLKEM_ERROR_ARGUMENT);
    CHECK(mlkem_generate_key_pair(encapsulation_key, 0, decapsulation_key, sizeof(decapsulation_key)) == MLKEM_ERROR_ARGUMENT);
    CHECK(mlkem_generate_key_pair(encapsulation_key, sizeof(encapsulation_key), decapsulation_key, 0) == MLKEM_ERROR_ARGUMENT);
    CHECK(mlkem_encapsulate(NULL, sizeof(ciphertext), shared_secret, sizeof(shared_secret), encapsulation_key, sizeof(encapsulation_key)) == MLKEM_ERROR_ARGUMENT);
    CHECK(mlkem_encapsulate(ciphertext, sizeof(ciphertext), NULL, sizeof(shared_secret), encapsulation_key, sizeof(encapsulation_key)) == MLKEM_ERROR_ARGUMENT);
    CHECK(mlkem_encapsulate(ciphertext, sizeof(ciphertext), shared_secret, sizeof(shared_secret), NULL, sizeof(encapsulation_key)) == MLKEM_ERROR_ARGUMENT);
    CHECK(mlkem_encapsulate(ciphertext, 0, shared_secret, sizeof(shared_secret), encapsulation_key, sizeof(encapsulation_key)) == MLKEM_ERROR_ARGUMENT);
    CHECK(mlkem_encapsulate(ciphertext, sizeof(ciphertext), shared_secret, 0, encapsulation_key, sizeof(encapsulation_key)) == MLKEM_ERROR_ARGUMENT);
    CHECK(mlkem_encapsulate(ciphertext, sizeof(ciphertext), shared_secret, sizeof(shared_secret), encapsulation_key, 0) == MLKEM_ERROR_ARGUMENT);
    return 0;
}

int main(int argument_count, char **argument_values)
{
    CHECK(argument_count == 2);
    CHECK(check_vectors(argument_values[1]) == 0);
    CHECK(check_public_arguments() == 0);
    CHECK(mlkem_self_test() == 0);
    puts("public argument boundaries and system-random roundtrip passed");
    return 0;
}
