# T2.2 构建沙盒与产物判定记录

- 日期：2026-11-16
- 工作区：WSL Ubuntu-22.04.5 LTS，x86_64
- 编译器：`/home/ubuntu/miniconda3/envs/cry/bin/clang`，**clang 18.1.8**（证据机为 18.1.3，本任务第 0 步专门验证该差异）
- 反汇编：GNU objdump 2.45.1
- 构建口径：按 `docs/evidence/m2-kem-20261016/`（ENV.md / microbench COMMANDS.md / COLLECTOR_CONTRACT.md）
  记录的 CMake `RelWithDebInfo`（`-O2 -g -DNDEBUG`）与 M2 vendor 额外旗标
  `-Oz -g -fno-vectorize -fno-slp-vectorize -DKYBER_K=3 -Drandombytes=platform_m2_randombytes`，
  并沿用工程 C 标准 `-std=c11`（C_EXTENSIONS OFF）。
- 工作副本：`build/m2-branchfix-work/<variant>/ref/`（由 `vendor/kyber-kyberslash-fixed/ref`
  原样复制；不修改 vendor）。

## 1. 编译与链接命令（逐候选复刻）

```sh
clang -O2 -g -DNDEBUG -Oz -g -fno-vectorize -fno-slp-vectorize \
  -DKYBER_K=3 -Drandombytes=platform_m2_randombytes -std=c11 \
  -I<variant>/ref -c <variant>/ref/<source>.c -o objects-<variant>/<source>.o
# source ∈ kem indcpa poly polyvec ntt cbd reduce verify fips202 symmetric-shake
clang -O2 -g -DNDEBUG -std=c11 -I<variant>/ref -c driver.c -o objects-<variant>/driver.o
clang objects-<variant>/*.o -o <variant>-driver
objdump -d --no-show-raw-insn \
  --disassemble=pqcrystals_kyber768_ref_poly_frommsg \
  <variant>-driver > <variant>-poly_frommsg.asm
```

- 驱动 `driver.c` 只调用一次 `pqcrystals_kyber768_ref_keypair/enc/dec`，链接仅为产物判定，
  **不作计时**；`platform_m2_randombytes` 用 `/dev/urandom` 实现，仅为闭合链接。
- 构建脚本副本见 `build_variant.sh`，候选源码编辑见 `make_candidates.py`，补丁生成见
  `make_patches.sh`。

## 2. 前置门（第 0 步）：18.1.8 能否复现 bt/jae

- 未打补丁 baseline 产物判定：`bt_count=1`、`conditional_jumps=3`、
  **`secret_conditional_jumps=1`**、`verdict=secret_branch_present`、退出码 1
  （见 `judgements/baseline.txt`，反汇编 `disasm/baseline-poly_frommsg.asm`）。
- 关键序列：

```text
    2bb2:	bt     %ecx,%r8d
    2bb6:	jae    2bbd <pqcrystals_kyber768_ref_poly_frommsg+0x22>
    2bb8:	mov    $0x681,%edx
```

- 与 18.1.3 证据（`docs/evidence/r05-locate-20261016/remote-tree/m2-disasm/fixed-poly_frommsg.asm`）
  的 `bt → jae → mov $0x681` 形态一致；差异仅在地址与寄存器分配。
- **结论：前置门通过**，clang 18.1.8 能在本地复现 M2-c 的秘密条件分支，编译器小版本差异
  不构成阻断。

## 3. 三候选产物判定

| 候选 | 补丁做法 | bt_count | conditional_jumps | **secret_conditional_jumps** | verdict | exit |
|---|---|---:|---:|---:|---|---:|
| baseline（未修） | — | 1 | 3 | **1** | secret_branch_present | 1 |
| asm 值屏障 | `mask` 赋值后插入 `__asm__("" : "+r"(mask));` | 1 | 2 | **0** | branchless | 0 |
| volatile 指针往返 | 经 `int16_t volatile *` 读回掩码 | 1 | 2 | **0** | branchless | 0 |
| ctselect noinline | 抽 `mask_select_int16()` 并 `noinline` | 1 | 2 | **0** | branchless | 0 |

- 修后三份产物仍保留 `bt`，但 `bt` 只驱动 `sbb`（借位展开）或作为 `mask_select_int16()`
  的参数，**没有**任何条件跳转以 bt/test 为判据；剩余 2 个条件跳转都是
  `cmp $0x20` / `cmp $0x8` 立即数循环退出（按黑名单口径不计）。
- 判定脚本：`tests/check_m2_frommsg_branchless.sh --elf <path>`（退出 0/1，见 `judgements/`）。
- 三份候选均达标；按任务书"多个达标选侵入最小者"→ **主候选 = asm 值屏障**（一行插入 + 注释，
  不改控制流、不引入调用）。

## 4. 附件

| 文件 | 内容 |
|---|---|
| `disasm/{baseline,asm,volatile,ctselect}-poly_frommsg.asm` | 四份 objdump 片段 |
| `judgements/{baseline,asm,volatile,ctselect}.txt` | 判定输出与退出码 |
| `driver.c` / `build_variant.sh` / `make_candidates.py` / `make_patches.sh` | 复现材料 |
| `clang-version.txt` / `objdump-version.txt` | 工具版本 |
| `patches.sha256` | 三份候选补丁摘要 |
