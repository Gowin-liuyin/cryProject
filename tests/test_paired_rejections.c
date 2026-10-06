#define _POSIX_C_SOURCE 200809L
#ifdef __APPLE__
#define _DARWIN_C_SOURCE
#endif
#include "paired_data.h"

#include <assert.h>
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
    printf("software_rejection_fixture_directory=%s\n", directory);
    return 0;
}
