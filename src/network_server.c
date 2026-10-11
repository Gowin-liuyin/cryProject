#define _POSIX_C_SOURCE 200809L

#include "inputs.h"
#include "mlkem.h"
#include "network_frame.h"

#include <arpa/inet.h>
#include <netinet/in.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/socket.h>
#include <unistd.h>

static volatile uint8_t result_sink;

static int read_full(int socket_fd, uint8_t *bytes, size_t byte_count)
{
    size_t received = 0u;
    while (received < byte_count) {
        ssize_t chunk = recv(socket_fd, bytes + received, byte_count - received, 0);
        if (chunk <= 0) {
            return 1;
        }
        received += (size_t)chunk;
    }
    return 0;
}

static int write_full(int socket_fd, const uint8_t *bytes, size_t byte_count)
{
    size_t sent = 0u;
    while (sent < byte_count) {
        ssize_t chunk = send(socket_fd, bytes + sent, byte_count - sent, 0);
        if (chunk <= 0) {
            return 1;
        }
        sent += (size_t)chunk;
    }
    return 0;
}

static int argument_value(int argc, char **argv, const char *name, const char **value)
{
    for (int argument_index = 1; argument_index + 1 < argc; ++argument_index) {
        if (strcmp(argv[argument_index], name) == 0) {
            *value = argv[argument_index + 1];
            return 0;
        }
    }
    return 1;
}

int main(int argc, char **argv)
{
    const char *bind_address = NULL;
    const char *port_text = NULL;
    const char *seed_text = NULL;
    const char *count_text = NULL;
    uint64_t test_seed;
    uint64_t request_count;
    int listen_fd = -1;
    int connection_fd = -1;
    struct sockaddr_in address;
    socklen_t address_length = sizeof(address);
    int bound_port = 0;
    uint8_t encapsulation_key[MLKEM_ENCAPSULATION_KEY_BYTES];
    uint8_t decapsulation_key[MLKEM_DECAPSULATION_KEY_BYTES];
    uint8_t shared_secret[MLKEM_SHARED_SECRET_BYTES];
    int operation_status = 1;
    if (argument_value(argc, argv, "--bind", &bind_address) != 0 ||
        argument_value(argc, argv, "--port", &port_text) != 0 ||
        argument_value(argc, argv, "--seed", &seed_text) != 0 ||
        argument_value(argc, argv, "--request-count", &count_text) != 0 ||
        parse_unsigned_integer(seed_text, &test_seed) != 0 ||
        parse_unsigned_integer(count_text, &request_count) != 0 || request_count == 0u) {
        fputs("usage: network_server --bind ADDRESS --port PORT --seed SEED "
              "--request-count N\n",
            stderr);
        return 1;
    }
    listen_fd = socket(AF_INET, SOCK_STREAM, 0);
    if (listen_fd < 0) {
        return 1;
    }
    {
        int reuse = 1;
        (void)setsockopt(listen_fd, SOL_SOCKET, SO_REUSEADDR, &reuse, sizeof(reuse));
    }
    memset(&address, 0, sizeof(address));
    address.sin_family = AF_INET;
    address.sin_port = htons((uint16_t)strtoul(port_text, NULL, 10));
    if (inet_pton(AF_INET, bind_address, &address.sin_addr) != 1 ||
        bind(listen_fd, (struct sockaddr *)&address, sizeof(address)) != 0 ||
        listen(listen_fd, 1) != 0 ||
        getsockname(listen_fd, (struct sockaddr *)&address, &address_length) != 0) {
        goto cleanup;
    }
    bound_port = ntohs(address.sin_port);
    if (printf("bound_port=%d\n", bound_port) < 0 || fflush(stdout) != 0) {
        goto cleanup;
    }
    connection_fd = accept(listen_fd, NULL, NULL);
    if (connection_fd < 0 ||
        generate_test_key_pair(test_seed, encapsulation_key, decapsulation_key) != 0) {
        goto cleanup;
    }
    for (uint64_t request_index = 0; request_index < request_count; ++request_index) {
        uint8_t request[NETWORK_REQUEST_BYTES];
        uint8_t acknowledgement[NETWORK_ACK_BYTES];
        uint8_t ciphertext[MLKEM_CIPHERTEXT_BYTES];
        uint64_t parsed_index = 0u;
        if (read_full(connection_fd, request, sizeof(request)) != 0 ||
            network_parse_request(request,
                sizeof(request),
                &parsed_index,
                ciphertext,
                sizeof(ciphertext)) != 0 ||
            mlkem_decapsulate(shared_secret,
                sizeof(shared_secret),
                ciphertext,
                sizeof(ciphertext),
                decapsulation_key,
                sizeof(decapsulation_key)) != 0) {
            goto cleanup;
        }
        result_sink ^= shared_secret[0];
        erase_secret_bytes(shared_secret, sizeof(shared_secret));
        if (network_build_acknowledgement(acknowledgement, sizeof(acknowledgement)) != 0 ||
            write_full(connection_fd, acknowledgement, sizeof(acknowledgement)) != 0) {
            goto cleanup;
        }
    }
    if (printf("completed_decapsulations=%llu\n", (unsigned long long)request_count) < 0) {
        goto cleanup;
    }
    operation_status = 0;
cleanup:
    erase_secret_bytes(decapsulation_key, sizeof(decapsulation_key));
    erase_secret_bytes(shared_secret, sizeof(shared_secret));
    if (connection_fd >= 0) {
        (void)close(connection_fd);
    }
    if (listen_fd >= 0) {
        (void)close(listen_fd);
    }
    return operation_status;
}
