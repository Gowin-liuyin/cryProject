#define _POSIX_C_SOURCE 200809L
#ifdef __APPLE__
#define _DARWIN_C_SOURCE
#endif
#include "build_identity.h"
#include "paired_data.h"

#include <assert.h>
#include <inttypes.h>
#include <signal.h>
#include <stdlib.h>
#include <string.h>
#include <sys/stat.h>
#include <sys/wait.h>
#include <time.h>
#include <unistd.h>

static int run_arguments(char *const arguments[])
{
    pid_t child_process = fork();
    int wait_status;
    assert(child_process >= 0);
    if (child_process == 0) {
        execv(arguments[0], arguments);
        _exit(127);
    }
    assert(waitpid(child_process, &wait_status, 0) == child_process);
    assert(WIFEXITED(wait_status));
    return WEXITSTATUS(wait_status);
}

static void
write_shared(const char *path, const char *kernel_path, uint64_t shared_calls, int corrupt_digest)
{
    char digest[65];
    char source_commit[41] = "";
    assert(paired_digest_file(kernel_path, digest) == 0);
    if (corrupt_digest) {
        digest[0] = digest[0] == '0' ? '1' : '0';
    }
    for (size_t line_index = 0;
        line_index < sizeof(build_identity_lines) / sizeof(build_identity_lines[0]);
        ++line_index) {
        if (strncmp(build_identity_lines[line_index], "source_commit=", 14) == 0) {
            memcpy(source_commit, build_identity_lines[line_index] + 14, 40);
            source_commit[40] = '\0';
        }
    }
    assert(is_paired_hex(source_commit, 40));
    FILE *shared_file = fopen(path, "wx");
    assert(shared_file != NULL);
    assert(
        fprintf(shared_file,
            "source_commit=%s\nkernel_library_digest=%s\ncost_closure=exact\nplatform_review="
            "pending\n"
            "dependency_review=pending\npreflight_status=software_only\nshared_calls_upper=%" PRIu64
            "\nshared_wall_lower_ns=0\nshared_wall_upper_ns=0\n",
            source_commit,
            digest,
            shared_calls) > 0);
    assert(fclose(shared_file) == 0);
}

static void write_plan(const char *path, const char *prefix)
{
    FILE *plan_file = fopen(path, "wx");
    assert(plan_file != NULL);
    assert(fprintf(plan_file,
               "block_id,seed,samples_per_category,batch_size,first_method\n"
               "%s-0,42,1,4,baseline\n%s-1,43,1,4,candidate\n",
               prefix,
               prefix) > 0);
    assert(fclose(plan_file) == 0);
}

static int initialize(char *program, char *ledger_path, char *shared_path)
{
    char *arguments[] = {program, "init", ledger_path, shared_path, NULL};
    return run_arguments(arguments);
}

static int execute(char *program,
    char *phase,
    char *plan_path,
    char *build_directory,
    char *output_directory,
    char *ledger_path,
    char *wall_limit)
{
    char *arguments[] = {program,
        "run",
        phase,
        plan_path,
        build_directory,
        output_directory,
        ledger_path,
        wall_limit,
        NULL};
    return run_arguments(arguments);
}

static void verify_state(const char *directory, const char *expected)
{
    char path[4096];
    char state[64];
    assert(paired_data_path(path, sizeof(path), directory, "cohort.meta") == 0);
    struct paired_text_field field = {"cohort_status", state, sizeof(state), 0};
    assert(read_paired_fields(path, &field, 1) == 0);
    assert(strcmp(state, expected) == 0);
}

static void interrupt_execution(char *program,
    char *plan_path,
    char *build_directory,
    char *output_directory,
    char *ledger_path)
{
    pid_t runner_process = fork();
    assert(runner_process >= 0);
    if (runner_process == 0) {
        execl(program,
            program,
            "run",
            "software_fixture",
            plan_path,
            build_directory,
            output_directory,
            ledger_path,
            (char *)NULL);
        _exit(127);
    }
    int has_reservation = 0;
    for (unsigned check_index = 0; check_index < 200u; ++check_index) {
        char value[32];
        struct paired_text_field field = {"pending_method", value, sizeof(value), 0};
        if (read_paired_fields(ledger_path, &field, 1) == 0 && strcmp(value, "0") != 0) {
            has_reservation = 1;
            break;
        }
        struct timespec pause_duration = {0, 5000000};
        (void)nanosleep(&pause_duration, NULL);
    }
    assert(has_reservation);
    assert(kill(runner_process, SIGTERM) == 0);
    int wait_status;
    assert(waitpid(runner_process, &wait_status, 0) == runner_process);
    assert(WIFEXITED(wait_status) && WEXITSTATUS(wait_status) != 0);
}

int main(int argument_count, char **argument_values)
{
    assert(argument_count == 5);
    char directory[] = "/tmp/cry-paired-runner.XXXXXX";
    assert(mkdtemp(directory) != NULL);
    char plan_path[4096];
    char shared_path[4096];
    char ledger_path[4096];
    char output_path[4096];
    char kernel_path[4096];
    assert(
        snprintf(kernel_path, sizeof(kernel_path), "%s/reference/libmlkem.a", argument_values[2]) >
        0);
    assert(paired_data_path(plan_path, sizeof(plan_path), directory, "plan.csv") == 0);
    assert(paired_data_path(shared_path, sizeof(shared_path), directory, "shared.cost") == 0);
    assert(paired_data_path(ledger_path, sizeof(ledger_path), directory, "budget.meta") == 0);
    assert(paired_data_path(output_path, sizeof(output_path), directory, "successful") == 0);
    write_plan(plan_path, "fixture");
    write_shared(shared_path, kernel_path, 0, 0);
    assert(initialize(argument_values[1], ledger_path, shared_path) == 0);
    assert(initialize(argument_values[1], ledger_path, shared_path) == 1);
    assert(execute(argument_values[1],
               "software_fixture",
               plan_path,
               argument_values[2],
               output_path,
               ledger_path,
               NULL) == 0);
    verify_state(output_path, "complete");
    char report_path[4096];
    assert(
        paired_data_path(report_path, sizeof(report_path), directory, "actual-interface.report") ==
        0);
    char *analysis_arguments[] = {argument_values[3], output_path, report_path, NULL};
    assert(run_arguments(analysis_arguments) == 0);
    assert(execute(argument_values[1],
               "software_fixture",
               plan_path,
               argument_values[2],
               output_path,
               ledger_path,
               NULL) == 1);
    char exhausted_shared[4096];
    char exhausted_ledger[4096];
    char exhausted_output[4096];
    assert(
        paired_data_path(exhausted_shared, sizeof(exhausted_shared), directory, "exhausted.cost") ==
        0);
    assert(paired_data_path(exhausted_ledger,
               sizeof(exhausted_ledger),
               directory,
               "exhausted-budget.meta") == 0);
    assert(
        paired_data_path(exhausted_output, sizeof(exhausted_output), directory, "exhausted") == 0);
    write_shared(exhausted_shared, kernel_path, 80000, 0);
    assert(initialize(argument_values[1], exhausted_ledger, exhausted_shared) == 0);
    assert(execute(argument_values[1],
               "software_fixture",
               plan_path,
               argument_values[2],
               exhausted_output,
               exhausted_ledger,
               NULL) == 1);
    verify_state(exhausted_output, "partial");
    char bad_shared[4096];
    char bad_ledger[4096];
    char bad_output[4096];
    assert(paired_data_path(bad_shared, sizeof(bad_shared), directory, "mismatch.cost") == 0);
    assert(
        paired_data_path(bad_ledger, sizeof(bad_ledger), directory, "mismatch-budget.meta") == 0);
    assert(paired_data_path(bad_output, sizeof(bad_output), directory, "mismatch") == 0);
    write_shared(bad_shared, kernel_path, 0, 1);
    assert(initialize(argument_values[1], bad_ledger, bad_shared) == 0);
    assert(execute(argument_values[1],
               "software_fixture",
               plan_path,
               argument_values[2],
               bad_output,
               bad_ledger,
               NULL) == 1);
    assert(access(bad_output, F_OK) != 0);
    char stub_build[4096];
    char stub_reference[4096];
    char stub_program[4096];
    assert(paired_data_path(stub_build, sizeof(stub_build), directory, "stub-build") == 0 &&
        mkdir(stub_build, 0700) == 0);
    assert(paired_data_path(stub_reference, sizeof(stub_reference), stub_build, "reference") == 0 &&
        mkdir(stub_reference, 0700) == 0);
    assert(paired_data_path(stub_program, sizeof(stub_program), stub_reference, "benchmark") == 0 &&
        symlink(argument_values[4], stub_program) == 0);
    assert(
        paired_data_path(stub_program, sizeof(stub_program), stub_reference, "batch_benchmark") ==
            0 &&
        symlink(argument_values[4], stub_program) == 0);
    assert(
        paired_data_path(stub_program, sizeof(stub_program), stub_reference, "libmlkem.a") == 0 &&
        symlink(kernel_path, stub_program) == 0);
    const char *failure_modes[] = {"nonzero", "missing", "timeout"};
    for (size_t failure_index = 0; failure_index < 3u; ++failure_index) {
        char failure_shared[4096];
        char failure_ledger[4096];
        char failure_output[4096];
        char filename[192];
        assert(snprintf(filename, sizeof(filename), "failure-%zu.cost", failure_index) > 0);
        assert(paired_data_path(failure_shared, sizeof(failure_shared), directory, filename) == 0);
        assert(snprintf(filename, sizeof(filename), "failure-%zu-budget.meta", failure_index) > 0);
        assert(paired_data_path(failure_ledger, sizeof(failure_ledger), directory, filename) == 0);
        assert(snprintf(filename, sizeof(filename), "failure-%zu", failure_index) > 0);
        assert(paired_data_path(failure_output, sizeof(failure_output), directory, filename) == 0);
        write_shared(failure_shared, kernel_path, 0, 0);
        assert(initialize(argument_values[1], failure_ledger, failure_shared) == 0);
        assert(setenv("PAIRED_FAILURE_MODE", failure_modes[failure_index], 1) == 0);
        assert(execute(argument_values[1],
                   "software_fixture",
                   plan_path,
                   stub_build,
                   failure_output,
                   failure_ledger,
                   failure_index == 2 ? "300000000" : NULL) == 1);
        verify_state(failure_output, "partial");
    }
    assert(unsetenv("PAIRED_FAILURE_MODE") == 0);
    char interrupted_shared[4096];
    char interrupted_ledger[4096];
    char interrupted_output[4096];
    assert(paired_data_path(interrupted_shared,
               sizeof(interrupted_shared),
               directory,
               "interrupted.cost") == 0);
    assert(paired_data_path(interrupted_ledger,
               sizeof(interrupted_ledger),
               directory,
               "interrupted-budget.meta") == 0);
    assert(paired_data_path(interrupted_output,
               sizeof(interrupted_output),
               directory,
               "interrupted") == 0);
    write_shared(interrupted_shared, kernel_path, 0, 0);
    assert(initialize(argument_values[1], interrupted_ledger, interrupted_shared) == 0);
    assert(setenv("PAIRED_FAILURE_MODE", "timeout", 1) == 0);
    interrupt_execution(argument_values[1],
        plan_path,
        stub_build,
        interrupted_output,
        interrupted_ledger);
    verify_state(interrupted_output, "partial");
    assert(unsetenv("PAIRED_FAILURE_MODE") == 0);
    char tiny_shared[4096];
    char tiny_ledger[4096];
    char tiny_output[4096];
    assert(paired_data_path(tiny_shared, sizeof(tiny_shared), directory, "tiny.cost") == 0);
    assert(paired_data_path(tiny_ledger, sizeof(tiny_ledger), directory, "tiny-budget.meta") == 0);
    assert(paired_data_path(tiny_output, sizeof(tiny_output), directory, "tiny") == 0);
    write_shared(tiny_shared, kernel_path, 0, 0);
    assert(initialize(argument_values[1], tiny_ledger, tiny_shared) == 0);
    assert(execute(argument_values[1],
               "software_fixture",
               plan_path,
               argument_values[2],
               tiny_output,
               tiny_ledger,
               "1") == 1);
    verify_state(tiny_output, "partial");
    printf("software_runner_fixture_directory=%s\n", directory);
    return 0;
}
