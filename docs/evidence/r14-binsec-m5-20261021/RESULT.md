# R14：M5 重加密路径的 Binsec `checkct`（i386 裸机驱动 + 显式 secret global）

**结论先行**：R05 §5 登记为 `unknown` 的「M5 重加密步骤 Binsec `checkct`」，本轮在
真实 x86_64 Linux 裸金属上跑出了**有判定的结果**：在显式 `secret global` 建模下，
M5 参考实现的**重加密比较步骤**与**消息编码步骤**都没有秘密相关的控制流；
同时用 M4 已知脆弱内核做了阳性对照，证明这套配置**不会假阴性**。

本轮登记的关键事实是：**R05 当年登记的「2^256 状态空间」阻塞并不成立**——它当时是
一个前提假设（“若把消息设成秘密，路径数会达 2^256 量级”），而实际把 32 字节消息
声明为秘密后，i386 产物里的消息编码步骤只有 **1 条路径**：该实现的控制流本来就不
依赖消息位。因此模型覆盖的是**完整步骤**，不是受约束取值域的替代品。

**本轮不改变任何既有判定**：不改 M1–M5 的结论，不动任何 Holm 家族，不进既有
统计口径。形式化结果只回答「控制流是否依赖秘密」这一个属性。

---

## 1. 承接的问题（R05 §5 的三条阻塞）

[R05 §5](../r05-locate-20261016/RESULT.md) 登记的原始事实与理由：

| # | 阻塞 | R05 的原话要点 |
|---|---|---|
| 1 | 架构 | Binsec 0.11.3 的 `-isa` 列表虽含 `x86-64`，但解码器不存在（实验 A、C 报 `Can not resolve decoder for x86-64`） |
| 2 | 模型 | `checkct` 必须用显式 `secret global` 声明才能判“秘密相关”；配错时工具仍在 **0 路径 / 0 指令** 上打印 `secure`（实验 B、B4），把输入声明成 `public` 会让已知脆弱内核翻成假阴性（实验 B3） |
| 3 | 状态空间 | M5 重加密的消息是 32 字节自由值，`poly_frommsg` 每个消息位都会分叉，把消息设成秘密会让路径数达 2^256 量级 |

本轮对第 1、2 条给出工程解（i386 裸机驱动 + 显式声明 + 阳性对照），对第 3 条把它
变成**可测量的问题**：不再是「假定会分叉」，而是「实际数出来是 1 条路径」。

R05 当时的对照实验（B2：32 条路径、`Instruction 0x8049047 has control flow leak`、
`insecure`）本轮用同一套工具与选项重跑，作为本轮配置的阳性对照（见 §3）。

---

## 2. 方法

### 2.1 工具与环境

| 项 | 值 | 出处 |
|---|---|---|
| 主机 | `nss-marker@10.144.144.5`，`nss-m`，Linux x86_64（真实裸金属，非虚拟机） | 远端 `uname -m` |
| Binsec | 0.11.3，`/home/nss-marker/yhr/Cry/platform-m4-binsec-20261016-73f14add5392/runtime/binsec-0.11.3/_opam/bin/binsec` | 各次 `identity.txt` |
| 求解器 | Z3 4.15.3，同上 `runtime/z3-4.15.3-x64-glibc-2.39/bin/z3` | 各次 `identity.txt` |
| 编译器 | `clang`（仓库 CMake 目标，详见 §2.3） | 构建日志 |
| 源码提交 | `7c36f850`（`SOURCE_EXPORT.sha256` 见本目录） | `SOURCE_EXPORT.sha256` |

Binsec 与 Z3 的 SHA-256、版本行、被测 ELF 的 SHA-256 与 `file` 输出，逐次落盘在
`m4-vulnerable/identity.txt`、`m4-ct/identity.txt`、`m5-compare/identity.txt`、
`m5-frommsg/identity.txt`。

### 2.2 建模：秘密/公开的划分

两个目标的划分都写在 Binsec 配置里（`model.cfg`），驱动本身不实现密码学，只调用
被测实现：

**目标一 `m5-compare`——FO 重加密的比较步骤**

```
secret global m5_secret_reencrypted      # 重加密出的密文（由秘密密钥导出）
public global m5_public_ciphertext, m5_public_length
assume 0 < m5_public_length < 1089
```

比较长度是**公开**的，取值 1..1088。经典 FO 侧信道正是出在「比较提前退出」，
所以秘密侧是重加密出的密文、公开侧是收到的密文与长度。

**目标二 `m5-frommsg`——消息编码步骤**

```
secret global m5_secret_message          # 32 字节消息
public global m5_public_coefficients
```

秘密就是 32 字节消息本身，**没有收窄取值域**。

### 2.3 i386 裸机产物

Binsec 0.11.3 解不了 x86-64，所以走 i386 路线。工程条件与 M4 夹具一致：
`-m32 -O1 -g -ffreestanding -fno-pie -fno-stack-protector -fno-builtin`，
链接 `-m32 -nostdlib -no-pie -Wl,-e,m5_entry`，分析入口 `m5_entry`、终点 `m5_halt`。
链接加 `--gc-sections`，只保留被测函数及其依赖，不把整份 mlkem-native 拉进来。

本轮新增两处工程处理（都记在 `cmake/PlatformM5.cmake` 与
`tools/platform_m5/binsec/m5_formal_config.h`）：

1. i386 裸机环境没有 32 位 libc 头（`/usr/include/bits/libc-header-start.h` 找不到），
   mlkem-native 默认会包含 `<string.h>`。改用 `MLK_CONFIG_CUSTOM_MEMCPY` /
   `MLK_CONFIG_CUSTOM_MEMSET` 走自带实现；**其余配置项与仓库默认的
   `include/baseline_config.h` 逐字一致**（参数集 768、命名空间前缀
   `baseline_native`、关闭随机化 API），保证被分析的实现与正式采集产物同一条代码路径。
2. `mlk_poly_frommsg` 走命名空间前缀（`baseline_native_poly_frommsg`），驱动需要
   `#include "compress.h"` 才能拿到正确声明。

被测产物本体（4 个 i386 ELF）已拉回本目录 `elf/`，摘要见 `elf/SHA256SUMS`；
`file` 输出均为 `ELF 32-bit LSB executable, Intel 80386`。

### 2.4 判据与不放宽项

- 只开 `control-flow` 与 `memory-access` 两类检查（`multiplication`/`dividend` 在
  Binsec 0.11.3 里是实验特性，且与 M2 的 div 类判定无关）。
- `-sse-depth 10000`、`-sse-timeout 120`、`-smt-timeout 5` 固定，不因结果不好而放宽。
- 深度/超时固定，**不做重试择优**。
- 「secure/insecure」只以**非零路径数、非零指令数**的运行为准；0 路径的空结论
  （R05 实验 B/B4 的坑）不算阴性证据。
- 退出码、原始 stdout/stderr、checkct 统计文件（`checkct.toml`）、反汇编
  （`disasm.txt`）全部原样保留。

---

## 3. 结果

### 3.1 四次运行总表

| 运行 | 被测对象 | 秘密 | 路径数 | 静态指令 | 展开指令 | checkct 判定 | 退出码 |
|---|---|---|---|---|---|---|---|
| `m4-vulnerable` | M4 人工提前退出比较 | 16 字节秘密 | **32/32** | 32 | 335 | **insecure**（`Instruction 0x8049047 has control flow leak`） | 0 |
| `m4-ct` | M4 恒定时间比较 | 16 字节秘密 | 1/1 | 36 | 139 | secure | 0 |
| `m5-compare` | M5 FO 重加密比较步骤 | 1088 字节重加密密文 | **1088/1088** | 28 | 18504 | **secure**（17.6 s） | 0 |
| `m5-frommsg` | M5 消息编码步骤 | 32 字节消息 | **1/1** | 39 | 3061 | **secure** | 0 |

原件：`m4-vulnerable/`、`m4-ct/`、`m5-compare/`、`m5-frommsg/`（各含
`identity.txt` / `model.cfg` / `disasm.txt` / `stdout.txt` / `stderr.txt` /
`status.txt` / `checkct.toml` / `console.txt`）。

### 3.2 阳性对照成立（不假阴性）

`m4-vulnerable` 在**完全相同**的工具、选项与驱动脚本下报出控制流泄露并给出
`insecure`，32 条路径全部完成。这直接排除 R05 实验 B/B4 指出的「配置没配好就
打印 secure」的假阴性来源：**同一套配置既能判阳性，也能判阴性**。

`m4-ct`（同一夹具的恒定时间比较版本）报 `secure`，1 条路径、36 条静态指令——
说明工具不会把「没走过的路径」算成通过。

### 3.3 M5 比较步骤：1088 条路径全部由**公开**长度驱动

`m5-compare` 的 1088 条路径与 `assume 0 < m5_public_length < 1089` 的公开取值
一一对应：比较长度是公开变量，循环次数因而公开。秘密侧（1088 字节重加密密文）
不产生任何路径分叉。

这一点很重要：R05 当年担心的是「秘密导致路径爆炸」。实际爆炸的是**公开长度**，
且 1088 条路径全部完成（`pending 0` / `discontinued 0`），说明这是**完整枚举**，
不是被截断的采样。

**口径说明**：「1088 条路径与公开长度 1..1088 一一对应」是**由 `assume 0 <
m5_public_length < 1089` 与路径总数推出的推断**，本轮**没有**逐路径核对路径与长度的
对应关系（checkct 不导出该映射）。该推断与「秘密不产生路径分叉」这一由反汇编
直接支持的结论方向一致，但**前者是推断、后者是原件核对**。

反汇编（`m5-compare/disasm.txt`）里该函数只有三处跳转：
`je`（公开长度非零的假设检查）、`jne`（循环计数）、`jmp`（回边）——
没有一处依赖秘密。

### 3.4 M5 消息编码步骤：秘密是 32 字节消息，路径数仍是 1

`m5-frommsg` 在**完整 32 字节消息为秘密**的模型下只有 **1 条路径**、39 条静态
指令、3061 条展开指令，判定 `secure`。

也就是说：**R05 登记的 2^256 状态空间阻塞不成立**。原因是该实现的控制流本来
就不依赖消息位——`mlk_poly_frommsg` 的位选择用值屏障（value barrier）实现，
编译器无法把它识别成 0/1 选择，也就无从生成分支。

i386 产物里 `baseline_native_poly_frommsg` 的全部跳转共 **4 条**（`m5-frommsg/disasm.txt`）：
**2 条条件跳转**（`je 8049078`、`jne 8049058`）+ **1 条进入跳转**（`jmp 8049053`）
+ **1 条无条件回边**（`jmp 8049042`）。

| 指令 | 作用 | 是否依赖秘密 |
|---|---|---|
| `jmp 8049053`（`8049040`） | 进入字节循环 | 否（公开循环上界） |
| `cmp $0x8,%ecx; jne`（`8049074`） | 位循环计数（8 位） | 否（公开循环上界） |
| `cmp $0x100,%edi; je`（`8049051`） | 字节循环计数（256 系数） | 否（公开循环上界） |
| `jmp 8049042`（`8049076`） | 回边 | 否 |

### 3.5 i386 形式化产物与 x86-64 正式产物的结构对照

为把「i386 模型」与「正式 x86-64 产物」的关系说清，本轮把 x86-64 正式采集产物
（`build-m5ref` 的 `reference/benchmark`）里同名函数的反汇编一并拉回
（`x86-64/poly_frommsg.asm`）。

两个架构的 `baseline_native_poly_frommsg` **位选择与循环结构逐条相同**（同一条
`shl`/`and`/`neg`/`sar`/`and $0x681` 序列、同样的两处循环计数跳转），
**寄存器分配不同**（x86-64 用 r8/rdx/rcx，i386 用 ebx/edx/ecx），
因此不能称「指令序列逐条相同」：

```
i386   : shl %cl,%eax ; and (%ebx),%al ; movzbl %al,%eax ; neg %eax ; sar $0x10,%eax ; and $0x681,%ax ; mov %ax,(%edx,%ecx,2)
x86-64 : shl %cl,%eax ; and (%rsi),%al ; movzbl %al,%eax ; neg %eax ; sar $0x10,%eax ; and $0x681,%ax ; mov %ax,(%r8,%rdx,2)
```

跳转也只有同样两处循环计数（x86-64 是 `cmp $0x8,%ecx; jne` 与
`cmp $0x100,%edi; jne`）。即：**i386 形式化模型与 x86-64 正式产物在该函数上的
控制流结构一致**，这是把 i386 结论外推到正式产物的直接依据（仍不是恒时证明）。

**必须同时说明的差异**：两者的**编译身份不同**——i386 形式化产物用仓库的
`-m32 -O1 -ffreestanding` 构建（`cmake/PlatformM5.cmake`），x86-64 正式产物是
R09 12 格里的 `-O2`/`-O3`/`-Os` 构建。**优化级别不同**是该对照的实质限制：
上文的一致性只在**控制流结构**这一层面成立，不等于两个产物逐字节等价，
也不等于「x86-64 上任意优化级别都同样如此」。

`mlk_ct_memcmp` 是 `static inline`，在 x86-64 产物里被内联进调用者，没有独立符号，
因此 `x86-64/ct_memcmp.asm` 为空（该文件的行数为 0 是这个原因，不是取不到）。
x86-64 侧的比较步骤的既有证据仍以 M5 RESULT 记录的反汇编与 dudect 为准。

---

## 4. 能支持什么 / 不能支持什么

### 4.1 本轮支持的结论

1. 在**显式 secret global 建模**下，M5 参考实现（mlkem-native）的
   * FO 重加密比较步骤 `mlk_ct_memcmp`（秘密 = 1088 字节重加密密文，公开 = 收到的
     密文与长度 1..1088）：**1088 条路径全部完成，无控制流泄露**。
   * 消息编码步骤 `mlk_poly_frommsg`（秘密 = 完整 32 字节消息，无收窄）：
     **1 条路径，无控制流泄露**。
2. 这套配置**能检出**已知脆弱内核（M4 阳性对照：32 条路径、`insecure`），
   因此上述阴性不是「配错导致的空结论」。
3. R05 §5 的第 3 条阻塞（2^256 状态空间）在**完整消息秘密**的模型下不成立；
   本轮给出的是**完整步骤**的判定，不是受约束取值域的替代品。

### 4.2 本轮不支持、也不主张的

1. **不是恒时证明**：checkct 只回答「控制流是否依赖秘密」，不覆盖算术泄漏、
   缓存泄漏、内存访问模式，也不覆盖 `multiplication`/`dividend` 两类检查
   （本轮按 R05 §4.4 的边界没有开）。
2. **架构不同**：被分析的是 i386 产物，不是 x86-64 正式产物。§3.5 的结构对照
   表明这两个函数在两种架构上**位选择与循环结构一致、寄存器分配不同**（且两者编译身份不同，
   见 §3.5），但**这是逐函数对照，不是全程序等价、也不是逐字节等价**；
   换编译器、换优化级别、换函数都可能改变结论。
3. **覆盖范围有限**：分析的是重加密路径上的**比较步骤**与**消息编码步骤**两步，
   不是整个 `mlkem_decapsulate`（后者还包含 `indcpa_dec`、重加密本身、拒绝 KDF 等）。
4. **不覆盖实现变体**：本轮分析的是仓库默认的 `baseline_native` 命名空间实现；
   打过 `message-branch.patch` 的人工分支变体、以及 liboqs 0.10.0 历史实现，
   都不在本轮结论覆盖范围内。
5. **不改变任何既有判定**：M1–M5 的结论、四个 Holm 家族、R09 的可分辨性结论
   全部不变。本结果是**新增的、族外的**一层证据。

---

## 5. 复现命令

```sh
# 远端：构建四个 i386 形式化产物
cmake -S <source> -B <build> -DCMAKE_BUILD_TYPE=RelWithDebInfo \
    -DBUILD_TESTING=ON -DBASELINE_ENABLE_PLATFORM=ON
cmake --build <build> --target platform_m4_formal_vulnerable platform_m4_formal_ct \
    platform_m5_formal_frommsg platform_m5_formal_compare --parallel 2

# 远端：四次 checkct（参数与 M4 夹具同一契约）
sh tools/platform_m5/binsec/run_checkct_m5.sh <binsec> <z3> \
    <build>/platform_m4_formal_vulnerable tools/platform_m4/checkct_1_16.cfg      <out>/m4-vulnerable 180
sh tools/platform_m5/binsec/run_checkct_m5.sh <binsec> <z3> \
    <build>/platform_m4_formal_ct          tools/platform_m4/checkct_fixed16.cfg   <out>/m4-ct         180
sh tools/platform_m5/binsec/run_checkct_m5.sh <binsec> <z3> \
    <build>/platform_m5_formal_compare     tools/platform_m5/binsec/checkct_m5_compare.cfg <out>/m5-compare 600
sh tools/platform_m5/binsec/run_checkct_m5.sh <binsec> <z3> \
    <build>/platform_m5_formal_frommsg     tools/platform_m5/binsec/checkct_m5_frommsg.cfg <out>/m5-frommsg 900
```

云端工作根：`/home/nss-marker/yhr/Cry/r13-network-20261020/`
（`source-7c36f850/`、`runs/build-platform-7c36f850/`、`runs/binsec/`），
拉回副本是本目录 `docs/evidence/r14-binsec-m5-20261021/`。

---

## 6. 对既有登记的更新

| 登记位置 | 原状态 | 本轮之后 |
|---|---|---|
| [R05 §5](../r05-locate-20261016/RESULT.md) | `unknown`（有具体阻塞原因） | **已执行 + 判定**：两个 M5 目标均无秘密相关控制流；阳性对照成立 |
| R05 §5 的第 3 条阻塞（2^256 状态空间） | 作为前提假设登记 | **实测不成立**：完整 32 字节消息为秘密时路径数为 1 |

R05 的原始结论文件**不就地改写**（按仓库纪律），本目录是新一层的证据与结论。
