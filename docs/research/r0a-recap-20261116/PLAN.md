# R0a 分支修复复测采集冻结计划（PLAN）

- 任务号：T2.4（R0a 复测，裸金属，主控执行；本阶段只冻结计划、**不执行任何采集**）
- 冻结日期：2026-11-16（Asia/Shanghai）
- 对象：历史 pq-crystals Kyber768 round3（SHAKE），`KYBER_K=3`，**不是 FIPS 203**
- 上位依据：`docs/工程总体计划与分阶段任务书-20261116.md` §4 T2.4；
  采集口径沿用 `docs/evidence/platform-collection-20261016/README.md`、
  `docs/evidence/m2-kem-20261016/{PLAN,COLLECTOR_CONTRACT}.md`、`docs/evidence/r05-locate-20261016/`
- 状态：**冻结候选，待主控在本文件提交后执行**。执行前必须先提交本 PLAN，并在每次
  `controller.py run` 里用 `--plan-sha256` 校验本次执行的 PLAN blob；PLAN 内容本身无法自引用
  自身提交号，执行时写入 `plans/PLAN.exec.sha256`。

---

## 0. 冻结摘要（执行时逐条核对）

| 项 | 冻结值 |
|---|---|
| 家族名 | `m2_branchfix_end_to_end_v1` |
| 家族成员数 m | **9** = 3 臂 × 3 次运行 |
| 样本预算 | 主类对每类 **10000**，预热 **100**（窗口外，沿用 collector-v2 合同） |
| 种子 / CPU | r01 = seed `31337` / CPU2；r02 = seed `424242` / CPU2；r03 = seed `31337` / CPU6 |
| 目标频率 | 全局 boost=0；目标 singleton policy governor/EPP=`performance`、min=max=`4300000` kHz；`taskset -c 2` 或 `-c 6` |
| 放行门 | 写入回读完成后沉降 1.0 s，再取 20×50 ms `scaling_cur_freq`，全部在 4300000 ±2% 且跨度 ≤50000 kHz |
| 统计 | `platform_stats`（Welch CI/p）→ `platform_holm` 家族 m=9、全族 α=**0.05** |
| 定位层 | Valgrind Memcheck 秘密标记探针，上下文数判据 **1 / 1 / 0**（A0 / A1 / A2） |
| 产物层 | A2 修复臂 `pqcrystals_kyber768_ref_poly_frommsg` 的秘密条件跳转 **0** |
| 停止规则 | 9 次 controller 运行全部完成或明确失败；**不重试择优、不事后改 m/预算/α/种子/CPU/顺序** |

## 1. 三臂（固定对象）

| 臂 | 源码 | 采集 ELF（冻结摘要） | 说明 |
|---|---|---|---|
| **A0 未修** | pq-crystals kyber `a621b8dde405cc507cbcfc5f794570a4f98d69cc` | `m2_decaps_collector` `b1e820e848d83cb334a967c64573c3c3355451e6e72778b45af96724e9c96b5d` | 历史未修臂（KyberSlash1 父提交） |
| **A1 上游已修** | pq-crystals kyber `272125f6acc8e8b6850fd68ceb901a660ff48196` | `m2_decaps_collector` `c9cecdafb6bb855c44f08e52289baf2754fc6376fde0422ec004ec8945f4e9a8` | 上游 KyberSlash1+2 修复对照 |
| **A2 自研修复** | A1 源码 + `docs/patches/m2-frommsg-barrier-asm.patch`（SHA-256 `5e7fe0fce1132f0a13e0202e4bed73f0664231a686866836fb4510cd14838eed`） | 构建后冻结（执行前置） | R0a 主候选：`poly_frommsg` 值屏障 |

- A0/A1 使用已封存 collector-v2 的两个普通 ELF（摘要同上，来自
  `docs/evidence/m2-kem-20261016/COLLECTOR_CONTRACT.md` §3），**不得**用只读测量原件顶替。
- A2 构建方式：解包 `collector-v2-2e894561892a/source` 副本 → 应用主候选补丁 → 按
  `tools/platform_m2/run_collector_build.sh <tree-root>` 同一 configure/build 口径构建
  （Clang `18.1.3`、`RelWithDebInfo`、vendor `-Oz -g -fno-vectorize -fno-slp-vectorize`
  `-DKYBER_K=3 -Drandombytes=platform_m2_randombytes`；sanitizer 只做资格、不采数）。
- A2 的 ELF SHA-256、`SOURCE_TREE.sha256`、补丁摘要必须在**任何采数开始前**写入
  `runs/MANIFEST.sha256` 并复核；未冻结即不得采数。产物层准入：对 A2 collector 运行
  `tests/check_m2_frommsg_branchless.sh --elf <A2 collector>` 必须
  `secret_conditional_jumps=0`（退出 0）；A0/A1 同脚本各为 1（对照）。

## 2. 类对

- **主类对（进主检验）**：class0 = `message-zero`，class1 = `message-ones`；
  效应量 = `mean(class0) − mean(class1)`（ns），双侧。两类为同一固定公开测试 key 下的
  合法 1088 字节密文，各自重复同一密文。
- **对照类对（不进主检验）**：`malformed-zero-tail` vs `malformed-ff-tail`；
  只输出描述性统计/族外稳健性，不进入 Holm 家族，不改变任何判定。

## 3. 运行矩阵与顺序（合同的一部分）

| 运行 | seed | CPU | 臂顺序（固定） |
|---|---:|---:|---|
| `r01` | 31337 | 2 | A0 → A2 → A1 |
| `r02` | 424242 | 2 | A1 → A2 → A0 |
| `r03` | 31337 | 6 | A2 → A0 → A1 |

- 每个 controller run = 一个 `--run-name`（例：`r0a-r01-a0`），一个 worker 只跑一个臂的主类对；
  每臂每类 10000、预热 100（窗口外）。9 次 run 全部在锁频合同下串行执行。
- 固定测试密钥：`keypair_tool --key-seed 31337` 产出同一对 `pk.bin`/`sk.bin`，三臂共用
  （keypair 产物摘要记入 `runs/MANIFEST.sha256`；A0/A1 的 keypair 遇已有文件不得覆盖）。

## 4. 采集命令（模板）

控制根、源码、PLAN、补丁、构建与结果全部位于
`/home/nss-marker/yhr/Cry/r0a-branchfix-20261116-<12位hex nonce>/` 下的**新子目录**；
禁止写入 `Cry` 之外（含 `/tmp`、`/run`、用户家目录其他位置）；不 sudo 改系统配置；
控制器与锁按 `tools/platform_control/README.md` 合同，`controller.py` SHA-256
`4a0cf57a00c6802ff86ed410bd2518bc56cc8e694422cbc4ea7a24a3f1cdd701`
（与 `platform-collection-20261016/README.md` §1.0 一致，执行前复核）。

```sh
ROOT=/home/nss-marker/yhr/Cry/r0a-branchfix-20261116-<nonce>
CONTROL=$ROOT/controller
CRY=/home/nss-marker/yhr/Cry

# 0) 预置：上传本 PLAN、主候选补丁、collector-v2 source 副本、探针源码；落 SOURCE_TREE.sha256
# 1) 构建三臂 collector（A0/A1 复用封存 ELF，摘要复核；A2 按 §1 构建）并冻结
sha256sum $ROOT/build-ordinary/collector/{a0,a1,a2}/m2_decaps_collector | tee $ROOT/runs/MANIFEST.sha256

# 2) 产物层准入
$ROOT/source/tests/check_m2_frommsg_branchless.sh --elf $ROOT/build-ordinary/collector/a2/m2_decaps_collector
#   期望：secret_conditional_jumps=0（退出 0）；A0/A1 各为 1

# 3) 每次 run（共 9 次，按 §3 矩阵串行）：
sudo -n /usr/bin/python3 -I -B $CONTROL/controller.py run \
  --control-root $CONTROL --run-name r0a-r01-a0 --cpu 2 --timeout-seconds 300 \
  --plan $ROOT/plans/PLAN.md --plan-sha256 <冻结 PLAN 摘要> \
  -- $ROOT/build-ordinary/collector/a0/m2_decaps_collector \
     --class message-zero,message-ones --samples 10000 --seed 31337 \
     --raw $ROOT/runs/r0a-r01-a0/raw/m2-main.csv \
     --meta $ROOT/runs/r0a-r01-a0/raw/m2-main.meta \
     --run-id r0a-r01-a0 \
     --public-key $ROOT/fixtures/pk.bin --secret-key $ROOT/fixtures/sk.bin

# 4) 退出后核对：terminal.json 应为 reason=worker_finished、worker_exit_code=0、
#    worker_drained=true、restore_match=yes；主控另读 32 个 policy、global boost、
#    原 PID/组与两把锁，全部与进入快照一致后才开始下一 run。
```

- 采集 ELF 必须在 `Cry` 内；临时目录统一 `TMPDIR=$ROOT/tmp`、`XDG_CACHE_HOME=$ROOT/cache`，
  源码中的其他显式临时路径执行前逐项审查；不写 `Cry` 之外。
- 若任一 run 的放行门失败/超时/恢复不符：记录该 run 状态，**不补抽、不重试择优**；
  整个矩阵按实际完成情况报告（缺失成员记 `not_run`，不进入 Holm 家族）。

## 5. 统计口径（冻结）

1. 每 run × 臂的主类对原始 CSV 用 `platform_stats`（冻结 ELF
   `ddc48b9ef92a010e9b804389cabc4089e042c814ac8af4b3fa89e541bf4ac9e2`）：
   `--format measure --classes message-zero message-ones`，得 `ci_welch.json`：
   `mean_difference_class0_minus_class1_ns`、`ci95_normal_lower/upper_ns`、
   `welch_t`、`p_two_sided_normal_approximation`。极端 |t| 的 p 下溢按 0 报告，
   同时保留 t 与 CI，不称"数学 p 恰为 0"。
2. 家族 `m2_branchfix_end_to_end_v1`：m=9，全族 α=0.05，成员 = 9 个 (run, arm) 主类对；
   用 `platform_holm`（`tools/platform_stats/holm.c`）做 Holm step-down，输出
   `holm.csv`、`pooled.csv`、`holm_summary.json`。**只对 9 个已完成成员建族**；
   任何 `not_run` 成员必须在采集后按预注册规则处理（若无法完成全部 9 个，家族整体
   标记 `incomplete`，不补抽硬凑）。
3. RTLF/dudect 等族外检查可作描述性稳健性参考，**不进本家族、不改本家族判定**。
4. 判据（执行前冻结，失败不得放宽）：
   - **R0a-1 产物层**：A2 collector 的 `poly_frommsg` `secret_conditional_jumps=0`（判据）。
   - **R0a-2 定位层**：Memcheck 上下文数 A0/A1/A2 = **1 / 1 / 0**（判据）。
   - **R0a-3 统计层**：9 成员 Holm 结果 + 主类对 CI 如实报告；若 A2 出现 Holm 拒绝，
     该臂记为"未通过未检出判据"，不得事后调参或改族；若 A0/A1 未拒绝，不得据此宣布
     "无泄漏"（历史 M2 端到端家族未拒绝的先例见 `platform-collection-20261016`，
     统计层不是单一充分证据）。
   - 三层结论分开陈述：产物/定位/统计不得互相冒充。

## 6. 定位层 Memcheck 探针（冻结口径）

沿用 `docs/evidence/r05-locate-20261016/` §4 的口径（探针源码 SHA-256
`a4b10060a066f34ff53d161db50966c4347b00e56ac8f2a772c181591ec87be0`；本 PLAN 执行时
从该目录归档恢复探针源码并复核摘要；若该文件不可得，按下列规格重建并记录新摘要）：

- 探针调用同一份 vendor 源码的 `crypto_kem_keypair` / `crypto_kem_enc` / `crypto_kem_dec`，
  用 `VALGRIND_MAKE_MEM_UNDEFINED` 把 `sk` 的 **1152 字节 PKE 私钥**按 8 个分区累积标记
  （最后一次分区覆盖整段），共享秘密在消费前用 `VALGRIND_MAKE_MEM_DEFINED` declassify。
- 三臂各构建一份：`clang -O1 -g -DNDEBUG -DKYBER_K=3 -I<arm>/ref`，不加屏障类编译选项；
  A2 使用打了主候选补丁的源码。
- 运行：

```sh
taskset -c 0,1,3 valgrind --error-exitcode=99 --track-origins=yes \
  $ROOT/build-ordinary/probe/probe_<arm> 8 7
```

- 记录每份日志的 `ERROR SUMMARY: N errors from M contexts`；判据 M = **1 / 1 / 0**
  （A0 / A1 / A2）。A2 若出现任何秘密依赖上下文 → R0a-2 不通过，停止并如实报告。
  Memcheck 只覆盖实际执行到的秘密条件分支/条件传送，不覆盖非分支类时间差，也不是恒时证明。

## 7. 远端目录约定

```
/home/nss-marker/yhr/Cry/r0a-branchfix-20261116-<12位hex nonce>/
├── plans/PLAN.md  PLAN.exec.sha256
├── source/                    # collector-v2 source 副本 + 主候选补丁 + 探针源码 + 校验清单
├── build-ordinary/collector/{a0,a1,a2}/  # 三臂 m2_decaps_collector
├── build-ordinary/probe/      # 三臂 Memcheck 探针
├── fixtures/                  # keypair_tool --key-seed 31337 的 pk/sk 与摘要
├── runs/<run-name>/           # raw CSV/meta、controller/、terminal.json、entry/exit 快照
├── sets/<run-name>/           # platform_stats 输出（ci_welch.json 等）
├── stats/members/members.csv  # 9 成员表
├── stats/holm/                # platform_holm 输出
├── logs/                      # build/qualification/localize 日志
└── tmp/ cache/                # 仅本任务临时与缓存（均在 Cry 内）
```

- 每个执行使用**新 nonce 目录**，不覆盖、不复用旧根；结束后原件保留，不删除。
- 结果只读拉回后由主控归档到 `docs/evidence/r0a-branch-fix-20261116/` 的新子目录
  （不改已有文件）；拉回件与远端原件摘要逐项核对。

## 8. 执行前置检查清单（主控）

1. 本 PLAN 已在 `main` 提交；记录 `git show <提交>:docs/research/r0a-recap-20261116/PLAN.md`
   的 blob SHA-256 作为 `--plan-sha256`。
2. `sh tools/fetch_all_vendors.sh` 四棵树与钉版摘要一致；`docs/patches/m2-frommsg-barrier-asm.patch`
   摘要等于 `5e7fe0…`。
3. `controller.py` 摘要 `4a0cf57a…`；锁 `/home/nss-marker/yhr/Cry/partition-admin.lock` 与
   新控制根 `collection.lock` 可用；`boot_id`、32 policy/global 快照已记录。
4. 三臂 ELF/探针摘要、keypair 摘要、source 清单写入 `runs/MANIFEST.sha256` 后再开始第一次采数。
5. 全程 `frequency_control=not_configured` 之外的写操作只经控制器；不使用 sudo 改系统配置；
   不写 `Cry` 外；人工签字/审批不在本 PLAN 范围。
