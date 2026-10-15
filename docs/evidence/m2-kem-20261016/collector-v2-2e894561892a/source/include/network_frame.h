#ifndef BASELINE_NETWORK_FRAME_H
#define BASELINE_NETWORK_FRAME_H

#include <stddef.h>
#include <stdint.h>

#define NETWORK_REQUEST_BYTES 1104u
#define NETWORK_ACK_BYTES 32u

int network_build_request(uint8_t *request,
    size_t request_capacity,
    uint64_t request_index,
    const uint8_t *ciphertext,
    size_t ciphertext_bytes);
int network_parse_request(const uint8_t *request,
    size_t request_bytes,
    uint64_t *request_index,
    uint8_t *ciphertext,
    size_t ciphertext_capacity);
int network_build_acknowledgement(uint8_t *acknowledgement, size_t acknowledgement_capacity);
int network_acknowledgement_is_fixed(const uint8_t *bytes, size_t byte_count);

#endif
