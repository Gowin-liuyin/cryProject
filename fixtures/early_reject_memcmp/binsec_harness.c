#include "compare.h"

#include <stdlib.h>

#define M4_BINSEC_BYTES 16U

uint8_t m4_secret_input[M4_BINSEC_BYTES];
uint8_t m4_public_input[M4_BINSEC_BYTES];
size_t m4_public_length = M4_BINSEC_BYTES;

int main(void)
{
    int is_equal = m4_compare_bytes(m4_secret_input, m4_public_input, m4_public_length);
    /* Binsec 在 exit 入口停止，避免把允许的返回值公开混入路径性质。 */
    exit(is_equal);
}
