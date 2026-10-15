#include "collector_inputs.h"

#include "inputs.h"
#include "platform_m2.h"

#include <string.h>

static const char *const m2_collector_class_names[M2_COLLECTOR_CLASS_COUNT] = {"message-zero",
    "message-ones",
    "malformed-zero-tail",
    "malformed-ff-tail"};

const char *m2_collector_class_name(enum m2_collector_class class_index)
{
    if ((unsigned)class_index >= M2_COLLECTOR_CLASS_COUNT) {
        return "unknown";
    }
    return m2_collector_class_names[class_index];
}

int m2_collector_parse_class(const char *class_text, enum m2_collector_class *class_index)
{
    if (class_text == NULL || class_index == NULL) {
        return 1;
    }
    for (unsigned index = 0; index < M2_COLLECTOR_CLASS_COUNT; ++index) {
        if (strcmp(class_text, m2_collector_class_names[index]) == 0) {
            *class_index = (enum m2_collector_class)index;
            return 0;
        }
    }
    return 1;
}

int m2_collector_class_is_malformed(enum m2_collector_class class_index)
{
    return class_index == M2_COLLECTOR_MALFORMED_ZERO_TAIL ||
           class_index == M2_COLLECTOR_MALFORMED_FF_TAIL;
}

int m2_collector_build_ciphertext(enum m2_collector_class class_index,
    const uint8_t *encapsulation_key,
    uint8_t *ciphertext,
    uint8_t *expected_secret)
{
    uint8_t chosen_message[MLKEM_SHARED_SECRET_BYTES];
    uint8_t accept_secret[MLKEM_SHARED_SECRET_BYTES];
    int is_malformed;
    int operation_status;
    if ((unsigned)class_index >= M2_COLLECTOR_CLASS_COUNT || encapsulation_key == NULL ||
        ciphertext == NULL) {
        return MLKEM_ERROR_ARGUMENT;
    }
    is_malformed = m2_collector_class_is_malformed(class_index);
    if (is_malformed ? expected_secret != NULL : expected_secret == NULL) {
        return MLKEM_ERROR_ARGUMENT;
    }
    if (is_malformed) {
        /* 基准是 message-zero 密文；只把尾部固定字节数改写为常量模式，长度保持合法。 */
        memset(chosen_message, 0, sizeof(chosen_message));
    } else {
        memset(chosen_message,
            class_index == M2_COLLECTOR_MESSAGE_ZERO ? 0x00 : 0xFF,
            sizeof(chosen_message));
    }
    operation_status =
        platform_m2_test_message(ciphertext, accept_secret, encapsulation_key, chosen_message);
    if (operation_status == 0 && is_malformed) {
        memset(ciphertext + MLKEM_CIPHERTEXT_BYTES - M2_COLLECTOR_TAIL_BYTES,
            class_index == M2_COLLECTOR_MALFORMED_ZERO_TAIL ? 0x00 : 0xFF,
            M2_COLLECTOR_TAIL_BYTES);
    }
    if (operation_status == 0 && expected_secret != NULL) {
        memcpy(expected_secret, accept_secret, MLKEM_SHARED_SECRET_BYTES);
    }
    erase_secret_bytes(chosen_message, sizeof(chosen_message));
    erase_secret_bytes(accept_secret, sizeof(accept_secret));
    return operation_status;
}

static uint64_t m2_collector_draw_order_value(uint64_t test_seed,
    uint64_t *draw_index,
    uint64_t upper_bound)
{
    uint64_t random_value;
    uint64_t rejection_threshold = (UINT64_C(0) - upper_bound) % upper_bound;
    do {
        uint8_t random_bytes[8];
        expand_test_seed(random_bytes, sizeof(random_bytes), test_seed, (*draw_index)++, 4);
        random_value = 0;
        for (unsigned byte_index = 0; byte_index < 8U; ++byte_index) {
            random_value |= (uint64_t)random_bytes[byte_index] << (8U * byte_index);
        }
    } while (random_value < rejection_threshold);
    return random_value % upper_bound;
}

int m2_collector_build_schedule(const enum m2_collector_class *class_list,
    size_t class_count,
    uint64_t samples_per_class,
    uint64_t test_seed,
    enum m2_collector_class *row_classes)
{
    uint64_t draw_index = 0;
    if (class_list == NULL || row_classes == NULL || class_count == 0 ||
        class_count > M2_COLLECTOR_MAXIMUM_CLASSES || samples_per_class == 0 ||
        samples_per_class > M2_COLLECTOR_MAXIMUM_SAMPLES_PER_CLASS) {
        return 1;
    }
    for (uint64_t sample_index = 0; sample_index < samples_per_class; ++sample_index) {
        for (size_t class_slot = 0; class_slot < class_count; ++class_slot) {
            row_classes[(size_t)(sample_index * (uint64_t)class_count) + class_slot] =
                class_list[class_slot];
        }
    }
    uint64_t row_count = samples_per_class * (uint64_t)class_count;
    for (uint64_t remaining_count = row_count; remaining_count > 1U; --remaining_count) {
        size_t selected_index =
            (size_t)m2_collector_draw_order_value(test_seed, &draw_index, remaining_count);
        enum m2_collector_class selected_class = row_classes[selected_index];
        row_classes[selected_index] = row_classes[(size_t)(remaining_count - 1U)];
        row_classes[(size_t)(remaining_count - 1U)] = selected_class;
    }
    return 0;
}

int m2_collector_digest_ciphertexts(const uint8_t *ciphertexts,
    size_t sample_count,
    uint8_t digest[32])
{
    if (ciphertexts == NULL || digest == NULL || sample_count == 0 ||
        sample_count >
            (size_t)M2_COLLECTOR_MAXIMUM_SAMPLES_PER_CLASS * (size_t)M2_COLLECTOR_MAXIMUM_CLASSES) {
        return 1;
    }
    platform_m2_sha3_256(digest, ciphertexts, sample_count * (size_t)MLKEM_CIPHERTEXT_BYTES);
    return 0;
}
