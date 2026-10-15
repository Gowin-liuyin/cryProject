#include "compare.h"

#define PLATFORM_M4_FORMAL_BYTES 16U

uint8_t m4_secret_input[PLATFORM_M4_FORMAL_BYTES];
uint8_t m4_public_input[PLATFORM_M4_FORMAL_BYTES];
size_t m4_public_length = PLATFORM_M4_FORMAL_BYTES;
volatile int m4_observed_result;

__attribute__((noinline)) _Noreturn void m4_halt(int is_equal)
{
    m4_observed_result = is_equal;
    __builtin_trap();
}

void m4_entry(void)
{
    int is_equal = m4_compare_bytes(m4_secret_input, m4_public_input, m4_public_length);
    /* 分析在 m4_halt 入口结束，允许比较返回值而不执行消费代码。 */
    m4_halt(is_equal);
}
