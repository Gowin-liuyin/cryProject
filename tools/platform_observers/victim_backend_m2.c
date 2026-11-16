/* victim_backend_m2：历史 Kyber768 round3（非 FIPS 203）两臂的观测者后端。
 * 链接 platform_m2_<variant>（vendor -Oz 冻结旗标 + 适配层），与
 * platform-m2/<variant>/measure 同一实现路径；类别密文经
 * platform_m2_test_message 以全 0 /全 0xff 消息构造，解封装直调
 * vendor crypto_kem_dec——全部在窗口外准备、窗口内只做一次解封装。 */

#include "victim_backend.h"

#include "platform_m2.h"

#include "kem.h"

#include <string.h>

static uint8_t m2_encapsulation_key[MLKEM_ENCAPSULATION_KEY_BYTES];
static uint8_t m2_decapsulation_key[MLKEM_DECAPSULATION_KEY_BYTES];
static uint8_t m2_ciphertext_zero[MLKEM_CIPHERTEXT_BYTES];
static uint8_t m2_ciphertext_ones[MLKEM_CIPHERTEXT_BYTES];

const char *victim_backend_name(void)
{
#ifdef PLATFORM_M2_FIXED
    return "m2-fixed";
#else
    return "m2-unfixed";
#endif
}

static void m2_fill_seed_bytes(uint8_t *output, size_t output_byte_count, uint64_t test_seed)
{
    uint64_t state = test_seed;
    if (state == UINT64_C(0)) {
        state = UINT64_C(0x9e3779b97f4a7c15);
    }
    for (size_t byte_index = 0u; byte_index < output_byte_count; ++byte_index) {
        state ^= state << 13;
        state ^= state >> 7;
        state ^= state << 17;
        output[byte_index] = (uint8_t)(state >> 56);
    }
}

int victim_backend_prepare(uint64_t test_seed)
{
    uint8_t key_randomness[MLKEM_KEY_SEED_BYTES];
    uint8_t reference_secret[MLKEM_SHARED_SECRET_BYTES];
    uint8_t message_zero[MLKEM_SHARED_SECRET_BYTES];
    uint8_t message_ones[MLKEM_SHARED_SECRET_BYTES];
    memset(message_zero, 0x00, sizeof(message_zero));
    memset(message_ones, 0xff, sizeof(message_ones));
    m2_fill_seed_bytes(key_randomness, sizeof(key_randomness), test_seed);
    if (platform_m2_test_keypair(m2_encapsulation_key,
            m2_decapsulation_key,
            key_randomness)
        != 0) {
        return 1;
    }
    if (platform_m2_test_message(m2_ciphertext_zero,
            reference_secret,
            m2_encapsulation_key,
            message_zero)
        != 0) {
        return 1;
    }
    if (platform_m2_test_message(m2_ciphertext_ones,
            reference_secret,
            m2_encapsulation_key,
            message_ones)
        != 0) {
        return 1;
    }
    return 0;
}

int victim_backend_decapsulate_once(int class_is_ones,
    uint8_t shared_secret[VICTIM_SHARED_SECRET_BYTES])
{
    const uint8_t *ciphertext = (class_is_ones != 0) ? m2_ciphertext_ones : m2_ciphertext_zero;
    return crypto_kem_dec(shared_secret, ciphertext, m2_decapsulation_key) == 0 ? 0 : 1;
}
