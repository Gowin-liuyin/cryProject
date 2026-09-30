# Linux 与 GNU GCC 的功能与产物验证

功能源码提交：`178ae0b091b7f1a7960db1994ac1c8a73121f3be`。容器内 `git status --porcelain` 为空，
`tracked_delta_sha256` 为空内容摘要 `e3b0c442…7852b855`，即验证对象是干净工作区的该提交。

**这不是 x86_64 验证，也不是时序证据。** 实际平台是 Apple Silicon 主机上的
`linux/arm64` 容器：Linux 6.12.76-linuxkit aarch64、Ubuntu 24.04、**GNU GCC 13.3.0**、
CMake 3.28.3、GNU patch 2.7.6。容器内 `clock_getres(CLOCK_MONOTONIC)` 报告 1000000ns
（1ms），因此容器中的时间数据不能用于任何统计结论，原始 CSV 与报告不归档，
只保留 `.meta` 作为平台与来源记录。

## 本次验证覆盖的内容

verification.log 是单次容器运行的逐字输出，依次包含：

1. 平台与工具版本。
2. CMake 配置与完整构建：**GCC 下零警告**（严格警告加 `-Werror`），两个补丁都无 fuzz 应用。
3. `ctest --output-on-failure`：**13 项全部通过**，包含两版补丁变体的 NIST KAT、
   随机源失败传播、两组等价检查、CLI、采集、统计和向量检查。
4. 三个变体的 `baseline version` 与系统随机源自检。
5. 采集程序冒烟运行（每类 50 次），目的是执行 Linux 专用代码路径，不是采集时间数据。
6. 采集程序记录的平台字段与来源身份。
7. 三个变体编码函数的 GCC 产物反汇编。

## 首次被执行的代码路径

macOS 上从未编译或执行的部分在本次被覆盖：

- 两个补丁的 `#elif defined(__GNUC__)` 分支，即 `__attribute__((optimize("O0"), noinline))`；
  macOS 走的是 `__clang__` 分支。
- `src/measure.c` 中 `hash_running_executable` 的 `/proc/self/exe` 路径：
  `.meta` 中的 `executable_digest` 正常写出，说明该路径工作正常。
- `read_cpu_model` 的 `/proc/cpuinfo` 路径：ARM64 Linux 的 `/proc/cpuinfo` 没有
  `model name` 行，函数按设计回退为 `cpu_model=unavailable`，没有崩溃或输出脏数据。
  目标环境 x86_64 Linux 存在该字段；此处如实记录当前行为，未为非目标平台增加解析分支。

## GCC 产物中的机制

| 变体 | 编码函数内条件分支 | 说明 |
|---|---|---|
| reference | `3e28: b.ne`、`3e38: b.ne` | 两层循环边界，逐位为无分支选择 |
| vulnerable | `2d24: b.eq`、`2d5c: b.ls` | `b.eq` 由消息位控制（`ldrb → asr → and #1 → cmp → b.eq`），两条存储路径分别写 0x681(1665) 与 wzr |
| hardened | `2d64: b.ls` | 仅循环边界，消息位处为掩码运算 |

GCC 用 `cmp` + `b.eq` 表达同一个秘密相关分支，Clang 用 `tbz`；两种产物都保留了目标机制，
防护版在两种编译器下都只剩循环边界分支。地址只对应本目录 verification.log 里的这次构建。

## 复现命令

```sh
docker build 未使用；镜像由基础镜像加装工具链后 commit 得到：
docker run --name baseline-gcc-setup --platform linux/arm64 ubuntu:24.04 sh -c \
    'apt-get -qq update && apt-get -qq install -y --no-install-recommends \
     build-essential cmake git patch perl binutils'
docker commit baseline-gcc-setup baseline-linux-gcc:ubuntu2404

docker run --rm --platform linux/arm64 \
    -v "$PWD":/workspace:ro -v /tmp/linux-gcc-build:/build -w /build \
    baseline-linux-gcc:ubuntu2404 sh -c \
    'git config --global --add safe.directory /workspace
     cmake -S /workspace -B /build/cmake -DCMAKE_C_COMPILER=gcc -DCMAKE_BUILD_TYPE=RelWithDebInfo
     cmake --build /build/cmake --parallel
     ctest --test-dir /build/cmake --output-on-failure'
```

源码目录以只读方式挂载，构建输出只写入容器与 `/tmp`，不改动仓库。
装包步骤需要网络；本机通过 `http_proxy=http://host.docker.internal:7890` 访问镜像源，
该代理只用于安装工具链，不参与构建。仓库本身的构建不联网。

## 结论边界

支持：当前源码在 Linux 上用真实 GNU GCC 能零警告构建、13 项检查全部通过、
两个补丁在 GCC 下都保留了各自的目标机器码形态。
不支持：x86_64 指令集下的产物形态、真实 Linux 主机上的时序统计、容器时间数据的任何结论。
真实 x86_64 Linux 的采集与固定检验仍未执行。
