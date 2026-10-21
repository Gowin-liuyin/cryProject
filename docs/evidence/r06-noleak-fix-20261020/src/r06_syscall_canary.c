/*
 * R06 Memcheck 负对照（新增件）。
 *
 * 故意把"已标记为未定义（即秘密）"的缓冲区作为 syscall 参数交给内核写出，
 * 预期 Valgrind Memcheck 必须报出
 *   Syscall param write(buf) points to uninitialised byte(s)
 * 并因 --error-exitcode 使进程返回非 0。
 *
 * 用途：证明本轮使用的 Memcheck 通道与命令行参数确实能把"秘密流向 syscall 参数"
 * 这一类事件变成可计数错误；因此平台 harness 的 0 错误才是有信息的 0。
 * 本程序不读任何真实密钥，只写一个本地填充的缓冲区。
 */
#include <stdio.h>
#include <string.h>
#include <unistd.h>

#include <valgrind/memcheck.h>

int main(void)
{
    char marked_secret_buffer[64];
    ssize_t written_byte_count;

    memset(marked_secret_buffer, 0x41, sizeof(marked_secret_buffer));
    VALGRIND_MAKE_MEM_UNDEFINED(marked_secret_buffer, sizeof(marked_secret_buffer));
    written_byte_count = write(STDOUT_FILENO, marked_secret_buffer, sizeof(marked_secret_buffer));
    VALGRIND_MAKE_MEM_DEFINED(marked_secret_buffer, sizeof(marked_secret_buffer));
    if (written_byte_count != (ssize_t)sizeof(marked_secret_buffer)) {
        fputs("canary write failed\n", stderr);
        return 1;
    }
    return 0;
}
