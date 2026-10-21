# 第二架构（aarch64）复现环境

## 宿主机

| 项 | 值 |
|---|---|
| 机器 | 本机：Apple Silicon（`uname -m` = `arm64`），CPU 型号 Apple M5 |
| 操作系统 | macOS（Darwin），Docker Desktop 4.67.0（Engine 29.3.1） |
| 容器运行时 | Docker `desktop-linux` context，平台 `linux/arm64` |

## 容器

| 项 | 值 |
|---|---|
| 镜像 | `cryproject-aarch64:20261021` |
| 镜像 ID | `sha256:fc2acac63dac830cc491941c792f7e508851a720cc109c4bdd010ae97581b791` |
| 镜像创建时间 | 2026-10-20T16:18:56Z |
| 基底镜像 | `baseline-linux-gcc:ubuntu2404`（仓库既有的 arm64 基础镜像） |
| 架构 | `aarch64`（`docker image inspect` 的 Architecture = `arm64`，`uname -m` = `aarch64`） |
| 内核 | `Linux 6.12.76-linuxkit #1 SMP Sun Aug 8 14:41:59 UTC 2026 aarch64` |
| 编译器 | `Ubuntu clang version 18.1.3 (1ubuntu1)` |
| Valgrind | `valgrind-3.22.0` |
| CMake | `cmake version 3.28.3` |
| Python | `Python 3.12.3` |

镜像只补了五样东西（clang-18、valgrind、python3、ninja-build、ca-certificates），
其余全部来自仓库既有的 arm64 基础镜像。

## 口径与边界

- **是真 aarch64，不是 QEMU 模拟**：容器内 `uname -m` = `aarch64`，CPU 指令集就是
  ARM64；不是把 x86_64 二进制翻译执行。
- **但是虚拟化的 Linux**：跑在 Docker Desktop 的 Linux 虚拟机里，**不是裸金属**，
  没有 cpufreq 接口、**未锁频**、vCPU 而非独占物理核。
- 因此：**时间证据不与 x86_64 裸金属合并、也不要求同号**；跨架构可比的只有
  **确定性证据**（秘密标记 Memcheck 的错误数与上下文数、产物分支形态）。
- 源码取自仓库的 `git archive HEAD`（提交 `6fc2e6c1`），文件清单与摘要见
  `SOURCE_EXPORT.sha256`；`vendor/liboqs-0.10.0` 用仓库自带的
  `tools/fetch_liboqs_0.10.0.sh` 取钉版树并校验摘要。
- 钉版树的原件不动；已修臂用的是**独立副本**打上 `docs/patches/liboqs-982c762.patch`
  （补丁摘要见远端 `patch-982c762.sha256`）。

## 复现

```sh
git archive --format=tar HEAD | tar -x -C <source_root>
( cd <source_root> && sh tools/fetch_liboqs_0.10.0.sh )
docker run --rm --platform linux/arm64 \
    -v <source_root>:/work/source:ro -v <work_root>:/work/run -w /work/run \
    cryproject-aarch64:20261021 \
    sh /work/source/tools/platform_optlevel/run_aarch64_cells.sh /work/source /work/run/cells
```
