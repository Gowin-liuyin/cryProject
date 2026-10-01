# x86_64 指令集下的产物形态（QEMU 模拟，明确不是时序证据）

**这是 QEMU 模拟的 `linux/amd64` 容器，不是真实 x86_64 主机，本目录不产出任何时序结论。**
容器内 `clock_getres(CLOCK_MONOTONIC)` 实测为 **1000000ns（1ms）**，模拟执行时间在任何意义上
都不是时序证据，连「量级参考」都不写。原始 CSV 与分析报告一律不归档，`analyze` 未运行，
只保留四份 `.meta` 作为平台与来源记录（口径照 `docs/evidence/linux-gcc/`）。
本目录**不改变** README 与 `docs/acceptance.md` 中「仍未执行真实 x86_64 Linux 主机时序实测」这一条。

**预注册凭证（模块零提交）**：`adf9db9d2734837de11274343d3828d49d0f2444`。
本目录的设计与验收标准由该提交固定在 `docs/tasks/four-module-design.md` 第 2 节，
取证全部在该提交之后执行。该凭证只有本地顺序效力，没有第三方时间戳
（本仓库从未 push，`origin/main` 实测为 `gone`，本地提交日期可由作者设置）。

**功能源码提交**：`343a6cb5934bf1241106e4f9742a74c3dae1e5a7`（模块一证据提交，本模块无代码改动）。
**构建时工作区状态（逐字抄录 `.meta` 的 `git_worktree_status_*`）**：

```
git_worktree_status_begin
?? .agents/
git_worktree_status_end
tracked_delta_sha256=e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
```

即**被跟踪文件无任何未提交改动**（`tracked_delta_sha256` 为空内容摘要），
工作区只有一个未跟踪目录 `.agents/`（代理会话草稿，不参与构建）。
取证时本证据目录尚未创建，所以它不出现在上面的状态里。
运行结束后在宿主执行 `git status --porcelain`，输出同为 `?? .agents/`（M2-10），
即容器没有污染仓库——源码以 `:ro` 挂载，全部输出写在容器内 `/build`
（= 宿主 `/tmp/linux-amd64-build`，仓库工作区之外）。

## 为什么说「这是模拟」（M2-2）

四条并列事实（`docker buildx ls` 的标签里**没有** emulated / QEMU 字样，不能从标签下结论）：

1. 宿主 `uname -m` = `arm64`（`Darwin 25.6.0`，macOS 26.6.2 / 25G83，Apple Silicon）。
2. 容器内 `uname -m` = `x86_64`，`uname -a` =
   `Linux a8f082d68ce6 6.12.76-linuxkit #1 SMP Sun Mar  8 14:41:59 UTC 2026 x86_64 x86_64 x86_64 GNU/Linux`。
3. `docker buildx ls` 里没有原生 amd64 节点，只有 `default` 与 `desktop-linux` 两个 docker driver 节点：

```
NAME/NODE           DRIVER/ENDPOINT     STATUS    BUILDKIT   PLATFORMS
default             docker
 \_ default          \_ default         running   v0.28.1    linux/amd64 (+2), linux/arm64, linux/ppc64le, linux/s390x, (2 more)
desktop-linux*      docker
 \_ desktop-linux    \_ desktop-linux   running   v0.28.1    linux/amd64 (+2), linux/arm64, linux/ppc64le, linux/s390x, (2 more)
```

4. **容器内 `/proc/cpuinfo` 是宿主 ARM64 的内容**（`cpuinfo.txt` 逐字归档）：有 `BogoMIPS: 48.00`、
   `Features: fp asimd … sha3 … bti afp ebf16`、`CPU implementer: 0x61`，**没有 x86 的 `model name` 行**
   （容器内 `grep -c "model name" /proc/cpuinfo` 输出 `0`，`cpuinfo_model_name_grep_exit=1`）。

**另外两条本轮直接查到的硬证据（宿主侧独立探测，不属于下面那次归档容器运行，命令与输出逐字照录）**：

```sh
docker run --rm --privileged --platform linux/amd64 baseline-linux-gcc-amd64:ubuntu2404 sh -c \
    'mount -t binfmt_misc binfmt_misc /proc/sys/fs/binfmt_misc 2>/dev/null; cat /proc/sys/fs/binfmt_misc/x86_64'
```

```
enabled
interpreter /usr/bin/qemu-x86_64
flags: POCF
offset 0
magic 7f454c4602010100000000000000000002003e00
mask fffffffffffefe00fffffffffffffffffeffffff
```

即 amd64 可执行文件由 **`/usr/bin/qemu-x86_64`** 这个解释器执行，所以「QEMU 模拟」是实测事实、
不是推断。Docker Desktop 的 Rosetta 选项实测为关闭
（`~/Library/Group Containers/group.com.docker/settings-store.json` 中
`"UseVirtualizationFrameworkRosetta": false`），因此走的不是 Rosetta。

```sh
docker run --rm --platform linux/amd64 baseline-linux-gcc-amd64:ubuntu2404 sh -c 'head -8 /proc/self/maps'
```

```
555555556000-555555558000 r--p 00000000 00:3b 202432                     /usr/bin/head
…
ffff847ec000-ffff84814000 r--p 00000000 00:3b 203006                     /usr/lib/x86_64-linux-gnu/libc.so.6
```

`0xffff847ec000` 超出 x86_64 用户态的规范地址范围，是宿主 ARM64 的地址布局透过
QEMU 用户态模拟暴露出来的，同样指向模拟而非原生执行。

## 平台与工具版本（容器内，逐字见 `verification.log`）

- Ubuntu 24.04，Linux 6.12.76-linuxkit **x86_64**。
- `gcc (Ubuntu 13.3.0-6ubuntu2~24.04.1) 13.3.0`（`/usr/bin/gcc`，真实 GNU GCC）。
- `cmake version 3.28.3`。
- `GNU patch 2.7.6`。
- `GNU objdump (GNU Binutils for Ubuntu) 2.42`；`objdump --help` 实测支持
  `--disassemble=<sym>`（GNU 拼写，与 LLVM 的 `--disassemble-symbols=` 不同）。
- `OpenSSL 3.0.13 30 Jan 2024`（装进镜像，M2-11 主路线用它算 SHA3-256）、容器内 `/usr/bin/shasum`。
- 宿主：`docker version` 客户端 29.3.1 / `darwin/arm64`，服务端 Docker Desktop 4.67.0 (222858)
  引擎 29.3.1 / `linux/arm64`，containerd v2.2.1，runc 1.3.4。
  宿主 OpenSSL 3.5.5、shasum 6.02（只用于出容器后的核对）。

## 本目录结论所覆盖的构建配置（逐字抄录 `.meta` 实测值）

```
build_system=CMake 3.28.3
generator=Unix Makefiles
configuration=RelWithDebInfo
compiler_flags= -O2 -g -DNDEBUG -std=c11
compile_options=-Wall -Wextra -Wpedantic -Wshadow -Wconversion -Wstrict-prototypes -Werror
compile_definitions=MLK_CONFIG_FILE="baseline_config.h"
sanitizers=OFF
compiler_command=/usr/bin/gcc
```

**生成器是容器内默认的 `Unix Makefiles`**（照 `docs/evidence/linux-gcc` 先例不指定 `-G`），
与模块一、模块三的 `Ninja` **不是同一配置**；地址与反汇编结论不跨构建复用。
本目录的全部地址只对应这一次构建。

## 复现命令

建镜像（本机 apt **需要**代理，下面两个 `-e` 就是全部代理设置；实际执行的就是这两条）：

```sh
docker run --name baseline-gcc-amd64-setup --platform linux/amd64 \
    -e http_proxy=http://host.docker.internal:7890 \
    -e https_proxy=http://host.docker.internal:7890 \
    ubuntu:24.04 sh -c \
    'apt-get -qq update && apt-get -qq install -y --no-install-recommends \
     build-essential cmake git patch perl binutils openssl'
docker commit baseline-gcc-amd64-setup baseline-linux-gcc-amd64:ubuntu2404
```

apt 清单里的 `openssl` 是本模块显式加的（`docs/evidence/linux-gcc` 那份清单没有 `openssl`、
也没有 `python3`），因为 M2-11 必须用 SHA3-256 与 `.meta` 的 `executable_digest` 对照，
`shasum` 算不出 SHA3-256。`apt` 步骤需要网络，**构建与测试本身不联网**。
镜像建好后 `apt_exit=0`，不需要 `attempt-failure.log`（本目录因此没有这个文件）。

取证（**单次容器运行**，在仓库根目录执行；`/build` 绑定到宿主 `/tmp/linux-amd64-build`，
这是证据出容器的唯一路径，用的是「可写宿主挂载」而不是 `docker cp`）：

```sh
mkdir -p /tmp/linux-amd64-build
docker run --rm --platform linux/amd64 \
    -v "$PWD":/workspace:ro -v /tmp/linux-amd64-build:/build -w /build \
    baseline-linux-gcc-amd64:ubuntu2404 sh -c '
      set -u
      : > /build/step-exits.txt
      ...（平台事实、cpuinfo）
      git config --global --add safe.directory /workspace
      cmake -S /workspace -B /build/cmake -DCMAKE_C_COMPILER=gcc \
          -DCMAKE_BUILD_TYPE=RelWithDebInfo -DBUILD_TESTING=ON \
          -DBASELINE_SANITIZERS=OFF > /build/configure.log 2>&1 || {
          echo "configure_exit=$?" >> /build/step-exits.txt; exit 1; }
      echo "configure_exit=0" >> /build/step-exits.txt
      cmake --build /build/cmake --parallel > /build/build.log 2>&1
      echo "build_exit=$?" >> /build/step-exits.txt
      grep -n "with fuzz" /build/build.log
      echo "fuzz_grep_exit=$?" >> /build/step-exits.txt
      grep -nE "warning:|Warning:" /build/build.log
      echo "build_warning_grep_exit=$?" >> /build/step-exits.txt
      ctest --test-dir /build/cmake -N > /build/ctest-list.log 2>&1
      echo "ctest_list_exit=$?" >> /build/step-exits.txt
      ctest --test-dir /build/cmake --output-on-failure > /build/ctest.log 2>&1
      echo "ctest_exit=$?" >> /build/step-exits.txt
      ...（产物前置条件硬失败检查、M2-6、冒烟采集、M2-7、M2-7a、M2-8、M2-11）
    ' 2>&1 | tee /tmp/linux-amd64-build/verification.log
```

`verification.log` 是这一次运行的逐字输出（宿主 `tee`）；各步的详细输出已分别重定向到
`configure.log` / `build.log` / `ctest-list.log` / `ctest.log`，两者都归档、不互相替代。
脚本用 `set -u` **而不是** `set -eu`：只有「`cmake` 配置失败」与「进入反汇编前八个产物缺失」
两处硬失败退出，其余被判定步骤一律「记录退出码后继续」，这样任何一步失败时前面的产物仍落盘。
每个被判定步骤的实测退出码在 `step-exits.txt`（共 53 行），下面「未能完成的项」一节引用它。

出容器后由宿主复制证据进本目录、算 `binaries.sha256` 与 `SHA256SUMS`，核对见 `record-checks.txt`。
目录核对：

```sh
shasum -a 256 -c docs/evidence/linux-amd64/SHA256SUMS   # 在仓库根目录执行
```

## 构建与测试结果

- **配置**：`configure_exit=0`，`The C compiler identification is GNU 13.3.0`。
- **完整构建**：`build_exit=0`。**严格警告 + `-Werror` 下零警告**——
  `compile_commands.json` 的 38 条编译命令每条都带
  `-Wall -Wextra -Wpedantic -Wshadow -Wconversion -Wstrict-prototypes -Werror`，
  而 `grep -nE "warning:|Warning:" /build/build.log` 输出为空、`build_warning_grep_exit=1`。
  因此 M2-4 不需要任何 `fix:` 提交，也没有 vendor 警告要记。
- **M2-4a fuzz 门禁，两次都过**（判据：`exit=1` 即无匹配）：
  - 容器内 `grep -n "with fuzz" /build/build.log` → 空输出，`fuzz_grep_exit=1`；
  - 宿主对归档副本 `grep -n 'with fuzz' docs/evidence/linux-amd64/build.log` → 空输出，`exit=1`。

  `cmake/PrepareVariant.cmake` 只用 `patch -p1 -i`、**不带** `--no-fuzz`，所以 fuzz 会被静默接受；
  本模块全部结论都是对打完补丁的产物做反汇编，所以这道门禁必须跑。
  容器内用 **GNU patch 2.7.6** 重新应用三个补丁，`build.log:4-6` 三行均为
  `patching file mlkem/src/compress.c`，无 `Hunk #… succeeded … with fuzz`。
- **M2-5 `ctest`**：`ctest --test-dir /build/cmake -N` 实测 **16 项**（`ctest-list.log`），
  `ctest --test-dir /build/cmake --output-on-failure` **16/16 全部通过**，
  `ctest_exit=0`，`Total Test time (real) = 6.53 sec`（见 `ctest.log`）。
  **QEMU 下没有出现失败或超时**，因此没有为通过而缩减样本、放宽断言或跳过任何测试。
  16 项即未降级的预期值（模块一未触发 0.5 的依赖降级规则）。
  这 6.53 秒是模拟环境下的挂钟时间，**不是任何性能或时序结论**。
- **M2-6 四个变体**（`step-exits.txt` 中四个 `*_version_exit=0` 与四个 `*_selftest_exit=0`）：
  `baseline version` 分别输出 `reference / vulnerable / hardened / deployable ML-KEM-768 FIPS203`，
  `baseline selftest`（系统随机源）全部成功。
- **冒烟采集**：四个变体各每类 50 次，`RUN_ID=smoke-<variant>`、种子 `20260930`，
  四个 `*_smoke_exit=0`。目的只是执行 Linux 代码路径并记录平台字段，
  CSV 写在 `/tmp/linux-amd64-build/` 且**不归档**。
- **M2-3 时钟**：四份 `.meta` 的 `clock=CLOCK_MONOTONIC`、`time_unit=ns`、
  **`clock_resolution_ns=1000000`**（即 1ms，由 `measure` 调 `clock_getres(CLOCK_MONOTONIC)` 实测）。
  与 `docs/evidence/linux-gcc` 的容器同为 1ms。无论这个值是多少，都不改变开头那条声明。
- **M2-9 `read_cpu_model`**：四份 `.meta` 实测 `cpu_model=unavailable`。
  容器 `/proc/cpuinfo` 是宿主 ARM64 字段、没有 `model name` 行（`cpuinfo.txt`），
  函数按设计回退，没有崩溃或写出脏数据。**这不能证明真实 x86_64 主机上的行为**——
  真实 x86_64 Linux 有 `model name` 字段，本次没有覆盖那条路径。
- **M2-8 便携 C 后端**：`grep -c "native/x86_64" compile_commands.json` = 0
  （`x86_64_source_grep_exit=1`）、`grep -nE "avx2|AVX2|mavx2"` 对
  `compile_commands.json` 与 `build.log` 均无命中（`avx2_grep_exit=1`）、
  `grep -c "MLK_CONFIG_USE_NATIVE_BACKEND" compile_commands.json` = 0
  （`native_backend_grep_exit=1`），编译命令里也没有任何 `-m…` 架构选项。
  四个变体的实际编译命令（`compile_commands.json`）：reference 编译 `/workspace/src/kernel.c`，
  三个补丁变体编译 `/build/cmake/<variant>_kernel.c`，其
  `-I/build/cmake/<variant>-source/mlkem` 排在 `-I/workspace/vendor/mlkem-native/mlkem` **之前**，
  即链接进去的是构建目录里的补丁副本，vendor 原文未被修改。
  **因此本目录结论只覆盖便携 C 后端**，不覆盖任何 AVX2 / 原生后端产物。

## 产物机制：x86_64 GCC 怎么表达那个秘密相关分支（M2-7）

反汇编命令（四份离线符号副本）：

```sh
objdump -d --disassemble=baseline_native_poly_frommsg \
    /build/cmake/<variant>/measure > {variant}-encoder-amd64-gcc.txt
```

### 第 1 步：逐条列出**所有**条件跳转（地址 + 助记符，一条不漏）

检索命令为 `grep -nE "\b(j[a-z]+)\b" {variant}-encoder-amd64-gcc.txt`（见
`call-site-counts-amd64.txt` 每个变体末段，**含无条件 `jmp`**，下表按归属分开标注）。

| 变体 | 文件:行 | 地址 | 助记符 | 是否条件跳转 |
|---|---|---|---|---|
| reference | `reference-encoder-amd64-gcc.txt:34` | `0x46c9` | `jne 46a8` | 条件 |
| reference | `reference-encoder-amd64-gcc.txt:38` | `0x46d8` | `jne 46a0` | 条件 |
| vulnerable | `vulnerable-encoder-amd64-gcc.txt:22` | `0x2ff7` | `jmp 3041` | 无条件（循环入口） |
| vulnerable | `vulnerable-encoder-amd64-gcc.txt:37` | `0x301f` | `je 3030` | 条件 |
| vulnerable | `vulnerable-encoder-amd64-gcc.txt:41` | `0x302e` | `jmp 303d` | 无条件（if/else 汇合） |
| vulnerable | `vulnerable-encoder-amd64-gcc.txt:47` | `0x3048` | `jbe 2ff9` | 条件 |
| hardened | `hardened-encoder-amd64-gcc.txt:22` | `0x2ff7` | `jmp 3044` | 无条件（循环入口） |
| hardened | `hardened-encoder-amd64-gcc.txt:48` | `0x304b` | `jbe 2ff9` | 条件 |
| deployable（离线副本，**未被调用**） | `deployable-encoder-amd64-gcc.txt:34` | `0x46cd` | `jne 46a0` | 条件 |
| deployable（内联段，**实际执行**） | `deployable-caller-indcpa-enc-amd64-gcc.txt:78` | `0x6076` | `jne 6048` | 条件 |

deployable 内联段的检索范围是 `deployable-caller-indcpa-enc-amd64-gcc.txt` 的第 **55–78** 行
（地址 `0x6020`–`0x6076`），该区间内只有上表那一条跳转，且是条件跳转。

### 第 2 步：逐条标注归属，并给出标注依据（M2-7 / 发现 15 口径）

| 地址 | 归属 | 依据（影响标志位的上一条指令及其操作数来源） |
|---|---|---|
| reference `0x46c9` | **循环边界** | 前一条 `0x46c6 cmp $0x8,%ecx`；`%ecx` 由 `0x46a0 xor %ecx,%ecx` 置零、`0x46ba add $0x1,%ecx` 递增，上界 8 = 每字节的位数，即上游内层位循环 |
| reference `0x46d8` | **循环边界** | 前一条 `0x46d2 cmp $0x100,%edi`；`%edi` 由 `0x469d xor %edi,%edi` 置零、`0x46cb add $0x8,%edi` 每轮加 8，上界 256 = `MLKEM_N`，即上游外层字节循环（32 轮 × 8） |
| vulnerable `0x301f` | **消息位相关** | 前一条 `0x301d test %eax,%eax`；`%eax` 来自 `0x301a and $0x1,%eax` ← `0x3018 mov %edx,%eax` ← `0x3016 sar %cl,%edx`（`%cl` = `coefficient_index & 7`，来自 `0x3011 and $0x7,%eax`）← `0x300b movzbl %al,%edx` ← `0x3008 movzbl (%rax),%eax`，而 `%rax` = `-0x20(%rbp)`（`0x2fec` 存入的第二个参数 `message_bytes`）+ `coefficient_index >> 3`（`0x2ffc shr $0x3,%eax`）。**操作数链可追到消息字节取位**；两条分支分别写 `0x3028 movw $0x681,(…)` 与 `0x3037 movw $0x0,(…)` |
| vulnerable `0x3048` | **循环边界** | 前一条 `0x3041 cmpl $0xff,-0x4(%rbp)`；`-0x4(%rbp)` 是栈上系数计数器（`0x2ff0` 置 0、`0x303d addl $0x1`），上界 255（`jbe` 含等号，共 256 轮） |
| hardened `0x304b` | **循环边界** | 前一条 `0x3044 cmpl $0xff,-0x4(%rbp)`，同 vulnerable 的栈上系数计数器。消息位处只剩算术：`0x301a and $0x1,%eax` → `0x3025 neg %eax` → `0x302f and $0x681,%ax` → `0x303c mov %cx,(…)`，**没有任何条件跳转消费这条链产生的标志位** |
| deployable 离线副本 `0x46cd` | **循环边界** | 前一条 `0x46c6 cmp $0x100,%rdx`；`%rdx` 由 `0x4694 xor %edx,%edx` 置零、`0x46c2 add $0x1,%rdx` 递增，上界 256 |
| deployable 内联段 `0x6076` | **循环边界** | 前一条 `0x606f cmp $0x100,%rdx`；`%rdx` 由 `0x6020 xor %edx,%edx` 置零、`0x606b add $0x1,%rdx` 递增，上界 256。消息字节在 `0x6056 and (%r11,%rcx,1),%al` 取入（`%r11` = `0x5fc5 mov %rsi,%r11`，`%rsi` 是 `mlk_indcpa_enc` 的第二个参数 `m`，即 `message_bytes`；`%rcx` = `coefficient_index >> 3`），之后只流向 `0x605a movzbl` → `0x605d neg` → `0x605f sar $0x10` → `0x6062 and $0x681,%ax` → `0x6066 mov %ax,(%r15,%rdx,2)` 这条算术链，不被任何条件跳转消费 |

**无法判定归属的条件跳转：无**（上表八条条件跳转全部有可追踪的操作数链）。
按设计口径，归属无法判定的条件跳转应按 0.5 记缺口、**不得默认算作循环边界**；本次没有触发该条。

### 第 3 步：x86_64 下的助记符与 ARM64 的对照（本模块的有价值结论）

**同一个秘密相关分支，三种工具链的表达各不相同**：

| 工具链 / 架构 | 秘密相关分支的表达 | 来源 |
|---|---|---|
| Apple Clang 21 / ARM64 | `tbz w8, #0x0, …`（直接测位，无显式比较） | `docs/evidence/deployable/vulnerable-encoder-arm64.txt:25` |
| GNU GCC 13.3.0 / ARM64 | `cmp` + `b.eq` | `docs/evidence/linux-gcc/README.md` 的表 |
| **GNU GCC 13.3.0 / x86_64（本目录）** | **`and $0x1,%eax` + `test %eax,%eax` + `je`** | `vulnerable-encoder-amd64-gcc.txt:35-37` |

x86_64 GCC 既不像 Clang 那样用单条测位跳转，也不复用 ARM64 的 `cmp`：它先把位掩到 `%eax`
的最低位，再用 `test %eax,%eax` 自比置标志位，然后 `je`。
**三种产物都保留了目标机制**（消息位直接控制一条条件跳转，两条路径分别写
`0x681`=1665 与 0），所以缺陷变体的机制在 x86_64 / GNU GCC 下同样成立。

**循环边界助记符按实测填写（设计明确要求不先写死）**：x86_64 GCC 13.3.0 / RelWithDebInfo 下
实测为 **`jne`**（reference 的两层循环、deployable 的系数循环，`-O2` 正常优化）与
**`jbe`**（vulnerable / hardened 两个 `optimize("O0")` 变体的系数循环，比较写成 `cmpl $0xff`）。
ARM64 侧既有实测为 `b.ne`、`b.lo`（Apple Clang）与 `b.ls`（GNU GCC）。
归属判定依据的是上一条影响标志位的指令的操作数链，不是助记符清单。

### 第 4 步：防护/可部署变体在 x86_64 产物里是否同样只剩循环边界分支

**是。**

- **hardened**：编码函数内唯一的条件跳转是 `0x304b jbe`（系数计数器 vs `0xff`），
  消息位处只有 `and $0x1` → `neg` → `and $0x681` → 存储的算术链。
  与 ARM64（Apple Clang、GNU GCC 两版）结论一致。
- **deployable**：实际执行的内联段（`0x6020`–`0x6076`）里唯一的条件跳转是
  `0x6076 jne`（系数计数器 vs `0x100`），消息字节只参与掩码算术。
  **即「在正常优化下，这种源码形态在 x86_64 GCC 产物里同样没有被重新引入消息位相关条件分支」。**
- **reference**：两条条件跳转都是循环边界。值得注意的差别：x86_64 GCC **没有展开**
  上游的内层 8 次位循环（保留 `cmp $0x8,%ecx` 的内层回边），而 ARM64 Apple Clang 把它完全展开、
  只剩一条外层回边。这是同一份上游源码在两套工具链下的优化差异，不改变「只有循环边界分支」的判定。

## 调用路径核对（M2-7a）：deployable 在 x86_64 GCC 下同样被内联

这一步**独立重做**，不套用 ARM64 结论（GCC 13 的内联决策与 Apple Clang 21 无关）。
调用者是 `mlk_indcpa_enc`，**不是** `mlk_indcpa_dec`：解封装路径为
`dec → indcpa_enc`（隐式拒绝所需的重加密）`→ poly_frommsg`；`indcpa_dec` 只调 `poly_tomsg`。

命令（GCC 下符号无前导下划线；`objdump --help` 实测支持 `--disassemble=<sym>`）：

```sh
objdump -d --disassemble=baseline_native_indcpa_enc \
    /build/cmake/<variant>/measure > {variant}-caller-indcpa-enc-amd64-gcc.txt
objdump -d /build/cmake/deployable/measure > deployable-path-amd64-gcc.txt
```

层级规则按实测走：四个变体 `grep -c "call.*<baseline_native_indcpa_enc>"`（全二进制）
**均为 2**，所以调用者一律取 `baseline_native_indcpa_enc`，没有一个需要退到 `baseline_native_dec`。

内联判据正则与 M1-5a **完全相同**，逐字传给 grep 的形式是
`(#|\$)0x681|[#$ ]1665\b`（`MLKEM_Q_HALF` = 1665 = `0x681`），已写进
`call-site-counts-amd64.txt` 首行。**`0x681` 在 GNU objdump / x86_64 下的实际印法本次实测为
`$0x681`**（如 `and $0x681,%ax`、`movw $0x681,(%rax,%rdx,2)`），正则的 `\$0x681` 分支命中，
无需扩充正则，也没有落入「三种印法都不命中」的情形。

| 变体 | `poly_frommsg` 调用点计数与地址 | 调用者 `grep -nE` | 全二进制 `grep -cE`（特异性对照） | 情况 |
|---|---|---|---|---|
| reference | 1（`0x6073`） | 未命中，`exit=1` | 1（`0x46bd`，在编码函数内） | **情况 1** |
| vulnerable | 1（`0x6093`） | 未命中，`exit=1` | 1（`0x3028`，在编码函数内） | **情况 1** |
| hardened | 1（`0x60a3`） | 未命中，`exit=1` | 1（`0x302f`，在编码函数内） | **情况 1** |
| deployable | **0** | **命中**：`:74 6062: and $0x681,%ax`，`exit=0` | **2** | **情况 2（被内联）** |

实际命令、命中行与空结果逐字记录在 `call-site-counts-amd64.txt`。

**deployable 落在情况 2：`poly_frommsg` 调用点计数为 0，GCC 13.3.0 把它内联进了
`baseline_native_indcpa_enc`。因此 `deployable-encoder-amd64-gcc.txt`（离线副本）不构成产物证据，
deployable 的 x86_64 产物形态结论来自 `deployable-caller-indcpa-enc-amd64-gcc.txt` 的内联段
（第 55–78 行，地址 `0x6020`–`0x6076`）。**
离线副本仍然存在，是因为 `mlk_poly_frommsg` 是 `MLK_INTERNAL_API`（展开为空、外部链接），
符号必然被发出；但它没有任何调用点，所以不是执行路径。
deployable 按设计不带任何 `__attribute__`（含 `noinline`），内联是预期后果；
设计明令**不得**为了拿到独立符号而给它加回 `noinline`，本目录遵守该约束。
**这与模块一在 Apple Clang 21 / ARM64 上的实测结论相同（同样是情况 2），但是两次独立实测，
不是互相套用。**

全二进制正则计数 2 的两处落点已逐处写明：一处在从未被调用的离线副本
（`deployable-path-amd64-gcc.txt` 第 2719 行，`0x46ba`），一处在内联段（第 4319 行，`0x6062`）。
另三个变体全二进制计数均为 1，就在各自的编码函数内，调用者命中 0，
说明这不是只对 deployable 放宽的检查。

「按系数推进的 256 次循环结构」**只作佐证、不作判据**（grep 表达不出「256 次系数循环」）：
正则命中后人工读 `deployable-caller-indcpa-enc-amd64-gcc.txt` 第 55–78 行，
看到 `xor %edx,%edx` 起始、`add $0x1,%rdx` 递增、`cmp $0x100,%rdx` + `jne` 回边的单层 256 次
系数循环，每轮按 `coefficient_index & 7` 取位掩码、按 `coefficient_index >> 3` 取消息字节，
与 deployable 补丁的源码形态逐项对应。

`deployable-path-amd64-gcc.txt` 是 `/build/cmake/deployable/measure` 的**全二进制**反汇编
（6751 行），`grep -c "call.*<baseline_native_poly_frommsg>"` 实测为 **0**，
所以调用点地址一栏为空。另三个变体的全二进制反汇编只用于计数与特异性对照，按既有口径不归档
（模块一同样只归档 deployable 一份全二进制）。

## 摘要核对（M2-11）

走的是**主路线**（容器内 `openssl dgst -sha3-256`），不是备用路线。
`.meta` 的 `executable_digest_algorithm=SHA3-256`，所以只有 SHA3-256 能与它对照。
四份 `.meta` 的 `executable_digest` 与容器内 SHA3-256 逐个相同，
容器内与宿主的 `shasum -a 256` 八行逐行相同。全部逐字输出见 `record-checks.txt`。
`binaries.sha256` 是**宿主**算的，对象是
`/tmp/linux-amd64-build/cmake/<variant>/{baseline,measure}` 这八个宿主可见的构建目录产物，
路径逐字保留，**二进制副本未拷进仓库**（与 `docs/evidence/mitigation/binaries.sha256` 同口径）。
`.meta` 的 `build_input_manifest_*` 段含每个源文件的 SHA-256，一并作为来源记录归档。

## 结论边界（支持什么／不支持什么）

**支持**：

- 当前源码在 **QEMU 模拟的 linux/amd64** 上用真实 GNU GCC 13.3.0 能**零警告**（严格警告 + `-Werror`）
  完整构建，`ctest` 实测 16 项**全部通过**，三个补丁在 GNU patch 2.7.6 下**无 fuzz 应用**。
- x86_64 GCC 把缺陷变体的那个秘密相关分支表达为 `and $0x1` + `test` + `je`，
  与 ARM64 GCC 的 `cmp` + `b.eq`、ARM64 Clang 的 `tbz` 并列记录；目标机制在 x86_64 下同样保留。
- hardened 与 deployable 在 x86_64 产物里**同样只剩循环边界条件分支**
  （`jbe` / `jne`，操作数链为系数计数器），消息位只参与掩码算术。
- deployable 在 GCC 13.3.0 / `-O2` 下**被内联**（情况 2），结论对象是
  `baseline_native_indcpa_enc` 里的内联段；这是独立于 ARM64 的第二次实测。
- 本构建是**便携 C 后端**：无 `src/native/x86_64` 源文件、无 AVX2 选项、无原生后端宏。

**不支持**：

- **不支持任何时序结论。** 这是 QEMU 用户态模拟（解释器实测为 `/usr/bin/qemu-x86_64`），
  不是真实 x86_64 主机；容器 `clock_getres(CLOCK_MONOTONIC)` 为 1ms。
  模拟执行时间（含 `ctest` 的 6.53 秒）在任何意义上都不是时序证据，连「量级参考」都不写。
  CSV 与报告不归档，`analyze` 未运行。
- **不支持**「真实 x86_64 Linux 主机已验证」。真实 x86_64 Linux 主机上的采集与固定检验
  **仍未执行**，这条未闭合项不因本目录而改变。QEMU 模拟、容器、交叉编译、macOS/ARM
  一律不得表述为真实 x86_64 Linux 实测。
- **不支持**任何 AVX2 / 原生后端产物形态的结论（本构建没有编译那些源文件）。
- 反汇编结论只覆盖 **GNU GCC 13.3.0 / x86_64 / RelWithDebInfo / 容器内默认 Unix Makefiles 生成器 /
  上面写死的那条配置命令**这一配置，和本次构建的这些地址。
  与模块一、模块三的 Ninja 构建**不是同一配置**，地址不跨构建复用。
- **不支持**「`read_cpu_model` 在 x86_64 Linux 上的行为已验证」：本次 `/proc/cpuinfo` 是宿主
  ARM64 内容、`cpu_model=unavailable`，真实 x86_64 的 `model name` 解析路径未被覆盖。
- **deployable 的产物证据与另三个变体不是同一粒度**：它落在情况 2（被内联），
  结论对象是 `baseline_native_indcpa_enc` 里的内联段；另三个变体的结论对象是独立符号。
  四个变体的产物形态**不能并列成一张等价的表**，上面的条件跳转表已按
  「离线副本（未被调用）」与「内联段（实际执行）」分行标注。
- 本目录不含二进制副本、不含 CSV、不含 `.report`、不含任何统计结论。

## 未能完成的项

**无。** M2-1 至 M2-12 全部在本机闭合。`step-exits.txt` 共 53 行实测退出码，
逐项对照如下（`grep` 类步骤的 `exit=1` 表示「无匹配」，即判据通过）：

- `configure_exit=0`、`build_exit=0`、`ctest_list_exit=0`、`ctest_exit=0`、
  `artifact_precondition_exit=0`（八个产物齐备，没有触发第二处硬失败）。
- `fuzz_grep_exit=1`（无 fuzz，通过）、`build_warning_grep_exit=1`（零警告）、
  `cpuinfo_model_name_grep_exit=1`（无 `model name` 行）、
  `x86_64_source_grep_exit=1` / `avx2_grep_exit=1` / `native_backend_grep_exit=1`（便携 C 后端）。
- 四个 `*_version_exit=0` 与四个 `*_selftest_exit=0`、四个 `*_smoke_exit=0`、
  十三个 `*_objdump_exit=0`、`compile_commands_copy_exit=0`、
  八个 `*_openssl_sha3_exit=0` 与八个 `*_shasum_exit=0`。

没有触发 0.5 的缺口记录规程（因此本目录没有 `attempt-failure.log`），
也没有触发模块间依赖降级规则（四个变体全部可用，`ctest -N` 实测 16 项即未降级的预期值）。
**仍然未闭合、且不属于本模块范围的那一项**：真实 x86_64 Linux 主机上的时序采集与固定检验。
本模块只闭合「x86_64 指令集下的产物形态与功能构建」，不闭合时序。
