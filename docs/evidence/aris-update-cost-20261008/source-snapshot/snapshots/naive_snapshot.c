#include "controlled_statistics.h"
#include "paired_statistics.h"

#include <stdlib.h>
#include <string.h>

static uint64_t absolute_sum(int64_t signed_sum)
{
    return (uint64_t)(signed_sum < 0 ? -signed_sum : signed_sum);
}

static int compare_means(const void *first_value, const void *second_value)
{
    long double first_mean = *(const long double *)first_value;
    long double second_mean = *(const long double *)second_value;
    return first_mean < second_mean ? -1 : first_mean > second_mean ? 1 : 0;
}

static long double
endpoint(const long double *sorted_values, size_t value_count, long double fraction)
{
    long double position = fraction * (long double)(value_count - 1u);
    size_t lower_index = (size_t)position;
    long double remainder = position - (long double)lower_index;
    return sorted_values[lower_index] * (1.0L - remainder) +
        sorted_values[lower_index + 1u] * remainder;
}

int compute_controlled_result(const int64_t *differences_ns,
    size_t pair_count,
    int compute_interval,
    struct controlled_result *result)
{
    if (differences_ns == NULL || result == NULL || pair_count < 4u ||
        pair_count > CONTROLLED_MAXIMUM_PAIRS) {
        return 1;
    }
    memset(result, 0, sizeof(*result));
    int64_t observed_sum = 0;
    for (size_t pair_index = 0; pair_index < pair_count; ++pair_index) {
        if (differences_ns[pair_index] < -CONTROLLED_MAXIMUM_DIFFERENCE_NS ||
            differences_ns[pair_index] > CONTROLLED_MAXIMUM_DIFFERENCE_NS) {
            return 1;
        }
        observed_sum += differences_ns[pair_index];
        if (differences_ns[pair_index] != 0) {
            result->has_variation = 1;
        }
    }
    result->mean_difference_ns = (long double)observed_sum / (long double)pair_count;
    result->assignment_count = UINT64_C(1) << pair_count;
    for (uint64_t assignment_index = 0; assignment_index < result->assignment_count;
        ++assignment_index) {
        uint64_t gray_code = assignment_index ^ (assignment_index >> 1u);
        int64_t permuted_sum = 0;
        for (size_t pair_index = 0; pair_index < pair_count; ++pair_index) {
            permuted_sum += (gray_code & (UINT64_C(1) << pair_index)) != 0
                ? differences_ns[pair_index]
                : -differences_ns[pair_index];
        }
        if (absolute_sum(permuted_sum) >= absolute_sum(observed_sum)) {
            ++result->tail_count;
        }
    }
    result->exact_p_value = (long double)result->tail_count / (long double)result->assignment_count;
    if (compute_interval) {
        long double bootstrap_means[PAIRED_BOOTSTRAP_COUNT];
        uint64_t random_state = UINT64_C(2026100701);
        for (size_t replicate_index = 0; replicate_index < PAIRED_BOOTSTRAP_COUNT;
            ++replicate_index) {
            int64_t replicate_sum = 0;
            for (size_t draw_index = 0; draw_index < pair_count; ++draw_index) {
                size_t selected_index;
                if (draw_paired_index(&random_state, pair_count, &selected_index) != 0) {
                    return 1;
                }
                replicate_sum += differences_ns[selected_index];
            }
            bootstrap_means[replicate_index] = (long double)replicate_sum / (long double)pair_count;
        }
        qsort(bootstrap_means, PAIRED_BOOTSTRAP_COUNT, sizeof(*bootstrap_means), compare_means);
        result->interval_lower_ns = endpoint(bootstrap_means, PAIRED_BOOTSTRAP_COUNT, 0.005L);
        result->interval_upper_ns = endpoint(bootstrap_means, PAIRED_BOOTSTRAP_COUNT, 0.995L);
    }
    return 0;
}
