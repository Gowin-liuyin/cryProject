# A 线 bundle：需裸金属执行的动态/计时补采清单（2026-11-16）

本文件汇总 P7 三处本地只能做到反汇编层、必须由主控在裸金属补采的项。
每项写：来源、待采内容、判据、参考命令/材料、依赖与边界。**本阶段不执行任何采集。**

## A-R17：向量化对象（R17，来源 `docs/R17-向量化排查表-20261116.md`）

| id | 对象 | 待采内容 | 判据 | 备注 |
|---|---|---|---|---|
| A-R17-01 | `liboqs-avx2-dist`（分发构建，AVX2 变体） | Memcheck 秘密标记：sk 的 1152 B PKE 私钥；统计 `errors/contexts` | 只记录实际命中；不得把反汇编"无分支"当阴性 | 本机 `valgrind` ABSENT；本地仅 roundtrip 100/100 |
| A-R17-02 | `kyber-avx2-unfixed` / `-fixed`（round3 `avx2/` 两臂） | Memcheck 秘密标记 + 官方 `test_kyber768` KAT 复核（本地已跑退出 0，裸金属复跑） | 同上；两臂对照如实记录 | 本机已跑自带 selftest（退出 0），动态未做 |
| A-R17-03 | `mlkem-native-native`（amalgamation + asm 后端） | Memcheck 秘密标记 + 官方 KAT（vendor 无自带 KAT 入口，需按 mlkem-native 上游 KAT 流程补） | 同上 | 本机只做 deterministic roundtrip |
| A-R17-04 | 三对象 | 锁频计时（可选、族外描述）：向量化与非向量化对象的对照批次 | 只作族外 exploratory；不进 Holm | 与 R23/R09 口径一致，主控决定是否开展 |

## A-R23：优化矩阵本地补格（R23，来源 `docs/research/r23-optlevel-ext-20261116/`）

| id | 内容 | 待采内容 | 判据 | 备注 |
|---|---|---|---|---|
| A-R23-01 | 24 个本地格（gcc 4×M1 两臂；clang-18 3×M1 两臂；clang-18 4×M2 两臂） | 逐格 Memcheck 秘密标记（M1 1152 B；M2 sk/PKE 秘密） | 逐格 `errors/contexts` 如实记录；同一 secret 标记口径 | 本地只判反汇编五预注册位 |
| A-R23-02 | 锁频计时矩阵（可延后） | 需要时由主控冻结新预算，按 R09 PLAN 体例对新增格做 3 seed 计时 | 族外 exploratory，不进 Holm；预算先冻结 | 本轮不执行、不扩预算 |

## A-R24：Binsec 扩面（R24，来源 `docs/research/r24-binsec-ext-20261116/PLAN.md`）

| id | 内容 | 待采内容 | 判据 | 备注 |
|---|---|---|---|---|
| A-R24-01 | `binsec_harness_cmov` / `binsec_harness_kdf`（新增 harness） | Binsec `-checkct` 有界分析执行与原始输出 | 未知/pending/超时/装载失败一律保留，不只凭退出码 0 写 secure | 本机只做源码语法级检查；执行命令/判据见 R24 PLAN |

## 完成状态

- R17 部分：本地反汇编与自检完成（3 对象、KAT/自检状态见 R17 表）；Memcheck/KAT 复核待裸金属（A-R17-01..04）。
- R23 部分：24 格本地产物判定完成（见 R23 RESULT）；Memcheck 与锁频计时待裸金属（A-R23-01/02）。
- R24 部分：harness + cfg + PLAN 完成；执行待裸金属（A-R24-01）。
- 本清单只列待办与判据，不改变任何既有判定；实际采集由主控执行并把原件拉回 `docs/evidence/` 新目录。
