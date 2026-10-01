#include "mlkem.h"
#include "mlkem_native.h"

#include <string.h>

const char *mlkem_implementation_name(void)
{
#ifdef BASELINE_VULNERABLE
    return "vulnerable";
#elif defined(BASELINE_HARDENED)
    return "hardened";
#elif defined(BASELINE_DEPLOYABLE)
    return "deployable";
#else
    return "reference";
#endif
}

int mlkem_generate_key_pair(uint8_t *encapsulation_key,
    size_t encapsulation_key_byte_count,
    uint8_t *decapsulation_key,
    size_t decapsulation_key_byte_count)
{
    uint8_t key_seed[MLKEM_KEY_SEED_BYTES];
    int operation_status;
    if (encapsulation_key == NULL || decapsulation_key == NULL ||
        encapsulation_key_byte_count != MLKEM_ENCAPSULATION_KEY_BYTES ||
        decapsulation_key_byte_count != MLKEM_DECAPSULATION_KEY_BYTES) {
        return MLKEM_ERROR_ARGUMENT;
    }
    operation_status = system_random_bytes(key_seed, sizeof(key_seed));
    if (operation_status == 0) {
        operation_status =
            baseline_native_keypair_derand(encapsulation_key, decapsulation_key, key_seed);
    }
    erase_secret_bytes(key_seed, sizeof(key_seed));
    return operation_status;
}

int mlkem_encapsulate(uint8_t *ciphertext,
    size_t ciphertext_byte_count,
    uint8_t *shared_secret,
    size_t shared_secret_byte_count,
    const uint8_t *encapsulation_key,
    size_t encapsulation_key_byte_count)
{
    uint8_t encapsulation_seed[MLKEM_ENCAPSULATION_SEED_BYTES];
    int operation_status;
    if (ciphertext == NULL || shared_secret == NULL || encapsulation_key == NULL ||
        ciphertext_byte_count != MLKEM_CIPHERTEXT_BYTES ||
        shared_secret_byte_count != MLKEM_SHARED_SECRET_BYTES ||
        encapsulation_key_byte_count != MLKEM_ENCAPSULATION_KEY_BYTES) {
        return MLKEM_ERROR_ARGUMENT;
    }
    operation_status = system_random_bytes(encapsulation_seed, sizeof(encapsulation_seed));
    if (operation_status == 0) {
        operation_status = baseline_native_enc_derand(ciphertext,
            shared_secret,
            encapsulation_key,
            encapsulation_seed);
    }
    erase_secret_bytes(encapsulation_seed, sizeof(encapsulation_seed));
    return operation_status;
}

int mlkem_decapsulate(uint8_t *shared_secret,
    size_t shared_secret_byte_count,
    const uint8_t *ciphertext,
    size_t ciphertext_byte_count,
    const uint8_t *decapsulation_key,
    size_t decapsulation_key_byte_count)
{
    if (shared_secret == NULL || ciphertext == NULL || decapsulation_key == NULL ||
        shared_secret_byte_count != MLKEM_SHARED_SECRET_BYTES ||
        ciphertext_byte_count != MLKEM_CIPHERTEXT_BYTES ||
        decapsulation_key_byte_count != MLKEM_DECAPSULATION_KEY_BYTES) {
        return MLKEM_ERROR_ARGUMENT;
    }
    return baseline_native_dec(shared_secret, ciphertext, decapsulation_key);
}

int mlkem_self_test(void)
{
    uint8_t encapsulation_key[MLKEM_ENCAPSULATION_KEY_BYTES];
    uint8_t decapsulation_key[MLKEM_DECAPSULATION_KEY_BYTES];
    uint8_t ciphertext[MLKEM_CIPHERTEXT_BYTES];
    uint8_t encapsulated_secret[MLKEM_SHARED_SECRET_BYTES];
    uint8_t decapsulated_secret[MLKEM_SHARED_SECRET_BYTES];
    int operation_status = mlkem_generate_key_pair(encapsulation_key,
        sizeof(encapsulation_key),
        decapsulation_key,
        sizeof(decapsulation_key));
    if (operation_status == 0) {
        operation_status = mlkem_encapsulate(ciphertext,
            sizeof(ciphertext),
            encapsulated_secret,
            sizeof(encapsulated_secret),
            encapsulation_key,
            sizeof(encapsulation_key));
    }
    if (operation_status == 0) {
        operation_status = mlkem_decapsulate(decapsulated_secret,
            sizeof(decapsulated_secret),
            ciphertext,
            sizeof(ciphertext),
            decapsulation_key,
            sizeof(decapsulation_key));
    }
    if (operation_status == 0 &&
        memcmp(encapsulated_secret, decapsulated_secret, sizeof(encapsulated_secret)) != 0) {
        operation_status = -1;
    }
    erase_secret_bytes(decapsulation_key, sizeof(decapsulation_key));
    erase_secret_bytes(encapsulated_secret, sizeof(encapsulated_secret));
    erase_secret_bytes(decapsulated_secret, sizeof(decapsulated_secret));
    return operation_status;
}
