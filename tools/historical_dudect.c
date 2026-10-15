#define _POSIX_C_SOURCE 200809L

#include "inputs.h"
#include "mlkem.h"

#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

/*
 * 上游 dudect 要求这两个函数名。预算在跑之前固定：每批 10000 次，
 * 最多 21 批（第 1 批被 dudect 丢掉），亲和与锁频由外部规程规定。
 * 阈值仍是上游的 t>10，不在看到结果后改。
 */
#define DUDECT_IMPLEMENTATION
#include "dudect.h"

#define HISTORICAL_DUDECT_SEED 31337ull
#define HISTORICAL_DUDECT_MEASUREMENTS 10000u
#define HISTORICAL_DUDECT_MAX_BATCHES 21u

static uint8_t encapsulation_key[MLKEM_ENCAPSULATION_KEY_BYTES];
static uint8_t decapsulation_key[MLKEM_DECAPSULATION_KEY_BYTES];
static int key_is_ready;

uint8_t do_one_computation(uint8_t *data)
{
    uint8_t shared_secret[MLKEM_SHARED_SECRET_BYTES];
    volatile uint8_t consumed_byte;
    int operation_status;

    operation_status = mlkem_decapsulate(shared_secret,
        sizeof(shared_secret),
        data,
        MLKEM_CIPHERTEXT_BYTES,
        decapsulation_key,
        sizeof(decapsulation_key));
    consumed_byte = shared_secret[0];
    erase_secret_bytes(shared_secret, sizeof(shared_secret));
    if (operation_status != 0) {
        return 0;
    }
    return consumed_byte;
}

void prepare_inputs(dudect_config_t *config, uint8_t *input_data, uint8_t *classes)
{
    size_t measurement_index;
    static uint64_t actual_seed = HISTORICAL_DUDECT_SEED;

    if (key_is_ready == 0) {
        const char *environment_seed = getenv("HISTORICAL_DUDECT_SEED");
        if (environment_seed != NULL && *environment_seed != '\0') {
            actual_seed = strtoull(environment_seed, NULL, 0);
        }
        if (generate_test_key_pair(actual_seed,
                encapsulation_key,
                decapsulation_key) != 0) {
            fputs("historical dudect key generation failed\n", stderr);
            exit(1);
        }
        key_is_ready = 1;
    }
    for (measurement_index = 0; measurement_index < config->number_measurements;
         measurement_index++) {
        enum input_category category;
        uint8_t *ciphertext;

        classes[measurement_index] = randombit();
        if (classes[measurement_index] == 0) {
            category = INPUT_MESSAGE_ZERO;
        } else {
            category = INPUT_MESSAGE_ONES;
        }
        ciphertext = input_data + measurement_index * config->chunk_size;
        if (generate_test_ciphertext(category,
                actual_seed,
                (uint64_t)measurement_index,
                encapsulation_key,
                ciphertext) != 0) {
            fputs("historical dudect ciphertext generation failed\n", stderr);
            exit(1);
        }
    }
}

int main(void)
{
    dudect_config_t config;
    dudect_ctx_t context;
    dudect_state_t state;
    unsigned batch_index;

    config.chunk_size = MLKEM_CIPHERTEXT_BYTES;
    config.number_measurements = HISTORICAL_DUDECT_MEASUREMENTS;
    if (dudect_init(&context, &config) != 0) {
        return 1;
    }
    state = DUDECT_NO_LEAKAGE_EVIDENCE_YET;
    batch_index = 0;
    while (batch_index < HISTORICAL_DUDECT_MAX_BATCHES &&
           state == DUDECT_NO_LEAKAGE_EVIDENCE_YET) {
        state = dudect_main(&context);
        batch_index++;
    }
    printf("stopped_after_batches=%u state=%d\n", batch_index, (int)state);
    dudect_free(&context);
    erase_secret_bytes(decapsulation_key, sizeof(decapsulation_key));
    return 0;
}
