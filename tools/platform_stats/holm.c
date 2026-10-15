/* platform_holm：把逐成员 p 值组成预注册 Holm 家族，并做固定效应合并。
 * 只读取已有 CSV，不采集硬件、不接触密码内核，因此只依赖标准库。 */

#define _POSIX_C_SOURCE 200809L
#ifdef __APPLE__
#define _DARWIN_C_SOURCE
#endif

#include <assert.h>
#include <errno.h>
#include <math.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/stat.h>
#include <unistd.h>

#define HOLM_EXIT_USAGE 1
#define HOLM_EXIT_DATA 2
#define HOLM_Z_95 1.96
#define HOLM_LINE_CAPACITY_BYTES 4096u
#define HOLM_PATH_CAPACITY_BYTES 1024u
#define HOLM_NAME_CAPACITY_BYTES 64u
#define HOLM_MAXIMUM_RECORD_COUNT 100000u
#define HOLM_MAXIMUM_FAMILY_COUNT 1000u
#define HOLM_COLUMN_COUNT 11u

/* 输入表头必须逐字一致；CSV 本身无引号，名称里不允许逗号或空白。 */
static const char *const holm_input_header[HOLM_COLUMN_COUNT] = {
    "family_id",
    "member_id",
    "mean0_ns",
    "mean1_ns",
    "sd0_ns",
    "sd1_ns",
    "n0",
    "n1",
    "p_two_sided",
    "ci95_low_ns",
    "ci95_high_ns",
};

struct holm_record {
    char family_id[HOLM_NAME_CAPACITY_BYTES];
    char member_id[HOLM_NAME_CAPACITY_BYTES];
    double mean0_nanoseconds;
    double mean1_nanoseconds;
    double sd0_nanoseconds;
    double sd1_nanoseconds;
    double p_two_sided;
    double ci95_low_nanoseconds;
    double ci95_high_nanoseconds;
    uint64_t n0;
    uint64_t n1;
};

struct holm_family {
    char family_id[HOLM_NAME_CAPACITY_BYTES];
    size_t member_count;
    size_t *record_indices;
};

struct holm_family_summary {
    double pooled_effect_nanoseconds;
    double pooled_se_nanoseconds;
    double ci95_low_nanoseconds;
    double ci95_high_nanoseconds;
    double q_statistic;
    double i2_percent;
};

/* 固定效应成员内方差 sd0^2/n0 + sd1^2/n1；n 为零的输入已在读入阶段拒绝。 */
static double member_variance_nanoseconds_squared(const struct holm_record *record)
{
    return record->sd0_nanoseconds * record->sd0_nanoseconds / (double)record->n0 +
        record->sd1_nanoseconds * record->sd1_nanoseconds / (double)record->n1;
}

static void print_usage(void)
{
    fputs("usage: platform_holm --input <members.csv> --output-dir <NEW_DIR> --alpha <0..1>\n",
        stderr);
}

static int has_blank(const char *text)
{
    for (const char *cursor = text; *cursor != '\0'; ++cursor) {
        if (*cursor == ' ' || *cursor == '\t') {
            return 1;
        }
    }
    return 0;
}

static int is_identifier(const char *text)
{
    if (*text == '\0' || has_blank(text)) {
        return 0;
    }
    for (const char *cursor = text; *cursor != '\0'; ++cursor) {
        if (*cursor == ',') {
            return 0;
        }
    }
    return 1;
}

static int parse_decimal(const char *text, double *value)
{
    if (*text == '\0' || has_blank(text)) {
        return 1;
    }
    /* 十进制口径：nan/inf/十六进制浮点都不是十进制数字，交给文本字符集先拒绝。 */
    for (const char *cursor = text; *cursor != '\0'; ++cursor) {
        if ((*cursor < '0' || *cursor > '9') && *cursor != '+' && *cursor != '-' &&
            *cursor != '.' && *cursor != 'e' && *cursor != 'E') {
            return 1;
        }
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

static int parse_count(const char *text, uint64_t *value)
{
    if (*text == '\0' || has_blank(text)) {
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
    if (errno != 0 || end == text || *end != '\0') {
        return 1;
    }
    *value = (uint64_t)parsed_value;
    return 0;
}

/* 按逗号切分一行；返回字段数，0 表示行内有引号或 CR，或字段数超过容量。
 * CR 在调用方已经按「拒绝 CRLF」处理，这里再挡一次只为不让异常字节进入数值解析。 */
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
            fields[field_count] = cursor + 1;
            ++field_count;
        }
    }
    return field_count;
}

/* 拼出唯一合法表头，供首行校验和重复表头检测共用。 */
static void build_expected_header(char *destination, size_t capacity)
{
    size_t used_bytes = 0u;
    for (size_t column_index = 0u; column_index < HOLM_COLUMN_COUNT; ++column_index) {
        int written = snprintf(destination + used_bytes,
            capacity - used_bytes,
            "%s%s",
            column_index == 0u ? "" : ",",
            holm_input_header[column_index]);
        assert(written > 0 && (size_t)written < capacity - used_bytes);
        used_bytes += (size_t)written;
    }
}

static int copy_identifier(const char *text, char *destination, size_t capacity)
{
    if (!is_identifier(text) || strlen(text) >= capacity) {
        return 1;
    }
    memcpy(destination, text, strlen(text) + 1u);
    return 0;
}

static int read_record(char **fields, struct holm_record *record)
{
    if (copy_identifier(fields[0], record->family_id, sizeof(record->family_id)) != 0 ||
        copy_identifier(fields[1], record->member_id, sizeof(record->member_id)) != 0) {
        return 1;
    }
    if (parse_decimal(fields[2], &record->mean0_nanoseconds) != 0 ||
        parse_decimal(fields[3], &record->mean1_nanoseconds) != 0 ||
        parse_decimal(fields[4], &record->sd0_nanoseconds) != 0 ||
        parse_decimal(fields[5], &record->sd1_nanoseconds) != 0 ||
        parse_count(fields[6], &record->n0) != 0 || parse_count(fields[7], &record->n1) != 0 ||
        parse_decimal(fields[8], &record->p_two_sided) != 0 ||
        parse_decimal(fields[9], &record->ci95_low_nanoseconds) != 0 ||
        parse_decimal(fields[10], &record->ci95_high_nanoseconds) != 0) {
        return 1;
    }
    /* p 是概率：越界值静默夹到 [0,1] 会把非法输入洗成合法结果，因此直接拒绝。 */
    if (record->p_two_sided < 0.0 || record->p_two_sided > 1.0) {
        return 1;
    }
    if (record->sd0_nanoseconds < 0.0 || record->sd1_nanoseconds < 0.0) {
        return 1;
    }
    if (record->n0 == 0u || record->n1 == 0u) {
        return 1;
    }
    return 0;
}

static int load_members(const char *input_path, struct holm_record **records, size_t *record_count)
{
    FILE *input_file = fopen(input_path, "r");
    if (input_file == NULL) {
        fprintf(stderr, "error: cannot open input %s\n", input_path);
        return HOLM_EXIT_USAGE;
    }
    struct holm_record *loaded_records =
        calloc(HOLM_MAXIMUM_RECORD_COUNT, sizeof(struct holm_record));
    if (loaded_records == NULL) {
        fprintf(stderr, "error: cannot allocate member records\n");
        fclose(input_file);
        return HOLM_EXIT_USAGE;
    }
    char line[HOLM_LINE_CAPACITY_BYTES];
    char expected_header[HOLM_LINE_CAPACITY_BYTES];
    char *fields[HOLM_COLUMN_COUNT];
    build_expected_header(expected_header, sizeof(expected_header));
    size_t loaded_count = 0u;
    size_t line_number = 0u;
    int header_seen = 0;
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
                (unsigned)HOLM_LINE_CAPACITY_BYTES);
            status = HOLM_EXIT_DATA;
            break;
        }
        if (strchr(line, '\r') != NULL) {
            fprintf(stderr, "error: line %zu uses CR or CRLF line endings\n", line_number);
            status = HOLM_EXIT_DATA;
            break;
        }
        if (line[0] == '\0') {
            fprintf(stderr, "error: line %zu is blank\n", line_number);
            status = HOLM_EXIT_DATA;
            break;
        }
        if (!header_seen) {
            if (strcmp(line, expected_header) != 0) {
                fprintf(stderr, "error: line %zu is not the expected header\n", line_number);
                status = HOLM_EXIT_DATA;
                break;
            }
            header_seen = 1;
            continue;
        }
        /* 重复表头本身就是一行非法数值，单独报出来便于定位拼接错误。 */
        if (strcmp(line, expected_header) == 0) {
            fprintf(stderr, "error: line %zu repeats the input header\n", line_number);
            status = HOLM_EXIT_DATA;
            break;
        }
        size_t field_count = split_fields(line, fields, HOLM_COLUMN_COUNT);
        if (field_count != HOLM_COLUMN_COUNT) {
            fprintf(stderr,
                "error: line %zu has %zu fields, expected %u\n",
                line_number,
                field_count,
                (unsigned)HOLM_COLUMN_COUNT);
            status = HOLM_EXIT_DATA;
            break;
        }
        if (loaded_count == HOLM_MAXIMUM_RECORD_COUNT) {
            fprintf(stderr,
                "error: more than %u member rows\n",
                (unsigned)HOLM_MAXIMUM_RECORD_COUNT);
            status = HOLM_EXIT_USAGE;
            break;
        }
        if (read_record(fields, &loaded_records[loaded_count]) != 0) {
            fprintf(stderr, "error: line %zu has an invalid field value\n", line_number);
            status = HOLM_EXIT_DATA;
            break;
        }
        ++loaded_count;
    }
    fclose(input_file);
    if (status == 0) {
        if (!header_seen) {
            fprintf(stderr, "error: input %s is empty\n", input_path);
            status = HOLM_EXIT_DATA;
        } else if (loaded_count == 0u) {
            fprintf(stderr, "error: input %s has no member rows\n", input_path);
            status = HOLM_EXIT_DATA;
        }
    }
    if (status != 0) {
        free(loaded_records);
        return status;
    }
    *records = loaded_records;
    *record_count = loaded_count;
    return 0;
}

static int build_families(const struct holm_record *records,
    size_t record_count,
    struct holm_family *families,
    size_t *family_count)
{
    size_t built_count = 0u;
    for (size_t record_index = 0u; record_index < record_count; ++record_index) {
        size_t family_index = built_count;
        for (size_t candidate_index = 0u; candidate_index < built_count; ++candidate_index) {
            if (strcmp(families[candidate_index].family_id, records[record_index].family_id) == 0) {
                family_index = candidate_index;
                break;
            }
        }
        if (family_index == built_count) {
            if (built_count == HOLM_MAXIMUM_FAMILY_COUNT) {
                fprintf(stderr,
                    "error: more than %u families\n",
                    (unsigned)HOLM_MAXIMUM_FAMILY_COUNT);
                return HOLM_EXIT_USAGE;
            }
            memcpy(families[built_count].family_id,
                records[record_index].family_id,
                sizeof(families[built_count].family_id));
            families[built_count].member_count = 0u;
            families[built_count].record_indices = NULL;
            ++built_count;
        }
    }
    for (size_t record_index = 0u; record_index < record_count; ++record_index) {
        for (size_t family_index = 0u; family_index < built_count; ++family_index) {
            if (strcmp(families[family_index].family_id, records[record_index].family_id) == 0) {
                ++families[family_index].member_count;
                break;
            }
        }
    }
    *family_count = built_count;
    return 0;
}

static int collect_family_members(const struct holm_record *records,
    size_t record_count,
    struct holm_family *family)
{
    family->record_indices = calloc(family->member_count, sizeof(size_t));
    if (family->record_indices == NULL) {
        fprintf(stderr, "error: cannot allocate family members\n");
        return HOLM_EXIT_USAGE;
    }
    size_t member_index = 0u;
    for (size_t record_index = 0u; record_index < record_count; ++record_index) {
        if (strcmp(records[record_index].family_id, family->family_id) == 0) {
            family->record_indices[member_index] = record_index;
            ++member_index;
        }
    }
    return 0;
}

/* 稳定性由严格小于决定：p 相同则保持输入出现顺序，不交换。 */
static void sort_members_by_p(const struct holm_record *records, struct holm_family *family)
{
    for (size_t left = 0u; left + 1u < family->member_count; ++left) {
        size_t current = left + 1u;
        size_t current_record = family->record_indices[current];
        while (current > 0u) {
            size_t previous_record = family->record_indices[current - 1u];
            if (records[current_record].p_two_sided < records[previous_record].p_two_sided) {
                family->record_indices[current] = previous_record;
                --current;
            } else {
                break;
            }
        }
        family->record_indices[current] = current_record;
    }
}

/* 固定效应合并：theta = mean0-mean1，w = 1/se^2，pooled = sum(w*theta)/sum(w)。
 * se 为零的成员已在读入阶段整体拒绝，这里不会出现权重无定义或除零。 */
static void summarize_family(const struct holm_record *records,
    const struct holm_family *family,
    struct holm_family_summary *summary)
{
    double weight_total = 0.0;
    double weighted_effect_total = 0.0;
    for (size_t member_index = 0u; member_index < family->member_count; ++member_index) {
        const struct holm_record *record = &records[family->record_indices[member_index]];
        double weight = 1.0 / member_variance_nanoseconds_squared(record);
        double effect = record->mean0_nanoseconds - record->mean1_nanoseconds;
        weight_total += weight;
        weighted_effect_total += weight * effect;
    }
    double pooled_effect = weighted_effect_total / weight_total;
    double pooled_se = 1.0 / sqrt(weight_total);
    double q_statistic = 0.0;
    for (size_t member_index = 0u; member_index < family->member_count; ++member_index) {
        const struct holm_record *record = &records[family->record_indices[member_index]];
        double weight = 1.0 / member_variance_nanoseconds_squared(record);
        double deviation = (record->mean0_nanoseconds - record->mean1_nanoseconds) - pooled_effect;
        q_statistic += weight * deviation * deviation;
    }
    double degrees_of_freedom = (double)(family->member_count - 1u);
    double i2_percent = 0.0;
    if (q_statistic > degrees_of_freedom && q_statistic > 0.0) {
        i2_percent = (q_statistic - degrees_of_freedom) / q_statistic * 100.0;
    }
    /* m = 1 时 df = 0、Q = 0，I2 按定义记 0，置信区间退化为单成员正态区间。 */
    summary->pooled_effect_nanoseconds = pooled_effect;
    summary->pooled_se_nanoseconds = pooled_se;
    summary->ci95_low_nanoseconds = pooled_effect - HOLM_Z_95 * pooled_se;
    summary->ci95_high_nanoseconds = pooled_effect + HOLM_Z_95 * pooled_se;
    summary->q_statistic = q_statistic;
    summary->i2_percent = i2_percent;
}

static int write_holm_csv(const char *output_directory,
    const struct holm_record *records,
    const struct holm_family *families,
    size_t family_count,
    const double *adjusted_p_values,
    const int *rejected,
    double alpha)
{
    char path[HOLM_PATH_CAPACITY_BYTES];
    (void)snprintf(path, sizeof(path), "%s/holm.csv", output_directory);
    FILE *output_file = fopen(path, "w");
    if (output_file == NULL) {
        fprintf(stderr, "error: cannot create %s\n", path);
        return HOLM_EXIT_USAGE;
    }
    fputs("family_id,member_id,raw_p,rank,threshold,adjusted_p,reject\n", output_file);
    int status = 0;
    for (size_t family_index = 0u; family_index < family_count; ++family_index) {
        const struct holm_family *family = &families[family_index];
        for (size_t rank_index = 0u; rank_index < family->member_count; ++rank_index) {
            size_t record_index = family->record_indices[rank_index];
            size_t rank = rank_index + 1u;
            double threshold = alpha / (double)(family->member_count - rank_index);
            if (fprintf(output_file,
                    "%s,%s,%.15g,%zu,%.15g,%.15g,%d\n",
                    family->family_id,
                    records[record_index].member_id,
                    records[record_index].p_two_sided,
                    rank,
                    threshold,
                    adjusted_p_values[record_index],
                    rejected[record_index]) < 0) {
                status = HOLM_EXIT_USAGE;
                break;
            }
        }
        if (status != 0) {
            break;
        }
    }
    if (fclose(output_file) != 0) {
        status = HOLM_EXIT_USAGE;
    }
    if (status != 0) {
        fprintf(stderr, "error: cannot write %s\n", path);
    }
    return status;
}

static int write_pooled_csv(const char *output_directory,
    const struct holm_family *families,
    size_t family_count,
    struct holm_family_summary **const summaries)
{
    char path[HOLM_PATH_CAPACITY_BYTES];
    (void)snprintf(path, sizeof(path), "%s/pooled.csv", output_directory);
    FILE *output_file = fopen(path, "w");
    if (output_file == NULL) {
        fprintf(stderr, "error: cannot create %s\n", path);
        return HOLM_EXIT_USAGE;
    }
    fputs("family_id,m,pooled_effect_ns,pooled_se_ns,ci95_low_ns,ci95_high_ns,q_statistic,df,"
          "i2_percent\n",
        output_file);
    int status = 0;
    for (size_t family_index = 0u; family_index < family_count; ++family_index) {
        const struct holm_family *family = &families[family_index];
        if (fprintf(output_file,
                "%s,%zu,%.15g,%.15g,%.15g,%.15g,%.15g,%zu,%.15g\n",
                family->family_id,
                family->member_count,
                summaries[family_index]->pooled_effect_nanoseconds,
                summaries[family_index]->pooled_se_nanoseconds,
                summaries[family_index]->ci95_low_nanoseconds,
                summaries[family_index]->ci95_high_nanoseconds,
                summaries[family_index]->q_statistic,
                family->member_count - 1u,
                summaries[family_index]->i2_percent) < 0) {
            status = HOLM_EXIT_USAGE;
            break;
        }
    }
    if (fclose(output_file) != 0) {
        status = HOLM_EXIT_USAGE;
    }
    if (status != 0) {
        fprintf(stderr, "error: cannot write %s\n", path);
    }
    return status;
}

static int write_summary_json(const char *output_directory,
    const struct holm_record *records,
    const struct holm_family *families,
    size_t family_count,
    const double *adjusted_p_values,
    const int *rejected,
    double alpha)
{
    char path[HOLM_PATH_CAPACITY_BYTES];
    (void)snprintf(path, sizeof(path), "%s/holm_summary.json", output_directory);
    FILE *output_file = fopen(path, "w");
    if (output_file == NULL) {
        fprintf(stderr, "error: cannot create %s\n", path);
        return HOLM_EXIT_USAGE;
    }
    int status = 0;
    if (fprintf(output_file, "{\n  \"alpha\": %.15g,\n  \"families\": [\n", alpha) < 0) {
        status = HOLM_EXIT_USAGE;
    }
    for (size_t family_index = 0u; status == 0 && family_index < family_count; ++family_index) {
        const struct holm_family *family = &families[family_index];
        size_t reject_count = 0u;
        for (size_t member_index = 0u; member_index < family->member_count; ++member_index) {
            if (rejected[family->record_indices[member_index]] != 0) {
                ++reject_count;
            }
        }
        if (fprintf(output_file,
                "    {\n      \"family_id\": \"%s\",\n      \"m\": %zu,\n      "
                "\"reject_count\": %zu,\n      \"members\": [\n",
                family->family_id,
                family->member_count,
                reject_count) < 0) {
            status = HOLM_EXIT_USAGE;
            break;
        }
        for (size_t rank_index = 0u; status == 0 && rank_index < family->member_count;
            ++rank_index) {
            size_t record_index = family->record_indices[rank_index];
            size_t rank = rank_index + 1u;
            double threshold = alpha / (double)(family->member_count - rank_index);
            if (fprintf(output_file,
                    "        {\"member_id\": \"%s\", \"rank\": %zu, \"raw_p\": %.15g, "
                    "\"threshold\": %.15g, \"adjusted_p\": %.15g, \"reject\": %d}%s\n",
                    records[record_index].member_id,
                    rank,
                    records[record_index].p_two_sided,
                    threshold,
                    adjusted_p_values[record_index],
                    rejected[record_index],
                    rank_index + 1u < family->member_count ? "," : "") < 0) {
                status = HOLM_EXIT_USAGE;
                break;
            }
        }
        if (status == 0 &&
            fprintf(output_file,
                "      ]\n    }%s\n",
                family_index + 1u < family_count ? "," : "") < 0) {
            status = HOLM_EXIT_USAGE;
        }
    }
    if (status == 0 && fputs("  ]\n}\n", output_file) < 0) {
        status = HOLM_EXIT_USAGE;
    }
    if (fclose(output_file) != 0) {
        status = HOLM_EXIT_USAGE;
    }
    if (status != 0) {
        fprintf(stderr, "error: cannot write %s\n", path);
    }
    return status;
}

static int write_result_markdown(const char *output_directory,
    const struct holm_record *records,
    const struct holm_family *families,
    size_t family_count,
    const double *adjusted_p_values,
    const int *rejected,
    struct holm_family_summary **const summaries,
    double alpha)
{
    char path[HOLM_PATH_CAPACITY_BYTES];
    (void)snprintf(path, sizeof(path), "%s/RESULT.md", output_directory);
    FILE *output_file = fopen(path, "w");
    if (output_file == NULL) {
        fprintf(stderr, "error: cannot create %s\n", path);
        return HOLM_EXIT_USAGE;
    }
    int status = 0;
    if (fprintf(output_file,
            "# platform_holm 结果\n\nHolm 家族按预注册 m 计算；RTLF 与 dudect 一律族外，最大 t "
            "不得转伪 p。\n"
            "\n族水平 alpha = %.15g；adjusted_p 单调不减，一旦某项不拒绝，其后全部不拒绝。\n\n"
            "## Holm 逐步检验\n\n",
            alpha) < 0) {
        status = HOLM_EXIT_USAGE;
    }
    if (status == 0) {
        fputs("| family_id | member_id | raw_p | rank | threshold | adjusted_p | reject |\n"
              "| --- | --- | --- | --- | --- | --- | --- |\n",
            output_file);
    }
    for (size_t family_index = 0u; status == 0 && family_index < family_count; ++family_index) {
        const struct holm_family *family = &families[family_index];
        for (size_t rank_index = 0u; rank_index < family->member_count; ++rank_index) {
            size_t record_index = family->record_indices[rank_index];
            if (fprintf(output_file,
                    "| %s | %s | %.6g | %zu | %.6g | %.6g | %s |\n",
                    family->family_id,
                    records[record_index].member_id,
                    records[record_index].p_two_sided,
                    rank_index + 1u,
                    alpha / (double)(family->member_count - rank_index),
                    adjusted_p_values[record_index],
                    rejected[record_index] != 0 ? "yes" : "no") < 0) {
                status = HOLM_EXIT_USAGE;
                break;
            }
        }
    }
    if (status == 0) {
        fputs("\n## 固定效应合并\n\n"
              "theta = mean0 - mean1；se = sqrt(sd0^2/n0 + sd1^2/n1)；w = 1/se^2；\n"
              "pooled = sum(w*theta)/sum(w)；pooled_se = 1/sqrt(sum(w))；ci95 = pooled +- "
              "1.96*pooled_se；\nQ = sum(w*(theta-pooled)^2)；df = m-1；I2 = (Q > df) ? "
              "(Q-df)/Q*100 : 0。\n\n"
              "| family_id | m | pooled_effect_ns | pooled_se_ns | ci95_low_ns | ci95_high_ns | "
              "q_statistic | df | i2_percent |\n"
              "| --- | --- | --- | --- | --- | --- | --- | --- | --- |\n",
            output_file);
    }
    for (size_t family_index = 0u; status == 0 && family_index < family_count; ++family_index) {
        const struct holm_family *family = &families[family_index];
        if (fprintf(output_file,
                "| %s | %zu | %.9g | %.9g | %.9g | %.9g | %.9g | %zu | %.9g |\n",
                family->family_id,
                family->member_count,
                summaries[family_index]->pooled_effect_nanoseconds,
                summaries[family_index]->pooled_se_nanoseconds,
                summaries[family_index]->ci95_low_nanoseconds,
                summaries[family_index]->ci95_high_nanoseconds,
                summaries[family_index]->q_statistic,
                family->member_count - 1u,
                summaries[family_index]->i2_percent) < 0) {
            status = HOLM_EXIT_USAGE;
            break;
        }
    }
    if (status == 0) {
        fputs("\n数值护栏：se == 0、n0 == 0 或 n1 == 0 一律报错退出码 2，不跳过也不除零。\n"
              "并列 p 值按输入出现顺序作为次级键，排名稳定。\n",
            output_file);
    }
    if (fclose(output_file) != 0) {
        status = HOLM_EXIT_USAGE;
    }
    if (status != 0) {
        fprintf(stderr, "error: cannot write %s\n", path);
    }
    return status;
}

static int reject_existing_output_directory(const char *output_directory)
{
    struct stat status;
    if (stat(output_directory, &status) == 0) {
        fprintf(stderr, "error: output directory %s already exists\n", output_directory);
        return 1;
    }
    if (errno != ENOENT) {
        fprintf(stderr, "error: cannot check output directory %s\n", output_directory);
        return 1;
    }
    return 0;
}

static int create_output_directory(const char *output_directory)
{
    if (mkdir(output_directory, 0700) != 0) {
        fprintf(stderr, "error: cannot create output directory %s\n", output_directory);
        return 1;
    }
    return 0;
}

static void remove_output_files(const char *output_directory)
{
    static const char *const file_names[] = {
        "holm.csv",
        "pooled.csv",
        "holm_summary.json",
        "RESULT.md",
    };
    char path[HOLM_PATH_CAPACITY_BYTES];
    for (size_t file_index = 0u; file_index < sizeof(file_names) / sizeof(file_names[0]);
        ++file_index) {
        (void)snprintf(path, sizeof(path), "%s/%s", output_directory, file_names[file_index]);
        (void)remove(path);
    }
    (void)rmdir(output_directory);
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

int main(int argument_count, char **argument_values)
{
    const char *input_path = NULL;
    const char *output_directory = NULL;
    const char *alpha_text = NULL;
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
                return HOLM_EXIT_USAGE;
            }
            input_path = value;
            continue;
        }
        taken = take_argument_value(argument_count,
            argument_values,
            &argument_index,
            "--output-dir",
            &value);
        if (taken == 0) {
            if (output_directory != NULL) {
                print_usage();
                return HOLM_EXIT_USAGE;
            }
            output_directory = value;
            continue;
        }
        taken = take_argument_value(argument_count,
            argument_values,
            &argument_index,
            "--alpha",
            &value);
        if (taken == 0) {
            if (alpha_text != NULL) {
                print_usage();
                return HOLM_EXIT_USAGE;
            }
            alpha_text = value;
            continue;
        }
        print_usage();
        return HOLM_EXIT_USAGE;
    }
    if (input_path == NULL || output_directory == NULL || alpha_text == NULL) {
        print_usage();
        return HOLM_EXIT_USAGE;
    }
    double alpha = 0.0;
    if (parse_decimal(alpha_text, &alpha) != 0 || alpha <= 0.0 || alpha >= 1.0) {
        fprintf(stderr, "error: alpha must be a decimal in (0,1)\n");
        return HOLM_EXIT_DATA;
    }
    /* 输出目录只接受已存在的父目录下的单个新名字，避免隐式递归建树。 */
    if (output_directory[0] == '\0' || output_directory[0] == '/' ||
        strchr(output_directory, '/') != NULL) {
        fprintf(stderr, "error: output directory must be a non-empty relative name\n");
        return HOLM_EXIT_USAGE;
    }
    size_t output_bytes = strlen(output_directory);
    if (output_bytes > HOLM_PATH_CAPACITY_BYTES / 2u) {
        fprintf(stderr, "error: output directory name is too long\n");
        return HOLM_EXIT_USAGE;
    }

    struct holm_record *records = NULL;
    size_t record_count = 0u;
    int status = load_members(input_path, &records, &record_count);
    if (status != 0) {
        return status;
    }
    /* 家族表本身按固定上限分配，成员索引按家族实际规模另分配。 */
    struct holm_family *families = calloc(HOLM_MAXIMUM_FAMILY_COUNT, sizeof(struct holm_family));
    if (families == NULL) {
        fprintf(stderr, "error: cannot allocate family table\n");
        free(records);
        return HOLM_EXIT_USAGE;
    }
    size_t family_count = 0u;
    status = build_families(records, record_count, families, &family_count);
    if (status != 0) {
        free(families);
        free(records);
        return status;
    }
    for (size_t family_index = 0u; status == 0 && family_index < family_count; ++family_index) {
        status = collect_family_members(records, record_count, &families[family_index]);
        if (status != 0) {
            break;
        }
    }
    /* se 为 0 时权重无定义；这里整表拒绝，不做跳过、也不让 inf/nan 流进结果文件。 */
    for (size_t record_index = 0u; status == 0 && record_index < record_count; ++record_index) {
        const struct holm_record *record = &records[record_index];
        if (!(member_variance_nanoseconds_squared(record) > 0.0)) {
            fprintf(stderr,
                "error: %s/%s has se == 0 (sd and n must be nonzero)\n",
                record->family_id,
                record->member_id);
            status = HOLM_EXIT_DATA;
        }
    }
    struct holm_family_summary **summaries = NULL;
    double *adjusted_p_values = NULL;
    int *rejected = NULL;
    if (status == 0) {
        summaries = calloc(family_count, sizeof(struct holm_family_summary *));
        adjusted_p_values = calloc(record_count, sizeof(double));
        rejected = calloc(record_count, sizeof(int));
        if (summaries == NULL || adjusted_p_values == NULL || rejected == NULL) {
            fprintf(stderr, "error: cannot allocate result tables\n");
            status = HOLM_EXIT_USAGE;
        }
    }
    for (size_t family_index = 0u; status == 0 && family_index < family_count; ++family_index) {
        summaries[family_index] = calloc(1u, sizeof(struct holm_family_summary));
        if (summaries[family_index] == NULL) {
            fprintf(stderr, "error: cannot allocate family summary\n");
            status = HOLM_EXIT_USAGE;
        }
    }

    /* Holm step-down：adjusted_p 取前缀最大值保证单调不减；一旦某项不拒绝，其后全部不拒绝。 */
    for (size_t family_index = 0u; status == 0 && family_index < family_count; ++family_index) {
        struct holm_family *family = &families[family_index];
        sort_members_by_p(records, family);
        summarize_family(records, family, summaries[family_index]);
        double running_adjusted = 0.0;
        int still_rejecting = 1;
        for (size_t rank_index = 0u; rank_index < family->member_count; ++rank_index) {
            size_t record_index = family->record_indices[rank_index];
            double multiplier = (double)(family->member_count - rank_index);
            double step_adjusted = multiplier * records[record_index].p_two_sided;
            if (step_adjusted > 1.0) {
                step_adjusted = 1.0;
            }
            if (step_adjusted > running_adjusted) {
                running_adjusted = step_adjusted;
            }
            adjusted_p_values[record_index] = running_adjusted;
            rejected[record_index] = (still_rejecting && running_adjusted <= alpha) ? 1 : 0;
            if (rejected[record_index] == 0) {
                still_rejecting = 0;
            }
        }
    }

    /* 计算完成后才碰输出目录：任何非法输入都不会留下半个目录。 */
    if (status == 0 && reject_existing_output_directory(output_directory) != 0) {
        status = HOLM_EXIT_USAGE;
    }
    if (status == 0 && create_output_directory(output_directory) != 0) {
        status = HOLM_EXIT_USAGE;
    }
    if (status == 0) {
        status = write_holm_csv(output_directory,
            records,
            families,
            family_count,
            adjusted_p_values,
            rejected,
            alpha);
    }
    if (status == 0) {
        status = write_pooled_csv(output_directory, families, family_count, summaries);
    }
    if (status == 0) {
        status = write_summary_json(output_directory,
            records,
            families,
            family_count,
            adjusted_p_values,
            rejected,
            alpha);
    }
    if (status == 0) {
        status = write_result_markdown(output_directory,
            records,
            families,
            family_count,
            adjusted_p_values,
            rejected,
            summaries,
            alpha);
    }
    if (status != 0) {
        remove_output_files(output_directory);
    }

    size_t rejected_count = 0u;
    for (size_t record_index = 0u; rejected != NULL && record_index < record_count;
        ++record_index) {
        rejected_count += (size_t)rejected[record_index];
    }
    if (summaries != NULL) {
        for (size_t family_index = 0u; family_index < family_count; ++family_index) {
            free(summaries[family_index]);
        }
    }
    free(summaries);
    for (size_t family_index = 0u; family_index < family_count; ++family_index) {
        free(families[family_index].record_indices);
    }
    free(families);
    /* 构造失败时这里可能还是空指针，free(NULL) 是安全的。 */
    free(rejected);
    free(adjusted_p_values);
    free(records);
    if (status == 0) {
        printf("families=%zu members=%zu rejected=%zu alpha=%.15g\n",
            family_count,
            record_count,
            rejected_count,
            alpha);
    }
    return status;
}
