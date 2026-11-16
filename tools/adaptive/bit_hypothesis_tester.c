/* 逐位检验器（T6.1）：输入某目标位的两组重复观测（CSV 两列，每行=一次重复的均值纳秒），
 * 每次重复 vote = (t_h1 > t_h0)，多数票定为位判定；二项精确检验
 * p = P(X >= 多数票数)，X ~ Bin(REPEAT_COUNT, 0.5)，不用正态近似。
 *
 * 常量已冻结（本文件头 #define，运行期不可改）：
 *   REPEAT_COUNT = 1000、MAJORITY_THRESHOLD = 501、ALPHA = 0.05。
 * 退化情形：所有重复的 t_h0 == t_h1（逐元素相等）时不存在可判方向，
 * 按“未检出差异”输出 decision=0、p_value=1（注释说明，不当作用精确式的例外外推）。
 *
 * 用法：bit_hypothesis_tester --input <two-column.csv>
 * 退出码：0 成功；1 用法；2 数据。 */

#define _POSIX_C_SOURCE 200809L

#include <errno.h>
#include <math.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#define REPEAT_COUNT 1000u
#define MAJORITY_THRESHOLD 501u
#define ALPHA 0.05
#define BIT_TESTER_LINE_CAPACITY_BYTES 4096u
#define BIT_TESTER_CSV_HEADER "hypothesis_zero_nanoseconds,hypothesis_one_nanoseconds"
#define BIT_TESTER_EXIT_USAGE 1
#define BIT_TESTER_EXIT_DATA 2

static void print_usage(void)
{
    fputs("usage: bit_hypothesis_tester --input <two-column.csv>\n", stderr);
}

static int take_argument_value(int argument_count,
    char **argument_values,
    int *argument_index,
    const char *name,
    const char **value)
{
    const char *argument = argument_values[*argument_index];
    size_t name_bytes = strlen(name);
    if (strncmp(argument, name, name_bytes) != 0) {
        return 1;
    }
    if (argument[name_bytes] == '=') {
        *value = argument + name_bytes + 1u;
        return 0;
    }
    if (argument[name_bytes] != '\0') {
        return 1;
    }
    if (*argument_index + 1 >= argument_count) {
        return 2;
    }
    ++(*argument_index);
    *value = argument_values[*argument_index];
    return 0;
}

static int parse_decimal(const char *text, double *value)
{
    if (*text == '\0') {
        return 1;
    }
    errno = 0;
    char *end = NULL;
    double parsed_value = strtod(text, &end);
    if (errno != 0 || end == text || *end != '\0' || !isfinite(parsed_value)) {
        return 1;
    }
    *value = parsed_value;
    return 0;
}

static size_t split_fields(char *line, char **fields, size_t capacity)
{
    size_t field_count = 1u;
    fields[0] = line;
    for (char *cursor = line; *cursor != '\0'; ++cursor) {
        if (*cursor == '"' || *cursor == '\r') {
            return 0u;
        }
        if (*cursor == ',') {
            *cursor = '\0';
            if (field_count == capacity) {
                return 0u;
            }
            fields[field_count] = cursor + 1u;
            ++field_count;
        }
    }
    return field_count;
}

/* 二项精确尾概率：P(X >= majority_votes)，X ~ Bin(REPEAT_COUNT, 0.5)。
 * 用递推 pmf 逐项精确求和；REPEAT_COUNT=1000 时 pmf(0)=2^-1000 仍在 double 正规/次正规范围。 */
static double binomial_tail_probability(unsigned majority_votes)
{
    double probability_mass = pow(0.5, (double)REPEAT_COUNT);
    double tail_probability = 0.0;
    for (unsigned success_count = 0u; success_count <= REPEAT_COUNT; ++success_count) {
        if (success_count >= majority_votes) {
            tail_probability += probability_mass;
        }
        if (success_count < REPEAT_COUNT) {
            probability_mass *=
                (double)(REPEAT_COUNT - success_count) / (double)(success_count + 1u);
        }
    }
    if (tail_probability > 1.0) {
        tail_probability = 1.0;
    }
    return tail_probability;
}

int main(int argument_count, char **argument_values)
{
    const char *input_path = NULL;
    for (int argument_index = 1; argument_index < argument_count; ++argument_index) {
        const char *value = NULL;
        int taken = take_argument_value(argument_count,
            argument_values,
            &argument_index,
            "--input",
            &value);
        if (taken == 0) {
            if (input_path != NULL) {
                print_usage();
                return BIT_TESTER_EXIT_USAGE;
            }
            input_path = value;
            continue;
        }
        print_usage();
        return BIT_TESTER_EXIT_USAGE;
    }
    if (input_path == NULL) {
        print_usage();
        return BIT_TESTER_EXIT_USAGE;
    }
    FILE *input_file = fopen(input_path, "r");
    if (input_file == NULL) {
        fprintf(stderr, "error: cannot open input %s\n", input_path);
        return BIT_TESTER_EXIT_DATA;
    }
    char line[BIT_TESTER_LINE_CAPACITY_BYTES];
    char *fields[2];
    size_t line_number = 0u;
    unsigned votes_true = 0u;
    unsigned votes_false = 0u;
    unsigned equal_count = 0u;
    int status = 0;
    while (fgets(line, (int)sizeof(line), input_file) != NULL) {
        ++line_number;
        size_t line_bytes = strlen(line);
        if (line_bytes > 0u && line[line_bytes - 1u] == '\n') {
            line[line_bytes - 1u] = '\0';
        } else if (!feof(input_file)) {
            fprintf(stderr,
                "error: line %zu exceeds %u bytes\n",
                line_number,
                (unsigned)BIT_TESTER_LINE_CAPACITY_BYTES);
            status = BIT_TESTER_EXIT_DATA;
            break;
        }
        if (strchr(line, '\r') != NULL) {
            fprintf(stderr, "error: line %zu uses CR/CRLF\n", line_number);
            status = BIT_TESTER_EXIT_DATA;
            break;
        }
        if (line_number == 1u) {
            if (strcmp(line, BIT_TESTER_CSV_HEADER) != 0) {
                fprintf(stderr, "error: unexpected header on line 1\n");
                status = BIT_TESTER_EXIT_DATA;
                break;
            }
            continue;
        }
        if (line[0] == '\0') {
            fprintf(stderr, "error: line %zu is blank\n", line_number);
            status = BIT_TESTER_EXIT_DATA;
            break;
        }
        size_t field_count = split_fields(line, fields, 2u);
        if (field_count != 2u) {
            fprintf(stderr,
                "error: line %zu has %zu fields, expected 2\n",
                line_number,
                field_count);
            status = BIT_TESTER_EXIT_DATA;
            break;
        }
        double hypothesis_zero_nanoseconds = 0.0;
        double hypothesis_one_nanoseconds = 0.0;
        if (parse_decimal(fields[0], &hypothesis_zero_nanoseconds) != 0 ||
            parse_decimal(fields[1], &hypothesis_one_nanoseconds) != 0) {
            fprintf(stderr, "error: line %zu has an invalid decimal value\n", line_number);
            status = BIT_TESTER_EXIT_DATA;
            break;
        }
        if (hypothesis_one_nanoseconds > hypothesis_zero_nanoseconds) {
            ++votes_true;
        } else if (hypothesis_one_nanoseconds < hypothesis_zero_nanoseconds) {
            ++votes_false;
        } else {
            ++equal_count;
        }
        if (votes_true + votes_false + equal_count > REPEAT_COUNT) {
            fprintf(stderr, "error: more than %u repeat rows\n", (unsigned)REPEAT_COUNT);
            status = BIT_TESTER_EXIT_DATA;
            break;
        }
    }
    if (fclose(input_file) != 0 && status == 0) {
        fprintf(stderr, "error: cannot close input %s\n", input_path);
        status = BIT_TESTER_EXIT_DATA;
    }
    if (status == 0) {
        if (line_number == 0u) {
            fprintf(stderr, "error: input %s is empty\n", input_path);
            status = BIT_TESTER_EXIT_DATA;
        } else if (votes_true + votes_false + equal_count != REPEAT_COUNT) {
            fprintf(stderr,
                "error: input %s has %u repeat rows, expected %u\n",
                input_path,
                votes_true + votes_false + equal_count,
                (unsigned)REPEAT_COUNT);
            status = BIT_TESTER_EXIT_DATA;
        }
    }
    if (status != 0) {
        return status;
    }
    unsigned decision = votes_true >= MAJORITY_THRESHOLD ? 1u : 0u;
    unsigned majority_votes = decision != 0u ? votes_true : votes_false;
    double p_value = 1.0;
    if (equal_count < REPEAT_COUNT) {
        p_value = binomial_tail_probability(majority_votes);
    }
    /* equal_count == REPEAT_COUNT：逐元素全等，没有可判方向，按未检出输出 0/1。 */
    const char *verdict = p_value < ALPHA ? "flag" : "clear";
    printf("repeat_count=%u\n", (unsigned)REPEAT_COUNT);
    printf("majority_threshold=%u\n", (unsigned)MAJORITY_THRESHOLD);
    printf("alpha=%.17g\n", ALPHA);
    printf("votes_true=%u\n", votes_true);
    printf("votes_false=%u\n", votes_false);
    printf("equal_count=%u\n", equal_count);
    printf("majority_votes=%u\n", majority_votes);
    printf("decision=%u\n", decision);
    printf("p_value=%.17g\n", p_value);
    printf("verdict=%s\n", verdict);
    return 0;
}
