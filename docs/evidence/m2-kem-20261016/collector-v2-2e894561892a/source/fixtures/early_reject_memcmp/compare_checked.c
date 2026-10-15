#include "compare.h"

int m4_compare_checked(const uint8_t *secret_bytes,
    size_t secret_length_bytes,
    const uint8_t *candidate_bytes,
    size_t candidate_length_bytes,
    int *is_equal)
{
    if (secret_bytes == NULL || candidate_bytes == NULL || is_equal == NULL ||
        secret_length_bytes != M4_COMPARE_BYTES || candidate_length_bytes != M4_COMPARE_BYTES) {
        return -1;
    }
    *is_equal = m4_compare_bytes(secret_bytes, candidate_bytes, M4_COMPARE_BYTES);
    return 0;
}
