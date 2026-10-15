# T18 / R06 日志·异常·返回码泄露专项审计（2026-10-16）

对象：本工程自有实现（`src/`、`include/`、`tools/`、`tests/`、`fixtures/`、`scripts/`）与本轮平台 harness。
基线提交：`e81c1aee541f5e9c2f93e061c8a5b5fa923c749d`（`main`）。
审计问题：进程是否通过**日志、异常、返回码/退出码、errno、stdout/stderr** 泄露**秘密**
（共享密钥 `ss`、私钥 `sk`/拒绝种子 `z`、内部消息 `m'`）或**"验证是否通过"这一内部结果**
（重加密比较位 / 接受-拒绝分支）。

**本审计不构成恒时证明，也不主张"零泄露"。** 它只给出本轮固定代码快照、固定工具链与固定命令下
的可观察面描述；未覆盖面见 §6。所有实跑均为**非锁频、仅功能性检查**（`frequency_control=not_configured`，
调速器 `powersave`），不代表计时结论。

---

## 0. 结论摘要

| 项 | 结果 |
|---|---|
| 静态扫描 | 128 个 C 源/头文件（`src` 47、`include` 16、`tools` 20、`tests` 33、`fixtures` 10、`scripts` 2）；命中 1048 个"可能送出进程边界"的调用点；机器分类出 **122 个接触秘密相关标识符**的调用点，逐条人工判定见 §1 |
| **秘密内容泄露** | **0 条**：没有任何把 `ss`/`sk`/`z`/`m'` 的字节写进 stdout/stderr/返回码/errno 的语句；输出语句参数里**没有**秘密标识符（多行语句也按整句判定） |
| **"验证是否通过"泄露** | **1 条**（低危、需处理）：`tools/platform_m2/collector.c` 的功能门把 `chosen_message_accept_mismatch_count` / `failed_decapsulation_count` 汇总后写进 **stderr、进程退出码和 meta 的 `run_status`**（见 §1.3 F1）。它是**每批调用级别**的接受/拒绝汇总，不是逐调用的比较位 |
| 动态 diff | **为空**。7 种输入模式（1 合法 + 6 隐式拒绝）× 各 120 次，本机（macOS/ARM）与远端（x86_64 Linux）两次独立运行：7 个模式的退出码唯一值均为 `0`，stdout/stderr **逐字节一致**；`diff -u` 0 个差异块（§2） |
| Memcheck syscall 检查 | **未发现"秘密作为 syscall 参数"**。M5 `platform_m5_poison --poison`（1152 B PKE 秘密 + 32 B 拒绝种子标记）Valgrind 3.22.0 下 `ERROR SUMMARY: 0 errors`，`--track-origins=yes` 复跑同为 0；负对照 canary 能稳定报出 `Syscall param write(buf) points to uninitialised byte(s)`（rc=99），证明该通道有效（§3） |
| 计时窗口 I/O | **窗口内无 I/O/日志/分配**。7 个 fence-to-fence 窗口全部通过白名单核对；I/O、分配、结果消费都在窗口外（§4） |
| 阻塞 | 无。远端与主控并发任务无冲突；未使用 sudo，未写 `/tmp`，未使用 CPU2/CPU6 |

---

## 1. 静态扫描

### 1.1 覆盖范围与命令

```sh
# 覆盖：自有实现 + harness；排除 vendor/、sources/、deliverables/ 内的封存副本
cd <repo> && find src include tools tests fixtures scripts -type f \( -name '*.c' -o -name '*.h' \) \
  | LC_ALL=C sort > static/scanned-files.txt          # 128 个文件
python3 src/r06_static_classify.py < static/scanned-files.txt > static/call-sites.tsv
```

分类器先把注释与字符串字面量剥离、按函数体切分语句（多行 `printf` 作为一条），
再用"秘密相关标识符集合"判定该语句是否接触秘密。关键词明细另存：
`static/grep-raw.txt`（1640 行原始命中）、`static/secret-identifier-hits.txt`（668 行秘密标识符出现位置）。
扫描口径是上列六个目录下的**全部** `.c`/`.h`，包含 `tools/platform_perf/`、`tools/platform_optlevel/`
这类尚未接入构建的新增件；**未**扫描 `vendor/`、`sources/`、`third_party/` 上游快照，
未扫描 `build/`、`deliverables/`、`docs/evidence/` 内旧封存副本（后者不属于本轮对象）。

| 目录 | 扫描文件 | 调用点 | 其中接触秘密相关标识符 |
|---|---:|---:|---:|
| `src/` | 47 | 227 | 31 |
| `include/` | 16 | 0 | 0 |
| `tools/` | 20 | 121 | 40 |
| `tests/` | 33 | 679 | 45 |
| `fixtures/` | 10 | 9 | 6 |
| `scripts/` | 2 | 12 | 0 |
| **合计** | **128** | **1048** | **122** |

### 1.2 122 个"接触秘密相关标识符"调用点的判定表

判定分四类。**A 类 = 秘密内容泄露；B 类 = 验证结果泄露；C 类 = 只打印路径/字节数/摘要；D 类 = 命名误报。**

| 类 | 数量 | 判定理由 | 代表条目（文件:行） |
|---|---:|---|---|
| **A：秘密内容泄露** | **0** | 没有任何语句把秘密缓冲区的字节作为输出实参 | — |
| **B：内部验证结果泄露** | **1** | 退出码/stderr/meta 携带"接受路径是否一致"汇总 | `tools/platform_m2/collector.c:735-742`（见 F1） |
| **C：只打印公开派生量** | 67 | 打印路径、字节数、行数、耗时、SHA3-256/摘要、公开类别名、公开测试种子、构建身份；不含密钥字节 | `tools/platform_m2/collector.c:484-500`（`public_key_path`/`public_key_bytes`/`public_key_sha3_256`/`secret_key_path`/`secret_key_bytes`/`secret_key_sha3_256`/`input_sequence_digest`/`executable_sha3_256`）、`tools/platform_m2/keypair_tool.c:75`（"secret key write failed" 只报失败）、`tools/platform_m2/collector_selftest.c:238`（公开 `key_seed`）、`tools/platform_m4/measure.c:202,219`（公开类别标签与公开夹具期望计数）、`tools/platform_m5/poison.c:106`（标记字节数） |
| **D：命名误报** | 54 | 命中的标识符与秘密无关：`rank_z`/`rank_z_score`（秩统计）、`rejection_sampling`（SplitMix64 拒绝采样）、`is_preimported`、`stopped_digest_mismatch`（文件摘要核对）、`secret_attribution=not_assessed`（结论字段）、`no_secret_synthetic`（来源类型）、`secret_conditional_branches`（机制计数）、`files_equal`（证据文件比对）、`accept()`（socket 系统调用）、`memcmp`（公开向量/文件比对）、`assert` 的整型条件 | `src/analyze.c:128`、`src/analyze_paired.c:340`、`src/attribution_v3_run.c:448`、`src/audit.c:294`、`src/mechanism_audit.c:1016,1156`、`src/network_server.c:99,103`、`tests/*` 中的 `assert`、`fixtures/*` 人工缺陷夹具 |

**关于"摘要而非原文"的边界**：M2 采集件的 meta 里有 `secret_key_sha3_256`（对 sk 的 SHA3-256）。
它在密码学上不可逆，但**是一个离线校验值**：若攻击者对 sk 的生成随机性有低熵猜测，
可用它确认猜测。本轮夹具 sk 由公开种子确定（见 §5），因此不构成新泄露；
但它属于"可校验派生值"，在真实密钥场景下应重新评估（见 §1.4 建议 R3）。

### 1.3 发现项

#### F1（低危，建议处理）M2 采集件把"接受路径一致性"汇总写进 stderr 与退出码

- 位置：`tools/platform_m2/collector.c:735-742`（stderr + 非 0 退出）、`:504-510` / `:523-526`（meta 字段与 `run_status`）。
- 语句：

  ```c
  if (failed_decapsulation_count != 0 || accept_mismatch_count != 0) {
      fprintf(stderr, "functional gate failed: failed_decapsulations=%" PRIu64
                      ", accept_mismatches=%" PRIu64 "\n", ...);
      goto cleanup;                       /* → 进程退出码非 0 */
  }
  ```

- 为什么算"接触内部结果"：`accept_mismatch_count` 由 `memcmp(row_secret, expected_secret, 32)`
  在 **message-zero / message-ones 类**上累加（`:707-714`）。`expected_secret` 由
  `m2_collector_build_ciphertext` 用选定消息经上游确定性加密重新导出（`tools/platform_m2/collector_inputs.c:66-75`）。
  两者在"内层重加密比较通过"时应逐字节相等；因此该计数**携带了内层重加密比较的通过/失败信息**，
  并被映射到**进程退出码**、**stderr 文本**与 **meta 的 `run_status=failed`**。
- 影响面：只在门失败时可见，且是本批所有行的**汇总**（不逐行、不逐类、不含位置）。
  但"同一批输入在不同实现/不同构建下退出码不同"本身就是一个可观察的接受-拒绝信号，
  与工程约定"错误状态不得泄露内部验证结果"存在张力。
- 动态验证：正常路径下三种不同密文类（含隐式拒绝类）在同一夹具上 rc 恒为 0、stderr 恒为空（§2.3），
  因此该发现**不会在正常采集时被触发**；它描述的是门失败时的可观察面。
- 建议（R1）：把门失败信息降级为**不含计数的**固定文本，并把计数只写进**调用方指定的 meta 文件**；
  或者让退出码只表示"参数/资源/IO 错误"，把功能门结果完全放在文件里，由离线分析读取。
  任何修改都必须重新跑 §2 的动态 diff 与 §3 的 Memcheck。

#### F2（信息）M3 `on` 变体在秘密标记下报 1280 个未初始化使用错误，但**不流向 syscall 参数**

- 本轮实跑（`memcheck/remote/m3-on.valgrind.log`）：`ERROR SUMMARY: 1280 errors from 2 contexts`，
  两条上下文都在 `baseline_native_poly_frommsg`（`compress.c:714`）← `indcpa_enc` ← `dec`，
  即人工植入的"数据相关访存"缺陷本身；`on` 的 `--defined` 对照与 `off` 的 `--secret` 对照均为 0 错误。
- 与已有证据一致：`docs/evidence/m3-completion-20261016/native-8b6f2d91/on-secret.memcheck.log`
  同样是 `1280 errors from 2 contexts`（独立复现成立）。
- 判定：**未发现 `Syscall param` 类错误**——标记过的秘密没有作为 syscall 参数交给内核。
  这正是"缺陷存在但不通过日志/返回码泄露"的分离结论；缺陷本身由 M3 的定位结论负责，不归本轮。

#### F3（信息）`tools/platform_perf/perf_measure.c` 未接入构建

该文件不在任何 `CMakeLists.txt`/`cmake/*.cmake` 目标的依赖里，因此**不在任何正式产物**中。
本轮仍把它纳入扫描与窗口检查（0 条秘密接触、窗口干净），以免"未接入"变成扫描盲区。

#### F4（信息）人工缺陷夹具 `fixtures/early_reject_memcmp/binsec_harness.c:13`

`exit(is_equal);` —— 把比较结果作为进程退出码，这是**故意保留的实验缺陷**（BINSEC 早退比较定位夹具），
不在正式产物路径上。列出以避免读者误以为扫描遗漏。

### 1.4 未在输出语句中出现的复核（补充机械检查）

```sh
# 输出调用与秘密标识符同一行（含多行语句由分类器另行覆盖）
grep -rnE '(printf|fputs|puts|fprintf|snprintf)[^;]*\b(shared_secret|decapsulation_key|secret_key|row_secrets|expected_secret|m_prime|decapsulated_secret)\b' tools/ src/
grep -rnE '(printf|fputs|puts|fprintf|snprintf)[^;]*\b(is_equal|compare_status|decapsulation_status|accept_mismatch|failed_decapsulation|verification)\b' tools/ src/
grep -rnE '\b(exit|_exit)\s*\([^)]*\b(is_equal|status|mismatch|reject)' tools/ src/ tests/ fixtures/
```

结果：前两条 0 命中；第三条只命中 F4 的人工夹具。`fwrite`/`write`/`syslog`/`perror` 的使用已逐处核对：
`src/main.c:25` 写的是**公开密文**，`src/network_client.c:154` 写的是**公开 ack**，
`tools/platform_m2/keypair_tool.c:23` 写的是**调用方指定的密钥文件**（工具的本职，不算日志泄露），
`tools/platform_m5/dudect.c:211` 的 `perror("dudect raw output")` 只报打开失败。
`errno` 在六个目录中共出现 52 处（含 `#include <errno.h>`），全部是参数解析（`strtoull` 后判 `errno`）
与 `EINTR` 重试，不承载秘密或验证结果。

---

## 2. 动态 diff（合法密文 vs 隐式拒绝密文）

### 2.1 方法

- 探针（本轮新增件）：`src/r06_observable_probe.c`（源码在库，可重建）。
  只调用公开入口 `generate_test_key_pair` / `generate_test_ciphertext` / `mlkem_decapsulate`；
  **输出语句不含任何按输入类别分支的文本**，只打印 `calls_completed=<n>`；
  结果只累加到 `volatile` sink，不参与输出。
- 7 种模式（`R06_MODES`）：`valid`（合法）与 6 种隐式拒绝
  （`bit-flipped`、`random`、`message-zero`、`message-ones`、
  `malformed-zero-tail`、`malformed-ff-tail`；后两种与 M2 采集件的对照类同口径：
  message-zero 密文末 32 字节置 `0x00`/`0xFF`，长度仍为合法 1088 B）。
  注：`message-zero`/`message-ones` 在**本探针的调用链**里是接受路径（chosen-message 成功解密），
  在 **M2 采集件**里是"期望接受"类；两者都保留，以便对照组不只覆盖一种路径。
- 每个模式 **120 次**进程调用；每次记录：退出码、stdout 逐字节、stderr 逐字节。
  汇总为每个模式的"退出码唯一集合 / stdout SHA-256 唯一集合 / stderr SHA-256 唯一集合"，
  再以 `valid` 为基准与其余每个模式做 `diff -u`。

### 2.2 结果：diff 为空

两次独立运行（本机 macOS/ARM 与远端 x86_64 Linux），`diff/matrix.tsv` 与 `diff/remote/matrix.tsv`
**逐字节相同**（SHA-256 `1de9f37c…`），`diff-results.txt` 亦相同（`b3bf976d…`）：

| 模式 | 次数 | 退出码唯一集合 | stdout SHA-256 唯一数 | stderr SHA-256 唯一数 |
|---|---:|---|---:|---:|
| valid | 120 | `{0}` | 1 | 1 |
| bit-flipped | 120 | `{0}` | 1 | 1 |
| random | 120 | `{0}` | 1 | 1 |
| message-zero | 120 | `{0}` | 1 | 1 |
| message-ones | 120 | `{0}` | 1 | 1 |
| malformed-zero-tail | 120 | `{0}` | 1 | 1 |
| malformed-ff-tail | 120 | `{0}` | 1 | 1 |

7 个模式的 stdout 摘要全部等于 `7efd896d67f4e015c5c697ae907417ccca2f2dcd02036152ca4f4c2714b61066`
（内容为 `calls_completed=1`），stderr 摘要全部等于空串摘要
`e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855`。
`diff -u` 的差异块数：**0**（`diff/diff-results.txt`、`diff/remote/diff-results.txt` 每个小节均输出 `(no difference)`）。

**diff 机制非空转的对照**：把同一个探针按"非法模式"调用时，可观察面**确实**会变：

```
$ ./r06_observable_probe nonsense 1 31337 ; echo rc=$?
rc=2                                  # stderr: "invalid mode"
$ diff -u probe-valid.err probe-nonsense.err
@@ -0,0 +1 @@
+invalid mode                         # diff-rc=1
```

即本轮 `diff` 为空是**被测实现的可观察面对称**所致，而不是比较脚本失效。
（该对照只用于验证工具，不属于被测对象。）

### 2.3 真实采集件的补充观察

- M5 参考 `measure`（远端 `platform-m5-20261016-30efdf66eb26/build-v2-ordinary/reference/measure`，
  ELF SHA-256 `4ff0956a…`）：3 次运行（`-c 0,1,3`，seed 31337，3/类）rc 全为 0，stderr 全为 0 字节，
  stdout 三次同一摘要 `449c6394…`，内容
  `reference: saved 15 raw decapsulation times in ns; no statistical conclusion`。
  该程序不按输入类别分支输出；类别只体现在 CSV 的 `input_category` 列与 meta 的类计数里。
- M2 采集件（远端 `collector-v2-2e894561892a/build-ordinary/collector/unfixed/m2_decaps_collector`）：
  `--class message-zero`（接受类）与 `--class malformed-zero-tail`（隐式拒绝类）各 3 次、同一夹具，
  **rc 均为 0、stderr 均为 0 字节、stdout 文本一致**；meta 中
  `failed_decapsulation_count=0`、`chosen_message_accept_mismatch_count=0`、`run_status=complete`。
  记录：`logs/real-m2-observable.txt`。

**结论**：在本轮覆盖的输入类别上，进程可观察面（退出码 + stdout + stderr）与"密文是合法还是隐式拒绝"
**无差异**。这不等于恒时，也不覆盖失败路径（如资源不足、IO 失败）在类别间的差异。

---

## 3. Memcheck：秘密是否作为 syscall 参数流向内核

### 3.1 通道有效性（负对照）

新增负对照 `src/r06_syscall_canary.c`：把本地填充的缓冲区标记为未定义后 `write(1, ...)`。

```
canary rc=99
==420335== Syscall param write(buf) points to uninitialised byte(s)
==420335== ERROR SUMMARY: 1 errors from 1 contexts (suppressed: 0 from 0)
```

即本轮使用的 `valgrind --tool=memcheck --error-exitcode=99` 参数**确实能**把
"秘密流向 syscall 参数"变成非 0 退出与可计数错误；因此下面 harness 的 0 错误是**有信息的 0**。
（该负对照本身是故意泄露的合成程序，只在审计目录内，不在任何产物路径。）

### 3.2 M5 秘密标记 harness

- 构建：远端新根内重新编译 `source-v2/tools/platform_m5/poison.c`，
  `-DPLATFORM_M5_HAVE_VALGRIND=1`（`/usr/include/valgrind`，Valgrind 3.22.0），链接
  `build-v2-ordinary/reference/libmlkem.a`（SHA-256 `ed9a6581…`）。
  标注 1152 B PKE 秘密 + sk 末 32 B 拒绝种子 `z`；公开 key/hash/密文保持 defined。
- 功能自检 `--self-test`：rc=0（624 B stdout / 11 行，含 2 个公开种子 × 5 类 `class=… complete_decapsulation=ok`
  与末行 `mode=functional_only …`）。
- `--poison`（`taskset -c 0`）：

  | 运行 | 命令 | ERROR SUMMARY | Syscall param |
  |---|---|---|---|
  | 1 | 默认 | `0 errors from 0 contexts` | 无 |
  | 2 | `--track-origins=yes` | `0 errors from 0 contexts` | 无 |

  stdout 末行为 `mode=valgrind_secret_marked pke_secret_bytes=1152 rejection_secret_bytes=32 ciphertext=public`，
  stderr 0 字节，进程 rc=0（未被 `--error-exitcode` 触发）。
- 已有证据交叉核对：旧 M5 构建目录 `logs-v2/system.valgrind.log` 同样 `ERROR SUMMARY: 0 errors`。

### 3.3 其他探针与既有日志

| 对象 | 本轮实跑 | 既有日志（引用） | syscall 参数报错 |
|---|---|---|---|
| M3 `platform_m3_on_probe --secret` | 1280 errors / 2 contexts（`poly_frommsg`） | `docs/evidence/m3-completion-20261016/native-8b6f2d91/on-secret.memcheck.log`（同 1280/2） | **无** |
| M3 `platform_m3_off_probe --secret` | 0 errors | 同上目录 `off-secret.memcheck.log`（0） | 无 |
| M4 `m4_compare_ct --probe` | 未重跑 | `docs/evidence/m4-compare-20261016/linux-run-250f424b/valgrind-ct.log`（0 errors） | 无 |
| M4 `m4_compare_vulnerable --probe` | 未重跑 | 同目录 `valgrind-vulnerable.log`（32 errors，人工缺陷） | 无 |
| 全部既有 memcheck/valgrind 日志（20 个文件） | — | 逐一 grep | **0 个文件含 `Syscall param`** |

（`docs/evidence/m2-kyberslash-20261016/varlat-tool/valgrind-try-patch-20250805.txt` 里出现的 2 处
`Syscall param` 是该补丁源码文本的上下文，不是运行日志。）

**结论**：本轮与既有日志中，**没有**任何"秘密值作为 syscall 参数"的记录。
M3/M4 的人工缺陷确实被 Memcheck 捕获，但表现为**数据相关访存/分支**，不表现为 syscall 参数泄露。

---

## 4. 计时窗口：窗口内不得有 I/O 或日志

方法（`src/r06_window_check.py`）：先剥离字符串字面量（避免把 meta 里记录的
`window=…` 断言文本误当代码），再定位**代码中**的 `atomic_signal_fence(memory_order_seq_cst)`，
按相邻两个 fence 配成一个窗口，逐窗打印原文并用白名单核对
（允许：读钟、fence、被测函数、整型状态接收；其余一律列为可疑）。

| 采集件 | 窗口（行） | 窗口内内容 | 窗口内非白名单调用 |
|---|---|---|---|
| `tools/platform_m2/collector.c` | 674–681 | 读钟 → fence → `mlkem_decapsulate` → fence → 读钟 | 无 |
| `src/measure.c`（M5 参考） | 173–174 | 空窗（读钟+两次 fence 的读钟开销测量） | 无 |
| `src/measure.c` | 712–718 | 读钟 → fence → 批量解封装 → fence → 读钟 | 无 |
| `src/measure.c` | 753–760 | 读钟 → fence → `mlkem_decapsulate` → fence → 读钟 | 无 |
| `tools/platform_m2_micro/m2_hotspot_microbench.c` | 771–773 | 读钟 → fence → `poly_tomsg` → fence → 读钟 | 无 |
| `tools/platform_m4/measure.c` | 177–184 | 读钟 → fence → `compare_once` → fence → 读钟 | 无 |
| `tools/platform_perf/perf_measure.c`（未接入构建） | 628–639 | fence 包住单个被测操作 | 无 |

合计 `R06_WINDOW_TOTAL=7`、`R06_WINDOW_PROBLEM_WINDOWS=0`（`window/window-check.txt`）。

**窗口外**（源码结构核对）：

- M2 采集件 meta 自述断言（`tools/platform_m2/collector.c:475-477`，实测导出值一致）：
  `window_scope=one_complete_mlkem_decapsulate`、`input_generation_window=outside`、
  `result_consumption_window=outside`、`io_window=outside`。
  源码对应：分配与密文构造在 `:594-650`，预热在 `:651-665`，结果消费与接受路径核对在 `:693-715`，
  CSV/meta 写入在 `:716` 之后。窗口内只有 `read_monotonic_nanoseconds`、
  `atomic_signal_fence`、`mlkem_decapsulate` 与整型状态接收（`:666-692`）。
- M5 `src/measure.c`：输入生成与哈希在 `:643-666`，预热在 `:667-689`，
  结果消费在 `:770`（窗口之后），CSV/meta 写入在 `save_measurements`（`:782` 起）。
- M4 `tools/platform_m4/measure.c`：预热 `:156` 起、结果消费与写盘在窗口循环之后。

**限制**：本检查是**源码结构**核对，不是运行时插桩；它不能证明编译器没有把 I/O 移入窗口，
也不能证明窗口内不存在隐含的系统调用（如 page fault）。此项与"恒时"无关。

---

## 5. 运行环境与可复现信息

| 项 | 值 |
|---|---|
| 基线提交 | `e81c1aee541f5e9c2f93e061c8a5b5fa923c749d` |
| 本机 | macOS / Apple Silicon（arm64），`/usr/bin/clang`，仅做功能性 diff，**不作为 x86_64 实测** |
| 远端 | `nss-marker@10.144.144.5` = `nss-m`，Ubuntu 24.04，Linux 6.17.0-35-generic，x86_64，AMD Ryzen 9 9950X，32 线程 |
| 远端新根 | `/home/nss-marker/yhr/Cry/r06-noleak-20261016-dc1567bbf852/`（唯一可写根之下的新目录，不覆盖任何既有目录） |
| 频率与亲和性 | **非锁频**：调速器 `powersave`、`frequency_control=not_configured`；动态 diff 用 `taskset -c 0,1,3`，Valgrind 用 `taskset -c 0`；**未使用 CPU2/CPU6**（留给主控锁频采集） |
| 工具链 | 远端 GCC 13.3.0、Valgrind 3.22.0、CMake 3.28.3；未使用 sudo；未在 `/tmp` 落盘 |
| 产物摘要 | M5 `measure` `4ff0956ac79550bc62caa0ea8d88968d3de8a926aebace9535481cb232145fa8`；`libmlkem.a` `ed9a658183562a88a96a631602cdcdd137d4bb405bd224fc2ac8cf682514416a`；探针 `6cb9e971…`；poison `613c9c6c…`；canary `8877ad65…`（完整记录见 `logs/remote-environment.txt`） |

复跑方式（脚本固化，见 `audit.sh`）：

```sh
R06_REPO=<repo> R06_OUT=<本目录> R06_BIN=<探针> R06_REPEAT=120 bash audit.sh dynamic-diff
R06_REPO=<repo> R06_OUT=<本目录>                            bash audit.sh static-scan
R06_REPO=<repo> R06_OUT=<本目录>                            bash audit.sh timing-window
R06_POISON=<poison ELF> R06_OUT=<本目录> R06_RUNNER="taskset -c 0" bash audit.sh memcheck
```

### 5.1 结果文件清单（SHA-256 前 16 位）

| 文件 | SHA-256（前 16） |
|---|---|
| `audit.sh` | `ae63f745142e5e51` |
| `src/r06_static_classify.py` | `b664478ef67b7aa6` |
| `src/r06_window_check.py` | `7bdab76663753f22` |
| `src/r06_observable_probe.c` | `278688d9ec86a88a` |
| `src/r06_syscall_canary.c` | `bc6f1bb450071a81` |
| `static/call-sites.tsv`（表头 + 1048 条数据 + `#SUMMARY` 行） | `c93ae93b4d1d37e0` |
| `static/call-sites.summary.txt` | 见文件 |
| `diff/matrix.tsv` = `diff/remote/matrix.tsv` | `1de9f37c27f12c04` |
| `diff/diff-results.txt` = `diff/remote/diff-results.txt` | `b3bf976d6a110d92` |
| `memcheck/remote/poison.valgrind.log` | `fb07248d80c2f3dc` |
| `memcheck/remote/poison-track-origins.valgrind.log` | `efc47b083d7eea65` |
| `memcheck/remote/canary.valgrind.log` | `950a9b333631f404` |
| `memcheck/remote/m3-on.valgrind.log` | `a543ca1ad5f950f5` |
| `window/window-check.txt` | `b1e3f8bc30de21d5` |
| `logs/remote-environment.txt` | `0c863c964281969b` |

完整逐条清单（`static/call-sites.tsv`：表头 + 1048 条数据 + `#SUMMARY` 行；
每条为 文件:行 | 调用 | 语句原文 | 是否接触秘密 | 判定理由）。
本文表格是该清单的汇总与人工复核结论。

**复现说明**：`diff/*`、`static/*`、`window/*` 三个目录是**逐字节可复现**的
（重跑 120 次得到同一摘要）。`memcheck/remote/*.valgrind.log` **不可能逐字节复现**——
Valgrind 会把 PID 写进每一行（`==<pid>==`）；复现时应比较
`ERROR SUMMARY` 与 `Syscall param` 计数，而不是文件摘要。
`logs/remote-environment.txt` 含远端根路径与 ELF 摘要，换根重跑会变化。

---

## 6. 未覆盖面（明确列出，不隐藏）

1. **未覆盖的模块**：`vendor/`（mlkem-native / liboqs / kyber 上游快照）、`sources/`（只读参考镜像）、
   `third_party/`、`build/`、`deliverables/`、`docs/evidence/` 内旧封存副本均**未扫描**。
   因此本审计只描述"自有实现 + harness"，不覆盖上游代码本身（上游由既有 security review 记录负责）。
2. **未覆盖的运行路径**：
   - 未执行 M5 原生 dudect 采数（`--collect` 使用上游 rdtsc，属主控锁频任务范围）；
     `tools/platform_m5/dudect.c` 与 `tools/platform_m2/dudect_online.c` 里**没有**
     `atomic_signal_fence` 计时窗口，因此不在 §4 的 7 个窗口之列；其窗口语义只做了源码阅读，
     未按本审计的同一方法核对。
   - 未执行 M4 的 `checkct`/BINSEC 与 `m4_compare_*_probe`（未在本轮重跑，只引用既有日志）。
   - 未执行网络路径（`src/network_server.c` / `src/network_client.c`）的端到端差分。
   - 未构造"门失败"场景（如故意让接受路径不一致），因此 **F1 的失败分支只做了源码判定**，
     未做动态演示。
3. **未覆盖的工具**：未运行 `-fsanitize=address,undefined`（属其他专项）、未运行 dudect 统计检验、
   未运行 `checkct`、未做编译器/汇编级窗口边界证明（只做源码结构检查）。
4. **未覆盖的时间维度**：动态 diff 每个模式 120 次只是**功能重复**，不构成任何时间侧信道或统计结论；
   失败路径、资源竞争、缓存/页错误、信号处理、环境变量等条件下的可观察面均未覆盖。
5. **未覆盖的进程可观察面**：本轮检查 stdout/stderr/退出码/errno。
   **未检查**：进程名与命令行（`/proc/<pid>/cmdline`）、打开的文件描述符与文件内容、
   内存映射与 `/proc/<pid>/maps`、core dump、`wait4` 资源用量（`ru_maxrss` 等）、
   信号、`/proc/<pid>/stat` 的调度字段、子进程树、以及运行目录下的文件名与 mtime。
   这些都能成为侧信道，需要单独专项。
6. **未覆盖的错误码语义**：`mlkem_*` 的返回码只表示参数/长度/空指针错误（`MLKEM_ERROR_ARGUMENT`、
   `MLKEM_ERROR_RANDOM`），**不表示密文重加密比较结果**（`include/mlkem.h` 已注明）；
   本轮只核对了源码与文档一致性，未对每个调用方逐一证明其错误分支不依赖比较结果（除 M2 采集件 F1）。
7. **单项工具局限**：Valgrind Memcheck 只跟踪"未定义位"的传播；
   若实现把秘密改成用"定义位"表示的等价值（例如重新常量化的掩码），Memcheck 不会报警，
   但秘密仍可能通过其他通道泄露。

---

## 7. 明确声明

- 本审计**不构成恒时证明**；动态 diff 为空**不等于**没有时间侧信道，
  也不等于所有输入类别上的可观察面都相同（只覆盖 §2.1 列出的 7 种模式）。
- 本审计**不主张"零泄露"**；它给出的是固定代码快照 + 固定工具链 + 固定命令下的可观察面描述，
  并已如实列出 1 条低危发现（F1）与 3 条信息项（F2–F4）。
- 本轮所有实跑均在**非锁频**下完成，标注为"非锁频、仅功能性检查"，
  不得引用为频率结论、统计结论或竞赛签收依据。
- 未提交、未 push；未修改 `src/`、`tests/`、`fixtures/` 及任何既有证据文件；
  本目录仅新增本轮文件（`MAPPING.md` 由并发的其他 R06 子任务创建，本审计未触碰）。
