#ifndef BASELINE_CONTROLLED_STATISTICS_H
#define BASELINE_CONTROLLED_STATISTICS_H

#include <stddef.h>
#include <stdint.h>

#define CONTROLLED_MAXIMUM_PAIRS 20u
#define CONTROLLED_MAXIMUM_DIFFERENCE_NS INT64_C(1000000000000)

struct controlled_result {
    uint64_t assignment_count;
    uint64_t tail_count;
    long double mean_difference_ns;
    long double exact_p_value;
    long double interval_lower_ns;
    long double interval_upper_ns;
    int has_variation;
};

int compute_controlled_result(const int64_t *differences_ns,
    size_t pair_count,
    int compute_interval,
    struct controlled_result *result);

#endif
