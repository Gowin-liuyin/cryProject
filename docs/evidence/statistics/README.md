# 正式统计确认的实测证据

功能源码提交：`d322cbf2743a6db8529a59641f161c688bff7acf`。构建时工作区干净，
`tracked_delta_sha256` 为空内容摘要 `e3b0c442…7852b855`。此目录后续只增加本说明与校验文件。

平台：Apple M5 / ARM64 macOS（Darwin 25.6.0）、Apple Clang 21、CMake 4.3.2 / Ninja、
RelWithDebInfo（`-O2 -g -DNDEBUG -std=c11`）、`CLOCK_MONOTONIC` 报告分辨率 1000ns、
未固定 CPU 亲和性与频率。configure.log、build.log、ctest.log 记录全新 build/statistics
目录的配置、构建与 10 项 CTest 全通过；compile_commands.json 保存实际编译命令。

## 数据集

| 文件前缀 | run_id | 公开种子 | 记录数 |
|---|---|---|---|
| `reference` / `vulnerable` | `stats-reference` / `stats-vulnerable` | 20260930 | 各 25000（五类各 5000） |
| `reference-replication` / `vulnerable-replication` | `replication-reference` / `replication-vulnerable` | 42 | 各 25000（五类各 5000） |

每组包含原始逐次 CSV、运行元数据 `.meta` 和固定检验报告 `.report`。保留全部原始值，
未删除长尾，未用均值代替逐次数据。两个种子是各自独立的一次采集，不是同一批数据的重算。

## 独立核对

record-checks.txt 包含：C 记录校验程序对两组 CSV 对的条数、类别顺序、单位和运行编号检查；
OpenSSL 3.5.5 对采集程序、分析程序及四份 CSV 的 SHA3-256。各 `.report` 中的 `csv_digest`
与该文件的 OpenSSL 摘要一致，各 `.meta` 中的 `executable_digest` 与对应采集程序摘要一致。
binaries.sha256 另用 shasum 记录五个产物的 SHA-256。

## 产物机制

reference-encoder-arm64.txt：编码函数 `_baseline_native_poly_frommsg` 位于 0x100002690，
全部消息位使用 `and / neg / and …, lsr #16` 无分支算术选择，函数内唯一条件分支是
0x100002768 的循环边界 `b.ne`（`cmp x8, #0x20`）。
vulnerable-encoder-arm64.txt：同名函数位于 0x100002690，+0x48（0x1000026d8）为
`tbz w8, #0x0`，由 `ldrb → lsr` 取出的消息位控制两条存储路径。
以上地址只对应本目录记录的二进制摘要，不跨构建复用。

## 统计结论

两份报告使用同一族 10 个预先规定的类别比较、Bonferroni 校正后单比较水平 1e-4，
主统计量为并列修正的 Mann-Whitney U 正态近似。

| 采集 | 判定显著的比较数 | 恒定消息类 vs 变化消息类 |
|---|---|---|
| reference（种子 20260930） | 0 / 10 | 最大 \|z\|=1.74，均值差 ≤ 23ns |
| vulnerable（种子 20260930） | 7 / 10 | 6 项全部显著，均值差 711–800ns，效应量 0.819–0.844 |
| reference（种子 42） | 0 / 10 | 同样全部不显著 |
| vulnerable（种子 42） | 7 / 10 | 同样 6 项显著，`valid:message-zero` 均值差 789ns |

缺陷版第 7 项显著比较是主比较 `message-zero:message-ones`（分支方向对照）：
两次采集分别为 z=-4.04（p=5.33e-05）和 z=-4.83（p=1.36e-06），均值差 -83.2ns 与 -55.8ns。
这是远小于上表主效应的次级差异，跨运行方向一致但幅度不稳定。
报告中 `rank_p=0` 表示 erfc 下溢到双精度下限（|z| 超过约 38），应以 z 值为准。

参考版与缺陷版使用同一采集程序、同一公开种子、同一类别顺序和同一输入构造，
因此缓存与序列效应在两版之间受控；仅编码函数补丁不同。
这是本机的统计确认，不是未知密钥攻击、不是密钥恢复，也不证明参考版整体恒时。
真实 x86_64 Linux / GCC 的同组采集与确认仍未执行。
