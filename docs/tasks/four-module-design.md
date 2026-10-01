# 四模块设计与验收标准

> ## 当前状态（入库时如实记录）
>
> - **设计评审发现已逐条解决，本文件为定稿。** 第三轮设计评审判定 `CHANGES_REQUESTED`
>   （1 HIGH、9 MEDIUM、7 NIT，10 项阻断），17 项的处置逐条记在第 9 节。
>   HIGH 项（本文件 3.3 节把「按类别排序」的归属写错）已按实测改正：排序发生在
>   `src/analyze.c:647` 的 `main`，`load_measurement_set` 本身不排序；
>   对应的执行顺序、抽取入口与 M3-1 的捕获场景都已改写。
> - **提交本文件的这个提交就是 0.1 的模块零提交，也是设计定稿提交。**
>   按 0.1 的新增硬约束，此提交之后本文件不再修改。
>   注意上一个提交 `68ba0c3` 已经把本文件的**修订前草稿**入库过一次——那次提交当时就自我声明
>   「不构成模块零预注册凭证」（草稿仍带全部阻断发现）。**预注册文本指的是模块零提交里的这一版**，
>   引用凭证时给出模块零提交的哈希，不要指向 `68ba0c3`。
> - **实现阶段尚未开始执行。** 仓库代码、构建配置、测试和既有证据在本提交中均未改动；
>   本次修订只动 `docs/tasks/` 下的文件。下一步是模块一。
> - **预注册凭证只有本地顺序效力，没有第三方时间戳。** 本仓库从未 push
>   （`origin/main` 实测为 `gone`），本地提交日期可由作者设置。因此模块零提交只支持
>   「第二轮假设在新种子采集开始之前已以文字形式固定并入库」这一**作者自证的顺序**，
>   **不是**可向第三方证明的预注册。完整口径见篇首「预注册的性质与其边界」与 3.6。
> - **第一、二轮评审文件已被覆盖、无法逐字复核。** 三轮评审曾写在同一路径上，
>   第一、二轮内容已不存在，本文件第 7、8 节对前两轮评审文件的引用因此只能以该两节的
>   逐条摘要为准。第四轮起的评审产物改用互不覆盖的文件名，规则见 0.1。
> - **下一步入口**：按「模块零（本提交）→ 模块一 → 二 → 三 → 四」串行执行，不跳步。

本文件是后续四个模块的**设计与验收契约**，在动手前固定下来：目标、可执行验收标准、
需要归档的证据、诚实性边界，以及本机做不到时如何如实记录缺口。
本文件不写实现代码；模块三的第二轮统计假设与公开种子在此**先于采集**固定下来，
由 0.1 的**模块零提交**把这份文字入库。

执行顺序固定为**模块零（预注册入库）→ 模块一 → 二 → 三 → 四**，串行，不并行，不跳步。

**预注册生效条件**：本文件（含设计评审后的最终版）必须在**任何取证开始之前**、由一个
**独立的模块零提交**入库到 `main`；否则第二轮假设就不再是「采集前已写定」的。
模块零的命令与核对见 0.1。
模块零提交号无法写进被它提交的本文件（自指），因此落点固定为：模块零提交后立即执行
`git log -1 --format=%H` 并把该哈希逐字记入模块一至模块四**每个**证据目录的 `README.md`
开头，模块三的 `README.md` 另需写出下面这段诚实声明的全文，
`docs/acceptance.md` 的追加章节（M4-5）同样引用该哈希并写出同一段声明。

**预注册的性质与其边界（定型文字，三处必须逐字一致）**：

> 第二轮假设在新种子采集开始之前已以文字形式固定并入库（提交 `<模块零提交哈希>`）。
> 本仓库是**本地仓库**：从未 push，`origin/main` 实测为 `gone`，没有任何第三方时间戳，
> 提交日期可由作者设置。因此这是**作者自证的顺序**，只支持「这份假设文本的入库早于
> 任何第二轮采集提交」这一本仓库历史内的相对关系，**不是可向第三方证明的预注册**。
> 更强的凭证需要公开推送或外部时间戳服务，属本阶段范围之外，按 0.5 记为未闭合项。

**措辞禁令**：本文件、证据 `README.md`、`docs/statistics.md` 新章节、
`docs/acceptance.md` 追加章节与最终报告中，**不得**出现「可信时间凭证」
「时间戳证明」「可验证的预注册」一类措辞；需要指代该提交时写「模块零提交」
或「作者自证的顺序凭证」。上面那段定型文字的三处落点为：模块三证据 `README.md`、
`docs/acceptance.md` 追加章节、最终报告的「未闭合项」单列。

## 0. 全局约束

### 0.1 Git 规程

- 直接在 `main` 开发。不新建分支、不建 worktree、不 push、不 force reset、不改写历史。
- 提交前核对本仓库局部配置：`git config user.name` 应为 `Gowin-liuyin`、
  `git config user.email` 应为 `yinhaoran0808@outlook.com`（本轮已用
  `git config --local user.name` / `--local user.email` 复核，两项确实写在**本仓库局部配置**里，
  不需改动，也不要动全局配置）。
- 每个模块按「实现 → 必要检查 → 检查 diff → commit」推进，只暂存本模块文件，
  修复用新提交，不用 `--amend`。
- 每次提交后执行并保留输出：

```sh
git rev-parse --abbrev-ref HEAD
git log -1 --format='%h %an <%ae> %cn <%ce>'
git status --porcelain
```

- **每个模块拆成两个提交**，原因是证据必须绑定干净工作区：
  先提交功能/配置改动（提交 A），再从干净树采集证据，最后提交证据与文档（提交 B）。
  既有证据目录都记录 `git status --porcelain` 为空、`tracked_delta_sha256`
  为空内容摘要 `e3b0c442…7852b855`，本次必须保持同一口径。
  模块二没有代码改动，只有一个文档/证据提交。
- **模块零（预注册入库，必须是本次第一个提交）**：`tools/build_identity.sh` 把
  `git status --porcelain` 的输出逐字写进 `build_identity.h`，再由 `measure` 写进每份 `.meta`
  的 `git_worktree_status_*` 段。所以只要 `docs/tasks/` 下还有未提交的改动，
  此时采集的任何 `.meta` 都会记录脏工作区，与既有证据「状态为空」的口径不一致。
  **本轮实测的起点状态**：`docs/tasks/` 的三个文件**已被跟踪**——它们在上一个提交
  `68ba0c3`（`docs: record the four-module design and its unresolved review findings`）里入库，
  那次提交记录的是**修订前、仍带全部阻断发现的草稿**，并在当时的「当前状态」段里
  明确声明**它不是模块零提交、不构成预注册**。本次定稿修订后，
  `git status --porcelain` 实测输出 ` M docs/tasks/four-module-design.md`（不是 `?? docs/tasks/`）。
  因此先执行：

```sh
git add docs/tasks/
git commit -m "docs: pre-register the four-module design and its reviews"
git rev-parse --abbrev-ref HEAD
git log -1 --format='%H %h %an <%ae> %cn <%ce>'
git status --porcelain   # 必须为空
```

  用 `git add docs/tasks/`（而不是逐个列文件）是因为 `docs/tasks/` 整体就是模块零的暂存范围，
  不会带进别的模块的文件；提交前用 `git status --porcelain` 与
  `git diff --cached --name-only` 核对实际暂存清单并保留输出。
  **模块零提交的实际 diff 只含一个文件**：`docs/tasks/four-module-design.md`（本次定稿修订）。
  `docs/tasks/design-review.md` 与 `docs/tasks/design-review.json`（第三轮评审的产物）
  本次**不变**，它们已随 `68ba0c3` 入库、内容即第三轮评审原文。
  第一、二轮评审产物**不在仓库里**——三轮评审曾写在同一路径上，前两轮已被覆盖、不可恢复，
  它们只以第 7、8 节的逐条摘要形式留存，这一限制必须照第 7、8 节首段的措辞对外写明。
  **「预注册文本」指的是模块零提交里的这一版，不是 `68ba0c3` 里的草稿**：两者内容不同，
  引用凭证时必须给出模块零提交的哈希，并说明 `68ba0c3` 是自我声明不作凭证的修订前草稿。

- **评审产物的命名规则（第四轮起生效，互不覆盖）**：`docs/tasks/design-review.{md,json}`
  自模块零提交起**冻结**为第三轮设计评审的内容，**不得再被任何一轮覆盖**。
  模块零之后的每一轮评审产物改用模块与轮次都写进文件名的路径，形如
  `docs/tasks/review-m<模块号>-r<轮次>.md` 与 `docs/tasks/review-m<模块号>-r<轮次>.json`
  （例如模块一第一轮评审为 `docs/tasks/review-m1-r1.md` / `.json`），
  同一路径只写一次。引用评审结论时一律给出该轮的具体文件名，不写「评审文档」这种会漂移的指代。

- **硬约束（证据与脏工作区）**：`docs/tasks/` 下任一文件处于未跟踪或已修改状态时，
  **不得采集任何计时数据、不得产出任何反汇编证据**。

- **硬约束（模块零之后冻结本设计文件）**：模块零提交之后，
  `docs/tasks/four-module-design.md` **不再修改**——含行号引用、措辞与笔误。
  需要更新的事实只写进对应证据目录的 `README.md` 与 `docs/statistics.md` /
  `docs/acceptance.md` 的**新增章节**，并在那里注明「本设计文件保持模块零提交时的原文」。
  这条的用途是把「模块零提交号 ↔ 预注册文本」绑死：凭证指向的是**模块零那次提交里的文本**，
  此后文件内容不再变动，读者不必判断凭证指的是哪一版。
  **若确实必须修订本文件**：作为一个**新的独立提交**（不 `--amend`、不改写历史），
  并在后续每个证据目录的 `README.md`、`docs/acceptance.md` 追加章节与最终报告里
  **并列写出两个哈希**——「预注册凭证提交（模块零）」与「修订提交」——
  同时写明该修订**是否触及 3.2 的第二轮假设内容**（假设、统计形式、阈值、种子清单、样本量）；
  **触及则该轮预注册作废、必须换一组从未使用过的种子重做**，不得沿用已采集的数据。
- 提交信息沿用现有历史风格：英文小写前缀 `feat:` / `test:` / `docs:` / `fix:` / `style:`，
  主题行不超过 72 字符。

### 0.2 构建与检查口径

- CMake/CTest 是唯一构建与测试配置来源；根 `Makefile` 只做转发，不加第二套规则。
- 必要检查命令（**每个含代码或配置改动的模块**，在其提交 A 之前跑完；
  模块二没有提交 A，其检查以 M2-4 / M2-4a / M2-5 的容器内结果为准；
  模块四本身就是检查模块，其检查以 M4-1 / M4-3 / M4-7 为准）：

```sh
cmake --preset baseline && cmake --build --preset baseline --parallel && ctest --preset baseline
cmake --build --preset baseline --target format-check
cmake --preset sanitize && cmake --build --preset sanitize --parallel && ctest --preset sanitize
```

- 正式采集与反汇编用独立构建目录（沿用既有做法，如 `build/mitigation`、`build/completion`），
  不与 `build/cmake` 或 sanitizer 目录混用；动态检查产物不得进入正式证据。
  本次的构建目录、**配置命令**与 `RUN_ID` 一并写死（`RUN_ID` 均满足实测约束
  `[A-Za-z0-9_-]`、长度 ≤ 64）。三个宿主采集目录都**不是 preset**
  （`CMakePresets.json` 的 `baseline` / `sanitize` 的 `binaryDir` 固定为 `build/cmake` 与
  `build/cmake-sanitize`），所以配置命令必须显式给出，不能只写目录名：

| 模块 | 采集构建目录 | 配置命令（逐字） | `RUN_ID` |
|---|---|---|---|
| 模块一 | `build/deployable` | `cmake -S . -B build/deployable -G Ninja -DCMAKE_BUILD_TYPE=RelWithDebInfo -DBUILD_TESTING=ON -DBASELINE_SANITIZERS=OFF` | `deployable-<variant>` |
| 模块二 | 容器内 `/build/cmake`，其中 `/build` = 宿主 `/tmp/linux-amd64-build`（仓库工作区之外，见 2.2） | `cmake -S /workspace -B /build/cmake -DCMAKE_C_COMPILER=gcc -DCMAKE_BUILD_TYPE=RelWithDebInfo -DBUILD_TESTING=ON -DBASELINE_SANITIZERS=OFF`（容器内默认生成器 Unix Makefiles，照 `docs/evidence/linux-gcc` 先例不指定 `-G`） | `smoke-<variant>` |
| 模块三 | `build/multiseed` | `cmake -S . -B build/multiseed -G Ninja -DCMAKE_BUILD_TYPE=RelWithDebInfo -DBUILD_TESTING=ON -DBASELINE_SANITIZERS=OFF` | `multiseed-<variant>-<seed>`；动机复采 `motivation777-<variant>` |
| 模块四 | `build/review-four-module` | `cmake -S . -B build/review-four-module -G Ninja -DCMAKE_BUILD_TYPE=RelWithDebInfo -DBUILD_TESTING=ON -DBASELINE_SANITIZERS=OFF` | `review-<variant>`（仅 4.3 的小样本摘要核对用） |

  构建与测试命令随之固定为 `cmake --build <dir> --parallel` 与
  `ctest --test-dir <dir> --output-on-failure`（`ctest -N` 同样带 `--test-dir <dir>`）。

  **为什么写死 `-G Ninja` 与 `RelWithDebInfo`**：编译器是否内联 deployable 的编码器
  （M1-5a 的全部分流）以及 hardened 约 400ns 代价是否成立（M1-8）都取决于优化级别，
  1.5 又自称结论只覆盖 RelWithDebInfo。既有先例 `docs/evidence/mitigation/README.md:6-8`
  记录的正是 CMake 4.3.2 / **Ninja** / RelWithDebInfo（`-O2 -g -DNDEBUG -std=c11`），
  对应 `.meta` 实测字段 `generator=Ninja`、`configuration=RelWithDebInfo`、
  `compiler_flags= -O2 -g -DNDEBUG -std=c11`、
  `compile_options=-Wall -Wextra -Wpedantic -Wshadow -Wconversion -Wstrict-prototypes -Werror`；
  沿用 Ninja 是为了与归档的三变体反汇编同配置可比。
  **注意与 preset 的差异必须写进证据**：`baseline` preset 的生成器实测是
  `Unix Makefiles`（`CMakePresets.json:12`），与上面三个采集目录的 `Ninja` **不同**；
  地址与反汇编结论不跨构建复用，所以每个证据 `README.md` 必须逐字抄录该目录 `.meta` 的
  `generator=` / `configuration=` / `compiler_flags=` / `compile_options=` 实测值，
  并写明「本目录结论只覆盖这一配置」。若实测生成器与
  `docs/evidence/mitigation` 不同（例如本机没有 `ninja` 而回退到 Unix Makefiles），
  必须在 README 明确写出该差异及其对可比性的影响，不得默默换掉。

- `ctest -N` 的实测项数每个模块都要记录。基线与预期增量：

| 阶段 | 预期 CTest 项数 | 新增项 |
|---|---|---|
| 当前 | 13 | — |
| 模块一后 | 16 | `deployable_kat`、`deployable_random_failure`、`equivalence_deployable` |
| 模块三后 | 18 | `analysis_groups`、`analysis_round1_replay` |

表中的 16 / 18 是设计预期，**最终文档必须写 `ctest -N` 的实测值**；不一致时以实测为准并说明原因。

### 0.3 只读边界

`vendor/`、`tests/vectors/`、`docs/evidence/` 下**已封存**的目录一律只读：不编辑、不重新生成、
不删除、不格式化。新证据只进新目录。补丁只作用于构建目录副本（`cmake/PrepareVariant.cmake`
已如此实现）。

**「已封存」的定义（可机械判断）**：当前 `main` 上**已提交**的 `docs/evidence/` 下的全部目录。
本轮实测共 **8 个**：`cmake`、`completion`、`final`、`linux-gcc`、`mitigation`、`module3`、
`review`、`statistics`。其中 `module3` 只有 `SHA256SUMS` 与 `encoder-arm64.txt` 两份文件，
既无 `README.md` 也无 `record-checks.txt`，**不满足 0.4 的必备清单**，属历史遗留；
它**同样只读**，并且**不得回头补齐**——补齐等于事后给一份已归档证据加内容，
与「新证据只进新目录」冲突。本次四个模块新建的目录（`deployable`、`linux-amd64`、
`statistics-multiseed`、`review-four-module`）在各自的证据提交落地后同样进入封存状态。

### 0.4 证据目录统一契约

每个新证据目录（`docs/evidence/<name>/`）必须包含：

1. `README.md`：开头写平台与工具版本、绑定的源码提交号、`git status` 是否干净；
   然后写覆盖内容、结论、**结论边界（支持什么／不支持什么）**、复现命令。
2. 原始产物：日志逐字保存（不裁剪、不重排），`compile_commands.json`（如涉及构建）。
3. `binaries.sha256`（`shasum -a 256`，被测产物）与 `record-checks.txt`
   （独立摘要与一致性核对，沿用 `openssl dgst -sha3-256`）。
   **摘要对象一律是构建目录里的产物文件，按既有口径逐字保留其路径，不把二进制副本拷进仓库**
   （实测先例：`docs/evidence/mitigation/binaries.sha256` 七行全是
   `build/mitigation/reference/measure` 这类构建目录路径，目录内没有任何二进制副本；
   `docs/evidence/` 下目前一个二进制文件都没有）。
   模块二的构建目录在容器内，但 2.2 已把它绑定到宿主 `/tmp/linux-amd64-build`，
   八个产物在宿主直接可见，因此模块二的 `binaries.sha256` 同样对**宿主可见的构建目录路径**算，
   并在 `record-checks.txt` 里附带容器内／宿主两侧 `shasum -a 256` 的逐行一致性核对，
   钉住「两侧看到的是同一份文件」，细则见 M2-11 与 2.4。
   这样四个新证据目录的摘要对象口径一致（都是构建目录文件），清单一致才有可核对性。
4. `SHA256SUMS`：覆盖本目录**除 `SHA256SUMS` 自身以外**的全部文件（校验文件不能包含自身摘要；
   既有口径实测即如此：`docs/evidence/mitigation/` 有 20 个文件、`SHA256SUMS` 19 行），可用
   `shasum -a 256 -c docs/evidence/<name>/SHA256SUMS`（在仓库根目录）核对。
5. 目录内所有摘要必须是**独立工具**算出的（OpenSSL / shasum），并与程序自报字段
   （`.report` 的 `csv_digest`、`.meta` 的 `executable_digest`）逐个对照，
   不用被测程序自证。
6. **`.gitattributes` 条目**：既有 `.gitattributes` 实测**不是**给每个证据目录都加同一组条目，
   而是按需添加（`cmake`、`linux-gcc` 各有 `*.log` + `*.meta`；`completion`、`mitigation`、
   `review`、`statistics` 只有 `*.meta`；`docs/evidence/final/*.txt` 这类反汇编文本没有条目）。
   本次沿用「按需添加、不发明新模式」，并把它变成机械步骤：每个证据提交前执行

```sh
git add docs/evidence/<name>
git diff --cached --check
echo "exit=$?"
```

   有 `blank at EOL` 一类警告就为该目录补 `whitespace=-blank-at-eol` 条目（模式限定为
   实际报警的 `*.log` / `*.meta`，与既有条目同型），再重跑上面两条命令；
   输出（含空结果）逐字写入该目录的 `record-checks.txt`。
   预期落点：`deployable`、`linux-amd64`、`statistics-multiseed` 三个目录归档了机器生成的
   `*.log` 与 `*.meta`，预期各需 `*.log` + `*.meta` 两条；`review-four-module` 只归档 `*.log`
   （以及 `.txt`，照 `docs/evidence/final` 先例不加条目），预期只需 `*.log` 一条。
   **这是预期不是结论**：以 `git diff --cached --check` 的实测输出为准，实际加了哪几条要写进
   `record-checks.txt`；一条都不需要加时也要把空输出留下来，不得默默省略。
   `.gitattributes` 的改动跟在**该模块的证据提交（提交 B）**里，不单独开提交。

### 0.5 缺口记录规程（任何模块适用）

某项在本机做不到时：**不伪造、不降级冒充、不削弱测试让它通过**。按以下方式记录并继续下一模块：

1. 在对应证据目录保存逐字失败输出（如 `attempt-failure.log`），含实际执行的完整命令。
2. 在证据 `README.md` 增加「未能完成的项」小节：尝试过程、失败原因、需要什么条件才能完成。
3. 在模块对应的 `docs/*.md` 章节与 `docs/acceptance.md` 的追加章节里同样列为未闭合项。
4. 最终报告里单列。特别地：QEMU 模拟、容器、交叉编译、macOS/ARM 一律不得表述为
   真实 x86_64 Linux 实测。

**模块间依赖降级规则（0.5 的延伸，覆盖「串行不跳步」下的前提失效）**：模块二 M2-6/M2-7 与
模块三 3.2 都把「四个变体」写成硬前提，所以模块一失败会让它们不可执行。**触发条件**固定为：
`deployable` 目标**无法构建**，或 `deployable_kat` / `deployable_random_failure` /
`equivalence_deployable` 中任一项**未通过**。处置固定为：

- **第 1 步（择一已写死：撤回注册）**：用一个独立的 `fix:` 或 `docs:` 提交**撤回 deployable
  的注册**——`CMakeLists.txt` 的 `foreach(patched_variant …)` 与 `foreach(variant …)` 列表移除
  `deployable`、移除 `equivalence_deployable` 的循环项，`tests/test_cli.sh`、
  `tests/test_measurement.sh`、`tests/test_analysis.sh`、`tests/test_vector_parser.sh`
  **四个**脚本的变体循环去掉 `deployable`，**并还原 `tests/test_cli.sh` 末尾那段跨变体
  逐字节比较块**（实测在 41–44 行，见 1.2；它不在变体循环内，加 `deployable` 与去掉
  `deployable` 都必须单独改它）。
  `src/mlkem.c` 的 `BASELINE_DEPLOYABLE` 分支与 `docs/patches/message-value-barrier.patch`
  **保留在仓库里**（它们是缺口的材料），只撤回构建与测试注册。
  撤回后 `ctest -N` 实测值预期回到 **13**（模块三后 **15**）。
  **不采用**「保留注册并接受三项失败」的替代路线：本仓库既有证据目录都记录了「全部 CTest 通过」
  （实测七份有 CTest 记录：`completion`、`mitigation`、`review`、`statistics` 带 `ctest.log`；
  `cmake` 带 `multi-config-ctest.log` 与 `sanitize-ctest.log`；`final` 带 `build-and-test.log`
  与 `sanitize.log`；`linux-gcc` 的 CTest 结果在 `verification.log` 里。
  第 8 个目录 `module3` 没有任何 CTest 记录，见 0.3），
  留一个长期失败的注册会让后续每个模块的 `ctest` 判据都带一个必须口头解释的例外，
  比撤回注册更容易被误读成「测试本来就允许红」。
- **第 2 步（判据改写）**：M1-2、M1-3、M3-3、M4-1 的项数一律以**降级后 `ctest -N` 的实测值**
  为准（预期 13 / 13 / 15 / 15），判据文字改为「实测项数 N，全部通过」，
  并在同一处注明「N 低于未降级预期的 16 / 18，原因见模块一缺口记录」。
  **不得**把失败项算作通过，也不得放宽断言让它通过。
- **第 3 步（缺口材料）**：失败时的补丁、`configure.log` / `build.log` / `ctest.log` 的逐字失败
  输出与实际命令，全部留在 `docs/evidence/deployable/`，按 0.5 的四步记录。
- **第 4 步（下游变体数）**：模块二与模块三改为覆盖 reference / vulnerable / hardened
  **三个**变体继续执行：模块二的反汇编、调用路径核对、冒烟采集与摘要对照都变为 3 份；
  模块三的预注册采集由 4×5=20 次变为 3×5=**15 次**，动机复采由 4 次变为 3 次；
  **M3-1 最后一条的「真实数据全流程」由四个变体小样本改为三个变体小样本**，
  三个 `test_*.sh` 与 `test_vector_parser.sh` 的变体循环在降级后按三变体执行
  （因为第 1 步已经把 `deployable` 从循环里去掉了）。
- 3.2 中 deployable 的方向性期待**不得删除、也不得改判为成立**，记为「未采集」。
- 所有汇总表（含 M3-5、最终报告）保留 deployable 行，值写「未采集（原因见模块一缺口记录）」。
- 该降级**不影响**第二轮预注册的内容：种子清单、样本量、假设与阈值在模块零提交时已固定，
  不因变体数量变化而调整。

### 0.6 已核实的仓库事实（设计依据，不需重新发现）

- **上游 `mlk_poly_frommsg` 本来就是无分支实现**：`vendor/mlkem-native/mlkem/src/compress.c`
  用 `mlk_value_barrier_u8((uint8_t)(1u << j))` 取位掩码，再用
  `mlk_ct_sel_int16(MLKEM_Q_HALF, 0, msg[i] & mask)` 做选择；
  `mlk_ct_sel_int16` / `mlk_ct_cmask_nonzero_u16` / `mlk_value_barrier_*` 定义在
  `vendor/mlkem-native/mlkem/src/verify.h`，GCC/Clang 下值屏障是空 `__asm__ volatile("" : "+r"(b))`，
  否则回退到 volatile 全局 opt-blocker。**这直接决定模块一的目标必须调整**，见 1.1。
- 原生后端是 opt-in：`MLK_CONFIG_USE_NATIVE_BACKEND_ARITH` 未在
  `include/baseline_config.h` 中定义，`src/native/meta.h` 因此不会被引入，
  x86_64 上也不会启用 AVX2 后端。模块二的结论只覆盖便携 C 后端。
- 反汇编命令（与既有证据格式一致，已实测）：
  - macOS / Apple objdump：`objdump -d --disassemble-symbols=_baseline_native_poly_frommsg <binary>`
  - Linux / GNU binutils：`objdump -d --disassemble=baseline_native_poly_frommsg <binary>`
    （GNU 与 LLVM 的选项拼写不同，容器内先用 `objdump --help` 确认实际支持的写法并记录）
  既有证据文件没有记录该命令，本次新证据 `README.md` 必须写出实际命令。
- **编码函数目前确实是独立调用，但这点对 deployable 必须重新验证**：`mlk_poly_frommsg` 是
  `MLK_INTERNAL_API`（外部链接），所以离线副本总会存在；问题是它是否真的被调用。
  **调用者是 `mlk_indcpa_enc`，不是 `mlk_indcpa_dec`**（第二轮评审纠正的事实错误，本轮复核确认）：
  `vendor/mlkem-native/mlkem/src/indcpa.c:544` 的 `mlk_poly_frommsg(k, m);` 位于
  `mlk_indcpa_enc`（该函数自 `indcpa.c:518` 起），且 `grep -rn 'poly_frommsg' vendor/…/src/`
  实测这是全 vendor **唯一**的调用点；`mlk_indcpa_dec` 只调 `mlk_poly_tomsg`。
  解封装路径是 `dec → indcpa_enc`（隐式拒绝所需的**重加密**）`→ poly_frommsg`，
  所以编码函数确实在解封装窗口内执行，但它的**词法调用者是 `indcpa_enc`**。
  本机对 `build/cmake/reference/measure` 实测：符号在 `0x100002690`，
  全二进制中只有一处 `100006edc: bl 0x100002690 <_baseline_native_poly_frommsg>`，
  该地址落在 `_baseline_native_indcpa_enc`（起始 `0x100006e50`）之内，而
  `_baseline_native_indcpa_dec` 起始于 `0x100008ad8`；即 reference 在 `-O2` 下**没有被内联**。
  `_baseline_native_indcpa_enc` 自身也没有被内联，实测
  `objdump -d … | grep -c 'bl.*<_baseline_native_indcpa_enc>'` = **2**
  （`10000b8d4` 在 `_baseline_native_enc_derand` 内、`10000ba48` 在 `_baseline_native_dec` 内）。
  vulnerable / hardened 靠补丁里的 `noinline` 保证独立符号，
  而 **deployable 按设计不带任何 `__attribute__`，因此没有 `noinline` 保护**，
  编译器完全可能把它内联到 `mlk_indcpa_enc` 里，使「离线副本的反汇编」不再等于实际执行的代码。
  这直接产生 M1-5a / M2-7a 的调用路径核对要求，**其调用者符号一律取 `indcpa_enc`**
  （层级规则见 M1-5a 第 2 步）。
  既有 `docs/evidence/final/vulnerable-path-arm64.txt` 就是「全二进制反汇编作为调用路径证据」
  的现成格式（实测 2216 行全量反汇编），本次沿用。
- **内联判据所用常数 `0x681`（`MLKEM_Q_HALF` = 1665）在本仓库高度特异（本轮实测）**：
  对 `build/mitigation/{reference,vulnerable,hardened}/measure` 三份归档同配置产物，
  正则 `(#|\$)0x681|[#$ ]1665\b` 在**全二进制**反汇编中各命中 **1** 次，就在编码函数内
  （Apple objdump 印作 `mov w10, #0x681             ; =1665`）；
  同一正则对 `_baseline_native_indcpa_enc` 的调用者反汇编各命中 **0** 次。
  `MLKEM_Q_HALF` 在 vendor 其他出现处（`poly.c` 的 `mlk_assert_abs_bound` / CBMC 契约）
  在本仓库不产生代码，因此「调用者里出现 `0x681` 就说明有内联副本」是可用的充分条件。
  三个变体的编码函数都物化这个常数（vulnerable 的两条分支分别写 `0x681` 与 `wzr`，
  hardened 写 `selection_mask & MLKEM_Q_HALF`，reference 走 `mlk_ct_sel_int16(MLKEM_Q_HALF, 0, …)`），
  所以判据对四个变体同样适用。**这是 ARM64 / Apple objdump 的实测，x86_64 / GNU objdump
  侧的印法未验证**，落点见 M2-7a。
- **`mlk_assert_abs_bound` 在本仓库任何 preset 下都展开成 `do {} while (0)`**：
  `vendor/mlkem-native/mlkem/src/debug.h` 的三分支按 `MLKEM_DEBUG` / `CBMC` 选择，
  而 `MLK_CONFIG_DEBUG` 与 `MLKEM_DEBUG` 在 `include/`、`CMakeLists.txt`、`cmake/`、`src/`
  中**一次都没有出现**（已 grep 确认）。`sanitize` preset 只是 `CMAKE_BUILD_TYPE=Debug`
  加 ASan/UBSan，并不定义 `MLK_CONFIG_DEBUG`。因此保留该断言**不产生任何代码、也永远不会触发**，
  它的唯一价值是源码形态贴近上游。1.2 的表述据此修正。
- **上层协调者提到的种子 777 复核数据在本仓库不可追溯（已确认，不是「待查」）**：
  在整个工作树中搜索 `test_seed=777` 无任何命中；`runs/` 只有
  `module5`、`module5-final`、`readme.Y0FbhI`、`review-reproduction`、`style-patch` 五个目录，
  其中 `.meta` 全是 `test_seed=42`，且 `runs/` 被 `.gitignore` 排除（`/runs/`）。
  处理办法见 3.1。
- **归档报告中主比较的实测值（本次逐份读取确认，模块三必须照此引用，不得凭记忆改写）**：

| 报告 | `significant_comparison_count` | 主比较 `mean_difference_ns` | `rank_z` | `rank_p` | `result` |
|---|---|---|---|---|---|
| `statistics/vulnerable.report` | 7 / 10 | −83.200 | −4.0408 | 5.32762e-05 | significant |
| `statistics/vulnerable-replication.report` | 7 / 10 | −55.800 | −4.8309 | 1.35919e-06 | significant |
| `mitigation/vulnerable.report` | 6 / 10 | −84.200 | −3.8338 | 0.000126165 | not_significant |
| `mitigation/hardened.report` | 0 / 10 | −21.000 | −0.8239 | 0.410017 | not_significant |
| `mitigation/reference.report` | 0 / 10 | +12.600 | +1.2690 | 0.204443 | not_significant |
| `statistics/reference.report` | 0 / 10 | +7.800 | −0.4954 | 0.620339 | not_significant |
| `statistics/reference-replication.report` | 0 / 10 | +0.800 | −0.8037 | 0.421582 | not_significant |

  全部为 `n1=n2=5000`、`median_difference_ns=0.0`。三次缺陷版主比较的**符号一致为负**，
  这一点决定了 3.1 不能写成「方向跨运行不稳定」。
- `measure` 的输入约束（限制模块一、模块三的采集参数）：`samples_per_category`
  必须在 `1..20000`，因此每类 5000 合法；`RUN_ID` 长度 1..64、字符集 `[A-Za-z0-9_-]`；
  `test_seed` 走 `uint64_t`，`141421356` 等全部合法。命令形式
  `measure RUN_ID SEED SAMPLES_PER_CATEGORY CSV_FILE META_FILE`。
- `analyze` 固定族共 **10** 个比较（`src/analyze.c` 的 `prespecified_comparisons`），
  所以「x/10」的分母是源码事实，不是约定。
- `src/analyze.c` 的 `is_valid_implementation_name` 只接受小写字母与 `-`，
  因此新变体名必须是小写（`deployable` 合法）。
- 归档报告里的 `csv_path` 是仓库相对路径（如 `docs/evidence/mitigation/vulnerable.csv`），
  因此第一轮报告可在仓库根目录**逐字重放**，这是模块三 `analysis_round1_replay` 的基础。
- 本机：Apple M5 / ARM64 macOS、Apple Clang 21、`CLOCK_MONOTONIC` 分辨率 1000ns。
  Docker server 29.3.1，`docker buildx ls` 实测列出 `linux/amd64`（Apple Silicon 上为模拟执行，
  但该输出本身没有 emulated 标记，见 M2-2）。

---

## 1. 模块一：可部署的恒时编码变体（正常优化下）

### 1.1 目标与被迫调整的部分

闭合 `docs/mitigation.md` 自述的下一步：去掉函数级优化控制、改用上游值屏障写法、
对该配置重新做反汇编与统计验证。

**必须如实记录的调整**：上游 `mlk_poly_frommsg` 已经是带值屏障的无分支实现（见 0.6），
所以新变体不是「修补上游漏洞」，也不可能比 reference 更安全。新变体的真实意义收窄为三点，
文档必须按这三点表述，不得升级：

1. 证明 hardened 那条补丁的**源码形态**（平铺 256 次循环 + 自有命名）在去掉
   `optnone` / `optimize("O0")`、改用上游值屏障后，`-O2` 下**没有被编译器重新引入
   消息位相关条件分支**；
2. 量化 hardened 为保持对照而保留 `optnone` 所付出的约 400ns 代价在新变体上消失；
3. 给出一个「若要部署，应该长成什么样」的可执行参照配置，其与 reference 的差别被明确写出。

**不要改动 hardened**：它是「只改变有无分支」这一项的对照，必须原样保留。

### 1.2 设计决定

- 变体名 `deployable`（小写，满足 CSV 实现名字符集）。产物路径
  `build/deployable/deployable/{baseline,measure}`。
- 新补丁 `docs/patches/message-value-barrier.patch`（独立文件，命名取其区别特征：
  用上游值屏障而非自造掩码）。它相对上游的改动只有：
  - 去掉 `#if defined(__clang__) … optnone … #elif defined(__GNUC__) … optimize("O0") … noinline`
    这段函数级优化控制（即不写任何 `__attribute__`），按所选构建配置正常编译；
    **后果**：deployable 同时失去 `noinline`，所以「反汇编的是不是实际执行的代码」
    必须由 M1-5 的调用路径核对回答，不能假设；
  - 保持与 vulnerable / hardened 相同的平铺单层循环与自有 snake_case 命名
    （参数名沿用两个既有补丁的 `message_polynomial` / `message_bytes`，
    循环变量 `coefficient_index`），使四个变体的源码形态可直接对照；
  - 位选择改用上游设施：`mlk_value_barrier_u8` 取位掩码 + `mlk_ct_sel_int16` 做选择。
    `mlk_ct_sel_int16` 的签名是 `(int16_t a, int16_t b, uint16_t cond)`，
    因此条件参数必须显式转 `uint16_t` 才能过 `-Wconversion -Werror`。
    **目标片段写死如下**（照 `docs/mitigation.md` 对 hardened 给出片段的先例，
    免得字节/位索引算法、屏障取法与 `MLKEM_Q_HALF` 的传参形式留给实现时临场决定，
    而 `-Wall -Wextra -Wpedantic -Wshadow -Wconversion -Wstrict-prototypes -Werror`
    （`CMakeLists.txt` 的 `baseline_options` 实测值）对这几处敏感）：

```c
for (unsigned coefficient_index = 0; coefficient_index < MLKEM_N; ++coefficient_index) {
    const uint8_t bit_mask = mlk_value_barrier_u8((uint8_t)(1u << (coefficient_index % 8u)));
    const uint16_t selection_condition
        = (uint16_t)(message_bytes[coefficient_index / 8u] & bit_mask);
    message_polynomial->coeffs[coefficient_index]
        = mlk_ct_sel_int16(MLKEM_Q_HALF, 0, selection_condition);
}
```

    两点说明：**值屏障按系数取**（每次迭代算一次 `1u << (coefficient_index % 8u)`），
    与上游「外层按字节、内层按位」的写法在数值上等价，但形态贴近平铺单层循环，
    与 vulnerable / hardened 的源码形态可直接对照；
    `selection_condition` 的显式 `uint16_t` 转换是为了过 `-Wconversion -Werror`
    （`message_bytes[...] & bit_mask` 的整型提升结果是 `int`）。
    实现时若该片段与严格警告冲突，按 M2-4 的口径修并记录实际写法，**不得**删警告选项。
  - **保留**上游的编译期守卫
    `#if (MLKEM_INDCPA_MSGBYTES != MLKEM_N / 8) #error "MLKEM_INDCPA_MSGBYTES must be equal to MLKEM_N/8 bytes!" #endif`，
    位置放在函数体开头、平铺循环之前（上游原文在 `unsigned i;` 之后）。
    **这是与另两个补丁的一处有意差别**：`docs/patches/message-constant-time.patch` 实测把这段守卫
    一并删掉了，而 deployable 的定位是「若要部署，应该长成什么样」的参照，
    保留上游的编译期一致性检查符合这个定位，且它是纯预处理判断、**不产生任何指令**，
    对产物与反汇编结论零影响。文档必须把这一差别写出来，并明确它属**源码形态**差别，
    **不得**表述为「deployable 多了一层运行时检查」——与 `mlk_assert_abs_bound` 同样的口径；
  - 收尾写 `mlk_assert_abs_bound(message_polynomial, MLKEM_N, MLKEM_Q)`（注意用改名后的参数，
    上游原文是 `r`）。**如实记录其实际效果**：按 0.6 的核实，本仓库任何 preset 都没有定义
    `MLK_CONFIG_DEBUG`，该宏一律展开成 `do {} while (0)`，所以它不产生代码、不可能触发，
    与 vulnerable / hardened 补丁删掉它在产物上**没有差别**；保留它只是为了贴近上游源码形态。
    文档不得把它写成「deployable 多了一层边界检查」。
  - 与另两个补丁一样**不保留** `__loop__` 回路契约。
- 补丁必须**无 fuzz 应用**（`cmake/PrepareVariant.cmake` 只用 `patch -p1 -i`，
  不带 `--no-fuzz`，所以 fuzz 会被静默接受）。因此提交 A 之前必须执行下面这条**写死的命令**，
  并把输出（**含空结果**）逐字写入 `docs/evidence/deployable/record-checks.txt`：

```sh
grep -n 'with fuzz' docs/evidence/deployable/build.log; echo "exit=$?"
```

  判据：`exit=1`（grep 无匹配）即通过；`exit=0` 说明有 fuzz 应用，必须修补丁上下文后重新构建
  并重跑该命令，**不得**带着 fuzz 继续。提交 A 之前先在采集构建目录的 `build.log` 上跑同一条
  命令（把路径换成 `build/deployable` 下的日志），归档时再对归档副本跑一次。
  这条是既有历史 `fix: apply the constant-time encoder patch without context fuzz` 的教训，
  必须复用。
- 选型理由：备选方案是「自造掩码 `0u - message_bit` 直接在 `-O2` 下编译」。
  不采用，因为上游注释明确说明无屏障的掩码写法可能被编译器还原成分支，
  而本模块的目的正是给出可部署参照；用上游惯用法也避免自行发明常数时间原语。
- 可选补充观察（**不新增第五个变体**）：可以额外记录「无屏障掩码在 `-O2` 下」的一次性反汇编，
  作为「编译器可能重新引入分支」的说明性材料，放入证据目录并标注为一次性观察、
  不参与任何统计与 CTest。做不做都不影响验收。
- CMake 改动：
  - `encoder_patch_deployable` 指向新补丁；`foreach(patched_variant IN ITEMS vulnerable hardened
    deployable)`；主 `foreach(variant IN ITEMS reference vulnerable hardened deployable)`；
    在既有 `if(variant STREQUAL "vulnerable") … elseif(variant STREQUAL "hardened")` 链条上
    追加 `elseif(variant STREQUAL "deployable")` 给出 `BASELINE_DEPLOYABLE=1` 编译定义。
  - 两处重复的 `equivalence_*` 注册改成对 `vulnerable hardened deployable` 的循环，
    测试名保持 `equivalence_vulnerable` / `equivalence_hardened` 不变（用 `ctest -N` 核对）。
- `src/mlkem.c` 的 `mlkem_implementation_name()` 增加 `#elif defined(BASELINE_DEPLOYABLE)`
  分支返回 `"deployable"`。
- `tests/test_cli.sh`、`tests/test_measurement.sh`、`tests/test_analysis.sh`、
  `tests/test_vector_parser.sh` 的变体循环各加 `deployable`（**四个**脚本，实测四处
  `for implementation in reference vulnerable hardened`，分别在
  `test_cli.sh:6`、`test_measurement.sh:6`、`test_analysis.sh:134`、`test_vector_parser.sh:11`；
  原设计漏了 `test_vector_parser.sh`，那会让 `vector_parser` 这项 CTest 不覆盖新变体）。
  这四项仍各是一个 CTest 项，不增加项数。
- **`tests/test_cli.sh` 末尾还有一段不在变体循环里的硬编码比较块，必须单独改**：
  实测 41–44 行是

```sh
for category in valid bit-flipped random message-zero message-ones; do
    cmp "$test_directory/reference-$category" "$test_directory/vulnerable-$category"
    cmp "$test_directory/reference-$category" "$test_directory/hardened-$category"
done
```

  即「新变体生成的测试向量与 reference 逐字节一致」是**逐变体列出**的。只改 `:6` 的循环，
  deployable 会生成五个文件却从不被比较，CLI 层的跨变体一致性检查静默漏掉新变体
  （与 8.4 自查出的 `test_vector_parser.sh` 漏项同类）。**改法写死**为对变体再套一层循环：

```sh
for category in valid bit-flipped random message-zero message-ones; do
    for variant in vulnerable hardened deployable; do
        cmp "$test_directory/reference-$category" "$test_directory/$variant-$category"
    done
done
```

  （等效的最小改法是在原块里补一行 `cmp … "$test_directory/deployable-$category"`；
  两种都可，选哪种都要让三个变体都被比较。）
  另两处硬编码**不需要改**，已逐条核对：`tests/test_measurement.sh:29` 与 `:32` 的
  `reference.csv` / `vulnerable.csv` 是比较工具 `test_measurement` 的固定一对参数
  （`hardened` 本来也不在内）；`tests/test_analysis.sh:100` 的 `s/,reference,/,hardened,/`
  是构造「跨行 implementation 不一致」畸形 CSV 用的字面量，不是变体枚举。

### 1.3 验收标准（逐条可执行）

- **M1-1** `build/deployable/deployable/baseline version` 输出 `deployable ML-KEM-768 FIPS203`；
  采集 `.meta` 的 `implementation=deployable`。
- **M1-2** `ctest -N`（`--test-dir build/deployable`）实测项数为 16（预期），且新增
  `deployable_kat`、`deployable_random_failure`、`equivalence_deployable` 三项；
  `ctest --preset baseline` 全通过。
  `deployable_kat` 覆盖 80 组 NIST 独立预期答案（25 keygen / 25 encaps / 10 decaps / 20 key checks，
  含 5 组隐式拒绝），`equivalence_deployable` 覆盖 64 种子 × 三类输入与 reference 逐字节一致。
  **触发 0.5 的降级规则时**：项数改写为降级后 `ctest -N` 的实测值（预期 13），
  判据变为「实测 N 项全部通过」，并注明 N 低于 16 的原因与缺口落点。
- **M1-3** `ctest --preset sanitize` 16 项全通过，无 ASan/UBSan 报告。
  （降级时同 M1-2，改写为降级后实测项数。）
- **M1-4** `cmake --build --preset baseline --target format-check` 通过；
  `cmake-format --check` 与 `sh -n` 通过（见 4.2）。
- **M1-5** 四个变体（reference / vulnerable / hardened / deployable）的编码函数
  ARM64 反汇编各一份，格式与现成的三变体先例
  `docs/evidence/mitigation/{reference,vulnerable,hardened}-encoder-arm64.txt` 一致
  （`docs/evidence/completion/` 下只有 `reference-encoder-arm64.txt` 一份，不作为四份的格式参照）。
  判定：deployable 函数体内**只有循环边界条件分支**，不存在由消息位控制的
  `tbz` / `cbz` / `cmp+b.eq` 之类；逐条列出实际出现的条件分支指令与地址。
  **「只有循环边界分支」的判定口径写死（否则这一句是人工裁量）**：
  1. 先把该函数反汇编里**所有**条件跳转逐条列出（地址 + 助记符），一条不漏地抄进
     `README.md`；
  2. 再逐条标注归属：**循环计数比较**判为循环边界（ARM64 实测形式为 `b.ne`（Apple Clang）
     与 `b.ls`（ARM64 GCC），依据是 `docs/evidence/linux-gcc/README.md` 的表与
     `docs/evidence/mitigation/*-encoder-arm64.txt`；x86_64 / GNU 侧的形式**尚未观察**，
     按模块二实测填写，不先写死）；操作数链能追到 `message_bytes` 取字节/取位的
     判为**消息位相关**；
  3. 标注依据（上一条影响标志位的指令是什么、它的操作数从哪来）写进 `README.md`，
     不只给结论；
  4. **归属无法判定的条件跳转按 0.5 记缺口**，逐字留输出，**不得默认算作循环边界**。

  若 `-O2` 下出现了消息位相关分支，**照实记录为本模块的主要发现**，不换写法、不调编译选项去掩盖。
- **M1-5a 调用路径核对（因 deployable 无 `noinline` 而必需，见 0.6）**：离线副本一定存在
  （`MLK_INTERNAL_API` 展开为空，外部链接），所以真正的风险只在「是否**另有**内联副本」。
  因此调用者反汇编**无条件产出**，不作为情况 2 的应急手段：
  1. 对 `build/deployable/deployable/measure` 做**全二进制**反汇编，存为
     `deployable-path-arm64.txt`（格式照 `docs/evidence/final/vulnerable-path-arm64.txt`），
     并记录 `grep -c 'bl.*<_baseline_native_poly_frommsg>'` 的实测计数与每处地址。
  2. **四个变体都**产出调用者反汇编。**调用者是 `mlk_indcpa_enc`**（见 0.6：解封装路径为
     `dec → indcpa_enc`（重加密）`→ poly_frommsg`；`indcpa_dec` 只调 `poly_tomsg`）。
     命令写死为：

```sh
objdump -d --disassemble-symbols=_baseline_native_indcpa_enc \
    build/deployable/<variant>/measure > {variant}-caller-indcpa-enc-arm64.txt
```

     **层级规则（先记计数再决定取哪一层，不许凭猜）**：先对全二进制反汇编执行
     `grep -c 'bl.*<_baseline_native_indcpa_enc>'`。
     - 计数 ≥ 1 → `indcpa_enc` 自身是独立符号，调用者取 `_baseline_native_indcpa_enc`。
       本机 reference / vulnerable / hardened 三份归档同配置产物实测该计数均为 **2**，
       正常情况走这条。
     - 计数为 0 → `indcpa_enc` 自己被内联进了 `_baseline_native_dec`，调用者改取
       `_baseline_native_dec`（文件名相应为 `{variant}-caller-dec-arm64.txt`），
       并在 `README.md` 与 `call-site-counts.txt` 写明**取的是哪一层符号、为什么**。
     该计数与所取符号必须逐个变体记录在 `call-site-counts.txt` 里。
  3. **机械判据（充分条件，写死正则）**：在上一步产出的调用者反汇编上执行

```sh
grep -nE '(#|\$)0x681|[#$ ]1665\b' {variant}-caller-indcpa-enc-arm64.txt; echo "exit=$?"
```

     命中（`exit=0`）即判**存在内联副本**；未命中（`exit=1`）即判无内联副本。
     正则同时覆盖 Apple objdump 的 `#0x681`、GNU x86_64 的 `$0x681`、以及可能的十进制
     `1665` 印法（本机 Apple objdump 实测印作 `mov w10, #0x681             ; =1665`）。
     **特异性对照（同一正则，对全二进制反汇编）**：`grep -cE '(#|\$)0x681|[#$ ]1665\b' <全二进制反汇编>`，
     本机对三份归档产物实测均为 **1**（就在编码函数内），该计数一并归档；
     若某变体的全二进制计数 > 1 而调用者命中 0，说明常数还有别的来源，必须在 README 写明
     多出来的那几处落在哪个符号里，再下结论。
     **「按系数推进的 256 次循环结构」降为佐证，不作判据**（原设计把它写成合取项，
     但 grep 表达不出「256 次系数循环」，那会让判据回到人工裁量）：正则命中后，
     人工读该段并在 `README.md` 引用**行号区间**与看到的循环形态，作为对「命中不是巧合」的佐证。
     三种情况都必须在 `README.md` 贴出实际命令与命中行／空结果。

  三种情况由此可操作地区分，各有明确处置：
  - **情况 1 = `poly_frommsg` 调用点计数 ≥ 1 且调用者正则未命中** → M1-5 的反汇编就是实际执行的
    代码，正常继续。本机三份归档产物实测全部落在情况 1（调用点 1 次、调用者命中 0 次）。
  - **情况 2 = `poly_frommsg` 调用点计数为 0**（编译器内联了该函数）→ **M1-5 的离线副本反汇编
    不构成产物证据**。结论改由调用者内联段给出：在 `{variant}-caller-indcpa-enc-arm64.txt`
    中定位消息编码段（以正则命中行为锚点），按 M1-5 的同一口径列出条件分支；
    同时在 `README.md` 与 `docs/mitigation.md` 明确写出
    「本变体被内联，结论来自调用者内联段」。
    **不得**为了拿到独立符号而给 deployable 加回 `noinline`——那样就退回 hardened 的处境，
    本模块的目的就没了。
  - **情况 3 = 调用点计数 ≥ 1 且调用者正则命中**（部分内联）→ 离线副本与内联段两处都判定，
    结论取较弱的一方，并写明两处的判定结果各是什么。
  - **矛盾组合 = 调用点计数为 0 且调用者正则未命中**（不应该出现：没有调用点就必须有内联副本）
    → **不得**把它读成「无内联」。按 0.5 处理：把两条命令的逐字输出、`deployable-path-arm64.txt`
    与调用者反汇编一并留作缺口材料，在 `README.md` 写明「判据在本变体上自相矛盾，
    产物形态结论未闭合」，并先按 M2-7a 的同一思路检查常数印法是否超出正则；
    仍无法解释时不下产物形态结论，**不以离线副本反汇编冒充执行路径证据**。

  reference / vulnerable / hardened 也各记录一次调用点计数、所取调用者符号与正则判据结果作对照
  （本机对 `build/mitigation` 三份归档产物实测：`poly_frommsg` 调用点各 1、
  `indcpa_enc` 调用点各 2、调用者正则命中各 0、全二进制正则命中各 1，即三者都在情况 1），
  用于说明这不是只对 deployable 放宽的检查。
- **M1-6** 链接与调用路径核对：`compile_commands.json` 确认 deployable 内核来自
  `build/deployable/deployable-source/mlkem` 副本；`build.log` 用 1.2 写死的
  `grep -n 'with fuzz' …; echo "exit=$?"` 确认 `patch` 输出无 fuzz（输出含空结果写入
  `record-checks.txt`）；产物摘要核对**拆成两条，算法不得混用**：
  1. **同算法独立工具对照**：`openssl dgst -sha3-256 build/deployable/<variant>/{baseline,measure}`
     的输出与对应 `.meta` 的 `executable_digest` **逐个相同**。
     `.meta` 实测写的是 `executable_digest_algorithm=SHA3-256`
     （`docs/evidence/mitigation/reference.meta:16-17`），所以只有 SHA3-256 能与它对照；
     现成先例：`docs/evidence/mitigation/record-checks.txt:5` 的
     `SHA3-256(build/mitigation/reference/measure)= 4d677872…fba3c` 与该 `.meta` 的
     `executable_digest` 逐字相同（本轮已复核一致）。这一条才是「测的是该变体产物」的证明。
  2. **`binaries.sha256` 另算、不参与上面的对照**：用 `shasum -a 256` 对同一批产物生成，
     只为满足 0.4 第 3 条的目录必备清单。SHA-256 与 SHA3-256 是不同算法，
     `binaries.sha256` 的值**不可能**等于 `executable_digest`，
     **不得**拿它去和 `executable_digest` 比对，更不得比对不上后改写任何一方
     （这正是 M2-11 明令禁止的做法）。
- **M1-7** 统计：四个变体在**同一次采集会话**、同一公开种子 `20260930`、每类 5000 次
  （每版 25000 条，与 `docs/evidence/mitigation` 同口径）采集，用现有固定 `analyze` 判定。
  `RUN_ID` 固定为 `deployable-<variant>`（如 `deployable-reference`），构建目录 `build/deployable`；
  该 `RUN_ID` 会逐字进入 CSV 每一行、`.meta` 与报告的 `run_id=` 字段。
  如实报告 deployable 的显著数、类别均值极差、最大 |rank z|。
  沿用 `20260930` 是为了与归档的三变体对照直接可比；全新种子的稳健性由模块三负责。
- **M1-8** 性能：同一次会话内给出四个变体的整体均值与各类均值（ns），
  明确 deployable 相对 reference 的差值，并与 hardened 的约 400ns 代价对比。
  只在同一次采集内比较，不跨会话比较。
- **M1-9** 类别顺序一致性：用 `cut` 提取类别列逐字节比较四个变体的 CSV，确认顺序完全相同
  （沿用 `docs/evidence/mitigation/record-checks.txt` 的做法）。
- **M1-10** 文档：`docs/mitigation.md` **追加**新章节（不改写既有结论），给出可执行命令、
  机制、与 reference 的实际差别、验证结果、限制。

### 1.4 证据契约

目录 `docs/evidence/deployable/`：

| 文件 | 内容 |
|---|---|
| `README.md` | 平台/工具版本、**模块零提交号**、源码提交号、干净状态、**0.2 表里的配置命令与 `.meta` 的 `generator=`/`configuration=`/`compiler_flags=`/`compile_options=` 实测抄录**、反汇编命令、判据正则与命中行、结论与边界 |
| `configure.log`、`build.log`、`ctest.log` | 全新构建目录 `build/deployable` 的逐字输出（含配置命令与 `ctest -N`） |
| `sanitize-ctest.log` | sanitize preset 的 16 项结果（降级时为实测项数）。**来自 `build/cmake-sanitize`**（`sanitize` preset 实测：`binaryDir` = `build/cmake-sanitize`、生成器继承 `baseline` 的 `Unix Makefiles`、`CMAKE_BUILD_TYPE=Debug`、`BASELINE_SANITIZERS=ON`，见 `CMakePresets.json:12,22-29`），**不是** `build/deployable` 这一配置；仅用于功能正确性，不用于任何产物形态或性能结论 |
| `compile_commands.json` | 实际编译命令 |
| `{reference,vulnerable,hardened,deployable}-encoder-arm64.txt` | 四份编码函数反汇编 |
| `deployable-path-arm64.txt` | deployable `measure` 的全二进制反汇编（M1-5a 调用路径证据） |
| `{reference,vulnerable,hardened,deployable}-caller-indcpa-enc-arm64.txt` | 四份调用者反汇编（M1-5a 第 2 步，**无条件产出**；调用者是 `indcpa_enc`。若某变体的 `indcpa_enc` 调用点计数为 0，该份改名为 `{variant}-caller-dec-arm64.txt` 并在 README 写明取的层级） |
| `call-site-counts.txt` | 每个变体的 `bl … <_baseline_native_poly_frommsg>` 计数与地址、`bl … <_baseline_native_indcpa_enc>` 计数与所取调用者符号、判据正则 `(#\|\$)0x681\|[#$ ]1665\b` 在调用者反汇编与全二进制反汇编上的 `grep -nE` / `grep -cE` 命令与命中行（含空结果）、以及每个变体落到情况 1/2/3 的结论 |
| `{variant}.csv` / `.meta` / `.report` | 四个变体各 25000 条原始值、元数据、固定检验报告 |
| `record-checks.txt` | 类别顺序比较、四份 CSV 与产物的 SHA3-256、与报告/元数据自报字段的对照、fuzz 核对输出、`git diff --cached --check` 输出（0.4 第 6 条） |
| `binaries.sha256`、`SHA256SUMS` | 产物与全目录摘要（`SHA256SUMS` 不含自身） |

### 1.5 诚实性边界（必须写进文档）

- deployable **不是**对上游漏洞的修复；上游此函数原本无分支。
- 反汇编结论只覆盖 Apple Clang 21 / ARM64 / RelWithDebInfo / **Ninja 生成器、0.2 写死的
  `build/deployable` 配置命令**这一配置和本次构建的地址（`README.md` 抄录 `.meta` 的
  `generator=` / `configuration=` / `compiler_flags=` / `compile_options=` 实测值）；
  x86_64 产物形态由模块二在**模拟环境**给出，且模块二不产出时序结论。
- **本目录的 `sanitize-ctest.log` 属另一套配置**：它来自 `build/cmake-sanitize`
  （`sanitize` preset：`Unix Makefiles` / `Debug` / ASan+UBSan，见 `CMakePresets.json:12,22-29`），
  与本目录其余日志所属的 `build/deployable`（Ninja / RelWithDebInfo）**不是同一配置**；
  它**只用于功能正确性**，不支持任何产物形态、地址或性能结论。
- 0/10 不显著 **不等于**证明恒时；更大样本、其他主机、其他优化级别都可能重新分辨出差异。
- 性能数字只在同一次采集会话内有效；未固定 CPU 亲和性与频率。
- 补丁副本丢掉了上游 `__loop__` 契约，因此上游 CBMC 证明不覆盖被编译的这份副本
  （另两个补丁同样如此，本次一并写明）。
- deployable 保留的 `mlk_assert_abs_bound` 在本仓库任何 preset 下都是空展开（见 0.6），
  保留的 `MLKEM_INDCPA_MSGBYTES` 编译期守卫是纯预处理判断、不产生指令，
  **两者都不得**被表述为「deployable 额外带了边界检查／运行时检查」；
  它们只是**源码形态**上与另两个补丁的差别，必须如实写成源码形态差别。
- 若 M1-5a 落到情况 2（被内联）或情况 3（部分内联），产物结论的对象就包含调用者里的内联段，
  与 vulnerable / hardened 的「独立符号」证据不是同一粒度，必须写明这一差别，
  不能与另三个变体并列成一张等价的表。
- 调用者反汇编对四个变体都无条件产出，这是**判别手段**而非降级；`README.md` 必须写出
  内联判据正则 `(#|\$)0x681|[#$ ]1665\b` 在调用者反汇编上的实际 `grep -nE` 命令与命中/未命中行、
  以及同一正则对全二进制反汇编的 `grep -cE` 特异性对照计数，不能只给一句结论。
  「256 次系数循环」只作佐证（命中后人工读段并引用行号区间），**不作判据**。

### 1.6 提交

- 提交 A（代码/配置）：`docs/patches/message-value-barrier.patch`、`CMakeLists.txt`、
  `src/mlkem.c`、`tests/test_cli.sh`、`tests/test_measurement.sh`、`tests/test_analysis.sh`、
  `tests/test_vector_parser.sh`。
- 提交 B（证据/文档）：`docs/evidence/deployable/*`、`docs/mitigation.md`、
  `.gitattributes`（按 0.4 第 6 条的实测结果，可能无改动）。

---

## 2. 模块二：x86_64 指令集下的产物形态验证（明确不是时序证据）

### 2.1 目标

`docs/evidence/linux-gcc/README.md` 的结论边界里「不支持：x86_64 指令集下的产物形态」
这一条，在本机用 `docker run --platform linux/amd64`（QEMU 模拟）+ 真实 GNU GCC
**部分**闭合：只闭合产物形态与功能构建，绝不闭合时序。

### 2.2 设计决定

- 镜像：现有 `baseline-linux-gcc:ubuntu2404` 是 arm64，必须另建 amd64 镜像
  `baseline-linux-gcc-amd64:ubuntu2404`。流程沿用 `docs/evidence/linux-gcc/README.md` 的
  「基础镜像 + apt 安装工具链 + docker commit」，但 **apt 清单不照抄**：那份 README 的清单
  （`build-essential cmake git patch perl binutils`）里**既没有 `openssl` 也没有 `python3`**，
  本轮已用同源 arm64 镜像实测确认（`openssl: MISSING` / `python3: MISSING` /
  `sh: 1: openssl: not found`，容器内只有 `/usr/bin/shasum`）。而 M2-11 必须算 SHA3-256，
  `shasum` 算不出。因此清单显式钉死并加 `openssl`：

```sh
docker run --name baseline-gcc-amd64-setup --platform linux/amd64 \
    -e http_proxy=http://host.docker.internal:7890 \
    -e https_proxy=http://host.docker.internal:7890 \
    ubuntu:24.04 sh -c \
    'apt-get -qq update && apt-get -qq install -y --no-install-recommends \
     build-essential cmake git patch perl binutils openssl'
docker commit baseline-gcc-amd64-setup baseline-linux-gcc-amd64:ubuntu2404
```

  **代理写在命令里，不靠散文描述**：上面两个 `-e` 就是「apt 走
  `http_proxy=http://host.docker.internal:7890`」的全部实现，没有别的隐含设置。
  若本机 apt **不需要**代理，就去掉这两个 `-e`，并在
  `docs/evidence/linux-amd64/README.md` 写明实际执行的那条命令（逐字），
  不要两种写法都留着让读者猜。`--platform linux/amd64` 不可省。
  镜像建好后的构建与测试本身不联网。
  **apt 失败的处置**：逐字保存输出（含实际命令）到
  `docs/evidence/linux-amd64/attempt-failure.log`，按 0.5 记缺口；
  `openssl` 装不上时**不得**改用宿主算 SHA3-256 就当模块二完成——
  那是 M2-11 的备用路线，必须按 M2-11 的原文标注「走的是备用路线及原因」。
- **不装 `python3`**：`hashlib.sha3_256` 备用路线一并取消，改用 M2-11 写死的宿主备用路线。
- 源码目录**只读挂载** `-v "$PWD":/workspace:ro`；构建输出与全部证据写容器内 `/build`，
  而 `/build` 绑定到**可写的宿主目录** `/tmp/linux-amd64-build`（仓库工作区之外）。
  容器内需 `git config --global --add safe.directory /workspace`。
- **完整运行方式写死（这是证据出容器的唯一路径）**：既有先例
  `docs/evidence/linux-gcc/README.md` 的复现命令用的正是 `docker run --rm … -v "$PWD":/workspace:ro
  -v /tmp/linux-gcc-build:/build -w /build …`——**可写的宿主挂载**才是归档文件得以取出的原因；
  只沿用只读挂载那半边会让 2.4 的十余个文件无法进入仓库，`--rm` 之后也没有容器可供 `docker cp`。
  因此固定为：

```sh
mkdir -p /tmp/linux-amd64-build
docker run --rm --platform linux/amd64 \
    -v "$PWD":/workspace:ro -v /tmp/linux-amd64-build:/build -w /build \
    baseline-linux-gcc-amd64:ubuntu2404 sh -c '
      set -u
      : > /build/step-exits.txt
      git config --global --add safe.directory /workspace
      # —— 硬失败段：这几步失败则后面的证据没有对象，直接退出 ——
      cmake -S /workspace -B /build/cmake -DCMAKE_C_COMPILER=gcc \
          -DCMAKE_BUILD_TYPE=RelWithDebInfo -DBUILD_TESTING=ON \
          -DBASELINE_SANITIZERS=OFF > /build/configure.log 2>&1 || {
          echo "configure_exit=$?" >> /build/step-exits.txt; exit 1; }
      echo "configure_exit=0" >> /build/step-exits.txt
      # —— 记录退出码后继续段：失败也要把后面的证据产出来 ——
      cmake --build /build/cmake --parallel > /build/build.log 2>&1
      echo "build_exit=$?" >> /build/step-exits.txt
      grep -n "with fuzz" /build/build.log
      echo "fuzz_grep_exit=$?" >> /build/step-exits.txt
      ctest --test-dir /build/cmake -N > /build/ctest-list.log 2>&1
      echo "ctest_list_exit=$?" >> /build/step-exits.txt
      ctest --test-dir /build/cmake --output-on-failure > /build/ctest.log 2>&1
      echo "ctest_exit=$?" >> /build/step-exits.txt
      …  # M2-2、M2-3、M2-6…M2-9、M2-11 主路线的其余步骤，产物一律写 /build 下，
         # 每一步同样以 echo "<step>_exit=$?" >> /build/step-exits.txt 记录退出码
    ' 2>&1 | tee /tmp/linux-amd64-build/verification.log
```

  **失败处置写死在脚本骨架里（这是本模块能否留下失败证据的关键）**：
  - **用 `set -u` 而不是 `set -eu`**。原设计的 `set -eu` 与 M2-4「允许出现警告并如实记录」、
    M2-5「某项失败或超时就如实记录、写成缺口」直接矛盾：构建或 `ctest` 一失败脚本即终止，
    四份 encoder 反汇编、四份 caller 反汇编、`call-site-counts-amd64.txt`、四份 `.meta`、
    `binaries.sha3-256` 一份都拿不到，而失败恰是最需要证据的情形。
  - **硬失败只保留两处前置条件**：① `cmake` 配置失败（后续一切都没有对象）；
    ② 进入反汇编与摘要步骤之前，`/build/cmake/{reference,vulnerable,hardened,deployable}/measure`
    四个产物若不存在（降级后为三个），则硬失败并退出——没有产物时反汇编命令只会报错，
    留下的不是证据而是噪声。两处硬失败各自把退出码写进 `step-exits.txt` 后再 `exit 1`。
  - **其余被判定步骤一律「记录退出码后继续」**：构建、fuzz 核对、`ctest -N`、`ctest`、
    反汇编、调用点计数、摘要生成都走 `命令 > 日志 2>&1; echo "<step>_exit=$?" >> step-exits.txt`
    的形式，日志逐字落盘。
  - **反汇编、调用点计数与摘要步骤排在 `ctest` 之后，但不依赖它的退出码**：
    产物形态结论的对象是构建出来的二进制，与测试是否全绿无关；
    QEMU 下某项测试超时（M2-5 预期可能发生）不应该连带毁掉产物形态证据。
  - `README.md` 的「未能完成的项」小节（0.5 第 2 条）必须**引用 `step-exits.txt` 里的实测退出码**，
    不写「构建失败」这种无数字的描述。
  - 容器内所有证据（四份 encoder 反汇编、四份 caller 反汇编、`deployable-path-amd64-gcc.txt`、
    `call-site-counts-amd64.txt`、`cpuinfo.txt`、`compile_commands.json`、
    四份 `{variant}-smoke.meta`、`binaries.sha3-256`、容器内 `shasum -a 256` 结果、
    `step-exits.txt`、`configure.log`、`build.log`、`ctest-list.log`、`ctest.log`）
    一律写入 `/build`，即宿主 `/tmp/linux-amd64-build`。
  - `verification.log` 由宿主 `tee` 落到同一目录，内容是单次容器运行的逐字输出
    （由于各步输出已重定向进各自日志，`verification.log` 主要留下未重定向的命令输出与
    `grep` 的命中行；两者**都要**归档，不互相替代）。
  - **容器内的 `grep` 模式用双引号**（`grep -n "with fuzz"`），因为外层 `sh -c '…'` 已经占用了单引号；
    归档后在宿主对归档副本重跑时用单引号形式，见 M2-4。
  - 出容器后**由宿主**把这些文件复制进 `docs/evidence/linux-amd64/`，
    在宿主生成 `binaries.sha256`（`shasum -a 256`，对象是
    `/tmp/linux-amd64-build/cmake/<variant>/{baseline,measure}` 这些**宿主可见的构建目录路径**，
    路径逐字保留，**不把二进制副本拷进仓库**，见 0.4 第 3 条与 2.4）与 `SHA256SUMS`（不含自身），
    并在 `record-checks.txt` 做容器内／宿主两侧 `shasum -a 256` 的逐行一致性核对。
  - `/tmp` 不在仓库内，所以 M2-10 的宿主 `git status --porcelain` 为空仍然适用。
  - 如果确实要用 `docker cp`（不是默认路线），必须写明容器带 `--name baseline-gcc-amd64-run`
    且**不带** `--rm`、取完后 `docker rm`；默认路线不需要 `docker cp`。
- 证据目录 `docs/evidence/linux-amd64/`，**不动**既有 `linux-gcc` 目录。
- 时序数据处理照抄 linux-gcc 口径：采集程序只做冒烟运行（每类 50 次）以执行 Linux 代码路径，
  **只保留 `.meta` 作为平台与来源记录，CSV 与报告一律不归档，不跑 `analyze`**。

### 2.3 验收标准

- **M2-1** `README.md` 第一段就写明：这是 QEMU 模拟的 `linux/amd64`，不是真实 x86_64 主机，
  **不产出任何时序结论**。
- **M2-2** 平台事实逐字记录：`uname -a`（`uname -m` 应为 `x86_64`）、`gcc --version`、
  `cmake --version`、`patch --version`、`objdump --version`、**`openssl version`**、
  宿主 `docker version`、`docker buildx ls` 全量输出。
  **注意「是模拟」这件事不能从 `buildx ls` 的标签直接读出来**：本机实测该输出只列
  `linux/amd64 (+2), linux/arm64, linux/ppc64le, linux/s390x, (2 more)`，
  没有任何 emulated / QEMU 字样。因此「模拟」的论证必须靠这**四**件事并列：
  1. 宿主 `uname -m` = `arm64`；
  2. 容器内 `uname -m` = `x86_64`；
  3. `buildx ls` 里没有原生 amd64 节点（只有 `default` 与 `desktop-linux` 两个 docker driver 节点）；
  4. **容器内 `/proc/cpuinfo` 是宿主 ARM64 的内容**——本轮已在宿主实测
     `docker run --rm --platform linux/amd64 ubuntu:24.04 sh -c 'uname -m; head -3 /proc/cpuinfo'`
     输出 `x86_64` 后跟 `BogoMIPS: 48.00`、`Features: fp asimd … sha3 … bti afp ebf16`，
     **没有 x86 的 `model name` 行**。这比第 3 条更直接。

  README 里按这四条写，不要凭一个不存在的标签下结论。
- **M2-3** 先实测并记录 `clock_getres(CLOCK_MONOTONIC)`（用采集程序 `.meta` 的时钟字段即可，
  这是现成入口），数值照实写；无论是多少，都不改变 M2-1 的结论。
- **M2-4** 配置与完整构建：严格警告 + `-Werror` 下**记录是否零警告**。
  若我方代码出现 x86_64 GCC 特有警告，在独立 `fix:` 提交中修，然后重跑；
  若警告来自 vendor，**不改 vendor**，如实记录为发现与缺口。
- **M2-4a fuzz 门禁（与 1.2 / M1-6 同型，模块二原本缺这一道）**：模块二在容器内用
  **GNU patch 2.7.6**（`docs/evidence/linux-gcc/README.md` 实测版本）重新应用同样三到四个补丁，
  而 `cmake/PrepareVariant.cmake` 实测只用 `patch -p1 -i`、**不带 `--no-fuzz`**（本轮确认），
  所以 fuzz 会被静默接受；GNU patch 与宿主 BSD patch 的 fuzz 行为不保证相同，
  而模块二全部结论都是对打完补丁的产物做反汇编。先例 `docs/evidence/linux-gcc/README.md:17`
  反而明写了「两个补丁都无 fuzz 应用」，即原设计比先例弱。因此**命令写死，跑两次**：

```sh
# 容器内（2.2 的脚本骨架里已含这一步，模式用双引号避开外层单引号）
grep -n "with fuzz" /build/build.log; echo "exit=$?"
# 归档后在宿主对归档副本再跑一次
grep -n 'with fuzz' docs/evidence/linux-amd64/build.log; echo "exit=$?"
```

  判据：`exit=1`（无匹配）通过。`exit=0` 时**不得继续产出反汇编结论**——
  按 0.5 记缺口，把两次的逐字输出（含空结果）写入 `record-checks.txt` 与 `README.md`，
  并说明反汇编对象是带 fuzz 应用的补丁副本、形态结论因此不成立。
- **M2-5** `ctest --output-on-failure` 跑全部项（此时应为 16 项；触发 0.5 降级时为降级后的
  实测项数，预期 13），逐字记录。
  QEMU 下某项失败或超时就如实记录（含 `ctest` 超时提示原文），
  **不得为了通过而缩减样本、放宽断言或跳过测试**；把它写成缺口。
- **M2-6** 四个变体的 `baseline version` 与 `selftest`（系统随机源）在容器内成功。
- **M2-7** 四个变体编码函数的 x86_64 GCC 反汇编各一份，文件名
  `{variant}-encoder-amd64-gcc.txt`，命令
  `objdump -d --disassemble=baseline_native_poly_frommsg <binary>`。
  结论只允许写到这一层：x86_64 下 GCC 用什么指令表达那个秘密相关分支
  （与 ARM64 Clang 的 `tbz`、ARM64 GCC 的 `cmp+b.eq` 对照），
  以及 hardened / deployable 在 x86_64 产物里是否同样只剩循环边界分支。
  **「只剩循环边界分支」用与 M1-5 完全相同的四步口径判定**：逐条列出所有条件跳转
  （地址 + 助记符）→ 逐条标注归属（循环计数比较 = 循环边界；操作数链可追到 `message_bytes`
  取字节/取位 = 消息位相关）→ 标注依据（上一条影响标志位的指令及其操作数来源）写进 `README.md`
  → 归属无法判定的按 0.5 记缺口，**不得默认算作循环边界**。
  **x86_64 / GNU 侧的循环边界助记符本轮未观察**（ARM64 实测为 Apple Clang 的 `b.ne`
  与 ARM64 GCC 的 `b.ls`），按模块二实测填写，不先写死一份清单让实现时去凑。
- **M2-7a** x86_64 上同样做 M1-5a 的调用路径核对，且**必须独立重做**——GCC 13 的内联决策与
  Apple Clang 21 无关，不能拿 ARM64 的结论套用。产物：
  `deployable-path-amd64-gcc.txt`（全二进制反汇编）、
  `{variant}-caller-indcpa-enc-amd64-gcc.txt`（四个变体的调用者反汇编，**无条件产出**；
  **调用者是 `indcpa_enc`，不是 `indcpa_dec`**，见 0.6）、
  `call-site-counts-amd64.txt`。命令写死为：

```sh
objdump -d --disassemble=baseline_native_indcpa_enc <binary> \
    > {variant}-caller-indcpa-enc-amd64-gcc.txt
```

  （GCC 下符号无前导下划线；容器内先用 `objdump --help` 确认 GNU 选项拼写并把实际命令记进证据。）
  层级规则与 M1-5a 同型，只换指令助记符：先记
  `grep -c 'call.*<baseline_native_indcpa_enc>'`，计数 ≥ 1 取 `indcpa_enc`；
  计数为 0 则改取 `baseline_native_dec`（文件名相应为 `{variant}-caller-dec-amd64-gcc.txt`），
  并在 README 写明取的是哪一层。`poly_frommsg` 的调用点计数用
  `grep -c 'call.*<baseline_native_poly_frommsg>'`。
  内联判据用与 M1-5a **完全相同的正则**
  `grep -nE '(#|\$)0x681|[#$ ]1665\b'`（对调用者反汇编）与 `grep -cE`（对全二进制反汇编，
  作特异性对照）；命中即判存在内联副本，未命中且调用点计数 ≥ 1 即情况 1，
  计数为 0 即情况 2，计数 ≥ 1 且命中即情况 3；**计数为 0 且未命中**按 M1-5a 的「矛盾组合」处置。
  落到情况 2/3 时按 M1-5a 的同一处置写明结论粒度。

  **`0x681` 在 GNU objdump / x86_64 下的实际印法本轮未验证**（本机只实测了 Apple objdump 印作
  `#0x681 ; =1665`）：正则已同时覆盖 `$0x681`、`#0x681` 与十进制 `1665` 三种形式；
  若容器内实测三种都不命中而全二进制的 `grep -cE` 也为 0，说明印法超出该正则，
  **此时不得把「未命中」读成「无内联」**，必须先在 `{variant}-encoder-amd64-gcc.txt`
  里找出该常数的实际印法、把实际用的正则写进 `call-site-counts-amd64.txt` 与 README，
  再重跑判据；找不到就按 0.5 记为缺口，不硬下结论。
- **M2-8** 确认便携 C 后端：`compile_commands.json` 与构建日志中不存在
  `src/native/x86_64` 下的源文件，也没有 AVX2 相关选项；据此限定结论范围。
- **M2-9** `read_cpu_model` 的 `/proc/cpuinfo` 路径在此环境的实际行为照实记录
  （同时保存容器内 `head -20 /proc/cpuinfo` 的逐字输出）。
  本轮已在模块二开始之前于宿主观察到：`--platform linux/amd64` 容器的 `/proc/cpuinfo`
  是宿主 ARM64 字段、没有 `model name` 行，因此**预期** `read_cpu_model` 会写
  `cpu_model=unavailable`。这只是预期，**不预设**结论：M2-9 以模块二实测输出为准，
  只写观察到的结果，并明确这不能证明真实 x86_64 主机上的行为。
- **M2-10** 运行结束后在宿主执行 `git status --porcelain`，确认容器没有污染仓库（应为空）。
- **M2-11** 独立摘要核对（补齐本模块原本缺的一环）：`.meta` 实测写的是
  `executable_digest_algorithm=SHA3-256`（见 `docs/evidence/linux-gcc/reference-smoke.meta`），
  所以核对必须用**同算法的独立工具**。主路线（依赖 2.2 已把 `openssl` 装进镜像）：
  容器内 `openssl dgst -sha3-256` 对四个变体的 `baseline` 与 `measure` 产物生成
  `/build/binaries.sha3-256`，与四份 `{variant}-smoke.meta` 的 `executable_digest` 逐个对照；
  同一次容器运行里再用容器内 `shasum -a 256` 对同一批八个文件生成
  `/build/binaries.sha256-in-container`。两者的结果与对照结论写入 `record-checks.txt`。
  这是 0.4 第 5 条的要求：`executable_digest` 是被测程序自报字段（走 `/proc/self/exe`），
  不能自证。
  出容器后在**宿主**对 `/tmp/linux-amd64-build/cmake/<variant>/{baseline,measure}`
  这八个**宿主可见的构建目录产物**执行 `shasum -a 256` 生成 `binaries.sha256`
  （0.4 第 3 条要求的那一份，宿主算，路径逐字保留，**不把二进制副本拷进仓库**），
  并在 `record-checks.txt` 里与 `binaries.sha256-in-container` 逐行比对——
  这一步钉住「宿主算的和容器里算的是同一份文件」。
  **备用路线（唯一允许的替代，`python3` 不装因此不用 `hashlib`）**：若容器内 `openssl`
  仍不支持 `sha3-256`，因为 2.2 已把 `/build` 绑定到宿主 `/tmp/linux-amd64-build`，
  八个产物本来就在宿主可见，**不需要 `docker cp`**：
  1. 在**宿主**直接对 `/tmp/linux-amd64-build/cmake/{variant}/{baseline,measure}` 用
     `openssl dgst -sha3-256`（本机已实测可用）算这八个文件的摘要，
     与 `.meta` 的 `executable_digest` 逐个对照；
  2. 容器内 `shasum -a 256` 与宿主对同一批文件的 `shasum -a 256` 必须逐行一致——
     这一步只用来钉住「宿主看到的就是容器里那份」，不充当 SHA3-256 的替代；
  3. 两组数字（SHA3-256 对照 + 两侧 SHA-256 一致性）全部写入 `record-checks.txt`，
     并写明走的是备用路线及原因。

  **无论走哪条路线，都不得改用 SHA-256 与 `executable_digest` 对照后声称对上了。**
  若两条路线都不可行，按 0.5 记为缺口：在 `record-checks.txt` 与 `README.md` 写明
  「本模块未能完成 0.4 第 5 条要求的独立同算法摘要对照」及逐字失败输出。
  `.meta` 里的 `build_input_manifest_*` 段已含每个源文件的 SHA-256，一并作为来源记录归档。
  出容器后在宿主对归档文件生成 `SHA256SUMS`（`shasum -a 256`，不含自身），
  可用 `shasum -a 256 -c docs/evidence/linux-amd64/SHA256SUMS` 在仓库根目录核对
  （已实测该写法对既有 `docs/evidence/mitigation/SHA256SUMS` 通过）。
- **M2-12** `docs/validation.md` **追加**一节（不改写旧节）记录本次范围与边界。

### 2.4 证据契约

目录 `docs/evidence/linux-amd64/`。**所有文件都由容器写进 `/build`（= 宿主
`/tmp/linux-amd64-build`），出容器后由宿主复制进本目录**（路径见 2.2）：

| 文件 | 算处与说明 |
|---|---|
| `README.md` | 宿主撰写。开头写模块零提交号、M2-1 的「模拟、非时序证据」声明、0.2 表里的容器配置命令、实际执行的建镜像命令（含或不含两个 `-e` 代理参数，见 2.2）、`.meta` 的 `generator=`/`configuration=`/`compiler_flags=`/`compile_options=` 实测抄录、实际用的 `objdump` 命令与判据正则、以及「未能完成的项」小节（引用 `step-exits.txt` 的实测退出码） |
| `verification.log` | 宿主 `tee`，单次容器运行的逐字输出 |
| `step-exits.txt` | 容器内。每个被判定步骤的 `<step>_exit=<码>` 实测值（2.2 的失败处置），`README.md` 的缺口小节引用它 |
| `configure.log`、`build.log`、`ctest-list.log`、`ctest.log` | 容器内。配置、构建、`ctest -N`、`ctest --output-on-failure` 的逐字输出，各自落盘，失败也归档 |
| `compile_commands.json` | 容器内构建产生 |
| `{variant}-encoder-amd64-gcc.txt` | 四份，容器内 `objdump` |
| `{variant}-caller-indcpa-enc-amd64-gcc.txt` | 四份，容器内 `objdump`（调用者是 `indcpa_enc`；若其调用点计数为 0 则改名 `{variant}-caller-dec-amd64-gcc.txt` 并在 README 写明层级） |
| `deployable-path-amd64-gcc.txt` | 容器内全二进制反汇编 |
| `call-site-counts-amd64.txt` | 容器内。两个调用点计数、所取调用者符号、判据正则在调用者与全二进制上的命中/空结果、情况 1/2/3 结论 |
| `{variant}-smoke.meta` | 四份冒烟采集元数据，仅作平台记录，`RUN_ID=smoke-<variant>` |
| `cpuinfo.txt` | 容器内 `head -20 /proc/cpuinfo` 的逐字输出（M2-9） |
| `binaries.sha3-256` | **容器内** `openssl dgst -sha3-256`（独立同算法），对照 `.meta` 的 `executable_digest` |
| `binaries.sha256` | **宿主** `shasum -a 256`，对象是 `/tmp/linux-amd64-build/cmake/<variant>/{baseline,measure}` 八个构建目录产物，路径逐字保留；满足 0.4 第 3 条 |
| `record-checks.txt` | M2-11 的全部对照：SHA3-256 与 `executable_digest` 逐个对照、容器内 `shasum -a 256`（`binaries.sha256-in-container` 的内容）与宿主 `binaries.sha256` 的逐行一致性核对、所走路线及原因、M2-4a 两次 fuzz 核对的逐字输出、0.4 第 6 条的 `git diff --cached --check` 输出 |
| `SHA256SUMS` | 宿主生成，覆盖本目录除自身以外的全部文件 |

**八个被测产物的副本不归档进本目录（择一已写死：不归档）**。理由是实测的三处先例与另三个模块
都不这样做：`docs/evidence/mitigation/binaries.sha256` 七行全是构建目录路径、目录内无二进制副本；
容器先例 `docs/evidence/linux-gcc/` 既无 `binaries.sha256` 也无 `record-checks.txt`，更无副本；
`docs/evidence/` 下目前没有任何二进制文件。模块一、三、四的 `binaries.sha256` 也都记录
`build/<dir>/…` 路径，若只有模块二改算归档副本，四个目录的清单只在**文件名**层面一致、
**摘要对象**却不一致（一个算副本、三个算构建目录文件），反而更难核对；
且单个 `measure` 实测 129KB，八个副本约 1MB，进 git 后按 0.3 不可删。
2.2 已把 `/build` 绑定到宿主 `/tmp/linux-amd64-build`，八个产物在宿主直接可见，
**不需要拷进仓库才有摘要对象**。`record-checks.txt` 必须写明：
「摘要对象是容器写出的、宿主可见的构建目录产物（`/tmp/linux-amd64-build/cmake/…`），
未拷入仓库；容器内 `shasum -a 256`（`binaries.sha256-in-container`）与这份 `binaries.sha256`
逐行一致，两侧钉住的是同一份文件。」
**不含** 二进制副本、不含 CSV、不含 `.report`、不含任何统计结论。

### 2.5 诚实性边界

- 模拟执行时间在任何意义上都不是时序证据，连「量级参考」都不写。
- 本模块**不改变** README 与 acceptance 中「仍未执行真实 x86_64 Linux 主机时序实测」这一条。
- 结论限于：便携 C 后端、GCC 13.x、x86_64 指令集、本次构建的这些地址、
  以及 0.2 表里写死的那条容器配置命令（生成器为容器内默认的 Unix Makefiles，
  与模块一、模块三的 Ninja 不同，地址不跨构建复用）。

### 2.6 提交

单个 `docs:` 提交：`docs/evidence/linux-amd64/*`、`docs/validation.md`、
`.gitattributes`（按 0.4 第 6 条的实测结果）。
若 M2-4 需要修我方代码，先出独立 `fix:` 提交并重跑全部容器步骤。

---

## 3. 模块三：诚实处理预注册主比较的失败 + 多种子稳健性

### 3.1 需要如实陈述的事实

`docs/statistics.md` 把 `message-zero:message-ones` 预先规定为 `primary=yes` 主比较
（分支方向假设）。0.6 的表格是逐份读取归档报告得到的实测值，三次缺陷版采集为：

| 采集 | 主比较均值差 | `rank_z` | `rank_p` | 判定 | 同族显著数 |
|---|---|---|---|---|---|
| `statistics/vulnerable` | −83.2ns | −4.0408 | 5.33e-05 | significant | 7 / 10 |
| `statistics/vulnerable-replication` | −55.8ns | −4.8309 | 1.36e-06 | significant | 7 / 10 |
| `mitigation/vulnerable` | −84.2ns | −3.8338 | 1.26e-04 | **not_significant** | 6 / 10 |

据此可以说、也只能说：

1. **符号是稳定的**，三次都是负（恒定类更快）。**不能**写成「方向跨运行不稳定」——
   归档数据不支持这个说法，写了就是无据升级。
2. **量级小**：主比较 |均值差| 为 55.8–84.2ns，而同族「恒定类 vs 变化类」的主效应按**各轮自比**
   分别是：`statistics/` 那一轮均值差 711–800ns、效应量 0.819–0.844、|z| 62–67
   （`docs/statistics.md:72`）；`mitigation/vulnerable.report` 那一轮均值差 690–824ns、
   效应量 0.776–0.795、|z| 52.6–55.9。即主比较在**各自所在的采集轮次内**都只有主效应的
   约十分之一量级。**不得**把 55.8–84.2 这个跨两轮的范围去除以只描述某一轮的主效应范围。
3. **显著性判定不稳定**：同一预注册阈值下三次分别是 显著 / 显著 / 不显著，
   p 在 1.36e-06 与 1.26e-04 之间跨越 1e-4 阈值。
4. 效应量始终贴近 0.5（0.479859 / 0.482959 / 0.481158），即分布几乎重合。

上层协调者用**新种子 777、每版 10000 条**（即 `samples_per_category=2000`）复核时，
三个变体的这个主比较全部不显著：**p = 0.923（reference）/ 0.844（vulnerable）/ 0.516（hardened）**。

结论：第一轮预注册的主假设**在预先规定的阈值下没有稳定成立**；稳定的效应在
「消息位方向恒定」与「方向变化」之间，即分支可预测性。

**种子 777 复核数据不可追溯，这一点已经查实，不是待确认项**：全工作树搜索
`test_seed=777` 零命中，`runs/` 只有 `test_seed=42` 的材料且被 `.gitignore` 排除（见 0.6）。
因此处理办法固定为两条，缺一不可：

- 上面那三个 777 的 p 值在文档里**必须标注为「未归档、无法从本仓库复现的口头复核结果」**，
  只作为提出第二轮假设的动机记录，不作为证据引用，不进汇总表的证据列。
- 模块三**另外重跑一次种子 777 的动机复采**（四个变体，`samples_per_category=2000`，
  与原复核同参数），`RUN_ID=motivation777-<variant>`，
  归档为 `motivation-seed777-{variant}.{csv,meta,report,groups.report}`
  （**四件**，含第二轮报告，与 M3-4「两份报告都归档」和 3.5 的清单一致）。
  这次重采是**可复现的替代材料**，但：
  - 它**不属于** 3.2 的预注册稳健性集合（777 是已用过的种子，已在排除清单里），
    汇总表必须把它单独列在预注册五个种子之外，并标注 `prespecified=no`；
  - 它的数字**不等于**原复核的数字（不同时间、不同机器负载），文档必须把「重采值」与
    「上面引用的原复核值」并列写出、分别标注，**不得**用重采值替换原值假装原值已被证实；
  - 若重采结果与原复核相反（例如某变体判显著），照实记录为「动机复采与原口头复核不一致」，
    并说明这不改变第二轮预注册的内容——预注册已在本文件固定，不因动机材料变动而调整。

处理原则：
- 第一轮预注册内容与结果**原样保留**。不修改 `src/analyze.c` 中已有的比较族定义，
  不改写 `docs/statistics.md` 已记录的第一轮结论。
- 新章节明确写出「第一轮预注册主比较未能在预定阈值下稳定成立」，并附上上表的逐份数字、
  777 原复核的三个 p 值（标注未归档）与动机复采的实测值。

### 3.2 第二轮预注册（假设文本由 0.1 的模块零提交入库）

**标注：这是第二轮预注册，是在看过第一轮数据之后提出的。不这样标注就是 p-hacking。**
**同时标注：模块零提交只给出本仓库本地历史内的顺序，没有第三方时间戳**——
完整口径见篇首「预注册的性质与其边界」与 3.6，引用该提交时不得用「时间凭证」一类措辞。

- 假设 H2：解密消息位**方向恒定类**（`message-zero`、`message-ones`）与**方向变化类**
  （`valid`、`bit-flipped`、`random`）之间，完整解封装耗时分布存在差异。
- 统计形式：把两组各自的逐次原始值**合并成两个样本**（每次采集下 n1 = 2×5000 = 10000，
  n2 = 3×5000 = 15000），对这两个样本做**并列修正、带连续性校正的 Mann-Whitney U
  正态近似**；判定只依据它。辅助报告 Welch t 与 Welch–Satterthwaite 自由度。
  分位点按最近秩取值、不插值、不删离群值、不裁尾（与第一轮完全相同的口径）。
- 显著性水平：`alpha_family = 0.001`。本族只有 **1 个**预先规定的比较，
  因此 `comparison_count=1`、`multiplicity_correction=none_single_prespecified_comparison`、
  `alpha_per_comparison=0.001`。
- **阈值严格度差异必须披露（否则等于无据升级）**：第一轮源码实测为
  `ANALYSIS_FAMILY_ALPHA=0.001` 配 `ANALYSIS_COMPARISON_COUNT=10`，即
  `alpha_per_comparison=1e-4`——这正是 `mitigation/vulnerable.report` 的
  `rank_p=0.000126165` 被判 `not_significant` 的原因。第二轮 `alpha_per_comparison=1e-3`
  是第一轮主比较阈值的 **10 倍宽**。因此「第一轮主比较在 1e-4 下未稳定成立」与
  「第二轮在 1e-3 下成立」**不是同一严格度的陈述**；汇总表与报告必须并列写出两个阈值，
  **不得**暗示第二轮更强地证实了第一轮的同一假设。
  为避免事后挑阈值，M3-5 的汇总表对第二轮同时给出「按 1e-3 判定」与「若按 1e-4 判定」两列，
  后者作为**此处预先写下**的附带读数。
- 评价单位：每个 (变体, 种子) 的采集**各自独立评价**，不做跨运行池化检验；
  稳健性结论是「同一模式在多少个独立种子上重现」，不是一个合并 p 值。
- 预先写下的方向性期待（来自第一轮已看到的数据，故属第二轮的一部分）：
  - vulnerable：五个种子**全部**判 `significant`，且 `mean_difference_ns ≤ −300`
    （恒定类更快）、`effect_size_first_greater ≤ 0.40`。
  - reference / hardened / deployable：五个种子**全部**判 `not_significant`，
    且 `|mean_difference_ns| ≤ 150`。
  - 任何偏离都按偏离报告，写成「预期未成立」，**不允许**丢弃种子、改阈值或换种子重来。
    采集中断可以用**同一种子**重跑，两次都归档并说明。
- 公开种子（此前从未使用过，顺序固定，不得增删替换）：

```text
31337  90210  20261111  8675309  141421356
```

  已用过、因此排除的种子：42、777、20260926、20260930。
  3.1 的动机复采仍然用 777，这不违反预注册：它被显式标注 `prespecified=no`、
  排在汇总表的预注册区之外、且不参与「五个种子」的任何计数；预注册集合就是上面五个，不增不减。
- 样本量：每类 5000 次、每版 25000 条（`docs/statistics.md` 既有口径），
  变体 = reference / vulnerable / hardened / deployable，共 4 × 5 = **20 次采集**。
  `RUN_ID` 固定为 `multiseed-<variant>-<seed>`（如 `multiseed-vulnerable-31337`），
  构建目录 `build/multiseed`。
- **样本量的决定时点写死（不允许看着数据缩样）**：预注册集合的 `samples_per_category`
  固定为 **5000**，且必须在**第一次预注册采集开始之前**确定。若必须改动，则 20 次采集
  **全部按新值重做**，旧值与放弃原因作为偏离一并记录；预注册集合内**不允许**混用不同样本量
  （否则 M3-5 的「五个种子全部如何」失去可比性）。已采集的部分归档到明确非预注册的文件名下
  （`aborted-<variant>-seed<SEED>.*`），**不进**汇总表的预注册区，也不参与任何计数。
  若最终确实以更小样本量完成，必须同时说明正态近似在小样本下偏乐观、以及这对结论强度的影响。

### 3.3 设计决定：新增独立程序而不是改动第一轮族

第二轮用**独立程序** `analyze_groups`（源码 `src/analyze_groups.c`，产物
`build/multiseed/analyze_groups`，用法 `analyze_groups CSV_FILE REPORT_FILE`）实现，
理由：① 第一轮报告保持逐字可复现（由 `analysis_round1_replay` 强制）；
② 避免任何「事后往原族里塞比较」的观感；③ 第二轮是单比较族，校正记账与第一轮不同；
④ 与仓库「单一用途固定检验工具」的风格一致。

为避免把 300 行 CSV 校验逻辑复制一份，把**共用部分**从 `src/analyze.c` 抽到
`src/timing_statistics.c` + `include/timing_statistics.h`：记录结构、CSV 加载与严格校验、
SHA3-256 摘要、序列视图与分位点/矩、Mann-Whitney/Welch 比较与判定标签，
外加**两个无状态排序入口**（见下）。
`src/analyze.c` 只保留第一轮比较族与报告写出，**比较族定义一个字符都不改**。
抽取的正确性由 M3-2 的逐字重放测试证明。

**抽出的两个排序入口（名字与语义写死，都不持有状态、都可单独测试）**：

| 入口 | 语义 | 谁调用 |
|---|---|---|
| `sort_records_by_category_then_duration(records, record_count)` | 对**整份**记录数组按「先类别索引、后耗时」排序，即现 `src/analyze.c` 的 `compare_measurement_record`（实测在 `src/analyze.c:81`）所定义的序 | `src/analyze.c` 的 `main`（替换现在那行 `qsort`，**行为逐字不变**，由 M3-2 兜住）；`analyze_groups` 的 `main`（第 2 步） |
| `sort_range_by_duration(records, record_count)` | 对**给定的一段连续区间**只按耗时排序，不看类别 | 只有 `analyze_groups` 的 `main` 调用（第 5 步，对两个组区间各调一次） |

`compare_measurement_record` 随第一个入口一起移入 `src/timing_statistics.c`。
`analyze_groups` 必须**自己依次调用这两个入口**，不存在「加载即已排好序」的隐含前提。

CMake 接入照 `analyze` 的现有写法：`add_executable(analyze_groups src/analyze_groups.c
src/timing_statistics.c)`，链接 `mlkem_reference` 与 `MATH_LIBRARY`，
`INTERPROCEDURAL_OPTIMIZATION FALSE`，`RUNTIME_OUTPUT_DIRECTORY` 为构建根（与 `analyze` 同级）；
`src/timing_statistics.c` 同时加入 `analyze` 的源码列表，不新建库目标。

两个新 CTest 的注册写死如下（`SH_EXECUTABLE`、`output_root` 都是 `CMakeLists.txt` 里的现成变量）：

```cmake
add_test(NAME analysis_groups
         COMMAND "${SH_EXECUTABLE}" "${CMAKE_CURRENT_SOURCE_DIR}/tests/test_analysis_groups.sh"
                 "${output_root}"
)
add_test(NAME analysis_round1_replay
         COMMAND
             "${SH_EXECUTABLE}"
             "${CMAKE_CURRENT_SOURCE_DIR}/tests/test_analysis_round1_replay.sh" "${output_root}"
)
set_tests_properties(
    analysis_round1_replay PROPERTIES WORKING_DIRECTORY "${CMAKE_CURRENT_SOURCE_DIR}"
)
```

`WORKING_DIRECTORY` 指向源码根目录，与既有 `vector_integrity` 测试同一写法（已核对
`CMakeLists.txt` 中该测试正是 `set_tests_properties(... WORKING_DIRECTORY
"${CMAKE_CURRENT_SOURCE_DIR}")`）。这一条是**必需**的，不是风格选择：归档报告的
`csv_path` 是仓库相对路径（实测 `csv_path=docs/evidence/mitigation/hardened.csv`），
只有从仓库根目录、用完全相同的相对路径调用 `analyze`，重放报告才会逐字一致。

`tests/test_analysis_round1_replay.sh` 的落点规则同样写死：`src/analyze.c:649` 用
`fopen(argument_values[2], "wx")`，目标**必须是新文件**，否则第二次 `ctest` 直接失败。
因此脚本把重放报告写到 `$1/round1-replay-<name>.report`（`$1` 即传入的 `output_root`，
即构建目录），进入时先对这些路径 `rm -f`；**不得**向 `docs/evidence/` 下任何路径写入
（那是 0.3 的只读封存范围）。
**被调用的程序路径固定为 `$1/analyze`**（与其余测试脚本的惯例一致；`analyze` 的
`RUNTIME_OUTPUT_DIRECTORY` 实测就是构建根，所以 `output_root` 下就是它）。
**用例固定为两份，数量本身就是判据**：

| 归档 CSV | 重放报告 | 对照的归档报告 |
|---|---|---|
| `docs/evidence/statistics/vulnerable.csv` | `$1/round1-replay-statistics-vulnerable.report` | `docs/evidence/statistics/vulnerable.report` |
| `docs/evidence/mitigation/hardened.csv` | `$1/round1-replay-mitigation-hardened.report` | `docs/evidence/mitigation/hardened.report` |

两次重放、两次 `cmp`（都在屏蔽 `welch_p=` / `rank_p=` 之后），**两次都必须通过**，
任一失败即该测试失败；脚本不得只跑一份就返回成功。

分组在实现上是连续区间：`enum input_category` 顺序为
`VALID, BIT_FLIPPED, RANDOM, MESSAGE_ZERO, MESSAGE_ONES`，**在整份数组按类别索引排序之后**
方向变化类是 0–2、方向恒定类是 3–4，两组各自连续，此时才只需对各组区间按耗时再排序一次。
**「排序之后」这个前提不是自动成立的**，见下一段。

**这里有两个必须由 `analyze_groups` 自己守住的不变式，先把实测事实写清**：

1. **加载函数不排序，排序在 `main` 里。** 实测：`src/analyze.c` 的 `load_measurement_set`
   （自 `:346` 起）只做逐行校验与 `append_record`，全程不排序；排序发生在 `main`——
   `src/analyze.c:647` 的
   `qsort(set.records, set.record_count, sizeof(*set.records), compare_measurement_record)`，
   **之后**才是 `:648` 的 `build_series` 按类别取连续区间。
   CSV 文件本身的类别是乱序的（`docs/evidence/mitigation/reference.csv` 前四条数据行实测为
   `message-zero, valid, message-zero, message-zero`）。
   **所以 `analyze_groups` 若只调用加载函数就按下标切两段，切到的是乱序数组的前 N 条与后 M 条，
   和类别毫无关系**——它仍会算出格式合法的分位点与 Mann-Whitney p 值，没有任何断言会失败，
   M3-1 原有的「完全分离」「分布相同」两个合成场景对类别归属不敏感也抓不到，
   结果是第二轮预注册的唯一判定统计量在真实数据上算错而 CTest 全绿。这一步不能省。
2. **组区间重排是原地改写共享数组。** `struct sample_series` 只持有指向 `set->records` 的
   区间视图（`records` 指针 + `sample_count`），不拥有数据。所以「对组区间按耗时重排」
   会破坏组内原本的类别分段，使任何**随后**按类别取视图的操作失效。

归属明确：

- 两个不变式都由 `analyze_groups` 的 `main` 流程负责，**不**下沉到 `timing_statistics.c`
  ——抽出的两个排序入口都只做自己那一件事、保持无状态、可单独测试；
- **`analyze_groups` 的 `main` 固定为六步，缺一不可，顺序不得调整**：
  1. 加载并校验（`load_measurement_set`）；
  2. **对整份 `set->records` 调用 `sort_records_by_category_then_duration`**
     ——这一步是第 3 步能按下标切组的唯一前提；
  3. 校验五类齐全、每类样本数相等、每组样本数 ≥ 2；
  4. 记录两组的 `count` 与各自区间的起止下标；
  5. **才**对这两个区间各调用一次 `sort_range_by_duration`；
  6. 计算分位点/矩与比较，写报告。

  即 `analyze_groups` **不计算任何按类别的序列**，第 5 步之后不再按类别取视图，
  因此第 5 步的原地重排不会影响别的东西；
- `src/analyze.c` 的 `main` 把现在那行 `qsort` 换成
  `sort_records_by_category_then_duration(set.records, set.record_count)`，
  **排序语义与调用时点一个字节都不变**，第一轮行为因此不变（由 M3-2 逐字重放兜住）；
  `src/analyze.c` **不调用** `sort_range_by_duration`。

`enum input_category` 的取值顺序是本设计的硬依赖。因此 `analyze_groups.c` 里用
`_Static_assert` 把 `INPUT_VALID == 0 … INPUT_MESSAGE_ONES == 4` 与
`INPUT_CATEGORY_COUNT == 5` 钉住：将来有人往 `include/inputs.h` 中间插入类别时编译期就失败，
而不是静默算出错的分组。

`analyze_groups` 的输入校验（在第一轮全部校验之上追加）：五类必须全部出现、
**每类样本数相等**、每组样本数 ≥ 2；不满足即退出码 1 且不创建报告。
退出码：0 成功、2 参数个数错、1 读取/校验/写入失败。报告路径必须是新文件（`fopen "wx"`）。

报告为 `key=value` 行，固定包含（字段名即契约）：

```text
analysis_tool=fixed_prespecified_group_test
analysis_version=1
analysis_round=2
prespecified_after_round1_data=yes
hypothesis=direction_constant_vs_direction_varying
csv_path=… csv_digest_algorithm=SHA3-256 csv_digest=<64 hex>
run_id=… implementation=… record_count=… time_unit=ns
group=direction-constant members=message-zero,message-ones count=… min=… p25=… median=… p75=… p99=… max=… mean=… stddev=… distinct_values=…
group=direction-varying members=valid,bit-flipped,random count=… （同上字段）
location_test=welch_t_normal_approximation
rank_test=mann_whitney_u_tie_corrected_normal_approximation
quantile_rule=nearest_rank_no_interpolation
outlier_removal=none
alpha_family=0.001000
comparison_count=1
multiplicity_correction=none_single_prespecified_comparison
alpha_per_comparison=0.00100000
round1_alpha_per_comparison_for_reference=0.00010000
comparison=direction-constant:direction-varying primary=yes n1=… n2=… median_difference_ns=… mean_difference_ns=… welch_t=… welch_df=… welch_p=… rank_u1=… rank_z=… rank_p=… effect_size_first_greater=… result=…
significant_comparison_count=…
note=statistical_difference_only_no_exploitability_claim
sample_independence_note=direction_constant_group_reuses_two_fixed_ciphertexts_under_one_key
```

`prespecified_after_round1_data=yes` 与 `sample_independence_note` 是**机器可读的诚实性字段**，
不得删除。`round1_alpha_per_comparison_for_reference=0.00010000` 是常量字面量
（不参与本轮判定，只把第一轮主比较的阈值并列写在同一份报告里，落实 3.2 的阈值披露要求），
同样不得删除。

`result=` **复用 `src/analyze.c` 的 `comparison_result_label` 四个标签，不新造标签**：
`insufficient_samples`（`comparison_status != 0`）/ `degenerate_no_variation`
（`!has_rank_test`，即组内无变化）/ `significant`（`rank_p < alpha_per_comparison`）/
`not_significant`。该函数随共用部分一起抽到 `src/timing_statistics.c`，两个程序调用同一份实现，
只是传入各自的 `alpha_per_comparison`（第一轮 1e-4、第二轮 1e-3）。
与之配套的字段存在性规则也照抄第一轮（`write_comparison_line` 的实测行为）：
`insufficient_samples` 时不写差值与检验字段；`degenerate_no_variation` 时写
`median_difference_ns` / `mean_difference_ns`，但**不写** `rank_u1` / `rank_z` / `rank_p` /
`effect_size_first_greater`。M3-5 的派生列必须能处理 `rank_p=` 缺失的情形（见 M3-5）。

### 3.4 验收标准

- **M3-1** 新 CTest `analysis_groups`（`tests/test_analysis_groups.sh`）用**解析上可手算**的
  合成数据检查，预期值不由被测程序产生：
  - 完全分离：恒定组每类 10 个 1000ns（n1=20），变化组每类 10 个 2000ns（n2=30）
    → **只断言** `rank_u1=0.0`、`effect_size_first_greater=0.000000`、`rank_z` 为负、
    `result=significant`。**不断言具体的 `rank_z` / `rank_p` 数值**：该场景两个并列块使
    并列修正生效（见 6.5 的正确手算 σ=42.857、z=−6.9884、p≈2.8e-12），
    把浮点数值写成逐字断言既脆弱又容易照抄错。
  - 分布相同：五类各 10 个、每类 5 个 1000ns + 5 个 2000ns
    → n1=20、n2=30，`rank_u1` 恰为 n1·n2/2 = 300.0（150 个胜出对 + 300 个并列对的一半），
    连续性校正后 `rank_z=0.0000`、`rank_p=1`、`effect_size_first_greater=0.500000`、判不显著。
    （此处的 `rank_z` / `rank_p` 可以断言：`|300−300| − 0.5 < 0` 被实现钳到 0，是精确值。）
  - **类别乱序输入（这一条专门捕获「漏掉整份排序」这个错误，不可省）**：
    合成 CSV 的**行序按类别交替写出**（例如 `valid, message-zero, bit-flipped, message-ones,
    random, valid, …`，只要不是按类别分段即可；真实 CSV 本来就是乱序的，
    `docs/evidence/mitigation/reference.csv` 前四条数据行实测为
    `message-zero, valid, message-zero, message-zero`），取值仍为
    **方向恒定类每类 10 个全 1000ns、方向变化类每类 10 个全 2000ns**。
    断言：`count=20`（恒定组）、`count=30`（变化组）、`rank_u1=0.0`、
    `effect_size_first_greater=0.000000`、`rank_z` 为负、`result=significant`。
    **若 `analyze_groups` 漏掉 3.3 第 2 步的整份排序，这一条必然失败**
    （切到的是乱序数组的前 20 条与后 30 条，两组都混有 1000ns 与 2000ns，
    `rank_u1` 不会是 0、效应量不会是 0.000000）；而上面「完全分离」那一条
    若按类别分段写出 CSV 就抓不到这个错误，所以两条都要有。
  - 全部取值相同 → `degenerate_no_variation`，不给显著结论。
  - 拒绝场景：缺一个类别、各类数量不等、报告文件已存在、参数个数错（退出码 2）、
    以及第一轮已覆盖的畸形 CSV 抽样若干（表头、负数、`0`、溢出、单位、尾随字段、
    样本序号、未知类别、跨行 run_id/implementation、未以换行结束）。
  - 真实数据全流程：四个变体各小样本（每类 50）跑通，报告含两组与一个比较。
    （触发 0.5 降级时按三个变体执行，见 0.5 第 4 步。）
- **M3-2** 新 CTest `analysis_round1_replay`：在**仓库根目录**（由 `WORKING_DIRECTORY` 保证，
  注册写法见 3.3）对**已归档**的
  `docs/evidence/statistics/vulnerable.csv` 与 `docs/evidence/mitigation/hardened.csv`
  重新运行 `analyze`，重放报告写到构建目录下的 `round1-replay-<name>.report`（先 `rm -f`
  以避开 `fopen "wx"`），再与归档 `.report` 比较。比较时用 `sed` 把 `welch_p=` 与 `rank_p=`
  两个字段的值置空后再 `cmp`，理由写在脚本注释里：`erfc` 属 libm 实现，
  跨平台不保证逐位一致；其余全部字段（含 `rank_u1`、`rank_z`、`welch_t`、
  `effect_size_first_greater`、各 `category=` 行、`result=` 标签、`csv_digest`）必须逐字相同。
  该测试是「第一轮结果未被动过」的机器化证明。
  设计时已在本机实测两轮：撰写阶段用当前 `build/cmake/analyze`、评审阶段另用
  `build/cmake-sanitize/analyze`（`-O1 -g` + ASan/UBSan），对这两份归档 CSV 共四次重放，
  `cmp` **全部逐字节相同**（无需屏蔽 `welch_p`/`rank_p`）。所以屏蔽只是为跨 libm 平台
  （模块二的容器）留余量，余量比原设计声称的还宽松，不是为掩盖差异；
  若屏蔽后仍不相同，说明抽取改变了第一轮行为，必须回退重做。
- **M3-3** `ctest -N` 实测项数为 18（预期），`ctest --preset baseline` 与
  `ctest --preset sanitize` 全通过；format-check 通过。
  （触发 0.5 降级时改写为降级后实测项数，预期 15，判据为「实测 N 项全部通过」并注明原因。）
- **M3-4** 按 3.2 的种子与样本量完成 20 次采集，每份 CSV 同时跑第一轮 `analyze`
  与第二轮 `analyze_groups`，两份报告都归档。第一轮族在新种子上的结果（含
  `message-zero:message-ones` 的 p 值）逐种子列出，作为「第一轮预注册失败」的多种子证据。
  另完成 3.1 要求的 4 次种子 777 动机复采（`samples_per_category=2000`），同样两份报告都归档。
- **M3-5** 多种子汇总表（每个变体 × 每个种子一行）：第一轮显著数（x/10）、
  第一轮主比较 p、**第一轮阈值 `alpha_per_comparison=1e-4`（常量列，提醒严格度）**、
  第二轮 `result`（按 `alpha_per_comparison=1e-3` 判定）、
  **第二轮「若按 1e-4 判定」的结果（预先写下的附带读数，见 3.2）**、
  `mean_difference_ns`、`effect_size_first_greater`、`rank_z`、类别均值极差，
  外加一列 `prespecified`（五个新种子为 `yes`，种子 777 动机复采为 `no`）。
  两个阈值必须并列出现在表头与表下说明里，不得只写「第二轮显著」。
  动机复采的 4 行必须排在预注册 20 行之后并用分隔标注，
  **不参与**「五个种子全部如何」的判定计数。
  汇总表由 `grep`/`awk` 从报告生成，生成命令记入证据 README。
  **制表符表头与列序写死**（汇总表是模块三对外的主结论载体，列名不定会让
  「若按 1e-4 判定」这类派生列无法核对）。下面每个 `\t` 代表**一个字面制表符**
  （本设计文件按 `.editorconfig` 不写字面制表符，故在此用转义形式表示；
  实际写入 `multiseed-summary.tsv` 的是制表符本身）：

```text
implementation\tseed\tprespecified\tround1_significant_count\tround1_primary_rank_p\tround1_alpha_per_comparison\tround2_result\tround2_rank_p\tround2_significant_at_1e-4\tmean_difference_ns\teffect_size_first_greater\trank_z\tcategory_mean_range_ns
```

  列语义补充：`round1_alpha_per_comparison` 恒为 `0.00010000`（常量列，只为提醒严格度）；
  `round2_significant_at_1e-4` 取值域为 `yes|no|na`；
  动机复采四行 `prespecified=no` 且排在表的**最后**。
  **「若按 1e-4 判定」列的规则写死**（否则那一列没有生成方式）：从 `.groups.report` 的
  `comparison=` 行取 `rank_p=` 字段，`rank_p < 1e-4` → `significant_at_1e-4=yes`，
  否则 `no`；该列**只改判定阈值，不重算任何统计量**。生成命令固定为

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

  `rank_p=` 缺失（`result=degenerate_no_variation` 或 `insufficient_samples`，见 3.3 的
  字段存在性规则）时该列写 `na`，**不得**当成 `no` 混进计数。
  该命令与其逐份输出记入 `docs/evidence/statistics-multiseed/README.md`。
- **M3-6** 明确回答 `docs/mitigation.md` 里「防护版残差随运行波动（本次最大 |z|=2.15，
  此前一次 |z| ≤ 3.61）」的稳定性问题：给出 hardened 与 deployable 在五个新种子上的
  最大 |z| 与均值差范围。
- **M3-7** 原始值全部保留，不删普通长尾；类别乱序可复现（同种子同样本数下各变体顺序相同，
  用 `cut` + `cmp` 逐字节确认）；时钟与单位记录在 `.meta`。
- **M3-8** 独立摘要核对：每份 CSV 的 `openssl dgst -sha3-256` 与其两份报告的 `csv_digest`
  一致；每份 `.meta` 的 `executable_digest` 与对应 `measure` 产物的
  **`openssl dgst -sha3-256`** 摘要一致（算法必须写出来：`.meta` 实测
  `executable_digest_algorithm=SHA3-256`，拿 `shasum -a 256` 的值去对照是算法不同、
  永远对不上，见 M1-6 与 M2-11）；
  目录级 `SHA256SUMS` 可用 `shasum -a 256 -c` 通过。
- **M3-9** `docs/statistics.md` **追加**章节（不改写旧结论），内容顺序：
  第一轮预注册主比较未在预定阈值下稳定成立的事实与数字（3.1 的表 + 777 原复核标注为未归档
  + 动机复采实测值）→ 第二轮预注册的完整形式与「看过第一轮数据之后提出」的标注
  → 五个新种子的结果 → 边界。
- **M3-10 正面更正既有措辞（必做，否则等于默认了旧表述）**：两处旧措辞已逐字核对：
  - `docs/evidence/mitigation/README.md:47`：「…略高于 1e-4 阈值因此判不显著；
    该项在不同采集之间反复越过阈值，属于小幅不稳定的**次级差异**。」
  - `docs/statistics.md:84`（在「机制解释与其边界」一节内）：「…而不是两条分支本身代价不同；
    **主比较只呈现次级差异**，也符合这一解释。」

  两处的处置**不同**，依据也不同：

  1. `docs/evidence/mitigation/README.md` 在 0.3 的只读封存范围内，**不得回去编辑**。
     它的更正只在 `docs/statistics.md` 的新章节里给出，并在新章节写明
     「旧文件因只读约定原样保留，以本章节为准」。
  2. `docs/statistics.md` **不在** 0.3 的只读范围内（0.3 只覆盖 `vendor/`、`tests/vectors/`、
     `docs/evidence/` 下已封存目录），而且 M3-9 正要往它里面追加章节。因此这里的约束依据是
     本仓库「**不改写既有结论、只追加**」的工程约定，**不引 0.3**。
     具体做法：第 84 行那句原文**保持不动**，紧随该段落之后**新增**一句交叉引用
     （这是追加，不是改写），形如：

     > （更正见本文件第 N 节：该主比较是预注册的 `primary=yes` 比较，在预定阈值 1e-4 下
     > 未稳定成立；此处「次级差异」的措辞不准确。）

     `N` 填 M3-9 追加章节的实际序号。这一步是必需的：只把更正写在文末新章节里，
     读到第 84 行那段的人不会知道它已被更正，那就不成立「正面更正」。

     **行号引用的处理（本文件与 `docs/statistics.md` 都有多处 `:84` 引用）**：
     交叉引用句插在**该段落之后**（该段落实测为第 80–85 行，第 85 行是
     「m' 由私钥参与的解密产生，因此分支条件具有秘密依赖。」），M3-9 的新章节**追加在文件末尾**，
     因此第 84 行本身的行号**预期不变**。但这只是预期，必须机械核对：

```sh
grep -n '主比较只呈现次级差异' docs/statistics.md   # 插入前，实测应为 84
# …插入交叉引用句、追加 M3-9 新章节…
grep -n '主比较只呈现次级差异' docs/statistics.md   # 插入后
```

     两次输出逐字写入 `docs/evidence/statistics-multiseed/README.md`。
     新章节与证据 README 引用该措辞时，**以原句文本为主、行号为辅**，并写出
     「插入前 84 / 插入后 <实测>」两个数字。
     **若实测行号发生了变化，只更新 `docs/statistics.md` 的新章节与
     `docs/evidence/statistics-multiseed/README.md` 这两处**，并在那里写明
     「本设计文件引用的 84 是模块零时点的实测值，插入后实测为 `<N>`」。
     **不得回头修改本设计文件的行号引用**——0.1 的硬约束规定模块零提交之后本文件冻结，
     而本文件正是预注册文本本身；为了消掉一个过期行号去改它，会把
     「模块零提交号 ↔ 预注册文本」这层绑定解开，代价远大于留一个已标注时点的旧行号。

  新章节里还必须做到三点：① 逐字引用上述两处旧措辞并给出文件与行号定位；
  ② 说明为什么它不够准确——「次级差异」是在主假设已被预注册为 `primary=yes` 的前提下，
  对一个**预注册失败**的结果做的降级描述，读者容易以为预注册按计划成立了；
  ③ 写明更正后的口径（3.1 的四条）。

### 3.5 证据契约

目录 `docs/evidence/statistics-multiseed/`：

| 文件 | 内容 |
|---|---|
| `README.md` | 平台/**模块零提交号 + 篇首「预注册的性质与其边界」定型文字全文**/源码提交/干净状态、种子清单、第二轮预注册摘要与标注、两个阈值（1e-4 与 1e-3）的并列说明、**0.2 表里 `build/multiseed` 的配置命令与 `.meta` 的 `generator=`/`configuration=`/`compiler_flags=`/`compile_options=` 实测抄录**、M3-5 的汇总表与「若按 1e-4 判定」列的生成命令、M3-10 的两次 `grep -n` 输出、`du -sh` 实测体积、结论与边界 |
| `configure.log`、`build.log`、`ctest.log`、`compile_commands.json` | 采集所用构建（`build/multiseed`：Ninja / RelWithDebInfo）的逐字记录（含配置命令与 `ctest -N`） |
| `sanitize-ctest.log` | **来自 `build/cmake-sanitize`**（`sanitize` preset：`Unix Makefiles` / `Debug` / ASan+UBSan，见 `CMakePresets.json:12,22-29`），**不是** `build/multiseed` 这一配置；仅用于功能正确性，不用于任何产物形态、性能或统计结论 |
| `{variant}-seed{SEED}.csv` | 20 份原始逐次数据，各 25000 条 |
| `{variant}-seed{SEED}.meta` | 20 份运行元数据 |
| `{variant}-seed{SEED}.report` | 第一轮固定族报告 |
| `{variant}-seed{SEED}.groups.report` | 第二轮单比较族报告 |
| `multiseed-summary.tsv` | M3-5 汇总表 |
| `motivation-seed777-{variant}.{csv,meta,report,groups.report}` | 4 组种子 777 动机复采（`samples_per_category=2000`，每份 10000 条）；`prespecified=no`，不属预注册集合 |
| `record-checks.txt` | 类别顺序比较、全部 SHA3-256、自报字段对照、0.4 第 6 条的 `git diff --cached --check` 输出 |
| `binaries.sha256`、`SHA256SUMS` | 产物与全目录摘要（`SHA256SUMS` 不含自身） |

规模提示：20 份 25000 行 CSV 约 28MB（现有单份约 1.4MB），加 4 份 10000 行动机复采约 2.3MB，
合计约 30MB。保留全部逐次原始值是硬要求，因此按原文本归档，不压缩、不抽样，
并在 README 写明目录体积（`du -sh` 实测值）。

### 3.6 诚实性边界

- 第一轮预注册主比较**在预定阈值下失败**这一事实必须正面写出，不用「次级差异」一类措辞
  把它抹过去；同时按 M3-10 正面更正既有文档里已经这样写过的两处。
- 归档数据显示主比较的**符号是一致的**（三次均为负），只有量级与显著性判定不稳定；
  不得为了强调「失败」而反过来声称方向不稳定——两个方向的夸大都是无据升级。
- 种子 777 的三个 p 值（0.923 / 0.844 / 0.516）来自**未归档、不可从本仓库复现**的口头复核，
  只能作为动机引用；动机复采的数字与它们分开呈现，不互相替代。
- 第二轮假设是**看过第一轮数据之后**提出的；验证数据必须来自 3.2 列出的全新种子，
  先固定假设再采集。假设文本由 0.1 的**模块零提交**入库。
- **预注册凭证的强度边界（必须逐字写进模块三证据 `README.md`、`docs/acceptance.md`
  追加章节与最终报告的「未闭合项」单列，三处措辞一致）**：模块零提交只是**本仓库本地历史中的
  顺序凭证**——本仓库从未推送（M4-7 实测 `git branch -vv` 显示 `main … [origin/main: gone]`、
  `git rev-parse --verify origin/main` 退出码 128），没有第三方时间戳，提交日期可被作者设置。
  因此它只支持「第二轮假设文本的入库早于任何第二轮采集提交」这一**作者自证的相对顺序**，
  **不构成对外可验证的时间戳，也不是可向第三方证明的预注册**。
  更强凭证需要公开推送或外部时间戳服务，属本阶段范围之外，按 0.5 记为未闭合项。
  本仓库对 QEMU、对种子 777 口头复核都用严格口径，对自己的凭证同样不得升级：
  **不得**出现「可信时间凭证」「时间戳证明」「可验证的预注册」一类措辞。
- **两轮的显著性阈值不同严格度，必须并列写出**：第一轮主比较 `alpha_per_comparison=1e-4`，
  第二轮 `alpha_per_comparison=1e-3`（宽 10 倍）。因此「第一轮在 1e-4 下未稳定成立」与
  「第二轮在 1e-3 下成立」不是同一严格度的陈述，**不得**把后者写成对前者同一假设的更强证实；
  汇总表按 M3-5 同时给出按 1e-3 与按 1e-4 的两列读数。
- 方向恒定组在固定密钥下只有**两个不同密文**反复测量，不能当作独立随机密文总体；
  第二轮是机制审计统计量，不是攻击成功率。这一点必须同时出现在文档与报告字段里。
- 多种子重现 ≠ 恒时证明；结论限于 Apple M5 / ARM64 macOS、1000ns 量化时钟、未固定亲和性与频率。
- 不用被测程序自产的期望值证明自身正确（M3-1 的期望值全部手算）。

### 3.7 提交

- 提交 A（代码）：`src/analyze_groups.c`、`src/timing_statistics.c`、
  `include/timing_statistics.h`、`src/analyze.c`（仅抽取共用部分 + 把 `:647` 那行 `qsort`
  换成 `sort_records_by_category_then_duration`，排序语义与调用时点不变，**不改比较族**）、
  `tests/test_analysis_groups.sh`、`tests/test_analysis_round1_replay.sh`、`CMakeLists.txt`。
- 提交 B（证据/文档）：`docs/evidence/statistics-multiseed/*`、`docs/statistics.md`、
  `.gitattributes`（按 0.4 第 6 条的实测结果）。

---

## 4. 模块四：新增代码的检查补齐与追加验收收尾

### 4.1 目标

把本次新增的自有代码纳入与既有代码同级别的检查，并在文档层面如实收尾。

### 4.2 验收标准

**本模块的执行顺序固定**：先做 M4-7 的全新构建（`cmake -S . -B build/review-four-module …`，
命令见 0.2 表）→ 再做 M4-2 的静态分析（它依赖该目录下的 `generated/RelWithDebInfo`）
→ 再做 M4-1 / M4-3 / M4-7 的其余核对 → 最后 M4-4 / M4-5 / M4-6 / M4-8 的文档收尾。

- **M4-1** sanitize preset：`cmake --preset sanitize` → `--build` → `ctest --preset sanitize`，
  18 项全通过，无 ASan/UBSan 报告。日志归档。
  （触发 0.5 降级时改写为降级后实测项数，预期 15。）
- **M4-2** Apple Clang 静态分析覆盖到新文件，命令照 `docs/evidence/review/static-analysis.txt`
  的既有做法，只把 `-I` 的生成目录换成本模块自己的构建目录（**择一已写死**）：

```sh
clang --analyze -std=c11 -Wall -Wextra -Iinclude -Ivendor/mlkem-native/mlkem \
    -Ibuild/review-four-module/generated/RelWithDebInfo \
    -DMLK_CONFIG_FILE='"baseline_config.h"' -Xanalyzer -analyzer-output=text [sources]
```

  既有 `static-analysis.txt` 用的是 `-Ibuild/cmake/generated/RelWithDebInfo`（baseline preset 的
  目录），而本模块用全新的 `build/review-four-module`；选换路径而不是「先跑一次
  `cmake --preset baseline` 让旧目录存在」，理由是本模块的全量复核本来就要建
  `build/review-four-module`，用它自己的 `generated/` 目录能让静态分析与 M4-7 的复核绑定同一次
  配置（`identity_directory` 实测为 `${CMAKE_CURRENT_BINARY_DIR}/generated/$<CONFIG>`，
  RelWithDebInfo 构建后该目录必然存在，内含 `build_identity.h`）。
  **实际使用的包含路径必须逐字记进 `docs/evidence/review-four-module/static-analysis.txt`**，
  并在该文件里写明它与既有 `docs/evidence/review/static-analysis.txt` 的这处差异。
  覆盖 `src/main.c`、`mlkem.c`、`random.c`、`inputs.c`、`measure.c`、`analyze.c`、
  `analyze_groups.c`、`timing_statistics.c`，并分别重复 `-DBASELINE_VULNERABLE=1`、
  `-DBASELINE_HARDENED=1`、`-DBASELINE_DEPLOYABLE=1`。要求**无报告**；
  有报告就修，修复用**独立提交**，修完重跑并归档。
  注意：既有 `docs/evidence/review/static-analysis.txt` 只记录了
  「Checked src/main.c src/mlkem.c src/random.c src/inputs.c src/measure.c.」与
  「Repeated with -DBASELINE_VULNERABLE=1.」，即 **`analyze.c` 从未被静态分析过**，
  而三个变体宏里 `-DBASELINE_HARDENED=1` 与 `-DBASELINE_DEPLOYABLE=1` **两个都是首次**。
  所以这次首次出现报告是正常的，要按上面的流程当真修，
  不要因为「旧代码一直没报」就把它当噪声跳过。
- **M4-3** `format-check` 通过；`uvx --from cmakelang==0.6.13 cmake-format --check CMakeLists.txt
  cmake/*.cmake` 通过；全部 `tests/*.sh`、`tools/*.sh` 的 `sh -n` 通过。
  格式提交与功能修复分开验证，且不格式化 vendor、固定向量、已封存证据。
- **M4-4** `README.md` 更新：变体数量改为四个（含 `deployable` 产物表行）、
  CTest 实测数量、`analyze_groups` 的可执行示例、新文档与新证据链接、
  四变体关系的说明。**必须保留**「仍未执行真实 x86_64 Linux 主机时序实测」这一条，
  不得因为模块二就宣称 x86_64 已验证；模块二只写成「模拟 linux/amd64 的产物形态与功能验证」。
- **M4-5** `docs/acceptance.md` **末尾追加**新章节（不改写既有章节）：引用模块零提交号、
  **逐字写出篇首「预注册的性质与其边界」的定型文字**（这是三处落点之一，见篇首与 3.6）、
  逐项列出本次四个模块的要求、证据入口、结论，以及仍不包含的内容和下一阶段入口；
  该章节内含 M4-8 规定的「最终报告」小节。
  **来源引用的限制必须同时写进本章节**（与第 7、8 节首段同一句）：第一、二轮设计评审的
  原文件已被后续轮次覆盖、不可恢复，只以本设计文件第 7、8 节的逐条摘要留存；
  `docs/tasks/design-review.{md,json}` 的内容是**第三轮**设计评审，自模块零提交起冻结；
  模块零之后各轮评审产物见 `docs/tasks/review-m<模块号>-r<轮次>.{md,json}`（0.1 的命名规则）。
- **M4-6** **追加到 `docs/review.md`**（不新增审查文档，与 4.5 的提交清单一致），
  说明本轮审查/检查范围、修正项、实测平台与边界。
- **M4-7** 全量复核并归档：干净重新构建（全新构建目录 `build/review-four-module`）、
  全部 CTest、format-check、`git log` 逐个核对本次每个提交（**含模块零提交**）的
  分支/作者/提交者/邮箱/hash、`git status` 干净。
  「未 push」的证明方式**已按本机实测定好，不要用 `origin/main..HEAD`**：该写法在本仓库
  直接失败（`git rev-parse origin/main` 报 `unknown revision`，`git branch -vv` 显示
  `main b53e4e0 [origin/main: gone]`，即远端跟踪引用不存在）。改用这三条，逐字归档输出：

```sh
git remote -v
git branch -vv
git rev-parse --verify origin/main; echo "exit=$?"
```

  记录含义：`origin` 指向 `https://github.com/Gowin-liuyin/cryProject.git`，
  但本地没有 `origin/main` 跟踪引用（标记为 `gone`），因此本次提交只存在于本地。
  **第三条的预期输出写死（否则归档时会误以为命令跑错）**：`--verify` 形式实测输出
  `fatal: Needed a single revision`、`exit=128`。**那句 `unknown revision` 属于不带
  `--verify` 的形式**——`git rev-parse origin/main` 实测会先打印一行 `origin/main`，
  再报 `fatal: ambiguous argument 'origin/main': unknown revision or path not in the working tree.`，
  退出码同样是 128（6.1 第 3 条描述的是这一形式，见那里的注）。
  两种文本任一出现都说明 `origin/main` 不存在；**逐字归档实际输出即可，不要去凑另一种文本**。
  同时按 3.6 把「本地顺序凭证、无第三方时间戳」这一条写进最终报告的「未闭合项」单列。
  **不执行 `git fetch`，也不执行 `git push`**——前者会改变上面的观察结果，后者是明令禁止的。
  如果确实需要更强的「远端没有这些提交」证据，那需要联网查询，属于超出本阶段的操作，
  按 0.5 记为缺口，不擅自联网。
- **M4-8 最终报告的落点写死**：最终报告写入 `docs/acceptance.md` 追加章节（M4-5）中一个
  标题为「**最终报告**」的小节，**不新建独立文件**（选这条而不是新建
  `docs/tasks/final-report.md`，理由：`docs/acceptance.md` 已经是本仓库的验收单一入口，
  读者不会漏掉，也避免第二处结论文档与它漂移）。该小节严格按第 5 节排列：
  六类分节 + 四项单列，一项不少。交接消息里给出同样的六类摘要与该小节的链接。
  验收判据：`docs/acceptance.md` 中存在该小节，且六个分节标题与四个单列项逐一可见。

### 4.3 证据契约

目录 `docs/evidence/review-four-module/`：`README.md`（开头写模块零提交号、0.2 表里
`build/review-four-module` 的配置命令、`.meta` 的 `generator=`/`configuration=`/
`compiler_flags=`/`compile_options=` 实测抄录）、
`ctest.log`（含 `ctest -N`）、
`sanitize-ctest.log`、`format-check.log`、`cmake-format.log`、`shell-syntax.log`、
`static-analysis.txt`（含实际使用的 `-I` 包含路径与与既有 `docs/evidence/review/` 的差异说明）、
`git-log.txt`（本次全部提交的 `%h %an <%ae> %cn <%ce>` 与分支状态）、
`readme-examples.log`（README 新示例命令的实际执行输出）、`binaries.sha256`、
`record-checks.txt`、`SHA256SUMS`（不含自身）。

`record-checks.txt` 是 0.4 第 3、5 条的硬要求（既有同类目录 `docs/evidence/review/`
也带这个文件），原设计漏列，本轮补上。本模块没有新的统计采集，因此最小可执行内容定为：
全新构建目录 `build/review-four-module` 里四个变体的 `baseline` / `measure` 用
`openssl dgst -sha3-256` 算摘要；跑一次小样本 `measure`（`RUN_ID=review-<variant>`、每类 50，
**明确不作为统计材料**，CSV 与报告不归档）取其 `.meta` 的 `executable_digest` 逐个对照。
若决定不跑这次小样本，则必须在 `record-checks.txt` 里写明
「本目录无程序自报摘要可对照，0.4 第 5 条在本目录不适用」及理由，**不得默默省略**。
`record-checks.txt` 同时收 0.4 第 6 条的 `git diff --cached --check` 输出。

### 4.4 诚实性边界

- 静态分析是**范围内**的封装/运行代码分析，不是证明，也不是对 vendor 的重新审计。
- 「全部检查通过」只等于检查通过，不等于结论成立；每条结论仍绑定自己的证据目录。
- 真实 x86_64 Linux 主机时序实测**预期仍未闭合**，必须在 README、acceptance、
  最终报告三处都保留。

### 4.5 提交

`docs:` 提交：`README.md`、`docs/acceptance.md`、`docs/review.md`、
`docs/evidence/review-four-module/*`、`.gitattributes`（按 0.4 第 6 条的实测结果）。
M4-2 的修复另出 `fix:` 提交，格式调整另出 `style:` 提交。

---

## 5. 交付与最终报告格式

预计新增提交 **7–9 个**（模块零 1 个、模块一 2 个、模块二 1 个、模块三 2 个、模块四 1–3 个）。
若触发 0.5 的模块间依赖降级规则，另加 **1 个**撤回 deployable 注册的提交（合计 8–10 个）。

最终报告的落点由 M4-8 写死：`docs/acceptance.md` 追加章节里的「最终报告」小节。
它必须**分开**写以下几类，不混为一句「验证通过」：

1. 功能正确（CTest/KAT/等价/随机源失败）——实测项数与覆盖。
2. 源码秘密依赖（哪段源码、为什么依赖私钥）。
3. 产物机制（哪个二进制、哪个地址、什么指令，分 ARM64 实测与模拟 amd64 两类）。
   每类都要注明证据粒度：是**独立符号**的反汇编，还是（deployable 被内联时）
   调用者内联段的反汇编——见 M1-5a / M2-7a；调用者层级取的是 `indcpa_enc` 还是
   `dec`（按 M1-5a 第 2 步的层级规则）也要写出来。
4. 原始数据（多少次、什么种子、什么时钟、存在哪里）。种子 777 动机复采与预注册五种子分列。
5. 观察差异（均值差、效应量，属描述性）。
6. 正式统计确认（第一轮族结果**含其预注册主比较的失败**、第二轮预注册结果、多种子稳健性）。

另外必须单列：

- 本次**新确立**的结论（逐条附证据路径）。
- 本次**未闭合**的项，至少包含：①「真实 x86_64 Linux 主机时序实测」；
  ②「第二轮预注册只有本地顺序凭证、无第三方时间戳」——按 3.6 的定型文字逐字写出，
  不得用「可信时间凭证」一类措辞把它写成已闭合。
- 新增提交数与 `ctest -N` 的实测项数。
- 每个模块提交（**含模块零**）的分支/作者/提交者/邮箱/hash 核对结果。
  若 0.1 的「模块零之后必须修订本设计文件」那条例外被触发，这里**并列**写出
  「预注册凭证提交（模块零）」与「修订提交」两个哈希，并写明修订是否触及 3.2 的第二轮假设。
- 来源引用的限制：第一、二轮设计评审原文件已被覆盖、不可逐字复核，只以第 7、8 节摘要留存
  （与 M4-5、第 7、8 节首段同一句）。

---

## 6. 第一轮复读的修订记录

本文件第一版由上一步写出，**第一轮**复读按步骤要求逐条对着仓库复核，归纳为 13 项修订
（落到 22 处文本改动）。下面记录**改了什么、为什么**，便于评审只看变化点。
**第二轮（按第一轮设计评审发现）的修订记录在第 7 节，第三轮（按第二轮评审发现）在第 8 节，
第四轮（按第三轮评审发现）在第 9 节**；几节冲突时以**第 9 节与正文**为准。

### 6.1 改正的事实错误（3 处）

1. **3.1「方向跨运行不稳定」不成立。** 逐份读取三个归档 vulnerable 报告，
   主比较 `mean_difference_ns` 为 −83.200 / −55.800 / −84.200，`rank_z` 为
   −4.0408 / −4.8309 / −3.8338，**符号三次全为负**。原表述属于无据升级，
   已改写为「符号稳定、量级只有主效应约十分之一、显著性判定跨运行越过阈值」，
   并把 0.6 补上逐份实测值表（7 份报告全录），供模块三直接引用而不用凭记忆。
2. **1.2 说 `mlk_assert_abs_bound`「调试配置下才有效」是错的。** `debug.h` 按
   `MLKEM_DEBUG` / `CBMC` 三分支选择，而 `MLK_CONFIG_DEBUG` 与 `MLKEM_DEBUG` 在
   `include/`、`CMakeLists.txt`、`cmake/`、`src/` 中零出现；`sanitize` preset 只是
   `Debug` + ASan/UBSan，不定义它。所以该宏在**任何** preset 下都展开成 `do {} while (0)`。
   已改为如实表述，并加了一条诚实性边界禁止把它写成「deployable 多了边界检查」。
   顺带补上上游原文用的是参数名 `r`，补丁改名后必须写 `message_polynomial`，
   否则编译不过。
3. **M4-7 的 `git log --oneline origin/main..HEAD` 在本仓库直接失败。**
   实测 `git branch -vv` 显示 `[origin/main: gone]`，`git rev-parse origin/main` 报
   `unknown revision`。已替换为三条可执行命令，并明确禁止用 `git fetch` 去「修好」
   这个观察，也禁止 `git push`。
   **（第四轮已注明：本条描述的 `unknown revision` 是不带 `--verify` 的
   `git rev-parse origin/main` 的输出文本；M4-7 最终写死的是 `--verify` 形式，
   其实测输出为 `fatal: Needed a single revision`、`exit=128`。两种形式的预期输出都已写进
   M4-7，见 9.3 发现 13。）**

### 6.2 补上的设计缺口（5 处）

4. **deployable 没有 `noinline`，「反汇编的是不是执行的代码」原设计未回答。**
   vulnerable / hardened 靠补丁里的 `noinline` 保证独立符号，而 deployable 按设计不带
   任何 `__attribute__`，编译器可以把它内联进调用者，那样离线副本的反汇编
   就不是实际执行的代码。本机实测 reference（同样无属性）目前确实没被内联
   ——`build/cmake/reference/measure` 中只有一处
   `100006edc: bl 0x100002690 <_baseline_native_poly_frommsg>`——但这是观察，不是保证。
   新增 **M1-5a**：全二进制反汇编 + 调用点计数，三种结果（正常 / 被内联 / 部分内联）
   各给定处置，并明确**不许**为了拿到独立符号而给 deployable 加回 `noinline`。
   新增 **M2-7a** 在 x86_64 GCC 下独立重做同一核对（GCC 13 的内联决策与 Clang 无关）。
   两处证据契约都相应加了文件。
   **（第三轮已修正：本条第一轮写的调用者符号 `mlk_indcpa_dec` 是错的，
   实际调用者是 `mlk_indcpa_enc`（重加密路径）。现行口径见 0.6、M1-5a、M2-7a 与 8.1 发现 1。
   本条只保留为第一轮的历史记录。）**
5. **种子 777 复核数据的处置从「如可追溯」变成确定结论。** 全工作树搜索
   `test_seed=777` 零命中，`runs/` 五个目录的 `.meta` 全是 `test_seed=42` 且 `runs/`
   被 `.gitignore` 排除。改为：原三个 p 值标注「未归档、不可从本仓库复现」只作动机，
   **另加 4 次种子 777 动机复采**（`samples_per_category=2000`，与原复核同参数）
   作为可复现替代材料，标注 `prespecified=no`、排在汇总表预注册区之外、不参与
   「五个种子」计数，且重采值与原值并列写出不互相替代。3.2 的排除清单加了一句
   说明这不破坏预注册。
6. **`analyze_groups` 原地重排共享数组的不变式没人负责。** `sample_series` 只是指向
   `set->records` 的区间视图、不拥有数据，「按耗时重排组区间」会破坏组内的类别分段。
   3.3 明确把这个不变式归给 `analyze_groups` 的 `main` 流程（抽出的排序入口保持无状态），
   并固定执行顺序（校验 → 记 `count` → 才排序 → 计算），同时要求用 `_Static_assert`
   钉住 `INPUT_VALID==0 … INPUT_MESSAGE_ONES==4` 与 `INPUT_CATEGORY_COUNT==5`，
   免得将来有人往 `include/inputs.h` 中间插类别时静默算错分组。
7. **补丁 fuzz 没有被挡住。** `cmake/PrepareVariant.cmake` 只用 `patch -p1 -i`，
   不带 `--no-fuzz`，所以 fuzz 会被静默接受，而历史上已经因此出过一次
   `fix: apply the constant-time encoder patch without context fuzz`。1.2 加了
   「提交 A 前在 `build.log` 里确认无 `with fuzz` 字样」，M1-6 也一并要求。
8. **模块二原本没有独立摘要核对环节**，而 0.4 第 5 条对每个证据目录都要求。
   新增 **M2-11**：`.meta` 实测用的是 `executable_digest_algorithm=SHA3-256`，
   所以核对要用容器内 `openssl dgst -sha3-256`（同算法的独立工具）对四个变体的产物
   生成 `binaries.sha3-256` 再逐个对照，并明确「若容器内 openssl 不支持 sha3-256
   就换 `hashlib.sha3_256` 并记录命令，**不许**降成 SHA-256 假装对上」。
   原 M2-11（`docs/validation.md` 追加）顺延为 M2-12，2.4 的文件清单相应补齐。
   **（第二轮已修正：容器内实测既无 `openssl` 也无 `python3`，`hashlib` 备用路线不可用，
   现行口径见 2.2 / M2-11 与 7.1 发现 1。本条只保留为第一轮的历史记录。）**

### 6.3 加强的诚实性要求（1 处）

9. **原设计只说「不用『次级差异』抹过去」，但没处理既有文档里已经这样写了的事实。**
   `docs/evidence/mitigation/README.md` 写了「属于小幅不稳定的次级差异」，
   `docs/statistics.md:84` 写了「主比较只呈现次级差异」。前者是封存证据、按 0.3 只读，
   不能回去改。新增 **M3-10** 要求在新章节里逐字引用这两处、说明为什么不准确
   （在 `primary=yes` 已预注册的前提下对一个预注册失败结果做降级描述，读者会误以为
   预注册按计划成立了）、给出更正口径并声明以新章节为准。
   3.6 同时加了一条反向约束：也不许为了强调「失败」而夸大成方向不稳定。

### 6.4 补上的可执行细节（4 处）

10. 0.6 补 `measure` 的输入约束（`samples_per_category ∈ 1..20000`、`RUN_ID` 1..64 且
   字符集 `[A-Za-z0-9_-]`、`test_seed` 为 `uint64_t`、参数顺序），据此确认每类 5000
   与 `141421356` 这种大种子都合法，不用到实现时才发现被拒。
11. 1.2 补 CMake 的确切落点：`BASELINE_DEPLOYABLE=1` 要加在既有
    `if(variant STREQUAL "vulnerable") … elseif("hardened")` 链条上的
    `elseif(variant STREQUAL "deployable")`。
12. M4-2 补一句：既有 `static-analysis.txt` 只覆盖 5 个文件，**`analyze.c` 从未被静态分析**，
    首次出报告是有可能的，要按流程真修，不要当噪声跳过。
13. **M2-2 原来要求记录「`docker buildx ls` 中 `linux/amd64` 的模拟说明」，但那个说明不存在。**
    本机实测该输出只有平台清单（`linux/amd64 (+2), linux/arm64, …`），没有 emulated / QEMU
    字样。已改为：记录全量输出，并用「宿主 `uname -m`=arm64 + 容器内 `uname -m`=x86_64
    + 无原生 amd64 节点」三件事并列来论证模拟，不靠不存在的标签。

### 6.5 已实测确认、不需要再怀疑的前提

- **第一轮报告逐字可重放**：用当前 `build/cmake/analyze` 对
  `docs/evidence/statistics/vulnerable.csv` 与 `docs/evidence/mitigation/hardened.csv`
  重跑，`cmp` 对归档 `.report` 均**逐字节相同**（无需屏蔽 `welch_p`/`rank_p`）。
  M3-2 的屏蔽只是给跨 libm 平台留余量，结论不变。
- **CTest 基线确为 13 项**（`ctest --test-dir build/cmake -N` 实测），0.2 的 16 / 18 预期成立。
- **`analyze` 固定族确为 10 个比较**（`prespecified_comparisons` 数组），「x/10」有源码依据。
- **四个结果标签齐全**：`insufficient_samples` / `degenerate_no_variation` /
  `significant` / `not_significant`（`comparison_result_label`），M3-1 的拒绝场景有落点。
- **M3-1 的手算期望值已按并列修正重算（原设计此处算错，评审发现 3）**：完全分离场景
  `rank_u1=0.0`、`effect=0.000000`。该场景恒定组 20 个全 1000ns、变化组 30 个全 2000ns，
  只有两个并列块，`src/analyze.c` 的 `rank_sum_test` 用的是**并列修正**方差
  `u_variance = pair_count/12 × (N+1 − Σ(t³−t)/(N(N−1)))`：
  Σ(t³−t) = (20³−20)+(30³−30) = 34950，N=50，
  `u_variance` = 600/12 × (51 − 34950/(50×49)) = 50 × 36.734694 = **1836.7347**，
  σ = **42.8571**，连续性校正后 z = −299.5/42.8571 = **−6.9883**，
  p = erfc(6.9883/√2) ≈ **2.8e-12**。
  原设计写的 σ=50.498 / z≈−5.93 / p≈3e-9 漏了并列修正，是错的（判定 `significant` 不变）。
  因此 M3-1 对该场景**只断言** `rank_u1` / `effect` / `rank_z` 为负 / `result`，
  不把 z、p 的数值写成断言。
- 分布相同场景的手算复核无误：150 胜出对 + 300 并列对之半 = 300 = n1·n2/2，
  `absolute_deviation = |300−300| − 0.5 < 0` 被实现钳到 0，故 `rank_z=0.0000`、`rank_p=1`、
  `effect=0.500000`，这些是精确值，可以断言。
- **工具链齐备（注意区分宿主与容器）**：**宿主** `openssl dgst -sha3-256` 可用；
  **宿主 `ninja` 可用**（本轮实测 `command -v ninja` → `/Users/yin/.local/bin/ninja`，
  0.2 写死的 `-G Ninja` 因此可执行；`baseline` preset 本身用的是 `Unix Makefiles`）；
  **容器内只有 `shasum`，没有 `openssl` 也没有 `python3`**（本轮实测，故 2.2 必须显式装
  `openssl`，见 7.1 发现 1）；`shasum -a 256 -c
  docs/evidence/mitigation/SHA256SUMS` 在仓库根目录通过；`uvx --from cmakelang==0.6.13
  cmake-format` 报 0.6.13；Docker server 29.3.1。
- **提交身份写在局部配置**：`git config --local user.name/user.email` 实测为
  `Gowin-liuyin` / `yinhaoran0808@outlook.com`，无需改动、不动全局。
- **上游 `mlk_poly_frommsg` 确实无分支**（`mlk_value_barrier_u8` + `mlk_ct_sel_int16`），
  两个既有补丁都删掉了 `mlk_assert_abs_bound` 并都保留了 `noinline`，
  参数名都是 `message_polynomial` / `message_bytes`。1.1 对模块一目标的收窄成立。

---

## 7. 对第一轮设计评审发现的处置（第二轮修订）

**来源限制（必须随本节一起引用）**：第一轮设计评审的原文件曾写在
`docs/tasks/design-review.md` / `.json`，**已被第二、三轮写在同一路径上覆盖，不可恢复**；
本节的逐条摘要是它在本仓库里**唯一留存的形式**，无法再逐字复核。
`docs/tasks/design-review.{md,json}` 的内容是**第三轮**设计评审，自模块零提交起冻结；
模块零之后各轮评审产物按 0.1 的命名规则写入互不覆盖的
`docs/tasks/review-m<模块号>-r<轮次>.{md,json}`。这段限制同样写进 M4-5 与最终报告。

第一轮门控 `CHANGES_REQUESTED`（2 HIGH、9 MEDIUM、8 NIT，阻断 11 项）。
以下逐条给出处置。**19 项全部采纳并落到正文**，无一项 backlog、无一项驳回。
**第三轮（按第二轮评审发现）的修订记录在第 8 节、第四轮在第 9 节；
本节与它们冲突时以第 9 节与正文为准。**

### 7.1 HIGH

| # | 发现 | 处置 | 落点 |
|---|---|---|---|
| 1 | 模块二容器内既无 `openssl` 也无 `python3`，M2-11 的主用与备用命令都不存在 | 采纳。2.2 不再写「照抄」apt 清单，显式钉死并加 `openssl`；明确**不装** `python3`，因此取消 `hashlib` 备用路线；M2-11 改写为「主路线容器内 `openssl dgst -sha3-256`」+「备用路线 `docker cp` 到宿主用宿主 openssl 算 SHA3-256，并用两侧 `shasum -a 256` 钉住拷贝一致性」，两组数字都进 `record-checks.txt`；两条都不可行时按 0.5 记缺口。M2-2 增记 `openssl version`。6.5「工具链齐备」一条改为明确区分宿主与容器 | 2.2、M2-2、M2-11、2.4、6.5 |
| 2 | 预注册提交没有安排进任何模块，且与「证据绑定干净工作区」冲突 | 采纳。新增**模块零提交**（本次第一个提交，只含 `docs/tasks/` 三个文件），执行顺序改为模块零 → 一 → 二 → 三 → 四；0.1 给出完整命令并加硬约束「`docs/tasks/` 未跟踪或已修改时不得采集任何计时数据、不得产出任何反汇编证据」；篇首改为引用模块零提交号，并说明自指问题的解决办法（提交后把 `git log -1 --format=%H` 写入四个证据目录 README，模块三 README 另标注它为第二轮预注册的时间凭证）；3.6 与 3.5 的凭证表述同步；第 5 节提交数由 6–8 改为 **7–9**；M4-7 与最终报告的提交核对明确含模块零 | 篇首、0.1、3.5、3.6、4.2（M4-5/M4-7）、第 5 节 |

**（第四轮已修正本行的措辞：「标注它为第二轮预注册的时间凭证」违反篇首的措辞禁令。
现行口径是模块零提交只给出本仓库本地历史内的「作者自证顺序」、无第三方时间戳，
模块三 README 要逐字写出篇首「预注册的性质与其边界」全文，见 3.6 与 9.2 发现 8。
本行的「只含 `docs/tasks/` 三个文件」也已按现状改写：三个文件在上一个提交 `68ba0c3` 已入库，
模块零提交的实际 diff 只含 `four-module-design.md` 一个文件，见 0.1 与 9.2 发现 10。）**

### 7.2 MEDIUM

| # | 发现 | 处置 | 落点 |
|---|---|---|---|
| 3 | 6.5 对 M3-1「完全分离」场景的 σ/z/p 漏了并列修正（写成 50.498 / −5.93 / 3e-9） | 采纳。6.5 改为 Σ(t³−t)=34950、`u_variance`=1836.7347、σ=**42.8571**、z=**−6.9883**、p≈**2.8e-12**，并注明原值是错的、判定 `significant` 不变；M3-1 明确该场景**只断言** `rank_u1=0.0`、`effect=0.000000`、`rank_z` 为负、`result=significant`，不断言 z/p 数值；「分布相同」场景的精确值仍可断言 | 6.5、M3-1 |
| 4 | M1-5a 情况 1 与情况 3 在操作上不可区分，「部分内联」分支永不触发 | 采纳。调用者反汇编改为**四个变体无条件产出**；判据写死为「调用者中同时出现常数 1665（`0x681`）物化 + 按系数推进的 256 次循环」；情况 1 = 计数 ≥ 1 且无该模式、情况 2 = 计数为 0、情况 3 = 计数 ≥ 1 且有该模式；三种都要在 README 写出实际 grep 文本与命中/未命中行。原「仅在情况 2/3 出现」的 `deployable-inlined-*` 文件被替换为无条件的四份调用者反汇编。**（第三轮已修正两点：调用者符号由 `indcpa_dec` 改为 `indcpa_enc`（8.1 发现 1）；「256 次循环」这个合取项因无可执行定义而降为佐证，判据改为写死的正则（8.2 发现 5）。现行口径见 M1-5a / M2-7a。）** | M1-5a、M2-7a、1.4、2.4、1.5 |
| 5 | 第二轮单比较阈值比第一轮主比较宽 10 倍，设计未披露 | 采纳。3.2 新增专条披露（第一轮 `ANALYSIS_FAMILY_ALPHA=0.001` / `COMPARISON_COUNT=10` → 1e-4；第二轮 → 1e-3，宽 10 倍），明令不得暗示第二轮更强证实了第一轮同一假设；3.6 加同一条；M3-5 汇总表对第二轮同时给出「按 1e-3」与「若按 1e-4」两列；报告字段契约新增常量字面量 `round1_alpha_per_comparison_for_reference=0.00010000` 并列入不得删除的诚实性字段 | 3.2、3.3（报告契约）、M3-5、3.6 |
| 6 | 3.2 的样本量退让条款允许采集中途缩样 | 采纳。改为决定时点写死：`samples_per_category=5000` 必须在**第一次预注册采集开始之前**确定；若改则 20 次全部重做，预注册集合内不允许混用样本量；已采集部分归档为 `aborted-<variant>-seed<SEED>.*`，不进预注册区、不参与任何计数 | 3.2 |
| 7 | M3-10 的更正没落在读者会读到的位置，且对 `docs/statistics.md` 误用 0.3 作依据 | 采纳。M3-10 改为两处分别处置：`docs/evidence/mitigation/README.md:47` 按 0.3 只读原样保留、更正只在新章节给出并写明原因；`docs/statistics.md` 的依据换成「不改写既有结论、只追加」的工程约定（**不引 0.3**），第 84 行原句不动，紧随该段之后**追加**一句交叉引用（给出定型文字与第 N 节占位），并写明「只把更正写在文末就不成立正面更正」 | M3-10 |
| 8 | `analysis_round1_replay` 缺工作目录与报告落点两个决定能否运行的细节 | 采纳。3.3 写死两个新测试的 `add_test` 与 `set_tests_properties(analysis_round1_replay PROPERTIES WORKING_DIRECTORY "${CMAKE_CURRENT_SOURCE_DIR}")`（已核对 `vector_integrity` 正是此写法）；脚本报告落点固定为 `$1/round1-replay-<name>.report` 并先 `rm -f` 以避开 `fopen "wx"`，明令不得向 `docs/evidence/` 写入；M3-2 补记评审侧的第二次实测（`build/cmake/analyze` 与 `build/cmake-sanitize/analyze` 共四次重放全部逐字节相同，屏蔽余量比原设计声称的更宽松） | 3.3、M3-2 |
| 9 | M4-8 的「最终报告」没有指定产物，不可验收 | 采纳，并**择一写死**：最终报告写入 `docs/acceptance.md` 追加章节里标题为「最终报告」的小节，不新建 `docs/tasks/final-report.md`（理由写在 M4-8：acceptance 已是验收单一入口，避免第二处结论文档漂移）；给出验收判据（六个分节标题 + 四个单列项逐一可见）；M4-5 与第 5 节同步 | M4-8、M4-5、第 5 节 |
| 10 | 4.3 漏了 `record-checks.txt`，与 0.4 第 3、5 条冲突 | 采纳。4.3 加上 `record-checks.txt` 并写明最小可执行内容：`build/review-four-module` 里四个变体产物用 `openssl dgst -sha3-256` 算摘要 + 一次小样本 `measure`（`RUN_ID=review-<variant>`、每类 50、明确不作统计材料、CSV 与报告不归档）取 `.meta` 的 `executable_digest` 对照；不跑则必须写明「0.4 第 5 条在本目录不适用」及理由 | 4.3 |
| 11 | 模块一失败时模块二、三的输入前提失效，无降级路径 | 采纳。0.5 后新增「模块间依赖降级规则」：deployable 构建失败或 `deployable_kat` / `equivalence_deployable` 未通过时按 0.5 记未闭合项，模块二与模块三改为三变体继续（模块三 20 次 → **15 次**，动机复采 4 → 3）；3.2 中 deployable 的方向性期待记「未采集」，不得删除也不得改判成立；所有汇总表保留 deployable 行并标注「未采集（原因见模块一缺口记录）」；并明确该降级不改动第二轮预注册内容 | 0.5 |

### 7.3 NIT

| # | 发现 | 处置 | 落点 |
|---|---|---|---|
| 12 | `vulnerable-path-arm64.txt` 实测 2216 行，非 2209 | 采纳，改为「实测 2216 行」 | 0.6 |
| 13 | `docs/evidence/completion/` 只有一份 encoder 反汇编，不宜作四份的格式先例 | 采纳，改引 `docs/evidence/mitigation/{reference,vulnerable,hardened}-encoder-arm64.txt`，并注明 completion 只有一份 | M1-5（1.4 的表随 4 号发现一并改写） |
| 14 | `SHA256SUMS` 不可能包含自身 | 采纳，0.4 第 4 条改为「除 `SHA256SUMS` 自身以外的全部文件」，并附既有口径实测（20 文件 / 19 行）；2.4、3.5、4.3 的清单同步标注「不含自身」 | 0.4、2.4、4.3 |
| 15 | M2-2 可加一条更硬的模拟证据；M2-9 的答案已提前观察到 | 采纳。M2-2 的三件事改为**四件**，新增「容器内 `/proc/cpuinfo` 为宿主 ARM64 字段、无 `model name` 行」并附实测输出；M2-9 补一句该现象已在模块二开始前于宿主观察到、预期 `cpu_model=unavailable`，但仍以模块二实测为准（保留「不预设」口径） | M2-2、M2-9 |
| 16 | 模块一、模块三未固定 `RUN_ID` 与采集构建目录名 | 采纳，并扩到四个模块：0.2 新增一张表（模块一 `build/deployable` / `deployable-<variant>`；模块二容器内 `/build` / `smoke-<variant>`；模块三 `build/multiseed` / `multiseed-<variant>-<seed>` 与 `motivation777-<variant>`；模块四 `build/review-four-module` / `review-<variant>`），M1-7、3.1、3.2、2.4、4.3 处同步写出 | 0.2、M1-7、3.1、3.2、2.4、4.3 |
| 17 | 3.1 第 2 条把跨两轮的主比较范围除以只描述一轮的主效应范围 | 采纳，改为**按各轮自比**：`statistics/` 那轮 711–800ns / 0.819–0.844 / \|z\| 62–67，`mitigation/vulnerable` 那轮 690–824ns / 0.776–0.795 / \|z\| 52.6–55.9，并明令不得跨轮混用分母 | 3.1 |
| 18 | M4-2 漏了 `-DBASELINE_HARDENED=1` 也从未跑过 | 采纳，提示改为「三个变体宏里 HARDENED 与 DEPLOYABLE 两个都是首次，`analyze.c` 也是首次被分析，首次出报告正常，按流程当真修」，并附既有 `static-analysis.txt` 的逐字两行内容 | M4-2 |
| 19 | 0.2 的「每个模块的提交 A 之前」对模块二、模块四不成立 | 采纳，改为「每个**含代码或配置改动**的模块，在其提交 A 之前跑完」，并注明模块二以 M2-4 / M2-5 为准、模块四以 M4-1 / M4-3 为准 | 0.2 |

### 7.4 第一轮评审的「本轮无法验证」项如何处理

评审列出的 5 项「无法验证但设计不应当作既定前提」不需要新增修订，理由逐条如下，
本轮只确认它们已有落点：模拟 amd64 容器能否在超时内完成构建与 16 项测试 → M2-5 的
「超时即记缺口、不得缩减样本或跳过测试」；GCC 13 是否内联 → M2-7a 明令独立重做、
不套用 ARM64 结论，且经 4 号发现改造后判据已可执行；新补丁能否过
`-Wconversion -Wpedantic -Werror` → M2-4 的「我方代码有警告就独立 `fix:` 提交修」；
模块三 CSV 实际体积 → 3.5 已要求写 `du -sh` 实测值；deployable 在 Apple Clang 21 下是否被内联
→ M1-5a 已把它当观察而非保证。

---

## 8. 对第二轮设计评审发现的处置（第三轮修订）

**来源限制（与第 7 节同一句）**：第二轮设计评审的原文件（实测曾为 319 行）同样写在
`docs/tasks/design-review.md` / `.json`，**已被第三轮覆盖、不可恢复**；
本节的逐条摘要是它唯一留存的形式，无法再逐字复核。
`docs/tasks/design-review.{md,json}` 现在的内容是第三轮设计评审，自模块零提交起冻结。

第二轮门控 `CHANGES_REQUESTED`：2 HIGH、4 MEDIUM、9 NIT，阻断 6 项。
**15 项全部采纳并落到正文，无一项 backlog、无一项驳回。**
凡评审给出「择一写死」的地方，本节写出选了哪一条与理由；
凡评审给出可实测的判据，当轮都在本机重跑确认后才写进正文。
**第四轮（按第三轮评审发现）的修订记录在第 9 节；本节与第 9 节冲突时以第 9 节与正文为准。**

### 8.1 HIGH

| # | 发现 | 处置 | 落点 |
|---|---|---|---|
| 1 | 调用路径核对打在错误的调用者符号上（`indcpa_dec` 不含编码器，使 M1-5a / M2-7a 成为恒假检查） | 采纳。本轮独立复核确认：`vendor/.../indcpa.c:544` 的 `mlk_poly_frommsg(k, m)` 在 `mlk_indcpa_enc`（自 :518 起）内，是全 vendor 唯一调用点，解封装路径为 `dec → indcpa_enc`（重加密）`→ poly_frommsg`；`indcpa_dec` 只调 `poly_tomsg`。调用者符号一律改为 `indcpa_enc`：ARM64 `objdump -d --disassemble-symbols=_baseline_native_indcpa_enc …`、x86_64 `objdump -d --disassemble=baseline_native_indcpa_enc …`；文件名改为 `{variant}-caller-indcpa-enc-arm64.txt` / `{variant}-caller-indcpa-enc-amd64-gcc.txt`。新增**层级规则**：先记 `grep -c 'bl.*<_baseline_native_indcpa_enc>'`（x86_64 用 `call.*<baseline_native_indcpa_enc>`），计数 ≥ 1 取 `indcpa_enc`，计数为 0 改取 `dec` 层并在 README 写明取的层级。本轮对 `build/mitigation/{reference,vulnerable,hardened}/measure` 三份归档同配置产物实测该计数均为 **2**，`poly_frommsg` 调用点均为 **1**，三者都落情况 1。0.6 的叙述、6.2 第 4 条与 7.2 发现 4 均加注更正 | 0.6、M1-5a、M2-7a、1.4、2.4、1.5、第 5 节、6.2、7.2 |
| 2 | 模块二的证据没有出容器的路径，M2-11 备用路线与 `--rm` 互斥 | 采纳。2.2 写死完整运行方式：`mkdir -p /tmp/linux-amd64-build` + `docker run --rm --platform linux/amd64 -v "$PWD":/workspace:ro -v /tmp/linux-amd64-build:/build -w /build baseline-linux-gcc-amd64:ubuntu2404 sh -c '…'` 并由宿主 `tee` 出 `verification.log`；容器内所有证据写 `/build`（= 宿主 `/tmp/linux-amd64-build`），出容器后由宿主复制进 `docs/evidence/linux-amd64/` 并在宿主生成 `binaries.sha256` 与 `SHA256SUMS`。0.2 表模块二行改为「容器内 `/build/cmake`，`/build` = 宿主 `/tmp/linux-amd64-build`（仓库工作区之外）」并补上容器配置命令。M2-11 备用路线改为**直接对宿主 `/tmp/linux-amd64-build` 下的产物**用宿主 `openssl dgst -sha3-256`，不需要 `docker cp`；若仍要用 `docker cp` 则必须 `--name` + 不带 `--rm` + 事后 `docker rm`。M2-10 的宿主 `git status --porcelain` 为空仍适用（`/tmp` 不在仓库内）。2.4 改成带「算处」列的表，并明确八个产物副本本身也归档（否则宿主侧 `binaries.sha256` 没有对象） | 2.2、0.2、M2-11、2.4、2.6 |

**（第四轮已修正本行最后一句：实测既有先例对「构建目录路径」算摘要、目录内无二进制副本，
所以「不归档副本就没有对象」这个前提不成立。现行口径是不归档副本、宿主 `binaries.sha256`
对 `/tmp/linux-amd64-build/cmake/…` 算，见 0.4 第 3 条、2.4 与 9.2 发现 9。）**

### 8.2 MEDIUM

| # | 发现 | 处置 | 落点 |
|---|---|---|---|
| 3 | 降级规则与写死的 CTest 项数、「全部通过」判据冲突 | 采纳，**择一写死为「撤回注册」**（评审建议的前者）。0.5 的降级规则扩成四步：①独立提交撤回 deployable 的构建与测试注册（`CMakeLists.txt` 两个 `foreach` 与 `equivalence_deployable`、**四个** `test_*.sh` 的变体循环），补丁与 `BASELINE_DEPLOYABLE` 分支保留在仓库作缺口材料；②M1-2 / M1-3 / M3-3 / M4-1 的项数改以降级后 `ctest -N` 实测值为准（预期 13 / 13 / 15 / 15）并注明低于 16 / 18 的原因；③缺口材料落 `docs/evidence/deployable/`；④下游改三变体，并点明 M3-1 最后一条与四个 `test_*.sh` 循环的降级行为。**不采用**「保留注册接受三项失败」：既有七份证据都记录「全部 CTest 通过」，长期留红会让后续每个 `ctest` 判据都带口头例外。第 5 节的提交数补上「降级另加 1 个提交」 | 0.5、M1-2、M1-3、M3-1、M3-3、M4-1、第 5 节 |
| 4 | 三个正式采集构建目录只写了名字，没写配置命令、生成器与构建类型 | 采纳。0.2 的表增加**配置命令**列并逐字写死（`cmake -S . -B build/deployable -G Ninja -DCMAKE_BUILD_TYPE=RelWithDebInfo -DBUILD_TESTING=ON -DBASELINE_SANITIZERS=OFF`，`build/multiseed`、`build/review-four-module` 同型；模块二为容器内 `cmake -S /workspace -B /build/cmake -DCMAKE_C_COMPILER=gcc …`），并写出为什么固定 Ninja + RelWithDebInfo（与 `docs/evidence/mitigation/README.md:6-8` 及其 `.meta` 实测 `generator=Ninja` 同配置可比）。同时写明**与 preset 的差异**：`baseline` preset 实测生成器是 `Unix Makefiles`（`CMakePresets.json:12`），与采集目录的 Ninja 不同，地址不跨构建复用。四个证据 README 都要求逐字抄录该目录 `.meta` 的 `generator=` / `configuration=` / `compiler_flags=` / `compile_options=`；实测生成器若与 mitigation 不同必须写出差异 | 0.2、1.4、1.5、2.5、3.5、4.3 |
| 5 | 内联判据只有一半机械，立即数文本形式未写死 | 采纳。判据改为**写死的正则**：`grep -nE '(#\|\$)0x681\|[#$ ]1665\b' <调用者反汇编>; echo "exit=$?"`，命中即判存在内联副本（充分条件），同时覆盖 Apple 的 `#0x681`、GNU x86_64 的 `$0x681` 与十进制 `1665`。特异性对照为同一正则对**全二进制**反汇编的 `grep -cE`，本轮对三份归档产物实测均为 **1**（就在编码函数内），调用者侧实测均为 **0**；两个数字都归档。「按系数推进的 256 次循环」降为**佐证**（命中后人工读段并在 README 引用行号区间），不作判据。0.6 补一条专门记录该常数的特异性实测与 Apple objdump 的实际印法 `mov w10, #0x681             ; =1665`，并声明 GNU / x86_64 印法未验证；M2-7a 补「三种形式都不命中且全二进制计数为 0 时，不得把未命中读成无内联，必须先在 encoder 反汇编里找出实际印法并记进证据，找不到按 0.5 记缺口」 | M1-5a、M2-7a、0.6、1.4、1.5、2.4 |
| 6 | 0.4 第 3 条要求 `binaries.sha256`，2.4 只列 `binaries.sha3-256` | 采纳，**择一写死为评审的 (a)**：2.4 同时列两份并写明算处——`binaries.sha3-256` 由**容器内** `openssl dgst -sha3-256` 算（独立同算法，对照 `.meta` 的 `executable_digest`）、`binaries.sha256` 由**宿主** `shasum -a 256` 对拷进证据目录的八个产物副本算（满足 0.4 第 3 条）；容器内另出 `binaries.sha256-in-container`，两侧 SHA-256 在 `record-checks.txt` 逐行比对。选 (a) 而不是给 0.4 开例外，是为了让四个新证据目录的必备文件清单保持一致 | 0.4、2.4、M2-11 |

**（第四轮已修正本行：实测既有先例都对「构建目录路径」算摘要、证据目录里没有二进制副本，
所以「对拷进证据目录的八个产物副本算」与另三个模块不一致。现行口径是不归档副本、
宿主 `binaries.sha256` 对 `/tmp/linux-amd64-build/cmake/…` 算，两份摘要文件仍都要有，
见 0.4 第 3 条、2.4 与 9.2 发现 9。）**

### 8.3 NIT

| # | 发现 | 处置 | 落点 |
|---|---|---|---|
| 7 | M4-6 的「或新增审查文档」是未决二选一 | 采纳，改为「**追加到 `docs/review.md`**」，与 4.5 的提交清单一致 | M4-6 |
| 8 | M3-5「若按 1e-4 判定」列没有判定规则 | 采纳，写死 `rank_p < 1e-4 → significant_at_1e-4=yes`，并给出从 `comparison=` 行取 `rank_p=` 的完整 `awk` 命令；`rank_p=` 缺失（`degenerate_no_variation` / `insufficient_samples`）时写 `na`，不得当成 `no` 混进计数。命令与逐份输出记入证据 README | M3-5、3.3 |
| 9 | 3.3 没说 `result=` 用哪套标签 | 采纳，写明复用 `src/analyze.c` 的 `comparison_result_label` 四个标签（`insufficient_samples` / `degenerate_no_variation` / `significant` / `not_significant`），随共用部分抽到 `timing_statistics.c`、两个程序共用同一实现只换 `alpha_per_comparison`；并照抄 `write_comparison_line` 的字段存在性规则（`degenerate_no_variation` 不写 `rank_*`），供 M3-5 的派生列使用 | 3.3 |
| 10 | deployable 补丁是否保留上游 `MLKEM_INDCPA_MSGBYTES` 守卫未定 | 采纳，**择一写死为「保留该守卫」**，位置在函数体开头、平铺循环之前。理由：deployable 的定位是「若要部署应该长成什么样」的参照，保留上游编译期一致性检查符合该定位，且它是纯预处理判断、不产生指令，对产物零影响。同时在 1.2 与 1.5 写明这是与另两个补丁的**源码形态**差别（实测 `message-constant-time.patch` 把它删掉了），并禁止表述为「多了一层运行时检查」 | 1.2、1.5 |
| 11 | 四个新证据目录缺 `.gitattributes` 条目 | 采纳，并改成机械步骤而不是照抄一份清单：0.4 新增第 6 条，指出既有 `.gitattributes` 实测**不是**每个目录同一组条目（`cmake`/`linux-gcc` 有 `*.log`+`*.meta`，`completion`/`mitigation`/`review`/`statistics` 只有 `*.meta`，`docs/evidence/final/*.txt` 没有条目），因此沿用「按需添加、不发明新模式」，每个证据提交前跑 `git add docs/evidence/<name>` + `git diff --cached --check` + `echo "exit=$?"`，按实测报警补条目并把输出（含空结果）写进 `record-checks.txt`；给出四个目录的预期落点但明确「以实测为准」。`.gitattributes` 改动并入各模块的提交 B | 0.4、1.6、2.6、3.7、4.5、1.4、2.4、3.5、4.3 |
| 12 | M3-10 的插入会使多处 `docs/statistics.md:84` 行号引用失效 | 采纳。本轮实测该段落为第 80–85 行，交叉引用句插在段落之后、M3-9 新章节追加在文件末尾，因此第 84 行**预期不变**；但仍按发现要求写死机械核对：插入前后各跑 `grep -n '主比较只呈现次级差异' docs/statistics.md`，两次输出写入证据 README，引用时「以原句文本为主、行号为辅」并写出插入前 84 / 插入后实测两个数字；若实测行号真变了则同步更新新章节、证据 README 与本设计文件 | M3-10、3.5 |
| 13 | fuzz 核对没有写死命令与归档落点 | 采纳，写死 `grep -n 'with fuzz' docs/evidence/deployable/build.log; echo "exit=$?"`，判据为 `exit=1` 通过、`exit=0` 必须修补丁上下文后重建重跑，输出（含空结果）写入 `record-checks.txt`；M1-6 引用同一条命令 | 1.2、M1-6、1.4 |
| 14 | 动机复采归档清单 3.1 与 3.5 不一致 | 采纳，3.1 统一为**四件** `motivation-seed777-{variant}.{csv,meta,report,groups.report}`，与 3.5 和 M3-4「两份报告都归档」一致 | 3.1 |
| 15 | M4-2 的静态分析包含路径依赖 baseline preset 目录 | 采纳，**择一写死**：包含路径改为 `-Ibuild/review-four-module/generated/RelWithDebInfo`（本模块自己的构建目录，`identity_directory` 实测为 `${CMAKE_CURRENT_BINARY_DIR}/generated/$<CONFIG>`，RelWithDebInfo 构建后必然存在），并固定模块四的执行顺序为「M4-7 的全新构建 → M4-2 → M4-1/M4-3/M4-7 其余 → 文档收尾」；实际使用的包含路径与与既有 `docs/evidence/review/static-analysis.txt` 的差异都要写进本模块的 `static-analysis.txt` | M4-2、4.2、4.3 |

**（第四轮对本小节两行加注更正：第 3 行的理由句「既有七份证据都记录『全部 CTest 通过』」
实测不准确——`docs/evidence/` 共 8 个目录，其中 `module3` 没有任何 CTest 记录，
且那七份的记录文件名并非都叫 `ctest.log`，现行准确表述见 0.5 第 1 步与 9.3 发现 12；
第 12 行的「若实测行号真变了则同步更新…与本设计文件」已被 0.1 的冻结约束取代，
现行口径是只更新新章节与证据 README，见 M3-10 与 9.2 发现 7。）**

### 8.4 本轮自行补上的两处设计缺口（不在评审发现里）

- **`tests/test_vector_parser.sh:11` 也有变体循环，原设计漏了它。** 实测四个脚本都写着
  `for implementation in reference vulnerable hardened`：`test_cli.sh:6`、
  `test_measurement.sh:6`、`test_analysis.sh:134`、`test_vector_parser.sh:11`。
  1.2 只列了前三个，那会让 `vector_parser` 这项 CTest 不覆盖 deployable（畸形向量文件的拒绝
  在新变体上完全没被检查）。已把 1.2、1.6 与 0.5 的降级规则一并改为**四个**脚本。
- **M1-5a 的四种组合里有一种是自相矛盾的，原设计只列了三种。** 调用点计数为 0 意味着
  编码器必定被内联，此时调用者正则**应当**命中；若「计数为 0 且未命中」同时出现，
  说明判据本身在该变体上失效（例如常数印法超出正则），既不能读成情况 1（无内联），
  也不能读成情况 2（有内联段可读）。已在 M1-5a 与 M2-7a 各加一条「矛盾组合」处置：
  按 0.5 记为缺口、留全部逐字输出、先查常数印法，仍无法解释就不下产物形态结论，
  **不以离线副本反汇编冒充执行路径证据**。

### 8.5 第二轮评审的「本轮无法验证」项如何处理

评审列出的 9 项 Unverified 不需要额外修订，本轮只确认落点并把「未验证」写进正文，
不当作既定前提：

| 项 | 落点 |
|---|---|
| amd64 镜像能否经代理装上 `openssl`、容器内 `openssl` 是否支持 `sha3-256` | M2-11 的主/备两条路线 + 两条都不可行时按 0.5 记缺口；2.2 的 apt 清单已显式加 `openssl` |
| QEMU 能否在超时内完成配置、构建与全部 CTest | M2-5「超时即记缺口，不得缩减样本、放宽断言或跳过测试」 |
| GCC 13 是否内联 deployable 编码器、`0x681` 在 GNU objdump 下的印法 | M2-7a 明令独立重做；本轮新增「三种印法都不命中时不得读成无内联」的处置 |
| Apple Clang 21 是否内联无属性的 deployable 编码器 | M1-5a 的三情况分流；0.6 明写 reference 的实测只是观察不是保证 |
| 新补丁能否过 `-Wconversion -Wpedantic -Wshadow -Werror` | 0.2 的必要检查（提交 A 之前）+ M2-4 的独立 `fix:` 提交 |
| 种子 777 的三个口头复核 p 值 | 3.1 / 3.6 已定为「未归档、不可复现，只作动机」，另有可复现的动机复采并列呈现 |
| 模块三证据目录约 30MB 的估算 | 3.5 要求写 `du -sh` 实测值 |
| M2-2 引用的 `docker buildx ls`、容器内 `/proc/cpuinfo`、`uname -m` | M2-2 / M2-9 要求以模块二实测为准；M2-9 明写「预期 `cpu_model=unavailable`」只是预期 |
| 三个采集构建目录的生成器与编译选项实际取值 | 已由发现 4 写死配置命令，并要求 README 抄录 `.meta` 实测值——本项在本轮后从「无法核对」变为「可核对」 |

---

## 9. 对第三轮设计评审发现的处置（第四轮修订，本文件定稿）

评审文档：`docs/tasks/design-review.md`（第三轮，557 行），门控 `docs/tasks/design-review.json`
（`CHANGES_REQUESTED`：1 HIGH、9 MEDIUM、7 NIT，共 17 项，阻断 10 项）。
**17 项全部采纳并落到正文，无一项 backlog、无一项驳回。**
凡评审给出「择一写死」的地方，本节写出选了哪一条与理由；
凡评审给出的实测事实，本轮都在本机重新跑过命令确认后才写进正文——
其中有一处**评审建议的措辞本身不够准确，按实测事实改写**，见 9.3 发现 12。
**本节与第 6、7、8 节冲突时以本节与正文为准。本文件自模块零提交起冻结（0.1）。**

### 9.1 HIGH

| # | 发现 | 处置 | 落点 |
|---|---|---|---|
| 1 | 第二轮分组依赖的「按类别排序」归属错了，照设计实现会静默算错分组 | 采纳，按实测改正。本轮复核确认：`src/analyze.c` 的 `load_measurement_set`（自 `:346` 起）只做逐行校验与 `append_record`、**全程不排序**；排序在 `main` 的 `src/analyze.c:647` `qsort(set.records, set.record_count, sizeof(*set.records), compare_measurement_record)`，`:648` 才是 `build_series`；`docs/evidence/mitigation/reference.csv` 前四条数据行实测为 `message-zero, valid, message-zero, message-zero`，即 CSV 本身类别乱序。四项修订全部落地：① 3.3 的事实句改为「排序在 `main`，加载函数不排序」，并写明照原写法会切到乱序数组的前 N / 后 M 条、仍能算出格式合法的 p 值而无断言失败；② `analyze_groups` 的 `main` 固定为**六步**，新增第 2 步「对整份 `set->records` 调用 `sort_records_by_category_then_duration`」；③ 抽到 `src/timing_statistics.c` 的是**两个无状态入口** `sort_records_by_category_then_duration(records, record_count)`（整份、先类别后耗时，`compare_measurement_record` 随之移入）与 `sort_range_by_duration(records, record_count)`（单区间、只按耗时），`src/analyze.c` 的 `main` 改调前者且排序语义与时点逐字不变（M3-2 兜住）、**不调**后者，`analyze_groups` 必须自己依次调用两者；④ M3-1 新增「类别乱序输入」场景（行序按类别交替、恒定类全 1000ns、变化类全 2000ns），断言 `count=20` / `count=30` / `rank_u1=0.0` / `effect_size_first_greater=0.000000` / `rank_z` 为负 / `result=significant`，并写明漏掉整份排序时该条必然失败 | 3.3、M3-1、3.7 |

### 9.2 MEDIUM

| # | 发现 | 处置 | 落点 |
|---|---|---|---|
| 2 | M1-6 拿 SHA-256 去对 SHA3-256 的自报字段 | 采纳，按实测拆句。实测 `docs/evidence/mitigation/reference.meta:16-17` 为 `executable_digest_algorithm=SHA3-256` / `executable_digest=4d677872…fba3c`，而 `record-checks.txt:5` 的 `SHA3-256(build/mitigation/reference/measure)=` 与它**逐字相同**（本轮复核一致），这就是现成的正确先例。M1-6 拆成两条：①`openssl dgst -sha3-256 build/deployable/<variant>/{baseline,measure}` 与对应 `.meta` 的 `executable_digest` 逐个相同（同算法独立工具，照上述先例）；②`binaries.sha256` 另用 `shasum -a 256` 记录同一批产物以满足 0.4 第 3 条，**不参与** `executable_digest` 的对照，并明写「SHA-256 的值不可能等于 SHA3-256，不得比对、不得改写任何一方」。M3-8 的「与对应 `measure` 产物摘要一致」补上算法名 `openssl dgst -sha3-256` 及同一条禁令 | M1-6、M3-8 |
| 3 | `tests/test_cli.sh` 末尾还有一段硬编码的跨变体逐字节比较，1.2 只改了循环 | 采纳。实测 41–44 行确实是逐变体列出的 `cmp reference-$category vulnerable-$category` / `… hardened-$category`，**不在** `:6` 的变体循环内；只改循环会让 deployable 生成五个文件却从不被比较。1.2 新增一条项目符号，贴出实测原文与写死的改法（对 `vulnerable hardened deployable` 再套一层循环，或等效地补一行 `cmp … deployable-$category`）；0.5 降级第 1 步的撤回清单加上「还原 `test_cli.sh` 末尾比较块」。另两处硬编码已逐条核对**不需要改**并写进 1.2：`test_measurement.sh:29,32` 的 `reference.csv`/`vulnerable.csv` 是比较工具的固定一对参数，`test_analysis.sh:100` 的 `s/,reference,/,hardened,/` 是构造畸形 CSV 的字面量。1.6 的提交 A 清单不变（同一文件） | 1.2、0.5、M1-2 |
| 4 | 模块二把全部步骤塞进一个 `set -eu` 的 `sh -c`，任何被判失败的步骤都会吞掉后续证据 | 采纳。2.2 的脚本骨架改写并把失败处置写死：① `set -eu` 改为 **`set -u`**；② 硬失败只保留两处**前置条件**（`cmake` 配置失败；进入反汇编与摘要之前四个 `measure` 产物不存在），两处都先把退出码写进 `step-exits.txt` 再 `exit 1`；③ 构建、fuzz 核对、`ctest -N`、`ctest`、反汇编、调用点计数、摘要一律 `命令 > 日志 2>&1; echo "<step>_exit=$?" >> /build/step-exits.txt` 记录后继续，反汇编与摘要**排在 `ctest` 之后但不依赖其退出码**；④ `step-exits.txt`、`configure.log`、`build.log`、`ctest-list.log`、`ctest.log` 一并归档，2.4 清单补上这五个文件，`README.md` 的「未能完成的项」小节必须引用 `step-exits.txt` 的**实测退出码**而不是无数字的描述。这样 M2-4 的「允许警告并记录」与 M2-5 的「失败或超时就记成缺口并继续」才真正可执行 | 2.2、2.4、M2-5、0.5 |
| 5 | 模块二没有 fuzz 门，而容器里换的是另一个 `patch` 实现 | 采纳，新增 **M2-4a**。依据：`cmake/PrepareVariant.cmake` 实测只有 `COMMAND "${PATCH_EXECUTABLE}" -p1 -i "${PATCH_FILE}"`、**无 `--no-fuzz`**（本轮确认），容器内是 GNU patch 2.7.6（`docs/evidence/linux-gcc/README.md:8`），与宿主 BSD patch 的 fuzz 行为不保证相同；先例 `docs/evidence/linux-gcc/README.md:17` 反而写了「两个补丁都无 fuzz 应用」。命令写死跑两次（容器内对 `/build/build.log`、归档后对 `docs/evidence/linux-amd64/build.log`），判据 `exit=1` 通过，`exit=0` 时**不得继续产出反汇编结论**、按 0.5 记缺口并把逐字输出写进 `record-checks.txt` 与 `README.md`；2.4 清单补上 `build.log` | M2-4a、2.2、2.4 |
| 6 | 2.2 的 apt 命令与「走代理」的叙述不一致，照抄不可执行 | 采纳，**把代理写进命令本身**：建镜像的 `docker run` 加 `-e http_proxy=http://host.docker.internal:7890` 与 `-e https_proxy=…`，并写明「这两个 `-e` 就是『走该代理』的全部实现，没有别的隐含设置」；若本机 apt 不需要代理则去掉两个 `-e` 并在 `README.md` 写明实际执行的那条命令（逐字），不留两种写法让读者猜。apt 失败时逐字保存到 `attempt-failure.log` 并按 0.5 记缺口；`openssl` 装不上时**不得**改用宿主算 SHA3-256 就当模块二完成，必须按 M2-11 标注走的是备用路线及原因 | 2.2、2.4 |
| 7 | M3-10 与 8.3 第 12 条要求在模块零之后回头改本文件，这会解绑「提交号 ↔ 预注册文本」 | 采纳，三处都写死。① 0.1 新增硬约束：**模块零提交之后 `docs/tasks/four-module-design.md` 不再修改**（含行号、措辞、笔误），需要更新的事实只写进证据 `README.md` 与 `docs/statistics.md` / `docs/acceptance.md` 的新增章节并注明「本设计文件保持模块零提交时的原文」；② M3-10 的行号处置改为**只更新**新章节与 `docs/evidence/statistics-multiseed/README.md`，并在那里写「本设计文件引用的 84 是模块零时点实测值，插入后实测为 `<N>`」，明确不得回头改本文件；③ 0.1 给出例外路径：若确实必须修订本文件，作为**新的独立提交**，并在证据 README、`docs/acceptance.md` 追加章节与最终报告**并列写出「预注册凭证提交（模块零）」与「修订提交」两个哈希**、说明修订是否触及 3.2 的第二轮假设内容，**触及则该轮预注册作废、换全新种子重做**。第 5 节的单列项同步 | 0.1、M3-10、第 5 节 |
| 8 | 预注册凭证是本地未推送提交，这个限制一个字都没写 | 采纳。本轮复核：`git branch -vv` 显示 `main 68ba0c3 [origin/main: gone]`，`git rev-parse --verify origin/main` 退出码 **128**。篇首新增「**预注册的性质与其边界**」定型文字段：第二轮假设在新种子采集开始之前已以文字形式固定并入库，**仓库为本地仓库、从未 push、无第三方时间戳、提交日期可由作者设置，因此这是作者自证的顺序、不是可向第三方证明的预注册**；更强凭证需公开推送或外部时间戳服务，属本阶段之外、按 0.5 记未闭合项。同段给出**措辞禁令**（不得出现「可信时间凭证」「时间戳证明」「可验证的预注册」）与三处落点（模块三证据 `README.md`、`docs/acceptance.md` 追加章节、最终报告的「未闭合项」单列）。3.2 标题与标注段、3.5 的 README 行、3.6 的凭证条、M4-5、第 5 节的未闭合项全部按该口径改写 | 篇首、3.2、3.5、3.6、M4-5、第 5 节 |
| 9 | 只有模块二把八个二进制产物拷进证据目录，与三处先例和另三个模块都不一致 | 采纳，**择一写死为评审建议的 (a)：不归档二进制副本**。实测依据：`docs/evidence/mitigation/binaries.sha256` 七行全是 `build/mitigation/…` 构建目录路径、目录内无副本；容器先例 `docs/evidence/linux-gcc/` 连 `binaries.sha256` 与 `record-checks.txt` 都没有，更无副本；`docs/evidence/` 下当前没有任何二进制文件；单个 `measure` 实测 129KB、八个约 1MB 且进 git 后按 0.3 不可删。2.2 已把 `/build` 绑定到宿主 `/tmp/linux-amd64-build`，八个产物在宿主直接可见。因此宿主 `binaries.sha256` 用 `shasum -a 256` 对 `/tmp/linux-amd64-build/cmake/<variant>/{baseline,measure}` 生成、路径逐字保留（与 mitigation 同型），`record-checks.txt` 写明「摘要对象是容器写出的宿主可见产物，未拷入仓库；容器内 `shasum -a 256`（`binaries.sha256-in-container`）与这份逐行一致，钉住同一份文件」；2.4 删除产物副本行并写出选 (a) 的全部理由。0.4 第 3 条相应改为「摘要对象一律是构建目录里的产物文件、不把副本拷进仓库」，这样四个新证据目录的**摘要对象**口径才真正一致（8.2 发现 6 声称的「清单一致」原先只在文件名层面成立） | 0.4、2.4、M2-11、2.2 |
| 10 | 第 7、8 节把两轮评审当证据引用，但评审文件是固定路径、每轮覆盖 | 采纳，**择一写死为评审的 (b)（保留单一文件名 + 如实声明来源限制），并补上向前的命名规则以免再次覆盖**。实测 `docs/tasks/` 只有 `four-module-design.md`、`design-review.md`、`design-review.json` 三个文件，且三者**已随上一个提交 `68ba0c3` 入库**（评审当轮观察到的 `?? docs/tasks/` 已不成立，本轮按现状改写），历史里没有任何一轮评审产物的旧版本，前两轮内容**已不可恢复**，所以 (a)「提交全部轮次文件」在事实上无法执行。落地：① 第 7、8 节首段各加同一句来源限制——前两轮原文件已被覆盖、不可逐字复核，只以该两节的逐条摘要留存，`docs/tasks/design-review.{md,json}` 的内容是第三轮；② 0.1 把「会有多轮评审产物」改为实测的三个文件，并写明前两轮不在其中；③ 0.1 新增命名规则：`design-review.{md,json}` 自模块零提交起**冻结**、不得再被覆盖，**第四轮起**每轮评审产物写入互不覆盖的 `docs/tasks/review-m<模块号>-r<轮次>.{md,json}`（如 `review-m1-r1.md`），引用时一律给出具体文件名；④ M4-5 与第 5 节的单列项写同一句来源限制 | 0.1、第 7 节、第 8 节、M4-5、第 5 节 |

### 9.3 NIT

| # | 发现 | 处置 | 落点 |
|---|---|---|---|
| 11 | deployable 补丁的函数体没有给出可照抄的片段 | 采纳，1.2 贴出目标片段（平铺 256 次系数循环 + `mlk_value_barrier_u8((uint8_t)(1u << (coefficient_index % 8u)))` 取位掩码 + `mlk_ct_sel_int16(MLKEM_Q_HALF, 0, selection_condition)` 选择），并注明两点：**值屏障按系数取**（与上游按字节/按位的写法数值等价，但形态贴近平铺单层循环、与另两个变体可直接对照）；`selection_condition` 的显式 `uint16_t` 转换是为了过 `-Wconversion -Werror`（`message_bytes[...] & bit_mask` 的整型提升结果是 `int`）。同时写明若该片段与严格警告冲突，按 M2-4 的口径修并记录实际写法，不得删警告选项 | 1.2 |
| 12 | 「既有七份证据」与实测目录数不符，0.3 的「已封存」没有定义 | 采纳，但**措辞按实测改写**：评审建议的「实测 cmake、completion、final、linux-gcc、mitigation、review、statistics 七份**带 `ctest.log`**」本轮核对**不准确**——只有 `completion`、`mitigation`、`review`、`statistics` 有 `ctest.log`，`cmake` 是 `multi-config-ctest.log` + `sanitize-ctest.log`，`final` 是 `build-and-test.log` + `sanitize.log`，`linux-gcc` 的 CTest 结果在 `verification.log` 里。因此 0.5 的理由句改为「既有**有 CTest 记录**的七份证据目录」并逐目录列出实际文件名；0.3 补上可机械判断的定义：「已封存 = 当前 `main` 上已提交的 `docs/evidence/` 全部目录，实测 8 个（`cmake`、`completion`、`final`、`linux-gcc`、`mitigation`、`module3`、`review`、`statistics`）；`module3` 只有 `SHA256SUMS` 与 `encoder-arm64.txt`、不满足 0.4 清单，属历史遗留，同样只读且**不得回头补齐**」，并写明本次四个新目录在各自证据提交后同样进入封存状态 | 0.3、0.5 |
| 13 | M4-7 写死的命令与 6.1 描述的报错文本不是同一条命令的输出 | 采纳。M4-7 补上预期输出：`--verify` 形式实测 `fatal: Needed a single revision`、`exit=128`；`unknown revision` 属**不带 `--verify`** 的形式（实测 `git rev-parse origin/main` 先打印一行 `origin/main`，再报 `fatal: ambiguous argument 'origin/main': unknown revision or path not in the working tree.`，退出码同样 128）；两种文本任一出现都说明 `origin/main` 不存在，逐字归档实际输出即可、不要去凑另一种文本。6.1 第 3 条加注说明它描述的是不带 `--verify` 的形式 | M4-7、6.1 |
| 14 | M3-2 没说重放脚本调哪个 `analyze`，也没说比较几份 | 采纳。3.3 补上：程序路径固定为 `$1/analyze`（`analyze` 的 `RUNTIME_OUTPUT_DIRECTORY` 实测就是构建根）；用例固定为两份并列成表（`docs/evidence/statistics/vulnerable.csv` → `round1-replay-statistics-vulnerable.report`、`docs/evidence/mitigation/hardened.csv` → `round1-replay-mitigation-hardened.report`，各自对照同目录的归档 `.report`）；两次 `cmp`（屏蔽 `welch_p=` / `rank_p=` 之后）**都必须通过**，任一失败即测试失败，脚本不得只跑一份就返回成功 | 3.3、M3-2 |
| 15 | M1-5 / M2-7 的分支判据没有给出助记符清单 | 采纳，两处各加同一套**四步口径**：逐条列出该函数反汇编里所有条件跳转（地址 + 助记符）→ 逐条标注归属（循环计数比较 = 循环边界，ARM64 实测形式为 Apple Clang 的 `b.ne` 与 ARM64 GCC 的 `b.ls`，依据 `docs/evidence/linux-gcc/README.md` 的表与 `docs/evidence/mitigation/*-encoder-arm64.txt`；操作数链可追到 `message_bytes` 取字节/取位 = 消息位相关）→ 标注依据（上一条影响标志位的指令及其操作数来源）写进 `README.md` → **归属无法判定的按 0.5 记缺口，不得默认算作循环边界**。x86_64 / GNU 侧的助记符**未观察**，按模块二实测填写，不先写死一份清单让实现时去凑 | M1-5、M2-7 |
| 16 | `multiseed-summary.tsv` 的列名与列序没有写死 | 采纳，M3-5 写死制表符表头与列序：`implementation`、`seed`、`prespecified`、`round1_significant_count`、`round1_primary_rank_p`、`round1_alpha_per_comparison`、`round2_result`、`round2_rank_p`、`round2_significant_at_1e-4`、`mean_difference_ns`、`effect_size_first_greater`、`rank_z`、`category_mean_range_ns`，并注明 `round1_alpha_per_comparison` 恒为 `0.00010000`、`round2_significant_at_1e-4` 取值域 `yes|no|na`、动机复采四行 `prespecified=no` 且排在最后 | M3-5 |
| 17 | 模块一证据目录会混进另一套构建配置的日志，1.4 没要求说明 | 采纳。实测 `sanitize` preset 的 `binaryDir` 是 `build/cmake-sanitize`、生成器继承 `baseline` 的 `Unix Makefiles`、构建类型 `Debug` 且带 ASan/UBSan（`CMakePresets.json:12,22-29`），与 `build/deployable`（Ninja / RelWithDebInfo）不是同一配置。1.4 的 `sanitize-ctest.log` 行加括注写明来源配置、并声明「仅用于功能正确性，不用于任何产物形态或性能结论」；1.5 加同一条诚实性边界；3.5 的同名文件行同样处理（并把 `build/multiseed` 的日志与它分行列出，不再混在一格里） | 1.4、1.5、3.5 |

### 9.4 第三轮评审的「判定为错」与「本轮无法验证」项如何处理

评审「判定为错」的 6 项都是上面 17 项的同一事实（发现 1、2、3、12、13、9），已逐条按实测改正，
不另列。评审列出的 10 项 Unverified 不需要新增修订，本轮只确认落点并把「未验证」写进正文：

| 项 | 落点 |
|---|---|
| amd64 镜像能否经（或不经）代理装上 `openssl`、容器内 `openssl` 是否支持 `sha3-256` | M2-11 的主/备两条路线 + 两条都不可行时按 0.5 记缺口；代理参数已按发现 6 写进 2.2 的命令 |
| QEMU 下配置、构建与全部 CTest 能否在可接受时间内完成 | M2-5；**失败时的证据可得性已由发现 4 修好**（`set -u` + `step-exits.txt` + 各步日志落盘） |
| GCC 13 是否内联 deployable 编码器、`0x681` 在 GNU objdump / x86_64 下的印法 | M2-7a（含「三种印法都不命中时不得读成无内联」） |
| Apple Clang 21 是否内联无属性的 deployable 编码器 | M1-5a 的四种组合分流（含矛盾组合） |
| 新补丁能否过 `-Wall -Wextra -Wpedantic -Wshadow -Wconversion -Wstrict-prototypes -Werror` | 0.2 的必要检查 + M2-4；发现 11 已贴出目标片段并写明 `uint16_t` 转换的理由 |
| 容器内 GNU patch 2.7.6 是否会以 fuzz 应用补丁 | **原为「无落点」，已由发现 5 新增 M2-4a 补上** |
| 种子 777 的三个口头复核 p 值 | 3.1 / 3.6 已定为「未归档、不可复现，只作动机」，另有可复现的动机复采并列呈现 |
| 模块三证据目录约 30MB 的估算 | 3.5 要求写 `du -sh` 实测值 |
| `uvx --from cmakelang==0.6.13 cmake-format` 能否在无网络时运行 | M4-3；本阶段未预取该版本，失败按 0.5 记缺口 |
| 容器内 `clock_getres(CLOCK_MONOTONIC)` 的实测值 | M2-3；无论多少都不改变 M2-1 |
