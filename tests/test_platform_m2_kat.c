#include "inputs.h"
#include "platform_m2.h"

#include "rng.h"

#include <stdio.h>
#include <string.h>

#define CHECK(condition)                                                                           \
    do {                                                                                           \
        if (!(condition)) {                                                                        \
            fprintf(stderr, "M2 KAT check failed at line %d: %s\n", __LINE__, #condition);         \
            return 1;                                                                              \
        }                                                                                          \
    } while (0)

static int read_nonempty_line(FILE *vector_file, char *line, size_t line_capacity_bytes)
{
    while (fgets(line, (int)line_capacity_bytes, vector_file) != NULL) {
        size_t line_byte_count = strlen(line);
        if (line_byte_count == 0 || line[line_byte_count - 1U] != '\n') {
            return 1;
        }
        line[strcspn(line, "\r\n")] = '\0';
        if (line[0] != '\0' && line[0] != '#') {
            return 0;
        }
    }
    return 1;
}

static int hex_digit(char character)
{
    if (character >= '0' && character <= '9') {
        return character - '0';
    }
    if (character >= 'A' && character <= 'F') {
        return character - 'A' + 10;
    }
    if (character >= 'a' && character <= 'f') {
        return character - 'a' + 10;
    }
    return -1;
}

static int
read_hex_field(FILE *vector_file, const char *prefix, uint8_t *output, size_t output_byte_count)
{
    char line[MLKEM_DECAPSULATION_KEY_BYTES * 2U + 32U];
    size_t prefix_byte_count = strlen(prefix);
    CHECK(read_nonempty_line(vector_file, line, sizeof(line)) == 0);
    CHECK(strncmp(line, prefix, prefix_byte_count) == 0);
    CHECK(strlen(line + prefix_byte_count) == output_byte_count * 2U);
    for (size_t byte_index = 0; byte_index < output_byte_count; byte_index++) {
        int high_digit = hex_digit(line[prefix_byte_count + byte_index * 2U]);
        int low_digit = hex_digit(line[prefix_byte_count + byte_index * 2U + 1U]);
        CHECK(high_digit >= 0 && low_digit >= 0);
        output[byte_index] = (uint8_t)((unsigned)high_digit * 16U + (unsigned)low_digit);
    }
    return 0;
}

int main(int argument_count, char **argument_values)
{
    uint8_t entropy_input[48];
    uint8_t key_randomness[MLKEM_KEY_SEED_BYTES];
    uint8_t encapsulation_randomness[MLKEM_ENCAPSULATION_SEED_BYTES];
    uint8_t encapsulation_key[MLKEM_ENCAPSULATION_KEY_BYTES];
    uint8_t expected_key[MLKEM_ENCAPSULATION_KEY_BYTES];
    uint8_t decapsulation_key[MLKEM_DECAPSULATION_KEY_BYTES];
    uint8_t expected_secret_key[MLKEM_DECAPSULATION_KEY_BYTES];
    uint8_t ciphertext[MLKEM_CIPHERTEXT_BYTES];
    uint8_t expected_ciphertext[MLKEM_CIPHERTEXT_BYTES];
    uint8_t shared_secret[MLKEM_SHARED_SECRET_BYTES];
    uint8_t expected_secret[MLKEM_SHARED_SECRET_BYTES];
    CHECK(argument_count == 2);
    FILE *vector_file = fopen(argument_values[1], "r");
    CHECK(vector_file != NULL);
    for (uint64_t expected_count = 0; expected_count < 100U; expected_count++) {
        char count_line[64];
        uint64_t vector_count;
        CHECK(read_nonempty_line(vector_file, count_line, sizeof(count_line)) == 0);
        CHECK(strncmp(count_line, "count = ", 8U) == 0);
        CHECK(parse_unsigned_integer(count_line + 8U, &vector_count) == 0);
        CHECK(vector_count == expected_count);
        CHECK(read_hex_field(vector_file, "seed = ", entropy_input, sizeof(entropy_input)) == 0);
        CHECK(read_hex_field(vector_file, "pk = ", expected_key, sizeof(expected_key)) == 0);
        CHECK(read_hex_field(vector_file,
                  "sk = ",
                  expected_secret_key,
                  sizeof(expected_secret_key)) == 0);
        CHECK(read_hex_field(vector_file,
                  "ct = ",
                  expected_ciphertext,
                  sizeof(expected_ciphertext)) == 0);
        CHECK(read_hex_field(vector_file, "ss = ", expected_secret, sizeof(expected_secret)) == 0);
        randombytes_init(entropy_input, NULL, 256);
        /* NIST DRBG 每次调用后更新状态，keygen 的两次 32 字节不能合并。 */
        CHECK(randombytes(key_randomness, 32U) == RNG_SUCCESS);
        CHECK(randombytes(key_randomness + 32U, 32U) == RNG_SUCCESS);
        CHECK(randombytes(encapsulation_randomness, 32U) == RNG_SUCCESS);
        CHECK(platform_m2_test_keypair(encapsulation_key, decapsulation_key, key_randomness) == 0);
        CHECK(memcmp(encapsulation_key, expected_key, sizeof(expected_key)) == 0);
        CHECK(memcmp(decapsulation_key, expected_secret_key, sizeof(expected_secret_key)) == 0);
        CHECK(platform_m2_test_encapsulate(ciphertext,
                  shared_secret,
                  encapsulation_key,
                  encapsulation_randomness) == 0);
        CHECK(memcmp(ciphertext, expected_ciphertext, sizeof(expected_ciphertext)) == 0);
        CHECK(memcmp(shared_secret, expected_secret, sizeof(expected_secret)) == 0);
        CHECK(mlkem_decapsulate(shared_secret,
                  sizeof(shared_secret),
                  expected_ciphertext,
                  sizeof(expected_ciphertext),
                  expected_secret_key,
                  sizeof(expected_secret_key)) == 0);
        CHECK(memcmp(shared_secret, expected_secret, sizeof(expected_secret)) == 0);
    }
    char extra_line[64];
    CHECK(read_nonempty_line(vector_file, extra_line, sizeof(extra_line)) != 0);
    CHECK(feof(vector_file) && !ferror(vector_file));
    CHECK(fclose(vector_file) == 0);
    erase_secret_bytes(key_randomness, sizeof(key_randomness));
    erase_secret_bytes(encapsulation_randomness, sizeof(encapsulation_randomness));
    erase_secret_bytes(decapsulation_key, sizeof(decapsulation_key));
    erase_secret_bytes(shared_secret, sizeof(shared_secret));
    printf("%s: 100 independent official round3 KAT keygen/encap/decap cases passed\n",
        mlkem_implementation_name());
    return 0;
}
