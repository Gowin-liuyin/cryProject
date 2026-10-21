# 多泄漏平台新补充报告（2026-10-20 P2 收尾版）

本目录为独立的新报告载体，旧正式报告、旧展示、draft10/11/12、refresh-20261016、final-20261016、final2-20261016、final3-20261016、final4-20261016 旧包保持原字节。
当前状态：**全部实测数字已回填（含 RTLF 族外交叉 42/42 与 M2 除法热点微基准层），并已并入
R03 格式破损 / 截断族的族外对照与 R05 全流程六类来源排查表（90 格）；题面第 3/4/5 条对照表、
矩阵图、离线 HTML 与匿名 ZIP 已出终版**。报告数据格中已无 `«待主控数据»`，仍标"未执行"的
只有题面第 5 条结构性未做的单元格；文稿存在不替代平台验收。

当前已核验副本为 [97 页 PDF](report.pdf) 与 [离线展示](index.html)，绑定 70 份实际来源、
25 章正文、26 张表。M2/M3/M5 的端到端家族 Holm 拒绝 0、M4 拒绝 3 项且全在
vulnerable 臂（**M4 只引用分臂数值**：vulnerable Δ −4.089 ns、ct Δ +0.055 ns）；族外 dudect、
RTLF 与 R03 破损对照一律不进 Holm。实包解出后的 CTest 复算为 5/5（见
[refresh 记录](../../../docs/evidence/platform-report-20261016/refresh-20261016/REFRESH.md)）。

**本轮（2026-10-20）更新**：题面 12 条由 11 满足 + 1 部分改为 **10 满足 + 2 部分**（2026-10-21 第 6 轮逐字对照复核后：第 6、7 条按实际证据降为「部分」）——R06 的低危发现 F1
已闭合（M2 采集件新增 `--self-test` 显式功能门模式，计时模式 stderr 恒空、退出码与内部比较结果无关，
static-scan B 类由 1 条降为 0 条，见
[F1 修复验证](../../../docs/evidence/r06-noleak-fix-20261020/AUDIT.md) §7）；R09 统计改为逆方差固定效应
合并 CI（新增「合并 Δ_pool」列，m1unfixed-Os 为 −26.16 [−37.51, −14.81] 不含 0，m1fixed-O0 与
m1fixed-O3 的合并 CI 均含 0）；R08/R09 控制器目录口径更新为 54/54 与 36/36 全部归档并补上实测周期换算核对表；
新增三台机器的 WSL 跨环境复现归档与一致性核对
（[CROSSCHECK](../../../docs/evidence/wsl-repro-20261020/CROSSCHECK.md)）。**本目录是支撑材料卷**，
主报告载体是根目录的[官方作品设计报告](../../../CACR2026EA16XZ-作品设计报告.docx)。

**同日 P1 级补强（95 页版本的来源）**：

1. **M2 叙事提炼**（报告 §20 开头）：把 R05 补格时用**反汇编 + 秘密标记 Memcheck** 实锤到的那件事
   提到 M2 章开头——pq-crystals 的 KyberSlash 修复 `272125f` **只消除了除法**，却把
   `poly_frommsg` 里的 `bt`/`jae` 数据相关分支原样留下（未修 `3668: bt` → `366c: jae`，
   已修 `366e: bt` → `3672: jae`，**两侧指令字节逐字节相同**；两臂秘密标记探针各报
   `256 errors from 1 contexts`，唯一上下文都是 `poly_frommsg`）。由此给出「全 0／全 1 消息类对
   在 M2 已修臂上仍可能触发分布工具报警」的**机制层面候选解释**（该分支与 M1 同源，判据就是
   重加密时消息多项式的位，两臂都一样），并把这条写成**多工具交叉定位能力**的亮点。
   **边界同时写清**：候选归因不是已证成的因果归因，**不改变**任何预注册判定（端到端与
   除法热点微基准两个家族仍是 Holm 拒绝 0）。
2. **一键取件**（报告 §17）：新增 `tools/fetch_all_vendors.sh` 与
   `docs/patches/liboqs-982c762.patch`（官方补丁 982c762 的逐字节副本），两层 SHA-256 校验；
   `scripts/reproduce_all.sh quick --fetch` 可一步取件并复现，干净 clone **两条命令**即可跑通
   含 M1/M2 在内的全套测试。验证记录见
   [一键取件验证](../../../docs/evidence/fetch-vendors-20261020/RESULT.md)。

**同日 P2 级收尾（本页 96 页版本的来源）**：

1. **报告口径回填**：题面第 6 条的 F1 缺口闭合后，摘要与附录 A 统一为 **10 满足 + 2 部分**；
   正文中「本轮 final5 只重出报告」「复算产物是 final4」一类**过期口径**已改为按实际执行
   的 revision 表述，避免报告自述与实际产物不一致。
2. **一键复现的缺陷修复**：`scripts/reproduce_all.sh quick` 的 Holm 演练此前**实际没有跑成**
   （在子目录里用相对路径调用 `platform_holm`，`cd` 之后路径失效，失败被吞掉、退出码仍是 0）。
   本轮把工作目录统一为绝对路径、演练失败按失败返回，本机重跑后五个家族的 Holm 演练全部真实执行，
   CTest **263/263 通过、0 失败**。复现日志见
   [screenshots-20261020](../../../docs/evidence/screenshots-20261020/)。
3. **真实运行截图**：[screenshots/](screenshots/) 给出 4 张真实运行输出的屏幕图与逐张说明
   （一键复现、Memcheck 命中、锁频控制器状态、离线展示），供人工签收核对。
4. **官方报告 PDF 的中文字形修复**：本机 LibreOffice 26.8.1.1 找不到 macOS 中文系统字体，
   导出的《作品设计报告》PDF 里**汉字整段不显示**（文本层仍在，纯文本检查抓不到）。
   本轮显式给出系统字体目录（`scripts/libreoffice-fonts.conf`）并加渲染门禁
   （`scripts/check_pdf_render.py`：无中文字体或页面渲染全白即失败），官方 PDF 重出后为
   **104 页**且中文字形正常。

- `report-data.json`：显式模块状态、五模块摘要与证据来源；新结果须由主控确认后更新。
- `report-tables.json`：题面第 3/4/5 条对照表、实测数字—证据对照表与回填状态清单。
- `generate_report.py`：生成自包含中文 LaTeX、Markdown、SVG 矩阵、离线 HTML 及来源摘要。
- `r05_flowchart.py`：把 `docs/R05-全流程排查表.md` 第 5 节的 mermaid 流程图渲染成等价静态图
  （`r05-flowchart.svg` 供离线 HTML 内联，`r05-flowchart.png` 供 PDF；mermaid 源码在 HTML 中原样保留）。
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

回填数字时先改 `report-tables.json`/`report-data.json`，再按上面的顺序重新生成、
编译、逐页渲染，并用**新 revision** 重新成包（不覆盖 `refresh-20261016`）。
本轮没有 push、硬件采数或对旧证据的改写。
