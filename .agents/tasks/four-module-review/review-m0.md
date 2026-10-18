# 模块零评审：四模块设计定稿（第三轮 17 项发现的逐条核对）

有界评审：只核对 `docs/tasks/design-review.json`（第三轮，1 HIGH / 9 MEDIUM / 7 NIT，阻断 10 项）
登记的 17 条发现是否在 `docs/tasks/four-module-design.md` 中逐条落地，不另开放式挑错。入库提交
`adf9db9` 的 diff 只含一个文件（`docs/tasks/four-module-design.md`，+535/−92），未触及 `vendor/`、
`tests/vectors/`、`docs/evidence/` 任何路径。17 条全部有落点、10 条阻断发现全部解决，HIGH 发现 1 的
排序归属与分组不变式、发现 2 的 SHA3-256 口径、发现 7/8 的凭证诚实口径、发现 4 的容器容错都写死到
可照抄的程度。文档引用的实测锚点我按只读方式复核了关键几处——`src/analyze.c` 的 :81/:346/:647/:648、
`tests/test_cli.sh:41-44`、`reference.meta:16-17` 与 `record-checks.txt:5` 的 SHA3-256 逐字相同、
`CMakePresets.json:12,22-29`、`reference.csv` 前四条数据行的类别乱序、`docs/evidence/` 的 8 个目录与
各自 CTest 记录文件名——全部与文档一致。

**Watch for:**「可信时间凭证」类措辞已清除，全文命中只剩禁令本身（confirmed：篇首措辞禁令、3.2、
3.6、第 5 节未闭合项）；第 7、8 节的历史台账行保留了已被取代的旧措辞，靠紧随的「第四轮已修正」加注
与「冲突时以第 9 节与正文为准」消解（confirmed，非阻断）；发现 4 的第二处硬失败（反汇编前四个
`measure` 产物不存在）写在 2.2 的散文里、脚本骨架对应位置仍是 `…` 占位（confirmed，非阻断）。

**Verdict**: APPROVED

## High-level view

HIGH 发现 1 是唯一会造成「CTest 全绿但第二轮判定统计量算错」的问题，四项修订（排序归属的事实句、
六步固定顺序、两个无状态排序入口、M3-1 的乱序捕获场景）全部落地，其中新增的捕获场景在漏掉整份排序
时必然失败，这是让该错误不再静默的机械保证。

摘要算法纪律已统一：`openssl dgst -sha3-256` 对照 `.meta` 的 `executable_digest`、`binaries.sha256`
另算且不参与对照，M1-6 与 1.4 / M2-11 / 4.3 之间原先的算法冲突消除。

凭证诚实性是本轮改动最大的部分。篇首新增「预注册的性质与其边界」定型文字（本地仓库、从未 push、
无第三方时间戳、提交日期可改写，因此只是作者自证的顺序）与措辞禁令、三处逐字落点；0.1 新增
「模块零之后本文件冻结」的硬约束，M3-10 的行号更新改为只动新章节与证据 README，并给出必须修订时的
两哈希并列 + 预注册作废路径。「提交号 ↔ 预注册文本」这层绑定现在是闭合的。

模块二的容错与门禁补齐：`set -eu` 改为 `set -u` + `step-exits.txt` 逐步记录退出码、硬失败只保留两处
前置条件、反汇编与摘要不依赖 `ctest` 的退出码，失败时的证据因此仍然可得；新增 M2-4a 把 fuzz 门做成
与 1.2 同型的两次 `grep`；代理参数写进了 `docker run` 本身。

两处「择一写死」都选定并写出理由：模块二不归档二进制副本、`binaries.sha256` 对宿主可见的构建目录
路径算（与 `mitigation` 先例同型，四个新目录摘要对象口径一致）；评审产物保留单一文件名 + 如实声明
前两轮已被覆盖，并新增第四轮起 `review-m<模块号>-r<轮次>.{md,json}` 的互不覆盖规则。

7 项 NIT 全部落地。发现 12 的处置**故意偏离评审建议的措辞**并在 9.3 声明了偏离：json 建议写「七份带
`ctest.log`」，文档核对后指出只有 4 份叫 `ctest.log`，改为逐目录列出实际文件名。我复核了磁盘清单，
与文档一致——这是按实测改正，不是回避，不记为阻断。

<details>
<summary>Issues (3)</summary>

1. **2.4 未列 `attempt-failure.log`**（confirmed，非阻断）— 发现 6 要求 apt 失败时逐字保存到
   `docs/evidence/linux-amd64/attempt-failure.log`，2.2 写了、2.4 的文件清单没列；0.5 第 1 条的通用
   规则已兜住。模块二写 README 时补进清单即可。
2. **发现 4 的第二处硬失败只在散文里**（confirmed，非阻断）— 「反汇编与摘要之前四个 `measure` 产物
   不存在则硬失败」写在 2.2 的失败处置段，骨架对应位置是 `…` 占位。模块二落地时按散文补成实际代码。
3. **第 7、8 节台账保留旧措辞**（confirmed，非阻断）— 7.1 发现 2 的「时间凭证」、8.1 发现 2 与 8.2
   发现 6 的「归档八个产物副本」、8.3 第 3/12 行都已被取代，处置方式是加注而非改写。属有意选择
   （不改写历史记录），引用时须连带读加注。

</details>

<details>
<summary>Details</summary>

### HIGH 发现 1：分组排序归属与六步不变式

json 要求四项，逐项核对：

① 事实句。3.3 现在写「`load_measurement_set`（自 `:346` 起）只做逐行校验与 `append_record`，
全程不排序；排序发生在 `main`——`src/analyze.c:647` 的 `qsort(...)`，**之后**才是 `:648` 的
`build_series`」。源文件实测：

```
81:static int compare_measurement_record(const void *left, const void *right)
346:static int load_measurement_set(const char *csv_path, struct measurement_set *set)
405:static void build_series(const struct measurement_set *set,
647:    qsort(set.records, set.record_count, sizeof(*set.records), compare_measurement_record);
648:    build_series(&set, series);
```

四个行号与文档一致。json 发现 1 自己写的是「`load_measurement_set`（:349 起）」，文档写的 `:346`
才是实测值——此处文档取的是正确的那个数。

② 执行顺序。`analyze_groups` 的 `main` 固定为六步，第 2 步即「对整份 `set->records` 调用
`sort_records_by_category_then_duration`」，并标注这一步是第 3 步能按下标切组的唯一前提。原先缺失的
「整份按类别排序」现在是独立编号的一步，不再是夹在叙述里的默认前提。

③ 抽取入口。3.3 用表格把两个入口的语义与调用者写死：整份入口由 `src/analyze.c` 的 `main`
（替换那行 `qsort`，行为逐字不变，M3-2 兜住）与 `analyze_groups` 的 `main` 第 2 步调用；区间入口只有
`analyze_groups` 第 5 步调用，`src/analyze.c` **不调**。`compare_measurement_record` 随整份入口一起
移入 `src/timing_statistics.c`。3.7 的提交 A 清单同步写了 `src/analyze.c`（仅抽取 + 换那行 `qsort`，
不改比较族）。

④ 捕获场景。M3-1 新增「类别乱序输入」一条，行序按类别交替、恒定类全 1000ns、变化类全 2000ns，
断言 `count=20` / `count=30` / `rank_u1=0.0` / `effect_size_first_greater=0.000000` / `rank_z` 为负 /
`result=significant`，并明写「若漏掉 3.3 第 2 步的整份排序，这一条必然失败」，同时说明原有「完全分离」
场景若按类别分段写 CSV 就抓不到，所以两条都要有。文档引用的「真实 CSV 本身乱序」核对一致：
`docs/evidence/mitigation/reference.csv` 前四条数据行实测为 `message-zero, valid, message-zero,
message-zero`。

### 发现 2：SHA3-256 与 shasum 的算法纪律

M1-6 拆成两条，并把「为什么只有 SHA3-256 能对照」写进正文：`.meta` 实测
`executable_digest_algorithm=SHA3-256`（`reference.meta:16-17`），现成先例是 `record-checks.txt:5`
的 `SHA3-256(build/mitigation/reference/measure)= 4d677872…fba3c`。这两处我都核对了，摘要值逐字相同。
第二条明写 `binaries.sha256` 只为满足 0.4 第 3 条、「SHA-256 的值不可能等于 SHA3-256，不得比对、
不得改写任何一方」——即 M2-11 原本禁止的那种做法。M3-8 也补上了 `openssl dgst -sha3-256` 与同一条禁令。

### 发现 4：容器失败时证据还在不在

原设计的 `set -eu` 与 M2-4「允许警告并记录」、M2-5「失败或超时就记成缺口并继续」直接矛盾。现在 2.2
的骨架里：`set -u`；`: > /build/step-exits.txt` 开头清空；配置失败是硬失败（写退出码再 `exit 1`）；
构建、fuzz 核对、`ctest -N`、`ctest` 都走
`命令 > 日志 2>&1; echo "<step>_exit=$?" >> /build/step-exits.txt`；反汇编/调用点计数/摘要排在
`ctest` 之后且不依赖其退出码，理由写明（产物形态结论的对象是二进制，与测试是否全绿无关，QEMU 超时
不该连带毁掉形态证据）。2.4 清单补上 `step-exits.txt`、`configure.log`、`build.log`、
`ctest-list.log`、`ctest.log` 五个文件（json 只要求三个，这里是超集），README 的「未能完成的项」
必须引用 `step-exits.txt` 的实测退出码而不是无数字描述。

第二处硬失败（进入反汇编与摘要前四个 `measure` 产物不存在则退出）只写在骨架下方的失败处置段，骨架
对应位置仍是 `…  # M2-2、M2-3、M2-6…M2-9、M2-11 主路线的其余步骤` 占位。规则本身无歧义，非阻断。

### 发现 7 与 8：预注册凭证的绑定与强度

发现 8 要求的边界声明以**定型文字**形式落在篇首：假设文本在采集前入库（提交 `<模块零哈希>`）、
本仓库从未 push、`origin/main` 实测 `gone`、无第三方时间戳、提交日期可由作者设置，因此这是**作者
自证的顺序**、不是可向第三方证明的预注册，更强凭证需公开推送或外部时间戳服务、按 0.5 记未闭合项。
同段给出措辞禁令与三处逐字落点（模块三证据 README、`docs/acceptance.md` 追加章节、最终报告
「未闭合项」单列）。3.2 的标题从「凭证为 0.1 的模块零提交」改成「假设文本由 0.1 的模块零提交入库」，
3.6 展开同一口径并写明「本仓库对 QEMU、对种子 777 口头复核都用严格口径，对自己的凭证同样不得升级」。

措辞禁令的执行情况单独查过：全文「时间凭证 / 时间戳证明 / 可验证的预注册 / 可信时间」命中四处，
分别是篇首禁令本身、3.2 的「不得用『时间凭证』一类措辞」、3.6 的禁令、第 5 节「不得用『可信时间凭证』
一类措辞把它写成已闭合」——没有一处把该提交称作时间凭证。历史台账 7.1 发现 2 那行仍含旧措辞，
紧随其后有「第四轮已修正本行的措辞」加注。

发现 7 的三项都在：0.1 的冻结硬约束（模块零之后本文件不再修改，含行号、措辞、笔误；需要更新的事实
只进证据 README 与 `docs/statistics.md` / `docs/acceptance.md` 的新增章节并注明原文保持不变）；
M3-10 改为行号变化只更新新章节与 `statistics-multiseed/README.md` 并写出「本设计文件引用的 84 是
模块零时点实测值，插入后实测为 `<N>`」，明确不得回头改本文件；例外路径要求新的独立提交 + 两哈希
并列 + 说明是否触及 3.2 的第二轮假设，触及则该轮预注册作废、换全新种子重做。第 5 节的单列项同步
写了两哈希并列。

篇首另如实交代了 `68ba0c3` 已经把**修订前草稿**入库过一次、那次提交当时就自我声明不构成凭证，
并要求引用凭证时给出模块零提交的哈希而不是 `68ba0c3`——这处自指歧义没有被绕过去。

### 发现 9 与 10：摘要对象与评审产物命名

发现 9 选 (a) 不归档二进制副本：0.4 第 3 条改为「摘要对象一律是构建目录里的产物文件、不把二进制副本
拷进仓库」，列出三处实测依据（`mitigation/binaries.sha256` 七行全是构建目录路径、容器先例
`linux-gcc/` 连这两份文件都没有、`docs/evidence/` 下当前没有任何二进制文件）与体积数字（单个
`measure` 129KB、八个约 1MB、进 git 后按 0.3 不可删）；2.4 删掉副本行，M2-11 的宿主 `shasum -a 256`
对象改为 `/tmp/linux-amd64-build/cmake/<variant>/{baseline,measure}`。9.2 同时点明 8.2 发现 6 原先
声称的「清单一致」只在文件名层面成立，现在摘要对象口径才真正一致。

发现 10 选 (b)（保留单一文件名 + 声明来源限制）并补了向前的规则：`design-review.{md,json}` 自模块零
起冻结，第四轮起写入 `docs/tasks/review-m<模块号>-r<轮次>.{md,json}`。第 7、8 节首段各加同一句来源
限制（前两轮原文件已被覆盖、不可逐字复核，只以该两节逐条摘要留存），M4-5 与第 5 节同步。文档还纠正
了评审当轮的观察：`?? docs/tasks/` 已不成立，三个文件已随 `68ba0c3` 入库，因此 (a)「提交全部轮次
文件」在事实上无法执行。

### 发现 3、5、6 与 7 项 NIT

发现 3（`test_cli.sh` 末尾硬编码比较块）：1.2 贴出实测原文并写死改法（对
`vulnerable hardened deployable` 再套一层循环，或等效补一行），0.5 降级第 1 步的撤回清单加上
「还原 `test_cli.sh` 末尾比较块」。行号核对一致：41 行 `for category`、42/43 两条 `cmp`、44 行 `done`，
确实不在 `:6` 的变体循环内。另两处硬编码（`test_measurement.sh:29,32`、`test_analysis.sh:100`）按
json 的判断写进 1.2 说明不需要改。

发现 5（容器 fuzz 门）：新增 M2-4a，命令跑两次（容器内对 `/build/build.log` 用双引号模式避开外层
单引号、归档后对 `docs/evidence/linux-amd64/build.log` 用单引号），判据 `exit=1` 通过，`exit=0` 时
不得继续产出反汇编结论、按 0.5 记缺口并说明形态结论不成立；2.4 清单补上 `build.log`。依据核对一致：
`cmake/PrepareVariant.cmake:6` 只有 `COMMAND "${PATCH_EXECUTABLE}" -p1 -i "${PATCH_FILE}"`、
无 `--no-fuzz`；`docs/evidence/linux-gcc/README.md` 实测 GNU patch 2.7.6，并写了「两个补丁都无 fuzz
应用」这一先例。

发现 6（代理）：两个 `-e` 写进 `docker run`，并写明「这两个 `-e` 就是『走该代理』的全部实现，没有
别的隐含设置」；无代理时去掉并在 README 逐字写实际命令；apt 失败逐字存 `attempt-failure.log` 并按
0.5 记缺口，`openssl` 装不上时不得改用宿主算 SHA3-256 就当模块二完成。`attempt-failure.log` 未进
2.4 清单，见 Issues 1。

其余 NIT 逐条确认：11 在 1.2 贴出可照抄的 C 片段并解释 `uint16_t` 转换是为过 `-Wconversion -Werror`；
13 在 M4-7 写死 `--verify` 形式的实测输出（`fatal: Needed a single revision`、`exit=128`）并给 6.1
第 3 条加注；14 在 3.3 固定程序路径 `$1/analyze` 与两份用例表、两次 `cmp` 都必须通过；15 在 M1-5 与
M2-7 各加同一套四步口径（逐条列条件跳转 → 标注归属 → 写依据 → 无法判定按 0.5 记缺口，不得默认算作
循环边界）并声明 x86_64/GNU 侧助记符未观察；16 在 M3-5 写死 13 列制表符表头与列序、取值域与动机
复采四行的位置；17 给 1.4、1.5、3.5 的 `sanitize-ctest.log` 都标注来源配置并声明只用于功能正确性
——`CMakePresets.json` 核对一致：第 12 行 `"generator": "Unix Makefiles"`，sanitize preset
`binaryDir` 为 `build/cmake-sanitize`、`CMAKE_BUILD_TYPE=Debug`、`BASELINE_SANITIZERS=ON`。

发现 12 的实测清单我复核了磁盘：`completion`、`mitigation`、`review`、`statistics` 有 `ctest.log`；
`cmake` 是 `multi-config-ctest.log` + `sanitize-ctest.log`；`final` 是 `build-and-test.log` +
`sanitize.log`；`linux-gcc` 的 CTest 结果在 `verification.log`（第 128 行
`100% tests passed, 0 tests failed out of 13`）；`module3` 只有 `SHA256SUMS` 与 `encoder-arm64.txt`、
无任何 CTest 记录。0.3 新增的「已封存 = 当前 main 上已提交的 `docs/evidence/` 全部目录，实测 8 个」
定义与磁盘一致，`module3` 被写明「同样只读且不得回头补齐」。

### 只读边界与诚实性

提交 `adf9db9` 的 diff 只含 `docs/tasks/four-module-design.md`，`vendor/`、`tests/vectors/`、
`docs/evidence/` 下无任何改动。篇首状态段不再声称本轮跑过测试——旧版的「入库前实测 13 项 CTest
全通过、format-check 通过」已替换为「实现阶段尚未开始执行，本次修订只动 `docs/tasks/` 下的文件」，
与本次 diff 相符，没有把上一轮的检查结果挪来充当本轮证据。

</details>

<details>
<summary>File map</summary>

- `docs/tasks/four-module-design.md` — 本次提交唯一改动文件（+535/−92）：篇首新增预注册性质与措辞
  禁令；0.1 新增冻结约束、评审产物命名规则、模块零 diff 事实；0.3 定义「已封存」并列出 8 个目录；
  0.4 第 3 条改写摘要对象口径；0.5 补撤回清单项与 CTest 记录的准确表述；1.2 贴出 C 片段与
  `test_cli.sh` 改法；1.4/1.5 标注 sanitize 日志来源；M1-5/M1-6 写死分支判定口径与摘要双轨；
  2.2 改 `set -u` + `step-exits.txt` + 代理参数；新增 M2-4a；2.4 重写文件清单；M2-7/M2-11 同步；
  3.2/3.3/3.5/3.6/3.7 重写排序不变式、两个排序入口、重放用例、凭证边界；M3-1/M3-5/M3-8/M3-10 同步；
  M4-5/M4-7 与第 5 节同步；第 6/7/8 节加注更正；新增第 9 节（17 项逐条处置）。
- 完整 diff：`git -C /Users/yin/code/cryProject show adf9db9 -- docs/tasks/four-module-design.md`
- 登记发现：`docs/tasks/design-review.json`（第三轮，17 项）

</details>
