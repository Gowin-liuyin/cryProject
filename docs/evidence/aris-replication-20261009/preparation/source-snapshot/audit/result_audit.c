#include <inttypes.h>
#include <math.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#define TASK_COUNT 8u
#define REPEAT_COUNT 10u
#define PAIR_COUNT 20u
#define CLOCK_COUNT 256u
#define LINE_CAPACITY 4096u
#define PATH_CAPACITY 4096u
#define REQUIRE(condition) require_fact((condition), #condition, __LINE__)

struct audit_task {
    int64_t observed_sum;
    size_t nonzero_count;
    uint64_t elapsed_ns[REPEAT_COUNT][2];
    long double ratios[REPEAT_COUNT];
    long double ratio_median;
    long double ratio_minimum;
    long double ratio_maximum;
};

struct metadata_field {
    char name[128];
    char value[1024];
};

struct metadata {
    struct metadata_field fields[64];
    size_t count;
};

static const uint64_t expected_tails[TASK_COUNT] =
    {791138u, 124u, 1048576u, 811486u, 203246u, 62u, 1048576u, 470724u};
static const char *const method_names[2] = {"incremental", "naive"};
static const uint64_t assignment_count = UINT64_C(1048576);

static void require_fact(int condition, const char *description, int line_number)
{
    if (!condition) {
        fprintf(stderr, "Audit failed at line %d: %s\n", line_number, description);
        exit(3);
    }
}

static void make_path(char *path, const char *directory, const char *relative_path)
{
    int written = snprintf(path, PATH_CAPACITY, "%s/%s", directory, relative_path);
    REQUIRE(written > 0 && (size_t)written < PATH_CAPACITY);
}

static FILE *open_input(const char *directory, const char *relative_path)
{
    char path[PATH_CAPACITY];
    make_path(path, directory, relative_path);
    FILE *input_file = fopen(path, "rb");
    REQUIRE(input_file != NULL);
    return input_file;
}

static int read_line(FILE *input_file, char *line)
{
    if (fgets(line, LINE_CAPACITY, input_file) == NULL) {
        REQUIRE(!ferror(input_file));
        return 0;
    }
    size_t length = strlen(line);
    REQUIRE(length > 0 && line[length - 1u] == '\n');
    line[length - 1u] = '\0';
    REQUIRE(strchr(line, '\r') == NULL);
    return 1;
}

static void require_header(FILE *input_file, const char *expected_header)
{
    char line[LINE_CAPACITY];
    REQUIRE(read_line(input_file, line));
    REQUIRE(strcmp(line, expected_header) == 0);
}

static void require_finished(FILE *input_file)
{
    char line[LINE_CAPACITY];
    REQUIRE(!read_line(input_file, line));
    REQUIRE(fclose(input_file) == 0);
}

static void split_fields(char *line, char **fields, size_t field_count, char separator)
{
    fields[0] = line;
    for (size_t field_index = 0; field_index < field_count; ++field_index) {
        char *next_separator = strchr(fields[field_index], separator);
        REQUIRE((field_index + 1u < field_count) == (next_separator != NULL));
        REQUIRE(*fields[field_index] != '\0');
        if (next_separator != NULL) {
            *next_separator = '\0';
            fields[field_index + 1u] = next_separator + 1;
        }
    }
}

static uint64_t unsigned_value(const char *text)
{
    REQUIRE(*text != '\0');
    uint64_t result = 0;
    for (const char *character = text; *character != '\0'; ++character) {
        REQUIRE(*character >= '0' && *character <= '9');
        uint64_t digit = (uint64_t)(*character - '0');
        REQUIRE(result <= (UINT64_MAX - digit) / UINT64_C(10));
        result = result * UINT64_C(10) + digit;
    }
    return result;
}

static void require_decimal(const char *text, long double value, int decimal_places)
{
    char expected_text[128];
    int written = snprintf(expected_text, sizeof(expected_text), "%.*Lf", decimal_places, value);
    REQUIRE(written > 0 && (size_t)written < sizeof(expected_text));
    REQUIRE(strcmp(text, expected_text) == 0);
}

static int compare_unsigned(const void *first_value, const void *second_value)
{
    uint64_t first_ns = *(const uint64_t *)first_value;
    uint64_t second_ns = *(const uint64_t *)second_value;
    return (first_ns > second_ns) - (first_ns < second_ns);
}

static int compare_ratio(const void *first_value, const void *second_value)
{
    long double first_ratio = *(const long double *)first_value;
    long double second_ratio = *(const long double *)second_value;
    return (first_ratio > second_ratio) - (first_ratio < second_ratio);
}

static void load_metadata(const char *directory, const char *filename, struct metadata *result)
{
    FILE *input_file = open_input(directory, filename);
    char line[LINE_CAPACITY];
    while (read_line(input_file, line)) {
        REQUIRE(result->count < 64u);
        char *separator = strchr(line, '=');
        REQUIRE(separator != NULL);
        *separator = '\0';
        REQUIRE(strlen(line) < sizeof(result->fields[0].name));
        REQUIRE(strlen(separator + 1) < sizeof(result->fields[0].value));
        for (size_t field_index = 0; field_index < result->count; ++field_index) {
            REQUIRE(strcmp(line, result->fields[field_index].name) != 0);
        }
        strcpy(result->fields[result->count].name, line);
        strcpy(result->fields[result->count].value, separator + 1);
        ++result->count;
    }
    REQUIRE(fclose(input_file) == 0);
}

static const char *metadata_text(const struct metadata *source, const char *name)
{
    for (size_t field_index = 0; field_index < source->count; ++field_index) {
        if (strcmp(source->fields[field_index].name, name) == 0) {
            return source->fields[field_index].value;
        }
    }
    REQUIRE(0);
    return "";
}

static uint64_t metadata_number(const struct metadata *source, const char *name)
{
    return unsigned_value(metadata_text(source, name));
}

static void require_identical(FILE *first_file, FILE *second_file)
{
    int first_byte;
    int second_byte;
    do {
        first_byte = fgetc(first_file);
        second_byte = fgetc(second_file);
        REQUIRE(first_byte == second_byte);
    } while (first_byte != EOF);
    REQUIRE(!ferror(first_file) && !ferror(second_file));
    REQUIRE(fclose(first_file) == 0);
    REQUIRE(fclose(second_file) == 0);
}

static void load_task_inputs(const char *evidence_directory,
    const char *original_directory,
    struct audit_task *tasks)
{
    for (size_t task_index = 0; task_index < TASK_COUNT; ++task_index) {
        char filename[128];
        char original_filename[128];
        const char *suffixes[3] = {".csv", ".plan", "-r1-baseline.report"};
        for (size_t file_index = 0; file_index < 3u; ++file_index) {
            snprintf(filename, sizeof(filename), "run/inputs/task-%zu%s", task_index + 1u,
                suffixes[file_index]);
            snprintf(original_filename, sizeof(original_filename), "%s/task-%zu%s",
                file_index == 2u ? "confirmation-results" : "confirmation-data",
                task_index + 1u, suffixes[file_index]);
            require_identical(open_input(evidence_directory, filename),
                open_input(original_directory, original_filename));
        }
        snprintf(filename, sizeof(filename), "run/inputs/task-%zu.csv", task_index + 1u);
        FILE *input_file = open_input(evidence_directory, filename);
        require_header(input_file, "pair_index,first_total_ns,second_total_ns,call_count");
        char line[LINE_CAPACITY];
        for (size_t pair_index = 0; pair_index < PAIR_COUNT; ++pair_index) {
            char *fields[4];
            REQUIRE(read_line(input_file, line));
            split_fields(line, fields, 4u, ',');
            REQUIRE(unsigned_value(fields[0]) == pair_index);
            uint64_t first_total = unsigned_value(fields[1]);
            uint64_t second_total = unsigned_value(fields[2]);
            REQUIRE(first_total > 0 && first_total <= UINT64_C(1000000000000));
            REQUIRE(second_total > 0 && second_total <= UINT64_C(1000000000000));
            REQUIRE(unsigned_value(fields[3]) == 1u);
            int64_t difference = (int64_t)first_total - (int64_t)second_total;
            tasks[task_index].observed_sum += difference;
            tasks[task_index].nonzero_count += (size_t)(difference != 0);
        }
        require_finished(input_file);
        snprintf(filename, sizeof(filename), "run/inputs/task-%zu-r1-baseline.report",
            task_index + 1u);
        struct metadata expectation = {0};
        load_metadata(evidence_directory, filename, &expectation);
        REQUIRE(expectation.count == 7u);
        REQUIRE(strcmp(metadata_text(&expectation, "format"), "scipy_exact_baseline_v1") == 0);
        REQUIRE(strcmp(metadata_text(&expectation, "scipy_version"), "1.16.3") == 0);
        REQUIRE(strcmp(metadata_text(&expectation, "numpy_version"), "2.3.5") == 0);
        REQUIRE(metadata_number(&expectation, "assignment_count") == assignment_count);
        REQUIRE(metadata_number(&expectation, "tail_count") == expected_tails[task_index]);
        REQUIRE(strcmp(metadata_text(&expectation, "report_status"), "complete") == 0);
        require_decimal(metadata_text(&expectation, "p_value"),
            (long double)expected_tails[task_index] / (long double)assignment_count, 15);
    }
    require_identical(open_input(evidence_directory, "run/inputs/task-3.csv"),
        open_input(evidence_directory, "run/inputs/task-7.csv"));
    REQUIRE(tasks[2].nonzero_count == 0 && tasks[6].nonzero_count == 0);
}

static long double audit_clock(const char *directory,
    uint64_t management_start,
    uint64_t management_finish,
    uint64_t resolution,
    long double *empty_median,
    uint64_t *calibration_finish)
{
    FILE *input_file = open_input(directory, "run/raw-clock.csv");
    require_header(input_file, "kind,sample,start_ns,finish_ns,elapsed_ns");
    uint64_t empty_elapsed[CLOCK_COUNT];
    uint64_t previous_finish = 0;
    for (size_t row_index = 0; row_index < 2u * CLOCK_COUNT; ++row_index) {
        char line[LINE_CAPACITY];
        char *fields[5];
        REQUIRE(read_line(input_file, line));
        split_fields(line, fields, 5u, ',');
        size_t sample_index = row_index % CLOCK_COUNT;
        REQUIRE(strcmp(fields[0], row_index < CLOCK_COUNT ? "step" : "empty") == 0);
        REQUIRE(unsigned_value(fields[1]) == sample_index);
        uint64_t start_ns = unsigned_value(fields[2]);
        uint64_t finish_ns = unsigned_value(fields[3]);
        uint64_t elapsed_ns = unsigned_value(fields[4]);
        REQUIRE(start_ns >= management_start && finish_ns <= management_finish);
        REQUIRE(finish_ns >= start_ns && elapsed_ns == finish_ns - start_ns);
        if (row_index > 0) {
            REQUIRE(start_ns >= previous_finish);
            if (row_index < CLOCK_COUNT) {
                REQUIRE(start_ns == previous_finish);
            }
        }
        previous_finish = finish_ns;
        if (row_index >= CLOCK_COUNT) {
            empty_elapsed[sample_index] = elapsed_ns;
        }
    }
    require_finished(input_file);
    *calibration_finish = previous_finish;
    qsort(empty_elapsed, CLOCK_COUNT, sizeof(empty_elapsed[0]), compare_unsigned);
    *empty_median = (long double)empty_elapsed[127] / 2.0L +
        (long double)empty_elapsed[128] / 2.0L;
    return 100.0L * fmaxl((long double)resolution, *empty_median);
}

static uint64_t audit_times(const char *directory,
    struct audit_task *tasks,
    long double minimum_window,
    uint64_t management_start,
    uint64_t management_finish,
    uint64_t calibration_finish,
    uint64_t *checksum,
    uint64_t *minimum_elapsed,
    uint64_t *maximum_elapsed)
{
    FILE *input_file = open_input(directory, "run/raw-times.csv");
    require_header(input_file,
        "phase,task,repeat,order,method,start_ns,finish_ns,elapsed_ns,function_status,"
        "assignment_count,tail_count,mean_difference_ns,exact_p_value,has_variation,"
        "window_clock_qualified,mechanism_scope,consumed_results,status");
    uint64_t total_elapsed = 0;
    uint64_t previous_finish = calibration_finish;
    *minimum_elapsed = UINT64_MAX;
    for (size_t row_index = 0; row_index < TASK_COUNT * 22u; ++row_index) {
        char line[LINE_CAPACITY];
        char *fields[18];
        REQUIRE(read_line(input_file, line));
        split_fields(line, fields, 18u, ',');
        size_t task_index = row_index / 22u;
        size_t task_row = row_index % 22u;
        int is_formal = task_row >= 2u;
        size_t repeat_number = is_formal ? (task_row - 2u) / 2u + 1u : 0u;
        size_t order_index = is_formal ? (task_row - 2u) % 2u : task_row;
        size_t method_index = is_formal ? (repeat_number - 1u + order_index) % 2u : task_row;
        REQUIRE(strcmp(fields[0], is_formal ? "formal" : "warmup") == 0);
        REQUIRE(unsigned_value(fields[1]) == task_index + 1u);
        REQUIRE(unsigned_value(fields[2]) == repeat_number);
        REQUIRE(unsigned_value(fields[3]) == order_index + 1u);
        REQUIRE(strcmp(fields[4], method_names[method_index]) == 0);
        uint64_t start_ns = unsigned_value(fields[5]);
        uint64_t finish_ns = unsigned_value(fields[6]);
        uint64_t elapsed_ns = unsigned_value(fields[7]);
        REQUIRE(unsigned_value(fields[8]) == 0u);
        REQUIRE(unsigned_value(fields[9]) == assignment_count);
        REQUIRE(unsigned_value(fields[10]) == expected_tails[task_index]);
        require_decimal(fields[11], (long double)tasks[task_index].observed_sum / 20.0L, 9);
        require_decimal(fields[12],
            (long double)expected_tails[task_index] / (long double)assignment_count, 15);
        REQUIRE(unsigned_value(fields[13]) == (uint64_t)(tasks[task_index].nonzero_count != 0));
        REQUIRE(strcmp(fields[14], is_formal ? "yes" : "not_timed") == 0);
        REQUIRE(strcmp(fields[15], tasks[task_index].nonzero_count == 0 ?
            "zero_vector_no_per_state_claim" : "nonzero_requires_artifact_review") == 0);
        REQUIRE(unsigned_value(fields[16]) == row_index + 1u);
        REQUIRE(strcmp(fields[17], "count_checked_and_consumed") == 0);
        *checksum = (*checksum ^ expected_tails[task_index]) + assignment_count +
            (uint64_t)(tasks[task_index].nonzero_count != 0);
        if (is_formal) {
            REQUIRE(start_ns >= management_start && finish_ns <= management_finish);
            REQUIRE(start_ns >= previous_finish && finish_ns >= start_ns);
            REQUIRE(elapsed_ns == finish_ns - start_ns);
            REQUIRE((long double)elapsed_ns >= minimum_window);
            previous_finish = finish_ns;
            REQUIRE(total_elapsed <= UINT64_MAX - elapsed_ns);
            total_elapsed += elapsed_ns;
            tasks[task_index].elapsed_ns[repeat_number - 1u][method_index] = elapsed_ns;
            if (elapsed_ns < *minimum_elapsed) {
                *minimum_elapsed = elapsed_ns;
            }
            if (elapsed_ns > *maximum_elapsed) {
                *maximum_elapsed = elapsed_ns;
            }
        } else {
            REQUIRE(start_ns == 0 && finish_ns == 0 && elapsed_ns == 0);
        }
    }
    require_finished(input_file);
    return total_elapsed;
}

static void audit_pairs(const char *directory, struct audit_task *tasks)
{
    FILE *input_file = open_input(directory, "run/pairs.csv");
    require_header(input_file,
        "task,repeat,first_method,incremental_ns,naive_ns,incremental_to_naive_ratio,"
        "both_clock_qualified,mechanism_scope");
    for (size_t row_index = 0; row_index < TASK_COUNT * REPEAT_COUNT; ++row_index) {
        char line[LINE_CAPACITY];
        char *fields[8];
        REQUIRE(read_line(input_file, line));
        split_fields(line, fields, 8u, ',');
        size_t task_index = row_index / REPEAT_COUNT;
        size_t repeat_index = row_index % REPEAT_COUNT;
        REQUIRE(unsigned_value(fields[0]) == task_index + 1u);
        REQUIRE(unsigned_value(fields[1]) == repeat_index + 1u);
        REQUIRE(strcmp(fields[2], method_names[repeat_index % 2u]) == 0);
        REQUIRE(unsigned_value(fields[3]) == tasks[task_index].elapsed_ns[repeat_index][0]);
        REQUIRE(unsigned_value(fields[4]) == tasks[task_index].elapsed_ns[repeat_index][1]);
        REQUIRE(tasks[task_index].elapsed_ns[repeat_index][1] != 0);
        long double ratio = (long double)tasks[task_index].elapsed_ns[repeat_index][0] /
            (long double)tasks[task_index].elapsed_ns[repeat_index][1];
        tasks[task_index].ratios[repeat_index] = ratio;
        require_decimal(fields[5], ratio, 12);
        REQUIRE(strcmp(fields[6], "yes") == 0);
        REQUIRE(strcmp(fields[7], tasks[task_index].nonzero_count == 0 ?
            "zero_vector_no_per_state_claim" : "nonzero_requires_artifact_review") == 0);
    }
    require_finished(input_file);
}

static void audit_summary(const char *directory, struct audit_task *tasks)
{
    FILE *input_file = open_input(directory, "run/summary.csv");
    require_header(input_file,
        "task,nonzero_pair_count,repeat_pairs,ratio_median,ratio_minimum,ratio_maximum,"
        "clock_qualified_pairs,mechanism_scope");
    for (size_t task_index = 0; task_index < TASK_COUNT; ++task_index) {
        char line[LINE_CAPACITY];
        char *fields[8];
        REQUIRE(read_line(input_file, line));
        split_fields(line, fields, 8u, ',');
        REQUIRE(unsigned_value(fields[0]) == task_index + 1u);
        REQUIRE(unsigned_value(fields[1]) == tasks[task_index].nonzero_count);
        REQUIRE(unsigned_value(fields[2]) == REPEAT_COUNT);
        long double sorted_ratios[REPEAT_COUNT];
        memcpy(sorted_ratios, tasks[task_index].ratios, sizeof(sorted_ratios));
        qsort(sorted_ratios, REPEAT_COUNT, sizeof(sorted_ratios[0]), compare_ratio);
        tasks[task_index].ratio_median = sorted_ratios[4] / 2.0L + sorted_ratios[5] / 2.0L;
        tasks[task_index].ratio_minimum = sorted_ratios[0];
        tasks[task_index].ratio_maximum = sorted_ratios[9];
        require_decimal(fields[3], tasks[task_index].ratio_median, 12);
        require_decimal(fields[4], tasks[task_index].ratio_minimum, 12);
        require_decimal(fields[5], tasks[task_index].ratio_maximum, 12);
        REQUIRE(unsigned_value(fields[6]) == REPEAT_COUNT);
        REQUIRE(strcmp(fields[7], tasks[task_index].nonzero_count == 0 ?
            "zero_vector_no_per_state_claim" : "nonzero_requires_artifact_review") == 0);
    }
    require_finished(input_file);
}

int main(int argument_count, char **argument_values)
{
    REQUIRE(argument_count == 4);
    const char *evidence_directory = argument_values[1];
    struct metadata final_state = {0};
    struct metadata initial_state = {0};
    load_metadata(evidence_directory, "run/final-state.meta", &final_state);
    load_metadata(evidence_directory, "run/initial-state.meta", &initial_state);
    REQUIRE(strcmp(metadata_text(&final_state, "final_state"), "complete") == 0);
    REQUIRE(strcmp(metadata_text(&final_state, "failure_reason"), "none") == 0);
    REQUIRE(strcmp(metadata_text(&final_state, "clock"), "CLOCK_MONOTONIC") == 0);
    REQUIRE(strcmp(metadata_text(&final_state, "time_unit"), "ns") == 0);
    REQUIRE(strcmp(metadata_text(&initial_state, "initial_state"), "started") == 0);
    uint64_t management_start = metadata_number(&final_state, "management_start_ns");
    uint64_t management_finish = metadata_number(&final_state, "management_finish_ns");
    REQUIRE(management_finish >= management_start);
    REQUIRE(metadata_number(&initial_state, "management_start_ns") == management_start);
    REQUIRE(metadata_number(&initial_state, "budget_ns") == UINT64_C(30000000000));
    REQUIRE(metadata_number(&final_state, "management_elapsed_ns") ==
        management_finish - management_start);
    REQUIRE(metadata_number(&final_state, "budget_ns") == UINT64_C(30000000000));
    REQUIRE(management_finish - management_start < UINT64_C(30000000000));
    REQUIRE(metadata_number(&final_state, "clock_step_count") == CLOCK_COUNT);
    REQUIRE(metadata_number(&final_state, "empty_window_count") == CLOCK_COUNT);
    REQUIRE(metadata_number(&final_state, "warmup_count") == 16u);
    REQUIRE(metadata_number(&final_state, "formal_count") == 160u);
    REQUIRE(metadata_number(&final_state, "consumed_results") == 176u);
    REQUIRE(metadata_number(&final_state, "compute_interval") == 0);
    REQUIRE(metadata_number(&final_state, "repeat_pairs_per_task") == REPEAT_COUNT);
    REQUIRE(strcmp(metadata_text(&final_state, "input_byte_comparison"),
        "all_24_files_identical") == 0);
    REQUIRE(strcmp(metadata_text(&final_state, "sanitizers"), "disabled") == 0);
    REQUIRE(strcmp(metadata_text(&final_state, "lto"), "disabled") == 0);
    REQUIRE(strcmp(metadata_text(&final_state, "architecture"), "arm64") == 0);
    REQUIRE(strcmp(metadata_text(&final_state, "platform"), "Darwin") == 0);
    uint64_t publication_start = metadata_number(&final_state, "publication_start_ns");
    uint64_t publication_flush = metadata_number(&final_state, "publication_content_flushed_ns");
    REQUIRE(publication_start >= management_finish && publication_flush >= publication_start);
    REQUIRE(metadata_number(&final_state, "publication_content_elapsed_ns") ==
        publication_flush - publication_start);
    require_identical(open_input(evidence_directory, "run/final-state.meta"),
        open_input(evidence_directory, "run/final-state.pending"));
    FILE *failure_file = open_input(evidence_directory, "run/failures.csv");
    require_header(failure_file, "phase,task,repeat,method,reason");
    require_finished(failure_file);
    struct audit_task tasks[TASK_COUNT] = {0};
    load_task_inputs(evidence_directory, argument_values[2], tasks);
    long double empty_median = 0;
    uint64_t calibration_finish = 0;
    uint64_t resolution = metadata_number(&final_state, "clock_resolution_ns");
    long double minimum_window = audit_clock(evidence_directory, management_start,
        management_finish, resolution, &empty_median, &calibration_finish);
    require_decimal(metadata_text(&final_state, "minimum_algorithm_window_ns"), minimum_window, 3);
    uint64_t checksum = 0;
    uint64_t minimum_elapsed = 0;
    uint64_t maximum_elapsed = 0;
    uint64_t total_elapsed = audit_times(evidence_directory, tasks, minimum_window,
        management_start, management_finish, calibration_finish, &checksum, &minimum_elapsed,
        &maximum_elapsed);
    REQUIRE(metadata_number(&final_state, "checksum") == checksum);
    REQUIRE(metadata_number(&final_state, "algorithm_window_total_ns") == total_elapsed);
    REQUIRE(total_elapsed <= management_finish - management_start);
    audit_pairs(evidence_directory, tasks);
    audit_summary(evidence_directory, tasks);
    FILE *output_file = fopen(argument_values[3], "wx");
    REQUIRE(output_file != NULL);
    REQUIRE(fprintf(output_file,
        "{\n  \"format\": \"independent_c_update_cost_audit_v1\",\n"
        "  \"verified\": true,\n  \"statistics_rerun\": false,\n"
        "  \"cryptographic_calls\": 0,\n  \"input_copies_compared\": 24,\n"
        "  \"input_copies_identical\": true,\n  \"zero_tasks_3_7_identical\": true,\n"
        "  \"warmup_rows\": 16,\n  \"formal_rows\": 160,\n  \"consumed_results\": 176,\n"
        "  \"step_rows\": 256,\n  \"empty_rows\": 256,\n  \"pair_rows\": 80,\n"
        "  \"qualified_pair_rows\": 80,\n  \"summary_rows\": 8,\n  \"failure_rows\": 0,\n"
        "  \"raw_order_and_expected_results_verified\": true,\n"
        "  \"all_decimal_ratios_and_summaries_verified\": true,\n"
        "  \"clock_resolution_ns\": %" PRIu64 ",\n  \"empty_median_ns\": %.3Lf,\n"
        "  \"minimum_window_ns\": %.3Lf,\n  \"minimum_formal_elapsed_ns\": %" PRIu64 ",\n"
        "  \"maximum_formal_elapsed_ns\": %" PRIu64 ",\n"
        "  \"management_elapsed_ns\": %" PRIu64 ",\n"
        "  \"algorithm_window_total_ns\": %" PRIu64 ",\n"
        "  \"management_excluding_algorithm_windows_ns\": %" PRIu64 ",\n"
        "  \"budget_ns\": 30000000000,\n  \"within_budget\": true,\n"
        "  \"checksum\": %" PRIu64 ",\n  \"publication_content_elapsed_ns\": %" PRIu64 ",\n"
        "  \"tasks\": [\n",
        resolution, empty_median, minimum_window, minimum_elapsed, maximum_elapsed,
        management_finish - management_start, total_elapsed,
        management_finish - management_start - total_elapsed, checksum,
        publication_flush - publication_start) > 0);
    for (size_t task_index = 0; task_index < TASK_COUNT; ++task_index) {
        REQUIRE(fprintf(output_file,
            "    {\"task\": %zu, \"nonzero_pair_count\": %zu, \"tail_count\": %" PRIu64
            ", \"ratio_median\": %.12Lf, \"ratio_minimum\": %.12Lf, \"ratio_maximum\": %.12Lf,"
            " \"is_nonzero_task\": %s}%s\n",
            task_index + 1u, tasks[task_index].nonzero_count, expected_tails[task_index],
            tasks[task_index].ratio_median, tasks[task_index].ratio_minimum,
            tasks[task_index].ratio_maximum, tasks[task_index].nonzero_count != 0 ? "true" : "false",
            task_index + 1u < TASK_COUNT ? "," : "") > 0);
    }
    REQUIRE(fputs("  ],\n  \"scope\": \"fixed_tasks_single_process_single_build_macos_arm64\",\n"
        "  \"decomposes_previous_c_scipy_ratio\": false,\n"
        "  \"population_inference\": false\n}\n", output_file) != EOF);
    REQUIRE(fclose(output_file) == 0);
    puts("Independent C audit passed; formal observer and statistics were not rerun.");
    return 0;
}
