#define _POSIX_C_SOURCE 200809L

#include "inputs.h"
#include "mlkem.h"

#include <inttypes.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#define DUDECT_IMPLEMENTATION
#include "dudect.h"

#define M5_DUDECT_MEASUREMENTS_PER_BATCH 10000u
#define M5_DUDECT_MAXIMUM_BATCHES 21u
#define M5_DUDECT_LABEL_DOMAIN 5u
#define M5_DUDECT_RAW_HEADER                                                                       \
    "batch_index,sample_index,class,ticks_begin,ticks_end,elapsed_cycles,phase,"                   \
    "uncropped_test_member,time_unit\n"

static uint8_t encapsulation_key[MLKEM_ENCAPSULATION_KEY_BYTES];
static uint8_t decapsulation_key[MLKEM_DECAPSULATION_KEY_BYTES];
static uint8_t class_ciphertexts[2][MLKEM_CIPHERTEXT_BYTES];
static uint8_t batch_shared_secrets[M5_DUDECT_MEASUREMENTS_PER_BATCH][MLKEM_SHARED_SECRET_BYTES];
static int batch_operation_statuses[M5_DUDECT_MEASUREMENTS_PER_BATCH];
static size_t callback_count;
static uint64_t input_seed;
static uint64_t prepared_batch_count;
static size_t prepared_class_counts[2];
static volatile uint8_t result_sink;

static int prepare_class_pair(uint64_t test_seed)
{
    input_seed = test_seed;
    if (generate_test_key_pair(test_seed, encapsulation_key, decapsulation_key) != 0 ||
        generate_test_ciphertext(INPUT_MESSAGE_ZERO,
            test_seed,
            0u,
            encapsulation_key,
            class_ciphertexts[0]) != 0 ||
        generate_test_ciphertext(INPUT_MESSAGE_ONES,
            test_seed,
            0u,
            encapsulation_key,
            class_ciphertexts[1]) != 0) {
        return 1;
    }
    return strcmp(mlkem_implementation_name(), "reference") != 0;
}

uint8_t do_one_computation(uint8_t *input_data)
{
    if (callback_count >= M5_DUDECT_MEASUREMENTS_PER_BATCH) {
        abort();
    }
    batch_operation_statuses[callback_count] =
        mlkem_decapsulate(batch_shared_secrets[callback_count],
            MLKEM_SHARED_SECRET_BYTES,
            input_data,
            MLKEM_CIPHERTEXT_BYTES,
            decapsulation_key,
            MLKEM_DECAPSULATION_KEY_BYTES);
    ++callback_count;
    return 0u;
}

void prepare_inputs(dudect_config_t *configuration, uint8_t *input_data, uint8_t *classes)
{
    if (configuration->chunk_size != MLKEM_CIPHERTEXT_BYTES ||
        configuration->number_measurements > M5_DUDECT_MEASUREMENTS_PER_BATCH) {
        abort();
    }
    expand_test_seed(classes,
        configuration->number_measurements,
        input_seed,
        prepared_batch_count,
        M5_DUDECT_LABEL_DOMAIN);
    for (size_t measurement_index = 0u; measurement_index < configuration->number_measurements;
        ++measurement_index) {
        classes[measurement_index] &= 1u;
        ++prepared_class_counts[classes[measurement_index]];
        memcpy(input_data + measurement_index * configuration->chunk_size,
            class_ciphertexts[classes[measurement_index]],
            MLKEM_CIPHERTEXT_BYTES);
    }
    ++prepared_batch_count;
}

static int consume_batch(size_t expected_callback_count)
{
    if (callback_count != expected_callback_count) {
        return 1;
    }
    uint8_t consumed_value = 0u;
    int has_operation_failure = 0;
    for (size_t measurement_index = 0u; measurement_index < callback_count; ++measurement_index) {
        has_operation_failure |= batch_operation_statuses[measurement_index] != 0;
        for (size_t secret_byte_index = 0u; secret_byte_index < MLKEM_SHARED_SECRET_BYTES;
            ++secret_byte_index) {
            consumed_value ^= batch_shared_secrets[measurement_index][secret_byte_index];
        }
    }
    result_sink ^= consumed_value;
    erase_secret_bytes(batch_shared_secrets, sizeof(batch_shared_secrets));
    return has_operation_failure;
}

static int write_batch_samples(FILE *raw_file, size_t batch_index, const dudect_ctx_t *context)
{
    const char *phase = batch_index == 0u ? "warmup" : "formal";
    for (size_t measurement_index = 0u; measurement_index < M5_DUDECT_MEASUREMENTS_PER_BATCH;
        ++measurement_index) {
        int64_t begin_ticks = context->ticks[measurement_index];
        fprintf(raw_file,
            "%zu,%zu,%u,%" PRIi64 ",",
            batch_index,
            measurement_index,
            (unsigned)context->classes[measurement_index],
            begin_ticks);
        if (measurement_index + 1u < M5_DUDECT_MEASUREMENTS_PER_BATCH) {
            int64_t end_ticks = context->ticks[measurement_index + 1u];
            fprintf(raw_file, "%" PRIi64 ",", end_ticks);
            if (begin_ticks >= 0 && end_ticks >= begin_ticks) {
                int64_t elapsed_cycles = end_ticks - begin_ticks;
                int is_raw_test_member = batch_index != 0u && measurement_index >= 10u;
                fprintf(raw_file,
                    "%" PRIi64 ",%s,%d,cycles\n",
                    elapsed_cycles,
                    phase,
                    is_raw_test_member);
            } else {
                fprintf(raw_file, ",%s,0,cycles\n", phase);
            }
        } else {
            fprintf(raw_file, ",,%s,0,cycles\n", phase);
        }
    }
    return ferror(raw_file) || fflush(raw_file) != 0;
}

static int check_raw_writer_without_clock(const char *output_path)
{
    int64_t synthetic_ticks[M5_DUDECT_MEASUREMENTS_PER_BATCH];
    uint8_t synthetic_classes[M5_DUDECT_MEASUREMENTS_PER_BATCH];
    for (size_t measurement_index = 0u; measurement_index < M5_DUDECT_MEASUREMENTS_PER_BATCH;
        ++measurement_index) {
        synthetic_ticks[measurement_index] = (int64_t)measurement_index * 7;
        synthetic_classes[measurement_index] = (uint8_t)(measurement_index & 1u);
    }
    FILE *raw_file = fopen(output_path, "wx");
    if (raw_file == NULL) {
        return 1;
    }
    fputs("# SYNTHETIC SOFTWARE SELFTEST; NO HARDWARE CLOCKS\n", raw_file);
    fputs(M5_DUDECT_RAW_HEADER, raw_file);
    dudect_ctx_t context = {0};
    context.ticks = synthetic_ticks;
    context.classes = synthetic_classes;
    int status = write_batch_samples(raw_file, 0u, &context);
    status |= fclose(raw_file) != 0;
    return status;
}

static int check_callback_without_clock(void)
{
    if (prepare_class_pair(UINT64_C(31337)) != 0) {
        return 1;
    }
    uint8_t expected_shared_secret[MLKEM_SHARED_SECRET_BYTES];
    for (size_t class_index = 0u; class_index < 2u; ++class_index) {
        if (mlkem_decapsulate(expected_shared_secret,
                sizeof(expected_shared_secret),
                class_ciphertexts[class_index],
                MLKEM_CIPHERTEXT_BYTES,
                decapsulation_key,
                sizeof(decapsulation_key)) != 0) {
            return 1;
        }
        (void)do_one_computation(class_ciphertexts[class_index]);
        if (memcmp(expected_shared_secret,
                batch_shared_secrets[class_index],
                sizeof(expected_shared_secret)) != 0) {
            return 1;
        }
    }
    erase_secret_bytes(expected_shared_secret, sizeof(expected_shared_secret));
    int status = consume_batch(2u);
    erase_secret_bytes(decapsulation_key, sizeof(decapsulation_key));
    puts("M5 dudect callback self-test passed; no clocks or collection invoked");
    return status;
}

int main(int argument_count, char **arguments)
{
    if (argument_count == 2 && strcmp(arguments[1], "--self-test") == 0) {
        return check_callback_without_clock();
    }
    if (argument_count == 3 && strcmp(arguments[1], "--self-test-raw") == 0) {
        return check_raw_writer_without_clock(arguments[2]);
    }
    uint64_t test_seed;
    if (argument_count != 6 || strcmp(arguments[1], "--collect") != 0 ||
        strcmp(arguments[2], "--seed") != 0 ||
        parse_unsigned_integer(arguments[3], &test_seed) != 0 ||
        strcmp(arguments[4], "--raw") != 0) {
        fputs("usage: platform_m5_dudect --self-test | --collect --seed N --raw NEW.csv\n", stderr);
        return 2;
    }
    FILE *raw_file = fopen(arguments[5], "wx");
    if (raw_file == NULL) {
        perror("dudect raw output");
        return 1;
    }
    fputs(M5_DUDECT_RAW_HEADER, raw_file);
    if (prepare_class_pair(test_seed) != 0) {
        fclose(raw_file);
        return 1;
    }
    dudect_config_t configuration = {MLKEM_CIPHERTEXT_BYTES, M5_DUDECT_MEASUREMENTS_PER_BATCH};
    dudect_ctx_t context;
    if (dudect_init(&context, &configuration) != 0) {
        fclose(raw_file);
        return 1;
    }
    if (context.config == NULL || context.input_data == NULL || context.classes == NULL ||
        context.ticks == NULL || context.exec_times == NULL || context.percentiles == NULL) {
        dudect_free(&context);
        fclose(raw_file);
        return 1;
    }
    for (size_t test_index = 0u; test_index < DUDECT_TESTS; ++test_index) {
        if (context.ttest_ctxs[test_index] == NULL) {
            dudect_free(&context);
            fclose(raw_file);
            return 1;
        }
    }
    printf("module=M5 backend=reference seed=%" PRIu64
           " classes=message-zero,message-ones measurements_per_batch=%u maximum_batches=%u\n",
        test_seed,
        M5_DUDECT_MEASUREMENTS_PER_BATCH,
        M5_DUDECT_MAXIMUM_BATCHES);
    dudect_state_t state = DUDECT_NO_LEAKAGE_EVIDENCE_YET;
    size_t batch_count = 0u;
    int status = 0;
    while (batch_count < M5_DUDECT_MAXIMUM_BATCHES && state == DUDECT_NO_LEAKAGE_EVIDENCE_YET) {
        callback_count = 0u;
        state = dudect_main(&context);
        int batch_write_status = write_batch_samples(raw_file, batch_count, &context);
        if (consume_batch(M5_DUDECT_MEASUREMENTS_PER_BATCH) != 0 || batch_write_status != 0) {
            status = 1;
            break;
        }
        ++batch_count;
    }
    printf("stopped_after_batches=%zu state=%d prepared_class0=%zu prepared_class1=%zu "
           "holm_member=0 timer=upstream_rdtsc output_consumption=after_batch\n",
        batch_count,
        (int)state,
        prepared_class_counts[0],
        prepared_class_counts[1]);
    dudect_free(&context);
    status |= fclose(raw_file) != 0;
    erase_secret_bytes(decapsulation_key, sizeof(decapsulation_key));
    return status;
}
