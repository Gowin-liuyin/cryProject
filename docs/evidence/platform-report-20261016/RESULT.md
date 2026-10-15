# S8 报告、图、离线 HTML 与匿名包：2026-10-16 第五次刷新（final5-20261016）

状态：**T31 报告整合已完成——题面 12 条逐条证据并入正文，并新增附录 A「题面 12 条对照矩阵」；
威胁模型章以独立 LaTeX 片段直接 `\input{}` 并入。报告 **91 页**、
SHA-256 `d391114c9269b0c0ed463e06f3fed38a1cbded783be81590b7ae18151960db20`，
两遍 XeLaTeX 实测 0 Overfull / 0 Underfull / 0 缺字 / 0 hyperref 警告 / 0 LaTeX 警告。
**本轮只重出报告**：匿名 ZIP、包内解出复算与包审计由主控另跑，本文件不含包内复算结论。**

本轮没有硬件采数、调频、远端操作或密码实验；旧报告、旧展示、旧支撑包、旧 revision 目录与
原证据保持原字节；`docs/evidence/r03-malformed-20261016/` 与 `docs/R05-全流程排查表.md`
**一个字节也没有改**（生成器只读它们）。

## 载体（F02/F03，final5）

- 当前 PDF 为 **91 页**（权威值见 `final5-20261016/pdf-metadata-audit-repo-copy.json` 的 `pages`）：
  `deliverables/research/multi-leakage-platform-20261016/report.pdf`，
  SHA-256 `d391114c9269b0c0ed463e06f3fed38a1cbded783be81590b7ae18151960db20`。
- 正文 **25 节 + 证据来源索引**、**26 张对照表**、**2 张图**、**60 份来源**；
  `report.md`、`report.tex`、`index.html`、`platform-matrix.svg`、`r05-flowchart.svg`、
  `r05-flowchart.png`、`report-tables.json`、`evidence-snapshot.json` 同时生成。
- 生成器输出：
  `{"sources": 60, "sections": 25, "tables": 26, "document_state":
  "final5_20261016_full_clause_matrix_and_report_consolidation", "forbidden_token_hits": 0}`。
- 新增 15 张对照表：T12 向量来源、T13 修复语义等价、T14 环境总表、T15 稳健性与异常样本规则、
  T16 功效/MDE、T17 分位数差与分布图、T18 修复手段映射（16 行、5 模块）、T19 泄露渠道审计、
  T20 性能 25 行汇总、T21 成对开销 11 行、T22 优化级别 12 格、T23 锁频 vs 不锁频、
  T24 多工具矩阵 9×5、T25 一键复现、T26 附录 A 12 条对照矩阵。
- 新增 29 份来源 E32–E60（R01 向量与等价、R02 环境/规则/稳健性、R04 功效与分位数、
  R05 补缺格、R06 审计与映射、R08 性能、R09 优化级别、R11 威胁模型、R12 创新对照与复现、
  REPRODUCE-PARAMS、reproduce_all.sh、BLOCKERS，以及 R08/R09 控制器终态判据的代表文件 E59/E60）。
- **R05 计数已更新**：3 实现 × 5 步骤 × 6 类 = 90 格，**存在 5 / 不存在 75 / 不适用 10 / 未检查 0**
  （原唯一的「未检查」格已于 2026-10-16 补做并改判为「存在」）。表 T10 的逐实现计数同步改为
  M1 1/26/3/0、M2 3/24/3/0、M5 1/25/4/0；表 T11 的表题与行数改为「5 个『存在』格清单」。
- **附录 A（表 T26）**：12 行 × 6 列（条款 / 一句要求 / 状态 / 报告章节 / 证据路径 / 说明）。
  状态为 **11 条满足、第 6 条部分**。第 6 条的缺口是 R06 低危发现 F1
  （`tools/platform_m2/collector.c` 功能门失败时把批级接受/拒绝汇总写进 stderr、退出码与
  meta 的 `run_status`），已在同行的说明列写明缺什么、为什么没关、影响什么。
  第 9 条按项目冻结范围拆开写：必做的优化级别对照已完成；可选中「不同编译优化级别」完成、
  「不同 CPU 架构」不做（macOS/ARM、交叉编译或模拟器不能冒充真实 x86_64 Linux 实测）、
  「本地与网络场景」（T25）**未执行**（需 netns/veth/netem 与 sudo，登记为 BLOCKERS B01）。
- **威胁模型章**：`\input{docs/evidence/r11-threat-20261016/threat-model.tex}`，
  该片段独立编号为第 18 节（含 18.1–18.5）。片段**一个字节也没有改**；为消除该片段自身在默认
  排版参数下的 8 处 Underfull，只在其外层加了 `\begingroup\sloppy\hbadness=2000 … \endgroup`，
  并另做一次去掉该 `\input` 的对照编译证明**本报告自身段落 0 Overfull / 0 Underfull / 0 缺字**。
- M4 的分臂数值（vulnerable Δ −4.089 ns [−4.215, −3.963]、ct Δ +0.055 ns [−0.363, +0.473]）
  在正文、表 T3/T5、矩阵图内统一引用；**混臂合并 Δ 在全篇 0 次出现**——已在生成器里加了
  口径守卫（`report.md`/`report.tex`/`index.html`/`platform-matrix.svg`/`report-tables.json`/
  `report-data.json` 六个文件逐文件检索 `3.74` / `3,74`，命中即 `SystemExit`），
  本轮实测 `forbidden_token_hits: 0`。
- **PDF 可复现构建**：`SOURCE_DATE_EPOCH=1792080000 FORCE_SOURCE_DATE=1` 下两遍 xelatex
  输出**字节相同**（均为 `d391114c…`），因此归档日志与发布的 PDF 严格对应。
- 逐页渲染与核验见 [VISUAL_QA.md](VISUAL_QA.md) 与 `final5-20261016/render/`
  （91 张 100 DPI PNG + `contact-sheet.png`）。旧 draft10/draft12、refresh、final、final2、
  final3、final4 的版本与核验按各自目录原件保留。

## 数据来源与逐项核对（final5）

所有数字都从证据文件读取，不手工转录：`emit_final5_tables.py` 直接读
`r08-perf-20261016/perf.csv` 与 `perf.csv.comparison.csv`（T20/T21）、
`r09-optlevel-20261016/result.csv` 与 `result.csv.cells.csv`（T22，含逐种子 CI 不含 0 的计数）、
`r06-noleak-20261016/MAPPING.md` §1 表格（T18，剥掉 Markdown 链接与反引号并留出断行点）。
其余表由证据文件原文逐条录入，并在表注写明口径与边界。

**来源文件与本轮归档之间发现四处不一致，本报告不改判、按可核的一侧引用，并写进报告第 24 节**：

1. `docs/evidence/r06-noleak-20261016/MAPPING.md` §1 表格实际有 **16 个数据行**，
   该文件 §2 却自述「表内行数 15」（其自身的 6 + 5 + 4 分组算术与表格行数不符）。
   本报告按实际行数 16 引用。
2. `docs/evidence/r04-stats-20261016/POWER.md` §1 已更正 M1 主类对属于预注册 Holm 家族
   （m = 6、α_eff = 0.008333，主检验 p = 1.30117e-05、阈值 0.00833、拒绝），
   但同文件 §5 的家族列仍把 M1 标为「族外」。本报告采用更正后的 m=6 口径与
   MDE(25.2709 / 31.3901 ns)，不引用 §5 的陈旧表述。
3. 「M5 × 可变时间比较」4 格在 `docs/R05-全流程排查表.md` 本体按产物 + 源码判「不存在」，
   而 `BLOCKERS.md` 第 1 条把这一情形描述为「工具不适用型 unknown」，两处措辞不一致。
   本报告按 R05 本体的结论与计数（存在 5 / 不存在 75 / 不适用 10 / 未检查 0）引用，
   并保留该工具侧边界（varlat 面向可变时延指令，而该实现从上游起不用 `div`）。
4. **归档与文稿的时间差**：本轮写作期间（05:10）R08 / R09 的控制器目录被补入归档
   （`remote/R08/<run>/controller/` 54 个、`remote/R09/<run>/controller/` 36 个，
   含 `terminal.json`、`entry-probes.json`、`during.json`），而 `PERF.md`（05:08）与
   R09 的 `RESULT.md`（05:09）仍写着「副本只有 CSV 与 meta / 没有 controller 目录」。
   直接读取这些原始 `terminal.json` 计数得到 **R08 54/54、R09 36/36 四判据全部通过**
   （`restore_match=yes`、`worker_exit_code=0`、`worker_drained=true`），已作为**补充登记**
   写进 §15 与表 T21 的表注，并新增 E59/E60 两个代表文件作为证据路径；
   **本报告不改写两份证据文件的任何数值与结论**——两文件同步更新后应回填并重新生成报告
   （届时 `evidence-snapshot.json` 的摘要变化会使 `build_support.py` 拒绝旧包，属预期行为）。

以上四处中前三处是**文件表述层面**的差异，第四处是**归档与文稿的时间差**；
四者都不改变本报告已引用的任何数字；本报告没有擅自改判，也没有据此新增或撤销任何结论。

## 本轮修复的载体缺陷（照实记录）

1. **占位符 key 与 ASCII 长 token 合并**：把 `long_token` 阈值从 18 降到 15 做试验时，
   `@@MATH0@@` 这类占位符被当成 ASCII 长 token 一起塞进 `\texttt{\seqsplit{}}`，
   数学宏落在 `\texttt` 内触发 `! Missing $ inserted` 等 18 处报错、44 次 `Missing character`。
   修法：占位符 key 改为私用区字符 `\ue000<index>\ue001`，不再与 ASCII 串合并；阈值回到 18。
2. **表格列内的 Markdown 残留**：表 T18 的单元格带入反引号（PDF 里显示为成对引号）与
   Markdown 链接（展开成很长的相对路径），造成 2 处 Overfull。修法见上节。
3. **不可断行 token**：`holm_member=false`（17 字符）与 `mlk_ct_sel_int16(MLKEM_Q_HALF, …`
   在窄列里无法断行，各造成 1 处 Overfull。修法：前者改写为「holm_member 为 false」，
   后者在标识符与左括号之间留一个空格。
4. **缺字**：`⇒`、`↔`、`β`、`⁴` 在 lmroman 无字形。修法：加入 `MATH_REPLACEMENTS`。
5. **摘要溢出成近乎空白页**：摘要变长后 `\vfill` 把「版本性质」一行推到第 2 页。
   修法：删去与新摘要重复的第二段摘要、`\vfill` 改为固定间距，摘要整段回到第 1 页。
6. **附录导语被拆成 2 行尾页**：附录的表是 `landscape`、强制分页。修法：附录节也从新页开始。
7. **失败日志归档**：第一次编译的日志按新约定另存为
   `refresh-20261016/xelatex-final5-first-attempt1-failed.log`（4 Overfull、2 Underfull、
   4 次缺字），不会被后续重试覆盖。本轮之后所有编译都收敛为 0 告警。

## 本轮的边界与未做

- **没有** `git add`/`commit`/`push`（提交由主控统一完成）；**没有** sudo、硬件采数、调频或隔离写入。
- **没有**改任何证据文件的原始字节，特别包括 `docs/evidence/r03-malformed-20261016/`、
  `docs/R05-全流程排查表.md`、`docs/evidence/r11-threat-20261016/threat-model.tex`、
  M1 证据，以及 `final{,2,3,4}-20261016`、`refresh-20261016`、draft10/11/12 的原字节。
- **没有**运行 `audit_revision.py`：该脚本第一步就读匿名 ZIP（`verify_package.py`、解包、
  包内 `report/report.pdf`、`reproduce.sh` 离线回放、校验器反例），**依赖本轮尚未生成的包**。
  实测运行 `python3 .../audit_revision.py final5-20261016` 得到：
  `verify_package.py …/CACR2026EA16XZ-platform-final5-20261016.zip` 返回非 0（包不存在），
  脚本在 `subprocess.check_output` 处抛 `CalledProcessError`、整体 exit 1；除
  `final5-20261016/` 目录本身外没有写入任何审计产物。
  按主控安排，成包与解出复算由主控另跑。本轮只做了**不依赖 ZIP 的那部分**——
  直接对仓库副本做 PDF 元数据审计，结果写在
  `final5-20261016/pdf-metadata-audit-repo-copy.json`（`status=pass`、90 页、作者空、
  0 私有标记、无文档级 JavaScript、SHA-256 与发布件一致），并明确标注包内审计未执行。
- **没有**在报告里把「未执行」写成阴性，也没有把 R05 的「不存在」写成恒时证明、把 M5 那个
  只携带公开信息的早退写成可利用缺陷、把 M3/M4 的人工夹具算成上游 CVE。

---

# S8 报告、图、离线 HTML 与匿名包：2026-10-16 第四次刷新（final4-20261016）

状态：**全部实测数字已回填（含 RTLF 族外交叉 42/42、M2 除法热点微基准层），并已并入
R03 格式破损 / 截断族的族外对照与 R05 全流程六类来源排查表（90 格）；报告（33 页）、
平台矩阵图、R05 流程图、离线 HTML 与匿名 ZIP 已出终版 `final4-20261016`，并通过实包解出
复算（CTest 5/5）。报告数据格中的 `«待主控数据»` 为 0；仍标“未执行”的只有题面第 5 条
结构性未做的单元格。M4 的效应量只引用分臂数值。**
本轮没有硬件采数、调频、远端操作或密码实验；旧报告、旧展示、旧支撑包及原证据保持原字节。

## 报告载体（F02）

- 当前 PDF 为 **33 页**（权威值见 `final4-20261016/pdf-metadata-audit.json` 的 `pages`）：
  `deliverables/research/multi-leakage-platform-20261016/report.pdf`，
  SHA-256 `570ab957bc50d6f8f79839eb946ad7a05eb03fd807b9f93175c7f6721b669c53`。
- 正文 **15 章**、**11 张对照表**、**2 张图**、**31 份来源**；`report.md`、`report.tex`、
  `index.html`、`platform-matrix.svg`、`r05-flowchart.svg`、`r05-flowchart.png`、
  `report-tables.json`、`evidence-snapshot.json` 同时生成。
- 本轮新增两章：第 8 章「题面第 3 条补充：R03 格式破损 / 截断族的族外对照」（表 T7/T8/T9）
  与第 9 章「题面第 5 条补充：R05 全流程六类来源排查表（90 格）」（表 T10/T11 + 图 2）。
- 表 T7（对照 A，`valid − malformed`）：9 行，Δ 全部落在 +9.8 ～ −3.2 ns、9/9 CI 含 0、
  9/9 原始 p ≥ 0.28（最大 0.9552）；表 T8（对照 B，`valid − truncated`）：9 行，
  truncated 均值 23.1–23.4 ns、Δ ≈ 29.3 µs（M5）/ ≈ 55.1 µs（M1）、原始 p 为下溢打印的 0；
  表 T9：族外 online dudect，M1 未修 10.78 / 11.43 / 12.02（越阈）、M1 已修 1.12 / 2.05 / 2.01、
  M5 1.35 / 1.52 / 2.00。三者一律族外、不做 Holm、不改 `efca8a1` 与 M1/M5 既有判定。
- 表 T10：R05 90 格汇总（3 实现 × 5 步骤 × 6 类）：存在 5、不存在 74、不适用 10、未检查 1。
  表 T11：5 个「存在」格 + 1 个「未检查」格（M2 重加密 × 提前返回），带函数名、反汇编地址/
  行号与修复点（982c762、272125f）。Binsec 只开 `control-flow,memory-access`、未开乘除法检查
  的边界同时写入正文与表注。
- 图 2 是 R05 排查表第 5 节 mermaid 流程图的**等价静态渲染**（`r05_flowchart.py` 生成 SVG/PNG，
  XeLaTeX 不能渲染 mermaid）；**mermaid 源码原样保留在 `docs/R05-全流程排查表.md` 与本次
  离线 HTML 的 `<pre>` 中**，MD 载体同样原样内嵌该代码块。
- M4 的分臂数值（vulnerable Δ −4.089 ns [−4.215, −3.963]、ct Δ +0.055 ns [−0.363, +0.473]）
  在正文、表 T3/T5、矩阵图内统一引用；家族窗口把两臂混在一起（I²=98.6%），故全篇不再出现
  混臂合并 Δ（已逐文件检索确认：`report.md`/`report.tex`/`index.html`/`report-data.json`/
  `report-tables.json`/`evidence-snapshot.json`/`platform-matrix.svg` 均为 0 次）。
- XeLaTeX 两遍实际编译：**0 Overfull、0 Underfull、0 缺字、0 hyperref 警告、0 LaTeX 警告**。
  逐页渲染与核验见 [VISUAL_QA.md](VISUAL_QA.md) 与 `refresh-20261016/render-final4/`。
  此前 draft10/draft12、refresh、final、final2、final3 的版本及核验按各自目录原件保留。

## 平台矩阵图（F03）

`deliverables/research/platform-completion-20261016/figures/` 的图未变（`EVIDENCE_MATRIX.csv`
的 M4 行本就是分臂 p 值，无混臂合并 Δ）；报告内联矩阵 `platform-matrix.svg` 由
`report-data.json` 重新生成，M4 时间统计格已改为分臂写法。

## 匿名包与实包复算（F04）

当前匿名快照：
`deliverables/support/CACR2026EA16XZ-multi-leakage-platform-20261016/CACR2026EA16XZ-platform-final4-20261016.zip`。
SHA-256：`88395b6cc26f205c7d377808b0021f741203ed901603ff056c3379c07c8559f7`。
**784 个成员、783 个成员摘要、122 个本地 HTML 链接**通过，`status=pass`、
`direct_identity_markers=0`；此前 `final-20261016`（`15f8e2e4…`）、`final2-20261016`
（`2692d655…`）与 `final3-20261016`（`60deadab…`）保持原字节。包内新增 R03 的
`PLAN.md`/`RESULT.md`/`logs/status.log` 与 `docs/R05-全流程排查表.md` 四份来源副本及其查看页
（E28–E31）。ZIP CRC、唯一成员、路径、无符号链接、直接私有路径、活动内容与远端依赖检查通过。
作者字段为空，PDF 解压文本与元数据未命中本项目直接身份字串（匿名检查不承诺公开内容无法关联作者）。

**从该实际 ZIP 解出后**，在新建目录 `build/zip-recompute-final4-20261016/` 独立重跑
`cmake -S … -B …/build`、`cmake --build … --parallel 4`、`ctest --output-on-failure`：
**CTest 5/5 通过、0 失败（总耗时 2.06 s）**（`support_stats_qualification` 1.23 s、
两组 M4 self-test 各 0.38 s 与 0.44 s、两个 probe smoke 各 0.01 s 与 0.00 s）。确切命令、
环境、解出清单与逐项结果见
[refresh-20261016/zip-recompute-final4.log](refresh-20261016/zip-recompute-final4.log)。
**没有用仓库本体的构建充当本次复算。**

独立包审计（`audit_revision.py final4-20261016`，产物在 [final4-20261016/](final4-20261016/)）另给：
`pdf-metadata-audit.json`（33 页、作者空、0 直接私有标记、无文档级 JavaScript）、
`offline-replay.log` 与 `offline-reproduction.json`（只从实包解出后重建，CTest 5/5，
6 份数据集回放、12 个 C 输出逐字一致、包内原始时间输入字节未变；外部 RTLF/Mona/dudect/Binsec
未在该入口重执行）、`validator-rejection-tests.json`（摘要篡改、缺成员、目录越界、重复成员、
远端资产、活动脚本、私有路径与坏锚点八种坏例全部拒绝）。
包内 report 负载与仓库副本逐字节一致（pdf、tex、tables、data、snapshot、svg 六项摘要相同；
`report.md` 与 `report/index.html` 按设计做匿名文本转换与包内链接重写）。

## 包装边界与保留失败

时间输入 CSV 原字节保留。Mona `box-results.csv` 等含路径字段的文件只在新副本中转换路径、
保留数值，并记录原件与副本两套摘要。许可未明确的 RTLF/Mona/ctgrind 源码或 JAR、构建 ELF、
私钥、凭证与缓存均未再分发；旧原始档案中的 AppleDouble 隐藏元数据不进入新包。

生成器会拒绝证据来源在报告生成后变化的打包操作，要求先刷新来源摘要。
`document_state=final4_20261016_r03_extra_family_and_r05_matrix_merged`：M2–M5 锁频家族统计、
频率/恢复记录、Mona 对 M2 对照、RTLF 族外交叉（42/42）、M2 除法热点微基准层、R03 族外对照
与 R05 的 90 格排查表均已回填；**数据格占位符为 0**，报告中仍标“未执行”的只有题面第 5 条
结构性未做的单元格（见报告表 T6 与 T11）。
未 stage、commit 或 push。

## 本轮实际修复的三处载体缺陷（照实记录）

1. `\path{…}` 遇到含中文的来源路径 `docs/R05-全流程排查表.md` 时，lmmono 字体缺 CJK 字形，
   日志出现 6 次 `Missing character`；改为：纯 ASCII 路径仍用 `\path{}`，非 ASCII 路径走
   `tex_escape`（长 ASCII 片段仍进 `\texttt{\seqsplit{}}`）。
2. §9 段落里 `` `control-flow,memory-access` `` 是不可断行的长 token，造成
   1 处 Overfull \hbox（9.07pt）；改写为「control-flow 与 memory-access 两项」后消失。
3. `\noindent` 与 `path_tex` 直接拼接生成 `\noindentdocs/…`，触发 `! Undefined control
   sequence`；补一个空格后两遍编译均 exit 0。三处缺陷的中间失败日志未保留（同目录被覆盖），
   但同一日志中 `^!`/`Missing character`/`Overfull` 的计数已复核为 0。
