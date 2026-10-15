#define _POSIX_C_SOURCE 200809L

#include <inttypes.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

/* 上游计时入口不调用；仅把既有 CSV 交给原统计内核。 */
#define DUDECT_IMPLEMENTATION
#include "dudect.h"

#define REPLAY_BATCH_RECORDS 10000u

uint8_t do_one_computation(uint8_t *input_data)
{
    (void)input_data;
    abort();
}

void prepare_inputs(dudect_config_t *configuration, uint8_t *input_data, uint8_t *classes)
{
    (void)configuration;
    (void)input_data;
    (void)classes;
    abort();
}

int main(int argument_count, char **arguments)
{
    if (argument_count != 2) {
        return 2;
    }
    FILE *source = fopen(arguments[1], "r");
    if (source == NULL) {
        return 1;
    }
    char line[128];
    if (fgets(line, sizeof(line), source) == NULL || strcmp(line, "V1,V2\n") != 0) {
        fclose(source);
        return 1;
    }
    dudect_config_t configuration = {1u, REPLAY_BATCH_RECORDS};
    dudect_ctx_t context = {0};
    if (dudect_init(&context, &configuration) != 0) {
        fclose(source);
        return 1;
    }
    size_t batch_count = 0u;
    size_t batch_record_count = 0u;
    size_t total_record_count = 0u;
    size_t discarded_endpoint_count = 0u;
    int has_leakage_evidence = 0;
    while (fgets(line, sizeof(line), source) != NULL) {
        char class_label;
        uint64_t elapsed_nanoseconds;
        char final_character;
        if (sscanf(line,
                "%c,%" SCNu64 "%c",
                &class_label,
                &elapsed_nanoseconds,
                &final_character) != 3 ||
            (class_label != 'X' && class_label != 'Y') || final_character != '\n' ||
            elapsed_nanoseconds > INT64_MAX) {
            dudect_free(&context);
            fclose(source);
            return 1;
        }
        context.exec_times[batch_record_count] = (int64_t)elapsed_nanoseconds;
        context.classes[batch_record_count] = class_label == 'X' ? 0u : 1u;
        ++batch_record_count;
        ++total_record_count;
        if (batch_record_count == REPLAY_BATCH_RECORDS) {
            if (batch_count == 0u) {
                prepare_percentiles(&context);
            } else {
                update_statistics(&context);
                discarded_endpoint_count += 11u;
                if (context.ttest_ctxs[0]->n[0] > DUDECT_ENOUGH_MEASUREMENTS &&
                    context.ttest_ctxs[0]->n[1] > DUDECT_ENOUGH_MEASUREMENTS) {
                    if (report(&context) == DUDECT_LEAKAGE_FOUND) {
                        has_leakage_evidence = 1;
                    }
                }
            }
            ++batch_count;
            batch_record_count = 0u;
        }
    }
    int status = ferror(source);
    status |= fclose(source) != 0;
    printf("mode=upstream_dudect_offline_csv_replay unit=ns no_rdtsc=1 holm_member=0\n");
    printf("complete_batches=%zu total_records=%zu warmup_records=%u "
           "partial_batch_records=%zu endpoint_discarded_records=%zu\n",
        batch_count,
        total_record_count,
        batch_count == 0u ? 0u : REPLAY_BATCH_RECORDS,
        batch_record_count,
        discarded_endpoint_count);
    if (context.ttest_ctxs[0]->n[0] > DUDECT_ENOUGH_MEASUREMENTS &&
        context.ttest_ctxs[0]->n[1] > DUDECT_ENOUGH_MEASUREMENTS) {
        printf("battery_dudect_status=%s\n",
            has_leakage_evidence ? "offline_leakage_found" : "offline_no_evidence_yet");
    } else {
        printf("battery_dudect_status=insufficient_measurements\n");
    }
    dudect_free(&context);
    return status;
}
