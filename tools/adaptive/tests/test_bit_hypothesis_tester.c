/* T6.1 单测：合成数据下逐位检验器 20 次判定 20 对；完全相同两组 → p=1；
 * 非法参数/坏 CSV 的退出码。通过 CTest 的 A113_TEST_TMPDIR 取临时目录。 */

#define _POSIX_C_SOURCE 200809L

#include <fcntl.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/stat.h>
#include <sys/wait.h>
#include <unistd.h>

#define TEST_PATH_CAPACITY_BYTES 4096u
#define TEST_REPEAT_COUNT 1000u
#define TEST_JUDGEMENT_COUNT 20u
#define TEST_LCG_MULTIPLIER 1664525u
#define TEST_LCG_INCREMENT 1013904223u

static uint32_t next_lcg_value(uint32_t *state)
{
    *state = *state * TEST_LCG_MULTIPLIER + TEST_LCG_INCREMENT;
    return *state;
}

static int run_program(const char *program, char *const argument_values[], const char *output_path)
{
    pid_t child_process = fork();
    if (child_process < 0) {
        return -1;
    }
    if (child_process == 0) {
        int output_descriptor = open(output_path, O_WRONLY | O_CREAT | O_TRUNC, 0600);
        if (output_descriptor < 0) {
            _exit(126);
        }
        if (dup2(output_descriptor, STDOUT_FILENO) < 0) {
            _exit(126);
        }
        (void)close(output_descriptor);
        execv(program, argument_values);
        _exit(127);
    }
    int wait_status = 0;
    if (waitpid(child_process, &wait_status, 0) != child_process) {
        return -1;
    }
    if (!WIFEXITED(wait_status)) {
        return -1;
    }
    return WEXITSTATUS(wait_status);
}

static int read_output_line(const char *output_path, const char *key, char *value, size_t capacity)
{
    FILE *output_file = fopen(output_path, "r");
    if (output_file == NULL) {
        return 1;
    }
    char line[512];
    size_t key_bytes = strlen(key);
    int status = 1;
    while (fgets(line, (int)sizeof(line), output_file) != NULL) {
        if (strncmp(line, key, key_bytes) == 0 && line[key_bytes] == '=') {
            size_t line_bytes = strlen(line);
            if (line_bytes > 0u && line[line_bytes - 1u] == '\n') {
                line[line_bytes - 1u] = '\0';
            }
            (void)snprintf(value, capacity, "%s", line + key_bytes + 1u);
            status = 0;
            break;
        }
    }
    (void)fclose(output_file);
    return status;
}

static int write_judgement_csv(const char *csv_path, uint32_t *lcg_state, int identical_groups)
{
    FILE *csv_file = fopen(csv_path, "w");
    if (csv_file == NULL) {
        return 1;
    }
    if (fprintf(csv_file, "hypothesis_zero_nanoseconds,hypothesis_one_nanoseconds\n") < 0) {
        (void)fclose(csv_file);
        return 1;
    }
    for (unsigned repeat_index = 0u; repeat_index < TEST_REPEAT_COUNT; ++repeat_index) {
        uint32_t random_value = next_lcg_value(lcg_state);
        double hypothesis_zero_nanoseconds =
            1000.0 + (double)(random_value % 37u) + (double)(repeat_index % 5u) * 0.25;
        double hypothesis_one_nanoseconds = 0.0;
        if (identical_groups != 0) {
            hypothesis_one_nanoseconds = hypothesis_zero_nanoseconds;
        } else {
            /* 位=0 判定组：t_h1 比 t_h0 低 30 ns（vote=(t_h1>t_h0) 全为假 → decision 0）。 */
            hypothesis_one_nanoseconds =
                hypothesis_zero_nanoseconds - 30.0 + (double)(random_value % 3u) * 0.5;
        }
        if (fprintf(csv_file,
                "%.17g,%.17g\n",
                hypothesis_zero_nanoseconds,
                hypothesis_one_nanoseconds) < 0) {
            (void)fclose(csv_file);
            return 1;
        }
    }
    return fclose(csv_file) == 0 ? 0 : 1;
}

int main(int argument_count, char **argument_values)
{
    if (argument_count != 2) {
        fprintf(stderr, "usage: test_bit_hypothesis_tester <tester_program>\n");
        return 1;
    }
    const char *tester_program = argument_values[1];
    const char *temporary_root = getenv("A113_TEST_TMPDIR");
    if (temporary_root == NULL || temporary_root[0] != '/') {
        fprintf(stderr, "error: A113_TEST_TMPDIR must be an absolute path\n");
        return 1;
    }
    char csv_path[TEST_PATH_CAPACITY_BYTES];
    char output_path[TEST_PATH_CAPACITY_BYTES];
    if (snprintf(csv_path,
            sizeof(csv_path),
            "%s/bit-tester-%ld.csv",
            temporary_root,
            (long)getpid()) < 0 ||
        snprintf(output_path,
            sizeof(output_path),
            "%s/bit-tester-%ld.out",
            temporary_root,
            (long)getpid()) < 0) {
        return 1;
    }
    uint32_t lcg_state = UINT32_C(20261116);
    unsigned correct_count = 0u;
    for (unsigned judgement_index = 0u; judgement_index < TEST_JUDGEMENT_COUNT; ++judgement_index) {
        if (write_judgement_csv(csv_path, &lcg_state, 0) != 0) {
            fprintf(stderr, "error: cannot write judgement CSV\n");
            return 1;
        }
        char *tester_arguments[] = {(char *)tester_program, (char *)"--input", csv_path, NULL};
        int exit_code = run_program(tester_program, tester_arguments, output_path);
        if (exit_code != 0) {
            fprintf(stderr, "error: tester exited %d\n", exit_code);
            return 1;
        }
        char decision_text[32];
        char p_value_text[64];
        if (read_output_line(output_path, "decision", decision_text, sizeof(decision_text)) != 0 ||
            read_output_line(output_path, "p_value", p_value_text, sizeof(p_value_text)) != 0) {
            fprintf(stderr, "error: tester output is missing decision/p_value\n");
            return 1;
        }
        double p_value = strtod(p_value_text, NULL);
        if (strcmp(decision_text, "0") == 0 && p_value < 0.05) {
            ++correct_count;
        }
    }
    if (correct_count != TEST_JUDGEMENT_COUNT) {
        fprintf(stderr,
            "error: %u/%u judgements correct, expected %u/%u\n",
            correct_count,
            TEST_JUDGEMENT_COUNT,
            TEST_JUDGEMENT_COUNT,
            TEST_JUDGEMENT_COUNT);
        return 1;
    }

    /* 完全相同两组：逐元素相等，按未检出输出 decision=0、p=1。 */
    if (write_judgement_csv(csv_path, &lcg_state, 1) != 0) {
        fprintf(stderr, "error: cannot write identical-groups CSV\n");
        return 1;
    }
    char *tester_arguments[] = {(char *)tester_program, (char *)"--input", csv_path, NULL};
    int exit_code = run_program(tester_program, tester_arguments, output_path);
    if (exit_code != 0) {
        return 1;
    }
    char decision_text[32];
    char p_value_text[64];
    if (read_output_line(output_path, "decision", decision_text, sizeof(decision_text)) != 0 ||
        read_output_line(output_path, "p_value", p_value_text, sizeof(p_value_text)) != 0) {
        return 1;
    }
    if (strcmp(decision_text, "0") != 0 || strtod(p_value_text, NULL) != 1.0) {
        fprintf(stderr, "error: identical groups must give decision 0 / p=1\n");
        return 1;
    }

    /* 非法参数/坏 CSV 的退出码。 */
    char *missing_input_arguments[] = {(char *)tester_program, NULL};
    if (run_program(tester_program, missing_input_arguments, output_path) != 1) {
        fprintf(stderr, "error: missing --input must exit 1\n");
        return 1;
    }
    char *missing_file_arguments[] = {(char *)tester_program,
        (char *)"--input",
        (char *)"/nonexistent-input.csv",
        NULL};
    if (run_program(tester_program, missing_file_arguments, output_path) != 2) {
        fprintf(stderr, "error: missing input file must exit 2\n");
        return 1;
    }
    (void)remove(csv_path);
    (void)remove(output_path);
    printf("bit_hypothesis_tester: %u/%u judgements correct; identical p=1; exit codes ok\n",
        correct_count,
        TEST_JUDGEMENT_COUNT);
    return 0;
}
