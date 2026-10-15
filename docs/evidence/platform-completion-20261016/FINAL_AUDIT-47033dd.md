# 多泄漏模块平台完整完成条件 —— 最终完成审计（FINAL_AUDIT）

**审计快照：** 2026-10-16T02:08:44+08:00（Asia/Shanghai）
**被审计文档：** `docs/platform/COMPLETION_REQUIREMENTS.md`（sha256 前 16 位 `31cac9c7b848585c`，文档自述基线 `main@ac46e62`）
**审计时仓库状态：** 分支 `main`，HEAD `47033dd864cab5544d2d2cc82d1ed0cf03b30f83`（"fix: restrict platform controller empty-task commands to frozen names"，02:06:31）
**审计性质：** 只读。本审计不修改 `COMPLETION_REQUIREMENTS.md`、不修改任何被审计证据文件、不 `git add/commit/push`。本文件与 `FINAL_AUDIT.csv`、`partials/S09.md` 是本路唯一新增产物。

> **后续将进行最终复核。** 本快照期间 M2/M3/M4/M5 的锁频采数与若干工具运行正在并行推进（审计开始前 45 分钟内，`docs/evidence/` 有 693 个文件被写入；HEAD 在审计过程中从 `44c209a` 推进到 `47033dd`）。因此本表的"未执行/部分"判定**只对上述快照时点成立**，不排除随后被新证据改变。正式收口应由主控在全部并行路停止写入后，按本文件与 `FINAL_AUDIT.csv` 的核对命令重跑一遍，并对差异逐条说明。本审计的价值在于**把口径与证据路径核实清楚**，不给出乐观结论。

> **状态口径（严格遵守原文第 1 节）：** 未运行 ≠ 未检出；软件就绪 ≠ 工具已执行；clone 成功 ≠ 运行成功；前置完成 ≠ 模块完成。本审计中：
> - **已满足**＝已有对应实际产物、命令与结果，可按下述路径核对；
> - **部分**＝有前置实现或局部证据，但本行要求的运行/整合尚缺；
> - **未执行**＝本行要求的运行完全没有发生（原文"未满足"中"未运行"的子类，为满足本任务的状态词要求单列；原文"未满足"＝本列"未执行"∪"部分"中确无交付者）；
> - **条件未触发**＝类型为条件项且触发条件尚未成立；
> - **可选未做**＝类型为可选且按计划允许不做。
>
> 任何"未检出/无报警"结论在本表中都不会被升级为"恒时"或"总体阴性"。

---

## 1. "32 项"的口径推导（两种口径都算，不删行、不改判定）

### 1.1 原文逐行 ID 清单（G/A/B/C/D/E/F 全量）

| 段 | ID 范围 | 行数 | 原文位置 |
|---|---|---:|---|
| 贯穿门槛 G | G01–G09 | 9 | §2 表格（原文 L27–L35） |
| Phase A | A01–A04 | 4 | §3 表格（L45–L48） |
| Phase B | B01–B07 | 7 | §4 表格（L57–L63） |
| Phase C | C01–C05 | 5 | §5 表格（L73–L77） |
| Phase D | D01–D06 | 6 | §6 表格（L83–L88） |
| Phase E | E01–E06 | 6 | §7 表格（L94–L99） |
| Phase F | F01–F04 | 4 | §8 表格（L108–L111） |
| **合计** | **G01–G09 + A01–F04** | **41** | 40 条表格行 + 1 条 G01 |

**总行数 = 41。** 其中：必做 36、条件项 2（B06、D03）、可选 3（C05、D06、E06）。36+2+3=41。

### 1.2 口径 B（用户口径"32 项"）＝ A–F 六个 Phase 的阶段项

- 推导：A(4)+B(7)+C(5)+D(6)+E(6)+F(4) = **32**。G01–G09 是 §2 的"贯穿所有阶段的门槛"，不属于任何 Phase，故不计入"阶段项"。
- 独立佐证：`docs/evidence/platform-completion-20261016/partials/S01.md` L16 原文自述"**共32条阶段项：27条必做、2条条件项、3条可选项；另有9条贯穿门槛**"。本审计按原文逐行复算得到 27/2/3/9，与该自述完全一致（32 阶段项 + 9 贯穿门槛 = 41 行）。
- 32 的阶段项内部：必做 27（32−2 条件−3 可选）；条件项 2；可选 3。

### 1.3 口径 A（原文全量 41 行）与"排除后的必做子集"

- 全量 = 41；"排除可选与未触发条件项后的必做子集" = 36（不是 32）。
- **结论：若把"32"理解为"排除可选/条件项后的必做门"，则按原文得到 36 项，与 32 不符。** 与 32 相符的合理划分只有一种且自洽：**32 = A–F 阶段项（必做 27 + 条件 2 + 可选 3），另加 9 条 G 贯穿门槛构成 41 行全量**。
- 另一条同样对不上 32 的划法（供排除）：41 −3 可选 −2 条件 −4 "Phase A 已满足骨架" = 32，但该划法无原文依据（§10 只说 Phase A 四项已具备骨架证据，未把它们排除出验收范围），故**不采用**，仅在此说明已被检验并否决。

**两个口径的完成计数（快照时点）：**

| 口径 | 分母 | 已满足 | 部分 | 未执行 | 条件未触发 | 可选未做 | 必做子集完成率 |
|---|---:|---:|---:|---:|---:|---:|---:|
| **口径 A：原文全量 41 行** | 41 | **18** | 15 | 4 | 1 | 3 | 必做 36 中 18 已满足（**50.0%**） |
| **口径 B：用户"32 项"（A–F 阶段项）** | 32 | **14** | 10 | 4 | 1 | 3 | 必做 27 中 14 已满足（**51.9%**） |

---

## 2. 汇总计数表

### 2.1 类型 × 状态 交叉表（自洽校验）

| 类型 | 已满足 | 部分 | 未执行 | 条件未触发 | 可选未做 | 小计 |
|---|---:|---:|---:|---:|---:|---:|
| 必做 | 18 | 14 | 4 | 0 | 0 | **36** |
| 条件项（B06、D03） | 0 | 1（D03） | 0 | 1（B06） | 0 | **2** |
| 可选（C05、D06、E06） | 0 | 0 | 0 | 0 | 3 | **3** |
| **合计** | **18** | **15** | **4** | **1** | **3** | **41** |

- 用户要求的计数口径：总数 **41**、已满足 **18**、部分 **15**、未执行/未满足 **4**、可选未做 **3**；另有条件项未触发 **1**。
- 41 行 × 8 列机器可读版本见 [FINAL_AUDIT.csv](FINAL_AUDIT.csv)（已校验：41 数据行、8 列、引用路径 115 条全部存在、0 断链）。

### 2.2 分 Phase 计数

| 段 | 行数 | 已满足 | 部分 | 未执行 | 条件未触发 | 可选未做 |
|---|---:|---:|---:|---:|---:|---:|
| G 贯穿门槛 | 9 | 4（G01/G02/G04/G08） | 5（G03/G05/G06/G07/G09） | 0 | 0 | 0 |
| A 平台骨架 | 4 | 4 | 0 | 0 | 0 | 0 |
| B M2 KyberSlash | 7 | 3（B01/B02/B03） | 2（B04/B07） | 1（B05） | 1（B06） | 0 |
| C M5 阴性对照 | 5 | 2（C01/C02） | 1（C04） | 1（C03） | 0 | 1（C05） |
| D M3 秘密访存 | 6 | 2（D01/D02） | 2（D03/D05） | 1（D04） | 0 | 1（D06） |
| E M4 比较/有界验证 | 6 | 3（E01/E02/E03） | 1（E05） | 1（E04） | 0 | 1（E06） |
| F Mona/报告/平台图 | 4 | 0 | 4 | 0 | 0 | 0 |

---

## 3. 逐项审计矩阵（41 行）

**图例：** 状态列取值见文首口径。证据路径均为**本次实际 `test -f`/`ls` 验证通过**的仓库相对路径（CSV 中 115 条证据路径已由脚本复验，0 缺失）。`核对命令` 一律在仓库根 `/Users/yin/code/cryProject` 下可直接执行；更完整的命令见 `FINAL_AUDIT.csv` 的 `verify_command` 列。

### 3.1 G 贯穿门槛（9 行）

| ID | 类型 | 要求产物 | 证据路径（已验证存在） | 状态 | 剩余缺口 | 核对命令 |
|---|---|---|---|---|---|---|
| G01 | 必做 | 各 RESULT 三句结论、运行入口及原日志；真实案例与人工校准分列 | `docs/evidence/m2-kem-20261016/RESULT.md`；`docs/evidence/m3-completion-20261016/RESULT.md`；`docs/evidence/m4-completion-20261016/RESULT.md`；`docs/evidence/m5-completion-20261016/RESULT.md`；`deliverables/research/multi-leakage-platform-20261016/report.md`§6 | 已满足 | 后续新增模块继续留三句；无 exploit/密钥恢复（已 grep 核对 5 份 RESULT 均声明） | `grep -l 密钥恢复 docs/evidence/*-20261016/RESULT.md` |
| G02 | 必做 | 保护路径 diff 为空；新证据新目录 | `git diff ac46e62..47033dd -- sources vendor` 为空；`git status --porcelain sources/` 为空 | 已满足 | 后续每次提交仍须复核该 diff | `git diff --stat ac46e62 HEAD -- sources vendor` |
| G03 | 必做 | 正式采数前冻结并本地提交 PLAN | `docs/evidence/m2-kem-20261016/STATISTICAL_PLAN.md`；`docs/evidence/m3-completion-20261016/STATISTICAL_PLAN.md`；`docs/evidence/m4-completion-20261016/STATISTICAL_PLAN_DRAFT.md`；`docs/evidence/m5-completion-20261016/PLAN.md` | 部分 | 四份新时序 PLAN 均已成文但 `git ls-files` 计数为 0（未跟踪、未冻结提交）；已提交的只有 M2 定位 PLAN、M5 前置 PLAN、M1 闭合 PLAN（`4b1502c`） | `git ls-files --error-unmatch docs/evidence/m2-kem-20261016/STATISTICAL_PLAN.md` |
| G04 | 必做 | 计时输入与目标功能成立；独立公开 KAT、边界/篡改/等价、普通与 sanitizer 分开 | `m2-kem-20261016/native-qualification/ctest-ordinary.log`（7 passed）与 `ctest-sanitize.log`（7 passed）；`tests/vectors/kyber768_round3/PQCkemKAT_2400.rsp`；`m3-completion-20261016/native-8b6f2d91/build-ordinary.log`（"100% tests passed, 0 tests failed out of 6"，含 full_output_equivalence）；`m4-completion-20261016/software-native/software-logs-v2/ctest.txt`（7 tests）；`m5-completion-20261016/RESULT.md` | 已满足 | 挂载/产物变更后须重验；锁频窗口换 ELF 时属重复前置 | `grep -c '^Test Passed\.' docs/evidence/m2-kem-20261016/native-qualification/ctest-ordinary.log` |
| G05 | 必做 | boost=0、performance、约4300000kHz、taskset、进入/采中/退出日志、restore_match | `docs/evidence/r02-r04-close-20261016/raw/cpu-6/lock.txt`（`lock_accepted=yes / boost=0 / governor=performance / epp=performance / min=max=4300000`）；`raw/cpu-6/status.txt`（`restore_match=yes`）；`docs/evidence/platform-control-fix-20261016/README.md` | 部分 | 已有 **M1 R02/R04** 真实锁频运行；**M2/M3/M4/M5 均无各自锁频运行**；控制器首次真实空任务资格失败（q-normal 在任何频率写入前被拒），修复后真实 root 资格待重跑 | `cat docs/evidence/r02-r04-close-20261016/raw/cpu-6/lock.txt docs/evidence/r02-r04-close-20261016/raw/cpu-6/status.txt` |
| G06 | 必做 | 全量 CSV、乱序/种子/单位/时钟、源/工作区/ELF 摘要、ENV、调用边界、命令 | `docs/evidence/r02-r04-close-20261016/raw/cpu-6/fixed/samples.csv`；`raw/cpu-6/fixed/meta.txt`；`docs/evidence/r02-r04-close-20261016/ENV.md` | 部分 | 仅 M1 类对有 raw 与 ENV；**M2/M3/M4/M5 证据目录内 0 个 CSV**（`find -name '*.csv'` 为空），无派生工具输入 | `find docs/evidence/m2-kem-20261016 docs/evidence/m3-completion-20261016 docs/evidence/m4-completion-20261016 docs/evidence/m5-completion-20261016 -name '*.csv'` |
| G07 | 必做 | PLAN 的 family_id/成员/α、有效参数 p 与 Holm 表；RTLF/dudect 独立列 | `docs/evidence/r02-r04-close-20261016/holm.csv`（m=6，FWER α=0.05）；`raw/cpu-6/rtlf/fixed-run1.json`；`raw/cpu-6/dudect/fixed.txt`；`scripts/platform_stats/README.md` | 部分 | 已有 M1 参数族与三工具对照（dudect/RTLF 族外）；**新模块尚无实际参数族与运行结果**，仅软件接口就绪 | `head -3 docs/evidence/r02-r04-close-20261016/holm.csv` |
| G08 | 必做 | 源、构建、缓存、临时、归档、工具存储与链接目标核查 | `m2-kem-20261016/native-qualification/boundary-and-process-review.json`（45 symlink，越界 0）；`m3-completion-20261016/native-8b6f2d91/symlinks.txt` 与 `boundary-end.log`（root/tmp/cache 均在 Cry 内）；`m4-completion-20261016/runtime/runtime-logs/path-audit.json`（466 symlink，越界 0）；`mona-wire-20261016/archive-verification.json`（1718 成员、0 symlink） | 已满足 | 快照内每个新运行都有边界核查且越界为 0；Mona/M4 的 JDK/opam 安装亦在自有根内；后续新运行仍须逐次重做 | `cat docs/evidence/m4-completion-20261016/runtime/runtime-logs/path-audit.json` |
| G09 | 必做 | main 本地模块提交、不 push；必要检查/format-check/diff/模块 commit；身份按约定 | `main@47033dd`，作者 `Gowin-liuyin`；`r02-r04-close-20261016`（88 文件已跟踪）、`platform-control-fix-20261016`（8 文件已跟踪） | 部分 | **六个新证据目录 tracked=0**：`m2-kem`、`m3-completion`、`m4-completion`、`m5-completion`、`mona-wire`、`platform-report`；模块提交与随附 format-check 记录未完成（与 F04 的最终交接缺失互相印证） | `git ls-files docs/evidence/m2-kem-20261016 \| wc -l` |

### 3.2 Phase A 平台骨架（4 行，全部已满足）

| ID | 类型 | 要求产物 | 证据路径（已验证） | 状态 | 剩余缺口 | 核对命令 |
|---|---|---|---|---|---|---|
| A01 | 必做 | 计划与架构可引用，标明模块/CSV/工具/证据边界 | `docs/platform/ARCHITECTURE.md`（9884 B）；`docs/多泄漏模块平台工程计划-20261016.md`（23502 B） | 已满足 | 接口有变时同步架构，不改旧执行源 | `test -f docs/platform/ARCHITECTURE.md` |
| A02 | 必做 | 六工具 clone、完整 commit/tree、获取与许可状态 | `third_party/REPOS.md`；六个仓库目录实际存在且 HEAD 与 REPOS.md 六个 40 位提交号**逐一相等**（RTLF `2497d66…`、dudect `dc26965…`、ctgrind `ca93f4f…`、mona-timing-lib `81e4de2…`、mona-timing-report `4c74fb7…`、Microwalk `7760a92…`） | 已满足 | clone 成功≠运行成功（运行另见 C02/E03/F01 已实跑）；RTLF/ctgrind/mona 许可仍待上游确认 | `git -C third_party/Microwalk rev-parse HEAD` |
| A03 | 必做 | 两类 CSV 经统一入口输出 CI/Welch、RTLF α=.01、dudect 摘要；错误不伪成功 | `scripts/platform_stats/README.md`；`platform-matrix-20261016/integration/ordinary-ctest.log`（Test #61 `platform_stats_battery` Passed）与 `sanitize-ctest.log`（61/67 实测命令与耗时） | 已满足（软件接口层） | CSV 离线回放不等于在线采集；原生在线 dudect 属模块后续，本行不覆盖 | `grep platform_stats_battery docs/evidence/platform-matrix-20261016/integration/ordinary-ctest.log` |
| A04 | 必做 | 模块模板与平台矩阵；定位/统计/边界三句及明确未知状态 | `templates/MODULE_RESULT.md`；`docs/evidence/platform-matrix-20261016/RESULT.md` | 已满足 | 骨架就位；矩阵为 01:29 快照，最终须逐模块回填并由主控更新（见矛盾清单 C-01） | `test -f templates/MODULE_RESULT.md` |

### 3.3 Phase B M2 KyberSlash（7 行）

| ID | 类型 | 要求产物 | 证据路径（已验证） | 状态 | 剩余缺口 | 核对命令 |
|---|---|---|---|---|---|---|
| B01 | 必做（允许既定替代） | 未修/完整已修固定源码、许可证、PIN、秘密路径与实际 div/idiv 对照 | `m2-kyberslash-20261016/VERSION_AUDIT.md`；`disasm/linux-clang18-oz-{unfixed,fixed}-{poly_tomsg,poly_compress,polyvec_compress}.asm`（6 份） | 已满足 | 无须为凑 liboqs tag 重建已有效的 pq-crystals 路线 | `test -f docs/evidence/m2-kyberslash-20261016/VERSION_AUDIT.md` |
| B02 | 必做 | 原 20250805 补丁工具真实可用；未修报警、已修消失；普通 Memcheck 对照 | `version-audit/varlat-unfixed.log`（`1280 errors from 3 contexts`）；`version-audit/varlat-fixed.log`（`0 errors from 0 contexts`）；`varlat-tool/README.md`、`varlat-tool/tool-logs.tar.gz`；`version-audit/ordinary-memcheck-{unfixed,fixed}.log` | 已满足（热点层） | 只覆盖三热点；换 ELF 后须重新绑定工具与秘密范围，不能搬用旧日志 | `grep 'ERROR SUMMARY' docs/evidence/m2-kyberslash-20261016/version-audit/varlat-unfixed.log docs/evidence/m2-kyberslash-20261016/version-audit/varlat-fixed.log` |
| B03 | 必做前置 | 完整历史 Kyber768 解封装接入同一测量协议；功能资格、合法输入/拒绝语义、实际链接核验 | `m2-kem-20261016/RESULT.md`；`native-qualification/ctest-ordinary.log`（7 passed）与 `ctest-sanitize.log`（7 passed）；`ordinary-unfixed-measure.ldd`；`unfixed-mlkem_decapsulate.asm`（证实长度/空指针检查后进入原 `pqcrystals_kyber768_ref_dec`）；`tests/vectors/kyber768_round3/SHA256SUMS` | 已满足 | 接入与资格成立；**锁频窗口实际执行属 B05，本行不覆盖**，不得写成端到端已完成 | `grep -c '^Test Passed\.' docs/evidence/m2-kem-20261016/native-qualification/ctest-ordinary.log` |
| B04 | 必做 | 新正式 PLAN 固定主类对、预算、α、停止/复测及家族，先提交再启动 | `m2-kem-20261016/STATISTICAL_PLAN.md`（三 run 31337/CPU2、424242/CPU2、31337/CPU6；每类 10000；端到端 m=6） | 部分 | 草案成文但 **tracked=0**，未冻结提交；采集未启动 →"先提交再启动"未满足；不得由采数结果倒写计划 | `git ls-files --error-unmatch docs/evidence/m2-kem-20261016/STATISTICAL_PLAN.md` |
| B05 | 必做 | 未修/已修完整解封装锁频采集与 CI/Welch+Holm、RTLF、原生在线 dudect 对照 | **（无）** | 未执行 | 无 M2 时间 CSV、无 ENV、无频率恢复记录、无工具输出、无参数族与复测；不得用合成数据或离线回放替代 | `find docs/evidence/m2-kem-20261016 -name '*.csv'` |
| B06 | 条件项 | 若完整调用不区分，按合同补热点微基准，保留完整调用结果并分层 | `m2-kem-20261016/STATISTICAL_PLAN.md` §"条件微基准：触发与边界事先固定"（L110–121，预注册单一热点 `poly_tomsg`、固定公开多项式、与主表同序同预算） | 条件未触发 | 触发条件依赖 B05 结果；当前完整调用未运行，条件不成立。预注册本身已满足"事先固定"要求；不得事后只挑显著热点，也不强求微基准阳性 | `sed -n '110,121p' docs/evidence/m2-kem-20261016/STATISTICAL_PLAN.md` |
| B07 | 必做 | 新 M2 REQUIREMENTS/PLAN/ENV/RESULT/raw/disasm/日志；适用时 holm/replication；平台行与报告同步 | `m2-kem-20261016/{REQUIREMENTS.md,ENV.md,RESULT.md,SHA256SUMS,SOFTWARE_CONTRACT.md}`；`native-qualification/`（42 文件，含 ELF/ASM/ldd/日志） | 部分 | 软件与原生资格包完整；**缺 raw/holm/replication 与统计结论**；平台矩阵 M2 行与报告未按新结果更新 | `ls docs/evidence/m2-kem-20261016/` |

### 3.4 Phase C M5 阴性对照（5 行）

| ID | 类型 | 要求产物 | 证据路径（已验证） | 状态 | 剩余缺口 | 核对命令 |
|---|---|---|---|---|---|---|
| C01 | 必做 | 固定 mlkem-native、完整 reference/measure 调用链、适用独立功能资格 | `vendor/mlkem-native/PIN.md`；`m5-mlkem-native-20261016/RESULT.md`；`measure-link.txt`（只链 `reference/libmlkem.a`）；`snapshot-verification.json`（126 文件核对） | 已满足（前置） | 保留普通参考路径，不得误选人工补丁变体 | `test -f vendor/mlkem-native/PIN.md` |
| C02 | 必做 | x86_64 原生反汇编、秘密标记分支/地址检查，以及已就绪并已运行的 varlat | `m5-completion-20261016/RESULT.md`；`m5-completion-20261016/software-dynamic-evidence.tar.gz` → `logs-v2/{system,varlat-no,varlat-yes}.valgrind.log` 三模式 **0 errors/0 contexts、exit 0**（本次已解包核验 `ERROR SUMMARY` 与 `exit-status` 文件） | 已满足 | 仅 2 key×5 类有限公开输入的**无命中观察**，不外推任意输入/总体误报率；成员在 tar 内，复核须解包 | `tar -xzOf docs/evidence/m5-completion-20261016/software-dynamic-evidence.tar.gz logs-v2/varlat-yes.valgrind.log \| grep 'ERROR SUMMARY'` |
| C03 | 必做 | 与 M1 同规程/主类对的锁频原值、CI/Holm、RTLF、原生在线 dudect | **（无）** | 未执行 | M5 无 raw 时间样本、无频率恢复、无 CI/Holm/RTLF 判决；online dudect 只通过"不读钟 callback + 合成 raw"自检，**不能据此填阴性统计通过** | `find docs/evidence/m5-completion-20261016 -name '*.csv'` |
| C04 | 必做 | 三句 RESULT 判断有限范围内是否符合阴性预期；若阳性完成原因调查 | `m5-completion-20261016/RESULT.md`（定位/统计/边界三句，统计栏明确写"未执行 measure 与在线 dudect，不能据此填阴性统计通过"） | 部分 | 三句与诚实边界已具备；**缺真实统计运行**，故无法给出"符合/不符合阴性预期"的完整判断；不得预填"通过" | `sed -n '1,12p' docs/evidence/m5-completion-20261016/RESULT.md` |
| C05 | 可选 | 修后 liboqs ref 作为第二阴性 | **（无）** | 可选未做 | 不是 M5 必做前置；主 mlkem-native 完成后才决定；不阻止原文 §10 定义的完整完成 | `—` |

### 3.5 Phase D M3 秘密访存校准（6 行）

| ID | 类型 | 要求产物 | 证据路径（已验证） | 状态 | 剩余缺口 | 核对命令 |
|---|---|---|---|---|---|---|
| D01 | 必做 | 人工 LUT 开/关夹具，功能等价与边界；按原文挂载到解封装路径，保留"人工构造" | `docs/patches/m3-mem-lut-toggle.patch`；`m3-completion-20261016/patch-apply.log` 与 `patch-dry-run.log`（`--dry-run --fuzz=0`）；`native-8b6f2d91/on.measure.disasm` 与 `off.measure.disasm`；`native-8b6f2d91/build-ordinary.log`（6/6，含 `platform_m3_full_output_equivalence`） | 已满足 | 人工构造性质须始终标注；旧独立夹具（`fixtures/mem_lut_leak`）不得冒称 KEM 端到端 | `grep -n full_output_equivalence docs/evidence/m3-completion-20261016/native-8b6f2d91/build-ordinary.log` |
| D02 | 必做 | ctgrind/Memcheck 秘密下标定位与产物检查，开/关实际日志 | `native-8b6f2d91/on-secret.memcheck.log`（**1280 errors/2 contexts**）、`off-secret.memcheck.log`（0/0）、`on-defined.memcheck.log`（0/0）、`off-defined.memcheck.log`（0/0）；旧一轮 `m3-memaccess-20261016/native-idAExSCX/logs/on-valgrind.txt`、`off-valgrind.txt` | 已满足 | 新产物下 1280/2 与旧 32/1 必须分列，不能混作一次运行；换产物须重验 | `grep 'ERROR SUMMARY' docs/evidence/m3-completion-20261016/native-8b6f2d91/on-secret.memcheck.log docs/evidence/m3-completion-20261016/native-8b6f2d91/off-secret.memcheck.log` |
| D03 | 条件优先，可降级 | 有 Pin 时运行 Microwalk；无 Pin 时尝试满足 Cry 边界的可行路径，仍受阻可降级（保留 ctgrind+人工夹具统计） | `m3-completion-20261016/NOTES.md` §"Microwalk 按计划降级"（pin/dotnet/microwalk 均未找到；`docker info` 返回 `DockerRootDir=/home/docker-data`，越 Cry 边界）；`m3-memaccess-20261016/NOTES.md`；`native-8b6f2d91/environment.log` | 部分 | 探测、安装/运行状态与具体阻塞**证据完整**，且已按降级用标准 Memcheck 定位、未把 clone 或 docker 命令写成工具已运行；**但降级所要求的"人工夹具统计"（即 D04 的统计电池）尚未执行**，故降级链未闭合 | `sed -n '/Microwalk 按计划降级/,$p' docs/evidence/m3-completion-20261016/NOTES.md` |
| D04 | 必做 | 冻结类对后开/关同类输入锁频统计电池与复测；不能比较两版本总成本冒称泄漏 | **（无）** | 未执行 | 无原始时间数据；`STATISTICAL_PLAN.md` 已备但未冻结提交、未采数、未检验；不得用两版总耗时差当作泄漏证据 | `find docs/evidence/m3-completion-20261016 -name '*.csv'` |
| D05 | 必做 | 新 RESULT/ENV/raw/定位/家族等与平台行，人工校准独立于真实案例 | `m3-completion-20261016/{RESULT.md,ENV.md,native-build-identity.txt}`；`STATISTICAL_PLAN.md` | 部分 | 定位/资格/身份齐备；**缺 raw、家族与统计**；平台矩阵 M3 行未更新；本行不计为第三个上游 CVE | `sed -n '1,10p' docs/evidence/m3-completion-20261016/RESULT.md` |
| D06 | 可选 | 有公告/固定提交的真实历史访存例 | **（无）** | 可选未做 | 不作为人工校准完成条件，无须硬凑 | `—` |

> 注：D05 行中 `NATIVE_BUILD_OPTIONS.txt` 实际位于 `docs/evidence/m3-memaccess-20261016/`，`m3-completion-20261016/` 下不存在同名文件——本审计按实际存在路径给出，见矛盾清单 C-04。

### 3.6 Phase E M4 比较/拒绝校准与有界验证（6 行）

| ID | 类型 | 要求产物 | 证据路径（已验证） | 状态 | 剩余缺口 | 核对命令 |
|---|---|---|---|---|---|---|
| E01 | 必做 | 人工提前退出与恒时意图比较；相等性等价、封装边界与产物 | `fixtures/early_reject_memcmp/README.md`（长度 0–32、全部差异位置/替换字节对照标准 `memcmp(...)==0`；封装只接受 32 字节）；`m4-compare-20261016/ctest-ordinary.log` 与 `ctest-sanitize.log`（各 `m4_vulnerable_self_test`/`m4_ct_self_test` 等 4/4 Passed）；`m4-completion-20261016/RESULT.md` | 已满足 | 本夹具未挂载 KEM，故不触发"挂载后另验隐式拒绝"条件；不宣称标准 memcmp 排序语义 | `grep -n self_test docs/evidence/m4-compare-20261016/ctest-ordinary.log` |
| E02 | 必做 | ctgrind/Memcheck 定位非恒时比较，关版对照与源码/ELF/日志关联 | `m4-compare-20261016/linux-run-250f424b/valgrind-vulnerable.log`（`32 errors from 1 contexts`）、`valgrind-ct.log`（`0 errors from 0 contexts`）；`m4-completion-20261016/software-native/software-logs-v2/formal-vulnerable-disasm.txt` | 已满足 | 新入口/编译产物改变后须重新核验；判据关联须同时看源码行、ELF 地址与日志 | `grep 'ERROR SUMMARY' docs/evidence/m4-compare-20261016/linux-run-250f424b/valgrind-vulnerable.log docs/evidence/m4-compare-20261016/linux-run-250f424b/valgrind-ct.log` |
| E03 | 必做 | Binsec 对抽出 compare/verify 实际执行；入口/秘密模型/bound/退出/原日志，反例与有界完整探索对照 | `formal-v1/vulnerable-1-16/stdout.txt`（`Instruction 0x8049047 has control flow leak` → `Program status is : insecure`）；`formal-v1/ct-1-16/stdout.txt`（`Program status is : secure`）；两目录 `status.txt`（`exit_status=0`、depth 10000、120s/5s/180s）；`checkct.toml`、`model.cfg`、`identity.txt`、`disasm.txt` | 已满足（小边界） | 只覆盖 i386 `-O1`、公开长度 1–16 的抽取内核、具体栈指针；有界 secure 不外推 32 字节采集 ELF、任意长度、完整 KEM 或其他编译条件 | `grep -E 'Program status' docs/evidence/m4-completion-20261016/formal-v1/vulnerable-1-16/stdout.txt docs/evidence/m4-completion-20261016/formal-v1/ct-1-16/stdout.txt` |
| E04 | 必做 | 定义端到端调用边界与两类输入，冻结后采数并跑统计电池与复测 | **（无）** | 未执行 | 未执行 `--collect`：无 M4 原始时间 CSV、无在线 dudect 测量、无 CI/Holm/RTLF；统计合同仍为草案（`STATISTICAL_PLAN_DRAFT.md`），不得混入旧 m=0 计划 | `find docs/evidence/m4-completion-20261016 -name '*.csv'` |
| E05 | 必做 | 新结果包与总表、报告的校准/有界结论，保留局限 | `m4-completion-20261016/{RESULT.md,ENV.md,REQUIREMENTS.md,PLAN.md}`；`deliverables/research/multi-leakage-platform-20261016/report.md`§6/§8（已纳入 Binsec 有界实跑与"时序仍未运行"） | 部分 | 定位/形式化/边界已分列且不互相替代；**统计缺失**；平台矩阵 M4 行未更新，报告须在采数后刷新 | `sed -n '1,8p' docs/evidence/m4-completion-20261016/RESULT.md` |
| E06 | 可选 | Binsec 扩大到完整解封装，或增加真实 TLS/KEM 历史案例 | **（无）** | 可选未做 | 路径爆炸只限制扩大范围，**不能免除 E03 小边界实跑**（E03 已完成） | `—` |

### 3.7 Phase F Mona、报告与平台图（4 行）

| ID | 类型 | 要求产物 | 证据路径（已验证） | 状态 | 剩余缺口 | 核对命令 |
|---|---|---|---|---|---|---|
| F01 | 必做于完整 Phase F | Mona 对 M1 与 M2 主 CSV 给独立对照行，记录库/报告提交、输入、算法设置、原输出与摘要 | `mona-wire-20261016/RESULT.md`；`native-qualification/run/m1/m1-mona.csv`（六份 M1 类对真实回放，`holm_member=false`）；`local-qualification/m1/`（逐项 box-results/validations/摘要）；`archive-verification.json`；`failed-preparation/`（三次准备失败原件保留） | 部分 | **M1 已实际执行**（Linux + macOS，且结果未与既有检测方向一致，已如实记录）；**M2 无对照行**（阻塞于 B05）；`native-qualification/run/` 下只有 `m1` 子目录；不得把工具缺失写阴性或把 RTLF 结果改名 Mona | `head -3 docs/evidence/mona-wire-20261016/native-qualification/run/m1/m1-mona.csv` |
| F02 | 必做 | 新正式报告版本含"检测—定位—修复—复测"章，实测表/图与证据一一对应 | `deliverables/research/multi-leakage-platform-20261016/report.tex`、`report.pdf`、`report.md`（§8"修复与复测的判定链"）；`report-data.json`、`index.html`、`platform-matrix.svg`；`docs/evidence/platform-report-20261016/RESULT.md`（draft12、16 来源、6 页目视通过、八类坏包拒绝） | 部分 | 载体、章节与离线复算已就位；**新增模块正式时序全部为 `not_run`**，须采数后刷新；大纲不等于最终章稿，不覆盖旧封存 DOCX/PDF | `grep -n 修复与复测 deliverables/research/multi-leakage-platform-20261016/report.md` |
| F03 | 必做 | 平台矩阵图与可重建源，分真实案例/人工校准/阴性和各层状态 | `deliverables/research/platform-completion-20261016/figures/platform-evidence-matrix.svg`、`.png`（2920×1620）、`render_matrix.py`（可重建源）、`REVIEW.md`、`SHA256SUMS`、`RENDER_ENV.json` | 部分 | 图源可重建、30 格与图注已目视核对；**当前是基线状态图**，最终须按新结果更新图与图注，不得用它伪装全目标完成图 | `test -f deliverables/research/platform-completion-20261016/figures/render_matrix.py` |
| F04 | 必做 | 当前 deliverables 入口、进度、平台总表及最终交接同步；复算路径/边界可读 | `deliverables/research/multi-leakage-platform-20261016/README.md`；`deliverables/research/platform-completion-20261016/{README.md,EVIDENCE_MATRIX.csv,REPORT_OUTLINE.md}`；`docs/full-work-progress.md`；`HANDOFF_DONE.md`（仅覆盖启动分工） | 部分 | 入口与进度已更新；**缺最终完成交接与本地提交清单**（与 G09 六个未提交目录互相印证）；旧交接保留历史时点 | `test -f deliverables/research/platform-completion-20261016/EVIDENCE_MATRIX.csv` |

---

## 4. 矛盾清单

**判定标准：** ①文档自述"已满足/已完成"但对应证据文件不存在；②自述路径指向不存在文件；③同一事实在两份文档中互相冲突且会影响完成判定。

**结论先行：本快照未发现"自述已满足但证据不存在"的硬矛盾。** 客观核验：

- `COMPLETION_REQUIREMENTS.md` 中 **21 条引用路径全部存在**（21/21，含 5 个外部文档、6 个证据文件、fixtures/vendor/scripts/templates/deliverables 各若干）。
- 15 个新增证据目录内 Markdown 的 **29 条相对链接 0 断链**。
- CSV 中 **115 条证据路径全部存在**（见 §5 校验记录）。
- 倾向为**保守低报**而非虚假完成：多处"当前情况"栏写的仍是上一时点状态（工具未运行），而证据已显示工具实际运行。

以下 4 条为需由主控在最终复核时处理的矛盾/不一致：

| 编号 | 级别 | 冲突内容 | 证据 | 影响与建议 |
|---|---|---|---|---|
| **C-01** | 高（状态滞后，影响汇总入口） | `docs/evidence/platform-matrix-20261016/RESULT.md`（01:29 快照，**已提交**，自述"本轮汇总入口…每路完成立即记录一行"）M4 行写"Binsec 与统计未运行"、M5 行写"秘密标记工具未运行/不能报告阴性"、M3 行写"Pin/Microwalk 与统计未运行" | 矩阵 L14–L16 vs `m4-completion-20261016/formal-v1/*/stdout.txt`（Binsec 实跑 insecure/secure）、`m5-completion-20261016/software-dynamic-evidence.tar.gz`（三模式 0/0）、`m3-completion-20261016/native-8b6f2d91/on-secret.memcheck.log`（1280/2） | 该矩阵为指定汇总入口，若原样进入最终材料会**低报**已执行的工具范围（方向保守，不是伪造）。建议主控在收口提交时同步 M2–M5 行状态与证据路径 |
| **C-02** | 中（历史时点陈述易被当作现状） | `m3-memaccess-20261016/NOTES.md` 末段"后续两步：主控先将本独立子目录纳入顶层 CMake/CTest…**本轮没有实现这两项**"；`m4-compare-20261016/{NOTES,RESULT}.md`"本轮未运行 Binsec" | 与 `cmake/PlatformM3.cmake` 已接入 `platform_m3` 目标、`m4-completion-20261016/formal-v1/` 已实跑 Binsec 冲突 | 两文件是各自回合的快照，"本轮"语义正确，但与现状并读会误判。建议在新 RESULT 中显式交叉引用，或在旧 NOTES 顶部加时点标注（不改原字节） |
| **C-03** | 低（基线时点不一致） | `partials/S01.md` L25"基线固定为 `main@ac46e62`；其他路后续新结果不会自动改成本轮已知事实"，而审计时 HEAD 已到 `47033dd`（审计期间还在推进） | `git log`：`ac46e62` → `dd060ae` → `44c209a` → `47033dd` | 非缺陷，但完成计数必须绑定快照时点。本文件已在文首声明快照时间与 HEAD，并声明最终复核由主控在写入停止后进行 |
| **C-04** | 低（入口描述不精确） | `m3-completion-20261016/RESULT.md`"复核入口"把"原生各 6/6"归到 `native-8b6f2d91/`，但该目录**没有独立 ctest 日志**；6/6 实际写在 `native-8b6f2d91/build-{ordinary,sanitize}.log` 内 | `find docs/evidence/m3-completion-20261016/native-8b6f2d91 -name '*ctest*'` 为空；`grep '100% tests passed' native-8b6f2d91/build-ordinary.log` 命中 `out of 6` | 可核对性未受损（日志确实存在且含 6/6 与 `platform_m3_full_output_equivalence`），但复核者按文件名找会扑空。建议 RESULT 指明"6/6 见 build-*.log 末尾" |

> 说明：`m3-memaccess-20261016/NATIVE_BUILD_OPTIONS.txt` 与 `m3-completion-20261016/` 下同名文件的差异（§3.5 D05 脚注）属**本审计的路径纠正**，不计为被审计文档的矛盾——D05 未引用该文件，是审计表初稿的候选路径，已按实际存在路径修正。

---

## 5. 审计方法与可复现校验

完整方法与逐条命令见 [`partials/S09.md`](partials/S09.md)。摘要：

1. **口径复算**：按原文表格逐行提取 ID，得到 41 行（G 9 + A 4 + B 7 + C 5 + D 6 + E 6 + F 4），并与 `S01.md` 自述"32 阶段项 + 9 贯穿门槛、27 必做 + 2 条件 + 3 可选"交叉核对一致。
2. **路径存在性**：对 `COMPLETION_REQUIREMENTS.md` 全部 21 条引用路径逐一 `test -f`；对 CSV 115 条证据路径用脚本 `os.path.exists` 复验；对 15 个证据目录内 29 条 Markdown 相对链接做断链扫描。结果：**0 缺失、0 断链**。
3. **内容级核验**（不只验文件存在，还验数值/结论）：varlat `1280 errors from 3 contexts` 对 `0 errors`；M3 Memcheck `1280/2`、`0/0`、defined 双向 `0/0`；M4 Valgrind `32/1` 对 `0/0`；Binsec `insecure`（`0x8049047`）对 `secure`；M5 tar 内三模式 `0/0` 与 `exit 0`；M2/M3/M4/M5 各配置 CTest 计数（7/7、6/6、7 tests）；M1 锁频 `boost=0 / performance / 4300000 / restore_match=yes`；六库 HEAD 与 `REPOS.md` 逐一相等。
4. **反向核验（缺口定位）**：对 M2/M3/M4/M5 四个证据目录执行 `find -name '*.csv'`，结果**四者皆空**——这是 B05/C03/D04/E04 判为"未执行"的直接依据，也是 G06 判为"部分"的依据。
5. **提交状态核验**：`git ls-files docs/evidence/<dir> | wc -l` 逐目录统计，六个新目录为 0；`git diff --stat ac46e62 HEAD -- sources vendor` 为空；HEAD/作者/分支已记录。

**快照摘要（sha256 前 16 位，供最终复核比对是否被后续写入改变）：**

| 文件 | sha256(16) |
|---|---|
| `docs/platform/COMPLETION_REQUIREMENTS.md` | `31cac9c7b848585c` |
| `docs/evidence/platform-matrix-20261016/RESULT.md` | `33392e533922e4d1` |
| `docs/evidence/m2-kem-20261016/RESULT.md` | `7638266a90fde2ef` |
| `docs/evidence/m2-kem-20261016/STATISTICAL_PLAN.md` | `11e5d53cec36d833` |
| `docs/evidence/m3-completion-20261016/RESULT.md` | `50a21f5d257b4a6e` |
| `docs/evidence/m3-completion-20261016/STATISTICAL_PLAN.md` | `74f88d2a74b17642` |
| `docs/evidence/m4-completion-20261016/RESULT.md` | `7c4260f6351ddaa7` |
| `docs/evidence/m4-completion-20261016/formal-v1/{vulnerable,ct}-1-16/status.txt` | `2cb8929f3fa2d061`（两份相同） |
| `docs/evidence/m5-completion-20261016/RESULT.md` | `64df3dfe1f79c950` |
| `docs/evidence/m5-mlkem-native-20261016/RESULT.md` | `ce9dd487b5e5256c` |
| `docs/evidence/mona-wire-20261016/RESULT.md` | `756a996d398880d8` |
| `docs/evidence/platform-report-20261016/RESULT.md` | `00f0ede34da2caca` |
| `docs/evidence/r02-r04-close-20261016/RESULT.md` | `2056fbf434dfb1df` |
| `docs/evidence/r02-r04-close-20261016/raw/cpu-6/lock.txt` | `6171186140f007a4` |
| `docs/evidence/r02-r04-close-20261016/raw/cpu-6/status.txt` | `ae6d921267866fe9` |

---

## 6. 关键未满足项（Top 5，按阻塞面排序）

| 排序 | ID | 阻塞内容 | 为什么它是关键 | 解除条件 |
|---|---|---|---|---|
| 1 | **B05**（必做，未执行） | M2 未修/已修完整解封装的锁频采集与 CI/Welch+Holm、RTLF、原生在线 dudect | 它是 M2 从"定位阳性"走到"统计结论"的唯一路径；同时阻塞 B06 触发条件、F01 的 M2 对照列、F02/F03 的实测数据 | 先提交冻结 `STATISTICAL_PLAN.md`（B04/G03）→ 控制器真实 root 空任务资格重跑通过（G05）→ 单任务锁频采数并保存 raw/ENV/恢复记录 |
| 2 | **C03**（必做，未执行） | M5 与 M1 同规程/主类对的锁频原值、CI/Holm、RTLF、原生在线 dudect | M5 是"阴性对照"，没有统计就无法给出阴性验收；当前只有有限标记 0 无命中，绝不是阴性证明 | 与 B05 同一锁频窗口调度；online dudect 采集入口已构建并通过自检，待冻结后执行 |
| 3 | **D04**（必做，未执行） | M3 开/关同类输入的锁频统计电池与复测 | 人工校准若无统计层，D03 的"无 Pin 降级"链无法闭合（降级要求保留人工夹具统计）；且不能用两版总成本差替代 | 冻结 M3 类对与预算后串行采数；同时补齐 D05 的 raw/家族 |
| 4 | **E04**（必做，未执行） | M4 端到端调用边界的两类输入采数与统计电池、复测 | M4 的形式化（E03）与定位（E02）已完成，唯独统计层空白，E05 的"总表结论"因此只能写部分 | 冻结 `STATISTICAL_PLAN_DRAFT.md` → 执行 `--collect` 与在线 dudect → CI/Holm/RTLF |
| 5 | **B04 + G03**（必做，部分） | 四份新时序 PLAN 未提交冻结（`tracked=0`），与 G09 六个新证据目录未提交同源 | 它是上述 4 项的共同前置：原文明确"先提交再启动"，跳过则后续所有采数结果都无法与冻结合同对账 | 主控先本地提交 PLAN 与现有证据目录，再按冻结 hash 启动唯一锁频任务；同时完成 G09/F04 的模块提交与最终交接 |

**完整完成判定（对齐原文 §10）：** 截至快照时点，原文 §10 列举的完成条件中 —— B03 已具备、**B04 未冻结提交、B05 未执行**；C02 已具备、**C03 未执行**、C04 部分；D01 挂载已具备、D03 降级证据完整但统计未闭合、**D04 未执行**、D05 部分；E03 已具备、**E04 未执行**、E05 部分；**F01–F04 均为部分**。因此**本快照不构成完整完成**，也不自动替代比赛方材料审核、本人签署或官方验收。

---

*本文件由只读审计路 S09 生成；不修改任何被审计产物。最终判定以主控在全部写入停止后的复核为准。*
