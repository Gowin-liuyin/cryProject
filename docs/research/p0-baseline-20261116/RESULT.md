# P0 环境基线记录（2026-11-16）

本文件记录 T0.1/T0.2 在 WSL 独立克隆 `~/cryProject-work` 上的复核结果。构建由主控预先
完成，本轮只复跑构建、测试与格式检查并落盘，不改动任何既有源码。

## 1. 环境表

| 项 | 实际值 |
|---|---|
| 仓库 | `/home/ubuntu/cryProject-work`（WSL 内独立克隆，分支 `main`，开工 HEAD `896007ca`） |
| 操作系统 | Ubuntu 22.04.5 LTS（Jammy Jellyfish） |
| 是否 WSL | 是（Ubuntu-22.04，WSL 版本 2，内核 `6.6.114.1-microsoft-standard-WSL2`） |
| 架构 | x86_64 |
| 编译器 | gcc（conda-forge）14.3.0，路径 `/home/ubuntu/miniconda3/bin/gcc` |
| CMake | 4.3.1 |
| 生成器 / 构建类型 | Unix Makefiles / RelWithDebInfo |
| 构建命令 | `cmake --build --preset baseline-wsl --parallel 8` |
| CTest 通过数 | **57/57**（0 失败，总耗时 12.18 s） |
| 测试命令 | `ctest --preset baseline-wsl` |
| format-check 入口 | 根构建目标 `format-check` → `cmake/Format.cmake` |
| format-check 命令 | `cmake --build --preset baseline-wsl --target format-check` |
| clang-format | 21.1.8（pip 版），经 `CLANG_FORMAT_EXECUTABLE=/home/ubuntu/miniconda3/bin/clang-format` 钉版 |
| format-check 结果 | 通过（0 diff，输出 `Built target format-check`） |

## 2. 本地适配声明（原样抄录）

编译用 CMakeUserPresets.json 的 baseline-wsl 预设，增补 -Wno-format-truncation -Wno-format-overflow；原因是 gcc-14 新增分析在 src/attribution_v3_run.c:463 一处既有 snprintf 截断告警撞 -Werror（运行时安全，证据机 gcc 13/clang 18 不触发），仓库代码零改动。

## 3. 复核输出摘要

构建（增量复跑）：

```text
[ 99%] Built target encoder_mask_v4_collect
[100%] Built target hardened_v4_collect
```

CTest：

```text
57/57 Test #57: vector_integrity ...................   Passed    0.06 sec

100% tests passed, 0 tests failed out of 57

Total Test time (real) =  12.18 sec
```

format-check：

```text
Built target format-check
```

## 4. 口径与边界

- `baseline-wsl` 继承仓库 `baseline` 预设（`BUILD_TESTING=ON`、`BASELINE_SANITIZERS=OFF`），
  未开启 `BASELINE_ENABLE_PLATFORM`，因此 57 条用例不含平台统计目标；这与历史参考的
  “ordinary 57” 同组，非 platform 88 / sanitize 57 / historical 61 的同机复算。
- 历史参考值 263/263 是四组配置之和，本机既有测试只覆盖其中 ordinary 组；数值以本机
  实测 57/57 为准，未把其他配置的通过数外推。
- P1 的 `platform_shape_stats` 按任务要求注册在 `cmake/PlatformStats.cmake`，该文件只在
  `BASELINE_ENABLE_PLATFORM=ON` 时被根 CMake include。为不改动已冻结的 `baseline-wsl`
  预设与 57 条基线计数，本轮用同一编译器、同一告警抑制、同一 clang-format 钉版配置的
  独立平台构建树 `build/cmake-platform`（`-DBASELINE_ENABLE_PLATFORM=ON`）编译并运行
  新增目标与用例；该树只是构建产物，不作证据，平台目标也不计入上表的 57 条基线。
- 本轮未新增或改写任何现有测试/源码，未安装系统级或 conda/pip 包。
