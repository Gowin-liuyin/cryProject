# A1-13 · ML-KEM-768 时间侧信道实验基线

用 **C11** 搭建的单机实验系统：包含 ML-KEM 参考实现、保持密码输出语义的时序缺陷变体、
在同一构建条件下去掉秘密相关分支的防护变体、命令行自检、可复现测试密文、
在 C 内部计时的原始数据采集程序，以及对原始数据执行固定预先规定检验的统计程序。
使用 CMake 构建、CTest 验证。

这是竞赛第一阶段的软件基线，以及在其上完成的统计确认与恒时编码对照。
缺陷版是**公开标注的人工机制回归**，用于研究消息编码中的秘密相关分支；
不是新发现的部署漏洞，也不用于保护真实业务秘密。防护版是对照实验用的最小补丁，
不是可交付的加固实现。

## 1. 构建并运行

以下命令均在本仓库根目录执行。源码需要保留 Git 历史，构建程序会读取提交号和工作区状态。

依赖：CMake **3.21 或更新版本**、Clang/GCC、Make 或 Ninja，以及 Git、patch、sh、awk、shasum。
macOS 可使用 Xcode Command Line Tools 提供的编译器；Linux 需安装对应编译工具和 CMake。
默认 preset 使用 Unix Makefiles；普通构建不联网、不下载密码库，也不需要 Python 或 jq。

```sh
cmake --preset baseline
cmake --build --preset baseline --parallel
ctest --preset baseline

build/cmake/reference/baseline version
build/cmake/reference/baseline selftest
build/cmake/vulnerable/baseline demo
build/cmake/hardened/baseline demo
```

默认配置是 `RelWithDebInfo`，本机对应 `-O2 -g -DNDEBUG`，启用 C11 和严格编译警告。
三个变体的产物分别位于：

| 路径 | 用途 |
|---|---|
| `build/cmake/reference/baseline` | 参考版命令行 |
| `build/cmake/vulnerable/baseline` | 缺陷版命令行 |
| `build/cmake/hardened/baseline` | 防护版命令行 |
| `build/cmake/reference/measure` | 参考版逐次计时 |
| `build/cmake/vulnerable/measure` | 缺陷版逐次计时 |
| `build/cmake/hardened/measure` | 防护版逐次计时 |
| `build/cmake/analyze` | 原始数据的固定统计检验，与实现无关 |

`selftest` 和 `demo` 都使用系统安全随机源，执行一次密钥生成、封装、解封装，并检查共享密钥一致。
成功只输出操作结果，不显示私钥、共享密钥或内部重加密验证结果。
**完整的独立已知答案验证需要运行 CTest；一次往返自检不等于完整标准验证。**

## 2. 生成和解封装测试密文

`generate-test` 与 `decapsulate-test` 使用公开种子重建同一测试密钥。
输出文件只有密文；解封装时必须使用相同种子。所有输出路径都必须是新路径。

```sh
mkdir -p runs
run_directory=$(mktemp -d runs/input.XXXXXX)

build/cmake/reference/baseline generate-test bit-flipped 42 "$run_directory/input.bin"
build/cmake/vulnerable/baseline decapsulate-test 42 "$run_directory/input.bin"
```

命令格式：

```text
baseline version
baseline selftest
baseline demo
baseline generate-test CATEGORY SEED CIPHERTEXT_FILE
baseline decapsulate-test SEED CIPHERTEXT_FILE
```

| CATEGORY | 生成方式 | 标签的含义 |
|---|---|---|
| `valid` | 使用派生测试消息正常封装 | 生成器产生的有效密文 |
| `bit-flipped` | 在有效密文上翻转一位，长度不变 | 表示修改方式，不来自内部验证标志 |
| `random` | 生成 1088 字节确定性伪随机输入 | 不预先假定它显著触发目标分支 |
| `message-zero` | 用全零消息执行内部封装 | 已知消息位为 0 的机制审计输入 |
| `message-ones` | 用全 1 消息执行内部封装 | 已知消息位为 1 的机制审计输入 |

SEED 是十进制无符号 64 位整数。相同类别和种子产生相同测试文件；CLI 生成的是索引为 0 的样本。
采集程序还会使用样本索引派生输入。固定密钥下，两个固定消息类别会重复相同密文。

测试种子是公开实验材料，**不能用于真实密钥生成**。正确长度的无效密文仍按规范执行隐式拒绝，
CLI 不会额外告诉调用者重加密比较是否通过。短文件、超长文件或读取错误在调用内核前被拒绝。

## 3. 采集逐次时间

```sh
mkdir -p runs
run_directory=$(mktemp -d runs/timing.XXXXXX)

build/cmake/reference/measure reference-run 42 1000 \
    "$run_directory/reference.csv" "$run_directory/reference.meta"
build/cmake/vulnerable/measure vulnerable-run 42 1000 \
    "$run_directory/vulnerable.csv" "$run_directory/vulnerable.meta"
build/cmake/hardened/measure hardened-run 42 1000 \
    "$run_directory/hardened.csv" "$run_directory/hardened.meta"
```

参数顺序为：

```text
measure RUN_ID SEED SAMPLES_PER_CATEGORY CSV_FILE META_FILE
```

- RUN_ID 为 1–64 个 ASCII 字母、数字、下划线或连字符。
- 每类次数为 1–20000；共有五类，因此上例每个变体保存 **5000 条记录**。
- 全部输入提前生成，类别顺序按种子随机化；同种子、同次数下各变体顺序相同。
- 先运行 100 次预热；每条正式记录围绕完整解封装调用计时。
- 输入生成、内存申请、结果消费和文件 I/O 都在单次计时窗口外。

CSV 固定包含以下列，保存每次原始值，不只保存均值，不删除普通长尾：

```text
run_id,implementation,input_category,sample_index,elapsed_nanoseconds,time_unit
```

时钟为 `CLOCK_MONOTONIC`，单位是纳秒。**单位不代表精度**：本次 Apple M5 的时钟报告分辨率为
1000ns。没有使用 TSC，也没有把数值称为 CPU 周期。默认不固定 CPU 亲和性或频率。

配套 `.meta` 记录源码提交与未提交改动摘要、构建输入摘要、编译器、配置和选项、实际 OS/CPU、
种子、时钟、样本数，以及正在运行的可执行文件的 SHA3-256。准确编译命令见构建目录的
`compile_commands.json`。仅使用退出码为 0 的完整运行；写入失败可能留下部分文件，不能用于分析。

详细的计时边界、标签依据和解释限制见 [计时说明](docs/timing.md) 与 [缺陷说明](docs/defect.md)。

## 4. 固定统计检验

`analyze` 读取一份原始 CSV，按**采集前即固定**的检验族输出报告，不做任何数据相关的选择：

```sh
build/cmake/analyze "$run_directory/reference.csv" "$run_directory/reference.report"
build/cmake/analyze "$run_directory/vulnerable.csv" "$run_directory/vulnerable.report"
```

```text
analyze CSV_FILE REPORT_FILE
```

检验族为五类输入的全部 10 个类别对，族水平 0.001，Bonferroni 校正后单比较水平 1e-4；
判定用并列修正的 Mann-Whitney U，辅以 Welch t；不删离群值，不插值，不改写输入。
报告为 `key=value` 行，含每类的计数/分位点/均值/标准差、每个比较的统计量与判定，
以及被分析 CSV 的 SHA3-256，可用 `openssl dgst -sha3-256` 独立核对。
输入表头、列数、类别名、样本序号、单位和行结束都严格校验，不合格即拒绝且不创建报告。

本机结果：**参考版 0/10 显著；缺陷版 7/10 显著**，两个独立公开种子各 25000 条一致复现。
主效应出现在「恒定消息类」与「变化消息类」之间，均值差 711–800ns、效应量 0.819–0.844。
方法、预先规定项、数值边界和解释限制见 [统计说明](docs/statistics.md)。

## 5. 三个变体的关系

参考实现固定自 [mlkem-native](https://github.com/pq-code-package/mlkem-native) 提交：

```text
b3ba7b32773e657dd37f6f87bce82528459ad8a4
```

采用 FIPS 203 的 ML-KEM-768 和便携 C 后端。封装公钥为 1184 字节、解封装私钥为 2400 字节、
密文为 1088 字节、共享密钥为 32 字节。第三方源码和许可证原样保存在 `vendor/`；
许可与规范出处见 [来源记录](docs/sources.md)。功能测试通过不表示获得 FIPS 模块认证。

缺陷版在构建目录的副本上应用 [消息编码补丁](docs/patches/message-branch.patch)，
将 `mlk_poly_frommsg` 的常数时间选择改为按消息位执行的 `if/else`。
解封装重加密使用的消息来自私钥参与的解密，因此分支条件具有秘密依赖。
Clang 对该函数使用 `optnone,noinline`；GCC 使用 `optimize("O0"),noinline`，以明确保留机制。

防护版应用 [恒时编码补丁](docs/patches/message-constant-time.patch)，
保留**与缺陷版相同的**函数级优化控制和循环结构，只把分支换成掩码选择，
使对照只改变「有无分支」这一项。三个变体各有独立的库、源码副本和可执行文件，
其余代码按所选构建配置编译，不在同一进程混合链接。

两个补丁都保持数学输出、重加密验证和隐式拒绝，不添加延迟或空转。
由于编码函数优化条件不同，**参考版与另两版的整体速度差本身不能证明秘密泄露**；
已知消息类别的时序也不能直接推广为未知密钥攻击。对照设计与结果见
[防护说明](docs/mitigation.md)。

## 6. 验证结果与证据边界

当前有 **13 项 CTest**，覆盖：

| 检查 | 实际覆盖 |
|---|---|
| 三版 NIST 检查 | 每版 25 keygen、25 encaps、10 decaps、20 密钥校验；解封装含 5 组隐式拒绝 |
| 三版随机源失败 | 系统随机源打开失败的传播，以及恢复后的往返验证 |
| 两组差分 | 缺陷版和防护版各对参考版：64 个种子 × 三类输入；拒绝样本另核对 J(z∥c) |
| CLI | 三版五类输入、参数错误、长度边界、目录读取错误、拒绝覆盖及跨版本密文一致 |
| 采集与记录 | 行数、类别顺序、单位、运行编号一致性；拒绝负数、溢出和尾随字段 |
| 统计检验 | 可解析验证的合成数据、退化与样本不足处理、十类畸形 CSV 拒绝、三版真实数据全流程 |
| 向量读取 | 拒绝截断用例、非法编号和非法十六进制 |
| 向量完整性 | 原始 NIST JSON 与转换文件的固定 SHA-256 |

NIST 原件、固定版本和转换方式保存在 `tests/vectors/` 与 [验证记录](docs/validation.md)。
预期答案不由被测实现生成；只有重新转换已保存的 JSON 时才需要 jq。

已执行的平台是 **Apple M5 / ARM64 macOS、Apple Clang 21**：干净构建、13 项 CTest、
独立 ASan/UBSan、格式检查和自有运行代码静态分析均已通过。
最近一次审查及对应产物证据见 [代码审查记录](docs/review.md)。
历史数据在 `docs/evidence/` 中按构建分别保存；每组绑定自己的源码版本和二进制摘要。
修改代码或编译条件后，必须重新定位机器码和重新采集，不能拿旧数据为新产物背书。

**目标机制、原始数据、本机统计确认和防护对照是分别核实的结论。**
统计确认限于 Apple M5 / ARM64 macOS，证据见
[evidence/statistics](docs/evidence/statistics/README.md)；同一固定检验在参考版上不显著。
去掉分支后的对照见 [evidence/mitigation](docs/evidence/mitigation/README.md)：
同一构建条件下防护版 0/10 显著、缺陷版 6/10 显著，但残差随运行波动，不宣称防护版已证明恒时。
尚未执行真实 x86_64 Linux/GCC 验证；没有宣称参考版完全恒时，也没有完成密钥恢复。
下一阶段可在真实 x86_64 Linux/GCC 上重跑同一组功能检查、采集与固定检验，
并对打开优化后的恒时编码逐个反汇编确认。

## 7. 开发和代码风格

独立的内存及未定义行为检查：

```sh
cmake --preset sanitize
cmake --build --preset sanitize --parallel
ctest --preset sanitize
```

该配置输出到 `build/cmake-sanitize`。它的计时仅用于接口检查，不能作为正式性能数据。

自有 C 代码采用固定的 clang-format 21 规则；正常构建不依赖格式工具：

```sh
cmake --build --preset baseline --target format-check
cmake --build --preset baseline --target format
```

格式工具不在 PATH 时可在配置时指定 `CLANG_FORMAT_EXECUTABLE`。CMake 风格、命名、注释和脚本
约定见 [代码风格](docs/style.md)。格式化仅覆盖自有代码，不改动上游源码、固定向量或封存证据。

其他常用配置：

```sh
cmake -S . -B build/ninja -G Ninja -DCMAKE_C_COMPILER=clang -DCMAKE_BUILD_TYPE=RelWithDebInfo
cmake --build build/ninja --parallel
ctest --test-dir build/ninja --output-on-failure

cmake --build build/ninja --target reference
cmake --build build/ninja --target vulnerable
cmake --build build/ninja --target hardened
```

`BUILD_TESTING=OFF` 可关闭测试程序；`BASELINE_SANITIZERS=ON` 可开启动态检查。
多配置生成器需要 `cmake --build <目录> --config Debug` 与 `ctest --test-dir <目录> -C Debug`，
程序位于该构建目录的 `Debug/` 下。根 Makefile 只是 CMake/CTest 的兼容入口。

## 8. 文件职责与常见问题

| 目录/文件 | 职责 |
|---|---|
| `src/`、`include/` | C 接口封装、随机源、测试输入、CLI、计时和统计检验 |
| `tests/` | 功能与边界检查、命令编排、NIST 原件 |
| `CMakeLists.txt`、`CMakePresets.json`、`cmake/` | 唯一构建配置、测试注册、补丁副本及格式检查 |
| `tools/build_identity.sh` | 生成并嵌入构建追溯信息 |
| `vendor/` | 未修改的第三方源码与许可证 |
| `docs/` | 来源、机制、计时、统计、防护、验收、审查和原始证据 |

- **输出文件已存在**：程序有意拒绝覆盖，换用新的运行目录或文件名。
- **密文读取失败**：输入必须是恰好 1088 字节的可读文件；先检查路径及长度。
- **解封装显示完成**：只表示操作完成，不表示内部重加密比较通过。
- **报告显示 `p=0`**：`erfc` 在 |z| 很大时下溢，应以报告中的 z 值为准。
- **不知道测的是哪一版**：运行该目录下的 `baseline version`，并核对采集 `.meta` 中的实现名和文件摘要。
- **防护版比参考版慢**：防护版为保持与缺陷版同一构建条件保留了 `optnone`，见 [防护说明](docs/mitigation.md)。
- **更改编译器后配置报错**：使用新的构建目录，不在已有 CMake 缓存中切换工具链。

CLI 退出码：0 为成功，2 为公开命令参数错误，1 为运行或文件操作失败。
C API 的精确长度和返回值定义见 [mlkem.h](include/mlkem.h)；调用方需提供互不重叠的有效缓冲区。
