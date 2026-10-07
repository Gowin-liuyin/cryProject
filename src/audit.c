#define _XOPEN_SOURCE 700
#define _POSIX_C_SOURCE 200809L

#include "build_identity.h"
#include "controlled_statistics.h"
#include "paired_data.h"

#include <errno.h>
#include <fcntl.h>
#include <inttypes.h>
#include <signal.h>
#include <stdlib.h>
#include <string.h>
#include <sys/stat.h>
#include <sys/utsname.h>
#include <sys/wait.h>
#include <time.h>
#include <unistd.h>

#define ORDINARY_METADATA_COUNT 17u

struct ordinary_dataset {
    struct measurement_set measurements;
    char metadata[ORDINARY_METADATA_COUNT][256];
    char csv_digest[65];
    uint64_t total_duration_ns;
};

static const char *const metadata_names[ORDINARY_METADATA_COUNT] = {"run_id",
    "implementation",
    "sample_count",
    "run_status",
    "sanitizers",
    "source_commit",
    "ordered_input_digest",
    "test_seed",
    "executable_digest",
    "clock",
    "time_unit",
    "measurement_format",
    "formal_attempted_calls",
    "formal_completed_calls",
    "warmup_attempted_calls",
    "warmup_completed_calls",
    "outputs_consumed"};
static const char *const safe_variants[3] = {"reference", "hardened", "deployable"};
static volatile sig_atomic_t active_child;
static volatile sig_atomic_t deadline_expired;
static uint64_t last_process_wall_ns;

static void stop_child(int signal_number)
{
    (void)signal_number;
    deadline_expired = 1;
    if (active_child > 0) {
        (void)kill((pid_t)active_child, SIGKILL);
    }
}

static int make_path(char *path, size_t capacity, const char *directory, const char *filename)
{
    int path_length = snprintf(path, capacity, "%s/%s", directory, filename);
    return path_length < 0 || (size_t)path_length >= capacity;
}

static int execute_program(char *const arguments[], const char *log_path)
{
    struct timespec start_time;
    struct timespec finish_time;
    last_process_wall_ns = 0;
    if (deadline_expired || clock_gettime(CLOCK_MONOTONIC, &start_time) != 0) {
        return 125;
    }
    int log_descriptor = -1;
    if (log_path != NULL) {
        log_descriptor = open(log_path, O_WRONLY | O_CREAT | O_EXCL, 0600);
        if (log_descriptor < 0) {
            return 1;
        }
    }
    fflush(stdout);
    pid_t child_process = fork();
    if (child_process == 0) {
        if (log_descriptor >= 0) {
            if (dup2(log_descriptor, STDOUT_FILENO) < 0 ||
                dup2(log_descriptor, STDERR_FILENO) < 0) {
                _exit(125);
            }
            (void)close(log_descriptor);
        }
        execvp(arguments[0], arguments);
        _exit(127);
    }
    if (log_descriptor >= 0) {
        (void)close(log_descriptor);
    }
    if (child_process < 0) {
        return 1;
    }
    active_child = (sig_atomic_t)child_process;
    if (deadline_expired) {
        (void)kill(child_process, SIGKILL);
    }
    int wait_status;
    while (waitpid(child_process, &wait_status, 0) < 0) {
        if (errno != EINTR) {
            (void)kill(child_process, SIGKILL);
            active_child = 0;
            return 1;
        }
    }
    active_child = 0;
    if (clock_gettime(CLOCK_MONOTONIC, &finish_time) != 0) {
        return 125;
    }
    uint64_t start_ns =
        (uint64_t)start_time.tv_sec * UINT64_C(1000000000) + (uint64_t)start_time.tv_nsec;
    uint64_t finish_ns =
        (uint64_t)finish_time.tv_sec * UINT64_C(1000000000) + (uint64_t)finish_time.tv_nsec;
    if (finish_ns < start_ns) {
        return 125;
    }
    last_process_wall_ns = finish_ns - start_ns;
    return WIFEXITED(wait_status) ? WEXITSTATUS(wait_status) : 128;
}

static int load_ordinary_dataset(const char *csv_path,
    const char *metadata_path,
    struct ordinary_dataset *dataset)
{
    memset(dataset, 0, sizeof(*dataset));
    struct paired_text_field fields[ORDINARY_METADATA_COUNT];
    for (size_t field_index = 0; field_index < ORDINARY_METADATA_COUNT; ++field_index) {
        fields[field_index] = (struct paired_text_field){metadata_names[field_index],
            dataset->metadata[field_index],
            sizeof(dataset->metadata[field_index]),
            0};
    }
    if (load_measurement_set(csv_path, &dataset->measurements) != 0 ||
        read_paired_fields(metadata_path, fields, ORDINARY_METADATA_COUNT) != 0 ||
        paired_digest_file(csv_path, dataset->csv_digest) != 0 ||
        strcmp(dataset->metadata[0], dataset->measurements.run_id) != 0 ||
        strcmp(dataset->metadata[1], dataset->measurements.implementation) != 0 ||
        strcmp(dataset->metadata[3], "complete") != 0 || strcmp(dataset->metadata[4], "OFF") != 0 ||
        !is_paired_hex(dataset->metadata[6], 64) || !is_paired_hex(dataset->metadata[8], 64) ||
        strcmp(dataset->metadata[9], "CLOCK_MONOTONIC") != 0 ||
        strcmp(dataset->metadata[10], "ns") != 0 ||
        strcmp(dataset->metadata[11], "reference_ordinary_v1") != 0) {
        free(dataset->measurements.records);
        dataset->measurements.records = NULL;
        return 1;
    }
    uint64_t expected_count;
    uint64_t test_seed;
    size_t category_counts[3] = {0};
    if (parse_unsigned_integer(dataset->metadata[2], &expected_count) != 0 ||
        expected_count != dataset->measurements.record_count ||
        expected_count > UINT64_MAX - 100u ||
        parse_unsigned_integer(dataset->metadata[7], &test_seed) != 0) {
        goto invalid;
    }
    uint64_t expected_counters[5] = {expected_count,
        expected_count,
        100u,
        100u,
        expected_count + 100u};
    for (size_t counter_index = 0; counter_index < 5u; ++counter_index) {
        uint64_t actual_counter;
        if (parse_unsigned_integer(dataset->metadata[counter_index + 12u], &actual_counter) != 0 ||
            actual_counter != expected_counters[counter_index]) {
            goto invalid;
        }
    }
    for (size_t record_index = 0; record_index < dataset->measurements.record_count;
        ++record_index) {
        const struct measurement_record *record = &dataset->measurements.records[record_index];
        if (record->category_index >= 3u ||
            record->elapsed_nanoseconds > (uint64_t)CONTROLLED_MAXIMUM_DIFFERENCE_NS ||
            dataset->total_duration_ns > UINT64_MAX - record->elapsed_nanoseconds) {
            goto invalid;
        }
        ++category_counts[record->category_index];
        dataset->total_duration_ns += record->elapsed_nanoseconds;
    }
    if (category_counts[0] == 0 || category_counts[0] != category_counts[1] ||
        category_counts[0] != category_counts[2]) {
        goto invalid;
    }
    struct measurement_cost cost;
    if (load_measurement_cost(csv_path,
            dataset->measurements.run_id,
            expected_count,
            dataset->total_duration_ns,
            &cost) != 0) {
        goto invalid;
    }
    return 0;
invalid:
    free(dataset->measurements.records);
    dataset->measurements.records = NULL;
    return 1;
}

static int write_escaped(FILE *output, const char *text)
{
    for (const char *character = text; *character != '\0'; ++character) {
        const char *replacement = *character == '&' ? "&amp;"
            : *character == '<'                     ? "&lt;"
            : *character == '>'                     ? "&gt;"
            : *character == '"'                     ? "&quot;"
            : *character == '\''                    ? "&#39;"
                                                    : NULL;
        if ((replacement != NULL && fputs(replacement, output) == EOF) ||
            (replacement == NULL && fputc((unsigned char)*character, output) == EOF)) {
            return 1;
        }
    }
    return 0;
}

static int write_link(FILE *output, const char *path, const char *label)
{
    const char *filename = strrchr(path, '/');
    filename = filename == NULL ? path : filename + 1;
    return fputs("<a href=\"./", output) == EOF || write_escaped(output, filename) != 0 ||
        fputs("\">", output) == EOF || write_escaped(output, label) != 0 ||
        fputs("</a>", output) == EOF;
}

static int export_html(const char *csv_path,
    const char *metadata_path,
    const char *html_path,
    const char *origin)
{
    struct ordinary_dataset dataset;
    if (load_ordinary_dataset(csv_path, metadata_path, &dataset) != 0) {
        return 1;
    }
    struct measurement_record *sorted_records =
        malloc(dataset.measurements.record_count * sizeof(*sorted_records));
    FILE *output = NULL;
    char temporary_html_path[4096];
    char cost_path[4096];
    int operation_status = 1;
    int temporary_path_length = snprintf(temporary_html_path,
        sizeof(temporary_html_path),
        "%s.partial.%jd",
        html_path,
        (intmax_t)getpid());
    int cost_path_length = snprintf(cost_path, sizeof(cost_path), "%s.cost", csv_path);
    if (sorted_records == NULL || temporary_path_length < 0 ||
        (size_t)temporary_path_length >= sizeof(temporary_html_path) || cost_path_length < 0 ||
        (size_t)cost_path_length >= sizeof(cost_path)) {
        goto cleanup;
    }
    memcpy(sorted_records,
        dataset.measurements.records,
        dataset.measurements.record_count * sizeof(*sorted_records));
    sort_records_by_category_then_duration(sorted_records, dataset.measurements.record_count);
    output = fopen(temporary_html_path, "wx");
    if (output == NULL) {
        goto cleanup;
    }
    if (fputs("<!doctype html><html lang=\"zh-CN\"><meta charset=\"utf-8\">"
              "<meta name=\"viewport\" content=\"width=device-width,initial-scale=1\">"
              "<title>ML-KEM 普通负载结果</title><style>body{font:16px/1.7 "
              "sans-serif;max-width:1000px;"
              "margin:48px auto;padding:0 24px;color:#172734;background:#f5f7f8}h1{font-size:30px}"
              "table{border-collapse:collapse;width:100%;background:white}th,td{padding:10px;text-"
              "align:left;"
              "border-bottom:1px solid #d8e0e5}code{overflow-wrap:anywhere}a{color:#17647a}"
              ".note{padding:16px;background:#fff3d6}footer{font-size:13px;margin-top:32px}</style>"
              "<h1>ML-KEM 普通负载结果</h1><p>数据身份：",
            output) == EOF ||
        write_escaped(output, origin) != 0 || fputs("。运行编号：<code>", output) == EOF ||
        write_escaped(output, dataset.measurements.run_id) != 0 ||
        fprintf(output,
            "</code>。共 %zu 条逐次记录，三类比例 1:1:1，记录、阶段成本和完成状态已核验。</p>"
            "<p>对象：",
            dataset.measurements.record_count) < 0 ||
        write_escaped(output, dataset.measurements.implementation) != 0 ||
        fputs("。计时覆盖完整解封装；没有删长尾，也没有扣计时开销。</p>"
              "<table><tr><th>输入类别</th><th>记录数</th><th>均值 ns</th><th>P50 ns</th><th>P90 "
              "ns</th><th>P99 ns</th></tr>",
            output) == EOF) {
        goto cleanup;
    }
    size_t category_count = dataset.measurements.record_count / 3u;
    for (size_t category_index = 0; category_index < 3u; ++category_index) {
        struct sample_series series = {sorted_records + category_index * category_count,
            category_count};
        double mean_ns;
        double variance_ns_squared;
        series_moments(&series, &mean_ns, &variance_ns_squared);
        if (fprintf(output,
                "<tr><td>%s</td><td>%zu</td><td>%.3f</td><td>%" PRIu64 "</td><td>%" PRIu64
                "</td><td>%" PRIu64 "</td></tr>",
                input_category_name((enum input_category)category_index),
                category_count,
                mean_ns,
                series_quantile(&series, 0.5),
                series_quantile(&series, 0.9),
                series_quantile(&series, 0.99)) < 0) {
            goto cleanup;
        }
    }
    if (fputs("</table><p>分位数：floor(p × (n−1) + 0.5) "
              "零基下标，不插值。纳秒是单位，不代表精度。</p>"
              "<p class=\"note\">该页是普通负载的描述统计，未进行秘密归因或恒时认证。"
              "单次运行不能给出运行总体置信区间；批次窗口不能提供单次 P99。</p>"
              "<h2>证据与复算</h2><p>",
            output) == EOF ||
        write_link(output, csv_path, "逐次原始数据") != 0 || fputs(" · ", output) == EOF ||
        write_link(output, metadata_path, "环境及方法记录") != 0 || fputs(" · ", output) == EOF ||
        write_link(output, cost_path, "阶段成本及完成记录") != 0 ||
        fputs("</p><p>原始数据 SHA3-256：<code>", output) == EOF ||
        write_escaped(output, dataset.csv_digest) != 0 ||
        fputs("</code></p><p>被测源码身份：<code>", output) == EOF ||
        write_escaped(output, dataset.metadata[5]) != 0 ||
        fputs("</code>。公开输入流摘要：<code>", output) == EOF ||
        write_escaped(output, dataset.metadata[6]) != 0 ||
        fputs("</code></p><p>复算：<code>audit inspect 数据.csv "
              "新描述.report</code>。定位、防护、对照、"
              "未闭合项及完整交接见支撑包的证据索引；历史案例与本次普通记录分开解释。</p>"
              "<footer>导出状态：完整。元数据声明需结合采集退出码、源码和产物清单核查。"
              "该页的数据链接要求 HTML 与 CSV/meta/cost 放在同一目录。</footer></html>\n",
            output) == EOF) {
        goto cleanup;
    }
    operation_status = 0;
cleanup:
    if (output != NULL) {
        int flush_failed = fflush(output) != 0 || fsync(fileno(output)) != 0;
        if (fclose(output) != 0 || flush_failed) {
            operation_status = 1;
        }
    }
    if (operation_status == 0) {
        if (link(temporary_html_path, html_path) != 0 || unlink(temporary_html_path) != 0) {
            operation_status = 1;
        }
    }
    free(sorted_records);
    free(dataset.measurements.records);
    return operation_status;
}

static int files_equal(const char *first_path, const char *second_path)
{
    FILE *first_file = fopen(first_path, "rb");
    FILE *second_file = fopen(second_path, "rb");
    int equal = first_file != NULL && second_file != NULL;
    while (equal) {
        int first_byte = fgetc(first_file);
        int second_byte = fgetc(second_file);
        if (first_byte != second_byte) {
            equal = 0;
        } else if (first_byte == EOF) {
            break;
        }
    }
    if (first_file != NULL) {
        int read_failed = ferror(first_file);
        if (fclose(first_file) != 0 || read_failed) {
            equal = 0;
        }
    }
    if (second_file != NULL) {
        int read_failed = ferror(second_file);
        if (fclose(second_file) != 0 || read_failed) {
            equal = 0;
        }
    }
    return equal;
}

static int
replay_archive(const char *binary_directory, const char *source_directory, const char *new_output)
{
    char output_directory[4096];
    if (mkdir(new_output, 0700) != 0 || realpath(new_output, output_directory) == NULL ||
        chdir(source_directory) != 0) {
        return 1;
    }
    char integrity_log[4096];
    if (make_path(integrity_log, sizeof(integrity_log), output_directory, "integrity.log") != 0) {
        return 1;
    }
    char *integrity_arguments[] =
        {"shasum", "-a", "256", "-c", "docs/evidence/statistics-multiseed/SHA256SUMS", NULL};
    if (execute_program(integrity_arguments, integrity_log) != 0) {
        fputs("封存清单校验失败；停止复算并保留日志。\n", stderr);
        return 1;
    }
    const uint64_t seeds[5] = {31337, 90210, 8675309, 20261111, 141421356};
    const char *variants[4] = {"reference", "vulnerable", "hardened", "deployable"};
    size_t replayed_reports = 0;
    for (size_t variant_index = 0; variant_index < 4u; ++variant_index) {
        for (size_t seed_index = 0; seed_index < 5u; ++seed_index) {
            char csv_path[256];
            (void)snprintf(csv_path,
                sizeof(csv_path),
                "docs/evidence/statistics-multiseed/%s-seed%" PRIu64 ".csv",
                variants[variant_index],
                seeds[seed_index]);
            for (size_t method_index = 0; method_index < 2u; ++method_index) {
                char program_path[4096];
                char report_path[4096];
                char archived_path[256];
                char report_name[192];
                (void)snprintf(report_name,
                    sizeof(report_name),
                    "%s-seed%" PRIu64 "%s.report",
                    variants[variant_index],
                    seeds[seed_index],
                    method_index == 0 ? "" : ".groups");
                if (make_path(program_path,
                        sizeof(program_path),
                        binary_directory,
                        method_index == 0 ? "analyze" : "analyze_groups") != 0 ||
                    make_path(report_path, sizeof(report_path), output_directory, report_name) !=
                        0 ||
                    make_path(archived_path,
                        sizeof(archived_path),
                        "docs/evidence/statistics-multiseed",
                        report_name) != 0) {
                    return 1;
                }
                char *arguments[] = {program_path, csv_path, report_path, NULL};
                if (execute_program(arguments, NULL) != 0 ||
                    !files_equal(archived_path, report_path)) {
                    fputs("复算存在错误或跨平台数值差异；保留新输出供核查。\n", stderr);
                    return 1;
                }
                ++replayed_reports;
            }
        }
    }
    printf("历史重分析完成：%zu 份报告逐字一致；未重新采集，名义模型与旧限制保留。\n",
        replayed_reports);
    return 0;
}

static int collect_ordinary(const char *binary_directory, char **argument_values)
{
    char program_path[4096];
    char csv_path[4096];
    char metadata_path[4096];
    char summary_path[4096];
    char html_path[4096];
    char log_path[4096];
    const char *output_directory = argument_values[5];
    if (mkdir(output_directory, 0700) != 0 ||
        make_path(program_path, sizeof(program_path), binary_directory, "reference/benchmark") !=
            0 ||
        make_path(csv_path, sizeof(csv_path), output_directory, "data.csv") != 0 ||
        make_path(metadata_path, sizeof(metadata_path), output_directory, "data.meta") != 0 ||
        make_path(summary_path, sizeof(summary_path), output_directory, "description.report") !=
            0 ||
        make_path(html_path, sizeof(html_path), output_directory, "index.html") != 0 ||
        make_path(log_path, sizeof(log_path), output_directory, "collection.log") != 0) {
        return 1;
    }
    char *collect_arguments[] = {program_path,
        argument_values[2],
        argument_values[3],
        argument_values[4],
        csv_path,
        metadata_path,
        NULL};
    puts("正在采集参考实现的普通三类负载；保留每次原始值。");
    if (execute_program(collect_arguments, log_path) != 0 ||
        make_path(program_path, sizeof(program_path), binary_directory, "inspect_timing") != 0) {
        return 1;
    }
    char *inspect_arguments[] = {program_path, csv_path, summary_path, NULL};
    if (execute_program(inspect_arguments, NULL) != 0 ||
        export_html(csv_path, metadata_path, html_path, "本次普通采集") != 0) {
        return 1;
    }
    printf("采集及记录核验完成。描述页面：%s\n", html_path);
    return 0;
}

static int write_performance_comparisons(FILE *report, uint64_t totals_ns[3][6])
{
    for (size_t variant_index = 1; variant_index < 3u; ++variant_index) {
        int64_t differences_ns[6];
        long double reference_sum = 0.0L;
        for (size_t block_index = 0; block_index < 6u; ++block_index) {
            if (totals_ns[0][block_index] > (uint64_t)CONTROLLED_MAXIMUM_DIFFERENCE_NS ||
                totals_ns[variant_index][block_index] >
                    (uint64_t)CONTROLLED_MAXIMUM_DIFFERENCE_NS) {
                return 1;
            }
            differences_ns[block_index] =
                (int64_t)totals_ns[variant_index][block_index] - (int64_t)totals_ns[0][block_index];
            reference_sum += (long double)totals_ns[0][block_index];
        }
        struct controlled_result result;
        if (compute_controlled_result(differences_ns, 6, 1, &result) != 0 ||
            fprintf(report,
                "comparison=%s:reference mean_difference_ns=%.9Lf relative_overhead=%.9Lf"
                " interval_lower_ns=%.9Lf interval_upper_ns=%.9Lf\n",
                safe_variants[variant_index],
                result.mean_difference_ns / 3000.0L,
                result.mean_difference_ns * 6.0L / reference_sum,
                result.interval_lower_ns / 3000.0L,
                result.interval_upper_ns / 3000.0L) < 0) {
            return 1;
        }
    }
    return 0;
}

static int safe_performance(const char *binary_directory, const char *output_directory)
{
    char report_path[4096];
    char ledger_path[4096];
    if (mkdir(output_directory, 0700) != 0 ||
        make_path(report_path, sizeof(report_path), output_directory, "performance.report") != 0 ||
        make_path(ledger_path, sizeof(ledger_path), output_directory, "attempts.tsv") != 0) {
        return 1;
    }
    struct sigaction action = {0};
    action.sa_handler = stop_child;
    if (sigemptyset(&action.sa_mask) != 0 || sigaction(SIGALRM, &action, NULL) != 0) {
        return 1;
    }
    (void)alarm(180);
    FILE *ledger = fopen(ledger_path, "wx");
    FILE *report = fopen(report_path, "wx");
    uint64_t totals_ns[3][6] = {{0}};
    char source_identity[256] = "";
    int operation_status = 1;
    if (ledger == NULL || report == NULL ||
        fputs("block\timplementation\texit_status\tparent_process_wall_ns\n", ledger) == EOF ||
        fputs("format=safe_ordinary_performance_v1\nblocks=6\nformal_calls_per_run=3000\n"
              "warmup_calls_per_run=100\nplanned_total_calls=55800\nclock=CLOCK_MONOTONIC\n"
              "time_unit=ns\ninterval_scope=exploratory_iid_run_pair_bootstrap_only\n"
              "secret_attribution=not_assessed\n",
            report) == EOF) {
        goto cleanup;
    }
    const size_t orders[6][3] = {{0, 1, 2}, {1, 2, 0}, {2, 0, 1}, {2, 1, 0}, {1, 0, 2}, {0, 2, 1}};
    for (size_t block_index = 0; block_index < 6u; ++block_index) {
        if (deadline_expired) {
            goto cleanup;
        }
        char input_digest[65] = "";
        for (size_t position_index = 0; position_index < 3u; ++position_index) {
            size_t variant_index = orders[block_index][position_index];
            const char *variant = safe_variants[variant_index];
            char executable_path[4096];
            char csv_path[4096];
            char metadata_path[4096];
            char log_path[4096];
            char run_name[128];
            char filename[192];
            char seed_text[32];
            char executable_digest[65];
            (void)snprintf(run_name,
                sizeof(run_name),
                "ordinary-%s-block%zu",
                variant,
                block_index + 1u);
            (void)snprintf(seed_text,
                sizeof(seed_text),
                "%" PRIu64,
                UINT64_C(202610072000) + block_index + 1u);
            (void)snprintf(filename, sizeof(filename), "%s/benchmark", variant);
            if (make_path(executable_path, sizeof(executable_path), binary_directory, filename) !=
                    0 ||
                paired_digest_file(executable_path, executable_digest) != 0) {
                goto cleanup;
            }
            (void)snprintf(filename, sizeof(filename), "%s.csv", run_name);
            if (make_path(csv_path, sizeof(csv_path), output_directory, filename) != 0) {
                goto cleanup;
            }
            (void)snprintf(filename, sizeof(filename), "%s.meta", run_name);
            if (make_path(metadata_path, sizeof(metadata_path), output_directory, filename) != 0) {
                goto cleanup;
            }
            (void)snprintf(filename, sizeof(filename), "%s.log", run_name);
            if (make_path(log_path, sizeof(log_path), output_directory, filename) != 0) {
                goto cleanup;
            }
            char *arguments[] =
                {executable_path, run_name, seed_text, "1000", csv_path, metadata_path, NULL};
            int child_status = execute_program(arguments, log_path);
            if (fprintf(ledger,
                    "%zu\t%s\t%d\t%" PRIu64 "\n",
                    block_index + 1u,
                    variant,
                    child_status,
                    last_process_wall_ns) < 0 ||
                fflush(ledger) != 0 || child_status != 0) {
                goto cleanup;
            }
            struct ordinary_dataset dataset;
            if (load_ordinary_dataset(csv_path, metadata_path, &dataset) != 0) {
                goto cleanup;
            }
            int invalid = dataset.measurements.record_count != 3000u ||
                strcmp(dataset.metadata[1], variant) != 0 ||
                strcmp(dataset.metadata[7], seed_text) != 0 ||
                strcmp(dataset.metadata[8], executable_digest) != 0 ||
                (input_digest[0] != '\0' && strcmp(input_digest, dataset.metadata[6]) != 0) ||
                (source_identity[0] != '\0' && strcmp(source_identity, dataset.metadata[5]) != 0);
            if (input_digest[0] == '\0') {
                (void)snprintf(input_digest, sizeof(input_digest), "%.64s", dataset.metadata[6]);
            }
            if (source_identity[0] == '\0') {
                memcpy(source_identity, dataset.metadata[5], sizeof(source_identity));
            }
            totals_ns[variant_index][block_index] = dataset.total_duration_ns;
            sort_range_by_duration(dataset.measurements.records, dataset.measurements.record_count);
            struct sample_series series = {dataset.measurements.records,
                dataset.measurements.record_count};
            if (invalid ||
                fprintf(report,
                    "run=%s seed=%s count=3000 mean_ns=%.9Lf p50_ns=%" PRIu64 " p90_ns=%" PRIu64
                    " p99_ns=%" PRIu64 " csv_digest=%s\n",
                    run_name,
                    seed_text,
                    (long double)dataset.total_duration_ns / 3000.0L,
                    series_quantile(&series, 0.5),
                    series_quantile(&series, 0.9),
                    series_quantile(&series, 0.99),
                    dataset.csv_digest) < 0) {
                free(dataset.measurements.records);
                goto cleanup;
            }
            free(dataset.measurements.records);
        }
    }
    if (write_performance_comparisons(report, totals_ns) != 0) {
        goto cleanup;
    }
    if (deadline_expired ||
        fprintf(report,
            "source_identity=%s\nformal_completed_calls=54000\nwarmup_completed_calls=1800\n"
            "result_status=ordinary_performance_description_only\nreport_status=complete\n",
            source_identity) < 0) {
        goto cleanup;
    }
    operation_status = 0;
cleanup:
    (void)alarm(0);
    if (ledger != NULL && fclose(ledger) != 0) {
        operation_status = 1;
    }
    if (report != NULL && fclose(report) != 0) {
        operation_status = 1;
    }
    return operation_status;
}

static int replay_performance(const char *data_directory, const char *report_path)
{
    FILE *report = fopen(report_path, "wx");
    uint64_t totals_ns[3][6] = {{0}};
    char source_identity[256] = "";
    char executable_digests[3][65] = {{0}};
    int operation_status = 1;
    if (report == NULL ||
        fputs("format=safe_ordinary_performance_v1\nblocks=6\nformal_calls_per_run=3000\n"
              "warmup_calls_per_run=100\nplanned_total_calls=55800\nclock=CLOCK_MONOTONIC\n"
              "time_unit=ns\ninterval_scope=exploratory_iid_run_pair_bootstrap_only\nsecret_"
              "attribution=not_assessed\n",
            report) == EOF) {
        goto cleanup;
    }
    const size_t orders[6][3] = {{0, 1, 2}, {1, 2, 0}, {2, 0, 1}, {2, 1, 0}, {1, 0, 2}, {0, 2, 1}};
    for (size_t block_index = 0; block_index < 6u; ++block_index) {
        char input_digest[65] = "";
        for (size_t position_index = 0; position_index < 3u; ++position_index) {
            size_t variant_index = orders[block_index][position_index];
            char run_name[128];
            char filename[192];
            char csv_path[4096];
            char metadata_path[4096];
            char seed_text[32];
            (void)snprintf(run_name,
                sizeof(run_name),
                "ordinary-%s-block%zu",
                safe_variants[variant_index],
                block_index + 1u);
            (void)snprintf(filename, sizeof(filename), "%s.csv", run_name);
            if (make_path(csv_path, sizeof(csv_path), data_directory, filename) != 0) {
                goto cleanup;
            }
            (void)snprintf(filename, sizeof(filename), "%s.meta", run_name);
            if (make_path(metadata_path, sizeof(metadata_path), data_directory, filename) != 0) {
                goto cleanup;
            }
            (void)snprintf(seed_text,
                sizeof(seed_text),
                "%" PRIu64,
                UINT64_C(202610072001) + block_index);
            struct ordinary_dataset dataset;
            if (load_ordinary_dataset(csv_path, metadata_path, &dataset) != 0) {
                goto cleanup;
            }
            int invalid = dataset.measurements.record_count != 3000u ||
                strcmp(dataset.metadata[1], safe_variants[variant_index]) != 0 ||
                strcmp(dataset.metadata[7], seed_text) != 0 ||
                (source_identity[0] != '\0' && strcmp(source_identity, dataset.metadata[5]) != 0) ||
                (input_digest[0] != '\0' && strcmp(input_digest, dataset.metadata[6]) != 0) ||
                (executable_digests[variant_index][0] != '\0' &&
                    strcmp(executable_digests[variant_index], dataset.metadata[8]) != 0);
            memcpy(source_identity, dataset.metadata[5], sizeof(source_identity));
            (void)snprintf(input_digest, sizeof(input_digest), "%.64s", dataset.metadata[6]);
            (void)snprintf(executable_digests[variant_index],
                sizeof(executable_digests[0]),
                "%.64s",
                dataset.metadata[8]);
            totals_ns[variant_index][block_index] = dataset.total_duration_ns;
            sort_range_by_duration(dataset.measurements.records, dataset.measurements.record_count);
            struct sample_series series = {dataset.measurements.records,
                dataset.measurements.record_count};
            if (invalid ||
                fprintf(report,
                    "run=%s seed=%s count=3000 mean_ns=%.9Lf p50_ns=%" PRIu64 " p90_ns=%" PRIu64
                    " p99_ns=%" PRIu64 " csv_digest=%s\n",
                    run_name,
                    seed_text,
                    (long double)dataset.total_duration_ns / 3000.0L,
                    series_quantile(&series, 0.5),
                    series_quantile(&series, 0.9),
                    series_quantile(&series, 0.99),
                    dataset.csv_digest) < 0) {
                free(dataset.measurements.records);
                goto cleanup;
            }
            free(dataset.measurements.records);
        }
    }
    if (write_performance_comparisons(report, totals_ns) != 0 ||
        fprintf(report,
            "source_identity=%s\nformal_completed_calls=54000\nwarmup_completed_calls=1800\n"
            "result_status=ordinary_performance_description_only\nreport_status=complete\n",
            source_identity) < 0) {
        goto cleanup;
    }
    operation_status = 0;
cleanup:
    if (report != NULL && fclose(report) != 0) {
        operation_status = 1;
    }
    return operation_status;
}

int main(int argument_count, char **argument_values)
{
    char executable_path[4096];
    if (realpath(argument_values[0], executable_path) == NULL) {
        return 1;
    }
    char *last_separator = strrchr(executable_path, '/');
    if (last_separator == NULL) {
        return 1;
    }
    *last_separator = '\0';
    char program_path[4096];
    if (argument_count == 2 && strcmp(argument_values[1], "version") == 0) {
        struct utsname environment;
        if (uname(&environment) != 0) {
            return 1;
        }
        printf("对象：ML-KEM-768，C11 本地审计与复算。环境：%s %s。\n",
            environment.sysname,
            environment.machine);
        for (size_t line_index = 0;
            line_index < sizeof(build_identity_lines) / sizeof(build_identity_lines[0]);
            ++line_index) {
            const char *line = build_identity_lines[line_index];
            if (strncmp(line, "source_commit=", strlen("source_commit=")) == 0 ||
                strncmp(line, "source_identity_kind=", strlen("source_identity_kind=")) == 0 ||
                strncmp(line,
                    "source_export_manifest_sha256=",
                    strlen("source_export_manifest_sha256=")) == 0 ||
                strncmp(line, "compiler_flags=", strlen("compiler_flags=")) == 0) {
                fputs(line, stdout);
            }
        }
        return 0;
    }
    if (argument_count == 2 && strcmp(argument_values[1], "check") == 0) {
        puts("正在执行功能、接口、统计软件和失败路径验收；结果不等于恒时认证。");
        char *arguments[] = {"ctest",
            "--test-dir",
            executable_path,
            "--output-on-failure",
            "--no-tests=error",
            "-E",
            "^(measurement|analysis|analysis_groups)$",
            NULL};
        return execute_program(arguments, NULL);
    }
    if (argument_count == 6 && strcmp(argument_values[1], "collect") == 0) {
        return collect_ordinary(executable_path, argument_values);
    }
    if (argument_count == 3 && strcmp(argument_values[1], "performance") == 0) {
        puts("正在执行6个固定普通运行块，三种无分支实现；失败会保留部分数据。");
        return safe_performance(executable_path, argument_values[2]);
    }
    if (argument_count == 4 && strcmp(argument_values[1], "performance-replay") == 0) {
        return replay_performance(argument_values[2], argument_values[3]);
    }
    if (argument_count == 5 && strcmp(argument_values[1], "export") == 0) {
        return export_html(argument_values[2],
            argument_values[3],
            argument_values[4],
            "指定归档的普通记录");
    }
    if (argument_count == 4 && strcmp(argument_values[1], "replay") == 0) {
        return replay_archive(executable_path, argument_values[2], argument_values[3]);
    }
    if (argument_count == 2 && strcmp(argument_values[1], "case") == 0) {
        puts("案例：公开人工消息编码回归。源码依赖、产物、历史观察和防护对照分别留证。\n"
             "vulnerable为人工机制回归；hardened为同优化条件掩码对照；deployable为正常优化形态对照"
             "。\n"
             "上游原目标编码已无分支；历史未检出不等于恒时。新原生受控防护复测仍缺。\n"
             "证据入口：docs/defensive-case.md。这里没有启动新的秘密机制计时。");
        return 0;
    }
    if (argument_count == 4 &&
        (strcmp(argument_values[1], "inspect") == 0 ||
            strcmp(argument_values[1], "analyze") == 0)) {
        if (make_path(program_path,
                sizeof(program_path),
                executable_path,
                strcmp(argument_values[1], "inspect") == 0 ? "inspect_timing" : "analyze") != 0) {
            return 1;
        }
        char *arguments[] = {program_path, argument_values[2], argument_values[3], NULL};
        return execute_program(arguments, NULL);
    }
    if (argument_count == 5 && strcmp(argument_values[1], "analyze-pairs") == 0) {
        if (make_path(program_path, sizeof(program_path), executable_path, "controlled_stats") !=
            0) {
            return 1;
        }
        char *arguments[] = {program_path,
            "analyze",
            argument_values[2],
            argument_values[3],
            argument_values[4],
            NULL};
        return execute_program(arguments, NULL);
    }
    fputs("audit version | check | case\n"
          "audit collect RUN_ID SEED SAMPLES_PER_CATEGORY NEW_DIRECTORY\n"
          "audit inspect CSV NEW_REPORT | analyze CSV NEW_REPORT\n"
          "audit analyze-pairs CSV PLAN NEW_REPORT\n"
          "audit replay SOURCE_ROOT NEW_DIRECTORY | performance NEW_DIRECTORY\n"
          "audit performance-replay DATA_DIRECTORY NEW_REPORT\n"
          "audit export ORDINARY_CSV META NEW_HTML\n",
        stderr);
    return 2;
}
