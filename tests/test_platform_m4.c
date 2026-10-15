#include "compare.h"
#include "inputs.h"

#include <stdio.h>
#include <string.h>

int main(void)
{
    uint8_t secret_input[PLATFORM_M4_INPUT_BYTES];
    uint8_t candidate_input[PLATFORM_M4_INPUT_BYTES];
    for (uint8_t class_label = 0U; class_label < 2U; class_label++) {
        int is_equal = 1;
        if (m4_prepare_case(class_label, secret_input, candidate_input) != 0 ||
            m4_compare_checked(secret_input,
                sizeof(secret_input),
                candidate_input,
                sizeof(candidate_input),
                &is_equal) != 0 ||
            is_equal != 0) {
            return 1;
        }
        size_t difference_count = 0U;
        for (size_t input_index = 0U; input_index < sizeof(secret_input); input_index++) {
            difference_count += secret_input[input_index] != candidate_input[input_index];
        }
        size_t expected_index = class_label == 0U ? 0U : PLATFORM_M4_INPUT_BYTES - 1U;
        if (difference_count != 1U ||
            secret_input[expected_index] == candidate_input[expected_index]) {
            return 1;
        }
    }
    uint8_t first_order[200];
    uint8_t repeated_order[200];
    uint64_t first_state = UINT64_C(2026101607);
    uint64_t repeated_state = first_state;
    if (m4_prepare_class_order(first_order, sizeof(first_order), &first_state) != 0 ||
        m4_prepare_class_order(repeated_order, sizeof(repeated_order), &repeated_state) != 0 ||
        memcmp(first_order, repeated_order, sizeof(first_order)) != 0 ||
        first_state != repeated_state) {
        return 1;
    }
    size_t first_class_count = 0U;
    for (size_t sample_index = 0U; sample_index < sizeof(first_order); sample_index++) {
        if (first_order[sample_index] > 1U ||
            first_order[sample_index] == first_order[sample_index ^ 1U]) {
            return 1;
        }
        first_class_count += first_order[sample_index] == 0U;
    }
    uint64_t parsed_value;
    if (first_class_count != sizeof(first_order) / 2U ||
        m4_prepare_case(2U, secret_input, candidate_input) == 0 ||
        m4_prepare_class_order(NULL, sizeof(first_order), &first_state) == 0 ||
        m4_prepare_class_order(first_order, 3U, &first_state) == 0 ||
        m4_parse_unsigned("18446744073709551615", 1U, UINT64_MAX, &parsed_value) != 0 ||
        parsed_value != UINT64_MAX || m4_parse_unsigned("-1", 1U, 100U, &parsed_value) == 0 ||
        m4_parse_unsigned(" 1", 1U, 100U, &parsed_value) == 0 ||
        m4_parse_unsigned("101", 1U, 100U, &parsed_value) == 0 ||
        m4_parse_unsigned("18446744073709551616", 1U, UINT64_MAX, &parsed_value) == 0) {
        return 1;
    }
    puts("m4_inputs=pass timing_collection=not_run");
    return 0;
}
