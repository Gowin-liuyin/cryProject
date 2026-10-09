#ifndef TEST_TEMP_DIRECTORY_H
#define TEST_TEMP_DIRECTORY_H

#include <errno.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>

#define TEST_TEMP_DIRECTORY_CAPACITY_BYTES 128u

static inline char *create_test_temp_directory(char *directory_path,
    size_t path_capacity_bytes,
    const char *fixture_prefix)
{
    const char *parent_directory = getenv("A113_TEST_TMPDIR");
    if (directory_path == NULL || path_capacity_bytes == 0u || fixture_prefix == NULL ||
        fixture_prefix[0] == '\0' || strchr(fixture_prefix, '/') != NULL ||
        strchr(fixture_prefix, '\\') != NULL || parent_directory == NULL ||
        parent_directory[0] != '/') {
        errno = EINVAL;
        return NULL;
    }
    int path_length_bytes = snprintf(directory_path,
        path_capacity_bytes,
        "%s/%s.XXXXXX",
        parent_directory,
        fixture_prefix);
    if (path_length_bytes < 0 || (size_t)path_length_bytes >= path_capacity_bytes) {
        errno = ENAMETOOLONG;
        return NULL;
    }
    return mkdtemp(directory_path);
}

#endif
