#ifndef BASELINE_BATCH_MEASUREMENT_H
#define BASELINE_BATCH_MEASUREMENT_H

#include "mlkem.h"

#define MAXIMUM_BATCH_CALLS 16u

/* 每个结果单独保留，状态检查和消费由计时结束后的调用方完成。 */
int run_batch_decapsulations(size_t call_count,
    const uint8_t *const ciphertexts[MAXIMUM_BATCH_CALLS],
    const uint8_t *decapsulation_key,
    uint8_t shared_secrets[MAXIMUM_BATCH_CALLS][MLKEM_SHARED_SECRET_BYTES],
    int call_statuses[MAXIMUM_BATCH_CALLS]);

#endif
