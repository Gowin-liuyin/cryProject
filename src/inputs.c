#include "inputs.h"
#include "mlkem_native.h"
#include "src/fips202/fips202.h"
#include <errno.h>
#include <stdlib.h>
#include <string.h>

const char *input_category_name(enum input_category category)
{
    static const char *const category_names[] = {"valid", "bit-flipped", "random", "message-zero", "message-ones"};
    return (unsigned)category < INPUT_CATEGORY_COUNT ? category_names[category] : "unknown";
}

int parse_input_category(const char *category_text, enum input_category *category)
{
    for (unsigned category_index = 0; category_index < INPUT_CATEGORY_COUNT; ++category_index) {
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
    unsigned long long parsed_value;
    if (*integer_text == '\0') return 1;
    for (const char *character = integer_text; *character != '\0'; ++character)
        if (*character < '0' || *character > '9') return 1;
    errno = 0;
    parsed_value = strtoull(integer_text, &end_position, 10);
    if (errno != 0 || *end_position != '\0' || parsed_value > UINT64_MAX) return 1;
    *integer_value = (uint64_t)parsed_value;
    return 0;
}

void expand_test_seed(uint8_t *output, size_t output_byte_count, uint64_t test_seed,
    uint64_t sample_index, uint8_t purpose_tag)
{
    uint8_t domain_input[17];
    domain_input[0] = purpose_tag;
    for (unsigned byte_index = 0; byte_index < 8u; ++byte_index) {
        domain_input[1u + byte_index] = (uint8_t)(test_seed >> (8u * byte_index));
        domain_input[9u + byte_index] = (uint8_t)(sample_index >> (8u * byte_index));
    }
    /* 固定小端编码只服务公开测试种子，普通密码随机源不走这里。 */
    mlk_shake256(output, output_byte_count, domain_input, sizeof(domain_input));
}

int generate_test_key_pair(uint64_t test_seed, uint8_t *encapsulation_key, uint8_t *decapsulation_key)
{
    uint8_t key_seed[MLKEM_KEY_SEED_BYTES];
    int operation_status;
    expand_test_seed(key_seed, sizeof(key_seed), test_seed, 0, 1);
    operation_status = baseline_native_keypair_derand(encapsulation_key, decapsulation_key, key_seed);
    erase_secret_bytes(key_seed, sizeof(key_seed));
    return operation_status;
}

int generate_test_ciphertext(enum input_category category, uint64_t test_seed, uint64_t sample_index,
    const uint8_t *encapsulation_key, uint8_t *ciphertext)
{
    uint8_t encapsulation_seed[MLKEM_ENCAPSULATION_SEED_BYTES];
    uint8_t shared_secret[MLKEM_SHARED_SECRET_BYTES];
    int operation_status;
    if ((unsigned)category >= INPUT_CATEGORY_COUNT) return MLKEM_ERROR_ARGUMENT;
    if (category == INPUT_RANDOM) {
        expand_test_seed(ciphertext, MLKEM_CIPHERTEXT_BYTES, test_seed, sample_index, 3);
        return 0;
    }
    expand_test_seed(encapsulation_seed, sizeof(encapsulation_seed), test_seed, sample_index, 2);
    if (category == INPUT_MESSAGE_ZERO) memset(encapsulation_seed, 0, sizeof(encapsulation_seed));
    if (category == INPUT_MESSAGE_ONES) memset(encapsulation_seed, 255, sizeof(encapsulation_seed));
    operation_status = baseline_native_enc_derand(ciphertext, shared_secret, encapsulation_key, encapsulation_seed);
    erase_secret_bytes(shared_secret, sizeof(shared_secret));
    erase_secret_bytes(encapsulation_seed, sizeof(encapsulation_seed));
    if (operation_status == 0 && category == INPUT_BIT_FLIPPED)
        ciphertext[sample_index % MLKEM_CIPHERTEXT_BYTES] ^= (uint8_t)(1u << (sample_index % 8u));
    return operation_status;
}
