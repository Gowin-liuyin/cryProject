#include "inputs.h"
#include "mlkem.h"
#include "src/fips202/fips202.h"

#include <stdio.h>
#include <string.h>

int main(void)
{
    uint8_t encapsulation_key[MLKEM_ENCAPSULATION_KEY_BYTES];
    uint8_t decapsulation_key[MLKEM_DECAPSULATION_KEY_BYTES];
    uint8_t ciphertext[MLKEM_CIPHERTEXT_BYTES];
    uint8_t shared_secret[MLKEM_SHARED_SECRET_BYTES];
    uint8_t rejection_input[MLKEM_SHARED_SECRET_BYTES + MLKEM_CIPHERTEXT_BYTES];
    uint8_t rejection_secret[MLKEM_SHARED_SECRET_BYTES];
    for (uint64_t public_test_seed = 0; public_test_seed < 64u; ++public_test_seed) {
        if (generate_test_key_pair(public_test_seed, encapsulation_key, decapsulation_key) != 0) {
            return 1;
        }
        for (unsigned category_index = 0; category_index < INPUT_CATEGORY_COUNT; ++category_index) {
            enum input_category category = (enum input_category)category_index;
            if (generate_test_ciphertext(category,
                    public_test_seed,
                    public_test_seed,
                    encapsulation_key,
                    ciphertext) != 0 ||
                mlkem_decapsulate(shared_secret,
                    sizeof(shared_secret),
                    ciphertext,
                    sizeof(ciphertext),
                    decapsulation_key,
                    sizeof(decapsulation_key)) != 0) {
                return 1;
            }
            if (category == INPUT_BIT_FLIPPED || category == INPUT_RANDOM) {
                memcpy(rejection_input, decapsulation_key + sizeof(decapsulation_key) - 32u, 32u);
                memcpy(rejection_input + 32u, ciphertext, sizeof(ciphertext));
                mlk_shake256(rejection_secret,
                    sizeof(rejection_secret),
                    rejection_input,
                    sizeof(rejection_input));
                if (memcmp(shared_secret, rejection_secret, sizeof(shared_secret)) != 0) {
                    return 1;
                }
            }
            /* 只为公开种子的 CTest 转录逐字比较，不接收或输出实际运行秘密。 */
            if (fwrite(encapsulation_key, 1, sizeof(encapsulation_key), stdout) !=
                    sizeof(encapsulation_key) ||
                fwrite(decapsulation_key, 1, sizeof(decapsulation_key), stdout) !=
                    sizeof(decapsulation_key) ||
                fwrite(ciphertext, 1, sizeof(ciphertext), stdout) != sizeof(ciphertext) ||
                fwrite(shared_secret, 1, sizeof(shared_secret), stdout) != sizeof(shared_secret)) {
                return 1;
            }
        }
    }
    return fflush(stdout) == 0 ? 0 : 1;
}
