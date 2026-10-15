#ifndef MEM_LUT_H
#define MEM_LUT_H

#include <stddef.h>
#include <stdint.h>

#define MEM_LUT_INPUT_BYTES 32U

/* 人工校准变换，不是密码算法或 ML-KEM 解封装。 */
int mem_lut_apply(const uint8_t *secret_input,
    size_t secret_input_bytes,
    uint8_t *output,
    size_t output_capacity_bytes);

#endif
