#ifndef BASELINE_MLKEM_H
#define BASELINE_MLKEM_H
#include <stddef.h>
#include <stdint.h>
#define MLKEM_ENCAPSULATION_KEY_BYTES 1184u
#define MLKEM_DECAPSULATION_KEY_BYTES 2400u
#define MLKEM_CIPHERTEXT_BYTES 1088u
#define MLKEM_SHARED_SECRET_BYTES 32u
#define MLKEM_KEY_SEED_BYTES 64u
#define MLKEM_ENCAPSULATION_SEED_BYTES 32u
#define MLKEM_ERROR_ARGUMENT (-100)
#define MLKEM_ERROR_RANDOM (-101)
int system_random_bytes(uint8_t *output, size_t output_byte_count);
void erase_secret_bytes(void *secret, size_t secret_byte_count);
int mlkem_generate_key_pair(uint8_t *encapsulation_key, size_t encapsulation_key_byte_count,
    uint8_t *decapsulation_key, size_t decapsulation_key_byte_count);
int mlkem_encapsulate(uint8_t *ciphertext, size_t ciphertext_byte_count,
    uint8_t *shared_secret, size_t shared_secret_byte_count,
    const uint8_t *encapsulation_key, size_t encapsulation_key_byte_count);
int mlkem_decapsulate(uint8_t *shared_secret, size_t shared_secret_byte_count,
    const uint8_t *ciphertext, size_t ciphertext_byte_count,
    const uint8_t *decapsulation_key, size_t decapsulation_key_byte_count);
int mlkem_self_test(void);
const char *mlkem_implementation_name(void);
#endif
