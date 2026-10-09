# A1-13 · ML-KEM-768 本地审计与复算作品

本轮提交候选版新增[公开来源审查](docs/upstream-security-review.md)、
[固定版本适用性](docs/current-version-defense-review.md)与[真实Linux工程核验](docs/evidence/candidate-round-20261007/README.md)。
[离线证据展示](deliverables/demo/index.html)和[结论索引](deliverables/demo/evidence-index.md)按稳定编号直达材料。
`build/cmake/audit help`给出普通使用与复算命令。封存 v3 的新目录执行已由所有者授权代理完成并计入 R11，
见 [执行记录](docs/evidence/author-proxy-v3-20261008/README.md)。同一 Linux 上的人工机制防护前后见 [R07记录](docs/evidence/r07-linux-20261008/README.md)。实际截图及审批签署仍缺，
当前材料供项目组审阅修改，不称全部要求验收完成。

2026-10-10的[47页研究补强报告](deliverables/research/aris-report-weak-mean-20261010/README.md)
在原45页及[M02重建复核](docs/research/aris-replication-20261009/RESULTS.md)基础上补入条件均值推断，保留官方潜在修正核对及原数据。
一次干净重建后的三个同机新进程支持固定六非零输入的较低中位成本观察，原M01不合并。
报告经科学与全页视觉核验；R02/R04的真实测量及统计前提、实际截图和本人签署仍需适用证据。
[新版匿名研究补充件](deliverables/support/CACR2026EA16XZ-mean-inference-20261010/README.md)已闭合47页报告、完整均值证明及协议阅读视图；原870项嵌于明确历史子根保持原字节。
[当前状态与下一协议](docs/research/aris-replication-20261009/CURRENT_STATUS.md)提供复算、单核管理恢复原件及未闭合门槛入口。

当前作品入口为C11 `audit`：功能验收、参考普通采集、数据检查、历史重分析、
成对统计、普通性能及离线HTML导出。构建后从这里开始：

```sh
cmake --preset baseline
cmake --build --preset baseline --parallel 4
build/cmake/audit version
build/cmake/audit check
build/cmake/audit case
```

[使用流程](docs/product-workflow.md)、[完整验收表](docs/full-work-acceptance.md)及
[进度](docs/full-work-progress.md)给出最新状态。已取得真实4vCPU KVM/x86_64 Linux普通参考证据；
有限批次合同准备失败并停止；无秘密精确复算的C/SciPy效率比较已确认。
人工回归历史链、新原生普通测量和合成统计验证分开，尚未宣称完整受控防护闭环或全部竞赛达标。
以下章节保留原软件基线及历轮的时点记录。

用 **C11** 搭建的单机实验系统：包含 ML-KEM 参考实现、保持密码输出语义的时序缺陷变体、
在同一构建条件下去掉秘密相关分支的防护变体、不带函数级优化控制的可部署恒时编码变体、
命令行自检、可复现测试密文、在 C 内部计时的原始数据采集程序，
以及对原始数据执行两组固定预先规定检验的统计程序。使用 CMake 构建、CTest 验证。

这是竞赛第一阶段的软件基线，以及在其上完成的统计确认、恒时编码对照和多种子稳健性复核。
缺陷版是**公开标注的人工机制回归**，用于研究消息编码中的秘密相关分支；
不是新发现的部署漏洞，也不用于保护真实业务秘密。防护版是对照实验用的最小补丁，
不是可交付的加固实现；可部署版去掉了那层优化控制，但同样不是加固交付件
（上游该函数本来就无分支，见第 5 节）。

## 1. 构建并运行

以下命令均在本仓库根目录执行。源码需要保留 Git 历史，构建程序会读取提交号和工作区状态。

测试临时文件统一由CTest放入各构建目录的`test-tmp/`，C和Shell测试共用配置、各建唯一子目录。
内部C测试缺少`A113_TEST_TMPDIR`时会拒绝创建，不回退`/tmp`；请通过CTest运行。
云端构建和测试的实际路径遵守AGENTS，只能位于`/home/nss-marker/yhr/Cry`及其子目录。

依赖：CMake **3.21 或更新版本**、Clang/GCC、Make 或 Ninja，以及 Git、patch、sh、awk、shasum。
默认测试配置还需要提供 SHA3-256 的 OpenSSL，用于独立核对原生准备日志的摘要。
macOS 可使用 Xcode Command Line Tools 提供的编译器；Linux 需安装对应编译工具和 CMake。
默认 preset 使用 Unix Makefiles；普通构建不联网、不下载密码库，也不需要 Python 或 jq。

只验收参考版功能时，可以使用独立入口：

```sh
cmake --preset baseline
cmake --build --preset baseline --target check-reference --parallel
build/cmake/reference/baseline selftest

cmake --preset sanitize
cmake --build --preset sanitize --target check-reference --parallel
```

`check-reference` 自动构建参考版 CLI 和两个功能测试程序，再运行带 `reference` 标签的
5 项 CTest：独立 NIST 向量与接口边界、随机源失败、普通三类输入的 CLI、向量解析、向量完整性。
它不构建其他变体或计时程序。测试要求 `BUILD_TESTING=ON`（两个 preset 都已启用）。
2026-10-06 首轮普通、ASan/UBSan 和 Ninja 多配置 Debug 检查均通过，来源及日志见
[参考版复核记录](docs/reference-recheck.md)。
随后独立收口在全新目录补查公共入口：普通与动态检查各通过参考 5 项和公共功能 11 项，
共 16 个不同测试；多配置 Debug 通过参考 5 项，见该记录的追加章节。

```sh
cmake --preset baseline
cmake --build --preset baseline --parallel
ctest --preset baseline

build/cmake/reference/baseline version
build/cmake/reference/baseline selftest
build/cmake/vulnerable/baseline demo
build/cmake/hardened/baseline demo
build/cmake/deployable/baseline demo
```

默认配置是 `RelWithDebInfo`，本机对应 `-O2 -g -DNDEBUG`，启用 C11 和严格编译警告。
四个变体的产物分别位于：

| 路径 | 用途 |
|---|---|
| `build/cmake/reference/baseline` | 参考版命令行 |
| `build/cmake/vulnerable/baseline` | 缺陷版命令行 |
| `build/cmake/hardened/baseline` | 防护版命令行 |
| `build/cmake/deployable/baseline` | 可部署恒时编码版命令行 |
| `build/cmake/reference/measure` | 参考版逐次计时 |
| `build/cmake/vulnerable/measure` | 缺陷版逐次计时 |
| `build/cmake/hardened/measure` | 防护版逐次计时 |
| `build/cmake/deployable/measure` | 可部署版逐次计时 |
| `build/cmake/reference/benchmark` | 参考版三类普通负载与读钟/空窗口自检 |
| `build/cmake/inspect_timing` | 原序保留的离线描述诊断，不给显著性告警 |
| `build/cmake/analyze` | 原始数据的第一轮固定统计检验，与实现无关 |
| `build/cmake/analyze_groups` | 原始数据的第二轮预注册分组检验，与实现无关 |

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
build/cmake/deployable/measure deployable-run 42 1000 \
    "$run_directory/deployable.csv" "$run_directory/deployable.meta"
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

**第一轮预注册的主比较本身并未稳定成立**：`message-zero:message-ones` 在五个全新公开种子上
缺陷版只有 4/5 显著、均值差 −11.4 至 −81.4ns，约为分组主效应的十分之一量级。
这一失败照实记录，没有改阈值、没有换种子重来，见 [统计说明](docs/statistics.md) 的多种子章节。

## 5. 第二轮预注册的分组检验

`analyze_groups` 是独立程序，读同一份 CSV，只做**一个**预先写定的比较：把
`message-zero`、`message-ones` 合成「方向恒定组」，把 `valid`、`bit-flipped`、`random`
合成「方向变化组」，单比较水平 1e-3：

```sh
build/cmake/analyze_groups "$run_directory/vulnerable.csv" "$run_directory/vulnerable.groups.report"
```

```text
analyze_groups CSV_FILE REPORT_FILE
```

该假设与种子清单在采集开始之前由**模块零提交**
`adf9db9d2734837de11274343d3828d49d0f2444` 固定在
[四模块设计](docs/tasks/four-module-design.md) 第 3.2 节。本仓库从未 push、没有第三方时间戳，
因此它只是**作者自证的顺序**，不是可向第三方证明的预注册。

五个新种子 × 四个变体各 25000 条的实测：缺陷版 **5/5 显著**（均值差 −663 至 −776ns）、
参考版与可部署版各 **5/5 不显著**、防护版 **4/5 不显著、1/5 显著**（残差 −30 至 −13ns，
方向一致）。报告的 `sample_independence_note=` 字段写明：固定密钥下方向恒定组只有两个不同密文
反复测量，这是机制审计统计量，不是攻击成功率。证据见
[evidence/statistics-multiseed](docs/evidence/statistics-multiseed/README.md)。

## 6. 四个变体的关系

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
使对照只改变「有无分支」这一项。

可部署版应用 [值屏障掩码补丁](docs/patches/message-value-barrier.patch)，
在防护版的掩码写法上**去掉**函数级优化控制，交由正常 `-O2` 优化，用于回答
「这种源码形态在真实优化下还剩不剩分支」。本机实测它在 Apple Clang 21 / `-O2` 下
**被内联进 `mlk_indcpa_enc`**，所以结论对象是调用者里的内联段，不是独立符号；
内联段里只剩一条按系数计数器的循环回边，没有消息位相关分支。
同一形态在 QEMU 模拟的 x86_64 GCC 13.3.0 下同样被内联、同样只剩循环分支。

四个变体各有独立的库、源码副本和可执行文件，
其余代码按所选构建配置编译，不在同一进程混合链接。

三个补丁都保持数学输出、重加密验证和隐式拒绝，不添加延迟或空转。
由于编码函数优化条件不同，**参考版与缺陷版/防护版的整体速度差本身不能证明秘密泄露**；
已知消息类别的时序也不能直接推广为未知密钥攻击。
上游 `mlk_poly_frommsg` 本来就是无分支实现，所以**防护版和可部署版都不是「修复」**，
也不比参考版更安全；它们是对照实验材料。对照设计与结果见
[防护说明](docs/mitigation.md)，可部署变体的实测见
[evidence/deployable](docs/evidence/deployable/README.md)。

## 7. 验证结果与证据边界

上一轮注册 **22 项 CTest**。独立参考入口阶段由18增至20，随后增加
`reference_benchmark` 和 `timing_diagnostics`。以下表格记录原有18项历史完整验收的覆盖；
本轮分阶段执行了16个功能测试、2个新增测试及历史重放，共19个不同测试，均通过。
这不是22项全量执行：未重新执行 `measurement`、`analysis`、`analysis_groups`。

| 检查 | 实际覆盖 |
|---|---|
| 四版 NIST 检查 | 每版 25 keygen、25 encaps、10 decaps、20 密钥校验；解封装含 5 组隐式拒绝 |
| 四版随机源失败 | 系统随机源打开失败的传播，以及恢复后的往返验证 |
| 三组差分 | 缺陷版、防护版、可部署版各对参考版：64 个种子 × 三类输入；拒绝样本另核对 J(z∥c) |
| CLI | 四版五类输入、参数错误、长度边界、目录读取错误、拒绝覆盖及跨版本密文一致 |
| 采集与记录 | 行数、类别顺序、单位、运行编号一致性；拒绝负数、溢出和尾随字段 |
| 统计检验 | 两轮检验各自可解析验证的合成数据、退化与样本不足处理、十类畸形 CSV 拒绝、四版真实数据全流程；另有第一轮归档报告的逐字重放 |
| 向量读取 | 拒绝截断用例、非法编号和非法十六进制 |
| 向量完整性 | 原始 NIST JSON 与转换文件的固定 SHA-256 |

NIST 原件、固定版本和转换方式保存在 `tests/vectors/` 与 [验证记录](docs/validation.md)。
预期答案不由被测实现生成；只有重新转换已保存的 JSON 时才需要 jq。

已执行的平台是 **Apple M5 / ARM64 macOS、Apple Clang 21**：干净构建、18 项 CTest、
独立 ASan/UBSan、格式检查和自有运行代码静态分析均已通过。
另有两次容器验证，都**不产出时序证据**（两个容器的时钟分辨率都是 1ms）：

- `linux/arm64` 容器、**真实 GNU GCC 13.3.0**：零警告构建、当时的 13 项 CTest 通过、
  首次执行两个补丁的 GCC 分支与 `/proc` 代码路径，证据见
  [evidence/linux-gcc](docs/evidence/linux-gcc/README.md)。
- **QEMU 模拟的 `linux/amd64`** 容器、GNU GCC 13.3.0：零警告构建、当时的 16 项 CTest 通过、
  四个变体的 x86_64 产物形态与调用路径核对，证据见
  [evidence/linux-amd64](docs/evidence/linux-amd64/README.md)。这是**模拟 linux/amd64 的
  产物形态与功能验证**，解释器实测为 `/usr/bin/qemu-x86_64`；它**不等于** x86_64 验证，
  模拟执行时间在任何意义上都不是时序证据。

两次容器验证的项数都是当时的实测值，低于现在的 18 项（第二轮统计程序的两项测试在它们之后加入）。

最近一次审查及对应产物证据见 [代码审查记录](docs/review.md)，本轮检查补齐的证据见
[evidence/review-four-module](docs/evidence/review-four-module/README.md)。
历史数据在 `docs/evidence/` 中按构建分别保存；每组绑定自己的源码版本和二进制摘要。
修改代码或编译条件后，必须重新定位机器码和重新采集，不能拿旧数据为新产物背书。

**目标机制、原始数据、本机统计确认和防护对照是分别核实的结论。**
统计确认限于 Apple M5 / ARM64 macOS，证据见
[evidence/statistics](docs/evidence/statistics/README.md)；同一固定检验在参考版上不显著。
去掉分支后的对照见 [evidence/mitigation](docs/evidence/mitigation/README.md)：
同一构建条件下防护版 0/10 显著、缺陷版 6/10 显著。
防护版残差的稳定性已由多种子复核回答：五个新种子上它的残差方向一致、量级 −30 至 −13ns，
其中一个种子越过第二轮阈值；仍不宣称防护版或可部署版已证明恒时。
**仍未执行真实 x86_64 Linux 主机时序实测**——模块二的 QEMU 模拟不改变这一条。
没有宣称参考版完全恒时，也没有完成密钥恢复。
下一阶段可以在真实 x86_64 Linux 主机上重跑同一组功能检查、采集与两轮固定检验。

## 8. 开发和代码风格

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
cmake --build build/ninja --target deployable
```

`BUILD_TESTING=OFF` 可关闭测试程序；`BASELINE_SANITIZERS=ON` 可开启动态检查。
多配置生成器需要 `cmake --build <目录> --config Debug` 与 `ctest --test-dir <目录> -C Debug`，
程序位于该构建目录的 `Debug/` 下。根 Makefile 只是 CMake/CTest 的兼容入口。

## 9. 文件职责与常见问题

| 目录/文件 | 职责 |
|---|---|
| `src/`、`include/` | C 接口封装、随机源、测试输入、CLI、计时、共用统计例程和两轮固定检验 |
| `tests/` | 功能与边界检查、命令编排、NIST 原件 |
| `CMakeLists.txt`、`CMakePresets.json`、`cmake/` | 唯一构建配置、测试注册、补丁副本及格式检查 |
| `tools/build_identity.sh` | 生成并嵌入构建追溯信息 |
| `vendor/` | 未修改的第三方源码与许可证 |
| `docs/` | 来源、机制、计时、统计、防护、验收、审查和原始证据 |
| `docs/tasks/` | 设计与验收契约、设计评审产物；模块零提交后不再修改 |

- **输出文件已存在**：程序有意拒绝覆盖，换用新的运行目录或文件名。
- **密文读取失败**：输入必须是恰好 1088 字节的可读文件；先检查路径及长度。
- **解封装显示完成**：只表示操作完成，不表示内部重加密比较通过。
- **报告显示 `p=0`**：`erfc` 在 |z| 很大时下溢，应以报告中的 z 值为准。
- **不知道测的是哪一版**：运行该目录下的 `baseline version`，并核对采集 `.meta` 中的实现名和文件摘要。
- **防护版比参考版慢**：防护版为保持与缺陷版同一构建条件保留了 `optnone`，见 [防护说明](docs/mitigation.md)；
  可部署版去掉了这层控制，本机实测该代价消失。
- **两份报告结论不一致**：`analyze` 和 `analyze_groups` 检验的是**不同假设**、阈值也不同
  （1e-4 对 1e-3），不能互相当作同一假设的复核。
- **均值差很大但判不显著**：判定统计量是秩检验；普通长尾按硬要求全部保留，均值对长尾不稳健。
- **更改编译器后配置报错**：使用新的构建目录，不在已有 CMake 缓存中切换工具链。

CLI 退出码：0 为成功，2 为公开命令参数错误，1 为运行或文件操作失败。
C API 的精确长度和返回值定义见 [mlkem.h](include/mlkem.h)；调用方需提供互不重叠的有效缓冲区。

## 10. 2026-10-06 验收收口与后续入口

本轮没有重写原始六模块。参考入口及公共功能已补查；对43份历史CSV、826300条记录
作离线审计，明确旧报告的分位数名称错误，数值和旧输出保留供重放。
[统计口径审计](docs/statistical-audit.md) 区分记录、运行、种子和重复密文，保留第一轮失败
与hardened显著残差；相同顺序不等于缓存或预测器状态受控。

[参考普通负载](docs/reference-benchmark.md) 新增三类1:1:1入口、读钟/空窗原始诊断、
完成状态及描述摘要。本机三次共9000条记录，混合均值13.90–14.44µs；分辨率和观察到的
最小正增量均1000ns，未配置CPU亲和性或频率，不扣开销、不删长尾。
源码、未提交内容与实际正式文件分别绑定，动态检查样本不进性能结果。

[原生x86_64 Linux准备包](docs/native-linux-reference.md) 已完成，**尚未执行**。
[R01–R12要求表](docs/requirement-evidence.md) 继续把防护、受控复测、第三方复现和实证
改进标为缺口；[下一轮比较合同](docs/next-comparison.md) 以未修改参考版为强基线，
先检验普通测量稳定性及全成本，输入选择路线目前尚无依据。
模块提交、实际测试范围、证据及交接见 [本轮验收报告](docs/acceptance.md)。

## 11. 有限批次普通测量比较

新增参考版 `reference/batch_benchmark`（K=1/4/16）、`paired_runner`共用预算/失败记录、
`analyze_paired`运行级成对分析及`paired_prepare`准备工具；核心和测试仍为C11。
原普通逐次CSV、历史统计程序和未修改参考内核保持有效。
当前注册28项，本轮普通与ASan/UBSan各选择相关12项通过，没有执行无关历史机制采集。

原生环境尚未提供，正式开发和20对确认均未执行，K没有选择。
软件夹具只证明实现及复算，不证明性能或R12改进。
数学与预算见 [执行规约](docs/batch-execution-v1.md)，完整入口、提交、检查范围、结果缺口
见 [本轮交接](docs/paired-round-results.md)。
[原生准备包](docs/paired-native-package.md) 不自动启动正式实验；
[复算说明](docs/paired-reproduction.md) 可从封存数据重建软件报告；
[贡献审查](docs/paired-contribution-review.md) 明确已有做法与待证明增量。


## 12. 代码审查修复与当前入口

2026-10-06追加审查修复了正式K资格、跨块顺序/构建条件、采集阶段对账、中心边界、
失败收尾预算保留和原生摘要解析。准备流程现在有完整截止、失败成本预留及完成收据。
本轮注册29项，普通与ASan/UBSan实际各13项通过；原生实验仍未执行。
详见[审查与交接](docs/paired-review-20261006.md)，历史章节保留原时点结果。

```sh
cmake -S . -B build/paired-current -DCMAKE_BUILD_TYPE=RelWithDebInfo -DBUILD_TESTING=ON -DBASELINE_SANITIZERS=OFF
cmake --build build/paired-current --target check-reference reference_benchmark reference_batch_benchmark \
    analyze_paired paired_runner paired_prepare native_digest test_native_digest test_batch_measurement \
    test_reference_benchmark test_paired_statistics test_paired_data test_paired_rejections \
    test_paired_runner test_paired_prepare paired_worker_fixture --parallel 4
ctest --test-dir build/paired-current --output-on-failure \
    -R '^(reference_kat|reference_random_failure|reference_cli|reference_vector_parser|vector_integrity|reference_benchmark|batch_measurement|paired_statistics|paired_data|paired_rejections|paired_runner|paired_prepare|native_digest)$'
sh tools/replay_paired.sh build/paired-current/analyze_paired \
    docs/evidence/paired-software-20261006/synthetic-cohort /absolute/new-software-report.txt
```
