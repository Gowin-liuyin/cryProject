#include "compare.h"

int m4_compare_bytes(const uint8_t *secret_bytes,
    const uint8_t *candidate_bytes,
    size_t compare_length_bytes)
{
    for (size_t byte_index = 0; byte_index < compare_length_bytes; byte_index++) {
        /* 人工保留秘密相关提前退出，作为比较机制阳性夹具。 */
        if (secret_bytes[byte_index] != candidate_bytes[byte_index]) {
            return 0;
        }
    }
    return 1;
}
