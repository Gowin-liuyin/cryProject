/* platform_holm 的黑盒对照：手算 Holm 表与固定效应合并，再逐项核对程序输出。
 * 用法：test_platform_holm <platform_holm 可执行文件> <临时根目录>
 * 手算口径逐条写在对应 case 的注释里；数值偏差超过 1e-9 即判失败。 */

#define _POSIX_C_SOURCE 200809L
#ifdef __APPLE__
#define _DARWIN_C_SOURCE
#endif

#include <assert.h>
#include <math.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/stat.h>
#include <sys/wait.h>
#include <unistd.h>

#define TEST_PATH_CAPACITY_BYTES 4096
#define TEST_FILE_CAPACITY_BYTES (256u * 1024u)
#define TEST_LINE_CAPACITY_BYTES 1024
#define TEST_COLUMN_COUNT 11u
#define TEST_TOLERANCE 1e-9

struct holm_row {
    char family_id[64];
    char member_id[64];
    double raw_p;
    size_t rank;
    double threshold;
    double adjusted_p;
    int reject;
};

struct pooled_row {
    char family_id[64];
    double pooled_effect_ns;
    double pooled_se_ns;
    double ci95_low_ns;
    double ci95_high_ns;
    double q_statistic;
    size_t member_count;
    size_t degrees_of_freedom;
    double i2_percent;
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

/* 取出输出目录的父目录名（保持绝对路径起始的 '/'），子进程工作目录必须先切到这里。 */
static void
derive_working_directory(const char *output_directory, char *destination, size_t capacity)
{
    const char *last_separator = strrchr(output_directory, '/');
    assert(last_separator != NULL);
    size_t directory_bytes = (size_t)(last_separator - output_directory);
    assert(directory_bytes > 0u && directory_bytes < capacity);
    memcpy(destination, output_directory, directory_bytes);
    destination[directory_bytes] = '\0';
}

/* 运行一次 platform_holm；返回进程退出码。alpha 为 NULL 时不传 --alpha。 */
static int run_holm(const char *program,
    const char *input_path,
    const char *output_directory,
    const char *alpha)
{
    char working_directory[TEST_PATH_CAPACITY_BYTES];
    char output_name[TEST_PATH_CAPACITY_BYTES];
    const char *last_separator = strrchr(output_directory, '/');
    const char *last_input_separator = strrchr(input_path, '/');
    assert(last_separator != NULL && last_input_separator != NULL);
    derive_working_directory(output_directory, working_directory, sizeof(working_directory));
    (void)snprintf(output_name, sizeof(output_name), "%s", last_separator + 1);
    pid_t child_process = fork();
    int wait_status = 0;
    assert(child_process >= 0);
    if (child_process == 0) {
        assert(chdir(working_directory) == 0);
        if (alpha == NULL) {
            execl(program,
                program,
                "--input",
                last_input_separator + 1,
                "--output-dir",
                output_name,
                (char *)NULL);
        } else {
            execl(program,
                program,
                "--input",
                last_input_separator + 1,
                "--output-dir",
                output_name,
                "--alpha",
                alpha,
                (char *)NULL);
        }
        _exit(127);
    }
    assert(waitpid(child_process, &wait_status, 0) == child_process);
    assert(WIFEXITED(wait_status));
    return WEXITSTATUS(wait_status);
}

static size_t split_line(char *line, char **fields, size_t capacity)
{
    size_t field_count = 1u;
    fields[0] = line;
    for (char *cursor = line; *cursor != '\0'; ++cursor) {
        if (*cursor == ',') {
            *cursor = '\0';
            assert(field_count < capacity);
            fields[field_count] = cursor + 1;
            ++field_count;
        }
    }
    return field_count;
}

/* 行文本复制到独立竞技场后再切分：字段指针要跨行有效，不能指向被复用的行缓冲。 */
static size_t read_csv_rows(const char *path,
    char **fields,
    size_t field_capacity,
    size_t expected_field_count,
    size_t row_capacity)
{
    static char row_arena[64u * TEST_LINE_CAPACITY_BYTES];
    char line[TEST_LINE_CAPACITY_BYTES];
    FILE *file = fopen(path, "r");
    assert(file != NULL);
    size_t row_count = 0u;
    size_t line_index = 0u;
    assert(row_capacity * TEST_LINE_CAPACITY_BYTES <= sizeof(row_arena));
    while (fgets(line, (int)sizeof(line), file) != NULL) {
        size_t line_bytes = strlen(line);
        if (line_bytes > 0u && line[line_bytes - 1u] == '\n') {
            line[line_bytes - 1u] = '\0';
        }
        if (line_index > 0u) {
            assert(row_count < row_capacity);
            char *row_text = row_arena + row_count * TEST_LINE_CAPACITY_BYTES;
            memcpy(row_text, line, strlen(line) + 1u);
            char **row_fields = &fields[row_count * field_capacity];
            assert(split_line(row_text, row_fields, field_capacity) == expected_field_count);
            ++row_count;
        }
        ++line_index;
    }
    assert(fclose(file) == 0);
    assert(line_index > 0u);
    return row_count;
}

static struct holm_row read_holm_row(char *const *fields)
{
    struct holm_row row;
    (void)snprintf(row.family_id, sizeof(row.family_id), "%s", fields[0]);
    (void)snprintf(row.member_id, sizeof(row.member_id), "%s", fields[1]);
    row.raw_p = strtod(fields[2], NULL);
    row.rank = (size_t)strtoul(fields[3], NULL, 10);
    row.threshold = strtod(fields[4], NULL);
    row.adjusted_p = strtod(fields[5], NULL);
    row.reject = atoi(fields[6]);
    return row;
}

static struct pooled_row read_pooled_row(char *const *fields)
{
    struct pooled_row row;
    (void)snprintf(row.family_id, sizeof(row.family_id), "%s", fields[0]);
    row.member_count = (size_t)strtoul(fields[1], NULL, 10);
    row.pooled_effect_ns = strtod(fields[2], NULL);
    row.pooled_se_ns = strtod(fields[3], NULL);
    row.ci95_low_ns = strtod(fields[4], NULL);
    row.ci95_high_ns = strtod(fields[5], NULL);
    row.q_statistic = strtod(fields[6], NULL);
    row.degrees_of_freedom = (size_t)strtoul(fields[7], NULL, 10);
    row.i2_percent = strtod(fields[8], NULL);
    return row;
}

static void expect_close(double actual, double expected, const char *label)
{
    if (!(fabs(actual - expected) <= TEST_TOLERANCE)) {
        fprintf(stderr, "%s: actual %.17g expected %.17g\n", label, actual, expected);
        assert(0);
    }
}

static void remove_case_output(const char *output_directory)
{
    static const char *const file_names[] = {
        "holm.csv",
        "pooled.csv",
        "holm_summary.json",
        "RESULT.md",
    };
    char path[TEST_PATH_CAPACITY_BYTES];
    for (size_t file_index = 0u; file_index < sizeof(file_names) / sizeof(file_names[0]);
        ++file_index) {
        build_path(path, sizeof(path), output_directory, file_names[file_index]);
        (void)remove(path);
    }
}

static void define_case(const char *scratch_root,
    const char *case_name,
    const char *csv_text,
    char *input_path,
    size_t input_capacity,
    char *output_directory,
    size_t output_capacity)
{
    char input_name[TEST_LINE_CAPACITY_BYTES];
    char output_name[TEST_LINE_CAPACITY_BYTES];
    (void)snprintf(input_name, sizeof(input_name), "%s-members.csv", case_name);
    (void)snprintf(output_name, sizeof(output_name), "%s-out", case_name);
    build_path(input_path, input_capacity, scratch_root, input_name);
    build_path(output_directory, output_capacity, scratch_root, output_name);
    remove_case_output(output_directory);
    (void)rmdir(output_directory);
    write_text_file(input_path, csv_text);
}

/* (a) m=3、p=0.001/0.02/0.04、alpha=0.05 的完整 Holm 表。
 * 升序 p1=0.001、p2=0.02、p3=0.04；阈值 alpha/(m-k+1) = 0.05/3、0.05/2、0.05/1；
 * adjusted_p(1) = 3*0.001 = 0.003；
 * adjusted_p(2) = max(0.003, 2*0.02) = 0.04；
 * adjusted_p(3) = max(0.04, 1*0.04) = 0.04（前缀最大值保证单调不减）；
 * 三项都 <= 0.05，因此全部 reject。 */
static void check_case_a(const char *program, const char *scratch_root)
{
    static const char *const csv_text =
        "family_id,member_id,mean0_ns,mean1_ns,sd0_ns,sd1_ns,n0,n1,p_two_sided,ci95_low_ns,"
        "ci95_high_ns\n"
        "F1,m1,1,0,1,1,100,100,0.001,-1,3\n"
        "F1,m2,2,0,1,1,100,100,0.02,-1,5\n"
        "F1,m3,3,0,1,1,100,100,0.04,-1,7\n";
    static const double expected_raw_p[3] = {0.001, 0.02, 0.04};
    static const double expected_threshold[3] = {0.05 / 3.0, 0.05 / 2.0, 0.05 / 1.0};
    static const double expected_adjusted_p[3] = {0.003, 0.04, 0.04};
    char input_path[TEST_PATH_CAPACITY_BYTES];
    char output_directory[TEST_PATH_CAPACITY_BYTES];
    char holm_path[TEST_PATH_CAPACITY_BYTES];
    char pooled_path[TEST_PATH_CAPACITY_BYTES];
    char json_path[TEST_PATH_CAPACITY_BYTES];
    char result_path[TEST_PATH_CAPACITY_BYTES];
    char *fields[3u * TEST_COLUMN_COUNT];
    define_case(scratch_root,
        "a",
        csv_text,
        input_path,
        sizeof(input_path),
        output_directory,
        sizeof(output_directory));
    assert(run_holm(program, input_path, output_directory, "0.05") == 0);
    build_path(holm_path, sizeof(holm_path), output_directory, "holm.csv");
    build_path(pooled_path, sizeof(pooled_path), output_directory, "pooled.csv");
    build_path(json_path, sizeof(json_path), output_directory, "holm_summary.json");
    build_path(result_path, sizeof(result_path), output_directory, "RESULT.md");
    assert(read_csv_rows(holm_path, fields, TEST_COLUMN_COUNT, 7u, 3u) == 3u);
    for (size_t row_index = 0u; row_index < 3u; ++row_index) {
        struct holm_row row = read_holm_row(&fields[row_index * TEST_COLUMN_COUNT]);
        assert(strcmp(row.family_id, "F1") == 0);
        assert(row.rank == row_index + 1u);
        expect_close(row.raw_p, expected_raw_p[row_index], "case a raw_p");
        expect_close(row.threshold, expected_threshold[row_index], "case a threshold");
        expect_close(row.adjusted_p, expected_adjusted_p[row_index], "case a adjusted_p");
        assert(row.reject == 1);
    }
    /* 固定效应：theta = 1/2/3，se = sqrt(1/100+1/100) = 1/sqrt(50)，w = 50，sum(w) = 150；
     * pooled = 2；pooled_se = 1/sqrt(150)；Q = 50*((1-2)^2+0+(3-2)^2) = 100 > df = 2；
     * I2 = (100-2)/100*100 = 98。 */
    assert(read_csv_rows(pooled_path, fields, TEST_COLUMN_COUNT, 9u, 1u) == 1u);
    struct pooled_row pooled = read_pooled_row(&fields[0]);
    assert(strcmp(pooled.family_id, "F1") == 0);
    assert(pooled.member_count == 3u);
    assert(pooled.degrees_of_freedom == 2u);
    expect_close(pooled.pooled_effect_ns, 2.0, "case a pooled");
    expect_close(pooled.pooled_se_ns, 1.0 / sqrt(150.0), "case a pooled_se");
    expect_close(pooled.ci95_low_ns, 2.0 - 1.96 / sqrt(150.0), "case a ci95_low");
    expect_close(pooled.ci95_high_ns, 2.0 + 1.96 / sqrt(150.0), "case a ci95_high");
    expect_close(pooled.q_statistic, 100.0, "case a q");
    expect_close(pooled.i2_percent, 98.0, "case a i2");
    expect_contains(json_path, "\"alpha\": 0.05");
    expect_contains(json_path, "\"family_id\": \"F1\"");
    expect_contains(json_path, "\"m\": 3");
    expect_contains(json_path, "\"reject_count\": 3");
    expect_contains(json_path, "\"member_id\": \"m3\"");
    expect_contains(json_path, "\"adjusted_p\": 0.04");
    expect_contains(result_path,
        "Holm 家族按预注册 m 计算；RTLF 与 dudect 一律族外，最大 t 不得转伪 p。");
    remove_case_output(output_directory);
}

/* (b) 边界与「前面不拒绝则其后不拒绝」：
 * F2 三项 p = 0、0.5、1，m=3，alpha=0.05；
 * k=1：3*0 = 0 <= 0.05，reject=1；
 * k=2：max(0, 2*0.5) = 1 > 0.05，reject=0，其后一直不拒绝；
 * k=3：max(1, 1*1) = 1 > 0.05，reject=0。
 * 反例：若只看单项，k=3 的 adjusted_p = 1 并不小，因此另加一项验证保护顺序：
 * F4 的三项 p 为 0.001、0.04、0.04，alpha=0.05 时 k=3 的单项 1*0.04 = 0.04 很小，
 * 但 k=2 的 adjusted_p = max(0.003, 2*0.04) = 0.08 > 0.05 不拒绝，k=3 必须记为 0。
 * m=1 的 F3 只有一项 p=0.5：adjusted_p = 0.5 > 0.05，reject=0，Q=0、df=0、I2=0。 */
static void check_case_b(const char *program, const char *scratch_root)
{
    static const char *const csv_text =
        "family_id,member_id,mean0_ns,mean1_ns,sd0_ns,sd1_ns,n0,n1,p_two_sided,ci95_low_ns,"
        "ci95_high_ns\n"
        "F2,z,1,0,1,1,100,100,0,-1,3\n"
        "F2,mid,1,0,1,1,100,100,0.5,-1,3\n"
        "F2,one,1,0,1,1,100,100,1,-1,3\n"
        "F4,t1,1,0,1,1,100,100,0.001,-1,3\n"
        "F4,t2,1,0,1,1,100,100,0.04,-1,3\n"
        "F4,t3,1,0,1,1,100,100,0.04,-1,3\n"
        "F3,solo,3.5,0.25,1,2,25,100,0.5,0,1\n";
    char input_path[TEST_PATH_CAPACITY_BYTES];
    char output_directory[TEST_PATH_CAPACITY_BYTES];
    char holm_path[TEST_PATH_CAPACITY_BYTES];
    char pooled_path[TEST_PATH_CAPACITY_BYTES];
    char *fields[7u * TEST_COLUMN_COUNT];
    define_case(scratch_root,
        "b",
        csv_text,
        input_path,
        sizeof(input_path),
        output_directory,
        sizeof(output_directory));
    assert(run_holm(program, input_path, output_directory, "0.05") == 0);
    build_path(holm_path, sizeof(holm_path), output_directory, "holm.csv");
    build_path(pooled_path, sizeof(pooled_path), output_directory, "pooled.csv");
    assert(read_csv_rows(holm_path, fields, TEST_COLUMN_COUNT, 7u, 7u) == 7u);
    struct holm_row rows[7];
    for (size_t row_index = 0u; row_index < 7u; ++row_index) {
        rows[row_index] = read_holm_row(&fields[row_index * TEST_COLUMN_COUNT]);
    }
    assert(strcmp(rows[0].family_id, "F2") == 0 && strcmp(rows[0].member_id, "z") == 0);
    assert(rows[0].rank == 1u && rows[0].reject == 1);
    expect_close(rows[0].raw_p, 0.0, "case b p=0 raw");
    expect_close(rows[0].threshold, 0.05 / 3.0, "case b rank1 threshold");
    expect_close(rows[0].adjusted_p, 0.0, "case b rank1 adjusted");
    assert(strcmp(rows[1].member_id, "mid") == 0 && rows[1].rank == 2u && rows[1].reject == 0);
    expect_close(rows[1].adjusted_p, 1.0, "case b rank2 adjusted");
    assert(strcmp(rows[2].member_id, "one") == 0 && rows[2].rank == 3u && rows[2].reject == 0);
    expect_close(rows[2].raw_p, 1.0, "case b p=1 raw");
    expect_close(rows[2].adjusted_p, 1.0, "case b p=1 adjusted");
    /* F4：t2 与 t3 的 p 相同，稳定的次级键保持 t2 在前。 */
    assert(strcmp(rows[3].family_id, "F4") == 0 && strcmp(rows[3].member_id, "t1") == 0);
    assert(rows[3].rank == 1u && rows[3].reject == 1);
    expect_close(rows[3].adjusted_p, 0.003, "case b tie rank1 adjusted");
    assert(strcmp(rows[4].member_id, "t2") == 0 && rows[4].rank == 2u);
    assert(strcmp(rows[5].member_id, "t3") == 0 && rows[5].rank == 3u);
    expect_close(rows[4].adjusted_p, 0.08, "case b tie rank2 adjusted");
    expect_close(rows[5].adjusted_p, 0.08, "case b tie rank3 adjusted");
    assert(rows[4].reject == 0 && rows[5].reject == 0);
    assert(strcmp(rows[6].family_id, "F3") == 0 && strcmp(rows[6].member_id, "solo") == 0);
    assert(rows[6].rank == 1u && rows[6].reject == 0);
    expect_close(rows[6].adjusted_p, 0.5, "case b m=1 adjusted");
    /* F3 的 m=1 合并：theta = 3.5-0.25 = 3.25；se = sqrt(1/25 + 4/100) = sqrt(0.08)；
     * Q = 0（单项），df = 0，I2 = 0。 */
    assert(read_csv_rows(pooled_path, fields, TEST_COLUMN_COUNT, 9u, 3u) == 3u);
    struct pooled_row solo = read_pooled_row(&fields[2u * TEST_COLUMN_COUNT]);
    assert(strcmp(solo.family_id, "F3") == 0);
    assert(solo.member_count == 1u && solo.degrees_of_freedom == 0u);
    expect_close(solo.pooled_effect_ns, 3.25, "case b solo pooled");
    expect_close(solo.pooled_se_ns, sqrt(0.08), "case b solo pooled_se");
    expect_close(solo.q_statistic, 0.0, "case b solo q");
    expect_close(solo.i2_percent, 0.0, "case b solo i2");
    struct pooled_row equal = read_pooled_row(&fields[0]);
    expect_close(equal.pooled_effect_ns, 1.0, "case b equal pooled");
    remove_case_output(output_directory);
}

/* (c) 固定效应合并：等权与不等权各一例。
 * EQ（等权）：n0=n1=100、sd0=sd1=0.5，se^2 = 0.25/100+0.25/100 = 0.005，w = 200；
 * theta = 0.6-0.4 = 0.2 与 0.7-0.5 = 0.2，pooled = 0.2；
 * pooled_se = 1/sqrt(2*200) = 0.05；ci95 = 0.2 +- 1.96*0.05 = [0.102, 0.298]；
 * Q = 200*0+200*0 = 0 <= df = 1，I2 = 0。
 * UN（不等权）：a 行 n0=100、sd0=1、n1=400、sd1=2：se^2 = 0.01+0.01 = 0.02，w = 50；
 * b 行 n0=200、sd0=1.5、n1=100、sd1=2.5：se^2 = 0.01125+0.0625 = 0.07375，w = 800/59；
 * theta_a = 1.1-1.0 = 0.1，theta_b = 2.0-1.0 = 1.0；
 * sum(w) = 50 + 800/59 = 3750/59；
 * pooled = (50*0.1 + (800/59)*1.0) / (3750/59) = (5 + 800/59) * 59/3750 = 1095/3750 = 0.292；
 * pooled_se = 1/sqrt(3750/59) = sqrt(59/3750)；
 * Q = 50*(0.1-0.292)^2 + (800/59)*(1.0-0.292)^2 = 1.8432 + 6.7968 = 8.64 > df = 1；
 * I2 = (8.64-1)/8.64*100 = 88.4259259259259... */
static void check_case_c(const char *program, const char *scratch_root)
{
    static const char *const csv_text =
        "family_id,member_id,mean0_ns,mean1_ns,sd0_ns,sd1_ns,n0,n1,p_two_sided,ci95_low_ns,"
        "ci95_high_ns\n"
        "EQ,eq1,0.6,0.4,0.5,0.5,100,100,0.01,0,1\n"
        "EQ,eq2,0.7,0.5,0.5,0.5,100,100,0.20,0,1\n"
        "UN,a,1.1,1,1,2,100,400,0.01,0,1\n"
        "UN,b,2,1,1.5,2.5,200,100,0.20,0,1\n";
    char input_path[TEST_PATH_CAPACITY_BYTES];
    char output_directory[TEST_PATH_CAPACITY_BYTES];
    char pooled_path[TEST_PATH_CAPACITY_BYTES];
    char *fields[2u * TEST_COLUMN_COUNT];
    define_case(scratch_root,
        "c",
        csv_text,
        input_path,
        sizeof(input_path),
        output_directory,
        sizeof(output_directory));
    assert(run_holm(program, input_path, output_directory, "0.05") == 0);
    build_path(pooled_path, sizeof(pooled_path), output_directory, "pooled.csv");
    assert(read_csv_rows(pooled_path, fields, TEST_COLUMN_COUNT, 9u, 2u) == 2u);
    struct pooled_row equal = read_pooled_row(&fields[0]);
    assert(strcmp(equal.family_id, "EQ") == 0);
    assert(equal.member_count == 2u && equal.degrees_of_freedom == 1u);
    expect_close(equal.pooled_effect_ns, 0.2, "case c equal pooled");
    expect_close(equal.pooled_se_ns, 0.05, "case c equal pooled_se");
    expect_close(equal.ci95_low_ns, 0.102, "case c equal ci95_low");
    expect_close(equal.ci95_high_ns, 0.298, "case c equal ci95_high");
    expect_close(equal.q_statistic, 0.0, "case c equal q");
    expect_close(equal.i2_percent, 0.0, "case c equal i2");
    struct pooled_row unequal = read_pooled_row(&fields[TEST_COLUMN_COUNT]);
    assert(strcmp(unequal.family_id, "UN") == 0);
    assert(unequal.member_count == 2u && unequal.degrees_of_freedom == 1u);
    expect_close(unequal.pooled_effect_ns, 0.292, "case c unequal pooled");
    expect_close(unequal.pooled_se_ns, sqrt(59.0 / 3750.0), "case c unequal pooled_se");
    expect_close(unequal.ci95_low_ns,
        0.292 - 1.96 * sqrt(59.0 / 3750.0),
        "case c unequal ci95_low");
    expect_close(unequal.ci95_high_ns,
        0.292 + 1.96 * sqrt(59.0 / 3750.0),
        "case c unequal ci95_high");
    expect_close(unequal.q_statistic, 8.64, "case c unequal q");
    expect_close(unequal.i2_percent, 100.0 * (8.64 - 1.0) / 8.64, "case c unequal i2");
    remove_case_output(output_directory);
}

/* (d) 非法输入必须非 0 退出；数据类错误固定为 2，且不得留下输出目录。 */
static void check_case_d(const char *program, const char *scratch_root)
{
    static const char *const missing_column =
        "family_id,member_id,mean0_ns,mean1_ns,sd0_ns,sd1_ns,n0,n1,p_two_sided,ci95_low_ns\n"
        "D1,x,1,0,1,1,100,100,0.01,0\n";
    static const char *const non_numeric =
        "family_id,member_id,mean0_ns,mean1_ns,sd0_ns,sd1_ns,n0,n1,p_two_sided,ci95_low_ns,"
        "ci95_high_ns\n"
        "D1,x,1,0,1,1,100,100,abc,0,1\n";
    static const char *const zero_count =
        "family_id,member_id,mean0_ns,mean1_ns,sd0_ns,sd1_ns,n0,n1,p_two_sided,ci95_low_ns,"
        "ci95_high_ns\n"
        "D1,x,1,0,1,1,0,100,0.01,0,1\n";
    static const char *const zero_se =
        "family_id,member_id,mean0_ns,mean1_ns,sd0_ns,sd1_ns,n0,n1,p_two_sided,ci95_low_ns,"
        "ci95_high_ns\n"
        "D1,x,1,0,0,0,100,100,0.01,0,1\n";
    static const char *const duplicated_header =
        "family_id,member_id,mean0_ns,mean1_ns,sd0_ns,sd1_ns,n0,n1,p_two_sided,ci95_low_ns,"
        "ci95_high_ns\n"
        "family_id,member_id,mean0_ns,mean1_ns,sd0_ns,sd1_ns,n0,n1,p_two_sided,ci95_low_ns,"
        "ci95_high_ns\n"
        "D1,x,1,0,1,1,100,100,0.01,0,1\n";
    static const char *const extra_column =
        "family_id,member_id,mean0_ns,mean1_ns,sd0_ns,sd1_ns,n0,n1,p_two_sided,ci95_low_ns,"
        "ci95_high_ns\n"
        "D1,x,1,0,1,1,100,100,0.01,0,1,2\n";
    static const char *const carlf_line =
        "family_id,member_id,mean0_ns,mean1_ns,sd0_ns,sd1_ns,n0,n1,p_two_sided,ci95_low_ns,"
        "ci95_high_ns\r\n"
        "D1,x,1,0,1,1,100,100,0.01,0,1\r\n";
    static const char *const blank_line =
        "family_id,member_id,mean0_ns,mean1_ns,sd0_ns,sd1_ns,n0,n1,p_two_sided,ci95_low_ns,"
        "ci95_high_ns\n"
        "\n"
        "D1,x,1,0,1,1,100,100,0.01,0,1\n";
    static const char *const out_of_range_p =
        "family_id,member_id,mean0_ns,mean1_ns,sd0_ns,sd1_ns,n0,n1,p_two_sided,ci95_low_ns,"
        "ci95_high_ns\n"
        "D1,x,1,0,1,1,100,100,1.5,0,1\n";
    static const char *const cases[][2] = {
        {"missing_column", missing_column},
        {"non_numeric", non_numeric},
        {"zero_count", zero_count},
        {"zero_se", zero_se},
        {"duplicated_header", duplicated_header},
        {"extra_column", extra_column},
        {"carlf", carlf_line},
        {"blank_line", blank_line},
        {"out_of_range_p", out_of_range_p},
    };
    for (size_t case_index = 0u; case_index < sizeof(cases) / sizeof(cases[0]); ++case_index) {
        char input_path[TEST_PATH_CAPACITY_BYTES];
        char output_directory[TEST_PATH_CAPACITY_BYTES];
        char holm_path[TEST_PATH_CAPACITY_BYTES];
        struct stat directory_status;
        define_case(scratch_root,
            cases[case_index][0],
            cases[case_index][1],
            input_path,
            sizeof(input_path),
            output_directory,
            sizeof(output_directory));
        int exit_code = run_holm(program, input_path, output_directory, "0.05");
        if (exit_code != 2) {
            fprintf(stderr, "case d %s: exit %d, expected 2\n", cases[case_index][0], exit_code);
            assert(0);
        }
        /* 计算全部成功之前不得建目录，避免留下半个结果。 */
        assert(stat(output_directory, &directory_status) != 0);
        build_path(holm_path, sizeof(holm_path), output_directory, "holm.csv");
        assert(stat(holm_path, &directory_status) != 0);
        (void)remove(input_path);
    }

    /* 输出目录必须不存在：先准备一份合法输入，再让目录先存在。 */
    char input_path[TEST_PATH_CAPACITY_BYTES];
    char output_directory[TEST_PATH_CAPACITY_BYTES];
    char marker_path[TEST_PATH_CAPACITY_BYTES];
    char pooled_path[TEST_PATH_CAPACITY_BYTES];
    define_case(scratch_root,
        "existing_output",
        "family_id,member_id,mean0_ns,mean1_ns,sd0_ns,sd1_ns,n0,n1,p_two_sided,ci95_low_ns,"
        "ci95_high_ns\n"
        "D1,x,1,0,1,1,100,100,0.01,0,1\n",
        input_path,
        sizeof(input_path),
        output_directory,
        sizeof(output_directory));
    assert(mkdir(output_directory, 0700) == 0);
    build_path(marker_path, sizeof(marker_path), output_directory, "keep.txt");
    write_text_file(marker_path, "keep\n");
    assert(run_holm(program, input_path, output_directory, "0.05") != 0);
    /* 已存在目录里的内容不能被改写或删除。 */
    expect_contains(marker_path, "keep");
    build_path(pooled_path, sizeof(pooled_path), output_directory, "pooled.csv");
    struct stat file_status;
    assert(stat(pooled_path, &file_status) != 0);
    (void)remove(marker_path);
    (void)rmdir(output_directory);

    /* 命令行用法错误：缺少 --alpha、非法 alpha、缺输入文件。 */
    define_case(scratch_root,
        "usage",
        "family_id,member_id,mean0_ns,mean1_ns,sd0_ns,sd1_ns,n0,n1,p_two_sided,ci95_low_ns,"
        "ci95_high_ns\n"
        "D1,x,1,0,1,1,100,100,0.01,0,1\n",
        input_path,
        sizeof(input_path),
        output_directory,
        sizeof(output_directory));
    assert(run_holm(program, input_path, output_directory, NULL) != 0);
    assert(run_holm(program, input_path, output_directory, "1.5") != 0);
    char missing_input[TEST_PATH_CAPACITY_BYTES];
    build_path(missing_input, sizeof(missing_input), scratch_root, "does-not-exist.csv");
    assert(run_holm(program, missing_input, output_directory, "0.05") != 0);
    assert(stat(output_directory, &file_status) != 0);
    (void)remove(input_path);
    (void)remove(missing_input);
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

/* 临时根候选：CTest 给的 A113_TEST_TMPDIR、当前目录、/tmp，取第一个可用者可写。 */
static const char *select_scratch_root(void)
{
    const char *candidates[3];
    const char *configured_root = getenv("A113_TEST_TMPDIR");
    char scratch_path[TEST_PATH_CAPACITY_BYTES];
    candidates[0] = configured_root;
    candidates[1] = ".";
    candidates[2] = "/tmp";
    static char selected_scratch[TEST_PATH_CAPACITY_BYTES];
    for (size_t candidate_index = 0u; candidate_index < 3u; ++candidate_index) {
        struct stat scratch_status;
        if (candidates[candidate_index] == NULL ||
            stat(candidates[candidate_index], &scratch_status) != 0 ||
            !S_ISDIR(scratch_status.st_mode)) {
            continue;
        }
        int written = snprintf(scratch_path,
            sizeof(scratch_path),
            "%s/platform-holm-scratch-%ld",
            candidates[candidate_index],
            (long)getpid());
        assert(written > 0 && (size_t)written < sizeof(scratch_path));
        if (mkdir(scratch_path, 0700) == 0) {
            (void)snprintf(selected_scratch, sizeof(selected_scratch), "%s", scratch_path);
            return selected_scratch;
        }
    }
    fputs("error: no writable scratch root for platform_holm tests\n", stderr);
    return NULL;
}

int main(int argument_count, char **argument_values)
{
    assert(argument_count == 2);
    const char *program = absolute_program_path(argument_values[1]);
    const char *scratch_root = select_scratch_root();
    if (scratch_root == NULL) {
        return 1;
    }
    check_case_a(program, scratch_root);
    check_case_b(program, scratch_root);
    check_case_c(program, scratch_root);
    check_case_d(program, scratch_root);
    (void)rmdir(scratch_root);
    puts("platform_holm: cases a/b/c/d pass");
    return 0;
}
