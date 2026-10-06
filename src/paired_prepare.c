#define _POSIX_C_SOURCE 200809L
#include "build_identity.h"
#include "paired_data.h"
#include "paired_statistics.h"

#include <errno.h>
#include <fcntl.h>
#include <inttypes.h>
#include <signal.h>
#include <stdlib.h>
#include <string.h>
#include <sys/stat.h>
#include <sys/time.h>
#include <sys/wait.h>
#include <time.h>
#include <unistd.h>

#define PREPARATION_REPORTING_UPPER_NS UINT64_C(1000000000)
#define SHARED_WALL_LIMIT_NS UINT64_C(3600000000000)

static volatile sig_atomic_t reporting_expired;
static volatile sig_atomic_t initialization_process;

static void stop_reporting(int signal_number)
{
    (void)signal_number;
    reporting_expired = 1;
    if (initialization_process > 0) {
        (void)kill((pid_t)initialization_process, SIGKILL);
    }
}

static int read_clock(uint64_t *timestamp_nanoseconds)
{
    struct timespec timestamp;
    if (clock_gettime(CLOCK_MONOTONIC, &timestamp) != 0 || timestamp.tv_sec < 0 ||
        timestamp.tv_nsec < 0 || timestamp.tv_nsec >= 1000000000L ||
        (uint64_t)timestamp.tv_sec >
            (UINT64_MAX - (uint64_t)timestamp.tv_nsec) / UINT64_C(1000000000)) {
        return 1;
    }
    *timestamp_nanoseconds =
        (uint64_t)timestamp.tv_sec * UINT64_C(1000000000) + (uint64_t)timestamp.tv_nsec;
    return 0;
}

static int create_shared_cost(const char *output_path,
    const char *library_path,
    uint64_t start_nanoseconds,
    uint64_t bootstrap_upper,
    uint64_t reporting_upper,
    const char *platform_review,
    const char *dependency_review)
{
    uint64_t finish_nanoseconds;
    char source_commit[41] = "";
    char library_digest[65];
    if (bootstrap_upper > UINT64_C(600000000000) - reporting_upper ||
        paired_digest_file(library_path, library_digest) != 0 ||
        (strcmp(platform_review, "pending") != 0 && strcmp(platform_review, "accepted") != 0) ||
        (strcmp(dependency_review, "pending") != 0 && strcmp(dependency_review, "accepted") != 0)) {
        return 1;
    }
    if (read_clock(&finish_nanoseconds) != 0 || finish_nanoseconds < start_nanoseconds ||
        finish_nanoseconds - start_nanoseconds >
            SHARED_WALL_LIMIT_NS - bootstrap_upper - reporting_upper) {
        return 1;
    }
    for (size_t line_index = 0;
        line_index < sizeof(build_identity_lines) / sizeof(build_identity_lines[0]);
        ++line_index) {
        if (strncmp(build_identity_lines[line_index], "source_commit=", 14) == 0) {
            memcpy(source_commit, build_identity_lines[line_index] + 14, 40);
            source_commit[40] = '\0';
        }
    }
    if (!is_paired_hex(source_commit, 40)) {
        return 1;
    }
    FILE *output = fopen(output_path, "wx");
    if (output == NULL) {
        return 1;
    }
    uint64_t measured_wall = finish_nanoseconds - start_nanoseconds;
    int operation_status =
        fprintf(output,
            "format=%s\nsource_commit=%s\nkernel_library_digest=%s\n"
            "cost_closure=bounded\nplatform_review=%s\ndependency_review=%s\npreflight_status="
            "complete\n"
            "shared_calls_upper=40000\nshared_wall_lower_ns=%" PRIu64
            "\nshared_wall_upper_ns=%" PRIu64
            "\nshared_clock=CLOCK_MONOTONIC\nbootstrap_wall_upper_ns=%" PRIu64
            "\nreporting_wall_upper_ns=%" PRIu64 "\n"
            "call_bound=reference_and_paired_preflight_fixed_tests_plus_9000_reference_calls\n",
            reporting_upper == 0 ? "paired_shared_cost_v1" : "paired_shared_cost_v2",
            source_commit,
            library_digest,
            platform_review,
            dependency_review,
            measured_wall,
            measured_wall + bootstrap_upper + reporting_upper,
            bootstrap_upper,
            reporting_upper) < 0;
    int output_sync_failed = fflush(output) != 0 || fsync(fileno(output)) != 0;
    if (fclose(output) != 0 || output_sync_failed) {
        operation_status = 1;
    }
    return operation_status;
}

static int finish_preparation(const char *directory,
    const char *library_path,
    uint64_t start_nanoseconds,
    uint64_t bootstrap_upper,
    const char *platform_review,
    const char *dependency_review,
    const char *runner_path)
{
    char shared_path[4096];
    char budget_path[4096];
    char receipt_path[4096];
    char temporary_path[4096];
    char status_path[4096];
    char steps_path[4096];
    uint64_t reporting_start;
    if (bootstrap_upper > UINT64_C(599000000000) ||
        paired_data_path(shared_path, sizeof(shared_path), directory, "shared.cost") != 0 ||
        paired_data_path(budget_path, sizeof(budget_path), directory, "budget.meta") != 0 ||
        paired_data_path(receipt_path,
            sizeof(receipt_path),
            directory,
            "budget.meta.preparation") != 0 ||
        paired_data_path(temporary_path,
            sizeof(temporary_path),
            directory,
            "budget.meta.preparation.new") != 0 ||
        paired_data_path(status_path, sizeof(status_path), directory, "preparation-status.txt") !=
            0 ||
        paired_data_path(steps_path, sizeof(steps_path), directory, "step-exits.tsv") != 0 ||
        read_clock(&reporting_start) != 0) {
        return 1;
    }
    if (access(shared_path, F_OK) == 0 || errno != ENOENT) {
        return 1;
    }
    struct sigaction action = {0};
    action.sa_handler = stop_reporting;
    struct itimerval reporting_timer = {{0, 0}, {1, 0}};
    if (sigemptyset(&action.sa_mask) != 0 || sigaction(SIGALRM, &action, NULL) != 0 ||
        setitimer(ITIMER_REAL, &reporting_timer, NULL) != 0) {
        return 1;
    }
    /* 最后写账和发布也计共同上界；失败保留未闭合的准备收据。 */
    int operation_status = create_shared_cost(shared_path,
        library_path,
        start_nanoseconds,
        bootstrap_upper,
        PREPARATION_REPORTING_UPPER_NS,
        platform_review,
        dependency_review);
    pid_t child_process = -1;
    if (operation_status == 0 && !reporting_expired) {
        child_process = fork();
        if (child_process == 0) {
            execl(runner_path, runner_path, "init", budget_path, shared_path, (char *)NULL);
            _exit(127);
        }
        initialization_process = (sig_atomic_t)child_process;
        if (child_process > 0 && reporting_expired) {
            (void)kill(child_process, SIGKILL);
        }
        if (child_process < 0) {
            operation_status = 1;
        } else {
            int wait_status;
            pid_t waited_process;
            do {
                waited_process = waitpid(child_process, &wait_status, 0);
            } while (waited_process < 0 && errno == EINTR);
            operation_status = waited_process != child_process || !WIFEXITED(wait_status) ||
                WEXITSTATUS(wait_status) != 0;
        }
        initialization_process = 0;
    }
    char source_commit[41];
    struct paired_text_field source_field = {"source_commit", source_commit, 41, 0};
    if (operation_status == 0 && read_paired_fields(shared_path, &source_field, 1) != 0) {
        operation_status = 1;
    }
    FILE *status_file = fopen(status_path, "wx");
    if (status_file == NULL) {
        operation_status = 1;
    } else {
        if (fprintf(status_file, "preparation_exit_status=%d\n", operation_status != 0) < 0 ||
            fflush(status_file) != 0 || fsync(fileno(status_file)) != 0) {
            operation_status = 1;
        }
        if (fclose(status_file) != 0) {
            operation_status = 1;
        }
    }
    FILE *steps_file = fopen(steps_path, "a");
    if (steps_file == NULL) {
        operation_status = 1;
    } else {
        if (fprintf(steps_file, "finish-cost-and-budget\t%d\n", operation_status != 0) < 0 ||
            fflush(steps_file) != 0 || fsync(fileno(steps_file)) != 0) {
            operation_status = 1;
        }
        if (fclose(steps_file) != 0) {
            operation_status = 1;
        }
    }
    if (operation_status == 0 && !reporting_expired) {
        FILE *receipt = fopen(temporary_path, "wx");
        if (receipt == NULL) {
            operation_status = 1;
        } else {
            if (fprintf(receipt,
                    "preparation_status=complete\nsource_commit=%s\n"
                    "reporting_wall_upper_ns=1000000000\n",
                    source_commit) < 0 ||
                fflush(receipt) != 0 || fsync(fileno(receipt)) != 0) {
                operation_status = 1;
            }
            if (fclose(receipt) != 0) {
                operation_status = 1;
            }
        }
    }
    uint64_t reporting_finish;
    if (read_clock(&reporting_finish) != 0 || reporting_finish < reporting_start ||
        reporting_finish - reporting_start >= PREPARATION_REPORTING_UPPER_NS || reporting_expired) {
        operation_status = 1;
    }
    if (operation_status == 0 && rename(temporary_path, receipt_path) != 0) {
        operation_status = 1;
    }
    if (operation_status == 0) {
        int directory_descriptor = open(directory, O_RDONLY);
        if (directory_descriptor < 0) {
            operation_status = 1;
        } else {
            int directory_sync_failed = fsync(directory_descriptor) != 0;
            if (close(directory_descriptor) != 0 || directory_sync_failed) {
                operation_status = 1;
            }
        }
        if (operation_status != 0) {
            (void)unlink(receipt_path);
        }
    }
    if (read_clock(&reporting_finish) != 0 || reporting_finish < reporting_start ||
        reporting_finish - reporting_start >= PREPARATION_REPORTING_UPPER_NS || reporting_expired) {
        if (operation_status == 0) {
            (void)unlink(receipt_path);
        }
        operation_status = 1;
    }
    reporting_timer.it_value.tv_sec = 0;
    if (setitimer(ITIMER_REAL, &reporting_timer, NULL) != 0) {
        (void)unlink(receipt_path);
        operation_status = 1;
    }
    if (read_clock(&reporting_finish) != 0 || reporting_finish < reporting_start ||
        reporting_finish - reporting_start >= PREPARATION_REPORTING_UPPER_NS || reporting_expired) {
        if (operation_status == 0) {
            (void)unlink(receipt_path);
        }
        operation_status = 1;
    }
    if (operation_status != 0) {
        status_file = fopen(status_path, "w");
        if (status_file != NULL) {
            (void)fputs("preparation_exit_status=1\n", status_file);
            (void)fclose(status_file);
        }
        steps_file = fopen(steps_path, "a");
        if (steps_file != NULL) {
            (void)fputs("finish-publication\t1\n", steps_file);
            (void)fclose(steps_file);
        }
    }
    return operation_status;
}

static int create_development_plans(const char *directory)
{
    if (mkdir(directory, 0700) != 0) {
        return 1;
    }
    unsigned first_methods[10];
    for (size_t pair_index = 0; pair_index < 10u; ++pair_index) {
        first_methods[pair_index] = pair_index < 5u ? 0u : 1u;
    }
    uint64_t random_state = UINT64_C(20261031);
    for (size_t remaining_count = 10; remaining_count > 1u; --remaining_count) {
        size_t selected_index;
        if (draw_paired_index(&random_state, remaining_count, &selected_index) != 0) {
            return 1;
        }
        unsigned selected_method = first_methods[selected_index];
        first_methods[selected_index] = first_methods[remaining_count - 1u];
        first_methods[remaining_count - 1u] = selected_method;
    }
    for (unsigned candidate_index = 0; candidate_index < 2u; ++candidate_index) {
        unsigned batch_size = candidate_index == 0 ? 4u : 16u;
        char filename[64];
        char path[4096];
        (void)snprintf(filename, sizeof(filename), "development-k%u.plan.csv", batch_size);
        if (paired_data_path(path, sizeof(path), directory, filename) != 0) {
            return 1;
        }
        FILE *plan = fopen(path, "wx");
        if (plan == NULL) {
            return 1;
        }
        int operation_status =
            fputs("block_id,seed,samples_per_category,batch_size,first_method\n", plan) == EOF;
        for (size_t pair_index = 0; pair_index < 5u; ++pair_index) {
            uint64_t seed = UINT64_C(2026120101) + 100u * candidate_index + pair_index;
            if (fprintf(plan,
                    "development-k%u-%zu,%" PRIu64 ",1000,%u,%s\n",
                    batch_size,
                    pair_index,
                    seed,
                    batch_size,
                    first_methods[5u * candidate_index + pair_index] == 0 ? "baseline"
                                                                          : "candidate") < 0) {
                operation_status = 1;
            }
        }
        if (fclose(plan) != 0 || operation_status != 0) {
            return 1;
        }
    }
    char state_path[4096];
    if (paired_data_path(state_path, sizeof(state_path), directory, "state.txt") != 0) {
        return 1;
    }
    FILE *state_file = fopen(state_path, "wx");
    if (state_file == NULL) {
        return 1;
    }
    int operation_status =
        fputs("plan_state=proposed_not_executed\nconfirmation_candidate=not_selected\n"
              "confirmation_cohort=not_frozen\norder_seed=20261031\n",
            state_file) == EOF;
    if (fclose(state_file) != 0) {
        operation_status = 1;
    }
    return operation_status;
}

static int validate_plan(const char *plan_path, const char *registry_path)
{
    uint64_t registry[2048];
    size_t registry_count = 0;
    FILE *registry_file = fopen(registry_path, "r");
    char line[512];
    if (registry_file == NULL) {
        return 1;
    }
    while (fgets(line, sizeof(line), registry_file) != NULL) {
        size_t line_bytes = strlen(line);
        if (registry_count >= 2048u || line_bytes == 0 || line[line_bytes - 1u] != '\n') {
            (void)fclose(registry_file);
            return 1;
        }
        line[line_bytes - 1u] = '\0';
        if (parse_unsigned_integer(line, &registry[registry_count++]) != 0) {
            (void)fclose(registry_file);
            return 1;
        }
    }
    int operation_status = ferror(registry_file) != 0;
    if (fclose(registry_file) != 0 || operation_status || registry_count == 0) {
        return 1;
    }
    FILE *plan = fopen(plan_path, "r");
    if (plan == NULL) {
        return 1;
    }
    if (fgets(line, sizeof(line), plan) == NULL ||
        strcmp(line, "block_id,seed,samples_per_category,batch_size,first_method\n") != 0) {
        (void)fclose(plan);
        return 1;
    }
    size_t plan_count = 0;
    while (fgets(line, sizeof(line), plan) != NULL) {
        char *fields[5];
        uint64_t seed;
        if (split_paired_csv(line, fields, 5) != 0 ||
            parse_unsigned_integer(fields[1], &seed) != 0) {
            operation_status = 1;
            break;
        }
        for (size_t seed_index = 0; seed_index < registry_count; ++seed_index) {
            if (seed == registry[seed_index]) {
                operation_status = 1;
            }
        }
        if (seed <= 63u || seed == PAIRED_ANALYSIS_SEED) {
            operation_status = 1;
        }
        ++plan_count;
    }
    if (ferror(plan) || plan_count == 0) {
        operation_status = 1;
    }
    if (fclose(plan) != 0) {
        operation_status = 1;
    }
    return operation_status;
}

int main(int argument_count, char **argument_values)
{
    if (argument_count == 9 && strcmp(argument_values[1], "finish") == 0) {
        uint64_t start_nanoseconds;
        uint64_t bootstrap_upper;
        if (parse_unsigned_integer(argument_values[4], &start_nanoseconds) != 0 ||
            parse_unsigned_integer(argument_values[5], &bootstrap_upper) != 0) {
            return 2;
        }
        return finish_preparation(argument_values[2],
            argument_values[3],
            start_nanoseconds,
            bootstrap_upper,
            argument_values[6],
            argument_values[7],
            argument_values[8]);
    }
    if (argument_count == 2 && strcmp(argument_values[1], "clock") == 0) {
        uint64_t timestamp_nanoseconds;
        if (read_clock(&timestamp_nanoseconds) != 0) {
            return 1;
        }
        printf("%" PRIu64 "\n", timestamp_nanoseconds);
        return 0;
    }
    if (argument_count == 3 && strcmp(argument_values[1], "development-plans") == 0) {
        return create_development_plans(argument_values[2]);
    }
    if (argument_count == 4 && strcmp(argument_values[1], "validate-plan") == 0) {
        return validate_plan(argument_values[2], argument_values[3]);
    }
    if (argument_count == 8 && strcmp(argument_values[1], "shared") == 0) {
        uint64_t start_nanoseconds;
        uint64_t bootstrap_upper;
        if (parse_unsigned_integer(argument_values[4], &start_nanoseconds) != 0 ||
            parse_unsigned_integer(argument_values[5], &bootstrap_upper) != 0) {
            return 2;
        }
        return create_shared_cost(argument_values[2],
            argument_values[3],
            start_nanoseconds,
            bootstrap_upper,
            0,
            argument_values[6],
            argument_values[7]);
    }
    fputs("Usage: paired_prepare clock\n"
          "       paired_prepare finish DIRECTORY LIBRARY START_NS BOOTSTRAP_UPPER_NS "
          "PLATFORM_REVIEW DEPENDENCY_REVIEW RUNNER\n"
          "       paired_prepare development-plans NEW_DIRECTORY\n"
          "       paired_prepare validate-plan PLAN_CSV EXCLUDED_SEEDS_FILE\n"
          "       paired_prepare shared NEW_COST_FILE LIBRARY START_NS BOOTSTRAP_UPPER_NS "
          "PLATFORM_REVIEW DEPENDENCY_REVIEW\n",
        stderr);
    return 2;
}
