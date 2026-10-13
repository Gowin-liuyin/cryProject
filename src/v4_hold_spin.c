#define _POSIX_C_SOURCE 200809L
#ifdef __linux__
#define _GNU_SOURCE
#endif

#include <errno.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <time.h>
#ifdef __linux__
#include <sched.h>
#endif

/* 频率保持探测的空转。不解封装。只在 Linux 上把本进程钉到 CPU2。 */
int main(int argc, char **argv)
{
    char *end = NULL;
    long duration_ms = 0;
    if (argc != 2) {
        fputs("usage: v4_hold_spin DURATION_MS\n", stderr);
        return 1;
    }
    errno = 0;
    duration_ms = strtol(argv[1], &end, 10);
    if (errno != 0 || end == argv[1] || *end != '\0' || duration_ms < 1 || duration_ms > 10000) {
        return 1;
    }
#ifndef __linux__
    fputs("v4_hold_spin requires linux\n", stderr);
    return 2;
#else
    struct timespec start;
    uint64_t start_ns = 0u;
    uint64_t limit_ns = 0u;
    cpu_set_t cpu_set;
    CPU_ZERO(&cpu_set);
    CPU_SET(2, &cpu_set);
    if (sched_setaffinity(0, sizeof(cpu_set), &cpu_set) != 0) {
        return 1;
    }
    if (clock_gettime(CLOCK_MONOTONIC, &start) != 0) {
        return 1;
    }
    start_ns = (uint64_t)start.tv_sec * UINT64_C(1000000000) + (uint64_t)start.tv_nsec;
    limit_ns = (uint64_t)duration_ms * UINT64_C(1000000);
    for (;;) {
        struct timespec now;
        uint64_t now_ns = 0u;
        if (clock_gettime(CLOCK_MONOTONIC, &now) != 0) {
            return 1;
        }
        now_ns = (uint64_t)now.tv_sec * UINT64_C(1000000000) + (uint64_t)now.tv_nsec;
        if (now_ns - start_ns >= limit_ns) {
            break;
        }
    }
    return 0;
#endif
}
