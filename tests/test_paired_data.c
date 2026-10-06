#define _POSIX_C_SOURCE 200809L
#ifdef __APPLE__
#define _DARWIN_C_SOURCE
#endif
#include "paired_data.h"
#include "paired_statistics.h"

#include <assert.h>
#include <inttypes.h>
#include <math.h>
#include <stdlib.h>
#include <string.h>
#include <sys/stat.h>
#include <sys/wait.h>
#include <unistd.h>

static const char source_commit[] = "0000000000000000000000000000000000000000";
static const char digest_text[] =
    "0000000000000000000000000000000000000000000000000000000000000000";

static void write_fixture_run(const char *directory,
    const char *block_id,
    unsigned method_index,
    uint64_t seed,
    uint64_t mean_nanoseconds,
    uint64_t start_nanoseconds,
    uint64_t call_count,
    uint64_t batch_size,
    int is_confirmation_fixture)
{
    char csv_path[4096];
    char metadata_path[4096];
    char cost_path[4096];
    char filename[192];
    const char *method = method_index == 0 ? "baseline" : "candidate";
    assert(snprintf(filename, sizeof(filename), "%s-%s.csv", block_id, method) > 0);
    assert(paired_data_path(csv_path, sizeof(csv_path), directory, filename) == 0);
    assert(snprintf(filename, sizeof(filename), "%s-%s.meta", block_id, method) > 0);
    assert(paired_data_path(metadata_path, sizeof(metadata_path), directory, filename) == 0);
    assert(snprintf(cost_path, sizeof(cost_path), "%s.cost", csv_path) > 0);
    FILE *csv_file = fopen(csv_path, "wx");
    assert(csv_file != NULL);
    if (method_index == 0) {
        assert(
            fputs(
                "run_id,implementation,input_category,sample_index,elapsed_nanoseconds,time_unit\n",
                csv_file) >= 0);
        for (uint64_t record_index = 0; record_index < call_count; ++record_index) {
            assert(fprintf(csv_file,
                       "%s,reference,%s,%" PRIu64 ",%" PRIu64 ",ns\n",
                       block_id,
                       input_category_name((enum input_category)(record_index % 3u)),
                       record_index,
                       mean_nanoseconds) > 0);
        }
    } else {
        assert(fputs("run_id,block_id,method,window_index,input_start,input_end,call_count,valid_"
                     "count,bit_flipped_count,random_count,elapsed_nanoseconds,time_unit,status\n",
                   csv_file) >= 0);
        for (uint64_t first_input_index = 0; first_input_index < call_count;
            first_input_index += batch_size) {
            uint64_t window_calls = call_count - first_input_index < batch_size
                ? call_count - first_input_index
                : batch_size;
            uint64_t category_counts[3] = {0};
            for (uint64_t input_index = first_input_index;
                input_index < first_input_index + window_calls;
                ++input_index) {
                ++category_counts[input_index % 3u];
            }
            assert(fprintf(csv_file,
                       "%s,%s,candidate,%" PRIu64 ",%" PRIu64 ",%" PRIu64 ",%" PRIu64 ",%" PRIu64
                       ",%" PRIu64 ",%" PRIu64 ",%" PRIu64 ",ns,complete\n",
                       block_id,
                       block_id,
                       first_input_index / batch_size,
                       first_input_index,
                       first_input_index + window_calls,
                       window_calls,
                       category_counts[0],
                       category_counts[1],
                       category_counts[2],
                       mean_nanoseconds * window_calls) > 0);
        }
    }
    assert(fclose(csv_file) == 0);
    FILE *metadata_file = fopen(metadata_path, "wx");
    assert(metadata_file != NULL);
    assert(
        fprintf(metadata_file,
            "synthetic_fixture=yes\nrun_id=%s\nmethod=%s\nordered_input_digest=%s\nexecutable_"
            "digest=%s\n"
            "source_commit=%s\ncompiler_flags=synthetic\ncompile_options=synthetic\narchitecture="
            "%s\n"
            "os=%s\nsanitizers=OFF\ntest_seed=%" PRIu64 "\nsample_count=%" PRIu64
            "\nbatch_size=%" PRIu64 "\nformal_attempted_calls=%" PRIu64
            "\nformal_completed_calls=%" PRIu64 "\noutputs_consumed=%" PRIu64 "\n"
            "warmup_attempted_calls=100\nwarmup_completed_calls=100\nvalid_count=%" PRIu64
            "\nbit_flipped_count=%" PRIu64 "\nrandom_count=%" PRIu64 "\n"
            "run_status=complete\npaired_metadata_version=paired_workload_v1\nparameter_set=ML-KEM-"
            "768\n"
            "input_rule=ordinary_input_stream_v1\nupstream_commit="
            "b3ba7b32773e657dd37f6f87bce82528459ad8a4\n"
            "measurement_format=%s\nclock=CLOCK_MONOTONIC\ntime_unit=ns\n",
            block_id,
            method,
            digest_text,
            digest_text,
            source_commit,
            is_confirmation_fixture ? "x86_64" : "synthetic",
            is_confirmation_fixture ? "Linux synthetic_software_fixture" : "synthetic",
            seed,
            call_count,
            method_index == 0 ? UINT64_C(1) : batch_size,
            call_count,
            call_count,
            call_count + 100u,
            call_count / 3u,
            call_count / 3u,
            call_count / 3u,
            method_index == 0 ? "reference_ordinary_v1" : "reference_batch_v1") > 0);
    assert(fclose(metadata_file) == 0);
    FILE *cost_file = fopen(cost_path, "wx");
    assert(cost_file != NULL);
    uint64_t finish_nanoseconds = start_nanoseconds + call_count * mean_nanoseconds + 10000u;
    assert(
        fprintf(cost_file,
            "cost_format=measurement_cost_v1\ninitial_state=started\nfinal_state=complete\n"
            "start_ns=%" PRIu64 "\npreparation_end_ns=%" PRIu64 "\nwarmup_end_ns=%" PRIu64
            "\ncollection_end_ns=%" PRIu64 "\nfinish_ns=%" PRIu64 "\nchild_total_wall_ns=%" PRIu64
            "\nwarmup_attempted_calls=100\nwarmup_completed_calls=100\nformal_attempted_calls="
            "%" PRIu64 "\nformal_completed_calls=%" PRIu64 "\noutputs_consumed=%" PRIu64 "\n",
            start_nanoseconds,
            start_nanoseconds + 100u,
            start_nanoseconds + 200u,
            start_nanoseconds + 200u + call_count * mean_nanoseconds,
            finish_nanoseconds,
            finish_nanoseconds - start_nanoseconds,
            call_count,
            call_count,
            call_count + 100u) > 0);
    assert(fclose(cost_file) == 0);
}

static void write_fixture(const char *directory, int is_confirmation_fixture, uint64_t batch_size)
{
    static const unsigned confirmation_order[20] =
        {1, 0, 1, 1, 0, 0, 0, 0, 0, 0, 1, 1, 0, 1, 0, 1, 1, 1, 0, 1};
    static const unsigned mean_order[20] =
        {3, 14, 1, 18, 17, 6, 13, 9, 15, 8, 10, 5, 2, 0, 19, 4, 11, 16, 12, 7};
    uint64_t call_count = is_confirmation_fixture ? 6000u : 6u;
    char manifest_path[4096];
    char context_path[4096];
    assert(paired_data_path(manifest_path, sizeof(manifest_path), directory, "cohort.csv") == 0);
    assert(paired_data_path(context_path, sizeof(context_path), directory, "cohort.meta") == 0);
    FILE *manifest = fopen(manifest_path, "wx");
    assert(manifest != NULL);
    assert(fputs(PAIRED_COHORT_HEADER, manifest) >= 0);
    for (size_t pair_index = 0; pair_index < 20u; ++pair_index) {
        char block_id[65];
        assert(snprintf(block_id, sizeof(block_id), "fixture-%02zu", pair_index) > 0);
        uint64_t selected_mean_index =
            is_confirmation_fixture ? mean_order[pair_index] : pair_index;
        uint64_t baseline_mean = 920u + 8u * selected_mean_index;
        uint64_t candidate_mean = 980u + 2u * selected_mean_index;
        uint64_t first_start =
            1000000u + (is_confirmation_fixture ? 100000000u : 100000u) * pair_index;
        uint64_t second_start_offset = is_confirmation_fixture ? 50000000u : 50000u;
        unsigned first_method = is_confirmation_fixture ? confirmation_order[pair_index]
            : pair_index < 10u                          ? 0u
                                                        : 1u;
        write_fixture_run(directory,
            block_id,
            0,
            5000u + pair_index,
            baseline_mean,
            first_start + (first_method == 0 ? 0u : second_start_offset),
            call_count,
            batch_size,
            is_confirmation_fixture);
        write_fixture_run(directory,
            block_id,
            1,
            5000u + pair_index,
            candidate_mean,
            first_start + (first_method == 1 ? 0u : second_start_offset),
            call_count,
            batch_size,
            is_confirmation_fixture);
        char names[4][192];
        char digests[6][65];
        assert(snprintf(names[0], sizeof(names[0]), "%s-baseline.csv", block_id) > 0);
        assert(snprintf(names[1], sizeof(names[1]), "%s-baseline.meta", block_id) > 0);
        assert(snprintf(names[2], sizeof(names[2]), "%s-candidate.csv", block_id) > 0);
        assert(snprintf(names[3], sizeof(names[3]), "%s-candidate.meta", block_id) > 0);
        for (size_t method_index = 0; method_index < 2u; ++method_index) {
            char path[4096];
            char cost_path[4096];
            assert(paired_data_path(path, sizeof(path), directory, names[2u * method_index]) == 0);
            assert(paired_digest_file(path, digests[3u * method_index]) == 0);
            assert(snprintf(cost_path, sizeof(cost_path), "%s.cost", path) > 0);
            assert(paired_digest_file(cost_path, digests[3u * method_index + 2u]) == 0);
            assert(paired_data_path(path, sizeof(path), directory, names[2u * method_index + 1u]) ==
                0);
            assert(paired_digest_file(path, digests[3u * method_index + 1u]) == 0);
        }
        assert(fprintf(manifest,
                   "%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%" PRIu64 ",%" PRIu64 "\n",
                   block_id,
                   first_method == 0 ? "baseline" : "candidate",
                   names[0],
                   names[1],
                   names[2],
                   names[3],
                   digests[0],
                   digests[1],
                   digests[2],
                   digests[3],
                   digests[4],
                   digests[5],
                   is_confirmation_fixture ? call_count * baseline_mean + 11000u : 100000u,
                   is_confirmation_fixture ? call_count * candidate_mean + 11000u : 100000u) > 0);
    }
    assert(fclose(manifest) == 0);
    char manifest_digest[65];
    assert(paired_digest_file(manifest_path, manifest_digest) == 0);
    FILE *context_file = fopen(context_path, "wx");
    assert(context_file != NULL);
    assert(
        fprintf(context_file,
            "cohort_format=paired_cohort_v1\nphase=%s\nexpected_pairs=20\nshared_"
            "calls_upper=0\n"
            "shared_wall_lower_ns=0\nshared_wall_upper_ns=0\nprior_baseline_development_calls=0\n"
            "prior_candidate_development_calls=0\nprior_baseline_auxiliary_calls=0\nprior_"
            "candidate_auxiliary_calls=0\n"
            "prior_baseline_wall_ns=0\nprior_candidate_wall_ns=0\nplatform_review="
            "%s\ndependency_review=%s\n"
            "cost_closure=exact\nsource_commit=%s\nbaseline_executable_digest=%s\ncandidate_"
            "executable_digest=%s\n"
            "cohort_manifest_digest=%s\nselected_batch_size=%" PRIu64 "\nprotocol_commit="
            "5db7833c362b1bfb4b68d4fb7ff3418adba22cc9\n"
            "cohort_status=complete\n",
            is_confirmation_fixture ? "confirmation" : "software_fixture",
            is_confirmation_fixture ? "accepted" : "pending",
            is_confirmation_fixture ? "accepted" : "pending",
            source_commit,
            digest_text,
            digest_text,
            manifest_digest,
            batch_size) > 0);
    assert(fclose(context_file) == 0);
}

static int run_analyzer(const char *program, const char *directory, const char *report_path)
{
    pid_t child_process = fork();
    int wait_status;
    assert(child_process >= 0);
    if (child_process == 0) {
        execl(program, program, directory, report_path, (char *)NULL);
        _exit(127);
    }
    assert(waitpid(child_process, &wait_status, 0) == child_process);
    assert(WIFEXITED(wait_status));
    return WEXITSTATUS(wait_status);
}

int main(int argument_count, char **argument_values)
{
    if (argument_count == 3 && strcmp(argument_values[1], "--write-fixture") == 0) {
        assert(mkdir(argument_values[2], 0700) == 0);
        write_fixture(argument_values[2], 0, 4);
        return 0;
    }
    if (argument_count == 4 && strcmp(argument_values[1], "--write-confirmation-fixture") == 0) {
        uint64_t batch_size;
        assert(parse_unsigned_integer(argument_values[3], &batch_size) == 0);
        assert(batch_size == 1u || batch_size == 4u || batch_size == 16u);
        assert(mkdir(argument_values[2], 0700) == 0);
        /* 仅构造资格分支的软件输入，不是目标平台确认记录。 */
        write_fixture(argument_values[2], 1, batch_size);
        return 0;
    }
    assert(argument_count == 2);
    char directory[] = "/tmp/cry-paired-data.XXXXXX";
    assert(mkdtemp(directory) != NULL);
    write_fixture(directory, 0, 4);
    char report_path[4096];
    assert(paired_data_path(report_path, sizeof(report_path), directory, "report.txt") == 0);
    assert(run_analyzer(argument_values[1], directory, report_path) == 0);
    FILE *report_file = fopen(report_path, "r");
    char report_text[32768];
    assert(report_file != NULL);
    size_t report_bytes = fread(report_text, 1, sizeof(report_text) - 1u, report_file);
    assert(!ferror(report_file) && fclose(report_file) == 0);
    report_text[report_bytes] = '\0';
    assert(strstr(report_text, "result=comparison_evidence_insufficient\n") != NULL);
    assert(strstr(report_text, "phase=software_fixture\n") != NULL);
    assert(strstr(report_text, "pair_count=20\n") != NULL);
    assert(run_analyzer(argument_values[1], directory, report_path) == 1);
    char csv_path[4096];
    char metadata_path[4096];
    assert(
        paired_data_path(csv_path, sizeof(csv_path), directory, "fixture-00-candidate.csv") == 0);
    assert(paired_data_path(metadata_path,
               sizeof(metadata_path),
               directory,
               "fixture-00-candidate.meta") == 0);
    struct paired_run run = {0};
    assert(load_paired_run(csv_path, metadata_path, &run) == 0);
    assert(run.total_nanoseconds == 5880u && run.call_count == 6u && run.window_count == 2u);
    release_paired_run(&run);
    FILE *csv_file = fopen(csv_path, "w");
    assert(csv_file != NULL);
    assert(fputs("run_id,block_id,method,window_index,input_start,input_end,call_count,valid_count,"
                 "bit_flipped_count,random_count,elapsed_nanoseconds,time_unit,status\n"
                 "fixture-00,fixture-00,candidate,0,0,4,4,2,1,1,400,ns,complete\n"
                 "fixture-00,fixture-00,candidate,1,4,6,2,0,1,1,600,ns,complete\n",
               csv_file) >= 0);
    assert(fclose(csv_file) == 0);
    assert(load_paired_run(csv_path, metadata_path, &run) == 0);
    assert(run.total_nanoseconds == 1000u && run.call_count == 6u);
    assert(fabsl((long double)run.total_nanoseconds / (long double)run.call_count -
               1000.0L / 6.0L) < 1e-15L);
    release_paired_run(&run);
    char rejected_path[4096];
    assert(paired_data_path(rejected_path, sizeof(rejected_path), directory, "rejected.txt") == 0);
    assert(run_analyzer(argument_values[1], directory, rejected_path) == 1);
    assert(access(rejected_path, F_OK) != 0);
    csv_file = fopen(csv_path, "a");
    assert(csv_file != NULL && fputs("truncated", csv_file) >= 0 && fclose(csv_file) == 0);
    assert(load_paired_run(csv_path, metadata_path, &run) == 1);
    release_paired_run(&run);
    /* 软件夹具保留路径，后续失败演练或复算可由外层另存证据。 */
    printf("software_fixture_directory=%s\n", directory);
    return 0;
}
