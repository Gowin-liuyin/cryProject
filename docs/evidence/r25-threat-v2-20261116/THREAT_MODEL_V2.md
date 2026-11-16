# 威胁模型 v2：树状化与 L0–L4 分级实证（2026-11-16）

- 任务号：T7.4（R25）
- 关系：本文件是 R11 威胁模型（`docs/evidence/r11-threat-20261016/THREAT_MODEL.md`，**原件不改**）
  的树状化扩展；骨架采用 `docs/测评总树与展开清单-20261115.md` §1 的七维树，
  并给出 A.2 观测量清单的 L0–L4 分级与 P0–P6 新证据索引。
- 口径：★ 已有实证资产｜◇ 范式内可拓展（计划/工具已备）｜△ 只做边界声明｜✕ 竞赛红线排除。
  本文件不改变任何既有签收状态（R02/R04 仍部分），不写"恒时/可利用/密钥恢复成立"。

## 0. 分级授权原文与边界

R11 时代的 AGENTS 禁令原文为：
> 不建立通用统计平台、云服务、网络攻击、密钥恢复、STM32 或多算法框架。

按《任务书》§2 T0.3 的拟替换文本（作者侧的分级授权口径；**AGENTS.md 的正式修订由主控提交**，
当前仓库 AGENTS.md 仍是旧句，本文件引用该拟替换文本并注明待主控落地）：
> 不建立通用统计平台、云服务、网络攻击、STM32 或多算法框架；不攻击真实第三方系统与真实用户密钥。
> 对平台自有的固定测试密钥对，允许按 L0（固定类对可区分性）至 L2（校准臂逐位恢复）预注册
> 推进自攻击演示；L3（真实臂消息位恢复）须功效门通过后开跑；L4（完整密钥恢复）须主控确认
> 且不进入匿名支撑包。

**边界声明**：本文件与全部 P0–P6 工作只覆盖平台自有校准臂/固定测试输入与离线分析；
不攻击真实第三方系统或真实用户密钥；L3 未开跑，L4 未授权且不进入匿名包。

## 1. 七维树 v2（骨架 = 测评总树 §1）

```
A. 观测者位置与通道（威胁模型主轴）
├─ A1 同进程自测                       ★ 已实证（P0–P2 复用）
│   ├─ A1.1 端到端计时+锁频+Holm       ★ platform-collection-20261016；本轮 P0 基线记录
│   ├─ A1.2 指令/函数级微基准          ★ M2 除法热点微基准（m2-kem-20261016）
│   └─ A1.3 多统计口径（族外交叉）     ★ dudect/RTLF/Mona；P1 shape_stats 补形状/方差族外件
├─ A2 同机跨上下文（观测者测自己的指令）◇ 主拓展区
│   ├─ A2.1 cache 状态（F+R）         ◇ 工具已交付：tools/platform_observers/cache_flush_reload_observer.c；
│   │                                   正对照=M3 跨缓存行 LUT（m3-lut-shared-page.patch + shared-on 臂）；
│   │                                   pilot PLAN=r19-cache-pilot-20261116；**未执行采集**
│   ├─ A2.2 SMT 端口/执行单元争用     ◇ 工具已交付：smt_contention_observer.c；
│   │                                   正对照=M2 KyberSlash；pilot PLAN=r18-smt-pilot-20261116；未执行
│   ├─ A2.3 分支预测器/BTB              ◇ 工具已交付：btb_observer.c；**未执行采集**
│   ├─ A2.4 TLB/页表                  △ 无对照臂，仅边界声明
│   └─ A2.5 推测执行瞬时窗口          △ 静态面被 ctgrind/Binsec 部分覆盖；瞬时观测未做
├─ A3 跨机远程（网络时序）
│   ├─ A3.1 RTT 非自适应              △ r13-network-20261020 本预算未检出（样本量差 1.3–7.7 个量级）
│   └─ A3.2 自适应选择密文攻击        ✕ 网络攻击，AGENTS 红线
└─ A4 物理接触                        △ B2 排除（功耗/EM/故障注入），文献边界
B. 对策范式
├─ B1 常数级修复                       ★ 平台主体
│   ├─ B1.1 源码级无秘密依赖           ★ 982c762 / 272125f / 自研 asm 值屏障补丁（P2）
│   ├─ B1.2 编译与架构边界             ★ R09 12 格；P7 R23 本地补 24 格判定（反汇编层）
│   └─ B1.3 形式化佐证（Binsec 有界）  ★ M4/M5 r14；P7 R24 扩面 harness+cfg+PLAN（未执行）
├─ B2 掩码（高阶对抗）                △ 仅叙事比较，不做模块
├─ B3 隐藏/随机化                     △ 文献对照
└─ B4 系统级缓解（SMT 关、核隔离）    ◇ 与 A2 实验天然配对，未执行
C. 检测统计方法
├─ C1 一阶固定类对                    ★ Welch+Holm（holm.c）/ dudect / RTLF
├─ C2 非类对/形状/方差                ★ P1：shape_stats 三族四行（族外 exploratory）
├─ C3 高阶（中心化组合二阶 t）         △ 无掩码目标，暂缺对象
├─ C4 画像/模板（含 ML 分类器）        △ 慎入，易滑向 F3
└─ C5 形式化                          ★ 部分（M4/M5）；◇ R24 扩面计划
D. 对象形态
├─ D1 标量参考实现                    ★ liboqs 0.10.0 ref / kyber round3 ref / mlkem-native portable
├─ D2 向量化实现（AVX2/AARCH64）      ◇ P7 R17：三对象构建+反汇编六类扫描完成；动态/Memcheck 待裸金属
├─ D3 优化级别矩阵                    ★ R09 12 格；◇ P7 R23 本地补 24 格（产物层），Memcheck/计时待裸金属
├─ D4 架构                            ★ Zen 5 主台 + aarch64 R15 对照（只复现机制，非第二测量机）
├─ D5 集成/部署栈                     ◇ 大类缺口（liboqs 默认分发/OpenSSL），未覆盖
└─ D6 硬件实现                        ✕ STM32/多算法框架红线
E. 生命周期阶段
├─ E1 解封装                          ★ 赛题限定
├─ E2 keygen / encapsulation          △ 赛题外；可小规模补审计格
└─ E3 集成层（RNG/状态/API/日志面）    ★ R06：122 个接触秘密调用点 0 条内容泄露，F1 已闭合
F. 评估终点深度
├─ F1 可区分性检出                     ★ 全部结论停在这里
├─ F2 泄漏量化（bits/效应量）          ★ 部分（Microwalk MI 1.922 bits）；◇ 效应量口径可扩
└─ F3 密钥恢复 / exploit              ✕ B1 红线；L3/L4 只在授权条款下讨论
G. 环境与可复现
├─ G1 频率控制与校准                  ★ R16：TSC 速率 4 291 962 kHz 不随内核频率变；分辨率≈10 ns
├─ G2 跨机复现                        ★ WSL 三机确定性证据逐项一致（wsl-repro-20261020）
└─ G3 微架构多样性                    ◇ 全部单台 Zen 5；Intel 对照未做
```

## 2. A.2 观测量清单与 L0–L4 分级

| # | 观测量 | 层级 | 现状 | 证据路径 | 一句话边界 |
|---:|---|---|---|---|---|
| 1 | 固定类对端到端均值差（Welch CI/Holm） | L0 | ★ 已执行 | `docs/evidence/platform-collection-20261016/`；`r02-r04-close-20261016/` | 统计结论只对固定输入族/锁频窗口成立 |
| 2 | 端到端方差/形状/类内二阶 | L0 | ★ 已执行（族外） | `docs/evidence/r20-shape-tests-20261116/`；`tools/platform_stats/shape_stats.c` | 探索性、不进 Holm |
| 3 | 指令/微基准热点（M2 div、M3 LUT） | L1 | ★ 已执行 | `docs/evidence/m2-kem-20261016/`、`m2-kyberslash-20261016/`、`m3-completion-20261016/` | 微基准阳性只在微基准层 |
| 4 | 定位层秘密标记（Memcheck/ctgrind） | L1 | ★ 已执行（部分对象） | `docs/evidence/r05-locate-20261016/`、`m5-completion-20261016/` | Memcheck 只报实际执行到的秘密条件分支 |
| 5 | Cache Flush+Reload 行访问（A2.1） | L1/L2 | ◇ 工具+PLAN，未执行 | `tools/platform_observers/cache_flush_reload_observer.c`；`docs/research/r19-cache-pilot-20261116/PLAN.md` | 缓存行为代理，未跑 pilot/正式 |
| 6 | SMT 批时延（A2.2） | L1/L2 | ◇ 工具+PLAN，未执行 | `tools/platform_observers/smt_contention_observer.c`；`docs/research/r18-smt-pilot-20261116/PLAN.md` | 争用是间接代理，未跑 |
| 7 | BTB 批时延（A2.3） | L1/L2 | ◇ 工具已交付，未执行 | `tools/platform_observers/btb_observer.c` | 功效预算先行，未跑 |
| 8 | M4 compare 失配位置恢复（L2 校准臂） | L2 | ◇ 已本地演示 | `docs/evidence/l2-m4-recovery-20261116/RESULT.md` | vulnerable 15/20（未达 20/20 目标）、ct 1/20 未检出；本地未锁频 |
| 9 | M3 LUT 下标序列恢复（A2.1×M3） | L2 | ◇ 计划 | `docs/research/l2l3-plan-20261116/PLAN.md` §1 | 未执行；判据与样本量已冻结 |
| 10 | 真实臂消息位恢复（L3） | L3 | △ 未授权/未开跑 | `docs/research/l2l3-plan-20261116/PLAN.md` §2 | 须 ≥16 已知位 + 功效门 + 主控确认 |
| 11 | 完整密钥恢复（L4） | L4 | ✕ 排除 | 本文件 §0 | 须主控确认且不进入匿名支撑包 |

结论口径：L0/L1 已有实证资产，但都是固定输入/固定产物的有限描述；L2 只有 M4 人工校准臂的
本地演示（15/20 与 ct 未检出），M3×R19 仍是计划；L3/L4 未开跑/未授权，不写任何恢复结论。

## 3. P0–P6 新证据索引（本周期）

| 阶段 | 证据/交付路径 | 关键结论状态 |
|---|---|---|
| P0 | `docs/research/p0-baseline-20261116/RESULT.md` | 环境基线（WSL/clang-format 21/57 测试） |
| P1 | `tools/platform_stats/shape_stats.c`、`tests/test_shape_stats.c`、`docs/evidence/r20-shape-tests-20261116/` | 形状/方差三族族外回放完成 |
| P2 | `docs/evidence/r0b-vendor-surface-20261116/`、`docs/evidence/r0a-branch-fix-20261116/`、`docs/patches/m2-frommsg-barrier-*.patch`、`docs/research/r0a-recap-20261116/PLAN.md` | vendor 扫描 0 命中；R0a 三候选判定 + KAT/等价；复测 PLAN 待主控 |
| P3 | `tools/pipeline/{pipeline.py,manifest.schema.json,findings.schema.json}`、`docs/research/phase3-session-20261116/manifests/` | 编排器 MVP + 两个真实 manifest report（runs 在 build/，未入库） |
| P4 | `tools/pipeline/{repair_patterns/,repair_propose.py,mcp_server.py}`、`docs/research/phase4-session-20261116/SESSION.md` | 四模式建议器 + MCP 八工具冒烟绿 |
| P5 | `tools/platform_observers/`、`docs/patches/m3-lut-shared-page.patch`、`docs/research/{r18,r19}-*-20261116/PLAN.md` | 三观测者 + shared-on 臂；pilot PLAN 冻结，未采集 |
| P6 | `tools/adaptive/`、`docs/evidence/l2-m4-recovery-20261116/`、`docs/research/l2l3-plan-20261116/PLAN.md` | 逐位检验器/构造器/引擎；M4 演示 15/20 vs ct 1/20；L2/L3 计划冻结 |
| P7 | `docs/R17-向量化排查表-20261116.md`、`docs/research/{r23,r24}-*-20261116/`、本文件 | R17 反汇编层审计完成；R23 本地 24 格判定；R24 harness/计划；本威胁模型 v2 |

## 4. 未执行节点与边界（逐条一句话）

- A2.1/A2.2/A2.3 观测者：工具与 PLAN 已备，**未执行任何采集**；结论只能等主控按冻结 PLAN 执行。
- R17 动态层：Memcheck/KAT 复核未做（本机 `valgrind` ABSENT），见 `A_LINE_BUNDLE.md` A-R17-01..04。
- R23 动态层：24 格 Memcheck 与锁频计时未做，见 `A-LINE` A-R23-01/02 与 `r23-.../BARE_METAL_PLAN.md`。
- R24 Binsec：harness/cfg/PLAN 已备，执行未做（A-R24-01）。
- R18/R19 pilot 与正式采集：未执行，MDE/预算冻结在 PLAN。
- L2 的 M3×R19 恢复：未执行；M4 演示只到 15/20（本地未锁频），不作为总体检出率。
- L3：真实臂消息位恢复未授权、未开跑；先决条件为 ≥16 已知位与预注册功效门。
- L4：完整密钥恢复排除，须主控确认且不进入匿名支撑包。
- A2.4 TLB / A2.5 推测执行：无对照臂/未做瞬时观测，只作边界。
- A3.1 远程：本预算未检出；A3.2 自适应选择密文攻击为 AGENTS 红线。
- B2/B3 掩码与隐藏：不做模块，只作文献对照；D5 集成栈、C3/C4 高阶统计与画像、G3 Intel 对照未覆盖。

## 5. 不变量

- R11 原件 `docs/evidence/r11-threat-20261016/THREAT_MODEL.md` 未改；本文件是新目录新文件。
- 不改变 R02/R04 与任何既有签收；不写"恒时/可利用/密钥恢复"；L3/L4 只在授权条款下讨论。
- AGENTS 分级文本的正式落地待主控（本文件引用拟替换文本并显式标注），不替代治理文件修订。
