#include "compare.h"

int m4_compare_bytes(const uint8_t *secret_bytes,
    const uint8_t *candidate_bytes,
    size_t compare_length_bytes)
{
    unsigned int difference_bits = 0;
    for (size_t byte_index = 0; byte_index < compare_length_bytes; byte_index++) {
        difference_bits |= (unsigned int)(secret_bytes[byte_index] ^ candidate_bytes[byte_index]);
    }
    return difference_bits == 0;
}
