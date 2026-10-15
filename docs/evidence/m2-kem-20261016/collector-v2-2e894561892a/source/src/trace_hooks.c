#define _POSIX_C_SOURCE 200809L

#include "trace_account.h"

#include <time.h>

struct trace_runtime {
    struct trace_store *store;
    uint64_t image_base;
    uint64_t sample_id;
    uint64_t sequence_counts;
    int use_clock;
    int active;
    int failed;
};

static struct trace_runtime trace_runtime;

__attribute__((no_instrument_function)) static int read_hook_clock(uint64_t *timestamp_counts)
{
    struct timespec timestamp;
    if (clock_gettime(CLOCK_MONOTONIC, &timestamp) != 0 || timestamp.tv_sec < 0 ||
        timestamp.tv_nsec < 0 || timestamp.tv_nsec >= 1000000000L) {
        return 1;
    }
    *timestamp_counts =
        (uint64_t)timestamp.tv_sec * UINT64_C(1000000000) + (uint64_t)timestamp.tv_nsec;
    return 0;
}

__attribute__((no_instrument_function)) static void record_hook(void *this_function,
    uint32_t call_relation)
{
    struct trace_event event;
    uintptr_t function_address = (uintptr_t)this_function;
    if (!trace_runtime.active || trace_runtime.store == NULL || trace_runtime.failed) {
        return;
    }
    if (function_address < (uintptr_t)trace_runtime.image_base) {
        trace_runtime.failed = 1;
        trace_runtime.store->unpaired_failed = 1;
        return;
    }
    event.sample_id = trace_runtime.sample_id;
    event.function_id = (uint64_t)(function_address - (uintptr_t)trace_runtime.image_base);
    event.call_relation = call_relation;
    event.integrity_status = TRACE_INTEGRITY_OK;
    if (trace_runtime.use_clock) {
        if (read_hook_clock(&event.timestamp_counts) != 0) {
            trace_runtime.failed = 1;
            return;
        }
    } else {
        event.timestamp_counts = trace_runtime.sequence_counts;
        trace_runtime.sequence_counts += 1u;
    }
    if (trace_store_push(trace_runtime.store, &event) != 0) {
        event.integrity_status = TRACE_INTEGRITY_OVERFLOW;
        trace_runtime.failed = 1;
    }
}

__attribute__((no_instrument_function)) void
trace_runtime_bind(struct trace_store *store, uint64_t image_base, int use_clock)
{
    trace_runtime.store = store;
    trace_runtime.image_base = image_base;
    trace_runtime.use_clock = use_clock;
    trace_runtime.sample_id = 0u;
    trace_runtime.sequence_counts = 0u;
    trace_runtime.active = 0;
    trace_runtime.failed = 0;
}

__attribute__((no_instrument_function)) void trace_runtime_begin_sample(uint64_t sample_id)
{
    trace_runtime.sample_id = sample_id;
    trace_runtime.active = 1;
    if (trace_runtime.store != NULL) {
        trace_runtime.store->event_count = 0u;
    }
}

__attribute__((no_instrument_function)) void trace_runtime_end_sample(void)
{
    trace_runtime.active = 0;
}

__attribute__((no_instrument_function)) int trace_runtime_failed(void)
{
    return trace_runtime.failed;
}

__attribute__((no_instrument_function)) void __cyg_profile_func_enter(void *this_function,
    void *call_site)
{
    (void)call_site;
    record_hook(this_function, TRACE_RELATION_ENTER);
}

__attribute__((no_instrument_function)) void __cyg_profile_func_exit(void *this_function,
    void *call_site)
{
    (void)call_site;
    record_hook(this_function, TRACE_RELATION_EXIT);
}
