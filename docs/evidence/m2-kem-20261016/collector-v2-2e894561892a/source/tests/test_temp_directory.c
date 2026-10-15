#define _POSIX_C_SOURCE 200809L
#ifdef __APPLE__
#define _DARWIN_C_SOURCE
#endif

#include "test_temp_directory.h"

#include <assert.h>
#include <sys/stat.h>
#include <unistd.h>

int main(void)
{
    const char *configured_root = getenv("A113_TEST_TMPDIR");
    assert(configured_root != NULL);
    char *saved_root = strdup(configured_root);
    assert(saved_root != NULL);
    char first_directory[TEST_TEMP_DIRECTORY_CAPACITY_BYTES];
    char second_directory[TEST_TEMP_DIRECTORY_CAPACITY_BYTES];
    assert(unsetenv("A113_TEST_TMPDIR") == 0);
    errno = 0;
    assert(create_test_temp_directory(first_directory, sizeof(first_directory), "missing") == NULL);
    assert(errno == EINVAL);
    assert(setenv("A113_TEST_TMPDIR", "relative", 1) == 0);
    assert(
        create_test_temp_directory(first_directory, sizeof(first_directory), "relative") == NULL);
    assert(setenv("A113_TEST_TMPDIR", saved_root, 1) == 0);
    assert(
        create_test_temp_directory(first_directory, sizeof(first_directory), "../escape") == NULL);
    assert(create_test_temp_directory(first_directory, 1u, "too-long") == NULL);
    assert(errno == ENAMETOOLONG);
    assert(
        create_test_temp_directory(first_directory, sizeof(first_directory), "temp-root") != NULL);
    assert(create_test_temp_directory(second_directory, sizeof(second_directory), "temp-root") !=
        NULL);
    assert(strcmp(first_directory, second_directory) != 0);
    size_t root_length_bytes = strlen(saved_root);
    assert(strncmp(first_directory, saved_root, root_length_bytes) == 0);
    assert(first_directory[root_length_bytes] == '/');
    struct stat directory_status;
    assert(stat(first_directory, &directory_status) == 0);
    assert(S_ISDIR(directory_status.st_mode));
    assert((directory_status.st_mode & 0777u) == 0700u);
    assert(rmdir(first_directory) == 0);
    assert(rmdir(second_directory) == 0);
    free(saved_root);
    return 0;
}
