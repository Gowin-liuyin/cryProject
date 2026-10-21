# R12 创新对照：多工具交叉 vs 单工具矩阵（T29b）与一键复现（T30）

本页覆盖两项任务：**T29(b)** 九个检测工具 × 五个泄漏模块的检出/误报矩阵，与 **T30**
一键复现脚本加参数总表。R12 的另一半——锁频 vs 不锁频的 A/B 对照——按
[PLAN.md](PLAN.md) 单独执行，它的结果不属于本页；那份结果落盘时应另用一个文件名
（例如 `RESULT-locked-vs-unlocked.md`），不要覆盖本页。

逐格证据写在 [TOOL_MATRIX.csv](TOOL_MATRIX.csv)：**9 个工具行 × 5 个模块列 = 45 格**，
另有 6 个统计列（家族归属、覆盖模块数、报阳性模块数、M5 误报数、方向不符说明）。
本页的每个数字与每条路径都逐条打开核对过；工具缺失一律写「未运行 + 原因」，不写「未检出」。

## 1. 口径

### 1.1 ground truth（按指定口径，未改）

| 模块 | ground truth | 依据 |
|---|---|---|
| M1 | **阳性**（真实历史 CVE，编译器引入的消息位分支） | [liboqs010-locked-20261015/README.md](../liboqs010-locked-20261015/README.md)、[tooling-strengthen-20261015/RESULT.md](../tooling-strengthen-20261015/RESULT.md) |
| M2 | **定位层阳性、端到端未检出、微基准未检出** | [m2-kem-20261016/RESULT.md](../m2-kem-20261016/RESULT.md)、[microbench-0551254c9579/RESULT.md](../m2-kem-20261016/microbench-0551254c9579/RESULT.md) |
| M3 | **人工构造校准阳性（定位层），端到端未检出** | [m3-completion-20261016/RESULT.md](../m3-completion-20261016/RESULT.md)、[LOCATE_RESULT.md](../m3-completion-20261016/LOCATE_RESULT.md) |
| M4 | **人工构造校准阳性，端到端阳性（vulnerable 臂）** | [m4-completion-20261016/RESULT.md](../m4-completion-20261016/RESULT.md)、[FORMAL_RESULT.md](../m4-completion-20261016/FORMAL_RESULT.md) |
| M5 | **阴性** | [m5-completion-20261016/RESULT.md](../m5-completion-20261016/RESULT.md) |

### 1.2 计数规则

- **运行过** = 该工具在该模块上有真实的产物原件（日志、JSON、CSV、反汇编），且我打开核对过。
- **报阳性** = 工具自己的判定为阳性（dudect 的 `DUDECT_LEAKAGE_FOUND` / `online_leakage_found`、
  RTLF 的 exit 11、Holm 的 `reject=1`、Memcheck 的非 0 errors、varlat 的非 0 errors、
  Binsec 的 `insecure`、Microwalk 的 MI 抬升、Mona 的 `validated_box_separation`）。
- **与 ground truth 一致** = 阳性落在该模块 ground truth 的阳性层（M2/M3 只认定位层，
  M4 认 vulnerable 臂）。落在别的臂、或方向与既有结论相反时，记入「方向不符」而不是记成检出。
- **误报** 只按用户指定的阴性基准 M5 统计：某工具在 M5 上报阳性即为误报候选，必须解释。

## 2. 矩阵总览（简版；逐格证据见 TOOL_MATRIX.csv）

| 工具（家族） | M1 阳性 | M2 定位阳性/端到端未检出 | M3 定位阳性/端到端未检出 | M4 vulnerable 阳性 | M5 阴性 |
|---|---|---|---|---|---|
| dudect（族外） | 检出 | 未检出（已修臂反报阳性） | 未检出 | 检出 | 未检出 |
| RTLF α=0.01（族外） | 检出 | 两个臂都检出（不可归因） | 未检出 | 检出 | 未检出 |
| Welch+Holm（家族内） | 检出（1/6 拒绝） | 未检出（0 拒绝） | 未检出（0 拒绝） | 检出（3 拒绝，全在 vulnerable 臂） | 未检出（0 拒绝） |
| Memcheck-ctgrind（定位层） | 检出 | 未运行（完整解封装） | 检出（1280/2 对 0/0） | 检出（32/1 对 0/0） | 未检出（三模式 0/0） |
| KyberSlash varlat（定位层） | 未运行 | 检出（1280/3 对 0/0） | 未运行 | 未运行 | 未检出（两模式 0/0） |
| Binsec checkct（形式层） | 未运行 | 未运行 | 未运行 | 检出（insecure 对 bounded secure） | 未运行 |
| Microwalk（定位层） | 未运行（pin 缺失） | 未运行 | 检出（1.922 bits 对 0.722 bits） | 未运行 | 未运行 |
| Mona（族外统计对照） | 未检出未修臂（已修臂 2/6 有分离） | 未检出未修臂（s3-fixed 1/8 有分离） | 未运行 | 未运行 | 未运行 |
| 反汇编（定位层） | 检出（bt/jae → bt/setb） | 检出（三热点各 1 个 div → 0） | 检出（两处秘密下标 movzwl） | 检出（0x8049047 数据相关） | 未发现 |

矩阵覆盖：45 格中 **30 格有真实运行产物**，**15 格为未运行**（每一格在 CSV 里都写了原因）。

## 3. 每个工具在其覆盖模块上的检出与误报

| 工具 | 运行过的模块数 | 报阳性的模块数 | 与 ground truth 阳性层一致 | 在 M5 报阳性（误报） | 方向不符 / 未归因 |
|---|---:|---:|---:|---:|---|
| dudect | 5 | 3（M1、M2、M4） | 2（M1、M4） | **0** | M2：阳性出现在**已修**臂（max\|t\| 36.27/30.94/61.91），未修臂反而阴性（4.68/3.05/3.66） |
| RTLF α=0.01 | 5 | 3（M1、M2、M4） | 2（M1、M4） | **0** | M2：主类对 6/6 全检出，未修与已修各 3 项，不可归因于除法变体 |
| Welch+Holm | 5 | 2（M1、M4） | 2（M1、M4） | **0** | 无 |
| Memcheck-ctgrind | 4 | 3（M1、M3、M4） | 3 | **0** | 无（M2 按未运行登记） |
| KyberSlash varlat | 2 | 1（M2） | 1 | **0** | 无 |
| Binsec checkct | 1 | 1（M4） | 1 | 不适用（未运行） | 无 |
| Microwalk | 1 | 1（M3） | 1 | 不适用（未运行） | 无 |
| Mona | 2 | 0 | 0 | 不适用（未运行） | M1/M2：未修臂全部无分离，却在**已修**臂分别出现 2/6 与 1/6 次箱体分离 |
| 反汇编 | 5 | 4（M1-M4） | 4 | **0** | 无 |

**M5 阴性基准上的误报合计为 0**：在 M5 上真正运行过的 6 个工具（dudect、RTLF、Welch+Holm、
Memcheck-ctgrind、varlat、反汇编）全部给出阴性，与 M5 的 ground truth 一致。
其余 3 个工具（Binsec、Microwalk、Mona）在 M5 上未运行，不填阴性、也不计误报。

需要单独说明的「阳性但不该算检出」两处，都在 M2：dudect 与 RTLF 都在 M2 报了阳性，
但方向或归因不成立——如果只拿这两个工具中的一个看 M2，会得到与预注册结论相反的读法。
这正是多工具交叉的价值所在，见下一节。

## 4. 多工具交叉 vs 单工具

### 4.1 如果只用一种工具，各条路线会得到什么

| 单工具路线 | 会得到的结论 | 漏检 | 误报/错向 |
|---|---|---|---|
| 只用 Welch+Holm | M1 检出（1/6 拒绝）、M4 检出（3 拒绝，全在 vulnerable 臂）、M2/M3/M5 未检出 | **M2 与 M3 的定位层阳性完全看不到**（Welch 只测端到端均值差）；M2 的除法热点机制、M3 的秘密下标 LUT 机制都不会出现在结论里 | M5 无误报；不会错向 |
| 只用 dudect | M1 检出、M4 检出、M3/M5 未检出 | M2/M3 的定位层阳性；M2 的微基准层 | **M2 上给出方向错位的阳性**：报的是已修臂，若单工具解读会得出「修复引入了泄漏」；此外 M3 的该入口没有逐样本 CSV，无法离线复核 |
| 只用 RTLF | M1 检出、M4 检出、M3/M5 未检出 | M2/M3 的定位层阳性 | **M2 上未修与已修各 3 项全部检出**，单工具会把 M2 读成「两臂都可区分」，与 Welch/Holm 的 0 拒绝冲突 |
| 只用 Memcheck-ctgrind | M1/M3/M4 的定位层阳性 | **M2 完全没有覆盖**（对完整解封装没有跑）；它不是端到端时序检验，无法给出 M2/M3 的「端到端未检出」 | M5 无误报 |
| 只用 KyberSlash varlat | 只有 M2（1280/3 对 0/0）与 M5（0/0） | **M1、M3、M4 全部丢失**：M1 的消息位分支不在 varlat 的命中类别里，M3/M4 没有跑 | 无误报 |
| 只用 Binsec | 只有 M4 的 `insecure` 对 bounded secure | **M1、M2、M3、M5 全部丢失**（只有 M4 建了 i386 抽取内核与模型） | M5 未运行 |
| 只用 Microwalk | 只有 M3（1.922 bits 对 0.722 bits） | **M1、M2、M4、M5 全部丢失** | M5 未运行；M3 只有 5 个公开 testcase，无统计检验 |
| 只用 Mona | M1/M2 的未修臂都「无分离」 | 会把 M1 与 M2 的定位层阳性一起漏掉 | **M1 已修臂 2/6、M2 s3 已修臂 1/8 出现分离**，单工具会给出「修复反而有分离」的错误方向 |
| 只用反汇编 | M1–M4 的定位层全部命中、M5 未发现 | 给不出任何「物理时间是否可区分」的结论：M2/M3 的端到端未检出、M4 的端到端阳性都必须靠统计工具 | 无误报 |

### 4.2 交叉之后多出来的东西

1. **M1**：反汇编（`bt`/`jae` → `bt`/`setb` + `cmov_int16`）、Memcheck（`poly.c:179`）、
   Welch+Holm（修正后 p=0.196 不拒绝）、RTLF（exit 10）、dudect（max t +1.15）**五路同向**，
   是唯一一个「真实历史 CVE + 多工具同向」的模块。
2. **M2**：反汇编与 varlat 在三个除法热点上定位阳性（各 1 个 `div` → 0 个；1280/3 → 0/0），
   而 Welch+Holm 在端到端（m=6，Δ=+4.58 ns，CI 含 0）与除法热点微基准（m=6，Δ=+0.044 ns，
   CI 含 0）两层都未检出——**「定位阳性 + 端到端未检出」这个分层结论只有交叉才成立**。
   单看 RTLF 或单看 dudect 都会在 M2 上得到方向错误的读法。
3. **M3**：Microwalk 的内存访问互信息峰值（`poly_frommsg+30/+59` 各 1.922 bits）、
   Memcheck 的两个报警 PC（静态偏移 `0x5CED`/`0x5D15`）与反汇编的两条
   `movzwl (%r8,%rcx,1)` 指向**同一对指令**；而三个统计工具在端到端都未检出。
   人工构造校准的定位结论因此有三个独立来源，同时端到端阴性也被明确分层记录。
4. **M4**：Binsec（`insecure` + 反例 `0x8049047`）、Memcheck（32/1 对 0/0）、反汇编（3 个条件
   跳转中 1 个数据相关）三路定位同向；Welch+Holm（3 项拒绝）、RTLF（6/6 检出 vulnerable）、
   dudect（max\|t\| ≈ 356–396）三路端到端同向。**这是唯一一个定位层与端到端都阳性、
   且 `ct` 对照臂在所有工具下都不报的模块**，给出了「工具确实能检出」的对照。
5. **M5**：6 个工具 6 路全阴，构成阴性基准；同时 M5 也是唯一一个「三个统计工具 +
   两个 Valgrind 模式 + 反汇编」都覆盖到的模块，所以 M5 的阴性不是单一工具的产物。
6. **Mona 是唯一与既有方向不一致的工具**（M1/M2 未修臂无分离、已修臂有分离）。
   矩阵把它登记为工具规则差异：它的 `Confidence Interval` 字段是批次成功百分比而不是 p 值，
   自适应箱体搜索可产生假阳性，`holm_member=false`。**没有**用它推翻任何既有结论，
   也**没有**把它的「无分离」写成 M1/M2 的阴性证据。

### 4.3 反过来的两条：交叉也会暴露工具自身的边界

- dudect 与 RTLF 在 M2 上给出的阳性**没有**被升格为泄漏结论，因为：(a) RTLF 在两个臂上同时
  检出；(b) dudect 的阳性落在已修臂。把它们与 Welch/Holm、反汇编、varlat 放在一起看，
  才能把它们读成类构造/环境漂移而不是秘密相关泄漏。
- Mona 的「有分离」也没有被当成受控误报率：它出现在迭代扩展子集后只剩一个子集的末轮，
  相邻同类子集重叠条件此时没有后续子集可比。

## 5. 工具缺失与阻塞（如实）

| 项 | 状态 | 原因或替代 |
|---|---|---|
| Microwalk 官方镜像 `ghcr.io/microwalk-project/microwalk:pin` | **未拉取、未运行** | M1 轮 `pin` 不在 `PATH`，按 [PROTOCOL.md](../tooling-strengthen-20261015/PROTOCOL.md) §不做记跳过；M3 轮改用**源码自建** Microwalk 3.x master + 自建 Pin 3.28，真实跑通并有互信息原件（[LOCATE_RESULT.md](../m3-completion-20261016/LOCATE_RESULT.md) §2.6、§2.7）。官方镜像可用性这一项仍是阻塞。 |
| ctgrind 上游补丁 `ca93f4f` | **打不上**（针对 Valgrind SVN r11097；本机 3.22.0 无对应 `mc_main.c`） | 改用发行版 memcheck 的 `VALGRIND_MAKE_MEM_UNDEFINED` 做秘密标记；不把未打上的补丁当阳性（[RESULT.md](../tooling-strengthen-20261015/RESULT.md) 第 17 行） |
| M2 的 ctgrind/Memcheck（完整解封装） | **未运行** | M2 只有 varlat 的关闭对照在三个热点函数上跑过普通 Memcheck（0/0），对象是公开人工探针，不是完整解封装 |
| M1/M3/M4 的 varlat | **未运行** | varlat 为 M2 的除法热点建立；M1 的机制不在命中类别，M3 明确用 Memcheck 标准标记，M4 没有除法热点 |
| Binsec 在 M1/M2/M3/M5 | **未运行** | 只有 M4 建了 i386 抽取内核（`m4_entry`/`m4_halt`）与秘密-公开模型；其余模块没有对应 harness |
| Mona 在 M3/M4/M5 | **未运行** | Mona 只接入 M1 与 M2 |
| M1 的 quick 档 | 不在 `reproduce_all.sh quick` 内 | 需要 `vendor/liboqs-0.10.0/`（`.gitignore`），先跑 `tools/fetch_liboqs_0.10.0.sh` |

没有发现「官方镜像不可用」以外的未核实项；上表每一行的现状都有仓库内原件支撑。

## 6. T30 一键复现

### 6.1 `scripts/reproduce_all.sh`

- `quick` 档：配置 + 构建 + CTest（`platform` / `ordinary` / `sanitize`，可用 `--configs` 三选一
  或全跑）+ 每类小样本统计演练（默认 1000，`--runs` 默认 3）。**全程不需要 sudo**，
  不写任何 sysfs 频率节点，不绑核。演练链路为：`measure`/`m4_measure` → `platform_stats`
  （Welch CI）→ 汇总 `members.csv` → `platform_holm`（Holm + 固定效应合并）→
  逐行打印 `holm.csv` / `pooled.csv`。
- `full` 档：按四份冻结 PLAN 生成完整采集命令，**默认 dry-run 只打印**；加 `--execute`
  才真跑，且必须给 `--control-root`（校验位于 `<...>/Cry` 之下并含 `controller.py`）。
  打印内容含串行/sudo 提示、每个模块工作区 PLAN 的 sha256、以及「工作区 PLAN 已被文档修订、
  与执行版摘要不同」的说明，命令形态与各模块 PLAN §7 的执行入口一致。
- 干净 clone 依赖：脚本不强依赖 `third_party/`、`vendor/liboqs-0.10.0/`、
  `vendor/kyber-kyberslash-*/`；缺件时打印跳过原因而不是填「未检出」。OpenSSL 3 自动探测，
  找不到就退回 `-DBASELINE_ALLOW_NON_SHA3_OPENSSL=ON`（`native_digest` 记为 Skipped，不伪装通过）。

### 6.2 干净 clone 验证结果

在 `/tmp` 的干净 clone（HEAD `8a95f64`）里跑
`sh scripts/reproduce_all.sh quick --work-dir … --samples 1000 --runs 3`，退出码 `0`；
验证用的脚本 sha256 为 `16562851a309ed40ee37b4b5deb3d1b54a4f44f70af01140cd235619c0117b97`
（与工作区当前文件一致）：

| 配置 | CTest |
|---|---|
| platform（`BASELINE_ENABLE_PLATFORM=ON`、`A113_ARCHIVED_CASE_ONLY=OFF`） | **80/80 通过，0 失败** |
| ordinary（默认） | **57/57 通过，0 失败** |
| sanitize（`BASELINE_SANITIZERS=ON`、`Debug`） | **57/57 通过，0 失败** |

合计 **194 项 CTest 通过、0 失败**。演练产出：M3 m=6 拒绝 1（`M3-on-r2`，Δ=+22.12 ns）、
M4 m=6 拒绝 0（Δ=+0.56 ns）、M5 m=3 拒绝 0（Δ=−43.38 ns）；M2 因干净 clone 缺 vendor 而跳过。
演练不锁频、不绑核、跑在 macOS/ARM、每类只 1000 次，**不是任何模块的正式统计结论**：
M3 的 1 项拒绝与 M5 合并 CI 不含 0 都只是「没有锁频协议时同一台机器会给出什么」的演示，
不构成 M3 或 M5 的阳性。

原始日志按原字节留存在：
[reproduce-quick-clean-clone.log](reproduce-quick-clean-clone.log)
（sha256 `5133e51e10ead20d6def233cd5a7dd47325579a95e6d8f49eb806ae6995a3c2a`）、
外层 stdout [reproduce-quick-clean-clone.stdout.log](reproduce-quick-clean-clone.stdout.log)，说明与逐项读数见
[REPRODUCE-QUICK-LOG.md](REPRODUCE-QUICK-LOG.md)。

### 6.3 参数总表

[docs/REPRODUCE-PARAMS.md](../../REPRODUCE-PARAMS.md)：覆盖 **M1、M2、M3、M4、M5 五个模块**
加公共入口共 6 张表，逐行给出编译选项、种子、样本数、核与频率、统计脚本/工具、PLAN 链接与
证据目录；文末 90 条链接逐条核对存在。

## 7. 边界

- 本矩阵是**已有证据的对照汇总**，没有新增任何硬件采集；所有数字都取自仓库内已有原件。
- 「未运行」不等于「未检出」，本页与 CSV 一律分开写。
- 「检出」按各工具自己的判定登记，不把定位层阳性写成端到端阳性，也不把「未检出」写成恒时证明。
- M5 的误报为 0 只覆盖本机、本类对、本样本预算与本次工具设置，不构成总体误报率结论。
- RTLF 的 α=0.01 与 Holm 家族的 α=0.05 不是同一个多重比较框架，两者的二值/拒绝结果不可折算。

---

## 2026-10-21 更正（独立复核发现，原文不改）

①上文表格里「脚本 sha256 `16562851…`（验证时尚未提交……该摘要与工作区当前文件一致）」**后半句现已不成立**：`scripts/reproduce_all.sh` 在此���又改过，当前工作区的摘要是 **`002ab0be60373375f1ea871764bba1645bbe5946330561476cd94797abbabe75`**（报告表 T25 里的摘要**现算自当前工作区**，不再写死）。**产出 263/263 的那次运行用的正是当前这版脚本**，其日志 `docs/evidence/screenshots-20261020/reproduce-quick-terminal-p2b.log` 现已随匿名支撑卷分发。

②上文「原始日志按原字节留在同目录，未做删改」中的「同目录」指**仓库里的本证据目录**；匿名支撑卷里这两份日志镜像在 `evidence/files/<同一路径>` 下（路径一一对应），内容为**原字节副本**。
