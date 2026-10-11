#define _POSIX_C_SOURCE 200809L

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

static int file_contains(const char *path, const char *needle)
{
    FILE *file = fopen(path, "r");
    char line[1024];
    if (file == NULL) {
        return 0;
    }
    while (fgets(line, sizeof(line), file) != NULL) {
        if (strstr(line, needle) != NULL) {
            (void)fclose(file);
            return 1;
        }
    }
    (void)fclose(file);
    return 0;
}

int main(int argc, char **argv)
{
    const char *temp_root = getenv("A113_TEST_TMPDIR");
    char events_path[512];
    char summary_path[512];
    char candidate_path[512];
    char command[2048];
    const char *stages[] = {"decode",
        "decrypt",
        "message_extraction",
        "reencryption",
        "compare",
        "rejection_key",
        "selection"};
    int status;
    if (argc != 2 || temp_root == NULL || temp_root[0] != '/') {
        return 1;
    }
    if (snprintf(events_path, sizeof(events_path), "%s/diagnostic-events.csv", temp_root) >=
            (int)sizeof(events_path) ||
        snprintf(summary_path, sizeof(summary_path), "%s/diagnostic-summary.txt", temp_root) >=
            (int)sizeof(summary_path) ||
        snprintf(candidate_path,
            sizeof(candidate_path),
            "%s/diagnostic-candidates.csv",
            temp_root) >= (int)sizeof(candidate_path)) {
        return 1;
    }
    (void)remove(events_path);
    (void)remove(summary_path);
    (void)remove(candidate_path);
    if (snprintf(command,
            sizeof(command),
            "'%s' --account 31337 1 '%s' '%s' '%s'",
            argv[1],
            events_path,
            summary_path,
            candidate_path) >= (int)sizeof(command)) {
        return 1;
    }
    status = system(command);
    if (status != 0) {
        return 1;
    }
    if (!file_contains(events_path,
            "sample_id,function_id,call_relation,timestamp_counts,integrity_status") ||
        !file_contains(events_path, ",1,") || !file_contains(events_path, ",2,") ||
        file_contains(events_path, "shared_secret") || file_contains(events_path, "verify") ||
        file_contains(events_path, "ground_truth")) {
        return 1;
    }
    if (!file_contains(summary_path, "hook_cost_not_subtracted=yes\n") ||
        !file_contains(summary_path, "compiler_events=enter_exit\n") ||
        !file_contains(summary_path, "inline_mapping stage=compare") ||
        !file_contains(summary_path, "inline_mapping stage=rejection_key") ||
        !file_contains(summary_path, "inline_mapping stage=selection")) {
        return 1;
    }
    for (size_t stage_index = 0; stage_index < sizeof(stages) / sizeof(stages[0]); ++stage_index) {
        char uncovered_row[96];
        if (!file_contains(candidate_path, stages[stage_index])) {
            return 1;
        }
        if (snprintf(uncovered_row, sizeof(uncovered_row), "uncovered,%s,", stages[stage_index]) <
            0) {
            return 1;
        }
        if (file_contains(candidate_path, uncovered_row)) {
            return 1;
        }
    }
    return 0;
}
