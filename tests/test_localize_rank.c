#define _POSIX_C_SOURCE 200809L

#include <assert.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/wait.h>

static char *run_capture(const char *command)
{
    FILE *pipe = popen(command, "r");
    char *text = NULL;
    size_t capacity = 0u;
    size_t length = 0u;
    char chunk[256];
    assert(pipe != NULL);
    while (fgets(chunk, sizeof(chunk), pipe) != NULL) {
        size_t chunk_length = strlen(chunk);
        char *grown = realloc(text, length + chunk_length + 1u);
        assert(grown != NULL);
        text = grown;
        memcpy(text + length, chunk, chunk_length + 1u);
        length += chunk_length;
        (void)capacity;
    }
    assert(pclose(pipe) == 0);
    return text;
}

static void assert_same_top(const char *first, const char *second, const char *stage)
{
    char needle[64];
    assert(snprintf(needle, sizeof(needle), "top1_stage=%s\n", stage) < (int)sizeof(needle));
    assert(strstr(first, needle) != NULL);
    assert(strstr(second, needle) != NULL);
    assert(strcmp(first, second) == 0);
    assert(strstr(first, "top3_1_stage=") != NULL);
    assert(strstr(first, "\nroot_cause=") == NULL);
    assert(strncmp(first, "root_cause=", 11) != 0);
}

int main(int argc, char **argv)
{
    const char *temp_root = getenv("A113_TEST_TMPDIR");
    char detection_yes[512];
    char detection_no[512];
    char forbidden_path[512];
    char command[2048];
    char *first;
    char *second;
    char *compare_first;
    FILE *file;
    int status;
    if (argc != 4 || temp_root == NULL) {
        return 1;
    }
    assert(snprintf(detection_yes, sizeof(detection_yes), "%s/detected-yes.txt", temp_root) <
        (int)sizeof(detection_yes));
    assert(snprintf(detection_no, sizeof(detection_no), "%s/detected-no.txt", temp_root) <
        (int)sizeof(detection_no));
    assert(snprintf(forbidden_path, sizeof(forbidden_path), "%s/forbidden-rank.csv", temp_root) <
        (int)sizeof(forbidden_path));
    file = fopen(detection_yes, "w");
    assert(file != NULL);
    assert(fputs("end_to_end_detected=yes\n", file) >= 0);
    assert(fclose(file) == 0);
    file = fopen(detection_no, "w");
    assert(file != NULL);
    assert(fputs("end_to_end_detected=no\n", file) >= 0);
    assert(fclose(file) == 0);
    assert(snprintf(command, sizeof(command), "'%s' '%s' '%s'", argv[1], argv[2], detection_yes) <
        (int)sizeof(command));
    first = run_capture(command);
    second = run_capture(command);
    assert_same_top(first, second, "reencryption");
    assert(snprintf(command, sizeof(command), "'%s' '%s' '%s'", argv[1], argv[3], detection_yes) <
        (int)sizeof(command));
    compare_first = run_capture(command);
    second = run_capture(command);
    assert_same_top(compare_first, second, "compare");
    assert(strstr(first, "top1_stage=reencryption") != NULL);
    assert(strstr(compare_first, "top1_stage=compare") != NULL);
    assert(strcmp(first, compare_first) != 0);
    file = fopen(forbidden_path, "w");
    assert(file != NULL);
    assert(fputs("ground_truth,stage_id,function_id\n", file) >= 0);
    assert(fclose(file) == 0);
    assert(snprintf(command,
               sizeof(command),
               "'%s' '%s' '%s'",
               argv[1],
               forbidden_path,
               detection_yes) < (int)sizeof(command));
    status = system(command);
    assert(WIFEXITED(status) && WEXITSTATUS(status) == 2);
    assert(snprintf(command, sizeof(command), "'%s' '%s' '%s'", argv[1], argv[2], detection_no) <
        (int)sizeof(command));
    free(first);
    first = run_capture(command);
    assert(strstr(first, "single_root_cause=not_forced\n") != NULL);
    assert(strstr(first, "\nroot_cause=") == NULL);
    assert(strncmp(first, "root_cause=", 11) != 0);
    free(first);
    free(compare_first);
    return 0;
}
