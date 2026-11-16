#ifndef PLATFORM_OBSERVERS_VICTIM_BACKEND_H
#define PLATFORM_OBSERVERS_VICTIM_BACKEND_H

/* 观测者 pilot 的受害者侧后端接口：wrapper 骨架按协议驱动，后端只提供
 * "窗口外准备"与"窗口内一次完整解封装"两个动作。窗口内不得 I/O、日志或分配。 */

#include <stdint.h>

#define VICTIM_SHARED_SECRET_BYTES 32u

/* 后端名（写入 victim meta 的 backend 字段）。 */
const char *victim_backend_name(void);

/* 窗口外准备：生成密钥对与两个类别的固定密文；0 成功。 */
int victim_backend_prepare(uint64_t test_seed);

/* 计时窗口体：一次完整解封装；返回 0 成功，非 0 表示失败并中止运行。 */
int victim_backend_decapsulate_once(int class_is_ones, uint8_t shared_secret[VICTIM_SHARED_SECRET_BYTES]);

#endif /* PLATFORM_OBSERVERS_VICTIM_BACKEND_H */
