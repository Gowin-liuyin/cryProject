/* M4 失配位置构造器（T6.2）：给定 position_bytes(0..31)，产出 32 字节输入对，
 * 使 m4_compare_bytes 的首个差异字节恰在该位置；作为本地 L2 恢复演示的 craft 输入源。
 *
 * 本文件同时提供可复用函数与独立 CLI：
 *   - 定义 ADAPTIVE_ENGINE_EMBEDS_CRAFT_INPUTS 时只编译函数（供自适应引擎内嵌）；
 *   - 否则编译 CLI：craft_inputs --position <0..31> 打印 secret/candidate 的十六进制。
 * 退出码：0 成功；1 用法；2 数据。
 */

#include <stddef.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#define CRAFT_INPUT_BYTES 32u
#define CRAFT_INPUT_BASE_BYTE 0x5au
#define CRAFT_EXIT_USAGE 1
#define CRAFT_EXIT_DATA 2

/* secret 与 candidate 除 position_bytes 外逐字节相同；该位置差 1 位。
 * 返回 0 成功，1 参数非法。 */
int craft_input_pair(unsigned position_bytes,
    uint8_t secret_input[CRAFT_INPUT_BYTES],
    uint8_t candidate_input[CRAFT_INPUT_BYTES])
{
    if (position_bytes >= CRAFT_INPUT_BYTES || secret_input == NULL || candidate_input == NULL) {
        return 1;
    }
    memset(secret_input, CRAFT_INPUT_BASE_BYTE, CRAFT_INPUT_BYTES);
    memset(candidate_input, CRAFT_INPUT_BASE_BYTE, CRAFT_INPUT_BYTES);
    candidate_input[position_bytes] ^= 1u;
    return 0;
}

/* 辅助：返回首个差异字节位置；完全相同返回 CRAFT_INPUT_BYTES。 */
unsigned craft_first_difference(const uint8_t secret_input[CRAFT_INPUT_BYTES],
    const uint8_t candidate_input[CRAFT_INPUT_BYTES])
{
    for (unsigned byte_index = 0u; byte_index < CRAFT_INPUT_BYTES; ++byte_index) {
        if (secret_input[byte_index] != candidate_input[byte_index]) {
            return byte_index;
        }
    }
    return CRAFT_INPUT_BYTES;
}

#ifndef ADAPTIVE_ENGINE_EMBEDS_CRAFT_INPUTS

static void print_usage(void)
{
    fputs("usage: craft_inputs --position <0..31>\n", stderr);
}

int main(int argument_count, char **argument_values)
{
    if (argument_count != 3 || strcmp(argument_values[1], "--position") != 0) {
        print_usage();
        return CRAFT_EXIT_USAGE;
    }
    unsigned long position_value = 0u;
    const char *position_text = argument_values[2];
    if (position_text[0] == '\0') {
        return CRAFT_EXIT_USAGE;
    }
    for (const char *cursor = position_text; *cursor != '\0'; ++cursor) {
        if (*cursor < '0' || *cursor > '9') {
            return CRAFT_EXIT_USAGE;
        }
    }
    position_value = strtoul(position_text, NULL, 10);
    if (position_value >= CRAFT_INPUT_BYTES) {
        fprintf(stderr, "error: position must be 0..%u\n", (unsigned)(CRAFT_INPUT_BYTES - 1u));
        return CRAFT_EXIT_DATA;
    }
    uint8_t secret_input[CRAFT_INPUT_BYTES];
    uint8_t candidate_input[CRAFT_INPUT_BYTES];
    if (craft_input_pair((unsigned)position_value, secret_input, candidate_input) != 0) {
        return CRAFT_EXIT_DATA;
    }
    printf("position=%u\n", (unsigned)position_value);
    printf("secret=");
    for (unsigned byte_index = 0u; byte_index < CRAFT_INPUT_BYTES; ++byte_index) {
        printf("%02x", secret_input[byte_index]);
    }
    printf("\ncandidate=");
    for (unsigned byte_index = 0u; byte_index < CRAFT_INPUT_BYTES; ++byte_index) {
        printf("%02x", candidate_input[byte_index]);
    }
    printf("\nfirst_difference=%u\n", craft_first_difference(secret_input, candidate_input));
    return 0;
}

#endif /* ADAPTIVE_ENGINE_EMBEDS_CRAFT_INPUTS */
