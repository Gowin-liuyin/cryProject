# P6（自适应引擎 L1/L2）会话报告（2026-11-16）

## 1. 开工自检（原文）

```text
$ git branch --show-current
main
$ git status --porcelain | head -5
（无输出）
$ git log --oneline -2
5289b590 feat(observers): BTB 观测者、MDE 预算工具与两份 pilot 冻结计划
5d689497 feat(observers): cache F+R 观测者与 M3 共享页臂
```

前置阅读复述：
- `fixtures/early_reject_memcmp/compare_early.c`：循环内 `if (secret[i] != candidate[i]) return 0;`
  在首个失配字节处提前返回，比较耗时随失配位置后移而增加；`compare_ct.c` 用 OR 累积、
  无秘密相关早退，耗时不随失配位置变化（恒定控制臂）。
- `tools/platform_m4/inputs.c`：`m4_prepare_case` 固定两类（首字节不等 / 末字节不等）；
  `tools/platform_m4/measure.c` 的 `--collect NEW.csv CALLS_PER_CLASS SEED RUN_ID`
  一次窗口覆盖完整 `m4_compare_checked`，`CLOCK_MONOTONIC_RAW`、100 次预热、CSV 长表。

《任务书》§8 复述：T6.1 逐位检验器（两列重复观测、vote=(t_h1>t_h0)、多数票 + 二项精确 p）；
T6.2 M4 位置构造器（position 0..31 的 32 字节输入对）；T6.3 自适应引擎（craft→measure→test
循环，M4 vulnerable 目标 20/20、ct 登记未检出）；T6.4 L2(M3×R19) 与 L3 提纲 PLAN。

## 2. 每任务状态与关键数字

### 提交 1｜T6.1 + T6.2 —— 完成

- `bit_hypothesis_tester.c`：冻结 `REPEAT_COUNT=1000`、`MAJORITY_THRESHOLD=501`、`ALPHA=0.05`；
  每重复 `vote=(t_h1>t_h0)`，多数票定判定，`p=P(X≥多数票数)` 用二项精确递推求和；
  逐元素全等退化输出 decision=0、p=1（注释说明）；单测 **20/20 判定正确**、完全相同两组 p=1、
  非法参数退出 1/2。
- `craft_inputs.c`：给定 position 0..31 产出 32 字节输入对，首个差异字节=position、其余相同；
  单测 **32 个位置逐一构造正确**，非法位置/指针拒绝。
- CTest 新增 `adaptive_bit_hypothesis_tester`、`adaptive_craft_inputs` → **66/66**。

### 提交 2｜T6.3 —— 完成（目标 20/20 未达，如实登记）

- 平台树构建 M4 两臂 measure（clang 18.1.8）：`platform_m4_measure_vulnerable/ct` 可构建；
  `--describe` 与 500 调用/类 sanity：vulnerable mismatch-first/last 中位 **50 / 80 ns**，
  ct **60 / 60 ns**（信号方向确认）。
- 引擎 sanity（100 样本/位置）：vulnerable position 0/15/31 中位 **4.480 / 9.432 / 19.812 ns**
  单调递增，确认早退方向；ct 无方向。
- 全量恢复（冻结参数 REPEATS_CAL=1000、REPEATS_TEST=1000、INNER_REPEATS=1024、DEMO_RUNS=20、
  最近中位参考、LCG seed 20261116）：
  - **vulnerable：15/20（75%），未达 20/20 目标**；5 个错误均为相邻/近邻位置
    （11→8、16→14、2→1、25→31、1→0）；校准相位与恢复相位间存在系统性漂移（本地未锁频 WSL）。
    按 §2 口径**未调参重跑**：如实记录 15/20，并用 `mde_budget.py` 以 pilot（位置 0/1 各 1000
    样本、pooled SD=3.9229 ns、相邻 Δ=0.49 ns）估算所需 **1007 样本/类**（≈ 冻结的
    REPEATS_TEST=1000，处边界；32 位置分类与相位漂移使实际需求更高）。
  - **ct：1/20（5%）**，32 位置随机期望 3.125%，按“未检出失配位置”登记。
- 证据落盘 `docs/evidence/l2-m4-recovery-20261116/`：RESULT.md（含逐 run 表、两臂正确率、
  未达标分析、ct“未检出”口径、本地未锁频环境声明）、两臂 recovery CSV/meta（含冻结参数与
  32 个校准中位）、measure 两臂 CSV/meta + sanity、pilot/MDE、environment、commands。
- 偏离说明：既有 M4 measure 只提供固定的 mismatch-first/mismatch-last 两类，无法按任意位置
  重采；因此引擎以 `craft_inputs` + **同一夹具内核**（`compare_early.c`/`compare_ct.c` +
  `compare_checked.c`）按 measure 相同窗口口径在进程内驱动 32 位置测量；measure 两臂构建与
  first/last sanity 仍按任务要求完成并落盘。

### 提交 3｜T6.4 —— 完成（纯文档，不执行）

`docs/research/l2l3-plan-20261116/PLAN.md`：
- **L2·M3×R19**：复用 r19-cache-pilot 的 LUT/layout、wrapper 同步与环境合同；cache 观测者
  逐调用 flush/reload 两行 LUT → 恢复 256 位下标序列。冻结判据：逐调用行分类 shared-on
  **≥0.95**（off 臂须 ≈随机）、整序列精确恢复率 **≥0.90** 且逐位 ≥0.98；样本量由 pilot
  MDE（`max(2000, 估算)`、上限 50000）在正式前冻结。
- **L3 提纲**：真实臂消息位恢复**只写提纲**；功效门 ≥16 个已知位、pilot 后冻结每类样本量、
  逐位正确率阈值预注册（建议 ≥0.90，主控确认）、16 位全部门槛达标才谈全量；
  **须主控确认后开跑**，不进入匿名支撑包，不攻击真实第三方系统/真实用户密钥。
- 本阶段未执行任何采集；L2/L3 均由主控按 PLAN 在裸金属执行。

## 3. 三个提交（本地 main，作者/提交者 `Gowin-liuyin`，未 push）

| hash | 信息 |
|---|---|
| `dc0a6913` | `feat(adaptive): 逐位检验器与 M4 位置构造器` |
| `05026055` | `test(adaptive): M4 失配位置恢复演示（两臂对照）` |
| 本文件所在提交 | `docs(l2l3): M3×R19 恢复计划与 L3 提纲`（hash 见 `git log -1`） |

## 4. 偏离项及理由

1. **引擎测量入口**：既有 `platform_m4_measure_*` 只有固定 first/last 两类，不能按任意位置
   采集；引擎改为 `craft_inputs` + 同一夹具内核的进程内测量（窗口口径：一次完整
   `m4_compare_checked`、`CLOCK_MONOTONIC_RAW`、100 次预热、窗口内无 I/O/日志/malloc）。
   平台树仍按任务要求构建 M4 两臂 measure 并做 sanity。
2. **`INNER_REPEATS=1024`**：为把一次比较的亚纳秒级位置差放大到可测窗口，冻结
   “每样本=1024 次完整比较均值”；该常量与 REPEATS_* 一起写死并写入 meta，运行期不可改。
3. **20/20 未达标**：按 §2 口径不调参重跑，保留 15/20 与全部原始 CSV/meta，并在 RESULT 中
   给出 `mde_budget` 预算估计（1007/类 ≈ 冻结预算边界）与相位漂移主因分析；后续是否按新预算
   重跑由主控决定。
4. **build 内辅助件**：pilot 探针、两臂位置中位数脚本、engine 修正脚本均在 `build/` 内
   （gitignored），不提交；证据目录只收结果与可复跑命令。
5. **平台树**：沿用 P2/P3/P5 的 clang 平台树缓存（编译器与 `MATH_LIBRARY` 修正只在 `build/`），
   未改仓库构建文件。
6. **工具环境限制**：WSL 既有文件编辑仍受 `GetFileSecurityW EIO` 限制，用“Windows 临时文件 +
   cp”/`sed -i` 落地，`git diff` 核对为预期新增/修订。

## 5. 卡点

- 无阻塞性卡点（本地 WSL 纯软件 + 人工校准臂演示；未取件、未联网、未采集）。
- 边界：M4 是人工校准夹具，结论不涉及真实实现/真实密钥；vulnerable 15/20 与 ct 1/20 只描述
  本机本预算；L2/L3 均为**计划**，执行与 L3 授权属主控决策。
