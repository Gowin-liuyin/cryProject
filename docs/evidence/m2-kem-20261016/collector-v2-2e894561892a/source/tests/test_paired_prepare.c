#define _POSIX_C_SOURCE 200809L
#ifdef __APPLE__
#define _DARWIN_C_SOURCE
#endif
#include "paired_data.h"
#include "test_temp_directory.h"

#include <assert.h>
#include <stdlib.h>
#include <string.h>
#include <sys/stat.h>
#include <sys/wait.h>
#include <unistd.h>

static int invoke(char *const arguments[], char *output, size_t capacity)
{
    int descriptors[2];
    assert(pipe(descriptors) == 0);
    pid_t child_process = fork();
    assert(child_process >= 0);
    if (child_process == 0) {
        assert(close(descriptors[0]) == 0);
        assert(dup2(descriptors[1], STDOUT_FILENO) >= 0);
        execv(arguments[0], arguments);
        _exit(127);
    }
    assert(close(descriptors[1]) == 0);
    ssize_t output_bytes = read(descriptors[0], output, capacity - 1u);
    assert(output_bytes >= 0);
    output[(size_t)output_bytes] = '\0';
    assert(close(descriptors[0]) == 0);
    int wait_status;
    assert(waitpid(child_process, &wait_status, 0) == child_process);
    assert(WIFEXITED(wait_status));
    return WEXITSTATUS(wait_status);
}

int main(int argument_count, char **argument_values)
{
    if (argument_count == 4 && strcmp(argument_values[1], "init") == 0) {
        const char *fixture_mode = getenv("CRY_PREPARE_FIXTURE_MODE");
        if (fixture_mode != NULL && strcmp(fixture_mode, "timeout") == 0) {
            for (;;) {
                (void)pause();
            }
        }
        return 17;
    }
    assert(argument_count == 4);
    char output[4096];
    char *clock_arguments[] = {argument_values[1], "clock", NULL};
    assert(invoke(clock_arguments, output, sizeof(output)) == 0);
    assert(strchr(output, '\n') != NULL);
    *strchr(output, '\n') = '\0';
    uint64_t first_timestamp;
    assert(parse_unsigned_integer(output, &first_timestamp) == 0 && first_timestamp > 0);
    char directory[TEST_TEMP_DIRECTORY_CAPACITY_BYTES];
    assert(create_test_temp_directory(directory, sizeof(directory), "cry-paired-prepare") != NULL);
    char plans_path[4096];
    char registry_path[4096];
    assert(paired_data_path(plans_path, sizeof(plans_path), directory, "plans") == 0);
    assert(paired_data_path(registry_path, sizeof(registry_path), directory, "registry.txt") == 0);
    char *plan_arguments[] = {argument_values[1], "development-plans", plans_path, NULL};
    assert(invoke(plan_arguments, output, sizeof(output)) == 0);
    assert(invoke(plan_arguments, output, sizeof(output)) == 1);
    unsigned baseline_first = 0;
    for (unsigned plan_index = 0; plan_index < 2u; ++plan_index) {
        char filename[64];
        char plan_path[4096];
        (void)snprintf(filename,
            sizeof(filename),
            "development-k%u.plan.csv",
            plan_index == 0 ? 4u : 16u);
        assert(paired_data_path(plan_path, sizeof(plan_path), plans_path, filename) == 0);
        FILE *plan = fopen(plan_path, "r");
        assert(plan != NULL && fgets(output, sizeof(output), plan) != NULL);
        size_t row_count = 0;
        while (fgets(output, sizeof(output), plan) != NULL) {
            char *fields[5];
            assert(split_paired_csv(output, fields, 5) == 0);
            uint64_t seed;
            assert(parse_unsigned_integer(fields[1], &seed) == 0);
            assert(seed == UINT64_C(2026120101) + 100u * plan_index + row_count);
            assert(strcmp(fields[2], "1000") == 0);
            baseline_first += strcmp(fields[4], "baseline") == 0 ? 1u : 0u;
            ++row_count;
        }
        assert(row_count == 5u && fclose(plan) == 0);
    }
    assert(baseline_first == 5u);
    FILE *registry = fopen(registry_path, "w");
    assert(registry != NULL && fputs("42\n20261029\n", registry) >= 0 && fclose(registry) == 0);
    char plan_path[4096];
    assert(
        paired_data_path(plan_path, sizeof(plan_path), plans_path, "development-k4.plan.csv") == 0);
    char *validate_arguments[] = {argument_values[1],
        "validate-plan",
        plan_path,
        registry_path,
        NULL};
    assert(invoke(validate_arguments, output, sizeof(output)) == 0);
    registry = fopen(registry_path, "a");
    assert(registry != NULL && fputs("2026120101\n", registry) >= 0 && fclose(registry) == 0);
    assert(invoke(validate_arguments, output, sizeof(output)) == 1);
    char shared_path[4096];
    char timestamp_text[32];
    assert(paired_data_path(shared_path, sizeof(shared_path), directory, "shared.cost") == 0);
    (void)snprintf(timestamp_text,
        sizeof(timestamp_text),
        "%llu",
        (unsigned long long)first_timestamp);
    char *shared_arguments[] = {argument_values[1],
        "shared",
        shared_path,
        argument_values[2],
        timestamp_text,
        "300000000000",
        "pending",
        "pending",
        NULL};
    assert(invoke(shared_arguments, output, sizeof(output)) == 0);
    assert(invoke(shared_arguments, output, sizeof(output)) == 1);
    for (unsigned finish_index = 0; finish_index < 4u; ++finish_index) {
        char finish_directory[4096];
        char filename[64];
        char receipt_path[4096];
        assert(snprintf(filename, sizeof(filename), "finish-%u", finish_index) > 0);
        assert(
            paired_data_path(finish_directory, sizeof(finish_directory), directory, filename) == 0);
        assert(mkdir(finish_directory, 0700) == 0);
        assert(paired_data_path(receipt_path,
                   sizeof(receipt_path),
                   finish_directory,
                   "budget.meta.preparation") == 0);
        FILE *receipt = fopen(receipt_path, "wx");
        assert(receipt != NULL && fputs("preparation_status=pending\n", receipt) >= 0 &&
            fclose(receipt) == 0);
        char *finish_arguments[] = {argument_values[1],
            "finish",
            finish_directory,
            argument_values[2],
            timestamp_text,
            "301000000000",
            "pending",
            "pending",
            finish_index == 0 || finish_index == 3 ? argument_values[3] : argument_values[0],
            NULL};
        if (finish_index == 3u) {
            char blocked_receipt[4096];
            assert(paired_data_path(blocked_receipt,
                       sizeof(blocked_receipt),
                       finish_directory,
                       "budget.meta.preparation.new") == 0);
            assert(mkdir(blocked_receipt, 0700) == 0);
        }
        if (finish_index == 2u) {
            assert(setenv("CRY_PREPARE_FIXTURE_MODE", "timeout", 1) == 0);
        }
        assert(invoke(finish_arguments, output, sizeof(output)) == (finish_index == 0 ? 0 : 1));
        assert(unsetenv("CRY_PREPARE_FIXTURE_MODE") == 0);
        char receipt_status[32];
        struct paired_text_field receipt_field = {"preparation_status", receipt_status, 32, 0};
        assert(read_paired_fields(receipt_path, &receipt_field, 1) == 0);
        assert(strcmp(receipt_status, finish_index == 0 ? "complete" : "pending") == 0);
        char status_path[4096];
        assert(paired_data_path(status_path,
                   sizeof(status_path),
                   finish_directory,
                   "preparation-status.txt") == 0);
        char exit_status[8];
        struct paired_text_field exit_field = {"preparation_exit_status", exit_status, 8, 0};
        assert(read_paired_fields(status_path, &exit_field, 1) == 0);
        assert(strcmp(exit_status, finish_index == 0 ? "0" : "1") == 0);
        char cost_path[4096];
        assert(
            paired_data_path(cost_path, sizeof(cost_path), finish_directory, "shared.cost") == 0);
        const char *const cost_names[] = {"shared_calls_upper",
            "shared_wall_lower_ns",
            "shared_wall_upper_ns"};
        char cost_values[3][32];
        struct paired_text_field cost_fields[3];
        uint64_t cost_numbers[3];
        for (size_t cost_index = 0; cost_index < 3u; ++cost_index) {
            cost_fields[cost_index] =
                (struct paired_text_field){cost_names[cost_index], cost_values[cost_index], 32, 0};
        }
        assert(read_paired_fields(cost_path, cost_fields, 3) == 0);
        for (size_t cost_index = 0; cost_index < 3u; ++cost_index) {
            assert(parse_unsigned_integer(cost_values[cost_index], &cost_numbers[cost_index]) == 0);
        }
        assert(cost_numbers[0] == 40000u &&
            cost_numbers[2] == cost_numbers[1] + UINT64_C(302000000000));
        assert(invoke(finish_arguments, output, sizeof(output)) == 1);
        assert(read_paired_fields(status_path, &exit_field, 1) == 0);
        assert(strcmp(exit_status, finish_index == 0 ? "0" : "1") == 0);
    }
    printf("software_prepare_fixture_directory=%s\n", directory);
    return 0;
}
