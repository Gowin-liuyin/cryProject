#ifndef PLATFORM_M2_H
#define PLATFORM_M2_H

#include "mlkem.h"

/* 固定长度入口仅用于公开测试随机量和已选消息，不用于普通调用。 */
int platform_m2_test_keypair(uint8_t *encapsulation_key,
    uint8_t *decapsulation_key,
    const uint8_t key_randomness[MLKEM_KEY_SEED_BYTES]);
int platform_m2_test_encapsulate(uint8_t *ciphertext,
    uint8_t *shared_secret,
    const uint8_t *encapsulation_key,
    const uint8_t encapsulation_randomness[MLKEM_ENCAPSULATION_SEED_BYTES]);
int platform_m2_test_message(uint8_t *ciphertext,
    uint8_t *shared_secret,
    const uint8_t *encapsulation_key,
    const uint8_t message[MLKEM_SHARED_SECRET_BYTES]);
void platform_m2_sha3_256(uint8_t output[32], const uint8_t *input, size_t input_byte_count);

/* 上游 randombytes 的独立链接回调，只消费封装层预先取得的随机量。 */
void platform_m2_randombytes(uint8_t *output, size_t output_byte_count);

#endif
