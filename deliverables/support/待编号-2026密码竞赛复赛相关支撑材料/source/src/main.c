#include "inputs.h"

#include <stdio.h>
#include <string.h>

static int print_usage(void)
{
    fputs("Usage: baseline selftest | demo | version\n"
          "       baseline generate-test CATEGORY SEED CIPHERTEXT_FILE\n"
          "       baseline decapsulate-test SEED CIPHERTEXT_FILE\n"
          "Categories: valid bit-flipped random message-zero message-ones\n"
          "Test seeds are public fixtures; never use test keys for real secrets.\n",
        stderr);
    return 2;
}

static int write_ciphertext_file(const char *file_path, const uint8_t *ciphertext)
{
    FILE *ciphertext_file = fopen(file_path, "wbx");
    int operation_status;
    if (ciphertext_file == NULL) {
        return 1;
    }
    operation_status =
        fwrite(ciphertext, 1, MLKEM_CIPHERTEXT_BYTES, ciphertext_file) == MLKEM_CIPHERTEXT_BYTES
        ? 0
        : 1;
    if (fclose(ciphertext_file) != 0) {
        operation_status = 1;
    }
    return operation_status;
}

static int read_ciphertext_file(const char *file_path, uint8_t *ciphertext)
{
    FILE *ciphertext_file = fopen(file_path, "rb");
    int operation_status;
    if (ciphertext_file == NULL) {
        return 1;
    }
    operation_status =
        fread(ciphertext, 1, MLKEM_CIPHERTEXT_BYTES, ciphertext_file) == MLKEM_CIPHERTEXT_BYTES ? 0
                                                                                                : 1;
    if (operation_status == 0 && (fgetc(ciphertext_file) != EOF || ferror(ciphertext_file))) {
        operation_status = 1;
    }
    if (fclose(ciphertext_file) != 0) {
        operation_status = 1;
    }
    return operation_status;
}

int main(int argument_count, char **argument_values)
{
    uint8_t encapsulation_key[MLKEM_ENCAPSULATION_KEY_BYTES];
    uint8_t decapsulation_key[MLKEM_DECAPSULATION_KEY_BYTES];
    uint8_t ciphertext[MLKEM_CIPHERTEXT_BYTES];
    uint8_t shared_secret[MLKEM_SHARED_SECRET_BYTES];
    uint64_t test_seed;
    enum input_category category;
    int operation_status;
    if (argument_count < 2) {
        return print_usage();
    }
    if (argument_count == 2 && strcmp(argument_values[1], "version") == 0) {
        printf("%s ML-KEM-768 FIPS203\n", mlkem_implementation_name());
        return 0;
    }
    if (argument_count == 2 &&
        (strcmp(argument_values[1], "selftest") == 0 || strcmp(argument_values[1], "demo") == 0)) {
        operation_status = mlkem_self_test();
        if (operation_status != 0) {
            fputs("system-random roundtrip failed\n", stderr);
            return 1;
        }
        printf("%s: system-random keygen/encaps/decaps roundtrip passed\n",
            mlkem_implementation_name());
        return 0;
    }
    if (argument_count == 5 && strcmp(argument_values[1], "generate-test") == 0) {
        if (parse_input_category(argument_values[2], &category) != 0 ||
            parse_unsigned_integer(argument_values[3], &test_seed) != 0) {
            return print_usage();
        }
        operation_status = generate_test_key_pair(test_seed, encapsulation_key, decapsulation_key);
        if (operation_status == 0) {
            operation_status =
                generate_test_ciphertext(category, test_seed, 0, encapsulation_key, ciphertext);
        }
        erase_secret_bytes(decapsulation_key, sizeof(decapsulation_key));
        if (operation_status == 0) {
            operation_status = write_ciphertext_file(argument_values[4], ciphertext);
        }
        if (operation_status != 0) {
            fputs("test ciphertext generation/write failed (destination must be new)\n", stderr);
            return 1;
        }
        printf("%s: generated %s test ciphertext, 1088 bytes; label comes from generator\n",
            mlkem_implementation_name(),
            input_category_name(category));
        return 0;
    }
    if (argument_count == 4 && strcmp(argument_values[1], "decapsulate-test") == 0) {
        if (parse_unsigned_integer(argument_values[2], &test_seed) != 0) {
            return print_usage();
        }
        if (read_ciphertext_file(argument_values[3], ciphertext) != 0) {
            fputs("cannot read ciphertext: require exactly 1088 bytes\n", stderr);
            return 1;
        }
        operation_status = generate_test_key_pair(test_seed, encapsulation_key, decapsulation_key);
        if (operation_status == 0) {
            operation_status = mlkem_decapsulate(shared_secret,
                sizeof(shared_secret),
                ciphertext,
                sizeof(ciphertext),
                decapsulation_key,
                sizeof(decapsulation_key));
        }
        erase_secret_bytes(decapsulation_key, sizeof(decapsulation_key));
        erase_secret_bytes(shared_secret, sizeof(shared_secret));
        if (operation_status != 0) {
            fputs("decapsulation operation failed\n", stderr);
            return 1;
        }
        printf("%s: decapsulation completed\n", mlkem_implementation_name());
        return 0;
    }
    return print_usage();
}
