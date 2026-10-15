#define _POSIX_C_SOURCE 200809L

#include "build_identity.h"

#include <ctype.h>
#include <errno.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/wait.h>
#include <unistd.h>

/* 三类机制只根据本次编译产物的指令归类。
 * 循环边界、公开错误返回和栈保护比较不算秘密依赖控制流。
 * 除法只在消息编码或压缩函数里计数；常数乘法约减不是 KyberSlash。
 */

#define MECHANISM_MAX_FUNCTIONS 512u
#define MECHANISM_MAX_INSTRUCTIONS 200000u

struct mechanism_instruction {
    uint64_t address;
    char mnemonic[24];
    char operands[256];
};

struct mechanism_function {
    char name[160];
    struct mechanism_instruction *instructions;
    size_t instruction_count;
};

struct mechanism_program {
    struct mechanism_function *functions;
    size_t function_count;
};

struct mechanism_branch_counts {
    int division_instructions;
    int secret_conditional_branches;
    int loop_bound_branches;
    int public_error_branches;
    int canary_branches;
};

static uint32_t mechanism_rotr(uint32_t value, unsigned shift)
{
    return (value >> shift) | (value << (32u - shift));
}

static void mechanism_sha256_block(uint32_t state[8], const uint8_t block[64])
{
    static const uint32_t round_constants[64] = {0x428a2f98u,
        0x71374491u,
        0xb5c0fbcfu,
        0xe9b5dba5u,
        0x3956c25bu,
        0x59f111f1u,
        0x923f82a4u,
        0xab1c5ed5u,
        0xd807aa98u,
        0x12835b01u,
        0x243185beu,
        0x550c7dc3u,
        0x72be5d74u,
        0x80deb1feu,
        0x9bdc06a7u,
        0xc19bf174u,
        0xe49b69c1u,
        0xefbe4786u,
        0x0fc19dc6u,
        0x240ca1ccu,
        0x2de92c6fu,
        0x4a7484aau,
        0x5cb0a9dcu,
        0x76f988dau,
        0x983e5152u,
        0xa831c66du,
        0xb00327c8u,
        0xbf597fc7u,
        0xc6e00bf3u,
        0xd5a79147u,
        0x06ca6351u,
        0x14292967u,
        0x27b70a85u,
        0x2e1b2138u,
        0x4d2c6dfcu,
        0x53380d13u,
        0x650a7354u,
        0x766a0abbu,
        0x81c2c92eu,
        0x92722c85u,
        0xa2bfe8a1u,
        0xa81a664bu,
        0xc24b8b70u,
        0xc76c51a3u,
        0xd192e819u,
        0xd6990624u,
        0xf40e3585u,
        0x106aa070u,
        0x19a4c116u,
        0x1e376c08u,
        0x2748774cu,
        0x34b0bcb5u,
        0x391c0cb3u,
        0x4ed8aa4au,
        0x5b9cca4fu,
        0x682e6ff3u,
        0x748f82eeu,
        0x78a5636fu,
        0x84c87814u,
        0x8cc70208u,
        0x90befffau,
        0xa4506cebu,
        0xbef9a3f7u,
        0xc67178f2u};
    uint32_t words[64];
    unsigned round_index;
    for (round_index = 0; round_index < 16u; ++round_index) {
        words[round_index] = ((uint32_t)block[round_index * 4u] << 24) |
            ((uint32_t)block[round_index * 4u + 1u] << 16) |
            ((uint32_t)block[round_index * 4u + 2u] << 8) | (uint32_t)block[round_index * 4u + 3u];
    }
    for (round_index = 16; round_index < 64u; ++round_index) {
        uint32_t small_sigma0 = mechanism_rotr(words[round_index - 15u], 7) ^
            mechanism_rotr(words[round_index - 15u], 18) ^ (words[round_index - 15u] >> 3);
        uint32_t small_sigma1 = mechanism_rotr(words[round_index - 2u], 17) ^
            mechanism_rotr(words[round_index - 2u], 19) ^ (words[round_index - 2u] >> 10);
        words[round_index] =
            words[round_index - 16u] + small_sigma0 + words[round_index - 7u] + small_sigma1;
    }
    uint32_t a = state[0];
    uint32_t b = state[1];
    uint32_t c = state[2];
    uint32_t d = state[3];
    uint32_t e = state[4];
    uint32_t f = state[5];
    uint32_t g = state[6];
    uint32_t h = state[7];
    for (round_index = 0; round_index < 64u; ++round_index) {
        uint32_t upper_sigma1 =
            mechanism_rotr(e, 6) ^ mechanism_rotr(e, 11) ^ mechanism_rotr(e, 25);
        uint32_t choice = (e & f) ^ ((~e) & g);
        uint32_t temp1 =
            h + upper_sigma1 + choice + round_constants[round_index] + words[round_index];
        uint32_t upper_sigma0 =
            mechanism_rotr(a, 2) ^ mechanism_rotr(a, 13) ^ mechanism_rotr(a, 22);
        uint32_t majority = (a & b) ^ (a & c) ^ (b & c);
        uint32_t temp2 = upper_sigma0 + majority;
        h = g;
        g = f;
        f = e;
        e = d + temp1;
        d = c;
        c = b;
        b = a;
        a = temp1 + temp2;
    }
    state[0] += a;
    state[1] += b;
    state[2] += c;
    state[3] += d;
    state[4] += e;
    state[5] += f;
    state[6] += g;
    state[7] += h;
}

static int mechanism_sha256_file(const char *path, char hex_out[65])
{
    FILE *input = fopen(path, "rb");
    uint32_t state[8] = {0x6a09e667u,
        0xbb67ae85u,
        0x3c6ef372u,
        0xa54ff53au,
        0x510e527fu,
        0x9b05688cu,
        0x1f83d9abu,
        0x5be0cd19u};
    uint8_t block[64];
    size_t filled = 0;
    uint64_t message_bytes = 0;
    uint64_t bit_length;
    unsigned byte_index;
    if (input == NULL) {
        return 1;
    }
    while (1) {
        size_t room = sizeof(block) - filled;
        size_t read_count = fread(block + filled, 1, room, input);
        if (ferror(input)) {
            (void)fclose(input);
            return 1;
        }
        filled += read_count;
        message_bytes += (uint64_t)read_count;
        if (filled == sizeof(block)) {
            mechanism_sha256_block(state, block);
            filled = 0;
        }
        if (read_count == 0 || feof(input)) {
            break;
        }
    }
    if (fclose(input) != 0) {
        return 1;
    }
    bit_length = message_bytes * 8u;
    block[filled++] = 0x80u;
    if (filled > 56u) {
        while (filled < 64u) {
            block[filled++] = 0;
        }
        mechanism_sha256_block(state, block);
        filled = 0;
    }
    while (filled < 56u) {
        block[filled++] = 0;
    }
    for (byte_index = 0; byte_index < 8u; ++byte_index) {
        block[56u + byte_index] = (uint8_t)(bit_length >> (56u - 8u * byte_index));
    }
    mechanism_sha256_block(state, block);
    for (byte_index = 0; byte_index < 8u; ++byte_index) {
        (void)sprintf(hex_out + byte_index * 8u, "%08x", state[byte_index]);
    }
    hex_out[64] = '\0';
    return 0;
}

static int mechanism_sha256_self_check(void)
{
    uint32_t state[8] = {0x6a09e667u,
        0xbb67ae85u,
        0x3c6ef372u,
        0xa54ff53au,
        0x510e527fu,
        0x9b05688cu,
        0x1f83d9abu,
        0x5be0cd19u};
    uint8_t block[64] = {0};
    char hex_out[65];
    unsigned byte_index;
    block[0] = 0x80u;
    mechanism_sha256_block(state, block);
    for (byte_index = 0; byte_index < 8u; ++byte_index) {
        (void)sprintf(hex_out + byte_index * 8u, "%08x", state[byte_index]);
    }
    hex_out[64] = '\0';
    return strcmp(hex_out, "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855") == 0
        ? 0
        : 1;
}

static const char *mechanism_skip_space(const char *text)
{
    while (*text == ' ' || *text == '\t' || *text == '\r') {
        ++text;
    }
    return text;
}

static int mechanism_hex_value(char character)
{
    if (character >= '0' && character <= '9') {
        return character - '0';
    }
    if (character >= 'a' && character <= 'f') {
        return character - 'a' + 10;
    }
    if (character >= 'A' && character <= 'F') {
        return character - 'A' + 10;
    }
    return -1;
}

static int mechanism_parse_hex_token(const char *text, uint64_t *value, const char **rest)
{
    const char *cursor = text;
    uint64_t parsed = 0;
    int digits = 0;
    if (cursor[0] == '0' && (cursor[1] == 'x' || cursor[1] == 'X')) {
        cursor += 2;
    }
    while (mechanism_hex_value(*cursor) >= 0) {
        parsed = (parsed << 4) | (uint64_t)mechanism_hex_value(*cursor);
        ++cursor;
        ++digits;
    }
    if (digits == 0) {
        return 1;
    }
    *value = parsed;
    *rest = cursor;
    return 0;
}

static int mechanism_token_is_raw_byte(const char *token)
{
    size_t length = strlen(token);
    size_t index;
    if (length != 2u && length != 8u) {
        return 0;
    }
    for (index = 0; index < length; ++index) {
        if (mechanism_hex_value(token[index]) < 0) {
            return 0;
        }
    }
    return 1;
}

static void mechanism_normalize_symbol(const char *raw_name, char *name, size_t capacity)
{
    const char *cursor = raw_name;
    if (cursor[0] == '_' && cursor[1] != '\0') {
        ++cursor;
    }
    (void)snprintf(name, capacity, "%s", cursor);
}

static int mechanism_is_division(const char *mnemonic)
{
    return strcmp(mnemonic, "div") == 0 || strcmp(mnemonic, "idiv") == 0 ||
        strcmp(mnemonic, "udiv") == 0 || strcmp(mnemonic, "sdiv") == 0 ||
        strcmp(mnemonic, "divw") == 0 || strcmp(mnemonic, "divuw") == 0 ||
        strcmp(mnemonic, "udivw") == 0 || strcmp(mnemonic, "sdivw") == 0;
}

static int mechanism_is_conditional_branch(const char *mnemonic)
{
    if (strcmp(mnemonic, "cbz") == 0 || strcmp(mnemonic, "cbnz") == 0 ||
        strcmp(mnemonic, "tbz") == 0 || strcmp(mnemonic, "tbnz") == 0) {
        return 1;
    }
    if (mnemonic[0] == 'b' && mnemonic[1] == '.') {
        return 1;
    }
    if (mnemonic[0] == 'j' && strcmp(mnemonic, "jmp") != 0 && strcmp(mnemonic, "jmpq") != 0) {
        return 1;
    }
    return 0;
}

static int mechanism_is_call(const char *mnemonic)
{
    return strcmp(mnemonic, "bl") == 0 || strcmp(mnemonic, "blr") == 0 ||
        strcmp(mnemonic, "call") == 0 || strcmp(mnemonic, "callq") == 0;
}

static int mechanism_operands_have_immediate(const char *operands)
{
    return strchr(operands, '#') != NULL || strchr(operands, '$') != NULL;
}

static int mechanism_is_address_range_branch(const char *mnemonic)
{
    return strcmp(mnemonic, "b.lo") == 0 || strcmp(mnemonic, "b.hs") == 0 ||
        strcmp(mnemonic, "b.cc") == 0 || strcmp(mnemonic, "b.cs") == 0 ||
        strcmp(mnemonic, "jb") == 0 || strcmp(mnemonic, "jae") == 0 ||
        strcmp(mnemonic, "jc") == 0 || strcmp(mnemonic, "jnc") == 0 ||
        strcmp(mnemonic, "jnae") == 0 || strcmp(mnemonic, "jnb") == 0;
}

static int mechanism_preceding_immediate_compare(const struct mechanism_function *function,
    size_t instruction_index)
{
    size_t lookback = instruction_index > 4u ? instruction_index - 4u : 0u;
    size_t cursor;
    for (cursor = lookback; cursor < instruction_index; ++cursor) {
        const char *mnemonic = function->instructions[cursor].mnemonic;
        if ((strcmp(mnemonic, "cmp") == 0 || strcmp(mnemonic, "ccmp") == 0 ||
                strcmp(mnemonic, "subs") == 0 || strcmp(mnemonic, "sub") == 0 ||
                strcmp(mnemonic, "test") == 0 || strcmp(mnemonic, "cmn") == 0) &&
            mechanism_operands_have_immediate(function->instructions[cursor].operands)) {
            return 1;
        }
    }
    return 0;
}

static int mechanism_recent_call(const struct mechanism_function *function,
    size_t instruction_index)
{
    /* GCC 会在 call 和返回值判断之间插入几条栈重载。 */
    size_t lookback = instruction_index > 8u ? instruction_index - 8u : 0u;
    size_t cursor;
    for (cursor = lookback; cursor < instruction_index; ++cursor) {
        if (mechanism_is_call(function->instructions[cursor].mnemonic)) {
            return 1;
        }
    }
    return 0;
}

static int mechanism_tests_return_register(const struct mechanism_function *function,
    size_t instruction_index)
{
    const char *operands = function->instructions[instruction_index].operands;
    const char *mnemonic = function->instructions[instruction_index].mnemonic;
    if (strncmp(operands, "w0", 2) == 0 || strncmp(operands, "x0", 2) == 0 ||
        strncmp(operands, "%eax", 4) == 0 || strncmp(operands, "%rax", 4) == 0 ||
        strncmp(operands, "eax", 3) == 0 || strncmp(operands, "rax", 3) == 0) {
        return 1;
    }
    if (mechanism_is_conditional_branch(mnemonic) && mnemonic[0] == 'j') {
        size_t lookback = instruction_index > 3u ? instruction_index - 3u : 0u;
        size_t cursor;
        for (cursor = lookback; cursor < instruction_index; ++cursor) {
            const char *prior = function->instructions[cursor].operands;
            if (strcmp(function->instructions[cursor].mnemonic, "test") == 0 ||
                strcmp(function->instructions[cursor].mnemonic, "cmp") == 0) {
                if (strstr(prior, "%eax") != NULL || strstr(prior, "%rax") != NULL ||
                    strstr(prior, "w0") != NULL || strstr(prior, "x0") != NULL) {
                    return 1;
                }
            }
        }
    }
    return 0;
}

static int mechanism_branch_target(const struct mechanism_instruction *instruction,
    uint64_t *target)
{
    const char *rest = NULL;
    if (mechanism_parse_hex_token(instruction->operands, target, &rest) != 0) {
        return 1;
    }
    return 0;
}

static const struct mechanism_instruction *
mechanism_instruction_at(const struct mechanism_function *function, uint64_t address)
{
    size_t instruction_index;
    for (instruction_index = 0; instruction_index < function->instruction_count;
        ++instruction_index) {
        if (function->instructions[instruction_index].address == address) {
            return &function->instructions[instruction_index];
        }
    }
    return NULL;
}

static int mechanism_is_canary(const struct mechanism_function *function, size_t instruction_index)
{
    const struct mechanism_instruction *instruction = &function->instructions[instruction_index];
    uint64_t target = 0;
    const struct mechanism_instruction *target_instruction;
    size_t lookback;
    size_t cursor;
    if (strstr(instruction->operands, "stack_chk") != NULL) {
        return 1;
    }
    {
        size_t canary_lookback = instruction_index > 4u ? instruction_index - 4u : 0u;
        size_t canary_cursor;
        for (canary_cursor = canary_lookback; canary_cursor < instruction_index; ++canary_cursor) {
            if (strstr(function->instructions[canary_cursor].operands, "%fs:") != NULL ||
                strstr(function->instructions[canary_cursor].operands, "stack_chk") != NULL) {
                return 1;
            }
        }
    }
    if (mechanism_branch_target(instruction, &target) != 0 || target <= instruction->address) {
        return 0;
    }
    target_instruction = mechanism_instruction_at(function, target);
    if (target_instruction == NULL || !mechanism_is_call(target_instruction->mnemonic)) {
        return 0;
    }
    lookback = instruction_index > 3u ? instruction_index - 3u : 0u;
    for (cursor = lookback; cursor < instruction_index; ++cursor) {
        const struct mechanism_instruction *prior = &function->instructions[cursor];
        if (strcmp(prior->mnemonic, "cmp") == 0 &&
            !mechanism_operands_have_immediate(prior->operands) &&
            (strstr(prior->operands, "x") != NULL || strstr(prior->operands, "%r") != NULL)) {
            return 1;
        }
    }
    return 0;
}

static void mechanism_count_control(const struct mechanism_function *function,
    size_t begin_index,
    size_t end_index,
    int classify_public_edges,
    struct mechanism_branch_counts *counts)
{
    size_t instruction_index;
    if (end_index > function->instruction_count) {
        end_index = function->instruction_count;
    }
    for (instruction_index = begin_index; instruction_index < end_index; ++instruction_index) {
        const struct mechanism_instruction *instruction =
            &function->instructions[instruction_index];
        uint64_t target = 0;
        int has_target;
        if (mechanism_is_division(instruction->mnemonic)) {
            ++counts->division_instructions;
        }
        if (!mechanism_is_conditional_branch(instruction->mnemonic)) {
            continue;
        }
        has_target = mechanism_branch_target(instruction, &target) == 0;
        if (has_target && target < instruction->address &&
            mechanism_preceding_immediate_compare(function, instruction_index)) {
            ++counts->loop_bound_branches;
            continue;
        }
        if (!mechanism_operands_have_immediate(instruction->operands) &&
            mechanism_is_address_range_branch(instruction->mnemonic)) {
            size_t lookback = instruction_index > 3u ? instruction_index - 3u : 0u;
            size_t cursor;
            int pointer_compare = 0;
            for (cursor = lookback; cursor < instruction_index; ++cursor) {
                if (strcmp(function->instructions[cursor].mnemonic, "cmp") == 0 &&
                    !mechanism_operands_have_immediate(function->instructions[cursor].operands)) {
                    pointer_compare = 1;
                }
            }
            if (pointer_compare) {
                ++counts->loop_bound_branches;
                continue;
            }
        }
        if (classify_public_edges && mechanism_recent_call(function, instruction_index) &&
            mechanism_tests_return_register(function, instruction_index)) {
            ++counts->public_error_branches;
            continue;
        }
        if (classify_public_edges && mechanism_is_canary(function, instruction_index)) {
            ++counts->canary_branches;
            continue;
        }
        ++counts->secret_conditional_branches;
    }
}

static struct mechanism_function *mechanism_find_exact(struct mechanism_program *program,
    const char *name)
{
    size_t function_index;
    for (function_index = 0; function_index < program->function_count; ++function_index) {
        if (strcmp(program->functions[function_index].name, name) == 0) {
            return &program->functions[function_index];
        }
    }
    return NULL;
}

static int mechanism_name_has(const char *name, const char *fragment)
{
    return strstr(name, fragment) != NULL;
}

static int mechanism_is_compress_family(const char *name)
{
    return mechanism_name_has(name, "poly_frommsg") || mechanism_name_has(name, "poly_tomsg") ||
        mechanism_name_has(name, "poly_compress") || mechanism_name_has(name, "poly_decompress");
}

static int mechanism_operands_have_modulus(const char *operands)
{
    return strstr(operands, "3329") != NULL || strstr(operands, "0xd01") != NULL ||
        strstr(operands, "0xD01") != NULL || strstr(operands, "0XD01") != NULL;
}

static int mechanism_division_near_modulus(const struct mechanism_function *function,
    size_t instruction_index)
{
    size_t begin = instruction_index > 6u ? instruction_index - 6u : 0u;
    size_t end = instruction_index + 6u;
    size_t cursor;
    if (end > function->instruction_count) {
        end = function->instruction_count;
    }
    for (cursor = begin; cursor < end; ++cursor) {
        if (mechanism_operands_have_modulus(function->instructions[cursor].operands) ||
            mechanism_operands_have_modulus(function->instructions[cursor].mnemonic)) {
            return 1;
        }
    }
    return 0;
}

static void mechanism_count_divisions(const struct mechanism_function *function,
    int require_modulus,
    struct mechanism_branch_counts *counts)
{
    size_t instruction_index;
    for (instruction_index = 0; instruction_index < function->instruction_count;
        ++instruction_index) {
        if (!mechanism_is_division(function->instructions[instruction_index].mnemonic)) {
            continue;
        }
        if (require_modulus && !mechanism_division_near_modulus(function, instruction_index)) {
            continue;
        }
        ++counts->division_instructions;
    }
}

static int mechanism_find_half_q_window(const struct mechanism_function *function,
    size_t *begin_index,
    size_t *end_index)
{
    size_t instruction_index;
    size_t first = function->instruction_count;
    size_t last = 0;
    int found = 0;
    for (instruction_index = 0; instruction_index < function->instruction_count;
        ++instruction_index) {
        const char *operands = function->instructions[instruction_index].operands;
        if (strstr(operands, "0x681") != NULL || strstr(operands, "1665") != NULL) {
            if (!found) {
                first = instruction_index;
            }
            last = instruction_index;
            found = 1;
        }
    }
    if (!found) {
        return 1;
    }
    *begin_index = first > 16u ? first - 16u : 0u;
    *end_index = last + 1u;
    for (instruction_index = last; instruction_index < function->instruction_count;
        ++instruction_index) {
        uint64_t target = 0;
        if (mechanism_is_conditional_branch(function->instructions[instruction_index].mnemonic) &&
            mechanism_branch_target(&function->instructions[instruction_index], &target) == 0 &&
            target < function->instructions[instruction_index].address) {
            *end_index = instruction_index + 1u;
            if (target <= function->instructions[first].address && first > 0u) {
                size_t cursor;
                for (cursor = 0; cursor < first; ++cursor) {
                    if (function->instructions[cursor].address == target) {
                        *begin_index = cursor;
                    }
                }
            }
            break;
        }
    }
    return 0;
}

static int mechanism_append_instruction(struct mechanism_function *function,
    const struct mechanism_instruction *instruction)
{
    if (function->instruction_count > 0u && function->instruction_count % 256u == 0u) {
        size_t new_capacity = function->instruction_count + 256u;
        struct mechanism_instruction *grown =
            realloc(function->instructions, new_capacity * sizeof(*function->instructions));
        if (grown == NULL) {
            return 1;
        }
        function->instructions = grown;
    }
    if (function->instructions == NULL) {
        function->instructions = calloc(256u, sizeof(*function->instructions));
        if (function->instructions == NULL) {
            return 1;
        }
    }
    function->instructions[function->instruction_count] = *instruction;
    ++function->instruction_count;
    return 0;
}

static void mechanism_program_free(struct mechanism_program *program)
{
    size_t function_index;
    if (program->functions == NULL) {
        return;
    }
    for (function_index = 0; function_index < program->function_count; ++function_index) {
        free(program->functions[function_index].instructions);
    }
    free(program->functions);
    program->functions = NULL;
    program->function_count = 0;
}

static int mechanism_parse_disassembly(const char *text, struct mechanism_program *program)
{
    const char *cursor = text;
    struct mechanism_function *current = NULL;
    program->functions = calloc(MECHANISM_MAX_FUNCTIONS, sizeof(*program->functions));
    program->function_count = 0;
    if (program->functions == NULL) {
        return 1;
    }
    while (*cursor != '\0') {
        const char *line_end = strchr(cursor, '\n');
        char line[768];
        size_t line_length = line_end == NULL ? strlen(cursor) : (size_t)(line_end - cursor);
        const char *trimmed;
        if (line_length >= sizeof(line)) {
            line_length = sizeof(line) - 1u;
        }
        memcpy(line, cursor, line_length);
        line[line_length] = '\0';
        if (line_end == NULL) {
            cursor += strlen(cursor);
        } else {
            cursor = line_end + 1;
        }
        trimmed = mechanism_skip_space(line);
        if (*trimmed == '\0' || strncmp(trimmed, "Disassembly", 11) == 0) {
            continue;
        }
        {
            uint64_t header_address = 0;
            const char *after_address = NULL;
            if (mechanism_parse_hex_token(trimmed, &header_address, &after_address) == 0) {
                after_address = mechanism_skip_space(after_address);
                if (*after_address == '<') {
                    const char *name_end = strchr(after_address + 1, '>');
                    if (name_end != NULL && name_end[1] == ':') {
                        char raw_name[160];
                        size_t name_length = (size_t)(name_end - (after_address + 1));
                        if (name_length >= sizeof(raw_name)) {
                            name_length = sizeof(raw_name) - 1u;
                        }
                        memcpy(raw_name, after_address + 1, name_length);
                        raw_name[name_length] = '\0';
                        if (program->function_count >= MECHANISM_MAX_FUNCTIONS) {
                            mechanism_program_free(program);
                            return 1;
                        }
                        current = &program->functions[program->function_count++];
                        memset(current, 0, sizeof(*current));
                        mechanism_normalize_symbol(raw_name, current->name, sizeof(current->name));
                        continue;
                    }
                }
            }
        }
        if (current == NULL) {
            continue;
        }
        {
            uint64_t address = 0;
            const char *after_address = NULL;
            char tokens[512];
            char *token;
            struct mechanism_instruction instruction;
            if (mechanism_parse_hex_token(trimmed, &address, &after_address) != 0) {
                continue;
            }
            after_address = mechanism_skip_space(after_address);
            if (*after_address != ':') {
                continue;
            }
            (void)snprintf(tokens, sizeof(tokens), "%s", mechanism_skip_space(after_address + 1));
            memset(&instruction, 0, sizeof(instruction));
            instruction.address = address;
            token = tokens;
            while (*token != '\0') {
                char *next_space;
                while (*token == ' ' || *token == '\t') {
                    ++token;
                }
                if (*token == '\0') {
                    break;
                }
                next_space = token;
                while (*next_space != '\0' && *next_space != ' ' && *next_space != '\t') {
                    ++next_space;
                }
                if (*next_space != '\0') {
                    *next_space = '\0';
                    ++next_space;
                }
                if (instruction.mnemonic[0] == '\0' && mechanism_token_is_raw_byte(token) &&
                    *next_space != '\0') {
                    token = next_space;
                    continue;
                }
                if (instruction.mnemonic[0] == '\0') {
                    size_t mnemonic_length = strlen(token);
                    if (mnemonic_length >= sizeof(instruction.mnemonic)) {
                        mnemonic_length = sizeof(instruction.mnemonic) - 1u;
                    }
                    memcpy(instruction.mnemonic, token, mnemonic_length);
                    instruction.mnemonic[mnemonic_length] = '\0';
                    for (token = instruction.mnemonic; *token != '\0'; ++token) {
                        *token = (char)tolower((unsigned char)*token);
                    }
                } else {
                    size_t used = strlen(instruction.operands);
                    size_t token_length = strlen(token);
                    if (used != 0u && used + 1u < sizeof(instruction.operands)) {
                        instruction.operands[used++] = ' ';
                        instruction.operands[used] = '\0';
                    }
                    if (used + token_length >= sizeof(instruction.operands)) {
                        token_length = sizeof(instruction.operands) - used - 1u;
                    }
                    if (token_length > 0u) {
                        memcpy(instruction.operands + used, token, token_length);
                        instruction.operands[used + token_length] = '\0';
                    }
                }
                token = next_space;
            }
            if (instruction.mnemonic[0] == '\0') {
                continue;
            }
            if (current->instruction_count >= MECHANISM_MAX_INSTRUCTIONS) {
                mechanism_program_free(program);
                return 1;
            }
            if (mechanism_append_instruction(current, &instruction) != 0) {
                mechanism_program_free(program);
                return 1;
            }
        }
    }
    return program->function_count == 0u ? 1 : 0;
}

static int mechanism_read_stream(FILE *stream, char **text_out)
{
    size_t capacity = 65536u;
    size_t length = 0;
    char *text = malloc(capacity);
    if (text == NULL) {
        return 1;
    }
    while (1) {
        size_t read_count;
        if (length + 4096u >= capacity) {
            size_t new_capacity = capacity * 2u;
            char *grown = realloc(text, new_capacity);
            if (grown == NULL) {
                free(text);
                return 1;
            }
            text = grown;
            capacity = new_capacity;
        }
        read_count = fread(text + length, 1, capacity - length - 1u, stream);
        length += read_count;
        if (read_count == 0) {
            break;
        }
    }
    if (ferror(stream)) {
        free(text);
        return 1;
    }
    text[length] = '\0';
    *text_out = text;
    return 0;
}

static int mechanism_run_objdump(const char *object_path, char **text_out)
{
#ifndef MECHANISM_OBJDUMP
#define MECHANISM_OBJDUMP "objdump"
#endif
    int pipes[2];
    pid_t child;
    FILE *stream;
    int wait_status = 0;
    char *first_attempt = NULL;
    if (pipe(pipes) != 0) {
        return 1;
    }
    child = fork();
    if (child == 0) {
        char *arguments[] = {MECHANISM_OBJDUMP,
            "-d",
            "--no-show-raw-insn",
            (char *)object_path,
            NULL};
        (void)close(pipes[0]);
        if (dup2(pipes[1], STDOUT_FILENO) < 0) {
            _exit(127);
        }
        (void)close(pipes[1]);
        execvp(arguments[0], arguments);
        _exit(127);
    }
    (void)close(pipes[1]);
    if (child < 0) {
        (void)close(pipes[0]);
        return 1;
    }
    stream = fdopen(pipes[0], "r");
    if (stream == NULL || mechanism_read_stream(stream, &first_attempt) != 0) {
        if (stream != NULL) {
            (void)fclose(stream);
        } else {
            (void)close(pipes[0]);
        }
        (void)waitpid(child, &wait_status, 0);
        return 1;
    }
    (void)fclose(stream);
    if (waitpid(child, &wait_status, 0) < 0 || !WIFEXITED(wait_status) ||
        WEXITSTATUS(wait_status) != 0) {
        free(first_attempt);
        if (pipe(pipes) != 0) {
            return 1;
        }
        child = fork();
        if (child == 0) {
            char *arguments[] = {MECHANISM_OBJDUMP, "-d", (char *)object_path, NULL};
            (void)close(pipes[0]);
            if (dup2(pipes[1], STDOUT_FILENO) < 0) {
                _exit(127);
            }
            (void)close(pipes[1]);
            execvp(arguments[0], arguments);
            _exit(127);
        }
        (void)close(pipes[1]);
        if (child < 0) {
            (void)close(pipes[0]);
            return 1;
        }
        stream = fdopen(pipes[0], "r");
        if (stream == NULL || mechanism_read_stream(stream, text_out) != 0) {
            if (stream != NULL) {
                (void)fclose(stream);
            }
            (void)waitpid(child, &wait_status, 0);
            return 1;
        }
        (void)fclose(stream);
        if (waitpid(child, &wait_status, 0) < 0 || !WIFEXITED(wait_status) ||
            WEXITSTATUS(wait_status) != 0) {
            free(*text_out);
            return 1;
        }
        return 0;
    }
    *text_out = first_attempt;
    return 0;
}

static int mechanism_source_line(const char *source_root,
    const char *relative_path,
    const char *marker,
    char *location,
    size_t location_capacity)
{
    char path[1024];
    FILE *source_file;
    char line[512];
    unsigned line_number = 0;
    int path_length = snprintf(path, sizeof(path), "%s/%s", source_root, relative_path);
    if (path_length < 0 || (size_t)path_length >= sizeof(path)) {
        return 1;
    }
    source_file = fopen(path, "r");
    if (source_file == NULL) {
        return 1;
    }
    while (fgets(line, sizeof(line), source_file) != NULL) {
        ++line_number;
        if (strstr(line, marker) != NULL) {
            (void)snprintf(location, location_capacity, "%s:%u", relative_path, line_number);
            (void)fclose(source_file);
            return 0;
        }
    }
    (void)fclose(source_file);
    return 1;
}

static const char *mechanism_identity_line(const char *prefix)
{
    size_t line_index;
    size_t prefix_length = strlen(prefix);
    for (line_index = 0;
        line_index < sizeof(build_identity_lines) / sizeof(build_identity_lines[0]);
        ++line_index) {
        if (strncmp(build_identity_lines[line_index], prefix, prefix_length) == 0) {
            return build_identity_lines[line_index];
        }
    }
    return NULL;
}

static const char *mechanism_compiler_version_line(void)
{
    size_t line_index;
    for (line_index = 0;
        line_index < sizeof(build_identity_lines) / sizeof(build_identity_lines[0]);
        ++line_index) {
        if (strstr(build_identity_lines[line_index], "clang version") != NULL ||
            strstr(build_identity_lines[line_index], "gcc version") != NULL ||
            strstr(build_identity_lines[line_index], "gcc (") != NULL ||
            strstr(build_identity_lines[line_index], "Apple clang") != NULL) {
            return build_identity_lines[line_index];
        }
    }
    return "compiler_version=unavailable\n";
}

static int mechanism_print_record(FILE *output,
    const char *mechanism_name,
    const char *status,
    const char *source_location,
    const char *symbol_name,
    const struct mechanism_branch_counts *counts,
    const char *leak_if_present)
{
    const char *observed = strcmp(status, "present") == 0 ? leak_if_present : "neither";
    return fprintf(output,
               "mechanism %s status=%s source=%s symbol=%s division_instructions=%d "
               "secret_conditional_branches=%d loop_bound_branches=%d leak_if_present=%s "
               "observed=%s\n",
               mechanism_name,
               status,
               source_location,
               symbol_name[0] == '\0' ? "none" : symbol_name,
               counts->division_instructions,
               counts->secret_conditional_branches,
               counts->loop_bound_branches,
               leak_if_present,
               observed) < 0
        ? 1
        : 0;
}

static int mechanism_audit_program(FILE *output,
    struct mechanism_program *program,
    const char *source_root,
    const char *artifact_sha256)
{
    struct mechanism_branch_counts kyber_counts;
    struct mechanism_branch_counts clangover_counts;
    struct mechanism_branch_counts fo_counts;
    struct mechanism_function *decapsulation;
    char kyber_symbols[512] = "";
    char clangover_symbol[160] = "";
    char kyber_source[256];
    char clangover_source[256];
    char fo_source[256];
    const char *compiler_command;
    const char *compiler_flags;
    const char *compile_options;
    const char *configuration;
    size_t function_index;
    int saw_compress_family = 0;
    int unresolved = 0;
    memset(&kyber_counts, 0, sizeof(kyber_counts));
    memset(&clangover_counts, 0, sizeof(clangover_counts));
    memset(&fo_counts, 0, sizeof(fo_counts));
    if (mechanism_source_line(source_root,
            "vendor/mlkem-native/mlkem/src/compress.c",
            "void mlk_poly_tomsg",
            kyber_source,
            sizeof(kyber_source)) != 0 ||
        mechanism_source_line(source_root,
            "vendor/mlkem-native/mlkem/src/compress.c",
            "void mlk_poly_frommsg",
            clangover_source,
            sizeof(clangover_source)) != 0 ||
        mechanism_source_line(source_root,
            "vendor/mlkem-native/mlkem/src/kem.c",
            "int mlk_kem_dec",
            fo_source,
            sizeof(fo_source)) != 0) {
        return 1;
    }
    for (function_index = 0; function_index < program->function_count; ++function_index) {
        struct mechanism_function *function = &program->functions[function_index];
        if (!mechanism_is_compress_family(function->name)) {
            continue;
        }
        saw_compress_family = 1;
        mechanism_count_divisions(function, 0, &kyber_counts);
        if (strlen(kyber_symbols) + strlen(function->name) + 2u < sizeof(kyber_symbols)) {
            if (kyber_symbols[0] != '\0') {
                (void)strcat(kyber_symbols, ",");
            }
            (void)strcat(kyber_symbols, function->name);
        }
        if (mechanism_name_has(function->name, "poly_frommsg")) {
            (void)snprintf(clangover_symbol, sizeof(clangover_symbol), "%s", function->name);
            mechanism_count_control(function, 0, function->instruction_count, 0, &clangover_counts);
        }
    }
    for (function_index = 0; function_index < program->function_count; ++function_index) {
        struct mechanism_function *function = &program->functions[function_index];
        size_t begin_index = 0;
        size_t end_index = 0;
        if (!mechanism_name_has(function->name, "indcpa_enc")) {
            continue;
        }
        if (mechanism_find_half_q_window(function, &begin_index, &end_index) != 0) {
            continue;
        }
        if (clangover_symbol[0] == '\0') {
            (void)snprintf(clangover_symbol, sizeof(clangover_symbol), "%s", function->name);
        }
        mechanism_count_control(function, begin_index, end_index, 0, &clangover_counts);
    }
    if (!saw_compress_family) {
        for (function_index = 0; function_index < program->function_count; ++function_index) {
            struct mechanism_function *function = &program->functions[function_index];
            if (mechanism_name_has(function->name, "indcpa_enc") ||
                mechanism_name_has(function->name, "indcpa_dec") ||
                strcmp(function->name, "baseline_native_dec") == 0) {
                mechanism_count_divisions(function, 1, &kyber_counts);
            }
        }
        (void)snprintf(kyber_symbols, sizeof(kyber_symbols), "inlined-callers");
    }
    if (clangover_symbol[0] == '\0') {
        struct mechanism_function *encaps = NULL;
        for (function_index = 0; function_index < program->function_count; ++function_index) {
            if (mechanism_name_has(program->functions[function_index].name, "indcpa_enc")) {
                encaps = &program->functions[function_index];
                break;
            }
        }
        if (encaps == NULL) {
            unresolved = 1;
        } else {
            size_t begin_index = 0;
            size_t end_index = 0;
            if (mechanism_find_half_q_window(encaps, &begin_index, &end_index) != 0) {
                unresolved = 1;
            } else {
                (void)snprintf(clangover_symbol, sizeof(clangover_symbol), "%s", encaps->name);
                mechanism_count_control(encaps, begin_index, end_index, 0, &clangover_counts);
            }
        }
    }
    decapsulation = mechanism_find_exact(program, "baseline_native_dec");
    if (decapsulation == NULL) {
        unresolved = 1;
    } else {
        mechanism_count_control(decapsulation, 0, decapsulation->instruction_count, 1, &fo_counts);
    }
    for (function_index = 0; function_index < program->function_count; ++function_index) {
        struct mechanism_function *function = &program->functions[function_index];
        if (mechanism_name_has(function->name, "ct_memcmp") ||
            mechanism_name_has(function->name, "ct_cmov")) {
            mechanism_count_control(function, 0, function->instruction_count, 0, &fo_counts);
        }
    }
    compiler_command = mechanism_identity_line("compiler_command=");
    compiler_flags = mechanism_identity_line("compiler_flags=");
    compile_options = mechanism_identity_line("compile_options=");
    configuration = mechanism_identity_line("configuration=");
    if (compiler_command == NULL || compiler_flags == NULL || compile_options == NULL ||
        configuration == NULL) {
        return 1;
    }
    if (fprintf(output, "artifact_sha256=%s\n", artifact_sha256) < 0 ||
        fputs(compiler_command, output) == EOF || fputs(compiler_flags, output) == EOF ||
        fputs(compile_options, output) == EOF || fputs(configuration, output) == EOF ||
        fputs(mechanism_compiler_version_line(), output) == EOF) {
        return 1;
    }
    if (unresolved) {
        if (fprintf(output, "mechanism kyber_slash_division status=unresolved\n") < 0 ||
            fprintf(output, "mechanism clangover_message_branch status=unresolved\n") < 0 ||
            fprintf(output, "mechanism fo_compare_rejection status=unresolved\n") < 0) {
            return 1;
        }
        return 2;
    }
    if (mechanism_print_record(output,
            "kyber_slash_division",
            kyber_counts.division_instructions > 0 ? "present" : "absent",
            kyber_source,
            kyber_symbols,
            &kyber_counts,
            "message_bit") != 0 ||
        mechanism_print_record(output,
            "clangover_message_branch",
            clangover_counts.secret_conditional_branches > 0 ? "present" : "absent",
            clangover_source,
            clangover_symbol,
            &clangover_counts,
            "message_bit") != 0 ||
        mechanism_print_record(output,
            "fo_compare_rejection",
            fo_counts.secret_conditional_branches > 0 ? "present" : "absent",
            fo_source,
            "baseline_native_dec",
            &fo_counts,
            "rejection_flag") != 0) {
        return 1;
    }
    return 0;
}

static int mechanism_self_test_case(const char *disassembly,
    const char *mechanism_name,
    const char *expected_status)
{
    struct mechanism_program program;
    int parse_status = mechanism_parse_disassembly(disassembly, &program);
    int expect_status;
    if (parse_status != 0) {
        fprintf(stderr, "self-test failed to parse %s\n", mechanism_name);
        return 1;
    }
    /* 自检不读仓库源码，源码行在正式入口核对。这里只核对指令归类。 */
    expect_status = 0;
    {
        struct mechanism_branch_counts counts;
        struct mechanism_function *function = &program.functions[0];
        memset(&counts, 0, sizeof(counts));
        if (strcmp(mechanism_name, "kyber_slash_division") == 0) {
            mechanism_count_divisions(function, 0, &counts);
            if ((counts.division_instructions > 0 ? "present" : "absent") != expected_status &&
                strcmp(counts.division_instructions > 0 ? "present" : "absent", expected_status) !=
                    0) {
                expect_status = 1;
            }
        } else if (strcmp(mechanism_name, "clangover_message_branch") == 0) {
            if (mechanism_name_has(function->name, "poly_frommsg")) {
                mechanism_count_control(function, 0, function->instruction_count, 0, &counts);
            } else {
                size_t begin_index = 0;
                size_t end_index = 0;
                if (mechanism_find_half_q_window(function, &begin_index, &end_index) != 0) {
                    expect_status = 1;
                } else {
                    mechanism_count_control(function, begin_index, end_index, 0, &counts);
                }
            }
            if (expect_status == 0 &&
                strcmp(counts.secret_conditional_branches > 0 ? "present" : "absent",
                    expected_status) != 0) {
                expect_status = 1;
            }
        } else {
            mechanism_count_control(function, 0, function->instruction_count, 1, &counts);
            if (strcmp(counts.secret_conditional_branches > 0 ? "present" : "absent",
                    expected_status) != 0) {
                expect_status = 1;
            }
        }
        if (expect_status != 0) {
            fprintf(stderr,
                "self-test %s expected %s divisions=%d secret=%d loops=%d\n",
                mechanism_name,
                expected_status,
                counts.division_instructions,
                counts.secret_conditional_branches,
                counts.loop_bound_branches);
        }
    }
    mechanism_program_free(&program);
    return expect_status;
}

static int mechanism_self_test(void)
{
    static const char *safe_frommsg = "0000000000001260 <_baseline_native_poly_frommsg>:\n"
                                      "    1260:\tmov\tw10, #0x681\n"
                                      "    1264:\tldrb\tw12, [x1, x8]\n"
                                      "    1268:\tand\tw11, w11, w12\n"
                                      "    126c:\tneg\tw11, w11\n"
                                      "    1270:\tand\tw11, w10, w11, lsr #16\n"
                                      "    1274:\tcmp\tx8, #0x20\n"
                                      "    1278:\tb.ne\t0x1260 <_baseline_native_poly_frommsg>\n"
                                      "    127c:\tret\n";
    static const char *vulnerable_frommsg =
        "0000000000002000 <_baseline_native_poly_frommsg>:\n"
        "    2000:\tldrb\tw12, [x1, x8]\n"
        "    2004:\tand\tw11, w12, #1\n"
        "    2008:\tcmp\tw11, #0\n"
        "    200c:\tb.eq\t0x2018 <_baseline_native_poly_frommsg+0x18>\n"
        "    2010:\tmov\tw11, #0x681\n"
        "    2014:\tb\t0x201c <_baseline_native_poly_frommsg+0x1c>\n"
        "    2018:\tmov\tw11, #0\n"
        "    201c:\tcmp\tx8, #0x20\n"
        "    2020:\tb.ne\t0x2000 <_baseline_native_poly_frommsg>\n"
        "    2024:\tret\n";
    static const char *slash_tomsg = "0000000000003000 <_baseline_native_poly_tomsg>:\n"
                                     "    3000:\tmov\tw9, #3329\n"
                                     "    3004:\tudiv\tw10, w8, w9\n"
                                     "    3008:\tcmp\tx8, #0x100\n"
                                     "    300c:\tb.ne\t0x3000 <_baseline_native_poly_tomsg>\n"
                                     "    3010:\tret\n";
    static const char *safe_tomsg = "0000000000004000 <_baseline_native_poly_tomsg>:\n"
                                    "    4000:\tmov\tw9, #1290168\n"
                                    "    4004:\tmul\tw10, w8, w9\n"
                                    "    4008:\tlsr\tw10, w10, #31\n"
                                    "    400c:\tcmp\tx11, #0x20\n"
                                    "    4010:\tb.ne\t0x4000 <_baseline_native_poly_tomsg>\n"
                                    "    4014:\tret\n";
    static const char *safe_dec = "000000000000a504 <_baseline_native_dec>:\n"
                                  "    a504:\tbl\t0xa600 <_baseline_native_dec+0xfc>\n"
                                  "    a508:\tmov\tx19, x0\n"
                                  "    a50c:\tcbnz\tw0, 0xa580 <_baseline_native_dec+0x7c>\n"
                                  "    a510:\tcmp\tx8, #0x440\n"
                                  "    a514:\tb.ne\t0xa510 <_baseline_native_dec+0xc>\n"
                                  "    a518:\tcmp\tx8, #0x20\n"
                                  "    a51c:\tb.ne\t0xa518 <_baseline_native_dec+0x14>\n"
                                  "    a520:\tldr\tx8, [sp]\n"
                                  "    a524:\tldr\tx9, [sp, #8]\n"
                                  "    a528:\tcmp\tx9, x8\n"
                                  "    a52c:\tb.ne\t0xa540 <_baseline_native_dec+0x3c>\n"
                                  "    a530:\tret\n"
                                  "    a540:\tbl\t0xa700 <__stack_chk_fail>\n";
    static const char *early_reject = "000000000000b000 <_baseline_native_dec>:\n"
                                      "    b000:\tcmp\tw22, #0\n"
                                      "    b004:\tb.ne\t0xb020 <_baseline_native_dec+0x20>\n"
                                      "    b008:\tcmp\tx8, #0x20\n"
                                      "    b00c:\tb.ne\t0xb008 <_baseline_native_dec+0x8>\n"
                                      "    b010:\tret\n"
                                      "    b020:\tret\n";
    static const char *x86_branch = "0000000000005000 <baseline_native_poly_frommsg>:\n"
                                    "    5000:\tand\t$0x1,%eax\n"
                                    "    5004:\ttest\t%eax,%eax\n"
                                    "    5008:\tje\t5014 <baseline_native_poly_frommsg+0x14>\n"
                                    "    500c:\tmovl\t$0x681,%ecx\n"
                                    "    5010:\tjmp\t5018 <baseline_native_poly_frommsg+0x18>\n"
                                    "    5014:\txor\t%ecx,%ecx\n"
                                    "    5018:\tcmp\t$0x20,%rdx\n"
                                    "    501c:\tjne\t5000 <baseline_native_poly_frommsg>\n"
                                    "    5020:\tret\n";
    static const char *x86_div = "0000000000006000 <baseline_native_poly_compress_d10>:\n"
                                 "    6000:\t48 89 c1\tmov\t$0xd01,%ecx\n"
                                 "    6004:\tf7 f1\tidiv\t%ecx\n"
                                 "    6008:\tc3\tret\n";
    static const char *gcc_decapsulation = "0000000000003d60 <baseline_native_dec>:\n"
                                           "    3d9b:\tcall\t3da0 <baseline_native_dec+0x40>\n"
                                           "    3da0:\ttest\t%eax,%eax\n"
                                           "    3da2:\tje\t3e20 <baseline_native_dec+0xc0>\n"
                                           "    3ebf:\tcall\t3ec4 <baseline_native_dec+0x164>\n"
                                           "    3ec4:\tmov\t0x18(%rsp),%r8\n"
                                           "    3ec9:\tmov\t0x10(%rsp),%r10\n"
                                           "    3ece:\ttest\t%eax,%eax\n"
                                           "    3ed0:\tmov\t0x8(%rsp),%r9\n"
                                           "    3ed5:\tmov\t%eax,%ebx\n"
                                           "    3ed7:\tjne\t3db8 <baseline_native_dec+0x58>\n"
                                           "    3ef0:\tpxor\t%xmm1,%xmm2\n"
                                           "    3f08:\tcmp\t$0x440,%rax\n"
                                           "    3f0e:\tjne\t3ef0 <baseline_native_dec+0x190>\n"
                                           "    3dff:\tsub\t%fs:0x28,%rax\n"
                                           "    3e08:\tjne\t4039 <baseline_native_dec+0x2d9>\n"
                                           "    402e:\tcmp\t$0x20,%rax\n"
                                           "    4032:\tjne\t4010 <baseline_native_dec+0x2b0>\n"
                                           "    4039:\tcall\t403e <__stack_chk_fail>\n";
    if (mechanism_sha256_self_check() != 0 ||
        mechanism_self_test_case(safe_frommsg, "clangover_message_branch", "absent") != 0 ||
        mechanism_self_test_case(vulnerable_frommsg, "clangover_message_branch", "present") != 0 ||
        mechanism_self_test_case(slash_tomsg, "kyber_slash_division", "present") != 0 ||
        mechanism_self_test_case(safe_tomsg, "kyber_slash_division", "absent") != 0 ||
        mechanism_self_test_case(safe_dec, "fo_compare_rejection", "absent") != 0 ||
        mechanism_self_test_case(early_reject, "fo_compare_rejection", "present") != 0 ||
        mechanism_self_test_case(x86_branch, "clangover_message_branch", "present") != 0 ||
        mechanism_self_test_case(x86_div, "kyber_slash_division", "present") != 0 ||
        mechanism_self_test_case(gcc_decapsulation, "fo_compare_rejection", "absent") != 0) {
        return 1;
    }
    puts("mechanism_audit self-test passed");
    return 0;
}

static int mechanism_print_usage(void)
{
    fputs("Usage: mechanism_audit --self-test\n"
          "       mechanism_audit KERNEL_OBJECT SOURCE_ROOT\n"
          "KERNEL_OBJECT 是本次构建的参考 kernel 目标文件。\n"
          "结果只报告三类机制在该产物中存在或不存在。\n",
        stderr);
    return 2;
}

int main(int argument_count, char **argument_values)
{
    char *disassembly = NULL;
    char artifact_sha256[65];
    struct mechanism_program program;
    int audit_status;
    if (argument_count == 2 && strcmp(argument_values[1], "--self-test") == 0) {
        return mechanism_self_test();
    }
    if (argument_count != 3) {
        return mechanism_print_usage();
    }
    if (mechanism_sha256_file(argument_values[1], artifact_sha256) != 0) {
        fputs("cannot hash kernel object\n", stderr);
        return 1;
    }
    if (mechanism_run_objdump(argument_values[1], &disassembly) != 0) {
        fputs("cannot disassemble kernel object\n", stderr);
        return 1;
    }
    if (mechanism_parse_disassembly(disassembly, &program) != 0) {
        free(disassembly);
        fputs("cannot parse kernel disassembly\n", stderr);
        return 1;
    }
    free(disassembly);
    audit_status = mechanism_audit_program(stdout, &program, argument_values[2], artifact_sha256);
    mechanism_program_free(&program);
    return audit_status;
}
