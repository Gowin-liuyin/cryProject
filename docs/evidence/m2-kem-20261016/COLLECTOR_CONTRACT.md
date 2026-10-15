# M2 collector-v2 采集合同

2026-10-16。状态：**采集件已就绪并冻结；本轮未执行正式锁频采数**。
主控按本文件 §7 的命令在 `tools/platform_control` 锁频控制器内执行即可；采数前后仍须按冻结 PLAN 管理频率与恢复。

本轮只新增源与产物，不覆盖、不改动 `platform-m2kem-20261016-d75a4019/` 下的旧件，
也不使用旧 `build-ordinary/platform-m2/{unfixed,fixed}/measure`（它仍在原位，另作他用）。

## 1. 对象与源码身份

| 项 | 值 |
|---|---|
| 未修链 | `pq-crystals/kyber` `a621b8dde405cc507cbcfc5f794570a4f98d69cc`（KyberSlash1 修复的直接父提交） |
| 已修链 | `pq-crystals/kyber` `272125f6acc8e8b6850fd68ceb901a660ff48196`（含 KyberSlash1+2 修复） |
| 算法身份 | 历史 Kyber768 round3 SHAKE，`KYBER_K=3`，**非 FIPS 203**，非 90s |
| 上游 dudect | `oreparaz/dudect` `dc269651fb2567e46755cfb2a13d3875592968b5`，MIT |
| 源树根（远端） | `/home/nss-marker/yhr/Cry/platform-m2kem-20261016-d75a4019/collector-v2-2e894561892a/source` |
| 源树清单 | `SOURCE_TREE.sha256`（594 条），SHA-256 `c5368cd0604451e614efabf863c0c310080dd2ca25609f31aae6557dc36316ac` |
| 冻结导出清单 | `source/SOURCE_EXPORT.sha256`（父树 575 条，逐项 `sha256sum -c` 通过），SHA-256 `7f721febeaaac826bc38de05b3470439d656792ac379a083baead82bc0b92146` |
| 本轮新增清单 | `source/COLLECTOR_V2_ADDITIONS.sha256`（17 条目），SHA-256 `d0402c6cb08cb23dc9ca639b3b00b58564e527d47f70209ff0c621c4bddbbc03` |

`source/` 是父树 `source/` 的 `cp -a` 副本（逐项摘要校验通过）加上表内 17 个新增文件；
`vendor/` 与既有 `src/`、`include/`、`tests/` 未改动。新增文件为：

- `tools/platform_m2/{collector.c,collector_inputs.c,collector_inputs.h,collector_selftest.c,dudect_online.c,keypair_tool.c,CMakeLists.txt,README.md}`
- `tools/platform_m2/{run_collector_build.sh,run_collector_qualification.sh,run_dudect_readiness.sh,collect_binary_evidence.sh,test_collector_cli_guards.cmake,test_collector_equivalence.cmake}`
- `cmake/PlatformM2Collector.cmake`（独立模块，根构建显式 `include()` 不含它，故根构建行为不变）
- `third_party/dudect/{LICENSE,src/dudect.h}`（上游原件拷贝）

## 2. 构建身份

机器 `nss-m`：AMD Ryzen 9 9950X、32 线程、x86_64、Ubuntu 24.04、Linux 6.17.0-35-generic、
Clang 18.1.3（`/usr/bin/clang-18`）、CMake 3.28.3。**非 root、未使用 sudo、未写 sysfs。**

构建入口：`source/tools/platform_m2/run_collector_build.sh <tree-root>`（普通与 ASan/UBSan 两棵树）。
configure 关键选项：

```
cmake -S <source>/tools/platform_m2 -B <tree>/build-ordinary \
  -DCMAKE_C_COMPILER=/usr/bin/clang-18 -DCMAKE_BUILD_TYPE=RelWithDebInfo \
  -DCMAKE_C_FLAGS="-isystem <tree>/dependencies/sysroot/usr/include/x86_64-linux-gnu" \
  -DOPENSSL_ROOT_DIR=<tree>/dependencies/sysroot/usr \
  -DOPENSSL_INCLUDE_DIR=<tree>/dependencies/sysroot/usr/include \
  -DOPENSSL_CRYPTO_LIBRARY=/lib/x86_64-linux-gnu/libcrypto.so.3
# sanitize 树追加 -DM2_COLLECTOR_SANITIZERS=ON
```

实际编译选项（取自 `flags.make`）：

| 目标 | 选项 |
|---|---|
| `*_vendor`（上游 ref 10 文件） | `-O2 -g -DNDEBUG -Oz -g -fno-vectorize -fno-slp-vectorize`，`-DKYBER_K=3 -Drandombytes=platform_m2_randombytes` |
| `platform_m2_*`（适配层） | `-O2 -g -DNDEBUG -Wall -Wextra -Wpedantic -Wshadow -Wconversion -Wstrict-prototypes -Werror` |
| collector / selftest / keypair | 同上告警口径 |
| `m2_dudect` | `-O2 -g -DNDEBUG`（第三方 dudect 头不加仓库告警口径，与 M4 先例一致） |
| `M2_COLLECTOR_SANITIZERS=ON` 时 | 上述各目标追加 `-O1 -g -fsanitize=address,undefined -fno-omit-frame-pointer`（**sanitizer 产物只做软件资格，不用于采数**） |

## 3. 采集 ELF

绝对路径（远端，普通构建）：

```
/home/nss-marker/yhr/Cry/platform-m2kem-20261016-d75a4019/collector-v2-2e894561892a/build-ordinary/collector/unfixed/m2_decaps_collector
/home/nss-marker/yhr/Cry/platform-m2kem-20261016-d75a4019/collector-v2-2e894561892a/build-ordinary/collector/fixed/m2_decaps_collector
```

| ELF | SHA-256 | 大小 |
|---|---|---|
| `unfixed/m2_decaps_collector` | `b1e820e848d83cb334a967c64573c3c3355451e6e72778b45af96724e9c96b5d` | 131320 B |
| `fixed/m2_decaps_collector` | `c9cecdafb6bb855c44f08e52289baf2754fc6376fde0422ec004ec8945f4e9a8` | 135448 B |

同一目录另有 online dudect 入口 `m2_dudect`（§9）。本文件的本地证据副本
`docs/evidence/m2-kem-20261016/collector-v2-2e894561892a/artifacts/` 保存了这四个 ELF 的原始字节，
本地 `shasum -a 256` 结果与上表逐字节一致。

`ldd`（两个采集 ELF 相同，只有 libc 与 loader，**无 OpenSSL、无 libcrypto**）：

```
	linux-vdso.so.1 (0x00007...)
	libc.so.6 => /lib/x86_64-linux-gnu/libc.so.6 (0x00007...)
	/lib64/ld-linux-x86-64.so.2 (0x00007...)
```

sanitizer 树的两个 `m2_decaps_collector`（只做软件资格）：
`unfixed` `9b08e5b166a686b908b519b3fa7ed42d9d6b7ce948c7fb9699ad1a76d12c63a1`、
`fixed` `709b2ef653a103cf94636185da68ac6a3a00cf5d525dc80c003ce162d4fec3d5`。

## 4. 反汇编证据与调用边界

`disasm/` 保存 6 个 ELF × 5 个符号的 `objdump -d` 原文与操作码直方图，
`*-division-counts.txt` 给出 `div/idiv` 计数（普通构建）：

| 符号 | unfixed | fixed |
|---|---:|---:|
| `pqcrystals_kyber768_ref_poly_tomsg` | **1** | 0 |
| `pqcrystals_kyber768_ref_poly_compress` | **1** | 0 |
| `pqcrystals_kyber768_ref_polyvec_compress` | **1** | 0 |
| `pqcrystals_kyber768_ref_dec` | 0 | 0 |
| `mlkem_decapsulate` | 0 | 0 |

调用边界（`disasm/ordinary-unfixed-collector-mlkem_decapsulate.asm`，两条链一致）：
`mlkem_decapsulate` 先比较长度 `0x960=2400`、`0x440=1088`、`0x20=32` 并判三个指针非空，
任一不满足返回 `0xffffff9c = -100`；全部通过后 `jmp pqcrystals_kyber768_ref_dec`，
进入未改动的原 `kem.c` 完整解封装（解密 → 重加密 → 常数时间比较 → 接受或隐式拒绝）。
即：**长度/空指针先验在封装层，长度合法即进入完整内核，不存在提前返回的捷径。**

链接符号：`randombytes` 在构建期被重命名为 `platform_m2_randombytes`
（`nm`：`T platform_m2_randombytes`），普通 ELF 的动态未定义符号只有 libc 条目；
NIST DRBG/OpenSSL 只出现在资格二进制里，不在采集 ELF 里。

**重要限制（本轮实测发现）**：sanitizer 构建的 `div` 计数三个热点**都是 0**，因为
`M2_COLLECTOR_SANITIZERS=ON` 追加的 `-O1` 覆盖了 vendor 的 `-Oz`，LLVM 在 `-O1`
下会把"除以常数"折成乘加序列（这正是 KyberSlash 修复手工做的变换）。
因此：`div` 机制断言**只对 §2 那组普通构建选项成立**；
sanitizer 产物只可用于内存/UB 资格，不得用于机制或"已修/未修"指令级对照；
换用其它优化级别重建会让该机制静默消失，采集件必须锁定为本文件的两个摘要。

## 5. 输入类

| 类名 | 构造（同一固定公开公钥） | 期望路径 |
|---|---|---|
| `message-zero` | 实际解密消息 0x00 的密文：`G(00…0‖H(pk))` → 原 `indcpa_enc` | 重加密验证通过（接受） |
| `message-ones` | 实际解密消息 0xFF 的密文：`G(FF…F‖H(pk))` → 原 `indcpa_enc` | 重加密验证通过（接受） |
| `malformed-zero-tail` | 同一 `message-zero` 密文，前 1056 字节不变、**末 32 字节置 0x00** | 原 `kem.c` 隐式拒绝 |
| `malformed-ff-tail` | 同一 `message-zero` 密文，前 1056 字节不变、**末 32 字节置 0xFF** | 原 `kem.c` 隐式拒绝 |

前两个是**主类对**，后两个是**对照类对**。四个类长度都恰好 1088 字节（ABI 合法），
对照类不触发长度拒绝，走的是完整解封装里的隐式拒绝分支。
对照类只做族外描述性报告，不进 Holm 家族（与主类对的秘密依赖不同源）。
`collector_selftest` 用独立实现的拒绝公式 `SHAKE256(z‖H(ct))`（`z` 取 sk 末 32 字节）逐例核对，
并核对 `indcpa_dec` 对主类对分别得到全 0x00 / 全 0xFF。

`--class` 取值：上述四个名字，逗号分隔（不允许重复/空字段），或 `all`（四个类）。
**主类对与对照类对分两次独立调用、两个独立 CSV**，因此对照行不可能混进主 CSV。

## 6. 测量协议

- **窗口**：`clock_gettime(CLOCK_MONOTONIC)` → `atomic_signal_fence(memory_order_seq_cst)` →
  `mlkem_decapsulate(ss,32,ct,1088,sk,2400)` → `atomic_signal_fence(memory_order_seq_cst)` →
  `clock_gettime(CLOCK_MONOTONIC)`；单位 **ns**，不扣读钟开销、不换算 cycles。
  窗口内不含分支、I/O、分配、结果消费；`mlkem_decapsulate` 返回值在窗口内只做无分支累积。
- **预热**：默认 100 次完整解封装，在计时循环之前、窗口外执行，不进 CSV；
  meta 断言 `warmup_decapsulations=100`、`warmup_attempted_calls=100`、`warmup_completed_calls=100`。
- **窗口外**：公私钥文件读取、密文构造、类顺序生成与洗牌、结果消费与接受路径核对、
  CSV/meta 写入、ELF 自哈希全部在窗口外。
- **类顺序**：先按调用方给出的类列表铺满，再做 Fisher–Yates；随机流为
  `SHAKE256(domain ‖ seed ‖ counter)`（`purpose_tag=4`，与既有 measure 协议同族）。
  同一 `(seed, 类列表, 每类数量)` 的行序逐行可重放；不同 seed 改变顺序但保持每类计数。
- **CSV**：表头逐字节等于
  `run_id,implementation,input_category,sample_index,elapsed_nanoseconds,time_unit`，
  `sample_index` 为 0..N-1 全局行号，`time_unit` 恒为 `ns`；**全量保留**，不裁剪长尾、不删异常；
  `elapsed_nanoseconds` 为 0 的行也保留（meta 另计 `zero_elapsed_count`）。
- **meta**：每行一个 `key=value`，含 `run_id`、`implementation`、`test_seed`、
  `samples_per_class`、`row_count`、`class_list`、`per_class_row_counts`、
  `clock=CLOCK_MONOTONIC`、`time_unit=ns`、`clock_resolution_ns`、`window=...`、`order=...`、
  `input_sequence_digest`（行序密文序列的 SHA3-256，跨版本/跨运行核对同一批输入）、
  `public_key_sha3_256`/`secret_key_sha3_256`（公开测试夹具）、`executable_sha3_256`（自哈希）、
  `minimum/maximum_elapsed_nanoseconds`、`zero_elapsed_count`、`failed_decapsulation_count`、
  `chosen_message_accept_mismatch_count`、`cpu_affinity=not_pinned`、
  `frequency_control=not_configured`、`run_status`。
- **输出**：`--raw` 与 `--meta` 都以 `wx` 新建，**已存在路径必定失败**（不会覆盖已有证据）；
  `--meta` 缺省为 `<raw>.meta`。进程只写这两个调用方给出的路径。
- **worker 合同**：不 fork、不 daemonize、不 setsid、不改 HOME、不写任何其它路径、
  不设 CPU 亲和性（`cpu_affinity=not_pinned`，由外层 `taskset -c 2/6` 决定）。
- 功能门：任一 `mlkem_decapsulate` 返回非 0，或主类对出现接受路径不一致，进程仍写完整
  CSV/meta 但以非 0 退出并把 `run_status=failed` 写进 meta。

## 7. 主控可直接复制执行的命令

```sh
BUILD=/home/nss-marker/yhr/Cry/platform-m2kem-20261016-d75a4019/collector-v2-2e894561892a/build-ordinary/collector
FIX=/home/nss-marker/yhr/Cry/platform-m2kem-20261016-d75a4019/collector-v2-2e894561892a/qualification-ordinary/fixtures
RUN=/home/nss-marker/yhr/Cry/platform-m2-stat-20261016-<nonce>
mkdir -p "$RUN/raw"

# 主类对：每类 10000，共 20000 行
taskset -c 2 "$BUILD/unfixed/m2_decaps_collector" \
  --class message-zero,message-ones --samples 10000 --seed 31337 --warmup 100 \
  --raw "$RUN/raw/m2_r01_unfixed.csv" --meta "$RUN/raw/m2_r01_unfixed.meta" \
  --run-id m2_r01_unfixed --public-key "$FIX/pk.bin" --secret-key "$FIX/sk.bin"

# 对照类对：每类 10000，共 20000 行（另开一个 CSV，绝不混入主 CSV）
taskset -c 2 "$BUILD/unfixed/m2_decaps_collector" \
  --class malformed-zero-tail,malformed-ff-tail --samples 10000 --seed 31337 --warmup 100 \
  --raw "$RUN/raw/m2_r01_unfixed_control.csv" --meta "$RUN/raw/m2_r01_unfixed_control.meta" \
  --run-id m2_r01_unfixed_control --public-key "$FIX/pk.bin" --secret-key "$FIX/sk.bin"
```

fixed 变体把 `unfixed` 换成 `fixed`、并改 `--raw/--meta/--run-id` 即可；
run2 用 `--seed 424242`，run3 用 `--seed 31337` + `taskset -c 6`。

分析入口（两种类对都能喂，`input_category` 与 `--classes` 逐字符串匹配）：

```sh
scripts/run_stats_battery.sh --input "$RUN/raw/m2_r01_unfixed.csv" --format measure \
  --classes message-zero message-ones --output-dir "$RUN/analysis/m2_r01_unfixed" \
  --stats-bin <pinned platform_stats> --rtlf-script <pinned RTLF/rtlf.R>
scripts/run_stats_battery.sh --input "$RUN/raw/m2_r01_unfixed_control.csv" --format measure \
  --classes malformed-zero-tail malformed-ff-tail \
  --output-dir "$RUN/analysis/m2_r01_unfixed_control" \
  --stats-bin <pinned platform_stats> --rtlf-script <pinned RTLF/rtlf.R>
```

注意区分：`scripts/platform_stats/stats_csv.c`（电池用）按字符串匹配类别，未知名只计入
`excluded_other_category_count`；而 `src/timing_statistics.c` 的 `load_measurement_set()`
走历史 5 类枚举，遇到 `malformed-*` 会整份 fail-closed —— 所以对照 CSV 只喂电池这一路。
`samples` 上限 20000/类；`--samples` 是**每类**行数。

## 8. 功能资格结果（普通与动态分开，全部实跑并保存日志）

| 资格 | 普通构建 | ASan/UBSan 构建 |
|---|---|---|
| CTest 总数 | 14/14 通过（`ctest-final-ordinary.log`） | 14/14 通过（`ctest-final-sanitize.log`） |
| 官方 round3 公开 KAT（100 例 × 两变体，逐字核对 pk/sk/ct/ss 与解封装） | 200 例通过 | 200 例通过 |
| 随机回环 + 空指针 + 0/短/长/SIZE_MAX 长度 + 选择消息 + 64 例隐式拒绝 | 通过（两变体） | 通过（两变体） |
| collector 类语义/拒绝公式/类顺序重放（`m2_collector_selftest`） | 通过（两变体） | 通过（两变体） |
| 跨版本等价：160 类例转录 + collector 类/拒绝/顺序转录逐字节相同 | 通过 | 通过 |
| CLI 准入：非法参数/未知类/重复类/越界样本/错误密钥长度/已有输出路径必须失败且不留输出 | 通过（两变体） | 通过（两变体） |
| 系统随机源失败路径（`m2_platform_rng_failure`） | 通过（两变体） | 通过（两变体） |
| 资格脚本 `run_collector_qualification.sh` | 18 步 / 0 失败（`qualification-ordinary.log`） | 18 步 / 0 失败（`qualification-sanitize.log`） |

采集冒烟（在资格脚本内，普通构建）：4 类 × 200 与主类对 2 类 × 100 各跑一次，
断言 meta 全绿、行数精确、最小原始值未被裁剪、同 seed 行序与输入摘要可重放、
不同 seed 只改顺序不改计数、两变体同 seed 行序与输入摘要一致。

## 9. online dudect 入口（已实现，族外辅助）

**结论：可用，已实现并实跑。** 两个 ELF：

| ELF | 绝对路径 | SHA-256 |
|---|---|---|
| unfixed | `.../build-ordinary/collector/unfixed/m2_dudect` | `1c4e19866e7e1986f784d0819a14d993cc76ab5ebcc3ae636483cd9728103c1a` |
| fixed | `.../build-ordinary/collector/fixed/m2_dudect` | `ff92c5df271dc337c78e4b78311fa0e9b99cced59c1b754466e9dea52e038858` |

（前缀同 §3 的 `collector-v2-2e894561892a` 树。）

```sh
DU=$BUILD/unfixed/m2_dudect        # fixed 同理
"$DU" --describe
"$DU" --collect "$RUN/raw/m2_dudect_unfixed.csv" 20 31337 "$FIX/pk.bin" "$FIX/sk.bin"
```

- 直接调用上游 `dudect_main`：每批固定 10000 次回调，回调体只有一次完整
  `mlkem_decapsulate`（+ 一次常量 XOR 消费）；**batch 0 是上游预热/分位批次**，不计入 t 检验，
  所以 20 批 = 1 预热 + 19 检验批 = 200000 次完整解封装。
- 两臂 = `message-zero` / `message-ones`，标签每批严格平衡（5000/5000）后按
  `SHAKE256(seed, counter)`（tag=6）洗牌；同 seed 两变体行序逐行相同（已断言）。
- 原始 tick 在窗口外落盘：`batch_index,batch_role,sample_index,class_label,start_tsc,finish_tsc,elapsed_tsc_ticks`；
  保留上游丢弃的端点与相邻读数，不裁剪。
- 上游阈值 `max|t|>10` 不改；输出 `battery_dudect_status=online_leakage_found|online_no_evidence_yet`。
- **默认阳性粘滞**（跑满批数，符合冻结 PLAN 的"无论是否提前遇到阳性都保留20批"）；
  若需"t>10 即停"，在命令末尾加 `--stop-on-positive`（两种口径都已支持）。
- 单批 10000 次；20 批实测 wall ≈ 8.7–9.5 s、RSS ≈ 12.7 MB（**未锁频**）。

**就绪运行与原样数字（未锁频、未绑核、两进程串行；只能说明环境漂移，不是泄漏结论）**：
`dudect-qualification/` 记录一次 20 批就绪运行（unfixed `online_leakage_found`、
fixed `online_no_evidence_yet`），`dudect-readiness/` 记录更早的同 seed 一次（方向相反：
unfixed `+2.75` 无证据、fixed `+35.87` 阳性）以及 4 次交替顺序诊断（u,f,f,u），
4 次里 3 次阳性且与变体顺序无关；同期 `avg_mhz` 在 3105–3901 间漂移。
因此**正式 online dudect 必须在 CPU2/6 绑核 + 锁频控制器内执行**，
并按 PLAN 的阳性粘滞与"未完成不补签"口径报告；不得引用上述未受控数字作为任一方向的结论。
`run_dudect_readiness.sh` 的 15 项检查全部通过（含两变体行序一致、已有路径拒绝覆盖、行数精确）。
sanitizer 树也构建并跑通 3 批冒烟（`dudect-qualification-sanitize/`，ASan/UBSan 均无报错），
但 sanitizer 的 tick 数值不用于任何结论。

## 10. 归档、边界与不构成的主张

- 远端树：`/home/nss-marker/yhr/Cry/platform-m2kem-20261016-d75a4019/collector-v2-2e894561892a/`；
  同级归档 `collector-v2-2e894561892a.tar.gz`（41,221,930 B，含源、两棵构建树、全部日志、disasm、
  dudect 原始 CSV、本文件副本），SHA-256
  `30a732c66ab9674236b326c36eb464a716466d7dc339dbe77e37f31ef17f811e`
  （同目录 `collector-v2-2e894561892a.tar.gz.sha256`）。
  本文件的**权威副本**在仓库 `docs/evidence/m2-kem-20261016/COLLECTOR_CONTRACT.md`；
  归档内的同名副本是打包时的快照（差别仅在本行归档摘要与 `TREE_ARCHIVE.sha256`）。
- 清单：`ELF.sha256`（32 条，`b1b71b5a…`）、`EVIDENCE.sha256`（689 条，`e53b3800…`）、
  `SOURCE_TREE.sha256`（594 条，`c5368cd0…`）。
- 本地证据副本：`docs/evidence/m2-kem-20261016/collector-v2-2e894561892a/`
  （含 `artifacts/` 四个 ELF 原件、`disasm/`、两套资格目录与日志、dudect 日志；
  两个 12.9 MB 的 dudect 20 批原始 CSV 与 79 MB 的探索性 CSV 只留在远端树内）。
- 全部内容在 `/home/nss-marker/yhr/Cry` 物理边界内；未使用 sudo、未写 sysfs、
  未改 `vendor/` 与 M1 证据、未执行密钥恢复或 exploit、未 git add/commit/push。
- 本文件不主张：恒时性、无泄漏、统计显著或阴性结论、物理频率精度、M2 端到端已完成。
  它只证明"两个普通完整解封装 collector（及 online dudect 入口）与既有普通 measure 同机制、
  已通过功能与 CLI 资格、可被主控按 §7 复现执行"。
