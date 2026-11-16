# R23 优化矩阵本地补格结果（反汇编层，2026-11-16）

- 任务号：T7.2
- 范围：**本地只做产物判定（反汇编层）**；Memcheck 与锁频计时一律留给裸金属
  （见 `BARE_METAL_PLAN.md` 与 `docs/research/phase7-session-20261116/A_LINE_BUNDLE.md`）。
- 环境：WSL2 Linux 6.6.114.1，gcc 14.3.0（conda）、clang 18.1.8（conda `envs/cry`），
  binutils 2.45.1；`valgrind` ABSENT；vendor 只读，全部构建在 `build/p7/r23/`（gitignored）。

## 1. 矩阵与判定位

| 组 | 格数 | 臂 | 编译器/级别 |
|---|---:|---|---|
| gcc 新增补格 | 8 | M1 未修 / 982c762 已修 | gcc `-O0/-O2/-O3/-Os`（gcc 无 `-Oz`，禁止生成该组合） |
| clang 缺失补格 | 6 | M1 两臂 | clang 18.1.8 `-O1/-Oz/-Og` |
| M2 全新格 | 8 | M2 `a621b8d` 未修 / `272125f` 已修 | clang 18.1.8 四级 `-O0/-O1/-Oz/-Og`（覆盖最小、基础、历史 `-Oz`、调试优化；`-O2/-O3` 的 clangover 形态已由 R09 M1 系列覆盖） |

- M1 源：`vendor/liboqs-0.10.0(-982c762)/src/kem/ml_kem/pqcrystals-kyber-standard_ml-kem-768-ipd_ref/`
  的 `poly.c/indcpa.c/kem.c/verify.c`（liboqs 用共享 sha3，不另编 `fips202.c`）。
- M2 源：`vendor/kyber-kyberslash-{unfixed,fixed}/ref/` 的 `poly.c/indcpa.c/kem.c/verify.c/fips202.c`。
- 编译口径：除 `-O*` 一个 token 外沿用 R09 冻结口径——
  clang 组 `-fno-vectorize -fno-slp-vectorize -DKYBER_K=3`，gcc 组
  `-fno-tree-vectorize -fno-tree-slp-vectorize -DKYBER_K=3`（gcc 的两条等价禁止向量化旗标）。
- 判定位**复刻 R09 预注册五判定**（`tools/platform_optlevel/judge_cells.py` 文档字符串）：
  `clangover_bt_jae`（bt 后 4 条内条件跳转）、`per_bit_test_jcc`（`testb $imm,(内存)` 后 2 条内条件跳转）、
  `secret_division`（div/idiv 计数）、`setcc` / `cmov`、`conditional_jumps` 对照。
  **判定规则先冻结后跑数，未按结果改。**

## 2. 本地 24 格判定表

完整机器可读表见 [`cells.tsv`](cells.tsv)。摘要：

| 组 | bt_jae | per_bit_test_jcc | frommsg div | poly_compress/tomsg div | setcc | 结论（反汇编层） |
|---|---|---|---|---|---|---|
| M1 未修 × gcc 4 级 | 0/4 | 0/4 | 0 | 0 | 0 | gcc 不产生 clangover 位分支形态（与 R09 的"gcc 未做"方向一致） |
| M1 已修 × gcc 4 级 | 0/4 | 0/4 | 0 | 0 | 0 | 无秘密位分支；无 div |
| M1 未修 × clang O1/Oz/Og | **3/3 yes** | 0/3 | 0 | 0 | 0 | `bt+jae` 形态在三个 clang 级别复现（O1/Oz/Og） |
| M1 已修 × clang O1/Oz/Og | 0/3 | 0/3 | 0 | 0 | 1（三格） | 同源码修复后 `bt` 接 `setcc` 而非 `jae`（与 R09 `-Os` 结论同向） |
| M2 两臂 × clang O0/O1/Oz/Og | 未修 3/4、已修 3/4（O0 均 no） | 0/8 | 0 | 未修 O0=1、Oz=1，O1/Og=0；已修全 0 | 0 | M2-c 的 `bt/jae` 在 O1/Oz/Og 两臂都保留（上游 272125f 不碰 `poly_frommsg`）；KyberSlash `div` 只在未修臂 O0/Oz 出现 |

行级明细（24 行）见 `cells.tsv`；每格编译命令为脚本 `build/p7/r23.py` 中
`compile_object()` 的实参，原生反汇编在 `build/p7/r23/<cell>/`（产物，未提交）。

## 3. 结论与边界

- 本地 24 格**全部完成反汇编判定**（无"未检查"格）；每格判定位为 R09 预注册五位的复刻。
- M1 gcc 四级别**没有**出现 clangover `bt/jae` 或 `testb+jcc`：与 R09 "gcc 不做"的路径选择一致，
  但本表仅覆盖本机 gcc 14.3.0 + 上述旗标，不外推到其它 gcc。
- M1 已修在 clang O1/Oz/Og 出现 `setcc`（不是 `jae`），说明修复后的源码在三个级别都走向掩码物化；
  但仍**不能**据此写"泄漏消失"（反汇编层，无动态依赖检查）。
- M2 两臂在 clang O1/Oz/Og 都有 `bt/jae`：`272125f` 只修 KyberSlash 除法、不碰 `poly_frommsg`
  （与 R05 M2-c 一致）；M2 未修的 `div` 在 `-O0/-Oz` 出现、`-O1/-Og` 消失，说明**级别变化会让
  KyberSlash 除法形态静默消失**——正式计时必须锁级别，本表不给跨级别"泄漏消失"结论。
- 本地编译器与证据机不同（本机 clang 18.1.8 vs 证据机 18.1.3；gcc 14.3.0 无证据机对应），
  因此本表结论**不搬到证据机产物**；裸金属复核见 `BARE_METAL_PLAN.md`。
- Memcheck 与锁频计时**未执行**（本机 valgrind ABSENT、无锁频）；汇入
  `A_LINE_BUNDLE.md` 的 `A-R23-01/02`，不改变任何既有判定。

## 4. 复跑

```sh
python3 build/p7/r23.py            # 24 格编译 + 五预注册位判定，输出 build/p7/r23/cells.tsv
# 判定位脚本参照：tools/platform_optlevel/judge_cells.py（R09 预注册五判定）
```
