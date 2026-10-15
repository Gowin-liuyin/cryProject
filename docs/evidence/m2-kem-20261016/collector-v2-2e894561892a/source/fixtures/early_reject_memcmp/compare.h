#ifndef M4_COMPARE_H
#define M4_COMPARE_H

#include <stddef.h>
#include <stdint.h>

#define M4_COMPARE_BYTES 32U

/* 内核只接受已验证的指针和公开长度；返回相等性，不提供排序语义。 */
int m4_compare_bytes(const uint8_t *secret_bytes,
    const uint8_t *candidate_bytes,
    size_t compare_length_bytes);

int m4_compare_checked(const uint8_t *secret_bytes,
    size_t secret_length_bytes,
    const uint8_t *candidate_bytes,
    size_t candidate_length_bytes,
    int *is_equal);

int m4_self_test(void);

#endif
