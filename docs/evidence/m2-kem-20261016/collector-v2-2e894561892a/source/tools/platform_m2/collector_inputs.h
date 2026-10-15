#ifndef PLATFORM_M2_COLLECTOR_INPUTS_H
#define PLATFORM_M2_COLLECTOR_INPUTS_H

#include "mlkem.h"

#include <stddef.h>
#include <stdint.h>

/* collector-v2 的四个类：前两个是主类对，后两个是"格式破坏密文"对照类对。 */
#define M2_COLLECTOR_CLASS_COUNT 4U
#define M2_COLLECTOR_MAXIMUM_CLASSES 4U
#define M2_COLLECTOR_MAXIMUM_SAMPLES_PER_CLASS 20000U
/* 对照类只改写密文尾部这么多字节，总长度仍是合法 MLKEM_CIPHERTEXT_BYTES。 */
#define M2_COLLECTOR_TAIL_BYTES 32U

enum m2_collector_class {
    M2_COLLECTOR_MESSAGE_ZERO,
    M2_COLLECTOR_MESSAGE_ONES,
    M2_COLLECTOR_MALFORMED_ZERO_TAIL,
    M2_COLLECTOR_MALFORMED_FF_TAIL
};

const char *m2_collector_class_name(enum m2_collector_class class_index);
int m2_collector_parse_class(const char *class_text, enum m2_collector_class *class_index);
int m2_collector_class_is_malformed(enum m2_collector_class class_index);

/* 每个类只有一份确定性密文；固定公开公钥下可重复构造。
   主类对额外返回"接受路径"应有的共享秘密（expected_secret 不得为 NULL）；
   对照类对没有接受秘密，expected_secret 必须为 NULL，返回隐式拒绝密文。 */
int m2_collector_build_ciphertext(enum m2_collector_class class_index,
    const uint8_t *encapsulation_key,
    uint8_t *ciphertext,
    uint8_t *expected_secret);

/* 行序：各类先按调用方给出的列表顺序铺满，再做 Fisher–Yates；
   随机流与既有 measure 协议一致（SHAKE256 域分离 tag=4）。
   同一 (seed, 类列表, 每类数量) 逐行可重放；行数 = class_count * samples_per_class。 */
int m2_collector_build_schedule(const enum m2_collector_class *class_list,
    size_t class_count,
    uint64_t samples_per_class,
    uint64_t test_seed,
    enum m2_collector_class *row_classes);

/* 输入序列摘要（SHA3-256，按行序），用于跨版本/跨运行核对确实是同一批输入。 */
int m2_collector_digest_ciphertexts(const uint8_t *ciphertexts,
    size_t sample_count,
    uint8_t digest[32]);

#endif
