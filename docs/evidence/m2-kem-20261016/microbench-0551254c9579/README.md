# M2 除法热点微基准层（`B06`）：构建、资格、命令清单与运行核对

2026-10-16。子树 `/home/nss-marker/yhr/Cry/platform-m2micro-20261016-0551254c9579/`。
本目录是本地证据副本。作者（微基准任务）负责：新增微基准入口、两臂构建、反汇编证明、
独立功能资格、可复制命令清单，以及运行后的只读核对；作者没有 sudo，**不自行运行锁频控制器**。
六个预注册 run 由 lead 用本目录同一批命令执行（2026-10-16 02:39–02:40），
统计结论见同目录 `RESULT.md`；本文件只描述"仪表"及其资格，不复述也不改写该统计结论。

## 1. 触发与范围

- 端到端主类对 Holm 家族（m = 6）全部不拒绝（`docs/evidence/m2-kem-20261016/RESULT.md`），
  冻结 PLAN §5.1 的触发条件成立，因此必须补微基准层。
- 窗口**只包除法热点**：一次 `pqcrystals_kyber768_ref_poly_tomsg`
  （PLAN §5.2 点名的消息压缩除法），meta 记 `window_scope=one_poly_tomsg_call`；
  反汇编证明窗口内只有这一条 `call`（`disasm/ordinary-*-microbench-window.asm`，18 行）。
- 预算/运行表与 PLAN §3.1/§3.2 一致：3 run × 2 臂、每类 10000、预热 100；
  微基准是**单独标记的探索族**，不与端到端 p 合并，不得用微基准阳性冒充端到端阳性。

## 2. 固定产物

| 项 | 值 |
|---|---|
| 未修微基准 ELF（唯一允许的微基准产物） | `/home/nss-marker/yhr/Cry/platform-m2micro-20261016-0551254c9579/build-ordinary/microbench/unfixed/m2_hotspot_microbench` |
| └ SHA-256 | `984f6b071311b64d7872fa7b185e0e8096da4bc796347a7481b0729ddbbe3287`（137656 B） |
| 已修微基准 ELF | 同树 `build-ordinary/microbench/fixed/m2_hotspot_microbench` |
| └ SHA-256 | `2daa017de53d6c139028fde8a6f4ce60a9c0ed0516c55384ee82f7420cde5289`（137688 B） |
| 资格 ELF（不参与计时） | 同树 `build-ordinary/qualification/{unfixed,fixed}/m2_hotspot_qualification`，`aa90eb9c…` / `99170ef8…` |
| sanitizer 微基准 ELF（只做内存/UB 资格） | `build-sanitize/microbench/{unfixed,fixed}/m2_hotspot_microbench`，`35084794…` / `2590b1af…` |
| 编译器与选项 | `/usr/bin/clang-18`（Ubuntu clang 18.1.3）、CMake 3.28.3、`RelWithDebInfo` = `-O2 -g -DNDEBUG`；新入口加 `-Wall -Wextra -Wpedantic -Wshadow -Wconversion -Wstrict-prototypes -Werror`；vendor 另加 `-Oz -g -fno-vectorize -fno-slp-vectorize -DKYBER_K=3` |
| 源码树 | `<tree>/source/` 是 `collector-v2-2e894561892a/source` 的 `cp -a` 副本 |
| └ 副本核对 | `diff -rq` **完全相同**；对冻结 `SOURCE_TREE.sha256` 复核 **592 项通过 / 2 项陈旧**，两个陈旧项（`COLLECTOR_V2_ADDITIONS.sha256`、`tools/platform_m2/README.md`）在**冻结原件上同样失败**（`frozen_ok=592 / frozen_stale=2`），即清单早于这两份文件定稿，与本次复制无关 |
| 新增文件清单 | `<tree>/MICRO_ADDITIONS.sha256`（8 条）；`<tree>/EVIDENCE.sha256`（224 条）；`<tree>/ELF.sha256`（6 条） |
| ldd | 只有 `libc.so.6` 与 loader（无 OpenSSL） |

## 3. 反汇编证据（`disasm/`）

`div/idiv` 计数（普通构建，冻结脚本 `tools/platform_m2/collect_binary_evidence.sh` 原样复用）：

| 符号 | 未修微基准 | 已修微基准 |
|---|---:|---:|
| `pqcrystals_kyber768_ref_poly_tomsg` | **1** | **0** |
| `pqcrystals_kyber768_ref_poly_compress` | 1 | 0 |
| `pqcrystals_kyber768_ref_polyvec_compress` | 1 | 0 |
| `pqcrystals_kyber768_ref_dec` | 0 | 0 |
| `mlkem_decapsulate` | 0 | 0 |

- 未修热点体内层循环是一枚 32 位 `div %r9d`（`51da` 起），已修热点是
  `imul $0x275f6` + `add $0x8009a7b` + `shr $0x1c` 的乘加序列。
- `ordinary-{unfixed,fixed}-microbench-window.asm` 给出窗口边界：
  起点 `clock_gettime`（`0x25ad`）→ 一次 `call pqcrystals_kyber768_ref_poly_tomsg`（`0x25e4`）
  → 终点 `clock_gettime`（`0x25f6`），两臂结构相同；窗口内没有 I/O、分配或别的函数调用
  （`atomic_signal_fence` 在 x86 上不生成指令）。
- `poly_compress` / `polyvec_compress` 虽在同 ELF 内，但只在**窗口外**的输入构造阶段
  （`platform_m2_test_message` → `indcpa_enc`）各执行一次，不在计时窗口内。
- `sanitize-*` 的 `div` 计数全为 0：`-O1` 覆盖 vendor 的 `-Oz` 后机制静默消失
  （与 `COLLECTOR_CONTRACT.md` §4 同一限制），故 sanitizer 产物不得用于机制对照。
- `NOTE-poly_tomsg-minus2497.txt`：登记已修臂在 `poly_reduce` 之后可达的系数值 −2497 上
  与未修臂位输出不同；本微基准两类输入（各 256 系数、两臂共 1024 个系数，含 265 个负系数）
  **都不含该值**，两臂输出逐字节相同，不影响本层结论。

## 4. 功能资格（`qualification-ordinary/`，`micro-qualification.log`）

- 资格驱动每个臂 15 项检查全 PASS、0 FAIL、0 SKIP（`qualification-{unfixed,fixed}.log`），
  关键三项为**逐字节对照**：
  1. `hotspot_input_matches_decapsulation`：链接期 `--wrap=pqcrystals_kyber768_ref_poly_tomsg`
     抓住真实 `mlkem_decapsulate` 路径喂给热点的多项式，与微基准推导值 512 B `memcmp` 相同
     （类 `message-zero`、`message-ones` 各一次，另有 KAT 一次）；
  2. `hotspot_output_matches_decapsulation`：热点输出与同源码 `indcpa_dec` 输出 32 B 相同；
  3. `collector_input_sequence_digest`：用采集件同一份 `collector_inputs.c` 在
     (seed 31337, 每类 100, message-zero/message-ones) 下重算的行序密文序列 SHA3-256
     ＝ 冻结采集件 `smoke/main_u_seed31337.meta` 的 `input_sequence_digest`
     `24380996a75cabcd6fa3ef7299d8591f258b1f9be6a56005ff1accec94a4df80`。
- `decapsulation_calls_hotspot_once`：一次完整解封装只调用该热点 1 次（两臂一致）。
- 公开 round3 KAT（100 例）另由冻结采集件的 `m2_platform_kat` 只读执行复核：
  两臂 `kat-{unfixed,fixed}.log` 均为 100 例通过；资格驱动另取 KAT 第一条 `count = 0`
  核对 `mlkem_decapsulate` 共享秘密与向量 `ss` 相同、热点输入一致。
- ASan/UBSan 两臂资格同样 15/15（`qualification-sanitize-*.log`），无 ASan/UBSan 报错。
- 跨臂转录 `transcript-{unfixed,fixed}.txt`：`cmp` **逐字节相同**。
- CLI 准入 12 条：无参/未知选项/未知类/格式破坏类/重复类/0 样本/超样本/非十进制 seed/
  0 预热/缺 `--raw` → 退出 2；缺公钥/短公钥 → 退出 1；**均不留任何输出文件**。
- 普通与 sanitizer 两棵树的 CTest 各 2/2 通过（`ctest-build-{ordinary,sanitize}.log`）。
- 冻结 `platform_stats`（`ddc48b9e…`）直接解析冒烟 CSV 成功
  （`qualification-smoke/measure-format-check/`），证明六列表头与 `--format measure` 兼容。

## 5. 解锁冒烟（`qualification-smoke/`）——**不是结果，不得引用为结论**

未绑核、未锁频（meta 记 `cpu_affinity=not_pinned`、`frequency_control=not_configured`）。
仅用于证明入口可跑、协议自洽、格式兼容。逐条观察（描述性，不作任何统计或泄漏判断）：

| 冒烟 | 臂 | n | 均值 ns | 最小 | 最大 |
|---|---|---:|---:|---:|---:|
| `smoke-unfixed` | 未修 | 400 | 300.8 | 290 | 401 |
| `smoke-fixed` | 已修 | 400 | 143.8 | 140 | 240 |
| `smoke-unfixed-seed424242` | 未修 | 400 | 310.1 | 290 | 3377 |

同 seed 重放行序逐字节相同；换 seed 只改行序不改每类计数；
两臂 `input_sequence_digest` 相同（同一批输入）。
**值得 lead 注意的两点**（都只来自未锁频冒烟，正式判定以六个锁频 run 为准）：

1. **臂间**差异很大（≈ 300.8 ns vs 143.8 ns，即每次 `poly_tomsg` 调用上
   `div` 机制约贵 157 ns）；**类间**差异很小（未修 300.6 vs 301.1 ns，
   已修 143.8 vs 143.9 ns）。预注册微基准族检验的是**类间**对比
   （`message-zero` − `message-ones`，臂内），因此本层很可能同样给出"未检出"，
   而臂间机制差是结构性的。
2. 机制解释（**假设**，非结论）：一次 `poly_tomsg` 有 256 枚**相互独立**的除法，
   Zen 的分支器在乱序窗口里可重叠执行，实测 ≈ 6.6 cycles/div（5.6 GHz 下 301 ns/256）
   远低于单枚 `div` 的串行延迟量级，说明窗口是**吞吐受限**而非延迟受限；
   操作数幅度（商 0 vs 商 1）带来的单枚延迟差因此大部分被吸收。
   PLAN §6.2 禁止因显著性换类对或增样，所以本层不追加类别；
   若要提高类间灵敏度，只能由 lead 走 PLAN 修订另立新族。
   锁频后的正式结果与此方向一致（见 `RESULT.md`：微基准族 m = 6 拒绝 0，
   合并 Δ = +0.044 ns、CI 含 0），而臂间机制差在本产物上仍是结构性的。

## 6. 命令清单、执行与运行后核对

见 `COMMANDS.md`（运行表、展开命令、有效性判据、统计命令、已知注意项）与
`run_controller_microbench.sh`（六个 run 的完整命令，整份可复制）。

**六个 run 已由 lead 按该清单执行完毕**，原始 CSV/meta 在 `<tree>/runs/<run-name>/` 下。
作者随后做了独立只读核对（`verify_completed_micro_runs.sh` → `micro-runs-verification.log`）：

```
verified_runs=6 pending_runs=0 failed_checks=0
micro_run_verification_status=PASS
```

逐项检查包括：CSV 表头逐字节、20001 行、每类 10000、`time_unit=ns`、
`run_status=complete`、预热三字段 = 100、`window_scope=one_poly_tomsg_call`、
热点不符计数 0、`zero_elapsed_count=0`、ELF 自哈希与 meta 一致、min/max 与 CSV 一致、
同一 seed 的 `input_sequence_digest` 在跨 run/跨臂上一致，以及控制器 `terminal.json` 的
四个有效性条件（`reason=worker_finished`、`worker_exit_code=0`、`worker_drained=true`、
`restore_match=yes`）。原始逐次数据摘要见 `RUNS.sha256`（6 份 CSV + 6 份 meta）；
本地副本 `runs/*.csv.gz` 解压后与远端原字节摘要**逐份一致（6/6）**。

## 7. 失败归档

`failed/attempt-01-script-defects/`：第一次资格脚本运行的现场（MANIFEST + SHA256SUMS + 原字节副本）。
失败原因全部在资格脚本自身（摘要 grep 锚点、`unit` 列计数差一、`platform_stats` 输出文件名写错），
微基准与资格 ELF 本身无缺陷；修正后重跑 0 失败。归档原件未改写。

## 8. 远端树结构与临时目录

```
platform-m2micro-20261016-0551254c9579/
  source/                       冻结采集件源码树的逐字节副本 + 本次新增 8 个文件
  build-ordinary/ build-sanitize/   两棵构建树（普通/ASan+UBSan）
  disasm/ ELF.sha256 RUNS.sha256 EVIDENCE.sha256 MICRO_ADDITIONS.sha256
  qualification-ordinary/ qualification-smoke/ failed/
  runs/<run-name>/              六个 run 的原始 CSV/meta
  tmp/                          一次性诊断探针与自检现场（**不属于证据**）
  README.md COMMANDS.md NOTE-poly_tomsg-minus2497.txt run_controller_microbench.sh
  verify_completed_micro_runs.sh micro-qualification.log micro-runs-verification.log
```

`tmp/` 里是作者的一次性诊断（例如确认两臂在同一多项式上输出一致的探针），
不参与任何结论，也未纳入 `EVIDENCE.sha256`。

## 9. 边界（不构成的主张）

- 微基准层只覆盖本固定输入、本机、本预算、本产物；**未检出 ≠ 恒时**，
  微基准阳性也不得冒充端到端阳性（PLAN §5.3 三层必须分别报告）。
- 本层不主张物理频率精度、不主张逐调用恒频；微基准 ns 值不换算 cycles。
- 未执行密钥恢复或 exploit 演示；未改 vendor、未改已冻结采集件、未写频率/隔离，
  未使用 sudo，未 git add/commit/push。
- **微基准层状态**：构建、机制证明与功能资格已完成；六个预注册 run 已由 lead 执行，
  并通过上述独立只读核对。统计结论（独立探索族 m = 6、Holm 拒绝数 0、合并 Δ 的 CI 含 0）
  见同目录 `RESULT.md`，本文件不复述、不改写。
