#ifdef __APPLE__
#define _DARWIN_C_SOURCE
#else
#define _GNU_SOURCE
#endif

#include "diagnostic_stages.h"
#include "inputs.h"
#include "mlkem.h"
#include "trace_account.h"

#include <dlfcn.h>
#include <inttypes.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>

#define TRACE_EVENT_CAPACITY 128u
#define TRACE_STAGE_COUNT 8u

struct stage_descriptor {
    const char *symbol_suffix;
    const char *stage_id;
    const char *source_path;
    const char *source_line;
    const char *inline_extent;
};

struct function_accumulator {
    uint64_t function_id;
    char function_name[128];
    char stage_id[64];
    char source_path[160];
    char source_line[16];
    char inline_extent[128];
    uint64_t exclusive_sum[INPUT_CATEGORY_COUNT];
    uint64_t inclusive_sum[INPUT_CATEGORY_COUNT];
    size_t sample_count[INPUT_CATEGORY_COUNT];
};

static const struct stage_descriptor stage_descriptors[TRACE_STAGE_COUNT] = {
    {"baseline_stage_decode",
        "decode",
        "vendor/mlkem-native/mlkem/src/indcpa.c",
        "156",
        "baseline_stage_decode"},
    {"baseline_stage_decrypt",
        "decrypt",
        "vendor/mlkem-native/mlkem/src/indcpa.c",
        "598",
        "baseline_stage_decrypt"},
    {"baseline_stage_message_extraction",
        "message_extraction",
        "vendor/mlkem-native/mlkem/src/compress.c",
        "737",
        "baseline_stage_message_extraction"},
    {"baseline_stage_reencrypt_message",
        "reencryption",
        "vendor/mlkem-native/mlkem/src/compress.c",
        "697",
        "mlk_poly_frommsg"},
    {"baseline_stage_reencrypt",
        "reencryption",
        "vendor/mlkem-native/mlkem/src/indcpa.c",
        "518",
        "baseline_stage_reencrypt"},
    {"baseline_stage_compare",
        "compare",
        "vendor/mlkem-native/mlkem/src/verify.h",
        "338",
        "mlk_ct_memcmp_inlined"},
    {"baseline_stage_rejection_key",
        "rejection_key",
        "vendor/mlkem-native/mlkem/src/symmetric.h",
        "35",
        "mlk_hash_j_inlined"},
    {"baseline_stage_select",
        "selection",
        "vendor/mlkem-native/mlkem/src/verify.h",
        "388",
        "mlk_ct_cmov_zero_inlined"},
};

static volatile uint8_t result_sink;

static int describe_function(uint64_t function_id,
    uint64_t image_base,
    struct function_accumulator *accumulator)
{
    void *function_address = (void *)(uintptr_t)(image_base + function_id);
    Dl_info symbol_info;
    const char *symbol_name = "";
    accumulator->function_id = function_id;
    snprintf(accumulator->function_name,
        sizeof(accumulator->function_name),
        "fn_%llu",
        (unsigned long long)function_id);
    snprintf(accumulator->stage_id, sizeof(accumulator->stage_id), "unknown");
    snprintf(accumulator->source_path, sizeof(accumulator->source_path), "unknown");
    snprintf(accumulator->source_line, sizeof(accumulator->source_line), "0");
    snprintf(accumulator->inline_extent, sizeof(accumulator->inline_extent), "unknown");
    if (dladdr(function_address, &symbol_info) != 0 && symbol_info.dli_sname != NULL) {
        symbol_name = symbol_info.dli_sname;
        snprintf(accumulator->function_name, sizeof(accumulator->function_name), "%s", symbol_name);
    }
    for (size_t stage_index = 0; stage_index < TRACE_STAGE_COUNT; ++stage_index) {
        if (strstr(symbol_name, stage_descriptors[stage_index].symbol_suffix) != NULL) {
            snprintf(accumulator->stage_id,
                sizeof(accumulator->stage_id),
                "%s",
                stage_descriptors[stage_index].stage_id);
            snprintf(accumulator->source_path,
                sizeof(accumulator->source_path),
                "%s",
                stage_descriptors[stage_index].source_path);
            snprintf(accumulator->source_line,
                sizeof(accumulator->source_line),
                "%s",
                stage_descriptors[stage_index].source_line);
            snprintf(accumulator->inline_extent,
                sizeof(accumulator->inline_extent),
                "%s",
                stage_descriptors[stage_index].inline_extent);
            return 0;
        }
    }
    return 0;
}

static struct function_accumulator *
find_accumulator(struct function_accumulator *rows, size_t row_count, uint64_t function_id)
{
    for (size_t row_index = 0; row_index < row_count; ++row_index) {
        if (rows[row_index].function_id == function_id) {
            return &rows[row_index];
        }
    }
    return NULL;
}

static int write_candidates(const char *candidate_path,
    const struct function_accumulator *rows,
    size_t row_count)
{
    FILE *candidate_file = fopen(candidate_path, "wx");
    int stage_seen[TRACE_STAGE_COUNT] = {0};
    if (candidate_file == NULL) {
        return 1;
    }
    if (fprintf(candidate_file,
            "record_kind,stage_id,function_id,source_path,source_line,inline_extent,"
            "inclusive_difference_counts,exclusive_difference_counts,evidence_path\n") < 0) {
        (void)fclose(candidate_file);
        return 1;
    }
    for (size_t row_index = 0; row_index < row_count; ++row_index) {
        const struct function_accumulator *row = &rows[row_index];
        double exclusive_difference = 0.0;
        double inclusive_difference = 0.0;
        const char *record_kind = "candidate";
        if (row->sample_count[INPUT_MESSAGE_ZERO] == 0u ||
            row->sample_count[INPUT_MESSAGE_ONES] == 0u) {
            continue;
        }
        exclusive_difference = (double)row->exclusive_sum[INPUT_MESSAGE_ZERO] /
                (double)row->sample_count[INPUT_MESSAGE_ZERO] -
            (double)row->exclusive_sum[INPUT_MESSAGE_ONES] /
                (double)row->sample_count[INPUT_MESSAGE_ONES];
        inclusive_difference = (double)row->inclusive_sum[INPUT_MESSAGE_ZERO] /
                (double)row->sample_count[INPUT_MESSAGE_ZERO] -
            (double)row->inclusive_sum[INPUT_MESSAGE_ONES] /
                (double)row->sample_count[INPUT_MESSAGE_ONES];
        for (size_t stage_index = 0; stage_index < TRACE_STAGE_COUNT; ++stage_index) {
            if (strcmp(row->stage_id, stage_descriptors[stage_index].stage_id) == 0) {
                stage_seen[stage_index] = 1;
            }
        }
        if (fprintf(candidate_file,
                "%s,%s,%s,%s,%s,%s,%.0f,%.0f,%s\n",
                record_kind,
                row->stage_id,
                row->function_name,
                row->source_path,
                row->source_line,
                row->inline_extent,
                inclusive_difference,
                exclusive_difference,
                candidate_path) < 0) {
            (void)fclose(candidate_file);
            return 1;
        }
    }
    for (size_t stage_index = 0; stage_index < TRACE_STAGE_COUNT; ++stage_index) {
        if (stage_seen[stage_index]) {
            continue;
        }
        if (fprintf(candidate_file,
                "uncovered,%s,none,%s,%s,%s,0,0,%s\n",
                stage_descriptors[stage_index].stage_id,
                stage_descriptors[stage_index].source_path,
                stage_descriptors[stage_index].source_line,
                stage_descriptors[stage_index].inline_extent,
                candidate_path) < 0) {
            (void)fclose(candidate_file);
            return 1;
        }
    }
    return fclose(candidate_file) == 0 ? 0 : 1;
}

int main(int argc, char **argv)
{
    uint64_t test_seed;
    uint64_t samples_per_category;
    size_t sample_count;
    int use_clock;
    struct trace_event events[TRACE_EVENT_CAPACITY];
    struct trace_store store;
    struct function_accumulator *rows;
    size_t row_count = 0u;
    size_t row_capacity;
    Dl_info image_info;
    void *stage_probe;
    uint64_t image_base;
    uint8_t encapsulation_key[MLKEM_ENCAPSULATION_KEY_BYTES];
    uint8_t decapsulation_key[MLKEM_DECAPSULATION_KEY_BYTES];
    uint8_t shared_secret[MLKEM_SHARED_SECRET_BYTES];
    uint8_t (*ciphertexts)[MLKEM_CIPHERTEXT_BYTES] = NULL;
    enum input_category *categories = NULL;
    FILE *event_file = NULL;
    FILE *summary_file = NULL;
    uint64_t outer_sum[INPUT_CATEGORY_COUNT] = {0};
    size_t outer_count[INPUT_CATEGORY_COUNT] = {0};
    int operation_status = 1;
    if (argc != 7 || (strcmp(argv[1], "--account") != 0 && strcmp(argv[1], "--timing") != 0) ||
        parse_unsigned_integer(argv[2], &test_seed) != 0 ||
        parse_unsigned_integer(argv[3], &samples_per_category) != 0 || samples_per_category == 0u ||
        samples_per_category > 1000u) {
        fputs("usage: diagnostic_trace --account|--timing SEED SAMPLES_PER_CATEGORY "
              "EVENTS SUMMARY CANDIDATES\n",
            stderr);
        return 1;
    }
    use_clock = strcmp(argv[1], "--timing") == 0;
    stage_probe = dlsym(RTLD_DEFAULT, "baseline_stage_decode");
    if (stage_probe == NULL || dladdr(stage_probe, &image_info) == 0 ||
        image_info.dli_fbase == NULL) {
        return 1;
    }
    image_base = (uint64_t)(uintptr_t)image_info.dli_fbase;
    if (trace_store_init(&store, events, TRACE_EVENT_CAPACITY) != 0) {
        return 1;
    }
    trace_runtime_bind(&store, image_base, use_clock);
    sample_count = (size_t)samples_per_category * INPUT_CATEGORY_COUNT;
    row_capacity = 64u;
    rows = calloc(row_capacity, sizeof(*rows));
    ciphertexts = calloc(sample_count, sizeof(*ciphertexts));
    categories = calloc(sample_count, sizeof(*categories));
    event_file = fopen(argv[4], "wx");
    summary_file = fopen(argv[5], "wx");
    if (rows == NULL || ciphertexts == NULL || categories == NULL || event_file == NULL ||
        summary_file == NULL ||
        generate_test_key_pair(test_seed, encapsulation_key, decapsulation_key) != 0) {
        goto cleanup;
    }
    if (fprintf(event_file, "%s\n", trace_event_header()) < 0) {
        goto cleanup;
    }
    for (size_t sample_index = 0; sample_index < sample_count; ++sample_index) {
        categories[sample_index] = (enum input_category)(sample_index % INPUT_CATEGORY_COUNT);
        if (generate_test_ciphertext(categories[sample_index],
                test_seed,
                sample_index / INPUT_CATEGORY_COUNT,
                encapsulation_key,
                ciphertexts[sample_index]) != 0) {
            goto cleanup;
        }
    }
    for (size_t sample_index = 0; sample_index < sample_count; ++sample_index) {
        struct trace_function_total totals[TRACE_FUNCTION_CAPACITY];
        size_t total_count = 0u;
        uint64_t outermost = 0u;
        uint64_t start_counts = 0u;
        uint64_t end_counts = 0u;
        struct timespec start_time;
        struct timespec end_time;
        if (clock_gettime(CLOCK_MONOTONIC, &start_time) != 0) {
            goto cleanup;
        }
        trace_runtime_begin_sample(sample_index + 1u);
        if (mlkem_decapsulate(shared_secret,
                sizeof(shared_secret),
                ciphertexts[sample_index],
                MLKEM_CIPHERTEXT_BYTES,
                decapsulation_key,
                sizeof(decapsulation_key)) != 0) {
            trace_runtime_end_sample();
            goto cleanup;
        }
        trace_runtime_end_sample();
        if (clock_gettime(CLOCK_MONOTONIC, &end_time) != 0 || trace_runtime_failed()) {
            goto cleanup;
        }
        start_counts =
            (uint64_t)start_time.tv_sec * UINT64_C(1000000000) + (uint64_t)start_time.tv_nsec;
        end_counts = (uint64_t)end_time.tv_sec * UINT64_C(1000000000) + (uint64_t)end_time.tv_nsec;
        if (end_counts < start_counts) {
            goto cleanup;
        }
        result_sink ^= shared_secret[sample_index % MLKEM_SHARED_SECRET_BYTES];
        outer_sum[categories[sample_index]] += end_counts - start_counts;
        outer_count[categories[sample_index]] += 1u;
        if (trace_account_sample(&store,
                sample_index + 1u,
                totals,
                TRACE_FUNCTION_CAPACITY,
                &total_count,
                &outermost) != 0) {
            goto cleanup;
        }
        for (size_t event_index = 0; event_index < store.event_count; ++event_index) {
            if (trace_event_write(event_file, &store.events[event_index]) != 0) {
                goto cleanup;
            }
        }
        for (size_t total_index = 0; total_index < total_count; ++total_index) {
            struct function_accumulator *row =
                find_accumulator(rows, row_count, totals[total_index].function_id);
            if (row == NULL) {
                if (row_count >= row_capacity) {
                    goto cleanup;
                }
                row = &rows[row_count];
                describe_function(totals[total_index].function_id, image_base, row);
                row_count += 1u;
            }
            row->exclusive_sum[categories[sample_index]] += totals[total_index].exclusive_counts;
            row->inclusive_sum[categories[sample_index]] += totals[total_index].inclusive_counts;
            row->sample_count[categories[sample_index]] += 1u;
        }
    }
    if (fprintf(summary_file,
            "mode=%s\nhook_cost_not_subtracted=yes\ncompiler_events=enter_exit\n"
            "inline_mapping stage=reencryption wrapper=baseline_stage_reencrypt_message "
            "inlined=mlk_poly_frommsg\n"
            "inline_mapping stage=compare wrapper=baseline_stage_compare inlined=mlk_ct_memcmp\n"
            "inline_mapping stage=rejection_key wrapper=baseline_stage_rejection_key "
            "inlined=mlk_hash_j\n"
            "inline_mapping stage=selection wrapper=baseline_stage_select "
            "inlined=mlk_ct_cmov_zero\n",
            use_clock ? "timing" : "account") < 0) {
        goto cleanup;
    }
    for (unsigned category_index = 0; category_index < INPUT_CATEGORY_COUNT; ++category_index) {
        double mean_counts = outer_count[category_index] == 0u
            ? 0.0
            : (double)outer_sum[category_index] / (double)outer_count[category_index];
        if (fprintf(summary_file,
                "outer_mean_counts_%s=%.3f\n",
                input_category_name((enum input_category)category_index),
                mean_counts) < 0) {
            goto cleanup;
        }
    }
    if (write_candidates(argv[6], rows, row_count) != 0 || fclose(event_file) != 0 ||
        fclose(summary_file) != 0) {
        event_file = NULL;
        summary_file = NULL;
        goto cleanup;
    }
    event_file = NULL;
    summary_file = NULL;
    operation_status = 0;
cleanup:
    if (event_file != NULL) {
        (void)fclose(event_file);
    }
    if (summary_file != NULL) {
        (void)fclose(summary_file);
    }
    erase_secret_bytes(decapsulation_key, sizeof(decapsulation_key));
    erase_secret_bytes(shared_secret, sizeof(shared_secret));
    free(rows);
    free(ciphertexts);
    free(categories);
    if (operation_status != 0) {
        fputs("diagnostic trace failed\n", stderr);
    }
    return operation_status;
}
