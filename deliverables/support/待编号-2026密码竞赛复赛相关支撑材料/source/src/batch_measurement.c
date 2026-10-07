#include "batch_measurement.h"

int run_batch_decapsulations(size_t call_count,
    const uint8_t *const ciphertexts[MAXIMUM_BATCH_CALLS],
    const uint8_t *decapsulation_key,
    uint8_t shared_secrets[MAXIMUM_BATCH_CALLS][MLKEM_SHARED_SECRET_BYTES],
    int call_statuses[MAXIMUM_BATCH_CALLS])
{
    if (call_count == 0 || call_count > MAXIMUM_BATCH_CALLS || ciphertexts == NULL ||
        decapsulation_key == NULL || shared_secrets == NULL || call_statuses == NULL) {
        return MLKEM_ERROR_ARGUMENT;
    }
    for (size_t call_index = 0; call_index < call_count; ++call_index) {
        if (ciphertexts[call_index] == NULL) {
            return MLKEM_ERROR_ARGUMENT;
        }
    }
    for (size_t call_index = 0; call_index < call_count; ++call_index) {
        call_statuses[call_index] = mlkem_decapsulate(shared_secrets[call_index],
            MLKEM_SHARED_SECRET_BYTES,
            ciphertexts[call_index],
            MLKEM_CIPHERTEXT_BYTES,
            decapsulation_key,
            MLKEM_DECAPSULATION_KEY_BYTES);
    }
    return 0;
}
