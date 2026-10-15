#include "compare.h"

#include <stdio.h>
#include <string.h>

int m4_self_test(void)
{
    uint8_t secret_bytes[M4_COMPARE_BYTES];
    uint8_t candidate_bytes[M4_COMPARE_BYTES];
    for (size_t byte_index = 0; byte_index < M4_COMPARE_BYTES; byte_index++) {
        secret_bytes[byte_index] = (uint8_t)(byte_index * 7U);
    }

    for (size_t compare_length_bytes = 0; compare_length_bytes <= M4_COMPARE_BYTES;
        compare_length_bytes++) {
        memcpy(candidate_bytes, secret_bytes, M4_COMPARE_BYTES);
        if (m4_compare_bytes(secret_bytes, candidate_bytes, compare_length_bytes) != 1) {
            return 1;
        }
        for (size_t difference_index = 0; difference_index < compare_length_bytes;
            difference_index++) {
            for (unsigned int replacement_byte = 0; replacement_byte <= UINT8_MAX;
                replacement_byte++) {
                candidate_bytes[difference_index] = (uint8_t)replacement_byte;
                int expected_equal =
                    memcmp(secret_bytes, candidate_bytes, compare_length_bytes) == 0;
                if (m4_compare_bytes(secret_bytes, candidate_bytes, compare_length_bytes) !=
                    expected_equal) {
                    return 1;
                }
            }
            candidate_bytes[difference_index] = secret_bytes[difference_index];
        }
    }

    int is_equal = -7;
    if (m4_compare_checked(secret_bytes,
            M4_COMPARE_BYTES,
            secret_bytes,
            M4_COMPARE_BYTES,
            &is_equal) != 0 ||
        is_equal != 1) {
        return 1;
    }
    memcpy(candidate_bytes, secret_bytes, M4_COMPARE_BYTES);
    candidate_bytes[M4_COMPARE_BYTES - 1U] ^= UINT8_C(1);
    if (m4_compare_checked(secret_bytes,
            M4_COMPARE_BYTES,
            candidate_bytes,
            M4_COMPARE_BYTES,
            &is_equal) != 0 ||
        is_equal != 0) {
        return 1;
    }

    uint8_t short_bytes[M4_COMPARE_BYTES - 1U] = {0};
    is_equal = -7;
    if (m4_compare_checked(NULL, M4_COMPARE_BYTES, candidate_bytes, M4_COMPARE_BYTES, &is_equal) !=
            -1 ||
        m4_compare_checked(secret_bytes, M4_COMPARE_BYTES, NULL, M4_COMPARE_BYTES, &is_equal) !=
            -1 ||
        m4_compare_checked(secret_bytes,
            M4_COMPARE_BYTES,
            candidate_bytes,
            M4_COMPARE_BYTES,
            NULL) != -1 ||
        m4_compare_checked(short_bytes,
            sizeof(short_bytes),
            candidate_bytes,
            M4_COMPARE_BYTES,
            &is_equal) != -1 ||
        m4_compare_checked(secret_bytes,
            M4_COMPARE_BYTES,
            short_bytes,
            sizeof(short_bytes),
            &is_equal) != -1 ||
        m4_compare_checked(secret_bytes, 0, candidate_bytes, M4_COMPARE_BYTES, &is_equal) != -1 ||
        m4_compare_checked(secret_bytes, M4_COMPARE_BYTES, candidate_bytes, SIZE_MAX, &is_equal) !=
            -1 ||
        is_equal != -7) {
        return 1;
    }
    puts("artificial_fixture=yes oracle=libc_memcmp equality_and_length_checks=pass");
    return 0;
}
