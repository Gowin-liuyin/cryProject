#include "inputs.h"

#include <errno.h>
#include <stdlib.h>
#include <string.h>

int m4_prepare_case(uint8_t class_label, uint8_t *secret_input, uint8_t *candidate_input)
{
    if (class_label > 1U || secret_input == NULL || candidate_input == NULL) {
        return 1;
    }
    memset(secret_input, 0x5a, PLATFORM_M4_INPUT_BYTES);
    memset(candidate_input, 0x5a, PLATFORM_M4_INPUT_BYTES);
    size_t difference_index = class_label == 0U ? 0U : PLATFORM_M4_INPUT_BYTES - 1U;
    secret_input[difference_index] ^= 1U;
    return 0;
}

static uint64_t next_order_value(uint64_t *order_state)
{
    /* 显式测试种子只用于类序乱序，不充当密码随机源。 */
    *order_state += UINT64_C(0x9e3779b97f4a7c15);
    uint64_t mixed_value = *order_state;
    mixed_value = (mixed_value ^ (mixed_value >> 30U)) * UINT64_C(0xbf58476d1ce4e5b9);
    mixed_value = (mixed_value ^ (mixed_value >> 27U)) * UINT64_C(0x94d049bb133111eb);
    return mixed_value ^ (mixed_value >> 31U);
}

int m4_prepare_class_order(uint8_t *class_order, size_t call_count, uint64_t *order_state)
{
    if (class_order == NULL || order_state == NULL || call_count == 0U || call_count % 2U != 0U) {
        return 1;
    }
    for (size_t pair_index = 0U; pair_index < call_count / 2U; pair_index++) {
        uint8_t first_class = (uint8_t)(next_order_value(order_state) & 1U);
        class_order[pair_index * 2U] = first_class;
        class_order[pair_index * 2U + 1U] = first_class ^ 1U;
    }
    return 0;
}

int m4_parse_unsigned(const char *text, uint64_t minimum, uint64_t maximum, uint64_t *value)
{
    if (text == NULL || value == NULL || *text == '\0') {
        return 1;
    }
    for (const char *digit = text; *digit != '\0'; digit++) {
        if (*digit < '0' || *digit > '9') {
            return 1;
        }
    }
    errno = 0;
    char *number_end = NULL;
    unsigned long long parsed_value = strtoull(text, &number_end, 10);
    if (errno != 0 || number_end == text || *number_end != '\0' || parsed_value < minimum ||
        parsed_value > maximum) {
        return 1;
    }
    *value = (uint64_t)parsed_value;
    return 0;
}
