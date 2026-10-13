#include <stdint.h>
#include <stdio.h>
#include <string.h>

static const uint32_t sha256_round_constants[64] = {0x428a2f98u,
    0x71374491u,
    0xb5c0fbcfu,
    0xe9b5dba5u,
    0x3956c25bu,
    0x59f111f1u,
    0x923f82a4u,
    0xab1c5ed5u,
    0xd807aa98u,
    0x12835b01u,
    0x243185beu,
    0x550c7dc3u,
    0x72be5d74u,
    0x80deb1feu,
    0x9bdc06a7u,
    0xc19bf174u,
    0xe49b69c1u,
    0xefbe4786u,
    0x0fc19dc6u,
    0x240ca1ccu,
    0x2de92c6fu,
    0x4a7484aau,
    0x5cb0a9dcu,
    0x76f988dau,
    0x983e5152u,
    0xa831c66du,
    0xb00327c8u,
    0xbf597fc7u,
    0xc6e00bf3u,
    0xd5a79147u,
    0x06ca6351u,
    0x14292967u,
    0x27b70a85u,
    0x2e1b2138u,
    0x4d2c6dfcu,
    0x53380d13u,
    0x650a7354u,
    0x766a0abbu,
    0x81c2c92eu,
    0x92722c85u,
    0xa2bfe8a1u,
    0xa81a664bu,
    0xc24b8b70u,
    0xc76c51a3u,
    0xd192e819u,
    0xd6990624u,
    0xf40e3585u,
    0x106aa070u,
    0x19a4c116u,
    0x1e376c08u,
    0x2748774cu,
    0x34b0bcb5u,
    0x391c0cb3u,
    0x4ed8aa4au,
    0x5b9cca4fu,
    0x682e6ff3u,
    0x748f82eeu,
    0x78a5636fu,
    0x84c87814u,
    0x8cc70208u,
    0x90befffau,
    0xa4506cebu,
    0xbef9a3f7u,
    0xc67178f2u};

static uint32_t rotate_right(uint32_t value, unsigned bits)
{
    return (value >> bits) | (value << (32u - bits));
}

static void sha256_compress(uint32_t state[8], const uint8_t block[64])
{
    uint32_t words[64];
    uint32_t letter_a;
    uint32_t letter_b;
    uint32_t letter_c;
    uint32_t letter_d;
    uint32_t letter_e;
    uint32_t letter_f;
    uint32_t letter_g;
    uint32_t letter_h;
    for (unsigned word_index = 0; word_index < 16u; ++word_index) {
        words[word_index] = ((uint32_t)block[word_index * 4u] << 24) |
            ((uint32_t)block[word_index * 4u + 1u] << 16) |
            ((uint32_t)block[word_index * 4u + 2u] << 8) | (uint32_t)block[word_index * 4u + 3u];
    }
    for (unsigned word_index = 16; word_index < 64u; ++word_index) {
        uint32_t small_sigma0 = rotate_right(words[word_index - 15u], 7u) ^
            rotate_right(words[word_index - 15u], 18u) ^ (words[word_index - 15u] >> 3u);
        uint32_t small_sigma1 = rotate_right(words[word_index - 2u], 17u) ^
            rotate_right(words[word_index - 2u], 19u) ^ (words[word_index - 2u] >> 10u);
        words[word_index] =
            words[word_index - 16u] + small_sigma0 + words[word_index - 7u] + small_sigma1;
    }
    letter_a = state[0];
    letter_b = state[1];
    letter_c = state[2];
    letter_d = state[3];
    letter_e = state[4];
    letter_f = state[5];
    letter_g = state[6];
    letter_h = state[7];
    for (unsigned round_index = 0; round_index < 64u; ++round_index) {
        uint32_t capital_sigma1 =
            rotate_right(letter_e, 6u) ^ rotate_right(letter_e, 11u) ^ rotate_right(letter_e, 25u);
        uint32_t choice = (letter_e & letter_f) ^ ((~letter_e) & letter_g);
        uint32_t temporary1 = letter_h + capital_sigma1 + choice +
            sha256_round_constants[round_index] + words[round_index];
        uint32_t capital_sigma0 =
            rotate_right(letter_a, 2u) ^ rotate_right(letter_a, 13u) ^ rotate_right(letter_a, 22u);
        uint32_t majority = (letter_a & letter_b) ^ (letter_a & letter_c) ^ (letter_b & letter_c);
        uint32_t temporary2 = capital_sigma0 + majority;
        letter_h = letter_g;
        letter_g = letter_f;
        letter_f = letter_e;
        letter_e = letter_d + temporary1;
        letter_d = letter_c;
        letter_c = letter_b;
        letter_b = letter_a;
        letter_a = temporary1 + temporary2;
    }
    state[0] += letter_a;
    state[1] += letter_b;
    state[2] += letter_c;
    state[3] += letter_d;
    state[4] += letter_e;
    state[5] += letter_f;
    state[6] += letter_g;
    state[7] += letter_h;
}

static void sha256_store(const uint32_t state[8], char hex_out[65])
{
    unsigned char digest[32];
    for (unsigned word_index = 0; word_index < 8u; ++word_index) {
        digest[word_index * 4u] = (unsigned char)(state[word_index] >> 24);
        digest[word_index * 4u + 1u] = (unsigned char)(state[word_index] >> 16);
        digest[word_index * 4u + 2u] = (unsigned char)(state[word_index] >> 8);
        digest[word_index * 4u + 3u] = (unsigned char)state[word_index];
    }
    for (unsigned byte_index = 0; byte_index < 32u; ++byte_index) {
        (void)snprintf(hex_out + (size_t)byte_index * 2u, 3u, "%02x", digest[byte_index]);
    }
}

int sha256_file(const char *path, char hex_out[65])
{
    static const uint8_t padding[64] = {0x80u};
    FILE *file = fopen(path, "rb");
    uint32_t state[8] = {0x6a09e667u,
        0xbb67ae85u,
        0x3c6ef372u,
        0xa54ff53au,
        0x510e527fu,
        0x9b05688cu,
        0x1f83d9abu,
        0x5be0cd19u};
    uint8_t block[64];
    size_t filled = 0u;
    uint64_t message_bits = 0u;
    if (file == NULL) {
        return 1;
    }
    for (;;) {
        size_t read_count = fread(block + filled, 1u, 64u - filled, file);
        filled += read_count;
        message_bits += (uint64_t)read_count * 8u;
        if (read_count == 0u && ferror(file)) {
            (void)fclose(file);
            return 1;
        }
        if (filled < 64u) {
            break;
        }
        sha256_compress(state, block);
        filled = 0u;
    }
    if (ferror(file) != 0) {
        (void)fclose(file);
        return 1;
    }
    (void)fclose(file);
    if (filled > 55u) {
        memcpy(block + filled, padding, 64u - filled);
        sha256_compress(state, block);
        memset(block, 0, 64u);
    } else {
        memcpy(block + filled, padding, 64u - filled);
    }
    for (unsigned byte_index = 0; byte_index < 8u; ++byte_index) {
        block[63u - byte_index] = (uint8_t)(message_bits >> (8u * byte_index));
    }
    sha256_compress(state, block);
    sha256_store(state, hex_out);
    return 0;
}

int sha256_self_check(void)
{
    const char *known_abc = "ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad";
    const uint8_t abc_bytes[3] = {'a', 'b', 'c'};
    uint32_t state[8] = {0x6a09e667u,
        0xbb67ae85u,
        0x3c6ef372u,
        0xa54ff53au,
        0x510e527fu,
        0x9b05688cu,
        0x1f83d9abu,
        0x5be0cd19u};
    uint8_t block[64] = {0};
    uint64_t message_bits = 24u;
    char actual[65];
    memcpy(block, abc_bytes, 3u);
    block[3] = 0x80u;
    for (unsigned byte_index = 0; byte_index < 8u; ++byte_index) {
        block[63u - byte_index] = (uint8_t)(message_bits >> (8u * byte_index));
    }
    sha256_compress(state, block);
    sha256_store(state, actual);
    return strcmp(actual, known_abc) == 0 ? 0 : 1;
}
