#define _POSIX_C_SOURCE 200809L
#ifdef __APPLE__
#define _DARWIN_C_SOURCE
#endif
#include "build_identity.h"
#include "inputs.h"
#include "src/fips202/fips202.h"
#ifdef BASELINE_BATCH_WORKLOAD
#include "batch_measurement.h"
#endif

#include <inttypes.h>
#include <stdatomic.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/stat.h>
#include <sys/utsname.h>
#include <time.h>
#include <unistd.h>
#ifdef __APPLE__
#include <mach-o/dyld.h>
#include <sys/sysctl.h>
#endif

struct measurement_sample {
    uint8_t ciphertext[MLKEM_CIPHERTEXT_BYTES];
    enum input_category category;
    uint64_t elapsed_nanoseconds;
};

#ifdef BASELINE_BATCH_WORKLOAD
#define MEASUREMENT_ARGUMENT_COUNT 7
#define CSV_ARGUMENT_INDEX 5
#define METADATA_ARGUMENT_INDEX 6
#define MEASUREMENT_METHOD "candidate"
#define MEASUREMENT_FORMAT "reference_batch_v1"

struct batch_window {
    size_t first_input_index;
    size_t call_count;
    size_t category_counts[3];
    uint64_t total_nanoseconds;
};

static size_t measurement_batch_size = 1;
static struct batch_window *batch_windows;
#else
#define MEASUREMENT_ARGUMENT_COUNT 6
#define CSV_ARGUMENT_INDEX 4
#define METADATA_ARGUMENT_INDEX 5
#define MEASUREMENT_METHOD "baseline"
#define MEASUREMENT_FORMAT "reference_ordinary_v1"
#ifdef BASELINE_ORDINARY_WORKLOAD
static const size_t measurement_batch_size = 1;
#endif
#endif

#ifdef BASELINE_ORDINARY_WORKLOAD
#define MEASUREMENT_CATEGORY_COUNT 3u
#define EMPTY_WINDOW_COUNT 1000u
static uint64_t clock_read_steps_nanoseconds[10000];
static uint64_t empty_windows_nanoseconds[EMPTY_WINDOW_COUNT];

struct measurement_accounting {
    uint64_t start_nanoseconds;
    uint64_t preparation_end_nanoseconds;
    uint64_t warmup_end_nanoseconds;
    uint64_t collection_end_nanoseconds;
    uint64_t warmup_attempted_calls;
    uint64_t warmup_completed_calls;
    uint64_t formal_attempted_calls;
    uint64_t formal_completed_calls;
    uint64_t outputs_consumed;
    uint8_t ordered_input_digest[32];
};
static struct measurement_accounting accounting;
#else
#define MEASUREMENT_CATEGORY_COUNT INPUT_CATEGORY_COUNT
#endif

static volatile uint8_t result_sink;

static void read_cpu_model(char *cpu_model, size_t cpu_model_capacity_bytes)
{
    (void)snprintf(cpu_model, cpu_model_capacity_bytes, "unavailable");
#ifdef __APPLE__
    if (sysctlbyname("machdep.cpu.brand_string", cpu_model, &cpu_model_capacity_bytes, NULL, 0) !=
        0) {
        (void)snprintf(cpu_model, cpu_model_capacity_bytes, "unavailable");
    }
#else
    FILE *cpu_file = fopen("/proc/cpuinfo", "r");
    char information_line[256];
    if (cpu_file == NULL) {
        return;
    }
    while (fgets(information_line, sizeof(information_line), cpu_file) != NULL) {
        if (strncmp(information_line, "model name", 10) == 0) {
            const char *model_value = strchr(information_line, ':');
            if (model_value != NULL) {
                (void)snprintf(cpu_model, cpu_model_capacity_bytes, "%s", model_value + 1);
                cpu_model[strcspn(cpu_model, "\r\n")] = '\0';
            }
            break;
        }
    }
    (void)fclose(cpu_file);
#endif
}

static int read_monotonic_nanoseconds(uint64_t *timestamp_nanoseconds)
{
    struct timespec timestamp;
    if (clock_gettime(CLOCK_MONOTONIC, &timestamp) != 0 || timestamp.tv_sec < 0 ||
        timestamp.tv_nsec < 0 || timestamp.tv_nsec >= 1000000000L) {
        return 1;
    }
    if ((uint64_t)timestamp.tv_sec >
        (UINT64_MAX - (uint64_t)timestamp.tv_nsec) / UINT64_C(1000000000)) {
        return 1;
    }
    *timestamp_nanoseconds =
        (uint64_t)timestamp.tv_sec * UINT64_C(1000000000) + (uint64_t)timestamp.tv_nsec;
    return 0;
}

static int check_timer(uint64_t *resolution_nanoseconds)
{
    struct timespec clock_resolution;
    uint64_t previous_nanoseconds;
    uint64_t current_nanoseconds;
    int has_clock_progress = 0;
    if (clock_getres(CLOCK_MONOTONIC, &clock_resolution) != 0 || clock_resolution.tv_sec < 0 ||
        clock_resolution.tv_nsec < 0) {
        return 1;
    }
    *resolution_nanoseconds = (uint64_t)clock_resolution.tv_sec * UINT64_C(1000000000) +
        (uint64_t)clock_resolution.tv_nsec;
    if (*resolution_nanoseconds == 0 || read_monotonic_nanoseconds(&previous_nanoseconds) != 0) {
        return 1;
    }
    for (unsigned check_index = 0; check_index < 10000u; ++check_index) {
        if (read_monotonic_nanoseconds(&current_nanoseconds) != 0 ||
            current_nanoseconds < previous_nanoseconds) {
            return 1;
        }
        if (current_nanoseconds > previous_nanoseconds) {
            has_clock_progress = 1;
        }
#ifdef BASELINE_ORDINARY_WORKLOAD
        clock_read_steps_nanoseconds[check_index] = current_nanoseconds - previous_nanoseconds;
#endif
        previous_nanoseconds = current_nanoseconds;
    }
#ifdef BASELINE_ORDINARY_WORKLOAD
    for (unsigned window_index = 0; window_index < EMPTY_WINDOW_COUNT; ++window_index) {
        uint64_t start_nanoseconds;
        uint64_t end_nanoseconds;
        if (read_monotonic_nanoseconds(&start_nanoseconds) != 0) {
            return 1;
        }
        atomic_signal_fence(memory_order_seq_cst);
        atomic_signal_fence(memory_order_seq_cst);
        if (read_monotonic_nanoseconds(&end_nanoseconds) != 0 ||
            end_nanoseconds < start_nanoseconds) {
            return 1;
        }
        empty_windows_nanoseconds[window_index] = end_nanoseconds - start_nanoseconds;
    }
#endif
    return has_clock_progress ? 0 : 1;
}

#ifdef BASELINE_ORDINARY_WORKLOAD
static int hash_ordered_inputs(const struct measurement_sample *samples,
    size_t sample_count,
    const uint8_t encapsulation_key[MLKEM_ENCAPSULATION_KEY_BYTES])
{
    static const uint8_t stream_header[] = "ordinary_input_stream_v1:ML-KEM-768";
    size_t header_bytes = sizeof(stream_header) - 1u;
    size_t input_byte_count = header_bytes + MLKEM_ENCAPSULATION_KEY_BYTES + 8u +
        sample_count * (1u + MLKEM_CIPHERTEXT_BYTES);
    uint8_t *input_bytes = malloc(input_byte_count);
    if (input_bytes == NULL) {
        return 1;
    }
    memcpy(input_bytes, stream_header, header_bytes);
    memcpy(input_bytes + header_bytes, encapsulation_key, MLKEM_ENCAPSULATION_KEY_BYTES);
    size_t write_offset = header_bytes + MLKEM_ENCAPSULATION_KEY_BYTES;
    for (unsigned byte_index = 0; byte_index < 8u; ++byte_index) {
        input_bytes[write_offset++] = (uint8_t)((uint64_t)sample_count >> (8u * byte_index));
    }
    for (size_t sample_index = 0; sample_index < sample_count; ++sample_index) {
        input_bytes[write_offset++] = (uint8_t)samples[sample_index].category;
        memcpy(input_bytes + write_offset,
            samples[sample_index].ciphertext,
            MLKEM_CIPHERTEXT_BYTES);
        write_offset += MLKEM_CIPHERTEXT_BYTES;
    }
    mlk_sha3_256(accounting.ordered_input_digest, input_bytes, input_byte_count);
    free(input_bytes);
    return 0;
}

static int finish_cost_record(FILE *cost_file, int operation_status)
{
    uint64_t finish_nanoseconds;
    if (read_monotonic_nanoseconds(&finish_nanoseconds) != 0 ||
        finish_nanoseconds < accounting.start_nanoseconds) {
        (void)fclose(cost_file);
        return 1;
    }
    if (fprintf(cost_file,
            "final_state=%s\nstart_ns=%" PRIu64 "\npreparation_end_ns=%" PRIu64
            "\nwarmup_end_ns=%" PRIu64 "\ncollection_end_ns=%" PRIu64 "\nfinish_ns=%" PRIu64
            "\nchild_total_wall_ns=%" PRIu64 "\nwarmup_attempted_calls=%" PRIu64
            "\nwarmup_completed_calls=%" PRIu64 "\nformal_attempted_calls=%" PRIu64
            "\nformal_completed_calls=%" PRIu64 "\noutputs_consumed=%" PRIu64
            "\ncost_file_final_write=outside_child_total_use_parent_wall\n",
            operation_status == 0 ? "complete" : "failed",
            accounting.start_nanoseconds,
            accounting.preparation_end_nanoseconds,
            accounting.warmup_end_nanoseconds,
            accounting.collection_end_nanoseconds,
            finish_nanoseconds,
            finish_nanoseconds - accounting.start_nanoseconds,
            accounting.warmup_attempted_calls,
            accounting.warmup_completed_calls,
            accounting.formal_attempted_calls,
            accounting.formal_completed_calls,
            accounting.outputs_consumed) < 0) {
        operation_status = 1;
    }
    if (fclose(cost_file) != 0) {
        operation_status = 1;
    }
    return operation_status;
}

static int save_workload_identity(FILE *metadata_file, size_t sample_count)
{
    if (fprintf(metadata_file,
            "paired_metadata_version=paired_workload_v1\nmethod=" MEASUREMENT_METHOD
            "\nbatch_size=%zu\n"
            "parameter_set=ML-KEM-768\ninput_rule=ordinary_input_stream_v1\n"
            "upstream_commit=b3ba7b32773e657dd37f6f87bce82528459ad8a4\n"
            "valid_count=%zu\nbit_flipped_count=%zu\nrandom_count=%zu\n"
            "formal_attempted_calls=%" PRIu64 "\nformal_completed_calls=%" PRIu64
            "\nwarmup_attempted_calls=%" PRIu64 "\nwarmup_completed_calls=%" PRIu64
            "\noutputs_consumed=%" PRIu64 "\nordered_input_digest_algorithm=SHA3-256\n"
            "ordered_input_digest=",
            measurement_batch_size,
            sample_count / 3u,
            sample_count / 3u,
            sample_count / 3u,
            accounting.formal_attempted_calls,
            accounting.formal_completed_calls,
            accounting.warmup_attempted_calls,
            accounting.warmup_completed_calls,
            accounting.outputs_consumed) < 0) {
        return 1;
    }
    for (size_t byte_index = 0; byte_index < 32u; ++byte_index) {
        if (fprintf(metadata_file, "%02x", accounting.ordered_input_digest[byte_index]) < 0) {
            return 1;
        }
    }
    return fputc('\n', metadata_file) == EOF;
}

static int save_timer_diagnostics(FILE *metadata_file)
{
    uint64_t minimum_positive_step_nanoseconds = UINT64_MAX;
    uint64_t maximum_step_nanoseconds = 0;
    size_t zero_step_count = 0;
    uint64_t empty_minimum_nanoseconds = UINT64_MAX;
    uint64_t empty_maximum_nanoseconds = 0;
    size_t empty_zero_count = 0;
    long double empty_total_nanoseconds = 0.0L;
    for (size_t step_index = 0;
        step_index < sizeof(clock_read_steps_nanoseconds) / sizeof(clock_read_steps_nanoseconds[0]);
        ++step_index) {
        uint64_t step_nanoseconds = clock_read_steps_nanoseconds[step_index];
        if (step_nanoseconds == 0) {
            ++zero_step_count;
        } else if (step_nanoseconds < minimum_positive_step_nanoseconds) {
            minimum_positive_step_nanoseconds = step_nanoseconds;
        }
        if (step_nanoseconds > maximum_step_nanoseconds) {
            maximum_step_nanoseconds = step_nanoseconds;
        }
        if (fprintf(metadata_file,
                "clock_read_step=%zu elapsed_ns=%" PRIu64 "\n",
                step_index,
                step_nanoseconds) < 0) {
            return 1;
        }
    }
    for (size_t window_index = 0; window_index < EMPTY_WINDOW_COUNT; ++window_index) {
        uint64_t duration_nanoseconds = empty_windows_nanoseconds[window_index];
        empty_total_nanoseconds += (long double)duration_nanoseconds;
        if (duration_nanoseconds == 0) {
            ++empty_zero_count;
        }
        if (duration_nanoseconds < empty_minimum_nanoseconds) {
            empty_minimum_nanoseconds = duration_nanoseconds;
        }
        if (duration_nanoseconds > empty_maximum_nanoseconds) {
            empty_maximum_nanoseconds = duration_nanoseconds;
        }
        if (fprintf(metadata_file,
                "empty_window=%zu elapsed_ns=%" PRIu64 "\n",
                window_index,
                duration_nanoseconds) < 0) {
            return 1;
        }
    }
    return fprintf(metadata_file,
               "clock_monotonicity=passed\nclock_read_count=10001\nclock_zero_step_count=%zu\n"
               "clock_minimum_positive_step_ns=%" PRIu64 "\nclock_maximum_step_ns=%" PRIu64
               "\nempty_window_count=%u\nempty_window_zero_count=%zu\nempty_window_mean_ns=%.6Lf\n"
               "empty_window_min_ns=%" PRIu64 "\nempty_window_max_ns=%" PRIu64 "\n"
               "overhead_subtraction=none\n",
               zero_step_count,
               minimum_positive_step_nanoseconds,
               maximum_step_nanoseconds,
               EMPTY_WINDOW_COUNT,
               empty_zero_count,
               empty_total_nanoseconds / (long double)EMPTY_WINDOW_COUNT,
               empty_minimum_nanoseconds,
               empty_maximum_nanoseconds) < 0;
}
#endif

static uint64_t draw_order_value(uint64_t test_seed, uint64_t *draw_index, uint64_t upper_bound)
{
    uint64_t random_value;
    uint64_t rejection_threshold = (UINT64_C(0) - upper_bound) % upper_bound;
    do {
        uint8_t random_bytes[8];
        expand_test_seed(random_bytes, sizeof(random_bytes), test_seed, (*draw_index)++, 4);
        random_value = 0;
        for (unsigned byte_index = 0; byte_index < 8u; ++byte_index) {
            random_value |= (uint64_t)random_bytes[byte_index] << (8u * byte_index);
        }
    } while (random_value < rejection_threshold);
    return random_value % upper_bound;
}

static int hash_running_executable(uint8_t executable_digest[32])
{
    char executable_path[4096];
    FILE *executable_file;
    struct stat file_status;
    uint8_t *executable_bytes;
    size_t executable_byte_count;
    int operation_status = 0;
#ifdef __APPLE__
    uint32_t executable_path_capacity_bytes = (uint32_t)sizeof(executable_path);
    if (_NSGetExecutablePath(executable_path, &executable_path_capacity_bytes) != 0) {
        return 1;
    }
#else
    ssize_t path_byte_count =
        readlink("/proc/self/exe", executable_path, sizeof(executable_path) - 1u);
    if (path_byte_count < 0 || (size_t)path_byte_count >= sizeof(executable_path) - 1u) {
        return 1;
    }
    executable_path[path_byte_count] = '\0';
#endif
    executable_file = fopen(executable_path, "rb");
    if (executable_file == NULL) {
        return 1;
    }
    if (fstat(fileno(executable_file), &file_status) != 0 || file_status.st_size <= 0 ||
        file_status.st_size > 67108864) {
        (void)fclose(executable_file);
        return 1;
    }
    executable_byte_count = (size_t)file_status.st_size;
    executable_bytes = malloc(executable_byte_count);
    if (executable_bytes == NULL) {
        (void)fclose(executable_file);
        return 1;
    }
    if (fread(executable_bytes, 1, executable_byte_count, executable_file) !=
            executable_byte_count ||
        fgetc(executable_file) != EOF || ferror(executable_file)) {
        operation_status = 1;
    }
    if (fclose(executable_file) != 0) {
        operation_status = 1;
    }
    if (operation_status == 0) {
        mlk_sha3_256(executable_digest, executable_bytes, executable_byte_count);
    }
    free(executable_bytes);
    return operation_status;
}

static int save_measurements(const char *csv_path,
    const char *metadata_path,
    const char *run_id,
    uint64_t test_seed,
    const struct measurement_sample *samples,
    size_t sample_count,
    uint64_t resolution_nanoseconds,
    const uint8_t executable_digest[32])
{
    struct utsname machine_information;
    char cpu_model[256];
    FILE *csv_file;
    FILE *metadata_file;
    int operation_status = 0;
    time_t wall_clock_seconds = time(NULL);
    if (uname(&machine_information) != 0 || wall_clock_seconds == (time_t)-1) {
        return 1;
    }
    read_cpu_model(cpu_model, sizeof(cpu_model));
    csv_file = fopen(csv_path, "wx");
    if (csv_file == NULL) {
        return 1;
    }
    metadata_file = fopen(metadata_path, "wx");
    if (metadata_file == NULL) {
        (void)fclose(csv_file);
        (void)remove(csv_path);
        return 1;
    }
#ifdef BASELINE_BATCH_WORKLOAD
    (void)samples;
    size_t window_count = (sample_count + measurement_batch_size - 1u) / measurement_batch_size;
    if (fputs("run_id,block_id,method,window_index,input_start,input_end,call_count,valid_count,"
              "bit_flipped_count,random_count,elapsed_nanoseconds,time_unit,status\n",
            csv_file) == EOF) {
        operation_status = 1;
    }
    for (size_t window_index = 0; window_index < window_count; ++window_index) {
        const struct batch_window *window = &batch_windows[window_index];
        if (fprintf(csv_file,
                "%s,%s,candidate,%zu,%zu,%zu,%zu,%zu,%zu,%zu,%" PRIu64 ",ns,complete\n",
                run_id,
                run_id,
                window_index,
                window->first_input_index,
                window->first_input_index + window->call_count,
                window->call_count,
                window->category_counts[0],
                window->category_counts[1],
                window->category_counts[2],
                window->total_nanoseconds) < 0) {
            operation_status = 1;
        }
    }
#else
    if (fprintf(csv_file,
            "run_id,implementation,input_category,sample_index,elapsed_nanoseconds,time_unit\n") <
        0) {
        operation_status = 1;
    }
    for (size_t sample_index = 0; sample_index < sample_count; ++sample_index) {
        if (fprintf(csv_file,
                "%s,%s,%s,%zu,%" PRIu64 ",ns\n",
                run_id,
                mlkem_implementation_name(),
                input_category_name(samples[sample_index].category),
                sample_index,
                samples[sample_index].elapsed_nanoseconds) < 0) {
            operation_status = 1;
        }
    }
#endif
    if (fprintf(metadata_file,
            "run_id=%s\nimplementation=%s\ntest_seed=%" PRIu64 "\nsample_count=%zu\n"
            "clock=CLOCK_MONOTONIC\ntime_unit=ns\nclock_resolution_ns=%" PRIu64 "\n"
            "warmup_decapsulations=100\norder=balanced_fisher_yates_shake256_tag4\n"
            "wall_clock_unix_seconds=%jd\nos=%s %s\narchitecture=%s\ncpu_model=%s\n"
            "cpu_affinity=not_pinned\nfrequency_control=not_configured\n"
            "executable_digest_algorithm=SHA3-256\nexecutable_digest=",
            run_id,
            mlkem_implementation_name(),
            test_seed,
            sample_count,
            resolution_nanoseconds,
            (intmax_t)wall_clock_seconds,
            machine_information.sysname,
            machine_information.release,
            machine_information.machine,
            cpu_model) < 0) {
        operation_status = 1;
    }
    for (size_t byte_index = 0; byte_index < 32u; ++byte_index) {
        if (fprintf(metadata_file, "%02x", executable_digest[byte_index]) < 0) {
            operation_status = 1;
        }
    }
    if (fputc('\n', metadata_file) == EOF) {
        operation_status = 1;
    }
    for (size_t line_index = 0;
        line_index < sizeof(build_identity_lines) / sizeof(build_identity_lines[0]);
        ++line_index) {
        if (fputs(build_identity_lines[line_index], metadata_file) == EOF) {
            operation_status = 1;
        }
    }
#ifdef BASELINE_ORDINARY_WORKLOAD
    if (fputs("measurement_format=" MEASUREMENT_FORMAT "\n"
              "workload=valid:bit-flipped:random=1:1:1\n"
              "input_index_rule=category_local_index_shared_across_categories\n"
              "virtualization=not_verified_by_program_see_environment_log\n",
            metadata_file) == EOF ||
        save_timer_diagnostics(metadata_file) != 0 ||
        save_workload_identity(metadata_file, sample_count) != 0) {
        operation_status = 1;
    }
    if (fflush(metadata_file) != 0) {
        operation_status = 1;
    }
#endif
    if (fclose(csv_file) != 0) {
        operation_status = 1;
    }
#ifdef BASELINE_ORDINARY_WORKLOAD
    if (fprintf(metadata_file, "run_status=%s\n", operation_status == 0 ? "complete" : "failed") <
        0) {
        operation_status = 1;
    }
#endif
    if (fclose(metadata_file) != 0) {
        operation_status = 1;
    }
    return operation_status;
}

int main(int argument_count, char **argument_values)
{
    uint64_t test_seed;
    uint64_t samples_per_category;
    uint64_t resolution_nanoseconds;
    uint64_t order_draw_index = 0;
    uint8_t encapsulation_key[MLKEM_ENCAPSULATION_KEY_BYTES];
    uint8_t decapsulation_key[MLKEM_DECAPSULATION_KEY_BYTES];
    uint8_t shared_secret[MLKEM_SHARED_SECRET_BYTES];
    uint8_t executable_digest[32];
    struct measurement_sample *samples = NULL;
    size_t sample_count;
    int operation_status = 1;
#ifdef BASELINE_BATCH_WORKLOAD
    uint8_t batch_shared_secrets[MAXIMUM_BATCH_CALLS][MLKEM_SHARED_SECRET_BYTES] = {{0}};
#endif
#ifdef BASELINE_ORDINARY_WORKLOAD
    FILE *cost_file = NULL;
    char cost_path[4096];
#endif
    if (argument_count != MEASUREMENT_ARGUMENT_COUNT ||
        parse_unsigned_integer(argument_values[2], &test_seed) != 0 ||
        parse_unsigned_integer(argument_values[3], &samples_per_category) != 0 ||
        samples_per_category == 0 || samples_per_category > 20000u) {
#ifdef BASELINE_BATCH_WORKLOAD
        fputs("Usage: batch_benchmark RUN_ID SEED SAMPLES_PER_CATEGORY K CSV_FILE META_FILE\n",
            stderr);
#else
        fputs(
            "Usage: measure RUN_ID SEED SAMPLES_PER_CATEGORY CSV_FILE META_FILE (count 1..20000)\n",
            stderr);
#endif
        return 2;
    }
#ifdef BASELINE_BATCH_WORKLOAD
    uint64_t requested_batch_size;
    if (parse_unsigned_integer(argument_values[4], &requested_batch_size) != 0 ||
        (requested_batch_size != 1u && requested_batch_size != 4u && requested_batch_size != 16u)) {
        fputs("batch size must be 1, 4 or 16\n", stderr);
        return 2;
    }
    measurement_batch_size = (size_t)requested_batch_size;
#endif
    if (strlen(argument_values[1]) == 0 || strlen(argument_values[1]) > 64u) {
        fputs("invalid RUN_ID: length must be 1..64 characters\n", stderr);
        return 2;
    }
    for (const char *character = argument_values[1]; *character != '\0'; ++character) {
        if (!((*character >= 'a' && *character <= 'z') ||
                (*character >= 'A' && *character <= 'Z') ||
                (*character >= '0' && *character <= '9') || *character == '_' ||
                *character == '-')) {
            fputs("invalid RUN_ID: use only ASCII letters, digits, underscore or hyphen\n", stderr);
            return 2;
        }
    }
#ifdef BASELINE_ORDINARY_WORKLOAD
    int path_byte_count =
        snprintf(cost_path, sizeof(cost_path), "%s.cost", argument_values[CSV_ARGUMENT_INDEX]);
    if (path_byte_count < 0 || (size_t)path_byte_count >= sizeof(cost_path) ||
        read_monotonic_nanoseconds(&accounting.start_nanoseconds) != 0) {
        return 1;
    }
    cost_file = fopen(cost_path, "wx");
    if (cost_file == NULL) {
        return 1;
    }
    if (fprintf(cost_file,
            "cost_format=measurement_cost_v1\ninitial_state=started\nrun_id=%s\n",
            argument_values[1]) < 0 ||
        fflush(cost_file) != 0) {
        goto cleanup;
    }
#endif
    if (check_timer(&resolution_nanoseconds) != 0 ||
        hash_running_executable(executable_digest) != 0) {
        fputs("timer/executable identity check failed\n", stderr);
#ifdef BASELINE_ORDINARY_WORKLOAD
        goto cleanup;
#else
        return 1;
#endif
    }
    sample_count = (size_t)samples_per_category * MEASUREMENT_CATEGORY_COUNT;
    samples = calloc(sample_count, sizeof(*samples));
#ifdef BASELINE_BATCH_WORKLOAD
    batch_windows = calloc((sample_count + measurement_batch_size - 1u) / measurement_batch_size,
        sizeof(*batch_windows));
    if (batch_windows == NULL) {
        goto cleanup;
    }
#endif
    if (samples == NULL ||
        generate_test_key_pair(test_seed, encapsulation_key, decapsulation_key) != 0) {
        goto cleanup;
    }
    for (size_t sample_index = 0; sample_index < sample_count; ++sample_index) {
        samples[sample_index].category =
            (enum input_category)(sample_index % MEASUREMENT_CATEGORY_COUNT);
        if (generate_test_ciphertext(samples[sample_index].category,
                test_seed,
                sample_index / MEASUREMENT_CATEGORY_COUNT,
                encapsulation_key,
                samples[sample_index].ciphertext) != 0) {
            goto cleanup;
        }
    }
    for (size_t remaining_count = sample_count; remaining_count > 1u; --remaining_count) {
        size_t selected_index =
            (size_t)draw_order_value(test_seed, &order_draw_index, remaining_count);
        struct measurement_sample selected_sample = samples[selected_index];
        samples[selected_index] = samples[remaining_count - 1u];
        samples[remaining_count - 1u] = selected_sample;
    }
#ifdef BASELINE_ORDINARY_WORKLOAD
    if (hash_ordered_inputs(samples, sample_count, encapsulation_key) != 0 ||
        read_monotonic_nanoseconds(&accounting.preparation_end_nanoseconds) != 0) {
        goto cleanup;
    }
#endif
    for (unsigned warmup_index = 0; warmup_index < 100u; ++warmup_index) {
#ifdef BASELINE_ORDINARY_WORKLOAD
        ++accounting.warmup_attempted_calls;
#endif
        if (mlkem_decapsulate(shared_secret,
                sizeof(shared_secret),
                samples[warmup_index % sample_count].ciphertext,
                MLKEM_CIPHERTEXT_BYTES,
                decapsulation_key,
                sizeof(decapsulation_key)) != 0) {
            goto cleanup;
        }
        result_sink ^= shared_secret[0];
#ifdef BASELINE_ORDINARY_WORKLOAD
        ++accounting.warmup_completed_calls;
        ++accounting.outputs_consumed;
#endif
    }
#ifdef BASELINE_ORDINARY_WORKLOAD
    if (read_monotonic_nanoseconds(&accounting.warmup_end_nanoseconds) != 0) {
        goto cleanup;
    }
#endif
#ifdef BASELINE_BATCH_WORKLOAD
    for (size_t first_input_index = 0; first_input_index < sample_count;
        first_input_index += measurement_batch_size) {
        struct batch_window *window = &batch_windows[first_input_index / measurement_batch_size];
        const uint8_t *ciphertexts[MAXIMUM_BATCH_CALLS];
        int call_statuses[MAXIMUM_BATCH_CALLS];
        uint64_t start_nanoseconds;
        uint64_t end_nanoseconds;
        window->first_input_index = first_input_index;
        window->call_count = sample_count - first_input_index < measurement_batch_size
            ? sample_count - first_input_index
            : measurement_batch_size;
        for (size_t call_index = 0; call_index < window->call_count; ++call_index) {
            const struct measurement_sample *sample = &samples[first_input_index + call_index];
            ciphertexts[call_index] = sample->ciphertext;
            ++window->category_counts[(unsigned)sample->category];
        }
        accounting.formal_attempted_calls += (uint64_t)window->call_count;
        if (read_monotonic_nanoseconds(&start_nanoseconds) != 0) {
            accounting.formal_attempted_calls -= (uint64_t)window->call_count;
            goto cleanup;
        }
        atomic_signal_fence(memory_order_seq_cst);
        int batch_status = run_batch_decapsulations(window->call_count,
            ciphertexts,
            decapsulation_key,
            batch_shared_secrets,
            call_statuses);
        atomic_signal_fence(memory_order_seq_cst);
        if (read_monotonic_nanoseconds(&end_nanoseconds) != 0 ||
            end_nanoseconds < start_nanoseconds || batch_status != 0) {
            goto cleanup;
        }
        window->total_nanoseconds = end_nanoseconds - start_nanoseconds;
        int has_failed_call = 0;
        for (size_t call_index = 0; call_index < window->call_count; ++call_index) {
            if (call_statuses[call_index] != 0) {
                has_failed_call = 1;
            } else {
                ++accounting.formal_completed_calls;
                result_sink ^=
                    batch_shared_secrets[call_index][(first_input_index + call_index) % 32u];
                ++accounting.outputs_consumed;
            }
        }
        if (has_failed_call) {
            goto cleanup;
        }
    }
#else
    for (size_t sample_index = 0; sample_index < sample_count; ++sample_index) {
        uint64_t start_nanoseconds;
        uint64_t end_nanoseconds;
        int decapsulation_status;
#ifdef BASELINE_ORDINARY_WORKLOAD
        ++accounting.formal_attempted_calls;
#endif
        if (read_monotonic_nanoseconds(&start_nanoseconds) != 0) {
#ifdef BASELINE_ORDINARY_WORKLOAD
            --accounting.formal_attempted_calls;
#endif
            goto cleanup;
        }
        atomic_signal_fence(memory_order_seq_cst);
        decapsulation_status = mlkem_decapsulate(shared_secret,
            sizeof(shared_secret),
            samples[sample_index].ciphertext,
            MLKEM_CIPHERTEXT_BYTES,
            decapsulation_key,
            sizeof(decapsulation_key));
        atomic_signal_fence(memory_order_seq_cst);
        if (read_monotonic_nanoseconds(&end_nanoseconds) != 0 ||
            end_nanoseconds < start_nanoseconds) {
            goto cleanup;
        }
        if (decapsulation_status != 0) {
            goto cleanup;
        }
        samples[sample_index].elapsed_nanoseconds = end_nanoseconds - start_nanoseconds;
        /* 在计时结束后消费结果，文件输出等到整批测量结束。 */
        result_sink ^= shared_secret[sample_index % sizeof(shared_secret)];
#ifdef BASELINE_ORDINARY_WORKLOAD
        ++accounting.formal_completed_calls;
        ++accounting.outputs_consumed;
#endif
    }
#endif
#ifdef BASELINE_ORDINARY_WORKLOAD
    if (read_monotonic_nanoseconds(&accounting.collection_end_nanoseconds) != 0) {
        goto cleanup;
    }
#endif
    operation_status = save_measurements(argument_values[CSV_ARGUMENT_INDEX],
        argument_values[METADATA_ARGUMENT_INDEX],
        argument_values[1],
        test_seed,
        samples,
        sample_count,
        resolution_nanoseconds,
        executable_digest);
cleanup:
    erase_secret_bytes(decapsulation_key, sizeof(decapsulation_key));
    erase_secret_bytes(shared_secret, sizeof(shared_secret));
    free(samples);
#ifdef BASELINE_BATCH_WORKLOAD
    erase_secret_bytes(batch_shared_secrets, sizeof(batch_shared_secrets));
    free(batch_windows);
#endif
#ifdef BASELINE_ORDINARY_WORKLOAD
    if (cost_file != NULL) {
        operation_status = finish_cost_record(cost_file, operation_status);
    }
#endif
    if (operation_status != 0) {
        fputs("measurement failed; check resources and use new output paths\n", stderr);
    } else {
#ifdef BASELINE_BATCH_WORKLOAD
        printf("reference: saved raw window totals for %zu decapsulations; no statistical "
               "conclusion\n",
            sample_count);
#else
        printf("%s: saved %zu raw decapsulation times in ns; no statistical conclusion\n",
            mlkem_implementation_name(),
            sample_count);
#endif
    }
    return operation_status;
}
