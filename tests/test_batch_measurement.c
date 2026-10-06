#define _POSIX_C_SOURCE 200809L
#ifdef __APPLE__
#define _DARWIN_C_SOURCE
#endif
#include "batch_measurement.h"
#include "inputs.h"

#include <assert.h>
#include <signal.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/resource.h>
#include <sys/wait.h>
#include <unistd.h>

static int run_program(const char *program,
    const char *batch_size,
    const char *sample_count,
    const char *csv_path,
    const char *metadata_path,
    int restrict_size)
{
    pid_t child_process = fork();
    int wait_status;
    assert(child_process >= 0);
    if (child_process == 0) {
        if (restrict_size) {
            struct rlimit file_limit = {1024, 1024};
            assert(signal(SIGXFSZ, SIG_IGN) != SIG_ERR);
            assert(setrlimit(RLIMIT_FSIZE, &file_limit) == 0);
        }
        if (batch_size == NULL) {
            execl(program,
                program,
                "fixture",
                "42",
                sample_count,
                csv_path,
                metadata_path,
                (char *)NULL);
        } else {
            execl(program,
                program,
                "fixture",
                "42",
                sample_count,
                batch_size,
                csv_path,
                metadata_path,
                (char *)NULL);
        }
        _exit(127);
    }
    assert(waitpid(child_process, &wait_status, 0) == child_process);
    assert(WIFEXITED(wait_status));
    return WEXITSTATUS(wait_status);
}

static void read_digest_and_check_counts(const char *metadata_path, char digest[65])
{
    FILE *metadata_file = fopen(metadata_path, "r");
    char line[4096];
    unsigned found_flags = 0;
    assert(metadata_file != NULL);
    while (fgets(line, sizeof(line), metadata_file) != NULL) {
        if (strncmp(line, "ordered_input_digest=", 21) == 0) {
            assert(strlen(line) == 86u);
            memcpy(digest, line + 21, 64);
            digest[64] = '\0';
            found_flags |= 1u;
        }
        if (strcmp(line, "formal_completed_calls=30\n") == 0) {
            found_flags |= 2u;
        }
        if (strcmp(line, "outputs_consumed=130\n") == 0) {
            found_flags |= 4u;
        }
        if (strcmp(line, "run_status=complete\n") == 0) {
            found_flags |= 8u;
        }
    }
    assert(!ferror(metadata_file));
    assert(fclose(metadata_file) == 0);
    assert(found_flags == 15u);
}

static void verify_batch_output(const char *csv_path, size_t batch_size)
{
    FILE *csv_file = fopen(csv_path, "r");
    char line[1024];
    size_t input_count = 0;
    size_t window_count = 0;
    size_t category_counts[3] = {0};
    assert(csv_file != NULL);
    assert(fgets(line, sizeof(line), csv_file) != NULL);
    while (fgets(line, sizeof(line), csv_file) != NULL) {
        size_t window_index;
        size_t first_input_index;
        size_t last_input_index;
        size_t call_count;
        size_t valid_count;
        size_t flipped_count;
        size_t random_count;
        unsigned long long duration_nanoseconds;
        int parsed_bytes = 0;
        assert(sscanf(line,
                   "fixture,fixture,candidate,%zu,%zu,%zu,%zu,%zu,%zu,%zu,%llu,ns,complete\n%n",
                   &window_index,
                   &first_input_index,
                   &last_input_index,
                   &call_count,
                   &valid_count,
                   &flipped_count,
                   &random_count,
                   &duration_nanoseconds,
                   &parsed_bytes) == 8);
        assert((size_t)parsed_bytes == strlen(line));
        assert(window_index == window_count && first_input_index == input_count);
        assert(last_input_index == input_count + call_count);
        assert(call_count == (30u - input_count < batch_size ? 30u - input_count : batch_size));
        assert(valid_count + flipped_count + random_count == call_count);
        assert(duration_nanoseconds > 0);
        input_count += call_count;
        category_counts[0] += valid_count;
        category_counts[1] += flipped_count;
        category_counts[2] += random_count;
        ++window_count;
    }
    assert(!ferror(csv_file));
    assert(fclose(csv_file) == 0);
    assert(input_count == 30u && window_count == (30u + batch_size - 1u) / batch_size);
    assert(category_counts[0] == 10u && category_counts[1] == 10u && category_counts[2] == 10u);
}

int main(int argument_count, char **argument_values)
{
    uint8_t encapsulation_key[MLKEM_ENCAPSULATION_KEY_BYTES];
    uint8_t decapsulation_key[MLKEM_DECAPSULATION_KEY_BYTES];
    uint8_t ciphertexts[MAXIMUM_BATCH_CALLS][MLKEM_CIPHERTEXT_BYTES];
    const uint8_t *ciphertext_pointers[MAXIMUM_BATCH_CALLS];
    uint8_t expected_secrets[MAXIMUM_BATCH_CALLS][MLKEM_SHARED_SECRET_BYTES];
    uint8_t batch_secrets[MAXIMUM_BATCH_CALLS][MLKEM_SHARED_SECRET_BYTES];
    int call_statuses[MAXIMUM_BATCH_CALLS];
    const size_t checked_counts[] = {1, 4, 16, 2};
    assert(argument_count == 3);
    assert(generate_test_key_pair(42, encapsulation_key, decapsulation_key) == 0);
    for (size_t call_index = 0; call_index < MAXIMUM_BATCH_CALLS; ++call_index) {
        assert(generate_test_ciphertext((enum input_category)(call_index % 3u),
                   42,
                   call_index,
                   encapsulation_key,
                   ciphertexts[call_index]) == 0);
        ciphertext_pointers[call_index] = ciphertexts[call_index];
        assert(mlkem_decapsulate(expected_secrets[call_index],
                   MLKEM_SHARED_SECRET_BYTES,
                   ciphertext_pointers[call_index],
                   MLKEM_CIPHERTEXT_BYTES,
                   decapsulation_key,
                   MLKEM_DECAPSULATION_KEY_BYTES) == 0);
    }
    for (size_t count_index = 0; count_index < sizeof(checked_counts) / sizeof(checked_counts[0]);
        ++count_index) {
        assert(run_batch_decapsulations(checked_counts[count_index],
                   ciphertext_pointers,
                   decapsulation_key,
                   batch_secrets,
                   call_statuses) == 0);
        for (size_t call_index = 0; call_index < checked_counts[count_index]; ++call_index) {
            assert(call_statuses[call_index] == 0);
            assert(memcmp(expected_secrets[call_index],
                       batch_secrets[call_index],
                       MLKEM_SHARED_SECRET_BYTES) == 0);
        }
    }
    assert(run_batch_decapsulations(0,
               ciphertext_pointers,
               decapsulation_key,
               batch_secrets,
               call_statuses) == MLKEM_ERROR_ARGUMENT);
    assert(run_batch_decapsulations(17,
               ciphertext_pointers,
               decapsulation_key,
               batch_secrets,
               call_statuses) == MLKEM_ERROR_ARGUMENT);
    char test_directory[] = "/tmp/cry-batch-test.XXXXXX";
    assert(mkdtemp(test_directory) != NULL);
    char csv_path[256];
    char metadata_path[256];
    char cost_path[256];
    char baseline_digest[65] = "";
    const char *batch_sizes[] = {NULL, "1", "4", "16"};
    for (size_t run_index = 0; run_index < 4u; ++run_index) {
        assert(
            snprintf(csv_path, sizeof(csv_path), "%s/run%zu.csv", test_directory, run_index) > 0);
        assert(snprintf(metadata_path,
                   sizeof(metadata_path),
                   "%s/run%zu.meta",
                   test_directory,
                   run_index) > 0);
        assert(snprintf(cost_path, sizeof(cost_path), "%s.cost", csv_path) > 0);
        assert(run_program(argument_values[run_index == 0 ? 1 : 2],
                   batch_sizes[run_index],
                   "10",
                   csv_path,
                   metadata_path,
                   0) == 0);
        char run_digest[65];
        read_digest_and_check_counts(metadata_path, run_digest);
        if (run_index == 0) {
            memcpy(baseline_digest, run_digest, sizeof(baseline_digest));
        } else {
            assert(strcmp(baseline_digest, run_digest) == 0);
            verify_batch_output(csv_path, (size_t)strtoul(batch_sizes[run_index], NULL, 10));
        }
        assert(run_program(argument_values[2], "4", "10", csv_path, metadata_path, 0) == 1);
        assert(unlink(csv_path) == 0 && unlink(metadata_path) == 0 && unlink(cost_path) == 0);
    }
    const char *bad_batch_sizes[] = {"0", "2", "17", "18446744073709551616"};
    for (size_t bad_index = 0; bad_index < 4u; ++bad_index) {
        assert(run_program(argument_values[2],
                   bad_batch_sizes[bad_index],
                   "10",
                   csv_path,
                   metadata_path,
                   0) == 2);
    }
    assert(run_program(argument_values[2], "4", "0", csv_path, metadata_path, 0) == 2);
    assert(
        run_program(argument_values[2], "4", "18446744073709551616", csv_path, metadata_path, 0) ==
        2);
    assert(run_program(argument_values[2], "16", "100", csv_path, metadata_path, 1) == 1);
    assert(unlink(csv_path) == 0 && unlink(metadata_path) == 0 && unlink(cost_path) == 0);
    assert(rmdir(test_directory) == 0);
    erase_secret_bytes(decapsulation_key, sizeof(decapsulation_key));
    return 0;
}
