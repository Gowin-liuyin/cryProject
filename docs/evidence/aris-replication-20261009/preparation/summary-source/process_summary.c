#include <errno.h>
#include <math.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#define PROCESS_COUNT 3u
#define TASK_COUNT 8u
#define REPEAT_PAIRS 10u
#define LINE_CAPACITY 512u
#define PATH_CAPACITY 4096u
#define FIXTURE_CAPACITY 4096u

struct summary_row {
    unsigned int nonzero_pair_count;
    long double ratio_median;
    long double ratio_minimum;
    long double ratio_maximum;
    unsigned int clock_qualified_pairs;
};

struct summary_facts {
    unsigned int supporting_nonzero_medians;
    unsigned int clock_qualified_pairs;
    int direction_supported;
    int clocks_complete;
};

static const char *const summary_header =
    "task,nonzero_pair_count,repeat_pairs,ratio_median,ratio_minimum,ratio_maximum,"
    "clock_qualified_pairs,mechanism_scope";
static const char *const nonzero_scope = "nonzero_requires_artifact_review";
static const char *const zero_scope = "zero_vector_no_per_state_claim";

static int read_line(FILE *input_file, char *line)
{
    size_t length = 0;
    int character;
    while ((character = fgetc(input_file)) != EOF) {
        if (character == '\n') {
            line[length] = '\0';
            return 1;
        }
        if (character == '\0' || character == '\r' || length + 1u >= LINE_CAPACITY) {
            return -1;
        }
        line[length++] = (char)character;
    }
    return ferror(input_file) || length != 0u ? -1 : 0;
}

static int split_fields(char *line, char **fields)
{
    fields[0] = line;
    for (size_t field_index = 0; field_index < 8u; ++field_index) {
        char *separator = strchr(fields[field_index], ',');
        if (*fields[field_index] == '\0' || ((field_index + 1u < 8u) != (separator != NULL))) {
            return 0;
        }
        if (separator != NULL) {
            *separator = '\0';
            fields[field_index + 1u] = separator + 1;
        }
    }
    return 1;
}

static int parse_unsigned(const char *text, unsigned int *value)
{
    uint32_t parsed = 0;
    if (*text == '\0' || (text[0] == '0' && text[1] != '\0')) {
        return 0;
    }
    for (const char *character = text; *character != '\0'; ++character) {
        if (*character < '0' || *character > '9') {
            return 0;
        }
        uint32_t digit = (uint32_t)(*character - '0');
        if (parsed > (UINT32_MAX - digit) / UINT32_C(10)) {
            return 0;
        }
        parsed = parsed * UINT32_C(10) + digit;
    }
    *value = (unsigned int)parsed;
    return 1;
}

static int parse_ratio(const char *text, long double *value)
{
    const char *decimal = strchr(text, '.');
    if (decimal == NULL || decimal == text || strlen(decimal + 1) != 12u ||
        (text[0] == '0' && decimal != text + 1)) {
        return 0;
    }
    for (const char *character = text; *character != '\0'; ++character) {
        if (character != decimal && (*character < '0' || *character > '9')) {
            return 0;
        }
    }
    errno = 0;
    char *end = NULL;
    long double parsed = strtold(text, &end);
    if (errno != 0 || end == NULL || *end != '\0' || !isfinite(parsed) || parsed <= 0.0L) {
        return 0;
    }
    *value = parsed;
    return 1;
}

static int read_summary(FILE *input_file, struct summary_row *rows)
{
    char line[LINE_CAPACITY];
    if (read_line(input_file, line) != 1 || strcmp(line, summary_header) != 0) {
        return 0;
    }
    for (size_t task_index = 0; task_index < TASK_COUNT; ++task_index) {
        char *fields[8];
        unsigned int task_number;
        unsigned int repeat_pairs;
        unsigned int nonzero_pairs;
        unsigned int qualified_pairs;
        if (read_line(input_file, line) != 1 || !split_fields(line, fields) ||
            !parse_unsigned(fields[0], &task_number) || task_number != task_index + 1u ||
            !parse_unsigned(fields[1], &nonzero_pairs) ||
            !parse_unsigned(fields[2], &repeat_pairs) || repeat_pairs != REPEAT_PAIRS ||
            !parse_unsigned(fields[6], &qualified_pairs) || qualified_pairs > REPEAT_PAIRS) {
            return 0;
        }
        int is_zero_task = task_number == 3u || task_number == 7u;
        if (nonzero_pairs != (is_zero_task ? 0u : 20u) ||
            strcmp(fields[7], is_zero_task ? zero_scope : nonzero_scope) != 0 ||
            !parse_ratio(fields[3], &rows[task_index].ratio_median) ||
            !parse_ratio(fields[4], &rows[task_index].ratio_minimum) ||
            !parse_ratio(fields[5], &rows[task_index].ratio_maximum) ||
            rows[task_index].ratio_minimum > rows[task_index].ratio_median ||
            rows[task_index].ratio_median > rows[task_index].ratio_maximum) {
            return 0;
        }
        rows[task_index].nonzero_pair_count = nonzero_pairs;
        rows[task_index].clock_qualified_pairs = qualified_pairs;
    }
    return read_line(input_file, line) == 0;
}

static struct summary_facts summarize_rows(struct summary_row rows[PROCESS_COUNT][TASK_COUNT])
{
    struct summary_facts facts = {0};
    for (size_t process_index = 0; process_index < PROCESS_COUNT; ++process_index) {
        for (size_t task_index = 0; task_index < TASK_COUNT; ++task_index) {
            const struct summary_row *row = &rows[process_index][task_index];
            if (row->nonzero_pair_count != 0u && row->ratio_median < 1.0L) {
                ++facts.supporting_nonzero_medians;
            }
            facts.clock_qualified_pairs += row->clock_qualified_pairs;
        }
    }
    facts.direction_supported = facts.supporting_nonzero_medians == 18u;
    facts.clocks_complete = facts.clock_qualified_pairs == 240u;
    return facts;
}

static int write_report(FILE *output_file,
    struct summary_row rows[PROCESS_COUNT][TASK_COUNT],
    struct summary_facts facts)
{
    int pattern_supported = facts.direction_supported && facts.clocks_complete;
    const char *claim_status = pattern_supported
        ? "awaiting_independent_process_audits_and_artifact_checks"
        : "unsupported_by_three_summary_tables";
    if (fprintf(output_file,
            "{\n  \"format\": \"m02_three_process_summary_v1\",\n"
            "  \"process_count\": 3,\n  \"tasks_per_process\": 8,\n"
            "  \"nonzero_task_medians\": 18,\n"
            "  \"supporting_nonzero_task_medians\": %u,\n"
            "  \"clock_qualified_pairs\": %u,\n"
            "  \"summary_direction_supported\": %s,\n"
            "  \"summary_clock_qualification_complete\": %s,\n"
            "  \"summary_pattern_supported\": %s,\n"
            "  \"research_claim_status\": \"%s\",\n"
            "  \"process_identity_verified_by_this_program\": false,\n"
            "  \"source_artifact_raw_counts_verified_by_this_program\": false,\n"
            "  \"statistics_rerun\": false,\n  \"cryptographic_calls\": 0,\n"
            "  \"old_m01_loaded\": false,\n  \"population_inference\": false,\n"
            "  \"scope\": \"three_named_summary_tables_only\",\n"
            "  \"rows\": [\n",
            facts.supporting_nonzero_medians,
            facts.clock_qualified_pairs,
            facts.direction_supported ? "true" : "false",
            facts.clocks_complete ? "true" : "false",
            pattern_supported ? "true" : "false",
            claim_status) < 0) {
        return 0;
    }
    for (size_t process_index = 0; process_index < PROCESS_COUNT; ++process_index) {
        for (size_t task_index = 0; task_index < TASK_COUNT; ++task_index) {
            const struct summary_row *row = &rows[process_index][task_index];
            if (fprintf(output_file,
                    "    {\"process\": %zu, \"task\": %zu, \"nonzero_pair_count\": %u,"
                    " \"repeat_pairs\": 10, \"ratio_median\": %.12Lf,"
                    " \"ratio_minimum\": %.12Lf, \"ratio_maximum\": %.12Lf,"
                    " \"clock_qualified_pairs\": %u, \"mechanism_scope\": \"%s\"}%s\n",
                    process_index + 1u,
                    task_index + 1u,
                    row->nonzero_pair_count,
                    row->ratio_median,
                    row->ratio_minimum,
                    row->ratio_maximum,
                    row->clock_qualified_pairs,
                    row->nonzero_pair_count == 0u ? zero_scope : nonzero_scope,
                    process_index + 1u == PROCESS_COUNT && task_index + 1u == TASK_COUNT
                        ? ""
                        : ",") < 0) {
                return 0;
            }
        }
    }
    return fputs("  ]\n}\n", output_file) != EOF;
}

#define FIXTURE_HEADER                                                                             \
    "task,nonzero_pair_count,repeat_pairs,ratio_median,ratio_minimum,ratio_maximum,"               \
    "clock_qualified_pairs,mechanism_scope\n"
#define ZERO_ROW(task)                                                                             \
    task ",0,10,1.500000000000,1.000000000000,2.000000000000,10,zero_vector_no_per_state_claim\n"
#define NONZERO_ROW(task, median, minimum, maximum)                                                \
    task ",20,10," median "," minimum "," maximum ",10,nonzero_requires_artifact_review\n"

static const char *const valid_fixtures[PROCESS_COUNT] = {
    FIXTURE_HEADER NONZERO_ROW("1", "0.500000000000", "0.250000000000", "0.750000000000")
        NONZERO_ROW("2", "0.500000000000", "0.250000000000", "0.750000000000") ZERO_ROW(
            "3") NONZERO_ROW("4", "0.500000000000", "0.250000000000", "0.750000000000")
            NONZERO_ROW("5", "0.500000000000", "0.250000000000", "0.750000000000")
                NONZERO_ROW("6", "0.500000000000", "0.250000000000", "0.750000000000") ZERO_ROW("7")
                    NONZERO_ROW("8", "0.500000000000", "0.250000000000", "0.750000000000"),
    FIXTURE_HEADER NONZERO_ROW("1", "0.750000000000", "0.500000000000", "1.000000000000")
        NONZERO_ROW("2", "0.750000000000", "0.500000000000", "1.000000000000") ZERO_ROW(
            "3") NONZERO_ROW("4", "0.750000000000", "0.500000000000", "1.000000000000")
            NONZERO_ROW("5", "0.750000000000", "0.500000000000", "1.000000000000")
                NONZERO_ROW("6", "0.750000000000", "0.500000000000", "1.000000000000") ZERO_ROW("7")
                    NONZERO_ROW("8", "0.750000000000", "0.500000000000", "1.000000000000"),
    FIXTURE_HEADER NONZERO_ROW("1", "0.900000000000", "0.800000000000", "1.000000000000")
        NONZERO_ROW("2", "0.900000000000", "0.800000000000", "1.000000000000") ZERO_ROW(
            "3") NONZERO_ROW("4", "0.900000000000", "0.800000000000", "1.000000000000")
            NONZERO_ROW("5", "0.900000000000", "0.800000000000", "1.000000000000")
                NONZERO_ROW("6", "0.900000000000", "0.800000000000", "1.000000000000") ZERO_ROW("7")
                    NONZERO_ROW("8", "0.900000000000", "0.800000000000", "1.000000000000")};

static void require_test(int condition, const char *name)
{
    if (!condition) {
        fprintf(stderr, "Self-test failed: %s\n", name);
        exit(3);
    }
}

static void require_report(struct summary_row rows[PROCESS_COUNT][TASK_COUNT],
    struct summary_facts facts,
    const char *expected_status)
{
    FILE *output_file = tmpfile();
    require_test(output_file != NULL, "report temporary file");
    require_test(write_report(output_file, rows, facts), "report write");
    require_test(fflush(output_file) == 0 && fseek(output_file, 0, SEEK_SET) == 0, "report rewind");
    char status_line[128];
    int written = snprintf(status_line,
        sizeof(status_line),
        "  \"research_claim_status\": \"%s\",",
        expected_status);
    require_test(written > 0 && (size_t)written < sizeof(status_line), "status line bound");
    unsigned int row_count = 0;
    unsigned int limit_count = 0;
    unsigned int status_count = 0;
    char line[LINE_CAPACITY];
    int line_status;
    while ((line_status = read_line(output_file, line)) == 1) {
        if (strncmp(line, "    {\"process\":", 15u) == 0) {
            ++row_count;
        }
        if (strcmp(line, status_line) == 0) {
            ++status_count;
        }
        if (strcmp(line, "  \"process_identity_verified_by_this_program\": false,") == 0 ||
            strcmp(line, "  \"source_artifact_raw_counts_verified_by_this_program\": false,") ==
                0 ||
            strcmp(line, "  \"population_inference\": false,") == 0) {
            ++limit_count;
        }
    }
    require_test(line_status == 0 && row_count == 24u && status_count == 1u && limit_count == 3u,
        "handwritten report status, limits and 24 rows");
    require_test(fclose(output_file) == 0, "report close");
}

static int parse_fixture(const char *text, size_t length, struct summary_row *rows)
{
    FILE *input_file = tmpfile();
    require_test(input_file != NULL, "fixture temporary file");
    require_test(fwrite(text, 1u, length, input_file) == length, "fixture write");
    require_test(fflush(input_file) == 0 && fseek(input_file, 0, SEEK_SET) == 0, "fixture rewind");
    int parsed = read_summary(input_file, rows);
    require_test(fclose(input_file) == 0, "fixture close");
    return parsed;
}

static size_t replace_fixture(char *output, const char *original, const char *from, const char *to)
{
    const char *position = strstr(original, from);
    require_test(position != NULL, "fixture replacement exists");
    size_t prefix_length = (size_t)(position - original);
    size_t suffix_length = strlen(position + strlen(from));
    size_t total_length = prefix_length + strlen(to) + suffix_length;
    require_test(total_length < FIXTURE_CAPACITY, "fixture replacement bound");
    memcpy(output, original, prefix_length);
    memcpy(output + prefix_length, to, strlen(to));
    memcpy(output + prefix_length + strlen(to), position + strlen(from), suffix_length + 1u);
    return total_length;
}

static void selftest(void)
{
    struct summary_row rows[PROCESS_COUNT][TASK_COUNT];
    for (size_t process_index = 0; process_index < PROCESS_COUNT; ++process_index) {
        require_test(parse_fixture(valid_fixtures[process_index],
                         strlen(valid_fixtures[process_index]),
                         rows[process_index]),
            "valid fixture");
    }
    struct summary_facts facts = summarize_rows(rows);
    require_test(facts.supporting_nonzero_medians == 18u && facts.clock_qualified_pairs == 240u &&
            facts.direction_supported && facts.clocks_complete,
        "hand-counted support");
    require_report(rows, facts, "awaiting_independent_process_audits_and_artifact_checks");
    char modified[FIXTURE_CAPACITY];
    size_t length = replace_fixture(modified,
        valid_fixtures[2],
        "8,20,10,0.900000000000,0.800000000000,1.000000000000,10,",
        "8,20,10,1.000000000000,0.750000000000,1.250000000000,10,");
    require_test(parse_fixture(modified, length, rows[2]), "equal-one is valid data");
    facts = summarize_rows(rows);
    require_test(facts.supporting_nonzero_medians == 17u && !facts.direction_supported &&
            facts.clocks_complete,
        "equal-one unsupported direction");
    require_report(rows, facts, "unsupported_by_three_summary_tables");
    require_test(parse_fixture(valid_fixtures[2], strlen(valid_fixtures[2]), rows[2]),
        "restore data");
    length = replace_fixture(modified,
        valid_fixtures[1],
        "6,20,10,0.750000000000,0.500000000000,1.000000000000,10,",
        "6,20,10,0.750000000000,0.500000000000,1.000000000000,9,");
    require_test(parse_fixture(modified, length, rows[1]), "insufficient-clock is valid data");
    facts = summarize_rows(rows);
    require_test(facts.direction_supported && !facts.clocks_complete &&
            facts.clock_qualified_pairs == 239u,
        "one missing clock qualification");
    require_report(rows, facts, "unsupported_by_three_summary_tables");

    static const struct {
        const char *from;
        const char *to;
    } rejected[] = {{"task,", "wrong,"},
        {"1,20,10,", "2,20,10,"},
        {"3,0,10,", "3,20,10,"},
        {"1,20,10,", "1,0,10,"},
        {"1,20,10,", "1,20,9,"},
        {",10,nonzero_requires", ",11,nonzero_requires"},
        {"0.500000000000,0.250000000000", "-1.000000000000,0.250000000000"},
        {"0.500000000000,0.250000000000", "NaN,0.250000000000"},
        {"0.500000000000,0.250000000000", "Inf,0.250000000000"},
        {"0.500000000000,0.250000000000", "0.500000000000,0.600000000000"},
        {"0.750000000000,10,nonzero", "0.400000000000,10,nonzero"},
        {"zero_vector_no_per_state_claim", "nonzero_requires_artifact_review"},
        {"0.500000000000,0.250000000000", "0.5,0.250000000000"},
        {"1,20,10,", "1,42949672960,10,"},
        {"0.500000000000,0.250000000000", "0.500000000000,extra,0.250000000000"}};

    for (size_t rejected_index = 0; rejected_index < sizeof(rejected) / sizeof(rejected[0]);
        ++rejected_index) {
        length = replace_fixture(modified,
            valid_fixtures[0],
            rejected[rejected_index].from,
            rejected[rejected_index].to);
        require_test(!parse_fixture(modified, length, rows[0]), "invalid schema or value rejected");
    }
    const char *last_row = strstr(valid_fixtures[0], "\n8,");
    require_test(last_row != NULL, "last fixture row");
    require_test(
        !parse_fixture(valid_fixtures[0], (size_t)(last_row + 1 - valid_fixtures[0]), rows[0]),
        "missing row rejected");
    require_test(!parse_fixture(valid_fixtures[0], strlen(valid_fixtures[0]) - 1u, rows[0]),
        "truncated final newline rejected");
    length = strlen(valid_fixtures[0]);
    memcpy(modified, valid_fixtures[0], length);
    modified[length++] = '\n';
    require_test(!parse_fixture(modified, length, rows[0]), "extra row rejected");
    memcpy(modified, valid_fixtures[0], strlen(valid_fixtures[0]));
    modified[0] = '\0';
    require_test(!parse_fixture(modified, strlen(valid_fixtures[0]), rows[0]),
        "embedded NUL rejected");
    puts("Hand-written support, reversal, clock and strict-input fixtures passed; no observer "
         "called.");
}

int main(int argument_count, char **argument_values)
{
    if (argument_count == 2 && strcmp(argument_values[1], "--selftest") == 0) {
        selftest();
        return 0;
    }
    if (argument_count != 3) {
        fprintf(stderr, "Usage: process_summary M02_RAW_ROOT NEW_REPORT_FILE\n");
        return 2;
    }
    struct summary_row rows[PROCESS_COUNT][TASK_COUNT];
    for (size_t process_index = 0; process_index < PROCESS_COUNT; ++process_index) {
        char path[PATH_CAPACITY];
        int written = snprintf(path,
            sizeof(path),
            "%s/run-%zu/summary.csv",
            argument_values[1],
            process_index + 1u);
        if (written <= 0 || (size_t)written >= sizeof(path)) {
            fprintf(stderr, "Summary path exceeds bound\n");
            return 1;
        }
        FILE *input_file = fopen(path, "rb");
        if (input_file == NULL) {
            fprintf(stderr, "Cannot open process %zu summary\n", process_index + 1u);
            return 1;
        }
        int parsed = read_summary(input_file, rows[process_index]);
        int closed = fclose(input_file);
        if (!parsed || closed != 0) {
            fprintf(stderr, "Invalid or unreadable process %zu summary\n", process_index + 1u);
            return 1;
        }
    }
    FILE *output_file = fopen(argument_values[2], "wx");
    if (output_file == NULL) {
        fprintf(stderr, "Cannot create new summary report\n");
        return 1;
    }
    struct summary_facts facts = summarize_rows(rows);
    int written = write_report(output_file, rows, facts);
    int closed = fclose(output_file);
    if (!written || closed != 0) {
        fprintf(stderr, "Summary output failed; retain partial report\n");
        return 1;
    }
    puts("Three summary tables recorded; overall claim still requires independent process checks.");
    return 0;
}
