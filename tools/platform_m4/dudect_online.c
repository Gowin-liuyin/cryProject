#define _POSIX_C_SOURCE 200809L

#include "compare.h"
#include "inputs.h"

#include <inttypes.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#define DUDECT_IMPLEMENTATION
#include "dudect.h"

#define M4_DUDECT_BATCH_CALLS 20000U
#define M4_DUDECT_CHUNK_BYTES (PLATFORM_M4_INPUT_BYTES * 2U)

static uint64_t input_order_state;

uint8_t do_one_computation(uint8_t *input_data)
{
    int is_equal = 0;
    if (m4_compare_checked(input_data,
            PLATFORM_M4_INPUT_BYTES,
            input_data + PLATFORM_M4_INPUT_BYTES,
            PLATFORM_M4_INPUT_BYTES,
            &is_equal) != 0) {
        abort();
    }
    return (uint8_t)is_equal;
}

void prepare_inputs(dudect_config_t *configuration, uint8_t *input_data, uint8_t *classes)
{
    if (configuration->chunk_size != M4_DUDECT_CHUNK_BYTES ||
        m4_prepare_class_order(classes, configuration->number_measurements, &input_order_state) !=
            0) {
        abort();
    }
    for (size_t input_index = 0U; input_index < configuration->number_measurements; input_index++) {
        uint8_t *case_input = input_data + input_index * configuration->chunk_size;
        if (m4_prepare_case(classes[input_index],
                case_input,
                case_input + PLATFORM_M4_INPUT_BYTES) != 0) {
            abort();
        }
    }
}

int main(int argument_count, char **argument_values)
{
    if (argument_count == 2 && strcmp(argument_values[1], "--describe") == 0) {
        puts("module=M4 mode=upstream_dudect_online unit=tsc_ticks holm_member=0 "
             "timing_collection=not_run batch_calls=20000");
        return 0;
    }
    uint64_t requested_batches;
    uint64_t order_seed;
    if (argument_count != 5 || strcmp(argument_values[1], "--collect") != 0 ||
        m4_parse_unsigned(argument_values[3], 2U, 100U, &requested_batches) != 0 ||
        m4_parse_unsigned(argument_values[4], 1U, UINT64_MAX, &order_seed) != 0) {
        fputs("usage: m4_dudect --describe | --collect NEW_CYCLES.csv BATCHES SEED\n", stderr);
        return 2;
    }
    FILE *raw_file = fopen(argument_values[2], "wx");
    if (raw_file == NULL) {
        return 1;
    }
    int output_status = fputs("batch_index,sample_index,class_label,start_tsc,finish_tsc,"
                              "elapsed_tsc_ticks\n",
                            raw_file) < 0;
    dudect_config_t configuration = {M4_DUDECT_CHUNK_BYTES, M4_DUDECT_BATCH_CALLS};
    dudect_ctx_t context = {0};
    if (dudect_init(&context, &configuration) != 0) {
        fclose(raw_file);
        return 1;
    }
    input_order_state = order_seed;
    int has_leakage_evidence = 0;
    printf("module=M4 case=artificial_compare variant=%s mode=upstream_dudect_online "
           "unit=tsc_ticks holm_member=0 seed=%" PRIu64 " batch_calls=%u requested_batches=%" PRIu64
           "\n",
        M4_VARIANT_NAME,
        order_seed,
        M4_DUDECT_BATCH_CALLS,
        requested_batches);
    for (uint64_t batch_index = 0U; batch_index < requested_batches; batch_index++) {
        if (dudect_main(&context) == DUDECT_LEAKAGE_FOUND) {
            has_leakage_evidence = 1;
        }
        /* ticks 不受首批百分位排序影响，保留全部相邻读数及被上游丢弃的端点。 */
        for (size_t sample_index = 0U; sample_index + 1U < configuration.number_measurements;
            sample_index++) {
            uint64_t start_ticks = (uint64_t)context.ticks[sample_index];
            uint64_t finish_ticks = (uint64_t)context.ticks[sample_index + 1U];
            int has_backward_ticks = finish_ticks < start_ticks;
            uint64_t interval_ticks =
                has_backward_ticks ? start_ticks - finish_ticks : finish_ticks - start_ticks;
            if (fprintf(raw_file,
                    "%" PRIu64 ",%zu,%u,%" PRIu64 ",%" PRIu64 ",%s%" PRIu64 "\n",
                    batch_index,
                    sample_index,
                    (unsigned)context.classes[sample_index],
                    start_ticks,
                    finish_ticks,
                    has_backward_ticks ? "-" : "",
                    interval_ticks) < 0) {
                output_status = 1;
            }
        }
    }
    printf("battery_dudect_status=%s\n"
           "completed_batches=%" PRIu64 " total_calls=%" PRIu64
           " warmup_calls=%u intervals_per_batch=%u endpoint_discarded_per_update=11\n",
        has_leakage_evidence ? "online_leakage_found" : "online_no_evidence_yet",
        requested_batches,
        requested_batches * M4_DUDECT_BATCH_CALLS,
        M4_DUDECT_BATCH_CALLS,
        M4_DUDECT_BATCH_CALLS - 1U);
    output_status |= dudect_free(&context) != 0;
    output_status |= fclose(raw_file) != 0;
    output_status |= ferror(stdout) != 0;
    return output_status;
}
