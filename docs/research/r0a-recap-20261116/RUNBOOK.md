# R0a 复测执行手册（RUNBOOK）——给裸金属侧机器/操作者

配套冻结文件：本目录 `PLAN.md`（采集合同，执行前用其 git blob SHA-256 作 `plan_sha256`）。
本手册只回答"在哪台机器上、按什么顺序、敲哪些命令"，判据与停止规则一律以 PLAN 为准。
执行环境：能 SSH `nss-marker@10.144.144.5`（密码认证，按 AGENTS 主机身份核验）的开发机
（Linux/WSL/macOS 均可），远端唯一存放边界 `/home/nss-marker/yhr/Cry`。

## 0. 预备（开发机，一次性）

```sh
git clone https://github.com/Gowin-liuyin/cryProject.git   # 或已有克隆 git pull
cd cryProject && git checkout <包含 P2/P8 提交的 main HEAD>
sh tools/fetch_all_vendors.sh                              # 取齐两棵 kyber 树
sh scripts/prepare_r0a_bundle.sh HEAD /tmp/r0a-upload.tar.gz
git rev-parse HEAD                                          # 记录源提交
```

## 1. 上传与预置（远端）

```sh
scp /tmp/r0a-upload.tar.gz nss-marker@10.144.144.5:/home/nss-marker/yhr/Cry/
ssh nss-marker@10.144.144.5
cd /home/nss-marker/yhr/Cry
NONCE=$(printf '%012x' $((RANDOM * RANDOM * RANDOM)))
ROOT=$PWD/r0a-branchfix-20261116-$NONCE
mkdir -p $ROOT && tar -xzf r0a-upload.tar.gz -C $ROOT --strip-components=1
cd $ROOT && mkdir -p plans runs build-ordinary controller logs
# PLAN blob 摘要（开发机执行，回填远端）：
#   git show <HEAD>:docs/research/r0a-recap-20261116/PLAN.md | sha256sum
cp docs/research/r0a-recap-20261116/PLAN.md plans/PLAN.md
sha256sum plans/PLAN.md | tee plans/PLAN.exec.sha256
```

## 2. 三臂构建与冻结（PLAN §1）

- A0/A1：复用封存 collector-v2 的两个普通 ELF，摘要必须逐字等于 PLAN §1 表
  （`b1e820e8…` / `c9cecdaf…`）；不一致即停。
- A2：解包 `docs/evidence/m2-kem-20261016/collector-v2-2e894561892a/source` 副本 →
  `git apply docs/patches/m2-frommsg-barrier-asm.patch`（补丁 SHA-256 `5e7fe0fc…`）→
  按 `tools/platform_m2/run_collector_build.sh` 同口径构建（远端 clang 18.1.3）。
- 三臂 ELF 摘要与 keypair 产物写入 `runs/MANIFEST.sha256` 后才允许采数。

## 3. 产物层准入（先于任何采数）

```sh
tests/check_m2_frommsg_branchless.sh --elf <A0 ELF>   # 期望 secret_conditional_jumps=1
tests/check_m2_frommsg_branchless.sh --elf <A1 ELF>   # 期望 1
tests/check_m2_frommsg_branchless.sh --elf <A2 ELF>   # 期望 0（退出 0）
```

## 4. 九次锁频运行（PLAN §3 矩阵，串行）

- controller.py 摘要先核对 PLAN §4（`4a0cf57a…`）。
- 每次 run：`sudo -n /usr/bin/python3 -I -B controller/controller.py run …`，
  参数按 PLAN §4 模板（`--plan-sha256` 用第 1 步的摘要；seed/CPU/臂顺序照矩阵表）。
- 每次运行后检查 `terminal.json` 四判据；任何一次不满足即停，不重试择优。

## 5. 定位层（Memcheck，三臂）

- 秘密标记探针对三臂各跑：期望上下文数 **1 / 1 / 0**（A0/A1/A2）。
- 输出与退出码落 `logs/`。

## 6. 拉回与统计（开发机）

```sh
rsync -a nss-marker@10.144.144.5:$ROOT/ docs/evidence/r0a-branchfix-recap-20261116/remote/
# 统计：platform_stats 逐 run Welch → platform_holm 家族 m=9、α=0.05
# 结论按三层写：产物层 0/1/1、定位层 1/1/0、统计层 Holm/CI 如实（CI 含 0 = 未检出，不是恒时）
```

## 7. 顺带任务（同一趟 SSH 可打包）

- **R18 SMT pilot**：按 `docs/research/r18-smt-pilot-20261116/PLAN.md`；受害者侧用
  本仓库新交付的 `platform-m2/<arm>/observer_victim`（P8，`sync_mode=wrapper_hook`，
  PLAN §2 例外条款），观测者 ELF 在远端从同一提交构建并把摘要写入
  `observer/MANIFEST.sha256`；一对进程由 `tools/platform_observers/run_pair.sh` 拉起，
  类别 join 用 `scripts/platform_stats/join_observer_classes.py`，pilot 后接
  `mde_budget.py`。
- **R19 cache pilot**：按 `docs/research/r19-cache-pilot-20261116/PLAN.md`；受害者侧
  `platform-m3/shared-on/observer_victim`（P8），LUT 文件按 PLAN §1 规格生成并设
  `PLATFORM_M3_SHARED_LUT_PATH`；本地真实臂冒烟已验证该链路（30/30 类别命中，仅作
  机制存在性参考，不作正式统计）。
- 两个 pilot 的输出全部标族外 exploratory，不进任何 Holm 家族。

## 8. 边界（执行者必读）

- 全部远端文件只在 `Cry` 边界内；不写 `/tmp`、`/run`；`TMPDIR=$ROOT/tmp`。
- 不重试择优、不事后改预算/种子/CPU/顺序；失败如实记录并停。
- 阴性（CI 含 0）写"未检出"；本 PLAN 全部判据都不构成恒时证明。
- 结束核对：32 policy/global boost 回读、控制器锁释放、SSH 会话关闭。
