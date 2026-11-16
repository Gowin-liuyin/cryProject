/* victim_backend_m3：M3 LUT 人工校准臂的观测者后端。
 * 链接 platform_m3_<mode>_kernel（mlkem-native 覆盖层 + 对应补丁），与
 * platform-m3/<mode>/measure 同一实现路径；类别密文用 inputs 模块的
 * message-zero /message-ones 固定种子入口构造（窗口外），窗口内只做一次
 * mlkem_decapsulate。shared-on 臂的共享 LUT 由内核里的 constructor 按
 * PLATFORM_M3_SHARED_LUT_PATH 建立，不经过本后端。 */

#include "victim_backend.h"

#include "inputs.h"
#include "mlkem.h"

static uint8_t m3_encapsulation_key[MLKEM_ENCAPSULATION_KEY_BYTES];
static uint8_t m3_decapsulation_key[MLKEM_DECAPSULATION_KEY_BYTES];
static uint8_t m3_ciphertext_zero[MLKEM_CIPHERTEXT_BYTES];
static uint8_t m3_ciphertext_ones[MLKEM_CIPHERTEXT_BYTES];

const char *victim_backend_name(void)
{
#ifdef PLATFORM_M3_LUT_LEAK
    #ifdef PLATFORM_M3_SHARED_LUT
        return "m3-shared-on";
    #else
        return "m3-on";
    #endif
#else
    return "m3-off";
#endif
}

int victim_backend_prepare(uint64_t test_seed)
{
    if (generate_test_key_pair(test_seed, m3_encapsulation_key, m3_decapsulation_key) != 0) {
        return 1;
    }
    if (generate_test_ciphertext(INPUT_MESSAGE_ZERO,
            test_seed,
            0,
            m3_encapsulation_key,
            m3_ciphertext_zero)
        != 0) {
        return 1;
    }
    if (generate_test_ciphertext(INPUT_MESSAGE_ONES,
            test_seed,
            0,
            m3_encapsulation_key,
            m3_ciphertext_ones)
        != 0) {
        return 1;
    }
    return 0;
}

int victim_backend_decapsulate_once(int class_is_ones,
    uint8_t shared_secret[VICTIM_SHARED_SECRET_BYTES])
{
    const uint8_t *ciphertext = (class_is_ones != 0) ? m3_ciphertext_ones : m3_ciphertext_zero;
    int decapsulation_status = mlkem_decapsulate(shared_secret,
        VICTIM_SHARED_SECRET_BYTES,
        ciphertext,
        MLKEM_CIPHERTEXT_BYTES,
        m3_decapsulation_key,
        MLKEM_DECAPSULATION_KEY_BYTES);
    return decapsulation_status == 0 ? 0 : 1;
}
