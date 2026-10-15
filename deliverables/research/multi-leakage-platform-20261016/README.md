# 多泄漏平台新补充报告（2026-10-16 终版 final3-20261016）

本目录为独立的新报告载体，旧正式报告、旧展示、draft10/11/12、refresh-20261016、final-20261016、final2-20261016 旧包保持原字节。
当前状态：**全部实测数字已回填（含 RTLF 族外交叉 42/42 与 M2 除法热点微基准层）；题面第 3/4/5 条
对照表、矩阵图、离线 HTML 与匿名 ZIP 已出终版**。报告数据格中已无 `«待主控数据»`，仍标“未执行”的
只有题面第 5 条结构性未做的单元格；文稿存在不替代平台验收。

当前已核验副本为 [23 页 PDF](report.pdf) 与 [离线展示](index.html)，绑定 27 份实际来源、
13 章正文与 6 张对照表。M2/M3/M5 的端到端家族 Holm 拒绝 0、M4 拒绝 3 项且全在 vulnerable 臂；
族外 dudect 与 RTLF 一律不进 Holm。实包解出后的 CTest 复算为 5/5（见
[refresh 记录](../../../docs/evidence/platform-report-20261016/refresh-20261016/REFRESH.md)）。

- `report-data.json`：显式模块状态、五模块摘要与证据来源；新结果须由主控确认后更新。
- `report-tables.json`：题面第 3/4/5 条对照表、实测数字—证据对照表与回填状态清单。
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
