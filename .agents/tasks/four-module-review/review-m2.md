# 模块二评审：QEMU 模拟 linux/amd64 下的 x86_64 产物形态验证

单个 `docs:` 提交 `c1ea9ca`，无代码改动，新增证据目录 `docs/evidence/linux-amd64/`（27 个文件）、
`docs/validation.md` 追加一节、`.gitattributes` 增三条 `whitespace=-blank-at-eol`。内容是在
`docker run --platform linux/amd64`（Apple Silicon 上的 QEMU 用户态模拟）+ 真实 GNU GCC 13.3.0
容器里，对模块一的干净提交 `343a6cb` 做配置、构建、`ctest`、四变体反汇编、调用路径核对与独立摘要对照，
只闭合「产物形态与功能构建」，明确不闭合时序。设计口径由模块零提交 `adf9db9` 预先固定在
`docs/tasks/four-module-design.md` 第 2 节，本模块未改动该文件。

**Watch for：** README 第 2 步把条件跳转总数写成「八条」，实测是七条（confirmed，纯计数口误，
逐条枚举与归属本身完整正确）；M2-2 要求的宿主 `docker version` **全量**输出只以散文摘要出现、未逐字归档
（confirmed，我对照本机实测，五项数值全部正确）；容器驱动脚本在 README 里带两处 `...` 省略，
逐字全文不在证据中（confirmed，与设计骨架同形，不是契约违规）。模块一遗留的 fail-open 风险
（判据正则丢 `\$` 转义）在本模块**已闭合**，并有可验证的证据。

**Verdict**: APPROVED

## High-level view

「这是模拟」不靠 `docker buildx ls` 的标签（该输出没有 emulated/QEMU 字样），而是宿主 `uname -m`=arm64、
容器 `uname -m`=x86_64、无原生 amd64 节点、容器 `/proc/cpuinfo` 为宿主 ARM64 字段四条并列，再加两条本轮
自查的硬证据：`binfmt_misc` 注册的解释器实测为 `/usr/bin/qemu-x86_64`，容器内 `libc.so.6` 映射在
`0xffff847ec000`（x86_64 非规范地址）。Rosetta 关闭这一条我在 Docker 设置里独立确认，排除 Rosetta 成立。

时序被完整隔离：四份 `.meta` 之外没有 CSV、没有 `.report`、没有任何统计字段，`analyze` 未运行，
`ctest` 的 6.53 秒被明写为「不是任何性能或时序结论」，`clock_getres` 实测 1ms 照实写出而不作辩解。

产物机制结论可复算。我用另一套反汇编器（宿主 LLVM objdump）对容器留在 `/tmp/linux-amd64-build` 的八个
产物重做了全部关键计数与跳转枚举，逐项与归档件相同：编码函数共 7 条条件跳转 + 3 条无条件 `jmp`，
`indcpa_enc` 调用点四变体均为 2，`poly_frommsg` 调用点 1/1/1/0，判据正则全二进制计数 1/1/1/2。

模块一评审的首要风险在本模块闭合。模块一执行的正则丢了 `\$` 转义，对 GNU x86_64 的 `$0x681` 会漏命中
（fail-open）；本模块记录的是带转义的形式，而且这不是自述——命中行与三个非 deployable 变体的唯一落点
全是 `$0x681` 印法，用破损形式这四个数字会变成 0。

deployable 的判定对作者不利且被保留：`poly_frommsg` 调用点为 0，离线符号副本被声明「不构成产物证据」，
结论对象改为内联段，结论边界单列「四个变体的产物形态不能并列成一张等价的表」，没有加回 `noinline`
换取独立符号。

缺口小节写「无」这次成立：53 个退出码逐项落盘，无失败需要降级。代价是脚本逐字全文没有进证据，
省略段只能从 `verification.log` 的小节标题与 `record-checks.txt` 反推。

<details>
<summary>Issues (5)</summary>

1. **条件跳转计数口误** — README 第 2 步写「上表八条条件跳转全部有可追踪的操作数链」，实测为七条
   （reference 2、vulnerable 2、hardened 1、deployable 离线副本 1、deployable 内联段 1）。
   归属表七行本身完整正确；按 0.3 本目录已封存，留给后续模块引用时按实测数。
2. **宿主 `docker version` 未逐字归档** — M2-2 要求逐字记录宿主 `docker version` 全量输出，README 只给了
   散文摘要（客户端 29.3.1/darwin/arm64、服务端 Docker Desktop 4.67.0 (222858)、引擎 29.3.1/linux/arm64、
   containerd v2.2.1、runc 1.3.4）。我对照本机实测五项全对。后续模块若再引用宿主工具链，把全量输出落盘。
3. **容器驱动脚本逐字全文未归档** — README 的取证命令块含 `...（平台事实、cpuinfo）` 与
   `...（产物前置条件硬失败检查、M2-6、冒烟采集、M2-7、M2-7a、M2-8、M2-11）` 两处省略，设计骨架同样是省略形式，
   因此不是契约违规；但读者无法逐字重放。模块三/四把完整驱动脚本作为证据文件归档。
4. **另三个变体全二进制反汇编仍未归档** — 只有 `deployable-path-amd64-gcc.txt` 入库（设计 2.4 的要求），
   reference/vulnerable/hardened 的调用点与特异性计数只能靠 `call-site-counts-amd64.txt` 的逐字 grep 输出。
   本次我能用 `/tmp/linux-amd64-build` 的残留产物复算出同样的 2/1/1、1/1/1，但 `/tmp` 会被清理、不在仓库内，
   未来只剩转录值。与模块一同一条遗留项，非本模块新引入。
5. **内联成因的因果表述偏松** — README 写「deployable 按设计不带任何 `__attribute__`（含 `noinline`），
   内联是预期后果」。reference 的上游编码器同样不带任何 attribute，GCC 却**没有**内联它（调用点计数 1），
   所以「没有 noinline」本身不构成内联的原因（真正的差别是补丁后函数体更小）。结论不受影响——
   判定依据是实测的调用点计数 0，不是这句推理。

</details>

<details>
<summary>Details</summary>

### 模拟论证的两条额外硬证据与我的核对范围

```
binfmt_misc/x86_64 → interpreter /usr/bin/qemu-x86_64      ← amd64 ELF 由 QEMU 解释执行
/proc/self/maps    → libc.so.6 @ 0xffff847ec000            ← x86_64 非规范地址，ARM64 宿主布局
```

`0xffff847ec000` 落在 x86_64 的非规范空洞（用户态上限 `0x00007fff_ffffffff`），同时正是 aarch64 48 位
用户空间的高端布局，论证成立。两条都被标注为「宿主侧独立探测，不属于下面那次归档容器运行」，
没有混进单次运行的日志里冒充同源证据。我独立复核了
`~/Library/Group Containers/group.com.docker/settings-store.json` 的
`"UseVirtualizationFrameworkRosetta": false`，以及 `docker buildx ls`、`cpuinfo.txt` 与归档表格逐行一致。

这两条自查证据本身依赖一次 `--privileged` 容器探测，按指示我没有重跑；它们只支撑「是模拟」这个对作者
不利的方向，不支撑任何有利结论。

### 条件跳转枚举与归属：用第二套反汇编器逐条复算

我用宿主 LLVM objdump 对 `/tmp` 残留产物重做同一枚举，地址、助记符与编码字节逐条与归档件相同，
一条不多一条不少：

```
reference : 46c9 jne          46d8 jne
vulnerable: 2ff7 jmp  301f je 302e jmp  3048 jbe
hardened  : 2ff7 jmp  304b jbe
deployable: 46cd jne（离线副本）   6076 jne（内联段 0x6020–0x6076，区间内唯一跳转）
```

关键归属链我按归档反汇编逐条回溯：

- vulnerable `0x301f je` 判为**消息位相关**：`test %eax,%eax` ← `and $0x1,%eax` ← `sar %cl,%edx`
  （`%cl` 来自 `and $0x7` 的 `coefficient_index & 7`）← `movzbl (%rax)`，`%rax` = `-0x20(%rbp)`
  （`0x2fec` 存入的第二个参数）+ `shr $0x3` 的字节下标。两条分支分别写 `$0x681` 与 `$0x0`。
- deployable 内联段 `0x6076 jne` 判为**循环边界**：`cmp $0x100,%rdx`，`%rdx` 由 `0x6020 xor %edx,%edx`
  起始、`0x606b add $0x1,%rdx` 递增；消息字节在 `0x6056 and (%r11,%rcx,1),%al` 取入，`%r11` 来自
  `0x5fc5 mov %rsi,%r11`。我在 vendor 源码核对了 `mlk_indcpa_enc(c, m, pk, coins, context)` 的形参顺序，
  SysV ABI 下 `%rsi` 确实是 `m`，该标注正确；此后只流向 `movzbl → neg → sar $0x10 → and $0x681 → mov`
  的算术链，不被任何条件跳转消费。
- 循环边界助记符按设计要求实测后填，记为 `jne`（`-O2` 的 reference/deployable）与 `jbe`
  （vulnerable/hardened，比较写成 `cmpl $0xff`）。我在 `docs/patches/` 核对了这两个补丁确实带
  `__attribute__((optimize("O0"), noinline))`，deployable 补丁无 attribute。

三条无条件 `jmp` 的标注（循环入口、if/else 汇合）与 O0 下的 while 结构吻合，模块一在 ARM64 上那两处误标
没有重演。唯一偏差是第 2 步末尾的总数：七条写成「八条」，归属表七行各自有依据，这个数字不支撑任何结论。

### 内联判据正则：模块一的 fail-open 风险已闭合，且闭合可验证

模块一执行的形式 `(#|$)0x681|[#$ ]1665` 丢了 `\$` 与 `\b`——GNU grep 把 `)` 前的 `$` 当行尾锚，于是
GNU x86_64 的 `$0x681` 永远漏命中，真有内联副本时会误报「无内联」。本模块
`call-site-counts-amd64.txt` 首行记录 `judgement_regex_as_passed_to_grep=(#|\$)0x681|[#$ ]1665\b`。

这不止是自述，归档的命中证据本身排除了破损形式：deployable 调用者命中行是 `74: 6062: and $0x681,%ax`，
另三个变体全二进制计数 1 的落点是 `46bd: and $0x681,%ax`、`3028: movw $0x681,(%rax,%rdx,2)`、
`302f: and $0x681,%ax`——全是 `$0x681` 印法，没有 `#0x681`、也没有十进制 `1665`，用模块一的形式这四个
数字必然是 0。我在归档件上重跑带转义的正则，得到同样的 0/0/0（三变体调用者）与 1/1/1/2（全二进制），
并用 LLVM objdump 对真实产物复算一致。

README 另按 M2-7a 写明「`0x681` 的 GNU/x86_64 实际印法本次实测为 `$0x681`，正则的 `\$0x681` 分支命中，
无需扩充正则，也没有落入三种印法都不命中的情形」，即没有把未命中读成无内联的空间。

### deployable 落情况 2：不利判定被保留，粒度差异写进结论边界

四变体 `grep -c 'call.*<baseline_native_indcpa_enc>'` 均为 2，调用者层级一律取 `indcpa_enc`，
无一需要退到 `dec`——与设计写死的层级规则一致，也与 vendor 源码里 `mlk_poly_frommsg(k, m)` 是
`mlk_indcpa_enc` 内唯一调用点、解封装经重加密到达该函数的事实吻合。

deployable 的 `poly_frommsg` 调用点为 0，判为情况 2。处置落在对作者不利的那一边且完整保留：
`deployable-encoder-amd64-gcc.txt` 被声明为「离线副本、未被调用、不构成产物证据」，结论对象改为内联段
（第 55–78 行）；第 1 步表格按「离线副本（未被调用）/ 内联段（实际执行）」分行标注；结论边界单列
「四个变体不能并列成一张等价的表」。特异性对照同时给出：deployable 全二进制计数 2 的两处落点逐处写明
（一处在从未被调用的离线副本、一处在内联段），另三变体计数 1 且调用者命中 0，说明判据不是只对
deployable 放宽。与模块一 ARM64/Apple Clang 的同一结论被明写为「两次独立实测，不是互相套用」。

### M2-11 摘要链：我在宿主独立复算了 12 个摘要

走的是主路线（容器内 `openssl dgst -sha3-256`），没有用 SHA-256 冒充同算法对照。我对容器留在
`/tmp/linux-amd64-build` 的八个产物重算：

```
shasum -a 256  八行  == binaries.sha256 的八行摘要列（diff 为空）
openssl dgst -sha3-256  四个 measure == binaries.sha3-256 == 四份 .meta 的 executable_digest
file cmake/*/measure → ELF 64-bit LSB pie executable, x86-64
```

容器内与宿主两侧 `shasum -a 256` 的逐行一致性核对在 `record-checks.txt` 里，钉住「两侧看到的是同一份
文件」；二进制副本未拷进仓库，与 `docs/evidence/mitigation/binaries.sha256` 同口径。`SHA256SUMS` 26 行
覆盖其余 26 个文件、不含自身，我在仓库根目录跑 `shasum -a 256 -c` 全部 OK。

`record-checks.txt` 把 0.4 第 6 条的 `git diff --cached --check` 两次输出都写了下来：补 `.gitattributes`
之前 757 行 trailing-whitespace 警告（按文件分布 + 前 24 行逐字 + 复现命令），补条目之后为空、`exit=0`。
警告来源被查清是机器输出本身（x86_64 objdump 折行续行、`.meta` 的空 `link_flags=`、CMake 的
`Found Git ... ` 尾随空格），没有去格式化证据文件；比预期多一条 `*.txt` 条目的原因也如实写出。

### 失败容错骨架、53 个退出码与脚本逐字缺口

骨架按设计用 `set -u` 而非 `set -eu`，只保留两处硬失败（配置失败、进入反汇编前八个产物缺失），
其余步骤「记录退出码后继续」，反汇编与摘要排在 `ctest` 之后但不依赖其退出码。53 行退出码我逐类点过数，
与 README 缺口小节的逐项引用（四个 version、四个 selftest、十三个 objdump、八个 + 八个摘要）完全对得上；
五类判据 `grep` 全为 1（无匹配即通过）。因此「未能完成的项：无」成立，并且同一小节仍重申「真实 x86_64
Linux 主机上的时序采集与固定检验仍未执行」不因本目录改变。

缺的是脚本逐字全文：README 取证命令块保留了设计骨架的两处 `...` 省略，`verification.log` 只留小节标题
与未重定向的输出。省略段可从 `record-checks.txt`、`call-site-counts-amd64.txt` 与 README 给出的
`objdump`/`grep` 命令反推，但不是逐字重放。

### 时序证据的隔离

四份 `.meta` 之外没有 CSV、没有 `.report`。我确认四个 `*-smoke.csv` 只存在于 `/tmp/linux-amd64-build`，
没有进仓库；`.meta` 里除 `sample_count=250`、`warmup_decapsulations=100` 这类来源字段外没有任何统计量
（`mean`/`rank_z`/`outlier` 一律不存在）。`clock_resolution_ns=1000000` 照实写出并明说「无论这个值是多少，
都不改变开头那条声明」；`ctest` 的 6.53 秒被两次标注为非性能/时序结论。`docs/validation.md` 的追加节
同样以「QEMU 模拟、绝不闭合时序」开头收尾，并重复「QEMU 模拟、容器、交叉编译、macOS/ARM 都不得表述为
真实 x86_64 Linux 实测」。

### 只读边界与仓库污染

提交只触及新建的 `docs/evidence/linux-amd64/`、`.gitattributes`（纯新增三行）与 `docs/validation.md`
（纯追加一节，旧节未改写）。`vendor/`、`tests/vectors/`、既有八个证据目录、`cmake/`、`src/`、`docs/patches/`
在本提交零命中——源码以 `:ro` 挂载，构建输出全部落在 `/build` = 宿主 `/tmp/linux-amd64-build`（仓库之外），
`record-checks.txt` 第 6 节记录运行后宿主 `git status --porcelain` 为 `?? .agents/`，当前实测同样如此。
提交在 `main`、作者与提交者均为 `Gowin-liuyin <yinhaoran0808@outlook.com>`、`main` 无上游跟踪（未 push）。
`.meta` 的 `git_worktree_status` 为 `?? .agents/`、`tracked_delta_sha256` 是空内容摘要，即取证时被跟踪
文件无未提交改动。

### 功能结果与范围限定

38 条编译命令我逐条检查，全部带 `-Wall -Wextra -Wpedantic -Wshadow -Wconversion -Wstrict-prototypes
-Werror`，`build.log` 的 `warning:` 扫描为空，所以「零警告」成立、M2-4 不需要 `fix:` 提交。
`ctest -N` 16 项、`--output-on-failure` 16/16 通过，含 `deployable_kat`、`deployable_random_failure`、
`equivalence_deployable`，QEMU 下未出现失败或超时，没有缩减样本或跳过测试。M2-4a 两次 fuzz 门禁我在
归档副本上复跑得到同样的空输出（`exit=1`），`build.log:4-6` 三行均为 `patching file mlkem/src/compress.c`。
便携 C 后端限定我按 `compile_commands.json` 复核：无 `native/x86_64` 源文件、无 AVX2 选项、
无 `MLK_CONFIG_USE_NATIVE_BACKEND`、无任何 `-m` 架构选项，三个补丁变体的 `-I<变体>-source/mlkem` 排在
vendor 之前（实测下标 77 < 137），即链接的是构建目录里的补丁副本。生成器为容器内默认 `Unix Makefiles`，
与模块一、三的 Ninja 不同，README 明写地址不跨构建复用。

`cpu_model=unavailable` 照实记录，并明说这不能证明真实 x86_64 主机上 `read_cpu_model` 的行为
（真实 x86_64 有 `model name` 字段，本次没覆盖那条路径），符合 M2-9 的「不预设」口径。

</details>

<details>
<summary>File map</summary>

| 文件 | 本次变更 |
|---|---|
| `docs/evidence/linux-amd64/README.md` | 新增 427 行：M2-1 声明、模拟论证、工具版本、构建配置抄录、复现命令、构建与测试结果、M2-7 四步跳转表、M2-7a 调用路径核对、M2-11 摘要核对、结论边界、未能完成的项 |
| `verification.log` | 宿主 `tee` 的单次容器运行输出（平台事实、cpuinfo、ctest 摘录、四变体 version/selftest/冒烟、`.meta` 关键字段、摘要、step-exits 全文） |
| `step-exits.txt` | 53 个被判定步骤的实测退出码 |
| `configure.log`、`build.log`、`ctest-list.log`、`ctest.log` | 配置、构建、`ctest -N`（16 项）、`ctest --output-on-failure`（16/16）逐字输出 |
| `compile_commands.json` | 容器内构建产生，38 条编译命令 |
| `{reference,vulnerable,hardened,deployable}-encoder-amd64-gcc.txt` | 四份编码函数 x86_64 GCC 反汇编 |
| `{...}-caller-indcpa-enc-amd64-gcc.txt` | 四份 `baseline_native_indcpa_enc` 反汇编（deployable 的第 55–78 行即内联段） |
| `deployable-path-amd64-gcc.txt` | deployable 全二进制反汇编 6751 行（另三变体按设计不归档） |
| `call-site-counts-amd64.txt` | 判据正则（含 `\$` 转义）、四变体两类调用点计数与地址、调用者/全二进制正则结果、编码函数全部 `j*` |
| `{...}-smoke.meta` | 四份冒烟元数据，`RUN_ID=smoke-<variant>`、`clock_resolution_ns=1000000`、`cpu_model=unavailable`；无统计字段 |
| `cpuinfo.txt` | 容器内 `head -20 /proc/cpuinfo`（ARM64 字段、无 `model name`） |
| `binaries.sha3-256` / `binaries.sha256` | 容器内 SHA3-256 八行 / 宿主 SHA-256 八行（对象为 `/tmp` 构建目录产物，无二进制副本入库） |
| `record-checks.txt` | M2-11 摘要对照、两侧 SHA-256 一致性、fuzz 门禁两次、零警告、便携后端、宿主 `git status`、`git diff --cached --check` 两次 |
| `SHA256SUMS` | 26 行，覆盖本目录其余全部文件、不含自身，`shasum -a 256 -c` 实测全部 OK |
| `docs/validation.md` | 追加「x86_64 指令集下的产物形态（QEMU 模拟）」一节，旧节未改写 |
| `.gitattributes` | 为本目录新增 `*.log` / `*.meta` / `*.txt` 三条 `whitespace=-blank-at-eol` |

完整 diff：`git -C /Users/yin/code/cryProject show c1ea9ca`

</details>
