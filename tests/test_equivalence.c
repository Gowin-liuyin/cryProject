#include "mlkem.h"
#include "mlkem_native.h"
#include "src/fips202/fips202.h"
#include <stdio.h>
#include <string.h>

int main(void)
{
    uint8_t key_seed[MLKEM_KEY_SEED_BYTES];
    uint8_t encapsulation_key[MLKEM_ENCAPSULATION_KEY_BYTES];
    uint8_t decapsulation_key[MLKEM_DECAPSULATION_KEY_BYTES];
    uint8_t ciphertext[MLKEM_CIPHERTEXT_BYTES];
    uint8_t valid_ciphertext[MLKEM_CIPHERTEXT_BYTES];
    uint8_t encapsulated_secret[MLKEM_SHARED_SECRET_BYTES];
    uint8_t shared_secret[MLKEM_SHARED_SECRET_BYTES];
    uint8_t rejection_input[MLKEM_SHARED_SECRET_BYTES + MLKEM_CIPHERTEXT_BYTES];
    uint8_t rejection_secret[MLKEM_SHARED_SECRET_BYTES];
    uint8_t transcript[MLKEM_ENCAPSULATION_KEY_BYTES + MLKEM_DECAPSULATION_KEY_BYTES +
        MLKEM_CIPHERTEXT_BYTES + MLKEM_SHARED_SECRET_BYTES];
    uint8_t transcript_digest[32];
    for (unsigned test_index = 0; test_index < 64u; ++test_index) {
        for (size_t byte_index = 0; byte_index < sizeof(key_seed); ++byte_index)
            key_seed[byte_index] = (uint8_t)(test_index + byte_index);
        if (baseline_native_keypair_derand(encapsulation_key, decapsulation_key, key_seed) != 0 ||
            baseline_native_enc_derand(valid_ciphertext, encapsulated_secret, encapsulation_key, key_seed) != 0) return 1;
        for (unsigned category_index = 0; category_index < 3u; ++category_index) {
            memcpy(ciphertext, valid_ciphertext, sizeof(ciphertext));
            if (category_index == 1u) ciphertext[test_index] ^= 1u;
            if (category_index == 2u) mlk_shake256(ciphertext, sizeof(ciphertext), key_seed, sizeof(key_seed));
            if (mlkem_decapsulate(shared_secret, sizeof(shared_secret), ciphertext, sizeof(ciphertext),
                decapsulation_key, sizeof(decapsulation_key)) != 0) return 1;
            if (category_index == 0u) {
                if (memcmp(shared_secret, encapsulated_secret, sizeof(shared_secret)) != 0) return 1;
            } else {
                memcpy(rejection_input, decapsulation_key + sizeof(decapsulation_key) - 32u, 32u);
                memcpy(rejection_input + 32u, ciphertext, sizeof(ciphertext));
                mlk_shake256(rejection_secret, sizeof(rejection_secret), rejection_input, sizeof(rejection_input));
                if (memcmp(shared_secret, rejection_secret, sizeof(shared_secret)) != 0) return 1;
            }
            memcpy(transcript, encapsulation_key, sizeof(encapsulation_key));
            memcpy(transcript + sizeof(encapsulation_key), decapsulation_key, sizeof(decapsulation_key));
            memcpy(transcript + sizeof(encapsulation_key) + sizeof(decapsulation_key), ciphertext, sizeof(ciphertext));
            memcpy(transcript + sizeof(transcript) - sizeof(shared_secret), shared_secret, sizeof(shared_secret));
            mlk_sha3_256(transcript_digest, transcript, sizeof(transcript));
            /* 仅输出公开固定测试种子的摘要，避免打印实际运行密钥。 */
            for (size_t byte_index = 0; byte_index < sizeof(transcript_digest); ++byte_index)
                if (printf("%02x", transcript_digest[byte_index]) < 0) return 1;
            if (putchar('\n') == EOF) return 1;
        }
    }
    return fflush(stdout) == 0 ? 0 : 1;
}
