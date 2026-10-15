# 根集成构建并行度修复与全量验证（2026-10-16，本机 macOS/ARM）

任务：`task-1`（T1 修复根集成构建并行度并全量验证）。本目录是这次修复的原始证据与报告。

## 0. 结论摘要

| 项目 | 结果 | 证据 |
| --- | --- | --- |
| 问题复现（修前） | `make -j4` 输出 `make[1]: warning: jobserver unavailable: using -j1.`，且实际退回串行 | `jobserver-before.log:6` |
| 四个入口（`make -j4` / `make -j` / `make test` / `make sanitize`） | 全部 exit=0，jobserver 警告 0 条 | `jobserver-after.log`、`jobserver-unj.log`、`make-test.log`、`make-sanitize.log`；计数见 `warning-scan.log` 末段 |
| 普通配置全量构建 | 编译 169 个 C 对象、构建 96 个 target、87 次链接，exit=0 | `build-ordinary.log` |
| 普通 CTest | **57/57 通过**（0 失败），29.02 s | `ctest-ordinary.log` |
| sanitize（ASan/UBSan）全量构建 + CTest | 构建 exit=0；**57/57 通过**，19.68 s | `build-sanitize.log`、`ctest-sanitize.log` |
| `format-check` | 通过（exit=0），覆盖 107 个文件；同工具敏感性对照返回非 0 | `format-check.log` |
| 并行度真实性 | 同一源码全量构建：`BUILD_JOBS=1` 31 s，4 路并行 11 s | `parallelism-proof.log` |
| 改动范围 | 仅根 `Makefile`（11 增 4 删）；未提交 | `makefile-diff.txt` |

边界与未决项见第 9 节：本机为 macOS/ARM，不代表 x86_64 Linux；过程中还发现一个与本修复无关的、依赖 OpenSSL 3 `dgst` 的既有测试环境问题（第 8.1 节）。

## 1. 环境与版本

来自 `source-state-before.txt`（2026-10-16 02:10:32 CST）：

| 项目 | 值 |
| --- | --- |
| 主机 / 架构 / 系统 | `yindeMacBook-Air.local`，`arm64`，macOS 26.6.2 |
| CPU | Apple M5 |
| CMake | 4.3.2（`~/.local/bin/cmake`） |
| make | GNU Make 3.81（macOS `/usr/bin/make`，jobserver 变量为 `--jobserver-fds=`） |
| Ninja | 1.13.0.git.kitware.jobserver-pipe-1（仅用于对照实验，未用于交付构建） |
| C 编译器 | Apple clang 21.0.0（`/usr/bin/cc`） |
| clang-format | Apple clang-format 21.0.0，经 `xcrun --find clang-format` 命中（PATH 中无 `clang-format`） |
| git | `main` 分支；采集期 HEAD 从 `47033dd8` 变到 `efca8a1`（期间主控提交，不影响构建输入内容） |

## 2. 问题复现（修复前）

修复前的原文：

```
$ make -j4
cmake -S . -B "build/cmake"
cmake --build "build/cmake" --parallel
make[1]: warning: jobserver unavailable: using -j1.  Add `+' to parent make rule.
```

完整输出见 `jobserver-before.log`（该文件是修复前 Makefile 的原样输出，第 6 行即告警）。

机制：`make -j4` 通过 MAKEFLAGS 把 jobserver 描述符交给子进程，但 `cmake --build` 派生 make 时没有把这些描述符传下去（实测：`+$(MAKE)` 直接递归能拿到，`+cmake --build` 拿不到）。子 make 看到 jobserver 标记却拿不到描述符，于是打印告警并退回 `-j1`。所以这不只是噪声：**`make -j4` 实际上被降级成了串行构建**。

## 3. 候选修法与实测矩阵

为了不靠猜，先用一个 4 个互不依赖 target（各 `sleep 1`）的最小工程逐一变体实测（脚本与工程在 `jobserver-matrix/`，结果 `jobserver-matrix/jobserver-matrix-results.txt`，可复算：`bash jobserver-matrix/run-matrix.sh`）。串行约 4.2 s、4 路并行约 1.1 s，因此 `real` 一列能直接区分"真并行"和"退回 -j1"。

| 变体 | `make -j4` | `make -j` | `make`（无参） |
| --- | --- | --- | --- |
| `cur`：修前写法（`--parallel` 不带数字） | 4.26 s，**告警 jobserver unavailable** | 1.12 s 无告警 | 1.13 s |
| `plus_bare`：只加 `+`（GNU make 官方建议） | 4.25 s，**同样告警**（`+` 不够） | 1.14 s | 1.12 s |
| `plus_jobs`：`+` + `--parallel 4` | 1.14 s，**告警 -jN forced in submake** | 1.14 s | 1.12 s |
| `makeflags_clear`：recipe 前 `MAKEFLAGS=` + `--parallel 4`（**本次采用**） | 1.14 s，**无告警** | 1.16 s 无告警 | 1.13 s 无告警 |
| `ninja_plus`：Ninja 生成器 + `+` + `--parallel 4` | 1.12 s 无告警 | 1.11 s | 1.10 s |
| `ninja_plain`：Ninja 生成器 + `--parallel 4` | 1.09 s 无告警 | 1.10 s | 1.09 s |

结论：

1. **只加 `+` 无效**：`cmake --build` 不会把 jobserver 描述符转交子 make，告警与串行降级都还在。
2. **`+` 加显式并行度会换一条告警**：`-jN forced in submake: disabling jobserver mode`。仍是 jobserver 相关告警。
3. 在 Unix Makefiles 下，唯一实测"三种调用都零告警且真并行"的写法是清掉继承的 MAKEFLAGS 并显式给并行度。
4. Ninja 也零告警，但没有采用，理由见第 4 节。

另有一条被否掉的思路：在 Makefile 里写 `MAKEFLAGS := $(filter-out ...)`。实测无效——make 在导出环境时会把自己的 jobserver 标记重新加回去（`$(MAKEFLAGS)` 赋值只影响 make 自己的解析，不影响 recipe 环境）。只有 recipe 行上的 shell 前置赋值 `MAKEFLAGS=` 才真正生效。

## 4. 最终改动（根 Makefile）

`git diff -- Makefile` 全文见 `makefile-diff.txt`；改动前/后副本为 `Makefile.before.txt` / `Makefile.after.txt`。

```make
BUILD_JOBS ?= 4
all: configure
	MAKEFLAGS= $(CMAKE) --build "$(BUILD_DIR)" --parallel $(BUILD_JOBS)
reference vulnerable: configure
	MAKEFLAGS= $(CMAKE) --build "$(BUILD_DIR)" --target $@ --parallel $(BUILD_JOBS)
sanitize:
	$(CMAKE) --preset sanitize
	MAKEFLAGS= $(CMAKE) --build --preset sanitize --parallel $(BUILD_JOBS)
	$(CTEST) --preset sanitize
clean:
	MAKEFLAGS= $(CMAKE) --build "$(BUILD_DIR)" --target clean
```

逐条理由（也写在 Makefile 注释里）：

- `BUILD_JOBS ?= 4`：并行度改成显式量，`make` 不必再带 `-j`；`--parallel` 带数字后不再依赖 jobserver。
- recipe 前 `MAKEFLAGS=`：清掉父 make 的 jobserver 标记，否则子 make 仍会尝试使用拿不到的描述符并告警。
- **不加 `+`**：这里的 recipe 不依赖 jobserver（并行度已经显式给出），而 `+` 会让 `make -n` 真的开始编译。实测无 `+` 时三种调用都零告警且并行度正确，`make -n` 语义保持为"只打印"。
- 未改 `CMAKE_ARGS`、目标名、`ctest` 调用方式：`test`/`sanitize` 的 CTest 目标名与参数完全不变。

为什么不切 Ninja 预置（虽然矩阵里 Ninja 也零告警）：

- 本任务指定的普通路径是 `cmake -S . -B build/cmake`，它使用默认生成器（Unix Makefiles），因此无论预置怎么写，`make -j4` 这条入口都必须修 Makefile。
- `build/cmake` 与 `build/cmake-sanitize` 现存缓存生成器都是 Unix Makefiles；把 `baseline`/`sanitize` 预置改成 Ninja 会让这两个既有 binaryDir 报"generator does not match"，需要清空重建，影响其它并行工作的模块。CMakePresets.json 本次未改。

## 5. 全量验证结果

每一行都是本轮最后一次采集的原样记录（`run-summary-final.txt` 是机器汇总）。构建目录：普通 `build/cmake`（RelWithDebInfo，`BASELINE_SANITIZERS=OFF`），sanitize `build/cmake-sanitize`（Debug，`BASELINE_SANITIZERS=ON` → `-O1 -g -fsanitize=address,undefined -fno-omit-frame-pointer`，见 `CMakeLists.txt:26,91-95`）。

| # | 命令 | exit | 结果 | 日志 |
| --- | --- | --- | --- | --- |
| 1 | `cmake -S . -B build/cmake` | 0 | 普通配置（RelWithDebInfo） | `configure-ordinary.log` |
| 2 | `cmake --build build/cmake --target clean` | 0 | 清空普通产物 | `parallelism-proof.log` |
| 3 | `make BUILD_JOBS=1` | 0 | 全量构建，31 s | `parallelism-proof.log` |
| 4 | `cmake --build build/cmake --target clean` | 0 | 再次清空 | `parallelism-proof.log` |
| 5 | **`make -j4`（入口 1）** | 0 | 全量构建 11 s：编译 169 个 C 对象 / 96 个 target / 87 次链接；0 条 jobserver 告警 | `build-ordinary.log`、`jobserver-after.log` |
| 6 | `ctest --test-dir build/cmake --output-on-failure` | 0 | **57/57 通过**，29.02 s | `ctest-ordinary.log` |
| 7 | **`make -j`（入口 2）** | 0 | 增量构建，5 s；0 条告警 | `jobserver-unj.log` |
| 8 | **`make test`（入口 3）** | 0 | configure + build + CTest，**57/57 通过**（CTest 12.02 s） | `make-test.log` |
| 9 | `cmake --preset sanitize` + `--target clean` + `--parallel 4` | 0 | sanitize 全量构建 17 s：编译 169 个 C 对象 / 96 个 target / 87 次链接 | `build-sanitize.log` |
| 10 | **`make sanitize`（入口 4）** | 0 | configure + build + CTest，**57/57 通过**（CTest 41.98 s） | `make-sanitize.log` |
| 11 | `ctest --preset sanitize` | 0 | **57/57 通过**，19.68 s | `ctest-sanitize.log` |
| 12 | `cmake --build build/cmake --target format-check` | 0 | 通过，覆盖 107 文件 | `format-check.log` |
| 13 | `make reference` / `make vulnerable`（额外目标） | 0 / 0 | 两个 recipe 同样生效，无告警 | `make-extra-targets.log` |
| 14 | `make clean` + `make -j4` + `ctest` + `format-check`（补充复跑） | 0 / 0 / 0 / 0 | 改动过的 `clean` recipe 同样无告警；重建后 CTest 仍 **57/57**、format-check 仍通过 | `make-clean-and-rebuild.log` |

逐入口 jobserver 计数（`warning-scan.log` 末段，`grep -ci jobserver`）：

```
jobserver-before.log    1   （修复前，预期保留）
jobserver-after.log     0
jobserver-unj.log       0
make-test.log           0
make-sanitize.log       0
build-ordinary.log      0
build-sanitize.log      0
ctest-ordinary.log      0
ctest-sanitize.log      0
parallelism-proof.log   0
```

sanitize 产物确为插桩（`sanitize-instrumentation-check.log`）：

- `build/cmake-sanitize/audit`：`otool -L` 含 `@rpath/libclang_rt.asan_osx_dynamic.dylib`，未定义 `__asan/__ubsan` 符号 43 个。
- 对照 `build/cmake/audit`：无 sanitizer 运行时，`__asan/__ubsan` 0 个。

## 6. 并行度对照（真实仓库，非玩具工程）

`parallelism-proof.log` 用同一份源码、同一配置连续两轮全量构建，只改 `BUILD_JOBS`：

```
$ cmake --build build/cmake --target clean && make BUILD_JOBS=1     # 31 s（日志中 recipe 为 --parallel 1）
$ cmake --build build/cmake --target clean && make -j4              # 11 s（日志中 recipe 为 --parallel 4）
```

两次都是 169 个 C 目标全量重编（日志里 `Building C object` 各 169 行），因此 31 s → 11 s（约 2.8×）证明修复后确实按 4 路并行执行，而不是修前的 `-j1`。日志中可直接看到两行 recipe：

```
MAKEFLAGS= cmake --build "build/cmake" --parallel 1
MAKEFLAGS= cmake --build "build/cmake" --parallel 4
```

## 7. format-check

- 本机 PATH 中没有 `clang-format`，但 `cmake/Format.cmake` 在 APPLE 分支先跑 `xcrun --find clang-format`，命中 Xcode 自带 `/Applications/Xcode.app/.../usr/bin/clang-format`，版本 **Apple clang-format 21.0.0**，满足脚本"钉 21"的检查。`build/cmake` 缓存里的 `CLANG_FORMAT_EXECUTABLE` 为空，属于预期（走 xcrun 探测）。
- 目标本身：`cmake --build build/cmake --target format-check` → `Built target format-check`，exit=0，未写入任何文件（`format-check` 用 `--dry-run --Werror`，与 `-i` 的 `format` 目标区分）。
- 覆盖范围：`cmake/Format.cmake` 的 GLOB 集合在归档轮展开为 **107 个文件**（`src/*.c`、`include/*.h`、`tests/*.c`、`scripts/platform_stats/*.c`、两个 fixture 目录），非空跑。02:19 首次测量为 106，差额来自队友期间新增的 `tests/test_platform_holm.c`（见 8.2）。
- 敏感性对照：把 `int main(void){int x=1;return x;}` 写进临时副本，用同一个 clang-format 与仓库 `.clang-format` 跑 `--dry-run --Werror` → 6 条 `-Wclang-format-violations`，exit=1。证明该检查在格式不合规时确实会失败。
- 可复算替代（若某机器既无 `clang-format` 也无 Xcode）：`cmake -S . -B build/cmake -DCLANG_FORMAT_EXECUTABLE=$(command -v clang-format-21)`，或用仓库既有入口 `cmake --build <dir> --target format-check`。

## 8. 过程中发现的环境问题（均与本次修复无关）

### 8.1 `native_digest` 依赖 OpenSSL 3 的 `dgst -sha3-256`

第一轮普通 CTest 是 56/57：`native_digest` 断言失败（`tests/test_native_digest.c:77`，子进程 `openssl dgst -sha3-256` 返回非 0）。原因是**本机 `build/cmake` 缓存里有过期的 `OPENSSL_EXECUTABLE`**：

| 构建目录 | 缓存的 OPENSSL_EXECUTABLE | 该 `dgst -sha3-256` 行为 |
| --- | --- | --- |
| `build/cmake`（修复前） | `/usr/bin/openssl` = LibreSSL 3.3.6 | 打印用法并以 1 退出（不支持 SHA3-256） |
| `build/cmake-sanitize` | `/Users/yin/miniconda3/bin/openssl` = OpenSSL 3.5.5 | 输出 `SHA3-256(...)= 3a985da7…1532`，退出 0 |
| 备选 | `/opt/homebrew/bin/openssl` = OpenSSL 3.6.3 | 同上，退出 0 |

核对过程见 `openssl-digest-check.log`；第一轮失败原样保留在 `ctest-ordinary-libressl-stale.log` 与 `make-test-libressl-stale.log`。处理方式是**修复本地构建缓存**（不是改测试）：`cmake -S . -B build/cmake -DOPENSSL_EXECUTABLE=/Users/yin/miniconda3/bin/openssl`（`configure-ordinary-openssl-repair.log`），此后普通 CTest 57/57。

留给主控的判断（超出本任务写范围，未自行改动）：`native_digest` 依赖配置期 `find_program(openssl)`（`CMakeLists.txt:561`），在 macOS 上会命中不支持 SHA3-256 的 LibreSSL；建议在 README/CMake 里显式说明需要 OpenSSL 3，或在配置期校验 `dgst -sha3-256` 能力，避免下一个人在干净的 `build/cmake` 上再遇到同样的 56/57。

### 8.2 采集期间工作树被并发写入

本模块只写根 `Makefile` 与本证据目录；期间队友 `m2-kem` 按任务的 `task-2` 在工作树里新建/修改了文件。对本次证据的影响已逐项核对：

| 变化 | 时间 | 是否在根构建引用链上 | 处理 |
| --- | --- | --- | --- |
| 新建 `cmake/PlatformM2Collector.cmake` | 02:11:16（第一轮采集期间） | 否。它只被 `tools/platform_m2/CMakeLists.txt` 引用（独立 `project()`）；根 `CMakeLists.txt` 只 `add_subdirectory(fixtures/*)`，`build/cmake` 中 collector/dudect 目标数 **0** | 第一轮结论作废，重采；最终轮前后快照可证 |
| 新建并修改 `tests/test_platform_holm.c`（`??` 未跟踪，不在 HEAD；02:19 之后进入 format-check 的 GLOB，02:24:12 内容变化） | 归档轮期间 | 编译/测试：否。`cmake/PlatformStats.cmake` 仅在 `BASELINE_ENABLE_PLATFORM=ON` 时包含，两个构建目录该选项均为 **OFF**，`build/cmake` 中 holm 目标数 **0**、CTest 中 holm 用例 0。格式检查：**是**，它在 `format-check` 的 GLOB 内 | `format-check`（02:26:08）晚于该写入，在含新内容的 107 文件上通过；归档轮后的复核（`post-pass-recheck.log`）显示构建输入无变化 |
| HEAD 从 `47033dd8` 变为 `efca8a1` | 采集期间 | 提交不改文件内容；归档轮前后快照的构建输入 sha256 一致 | 记录即可 |

归档轮（02:23:00–02:26:10）前后的 `sha256` 对比：除 `tests/test_platform_holm.c` 一行外全部构建输入一致；`post-pass-recheck.log`（02:26:39）复核结论为"构建输入无变化"，`build/cmake` 目标数 362、CTest 用例数 57、`holm|dudect|collector` 目标数 0、`format-check` 再次通过。

## 9. 与任务验收对照

| 验收项 | 状态 | 说明 |
| --- | --- | --- |
| 四个入口零 jobserver 警告 | 通过 | 四个日志各 0 条；修前 `jobserver-before.log` 1 条 |
| 普通与 sanitize CTest 全绿 | 通过 | 均 57/57；`make test`、`make sanitize` 亦为 57/57 |
| format-check 通过 | 通过 | exit=0，107 文件，含敏感性对照 |
| 证据文件齐全 | 通过 | 见第 10 节索引 |
| 根 Makefile 显式并行度 | 通过 | `BUILD_JOBS ?= 4`，`--parallel $(BUILD_JOBS)` |
| 未 git add / commit / push | 通过 | 本模块相关条目只有 `M Makefile` 与新增 `docs/evidence/build-20261016/`（其余未提交改动属队友模块） |
| 未改 src/ 业务逻辑、未改测试语义 | 通过 | 改动仅 `Makefile` 一个文件 |
| 未碰他人证据目录 | 通过 | 只写 `docs/evidence/build-20261016/` |

未做与未决（如实列出）：

1. 未采用 `+` 前缀与未切换 Ninja 预置，理由与实测数据在第 3、4 节；`CMakePresets.json` 未改动。
2. `clean` 目标的 recipe 也加了 `MAKEFLAGS=`，并已作为补充项实测（第 5 节第 14 行、`make-clean-and-rebuild.log`）：`make clean` 无告警，随后 `make -j4` 重建、CTest 57/57、format-check 通过。它不在这四个必测入口里，且会清空构建产物，因此放在主轮之后补跑。
3. 8.1 的 OpenSSL 3 依赖是环境层面的既有问题，本任务只修本地缓存并在证据里说明，未改 `CMakeLists.txt`。
4. 本机为 macOS/ARM（Apple M5），这些结果不代表 x86_64 Linux；并行度结论与平台无关，但耗时数字只对本机成立。

## 10. 原始文件索引

| 文件 | 内容 |
| --- | --- |
| `jobserver-before.log` | 修复前 `make -j4` 原样输出（含 jobserver 告警） |
| `jobserver-after.log` | 入口 1：`make -j4` 全量构建（与 `build-ordinary.log` 同一次运行） |
| `jobserver-unj.log` | 入口 2：`make -j` |
| `make-test.log` | 入口 3：`make test`（含 57/57） |
| `make-sanitize.log` | 入口 4：`make sanitize`（含 57/57） |
| `build-ordinary.log` | 普通 clean + `make -j4` 全量构建（169 C 目标 / 96 target / 87 链接） |
| `ctest-ordinary.log` | 普通 `ctest --output-on-failure`，57/57 |
| `build-sanitize.log` | `cmake --preset sanitize` + clean + 全量构建 |
| `ctest-sanitize.log` | `ctest --preset sanitize`，57/57 |
| `parallelism-proof.log` | `BUILD_JOBS=1`（31 s）与 4 路并行（11 s）对照 |
| `format-check.log` | format-check 通过 + 格式化器来源 + 107 文件覆盖 + 敏感性对照 |
| `make-extra-targets.log` | `make reference` / `make vulnerable` |
| `make-clean-and-rebuild.log` | 补充：`make clean` + `make -j4` + CTest 57/57 + format-check |
| `sanitize-instrumentation-check.log` | 普通/sanitize 产物插桩对照 |
| `openssl-digest-check.log` | LibreSSL / OpenSSL 3 的 `dgst -sha3-256` 能力核对 |
| `ctest-ordinary-libressl-stale.log`、`make-test-libressl-stale.log` | 第一轮 56/57 的失败原文（LibreSSL 导致） |
| `configure-ordinary.log` | 普通配置（任务指定命令） |
| `configure-ordinary-openssl-repair.log` | 修复 `OPENSSL_EXECUTABLE` 缓存的重配置 |
| `makefile-diff.txt`、`Makefile.before.txt`、`Makefile.after.txt` | Makefile 前后对比 |
| `warning-scan.log` | 全部日志的 jobserver/warning/error 扫描与逐入口计数 |
| `source-state-before.txt`、`source-state-after.txt` | 第一轮采集的源码/工具链/工作树快照 |
| `source-state-final-before.txt`、`source-state-final-after.txt` | 归档轮的冻结快照（HEAD、OpenSSL 缓存、目标数、git status、输入 sha256） |
| `post-pass-recheck.log` | 归档轮之后的复核（无输入变化 + format-check 复跑通过） |
| `run-summary-final.txt` | 归档轮机器汇总（命令/退出码/耗时/日志） |
| `run-summary-pass1.txt`、`run-summary-pass2.txt` | 前两轮的中间汇总（历史；同名日志已被归档轮覆盖，其失败原文见两个 `*-libressl-stale.log`） |
| `jobserver-matrix/` | 变体矩阵工程、脚本与结果（可独立复算） |

## 11. 复算步骤（本机，约 3 分钟）

```bash
export PATH="$HOME/.local/bin:$PATH"
cd /Users/yin/code/cryProject

# 普通：配置 → 清空 → 通过根 Makefile 全量构建 → CTest
cmake -S . -B build/cmake
cmake --build build/cmake --target clean
make -j4
ctest --test-dir build/cmake --output-on-failure

# sanitize 预设：配置 → 清空 → 全量构建 → CTest
cmake --preset sanitize
cmake --build --preset sanitize --target clean
cmake --build --preset sanitize --parallel 4
ctest --preset sanitize

# 其余入口
make -j
make test
make sanitize

# format-check 与机制矩阵
cmake --build build/cmake --target format-check
bash docs/evidence/build-20261016/jobserver-matrix/run-matrix.sh
```

判读要点：`make -j4` 的输出里 recipe 行必须是 `MAKEFLAGS= cmake --build "build/cmake" --parallel 4`，且全文不得出现 `jobserver`；两套 CTest 的最后一行都应为 `100% tests passed, 0 tests failed out of 57`。
