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
#include <time.h>
#include <unistd.h>

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

static enum input_category category_for_index(uint64_t request_index)
{
    switch (request_index % 5u) {
    case 0u:
        return INPUT_VALID;
    case 1u:
        return INPUT_BIT_FLIPPED;
    case 2u:
        return INPUT_RANDOM;
    case 3u:
        return INPUT_MESSAGE_ZERO;
    default:
        return INPUT_MESSAGE_ONES;
    }
}

static int read_monotonic(uint64_t *timestamp_counts)
{
    struct timespec timestamp;
    if (clock_gettime(CLOCK_MONOTONIC, &timestamp) != 0 || timestamp.tv_sec < 0) {
        return 1;
    }
    *timestamp_counts =
        (uint64_t)timestamp.tv_sec * UINT64_C(1000000000) + (uint64_t)timestamp.tv_nsec;
    return 0;
}

int main(int argc, char **argv)
{
    const char *connect_address = NULL;
    const char *port_text = NULL;
    const char *seed_text = NULL;
    const char *count_text = NULL;
    const char *rtt_path = NULL;
    uint64_t test_seed;
    uint64_t request_count;
    int socket_fd = -1;
    struct sockaddr_in address;
    FILE *rtt_file = NULL;
    FILE *ack_file = NULL;
    char ack_path[512];
    uint8_t encapsulation_key[MLKEM_ENCAPSULATION_KEY_BYTES];
    uint8_t decapsulation_key[MLKEM_DECAPSULATION_KEY_BYTES];
    int operation_status = 1;
    if (argument_value(argc, argv, "--connect", &connect_address) != 0 ||
        argument_value(argc, argv, "--port", &port_text) != 0 ||
        argument_value(argc, argv, "--seed", &seed_text) != 0 ||
        argument_value(argc, argv, "--request-count", &count_text) != 0 ||
        argument_value(argc, argv, "--rtt-path", &rtt_path) != 0 ||
        parse_unsigned_integer(seed_text, &test_seed) != 0 ||
        parse_unsigned_integer(count_text, &request_count) != 0 || request_count == 0u) {
        fputs("usage: network_client --connect ADDRESS --port PORT --seed SEED "
              "--request-count N --rtt-path PATH\n",
            stderr);
        return 1;
    }
    if (snprintf(ack_path, sizeof(ack_path), "%s.acks", rtt_path) >= (int)sizeof(ack_path)) {
        return 1;
    }
    rtt_file = fopen(rtt_path, "wx");
    ack_file = fopen(ack_path, "wx");
    if (rtt_file == NULL || ack_file == NULL ||
        fprintf(rtt_file, "request_index,elapsed_clock_counts,clock_path\n") < 0 ||
        generate_test_key_pair(test_seed, encapsulation_key, decapsulation_key) != 0) {
        goto cleanup;
    }
    socket_fd = socket(AF_INET, SOCK_STREAM, 0);
    memset(&address, 0, sizeof(address));
    address.sin_family = AF_INET;
    address.sin_port = htons((uint16_t)strtoul(port_text, NULL, 10));
    if (socket_fd < 0 || inet_pton(AF_INET, connect_address, &address.sin_addr) != 1 ||
        connect(socket_fd, (struct sockaddr *)&address, sizeof(address)) != 0) {
        goto cleanup;
    }
    for (uint64_t request_index = 0; request_index < request_count; ++request_index) {
        uint8_t ciphertext[MLKEM_CIPHERTEXT_BYTES];
        uint8_t request[NETWORK_REQUEST_BYTES];
        uint8_t acknowledgement[NETWORK_ACK_BYTES];
        uint64_t start_counts = 0u;
        uint64_t end_counts = 0u;
        if (generate_test_ciphertext(category_for_index(request_index),
                test_seed,
                0u,
                encapsulation_key,
                ciphertext) != 0 ||
            network_build_request(request,
                sizeof(request),
                request_index,
                ciphertext,
                sizeof(ciphertext)) != 0 ||
            read_monotonic(&start_counts) != 0 ||
            write_full(socket_fd, request, sizeof(request)) != 0 ||
            read_full(socket_fd, acknowledgement, sizeof(acknowledgement)) != 0 ||
            read_monotonic(&end_counts) != 0 || end_counts < start_counts ||
            !network_acknowledgement_is_fixed(acknowledgement, sizeof(acknowledgement))) {
            goto cleanup;
        }
        if (fprintf(rtt_file,
                "%llu,%llu,CLOCK_MONOTONIC\n",
                (unsigned long long)request_index,
                (unsigned long long)(end_counts - start_counts)) < 0 ||
            fwrite(acknowledgement, 1, sizeof(acknowledgement), ack_file) !=
                sizeof(acknowledgement)) {
            goto cleanup;
        }
    }
    if (printf("rtt_recorded=yes\nack_bytes=%llu\n",
            (unsigned long long)(NETWORK_ACK_BYTES * request_count)) < 0) {
        goto cleanup;
    }
    operation_status = 0;
cleanup:
    erase_secret_bytes(decapsulation_key, sizeof(decapsulation_key));
    if (rtt_file != NULL) {
        (void)fclose(rtt_file);
    }
    if (ack_file != NULL) {
        (void)fclose(ack_file);
    }
    if (socket_fd >= 0) {
        (void)close(socket_fd);
    }
    return operation_status;
}
