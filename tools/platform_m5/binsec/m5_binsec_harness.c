/* M5 重加密路径的 Binsec checkct 裸机驱动（i386）。
 *
 * 目的：把 M5 参考实现里「重加密」路径上的两个步骤放进 Binsec 能分析的形态，
 * 用显式 `secret global` 声明秘密数据，检验**控制流**是否依赖秘密。
 *
 * 两个目标（分别编译成两个 ELF）：
 *
 *   m5_frommsg  —— 消息编码步骤 `mlk_poly_frommsg`（来自 mlkem-native 的
 *                  compress.c，未改动 vendor 原件）。秘密 = 32 字节消息。
 *                  这一步是 R05 §5 登记为 unknown 的那一步：R05 的理由是
 *                  「每个消息位都会分叉，路径数达 2^256 量级」。本驱动不预设
 *                  该前提成立与否——若 i386 产物里没有秘密相关分支，路径数就是
 *                  1，模型覆盖**完整步骤**；若确有分支，路径数会如实爆炸，
 *                  结论按 unknown 登记并附实测路径数。
 *
 *   m5_compare  —— FO 重加密的**比较**步骤 `mlk_ct_memcmp`（mlkem-native
 *                  verify.h 里的静态内联）。秘密 = 重加密出的密文（由秘密密钥
 *                  导出），公开 = 收到的密文与比较长度。经典 FO 侧信道就出在
 *                  「比较提前退出」，所以这一步是 checkct 的目标。
 *
 * 约束：
 *   * 只用仓库自有的测试夹具与 vendor 原件，不做密钥恢复、不产出 exploit。
 *   * 驱动本身不实现密码学，只调用被测实现；秘密/公开的划分写在 Binsec 配置里。
 *   * 入口 m5_entry 是分析起点，m5_halt 是分析终点（与 M4 夹具同一约定）。
 */
#define MLK_BUILD_INTERNAL

#include "common.h"
#include "params.h"
#include "poly.h"
#include "verify.h"
#if defined(M5_BINSEC_TARGET_FROMMSG)
#include "compress.h"
#endif

#if defined(M5_BINSEC_TARGET_FROMMSG)
/* 消息编码：秘密是 32 字节消息，输出系数是公开的接收方无关量。 */
uint8_t m5_secret_message[MLKEM_INDCPA_MSGBYTES];
mlk_poly m5_public_coefficients;
#else
/* FO 比较：秘密是重加密出的密文，公开的是收到的密文与比较长度。 */
uint8_t m5_secret_reencrypted[MLKEM_INDCCA_CIPHERTEXTBYTES];
uint8_t m5_public_ciphertext[MLKEM_INDCCA_CIPHERTEXTBYTES];
size_t m5_public_length = MLKEM_INDCCA_CIPHERTEXTBYTES;
#endif

volatile int m5_observed_result;

__attribute__((noinline)) _Noreturn void m5_halt(int observed)
{
    m5_observed_result = observed;
    __builtin_trap();
}

void m5_entry(void)
{
#if defined(M5_BINSEC_TARGET_FROMMSG)
    mlk_poly_frommsg(&m5_public_coefficients, m5_secret_message);
    /* 系数是消息的函数；分析在 m5_halt 入口结束，不把允许的输出公开混入路径性质。 */
    m5_halt(0);
#else
    int is_equal = mlk_ct_memcmp(m5_public_ciphertext, m5_secret_reencrypted, m5_public_length);
    m5_halt(is_equal);
#endif
}
