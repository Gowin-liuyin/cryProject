#include "controlled_statistics.h"

#include <assert.h>
#include <math.h>

int main(void)
{
    struct controlled_result result;
    const int64_t separated[4] = {1, 1, 1, 1};
    const int64_t balanced[4] = {1, -1, 1, -1};
    const int64_t equal[4] = {0, 0, 0, 0};
    const int64_t boundary[4] = {CONTROLLED_MAXIMUM_DIFFERENCE_NS,
        CONTROLLED_MAXIMUM_DIFFERENCE_NS,
        CONTROLLED_MAXIMUM_DIFFERENCE_NS,
        CONTROLLED_MAXIMUM_DIFFERENCE_NS};
    const int64_t excessive[4] = {INT64_MIN, 0, 0, 0};
    assert(compute_controlled_result(separated, 4, 1, &result) == 0);
    assert(result.assignment_count == 16 && result.tail_count == 2);
    assert(result.exact_p_value == 0.125L && result.mean_difference_ns == 1.0L);
    assert(result.interval_lower_ns == 1.0L && result.interval_upper_ns == 1.0L);
    assert(compute_controlled_result(balanced, 4, 0, &result) == 0);
    assert(result.tail_count == 16 && result.exact_p_value == 1.0L);
    assert(compute_controlled_result(equal, 4, 1, &result) == 0);
    assert(!result.has_variation && result.exact_p_value == 1.0L);
    assert(compute_controlled_result(boundary, 4, 0, &result) == 0 && result.tail_count == 2);
    assert(compute_controlled_result(excessive, 4, 0, &result) != 0);
    assert(compute_controlled_result(NULL, 4, 0, &result) != 0);
    assert(compute_controlled_result(separated, 3, 0, &result) != 0);
    assert(compute_controlled_result(separated, 21, 0, &result) != 0);
    return 0;
}
