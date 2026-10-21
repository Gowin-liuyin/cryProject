# 真实运行截图与人工签收佐证（2026-10-20）

本目录是**人工签收**用的佐证材料：把本轮真实跑过的终端输出与离线展示渲染成屏幕图，
便于复核人在不打开终端的情况下核对「确实跑过、确实有输出」。**这些图不替代原始日志与
证据文件**——每一张都能回到仓库内可打开的原件。

## 总体口径

1. **不生成、不改写运行内容**。每张图的正文字符都取自实际产生的日志文件或实际渲染的页面；
   图上唯一的额外内容是标题栏里的命令与底部一行说明，以及被截取时插入的「本图只显示日志末尾 N 行」。
2. **真实性分两类，图上写明**：
   - **本轮实时采集**：在提交这台机器上当场跑出来并当场渲染（图 1、图 4）；
   - **归档的真实运行输出**：在 Linux 实测机上真实跑出来的原始日志，本次按终端外观渲染（图 2、图 3）。
     这类图的原始日志在证据目录里原字节保存，可逐字核对。
3. **像素层也已人工目检**（2026-10-21 第 9 轮复核补做）：包审计的字节/文本扫描
   扫不到图片像素，所以本目录 4 张终端/页面截图**逐张打开看过**——画面里没有地址栏、
   主机名、用户名或本机绝对路径（可见的路径一律是 `[REPOSITORY]` / `[REMOTE_PROJECT]`
   占位）。这是**目检**结论，不是 OCR 结论：像素无法机器核对这一点仍如实保留。
4. **身份替换规则与匿名支撑包完全一致**：本机仓库路径 → `[REPOSITORY]`，本机用户名 →
   `[LOCAL_USER]`，远端项目根 → `[REMOTE_PROJECT]`，远端用户名 → `[REMOTE_USER]`，公网 IP →
   `[REMOTE_IP]`/`[HISTORICAL_IP]`，作者名与邮箱 → `[PROJECT_AUTHOR]`/`[AUTHOR_EMAIL]`。
   替换只作用于路径与身份串，**不改动任何数值、判定或结论**。
5. 图是**佐证**，不是新证据：统计结论仍以报告正文与证据文件为准。

## 逐张说明

| 图 | 文件 | 拍的是什么 | 来源（命令 / 原件） | 环境与时间 | 真实性 |
|---|---|---|---|---|---|
| 1 | `01-reproduce-quick-terminal.png` | 一键复现 `quick` 档实跑：四套配置的 CTest 汇总（platform 88/88、ordinary 57/57、sanitize 57/57、historical-fixed 61/61，**合计 263 项通过、0 失败**）与 M1–M5 五个家族的 Holm 演练输出 | `sh scripts/reproduce_all.sh quick --samples 200 --runs 1 --work-dir build/reproduce-quick-p2b-20261020`；完整输出 `docs/evidence/screenshots-20261020/reproduce-quick-terminal-p2b.log`（113 行） | 本机 macOS/ARM，2026-10-20 22:12（UTC 14:12） | 本轮实时采集 |
| 2 | `02-valgrind-memcheck-hit.png` | M3 秘密标记 Memcheck 命中：秘密下标访存被标记为未初始化值，调用栈 `baseline_native_poly_frommsg (compress.c:714)` ← `baseline_native_indcpa_enc` ← `baseline_native_dec` ← `main` | 原件 `docs/evidence/m3-completion-20261016/native-8b6f2d91/on-secret.memcheck.log`（31 行，Valgrind 3.22.0） | Linux x86_64 实测机（项目根在 `[REMOTE_PROJECT]`），采集于 2026-10-16 | 归档的真实运行输出 |
| 3 | `03-frequency-controller-log.png` | 锁频控制器逐条状态：`locked` 臂 `controller_exit=0 worker_exit_code=0 restore_match=yes`；`unlocked` 臂 `worker_exit_code=0 config_changed=no` | 原件 `docs/evidence/r12-innovation-20261016/remote/logs/status.log`（18 行） | Linux x86_64 实测机（项目根在 `[REMOTE_PROJECT]`），采集于 2026-10-16 | 归档的真实运行输出 |
| 4 | `04-offline-html.png` | 离线展示首页真实浏览器渲染：标题、摘要、目录导航与「打开 PDF / LaTeX 源 / 对照表数据 / 状态与摘要 / 证据索引」入口 | `deliverables/research/multi-leakage-platform-20261016/index.html`（**与提交件同源**：报告抬头日期 2026-10-21），本机 Chrome 无头模式截图 | 本机 macOS/ARM，2026-10-21 | 本轮实时采集 |

## 图 1 的一个已知缺陷与本轮修复

第一次跑 `quick` 档时，五个家族的 Holm 演练**其实没有跑成**：脚本在子目录里用相对路径调用
`platform_holm`，`cd` 之后路径失效，日志里是 `No such file or directory`，而脚本仍以退出码 0
结束（失败被吞掉）。本轮修了三处：

1. 工作目录统一取绝对路径（`scripts/reproduce_all.sh` 的 `quick_main`）；
2. Holm 演练失败时打印「错误：…」并置失败标志，演练不完整即**按失败返回**；
3. `quick` 档在演练失败时退出码非 0，不再把「一键复现没跑通」记成成功。

修完后重跑（即图 1）：五个家族的 Holm 演练全部真实执行并打印 `holm.csv` 与 `pooled.csv`，
CTest 263/263 通过、0 失败，退出码 0。**旧日志里的「演练跑通」说法在这一轮之前是不成立的**，
以图 1 与其对应日志为准。

## 怎么重跑这些图

```sh
# 图 1：一键复现 quick 档（本机实跑）
sh scripts/reproduce_all.sh quick --samples 200 --runs 1 --work-dir build/reproduce-quick-p2b-20261020
# 图 2：把原始 Memcheck 日志渲染成终端图
python3 tools/render_terminal_shot.py \
    --input docs/evidence/m3-completion-20261016/native-8b6f2d91/on-secret.memcheck.log \
    --output deliverables/research/multi-leakage-platform-20261016/screenshots/02-valgrind-memcheck-hit.png \
    --title "M3 秘密标记 Memcheck 命中（归档真实运行输出）" \
    --command "valgrind --tool=memcheck --track-origins=yes ./build-ordinary/platform_m3_on_probe --secret"
# 图 3：锁频控制器状态日志
python3 tools/render_terminal_shot.py \
    --input docs/evidence/r12-innovation-20261016/remote/logs/status.log \
    --output deliverables/research/multi-leakage-platform-20261016/screenshots/03-frequency-controller-log.png \
    --title "锁频控制器逐条状态（归档真实运行输出）" \
    --command "cat remote/logs/status.log   # R12 锁频 vs 不锁频 A/B 对照"
# 图 4：离线展示页面的浏览器截图
python3 tools/render_offline_html_shot.py \
    --html deliverables/research/multi-leakage-platform-20261016/index.html \
    --output deliverables/research/multi-leakage-platform-20261016/screenshots/04-offline-html.png
```

`SHA256SUMS` 记录本目录各文件的摘要。

## 人工签收提醒（必须由人完成）

- 图 1、图 4 是**本轮实时采集**；图 2、图 3 是**归档的真实运行输出**，图上已标明。
- 若赛事方要求**现场屏幕照片**（相机拍摄或现场录屏），签字前须用上面同样的命令在评委可见的
  环境重跑并用这些图替换；图 2、图 3 需要在 Linux 实测机上重跑对应模块的采集命令。
- 截图里没有任何秘密材料；`quick` 档不写 sysfs、不调用 sudo、不绑核。
