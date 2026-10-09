#define _POSIX_C_SOURCE 200809L
#ifdef __APPLE__
#define _DARWIN_C_SOURCE
#endif
#include "build_identity.h"
#include "paired_data.h"
#include "test_temp_directory.h"

#include <assert.h>
#include <fcntl.h>
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

static void verify_budget(const char *path,
    uint64_t development_calls,
    uint64_t baseline_auxiliary_calls,
    uint64_t candidate_auxiliary_calls,
    uint64_t observer_pending)
{
    static const char *const names[] = {"baseline_development_calls",
        "candidate_development_calls",
        "baseline_confirmation_calls",
        "candidate_confirmation_calls",
        "baseline_auxiliary_calls",
        "candidate_auxiliary_calls",
        "pending_method",
        "observer_pending"};
    char values[8][32];
    struct paired_text_field fields[8];
    for (size_t field_index = 0; field_index < 8u; ++field_index) {
        fields[field_index] =
            (struct paired_text_field){names[field_index], values[field_index], 32, 0};
    }
    assert(read_paired_fields(path, fields, 8) == 0);
    const uint64_t expected[] = {development_calls,
        development_calls,
        0,
        0,
        baseline_auxiliary_calls,
        candidate_auxiliary_calls,
        0,
        observer_pending};
    for (size_t field_index = 0; field_index < 8u; ++field_index) {
        uint64_t actual;
        assert(parse_unsigned_integer(values[field_index], &actual) == 0);
        assert(actual == expected[field_index]);
    }
}

static void write_confirmation_plan(const char *path, uint64_t first_seed, int incorrect_order)
{
    static const unsigned frozen_order[20] =
        {1, 0, 1, 1, 0, 0, 0, 0, 0, 0, 1, 1, 0, 1, 0, 1, 1, 1, 0, 1};
    FILE *plan_file = fopen(path, "wx");
    assert(plan_file != NULL);
    assert(fputs("block_id,seed,samples_per_category,batch_size,first_method\n", plan_file) != EOF);
    for (size_t pair_index = 0; pair_index < 20u; ++pair_index) {
        unsigned first_method = frozen_order[pair_index];
        if (incorrect_order && pair_index < 2u) {
            first_method = 1u - first_method;
        }
        assert(fprintf(plan_file,
                   "confirmation-%zu,%" PRIu64 ",2000,4,%s\n",
                   pair_index,
                   pair_index == 0 ? first_seed : UINT64_C(2026130001) + pair_index,
                   first_method == 0u ? "baseline" : "candidate") > 0);
    }
    assert(fclose(plan_file) == 0);
}

static void write_development_plan(const char *path, unsigned batch_size, int invalid_plan)
{
    static const unsigned frozen_orders[2][5] = {{0, 0, 0, 1, 0}, {1, 1, 1, 0, 1}};
    unsigned candidate_index = batch_size == 4u ? 0u : 1u;
    FILE *plan_file = fopen(path, "wx");
    assert(plan_file != NULL);
    assert(fputs("block_id,seed,samples_per_category,batch_size,first_method\n", plan_file) != EOF);
    for (size_t pair_index = 0; pair_index < 5u; ++pair_index) {
        unsigned first_method = frozen_orders[candidate_index][pair_index];
        uint64_t seed = UINT64_C(2026120101) + 100u * candidate_index + pair_index;
        if (invalid_plan == 1 && pair_index == 0u) {
            first_method = 1u - first_method;
        } else if (invalid_plan == 2 && pair_index == 0u) {
            seed = 42;
        }
        assert(fprintf(plan_file,
                   "development-%zu,%" PRIu64 ",1000,%u,%s\n",
                   pair_index,
                   seed,
                   batch_size,
                   first_method == 0u ? "baseline" : "candidate") > 0);
    }
    assert(fclose(plan_file) == 0);
}

static void fail_publication(char *program,
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
    struct stat output_information;
    int output_created = 0;
    for (unsigned check_index = 0; check_index < 2000u; ++check_index) {
        if (stat(output_directory, &output_information) == 0) {
            output_created = 1;
            break;
        }
        struct timespec pause_duration = {0, 100000};
        (void)nanosleep(&pause_duration, NULL);
    }
    assert(output_created);
    assert(kill(runner_process, SIGSTOP) == 0);
    int wait_status;
    assert(waitpid(runner_process, &wait_status, WUNTRACED) == runner_process);
    assert(WIFSTOPPED(wait_status));
    char envelope_path[4096];
    assert(paired_data_path(envelope_path,
               sizeof(envelope_path),
               output_directory,
               "cohort.envelope") == 0);
    assert(mkdir(envelope_path, 0700) == 0);
    assert(kill(runner_process, SIGCONT) == 0);
    assert(waitpid(runner_process, &wait_status, 0) == runner_process);
    assert(WIFEXITED(wait_status) && WEXITSTATUS(wait_status) != 0);
    char context_path[4096];
    assert(
        paired_data_path(context_path, sizeof(context_path), output_directory, "cohort.meta") == 0);
    assert(access(context_path, F_OK) != 0);
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
    char directory[TEST_TEMP_DIRECTORY_CAPACITY_BYTES];
    assert(create_test_temp_directory(directory, sizeof(directory), "cry-paired-runner") != NULL);
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
    verify_budget(ledger_path, 6, 200, 200, 0);
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
    verify_budget(exhausted_ledger, 0, 0, 0, 1);
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
        verify_budget(failure_ledger, 0, 103, 0, 1);
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
    verify_budget(interrupted_ledger, 0, 103, 0, 1);
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
    verify_budget(tiny_ledger, 0, 103, 0, 1);

    char publication_shared[4096];
    char publication_ledger[4096];
    char publication_output[4096];
    char publication_following[4096];
    assert(paired_data_path(publication_shared,
               sizeof(publication_shared),
               directory,
               "publication.cost") == 0);
    assert(paired_data_path(publication_ledger,
               sizeof(publication_ledger),
               directory,
               "publication-budget.meta") == 0);
    assert(paired_data_path(publication_output,
               sizeof(publication_output),
               directory,
               "publication") == 0);
    assert(paired_data_path(publication_following,
               sizeof(publication_following),
               directory,
               "publication-following") == 0);
    write_shared(publication_shared, kernel_path, 0, 0);
    assert(initialize(argument_values[1], publication_ledger, publication_shared) == 0);
    fail_publication(argument_values[1],
        plan_path,
        argument_values[2],
        publication_output,
        publication_ledger);
    verify_budget(publication_ledger, 6, 200, 200, 1);
    assert(execute(argument_values[1],
               "software_fixture",
               plan_path,
               argument_values[2],
               publication_following,
               publication_ledger,
               NULL) == 1);
    assert(access(publication_following, F_OK) != 0);
    verify_budget(publication_ledger, 6, 200, 200, 1);

    char validation_shared[4096];
    char validation_ledger[4096];
    char validation_output[4096];
    assert(paired_data_path(validation_shared,
               sizeof(validation_shared),
               directory,
               "validation.cost") == 0);
    assert(paired_data_path(validation_ledger,
               sizeof(validation_ledger),
               directory,
               "validation-budget.meta") == 0);
    assert(paired_data_path(validation_output,
               sizeof(validation_output),
               directory,
               "validation-output") == 0);
    write_shared(validation_shared, kernel_path, 0, 0);
    assert(initialize(argument_values[1], validation_ledger, validation_shared) == 0);
    static const uint64_t confirmation_seeds[] = {UINT64_C(2026130001),
        0,
        63,
        777,
        31337,
        90210,
        8675309,
        20260926,
        20260930,
        20261006,
        20261007,
        20261008,
        20261029,
        20261111,
        141421356,
        UINT64_C(2026120101),
        UINT64_C(2026120105),
        UINT64_C(2026120201),
        UINT64_C(2026120205)};
    for (size_t seed_index = 0;
        seed_index < sizeof(confirmation_seeds) / sizeof(confirmation_seeds[0]);
        ++seed_index) {
        char validation_plan[4096];
        char filename[128];
        assert(snprintf(filename, sizeof(filename), "confirmation-seed-%zu.csv", seed_index) > 0);
        assert(
            paired_data_path(validation_plan, sizeof(validation_plan), directory, filename) == 0);
        write_confirmation_plan(validation_plan, confirmation_seeds[seed_index], 0);
        assert(execute(argument_values[1],
                   "confirmation",
                   validation_plan,
                   argument_values[2],
                   validation_output,
                   validation_ledger,
                   NULL) == (seed_index == 0u ? 2 : 1));
        verify_budget(validation_ledger, 0, 0, 0, 0);
        assert(access(validation_output, F_OK) != 0);
    }
    char order_plan[4096];
    assert(
        paired_data_path(order_plan, sizeof(order_plan), directory, "confirmation-order.csv") == 0);
    write_confirmation_plan(order_plan, UINT64_C(2026130001), 1);
    assert(execute(argument_values[1],
               "confirmation",
               order_plan,
               argument_values[2],
               validation_output,
               validation_ledger,
               NULL) == 1);
    verify_budget(validation_ledger, 0, 0, 0, 0);
    for (unsigned candidate_index = 0; candidate_index < 2u; ++candidate_index) {
        for (int invalid_plan = 0; invalid_plan < 3; ++invalid_plan) {
            char development_plan[4096];
            char filename[128];
            assert(snprintf(filename,
                       sizeof(filename),
                       "development-%u-%d.csv",
                       candidate_index,
                       invalid_plan) > 0);
            assert(
                paired_data_path(development_plan, sizeof(development_plan), directory, filename) ==
                0);
            write_development_plan(development_plan,
                candidate_index == 0u ? 4u : 16u,
                invalid_plan);
            assert(execute(argument_values[1],
                       "development",
                       development_plan,
                       argument_values[2],
                       validation_output,
                       validation_ledger,
                       NULL) == (invalid_plan == 0 ? 2 : 1));
            verify_budget(validation_ledger, 0, 0, 0, 0);
            assert(access(validation_output, F_OK) != 0);
        }
    }
    char receipt_path[4096];
    char receipt_source[41];
    struct paired_text_field source_field = {"source_commit",
        receipt_source,
        sizeof(receipt_source),
        0};
    assert(read_paired_fields(validation_ledger, &source_field, 1) == 0);
    assert(snprintf(receipt_path, sizeof(receipt_path), "%s.preparation", validation_ledger) > 0);
    for (unsigned receipt_index = 0; receipt_index < 2u; ++receipt_index) {
        FILE *receipt = fopen(receipt_path, "w");
        assert(receipt != NULL);
        assert(fprintf(receipt,
                   "preparation_status=%s\nsource_commit=%s\n",
                   receipt_index == 0u ? "unclosed" : "complete",
                   receipt_index == 0u ? receipt_source
                                       : "0000000000000000000000000000000000000000") > 0);
        assert(fclose(receipt) == 0);
        char valid_plan[4096];
        assert(paired_data_path(valid_plan,
                   sizeof(valid_plan),
                   directory,
                   "confirmation-seed-0.csv") == 0);
        assert(execute(argument_values[1],
                   "confirmation",
                   valid_plan,
                   argument_values[2],
                   validation_output,
                   validation_ledger,
                   NULL) == 2);
        verify_budget(validation_ledger, 0, 0, 0, 0);
        assert(access(validation_output, F_OK) != 0);
    }
    int start_pipe[2];
    assert(pipe(start_pipe) == 0);
    pid_t blocked_runner = fork();
    assert(blocked_runner >= 0);
    if (blocked_runner == 0) {
        assert(close(start_pipe[1]) == 0);
        char start_signal;
        assert(read(start_pipe[0], &start_signal, 1) == 1);
        assert(close(start_pipe[0]) == 0);
        execl(argument_values[1],
            argument_values[1],
            "run",
            "software_fixture",
            plan_path,
            argument_values[2],
            validation_output,
            validation_ledger,
            (char *)NULL);
        _exit(127);
    }
    assert(close(start_pipe[0]) == 0);
    char blocked_update[4096];
    assert(snprintf(blocked_update,
               sizeof(blocked_update),
               "%s.new.%jd",
               validation_ledger,
               (intmax_t)blocked_runner) > 0);
    int blocked_descriptor = open(blocked_update, O_WRONLY | O_CREAT | O_EXCL, 0600);
    assert(blocked_descriptor >= 0 && close(blocked_descriptor) == 0);
    assert(write(start_pipe[1], "x", 1) == 1);
    assert(close(start_pipe[1]) == 0);
    int blocked_status;
    assert(waitpid(blocked_runner, &blocked_status, 0) == blocked_runner);
    assert(WIFEXITED(blocked_status) && WEXITSTATUS(blocked_status) != 0);
    assert(unlink(blocked_update) == 0);
    char audit_path[4096];
    assert(snprintf(audit_path, sizeof(audit_path), "%s.audit", validation_ledger) > 0);
    assert(access(audit_path, F_OK) == 0);
    verify_budget(validation_ledger, 0, 0, 0, 0);
    assert(execute(argument_values[1],
               "software_fixture",
               plan_path,
               argument_values[2],
               validation_output,
               validation_ledger,
               NULL) == 1);
    assert(access(validation_output, F_OK) != 0);
    verify_budget(validation_ledger, 0, 0, 0, 0);
    printf("software_runner_fixture_directory=%s\n", directory);
    return 0;
}
