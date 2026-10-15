#include "trace_account.h"

#include <string.h>

int trace_store_init(struct trace_store *store, struct trace_event *backing, size_t capacity_events)
{
    if (store == NULL || backing == NULL || capacity_events == 0u) {
        return 1;
    }
    store->events = backing;
    store->capacity_events = capacity_events;
    store->event_count = 0u;
    store->overflow_failed = 0;
    store->unpaired_failed = 0;
    store->stack_failed = 0;
    return 0;
}

int trace_store_push(struct trace_store *store, const struct trace_event *event)
{
    if (store == NULL || event == NULL || store->events == NULL) {
        return 1;
    }
    if (store->overflow_failed || store->event_count >= store->capacity_events) {
        store->overflow_failed = 1;
        return 1;
    }
    store->events[store->event_count] = *event;
    store->event_count += 1u;
    return 0;
}

const char *trace_event_header(void)
{
    return "sample_id,function_id,call_relation,timestamp_counts,integrity_status";
}

int trace_event_write(FILE *output, const struct trace_event *event)
{
    if (output == NULL || event == NULL) {
        return 1;
    }
    if (fprintf(output,
            "%llu,%llu,%u,%llu,%u\n",
            (unsigned long long)event->sample_id,
            (unsigned long long)event->function_id,
            event->call_relation,
            (unsigned long long)event->timestamp_counts,
            event->integrity_status) < 0) {
        return 1;
    }
    return 0;
}

static int find_total(struct trace_function_total *totals,
    size_t total_count,
    uint64_t function_id,
    size_t *found_index)
{
    for (size_t total_index = 0; total_index < total_count; ++total_index) {
        if (totals[total_index].function_id == function_id) {
            *found_index = total_index;
            return 1;
        }
    }
    return 0;
}

int trace_account_sample(struct trace_store *store,
    uint64_t sample_id,
    struct trace_function_total *totals,
    size_t total_capacity,
    size_t *total_count,
    uint64_t *outermost_inclusive_counts)
{
    struct trace_event stack_events[TRACE_STACK_LIMIT];
    uint64_t child_inclusive[TRACE_STACK_LIMIT];
    size_t stack_depth = 0u;
    uint64_t outermost_sum = 0u;
    uint64_t exclusive_sum = 0u;
    if (store == NULL || totals == NULL || total_count == NULL ||
        outermost_inclusive_counts == NULL || store->overflow_failed) {
        return 1;
    }
    *total_count = 0u;
    *outermost_inclusive_counts = 0u;
    for (size_t event_index = 0; event_index < store->event_count; ++event_index) {
        const struct trace_event *event = &store->events[event_index];
        if (event->sample_id != sample_id) {
            continue;
        }
        if (event->call_relation == TRACE_RELATION_ENTER) {
            if (stack_depth >= TRACE_STACK_LIMIT) {
                store->stack_failed = 1;
                return 1;
            }
            stack_events[stack_depth] = *event;
            child_inclusive[stack_depth] = 0u;
            stack_depth += 1u;
            continue;
        }
        if (event->call_relation != TRACE_RELATION_EXIT || stack_depth == 0u ||
            stack_events[stack_depth - 1u].function_id != event->function_id ||
            event->timestamp_counts < stack_events[stack_depth - 1u].timestamp_counts) {
            store->unpaired_failed = 1;
            return 1;
        }
        stack_depth -= 1u;
        uint64_t inclusive_counts =
            event->timestamp_counts - stack_events[stack_depth].timestamp_counts;
        if (inclusive_counts < child_inclusive[stack_depth]) {
            store->unpaired_failed = 1;
            return 1;
        }
        uint64_t exclusive_counts = inclusive_counts - child_inclusive[stack_depth];
        if (stack_depth > 0u) {
            if (child_inclusive[stack_depth - 1u] > UINT64_MAX - inclusive_counts) {
                return 1;
            }
            child_inclusive[stack_depth - 1u] += inclusive_counts;
        } else {
            if (outermost_sum > UINT64_MAX - inclusive_counts) {
                return 1;
            }
            outermost_sum += inclusive_counts;
        }
        if (exclusive_sum > UINT64_MAX - exclusive_counts) {
            return 1;
        }
        exclusive_sum += exclusive_counts;
        size_t found_index = 0u;
        if (!find_total(totals, *total_count, event->function_id, &found_index)) {
            if (*total_count >= total_capacity) {
                return 1;
            }
            found_index = *total_count;
            memset(&totals[found_index], 0, sizeof(totals[found_index]));
            totals[found_index].function_id = event->function_id;
            *total_count += 1u;
        }
        if (totals[found_index].inclusive_counts > UINT64_MAX - inclusive_counts ||
            totals[found_index].exclusive_counts > UINT64_MAX - exclusive_counts) {
            return 1;
        }
        totals[found_index].inclusive_counts += inclusive_counts;
        totals[found_index].exclusive_counts += exclusive_counts;
        totals[found_index].call_count += 1u;
    }
    if (stack_depth != 0u) {
        store->unpaired_failed = 1;
        return 1;
    }
    if (exclusive_sum != outermost_sum) {
        store->unpaired_failed = 1;
        return 1;
    }
    *outermost_inclusive_counts = outermost_sum;
    return 0;
}
