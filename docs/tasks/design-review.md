# 四模块设计评审（第三轮，独立复核）

评审对象：`docs/tasks/four-module-design.md`（1541 行，含第 7 节对第一轮、第 8 节对第二轮评审的处置）。
评审方式：不带写作上下文，逐条对着仓库源码、归档证据与本机实际执行结果核对。
凡设计声称「实测」「已核实」的前提，本轮都重新跑命令验证，不采信文本。

结论：**CHANGES_REQUESTED**（1 HIGH、9 MEDIUM、7 NIT；阻断 10 项）。

第二轮的 15 项修订全部落地且方向正确。本轮重新跑的数字全部成立：
`indcpa.c:544` 的 `mlk_poly_frommsg(k, m)` 确实在 `mlk_indcpa_enc`（:518 起）内且是 vendor 唯一调用点；
对 `build/mitigation/{reference,vulnerable,hardened}/measure` 实测 `poly_frommsg` 调用点各 1、
`indcpa_enc` 调用点各 2、判据正则在调用者反汇编上命中各 0、在全二进制上各 1；
CTest 基线 13 项；`analyze` 固定族 10 个比较；七份归档报告的主比较数值逐字与 0.6 的表一致；
6.5 的并列修正手算（Σ(t³−t)=34950、σ=42.857、z=−6.988）复算无误，且 `%.1f/%.4f/%.6g/%.6f`
的打印格式支持 M3-1 挑选的那几条逐字断言。

阻断项集中在三类：一处会让第二轮统计**静默算错**的源码事实错误（分组前的排序归属）；
若干条自相矛盾或不可执行的证据契约（摘要算法、容器脚本的失败处置、fuzz 门、代理参数、产物归档口径）；
以及预注册凭证链的两处诚实性缺口（模块零提交后仍要改本文件、本地未推送提交不构成时间凭证）。

---

## 发现列表

### 1. HIGH — 第二轮分组依赖的「按类别排序」归属错了，照设计写会静默算错分组

位置：3.3「这里有一个必须由 `analyze_groups` 自己守住的不变式」段第一句；
同段固定执行顺序那一条；3.3「分组在实现上是连续区间」段。

问题（本轮实测）：

- 设计写「`load_measurement_set` 用 `compare_measurement_record`（先类别、后耗时）对 `set->records`
  整体排序」。实测**不是**：`src/analyze.c` 的 `load_measurement_set`（:349 起）只做逐行校验与
  `append_record`，全程不排序；排序发生在 `main` 里，`src/analyze.c:647`
  `qsort(set.records, set.record_count, sizeof(*set.records), compare_measurement_record);`
  紧跟其后才是 `build_series`（:405）按类别取连续区间。
- CSV 本身是类别乱序的（`docs/evidence/mitigation/reference.csv` 前四行实测为
  `message-zero, valid, message-zero, message-zero`），所以未排序时「类别索引 0–2 / 3–4 两段连续」
  这一前提不成立。
- 而 3.3 写死的执行顺序是「加载并校验 → 校验五类齐全且等量 → 记录两组的 `count` →
  **才**对两个区间各排一次序 → 计算」，**整份数组按类别排序这一步根本没有出现**。
  按字面实现，`analyze_groups` 会把乱序数组的前 N 条当成「方向变化组」、后 M 条当成「方向恒定组」，
  两组各自再按耗时排序后照样能算出分位点、Mann-Whitney、p 值并写出格式完全合法的报告——
  错误不会被任何断言抓到，M3-1 的「完全分离」「分布相同」两个合成场景恰好对类别归属不敏感
  （前者各类同值、后者各类同分布），也抓不到。

影响：第二轮预注册的唯一判定统计量会在真实数据上算错，而报告与 CTest 全绿。
这是本轮唯一必须在写代码之前改掉的项。

修复（写死步骤与归属）：

1. 3.3 那句事实改为：「`src/analyze.c:647` 的 `main` 在 `load_measurement_set` **之后**调用
   `qsort(..., compare_measurement_record)`，加载函数本身不排序」。
2. `analyze_groups` 的固定顺序改成五步，第 2 步是新增的：
   ① 加载并校验 → ② **对整份 `set->records` 调用 `compare_measurement_record` 排序**
   → ③ 校验五类齐全且每类等量、每组 ≥ 2 → ④ 记录两组 `count` 与区间起止
   → ⑤ 才对两个区间各按耗时排一次序 → ⑥ 计算分位点/矩与比较、写报告。
3. 明确排序入口的归属：抽到 `src/timing_statistics.c` 的是**两个无状态入口**——
   `sort_records_by_category_then_duration(records, count)`（现 `analyze.c:647` 那一次）与
   `sort_range_by_duration(records, count)`（组区间那一次）；
   `src/analyze.c` 的 `main` 改为调用前者，行为逐字不变（由 M3-2 兜住），
   `analyze_groups` 必须自己依次调用前者与后者。
4. M3-1 追加一条能抓住这个错误的拒绝/正确性场景：构造一份**类别乱序**且两组均值明显不同的
   合成 CSV（例如恒定类全 1000ns、变化类全 2000ns，但行序按 `message-zero, valid, …` 交替写出），
   断言 `count=20` / `count=30`、`rank_u1=0.0`、`effect_size_first_greater=0.000000`；
   若 `analyze_groups` 漏了整份排序，这一条必然失败。

---

### 2. MEDIUM — M1-6 拿 SHA-256 去对 SHA3-256 的自报字段，正是 M2-11 明令禁止的做法

位置：M1-6 最后一句；与 0.4 第 5 条、1.4 的 `record-checks.txt` 行、M2-11 结论句冲突。

问题：M1-6 写「`binaries.sha256` 与 `.meta` 的 `executable_digest` 对上，证明测的是该变体产物」。
但 `.meta` 实测是 `executable_digest_algorithm=SHA3-256`
（`docs/evidence/mitigation/reference.meta:16-17`），而 `binaries.sha256` 是
`shasum -a 256`（0.4 第 3 条）。两者算法不同，不可能「对上」。
M2-11 自己写着「**无论走哪条路线，都不得改用 SHA-256 与 `executable_digest` 对照后声称对上了**」，
1.4 的 `record-checks.txt` 行也写的是 SHA3-256 对照——只有 M1-6 这条判据写错了，
而模块一的验收会照 M1-6 执行。既有先例 `docs/evidence/mitigation/record-checks.txt` 的做法正确：
`SHA3-256(build/mitigation/reference/measure)= 4d6778…` 与 `reference.meta` 的
`executable_digest=4d6778…` 逐字相同（本轮已比对一致）。

修复：M1-6 改为两句分开写——
「`openssl dgst -sha3-256 build/deployable/<variant>/{baseline,measure}` 的输出与对应
`.meta` 的 `executable_digest` 逐个相同（同算法独立工具，照
`docs/evidence/mitigation/record-checks.txt` 先例）；`binaries.sha256` 另用
`shasum -a 256` 记录同一批产物，满足 0.4 第 3 条，**不参与** `executable_digest` 的对照」。
M3-8「与对应 `measure` 产物摘要一致」同样补上算法名 `openssl dgst -sha3-256`。

---

### 3. MEDIUM — `tests/test_cli.sh` 末尾还有一段硬编码的跨变体逐字节比较，1.2 只改了循环

位置：1.2 第四个项目符号（四个脚本的变体循环）；1.6 提交 A 清单；0.5 降级第 1 步；8.4 第一条。

问题（本轮实测）：`tests/test_cli.sh` 除了 `:6` 的变体循环，**末尾另有一段**（实测 41–44 行）：

```sh
for category in valid bit-flipped random message-zero message-ones; do
    cmp "$test_directory/reference-$category" "$test_directory/vulnerable-$category"
    cmp "$test_directory/reference-$category" "$test_directory/hardened-$category"
done
```

即 CLI 测试里「新变体生成的测试向量与 reference 逐字节一致」是靠这两行**逐变体列出**实现的，
不在循环里。只按 1.2 把 `deployable` 加进 `:6` 的循环，deployable 会生成
`$test_directory/deployable-*` 五个文件却**从不被比较**，CLI 层的一致性检查静默不覆盖新变体。
这与 8.4 自查出的 `test_vector_parser.sh` 漏项是同一类问题。
（另两处硬编码不需要改：`test_measurement.sh:29,32` 的 `reference.csv` / `vulnerable.csv`
是固定一对，用于 `test_measurement` 比较工具本身，hardened 也不在内；
`test_analysis.sh:100` 的 `s/,reference,/,hardened,/` 是构造畸形 CSV 的字面量，与变体集合无关。）

修复：1.2 增加一条：`tests/test_cli.sh` 末尾的比较块改为
`for variant in vulnerable hardened deployable; do cmp "$test_directory/reference-$category" "$test_directory/$variant-$category"; done`
（或直接加一行 `cmp … deployable-$category`）；0.5 降级第 1 步的撤回清单同步加上「还原
`test_cli.sh` 末尾比较块」；1.6 提交 A 清单不变（同一文件）。

---

### 4. MEDIUM — 模块二把全部步骤塞进一个 `set -eu` 的 `sh -c`，任何被判失败的步骤都会吞掉后续证据

位置：2.2 写死的 `docker run … sh -c 'set -eu …'`；M2-4、M2-5 的「如实记录/记缺口」；0.5 第 1 步。

问题：2.2 规定单次容器运行、`set -eu`、内含 M2-2…M2-9 与 M2-11 的全部步骤，
宿主 `tee` 出唯一的 `verification.log`。但 M2-4 允许「`-Werror` 下出现警告」、
M2-5 明确「QEMU 下某项失败或超时就如实记录…把它写成缺口」。在 `set -e` 下：

- 构建失败（-Werror）→ 脚本在第 2 步终止，M2-5…M2-11 的产物一份都不存在；
- `ctest` 失败或超时（这是 M2-5 预期可能发生的情形）→ 脚本终止，
  四份 encoder 反汇编、四份 caller 反汇编、`call-site-counts-amd64.txt`、四份 `.meta`、
  `binaries.sha3-256` 全部拿不到，而 2.4 的证据清单要求它们在目录里，
  0.5 又要求「保存逐字失败输出并继续下一模块」。

即「记缺口后继续」在所选运行方式下不可执行，且失败恰好是最需要证据的情形。

修复（在 2.2 的脚本骨架里写死失败处置）：

1. 把被判定的步骤改成不终止脚本的形式，逐步记录退出码，例如
   `cmake --build /build/cmake --parallel > /build/build.log 2>&1; echo "build_exit=$?" >> /build/step-exits.txt`，
   `ctest --test-dir /build/cmake --output-on-failure > /build/ctest.log 2>&1; echo "ctest_exit=$?" >> /build/step-exits.txt`；
2. 只对「继续下去毫无意义」的前置步骤保留硬失败（配置失败、四个 `measure` 产物不存在），
   并在 2.2 写明哪几步是硬失败、哪几步是记录后继续；
3. 反汇编、调用点计数与摘要步骤放在 `ctest` **之后但不依赖其退出码**；
4. `/build/step-exits.txt` 与 `build.log`、`ctest.log` 一并归档，2.4 清单补上这三个文件，
   `README.md` 的「未能完成的项」小节引用其中的实测退出码。

---

### 5. MEDIUM — 模块二没有 fuzz 门，而容器里换的是另一个 `patch` 实现

位置：2.2 / 2.3（模块二检查项）；对比 1.2 的写死命令与 M1-6。

问题：1.2 与 M1-6 把「`build.log` 里不出现 `with fuzz`」定成硬门，理由是
`cmake/PrepareVariant.cmake` 实测只用 `patch -p1 -i`（本轮确认，无 `--no-fuzz`），
历史上已因此出过 `fix: apply the constant-time encoder patch without context fuzz`。
模块二在容器内**重新应用同样三到四个补丁**，用的是 GNU patch 2.7.6
（`docs/evidence/linux-gcc/README.md` 实测版本），与宿主 BSD patch 的 fuzz 行为不保证相同，
而模块二的全部结论都是对打完补丁的产物做反汇编。M2-4 只要求记录警告，没有任何 fuzz 判据；
先例 `docs/evidence/linux-gcc/README.md` 反而写了「两个补丁都无 fuzz 应用」，
即本设计比先例弱。

修复：M2-4 追加一条与 1.2 同型的写死命令（在容器内对 `/build/build.log` 跑，
并在归档后对 `docs/evidence/linux-amd64/build.log` 再跑一次）：
`grep -n 'with fuzz' /build/build.log; echo "exit=$?"`，判据 `exit=1` 通过；
`exit=0` 时不得继续产出反汇编结论，按 0.5 记缺口并保留逐字输出到
`record-checks.txt`；2.4 清单补上 `build.log`（当前只列了 `verification.log`）。

---

### 6. MEDIUM — 2.2 的 apt 命令与「走代理」的叙述不一致，照抄不可执行

位置：2.2 的 `docker run --name baseline-gcc-amd64-setup …` 代码块与紧随其后的那句
「apt 走 `http_proxy=http://host.docker.internal:7890`，`--platform linux/amd64`」。

问题：代码块是「写死」的建镜像命令，却**没有传任何代理环境变量**；
紧接着的散文说 apt 走该代理。两种读法都成立（要么命令漏了 `-e`，要么这句只是描述本机环境不需要写），
而这一步决定 `openssl` 能否装进镜像——整个 M2-11 主路线都挂在它上面。

修复：把代理写进命令本身并声明失败处置，例如

```sh
docker run --name baseline-gcc-amd64-setup --platform linux/amd64 \
    -e http_proxy=http://host.docker.internal:7890 \
    -e https_proxy=http://host.docker.internal:7890 \
    ubuntu:24.04 sh -c 'apt-get -qq update && apt-get -qq install -y --no-install-recommends \
     build-essential cmake git patch perl binutils openssl'
```

并加一句：若本机 apt 无需代理则去掉两个 `-e` 并在 `README.md` 写明实际用的命令；
apt 失败时逐字保存输出、按 0.5 记缺口，**不得**改用宿主算 SHA3-256 就当模块二完成。

---

### 7. MEDIUM — M3-10 与 8.3 第 12 条要求在模块零之后回头改本文件，这会解绑「提交号 ↔ 预注册文本」

位置：0.1 篇首的凭证落点与硬约束；M3-10「行号引用的处理」最后一句；8.3 第 12 条。

问题：0.1 把模块零提交号定为第二轮预注册的时间凭证，凭的是「该提交入库的这份文本」。
但 M3-10 写：「若实测行号发生了变化，以插入后的实测行号更新新章节、证据 README
**与本设计文件**的引用」——即在模块三（已看过并采集数据）期间修改预注册文件。
0.1 只给了操作路径（先单独提交修订再取证），没有禁止修改**预注册内容所在的文件**，
于是出现两种都能自洽的读法：凭证指向模块零那次提交的文本（则本文件此后不可再改），
或指向文件当前内容（则凭证失效）。这正是第二轮预注册最容易被质疑的地方。

修复：

1. 0.1 增加一条硬约束：「模块零提交之后，`docs/tasks/four-module-design.md`
   **不再修改**（含行号、措辞、笔误）。任何需要更新的事实只写进证据 `README.md`
   与 `docs/statistics.md` 的新章节，并注明『本设计文件保持模块零提交时的原文』。」
2. M3-10 相应改为：行号变化只更新新章节与 `docs/evidence/statistics-multiseed/README.md`，
   并写出「本设计文件引用的 84 是模块零时点的实测值，插入后实测为 <N>」。
3. 若确实必须修订本文件（例如发现事实错误），则必须作为**新的独立提交**，
   并在证据 README 与最终报告里把「预注册凭证提交」与「修订提交」两个哈希并列写出、
   说明修订内容与它是否触及第二轮假设；触及则该轮预注册作废重做。

---

### 8. MEDIUM — 预注册凭证是本地未推送提交，这个限制一个字都没写

位置：篇首「预注册生效条件」；0.1；3.2 标题段；3.6 第四条；M4-7。

问题：M4-7 自己实测并归档「本地没有 `origin/main` 跟踪引用（`gone`），本次提交只存在于本地」
（本轮复核：`git branch -vv` 显示 `main b53e4e0 [origin/main: gone]`，
`git rev-parse --verify origin/main` 失败退出 128）。
既然如此，模块零提交只能证明**本仓库历史里的相对顺序**：提交时间可由作者设置，
没有任何第三方时间戳或公开可见性。而篇首、3.2、3.6 一律把它称为「预注册的时间凭证」，
读者会理解成可对外验证的时间证明。这和本设计对 QEMU、对 777 口头复核的严格口径不一致
——同样的「不升级声明」标准应当用在自己的凭证上。

修复：在 3.6 与篇首各加一条诚实性边界（措辞可直接采用）：
「模块零提交只是**本仓库本地历史中的顺序凭证**：它未推送、无第三方时间戳，
提交日期可被改写，因此它只支持『第二轮假设在任何第二轮采集提交之前已写定』这一相对顺序，
**不构成**对外可验证的时间戳。若将来需要更强的凭证，需要公开推送或外部时间戳服务，
属于本阶段范围之外（按 0.5 记为未闭合项）。」
最终报告的「未闭合项」单列里也加这一条。

---

### 9. MEDIUM — 只有模块二把八个二进制产物拷进证据目录，与三处先例和另三个模块都不一致

位置：2.4 表末段「八个被测产物…副本本身也归档」；0.4 第 3 条；8.2 第 6 条的选择理由。

问题（本轮实测）：

- `docs/evidence/mitigation/binaries.sha256` 的七行全部是**构建目录路径**
  （`build/mitigation/reference/measure` 等），目录里**没有**二进制副本；
- 容器先例 `docs/evidence/linux-gcc/` 既没有 `binaries.sha256` 也没有 `record-checks.txt`，
  更没有产物副本；
- 目前 `docs/evidence/` 下没有任何二进制文件；单个 `measure` 实测 129KB，
  八个副本约 1MB，进 git 后不可删（0.3 只读）。

而模块一、三、四的 `binaries.sha256` 按 0.4 第 3 条仍会记录 `build/<dir>/…` 路径。
于是 8.2 第 6 条声称的「让四个新证据目录的必备文件清单保持一致」只在文件名层面成立，
**对象**不一致（模块二算归档副本，其余算构建目录里的文件），反而更难核对。
2.2 已经把 `/build` 绑定到宿主 `/tmp/linux-amd64-build`，八个产物在宿主直接可见，
不需要拷进仓库才有摘要对象。

修复（择一写死，建议 a）：
(a) 模块二不归档二进制副本；宿主 `binaries.sha256` 用
`shasum -a 256 /tmp/linux-amd64-build/cmake/{reference,vulnerable,hardened,deployable}/{baseline,measure}`
生成，行内路径逐字保留（与 mitigation 先例同型），并在 `record-checks.txt` 说明
「摘要对象是容器写出的宿主可见产物，未拷入仓库；容器内 `shasum -a 256`
（`binaries.sha256-in-container`）与这份逐行一致，钉住同一份文件」，2.4 删除产物副本行；
(b) 仍归档副本，则必须在 2.4 写明实测体积、说明为什么模块一/三/四不这样做、
并给 `docs/evidence/linux-amd64/` 的产物加 `.gitattributes` 的 `binary` 条目（0.4 第 6 条的机械步骤要覆盖它）。

---

### 10. MEDIUM — 第 7、8 节把两轮评审当证据引用，但评审文件是固定路径、每轮覆盖

位置：0.1 关于 `git add docs/tasks/` 的理由段；第 7 节首段；第 8 节首段。

问题（本轮实测）：`docs/tasks/` 目前只有 `four-module-design.md`、`design-review.md`、
`design-review.json` 三个文件，且整个目录仍是未跟踪状态（`git status --porcelain` 输出 `?? docs/tasks/`），
历史里没有任何一轮评审产物。第 7 节写「评审文档：`docs/tasks/design-review.md`（第一轮）」、
第 8 节写「（第二轮，319 行）」，但这两轮的文件都已被下一轮写在同一路径上覆盖
（本轮同样覆盖第二轮那 319 行）。0.1 又说 `docs/tasks/` 下「会有多轮评审产物
（本设计文件 + 每轮的 `design-review.md` / `design-review.json`）」——按当前命名不可能成立。
结果是：模块零提交进去的是**最后一轮**评审，而第 7、8 节引用的第一、二轮评审在仓库里不存在，
第 5 节的「六类分节 + 四项单列」最终报告将引用一条无法核对的来源。

修复（择一写死）：
(a) 评审产物按轮次命名 `design-review-round1.md` / `-round1.json` … `-round3.*`，
模块零提交全部轮次的文件，第 7、8 节的引用改成对应轮次文件名；
本轮与后续轮次都先把上一轮文件改名归位再写新文件（改名属 `docs/tasks/` 内、模块零之前，不违反 0.3）；
(b) 保留单一文件名，但把第 7、8 节首段改成
「第一、二轮评审文档已被后续轮次覆盖，仅以本节的逐条摘要留存；
`docs/tasks/design-review.{md,json}` 始终是**最后一轮**的内容」，
并在 M4-5 的追加章节与最终报告里用同一句话说明来源限制。
无论选哪条，0.1 那句「多轮评审产物」的表述都要与实际命名一致。

---

### 11. NIT — deployable 补丁的函数体没有给出可照抄的片段

位置：1.2 第三个项目符号（位选择改用上游设施）。

问题：deployable 补丁是模块一唯一的新代码，设计对它的约束是散文式的：
平铺 256 次循环、`mlk_value_barrier_u8` 取位掩码 + `mlk_ct_sel_int16` 做选择、
条件参数显式转 `uint16_t`、参数名沿用既有补丁、保留 `MLKEM_INDCPA_MSGBYTES` 守卫与
`mlk_assert_abs_bound`。字节索引/位索引的算法（`coefficient_index / 8u`、`% 8u`）、
屏障是每系数调用还是每字节调用、`MLKEM_Q_HALF` 的传参形式都未写死，
而 `-Wall -Wextra -Wpedantic -Wshadow -Wconversion -Wstrict-prototypes -Werror`
（本轮从 `CMakeLists.txt` 的 `baseline_options` 确认）对这几处写法敏感。
既有 `docs/mitigation.md` 对 hardened 就给了三行片段作为先例。

修复：在 1.2 贴出与既有补丁同型的目标片段（实现时可微调但语义固定），例如

```c
for (unsigned coefficient_index = 0; coefficient_index < MLKEM_N; ++coefficient_index) {
    const uint8_t bit_mask = mlk_value_barrier_u8((uint8_t)(1u << (coefficient_index % 8u)));
    const uint16_t selection_condition =
        (uint16_t)(message_bytes[coefficient_index / 8u] & bit_mask);
    message_polynomial->coeffs[coefficient_index] =
        mlk_ct_sel_int16(MLKEM_Q_HALF, 0, selection_condition);
}
```

并注明：屏障按系数取（与上游按位取等价，形态上更贴近平铺循环），
`selection_condition` 的显式 `uint16_t` 转换是为了过 `-Wconversion -Werror`。

---

### 12. NIT — 「既有七份证据」与实测目录数不符，0.3 的「已封存」没有定义

位置：0.5 降级第 1 步的理由句「本仓库既有七份证据都记录『全部 CTest 通过』」；0.3。

问题：`docs/evidence/` 实测有 **8** 个目录：`cmake`、`completion`、`final`、`linux-gcc`、
`mitigation`、`module3`、`review`、`statistics`。其中 `module3` 只有 `SHA256SUMS` 与
`encoder-arm64.txt`，没有 `README.md`、没有 `record-checks.txt`——既不满足 0.4 的必备清单，
也不带「全部 CTest 通过」的记录。0.3 写「`docs/evidence/` 下已封存的目录」但没说哪些算已封存，
读者无法机械判断 `module3` 是否在只读范围内。

修复：0.3 改为「已封存 = 当前 `main` 上已提交的 `docs/evidence/` 全部目录，实测 8 个：
cmake、completion、final、linux-gcc、mitigation、module3、review、statistics；
其中 `module3` 只有两份文件、不满足 0.4 的清单，属历史遗留，同样只读、**不得**回头补齐」；
0.5 的理由句把「七份」改为「既有带 `ctest.log` 的证据目录（实测 cmake、completion、final、
linux-gcc、mitigation、review、statistics 七份）」。

---

### 13. NIT — M4-7 写死的命令与 6.1 描述的报错文本不是同一条命令的输出

位置：M4-7 的三条命令与随后的「记录含义」；6.1 第 3 条。

问题：6.1 说「`git rev-parse origin/main` 报 `unknown revision`」——这对**不带** `--verify`
的形式成立（本轮实测：`fatal: ambiguous argument 'origin/main': unknown revision or path
not in the working tree.`，且该形式还会先打印一行 `origin/main`）。
而 M4-7 写死的是 `git rev-parse --verify origin/main; echo "exit=$?"`，
实测输出是 `fatal: Needed a single revision`、`exit=128`。
归档时若按 6.1 的描述去核对，会误以为命令跑错了。

修复：M4-7 补一句预期输出：「`--verify` 形式实测输出 `fatal: Needed a single revision`、
`exit=128`（不是 `unknown revision`，那是不带 `--verify` 的形式的文本）；
两种文本任一出现都说明 `origin/main` 不存在，逐字归档实际输出即可」；
6.1 第 3 条注明它描述的是不带 `--verify` 的形式。

---

### 14. NIT — M3-2 没说重放脚本调哪个 `analyze`，也没说比较几份

位置：3.3 的 `tests/test_analysis_round1_replay.sh` 落点规则；M3-2。

问题：脚本只拿到 `$1 = output_root`。设计写死了报告落点
`$1/round1-replay-<name>.report` 与 `rm -f`，但没写被调用的程序路径（其余测试脚本的惯例是
`$1/analyze`，`analyze` 的 `RUNTIME_OUTPUT_DIRECTORY` 实测就是构建根），
也没把「两份归档 CSV → 两次重放 → 两次 `cmp`」的数量写成判据。

修复：3.3 补两句：「程序路径固定为 `$1/analyze`（`analyze` 的
`RUNTIME_OUTPUT_DIRECTORY` 为构建根）；用例固定为两份：
`docs/evidence/statistics/vulnerable.csv` → `round1-replay-statistics-vulnerable.report`、
`docs/evidence/mitigation/hardened.csv` → `round1-replay-mitigation-hardened.report`；
两次 `cmp`（屏蔽 `welch_p=` / `rank_p=` 之后）都必须通过，任一失败即测试失败。」

---

### 15. NIT — M1-5 / M2-7 的分支判据没有给出助记符清单，与内联判据的机械化程度不匹配

位置：M1-5 的判定句；M2-7 的结论范围句。

问题：内联判据已经写死成正则，但「函数体内只有循环边界条件分支，不存在由消息位控制的
`tbz` / `cbz` / `cmp+b.eq` 之类」仍是人工裁量：ARM64 GCC 与 Apple Clang 的循环边界实测分别印作
`b.ne` / `b.ls`（`docs/evidence/linux-gcc/README.md` 的表与
`docs/evidence/mitigation/*-encoder-arm64.txt`），x86_64 GCC 的形式尚未观察。
不写清单的后果是三个人可能给出三种结论。

修复：M1-5 与 M2-7 各加一条口径：「先把该函数反汇编里**所有**条件跳转逐条列出（地址 + 助记符），
再逐条标注归属：循环计数比较（ARM64 实测为 `b.ne` / `b.ls`，x86_64 GNU 侧按实测填写）
判为循环边界；其操作数链可追到 `message_bytes` 取字节/取位的判为消息位相关。
标注依据（上一条影响标志位的指令）必须一并写进 `README.md`；
无法判定归属的条件跳转按 0.5 记为缺口，不得默认算作循环边界。」

---

### 16. NIT — `multiseed-summary.tsv` 的列名与列序没有写死

位置：M3-5；3.5 的文件表。

问题：M3-5 用散文列出九到十列（含两个阈值列与 `prespecified`），生成方式是
`grep`/`awk`，但没有给出表头行。汇总表是模块三对外的主结论载体，列名不定会让
「若按 1e-4 判定」这类派生列难以核对。

修复：M3-5 写死表头（制表符分隔，顺序固定），例如

```text
implementation	seed	prespecified	round1_significant_count	round1_primary_rank_p	round1_alpha_per_comparison	round2_result	round2_rank_p	round2_significant_at_1e-4	mean_difference_ns	effect_size_first_greater	rank_z	category_mean_range_ns
```

并注明 `round1_alpha_per_comparison` 恒为 `0.00010000`、
`round2_significant_at_1e-4` 取值域 `yes|no|na`、动机复采四行的 `prespecified=no` 且排在最后。

---

### 17. NIT — 模块一证据目录会混进另一套构建配置的日志，1.4 没要求说明

位置：1.4 的 `sanitize-ctest.log` 行；1.5 第二条。

问题：1.4 要求 `configure.log` / `build.log` / `ctest.log` 来自 `build/deployable`
（Ninja + RelWithDebInfo，0.2 写死），但 `sanitize-ctest.log` 来自
`ctest --preset sanitize`——实测该 preset 的 `binaryDir` 是 `build/cmake-sanitize`、
生成器继承 `baseline` 的 `Unix Makefiles`、构建类型 `Debug` 且带 ASan/UBSan
（`CMakePresets.json:12,22-29`）。同一目录里放两套配置的日志，而 1.5 只声明
「反汇编结论只覆盖 …`build/deployable` 配置」，没说 sanitize 日志属另一配置。

修复：1.4 的 `sanitize-ctest.log` 行加括注「来自 `build/cmake-sanitize`（`sanitize` preset：
Unix Makefiles / Debug / ASan+UBSan），**不是** `build/deployable` 这一配置；
仅用于功能正确性，不用于任何产物形态或性能结论」；
1.5 加同一句；模块三 3.5 的 `sanitize-ctest.log` 行同样处理。

---

## 已验证的假设（本轮逐条跑过命令）

- `vendor/mlkem-native/mlkem/src/indcpa.c:544` 的 `mlk_poly_frommsg(k, m);` 在
  `mlk_indcpa_enc`（:518 起）内；`grep -rn 'poly_frommsg' vendor/.../src/` 实测该调用点唯一；
  `indcpa.c:627` 的 `mlk_poly_tomsg` 在 `mlk_indcpa_dec` 内。0.6 / M1-5a / M2-7a 的调用者口径正确。
- 内联判据的三个实测计数在 `build/mitigation/{reference,vulnerable,hardened}/measure` 上复现：
  `bl … <_baseline_native_poly_frommsg>` = 1、`bl … <_baseline_native_indcpa_enc>` = 2、
  `grep -cE '(#|\$)0x681|[#$ ]1665\b'` 全二进制 = 1、调用者反汇编 = 0。三者都在情况 1。
- 上游 `mlk_poly_frommsg`（`compress.c:697`）是 `mlk_value_barrier_u8` + `mlk_ct_sel_int16`
  的无分支实现，带 `#if (MLKEM_INDCPA_MSGBYTES != MLKEM_N / 8) #error …` 守卫与
  `mlk_assert_abs_bound(r, …)`；`verify.h:69-70` 在 `MLK_HAVE_INLINE_ASM` 下定义
  `MLK_USE_ASM_VALUE_BARRIER`，`:111` 之后的分支用空 `__asm__ volatile("" : "+r"(b))`，
  否则回退 volatile opt-blocker。1.1 / 0.6 的收窄成立。
- `docs/patches/message-constant-time.patch` 实测删除了 `MLKEM_INDCPA_MSGBYTES` 守卫与
  `mlk_assert_abs_bound`、保留 `noinline`、参数名 `message_polynomial` / `message_bytes`、
  循环变量 `coefficient_index`。1.2 / 1.5 关于「源码形态差别」的表述成立。
- `MLK_CONFIG_DEBUG` / `MLKEM_DEBUG` 在 `include/`、`CMakeLists.txt`、`cmake/`、`src/` 零出现；
  `include/baseline_config.h` 只定义参数集、命名空间前缀 `baseline_native` 与
  `MLK_CONFIG_NO_RANDOMIZED_API`，未定义原生后端开关。0.6 的两条成立。
- `ctest --test-dir build/cmake -N` 实测 13 项；按 `CMakeLists.txt` 的注册结构，
  加 deployable 后为 16、加两个分析测试后为 18、降级后 13 / 15，与 0.2 的表一致。
- `src/analyze.c`：`prespecified_comparisons` 恰 10 项、`ANALYSIS_FAMILY_ALPHA 0.001`、
  `alpha_per_comparison = 0.001/10 = 1e-4`、`comparison_result_label` 四个标签、
  `:649` 的 `fopen(argument_values[2], "wx")`、`is_valid_run_id`（1..64、`[A-Za-z0-9_-]`）、
  `is_valid_implementation_name`（小写 + `-`）、`ANALYSIS_MAXIMUM_RECORDS 200000`。
  3.2 / 3.3 / M3-5 的阈值披露与字段契约有源码依据。
- `rank_sum_test` 用并列修正方差 `pair_count/12 × (N+1 − Σ(t³−t)/(N(N−1)))`、连续性校正
  钳到 0；6.5 的手算（Σ=34950、σ=42.8571、z=−6.9883、p≈2.8e-12）与「分布相同」场景
  （`rank_u1=300.0`、`rank_z=0.0000`、`rank_p=1`、`effect=0.500000`）复算无误。
  打印格式 `rank_u1=%.1f`、`rank_z=%.4f`、`rank_p=%.6g`、`effect=%.6f` 支持 M3-1 挑选的断言。
- `include/inputs.h`：`INPUT_VALID … INPUT_MESSAGE_ONES` 顺序为 0..4、`INPUT_CATEGORY_COUNT 5u`，
  `_Static_assert` 的钉法有依据。
- `src/measure.c` 实测校验：`argument_count != 6` → 用法
  `measure RUN_ID SEED SAMPLES_PER_CATEGORY CSV_FILE META_FILE`、
  `samples_per_category ∈ 1..20000`、RUN_ID 长度 1..64 与 `[A-Za-z0-9_-]`、
  `hash_running_executable` 在 `__APPLE__` 下走 `_NSGetExecutablePath`、其余走 `/proc/self/exe`，
  写出 `executable_digest_algorithm=SHA3-256`。设计选的 5000/2000、`141421356`、
  各 `RUN_ID` 都合法。
- 七份归档报告的主比较数值与 0.6 的表逐字一致（−83.200 / −55.800 / −84.200 / −21.000 /
  +12.600 / +7.800 / +0.800，`rank_z`、`rank_p`、`result`、`significant_comparison_count`
  全部对上）；全部 `n1=n2=5000`、`median_difference_ns=0.0`；缺陷版三次符号一致为负。
- `docs/statistics.md:72`（711–800ns / 0.819–0.844 / |z| 62–67）、
  `docs/statistics.md:84`（「主比较只呈现次级差异」，所在段落 80–85 行，:85 为
  「m' 由私钥参与的解密产生…」）、`docs/evidence/mitigation/README.md:47`
  （「…属于小幅不稳定的次级差异。」）与 `README.md:6-8` 的 CMake 4.3.2 / Ninja /
  RelWithDebInfo / `-O2 -g -DNDEBUG -std=c11` 全部逐字核对通过；
  `reference.meta` 的 `generator=Ninja`、`configuration=RelWithDebInfo`、
  `compiler_flags`、`compile_options` 与设计抄录一致。
- `docs/mitigation.md` 末段确实写着「应去掉函数级优化控制、改用上游的值屏障写法，
  并对该配置重新做反汇编与统计验证」，且 |z|=2.15 / ≤3.61 / 约 400ns 三处数字成立。1.1 的目标定位准确。
- `cmake/PrepareVariant.cmake` 只用 `patch -p1 -i`（无 `--no-fuzz`）；
  `CMakeLists.txt` 的 `foreach(patched_variant IN ITEMS vulnerable hardened)`、
  主 `foreach(variant IN ITEMS reference vulnerable hardened)`、
  `if/elseif` 变体宏链、两处重复的 `equivalence_*` 注册、`SH_EXECUTABLE`、`output_root`、
  `identity_directory = ${CMAKE_CURRENT_BINARY_DIR}/generated/$<CONFIG>`、
  `set_tests_properties(vector_integrity … WORKING_DIRECTORY "${CMAKE_CURRENT_SOURCE_DIR}")`
  全部与 1.2 / 3.3 / M4-2 的落点描述一致。
- `cmake/Format.cmake` 的 glob 覆盖 `src/*.c`、`include/*.h`、`tests/*.c`，
  新增 `analyze_groups.c` / `timing_statistics.c` / `timing_statistics.h` 自动纳入；
  它硬性要求 clang-format 版本匹配 `version 21\.`，本机
  `xcrun --find clang-format` → Xcode 工具链、`--version` = Apple clang-format 21.0.0，M1-4 / M4-3 可执行。
- `tests/vectors/mlkem768.txt` 实测 80 行 = 25 keygen + 25 encap + 10 decap + 10 ekcheck +
  10 dkcheck；`tests/test_equivalence.c` 实测 64 种子 × 3 类输入。M1-2 的覆盖描述正确。
- 四个 `for implementation in reference vulnerable hardened` 的行号
  （`test_cli.sh:6`、`test_measurement.sh:6`、`test_analysis.sh:134`、`test_vector_parser.sh:11`）逐字正确。
- `.gitattributes` 的按需条目分布与 0.4 第 6 条的描述一致
  （`cmake`/`linux-gcc` 为 `*.log`+`*.meta`，`completion`/`mitigation`/`review`/`statistics`
  只有 `*.meta`，`docs/evidence/final/*.txt` 无条目）；
  `docs/evidence/mitigation/` 实测 20 个文件、`SHA256SUMS` 19 行，
  `shasum -a 256 -c docs/evidence/mitigation/SHA256SUMS` 在仓库根目录通过。
- `docs/evidence/final/vulnerable-path-arm64.txt` 实测 2216 行；
  `docs/evidence/completion/` 只有 `reference-encoder-arm64.txt` 一份 encoder 反汇编；
  `docs/evidence/mitigation/` 三份 encoder 反汇编齐全（M1-5 的格式先例成立）。
- `docs/evidence/review/static-analysis.txt` 实测只覆盖
  `src/main.c src/mlkem.c src/random.c src/inputs.c src/measure.c` 与
  `-DBASELINE_VULNERABLE=1`，包含路径为 `-Ibuild/cmake/generated/RelWithDebInfo`。
  M4-2 关于「`analyze.c` 与 HARDENED / DEPLOYABLE 两个宏都是首次」的提示成立。
- 全工作树 `test_seed=777` 零命中（仅本设计文件提到）；`runs/` 五个目录、`.meta` 全为
  `test_seed=42`、`.gitignore` 含 `/runs/` 与 `/build*/`。3.1 的处置前提成立。
- 本机环境：宿主 `openssl dgst -sha3-256` 可用、`ninja` 在 `/Users/yin/.local/bin/ninja`、
  `uvx` 可用、Docker server 29.3.1、`docker buildx ls` 只列平台清单
  （`linux/amd64 (+2), linux/arm64, …`，无 emulated/QEMU 字样，两个 docker driver 节点
  `default` 与 `desktop-linux`）。M2-2 的「不能从标签读出模拟」成立。
- git 状态：`main`、`b53e4e0`、`[origin/main: gone]`、`origin` =
  `https://github.com/Gowin-liuyin/cryProject.git`、局部 `user.name=Gowin-liuyin` /
  `user.email=yinhaoran0808@outlook.com`、`git status --porcelain` 输出 `?? docs/tasks/`。
  0.1 与 M4-7 的前提成立。

## 未验证 / 判定为错的假设

**判定为错（本轮实测与设计文本不符）**

1. **3.3「`load_measurement_set` … 对 `set->records` 整体排序」**：实测排序在
   `src/analyze.c:647` 的 `main` 里，加载函数不排序。见发现 1（HIGH）。
2. **M1-6「`binaries.sha256` 与 `.meta` 的 `executable_digest` 对上」**：算法不同
   （SHA-256 vs SHA3-256），不可能对上；与 0.4 第 5 条、1.4、M2-11 自相矛盾。见发现 2。
3. **1.2「四个脚本的变体循环各加 `deployable`」足以覆盖新变体**：`tests/test_cli.sh` 末尾
   41–44 行另有逐变体硬编码的 `cmp` 块，不在循环内。见发现 3。
4. **0.5「既有七份证据」**：`docs/evidence/` 实测 8 个目录（多出不合 0.4 清单的 `module3`）。见发现 12。
5. **6.1 第 3 条描述的报错文本**：M4-7 写死的 `git rev-parse --verify origin/main`
   实测报 `fatal: Needed a single revision`、`exit=128`，`unknown revision` 是不带
   `--verify` 的形式。见发现 13。
6. **2.4「八个被测产物的副本本身也归档，否则 `binaries.sha256` 没有对象」**：
   既有 `docs/evidence/mitigation/binaries.sha256` 实测对**构建目录路径**算摘要、目录内无副本，
   前提不成立。见发现 9。

**本轮无法验证（设计不应当作既定前提；已确认各有落点者标注落点）**

1. amd64 镜像能否经（或不经）代理装上 `openssl`、容器内 `openssl` 是否支持 `sha3-256`
   —— 落点 M2-11 主/备两路线 + 0.5 缺口；另见发现 6 的代理参数。
2. QEMU 模拟下配置、构建与全部 CTest 能否在可接受时间内完成 —— 落点 M2-5；
   但失败时的证据可得性受发现 4 影响。
3. GCC 13 是否内联 deployable 编码器、`0x681` 在 GNU objdump / x86_64 下的实际印法
   —— 落点 M2-7a（含「三种印法都不命中时不得读成无内联」）。
4. Apple Clang 21 是否内联无属性的 deployable 编码器（产物尚不存在）—— 落点 M1-5a 的四种组合分流。
5. 新补丁能否过 `-Wall -Wextra -Wpedantic -Wshadow -Wconversion -Wstrict-prototypes -Werror`
   —— 落点 0.2 的必要检查与 M2-4；另见发现 11。
6. 容器内 GNU patch 2.7.6 是否会以 fuzz 应用补丁 —— 当前**无落点**，见发现 5。
7. 种子 777 的三个口头复核 p 值（0.923 / 0.844 / 0.516）—— 已定为「未归档、不可复现，只作动机」，
   另有可复现的动机复采并列呈现。
8. 模块三证据目录约 30MB 的估算（20 份 25000 行 + 4 份 10000 行）—— 落点 3.5 的 `du -sh` 实测值。
9. `uvx --from cmakelang==0.6.13 cmake-format` 能否在无网络时运行 —— 落点 M4-3；
   本轮只确认 `uvx` 存在，未拉取该版本。
10. 容器内 `clock_getres(CLOCK_MONOTONIC)` 的实测值（先例 `linux-gcc` 为 1000000ns）
    —— 落点 M2-3；无论多少都不改变 M2-1。
