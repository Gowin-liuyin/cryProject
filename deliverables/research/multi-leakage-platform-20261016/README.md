# 多泄漏平台新补充报告（2026-10-16 刷新）

本目录为独立的新报告载体，旧正式报告、旧展示与 draft10/11/12 旧包保持原字节。
当前状态：**报告结构、题面第 3/4/5 条对照表、矩阵图、离线 HTML 与匿名 ZIP 已刷新；
M2–M5 锁频时间统计待主控采数回填（占位符 `«待主控数据»`）**，文稿存在不替代平台验收。

当前已核验副本为 [17 页 PDF](report.pdf) 与 [离线展示](index.html)，绑定 18 份实际来源、
13 章正文与 6 张对照表。M4 的 i386 -O1、1–16 字节 Binsec 有界对照已纳入；新增正式时序
仍 `not_run`，实包解出后的 CTest 复算为 5/5（见
[refresh 记录](../../../docs/evidence/platform-report-20261016/refresh-20261016/REFRESH.md)）。

- `report-data.json`：显式模块状态、五模块摘要与证据来源；新结果须由主控确认后更新。
- `report-tables.json`：题面第 3/4/5 条对照表、实测数字—证据对照表与 `«待主控数据»` 占位符清单。
- `generate_report.py`：生成自包含中文 LaTeX、Markdown、SVG 矩阵、离线 HTML 及来源摘要。
- `report.tex`、`report.pdf`：中文源与实际编译 PDF；Fandol 字体随 TeX 发行版提供，无个人字体路径。
- `index.html`：内嵌 CSS 与矩阵的静态离线展示，不依赖网络或活动脚本。
- `evidence-snapshot.json`：相对来源、状态、原始字节摘要与生成时仓库身份。
- `audit_revision.py`：只从实际 ZIP 复算，并审查 PDF 元数据、离线回放与校验器反例。

生成源后编译两次；中间文件放在本机独占构建目录：

```sh
python3 deliverables/research/multi-leakage-platform-20261016/generate_report.py
mkdir -p build/platform-report-s8
xelatex -interaction=nonstopmode -halt-on-error -output-directory=build/platform-report-s8 deliverables/research/multi-leakage-platform-20261016/report.tex
xelatex -interaction=nonstopmode -halt-on-error -output-directory=build/platform-report-s8 deliverables/research/multi-leakage-platform-20261016/report.tex
cp build/platform-report-s8/report.pdf deliverables/research/multi-leakage-platform-20261016/report.pdf
```

回填 `«待主控数据»` 时先改 `report-tables.json`/`report-data.json`，再按上面的顺序重新生成、
编译、逐页渲染，并用**新 revision** 重新成包（不覆盖 `refresh-20261016`）。
本轮没有 push、硬件采数或对旧证据的改写。
