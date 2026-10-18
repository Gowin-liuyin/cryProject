# 模块一评审：可部署恒时编码变体 deployable（正常优化下）与其实测证据

模块一由两个提交构成：`0cba2c7`（提交 A，代码/配置，+75/−26，7 个文件）与 `343a6cb`（提交 B，
证据/文档，+124489，33 个文件）。两者都在 `main`、作者与提交者均为
`Gowin-liuyin <yinhaoran0808@outlook.com>`、`main` 无上游跟踪（未 push）。提交 A 注册第四个变体
`deployable`：新补丁 `docs/patches/message-value-barrier.patch` 去掉全部函数级优化控制、用上游
`mlk_value_barrier_u8` + `mlk_ct_sel_int16` 做位选择，CMake 注册第四条变体链与
`equivalence_deployable`，四个测试脚本的变体循环与 `test_cli.sh` 末尾那段不在循环内的跨变体
`cmp` 块都已补上新变体；hardened 补丁一字未动。提交 B 归档 `docs/evidence/deployable/` 31 个文件：
四份编码函数反汇编、四份 `indcpa_enc` 调用者反汇编、deployable 全二进制反汇编、四份 25000 条
CSV/meta/report、核对记录与摘要清单，并纯追加 `docs/mitigation.md` 新章节（116 行、0 删除）。
我按只读方式复核了反汇编逐条标注、四份统计报告的每个被引用数字、摘要与 CTest 日志、跨会话引用的
归档数字，全部与文档一致——包括两处不理想结果与「deployable 被内联」这个对作者不利的判定。

**Watch for:** 内联判据正则在**执行时丢了 `\$` 转义**，`(#|$)0x681|[#$ ]1665` 实测不匹配 GNU
x86_64 的 `$0x681`，而 README / `call-site-counts.txt` / 提交信息三处都声称它「同时覆盖
GNU x86_64 的 `$0x681`」（confirmed，非阻断：ARM64 印法是 `#0x681`，命中成立，本模块结论不受影响；
但模块二在 GNU 侧复用这个形式会 fail-open）；vulnerable 的循环计数器回写地址标注错位一格
（confirmed，非阻断，归属依据本身正确）；M1-1 的 `version` 输出与 M1-2 的
`ctest --preset baseline` 全通过都只有文字主张、无归档逐字输出（confirmed，非阻断）。

**Verdict**: APPROVED

## High-level view

本模块最值得注意的技术结果是**对作者不利的那一个**：deployable 不带 `noinline`，`-O2` 下编译器
把编码函数整体内联进了 `mlk_indcpa_enc`，`bl <_baseline_native_poly_frommsg>` 调用点计数实测为
**0**。按模块零预注册的 M1-5a 这落到情况 2，离线符号副本的反汇编**不构成产物证据**，结论必须改由
调用者内联段给出，粒度与另三个变体的独立符号不同、不能并列成等价表。证据如实走了这条路，没有
为了拿独立符号而加回 `noinline`（设计明令禁止），也没有拿离线副本冒充执行路径。

四份编码函数反汇编里的条件跳转共 5 条，加内联段 1 条共 6 条，我用 README 自己的检索式复核，
条数、行号与地址与表格逐条相同。唯一的消息位相关分支是 vulnerable 的 `tbz w8,#0x0`
（`0x1000026d8`），其余五条都是按计数器与 256 比较的回边（reference 是 32，因为内层 8 次位循环被
完全展开）。deployable 内联段里消息字节经 `ldrb w13,[x21,x13]` 取入后只流向 `and`/`neg`/`and`
掩码算术，`x21` 是 prologue `mov x21,x1` 存下的第二个参数，操作数链闭合。

内联判据的正则是唯一有实质问题的地方。执行的命令丢了 `\$`，于是「覆盖 GNU `$0x681`」这句在实测上
不成立。本模块无害——Apple objdump 只印 `#0x681`，deployable 的命中是真的；但模块二要在 GNU x86_64
反汇编上复用同一判据，那边的立即数正是 `$0x681`，用现在这个形式会在「有内联副本」时报未命中，
方向是 fail-open。

统计与性能都给了，不理想的部分没有被藏起来。四个变体同一会话、同一种子 `20260930`、每类 5000 次，
显著数 0/7/0/0，deployable 最大 |rank z|=2.11 与 reference 的 2.05 同量级；README 主动写出 deployable
的类别均值极差 47.8ns **大于** reference 的 27.8ns、hardened 本次 |z|=3.06 高于归档那次的 2.15。
性能上 hardened − deployable = 237.88ns，并明确声明本次测得 238ns 而非既有文档的「约 400ns」、
两者属不同会话不得相减。我按归档的 `docs/evidence/mitigation` 报告复核了 2.15、
hardened 14531–14552、reference 14127–14168 这三个跨会话引用，全部逐字成立。

只读边界与身份干净：两个提交合起来没有触碰 `vendor/`、`tests/vectors/` 或任何既有
`docs/evidence/` 目录，`docs/patches/` 下只新增一个文件，hardened 补丁与 `cmake/` 全未改动。

<details>
<summary>Issues (7)</summary>

1. **内联判据正则丢了 `\$` 转义**（confirmed，MEDIUM，非阻断）— 执行的
   `grep -nE '(#|$)0x681|[#$ ]1665'` 实测不匹配 `$0x681`（未转义的 `$` 在 ERE 里不是字面量），
   设计写死的 `(#|\$)0x681|[#$ ]1665\b` 才匹配三种印法；README、`call-site-counts.txt`、
   提交信息三处的「同时覆盖 GNU x86_64 的 `$0x681`」不成立。模块二必须用带 `\$` 的形式，
   并在模块二 README 更正这句措辞（本目录已封存、不得回改）。
2. **vulnerable 计数器回写地址错位一格**（confirmed，NIT）— README 写「`0x10000271c str` 回写」，
   实测 `0x100002718` 才是 `str w8,[sp,#0xc]`，`0x10000271c` 是无条件回边 `b`。归属结论不受影响
   （依据是紧前的 `0x1000026a4 cmp w8,#0x100`，该地址正确）。后续模块引用时按实测地址。
3. **vulnerable 无条件 `b` 的说明不准**（confirmed，NIT）— 列为「`if/else` 汇合用的」三条里，
   `0x10000271c` 是循环回边不是汇合点，且漏了循环出口 `0x1000026ac` 的 `b`。条件分支清单本身完整，
   无条件跳转不在设计要求内。
4. **M1-1 与 M1-2 各有一句无归档逐字输出**（confirmed，NIT）— 证据目录里搜不到
   `deployable ML-KEM-768 FIPS203` 字符串（`tests/test_cli.sh` 只执行 `version`、不校验输出），
   `ctest --preset baseline` 全通过只出现在提交 A 的提交信息里，归档的是
   `--test-dir build/deployable` 与 sanitize 两份。后续模块把这两项输出一并归档，
   或给 `test_cli.sh` 加一条 `version` 输出比对。
5. **另三个变体的全二进制反汇编未归档**（confirmed，NIT）— 特异性对照计数 1 与 `bl` 调用点地址
   无法从已归档文件复核，只能靠 `call-site-counts.txt` 的转录。设计 1.4 只要求 deployable 一份，
   故不是违规。模块二按同口径把四份全二进制 grep 的逐字输出一并归档。
6. **提交 B 的文件数说法不自洽**（confirmed，NIT）— 「SHA256SUMS 30 行覆盖除自身外全部 31 个文件」：
   目录实测 31 个文件，除自身外是 30 个，`SHA256SUMS` 实测 30 行且不含自身。README 的
   「不含自身」表述正确，提交信息的数字需按「其余 30 个」理解。
7. **`.meta` 没有 deployable 的编码器自述行**（confirmed，NIT，既有、非本模块引入）—
   四份 `.meta` 只有 `vulnerable_kernel_include` / `vulnerable_definition` / `vulnerable_encoder`
   三行，归档的 `docs/evidence/mitigation/hardened.meta` 同样如此，`cmake/build_configuration.txt.in`
   本模块未改。变体身份由 `implementation=` 与 `executable_digest` 支撑，不影响结论；
   模块四补新增代码的检查时可一并给模板加 `deployable_encoder=` 行。

</details>

<details>
<summary>Details</summary>

### 补丁形态与预注册片段的逐字对照

`docs/patches/message-value-barrier.patch` 的循环体与设计 1.2 写死的目标片段逐字相同：
`coefficient_index` 单层 256 次、`mlk_value_barrier_u8((uint8_t)(1u << (coefficient_index % 8u)))`
取掩码、`selection_condition` 显式转 `uint16_t`、`mlk_ct_sel_int16(MLKEM_Q_HALF, 0, …)` 选择。
设计要求的四项差异逐项成立：补丁没有引入 `optnone` / `optimize` / `noinline` 任何一个
（对照 `docs/patches/message-constant-time.patch:13,15` 两行）、保留 `MLKEM_INDCPA_MSGBYTES`
编译期守卫且位置在函数体开头（hardened 补丁实测在 `:10-11` 把它删掉了）、
保留 `mlk_assert_abs_bound(message_polynomial, …)`（hardened 补丁 `:51` 删掉）、不保留 `__loop__`。

设计 1.5 点名禁止的那句表述没有出现：README 与 `docs/mitigation.md` 都把保留的编译期守卫与
`mlk_assert_abs_bound` 写成**源码形态**差别，并给出「`MLK_CONFIG_DEBUG` 在本仓库任何 preset
都未定义、宏空展开、不产生代码」的理由，没有一处说成「deployable 多了一层运行时检查」。

### 新变体是否真的接进了全部 CTest

`ctest.log` 的 `-N` 输出列出 16 项，三项新增全在：`deployable_kat`（#7）、
`deployable_random_failure`（#8）、`equivalence_deployable`（#11），`--output-on-failure` 16/16 通过；
`sanitize-ctest.log` 同样 16/16、来自 `build/cmake-sanitize`，README 与 1.5 都标注它属另一套配置、
只用于功能正确性。`equivalence_vulnerable` / `equivalence_hardened` 的测试名在改成循环注册后不变，
与 `-N` 输出一致。

`tests/test_cli.sh` 末尾那段原先硬编码两条 `cmp` 的跨变体逐字节比较块已改为：

```sh
for category in valid bit-flipped random message-zero message-ones; do
    for variant in vulnerable hardened deployable; do
        cmp "$test_directory/reference-$category" "$test_directory/$variant-$category"
    done
done
```

四个脚本的变体循环都已加上 deployable（`test_cli.sh:6`、`test_measurement.sh:6`、
`test_analysis.sh:134`、`test_vector_parser.sh:11`）。设计判定「不需要改」的另两处我核对了实际语境：
`test_measurement.sh:29` 的 `reference.csv` / `vulnerable.csv` 是比较工具的固定两参数，
`test_analysis.sh:100` 的 `s/,reference,/,hardened,/` 是构造畸形 CSV 的字面量——都不是变体枚举。
全仓库（排除已归档证据与冻结设计）再无 `reference vulnerable hardened` 三元组残留，
没有第二处会静默漏掉新变体的硬编码。

### 条件跳转清单与归属标注

用 README 自己的检索式 `grep -nE '\b(b\.[a-z]+|cbz|cbnz|tbz|tbnz)\b'` 对四份编码函数反汇编复核，
实测与表格逐条相同、无漏项：

```
reference-encoder-arm64.txt:61    0x100002768  b.ne
vulnerable-encoder-arm64.txt:13   0x1000026a8  b.lo
vulnerable-encoder-arm64.txt:25   0x1000026d8  tbz w8, #0x0
hardened-encoder-arm64.txt:13     0x1000026a8  b.lo
deployable-encoder-arm64.txt:20   0x1000026c4  b.ne
```

归属依据逐条可追：reference 的 `cmp x8,#0x20`（上界 32 = `MLKEM_N/8`，内层 8 次位循环展开成
8 组 `mov w11,#1…#0x80`）、deployable 离线副本与内联段的 `cmp x8,#0x100`、vulnerable `tbz` 前面
`lsr w8,w8,w9` ← `ldrb w8,[x8]` ← `message_bytes + coefficient_index/8` 这条消息位链。
两处地址转录不准见 Issues 2、3，都不触及「紧前影响标志位的指令」这个判定依据本身。

设计把 ARM64 循环边界助记符写成 `b.ne`（Apple Clang）与 `b.ls`（ARM64 GCC），本次两个 `optnone`
变体实测出现的是 `b.lo`。README 把这当成「与设计预期不符、按实测修正」单列一段，并说明归属判定
依据的是操作数链而非助记符清单——按实测改正，不是回避。

### deployable 被内联：情况 2 的处置

`call-site-counts.txt` 把四个变体的三项计数记全：`poly_frommsg` 调用点
（reference/vulnerable/hardened 各 1，deployable **0**）、`indcpa_enc` 调用点（四个都是 2，
所以调用者一律取 `_baseline_native_indcpa_enc`，无人需要退到 `_baseline_native_dec`）、
判据正则在调用者与全二进制上的命中（前三者未命中 + 全二进制 1，deployable 命中
`:39 0x100006e2c` + 全二进制 2）。全二进制计数 2 的两处落点逐处写明：一处在从未被调用的离线副本
（`0x100002698`），一处在内联段（`0x100006e2c`）——设计要求的「计数 > 1 时必须说明多出来的那几处
落在哪个符号里」做到了，而且这个计数同时为「没有第二份内联副本」提供了上界。

内联段我直接读了。`deployable-caller-indcpa-enc-arm64.txt` 第 33–51 行
（`0x100006e14`–`0x100006e5c`）确实只有一条条件跳转（第 51 行 `b.ne`，紧前 `cmp x8,#0x100`），
消息字节在第 44 行 `ldrb w13,[x21,x13]` 取入，`x21` 由 prologue 第 23 行 `mov x21,x1` 存下
（`indcpa_enc` 的第二个参数），之后只经 `and`→`neg`→`and …,lsr #16`→`strh`，不进入任何条件判断。
`call-site-counts.txt` 的「内联段佐证」小节把这 14 条指令逐行对上 C 语句，符合设计「256 次系数循环
只作佐证、不作判据」的定位。调用者取 `mlk_indcpa_enc` 也有仓库事实支撑：
`vendor/mlkem-native/mlkem/src/indcpa.c:544` 是 vendor 里唯一的 `mlk_poly_frommsg` 调用点，
位于重加密路径的 `mlk_indcpa_enc`。

### 正则的转义缺陷与它在模块二的方向

用三行探针文件实测两种形式（本次评审唯一一处窄 spot-check）：

```
mov    $0x681,%eax                      ← GNU x86_64 印法
mov w10, #0x681             ; =1665     ← Apple objdump 印法
movl   $1665, -4(%rbp)                  ← 十进制印法
```

设计写死的 `(#|\$)0x681|[#$ ]1665\b` 命中三行；`call-site-counts.txt` 与 README 记录的
`(#|$)0x681|[#$ ]1665` 只命中后两行，第一行漏掉。本模块的产物是 Apple objdump 输出、命中走
`#0x681` 分支，四个变体的判定结果都不受影响；偏差的方向是让判据**更难**命中，deployable 仍然命中
并被归到对作者不利的情况 2，不存在用放宽判据换有利结论。需要修两件事：模块二在 GNU x86_64 上必须
用带 `\$` 的形式，以及「覆盖三种印法」这句要在模块二 README 里更正（本目录按 0.3 已封存、不回改）。

### 统计与性能数字的逐个复核

四份 `.report` 的每个被引用数字都对上了：显著数 0/7/0/0；类别均值极差 27.8 / 797.8 / 40.6 / 47.8ns；
最大 |rank z| 2.0499 / 66.7937 / 3.0571 / 2.1101；主比较四行（含 vulnerable 的
`mean_difference_ns=-44.000`、`rank_z=-5.1353`、`rank_p=2.81633e-07`、`result=significant`）。
整体均值按五类均值复算为 14102.96 / 14741.32 / 14363.16 / 14125.28ns，hardened − deployable
= 237.88ns、deployable − reference = +22.32ns 均一致。`outlier_removal=none`，CSV 里 58000ns
一类的长尾仍在，没有删普通长尾。

同一会话的声明核得住：四份 `.meta` 的 `test_seed=20260930`、`sample_count=25000`、
`order=balanced_fisher_yates_shake256_tag4`、`source_commit=0cba2c7…` 全部相同，
`wall_clock_unix_seconds` 为 1790823499/499/500/500。M1-9 的类别顺序一致性我直接在归档 CSV 上做
`cut -d, -f3` 逐字节比较，三对全部相同；`reference.csv` 前四条数据行是
`message-zero, valid, message-zero, message-zero`，类别顺序确实乱序而非分段。

跨会话引用逐字成立：归档 `docs/evidence/mitigation/hardened.report` 的最大 rank z 实测 2.1452
（README 写 2.15）、hardened 类别均值 14531.4–14552.4（写 14531–14552）、reference 14126.8–14168.0
（写 14127–14168）。README 与 `docs/mitigation.md` 两处都明写本次 238ns 与既有「约 400ns」属不同
会话、不得相减或互换。

### 摘要纪律与证据目录完整性

`record-checks.txt` 把 M1-6 的两条分开记：`openssl dgst -sha3-256` 对四个 `measure` 的输出与各自
`.meta` 的 `executable_digest` 逐个相同（四对十六进制串我逐字核对过），四份 CSV 的 SHA3-256 与
`.report` 的 `csv_digest` 逐个相同；`binaries.sha256` 明写由 `shasum -a 256` 另算、算法不同、
不做跨算法比对——模块零登记的「不得混用两种摘要算法」在这里落实了。`SHA256SUMS` 实测 30 行、
不含自身，设计 1.4 要求的 31 个文件一个不缺。fuzz 核对两次（采集目录与归档副本）都是 `exit=1`，
`build.log` 里三份补丁各一行 `patching file 'mlkem/src/compress.c'`、无 `with fuzz`。
`compile_commands.json` 确认 deployable 的四个编译单元 `-I` 首项是
`build/deployable/deployable-source/mlkem` 副本而非 vendor 原件。

`.gitattributes` 的两条按实测而非按预期添加：第一次 `git diff --cached --check` 报的是四份 `.meta`
第 32 行 `link_flags=` 的行尾空格（`exit=2`），于是加 `*.meta`；`record-checks.txt` 因为逐字收录了
那段带行尾空格的输出而在第二次检查时自己被报警，于是为它单独加一条路径限定条目，并写明**不用
`*.txt` 通配**以免顺带豁免同目录的反汇编文件。设计预期的 `*.log` 条目实测不需要、没有添加。

### 诚实性边界

README 的「不支持」清单把该否的都否了：不是上游漏洞的修复、不可能比 reference 更安全、0/10 不等于
证明恒时、反汇编结论只覆盖 Apple Clang 21 / ARM64 / RelWithDebInfo / Ninja 这一配置、macOS/ARM 与
模拟器不能冒充真实 x86_64 Linux、性能只在同一会话内有效、`__loop__` 丢失导致上游 CBMC 不覆盖这份
副本、deployable 的产物证据与另三个变体不是同一粒度因此不并列成等价表。

两处细节值得单独记：工作区状态按实测写成「被跟踪文件无未提交改动 + 两个未跟踪目录」，没有照抄
mitigation 的「`git status --porcelain` 为空」；设计列为可选的「无屏障掩码在 `-O2` 下的一次性
反汇编」未做，README 明写未做并声明因此不对「无屏障掩码是否会被还原成分支」给出任何本机结论——
可选项不做且不顺带下结论。预注册凭证 `adf9db9` 的三句边界声明（本地顺序效力、无第三方时间戳、
提交日期可改）逐字在篇首。

</details>

<details>
<summary>File map</summary>

提交 A `0cba2c7`（代码/配置）：

- `docs/patches/message-value-barrier.patch` — 新增，49 行：平铺 256 次系数循环 + 上游值屏障，
  无任何 `__attribute__`，保留编译期守卫与 `mlk_assert_abs_bound`，不保留 `__loop__`。
- `CMakeLists.txt` — `encoder_patch_deployable`、两个 `foreach` 列表加 deployable、
  `BASELINE_DEPLOYABLE=1`、两处 `equivalence_*` 注册改为对三个补丁变体的循环（测试名不变）。
- `src/mlkem.c` — `mlkem_implementation_name()` 加 `BASELINE_DEPLOYABLE` 分支。
- `tests/test_cli.sh` — 变体循环加 deployable；末尾跨变体 `cmp` 块改为对三个变体套循环。
- `tests/test_measurement.sh`、`tests/test_analysis.sh`、`tests/test_vector_parser.sh` — 变体循环各加
  deployable。

提交 B `343a6cb`（证据/文档）：

- `docs/evidence/deployable/` — 新目录 31 个文件：`README.md`（353 行，结论与边界）、
  四份 `*-encoder-arm64.txt`、四份 `*-caller-indcpa-enc-arm64.txt`、`deployable-path-arm64.txt`
  （17619 行全二进制）、`call-site-counts.txt`（M1-5a 三项计数与内联段佐证）、
  四份 `*.csv`/`*.meta`/`*.report`（各 25000 条）、`record-checks.txt`（摘要/顺序/fuzz/空白核对）、
  `configure.log`/`build.log`/`ctest.log`/`sanitize-ctest.log`/`compile_commands.json`、
  `binaries.sha256`、`SHA256SUMS`。
- `docs/mitigation.md` — 纯追加 116 行新章节（0 删除，既有结论未改写）。
- `.gitattributes` — 按实测加两条 `whitespace=-blank-at-eol`。

完整 diff：`git -C /Users/yin/code/cryProject show 0cba2c7` 与 `git -C /Users/yin/code/cryProject show 343a6cb`
预注册文本：`docs/tasks/four-module-design.md` 第 1 节（冻结于 `adf9db9`）

</details>
