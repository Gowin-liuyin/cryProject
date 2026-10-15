#include "inputs.h"
#include "mlkem.h"

#include <inttypes.h>
#include <stdio.h>
#include <string.h>

#if defined(PLATFORM_M5_HAVE_VALGRIND)
#include <valgrind/memcheck.h>
#endif

#define M5_PKE_SECRET_BYTE_COUNT 1152u
#define M5_REJECTION_SECRET_BYTE_COUNT 32u
#define M5_REJECTION_SECRET_OFFSET 2368u

_Static_assert(M5_PKE_SECRET_BYTE_COUNT + MLKEM_ENCAPSULATION_KEY_BYTES + 64u ==
        MLKEM_DECAPSULATION_KEY_BYTES,
    "ML-KEM-768 secret-key layout mismatch");
_Static_assert(M5_REJECTION_SECRET_OFFSET + M5_REJECTION_SECRET_BYTE_COUNT ==
        MLKEM_DECAPSULATION_KEY_BYTES,
    "ML-KEM-768 rejection secret offset mismatch");

static int check_category(uint64_t test_seed, enum input_category category, int is_poisoned)
{
    uint8_t encapsulation_key[MLKEM_ENCAPSULATION_KEY_BYTES];
    uint8_t decapsulation_key[MLKEM_DECAPSULATION_KEY_BYTES];
    uint8_t ciphertext[MLKEM_CIPHERTEXT_BYTES];
    uint8_t ordinary_shared_secret[MLKEM_SHARED_SECRET_BYTES];
    uint8_t checked_shared_secret[MLKEM_SHARED_SECRET_BYTES];
    int status = generate_test_key_pair(test_seed, encapsulation_key, decapsulation_key);
    if (status == 0) {
        status = generate_test_ciphertext(category, test_seed, 0u, encapsulation_key, ciphertext);
    }
    if (status == 0) {
        status = mlkem_decapsulate(ordinary_shared_secret,
            sizeof(ordinary_shared_secret),
            ciphertext,
            sizeof(ciphertext),
            decapsulation_key,
            sizeof(decapsulation_key));
    }
    if (status == 0) {
#if defined(PLATFORM_M5_HAVE_VALGRIND)
        if (is_poisoned) {
            /* 内嵌公开key/hash与公开密文不标；拒绝秘密z同样属于秘密。 */
            VALGRIND_MAKE_MEM_UNDEFINED(decapsulation_key, M5_PKE_SECRET_BYTE_COUNT);
            VALGRIND_MAKE_MEM_UNDEFINED(decapsulation_key + M5_REJECTION_SECRET_OFFSET,
                M5_REJECTION_SECRET_BYTE_COUNT);
        }
#else
        (void)is_poisoned;
#endif
        status = mlkem_decapsulate(checked_shared_secret,
            sizeof(checked_shared_secret),
            ciphertext,
            sizeof(ciphertext),
            decapsulation_key,
            sizeof(decapsulation_key));
#if defined(PLATFORM_M5_HAVE_VALGRIND)
        VALGRIND_MAKE_MEM_DEFINED(decapsulation_key, sizeof(decapsulation_key));
        VALGRIND_MAKE_MEM_DEFINED(checked_shared_secret, sizeof(checked_shared_secret));
        VALGRIND_MAKE_MEM_DEFINED(&status, sizeof(status));
#endif
        if (status == 0 &&
            memcmp(ordinary_shared_secret, checked_shared_secret, sizeof(checked_shared_secret)) !=
                0) {
            status = 1;
        }
    }
    erase_secret_bytes(ordinary_shared_secret, sizeof(ordinary_shared_secret));
    erase_secret_bytes(checked_shared_secret, sizeof(checked_shared_secret));
    erase_secret_bytes(decapsulation_key, sizeof(decapsulation_key));
    if (status != 0) {
        fputs("M5 decapsulation qualification failed\n", stderr);
        return 1;
    }
    printf("seed=%" PRIu64 " class=%s complete_decapsulation=ok\n",
        test_seed,
        input_category_name(category));
    return 0;
}

int main(int argument_count, char **arguments)
{
    if (argument_count != 2 ||
        (strcmp(arguments[1], "--self-test") != 0 && strcmp(arguments[1], "--poison") != 0)) {
        fputs("usage: platform_m5_poison --self-test|--poison\n", stderr);
        return 2;
    }
    int is_poisoned = strcmp(arguments[1], "--poison") == 0;
    if (is_poisoned) {
#if defined(PLATFORM_M5_HAVE_VALGRIND)
        if (RUNNING_ON_VALGRIND == 0u) {
            fputs("secret marking requires an actual Valgrind process\n", stderr);
            return 77;
        }
#else
        fputs("Valgrind client headers were unavailable at build time\n", stderr);
        return 77;
#endif
    }
    if (strcmp(mlkem_implementation_name(), "reference") != 0) {
        fputs("M5 requires the unpatched reference backend\n", stderr);
        return 1;
    }
    const uint64_t test_seeds[] = {UINT64_C(31337), UINT64_C(424242)};
    for (size_t seed_index = 0; seed_index < sizeof(test_seeds) / sizeof(test_seeds[0]);
        ++seed_index) {
        for (unsigned category_index = 0u; category_index < INPUT_CATEGORY_COUNT;
            ++category_index) {
            if (check_category(test_seeds[seed_index],
                    (enum input_category)category_index,
                    is_poisoned) != 0) {
                return 1;
            }
        }
    }
    printf("mode=%s pke_secret_bytes=%u rejection_secret_bytes=%u ciphertext=public\n",
        is_poisoned ? "valgrind_secret_marked" : "functional_only",
        M5_PKE_SECRET_BYTE_COUNT,
        M5_REJECTION_SECRET_BYTE_COUNT);
    return 0;
}
