#define _POSIX_C_SOURCE 200809L
#ifdef __APPLE__
#define _DARWIN_C_SOURCE
#endif

#include "inputs.h"

#include <assert.h>
#include <inttypes.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/wait.h>
#include <unistd.h>

static int invoke(const char *program, const char *directory, const char *report_path)
{
    pid_t child_process = fork();
    assert(child_process >= 0);
    if (child_process == 0) {
        execl(program, program, "performance-replay", directory, report_path, (char *)NULL);
        _exit(127);
    }
    int wait_status;
    assert(waitpid(child_process, &wait_status, 0) == child_process);
    return WIFEXITED(wait_status) ? WEXITSTATUS(wait_status) : 128;
}

static void write_cost(const char *path,
    const char *run_name,
    const char *final_state,
    uint64_t total_duration_ns)
{
    FILE *cost_file = fopen(path, "w");
    assert(cost_file != NULL);
    assert(fprintf(cost_file,
               "cost_format=measurement_cost_v1\ninitial_state=started\nrun_id=%s\n"
               "final_state=%s\nstart_ns=100\npreparation_end_ns=200\nwarmup_end_ns=300\n"
               "collection_end_ns=%" PRIu64 "\nfinish_ns=%" PRIu64 "\nchild_total_wall_ns=%" PRIu64
               "\nwarmup_attempted_calls=100\nwarmup_completed_calls=100\n"
               "formal_attempted_calls=3000\nformal_completed_calls=3000\noutputs_consumed=3100\n",
               run_name,
               final_state,
               300u + total_duration_ns,
               1300u + total_duration_ns,
               1200u + total_duration_ns) > 0);
    assert(fclose(cost_file) == 0);
}

static void expect_incomplete(const char *program, const char *directory, const char *report_path)
{
    assert(invoke(program, directory, report_path) != 0);
    FILE *report_file = fopen(report_path, "r");
    assert(report_file != NULL);
    char report[8192];
    size_t report_bytes = fread(report, 1, sizeof(report) - 1u, report_file);
    report[report_bytes] = '\0';
    assert(fclose(report_file) == 0 && strstr(report, "report_status=complete") == NULL);
}

int main(int argument_count, char **argument_values)
{
    assert(argument_count == 2);
    char test_directory[] = "/tmp/a113-performance-fixture.XXXXXX";
    assert(mkdtemp(test_directory) != NULL);
    const char *variants[3] = {"reference", "hardened", "deployable"};
    char csv_path[512];
    char metadata_path[512];
    char cost_path[512];
    char report_path[512];
    const char zero_digest[] = "0000000000000000000000000000000000000000000000000000000000000000";
    for (size_t block_index = 1; block_index <= 6u; ++block_index) {
        for (size_t variant_index = 0; variant_index < 3u; ++variant_index) {
            char run_name[128];
            (void)snprintf(run_name,
                sizeof(run_name),
                "ordinary-%s-block%zu",
                variants[variant_index],
                block_index);
            (void)snprintf(csv_path, sizeof(csv_path), "%s/%s.csv", test_directory, run_name);
            (void)snprintf(metadata_path,
                sizeof(metadata_path),
                "%s/%s.meta",
                test_directory,
                run_name);
            (void)
                snprintf(cost_path, sizeof(cost_path), "%s/%s.csv.cost", test_directory, run_name);
            uint64_t duration_ns = 1000u + 100u * block_index;
            if (variant_index == 1u) {
                duration_ns += 100u;
            } else if (variant_index == 2u) {
                duration_ns -= 100u;
            }
            FILE *csv_file = fopen(csv_path, "wx");
            assert(csv_file != NULL);
            assert(fputs("run_id,implementation,input_category,sample_index,elapsed_nanoseconds,"
                         "time_unit\n",
                       csv_file) != EOF);
            for (size_t record_index = 0; record_index < 3000u; ++record_index) {
                assert(fprintf(csv_file,
                           "%s,%s,%s,%zu,%" PRIu64 ",ns\n",
                           run_name,
                           variants[variant_index],
                           input_category_name((enum input_category)(record_index % 3u)),
                           record_index,
                           duration_ns) > 0);
            }
            assert(fclose(csv_file) == 0);
            FILE *metadata_file = fopen(metadata_path, "wx");
            assert(metadata_file != NULL);
            assert(
                fprintf(metadata_file,
                    "run_id=%s\nimplementation=%s\nsample_count=3000\nrun_status=complete\n"
                    "sanitizers=OFF\nsource_commit=software_fixture\nordered_input_digest=%s\n"
                    "test_seed=%" PRIu64 "\nexecutable_digest=%s\norigin=synthetic_parser_fixture\n"
                    "clock=CLOCK_MONOTONIC\ntime_unit=ns\nmeasurement_format=reference_ordinary_"
                    "v1\n"
                    "formal_attempted_calls=3000\nformal_completed_calls=3000\n"
                    "warmup_attempted_calls=100\nwarmup_completed_calls=100\noutputs_consumed="
                    "3100\n",
                    run_name,
                    variants[variant_index],
                    zero_digest,
                    UINT64_C(202610072000) + block_index,
                    zero_digest) > 0);
            assert(fclose(metadata_file) == 0);
            write_cost(cost_path, run_name, "complete", duration_ns * 3000u);
        }
    }
    (void)snprintf(report_path, sizeof(report_path), "%s/result.report", test_directory);
    assert(invoke(argument_values[1], test_directory, report_path) == 0);
    FILE *report_file = fopen(report_path, "r");
    assert(report_file != NULL);
    char report[8192];
    size_t report_bytes = fread(report, 1, sizeof(report) - 1u, report_file);
    report[report_bytes] = '\0';
    assert(fclose(report_file) == 0);
    assert(strstr(report, "mean_difference_ns=100.000000000") != NULL);
    assert(strstr(report, "mean_difference_ns=-100.000000000") != NULL);
    assert(
        strstr(report, "interval_lower_ns=100.000000000 interval_upper_ns=100.000000000") != NULL);
    assert(strstr(report, "report_status=complete") != NULL);
    assert(invoke(argument_values[1], test_directory, report_path) != 0);
    assert(unlink(cost_path) == 0);
    (void)snprintf(report_path, sizeof(report_path), "%s/missing-cost.report", test_directory);
    expect_incomplete(argument_values[1], test_directory, report_path);
    write_cost(cost_path, "ordinary-deployable-block6", "partial", UINT64_C(4500000));
    (void)snprintf(report_path, sizeof(report_path), "%s/partial-cost.report", test_directory);
    expect_incomplete(argument_values[1], test_directory, report_path);
    write_cost(cost_path, "wrong-run", "complete", UINT64_C(4500000));
    (void)snprintf(report_path, sizeof(report_path), "%s/wrong-cost-run.report", test_directory);
    expect_incomplete(argument_values[1], test_directory, report_path);
    write_cost(cost_path, "ordinary-deployable-block6", "complete", 1);
    (void)snprintf(report_path, sizeof(report_path), "%s/short-cost-window.report", test_directory);
    expect_incomplete(argument_values[1], test_directory, report_path);
    write_cost(cost_path, "ordinary-deployable-block6", "complete", UINT64_C(4500000));
    assert(unlink(csv_path) == 0);
    (void)snprintf(report_path, sizeof(report_path), "%s/partial.report", test_directory);
    expect_incomplete(argument_values[1], test_directory, report_path);
    return 0;
}
