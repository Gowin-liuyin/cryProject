#include <ctype.h>
#include <stdio.h>
#include <string.h>

static int read_logged_digest(const char *log_path, char digest[65])
{
    FILE *log_file = fopen(log_path, "r");
    if (log_file == NULL) {
        return 1;
    }
    char line[8192];
    unsigned digest_count = 0;
    int operation_status = 0;
    while (fgets(line, sizeof(line), log_file) != NULL) {
        size_t line_bytes = strlen(line);
        if (line_bytes == 0 || line[line_bytes - 1u] != '\n') {
            operation_status = 1;
            break;
        }
        if (strncmp(line, "SHA3-256(", 9) != 0) {
            continue;
        }
        const char *digest_start = NULL;
        for (const char *delimiter = strstr(line + 9, ")= "); delimiter != NULL;
            delimiter = strstr(delimiter + 3, ")= ")) {
            digest_start = delimiter + 3;
        }
        if (digest_start == NULL || strlen(digest_start) != 65u || ++digest_count != 1u) {
            operation_status = 1;
            break;
        }
        for (size_t byte_index = 0; byte_index < 64u; ++byte_index) {
            unsigned char character = (unsigned char)digest_start[byte_index];
            if (!isxdigit(character)) {
                operation_status = 1;
                break;
            }
            digest[byte_index] = (char)tolower(character);
        }
        if (operation_status != 0) {
            break;
        }
        digest[64] = '\0';
    }
    if (ferror(log_file)) {
        operation_status = 1;
    }
    if (fclose(log_file) != 0 || digest_count != 1u) {
        operation_status = 1;
    }
    return operation_status;
}

int main(int argument_count, char **argument_values)
{
    if (argument_count != 2) {
        fputs("Usage: native_digest OPENSSL_LOG_FILE\n", stderr);
        return 2;
    }
    char digest[65];
    if (read_logged_digest(argument_values[1], digest) != 0) {
        fputs("OpenSSL log must contain exactly one complete SHA3-256 digest.\n", stderr);
        return 1;
    }
    return printf("%s\n", digest) < 0 || fflush(stdout) != 0 ? 1 : 0;
}
