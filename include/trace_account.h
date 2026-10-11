#ifndef BASELINE_TRACE_ACCOUNT_H
#define BASELINE_TRACE_ACCOUNT_H

#include <stddef.h>
#include <stdint.h>
#include <stdio.h>

#define TRACE_RELATION_ENTER 1u
#define TRACE_RELATION_EXIT 2u
#define TRACE_INTEGRITY_OK 0u
#define TRACE_INTEGRITY_OVERFLOW 1u
#define TRACE_INTEGRITY_UNPAIRED 2u
#define TRACE_INTEGRITY_STACK 3u
#define TRACE_STACK_LIMIT 64u
#define TRACE_FUNCTION_CAPACITY 32u

struct trace_event {
    uint64_t sample_id;
    uint64_t function_id;
    uint32_t call_relation;
    uint64_t timestamp_counts;
    uint32_t integrity_status;
};

struct trace_store {
    struct trace_event *events;
    size_t capacity_events;
    size_t event_count;
    int overflow_failed;
    int unpaired_failed;
    int stack_failed;
};

struct trace_function_total {
    uint64_t function_id;
    uint64_t inclusive_counts;
    uint64_t exclusive_counts;
    uint32_t call_count;
};

int trace_store_init(struct trace_store *store,
    struct trace_event *backing,
    size_t capacity_events);
int trace_store_push(struct trace_store *store, const struct trace_event *event);
int trace_account_sample(struct trace_store *store,
    uint64_t sample_id,
    struct trace_function_total *totals,
    size_t total_capacity,
    size_t *total_count,
    uint64_t *outermost_inclusive_counts);
const char *trace_event_header(void);
int trace_event_write(FILE *output, const struct trace_event *event);

void trace_runtime_bind(struct trace_store *store, uint64_t image_base, int use_clock);
void trace_runtime_begin_sample(uint64_t sample_id);
void trace_runtime_end_sample(void);
int trace_runtime_failed(void);

#endif
