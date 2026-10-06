#define _POSIX_C_SOURCE 200809L
#ifdef __APPLE__
#define _DARWIN_C_SOURCE
#endif
#include "paired_data.h"

#include <assert.h>
#include <inttypes.h>
#include <stdlib.h>
#include <string.h>
#include <sys/wait.h>
#include <unistd.h>

static int invoke(char *const arguments[])
{
    pid_t child_process = fork();
    int wait_status;
    assert(child_process >= 0);
    if (child_process == 0) {
        execv(arguments[0], arguments);
        _exit(127);
    }
    assert(waitpid(child_process, &wait_status, 0) == child_process);
    assert(WIFEXITED(wait_status));
    return WEXITSTATUS(wait_status);
}

static void replace_field(const char *path, const char *key, const char *value)
{
    char temporary_path[4096];
    assert(snprintf(temporary_path, sizeof(temporary_path), "%s.rewrite", path) > 0);
    FILE *input = fopen(path, "r");
    FILE *output = fopen(temporary_path, "wx");
    char line[4096];
    int found = 0;
    assert(input != NULL && output != NULL);
    while (fgets(line, sizeof(line), input) != NULL) {
        if (strncmp(line, key, strlen(key)) == 0 && line[strlen(key)] == '=') {
            assert(fprintf(output, "%s=%s\n", key, value) > 0);
            found = 1;
        } else {
            assert(fputs(line, output) >= 0);
        }
    }
    assert(found && !ferror(input));
    assert(fclose(input) == 0 && fclose(output) == 0);
    assert(rename(temporary_path, path) == 0);
}

static void update_digest(const char *manifest_path, const char *context_path)
{
    char digest[65];
    assert(paired_digest_file(manifest_path, digest) == 0);
    replace_field(context_path, "cohort_manifest_digest", digest);
}

static void update_run_digest(const char *directory,
    const char *block_id,
    const char *data_path,
    size_t digest_field_index)
{
    char manifest_path[4096];
    char context_path[4096];
    char temporary_path[4096];
    char digest[65];
    assert(digest_field_index >= 6u && digest_field_index <= 11u);
    assert(paired_data_path(manifest_path, sizeof(manifest_path), directory, "cohort.csv") == 0);
    assert(paired_data_path(context_path, sizeof(context_path), directory, "cohort.meta") == 0);
    assert(snprintf(temporary_path, sizeof(temporary_path), "%s.rewrite", manifest_path) > 0);
    assert(paired_digest_file(data_path, digest) == 0);
    FILE *input = fopen(manifest_path, "r");
    FILE *output = fopen(temporary_path, "wx");
    char line[4096];
    int found = 0;
    assert(input != NULL && output != NULL);
    assert(fgets(line, sizeof(line), input) != NULL && fputs(line, output) >= 0);
    while (fgets(line, sizeof(line), input) != NULL) {
        char *fields[14];
        assert(split_paired_csv(line, fields, 14) == 0);
        if (strcmp(fields[0], block_id) == 0) {
            fields[digest_field_index] = digest;
            found = 1;
        }
        for (size_t field_index = 0; field_index < 14u; ++field_index) {
            assert(
                fprintf(output, "%s%c", fields[field_index], field_index == 13u ? '\n' : ',') > 0);
        }
    }
    assert(found && !ferror(input));
    assert(fclose(input) == 0 && fclose(output) == 0);
    assert(rename(temporary_path, manifest_path) == 0);
    update_digest(manifest_path, context_path);
}

static void shift_cost_timestamps(const char *path, uint64_t offset_nanoseconds, int subtract)
{
    const char *const names[] = {"start_ns",
        "preparation_end_ns",
        "warmup_end_ns",
        "collection_end_ns",
        "finish_ns"};
    char values[5][32];
    struct paired_text_field fields[5];
    for (size_t field_index = 0; field_index < 5u; ++field_index) {
        fields[field_index] =
            (struct paired_text_field){names[field_index], values[field_index], 32, 0};
    }
    assert(read_paired_fields(path, fields, 5) == 0);
    for (size_t field_index = 0; field_index < 5u; ++field_index) {
        uint64_t timestamp_nanoseconds;
        assert(parse_unsigned_integer(values[field_index], &timestamp_nanoseconds) == 0);
        if (subtract) {
            assert(timestamp_nanoseconds >= offset_nanoseconds);
            timestamp_nanoseconds -= offset_nanoseconds;
        } else {
            assert(timestamp_nanoseconds <= UINT64_MAX - offset_nanoseconds);
            timestamp_nanoseconds += offset_nanoseconds;
        }
        assert(snprintf(values[field_index],
                   sizeof(values[field_index]),
                   "%" PRIu64,
                   timestamp_nanoseconds) > 0);
        replace_field(path, names[field_index], values[field_index]);
    }
}

static void check_report_result(const char *path, const char *expected_result)
{
    char value[128];
    struct paired_text_field field = {"result", value, sizeof(value), 0};
    assert(read_paired_fields(path, &field, 1) == 0);
    assert(strcmp(value, expected_result) == 0);
}

static void
check_confirmation_shapes(const char *parent, const char *generator, const char *analyzer)
{
    const char *const batch_sizes[] = {"1", "4", "16"};
    for (size_t batch_index = 0; batch_index < 3u; ++batch_index) {
        char directory[4096];
        char filename[64];
        char report_path[4096];
        assert(snprintf(filename,
                   sizeof(filename),
                   "confirmation-shape-k%s",
                   batch_sizes[batch_index]) > 0);
        assert(paired_data_path(directory, sizeof(directory), parent, filename) == 0);
        char *create_arguments[] = {(char *)generator,
            "--write-confirmation-fixture",
            directory,
            (char *)batch_sizes[batch_index],
            NULL};
        assert(invoke(create_arguments) == 0);
        assert(paired_data_path(report_path, sizeof(report_path), directory, "shape.report") == 0);
        char *analysis_arguments[] = {(char *)analyzer, directory, report_path, NULL};
        assert(invoke(analysis_arguments) == 0);
        check_report_result(report_path,
            batch_index == 0 ? "comparison_evidence_insufficient"
                             : "supports_this_measurement_quality_improvement");
        if (batch_index != 1u) {
            continue;
        }
        const char *const field_names[] = {"compiler_flags",
            "compile_options",
            "architecture",
            "os",
            "sanitizers"};
        const char *const original_values[] = {"synthetic",
            "synthetic",
            "x86_64",
            "Linux synthetic_software_fixture",
            "OFF"};
        const char *const changed_values[] = {"changed",
            "changed",
            "changed",
            "Linux changed_software_fixture",
            "ON"};
        char metadata_paths[2][4096];
        assert(paired_data_path(metadata_paths[0],
                   sizeof(metadata_paths[0]),
                   directory,
                   "fixture-01-baseline.meta") == 0);
        assert(paired_data_path(metadata_paths[1],
                   sizeof(metadata_paths[1]),
                   directory,
                   "fixture-01-candidate.meta") == 0);
        const char *const development_seeds[] = {"2026120101",
            "2026120105",
            "2026120201",
            "2026120205"};
        for (size_t seed_index = 0; seed_index < 4u; ++seed_index) {
            for (size_t method_index = 0; method_index < 2u; ++method_index) {
                replace_field(metadata_paths[method_index],
                    "test_seed",
                    development_seeds[seed_index]);
                update_run_digest(directory,
                    "fixture-01",
                    metadata_paths[method_index],
                    7u + 3u * method_index);
            }
            assert(snprintf(filename, sizeof(filename), "development-seed-%zu.report", seed_index) >
                0);
            assert(paired_data_path(report_path, sizeof(report_path), directory, filename) == 0);
            assert(invoke(analysis_arguments) == 0);
            check_report_result(report_path, "comparison_evidence_insufficient");
        }
        for (size_t method_index = 0; method_index < 2u; ++method_index) {
            replace_field(metadata_paths[method_index], "test_seed", "5001");
            update_run_digest(directory,
                "fixture-01",
                metadata_paths[method_index],
                7u + 3u * method_index);
        }
        for (size_t field_index = 0; field_index < 5u; ++field_index) {
            for (size_t method_index = 0; method_index < 2u; ++method_index) {
                replace_field(metadata_paths[method_index],
                    field_names[field_index],
                    changed_values[field_index]);
                update_run_digest(directory,
                    "fixture-01",
                    metadata_paths[method_index],
                    7u + 3u * method_index);
            }
            assert(snprintf(filename, sizeof(filename), "condition-%zu.report", field_index) > 0);
            assert(paired_data_path(report_path, sizeof(report_path), directory, filename) == 0);
            assert(invoke(analysis_arguments) == 1 && access(report_path, F_OK) != 0);
            for (size_t method_index = 0; method_index < 2u; ++method_index) {
                replace_field(metadata_paths[method_index],
                    field_names[field_index],
                    original_values[field_index]);
                update_run_digest(directory,
                    "fixture-01",
                    metadata_paths[method_index],
                    7u + 3u * method_index);
            }
        }
        char cost_paths[2][4096];
        assert(paired_data_path(cost_paths[0],
                   sizeof(cost_paths[0]),
                   directory,
                   "fixture-01-baseline.csv.cost") == 0);
        assert(paired_data_path(cost_paths[1],
                   sizeof(cost_paths[1]),
                   directory,
                   "fixture-01-candidate.csv.cost") == 0);
        for (size_t method_index = 0; method_index < 2u; ++method_index) {
            shift_cost_timestamps(cost_paths[method_index], 100000000u, 1);
            update_run_digest(directory,
                "fixture-01",
                cost_paths[method_index],
                8u + 3u * method_index);
        }
        assert(
            paired_data_path(report_path, sizeof(report_path), directory, "overlap.report") == 0);
        assert(invoke(analysis_arguments) == 1 && access(report_path, F_OK) != 0);
        for (size_t method_index = 0; method_index < 2u; ++method_index) {
            shift_cost_timestamps(cost_paths[method_index], 100000000u, 0);
            update_run_digest(directory,
                "fixture-01",
                cost_paths[method_index],
                8u + 3u * method_index);
        }
        assert(
            paired_data_path(report_path, sizeof(report_path), directory, "restored.report") == 0);
        assert(invoke(analysis_arguments) == 0);
        check_report_result(report_path, "supports_this_measurement_quality_improvement");
    }
}

int main(int argument_count, char **argument_values)
{
    assert(argument_count == 3);
    char parent[] = "/tmp/cry-paired-rejections.XXXXXX";
    assert(mkdtemp(parent) != NULL);
    char directory[4096];
    assert(paired_data_path(directory, sizeof(directory), parent, "fixture") == 0);
    char *create_arguments[] = {argument_values[1], "--write-fixture", directory, NULL};
    assert(invoke(create_arguments) == 0);
    char paths[4][4096];
    const char *filenames[] = {"fixture-00-baseline.csv",
        "fixture-00-baseline.meta",
        "fixture-00-candidate.csv",
        "fixture-00-candidate.meta"};
    for (size_t path_index = 0; path_index < 4u; ++path_index) {
        assert(paired_data_path(paths[path_index],
                   sizeof(paths[path_index]),
                   directory,
                   filenames[path_index]) == 0);
    }
    struct paired_run runs[2] = {{0}, {0}};
    assert(load_paired_run(paths[0], paths[1], &runs[0]) == 0);
    assert(load_paired_run(paths[2], paths[3], &runs[1]) == 0);
    assert(validate_paired_runs(&runs[0], &runs[1]) == 0);
    runs[1].ordered_input_digest[0] = '1';
    assert(validate_paired_runs(&runs[0], &runs[1]) == 1);
    runs[1].ordered_input_digest[0] = '0';
    ++runs[1].batch_records[0].category_counts[0];
    assert(validate_paired_runs(&runs[0], &runs[1]) == 1);
    --runs[1].batch_records[0].category_counts[0];
    runs[1].source_commit[0] = '1';
    assert(validate_paired_runs(&runs[0], &runs[1]) == 1);
    release_paired_run(&runs[0]);
    release_paired_run(&runs[1]);
    replace_field(paths[3], "run_status", "failed");
    assert(load_paired_run(paths[2], paths[3], &runs[1]) == 1);
    release_paired_run(&runs[1]);
    replace_field(paths[3], "run_status", "complete");
    char cost_path[4096];
    assert(snprintf(cost_path, sizeof(cost_path), "%s.cost", paths[0]) > 0);
    replace_field(cost_path, "collection_end_ns", "1000200");
    assert(load_paired_run(paths[0], paths[1], &runs[0]) == 1);
    release_paired_run(&runs[0]);
    replace_field(cost_path, "collection_end_ns", "1005719");
    assert(load_paired_run(paths[0], paths[1], &runs[0]) == 1);
    release_paired_run(&runs[0]);
    replace_field(cost_path, "collection_end_ns", "1005720");
    assert(load_paired_run(paths[0], paths[1], &runs[0]) == 0);
    release_paired_run(&runs[0]);
    char manifest_path[4096];
    char context_path[4096];
    assert(paired_data_path(manifest_path, sizeof(manifest_path), directory, "cohort.csv") == 0);
    assert(paired_data_path(context_path, sizeof(context_path), directory, "cohort.meta") == 0);
    char lines[21][4096];
    FILE *manifest = fopen(manifest_path, "r");
    assert(manifest != NULL);
    for (size_t line_index = 0; line_index < 21u; ++line_index) {
        assert(fgets(lines[line_index], sizeof(lines[line_index]), manifest) != NULL);
    }
    assert(fclose(manifest) == 0);
    manifest = fopen(manifest_path, "w");
    assert(manifest != NULL);
    for (size_t line_index = 0; line_index < 21u; ++line_index) {
        assert(fputs(lines[line_index == 2u ? 1u : line_index], manifest) >= 0);
    }
    assert(fclose(manifest) == 0);
    update_digest(manifest_path, context_path);
    char report_path[4096];
    assert(paired_data_path(report_path, sizeof(report_path), directory, "duplicate.report") == 0);
    char *analysis_arguments[] = {argument_values[2], directory, report_path, NULL};
    assert(invoke(analysis_arguments) == 1 && access(report_path, F_OK) != 0);
    manifest = fopen(manifest_path, "w");
    assert(manifest != NULL);
    for (size_t line_index = 0; line_index < 21u; ++line_index) {
        size_t selected_line = line_index == 1u ? 2u : line_index == 2u ? 1u : line_index;
        assert(fputs(lines[selected_line], manifest) >= 0);
    }
    assert(fclose(manifest) == 0);
    update_digest(manifest_path, context_path);
    assert(paired_data_path(report_path, sizeof(report_path), directory, "reordered.report") == 0);
    assert(invoke(analysis_arguments) == 1 && access(report_path, F_OK) != 0);
    manifest = fopen(manifest_path, "w");
    assert(manifest != NULL);
    for (size_t line_index = 0; line_index < 20u; ++line_index) {
        assert(fputs(lines[line_index], manifest) >= 0);
    }
    assert(fclose(manifest) == 0);
    update_digest(manifest_path, context_path);
    assert(
        paired_data_path(report_path, sizeof(report_path), directory, "missing-pair.report") == 0);
    assert(invoke(analysis_arguments) == 0);
    char value[64];
    struct paired_text_field count_field = {"pair_count", value, sizeof(value), 0};
    assert(read_paired_fields(report_path, &count_field, 1) == 0 && strcmp(value, "19") == 0);
    struct paired_text_field result_field = {"result", value, sizeof(value), 0};
    assert(read_paired_fields(report_path, &result_field, 1) == 0 &&
        strcmp(value, "comparison_evidence_insufficient") == 0);
    replace_field(context_path, "cohort_status", "partial");
    assert(paired_data_path(report_path, sizeof(report_path), directory, "partial.report") == 0);
    assert(invoke(analysis_arguments) == 1 && access(report_path, F_OK) != 0);
    check_confirmation_shapes(parent, argument_values[1], argument_values[2]);
    printf("software_rejection_fixture_directory=%s\n", directory);
    return 0;
}
