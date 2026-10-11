# 七项能力资源清单

日期：2026-10-11。本文件只登记路径和边界，不升级任何签收状态。R02、R04 仍按既有验收表保持部分签收，直到新的原始记录单独审计。

## 已有代码路径

| 职责 | 路径 |
|---|---|
| 既有完整解封装采集 | `src/measure.c`，格式 `reference_ordinary_v1` / `reference_batch_v1` |
| 空窗与计时检查 | `src/inspect_timing.c` |
| 批量窗口 | `src/batch_measurement.c` |
| 五类输入 | `src/inputs.c`，`include/inputs.h` |
| 历史逐次分析 | `src/analyze.c`，`src/timing_statistics.c` |
| 分组与受控统计 | `src/analyze_groups.c`，`src/controlled_statistics.c` |
| 历史复算入口 | `src/audit.c`，CTest `analysis_round1_replay` |
| 三机制反汇编审计 | `src/mechanism_audit.c` |
| 四变体补丁 | `docs/patches/message-branch.patch`，`message-constant-time.patch`，`message-value-barrier.patch` |

历史分析器的检验定义不改。新确认分析使用独立入口，读取本目录的 `confirmation_protocol_v1.txt`。

## 本轮新增边界

- 新采集格式为 `session_decapsulation_v1`。计时窗口只包住一次 `mlkem_decapsulate`。
- 诊断插桩是独立构建，不改正式 `deployable` 目标，也不把 sanitizer 计时写入矩阵。
- 新原始记录只进入 `docs/evidence/seven-capabilities-20261011/`。已封存证据字节不改。
- 云端文件只放在 `/home/nss-marker/yhr/Cry` 的新子目录。本机 `build/` 不是证据。

## 机器

| 平台 | 角色 | 当前约定 |
|---|---|---|
| Apple Silicon / macOS | 第二真实处理器 | 本机仓库根 `/Users/yin/code/cryProject`。计时记为 macOS/ARM，不并入 Linux。 |
| AMD Ryzen 9 9950X / Ubuntu | 主平台 | `ssh nss-marker@10.144.144.5`，根目录 `/home/nss-marker/yhr/Cry`。频率策略以当次读数为准，不把历史 G2 写成当前已锁频。 |
| 历史 KVM | 已有参照 | 不在旧根上开新实验。 |

网络三档抖动和 Mac 到 Ryzen 的客户端原值，只有在真实连接或 Cry 内的队列实验成功后才能写入证据。回环不能代替这两项。

## 签收

软件、实验、主张、作品验收仍分开。本清单不把任何一项标成实验完成或主张成立。
