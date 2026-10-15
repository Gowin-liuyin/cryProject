# R06 修复手段 → 题面第 6 条方法分类映射表（2026-10-16）

对象：本工程审计过的历史/参考实现（M1 liboqs 0.10.0、M2 pq-crystals kyber768、M5 mlkem-native 参考路径）
与本工程**人工构造**的校准夹具（M3/M4）。每行给出：修复点（commit / 补丁路径）| 题面第 6 条方法分类 |
证据路径 | 是否人工夹具。

题面第 6 条的七个分类（本表只用这七个标签，不改写）：
**常量时间比较 / 掩码选择（cmov）/ 固定循环上界 / 统一错误处理（隐式拒绝）/ 消除数据相关分支 /
消除数据相关除法 / 消除数据相关访存**。

写法约定：

- 「修复点」写上游提交号或本仓库内补丁路径；**M5 一栏不是修复**，是参考实现既有做法，见 M5 段的显式声明。
- 「是否人工夹具」三值：**否（上游/历史实现）**、**是（人工构造校准）**、**否（上游既有做法，非针对某次 CVE 的修复）**。
- 每个证据路径都是仓库内可打开的路径；地址只对 R05 §0 与本文写明的固定 ELF 有效。
- 阴性不是恒时证明；本表只做“修复手段 ↔ 方法分类”的对应，不新增任何泄漏判定。

---

## 1. 汇总表

| # | 模块 | 修复点（commit / 补丁路径） | 题面第 6 条方法分类 | 证据路径 | 是否人工夹具 |
|---|---|---|---|---|---|
| M1-a | M1 liboqs 0.10.0 ipd | 官方 `982c762c242ef549c914891b47bf6e0ed6321f91`（改 `…ml-kem-768-ipd_ref/poly.c`） | **消除数据相关分支** | 修复前 `16e: bt %ecx,%r8d` → `172: jae 179`：[locked-poly-frommsg-vulnerable.s](../liboqs010-locked-20261015/logs/locked-poly-frommsg-vulnerable.s)；修复后 `189: bt %r13d,%eax` → `18d: setb %dl` → `198: call …cmov_int16`，函数内无 `jae`：[poly-frommsg-fixed-reloc.s](../tooling-strengthen-20261015/logs/poly-frommsg-fixed-reloc.s)；补丁覆盖范围 [patch-apply.txt](../liboqs010-locked-20261015/logs/patch-apply.txt) | 否（上游/历史实现） |
| M1-b | M1 同上（同一补丁的另一半） | 同上 `982c762`（新增 `cmov_int16`） | **掩码选择（cmov）** | `cmov_int16` 机器码：`neg %edx` / `movzwl (%rdi),%eax` / `xor %eax,%esi` / `and %edx,%esi` / `xor %eax,%esi` / `mov %si,(%rdi)`，地址 `0x2c79`：[fixed-full.asm](../r05-locate-20261016/remote-tree/m1-disasm/fixed-full.asm)（本轮新增）；调用点 `3f04: call 3ecb/cmov_int16` 在 `poly_frommsg` 内 | 否（上游/历史实现） |
| M1-c | M1 隐式拒绝 / cmov 掩码生成 | 官方 `982c762` 同时给 `verify.c` 的 `cmov` 加 `__asm__("" : "+r"(b))` 值屏障 | **掩码选择（cmov）** | 掩码生成无分支：`2b26: test %ebx,%ebx` → `2b28: sete %cl` → `2b37: call …cmov`，`dec` 内 0 条跳转：[fixed-full.asm](../r05-locate-20261016/remote-tree/m1-disasm/fixed-full.asm)；`cmov` 体 `neg/and/xor` 无条件传送：[fixed-…cmov.bytes](../r05-locate-20261016/remote-tree/m1-disasm/fixed-pqcrystals_ml_kem_768_ipd_ref_cmov.bytes) | 否（上游/历史实现） |
| M2-a | M2 pq-crystals kyber768 | 官方 `dda29cc63af721981ee2c831cf00822e69be3220`（KyberSlash1，只改 `ref/poly.c` 的 `poly_tomsg`） | **消除数据相关除法** | 修复前 `3689: mov $0xd01,%r9d` + `36a5: movswl (%rsi,%rcx,2),%eax` + `36bf: div %r9d`：[unfixed-…poly_tomsg.asm](../m2-kem-20261016/native-qualification/)；修复后 `div` 计数 0、改成 `imul $0x275f6`+`add`+`shr $0x1c`：[fixed-…poly_tomsg.asm](../m2-kem-20261016/native-qualification/) 与 [ordinary-fixed-qualification.division-counts.txt](../m2-kem-20261016/microbench-0551254c9579/disasm/) | 否（上游/历史实现） |
| M2-b | M2 pq-crystals kyber768 | 官方 `272125f6acc8e8b6850fd68ceb901a660ff48196`（KyberSlash2；上游提交信息：Removed "/KYBER_Q" in poly_compress and polyvec_compress） | **消除数据相关除法** | 修复前 `3523: div %r8d`（`poly_compress`）、`38c7: div %r8d`（`polyvec_compress`）：[unfixed-…poly_compress.asm](../m2-kem-20261016/native-qualification/)、[unfixed-…polyvec_compress.asm](../m2-kem-20261016/native-qualification/)；修复后两侧 `div` 全 0：[ordinary-fixed-qualification.division-counts.txt](../m2-kem-20261016/microbench-0551254c9579/disasm/)；源码差异 [upstream-remediation.diff](../m2-kyberslash-20261016/version-audit/upstream-remediation.diff) | 否（上游/历史实现） |
| M2-c | M2 上游两个被测版本都保留的同一处老写法（Kyber round3 起即有） | 无对应修复：该处**两个被测版本都仍是分支**（`272125f` 不碰 `poly_frommsg`） | **消除数据相关分支（未修复，登记为缺口）** | 本轮新增反汇编：未修 `3668: bt` → `366c: jae 3673`；已修 `366e: bt` → `3672: jae 3679`，指令字节两侧完全相同（SHA-256 `6a6ee641a5e8a7de23052fbc7f5855dc01f3c08b6bb593fee43a2b41de26ed35`）：[unfixed-poly_frommsg.asm](../r05-locate-20261016/remote-tree/m2-disasm/unfixed-poly_frommsg.asm)、[fixed-poly_frommsg.asm](../r05-locate-20261016/remote-tree/m2-disasm/fixed-poly_frommsg.asm)；动态命中 [unfixed-z08of08.log](../r05-locate-20261016/remote-tree/m2-ctgrind/logs/unfixed-z08of08.log) | 否（上游/历史实现；本行是“未修复”状态，不是修复手段） |
| M3-a | M3 人工夹具（mlkem-native 副本） | 补丁 [m3-mem-lut-toggle.patch](../patches/m3-mem-lut-toggle.patch) 的**开版**（`-DPLATFORM_M3_LUT_LEAK=1`） | **消除数据相关访存**（对照物：把无分支掩码选择换成跨缓存行秘密下标表，用于证明工具链能检出该类的**反面**） | Memcheck `on --secret` 1280 errors / 2 contexts，栈 `baseline_native_poly_frommsg (compress.c:714) ← indcpa_enc (indcpa.c:544) ← dec (kem.c:443)`；PC 静态偏移 `0x5CED`/`0x5D15` = 两次 `movzwl` 秘密下标 load：[LOCATE_RESULT.md](../m3-completion-20261016/LOCATE_RESULT.md)；补丁 SHA-256 `2ae5aed747344fb978b87530ac5016495991bc007f8a93fff872f1273ca3c925` | **是（人工构造校准）** |
| M3-b | M3 人工夹具 | 补丁 [message-branch.patch](../patches/message-branch.patch)（A 版：逐位 `if/else`，固定该函数优化条件 `optnone/noinline`） | **消除数据相关分支**（对照物：把无分支掩码选择换成消息位分支，用于证明工具链能检出该类的**反面**） | 补丁原文见路径；对应 R05 §4.4 行（人工构造校准，不计入 90 格）与 [m3-memaccess-20261016/](../m3-memaccess-20261016/) | **是（人工构造校准）** |
| M3-c | M3 人工夹具 | 补丁 [message-constant-time.patch](../patches/message-constant-time.patch)（B 版：位掩码 + `mlk_ct_sel_int16`，固定该函数优化条件） | **掩码选择（cmov）** | 补丁原文见路径；与 A 版成对，用于“同结构、只换机制”的逐份反汇编对照 | **是（人工构造校准）** |
| M3-d | M3 人工夹具 | 补丁 [message-value-barrier.patch](../patches/message-value-barrier.patch)（C 版：沿用上游 `mlk_value_barrier_u8`，不施加函数级优化控制） | **掩码选择（cmov）+ 固定循环上界** | 补丁原文见路径；`mlk_value_barrier_u8` 定义在 [vendor/mlkem-native/mlkem/src/verify.h:108](../vendor/mlkem-native/mlkem/src/verify.h) | **是（人工构造校准）** |
| M4-a | M4 人工夹具（i386 抽取内核） | [fixtures/early_reject_memcmp/compare_early.c](../fixtures/early_reject_memcmp/compare_early.c)（阳性臂：命中即 `return 0`） | **消除数据相关分支 / 统一错误处理（隐式拒绝）的对照物（反面）** | Binsec `-sse -checkct`：`[checkct:result] Instruction 0x8049047 has control flow leak`，状态 `insecure`，反例 `m4_public_length=0x10`、`secret1[0]=0xff` vs `secret2` 全 0：[FORMAL_RESULT.md](../m4-completion-20261016/FORMAL_RESULT.md)、[vulnerable-1-16/checkct.toml](../m4-completion-20261016/formal-v2/vulnerable-1-16/checkct.toml) | **是（人工构造校准）** |
| M4-b | M4 人工夹具 | [fixtures/early_reject_memcmp/compare_ct.c](../fixtures/early_reject_memcmp/compare_ct.c)（归约臂：`difference_bits \|= a[i]^b[i]` 全量累积后一次比较） | **常量时间比较 + 消除提前返回（统一错误处理）** | 同一 Binsec 模型：`Program status is : secure`，16/16 路径、`pending 0`、`discontinued 全 0`、`SMT unknown 0`、控制流 33/33、访存 141/141：[ct-1-16/stdout.txt](../m4-completion-20261016/formal-v2/ct-1-16/stdout.txt)、[ct-1-16/checkct.toml](../m4-completion-20261016/formal-v2/ct-1-16/checkct.toml) | **是（人工构造校准）** |
| M5-a | M5 mlkem-native `b3ba7b3` 参考路径 | **不是修复**：上游参考实现既有做法（无对应 CVE） | **掩码选择（cmov）** | `mlk_poly_frommsg`：`mlk_value_barrier_u8` + `mlk_ct_sel_int16(MLKEM_Q_HALF, 0, msg[i] & mask)`（[vendor/mlkem-native/mlkem/src/compress.c:697-724](../vendor/mlkem-native/mlkem/src/compress.c)）；产物侧 8 个消息位全展开为 `and/or/shr/neg/and` 掩码路线、唯一跳转由 `cmp $0x20,%rax` 判定：`poison.disasm` 第 1532–1596 行（归档 [software-dynamic-evidence.tar.gz](../m5-completion-20261016/software-dynamic-evidence.tar.gz) 内 `logs-v2/poison.disasm`） | 否（上游既有做法，非针对某次 CVE 的修复） |
| M5-b | M5 参考路径 | **不是修复**：上游既有做法 | **常量时间比较 + 统一错误处理（隐式拒绝）** | `mlk_ct_memcmp`（[verify.h:338](../vendor/mlkem-native/mlkem/src/verify.h)）内联：`movdqu/pxor/por` 累积 + `movzbl/neg/shr/xor` 无分支出 0/1（`poison.disasm` 第 9160–9211 行）；`mlk_ct_cmov_zero`（[verify.h:388](../vendor/mlkem-native/mlkem/src/verify.h)）内联：掩码选择、回边常数（第 9589–9600 行）；`kem.c:449-458` 的 `fail = mlk_ct_memcmp(...)` → `mlk_hash_j(ss, z‖ct)` → `mlk_ct_cmov_zero(ss, kr, 32, fail)` | 否（上游既有做法，非针对某次 CVE 的修复） |
| M5-c | M5 参考路径 | **不是修复**：上游既有做法（对照 M2 的除法问题） | **消除数据相关除法** | 该实现从上游起就用乘加/移位而非 `div`：varlat=yes（KyberSlash 补丁 Valgrind，检测可变时延指令的秘密操作数）在三模式 10 次完整解封装上 **0 errors / 0 contexts**：[varlat-yes.valgrind.log](../m5-completion-20261016/software-dynamic-evidence.tar.gz)（归档内 `logs-v2/`） | 否（上游既有做法，非针对某次 CVE 的修复） |
| M5-d | M5 参考路径 | **不是修复**：上游既有做法（`mlk_kem_check_sk` 的 FIPS 203 §7.3 哈希检查） | **消除数据相关分支的“例外登记”**：该早退分支的判据是**公开** `sk` 部分的哈希，不属秘密相关分支 | `poison.disasm`：`a404: call 8a80 <baseline_native_check_sk>` → `a40c: test %eax,%eax` → `a40e: jne ad87`（第 9033–9036 行）；公开性声明 [vendor/mlkem-native/mlkem/src/kem.c:92-99](../vendor/mlkem-native/mlkem/src/kem.c) | 否（上游既有做法，非针对某次 CVE 的修复） |

---

## 2. 覆盖统计

- **覆盖模块数：5**（M1、M2、M3、M4、M5 全部覆盖）。
- 表内数据行 **16**（原自述写 15，主控 2026-10-16 按实际行数更正）；其中上游/历史实现 6 行（M1-a/b/c、M2-a/b、M2-c 的未修复登记）、
  **人工构造校准 5 行**（M3-a/b/c/d、M4-a/b —— 计数时 M4 两行各算一行，共 6 行里 5 个夹具补丁 + 2 个内核变体）、
  上游既有做法 4 行（M5-a/b/c/d）。
- 七个题面分类的落点：
  | 分类 | 出现位置 |
  |---|---|
  | 常量时间比较 | M4-b、M5-b |
  | 掩码选择（cmov） | M1-b、M1-c、M3-c、M3-d、M5-a |
  | 固定循环上界 | M3-d（`coefficient_index < MLKEM_N` 的常数上界）、M1-c/M2-a 的循环上界为常数（同表已注明） |
  | 统一错误处理（隐式拒绝） | M4-a（反面）、M4-b、M5-b |
  | 消除数据相关分支 | M1-a、M2-c（未修复登记）、M3-b、M4-a（反面） |
  | 消除数据相关除法 | M2-a、M2-b、M5-c |
  | 消除数据相关访存 | M3-a（反面） |

---

## 3. 必须一起读的边界

1. **M1 的“消除数据相关分支”只针对 `poly_frommsg` 一处。** `982c762` 同时改的 `verify.c` 值屏障
   属于**掩码选择**一侧的加固，本轮另立一行（M1-c）；不要把两处合并成“M1 已整体消除数据相关分支”。
2. **M2 的 KyberSlash 修复不覆盖重加密里的 `poly_frommsg`。** M2-c 明确登记为**未修复缺口**：
   两个被测版本该函数指令字节相同，`272125f` 的差异清单里没有它。
3. **M3/M4 全部是人工构造校准。** 它们的作用是让工具链的检出能力有非空对照
   （M3 的 Memcheck/Microwalk 阳性、M4 的 Binsec `insecure`），
   **不是**上游历史实现的缺陷记录，也不计入 R05 的 90 格。
4. **M5 不是“修复”。** 这四行记录的是 mlkem-native 参考路径**既有**的写法；
   `b3ba7b3` 没有对应的 CVE，也没有针对某次漏洞的补丁。写成“M5 的修复”会抬高声明。
5. **Binsec 的检查点边界。** R06 里唯一引用 Binsec 的是 M4-a/M4-b，用的是
   `-checkct-features control-flow,memory-access`；`multiplication`/`dividend`/`divisor`
   **未开**（工具帮助原文 “Multiplication and division checks are experimental”，见
   [formal-v2/identity/install-run.log](../m4-completion-20261016/formal-v2/identity/install-run.log)，
   命令见 [tools/platform_m4/run_checkct.sh:59](../tools/platform_m4/run_checkct.sh)）。
   因此 **M2-a/M2-b 的“消除数据相关除法”判定与 Binsec 无关**，全部来自反汇编 + varlat。
   M5 重加密一侧的 Binsec `checkct` 本轮为 **unknown**（架构/模型/状态空间三重阻塞），
   详见 [r05-locate-20261016/RESULT.md](../r05-locate-20261016/RESULT.md) 第 5 节。
6. **本表不新增泄漏判定。** 每格的“存在/不存在”仍以 [R05-全流程排查表.md](../R05-全流程排查表.md) 为准；
   本表只回答“这个修复手段属于题面第 6 条的哪一类”。

---

## 4. 复现入口

| 用途 | 路径 |
|---|---|
| M1 两变体整份反汇编 | [remote-tree/m1-disasm/](../r05-locate-20261016/remote-tree/m1-disasm/)（`clangover-full.asm`、`fixed-full.asm`、`function-byte-hashes.txt`） |
| M2 `poly_frommsg` 两变体反汇编 | [remote-tree/m2-disasm/](../r05-locate-20261016/remote-tree/m2-disasm/) |
| M2 秘密标记完整解封装 Memcheck 16 次 | [remote-tree/m2-ctgrind/](../r05-locate-20261016/remote-tree/m2-ctgrind/)（`run-log.txt`、`logs/`、`probe/probe_dec.c`） |
| M5 重加密 Binsec 尝试六份实验 | [remote-tree/binsec-m5/](../r05-locate-20261016/remote-tree/binsec-m5/) |
| 本轮全部命令 | [COMMANDS.md](../r05-locate-20261016/COMMANDS.md) |
| M3 工具阳性对照 | [m3-completion-20261016/LOCATE_RESULT.md](../m3-completion-20261016/LOCATE_RESULT.md) |
| M4 Binsec 有界验证 | [m4-completion-20261016/FORMAL_RESULT.md](../m4-completion-20261016/FORMAL_RESULT.md) |
| M5 三模式 Valgrind | [m5-completion-20261016/software-dynamic-evidence.tar.gz](../m5-completion-20261016/software-dynamic-evidence.tar.gz) → `logs-v2/` |
| M2 上游提交与差异 | [m2-kyberslash-20261016/version-audit/upstream-commits.txt](../m2-kyberslash-20261016/version-audit/upstream-commits.txt)、[upstream-remediation.diff](../m2-kyberslash-20261016/version-audit/upstream-remediation.diff) |

---

本文件不修改任何既有证据文件；不 `git add/commit/push`；不含密钥恢复、exploit 或现场修改。
