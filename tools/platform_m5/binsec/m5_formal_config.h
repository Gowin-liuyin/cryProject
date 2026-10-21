/*
 * M5 形式化产物的 mlkem-native 配置（i386 裸机环境专用）。
 *
 * 与仓库默认的 include/baseline_config.h 的差别只有一处实质内容：i386 裸机环境
 * 没有 32 位 libc 头与运行库，因此自带 memcpy/memset。其余（参数集、命名空间
 * 前缀、随机化 API 关闭）与默认配置逐字一致，保证被分析的实现与正式采集产物
 * 是同一套代码路径。
 *
 * 本文件只用于 Binsec 的 32 位形式化目标，不参与 64 位采集产物的构建。
 */
#ifndef M5_FORMAL_CONFIG_H
#define M5_FORMAL_CONFIG_H

#define MLK_CONFIG_PARAMETER_SET 768
#define MLK_CONFIG_NAMESPACE_PREFIX baseline_native
#define MLK_CONFIG_NO_RANDOMIZED_API

/* 自带内存函数，避免 <string.h>（32 位 libc 头在本机不存在）。 */
#define MLK_CONFIG_CUSTOM_MEMCPY
#define MLK_CONFIG_CUSTOM_MEMSET

#include <stddef.h>
#include <stdint.h>

static inline void *mlk_memcpy(void *destination, const void *source, size_t byte_count)
{
    unsigned char *destination_bytes = (unsigned char *)destination;
    const unsigned char *source_bytes = (const unsigned char *)source;
    for (size_t byte_index = 0; byte_index < byte_count; byte_index++) {
        destination_bytes[byte_index] = source_bytes[byte_index];
    }
    return destination;
}

static inline void *mlk_memset(void *destination, int byte_value, size_t byte_count)
{
    unsigned char *destination_bytes = (unsigned char *)destination;
    for (size_t byte_index = 0; byte_index < byte_count; byte_index++) {
        destination_bytes[byte_index] = (unsigned char)byte_value;
    }
    return destination;
}

#endif
