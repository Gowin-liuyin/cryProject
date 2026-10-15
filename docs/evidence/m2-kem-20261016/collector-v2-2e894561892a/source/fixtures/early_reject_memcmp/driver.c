#include "compare.h"

#include <stdio.h>
#include <string.h>

#ifdef M4_ENABLE_CTGRIND
#include <valgrind/memcheck.h>
#endif

static volatile int m4_result_sink;

static int m4_run_probe(void)
{
    uint8_t secret_bytes[M4_COMPARE_BYTES] = {0};
    uint8_t candidate_bytes[M4_COMPARE_BYTES] = {0};
    candidate_bytes[M4_COMPARE_BYTES - 1U] = UINT8_C(1);
    int is_equal = 0;
#ifdef M4_ENABLE_CTGRIND
    VALGRIND_MAKE_MEM_UNDEFINED(secret_bytes, sizeof(secret_bytes));
#endif
    int compare_status = m4_compare_checked(secret_bytes,
        sizeof(secret_bytes),
        candidate_bytes,
        sizeof(candidate_bytes),
        &is_equal);
#ifdef M4_ENABLE_CTGRIND
    VALGRIND_MAKE_MEM_DEFINED(secret_bytes, sizeof(secret_bytes));
    VALGRIND_MAKE_MEM_DEFINED(&is_equal, sizeof(is_equal));
#endif
    m4_result_sink = is_equal;
    if (compare_status != 0) {
        return 1;
    }
    puts("artificial_fixture=yes probe=completed timing_samples=not_collected");
    return 0;
}

int main(int argument_count, char **argument_values)
{
    if (argument_count == 1 ||
        (argument_count == 2 && strcmp(argument_values[1], "--self-test") == 0)) {
        return m4_self_test();
    }
    if (argument_count == 2 && strcmp(argument_values[1], "--probe") == 0) {
        return m4_run_probe();
    }
    fputs("usage: m4_compare_{vulnerable,ct} [--self-test|--probe]\n", stderr);
    return 2;
}
