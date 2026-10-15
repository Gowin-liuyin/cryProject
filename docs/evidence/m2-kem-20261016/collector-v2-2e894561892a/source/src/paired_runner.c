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
#include <sys/utsname.h>
#include <sys/wait.h>
#include <time.h>
#include <unistd.h>

#define METHOD_WALL_LIMIT_NS UINT64_C(1800000000000)
#define OBSERVER_REPORTING_UPPER_NS UINT64_C(1000000000)

struct budget_ledger {
    uint64_t development_calls[2];
    uint64_t confirmation_calls[2];
    uint64_t auxiliary_calls[2];
    uint64_t own_wall_nanoseconds[2];
    uint64_t shared_calls_upper;
    uint64_t shared_wall_lower;
    uint64_t shared_wall_upper;
    unsigned pending_method;
    unsigned observer_pending;
    char source_commit[41];
    char kernel_digest[65];
    char cost_closure[16];
    char platform_review[16];
    char dependency_review[16];
    char preflight_status[32];
};

struct planned_pair {
    char block_id[65];
    uint64_t seed;
    uint64_t samples_per_category;
    uint64_t batch_size;
    unsigned first_method;
};

static volatile sig_atomic_t deadline_reached;
static volatile sig_atomic_t interruption_signal;
static volatile sig_atomic_t active_child_process;
static volatile sig_atomic_t active_worker_process;

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

static void deadline_handler(int signal_number)
{
    (void)signal_number;
    deadline_reached = 1;
}

static void interruption_handler(int signal_number)
{
    interruption_signal = signal_number;
    if (active_child_process > 0) {
        (void)kill(-(pid_t)active_child_process, SIGKILL);
        (void)kill((pid_t)active_child_process, SIGKILL);
    }
    if (active_worker_process > 0) {
        (void)kill((pid_t)active_worker_process, SIGTERM);
    }
}

static int build_source(char source_commit[41])
{
    for (size_t line_index = 0;
        line_index < sizeof(build_identity_lines) / sizeof(build_identity_lines[0]);
        ++line_index) {
        if (strncmp(build_identity_lines[line_index], "source_commit=", 14) == 0 &&
            strlen(build_identity_lines[line_index]) == 55u) {
            memcpy(source_commit, build_identity_lines[line_index] + 14, 40);
            source_commit[40] = '\0';
            return !is_paired_hex(source_commit, 40);
        }
    }
    return 1;
}

static int sync_parent_directory(const char *path)
{
    char directory[4096];
    size_t path_length = strlen(path);
    if (path_length >= sizeof(directory)) {
        return 1;
    }
    memcpy(directory, path, path_length + 1u);
    char *separator = strrchr(directory, '/');
    if (separator == NULL) {
        memcpy(directory, ".", 2);
    } else if (separator == directory) {
        separator[1] = '\0';
    } else {
        *separator = '\0';
    }
    int directory_descriptor = open(directory, O_RDONLY);
    if (directory_descriptor < 0) {
        return 1;
    }
    int operation_status = fsync(directory_descriptor) != 0;
    if (close(directory_descriptor) != 0) {
        operation_status = 1;
    }
    return operation_status;
}

static int sync_data_file(const char *path)
{
    int file_descriptor = open(path, O_RDONLY);
    if (file_descriptor < 0) {
        return 1;
    }
    int operation_status = fsync(file_descriptor) != 0;
    if (close(file_descriptor) != 0) {
        operation_status = 1;
    }
    return operation_status;
}

static void preserve_budget_audit(const char *path)
{
    char audit_path[4096];
    int path_bytes = snprintf(audit_path, sizeof(audit_path), "%s.audit", path);
    if (path_bytes < 0 || (size_t)path_bytes >= sizeof(audit_path)) {
        return;
    }
    int audit_descriptor = open(audit_path, O_WRONLY | O_CREAT | O_EXCL, 0600);
    if (audit_descriptor >= 0) {
        static const char audit_state[] = "budget_state=unclosed\n";
        ssize_t written_bytes = write(audit_descriptor, audit_state, sizeof(audit_state) - 1u);
        if (written_bytes != (ssize_t)(sizeof(audit_state) - 1u)) {
            fputs("budget audit marker content incomplete\n", stderr);
        }
        (void)fsync(audit_descriptor);
        (void)close(audit_descriptor);
        (void)sync_parent_directory(audit_path);
    }
}

static int write_budget(const char *path, const struct budget_ledger *budget, int initial)
{
    char temporary_path[4096];
    char previous_path[4096];
    int path_bytes =
        snprintf(temporary_path, sizeof(temporary_path), "%s.new.%jd", path, (intmax_t)getpid());
    if (path_bytes < 0 || (size_t)path_bytes >= sizeof(temporary_path)) {
        return 1;
    }
    if (initial && access(path, F_OK) == 0) {
        return 1;
    }
    FILE *ledger_file = fopen(temporary_path, "wx");
    if (ledger_file == NULL) {
        preserve_budget_audit(path);
        return 1;
    }
    int operation_status =
        fprintf(ledger_file,
            "budget_format=paired_budget_v1\nsource_commit=%s\nkernel_library_digest=%s\n"
            "cost_closure=%s\nplatform_review=%s\ndependency_review=%s\npreflight_status=%s\n"
            "shared_calls_upper=%" PRIu64 "\nshared_wall_lower_ns=%" PRIu64
            "\nshared_wall_upper_ns=%" PRIu64 "\npending_method=%u\nobserver_pending=%u\n",
            budget->source_commit,
            budget->kernel_digest,
            budget->cost_closure,
            budget->platform_review,
            budget->dependency_review,
            budget->preflight_status,
            budget->shared_calls_upper,
            budget->shared_wall_lower,
            budget->shared_wall_upper,
            budget->pending_method,
            budget->observer_pending) < 0;
    for (size_t method_index = 0; method_index < 2u; ++method_index) {
        const char *method = method_index == 0 ? "baseline" : "candidate";
        if (fprintf(ledger_file,
                "%s_development_calls=%" PRIu64 "\n%s_confirmation_calls=%" PRIu64
                "\n%s_auxiliary_calls=%" PRIu64 "\n%s_own_wall_ns=%" PRIu64 "\n",
                method,
                budget->development_calls[method_index],
                method,
                budget->confirmation_calls[method_index],
                method,
                budget->auxiliary_calls[method_index],
                method,
                budget->own_wall_nanoseconds[method_index]) < 0) {
            operation_status = 1;
        }
    }
    if (fflush(ledger_file) != 0 || fsync(fileno(ledger_file)) != 0) {
        operation_status = 1;
    }
    if (fclose(ledger_file) != 0) {
        operation_status = 1;
    }
    if (operation_status == 0) {
        if (initial) {
            if (link(temporary_path, path) != 0 || unlink(temporary_path) != 0 ||
                sync_parent_directory(path) != 0) {
                operation_status = 1;
            }
        } else {
            path_bytes = snprintf(previous_path,
                sizeof(previous_path),
                "%s.previous.%jd",
                path,
                (intmax_t)getpid());
            if (path_bytes < 0 || (size_t)path_bytes >= sizeof(previous_path) ||
                link(path, previous_path) != 0 || sync_parent_directory(path) != 0 ||
                rename(temporary_path, path) != 0) {
                operation_status = 1;
            } else if (sync_parent_directory(path) != 0) {
                /* 同步失败时恢复上一份保守预留，不继续启动子程序。 */
                (void)rename(previous_path, path);
                (void)sync_parent_directory(path);
                operation_status = 1;
            } else {
                (void)unlink(previous_path);
            }
        }
    }
    if (operation_status != 0) {
        preserve_budget_audit(path);
    }
    return operation_status;
}

static int read_budget(const char *path, struct budget_ledger *budget)
{
    static const char *const names[] = {"budget_format",
        "source_commit",
        "kernel_library_digest",
        "cost_closure",
        "platform_review",
        "dependency_review",
        "preflight_status",
        "shared_calls_upper",
        "shared_wall_lower_ns",
        "shared_wall_upper_ns",
        "pending_method",
        "baseline_development_calls",
        "baseline_confirmation_calls",
        "baseline_auxiliary_calls",
        "baseline_own_wall_ns",
        "candidate_development_calls",
        "candidate_confirmation_calls",
        "candidate_auxiliary_calls",
        "candidate_own_wall_ns",
        "observer_pending"};
    char values[20][128];
    struct paired_text_field fields[20];
    for (size_t field_index = 0; field_index < 20u; ++field_index) {
        fields[field_index] =
            (struct paired_text_field){names[field_index], values[field_index], 128, 0};
    }
    if (read_paired_fields(path, fields, 20) != 0 || strcmp(values[0], "paired_budget_v1") != 0 ||
        !is_paired_hex(values[1], 40) || !is_paired_hex(values[2], 64)) {
        return 1;
    }
    uint64_t numbers[12];
    for (size_t number_index = 0; number_index < 12u; ++number_index) {
        if (parse_unsigned_integer(values[7u + number_index], &numbers[number_index]) != 0) {
            return 1;
        }
    }
    if (numbers[0] > 80000u || numbers[2] < numbers[1] || numbers[2] > 2u * METHOD_WALL_LIMIT_NS ||
        numbers[3] > 2u) {
        return 1;
    }
    memcpy(budget->source_commit, values[1], 41);
    memcpy(budget->kernel_digest, values[2], 65);
    char *text_targets[] = {budget->cost_closure,
        budget->platform_review,
        budget->dependency_review,
        budget->preflight_status};
    const size_t capacities[] = {16, 16, 16, 32};
    for (size_t text_index = 0; text_index < 4u; ++text_index) {
        if (strlen(values[3u + text_index]) >= capacities[text_index]) {
            return 1;
        }
        memcpy(text_targets[text_index],
            values[3u + text_index],
            strlen(values[3u + text_index]) + 1u);
    }
    budget->shared_calls_upper = numbers[0];
    budget->shared_wall_lower = numbers[1];
    budget->shared_wall_upper = numbers[2];
    budget->pending_method = (unsigned)numbers[3];
    uint64_t observer_pending;
    if (parse_unsigned_integer(values[19], &observer_pending) != 0 || observer_pending > 1u) {
        return 1;
    }
    budget->observer_pending = (unsigned)observer_pending;
    for (size_t method_index = 0; method_index < 2u; ++method_index) {
        budget->development_calls[method_index] = numbers[4u + method_index * 4u];
        budget->confirmation_calls[method_index] = numbers[5u + method_index * 4u];
        budget->auxiliary_calls[method_index] = numbers[6u + method_index * 4u];
        budget->own_wall_nanoseconds[method_index] = numbers[7u + method_index * 4u];
        if (budget->development_calls[method_index] > 200000u ||
            budget->confirmation_calls[method_index] > 200000u ||
            budget->auxiliary_calls[method_index] > 200000u ||
            budget->own_wall_nanoseconds[method_index] > 2u * METHOD_WALL_LIMIT_NS) {
            return 1;
        }
    }
    return 0;
}

static int initialize_budget(const char *path, const char *shared_path)
{
    const char *const names[] = {"source_commit",
        "kernel_library_digest",
        "cost_closure",
        "platform_review",
        "dependency_review",
        "preflight_status",
        "shared_calls_upper",
        "shared_wall_lower_ns",
        "shared_wall_upper_ns"};
    char values[9][128];
    struct paired_text_field fields[9];
    for (size_t field_index = 0; field_index < 9u; ++field_index) {
        fields[field_index] =
            (struct paired_text_field){names[field_index], values[field_index], 128, 0};
    }
    if (read_paired_fields(shared_path, fields, 9) != 0) {
        return 1;
    }
    struct budget_ledger budget = {0};
    char source_commit[41];
    if (build_source(source_commit) != 0 || strcmp(source_commit, values[0]) != 0 ||
        !is_paired_hex(values[1], 64) || strlen(values[2]) >= sizeof(budget.cost_closure) ||
        strlen(values[3]) >= sizeof(budget.platform_review) ||
        strlen(values[4]) >= sizeof(budget.dependency_review) ||
        strlen(values[5]) >= sizeof(budget.preflight_status) ||
        parse_unsigned_integer(values[6], &budget.shared_calls_upper) != 0 ||
        parse_unsigned_integer(values[7], &budget.shared_wall_lower) != 0 ||
        parse_unsigned_integer(values[8], &budget.shared_wall_upper) != 0 ||
        budget.shared_calls_upper > 80000u || budget.shared_wall_upper < budget.shared_wall_lower ||
        budget.shared_wall_upper > 2u * METHOD_WALL_LIMIT_NS) {
        return 1;
    }
    memcpy(budget.source_commit, source_commit, sizeof(source_commit));
    memcpy(budget.kernel_digest, values[1], 65);
    memcpy(budget.cost_closure, values[2], strlen(values[2]) + 1u);
    memcpy(budget.platform_review, values[3], strlen(values[3]) + 1u);
    memcpy(budget.dependency_review, values[4], strlen(values[4]) + 1u);
    memcpy(budget.preflight_status, values[5], strlen(values[5]) + 1u);
    return write_budget(path, &budget, 1);
}

static int excluded_confirmation_seed(uint64_t seed)
{
    static const uint64_t excluded_seeds[] = {777,
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
        141421356};
    if (seed <= 63u || (seed >= UINT64_C(2026120101) && seed <= UINT64_C(2026120105)) ||
        (seed >= UINT64_C(2026120201) && seed <= UINT64_C(2026120205))) {
        return 1;
    }
    for (size_t seed_index = 0; seed_index < sizeof(excluded_seeds) / sizeof(excluded_seeds[0]);
        ++seed_index) {
        if (seed == excluded_seeds[seed_index]) {
            return 1;
        }
    }
    return 0;
}

static int
validate_formal_plan(const char *phase, const struct planned_pair *pairs, size_t pair_count)
{
    if (strcmp(phase, "software_fixture") == 0) {
        return 0;
    }
    int confirmation = strcmp(phase, "confirmation") == 0;
    size_t order_count = confirmation ? 20u : 10u;
    unsigned first_methods[20];
    uint64_t random_state = confirmation ? UINT64_C(20261030) : UINT64_C(20261031);
    for (size_t order_index = 0; order_index < order_count; ++order_index) {
        first_methods[order_index] = order_index < order_count / 2u ? 0u : 1u;
    }
    for (size_t remaining_count = order_count; remaining_count > 1u; --remaining_count) {
        size_t selected_index;
        if (draw_paired_index(&random_state, remaining_count, &selected_index) != 0) {
            return 1;
        }
        unsigned selected_method = first_methods[selected_index];
        first_methods[selected_index] = first_methods[remaining_count - 1u];
        first_methods[remaining_count - 1u] = selected_method;
    }
    size_t order_offset = !confirmation && pairs[0].batch_size == 16u ? 5u : 0u;
    for (size_t pair_index = 0; pair_index < pair_count; ++pair_index) {
        if (pairs[pair_index].first_method != first_methods[order_offset + pair_index] ||
            (confirmation && excluded_confirmation_seed(pairs[pair_index].seed)) ||
            (!confirmation &&
                pairs[pair_index].seed !=
                    UINT64_C(2026120101) + (order_offset == 5u ? 100u : 0u) + pair_index)) {
            return 1;
        }
    }
    return 0;
}

static int
read_plan(const char *path, const char *phase, struct planned_pair pairs[20], size_t *pair_count)
{
    FILE *plan_file = fopen(path, "r");
    char line[512];
    int operation_status = 1;
    *pair_count = 0;
    if (plan_file == NULL) {
        return 1;
    }
    if (fgets(line, sizeof(line), plan_file) == NULL ||
        strcmp(line, "block_id,seed,samples_per_category,batch_size,first_method\n") != 0) {
        goto cleanup;
    }
    while (fgets(line, sizeof(line), plan_file) != NULL) {
        char *fields[5];
        if (*pair_count >= 20u || split_paired_csv(line, fields, 5) != 0 ||
            !is_paired_identifier(fields[0])) {
            goto cleanup;
        }
        struct planned_pair *pair = &pairs[*pair_count];
        if (parse_unsigned_integer(fields[1], &pair->seed) != 0 ||
            parse_unsigned_integer(fields[2], &pair->samples_per_category) != 0 ||
            parse_unsigned_integer(fields[3], &pair->batch_size) != 0 ||
            pair->samples_per_category == 0 || pair->samples_per_category > 20000u ||
            (pair->batch_size != 1u && pair->batch_size != 4u && pair->batch_size != 16u) ||
            (strcmp(fields[4], "baseline") != 0 && strcmp(fields[4], "candidate") != 0)) {
            goto cleanup;
        }
        memcpy(pair->block_id, fields[0], strlen(fields[0]) + 1u);
        pair->first_method = strcmp(fields[4], "baseline") == 0 ? 0u : 1u;
        for (size_t prior_index = 0; prior_index < *pair_count; ++prior_index) {
            if (strcmp(pairs[prior_index].block_id, pair->block_id) == 0 ||
                pairs[prior_index].seed == pair->seed ||
                pairs[prior_index].batch_size != pair->batch_size ||
                pairs[prior_index].samples_per_category != pair->samples_per_category) {
                goto cleanup;
            }
        }
        if ((strcmp(phase, "software_fixture") == 0 && pair->samples_per_category > 10u) ||
            (strcmp(phase, "development") == 0 &&
                (pair->samples_per_category != 1000u || pair->batch_size == 1u)) ||
            (strcmp(phase, "confirmation") == 0 &&
                (pair->samples_per_category != 2000u || pair->batch_size == 1u))) {
            goto cleanup;
        }
        ++*pair_count;
    }
    if (!ferror(plan_file) && *pair_count >= 2u &&
        (strcmp(phase, "development") != 0 || *pair_count == 5u) &&
        (strcmp(phase, "confirmation") != 0 || *pair_count == 20u) &&
        validate_formal_plan(phase, pairs, *pair_count) == 0) {
        operation_status = 0;
    }
cleanup:
    if (fclose(plan_file) != 0) {
        operation_status = 1;
    }
    return operation_status;
}

static int execute_method(const char *program,
    const struct planned_pair *pair,
    unsigned method_index,
    const char *csv_path,
    const char *metadata_path,
    const char *log_path,
    uint64_t remaining_wall)
{
    if (interruption_signal != 0) {
        return 130;
    }
    char seed_text[32];
    char count_text[32];
    char batch_text[32];
    (void)snprintf(seed_text, sizeof(seed_text), "%" PRIu64, pair->seed);
    (void)snprintf(count_text, sizeof(count_text), "%" PRIu64, pair->samples_per_category);
    (void)snprintf(batch_text, sizeof(batch_text), "%" PRIu64, pair->batch_size);
    int log_descriptor = open(log_path, O_WRONLY | O_CREAT | O_EXCL, 0600);
    if (log_descriptor < 0) {
        return 125;
    }
    pid_t child_process = fork();
    if (child_process < 0) {
        (void)close(log_descriptor);
        return 125;
    }
    if (child_process == 0) {
        (void)setpgid(0, 0);
        if (dup2(log_descriptor, STDOUT_FILENO) < 0 || dup2(log_descriptor, STDERR_FILENO) < 0) {
            _exit(127);
        }
        (void)close(log_descriptor);
        if (method_index == 0) {
            execl(program,
                program,
                pair->block_id,
                seed_text,
                count_text,
                csv_path,
                metadata_path,
                (char *)NULL);
        } else {
            execl(program,
                program,
                pair->block_id,
                seed_text,
                count_text,
                batch_text,
                csv_path,
                metadata_path,
                (char *)NULL);
        }
        _exit(127);
    }
    (void)close(log_descriptor);
    (void)setpgid(child_process, child_process);
    active_child_process = (sig_atomic_t)child_process;
    if (interruption_signal != 0) {
        (void)kill(-child_process, SIGKILL);
        (void)kill(child_process, SIGKILL);
    }
    struct itimerval timer = {0};
    uint64_t timeout_microseconds = (remaining_wall + 999u) / 1000u;
    timer.it_value.tv_sec = (time_t)(timeout_microseconds / UINT64_C(1000000));
    timer.it_value.tv_usec = (suseconds_t)(timeout_microseconds % UINT64_C(1000000));
    deadline_reached = 0;
    if (setitimer(ITIMER_REAL, &timer, NULL) != 0) {
        (void)kill(-child_process, SIGKILL);
        (void)kill(child_process, SIGKILL);
    }
    int wait_status;
    for (;;) {
        if (waitpid(child_process, &wait_status, 0) == child_process) {
            break;
        }
        if (errno != EINTR) {
            (void)kill(-child_process, SIGKILL);
            (void)kill(child_process, SIGKILL);
            (void)waitpid(child_process, &wait_status, 0);
            wait_status = -1;
            break;
        }
        if (deadline_reached) {
            (void)kill(-child_process, SIGKILL);
            (void)kill(child_process, SIGKILL);
        }
    }
    memset(&timer, 0, sizeof(timer));
    (void)setitimer(ITIMER_REAL, &timer, NULL);
    active_child_process = 0;
    if (interruption_signal != 0) {
        return 130;
    }
    if (deadline_reached) {
        return 124;
    }
    return wait_status >= 0 && WIFEXITED(wait_status) ? WEXITSTATUS(wait_status) : 128;
}

static int write_context(const char *directory,
    const char *phase,
    size_t pair_count,
    uint64_t batch_size,
    const struct budget_ledger *starting_budget,
    const char *baseline_executable_digest,
    const char *candidate_executable_digest,
    const char *state)
{
    char context_path[4096];
    char manifest_path[4096];
    char manifest_digest[65];
    if (paired_data_path(context_path, sizeof(context_path), directory, "cohort.meta") != 0 ||
        paired_data_path(manifest_path, sizeof(manifest_path), directory, "cohort.csv") != 0 ||
        paired_digest_file(manifest_path, manifest_digest) != 0) {
        return 1;
    }
    FILE *context_file = fopen(context_path, "wx");
    if (context_file == NULL) {
        return 1;
    }
    int operation_status =
        fprintf(context_file,
            "cohort_format=paired_cohort_v1\nphase=%s\nexpected_pairs=%zu\nshared_calls_upper="
            "%" PRIu64 "\nshared_wall_lower_ns=%" PRIu64 "\nshared_wall_upper_ns=%" PRIu64 "\n"
            "prior_baseline_development_calls=%" PRIu64
            "\nprior_candidate_development_calls=%" PRIu64
            "\nprior_baseline_auxiliary_calls=%" PRIu64 "\nprior_candidate_auxiliary_calls=%" PRIu64
            "\nprior_baseline_wall_ns=%" PRIu64 "\nprior_candidate_wall_ns=%" PRIu64
            "\nplatform_review=%s\ndependency_review=%s\ncost_closure=%s\nsource_commit=%s\n"
            "baseline_executable_digest=%s\ncandidate_executable_digest=%s\ncohort_manifest_digest="
            "%s\n"
            "selected_batch_size=%" PRIu64
            "\nprotocol_commit=5db7833c362b1bfb4b68d4fb7ff3418adba22cc9\ncohort_status=%s\n",
            phase,
            pair_count,
            starting_budget->shared_calls_upper,
            starting_budget->shared_wall_lower,
            starting_budget->shared_wall_upper,
            starting_budget->development_calls[0],
            starting_budget->development_calls[1],
            starting_budget->auxiliary_calls[0],
            starting_budget->auxiliary_calls[1],
            starting_budget->own_wall_nanoseconds[0],
            starting_budget->own_wall_nanoseconds[1],
            starting_budget->platform_review,
            starting_budget->dependency_review,
            starting_budget->cost_closure,
            starting_budget->source_commit,
            baseline_executable_digest,
            candidate_executable_digest,
            manifest_digest,
            batch_size,
            state) < 0;
    if (fclose(context_file) != 0) {
        operation_status = 1;
    }
    if (operation_status == 0 &&
        (sync_data_file(context_path) != 0 || sync_parent_directory(context_path) != 0)) {
        operation_status = 1;
    }
    return operation_status;
}

static int run_cohort(const char *phase,
    const char *plan_path,
    const char *build_directory,
    const char *output_directory,
    const char *budget_path,
    uint64_t wall_limit)
{
    struct budget_ledger budget;
    struct planned_pair pairs[20];
    size_t pair_count;
    struct utsname environment;
    char current_source[41];
    char lock_path[4096];
    char program_paths[2][4096];
    char executable_digests[2][65];
    char kernel_path[4096];
    char actual_kernel_digest[65];
    int path_bytes = snprintf(lock_path, sizeof(lock_path), "%s.lock", budget_path);
    if (path_bytes < 0 || (size_t)path_bytes >= sizeof(lock_path) ||
        read_plan(plan_path, phase, pairs, &pair_count) != 0 || build_source(current_source) != 0 ||
        read_budget(budget_path, &budget) != 0 || budget.pending_method != 0 ||
        strcmp(current_source, budget.source_commit) != 0 || uname(&environment) != 0) {
        return 1;
    }
    if (strcmp(phase, "software_fixture") != 0 &&
        (strcmp(environment.sysname, "Linux") != 0 || strcmp(environment.machine, "x86_64") != 0 ||
            strcmp(budget.preflight_status, "complete") != 0 ||
            strcmp(budget.platform_review, "accepted") != 0)) {
        fputs("native target preflight is required; this is not a target experiment\n", stderr);
        return 2;
    }
    int lock_descriptor = open(lock_path, O_WRONLY | O_CREAT, 0600);
    struct flock lock = {0};
    lock.l_type = F_WRLCK;
    lock.l_whence = SEEK_SET;
    if (lock_descriptor < 0 || fcntl(lock_descriptor, F_SETLK, &lock) != 0) {
        if (lock_descriptor >= 0) {
            (void)close(lock_descriptor);
        }
        return 1;
    }
    (void)fcntl(lock_descriptor, F_SETFD, FD_CLOEXEC);
    int operation_status = 1;
    FILE *manifest = NULL;
    FILE *attempt_log = NULL;
    if (read_budget(budget_path, &budget) != 0 || budget.pending_method != 0 ||
        budget.observer_pending != 1u ||
        snprintf(program_paths[0],
            sizeof(program_paths[0]),
            "%s/reference/benchmark",
            build_directory) < 0 ||
        snprintf(program_paths[1],
            sizeof(program_paths[1]),
            "%s/reference/batch_benchmark",
            build_directory) < 0 ||
        snprintf(kernel_path, sizeof(kernel_path), "%s/reference/libmlkem.a", build_directory) <
            0 ||
        paired_digest_file(program_paths[0], executable_digests[0]) != 0 ||
        paired_digest_file(program_paths[1], executable_digests[1]) != 0 ||
        paired_digest_file(kernel_path, actual_kernel_digest) != 0 ||
        strcmp(actual_kernel_digest, budget.kernel_digest) != 0 ||
        mkdir(output_directory, 0700) != 0) {
        goto cleanup;
    }
    struct budget_ledger starting_budget = budget;
    char manifest_path[4096];
    char log_path[4096];
    if (paired_data_path(manifest_path, sizeof(manifest_path), output_directory, "cohort.csv") !=
            0 ||
        paired_data_path(log_path, sizeof(log_path), output_directory, "attempts.tsv") != 0) {
        goto cleanup;
    }
    manifest = fopen(manifest_path, "wx");
    attempt_log = fopen(log_path, "wx");
    if (manifest == NULL || attempt_log == NULL || fputs(PAIRED_COHORT_HEADER, manifest) == EOF ||
        fputs("block_id\tphase\tmethod\texit_status\twall_ns\tcharged_calls_upper\tstate\n",
            attempt_log) == EOF) {
        goto cleanup;
    }
    struct sigaction action = {0};
    action.sa_handler = deadline_handler;
    if (sigemptyset(&action.sa_mask) != 0 || sigaction(SIGALRM, &action, NULL) != 0) {
        goto cleanup;
    }
    for (size_t pair_index = 0; pair_index < pair_count; ++pair_index) {
        if (interruption_signal != 0) {
            goto partial;
        }
        char filenames[4][192];
        char data_paths[4][4096];
        char data_digests[6][65];
        uint64_t parent_wall[2] = {0};
        struct paired_run runs[2] = {0};
        for (unsigned method_position = 0; method_position < 2u; ++method_position) {
            unsigned method_index = method_position == 0 ? pairs[pair_index].first_method
                                                         : 1u - pairs[pair_index].first_method;
            const char *method = method_index == 0 ? "baseline" : "candidate";
            uint64_t planned_calls = 3u * pairs[pair_index].samples_per_category;
            uint64_t shared_calls = (budget.shared_calls_upper + 1u) / 2u;
            uint64_t current_calls = budget.development_calls[method_index] +
                budget.confirmation_calls[method_index] + budget.auxiliary_calls[method_index] +
                shared_calls;
            uint64_t wall_charged =
                budget.own_wall_nanoseconds[method_index] + budget.shared_wall_upper / 2u;
            uint64_t phase_calls = strcmp(phase, "confirmation") == 0
                ? budget.confirmation_calls[method_index]
                : budget.development_calls[method_index];
            uint64_t phase_limit = strcmp(phase, "confirmation") == 0 ? 120000u : 40000u;
            if (current_calls + planned_calls + 100u > 200000u ||
                phase_calls + planned_calls > phase_limit ||
                budget.auxiliary_calls[method_index] + shared_calls + planned_calls + 100u >
                    40000u ||
                wall_charged >= wall_limit) {
                fputs("budget exhausted before attempt\n", stderr);
                release_paired_run(&runs[0]);
                release_paired_run(&runs[1]);
                goto partial;
            }
            (void)snprintf(filenames[2u * method_index],
                sizeof(filenames[0]),
                "%.64s-%s.csv",
                pairs[pair_index].block_id,
                method);
            (void)snprintf(filenames[2u * method_index + 1u],
                sizeof(filenames[0]),
                "%.64s-%s.meta",
                pairs[pair_index].block_id,
                method);
            if (paired_data_path(data_paths[2u * method_index],
                    sizeof(data_paths[0]),
                    output_directory,
                    filenames[2u * method_index]) != 0 ||
                paired_data_path(data_paths[2u * method_index + 1u],
                    sizeof(data_paths[0]),
                    output_directory,
                    filenames[2u * method_index + 1u]) != 0) {
                release_paired_run(&runs[0]);
                release_paired_run(&runs[1]);
                goto partial;
            }
            uint64_t attempt_start;
            uint64_t attempt_finish;
            if (read_clock(&attempt_start) != 0) {
                release_paired_run(&runs[0]);
                release_paired_run(&runs[1]);
                goto partial;
            }
            uint64_t reserved_wall = wall_limit - wall_charged;
            budget.pending_method = method_index + 1u;
            budget.auxiliary_calls[method_index] += planned_calls + 100u;
            budget.own_wall_nanoseconds[method_index] += reserved_wall;
            if (write_budget(budget_path, &budget, 0) != 0) {
                release_paired_run(&runs[0]);
                release_paired_run(&runs[1]);
                goto partial;
            }
            char child_log_name[192];
            char child_log_path[4096];
            (void)snprintf(child_log_name,
                sizeof(child_log_name),
                "%.64s-%s.log",
                pairs[pair_index].block_id,
                method);
            int child_status = paired_data_path(child_log_path,
                                   sizeof(child_log_path),
                                   output_directory,
                                   child_log_name) != 0
                ? 125
                : execute_method(program_paths[method_index],
                      &pairs[pair_index],
                      method_index,
                      data_paths[2u * method_index],
                      data_paths[2u * method_index + 1u],
                      child_log_path,
                      reserved_wall);
            int data_valid = child_status == 0 &&
                load_paired_run(data_paths[2u * method_index],
                    data_paths[2u * method_index + 1u],
                    &runs[method_index]) == 0 &&
                strcmp(runs[method_index].executable_digest, executable_digests[method_index]) ==
                    0 &&
                strcmp(runs[method_index].source_commit, budget.source_commit) == 0 &&
                strcmp(runs[method_index].run_id, pairs[pair_index].block_id) == 0 &&
                runs[method_index].test_seed == pairs[pair_index].seed &&
                runs[method_index].call_count == planned_calls;
            char cost_path[4096];
            if (data_valid) {
                int cost_path_bytes = snprintf(cost_path,
                    sizeof(cost_path),
                    "%s.cost",
                    data_paths[2u * method_index]);
                data_valid = cost_path_bytes > 0 && (size_t)cost_path_bytes < sizeof(cost_path) &&
                    paired_digest_file(data_paths[2u * method_index],
                        data_digests[3u * method_index]) == 0 &&
                    paired_digest_file(data_paths[2u * method_index + 1u],
                        data_digests[3u * method_index + 1u]) == 0 &&
                    paired_digest_file(cost_path, data_digests[3u * method_index + 2u]) == 0 &&
                    sync_data_file(data_paths[2u * method_index]) == 0 &&
                    sync_data_file(data_paths[2u * method_index + 1u]) == 0 &&
                    sync_data_file(cost_path) == 0;
            }
            if (read_clock(&attempt_finish) != 0 || attempt_finish < attempt_start) {
                release_paired_run(&runs[0]);
                release_paired_run(&runs[1]);
                goto partial;
            }
            parent_wall[method_index] = attempt_finish - attempt_start;
            budget.own_wall_nanoseconds[method_index] -= reserved_wall;
            budget.own_wall_nanoseconds[method_index] += parent_wall[method_index];
            budget.pending_method = 0;
            if (data_valid) {
                budget.auxiliary_calls[method_index] -= planned_calls;
                if (strcmp(phase, "confirmation") == 0) {
                    budget.confirmation_calls[method_index] += planned_calls;
                } else {
                    budget.development_calls[method_index] += planned_calls;
                }
            }
            if (fprintf(attempt_log,
                    "%s\t%s\t%s\t%d\t%" PRIu64 "\t%" PRIu64 "\t%s\n",
                    pairs[pair_index].block_id,
                    phase,
                    method,
                    child_status,
                    parent_wall[method_index],
                    planned_calls + 100u,
                    data_valid ? "complete" : "failed_or_invalid") < 0 ||
                fflush(attempt_log) != 0 || write_budget(budget_path, &budget, 0) != 0 ||
                !data_valid || parent_wall[method_index] > reserved_wall) {
                release_paired_run(&runs[0]);
                release_paired_run(&runs[1]);
                goto partial;
            }
        }
        int pair_valid = validate_paired_runs(&runs[0], &runs[1]) == 0 &&
            runs[1].batch_size == pairs[pair_index].batch_size;
        release_paired_run(&runs[0]);
        release_paired_run(&runs[1]);
        if (!pair_valid ||
            fprintf(manifest,
                "%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%" PRIu64 ",%" PRIu64 "\n",
                pairs[pair_index].block_id,
                pairs[pair_index].first_method == 0 ? "baseline" : "candidate",
                filenames[0],
                filenames[1],
                filenames[2],
                filenames[3],
                data_digests[0],
                data_digests[1],
                data_digests[2],
                data_digests[3],
                data_digests[4],
                data_digests[5],
                parent_wall[0],
                parent_wall[1]) < 0 ||
            fflush(manifest) != 0) {
            goto partial;
        }
    }
    int manifest_sync_failed = fflush(manifest) != 0 || fsync(fileno(manifest)) != 0;
    if (fclose(manifest) != 0 || manifest_sync_failed) {
        manifest = NULL;
        goto cleanup;
    }
    manifest = NULL;
    int log_sync_failed = fflush(attempt_log) != 0 || fsync(fileno(attempt_log)) != 0;
    if (fclose(attempt_log) != 0 || log_sync_failed) {
        attempt_log = NULL;
        goto cleanup;
    }
    attempt_log = NULL;
    operation_status = write_context(output_directory,
        phase,
        pair_count,
        pairs[0].batch_size,
        &starting_budget,
        executable_digests[0],
        executable_digests[1],
        "pending_observer");
    goto cleanup;
partial:
    if (manifest != NULL && fflush(manifest) == 0) {
        (void)write_context(output_directory,
            phase,
            pair_count,
            pairs[0].batch_size,
            &starting_budget,
            executable_digests[0],
            executable_digests[1],
            "partial");
    }
cleanup:
    if (manifest != NULL) {
        (void)fclose(manifest);
    }
    if (attempt_log != NULL) {
        (void)fclose(attempt_log);
    }
    (void)close(lock_descriptor);
    if (operation_status != 0) {
        fputs("paired execution failed; retain partial files and budget reservations\n", stderr);
    }
    return operation_status;
}

static int close_observed_cohort(const char *directory,
    const char *budget_path,
    uint64_t envelope_nanoseconds,
    uint64_t wall_limit)
{
    static const char *const names[] = {"cohort_format",
        "phase",
        "expected_pairs",
        "shared_calls_upper",
        "shared_wall_lower_ns",
        "shared_wall_upper_ns",
        "prior_baseline_development_calls",
        "prior_candidate_development_calls",
        "prior_baseline_auxiliary_calls",
        "prior_candidate_auxiliary_calls",
        "prior_baseline_wall_ns",
        "prior_candidate_wall_ns",
        "platform_review",
        "dependency_review",
        "cost_closure",
        "source_commit",
        "baseline_executable_digest",
        "candidate_executable_digest",
        "cohort_manifest_digest",
        "selected_batch_size",
        "protocol_commit",
        "cohort_status"};
    char values[22][PAIRED_TEXT_CAPACITY];
    struct paired_text_field fields[22];
    char context_path[4096];
    char manifest_path[4096];
    char envelope_path[4096];
    if (paired_data_path(context_path, sizeof(context_path), directory, "cohort.meta") != 0 ||
        paired_data_path(manifest_path, sizeof(manifest_path), directory, "cohort.csv") != 0 ||
        paired_data_path(envelope_path, sizeof(envelope_path), directory, "cohort.envelope") != 0) {
        return 1;
    }
    for (size_t field_index = 0; field_index < 22u; ++field_index) {
        fields[field_index] = (struct paired_text_field){names[field_index],
            values[field_index],
            PAIRED_TEXT_CAPACITY,
            0};
    }
    if (read_paired_fields(context_path, fields, 22) != 0 ||
        strcmp(values[21], "pending_observer") != 0) {
        return 1;
    }
    FILE *manifest = fopen(manifest_path, "r");
    char line[4096];
    uint64_t method_wall_sum = 0;
    int operation_status = 0;
    if (manifest == NULL) {
        return 1;
    }
    if (fgets(line, sizeof(line), manifest) == NULL || strcmp(line, PAIRED_COHORT_HEADER) != 0) {
        operation_status = 1;
    }
    while (operation_status == 0 && fgets(line, sizeof(line), manifest) != NULL) {
        char *record_fields[14];
        uint64_t durations[2];
        if (split_paired_csv(line, record_fields, 14) != 0 ||
            parse_unsigned_integer(record_fields[12], &durations[0]) != 0 ||
            parse_unsigned_integer(record_fields[13], &durations[1]) != 0 ||
            durations[0] > METHOD_WALL_LIMIT_NS || durations[1] > METHOD_WALL_LIMIT_NS) {
            operation_status = 1;
        } else {
            method_wall_sum += durations[0] + durations[1];
        }
    }
    if (ferror(manifest)) {
        operation_status = 1;
    }
    if (fclose(manifest) != 0 || operation_status != 0 || method_wall_sum > envelope_nanoseconds) {
        return 1;
    }
    uint64_t runtime_overhead = envelope_nanoseconds - method_wall_sum;
    struct budget_ledger budget;
    uint64_t context_lower;
    uint64_t context_upper;
    if (read_budget(budget_path, &budget) != 0 || budget.pending_method != 0 ||
        budget.observer_pending != 1u || parse_unsigned_integer(values[4], &context_lower) != 0 ||
        parse_unsigned_integer(values[5], &context_upper) != 0 ||
        runtime_overhead > 2u * METHOD_WALL_LIMIT_NS - OBSERVER_REPORTING_UPPER_NS ||
        budget.shared_wall_upper >
            2u * METHOD_WALL_LIMIT_NS - runtime_overhead - OBSERVER_REPORTING_UPPER_NS) {
        return 1;
    }
    budget.shared_wall_lower += runtime_overhead;
    budget.shared_wall_upper += runtime_overhead + OBSERVER_REPORTING_UPPER_NS;
    if (strcmp(budget.cost_closure, "exact") == 0) {
        memcpy(budget.cost_closure, "bounded", 8);
    }
    for (size_t method_index = 0; method_index < 2u; ++method_index) {
        if (budget.own_wall_nanoseconds[method_index] + (budget.shared_wall_upper + 1u) / 2u >
            wall_limit) {
            return 1;
        }
    }
    if (write_budget(budget_path, &budget, 0) != 0) {
        return 1;
    }
    (void)snprintf(values[4], sizeof(values[4]), "%" PRIu64, context_lower + runtime_overhead);
    (void)snprintf(values[5],
        sizeof(values[5]),
        "%" PRIu64,
        context_upper + runtime_overhead + OBSERVER_REPORTING_UPPER_NS);
    if (strcmp(values[14], "exact") == 0) {
        memcpy(values[14], "bounded", 8);
    }
    memcpy(values[21], "complete", 9);
    char temporary_path[4096];
    int path_bytes = snprintf(temporary_path, sizeof(temporary_path), "%s.observed", context_path);
    if (path_bytes < 0 || (size_t)path_bytes >= sizeof(temporary_path)) {
        return 1;
    }
    FILE *context = fopen(temporary_path, "wx");
    if (context == NULL) {
        return 1;
    }
    for (size_t field_index = 0; field_index < 22u; ++field_index) {
        if (fprintf(context, "%s=%s\n", names[field_index], values[field_index]) < 0) {
            operation_status = 1;
        }
    }
    int context_sync_failed = fflush(context) != 0 || fsync(fileno(context)) != 0;
    if (fclose(context) != 0 || context_sync_failed) {
        operation_status = 1;
    }
    FILE *envelope = fopen(envelope_path, "wx");
    if (envelope == NULL) {
        return 1;
    }
    if (fprintf(envelope,
            "format=paired_execution_envelope_v1\nworker_wall_ns=%" PRIu64
            "\nmethod_wall_sum_ns=%" PRIu64 "\nshared_runtime_overhead_ns=%" PRIu64
            "\nboundary=observer_fork_before_to_worker_exit_after\n"
            "final_observer_accounting=common_reporting_bounded_with_deadline\nobserver_reporting_"
            "upper_ns=1000000000\n",
            envelope_nanoseconds,
            method_wall_sum,
            runtime_overhead) < 0) {
        operation_status = 1;
    }
    int envelope_sync_failed = fflush(envelope) != 0 || fsync(fileno(envelope)) != 0;
    if (fclose(envelope) != 0 || envelope_sync_failed || operation_status != 0 ||
        deadline_reached || interruption_signal != 0 || rename(temporary_path, context_path) != 0 ||
        sync_parent_directory(context_path) != 0 || deadline_reached || interruption_signal != 0) {
        return 1;
    }
    budget.observer_pending = 0;
    if (write_budget(budget_path, &budget, 0) != 0 || deadline_reached ||
        interruption_signal != 0) {
        budget.observer_pending = 1;
        (void)write_budget(budget_path, &budget, 0);
        return 1;
    }
    return 0;
}

static int observe_cohort(const char *phase,
    const char *plan_path,
    const char *build_directory,
    const char *output_directory,
    const char *budget_path,
    uint64_t wall_limit)
{
    char lock_path[4096];
    char audit_path[4096];
    int audit_path_bytes = snprintf(audit_path, sizeof(audit_path), "%s.audit", budget_path);
    if (audit_path_bytes < 0 || (size_t)audit_path_bytes >= sizeof(audit_path) ||
        access(audit_path, F_OK) == 0 || errno != ENOENT) {
        return 1;
    }
    int path_bytes = snprintf(lock_path, sizeof(lock_path), "%s.observer.lock", budget_path);
    if (path_bytes < 0 || (size_t)path_bytes >= sizeof(lock_path)) {
        return 1;
    }
    int lock_descriptor = open(lock_path, O_WRONLY | O_CREAT, 0600);
    struct flock lock = {0};
    lock.l_type = F_WRLCK;
    lock.l_whence = SEEK_SET;
    if (lock_descriptor < 0 || fcntl(lock_descriptor, F_SETLK, &lock) != 0) {
        if (lock_descriptor >= 0) {
            (void)close(lock_descriptor);
        }
        return 1;
    }
    if (access(audit_path, F_OK) == 0 || errno != ENOENT) {
        (void)close(lock_descriptor);
        return 1;
    }
    uint64_t start_nanoseconds;
    uint64_t finish_nanoseconds;
    struct planned_pair checked_pairs[20];
    size_t checked_pair_count;
    if (read_clock(&start_nanoseconds) != 0 ||
        read_plan(plan_path, phase, checked_pairs, &checked_pair_count) != 0) {
        (void)close(lock_descriptor);
        return 1;
    }
    struct budget_ledger observer_budget;
    if (read_budget(budget_path, &observer_budget) != 0 || observer_budget.observer_pending != 0 ||
        observer_budget.pending_method != 0) {
        (void)close(lock_descriptor);
        return 1;
    }
    if (strcmp(phase, "software_fixture") != 0) {
        char receipt_path[4096];
        char receipt_status[32];
        char receipt_source[41];
        struct paired_text_field receipt_fields[] = {
            {"preparation_status", receipt_status, sizeof(receipt_status), 0},
            {"source_commit", receipt_source, sizeof(receipt_source), 0}};
        path_bytes = snprintf(receipt_path, sizeof(receipt_path), "%s.preparation", budget_path);
        if (path_bytes < 0 || (size_t)path_bytes >= sizeof(receipt_path) ||
            read_paired_fields(receipt_path, receipt_fields, 2) != 0 ||
            strcmp(receipt_status, "complete") != 0 ||
            strcmp(receipt_source, observer_budget.source_commit) != 0) {
            fputs("completed preparation receipt is required before target execution\n", stderr);
            (void)close(lock_descriptor);
            return 2;
        }
    }
    struct budget_ledger before_worker = observer_budget;
    observer_budget.observer_pending = 1;
    if (write_budget(budget_path, &observer_budget, 0) != 0) {
        (void)close(lock_descriptor);
        return 1;
    }
    pid_t worker_process = fork();
    if (worker_process < 0) {
        (void)close(lock_descriptor);
        return 1;
    }
    if (worker_process == 0) {
        (void)close(lock_descriptor);
        _exit(run_cohort(phase,
            plan_path,
            build_directory,
            output_directory,
            budget_path,
            wall_limit));
    }
    active_worker_process = (sig_atomic_t)worker_process;
    if (interruption_signal != 0) {
        (void)kill(worker_process, SIGTERM);
    }
    int wait_status;
    while (waitpid(worker_process, &wait_status, 0) != worker_process) {
        if (errno != EINTR) {
            (void)close(lock_descriptor);
            return 1;
        }
    }
    active_worker_process = 0;
    int operation_status = WIFEXITED(wait_status) ? WEXITSTATUS(wait_status) : 128;
    if (interruption_signal != 0) {
        operation_status = 130;
    }
    if (operation_status != 0 && read_clock(&finish_nanoseconds) == 0 &&
        finish_nanoseconds >= start_nanoseconds) {
        struct budget_ledger failed_budget;
        if (read_budget(budget_path, &failed_budget) == 0 && failed_budget.pending_method == 0) {
            uint64_t recorded_methods = 0;
            for (size_t method_index = 0; method_index < 2u; ++method_index) {
                recorded_methods += failed_budget.own_wall_nanoseconds[method_index] -
                    before_worker.own_wall_nanoseconds[method_index];
            }
            uint64_t observed_wall = finish_nanoseconds - start_nanoseconds;
            if (recorded_methods <= observed_wall) {
                failed_budget.shared_wall_lower += observed_wall - recorded_methods;
                failed_budget.shared_wall_upper +=
                    observed_wall - recorded_methods + OBSERVER_REPORTING_UPPER_NS;
                if (strcmp(failed_budget.cost_closure, "exact") == 0) {
                    memcpy(failed_budget.cost_closure, "bounded", 8);
                }
                (void)write_budget(budget_path, &failed_budget, 0);
            }
        }
    }
    if (operation_status == 0) {
        if (read_clock(&finish_nanoseconds) != 0 || finish_nanoseconds < start_nanoseconds) {
            operation_status = 1;
        } else {
            struct sigaction action = {0};
            action.sa_handler = deadline_handler;
            struct itimerval timer = {0};
            timer.it_value.tv_sec = 1;
            deadline_reached = 0;
            if (sigemptyset(&action.sa_mask) != 0 || sigaction(SIGALRM, &action, NULL) != 0 ||
                setitimer(ITIMER_REAL, &timer, NULL) != 0) {
                (void)close(lock_descriptor);
                return 1;
            }
            operation_status = close_observed_cohort(output_directory,
                budget_path,
                finish_nanoseconds - start_nanoseconds,
                wall_limit);
            memset(&timer, 0, sizeof(timer));
            (void)setitimer(ITIMER_REAL, &timer, NULL);
            if (deadline_reached || interruption_signal != 0) {
                operation_status = 1;
            }
        }
    }
    if (operation_status != 0) {
        struct budget_ledger failed_budget;
        if (read_budget(budget_path, &failed_budget) == 0 && failed_budget.observer_pending == 0) {
            failed_budget.observer_pending = 1;
            (void)write_budget(budget_path, &failed_budget, 0);
        }
        char context_path[4096];
        char failed_path[4096];
        if (paired_data_path(context_path, sizeof(context_path), output_directory, "cohort.meta") ==
                0 &&
            paired_data_path(failed_path,
                sizeof(failed_path),
                output_directory,
                "cohort.meta.failed") == 0) {
            char state[32];
            struct paired_text_field field = {"cohort_status", state, sizeof(state), 0};
            if (read_paired_fields(context_path, &field, 1) == 0 && strcmp(state, "partial") != 0) {
                if (rename(context_path, failed_path) == 0) {
                    (void)sync_parent_directory(failed_path);
                }
            }
        }
    }
    (void)close(lock_descriptor);
    return operation_status;
}

int main(int argument_count, char **argument_values)
{
    struct sigaction interrupt_action = {0};
    interrupt_action.sa_handler = interruption_handler;
    if (sigemptyset(&interrupt_action.sa_mask) != 0 ||
        sigaction(SIGINT, &interrupt_action, NULL) != 0 ||
        sigaction(SIGTERM, &interrupt_action, NULL) != 0) {
        return 1;
    }
    if (argument_count == 4 && strcmp(argument_values[1], "init") == 0) {
        return initialize_budget(argument_values[2], argument_values[3]);
    }
    if ((argument_count == 7 || argument_count == 8) && strcmp(argument_values[1], "run") == 0 &&
        (strcmp(argument_values[2], "software_fixture") == 0 ||
            strcmp(argument_values[2], "development") == 0 ||
            strcmp(argument_values[2], "confirmation") == 0)) {
        uint64_t wall_limit = METHOD_WALL_LIMIT_NS;
        if (argument_count == 8 &&
            (strcmp(argument_values[2], "software_fixture") != 0 ||
                parse_unsigned_integer(argument_values[7], &wall_limit) != 0 || wall_limit == 0 ||
                wall_limit > METHOD_WALL_LIMIT_NS)) {
            return 2;
        }
        return observe_cohort(argument_values[2],
            argument_values[3],
            argument_values[4],
            argument_values[5],
            argument_values[6],
            wall_limit);
    }
    fputs("Usage: paired_runner init LEDGER SHARED_COST_FILE\n"
          "       paired_runner run PHASE PLAN_CSV BUILD_DIR NEW_OUTPUT_DIR LEDGER "
          "[FIXTURE_WALL_LIMIT_NS]\n",
        stderr);
    return 2;
}
