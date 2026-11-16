# R24 Binsec 扩面执行计划（harness + cfg，2026-11-16）

- 任务号：T7.3（本阶段只做 harness/cfg/PLAN 与本地源码语法级检查；**执行归裸金属主控**）
- 对应 bundle：`docs/research/phase7-session-20261116/A_LINE_BUNDLE.md` 的 A-R24-01。
- 体例参照：`docs/evidence/r14-binsec-m5-20261021/`（model.cfg 格式、checkct TOML、
  identity/disasm/stdout/stderr 全套保留；未知/pending/超时/装载失败都保留，不凭退出码 0 写 secure）。

## 1. 新增文件与抽取来源

| 文件 | 内容 | 抽取来源 |
|---|---|---|
| `tools/platform_m4/binsec_harness_cmov.c` | 常数时间选择 `mlk_ct_cmov_zero` 路径（16 B 秘密/公开数组 + 秘密条件字节；入口 `m4_cmov_entry`、终点 `m4_cmov_halt`） | `vendor/mlkem-native/mlkem/src/verify.h` 的 `mlk_ct_sel_uint8()` / `mlk_ct_cmov_zero()`，去掉 `__contract__`/`MLK_INLINE`，逻辑逐字保留 |
| `tools/platform_m4/binsec_harness_cmov.cfg` | Binsec model：起始/终止符号、concrete stack pointer、秘密/公开 globals、`explore all` | r14 `m5-frommsg/model.cfg` 体例 |
| `tools/platform_m4/binsec_harness_kdf.c` | KDF absorb 速率边界循环（SHAKE256 rate=168 B，公开长度 200 B 跨一次边界；秘密只在吸收字节内容） | mlkem-native SHAKE-256 absorb 的按 rate 分块循环边界简化载体 |
| `tools/platform_m4/binsec_harness_kdf.cfg` | 同体例 model | 同上 |

**本地检查（已完成）**：两 harness 通过 `clang -fsyntax-only -ffreestanding -std=c11`
语法级检查（不要求 i386 链接，符合本阶段范围）；**未**链接、未执行 Binsec。

## 2. 裸金属构建与执行命令（模板）

```sh
ROOT=/home/nss-marker/yhr/Cry/r24-binsec-ext-20261116-<nonce>
BINSEC=<r14 同版本 Binsec 0.11.3 路径>/binsec
CLANG18=/usr/bin/clang-18

# 1) 构建 32 位 freestanding 载体（体例同 r14 PlatformM4 formal 目标；不依赖冻结树）
$CLANG18 -m32 -O1 -g -ffreestanding -fno-pie -fno-stack-protector -fno-builtin -nostdlib \
    -Wl,-e,m4_cmov_entry -Wl,-Ttext=0x1000 \
    tools/platform_m4/binsec_harness_cmov.c -o $ROOT/elf/m4_cmov_formal
$CLANG18 -m32 -O1 -g -ffreestanding -fno-pie -fno-stack-protector -fno-builtin -nostdlib \
    -Wl,-e,m4_kdf_entry -Wl,-Ttext=0x1000 \
    tools/platform_m4/binsec_harness_kdf.c -o $ROOT/elf/m4_kdf_formal

# 2) 身份与反汇编原件（先记摘要再分析）
sha256sum $ROOT/elf/m4_cmov_formal $ROOT/elf/m4_kdf_formal > $ROOT/elf/SHA256SUMS
objdump -d $ROOT/elf/m4_cmov_formal > $ROOT/cmov/disasm.txt
objdump -d $ROOT/elf/m4_kdf_formal  > $ROOT/kdf/disasm.txt

# 3) Binsec checkct（体例同 r14；M4 为 32 位 ELF，r14 先例用 -isa amd64 强制加载）
$BINSEC -isa amd64 -sse -checkct -smt-solver z3 \
    -sse-script tools/platform_m4/binsec_harness_cmov.cfg \
    -sse-depth 10000 -sse-timeout 120 -smt-timeout 5 \
    -checkct-features control-flow,memory-access \
    -checkct-stats-file $ROOT/cmov/checkct.toml \
    $ROOT/elf/m4_cmov_formal > $ROOT/cmov/stdout.txt 2> $ROOT/cmov/stderr.txt
$BINSEC -isa amd64 -sse -checkct -smt-solver z3 \
    -sse-script tools/platform_m4/binsec_harness_kdf.cfg \
    -sse-depth 10000 -sse-timeout 120 -smt-timeout 5 \
    -checkct-features control-flow,memory-access \
    -checkct-stats-file $ROOT/kdf/checkct.toml \
    $ROOT/elf/m4_kdf_formal > $ROOT/kdf/stdout.txt 2> $ROOT/kdf/stderr.txt
```

- 若 `-isa amd64` 装载 32 位 ELF 失败：按 r14 先例记录失败原文，不换机器、不伪造结果；
  可另试 Binsec 支持的同版本 `-isa x86-32`（若该版本无此 ISA 则记 `not_supported`）。
- 每目录保留 `identity.txt`（Binsec/Z3/ELF/CFG 摘要、命令原文）、`console.txt`、`status.txt`、
  `disasm.txt`、`checkct.toml`、`stdout.txt`、`stderr.txt`。

## 3. 判据（执行时逐条冻结核对）

1. **状态口径**：`checkct.toml` 的 control-flow / memory-access violation 计数与
   unknown/pending/cut/`timeout` 全部如实登记；出现 unknown/pending/超时/装载失败 →
   该 harness 记 `incomplete` 或 `failed`，**不得**写 secure/恒时。
2. **对照**：以 r14 已封存的 M4 `m4-vulnerable`/`m4-ct` 结果作正/负对照（不改原件），
   只在对比表中引用；新 harness 的结论不覆盖 r14。
3. **边界**：Binsec 是**有界**分析（固定深度/超时），只覆盖已探索路径；不证明任意输入、
   不证明物理恒时、不证明缓存/分支预测侧信道。
4. **失败处理**：不重试择优；同一配置的失败尝试保留在 `failed/` 并记录原因。

## 4. 产物与落盘位置

- 裸金属：`Cry/r24-binsec-ext-20261116-<nonce>/` 新目录（elf/、cmov/、kdf/、failed/、logs/）；
  所有文件在 Cry 内，临时目录 `TMPDIR=<root>/tmp`。
- 拉回：`docs/evidence/r24-binsec-ext-20261116/` 新子目录（不改既有证据）；摘要与原字节
  逐项核对后入档。
- 本阶段不执行任何 Binsec 运行；本 PLAN 与 harness/cfg 只作执行准备。
