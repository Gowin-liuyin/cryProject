# S8 报告、图、离线 HTML 与匿名包：2026-10-16 终版快照

状态：**全部实测数字已回填（含 RTLF 族外交叉 42/42 与 M2 除法热点微基准层）；报告（23 页）、
平台矩阵图、离线 HTML 与匿名 ZIP 已出终版 `final3-20261016` 并通过实包解出复算（CTest 5/5）。
报告数据格中的 `«待主控数据»` 为 0；仍标“未执行”的只有题面第 5 条结构性未做的单元格。**
本轮没有硬件采数、调频、远端操作或密码实验；旧报告、旧展示、旧支撑包及原证据保持原字节。

## 报告载体（F02）

- 当前 PDF 为 **23 页**（权威值见 `final3-20261016/pdf-metadata-audit.json` 的 `pages`）：`deliverables/research/multi-leakage-platform-20261016/report.pdf`，
  SHA-256 `bd0ddf92d42b5cad32b27cfdc073cdb51c4ed925483900198426df528c0211af`。
- 正文 13 章、**6 张对照表**、27 份来源；`report.md`、`report.tex`、`index.html`、
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
- M2–M5 的锁频端到端家族统计已回填：M2 m=6 / Holm 拒绝 0 / Δ +4.58 ns CI [−3.08, +12.25] / I²=58.3%；
  M3 m=6 / 0 / −0.73 ns [−5.56, +4.10] / 12.5%；M4 m=6 / 3（全在 vulnerable 臂）/ −3.74 ns / 98.6%；
  M5 m=3 / 0 / −5.30 ns [−11.77, +1.16] / 0%。原始 p 值与 `stats/holm/holm_summary.json` 逐项核对。
- Mona 对 M2 六份主类对已回填（三个未修臂与 s1/s2 已修臂无通过验证的箱体分离；s3 已修臂一次
  末轮单子集 100%），`holm_member=false`。
- RTLF 族外交叉 42/42 已回填：`no_difference_detected` 30 项、`difference_detected` 12 项；
  M4 与 Welch/Holm 同向（vulnerable 含截断 6/6 检出、ct 6/6 未检出）；M2 主类对 6/6 检出但两臂
  都检出（不可归因于除法变体，最一致读法是类构造＋未受控漂移，不据此作泄漏结论）；M3 12/12、
  M5 6/6 未检出；二值结论族外、不进 Holm。
- M2 除法热点微基准层已从 not_run 改为实测：家族 m=6、Holm 拒绝 0、Δ +0.044 ns、
  CI [−0.430, +0.517]、I²=68.7%；分层写法＝定位层阳性 / 热点微基准层未检出 / 完整解封装层未检出。
- XeLaTeX 两遍实际编译：**0 Overfull、0 Underfull、0 缺字、0 hyperref 警告**。
  逐页渲染与核验见 [VISUAL_QA.md](VISUAL_QA.md) 与 `refresh-20261016/render-final/`。
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
`deliverables/support/CACR2026EA16XZ-multi-leakage-platform-20261016/CACR2026EA16XZ-platform-final3-20261016.zip`。
SHA-256：`60deadaba9ef2b204a7cbf4fae2a915349b407667959762e2a6b3803b69b91e1`。
**776 个成员、775 个成员摘要、108 个本地 HTML 链接**通过；此前 `final-20261016`（`15f8e2e4…`）
与 `final2-20261016`（`2692d655…`）保持原字节。ZIP CRC、唯一成员、路径、无符号链接、
直接私有路径、活动内容与远端依赖检查通过。作者字段为空，PDF 解压文本与元数据未命中本项目
直接身份字串（匿名检查不承诺公开内容无法关联作者）。

**从该实际 ZIP 解出后**，在新建目录 `build/zip-recompute-final3-20261016/` 独立重跑
`cmake -S … -B …/build`、`cmake --build … --parallel 4`、`ctest --output-on-failure`：
**CTest 5/5 通过、0 失败（总耗时 1.94 s）**（`support_stats_qualification` 1.17 s、两组 M4 self-test
各 0.35 s 与 0.41 s、两个 probe smoke 各 0.00 s）。确切命令、环境、解出清单与逐项结果见
[refresh-20261016/zip-recompute-final3.log](refresh-20261016/zip-recompute-final3.log)，逐项命令汇总见
[refresh-20261016/REFRESH.md](refresh-20261016/REFRESH.md)（含第一阶段 refresh-20261016 的记录）。**没有用仓库本体的构建充当本次复算。**

独立包审计（`audit_revision.py final3-20261016`，产物在 [final3-20261016/](final3-20261016/)）另给：`pdf-metadata-audit.json`（23 页、
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
`document_state=final3_20261016_rtlf_and_microbench_filled`：M2–M5 锁频家族统计、频率/恢复记录、
Mona 对 M2 对照、RTLF 族外交叉（42/42）与 M2 除法热点微基准层均已回填；**数据格占位符为 0**，
报告中仍标“未执行”的只有题面第 5 条结构性未做的单元格（见报告表 T6）。
未 stage、commit 或 push。
