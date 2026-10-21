# 一键取件与干净 clone 复现验证（2026-10-20）

对象：`tools/fetch_all_vendors.sh`（新增）、`docs/patches/liboqs-982c762.patch`（新增）、
`scripts/reproduce_all.sh`（新增 `--fetch` 与 vendor 预检）、`.gitignore`（新增补丁副本目录）。

**本页只登记软件行为与校验结果，不涉及任何硬件采数，也不改变 M1–M5 的既有判定。**

## 1. 背景与要解决的问题

`vendor/liboqs-0.10.0/`、`vendor/liboqs-0.10.0-982c762/`、`vendor/kyber-kyberslash-unfixed/`、
`vendor/kyber-kyberslash-fixed/` 都在 `.gitignore` 内（上游许可证与体积原因），
干净 clone 默认没有这四棵树。后果是：

- M1（liboqs 0.10.0 历史阳性对照，GHSA-f2v9-5498-2vpp）**未修臂**与
  **官方修复 982c762 已修臂**都没有源码可编；
- M2（pq-crystals KyberSlash）**未修臂 a621b8d** 与**已修臂 272125f**都没有源码可编。

2026-10-16 的干净 clone 复现记录（[r12-innovation-20261016/REPRODUCE-QUICK-LOG.md](../r12-innovation-20261016/REPRODUCE-QUICK-LOG.md)）
就是在这个状态下做的：M2 臂未构建、脚本打印跳过原因，CTest 194/194 通过。
本轮把「缺件」从「需要人工分步处理」变成「一条命令取齐并自证」。

## 2. 取件内容与两层校验

| 步骤 | 产物 | 上游标识 | 上游归档摘要 | 树摘要 |
|---|---|---|---|---|
| 1 | `vendor/liboqs-0.10.0/` | liboqs tag `0.10.0`，commit `36be57445d8ca53f7095160fde548efe82ace09d` | `2b7b4436be9825dd0adaf000ee4f322f06551e638a8a9c8d54eda48ed40e40a9` | `d3322945483983b45c60406127790107865706523c4e83a15e27c7211c776cdd` |
| 2 | `vendor/liboqs-0.10.0-982c762/` | 同一棵树 + 官方补丁 `982c762c242ef549c914891b47bf6e0ed6321f91` | 补丁 `d1879ac6aa52cfbd8fbe91a282e2f2696115fdec807d7f2f79543181edbe6376` | `e27e55e5bdb59e89bfe26c8f82ddf8b162346537333c8b18b9e61c9d91093f14` |
| 3 | `vendor/kyber-kyberslash-unfixed/` | pq-crystals/kyber `a621b8dde405cc507cbcfc5f794570a4f98d69cc` | `509548a1741473cab69fe403eb685282419bc2a42554d358f16b9e991c88ac08` | `1898b727ed24e014cb731442b9a83cd4d82fc49e06899f9ab2d9364ecd60397f` |
| 4 | `vendor/kyber-kyberslash-fixed/` | pq-crystals/kyber `272125f6acc8e8b6850fd68ceb901a660ff48196` | `e3d020a78c59fc7248f64a4ca774db5ca8c6bc537e8c682a9fd0049a09180803` | `8503134f538461c03820e13a0936024a46fff5d85ba334fb0a365f6378a49976` |

- **上游归档摘要**：liboqs 的 tag tar 由 [tools/fetch_liboqs_0.10.0.sh](../../../../tools/fetch_liboqs_0.10.0.sh) 内
  校验；两个 kyber 的 `git archive` tar 由封存的
  [version-audit/fetch_vendor.sh](../m2-kyberslash-20261016/version-audit/fetch_vendor.sh) 内校验。
- **树摘要**：树内每个普通文件与符号链接各算一次 SHA-256，按相对路径（`./` 开头、
  `LC_ALL=C` 排序）列出后再整体算一次 SHA-256。它验证的是**落地结果**而不是下载声明，
  因此「已存在的树」与「刚取到的树」用同一把尺子。
- **摘要不符即拒绝覆盖**：既有目录与期望摘要不符时脚本报错退出，不删、不改既有内容。

## 3. 取件来源的自证（不靠下载内容自证）

2026-10-20 在本机独立复算了一遍上游，不依赖脚本自身：

| 复算项 | 命令 | 结果 |
|---|---|---|
| liboqs tag tar | `curl -fsSL https://github.com/open-quantum-safe/liboqs/archive/refs/tags/0.10.0.tar.gz` | SHA-256 与第 2 节登记值逐字一致；解包后与本地 `vendor/liboqs-0.10.0/` 递归逐文件相同（`diff -rq` 无输出） |
| kyber 两臂 tar | `git clone --mirror https://github.com/pq-crystals/kyber.git`，再 `git archive --format=tar <commit>` | 两个 tar 的 SHA-256 与登记值逐字一致；解包后与本地两臂目录递归逐文件相同（`diff -rq` 无输出） |
| 官方补丁 | 与 WSL 复现包内留存的 `out/env/liboqs-982c762.patch` 比对 | SHA-256 同为 `d1879ac6…e6376`；本仓库 `docs/patches/liboqs-982c762.patch` 为其逐字节副本 |

官方补丁的来源是上游 `https://github.com/open-quantum-safe/liboqs/commit/982c762c242ef549c914891b47bf6e0ed6321f91.patch`。
GitHub 生成的 `.patch` 头部可能随时间变化，**因此本仓库保存副本并按副本摘要强校验**，
不再依赖运行时的 GitHub `.patch`。

## 4. 已修臂的生成方式与两个坑

已修臂 `vendor/liboqs-0.10.0-982c762/` = `vendor/liboqs-0.10.0/` 的**副本** + 官方补丁。
上游未修树本身不动（`vendor/liboqs-0.10.0/` 保持原样），补丁只打在副本上。

1. **不能用 `git apply`**：补丁路径是 `src/kem/ml_kem/...`，而 `vendor/` 在本仓库工作树内；
   `git apply` 在仓库子目录里运行时会「把子目录之外的路径当作仓库外而整条忽略」，
   命令却返回 0——脚本据此改用 `patch -p1 -d <目录> -i <补丁绝对路径>`，
   并在打完后检查没有残留 `.orig`/`.rej`。
2. **补丁文件必须给绝对路径**：`patch -d <目录>` 会先切目录，相对路径会找不到文件。

补丁落地后脚本另查三处效果标记（`poly.c` 的掩码选择调用、`verify.c` 的 `cmov_int16`
实现、`verify.h` 的声明），三处齐备才算这一臂取件成功——不靠「patch 返回 0」判定。

## 5. 两条命令的干净 clone 复现

```sh
sh tools/fetch_all_vendors.sh          # 第 1 条：取件 + 两层 SHA-256 校验
sh scripts/reproduce_all.sh quick      # 第 2 条：配置 + 构建 + CTest + 小样本统计演练
```

`quick` 档新增的 vendor 预检逐项打印 `[就位]` / `[缺件]`，缺件时直接给出上面两条命令；
`--fetch` 可把两步合成一步（`sh scripts/reproduce_all.sh quick --fetch`）。

**本机实测（macOS 25.6.0 / Apple Silicon arm64 / Apple clang）**：

| 场景 | 命令 | 结果 |
|---|---|---|
| 四棵 vendor 树全部移走后再取件 | `sh tools/fetch_all_vendors.sh` | 退出码 0；重新下载 liboqs tar、重新 `git clone --mirror` kyber、重新复制并打补丁；四棵树的树摘要与第 2 节登记值逐字一致 |
| 取件后跑全套 quick | `sh scripts/reproduce_all.sh quick --samples 200 --runs 1` | 退出码 0；CTest：platform **88/88**、ordinary **57/57**、sanitize **57/57**、historical-fixed **61/61**，合计 **263 项通过、0 失败**；统计演练的 M1/M2/M3/M4/M5 五个家族各跑通一次 |
| 缺件时的行为 | 移走四棵 vendor 树后跑 `sh scripts/reproduce_all.sh quick --skip-stats --configs ordinary,historical-fixed` | 退出码 0；预检逐项打印 `[缺件]` 并给出取件命令；`historical-fixed` 配置以「本配置未构建」跳过，不伪造结果 |
| `--fetch` 一步完成 | `sh scripts/reproduce_all.sh quick --fetch --skip-stats --configs platform,historical-fixed` | 退出码 0；预检先报 4 处缺件，取件后复核「四棵 vendor 树齐备」，随后 platform 88/88、historical-fixed 61/61 |
| **真干净 clone 走两条命令** | `git clone <本仓库> /tmp/clean-clone-test`（克隆后 `vendor/` 只有 PIN 文件与 mlkem-native），再跑 `sh tools/fetch_all_vendors.sh` → `sh scripts/reproduce_all.sh quick` | 取件退出码 0；quick 退出码 0，CTest platform **88/88**、ordinary **57/57**、sanitize **57/57**、historical-fixed **61/61**（合计 263 项通过、0 失败）；带统计演练的一轮里 **M1 未修/已修、M2 未修/已修四个臂都被采集并进入 Holm 演练**（M1 2 个成员、M2 2 个成员） |

**边界**：这一组数字是**软件流程验证**（配置、构建、CTest、演练编排、摘要校验），
跑在 macOS/ARM 上、每类 200 样本、每臂 1 次运行，**不是任何模块的正式统计结论**，
也**不是** x86_64 Linux 实测。锁频采集与正式统计仍按四份冻结 PLAN 在裸金属上执行，
其结果见 [platform-collection-20261016/README.md](../platform-collection-20261016/README.md)。

## 6. 与正式统计的关系

- 本轮**没有**新增硬件采数，**没有**改动任何既有 CSV、统计家族或判定；
- `quick` 档演练的成员仍属族外流程演练，不进 Holm 家族；
- M1 的正式结论仍以 [liboqs010-locked-20261015](../liboqs010-locked-20261015/README.md) 与
  [r02-r04-close-20261016/RESULT.md](../r02-r04-close-20261016/RESULT.md) 的锁频采集为准；
  M2 的正式结论仍以 [m2-kem-20261016/RESULT.md](../m2-kem-20261016/RESULT.md) 为准。

## 7. 可移植性补丁

| 场景 | 处理 |
|---|---|
| 精简 Linux 没有 perl 的 `shasum` | 取件脚本自动生成临时 `shasum` 垫片（转调 coreutils `sha256sum -a 256` 等价形式），只在该次调用内生效，退出即删 |
| GitHub 下载抖动（HTTP/2 framing 错误、半截文件） | [tools/fetch_liboqs_0.10.0.sh](../../../../tools/fetch_liboqs_0.10.0.sh) 强制 HTTP/1.1、对传输错误重试，失败不留半截归档 |
| 残留的 kyber fetch 镜像目录 | 取件脚本把它挪到 `build/fetch-stale-<UTC 时间戳>/`，**不删除任何内容**，随后照常取件 |
| 只装了一部分 vendor 树 | 脚本拒绝覆盖既有树并报错退出，交人工核对 |
