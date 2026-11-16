/* platform_shape_stats 的确定性自检：LCG 合成数据、完全相同两组与格式拒绝路径。
 * 用法：test_shape_stats <platform_shape_stats 可执行文件>
 * 临时目录固定走 CTest 的 A113_TEST_TMPDIR（机制见 tests/test_temp_directory.h）。 */

#define _POSIX_C_SOURCE 200809L
#ifdef __APPLE__
#define _DARWIN_C_SOURCE
#endif

#include "test_temp_directory.h"

#include <assert.h>
#include <inttypes.h>
#include <math.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/stat.h>
#include <sys/wait.h>
#include <unistd.h>

#define TEST_PATH_CAPACITY_BYTES 4096
#define TEST_LINE_CAPACITY_BYTES 1024
#define TEST_FILE_CAPACITY_BYTES (256u * 1024u)
#define TEST_OUTPUT_ROW_COUNT 4u
#define TEST_OUTPUT_COLUMN_COUNT 6u
#define TEST_NAME_CAPACITY_BYTES 64
#define TEST_VERDICT_CAPACITY_BYTES 16
#define TEST_LCG_MULTIPLIER 1664525u
#define TEST_LCG_INCREMENT 1013904223u
#define TEST_LCG_SEED 20261116u
#define TEST_SYNTHETIC_SAMPLE_COUNT 2000u
#define TEST_SYNTHETIC_MINIMUM_NANOSECONDS 1000u
#define TEST_SYNTHETIC_SPAN_NANOSECONDS 1000u
#define TEST_SYNTHETIC_VARIANCE_SCALE 3.0
#define TEST_IDENTICAL_SAMPLE_COUNT 100u
#define TEST_IDENTICAL_NANOSECONDS 1500
#define TEST_LONG_SAMPLE_COUNT 40u

struct shape_output_row {
    char test_name[TEST_NAME_CAPACITY_BYTES];
    double statistic;
    double p_value;
    size_t n0;
    size_t n1;
    char verdict[TEST_VERDICT_CAPACITY_BYTES];
};

static char test_file_buffer[TEST_FILE_CAPACITY_BYTES];

static void build_path(char *destination, size_t capacity, const char *base, const char *name)
{
    int written = snprintf(destination, capacity, "%s/%s", base, name);
    assert(written > 0 && (size_t)written < capacity);
}

static void write_text_file(const char *path, const char *text)
{
    FILE *file = fopen(path, "w");
    assert(file != NULL);
    size_t text_bytes = strlen(text);
    assert(fwrite(text, 1u, text_bytes, file) == text_bytes);
    assert(fclose(file) == 0);
}

static const char *read_text_file(const char *path)
{
    FILE *file = fopen(path, "r");
    assert(file != NULL);
    size_t read_bytes = fread(test_file_buffer, 1u, sizeof(test_file_buffer) - 1u, file);
    test_file_buffer[read_bytes] = '\0';
    assert(fclose(file) == 0);
    return test_file_buffer;
}

static void expect_contains(const char *path, const char *needle)
{
    const char *text = read_text_file(path);
    if (strstr(text, needle) == NULL) {
        fprintf(stderr, "missing %s in %s\n", needle, path);
        assert(0);
    }
}

/* 参数可能是相对路径，而子进程会切到临时根；这里先固化成绝对路径。 */
static const char *absolute_program_path(const char *program)
{
    static char resolved[TEST_PATH_CAPACITY_BYTES];
    if (program[0] == '/') {
        (void)snprintf(resolved, sizeof(resolved), "%s", program);
        return resolved;
    }
    char working_directory[TEST_PATH_CAPACITY_BYTES];
    assert(getcwd(working_directory, sizeof(working_directory)) != NULL);
    int written = snprintf(resolved, sizeof(resolved), "%s/%s", working_directory, program);
    assert(written > 0 && (size_t)written < sizeof(resolved));
    return resolved;
}

/* 运行一次 platform_shape_stats：input_path 为 NULL 时不传 --input（用法错误用例）。 */
static int run_shape_stats(const char *program,
    const char *input_path,
    const char *format,
    const char *output_path,
    const char *meta_path,
    const char *label)
{
    char *argument_values[13];
    int argument_count = 0;
    argument_values[argument_count] = (char *)program;
    ++argument_count;
    if (input_path != NULL) {
        argument_values[argument_count] = (char *)"--input";
        ++argument_count;
        argument_values[argument_count] = (char *)input_path;
        ++argument_count;
    }
    argument_values[argument_count] = (char *)"--format";
    ++argument_count;
    argument_values[argument_count] = (char *)format;
    ++argument_count;
    argument_values[argument_count] = (char *)"--output";
    ++argument_count;
    argument_values[argument_count] = (char *)output_path;
    ++argument_count;
    argument_values[argument_count] = (char *)"--meta";
    ++argument_count;
    argument_values[argument_count] = (char *)meta_path;
    ++argument_count;
    if (label != NULL) {
        argument_values[argument_count] = (char *)"--label";
        ++argument_count;
        argument_values[argument_count] = (char *)label;
        ++argument_count;
    }
    argument_values[argument_count] = NULL;
    pid_t child_process = fork();
    assert(child_process >= 0);
    if (child_process == 0) {
        execv(program, argument_values);
        _exit(127);
    }
    int wait_status = 0;
    assert(waitpid(child_process, &wait_status, 0) == child_process);
    assert(WIFEXITED(wait_status));
    return WEXITSTATUS(wait_status);
}

static size_t split_line(char *line, char **fields, size_t capacity)
{
    size_t line_bytes = strlen(line);
    if (line_bytes > 0u && line[line_bytes - 1u] == '\n') {
        line[line_bytes - 1u] = '\0';
    }
    size_t field_count = 1u;
    fields[0] = line;
    for (char *cursor = line; *cursor != '\0'; ++cursor) {
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

static size_t
load_output_rows(const char *output_path, struct shape_output_row *rows, size_t capacity)
{
    FILE *output_file = fopen(output_path, "r");
    assert(output_file != NULL);
    char line[TEST_LINE_CAPACITY_BYTES];
    assert(fgets(line, (int)sizeof(line), output_file) != NULL);
    assert(strcmp(line, "test_name,statistic,p_value,n0,n1,verdict_exploratory\n") == 0);
    size_t row_count = 0u;
    while (fgets(line, (int)sizeof(line), output_file) != NULL) {
        assert(row_count < capacity);
        char *fields[TEST_OUTPUT_COLUMN_COUNT];
        size_t field_count = split_line(line, fields, TEST_OUTPUT_COLUMN_COUNT);
        assert(field_count == TEST_OUTPUT_COLUMN_COUNT);
        assert(strlen(fields[0]) < TEST_NAME_CAPACITY_BYTES);
        assert(strlen(fields[5]) < TEST_VERDICT_CAPACITY_BYTES);
        (void)
            snprintf(rows[row_count].test_name, sizeof(rows[row_count].test_name), "%s", fields[0]);
        rows[row_count].statistic = strtod(fields[1], NULL);
        rows[row_count].p_value = strtod(fields[2], NULL);
        rows[row_count].n0 = (size_t)strtoull(fields[3], NULL, 10);
        rows[row_count].n1 = (size_t)strtoull(fields[4], NULL, 10);
        (void)snprintf(rows[row_count].verdict, sizeof(rows[row_count].verdict), "%s", fields[5]);
        ++row_count;
    }
    assert(!ferror(output_file));
    assert(fclose(output_file) == 0);
    return row_count;
}

static const struct shape_output_row *
find_output_row(const struct shape_output_row *rows, size_t row_count, const char *test_name)
{
    for (size_t row_index = 0u; row_index < row_count; ++row_index) {
        if (strcmp(rows[row_index].test_name, test_name) == 0) {
            return &rows[row_index];
        }
    }
    fprintf(stderr, "missing test row %s\n", test_name);
    assert(0);
    return NULL;
}

static void write_wide_fixture(const char *path,
    const char *class_zero_name,
    const char *class_ones_name,
    const int64_t *class_zero_nanoseconds,
    const int64_t *class_ones_nanoseconds,
    size_t sample_count)
{
    FILE *input_file = fopen(path, "w");
    assert(input_file != NULL);
    assert(fprintf(input_file, "%s,%s\n", class_zero_name, class_ones_name) > 0);
    for (size_t sample_index = 0u; sample_index < sample_count; ++sample_index) {
        assert(fprintf(input_file,
                   "%" PRId64 ",%" PRId64 "\n",
                   class_zero_nanoseconds[sample_index],
                   class_ones_nanoseconds[sample_index]) > 0);
    }
    assert(fclose(input_file) == 0);
}

/* A) 均值同、方差 1 vs 9：Brown–Forsythe 与 KS 都应给 p<0.01。 */
static void check_case_mean_equal_variance_different(const char *program, const char *scratch_root)
{
    int64_t class_zero_nanoseconds[TEST_SYNTHETIC_SAMPLE_COUNT];
    int64_t class_ones_nanoseconds[TEST_SYNTHETIC_SAMPLE_COUNT];
    uint32_t lcg_state = TEST_LCG_SEED;
    double class_zero_sum = 0.0;
    for (size_t sample_index = 0u; sample_index < TEST_SYNTHETIC_SAMPLE_COUNT; ++sample_index) {
        lcg_state = lcg_state * TEST_LCG_MULTIPLIER + TEST_LCG_INCREMENT;
        class_zero_nanoseconds[sample_index] = (int64_t)(TEST_SYNTHETIC_MINIMUM_NANOSECONDS +
            lcg_state % (TEST_SYNTHETIC_SPAN_NANOSECONDS + 1u));
        class_zero_sum += (double)class_zero_nanoseconds[sample_index];
    }
    double class_zero_mean = class_zero_sum / (double)TEST_SYNTHETIC_SAMPLE_COUNT;
    for (size_t sample_index = 0u; sample_index < TEST_SYNTHETIC_SAMPLE_COUNT; ++sample_index) {
        double transformed = class_zero_mean +
            TEST_SYNTHETIC_VARIANCE_SCALE *
                ((double)class_zero_nanoseconds[sample_index] - class_zero_mean);
        class_ones_nanoseconds[sample_index] = (int64_t)(transformed + 0.5);
    }
    char input_path[TEST_PATH_CAPACITY_BYTES];
    char output_path[TEST_PATH_CAPACITY_BYTES];
    char meta_path[TEST_PATH_CAPACITY_BYTES];
    build_path(input_path, sizeof(input_path), scratch_root, "synthetic-wide.csv");
    build_path(output_path, sizeof(output_path), scratch_root, "synthetic-wide.out.csv");
    build_path(meta_path, sizeof(meta_path), scratch_root, "synthetic-wide.meta.txt");
    write_wide_fixture(input_path,
        "message-zero",
        "message-ones",
        class_zero_nanoseconds,
        class_ones_nanoseconds,
        TEST_SYNTHETIC_SAMPLE_COUNT);
    assert(run_shape_stats(program, input_path, "wide", output_path, meta_path, "synthetic") == 0);
    struct shape_output_row rows[TEST_OUTPUT_ROW_COUNT];
    assert(load_output_rows(output_path, rows, TEST_OUTPUT_ROW_COUNT) == TEST_OUTPUT_ROW_COUNT);
    const struct shape_output_row *brown_forsythe_row =
        find_output_row(rows, TEST_OUTPUT_ROW_COUNT, "brown_forsythe");
    const struct shape_output_row *ks_row =
        find_output_row(rows, TEST_OUTPUT_ROW_COUNT, "ks_two_sample");
    assert(brown_forsythe_row->p_value < 0.01);
    assert(ks_row->p_value < 0.01);
    assert(strcmp(brown_forsythe_row->verdict, "flag") == 0);
    assert(strcmp(ks_row->verdict, "flag") == 0);
    assert(brown_forsythe_row->n0 == TEST_SYNTHETIC_SAMPLE_COUNT);
    assert(brown_forsythe_row->n1 == TEST_SYNTHETIC_SAMPLE_COUNT);
    expect_contains(meta_path, "family=none_exploratory_only");
    expect_contains(meta_path, "format=wide");
    expect_contains(meta_path, "alpha=0.05");
    (void)remove(input_path);
    (void)remove(output_path);
    (void)remove(meta_path);
}

/* B) 两组完全相同：三族检验都应给统计量 0、p=1（类内二行为 t=0、p=1）。 */
static void check_case_identical_groups(const char *program, const char *scratch_root)
{
    int64_t class_zero_nanoseconds[TEST_IDENTICAL_SAMPLE_COUNT];
    int64_t class_ones_nanoseconds[TEST_IDENTICAL_SAMPLE_COUNT];
    for (size_t sample_index = 0u; sample_index < TEST_IDENTICAL_SAMPLE_COUNT; ++sample_index) {
        class_zero_nanoseconds[sample_index] = TEST_IDENTICAL_NANOSECONDS;
        class_ones_nanoseconds[sample_index] = TEST_IDENTICAL_NANOSECONDS;
    }
    char input_path[TEST_PATH_CAPACITY_BYTES];
    char output_path[TEST_PATH_CAPACITY_BYTES];
    char meta_path[TEST_PATH_CAPACITY_BYTES];
    build_path(input_path, sizeof(input_path), scratch_root, "identical-wide.csv");
    build_path(output_path, sizeof(output_path), scratch_root, "identical-wide.out.csv");
    build_path(meta_path, sizeof(meta_path), scratch_root, "identical-wide.meta.txt");
    write_wide_fixture(input_path,
        "class-zero",
        "class-ones",
        class_zero_nanoseconds,
        class_ones_nanoseconds,
        TEST_IDENTICAL_SAMPLE_COUNT);
    assert(run_shape_stats(program, input_path, "wide", output_path, meta_path, NULL) == 0);
    struct shape_output_row rows[TEST_OUTPUT_ROW_COUNT];
    assert(load_output_rows(output_path, rows, TEST_OUTPUT_ROW_COUNT) == TEST_OUTPUT_ROW_COUNT);
    const struct shape_output_row *brown_forsythe_row =
        find_output_row(rows, TEST_OUTPUT_ROW_COUNT, "brown_forsythe");
    const struct shape_output_row *ks_row =
        find_output_row(rows, TEST_OUTPUT_ROW_COUNT, "ks_two_sample");
    const struct shape_output_row *within_zero_row =
        find_output_row(rows, TEST_OUTPUT_ROW_COUNT, "within_class_second_order_zero");
    const struct shape_output_row *within_ones_row =
        find_output_row(rows, TEST_OUTPUT_ROW_COUNT, "within_class_second_order_ones");
    assert(brown_forsythe_row->statistic == 0.0);
    assert(brown_forsythe_row->p_value == 1.0);
    assert(ks_row->statistic == 0.0);
    assert(ks_row->p_value == 1.0);
    assert(within_zero_row->statistic == 0.0);
    assert(within_zero_row->p_value == 1.0);
    assert(within_ones_row->statistic == 0.0);
    assert(within_ones_row->p_value == 1.0);
    assert(strcmp(brown_forsythe_row->verdict, "clear") == 0);
    assert(strcmp(ks_row->verdict, "clear") == 0);
    (void)remove(input_path);
    (void)remove(output_path);
    (void)remove(meta_path);
}

/* C) 格式与用法拒绝：非整数、空文件、单列、多列、文件不存在退出 2；缺 --input 退出 1。 */
static void check_case_rejections(const char *program, const char *scratch_root)
{
    char input_path[TEST_PATH_CAPACITY_BYTES];
    char output_path[TEST_PATH_CAPACITY_BYTES];
    char meta_path[TEST_PATH_CAPACITY_BYTES];
    build_path(output_path, sizeof(output_path), scratch_root, "rejected.out.csv");
    build_path(meta_path, sizeof(meta_path), scratch_root, "rejected.meta.txt");
    build_path(input_path, sizeof(input_path), scratch_root, "rejected.csv");
    write_text_file(input_path, "class-zero,class-ones\nabc,12\n1,2\n");
    assert(run_shape_stats(program, input_path, "wide", output_path, meta_path, NULL) == 2);
    write_text_file(input_path, "");
    assert(run_shape_stats(program, input_path, "wide", output_path, meta_path, NULL) == 2);
    write_text_file(input_path, "only-one-column\n1\n2\n");
    assert(run_shape_stats(program, input_path, "wide", output_path, meta_path, NULL) == 2);
    write_text_file(input_path, "class-zero,class-ones\n1,2\n3,4,5\n");
    assert(run_shape_stats(program, input_path, "wide", output_path, meta_path, NULL) == 2);
    write_text_file(input_path, "class-zero,class-ones\n1,2\n");
    assert(run_shape_stats(program, input_path, "wide", output_path, meta_path, NULL) == 2);
    char missing_path[TEST_PATH_CAPACITY_BYTES];
    build_path(missing_path, sizeof(missing_path), scratch_root, "does-not-exist.csv");
    assert(run_shape_stats(program, missing_path, "wide", output_path, meta_path, NULL) == 2);
    assert(run_shape_stats(program, NULL, "wide", output_path, meta_path, NULL) == 1);
    (void)remove(input_path);
    (void)remove(output_path);
    (void)remove(meta_path);
}

/* 长表覆盖：五列与六列合法输入都应成功；三类输入必须退 2。 */
static void write_long_fixture(const char *path, int has_time_unit, int has_third_category)
{
    FILE *input_file = fopen(path, "w");
    assert(input_file != NULL);
    assert(fprintf(input_file,
               "run_id,implementation,input_category,sample_index,elapsed_nanoseconds%s\n",
               has_time_unit ? ",time_unit" : "") > 0);
    for (size_t sample_index = 0u; sample_index < TEST_LONG_SAMPLE_COUNT; ++sample_index) {
        const char *category = (sample_index % 2u) == 0u ? "message-zero" : "message-ones";
        int64_t elapsed_nanoseconds = 1000 + (int64_t)(sample_index % 7u);
        if (has_time_unit != 0) {
            assert(fprintf(input_file,
                       "run-a,ref,%s,%zu,%" PRId64 ",ns\n",
                       category,
                       sample_index,
                       elapsed_nanoseconds) > 0);
        } else {
            assert(fprintf(input_file,
                       "run-a,ref,%s,%zu,%" PRId64 "\n",
                       category,
                       sample_index,
                       elapsed_nanoseconds) > 0);
        }
    }
    if (has_third_category != 0) {
        assert(
            fprintf(input_file, "run-a,ref,random,%zu,2000,ns\n", (size_t)TEST_LONG_SAMPLE_COUNT) >
            0);
    }
    assert(fclose(input_file) == 0);
}

static void check_case_long_table(const char *program, const char *scratch_root)
{
    char input_path[TEST_PATH_CAPACITY_BYTES];
    char output_path[TEST_PATH_CAPACITY_BYTES];
    char meta_path[TEST_PATH_CAPACITY_BYTES];
    build_path(input_path, sizeof(input_path), scratch_root, "long-valid.csv");
    build_path(output_path, sizeof(output_path), scratch_root, "long-valid.out.csv");
    build_path(meta_path, sizeof(meta_path), scratch_root, "long-valid.meta.txt");
    write_long_fixture(input_path, 1, 0);
    assert(run_shape_stats(program, input_path, "long", output_path, meta_path, "long") == 0);
    struct shape_output_row rows[TEST_OUTPUT_ROW_COUNT];
    assert(load_output_rows(output_path, rows, TEST_OUTPUT_ROW_COUNT) == TEST_OUTPUT_ROW_COUNT);
    expect_contains(meta_path, "format=long");
    expect_contains(meta_path, "rows_class_zero=20");
    expect_contains(meta_path, "rows_class_ones=20");
    (void)remove(input_path);
    (void)remove(output_path);
    (void)remove(meta_path);
    build_path(input_path, sizeof(input_path), scratch_root, "long-no-unit.csv");
    build_path(output_path, sizeof(output_path), scratch_root, "long-no-unit.out.csv");
    build_path(meta_path, sizeof(meta_path), scratch_root, "long-no-unit.meta.txt");
    write_long_fixture(input_path, 0, 0);
    assert(run_shape_stats(program, input_path, "long", output_path, meta_path, NULL) == 0);
    (void)remove(input_path);
    (void)remove(output_path);
    (void)remove(meta_path);
    build_path(input_path, sizeof(input_path), scratch_root, "long-three-categories.csv");
    build_path(output_path, sizeof(output_path), scratch_root, "long-three.out.csv");
    build_path(meta_path, sizeof(meta_path), scratch_root, "long-three.meta.txt");
    write_long_fixture(input_path, 1, 1);
    assert(run_shape_stats(program, input_path, "long", output_path, meta_path, NULL) == 2);
    (void)remove(input_path);
    (void)remove(output_path);
    (void)remove(meta_path);
}

int main(int argument_count, char **argument_values)
{
    assert(argument_count == 2);
    const char *program = absolute_program_path(argument_values[1]);
    char scratch_root[TEST_PATH_CAPACITY_BYTES];
    assert(create_test_temp_directory(scratch_root, sizeof(scratch_root), "shape-stats") != NULL);
    check_case_mean_equal_variance_different(program, scratch_root);
    check_case_identical_groups(program, scratch_root);
    check_case_rejections(program, scratch_root);
    check_case_long_table(program, scratch_root);
    (void)rmdir(scratch_root);
    puts("shape_stats: synthetic, identical, rejection and long cases pass");
    return 0;
}
