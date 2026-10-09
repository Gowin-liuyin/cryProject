#define _POSIX_C_SOURCE 200809L
#ifdef __APPLE__
#define _DARWIN_C_SOURCE
#endif
#include "test_temp_directory.h"
#include "timing_statistics.h"

#include <assert.h>
#include <stdlib.h>
#include <string.h>
#include <sys/wait.h>
#include <unistd.h>

static int run_inspector(const char *program, const char *csv_path, const char *report_path)
{
    pid_t child_process = fork();
    int wait_status;
    assert(child_process >= 0);
    if (child_process == 0) {
        execl(program, program, csv_path, report_path, (char *)NULL);
        _exit(127);
    }
    assert(waitpid(child_process, &wait_status, 0) == child_process);
    assert(WIFEXITED(wait_status));
    return WEXITSTATUS(wait_status);
}

int main(int argument_count, char **argument_values)
{
    struct measurement_record quantile_records[] = {{1, 0}, {2, 0}, {3, 0}, {4, 0}};
    struct sample_series quantile_series = {quantile_records, 4};
    char test_directory[TEST_TEMP_DIRECTORY_CAPACITY_BYTES];
    char csv_path[256];
    char report_path[256];
    char report_text[8192];
    uint8_t original_digest[32];
    uint8_t final_digest[32];
    assert(argument_count == 2);
    /* 手算例子区分半向上取整下标与 ceil(p*n) 最近秩。 */
    assert(series_quantile(&quantile_series, 0.0) == 1);
    assert(series_quantile(&quantile_series, 0.5) == 3);
    assert(series_quantile(&quantile_series, 0.9) == 4);
    assert(series_quantile(&quantile_series, 1.0) == 4);
    assert(create_test_temp_directory(test_directory,
               sizeof(test_directory),
               "cry-timing-diagnostics") != NULL);
    assert(snprintf(csv_path, sizeof(csv_path), "%s/input.csv", test_directory) > 0);
    assert(snprintf(report_path, sizeof(report_path), "%s/report.txt", test_directory) > 0);
    FILE *csv_file = fopen(csv_path, "w");
    assert(csv_file != NULL);
    assert(fputs("run_id,implementation,input_category,sample_index,elapsed_nanoseconds,time_unit\n"
                 "fixture,reference,valid,0,4,ns\nfixture,reference,random,1,1,ns\n"
                 "fixture,reference,valid,2,2,ns\nfixture,reference,random,3,2,ns\n",
               csv_file) >= 0);
    assert(fclose(csv_file) == 0);
    assert(hash_csv_file(csv_path, original_digest) == 0);
    assert(run_inspector(argument_values[1], csv_path, report_path) == 0);
    FILE *report_file = fopen(report_path, "r");
    assert(report_file != NULL);
    size_t report_bytes = fread(report_text, 1, sizeof(report_text) - 1u, report_file);
    assert(!ferror(report_file));
    report_text[report_bytes] = '\0';
    assert(fclose(report_file) == 0);
    assert(strstr(report_text, "quantile_index=floor(p*(n-1)+0.5)\n") != NULL);
    assert(strstr(report_text, "series=all count=4 mean_ns=2.250000 p50_ns=2 p90_ns=4") != NULL);
    assert(strstr(report_text, "distinct_durations=3 tied_pair_fraction=0.166666667") != NULL);
    assert(strstr(report_text, "order_block=0 first_index=0 count=1 mean_ns=4.000000") != NULL);
    assert(strstr(report_text, "adjacent_equal_fraction=0.333333333\n") != NULL);
    assert(strstr(report_text, "report_status=complete\n") != NULL);
    assert(run_inspector(argument_values[1], csv_path, report_path) == 1);
    assert(hash_csv_file(csv_path, final_digest) == 0);
    assert(memcmp(original_digest, final_digest, sizeof(original_digest)) == 0);
    assert(unlink(report_path) == 0);
    csv_file = fopen(csv_path, "a");
    assert(csv_file != NULL);
    assert(fputs("fixture,reference,valid,9,2,ns\n", csv_file) >= 0);
    assert(fclose(csv_file) == 0);
    assert(run_inspector(argument_values[1], csv_path, report_path) == 1);
    assert(access(report_path, F_OK) != 0);
    assert(unlink(csv_path) == 0);
    assert(rmdir(test_directory) == 0);
    return 0;
}
