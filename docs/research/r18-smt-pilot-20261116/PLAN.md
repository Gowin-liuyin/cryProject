# R18 SMT 争用观测者 pilot 冻结计划（PLAN）

- 任务号：T5.2 / T5.4（观测者代码本阶段只做本地自模拟；**本 PLAN 不执行任何采集**）
- 冻结日期：2026-11-16（Asia/Shanghai）
- 执行者：主控（裸金属 `nss-m`，AMD Ryzen 9 9950X，32 逻辑 CPU，Linux x86_64）
- 状态：**冻结候选；待主控提交本文件后执行**。执行前用
  `git show <PLAN 提交>:docs/research/r18-smt-pilot-20261116/PLAN.md` 的 blob SHA-256 作为
  本次运行的 `plan_sha256` 写入 run manifest；PLAN 内容无法自引用自身提交号。
- 观测者交付件：`tools/platform_observers/smt_contention_observer.c`、`sync_flag.h/.c`
  （本阶段只交付代码与自模拟单测；下述采集命令由主控在裸金属执行）。

## 0. 冻结摘要

| 项 | 冻结值 |
|---|---|
| 观测者 | `smt_contention_observer`：绑核，批模式每批 `--div-batch 4096` 次 uint64/uint32 除法，`CLOCK_MONOTONIC_RAW` 批时延，CSV `batch_index,victim_run_id,batch_elapsed_nanoseconds` |
| 受害者 | M2（历史 pq-crystals Kyber768 round3，**非 FIPS 203**）两臂：未修 `a621b8d`、上游已修 `272125f` |
| 主类对 | class0 = `message-zero`、class1 = `message-ones`（M2 冻结 PLAN §2.1 原文口径），效应量 `mean(zero)-mean(ones)` 双侧 |
| 种子 / 拓扑 | 受害者绑 CPU2 时观测者绑 **CPU18**（9950X n+16 同核兄弟）；受害者绑 CPU6 时观测者绑 **CPU22** |
| pilot | 2 臂 × 2 seeds × **200 批**，用 `scripts/platform_stats/mde_budget.py` 估算正式每类批数 |
| 正式 | 2 臂 × 3 seeds（31337/CPU2、424242/CPU2、31337/CPU6），每臂每类批数在 pilot 后按 §4 规则冻结 |
| 统计口径 | **族外 exploratory Welch（双侧正态近似）+ 95% CI**，**不进 Holm**；不做族级判定 |
| 停止规则 | 见 §8；不重试择优、不事后改预算/种子/绑核/统计口径 |

## 1. 对象与产物身份（抄 docs/R05-全流程排查表.md §0）

| 角色 | 路径（裸金属） | SHA-256 |
|---|---|---|
| M2 未修 victims | `/home/nss-marker/yhr/Cry/platform-m2kem-20261016-d75a4019/build-ordinary/platform-m2/unfixed/measure` | `dd4073ba38d9ba6b465fca9b6f2e94ef11d8ebc8948901e41f0ba9926ee674e7` |
| M2 上游已修 victims | 同根 `.../platform-m2/fixed/measure` | `c48f89a5bc7f9bd8117a0319eacbc40bf9d061ecae2bad48812376d04745ada7` |

- 两臂源码与构建口径见 `docs/evidence/m2-kem-20261016/{PLAN,ENV}.md`（Clang 18.1.3、
  `-Oz -g -fno-vectorize -fno-slp-vectorize`、`KYBER_K=3`、无 AVX2 分发）。
- 观测者 ELF 由主控在裸金属用本仓库提交构建：
  `cmake --build build/cmake --target platform_observer_smt_contention`（主树自带
  `-Wall -Wextra -Wpedantic -Wshadow -Wconversion -Wstrict-prototypes -Werror`）；
  构建后把 ELF SHA-256、`ldd`、编译器版本写入 `<root>/observer/MANIFEST.sha256`，
  摘要不匹配即停止。观测者不接触密码内核、不读秘密。

## 2. 同步机制（wrapper 在受害者计时窗口外写 turn flag）

- 共享文件：`<root>/sync/smt-turn.bin`，布局 = `struct sync_flag_shared`
  （`sync_flag.h`：magic/closed/`atomic_ullong turn_sequence`）；`sync_flag_create_named`
  创建、观测者用 `sync_flag_open_named` 打开。
- 协议（每次批迭代）：
  1. wrapper（受害者侧）在**受害者计时窗口之前** `signal_turn`；
  2. 观测者 `wait_turn` → 执行一批除法并读钟 → `signal_turn`；
  3. wrapper 在**受害者计时窗口之后**再次 `wait_turn`，记录窗口边界与类别标签（`message-zero`
     / `message-ones`），然后进入下一次窗口。
- 约束：wrapper 的 flag 读写与 I/O 全部在受害者计时窗口**之外**；观测者计时窗口内只读
  flag、读钟、做除法，无 I/O/日志/malloc。若主控无法为现有 `measure` ELF 增加 window hook，
  必须改用等价的 wrapper 变体并在 run manifest 记录 `sync_mode=wrapper_hook` 或
  `sync_mode=unsynchronized`（后者不得用于主统计，只能标记 exploratory）。
- 批时间与类别归属：观测者 CSV 只有 `batch_index` 与 `victim_run_id`；wrapper 在
  `<root>/runs/<run>/batch-classes.csv` 记录 `batch_index,class_label`，统计阶段按此 join。

## 3. 环境前置

1. **受害者侧锁频合同**（沿用 `docs/evidence/platform-collection-20261016/README.md`）：
   唯一控制器 `tools/platform_control/controller.py`（SHA-256
   `4a0cf57a00c6802ff86ed410bd2518bc56cc8e694422cbc4ea7a24a3f1cdd701`）；全局 boost=0、
   目标 CPU governor/EPP=performance、min=max=4300000 kHz；taskset 绑 CPU2 或 CPU6；
   进入/运行中/退出快照；放行门 20×50 ms 全部在 ±2% 且跨度 ≤50000 kHz；
   `terminal.json` 需 reason=worker_finished、worker_exit_code=0、restore_match=yes。
2. **观测者侧频率登记**（不控制）：观测者不使用控制器、不写 sysfs；运行前后各读一次观测者
   CPU（18 或 22）的 `scaling_cur_freq`、`scaling_governor`、`cpuinfo_max_freq` 并写入
   `<root>/logs/observer-frequency.txt`，标 `observer_frequency_control=not_configured`；
   不把观测者频率当作锁频证据。
3. 两臂运行顺序与 CPU 组合固定：`r01` 31337/CPU2、`r02` 424242/CPU2、`r03` 31337/CPU6；
   每次运行先未修臂再已修臂（pilot 与正式阶段一致）。
4. 候选环境（非虚拟化）`systemd-detect-virt=none`；本 PLAN 只在 `nss-m` 执行，不在其它机器
   外推。所有项目文件只落 `/home/nss-marker/yhr/Cry/r18-smt-pilot-20261116-<nonce>/`，
   不写 `/tmp`、`/run` 或家目录其它位置；`TMPDIR=<root>/tmp`、`XDG_CACHE_HOME=<root>/cache`。

## 4. 预算、MDE 与统计口径

1. **pilot**：2 臂 × 2 seeds（31337、424242）× 200 批；每批观测者结果按 wrapper 类别标签
   分成两类（`message-zero` / `message-ones`）。
2. 用 pilot 两类批时延喂 `scripts/platform_stats/mde_budget.py`
   （`--input <pilot.csv> --delta-nanoseconds <M>`）：
   - 公式冻结：α=0.05 双侧、power=0.8，
     `n_per_class = 2(z_{0.975}+z_{0.8})²·σ_pooled²/Δ² = 15.697759468698177·σ²/Δ²`；
   - 目标效应 `Δ` 冻结为 **10 ns**（批时延尺度；若 pilot 的 σ_pooled > 20 ns，则按
     `Δ = σ_pooled/2` 取整数 ns 重新计算并写进 run manifest，先冻结再正式跑）；
   - 正式每类批数 `N_formal = max(2000, mde_budget 输出)`，上限 **20000**；
     若输出 >20000 则正式预算封顶 20000 并在统计层记 `budget_insufficient`（不延长、不重跑）。
3. **正式统计**：每个 (臂, seed) 对观测者批时延做双侧 Welch 大样本正态近似（与
   `platform_stats` 同口径）：
   - 效应 `mean(message-zero)-mean(message-ones)`（ns）；
   - 95% 正态近似 CI；p = `erfc(|t|/sqrt(2))`；
   - 结果全部标记 **family-external exploratory**，**不进 Holm、不改任何族判定**；
   - 同时报告 6 个 (臂,seed) 的合并描述性结果与 I²（仅描述）。
4. **MDE 报告**：记录 pilot σ、冻结 Δ、算得每类批数、正式实际完成批数；
   `mde_budget.py` 只作 pilot 预研估算，正式统计仍由 C 件承担。

## 5. 采集命令（模板）

```sh
ROOT=/home/nss-marker/yhr/Cry/r18-smt-pilot-20261116-<nonce>
CRY=/home/nss-marker/yhr/Cry
OBS=$ROOT/observer/smt_contention_observer
M2=$CRY/platform-m2kem-20261016-d75a4019/build-ordinary/platform-m2

# 0) 预置并冻结：本 PLAN、观测者源码/ELF 摘要、victim ELF 摘要、pilot 参数 → MANIFEST.sha256
# 1) pilot（每臂、每 seed 各 200 批）：
$OBS --cpu 18 --div-batch 4096 --batches 200 --sync-file $ROOT/sync/smt-turn.bin \
     --output $ROOT/runs/pilot-r01-unfixed/smt-batches.csv --victim-run-id pilot-r01-unfixed
# wrapper 同时在窗口外跑 victim measure（未修/已修）并记录类别标签：
#   $M2/unfixed/measure <run_id> 31337 10000 <root>/runs/.../victim.csv <root>/runs/.../victim.meta
# 2) MDE：python3 scripts/platform_stats/mde_budget.py --input <pilot-class-pair.csv> --delta-nanoseconds 10
# 3) 正式 6 次运行（r01/r02/r03 × 两臂），每类 N_formal 批，命令同 pilot、--batches <N_formal>
# 4) 退出核对：32 policy/global boost 回读、原 PID/组与两把锁、restore_match=yes
```

## 6. 远端目录约定

```
/home/nss-marker/yhr/Cry/r18-smt-pilot-20261116-<nonce>/
├── plans/PLAN.md  PLAN.exec.sha256
├── source/           # 观测者源码（本仓库提交）+ 本 PLAN + 校验清单
├── observer/         # 裸金属构建的观测者 ELF、ldd、MANIFEST.sha256
├── victims/          # victim 只读 ELF 摘要核对记录（不复制、不修改原件）
├── sync/             # smt-turn.bin 命名共享页
├── runs/<run-name>/  # smt-batches.csv、batch-classes.csv、victim CSV/meta、controller/ 快照
├── stats/<run-name>/ # Welch CI/p（C 件 platform_stats 或等价 C 口径）
├── stats/mde/        # mde_budget 输出
├── logs/             # 环境、频率登记、命令与结束核对
└── tmp/ cache/       # 均在本根内
```

## 7. 主控执行检查清单

1. 本 PLAN 已提交；记录 blob SHA-256 作为 plan_sha256。
2. victim 两臂 ELF 摘要逐字等于 §1 表；观测者 ELF 摘要已冻结。
3. 控制器资格与频率合同复核；锁 `/home/nss-marker/yhr/Cry/partition-admin.lock` 与
   `collection.lock` 状态已记录。
4. 同步文件、wrapper 类别标签、pilot CSV 列定义已核对。
5. 正式预算在 pilot 之后、正式采集之前冻结（写入 MANIFEST，之后不得改）。

## 8. 停止条件与边界

- 任一 victim/观测者 ELF 摘要不符、同步文件缺失或 turn 卡死（wrapper 超时）、
  频率放行门/恢复失败、控制器非零退出：该 run 记 `not_run`/失败，停止后续依赖，
  **不重试择优、不补抽**。
- pilot 后若 σ 无法稳定估计或 MDE 输出 >20000：正式仍按上限执行并在统计层记
  `budget_insufficient`，不改统计口径。
- 本 PLAN 与观测者代码只支持**族外 exploratory** 描述；不主张恒时、不主张泄漏因果、
  不做密钥恢复，也不把 SMT 争用观察当作受害者端到端独立证据。
- 未执行采集：本文件只冻结计划，任何实际运行由主控按上表命令执行并另落证据目录。
