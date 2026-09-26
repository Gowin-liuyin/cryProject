#include "mlkem.h"
#include <errno.h>
#include <fcntl.h>
#include <stdio.h>
#include <sys/resource.h>
#include <unistd.h>

int main(void)
{
    struct rlimit original_limit, limited_resources;
    int open_descriptors[64];
    size_t descriptor_count = 0;
    int generated_status, encapsulated_status, saved_error;
    uint8_t encapsulation_key[MLKEM_ENCAPSULATION_KEY_BYTES] = {0};
    uint8_t decapsulation_key[MLKEM_DECAPSULATION_KEY_BYTES];
    uint8_t ciphertext[MLKEM_CIPHERTEXT_BYTES];
    uint8_t shared_secret[MLKEM_SHARED_SECRET_BYTES];
    if (getrlimit(RLIMIT_NOFILE, &original_limit) != 0) return 1;
    limited_resources = original_limit;
    if (limited_resources.rlim_cur > 64u) limited_resources.rlim_cur = 64u;
    if (setrlimit(RLIMIT_NOFILE, &limited_resources) != 0) return 1;
    while (descriptor_count < 64u) {
        int opened_descriptor = open("/dev/null", O_RDONLY);
        if (opened_descriptor < 0) break;
        open_descriptors[descriptor_count++] = opened_descriptor;
    }
    saved_error = errno;
    generated_status = mlkem_generate_key_pair(encapsulation_key, sizeof(encapsulation_key), decapsulation_key, sizeof(decapsulation_key));
    encapsulated_status = mlkem_encapsulate(ciphertext, sizeof(ciphertext), shared_secret, sizeof(shared_secret), encapsulation_key, sizeof(encapsulation_key));
    for (size_t descriptor_index = 0; descriptor_index < descriptor_count; ++descriptor_index)
        if (close(open_descriptors[descriptor_index]) != 0) return 1;
    if (setrlimit(RLIMIT_NOFILE, &original_limit) != 0 || saved_error != EMFILE ||
        generated_status != MLKEM_ERROR_RANDOM || encapsulated_status != MLKEM_ERROR_RANDOM) return 1;
    if (mlkem_self_test() != 0) return 1;
    puts("system RNG open failure propagates; normal operation recovers");
    return 0;
}
