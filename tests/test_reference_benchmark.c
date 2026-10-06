#define _POSIX_C_SOURCE 200809L
#ifdef __APPLE__
#define _DARWIN_C_SOURCE
#endif
#include "timing_statistics.h"

#include <assert.h>
#include <signal.h>
#include <stdlib.h>
#include <string.h>
#include <sys/resource.h>
#include <sys/wait.h>
#include <unistd.h>

static int run_benchmark(const char *program,
    const char *sample_count,
    const char *csv_path,
    const char *metadata_path,
    int limit_file_size)
{
    pid_t child_process = fork();
    int wait_status;
    assert(child_process >= 0);
    if (child_process == 0) {
        if (limit_file_size) {
            struct rlimit file_limit = {1024, 1024};
            if (signal(SIGXFSZ, SIG_IGN) == SIG_ERR || setrlimit(RLIMIT_FSIZE, &file_limit) != 0) {
                _exit(127);
            }
        }
        execl(program,
            program,
            "fixture",
            "42",
            sample_count,
            csv_path,
            metadata_path,
            (char *)NULL);
        _exit(127);
    }
    assert(waitpid(child_process, &wait_status, 0) == child_process);
    assert(WIFEXITED(wait_status));
    return WEXITSTATUS(wait_status);
}

static void check_metadata(const char *metadata_path)
{
    FILE *metadata_file = fopen(metadata_path, "r");
    char metadata_line[4096];
    unsigned clock_step_count = 0;
    unsigned empty_window_count = 0;
    int has_complete_status = 0;
    int has_workload = 0;
    int has_call_count = 0;
    int has_input_digest = 0;
    assert(metadata_file != NULL);
    while (fgets(metadata_line, sizeof(metadata_line), metadata_file) != NULL) {
        clock_step_count += strncmp(metadata_line, "clock_read_step=", 16) == 0 ? 1u : 0u;
        empty_window_count += strncmp(metadata_line, "empty_window=", 13) == 0 ? 1u : 0u;
        has_complete_status |= strcmp(metadata_line, "run_status=complete\n") == 0;
        has_workload |= strcmp(metadata_line, "workload=valid:bit-flipped:random=1:1:1\n") == 0;
        has_call_count |= strcmp(metadata_line, "formal_completed_calls=30\n") == 0;
        has_input_digest |= strncmp(metadata_line, "ordered_input_digest=", 21) == 0;
    }
    assert(!ferror(metadata_file));
    assert(fclose(metadata_file) == 0);
    assert(clock_step_count == 10000u);
    assert(empty_window_count == 1000u);
    assert(has_complete_status && has_workload && has_call_count && has_input_digest);
}

int main(int argument_count, char **argument_values)
{
    char test_directory[] = "/tmp/cry-reference-benchmark.XXXXXX";
    char csv_path[2][256];
    char metadata_path[2][256];
    char cost_path[2][256];
    struct measurement_set sets[2] = {{0}, {0}};
    assert(argument_count == 2);
    assert(mkdtemp(test_directory) != NULL);
    for (size_t run_index = 0; run_index < 2u; ++run_index) {
        assert(snprintf(csv_path[run_index],
                   sizeof(csv_path[run_index]),
                   "%s/run%zu.csv",
                   test_directory,
                   run_index) > 0);
        assert(snprintf(metadata_path[run_index],
                   sizeof(metadata_path[run_index]),
                   "%s/run%zu.meta",
                   test_directory,
                   run_index) > 0);
        assert(snprintf(cost_path[run_index],
                   sizeof(cost_path[run_index]),
                   "%s.cost",
                   csv_path[run_index]) > 0);
        assert(run_benchmark(argument_values[1],
                   "10",
                   csv_path[run_index],
                   metadata_path[run_index],
                   0) == 0);
        assert(load_measurement_set(csv_path[run_index], &sets[run_index]) == 0);
        assert(sets[run_index].record_count == 30u);
        assert(strcmp(sets[run_index].implementation, "reference") == 0);
        size_t category_counts[3] = {0};
        for (size_t record_index = 0; record_index < sets[run_index].record_count; ++record_index) {
            unsigned category_index = sets[run_index].records[record_index].category_index;
            assert(category_index < 3u);
            ++category_counts[category_index];
        }
        assert(category_counts[0] == 10u && category_counts[1] == 10u && category_counts[2] == 10u);
        check_metadata(metadata_path[run_index]);
    }
    for (size_t record_index = 0; record_index < sets[0].record_count; ++record_index) {
        assert(sets[0].records[record_index].category_index ==
            sets[1].records[record_index].category_index);
    }
    assert(run_benchmark(argument_values[1], "10", csv_path[0], metadata_path[0], 0) == 1);
    for (size_t run_index = 0; run_index < 2u; ++run_index) {
        free(sets[run_index].records);
        assert(unlink(csv_path[run_index]) == 0);
        assert(unlink(metadata_path[run_index]) == 0);
        assert(unlink(cost_path[run_index]) == 0);
    }
    assert(run_benchmark(argument_values[1], "0", csv_path[0], metadata_path[0], 0) == 2);
    assert(access(csv_path[0], F_OK) != 0 && access(metadata_path[0], F_OK) != 0);
    assert(run_benchmark(argument_values[1], "10", csv_path[0], test_directory, 0) == 1);
    assert(access(csv_path[0], F_OK) != 0);
    assert(unlink(cost_path[0]) == 0);
    /* 模拟写满文件，失败产物保留供识别，不能进入性能汇总。 */
    assert(run_benchmark(argument_values[1], "100", csv_path[0], metadata_path[0], 1) == 1);
    assert(unlink(csv_path[0]) == 0);
    assert(unlink(metadata_path[0]) == 0);
    assert(unlink(cost_path[0]) == 0);
    assert(rmdir(test_directory) == 0);
    return 0;
}
