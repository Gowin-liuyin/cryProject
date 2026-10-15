#include "platform_m2.h"

#include "fips202.h"
#include "indcpa.h"
#include "kem.h"

#include <string.h>

_Static_assert(KYBER_PUBLICKEYBYTES == MLKEM_ENCAPSULATION_KEY_BYTES, "key size mismatch");
_Static_assert(KYBER_SECRETKEYBYTES == MLKEM_DECAPSULATION_KEY_BYTES, "key size mismatch");
_Static_assert(KYBER_CIPHERTEXTBYTES == MLKEM_CIPHERTEXT_BYTES, "ciphertext size mismatch");
_Static_assert(KYBER_SSBYTES == MLKEM_SHARED_SECRET_BYTES, "secret size mismatch");

struct random_context {
    uint8_t random_bytes[MLKEM_KEY_SEED_BYTES];
    size_t random_byte_count;
    size_t consumed_byte_count;
    int has_error;
};

static _Thread_local struct random_context current_random_context;

void platform_m2_randombytes(uint8_t *output, size_t output_byte_count)
{
    if (output == NULL || current_random_context.has_error ||
        output_byte_count >
            current_random_context.random_byte_count - current_random_context.consumed_byte_count) {
        current_random_context.has_error = 1;
        if (output != NULL) {
            memset(output, 0, output_byte_count);
        }
        return;
    }
    memcpy(output,
        current_random_context.random_bytes + current_random_context.consumed_byte_count,
        output_byte_count);
    current_random_context.consumed_byte_count += output_byte_count;
}

static void begin_random_context(const uint8_t *randomness, size_t randomness_byte_count)
{
    erase_secret_bytes(&current_random_context, sizeof(current_random_context));
    memcpy(current_random_context.random_bytes, randomness, randomness_byte_count);
    current_random_context.random_byte_count = randomness_byte_count;
}

static int finish_random_context(void)
{
    int operation_status = current_random_context.has_error ||
            current_random_context.consumed_byte_count != current_random_context.random_byte_count
        ? MLKEM_ERROR_RANDOM
        : 0;
    erase_secret_bytes(&current_random_context, sizeof(current_random_context));
    return operation_status;
}

int platform_m2_test_keypair(uint8_t *encapsulation_key,
    uint8_t *decapsulation_key,
    const uint8_t key_randomness[MLKEM_KEY_SEED_BYTES])
{
    if (encapsulation_key == NULL || decapsulation_key == NULL || key_randomness == NULL) {
        return MLKEM_ERROR_ARGUMENT;
    }
    begin_random_context(key_randomness, MLKEM_KEY_SEED_BYTES);
    (void)crypto_kem_keypair(encapsulation_key, decapsulation_key);
    int operation_status = finish_random_context();
    if (operation_status != 0) {
        erase_secret_bytes(encapsulation_key, MLKEM_ENCAPSULATION_KEY_BYTES);
        erase_secret_bytes(decapsulation_key, MLKEM_DECAPSULATION_KEY_BYTES);
    }
    return operation_status;
}

int platform_m2_test_encapsulate(uint8_t *ciphertext,
    uint8_t *shared_secret,
    const uint8_t *encapsulation_key,
    const uint8_t encapsulation_randomness[MLKEM_ENCAPSULATION_SEED_BYTES])
{
    if (ciphertext == NULL || shared_secret == NULL || encapsulation_key == NULL ||
        encapsulation_randomness == NULL) {
        return MLKEM_ERROR_ARGUMENT;
    }
    begin_random_context(encapsulation_randomness, MLKEM_ENCAPSULATION_SEED_BYTES);
    (void)crypto_kem_enc(ciphertext, shared_secret, encapsulation_key);
    int operation_status = finish_random_context();
    if (operation_status != 0) {
        erase_secret_bytes(ciphertext, MLKEM_CIPHERTEXT_BYTES);
        erase_secret_bytes(shared_secret, MLKEM_SHARED_SECRET_BYTES);
    }
    return operation_status;
}

int mlkem_generate_key_pair(uint8_t *encapsulation_key,
    size_t encapsulation_key_byte_count,
    uint8_t *decapsulation_key,
    size_t decapsulation_key_byte_count)
{
    uint8_t key_randomness[MLKEM_KEY_SEED_BYTES];
    if (encapsulation_key == NULL || decapsulation_key == NULL ||
        encapsulation_key_byte_count != MLKEM_ENCAPSULATION_KEY_BYTES ||
        decapsulation_key_byte_count != MLKEM_DECAPSULATION_KEY_BYTES) {
        return MLKEM_ERROR_ARGUMENT;
    }
    /* 先处理随机源失败，void 型上游回调不承担系统随机读取。 */
    int operation_status = system_random_bytes(key_randomness, sizeof(key_randomness));
    if (operation_status == 0) {
        operation_status =
            platform_m2_test_keypair(encapsulation_key, decapsulation_key, key_randomness);
    }
    erase_secret_bytes(key_randomness, sizeof(key_randomness));
    if (operation_status != 0) {
        erase_secret_bytes(encapsulation_key, encapsulation_key_byte_count);
        erase_secret_bytes(decapsulation_key, decapsulation_key_byte_count);
    }
    return operation_status;
}

int mlkem_encapsulate(uint8_t *ciphertext,
    size_t ciphertext_byte_count,
    uint8_t *shared_secret,
    size_t shared_secret_byte_count,
    const uint8_t *encapsulation_key,
    size_t encapsulation_key_byte_count)
{
    uint8_t encapsulation_randomness[MLKEM_ENCAPSULATION_SEED_BYTES];
    if (ciphertext == NULL || shared_secret == NULL || encapsulation_key == NULL ||
        ciphertext_byte_count != MLKEM_CIPHERTEXT_BYTES ||
        shared_secret_byte_count != MLKEM_SHARED_SECRET_BYTES ||
        encapsulation_key_byte_count != MLKEM_ENCAPSULATION_KEY_BYTES) {
        return MLKEM_ERROR_ARGUMENT;
    }
    int operation_status =
        system_random_bytes(encapsulation_randomness, sizeof(encapsulation_randomness));
    if (operation_status == 0) {
        operation_status = platform_m2_test_encapsulate(ciphertext,
            shared_secret,
            encapsulation_key,
            encapsulation_randomness);
    }
    erase_secret_bytes(encapsulation_randomness, sizeof(encapsulation_randomness));
    if (operation_status != 0) {
        erase_secret_bytes(ciphertext, ciphertext_byte_count);
        erase_secret_bytes(shared_secret, shared_secret_byte_count);
    }
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
    return crypto_kem_dec(shared_secret, ciphertext, decapsulation_key);
}

int platform_m2_test_message(uint8_t *ciphertext,
    uint8_t *shared_secret,
    const uint8_t *encapsulation_key,
    const uint8_t message[MLKEM_SHARED_SECRET_BYTES])
{
    uint8_t message_and_key_hash[2U * KYBER_SYMBYTES];
    uint8_t key_and_coins[2U * KYBER_SYMBYTES];
    if (ciphertext == NULL || shared_secret == NULL || encapsulation_key == NULL ||
        message == NULL) {
        return MLKEM_ERROR_ARGUMENT;
    }
    /* 原版先 H(随机量)；此明确测试入口直接选解密消息，后续公式与上游一致。 */
    memcpy(message_and_key_hash, message, KYBER_SYMBYTES);
    sha3_256(message_and_key_hash + KYBER_SYMBYTES, encapsulation_key, KYBER_PUBLICKEYBYTES);
    sha3_512(key_and_coins, message_and_key_hash, sizeof(message_and_key_hash));
    indcpa_enc(ciphertext, message, encapsulation_key, key_and_coins + KYBER_SYMBYTES);
    sha3_256(key_and_coins + KYBER_SYMBYTES, ciphertext, KYBER_CIPHERTEXTBYTES);
    shake256(shared_secret, KYBER_SSBYTES, key_and_coins, sizeof(key_and_coins));
    erase_secret_bytes(message_and_key_hash, sizeof(message_and_key_hash));
    erase_secret_bytes(key_and_coins, sizeof(key_and_coins));
    return 0;
}

void platform_m2_sha3_256(uint8_t output[32], const uint8_t *input, size_t input_byte_count)
{
    sha3_256(output, input, input_byte_count);
}

const char *mlkem_implementation_name(void)
{
#if defined(PLATFORM_M2_FIXED)
    return "m2-kyber768-round3-fixed";
#else
    return "m2-kyber768-round3-unfixed";
#endif
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
        operation_status = 1;
    }
    erase_secret_bytes(decapsulation_key, sizeof(decapsulation_key));
    erase_secret_bytes(encapsulated_secret, sizeof(encapsulated_secret));
    erase_secret_bytes(decapsulated_secret, sizeof(decapsulated_secret));
    return operation_status;
}
