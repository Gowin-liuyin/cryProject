# S8 报告、图、离线 HTML 与匿名包：2026-10-16 刷新快照

状态：**报告正文、平台矩阵图、离线 HTML 与匿名 ZIP 已刷新并通过实包复算；
M2–M5 锁频时间统计待主控采数回填（占位符 `«待主控数据»`）。**
本轮没有硬件采数、调频、远端操作或密码实验；旧报告、旧展示、旧支撑包及原证据保持原字节。

## 报告载体（F02）

- 当前 PDF 为 **17 页**：`deliverables/research/multi-leakage-platform-20261016/report.pdf`，
  SHA-256 `bd9821ce92bbf5c7ec282abb528d03aec6a7715a9945afd9f9f4f09259d7efce`。
- 正文 13 章、**6 张对照表**、18 份来源；`report.md`、`report.tex`、`index.html`、
  `platform-matrix.svg`、`report-tables.json`、`evidence-snapshot.json` 同时生成。
- 新增第 4 章「检测—定位—修复—复测：四段链状态」（表 T1），第 5/6/7 章为题面第 3/4/5 条
  逐项对照（表 T2/T3/T4），第 12 章为「实测数字—证据对照」（表 T5，15 行带仓库相对路径链接），
  第 13 章为 `«待主控数据»` 占位符清单（表 T6）。
- 表 T4 覆盖题面第 5 条的六类泄漏来源 × 解密 / 重加密 / 比较 / 隐式拒绝四个步骤，
  每格写“查了什么工具或方法、结果如何”；KyberSlash 的秘密操作数除法不属于题面六类，
  单独列为补充行。没有证据的格子写“未执行”，时间层未回填的写 `«待主控数据»`。
- Holm 家族口径已写入正文第 3 章：M2/M5 为主类对 × 3 次运行 × 2 版；M3/M4 为臂内主类对 ×
  3 次运行 × 2 臂 = m=6，跨臂 on/off 只作受控对照（含二进制级常数偏移），不进 Holm；
  RTLF α=.01 与 online dudect 一律族外。
- XeLaTeX 两遍实际编译：0 Overfull、0 缺字、0 hyperref 警告；1 条普通段落 Underfull。
  逐页渲染与核验见 [VISUAL_QA.md](VISUAL_QA.md) 与 `refresh-20261016/render-refresh/`。
  此前 draft10/draft12 的 6 页版本及核验按各自目录原件保留，不被本文件覆盖。

## 平台矩阵图（F03）

`deliverables/research/platform-completion-20261016/figures/`：`platform-evidence-matrix.svg`
（1492×912，纯 text 元素）+ `platform-evidence-matrix.png`（2984×1824，2 倍像素）+
`CAPTION.md`（图注与每格证据路径）+ `../EVIDENCE_MATRIX.csv`（机器可读，含 3 个分类带）。
图分「真实历史案例 / 人工构造校准 / 阴性对照候选」，逐格显示各层状态，并明写**这是结果图，
不是计划图**。渲染器、版本与裁剪方式见 `RENDER_ENV.json`（Chrome headless 在本环境不产出
文件，改用 QuickLook + Pillow 裁剪，失败过程照实记录）。

## 匿名包与实包复算（F04）

当前匿名快照：
`deliverables/support/CACR2026EA16XZ-multi-leakage-platform-20261016/CACR2026EA16XZ-platform-refresh-20261016.zip`。
SHA-256：`61759372cb82e8d3cbe10df909b1fb96fa1df11100d77243581a8786ed7565b4`。
**758 个成员、757 个成员摘要、66 个本地 HTML 链接**通过；ZIP CRC、唯一成员、路径、无符号链接、
直接私有路径、活动内容与远端依赖检查通过。作者字段为空，PDF 解压文本与元数据未命中本项目
直接身份字串（匿名检查不承诺公开内容无法关联作者）。

**从该实际 ZIP 解出后**，在新建目录 `build/zip-recompute-20261016/` 独立重跑
`cmake -S … -B …/build`、`cmake --build … --parallel 4`、`ctest --output-on-failure`：
**CTest 5/5 通过、0 失败**（`support_stats_qualification` 1.47 s、两组 M4 self-test 各 0.34 s、
两个 probe smoke 各 0.00 s）。确切命令、环境、解出清单与逐项结果见
[refresh-20261016/zip-recompute.log](refresh-20261016/zip-recompute.log)，逐项命令汇总见
[refresh-20261016/REFRESH.md](refresh-20261016/REFRESH.md)。**没有用仓库本体的构建充当本次复算。**

独立包审计（`audit_revision.py refresh-20261016`）另给：`pdf-metadata-audit.json`（17 页、
作者空、0 直接私有标记、无文档级 JavaScript）、`offline-replay.log` 与
`offline-reproduction.json`（只从实包解出后重建，CTest 5/5，6 份数据集回放、12 个 C 输出
逐字一致、包内原始时间输入字节未变；外部 RTLF/Mona/dudect/Binsec 未在该入口重执行）、
`validator-rejection-tests.json`（摘要篡改、缺成员、目录越界、重复成员、远端资产、活动脚本、
私有路径与坏锚点八种坏例全部拒绝）。

## 包装边界与保留失败

时间输入 CSV 原字节保留。Mona `box-results.csv` 等含路径字段的文件只在新副本中转换路径、
保留数值，并记录原件与副本两套摘要。许可未明确的 RTLF/Mona/ctgrind 源码或 JAR、构建 ELF、
私钥、凭证与缓存均未再分发；旧原始档案中的 AppleDouble 隐藏元数据不进入新包。

保留的失败记录：draft05 首次实包提取暴露 Python `extractall` 不保留执行位，导致统计脚本
permission denied，新包 CMake 显式恢复所需执行位；本轮首次成包在验证阶段失败，原因是报告
离线 HTML 的证据链接写成仓库根相对路径 `docs/...`，包内不存在，改为报告目录相对
`../../../docs/...` 并在成包时重写为包内证据副本路径后重新成包，失败尝试的暂存目录与
半成品 ZIP 已删除，draft10/11/12 三个旧包保持原字节。

生成器会拒绝证据来源在报告生成后变化的打包操作，要求先刷新来源摘要。
`document_state=structure_refreshed_20261016_pending_lead_statistics` 保留，等待主控回填
M2–M5 锁频统计、Mona 对 M2 新数据的对照行与频率/恢复记录后再出最终版本。
未 stage、commit 或 push。
