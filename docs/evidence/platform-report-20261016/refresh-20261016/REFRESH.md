# F02/F03/F04 刷新记录（2026-10-16，本机 macOS/ARM）

本轮把报告正文、平台矩阵图、离线 HTML、匿名 ZIP 刷新到当前状态，并**从实际 ZIP 解出后**
在独立目录重跑 CMake + build + CTest。没有硬件采数、没有调频、没有改旧封存 DOCX/PDF、
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
