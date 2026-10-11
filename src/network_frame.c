#include "network_frame.h"

#include <string.h>

static const uint8_t request_magic[8] = {'A', '1', '1', '3', 'R', 'Q', 'S', 'T'};
static const uint8_t acknowledgement_prefix[8] = {'A', '1', '1', '3', 'A', 'C', 'K', '\0'};

int network_build_request(uint8_t *request,
    size_t request_capacity,
    uint64_t request_index,
    const uint8_t *ciphertext,
    size_t ciphertext_bytes)
{
    if (request == NULL || ciphertext == NULL || request_capacity < NETWORK_REQUEST_BYTES ||
        ciphertext_bytes != 1088u) {
        return 1;
    }
    memcpy(request, request_magic, sizeof(request_magic));
    for (size_t byte_index = 0; byte_index < 8u; ++byte_index) {
        request[8u + byte_index] = (uint8_t)(request_index >> (8u * byte_index));
    }
    memcpy(request + 16u, ciphertext, 1088u);
    return 0;
}

int network_parse_request(const uint8_t *request,
    size_t request_bytes,
    uint64_t *request_index,
    uint8_t *ciphertext,
    size_t ciphertext_capacity)
{
    uint64_t parsed_index = 0u;
    if (request == NULL || request_index == NULL || ciphertext == NULL ||
        request_bytes != NETWORK_REQUEST_BYTES || ciphertext_capacity < 1088u ||
        memcmp(request, request_magic, sizeof(request_magic)) != 0) {
        return 1;
    }
    for (size_t byte_index = 0; byte_index < 8u; ++byte_index) {
        parsed_index |= (uint64_t)request[8u + byte_index] << (8u * byte_index);
    }
    *request_index = parsed_index;
    memcpy(ciphertext, request + 16u, 1088u);
    return 0;
}

int network_build_acknowledgement(uint8_t *acknowledgement, size_t acknowledgement_capacity)
{
    if (acknowledgement == NULL || acknowledgement_capacity < NETWORK_ACK_BYTES) {
        return 1;
    }
    memset(acknowledgement, 0, NETWORK_ACK_BYTES);
    memcpy(acknowledgement, acknowledgement_prefix, sizeof(acknowledgement_prefix));
    return 0;
}

int network_acknowledgement_is_fixed(const uint8_t *bytes, size_t byte_count)
{
    uint8_t expected[NETWORK_ACK_BYTES];
    if (bytes == NULL || byte_count != NETWORK_ACK_BYTES ||
        network_build_acknowledgement(expected, sizeof(expected)) != 0) {
        return 0;
    }
    return memcmp(bytes, expected, NETWORK_ACK_BYTES) == 0;
}
