/* R05 T15 补测：M2（历史 Kyber768 ref）完整解封装 + 秘密标记的 Memcheck 探针。
 *
 * 目的：给出“秘密标记下，完整解封装路径（含哈希 G/H/J 与重加密）有没有
 *       被 Memcheck 报出条件跳转/条件移动依赖未初始化值”的产物级证据。
 *
 * 做法：不重编密码内核，只在探针里对**已被测**的 measure ELF 用到的同一份
 *       vendor 源码做秘密标记。zones 参数把 sk 的 1152 字节 PKE 私钥分成若干段，
 *       每段单独标记（标记是累积的，因此总覆盖率以最后一段为准）。
 *       分段的原因：整段标记在 Valgrind 下会让 Keccak 置换也变成“未初始化”，
 *       运行时间放大到不可接受；分段后每段都跑到完整解封装，覆盖率仍是全量。
 *
 * 注意：本探针不修改任何既有证据；产物全部落在本轮新根内。
 */
#include "kem.h"
#include "params.h"

#include <errno.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <valgrind/memcheck.h>

static int read_urandom(uint8_t *output_bytes, size_t byte_count)
{
    FILE *random_stream = fopen("/dev/urandom", "rb");
    if (random_stream == NULL) {
        fprintf(stderr, "fopen /dev/urandom failed: %s\n", strerror(errno));
        return -1;
    }
    size_t read_bytes = fread(output_bytes, 1, byte_count, random_stream);
    fclose(random_stream);
    if (read_bytes != byte_count) {
        fprintf(stderr, "short read from /dev/urandom\n");
        return -1;
    }
    return 0;
}

int randombytes(uint8_t *output_bytes, size_t byte_count)
{
    return read_urandom(output_bytes, byte_count) == 0 ? 0 : -1;
}

/* 只标记 sk 中 [mark_start, mark_end) 这段 PKE 私钥为秘密；秘密标记是累积的。 */
static void mark_secret_range(uint8_t *secret_key, size_t mark_start, size_t mark_end)
{
    if (mark_end > mark_start) {
        VALGRIND_MAKE_MEM_UNDEFINED(secret_key + mark_start, mark_end - mark_start);
    }
}

int main(int argument_count, char **argument_values)
{
    static uint8_t public_key[KYBER_PUBLICKEYBYTES];
    static uint8_t secret_key[KYBER_SECRETKEYBYTES];
    static uint8_t ciphertext[KYBER_CIPHERTEXTBYTES];
    static uint8_t shared_secret_send[KYBER_SSBYTES];
    static uint8_t shared_secret_receive[KYBER_SSBYTES];
    uint8_t accumulator = 0;
    if (argument_count != 3) {
        fprintf(stderr, "usage: %s ZONE_COUNT ZONE_INDEX\n", argument_values[0]);
        return 2;
    }
    size_t zone_count = (size_t)strtoul(argument_values[1], NULL, 10);
    size_t zone_index = (size_t)strtoul(argument_values[2], NULL, 10);
    if (zone_count == 0 || zone_index >= zone_count) {
        fprintf(stderr, "invalid zone arguments\n");
        return 2;
    }
    if (crypto_kem_keypair(public_key, secret_key) != 0) {
        fprintf(stderr, "keypair failed\n");
        return 3;
    }
    if (crypto_kem_enc(ciphertext, shared_secret_send, public_key) != 0) {
        fprintf(stderr, "encapsulation failed\n");
        return 4;
    }
    /* 标记 zone_index 之前的所有分区：最后一次调用覆盖整段 PKE 私钥。 */
    for (size_t zone = 0; zone <= zone_index; zone++) {
        uint64_t mark_start = ((uint64_t)KYBER_INDCPA_SECRETKEYBYTES * zone) / zone_count;
        uint64_t mark_end = ((uint64_t)KYBER_INDCPA_SECRETKEYBYTES * (zone + 1)) / zone_count;
        mark_secret_range(secret_key, (size_t)mark_start, (size_t)mark_end);
    }
    printf("zone_count=%zu zone_index=%zu secret_marked_bytes=%llu pke_secret_bytes=%d\n",
           zone_count, zone_index,
           (unsigned long long)((uint64_t)KYBER_INDCPA_SECRETKEYBYTES * (zone_index + 1) / zone_count),
           KYBER_INDCPA_SECRETKEYBYTES);
    fflush(stdout);
    if (crypto_kem_dec(shared_secret_receive, ciphertext, secret_key) != 0) {
        fprintf(stderr, "decapsulation failed\n");
        return 5;
    }
    /* 共享秘密是解封装的**输出**，按 ctgrind 惯例在消费前显式 declassify，
     * 否则 Memcheck 会在 printf/puts 内部报一堆与密码实现无关的上下文。 */
    VALGRIND_MAKE_MEM_DEFINED(shared_secret_receive, KYBER_SSBYTES);
    for (size_t secret_index = 0; secret_index < KYBER_SSBYTES; secret_index++) {
        accumulator = (uint8_t)(accumulator ^ shared_secret_receive[secret_index]);
    }
    if (accumulator == 0xa5U) {
        puts("consume-marker");
    }
    return 0;
}
