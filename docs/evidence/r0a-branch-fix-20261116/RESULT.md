# T2.2 结果：R0a `poly_frommsg` 值屏障三候选与产物判定

- 日期：2026-11-16
- 对象：M2 已修臂 `vendor/kyber-kyberslash-fixed`（pq-crystals kyber `272125f`）的
  `ref/poly.c` `poly_frommsg()`，clang-18 `-Oz` 下被编成 `bt/jae` 秘密条件分支（M2-c）。
- 本地编译器：**clang 18.1.8**（证据机 18.1.3）；构建与判定细节见 `SANDBOX.md`。

## 1. 前置门结论

**通过。** 用本地 clang 18.1.8 按证据口径复刻未打补丁产物后，
`pqcrystals_kyber768_ref_poly_frommsg` 中存在 `bt %ecx,%r8d` + `jae` + `mov $0x681`
分支形态，判定 `secret_conditional_jumps=1`、退出 1；
与 18.1.3 证据的指令形态一致，仅地址/寄存器分配不同。

## 2. 主候选

**`docs/patches/m2-frommsg-barrier-asm.patch`**（SHA-256
`5e7fe0fce1132f0a13e0202e4bed73f0664231a686866836fb4510cd14838eed`）：

```c
      mask = -(int16_t)((msg[i] >> j)&1);
      /* 值屏障：让编译器无法把 mask 再识别成 0/-1 的位选择分支。 */
      __asm__("" : "+r"(mask));
      r->coeffs[8*i+j] = mask & ((KYBER_Q+1)/2);
```

- 修后反汇编：`bt → sbb → and $0x681`，无条件跳转以 bt/test 为判据；
  `secret_conditional_jumps=0`、`verdict=branchless`、退出 0。
- 选择理由：三候选全部达标，asm 屏障对源码侵入最小（单行 + 注释，不改控制流、不引入调用）。

## 3. 三候选对照

| 候选补丁 | SHA-256 | 判定（本地 clang 18.1.8 / objdump 2.45.1） |
|---|---|---|
| `m2-frommsg-barrier-asm.patch`（**主候选**） | `5e7fe0fce1132f0a13e0202e4bed73f0664231a686866836fb4510cd14838eed` | secret_conditional_jumps=0，branchless |
| `m2-frommsg-barrier-volatile.patch` | `ae0caa95420dfabee87f36143dbb2a8abe86017e9e04932ab0c9e574965bfc10` | secret_conditional_jumps=0，branchless |
| `m2-frommsg-ctselect.patch` | `c9715d39b20777dcc8a46c910daeee75c065c36694391f147292a30a31a67c05` | secret_conditional_jumps=0，branchless |

未修 baseline：secret_conditional_jumps=1（判定退出 1）。

## 4. 判定脚本

`tests/check_m2_frommsg_branchless.sh --elf <path>`：

- 黑名单式判据（写死）：`bt/test/testb` 紧邻驱动的条件跳转计为秘密条件跳转；
  `cmp $imm` 后的循环退出 `je/jne` 与无条件 `jmp` 不计。
- 输出 `bt_count / test_count / conditional_jumps / secret_conditional_jumps / verdict`，
  退出码 0（无秘密条件跳转）/ 1（存在或无法判定）/ 2（用法）。

## 5. 边界

- 本结论只针对本地 clang 18.1.8、`-Oz -g -fno-vectorize -fno-slp-vectorize` 产物；
  不外推到 clang 18.1.3 产物，也不把"无秘密条件跳转"扩大为恒时证明。
- T2.3 的 KAT 与等价验证是独立的后续门，见 `docs/evidence/r0a-branch-fix-20261116/`
  后续追加的 `kat/` 与 `equivalence/` 记录（同目录）。
- 不修改 vendor 原树；三份补丁在 T2.3 仅对已修臂工作副本临时应用，用后恢复。
