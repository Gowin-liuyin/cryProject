#define _POSIX_C_SOURCE 200809L

#include "paired_data.h"

#include <errno.h>
#include <fcntl.h>
#include <inttypes.h>
#include <signal.h>
#include <stdlib.h>
#include <string.h>
#include <sys/stat.h>
#include <sys/wait.h>
#include <time.h>
#include <unistd.h>

static volatile sig_atomic_t deadline_reached;

static void handle_deadline(int signal_number)
{
    (void)signal_number;
    deadline_reached = 1;
}

static int read_clock(uint64_t *nanoseconds)
{
    struct timespec reading;
    if (clock_gettime(CLOCK_MONOTONIC, &reading) != 0) {
        return 1;
    }
    *nanoseconds = (uint64_t)reading.tv_sec * UINT64_C(1000000000) + (uint64_t)reading.tv_nsec;
    return 0;
}

static int run_process(char *const arguments[], const char *log_path, uint64_t *wall_ns)
{
    uint64_t start_ns;
    uint64_t finish_ns;
    int log_descriptor = open(log_path, O_WRONLY | O_CREAT | O_EXCL, 0600);
    if (log_descriptor < 0 || read_clock(&start_ns) != 0) {
        if (log_descriptor >= 0) {
            (void)close(log_descriptor);
        }
        return 125;
    }
    pid_t child_process = fork();
    if (child_process == 0) {
        if (dup2(log_descriptor, STDOUT_FILENO) < 0 || dup2(log_descriptor, STDERR_FILENO) < 0) {
            _exit(125);
        }
        (void)close(log_descriptor);
        execv(arguments[0], arguments);
        _exit(127);
    }
    (void)close(log_descriptor);
    if (child_process < 0) {
        return 125;
    }
    int wait_status = 0;
    for (;;) {
        if (waitpid(child_process, &wait_status, 0) == child_process) {
            break;
        }
        if (deadline_reached || errno != EINTR) {
            (void)kill(child_process, SIGKILL);
            while (waitpid(child_process, &wait_status, 0) < 0 && errno == EINTR) {
            }
            return deadline_reached ? 124 : 125;
        }
    }
    if (read_clock(&finish_ns) != 0 || finish_ns <= start_ns) {
        return 125;
    }
    *wall_ns = finish_ns - start_ns;
    return WIFEXITED(wait_status) ? WEXITSTATUS(wait_status) : 128;
}

static int read_result(const char *path, uint64_t counts[2])
{
    char values[3][128];
    struct paired_text_field fields[3] = {{"assignment_count", values[0], sizeof(values[0]), 0},
        {"tail_count", values[1], sizeof(values[1]), 0},
        {"report_status", values[2], sizeof(values[2]), 0}};
    if (read_paired_fields(path, fields, 3) != 0 || strcmp(values[2], "complete") != 0 ||
        parse_unsigned_integer(values[0], &counts[0]) != 0 ||
        parse_unsigned_integer(values[1], &counts[1]) != 0) {
        return 1;
    }
    return counts[0] != UINT64_C(1048576) || counts[1] > counts[0];
}

static int compare_ratios(const void *first_value, const void *second_value)
{
    long double first_ratio = *(const long double *)first_value;
    long double second_ratio = *(const long double *)second_value;
    return first_ratio < second_ratio ? -1 : first_ratio > second_ratio ? 1 : 0;
}

int main(int argument_count, char **argument_values)
{
    if (argument_count != 6) {
        fputs("Usage: compare_replay C_ANALYZER PYTHON SCIPY_SCRIPT EIGHT_TASK_DIRECTORY "
              "NEW_OUTPUT\n",
            stderr);
        return 2;
    }
    struct sigaction action = {0};
    action.sa_handler = handle_deadline;
    if (sigemptyset(&action.sa_mask) != 0 || sigaction(SIGALRM, &action, NULL) != 0 ||
        mkdir(argument_values[5], 0700) != 0) {
        return 1;
    }
    (void)alarm(300);
    char ledger_path[4096];
    char summary_path[4096];
    if (paired_data_path(ledger_path, sizeof(ledger_path), argument_values[5], "attempts.tsv") !=
            0 ||
        paired_data_path(summary_path,
            sizeof(summary_path),
            argument_values[5],
            "comparison.report") != 0) {
        return 1;
    }
    FILE *ledger = fopen(ledger_path, "wx");
    if (ledger == NULL) {
        return 1;
    }
    int operation_status = 1;
    int all_tasks_faster = 1;
    size_t completed_attempts = 0;
    long double ratios[24];
    uint64_t method_total_ns[2] = {0};
    uint64_t comparison_start_ns;
    uint64_t comparison_finish_ns;
    if (read_clock(&comparison_start_ns) != 0 ||
        fputs("task\trepetition\tmethod\twall_ns\texit_status\ttail_count\tassignment_count\n",
            ledger) == EOF) {
        goto cleanup;
    }
    for (size_t task_index = 0; task_index < 8u; ++task_index) {
        char csv_path[4096];
        char plan_path[4096];
        char task_name[65];
        (void)snprintf(task_name, sizeof(task_name), "task-%zu.csv", task_index + 1u);
        if (paired_data_path(csv_path, sizeof(csv_path), argument_values[4], task_name) != 0) {
            goto cleanup;
        }
        (void)snprintf(task_name, sizeof(task_name), "task-%zu.plan", task_index + 1u);
        if (paired_data_path(plan_path, sizeof(plan_path), argument_values[4], task_name) != 0) {
            goto cleanup;
        }
        char original_digest[65];
        char final_digest[65];
        if (paired_digest_file(csv_path, original_digest) != 0) {
            goto cleanup;
        }
        uint64_t smallest_baseline_ns = UINT64_MAX;
        uint64_t largest_candidate_ns = 0;
        for (size_t repetition_index = 0; repetition_index < 3u; ++repetition_index) {
            uint64_t wall_ns[2] = {0};
            uint64_t result_counts[2][2] = {{0}};
            for (size_t method_position = 0; method_position < 2u; ++method_position) {
                size_t method_index = (task_index + repetition_index) % 2u == 0
                    ? method_position
                    : 1u - method_position;
                char report_name[192];
                char log_name[192];
                char report_path[4096];
                char log_path[4096];
                (void)snprintf(report_name,
                    sizeof(report_name),
                    "task-%zu-r%zu-%s.report",
                    task_index + 1u,
                    repetition_index + 1u,
                    method_index == 0 ? "baseline" : "candidate");
                (void)snprintf(log_name,
                    sizeof(log_name),
                    "task-%zu-r%zu-%s.log",
                    task_index + 1u,
                    repetition_index + 1u,
                    method_index == 0 ? "baseline" : "candidate");
                if (paired_data_path(report_path,
                        sizeof(report_path),
                        argument_values[5],
                        report_name) != 0 ||
                    paired_data_path(log_path, sizeof(log_path), argument_values[5], log_name) !=
                        0 ||
                    deadline_reached) {
                    goto cleanup;
                }
                char *candidate_arguments[] =
                    {argument_values[1], "analyze", csv_path, plan_path, report_path, NULL};
                char *baseline_arguments[] = {argument_values[2],
                    argument_values[3],
                    csv_path,
                    plan_path,
                    report_path,
                    NULL};
                int child_status =
                    run_process(method_index == 0 ? baseline_arguments : candidate_arguments,
                        log_path,
                        &wall_ns[method_index]);
                int result_failed =
                    child_status != 0 || read_result(report_path, result_counts[method_index]) != 0;
                if (fprintf(ledger,
                        "%zu\t%zu\t%s\t%" PRIu64 "\t%d\t%" PRIu64 "\t%" PRIu64 "\n",
                        task_index + 1u,
                        repetition_index + 1u,
                        method_index == 0 ? "baseline" : "candidate",
                        wall_ns[method_index],
                        child_status,
                        result_counts[method_index][1],
                        result_counts[method_index][0]) < 0 ||
                    fflush(ledger) != 0 || result_failed) {
                    goto cleanup;
                }
                ++completed_attempts;
                method_total_ns[method_index] += wall_ns[method_index];
            }
            if (memcmp(result_counts[0], result_counts[1], sizeof(result_counts[0])) != 0) {
                goto cleanup;
            }
            ratios[3u * task_index + repetition_index] =
                (long double)wall_ns[1] / (long double)wall_ns[0];
            if (wall_ns[0] < smallest_baseline_ns) {
                smallest_baseline_ns = wall_ns[0];
            }
            if (wall_ns[1] > largest_candidate_ns) {
                largest_candidate_ns = wall_ns[1];
            }
        }
        if (largest_candidate_ns >= smallest_baseline_ns) {
            all_tasks_faster = 0;
        }
        if (paired_digest_file(csv_path, final_digest) != 0 ||
            strcmp(original_digest, final_digest) != 0) {
            goto cleanup;
        }
    }
    if (read_clock(&comparison_finish_ns) != 0 || deadline_reached ||
        comparison_finish_ns - comparison_start_ns > UINT64_C(300000000000)) {
        goto cleanup;
    }
    qsort(ratios, 24, sizeof(*ratios), compare_ratios);
    long double median_ratio = (ratios[11] + ratios[12]) / 2.0L;
    FILE *summary = fopen(summary_path, "wx");
    if (summary == NULL) {
        goto cleanup;
    }
    operation_status =
        fprintf(summary,
            "format=replay_efficiency_v1\nclock=CLOCK_MONOTONIC\ntime_unit=ns\n"
            "completed_attempts=%zu\nexact_counts_identical=yes\nraw_csv_unchanged=yes\n"
            "all_task_candidate_max_below_baseline_min=%s\nmedian_process_wall_ratio=%.9Lf\n"
            "ratio_min=%.9Lf\nratio_max=%.9Lf\nbaseline_process_total_ns=%" PRIu64
            "\ncandidate_process_total_ns=%" PRIu64 "\ncomparison_wall_ns=%" PRIu64
            "\nresult_status=%s\nuncertainty=fixed_eight_tasks_three_runs_each\n"
            "general_population_interval=unavailable\nsecret_attribution=not_assessed\nreport_"
            "status=complete\n",
            completed_attempts,
            all_tasks_faster ? "yes" : "no",
            median_ratio,
            ratios[0],
            ratios[23],
            method_total_ns[0],
            method_total_ns[1],
            comparison_finish_ns - comparison_start_ns,
            all_tasks_faster && median_ratio <= 0.5L ? "supports_this_exact_replay_efficiency"
                                                     : "improvement_conditions_not_met") < 0;
    if (fclose(summary) != 0) {
        operation_status = 1;
    }
cleanup:
    (void)alarm(0);
    if (fclose(ledger) != 0) {
        operation_status = 1;
    }
    if (operation_status != 0) {
        fputs("comparison failed or insufficient; retain every attempt\n", stderr);
    }
    return operation_status;
}
