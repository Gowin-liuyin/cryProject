/* 独立复算：用 TOML 反例里的公开输入与两个秘密各跑同一内核，比较执行路径。
 * 反复调用以放大提前退出造成的动态指令数差异；不改变夹具语义。 */
#include "compare.h"

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

static int decode_hex(const char *text, unsigned char *bytes, size_t byte_count)
{
    if (strlen(text) != byte_count * 2U) {
        return 1;
    }
    for (size_t byte_index = 0U; byte_index < byte_count; byte_index++) {
        unsigned int decoded = 0U;
        if (sscanf(text + byte_index * 2U, "%2x", &decoded) != 1) {
            return 1;
        }
        bytes[byte_index] = (unsigned char)decoded;
    }
    return 0;
}

int main(int argc, char **argv)
{
    if (argc != 5) {
        fprintf(stderr, "usage: %s SECRET_HEX PUBLIC_HEX COMPARE_LENGTH ITERATIONS\n", argv[0]);
        return 2;
    }
    unsigned char secret_bytes[M4_COMPARE_BYTES];
    unsigned char public_bytes[M4_COMPARE_BYTES];
    if (decode_hex(argv[1], secret_bytes, M4_COMPARE_BYTES) != 0 ||
        decode_hex(argv[2], public_bytes, M4_COMPARE_BYTES) != 0) {
        fprintf(stderr, "need %u hex chars per array\n", M4_COMPARE_BYTES * 2U);
        return 2;
    }
    size_t compare_length = (size_t)strtoul(argv[3], NULL, 10);
    unsigned long iteration_count = strtoul(argv[4], NULL, 10);
    if (compare_length > M4_COMPARE_BYTES || iteration_count == 0UL) {
        return 2;
    }
    static volatile unsigned int result_sum = 0U;
    for (unsigned long iteration = 0UL; iteration < iteration_count; iteration++) {
        result_sum += (unsigned int)m4_compare_bytes(secret_bytes, public_bytes, compare_length);
    }
    /* 常量输出：格式化的指令数不随秘密变化，动态计数差异只能来自内核路径。 */
    printf("replay done\n");
    return 0;
}
