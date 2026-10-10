#define _POSIX_C_SOURCE 200809L

#include "mlkem.h"
#include "src/fips202/fips202.h"

#include <errno.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/wait.h>
#include <unistd.h>

#define CHECK(condition)                                                                           \
    do {                                                                                           \
        if (!(condition)) {                                                                        \
            fprintf(stderr, "check failed at line %d: %s\n", __LINE__, #condition);                \
            return 1;                                                                              \
        }                                                                                          \
    } while (0)

static int read_hex_bytes(FILE *vector_file, uint8_t *output, size_t output_byte_count)
{
    char encoded_bytes[MLKEM_DECAPSULATION_KEY_BYTES * 2u + 1u];
    size_t byte_index;
    if (fscanf(vector_file, "%4800s", encoded_bytes) != 1 ||
        strlen(encoded_bytes) != output_byte_count * 2u) {
        return 1;
    }
    for (byte_index = 0; byte_index < output_byte_count; ++byte_index) {
        unsigned decoded_byte;
        if (sscanf(encoded_bytes + byte_index * 2u, "%2x", &decoded_byte) != 1) {
            return 1;
        }
        output[byte_index] = (uint8_t)decoded_byte;
    }
    return 0;
}

static int capture_program(char *const arguments[], char **text_out)
{
    int pipes[2];
    pid_t child;
    size_t capacity = 4096u;
    size_t length = 0;
    char *text = malloc(capacity);
    if (text == NULL || pipe(pipes) != 0) {
        free(text);
        return 1;
    }
    child = fork();
    if (child == 0) {
        (void)close(pipes[0]);
        if (dup2(pipes[1], STDOUT_FILENO) < 0) {
            _exit(127);
        }
        (void)close(pipes[1]);
        execvp(arguments[0], arguments);
        _exit(127);
    }
    (void)close(pipes[1]);
    if (child < 0) {
        (void)close(pipes[0]);
        free(text);
        return 1;
    }
    while (1) {
        ssize_t read_count;
        if (length + 1024u >= capacity) {
            size_t new_capacity = capacity * 2u;
            char *grown = realloc(text, new_capacity);
            if (grown == NULL) {
                free(text);
                (void)close(pipes[0]);
                (void)waitpid(child, NULL, 0);
                return 1;
            }
            text = grown;
            capacity = new_capacity;
        }
        read_count = read(pipes[0], text + length, capacity - length - 1u);
        if (read_count < 0) {
            if (errno == EINTR) {
                continue;
            }
            free(text);
            (void)close(pipes[0]);
            (void)waitpid(child, NULL, 0);
            return 1;
        }
        if (read_count == 0) {
            break;
        }
        length += (size_t)read_count;
    }
    (void)close(pipes[0]);
    text[length] = '\0';
    {
        int wait_status = 0;
        if (waitpid(child, &wait_status, 0) < 0 || !WIFEXITED(wait_status) ||
            WEXITSTATUS(wait_status) != 0) {
            free(text);
            return 1;
        }
    }
    *text_out = text;
    return 0;
}

static int hash_matches_shasum(const char *record, const char *object_path, const char *shasum_path)
{
    char *arguments[] = {(char *)shasum_path, "-a", "256", (char *)object_path, NULL};
    char *shasum_output = NULL;
    const char *recorded = strstr(record, "artifact_sha256=");
    if (recorded == NULL || capture_program(arguments, &shasum_output) != 0) {
        free(shasum_output);
        return 1;
    }
    recorded += strlen("artifact_sha256=");
    if (strlen(shasum_output) < 64u || strncmp(recorded, shasum_output, 64) != 0) {
        free(shasum_output);
        return 1;
    }
    free(shasum_output);
    return 0;
}

static int record_has_mechanism(const char *record, const char *mechanism_name)
{
    const char *found = strstr(record, mechanism_name);
    const char *status;
    if (found == NULL) {
        return 0;
    }
    status = strstr(found, "status=");
    if (status == NULL) {
        return 0;
    }
    status += strlen("status=");
    if (strncmp(status, "present", 7) == 0 || strncmp(status, "absent", 6) == 0) {
        return strstr(found, "observed=") != NULL && strstr(found, "leak_if_present=") != NULL;
    }
    return 0;
}

static int check_public_decapsulation(const char *vector_path)
{
    FILE *vector_file = fopen(vector_path, "r");
    char operation_name[16];
    char case_number_text[21];
    uint8_t decapsulation_key[MLKEM_DECAPSULATION_KEY_BYTES];
    uint8_t ciphertext[MLKEM_CIPHERTEXT_BYTES];
    uint8_t expected_shared_secret[MLKEM_SHARED_SECRET_BYTES];
    uint8_t shared_secret[MLKEM_SHARED_SECRET_BYTES];
    uint8_t tampered_ciphertext[MLKEM_CIPHERTEXT_BYTES];
    uint8_t tampered_secret[MLKEM_SHARED_SECRET_BYTES];
    uint8_t rejection_input[MLKEM_SHARED_SECRET_BYTES + MLKEM_CIPHERTEXT_BYTES];
    uint8_t rejection_secret[MLKEM_SHARED_SECRET_BYTES];
    int scanned_field_count;
    int found_decapsulation = 0;
    CHECK(vector_file != NULL);
    while ((scanned_field_count =
                   fscanf(vector_file, "%15s %20s", operation_name, case_number_text)) == 2) {
        if (strcmp(operation_name, "decap") != 0) {
            int discarded = fscanf(vector_file, "%*[^\n]");
            (void)discarded;
            continue;
        }
        CHECK(read_hex_bytes(vector_file, decapsulation_key, sizeof(decapsulation_key)) == 0);
        CHECK(read_hex_bytes(vector_file, ciphertext, sizeof(ciphertext)) == 0);
        CHECK(read_hex_bytes(vector_file, expected_shared_secret, sizeof(expected_shared_secret)) ==
            0);
        found_decapsulation = 1;
        break;
    }
    CHECK(found_decapsulation == 1);
    (void)fclose(vector_file);
    CHECK(mlkem_decapsulate(shared_secret,
              sizeof(shared_secret),
              ciphertext,
              sizeof(ciphertext),
              decapsulation_key,
              sizeof(decapsulation_key)) == 0);
    CHECK(memcmp(shared_secret, expected_shared_secret, sizeof(shared_secret)) == 0);
    memcpy(tampered_ciphertext, ciphertext, sizeof(ciphertext));
    tampered_ciphertext[0] ^= 0x01u;
    CHECK(mlkem_decapsulate(tampered_secret,
              sizeof(tampered_secret),
              tampered_ciphertext,
              sizeof(tampered_ciphertext),
              decapsulation_key,
              sizeof(decapsulation_key)) == 0);
    memcpy(rejection_input,
        decapsulation_key + sizeof(decapsulation_key) - MLKEM_SHARED_SECRET_BYTES,
        MLKEM_SHARED_SECRET_BYTES);
    memcpy(rejection_input + MLKEM_SHARED_SECRET_BYTES,
        tampered_ciphertext,
        sizeof(tampered_ciphertext));
    mlk_shake256(rejection_secret,
        sizeof(rejection_secret),
        rejection_input,
        sizeof(rejection_input));
    CHECK(memcmp(tampered_secret, rejection_secret, sizeof(tampered_secret)) == 0);
    CHECK(memcmp(tampered_secret, shared_secret, sizeof(shared_secret)) != 0);
    CHECK(mlkem_decapsulate(shared_secret,
              sizeof(shared_secret) - 1u,
              ciphertext,
              sizeof(ciphertext),
              decapsulation_key,
              sizeof(decapsulation_key)) == MLKEM_ERROR_ARGUMENT);
    CHECK(mlkem_decapsulate(shared_secret,
              sizeof(shared_secret),
              ciphertext,
              sizeof(ciphertext) - 1u,
              decapsulation_key,
              sizeof(decapsulation_key)) == MLKEM_ERROR_ARGUMENT);
    CHECK(mlkem_decapsulate(shared_secret,
              sizeof(shared_secret),
              ciphertext,
              sizeof(ciphertext) + 1u,
              decapsulation_key,
              sizeof(decapsulation_key)) == MLKEM_ERROR_ARGUMENT);
    CHECK(mlkem_decapsulate(shared_secret,
              sizeof(shared_secret),
              NULL,
              sizeof(ciphertext),
              decapsulation_key,
              sizeof(decapsulation_key)) == MLKEM_ERROR_ARGUMENT);
    CHECK(mlkem_decapsulate(NULL,
              sizeof(shared_secret),
              ciphertext,
              sizeof(ciphertext),
              decapsulation_key,
              sizeof(decapsulation_key)) == MLKEM_ERROR_ARGUMENT);
    CHECK(mlkem_decapsulate(shared_secret,
              sizeof(shared_secret),
              ciphertext,
              sizeof(ciphertext),
              NULL,
              sizeof(decapsulation_key)) == MLKEM_ERROR_ARGUMENT);
    erase_secret_bytes(decapsulation_key, sizeof(decapsulation_key));
    erase_secret_bytes(shared_secret, sizeof(shared_secret));
    erase_secret_bytes(tampered_secret, sizeof(tampered_secret));
    erase_secret_bytes(rejection_secret, sizeof(rejection_secret));
    (void)scanned_field_count;
    return 0;
}

static int
copy_kernel_object_path(int argument_count, char **argument_values, char *output, size_t capacity)
{
    int argument_index;
    for (argument_index = 5; argument_index < argument_count; ++argument_index) {
        const char *cursor = argument_values[argument_index];
        while (*cursor != '\0') {
            const char *separator = strchr(cursor, ';');
            size_t length = separator == NULL ? strlen(cursor) : (size_t)(separator - cursor);
            if (length >= strlen("kernel.c.o") && length < capacity &&
                memcmp(cursor + length - strlen("kernel.c.o"),
                    "kernel.c.o",
                    strlen("kernel.c.o")) == 0) {
                memcpy(output, cursor, length);
                output[length] = '\0';
                return 0;
            }
            if (separator == NULL) {
                break;
            }
            cursor = separator + 1;
        }
    }
    return 1;
}

int main(int argument_count, char **argument_values)
{
    char object_path[1024];
    char *self_test_arguments[3];
    char *audit_arguments[4];
    char *first_record = NULL;
    char *second_record = NULL;
    CHECK(argument_count >= 6);
    CHECK(copy_kernel_object_path(argument_count,
              argument_values,
              object_path,
              sizeof(object_path)) == 0);
    CHECK(check_public_decapsulation(argument_values[1]) == 0);
    self_test_arguments[0] = argument_values[2];
    self_test_arguments[1] = "--self-test";
    self_test_arguments[2] = NULL;
    CHECK(capture_program(self_test_arguments, &first_record) == 0);
    CHECK(strstr(first_record, "mechanism_audit self-test passed") != NULL);
    free(first_record);
    first_record = NULL;
    audit_arguments[0] = argument_values[2];
    audit_arguments[1] = (char *)object_path;
    audit_arguments[2] = argument_values[3];
    audit_arguments[3] = NULL;
    CHECK(capture_program(audit_arguments, &first_record) == 0);
    CHECK(capture_program(audit_arguments, &second_record) == 0);
    CHECK(strcmp(first_record, second_record) == 0);
    CHECK(record_has_mechanism(first_record, "mechanism kyber_slash_division") == 1);
    CHECK(record_has_mechanism(first_record, "mechanism clangover_message_branch") == 1);
    CHECK(record_has_mechanism(first_record, "mechanism fo_compare_rejection") == 1);
    CHECK(strstr(first_record, "vendor/mlkem-native/mlkem/src/compress.c:") != NULL);
    CHECK(strstr(first_record, "vendor/mlkem-native/mlkem/src/kem.c:") != NULL);
    CHECK(hash_matches_shasum(first_record, object_path, argument_values[4]) == 0);
    free(first_record);
    free(second_record);
    puts("mechanism audit test passed");
    return 0;
}
