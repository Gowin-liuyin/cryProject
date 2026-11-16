/* victim_backend_mock：无密码学的自检后端。
 * decapsulate_once 做固定轮 xorshift 搅拌，工作量与类别无关（恒定控制）；
 * cache 协议下若设置环境变量 VICTIM_MOCK_LUT_PATH，则额外按类别读取该
 * MAP_SHARED 映射的对应 64B 行（类别 0 读行 0、类别 1 读行 1），使
 * 端到端测试能观察到类别相关的缓存行命中。 */

#define _POSIX_C_SOURCE 200809L

#include "victim_backend.h"

#include <fcntl.h>
#include <sys/mman.h>
#include <sys/stat.h>
#include <unistd.h>

#include <stdint.h>
#include <stdlib.h>
#include <string.h>

#define MOCK_WORK_BUFFER_BYTES 1088u
#define MOCK_MIX_ROUNDS 512u
#define MOCK_LUT_FILE_BYTES 4096u
#define MOCK_LUT_LINE_BYTES 64u

static uint64_t mock_state;
static uint8_t mock_work_buffer[MOCK_WORK_BUFFER_BYTES];
static const volatile uint16_t *mock_lut_mapping;

const char *victim_backend_name(void)
{
    return "mock";
}

static uint64_t mock_next(void)
{
    mock_state ^= mock_state << 13;
    mock_state ^= mock_state >> 7;
    mock_state ^= mock_state << 17;
    return mock_state;
}

int victim_backend_prepare(uint64_t test_seed)
{
    mock_state = test_seed;
    if (mock_state == UINT64_C(0)) {
        mock_state = UINT64_C(0x9e3779b97f4a7c15);
    }
    memset(mock_work_buffer, 0, sizeof(mock_work_buffer));
    mock_lut_mapping = NULL;
    const char *lut_path = getenv("VICTIM_MOCK_LUT_PATH");
    if (lut_path != NULL && lut_path[0] != '\0') {
        int descriptor = open(lut_path, O_RDONLY);
        if (descriptor < 0) {
            return 1;
        }
        void *mapping = mmap(NULL, MOCK_LUT_FILE_BYTES, PROT_READ, MAP_SHARED, descriptor, 0);
        (void)close(descriptor);
        if (mapping == MAP_FAILED) {
            return 1;
        }
        mock_lut_mapping = (const volatile uint16_t *)mapping;
    }
    return 0;
}

int victim_backend_decapsulate_once(int class_is_ones,
    uint8_t shared_secret[VICTIM_SHARED_SECRET_BYTES])
{
    for (unsigned round_index = 0u; round_index < MOCK_MIX_ROUNDS; ++round_index) {
        uint64_t value = mock_next();
        size_t offset = (size_t)(value % MOCK_WORK_BUFFER_BYTES);
        mock_work_buffer[offset] ^= (uint8_t)(value >> 32);
    }
    memset(shared_secret, 0, VICTIM_SHARED_SECRET_BYTES);
    if (mock_lut_mapping != NULL) {
        size_t line_offset = (class_is_ones != 0 ? 1u : 0u) * MOCK_LUT_LINE_BYTES;
        uint16_t accumulated = 0u;
        for (unsigned element_index = 0u; element_index < MOCK_LUT_LINE_BYTES / sizeof(uint16_t);
             ++element_index) {
            accumulated ^= mock_lut_mapping[(line_offset / sizeof(uint16_t)) + element_index];
        }
        shared_secret[0] = (uint8_t)(accumulated & 0xffu);
    }
    return 0;
}
