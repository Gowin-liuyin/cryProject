#ifndef UPDATE_COST_H
#define UPDATE_COST_H

#include "controlled_statistics.h"

int compute_incremental_controlled_result(const int64_t *differences_ns,
    size_t pair_count,
    int compute_interval,
    struct controlled_result *result);
int compute_naive_controlled_result(const int64_t *differences_ns,
    size_t pair_count,
    int compute_interval,
    struct controlled_result *result);

#endif
