#include "inputs.h"
#include "mlkem.h"

#include <stdio.h>
#include <stdlib.h>

/* 公开固定测试种子：与 platform_m3 探针一致，不含任何运行期真实密钥。 */
#define M3_MW_PUBLIC_TEST_SEED UINT64_C(20261016)

static uint8_t m3_encapsulation_key[MLKEM_ENCAPSULATION_KEY_BYTES];
static uint8_t m3_decapsulation_key[MLKEM_DECAPSULATION_KEY_BYTES];
static uint8_t m3_ciphertext[MLKEM_CIPHERTEXT_BYTES];
static uint8_t m3_shared_secret[MLKEM_SHARED_SECRET_BYTES];

extern void InitTarget(FILE *input)
{
    (void)input;
    if (generate_test_key_pair(M3_MW_PUBLIC_TEST_SEED, m3_encapsulation_key, m3_decapsulation_key) != 0) {
        exit(1);
    }
}

extern void RunTarget(FILE *input)
{
    uint8_t category_byte = 0u;
    if (fread(&category_byte, 1u, 1u, input) != 1u) {
        exit(1);
    }
    unsigned category_index = (unsigned)category_byte % INPUT_CATEGORY_COUNT;
    if (generate_test_ciphertext((enum input_category)category_index,
            M3_MW_PUBLIC_TEST_SEED,
            0,
            m3_encapsulation_key,
            m3_ciphertext) != 0) {
        exit(1);
    }
    int decapsulation_status = mlkem_decapsulate(m3_shared_secret,
        sizeof(m3_shared_secret),
        m3_ciphertext,
        sizeof(m3_ciphertext),
        m3_decapsulation_key,
        sizeof(m3_decapsulation_key));
    if (decapsulation_status != 0) {
        exit(1);
    }
}
