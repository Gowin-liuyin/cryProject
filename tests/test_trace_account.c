#define _POSIX_C_SOURCE 200809L

#include "trace_account.h"

#include <assert.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

static void test_reconciliation(void)
{
    struct trace_event backing[8];
    struct trace_store store;
    struct trace_function_total totals[4];
    size_t total_count = 0u;
    uint64_t outermost = 0u;
    struct trace_event enter_outer = {1u, 10u, TRACE_RELATION_ENTER, 0u, TRACE_INTEGRITY_OK};
    struct trace_event enter_inner = {1u, 20u, TRACE_RELATION_ENTER, 10u, TRACE_INTEGRITY_OK};
    struct trace_event exit_inner = {1u, 20u, TRACE_RELATION_EXIT, 40u, TRACE_INTEGRITY_OK};
    struct trace_event exit_outer = {1u, 10u, TRACE_RELATION_EXIT, 100u, TRACE_INTEGRITY_OK};
    assert(trace_store_init(&store, backing, 8u) == 0);
    assert(trace_store_push(&store, &enter_outer) == 0);
    assert(trace_store_push(&store, &enter_inner) == 0);
    assert(trace_store_push(&store, &exit_inner) == 0);
    assert(trace_store_push(&store, &exit_outer) == 0);
    assert(trace_account_sample(&store, 1u, totals, 4u, &total_count, &outermost) == 0);
    assert(total_count == 2u);
    assert(outermost == 100u);
    assert(totals[0].function_id == 20u);
    assert(totals[0].exclusive_counts == 30u);
    assert(totals[1].function_id == 10u);
    assert(totals[1].inclusive_counts == 100u);
    assert(totals[1].exclusive_counts == 70u);
    assert(totals[0].exclusive_counts + totals[1].exclusive_counts == outermost);
}

static void test_overflow_is_visible(void)
{
    struct trace_event backing[2];
    struct trace_store store;
    struct trace_event event = {1u, 1u, TRACE_RELATION_ENTER, 0u, TRACE_INTEGRITY_OK};
    assert(trace_store_init(&store, backing, 2u) == 0);
    assert(trace_store_push(&store, &event) == 0);
    assert(trace_store_push(&store, &event) == 0);
    assert(trace_store_push(&store, &event) != 0);
    assert(store.overflow_failed == 1);
    assert(store.event_count == 2u);
}

static void test_unpaired_is_visible(void)
{
    struct trace_event backing[2];
    struct trace_store store;
    struct trace_function_total totals[2];
    size_t total_count = 0u;
    uint64_t outermost = 0u;
    struct trace_event enter_event = {3u, 4u, TRACE_RELATION_ENTER, 1u, TRACE_INTEGRITY_OK};
    assert(trace_store_init(&store, backing, 2u) == 0);
    assert(trace_store_push(&store, &enter_event) == 0);
    assert(trace_account_sample(&store, 3u, totals, 2u, &total_count, &outermost) != 0);
    assert(store.unpaired_failed == 1);
}

static void test_event_text_has_no_secret(void)
{
    struct trace_event event = {9u, 8u, TRACE_RELATION_EXIT, 7u, TRACE_INTEGRITY_OK};
    char *line = NULL;
    size_t line_size = 0u;
    FILE *memory = open_memstream(&line, &line_size);
    const char *header = trace_event_header();
    assert(memory != NULL);
    assert(strcmp(header,
               "sample_id,function_id,call_relation,timestamp_counts,integrity_status") == 0);
    assert(strstr(header, "shared_secret") == NULL);
    assert(strstr(header, "verify") == NULL);
    assert(strstr(header, "ground_truth") == NULL);
    assert(trace_event_write(memory, &event) == 0);
    assert(fflush(memory) == 0);
    assert(strstr(line, "shared_secret") == NULL);
    assert(strstr(line, "decapsulation_key") == NULL);
    assert(strstr(line, "verify") == NULL);
    assert(strcmp(line, "9,8,2,7,0\n") == 0);
    (void)fclose(memory);
    free(line);
}

int main(void)
{
    test_reconciliation();
    test_overflow_is_visible();
    test_unpaired_is_visible();
    test_event_text_has_no_secret();
    return 0;
}
