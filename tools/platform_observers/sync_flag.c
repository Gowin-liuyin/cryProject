#define _POSIX_C_SOURCE 200809L
#define _GNU_SOURCE

#include "sync_flag.h"

#include <errno.h>
#include <fcntl.h>
#include <sched.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/mman.h>
#include <sys/stat.h>
#include <unistd.h>

static void initialize_shared_page(struct sync_flag_shared *shared)
{
    atomic_store(&shared->magic, SYNC_FLAG_MAGIC);
    atomic_store(&shared->closed, 0u);
    atomic_store(&shared->turn_sequence, 0ull);
}

static struct sync_flag *allocate_handle(void)
{
    struct sync_flag *flag = calloc(1u, sizeof(struct sync_flag));
    if (flag == NULL) {
        fprintf(stderr, "error: cannot allocate sync flag handle\n");
    }
    return flag;
}

static struct sync_flag *map_shared_page(int descriptor, size_t map_bytes)
{
    struct sync_flag *flag = allocate_handle();
    if (flag == NULL) {
        return NULL;
    }
    void *mapped_region = mmap(NULL, map_bytes, PROT_READ | PROT_WRITE, MAP_SHARED, descriptor, 0);
    if (mapped_region == MAP_FAILED) {
        fprintf(stderr, "error: mmap failed: %s\n", strerror(errno));
        free(flag);
        return NULL;
    }
    flag->shared = (struct sync_flag_shared *)mapped_region;
    flag->descriptor = descriptor;
    return flag;
}

struct sync_flag *sync_flag_create(void)
{
    struct sync_flag *flag = allocate_handle();
    if (flag == NULL) {
        return NULL;
    }
    void *mapped_region = mmap(NULL,
        sizeof(struct sync_flag_shared),
        PROT_READ | PROT_WRITE,
        MAP_SHARED | MAP_ANONYMOUS,
        -1,
        0);
    if (mapped_region == MAP_FAILED) {
        fprintf(stderr, "error: anonymous mmap failed: %s\n", strerror(errno));
        free(flag);
        return NULL;
    }
    flag->shared = (struct sync_flag_shared *)mapped_region;
    flag->descriptor = -1;
    flag->is_creator = 1;
    flag->is_named = 0;
    initialize_shared_page(flag->shared);
    return flag;
}

struct sync_flag *sync_flag_create_named(const char *path)
{
    if (path == NULL || path[0] == '\0' || strlen(path) >= SYNC_FLAG_PATH_CAPACITY_BYTES) {
        fprintf(stderr, "error: invalid sync flag path\n");
        return NULL;
    }
    int descriptor = open(path, O_RDWR | O_CREAT | O_TRUNC, 0600);
    if (descriptor < 0) {
        fprintf(stderr, "error: cannot create %s: %s\n", path, strerror(errno));
        return NULL;
    }
    if (ftruncate(descriptor, (off_t)sizeof(struct sync_flag_shared)) != 0) {
        fprintf(stderr, "error: cannot size %s: %s\n", path, strerror(errno));
        (void)close(descriptor);
        return NULL;
    }
    struct sync_flag *flag = map_shared_page(descriptor, sizeof(struct sync_flag_shared));
    if (flag == NULL) {
        (void)close(descriptor);
        return NULL;
    }
    flag->is_creator = 1;
    flag->is_named = 1;
    initialize_shared_page(flag->shared);
    (void)snprintf(flag->path, sizeof(flag->path), "%s", path);
    return flag;
}

struct sync_flag *sync_flag_open_named(const char *path)
{
    if (path == NULL || path[0] == '\0' || strlen(path) >= SYNC_FLAG_PATH_CAPACITY_BYTES) {
        fprintf(stderr, "error: invalid sync flag path\n");
        return NULL;
    }
    int descriptor = open(path, O_RDWR);
    if (descriptor < 0) {
        fprintf(stderr, "error: cannot open %s: %s\n", path, strerror(errno));
        return NULL;
    }
    struct stat file_status;
    if (fstat(descriptor, &file_status) != 0 ||
        file_status.st_size < (off_t)sizeof(struct sync_flag_shared)) {
        fprintf(stderr, "error: %s is not a sync flag file\n", path);
        (void)close(descriptor);
        return NULL;
    }
    struct sync_flag *flag = map_shared_page(descriptor, sizeof(struct sync_flag_shared));
    if (flag == NULL) {
        (void)close(descriptor);
        return NULL;
    }
    if (atomic_load(&flag->shared->magic) != SYNC_FLAG_MAGIC) {
        fprintf(stderr, "error: %s has an invalid sync flag magic\n", path);
        (void)munmap(flag->shared, sizeof(struct sync_flag_shared));
        (void)close(descriptor);
        free(flag);
        return NULL;
    }
    flag->is_creator = 0;
    flag->is_named = 1;
    flag->last_seen_sequence = atomic_load(&flag->shared->turn_sequence);
    (void)snprintf(flag->path, sizeof(flag->path), "%s", path);
    return flag;
}

void sync_flag_destroy(struct sync_flag *flag)
{
    if (flag == NULL) {
        return;
    }
    if (flag->shared != NULL) {
        atomic_store(&flag->shared->closed, 1u);
        (void)munmap(flag->shared, sizeof(struct sync_flag_shared));
        flag->shared = NULL;
    }
    if (flag->descriptor >= 0) {
        (void)close(flag->descriptor);
        flag->descriptor = -1;
    }
    free(flag);
}

int sync_flag_wait_turn(struct sync_flag *flag)
{
    if (flag == NULL || flag->shared == NULL) {
        return -1;
    }
    for (;;) {
        if (atomic_load_explicit(&flag->shared->closed, memory_order_acquire) != 0u) {
            return -1;
        }
        uint64_t current_sequence =
            atomic_load_explicit(&flag->shared->turn_sequence, memory_order_acquire);
        if (current_sequence != flag->last_seen_sequence) {
            flag->last_seen_sequence = current_sequence;
            return 0;
        }
        sched_yield();
    }
}

void sync_flag_signal_turn(struct sync_flag *flag)
{
    if (flag == NULL || flag->shared == NULL) {
        return;
    }
    (void)atomic_fetch_add_explicit(&flag->shared->turn_sequence, 1ull, memory_order_release);
}

uint64_t sync_flag_current_sequence(const struct sync_flag *flag)
{
    if (flag == NULL || flag->shared == NULL) {
        return 0u;
    }
    return atomic_load_explicit(&flag->shared->turn_sequence, memory_order_acquire);
}
