# R23 裸金属 Memcheck／锁频计时计划（冻结草案）

- 任务号：T7.2（本阶段只出计划，不执行）
- 状态：**冻结草案**；由主控在 `nss-m`（AMD Ryzen 9 9950X、32 线程、Ubuntu 24.04、
  Clang 18.1.3）执行；执行前主控提交本文件并以 blob SHA-256 冻结。
- 对应 bundle 项：`docs/research/phase7-session-20261116/A_LINE_BUNDLE.md` 的 A-R23-01/02。

## 1. 对象与本地格

- 24 个本地格（见 `RESULT.md` / `cells.tsv`）：gcc 8 格（M1 两臂 × O0/O2/O3/Os）、
  clang-18 6 格 M1 补格（O1/Oz/Og）、clang-18 8 格 M2 全格（O0/O1/Oz/Og）。
- 另加 R09 既有 12 格（M1 两版 + M5 × O0/O2/O3/Os）以保持同一 Memcheck 口径对照；
  不重跑 R09 计时产物，只在裸金属补 Memcheck 列。
- 全部实现只读：M1 `Cry/liboqs010-historical-…`、M2 `Cry/platform-m2kem-…/source/vendor`、
  M5 `Cry/platform-m5-…/source-v2`；本轮新根只写 `Cry/r23-optlevel-ext-20261116-<nonce>/`。

## 2. Memcheck（A-R23-01）

- 工具：系统 Valgrind 3.22.x，`--error-exitcode=99 --track-origins=yes`；
  秘密标记沿用 `docs/evidence/r05-locate-20261016/` 的 ctgrind 探针体例：
  M1/M2 标记 PKE 私钥 **1152 B**；解密出的消息/共享秘密在消费前 declassify。
- 每格流程（逐格独立）：
  1. 按本地格同口径（§1 + R09 冻结旗标）在裸金属重建实现对象与探针 ELF，
     记录 ELF/库摘要、编译器版本、完整编译命令；
  2. `taskset -c 0,1,3 valgrind ... probe_<cell>` 运行 8 分区累积标记（与 R05 一致）；
  3. 记录 `ERROR SUMMARY: N errors from M contexts` 与唯一上下文（函数/源码行）；
  4. **判据**：只如实记录 contexts/errors，不写"安全/恒时"；0 命中只能写
     "固定源码/编译器/后端下该标记未报出"。
- 失败/超时/装载失败：保留原始 stderr 与退出码，记 `not_run` 或失败原因，不重试择优。

## 3. 锁频计时（A-R23-02，可选、族外）

- 仅在主控决定扩预算时执行；**沿用 R09 PLAN 的锁频合同**（控制器 SHA
  `4a0cf57a…`、boost=0、governor/EPP=performance、min=max=4300000 kHz、taskset CPU2/6、
  20×50 ms ±2% 放行门、restore_match=yes）。
- 每新增格：3 seeds（31337/CPU2、424242/CPU2、7/CPU6）× 主类对 `message-zero` vs
  `message-ones` 各 10000 次；统计口径与 R09 同（族外 exploratory Welch，不进 Holm）。
- 若主控不开展计时，本项记 `not_run`，不把本地反汇编判定升格为计时结论。

## 4. 停止条件与边界

- 任一格 ELF/库摘要不符、控制器失败、恢复不一致、Memcheck 装载失败：该格记失败/not_run，
  不重试择优，后续依赖停止。
- 结论分层：本地反汇编（已完成）／裸金属 Memcheck（本计划）／锁频计时（可选）分开写，
  不得互相冒充；不改变 R05、R09 或任何既有判定。
