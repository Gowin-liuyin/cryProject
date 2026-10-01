# 新增自有代码的检查补齐与全量复核（模块四）

**预注册凭证（模块零提交）**：`adf9db9d2734837de11274343d3828d49d0f2444`。
本目录的检查项、命令口径与证据清单由该提交固定在
`docs/tasks/four-module-design.md` 第 4 节，全部检查在该提交之后执行。
该凭证只有本地顺序效力，没有第三方时间戳（本仓库从未 push，`origin/main` 实测为 `gone`，
本地提交日期可由作者设置）。

**本目录不含任何统计材料。** 唯一一次 `measure` 调用是每类 50 的小样本，只为把程序自报的
`executable_digest` 与独立摘要对照（0.4 第 5 条），CSV 与报告不归档，也不得被引用为时序数据。

## 平台与工具版本

- Apple M5 / ARM64 macOS，Apple clang version 21.0.0 (clang-2100.3.34.2)。
- CMake 4.3.2（`/Users/yin/.local/bin/cmake`）、Ninja 1.13.0、GNU Make（`sanitize` preset）。
- Apple clang-format version 21.0.0 (clang-2100.3.34.2)，由 `cmake/Format.cmake` 在 APPLE 上经
  `xcrun --find clang-format` 解析到
  `/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/clang-format`。
- cmakelang 0.6.13 的 `cmake-format`（`uvx --from cmakelang==0.6.13`）。
- OpenSSL（`/Users/yin/miniconda3/bin/openssl`）与 `shasum -a 256` 作独立摘要工具。

## 绑定的源码提交与工作区状态

**功能源码提交**：`4ce21336e756bb9a1018e99819b4ae50440b0e78`
（模块三证据提交；模块四没有代码改动，静态分析与构建都针对这一棵树）。
**构建时工作区状态（逐字抄录小样本 `.meta` 的 `git_worktree_status_*`）**：

```
git_worktree_status_begin
?? .agents/
?? docs/evidence/review-four-module/
git_worktree_status_end
tracked_delta_sha256=e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
```

即**被跟踪文件无任何未提交改动**（`tracked_delta_sha256` 为空内容摘要），
工作区只有两个未跟踪目录：`.agents/`（代理会话草稿，不参与构建）与本证据目录自身。
`docs/tasks/` 下无未跟踪或已修改文件，满足 0.1 的硬约束。

## 本目录结论所覆盖的构建配置（逐字抄录 `.meta` 实测值）

配置命令（0.2 表里模块四那一行，逐字）：

```sh
cmake -S . -B build/review-four-module -G Ninja -DCMAKE_BUILD_TYPE=RelWithDebInfo \
    -DBUILD_TESTING=ON -DBASELINE_SANITIZERS=OFF
cmake --build build/review-four-module --parallel
```

```
generator=Ninja
configuration=RelWithDebInfo
compiler_flags= -O2 -g -DNDEBUG -std=c11
compile_options=-Wall -Wextra -Wpedantic -Wshadow -Wconversion -Wstrict-prototypes -Werror
```

**本目录结论只覆盖这一配置。** 它与 `baseline` preset 不是同一配置：后者的生成器实测是
`Unix Makefiles`（`CMakePresets.json`），`sanitize-ctest.log` 则来自 `build/cmake-sanitize`
（`Unix Makefiles` / `Debug` / ASan+UBSan）。`sanitize-ctest.log` 与
`format-check.log` 后半段、`readme-examples.log` 都**不属于** `build/review-four-module`，
各自的归属已在文件内写明；它们只用于功能正确性与文档示例，不支持任何产物形态或性能结论。

## 覆盖内容与结论

| 检查项 | 结果 | 日志 |
|---|---|---|
| 干净重新构建（全新目录） | 配置 `exit=0`、构建 `exit=0`，`grep -ci warning` 实测 **0** | `configure.log`、`build.log` |
| `ctest -N` 与全部 CTest | 实测 **18 项**，`100% tests passed, 0 tests failed out of 18` | `ctest.log` |
| 独立 sanitize preset（M4-1） | 配置/构建/`ctest` 四步全部 `exit=0`，**18 项**全部通过 | `sanitize-ctest.log` |
| ASan/UBSan 报告 | `grep -icE 'AddressSanitizer\|UndefinedBehaviorSanitizer\|runtime error\|LeakSanitizer'` 实测 **0** | `sanitize-ctest.log` |
| Apple Clang 静态分析（M4-2） | 8 个自有源文件 × 4 个变体宏设置，四次调用 `exit=0`、**无诊断** | `static-analysis.txt` |
| `format-check`（M4-3） | 在 `build/review-four-module` 与 `baseline` preset 下各 `exit=0` | `format-check.log` |
| `cmake-format --check`（M4-3） | `CMakeLists.txt` 与 `cmake/*.cmake`，`exit=0` | `cmake-format.log` |
| `sh -n`（M4-3） | `tests/*.sh` 7 个、`tools/*.sh` 1 个，全部 `exit=0` | `shell-syntax.log` |
| README 新示例命令（M4-4） | `deployable` 的 `version`/`demo`/`generate-test`/`decapsulate-test`/`measure`、`analyze`、`analyze_groups` 全部 `exit=0` | `readme-examples.log` |
| 身份与未 push（M4-7） | 6 个已有提交全部在 `main`、作者与提交者均为 `Gowin-liuyin <yinhaoran0808@outlook.com>`；`origin/main` 不存在 | `git-log.txt` |
| 摘要对照（0.4 第 5 条） | 四个变体 `measure` 自报 `executable_digest` 与独立 OpenSSL SHA3-256 **逐个一致** | `record-checks.txt` |

**M4-2 的首次覆盖**：`src/analyze.c`、`src/analyze_groups.c`、`src/timing_statistics.c`
此前从未被静态分析过，`-DBASELINE_HARDENED=1` 与 `-DBASELINE_DEPLOYABLE=1` 也是首次使用。
四次调用都没有诊断，因此**本模块没有产生 `fix:` 修复提交，也没有 `style:` 格式提交**。

## 复现命令

在仓库根目录、干净工作区执行（顺序即本模块的固定执行顺序）：

```sh
rm -rf build/review-four-module
cmake -S . -B build/review-four-module -G Ninja -DCMAKE_BUILD_TYPE=RelWithDebInfo \
    -DBUILD_TESTING=ON -DBASELINE_SANITIZERS=OFF
cmake --build build/review-four-module --parallel

for macro in "" "-DBASELINE_VULNERABLE=1" "-DBASELINE_HARDENED=1" "-DBASELINE_DEPLOYABLE=1"; do
    clang --analyze -std=c11 -Wall -Wextra -Iinclude -Ivendor/mlkem-native/mlkem \
        -Ibuild/review-four-module/generated/RelWithDebInfo \
        -DMLK_CONFIG_FILE='"baseline_config.h"' ${macro} \
        -Xanalyzer -analyzer-output=text \
        src/main.c src/mlkem.c src/random.c src/inputs.c src/measure.c \
        src/analyze.c src/analyze_groups.c src/timing_statistics.c
done

ctest --test-dir build/review-four-module -N
ctest --test-dir build/review-four-module --output-on-failure

cmake --preset sanitize
cmake --build --preset sanitize --parallel
ctest --preset sanitize

cmake --build build/review-four-module --target format-check
uvx --from cmakelang==0.6.13 cmake-format --check CMakeLists.txt cmake/*.cmake
for script in tests/*.sh tools/*.sh; do sh -n "$script"; done

shasum -a 256 -c docs/evidence/review-four-module/SHA256SUMS
```

`zsh` 不对未加引号的变量做分词，所以上面的宏循环要写成 `${macro}` 形式；
把八个源文件写成一个变量再展开会被当成单个路径，实测报
`no such file or directory`。

## 结论边界（支持什么／不支持什么）

**支持**：

- 本轮新增的自有代码（`src/analyze.c`、`src/analyze_groups.c`、`src/timing_statistics.c`）
  已纳入与既有自有代码同级别的检查：严格警告零告警构建、CTest、独立 ASan/UBSan、
  Apple Clang 静态分析、格式与脚本语法检查。
- 本轮 6 个已有提交的分支、作者、提交者、邮箱与 hash 已逐个核对；本地没有 `origin/main`
  跟踪引用，这些提交只存在于本地。

**不支持**：

- **「全部检查通过」只等于检查通过，不等于结论成立。** 功能正确、源码秘密依赖、产物机制、
  原始数据、观察差异、正式统计确认是六个分别核实的结论，各自绑定自己的证据目录。
- 静态分析是**范围内**的封装／运行／分析代码检查，不是正确性证明、不是恒时证明，
  也不是对 `vendor/` 的重新审计。
- 本目录**不产出任何时序结论**，也不支持任何产物形态或地址结论（没有归档反汇编）。
- **不支持**「真实 x86_64 Linux 主机已验证」。真实 x86_64 Linux 主机上的采集与两轮固定检验
  **仍未执行**；这一条不因模块二的 QEMU 模拟而改变。macOS/ARM、容器、交叉编译或模拟器
  一律不得冒充真实 x86_64 Linux 实测。
- 本目录不含二进制副本、不含 CSV、不含 `.report`。

## 未能完成的项

1. **本轮四个模块的评审产物不在仓库内。** 设计 0.1 规定模块零之后各轮评审产物写入
   `docs/tasks/review-m<模块号>-r<轮次>.{md,json}`；实际由评审环节写在未跟踪目录
   `.agents/tasks/four-module-review/review-m{0,1,2,3}.{md,json}`，`.agents/` 全程未提交。
   因此「四份判定均为 `APPROVED`、无阻断发现」只能由作者转述，不可从仓库逐字复核。
   按 0.5 记为缺口，不在本轮补建仓库内副本（那会把别的模块的文件带进本模块的提交范围）。
2. **「远端没有这些提交」只有本地侧证据。** 本轮未执行 `git fetch`（会改变观察结果）、
   未执行 `git push`（明令禁止）。更强的凭证需要联网查询，超出本阶段范围。

## 本目录文件

| 文件 | 内容 |
|---|---|
| `README.md` | 本文件 |
| `configure.log`、`build.log` | `build/review-four-module` 的配置与构建逐字输出 |
| `ctest.log` | 同一目录的 `ctest -N` 与全部 CTest 逐字输出 |
| `sanitize-ctest.log` | `sanitize` preset 的配置/构建/`ctest -N`/`ctest` 四步逐字输出 |
| `static-analysis.txt` | 实际命令（含包含路径）、与既有 `review/static-analysis.txt` 的差异、四次调用输出 |
| `format-check.log`、`cmake-format.log`、`shell-syntax.log` | 三类格式与语法检查的逐字输出 |
| `readme-examples.log` | README 新增示例命令的实际执行输出 |
| `final-recheck.log` | 文档改动后的最终复核：产物摘要复验、全部 CTest、`format-check` |
| `git-log.txt` | 本轮全部提交的身份核对与未 push 的三条实测输出 |
| `binaries.sha256` | `shasum -a 256`，十个被检查产物（构建目录路径，无二进制副本） |
| `record-checks.txt` | 独立 OpenSSL SHA3-256、程序自报 `executable_digest` 对照、`git diff --cached --check` |
| `SHA256SUMS` | 本目录除自身以外全部文件的 `shasum -a 256` |

核对命令（在仓库根目录）：

```sh
shasum -a 256 -c docs/evidence/review-four-module/SHA256SUMS
openssl dgst -sha3-256 build/review-four-module/reference/measure
```

第二条需要先按上面的复现命令重新构建；地址与摘要绑定本次构建，不跨构建复用。
