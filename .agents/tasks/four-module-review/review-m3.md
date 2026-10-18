# 模块三评审：第二轮预注册分组检验 + 多种子稳健性证据

模块三由两个提交构成：`268bab8` 把 `src/analyze.c` 的加载/校验/分位点/检验部分抽到
`src/timing_statistics.c` + `include/timing_statistics.h`，新增独立程序 `analyze_groups`
与两个 CTest（`analysis_groups`、`analysis_round1_replay`）；`4ce2133`（HEAD）归档
`docs/evidence/statistics-multiseed/`（20 次预注册采集 + 4 次种子 777 动机复采、24 份
`.groups.report`、汇总表、`record-checks.txt`、三份构建日志、SHA256SUMS）并向
`docs/statistics.md` 追加第 8 节。核心争议点——第二轮分组是否先对**整份** records
按类别排序——我用三条互不依赖的路径确认成立：源码六步流程、类别乱序合成 CSV 的 CTest、
以及用仓库外的独立实现从 24 份原始 CSV 重算全部第二轮统计量（逐字段相同）。
诚实性方面，第一轮三个归档 p 值、种子 777 的三个未归档 p 值、第二轮「看过数据后提出」的标注、
两轮阈值 10 倍差、hardened 的预期未成立，都按实测写出，无一处被抹过去。

**Watch for:** M3-3 要求的 format-check 结果在模块三证据目录里没有任何落盘记录（confirmed，缺证据）；
README 的「全部 7 份归档 CSV」漏数了 `docs/evidence/deployable/` 的 4 对归档，实际是 11 对
（confirmed，我 11 对全部重放逐字节相同，结论比声称的更强）；类别乱序场景的实际捕获点
比设计预期更早（已在证据里如实披露，confirmed）。

**Verdict**: APPROVED

## High-level view

第二轮用独立程序而不是往第一轮族里塞比较，这个结构选择把「第一轮结果未被动过」变成可机器验证的事：
`analysis_round1_replay` 在仓库根目录重放归档 CSV 并逐字对比。抽取的无损性我独立复核过——
`src/analyze.c` 被删掉的 419 行里只有 9 行在新文件中没有原样副本，而这 9 行全是去掉 `static`
后的函数签名与一句重写的注释；11 份归档第一轮报告用抽取后的 `analyze` 重放，**不屏蔽**
`welch_p=`/`rank_p=` 就已全部逐字节相同。

分组不变式是这个模块唯一会「静默算错且 CTest 全绿」的地方，实现把它放在 `main` 的六步流程里：
加载不排序 → 对整份数组按类别再按耗时排序 → 校验五类齐全且等量 → 记区间 → 才对两个组区间按耗时重排
→ 计算并写报告。`_Static_assert` 把类别枚举的取值顺序钉死。乱序 CSV 的 CTest 存在且会失败，
只是失败点落在第 3 步的等量校验而不是设计预期的统计量断言——证据目录自己写出了这个差别。

多种子结果里真正值得注意的是 hardened：预注册写的是「reference / hardened / deployable 五个种子
全部 not_significant」，实测 hardened 在种子 141421356 判显著（`rank_p=1.42602e-05`），
另外四个种子的 `rank_p` 落在 0.001–0.0042，与 1e-3 阈值同数量级。文档把它写成「预期未成立」，
没有丢种子、没有改阈值、没有换种子重来，并把第一轮族在该种子上的 1/10 一并写出。

证据链与汇总表都能脱离被测程序复算：摘要三方对照全通过，汇总表 26 行用我自己的解析器从归档报告
重新生成后逐字节相同，24 份 CSV 的记录数/每类样本数/序号连续性与「样本量未缩减」的声明一致。

未闭合的是检查记录而不是结论：format-check 没有归档件，`analysis_round1_replay` 的机器化覆盖是
11 对归档中的 2 对（设计故意写死为两对），其余 9 对只有一次性手工核对（我已复现）。

<details>
<summary>Issues (7)</summary>

1. **format-check 结果未归档（缺证据）** — M3-3 把「format-check 通过」列为验收项，但
   `docs/evidence/statistics-multiseed/` 只有 configure/build/ctest/sanitize-ctest 四类日志，
   全目录 grep 不到任何 format-check 命令或输出；3.5 的文件契约也没要求这份日志。
   模块四按 M4-1/M4-3 收尾时把实际命令与输出落盘。
2. **「全部 7 份归档 CSV」漏数 4 对** — README 的重放小节称覆盖「全部 7 份归档 CSV」，
   但仓库里有 11 对归档 CSV+report（多出 `docs/evidence/deployable/` 的四个变体）。
   我 11 对全部重放、全部逐字节相同，所以结论成立且更强，只是「全部」这个词不实。
   后续引用时改成「statistics/ 与 mitigation/ 的 7 份」或直接写 11 份。
3. **乱序场景的捕获点比设计预期早** — 设计 3.4 预计漏掉整份排序会表现为 `rank_u1` 不为 0、
   效应量不为 0.000000；实现在第 3 步（五类齐全且等量）就先拒绝，因此该场景的统计量断言
   在这条路径上不起判别作用。捕获结论不变，证据 README 已如实披露；记录在案供模块四引用。
4. **`analysis_round1_replay` 的机器化覆盖是 2/11** — 设计故意把用例写死为两份，其余 9 对归档
   只靠一次性手工核对（本次我已全部复现）。若希望长期防回归，模块四可考虑把用例表扩成全部归档对。
5. **「约十分之一量级」比实测宽松** — 五个新种子上第一轮主比较 |均值差| 与第二轮主效应之比实测为
   1.7%、2.7%、4.2%、5.1%、10.9%，只有一个种子接近十分之一。该措辞让第一轮主比较显得相对更大，
   建议后续写成「百分之几到十分之一」。
6. **「statistics/ 那一轮」的主效应上端未含复采** — 新章节写该轮效应量 0.819–0.844、|z| 62–67，
   这正是 `statistics/vulnerable` 单份的区间；同目录的 `vulnerable-replication` 实测达 0.847 与 67.9。
   措辞原样来自已冻结的设计文件与既有 `docs/statistics.md:70-72`，不是本次新引入，
   但「那一轮」可能被读成包含复采。引用时写明是哪一份。
7. **degenerate 情况下 stdout 印 `rank p=1`** — `analyze_groups` 的结尾 `printf` 用
   `result.has_rank_test ? result.rank_p_value : 1.0`，无变化数据时控制台会显示一个报告里
   故意不写的 p 值。与 `src/analyze.c:193` 的既有写法完全一致，且 stdout 不进归档证据，优先级低。

</details>

<details>
<summary>Details</summary>

### 分组不变式：整份排序与它的三道独立确认

`analyze_groups` 的 `main` 按设计固定为六步，顺序本身就是不变式：

```
load_measurement_set(csv)                 ← 不排序，类别在文件里是乱的
  ↓
sort_records_by_category_then_duration()  ← 整份数组：先类别索引、后耗时
  ↓
count_sorted_categories()                 ← 五类必须连续出现且每类等量，否则退出 1
  ↓
varying = records[0 .. 3n)                ← 枚举顺序由 _Static_assert 钉死
constant = records[3n .. 5n)
  ↓
sort_range_by_duration() ×2               ← 原地重排两段，此后不再按类别取视图
  ↓
compare_series(constant, varying) → 报告
```

`count_sorted_categories` 跑在整份排序之后，因此它既校验齐全性又顺带兜住排序：乱序输入下
第 0 类的连续段会在第二条记录就断掉、计数为 0 → 拒绝。「漏掉第 2 步」因此有两道闸门，
不是只靠统计量断言。

最强的一道确认来自仓库外的独立实现：我用 Python 按**类别标签**（不依赖程序的下标切法）从 24 份原始
CSV 重新分组，自己实现并列修正 + 连续性校正的 Mann-Whitney U，与归档 `.groups.report` 的
`rank_u1`、`rank_z`、`rank_p`、`effect_size_first_greater`、`mean_difference_ns`、
`median_difference_ns` 以及两条 `group=` 行的全部字段逐一对比：**24 份零不一致**。
分组若切错，按标签分组的结果必然与之不同，所以归档产物里的分组是对的，不只是源码读起来是对的。

乱序 CSV 的 CTest 按类别交替写行，先断言前五行类别顺序确实是
`valid message-zero bit-flipped message-ones random`，再要求报告与「按类别分段写出」那一份的断言
完全相同（`count=20`/`count=30`/`rank_u1=0.0`/效应量 `0.000000`/`rank_z` 为负/`significant`）。
两组若被互换，count 断言同样会抓到。证据 README 记录了去掉第 2 步的实测探针，并写明失败点与
设计预期不同（issue 3），而不是悄悄把措辞对齐设计。

### 共用部分抽取与第一轮的逐字不变

`src/analyze.c` 的改动只有两行新增（`#include "timing_statistics.h"`、把 `qsort(...)` 换成
`sort_records_by_category_then_duration(...)`），`prespecified_comparisons`、
`ANALYSIS_FAMILY_ALPHA`、`ANALYSIS_COMPARISON_COUNT` 在 diff 里零命中；被删除的 419 行只有 9 行
在新文件中没有原样副本，全部是 `static` 去掉后的签名与一句改写的注释。

行为层面：用 `build/multiseed/analyze`（抽取后构建、摘要已记入 `binaries.sha256`）重放全部
**11** 对归档 CSV/报告（`statistics/` 4 对、`mitigation/` 3 对、`deployable/` 4 对），
不屏蔽 `welch_p=`/`rank_p=` 就全部逐字节相同。README 只声称其中 7 份却写作「全部」（issue 2），
机器化回归只盯住 2 对（issue 4）。

### 预注册完整性与偏离的处理方式

`docs/tasks/four-module-design.md` 的提交历史只有 `68ba0c3`（草稿）与 `adf9db9`（模块零），
模块三两个提交都没有碰它；五个种子在 `adf9db9` 的 3.2 节文本里，且在 `268bab8` 这棵树上除设计文件
以外零命中，即采集前从未用过。第一轮比较族与 `docs/statistics.md` 既有结论都没有被改写
（该文件 172 行新增、0 行删除）。

hardened 的偏离被当成结论而不是噪声：种子 141421356 判 `significant`
（`rank_p=1.42602e-05`、`rank_z=−4.3398`、按 1e-4 同样显著），第一轮族在该种子上 1/10
（`bit-flipped:message-zero`、`rank_p=6.55699e-05`），这两个数字我从归档报告复核过。
更尴尬的一条也写出来了：种子 20261111 的 `rank_p=0.00100445` 只比 1e-3 阈值高一点就判了不显著。
「五个种子方向一致为负的小残差」有数据支撑（均值差 −12.967 … −30.067 全为负），
并紧跟一句「本次没有做机制分离实验，不给机制归因」。

种子 777 的处理符合 3.1：三个未归档 p 值（0.923 / 0.844 / 0.516）逐字写出并标注「未归档、
无法从本仓库复现的口头复核」，动机复采另立四行 `prespecified=no` 排在表尾、不参与任何计数，
重采值与原值并列成表、不互相替换。我核对了重采四行的第一轮主比较实测值
（−10.000/0.397325、−30.000/0.000845961、+25.500/0.765653、−19.000/0.367708），与文档一致。

### 诚实性字段与措辞核对

第一轮三份归档报告的数字与新章节表格逐字一致（`statistics/vulnerable` −83.200 / −4.0408 /
5.32762e-05 / significant / 7-of-10；`vulnerable-replication` −55.800 / −4.8309 / 1.35919e-06 /
significant / 7-of-10；`mitigation/vulnerable` −84.200 / −3.8338 / 0.000126165 /
**not_significant** / 6-of-10），没有被四舍五入成更好看的形式，第三份的 not_significant 也没被淡化。

预注册凭证的强度边界：README 的引文与设计篇首的定型文字在替换哈希后逐字相同（规范化比对）。
全仓库 grep「可信时间凭证」「时间戳证明」「可验证的预注册」只命中设计文件里的禁令本身。
`.groups.report` 的两个机器可读诚实性字段与 `round1_alpha_per_comparison_for_reference=0.00010000`
齐备，字段名与顺序按 3.3 的契约逐行对上。

vulnerable 五个种子的 `rank_p` 都印作 `0`，两处文档都写明这是 `erfc` 在 |z| 很大时的下溢、
不是精确零、应以 `rank_z` 为准；派生列 `round2_significant_at_1e-4` 用设计写死的 awk 判据，
`rank_p` 缺失写 `na`（本次 24 份都有 `rank_p`，故无 `na`）。

### 证据链、原始数据与 M3-5 汇总表

独立复算过的摘要：`shasum -a 256 -c SHA256SUMS` 105 行全 OK（目录 106 个文件，清单不含自身）；
24 份 CSV 的 `openssl dgst -sha3-256` 与 `.report`/`.groups.report` 两处 `csv_digest` 三方相同；
四个 `measure` 产物的 SHA3-256 与 `.meta` 的 `executable_digest` 相同（算法同为 SHA3-256，
没有拿 SHA-256 去对照）；`binaries.sha256` 10 行全 OK。

原始数据：24 份 CSV 实测记录数 25000（动机复采 10000）、每类恰好 5000（2000）、`sample_index`
从 0 连续、`run_id`/`implementation` 单一、单位全为 `ns`，与「20 次预注册采集一次跑完、
样本量未缩减、无 `aborted-*`」一致，不存在看着数据缩样。

汇总表 13 列 26 行（含注释分隔行与四行 `prespecified=no`）我用自己的解析器从 24 对归档报告重新生成，
逐字节相同；`category_mean_range_ns` 取第一轮报告五条 `category=` 行的均值极差也对上。
README 的派生区间逐条复算一致：reference 第一轮族内最大 |z| 1.4753–2.4691、hardened 2.3403–3.9918、
deployable 0.6022–1.9655，vulnerable 第一轮主比较均值差 −11.4 … −81.4ns（4/5 显著）。
deployable/90210 那条读数陷阱（`mean_difference_ns=321.000` 配 `median_difference_ns=0.0`、
`rank_z=−0.1135`、`max` 402000–834000ns 的长尾）对作者不利，被主动写进两份文档。

### 测试覆盖与未覆盖

`analysis_groups` 覆盖三类手算场景（完全分离只断言 `rank_u1`/效应量/符号/判定，不写 z、p 的浮点字面量；
分布相同断言 `rank_u1=300.0`/`rank_z=0.0000`/`rank_p=1`/效应量 `0.500000` 这些精确值；全同值落
`degenerate_no_variation`）、类别乱序一例、十余个拒绝场景（缺类别、各类不等量、报告已存在、
参数个数错退出码 2、十种畸形 CSV、未以换行结束、文件不存在），外加四变体每类 50 的真实数据全流程。
期望值按秩和检验定义手算，没有用被测程序的输出当预期答案。

未覆盖/未归档：format-check 无归档件（issue 1）；第一轮重放的机器化用例只有 2 对（issue 4）；
乱序场景在当前实现下走等量校验而不是统计量断言（issue 3）；`unterminated.csv` 那一例没有跟一条
`test ! -e` 断言报告未被创建（其余拒绝场景都有）。归档 `ctest.log` 显示 `ctest -N` 18 项
（新增 `analysis_groups` #16、`analysis_round1_replay` #17）、18/18 通过，`sanitize-ctest.log`
（ASan+UBSan / Debug / Unix Makefiles）同样 18/18；按指示我没有重跑这三项检查。
`compile_commands.json` 里三个相关源文件逐条带
`-Wall -Wextra -Wpedantic -Wshadow -Wconversion -Wstrict-prototypes -Werror -std=c11`，
`build.log` 的 `warning` 扫描为空。

### 读写边界与硬约束

`268bab8` 只碰 `CMakeLists.txt`、`include/timing_statistics.h`、`src/analyze.c`、
`src/analyze_groups.c`、`src/timing_statistics.c`、两个 `tests/*.sh`；`4ce2133` 只碰新建的
`docs/evidence/statistics-multiseed/`、`.gitattributes`（追加两行 whitespace 豁免，对应 24 份
`.meta` 的 `link_flags=` 行尾空格与 `record-checks.txt:26`）、`docs/statistics.md`。
`vendor/`、`tests/vectors/`、既有证据目录、`CMakePresets.json`、根 `Makefile` 零命中。
`docs/statistics.md` 第 84 行原句未动，交叉引用句插在该段落之后、新章节追加在文件末尾；
插入后 `grep -n` 我实测仍为 84，与 README 记录的「插入前 84 / 插入后 84」一致，
交叉引用里的「第 8 节」与文件实际的第 8 个 `## ` 标题对得上。两个提交都在 `main`，
作者与提交者均为 `Gowin-liuyin <yinhaoran0808@outlook.com>`，未推送。

</details>

<details>
<summary>文件清单</summary>

提交 A `268bab8`（代码）：
- `src/timing_statistics.c`、`include/timing_statistics.h` — 新增：两程序共用的加载/校验/摘要/
  分位点/Welch/Mann-Whitney/判定标签，外加两个无状态排序入口
- `src/analyze_groups.c` — 新增：第二轮单比较族程序，`main` 六步固定、`_Static_assert` 钉住枚举顺序
- `src/analyze.c` — 只有两行新增（include 与 `qsort` 换成命名排序入口），比较族零改动
- `tests/test_analysis_groups.sh` — 新增：手算期望值的合成数据与拒绝场景、含类别乱序一例
- `tests/test_analysis_round1_replay.sh` — 新增：两份归档 CSV 的逐字重放
- `CMakeLists.txt` — 新增 `analyze_groups` 目标、两个 `add_test`、重放测试的 `WORKING_DIRECTORY`

提交 B `4ce2133`（证据/文档）：
- `docs/evidence/statistics-multiseed/`（106 个文件）— 24 份 CSV/`.meta`/两轮报告、
  `multiseed-summary.tsv`、`record-checks.txt`、三份构建日志 + `compile_commands.json`、
  `binaries.sha256`、`SHA256SUMS`、`README.md`
- `docs/statistics.md` — 追加第 8 节与一句交叉引用，旧内容 0 删除
- `.gitattributes` — 追加两条 whitespace 豁免

完整 diff：`git -C /Users/yin/code/cryProject show 268bab8`、
`git -C /Users/yin/code/cryProject show 4ce2133`

</details>
