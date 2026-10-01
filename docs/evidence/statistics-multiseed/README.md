# 多种子稳健性与第二轮预注册分组检验的实测证据

## 预注册凭证（模块零提交）与其强度边界

**模块零提交**：`adf9db9d2734837de11274343d3828d49d0f2444`
（`docs: pre-register the four-module design and its reviews`，diff 只含
`docs/tasks/four-module-design.md` 一个文件）。本目录的第二轮假设、统计形式、显著性水平、
种子清单与样本量全部由该提交固定在 `docs/tasks/four-module-design.md` 第 3.2 节，
本目录的全部采集都在该提交之后执行。

下面这段是设计文件篇首规定的定型文字，三处落点措辞必须一致，此处为其中一处（另两处为
`docs/acceptance.md` 追加章节与最终报告的「未闭合项」单列）：

> 第二轮假设在新种子采集开始之前已以文字形式固定并入库（提交
> `adf9db9d2734837de11274343d3828d49d0f2444`）。
> 本仓库是**本地仓库**：从未 push，`origin/main` 实测为 `gone`，没有任何第三方时间戳，
> 提交日期可由作者设置。因此这是**作者自证的顺序**，只支持「这份假设文本的入库早于
> 任何第二轮采集提交」这一本仓库历史内的相对关系，**不是可向第三方证明的预注册**。
> 更强的凭证需要公开推送或外部时间戳服务，属本阶段范围之外，按 0.5 记为未闭合项。

本机复核该两项实测（与上文一致）：

```
$ git branch -vv
* main 268bab8 [origin/main: gone] feat: add the round-two pre-registered group test as a separate tool
$ git rev-parse --verify origin/main
fatal: Needed a single revision
exit=128
```

`68ba0c3` 是模块零之前的**修订前草稿**提交，它在当时就自我声明不构成预注册凭证，
引用凭证时不要指向它。

## 功能源码提交与构建时工作区状态

**功能源码提交**：`268bab838d5cf8a4b0c9c8b6f5f8b144557de219`（模块三提交 A，
新增 `src/analyze_groups.c`、`src/timing_statistics.c`、`include/timing_statistics.h`、
两个测试脚本，并把 `src/analyze.c` 的共用部分抽出）。
与 `.meta` 的 `source_commit=` 实测一致。

**构建时工作区状态（逐字抄录 `.meta` 的 `git_worktree_status_*` 段）**：

```
git_worktree_status_begin
?? .agents/
?? docs/evidence/statistics-multiseed/
git_worktree_status_end
tracked_delta_sha256=e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
```

即**被跟踪文件无任何未提交改动**（`tracked_delta_sha256` 为空内容摘要），
工作区只有两个未跟踪目录：`.agents/`（代理会话草稿，不参与构建）与本证据目录自身
（采集时正在被写入）。这与 `docs/evidence/mitigation` 的「`git status --porcelain` 为空」
不完全相同，按实测如实记录，不声称完全干净；与 `docs/evidence/deployable` 同一口径。

## 平台与工具版本

- Apple M5 / ARM64 macOS（Darwin 25.6.0，产品版本 26.6.2，BuildVersion 25G83），
  `CLOCK_MONOTONIC` 分辨率 **1000ns**，**未固定 CPU 亲和性与频率**
  （`.meta`：`cpu_affinity=not_pinned`、`frequency_control=not_configured`）。
- 编译器 `Apple clang version 21.0.0 (clang-2100.3.34.2)`（`/usr/bin/cc`）。
- CMake 4.3.2、Ninja 1.13.0、OpenSSL 3.5.5、shasum 6.02。

## 本目录结论所覆盖的构建配置（逐字抄录 `.meta` 实测值）

```
build_system=CMake 4.3.2
generator=Ninja
configuration=RelWithDebInfo
compiler_flags= -O2 -g -DNDEBUG -std=c11
compile_options=-Wall -Wextra -Wpedantic -Wshadow -Wconversion -Wstrict-prototypes -Werror
compile_definitions=MLK_CONFIG_FILE="baseline_config.h"
sanitizers=OFF
```

配置、构建、测试命令（`configure.log`、`build.log`、`ctest.log` 的首行即为该命令）：

```sh
cmake -S . -B build/multiseed -G Ninja -DCMAKE_BUILD_TYPE=RelWithDebInfo \
    -DBUILD_TESTING=ON -DBASELINE_SANITIZERS=OFF
cmake --build build/multiseed --parallel
ctest --test-dir build/multiseed -N
ctest --test-dir build/multiseed --output-on-failure
```

`ctest -N` 实测 **18** 项，`ctest --output-on-failure` 实测 **18/18 通过**
（比模块一后的 16 项多出 `analysis_groups` 与 `analysis_round1_replay` 两项，与设计预期一致）。

**与 preset 的差异**：`baseline` preset 的生成器实测是 `Unix Makefiles`
（`CMakePresets.json:12`），而本目录用的是 `Ninja`。沿用 Ninja 是为了与归档的
`docs/evidence/mitigation`、`docs/evidence/deployable` 同配置可比。

`sanitize-ctest.log` 来自**另一个构建目录** `build/cmake-sanitize`（`sanitize` preset：
`Unix Makefiles` / `Debug` / ASan+UBSan），实测 18/18 通过、无任何 sanitizer 报告。
它**只用于功能正确性**，不用于任何产物形态、性能或统计结论。

## 采集参数

| 项 | 值 |
|---|---|
| 预注册种子（此前从未使用过，顺序固定） | `31337`、`90210`、`20261111`、`8675309`、`141421356` |
| 已用过因此排除的种子 | 42、777、20260926、20260930 |
| 变体 | reference、vulnerable、hardened、deployable |
| 预注册 `samples_per_category` | **5000**（每版 25000 条，`docs/statistics.md` 既有口径），在第一次预注册采集开始之前确定，20 次采集全部使用该值，无混用 |
| 预注册采集次数 | 4 × 5 = **20** |
| `RUN_ID` | `multiseed-<variant>-<seed>` |
| 动机复采（**非预注册**） | 种子 777、`samples_per_category=2000`（每份 10000 条）、`RUN_ID=motivation777-<variant>`、4 次 |

没有发生降级，也没有 `aborted-*` 文件：20 次预注册采集一次跑完，样本量未缩减。
目录体积 `du -sh` 实测 **33M**（全部逐次原始值按原文本归档，不压缩、不抽样、不删长尾）。

## 第二轮预注册的内容（摘自模块零提交，标注必读）

**这是第二轮预注册，是在看过第一轮数据之后提出的。** 不这样标注就是 p-hacking。

- 假设 H2：解密消息位**方向恒定类**（`message-zero`、`message-ones`）与**方向变化类**
  （`valid`、`bit-flipped`、`random`）之间，完整解封装耗时分布存在差异。
- 统计形式：两组各自的逐次原始值合并成两个样本（n1 = 2×5000 = 10000，n2 = 3×5000 = 15000），
  做并列修正、带连续性校正的 Mann-Whitney U 正态近似；判定**只**依据它。
  辅助报告 Welch t 与 Welch–Satterthwaite 自由度。分位点按最近秩取值、不插值、
  不删离群值、不裁尾（与第一轮完全相同的口径）。
- 显著性水平：`alpha_family=0.001`，本族只有 1 个预先规定的比较，
  因此 `comparison_count=1`、`multiplicity_correction=none_single_prespecified_comparison`、
  `alpha_per_comparison=0.001`。
- 评价单位：每个（变体, 种子）各自独立评价，不做跨运行池化检验。
- 预先写下的方向性期待：vulnerable 五个种子全部 `significant` 且
  `mean_difference_ns ≤ −300`、`effect_size_first_greater ≤ 0.40`；
  reference / hardened / deployable 五个种子全部 `not_significant` 且
  `|mean_difference_ns| ≤ 150`。

### 两轮的显著性阈值不是同一严格度，必须并列读

| 轮次 | 比较族大小 | 校正 | `alpha_per_comparison` |
|---|---|---|---|
| 第一轮（`analyze`，`message-zero:message-ones` 为 `primary=yes`） | 10 | Bonferroni | **1e-4** |
| 第二轮（`analyze_groups`，`direction-constant:direction-varying`） | 1 | 无（单一预先规定比较） | **1e-3** |

第二轮阈值比第一轮主比较阈值**宽 10 倍**。因此「第一轮主比较在 1e-4 下未稳定成立」与
「第二轮在 1e-3 下成立」**不是同一严格度的陈述**，后者**不是**对前者同一假设的更强证实
（两者的假设本身也不同）。汇总表因此同时给出 `round2_rank_p`（按 1e-3 判定的 `round2_result`）
与 `round2_significant_at_1e-4` 两列；后者是设计文件 3.2 **预先写下**的附带读数。
每份 `.groups.report` 里还有常量字段
`round1_alpha_per_comparison_for_reference=0.00010000`，把第一轮阈值并列写在同一份报告里。

## 实现上的隔离与第一轮不被动过的机器化证明

第二轮用**独立程序** `analyze_groups`（`src/analyze_groups.c`）实现，
`src/analyze.c` 的比较族定义**一个字符都没有改**（本次 `src/analyze.c` 的 diff 只有两行新增：
`#include "timing_statistics.h"` 与把那行 `qsort` 换成
`sort_records_by_category_then_duration(...)`，排序语义与调用时点不变）。

CTest 的 `analysis_round1_replay` 在仓库根目录对已归档的
`docs/evidence/statistics/vulnerable.csv` 与 `docs/evidence/mitigation/hardened.csv`
重放 `analyze`，与归档 `.report` 比较。**本机实测：抽取共用部分之后，`build/cmake/analyze`
对全部 7 份归档 CSV 的重放报告与归档报告在屏蔽 `welch_p=`/`rank_p=` 之前就已逐字节相同**
（`statistics/{reference,reference-replication,vulnerable,vulnerable-replication}`、
`mitigation/{reference,vulnerable,hardened}`）。脚本仍屏蔽这两个字段，只是为跨 libm 平台留余量。

CTest 的 `analysis_groups` 用解析上可手算的合成数据检查第二轮实现，预期值不由被测程序产生：
两组完全分离（`rank_u1=0.0`、效应量 `0.000000`、`rank_z` 为负、判显著）、
两组分布完全相同（`rank_u1=300.0` 恰为 n1·n2/2、`rank_z=0.0000`、`rank_p=1`、
效应量 `0.500000`、判不显著）、全部取值相同（`degenerate_no_variation`）、
以及**类别乱序输入**场景。

**分组不变式的实测捕获**：`analyze_groups` 的 `main` 固定六步，第 2 步必须对**整份**
`set.records` 调用 `sort_records_by_category_then_duration`，否则按下标切出的两段与类别无关。
本机做过去掉第 2 步的实测探针：重新编译后 `ctest -R analysis_groups` 失败，
单独对类别交替写出的合成 CSV 运行该探针二进制也失败（退出码 1、不创建报告，
stderr 为 `invalid timing CSV: all five categories must appear with equal sample counts`）。
**与设计 3.4 的预期有一点差别，按实测记录**：设计预计这一条会表现为
`rank_u1` 不是 0、效应量不是 0.000000；本实现的第 3 步（五类齐全且每类等量）在任何统计量
被算出之前就先失败了，所以捕获点更早、失败信息不同，但捕获结论一致——漏掉整份排序必然失败。
探针改动已还原，仓库里不留该改动。

CMake 注册的实际写法由 `.cmake-format.json`（cmakelang 0.6.13）归一化，
与设计 3.3 给出的代码片段在换行上不同、语义完全相同（同名测试、同一命令与参数、
`analysis_round1_replay` 的 `WORKING_DIRECTORY` 指向源码根目录）。

## 汇总表（M3-5）

完整表见 `multiseed-summary.tsv`（制表符分隔，列序与表头写死在设计 3.5/M3-5 中）。
`round1_significant_count` 的分母恒为 **10**（源码事实：`ANALYSIS_COMPARISON_COUNT`）；
`round1_alpha_per_comparison` 是常量列，恒为 `0.00010000`，只为提醒严格度；
`round2_result` 按 `alpha_per_comparison=1e-3` 判定；
`round2_significant_at_1e-4` 取值域 `yes|no|na`。
最后四行 `prespecified=no` 是种子 777 的动机复采，排在预注册 20 行之后、用注释行分隔，
**不参与**「五个种子全部如何」的任何计数。

| implementation | seed | presp. | r1 sig | r1 primary p | r1 alpha | r2 result | r2 rank_p | r2 @1e-4 | mean diff ns | effect | rank_z | cat mean range ns |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| reference | 31337 | yes | 0 | 0.151354 | 0.00010000 | not_significant | 0.632214 | no | 7.867 | 0.501274 | 0.4786 | 23.600 |
| vulnerable | 31337 | yes | 6 | 0.0214594 | 0.00010000 | significant | 0 | yes | −775.533 | 0.172429 | −98.6457 | 800.200 |
| hardened | 31337 | yes | 0 | 0.177848 | 0.00010000 | not_significant | 0.00267499 | no | −12.967 | 0.491814 | −3.0028 | 29.400 |
| deployable | 31337 | yes | 0 | 0.677125 | 0.00010000 | not_significant | 0.59014 | no | −3.000 | 0.498800 | −0.5386 | 16.400 |
| reference | 90210 | yes | 0 | 0.335984 | 0.00010000 | not_significant | 0.250177 | no | 19.567 | 0.502727 | 1.1499 | 33.200 |
| vulnerable | 90210 | yes | 7 | 2.69391e-05 | 0.00010000 | significant | 0 | yes | −663.233 | 0.248095 | −73.2206 | 728.600 |
| hardened | 90210 | yes | 0 | 0.965928 | 0.00010000 | not_significant | 0.00423424 | no | −17.300 | 0.492338 | −2.8602 | 37.000 |
| deployable | 90210 | yes | 0 | 0.909618 | 0.00010000 | not_significant | 0.0371592 | no | 52.300 | 0.494589 | −2.0840 | 427.200 |
| reference | 20261111 | yes | 0 | 0.0806086 | 0.00010000 | not_significant | 0.503897 | no | −1.000 | 0.498518 | −0.6684 | 47.600 |
| vulnerable | 20261111 | yes | 7 | 1.45399e-05 | 0.00010000 | significant | 0 | yes | −771.600 | 0.165089 | −102.0230 | 796.200 |
| hardened | 20261111 | yes | 0 | 0.510893 | 0.00010000 | not_significant | 0.00100445 | no | −13.100 | 0.491338 | −3.2893 | 44.800 |
| deployable | 20261111 | yes | 0 | 0.413672 | 0.00010000 | not_significant | 0.484306 | no | −5.233 | 0.501561 | 0.6994 | 17.400 |
| reference | 8675309 | yes | 0 | 0.0344369 | 0.00010000 | not_significant | 0.669278 | no | 3.000 | 0.500930 | 0.4271 | 29.600 |
| vulnerable | 8675309 | yes | 7 | 2.59526e-05 | 0.00010000 | significant | 0 | yes | −758.533 | 0.155744 | −104.9045 | 775.800 |
| hardened | 8675309 | yes | 0 | 0.841793 | 0.00010000 | not_significant | 0.00397703 | no | −16.600 | 0.492709 | −2.8800 | 27.000 |
| deployable | 8675309 | yes | 0 | 0.0756106 | 0.00010000 | not_significant | 0.75803 | no | −13.833 | 0.499336 | −0.3081 | 47.600 |
| reference | 141421356 | yes | 0 | 0.173681 | 0.00010000 | not_significant | 0.252271 | no | −7.967 | 0.497489 | −1.1449 | 30.400 |
| vulnerable | 141421356 | yes | 7 | 2.55524e-13 | 0.00010000 | significant | 0 | yes | −743.967 | 0.164978 | −102.2400 | 795.400 |
| **hardened** | **141421356** | **yes** | **1** | **0.116097** | **0.00010000** | **significant** | **1.42602e-05** | **yes** | **−30.067** | **0.488950** | **−4.3398** | **51.000** |
| deployable | 141421356 | yes | 0 | 0.693612 | 0.00010000 | not_significant | 0.908294 | no | 2.733 | 0.500244 | 0.1152 | 9.200 |
| *reference* | *777* | *no* | 0 | 0.397325 | 0.00010000 | not_significant | 0.101969 | no | 14.833 | 0.507282 | 1.6354 | 46.000 |
| *vulnerable* | *777* | *no* | 6 | 0.000845961 | 0.00010000 | significant | 0 | yes | −717.833 | 0.180577 | −61.1727 | 737.500 |
| *hardened* | *777* | *no* | 0 | 0.765653 | 0.00010000 | not_significant | 0.141259 | no | 0.083 | 0.494173 | −1.4711 | 52.000 |
| *deployable* | *777* | *no* | 0 | 0.367708 | 0.00010000 | not_significant | 0.539217 | no | −11.667 | 0.497541 | −0.6140 | 43.000 |

`rank_p=0`（vulnerable 全部五个种子）是 `erfc` 在 `|z|` 很大时的**下溢**，不是精确零；
该行应以 `rank_z` 为准（−73.2 至 −104.9）。这一数值边界是 `docs/statistics.md`
已记录的已知边界，不是本次新发现。

### 汇总表与「若按 1e-4 判定」列的生成命令

`multiseed-summary.tsv` 全部列都从已归档的 `.report` / `.groups.report` 里
`grep`/`awk` 出来，**不重算任何统计量**。取字段的三个辅助函数：

```sh
whole_line_field() {
    awk -v name="$2" 'index($0, name "=") == 1 { print substr($0, length(name) + 2); exit }' "$1"
}

comparison_field() {
    awk -v name="$3" -v prefix="$2" '
        index($0, prefix) == 1 {
            for (field_index = 1; field_index <= NF; ++field_index) {
                if (index($field_index, name "=") == 1) {
                    print substr($field_index, length(name) + 2);
                    exit;
                }
            }
        }' "$1"
}

category_mean_range() {
    awk '/^category=/ {
            for (field_index = 1; field_index <= NF; ++field_index) {
                if ($field_index ~ /^mean=/) {
                    mean_value = substr($field_index, 6) + 0;
                    if (seen == 0 || mean_value < minimum) { minimum = mean_value; }
                    if (seen == 0 || mean_value > maximum) { maximum = mean_value; }
                    seen = 1;
                }
            }
         }
         END { printf "%.3f\n", maximum - minimum; }' "$1"
}
```

`round2_significant_at_1e-4` 列的生成命令（设计 3.5/M3-5 写死，**只改判定阈值，
不重算任何统计量**；`rank_p=` 缺失时写 `na`，不得当成 `no` 混进计数）：

```sh
awk '/^comparison=/ {
        p = "";
        for (field_index = 1; field_index <= NF; ++field_index) {
            if ($field_index ~ /^rank_p=/) { p = substr($field_index, 8); }
        }
        if (p == "") { print "significant_at_1e-4=na"; }
        else { print "significant_at_1e-4=" (p + 0 < 1e-4 ? "yes" : "no"); }
     }' <report>
```

逐份输出（24 份 `.groups.report`，全部有 `rank_p=`，因此没有 `na`）：

```text
deployable-seed141421356.groups.report           significant_at_1e-4=no
deployable-seed20261111.groups.report            significant_at_1e-4=no
deployable-seed31337.groups.report               significant_at_1e-4=no
deployable-seed8675309.groups.report             significant_at_1e-4=no
deployable-seed90210.groups.report               significant_at_1e-4=no
hardened-seed141421356.groups.report             significant_at_1e-4=yes
hardened-seed20261111.groups.report              significant_at_1e-4=no
hardened-seed31337.groups.report                 significant_at_1e-4=no
hardened-seed8675309.groups.report               significant_at_1e-4=no
hardened-seed90210.groups.report                 significant_at_1e-4=no
motivation-seed777-deployable.groups.report      significant_at_1e-4=no
motivation-seed777-hardened.groups.report        significant_at_1e-4=no
motivation-seed777-reference.groups.report       significant_at_1e-4=no
motivation-seed777-vulnerable.groups.report      significant_at_1e-4=yes
reference-seed141421356.groups.report            significant_at_1e-4=no
reference-seed20261111.groups.report             significant_at_1e-4=no
reference-seed31337.groups.report                significant_at_1e-4=no
reference-seed8675309.groups.report              significant_at_1e-4=no
reference-seed90210.groups.report                significant_at_1e-4=no
vulnerable-seed141421356.groups.report           significant_at_1e-4=yes
vulnerable-seed20261111.groups.report            significant_at_1e-4=yes
vulnerable-seed31337.groups.report               significant_at_1e-4=yes
vulnerable-seed8675309.groups.report             significant_at_1e-4=yes
vulnerable-seed90210.groups.report               significant_at_1e-4=yes
```

## 结论（按预注册逐条对账，偏离照实写）

**vulnerable：预先写下的期待全部成立。** 五个新种子全部 `significant`；
`mean_difference_ns` 在 **−663.2 至 −775.5ns**（全部 ≤ −300）；
`effect_size_first_greater` 在 **0.155744 至 0.248095**（全部 ≤ 0.40）；
`rank_z` 在 **−73.22 至 −104.90**。方向全部为负，即方向恒定类更快。
这与归档两次采集的主效应量级（711–800ns / 690–824ns）同量级，是可重复的。

**reference：期待成立。** 五个种子全部 `not_significant`，
`|mean_difference_ns| ≤ 19.567ns`（≤ 150），第一轮同样 **5/5 都是 0/10**，
第一轮族内最大 `|z|` 为 1.4753–2.4691。

**deployable：期待成立。** 五个种子全部 `not_significant`，
`mean_difference_ns` 在 **−13.833 至 +52.300ns**（`|·| ≤ 150`），
第一轮 **5/5 都是 0/10**，第一轮族内最大 `|z|` 为 0.6022–1.9655。

**hardened：预先写下的期待未成立（偏离，照实记录，不丢种子、不改阈值、不换种子重来）。**
`mean_difference_ns` 在 **−30.067 至 −12.967ns**，量级上确实满足 `|·| ≤ 150`，
**但显著性判定不是五个种子全部 `not_significant`**：种子 `141421356` 判
`significant`（`rank_p=1.42602e-05`、`rank_z=−4.3398`、`effect_size=0.488950`），
按 1e-4 判定同样是 `yes`。另外四个种子的 `rank_p` 为 **0.00100445 至 0.00423424**，
全部落在 1e-3 阈值的同一个数量级附近——即 hardened 的残差不是随机摆动，
而是**五个种子方向一致为负、量级稳定在十几到三十纳秒的小残差**，
其中一个种子越过了第二轮阈值。第一轮族在该种子上也给出 **1/10**
（`bit-flipped:message-zero`，`mean_difference_ns=51.000`、`rank_z=3.9918`、
`rank_p=6.55699e-05`），其余四个种子为 0/10。

**因此「reference / hardened / 新变体在第一轮族上 0/10」这一稳定性说法，
按本次多种子实测必须分开表述**：reference 与 deployable 在五个新种子上 5/5 都是 0/10；
hardened 是 **4/5 为 0/10，1/5 为 1/10**，在第二轮分组统计量下是 **4/5 不显著、1/5 显著**。
`docs/mitigation.md` 里「防护版残差随运行波动」的稳定性问题（M3-6）据此回答：

| 变体 | 第一轮族内最大 `\|z\|`（五个新种子） | 第一轮显著数 | 第二轮 `\|rank_z\|` | 第二轮 `mean_difference_ns` | 第二轮判定 |
|---|---|---|---|---|---|
| hardened | 2.3403 – 3.9918 | 0/10 ×4、1/10 ×1 | 2.8602 – 4.3398 | −30.067 – −12.967 | not_significant ×4、significant ×1 |
| deployable | 0.6022 – 1.9655 | 0/10 ×5 | 0.1152 – 2.0840 | −13.833 – +52.300 | not_significant ×5 |

即两个防护变体都把 700ns 量级的主效应消掉了（对比 vulnerable 的 −663 至 −776ns），
但**hardened 留下了一个方向一致的小残差，deployable 在这五个种子上没有**。
这是统计观察，不是恒时证明；本实验没有给出 hardened 残差的机制归因。

**一个必须注意的读数陷阱（照实记录）**：deployable / 种子 `90210` 的第一轮主比较
`mean_difference_ns=321.000`，看上去很大，但该行 `median_difference_ns=0.0`、
`rank_z=−0.1135`、`rank_p=0.909618`、判 `not_significant`，同一报告的
`category_mean_range_ns=427.200`。原因是该次采集保留了普通长尾
（`category=` 行实测 `max` 为 402000–834000ns，而 `median` 全为 14000ns），
**均值对长尾不稳健**——这正是预注册把秩检验而不是均值定为判定统计量的原因。
长尾按硬要求全部保留，没有删除、裁尾或平滑。

## 种子 777：原口头复核与动机复采并列，互不替代

上层协调者当初用种子 777、每版 10000 条（`samples_per_category=2000`）复核第一轮主比较，
三个变体的 p 值为 **0.923（reference）/ 0.844（vulnerable）/ 0.516（hardened）**。
**这三个数字来自未归档、无法从本仓库复现的口头复核**：全工作树搜索 `test_seed=777`
零命中，`runs/` 只有 `test_seed=42` 的材料且被 `.gitignore` 排除。
它们**只作为提出第二轮假设的动机记录**，不作为证据引用，不进汇总表的证据列。

本目录另外重跑了一次同参数的种子 777 动机复采（四个变体，
`samples_per_category=2000`，`RUN_ID=motivation777-<variant>`），作为**可复现的替代材料**。
它**不属于**第二轮预注册的稳健性集合（777 在排除清单里），
在汇总表中标注 `prespecified=no` 并排在预注册 20 行之后，不参与任何计数。
重采的第一轮主比较实测值（与上面三个原值**分别标注、并列呈现，不互相替换**）：

| 变体 | 原口头复核 `rank_p`（未归档） | 本次动机复采 `rank_p` | 本次 `mean_difference_ns` | 本次判定（1e-4） |
|---|---|---|---|---|
| reference | 0.923 | 0.397325 | −10.000 | not_significant |
| vulnerable | 0.844 | 0.000845961 | −30.000 | not_significant |
| hardened | 0.516 | 0.765653 | 25.500 | not_significant |
| deployable | （原复核未覆盖） | 0.367708 | −19.000 | not_significant |

**判定层面一致**（两边四个/三个变体的第一轮主比较都不显著），
**数值层面不同**（不同时间、不同机器负载）。不得用重采值替换原值假装原值已被证实。
动机复采结果与原口头复核**没有相反**，但即使相反也不会改变第二轮预注册的内容——
预注册已在模块零提交固定，不因动机材料变动而调整。

## M3-10：正面更正两处既有措辞

两处旧措辞逐字引用如下（以原句文本为主、行号为辅）：

1. `docs/evidence/mitigation/README.md:47`：
   「…略高于 1e-4 阈值因此判不显著；该项在不同采集之间反复越过阈值，属于小幅不稳定的次级差异。」
   该文件在只读封存范围内（0.3），**不回去编辑**；它的更正只在
   `docs/statistics.md` 的新章节里给出，并在那里写明「旧文件因只读约定原样保留，以该章节为准」。
2. `docs/statistics.md`「机制解释与其边界」一节内：
   「…而不是两条分支本身代价不同；主比较只呈现次级差异，也符合这一解释。」
   该文件不在 0.3 的只读范围内，依据的是本仓库「不改写既有结论、只追加」的工程约定。
   处置：该句**原文保持不动**，紧随该段落之后**新增**一句交叉引用（这是追加，不是改写），
   并在文末追加新章节。

行号的机械核对（设计 3.4/M3-10 要求把两次输出逐字写入本文件）：

```sh
$ grep -n '主比较只呈现次级差异' docs/statistics.md   # 插入前
84:而不是两条分支本身代价不同；主比较只呈现次级差异，也符合这一解释。

$ grep -n '主比较只呈现次级差异' docs/statistics.md   # 插入后
84:而不是两条分支本身代价不同；主比较只呈现次级差异，也符合这一解释。
```

**插入前 84 / 插入后 84**，行号未变（交叉引用句插在该段落之后、新章节追加在文件末尾）。
`docs/tasks/four-module-design.md` 自模块零提交起冻结，其中引用的 `:84` 是模块零时点的
实测值，本次实测仍为 84，不需要也不允许回头修改该设计文件。

## 本目录文件

| 文件 | 内容 |
|---|---|
| `README.md` | 本文件 |
| `configure.log`、`build.log`、`ctest.log`、`compile_commands.json` | `build/multiseed`（Ninja / RelWithDebInfo）的逐字记录，含配置命令与 `ctest -N` |
| `sanitize-ctest.log` | 来自 `build/cmake-sanitize`（`sanitize` preset），仅用于功能正确性 |
| `{variant}-seed{SEED}.csv` | 20 份原始逐次数据，各 25000 条 |
| `{variant}-seed{SEED}.meta` | 20 份运行元数据（时钟、单位、分辨率、产物摘要、工作区状态） |
| `{variant}-seed{SEED}.report` | 第一轮固定族报告（10 个比较） |
| `{variant}-seed{SEED}.groups.report` | 第二轮单比较族报告 |
| `motivation-seed777-{variant}.{csv,meta,report,groups.report}` | 4 组种子 777 动机复采，每份 10000 条，`prespecified=no` |
| `multiseed-summary.tsv` | M3-5 汇总表 |
| `record-checks.txt` | 类别顺序比较、全部 SHA3-256、自报字段对照、原始值保留核对 |
| `binaries.sha256`、`SHA256SUMS` | 产物与全目录摘要（`SHA256SUMS` 不含自身） |

核对命令（在仓库根目录）：

```sh
shasum -a 256 -c docs/evidence/statistics-multiseed/SHA256SUMS
openssl dgst -sha3-256 docs/evidence/statistics-multiseed/vulnerable-seed31337.csv
grep '^csv_digest=' docs/evidence/statistics-multiseed/vulnerable-seed31337.groups.report
```

## 结论边界（支持什么／不支持什么）

**支持**：

- 第二轮预注册的分组假设在五个全新公开种子上，对 vulnerable **5/5 成立**，
  效应量级与归档采集同量级，是可重复的。
- reference 与 deployable 在这五个种子上 **5/5 不显著**（两轮都是）。
- 第一轮预注册的主比较 `message-zero:message-ones` 在五个新种子上**仍未稳定成立**：
  vulnerable 为 4/5 显著（种子 31337 的 `rank_p=0.0214594`，不显著），
  均值差 −11.4 至 −81.4ns，仍只有第二轮主效应的约十分之一量级。
- 把差异归到「消息位方向恒定 vs 方向变化」比归到「全 0 vs 全 1 两条分支」更稳定。

**不支持**：

- 不支持「参考版、hardened 或 deployable 是恒时实现」。多种子重现 ≠ 恒时证明。
- 不支持任何密钥恢复、未知密钥攻击或单条密文判定的结论。
- 方向恒定组在固定密钥下只有**两个不同密文**反复测量，不能当作独立随机密文总体的样本；
  第二轮是机制审计统计量，不是攻击成功率。该限制同时写在每份 `.groups.report` 的
  `sample_independence_note=` 字段里。
- 不支持把「第二轮在 1e-3 下成立」读成对第一轮同一假设的更强证实：假设不同、阈值宽 10 倍。
- 不支持跨平台外推：结论限于 Apple M5 / ARM64 macOS、1000ns 量化时钟、
  未固定 CPU 亲和性与频率、Ninja / RelWithDebInfo 这一配置。
  真实 x86_64 Linux 主机的同组采集仍未执行。
- 不支持 hardened 残差的机制解释：本次只观察到它存在且方向一致，没有做机制分离实验。
