#ifndef PLATFORM_OBSERVERS_OBSERVER_COMMON_H
#define PLATFORM_OBSERVERS_OBSERVER_COMMON_H

/* 观测者族共用的小工具：参数解析、CLOCK_MONOTONIC_RAW 读钟、绑核、CSV 写出与
 * 单进程自检。全部为 POSIX 本地操作；计时窗口内不调用这里的 I/O/分配函数。 */

#include <stddef.h>
#include <stdint.h>

#define OBSERVER_PATH_CAPACITY_BYTES 4096u

/* `--flag value` / `--flag=value` 取值；0 成功，1 不匹配，2 缺值。 */
int observer_take_value(int argument_count,
    char **argument_values,
    int *argument_index,
    const char *name,
    const char **value);

/* 只接受十进制数字并检查范围；0 成功，1 失败。 */
int observer_parse_unsigned(const char *text,
    unsigned long long minimum,
    unsigned long long maximum,
    unsigned long long *value);

/* CLOCK_MONOTONIC_RAW 纳秒；失败返回 0。 */
uint64_t observer_now_nanoseconds(void);

/* 绑定当前进程到指定 CPU；0 成功，-1 失败。 */
int observer_bind_cpu(unsigned cpu_index);

/* 追加格式化文本；0 成功，1 失败（容量不足等）。 */
int observer_append_text(char *buffer, size_t capacity, size_t *used, const char *format, ...);

/* 写出文本文件（窗口外调用）；0 成功，1 失败。 */
int observer_write_text(const char *path, const char *text);

/* 自检输出路径：$A113_TEST_TMPDIR/observer-<name>-<pid>.csv；失败返回 -1。 */
int observer_self_check_output_path(char *buffer, size_t capacity, const char *file_name);

/* 校验自检 CSV：表头逐字一致、数据行数正确、每行字段数一致；0 成功，1 失败。 */
int observer_validate_csv(const char *path, const char *expected_header, unsigned expected_rows);

/* 轮询直到共享 turn 序号达到绝对目标；0 达标，同步页被对端关闭返回 -1。
 * wait_turn 是"序号有变化即返回"，会吞掉自己的 signal，跨进程逐拍咬合
 * （观测者 pilot 的受害者窗口并发）必须用绝对目标轮询。 */
struct sync_flag;

int observer_wait_sequence(struct sync_flag *flag, uint64_t target_sequence);

#endif /* PLATFORM_OBSERVERS_OBSERVER_COMMON_H */
