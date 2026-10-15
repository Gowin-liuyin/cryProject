# 多泄漏模块平台完整完成条件 —— 最终复核审计（FINAL_AUDIT，第 2 版）

**审计快照：** 2026-10-16T02:49:10+08:00 – 02:56（Asia/Shanghai）
**仓库状态：** 分支 `main`，HEAD `a30d7c75d6790b9d79df7cf03935a2dffd476aa6`（"test: record the post-freeze clean acceptance run"，02:49:00）
**提交进展：** `git log --oneline 44c209a..HEAD | wc -l` = **29** 个提交（相对上一版快照 `47033dd` 新增 28 个）
**审计末期追加：** 审计收尾时 HEAD 前进到 `2b8557e`（"docs: finalize RTLF detail table and the final3 anonymous package"，02:50:32），`44c209a..HEAD` 变为 **30** 个提交。该提交只是把本审计**已经读取过**的工作区内容（report.pdf `bd0ddf92…`／442388 B／23 页、平台矩阵图、RTLF 明细、匿名包）纳入 git，未产生新的证据或结论，故本版全部判定不变；G09 行已按此注明。
**被审计文档：** `docs/platform/COMPLETION_REQUIREMENTS.md`（sha256 前 16 位 `31cac9c7b848585c`，未变更；文档自述基线 `main@ac46e62`）
**审计性质：** 只读。未改 `COMPLETION_REQUIREMENTS.md`、未改任何被审计证据文件、未 `git add/commit/push`。本路新增/改写仅：本文件、`FINAL_AUDIT.csv`、`partials/S09.md`。

> **上一版快照 47033dd 的结论在此：** 上一版判定为"全量 41 行已满足 18、部分 15、未执行 4、条件未触发 1、可选未做 3；口径 B（32 阶段项）已满足 14、部分 10、未执行 4、条件未触发 1、可选未做 3"，并给出 5 个关键未满足项（B05/C03/D04/E04 未执行 + B04/G03 未冻结提交）。该版原文原样保存在 [`FINAL_AUDIT-47033dd.md`](FINAL_AUDIT-47033dd.md) 与 [`FINAL_AUDIT-47033dd.csv`](FINAL_AUDIT-47033dd.csv)，**不覆盖、不追改**。本版在该时点之后重跑同一方法；两版的差异即为本轮新落地的证据（见 §7 差异对照）。

> **口径纪律（严格遵守原文第 1 节）：** 未运行 ≠ 未检出；软件就绪 ≠ 工具已执行；clone 成功 ≠ 运行成功；前置完成 ≠ 模块完成；人工夹具不得计为上游 CVE；M5 阴性不写成恒时证明；M2 定位阳性不写成端到端阳性。本版所有"已满足"均有实际产物 + 可跑命令 + 数值级核对；所有"未检出/无命中"均未被升级为"恒时"或"总体阴性"。

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

### 1.3 两个口径的完成计数（本版快照）

| 口径 | 分母 | 已满足 | 部分 | 未执行 | 条件未触发 | 可选未做 | 必做子集完成率 |
|---|---:|---:|---:|---:|---:|---:|---:|
| **口径 A：原文全量 41 行** | 41 | **37** | **1**（F04） | 0 | 0 | **3** | 必做 36 中 35 已满足（**97.2%**） |
| **口径 B：用户"32 项"（A–F 阶段项）** | 32 | **28** | **1**（F04） | 0 | 0 | **3** | 必做 27 中 26 已满足（**96.3%**） |

---

## 2. 汇总计数表

### 2.1 类型 × 状态 交叉表（自洽校验）

| 类型 | 已满足 | 部分 | 未执行 | 条件未触发 | 可选未做 | 小计 |
|---|---:|---:|---:|---:|---:|---:|
| 必做（含 B03 必做前置） | 35 | 1（F04） | 0 | 0 | 0 | **36** |
| 条件项（B06、D03） | 2 | 0 | 0 | 0 | 0 | **2** |
| 可选（C05、D06、E06） | 0 | 0 | 0 | 0 | 3 | **3** |
| **合计** | **37** | **1** | **0** | **0** | **3** | **41** |

- 条件项 B06 的触发条件（端到端家族不拒绝）**已成立并已执行**，故不再记"条件未触发"；D03 的"有 Pin 时运行 Microwalk"分支**已实际达成**（源码自建 Microwalk + Pin 3.28），故不再记"降级"。
- 41 行 × 8 列机器可读版本见 [FINAL_AUDIT.csv](FINAL_AUDIT.csv)（脚本校验：41 数据行、8 列、**131 条引用路径全部存在、0 缺失**）。

### 2.2 分 Phase 计数

| 段 | 行数 | 已满足 | 部分 | 可选未做 |
|---|---:|---:|---:|---:|
| G 贯穿门槛 | 9 | 9 | 0 | 0 |
| A 平台骨架 | 4 | 4 | 0 | 0 |
| B M2 KyberSlash | 7 | 7（含 B06 条件项已执行） | 0 | 0 |
| C M5 阴性对照 | 5 | 4 | 0 | 1（C05） |
| D M3 秘密访存 | 6 | 5（含 D03 条件项已达标） | 0 | 1（D06） |
| E M4 比较/有界验证 | 6 | 5 | 0 | 1（E06） |
| F Mona/报告/平台图 | 4 | 3 | 1（F04） | 0 |

---

## 3. 逐项审计矩阵（41 行）

**图例：** 证据路径均为**本次实际 `test -f`/`ls`/解包核对**通过的仓库相对路径（CSV 中 131 条路径由脚本 `os.path.exists` 复验，0 缺失）。`核对命令` 在仓库根 `/Users/yin/code/cryProject` 可直接执行；完整命令见 `FINAL_AUDIT.csv` 的 `verify_command` 列。

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

### 3.7 Phase F Mona、报告与平台图（4 行：3 已满足 + F04 部分）

| ID | 类型 | 要求产物 | 证据路径 | 状态 | 说明 / 剩余缺口 | 核对命令 |
|---|---|---|---|---|---|---|
| F01 | 必做 | Mona 对 M1 与 M2 主 CSV 的独立对照行 | `mona-wire-20261016/native-v2/run/m2/m2-mona.csv`；`.../run/m1/m1-mona.csv`；`mona-wire-20261016/RESULT.md` | 已满足 | M1 六份 + M2 六份各出对照行；M2 五份无验证分离、s3 已修臂一次末轮单子集（如实登记，不作受控误报率）；投影自检与多重集等价留证；`holm_member=false` 不入 Holm | `head -3 docs/evidence/mona-wire-20261016/native-v2/run/m2/m2-mona.csv` |
| F02 | 必做 | 新正式报告含四段链章，实测表/图与证据一一对应 | `deliverables/research/multi-leakage-platform-20261016/{report.pdf,report.tex,report.md}`；`platform-report-20261016/{VISUAL_QA.md,final3-20261016/pdf-metadata-audit.json}` | 已满足 | 终版 **23 页**（本次以 `pages=23` 与 VISUAL_QA 独立确认）、13 章、6 张对照表、27 份来源；第 4 章为四段链状态；数据格无占位符（报告内 6 处"待主控数据"字样均为"已无占位符"的说明句）。文档内 22/23 页表述不一致见 C-05 | `python3 -c "import json;print(json.load(open('docs/evidence/platform-report-20261016/final3-20261016/pdf-metadata-audit.json'))['pages'])"` |
| F03 | 必做 | 平台矩阵图与可重建源，分三类与各层状态 | `deliverables/research/platform-completion-20261016/figures/{platform-evidence-matrix.svg,CAPTION.md,render_matrix.py}`；`EVIDENCE_MATRIX.csv` | 已满足 | 结果图（明写非计划图）已按新结果刷新，图注明每格证据路径；无 `«待主控数据»`，橙色仅表结构性未运行 | `grep -n 结果图 deliverables/research/platform-completion-20261016/README.md` |
| F04 | 必做 | deliverables 入口、进度、平台总表及**最终交接**同步；复算路径/边界可读 | `deliverables/research/multi-leakage-platform-20261016/README.md`；`deliverables/research/platform-completion-20261016/{README.md,EVIDENCE_MATRIX.csv}`；`docs/full-work-progress.md`；`platform-report-20261016/refresh-20261016/zip-recompute-final3.log` | **部分** | 入口、进度、平台总表、复算路径已同步（匿名 ZIP final3 **实包解出后 CTest 5/5**、23 页 PDF、离线 HTML、REFRESH 记录）；**缺口**：最终交接仍停在启动轮——`HANDOFF_DONE.md` 只列 10 个提交至 `aa4d920`，未覆盖本轮 29 个新提交，也没有完成交接文档与本地提交清单 | `test -f deliverables/research/platform-completion-20261016/EVIDENCE_MATRIX.csv; grep -c '^| .[0-9a-f]' HANDOFF_DONE.md` |

---

## 4. 矛盾清单（本版：硬矛盾 0 条、需处理不一致 8 条，其中 C-01 已闭合）

**硬矛盾判定（自述"已满足"但证据缺失 / 路径不存在）：0 条。** 客观核验：
- `COMPLETION_REQUIREMENTS.md` 的 21 条引用路径 **21/21 存在**；
- 本节涉及的 131 条 CSV 证据路径 **全部存在**（脚本复验）；
- 新增证据目录内的 Markdown 相对链接 0 断链（沿用 S09 扫描方法，本版重跑）。

| 编号 | 状态 | 级别 | 内容与本次复核结论 |
|---|---|---|---|
| **C-01** | ✅ **已闭合** | — | 上轮指出 `platform-matrix-20261016/RESULT.md` 的 M3/M4/M5 行落后于新证据。本次复核：矩阵 M2–M5 行**已同步**（写明"已采数"、各族 Holm 拒绝数、合并 Δ 与 CI、I²、Microwalk MI、Binsec 有界结论与指向采集原件的链接），并新增逐模块运行数表（M2 18/18、M5 6/6、M3 12/12、M4 18/18 的 restore_match=yes）。矛盾解除。 |
| **C-02** | 未闭 | 中 | `m3-memaccess-20261016/NOTES.md` 末段"本轮没有实现这两项（顶层 CMake 接入 / 时序 PLAN）"与 `m4-compare-20261016/{NOTES,RESULT}.md`"本轮未运行 Binsec"仍是各自回合的快照；现状已有 `cmake/PlatformM3.cmake`、M3 采数、`formal-v2` 实跑。语义上"本轮"正确，但并读会误判。建议在新 RESULT 交叉引用或加时点标注（不改原字节）。 |
| **C-03** | 未闭 | 低 | `partials/S01.md` 写"基线固定为 main@ac46e62"，而快照 HEAD 已是 `a30d7c7`（相距 29 个提交）。非缺陷，但完成计数必须绑定快照时点——本文件已在文首声明。 |
| **C-04** | 未闭 | 低 | `m3-completion-20261016/RESULT.md`"复核入口"把"原生各 6/6"归到 `native-8b6f2d91/`，该目录无独立 ctest 日志；6/6 实际在 `native-8b6f2d91/build-{ordinary,sanitize}.log` 内（本次已核对命中 `100% tests passed ... out of 6` 与 `platform_m3_full_output_equivalence`）。可核对性未受损，但按文件名找会扑空。 |
| **C-05** | 新增 | 低 | `platform-report-20261016/RESULT.md` 内部页数自相矛盾：状态行写"报告（23 页）"，正文 §F02 与末段写"**22 页**"。**权威值经本次独立确认是 23 页**（`final3-20261016/pdf-metadata-audit.json` 的 `pages: 23`、`VISUAL_QA.md` 标题"23 页报告逐页视觉核验"、报告 README 亦写 23 页）。主控交办消息中的"22 页"即来自该 RESULT 正文。 |
| **C-06** | 新增 | 低 | `platform-collection-20261016/README.md` §4 写 `stats/members/members.csv` 与 `stats/holm/holm.csv`，实际文件为 `members.csv.gz`、`members-descriptive.csv.gz`、`holm.csv.gz`、`pooled.csv.gz`（§3 已声明"所有 .csv 以 gzip 存放"）。路径命名与存储约定不一致，易致命令失败。 |
| **C-07** | 新增 | 中 | 交办消息引用的 `docs/evidence/platform-boundary-cleanup-20261016/` **在仓库中不存在**（本次 `ls`/`find` 均无，也无任何文档引用该路径）。实际越界搬回证据是 `docs/evidence/mona-wire-20261016/native-v2/failed/out-of-bound-tmp/README.txt`（含来源、`observed_mtime`、前后条目数、处理方式）；第二处（M2 采集树变量缺陷致 worker 路径越出 Cry）只有 `platform-collection-20261016/README.md` §2 的文字描述，原件留在远端 `Cry/platform-collect-20261016-c011ec7a5e01/harness-bug-archive/`，**未拉回本地**。建议：更正引用路径，并考虑把远端 harness-bug 原件拉回留档。 |
| **C-08** | 新增 | 中 | 采集件自述与控制器记录分叉：各 run 的 `.meta` 写 `cpu_affinity=not_pinned`、`frequency_control=not_configured`，而采集 README 与控制器日志写明 `taskset -c 2/-c 6`、`min=max=4300000`、`restore_match=yes`。Mona RESULT 已如实说明"CPU 归属来自主控说明、本路不据此改称锁频"。结论不受影响（频率证据来自控制器），但报告或第三方引用 `.meta` 时会得到相反表述，建议在采集 README 注明该字段未由采集件自身写入。 |
| **C-09** | 新增 | 低 | `platform-collection-20261016/README.md` §1.0 写四个摘要"等于 `git show efca8a1:<路径>` 的 blob 摘要"。严格说 `git show`/`git rev-parse` 给的是 **SHA-1 blob id**，四个值是**对 blob 内容求的 SHA-256**。四个摘要本身正确：本次用 `git cat-file blob efca8a1:<path> \| shasum -a 256` 逐字复算与 README、控制器 `plan_sha256` 全部一致。仅措辞需精确化。 |
| **C-10** | 新增 | 低 | 拉回的 M2 采集源码树存在 5 个悬空符号链接（`dependencies/sysroot/usr/lib/x86_64-linux-gnu/libssl.so -> libssl.so.3` 等，目标缺失）；`git status` 另对两处 `avx2/.gitignore` 报 "Too many levels of symbolic links"（本次核查：目标是 `../ref/.gitignore`，文件内容可正常读取，未发现真实环）。均不影响被测 ELF（生产 measure 只依赖系统 libc/loader），但按"链接目标核查"应登记。 |

---

## 5. 仍未满足项与理由（本版）

| 项 | 状态 | 未满足内容与理由 | 解除条件 |
|---|---|---|---|
| **F04** | 部分 | 原文要求"当前 deliverables 入口、**进度、平台总表及最终交接**同步；复算路径/边界可读"。前三项与复算路径均已同步并有实包证据；**"最终交接"仍停留在启动轮**：`HANDOFF_DONE.md`（01:29，未更新）只列 10 个提交至 `aa4d920`，未覆盖 `44c209a..a30d7c7` 的 29 个新提交，也没有独立的完成交接文档或本地提交清单 | 主控补一份完成交接（或在 `HANDOFF_DONE.md` 追加本轮提交清单与未完成边界），即可闭合 |
| C05 / D06 / E06 | 可选未做 | 第二阴性对照（修后 liboqs ref）、真实历史访存例、Binsec 扩大或真实 TLS/KEM 案例——按原文 §10"可选项未做不阻止这一定义下的完整完成" | 无须解除 |

**除 F04 与三项可选项外，41 行中无"部分/未执行/未满足"项。** 需要特别强调的分层口径（均已按原文要求写在证据里，不构成本次缺口）：
- **M2**：定位层阳性、除法热点微基准层未检出、完整解封装层未检出——三层互不冒充；族外 dudect 阳性出现在**已修**臂，不可归因于除法变体，证据明确不作泄漏结论。
- **M3/M4**：均为**人工构造校准**，不是新增上游 CVE；M4 的 insecure/secure 只针对 i386 `-O1`、长度 1–16 的抽取内核。
- **M5**："CI 含 0 且 Holm 不拒绝"**只是未检出**，不构成恒时证明，也不给总体误报率为零的结论。
- **M3 在线 dudect**：该版本不产逐样本 CSV，只有 max t 与状态行，已按事实登记，未用离线回放冒充在线。

---

## 6. 审计方法与快照摘要

完整方法、命令与复算记录见 [`partials/S09.md`](partials/S09.md)。要点：
1. **口径复算**：逐行提取 41 个 ID，与 `S01.md` 自述交叉核对（32 阶段项 + 9 贯穿门槛）。
2. **路径存在性**：CSV 131 条路径脚本复验（0 缺失）+ 原文 21 条引用路径（21/21）+ 证据目录 Markdown 相对链接扫描（0 断链）。
3. **内容级核验**（不只验存在）：varlat 1280/3 对 0/0；M3 Memcheck 1280/2 对 0/0（新根重验）；M4 Valgrind 32/1 对 0/0；Binsec insecure 对 bounded secure + 截断对照 unknown；M5 三模式 0/0 且 exit 0；各配置 CTest 87/87、57/57、7/7、6/6；控制器 54 次 `controller_exit=0`+`restore_match=yes`；entry/exit 快照字节相同；Holm 家族与 Δ/CI/I²；RTLF 42/42；Microwalk MI 1.922 bits；Mona M1+M2 十二行；ZIP 实包复算 CTest 5/5；PDF 23 页；六库 HEAD 与 REPOS.md 逐一相等。
4. **G03 密码学绑定复核**：`git cat-file blob efca8a1:<4 个 PLAN 路径> | shasum -a 256` 与 README 表 + 控制器 `plan_sha256` 三方逐字一致。
5. **提交状态**：`44c209a..HEAD` 29 个提交作者唯一；证据目录 `git ls-files` 全部非 0；`origin/main..HEAD` = 43（未 push）。

**快照摘要（sha256 前 16 位，供最终比对是否被后续写入改变）：**

| 文件 | sha256(16) |
|---|---|
| `docs/platform/COMPLETION_REQUIREMENTS.md` | `31cac9c7b848585c`（与上版一致，未变） |
| `docs/evidence/platform-collection-20261016/README.md` | `01e6d8989ef71222` |
| `docs/evidence/platform-collection-20261016/status.log` | `7a4302811a382f3b` |
| `docs/evidence/platform-collection-20261016/stats/holm/RESULT.md` | `657f9b7b121c3498` |
| `docs/evidence/platform-control-qualification-20261016/QUALIFICATION.md` | `f04be2ce7ea06c41` |
| `docs/evidence/m2-kem-20261016/RESULT.md` | `3199c8e6344b5824` |
| `docs/evidence/m2-kem-20261016/microbench-0551254c9579/RESULT.md` | `b52322bfe2c858be` |
| `docs/evidence/m3-completion-20261016/RESULT.md` | `ee9be0e9446d4b1b` |
| `docs/evidence/m3-completion-20261016/LOCATE_RESULT.md` | `d3686fbea2378f1c` |
| `docs/evidence/m4-completion-20261016/RESULT.md` | `d53d2f870139f411` |
| `docs/evidence/m4-completion-20261016/FORMAL_RESULT.md` | `294835cea76990d2` |
| `docs/evidence/m5-completion-20261016/RESULT.md` | `6838be94f4d9c8d0` |
| `docs/evidence/mona-wire-20261016/RESULT.md` | `dca28fa3b086570a` |
| `docs/evidence/platform-rtlf-20261016/RTLF_RESULT.md` | `7794b69dc044b6d6` |
| `docs/evidence/platform-report-20261016/RESULT.md` | `b9a7968214c2f8fb` |
| `docs/evidence/platform-matrix-20261016/RESULT.md` | `dfdfa60e5ca4c48d` |
| `deliverables/research/platform-completion-20261016/EVIDENCE_MATRIX.csv` | `5c90c794d11e69ed` |

> 本轮处于持续写入期（审计期间 `platform-rtlf-20261016/RTLF_RESULT.md` 与若干新目录刚进入索引），上述摘要绑定本次读取时点；最终复核请用 `shasum -a 256` 重跑并比对，命令见 `partials/S09.md`。

---

## 7. 与上一版（47033dd）的差异对照

| 行 | 上版（47033dd, 02:08） | 本版（a30d7c7, 02:49） | 触发证据 |
|---|---|---|---|
| G03 | 部分 | **已满足** | `efca8a1` 冻结 + 四个执行用 sha256 独立复算一致 |
| G05 | 部分 | **已满足** | 54 次运行 restore_match=yes + 五条空任务资格 |
| G06 | 部分 | **已满足** | 42 数据集 raw CSV.gz + .meta + 统计 input.sha256 |
| G07 | 部分 | **已满足** | 四族 Holm 输出 + RTLF 42/42 族外 |
| G09 | 部分 | **已满足** | 六个新证据目录全部进入提交；29 提交身份唯一；未 push |
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
| F04 | 部分 | **部分**（唯一剩余） | 入口/进度/总表/复算已同步，最终交接未更新 |

**计数变化：** 口径 A 由 已满足 18 / 部分 15 / 未执行 4 / 条件未触发 1 / 可选未做 3 → **已满足 37 / 部分 1 / 未执行 0 / 条件未触发 0 / 可选未做 3**；口径 B（32 项）由 14 / 10 / 4 / 1 / 3 → **28 / 1 / 0 / 0 / 3**。

---

*本文件由只读审计路 S09 生成（第 2 版，绑定快照 `main@a30d7c7`）；不修改任何被审计产物。最终判定以主控在全部写入停止后的确认为准，并需与比赛方材料审核、本人签署和官方验收分开记录。*
