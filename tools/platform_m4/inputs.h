#ifndef PLATFORM_M4_INPUTS_H
#define PLATFORM_M4_INPUTS_H

#include <stddef.h>
#include <stdint.h>

#define PLATFORM_M4_INPUT_BYTES 32U

int m4_prepare_case(uint8_t class_label, uint8_t *secret_input, uint8_t *candidate_input);
int m4_prepare_class_order(uint8_t *class_order, size_t call_count, uint64_t *order_state);
int m4_parse_unsigned(const char *text, uint64_t minimum, uint64_t maximum, uint64_t *value);

#endif
