# 恒时编码补丁的对照实测证据

功能源码提交：`8e437f27f8a27f63a4edbe54f0472f040d6b091f`。构建时工作区干净，
`tracked_delta_sha256` 为空内容摘要 `e3b0c442…7852b855`。

平台：Apple M5 / ARM64 macOS（Darwin 25.6.0）、Apple Clang 21、CMake 4.3.2 / Ninja、
RelWithDebInfo（`-O2 -g -DNDEBUG -std=c11`）、`CLOCK_MONOTONIC` 分辨率 1000ns、
未固定 CPU 亲和性与频率。configure.log、build.log、ctest.log 对应全新 build/mitigation 目录，
13 项 CTest 全部通过；compile_commands.json 保存实际编译命令。

## 对照设计

三个变体使用同一采集程序、同一公开种子 20260930、每类 5000 次（共 25000 条）。
record-checks.txt 用 `cut` 提取类别列并逐字节比较，确认三者的类别顺序完全相同，
因此输入构造、样本顺序与缓存/序列条件在三者之间一致。

- `vulnerable`：编码函数按消息位 `if/else`，函数级 `optnone,noinline`。
- `hardened`：**相同的** `optnone,noinline` 和相同循环结构，只把分支换成掩码选择。
- `reference`：上游常数时间实现，按所选配置正常优化（无函数级优化控制）。

vulnerable 与 hardened 之间只差分支本身，优化条件不变，因此差异不能归因于优化级别。

## 产物机制

三份反汇编中编码函数都位于 0x100002690：

| 变体 | 函数内条件分支 | +0x48 指令 |
|---|---|---|
| reference | 仅 0x100002768 循环边界 `b.ne` | 无分支算术选择 |
| vulnerable | 循环边界 `b.lo` 与 0x1000026d8 的 `tbz w8, #0x0` | `tbz`，由消息位控制 |
| hardened | 仅 0x1000026a8 循环边界 `b.lo` | `and w8, w8, #0x1`，随后 `neg` 掩码 |

地址只对应本目录 binaries.sha256 与 record-checks.txt 记录的摘要，不跨构建复用。

## 固定检验结果

同一族 10 个预先规定的类别比较，Bonferroni 校正后单比较水平 1e-4。

| 变体 | 判定显著 | 类别均值极差 | 最大 \|rank z\| |
|---|---|---|---|
| vulnerable | 7 / 10 | 752ns（14308–15060） | 62.69 |
| hardened | 0 / 10 | 45ns（14264–14309） | 3.61 |
| reference | 0 / 10 | 29ns（14087–14116） | 1.01 |

缺陷版「恒定消息类 vs 变化消息类」六项全部显著，均值差 670.8–752.0ns、|z| 在 59.0–62.7 之间；
第 7 项显著比较是 `message-zero:message-ones`（均值差 -60.4ns、z=-4.67）。
防护版这六项同方向残差为均值差 22–44ns、|z| 在 2.47–3.61 之间，全部未达预先规定阈值，
约为缺陷版效应的 5%（1/20 量级）。`message-zero:message-ones` 在防护版为 z=-0.06、p=0.95。

防护版整体比参考版慢约 200ns，原因是 `optnone` 关闭了该函数的优化，
这是为保持与缺陷版同一构建条件而有意付出的代价，不是防护方案的必要开销。

## 结论边界

本组数据支持：在同一构建条件下去掉消息位分支后，类别相关的时间差异降到固定检验判不显著。
不支持：防护版已被证明恒时。残差仍有同方向的小幅偏差，更大样本或其他主机可能重新分辨出来；
本实验也未覆盖编译器自动向量化、其他优化级别或真实 x86_64 Linux / GCC 产物。
