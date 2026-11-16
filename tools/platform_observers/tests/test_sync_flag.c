/* T5.1 同步库单测：fork 双进程交替 turn 各 1000 次（匿名共享页与文件共享页两种模式），
 * alarm(10) 超时保护；无死锁则退出 0。 */

#define _POSIX_C_SOURCE 200809L
#define _GNU_SOURCE

#include "../sync_flag.h"

#include <signal.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/wait.h>
#include <unistd.h>

#define SYNC_FLAG_TEST_TURN_COUNT 1000u
#define SYNC_FLAG_TEST_TIMEOUT_SECONDS 10u

/* 子进程侧：先等父进程第一次 signal，然后循环 signal/wait。 */
static int child_ping_pong(struct sync_flag *flag)
{
    if (sync_flag_wait_turn(flag) != 0) {
        return 1;
    }
    sync_flag_signal_turn(flag);
    for (unsigned turn_index = 0u; turn_index < SYNC_FLAG_TEST_TURN_COUNT; ++turn_index) {
        if (sync_flag_wait_turn(flag) != 0) {
            return 1;
        }
        sync_flag_signal_turn(flag);
    }
    return 0;
}

/* 父进程侧：循环 signal/wait。 */
static int parent_ping_pong(struct sync_flag *flag)
{
    for (unsigned turn_index = 0u; turn_index < SYNC_FLAG_TEST_TURN_COUNT; ++turn_index) {
        sync_flag_signal_turn(flag);
        if (sync_flag_wait_turn(flag) != 0) {
            return 1;
        }
    }
    return 0;
}

static int wait_for_child(pid_t child_process)
{
    int wait_status = 0;
    if (waitpid(child_process, &wait_status, 0) != child_process) {
        return 1;
    }
    if (!WIFEXITED(wait_status) || WEXITSTATUS(wait_status) != 0) {
        return 1;
    }
    return 0;
}

static int run_anonymous_mode(void)
{
    struct sync_flag *flag = sync_flag_create();
    if (flag == NULL) {
        return 1;
    }
    pid_t child_process = fork();
    if (child_process < 0) {
        sync_flag_destroy(flag);
        return 1;
    }
    if (child_process == 0) {
        alarm(SYNC_FLAG_TEST_TIMEOUT_SECONDS);
        int status = child_ping_pong(flag);
        _exit(status == 0 ? 0 : 1);
    }
    alarm(SYNC_FLAG_TEST_TIMEOUT_SECONDS);
    int status = parent_ping_pong(flag);
    alarm(0u);
    status |= wait_for_child(child_process);
    sync_flag_destroy(flag);
    return status;
}

static int run_named_mode(void)
{
    const char *temporary_root = getenv("A113_TEST_TMPDIR");
    if (temporary_root == NULL || temporary_root[0] == '\0') {
        fprintf(stderr, "error: A113_TEST_TMPDIR is required for named sync flag test\n");
        return 1;
    }
    char sync_path[1024];
    int written = snprintf(sync_path,
        sizeof(sync_path),
        "%s/sync-flag-%ld.bin",
        temporary_root,
        (long)getpid());
    if (written < 0 || (size_t)written >= sizeof(sync_path)) {
        return 1;
    }
    struct sync_flag *creator_flag = sync_flag_create_named(sync_path);
    if (creator_flag == NULL) {
        return 1;
    }
    int readiness_pipe[2];
    if (pipe(readiness_pipe) != 0) {
        sync_flag_destroy(creator_flag);
        (void)remove(sync_path);
        return 1;
    }
    pid_t child_process = fork();
    if (child_process < 0) {
        sync_flag_destroy(creator_flag);
        (void)remove(sync_path);
        return 1;
    }
    if (child_process == 0) {
        (void)close(readiness_pipe[0]);
        struct sync_flag *opened_flag = sync_flag_open_named(sync_path);
        if (opened_flag == NULL) {
            _exit(1);
        }
        /* 通知父进程“已打开映射”，之后才开始 ping-pong；避免初始化竞态死锁。 */
        char ready_byte = 'R';
        if (write(readiness_pipe[1], &ready_byte, 1u) != 1) {
            _exit(1);
        }
        (void)close(readiness_pipe[1]);
        alarm(SYNC_FLAG_TEST_TIMEOUT_SECONDS);
        int status = child_ping_pong(opened_flag);
        sync_flag_destroy(opened_flag);
        _exit(status == 0 ? 0 : 1);
    }
    (void)close(readiness_pipe[1]);
    char ready_byte = 0;
    if (read(readiness_pipe[0], &ready_byte, 1u) != 1 || ready_byte != 'R') {
        (void)close(readiness_pipe[0]);
        (void)wait_for_child(child_process);
        sync_flag_destroy(creator_flag);
        (void)remove(sync_path);
        return 1;
    }
    (void)close(readiness_pipe[0]);
    alarm(SYNC_FLAG_TEST_TIMEOUT_SECONDS);
    int status = parent_ping_pong(creator_flag);
    alarm(0u);
    status |= wait_for_child(child_process);
    sync_flag_destroy(creator_flag);
    (void)remove(sync_path);
    return status;
}

int main(void)
{
    if (run_anonymous_mode() != 0) {
        fprintf(stderr, "error: anonymous sync flag ping-pong failed\n");
        return 1;
    }
    if (run_named_mode() != 0) {
        fprintf(stderr, "error: named sync flag ping-pong failed\n");
        return 1;
    }
    printf("sync_flag: anonymous and named ping-pong %u turns each pass\n",
        SYNC_FLAG_TEST_TURN_COUNT);
    return 0;
}
