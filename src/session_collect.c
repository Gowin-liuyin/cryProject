#define _POSIX_C_SOURCE 200809L
#ifdef __APPLE__
#define _DARWIN_C_SOURCE
#endif

#include "inputs.h"
#include "mlkem.h"
#include "src/fips202/fips202.h"

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
#endif

#define SESSION_EMPTY_WINDOW_COUNT 256u
#define SESSION_WARMUP_CALLS 8u
#define SESSION_ID_CAPACITY 64u

struct session_sample {
    uint8_t ciphertext[MLKEM_CIPHERTEXT_BYTES];
    enum input_category category;
    uint64_t class_ordinal;
    uint64_t elapsed_clock_counts;
    char ciphertext_sha256_hex[65];
};

static volatile uint8_t result_sink;

static int identifier_is_safe(const char *identifier)
{
    size_t length = identifier == NULL ? 0u : strlen(identifier);
    if (length == 0u || length >= SESSION_ID_CAPACITY) {
        return 0;
    }
    for (size_t character_index = 0; character_index < length; ++character_index) {
        char character = identifier[character_index];
        if (character == ',' || character == '\n' || character == '\r' || character == ' ') {
            return 0;
        }
    }
    return 1;
}

static int read_monotonic_counts(uint64_t *timestamp_counts)
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
    *timestamp_counts =
        (uint64_t)timestamp.tv_sec * UINT64_C(1000000000) + (uint64_t)timestamp.tv_nsec;
    return 0;
}

/* 正式计时窗口只包含这一次解封装。生成、消费、分类和写文件都在函数外。 */
static int time_one_decapsulation(uint8_t *shared_secret,
    const uint8_t *ciphertext,
    const uint8_t *decapsulation_key,
    uint64_t *elapsed_clock_counts)
{
    uint64_t start_counts;
    uint64_t end_counts;
    int decapsulation_status;
    if (read_monotonic_counts(&start_counts) != 0) {
        return 1;
    }
    atomic_signal_fence(memory_order_seq_cst);
    decapsulation_status = mlkem_decapsulate(shared_secret,
        MLKEM_SHARED_SECRET_BYTES,
        ciphertext,
        MLKEM_CIPHERTEXT_BYTES,
        decapsulation_key,
        MLKEM_DECAPSULATION_KEY_BYTES);
    atomic_signal_fence(memory_order_seq_cst);
    if (read_monotonic_counts(&end_counts) != 0 || end_counts < start_counts) {
        return 1;
    }
    *elapsed_clock_counts = end_counts - start_counts;
    return decapsulation_status == 0 ? 0 : 1;
}

static int time_empty_window(uint64_t *elapsed_clock_counts)
{
    uint64_t start_counts;
    uint64_t end_counts;
    if (read_monotonic_counts(&start_counts) != 0) {
        return 1;
    }
    atomic_signal_fence(memory_order_seq_cst);
    atomic_signal_fence(memory_order_seq_cst);
    if (read_monotonic_counts(&end_counts) != 0 || end_counts < start_counts) {
        return 1;
    }
    *elapsed_clock_counts = end_counts - start_counts;
    return 0;
}

static uint64_t draw_order_value(uint64_t test_seed, uint64_t *draw_index, uint64_t upper_bound)
{
    uint64_t random_value;
    uint64_t rejection_threshold = (UINT64_C(0) - upper_bound) % upper_bound;
    do {
        uint8_t random_bytes[8];
        expand_test_seed(random_bytes, sizeof(random_bytes), test_seed, (*draw_index)++, 7);
        random_value = 0u;
        for (unsigned byte_index = 0; byte_index < 8u; ++byte_index) {
            random_value |= (uint64_t)random_bytes[byte_index] << (8u * byte_index);
        }
    } while (random_value < rejection_threshold);
    return random_value % upper_bound;
}

static void write_hex(char *destination, const uint8_t *bytes, size_t byte_count)
{
    static const char hex_digits[] = "0123456789abcdef";
    for (size_t byte_index = 0; byte_index < byte_count; ++byte_index) {
        destination[byte_index * 2u] = hex_digits[bytes[byte_index] >> 4u];
        destination[byte_index * 2u + 1u] = hex_digits[bytes[byte_index] & 0x0fu];
    }
    destination[byte_count * 2u] = '\0';
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

static int write_records(const char *csv_path,
    const char *metadata_path,
    const char *empty_path,
    const char *run_id,
    const char *session_id,
    const char *key_id,
    uint64_t test_seed,
    uint64_t block_length,
    const struct session_sample *samples,
    size_t sample_count,
    const uint64_t *empty_windows,
    uint64_t resolution_counts,
    const uint8_t executable_digest[32])
{
    FILE *csv_file;
    FILE *metadata_file;
    FILE *empty_file;
    struct utsname machine_information;
    char executable_hex[65];
    uint64_t empty_max_counts = 0u;
    if (uname(&machine_information) != 0) {
        return 1;
    }
    csv_file = fopen(csv_path, "wx");
    metadata_file = fopen(metadata_path, "wx");
    empty_file = fopen(empty_path, "wx");
    if (csv_file == NULL || metadata_file == NULL || empty_file == NULL) {
        if (csv_file != NULL) {
            (void)fclose(csv_file);
        }
        if (metadata_file != NULL) {
            (void)fclose(metadata_file);
        }
        if (empty_file != NULL) {
            (void)fclose(empty_file);
        }
        return 1;
    }
    if (fprintf(csv_file,
            "schema,run_id,session_id,block_id,key_id,sample_index,predecessor_category,"
            "category,generator_label,elapsed_clock_counts,clock_path,ciphertext_sha256_hex\n") <
        0) {
        goto write_failed;
    }
    for (size_t sample_index = 0; sample_index < sample_count; ++sample_index) {
        const struct session_sample *sample = &samples[sample_index];
        const char *predecessor =
            sample_index == 0u ? "none" : input_category_name(samples[sample_index - 1u].category);
        if (fprintf(csv_file,
                "session_decapsulation_v1,%s,%s,%" PRIu64 ",%s,%zu,%s,%s,"
                "generate_test_ciphertext:%s,%" PRIu64 ",CLOCK_MONOTONIC,%s\n",
                run_id,
                session_id,
                sample->class_ordinal / block_length,
                key_id,
                sample_index,
                predecessor,
                input_category_name(sample->category),
                input_category_name(sample->category),
                sample->elapsed_clock_counts,
                sample->ciphertext_sha256_hex) < 0) {
            goto write_failed;
        }
    }
    if (fprintf(empty_file, "window_index,elapsed_clock_counts,clock_path\n") < 0) {
        goto write_failed;
    }
    for (size_t window_index = 0; window_index < SESSION_EMPTY_WINDOW_COUNT; ++window_index) {
        if (empty_windows[window_index] > empty_max_counts) {
            empty_max_counts = empty_windows[window_index];
        }
        if (fprintf(empty_file,
                "%zu,%" PRIu64 ",CLOCK_MONOTONIC\n",
                window_index,
                empty_windows[window_index]) < 0) {
            goto write_failed;
        }
    }
    write_hex(executable_hex, executable_digest, 32u);
    if (fprintf(metadata_file,
            "schema=session_decapsulation_v1\n"
            "run_id=%s\n"
            "session_id=%s\n"
            "key_id=%s\n"
            "seed=%" PRIu64 "\n"
            "clock_path=CLOCK_MONOTONIC\n"
            "clock_unit=nanosecond_tick_of_CLOCK_MONOTONIC\n"
            "physical_nanosecond_accuracy=not_claimed\n"
            "resolution_counts=%" PRIu64 "\n"
            "empty_window_count=%u\n"
            "empty_window_max_counts=%" PRIu64 "\n"
            "timed_window=mlkem_decapsulate_only\n"
            "input_generation=outside_window\n"
            "csv_and_log=outside_window\n"
            "warmup_calls=%u\n"
            "block_length=%" PRIu64 "\n"
            "machine=%s %s %s\n"
            "executable_sha3_256=%s\n",
            run_id,
            session_id,
            key_id,
            test_seed,
            resolution_counts,
            SESSION_EMPTY_WINDOW_COUNT,
            empty_max_counts,
            SESSION_WARMUP_CALLS,
            block_length,
            machine_information.sysname,
            machine_information.release,
            machine_information.machine,
            executable_hex) < 0) {
        goto write_failed;
    }
    for (unsigned category_index = 0; category_index < INPUT_CATEGORY_COUNT; ++category_index) {
        size_t category_count = 0u;
        size_t unique_count = 0u;
        for (size_t sample_index = 0; sample_index < sample_count; ++sample_index) {
            if ((unsigned)samples[sample_index].category != category_index) {
                continue;
            }
            int seen = 0;
            category_count += 1u;
            for (size_t earlier_index = 0; earlier_index < sample_index; ++earlier_index) {
                if ((unsigned)samples[earlier_index].category == category_index &&
                    strcmp(samples[earlier_index].ciphertext_sha256_hex,
                        samples[sample_index].ciphertext_sha256_hex) == 0) {
                    seen = 1;
                    break;
                }
            }
            if (!seen) {
                unique_count += 1u;
            }
        }
        if (fprintf(metadata_file,
                "%s_count=%zu\n%s_unique_ciphertexts=%zu\n"
                "%s_repeat_numerator=%zu\n%s_repeat_denominator=%zu\n",
                input_category_name((enum input_category)category_index),
                category_count,
                input_category_name((enum input_category)category_index),
                unique_count,
                input_category_name((enum input_category)category_index),
                category_count - unique_count,
                input_category_name((enum input_category)category_index),
                category_count) < 0) {
            goto write_failed;
        }
    }
    if (fclose(csv_file) != 0 || fclose(metadata_file) != 0 || fclose(empty_file) != 0) {
        return 1;
    }
    return 0;
write_failed:
    (void)fclose(csv_file);
    (void)fclose(metadata_file);
    (void)fclose(empty_file);
    return 1;
}

int main(int argc, char **argv)
{
    uint64_t test_seed;
    uint64_t samples_per_category;
    uint64_t block_length;
    size_t sample_count;
    struct session_sample *samples = NULL;
    uint64_t empty_windows[SESSION_EMPTY_WINDOW_COUNT];
    uint64_t resolution_counts = 0u;
    struct timespec clock_resolution;
    uint8_t encapsulation_key[MLKEM_ENCAPSULATION_KEY_BYTES];
    uint8_t decapsulation_key[MLKEM_DECAPSULATION_KEY_BYTES];
    uint8_t shared_secret[MLKEM_SHARED_SECRET_BYTES];
    uint8_t executable_digest[32];
    uint64_t order_draw_index = 0u;
    int operation_status = 1;
    if (argc != 10 || !identifier_is_safe(argv[1]) || !identifier_is_safe(argv[2]) ||
        !identifier_is_safe(argv[3]) || parse_unsigned_integer(argv[4], &test_seed) != 0 ||
        parse_unsigned_integer(argv[5], &samples_per_category) != 0 ||
        parse_unsigned_integer(argv[6], &block_length) != 0 || samples_per_category == 0u ||
        samples_per_category > 100000u || block_length == 0u) {
        fputs("usage: session_collect RUN_ID SESSION_ID KEY_ID SEED "
              "SAMPLES_PER_CATEGORY BLOCK_LENGTH CSV META EMPTY\n",
            stderr);
        return 1;
    }
    if (clock_getres(CLOCK_MONOTONIC, &clock_resolution) != 0 || clock_resolution.tv_sec < 0 ||
        clock_resolution.tv_nsec < 0) {
        return 1;
    }
    resolution_counts = (uint64_t)clock_resolution.tv_sec * UINT64_C(1000000000) +
        (uint64_t)clock_resolution.tv_nsec;
    for (size_t window_index = 0; window_index < SESSION_EMPTY_WINDOW_COUNT; ++window_index) {
        if (time_empty_window(&empty_windows[window_index]) != 0) {
            return 1;
        }
    }
    if (samples_per_category > SIZE_MAX / INPUT_CATEGORY_COUNT) {
        return 1;
    }
    sample_count = (size_t)samples_per_category * INPUT_CATEGORY_COUNT;
    if (sample_count < SESSION_WARMUP_CALLS) {
        fputs("session collection needs at least eight prepared inputs\n", stderr);
        return 1;
    }
    samples = calloc(sample_count, sizeof(*samples));
    if (samples == NULL ||
        generate_test_key_pair(test_seed, encapsulation_key, decapsulation_key) != 0 ||
        hash_running_executable(executable_digest) != 0) {
        goto cleanup;
    }
    for (size_t sample_index = 0; sample_index < sample_count; ++sample_index) {
        samples[sample_index].category = (enum input_category)(sample_index % INPUT_CATEGORY_COUNT);
        samples[sample_index].class_ordinal = sample_index / INPUT_CATEGORY_COUNT;
        if (generate_test_ciphertext(samples[sample_index].category,
                test_seed,
                samples[sample_index].class_ordinal,
                encapsulation_key,
                samples[sample_index].ciphertext) != 0) {
            goto cleanup;
        }
    }
    for (size_t remaining_count = sample_count; remaining_count > 1u; --remaining_count) {
        size_t selected_index =
            (size_t)draw_order_value(test_seed, &order_draw_index, remaining_count);
        struct session_sample selected_sample = samples[selected_index];
        samples[selected_index] = samples[remaining_count - 1u];
        samples[remaining_count - 1u] = selected_sample;
    }
    for (unsigned warmup_index = 0; warmup_index < SESSION_WARMUP_CALLS; ++warmup_index) {
        if (mlkem_decapsulate(shared_secret,
                sizeof(shared_secret),
                samples[warmup_index].ciphertext,
                MLKEM_CIPHERTEXT_BYTES,
                decapsulation_key,
                sizeof(decapsulation_key)) != 0) {
            goto cleanup;
        }
        result_sink ^= shared_secret[warmup_index % MLKEM_SHARED_SECRET_BYTES];
    }
    for (size_t sample_index = 0; sample_index < sample_count; ++sample_index) {
        if (time_one_decapsulation(shared_secret,
                samples[sample_index].ciphertext,
                decapsulation_key,
                &samples[sample_index].elapsed_clock_counts) != 0) {
            goto cleanup;
        }
        result_sink ^= shared_secret[sample_index % MLKEM_SHARED_SECRET_BYTES];
    }
    for (size_t sample_index = 0; sample_index < sample_count; ++sample_index) {
        uint8_t digest[32];
        mlk_sha3_256(digest, samples[sample_index].ciphertext, MLKEM_CIPHERTEXT_BYTES);
        write_hex(samples[sample_index].ciphertext_sha256_hex, digest, sizeof(digest));
    }
    operation_status = write_records(argv[7],
        argv[8],
        argv[9],
        argv[1],
        argv[2],
        argv[3],
        test_seed,
        block_length,
        samples,
        sample_count,
        empty_windows,
        resolution_counts,
        executable_digest);
cleanup:
    erase_secret_bytes(decapsulation_key, sizeof(decapsulation_key));
    erase_secret_bytes(shared_secret, sizeof(shared_secret));
    erase_secret_bytes(encapsulation_key, sizeof(encapsulation_key));
    free(samples);
    if (operation_status != 0) {
        fputs("session collection failed\n", stderr);
    }
    return operation_status;
}
