# M2 叙事补强：机制实锤与候选解释的边界核对（2026-10-20）

对象：报告 §20「M2 KyberSlash：真实历史案例」新增的四段叙事。

**本页只登记既有证据的核对结果，不产生新的实验数据，不改动任何既有 CSV、统计家族或判定。**

## 1. 要核对什么

新增叙事由三部分组成：

1. **机制事实**：R05 补格时用反汇编与秘密标记 Memcheck 实锤，pq-crystals 的 KyberSlash 修复
   `272125f` 只消除了除法，把 `poly_frommsg` 里的 `bt`/`jae` 数据相关分支原样留下。
2. **候选解释**：该分支与 M1 同源，判据就是重加密时消息多项式的位；`message-zero` 全零、
   `message-ones` 全 0xff，两类走**系统性不同的代码路径**，两臂都是如此——
   据此给族外 RTLF「主类对两臂都 `difference_detected`」一条**机制层面的候选解释**。
3. **平台能力叙事**：反汇编 + 秘密标记 Memcheck + varlat + 上游补丁差异核对四者交叉。

第 1、3 部分是可直接核对的事实；**第 2 部分是候选解释，必须单独核对它是否与观测一致**，
否则就成了「机制讲得通就当成原因」。

## 2. 机制事实的核对结果（全部通过）

| 核对项 | 结果 | 依据 |
|---|---|---|
| 未修产物的分支 | `3668: bt %ecx,%r8d` → `366c: jae 3673` | `docs/evidence/r05-locate-20261016/remote-tree/m2-disasm/unfixed-poly_frommsg.asm` |
| 已修产物的分支 | `366e: bt %ecx,%r8d` → `3672: jae 3679` | 同目录 `fixed-poly_frommsg.asm` |
| 两侧指令字节 | **逐字节相同**（SHA-256 同为 `6a6ee641a5e8a7de23052fbc7f5855dc01f3c08b6bb593fee43a2b41de26ed35`） | 同目录 `*-poly_frommsg.bytes` 与 `SHA256SUMS.remote-tree.txt` |
| 分支判据 | `3661: movzbl (%rsi,%rax,1),%r8d` 取的是消息字节，`bt %ecx,%r8d` 取的是该字节的第 `j` 位 | 同上反汇编 |
| 秘密标记 Memcheck | 两臂各 `256 errors from 1 contexts`，唯一上下文都是 `pqcrystals_kyber768_ref_poly_frommsg`（未修 `poly.c:167`／已修 `poly.c:178`） | `docs/evidence/r05-locate-20261016/remote-tree/m2-ctgrind/logs/{unfixed,fixed}-z01of08.log` |
| `272125f` 是否碰 `poly_frommsg` | **不碰**。上游差异只含 `ref/poly.c` 与 `ref/polyvec.c`；`poly.c` 的三处 hunk 是 `poly_compress` 与 **`poly_tomsg`** 的除法改写（diff 的 hunk 头 `@@ -180,14 +191,19 @@ void poly_frommsg(...)` 是 git 的**函数上下文**标注，hunk 体从 `void poly_tomsg(...)` 开始，**不是**改 `poly_frommsg`） | `docs/evidence/m2-kyberslash-20261016/version-audit/upstream-remediation.diff` |
| 源码逐字比较 | `poly_frommsg` 函数体在 **M2 未修、M2 已修、M1（liboqs 0.10.0 的 `pqcrystals-kyber-standard_ml-kem-768-ipd_ref`）三处逐字节相同** | `vendor/kyber-kyberslash-{unfixed,fixed}/ref/poly.c` 与 `vendor/liboqs-0.10.0/src/kem/ml_kem/pqcrystals-kyber-standard_ml-kem-768-ipd_ref/poly.c` |
| 类构造 | M2 采集件的 `message-zero` 用**全零消息**、`message-ones` 用**全 0xff 消息**（`m2_collector_build_ciphertext` 里 `memset(chosen_message, …0x00/0xFF, 32)`），因此重加密时消息多项式逐位全 0 或全 1 | `tools/platform_m2/collector_inputs.c` |

**代码路径的机制结论**（不是时序结论）：在 `poly_frommsg` 里，全零消息使 `jae` **恒取**（跳过
`mov $0x681,%edx`），全 0xff 消息使 `jae` **256 次都不取**（每次都写 1665）。两个臂的这段代码
逐字相同，所以**两类输入在两臂上走的路径确实系统性不同**。

## 3. 候选解释的核对结果：观测并不完全支持「两臂都是如此」

候选解释要成立，至少要能回答：**观测到的类间偏移在两个臂上是否同号且稳定**。
逐数据集读冻结的 RTLF 结果（`docs/evidence/platform-rtlf-20261016/results/<数据集>/rtlf.json`
的 `statistics.series_x/series_y`；X = message-zero，Y = message-ones）：

| 数据集 | 臂 | meanX (ns) | meanY (ns) | X−Y (ns) | sdX (ns) | sdY (ns) | 分布检出 |
|---|---|---:|---:|---:|---:|---:|---|
| m2-m2-s1-unfixed-main | unfixed | 56840.8 | 56830.2 | **+10.5** | 443.9 | 740.8 | 是 |
| m2-m2-s2-unfixed-main | unfixed | 56767.8 | 56748.6 | **+19.1** | 696.2 | 681.8 | 是 |
| m2-m2-s3-unfixed-main | unfixed | 56786.2 | 56776.3 | **+10.0** | 537.9 | 462.0 | 是 |
| m2-m2-s1-fixed-main | fixed | 60846.4 | 60824.7 | **+21.7** | 1531.5 | 1170.4 | 是 |
| m2-m2-s2-fixed-main | fixed | 60766.6 | 60783.7 | **−17.1** | 996.5 | 1087.5 | 是 |
| m2-m2-s3-fixed-main | fixed | 60832.2 | 60847.7 | **−15.5** | 588.6 | 595.6 | 是 |

- **未修臂**：三个种子的偏移**同号**（+10.5、+19.1、+10.0 ns），X 类平均离散度 559 ns。
- **已修臂**：符号**翻转**（+21.7、−17.1、−15.5 ns），X 类平均离散度 1039 ns（约为未修臂的 1.9 倍）。

可重跑脚本：`python3 scripts/analyze_m2_class_offset.py`（只读上述冻结结果，不写任何文件）。

**结论（据此写进报告）**：

1. 候选解释**不能升级为「两臂的差异都由这条分支驱动」**。已修臂的类间偏移符号不稳定、
   离散度更大，说明它的分布报警**不能单独归到 `poly_frommsg` 的分支**；未受控漂移与尾部形状
   仍是并列因素——这与冻结的
   [RTLF_RESULT.md](../platform-rtlf-20261016/RTLF_RESULT.md) §3 的读法（类构造 + 未受控漂移）一致。
2. **两臂都不据此作泄漏结论**：端到端家族 `m2_end_to_end_full_decaps_v1` 仍 Holm 拒绝 0
   （合并 Δ +4.58 ns、95% CI [−3.08, +12.25]、I²=58.3%），除法热点微基准族
   `m2_div_hotspot_microbench_v1` 同样拒绝 0；类间偏移的量级（10–20 ns）在本预算的 MDE
   （M2 约 25–67 ns）之下，观测效应 < MDE，不等于零效应、也不是恒时证明。
3. 这条核对的**价值**在于把「机制讲得通」和「观测支持」分开：机制事实（分支存在、秘密相关、
   官方修复漏修、两类路径系统性不同）是硬的、可逐字核对的；把 RTLF 报警归因给它是**候选**，
   且只在未修臂上得到方向一致的支持。

## 4. 对报告写法的约束（已落实到正文）

- 报告 §20 开头写明：机制事实（分支、两臂指令字节相同、秘密标记 Memcheck 命中、`272125f` 不碰此处）。
- 同段给出候选解释时**必须同时给出**第 3 节的符号稳定性核对结果与三条边界。
- 「两臂都是如此」只用于描述**代码路径**，不用于描述**时序差异**。
- 不新增任何泄漏声明，不改任何预注册判定。
