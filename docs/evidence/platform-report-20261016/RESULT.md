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
