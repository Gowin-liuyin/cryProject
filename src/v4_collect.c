#define _POSIX_C_SOURCE 200809L
#ifdef __APPLE__
#define _DARWIN_C_SOURCE
#endif
#ifdef __linux__
#define _GNU_SOURCE
#endif

#include "inputs.h"
#include "mlkem.h"
#include "mlkem_native.h"
#include "src/fips202/fips202.h"
#include "v4_stats.h"

#include <inttypes.h>
#include <stdatomic.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>
#include <unistd.h>
#ifdef __linux__
#include <sched.h>
#include <sys/prctl.h>
#endif
#ifdef __APPLE__
#include <mach-o/dyld.h>
#endif

int sha256_file(const char *path, char hex_out[65]);
int sha256_bytes(const uint8_t *bytes, size_t byte_count, char hex_out[65]);

#define V4_WARMUP_CALLS 8u

struct v4_call {
    unsigned key_index;
    unsigned repeat_index;
    unsigned slot_index;
    enum input_category category;
    uint8_t ciphertext[MLKEM_CIPHERTEXT_BYTES];
    uint64_t elapsed_counts;
    char ciphertext_sha256_hex[65];
};

static volatile uint8_t result_sink;

static int read_monotonic(uint64_t *timestamp_counts)
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

static int time_decapsulation(uint8_t *shared_secret,
    const uint8_t *ciphertext,
    const uint8_t *decapsulation_key,
    uint64_t *elapsed_counts)
{
    uint64_t start_counts;
    uint64_t end_counts;
    int status;
    if (read_monotonic(&start_counts) != 0) {
        return 1;
    }
    atomic_signal_fence(memory_order_seq_cst);
    status = mlkem_decapsulate(shared_secret,
        MLKEM_SHARED_SECRET_BYTES,
        ciphertext,
        MLKEM_CIPHERTEXT_BYTES,
        decapsulation_key,
        MLKEM_DECAPSULATION_KEY_BYTES);
    atomic_signal_fence(memory_order_seq_cst);
    if (read_monotonic(&end_counts) != 0 || end_counts < start_counts) {
        return 1;
    }
    *elapsed_counts = end_counts - start_counts;
    return status == 0 ? 0 : 1;
}

static int generate_v4_key(uint64_t session_seed,
    uint64_t key_index,
    uint8_t *encapsulation_key,
    uint8_t *decapsulation_key)
{
    uint8_t key_seed[MLKEM_KEY_SEED_BYTES];
    int status;
    expand_test_seed(key_seed, sizeof(key_seed), session_seed, key_index, 4);
    status = baseline_native_keypair_derand(encapsulation_key, decapsulation_key, key_seed);
    erase_secret_bytes(key_seed, sizeof(key_seed));
    return status;
}

static int build_schedule(uint64_t session_seed,
    unsigned repeat_count,
    struct v4_call *calls,
    uint8_t *encapsulation_keys,
    uint8_t *decapsulation_keys)
{
    size_t call_index = 0u;
    for (unsigned key_index = 0; key_index < V4_KEY_COUNT; ++key_index) {
        if (generate_v4_key(session_seed,
                key_index,
                encapsulation_keys + (size_t)key_index * MLKEM_ENCAPSULATION_KEY_BYTES,
                decapsulation_keys + (size_t)key_index * MLKEM_DECAPSULATION_KEY_BYTES) != 0) {
            return 1;
        }
        for (unsigned repeat_index = 0; repeat_index < repeat_count; ++repeat_index) {
            int branch_first = ((key_index + repeat_index) % 2u) == 0u;
            enum input_category order[4];
            if (branch_first) {
                order[0] = INPUT_MESSAGE_ZERO;
                order[1] = INPUT_MESSAGE_ONES;
                order[2] = INPUT_MESSAGE_ONES;
                order[3] = INPUT_MESSAGE_ZERO;
            } else {
                order[0] = INPUT_MESSAGE_ONES;
                order[1] = INPUT_MESSAGE_ZERO;
                order[2] = INPUT_MESSAGE_ZERO;
                order[3] = INPUT_MESSAGE_ONES;
            }
            for (unsigned slot_index = 0; slot_index < 4u; ++slot_index) {
                struct v4_call *call = &calls[call_index];
                call->key_index = key_index;
                call->repeat_index = repeat_index;
                call->slot_index = slot_index;
                call->category = order[slot_index];
                call->elapsed_counts = 0u;
                if (generate_test_ciphertext(call->category,
                        session_seed,
                        0u,
                        encapsulation_keys + (size_t)key_index * MLKEM_ENCAPSULATION_KEY_BYTES,
                        call->ciphertext) != 0) {
                    return 1;
                }
                call_index += 1u;
            }
        }
    }
    return 0;
}

static void write_hex(char *destination, const uint8_t *bytes, size_t byte_count)
{
    static const char digits[] = "0123456789abcdef";
    for (size_t index = 0; index < byte_count; ++index) {
        destination[index * 2u] = digits[bytes[index] >> 4u];
        destination[index * 2u + 1u] = digits[bytes[index] & 0x0fu];
    }
    destination[byte_count * 2u] = '\0';
}

static int executable_sha256(char hex_out[65])
{
    char path[4096];
#ifdef __APPLE__
    uint32_t capacity = (uint32_t)sizeof(path);
    if (_NSGetExecutablePath(path, &capacity) != 0) {
        return 1;
    }
#else
    ssize_t length = readlink("/proc/self/exe", path, sizeof(path) - 1u);
    if (length < 0 || (size_t)length >= sizeof(path)) {
        return 1;
    }
    path[length] = '\0';
#endif
    return sha256_file(path, hex_out);
}

static int
hashes_match_schedule(const struct v4_call *calls, size_t call_count, const char *csv_path)
{
    FILE *file = fopen(csv_path, "r");
    char line[2048];
    size_t row = 0u;
    if (file == NULL || fgets(line, sizeof(line), file) == NULL) {
        if (file != NULL) {
            (void)fclose(file);
        }
        return 1;
    }
    while (fgets(line, sizeof(line), file) != NULL) {
        char *hex;
        if (row >= call_count) {
            (void)fclose(file);
            return 1;
        }
        hex = strrchr(line, ',');
        if (hex == NULL) {
            (void)fclose(file);
            return 1;
        }
        hex += 1;
        if (strncmp(hex, calls[row].ciphertext_sha256_hex, 64u) != 0) {
            (void)fclose(file);
            return 1;
        }
        row += 1u;
    }
    if (fclose(file) != 0 || row != call_count) {
        return 1;
    }
    return 0;
}

static int
print_or_check(uint64_t session_seed, unsigned repeat_count, const char *csv_path, int check)
{
    size_t call_count = (size_t)V4_KEY_COUNT * (size_t)repeat_count * 4u;
    struct v4_call *calls = calloc(call_count, sizeof(*calls));
    uint8_t *encapsulation_keys = calloc(V4_KEY_COUNT, MLKEM_ENCAPSULATION_KEY_BYTES);
    uint8_t *decapsulation_keys = calloc(V4_KEY_COUNT, MLKEM_DECAPSULATION_KEY_BYTES);
    int status = 1;
    if (calls == NULL || encapsulation_keys == NULL || decapsulation_keys == NULL ||
        build_schedule(session_seed, repeat_count, calls, encapsulation_keys, decapsulation_keys) !=
            0) {
        goto done;
    }
    for (size_t index = 0; index < call_count; ++index) {
        uint8_t digest[32];
        mlk_sha3_256(digest, calls[index].ciphertext, MLKEM_CIPHERTEXT_BYTES);
        write_hex(calls[index].ciphertext_sha256_hex, digest, sizeof(digest));
    }
    if (check) {
        status = hashes_match_schedule(calls, call_count, csv_path);
    } else {
        FILE *file = fopen(csv_path, "w");
        status = file == NULL;
        for (size_t index = 0; status == 0 && index < call_count; ++index) {
            if (fprintf(file, "%s\n", calls[index].ciphertext_sha256_hex) < 0) {
                status = 1;
            }
        }
        if (file != NULL && fclose(file) != 0) {
            status = 1;
        }
    }
done:
    erase_secret_bytes(decapsulation_keys, V4_KEY_COUNT * MLKEM_DECAPSULATION_KEY_BYTES);
    free(calls);
    free(encapsulation_keys);
    free(decapsulation_keys);
    return status;
}

static int identifier_is_safe(const char *text)
{
    size_t length = text == NULL ? 0u : strlen(text);
    if (length == 0u || length > 64u) {
        return 0;
    }
    for (size_t index = 0; index < length; ++index) {
        char character = text[index];
        if (character == ',' || character == '\n' || character == '/' || character == ' ') {
            return 0;
        }
    }
    return 1;
}

int main(int argc, char **argv)
{
    uint64_t session_seed = 0u;
    uint64_t repeat_value = 0u;
    unsigned repeat_count;
    size_t call_count;
    struct v4_call *calls = NULL;
    uint8_t *encapsulation_keys = NULL;
    uint8_t *decapsulation_keys = NULL;
    uint64_t empty_windows[V4_EMPTY_WINDOW_COUNT];
    uint8_t shared_secret[MLKEM_SHARED_SECRET_BYTES];
    char executable_hex[65];
    char input_hex[65];
    uint8_t *schedule_bytes = NULL;
    const char *affinity = "not_set";
    int status = 1;
    int unique_ok = 1;
    if (argc == 5 &&
        (strcmp(argv[1], "--print-schedule") == 0 || strcmp(argv[1], "--check-schedule") == 0)) {
        if (parse_unsigned_integer(argv[2], &session_seed) != 0 ||
            parse_unsigned_integer(argv[3], &repeat_value) != 0 || repeat_value < 1u ||
            repeat_value > 8u) {
            return 1;
        }
        /* 重复次数已限制在 1..8，转成 unsigned 不改变数值。 */
        return print_or_check(session_seed,
                   (unsigned)repeat_value,
                   argv[4],
                   strcmp(argv[1], "--check-schedule") == 0) == 0
            ? 0
            : 3;
    }
    if (argc != 8 || !identifier_is_safe(argv[1]) || !identifier_is_safe(argv[2]) ||
        parse_unsigned_integer(argv[3], &session_seed) != 0 ||
        parse_unsigned_integer(argv[4], &repeat_value) != 0 || repeat_value < 1u ||
        repeat_value > 8u) {
        fputs("usage: v4_collect RUN_ID SESSION_ID SEED REPEATS CSV META EMPTY\n", stderr);
        return 1;
    }
    repeat_count = (unsigned)repeat_value;
    call_count = (size_t)V4_KEY_COUNT * (size_t)repeat_count * 4u;
#ifdef __linux__
    {
        cpu_set_t cpu_set;
        CPU_ZERO(&cpu_set);
        CPU_SET(2, &cpu_set);
        if (sched_setaffinity(0, sizeof(cpu_set), &cpu_set) == 0) {
            affinity = "cpu2";
        }
        if (prctl(PR_SET_DUMPABLE, 0L) != 0) {
            affinity = "cpu2_dumpable_unchanged";
        }
    }
#endif
    calls = calloc(call_count, sizeof(*calls));
    encapsulation_keys = calloc(V4_KEY_COUNT, MLKEM_ENCAPSULATION_KEY_BYTES);
    decapsulation_keys = calloc(V4_KEY_COUNT, MLKEM_DECAPSULATION_KEY_BYTES);
    if (calls == NULL || encapsulation_keys == NULL || decapsulation_keys == NULL) {
        goto done;
    }
    for (size_t index = 0; index < V4_EMPTY_WINDOW_COUNT; ++index) {
        uint64_t start_counts;
        uint64_t end_counts;
        if (read_monotonic(&start_counts) != 0 || read_monotonic(&end_counts) != 0 ||
            end_counts < start_counts) {
            goto done;
        }
        empty_windows[index] = end_counts - start_counts;
    }
    if (build_schedule(session_seed, repeat_count, calls, encapsulation_keys, decapsulation_keys) !=
            0 ||
        executable_sha256(executable_hex) != 0) {
        goto done;
    }
    for (unsigned warmup_index = 0; warmup_index < V4_WARMUP_CALLS; ++warmup_index) {
        if (time_decapsulation(shared_secret,
                calls[warmup_index].ciphertext,
                decapsulation_keys +
                    (size_t)calls[warmup_index].key_index * MLKEM_DECAPSULATION_KEY_BYTES,
                &calls[warmup_index].elapsed_counts) != 0) {
            goto done;
        }
        result_sink ^= shared_secret[warmup_index % MLKEM_SHARED_SECRET_BYTES];
        calls[warmup_index].elapsed_counts = 0u;
    }
    for (size_t index = 0; index < call_count; ++index) {
        if (time_decapsulation(shared_secret,
                calls[index].ciphertext,
                decapsulation_keys + (size_t)calls[index].key_index * MLKEM_DECAPSULATION_KEY_BYTES,
                &calls[index].elapsed_counts) != 0) {
            goto done;
        }
        result_sink ^= shared_secret[index % MLKEM_SHARED_SECRET_BYTES];
    }
    for (size_t index = 0; index < call_count; ++index) {
        uint8_t digest[32];
        mlk_sha3_256(digest, calls[index].ciphertext, MLKEM_CIPHERTEXT_BYTES);
        write_hex(calls[index].ciphertext_sha256_hex, digest, sizeof(digest));
    }
    for (unsigned key_index = 0; key_index < V4_KEY_COUNT; ++key_index) {
        unsigned zero_seen = 0u;
        unsigned ones_seen = 0u;
        for (size_t index = 0; index < call_count; ++index) {
            if (calls[index].key_index != key_index) {
                continue;
            }
            if (calls[index].category == INPUT_MESSAGE_ZERO) {
                zero_seen = calls[index].ciphertext_sha256_hex[0] == '\0' ? zero_seen : 1u;
            }
            if (calls[index].category == INPUT_MESSAGE_ONES) {
                ones_seen = 1u;
            }
            for (size_t earlier = 0; earlier < index; ++earlier) {
                if (calls[earlier].key_index != key_index &&
                    calls[earlier].category == calls[index].category &&
                    strcmp(calls[earlier].ciphertext_sha256_hex,
                        calls[index].ciphertext_sha256_hex) == 0) {
                    unique_ok = 0;
                }
            }
        }
        if (zero_seen == 0u || ones_seen == 0u) {
            unique_ok = 0;
        }
    }
    schedule_bytes = malloc(call_count * 64u);
    if (schedule_bytes == NULL) {
        goto done;
    }
    for (size_t index = 0; index < call_count; ++index) {
        memcpy(schedule_bytes + index * 64u, calls[index].ciphertext_sha256_hex, 64u);
    }
    if (sha256_bytes(schedule_bytes, call_count * 64u, input_hex) != 0) {
        goto done;
    }
    {
        FILE *csv_file = fopen(argv[5], "wx");
        FILE *meta_file = fopen(argv[6], "wx");
        FILE *empty_file = fopen(argv[7], "wx");
        uint64_t empty_values[V4_EMPTY_WINDOW_COUNT];
        memcpy(empty_values, empty_windows, sizeof(empty_windows));
        if (csv_file == NULL || meta_file == NULL || empty_file == NULL) {
            if (csv_file != NULL) {
                (void)fclose(csv_file);
            }
            if (meta_file != NULL) {
                (void)fclose(meta_file);
            }
            if (empty_file != NULL) {
                (void)fclose(empty_file);
            }
            goto done;
        }
        status = 0;
        if (fputs("schema,run_id,session_id,key_index,repeat_index,slot_index,category,"
                  "elapsed_clock_counts,clock_path,ciphertext_sha256_hex\n",
                csv_file) < 0) {
            status = 1;
        }
        for (size_t index = 0; status == 0 && index < call_count; ++index) {
            if (fprintf(csv_file,
                    "v4_group_session_v1,%s,%s,%u,%u,%u,%s,%" PRIu64 ",CLOCK_MONOTONIC,%s\n",
                    argv[1],
                    argv[2],
                    calls[index].key_index,
                    calls[index].repeat_index,
                    calls[index].slot_index,
                    input_category_name(calls[index].category),
                    calls[index].elapsed_counts,
                    calls[index].ciphertext_sha256_hex) < 0) {
                status = 1;
            }
        }
        if (fputs("window_index,elapsed_clock_counts,clock_path\n", empty_file) < 0) {
            status = 1;
        }
        for (size_t index = 0; status == 0 && index < V4_EMPTY_WINDOW_COUNT; ++index) {
            if (fprintf(empty_file,
                    "%zu,%" PRIu64 ",CLOCK_MONOTONIC\n",
                    index,
                    empty_windows[index]) < 0) {
                status = 1;
            }
        }
        if (fprintf(meta_file,
                "schema=v4_group_session_v1\nprotocol_id=%s\nrun_id=%s\nsession_id=%s\n"
                "seed=%" PRIu64 "\nrepeat_count=%u\nkey_count=%u\n"
                "abba=even_sum_ABBA_odd_sum_BAAB\n"
                "unique_ciphertext_check=%s\nexecutable_sha256=%s\n"
                "input_sha256=%s\n"
                "empty_window_count=%u\nempty_window_median_counts=%.17g\n"
                "affinity=%s\nclock_path=CLOCK_MONOTONIC\nwarmup_calls=%u\nstatus=%s\n",
                V4_PROTOCOL_ID,
                argv[1],
                argv[2],
                session_seed,
                repeat_count,
                V4_KEY_COUNT,
                unique_ok ? "passed" : "failed",
                executable_hex,
                input_hex,
                V4_EMPTY_WINDOW_COUNT,
                v4_even_median(empty_values, V4_EMPTY_WINDOW_COUNT),
                affinity,
                V4_WARMUP_CALLS,
                unique_ok ? "ok" : "stopped_ciphertext_collision") < 0) {
            status = 1;
        }
        if (fclose(csv_file) != 0 || fclose(meta_file) != 0 || fclose(empty_file) != 0) {
            status = 1;
        } else {
            status = unique_ok ? 0 : 3;
        }
    }
done:
    free(schedule_bytes);
    erase_secret_bytes(shared_secret, sizeof(shared_secret));
    if (decapsulation_keys != NULL) {
        erase_secret_bytes(decapsulation_keys, V4_KEY_COUNT * MLKEM_DECAPSULATION_KEY_BYTES);
    }
    free(calls);
    free(encapsulation_keys);
    free(decapsulation_keys);
    return status;
}
