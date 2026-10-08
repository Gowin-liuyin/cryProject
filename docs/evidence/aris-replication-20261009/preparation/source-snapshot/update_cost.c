#define _POSIX_C_SOURCE 200809L

#include "update_cost.h"

#include <errno.h>
#include <inttypes.h>
#include <math.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/stat.h>
#include <sys/utsname.h>
#include <time.h>
#include <unistd.h>

#define TASK_COUNT 8u
#define REPEAT_COUNT 10u
#define CLOCK_SAMPLE_COUNT 256u
#define FILE_CAPACITY 8192u
#define PATH_CAPACITY 4096u
#define BUDGET_NS UINT64_C(30000000000)
#define EXPECTED_ASSIGNMENTS UINT64_C(1048576)

typedef int (*statistics_function)(const int64_t *, size_t, int, struct controlled_result *);

struct source_file {
    char path[PATH_CAPACITY];
    char bytes[FILE_CAPACITY];
    size_t byte_count;
};

struct fixed_task {
    struct source_file csv;
    struct source_file plan;
    struct source_file expectation;
    int64_t differences_ns[CONTROLLED_MAXIMUM_PAIRS];
    int64_t observed_sum;
    uint64_t expected_tail_count;
    uint64_t elapsed_ns[REPEAT_COUNT][2];
    size_t nonzero_pair_count;
};

struct run_context {
    FILE *raw_times;
    FILE *raw_clock;
    FILE *failures;
    FILE *input_records;
    uint64_t management_start_ns;
    uint64_t clock_resolution_ns;
    uint64_t checksum;
    uint64_t algorithm_window_total_ns;
    size_t consumed_results;
    size_t formal_count;
    size_t warmup_count;
    size_t clock_step_count;
    size_t empty_window_count;
    size_t task_number;
    size_t repeat_number;
    int output_created;
    long double minimum_window_ns;
    const char *phase;
    const char *method;
    const char *failure_reason;
};

static const uint64_t expected_tails[TASK_COUNT] = {UINT64_C(791138),
    UINT64_C(124),
    EXPECTED_ASSIGNMENTS,
    UINT64_C(811486),
    UINT64_C(203246),
    UINT64_C(62),
    EXPECTED_ASSIGNMENTS,
    UINT64_C(470724)};
static const char *const scenarios[TASK_COUNT] =
    {"null", "effect", "ties", "drift", "null", "effect", "ties", "drift"};
static const char *const method_names[2] = {"incremental", "naive"};
static const statistics_function methods[2] = {compute_incremental_controlled_result,
    compute_naive_controlled_result};

static int read_clock(uint64_t *nanoseconds)
{
    struct timespec instant;
    if (clock_gettime(CLOCK_MONOTONIC, &instant) != 0 || instant.tv_sec < 0 ||
        instant.tv_nsec < 0 || instant.tv_nsec >= 1000000000L ||
        (uint64_t)instant.tv_sec >
            (UINT64_MAX - (uint64_t)instant.tv_nsec) / UINT64_C(1000000000)) {
        return 1;
    }
    *nanoseconds = (uint64_t)instant.tv_sec * UINT64_C(1000000000) + (uint64_t)instant.tv_nsec;
    return 0;
}

static int budget_valid(struct run_context *context)
{
    uint64_t instant_ns;
    if (read_clock(&instant_ns) != 0 || instant_ns < context->management_start_ns) {
        context->failure_reason = "budget_clock_failed";
        return 0;
    }
    if (instant_ns - context->management_start_ns >= BUDGET_NS) {
        context->failure_reason = "management_budget_exhausted";
        return 0;
    }
    return 1;
}

static int make_path(char *path, const char *directory, const char *filename)
{
    int path_bytes = snprintf(path, PATH_CAPACITY, "%s/%s", directory, filename);
    return path_bytes < 0 || (size_t)path_bytes >= PATH_CAPACITY;
}

static int valid_path_argument(const char *path)
{
    return *path != '\0' && strpbrk(path, "\r\n\t") == NULL;
}

static int load_source(struct source_file *source, const char *directory, const char *filename)
{
    if (make_path(source->path, directory, filename) != 0) {
        return 1;
    }
    FILE *input_file = fopen(source->path, "rb");
    if (input_file == NULL) {
        return 1;
    }
    source->byte_count = fread(source->bytes, 1u, FILE_CAPACITY - 1u, input_file);
    int extra_byte = fgetc(input_file);
    int operation_status = ferror(input_file) || extra_byte != EOF || source->byte_count == 0 ||
        memchr(source->bytes, '\0', source->byte_count) != NULL ||
        source->bytes[source->byte_count - 1u] != '\n';
    source->bytes[source->byte_count] = '\0';
    if (fclose(input_file) != 0) {
        operation_status = 1;
    }
    return operation_status;
}

static int source_unchanged(const struct source_file *source)
{
    struct source_file current_source;
    FILE *input_file = fopen(source->path, "rb");
    if (input_file == NULL) {
        return 0;
    }
    current_source.byte_count = fread(current_source.bytes, 1u, FILE_CAPACITY, input_file);
    int operation_status = ferror(input_file) || current_source.byte_count != source->byte_count ||
        memcmp(current_source.bytes, source->bytes, source->byte_count) != 0 ||
        fgetc(input_file) != EOF || ferror(input_file);
    if (fclose(input_file) != 0) {
        operation_status = 1;
    }
    return !operation_status;
}

static int next_line(char **cursor, char **line)
{
    if (**cursor == '\0') {
        return 1;
    }
    *line = *cursor;
    char *line_end = strchr(*cursor, '\n');
    if (line_end == NULL) {
        return 1;
    }
    *line_end = '\0';
    *cursor = line_end + 1;
    return 0;
}

static int parse_uint64(const char *text, uint64_t *value)
{
    if (*text == '\0') {
        return 1;
    }
    uint64_t parsed_value = 0;
    for (const char *character = text; *character != '\0'; ++character) {
        if (*character < '0' || *character > '9') {
            return 1;
        }
        uint64_t digit = (uint64_t)(*character - '0');
        if (parsed_value > (UINT64_MAX - digit) / UINT64_C(10)) {
            return 1;
        }
        parsed_value = parsed_value * UINT64_C(10) + digit;
    }
    *value = parsed_value;
    return 0;
}

static int parse_csv(const char *source_bytes, size_t required_pairs, struct fixed_task *task)
{
    char working_bytes[FILE_CAPACITY];
    size_t byte_count = strlen(source_bytes);
    if (byte_count >= sizeof(working_bytes) || required_pairs > CONTROLLED_MAXIMUM_PAIRS) {
        return 1;
    }
    memcpy(working_bytes, source_bytes, byte_count + 1u);
    char *cursor = working_bytes;
    char *line;
    if (next_line(&cursor, &line) != 0 ||
        strcmp(line, "pair_index,first_total_ns,second_total_ns,call_count") != 0) {
        return 1;
    }
    task->observed_sum = 0;
    task->nonzero_pair_count = 0;
    for (size_t pair_index = 0; pair_index < required_pairs; ++pair_index) {
        if (next_line(&cursor, &line) != 0) {
            return 1;
        }
        char *fields[4];
        fields[0] = line;
        for (size_t field_index = 0; field_index < 4u; ++field_index) {
            char *separator = strchr(fields[field_index], ',');
            if ((field_index < 3u) != (separator != NULL)) {
                return 1;
            }
            if (separator != NULL) {
                *separator = '\0';
                fields[field_index + 1u] = separator + 1;
            }
        }
        uint64_t numbers[4];
        for (size_t field_index = 0; field_index < 4u; ++field_index) {
            if (parse_uint64(fields[field_index], &numbers[field_index]) != 0) {
                return 1;
            }
        }
        if (numbers[0] != pair_index || numbers[1] == 0 || numbers[2] == 0 ||
            numbers[1] > (uint64_t)CONTROLLED_MAXIMUM_DIFFERENCE_NS ||
            numbers[2] > (uint64_t)CONTROLLED_MAXIMUM_DIFFERENCE_NS || numbers[3] != 1u) {
            return 1;
        }
        task->differences_ns[pair_index] = (int64_t)numbers[1] - (int64_t)numbers[2];
        task->observed_sum += task->differences_ns[pair_index];
        if (task->differences_ns[pair_index] != 0) {
            ++task->nonzero_pair_count;
        }
    }
    return *cursor != '\0';
}

static int parse_fields(const char *source_bytes,
    const char *const *field_names,
    size_t field_count,
    char values[][128])
{
    char working_bytes[FILE_CAPACITY];
    size_t byte_count = strlen(source_bytes);
    if (byte_count >= sizeof(working_bytes)) {
        return 1;
    }
    memcpy(working_bytes, source_bytes, byte_count + 1u);
    char *cursor = working_bytes;
    for (size_t field_index = 0; field_index < field_count; ++field_index) {
        char *line;
        if (next_line(&cursor, &line) != 0) {
            return 1;
        }
        char *separator = strchr(line, '=');
        if (separator == NULL) {
            return 1;
        }
        *separator = '\0';
        size_t value_bytes = strlen(separator + 1);
        if (strcmp(line, field_names[field_index]) != 0 || value_bytes == 0 ||
            value_bytes >= 128u) {
            return 1;
        }
        memcpy(values[field_index], separator + 1, value_bytes + 1u);
    }
    return *cursor != '\0';
}

static int is_lower_hex_digest(const char *text)
{
    if (strlen(text) != 64u) {
        return 0;
    }
    for (size_t character_index = 0; character_index < 64u; ++character_index) {
        char character = text[character_index];
        if (!((character >= '0' && character <= '9') || (character >= 'a' && character <= 'f'))) {
            return 0;
        }
    }
    return 1;
}

static int parse_plan(const char *source_bytes, size_t task_index)
{
    static const char *const field_names[11] = {"format",
        "source_kind",
        "randomization",
        "no_carryover",
        "interval_iid",
        "data_digest",
        "source_csv_digest",
        "generator_seed",
        "scenario",
        "assignment_rule",
        "source_indices"};
    char values[11][128];
    uint64_t generator_seed;
    if (task_index >= TASK_COUNT || parse_fields(source_bytes, field_names, 11u, values) != 0 ||
        strcmp(values[0], "controlled_plan_v1") != 0 ||
        strcmp(values[1], "no_secret_synthetic") != 0 ||
        strcmp(values[2], "independent_label_swaps") != 0 || strcmp(values[3], "verified") != 0 ||
        strcmp(values[4], task_index % 4u == 3u ? "unverified" : "verified") != 0 ||
        !is_lower_hex_digest(values[5]) || strcmp(values[6], "none_synthetic") != 0 ||
        parse_uint64(values[7], &generator_seed) != 0 ||
        generator_seed != UINT64_C(202610071001) + (uint64_t)task_index ||
        strcmp(values[8], scenarios[task_index]) != 0 ||
        strcmp(values[9], "SplitMix64_low_bit_independent_pair_swap") != 0 ||
        strcmp(values[10], "none_synthetic") != 0) {
        return 1;
    }
    return 0;
}

static int parse_expectation(const char *source_bytes, size_t task_index, uint64_t *tail_count)
{
    static const char *const field_names[7] = {"format",
        "scipy_version",
        "numpy_version",
        "assignment_count",
        "tail_count",
        "p_value",
        "report_status"};
    char values[7][128];
    uint64_t assignment_count;
    if (task_index >= TASK_COUNT || parse_fields(source_bytes, field_names, 7u, values) != 0 ||
        strcmp(values[0], "scipy_exact_baseline_v1") != 0 || strcmp(values[1], "1.16.3") != 0 ||
        strcmp(values[2], "2.3.5") != 0 || parse_uint64(values[3], &assignment_count) != 0 ||
        assignment_count != EXPECTED_ASSIGNMENTS || parse_uint64(values[4], tail_count) != 0 ||
        *tail_count != expected_tails[task_index] || strcmp(values[6], "complete") != 0) {
        return 1;
    }
    char expected_p_value[128];
    int value_bytes = snprintf(expected_p_value,
        sizeof(expected_p_value),
        "%.15Lf",
        (long double)*tail_count / (long double)assignment_count);
    return value_bytes < 0 || (size_t)value_bytes >= sizeof(expected_p_value) ||
        strcmp(values[5], expected_p_value) != 0;
}

static int
save_source(const struct source_file *source, const char *output_directory, const char *filename)
{
    char output_path[PATH_CAPACITY];
    if (make_path(output_path, output_directory, filename) != 0) {
        return 1;
    }
    FILE *output_file = fopen(output_path, "wx");
    if (output_file == NULL) {
        return 1;
    }
    int operation_status =
        fwrite(source->bytes, 1u, source->byte_count, output_file) != source->byte_count;
    if (fclose(output_file) != 0) {
        operation_status = 1;
    }
    return operation_status;
}

static int load_tasks(const char *input_directory,
    const char *output_directory,
    struct fixed_task tasks[TASK_COUNT],
    struct run_context *context)
{
    char data_directory[PATH_CAPACITY];
    char expectation_directory[PATH_CAPACITY];
    char saved_directory[PATH_CAPACITY];
    if (make_path(data_directory, input_directory, "confirmation-data") != 0 ||
        make_path(expectation_directory, input_directory, "confirmation-results") != 0 ||
        make_path(saved_directory, output_directory, "inputs") != 0 ||
        mkdir(saved_directory, 0700) != 0) {
        context->failure_reason = "input_directory_setup_failed";
        return 1;
    }
    for (size_t task_index = 0; task_index < TASK_COUNT; ++task_index) {
        context->task_number = task_index + 1u;
        char filename[64];
        struct fixed_task *task = &tasks[task_index];
        (void)snprintf(filename, sizeof(filename), "task-%zu.csv", task_index + 1u);
        if (load_source(&task->csv, data_directory, filename) != 0 ||
            parse_csv(task->csv.bytes, CONTROLLED_MAXIMUM_PAIRS, task) != 0 ||
            save_source(&task->csv, saved_directory, filename) != 0) {
            context->failure_reason = "fixed_csv_load_or_preservation_failed";
            return 1;
        }
        (void)snprintf(filename, sizeof(filename), "task-%zu.plan", task_index + 1u);
        if (load_source(&task->plan, data_directory, filename) != 0 ||
            parse_plan(task->plan.bytes, task_index) != 0 ||
            save_source(&task->plan, saved_directory, filename) != 0) {
            context->failure_reason = "fixed_plan_load_or_preservation_failed";
            return 1;
        }
        (void)snprintf(filename, sizeof(filename), "task-%zu-r1-baseline.report", task_index + 1u);
        if (load_source(&task->expectation, expectation_directory, filename) != 0 ||
            parse_expectation(task->expectation.bytes, task_index, &task->expected_tail_count) !=
                0 ||
            save_source(&task->expectation, saved_directory, filename) != 0) {
            context->failure_reason = "archived_scipy_load_or_preservation_failed";
            return 1;
        }
        if (fprintf(context->input_records,
                "%zu\t%s\t%s\t%s\t%zu\t%" PRIu64 "\t%" PRIu64 "\n",
                task_index + 1u,
                task->csv.path,
                task->plan.path,
                task->expectation.path,
                task->nonzero_pair_count,
                task->expected_tail_count,
                EXPECTED_ASSIGNMENTS) < 0 ||
            fflush(context->input_records) != 0 || !budget_valid(context)) {
            if (context->failure_reason == NULL) {
                context->failure_reason = "input_records_write_failed";
            }
            return 1;
        }
    }
    if (tasks[2].csv.byte_count != tasks[6].csv.byte_count ||
        memcmp(tasks[2].csv.bytes, tasks[6].csv.bytes, tasks[2].csv.byte_count) != 0 ||
        tasks[2].nonzero_pair_count != 0 || tasks[6].nonzero_pair_count != 0) {
        context->failure_reason = "fixed_zero_vector_identity_failed";
        return 1;
    }
    return 0;
}

static int compare_nanoseconds(const void *first, const void *second)
{
    uint64_t first_ns = *(const uint64_t *)first;
    uint64_t second_ns = *(const uint64_t *)second;
    return first_ns < second_ns ? -1 : first_ns > second_ns ? 1 : 0;
}

static int calibrate_clock(struct run_context *context)
{
    struct timespec resolution;
    uint64_t steps_before[CLOCK_SAMPLE_COUNT];
    uint64_t steps_after[CLOCK_SAMPLE_COUNT];
    uint64_t empty_before[CLOCK_SAMPLE_COUNT];
    uint64_t empty_after[CLOCK_SAMPLE_COUNT];
    uint64_t sorted_empty[CLOCK_SAMPLE_COUNT];
    int calibration_status = 0;
    if (clock_getres(CLOCK_MONOTONIC, &resolution) != 0 || resolution.tv_sec < 0 ||
        resolution.tv_nsec < 0 || resolution.tv_nsec >= 1000000000L ||
        (uint64_t)resolution.tv_sec >
            (UINT64_MAX - (uint64_t)resolution.tv_nsec) / UINT64_C(1000000000)) {
        context->failure_reason = "clock_resolution_failed";
        return 1;
    }
    context->clock_resolution_ns =
        (uint64_t)resolution.tv_sec * UINT64_C(1000000000) + (uint64_t)resolution.tv_nsec;
    uint64_t previous_ns;
    if (read_clock(&previous_ns) != 0) {
        context->failure_reason = "clock_steps_failed";
        return 1;
    }
    for (size_t sample_index = 0; sample_index < CLOCK_SAMPLE_COUNT; ++sample_index) {
        uint64_t current_ns;
        if (read_clock(&current_ns) != 0 || current_ns < previous_ns) {
            context->failure_reason = "clock_steps_failed";
            calibration_status = 1;
            goto save_samples;
        }
        steps_before[sample_index] = previous_ns;
        steps_after[sample_index] = current_ns;
        previous_ns = current_ns;
        ++context->clock_step_count;
    }
    for (size_t sample_index = 0; sample_index < CLOCK_SAMPLE_COUNT; ++sample_index) {
        if (read_clock(&empty_before[sample_index]) != 0 ||
            read_clock(&empty_after[sample_index]) != 0 ||
            empty_after[sample_index] < empty_before[sample_index]) {
            context->failure_reason = "empty_window_clock_failed";
            calibration_status = 1;
            goto save_samples;
        }
        sorted_empty[sample_index] = empty_after[sample_index] - empty_before[sample_index];
        ++context->empty_window_count;
    }
    qsort(sorted_empty, CLOCK_SAMPLE_COUNT, sizeof(*sorted_empty), compare_nanoseconds);
    long double empty_median_ns = (long double)sorted_empty[CLOCK_SAMPLE_COUNT / 2u - 1u] / 2.0L +
        (long double)sorted_empty[CLOCK_SAMPLE_COUNT / 2u] / 2.0L;
    context->minimum_window_ns =
        100.0L * fmaxl((long double)context->clock_resolution_ns, empty_median_ns);
save_samples:
    for (size_t sample_index = 0; sample_index < context->clock_step_count; ++sample_index) {
        if (fprintf(context->raw_clock,
                "step,%zu,%" PRIu64 ",%" PRIu64 ",%" PRIu64 "\n",
                sample_index,
                steps_before[sample_index],
                steps_after[sample_index],
                steps_after[sample_index] - steps_before[sample_index]) < 0) {
            context->failure_reason = "raw_clock_write_failed";
            return 1;
        }
    }
    for (size_t sample_index = 0; sample_index < context->empty_window_count; ++sample_index) {
        if (fprintf(context->raw_clock,
                "empty,%zu,%" PRIu64 ",%" PRIu64 ",%" PRIu64 "\n",
                sample_index,
                empty_before[sample_index],
                empty_after[sample_index],
                empty_after[sample_index] - empty_before[sample_index]) < 0) {
            context->failure_reason = "raw_clock_write_failed";
            return 1;
        }
    }
    if (fflush(context->raw_clock) != 0) {
        context->failure_reason = "raw_clock_flush_failed";
        return 1;
    }
    return calibration_status || !budget_valid(context);
}

static int result_valid(const struct controlled_result *result,
    const struct fixed_task *task,
    size_t pair_count)
{
    return result->assignment_count == (UINT64_C(1) << pair_count) &&
        result->tail_count == task->expected_tail_count &&
        result->mean_difference_ns == (long double)task->observed_sum / (long double)pair_count &&
        result->exact_p_value ==
        (long double)task->expected_tail_count / (long double)result->assignment_count &&
        result->has_variation == (task->nonzero_pair_count != 0) &&
        result->interval_lower_ns == 0.0L && result->interval_upper_ns == 0.0L;
}

static int run_method(struct fixed_task *task,
    size_t method_index,
    size_t order_index,
    int is_formal,
    struct run_context *context)
{
    context->method = method_names[method_index];
    if (!budget_valid(context)) {
        return 1;
    }
    statistics_function selected_function = methods[method_index];
    struct controlled_result result = {0};
    uint64_t start_ns = 0;
    uint64_t finish_ns = 0;
    uint64_t elapsed_ns = 0;
    int has_start = !is_formal;
    int has_finish = !is_formal;
    int has_valid_window = !is_formal;
    int statistics_status = -1;
    int has_valid_result = 0;
    int is_valid = 0;
    if (is_formal) {
        if (read_clock(&start_ns) != 0) {
            context->failure_reason = "function_start_clock_failed";
            goto record_outcome;
        }
        has_start = 1;
        statistics_status =
            selected_function(task->differences_ns, CONTROLLED_MAXIMUM_PAIRS, 0, &result);
        if (read_clock(&finish_ns) != 0) {
            context->failure_reason = "function_finish_clock_failed";
            goto record_outcome;
        }
        has_finish = 1;
        if (finish_ns < start_ns) {
            context->failure_reason = "function_clock_moved_backwards";
            goto record_outcome;
        }
        has_valid_window = 1;
        elapsed_ns = finish_ns - start_ns;
    } else {
        statistics_status =
            selected_function(task->differences_ns, CONTROLLED_MAXIMUM_PAIRS, 0, &result);
    }
record_outcome:
    has_valid_result =
        statistics_status == 0 && result_valid(&result, task, CONTROLLED_MAXIMUM_PAIRS);
    is_valid = has_valid_result && has_valid_window;
    if (is_valid) {
        context->checksum = (context->checksum ^ result.tail_count) + result.assignment_count +
            (uint64_t)result.has_variation;
        ++context->consumed_results;
        if (is_formal) {
            ++context->formal_count;
            context->algorithm_window_total_ns += elapsed_ns;
            task->elapsed_ns[context->repeat_number - 1u][method_index] = elapsed_ns;
        } else {
            ++context->warmup_count;
        }
    } else if (context->failure_reason == NULL) {
        context->failure_reason = "statistics_or_archived_count_mismatch";
    }
    char start_text[32] = "unavailable";
    char finish_text[32] = "unavailable";
    char elapsed_text[32] = "unavailable";
    if (has_start) {
        (void)snprintf(start_text, sizeof(start_text), "%" PRIu64, start_ns);
    }
    if (has_finish) {
        (void)snprintf(finish_text, sizeof(finish_text), "%" PRIu64, finish_ns);
    }
    if (has_valid_window) {
        (void)snprintf(elapsed_text, sizeof(elapsed_text), "%" PRIu64, elapsed_ns);
    }
    const char *clock_qualification = !is_formal                ? "not_timed"
        : !has_valid_window                                     ? "unavailable"
        : (long double)elapsed_ns >= context->minimum_window_ns ? "yes"
                                                                : "no";
    if (fprintf(context->raw_times,
            "%s,%zu,%zu,%zu,%s,%s,%s,%s,%d,%" PRIu64 ",%" PRIu64 ",%.9Lf,%.15Lf,%d,%s,%s,%zu,%s\n",
            is_formal ? "formal" : "warmup",
            context->task_number,
            context->repeat_number,
            order_index + 1u,
            context->method,
            start_text,
            finish_text,
            elapsed_text,
            statistics_status,
            result.assignment_count,
            result.tail_count,
            result.mean_difference_ns,
            result.exact_p_value,
            result.has_variation,
            clock_qualification,
            task->nonzero_pair_count == 0 ? "zero_vector_no_per_state_claim"
                                          : "nonzero_requires_artifact_review",
            context->consumed_results,
            is_valid ? "count_checked_and_consumed" : context->failure_reason) < 0 ||
        fflush(context->raw_times) != 0) {
        context->failure_reason = "raw_times_write_failed";
        return 1;
    }
    return !is_valid || !budget_valid(context);
}

static int execute_tasks(struct fixed_task tasks[TASK_COUNT], struct run_context *context)
{
    for (size_t task_index = 0; task_index < TASK_COUNT; ++task_index) {
        context->task_number = task_index + 1u;
        context->repeat_number = 0;
        context->phase = "warmup";
        for (size_t method_index = 0; method_index < 2u; ++method_index) {
            if (run_method(&tasks[task_index], method_index, method_index, 0, context) != 0) {
                return 1;
            }
        }
        context->phase = "formal";
        for (size_t repeat_index = 0; repeat_index < REPEAT_COUNT; ++repeat_index) {
            context->repeat_number = repeat_index + 1u;
            for (size_t order_index = 0; order_index < 2u; ++order_index) {
                size_t method_index = (repeat_index + order_index) % 2u;
                if (run_method(&tasks[task_index], method_index, order_index, 1, context) != 0) {
                    return 1;
                }
            }
        }
    }
    return 0;
}

static int compare_ratios(const void *first, const void *second)
{
    long double first_ratio = *(const long double *)first;
    long double second_ratio = *(const long double *)second;
    return first_ratio < second_ratio ? -1 : first_ratio > second_ratio ? 1 : 0;
}

static int save_pairs(const char *output_directory,
    const struct fixed_task tasks[TASK_COUNT],
    struct run_context *context)
{
    char pairs_path[PATH_CAPACITY];
    char summary_path[PATH_CAPACITY];
    if (make_path(pairs_path, output_directory, "pairs.csv") != 0 ||
        make_path(summary_path, output_directory, "summary.csv") != 0) {
        context->failure_reason = "summary_path_failed";
        return 1;
    }
    FILE *pairs_file = fopen(pairs_path, "wx");
    FILE *summary_file = fopen(summary_path, "wx");
    int operation_status = pairs_file == NULL || summary_file == NULL;
    if (operation_status) {
        goto cleanup;
    }
    operation_status =
        fputs("task,repeat,first_method,incremental_ns,naive_ns,incremental_to_naive_ratio,"
              "both_clock_qualified,mechanism_scope\n",
            pairs_file) == EOF ||
        fputs("task,nonzero_pair_count,repeat_pairs,ratio_median,ratio_minimum,ratio_maximum,"
              "clock_qualified_pairs,mechanism_scope\n",
            summary_file) == EOF;
    for (size_t task_index = 0; task_index < TASK_COUNT && !operation_status; ++task_index) {
        const struct fixed_task *task = &tasks[task_index];
        long double ratios[REPEAT_COUNT];
        size_t qualified_pairs = 0;
        const char *scope = task->nonzero_pair_count == 0 ? "zero_vector_no_per_state_claim"
                                                          : "nonzero_requires_artifact_review";
        for (size_t repeat_index = 0; repeat_index < REPEAT_COUNT; ++repeat_index) {
            uint64_t incremental_ns = task->elapsed_ns[repeat_index][0];
            uint64_t naive_ns = task->elapsed_ns[repeat_index][1];
            if (naive_ns == 0) {
                operation_status = 1;
                break;
            }
            ratios[repeat_index] = (long double)incremental_ns / (long double)naive_ns;
            int is_qualified = (long double)incremental_ns >= context->minimum_window_ns &&
                (long double)naive_ns >= context->minimum_window_ns;
            qualified_pairs += (size_t)is_qualified;
            if (fprintf(pairs_file,
                    "%zu,%zu,%s,%" PRIu64 ",%" PRIu64 ",%.12Lf,%s,%s\n",
                    task_index + 1u,
                    repeat_index + 1u,
                    method_names[repeat_index % 2u],
                    incremental_ns,
                    naive_ns,
                    ratios[repeat_index],
                    is_qualified ? "yes" : "no",
                    scope) < 0) {
                operation_status = 1;
                break;
            }
        }
        if (operation_status) {
            break;
        }
        qsort(ratios, REPEAT_COUNT, sizeof(*ratios), compare_ratios);
        if (fprintf(summary_file,
                "%zu,%zu,%u,%.12Lf,%.12Lf,%.12Lf,%zu,%s\n",
                task_index + 1u,
                task->nonzero_pair_count,
                REPEAT_COUNT,
                ratios[REPEAT_COUNT / 2u - 1u] / 2.0L + ratios[REPEAT_COUNT / 2u] / 2.0L,
                ratios[0],
                ratios[REPEAT_COUNT - 1u],
                qualified_pairs,
                scope) < 0) {
            operation_status = 1;
        }
    }
cleanup:
    if (pairs_file != NULL && fclose(pairs_file) != 0) {
        operation_status = 1;
    }
    if (summary_file != NULL && fclose(summary_file) != 0) {
        operation_status = 1;
    }
    if (operation_status) {
        context->failure_reason = "pairs_or_summary_write_failed";
    }
    return operation_status || !budget_valid(context);
}

static int close_output(FILE **output_file)
{
    if (*output_file == NULL) {
        return 0;
    }
    int operation_status = fclose(*output_file) != 0;
    *output_file = NULL;
    return operation_status;
}

static int initialize_output(const char *output_directory, struct run_context *context)
{
    if (mkdir(output_directory, 0700) != 0) {
        context->failure_reason = "exclusive_output_directory_failed";
        return 1;
    }
    context->output_created = 1;
    char path[PATH_CAPACITY];
    if (make_path(path, output_directory, "failures.csv") != 0 ||
        (context->failures = fopen(path, "wx")) == NULL ||
        fputs("phase,task,repeat,method,reason\n", context->failures) == EOF ||
        make_path(path, output_directory, "raw-times.csv") != 0 ||
        (context->raw_times = fopen(path, "wx")) == NULL ||
        fputs("phase,task,repeat,order,method,start_ns,finish_ns,elapsed_ns,function_status,"
              "assignment_count,tail_count,mean_difference_ns,exact_p_value,has_variation,"
              "window_clock_qualified,mechanism_scope,consumed_results,status\n",
            context->raw_times) == EOF ||
        make_path(path, output_directory, "raw-clock.csv") != 0 ||
        (context->raw_clock = fopen(path, "wx")) == NULL ||
        fputs("kind,sample,start_ns,finish_ns,elapsed_ns\n", context->raw_clock) == EOF ||
        make_path(path, output_directory, "input-records.tsv") != 0 ||
        (context->input_records = fopen(path, "wx")) == NULL ||
        fputs("task\tcsv_path\tplan_path\texpectation_path\tnonzero_pair_count\ttail_count\t"
              "assignment_count\n",
            context->input_records) == EOF) {
        context->failure_reason = "exclusive_output_open_failed";
        return 1;
    }
    if (make_path(path, output_directory, "initial-state.meta") != 0) {
        context->failure_reason = "initial_state_path_failed";
        return 1;
    }
    FILE *initial_state = fopen(path, "wx");
    if (initial_state == NULL) {
        context->failure_reason = "initial_state_open_failed";
        return 1;
    }
    int operation_status =
        fprintf(initial_state,
            "format=update_cost_v1\ninitial_state=started\nmanagement_start_ns=%" PRIu64
            "\nbudget_ns=%" PRIu64 "\nclock=CLOCK_MONOTONIC\ntime_unit=ns\n",
            context->management_start_ns,
            BUDGET_NS) < 0;
    if (fclose(initial_state) != 0) {
        operation_status = 1;
    }
    if (operation_status) {
        context->failure_reason = "initial_state_write_failed";
    }
    return operation_status;
}

static int publish_state(const char *output_directory,
    uint64_t management_finish_ns,
    int operation_status,
    const struct run_context *context)
{
    char path[PATH_CAPACITY];
    char published_path[PATH_CAPACITY];
    uint64_t publication_start_ns;
    if (make_path(path, output_directory, "final-state.pending") != 0 ||
        make_path(published_path, output_directory, "final-state.meta") != 0 ||
        read_clock(&publication_start_ns) != 0) {
        return 1;
    }
    FILE *state_file = fopen(path, "wx");
    if (state_file == NULL) {
        return 1;
    }
    struct utsname machine;
    int has_machine_identity = uname(&machine) == 0;
    int publication_status =
        fprintf(state_file,
            "format=update_cost_v1\nfinal_state=%s\nfailure_reason=%s\n"
            "clock=CLOCK_MONOTONIC\ntime_unit=ns\nclock_resolution_ns=%" PRIu64
            "\nminimum_algorithm_window_ns=%.3Lf\nmanagement_start_ns=%" PRIu64
            "\nmanagement_finish_ns=%" PRIu64 "\nmanagement_elapsed_ns=%" PRIu64
            "\nbudget_ns=%" PRIu64 "\nalgorithm_window_total_ns=%" PRIu64
            "\nclock_step_count=%zu\nempty_window_count=%zu\nwarmup_count=%zu\nformal_count=%"
            "zu\nconsumed_results=%zu\nchecksum=%" PRIu64
            "\ncompute_interval=0\nrepeat_pairs_per_task=10\n"
            "input_byte_comparison=%s\ninput_digest_validation=external_preflight_and_postflight\n"
            "binary_digest_validation=external_preflight\nartifact_mechanism_review=pending_"
            "external\n"
            "management_excludes=final_state_publication_external_hashing_process_tail\n"
            "function_window_excludes=loading_allocation_result_checks_consumption_logging_io\n"
            "function_window_includes=full_statistics_entry_validation_initialization_enumeration_"
            "result\n"
            "platform=%s\nrelease=%s\narchitecture=%s\nsanitizers=%s\nlto=disabled\n"
            "publication_start_ns=%" PRIu64 "\n",
            operation_status == 0 ? "complete" : "partial",
            context->failure_reason == NULL ? "none" : context->failure_reason,
            context->clock_resolution_ns,
            context->minimum_window_ns,
            context->management_start_ns,
            management_finish_ns,
            management_finish_ns >= context->management_start_ns
                ? management_finish_ns - context->management_start_ns
                : 0,
            BUDGET_NS,
            context->algorithm_window_total_ns,
            context->clock_step_count,
            context->empty_window_count,
            context->warmup_count,
            context->formal_count,
            context->consumed_results,
            context->checksum,
            operation_status == 0 ? "all_24_files_identical" : "not_completed",
            has_machine_identity ? machine.sysname : "unavailable",
            has_machine_identity ? machine.release : "unavailable",
            has_machine_identity ? machine.machine : "unavailable",
            UPDATE_COST_SANITIZERS ? "enabled" : "disabled",
            publication_start_ns) < 0;
    if (fflush(state_file) != 0) {
        publication_status = 1;
    }
    uint64_t publication_content_flushed_ns;
    if (read_clock(&publication_content_flushed_ns) != 0 ||
        publication_content_flushed_ns < publication_start_ns ||
        fprintf(state_file,
            "publication_content_flushed_ns=%" PRIu64 "\npublication_content_elapsed_ns=%" PRIu64
            "\npublication_boundary=through_first_content_flush_excludes_boundary_record_close_"
            "atomic_link\n",
            publication_content_flushed_ns,
            publication_content_flushed_ns - publication_start_ns) < 0) {
        publication_status = 1;
    }
    if (fclose(state_file) != 0) {
        publication_status = 1;
    }
    if (publication_status == 0 && link(path, published_path) != 0) {
        publication_status = 1;
    }
    return publication_status;
}

static int selfcheck(void)
{
    static const int64_t differences[6][4] = {{1, 1, 1, 1},
        {1, -1, 1, -1},
        {1, 1, 0, 0},
        {1, 2, 3, 4},
        {0, 0, 0, 0},
        {-CONTROLLED_MAXIMUM_DIFFERENCE_NS,
            -CONTROLLED_MAXIMUM_DIFFERENCE_NS,
            -CONTROLLED_MAXIMUM_DIFFERENCE_NS,
            -CONTROLLED_MAXIMUM_DIFFERENCE_NS}};
    static const uint64_t hand_counts[6] = {2u, 16u, 8u, 2u, 16u, 2u};
    for (size_t case_index = 0; case_index < 6u; ++case_index) {
        struct fixed_task task = {0};
        memcpy(task.differences_ns, differences[case_index], sizeof(differences[case_index]));
        task.expected_tail_count = hand_counts[case_index];
        for (size_t pair_index = 0; pair_index < 4u; ++pair_index) {
            task.observed_sum += task.differences_ns[pair_index];
            task.nonzero_pair_count += (size_t)(task.differences_ns[pair_index] != 0);
        }
        for (size_t method_index = 0; method_index < 2u; ++method_index) {
            struct controlled_result result;
            if (methods[method_index](task.differences_ns, 4u, 0, &result) != 0 ||
                !result_valid(&result, &task, 4u)) {
                fprintf(stderr,
                    "Hand-count selfcheck failed: case=%zu method=%s\n",
                    case_index,
                    method_names[method_index]);
                return 1;
            }
        }
    }
    int64_t boundary_differences[CONTROLLED_MAXIMUM_PAIRS + 1u] = {1, 1, 1, 1};
    for (size_t method_index = 0; method_index < 2u; ++method_index) {
        struct controlled_result result;
        statistics_function selected_function = methods[method_index];
        if (selected_function(NULL, 4u, 0, &result) == 0 ||
            selected_function(boundary_differences, 4u, 0, NULL) == 0 ||
            selected_function(boundary_differences, 3u, 0, &result) == 0 ||
            selected_function(boundary_differences, CONTROLLED_MAXIMUM_PAIRS + 1u, 0, &result) ==
                0) {
            fputs("Interface boundary selfcheck failed\n", stderr);
            return 1;
        }
        boundary_differences[0] = CONTROLLED_MAXIMUM_DIFFERENCE_NS + 1;
        if (selected_function(boundary_differences, 4u, 0, &result) == 0) {
            fputs("Positive integer boundary selfcheck failed\n", stderr);
            return 1;
        }
        boundary_differences[0] = -CONTROLLED_MAXIMUM_DIFFERENCE_NS - 1;
        if (selected_function(boundary_differences, 4u, 0, &result) == 0) {
            fputs("Negative integer boundary selfcheck failed\n", stderr);
            return 1;
        }
        boundary_differences[0] = 1;
    }
    struct fixed_task parser_task = {0};
    static const char valid_csv[] = "pair_index,first_total_ns,second_total_ns,call_count\n"
                                    "0,2,1,1\n1,2,1,1\n2,1,1,1\n3,1,1,1\n";
    static const char invalid_csv[] = "pair_index,first_total_ns,second_total_ns,call_count\n"
                                      "0,2,1,1\n1,2,1,1\n2,1,1,1\n3,1,1,1\n4,1,1,1\n";
    uint64_t parsed_value;
    if (parse_csv(valid_csv, 4u, &parser_task) != 0 || parser_task.observed_sum != 2 ||
        parser_task.nonzero_pair_count != 2u || parse_csv(invalid_csv, 4u, &parser_task) == 0 ||
        parse_csv(valid_csv, 20u, &parser_task) == 0 ||
        parse_uint64("18446744073709551616", &parsed_value) == 0 ||
        parse_uint64("-1", &parsed_value) == 0 || parse_uint64("1 ", &parsed_value) == 0 ||
        parse_uint64("18446744073709551615", &parsed_value) != 0 || parsed_value != UINT64_MAX) {
        fputs("Strict parser selfcheck failed\n", stderr);
        return 1;
    }
    puts("selfcheck=passed hand_cases=6 methods=2 interface_bounds=checked parser_bounds=checked");
    return 0;
}

static int selfcheck_inputs(const char *input_directory)
{
    char data_directory[PATH_CAPACITY];
    char expectation_directory[PATH_CAPACITY];
    struct fixed_task tasks[TASK_COUNT] = {0};
    if (make_path(data_directory, input_directory, "confirmation-data") != 0 ||
        make_path(expectation_directory, input_directory, "confirmation-results") != 0) {
        return 1;
    }
    for (size_t task_index = 0; task_index < TASK_COUNT; ++task_index) {
        char filename[64];
        struct fixed_task *task = &tasks[task_index];
        (void)snprintf(filename, sizeof(filename), "task-%zu.csv", task_index + 1u);
        if (load_source(&task->csv, data_directory, filename) != 0 ||
            parse_csv(task->csv.bytes, CONTROLLED_MAXIMUM_PAIRS, task) != 0) {
            return 1;
        }
        (void)snprintf(filename, sizeof(filename), "task-%zu.plan", task_index + 1u);
        if (load_source(&task->plan, data_directory, filename) != 0 ||
            parse_plan(task->plan.bytes, task_index) != 0) {
            return 1;
        }
        (void)snprintf(filename, sizeof(filename), "task-%zu-r1-baseline.report", task_index + 1u);
        if (load_source(&task->expectation, expectation_directory, filename) != 0 ||
            parse_expectation(task->expectation.bytes, task_index, &task->expected_tail_count) !=
                0 ||
            parse_expectation(task->expectation.bytes,
                (task_index + 1u) % TASK_COUNT,
                &task->expected_tail_count) == 0 ||
            parse_plan(task->plan.bytes, (task_index + 1u) % TASK_COUNT) == 0 ||
            !source_unchanged(&task->csv) || !source_unchanged(&task->plan) ||
            !source_unchanged(&task->expectation)) {
            return 1;
        }
    }
    if (tasks[2].csv.byte_count != tasks[6].csv.byte_count ||
        memcmp(tasks[2].csv.bytes, tasks[6].csv.bytes, tasks[2].csv.byte_count) != 0 ||
        tasks[2].nonzero_pair_count != 0 || tasks[6].nonzero_pair_count != 0) {
        return 1;
    }
    puts("input_selfcheck=passed archived_files=24 wrong_task_rejections=16 input_bytes=unchanged");
    return 0;
}

int main(int argument_count, char **argument_values)
{
    struct run_context context = {0};
    context.phase = "entry";
    context.method = "none";
    if (read_clock(&context.management_start_ns) != 0) {
        fputs("Entry CLOCK_MONOTONIC failed\n", stderr);
        return 1;
    }
    if (argument_count == 2 && strcmp(argument_values[1], "--selftest") == 0) {
        return selfcheck();
    }
    if (argument_count == 3 && strcmp(argument_values[1], "--check-inputs") == 0 &&
        valid_path_argument(argument_values[2])) {
        return selfcheck_inputs(argument_values[2]);
    }
    if (argument_count != 3 || !valid_path_argument(argument_values[1]) ||
        !valid_path_argument(argument_values[2])) {
        fputs("Usage: update_cost INPUT_EVIDENCE_ROOT NEW_OUTPUT_DIRECTORY\n"
              "       update_cost --selftest\n",
            stderr);
        return 2;
    }
    if (UPDATE_COST_SANITIZERS) {
        fputs("Sanitizer build permits --selftest only\n", stderr);
        return 2;
    }
    struct fixed_task tasks[TASK_COUNT] = {0};
    int operation_status = initialize_output(argument_values[2], &context);
    if (operation_status == 0) {
        context.phase = "loading";
        operation_status = load_tasks(argument_values[1], argument_values[2], tasks, &context);
    }
    if (operation_status == 0) {
        context.phase = "clock_calibration";
        context.task_number = 0;
        operation_status = calibrate_clock(&context);
    }
    if (operation_status == 0) {
        operation_status = execute_tasks(tasks, &context);
    }
    if (operation_status == 0 &&
        (context.warmup_count != 2u * TASK_COUNT ||
            context.formal_count != 2u * REPEAT_COUNT * TASK_COUNT ||
            context.consumed_results != 2u * (REPEAT_COUNT + 1u) * TASK_COUNT)) {
        context.failure_reason = "completed_and_consumed_call_count_mismatch";
        operation_status = 1;
    }
    if (operation_status == 0) {
        context.phase = "input_recheck";
        context.method = "none";
        context.repeat_number = 0;
        for (size_t task_index = 0; task_index < TASK_COUNT; ++task_index) {
            context.task_number = task_index + 1u;
            if (!source_unchanged(&tasks[task_index].csv) ||
                !source_unchanged(&tasks[task_index].plan) ||
                !source_unchanged(&tasks[task_index].expectation)) {
                context.failure_reason = "input_bytes_changed";
                operation_status = 1;
                break;
            }
            if (!budget_valid(&context)) {
                operation_status = 1;
                break;
            }
        }
    }
    if (operation_status == 0) {
        context.phase = "raw_summary";
        operation_status = save_pairs(argument_values[2], tasks, &context);
    }
    if (operation_status != 0 && context.failures != NULL) {
        if (fprintf(context.failures,
                "%s,%zu,%zu,%s,%s\n",
                context.phase,
                context.task_number,
                context.repeat_number,
                context.method,
                context.failure_reason == NULL ? "unspecified_failure" : context.failure_reason) <
                0 ||
            fflush(context.failures) != 0) {
            fputs("Failure record write failed\n", stderr);
        }
    }
    int close_status = close_output(&context.raw_times);
    close_status |= close_output(&context.raw_clock);
    close_status |= close_output(&context.input_records);
    close_status |= close_output(&context.failures);
    if (close_status != 0) {
        context.failure_reason = "raw_output_close_failed";
        operation_status = 1;
    }
    uint64_t management_finish_ns = 0;
    if (read_clock(&management_finish_ns) != 0 ||
        management_finish_ns < context.management_start_ns) {
        context.failure_reason = "management_finish_clock_failed";
        operation_status = 1;
    } else if (management_finish_ns - context.management_start_ns >= BUDGET_NS) {
        context.failure_reason = "management_budget_exhausted";
        operation_status = 1;
    }
    if (context.output_created &&
        publish_state(argument_values[2], management_finish_ns, operation_status, &context) != 0) {
        fputs("Final state publication failed\n", stderr);
        operation_status = 1;
    }
    if (operation_status != 0) {
        fprintf(stderr,
            "Update-cost execution stopped: %s\n",
            context.failure_reason == NULL ? "publication_failed" : context.failure_reason);
    }
    return operation_status;
}
