#include "inputs.h"
#include "platform_m2.h"

#include "fips202.h"

#include <errno.h>
#include <stdlib.h>
#include <string.h>

const char *input_category_name(enum input_category category)
{
    static const char *const names[] = {"valid",
        "bit-flipped",
        "random",
        "message-zero",
        "message-ones"};
    return (unsigned)category < INPUT_CATEGORY_COUNT ? names[category] : "unknown";
}

int parse_input_category(const char *category_text, enum input_category *category)
{
    if (category_text == NULL || category == NULL) {
        return 1;
    }
    for (unsigned category_index = 0; category_index < INPUT_CATEGORY_COUNT; category_index++) {
        if (strcmp(category_text, input_category_name((enum input_category)category_index)) == 0) {
            *category = (enum input_category)category_index;
            return 0;
        }
    }
    return 1;
}

int parse_unsigned_integer(const char *integer_text, uint64_t *integer_value)
{
    char *end_position;
    if (integer_text == NULL || integer_value == NULL || *integer_text == '\0') {
        return 1;
    }
    for (const char *character = integer_text; *character != '\0'; character++) {
        if (*character < '0' || *character > '9') {
            return 1;
        }
    }
    errno = 0;
    unsigned long long parsed_value = strtoull(integer_text, &end_position, 10);
    if (errno != 0 || *end_position != '\0' || parsed_value > UINT64_MAX) {
        return 1;
    }
    *integer_value = (uint64_t)parsed_value;
    return 0;
}

void expand_test_seed(uint8_t *output,
    size_t output_byte_count,
    uint64_t test_seed,
    uint64_t sample_index,
    uint8_t purpose_tag)
{
    uint8_t domain_input[17];
    domain_input[0] = purpose_tag;
    for (unsigned byte_index = 0; byte_index < 8U; byte_index++) {
        domain_input[1U + byte_index] = (uint8_t)(test_seed >> (8U * byte_index));
        domain_input[9U + byte_index] = (uint8_t)(sample_index >> (8U * byte_index));
    }
    shake256(output, output_byte_count, domain_input, sizeof(domain_input));
}

int generate_test_key_pair(uint64_t test_seed,
    uint8_t *encapsulation_key,
    uint8_t *decapsulation_key)
{
    uint8_t key_randomness[MLKEM_KEY_SEED_BYTES];
    expand_test_seed(key_randomness, sizeof(key_randomness), test_seed, 0, 1);
    int operation_status =
        platform_m2_test_keypair(encapsulation_key, decapsulation_key, key_randomness);
    erase_secret_bytes(key_randomness, sizeof(key_randomness));
    return operation_status;
}

int generate_test_ciphertext(enum input_category category,
    uint64_t test_seed,
    uint64_t sample_index,
    const uint8_t *encapsulation_key,
    uint8_t *ciphertext)
{
    uint8_t encapsulation_randomness[MLKEM_ENCAPSULATION_SEED_BYTES];
    uint8_t shared_secret[MLKEM_SHARED_SECRET_BYTES];
    if ((unsigned)category >= INPUT_CATEGORY_COUNT || encapsulation_key == NULL ||
        ciphertext == NULL) {
        return MLKEM_ERROR_ARGUMENT;
    }
    if (category == INPUT_RANDOM) {
        expand_test_seed(ciphertext, MLKEM_CIPHERTEXT_BYTES, test_seed, sample_index, 3);
        return 0;
    }
    int operation_status;
    if (category == INPUT_MESSAGE_ZERO || category == INPUT_MESSAGE_ONES) {
        memset(encapsulation_randomness,
            category == INPUT_MESSAGE_ZERO ? 0 : 255,
            sizeof(encapsulation_randomness));
        operation_status = platform_m2_test_message(ciphertext,
            shared_secret,
            encapsulation_key,
            encapsulation_randomness);
    } else {
        expand_test_seed(encapsulation_randomness,
            sizeof(encapsulation_randomness),
            test_seed,
            sample_index,
            2);
        operation_status = platform_m2_test_encapsulate(ciphertext,
            shared_secret,
            encapsulation_key,
            encapsulation_randomness);
    }
    erase_secret_bytes(shared_secret, sizeof(shared_secret));
    erase_secret_bytes(encapsulation_randomness, sizeof(encapsulation_randomness));
    if (operation_status == 0 && category == INPUT_BIT_FLIPPED) {
        ciphertext[sample_index % MLKEM_CIPHERTEXT_BYTES] ^= (uint8_t)(1U << (sample_index % 8U));
    }
    return operation_status;
}
