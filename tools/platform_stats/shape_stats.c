/* platform_shape_stats：在既有计时 CSV 上补三族形状/方差检验。
 * 只读取已有 CSV，不采集硬件；结果一律标 exploratory，不进任何 Holm 家族。
 * 退出码：0 成功、1 用法、2 数据或文件错误。 */

#define _POSIX_C_SOURCE 200809L
#ifdef __APPLE__
#define _DARWIN_C_SOURCE
#endif

#include <errno.h>
#include <math.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#define SHAPE_EXIT_USAGE 1
#define SHAPE_EXIT_DATA 2
#define SHAPE_ALPHA 0.05
#define SHAPE_GROUP_COUNT 2u
#define SHAPE_WIDE_COLUMN_COUNT 2u
#define SHAPE_LONG_REQUIRED_COLUMN_COUNT 5u
#define SHAPE_LONG_COLUMN_CAPACITY 6u
#define SHAPE_MINIMUM_CLASS_SAMPLE_COUNT 2u
#define SHAPE_MAXIMUM_SAMPLE_COUNT 1000000u
#define SHAPE_LINE_CAPACITY_BYTES 4096u
#define SHAPE_NAME_CAPACITY_BYTES 256u
#define SHAPE_TEST_COUNT 4u

struct shape_sample_set {
    int64_t *class_zero_nanoseconds;
    int64_t *class_ones_nanoseconds;
    size_t class_zero_count;
    size_t class_ones_count;
};

struct shape_test_result {
    double statistic;
    double p_value;
    size_t n0;
    size_t n1;
};

struct shape_tagged_sample {
    int64_t elapsed_nanoseconds;
    unsigned class_index;
};

/* 长表表头前五列必须逐字一致；time_unit 是可选第六列。 */
static const char *const shape_long_required_header[SHAPE_LONG_REQUIRED_COLUMN_COUNT] = {
    "run_id",
    "implementation",
    "input_category",
    "sample_index",
    "elapsed_nanoseconds",
};

static void print_usage(void)
{
    fputs("usage: platform_shape_stats --input <csv> --format wide|long --output <out.csv> "
          "--meta <meta.txt> [--label <name>]\n",
        stderr);
}

/* 取值支持 `--flag value` 与 `--flag=value` 两种写法，其余一律判用法错误。 */
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

/* 按逗号切分一行；返回字段数，0 表示行内有引号或 CR，或字段数超过容量。 */
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

/* 纳秒列只接受非负十进制整数；超大值同样拒绝，避免溢出成负数。 */
static int parse_integer_nanoseconds(const char *text, int64_t *value)
{
    if (*text == '\0') {
        return 1;
    }
    for (const char *cursor = text; *cursor != '\0'; ++cursor) {
        if (*cursor < '0' || *cursor > '9') {
            return 1;
        }
    }
    errno = 0;
    char *end = NULL;
    unsigned long long parsed_value = strtoull(text, &end, 10);
    if (errno != 0 || end == text || *end != '\0' || parsed_value > (unsigned long long)INT64_MAX) {
        return 1;
    }
    *value = (int64_t)parsed_value;
    return 0;
}

/* 去掉行尾换行；行超长或含 CR 时返回 1，由调用方统一按数据错误处理。 */
static int strip_line_ending(char *line, size_t capacity, FILE *input_stream, size_t line_number)
{
    size_t line_bytes = strlen(line);
    if (line_bytes > 0u && line[line_bytes - 1u] == '\n') {
        line[line_bytes - 1u] = '\0';
    } else if (!feof(input_stream)) {
        fprintf(stderr, "error: line %zu exceeds %u bytes\n", line_number, (unsigned)capacity);
        return 1;
    }
    if (strchr(line, '\r') != NULL) {
        fprintf(stderr, "error: line %zu uses CR or CRLF line endings\n", line_number);
        return 1;
    }
    return 0;
}

static int allocate_sample_arrays(struct shape_sample_set *sample_set)
{
    sample_set->class_zero_nanoseconds = calloc(SHAPE_MAXIMUM_SAMPLE_COUNT, sizeof(int64_t));
    sample_set->class_ones_nanoseconds = calloc(SHAPE_MAXIMUM_SAMPLE_COUNT, sizeof(int64_t));
    if (sample_set->class_zero_nanoseconds == NULL || sample_set->class_ones_nanoseconds == NULL) {
        fprintf(stderr, "error: cannot allocate sample arrays\n");
        free(sample_set->class_zero_nanoseconds);
        free(sample_set->class_ones_nanoseconds);
        sample_set->class_zero_nanoseconds = NULL;
        sample_set->class_ones_nanoseconds = NULL;
        return 1;
    }
    return 0;
}

static void release_sample_arrays(struct shape_sample_set *sample_set)
{
    free(sample_set->class_zero_nanoseconds);
    free(sample_set->class_ones_nanoseconds);
    sample_set->class_zero_nanoseconds = NULL;
    sample_set->class_ones_nanoseconds = NULL;
    sample_set->class_zero_count = 0u;
    sample_set->class_ones_count = 0u;
}

/* 宽表：首行两个非空类名，随后每行两列整数纳秒，空行跳过。 */
static int
load_wide_csv(FILE *input_stream, const char *input_path, struct shape_sample_set *sample_set)
{
    char line[SHAPE_LINE_CAPACITY_BYTES];
    char *fields[SHAPE_WIDE_COLUMN_COUNT];
    size_t line_number = 0u;
    if (fgets(line, (int)sizeof(line), input_stream) == NULL) {
        fprintf(stderr, "error: input %s is empty\n", input_path);
        return SHAPE_EXIT_DATA;
    }
    ++line_number;
    if (strip_line_ending(line, sizeof(line), input_stream, line_number) != 0) {
        return SHAPE_EXIT_DATA;
    }
    size_t field_count = split_fields(line, fields, SHAPE_WIDE_COLUMN_COUNT);
    if (field_count != SHAPE_WIDE_COLUMN_COUNT || fields[0][0] == '\0' || fields[1][0] == '\0') {
        fprintf(stderr, "error: line %zu is not a two-name wide header\n", line_number);
        return SHAPE_EXIT_DATA;
    }
    if (allocate_sample_arrays(sample_set) != 0) {
        return SHAPE_EXIT_DATA;
    }
    size_t row_count = 0u;
    int status = 0;
    while (fgets(line, (int)sizeof(line), input_stream) != NULL) {
        ++line_number;
        if (strip_line_ending(line, sizeof(line), input_stream, line_number) != 0) {
            status = SHAPE_EXIT_DATA;
            break;
        }
        /* 空行按规格跳过，不计入任何一类。 */
        if (line[0] == '\0') {
            continue;
        }
        field_count = split_fields(line, fields, SHAPE_WIDE_COLUMN_COUNT);
        if (field_count != SHAPE_WIDE_COLUMN_COUNT) {
            fprintf(stderr,
                "error: line %zu has %zu fields, expected %u\n",
                line_number,
                field_count,
                (unsigned)SHAPE_WIDE_COLUMN_COUNT);
            status = SHAPE_EXIT_DATA;
            break;
        }
        int64_t class_zero_nanoseconds = 0;
        int64_t class_ones_nanoseconds = 0;
        if (parse_integer_nanoseconds(fields[0], &class_zero_nanoseconds) != 0 ||
            parse_integer_nanoseconds(fields[1], &class_ones_nanoseconds) != 0) {
            fprintf(stderr, "error: line %zu has a non-integer nanosecond value\n", line_number);
            status = SHAPE_EXIT_DATA;
            break;
        }
        if (row_count == SHAPE_MAXIMUM_SAMPLE_COUNT) {
            fprintf(stderr,
                "error: more than %u wide rows\n",
                (unsigned)SHAPE_MAXIMUM_SAMPLE_COUNT);
            status = SHAPE_EXIT_DATA;
            break;
        }
        sample_set->class_zero_nanoseconds[row_count] = class_zero_nanoseconds;
        sample_set->class_ones_nanoseconds[row_count] = class_ones_nanoseconds;
        ++row_count;
    }
    if (status == 0 && ferror(input_stream)) {
        fprintf(stderr, "error: cannot read input %s\n", input_path);
        status = SHAPE_EXIT_DATA;
    }
    if (status == 0 && row_count < SHAPE_MINIMUM_CLASS_SAMPLE_COUNT) {
        fprintf(stderr,
            "error: input %s has %zu wide rows, at least %u required\n",
            input_path,
            row_count,
            (unsigned)SHAPE_MINIMUM_CLASS_SAMPLE_COUNT);
        status = SHAPE_EXIT_DATA;
    }
    if (status != 0) {
        release_sample_arrays(sample_set);
        return status;
    }
    sample_set->class_zero_count = row_count;
    sample_set->class_ones_count = row_count;
    return 0;
}

/* 长表：按 input_category 分组，必须恰好两类；类别名按首次出现顺序固定为类 0/类 1。 */
static int
load_long_csv(FILE *input_stream, const char *input_path, struct shape_sample_set *sample_set)
{
    char line[SHAPE_LINE_CAPACITY_BYTES];
    char *fields[SHAPE_LONG_COLUMN_CAPACITY];
    char category_names[SHAPE_GROUP_COUNT][SHAPE_NAME_CAPACITY_BYTES];
    size_t category_count = 0u;
    size_t line_number = 0u;
    if (fgets(line, (int)sizeof(line), input_stream) == NULL) {
        fprintf(stderr, "error: input %s is empty\n", input_path);
        return SHAPE_EXIT_DATA;
    }
    ++line_number;
    if (strip_line_ending(line, sizeof(line), input_stream, line_number) != 0) {
        return SHAPE_EXIT_DATA;
    }
    size_t field_count = split_fields(line, fields, SHAPE_LONG_COLUMN_CAPACITY);
    if (field_count != SHAPE_LONG_REQUIRED_COLUMN_COUNT &&
        field_count != SHAPE_LONG_REQUIRED_COLUMN_COUNT + 1u) {
        fprintf(stderr, "error: line %zu is not a valid long-table header\n", line_number);
        return SHAPE_EXIT_DATA;
    }
    for (size_t column_index = 0u; column_index < SHAPE_LONG_REQUIRED_COLUMN_COUNT;
        ++column_index) {
        if (strcmp(fields[column_index], shape_long_required_header[column_index]) != 0) {
            fprintf(stderr, "error: line %zu has an unexpected long-table header\n", line_number);
            return SHAPE_EXIT_DATA;
        }
    }
    if (field_count == SHAPE_LONG_REQUIRED_COLUMN_COUNT + 1u &&
        strcmp(fields[SHAPE_LONG_REQUIRED_COLUMN_COUNT], "time_unit") != 0) {
        fprintf(stderr, "error: line %zu has an unexpected time_unit column\n", line_number);
        return SHAPE_EXIT_DATA;
    }
    size_t expected_field_count = field_count;
    if (allocate_sample_arrays(sample_set) != 0) {
        return SHAPE_EXIT_DATA;
    }
    int status = 0;
    while (fgets(line, (int)sizeof(line), input_stream) != NULL) {
        ++line_number;
        if (strip_line_ending(line, sizeof(line), input_stream, line_number) != 0) {
            status = SHAPE_EXIT_DATA;
            break;
        }
        field_count = split_fields(line, fields, SHAPE_LONG_COLUMN_CAPACITY);
        if (field_count != expected_field_count || fields[0][0] == '\0' || fields[1][0] == '\0' ||
            fields[2][0] == '\0') {
            fprintf(stderr, "error: line %zu has an invalid long-table row\n", line_number);
            status = SHAPE_EXIT_DATA;
            break;
        }
        int64_t sample_index = 0;
        int64_t elapsed_nanoseconds = 0;
        if (parse_integer_nanoseconds(fields[3], &sample_index) != 0 ||
            parse_integer_nanoseconds(fields[4], &elapsed_nanoseconds) != 0) {
            fprintf(stderr,
                "error: line %zu has a non-integer index or nanosecond value\n",
                line_number);
            status = SHAPE_EXIT_DATA;
            break;
        }
        if (expected_field_count == SHAPE_LONG_REQUIRED_COLUMN_COUNT + 1u &&
            strcmp(fields[SHAPE_LONG_REQUIRED_COLUMN_COUNT], "ns") != 0) {
            fprintf(stderr, "error: line %zu does not use the ns time unit\n", line_number);
            status = SHAPE_EXIT_DATA;
            break;
        }
        size_t category_index = SHAPE_GROUP_COUNT;
        for (size_t known_index = 0u; known_index < category_count; ++known_index) {
            if (strcmp(category_names[known_index], fields[2]) == 0) {
                category_index = known_index;
                break;
            }
        }
        if (category_index == SHAPE_GROUP_COUNT) {
            if (category_count == SHAPE_GROUP_COUNT) {
                fprintf(stderr,
                    "error: input %s has more than %u input_category values\n",
                    input_path,
                    (unsigned)SHAPE_GROUP_COUNT);
                status = SHAPE_EXIT_DATA;
                break;
            }
            if (strlen(fields[2]) >= SHAPE_NAME_CAPACITY_BYTES) {
                fprintf(stderr, "error: line %zu has an over-long input_category\n", line_number);
                status = SHAPE_EXIT_DATA;
                break;
            }
            memcpy(category_names[category_count], fields[2], strlen(fields[2]) + 1u);
            category_index = category_count;
            ++category_count;
        }
        size_t class_count =
            category_index == 0u ? sample_set->class_zero_count : sample_set->class_ones_count;
        if (class_count == SHAPE_MAXIMUM_SAMPLE_COUNT) {
            fprintf(stderr,
                "error: more than %u samples in one class\n",
                (unsigned)SHAPE_MAXIMUM_SAMPLE_COUNT);
            status = SHAPE_EXIT_DATA;
            break;
        }
        if (category_index == 0u) {
            sample_set->class_zero_nanoseconds[class_count] = elapsed_nanoseconds;
            ++sample_set->class_zero_count;
        } else {
            sample_set->class_ones_nanoseconds[class_count] = elapsed_nanoseconds;
            ++sample_set->class_ones_count;
        }
    }
    if (status == 0 && ferror(input_stream)) {
        fprintf(stderr, "error: cannot read input %s\n", input_path);
        status = SHAPE_EXIT_DATA;
    }
    if (status == 0 && category_count != SHAPE_GROUP_COUNT) {
        fprintf(stderr,
            "error: input %s has %zu input_category values, exactly %u required\n",
            input_path,
            category_count,
            (unsigned)SHAPE_GROUP_COUNT);
        status = SHAPE_EXIT_DATA;
    }
    if (status == 0 &&
        (sample_set->class_zero_count < SHAPE_MINIMUM_CLASS_SAMPLE_COUNT ||
            sample_set->class_ones_count < SHAPE_MINIMUM_CLASS_SAMPLE_COUNT)) {
        fprintf(stderr,
            "error: input %s has a class with fewer than %u samples\n",
            input_path,
            (unsigned)SHAPE_MINIMUM_CLASS_SAMPLE_COUNT);
        status = SHAPE_EXIT_DATA;
    }
    if (status != 0) {
        release_sample_arrays(sample_set);
        return status;
    }
    return 0;
}

static int compare_integer_nanoseconds(const void *left_value, const void *right_value)
{
    int64_t left_nanoseconds = *(const int64_t *)left_value;
    int64_t right_nanoseconds = *(const int64_t *)right_value;
    if (left_nanoseconds < right_nanoseconds) {
        return -1;
    }
    if (left_nanoseconds > right_nanoseconds) {
        return 1;
    }
    return 0;
}

static int compare_tagged_sample(const void *left_value, const void *right_value)
{
    int64_t left_nanoseconds =
        ((const struct shape_tagged_sample *)left_value)->elapsed_nanoseconds;
    int64_t right_nanoseconds =
        ((const struct shape_tagged_sample *)right_value)->elapsed_nanoseconds;
    if (left_nanoseconds < right_nanoseconds) {
        return -1;
    }
    if (left_nanoseconds > right_nanoseconds) {
        return 1;
    }
    return 0;
}

static int64_t *copy_sorted_integer_nanoseconds(const int64_t *nanoseconds, size_t sample_count)
{
    int64_t *sorted_nanoseconds = malloc(sample_count * sizeof(int64_t));
    if (sorted_nanoseconds == NULL) {
        return NULL;
    }
    memcpy(sorted_nanoseconds, nanoseconds, sample_count * sizeof(int64_t));
    qsort(sorted_nanoseconds, sample_count, sizeof(int64_t), compare_integer_nanoseconds);
    return sorted_nanoseconds;
}

/* 中位数：偶数个取中间两数平均；调用前样本数已由加载阶段保证至少为 2。 */
static double median_nanoseconds(const int64_t *sorted_nanoseconds, size_t sample_count)
{
    size_t middle_index = sample_count / 2u;
    if ((sample_count % 2u) == 1u) {
        return (double)sorted_nanoseconds[middle_index];
    }
    return ((double)sorted_nanoseconds[middle_index - 1u] +
               (double)sorted_nanoseconds[middle_index]) /
        2.0;
}

/* Brown–Forsythe：z_ij = |x_ij - median_j|，W = (N-2) * Σn_j(z̄_j-z̄)^2 / ΣΣ(z_ij-z̄_j)^2。
 * p 用大样本正态近似 erfc(sqrt(W)/sqrt(2))，不称精确有限样本分布。 */
static int brown_forsythe_test(const struct shape_sample_set *sample_set,
    struct shape_test_result *result)
{
    size_t class_zero_count = sample_set->class_zero_count;
    size_t class_ones_count = sample_set->class_ones_count;
    size_t total_count = class_zero_count + class_ones_count;
    int64_t *sorted_class_zero =
        copy_sorted_integer_nanoseconds(sample_set->class_zero_nanoseconds, class_zero_count);
    int64_t *sorted_class_ones =
        copy_sorted_integer_nanoseconds(sample_set->class_ones_nanoseconds, class_ones_count);
    if (sorted_class_zero == NULL || sorted_class_ones == NULL) {
        free(sorted_class_zero);
        free(sorted_class_ones);
        fprintf(stderr, "error: cannot allocate median copies\n");
        return 1;
    }
    double median_class_zero = median_nanoseconds(sorted_class_zero, class_zero_count);
    double median_class_ones = median_nanoseconds(sorted_class_ones, class_ones_count);
    double class_zero_absolute_sum = 0.0;
    for (size_t sample_index = 0u; sample_index < class_zero_count; ++sample_index) {
        class_zero_absolute_sum +=
            fabs((double)sample_set->class_zero_nanoseconds[sample_index] - median_class_zero);
    }
    double class_ones_absolute_sum = 0.0;
    for (size_t sample_index = 0u; sample_index < class_ones_count; ++sample_index) {
        class_ones_absolute_sum +=
            fabs((double)sample_set->class_ones_nanoseconds[sample_index] - median_class_ones);
    }
    double class_zero_absolute_mean = class_zero_absolute_sum / (double)class_zero_count;
    double class_ones_absolute_mean = class_ones_absolute_sum / (double)class_ones_count;
    double overall_absolute_mean =
        (class_zero_absolute_sum + class_ones_absolute_sum) / (double)total_count;
    double class_zero_deviation = class_zero_absolute_mean - overall_absolute_mean;
    double class_ones_deviation = class_ones_absolute_mean - overall_absolute_mean;
    double numerator = (double)(total_count - 2u) *
        ((double)class_zero_count * class_zero_deviation * class_zero_deviation +
            (double)class_ones_count * class_ones_deviation * class_ones_deviation);
    double denominator = 0.0;
    for (size_t sample_index = 0u; sample_index < class_zero_count; ++sample_index) {
        double deviation =
            fabs((double)sample_set->class_zero_nanoseconds[sample_index] - median_class_zero) -
            class_zero_absolute_mean;
        denominator += deviation * deviation;
    }
    for (size_t sample_index = 0u; sample_index < class_ones_count; ++sample_index) {
        double deviation =
            fabs((double)sample_set->class_ones_nanoseconds[sample_index] - median_class_ones) -
            class_ones_absolute_mean;
        denominator += deviation * deviation;
    }
    double statistic = 0.0;
    double p_value = 1.0;
    if (denominator > 0.0) {
        statistic = numerator / denominator;
        if (statistic < 0.0) {
            statistic = 0.0;
        }
        p_value = erfc(sqrt(statistic) / sqrt(2.0));
    }
    /* denominator 为 0 表示两类到各自中位数的绝对偏差完全一致（全等时 z 全为 0），
     * W 无定义；此时按“未检出差异”输出 0/1，并保留上面的大样本近似口径。 */
    result->statistic = statistic;
    result->p_value = p_value;
    result->n0 = class_zero_count;
    result->n1 = class_ones_count;
    free(sorted_class_zero);
    free(sorted_class_ones);
    return 0;
}

/* 双样本 KS：合并排序后只在并列值整组处理完时更新经验分布，避免并列被错算成阶梯。
 * p 用渐近式 min(1, 2*exp(-2*n_eff*D^2))，n_eff = n0*n1/(n0+n1)。 */
static int ks_two_sample_test(const struct shape_sample_set *sample_set,
    struct shape_test_result *result)
{
    size_t class_zero_count = sample_set->class_zero_count;
    size_t class_ones_count = sample_set->class_ones_count;
    size_t total_count = class_zero_count + class_ones_count;
    struct shape_tagged_sample *tagged_samples =
        calloc(total_count, sizeof(struct shape_tagged_sample));
    if (tagged_samples == NULL) {
        fprintf(stderr, "error: cannot allocate pooled samples\n");
        return 1;
    }
    for (size_t sample_index = 0u; sample_index < class_zero_count; ++sample_index) {
        tagged_samples[sample_index].elapsed_nanoseconds =
            sample_set->class_zero_nanoseconds[sample_index];
        tagged_samples[sample_index].class_index = 0u;
    }
    for (size_t sample_index = 0u; sample_index < class_ones_count; ++sample_index) {
        tagged_samples[class_zero_count + sample_index].elapsed_nanoseconds =
            sample_set->class_ones_nanoseconds[sample_index];
        tagged_samples[class_zero_count + sample_index].class_index = 1u;
    }
    qsort(tagged_samples, total_count, sizeof(struct shape_tagged_sample), compare_tagged_sample);
    size_t class_zero_seen = 0u;
    size_t class_ones_seen = 0u;
    size_t sample_index = 0u;
    double maximum_distance = 0.0;
    while (sample_index < total_count) {
        int64_t current_nanoseconds = tagged_samples[sample_index].elapsed_nanoseconds;
        while (sample_index < total_count &&
            tagged_samples[sample_index].elapsed_nanoseconds == current_nanoseconds) {
            if (tagged_samples[sample_index].class_index == 0u) {
                ++class_zero_seen;
            } else {
                ++class_ones_seen;
            }
            ++sample_index;
        }
        double class_zero_fraction = (double)class_zero_seen / (double)class_zero_count;
        double class_ones_fraction = (double)class_ones_seen / (double)class_ones_count;
        double distance = fabs(class_zero_fraction - class_ones_fraction);
        if (distance > maximum_distance) {
            maximum_distance = distance;
        }
    }
    double effective_sample_count =
        ((double)class_zero_count * (double)class_ones_count) / (double)total_count;
    double p_value = 2.0 * exp(-2.0 * effective_sample_count * maximum_distance * maximum_distance);
    if (p_value > 1.0) {
        p_value = 1.0;
    }
    result->statistic = maximum_distance;
    result->p_value = p_value;
    result->n0 = class_zero_count;
    result->n1 = class_ones_count;
    free(tagged_samples);
    return 0;
}

/* 类内二阶对照的半步矩：方差用无偏样本方差；半步只有 1 个样本时无法估计，记 0。 */
static void half_moments(const int64_t *nanoseconds,
    size_t start_index,
    size_t sample_count,
    double *mean_out,
    double *variance_out)
{
    double sum = 0.0;
    for (size_t sample_index = 0u; sample_index < sample_count; ++sample_index) {
        sum += (double)nanoseconds[start_index + sample_index];
    }
    double mean = sum / (double)sample_count;
    double square_sum = 0.0;
    for (size_t sample_index = 0u; sample_index < sample_count; ++sample_index) {
        double deviation = (double)nanoseconds[start_index + sample_index] - mean;
        square_sum += deviation * deviation;
    }
    double variance = sample_count > 1u ? square_sum / (double)(sample_count - 1u) : 0.0;
    *mean_out = mean;
    *variance_out = variance;
}

/* 类内二阶对照：按到达序对半劈，前半 vs 后半做 Welch t；p = erfc(|t|/sqrt(2))。
 * 两侧方差同为 0 时 Welch t 无定义，按任务口径输出 t=0、p=1。 */
static void within_class_second_order_test(const int64_t *nanoseconds,
    size_t sample_count,
    struct shape_test_result *result)
{
    size_t first_count = sample_count / 2u;
    size_t second_count = sample_count - first_count;
    double first_mean = 0.0;
    double first_variance = 0.0;
    double second_mean = 0.0;
    double second_variance = 0.0;
    half_moments(nanoseconds, 0u, first_count, &first_mean, &first_variance);
    half_moments(nanoseconds, first_count, second_count, &second_mean, &second_variance);
    double standard_error =
        sqrt(first_variance / (double)first_count + second_variance / (double)second_count);
    double statistic = 0.0;
    double p_value = 1.0;
    if (standard_error > 0.0) {
        statistic = (first_mean - second_mean) / standard_error;
        p_value = erfc(fabs(statistic) / sqrt(2.0));
    }
    result->statistic = statistic;
    result->p_value = p_value;
    result->n0 = first_count;
    result->n1 = second_count;
}

static int write_result_csv(const char *output_path,
    const struct shape_test_result results[SHAPE_TEST_COUNT])
{
    static const char *const test_names[SHAPE_TEST_COUNT] = {
        "brown_forsythe",
        "ks_two_sample",
        "within_class_second_order_zero",
        "within_class_second_order_ones",
    };
    FILE *output_file = fopen(output_path, "w");
    if (output_file == NULL) {
        fprintf(stderr, "error: cannot create %s\n", output_path);
        return SHAPE_EXIT_DATA;
    }
    int status = 0;
    if (fputs("test_name,statistic,p_value,n0,n1,verdict_exploratory\n", output_file) < 0) {
        status = SHAPE_EXIT_DATA;
    }
    for (size_t test_index = 0u; status == 0 && test_index < SHAPE_TEST_COUNT; ++test_index) {
        const char *verdict = results[test_index].p_value < (double)SHAPE_ALPHA ? "flag" : "clear";
        if (fprintf(output_file,
                "%s,%.15g,%.15g,%zu,%zu,%s\n",
                test_names[test_index],
                results[test_index].statistic,
                results[test_index].p_value,
                results[test_index].n0,
                results[test_index].n1,
                verdict) < 0) {
            status = SHAPE_EXIT_DATA;
        }
    }
    if (fclose(output_file) != 0) {
        status = SHAPE_EXIT_DATA;
    }
    if (status != 0) {
        fprintf(stderr, "error: cannot write %s\n", output_path);
        (void)remove(output_path);
    }
    return status;
}

static int write_meta(const char *meta_path,
    const char *input_path,
    const char *format,
    const char *label,
    const struct shape_sample_set *sample_set)
{
    FILE *meta_file = fopen(meta_path, "w");
    if (meta_file == NULL) {
        fprintf(stderr, "error: cannot create %s\n", meta_path);
        return SHAPE_EXIT_DATA;
    }
    int status = 0;
    if (label != NULL && fprintf(meta_file, "label=%s\n", label) < 0) {
        status = SHAPE_EXIT_DATA;
    }
    if (status == 0 && fprintf(meta_file, "input_path=%s\n", input_path) < 0) {
        status = SHAPE_EXIT_DATA;
    }
    if (status == 0 && fprintf(meta_file, "format=%s\n", format) < 0) {
        status = SHAPE_EXIT_DATA;
    }
    if (status == 0 &&
        fprintf(meta_file, "rows_class_zero=%zu\n", sample_set->class_zero_count) < 0) {
        status = SHAPE_EXIT_DATA;
    }
    if (status == 0 &&
        fprintf(meta_file, "rows_class_ones=%zu\n", sample_set->class_ones_count) < 0) {
        status = SHAPE_EXIT_DATA;
    }
    if (status == 0 && fprintf(meta_file, "alpha=%g\n", (double)SHAPE_ALPHA) < 0) {
        status = SHAPE_EXIT_DATA;
    }
    if (status == 0 && fputs("family=none_exploratory_only\n", meta_file) < 0) {
        status = SHAPE_EXIT_DATA;
    }
    if (status == 0 &&
        fputs("note=exploratory replay only; not in any Holm family\n", meta_file) < 0) {
        status = SHAPE_EXIT_DATA;
    }
    if (fclose(meta_file) != 0) {
        status = SHAPE_EXIT_DATA;
    }
    if (status != 0) {
        fprintf(stderr, "error: cannot write %s\n", meta_path);
        (void)remove(meta_path);
    }
    return status;
}

int main(int argument_count, char **argument_values)
{
    const char *input_path = NULL;
    const char *format = NULL;
    const char *output_path = NULL;
    const char *meta_path = NULL;
    const char *label = NULL;
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
                return SHAPE_EXIT_USAGE;
            }
            input_path = value;
            continue;
        }
        taken = take_argument_value(argument_count,
            argument_values,
            &argument_index,
            "--format",
            &value);
        if (taken == 0) {
            if (format != NULL) {
                print_usage();
                return SHAPE_EXIT_USAGE;
            }
            format = value;
            continue;
        }
        taken = take_argument_value(argument_count,
            argument_values,
            &argument_index,
            "--output",
            &value);
        if (taken == 0) {
            if (output_path != NULL) {
                print_usage();
                return SHAPE_EXIT_USAGE;
            }
            output_path = value;
            continue;
        }
        taken =
            take_argument_value(argument_count, argument_values, &argument_index, "--meta", &value);
        if (taken == 0) {
            if (meta_path != NULL) {
                print_usage();
                return SHAPE_EXIT_USAGE;
            }
            meta_path = value;
            continue;
        }
        taken = take_argument_value(argument_count,
            argument_values,
            &argument_index,
            "--label",
            &value);
        if (taken == 0) {
            if (label != NULL) {
                print_usage();
                return SHAPE_EXIT_USAGE;
            }
            label = value;
            continue;
        }
        print_usage();
        return SHAPE_EXIT_USAGE;
    }
    if (input_path == NULL || format == NULL || output_path == NULL || meta_path == NULL) {
        print_usage();
        return SHAPE_EXIT_USAGE;
    }
    if (strcmp(format, "wide") != 0 && strcmp(format, "long") != 0) {
        fprintf(stderr, "error: --format must be wide or long\n");
        return SHAPE_EXIT_USAGE;
    }
    FILE *input_stream = fopen(input_path, "r");
    if (input_stream == NULL) {
        fprintf(stderr, "error: cannot open input %s\n", input_path);
        return SHAPE_EXIT_DATA;
    }
    struct shape_sample_set sample_set = {0};
    int status = strcmp(format, "wide") == 0 ? load_wide_csv(input_stream, input_path, &sample_set)
                                             : load_long_csv(input_stream, input_path, &sample_set);
    if (fclose(input_stream) != 0 && status == 0) {
        fprintf(stderr, "error: cannot close input %s\n", input_path);
        status = SHAPE_EXIT_DATA;
    }
    if (status != 0) {
        release_sample_arrays(&sample_set);
        return status;
    }
    struct shape_test_result results[SHAPE_TEST_COUNT];
    status = brown_forsythe_test(&sample_set, &results[0]);
    if (status == 0) {
        status = ks_two_sample_test(&sample_set, &results[1]);
    }
    if (status == 0) {
        within_class_second_order_test(sample_set.class_zero_nanoseconds,
            sample_set.class_zero_count,
            &results[2]);
        within_class_second_order_test(sample_set.class_ones_nanoseconds,
            sample_set.class_ones_count,
            &results[3]);
    }
    if (status == 0) {
        status = write_result_csv(output_path, results);
    }
    if (status == 0) {
        status = write_meta(meta_path, input_path, format, label, &sample_set);
    }
    if (status == 0) {
        printf("label=%s rows_class_zero=%zu rows_class_ones=%zu alpha=%g\n",
            label != NULL ? label : "(none)",
            sample_set.class_zero_count,
            sample_set.class_ones_count,
            (double)SHAPE_ALPHA);
    } else {
        /* 元数据写失败时不留半套输出；已写出的 CSV 一并撤销。 */
        (void)remove(output_path);
    }
    release_sample_arrays(&sample_set);
    return status;
}
