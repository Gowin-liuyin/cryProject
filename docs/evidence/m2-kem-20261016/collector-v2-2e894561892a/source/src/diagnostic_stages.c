#include "diagnostic_stages.h"

/* 头文件里的 static inline 不能再被钩子包一层，否则自耗时会算到内联体而不是阶段包装。 */
#if defined(__clang__)
#pragma clang attribute push(__attribute__((no_instrument_function)), apply_to = function)
#endif
#include "src/compress.h"
#include "src/indcpa.h"
#include "src/symmetric.h"
#include "src/verify.h"
#if defined(__clang__)
#pragma clang attribute pop
#endif

/* 这些函数单独编译并打开编译器进入/退出钩子。
 * 比较、拒绝派生和选择在上游是宏或 static inline，钩子到达的是本文件的包装函数。 */

__attribute__((noinline)) void baseline_stage_decode(void *ciphertext_vector,
    void *message_polynomial,
    const uint8_t *ciphertext_bytes)
{
    baseline_diagnostic_unpack_ciphertext(ciphertext_vector, message_polynomial, ciphertext_bytes);
}

__attribute__((noinline)) void baseline_stage_message_extraction(uint8_t *message_bytes,
    const void *polynomial)
{
    mlk_poly_tomsg(message_bytes, (const mlk_poly *)polynomial);
}

__attribute__((noinline)) int
baseline_stage_decrypt(uint8_t *message_bytes, const uint8_t *ciphertext, const uint8_t *secret_key)
{
    return mlk_indcpa_dec(message_bytes, ciphertext, secret_key, 0);
}

__attribute__((noinline)) int baseline_stage_reencrypt(uint8_t *ciphertext,
    const uint8_t *message_bytes,
    const uint8_t *encapsulation_key,
    const uint8_t *coins)
{
    return mlk_indcpa_enc(ciphertext, message_bytes, encapsulation_key, coins, 0);
}

/* 内核翻译单元没有进入/退出钩子。这一层单独打开钩子，排他时间才只覆盖消息多项式。 */
__attribute__((noinline)) void baseline_stage_reencrypt_message(void *message_polynomial,
    const uint8_t *message_bytes)
{
    mlk_poly_frommsg((mlk_poly *)message_polynomial, message_bytes);
}

__attribute__((noinline)) uint8_t baseline_stage_compare(const uint8_t *left_bytes,
    const uint8_t *right_bytes,
    size_t byte_count)
{
    return mlk_ct_memcmp(left_bytes, right_bytes, byte_count);
}

__attribute__((noinline)) void baseline_stage_rejection_key(uint8_t *output_bytes,
    const uint8_t *input_bytes,
    size_t input_byte_count)
{
    mlk_hash_j(output_bytes, input_bytes, input_byte_count);
}

__attribute__((noinline)) void baseline_stage_select(uint8_t *destination,
    const uint8_t *source,
    size_t byte_count,
    uint8_t selector)
{
    mlk_ct_cmov_zero(destination, source, byte_count, selector);
}
