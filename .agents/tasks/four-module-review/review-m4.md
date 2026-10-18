# 模块四：新增自有代码的检查补齐与四模块收尾（本轮最终收敛核对）

本次提交 `a07bbc1` 只动文档与新证据目录：README 改写为四变体口径与 18 项 CTest，
`docs/acceptance.md` 与 `docs/review.md` 各追加一章，新增
`docs/evidence/review-four-module/`（14 个文件 + SHA256SUMS）。
它要回答的是「模块一到三新增的自有代码是否被纳入与既有代码同级别的检查」，
答案是全新构建目录零告警、18/18 CTest 两套配置各通过、首次覆盖
`analyze.c` / `analyze_groups.c` / `timing_statistics.c` 与
`-DBASELINE_HARDENED=1` / `-DBASELINE_DEPLOYABLE=1` 的静态分析四次调用均无诊断，
因此本模块没有产生 `fix:` 或 `style:` 提交。诚实性口径是本次核对的重点：
「仍未执行真实 x86_64 Linux 主机时序实测」在 README、acceptance、review、证据 README
四处均在位，模块二一律写成「模拟 linux/amd64 的产物形态与功能验证」。

**Watch for**：`README.md:12` 的「见第 5 节」在本次插入新第 5 节后指错了章节，
应为第 6 节（confirmed）；`build.log` 比实际构建短一行且与 `configure.log` 一样没有
`exit=` 标记，而证据表断言「配置 `exit=0`、构建 `exit=0`」（confirmed，缺证据）；
`final-recheck.log` 的 `ctest` 节选未标省略，0.93s 与 `ctest.log` 的 10.68s 表面矛盾
（confirmed，已核对本地 `LastTest.log` 为真跑 18 项，非造假）；
`docs/mitigation.md` 仍留「残差随运行波动／方向不一致」的旧措辞，与 README 新口径不一致
（confirmed）。全部为非阻断。

**Verdict**: APPROVED

## High-level view

只读边界成立。`git show HEAD --numstat` 实测 `docs/acceptance.md` 201 增 0 删、
`docs/review.md` 35 增 0 删，两份都是纯追加；HEAD 触及的既有文件只有
`README.md`、`docs/acceptance.md`、`docs/review.md` 三个，`docs/evidence/` 下十一个已封存目录
与 `vendor/`、`sources/`、`tests/vectors/` 一字未动；`docs/tasks/` 自模块零提交 `adf9db9` 起
无任何提交触及。

预注册完整性成立。设计文件篇首「预注册的性质与其边界」定型文字在三处落点
（设计模板、`evidence/statistics-multiseed/README.md`、`docs/acceptance.md` 的追加章节与
「未闭合项」单列）逐字一致，禁用措辞「可信时间凭证／时间戳证明／可验证的预注册」
在本次所有改动文件中零命中。第二轮的水平 1e-3、单比较、五个公开种子
（31337、90210、20261111、8675309、141421356）、每版 25000 条，与设计 3.2 登记值一致；
hardened「五个种子全部不显著」的预期未成立这件事，数值
（4/5 不显著、残差 −30.067 至 −12.967ns、一个种子越阈）在 README 与 acceptance 两处都照实写出。

诚实性口径成立。README 把原来较弱的「尚未执行真实 x86_64 Linux 主机验证」改成了更强的
「**仍未执行真实 x86_64 Linux 主机时序实测**——模块二的 QEMU 模拟不改变这一条」，
并在第 7 节把两次容器验证的时钟分辨率（都是 1ms）与「不产出时序证据」写在同一句里，
解释器 `/usr/bin/qemu-x86_64` 的实测值也保留。
两次容器的 13 项 / 16 项都标注为「当时的实测值」并说明与现在 18 项的差额来源，
我按 `evidence/linux-amd64/README.md` 与 `evidence/linux-gcc/README.md` 核对一致。

全量复核如实记录。18 项 CTest 在 `build/review-four-module`（Ninja/RelWithDebInfo）与
`sanitize` preset（Unix Makefiles/Debug/ASan+UBSan）各 100% 通过，sanitize 日志里
AddressSanitizer / UBSan / LeakSanitizer / runtime error 四类关键词实测 0 命中；
`SHA256SUMS` 覆盖本目录除自身以外全部 14 个文件并全部 `OK`；六个在先提交的分支、作者、
提交者、邮箱、hash 逐字归档且与当前 `git log` 一致，第七个提交（本提交）由我独立核对为
`main`、作者与提交者均 `Gowin-liuyin <yinhaoran0808@outlook.com>`。未 push 的三条实测
（`git remote -v`、`git branch -vv` 的 `[origin/main: gone]`、`git rev-parse --verify origin/main`
的 `exit=128`）与设计写死的预期输出逐字相符。

证据的薄弱处集中在「exit 标记与节选标注」这一类，不改变任何结论：`configure.log`、
`build.log` 没有 `exit=` 行且 `build.log` 停在 `[72/73]`；`static-analysis.txt` 四次调用只归档
`exit=0`，「无诊断」靠捕获为空而不是显式计数；`final-recheck.log` 的 `ctest` 只留了尾部两项
与汇总行。前两项是归档完整度问题，第三项我做了本轮唯一一次窄 spot-check 并证实为真。

文档一致性有一处待收尾：README 关于 hardened 残差的措辞已按多种子结果改成「方向一致」，
但 README 直链的 `docs/mitigation.md` 仍写「残差随运行波动」「方向不一致」，
且没有指向多种子章节的更正指针——`docs/statistics.md` 有这样的指针，`mitigation.md` 没有。
模块四的注册编辑范围只含 README / acceptance / review，所以这属于合理延后而非遗漏，
但它现在是读者会撞到的不一致。

<details>
<summary>Issues (8)</summary>

1. **README 交叉引用错位** — `README.md:12` 的「（上游该函数本来就无分支，见第 5 节）」在本次插入新第 5 节「第二轮预注册的分组检验」后指错章节；该论述位于第 6 节「四个变体的关系」，应改为「见第 6 节」。
2. **`build.log` 短一行且无 exit 标记** — 日志 76 行、末行为 `[72/73] Linking C executable analyze_groups`，缺最后一个构建步骤，也没有其他日志都有的 `exit=0` 行，而证据 README 的表格断言「构建 `exit=0`」。补齐末行与 exit 标记，或在文内写明截断。
3. **`configure.log` 无 exit 标记** — 同表断言「配置 `exit=0`」，但该日志只有 CMake 输出、没有 `exit=` 行。补一行即可。
4. **`final-recheck.log` 的 ctest 节选未标省略** — 只留 `17/18`、`18/18` 与汇总行，加上 `Total Test time 0.93 sec` 与 `ctest.log` 的 `10.68 sec` 并列，表面像是没跑全。我已核对 `build/review-four-module/Testing/Temporary/LastTest.log`（13:01、18 项全 `Test Passed`、逐项时间合计 0.91s，首跑慢是新构建二进制首次执行开销），结论为真；建议加一行省略标记与时间差的一句说明。
5. **静态分析「无诊断」只有空捕获为证** — `static-analysis.txt` 四段只有 `exit=0`，没有显式的诊断计数或「stdout/stderr 捕获为空」的声明，证据强度低于本目录其他日志。补一句捕获口径说明。
6. **最终报告 §3 未给出具体地址** — 设计第 5 节第 3 条要求「哪个二进制、哪个地址、什么指令」；该小节给了二进制、调用者层级与指令，地址只以「不跨构建复用」加证据目录指针代替。补指针到具体地址行或明写为何不复述。
7. **`docs/mitigation.md` 与 README 新口径不一致** — `mitigation.md:57,174` 仍写「残差随运行波动」「方向不一致」，已被模块三五种子结果（方向一致、−30 至 −13ns、一个种子越阈）取代，且该文件无指向多种子章节的更正指针（`statistics.md` 有）。下一轮按 `statistics.md` 的做法补一条更正指针。
8. **「预期未成立」字样未带入模块四文档** — README 第 5 节与 acceptance 最终报告 §6 都给出了 hardened 4/5 不显著、1/5 显著的数值，但未沿用设计 3.2 要求的「预期未成立」标签；该标签在 `evidence/statistics-multiseed/README.md:316` 在位，故为措辞一致性问题而非隐瞒。

</details>

<details>
<summary>Details</summary>

### 只读边界与追加式写法的实测口径

本轮三条只读边界都能从 `--numstat` 直接判定，不需要逐段比对文本：

```
201 0 docs/acceptance.md     ← 纯追加
 35 0 docs/review.md         ← 纯追加
100 34 README.md             ← 允许改写（非验收章节）
15 个新文件 × 0 删            ← 新证据目录
```

`git log adf9db9..HEAD -- docs/tasks/` 为空；`docs/tasks/four-module-design.md` 的提交历史
只有 `68ba0c3`（修订前草稿）与 `adf9db9`（入库）两条，与 acceptance「引用凭证时不要指向
`68ba0c3`」的说明一致。

README 的 34 行删除里有两处是实质改写，都值得点出方向：原「尚未执行真实 x86_64 Linux
主机验证」被换成更强的否定句并点名 QEMU；原「残差随运行波动，不宣称防护版已证明恒时」
被换成基于五种子的「方向一致、量级 −30 至 −13ns，其中一个种子越过第二轮阈值；
仍不宣称防护版或可部署版已证明恒时」。后者是把一个不利事实（越阈）主动写进 README，
不是削弱限定。README 第 7 节的下一阶段句同时删掉了「并对打开优化后的恒时编码逐个反汇编确认」
——该工作已由模块一完成，而 acceptance 的既有章节仍保留原句（追加式写法的必然结果）。

### 18 项 CTest 的两套配置与 0.93s 的那个疑点

`ctest.log` 的 `ctest -N` 列出 18 项并给出 `100% tests passed, 0 tests failed out of 18`，
新增的三项相对上一轮的 15 项分别是 `deployable_kat`、`deployable_random_failure`、
`equivalence_deployable`（模块一）与 `analysis_groups`、`analysis_round1_replay`（模块三）。
`analysis_round1_replay` 的存在本身就是对「第二轮没有改动第一轮族」的机械化保证：
它重放第一轮归档报告并要求逐字相同，所以第二轮程序一旦污染第一轮口径，这项会红。

`final-recheck.log` 里同一目录的复跑写着 18 项全过、`Total Test time (real) = 0.93 sec`，
而 `ctest.log` 的首跑是 10.68 sec。单项最慢的 `measurement` 在首跑是 2.05 sec，
串行下 0.93s 装不下 18 项，所以这一处值得查。我读了
`build/review-four-module/Testing/Temporary/LastTest.log`（13:01，与提交时间 13:02 吻合）：

```
1/18 Testing: reference_kat      Test time = 0.02 sec   (首跑 0.78)
...
18/18 Testing: vector_integrity  Test time = 0.01 sec
逐项时间合计 = 0.91 sec，Test Passed 出现 18 次
```

即首跑的 10.68s 几乎全是 macOS 对全新构建二进制的首次执行开销，复跑降到 0.9s 量级是正常的。
日志为真，问题只在于节选没标省略、也没解释这个 12 倍差，读者第一眼会怀疑没跑全。

### 静态分析的首次覆盖与宏设置的实际作用面

四次调用是「默认 / `-DBASELINE_VULNERABLE=1` / `-DBASELINE_HARDENED=1` /
`-DBASELINE_DEPLOYABLE=1`」各一次，八个自有源文件，命令与设计 M4-2 写死的那段逐字一致，
`-I` 从既有 `build/cmake/generated/RelWithDebInfo` 换成本模块自己的
`build/review-four-module/generated/RelWithDebInfo`，差异按要求写进了文件。

文件末尾那句「三个 `BASELINE_*` 宏只在 `src/mlkem.c` 被读取（实现名选择），
所以四次设置只在该翻译单元不同，其余七个源文件是在同样文本下被分析四次」是准确的——
我 grep 全 `src/` 只命中 `src/mlkem.c:8-13` 的 `#ifdef / #elif` 实现名返回。
这句话同时也限定了本次「首次覆盖两个宏」的实际收益：收益在于首次分析了
`analyze.c`、`analyze_groups.c`、`timing_statistics.c` 三个新文件，
两个新宏带来的增量只有 `mlkem.c` 一个分支。文件没有夸大这一点，但也没有点明收益的不对称。

唯一的薄弱处是归档形态：四段只有 `=== macro=... ===` 与 `exit=0`，没有显式的
「捕获为空」或诊断计数。`clang --analyze -analyzer-output=text` 的诊断走 stderr，
空捕获确实等价于无诊断，但同目录其他日志（`shell-syntax.log`、`cmake-format.log`）
都有「命令 + 输出 + exit」的完整三段，这里只剩 exit，自证强度低一档。

### 预注册凭证的三处落点与评审产物的落点偏差

定型文字的四处实例——`docs/tasks/four-module-design.md:41-47`（模板）、
`docs/evidence/statistics-multiseed/README.md:13-19`、
`docs/acceptance.md:78-84`（追加章节首部）与 `docs/acceptance.md:199-205`（未闭合项单列）
——除模板的 `<模块零提交哈希>` 占位被替换为 `adf9db9d2734837de11274343d3828d49d0f2444`
外逐字相同；README 第 5 节是设计未要求的第四处落点，用压缩版表述，结论不弱于定型文字。

acceptance 主动记录了一处与设计不符的事实：设计 0.1 规定模块零之后各轮评审产物写入
`docs/tasks/review-m<模块号>-r<轮次>.{md,json}`，实际落在未跟踪的
`.agents/tasks/four-module-review/`，`.agents/` 全程未提交，因此「四份判定均为 APPROVED、
无阻断发现」只能由作者转述。这一条在 acceptance 的「来源引用的限制」、「未闭合项」第 3 条
与 `docs/review.md` 追加节三处都写了，并按 0.5 记为缺口。
我这份 `review-m4.md` 同样落在该未跟踪目录，所以这条缺口在本轮结束时依然成立。

### 第二轮预注册的数值与设计登记值对账

逐项核到设计 3.2：

| 登记项 | 设计 3.2 | README / acceptance 报告值 |
|---|---|---|
| 水平 | `alpha_per_comparison=0.001`、`comparison_count=1` | 1e-3、单比较 |
| 种子 | 31337 90210 20261111 8675309 141421356 | 同一集合（排列不同） |
| 样本量 | 每类 5000、每版 25000、4×5=20 次 | 五种子 × 四变体各 25000 条 |
| vulnerable 预期 | 5/5 显著、均值差 ≤ −300 | 5/5 显著、−663 至 −776ns |
| reference/deployable 预期 | 5/5 不显著、\|均值差\| ≤ 150 | 各 5/5 不显著 |
| hardened 预期 | 5/5 不显著 | **4/5 不显著、1/5 显著** |

`−663 至 −776ns` 对应证据的 `−663.2 至 −775.5ns`（取整后放大幅值，
`evidence/statistics-multiseed/README.md:337` 自己也用这个取整形式）；
`0.1557–0.2481` 对应 `0.155744 至 0.248095`；hardened 的 `−30 至 −13ns` 对应
`−30.067 至 −12.967ns`；deployable 的 `−13.8 至 +52.3ns` 对应 `−13.833 至 +52.300ns`；
第一轮主比较失败的 `4/5`、`−11.4 至 −81.4ns` 对应证据第 435-436 行。

hardened 这一行是本轮唯一的预期落空。README 第 5 节、acceptance 最终报告 §6、
「新确立的结论」第 5 条三处都写出了数值与「其中一个种子越过第二轮阈值」，
没有丢种子、没有改阈值。缺的只是设计 3.2 要求的「写成『预期未成立』」这个标签——
该标签在模块三证据 `README.md:316` 以
「**hardened：预先写下的期待未成立（偏离，照实记录，不丢种子、不改阈值、不换种子重来）**」
在位，所以模块四文档是在转述一个已被正式标注为偏离的结果，属措辞一致性问题。

两轮阈值 10 倍差这条最容易被无据升级的路径被堵住了：acceptance 最终报告 §6 保留了
「**不得**把第二轮成立读成对第一轮同一假设的更强证实」，README 新增的 FAQ
「两份报告结论不一致」做同样的隔离（1e-4 对 1e-3、不同假设）。

### README 新口径的事实校验与一处引用错位

我按文档校验了四类可机械核对的 README 断言：

- `analyze_groups CSV_FILE REPORT_FILE` 与 `src/analyze_groups.c:197` 的 usage 串一致。
- 「十类畸形 CSV 拒绝」与 `tests/test_analysis.sh` 的 corruption 列表恰好 10 条一致。
- 「四版真实数据全流程」与同文件 `for implementation in reference vulnerable hardened
  deployable` 一致。
- 两次容器的 13 项 / 16 项与 `evidence/linux-gcc/README.md:18`、
  `evidence/linux-amd64/README.md:195` 一致，16+2=18 的差额说明（第二轮两项测试在其后加入）
  与 `ctest.log` 的 `analysis_groups`、`analysis_round1_replay` 两项对得上。

错位的一处在章节号：本次在第 4 节后插入新的第 5 节，原第 5–8 节整体后移一位，
文首第 12 行的「（上游该函数本来就无分支，见第 5 节）」没有跟着改。
现在第 5 节是「第二轮预注册的分组检验」，不提上游无分支；该论述在第 6 节
「四个变体的关系」里（「上游 `mlk_poly_frommsg` 本来就是无分支实现，所以**防护版和可部署版
都不是「修复」**」）。全仓库没有其他地方按节号引用 README，所以影响面只有这一行。

### 第七个提交的身份核对为什么只能从仓库读

`git-log.txt` 覆盖 `adf9db9~1..HEAD`（抓取时 HEAD 为 `4ce2133`）共六个提交，
含模块零提交，六个的分支/作者/提交者/邮箱/hash 与当前 `git log` 逐一吻合，
`git config --local` 两项也归档了。第七个提交就是承载这份证据的提交本身，
无法把自己的 hash 写进自己的文件，acceptance 的表格因此写「见 `git-log.txt` 与 `git log -1`」。
我独立核对了它：`main`、`a07bbc19...`、作者与提交者均
`Gowin-liuyin <yinhaoran0808@outlook.com>`。这是归档形态的固有限制，不是遗漏，
但它意味着「本轮七个提交身份全部合规」这句话有一个环节必须由复核者现场执行一条命令。

「未 push」的三条实测与设计 M4-7 写死的预期输出（含 `fatal: Needed a single revision`、
`exit=128`）逐字相符；未执行 `fetch`、未执行 `push`，`git status --porcelain` 现在只剩
`?? .agents/`。

### 产物摘要的独立性与最终报告的格式对账

`record-checks.txt` 的判据来自独立工具：`openssl dgst -sha3-256` 算十个产物摘要，
再与四个变体小样本 `measure`（每类 50，`RUN_ID=review-<variant>`）`.meta` 里程序自报的
`executable_digest` 对照，四对逐个相等，因此 0.4 第 5 条「不用被测程序给自己作证」成立。
`analyze` / `analyze_groups` 不自报摘要，文件写明其摘要只是独立工具值。
`SHA256SUMS` 我实测 14 个全部 `OK`，`diff` 确认唯一未列项是 `SHA256SUMS` 自己。

最终报告按设计第 5 节对账：六个分节标题（功能正确、源码秘密依赖、产物机制、原始数据、
观察差异、正式统计确认）与五个单列项（新确立的结论、未闭合项、新增提交数与 `ctest -N` 实测数、
每模块提交身份核对、来源引用的限制）逐一在位；未闭合项含 ① 真实 x86_64 Linux 时序实测
② 定型文字逐字写出的本地顺序凭证两条。
§3 产物机制分「ARM64 实测（独立符号；deployable 为调用者内联段，层级取 `indcpa_enc`）」
与「模拟 amd64（同上，`baseline_native_indcpa_enc` 内联段）」两类并注明证据粒度，
符合 M1-5a / M2-7a；但设计第 5 节第 3 条还要求「哪个地址」，这一项只以
「地址与反汇编结论不跨构建复用」加证据目录指针代替，没有给出地址行。

### 与前几轮评审的衔接

模块零至三四份评审均为 APPROVED，共 1 MEDIUM + 21 NIT。其中与本模块直接相关的一条
——模块三的 NIT「`format-check` 结果未归档（缺证据）」——本轮已闭合：
`format-check.log` 归档了 `build/review-four-module` 与 `baseline` preset 两次调用、
formatter 解析路径与版本，`docs/review.md` 追加节也点名了这条闭合。
模块一的 MEDIUM（内联判据正则丢 `$` 转义，`$0x681` 覆盖主张不成立）未在本模块文档中被复述
（grep `0x681` 在 README / acceptance / review 零命中），因此不构成本轮的新结论风险。

</details>

<details>
<summary>File map</summary>

| 文件 | 本次变化 |
|---|---|
| `README.md` | 三变体改四变体、18 项 CTest、新增第 5 节分组检验、章节号后移、QEMU 与 x86_64 未实测口径加强、三条新 FAQ |
| `docs/acceptance.md` | 纯追加「四模块收尾」章节（201 行）：预注册凭证与边界、逐项核对表、最终报告六分节 + 五单列项 |
| `docs/review.md` | 纯追加模块四检查范围、修正项（无）、实测平台与边界 |
| `docs/evidence/review-four-module/README.md` | 新证据目录总入口：平台、配置归属、覆盖表、复现命令、结论边界、两条未闭合项 |
| `.../configure.log`、`build.log` | 全新构建目录的配置与构建输出（无 `exit=` 标记，`build.log` 停在 `[72/73]`） |
| `.../ctest.log`、`sanitize-ctest.log` | 两套配置各 18/18 的逐字输出 |
| `.../static-analysis.txt` | 实际 `-I` 路径、与既有目录的差异、四次调用的 `exit=0` |
| `.../format-check.log`、`cmake-format.log`、`shell-syntax.log` | 格式与脚本语法检查（8 个脚本 `sh -n`） |
| `.../readme-examples.log` | README 新示例命令的实际执行输出（标注为接口 smoke、非统计材料） |
| `.../final-recheck.log` | 文档改动后的摘要复验、全部 CTest、format-check（ctest 段为未标注的节选） |
| `.../git-log.txt` | 六个在先提交的身份核对与未 push 的三条实测 |
| `.../binaries.sha256`、`record-checks.txt`、`SHA256SUMS` | 十个产物摘要、独立 SHA3-256 对照与 `git diff --cached --check`、目录自摘要 |

完整 diff：`git -C /Users/yin/code/cryProject show a07bbc1`

</details>
