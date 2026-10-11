#define _POSIX_C_SOURCE 200809L

#include "inputs.h"
#include "mlkem.h"
#include "network_frame.h"

#include <assert.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/wait.h>
#include <unistd.h>

static void test_frames(void)
{
    uint8_t first_ciphertext[1088];
    uint8_t second_ciphertext[1088];
    uint8_t first_request[NETWORK_REQUEST_BYTES];
    uint8_t second_request[NETWORK_REQUEST_BYTES];
    uint8_t parsed[1088];
    uint8_t first_ack[NETWORK_ACK_BYTES];
    uint8_t second_ack[NETWORK_ACK_BYTES];
    uint8_t secret_pattern[NETWORK_ACK_BYTES];
    uint64_t request_index = 0u;
    memset(first_ciphertext, 1, sizeof(first_ciphertext));
    memset(second_ciphertext, 2, sizeof(second_ciphertext));
    memset(secret_pattern, 0xA5, sizeof(secret_pattern));
    assert(network_build_request(first_request,
               sizeof(first_request),
               1u,
               first_ciphertext,
               sizeof(first_ciphertext)) == 0);
    assert(network_build_request(second_request,
               sizeof(second_request),
               2u,
               second_ciphertext,
               sizeof(second_ciphertext)) == 0);
    assert(network_parse_request(first_request,
               sizeof(first_request),
               &request_index,
               parsed,
               sizeof(parsed)) == 0);
    assert(request_index == 1u);
    assert(memcmp(parsed, first_ciphertext, sizeof(parsed)) == 0);
    first_request[0] ^= 1u;
    assert(network_parse_request(first_request,
               sizeof(first_request),
               &request_index,
               parsed,
               sizeof(parsed)) != 0);
    assert(network_build_acknowledgement(first_ack, sizeof(first_ack)) == 0);
    assert(network_build_acknowledgement(second_ack, sizeof(second_ack)) == 0);
    assert(memcmp(first_ack, second_ack, sizeof(first_ack)) == 0);
    assert(memcmp(first_ack, secret_pattern, sizeof(first_ack)) != 0);
    assert(network_acknowledgement_is_fixed(first_ack, sizeof(first_ack)));
    first_ack[20] = 1u;
    assert(!network_acknowledgement_is_fixed(first_ack, sizeof(first_ack)));
}

static void test_loopback(const char *server_path, const char *client_path)
{
    const char *temp_root = getenv("A113_TEST_TMPDIR");
    char rtt_path[512];
    char ack_path[512];
    int server_pipe[2];
    pid_t server_pid;
    char bound_line[64];
    FILE *server_output;
    FILE *ack_file;
    uint8_t acknowledgements[64];
    uint8_t encapsulation_key[MLKEM_ENCAPSULATION_KEY_BYTES];
    uint8_t decapsulation_key[MLKEM_DECAPSULATION_KEY_BYTES];
    uint8_t ciphertext[MLKEM_CIPHERTEXT_BYTES];
    uint8_t shared_secret[MLKEM_SHARED_SECRET_BYTES];
    int server_status = 1;
    int client_status = 1;
    assert(temp_root != NULL);
    assert(snprintf(rtt_path, sizeof(rtt_path), "%s/loopback-rtt.csv", temp_root) <
        (int)sizeof(rtt_path));
    assert(snprintf(ack_path, sizeof(ack_path), "%s.acks", rtt_path) < (int)sizeof(ack_path));
    (void)remove(rtt_path);
    (void)remove(ack_path);
    assert(pipe(server_pipe) == 0);
    server_pid = fork();
    assert(server_pid >= 0);
    if (server_pid == 0) {
        char port_text[] = "0";
        (void)dup2(server_pipe[1], STDOUT_FILENO);
        (void)close(server_pipe[0]);
        (void)close(server_pipe[1]);
        execl(server_path,
            server_path,
            "--bind",
            "127.0.0.1",
            "--port",
            port_text,
            "--seed",
            "31337",
            "--request-count",
            "2",
            (char *)NULL);
        _exit(1);
    }
    (void)close(server_pipe[1]);
    server_output = fdopen(server_pipe[0], "r");
    assert(server_output != NULL);
    assert(fgets(bound_line, sizeof(bound_line), server_output) != NULL);
    assert(strncmp(bound_line, "bound_port=", 11) == 0);
    bound_line[strcspn(bound_line, "\r\n")] = '\0';
    {
        pid_t client_pid = fork();
        assert(client_pid >= 0);
        if (client_pid == 0) {
            execl(client_path,
                client_path,
                "--connect",
                "127.0.0.1",
                "--port",
                bound_line + 11,
                "--seed",
                "31337",
                "--request-count",
                "2",
                "--rtt-path",
                rtt_path,
                (char *)NULL);
            _exit(1);
        }
        assert(waitpid(client_pid, &client_status, 0) == client_pid);
    }
    assert(WIFEXITED(client_status) && WEXITSTATUS(client_status) == 0);
    assert(waitpid(server_pid, &server_status, 0) == server_pid);
    assert(WIFEXITED(server_status) && WEXITSTATUS(server_status) == 0);
    assert(fgets(bound_line, sizeof(bound_line), server_output) != NULL);
    assert(strcmp(bound_line, "completed_decapsulations=2\n") == 0);
    (void)fclose(server_output);
    ack_file = fopen(ack_path, "rb");
    assert(ack_file != NULL);
    assert(
        fread(acknowledgements, 1, sizeof(acknowledgements), ack_file) == sizeof(acknowledgements));
    assert(fclose(ack_file) == 0);
    assert(memcmp(acknowledgements, acknowledgements + 32, 32) == 0);
    assert(network_acknowledgement_is_fixed(acknowledgements, 32u));
    assert(generate_test_key_pair(31337u, encapsulation_key, decapsulation_key) == 0);
    assert(generate_test_ciphertext(INPUT_VALID, 31337u, 0u, encapsulation_key, ciphertext) == 0);
    assert(mlkem_decapsulate(shared_secret,
               sizeof(shared_secret),
               ciphertext,
               sizeof(ciphertext),
               decapsulation_key,
               sizeof(decapsulation_key)) == 0);
    assert(memcmp(shared_secret, acknowledgements, 32) != 0);
    erase_secret_bytes(shared_secret, sizeof(shared_secret));
    erase_secret_bytes(decapsulation_key, sizeof(decapsulation_key));
}

int main(int argc, char **argv)
{
    if (argc != 3) {
        return 1;
    }
    test_frames();
    test_loopback(argv[1], argv[2]);
    return 0;
}
