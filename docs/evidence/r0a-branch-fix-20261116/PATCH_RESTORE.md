# T2.3 vendor 临时修改与恢复记录

- 对象：`vendor/kyber-kyberslash-fixed`（pq-crystals kyber `272125f`，M2 已修臂；
  `tools/fetch_all_vendors.sh` 钉死树摘要 `8503134f538461c03820e13a0936024a46fff5d85ba334fb0a365f6378a49976`）。
- 修改方式：**只应用主候选补丁**，不手工编辑 vendor 内容。

## 1. 改前

- 树摘要（取件脚本幂等校验输出，2026-11-16 打补丁前复跑确认）：
  `8503134f538461c03820e13a0936024a46fff5d85ba334fb0a365f6378a49976`
  见 `pre-patch-tree-sha256.txt`。
- 已修臂在 clang-18 `-Oz` 下保留 M2-c 老写法（`bt/jae`），T2.2 前置门已固化。

## 2. 打补丁

```sh
git apply --directory=vendor/kyber-kyberslash-fixed \
    docs/patches/m2-frommsg-barrier-asm.patch
```

| 项 | 值 | 文件 |
|---|---|---|
| 主候选补丁 SHA-256 | `5e7fe0fce1132f0a13e0202e4bed73f0664231a686866836fb4510cd14838eed` | `main-candidate-patch-sha256.txt` |
| 改后 `ref/poly.c` SHA-256 | `e5940e851e2d4a8c906855e4f7baaec65112eba4bd6c92de79b1f08cd664273d` | `patched-ref-poly-sha256.txt` |
| 改后树摘要 | `88facaeb37065093116348a79e22e2ef7a0d458af206cfae0fb50cc4360f365e` | `patched-tree-sha256.txt` |

改后树摘要不同于改前，是"确实临时修改了工作副本"的证据。

## 3. 恢复

```sh
# 取件脚本在"只有一臂就绪"时拒绝继续；先把未修臂临时移出 vendor（不删除内容）：
mv vendor/kyber-kyberslash-unfixed build/kyber-unfixed-preserve-20261116
rm -rf vendor/kyber-kyberslash-fixed
sh tools/fetch_all_vendors.sh          # 重新取两臂并逐项校验
rm -rf build/kyber-unfixed-preserve-20261116   # 核对摘要与重取结果一致后删除副本
```

- 取件完整输出：`restore/fetch-restore.log`；四棵树摘要全部与钉版一致。
- 被临时移出的未修臂副本树摘要 `1898b727…` 与重新取件后的未修臂摘要一致后才删除。
- 恢复后树摘要：`8503134f538461c03820e13a0936024a46fff5d85ba334fb0a365f6378a49976`
  （与改前一致，`restore/post-restore-tree-sha256.txt`）。

## 4. 恢复后复核

- 重建 `build/cmake-platform --target platform_m2_fixed_test`：通过
  （`restore/rebuild-after-restore.log`）。
- 反汇编复核：恢复后的 fixed ELF 重新出现上游 `bt/jae` 秘密分支
  （`restore/restored-branch-judgement.txt`：`secret_conditional_jumps=1`、退出 1），
  说明 vendor 已回到上游原状，而不是残留打过补丁的产物。
- 恢复后 KAT：`fixed: 100/100`（`restore/fixed-kat-after-restore.txt`）；
  M2 CTest 7/7（`restore/m2-ctest-after-restore.log`）。

## 5. 说明

- 本记录对应任务书 §2 例外条款：T2.3 方案 B 允许临时修改该 vendor 树，记录改前摘要、
  用后恢复并核对一致；恢复路径按提示词命令展开（为了让取件脚本的单臂保护通过，
  先把另一臂临时移出 vendor 再整体取件）。
- 全程未手工编辑 vendor 文件；未删除其它 vendor 树；未在 vendor 内留下任何改动。
