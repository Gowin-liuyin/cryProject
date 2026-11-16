/* R24 Binsec 扩面 harness：KDF 循环边界（absorb 速率边界）的常数时间检查载体。
 * 抽取/简化自 mlkem-native SHAKE-256 absorb 的"按 rate 分块"循环边界（SHAKE256 rate=168 B）：
 * 长度是公开常量，秘密只出现在被吸收的字节内容里；Binsec 检查控制流/访存是否依赖秘密。
 * 本地只做源码语法级检查，不链接；运行命令与判据见
 * docs/research/r24-binsec-ext-20261116/PLAN.md。
 */

#include <stddef.h>
#include <stdint.h>

#define PLATFORM_M4_KDF_RATE_BYTES 168U
#define PLATFORM_M4_KDF_INPUT_BYTES 200U

uint8_t m4_kdf_secret_bytes[PLATFORM_M4_KDF_INPUT_BYTES];
uint8_t m4_kdf_public_bytes[PLATFORM_M4_KDF_INPUT_BYTES];
uint64_t m4_kdf_state_words[25];
size_t m4_kdf_length = PLATFORM_M4_KDF_INPUT_BYTES;
volatile int m4_kdf_observed_result;

/* 简化 absorb 前缀：按公开 rate 分块与尾部循环，循环边界全部由公开长度决定。 */
static void platform_m4_kdf_absorb_prefix(uint64_t state_words[25],
    const uint8_t *input_bytes,
    size_t input_byte_count)
{
    size_t absorbed_byte_count = 0u;
    for (size_t byte_index = 0u; byte_index < input_byte_count; ++byte_index) {
        state_words[0] ^= input_bytes[byte_index];
    }
    while (absorbed_byte_count + PLATFORM_M4_KDF_RATE_BYTES <= input_byte_count) {
        absorbed_byte_count += PLATFORM_M4_KDF_RATE_BYTES;
    }
    for (size_t byte_index = absorbed_byte_count; byte_index < input_byte_count; ++byte_index) {
        state_words[1] ^= input_bytes[byte_index];
    }
}

__attribute__((noinline)) _Noreturn void m4_kdf_halt(uint64_t selected_word)
{
    m4_kdf_observed_result = (int)(selected_word & 0x1u);
    __builtin_trap();
}

void m4_kdf_entry(void)
{
    platform_m4_kdf_absorb_prefix(m4_kdf_state_words, m4_kdf_secret_bytes, m4_kdf_length);
    m4_kdf_halt(m4_kdf_state_words[0] ^ m4_kdf_public_bytes[0]);
}
