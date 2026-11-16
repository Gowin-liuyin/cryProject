# T2.3 KAT 与等价验证记录（主候选修复臂）

- 日期：2026-11-16
- 方案：任务书 §4 T2.2 方案 B —— 对 `vendor/kyber-kyberslash-fixed` **临时**应用主候选
  `docs/patches/m2-frommsg-barrier-asm.patch`，重建平台树后跑既有 M2 用例与额外等价；
  用后恢复 vendor（过程与摘要见 `PATCH_RESTORE.md` 与 `restore/`）。
- 平台树：`build/cmake-platform`，编译器 **clang 18.1.8**
  （`/home/ubuntu/miniconda3/envs/cry/bin/clang`），`RelWithDebInfo`，
  `-DBASELINE_ENABLE_PLATFORM=ON`（`cmake/PlatformM2.cmake` 只在 Clang 下启用 M2 目标）。
  配置命令：

```sh
rm -rf build/cmake-platform
cmake -S . -B build/cmake-platform \
  -DCMAKE_BUILD_TYPE=RelWithDebInfo -DBUILD_TESTING=ON -DBASELINE_SANITIZERS=OFF \
  -DBASELINE_ENABLE_PLATFORM=ON \
  -DCMAKE_C_COMPILER=/home/ubuntu/miniconda3/envs/cry/bin/clang \
  -DCLANG_FORMAT_EXECUTABLE=/home/ubuntu/miniconda3/bin/clang-format
cmake --build build/cmake-platform --parallel 8 \
  --target platform_m2_unfixed_test platform_m2_fixed_test \
          platform_m2_unfixed_rng_failure platform_m2_fixed_rng_failure \
          platform_m2_unfixed_kat platform_m2_fixed_kat
```

## 1. 既有 M2 CTest：7/7 通过

```sh
ctest --test-dir build/cmake-platform -R platform_m2 -V --output-on-failure
```

| 用例 | 结果 |
|---|---|
| platform_m2_unfixed_functional / platform_m2_fixed_functional | Passed |
| platform_m2_unfixed_random_failure / platform_m2_fixed_random_failure | Passed |
| platform_m2_semantic_equivalence | Passed（两臂 160 个 ciphertext/decapsulation 用例 transcript 一致） |
| platform_m2_unfixed_public_kat / platform_m2_fixed_public_kat | Passed（各 **100/100** round3 KAT） |

- 完整 verbose 日志：`kat/ctest-m2.log`；直接 KAT 输出：`kat/fixed-kat.txt`、`kat/unfixed-kat.txt`。
- 修复臂 KAT 结论：`m2-kyber768-round3-fixed: 100 independent official round3 KAT
  keygen/encap/decap cases passed`（100/100）。

## 2. 额外等价：500 随机 + 500 逐字节篡改

驱动：`equivalence/equiv_driver.c`（构建脚本 `equivalence/build_equiv.sh`），
对未修/已修（已打主候选补丁）两臂各链接并运行一次：

- 确定性：固定公开测试种子 `20261016`、消息由固定公式生成、无 OS 随机源、不作计时。
- 500 个随机（伪随机固定公式消息）用例：`platform_m2_test_message` 构造 → 解封装，
  逐例校验共享密钥往返一致，并逐例输出共享密钥十六进制。
- 500 个逐字节篡改用例：对每例密文翻转一个不同字节（位置 = 用例序号），解封装必须返回
  `z || H(ct_tampered)` 的 SHAKE256 **隐式拒绝值**（与 `tests/test_platform_m2.c` 同口径），
  且不得等于原共享密钥。

结果：

```text
transcript 行数：两臂各 1001 行（1000 用例 + 1 SUMMARY）
transcript SHA-256：两臂同为 adc4113ae505935091250f55f1aaaa912e1a828ca63f2d778506b020117ea5f2
diff -u：全空（transcripts.diff 为 0 字节）
SUMMARY random_cases=500 random_roundtrips=500 tampered_cases=500 implicit_rejections=500
```

- 工件：`equivalence/{unfixed,fixed}-transcript.txt`、`transcripts.diff`（空）、
  `transcript.sha256`、驱动源码与构建脚本。
- 结论：主候选修复臂与未修臂在 1000 个确定性用例上**逐字节等价**；500 个篡改用例
  **500/500 全部隐式拒绝**，未出现接受或报错。

## 3. 恢复与复核

`PATCH_RESTORE.md`：改前树摘要 `8503134f…` → 打补丁后 `88facaeb…` → 恢复后
`8503134f…`（与改前一致）；恢复后重建通过，修复前的 `bt/jae` 重新出现
（`restore/restored-branch-judgement.txt`，`secret_conditional_jumps=1`），
KAT 100/100、M2 CTest 7/7。

## 4. 边界

- 本记录是**功能/等价门**，不是计时、恒时或"零泄露"证明；补丁只在临时工作树应用并已恢复。
- KAT 向量来源：仓库内 `tests/vectors/kyber768_round3/`（公开 round3 KAT, 100 例）。
- 额外等价的"随机"指固定公式伪随机消息（为跨臂逐字节比较），不是新的在线采集。
