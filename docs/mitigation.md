# 恒时编码补丁与对照验证

缺陷版把消息编码改成按位分支，统计确认见 [统计说明](statistics.md)。
防护版用 [恒时编码补丁](patches/message-constant-time.patch) 替换同一个函数，
**保留与缺陷版完全相同的函数级优化控制和循环结构**，只把 `if/else` 换成掩码选择：

```c
uint16_t message_bit = (uint16_t)((message_bytes[index / 8u] >> (index % 8u)) & 1u);
uint16_t selection_mask = (uint16_t)(0u - (unsigned)message_bit);
message_polynomial->coeffs[index] = (int16_t)(selection_mask & (uint16_t)MLKEM_Q_HALF);
```

这样设计是为了让对照只改变一件事。如果防护版按正常优化编译，它与缺陷版的差别就会同时
包含「没有分支」和「打开优化」两项，观察到的改善无法归因。补丁同样只作用于构建目录副本，
vendor 原件不修改，数学输出、重加密比较、J(z∥c) 和隐式拒绝都不变。

## 构建与运行

```sh
cmake --preset baseline
cmake --build --preset baseline --parallel
ctest --preset baseline

build/cmake/hardened/baseline version
build/cmake/hardened/measure hardened-run 20260930 5000 \
    runs/hardened.csv runs/hardened.meta
build/cmake/analyze runs/hardened.csv runs/hardened.report
```

三个变体各有独立的静态库、独立的构建目录源码副本和独立的可执行文件，不在同一进程混合链接。
`baseline version` 与采集 `.meta` 中的 `implementation` 都会显示 `hardened`。

## 功能等价

CTest 现有 13 项，其中与防护版直接相关的是：`hardened_kat`（80 组 NIST 独立答案，
含 5 组隐式拒绝）、`hardened_random_failure`（系统随机源失败传播与恢复）、
`equivalence_hardened`（64 个种子 × 三类输入的完整密钥/密文/输出摘要与参考版逐字节一致）。
CLI 检查另确认三个变体在相同种子下生成的五类测试密文互相一致。

## 对照结果

证据目录 [evidence/mitigation](evidence/mitigation/README.md)，源码提交 `e8f55e7`，
三个变体同一种子、同一类别顺序、每个 25000 条：

| 变体 | 判定显著 | 类别均值极差 | 最大 \|rank z\| |
|---|---|---|---|
| vulnerable | 6 / 10 | 824ns | 55.88 |
| hardened | 0 / 10 | 21ns | 2.15 |
| reference | 0 / 10 | 41ns | 1.31 |

缺陷版六项「恒定消息类 vs 变化消息类」全部显著（均值差 690–824ns）；防护版十项全不显著，
类别均值极差已小于参考版自身的 41ns。实测反汇编确认防护版函数内只剩循环边界分支，
消息位处由 `tbz` 变为 `and w8, w8, #0x1` 加后续掩码运算，地址与缺陷版一一对应。

## 边界

防护版残差随运行波动：本次最大 \|z\|=2.15 且方向不一致，此前一次采集为 \|z\| ≤ 3.61、
均值差 22–44ns 且方向一致。两次都未达预先规定阈值，但不能据此宣称该补丁已证明恒时：
更大样本、其他主机或其他优化级别都可能重新分辨出差异。本实验也没有验证编译器在打开优化后
是否会重新引入分支，这需要对目标配置的产物逐个反汇编确认。

防护版当前整体比参考版慢约 400ns，完全来自为保持对照而保留的 `optnone`。
如果要把恒时编码用于实际部署，应去掉函数级优化控制、改用上游的值屏障写法，
并对该配置重新做反汇编与统计验证；本仓库不把防护版当作可交付的加固实现。
真实 x86_64 Linux 的同组对照仍未执行；Linux 与 GNU GCC 的功能与产物验证见
[验证记录](validation.md)。

## 追加章节：可部署变体 deployable（正常优化下）

本章节闭合上一段自述的下一步，**不改写上面任何既有结论**。
防护版 hardened 原样保留：它是「只改变有无分支」这一项的对照，改动它会让归因失效。
第四个变体 `deployable` 用 [值屏障编码补丁](patches/message-value-barrier.patch) 单独实现。

### 机制

补丁相对上游只改四项，全部是源码形态：去掉函数级优化控制（不写任何 `__attribute__`）、
改成与另两个补丁同形的平铺 256 次系数循环、位选择沿用上游设施、不保留 `__loop__` 契约：

```c
for (unsigned coefficient_index = 0; coefficient_index < MLKEM_N; ++coefficient_index) {
    const uint8_t bit_mask = mlk_value_barrier_u8((uint8_t)(1u << (coefficient_index % 8u)));
    const uint16_t selection_condition =
        (uint16_t)(message_bytes[coefficient_index / 8u] & bit_mask);
    message_polynomial->coeffs[coefficient_index] =
        mlk_ct_sel_int16(MLKEM_Q_HALF, 0, selection_condition);
}
```

`selection_condition` 的显式 `uint16_t` 转换是为了过 `-Wconversion -Werror`
（`message_bytes[...] & bit_mask` 的整型提升结果是 `int`，而 `mlk_ct_sel_int16` 的
第三个参数是 `uint16_t`）。构建无警告，未删任何警告选项。

与另两个补丁的两处有意差别都在源码形态上，**不是运行时检查**：deployable 保留上游的
`MLKEM_INDCPA_MSGBYTES` 编译期 `#error` 守卫（纯预处理判断，不产生指令）与收尾的
`mlk_assert_abs_bound`（本仓库任何 preset 都未定义 `MLK_CONFIG_DEBUG`，该宏一律空展开，
不产生代码、永远不会触发）。

### 与参考版的实际差别

**deployable 不是对上游漏洞的修复，也不可能比参考版更安全。** 上游
`mlk_poly_frommsg` 本来就是带值屏障的无分支实现，参考版就是它按所选配置正常编译的结果。
deployable 与参考版的差别只有**源码形态**（平铺循环、自有命名、按系数取屏障）与
**编译器内联决策**，密码语义完全等同（80 组 KAT 含隐式拒绝、64 种子 × 三类逐字节等价）。

因此本变体的价值收窄为三点：证明这种源码形态在去掉 `optnone` 后 `-O2` 下**没有被编译器
重新引入消息位相关条件分支**；量化 hardened 的 `optnone` 代价在新变体上消失；
给出一个「若要部署，应该长成什么样」的可执行参照配置。
**本模块的真实价值落在「在正常优化下逐个反汇编确认无分支」，不在「更安全」。**

### 构建与运行

```sh
cmake -S . -B build/deployable -G Ninja -DCMAKE_BUILD_TYPE=RelWithDebInfo \
    -DBUILD_TESTING=ON -DBASELINE_SANITIZERS=OFF
cmake --build build/deployable --parallel
ctest --test-dir build/deployable --output-on-failure

build/deployable/deployable/baseline version
build/deployable/deployable/measure deployable-deployable 20260930 5000 \
    docs/evidence/deployable/deployable.csv docs/evidence/deployable/deployable.meta
build/deployable/analyze docs/evidence/deployable/deployable.csv \
    docs/evidence/deployable/deployable.report
```

CTest 项数由 13 增至**实测 16 项**，新增 `deployable_kat`（80 组 NIST 独立答案，
含 5 组隐式拒绝）、`deployable_random_failure`、`equivalence_deployable`（64 种子 × 三类
与参考版逐字节一致）；CLI 检查改为对 vulnerable / hardened / deployable 逐变体比较五类
测试密文与参考版一致。`ctest --preset baseline` 与 `ctest --preset sanitize` 均 16/16 通过，
无 ASan/UBSan 报告。

### 产物机制：deployable 被内联，结论来自调用者内联段

deployable 不带 `noinline`，实测 `-O2` 下编译器把编码函数**内联进了 `mlk_indcpa_enc`**：
全二进制中 `bl … <_baseline_native_poly_frommsg>` 的调用点计数为 **0**，
而内联判据正则 `(#|$)0x681|[#$ ]1665\b`（`MLKEM_Q_HALF`=1665）在调用者反汇编中命中。
因此**离线符号副本的反汇编不构成产物证据**，deployable 的结论取自
`mlk_indcpa_enc` 内的内联段（`0x100006e14`–`0x100006e5c`）。
reference / vulnerable / hardened 的调用点计数均为 1、调用者正则均未命中，结论仍取独立符号。
这意味着 **deployable 的产物证据与另三个变体不是同一粒度**，不能并列成一张等价的表。
设计明令不得为了拿到独立符号而给 deployable 加回 `noinline`，本次遵守。

内联段里只有一条条件跳转 `0x100006e5c b.ne`，由 `0x100006e58 cmp x8, #0x100`
（系数计数器与 256 比较）决定，属循环边界；消息字节由 `ldrb w13, [x21, x13]` 取入后
只流向 `and`/`neg`/`and` 掩码算术，不参与任何条件判断。
四个变体的全部条件跳转逐条列举与归属依据见
[evidence/deployable](evidence/deployable/README.md) 与同目录 `call-site-counts.txt`。

### 对照结果

证据目录 [evidence/deployable](evidence/deployable/README.md)，源码提交 `0cba2c7`，
四个变体**同一次采集会话**、同一种子 20260930、同一类别顺序、每个 25000 条：

| 变体 | 判定显著 | 类别均值极差 | 最大 \|rank z\| | 整体均值 | 相对 reference |
|---|---|---|---|---|---|
| reference | 0 / 10 | 27.8ns | 2.05 | 14102.96ns | — |
| vulnerable | 7 / 10 | 797.8ns | 66.79 | 14741.32ns | +638.36ns |
| hardened | 0 / 10 | 40.6ns | 3.06 | 14363.16ns | +260.20ns |
| deployable | 0 / 10 | 47.8ns | 2.11 | 14125.28ns | +22.32ns |

deployable 十项全不显著，最大 \|z\|=2.11，与参考版的 2.05 同量级：
**本次实测没有发现编译器在 `-O2` 下重新引入可被该固定检验分辨的消息位相关时间差异。**

性能上 **hardened − deployable = 237.88ns**，即 hardened 为保持对照而保留的 `optnone`
代价在 deployable 上消失；deployable 相对参考版只差 +22.32ns，落在本机噪声量级。

### 限制

本次会话测得的 `optnone` 代价是 **238ns**，与上一节记的「约 400ns」来自**不同采集会话**
（那次 hardened 14531–14552 对 reference 14127–14168）。两个数字都只在各自会话内有效，
**不得跨会话相减或互相替换**；未固定 CPU 亲和性与频率。

0/10 不显著**不等于**证明恒时：更大样本、其他主机、其他优化级别都可能重新分辨出差异。
如实记下两处不理想：deployable 的类别均值极差 47.8ns **大于**参考版的 27.8ns；
hardened 本次最大 \|z\|=3.06，高于归档那次的 2.15，两者都未达阈值，说明残差随运行波动。

反汇编结论只覆盖 Apple Clang 21 / ARM64 / RelWithDebInfo / Ninja / 上面写死的
`build/deployable` 配置命令这一配置和本次构建的地址；x86_64 产物形态待模块二在模拟环境给出，
且模块二不产出时序结论。补丁副本丢掉了上游 `__loop__` 契约，上游 CBMC 证明不覆盖被编译的
这份副本（另两个补丁同样如此）。

**下一阶段入口**：模块二（x86_64 指令集下的产物形态验证，明确不是时序证据），
设计见 [四模块设计](tasks/four-module-design.md) 第 2 节。
