#ifndef BASELINE_INPUTS_H
#define BASELINE_INPUTS_H

#include "mlkem.h"

#define INPUT_CATEGORY_COUNT 5u

enum input_category {
    INPUT_VALID,
    INPUT_BIT_FLIPPED,
    INPUT_RANDOM,
    INPUT_MESSAGE_ZERO,
    INPUT_MESSAGE_ONES
};

const char *input_category_name(enum input_category category);
int parse_input_category(const char *category_text, enum input_category *category);
int parse_unsigned_integer(const char *integer_text, uint64_t *integer_value);

/* 下列入口仅用于公开测试种子；缓冲区大小由 mlkem.h 中的常量规定。 */
void expand_test_seed(uint8_t *output,
    size_t output_byte_count,
    uint64_t test_seed,
    uint64_t sample_index,
    uint8_t purpose_tag);
int generate_test_key_pair(uint64_t test_seed,
    uint8_t *encapsulation_key,
    uint8_t *decapsulation_key);
int generate_test_ciphertext(enum input_category category,
    uint64_t test_seed,
    uint64_t sample_index,
    const uint8_t *encapsulation_key,
    uint8_t *ciphertext);

#endif
