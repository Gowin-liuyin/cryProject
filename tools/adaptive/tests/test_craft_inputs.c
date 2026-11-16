/* T6.2 单测：M4 失配位置构造器 32 个位置的构造正确性（逐位置断言首个差异字节位置）。 */

#include <stdint.h>
#include <stdio.h>
#include <string.h>

#define CRAFT_INPUT_BYTES 32u

int craft_input_pair(unsigned position_bytes,
    uint8_t secret_input[CRAFT_INPUT_BYTES],
    uint8_t candidate_input[CRAFT_INPUT_BYTES]);
unsigned craft_first_difference(const uint8_t secret_input[CRAFT_INPUT_BYTES],
    const uint8_t candidate_input[CRAFT_INPUT_BYTES]);

int main(void)
{
    for (unsigned position_bytes = 0u; position_bytes < CRAFT_INPUT_BYTES; ++position_bytes) {
        uint8_t secret_input[CRAFT_INPUT_BYTES];
        uint8_t candidate_input[CRAFT_INPUT_BYTES];
        memset(secret_input, 0, sizeof(secret_input));
        memset(candidate_input, 0, sizeof(candidate_input));
        if (craft_input_pair(position_bytes, secret_input, candidate_input) != 0) {
            fprintf(stderr, "error: craft_input_pair failed at position %u\n", position_bytes);
            return 1;
        }
        if (craft_first_difference(secret_input, candidate_input) != position_bytes) {
            fprintf(stderr, "error: first difference is not at position %u\n", position_bytes);
            return 1;
        }
        for (unsigned byte_index = 0u; byte_index < CRAFT_INPUT_BYTES; ++byte_index) {
            if (byte_index == position_bytes) {
                if (secret_input[byte_index] == candidate_input[byte_index]) {
                    fprintf(stderr,
                        "error: mismatch byte is equal at position %u\n",
                        position_bytes);
                    return 1;
                }
            } else if (secret_input[byte_index] != candidate_input[byte_index]) {
                fprintf(stderr, "error: unexpected extra difference at position %u\n", byte_index);
                return 1;
            }
        }
    }
    uint8_t secret_input[CRAFT_INPUT_BYTES];
    uint8_t candidate_input[CRAFT_INPUT_BYTES];
    if (craft_input_pair(CRAFT_INPUT_BYTES, secret_input, candidate_input) != 1 ||
        craft_input_pair(1000u, secret_input, candidate_input) != 1 ||
        craft_input_pair(0u, NULL, candidate_input) != 1 ||
        craft_input_pair(0u, secret_input, NULL) != 1) {
        fprintf(stderr, "error: invalid position/pointer was accepted\n");
        return 1;
    }
    printf("craft_inputs: 32 positions reconstructed, invalid inputs rejected\n");
    return 0;
}
