/* Cache Flush+Reload 观测者（T5.3）：映射 M3 shared-on 臂的同一 LUT 文件，
 * 对 --layout 指定的缓存行做 clflush，按同步协议在受害者访问前后测量 reload 的 rdtsc 差值。
 *
 * CSV 长表：victim_run_id,line_index,reload_tsc
 * 同步协议（--sync-file，可选）：
 *   每个样本对每一行：wait_turn（受害者窗口前）-> clflush -> wait_turn（窗口后）
 *   -> reload 计时 -> signal_turn（允许下一轮）；flush/reload 是计时目标操作，
 *   窗口内不做 I/O/日志/分配。
 * --self-check 模式在本进程内自建小映射，分别记录 flush 后的冷态 reload 与已访问后的
 * 热态 reload（同一行两行记录），只断言格式、行数与两态都出现，不断言时延阈值。 */

#define _POSIX_C_SOURCE 200809L
#define _GNU_SOURCE

#include "observer_common.h"
#include "sync_flag.h"

#include <fcntl.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/mman.h>
#include <sys/stat.h>
#include <unistd.h>

#define CACHE_DEFAULT_SAMPLE_COUNT 64u
#define CACHE_MAXIMUM_SAMPLE_COUNT 100000u
#define CACHE_MAXIMUM_LINE_COUNT 64u
#define CACHE_MAXIMUM_LAYOUT_BYTES 65536u
#define CACHE_SELF_CHECK_SAMPLE_COUNT 8u
#define CACHE_SELF_CHECK_LINE_COUNT 2u
#define CACHE_SELF_CHECK_LINE_BYTES 64u
#define CACHE_PAGE_BYTES 4096u
#define CACHE_CSV_HEADER "victim_run_id,line_index,reload_tsc"
#define CACHE_USAGE                                                                                \
    "usage: cache_flush_reload_observer --map <file> --layout <json> --output <csv>\n"             \
    "       --victim-run-id <id> [--samples 64] [--sync-file <path>] [--self-check]\n"

struct cache_layout {
    unsigned cache_line_bytes;
    unsigned line_count;
    size_t line_offsets[CACHE_MAXIMUM_LINE_COUNT];
};

struct cache_options {
    const char *map_path;
    const char *layout_path;
    const char *output_path;
    const char *victim_run_id;
    const char *sync_path;
    unsigned sample_count;
    int self_check;
};

static void print_usage(void)
{
    fputs(CACHE_USAGE, stderr);
}

static uint64_t read_time_stamp_counter(void)
{
    return (uint64_t)__builtin_ia32_rdtsc();
}

static void flush_cache_line(const volatile uint8_t *address)
{
    __builtin_ia32_clflush((const void *)address);
    __builtin_ia32_mfence();
}

static int read_text_file(const char *path, char *buffer, size_t capacity)
{
    FILE *input_stream = fopen(path, "r");
    if (input_stream == NULL) {
        fprintf(stderr, "error: cannot open %s\n", path);
        return 1;
    }
    size_t read_bytes = fread(buffer, 1u, capacity - 1u, input_stream);
    buffer[read_bytes] = '\0';
    int read_failed = ferror(input_stream);
    if (fclose(input_stream) != 0 || read_failed != 0) {
        fprintf(stderr, "error: cannot read %s\n", path);
        return 1;
    }
    return 0;
}

/* 极简 JSON 扫描：只接受本工具冻结的 layout schema，见 CACHE_USAGE 与 T5.3 PLAN。 */
static int find_integer_after_key(const char *text, const char *key, unsigned long *value)
{
    const char *key_position = strstr(text, key);
    if (key_position == NULL) {
        return 1;
    }
    const char *cursor = strchr(key_position, ':');
    if (cursor == NULL) {
        return 1;
    }
    ++cursor;
    while (*cursor == ' ' || *cursor == '\t' || *cursor == '\n' || *cursor == '\r') {
        ++cursor;
    }
    if (*cursor < '0' || *cursor > '9') {
        return 1;
    }
    char *end = NULL;
    unsigned long parsed_value = strtoul(cursor, &end, 10);
    if (end == cursor) {
        return 1;
    }
    *value = parsed_value;
    return 0;
}

static int parse_layout(const char *path, struct cache_layout *layout)
{
    char *text = malloc(CACHE_MAXIMUM_LAYOUT_BYTES);
    if (text == NULL) {
        fprintf(stderr, "error: cannot allocate layout buffer\n");
        return 1;
    }
    if (read_text_file(path, text, CACHE_MAXIMUM_LAYOUT_BYTES) != 0) {
        free(text);
        return 1;
    }
    unsigned long cache_line_bytes = 0u;
    if (find_integer_after_key(text, "\"cache_line_bytes\"", &cache_line_bytes) != 0 ||
        cache_line_bytes == 0u || cache_line_bytes > CACHE_PAGE_BYTES) {
        fprintf(stderr, "error: layout has no valid cache_line_bytes\n");
        free(text);
        return 1;
    }
    layout->cache_line_bytes = (unsigned)cache_line_bytes;
    layout->line_count = 0u;
    const char *cursor = text;
    for (;;) {
        const char *offset_key = strstr(cursor, "\"byte_offset\"");
        if (offset_key == NULL) {
            break;
        }
        const char *colon = strchr(offset_key, ':');
        if (colon == NULL) {
            free(text);
            return 1;
        }
        char *end = NULL;
        unsigned long long parsed_offset = strtoull(colon + 1, &end, 10);
        if (end == colon + 1 || layout->line_count == CACHE_MAXIMUM_LINE_COUNT) {
            fprintf(stderr, "error: layout has an invalid byte_offset list\n");
            free(text);
            return 1;
        }
        layout->line_offsets[layout->line_count] = (size_t)parsed_offset;
        ++layout->line_count;
        cursor = colon + 1;
    }
    free(text);
    if (layout->line_count == 0u) {
        fprintf(stderr, "error: layout lists no byte_offset\n");
        return 1;
    }
    return 0;
}

static void *map_shared_file(const char *path, size_t *mapped_bytes)
{
    int descriptor = open(path, O_RDONLY);
    if (descriptor < 0) {
        fprintf(stderr, "error: cannot open mapping file %s\n", path);
        return NULL;
    }
    struct stat file_status;
    if (fstat(descriptor, &file_status) != 0 || file_status.st_size <= 0) {
        fprintf(stderr, "error: cannot stat mapping file %s\n", path);
        (void)close(descriptor);
        return NULL;
    }
    void *mapped_region =
        mmap(NULL, (size_t)file_status.st_size, PROT_READ, MAP_SHARED, descriptor, 0);
    (void)close(descriptor);
    if (mapped_region == MAP_FAILED) {
        fprintf(stderr, "error: mmap failed for %s\n", path);
        return NULL;
    }
    *mapped_bytes = (size_t)file_status.st_size;
    return mapped_region;
}

static int validate_layout_against_mapping(const struct cache_layout *layout, size_t mapped_bytes)
{
    for (unsigned line_index = 0u; line_index < layout->line_count; ++line_index) {
        if (layout->line_offsets[line_index] + layout->cache_line_bytes > mapped_bytes) {
            fprintf(stderr, "error: layout line %u is outside the mapping\n", line_index);
            return 1;
        }
    }
    return 0;
}

static int parse_options(int argument_count, char **argument_values, struct cache_options *options)
{
    options->map_path = NULL;
    options->layout_path = NULL;
    options->output_path = NULL;
    options->victim_run_id = NULL;
    options->sync_path = NULL;
    options->sample_count = CACHE_DEFAULT_SAMPLE_COUNT;
    options->self_check = 0;
    for (int argument_index = 1; argument_index < argument_count; ++argument_index) {
        if (strcmp(argument_values[argument_index], "--self-check") == 0) {
            options->self_check = 1;
            continue;
        }
        const char *value = NULL;
        int taken =
            observer_take_value(argument_count, argument_values, &argument_index, "--map", &value);
        if (taken == 0) {
            options->map_path = value;
            continue;
        }
        taken = observer_take_value(argument_count,
            argument_values,
            &argument_index,
            "--layout",
            &value);
        if (taken == 0) {
            options->layout_path = value;
            continue;
        }
        taken = observer_take_value(argument_count,
            argument_values,
            &argument_index,
            "--output",
            &value);
        if (taken == 0) {
            options->output_path = value;
            continue;
        }
        taken = observer_take_value(argument_count,
            argument_values,
            &argument_index,
            "--victim-run-id",
            &value);
        if (taken == 0) {
            options->victim_run_id = value;
            continue;
        }
        taken = observer_take_value(argument_count,
            argument_values,
            &argument_index,
            "--sync-file",
            &value);
        if (taken == 0) {
            options->sync_path = value;
            continue;
        }
        taken = observer_take_value(argument_count,
            argument_values,
            &argument_index,
            "--samples",
            &value);
        if (taken == 0) {
            unsigned long long parsed_value = 0u;
            if (observer_parse_unsigned(value, 1u, CACHE_MAXIMUM_SAMPLE_COUNT, &parsed_value) !=
                0) {
                return 2;
            }
            options->sample_count = (unsigned)parsed_value;
            continue;
        }
        return 2;
    }
    if (options->self_check) {
        return 0;
    }
    if (options->map_path == NULL || options->layout_path == NULL || options->output_path == NULL ||
        options->victim_run_id == NULL) {
        return 2;
    }
    return 0;
}

static int append_csv_row(char *buffer,
    size_t capacity,
    size_t *used_bytes,
    const char *victim_run_id,
    unsigned line_index,
    uint64_t reload_tsc)
{
    return observer_append_text(buffer,
        capacity,
        used_bytes,
        "%s,%u,%llu\n",
        victim_run_id,
        line_index,
        (unsigned long long)reload_tsc);
}

static int write_self_check_map_file(const char *map_path)
{
    uint8_t page[CACHE_PAGE_BYTES];
    memset(page, 0, sizeof(page));
    for (unsigned entry_index = 0u; entry_index < CACHE_SELF_CHECK_LINE_BYTES; ++entry_index) {
        page[CACHE_SELF_CHECK_LINE_BYTES + entry_index] = (uint8_t)(entry_index + 1u);
    }
    FILE *output_file = fopen(map_path, "wb");
    if (output_file == NULL) {
        fprintf(stderr, "error: cannot create self-check map file\n");
        return 1;
    }
    int status = 0;
    if (fwrite(page, 1u, sizeof(page), output_file) != sizeof(page)) {
        status = 1;
    }
    if (fclose(output_file) != 0) {
        status = 1;
    }
    return status;
}

static int run_self_check(void)
{
    struct cache_options invalid_options;
    char *missing_arguments[] = {"platform_observer_cache_fr"};
    char *invalid_sample_arguments[] = {"platform_observer_cache_fr",
        "--samples",
        "0",
        "--map",
        "m",
        "--layout",
        "l",
        "--output",
        "o",
        "--victim-run-id",
        "v"};
    if (parse_options(1, missing_arguments, &invalid_options) != 2 ||
        parse_options(9, invalid_sample_arguments, &invalid_options) != 2) {
        fprintf(stderr, "error: self-check invalid-argument paths did not return 2\n");
        return 1;
    }
    char map_path[OBSERVER_PATH_CAPACITY_BYTES];
    char layout_path[OBSERVER_PATH_CAPACITY_BYTES];
    char output_path[OBSERVER_PATH_CAPACITY_BYTES];
    const char *temporary_root = getenv("A113_TEST_TMPDIR");
    if (temporary_root == NULL || temporary_root[0] == '\0') {
        fprintf(stderr, "error: A113_TEST_TMPDIR is required for cache self-check\n");
        return 1;
    }
    if (snprintf(map_path,
            sizeof(map_path),
            "%s/observer-cache-map-%ld.bin",
            temporary_root,
            (long)getpid()) < 0 ||
        snprintf(layout_path,
            sizeof(layout_path),
            "%s/observer-cache-layout-%ld.json",
            temporary_root,
            (long)getpid()) < 0 ||
        observer_self_check_output_path(output_path, sizeof(output_path), "cache") != 0) {
        return 1;
    }
    static const char self_check_layout[] =
        "{\"cache_line_bytes\": 64, \"line_count\": 2, "
        "\"lines\": [{\"byte_offset\": 0}, {\"byte_offset\": 64}]}\n";
    if (write_self_check_map_file(map_path) != 0 ||
        observer_write_text(layout_path, self_check_layout) != 0) {
        (void)remove(map_path);
        (void)remove(layout_path);
        return 1;
    }
    struct cache_layout layout;
    if (parse_layout(layout_path, &layout) != 0) {
        (void)remove(map_path);
        (void)remove(layout_path);
        return 1;
    }
    size_t mapped_bytes = 0u;
    volatile const uint8_t *mapped_region = map_shared_file(map_path, &mapped_bytes);
    if (mapped_region == NULL || validate_layout_against_mapping(&layout, mapped_bytes) != 0) {
        (void)remove(map_path);
        (void)remove(layout_path);
        return 1;
    }
    unsigned row_capacity = CACHE_SELF_CHECK_SAMPLE_COUNT * layout.line_count * 2u;
    size_t text_capacity = 128u * ((size_t)row_capacity + 1u) + 64u;
    char *csv_text = malloc(text_capacity);
    if (csv_text == NULL) {
        (void)munmap((void *)mapped_region, mapped_bytes);
        (void)remove(map_path);
        (void)remove(layout_path);
        return 1;
    }
    size_t used_bytes = 0u;
    int status =
        observer_append_text(csv_text, text_capacity, &used_bytes, "%s\n", CACHE_CSV_HEADER);
    unsigned cold_measurement_count = 0u;
    unsigned hot_measurement_count = 0u;
    for (unsigned sample_index = 0u; status == 0 && sample_index < CACHE_SELF_CHECK_SAMPLE_COUNT;
        ++sample_index) {
        for (unsigned line_index = 0u; status == 0 && line_index < layout.line_count;
            ++line_index) {
            const volatile uint8_t *line_address = mapped_region + layout.line_offsets[line_index];
            flush_cache_line(line_address);
            uint64_t cold_start = read_time_stamp_counter();
            uint8_t cold_value = *line_address;
            uint64_t cold_end = read_time_stamp_counter();
            (void)cold_value;
            status = append_csv_row(csv_text,
                text_capacity,
                &used_bytes,
                "self-check-cold",
                line_index,
                cold_end - cold_start);
            ++cold_measurement_count;
            uint8_t hot_value = *line_address;
            (void)hot_value;
            uint64_t hot_start = read_time_stamp_counter();
            uint8_t hot_reload_value = *line_address;
            uint64_t hot_end = read_time_stamp_counter();
            (void)hot_reload_value;
            if (status == 0) {
                status = append_csv_row(csv_text,
                    text_capacity,
                    &used_bytes,
                    "self-check-hot",
                    line_index,
                    hot_end - hot_start);
                ++hot_measurement_count;
            }
        }
    }
    if (status == 0 && (cold_measurement_count == 0u || hot_measurement_count == 0u)) {
        fprintf(stderr, "error: self-check did not observe both cold and hot states\n");
        status = 1;
    }
    if (status == 0) {
        status = observer_write_text(output_path, csv_text);
    }
    if (status == 0) {
        status = observer_validate_csv(output_path, CACHE_CSV_HEADER, row_capacity);
    }
    (void)munmap((void *)mapped_region, mapped_bytes);
    (void)remove(map_path);
    (void)remove(layout_path);
    (void)remove(output_path);
    free(csv_text);
    if (status != 0) {
        return 1;
    }
    printf("cache_flush_reload_observer self-check: samples=%u lines=%u cold=%u hot=%u csv=ok\n",
        CACHE_SELF_CHECK_SAMPLE_COUNT,
        layout.line_count,
        cold_measurement_count,
        hot_measurement_count);
    return 0;
}

static int run_observer(const struct cache_options *options)
{
    struct cache_layout layout;
    if (parse_layout(options->layout_path, &layout) != 0) {
        return 2;
    }
    size_t mapped_bytes = 0u;
    volatile const uint8_t *mapped_region = map_shared_file(options->map_path, &mapped_bytes);
    if (mapped_region == NULL || validate_layout_against_mapping(&layout, mapped_bytes) != 0) {
        return 2;
    }
    struct sync_flag *sync_flag = NULL;
    if (options->sync_path != NULL) {
        sync_flag = sync_flag_open_named(options->sync_path);
        if (sync_flag == NULL) {
            (void)munmap((void *)mapped_region, mapped_bytes);
            return 2;
        }
    }
    unsigned row_capacity = options->sample_count * layout.line_count;
    size_t text_capacity = 128u * ((size_t)row_capacity + 1u) + 64u;
    char *csv_text = malloc(text_capacity);
    if (csv_text == NULL) {
        fprintf(stderr, "error: cannot allocate CSV buffer\n");
        (void)munmap((void *)mapped_region, mapped_bytes);
        sync_flag_destroy(sync_flag);
        return 2;
    }
    size_t used_bytes = 0u;
    int status =
        observer_append_text(csv_text, text_capacity, &used_bytes, "%s\n", CACHE_CSV_HEADER);
    for (unsigned sample_index = 0u; status == 0 && sample_index < options->sample_count;
        ++sample_index) {
        for (unsigned line_index = 0u; status == 0 && line_index < layout.line_count;
            ++line_index) {
            const volatile uint8_t *line_address = mapped_region + layout.line_offsets[line_index];
            if (sync_flag != NULL && sync_flag_wait_turn(sync_flag) != 0) {
                fprintf(stderr, "error: sync flag closed before victim window\n");
                status = 1;
                break;
            }
            flush_cache_line(line_address);
            if (sync_flag != NULL && sync_flag_wait_turn(sync_flag) != 0) {
                fprintf(stderr, "error: sync flag closed after victim window\n");
                status = 1;
                break;
            }
            uint64_t reload_start = read_time_stamp_counter();
            uint8_t reload_value = *line_address;
            uint64_t reload_end = read_time_stamp_counter();
            (void)reload_value;
            if (sync_flag != NULL) {
                sync_flag_signal_turn(sync_flag);
            }
            status = append_csv_row(csv_text,
                text_capacity,
                &used_bytes,
                options->victim_run_id,
                line_index,
                reload_end - reload_start);
        }
    }
    if (status == 0) {
        status = observer_write_text(options->output_path, csv_text);
    }
    if (status == 0) {
        printf("cache_flush_reload_observer: samples=%u lines=%u victim_run_id=%s output=%s\n",
            options->sample_count,
            layout.line_count,
            options->victim_run_id,
            options->output_path);
    }
    free(csv_text);
    (void)munmap((void *)mapped_region, mapped_bytes);
    sync_flag_destroy(sync_flag);
    return status == 0 ? 0 : 1;
}

int main(int argument_count, char **argument_values)
{
    struct cache_options options;
    if (parse_options(argument_count, argument_values, &options) != 0) {
        print_usage();
        return 2;
    }
    if (options.self_check != 0) {
        return run_self_check();
    }
    return run_observer(&options);
}
