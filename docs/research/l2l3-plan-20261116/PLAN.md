# L2（M3×R19）恢复计划与 L3 提纲

- 任务号：T6.4
- 冻结日期：2026-11-16（Asia/Shanghai）
- 状态：**冻结计划；本阶段不执行任何采集/恢复实验**。L2 由主控按本文件在裸金属执行；
  L3 属 AGENTS 分级授权的 L3 层级，**须主控确认后开跑**。
- 交付件：`tools/platform_observers/cache_flush_reload_observer.c`（T5.3）、
  M3 shared-on 臂（`docs/patches/m3-lut-shared-page.patch` + `cmake/PlatformM3.cmake` 第三模式）、
  `docs/research/r19-cache-pilot-20261116/PLAN.md`（pilot 合同）。

## 1. L2·M3×R19：cache 观测者逐调用读 LUT 行 → 恢复下标序列

### 1.1 对象与机制

| 项 | 冻结值 |
|---|---|
| 受害者臂 | M3 `secret-index-lut-shared-on`（mlkem-native `b3ba7b32…` + `m3-mem-lut-toggle.patch` + `m3-lut-shared-page.patch`），LUT 为 4096 B 文件映射共享只读段；两行（`0` / `MLKEM_Q_HALF`）分别位于 byte offset 0 与 64，各占一个 64 B 缓存行 |
| 对照臂 | M3 `secret-index-lut-off`（恒定控制，无秘密下标查表），同 LUT 文件布局但 `frommsg` 不做下标读取 |
| 观测者 | `cache_flush_reload_observer --map <lut.bin> --layout <layout.json>`：`clflush` 目标行 → 等受害者窗口后 `rdtsc` reload；CSV `victim_run_id,line_index,reload_tsc` |
| 主类对 | `message-zero` vs `message-ones`（M3 冻结 PLAN §2.2 原文口径） |
| 同步 | 完全复用 `r19-cache-pilot-20261116/PLAN.md` §2 的 wrapper 合同：命名共享页 `sync_flag`，wrapper 在受害者计时窗口外写 turn flag；`PLATFORM_M3_SHARED_LUT_PATH` 指向同一 LUT 文件；类别标签由 wrapper 记录 |

恢复原理：`mlk_poly_frommsg` 对每个系数按消息位读取 `table[bit][0]`（两行分居两个缓存行）。
观测者对目标行 `clflush` 后在受害者访问后 reload：被访问行命中、未访问行 miss，
reload 时延差是公开 LUT 布局下的直接可观测代理。逐调用恢复两行访问序列即可还原
**下标序列**（256 个系数位）；每 8 位合并回 32 字节消息的对应位。

### 1.2 判据与样本量（冻结）

1. **逐调用 LUT 行分类**：每一调用先按公开校准（两行各 `CAL_PER_LINE = 200` 次 flush/reload，
   中位数作参考）建立阈值；再对 `TEST_CALLS = 1000` 次独立调用分类。
   判据：shared-on 臂逐调用行分类正确率 **≥ 0.95**；off 臂同流程 **≈ 随机（0.5）**，
   若 off 臂也 ≥0.95 则该观测不成立（记 negative，不改口径）。
2. **完整下标序列恢复**：对 `SEQUENCE_CALLS = 100` 次完整解封装逐次判决 256 位下标，
   与真实消息位序列逐位比较；判据：**整序列精确恢复率 ≥ 0.90**，
   且逐位平均正确率 ≥ 0.98；任一不达标记 `not_met`，不调参重跑。
3. **样本量来源**：r19 pilot（2 臂 × 2 seeds × 200 样本/行）测得 reload 时延的两类差 Δ 与
   pooled σ 后，用 `scripts/platform_stats/mde_budget.py` 按 α=0.05 双侧、power=0.8 估算
   `N_formal`（每类每行样本量，向上取整、下限 `max(2000, 估算值)`、上限 50000）；
   **正式预算必须在 pilot 之后、正式采集之前写入 run manifest，之后不得改**。
4. **统计边界**：本计划只做 L2 **自攻击演示**（对象为平台自有校准臂与固定测试输入）；
   所有结果标 `layer=L2 self-attack demo`，不进 Holm 家族、不改任何既有统计判定；
   不写“可利用”，不做真实实现外推。

### 1.3 运行与衔接

- 复用 r19-cache-pilot 的环境前置（锁频控制器受害者侧口径、观测者侧频率登记、CPU2/18 与
  CPU6/22 绑核、Cry 内新 nonce 目录、`TMPDIR` 在根内）与 wrapper 同步合同；本目录只追加
  L2 恢复阶段，不覆盖 r19 pilot 原件。
- 每 run：先 shared-on 臂、后 off 臂；pilot 之后冻结 `N_formal`；每阶段先 sanity
  （1 个已知 message-zero 调用）确认 reload 时延出现两行可分辨，再进正式。
- 输出：`<root>/runs/<run>/cache-fr.csv`、`index-sequences.csv`（run_id,call_index,
  true_bit_sequence,predicted_bit_sequence）、`classification.csv`、`stats/` 与日志；
  拉回 `docs/evidence/l2l3-20261116/` 新子目录（不改既有证据）。

### 1.4 停止条件

- LUT/layout/观测者/victim ELF 摘要不符、constructor mmap 失败、同步卡死、控制器失败或
  恢复不一致：该 run 记 not_run，不重试择优。
- shared-on 臂行分类 <0.95 或整序列恢复 <0.90：记 not_met，保留全部原始输出，
  由主控决定是否按新冻结预算重跑；**不得事后调阈值/换样本**。

## 2. L3·真实臂消息位恢复（仅提纲，须主控确认后开跑）

- **层级**：AGENTS 分级授权中的 L3（真实臂消息位恢复）；**本阶段只写提纲，不实现、不执行**。
  L4（完整密钥恢复）不在本阶段范围，须主控另行确认且不进入匿名支撑包。
- **对象**：平台自有的真实臂端点与固定测试密钥对；**不得**对真实第三方系统或真实用户密钥
  做任何恢复实验。
- **功效门（预注册，先于任何 L3 运行）**：
  1. 已知位数量 ≥ **16** 个（由主控在冻结计划中列明来源与顺序）；
  2. 每位每假设的重复数与样本量由 `mde_budget.py` 按 pilot σ 与目标效应估算并冻结；
  3. 逐位正确率阈值预注册（建议 ≥0.90，最终值主控确认），并要求 16 位 **全部达到**阈值；
  4. 只有 16 位 pilot 全部门槛达标，才讨论扩展到更多位/整条消息；
     不达标如实记录并停止，不调参重跑凑数。
- **流程**：冻结计划 → L2 同类观测/统计件（只对平台自有校准臂）→ 16 位 pilot →
  功效复核 → 主控确认 → 才允许全量；任何阶段输出保留原始数据、不删长尾。
- **边界**：不写“可利用”、不做密钥恢复声明；不进入匿名支撑包；不改变既有证据与判定。

## 3. 与既有计划的衔接

- R19 pilot（`docs/research/r19-cache-pilot-20261116/PLAN.md`）提供 LUT 布局、同步 wrapper、
  环境前置与 MDE 输入；本计划在其之后执行，复用同一 wrapper 合同与目录约定。
- L2 结论只作 `L2 self-attack demo` 层证据；L3 须主控确认，二者都不改变 R02/R04 等既有签收状态。
- 本文件不执行任何采集；pilot 与正式采集由主控按本文件与 r19 PLAN 执行。
