# R05 补缺格定位结果（2026-10-16）

对象：R05 §7 遗留清单第 1–3 条（必补）+ 第 4 条补充项（哈希 Memcheck、M5 重加密 Binsec）。
本目录只新增，不改 `docs/evidence/m2-kem-20261016/`、`m3-*`、`m4-*`、`m5-*` 下任何原始数据。

远端工作根：`/home/nss-marker/yhr/Cry/r05-locate-20261016-6039f84e5a09/`
（同名前缀的第二个根 `…-367a5a1ac659` 是首轮只读反汇编工作根，其产物已 `cp -a` 并入上者；两个根的 `tmp/`、`cache/` 均为显式 `TMPDIR`/`XDG_CACHE_HOME`，物理路径都在 `Cry` 内。）
本机归档：`r05-locate-20261016-6039f84e5a09.tar.gz`（本目录），SHA-256
`d03c7da4ebf4875aba485fe0afefff21aab30f3b0a9409cffac68e2d018416cc`；解出的原件在 `remote-tree/`
（100 个文件，逐文件摘要见 `SHA256SUMS.remote-tree.txt`，归档自身摘要见 `SHA256SUMS.archive.txt`）。
远端权威副本仍在 `/home/nss-marker/yhr/Cry/r05-locate-20261016-6039f84e5a09/` 与同级同名 `.tar.gz`（本轮未删、未覆盖）。

环境：`nss-m`，Linux 6.17.0-35-generic，x86_64，AMD Ryzen 9 9950X；Clang 18.1.3；GNU objdump 2.42；
Valgrind 3.22.0（远端默认，非 3.25.1）；Binsec 0.11.3 + Z3 4.15.3（复用 M4 已安装工具）。
**本轮全部命令 `taskset -c 0,1,3`**，避开 CPU2/CPU6；未 sudo、未跑锁频、未做密钥恢复。见 `remote-tree/00-ENV.txt`。

---

## 1. M2 重加密 × 提前返回：**存在**（原“未检查”格）

被查产物（与 `docs/evidence/m2-kem-20261016/COLLECTOR_CONTRACT.md` 固定的摘要逐个核对一致）：

| 变体 | ELF | SHA-256 |
|---|---|---|
| 未修 `a621b8d` | `build-ordinary/platform-m2/unfixed/measure` | `dd4073ba38d9ba6b465fca9b6f2e94ef11d8ebc8948901e41f0ba9926ee674e7` |
| 已修 `272125f` | `build-ordinary/platform-m2/fixed/measure` | `c48f89a5bc7f9bd8117a0319eacbc40bf9d061ecae2bad48812376d04745ada7` |

命令：`objdump -d --disassemble=pqcrystals_kyber768_ref_poly_frommsg <measure>`
原件：`remote-tree/m2-disasm/{unfixed,fixed}-poly_frommsg.asm`，字节列 `…-poly_frommsg.bytes`。

未修侧 `pqcrystals_kyber768_ref_poly_frommsg`（`0x3651`）：

```
    3661: 44 0f b6 04 06   movzbl (%rsi,%rax,1),%r8d     ; 取消息字节（解密输出，秘密）
    3668: 41 0f a3 c8      bt     %ecx,%r8d              ; 测第 j 位
    366c: 73 05            jae    3673                   ; ← 数据相关分支
    366e: ba 81 06 00 00   mov    $0x681,%edx
    3673: 66 89 14 4f      mov    %dx,(%rdi,%rcx,2)
```

已修侧同一函数（`0x3657`）**逐字节相同**（只整体平移 6 字节）：

```
    366e: 41 0f a3 c8      bt     %ecx,%r8d
    3672: 73 05            jae    3679                   ; ← 同一分支仍在
    3674: ba 81 06 00 00   mov    $0x681,%edx
```

- 指令字节比对：`cmp` 两侧的 `*-poly_frommsg.bytes` **完全相同**，SHA-256 同为 `6a6ee641a5e8a7de23052fbc7f5855dc01f3c08b6bb593fee43a2b41de26ed35`。
  即：**`272125f` 没有改动 `poly_frommsg`，修复前后这一格同为“存在”。**
- 与 R05 已记的事实一致：`upstream-remediation.diff` 只含 `ref/poly.c` 的 compress/tomsg 与 `ref/polyvec.c`；
  M2 家族从未收到 liboqs `982c762` 那种 `setb` + `cmov_int16` 改写。
- 该分支在完整解封装里可达：调用点 `unfixed: 32d2: call 3651`（`fixed: 32d2: call 3657`），
  地址落在 `pqcrystals_kyber768_ref_indcpa_enc`（`0x3283`，`indcpa.c:269`）；
  其调用者 `pqcrystals_kyber768_ref_dec`（`0x2e67`）在 `2edb: call 3283 <indcpa_enc>`。
  源码 `vendor/kyber-kyberslash-unfixed/ref/poly.c:155-170`，分支对应 `poly.c:166-167`。

**独立动态确认（本轮新增探针）**：`remote-tree/m2-ctgrind/` 的 16 次运行（见第 4 节）
在秘密标记下对 `poly_frommsg` 报出 “Conditional jump or move depends on uninitialised value(s)”，
调用链 `poly_frommsg (poly.c:167) ← indcpa_enc (indcpa.c:269) ← dec (kem.c:114)`。
即“源码相同”这一步不需要再当论据：**产物指令序列与动态命中都已直接给出**。

---

## 2. M1 隐式拒绝 × 可变时间比较：**不存在**（掩码未被编成分支，含 `sete` 掩码生成）

被查产物：

| 变体 | ELF | SHA-256 |
|---|---|---|
| M1 未修 | `build/historical-clangover/historical/measure` | `bd84ee9c2a44993fb5c6b43c4fb37027a168d265b4ca027eba3c3026798a0f78` |
| M1 已修 `982c762` | `build/historical-fixed-982c762/historical/measure` | `1849821eca3039872cf5f103e3928141978b8846792a8da4e7c790ce96c2b5e9` |

原件：`remote-tree/m1-disasm/{clangover,fixed}-full.asm`（整份 `objdump -d`）与按函数切出的 `*.bytes`。

### 2.1 掩码生成点（`crypto_kem_dec` 已内联进 `pqcrystals_ml_kem_768_ipd_ref_dec`）

`dec` 函数体 `0x2a7f`–`0x2b4f`，**修复前后逐字节同一**（唯一差异是 3 条 `call` 的相对位移，
因为补丁把 `poly_frommsg` 之后的函数整体后移；调用目标地址比对完全相同）：

```
    2b04: e8 17 01 00 00   call 2c20 <…_ref_verify>        ; 比较结果 eax ∈ {0,1}
    2b09: 89 c3            mov  %eax,%ebx                   ; fail 存进 ebx
    2b1f: e8 89 00 00 00   call 2bad <…_ref_kyber_shake256_rkprf>   ; rkprf(ss, z, ct)
    2b24: 31 c9            xor  %ecx,%ecx
    2b26: 85 db            test %ebx,%ebx                   ; ← 判 fail
    2b28: 0f 94 c1         sete %cl                         ; ← 无分支生成 0/1 掩码
    2b2b: ba 20 00 00 00   mov  $0x20,%edx
    2b37: e8 11 01 00 00   call 2c4d <…_ref_cmov>           ; 掩码作第 4 实参
```

- `dec` 函数体内**条件跳转计数 = 0**（`jmp/jcc` 全部为 0；只有 `call` 与 `ret`）。
- 全 ELF 内**没有任何跳转指令以 `2b09`–`2b37` 之间任一地址为目标**（该区间只有顺序流进入）。
- 函数调用序列两变体完全一致：`indcpa_dec → OQS_SHA3_sha3_512 → indcpa_enc → verify → rkprf → cmov`。

### 2.2 `cmov` 函数体：掩码只用于按位运算，不进入控制流

`pqcrystals_ml_kem_768_ipd_ref_cmov`（`0x2c4d`）：

```
    2c51: 48 85 d2        test %rdx,%rdx     ; len == 0 时整体跳过（len 恒为调用点的 0x20 常数）
    2c54: 74 21           je   2c77
    2c56: f6 d9           neg  %cl           ; b ∈ {0,1} → 掩码 0x00/0xff
    2c5a: 44 8a 04 07     mov  (%rdi,%rax,1),%r8b
    2c5e: 44 8a 0c 06     mov  (%rsi,%rax,1),%r9b
    2c62: 45 30 c1        xor  %r8b,%r9b
    2c65: 41 20 c9        and  %cl,%r9b      ; ← 掩码在此
    2c68: 45 30 c1        xor  %r8b,%r9b
    2c6b: 44 88 0c 07     mov  %r9b,(%rdi,%rax,1)
    2c72: 48 39 c2        cmp  %rax,%rdx     ; ← 唯一回边，判据是公开 len
    2c75: 75 e3           jne  2c5a
```

- 逐字节比较：未修与已修的 `cmov` 指令字节**除尾部对齐填充 `0f 1f 00` 外完全相同**。
- 唯一条件跳转的判据是参数 `len`（调用点传常数 `0x20`），与秘密无关；
  **没有 `cmov`（条件传送）指令参与掩码**——掩码走的是 `neg/and/xor` 算术路线。

### 2.3 `verify` 函数体

`pqcrystals_ml_kem_768_ipd_ref_verify`（`0x2c20`）在两变体上字节完全相同
（`*.bytes` SHA-256 同为 `056479975765099d3d3c3a9d8e6d3ff9bfbc15aff8027b06fc27fbd2222275e7`）：
循环累积 `xor`+`or`，末尾 `test %cl,%cl` + `setne %al` 无分支产出 0/1；回边判据是 `len`。

**结论口径**：在 M1 这两个固定产物上，“M1 `cmov` 无 `__asm__` 值屏障”这一源码层机制
**没有被编成分支或条件传送**；掩码只作数据参与 `and/xor`。故 R05 1.5 第 2 类由“机制存在、未观测”
更新为**不存在（本产物上未观测到分支；阴性不等于恒时证明）**，并把“为什么会有这一格”的原因
（屏障缺失是**可移植性隐患**，不是本产物的实测泄漏）写进格里。

**边界（必须一起读）**：这只是 Clang 18.1.3、`-Os -fno-vectorize`、上述两个固定 ELF 的结论。
屏障缺失的隐患是：换编译器/优化级别/内联布局后，`verify` 的返回值或 `cmov` 的 `b` 可能被重新折成分支。
本轮**没有**做换编译器的对照，所以该隐患仍是未验证风险，不是已证伪。

---

## 3. M1 隐式拒绝 × 失败路径：**不存在**（成功/失败同一条直链）

同 2.1 的 `dec` 函数体：

- `0x2a7f`–`0x2b4f` 共 58 条指令，**0 条条件跳转、0 条无条件跳转**（只有 6 处 `call` 与 1 处 `ret`）。
- 返回值恒为 0：`2b3c: xor %eax,%eax` → `2b3f: ret`；没有第二条返回路径，也没有对 `fail` 的 `test/jne`。
- `fail` 的唯一去向是 `2b26: test %ebx,%ebx` → `2b28: sete %cl` → `2b37: call cmov` 的第 4 实参；
  它只改 `ss[0..32)` 的**取值**（`cmov(ss, rkprf_out, 32, !fail)`），不改调用序列、不改返回码。
- 上层封装 `OQS_KEM_ml_kem_768_ipd_decaps`（`0x28b5`）是 `jmp 0x2a7f` 的尾调用；
  `mlkem_decapsulate`（`0x1fe0`）只在长度/空指针不合法（公开参数）时 `ret` `0xffffff9c`，
  合法路径 `call OQS_KEM_ml_kem_768_ipd_decaps` 后 `neg/sbb` 把错误码折成 0/-1，不据 `fail` 分支。
- 补丁前后该函数体逐字节同一（同 2.1 的位移说明）。

由此，R05 1.5 第 5 类的证明强度从“C 源码层面无条件 + 整段私钥日志无命中”
提升为“**本产物 `dec` 内无任何跳转、返回码单点**”。

---

## 4. 补充：哈希 G/H/J 在 M2 / M5 的秘密标记结果

### 4.1 M2（本轮新增，`remote-tree/m2-ctgrind/`）

R05 §2.2 原来引用的 varlat 日志只覆盖 3 个多项式热点，且探针只调用 `poly_tomsg`/`poly_compress`/
`polyvec_compress` 三个函数，**从未走过完整解封装**，因此哈希步骤实际没有秘密标记证据。本轮补上：

- 探针 `remote-tree/m2-ctgrind/probe/probe_dec.c`（SHA-256 `a4b10060a066f34ff53d161db50966c4347b00e56ac8f2a772c181591ec87be0`）：
  调用同一份 vendor 源码的 `crypto_kem_keypair` / `crypto_kem_enc` / `crypto_kem_dec`，
  用 `VALGRIND_MAKE_MEM_UNDEFINED` 把 `sk` 的 **1152 字节 PKE 私钥**按 8 个分区累积标记；
  共享秘密在消费前用 `VALGRIND_MAKE_MEM_DEFINED` 显式 declassify。
  构建：`clang -O1 -g -DNDEBUG -DKYBER_K=3`，未加屏障类编译选项（`__asm__` 值屏障来自上游 `verify.c:51` 本身）。
- 运行：2 变体 × 8 分区 = **16 次**，每次 `--error-exitcode=99 --track-origins=yes`，
  最后一次分区标记覆盖整段 1152 字节。日志 `remote-tree/m2-ctgrind/logs/*.log`，汇总 `run-log.txt`。
- 结果：**16/16 都是 `256 errors from 1 contexts`**，且这唯一一个上下文每次都相同：

```
Conditional jump or move depends on uninitialised value(s)
   at 0x10BBE8: pqcrystals_kyber768_ref_poly_frommsg (poly.c:167)   ← 未修 / (poly.c:178) ← 已修
   by 0x10B384: pqcrystals_kyber768_ref_indcpa_enc (indcpa.c:269)
   by 0x10B75C: pqcrystals_kyber768_ref_dec (kem.c:114)
 Uninitialised value was created by a client request
   at 0x1093A4: mark_secret_range (probe_dec.c:49)
```

  即：**哈希 G/H/J（`sha3_512` / `sha3_256` / `shake256`）与密文比较路径上没有任何
  秘密相关的条件跳转/条件移动**；唯一命中的是重加密里的 `poly_frommsg`（第 1 节的“存在”格）。
  该结论对未修与已修两侧都成立。
- 边界：Memcheck 只报“实际执行到的、以未初始化值判定的分支/条件传送”。
  它不覆盖非分支类时间差异（那由 varlat 覆盖：3 个上下文都在多项式热点，无 FIPS202 帧），
  也不是恒时证明。Keccak 的轮数与长度循环由公开常数驱动，本轮未观察到秘密依赖。

### 4.2 M5（引用既有，未重跑）

`docs/evidence/m5-completion-20261016/software-dynamic-evidence.tar.gz` → `logs-v2/`：
标记范围 PKE 私钥 1152 B + 拒绝秘密 z 32 B，共 1184 B；10 次完整解封装；

| 日志 | ERROR SUMMARY | 退出码 |
|---|---|---|
| `logs-v2/system.valgrind.log` | `0 errors from 0 contexts` | 0 |
| `logs-v2/varlat-no.valgrind.log` | `0 errors from 0 contexts` | 0 |
| `logs-v2/varlat-yes.valgrind.log` | `0 errors from 0 contexts` | 0 |

`logs-v2/system.stdout` 末行 `mode=valgrind_secret_marked pke_secret_bytes=1152 rejection_secret_bytes=32 ciphertext=public`。
即 M5 参考路径的哈希 G/H/J 与重加密在秘密标记下**无命中**（与 R05 §3.2、§3.3 一致，本轮只复核原件、不重跑）。

---

## 5. 补充项未完成：M5 重加密步骤的 Binsec `checkct` = **unknown（有具体阻塞原因）**

按 R05 §4.4 的边界，Binsec 本轮**只开 `control-flow,memory-access`**，`multiplication`/`dividend`/`divisor`
未开（帮助原文：“Multiplication and division checks are experimental”），
且 M2 的 `div` 类判定本来就与 Binsec 无关。以下是把边界推到 M5 重加密时遇到的**可复现阻塞**。

复用工具（与 M4 同一份安装，未改动）：`platform-m4-binsec-20261016-73f14add5392/runtime/…/binsec`，
Binsec 0.11.3、Z3 4.15.3；身份与摘要见 `remote-tree/binsec-m5/tool-identity.txt`。

| 实验 | 配置 | 结果 | 原件 |
|---|---|---|---|
| A | `-isa amd64` 加载 M4 的 i386 静态 ELF | `[sse:fatal] Can not resolve decoder for x86-64`；`sse:warning overwriting image isa (x86-32) with x86-64`；exit 2 | `A-amd64-on-i386.{out,err}` |
| B | 去掉 `secret global` 声明，其余同 M4 原配置 | `[sse:fatal] Unable to resolve the initial state`（`m4_public_length` 无类型信息）；checkct 在 **0 路径 / 0 指令**下仍打印 `Program status is : secure` | `B-no-symbolic.{out,err,checkct.toml}` |
| B2 | M4 原配置（阳性对照） | `[checkct:result] Instruction 0x8049047 has control flow leak` → `Program status is : insecure`；32/32 路径 | `B2-with-symbolic.{out,checkct.toml}` |
| B3 | 把 `m4_secret_input` 与 `m4_public_input` 都声明为 `public global` | 32 条路径全部完成，checkct 却报 `Program status is : secure` —— **对同一已知脆弱内核的假阴性** | `B3-free-public-input.{cfg,out,checkct.toml}` |
| B4 | 只留 `public global m4_secret_input`（`uint32_t … = 16` 语法不被接受，脚本解析失败） | 0 路径，仍打印 `secure` | `B4-secret-public-only.{cfg,out,err}` |
| C | 默认 loader 直接加载 **M5 的 x86-64 ELF** `build-v2-ordinary/platform_m5_poison` | `[sse:fatal] Can not resolve decoder for x86-64`；exit 2 | `C-m5-default-isa.{out,err}` |

阻塞原因（三条独立、都已实测）：

1. **架构**：Binsec 0.11.3 的 `-isa` 列表虽含 `x86-64`，但解码器不存在（实验 A、C）。
   M5 的正式产物是 x86-64 ELF，`checkct` 根本进不去。
   退路（重编 i386）也不通：远端 `clang -m32` 缺 32 位运行库
   （`Scrt1.o`/`crti.o`/`crtbeginS.o`/`-lgcc`/`-lgcc_s`，见 `remote-tree/tmp/probe32.err`）；
   M4 那条 i386 路径之所以能建，是 `-ffreestanding -nostdlib -fno-pie -Wl,-e,<entry>` 的裸机链接
   （`cmake/PlatformM4.cmake`），要为 M5 造同样的驱动属于新增工程。
2. **模型**：`checkct` 用显式 `secret global` 声明才能判“秘密相关”。
   实验 B/B4 显示：没有可用声明时，工具仍输出 `Program status is : secure`，
   而那是在 **0 条路径、0 条指令**上的空结论；实验 B3 显示把输入声明成 `public` 会让
   已知脆弱内核翻成假阴性。即：**不能拿一个“没配好”的 checkct 结果当 M5 的阴性证据**。
3. **状态空间**：M5 重加密的消息是 32 字节（`MLKEM_INDCPA_MSGBYTES`）自由值，
   `poly_frommsg` 的每个消息位都会分叉；把消息设成秘密/自由会让路径数达 2^256 量级，
   在有界模型内必然落到 `unknown`。M4 的对照能做完是因为秘密只有 16 字节、公开长度被钉在 1..16。
   若为了可判定而把消息取值域人为收窄（例如每系数只取 `0x0000`/`0x0681`），
   分析的是**另一个**（受约束的）模型，不能声称覆盖“完整重加密步骤”。

因此这一条按“**unknown + 参数**”登记，不写“不存在”。
本轮对 M5 重加密能给的仍是第 4.2 节的 Memcheck（含 G/H/J 与重加密的完整解封装、0 命中）
与 R05 §3.3 的反汇编（`poly_frommsg` 唯一跳转由 `cmp $0x20,%rax` 判定）。
若要真正补上 Binsec 一侧，需要的是新工程：i386 裸机驱动 + 单比特/受约束域的显式声明，
并把“受约束模型”与“完整步骤”的差别写进结论——超出本轮 T15 的范围。

---

## 6. 本次未改动 / 未主张

- 不修改 `docs/evidence/{m2-kem,m2-kyberslash,m3-*,m4-*,m5-*}-20261016/` 下任何文件；本轮产物只在本目录与远端新根。
- 未 `git add/commit/push`；未 sudo；未跑锁频；未做密钥恢复；未在 `/tmp` 落盘（远端临时路径全部在根内）。
- 所有“不存在/阴性”都只对本文写明的固定源码 + 编译器 + 选项 + 产物成立，不是恒时证明，
  不给总体误报率、不给 FIPS 203 认证结论。
