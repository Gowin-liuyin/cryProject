#define _POSIX_C_SOURCE 200809L
#ifdef __APPLE__
#define _DARWIN_C_SOURCE
#endif
#include "inputs.h"
#include "src/fips202/fips202.h"
#include "build_identity.h"
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
static volatile uint8_t result_sink;

static void read_cpu_model(char *cpu_model, size_t capacity)
{
    (void)snprintf(cpu_model, capacity, "unavailable");
#ifdef __APPLE__
    if (sysctlbyname("machdep.cpu.brand_string", cpu_model, &capacity, NULL, 0) != 0)
        (void)snprintf(cpu_model, capacity, "unavailable");
#else
    FILE *cpu_file = fopen("/proc/cpuinfo", "r");
    char information_line[256];
    if (cpu_file == NULL) return;
    while (fgets(information_line, sizeof(information_line), cpu_file) != NULL) {
        if (strncmp(information_line, "model name", 10) == 0) {
            const char *model_value = strchr(information_line, ':');
            if (model_value != NULL) {
                (void)snprintf(cpu_model, capacity, "%s", model_value + 1);
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
        timestamp.tv_nsec < 0 || timestamp.tv_nsec >= 1000000000L) return 1;
    if ((uint64_t)timestamp.tv_sec > (UINT64_MAX - (uint64_t)timestamp.tv_nsec) / UINT64_C(1000000000)) return 1;
    *timestamp_nanoseconds = (uint64_t)timestamp.tv_sec * UINT64_C(1000000000) + (uint64_t)timestamp.tv_nsec;
    return 0;
}

static int check_timer(uint64_t *resolution_nanoseconds)
{
    struct timespec clock_resolution;
    uint64_t previous_nanoseconds, current_nanoseconds;
    int observed_progress = 0;
    if (clock_getres(CLOCK_MONOTONIC, &clock_resolution) != 0 ||
        clock_resolution.tv_sec < 0 || clock_resolution.tv_nsec < 0) return 1;
    *resolution_nanoseconds = (uint64_t)clock_resolution.tv_sec * UINT64_C(1000000000) + (uint64_t)clock_resolution.tv_nsec;
    if (*resolution_nanoseconds == 0 || read_monotonic_nanoseconds(&previous_nanoseconds) != 0) return 1;
    for (unsigned check_index = 0; check_index < 10000u; ++check_index) {
        if (read_monotonic_nanoseconds(&current_nanoseconds) != 0 || current_nanoseconds < previous_nanoseconds) return 1;
        if (current_nanoseconds > previous_nanoseconds) observed_progress = 1;
        previous_nanoseconds = current_nanoseconds;
    }
    return observed_progress ? 0 : 1;
}

static uint64_t draw_order_value(uint64_t test_seed, uint64_t *draw_index, uint64_t upper_bound)
{
    uint64_t random_value;
    uint64_t rejection_threshold = (UINT64_C(0) - upper_bound) % upper_bound;
    do {
        uint8_t random_bytes[8];
        expand_test_seed(random_bytes, sizeof(random_bytes), test_seed, (*draw_index)++, 4);
        random_value = 0;
        for (unsigned byte_index = 0; byte_index < 8u; ++byte_index)
            random_value |= (uint64_t)random_bytes[byte_index] << (8u * byte_index);
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
    uint32_t path_capacity = (uint32_t)sizeof(executable_path);
    if (_NSGetExecutablePath(executable_path, &path_capacity) != 0) return 1;
#else
    ssize_t path_byte_count = readlink("/proc/self/exe", executable_path, sizeof(executable_path) - 1u);
    if (path_byte_count < 0 || (size_t)path_byte_count >= sizeof(executable_path) - 1u) return 1;
    executable_path[path_byte_count] = '\0';
#endif
    executable_file = fopen(executable_path, "rb");
    if (executable_file == NULL) return 1;
    if (fstat(fileno(executable_file), &file_status) != 0 || file_status.st_size <= 0 || file_status.st_size > 67108864) {
        (void)fclose(executable_file); return 1;
    }
    executable_byte_count = (size_t)file_status.st_size;
    executable_bytes = malloc(executable_byte_count);
    if (executable_bytes == NULL) { (void)fclose(executable_file); return 1; }
    if (fread(executable_bytes, 1, executable_byte_count, executable_file) != executable_byte_count ||
        fgetc(executable_file) != EOF || ferror(executable_file)) operation_status = 1;
    if (fclose(executable_file) != 0) operation_status = 1;
    if (operation_status == 0) mlk_sha3_256(executable_digest, executable_bytes, executable_byte_count);
    free(executable_bytes);
    return operation_status;
}

static int save_measurements(const char *csv_path, const char *metadata_path, const char *run_id,
    uint64_t test_seed, const struct measurement_sample *samples, size_t sample_count,
    uint64_t resolution_nanoseconds, const uint8_t executable_digest[32])
{
    struct utsname machine_information;
    char cpu_model[256];
    FILE *csv_file, *metadata_file;
    int operation_status = 0;
    time_t wall_clock_seconds = time(NULL);
    if (uname(&machine_information) != 0 || wall_clock_seconds == (time_t)-1) return 1;
    read_cpu_model(cpu_model, sizeof(cpu_model));
    csv_file = fopen(csv_path, "wx");
    if (csv_file == NULL) return 1;
    metadata_file = fopen(metadata_path, "wx");
    if (metadata_file == NULL) { (void)fclose(csv_file); (void)remove(csv_path); return 1; }
    if (fprintf(csv_file, "run_id,implementation,input_category,sample_index,elapsed_nanoseconds,time_unit\n") < 0) operation_status = 1;
    for (size_t sample_index = 0; sample_index < sample_count; ++sample_index) {
        if (fprintf(csv_file, "%s,%s,%s,%zu,%" PRIu64 ",ns\n", run_id, mlkem_implementation_name(),
            input_category_name(samples[sample_index].category), sample_index, samples[sample_index].elapsed_nanoseconds) < 0)
            operation_status = 1;
    }
    if (fprintf(metadata_file, "run_id=%s\nimplementation=%s\ntest_seed=%" PRIu64 "\nsample_count=%zu\n"
        "clock=CLOCK_MONOTONIC\ntime_unit=ns\nclock_resolution_ns=%" PRIu64 "\n"
        "warmup_decapsulations=100\norder=balanced_fisher_yates_shake256_tag4\n"
        "wall_clock_unix_seconds=%jd\nos=%s %s\narchitecture=%s\ncpu_model=%s\n"
        "cpu_affinity=not_pinned\nfrequency_control=not_configured\n"
        "executable_digest_algorithm=SHA3-256\nexecutable_digest=",
        run_id, mlkem_implementation_name(), test_seed, sample_count, resolution_nanoseconds,
        (intmax_t)wall_clock_seconds, machine_information.sysname, machine_information.release, machine_information.machine, cpu_model) < 0)
        operation_status = 1;
    for (size_t byte_index = 0; byte_index < 32u; ++byte_index)
        if (fprintf(metadata_file, "%02x", executable_digest[byte_index]) < 0) operation_status = 1;
    if (fputc('\n', metadata_file) == EOF) operation_status = 1;
    for (size_t line_index = 0; line_index < sizeof(build_identity_lines) / sizeof(build_identity_lines[0]); ++line_index)
        if (fputs(build_identity_lines[line_index], metadata_file) == EOF) operation_status = 1;
    if (fclose(csv_file) != 0) operation_status = 1;
    if (fclose(metadata_file) != 0) operation_status = 1;
    return operation_status;
}

int main(int argument_count, char **argument_values)
{
    uint64_t test_seed, samples_per_category, resolution_nanoseconds, order_draw_index = 0;
    uint8_t encapsulation_key[MLKEM_ENCAPSULATION_KEY_BYTES];
    uint8_t decapsulation_key[MLKEM_DECAPSULATION_KEY_BYTES];
    uint8_t shared_secret[MLKEM_SHARED_SECRET_BYTES];
    uint8_t executable_digest[32];
    struct measurement_sample *samples = NULL;
    size_t sample_count;
    int operation_status = 1;
    if (argument_count != 6 || parse_unsigned_integer(argument_values[2], &test_seed) != 0 ||
        parse_unsigned_integer(argument_values[3], &samples_per_category) != 0 ||
        samples_per_category == 0 || samples_per_category > 20000u) {
        fputs("Usage: measure RUN_ID SEED SAMPLES_PER_CATEGORY CSV_FILE META_FILE (count 1..20000)\n", stderr);
        return 2;
    }
    if (strlen(argument_values[1]) == 0 || strlen(argument_values[1]) > 64u) {
        fputs("invalid RUN_ID: length must be 1..64 characters\n", stderr);
        return 2;
    }
    for (const char *character = argument_values[1]; *character != '\0'; ++character) {
        if (!((*character >= 'a' && *character <= 'z') || (*character >= 'A' && *character <= 'Z') ||
            (*character >= '0' && *character <= '9') || *character == '_' || *character == '-')) {
            fputs("invalid RUN_ID: use only ASCII letters, digits, underscore or hyphen\n", stderr);
            return 2;
        }
    }
    if (check_timer(&resolution_nanoseconds) != 0 || hash_running_executable(executable_digest) != 0) {
        fputs("timer/executable identity check failed\n", stderr); return 1;
    }
    sample_count = (size_t)samples_per_category * INPUT_CATEGORY_COUNT;
    samples = calloc(sample_count, sizeof(*samples));
    if (samples == NULL || generate_test_key_pair(test_seed, encapsulation_key, decapsulation_key) != 0) goto cleanup;
    for (size_t sample_index = 0; sample_index < sample_count; ++sample_index) {
        samples[sample_index].category = (enum input_category)(sample_index % INPUT_CATEGORY_COUNT);
        if (generate_test_ciphertext(samples[sample_index].category, test_seed, sample_index / INPUT_CATEGORY_COUNT,
            encapsulation_key, samples[sample_index].ciphertext) != 0) goto cleanup;
    }
    for (size_t remaining_count = sample_count; remaining_count > 1u; --remaining_count) {
        size_t selected_index = (size_t)draw_order_value(test_seed, &order_draw_index, remaining_count);
        struct measurement_sample selected_sample = samples[selected_index];
        samples[selected_index] = samples[remaining_count - 1u];
        samples[remaining_count - 1u] = selected_sample;
    }
    for (unsigned warmup_index = 0; warmup_index < 100u; ++warmup_index) {
        if (mlkem_decapsulate(shared_secret, sizeof(shared_secret), samples[warmup_index % sample_count].ciphertext,
            MLKEM_CIPHERTEXT_BYTES, decapsulation_key, sizeof(decapsulation_key)) != 0) goto cleanup;
        result_sink ^= shared_secret[0];
    }
    for (size_t sample_index = 0; sample_index < sample_count; ++sample_index) {
        uint64_t start_nanoseconds, end_nanoseconds;
        int decapsulation_status;
        if (read_monotonic_nanoseconds(&start_nanoseconds) != 0) goto cleanup;
        atomic_signal_fence(memory_order_seq_cst);
        decapsulation_status = mlkem_decapsulate(shared_secret, sizeof(shared_secret), samples[sample_index].ciphertext,
            MLKEM_CIPHERTEXT_BYTES, decapsulation_key, sizeof(decapsulation_key));
        atomic_signal_fence(memory_order_seq_cst);
        if (read_monotonic_nanoseconds(&end_nanoseconds) != 0 || end_nanoseconds < start_nanoseconds) goto cleanup;
        if (decapsulation_status != 0) goto cleanup;
        samples[sample_index].elapsed_nanoseconds = end_nanoseconds - start_nanoseconds;
        /* 在计时结束后消费结果，文件输出等到整批测量结束。 */
        result_sink ^= shared_secret[sample_index % sizeof(shared_secret)];
    }
    operation_status = save_measurements(argument_values[4], argument_values[5], argument_values[1], test_seed,
        samples, sample_count, resolution_nanoseconds, executable_digest);
cleanup:
    erase_secret_bytes(decapsulation_key, sizeof(decapsulation_key));
    erase_secret_bytes(shared_secret, sizeof(shared_secret));
    free(samples);
    if (operation_status != 0) fputs("measurement failed; check resources and use new output paths\n", stderr);
    else printf("%s: saved %zu raw decapsulation times in ns; no statistical conclusion\n", mlkem_implementation_name(), sample_count);
    return operation_status;
}
