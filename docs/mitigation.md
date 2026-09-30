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
