#ifndef BASELINE_DIAGNOSTIC_STAGES_H
#define BASELINE_DIAGNOSTIC_STAGES_H

#include <stddef.h>
#include <stdint.h>

/* 诊断构建才链接这些函数。正式无插桩目标不声明、不调用。 */

void baseline_diagnostic_unpack_ciphertext(void *ciphertext_vector,
    void *message_polynomial,
    const uint8_t *ciphertext_bytes);

void baseline_stage_decode(void *ciphertext_vector,
    void *message_polynomial,
    const uint8_t *ciphertext_bytes);

void baseline_stage_message_extraction(uint8_t *message_bytes, const void *polynomial);

int baseline_stage_decrypt(uint8_t *message_bytes,
    const uint8_t *ciphertext,
    const uint8_t *secret_key);

int baseline_stage_reencrypt(uint8_t *ciphertext,
    const uint8_t *message_bytes,
    const uint8_t *encapsulation_key,
    const uint8_t *coins);

uint8_t
baseline_stage_compare(const uint8_t *left_bytes, const uint8_t *right_bytes, size_t byte_count);

void baseline_stage_rejection_key(uint8_t *output_bytes,
    const uint8_t *input_bytes,
    size_t input_byte_count);

void baseline_stage_select(uint8_t *destination,
    const uint8_t *source,
    size_t byte_count,
    uint8_t selector);

#endif
