# 多泄漏模块平台完整完成条件 —— 最终复核审计（FINAL_AUDIT，第 4 版）

**审计快照（第 4 次复核）：** 快照 `git rev-parse HEAD` = `dc6522c200cb8b0880d3d930987d8357629f4c28`（短 `dc6522c`，"docs: 把 R03 的实测数字补进 R05 排查表的族外对照一节"）；审计时刻 2026-10-16T03:27–03:50（Asia/Shanghai）。
**工作区状态（本版与前几版的关键差别）：** 本次审计的对象是 **`dc6522c` 提交 + 该提交之上尚未提交的本轮工作区改动**（R03/R05 并入报告、final4 匿名包、本审计第四版本身）。默认按仓库约定由主控统一提交，因此本版的"已满足"判定同时绑定**提交身份**与**工作区文件字节**：CSV 的 `evidence_path` 与 `verify_command` 对工作区文件逐一实跑通过，但**工作区尚未 commit**。这不是缺陷，是时点声明；主控提交后应以新快照复核一次。
**提交进展：** `git log --oneline 44c209a..HEAD | wc -l` = **38** 个提交（第 3 版为 31）；相对 `origin/main`（`c849c0f`，"docs: close the final completion audit at 100% of mandatory rows"）**领先 6 个提交且未被 push**，`origin/main` 是 HEAD 的祖先（无分叉）。
**本次复核范围：** 上一版（快照 `0d9876b`，本文件已经以 `c849c0f` 提交）之后仓库新增 6 个提交（R05 排查表、R03 计划/采集件/结果/数字回填、M2 取证树符号链接修复）；本轮把 R03 与 R05 两块证据并进正式报告、重出 PDF 与匿名包 `final4-20261016`、并把 M4 的统计引用改为只引用分臂数值。本次逐条复核 **41 行原文条目 + 2 行新增补充条目（S01/S02）**，并重跑全部 `verify_command`。
**被审计文档：** `docs/platform/COMPLETION_REQUIREMENTS.md`（sha256 前 16 位 `31cac9c7b848585c`，与前三版一致，未变更；文档自述基线 `main@ac46e62`）
**审计性质：** 只读。未改 `COMPLETION_REQUIREMENTS.md`、未改任何被审计证据文件、未 `git add/commit/push`（本轮新增的报告/包/审计文件由主控统一提交）。

> **三次历史快照的结论在此（均原字节保留）：**
> - **快照 `47033dd`（第 1 版，02:08）：** 全量 41 行 已满足 18 / 部分 15 / 未执行 4 / 条件未触发 1 / 可选未做 3；口径 B（32 项）14 / 10 / 4 / 1 / 3；5 个关键未满足项（B05/C03/D04/E04 未执行 + B04/G03 未冻结提交）。原文见 [`FINAL_AUDIT-47033dd.md`](FINAL_AUDIT-47033dd.md)、[`FINAL_AUDIT-47033dd.csv`](FINAL_AUDIT-47033dd.csv)。
> - **快照 `a30d7c7`（第 2 版，02:49）：** 全量 41 行 已满足 37 / 部分 1（F04） / 未执行 0 / 条件未触发 0 / 可选未做 3；口径 B（32 项）28 / 1 / 0 / 0 / 3；唯一缺口为 F04"最终交接"。原文见 [`FINAL_AUDIT-a30d7c7.md`](FINAL_AUDIT-a30d7c7.md)、[`FINAL_AUDIT-a30d7c7.csv`](FINAL_AUDIT-a30d7c7.csv)。
> - **快照 `0d9876b`（第 3 版，02:57）：** 全量 41 行 已满足 38 / 部分 0 / 未执行 0 / 条件未触发 0 / 可选未做 3；口径 B（32 项）29 / 0 / 0 / 0 / 3；F04 由 `0d9876b` 补齐，C-05…C-10 六条闭合，C-02/C-03/C-04 仍未闭。原文见 [`FINAL_AUDIT-0d9876b.md`](FINAL_AUDIT-0d9876b.md)、[`FINAL_AUDIT-0d9876b.csv`](FINAL_AUDIT-0d9876b.csv)（该版随后以 `c849c0f` 原字节提交入 main）。第 3 版文件 sha256 `1e02e10ec96a79b3…`（md）/`b694480216ff6f8f…`（csv）。
> - 四个版本的逐行差异见 §7。

> **口径纪律（严格遵守原文第 1 节）：** 未运行 ≠ 未检出；软件就绪 ≠ 工具已执行；clone 成功 ≠ 运行成功；前置完成 ≠ 模块完成；人工夹具不得计为上游 CVE；M5 阴性不写成恒时证明；M2 定位阳性不写成端到端阳性；族外对照（R03 的格式破损/截断、RTLF、dudect）不进 Holm，也不反过来推翻家族判定；R05 的"不存在/"不适用"只收窄到固定源码、固定编译器与固定产物，不是物理恒时。本版所有"已满足"均有实际产物 + 可跑命令 + 数值级核对；所有"未检出/无命中"均未被升级为"恒时"或"总体阴性"；**"必做项全部满足"不等于竞赛验收完成**——材料审核、本人签署与官方验收仍须人工完成。

---

## 1. 口径推导（两种口径都算，不删行、不改判定）

### 1.1 原文逐行 ID 清单

| 段 | ID 范围 | 行数 | 原文位置 |
|---|---|---:|---|
| 贯穿门槛 G | G01–G09 | 9 | §2 表格（L27–L35） |
| Phase A | A01–A04 | 4 | §3 表格（L45–L48） |
| Phase B | B01–B07 | 7 | §4 表格（L57–L63） |
| Phase C | C01–C05 | 5 | §5 表格（L73–L77） |
| Phase D | D01–D06 | 6 | §6 表格（L83–L88） |
| Phase E | E01–E06 | 6 | §7 表格（L94–L99） |
| Phase F | F01–F04 | 4 | §8 表格（L108–L111） |
| **合计** | G01–G09 + A01–F04 | **41** | 40 条表格行 + 1 条 G01 |

类型：必做 **36**（含 B03"必做前置"与 D03"条件优先，可降级"在计数上归入必做/条件项两类，见 §2 交叉表）、条件项 **2**（B06、D03）、可选 **3**（C05、D06、E06）。36+2+3 = 41。

### 1.2 用户口径"32 项" = A–F 阶段项

A(4)+B(7)+C(5)+D(6)+E(6)+F(4) = **32**；G01–G09 是原文 §2 的"贯穿所有阶段的门槛"，不属于任何 Phase。32 内：必做 27、条件项 2、可选 3；另加 9 条贯穿门槛 = 41 行全量。
该推导与 `partials/S01.md` L16 自述"共32条阶段项：27条必做、2条条件项、3条可选项；另有9条贯穿门槛"逐字一致。
**反例（已检验并否决）：** 把"排除可选与未触发条件项后的必做子集"当作 32 —— 按原文实为 36，与 32 不符；另有划法 41−3可选−2条件−4"Phase A 已满足"= 32，但原文无此排除依据。

### 1.3 两个口径的完成计数（本版快照 `dc6522c` + 本轮工作区改动）

| 口径 | 分母 | 已满足 | 部分 | 未执行 | 条件未触发 | 可选未做 | 必做子集完成率 |
|---|---:|---:|---:|---:|---:|---:|---:|
| **口径 A：原文全量 41 行** | 41 | **38** | **0** | 0 | 0 | **3** | 必做 36 中 36 已满足（**100%**） |
| **口径 A′：41 行 + 本轮 2 行补充（S01/S02）** | 43 | **40** | **0** | 0 | 0 | **3** | 必做 38 中 38 已满足（**100%**） |
| **口径 B：用户"32 项"（A–F 阶段项）** | 32 | **29** | **0** | 0 | 0 | **3** | 必做 27 中 27 已满足（**100%**） |
| **口径 B′：32 项 + 本轮 2 行补充** | 34 | **31** | **0** | 0 | 0 | **3** | 必做 29 中 29 已满足（**100%**） |

> **本版新增两行的性质与计数位置：** S01（R03 格式破损/截断族外对照）与 S02（R05 全流程六类来源排查表 90 格）**不属于原文 §2–§8 的 ID 清单**，因此口径 A（41）与口径 B（32）的分母**保持不变**，仍为 38/3 与 29/3；把两行并入后的合计口径 A′/B′ 为 40/3 与 31/3。两种读法都写出来，避免"改了分母"或"改了判定"的歧义。两行的逐条内容见 §3.8，机器可读行见 `FINAL_AUDIT.csv` 的 `S01`/`S02`。

> 两个口径的"已满足"均不含 3 项可选项（C05 第二阴性、D06 真实历史访存例、E06 Binsec 扩大范围）；条件项 B06 与 D03 均已按最强分支满足（B06 触发后实际执行、D03 实际运行 Microwalk）。**"必做 100%"只针对原文 §2–§8 的软件/实验交付条件**，不含 §10 明确排除的竞赛方材料审核、本人签署与官方验收。

---

## 2. 汇总计数表

### 2.1 类型 × 状态 交叉表（自洽校验）

| 类型 | 已满足 | 部分 | 未执行 | 条件未触发 | 可选未做 | 小计 |
|---|---:|---:|---:|---:|---:|---:|
| 必做（含 B03 必做前置、B06/D03 之外） | 36 | 0 | 0 | 0 | 0 | **36** |
| 条件项（B06、D03） | 2 | 0 | 0 | 0 | 0 | **2** |
| 可选（C05、D06、E06） | 0 | 0 | 0 | 0 | 3 | **3** |
| **原文小计** | **38** | **0** | **0** | **0** | **3** | **41** |
| 必做（本轮补充 S01/S02） | 2 | 0 | 0 | 0 | 0 | **2** |
| **合计（含补充）** | **40** | **0** | **0** | **0** | **3** | **43** |

- 条件项 B06 的触发条件（端到端家族不拒绝）**已成立并已执行**，故不再记"条件未触发"；D03 的"有 Pin 时运行 Microwalk"分支**已实际达成**（源码自建 Microwalk + Pin 3.28），故不再记"降级"。
- 43 行 × 8 列机器可读版本见 [FINAL_AUDIT.csv](FINAL_AUDIT.csv)（本轮脚本校验：**43 数据行、8 列、148 条可解析引用路径全部存在、0 缺失**（另有 10 条是描述性文本而非路径，按脚本规则跳过）；**43 条 `verify_command` 中 40 条可执行的全部实跑返回 0**，其余 3 条是 `—`（可选项未做））。
- **本版与上一版在 41 行上的判定完全相同**（38/0/0/0/3）：本轮没有把任何"可选未做"改判，也没有新增未满足项；R03/R05 两块证据以**新增补充行**登记，而不是改写原有 ID。

### 2.2 分 Phase 计数

| 段 | 行数 | 已满足 | 部分 | 可选未做 |
|---|---:|---:|---:|---:|
| G 贯穿门槛 | 9 | 9 | 0 | 0 |
| A 平台骨架 | 4 | 4 | 0 | 0 |
| B M2 KyberSlash | 7 | 7（含 B06 条件项已执行） | 0 | 0 |
| C M5 阴性对照 | 5 | 4 | 0 | 1（C05） |
| D M3 秘密访存 | 6 | 5（含 D03 条件项已达标） | 0 | 1（D06） |
| E M4 比较/有界验证 | 6 | 5 | 0 | 1（E06） |
| F Mona/报告/平台图 | 4 | 4（F02 报告刷新到 final4 33 页；F04 由 `0d9876b` 补齐完成交接、本轮随 final4 再次同步入口） | 0 | 0 |
| **S 本轮补充（原文 ID 清单之外）** | **2** | **2（S01 R03 族外对照、S02 R05 90 格排查表）** | 0 | 0 |

---

## 3. 逐项审计矩阵（原文 41 行 + 本轮补充 2 行）

**图例：** 证据路径均为**本次实际 `test -f`/`ls`/解包核对**通过的仓库相对路径（CSV 中 148 条可解析路径由脚本 `os.path.exists` 复验，0 缺失）。`核对命令` 在仓库根 `/Users/yin/code/cryProject` 可直接执行；完整命令见 `FINAL_AUDIT.csv` 的 `verify_command` 列。

### 3.1 G 贯穿门槛（9 行，全部已满足）

| ID | 类型 | 要求产物 | 证据路径（已验证） | 状态 | 说明 / 剩余缺口 | 核对命令 |
|---|---|---|---|---|---|---|
| G01 | 必做 | 各 RESULT 三句结论、运行入口及原日志；真实案例与人工校准分列 | 五模块 `RESULT.md`；`deliverables/research/multi-leakage-platform-20261016/report.md` §4 | 已满足 | 三句齐全且新增"本轮锁频端到端"小节；报告第 4 章为"检测—定位—修复—复测"四段链；无 exploit/密钥恢复 | `grep -l 密钥恢复 docs/evidence/*-20261016/RESULT.md` |
| G02 | 必做 | M1 vendor 与已有结论只读，sources 只读 | `git diff ac46e62..a30d7c7 -- sources vendor` 为空；`git status --porcelain sources/` 为空 | 已满足 | 29 个新提交均未触碰 sources/vendor | `git diff --stat ac46e62 HEAD -- sources vendor` |
| G03 | 必做 | 采数前冻结并提交 PLAN | `platform-collection-20261016/README.md` §1.0；`platform-collection-20261016/M2/m2-s1-unfixed/controller/command.json` | 已满足 | 四份 PLAN 由 `efca8a1` 一次冻结；本次用 `git cat-file blob efca8a1:<path> \| shasum -a 256` **独立复算四个摘要**，与 README 表及控制器 `plan_sha256` 逐字一致；冻结尾后的文档修订不改类对/预算/Holm 家族/α/停止规则 | `git cat-file blob efca8a1:docs/evidence/m2-kem-20261016/PLAN.md \| shasum -a 256` |
| G04 | 必做 | 计时输入与目标功能成立；KAT/边界/等价；普通与 sanitizer 分开 | `final-verification/ctest-platform-on.log`（87/87）、`ctest-ordinary-clean.log`（57/57）、`ctest-sanitize.log`（57/57）；各模块资格日志；`tests/vectors/kyber768_round3/SHA256SUMS` | 已满足 | 平台开 87/87 + 普通/ASan 各 57/57；M2 两版各 100 例公开 round3 KAT；M3 6/6 含三版完整输出等价；M4 7/7；M5 reference 5/5 | `grep -E 'tests passed' docs/evidence/platform-collection-20261016/final-verification/ctest-platform-on.log` |
| G05 | 必做 | 唯一锁频任务，退出恢复 | `platform-collection-20261016/status.log`；`README.md` §1.0/§2；`platform-control-qualification-20261016/QUALIFICATION.md`；各 run 的 `entry-snapshot.txt`/`exit-snapshot.txt`/`controller/*.json` | 已满足 | boost=0、governor/EPP=performance、min=max=4300000、taskset -c2/-c6 由控制器逐写 intent/visible 记录；**54 次正式运行 controller_exit=0 且 restore_match=yes**、20/20 放行探针在 ±2% 带内；本次复核 entry 与 exit 快照逐字相同；五条空任务资格全过（三次失败原件保留） | `grep -c '^run=.*controller_exit=0' docs/evidence/platform-collection-20261016/status.log` |
| G06 | 必做 | 原始计时可追溯 | `platform-collection-20261016/M2/m2-s1-unfixed/unfixed-main.csv.gz` + `.meta`；`stats/members/members.csv.gz`；四模块 `ENV.md` | 已满足 | 各 run 的 measure CSV 以 gzip 保存并配 `.meta`（seed/时钟/单位/乱序/预热/窗口/输入摘要/ELF 摘要）；42 个数据集各有 `input.sha256`；**已知限制**：M3 在线 dudect 该版本不产逐样本 CSV（已在 M3 RESULT 登记，原始 stdout 保留） | `find docs/evidence/platform-collection-20261016/M{2,3,4,5} -name '*.csv.gz' \| wc -l` |
| G07 | 必做 | 参数族与交叉工具分开 | `stats/members/members.csv.gz`；`stats/holm/{holm_summary.json,RESULT.md}`；`platform-rtlf-20261016/RTLF_RESULT.md`（42/42） | 已满足 | 四族 m/α 明确（M2 6、M5 3、M3 6、M4 6；α 全族 0.05），Holm + 固定效应合并逐族出表；RTLF α=0.01 与 dudect 族外，最大 t 未转伪 p；RTLF 42/42 逐数据集留原件 | `head -3 docs/evidence/platform-collection-20261016/stats/holm/RESULT.md` |
| G08 | 必做 | 远端 Cry 唯一物理边界 | `m2-kem/native-qualification/boundary-and-process-review.json`；`m3-completion/LOCATE_RESULT.md`；`m4-completion/runtime/runtime-logs/path-audit.json`；`mona-wire/native-v2/{path-audit.txt,failed/out-of-bound-tmp/README.txt}` | 已满足 | 各新根越界 0；两处越界事件有记录：Mona `/tmp` HotSpot 目录已搬回 `failed/out-of-bound-tmp/`（README 记来源/mtime/前后条目数/处理）；M2 采集树变量缺陷致 worker 路径越界，原件在远端 `harness-bug-archive/` 并在采集 README §2 描述。遗留观察见 C-07/C-10 | `cat docs/evidence/mona-wire-20261016/native-v2/failed/out-of-bound-tmp/README.txt` |
| G09 | 必做 | main 本地提交、不 push；检查/format-check/身份 | `(git)` main（快照 `a30d7c7`，收尾 `2b8557e`）；`final-verification/format-check.log` | 已满足 | 快照时 `44c209a..a30d7c7` 29 个提交、审计末期追加 1 个（`2b8557e`，仅提交已读工作区内容）共 30 个，作者与提交者全部为 `Gowin-liuyin`；新增证据目录全部已跟踪（m2-kem 1983、collection 2402、m3 388、m4 172、mona 655、m5 5、report 175、rtlf 181、qualification 161、matrix 19）；相对 `origin/main` 领先 43+ 个提交即未 push；format-check 实际构建通过 | `git log 44c209a..HEAD --format='%an' \| sort -u; git rev-list --count origin/main..HEAD` |

### 3.2 Phase A 平台骨架（4 行，全部已满足）

| ID | 类型 | 要求产物 | 证据路径 | 状态 | 说明 / 剩余缺口 | 核对命令 |
|---|---|---|---|---|---|---|
| A01 | 必做 | 计划与架构可引用 | `docs/platform/ARCHITECTURE.md`；`docs/多泄漏模块平台工程计划-20261016.md` | 已满足 | 接口有变时同步，不改旧执行源 | `test -f docs/platform/ARCHITECTURE.md` |
| A02 | 必做 | 六工具 clone、完整 commit/tree、许可 | `third_party/REPOS.md`；六个仓库目录 | 已满足 | 本次复核六个 HEAD 与 REPOS.md 逐一相等；clone 成功不等于运行成功——Mona/Binsec/Microwalk/RTLF/dudect 均已有真实运行证据 | `for r in RTLF dudect ctgrind mona-timing-lib mona-timing-report Microwalk; do git -C third_party/$r rev-parse HEAD; done` |
| A03 | 必做 | 两类 CSV 统一入口输出 CI/Welch、RTLF、dudect 摘要 | `scripts/platform_stats/README.md`；`stats/holm/RESULT.md`；`platform-stats-holm-20261016/README.md` | 已满足 | 软件接口已实际用于 42 个真实数据集与四个 Holm 家族；离线回放与在线采集仍分列 | `test -f scripts/platform_stats/README.md` |
| A04 | 必做 | 模块模板与平台矩阵；三句及未知状态 | `templates/MODULE_RESULT.md`；`platform-matrix-20261016/RESULT.md` | 已满足 | 矩阵本轮已同步 M2–M5 实际统计与工具状态（上轮 C-01 矛盾**闭合**） | `grep -c 已采数 docs/evidence/platform-matrix-20261016/RESULT.md` |

### 3.3 Phase B M2 KyberSlash（7 行，全部已满足；B06 为条件项已执行）

| ID | 类型 | 要求产物 | 证据路径 | 状态 | 说明 / 剩余缺口 | 核对命令 |
|---|---|---|---|---|---|---|
| B01 | 必做 | 未修/已修源码、许可、PIN、div/idiv 对照 | `m2-kyberslash-20261016/VERSION_AUDIT.md`；`disasm/*.asm`（6 份） | 已满足 | 三热点未修各 1 个 div、已修 0 | `test -f docs/evidence/m2-kyberslash-20261016/VERSION_AUDIT.md` |
| B02 | 必做 | 20250805 补丁工具真实可用；报警/消失；Memcheck 对照 | `version-audit/varlat-unfixed.log`（1280/3）与 `varlat-fixed.log`（0/0）；`varlat-tool/*` | 已满足 | 热点层；换 ELF 须重绑工具与秘密范围 | `grep 'ERROR SUMMARY' docs/evidence/m2-kyberslash-20261016/version-audit/varlat-{unfixed,fixed}.log` |
| B03 | 必做前置 | 完整历史 Kyber768 解封装接入同一测量协议 + 资格 + 链接核验 | `m2-kem-20261016/COLLECTOR_CONTRACT.md`；`collector-v2-2e894561892a`；`native-qualification/{ctest-ordinary.log,ordinary-unfixed-measure.ldd}` | 已满足 | 接入/合同/资格成立，且同一采集件已实际用于 B05，不再前置悬空 | `grep -c '^Test Passed\.' docs/evidence/m2-kem-20261016/native-qualification/ctest-ordinary.log` |
| B04 | 必做 | 新 PLAN（类对/预算/α/停止/复测/家族）先提交再启动 | `m2-kem-20261016/PLAN.md`；`platform-collection-20261016/README.md` §1.0；`.../controller/command.json` | 已满足 | `efca8a1` 冻结严格早于采数；执行用 sha256 独立复算一致且控制器逐次校验；微基准触发条件亦事先固定 | `git cat-file blob efca8a1:docs/evidence/m2-kem-20261016/PLAN.md \| shasum -a 256` |
| B05 | 必做 | 完整解封装锁频采集 + CI/Welch+Holm + RTLF + 在线 dudect | `platform-collection-20261016/M2`（18 次运行）；`stats/holm/`；`RTLF_RESULT.md`；`m2-kem/RESULT.md` | 已满足 | 家族 m=6、**Holm 拒绝 0**、Δ=+4.58 ns CI[−3.08,+12.25]、I²=58.3%；族外 RTLF/dudect 齐备；**定位阳性 / 微基准未检出 / 端到端未检出三层分列**；dudect 阳性出现在已修臂，已明确不可归因于除法变体 | `grep -n 'Holm 拒绝' docs/evidence/m2-kem-20261016/RESULT.md` |
| B06 | 条件项 | 若完整调用不区分则补热点微基准并分层 | `m2-kem-20261016/microbench-0551254c9579/{RESULT.md,runs/,controller/}` | 已满足 | 触发条件成立并已执行**六个预注册运行**（全部 restore_match=yes、20/20 探针在带内）；微基准家族 m=6 拒绝 0、Δ=+0.044 ns CI[−0.430,+0.517]；与端到端词表不可比、p 值未合并 | `grep -n restore_match docs/evidence/m2-kem-20261016/microbench-0551254c9579/RESULT.md \| head -3` |
| B07 | 必做 | 新 M2 全套运行包 + 平台行与报告同步 | `m2-kem-20261016/`（REQUIREMENTS/PLAN/ENV/RESULT/COLLECTOR_CONTRACT/native-qualification/microbench）；`platform-matrix/RESULT.md`；`report.md` | 已满足 | 软件资格、原生定位、采数原件、微基准、Holm/RTLF/dudect、平台行与报告互相引用 | `ls docs/evidence/m2-kem-20261016/` |

### 3.4 Phase C M5 阴性对照（5 行：4 已满足 + C05 可选未做）

| ID | 类型 | 要求产物 | 证据路径 | 状态 | 说明 / 剩余缺口 | 核对命令 |
|---|---|---|---|---|---|---|
| C01 | 必做 | 固定 mlkem-native + reference/measure 链 + 资格 | `vendor/mlkem-native/PIN.md`；`m5-mlkem-native-20261016/{RESULT.md,measure-link.txt,snapshot-verification.json}` | 已满足 | 固定提交 b3ba7b3 共 126 文件核对；普通/动态各 5/5 | `test -f vendor/mlkem-native/PIN.md` |
| C02 | 必做 | x86_64 原生反汇编、秘密标记检查、varlat 已运行 | `m5-completion-20261016/RESULT.md`；`software-dynamic-evidence.tar.gz` | 已满足 | 本次**解包复核** `logs-v2/{system,varlat-no,varlat-yes}` 三模式 `ERROR SUMMARY: 0 errors from 0 contexts` 且 exit 0；有限标记无命中，不外推总体误报率 | `tar -xzOf docs/evidence/m5-completion-20261016/software-dynamic-evidence.tar.gz logs-v2/varlat-yes.valgrind.log \| grep 'ERROR SUMMARY'` |
| C03 | 必做 | 与 M1 同规程的锁频原值 + CI/Holm + RTLF + 在线 dudect | `platform-collection-20261016/M5`（6 次运行）；`m5-completion-20261016/RESULT.md`；`stats/holm/`；`RTLF_RESULT.md` | 已满足 | 家族 m=3、**Holm 拒绝 0**、Δ=−5.30 ns CI[−11.77,+1.16]、I²=0；族外 RTLF/dudect 同向未检出；原始 p=0.249/0.410/0.427 可与 `holm_summary.json` 对账 | `grep -n 'Holm 拒绝' docs/evidence/m5-completion-20261016/RESULT.md` |
| C04 | 必做 | 三句 RESULT 判断有限范围内阴性预期 | `m5-completion-20261016/RESULT.md`（L54–73 新增小节） | 已满足 | 三句已从"待执行"更新为真实统计；边界明写"未检出≠恒时、不给总体误报率为零" | `sed -n '54,73p' docs/evidence/m5-completion-20261016/RESULT.md` |
| C05 | 可选 | 修后 liboqs ref 第二阴性 | （无） | 可选未做 | 按原文不是必做前置，不阻止完整完成 | `—` |

### 3.5 Phase D M3 秘密访存校准（6 行：5 已满足 + D06 可选未做；D03 条件项已达标）

| ID | 类型 | 要求产物 | 证据路径 | 状态 | 说明 / 剩余缺口 | 核对命令 |
|---|---|---|---|---|---|---|
| D01 | 必做 | 人工 LUT 开/关夹具、等价与边界、挂载到解封装路径 | `docs/patches/m3-mem-lut-toggle.patch`；`m3-completion-20261016/{patch-apply.log,native-8b6f2d91/build-ordinary.log,LOCATE_RESULT.md}` | 已满足 | 6/6 含 `platform_m3_full_output_equivalence`；人工构造性质在 RESULT/矩阵/报告三处标注，**不计为上游 CVE** | `grep -n full_output_equivalence docs/evidence/m3-completion-20261016/native-8b6f2d91/build-ordinary.log` |
| D02 | 必做 | ctgrind/Memcheck 秘密下标定位，开/关实际日志 | `native-8b6f2d91/{on,off}-secret.memcheck.log`（1280/2 对 0/0）；`LOCATE_RESULT.md`（新根四组合重验） | 已满足 | 新根重新构建后重验，未复用旧产物；旧 32/1 与新 1280/2 分列 | `grep 'ERROR SUMMARY' docs/evidence/m3-completion-20261016/native-8b6f2d91/{on,off}-secret.memcheck.log` |
| D03 | 条件优先，可降级 | 有 Pin 时运行 Microwalk；否则降级 | `LOCATE_RESULT.md`；`locate-v2/remote/microwalk-probe/pin/pin-3.28.sha256`；`.../work3-on/.../results-memory/mutual-information.txt` | 已满足 | **条件项最强分支达成**：Microwalk 源码自建 + Pin 3.28（sha256 固定）真实运行；开臂 `poly_frommsg+30/+59` MI=**1.922 bits**（全场最高）、关臂同函数 0.722 bits，与 ctgrind 报点同源；官方镜像因 Docker data-root 越 Cry 边界未用（如实登记） | `head -2 docs/evidence/m3-completion-20261016/locate-v2/remote/microwalk-probe/m3mw/work3-on/persist/target-m3-on/results-memory/mutual-information.txt` |
| D04 | 必做 | 冻结类对后开/关锁频统计电池与复测 | `platform-collection-20261016/M3`（12 次运行）；`m3-completion-20261016/RESULT.md`；`stats/holm/` | 已满足 | 家族 m=6、**Holm 拒绝 0**、Δ=−0.73 ns CI[−5.56,+4.10]；跨臂 on/off 因含二进制级常数偏移明确不进 Holm；不得用两版总成本差冒充泄漏 | `grep -n 'Holm 拒绝' docs/evidence/m3-completion-20261016/RESULT.md` |
| D05 | 必做 | 新结果包与总表、平台行；人工校准独立于真实案例 | `m3-completion-20261016/{RESULT.md,LOCATE_RESULT.md,ENV.md}`；`platform-matrix/RESULT.md` | 已满足 | 定位重验、采数原件、家族、平台行与报告同步；不计为第三个上游 CVE | `sed -n '50,60p' docs/evidence/m3-completion-20261016/RESULT.md` |
| D06 | 可选 | 真实历史访存例 | （无） | 可选未做 | 不作为人工校准完成条件 | `—` |

### 3.6 Phase E M4 比较/拒绝校准与有界验证（6 行：5 已满足 + E06 可选未做）

| ID | 类型 | 要求产物 | 证据路径 | 状态 | 说明 / 剩余缺口 | 核对命令 |
|---|---|---|---|---|---|---|
| E01 | 必做 | 人工提前退出与恒时意图比较；等价、边界与产物 | `fixtures/early_reject_memcmp/README.md`；`m4-compare-20261016/ctest-{ordinary,sanitize}.log`（4/4）；`m4-completion-20261016/.../software-logs-v2/ctest.txt`（7/7） | 已满足 | 相等性自检（长度 0–32、全部差异位置/字节对标准 memcmp）与 32 字节封装边界均有通过日志；未挂载 KEM，故不触发挂载后复验条件 | `grep -n self_test docs/evidence/m4-compare-20261016/ctest-ordinary.log` |
| E02 | 必做 | Memcheck 定位非恒时比较 + 关版对照 + 源码/ELF/日志关联 | `m4-compare-20261016/linux-run-250f424b/valgrind-{vulnerable,ct}.log`（32/1 对 0/0）；`m4-completion-20261016/.../formal-vulnerable-disasm.txt` | 已满足 | 新入口/产物重建后重新核验，源码行、ELF 地址、日志三者关联 | `grep 'ERROR SUMMARY' docs/evidence/m4-compare-20261016/linux-run-250f424b/valgrind-{vulnerable,ct}.log` |
| E03 | 必做 | Binsec 对抽取内核实际执行 + 入口/模型/bound/退出/原日志 | `m4-completion-20261016/FORMAL_RESULT.md`；`formal-v2/`；`formal-v1/{vulnerable,ct}-1-16/stdout.txt` | 已满足 | formal-v2 在新根重装工具并**重跑四次**（vulnerable 两次 insecure、ct 两次有界 secure，含固定长度 16 补运行），pending/cut/discontinued/unknown 全 0；另用 `-sse-depth 5` 截断对照得 unknown，证明退出码 0 不能单独判 secure | `grep -E 'Program status' docs/evidence/m4-completion-20261016/formal-v1/{vulnerable,ct}-1-16/stdout.txt` |
| E04 | 必做 | 端到端边界与两类输入，冻结后采数 + 统计电池 + 复测 | `platform-collection-20261016/M4`（18 次运行）；`m4-completion-20261016/RESULT.md`；`stats/holm/` | 已满足 | 家族 m=6、**Holm 拒绝 3 项且全部在 vulnerable 臂**（p=0/9.23e−25/3.14e−22），ct 臂三次均不拒绝；截断对照族外，RESULT 明写两者边界不同不可当同一界面的两个长度 | `grep -n 'Holm 拒绝' docs/evidence/m4-completion-20261016/RESULT.md` |
| E05 | 必做 | 新结果包与总表、报告的校准/有界结论 | `m4-completion-20261016/{RESULT.md,FORMAL_RESULT.md}`；`platform-matrix/RESULT.md`；`report.md` | 已满足 | 定位/形式化/统计三类分列不互相替代；人工夹具阳性明确不等于任何真实库存在同类缺陷 | `sed -n '38,64p' docs/evidence/m4-completion-20261016/RESULT.md` |
| E06 | 可选 | Binsec 扩大到完整解封装或真实 TLS/KEM 案例 | （无） | 可选未做 | 路径爆炸只限制扩大范围，不免除 E03 小边界实跑（已执行） | `—` |

### 3.7 Phase F Mona、报告与平台图（4 行，全部已满足）

| ID | 类型 | 要求产物 | 证据路径 | 状态 | 说明 / 剩余缺口 | 核对命令 |
|---|---|---|---|---|---|---|
| F01 | 必做 | Mona 对 M1 与 M2 主 CSV 的独立对照行 | `mona-wire-20261016/native-v2/run/m2/m2-mona.csv`；`.../run/m1/m1-mona.csv`；`mona-wire-20261016/RESULT.md` | 已满足 | M1 六份 + M2 六份各出对照行；M2 五份无验证分离、s3 已修臂一次末轮单子集（如实登记，不作受控误报率）；投影自检与多重集等价留证；`holm_member=false` 不入 Holm | `head -3 docs/evidence/mona-wire-20261016/native-v2/run/m2/m2-mona.csv` |
| F02 | 必做 | 新正式报告含四段链章，实测表/图与证据一一对应 | `deliverables/research/multi-leakage-platform-20261016/{report.pdf,report.tex,report.md,report-tables.json,index.html,r05-flowchart.png,r05_flowchart.py}`；`platform-report-20261016/{VISUAL_QA.md,final4-20261016/pdf-metadata-audit.json}` | 已满足 | 终版 **33 页**（本次以 `pages=33` 与 VISUAL_QA 逐页核验独立确认）、**15 章、11 张对照表、2 张图、31 份来源**；第 4 章为四段链状态；第 8/9 章为 R03/R05 补充；数据格无占位符。两遍 XeLaTeX（`xelatex-final4-{first,second}.log`）**0 Overfull / 0 Underfull / 0 缺字 / 0 hyperref 警告，均 exit 0**。**M4 已改为只引用分臂数值**：正文、表 T3/T5 与矩阵图统一为 vulnerable Δ −4.089 ns / ct Δ +0.055 ns，混臂合并 Δ 在 7 个报告产物中逐文件检索均为 0 次 | `grep -oE 'pages.: *[0-9]+' docs/evidence/platform-report-20261016/final4-20261016/pdf-metadata-audit.json; ! grep -qE '22 页|23 页' docs/evidence/platform-report-20261016/RESULT.md; ! grep -rq '3\.74' deliverables/research/multi-leakage-platform-20261016/report.md deliverables/research/multi-leakage-platform-20261016/report.tex deliverables/research/multi-leakage-platform-20261016/index.html` |
| F03 | 必做 | 平台矩阵图与可重建源，分三类与各层状态 | `deliverables/research/platform-completion-20261016/figures/{platform-evidence-matrix.svg,CAPTION.md,render_matrix.py}`；`EVIDENCE_MATRIX.csv` | 已满足 | 结果图（明写非计划图）已按新结果刷新，图注明每格证据路径；无 `«待主控数据»`，橙色仅表结构性未运行 | `grep -n 结果图 deliverables/research/platform-completion-20261016/README.md` |
| F04 | 必做 | deliverables 入口、进度、平台总表及**最终交接**同步；复算路径/边界可读 | `HANDOFF_DONE.md`（§2026-10-16 第二轮完成交接）；`deliverables/research/multi-leakage-platform-20261016/README.md`；`deliverables/research/platform-completion-20261016/{README.md,EVIDENCE_MATRIX.csv}`；`docs/full-work-progress.md`；`docs/evidence/platform-report-20261016/refresh-20261016/{REFRESH.md,zip-recompute-final4.log,run_zip_recompute_final4.sh}`；`docs/evidence/platform-report-20261016/final4-20261016/{package-verification.json,offline-reproduction.json}` | **已满足** | 入口/进度/平台总表/复算路径在 `0d9876b` 已同步（匿名 ZIP final3 **实包解出后 CTest 5/5**、23 页 PDF、离线 HTML、REFRESH 记录），本轮随 final4 再次同步：两份 deliverable README 改为 final4（**784 成员、122 个本地 HTML 链接、33 页**），REFRESH.md 新增"第五阶段"（含三处载体缺陷与一处流程偏离的如实记录），复算日志为 `zip-recompute-final4.log`（**5/5 通过、2.06 s**），审计产物在 `final4-20261016/`。`HANDOFF_DONE.md` 的"第二轮完成交接"整节仍是 `0d9876b` 时点的快照（其中"23 页报告 / final3"是当时的实际交付），本版**不就地改写该历史段落**，而是登记为 C-11 由主控在最终交接时统一刷新 | `grep -n '第二轮完成交接' HANDOFF_DONE.md; test -f deliverables/research/platform-completion-20261016/EVIDENCE_MATRIX.csv; test -f deliverables/support/CACR2026EA16XZ-multi-leakage-platform-20261016/CACR2026EA16XZ-platform-final4-20261016.zip; grep -c 'CTest 5/5' docs/evidence/platform-report-20261016/RESULT.md` |

---

### 3.8 本轮新增补充条目（2 行，原文 ID 清单之外，均为"已满足"）

> 这两行**不占用也不改写**原文 §2–§8 的 41 个 ID：它们记录的是本轮并入正式报告的两块证据。判定标准与原文条目一致——有产物、有可跑命令、有数值级核对（而不是只有文档描述）。

| ID | 类型 | 要求产物 | 证据路径（已验证） | 状态 | 说明 / 剩余缺口 | 核对命令 |
|---|---|---|---|---|---|---|
| S01 | 必做（补充） | R03 格式破损 / 截断输入族外对照：3 臂 × 3 种子、每类 10000 次、锁频单控制器、族外不进 Holm | `docs/evidence/r03-malformed-20261016/{PLAN.md,RESULT.md,logs/status.log}`（+ `R03/<run>/` 18 个运行目录）；报告侧 `deliverables/research/multi-leakage-platform-20261016/{report.tex,report-tables.json}`（第 8 章 + 表 T7/T8/T9 + 表 T5 四行） | **已满足** | 本次独立复核：`logs/status.log` 逐行 **18/18 `controller_exit=0` + `worker_exit_code=0` + `restore_match=yes`**，放行探针 20/20 `in_band=True`；`PLAN.md` 的 sha256 `79edb27f8339691f…` 与 `RESULT.md` 记录的 `--plan-sha256` 逐字一致；对照 A 的 9 个 Δ/CI/原始 p 与对照 B 的 9 行（含"下溢为 0"）逐项与 `RESULT.md` 表一致；族外 dudect 三臂九值一致。报告侧：Δ 全在 +9.8 ～ −3.2 ns、9/9 CI 含 0、9/9 原始 p ≥ 0.28（最大 0.9552）、截断 23.1–23.4 ns 与 Δ ≈ 29.3 µs / 55.1 µs 均逐字可核。**报告与 R05 表两处都写明：族外、不进 Holm、不改 `efca8a1`、截断差是公开长度检查的接口语义而不是泄漏、"未检出"不是恒时证明** | `grep -c 'restore_match=yes' docs/evidence/r03-malformed-20261016/logs/status.log; shasum -a 256 docs/evidence/r03-malformed-20261016/PLAN.md; grep -c 'R03 对照 A' deliverables/research/multi-leakage-platform-20261016/report.tex` |
| S02 | 必做（补充） | R05 解封装全流程六类来源排查表：3 实现（M1 未修/已修、M2 未修/已修、M5 参考）× 5 步骤 × 6 类 = **90 格**，逐格给结论/证据/修复点；流程图 mermaid 源码保留、PDF 用等价静态图 | `docs/R05-全流程排查表.md`；`deliverables/research/multi-leakage-platform-20261016/{r05-flowchart.png,r05-flowchart.svg,r05_flowchart.py,report.tex,index.html,report-tables.json}`（第 9 章 + 表 T10/T11 + 图 2） | **已满足** | 本次独立复核：该表 §4.1 汇总行为 `5 / 74 / 10 / 1 / 90`，与报告表 T10 逐字一致；5 个"存在"格与唯一"未检查"格（M2 重加密 × 提前返回）的**函数名 + 反汇编地址/行号 + 修复点（982c762、272125f）**同时出现在该表 §4.2/§4.3 与报告表 T11；M5 那处"存在"明确标注只携带公开信息、不可利用。**Binsec 只开 `control-flow,memory-access`、未开乘除法检查**的边界写进报告正文与 T11 表注。流程图：报告生成器**运行期**从该文件正则取出 mermaid 代码块 → `report.md` 原样内嵌、`index.html` 原样放进 `<pre>` 并内联等价 SVG、PDF 用 `r05-flowchart.png`（第 22 页）并在图注指向该文件 | `grep -c '| \*\*合计\*\* | \*\*5\*\* | \*\*74\*\* | \*\*10\*\* | \*\*1\*\* | \*\*90\*\* |' docs/R05-全流程排查表.md; grep -c 'R05 全流程排查表' deliverables/research/multi-leakage-platform-20261016/report.tex` |

**两行的共同边界（不因"已满足"而升级）：** S01 是人工构造输入的族外描述性对照，不是上游 CVE，不构成恒时证明，也不给总体误报率；S02 的 74 个"不存在"与 10 个"不适用"只覆盖该表固定的源码、编译器与产物，不覆盖任意输入/编译器/微架构，1 个"未检查"格如实保留未检查（不写成"不存在"）；两张表都**没有**把工具无报警、软件资格或定位结果写成统计结论。

---

## 4. 矛盾清单（本版：硬矛盾 0 条；需处理不一致 **1 条**——C-11（本轮新增，低）；C-01…C-10 共 **10 条已闭合**）

**硬矛盾判定（自述"已满足"但证据缺失 / 路径不存在）：0 条。** 客观核验（本版重跑）：
- `COMPLETION_REQUIREMENTS.md` 内可解析的相对引用路径 **20 条中 19 条**按文档相对路径直接命中；第 20 条写成裸名 `version-audit/fetch_vendor.sh`，其实际文件在 `docs/evidence/m2-kyberslash-20261016/version-audit/fetch_vendor.sh`（存在，`VERSION_AUDIT.md` 以完整路径引用它）——判定为**引用写法**问题而非缺失产物，**硬矛盾仍为 0**（这条与第 3 版的"21/21"提法不同，本版按可复现的提取规则重算并把差异写明）；
- CSV 中 **148 条可解析证据路径全部存在**（脚本复验，0 缺失）；
- 证据目录内 Markdown 相对链接 0 断链；
- CSV 的 **43 条 `verify_command` 全部实跑返回 0**（含本轮先复核并修好的 F02 命令：它原指 final3 的审计产物，本轮改指 final4）。

| 编号 | 状态 | 级别 | 内容与本次复核结论 |
|---|---|---|---|
| **C-01** | ✅ 已闭合（a30d7c7 轮） | — | `platform-matrix-20261016/RESULT.md` 的 M3/M4/M5 行落后于新证据。上版复核已同步（写明"已采数"、各族 Holm 拒绝数、合并 Δ 与 CI、I²、Microwalk MI、Binsec 有界结论与原件链接），并新增逐模块运行数表（M2 18/18、M5 6/6、M3 12/12、M4 18/18）。 |
| **C-02** | ✅ **已闭合（b637d0d）** | — | `m3-memaccess-20261016/NOTES.md` 末段"本轮没有实现这两项（顶层 CMake 接入 / 时序 PLAN）"与 `m4-compare-20261016/{NOTES,RESULT}.md`"Binsec 未运行，状态 `not_run`"曾是各自回合的快照。**本次复核：三个文件各追加了一个"状态更新（2026-10-16，主控）"块**（`grep -c` 逐文件 = 1），指明该描述只对当时成立、已被 `*-completion` 取代并给出指向链接，**原文一字未改**；`m3-memaccess/NOTES.md` 的 sha256 由 `f97b285b0cbd22a0` 变为 `88b3a31dba17a520`，正是这次追加。 |
| **C-03** | ✅ **已闭合（b637d0d）** | — | `partials/S01.md` 曾写"基线固定为 main@ac46e62"。**本次复核：该文件文首已加"基线更正（2026-10-16，主控）"块**，写明当时基线是 `ac46e62`、收尾轮基线是 `origin/main@c849c0f`、本轮再往后另有 R03/R05 收尾提交，并把正文两处"固定为 ac46e62"标注为**已过期**（原文未改写）。完成计数仍按本文件文首的四次快照声明绑定时点，本版另加 A′/B′ 两个合并口径。 |
| **C-04** | ✅ **已闭合（b637d0d）** | — | `m3-completion-20261016/RESULT.md` 曾把"原生各 6/6"归到 `native-8b6f2d91/`（该目录无独立 ctest 日志）。**本次复核：该行已加更正**（6/6 的原始行在本机 `build-{ordinary,sanitize}.log` 第 68–80 行，原生采数树的 6/6 见 `LOCATE_RESULT.md`），并新增 [`m3-completion-20261016/TESTS.md`](m3-completion-20261016/TESTS.md)（逐测试名 + 耗时 + 行号）；`m3-completion/RESULT.md` 的 sha256 由 `ee9be0e9446d4b1b` 变为 `7364a8116a54e349`，正是这次更正。 |
| **C-05** | ✅ **已闭合（0d9876b；本轮随 final4 复审）** | — | `platform-report-20261016/RESULT.md` 页数 22/23 自相矛盾，`0d9876b` 已统一为 23 页并标注权威来源。**本轮复审（页数因新增两章变为 33 页）**：`RESULT.md`、`VISUAL_QA.md`、报告 README、support README、`FINAL_AUDIT` 与 `final4-20261016/pdf-metadata-audit.json` 的 `pages` **六处同值 33**；`! grep -qE '22 页|23 页' RESULT.md` 返回 0。**新增一条同类护栏**：三处缺陷修复过程中 PDF 曾产出 32/33 页与两个不同 sha256，发布值以最后一次两遍编译为准，并在 REFRESH §I3 第 6 条写明"改完表格必须重跑生成器再编译、三处必须同值"。 |
| **C-06** | ✅ **已闭合（0d9876b）** | — | 采集 README 的家族成员表/输出名已改为 `members.csv.gz`、`members-descriptive.csv.gz`、`holm.csv.gz`、`pooled.csv.gz`，与 §3"所有 .csv 以 gzip 存放"一致；实际文件确为 `.csv.gz`。 |
| **C-07** | ✅ **已闭合（0d9876b）** | — | `docs/evidence/platform-boundary-cleanup-20261016/` **现已真实入库**：`README.txt`（来源、字节数、mtime、处置）、`ORIGINALS.tsv`（两行，含 sha256）、`remote-inputs.sha256`、`local-inputs.sha256` 与 `source-tmp-originals/` 两份副本 —— 记录的是 **RTLF 子任务**在 `/tmp` 写出的两个文件（第三处越界事件，Mona 处另存 `mona-wire/.../failed/out-of-bound-tmp/`）。**本次复核确认该路径存在且内容可核对。** 关于 M2 采集树变量那一处：原件保留在**远端 Cry 内**的 `harness-bug-archive/`，采集 README §2 有文字记录，未产生任何测量值——它本就在 Cry 物理边界内，故**本审计不要求必须拉回仓库**；如需最大可复现性可选择性拉回，不改变任何判定。 |
| **C-08** | ✅ **已闭合（0d9876b）** | — | 采集 README 新增 §7 第 1 条，明确 `.meta` 的 `cpu_affinity`/`frequency_control` 是**采集件静态字段**（采集件不设亲和性、不写频率），权威来源是控制器落盘的 `baseline.json`/`entry-probes.json`/`during.json`/`0020-restored.json`/`terminal.json` 与 README §1。与本次核对的字段内容一致。 |
| **C-09** | ✅ **已闭合（0d9876b）** | — | §1.0 措辞已改为"等于对 `git show efca8a1:<该路径>` 取出的 **blob 内容**再算一次 SHA-256"。四个摘要本身仍经本次独立复算（`git cat-file blob … \| shasum -a 256`）与控制器 `plan_sha256` 逐字一致。 |
| **C-10** | ✅ **已闭合（0d9876b；本轮升级为"已修"）** | — | 采集 README 新增 §7 第 2 条，登记拉回 M2 源码树的 5 个悬空符号链接与两处 `avx2/.gitignore` 的 git ELOOP 警告来自上游 kyber 快照、内容可读、无真实环、不在被测 ELF 链接路径上，并按"上游快照不改名、不修改"的约定**故意保留**。**本轮变化**：`dc6522c` 之前的提交 `b94e942` 已把 `avx2/.gitignore` 的符号链接换成普通文件（原字节内容保留），此后 `git status` 不再出现 ELOOP 类噪声；这条不改变任何测量与判定。 |
| **C-11** | 🆕 **本轮新增，未闭（低）** | 低 | `HANDOFF_DONE.md` 的"2026-10-16 第二轮完成交接（主控）"整节是 `0d9876b` 时点的快照，其中"23 页报告、匿名 ZIP `final3-20261016`"描述**当时**的实际交付；本轮交付已前进到 **33 页报告 + `final4-20261016`（784 成员）**。本审计**刻意不就地改写该历史段落**（与 C-02/C-03 同类：历史快照不是虚假声明），而是在 F04 行与 §5 明确登记。解除条件：主控在最终交接时补一节"第四轮交付刷新"（或明确以本审计第四版作为交接附件）。**在解除之前，凡引用交付载体请以 `deliverables/research/multi-leakage-platform-20261016/README.md`、`deliverables/support/CACR2026EA16XZ-multi-leakage-platform-20261016/README.md` 与本文件为准。** |

---

## 5. 仍未满足项与理由（本版）

| 项 | 状态 | 内容与理由 | 解除条件 |
|---|---|---|---|
| **F04** | ✅ **已满足（0d9876b；本轮随 final4 复审）** | 上版唯一必做缺口（"最终交接仍停启动轮"）已补齐：`HANDOFF_DONE.md` 新增"2026-10-16 第二轮完成交接（主控）"，含完成范围、本地提交清单与未做/不做；旧段落原字节保留。本轮把交付载体推进到 final4 后，两份 deliverable README、REFRESH.md、复算日志与 `final4-20261016/` 审计产物均已同步并实跑核验；`HANDOFF_DONE.md` 本身的历史快照按 C-11 登记给主控处理 | — |
| **S01 / S02** | ✅ **已满足（本轮新增）** | R03 族外对照与 R05 90 格排查表已并入正式报告：产物、命令与数值级核对见 §3.8；两块证据的来源文件本轮**字节未改**，由 `build_support.py` 的来源摘要检查在成包前复核 | — |
| C05 / D06 / E06 | 可选未做 | 第二阴性对照（修后 liboqs ref）、真实历史访存例、Binsec 扩大或真实 TLS/KEM 案例——按原文 §10"可选项未做不阻止这一定义下的完整完成" | 无须解除 |

**原文 41 行中已无"部分/未执行/条件未触发"项；剩余仅 3 项可选项。本轮新增的 S01/S02 两行均"已满足"。** 需要特别强调的分层口径（均已按原文要求写在证据里，不构成缺口，也不因"必做 100%"而升级）：
- **M2**：定位层阳性、除法热点微基准层未检出、完整解封装层未检出——三层互不冒充；族外 dudect 阳性出现在**已修**臂，不可归因于除法变体，证据明确不作泄漏结论。
- **M3/M4**：均为**人工构造校准**，不是新增上游 CVE；M4 的 insecure/secure 只针对 i386 `-O1`、长度 1–16 的抽取内核。
- **M5**："CI 含 0 且 Holm 不拒绝"**只是未检出**，不构成恒时证明，也不给总体误报率为零的结论。
- **M3 在线 dudect**：该版本不产逐样本 CSV，只有 max t 与状态行，已按事实登记，未用离线回放冒充在线。
- **M4（本轮改口径）**：家族窗口把 vulnerable 与 ct 两臂混在一起（I²=98.6%），故报告的正文、表与图**只引用分臂数值**（vulnerable Δ −4.089 ns、ct Δ +0.055 ns）；Holm 拒绝 3/6 全在 vulnerable 臂这一判定不变，也没有把 M4 的人工夹具阳性外推到真实密码库。
- **R03 / R05（本轮新增，见 §3.8）**：R03 是族外描述性对照，截断路径的 23.1–23.4 ns 是公开长度检查的接口语义，"未检出"不是恒时证明；R05 的 90 格里 74 个"不存在"、10 个"不适用"只覆盖固定源码/编译器/产物，1 个"未检查"格如实保留未检查，Binsec 只开 `control-flow,memory-access` 的边界已写明。
- **范围**：本表只覆盖原文 §2–§8 的软件/实验交付条件；竞赛方材料审核、本人签署与官方验收仍须人工完成（原文 §10）。

---

## 6. 审计方法与快照摘要

完整方法、命令与复算记录见 [`partials/S10.md`](partials/S10.md)（第 4 版）；第 3 版见 [`partials/S09.md`](partials/S09.md)。要点：
1. **口径复算**：逐行提取 41 个原文 ID（与 `S01.md` 自述交叉核对：32 阶段项 + 9 贯穿门槛），再新增 S01/S02 两行并按同一标准判定。
2. **路径存在性**：CSV **148 条可解析路径**脚本复验（0 缺失）+ `COMPLETION_REQUIREMENTS.md` 的 20 条可解析引用（19 条直接命中、1 条为裸名写法但产物存在）+ 证据目录 Markdown 相对链接扫描（0 断链）。
3. **内容级核验**（不只验存在，本版重跑）：varlat 1280/3 对 0/0；M3 Memcheck 1280/2 对 0/0；M4 Valgrind 32/1 对 0/0；Binsec insecure 对 bounded secure；M5 三模式 0/0 且 exit 0；控制器 54 次 `controller_exit=0`+`restore_match=yes`；Holm 家族与 Δ/CI/I²；RTLF 42/42；Microwalk MI 1.922 bits；Mona M1+M2 十二行；R03 `status.log` 18/18 `restore_match=yes` 且 20/20 探针在带内；R05 §4.1 汇总行 5/74/10/1/90；`final4` 实包复算 CTest 5/5（2.06 s）；PDF 33 页；六库 HEAD 与 REPOS.md 逐一相等。
4. **G03 密码学绑定复核**：`git cat-file blob efca8a1:<4 个 PLAN 路径> | shasum -a 256` 与 README 表 + 控制器 `plan_sha256` 三方逐字一致；R03 另有独立一例——`PLAN.md` 的 sha256 与 `RESULT.md` 记录的 `--plan-sha256` 相同。
5. **提交状态**：`44c209a..HEAD` **38 个提交**作者与提交者唯一为 `Gowin-liuyin <yinhaoran0808@outlook.com>`；`origin/main`（`c849c0f`）是 HEAD 的祖先，`origin/main..HEAD` = **6（未 push）**；本轮新增/改动的文件**尚未提交**（按仓库约定由主控统一提交），故本版同时绑定提交身份与工作区字节。
6. **本版（第 4 次）复核**：F02/F04 两行随 final4 重写，其余 39 行逐条取其证据路径重新存在性核对与命令实跑（未发现判定变化）；新增 S01/S02 两行、C-11 一条；对改动过的文档取新 sha256 与第 3 版比对（见下表"本版"行）。**报告侧另做一次独立复查**：7 个报告产物中混臂合并 Δ 的检索计数、两遍 XeLaTeX 的 Overfull/Underfull/缺字/hyperref 计数、以及"33 页"在六处的同值性。

**快照摘要（sha256 前 16 位，供最终比对是否被后续写入改变）：**

| 文件 | sha256(16) |
|---|---|
| `docs/platform/COMPLETION_REQUIREMENTS.md` | `31cac9c7b848585c`（与前三版一致，未变） |
| `docs/evidence/platform-collection-20261016/README.md` | `3c230f63f209aa74`（第 3 版 C-06/C-08/C-09/C-10 修正后的值，本轮未变） |
| `docs/evidence/platform-collection-20261016/status.log` | `7a4302811a382f3b`（未变） |
| `docs/evidence/platform-collection-20261016/stats/holm/RESULT.md` | `657f9b7b121c3498`（未变） |
| `docs/evidence/platform-control-qualification-20261016/QUALIFICATION.md` | `f04be2ce7ea06c41`（未变） |
| `docs/evidence/m2-kem-20261016/RESULT.md` | `3199c8e6344b5824`（未变） |
| `docs/evidence/m2-kem-20261016/microbench-0551254c9579/RESULT.md` | `b52322bfe2c858be`（未变） |
| `docs/evidence/m3-completion-20261016/RESULT.md` | `7364a8116a54e349`（**本版改变**：b637d0d 的 C-04 更正（第 3 版 `ee9be0e9446d4b1b`）） |
| `docs/evidence/m3-completion-20261016/TESTS.md` | `551ac10462446824`（b637d0d 新增（C-04）） |
| `docs/evidence/m3-completion-20261016/LOCATE_RESULT.md` | `d3686fbea2378f1c`（未变） |
| `docs/evidence/m3-memaccess-20261016/NOTES.md` | `88b3a31dba17a520`（**本版改变**：b637d0d 的 C-02 状态更新块（第 3 版 `f97b285b0cbd22a0`）） |
| `docs/evidence/m4-compare-20261016/NOTES.md` | `bc0e0268e60e27e5`（**本版改变**：b637d0d 的 C-02 状态更新块） |
| `docs/evidence/m4-compare-20261016/RESULT.md` | `8135862faf7508c8`（**本版改变**：b637d0d 的 C-02 状态更新块） |
| `docs/evidence/platform-completion-20261016/partials/S01.md` | `aa503425cc70f4ad`（**本版改变**：b637d0d 的 C-03 基线更正） |
| `docs/evidence/m4-completion-20261016/RESULT.md` | `d53d2f870139f411`（未变） |
| `docs/evidence/m4-completion-20261016/FORMAL_RESULT.md` | `294835cea76990d2`（未变） |
| `docs/evidence/m5-completion-20261016/RESULT.md` | `6838be94f4d9c8d0`（未变） |
| `docs/evidence/mona-wire-20261016/RESULT.md` | `dca28fa3b086570a`（未变） |
| `docs/evidence/platform-rtlf-20261016/RTLF_RESULT.md` | `7794b69dc044b6d6`（未变） |
| `docs/evidence/platform-matrix-20261016/RESULT.md` | `dfdfa60e5ca4c48d`（未变） |
| `deliverables/research/platform-completion-20261016/EVIDENCE_MATRIX.csv` | `5c90c794d11e69ed`（未变（M4 行本就是分臂 p 值）） |
| `HANDOFF_DONE.md` | `b054e9436dbd3c53`（未变（其 §第二轮交接 的时点问题见 C-11）） |
| `docs/evidence/platform-boundary-cleanup-20261016/README.txt` | `859c8531330448ee`（未变） |
| `docs/R05-全流程排查表.md` | `cc7ecff95ffd5a4e`（本轮新增来源（E30），**本审计与报告均未改动其字节**） |
| `docs/evidence/r03-malformed-20261016/PLAN.md` | `79edb27f8339691f`（本轮新增来源（E29）；sha256 与 RESULT.md 记录的 plan_sha256 一致） |
| `docs/evidence/r03-malformed-20261016/RESULT.md` | `3983d24615053af4`（本轮新增来源（E28）） |
| `docs/evidence/r03-malformed-20261016/logs/status.log` | `5c69b4404ed7e10b`（本轮新增来源（E31），18/18 restore_match=yes） |
| `deliverables/research/multi-leakage-platform-20261016/report-tables.json` | `260ac02226a60151`（本轮改变（新增 T7–T11、M4 分臂）） |
| `deliverables/research/multi-leakage-platform-20261016/report-data.json` | `a44bd9f848a65878`（本轮改变（M4 分臂、来源 E28–E31）） |
| `deliverables/research/multi-leakage-platform-20261016/report.pdf` | `570ab957bc50d6f8`（本轮重出：33 页） |
| `deliverables/research/multi-leakage-platform-20261016/report.tex` | `b0cd21f600d0349d`（本轮重出） |
| `docs/evidence/platform-report-20261016/RESULT.md` | `399c110a86c788f6`（**本版改变**：随 final4 重写（第 3 版 `bd7244ef9e526fb2`）） |
| `docs/evidence/platform-report-20261016/VISUAL_QA.md` | `0a7ae6388a7bb69d`（**本版改变**：33 页逐页核验） |
| `docs/evidence/platform-report-20261016/refresh-20261016/REFRESH.md` | `82df4145dab6d2e8`（**本版改变**：新增第五阶段（final4）） |
| `docs/evidence/platform-report-20261016/final4-20261016/pdf-metadata-audit.json` | `e10e140be1197d0d`（本轮新增：33 页、0 私有标记） |
| `docs/evidence/platform-report-20261016/final4-20261016/package-verification.json` | `5aa79b58a9b52178`（本轮新增：pass / 784 成员 / 0 直接身份字串） |
| `deliverables/support/CACR2026EA16XZ-multi-leakage-platform-20261016/CACR2026EA16XZ-platform-final4-20261016.zip` | `88395b6cc26f205c`（本轮新增匿名包） |
| `deliverables/research/multi-leakage-platform-20261016/r05_flowchart.py` | `3fdd32213c84d9d2`（本轮新增：R05 流程图静态渲染器） |
| `docs/evidence/platform-completion-20261016/FINAL_AUDIT-0d9876b.md` | `1e02e10ec96a79b3`（第 3 版原文（本版开始前复制，字节等于 c849c0f 提交内容）） |

> 摘要绑定本次读取时点（03:50）。**注意：第 3 版（快照 `0d9876b`）的完整摘要表见 [`FINAL_AUDIT-0d9876b.md`](FINAL_AUDIT-0d9876b.md) §6**，两表可直接比对哪些文件在本轮被改动——被改动的正是 C-02/C-03/C-04 涉及的两个文档与三个 NOTES/RESULT、以及本轮 final4 交付件。C-02 涉及的另外两个文件（`m4-compare-20261016/{NOTES,RESULT}.md`）在上一版摘要表里没有单列，本版补入以便逐字比对。最终复核请用 `shasum -a 256` 重跑并比对，命令见 [`partials/S10.md`](partials/S10.md)。

---

## 7. 版本间差异对照

### 7.1 快照 `47033dd`（第 1 版）→ 快照 `a30d7c7`（第 2 版）

| 行 | 47033dd（02:08） | a30d7c7（02:49） | 触发证据 |
|---|---|---|---|
| G03 | 部分 | **已满足** | `efca8a1` 冻结 + 四个执行用 sha256 独立复算一致 |
| G05 | 部分 | **已满足** | 54 次运行 restore_match=yes + 五条空任务资格 |
| G06 | 部分 | **已满足** | 42 数据集 raw CSV.gz + .meta + 统计 input.sha256 |
| G07 | 部分 | **已满足** | 四族 Holm 输出 + RTLF 42/42 族外 |
| G09 | 部分 | **已满足** | 六个新证据目录全部进入提交；身份唯一；未 push |
| B04 | 部分 | **已满足** | PLAN 冻结并绑定执行摘要 |
| B05 | 未执行 | **已满足** | M2 18 次锁频运行 + Holm/RTLF/dudect |
| B06 | 条件未触发 | **已满足** | 触发成立 + 六个微基准运行（`microbench-0551254c9579`） |
| B07 | 部分 | **已满足** | 完整运行包 + 平台行 + 报告 |
| C03 | 未执行 | **已满足** | M5 6 次运行 + Holm m=3 + RTLF/dudect |
| C04 | 部分 | **已满足** | 三句更新为真实统计 |
| D03 | 部分 | **已满足** | Microwalk 源码自建 + Pin 3.28 实跑（MI 1.922 bits） |
| D04 | 未执行 | **已满足** | M3 12 次运行 + Holm m=6 |
| D05 | 部分 | **已满足** | 结果包与平台行同步 |
| E04 | 未执行 | **已满足** | M4 18 次运行 + Holm 拒绝 3（全在 vulnerable 臂） |
| E05 | 部分 | **已满足** | 定位/形式化/统计分列 + 报告同步 |
| F01 | 部分 | **已满足** | Mona M2 六份对照行 |
| F02 | 部分 | **已满足** | 23 页终版报告（实测数字回填） |
| F03 | 部分 | **已满足** | 结果图刷新 + 图注 + 可重建源 |
| F04 | 部分 | 部分（当时唯一剩余） | 入口/进度/总表/复算已同步，最终交接未更新 |

**计数变化：** 口径 A 18/15/4/1/3 → **37/1/0/0/3**；口径 B（32 项）14/10/4/1/3 → **28/1/0/0/3**。

### 7.2 快照 `a30d7c7`（第 2 版）→ 快照 `0d9876b`（第 3 版）

| 行 / 编号 | a30d7c7（02:49） | 0d9876b（02:55） | 触发证据 |
|---|---|---|---|
| **F04** | 部分（唯一必做缺口） | **已满足** | `HANDOFF_DONE.md` 新增"第二轮完成交接（主控）"整节：完成范围 + 本地提交清单 + 未做与不做；旧段落原字节保留 |
| C-05 | 未闭 | **已闭合** | `platform-report-20261016/RESULT.md` 三处统一为 23 页并标注权威来源；`! grep -q '22 页'` 通过 |
| C-06 | 未闭 | **已闭合** | 采集 README 家族表/输出名改为 `.csv.gz` |
| C-07 | 未闭 | **已闭合** | `docs/evidence/platform-boundary-cleanup-20261016/` 真实入库（README.txt + ORIGINALS.tsv + 两份原件 + `source-tmp-originals/`） |
| C-08 | 未闭 | **已闭合** | 采集 README §7 第 1 条登记 `.meta` 静态字段与控制器权威来源 |
| C-09 | 未闭 | **已闭合** | §1.0 措辞改为"对 blob 内容再算 SHA-256" |
| C-10 | 未闭 | **已闭合** | 采集 README §7 第 2 条登记上游快照的悬空链接与 ELOOP 警告及"不改上游快照"的处置 |
| C-02 / C-03 / C-04 | 未闭 | **仍未闭**（3 条，均为"快照词/时点/入口描述"类低风险项） | `m3-memaccess/NOTES.md`、`m4-compare/*`、`S01.md`、`m3-completion/RESULT.md` 未被本轮修改（sha256 未变） |

**计数变化：** 口径 A 37/1/0/0/3 → **38/0/0/0/3**；口径 B（32 项）28/1/0/0/3 → **29/0/0/0/3**。需处理不一致由 8 条降至 **3 条**。

### 7.3 快照 `0d9876b`（第 3 版）→ 本版（第 4 版，快照 `dc6522c` + 工作区改动）

| 行 / 编号 | 第 3 版（0d9876b，02:57） | 本版（dc6522c + 工作区，03:50） | 触发证据 |
|---|---|---|---|
| F02 | 已满足（23 页、13 章、6 表、27 来源） | **已满足（33 页、15 章、11 表、2 图、31 来源）** | 新增 R03/R05 两章与表 T7–T11、图 2；M4 改为分臂引用；两遍编译 0 Overfull/Underfull/缺字/hyperref |
| F04 | 已满足（final3、23 页） | **已满足（final4、784 成员、33 页）** | deliverable README、REFRESH 第五阶段、`zip-recompute-final4.log`（CTest 5/5、2.06 s）、`final4-20261016/` 审计产物 |
| S01 | —（不存在） | **已满足（新增）** | R03 族外对照并入报告；`status.log` 18/18 restore_match=yes；PLAN sha256 与 RESULT 记录一致 |
| S02 | —（不存在） | **已满足（新增）** | R05 90 格排查表并入报告；汇总行 5/74/10/1/90 与报告表 T10 逐字一致；mermaid 源码在 MD/HTML 原样保留、PDF 用等价静态图 |
| C-02 | 未闭 | **已闭合** | `b637d0d` 给三个文件追加"状态更新"块（原文未改）；`m3-memaccess/NOTES.md` sha256 由 `f97b285b0cbd22a0` → `88b3a31dba17a520` |
| C-03 | 未闭 | **已闭合** | `b637d0d` 在 `partials/S01.md` 加"基线更正"并把两处过期措辞标注为已过期 |
| C-04 | 未闭 | **已闭合** | `b637d0d` 新增 `m3-completion-20261016/TESTS.md`（逐测试名 + 行号）并更正 `RESULT.md` 的归属表述；sha256 由 `ee9be0e9446d4b1b` → `7364a8116a54e349` |
| C-11 | —（不存在） | **未闭（本轮新增，低）** | `HANDOFF_DONE.md` 的"第二轮完成交接"仍是 `0d9876b` 时点快照（23 页/final3）；本版不改写历史段落，登记给主控在最终交接时刷新 |
| C-05 | 已闭合 | **复审后仍闭合**（页数改绑 33） | 六处同值 33；另在 REFRESH §I3 记入"改表格后必须重跑生成器再编译、三处必须同值"的护栏 |

**计数变化：** 口径 A 38/0/0/0/3 → **38/0/0/0/3（不变）**；口径 B（32 项）29/0/0/0/3 → **29/0/0/0/3（不变）**；新增口径 A′ 43 行 → **40/0/0/0/3**、B′ 34 项 → **31/0/0/0/3**。需处理不一致由 3 条（C-02/C-03/C-04）→ **1 条（C-11）**。

> 本版的判定口径与第 3 版一致：**新增证据以补充行登记，不改写原文 ID 的判定，也不把可选未做改判**。与第 3 版相比，41 行上没有一行状态发生变化。

---

*本文件由只读审计路 S10 生成（第 4 版，绑定快照 `main@dc6522c` + 本轮未提交工作区改动；前三版 `47033dd`、`a30d7c7`、`0d9876b` 原字节另存）；不修改任何被审计产物。最终判定以主控在全部写入停止后的确认为准，并需与比赛方材料审核、本人签署和官方验收分开记录。*
