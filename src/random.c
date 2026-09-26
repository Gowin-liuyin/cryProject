#include "mlkem.h"

#include <errno.h>
#include <fcntl.h>
#include <unistd.h>

void erase_secret_bytes(void *secret, size_t secret_byte_count)
{
    volatile uint8_t *secret_bytes = secret;
    while (secret_byte_count != 0u) {
        *secret_bytes++ = 0;
        --secret_byte_count;
    }
}

int system_random_bytes(uint8_t *output, size_t output_byte_count)
{
    size_t completed_byte_count = 0;
    int random_descriptor;
    if (output == NULL) {
        return MLKEM_ERROR_ARGUMENT;
    }
    random_descriptor = open("/dev/urandom", O_RDONLY);
    if (random_descriptor < 0) {
        return MLKEM_ERROR_RANDOM;
    }
    while (completed_byte_count < output_byte_count) {
        size_t remaining_byte_count = output_byte_count - completed_byte_count;
        ssize_t received_byte_count = read(random_descriptor,
            output + completed_byte_count,
            remaining_byte_count > 256u ? 256u : remaining_byte_count);
        if (received_byte_count < 0 && errno == EINTR) {
            continue;
        }
        if (received_byte_count <= 0) {
            (void)close(random_descriptor);
            erase_secret_bytes(output, output_byte_count);
            return MLKEM_ERROR_RANDOM;
        }
        completed_byte_count += (size_t)received_byte_count;
    }
    if (close(random_descriptor) != 0) {
        erase_secret_bytes(output, output_byte_count);
        return MLKEM_ERROR_RANDOM;
    }
    return 0;
}
