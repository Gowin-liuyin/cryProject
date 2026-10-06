#define _POSIX_C_SOURCE 200809L
#ifdef __APPLE__
#define _DARWIN_C_SOURCE
#endif
#include "paired_data.h"

#include <assert.h>
#include <stdlib.h>
#include <string.h>
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
    assert(argument_count == 3);
    char output[4096];
    char *clock_arguments[] = {argument_values[1], "clock", NULL};
    assert(invoke(clock_arguments, output, sizeof(output)) == 0);
    assert(strchr(output, '\n') != NULL);
    *strchr(output, '\n') = '\0';
    uint64_t first_timestamp;
    assert(parse_unsigned_integer(output, &first_timestamp) == 0 && first_timestamp > 0);
    char directory[] = "/tmp/cry-paired-prepare.XXXXXX";
    assert(mkdtemp(directory) != NULL);
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
    printf("software_prepare_fixture_directory=%s\n", directory);
    return 0;
}
