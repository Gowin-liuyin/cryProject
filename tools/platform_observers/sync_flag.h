#ifndef PLATFORM_OBSERVERS_SYNC_FLAG_H
#define PLATFORM_OBSERVERS_SYNC_FLAG_H

/* 观测者与受害者的 turn 同步原语：POSIX 共享页 + 原子序号。
 * 两种共享方式：
 *   - sync_flag_create：匿名 mmap 共享页，只能通过 fork 继承（单测用）；
 *   - sync_flag_create_named / sync_flag_open_named：文件 mmap 共享页，供独立进程
 *     （观测者进程与 wrapper/受害者进程）使用；文件布局就是 struct sync_flag_shared。
 * 计时窗口内的消费者只做原子读（sched_yield 轮询），不做 I/O、不分配内存。 */

#include <stdatomic.h>
#include <stddef.h>
#include <stdint.h>

#define SYNC_FLAG_PATH_CAPACITY_BYTES 4096u
#define SYNC_FLAG_MAGIC 0x41313353u

struct sync_flag_shared {
    atomic_uint magic;
    atomic_uint closed;
    atomic_ullong turn_sequence;
};

struct sync_flag {
    struct sync_flag_shared *shared;
    int descriptor;
    int is_creator;
    int is_named;
    char path[SYNC_FLAG_PATH_CAPACITY_BYTES];
    uint64_t last_seen_sequence;
};

/* 匿名共享页（fork 继承）；失败返回 NULL。 */
struct sync_flag *sync_flag_create(void);

/* 创建/截断共享文件并映射；失败返回 NULL。 */
struct sync_flag *sync_flag_create_named(const char *path);

/* 打开已存在的共享文件并映射；失败返回 NULL。 */
struct sync_flag *sync_flag_open_named(const char *path);

void sync_flag_destroy(struct sync_flag *flag);

/* 阻塞轮询（sched_yield）直到 turn 序号自上次调用后前进；被关闭时返回 -1。
 * 调用者负责超时保护（例如 alarm），本函数不做超时。 */
int sync_flag_wait_turn(struct sync_flag *flag);

/* 原子自增 turn 序号（release），通知对端。 */
void sync_flag_signal_turn(struct sync_flag *flag);

uint64_t sync_flag_current_sequence(const struct sync_flag *flag);

#endif /* PLATFORM_OBSERVERS_SYNC_FLAG_H */
