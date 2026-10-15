# r03 格式破损输入对照 —— 工具与构建资格（族外对照采集件）

- 日期：2026-10-16（Asia/Shanghai）。分支 `main`，基线 `c849c0f`。
- 本轮只做**工具与构建资格**；**未**运行任何锁频采数（9 条控制器命令交给主控串行执行）。
- 远端新根（唯一写入位置）：`/home/nss-marker/yhr/Cry/r03-malformed-20261016-29ea2774da23/`
- 冻结树只读、未改动：`liboqs010-historical-20261015-86131c2/`（M1）、`platform-m5-20261016-30efdf66eb26/`（M5）。

## 1. 三臂采集 ELF（绝对路径 + sha256 + 链接对象）

| 臂 | 绝对路径 | sha256（实读） |
|---|---|---|
| M1 未修 | `<Cry>/r03-malformed-20261016-29ea2774da23/build/m1unfixed/r03_malformed_measure` | `a3c94bc0048fd32b6e66a23a4113d3b80a363ea00c53d566fdc83c8b60586998` |
| M1 已修 | `<Cry>/r03-malformed-20261016-29ea2774da23/build/m1fixed/r03_malformed_measure` | `a93c2f60adaecc6458386594e028e2525c429d5d495d9f13a4f040fd742fecc8` |
| M5 参考 | `<Cry>/r03-malformed-20261016-29ea2774da23/build/m5ref/r03_malformed_measure` | `772cf099d240754d5781f231b89464543d5ccb6f98901c8385c241c306ec2934` |

`<Cry>` = `/home/nss-marker/yhr/Cry`。三个 ELF 都是 x86-64 PIE、动态链接（仅 `libc.so.6`）、带调试信息未 strip。

共用 C 源：`src/r03_malformed_measure.c`，sha256 `0b442b995fd263ddc180fc9ebaaeeada9a695a4fe56ab4676a6cd82d437134bd`
（本目录同名文件与远端逐字节相同）。源内**不含任何后端条件编译**：只用两棵树共同的
`include/mlkem.h` 与 `include/inputs.h`；两个 derand 封装符号用 `__attribute__((weak))` 声明，
在链接期按实际链接的静态库解析（`--describe` 会打印哪一个 linked / 哪一个 absent）。

链接到哪个实现（`nm` 原始证据见 `remote/logs/nm-implementation-evidence.txt`）：

| 臂 | 链接对象 | 关键符号（nm） | 实现构建参数（冻结树实读） |
|---|---|---|---|
| M1 未修 | `build/historical-clangover/historical/libmlkem.a` + `build/historical-clangover/liboqs010-install/lib/liboqs.a` | `OQS_KEM_ml_kem_768_ipd_decaps`, `pqcrystals_ml_kem_768_ipd_ref_dec`, `pqcrystals_ml_kem_768_ipd_ref_poly_frommsg` | clang、`RelWithDebInfo`、`-Os -fno-vectorize -g -DNDEBUG`、`OQS_DIST_BUILD=OFF`、`OQS_OPT_TARGET=generic` |
| M1 已修 | `build/historical-fixed-982c762/historical/libmlkem.a` + 该目录 `liboqs010-install/lib/liboqs.a` | 同上（`poly_frommsg` 地址不同，代码已换 cmov 路径） | 同上；源码另加官方 `982c762`（`poly_frommsg` 改用 `cmov_int16`） |
| M5 参考 | `build-v2-ordinary/reference/libmlkem.a`（`kernel.c.o` + `mlkem.c.o` + `random.c.o` + `inputs.c.o`） | `baseline_native_dec`, `baseline_native_enc_derand`, `baseline_native_poly_frommsg` | clang-18、`RelWithDebInfo`、`-O2 -g -DNDEBUG`、portable reference（无人工补丁变体） |

### 构建命令（可复跑，`remote/scripts/r03_build_arms.sh` 逐字）

工具自身编译选项三臂完全一致（避免臂间编译混淆）：

```
-std=c11 -O2 -g -DNDEBUG -Wall -Wextra -Wpedantic -Wshadow -Wconversion -Wstrict-prototypes -Werror
```

编译器：`/usr/bin/clang-18` 与 `/usr/bin/clang` 都是 Ubuntu clang 18.1.3 (1ubuntu1)、x86_64。
逐字溯源（编译器版本、库摘要、复跑命令、产物摘要、头文件摘要）见 `remote/logs/build-arms.log             三臂构建脚本的原样输出（构建静默、退出 0 时为空，实测即空）
remote/logs/build-provenance.txt`；
链接的既有静态库摘要：

```
54e7c71d805f4081529d59da54203c3861e649f200cb40aa44052a7476ab5d26  <M1>/build/historical-clangover/historical/libmlkem.a
2f130502b8c1e53b15406ec2f06952528a49fc17abe7577a7500c5722338caa6  <M1>/build/historical-clangover/liboqs010-install/lib/liboqs.a
486dccc29465c6cb65d2e38aaa78bee423c5c580b3d611e872537c509fc5ba5c  <M1>/build/historical-fixed-982c762/historical/libmlkem.a
fcd7c56f5751cfaab46c25a281c4c4e44582cb1f7ea3fb14223fc60b61dd4f76  <M1>/build/historical-fixed-982c762/liboqs010-install/lib/liboqs.a
ed9a658183562a88a96a631602cdcdd137d4bb405bd224fc2ac8cf682514416a  <M5>/build-v2-ordinary/reference/libmlkem.a
```

最后一项与 `m5-completion-PLAN.md` §1.3 记录的参考静态库摘要一致（独立复核）。
两棵树的接口头文件**逐字节相同**，这正是"三臂共用一个 C 源"成立的客观依据：

```
d2370cd5d17703f64ddd8a1a315536804709998c39ea61178e9949b0abc5c4e5  <M1>/include/mlkem.h  ==  <M5>/source-v2/include/mlkem.h
83056f6639dd8e43adc77c647a780a560ff6b21b53bb52ad8742a3a357772f1c  <M1>/include/inputs.h  ==  <M5>/source-v2/include/inputs.h
```

M5 臂（clang-18）：

```
/usr/bin/clang-18 <上述严格选项> \
  -DR03_ARM_NAME="m5-native-reference" \
  -DR03_LINKED_IMPLEMENTATION="mlkem-native-b3ba7b3-portable-reference" \
  -DR03_BUILD_FLAGS="..." -I <M5>/source-v2/include \
  <ROOT>/src/r03_malformed_measure.c -o <ROOT>/build/m5ref/r03_malformed_measure \
  <M5>/build-v2-ordinary/reference/libmlkem.a
```

M1 两臂（`/usr/bin/clang`，各自 build 目录）：

```
/usr/bin/clang <上述严格选项> -DR03_ARM_NAME="<臂名>" -DR03_LINKED_IMPLEMENTATION="<实现名>" \
  -DR03_BUILD_FLAGS="..." -I <M1>/include \
  <ROOT>/src/r03_malformed_measure.c -o <ROOT>/build/<m1unfixed|m1fixed>/r03_malformed_measure \
  <M1>/build/<historical-clangover|historical-fixed-982c762>/historical/libmlkem.a \
  <M1>/build/<historical-clangover|historical-fixed-982c762>/liboqs010-install/lib/liboqs.a
```

说明：工具自身的 TU 不需要 `-DMLK_CONFIG_FILE="baseline_config.h"`（不 include `mlkem_native.h`）；
实现的编译选项来自冻结树既有产物，未重编实现。普通构建（无 sanitizer）。

## 2. 采集语义（与 PLAN 逐条对应）

| 类名 | 构造 | 输入字节 | 预期路径 | 实测状态 |
|---|---|---|---|---|
| `valid` | `generate_test_ciphertext(VALID, seed, 0, ek)`，确定性封装 | 1088 | `full_decapsulation` | `0`（成功，解出真实共享密钥） |
| `malformed` | 同一份密文，前 960 字节全 `0xFF`、后 128 字节全 `0x00` | 1088 | `full_decapsulation` + 隐式拒绝 | `0`，且共享密钥与 `valid` 不同 |
| `truncated` | 同一份密文只喂前 1087 字节 | 1087 | `length_rejection`（封装层长度检查） | `-100`（`MLKEM_ERROR_ARGUMENT`），输出缓冲区哨兵 `0xA5` 保持未写 |

- 每类内部是**同一份输入的重复**；meta 写 `identical_input_per_class=yes` 与三类 `sha3_256`/`sha256`。
- 计时窗口只包一次 `mlkem_decapsulate`；两侧 `atomic_signal_fence(seq_cst)`；预热 100 次在窗口外；
  结果消费、分配、I/O 全在窗口外；CSV 表头与既有 measure 长表逐字相同，`time_unit=ns`。
- 行序只由 seed 与每类样本数决定（先在"三类齐全"的规范索引空间做降序 Fisher–Yates，再按出现的类压缩）：
  `--class` 的书写顺序无关，子集运行是全集运行的逐行子类序列；同 seed 逐行可重放。
- `--raw`/`--meta` 一律 `wx` 新建；失败时只删除本程序自己建的文件，预先存在的路径原字节保留。
- 不 fork、不 daemonize、不 setsid、不写亲和性、不写频率、不产生临时文件。
- 密钥：两棵树都有确定性 fixture 生成器，**不需要外部密钥文件**；`--public-key/--secret-key`
  仅作可选覆盖（给了就必须一对，且大小 1184/2400 字节，否则拒绝）。

## 3. 资格结果（全部实跑，原始日志在 `remote/logs/`）

| 检查 | 结果 | 原始日志 |
|---|---|---|
| 三臂 `--describe` | 退出 0；`digest_selfcheck=passed`；`valid_roundtrip_check=passed` | `describe-m1unfixed.txt` / `describe-m1fixed.txt` / `describe-m5ref.txt` |
| CLI 拒绝用例（25 条：缺参/越界/已存在路径/非法类名/混合模式/半对密钥/同路径/不存在目录） | 三臂各 25/25 通过，退出码非 0、零残留文件、预存文件原字节保留 | `cli-rejection-*.txt` |
| 功能一致性（valid 输入与既有 measure 同类输入逐字节相同） | 各树既有 `baseline generate-test valid 31337` 的产物 sha256/sha3_256 与工具 `class_valid_*` 完全一致：M1 两臂 `sha256=dbf3e11164d98c9767172ff37527a3f0615562c091ae89ad7bfedd478aafb240`；M5 `sha256=818669cf53c2664f4904a053bf534e5e2e738392d388c24116ec1b30cfaa8c3c`；`remote/qual/input-identity/*.bin` 为原件 | `elf-sha256.txt`、`describe-*.txt` |
| 功能一致性（同一密文同一密钥 → 同一共享密钥） | `--describe` 与实采轮内都做 derand 封装 ↔ 解封装逐字节比对：三臂 `valid_roundtrip_check=passed` | `describe-*.txt`、`functional-*.txt` |
| 各树既有 `baseline decapsulate-test 31337 <同一密文>` | 三臂均退出 0（`decapsulation completed`）；`baseline selftest` 亦通过 | 见 §7 日志摘录 |
| 功能微跑（100/类，seed 31337） | 三臂 `run_status=complete`，CSV 300 行 + 表头，类内零耗时行 0，`truncated` 约 20 ns vs 完整解封装约 44–47 µs | `qual/functional/*/r03-micro-31337.{csv,meta}` |
| 反汇编（机制确认） | 未修臂 `bt/jae` 分支；已修臂 `setb` + `call cmov_int16`；M5 `poly_frommsg` 纯掩码无秘密分支 | `disasm-*.txt` |
| 标准长表解析（`platform_stats <csv> measure <class0> <class1> <outdir>`） | 微跑 CSV 直接被解析：对照 A（valid vs malformed）与对照 B（valid vs truncated）都退出 0，`excluded_other_category_count=100` 说明第三类被正确排除；产出 `ci_welch.json` | `platform-stats-parse-check.txt`、`qual/stats-battery/*/ci_welch.json` |
| 产物机制自证（未定义符号扫描） | 三臂 ELF 都**没有** `fork/vfork/clone/daemon/setsid/sched_setaffinity/pthread_create/mkstemp/tmpfile/tmpnam/system/popen`；两棵树的另一个 derand 符号在各自臂里保持**弱未定义**（运行期 NULL） | `nm-no-forbidden-syscalls.txt` |
| 边界 | `/tmp` 前后无新增条目；新根内 0 个符号链接；`tmp/`、`cache/` 空；冻结树内 marker 比对无新文件 | `tmp-listing-before.txt`、`tmp-listing-after.txt`、`boundary-recheck.txt`、`symlink-check.txt` |

反汇编原始片段（命令：`objdump -d --disassemble=<symbol> <ELF>`）：

```
# M1 未修 a3c94bc0…：数据相关条件分支
    8ee6: 41 0f a3 c8   bt   %ecx,%r8d
    8eea: 73 05         jae  8ef1 <pqcrystals_ml_kem_768_ipd_ref_poly_frommsg+0x1a>
    8eec: ba 81 06 00 00 mov $0x681,%edx

# M1 已修 a93c2f60…：无分支取值
    8f15: 44 0f a3 e8   bt    %r13d,%eax
    8f19: 0f 92 c2      setb  %dl
    8f24: e8 70 ed ff ff call 7c99 <pqcrystals_ml_kem_768_ipd_ref_cmov_int16>

# M5 参考 772cf099…：纯掩码（and/neg/shr/and），循环内无数据相关跳转
    6e30: b1 01         mov  $0x1,%cl
    6e32: 22 0c 06      and  (%rsi,%rax,1),%cl
    6e38: f7 d9         neg  %ecx
    6e3a: c1 e9 10      shr  $0x10,%ecx
    6e3d: 81 e1 81 06 00 00 and $0x681,%ecx
```

## 4. 主控执行的 9 条命令

逐字命令见 `r03_controller_commands.sh`（含 `mkdir -p` 前置与族外 dudect 命令）。
摘要：run-name `r03-<m1unfixed|m1fixed|m5ref>-s<1|2|3>`；s1 seed 31337 / CPU2，s2 seed 424242 / CPU2，
s3 seed 7 / CPU6；`--timeout-seconds 600`；`--plan` 用
`<COLLECT>/plans/m5-completion-PLAN.md`（sha256 `15738beea1e8d22ae58f83ed741636c2bcf7d9f49e16f0c5c0f2f8590c323e44`，按要求）；
输出落在 `<COLLECT>/R03/<run-name>/`；每次 `--class valid,malformed,truncated --samples 10000 --warmup 100`。
有效判据同主合同：`reason=worker_finished` + `worker_exit_code=0` + `worker_drained=true` + `restore_match=yes`。

## 5. 族外 dudect 状态

| 臂 | 入口 | sha256 | 命令 |
|---|---|---|---|
| M5 | 冻结树既有 `<M5>/build-v2-ordinary/platform_m5_dudect` | `3be8772155774ad7cbcdc3ca1633d282f6209bfc5a6964eb60d7d705f902f77d` | `platform_m5_dudect --collect --seed N --raw NEW.csv`（21 批，每批 10000 次） |
| M1 未修 | 新根内编译 `<ROOT>/build/m1unfixed/r03_historical_dudect` | `3dfbab6e8b0da0a895d7d8eeae40f3d90aba8d21c4870a0b49802ccb2c3b96f2` | 无参数（种子默认 31337，可 `HISTORICAL_DUDECT_SEED=<n>` 覆盖） |
| M1 已修 | 新根内编译 `<ROOT>/build/m1fixed/r03_historical_dudect` | `525c1766483c14cc2d9ddb26d00a59afa3c50fe52f73fa32629e54940de657bf` | 同上 |

M1 入口来源：仓库既有 `tools/historical_dudect.c`（sha256 `34f4c7ae321aa88166f65ab2225d0d488ba65e06222904b9494d948e7d4ebb2b`）
+ 钉版上游 `third_party/dudect/src/dudect.h`（sha256 `3fb3b2bd7f9e17ae34b7c92518c1311c67342c56facc80da925d85f121b649da`，与冻结树
`platform-m5-…/source-v2/third_party/dudect/src/dudect.h` 同摘要）；在**新根内**编译，冻结树只读。
编译选项：`-std=c11 -O2 -g -DNDEBUG -I <M1>/include -isystem <ROOT>/src`，链接各自 `historical/libmlkem.a` + `liboqs.a -lm`。

**冒烟运行（不是测量、无亲和性、无锁频，只证明入口可跑）**：`remote/qual/dudect-smoke/*.txt`，21 批跑满；
未修臂末批 `max|t|=+10.31`（越过上游 `|t|>10` 阈值，`state=0`），已修臂末批 `max|t|=+2.07`（`state=1`）。
该结果不得当作族外结论，正式 dudect 由主控在控制器锁频窗口内按 §4 的命令执行。

## 6. 明确不做的与边界

- 未做任何锁频采数、未写频率/亲和性/隔离、未 sudo、未改动两棵冻结树。
- `truncated` 走封装层长度检查、耗时显著低于完整解封装，**是接口语义，不是泄漏**；
  它必须与 `malformed`（完整隐式拒绝）分开报告。
- 本目录只证明"工具与构建资格"；"未检出"不构成恒时证明，也不改变 M1/M5 既有统计结论。
- 动态/sanitizer 资格本轮未做（另列可选）。

## 7. 本机证据文件索引

```
r03_malformed_measure.c            共用 C 源（远端逐字节相同）
r03_build_arms.sh                  三臂构建脚本（远端逐字节相同）
r03_cli_rejection_check.sh         CLI 拒绝资格脚本（远端逐字节相同）
r03_controller_commands.sh         9 条控制器命令 + 族外 dudect 命令
remote/logs/                       describe / CLI 拒绝 / 反汇编 / nm / dudect / 边界 原始日志
remote/qual/functional/<arm>/      功能微跑 CSV + meta（100/类，seed 31337）
remote/qual/input-identity/*.bin   各树既有 baseline 生成的 valid 密文原件（比对用）
remote/qual/dudect-smoke/*.txt     M1 dudect 等价入口冒烟日志（非测量）
remote/qual/rejection/*/preexisting/ CLI 拒绝用例的预存文件（验证未被改写/删除）
remote/qual/stats-battery/pair-{A,B,C}/  platform_stats 实读（measure 长表解析资格，100/类 微跑，非正式统计）
remote/logs/platform-stats-parse-check.txt 上述解析资格原始输出
remote/qual/measure-crosscheck/           同树既有 measure 以同 seed 最小跑（1/类）的 CSV+meta，用于核对长表逐字一致
remote/logs/nm-no-forbidden-syscalls.txt  未定义符号禁止项扫描（无 fork/daemon/setsid/亲和/临时文件）
remote/logs/boundary-recheck.txt          marker 边界复检
```

补充说明（避免误读 `nm` 输出）：M1 两臂未定义符号里出现 `pthread_once`/`getentropy`/`explicit_bzero` 等，
来自 liboqs 静态库自身的运行时初始化，不是本工具的分支或进程操作；本工具自身只用
`clock_gettime/clock_getres/fopen/fprintf/malloc/...` 一类调用，且窗口内只有一次 `mlkem_decapsulate`。

解析资格只证明**格式可被既有统计工具消费**；`power-A/B/C` 的 Δ/p 是 100/类 微跑的描述性数字，
**不得**当正式结果引用。`valid vs truncated` 的 p 因 double 下溢打印为 0，按主合同口径原样保留、不解释为精确零。

`baseline` 一致性实读（原始输出）：

```
$ <M1>/build/historical-clangover/historical/baseline decapsulate-test 31337 m1unfixed-valid-31337.bin
historical: decapsulation completed                      # exit 0
$ <M1>/build/historical-fixed-982c762/historical/baseline decapsulate-test 31337 m1fixed-valid-31337.bin
historical: decapsulation completed                      # exit 0
$ <M5>/build-v2-ordinary/reference/baseline decapsulate-test 31337 m5ref-valid-31337.bin
reference: decapsulation completed                       # exit 0
$ <M1>/build/historical-clangover/historical/baseline version
historical ML-KEM-768-ipd liboqs-0.10.0
$ <M5>/build-v2-ordinary/reference/baseline version
reference ML-KEM-768 FIPS203
```
