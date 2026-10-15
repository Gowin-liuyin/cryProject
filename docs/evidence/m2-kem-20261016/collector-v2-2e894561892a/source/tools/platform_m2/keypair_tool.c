/* 生成固定的公开测试密钥对夹具：同一 --key-seed 在任何变体下都必须得到逐字节相同的 pk/sk。 */
#define _POSIX_C_SOURCE 200809L

#include "fips202.h"
#include "mlkem.h"
#include "platform_m2.h"

#include <stdio.h>
#include <string.h>

static int write_new_file(const char *path, const uint8_t *bytes, size_t byte_count)
{
    FILE *output_file;
    int operation_status = 0;
    if (path == NULL || bytes == NULL || byte_count == 0) {
        return 1;
    }
    /* 夹具不覆盖已有文件，避免破坏已记录摘要的原件。 */
    output_file = fopen(path, "wbx");
    if (output_file == NULL) {
        return 1;
    }
    if (fwrite(bytes, 1, byte_count, output_file) != byte_count) {
        operation_status = 1;
    }
    if (fclose(output_file) != 0) {
        operation_status = 1;
    }
    return operation_status;
}

static void print_digest(const char *label, const uint8_t *bytes, size_t byte_count)
{
    uint8_t digest[32];
    platform_m2_sha3_256(digest, bytes, byte_count);
    printf("%s_sha3_256=", label);
    for (size_t byte_index = 0; byte_index < sizeof(digest); ++byte_index) {
        printf("%02x", digest[byte_index]);
    }
    putchar('\n');
}

int main(int argument_count, char **argument_values)
{
    const char *key_seed_text = NULL;
    const char *public_key_path = NULL;
    const char *secret_key_path = NULL;
    uint8_t key_randomness[MLKEM_KEY_SEED_BYTES];
    static uint8_t public_key[MLKEM_ENCAPSULATION_KEY_BYTES];
    static uint8_t secret_key[MLKEM_DECAPSULATION_KEY_BYTES];
    int operation_status = 1;
    for (int argument_index = 1; argument_index < argument_count; argument_index += 2) {
        if (argument_index + 1 >= argument_count) {
            break;
        }
        if (strcmp(argument_values[argument_index], "--key-seed") == 0) {
            key_seed_text = argument_values[argument_index + 1];
        } else if (strcmp(argument_values[argument_index], "--public-key") == 0) {
            public_key_path = argument_values[argument_index + 1];
        } else if (strcmp(argument_values[argument_index], "--secret-key") == 0) {
            secret_key_path = argument_values[argument_index + 1];
        } else {
            break;
        }
    }
    if (key_seed_text == NULL || public_key_path == NULL || secret_key_path == NULL ||
        key_seed_text[0] == '\0') {
        fputs("usage: m2_make_keypair --key-seed <text> --public-key <file> --secret-key <file>\n",
            stderr);
        return 2;
    }
    shake256(key_randomness,
        sizeof(key_randomness),
        (const uint8_t *)key_seed_text,
        strlen(key_seed_text));
    if (platform_m2_test_keypair(public_key, secret_key, key_randomness) != 0) {
        fputs("key pair generation failed\n", stderr);
        goto cleanup;
    }
    if (write_new_file(public_key_path, public_key, sizeof(public_key)) != 0) {
        fputs("public key write failed; use a new path\n", stderr);
        goto cleanup;
    }
    if (write_new_file(secret_key_path, secret_key, sizeof(secret_key)) != 0) {
        fputs("secret key write failed; use a new path\n", stderr);
        goto cleanup;
    }
    print_digest("public_key", public_key, sizeof(public_key));
    print_digest("secret_key", secret_key, sizeof(secret_key));
    operation_status = 0;
cleanup:
    erase_secret_bytes(key_randomness, sizeof(key_randomness));
    erase_secret_bytes(secret_key, sizeof(secret_key));
    return operation_status;
}
