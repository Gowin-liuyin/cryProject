# 可部署恒时编码变体（deployable）在正常优化下的实测证据

**预注册凭证（模块零提交）**：`adf9db9d2734837de11274343d3828d49d0f2444`。
本目录的设计与验收标准由该提交固定在 `docs/tasks/four-module-design.md` 第 1 节，
取证全部在该提交之后执行。该凭证只有本地顺序效力，没有第三方时间戳
（本仓库从未 push，`origin/main` 实测为 `gone`，本地提交日期可由作者设置）。

**功能源码提交**：`0cba2c70893f433eb6a17d798660c0f407a7f6db`（模块一提交 A）。
**构建时工作区状态（逐字抄录 `.meta` 的 `git_worktree_status_*`）**：

```
git_worktree_status_begin
?? .agents/
?? docs/evidence/deployable/
git_worktree_status_end
tracked_delta_sha256=e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
```

即**被跟踪文件无任何未提交改动**（`tracked_delta_sha256` 为空内容摘要），
工作区只有两个未跟踪目录：`.agents/`（代理会话草稿，不参与构建）与本证据目录自身
（采集时正在被写入）。这与 `docs/evidence/mitigation` 的「`git status --porcelain` 为空」
不完全相同，按实测如实记录，不声称完全干净。

## 平台与工具版本

- Apple M5 / ARM64 macOS（Darwin 25.6.0，产品版本 26.6.2），`CLOCK_MONOTONIC` 分辨率 1000ns，
  **未固定 CPU 亲和性与频率**（`.meta`：`cpu_affinity=not_pinned`、
  `frequency_control=not_configured`）。
- 编译器 `Apple clang version 21.0.0 (clang-2100.3.34.2)`（`/usr/bin/cc`）。
- 反汇编 `Apple LLVM version 21.0.0` 的 `/usr/bin/objdump`。
- CMake 4.3.2、Ninja 1.13.0、OpenSSL 3.5.5、shasum 6.02。

## 本目录结论所覆盖的构建配置（逐字抄录 `.meta` 实测值）

```
build_system=CMake 4.3.2
generator=Ninja
configuration=RelWithDebInfo
compiler_flags= -O2 -g -DNDEBUG -std=c11
compile_options=-Wall -Wextra -Wpedantic -Wshadow -Wconversion -Wstrict-prototypes -Werror
compile_definitions=MLK_CONFIG_FILE="baseline_config.h"
sanitizers=OFF
```

配置、构建、测试命令（`configure.log`、`build.log`、`ctest.log` 的首行即为该命令）：

```sh
cmake -S . -B build/deployable -G Ninja -DCMAKE_BUILD_TYPE=RelWithDebInfo \
    -DBUILD_TESTING=ON -DBASELINE_SANITIZERS=OFF
cmake --build build/deployable --parallel
ctest --test-dir build/deployable -N
ctest --test-dir build/deployable --output-on-failure
```

**与 preset 的差异必须注意**：`baseline` preset 的生成器实测是 `Unix Makefiles`
（`CMakePresets.json:12`），而本目录用的是 `Ninja`。沿用 Ninja 是为了与归档的
`docs/evidence/mitigation` 三变体反汇编同配置可比。地址与反汇编结论不跨构建复用。

## deployable 是什么，与 reference 的实际差别是什么

**deployable 不是对上游漏洞的修复。** 上游 `mlk_poly_frommsg`
（`vendor/mlkem-native/mlkem/src/compress.c:696-726`）本来就是**无分支**实现：
它用 `mlk_value_barrier_u8((uint8_t)(1u << j))` 取位掩码，再用
`mlk_ct_sel_int16(MLKEM_Q_HALF, 0, msg[i] & mask)` 做选择。
reference 变体就是这份上游实现按所选配置正常编译的结果，
所以 deployable **不可能比 reference 更安全**。

补丁 `docs/patches/message-value-barrier.patch` 相对上游的改动只有四项，全部是**源码形态**：

1. **去掉函数级优化控制**：不写任何 `__attribute__`（vulnerable / hardened 两个补丁写的是
   `optnone,noinline`（Clang）/ `optimize("O0"),noinline`（GCC））。
   **后果**：deployable 同时失去 `noinline`，所以「反汇编的是不是实际执行的代码」
   必须由下面的调用路径核对回答——本次实测**它确实被内联了**，见「调用路径核对」。
2. **平铺单层 256 次系数循环**，参数名 `message_polynomial` / `message_bytes`、
   循环变量 `coefficient_index`，与 vulnerable / hardened 的源码形态一致，便于四份反汇编直接对照。
   值屏障按系数取（每次迭代算一次 `1u << (coefficient_index % 8u)`），与上游「外层按字节、
   内层按位」在数值上等价。
3. **位选择沿用上游设施**：`mlk_value_barrier_u8` 取位掩码 + `mlk_ct_sel_int16` 做选择。
   `mlk_ct_sel_int16` 的签名是 `(int16_t a, int16_t b, uint16_t cond)`，而
   `message_bytes[...] & bit_mask` 的整型提升结果是 `int`，所以 `selection_condition`
   必须显式转 `uint16_t` 才能过 `-Wconversion -Werror`。实际写法与设计写死的目标片段一致，
   未删任何警告选项，构建无警告。
4. **不保留** 上游的 `__loop__` 回路契约（另两个补丁同样如此）。

与另两个补丁的**两处有意差别**，必须按源码形态理解，**不是**运行时检查：

- **保留**上游编译期守卫 `#if (MLKEM_INDCPA_MSGBYTES != MLKEM_N / 8) #error … #endif`
  （`docs/patches/message-constant-time.patch` 实测把它删掉了）。它是纯预处理判断、
  **不产生任何指令**，对产物与反汇编结论零影响。
- **保留**收尾的 `mlk_assert_abs_bound(message_polynomial, MLKEM_N, MLKEM_Q)`。
  本仓库任何 preset 都没有定义 `MLK_CONFIG_DEBUG` / `MLKEM_DEBUG`
  （`sanitize` preset 只是 `CMAKE_BUILD_TYPE=Debug` 加 ASan/UBSan，并不定义它们），
  该宏一律展开成 `do {} while (0)`，**不产生代码、永远不会触发**。

**因此：deployable 的运行语义与 reference 等同**（64 种子 × 三类输入逐字节一致，见下）。
**本模块的真实价值不在「更安全」，而在「在正常优化下逐个反汇编确认无分支」**：
证明这种源码形态在去掉 `optnone` 后、`-O2` 下没有被编译器重新引入消息位相关条件分支，
并量化 hardened 为保持对照而保留 `optnone` 的时间代价在新变体上消失。
两者与 reference 的差别只是**源码形态**与**编译器内联决策**，不是密码语义。

## 功能等价（M1-1 / M1-2 / M1-3 / M1-4）

- `build/deployable/deployable/baseline version` 输出 `deployable ML-KEM-768 FIPS203`；
  采集 `.meta` 的 `implementation=deployable`、`run_id=deployable-deployable`。
- `ctest --test-dir build/deployable -N` **实测 16 项**（原 13 项 + `deployable_kat`、
  `deployable_random_failure`、`equivalence_deployable`），
  `ctest --test-dir build/deployable --output-on-failure` **16/16 全部通过**（见 `ctest.log`）。
  - `deployable_kat`：80 组 NIST 独立预期答案（25 keygen / 25 encaps / 10 decaps / 20 key checks，
    含 5 组隐式拒绝）。
  - `deployable_random_failure`：系统随机源失败传播与恢复。
  - `equivalence_deployable`：64 种子 × 三类输入的完整密钥/密文/输出摘要与 reference 逐字节一致。
  - `cli` 另覆盖四个变体的 CLI，并对 `vulnerable` / `hardened` / `deployable`
    逐变体比较五类测试密文与 reference 逐字节一致（`tests/test_cli.sh` 末尾那段
    原本硬编码只比较两个变体的块，本次改为对三个变体套循环）。
- `ctest --preset sanitize` **16/16 全部通过，无 ASan/UBSan 报告**（见 `sanitize-ctest.log`，
  首行即命令；`grep -niE 'AddressSanitizer|UndefinedBehaviorSanitizer|runtime error'`
  输出为空，`exit=1`，记录在 `record-checks.txt`）。
- `cmake --build --preset baseline --target format-check` 通过；
  `uvx --from cmakelang==0.6.13 cmake-format --check CMakeLists.txt cmake/*.cmake` 通过；
  `tests/*.sh`、`tools/*.sh` 的 `sh -n` 通过。

## 产物机制：四个变体的编码函数反汇编（M1-5）

反汇编命令（四份离线符号副本，格式与 `docs/evidence/mitigation/*-encoder-arm64.txt` 一致）：

```sh
objdump -d --disassemble-symbols=_baseline_native_poly_frommsg \
    build/deployable/<variant>/measure > {variant}-encoder-arm64.txt
```

### 第 1 步：逐条列出**所有**条件跳转（地址 + 助记符，一条不漏）

| 变体 | 文件:行 | 地址 | 助记符 |
|---|---|---|---|
| reference | `reference-encoder-arm64.txt:61` | `0x100002768` | `b.ne 0x10000269c` |
| vulnerable | `vulnerable-encoder-arm64.txt:13` | `0x1000026a8` | `b.lo 0x1000026b0` |
| vulnerable | `vulnerable-encoder-arm64.txt:25` | `0x1000026d8` | `tbz w8, #0x0, 0x1000026f8` |
| hardened | `hardened-encoder-arm64.txt:13` | `0x1000026a8` | `b.lo 0x1000026b0` |
| deployable（离线副本，**未被调用**） | `deployable-encoder-arm64.txt:20` | `0x1000026c4` | `b.ne 0x10000269c` |
| deployable（内联段，**实际执行**） | `deployable-caller-indcpa-enc-arm64.txt:51` | `0x100006e5c` | `b.ne 0x100006e34` |

检索命令为 `grep -nE '\b(b\.[a-z]+|cbz|cbnz|tbz|tbnz)\b' <文件>`；
deployable 内联段的检索范围是 `deployable-caller-indcpa-enc-arm64.txt` 的第 33–51 行
（地址 `0x100006e14`–`0x100006e5c`），该区间内只有上表那一条条件跳转。
无条件跳转（`b`）不计入条件分支，但 vulnerable 的 `if/else` 汇合用的
`0x1000026f4` / `0x10000270c` / `0x10000271c` 三条 `b` 一并在文件里可见。

### 第 2 步：逐条标注归属，并给出标注依据

| 地址 | 归属 | 依据（影响标志位的上一条指令及其操作数来源） |
|---|---|---|
| reference `0x100002768` | **循环边界** | 前一条 `0x100002764 cmp x8, #0x20`；`x8` 由 `0x10000275c add x8, x8, #0x1` 递增，初值 `0x100002690 mov x8, #0x0`，上界 `0x20`=32=`MLKEM_N/8`。内层 8 次位循环被完全展开（8 组 `mov w11,#1/2/4/…/0x80` + `ldrb`/`and`/`neg`/`and`/`strh`），所以只剩外层一条 |
| vulnerable `0x1000026a8` | **循环边界** | 前一条 `0x1000026a4 cmp w8, #0x100`；`w8` 来自栈上计数器 `[sp,#0xc]`（`0x10000271c str` 回写、`0x100002714 add w8,w8,#0x1`），上界 256=`MLKEM_N` |
| vulnerable `0x1000026d8` | **消息位相关** | `tbz` 直接测 `w8` 的第 0 位；`w8` 由 `0x1000026d4 lsr w8, w8, w9` 得到，其中 `w8` 来自 `0x1000026c4 ldrb w8,[x8]`，而 `x8` = `message_bytes`（`[sp,#0x10]`，即第二个参数）+ `coefficient_index/8`（`0x1000026b8 lsr w9,w9,#3`），`w9` = `coefficient_index & 7`。操作数链可追到消息字节取位 |
| hardened `0x1000026a8` | **循环边界** | 同 vulnerable：前一条 `0x1000026a4 cmp w8, #0x100`，`w8` 为栈上系数计数器。消息位处只剩 `0x1000026d8 and w8,w8,#0x1` 加 `0x1000026e4 neg` 掩码与 `0x1000026f4 and w8,w8,w9`（`w9`=`0x681`）算术，无条件跳转 |
| deployable 离线副本 `0x1000026c4` | **循环边界** | 前一条 `0x1000026c0 cmp x8, #0x100`；`x8` 由 `0x1000026bc add x8,x8,#0x1` 递增，初值 `0x100002690 mov x8,#0x0`，上界 256 |
| deployable 内联段 `0x100006e5c` | **循环边界** | 前一条 `0x100006e58 cmp x8, #0x100`；`x8` 由 `0x100006e54 add x8,x8,#0x1` 递增，初值 `0x100006e14 mov x8,#0x0`，上界 256 |

**无法判定归属的条件跳转：无**（上表六条全部有可追踪的操作数链）。
按设计口径，归属无法判定的条件跳转应按 0.5 记缺口、不得默认算作循环边界；
本次没有触发该条。

**一处与设计预期不符、按实测修正的记录**：设计把 ARM64 循环边界的实测形式写成
`b.ne`（Apple Clang）与 `b.ls`（ARM64 GCC）。本次在同一台机器、同一 Apple Clang 下
**还观察到 `b.lo`**（vulnerable / hardened 两个 `optnone` 变体）。
归属判定依据的是上一条 `cmp` 的操作数链，不是助记符清单，所以结论不受影响；
但助记符清单应按实测扩充为 `b.ne` / `b.lo`（Apple Clang，RelWithDebInfo），
`b.ls` 的 GCC 形式来自 `docs/evidence/linux-gcc`，x86_64 / GNU 侧由模块二实测填写。

### 第 3 步：deployable 的结论

**deployable 在 `-O2` 下没有出现任何消息位相关条件分支。** 实际执行的内联段里，
消息字节由 `0x100006e40 ldrb w13,[x21,x13]` 取入后，只流向
`and w12,w12,w13` → `neg w12,w12` → `and w12,w10,w12,lsr #16` → `strh` 这条算术链
（即 `mlk_ct_sel_int16` 的掩码选择），不参与任何条件判断；
唯一的条件跳转是按系数计数器与 256 比较的回边。离线副本的形态同样如此。
`x21` 是 `mlk_indcpa_enc` 的第二个参数（prologue `0x100006dec mov x21, x1`），即 `message_bytes`。

## 调用路径核对（M1-5a）：deployable 被内联，结论来自调用者内联段

**调用者是 `mlk_indcpa_enc`，不是 `mlk_indcpa_dec`**：解封装路径为
`dec → indcpa_enc`（隐式拒绝所需的重加密）`→ poly_frommsg`；`indcpa_dec` 只调 `poly_tomsg`。
`vendor/mlkem-native/mlkem/src/indcpa.c:544` 是全 vendor 唯一的 `poly_frommsg` 调用点，
位于 `mlk_indcpa_enc`（起自 `indcpa.c:518`）。

四个变体**无条件**产出调用者反汇编（这是判别手段，不是降级）：

```sh
objdump -d --disassemble-symbols=_baseline_native_indcpa_enc \
    build/deployable/<variant>/measure > {variant}-caller-indcpa-enc-arm64.txt
```

层级规则按实测走：四个变体的 `grep -c 'bl.*<_baseline_native_indcpa_enc>'`（全二进制）
**均为 2**，所以调用者一律取 `_baseline_native_indcpa_enc`，没有一个需要退到 `_baseline_native_dec`。

内联判据正则写死为 `(#|$)0x681|[#$ ]1665\b`（`MLKEM_Q_HALF` = 1665 = `0x681`；
正则同时覆盖 Apple objdump 的 `#0x681`、GNU x86_64 的 `$0x681` 与十进制 `1665` 印法，
本机实测印作 `mov w10, #0x681             ; =1665`）。实测：

| 变体 | `poly_frommsg` 调用点计数 | 调用者正则 `grep -nE` | 全二进制正则 `grep -cE`（特异性对照） | 情况 |
|---|---|---|---|---|
| reference | 1（`0x100006edc`） | 未命中，`exit=1` | 1 | **情况 1** |
| vulnerable | 1（`0x100006e94`） | 未命中，`exit=1` | 1 | **情况 1** |
| hardened | 1（`0x100006e90`） | 未命中，`exit=1` | 1 | **情况 1** |
| deployable | **0** | **命中**，`…:39 0x100006e2c mov w10, #0x681 ; =1665`，`exit=0` | **2** | **情况 2（被内联）** |

实际命令、命中行与空结果逐字记录在 `call-site-counts.txt`（含每个变体的调用点地址）。

**deployable 落在情况 2：`poly_frommsg` 调用点计数为 0，编译器把它内联进了
`mlk_indcpa_enc`。因此 `deployable-encoder-arm64.txt`（离线副本）不构成产物证据，
deployable 的产物形态结论来自 `deployable-caller-indcpa-enc-arm64.txt` 的内联段
（行 33–51，地址 `0x100006e14`–`0x100006e5c`）。**
离线副本仍然存在，是因为 `mlk_poly_frommsg` 是 `MLK_INTERNAL_API`（展开为空、外部链接），
符号必然被发出；但它没有任何调用点，所以不是执行路径。
deployable 按设计不带任何 `__attribute__`（含 `noinline`），内联是预期后果；
设计明令**不得**为了拿到独立符号而给 deployable 加回 `noinline`——那会退回 hardened 的处境，
本模块的目的就没了。本目录遵守该约束。

全二进制正则计数 2 的两处落点已逐处写明：一处在从未被调用的离线副本
（`deployable-encoder-arm64.txt:9`，`0x100002698`），一处在内联段（`0x100006e2c`）。
另三个变体全二进制计数均为 1，就在各自的编码函数内，调用者命中 0，
说明这不是只对 deployable 放宽的检查。

「按系数推进的 256 次循环结构」**只作佐证、不作判据**（grep 表达不出「256 次系数循环」）：
正则命中后人工读段，行号区间与逐条形态记在 `call-site-counts.txt` 的
「内联段佐证」小节。

`deployable-path-arm64.txt` 是 `build/deployable/deployable/measure` 的**全二进制**反汇编
（17619 行，格式照 `docs/evidence/final/vulnerable-path-arm64.txt`），
`grep -c 'bl.*<_baseline_native_poly_frommsg>'` 实测为 **0**，每处地址因此为空。

## 固定检验结果（M1-7）

四个变体在**同一次采集会话**、同一公开种子 `20260930`、每类 5000 次（每版 25000 条，
与 `docs/evidence/mitigation` 同口径），`RUN_ID` 为 `deployable-<variant>`，
用现有固定 `analyze`（`src/analyze.c` 的 10 个预先规定比较，Bonferroni 校正后
单比较水平 1e-4）判定：

| 变体 | 判定显著 | 类别均值极差 | 最大 \|rank z\| | 主比较 `message-zero:message-ones` |
|---|---|---|---|---|
| reference | 0 / 10 | 27.8ns（14085.0–14112.8） | 2.05 | 均值差 −7.8ns、z=−0.43、p=0.667 → not_significant |
| vulnerable | 7 / 10 | 797.8ns（14255.2–15053.0） | 66.79 | 均值差 −44.0ns、z=−5.14、p=2.82e-07 → **significant** |
| hardened | 0 / 10 | 40.6ns（14349.8–14390.4） | 3.06 | 均值差 +11.2ns、z=+0.35、p=0.730 → not_significant |
| **deployable** | **0 / 10** | **47.8ns（14110.4–14158.2）** | **2.11** | 均值差 −7.6ns、z=+0.51、p=0.608 → not_significant |

缺陷版六项「恒定消息类 vs 变化消息类」全部显著（均值差 748.4–797.8ns、\|z\| 61.9–66.8），
主比较本次也判显著，共 7/10。

**deployable 的结果：开优化后没有出现显著差异**，10 项全不显著，最大 \|z\|=2.11，
与 reference 的 2.05 同量级。**即本次实测没有发现编译器在 `-O2` 下重新引入可被该检验
分辨的消息位相关时间差异。** 如实记下两点不理想处：
deployable 的类别均值极差 47.8ns **大于** reference 的 27.8ns（也大于归档会话中
hardened 的 21ns），这属于本机噪声量级的波动，但不能说成「比 reference 更平」；
hardened 本次最大 \|z\|=3.06，高于归档 `docs/evidence/mitigation` 那次的 2.15，
同样未达阈值，再次说明残差幅度随运行波动。

沿用种子 `20260930` 是为了与归档的三变体对照直接可比；全新种子的稳健性由模块三负责。

## 性能（M1-8）：deployable 消除了 hardened 的 `optnone` 代价

同一次采集会话内（只在同一次会话内比较，不跨会话比较），25000 条的整体均值：

| 变体 | 整体均值 | 相对 reference | valid | bit-flipped | random | message-zero | message-ones |
|---|---|---|---|---|---|---|---|
| reference | 14102.960 | — | 14085.0 | 14102.0 | 14110.0 | 14105.0 | 14112.8 |
| vulnerable | 14741.320 | +638.36ns | 15047.6 | 15051.6 | 15053.0 | 14255.2 | 14299.2 |
| hardened | 14363.160 | +260.20ns | 14364.4 | 14390.4 | 14350.2 | 14361.0 | 14349.8 |
| **deployable** | **14125.280** | **+22.32ns** | 14158.2 | 14117.0 | 14110.4 | 14116.6 | 14124.2 |

（单位均为 ns。）

**hardened − deployable = +237.88ns**：这就是 hardened 为保持「只改变有无分支」这一对照
而保留 `optnone` 所付出的代价，在 deployable 上消失。deployable 相对 reference 只差
+22.32ns，落在本机噪声量级（reference 自身的类别均值极差为 27.8ns）。

**与 `docs/mitigation.md` 记的「约 400ns」的关系必须说清**：那个数字来自
`docs/evidence/mitigation` 的**另一次采集会话**（hardened 14531–14552 对 reference 14127–14168）。
本次会话测得的 `optnone` 代价是 238ns，不是 400ns。两次数字都只在各自会话内有效，
**不得跨会话相减**；本次只能结论「在本次同一会话内，hardened 的 `optnone` 代价为 238ns，
deployable 把它降到与 reference 相当的 +22ns」。

## 复现命令

```sh
cmake -S . -B build/deployable -G Ninja -DCMAKE_BUILD_TYPE=RelWithDebInfo \
    -DBUILD_TESTING=ON -DBASELINE_SANITIZERS=OFF
cmake --build build/deployable --parallel
ctest --test-dir build/deployable -N
ctest --test-dir build/deployable --output-on-failure

for variant in reference vulnerable hardened deployable; do
    objdump -d --disassemble-symbols=_baseline_native_poly_frommsg \
        "build/deployable/$variant/measure" > "$variant-encoder-arm64.txt"
    objdump -d --disassemble-symbols=_baseline_native_indcpa_enc \
        "build/deployable/$variant/measure" > "$variant-caller-indcpa-enc-arm64.txt"
    objdump -d "build/deployable/$variant/measure" > "$variant-full-arm64.txt"
    grep -cE 'bl.*<_baseline_native_poly_frommsg>' "$variant-full-arm64.txt"
    grep -nE '(#|\$)0x681|[#$ ]1665\b' "$variant-caller-indcpa-enc-arm64.txt"
    "build/deployable/$variant/measure" "deployable-$variant" 20260930 5000 \
        "docs/evidence/deployable/$variant.csv" "docs/evidence/deployable/$variant.meta"
    build/deployable/analyze "docs/evidence/deployable/$variant.csv" \
        "docs/evidence/deployable/$variant.report"
done

shasum -a 256 -c docs/evidence/deployable/SHA256SUMS   # 在仓库根目录执行
```

## 结论边界（支持什么／不支持什么）

**支持**：

- 在本配置下，这种源码形态（平铺 256 次系数循环 + 上游值屏障 + 不带函数级优化控制）
  经 `-O2` 编译后，实际执行的代码里**没有消息位相关条件分支**，只有一条按系数计数器的回边。
- 在同一次采集会话内，hardened 的 `optnone` 代价（本次 238ns）在 deployable 上消失。
- deployable 与 reference 的运行语义等同（80 组 KAT 含隐式拒绝、64 种子 × 三类逐字节等价、
  五类 CLI 测试密文逐字节一致、随机源失败传播）。

**不支持**：

- **不支持**「deployable 修复了上游漏洞」或「deployable 比 reference 更安全」。
  上游此函数原本无分支，本变体不可能更安全。
- **不支持**「deployable 已被证明恒时」。0/10 不显著不等于恒时：更大样本、其他主机、
  其他优化级别都可能重新分辨出差异。
- 反汇编结论只覆盖 **Apple Clang 21 / ARM64 / RelWithDebInfo / Ninja /
  上面写死的 `build/deployable` 配置命令**这一配置，和本次构建的地址。
  x86_64 产物形态由模块二在**模拟环境**给出，且模块二不产出时序结论。
  macOS/ARM、交叉编译或模拟器都不能冒充真实 x86_64 Linux 实测。
- **本目录的 `sanitize-ctest.log` 属另一套配置**：它来自 `build/cmake-sanitize`
  （`sanitize` preset：`Unix Makefiles` / `Debug` / ASan+UBSan，见 `CMakePresets.json:12,22-29`），
  与本目录其余日志所属的 `build/deployable`（Ninja / RelWithDebInfo）不是同一配置。
  它**只用于功能正确性**，不支持任何产物形态、地址或性能结论。
- 性能数字只在同一次采集会话内有效；未固定 CPU 亲和性与频率，整体水平随机器负载平移。
  **不得**把本次的 238ns 与归档会话的约 400ns 跨会话相减或互相替换。
- 补丁副本丢掉了上游 `__loop__` 契约，因此上游 CBMC 证明**不覆盖**被编译的这份副本
  （另两个补丁同样如此，本次一并写明）。
- deployable 保留的 `mlk_assert_abs_bound` 在本仓库任何 preset 下都是空展开，
  保留的 `MLKEM_INDCPA_MSGBYTES` 编译期守卫是纯预处理判断、不产生指令。
  **两者都不得**被表述为「deployable 额外带了边界检查／运行时检查」；
  它们只是**源码形态**上与另两个补丁的差别。
- **deployable 的产物证据与另三个变体不是同一粒度**：它落在 M1-5a 情况 2（被内联），
  结论对象是 `mlk_indcpa_enc` 里的内联段；reference / vulnerable / hardened 的结论对象是
  独立符号。因此四个变体的产物形态**不能并列成一张等价的表**，上面的条件分支表已按
  「离线副本（未被调用）」与「内联段（实际执行）」分行标注。

## 未能完成的项

无。M1-1 至 M1-10 全部在本机闭合，未触发 0.5 的缺口记录规程，也未触发模块间依赖降级规则
（`deployable` 目标构建成功，`deployable_kat` / `deployable_random_failure` /
`equivalence_deployable` 三项全部通过），因此 `ctest -N` 实测 16 项即为未降级的预期值。

设计 1.2 列为「可选补充观察」的「无屏障掩码在 `-O2` 下的一次性反汇编」**未做**。
设计原文写明「做不做都不影响验收」，本目录因此不含该材料，也不对
「无屏障掩码是否会被还原成分支」给出任何本机结论。
