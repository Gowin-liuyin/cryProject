#define _POSIX_C_SOURCE 200809L
#ifdef __APPLE__
#define _DARWIN_C_SOURCE
#endif
#include <assert.h>
#include <fcntl.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/wait.h>
#include <unistd.h>

static const char expected_digest[] =
    "3a985da74fe225b2045c172d6bd390bd855f086e3e9d525b46bfe24511431532";

static int invoke_parser(const char *program, const char *log_path, char output[128])
{
    int descriptors[2];
    assert(pipe(descriptors) == 0);
    pid_t child_process = fork();
    assert(child_process >= 0);
    if (child_process == 0) {
        assert(close(descriptors[0]) == 0);
        assert(dup2(descriptors[1], STDOUT_FILENO) >= 0);
        assert(close(descriptors[1]) == 0);
        execl(program, program, log_path, (char *)NULL);
        _exit(127);
    }
    assert(close(descriptors[1]) == 0);
    size_t output_bytes = 0;
    ssize_t read_bytes;
    while ((read_bytes = read(descriptors[0], output + output_bytes, 127u - output_bytes)) > 0) {
        output_bytes += (size_t)read_bytes;
        assert(output_bytes < 127u);
    }
    assert(read_bytes == 0 && close(descriptors[0]) == 0);
    output[output_bytes] = '\0';
    int wait_status;
    assert(waitpid(child_process, &wait_status, 0) == child_process && WIFEXITED(wait_status));
    return WEXITSTATUS(wait_status);
}

static void write_log(const char *log_path, const char *text)
{
    FILE *log_file = fopen(log_path, "w");
    assert(log_file != NULL && fputs(text, log_file) >= 0 && fclose(log_file) == 0);
}

int main(int argument_count, char **argument_values)
{
    assert(argument_count == 3);
    char directory[] = "/tmp/cry-native-digest.XXXXXX";
    assert(mkdtemp(directory) != NULL);
    char input_path[256];
    char log_path[256];
    assert(snprintf(input_path, sizeof(input_path), "%s/input.bin", directory) > 0);
    assert(snprintf(log_path, sizeof(log_path), "%s/openssl.log", directory) > 0);
    write_log(input_path, "abc");
    write_log(log_path, "arguments_begin\nopenssl\ndgst\n-sha3-256\narguments_end\n");
    pid_t child_process = fork();
    assert(child_process >= 0);
    if (child_process == 0) {
        int log_descriptor = open(log_path, O_WRONLY | O_APPEND);
        assert(log_descriptor >= 0 && dup2(log_descriptor, STDOUT_FILENO) >= 0);
        assert(close(log_descriptor) == 0);
        execl(argument_values[2],
            argument_values[2],
            "dgst",
            "-sha3-256",
            input_path,
            (char *)NULL);
        _exit(127);
    }
    int wait_status;
    assert(waitpid(child_process, &wait_status, 0) == child_process && WIFEXITED(wait_status));
    assert(WEXITSTATUS(wait_status) == 0);
    FILE *log_file = fopen(log_path, "a");
    assert(log_file != NULL && fputs("Tue Oct 6 11:14:22 UTC 2026\n", log_file) >= 0 &&
        fclose(log_file) == 0);
    char output[128];
    assert(invoke_parser(argument_values[1], log_path, output) == 0);
    assert(
        strlen(output) == 65u && strncmp(output, expected_digest, 64) == 0 && output[64] == '\n');
    write_log(log_path, "arguments_begin\nopenssl\nTue Oct 6 11:14:22 UTC 2026\n");
    assert(invoke_parser(argument_values[1], log_path, output) == 1 && output[0] == '\0');
    log_file = fopen(log_path, "a");
    assert(log_file != NULL);
    assert(fprintf(log_file,
               "SHA3-256(first)= %s\nSHA3-256(second)= %s\nTue Oct 6 11:14:22 UTC 2026\n",
               expected_digest,
               expected_digest) > 0 &&
        fclose(log_file) == 0);
    assert(invoke_parser(argument_values[1], log_path, output) == 1 && output[0] == '\0');
    write_log(log_path, "SHA3-256(input)= 1234\nTue Oct 6 11:14:22 UTC 2026\n");
    assert(invoke_parser(argument_values[1], log_path, output) == 1 && output[0] == '\0');
    assert(unlink(input_path) == 0 && unlink(log_path) == 0 && rmdir(directory) == 0);
    return 0;
}
