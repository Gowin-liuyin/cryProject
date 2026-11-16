/* 产物判定用最小驱动：只调用一次 keygen/encaps/decaps，不作计时。
 * randombytes 走本地 /dev/urandom，仅让链接闭合；不进入证据计时口径。 */

#define _POSIX_C_SOURCE 200809L

#include "api.h"

#include <fcntl.h>
#include <stddef.h>
#include <stdint.h>
#include <unistd.h>

void platform_m2_randombytes(uint8_t *output, size_t output_byte_count)
{
    int random_descriptor = open("/dev/urandom", O_RDONLY);
    if (random_descriptor < 0) {
        _exit(120);
    }
    size_t completed_byte_count = 0u;
    while (completed_byte_count < output_byte_count) {
        ssize_t received_byte_count =
            read(random_descriptor, output + completed_byte_count, output_byte_count - completed_byte_count);
        if (received_byte_count <= 0) {
            (void)close(random_descriptor);
            _exit(120);
        }
        completed_byte_count += (size_t)received_byte_count;
    }
    (void)close(random_descriptor);
}

int main(void)
{
    uint8_t public_key[pqcrystals_kyber768_PUBLICKEYBYTES];
    uint8_t secret_key[pqcrystals_kyber768_SECRETKEYBYTES];
    uint8_t ciphertext[pqcrystals_kyber768_CIPHERTEXTBYTES];
    uint8_t shared_secret[pqcrystals_kyber768_BYTES];
    uint8_t decapsulated_secret[pqcrystals_kyber768_BYTES];
    if (pqcrystals_kyber768_ref_keypair(public_key, secret_key) != 0) {
        return 1;
    }
    if (pqcrystals_kyber768_ref_enc(ciphertext, shared_secret, public_key) != 0) {
        return 1;
    }
    if (pqcrystals_kyber768_ref_dec(decapsulated_secret, ciphertext, secret_key) != 0) {
        return 1;
    }
    return 0;
}
