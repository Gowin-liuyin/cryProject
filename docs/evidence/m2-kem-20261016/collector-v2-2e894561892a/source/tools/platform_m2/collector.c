/* M2 完整解封装采集器（collector-v2）。
   单次计时窗口只包一次 mlkem_decapsulate；窗口两侧为 atomic_signal_fence。
   密钥读取、密文构造、类顺序、结果消费与 CSV/元数据写盘全部在窗口外。 */
#define _POSIX_C_SOURCE 200809L
#ifdef __APPLE__
#define _DARWIN_C_SOURCE
#endif

#include "collector_inputs.h"

#include "inputs.h"
#include "mlkem.h"
#include "platform_m2.h"

#include <inttypes.h>
#include <stdarg.h>
#include <stdatomic.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/utsname.h>
#include <time.h>
#include <unistd.h>
#ifdef __APPLE__
#include <mach-o/dyld.h>
#endif

#define M2_COLLECTOR_DEFAULT_WARMUP 100U
#define M2_COLLECTOR_MAXIMUM_WARMUP 10000U
#define M2_COLLECTOR_MAXIMUM_PATH_BYTES 4096U
#define M2_COLLECTOR_MAXIMUM_RUN_ID_BYTES 128U
#define M2_COLLECTOR_MAXIMUM_EXECUTABLE_BYTES 67108864L
#define M2_COLLECTOR_CSV_HEADER \
    "run_id,implementation,input_category,sample_index,elapsed_nanoseconds,time_unit\n"

/* 计时结束后才消费的共享秘密累积，防止编译器整体删除解封装调用。 */
static volatile uint8_t result_sink;

struct collector_options {
    enum m2_collector_class class_list[M2_COLLECTOR_MAXIMUM_CLASSES];
    size_t class_count;
    uint64_t samples_per_class;
    uint64_t test_seed;
    uint64_t warmup_count;
    const char *raw_path;
    const char *meta_path;
    const char *public_key_path;
    const char *secret_key_path;
    const char *run_id;
    char meta_path_buffer[M2_COLLECTOR_MAXIMUM_PATH_BYTES];
    char run_id_buffer[M2_COLLECTOR_MAXIMUM_RUN_ID_BYTES];
};

static void print_usage(FILE *stream)
{
    fputs("usage: m2_decaps_collector --class <name>[,<name>...] --samples <n> --seed <n>\n"
          "                           --raw <csv> --public-key <file> --secret-key <file>\n"
          "                           [--run-id <id>] [--meta <file>] [--warmup <n>]\n"
          "  classes: message-zero,message-ones,malformed-zero-tail,malformed-ff-tail,all\n"
          "  samples is per class; rows = classes * samples, class order is seed-replayable\n"
          "  raw/meta are created exclusively (wx) and never overwritten\n",
        stream);
}

static int read_monotonic_nanoseconds(uint64_t *timestamp_nanoseconds)
{
    struct timespec timestamp;
    if (clock_gettime(CLOCK_MONOTONIC, &timestamp) != 0 || timestamp.tv_sec < 0 ||
        timestamp.tv_nsec < 0) {
        return 1;
    }
    *timestamp_nanoseconds = (uint64_t)timestamp.tv_sec * UINT64_C(1000000000) +
                             (uint64_t)timestamp.tv_nsec;
    return 0;
}

/* 只接受十进制数字；拒绝空串、符号、越界。 */
static int parse_decimal(const char *text, uint64_t *value)
{
    if (parse_unsigned_integer(text, value) != 0) {
        return 1;
    }
    return 0;
}

/* run_id 直接进入 CSV 标识列，限制为统计电池接受的 [A-Za-z0-9_-]。 */
static int is_valid_run_id(const char *run_id)
{
    if (run_id == NULL || *run_id == '\0') {
        return 0;
    }
    for (const char *character = run_id; *character != '\0'; ++character) {
        int is_digit = *character >= '0' && *character <= '9';
        int is_letter = (*character >= 'a' && *character <= 'z') ||
                        (*character >= 'A' && *character <= 'Z');
        if (!is_digit && !is_letter && *character != '_' && *character != '-') {
            return 0;
        }
    }
    return 1;
}

static int parse_class_list(const char *class_text,
    enum m2_collector_class *class_list,
    size_t *class_count)
{
    char class_buffer[160];
    size_t parsed_count = 0;
    if (class_text == NULL || class_list == NULL || class_count == NULL ||
        strlen(class_text) >= sizeof(class_buffer)) {
        return 1;
    }
    memcpy(class_buffer, class_text, strlen(class_text) + 1U);
    if (strcmp(class_buffer, "all") == 0) {
        for (size_t class_index = 0; class_index < M2_COLLECTOR_CLASS_COUNT; ++class_index) {
            class_list[class_index] = (enum m2_collector_class)class_index;
        }
        *class_count = M2_COLLECTOR_CLASS_COUNT;
        return 0;
    }
    char *field_start = class_buffer;
    while (field_start != NULL) {
        char *field_end = strchr(field_start, ',');
        enum m2_collector_class parsed_class;
        if (field_end != NULL) {
            *field_end = '\0';
        }
        if (*field_start == '\0' || parsed_count >= M2_COLLECTOR_MAXIMUM_CLASSES ||
            m2_collector_parse_class(field_start, &parsed_class) != 0) {
            return 1;
        }
        for (size_t existing_index = 0; existing_index < parsed_count; ++existing_index) {
            if (class_list[existing_index] == parsed_class) {
                return 1;
            }
        }
        class_list[parsed_count] = parsed_class;
        parsed_count += 1U;
        field_start = field_end == NULL ? NULL : field_end + 1;
    }
    *class_count = parsed_count;
    return 0;
}

static int parse_options(int argument_count, char **argument_values, struct collector_options *options)
{
    int has_seed = 0;
    int has_samples = 0;
    if (argument_count < 2 || options == NULL) {
        return 1;
    }
    memset(options, 0, sizeof(*options));
    options->warmup_count = M2_COLLECTOR_DEFAULT_WARMUP;
    for (int argument_index = 1; argument_index < argument_count; ++argument_index) {
        const char *option_name = argument_values[argument_index];
        const char *option_value =
            argument_index + 1 < argument_count ? argument_values[argument_index + 1] : NULL;
        if (option_value == NULL) {
            return 1;
        }
        argument_index += 1;
        if (strcmp(option_name, "--class") == 0) {
            if (parse_class_list(option_value, options->class_list, &options->class_count) != 0) {
                return 1;
            }
        } else if (strcmp(option_name, "--samples") == 0) {
            if (parse_decimal(option_value, &options->samples_per_class) != 0 ||
                options->samples_per_class == 0 ||
                options->samples_per_class > M2_COLLECTOR_MAXIMUM_SAMPLES_PER_CLASS) {
                return 1;
            }
            has_samples = 1;
        } else if (strcmp(option_name, "--seed") == 0) {
            if (parse_decimal(option_value, &options->test_seed) != 0) {
                return 1;
            }
            has_seed = 1;
        } else if (strcmp(option_name, "--raw") == 0) {
            options->raw_path = option_value;
        } else if (strcmp(option_name, "--meta") == 0) {
            options->meta_path = option_value;
        } else if (strcmp(option_name, "--public-key") == 0) {
            options->public_key_path = option_value;
        } else if (strcmp(option_name, "--secret-key") == 0) {
            options->secret_key_path = option_value;
        } else if (strcmp(option_name, "--run-id") == 0) {
            options->run_id = option_value;
        } else if (strcmp(option_name, "--warmup") == 0) {
            if (parse_decimal(option_value, &options->warmup_count) != 0 ||
                options->warmup_count == 0 || options->warmup_count > M2_COLLECTOR_MAXIMUM_WARMUP) {
                return 1;
            }
        } else {
            return 1;
        }
    }
    if (!has_seed || !has_samples || options->class_count == 0 || options->raw_path == NULL ||
        options->public_key_path == NULL || options->secret_key_path == NULL) {
        return 1;
    }
    if (options->run_id == NULL) {
        int written_bytes = snprintf(options->run_id_buffer,
            sizeof(options->run_id_buffer),
            "m2-decaps-seed%" PRIu64,
            options->test_seed);
        if (written_bytes < 0 || (size_t)written_bytes >= sizeof(options->run_id_buffer)) {
            return 1;
        }
        options->run_id = options->run_id_buffer;
    }
    if (strlen(options->run_id) >= M2_COLLECTOR_MAXIMUM_RUN_ID_BYTES ||
        !is_valid_run_id(options->run_id)) {
        return 1;
    }
    if (options->meta_path == NULL) {
        int written_bytes = snprintf(options->meta_path_buffer,
            sizeof(options->meta_path_buffer),
            "%s.meta",
            options->raw_path);
        if (written_bytes < 0 || (size_t)written_bytes >= sizeof(options->meta_path_buffer)) {
            return 1;
        }
        options->meta_path = options->meta_path_buffer;
    }
    return 0;
}

static int read_fixed_file(const char *path, uint8_t *buffer, size_t expected_byte_count)
{
    FILE *file;
    size_t read_byte_count;
    int operation_status = 0;
    if (path == NULL || buffer == NULL || expected_byte_count == 0) {
        return 1;
    }
    file = fopen(path, "rb");
    if (file == NULL) {
        return 1;
    }
    read_byte_count = fread(buffer, 1, expected_byte_count, file);
    if (read_byte_count != expected_byte_count || fgetc(file) != EOF || ferror(file)) {
        operation_status = 1;
    }
    if (fclose(file) != 0) {
        operation_status = 1;
    }
    return operation_status;
}

static int read_cpu_model(char *model_buffer, size_t model_capacity_bytes)
{
    FILE *cpu_file = fopen("/proc/cpuinfo", "r");
    if (cpu_file == NULL || model_capacity_bytes == 0) {
        if (cpu_file != NULL) {
            (void)fclose(cpu_file);
        }
        return 1;
    }
    model_buffer[0] = '\0';
    char line_buffer[512];
    while (fgets(line_buffer, sizeof(line_buffer), cpu_file) != NULL) {
        const char *model_prefix = "model name";
        size_t prefix_byte_count = strlen(model_prefix);
        if (strncmp(line_buffer, model_prefix, prefix_byte_count) != 0) {
            continue;
        }
        const char *separator = strchr(line_buffer, ':');
        if (separator == NULL) {
            continue;
        }
        separator += 1;
        while (*separator == ' ' || *separator == '\t') {
            separator += 1;
        }
        size_t copied_byte_count = strlen(separator);
        while (copied_byte_count > 0 &&
               (separator[copied_byte_count - 1U] == '\n' ||
                   separator[copied_byte_count - 1U] == '\r')) {
            copied_byte_count -= 1U;
        }
        if (copied_byte_count >= model_capacity_bytes) {
            copied_byte_count = model_capacity_bytes - 1U;
        }
        memcpy(model_buffer, separator, copied_byte_count);
        model_buffer[copied_byte_count] = '\0';
        break;
    }
    if (fclose(cpu_file) != 0) {
        return 1;
    }
    return model_buffer[0] == '\0' ? 1 : 0;
}

/* 自哈希用于让元数据自证是哪一个 ELF 产生的，取材在计时窗口之外。 */
static int hash_running_executable(uint8_t executable_digest[32])
{
    char executable_path[M2_COLLECTOR_MAXIMUM_PATH_BYTES];
    uint8_t *executable_bytes = NULL;
    FILE *executable_file = NULL;
    long executable_byte_count;
    int operation_status = 1;
#ifdef __APPLE__
    uint32_t executable_path_capacity_bytes = (uint32_t)sizeof(executable_path);
    if (_NSGetExecutablePath(executable_path, &executable_path_capacity_bytes) != 0) {
        return 1;
    }
#else
    ssize_t path_byte_count =
        readlink("/proc/self/exe", executable_path, sizeof(executable_path) - 1U);
    if (path_byte_count <= 0 || (size_t)path_byte_count >= sizeof(executable_path) - 1U) {
        return 1;
    }
    executable_path[(size_t)path_byte_count] = '\0';
#endif
    executable_file = fopen(executable_path, "rb");
    if (executable_file == NULL) {
        return 1;
    }
    if (fseek(executable_file, 0, SEEK_END) != 0) {
        goto cleanup;
    }
    executable_byte_count = ftell(executable_file);
    if (executable_byte_count <= 0 ||
        executable_byte_count > M2_COLLECTOR_MAXIMUM_EXECUTABLE_BYTES ||
        fseek(executable_file, 0, SEEK_SET) != 0) {
        goto cleanup;
    }
    executable_bytes = malloc((size_t)executable_byte_count);
    if (executable_bytes == NULL) {
        goto cleanup;
    }
    if (fread(executable_bytes, 1, (size_t)executable_byte_count, executable_file) !=
            (size_t)executable_byte_count ||
        fgetc(executable_file) != EOF || ferror(executable_file)) {
        goto cleanup;
    }
    platform_m2_sha3_256(executable_digest, executable_bytes, (size_t)executable_byte_count);
    operation_status = 0;
cleanup:
    free(executable_bytes);
    if (fclose(executable_file) != 0) {
        operation_status = 1;
    }
    return operation_status;
}

static void meta_printf(FILE *meta_file, int *operation_status, const char *format, ...)
{
    va_list arguments;
    va_start(arguments, format);
    if (vfprintf(meta_file, format, arguments) < 0) {
        *operation_status = 1;
    }
    va_end(arguments);
}

static void write_digest_hex(FILE *meta_file, int *operation_status, const uint8_t digest[32])
{
    for (size_t byte_index = 0; byte_index < 32U; ++byte_index) {
        if (fprintf(meta_file, "%02x", digest[byte_index]) < 0) {
            *operation_status = 1;
            return;
        }
    }
}

static int save_results(const struct collector_options *options,
    const enum m2_collector_class *row_classes,
    const uint64_t *elapsed_nanoseconds,
    size_t row_count,
    uint64_t resolution_nanoseconds,
    uint64_t zero_elapsed_count,
    uint64_t minimum_elapsed_nanoseconds,
    uint64_t maximum_elapsed_nanoseconds,
    uint64_t failed_decapsulation_count,
    uint64_t accept_mismatch_count,
    uint64_t warmup_attempted_calls,
    uint64_t warmup_completed_calls,
    const uint8_t *public_key_digest,
    const uint8_t *secret_key_digest,
    const uint8_t *input_digest,
    const uint8_t *executable_digest)
{
    struct utsname machine_information;
    char cpu_model[256];
    FILE *csv_file;
    FILE *meta_file;
    int operation_status = 0;
    time_t wall_clock_seconds = time(NULL);
    size_t class_row_counts[M2_COLLECTOR_CLASS_COUNT];
    if (uname(&machine_information) != 0 || wall_clock_seconds == (time_t)-1) {
        return 1;
    }
    /* CPU 型号只是描述性元数据；读取失败写 unknown，不因此丢弃整批原始值。 */
    if (read_cpu_model(cpu_model, sizeof(cpu_model)) != 0) {
        (void)snprintf(cpu_model, sizeof(cpu_model), "unknown");
    }
    for (size_t class_index = 0; class_index < M2_COLLECTOR_CLASS_COUNT; ++class_index) {
        class_row_counts[class_index] = 0;
    }
    for (size_t row_index = 0; row_index < row_count; ++row_index) {
        class_row_counts[(size_t)row_classes[row_index]] += 1U;
    }
    csv_file = fopen(options->raw_path, "wx");
    if (csv_file == NULL) {
        return 1;
    }
    meta_file = fopen(options->meta_path, "wx");
    if (meta_file == NULL) {
        (void)fclose(csv_file);
        (void)remove(options->raw_path);
        return 1;
    }
    if (fputs(M2_COLLECTOR_CSV_HEADER, csv_file) == EOF) {
        operation_status = 1;
    }
    for (size_t row_index = 0; row_index < row_count; ++row_index) {
        if (fprintf(csv_file,
                "%s,%s,%s,%zu,%" PRIu64 ",ns\n",
                options->run_id,
                mlkem_implementation_name(),
                m2_collector_class_name(row_classes[row_index]),
                row_index,
                elapsed_nanoseconds[row_index]) < 0) {
            operation_status = 1;
        }
    }
    meta_printf(meta_file,
        &operation_status,
        "collector_format=platform_m2_decaps_collector_v1\n"
        "collector_name=m2_decaps_collector\n"
        "run_id=%s\nimplementation=%s\ntest_seed=%" PRIu64
        "\nsamples_per_class=%" PRIu64 "\nrow_count=%zu\nwarmup_decapsulations=%" PRIu64
        "\nwarmup_attempted_calls=%" PRIu64 "\nwarmup_completed_calls=%" PRIu64
        "\nclass_count=%zu\nclass_list=",
        options->run_id,
        mlkem_implementation_name(),
        options->test_seed,
        options->samples_per_class,
        row_count,
        options->warmup_count,
        warmup_attempted_calls,
        warmup_completed_calls,
        options->class_count);
    for (size_t class_slot = 0; class_slot < options->class_count; ++class_slot) {
        meta_printf(meta_file,
            &operation_status,
            "%s%s",
            class_slot == 0 ? "" : ",",
            m2_collector_class_name(options->class_list[class_slot]));
    }
    meta_printf(meta_file, &operation_status, "\nper_class_row_counts=");
    {
        int is_first_count = 1;
        for (size_t class_index = 0; class_index < M2_COLLECTOR_CLASS_COUNT; ++class_index) {
            if (class_row_counts[class_index] == 0) {
                continue;
            }
            meta_printf(meta_file,
                &operation_status,
                "%s%s=%zu",
                is_first_count ? "" : ",",
                m2_collector_class_name((enum m2_collector_class)class_index),
                class_row_counts[class_index]);
            is_first_count = 0;
        }
    }
    meta_printf(meta_file,
        &operation_status,
        "\nclock=CLOCK_MONOTONIC\ntime_unit=ns\nclock_resolution_ns=%" PRIu64
        "\nwindow=clock_gettime;atomic_signal_fence(memory_order_seq_cst);mlkem_decapsulate("
        "MLKEM_CIPHERTEXT_BYTES,MLKEM_DECAPSULATION_KEY_BYTES);"
        "atomic_signal_fence(memory_order_seq_cst);clock_gettime"
        "\norder=balanced_fisher_yates_shake256_tag4\n"
        "window_scope=one_complete_mlkem_decapsulate\n"
        "input_generation_window=outside\nresult_consumption_window=outside\n"
        "io_window=outside\noutput_buffer_bytes=%zu\n"
        "chosen_message_classes=message-zero,message-ones\n"
        "implicit_rejection_classes=malformed-zero-tail,malformed-ff-tail\n"
        "malformed_tail_bytes=%u\n",
        resolution_nanoseconds,
        row_count * (size_t)MLKEM_CIPHERTEXT_BYTES,
        (unsigned)M2_COLLECTOR_TAIL_BYTES);
    meta_printf(meta_file,
        &operation_status,
        "public_key_path=%s\npublic_key_bytes=%u\npublic_key_sha3_256=",
        options->public_key_path,
        (unsigned)MLKEM_ENCAPSULATION_KEY_BYTES);
    write_digest_hex(meta_file, &operation_status, public_key_digest);
    meta_printf(meta_file,
        &operation_status,
        "\nsecret_key_path=%s\nsecret_key_bytes=%u\nsecret_key_sha3_256=",
        options->secret_key_path,
        (unsigned)MLKEM_DECAPSULATION_KEY_BYTES);
    write_digest_hex(meta_file, &operation_status, secret_key_digest);
    meta_printf(meta_file, &operation_status, "\ninput_sequence_digest_algorithm=SHA3-256\n"
                                              "input_sequence_digest=");
    write_digest_hex(meta_file, &operation_status, input_digest);
    meta_printf(meta_file, &operation_status, "\nexecutable_sha3_256=");
    write_digest_hex(meta_file, &operation_status, executable_digest);
    meta_printf(meta_file,
        &operation_status,
        "\nzero_elapsed_count=%" PRIu64 "\nminimum_elapsed_nanoseconds=%" PRIu64
        "\nmaximum_elapsed_nanoseconds=%" PRIu64 "\nfailed_decapsulation_count=%" PRIu64
        "\nchosen_message_accept_mismatch_count=%" PRIu64 "\n",
        zero_elapsed_count,
        minimum_elapsed_nanoseconds,
        maximum_elapsed_nanoseconds,
        failed_decapsulation_count,
        accept_mismatch_count);
    meta_printf(meta_file,
        &operation_status,
        "csv_path=%s\ncpu_affinity=not_pinned\nfrequency_control=not_configured\n"
        "os=%s %s %s\ncpu_model=%s\nwall_clock_unix_seconds=%jd\n",
        options->raw_path,
        machine_information.sysname,
        machine_information.release,
        machine_information.machine,
        cpu_model,
        (intmax_t)wall_clock_seconds);
    meta_printf(meta_file,
        &operation_status,
        "run_status=%s\n",
        (operation_status == 0 && failed_decapsulation_count == 0 && accept_mismatch_count == 0)
            ? "complete"
            : "failed");
    if (fflush(csv_file) != 0) {
        operation_status = 1;
    }
    if (fclose(csv_file) != 0) {
        operation_status = 1;
    }
    if (fclose(meta_file) != 0) {
        operation_status = 1;
    }
    return operation_status;
}

int main(int argument_count, char **argument_values)
{
    struct collector_options options;
    uint8_t *public_key = NULL;
    uint8_t *secret_key = NULL;
    uint8_t *class_ciphertexts = NULL;
    uint8_t *ordered_ciphertexts = NULL;
    enum m2_collector_class *row_classes = NULL;
    uint8_t *row_secrets = NULL;
    uint64_t *elapsed_nanoseconds = NULL;
    uint8_t expected_secrets[2][MLKEM_SHARED_SECRET_BYTES] = {{0}};
    uint8_t public_key_digest[32];
    uint8_t secret_key_digest[32];
    uint8_t input_digest[32];
    uint8_t executable_digest[32];
    uint8_t shared_secret[MLKEM_SHARED_SECRET_BYTES];
    uint64_t resolution_nanoseconds = 0;
    uint64_t zero_elapsed_count = 0;
    uint64_t minimum_elapsed_nanoseconds = UINT64_MAX;
    uint64_t maximum_elapsed_nanoseconds = 0;
    uint64_t failed_decapsulation_count = 0;
    uint64_t accept_mismatch_count = 0;
    uint64_t warmup_attempted_calls = 0;
    uint64_t warmup_completed_calls = 0;
    size_t row_count = 0;
    int operation_status = 1;
    if (argument_count == 2 &&
        (strcmp(argument_values[1], "--help") == 0 || strcmp(argument_values[1], "-h") == 0)) {
        print_usage(stdout);
        return 0;
    }
    if (argument_count == 1) {
        print_usage(stderr);
        return 2;
    }
    if (parse_options(argument_count, argument_values, &options) != 0) {
        fputs("invalid arguments\n", stderr);
        print_usage(stderr);
        return 2;
    }
    {
        struct timespec clock_resolution;
        if (clock_getres(CLOCK_MONOTONIC, &clock_resolution) != 0 || clock_resolution.tv_sec < 0 ||
            clock_resolution.tv_nsec < 0) {
            fputs("clock resolution check failed\n", stderr);
            return 1;
        }
        resolution_nanoseconds = (uint64_t)clock_resolution.tv_sec * UINT64_C(1000000000) +
                                 (uint64_t)clock_resolution.tv_nsec;
        if (resolution_nanoseconds == 0) {
            fputs("clock resolution is zero\n", stderr);
            return 1;
        }
    }
    row_count = options.class_count * (size_t)options.samples_per_class;
    public_key = malloc(MLKEM_ENCAPSULATION_KEY_BYTES);
    secret_key = malloc(MLKEM_DECAPSULATION_KEY_BYTES);
    class_ciphertexts = malloc((size_t)M2_COLLECTOR_CLASS_COUNT * MLKEM_CIPHERTEXT_BYTES);
    ordered_ciphertexts = malloc(row_count * (size_t)MLKEM_CIPHERTEXT_BYTES);
    row_secrets = malloc(row_count * (size_t)MLKEM_SHARED_SECRET_BYTES);
    row_classes = malloc(row_count * sizeof(*row_classes));
    elapsed_nanoseconds = malloc(row_count * sizeof(*elapsed_nanoseconds));
    if (public_key == NULL || secret_key == NULL || class_ciphertexts == NULL ||
        ordered_ciphertexts == NULL || row_secrets == NULL || row_classes == NULL ||
        elapsed_nanoseconds == NULL) {
        fputs("allocation failed\n", stderr);
        goto cleanup;
    }
    if (read_fixed_file(options.public_key_path, public_key, MLKEM_ENCAPSULATION_KEY_BYTES) != 0) {
        fputs("public key file must hold exactly MLKEM_ENCAPSULATION_KEY_BYTES bytes\n", stderr);
        goto cleanup;
    }
    if (read_fixed_file(options.secret_key_path, secret_key, MLKEM_DECAPSULATION_KEY_BYTES) != 0) {
        fputs("secret key file must hold exactly MLKEM_DECAPSULATION_KEY_BYTES bytes\n", stderr);
        goto cleanup;
    }
    platform_m2_sha3_256(public_key_digest, public_key, MLKEM_ENCAPSULATION_KEY_BYTES);
    platform_m2_sha3_256(secret_key_digest, secret_key, MLKEM_DECAPSULATION_KEY_BYTES);
    for (size_t class_slot = 0; class_slot < options.class_count; ++class_slot) {
        enum m2_collector_class class_index = options.class_list[class_slot];
        uint8_t *class_ciphertext =
            class_ciphertexts + (size_t)class_index * MLKEM_CIPHERTEXT_BYTES;
        uint8_t *expected_secret = NULL;
        if (class_index == M2_COLLECTOR_MESSAGE_ZERO) {
            expected_secret = expected_secrets[0];
        } else if (class_index == M2_COLLECTOR_MESSAGE_ONES) {
            expected_secret = expected_secrets[1];
        }
        if (m2_collector_build_ciphertext(class_index, public_key, class_ciphertext, expected_secret) !=
            0) {
            fputs("ciphertext construction failed\n", stderr);
            goto cleanup;
        }
    }
    if (m2_collector_build_schedule(options.class_list,
            options.class_count,
            options.samples_per_class,
            options.test_seed,
            row_classes) != 0) {
        fputs("schedule construction failed\n", stderr);
        goto cleanup;
    }
    for (size_t row_index = 0; row_index < row_count; ++row_index) {
        memcpy(ordered_ciphertexts + row_index * (size_t)MLKEM_CIPHERTEXT_BYTES,
            class_ciphertexts + (size_t)row_classes[row_index] * MLKEM_CIPHERTEXT_BYTES,
            MLKEM_CIPHERTEXT_BYTES);
    }
    if (m2_collector_digest_ciphertexts(ordered_ciphertexts, row_count, input_digest) != 0 ||
        hash_running_executable(executable_digest) != 0) {
        fputs("input/executable digest failed\n", stderr);
        goto cleanup;
    }
    for (uint64_t warmup_index = 0; warmup_index < options.warmup_count; ++warmup_index) {
        size_t selected_row = (size_t)(warmup_index % (uint64_t)row_count);
        warmup_attempted_calls += 1U;
        if (mlkem_decapsulate(shared_secret,
                sizeof(shared_secret),
                ordered_ciphertexts + selected_row * (size_t)MLKEM_CIPHERTEXT_BYTES,
                MLKEM_CIPHERTEXT_BYTES,
                secret_key,
                MLKEM_DECAPSULATION_KEY_BYTES) != 0) {
            fputs("warmup decapsulation failed\n", stderr);
            goto cleanup;
        }
        warmup_completed_calls += 1U;
        result_sink ^= shared_secret[0];
    }
    for (size_t row_index = 0; row_index < row_count; ++row_index) {
        uint64_t start_nanoseconds;
        uint64_t end_nanoseconds;
        unsigned decapsulation_status;
        if (read_monotonic_nanoseconds(&start_nanoseconds) != 0) {
            fputs("clock read failed\n", stderr);
            goto cleanup;
        }
        atomic_signal_fence(memory_order_seq_cst);
        decapsulation_status = (unsigned)mlkem_decapsulate(shared_secret,
            sizeof(shared_secret),
            ordered_ciphertexts + row_index * (size_t)MLKEM_CIPHERTEXT_BYTES,
            MLKEM_CIPHERTEXT_BYTES,
            secret_key,
            MLKEM_DECAPSULATION_KEY_BYTES);
        atomic_signal_fence(memory_order_seq_cst);
        if (read_monotonic_nanoseconds(&end_nanoseconds) != 0 ||
            end_nanoseconds < start_nanoseconds) {
            fputs("clock read failed or moved backwards\n", stderr);
            goto cleanup;
        }
        failed_decapsulation_count += decapsulation_status != 0U ? 1U : 0U;
        elapsed_nanoseconds[row_index] = end_nanoseconds - start_nanoseconds;
        memcpy(row_secrets + row_index * (size_t)MLKEM_SHARED_SECRET_BYTES,
            shared_secret,
            MLKEM_SHARED_SECRET_BYTES);
    }
    /* 计时全部结束后才消费结果并核对主类对的接受路径。 */
    for (size_t row_index = 0; row_index < row_count; ++row_index) {
        enum m2_collector_class class_index = row_classes[row_index];
        const uint8_t *row_secret = row_secrets + row_index * (size_t)MLKEM_SHARED_SECRET_BYTES;
        result_sink ^= row_secret[row_index % (size_t)MLKEM_SHARED_SECRET_BYTES];
        if (elapsed_nanoseconds[row_index] == 0) {
            zero_elapsed_count += 1U;
        }
        if (elapsed_nanoseconds[row_index] < minimum_elapsed_nanoseconds) {
            minimum_elapsed_nanoseconds = elapsed_nanoseconds[row_index];
        }
        if (elapsed_nanoseconds[row_index] > maximum_elapsed_nanoseconds) {
            maximum_elapsed_nanoseconds = elapsed_nanoseconds[row_index];
        }
        if (class_index == M2_COLLECTOR_MESSAGE_ZERO || class_index == M2_COLLECTOR_MESSAGE_ONES) {
            const uint8_t *expected_secret = class_index == M2_COLLECTOR_MESSAGE_ZERO
                ? expected_secrets[0]
                : expected_secrets[1];
            if (memcmp(row_secret, expected_secret, MLKEM_SHARED_SECRET_BYTES) != 0) {
                accept_mismatch_count += 1U;
            }
        }
    }
    if (save_results(&options,
            row_classes,
            elapsed_nanoseconds,
            row_count,
            resolution_nanoseconds,
            zero_elapsed_count,
            minimum_elapsed_nanoseconds,
            maximum_elapsed_nanoseconds,
            failed_decapsulation_count,
            accept_mismatch_count,
            warmup_attempted_calls,
            warmup_completed_calls,
            public_key_digest,
            secret_key_digest,
            input_digest,
            executable_digest) != 0) {
        fputs("result write failed; use new output paths\n", stderr);
        goto cleanup;
    }
    if (failed_decapsulation_count != 0 || accept_mismatch_count != 0) {
        fprintf(stderr,
            "functional gate failed: failed_decapsulations=%" PRIu64 ", accept_mismatches=%" PRIu64
            "\n",
            failed_decapsulation_count,
            accept_mismatch_count);
        goto cleanup;
    }
    if (zero_elapsed_count != 0) {
        fprintf(stderr,
            "warning: %" PRIu64 " zero-nanosecond windows kept in raw CSV\n",
            zero_elapsed_count);
    }
    printf("%s: saved %zu raw decapsulation times in ns; no statistical conclusion\n",
        mlkem_implementation_name(),
        row_count);
    operation_status = 0;
cleanup:
    if (secret_key != NULL) {
        erase_secret_bytes(secret_key, MLKEM_DECAPSULATION_KEY_BYTES);
    }
    erase_secret_bytes(expected_secrets, sizeof(expected_secrets));
    erase_secret_bytes(shared_secret, sizeof(shared_secret));
    if (row_secrets != NULL) {
        erase_secret_bytes(row_secrets, row_count * (size_t)MLKEM_SHARED_SECRET_BYTES);
    }
    free(public_key);
    free(secret_key);
    free(class_ciphertexts);
    free(ordered_ciphertexts);
    free(row_secrets);
    free(row_classes);
    free(elapsed_nanoseconds);
    return operation_status;
}
