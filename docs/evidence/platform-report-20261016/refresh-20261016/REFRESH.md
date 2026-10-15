# F02/F03/F04 刷新记录（2026-10-16，本机 macOS/ARM）

本文件记录两阶段：**refresh-20261016**（结构、对照表、图与包刷新，统计留占位）与
**final-20261016**（主控真实锁频数字回填后的终版包，见文末「第二阶段」）。两阶段都**从实际 ZIP
解出后**在独立目录重跑 CMake + build + CTest。没有硬件采数、没有调频、没有改旧封存 DOCX/PDF、
没有改 M1 证据、没有 `git add`/`commit`/`push`。

占位符约定：锁频采数尚未回填处一律写 `«待主控数据»`。源文件（JSON/Markdown/HTML/SVG）里
就是这五个字加双尖括号；PDF 因中文字体渲染为 `「待主控数据」`（`report.tex` 中 48 处、
PDF 文本层 30 处，其余在表格重复表头处被 LaTeX 合并）。**占位符不是阴性，也不是未检出。**

## 1. 交付件与状态

| 交付件 | 路径 | 状态 |
|---|---|---|
| 报告正文（F02） | `deliverables/research/multi-leakage-platform-20261016/`（`report.md`、`report.tex`、`report.pdf`、`index.html`） | 13 章、6 张对照表、17 页 PDF、2 处 XeLaTeX 实际编译，0 Overfull |
| 平台矩阵图（F03） | `deliverables/research/platform-completion-20261016/figures/`（`platform-evidence-matrix.svg`、`.png`、`CAPTION.md`） | 3 分类带 × 5 列 × 5 行结果图，SVG 1492×912、PNG 2984×1824 |
| 离线 HTML + 匿名 ZIP（F04） | `index.html`（报告目录）与 `deliverables/support/CACR2026EA16XZ-multi-leakage-platform-20261016/CACR2026EA16XZ-platform-refresh-20261016.zip` | 758 成员、757 摘要、66 个本地 HTML 链接通过 |
| ZIP 解出复算（本轮新增必做） | `docs/evidence/platform-report-20261016/refresh-20261016/zip-recompute.log` | **CTest 5/5 通过、0 失败**（从 ZIP 解出，不是仓库本体） |
| 题面第 3/4/5 条对照表 | `report-tables.json` 的 T2/T3/T4，落在报告第 5/6/7 章 | 第 5 条为六类泄漏来源 × 4 个解封装步骤，共 7 行 × 5 列 |

## 2. 逐项命令与结果

### 2.1 报告与对照表（F02）

```sh
python3 deliverables/research/multi-leakage-platform-20261016/generate_report.py
```

结果：`{"sources": 18, "sections": 13, "tables": 6, "document_state": "structure_refreshed_20261016_pending_lead_statistics"}`。

本轮相对上一版的实质改动：

1. 新增第 4 章「检测—定位—修复—复测：四段链状态」与表 T1：逐模块给出检测、定位、修复/关闭、
   复测四段的实际执行范围，并区分「已执行且未检出」「已执行且检出」「未执行」「«待主控数据»」。
2. 新增第 5/6/7 章与表 T2/T3/T4，逐项对照官方题面第 3、4、5 条（题面原文取自
   `docs/reference/official-2026/A1-13-original.docx` 的 P17/P18/P19，本轮只读不改）。
3. 表 T4 覆盖题面第 5 条要求的六类泄漏来源 × 解密 / 重加密 / 比较 / 隐式拒绝四个步骤，
   每格写“查了什么工具或方法、结果如何”；KyberSlash 的秘密操作数除法不属于题面六类，
   单独列为第 7 行并明写“题面六类未单列”。
4. 新增表 T5「实测数字与证据对照」：15 行数字逐条给出仓库相对路径链接；新增表 T6
   `«待主控数据»` 占位符清单与回填来源。
5. 显式写入主控冻结的 Holm 家族口径：M2/M5 为主类对 × 3 次运行 × 2 版；M3/M4 为臂内主类对 ×
   3 次运行 × 2 臂 = m=6，跨臂 on/off 只作受控对照（含二进制级常数偏移）不进 Holm；
   RTLF α=.01 与 online dudect 一律族外。
6. 证据来源由 16 份增至 18 份，新增 E17（M1 锁频原始证据）与 E18（M1 开源检测器对照）。

### 2.2 PDF 编译与目视核验

```sh
xelatex -interaction=nonstopmode -halt-on-error -output-directory=build/platform-report-s8 \
  deliverables/research/multi-leakage-platform-20261016/report.tex   # 第一遍
xelatex -interaction=nonstopmode -halt-on-error -output-directory=build/platform-report-s8 \
  deliverables/research/multi-leakage-platform-20261016/report.tex   # 第二遍
```

原日志：`xelatex-refresh-first.log`、`xelatex-refresh-second.log`（两遍均 exit 0）。
结果：**17 页**，0 Overfull、1 Underfull（badness 1817，正文普通段落）、0 缺字、
0 hyperref PDF 字符串警告。表 T1 与 T4 使用横向页（`pdflscape`），避免 6 列/5 列宽表挤压。

逐页渲染（100 DPI）在 `render-refresh/page-01.png` … `page-17.png`；页码 4、5、10、11 为横向页。

### 2.3 平台矩阵图（F03）

```sh
python3 deliverables/research/platform-completion-20261016/figures/render_matrix.py
python3 deliverables/research/platform-completion-20261016/figures/render_preview.py
```

结果：`platform-evidence-matrix.svg` 1492×912（纯 `text` 元素，无 foreignObject）；
`platform-evidence-matrix.png` 2984×1824（2 倍像素）。数据源 `EVIDENCE_MATRIX.csv`
（5 行、3 个分类带、`audit_commit=ac46e62`），图注 `CAPTION.md`，视觉核验 `REVIEW.md`。

渲染器失败与替换（照实记录）：本机 Chrome headless 的 `--screenshot` 与 `--print-to-pdf`
在本次环境里只输出 GCM 报错、120–150 秒内不产出文件，因此改用 macOS QuickLook
（`qlmanage -t`）渲染正方形包装画布，再用 Pillow 裁回真实宽高；渲染器、版本与裁剪方式
记入 `RENDER_ENV.json`。图注明写**这是结果图，不是计划图**。

### 2.4 匿名 ZIP（F04）

```sh
python3 deliverables/support/CACR2026EA16XZ-multi-leakage-platform-20261016/build_support.py \
  --revision refresh-20261016
```

结果（`refresh-20261016-verification.json` 与 `package-verification.json`）：
**758 成员、757 个成员摘要、66 个本地 HTML 链接**、0 个直接身份字串、ZIP CRC 与路径检查通过。
ZIP SHA-256：`61759372cb82e8d3cbe10df909b1fb96fa1df11100d77243581a8786ed7565b4`。

保留的失败与修正：第一次成包在验证阶段失败，原因是报告离线 HTML 里的证据链接写成仓库根相对
路径 `docs/...`，在包内不存在（`missing HTML target: docs/platform/COMPLETION_REQUIREMENTS.md`）。
修正为报告目录相对路径 `../../../docs/...`，并在 `build_support.py` 中把包内
`report/index.html` 的 `href="../../../` 重写为 `href="../evidence/files/`（对应包内证据副本），
失败尝试的暂存目录与半成品 ZIP 已删除后重新成包。draft10/11/12 三个旧包保持原字节不动。

### 2.5 ZIP 解出后重新复算 CTest（本轮新增必做）

脚本：`run_zip_recompute.sh`；原日志：`zip-recompute.log`。解出根目录是本轮新建的
`build/zip-recompute-20261016/`，**不是仓库本体**。

```sh
rm -rf build/zip-recompute-20261016 && mkdir -p build/zip-recompute-20261016
unzip -q deliverables/support/CACR2026EA16XZ-multi-leakage-platform-20261016/CACR2026EA16XZ-platform-refresh-20261016.zip \
  -d build/zip-recompute-20261016
cmake -S build/zip-recompute-20261016 -B build/zip-recompute-20261016/build -DCMAKE_BUILD_TYPE=RelWithDebInfo
cmake --build build/zip-recompute-20261016/build --parallel 4
ctest --test-dir build/zip-recompute-20261016/build -N
ctest --test-dir build/zip-recompute-20261016/build --output-on-failure
```

结果：解出源码树 714 个文件（含构建产物共 1051 个），配置与构建 exit 0，
`ctest -N` 列出 5 项，实际执行 **5/5 通过、0 失败，总耗时 2.16 秒**：

| # | 测试 | 结果 |
|---|---|---|
| 1 | `support_stats_qualification` | Passed 1.47 s |
| 2 | `m4_vulnerable_self_test` | Passed 0.34 s |
| 3 | `m4_vulnerable_probe_smoke` | Passed 0.00 s |
| 4 | `m4_ct_self_test` | Passed 0.34 s |
| 5 | `m4_ct_probe_smoke` | Passed 0.00 s |

日志同时记录 6 份 `data/*.csv` 的 SHA-256、主机与工具版本、UTC 起止时间。
这是离线复算，不是新硬件实验；RTLF、Mona、dudect、Binsec 不在该入口重执行。

### 2.6 独立包审计、离线回放与校验器反例（CMD14）

```sh
python3 deliverables/research/multi-leakage-platform-20261016/audit_revision.py refresh-20261016
```

（该脚本本轮补了 `mkdir(exist_ok=True)`，以便写入已存在的 `refresh-20261016/`。）

结果：

- `pdf-metadata-audit.json`：17 页、作者字段为空、0 个直接私有标记、无文档级 JavaScript，
  PDF SHA-256 `bd9821ce92bbf5c7ec282abb528d03aec6a7715a9945afd9f9f4f09259d7efce`。
- `offline-replay.log` + `offline-reproduction.json`：只从实际 ZIP 解出后重建，CTest 5/5，
  6 份数据集回放、12 个 C 输出逐字一致、包内原始时间输入字节未变；
  新硬件采集 `not_run`，外部统计工具 `not_reexecuted`。
- `validator-rejection-tests.json`：校验器对摘要篡改、缺成员、目录越界、重复成员、远端资产、
  活动脚本、私有路径与坏锚点八种坏例全部拒绝。

## 3. 六类泄漏来源对照表是否齐

表 T4 共 7 行 × 5 列 = 35 格，题面六类各一行、四步各一列，另有 1 行补充（KyberSlash 秘密操作数除法）：

| 行 | 解密 | 重加密 | 比较 | 隐式拒绝 |
|---|---|---|---|---|
| 敏感条件分支 | M5 有限未检出 / 其余未执行 | **M1 真实案例阳性→官方修复消失** | M4 人工校准 32/1 对 0/0 | 功能与产物层已执行 |
| 提前返回 | 未执行 | 未执行 | **M4 人工校准阳性→归约消失** | 未执行（时间层） |
| 可变时间比较函数 | 未执行 | 未执行 | **M4 Memcheck + Binsec 两层已执行** | 未执行 |
| 数据相关循环 | 未执行 | 未执行 | 未执行（Binsec 有界不含循环次数对象） | 未执行 |
| 数据相关内存访问 | M5 有限未检出 | **M3 人工校准 1280/2 对 0/0** | 未执行 | M5 有限未检出 |
| 失败路径与异常处理 | 功能层已执行、时间层占位 | 功能层已执行、时间层占位 | 功能层已执行、时间层占位 | 功能层已执行、时间层占位 |
| 补充：秘密操作数除法 | **M2 真实案例 1 对 0** | **M2 真实案例 1 对 0** | 不适用 | 未执行 |

没有证据的格子一律写“未执行”，并给出最接近的相邻证据；`«待主控数据»` 只出现在时间层。

## 4. 占位符清单（等主控数字）

| 位置 | 需要的字段 |
|---|---|
| T1/T3/T4/T5 的 M2 行 | 每类 n、均值/SD/分位、Δ 与方向、CI、原始 p、family_id/Holm、RTLF α=.01、在线 dudect 预算/最大 t/state、三次运行条件与 restore_match |
| T1/T3/T4/T5 的 M3 行 | 臂内主类对 × 3 次运行 × 2 臂 = m=6 家族结果；跨臂受控对照常数偏移；RTLF 与在线 dudect |
| T1/T3/T4/T5 的 M4 行 | vulnerable/ct 各主类对 × 3 次运行的家族结果；RTLF；在线 dudect（族外） |
| T1/T3/T4/T5 的 M5 行 | 主类对 × 3 次运行 × 2 版家族；RTLF α=.01；原生 online dudect 批次/状态 |
| 第 8 章 Mona 段 | M2 新时间数据的 Mona 对照行（库/报告提交、输入映射、原输出） |
| 第 3 章频率与恢复段 | 进入/采中/退出频率记录、可见回读、`restore_match` 结果 |

回填方式（机械替换）：改 `report-tables.json` 与 `report-data.json` 里的 `«待主控数据»` 及对应
证据路径 → 重跑 `generate_report.py` → 两遍 `xelatex` → 重跑 `render_matrix.py`/`render_preview.py`
（若矩阵行有变）→ 用**新 revision** 重新成包（不覆盖 `refresh-20261016`）→ 对新包重跑
`run_zip_recompute.sh`。

## 5. 本轮没有做的事

- 没有 `git add`/`commit`/`push`；没有修改旧封存 DOCX/PDF；没有修改 M1 证据；
  没有 `sudo`；没有硬件采数、调频或隔离配置写入。
- 没有把仓库本体的构建冒充当次 ZIP 复算；没有把定位结果、软件资格或工具无报警写成统计结论。
- draft05/10/11/12 与旧报告载体保持原字节。

---

# 第二阶段：final-20261016（真实锁频数字回填后的终版包）

主控在 2026-10-16 02:30 交付 M2–M5 的真实锁频数字。回填前**逐项与证据文件核对**：
`docs/evidence/platform-collection-20261016/README.md`、`.../stats/holm/{RESULT.md,holm_summary.json}`、
`m2-kem-20261016/RESULT.md`、`m3-completion-20261016/{RESULT.md,LOCATE_RESULT.md}`、
`m4-completion-20261016/{RESULT.md,FORMAL_RESULT.md,MEASURE_V2.md}`、`m5-completion-20261016/RESULT.md`。
**没有一个数字是口头转述而未在文件中出现**；六项原始 p 值另与 `holm_summary.json` 逐项比对一致。

## F1. 数据与正文回填

更新 `report-data.json`（五模块 `software/localization/statistics/formal` 与摘要、来源增至 23 份、
`document_state=final_20261016_statistics_filled_rtlf_and_mona_pending`）与 `report-tables.json`
（T1 四段链、T2 题面第 3 条、T3 第 4 条、T4 六类 × 四步、T5 数字—证据 21 行、T6 剩余占位符），然后：

```sh
python3 deliverables/research/multi-leakage-platform-20261016/generate_report.py
```

新增来源：E19 锁频采数原件、E20 Holm 家族结果、E21 M3 定位复验、E22 M4 Binsec 形式化、
E23 M4 v2 采集件与口径。生成器第 2 行新增 `# -*- coding: utf-8 -*-`：本机无 locale 环境下
Python 3.9 的 tokenizer 会对含中文的源文件报 `Non-UTF-8 code`，显式声明后稳定（该文件不进包）。

回填的关键数字（均可在 T5 所指文件逐字核对）：M2 m=6 / Holm 拒绝 0 / Δ +4.58 ns CI [−3.08, +12.25] / I²=58.3%；
M3 m=6 / 0 / −0.73 ns [−5.56, +4.10] / 12.5%；M4 m=6 / **3（全在 vulnerable 臂）** / −3.74 ns
[−3.87, −3.62] / 98.6%；M5 m=3 / 0 / −5.30 ns [−11.77, +1.16] / 0%。口径按主控要求原样保留：
M2 定位阳性与端到端未检出分层；M4 的 insecure 只针对该夹具；M3/M4 明写人工构造校准；
M5 阴性只限本预算；RTLF 与 dudect 一律族外、最大 t 不转伪 p；“CI 含 0 且 Holm 不拒绝”＝未检出。

## F2. PDF 与目视核验

```sh
for round in 1 2; do xelatex -interaction=nonstopmode -halt-on-error \
  -output-directory=build/platform-report-s8 \
  deliverables/research/multi-leakage-platform-20261016/report.tex; done
cp build/platform-report-s8/report.pdf deliverables/research/multi-leakage-platform-20261016/report.pdf
pdftoppm -r 100 -png deliverables/research/multi-leakage-platform-20261016/report.pdf \
  docs/evidence/platform-report-20261016/refresh-20261016/render-final/page
```

结果：**22 页**，PDF SHA-256 `ee94ee847853a790cfc144b39072e7aabc3b3e4708fa0af0808aa146ddb3b20e`；
日志 `xelatex-final-first.log` / `xelatex-final-second.log`：**0 Overfull、0 Underfull、0 缺字、
0 hyperref 警告**。逐页渲染与 contact sheet 见 `render-final/`（横向页 5、6、11、12、13）。

修掉的两类版式缺陷（照实记录）：(a) 表格末列的 `[E06][E16]…` 连写超出列宽，改为 ID 间加空格；
(b) `≠`（U+2260）在 lmroman 缺字，映射为 `\texorpdfstring{$\neq$}{!=}`。

## F3. 平台矩阵图

```sh
python3 deliverables/research/platform-completion-20261016/figures/render_matrix.py
python3 deliverables/research/platform-completion-20261016/figures/render_preview.py
```

`EVIDENCE_MATRIX.csv` 的 M2–M5 行改为实际家族结果；SVG 1492×975、PNG 2984×1950；
`CAPTION.md`、`REVIEW.md`、`RENDER_ENV.json`、`SHA256SUMS` 同步；副标题与脚注改为
“M2–M5 已回填，`«待主控数据»` 只剩 RTLF、Mona 对 M2 行与 M2 微基准”，并保留“结果图不是计划图”。

## F4. 终版匿名包与解出复算

```sh
python3 deliverables/support/CACR2026EA16XZ-multi-leakage-platform-20261016/build_support.py \
  --revision final-20261016
sh docs/evidence/platform-report-20261016/refresh-20261016/run_zip_recompute_final.sh \
  > docs/evidence/platform-report-20261016/refresh-20261016/zip-recompute-final.log 2>&1
python3 deliverables/research/multi-leakage-platform-20261016/audit_revision.py final-20261016
```

- 包：**768 成员、767 摘要、93 个本地 HTML 链接、0 直接身份字串**；ZIP SHA-256
  `15f8e2e4c71cf0a093ea7b992d5008ede74623500fe1291e1ebbf49f66cf7799`。
- **解出复算：CTest 5/5 通过、0 失败（总耗时 2.06 s）**，解出到新建
  `build/zip-recompute-final-20261016/`；原日志 `zip-recompute-final.log`（111 行，含 ZIP 摘要、
  解出清单、CMake 配置与构建、`ctest -N`、逐项结果与 6 份 data CSV 的 SHA-256）。
- 独立审计（`docs/evidence/platform-report-20261016/final-20261016/`）：`pdf-metadata-audit.json`
  （22 页、作者空、0 私有标记、无文档级 JavaScript）、`offline-reproduction.json`
  （只从实包解出后重建，CTest 5/5，6 数据集回放、12 个 C 输出逐字一致、原始时间输入字节未变）、
  `validator-rejection-tests.json`（八种坏例全部拒绝）。
- 包内 report 负载与仓库副本逐字节一致（pdf、tables、data、snapshot、svg 五项摘要相同）。

保留的失败：第一次 `final-20261016` 成包在验证阶段被拒，原因是 T5 的复算日志行仍是
Markdown 链接、指向包内不存在的 `refresh-20261016/zip-recompute.log`；改为纯路径文本后重新成包，
失败尝试的暂存目录与半成品 ZIP 已删除。另有一次本记录文件自身的 heredoc 事故：追加本文的命令里
含示例用的 `PY` 结束行，提前结束了外层 heredoc，使后续示例行被 shell 执行（含一次失败的 xelatex、
一次无参数的 `build_support.py` 调用与一次复算重跑）。已核对：发布的 PDF、ZIP、包内负载摘要与
`final-20261016/` 审计产物均未被破坏；被清空的 `zip-recompute-final.log` 已重新实测生成；
本文件改用编辑工具写入，不再使用内嵌示例命令的 heredoc。

## F5. 剩余占位符（final-20261016 阶段）

数据位 3 处：T3 的 RTLF 状态、T5 的 RTLF 行、T5 的 Mona 对 M2 行（T6 清单列出这三项）。
它们**都不是阴性**；回填需新 revision 并重跑复算。（final2-20261016 阶段已回填 Mona，
只剩 RTLF 与 M2 微基准，见下。）

---

# 第三阶段：final2-20261016（Mona 对 M2 回填 + RTLF partial 状态）

主控在 2026-10-16 02:5x 交付 Mona 对 M2 的六份主类对结果与 RTLF 的部分状态。
**逐项核对**：`docs/evidence/mona-wire-20261016/RESULT.md`「本轮追加：M2 对照行」、
`native-v2/run/m2/{m2-mona.csv,m2-details.csv}`（两文件逐字读到与主控表格一致）；
RTLF 的两条退出码**只出现在主控消息中，仓库里没有对应原日志**（`docs/evidence/platform-rtlf-*`
不存在），因此报告中按“主控报告 + 原日志尚未落盘”归因书写，不写成已验证数字。

## G1. 回填内容与命令

```sh
# report-data.json：新增 E24（m2-mona.csv）、E25（m2-details.csv），document_state=final2_20261016_mona_filled_rtlf_partial
# report-tables.json：T5 的 Mona 行改为六份数据集实际状态；T5/T3 的 RTLF 改为 partial（进行中）；T6 去掉 Mona 行
python3 deliverables/research/multi-leakage-platform-20261016/generate_report.py
for round in 1 2; do xelatex -interaction=nonstopmode -halt-on-error \
  -output-directory=build/platform-report-s8 \
  deliverables/research/multi-leakage-platform-20261016/report.tex; done
cp build/platform-report-s8/report.pdf deliverables/research/multi-leakage-platform-20261016/report.pdf
pdftoppm -r 100 -png deliverables/research/multi-leakage-platform-20261016/report.pdf \
  docs/evidence/platform-report-20261016/refresh-20261016/render-final2/page
```

结果：**22 页**，PDF SHA-256 `eba21d09f7487bfd1144416022ea529563a84e21aea78a2e5b472271243465bd`；
日志 `xelatex-final2-first.log` / `xelatex-final2-second.log`：**0 Overfull、0 Underfull、0 缺字、
0 hyperref 警告**。

修掉的两处 LaTeX 错误（照实记录）：摘要里的 `partial/in_progress` 与 `not_run` 位于**未经过
tex_escape 的 raw 字符串**中，下划线触发 `Missing $ inserted`；改写为 `partial（进行中）` 与
`not\_run` 后通过。

## G2. Mona 对 M2 的实际结果（写入报告 §8 与表 T5）

六份主类对各一行、真实执行 exit 0：三个未修臂与 s1/s2 已修臂均 `no_validated_box_separation`
（0/9、0/9、0/9、0/7、0/9）；只有 s3 已修臂 `validated_box_separation`（1/8，`X<Y` 箱 0.27–0.34、
5120 值、子集数 1＝末轮单子集 100%），属该自适应实现「末轮只剩 1 个子集」的已知假阳性模式
（与 M1 两项 fixed 同型）。六批最高批次成功百分比 74/18/34/29/34/100。
`holm_member=false`；`Confidence Interval` 是批次成功百分比，不是 p 值或覆盖区间。
**不据此说两臂等价或恒时，不推翻 Welch CI + Holm / RTLF / dudect 结论，也没有把任何
RTLF/dudect 结果改称 Mona**；工具身份 mona-timing-report@4c74fb7e，六份原始 CSV 跑完后
sha256 6/6 未变。

## G3. RTLF 状态（族外，partial）

主控报告：`m2-s1-unfixed` 主类对退出码 **11 = difference_detected**、同数据集对照类对
退出码 **10 = no_difference_detected**；其余数据集仍在执行。报告里写成 **partial（进行中）**，
并明写「未完成不等于未检出，也不等于阴性」；同时保留口径句：
「RTLF α=0.01、二值结论、族外、不进 Holm；其 difference_detected 与 Welch/Holm 的均值判定
不冲突（RTLF 检验的是分布差异，不是均值差），两者分列不互相替代。」
**该两条退出码在本次刷新时没有仓库内原日志可核**，因此报告中的 T5 格仍标 `«待主控数据»`，
只把状态写成 partial；原日志落盘后按同一表格回填。

## G4. 终版包（final2）、复算与审计

```sh
python3 deliverables/support/CACR2026EA16XZ-multi-leakage-platform-20261016/build_support.py \
  --revision final2-20261016
sh docs/evidence/platform-report-20261016/refresh-20261016/run_zip_recompute_final2.sh \
  > docs/evidence/platform-report-20261016/refresh-20261016/zip-recompute-final2.log 2>&1
python3 deliverables/research/multi-leakage-platform-20261016/audit_revision.py final2-20261016
```

- 包：**772 成员、771 摘要、100 个本地 HTML 链接、0 直接身份字串**；ZIP SHA-256
  `2692d655ee42c4f2eff887d501b849d1ae15344d84f8300f2bff545763cee8ac`。
- **解出复算：CTest 5/5 通过、0 失败（1.82 s）**，解出到新建
  `build/zip-recompute-final2-20261016/`；原日志 `zip-recompute-final2.log`（111 行）。
- 独立审计（`docs/evidence/platform-report-20261016/final2-20261016/`）：PDF 元数据 pass
  （22 页、作者空、0 私有标记、无 JS）、离线回放 CTest 5/5 且 6 数据集 / 12 输出逐字一致、
  校验器八种坏例全拒；包内 report 负载与仓库副本五项摘要一致。

## G5. 剩余占位符与 not_run（final2）

`«待主控数据»` 数据位只剩 **2 处**：T3 的 RTLF 状态与 T5 的 RTLF 行（同一事项）；
`report.md` 全文件 8 次、`report-tables.json` 5 次、`index.html` 11 次、PDF 文本层同量级，
差额来自 T6 标题与 §1/§3/§13 的说明句。另有 **M2 微基准层**为 `not_run`（触发条件已满足），
在 T6 中单列。两者都不是阴性。

## G6. 环境清理

第二阶段 heredoc 事故在仓库根留下的 22 个 `\-01.png … \-22.png`（02:35，pdftoppm 前缀被破坏所致）
已按绝对路径逐个核对为本次事故产物后删除，仓库根不再有该前缀文件；其余文件未动。


---

# 第四阶段：final3-20261016（RTLF 42/42 与 M2 微基准层回填，占位符清零）

主控交付 `docs/evidence/platform-rtlf-20261016/`（RTLF 原日志）与
`docs/evidence/m2-kem-20261016/microbench-0551254c9579/RESULT.md`（M2 除法热点微基准层）。
回填前核对：`RTLF_RESULT.md` 的结果表与第 5 节逐数据集明细（30 项 exit 10 / 12 项 exit 11、
M2 主类对 6/6 检出且两臂都检出、M2 对照 6/6 未检出、M3 12/12、M5 6/6、M4 vulnerable 与截断
各 6/6 检出、ct 各 6/6 未检出）；微基准 `RESULT.md` 的家族表（m=6、Holm 拒绝 0、Δ +0.044 ns、
CI [−0.430, +0.517]、I²=68.7%、r01 未修 p=0.0416→校正 0.2495、六 run restore_match=yes）。

## H1. 回填内容

- `report-data.json`：新增 E26（RTLF_RESULT.md）、E27（微基准 RESULT.md）；M2 的 formal 字段与摘要
  改为三层写法（定位层阳性 / 除法热点微基准层未检出 / 完整解封装层未检出）；
  `document_state=final3_20261016_rtlf_and_microbench_filled`；剩余占位说明改为“已清空”。
- `report-tables.json`：T5 的 RTLF 行填 42/42 实数并新增“M2 除法热点微基准层”行；
  T3 的族外交叉状态填 RTLF 四类计数与逐模块方向；T1 的 M2 复测列、T4 的补充行与注释改三层写法；
  T6 改为“回填状态：已无 «待主控数据»”。**数据格中的占位符清零**（文件里剩 4 次均为
  “token 定义 / 已清空”这类元语句）。
- `generate_report.py`：§3 写入主控要求的五条 RTLF 读法（M4 与 Welch/Holm 同向＝独立印证；
  M2 两臂都检出→不可归因于除法变体、最一致读法是类构造＋未受控漂移、不据此作泄漏结论；
  二值族外不进 Holm、与均值判定分列；未检出≠恒时；不写“全部未检出”也不写“证明 M2 有泄漏”）；
  §9 写三层分层与微基准家族；§11 写 M5 的 RTLF 6/6 未检出；§13、摘要、§1 改为“已无占位符”。
  另修两处版式/渲染问题：Markdown 粗体在 PDF 中原样输出 `**`，改为 `\textbf{}`；
  报告内矩阵图副标题与图注去掉占位符表述（橙色只表示结构性未运行）。

## H2. PDF、图与包

```sh
python3 deliverables/research/multi-leakage-platform-20261016/generate_report.py
for round in 1 2; do xelatex -interaction=nonstopmode -halt-on-error \
  -output-directory=build/platform-report-s8 \
  deliverables/research/multi-leakage-platform-20261016/report.tex; done
cp build/platform-report-s8/report.pdf deliverables/research/multi-leakage-platform-20261016/report.pdf
pdftoppm -r 100 -png deliverables/research/multi-leakage-platform-20261016/report.pdf \
  docs/evidence/platform-report-20261016/refresh-20261016/render-final3/page
python3 deliverables/support/CACR2026EA16XZ-multi-leakage-platform-20261016/build_support.py \
  --revision final3-20261016
sh docs/evidence/platform-report-20261016/refresh-20261016/run_zip_recompute_final3.sh \
  > docs/evidence/platform-report-20261016/refresh-20261016/zip-recompute-final3.log 2>&1
python3 deliverables/research/multi-leakage-platform-20261016/audit_revision.py final3-20261016
```

- 报告 **23 页**，PDF SHA-256 `bd0ddf92d42b5cad32b27cfdc073cdb51c4ed925483900198426df528c0211af`；
  日志 `xelatex-final3-{first,second}.log`：**0 Overfull、0 Underfull、0 缺字、0 hyperref 警告**，
  PDF 文本层已无游离 `**`。
- 图：`EVIDENCE_MATRIX.csv` 的 M2 formal 改为微基准实测、M3/M4/M5 增 RTLF 证据路径；
  SVG 1492×975、PNG 2984×1950；CAPTION/REVIEW/RENDER_ENV/SHA256SUMS 同步为“已无占位符”。
- 包：**776 成员、775 摘要、108 个本地 HTML 链接、0 直接身份字串**；ZIP SHA-256
  `60deadaba9ef2b204a7cbf4fae2a915349b407667959762e2a6b3803b69b91e1`。
- **解出复算：CTest 5/5 通过、0 失败（1.94 s）**，解出到新建
  `build/zip-recompute-final3-20261016/`；原日志 `zip-recompute-final3.log`。
- 独立审计（`final3-20261016/`）：PDF 元数据 pass（23 页、作者空、0 私有标记、无 JS）、
  离线回放 CTest 5/5 + 6 数据集 + 12 输出逐字一致、校验器八种坏例全拒。

保留的失败：第一次 `final3` 成包被来源摘要检查拒绝（`RTLF_RESULT.md` 在我生成报告后又被
主控扩充了逐数据集明细），按设计先重跑 `generate_report.py` 刷新摘要再成包；失败的暂存目录已删除。
另在版式修复中两次触发 `Missing $ inserted`（未转义的 `not_run` 出现在 tex 的 raw 字符串里），
改写后通过。

## H3. 剩余占位符（final3）

**数据格 `«待主控数据»` = 0。** 文件里剩余的 4–7 次出现全部是“token 定义 / 已清空的说明 / T6 标题”，
不是待填数字。报告中仍标“未执行”的只有题面第 5 条结构性未做的单元格（如“数据相关循环”）。
---

# 第五阶段：final4-20261016（R03 族外对照与 R05 90 格排查表并入，M4 改为分臂引用）

本轮把两块已落盘的证据并进正式报告：`docs/evidence/r03-malformed-20261016/`（R03 格式破损 /
截断族外对照）与 `docs/R05-全流程排查表.md`（3 实现 × 5 步骤 × 6 类 = 90 格），并把 M4 的统计
引用从「家族窗口混臂合并 Δ」改成「只按臂引用」。**这两个来源文件本轮一个字节也没有改**
（`r03-malformed-20261016/` 与 `R05-全流程排查表.md` 的 sha256 在 `evidence-snapshot.json` 里
登记，`build_support.py` 会在成包前逐一复核；不一致就拒绝成包）。没有硬件采数、没有调频、
没有改旧封存证据与 M1 证据、没有 `git add`/`commit`/`push`。

## I1. 回填与改写内容

- `report-data.json`：新增来源 **E28**（R03 RESULT.md）、**E29**（R03 PLAN.md）、
  **E30**（`docs/R05-全流程排查表.md`）、**E31**（R03 `logs/status.log`），来源数 27 → **31**；
  `document_state=final4_20261016_r03_extra_family_and_r05_matrix_merged`；
  五个模块的陈旧字段 `statistics_pending`（原写“RTLF 与 Mona 待补”）改为“已清空…”；
  **M4 的 `statistics` 改为“Holm 拒绝 3/6（全在 vulnerable 臂）；vulnerable Δ −4.089 ns
  [−4.215, −3.963]；ct Δ +0.055 ns [−0.363, +0.473]（分臂；不引用混臂合并 Δ）”**。
- `report-tables.json`：新增 **T7**（对照 A，9×6）、**T8**（对照 B，9×6）、**T9**（族外 dudect，9×5）、
  **T10**（R05 90 格四类计数，4×6）、**T11**（5 个「存在」+ 1 个「未检查」，6×5，横向）；
  表 T3 的 CI 行与表 T5 的 M4 行改成 M4 分臂写法；表 T5 增 R03 三行与 R05 一行（共 33 行）；
  修掉 T3 表注与文件级 note 里“RTLF 与 Mona 仍待回填”的陈旧表述（数据格占位符本已为 0）。
- `generate_report.py`：新增第 8 章（R03）与第 9 章（R05），正文 13 → **15 章**、对照表 6 → **11 张**；
  §3 家族结果句删去 M4 混臂合并 Δ 并写明“只引用分臂数值”；§5/§7 各加一句指向第 8/9 节；
  §12 的复算入口与表 T5 的复算行改指 `zip-recompute-final4.log` 与 `final4-20261016/`；
  摘要、LaTeX 摘要与关键词同步；离线 HTML 页脚不再写“表内 «待主控数据» 表示尚未回填”。
- **R05 流程图**：新增 `r05_flowchart.py`，把 `docs/R05-全流程排查表.md` 第 5 节的 mermaid 代码块
  **按运行期实际读取**（`load_mermaid_source()` 正则取出代码块原文）渲染为等价静态图。
  PDF 用 `r05-flowchart.png`（`\includegraphics[width=0.94\textwidth]`，第 22 页）；
  离线 HTML 内联同一份 SVG **并把 mermaid 源码原样放进 `<pre>`**；`report.md` 直接内嵌该
  mermaid 代码块。图注写明“mermaid 源码原样保存在 docs/R05-全流程排查表.md 第 5 节”，
  四条修复边标签原样写进图注与图内页脚。
  静态图与 mermaid 的节点文字逐条对应（含 `:::leak`/`:::fix`/`:::art`/`:::pub` 四类配色，
  以及 M5 那个「公开信息、不可利用」的红色节点）；XeLaTeX 不能渲染 mermaid，这是等价渲染
  而不是把流程改写。

## I2. 命令与结果

```sh
python3 deliverables/research/multi-leakage-platform-20261016/generate_report.py
# → {"sources": 31, "sections": 15, "tables": 11,
#    "document_state": "final4_20261016_r03_extra_family_and_r05_matrix_merged"}
for round in 1 2; do xelatex -interaction=nonstopmode -halt-on-error \
  -output-directory=build/platform-report-s8 \
  deliverables/research/multi-leakage-platform-20261016/report.tex; done
cp build/platform-report-s8/report.pdf deliverables/research/multi-leakage-platform-20261016/report.pdf
pdftoppm -r 100 -png deliverables/research/multi-leakage-platform-20261016/report.pdf \
  docs/evidence/platform-report-20261016/render-final4/page
python3 deliverables/support/CACR2026EA16XZ-multi-leakage-platform-20261016/build_support.py \
  --revision final4-20261016
python3 deliverables/support/CACR2026EA16XZ-multi-leakage-platform-20261016/verify_package.py \
  deliverables/support/CACR2026EA16XZ-multi-leakage-platform-20261016/CACR2026EA16XZ-platform-final4-20261016.zip
sh docs/evidence/platform-report-20261016/refresh-20261016/run_zip_recompute_final4.sh \
  > docs/evidence/platform-report-20261016/refresh-20261016/zip-recompute-final4.log 2>&1
python3 deliverables/research/multi-leakage-platform-20261016/audit_revision.py final4-20261016
```

- 报告 **33 页**，PDF SHA-256 `570ab957bc50d6f8f79839eb946ad7a05eb03fd807b9f93175c7f6721b669c53`；
  日志 `xelatex-final4-{first,second}.log`：**两遍均 exit 0，0 Overfull、0 Underfull、0 缺字、
  0 hyperref 警告、0 LaTeX 警告**。逐页渲染 33 张 + `contact-sheet.png` 在 `render-final4/`，
  横向页为 5、6、11、12、13、15、16、19、20、21。
- 包：**784 成员、783 摘要、122 个本地 HTML 链接、0 直接身份字串**，`status=pass`；ZIP SHA-256
  `88395b6cc26f205c7d377808b0021f741203ed901603ff056c3379c07c8559f7`。
  包内新增 `evidence/files/docs/R05-全流程排查表.md`（含中文文件名的成员）与 R03 三份副本，
  以及 E28–E31 四个查看页；`package-verification.json` 落在 `final4-20261016/`。
- **解出复算：CTest 5/5 通过、0 失败（2.06 s）**，解出到新建
  `build/zip-recompute-final4-20261016/`；原日志 `zip-recompute-final4.log`。
- 独立审计（`final4-20261016/`）：PDF 元数据 pass（33 页、作者空、0 私有标记、无 JS）、
  离线回放 CTest 5/5 + 6 数据集 + 12 输出逐字一致、校验器八种坏例全拒；
  包内 report 负载与仓库副本 pdf/tex/tables/data/snapshot/svg 六项摘要一致
  （`report.md` 与 `report/index.html` 按设计做匿名文本转换与链接重写）。

## I3. 本轮踩到的坑（照实记录）

1. **`\path{}` 遇到中文路径会缺字**。来源索引用 `\path{docs/R05-全流程排查表.md}` 输出路径，
   `\path` 走 `\ttfamily`（lmmono10），该字体没有 CJK 字形，日志出现 6 次
   `Missing character: There is no 全 (U+5168) in font [lmmono10-regular]`。修法：纯 ASCII 路径
   仍用 `\path{}`，非 ASCII 路径改走 `tex_escape`（长 ASCII 片段照旧进 `\texttt{\seqsplit{}}`）。
2. **不可断行的长 token 造成 Overfull**。§9 段落里写成 `` `control-flow,memory-access` ``，
   28 个字符无法断行，出现 1 处 `Overfull \hbox (9.07pt too wide)`（`\emergencystretch` 对这种
   盒子无效）。改写为「control-flow 与 memory-access 两项」后消失。
3. **`\noindent` 与路径直接拼接**。改用 `path_tex` 变量后拼出 `\noindentdocs/…`，
   触发 `! Undefined control sequence`（两遍都 exit 1，但 PDF 仍被写出——**看到 PDF 有更新
   不等于编译成功，必须看日志与退出码**）。补一个空格后 exit 0。
4. **本轮这三处失败的中间日志没有单独归档**：xelatex 输出重定向到固定文件名
   `xelatex-final4-{first,second}.log`，重试时被覆盖。失败内容与修法如实记在上面，
   最终两遍日志的 `^!`、`Missing character`、`Overfull`、`Underfull`、hyperref 计数已复核为 0；
   这里是流程上的一个偏离（“失败先归档再重试”），下次改用具名失败日志。
5. **T11 单元格里的反引号**：第一版把 `` `16e: bt %ecx,%r8d` `` 这类写法直接放进表格单元，
   PDF 里满格反引号很吵，已在 T11 全部去掉（正文保留少量反引号，与既有章节写法一致）。
6. **改完表格要重跑生成器再编译**：T11 去反引号后 PDF 的 SHA-256 变化（
   `abfd9218…` → `570ab957…`），最终发布值以最后一次两遍编译的副本为准；
   `final4-20261016/pdf-metadata-audit.json` 与 `RESULT.md`/`VISUAL_QA.md` 三处必须同值。

## I4. 本轮没有做的事

- 没有 `git add`/`commit`/`push`（提交由主控统一完成）；没有 `sudo`、硬件采数、调频或隔离写入。
- 没有改 `docs/evidence/r03-malformed-20261016/`、`docs/R05-全流程排查表.md`、旧封存证据、
  M1 证据或任何 `final{,2,3}-20261016`、`refresh-20261016`、draft10/11/12 的原字节。
- 没有把 R03 的族外对照并入 Holm，没有把截断路径的接口语义写成“泄漏”，没有把 R05 的
  「不存在」写成恒时证明，也没有把 M5 那个只携带公开信息的早退写成可利用缺陷。
- 没有在包内重新执行 RTLF、Mona、dudect 或 Binsec（复算入口只重建 C11 统计工具并跑五项 CTest）。

---

# 第六阶段：final5-20261016（T31 报告整合：题面 12 条逐条并入 + 附录 A 对照矩阵 + 威胁模型章）

本轮把 T31 要求的所有收尾证据并进正式报告，并新增**附录 A「题面 12 条对照矩阵」**。
报告的章节顺序按题面条款重排（15 → 25 节），对照表 11 → **26 张**，来源 31 → **60 份**，
页数 33 → **91 页**。没有硬件采数、没有调频、没有改旧封存证据与 M1 证据、
没有 `git add`/`commit`/`push`。`docs/evidence/r03-malformed-20261016/` 与
`docs/R05-全流程排查表.md`、`docs/evidence/r11-threat-20261016/threat-model.tex`
**一个字节也没有改**（生成器只读它们；R05 的 mermaid 与 90 格计数都按运行期实读）。

## J1. 新增章节与表

| 节 | 题目 | 表 |
|---:|---|---|
| 4 | 题面第 1 条：向量来源与修复语义等价 | T12、T13 |
| 5 | 题面第 2 条：测量环境、异常样本规则与稳健性 | T14、T15 |
| 9 | 题面第 4 条补充：功效 / MDE、分位数差与分布图 | T16、T17 |
| 12 | 题面第 6 条：修复手段映射与泄露渠道审计 | T18、T19 |
| 14 | 题面第 8 条：性能开销表 | T20、T21 |
| 15 | 题面第 9 条：优化级别对照与跨环境范围 | T22 |
| 16 | 题面第 12 条：创新对照（锁频 vs 不锁频、多工具矩阵） | T23、T24 |
| 17 | 题面第 11 条：一键复现与复现参数总表 | T25 |
| 18 | 威胁模型（题面第 10 条，直接 `\input{}` 片段） | 片段自带 5 张表 |
| 25 | 附录 A：题面 12 条对照矩阵 | T26 |

表 T10/T11 按 `docs/R05-全流程排查表.md` 本体的新计数改写：**存在 5 / 不存在 75 /
不适用 10 / 未检查 0**（原唯一的「未检查」格已补做并改判为「存在」）；
T11 的行数 6 → 5，表题改为「5 个『存在』格清单（『未检查』已为 0）」。

## J2. 命令与结果

```sh
python3 deliverables/research/multi-leakage-platform-20261016/emit_final5_tables.py
# → {"new_tables": [T12..T26], "mapping_rows": 16, "perf_summary_rows": 25,
#    "perf_comparison_rows": 11, "optlevel_rows": 12, "sources": 60}
python3 deliverables/research/multi-leakage-platform-20261016/generate_report.py
# → {"sources": 60, "sections": 25, "tables": 26,
#    "document_state": "final5_20261016_full_clause_matrix_and_report_consolidation",
#    "forbidden_token_hits": 0}
export SOURCE_DATE_EPOCH=1792080000 FORCE_SOURCE_DATE=1
for round in 1 2; do xelatex -interaction=nonstopmode -halt-on-error \
  -output-directory=build/platform-report-s8 \
  deliverables/research/multi-leakage-platform-20261016/report.tex; done
cp build/platform-report-s8/report.pdf deliverables/research/multi-leakage-platform-20261016/report.pdf
pdftoppm -r 100 -png deliverables/research/multi-leakage-platform-20261016/report.pdf \
  docs/evidence/platform-report-20261016/final5-20261016/render/page
```

- 报告 **91 页**，PDF SHA-256
  `d391114c9269b0c0ed463e06f3fed38a1cbded783be81590b7ae18151960db20`；
  日志 `xelatex-final5-first.log` / `xelatex-final5-second.log`：**两遍均 exit 0、均 91 页、
  0 Overfull、0 Underfull、0 缺字、0 hyperref 警告、0 LaTeX 警告**。
- **PDF 可复现**：`SOURCE_DATE_EPOCH=1792080000 FORCE_SOURCE_DATE=1` 下两遍输出字节相同，
  因此归档日志与发布的 PDF 严格对应（此前各轮的 PDF 会因内嵌创建时间而逐次不同）。
  发布哈希 `d391114c…` 在 `final5-20261016/pdf-metadata-audit-repo-copy.json`、
  `RESULT.md`、`VISUAL_QA.md` 与本文件四处同值。
- 逐页渲染 91 张 + `contact-sheet.png` 在 `final5-20261016/render/`；
  横向页为 5–8、13–14、20–21、24–26、29–30、33–38、42–43、46–49、51–53、55–57、77–87。
- `final5-20261016/pdf-metadata-audit-repo-copy.json`：`status=pass`、91 页、作者空、
  0 私有标记、无文档级 JavaScript。
- **`audit_revision.py` 本轮未运行**：该脚本第一步就要读匿名 ZIP（`verify_package.py` →
  解包 → 包内 `report/report.pdf` → 包内 `reproduce.sh` 离线回放 → 校验器反例），
  实测运行得到 `verify_package.py …-platform-final5-20261016.zip` 返回非 0、脚本
  在 `subprocess.check_output` 处抛 `CalledProcessError`、整体 exit 1，且没有写出
  任何审计产物。按主控安排由主控另跑；本轮只做了不依赖 ZIP 的
  **PDF 元数据审计**（直接审计仓库副本），并在结果文件里写明包内审计未执行。

## J3. 本轮踩到的坑（照实记录，含失败归档）

1. **占位符 key 被当成 ASCII 长 token**。为消掉两处 Overfull 把 `tex_escape` 的长 token
   阈值从 18 降到 15，结果 `p=1.30×10⁻⁵` 先被换成 `@@MATH0@@`、整串 `p=1.30@@MATH0@@`
   恰好 15 字符，于是 `\texorpdfstring{$\times 10^{-5}$}{x10^-5}` 被塞进
   `\texttt{\seqsplit{…}}` 里，`$` 落在 `\texttt` 内触发 18 处 `! Missing $ inserted` /
   `! Extra }, or forgotten $`，并连带 44 次 `Missing character`、页数掉到 69 页。
   **修法**：占位符 key 改用私用区字符 `\ue000<index>\ue001`（既不在长 token 字符类里，
   也不会被转义），阈值恢复 18。**教训**：`tex_escape` 的两趟替换有顺序耦合，
   改阈值前必须先隔离占位符。
2. **表格里的 Markdown 残留**。表 T18 逐行取自 `MAPPING.md`，原样带进反引号（PDF 里显示成
   成对引号）与 `[标签](../相对路径)`（展开后是很长的相对路径），造成 2 处 Overfull。
   **修法**：渲染时把链接降级为标签、去掉反引号；并在「长标识符 + 左括号」之间插一个空格
   给 TeX 一个断行点（语义不变）。
3. **不可断行 token**。`holm_member=false`（17 字符，刚好卡在阈值 18 以下）与
   `mlk_ct_sel_int16(MLKEM_Q_HALF, …`（括号让长 token 匹配断开）各造成 1 处 Overfull。
   **修法**：前者改写为「holm_member 为 false」，后者留空格。
4. **缺字**：`⇒`、`↔`、`β`、`⁴` 在 lmroman 没有字形、也不在 `MATH_REPLACEMENTS` 里，
   第一遍出现 4 类缺字。**修法**：四个字符加入映射表。
5. **只读片段的 Underfull**：`threat-model.tex` 在默认排版参数下自身产生 **8 处 Underfull**，
   而该文件是证据、不能改字节。**修法**：只在其外层加
   `\begingroup\sloppy\hbadness=2000 … \endgroup`（`\sloppy` 先把 8 处真实降到 2 处，
   badness 1655 / 1014；剩下 2 处用该分组内的报告阈值不再告警）。为区分责任，
   另做了一次**去掉该 `\input` 的对照编译**：本报告自身段落 **0 Overfull / 0 Underfull / 0 缺字**。
   这条口径同时写进 `VISUAL_QA.md` 与 `RESULT.md`，不把「阈值提高」说成「没有 Underfull」。
6. **近乎空白的第 2 页**：摘要变长后 `\vfill` 把「版本性质」一行推到第 2 页。**修法**：
   删去与新摘要重复的第二段摘要、`\vfill` 改固定间距，摘要整段回到第 1 页（90 → 90 页，
   但去掉了那一页）。
7. **附录导语的 2 行尾页**：附录的表是 `landscape`、必然分页，导语的后 2 行独占一页。
   **修法**：以「附录」开头的节也从新页开始，标题与导语同页。
8. **失败日志已按新约定归档**：第一次编译（4 Overfull、2 Underfull、4 类缺字）的日志存为
   `xelatex-final5-first-attempt1-failed.log`，不被后续重试覆盖。上一轮记录的流程偏离
   （失败日志被覆盖）本轮已修正。

## J4. 数据一致性：来源文件与本轮归档之间发现四处不一致

本轮逐条打开证据文件核对时发现三处**文件表述**不一致，另有一处**归档与文稿的时间差**。
**本报告不改判**，按可核的一侧引用，并把四处写进报告第 24 节与 `RESULT.md`，供主控决定是否回改来源文件：

1. `docs/evidence/r06-noleak-20261016/MAPPING.md`：§1 表格实际 **16 个数据行**
   （M1 三、M2 三、M3 四、M4 两、M5 四），§2 却自述「表内行数 15」，
   且其 6 + 5 + 4 的分组算术与自身表格不符。报告按 **16 行**引用。
2. `docs/evidence/r04-stats-20261016/POWER.md`：§1 已更正 M1 主类对属于预注册 Holm 家族
   （m = 6、α_eff = 0.008333），§5 的家族列仍把 M1 标为「族外」。报告采用 **§1 的更正口径**
   （MDE 25.2709 / 31.3901 ns），不引用 §5 的陈旧表述。
3. 「M5 × 可变时间比较」4 格：`docs/R05-全流程排查表.md` 本体按产物 + 源码判「**不存在**」，
   而 `BLOCKERS.md` 第 1 条把这一情形描述为「**工具不适用型 unknown**」。
   报告按 R05 本体的结论与计数（存在 5 / 不存在 75 / 不适用 10 / 未检查 0）引用，
   并在第 24 节保留该工具侧边界（varlat 面向可变时延指令，而该实现从上游起不用 `div`）。

4. **归档与文稿的时间差（本轮写作期间发生）**：05:10 前后 R08 / R09 的控制器目录被补入归档
   （`docs/evidence/r08-perf-20261016/remote/R08/<run>/controller/` 共 54 个、
   `docs/evidence/r09-optlevel-20261016/remote/R09/<run>/controller/` 共 36 个，含
   `terminal.json`、`entry-probes.json`、`during.json`），而 `PERF.md`（05:08）与 R09 的
   `RESULT.md`（05:09）仍写着「副本只有 CSV 与 meta」「没有 controller 目录」。
   直接读取原始 `terminal.json` 计数为 **R08 54/54、R09 36/36 四判据全部通过**
   （`restore_match=yes`、`worker_exit_code=0`、`worker_drained=true`）。
   处理：**当作补充登记**写进报告 §15 与表 T21 的表注，新增 E59/E60 两个代表文件作证据路径，
   并在报告第 24 节登记该时间差；**没有改写 `PERF.md` / `RESULT.md` 的任何数值与结论**。
   两文件已于 `6c10f4d` 同步更新，报告也已在 `e6b35cf` 重新生成——生成后 `evidence-snapshot.json` 的 60 份来源实测 **0 stale**，重出的 PDF 与修正前**逐字节相同**（`d391114c…`），因此"报告与来源同字节"这条成立；留此条仅为记录当时的时间差。原文如下：两文件同步更新后应回填并重新生成报告——届时 `evidence-snapshot.json` 里的来源摘要会变化，
   `build_support.py` 会拒绝用旧包（属预期行为）。

## J5. 本轮没有做的事

- 没有 `git add`/`commit`/`push`；没有 `sudo`、硬件采数、调频或隔离写入。
- 没有改 `docs/evidence/r03-malformed-20261016/`、`docs/R05-全流程排查表.md`、
  `docs/evidence/r11-threat-20261016/threat-model.tex`、旧封存证据、M1 证据，
  或 `final{,2,3,4}-20261016`、`refresh-20261016`、draft10/11/12 的原字节。
- 没有成包、没有跑 `audit_revision.py`、没有解出复算；报告内引用的解出复算产物仍是
  最后一次实际执行的 `final4-20261016`（表 T5 与第 17 节都写明了这一点）。
- 没有把「未执行」写成阴性，没有把人工夹具写成真实 CVE，没有把锁频写成恒时证明。
