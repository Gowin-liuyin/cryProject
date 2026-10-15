# RTLF 族外交叉验证结果（2026-10-16）

RTLF 按冻结 PLAN 的定位执行：**α = 0.01、bootstrap 种子 2026101605、族外**。
它只给二值结论（`difference_detected` / `no_difference_detected`），
**不转成 p 值、不进 Holm 家族**，也不与 Welch/CI 的均值判定互相替代。

## 1. 工具身份与执行环境

| 项 | 值 |
|---|---|
| 脚本 | `<Cry>/platform-m5-20261016-30efdf66eb26/source-v2/third_party/RTLF/rtlf.R`，sha256 `50e5d4e5239e492337a131afaf2d1e3c0fdcadbb902d5433d56eac2ead1bd04e` |
| R | `Rscript (R) version 4.3.3 (2024-02-29)` |
| 依赖预检 | `tidyverse` / `optparse` / `jsonlite` / `crayon` / `parallel` 全部可用，`exit 0`，无需安装 |
| 调用 | `set.seed(2026101605); source(rtlf.R)` `-i <normalized.csv> -a 0.01 -o <rtlf.json> -q` |
| bootstrap 迭代 | 10000（工具内部） |
| 主机 | `nss-m`，Linux 6.17.0-35-generic x86_64 |
| 运行窗口 | 2026-10-15T18:30:57Z – 18:45:59Z（UTC） |
| 输入 | `docs/evidence/platform-collection-20261016/stats/<数据集>/normalized.csv.gz`，解压后逐字节用于 RTLF |
| 零值 | 42/42 数据集 `zero_X=0 zero_Y=0`，因此**没有**一个数据集触发上游零值过滤 |

执行根 `Cry/platform-rtlf-20261016/` 内的临时、缓存与 R 库全部落在 Cry 内。
42 个数据集的 `normalized.csv` 与本地独立复算逐字节一致，且与统计电池记录的
`input.sha256` 42/42 相同（见 `staging-meta.tsv` 的 `regen_match` 列）。

## 2. 结果（42/42 完成）

退出码语义（上游约定）：**10 = `no_difference_detected`，11 = `difference_detected`**。

| 模块 | 数据集 | 退出码 | significant deciles |
|---|---|---|---|
| M2 | 主类对 × 6（3 run × 2 臂） | **11 ×6** | 上分位 10–70 段 |
| M2 | 对照类对 × 6 | 10 ×6 | — |
| M5 | 主类对 × 3 / 对照 × 3 | 10 ×6 | — |
| M3 | 主类对 × 6（on/off） / 对照 × 6 | 10 ×12 | — |
| M4 | 主类对 vulnerable × 3 | **11 ×3** | 40–70 |
| M4 | 主类对 ct × 3 | 10 ×3 | — |
| M4 | 截断对照 vulnerable × 3 | **11 ×3** | 60–70 |
| M4 | 截断对照 ct × 3 | 10 ×3 | — |

汇总：**`no_difference_detected` 30 项、`difference_detected` 12 项、`blocked` 0 项、`failed` 0 项**。
逐数据集的 `rtlf.json`（含 `statistics.series_x/y` 的 count/min/max/mean/median/stdev 与
`significant_deciles`）、`rtlf.log`、`exit_code.txt`、`input.sha256` 在 `results/<数据集>/`；
批次总表在 `logs/run-summary.tsv` 与 `logs/batch-console.log`。

## 3. 正确读法（重要）

1. **M4 的 12 项里 6 项与 Welch/Holm 同向**：vulnerable 臂（含截断窗口）全部检出、
   ct 臂全部未检出。这与该模块 Welch 家族"3 项拒绝全在 vulnerable 臂"的结论方向一致，
   是**两种方法在同一批数据上的独立印证**。
2. **M2 的检出同时出现在两个臂**（未修 6/6、已修 6/6），而 Welch/Holm 家族拒绝 0。
   检出**不可归因于除法变体**：如果它是 KyberSlash 机制造成的，已修臂应当消失。
   与"未受控环境漂移"以及**类构造本身**（`message-zero` 与 `message-ones` 各自用全零 /
   全 0xff 的确定性封装种子，两类各 10000 次是同一份密文的重复，而 `bit-flipped`/`random`
   两类逐样本变化）一致的读法是：这更像**类构造带来的分布差异**，而不是秘密相关泄漏。
   本页只如实登记该分歧，**不据此作任一方向的泄漏结论**。
3. **RTLF 检出 ≠ Holm 拒绝**。RTLF 检验的是分布差异（含尾部/分位），Welch/CI 检验的是均值差；
   两者分列，互相不替代。M2 的分歧因此**不改变**预注册家族的判定，也**不追加**任何声明。
4. **RTLF 未检出 ≠ 恒时证明**：M3/M5 的 `no_difference_detected` 只覆盖本机、本类对、
   本样本预算与该工具设置。

## 4. 边界

- RTLF 是族外交叉工具，其 α=0.01 与 Holm 家族的 α=0.05 **不是同一个多重比较框架**，
  不可把它的二值结果折算成 Holm 家族成员。
- 本轮 RTLF 的输入是电池产出的 `normalized.csv`（`V1,V2` 长表头，原行序），
  不是原始采集顺序的重排；该文件的 sha256 已逐份记录。
- 工具为上游钉版脚本，本轮未打补丁、未改参数（除固定的 α 与种子）。
