/* R24 Binsec 扩面 harness：从 mlkem-native 抽取 `mlk_ct_cmov_zero` 的常数时间选择路径，
 * 供 Binsec `-checkct` 做**有界**控制流/访存检查（不是恒时证明）。
 *
 * 抽取来源：vendor/mlkem-native/mlkem/src/verify.h
 *   `mlk_ct_sel_uint8()` / `mlk_ct_cmov_zero()`（MIT/Apache-2.0，见 vendored 原文件）。
 * 为 32 位 freestanding 分析去掉了 `__contract__`/`MLK_INLINE` 宏，逻辑逐字保留。
 * 本地只做源码语法级检查，不链接；运行命令与判据见
 * docs/research/r24-binsec-ext-20261116/PLAN.md。
 */

#include <stddef.h>
#include <stdint.h>

#define PLATFORM_M4_FORMAL_BYTES 16U

uint8_t m4_cmov_secret_bytes[PLATFORM_M4_FORMAL_BYTES];
uint8_t m4_cmov_public_bytes[PLATFORM_M4_FORMAL_BYTES];
uint8_t m4_cmov_output_bytes[PLATFORM_M4_FORMAL_BYTES];
uint8_t m4_cmov_condition_secret;
size_t m4_cmov_length = PLATFORM_M4_FORMAL_BYTES;
volatile int m4_cmov_observed_result;

/* 来自 mlk_ct_sel_uint8：按 b 选 r0/r1 的常数时间选择（b=0/1 语义）。 */
static uint8_t platform_m4_ct_sel_uint8(uint8_t first_value, uint8_t second_value,
    uint8_t condition_value)
{
    uint8_t condition_mask = (uint8_t)(0u - (uint8_t)condition_value);
    return (uint8_t)((first_value & (uint8_t)~condition_mask) |
                     (second_value & condition_mask));
}

/* 来自 mlk_ct_cmov_zero：b==0 时把 x 复制到 r，否则保持 r；无数据相关分支。 */
static void platform_m4_ct_cmov_zero(uint8_t *output,
    const uint8_t *input,
    size_t byte_count,
    uint8_t condition_value)
{
    for (size_t byte_index = 0u; byte_index < byte_count; ++byte_index) {
        output[byte_index] =
            platform_m4_ct_sel_uint8(output[byte_index], input[byte_index], condition_value);
    }
}

__attribute__((noinline)) _Noreturn void m4_cmov_halt(int selected)
{
    m4_cmov_observed_result = selected;
    __builtin_trap();
}

void m4_cmov_entry(void)
{
    platform_m4_ct_cmov_zero(m4_cmov_output_bytes,
        m4_cmov_secret_bytes,
        m4_cmov_length,
        m4_cmov_condition_secret);
    m4_cmov_halt(m4_cmov_output_bytes[0] == m4_cmov_public_bytes[0]);
}
