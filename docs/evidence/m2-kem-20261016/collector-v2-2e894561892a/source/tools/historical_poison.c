#define _POSIX_C_SOURCE 200809L

#include "inputs.h"
#include "mlkem.h"

#include <stdint.h>
#include <stdio.h>
#include <valgrind/memcheck.h>

/*
 * 用 Valgrind 客户端请求把解封装私钥标成未初始化。
 * 不修改 vendor 树。ct_poison 需要打过补丁的 Valgrind；
 * 这里用的是发行版 memcheck 已经提供的同一类请求。
 */

static int decapsulate_poisoned(enum input_category category)
{
    uint8_t encapsulation_key[MLKEM_ENCAPSULATION_KEY_BYTES];
    uint8_t decapsulation_key[MLKEM_DECAPSULATION_KEY_BYTES];
    uint8_t ciphertext[MLKEM_CIPHERTEXT_BYTES];
    uint8_t shared_secret[MLKEM_SHARED_SECRET_BYTES];
    int operation_status;

    if (generate_test_key_pair(31337ull, encapsulation_key, decapsulation_key) != 0) {
        return 1;
    }
    if (generate_test_ciphertext(category, 31337ull, 0, encapsulation_key, ciphertext) != 0) {
        return 1;
    }
    /* k=3 时 indcpa 私钥是 384*3 字节。后面的公开封装密钥不标，
     * 否则 gen_at 的公开种子也会被当成秘密。 */
    VALGRIND_MAKE_MEM_UNDEFINED(decapsulation_key, 1152u);
    operation_status = mlkem_decapsulate(shared_secret,
        sizeof(shared_secret),
        ciphertext,
        sizeof(ciphertext),
        decapsulation_key,
        sizeof(decapsulation_key));
    VALGRIND_MAKE_MEM_DEFINED(decapsulation_key, sizeof(decapsulation_key));
    VALGRIND_MAKE_MEM_DEFINED(shared_secret, sizeof(shared_secret));
    erase_secret_bytes(shared_secret, sizeof(shared_secret));
    erase_secret_bytes(decapsulation_key, sizeof(decapsulation_key));
    printf("class=%s status=%d\n", input_category_name(category), operation_status);
    return operation_status == 0 ? 0 : 1;
}

int main(void)
{
    int operation_status;

    operation_status = decapsulate_poisoned(INPUT_MESSAGE_ZERO);
    if (operation_status != 0) {
        return operation_status;
    }
    return decapsulate_poisoned(INPUT_MESSAGE_ONES);
}
