# 人工复核签字清单（T34）

本清单列出**必须由人眼/人工判断确认**的点。每项给出检查方法与证据路径；
**签字栏留空，由复核人本人填写**。

> 机器可核对的项已由审计脚本覆盖（见 `FINAL_AUDIT.md` / `FINAL_AUDIT.csv`：
> 43 行 × 8 列、证据路径 0 缺失、`verify_command` 全部返回 0）。
> 本清单只列**机器不容易判、或必须人为担责**的部分。

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

## C. 数值与图表一致性

| # | 检查点 | 检查方法 | 证据路径 | 复核人 | 日期 |
|---|---|---|---|---|---|
| C1 | 报告里的每个统计数字与证据文件逐字一致（抽查 20 处） | 对照 `holm_summary.json`、各模块 `RESULT.md`、`PERF.md`、`POWER.md` | 报告表 T1–T11 对应证据 | | |
| C2 | 图与表一致（同一数据的两种呈现不矛盾） | 对照 `figures/*.pdf` 与对应表 | `docs/evidence/r04-stats-20261016/figures/`、`docs/evidence/r09-optlevel-20261016/figures/` | | |
| C3 | PDF 页码 / 目录 / 交叉引用正确 | 打开 PDF 翻页核对目录条目与 `\ref` | `deliverables/research/multi-leakage-platform-20261016/report.pdf` | | |
| C4 | 性能表的 ns 与周期两种单位换算口径写清且自洽 | 读 `PERF.md` 的换算说明并抽算 2 行 | `docs/evidence/r08-perf-20261016/PERF.md` | | |
| C5 | MDE 表的口径（α、功效、SD 定义）写清且与 `members.csv.gz` 自洽 | 抽算 2 行的 MDE | `docs/evidence/r04-stats-20261016/POWER.md` | | |
| C6 | "量化尺度约 10 ns"这条限制在引用分位数结论处随行出现 | 检查报告分位数节与 `QUANTILE_CI.md` | `docs/evidence/r04-stats-20261016/QUANTILE_CI.md` | | |

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
| E3 | 未通过日志/异常/返回码输出秘密或验证结果 | 复核 T18 的静态扫描与动态 diff；注意已登记的低危项 F1 是否已按建议处理 | `docs/evidence/r06-noleak-20261016/AUDIT.md` | | |
| E4 | 未做第二架构（aarch64/Mac）实验，且报告中明确了这一点 | 检索 `aarch64`/`Apple Silicon`，确认只出现在"不做"的声明里 | 报告 §范围、`docs/evidence/closeout-20261016/BASELINE.md` | | |
| E5 | `sources/`、`vendor/` 保持只读 | `git diff --numstat <基线>..HEAD -- sources/ vendor/` 为空 | `BASELINE.md` | | |

---

## 签字

| 角色 | 姓名 | 日期 | 签字 |
|---|---|---|---|
| 复核人 | | | |
| 复核人 | | | |
| 项目负责人 | | | |

> 本清单不构成竞赛方验收、不替代材料审核与官方签署。
> 复核人应在确认每一项后填写日期与签字；有异议的项请直接在该行备注，不要修改证据文件。
