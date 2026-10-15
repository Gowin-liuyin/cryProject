#include "mem_lut.h"

#include <stdio.h>
#include <string.h>

#if MEM_LUT_CTGRIND
#include <valgrind/memcheck.h>
#endif

static int check_selftest(void)
{
    uint8_t secret_input[MEM_LUT_INPUT_BYTES];
    uint8_t output[MEM_LUT_INPUT_BYTES + 1U];
    for (unsigned input_value = 0U; input_value < 256U; input_value++) {
        for (size_t input_index = 0U; input_index < MEM_LUT_INPUT_BYTES; input_index++) {
            secret_input[input_index] = (uint8_t)(input_value + (unsigned)input_index);
        }
        memset(output, 0xa5, sizeof(output));
        if (mem_lut_apply(secret_input, sizeof(secret_input), output, sizeof(output)) != 0) {
            return 1;
        }
        for (size_t output_index = 0U; output_index < MEM_LUT_INPUT_BYTES; output_index++) {
            unsigned expected_value = (197U * (unsigned)secret_input[output_index] + 101U) % 256U;
            if (output[output_index] != (uint8_t)expected_value) {
                return 1;
            }
        }
        if (output[MEM_LUT_INPUT_BYTES] != 0xa5U) {
            return 1;
        }
    }
    memset(output, 0xa5, sizeof(output));
    if (mem_lut_apply(NULL, sizeof(secret_input), output, sizeof(output)) != -1 ||
        mem_lut_apply(secret_input, sizeof(secret_input), NULL, sizeof(output)) != -1 ||
        mem_lut_apply(secret_input, 0U, output, sizeof(output)) != -1 ||
        mem_lut_apply(secret_input, MEM_LUT_INPUT_BYTES - 1U, output, sizeof(output)) != -1 ||
        mem_lut_apply(secret_input, MEM_LUT_INPUT_BYTES + 1U, output, sizeof(output)) != -1 ||
        mem_lut_apply(secret_input, sizeof(secret_input), output, MEM_LUT_INPUT_BYTES - 1U) != -1) {
        return 1;
    }
    for (size_t output_index = 0U; output_index < sizeof(output); output_index++) {
        if (output[output_index] != 0xa5U) {
            return 1;
        }
    }
    for (size_t input_index = 0U; input_index < MEM_LUT_INPUT_BYTES; input_index++) {
        secret_input[input_index] = (uint8_t)input_index;
    }
    if (mem_lut_apply(secret_input, sizeof(secret_input), secret_input, sizeof(secret_input)) !=
        0) {
        return 1;
    }
    for (size_t output_index = 0U; output_index < MEM_LUT_INPUT_BYTES; output_index++) {
        unsigned expected_value = (197U * (unsigned)output_index + 101U) % 256U;
        if (secret_input[output_index] != (uint8_t)expected_value) {
            return 1;
        }
    }
    for (size_t input_index = 0U; input_index < MEM_LUT_INPUT_BYTES; input_index++) {
        output[input_index] = (uint8_t)input_index;
    }
    if (mem_lut_apply(output, MEM_LUT_INPUT_BYTES, output + 1U, MEM_LUT_INPUT_BYTES) != 0) {
        return 1;
    }
    for (size_t output_index = 0U; output_index < MEM_LUT_INPUT_BYTES; output_index++) {
        unsigned expected_value = (197U * (unsigned)output_index + 101U) % 256U;
        if (output[output_index + 1U] != (uint8_t)expected_value) {
            return 1;
        }
    }
    printf("fixture=artificial_mem_lut mode=%s selftest=pass mappings=8192 boundary=pass "
           "overlap=pass\n",
        MEM_LUT_LEAK_ENABLED ? "on" : "off");
    return 0;
}

static int run_ctgrind_probe(void)
{
#if MEM_LUT_CTGRIND
    if (RUNNING_ON_VALGRIND == 0U) {
        fputs("ctgrind probe requires execution under Valgrind\n", stderr);
        return 77;
    }
    uint8_t secret_input[MEM_LUT_INPUT_BYTES];
    uint8_t output[MEM_LUT_INPUT_BYTES];
    memset(secret_input, 0x5a, sizeof(secret_input));
    VALGRIND_MAKE_MEM_UNDEFINED(secret_input, sizeof(secret_input));
    int apply_status = mem_lut_apply(secret_input, sizeof(secret_input), output, sizeof(output));
    /* 仅解除人工输入/输出的标记，避免日志消费污染定位结果。 */
    VALGRIND_MAKE_MEM_DEFINED(secret_input, sizeof(secret_input));
    VALGRIND_MAKE_MEM_DEFINED(output, sizeof(output));
    if (apply_status != 0) {
        return 1;
    }
    volatile uint8_t observed_value = output[0];
    (void)observed_value;
    puts("fixture=artificial_mem_lut ctgrind_probe=completed");
    return 0;
#else
    fputs("ctgrind hook unavailable; configure with -DMEM_LUT_ENABLE_CTGRIND=ON\n", stderr);
    return 77;
#endif
}

int main(int argument_count, char **argument_values)
{
    if (argument_count == 2 && strcmp(argument_values[1], "--selftest") == 0) {
        return check_selftest();
    }
    if (argument_count == 2 && strcmp(argument_values[1], "--ctgrind-probe") == 0) {
        return run_ctgrind_probe();
    }
    fputs("usage: mem_lut_leak_{on,off} --selftest|--ctgrind-probe\n", stderr);
    return 2;
}
