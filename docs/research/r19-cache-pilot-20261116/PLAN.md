# R19 cache F+R 观测者 pilot 冻结计划（PLAN）

- 任务号：T5.3 / T5.4（观测者与 M3 shared-on 臂本阶段只做本地构建与自模拟；
  **本 PLAN 不执行任何采集**）
- 冻结日期：2026-11-16（Asia/Shanghai）
- 执行者：主控（裸金属 `nss-m`，AMD Ryzen 9 9950X，32 逻辑 CPU，Linux x86_64）
- 状态：**冻结候选；待主控提交本文件后执行**。执行前用本 PLAN 的 blob SHA-256 作为
  `plan_sha256` 写入 run manifest；PLAN 内容无法自引用自身提交号。
- 交付件：`tools/platform_observers/cache_flush_reload_observer.c`、
  `docs/patches/m3-lut-shared-page.patch`、`cmake/PlatformM3.cmake` 第三模式 shared-on
  （本阶段只验证平台树可构建；下述采集命令由主控在裸金属执行）。

## 0. 冻结摘要

| 项 | 冻结值 |
|---|---|
| 观测者 | `cache_flush_reload_observer`：映射共享 LUT 文件，`--layout` 指定缓存行（两行、各 64 B），`clflush`→等 turn→`rdtsc` reload 计时；CSV `victim_run_id,line_index,reload_tsc` |
| 受害者 | M3 `mlkem-native` 两臂：`secret-index-lut-off`（恒定控制）与 `secret-index-lut-shared-on`（新臂，LUT 改为文件映射共享只读段） |
| 主类对 | class0 = `message-zero`、class1 = `message-ones`（M3 冻结 PLAN §2.2 原文口径；效应量 `mean(zero)-mean(ones)` 双侧，单位 tsc cycles） |
| 种子 / 拓扑 | 受害者 CPU2 时观测者 CPU18；受害者 CPU6 时观测者 CPU22（9950X n+16 同核兄弟） |
| pilot | 2 臂 × 2 seeds × **200 个样本/行**，用 `scripts/platform_stats/mde_budget.py` 估算正式样本量 |
| 正式 | 2 臂 × 3 seeds（31337/CPU2、424242/CPU2、31337/CPU6），每臂每类样本数按 §4 冻结 |
| 统计口径 | **族外 exploratory Welch（双侧正态近似）+ 95% CI**，**不进 Holm**；不做族级判定 |
| 停止规则 | 见 §8；不重试择优、不事后改预算/种子/绑核/统计口径 |

## 1. 对象与产物身份

| 角色 | 身份 / 路径 | 摘要 |
|---|---|---|
| M3 off 臂（恒定控制） | `docs/evidence/m3-completion-20261016/` 记录的 `platform-m3/off/measure` | `d62e39124660f758a6cc98b82b3bd9b8e41a45b0ccdc46a83bc6c6ddd73df4f0`（on 臂历史值 `fe5435ba…` 仅作对照，不用于本 PLAN 主臂） |
| M3 shared-on 臂（新） | 裸金属构建 `cmake --build build/cmake-platform --target platform_m3_shared_on_measure`（本仓库含 patch 与 PlatformM3 第三模式） | **裸金属构建后回填**：ELF SHA-256、ldd、编译器版本写入 `<root>/victims/MANIFEST.sha256`；未回填前不得采数 |
| LUT 共享文件 | `<root>/lut/m3-shared-lut.bin`，4096 B：`int16[0..31]=0`、`int16[32..63]=MLKEM_Q_HALF(0x681)`，其余 0（两行各占 64 B 缓存行） | 每 run 前 `sha256sum` 记入 meta |
| layout JSON | `<root>/lut/layout.json`：`{"cache_line_bytes":64,"line_count":2,"lines":[{"byte_offset":0},{"byte_offset":64}]}` | 与观测者 `--layout` 同 schema |
| 观测者 ELF | `cmake --build build/cmake --target platform_observer_cache_flush_reload` 在裸金属构建 | 构建后冻结 SHA-256 与 `ldd` |

- `shared-on` 臂在运行时通过环境变量 `PLATFORM_M3_SHARED_LUT_PATH=<root>/lut/m3-shared-lut.bin`
  由 `mlk_poly_frommsg` 的 constructor 打开并 `mmap(MAP_SHARED, PROT_READ)`；观测者用
  `--map` 打开同一文件。构造函数在进程启动时执行（在任何计时窗口外），窗口内只读映射。
- 两臂均为 mlkem-native `b3ba7b32773e657dd37f6f87bce82528459ad8a4` + 对应补丁；
  off 臂 = `m3-mem-lut-toggle.patch` 的常闭控制，shared-on = 在其上叠加
  `m3-lut-shared-page.patch`（`docs/patches/`，本阶段已验证补丁链与构建）。

## 2. 同步机制（wrapper 在受害者计时窗口外写 turn flag）

- 共享文件：`<root>/sync/cache-turn.bin`，布局 = `struct sync_flag_shared`（`sync_flag.h`）。
- 协议（每个样本、每个缓存行）：
  1. wrapper（受害者侧）在**受害者计时窗口之前** `signal_turn`；
  2. 观测者 `wait_turn` → `clflush` 目标行；
  3. wrapper 在**受害者计时窗口之后** `signal_turn`；
  4. 观测者 `wait_turn` → `rdtsc` reload 计时并写缓冲 → `signal_turn`（允许下一轮）。
- wrapper 的 flag 读写、CSV 记录与 I/O 全部在受害者计时窗口之外；观测者窗口内只读 flag、
  读钟、`clflush`/reload，无 I/O/日志/malloc。类别标签由 wrapper 在
  `<root>/runs/<run>/sample-classes.csv` 记录 `sample_index,class_label`，统计阶段 join。
- 若主控无法给现有 M3 `measure` ELF 增加 window hook，必须用等价 wrapper 变体并在 run
  manifest 记录 `sync_mode=wrapper_hook`；`sync_mode=unsynchronized` 只能标记 exploratory，
  不进主统计。

## 3. 环境前置

1. **受害者侧锁频合同**（同 `docs/evidence/platform-collection-20261016/README.md`）：
   `tools/platform_control/controller.py`（SHA-256 `4a0cf57a…`）；boost=0、
   governor/EPP=performance、min=max=4300000 kHz；taskset CPU2 或 CPU6；20×50 ms 放行门
   ±2%、跨度 ≤50000 kHz；`terminal.json` 需 reason=worker_finished、worker_exit_code=0、
   restore_match=yes；进入/运行中/退出快照齐全。
2. **观测者侧频率登记**（不控制）：观测者 CPU18/22 运行前后读取 `scaling_cur_freq`、
   `scaling_governor`、`cpuinfo_max_freq`，写 `<root>/logs/observer-frequency.txt`，
   标 `observer_frequency_control=not_configured`；不得把观测者频率当作锁频证据。
3. 序号固定：`r01` 31337/CPU2、`r02` 424242/CPU2、`r03` 31337/CPU6；每 run 先 off 臂
   再 shared-on 臂（pilot 与正式阶段一致）。不虚拟化外推（`systemd-detect-virt=none`）。
4. 全部文件只落 `/home/nss-marker/yhr/Cry/r19-cache-pilot-20261116-<nonce>/`；
   `TMPDIR=<root>/tmp`、`XDG_CACHE_HOME=<root>/cache`；不写 `/tmp`、`/run` 或家目录其它位置。

## 4. 预算、MDE 与统计口径

1. **pilot**：2 臂 × 2 seeds（31337、424242）× 每行 200 个样本；每样本每行一行
   `reload_tsc` 记录，按 wrapper 类别标签分两类。
2. 用 pilot 的 `reload_tsc`（单位：tsc cycles；`mde_budget.py` 按输入单位解释，输出
   `unit=tsc_cycles`）喂 `scripts/platform_stats/mde_budget.py`：
   - 公式冻结：α=0.05 双侧、power=0.8，
     `n_per_class = 15.697759468698177·σ_pooled²/Δ²`；
   - 目标效应 `Δ` 冻结为 **4 cycles**（reload_tsc 尺度；若 pilot σ_pooled > 8，则取
     `Δ = σ_pooled/2` 四舍五入到整数 cycles，先冻结再正式跑）；
   - 正式每类样本数 `N_formal = max(2000, mde_budget 输出)`，上限 **50000**；
     输出 >50000 时封顶并记 `budget_insufficient`（不延长、不重跑）。
3. **正式统计**：每个 (臂, seed, 缓存行) 对 reload_tsc 做双侧 Welch 大样本正态近似：
   效应 `mean(message-zero)-mean(message-ones)`、95% 正态近似 CI、p=`erfc(|t|/sqrt(2))`；
   结果全部标记 **family-external exploratory**，不进 Holm、不改任何族判定；
   两行分别报告，另给两行合并的描述性结果（不合并成族）。
4. `mde_budget.py` 只作 pilot 预研估算，正式统计仍由 C 件承担。

## 5. 采集命令（模板）

```sh
ROOT=/home/nss-marker/yhr/Cry/r19-cache-pilot-20261116-<nonce>
OBS=$ROOT/observer/cache_flush_reload_observer
SHARED=$ROOT/victims/measure-shared-on
OFF=$ROOT/victims/measure-off

# 0) 预置：PLAN、patch、源码、布局文件、layout.json、MANIFEST.sha256（含两臂 ELF 与 LUT 摘要）
# 1) shared-on 臂启动需设置共享 LUT 路径：
export PLATFORM_M3_SHARED_LUT_PATH=$ROOT/lut/m3-shared-lut.bin
# 2) pilot（每臂、每 seed 各 200 样本/行）：
$OBS --map $PLATFORM_M3_SHARED_LUT_PATH --layout $ROOT/lut/layout.json \
     --samples 200 --sync-file $ROOT/sync/cache-turn.bin \
     --output $ROOT/runs/pilot-r01-shared-on/cache-fr.csv --victim-run-id pilot-r01-shared-on
# 3) MDE：python3 scripts/platform_stats/mde_budget.py --input <pilot-class-pair.csv> \
#         --delta-nanoseconds 4
# 4) 正式 6 次运行（r01/r02/r03 × 两臂），每类 N_formal 样本，命令同 pilot
# 5) 退出核对：32 policy/global boost 回读、原 PID/组与两把锁、restore_match=yes
```

## 6. 远端目录约定

```
/home/nss-marker/yhr/Cry/r19-cache-pilot-20261116-<nonce>/
├── plans/PLAN.md  PLAN.exec.sha256
├── source/           # 本仓库提交的 patch/观测者源码/PLAN + 校验清单
├── victims/          # 裸金属构建的 off/shared-on measure ELF、ldd、回填摘要 MANIFEST.sha256
├── observer/         # 裸金属构建的 cache F+R 观测者 ELF、ldd、摘要
├── lut/              # m3-shared-lut.bin + layout.json + 摘要
├── sync/             # cache-turn.bin
├── runs/<run-name>/  # cache-fr.csv、sample-classes.csv、victim CSV/meta、controller/ 快照
├── stats/            # Welch CI/p、MDE 输出
├── logs/             # 环境、频率登记、命令与结束核对
└── tmp/ cache/       # 均在本根内
```

## 7. 主控执行检查清单

1. 本 PLAN 已提交；记录 blob SHA-256 作为 plan_sha256。
2. off 臂 ELF 摘要等于 §1；shared-on 臂在裸金属构建后把 ELF 摘要回填 MANIFEST，
   未回填不得采数。
3. LUT 文件内容与 layout.json 摘要冻结；观测者 `--map` 与 victim
   `PLATFORM_M3_SHARED_LUT_PATH` 指向同一文件。
4. 控制器资格与频率合同复核；锁状态记录；同步文件与类别标签格式核对。
5. 正式预算在 pilot 之后、正式采集之前冻结（写 MANIFEST，之后不得改）。

## 8. 停止条件与边界

- 任一 ELF/LUT/layout 摘要不符、M3 共享映射 constructor 启动失败、同步卡死（wrapper 超时）、
  频率放行门/恢复失败、控制器非零退出：该 run 记 `not_run`/失败，停止后续依赖，
  **不重试择优、不补抽**。
- pilot 后 σ 不稳定或 MDE 输出 >50000：按上限执行并记 `budget_insufficient`，不改口径。
- 本 PLAN 只支持族外 exploratory 描述；F+R 观察是**缓存行为代理**，不构成受害者端到端
  恒时或泄漏因果证明，也不做密钥恢复；shared-on 臂是新人工校准臂，不与历史封存臂混用。
- 未执行采集：本文件只冻结计划，实际运行由主控按上表命令执行并另落证据目录。
