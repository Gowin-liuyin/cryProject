#include "platform_m2.h"

#include <stdio.h>
#include <string.h>

static unsigned random_call_count;

int system_random_bytes(uint8_t *output, size_t output_byte_count)
{
    random_call_count++;
    memset(output, 0xa5, output_byte_count);
    return MLKEM_ERROR_RANDOM;
}

void erase_secret_bytes(void *secret, size_t secret_byte_count)
{
    volatile uint8_t *secret_bytes = secret;
    while (secret_byte_count != 0U) {
        *secret_bytes++ = 0;
        secret_byte_count--;
    }
}

int main(void)
{
    uint8_t encapsulation_key[MLKEM_ENCAPSULATION_KEY_BYTES];
    uint8_t decapsulation_key[MLKEM_DECAPSULATION_KEY_BYTES];
    uint8_t ciphertext[MLKEM_CIPHERTEXT_BYTES];
    uint8_t shared_secret[MLKEM_SHARED_SECRET_BYTES];
    memset(encapsulation_key, 0x3c, sizeof(encapsulation_key));
    memset(decapsulation_key, 0x3c, sizeof(decapsulation_key));
    memset(ciphertext, 0x3c, sizeof(ciphertext));
    memset(shared_secret, 0x3c, sizeof(shared_secret));
    if (mlkem_generate_key_pair(encapsulation_key,
            sizeof(encapsulation_key),
            decapsulation_key,
            sizeof(decapsulation_key)) != MLKEM_ERROR_RANDOM ||
        mlkem_encapsulate(ciphertext,
            sizeof(ciphertext),
            shared_secret,
            sizeof(shared_secret),
            encapsulation_key,
            sizeof(encapsulation_key)) != MLKEM_ERROR_RANDOM ||
        random_call_count != 2U) {
        return 1;
    }
    for (size_t byte_index = 0; byte_index < sizeof(encapsulation_key); byte_index++) {
        if (encapsulation_key[byte_index] != 0) {
            return 1;
        }
    }
    for (size_t byte_index = 0; byte_index < sizeof(decapsulation_key); byte_index++) {
        if (decapsulation_key[byte_index] != 0) {
            return 1;
        }
    }
    for (size_t byte_index = 0; byte_index < sizeof(ciphertext); byte_index++) {
        if (ciphertext[byte_index] != 0) {
            return 1;
        }
    }
    for (size_t byte_index = 0; byte_index < sizeof(shared_secret); byte_index++) {
        if (shared_secret[byte_index] != 0) {
            return 1;
        }
    }
    puts("M2: failing random provider returns an error and clears full output buffers");
    return 0;
}
