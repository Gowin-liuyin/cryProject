# P5（观测者族采集件）会话报告（2026-11-16）

## 1. 开工自检（原文）

```text
$ cd ~/cryProject-work && git branch --show-current
main
$ git status --porcelain | head -5
（无输出）
$ git log --oneline -2
f3cbc819 feat(pipeline): MCP server 八工具与冒烟测试
787aa182 feat(pipeline): 修复模式库四条目与 repair_propose 补丁建议器

$ nproc
24
$ grep -c processor /proc/cpuinfo
24
```

《任务书》§7 复述：T5.1 产出 `sync_flag.h/.c` 同步库与 fork 双进程交替 turn 单测；
T5.2 产出 SMT 争用观测者（绑核、批除法、CSV）与自模拟 CTest；T5.3 产出 cache F+R 观测者
与 M3 共享页臂（patch + `PlatformM3.cmake` 第三模式 shared-on）；T5.4 产出 BTB 观测者、
`mde_budget.py` 与 R18/R19 两份 pilot 冻结 PLAN（不采集）。

## 2. 每任务状态与关键数字

### 提交 1｜T5.1 + T5.2 —— 完成

- `tools/platform_observers/sync_flag.{h,c}`：匿名 mmap（fork 继承）与文件 mmap
  （独立进程）两种共享页 + 原子 turn 序号，`sync_flag_wait_turn` 用 `sched_yield` 轮询。
- `tools/platform_observers/tests/test_sync_flag.c`：fork 双进程交替 turn 各 **1000 次**
  ×（匿名/命名）两模式，`alarm(10)` 超时保护；通过。
- `tools/platform_observers/smt_contention_observer.c`：`--cpu` 绑核；每批
  `--div-batch 4096` 次 uint64/uint32 除法，`CLOCK_MONOTONIC_RAW` 批时延；CSV
  `batch_index,victim_run_id,batch_elapsed_nanoseconds`；`--self-check` 自模拟断言
  表头/行数/非法参数退出 2；通过。
- CTest 新增 `platform_observer_sync_flag`、`platform_observer_smt_selfcheck`（61/61）。

### 提交 2｜T5.3 —— 完成

- `docs/patches/m3-lut-shared-page.patch`：在 `m3-mem-lut-toggle.patch` 基础上把 LUT 表
  改为 4096 B 文件映射共享只读段（两行各占 64 B 缓存行，构造函数在计时窗口外 mmap，
  路径由 `PLATFORM_M3_SHARED_LUT_PATH` 指定）；补丁链在 build 副本应用并逐字节比对一致。
- `cmake/PlatformM3.cmake`：仅新增第三模式 shared-on 段（+73 行，on/off 段未改），
  平台 clang 树成功构建 `platform_m3_shared_on_baseline` 与 `platform_m3_shared_on_measure`
  （产物 `build/cmake-platform/platform-m3/shared-on/{baseline,measure}`）。
- `cache_flush_reload_observer.c`：`--map` 共享映射 + `--layout` JSON 行表，`clflush`→等
  turn→`rdtsc` reload 计时，CSV `victim_run_id,line_index,reload_tsc`；`--self-check` 自建
  小映射记录冷/热两态（8 样本 × 2 行 × 2 态 = 32 行，cold=16/hot=16）并通过。
- CTest 新增 `platform_observer_cache_selfcheck`（62/62）。

### 提交 3｜T5.4 —— 完成

- `btb_observer.c`：固定 8 目标间接跳转阵列、批时延 CSV，骨架同 SMT；自检通过。
- `scripts/platform_stats/mde_budget.py`：两列 pilot CSV → 每类样本量；
  冻结公式 α=0.05 双侧、power=0.8、`2(z_a+z_b)² = 15.697759468698177`；
  用合成 pilot（200 行、pooled sd 27.234 ns、Δ=10 ns）实测输出 **117/类**；
  头部与输出均含边界声明「pilot 预研估算，不作正式统计出口；正式统计由 C 件承担」。
- 两份冻结 PLAN：
  - `docs/research/r18-smt-pilot-20261116/PLAN.md`：受害者 = M2 两臂（R05 §0 摘要
    `dd4073ba…` / `c48f89a5…`），受害者 CPU2/6 → 观测者 CPU18/22；2 臂 × 2 seeds × 200 批
    pilot → `mde_budget`（Δ=10 ns，正式每类 2000–20000 批）→ 3 seeds 正式；
    族外 exploratory Welch，不进 Holm；锁频合同、观测者频率登记、wrapper 窗口外 turn
    flag 同步协议、停止条件与远端目录约定齐全。
  - `docs/research/r19-cache-pilot-20261116/PLAN.md`：对象 = M3 off（`d62e3912…`）vs
    shared-on（**裸金属构建后回填摘要**），同一 LUT 文件与 layout.json（行 0/64）；
    pilot 200 样本/行 → `mde_budget`（Δ=4 cycles，正式 2000–50000 样本/类）→ 3 seeds；
    其余合同同 r18。
- CTest 新增 `platform_observer_btb_selfcheck`、`platform_observer_invalid_arguments`
  （三观测者非法参数一律退出 2）；`ctest --preset baseline-wsl` **64/64**
  （原 59 + 新增 5：sync_flag、smt、cache、btb、invalid_arguments）。

## 3. 三个提交（本地 main，作者/提交者 `Gowin-liuyin`，未 push）

| hash | 信息 |
|---|---|
| `d797a08a` | `feat(observers): 同步库与 SMT 争用观测者` |
| `5d689497` | `feat(observers): cache F+R 观测者与 M3 共享页臂` |
| 本文件所在提交 | `feat(observers): BTB 观测者、MDE 预算工具与两份 pilot 冻结计划`（hash 见 `git log -1`） |

## 4. 偏离项及理由

1. **观测者的构建接线**：白名单只允许 `CMakeLists.txt` 的测试注册段；观测者是独立可执行
   工具，因此在同一 BUILD_TESTING 段内同时 `add_executable` 观测者 + 注册自模拟 CTest
   （仅 Linux 分支），未改其它构建段。
2. **新增 `observer_common.{h,c}`**：三个观测者共用的绑核/读钟/CSV/自检辅助放在
   `tools/platform_observers/`（白名单新目录）内，避免三份重复实现。
3. **M3 第三模式**：为保证"不改既有 on/off 段"，shared-on 作为独立块新增；因
   `cmake/PrepareVariant.cmake` 只接受单补丁，shared-on 的准备命令在 PrepareVariant 之后
   再执行 `patch -p1 -d <overlay> -i m3-lut-shared-page.patch`。
4. **gcc `-Wconversion` 与 CPU_SET**：glibc 的 `CPU_SET` 宏展开触发 int/size_t 符号转换
   告警；在 `observer_bind_cpu` 内对宏展开局部 `#pragma GCC diagnostic` 抑制（clang/gcc
   均支持），未放宽其它告警。
5. **平台树构建**：沿用 P2/P3 的 clang 平台树缓存（`CMAKE_C_COMPILER` + `MATH_LIBRARY`
   补丁仅存在于 `build/`，未改仓库构建文件）；shared-on 只验证可构建，不执行。
6. **同步 hook 的边界**：现有 M2/M3 `measure` ELF 没有窗口 hook；两份 PLAN 明确要求
   wrapper 在受害者计时窗口外写 turn flag，并给出 hook 合同与 `sync_mode` 记录要求；
   实际 wrapper 实现与采集由主控执行（本阶段未采集）。
7. **工具环境限制**：WSL 既有文件编辑仍受 `GetFileSecurityW EIO` 限制，用
   "Windows 临时文件 + cp"/`sed -i` 落地，`git diff` 核对为预期新增/修订。

## 5. 卡点

- 无阻塞性卡点（纯本地代码 + 单测；未取件、未联网、未装包、未采集）。
- 边界：三个观测者与 M3 shared-on 臂只做本地构建/自模拟自检；R18/R19 的 pilot 与正式
  采集、频率控制、wrapper、MDE 实测均由主控按 PLAN 执行；观测者结论只属族外 exploratory，
  不构成恒时/泄漏因果证明。
