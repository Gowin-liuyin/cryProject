# 人工复核签字清单（T34）

本清单列出**必须由人眼/人工判断确认**的点。每项给出检查方法与证据路径；
**签字栏留空，由复核人本人填写**。
**本清单共 31 项人工判定（A–E 五组）**——这个数字由审计行 D-04 / T34 从本行**解析**后
与实际行数比对，改动清单时两边会一起被门禁发现，不会各说各话。

> 机器可核对的项已由审计脚本覆盖（见 `FINAL_AUDIT.md` / `FINAL_AUDIT.csv`：
> **93 行 × 8 列（第 9.1 版）**、证据路径 **324 条 0 缺失**、**90 条 `verify_command` 全部返回 0**
> （**在作者工作区实测**：该工作区含 `.git` 历史与 `third_party/` 取件树；
> 在干净 clone 上，依赖 `.git` 历史的 6 条与 `third_party/` 的 6 条路径不可跑/不存在——
> 这是**分发形态的已知边界**（`BLOCKERS.md` B05 已登记），不是审计缺口）
> （另 3 条为可选未做的占位命令——C05 / D06 / E06，命令列是 `—`，**未执行**）；
> 实跑明细见 `docs/evidence/platform-completion-20261016/final-audit-checks-20261020.json`。
>
> **2026-10-20 更新：** ①表头口径推进到第 9.1 版；②末尾新增「机器可核项的复核结果」一节，
> 记录 `scripts/check_signoff_items.py` 的实跑结果（33 项全部通过，明细见
> `docs/evidence/closeout-20261016/signoff-machine-checks-20261020.json`）；
> ③**F1 已闭合**（B3/E3 一行的说明已更新）；④各表的**人工判定栏与签字栏一律留空**，
> 由复核人本人核对后填写——机器结果不能替代人的担责。

---

## A. 措辞与声明

| # | 检查点 | 检查方法 | 证据路径 | 复核人 | 日期 |
|---|---|---|---|---|---|
| A1 | "未检出"没有被写成"恒时证明" | 全文检索 `恒时`/`constant-time proof`/`证明`，逐处看上下文 | `docs/R05-全流程排查表.md`、`docs/evidence/*/RESULT.md`、`deliverables/research/multi-leakage-platform-20261016/report.pdf` | | |
| A2 | 阴性结论都限定了适用范围（机器/产物/类对/预算） | 抽查 M5 与 R03 对照 A 的结论段 | `docs/evidence/m5-completion-20261016/RESULT.md`、`docs/evidence/r03-malformed-20261016/RESULT.md` | | |
| A3 | "定位阳性"没有被写成"端到端阳性" | 抽查 M2/M3 的三层结论 | `docs/evidence/m2-kem-20261016/RESULT.md`、`docs/evidence/m3-completion-20261016/RESULT.md` | | |
| A4 | 人工夹具都标了"人工构造校准" | 检索 `人工构造校准` 的覆盖情况 | `docs/R05-全流程排查表.md`、`docs/evidence/m3-*`、`docs/evidence/m4-*`、报告 §5–§9 | | |
| A5 | 族外对照都标了"族外、不进 Holm" | 检索 `族外`，确认 R03 / RTLF / dudect / R12 / R09 都有 | `docs/evidence/platform-rtlf-20261016/RTLF_RESULT.md`、`docs/evidence/r12-innovation-20261016/RESULT_LOCKED_VS_UNLOCKED.md`、`docs/evidence/r09-optlevel-20261016/RESULT.md` | | |
| A6 | M4 只引用分臂数值，不引用家族合并 Δ | 检索报告全部载体中的 `3.74`（应为 0 命中）与 `4.089`/`0.055` | `report.md`、`report.tex`、`index.html`、`report-data.json`、`report-tables.json`、`platform-matrix.svg` | | |
| A7 | 锁频的价值表述为"确定性/可核对/可恢复"，不是"必然降低方差" | 读 T29a 结论与报告引用处 | `docs/evidence/r12-innovation-20261016/RESULT_LOCKED_VS_UNLOCKED.md` | | |
| A8 | "未运行"与"未检出"在全文严格区分 | 抽查 R05 的 unknown/不适用格与报告 T1 的状态列 | `docs/R05-全流程排查表.md` §7、报告表 T1 | | |

## B. 匿名性与隐私

| # | 检查点 | 检查方法 | 证据路径 | 复核人 | 日期 |
|---|---|---|---|---|---|
| B1 | 匿名包 `direct_identity_markers=0` | 跑 `verify_package.py <zip>`，看 `status` 与计数字段 | `docs/evidence/platform-report-20261016/final*-20261016/package-verification.json` | | |
| B2 | 人工抽查 10 个包内文件，无真名/邮箱/主机名/私有路径 | 解压后逐个 `grep -nE 'Gowin|yinhaoran|nss-marker|10\.144\.144|/Users/yin'` | 解出目录 + `REPRODUCE.md` | | |
| B3 | 报告 PDF 元数据无作者/私有标记/无 JS | `pdf-metadata-audit.json` + 手工打开属性面板 | `docs/evidence/platform-report-20261016/final*-20261016/` | | |
| B4 | 口令/私钥内容未进入仓库、证据或命令记录 | 检索 `password`/`passwd`/`SUDO_PW`/私钥块头 | 全仓库（排除 `build/`） | | |
| B5 | 附件三 DOCX 的元数据不含模板带出的设备标识与单位信息 | 读 `docProps/custom.xml`（WPS `hdid`/`userId` 应为 0 条）、`docProps/app.xml`（`Company`/`Application` 应为空）、`docProps/core.xml`（作者/最后修改者应为空） | `CACR2026EA16XZ-审批及签字页.docx` | | |

## C. 数值与图表一致性

| # | 检查点 | 检查方法 | 证据路径 | 复核人 | 日期 |
|---|---|---|---|---|---|
| C1 | 报告里的每个统计数字与证据文件逐字一致（抽查 20 处） | 对照 `holm_summary.json`、各模块 `RESULT.md`、`PERF.md`、`POWER.md` | 报告表 T1–T11 对应证据 | | |
| C2 | 图与表一致（同一数据的两种呈现不矛盾） | 对照 `figures/*.pdf` 与对应表 | `docs/evidence/r04-stats-20261016/figures/`、`docs/evidence/r09-optlevel-20261016/figures/` | | |
| C3 | PDF 页码 / 目录 / 交叉引用正确 | 打开 PDF 翻页核对目录条目与 `\ref` | `deliverables/research/multi-leakage-platform-20261016/report.pdf` | | |
| C4 | 性能表的 ns 与周期两种单位换算口径写清且自洽 | 读 `PERF.md` 的换算说明并抽算 2 行 | `docs/evidence/r08-perf-20261016/PERF.md` | | |
| C5 | MDE 表的口径（α、功效、SD 定义）写清且与 `members.csv.gz` 自洽 | 抽算 2 行的 MDE | `docs/evidence/r04-stats-20261016/POWER.md` | | |
| C6 | "量化尺度约 10 ns"这条限制在引用分位数结论处随行出现 | 检查报告分位数节与 `QUANTILE_CI.md` | `docs/evidence/r04-stats-20261016/QUANTILE_CI.md` | | |
| C7 | **M1 族的预注册完整性缺口已如实披露**（事前族 m=8，采集后收敛为 m=6） | 读 `BLOCKERS.md`「已登记的口径缺口」第 5 条，确认同时给出 m=8 与 m=6 的**并列**判定与 MDE，并确认报告/POWER/排查表三处都写明「不再把 m=6 说成事前族」 | `BLOCKERS.md`、`docs/evidence/r02-r04-close-20261016/holm.m8.csv`、`docs/evidence/r02-r04-close-20261016/RESULT.md` | | |

## D. 证据有效性与可复现

| # | 检查点 | 检查方法 | 证据路径 | 复核人 | 日期 |
|---|---|---|---|---|---|
| D1 | 冻结 PLAN 未被修改（sha256 与 `efca8a1` 的 blob 一致） | 跑 `BASELINE.md` 里的比对命令 | `docs/evidence/closeout-20261016/BASELINE.md` | | |
| D2 | 本轮所有锁频运行 `restore_match=yes` 占比 100% | 统计各处 `status.log` 与 `terminal.json` | `docs/evidence/platform-collection-20261016/status.log`、`R08/`、`R09/`、`r12/remote/logs/status.log` | | |
| D3 | 无效/失败运行都已归档且未计入结果 | 检查各 `failed*/` 目录与文档记录 | `R08/failed-blockcount-bug/`、`R09/failed/`、`platform-collection-20261016/harness-bug-archive/` | | |
| D4 | 新 PLAN 先于数据提交 | `git log` 中 PLAN 提交时间早于对应 raw 数据提交 | `git log --oneline -- docs/evidence/r0{8,9}-*/PLAN.md` 与数据提交 | | |
| D5 | 干净 clone 中 quick 档可跑通 | 按 `REPRODUCE-QUICK-LOG.md` 复跑一次 | `docs/evidence/r12-innovation-20261016/REPRODUCE-QUICK-LOG.md` | | |
| D6 | 匿名 ZIP 解出后 ctest 全过 | 解压到新目录后 `cmake`+`build`+`ctest` | `docs/evidence/platform-report-20261016/refresh-20261016/zip-recompute-final*.log` | | |

## E. 伦理与范围红线

| # | 检查点 | 检查方法 | 证据路径 | 复核人 | 日期 |
|---|---|---|---|---|---|
| E1 | 全程无密钥恢复、无 exploit demo | 检索 `key recovery`/`exploit`/`recover.*secret`，确认只有"不做"的声明 | 全仓库 | | |
| E2 | 计时窗口内无 I/O 或日志 | 复核 T18 的窗口检查结论与源码位置 | `docs/evidence/r06-noleak-20261016/AUDIT.md` §4 | | |
| E3 | 未通过日志/异常/返回码输出秘密或验证结果 | 复核 T18 的静态扫描与动态 diff；**F1 已于 2026-10-20 闭合**（static-scan 的 B 类由 1 条降为 0 条），闭合记录见 fix 目录，仍须人工确认未覆盖面 | `docs/evidence/r06-noleak-20261016/AUDIT.md`、`docs/evidence/r06-noleak-fix-20261020/AUDIT.md` | | |
| E4 | 第二架构（aarch64）已于 2026-10-21 执行并写明边界（12 格、只构成第二个架构、不构成第二个测量机） | 检索 `aarch64`/`Apple Silicon`，确认只出现在"不做"的声明里 | 报告 §范围、`docs/evidence/closeout-20261016/BASELINE.md` | | |
| E5 | `sources/`、`vendor/` 保持只读 | `git diff --numstat <基线>..HEAD -- sources/ vendor/` 为空 | `BASELINE.md` | | |

---

## 机器可核项的复核结果（2026-10-20，第 9 版复核自动生成）

下表由 `python3 scripts/check_signoff_items.py` 实跑生成，逐条命令与原始输出见
[`signoff-machine-checks-20261020.json`](signoff-machine-checks-20261020.json)。
**这些结果只是「机器能判的那一面」**：A1 的逐处措辞、A2 的限定范围是否说全、
C1 的数字抽查是否覆盖到本作品的关键结论，仍需复核人本人看过后签字。

| 清单项 | 机器可核的内容 | 结果 |
|---|---|---|
| A1 · 机器可核 | 报告全文检索「恒时」（36 处命中）且无肯定式恒时主张 | 通过（A1a：39）；通过（A1b：occurrences 42 sentences 42 affirmative []） |
| A2 · 机器可核 | M5 与 R03 的阴性结论都写明限定（不构成恒时证明、不给总体误报率） | 通过 |
| A3 · 机器可核 | M2/M3 的 RESULT 都区分定位层与端到端层 | 通过 |
| A4 · 机器可核 | 「人工构造校准」在 R05 与 M3/M4 的 RESULT 中均有标注 | 通过（A4：docs/R05-全流程排查表.md 6） |
| A5 · 机器可核 | 族外对照文件（RTLF / R12 / R09）都出现「族外」 | 通过（A5：4） |
| A6 · 机器可核 | M4 家族合并 Δ 3.74 在报告全部载体中 0 命中；分臂值 4.089 / 0.055 在位 | 通过；通过 |
| A7 · 机器可核 | 锁频价值未写成「必然降低方差」，写的是确定性 | 通过 |
| A8 · 机器可核 | R05 用「不适用 / 未检查」，报告用「未执行」，两套口径不混用 | 通过 |
| A6b · 机器可核 | M4 分臂数值 4.089 与 0.055 必须在位 | 通过 |
| A6a · 机器可核 | M4 家族合并 Δ 3.74 不得出现 | 通过 |
| A1b · 机器可核 | 报告不得出现肯定式恒时主张 | 通过（A1b：occurrences 42 sentences 42 affirmative []） |
| A1a · 机器可核 | 报告全文检索「恒时」，命中处均须带否定或限定 | 通过（A1a：39） |
| B1 · 机器可核 | 匿名包 `direct_identity_markers = 0`（**当前有效包**，见支撑包 README 头部的「当前有效」声明） | 通过 |
| B2 · 机器可核 | 包内**全部**可扫成员（文本成员 + `.gz` 解压后 + PDF 文字层），真名 / 邮箱 / 主机名 / 私有路径 0 命中 | 通过（B2：scanned 1374 hits []） |
| B3 · 机器可核 | 报告 PDF 元数据：无作者、私有标记 0、无 JavaScript | 通过 |
| B4 · 机器可核 | 仓库内无私钥块头、无 `SUDO_PW=` / `password=` 之类口令串 | 通过 |
| B5 · 机器可核 | 附件三 DOCX 的元数据不含设备标识、单位与作者 | 通过（B5：bad []） |
| B3b · 机器可核 | 官方作品设计报告（DOCX + PDF）正文无身份标记 | 通过（B3b：docx hits []） |
| C1 · 机器可核 | 抽查 7 处关键数字（54/54、36/36、26.16、42/42、存在 5、不存在 75、quick 档四个计数）逐字一致 | 通过（C1：checked 15 numbers; 0 problems） |
| C2 · 机器可核 | 图目录在位且图数与报告引用相符（R04 45 张） | 通过 |
| C3 · 机器可核 | 官方 PDF 目录条目页码全部落在实测页数范围内 | 通过（C3：entries 33 pages 104 out_of_range []） |
| C4 · 机器可核 | 性能表写明基频 4300000 kHz 与 ns/周期换算口径 | 通过 |
| C5 · 机器可核 | MDE 表写明 α 与功效口径 | 通过 |
| C6 · 机器可核 | 「量化尺度约 10 ns」在证据与报告里都在 | 通过 |
| C7 · 机器可核 | M1 族预注册完整性缺口已披露（m=8 存档 + 并列判定） | 通过 |
| D1 · 机器可核 | 冻结 PLAN 的 sha256 与 BASELINE 记录一致 | 通过 |
| D2 · 机器可核 | 锁频运行 `restore_match=yes` 命中，反面命中为 0 | 通过（D2：terminal.json 211 restore_match=yes 205 bad 0） |
| D3 · 机器可核 | 失败运行归档目录（R08 18 个、R09 1 个）在位 | 通过 |
| D4 · 机器可核 | PLAN 的提交时间早于对应原始数据 | 通过 |
| D5 · 机器可核 | 干净 clone 的 quick 档日志在案；本轮另在仓库本体实跑 263/263 | 通过 |
| D6 · 机器可核 | 匿名 ZIP 解出后 CTest 5/5 通过 | 通过 |
| E1 · 机器可核 | 本平台自有交付与证据里，密钥恢复 / exploit 的表述都在否定语境 | 通过（E1：files 120 non_negated 0） |
| E2 · 机器可核 | R06 的计时窗口 I/O 检查结论在案 | 通过 |
| E3 · 机器可核 | F1 已闭合：B 类 1 → 0，且闭合记录在案 | 通过 |
| E4 · 机器可核 | 报告写明第二架构**已执行**并写明边界（aarch64 12 格、只构成第二个架构、不构成第二个测量机） | 通过 |
| E5 · 机器可核 | `sources/` 与 `vendor/` 相对基线与工作区均无改动 | 通过 |
> **机器可核项合计 34 条（另有 2 行伞形行由子项聚合，不另计），通过 34 条、未通过 0 条**
> 复跑命令：`python3 scripts/check_signoff_items.py`。
> **这些自动结果不替代人工判定**：A1 的逐处措辞、C1 的抽查覆盖面、D2/D3 的运行计数是否被
> 复核人认可，仍以本清单上方的签字为准。

---

## 签字

| 角色 | 姓名 | 日期 | 签字 |
|---|---|---|---|
| 复核人 | | | |
| 复核人 | | | |
| 项目负责人 | | | |

> 本清单不构成竞赛方验收、不替代材料审核与官方签署。
> 复核人应在确认每一项后填写日期与签字；有异议的项请直接在该行备注，不要修改证据文件。
