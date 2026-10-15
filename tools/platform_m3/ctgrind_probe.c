#include "inputs.h"
#include "mlkem.h"

#include <stdio.h>
#include <string.h>
#include <valgrind/memcheck.h>

#define PLATFORM_M3_PKE_SECRET_BYTES 1152u

int main(int argument_count, char **argument_values)
{
    if (argument_count != 2 ||
        (strcmp(argument_values[1], "--secret") != 0 &&
            strcmp(argument_values[1], "--defined") != 0)) {
        fputs("usage: platform_m3_{on,off}_probe --secret|--defined\n", stderr);
        return 2;
    }
    if (RUNNING_ON_VALGRIND == 0u) {
        fputs("M3 localization probe requires Valgrind\n", stderr);
        return 77;
    }
    int is_secret_probe = strcmp(argument_values[1], "--secret") == 0;
    uint8_t encapsulation_key[MLKEM_ENCAPSULATION_KEY_BYTES];
    uint8_t decapsulation_key[MLKEM_DECAPSULATION_KEY_BYTES];
    uint8_t ciphertext[MLKEM_CIPHERTEXT_BYTES];
    uint8_t shared_secret[MLKEM_SHARED_SECRET_BYTES];
    if (generate_test_key_pair(UINT64_C(20261016), encapsulation_key, decapsulation_key) != 0) {
        return 1;
    }
    for (unsigned category_index = 0; category_index < INPUT_CATEGORY_COUNT; ++category_index) {
        if (generate_test_ciphertext((enum input_category)category_index,
                UINT64_C(20261016),
                0,
                encapsulation_key,
                ciphertext) != 0) {
            return 1;
        }
        if (is_secret_probe) {
            /* 嵌入公钥及其 hash 是公开的，只标记秘密多项式与拒绝种子。 */
            VALGRIND_MAKE_MEM_UNDEFINED(decapsulation_key, PLATFORM_M3_PKE_SECRET_BYTES);
            VALGRIND_MAKE_MEM_UNDEFINED(decapsulation_key + sizeof(decapsulation_key) - 32u, 32u);
        }
        int decapsulation_status = mlkem_decapsulate(shared_secret,
            sizeof(shared_secret),
            ciphertext,
            sizeof(ciphertext),
            decapsulation_key,
            sizeof(decapsulation_key));
        VALGRIND_MAKE_MEM_DEFINED(decapsulation_key, sizeof(decapsulation_key));
        VALGRIND_MAKE_MEM_DEFINED(shared_secret, sizeof(shared_secret));
        if (decapsulation_status != 0) {
            return 1;
        }
    }
    printf("module=artificial_m3_full_decapsulation implementation=%s marking=%s completed=5\n",
        mlkem_implementation_name(),
        is_secret_probe ? "secret" : "defined");
    return 0;
}
