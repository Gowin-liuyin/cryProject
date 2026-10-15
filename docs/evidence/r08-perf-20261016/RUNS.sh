#!/bin/sh
# R08 性能开销采集：54 条控制器命令。**本文件不被自动执行**，由主控串行逐条复制执行。
#
# 合同见 docs/evidence/r08-perf-20261016/PLAN.md（本文件只给可直接复制的命令与判据）。
#   - 频率：boost=0、governor/EPP=performance、min=max=4300000 kHz、taskset -c 2（控制器 --cpu 2）
#   - 有效判据：terminal.json 的 reason=worker_finished、worker_exit_code=0、
#     worker_drained=true、restore_match=yes **同时**成立；restore_match=yes 才算有效
#   - 交错：每两块一个单元，第一单元先 A 后 B，第二单元先 B 后 A（ABBA 配对块），共 12 块（每臂 6 块）
#   - **修正（主控 2026-10-16）**：原文件把 `--block-count` 写成 6 而 `--block-index` 用全局 0..11，
#     触发 harness 的 `block_index >= block_count` 校验（退出码 2），P2 的 18 次运行无效。
#     `block_count` 只用于该校验并写进 meta，不参与顺序生成（顺序由 order_seed 决定），
#     因此改为 12 是纯修正，不改变计时语义。18 次无效运行已归档到 R08/failed/ 后重跑。
#   - 每块：decaps 25000、keygen 5000、encaps 5000，预热各 100（窗口外）
#   - 每臂累计：decaps 150000、keygen 30000、encaps 30000（均高于 PLAN 预算）
#   - 运行名与输出目录一一对应；CSV/meta 用 "wx" 新建，已存在即失败
#
# 执行前必须做两件事：
#   1) 上传 PLAN 并核对摘要（必须逐字等于下面的 PLAN_SHA）：
#        sha256sum /home/nss-marker/yhr/Cry/platform-collect-20261016-c011ec7a5e01/plans/r08-perf-PLAN.md
#   2) 确认控制根存在、controller.py 摘要为
#        4a0cf57a00c6802ff86ed410d2518bc56cc8e694422cbc4ea7a24a3f1cdd701
#      （若主控本轮另建控制根，把下面的 CONTROL 换成主控给的路径即可，其余不变）
#
# 失败处理：任一 run 判据不成立时立即停止后续采集，把该 run 目录整体归档到
#   /home/nss-marker/yhr/Cry/platform-collect-20261016-c011ec7a5e01/R08/failed/<run-name>-attempt<n>/ ，换新 run-name（-a2/-a3）重跑；
#   失败运行不计入结果，也不从记录里消失。

COLLECT=/home/nss-marker/yhr/Cry/platform-collect-20261016-c011ec7a5e01
CONTROL=/home/nss-marker/yhr/Cry/platform-control-20261016-53929b406f0d
PLAN=$COLLECT/plans/r08-perf-PLAN.md
PLAN_SHA=b2e1833017c3c64f2a9de022615df0944e8d19edd8d663390c51b3e90bb20ea4
R08=/home/nss-marker/yhr/Cry/r08-perf-20261016-85e46c952887

# 执行记录（2026-10-16 04:19 起，由主控执行）：
#   主控实际使用的运行名与本文件的 `r08-perf-<arm>-b<块号>` **同构但编号不同**：
#   块号取"该配对 12 次运行中的全局序号 1..12"（A,B,B,A,A,B,B,A,A,B,B,A），
#   即 m1unfixed 占 b1/b4/b5/b8/b9/b12，m1fixed 占 b2/b3/b6/b7/b10/b11，其余配对同理。
#   每臂仍是 6 次运行。**主控传入的 `--block-index` 是该配对 12 次运行中的全局序号减 1
#   （0..11，实测 b1→0、b2→1、b3→2、b4→3、b5→4），而 `--block-count` 仍是 6**：
#   两个字段合起来只作标签，不参与任何计算；T21 请以运行名序列（ABBA 的第几次）
#   而不是 `block_index` 来数块。除运行名与这一对标签外，
#   采集参数（25000/5000/5000、预热 100、`--seed 31337`、`--order-seed 20261016`、
#   `--block-count 12`、`--cpu 2`、`--timeout-seconds 600`）与本文件逐字一致，
#   可从每个 run 目录内的 `<run>.meta` 与 `controller/command.json` 复核。
#   臂身份以 meta 的 `arm=` 与 CSV 的 `implementation` 为准，不以目录名推断。

# ------------------------------ P1 M1（liboqs 0.10.0 historical-clangover 未修 / +982c762） ------------------------------
mkdir -p $COLLECT/R08/r08-perf-m1unfixed-b1
sudo -n /usr/bin/python3 -I -B $CONTROL/controller.py run \
    --control-root $CONTROL --run-name r08-perf-m1unfixed-b1 --cpu 2 --timeout-seconds 600 \
    --plan $PLAN --plan-sha256 $PLAN_SHA \
    -- $R08/build/m1unfixed/perf_measure \
        --run-id r08-perf-m1unfixed-b1 --arm m1unfixed --seed 31337 --warmup 100 \
        --decaps-samples 25000 --keygen-samples 5000 --encaps-samples 5000 \
        --block-index 0 --block-count 12 --order-seed 20261016 \
        --raw $COLLECT/R08/r08-perf-m1unfixed-b1/r08-perf-m1unfixed-b1.csv \
        --meta $COLLECT/R08/r08-perf-m1unfixed-b1/r08-perf-m1unfixed-b1.meta
mkdir -p $COLLECT/R08/r08-perf-m1fixed-b2
sudo -n /usr/bin/python3 -I -B $CONTROL/controller.py run \
    --control-root $CONTROL --run-name r08-perf-m1fixed-b2 --cpu 2 --timeout-seconds 600 \
    --plan $PLAN --plan-sha256 $PLAN_SHA \
    -- $R08/build/m1fixed/perf_measure \
        --run-id r08-perf-m1fixed-b2 --arm m1fixed --seed 31337 --warmup 100 \
        --decaps-samples 25000 --keygen-samples 5000 --encaps-samples 5000 \
        --block-index 1 --block-count 12 --order-seed 20261016 \
        --raw $COLLECT/R08/r08-perf-m1fixed-b2/r08-perf-m1fixed-b2.csv \
        --meta $COLLECT/R08/r08-perf-m1fixed-b2/r08-perf-m1fixed-b2.meta
mkdir -p $COLLECT/R08/r08-perf-m1fixed-b3
sudo -n /usr/bin/python3 -I -B $CONTROL/controller.py run \
    --control-root $CONTROL --run-name r08-perf-m1fixed-b3 --cpu 2 --timeout-seconds 600 \
    --plan $PLAN --plan-sha256 $PLAN_SHA \
    -- $R08/build/m1fixed/perf_measure \
        --run-id r08-perf-m1fixed-b3 --arm m1fixed --seed 31337 --warmup 100 \
        --decaps-samples 25000 --keygen-samples 5000 --encaps-samples 5000 \
        --block-index 2 --block-count 12 --order-seed 20261016 \
        --raw $COLLECT/R08/r08-perf-m1fixed-b3/r08-perf-m1fixed-b3.csv \
        --meta $COLLECT/R08/r08-perf-m1fixed-b3/r08-perf-m1fixed-b3.meta
mkdir -p $COLLECT/R08/r08-perf-m1unfixed-b4
sudo -n /usr/bin/python3 -I -B $CONTROL/controller.py run \
    --control-root $CONTROL --run-name r08-perf-m1unfixed-b4 --cpu 2 --timeout-seconds 600 \
    --plan $PLAN --plan-sha256 $PLAN_SHA \
    -- $R08/build/m1unfixed/perf_measure \
        --run-id r08-perf-m1unfixed-b4 --arm m1unfixed --seed 31337 --warmup 100 \
        --decaps-samples 25000 --keygen-samples 5000 --encaps-samples 5000 \
        --block-index 3 --block-count 12 --order-seed 20261016 \
        --raw $COLLECT/R08/r08-perf-m1unfixed-b4/r08-perf-m1unfixed-b4.csv \
        --meta $COLLECT/R08/r08-perf-m1unfixed-b4/r08-perf-m1unfixed-b4.meta
mkdir -p $COLLECT/R08/r08-perf-m1unfixed-b5
sudo -n /usr/bin/python3 -I -B $CONTROL/controller.py run \
    --control-root $CONTROL --run-name r08-perf-m1unfixed-b5 --cpu 2 --timeout-seconds 600 \
    --plan $PLAN --plan-sha256 $PLAN_SHA \
    -- $R08/build/m1unfixed/perf_measure \
        --run-id r08-perf-m1unfixed-b5 --arm m1unfixed --seed 31337 --warmup 100 \
        --decaps-samples 25000 --keygen-samples 5000 --encaps-samples 5000 \
        --block-index 4 --block-count 12 --order-seed 20261016 \
        --raw $COLLECT/R08/r08-perf-m1unfixed-b5/r08-perf-m1unfixed-b5.csv \
        --meta $COLLECT/R08/r08-perf-m1unfixed-b5/r08-perf-m1unfixed-b5.meta
mkdir -p $COLLECT/R08/r08-perf-m1fixed-b6
sudo -n /usr/bin/python3 -I -B $CONTROL/controller.py run \
    --control-root $CONTROL --run-name r08-perf-m1fixed-b6 --cpu 2 --timeout-seconds 600 \
    --plan $PLAN --plan-sha256 $PLAN_SHA \
    -- $R08/build/m1fixed/perf_measure \
        --run-id r08-perf-m1fixed-b6 --arm m1fixed --seed 31337 --warmup 100 \
        --decaps-samples 25000 --keygen-samples 5000 --encaps-samples 5000 \
        --block-index 5 --block-count 12 --order-seed 20261016 \
        --raw $COLLECT/R08/r08-perf-m1fixed-b6/r08-perf-m1fixed-b6.csv \
        --meta $COLLECT/R08/r08-perf-m1fixed-b6/r08-perf-m1fixed-b6.meta
mkdir -p $COLLECT/R08/r08-perf-m1fixed-b7
sudo -n /usr/bin/python3 -I -B $CONTROL/controller.py run \
    --control-root $CONTROL --run-name r08-perf-m1fixed-b7 --cpu 2 --timeout-seconds 600 \
    --plan $PLAN --plan-sha256 $PLAN_SHA \
    -- $R08/build/m1fixed/perf_measure \
        --run-id r08-perf-m1fixed-b7 --arm m1fixed --seed 31337 --warmup 100 \
        --decaps-samples 25000 --keygen-samples 5000 --encaps-samples 5000 \
        --block-index 6 --block-count 12 --order-seed 20261016 \
        --raw $COLLECT/R08/r08-perf-m1fixed-b7/r08-perf-m1fixed-b7.csv \
        --meta $COLLECT/R08/r08-perf-m1fixed-b7/r08-perf-m1fixed-b7.meta
mkdir -p $COLLECT/R08/r08-perf-m1unfixed-b8
sudo -n /usr/bin/python3 -I -B $CONTROL/controller.py run \
    --control-root $CONTROL --run-name r08-perf-m1unfixed-b8 --cpu 2 --timeout-seconds 600 \
    --plan $PLAN --plan-sha256 $PLAN_SHA \
    -- $R08/build/m1unfixed/perf_measure \
        --run-id r08-perf-m1unfixed-b8 --arm m1unfixed --seed 31337 --warmup 100 \
        --decaps-samples 25000 --keygen-samples 5000 --encaps-samples 5000 \
        --block-index 7 --block-count 12 --order-seed 20261016 \
        --raw $COLLECT/R08/r08-perf-m1unfixed-b8/r08-perf-m1unfixed-b8.csv \
        --meta $COLLECT/R08/r08-perf-m1unfixed-b8/r08-perf-m1unfixed-b8.meta
mkdir -p $COLLECT/R08/r08-perf-m1unfixed-b9
sudo -n /usr/bin/python3 -I -B $CONTROL/controller.py run \
    --control-root $CONTROL --run-name r08-perf-m1unfixed-b9 --cpu 2 --timeout-seconds 600 \
    --plan $PLAN --plan-sha256 $PLAN_SHA \
    -- $R08/build/m1unfixed/perf_measure \
        --run-id r08-perf-m1unfixed-b9 --arm m1unfixed --seed 31337 --warmup 100 \
        --decaps-samples 25000 --keygen-samples 5000 --encaps-samples 5000 \
        --block-index 8 --block-count 12 --order-seed 20261016 \
        --raw $COLLECT/R08/r08-perf-m1unfixed-b9/r08-perf-m1unfixed-b9.csv \
        --meta $COLLECT/R08/r08-perf-m1unfixed-b9/r08-perf-m1unfixed-b9.meta
mkdir -p $COLLECT/R08/r08-perf-m1fixed-b10
sudo -n /usr/bin/python3 -I -B $CONTROL/controller.py run \
    --control-root $CONTROL --run-name r08-perf-m1fixed-b10 --cpu 2 --timeout-seconds 600 \
    --plan $PLAN --plan-sha256 $PLAN_SHA \
    -- $R08/build/m1fixed/perf_measure \
        --run-id r08-perf-m1fixed-b10 --arm m1fixed --seed 31337 --warmup 100 \
        --decaps-samples 25000 --keygen-samples 5000 --encaps-samples 5000 \
        --block-index 9 --block-count 12 --order-seed 20261016 \
        --raw $COLLECT/R08/r08-perf-m1fixed-b10/r08-perf-m1fixed-b10.csv \
        --meta $COLLECT/R08/r08-perf-m1fixed-b10/r08-perf-m1fixed-b10.meta
mkdir -p $COLLECT/R08/r08-perf-m1fixed-b11
sudo -n /usr/bin/python3 -I -B $CONTROL/controller.py run \
    --control-root $CONTROL --run-name r08-perf-m1fixed-b11 --cpu 2 --timeout-seconds 600 \
    --plan $PLAN --plan-sha256 $PLAN_SHA \
    -- $R08/build/m1fixed/perf_measure \
        --run-id r08-perf-m1fixed-b11 --arm m1fixed --seed 31337 --warmup 100 \
        --decaps-samples 25000 --keygen-samples 5000 --encaps-samples 5000 \
        --block-index 10 --block-count 12 --order-seed 20261016 \
        --raw $COLLECT/R08/r08-perf-m1fixed-b11/r08-perf-m1fixed-b11.csv \
        --meta $COLLECT/R08/r08-perf-m1fixed-b11/r08-perf-m1fixed-b11.meta
mkdir -p $COLLECT/R08/r08-perf-m1unfixed-b12
sudo -n /usr/bin/python3 -I -B $CONTROL/controller.py run \
    --control-root $CONTROL --run-name r08-perf-m1unfixed-b12 --cpu 2 --timeout-seconds 600 \
    --plan $PLAN --plan-sha256 $PLAN_SHA \
    -- $R08/build/m1unfixed/perf_measure \
        --run-id r08-perf-m1unfixed-b12 --arm m1unfixed --seed 31337 --warmup 100 \
        --decaps-samples 25000 --keygen-samples 5000 --encaps-samples 5000 \
        --block-index 11 --block-count 12 --order-seed 20261016 \
        --raw $COLLECT/R08/r08-perf-m1unfixed-b12/r08-perf-m1unfixed-b12.csv \
        --meta $COLLECT/R08/r08-perf-m1unfixed-b12/r08-perf-m1unfixed-b12.meta
# ------------------------------ P2 M2（KyberSlash a621b8d 未修 / 272125f 已修） ------------------------------
mkdir -p $COLLECT/R08/r08-perf-m2unfixed-b1
sudo -n /usr/bin/python3 -I -B $CONTROL/controller.py run \
    --control-root $CONTROL --run-name r08-perf-m2unfixed-b1 --cpu 2 --timeout-seconds 600 \
    --plan $PLAN --plan-sha256 $PLAN_SHA \
    -- $R08/build/m2unfixed/perf_measure \
        --run-id r08-perf-m2unfixed-b1 --arm m2unfixed --seed 31337 --warmup 100 \
        --decaps-samples 25000 --keygen-samples 5000 --encaps-samples 5000 \
        --block-index 0 --block-count 12 --order-seed 20261016 \
        --raw $COLLECT/R08/r08-perf-m2unfixed-b1/r08-perf-m2unfixed-b1.csv \
        --meta $COLLECT/R08/r08-perf-m2unfixed-b1/r08-perf-m2unfixed-b1.meta
mkdir -p $COLLECT/R08/r08-perf-m2fixed-b2
sudo -n /usr/bin/python3 -I -B $CONTROL/controller.py run \
    --control-root $CONTROL --run-name r08-perf-m2fixed-b2 --cpu 2 --timeout-seconds 600 \
    --plan $PLAN --plan-sha256 $PLAN_SHA \
    -- $R08/build/m2fixed/perf_measure \
        --run-id r08-perf-m2fixed-b2 --arm m2fixed --seed 31337 --warmup 100 \
        --decaps-samples 25000 --keygen-samples 5000 --encaps-samples 5000 \
        --block-index 1 --block-count 12 --order-seed 20261016 \
        --raw $COLLECT/R08/r08-perf-m2fixed-b2/r08-perf-m2fixed-b2.csv \
        --meta $COLLECT/R08/r08-perf-m2fixed-b2/r08-perf-m2fixed-b2.meta
mkdir -p $COLLECT/R08/r08-perf-m2fixed-b3
sudo -n /usr/bin/python3 -I -B $CONTROL/controller.py run \
    --control-root $CONTROL --run-name r08-perf-m2fixed-b3 --cpu 2 --timeout-seconds 600 \
    --plan $PLAN --plan-sha256 $PLAN_SHA \
    -- $R08/build/m2fixed/perf_measure \
        --run-id r08-perf-m2fixed-b3 --arm m2fixed --seed 31337 --warmup 100 \
        --decaps-samples 25000 --keygen-samples 5000 --encaps-samples 5000 \
        --block-index 2 --block-count 12 --order-seed 20261016 \
        --raw $COLLECT/R08/r08-perf-m2fixed-b3/r08-perf-m2fixed-b3.csv \
        --meta $COLLECT/R08/r08-perf-m2fixed-b3/r08-perf-m2fixed-b3.meta
mkdir -p $COLLECT/R08/r08-perf-m2unfixed-b4
sudo -n /usr/bin/python3 -I -B $CONTROL/controller.py run \
    --control-root $CONTROL --run-name r08-perf-m2unfixed-b4 --cpu 2 --timeout-seconds 600 \
    --plan $PLAN --plan-sha256 $PLAN_SHA \
    -- $R08/build/m2unfixed/perf_measure \
        --run-id r08-perf-m2unfixed-b4 --arm m2unfixed --seed 31337 --warmup 100 \
        --decaps-samples 25000 --keygen-samples 5000 --encaps-samples 5000 \
        --block-index 3 --block-count 12 --order-seed 20261016 \
        --raw $COLLECT/R08/r08-perf-m2unfixed-b4/r08-perf-m2unfixed-b4.csv \
        --meta $COLLECT/R08/r08-perf-m2unfixed-b4/r08-perf-m2unfixed-b4.meta
mkdir -p $COLLECT/R08/r08-perf-m2unfixed-b5
sudo -n /usr/bin/python3 -I -B $CONTROL/controller.py run \
    --control-root $CONTROL --run-name r08-perf-m2unfixed-b5 --cpu 2 --timeout-seconds 600 \
    --plan $PLAN --plan-sha256 $PLAN_SHA \
    -- $R08/build/m2unfixed/perf_measure \
        --run-id r08-perf-m2unfixed-b5 --arm m2unfixed --seed 31337 --warmup 100 \
        --decaps-samples 25000 --keygen-samples 5000 --encaps-samples 5000 \
        --block-index 4 --block-count 12 --order-seed 20261016 \
        --raw $COLLECT/R08/r08-perf-m2unfixed-b5/r08-perf-m2unfixed-b5.csv \
        --meta $COLLECT/R08/r08-perf-m2unfixed-b5/r08-perf-m2unfixed-b5.meta
mkdir -p $COLLECT/R08/r08-perf-m2fixed-b6
sudo -n /usr/bin/python3 -I -B $CONTROL/controller.py run \
    --control-root $CONTROL --run-name r08-perf-m2fixed-b6 --cpu 2 --timeout-seconds 600 \
    --plan $PLAN --plan-sha256 $PLAN_SHA \
    -- $R08/build/m2fixed/perf_measure \
        --run-id r08-perf-m2fixed-b6 --arm m2fixed --seed 31337 --warmup 100 \
        --decaps-samples 25000 --keygen-samples 5000 --encaps-samples 5000 \
        --block-index 5 --block-count 12 --order-seed 20261016 \
        --raw $COLLECT/R08/r08-perf-m2fixed-b6/r08-perf-m2fixed-b6.csv \
        --meta $COLLECT/R08/r08-perf-m2fixed-b6/r08-perf-m2fixed-b6.meta
mkdir -p $COLLECT/R08/r08-perf-m2fixed-b7
sudo -n /usr/bin/python3 -I -B $CONTROL/controller.py run \
    --control-root $CONTROL --run-name r08-perf-m2fixed-b7 --cpu 2 --timeout-seconds 600 \
    --plan $PLAN --plan-sha256 $PLAN_SHA \
    -- $R08/build/m2fixed/perf_measure \
        --run-id r08-perf-m2fixed-b7 --arm m2fixed --seed 31337 --warmup 100 \
        --decaps-samples 25000 --keygen-samples 5000 --encaps-samples 5000 \
        --block-index 6 --block-count 12 --order-seed 20261016 \
        --raw $COLLECT/R08/r08-perf-m2fixed-b7/r08-perf-m2fixed-b7.csv \
        --meta $COLLECT/R08/r08-perf-m2fixed-b7/r08-perf-m2fixed-b7.meta
mkdir -p $COLLECT/R08/r08-perf-m2unfixed-b8
sudo -n /usr/bin/python3 -I -B $CONTROL/controller.py run \
    --control-root $CONTROL --run-name r08-perf-m2unfixed-b8 --cpu 2 --timeout-seconds 600 \
    --plan $PLAN --plan-sha256 $PLAN_SHA \
    -- $R08/build/m2unfixed/perf_measure \
        --run-id r08-perf-m2unfixed-b8 --arm m2unfixed --seed 31337 --warmup 100 \
        --decaps-samples 25000 --keygen-samples 5000 --encaps-samples 5000 \
        --block-index 7 --block-count 12 --order-seed 20261016 \
        --raw $COLLECT/R08/r08-perf-m2unfixed-b8/r08-perf-m2unfixed-b8.csv \
        --meta $COLLECT/R08/r08-perf-m2unfixed-b8/r08-perf-m2unfixed-b8.meta
mkdir -p $COLLECT/R08/r08-perf-m2unfixed-b9
sudo -n /usr/bin/python3 -I -B $CONTROL/controller.py run \
    --control-root $CONTROL --run-name r08-perf-m2unfixed-b9 --cpu 2 --timeout-seconds 600 \
    --plan $PLAN --plan-sha256 $PLAN_SHA \
    -- $R08/build/m2unfixed/perf_measure \
        --run-id r08-perf-m2unfixed-b9 --arm m2unfixed --seed 31337 --warmup 100 \
        --decaps-samples 25000 --keygen-samples 5000 --encaps-samples 5000 \
        --block-index 8 --block-count 12 --order-seed 20261016 \
        --raw $COLLECT/R08/r08-perf-m2unfixed-b9/r08-perf-m2unfixed-b9.csv \
        --meta $COLLECT/R08/r08-perf-m2unfixed-b9/r08-perf-m2unfixed-b9.meta
mkdir -p $COLLECT/R08/r08-perf-m2fixed-b10
sudo -n /usr/bin/python3 -I -B $CONTROL/controller.py run \
    --control-root $CONTROL --run-name r08-perf-m2fixed-b10 --cpu 2 --timeout-seconds 600 \
    --plan $PLAN --plan-sha256 $PLAN_SHA \
    -- $R08/build/m2fixed/perf_measure \
        --run-id r08-perf-m2fixed-b10 --arm m2fixed --seed 31337 --warmup 100 \
        --decaps-samples 25000 --keygen-samples 5000 --encaps-samples 5000 \
        --block-index 9 --block-count 12 --order-seed 20261016 \
        --raw $COLLECT/R08/r08-perf-m2fixed-b10/r08-perf-m2fixed-b10.csv \
        --meta $COLLECT/R08/r08-perf-m2fixed-b10/r08-perf-m2fixed-b10.meta
mkdir -p $COLLECT/R08/r08-perf-m2fixed-b11
sudo -n /usr/bin/python3 -I -B $CONTROL/controller.py run \
    --control-root $CONTROL --run-name r08-perf-m2fixed-b11 --cpu 2 --timeout-seconds 600 \
    --plan $PLAN --plan-sha256 $PLAN_SHA \
    -- $R08/build/m2fixed/perf_measure \
        --run-id r08-perf-m2fixed-b11 --arm m2fixed --seed 31337 --warmup 100 \
        --decaps-samples 25000 --keygen-samples 5000 --encaps-samples 5000 \
        --block-index 10 --block-count 12 --order-seed 20261016 \
        --raw $COLLECT/R08/r08-perf-m2fixed-b11/r08-perf-m2fixed-b11.csv \
        --meta $COLLECT/R08/r08-perf-m2fixed-b11/r08-perf-m2fixed-b11.meta
mkdir -p $COLLECT/R08/r08-perf-m2unfixed-b12
sudo -n /usr/bin/python3 -I -B $CONTROL/controller.py run \
    --control-root $CONTROL --run-name r08-perf-m2unfixed-b12 --cpu 2 --timeout-seconds 600 \
    --plan $PLAN --plan-sha256 $PLAN_SHA \
    -- $R08/build/m2unfixed/perf_measure \
        --run-id r08-perf-m2unfixed-b12 --arm m2unfixed --seed 31337 --warmup 100 \
        --decaps-samples 25000 --keygen-samples 5000 --encaps-samples 5000 \
        --block-index 11 --block-count 12 --order-seed 20261016 \
        --raw $COLLECT/R08/r08-perf-m2unfixed-b12/r08-perf-m2unfixed-b12.csv \
        --meta $COLLECT/R08/r08-perf-m2unfixed-b12/r08-perf-m2unfixed-b12.meta
# ------------------------------ P3 M3（内存访问变体 开 / 关） ------------------------------
mkdir -p $COLLECT/R08/r08-perf-m3on-b1
sudo -n /usr/bin/python3 -I -B $CONTROL/controller.py run \
    --control-root $CONTROL --run-name r08-perf-m3on-b1 --cpu 2 --timeout-seconds 600 \
    --plan $PLAN --plan-sha256 $PLAN_SHA \
    -- $R08/build/m3on/perf_measure \
        --run-id r08-perf-m3on-b1 --arm m3on --seed 31337 --warmup 100 \
        --decaps-samples 25000 --keygen-samples 5000 --encaps-samples 5000 \
        --block-index 0 --block-count 12 --order-seed 20261016 \
        --raw $COLLECT/R08/r08-perf-m3on-b1/r08-perf-m3on-b1.csv \
        --meta $COLLECT/R08/r08-perf-m3on-b1/r08-perf-m3on-b1.meta
mkdir -p $COLLECT/R08/r08-perf-m3off-b2
sudo -n /usr/bin/python3 -I -B $CONTROL/controller.py run \
    --control-root $CONTROL --run-name r08-perf-m3off-b2 --cpu 2 --timeout-seconds 600 \
    --plan $PLAN --plan-sha256 $PLAN_SHA \
    -- $R08/build/m3off/perf_measure \
        --run-id r08-perf-m3off-b2 --arm m3off --seed 31337 --warmup 100 \
        --decaps-samples 25000 --keygen-samples 5000 --encaps-samples 5000 \
        --block-index 1 --block-count 12 --order-seed 20261016 \
        --raw $COLLECT/R08/r08-perf-m3off-b2/r08-perf-m3off-b2.csv \
        --meta $COLLECT/R08/r08-perf-m3off-b2/r08-perf-m3off-b2.meta
mkdir -p $COLLECT/R08/r08-perf-m3off-b3
sudo -n /usr/bin/python3 -I -B $CONTROL/controller.py run \
    --control-root $CONTROL --run-name r08-perf-m3off-b3 --cpu 2 --timeout-seconds 600 \
    --plan $PLAN --plan-sha256 $PLAN_SHA \
    -- $R08/build/m3off/perf_measure \
        --run-id r08-perf-m3off-b3 --arm m3off --seed 31337 --warmup 100 \
        --decaps-samples 25000 --keygen-samples 5000 --encaps-samples 5000 \
        --block-index 2 --block-count 12 --order-seed 20261016 \
        --raw $COLLECT/R08/r08-perf-m3off-b3/r08-perf-m3off-b3.csv \
        --meta $COLLECT/R08/r08-perf-m3off-b3/r08-perf-m3off-b3.meta
mkdir -p $COLLECT/R08/r08-perf-m3on-b4
sudo -n /usr/bin/python3 -I -B $CONTROL/controller.py run \
    --control-root $CONTROL --run-name r08-perf-m3on-b4 --cpu 2 --timeout-seconds 600 \
    --plan $PLAN --plan-sha256 $PLAN_SHA \
    -- $R08/build/m3on/perf_measure \
        --run-id r08-perf-m3on-b4 --arm m3on --seed 31337 --warmup 100 \
        --decaps-samples 25000 --keygen-samples 5000 --encaps-samples 5000 \
        --block-index 3 --block-count 12 --order-seed 20261016 \
        --raw $COLLECT/R08/r08-perf-m3on-b4/r08-perf-m3on-b4.csv \
        --meta $COLLECT/R08/r08-perf-m3on-b4/r08-perf-m3on-b4.meta
mkdir -p $COLLECT/R08/r08-perf-m3on-b5
sudo -n /usr/bin/python3 -I -B $CONTROL/controller.py run \
    --control-root $CONTROL --run-name r08-perf-m3on-b5 --cpu 2 --timeout-seconds 600 \
    --plan $PLAN --plan-sha256 $PLAN_SHA \
    -- $R08/build/m3on/perf_measure \
        --run-id r08-perf-m3on-b5 --arm m3on --seed 31337 --warmup 100 \
        --decaps-samples 25000 --keygen-samples 5000 --encaps-samples 5000 \
        --block-index 4 --block-count 12 --order-seed 20261016 \
        --raw $COLLECT/R08/r08-perf-m3on-b5/r08-perf-m3on-b5.csv \
        --meta $COLLECT/R08/r08-perf-m3on-b5/r08-perf-m3on-b5.meta
mkdir -p $COLLECT/R08/r08-perf-m3off-b6
sudo -n /usr/bin/python3 -I -B $CONTROL/controller.py run \
    --control-root $CONTROL --run-name r08-perf-m3off-b6 --cpu 2 --timeout-seconds 600 \
    --plan $PLAN --plan-sha256 $PLAN_SHA \
    -- $R08/build/m3off/perf_measure \
        --run-id r08-perf-m3off-b6 --arm m3off --seed 31337 --warmup 100 \
        --decaps-samples 25000 --keygen-samples 5000 --encaps-samples 5000 \
        --block-index 5 --block-count 12 --order-seed 20261016 \
        --raw $COLLECT/R08/r08-perf-m3off-b6/r08-perf-m3off-b6.csv \
        --meta $COLLECT/R08/r08-perf-m3off-b6/r08-perf-m3off-b6.meta
mkdir -p $COLLECT/R08/r08-perf-m3off-b7
sudo -n /usr/bin/python3 -I -B $CONTROL/controller.py run \
    --control-root $CONTROL --run-name r08-perf-m3off-b7 --cpu 2 --timeout-seconds 600 \
    --plan $PLAN --plan-sha256 $PLAN_SHA \
    -- $R08/build/m3off/perf_measure \
        --run-id r08-perf-m3off-b7 --arm m3off --seed 31337 --warmup 100 \
        --decaps-samples 25000 --keygen-samples 5000 --encaps-samples 5000 \
        --block-index 6 --block-count 12 --order-seed 20261016 \
        --raw $COLLECT/R08/r08-perf-m3off-b7/r08-perf-m3off-b7.csv \
        --meta $COLLECT/R08/r08-perf-m3off-b7/r08-perf-m3off-b7.meta
mkdir -p $COLLECT/R08/r08-perf-m3on-b8
sudo -n /usr/bin/python3 -I -B $CONTROL/controller.py run \
    --control-root $CONTROL --run-name r08-perf-m3on-b8 --cpu 2 --timeout-seconds 600 \
    --plan $PLAN --plan-sha256 $PLAN_SHA \
    -- $R08/build/m3on/perf_measure \
        --run-id r08-perf-m3on-b8 --arm m3on --seed 31337 --warmup 100 \
        --decaps-samples 25000 --keygen-samples 5000 --encaps-samples 5000 \
        --block-index 7 --block-count 12 --order-seed 20261016 \
        --raw $COLLECT/R08/r08-perf-m3on-b8/r08-perf-m3on-b8.csv \
        --meta $COLLECT/R08/r08-perf-m3on-b8/r08-perf-m3on-b8.meta
mkdir -p $COLLECT/R08/r08-perf-m3on-b9
sudo -n /usr/bin/python3 -I -B $CONTROL/controller.py run \
    --control-root $CONTROL --run-name r08-perf-m3on-b9 --cpu 2 --timeout-seconds 600 \
    --plan $PLAN --plan-sha256 $PLAN_SHA \
    -- $R08/build/m3on/perf_measure \
        --run-id r08-perf-m3on-b9 --arm m3on --seed 31337 --warmup 100 \
        --decaps-samples 25000 --keygen-samples 5000 --encaps-samples 5000 \
        --block-index 8 --block-count 12 --order-seed 20261016 \
        --raw $COLLECT/R08/r08-perf-m3on-b9/r08-perf-m3on-b9.csv \
        --meta $COLLECT/R08/r08-perf-m3on-b9/r08-perf-m3on-b9.meta
mkdir -p $COLLECT/R08/r08-perf-m3off-b10
sudo -n /usr/bin/python3 -I -B $CONTROL/controller.py run \
    --control-root $CONTROL --run-name r08-perf-m3off-b10 --cpu 2 --timeout-seconds 600 \
    --plan $PLAN --plan-sha256 $PLAN_SHA \
    -- $R08/build/m3off/perf_measure \
        --run-id r08-perf-m3off-b10 --arm m3off --seed 31337 --warmup 100 \
        --decaps-samples 25000 --keygen-samples 5000 --encaps-samples 5000 \
        --block-index 9 --block-count 12 --order-seed 20261016 \
        --raw $COLLECT/R08/r08-perf-m3off-b10/r08-perf-m3off-b10.csv \
        --meta $COLLECT/R08/r08-perf-m3off-b10/r08-perf-m3off-b10.meta
mkdir -p $COLLECT/R08/r08-perf-m3off-b11
sudo -n /usr/bin/python3 -I -B $CONTROL/controller.py run \
    --control-root $CONTROL --run-name r08-perf-m3off-b11 --cpu 2 --timeout-seconds 600 \
    --plan $PLAN --plan-sha256 $PLAN_SHA \
    -- $R08/build/m3off/perf_measure \
        --run-id r08-perf-m3off-b11 --arm m3off --seed 31337 --warmup 100 \
        --decaps-samples 25000 --keygen-samples 5000 --encaps-samples 5000 \
        --block-index 10 --block-count 12 --order-seed 20261016 \
        --raw $COLLECT/R08/r08-perf-m3off-b11/r08-perf-m3off-b11.csv \
        --meta $COLLECT/R08/r08-perf-m3off-b11/r08-perf-m3off-b11.meta
mkdir -p $COLLECT/R08/r08-perf-m3on-b12
sudo -n /usr/bin/python3 -I -B $CONTROL/controller.py run \
    --control-root $CONTROL --run-name r08-perf-m3on-b12 --cpu 2 --timeout-seconds 600 \
    --plan $PLAN --plan-sha256 $PLAN_SHA \
    -- $R08/build/m3on/perf_measure \
        --run-id r08-perf-m3on-b12 --arm m3on --seed 31337 --warmup 100 \
        --decaps-samples 25000 --keygen-samples 5000 --encaps-samples 5000 \
        --block-index 11 --block-count 12 --order-seed 20261016 \
        --raw $COLLECT/R08/r08-perf-m3on-b12/r08-perf-m3on-b12.csv \
        --meta $COLLECT/R08/r08-perf-m3on-b12/r08-perf-m3on-b12.meta
# ------------------------------ P4 M4（早退比较夹具 vulnerable / ct；窗口只包比较步） ------------------------------
mkdir -p $COLLECT/R08/r08-perf-m4vul-b1
sudo -n /usr/bin/python3 -I -B $CONTROL/controller.py run \
    --control-root $CONTROL --run-name r08-perf-m4vul-b1 --cpu 2 --timeout-seconds 600 \
    --plan $PLAN --plan-sha256 $PLAN_SHA \
    -- /home/nss-marker/yhr/Cry/platform-m4-20261016-6hRHRUxH/build-software-v3/platform_m4_measure_vulnerable \
        --collect $COLLECT/R08/r08-perf-m4vul-b1/m4-vulnerable.csv 20000 31337 r08-perf-m4vul-b1 --compare-bytes 32
mkdir -p $COLLECT/R08/r08-perf-m4ct-b2
sudo -n /usr/bin/python3 -I -B $CONTROL/controller.py run \
    --control-root $CONTROL --run-name r08-perf-m4ct-b2 --cpu 2 --timeout-seconds 600 \
    --plan $PLAN --plan-sha256 $PLAN_SHA \
    -- /home/nss-marker/yhr/Cry/platform-m4-20261016-6hRHRUxH/build-software-v3/platform_m4_measure_ct \
        --collect $COLLECT/R08/r08-perf-m4ct-b2/m4-ct.csv 20000 31337 r08-perf-m4ct-b2 --compare-bytes 32
mkdir -p $COLLECT/R08/r08-perf-m4ct-b3
sudo -n /usr/bin/python3 -I -B $CONTROL/controller.py run \
    --control-root $CONTROL --run-name r08-perf-m4ct-b3 --cpu 2 --timeout-seconds 600 \
    --plan $PLAN --plan-sha256 $PLAN_SHA \
    -- /home/nss-marker/yhr/Cry/platform-m4-20261016-6hRHRUxH/build-software-v3/platform_m4_measure_ct \
        --collect $COLLECT/R08/r08-perf-m4ct-b3/m4-ct.csv 20000 31337 r08-perf-m4ct-b3 --compare-bytes 32
mkdir -p $COLLECT/R08/r08-perf-m4vul-b4
sudo -n /usr/bin/python3 -I -B $CONTROL/controller.py run \
    --control-root $CONTROL --run-name r08-perf-m4vul-b4 --cpu 2 --timeout-seconds 600 \
    --plan $PLAN --plan-sha256 $PLAN_SHA \
    -- /home/nss-marker/yhr/Cry/platform-m4-20261016-6hRHRUxH/build-software-v3/platform_m4_measure_vulnerable \
        --collect $COLLECT/R08/r08-perf-m4vul-b4/m4-vulnerable.csv 20000 31337 r08-perf-m4vul-b4 --compare-bytes 32
mkdir -p $COLLECT/R08/r08-perf-m4vul-b5
sudo -n /usr/bin/python3 -I -B $CONTROL/controller.py run \
    --control-root $CONTROL --run-name r08-perf-m4vul-b5 --cpu 2 --timeout-seconds 600 \
    --plan $PLAN --plan-sha256 $PLAN_SHA \
    -- /home/nss-marker/yhr/Cry/platform-m4-20261016-6hRHRUxH/build-software-v3/platform_m4_measure_vulnerable \
        --collect $COLLECT/R08/r08-perf-m4vul-b5/m4-vulnerable.csv 20000 31337 r08-perf-m4vul-b5 --compare-bytes 32
mkdir -p $COLLECT/R08/r08-perf-m4ct-b6
sudo -n /usr/bin/python3 -I -B $CONTROL/controller.py run \
    --control-root $CONTROL --run-name r08-perf-m4ct-b6 --cpu 2 --timeout-seconds 600 \
    --plan $PLAN --plan-sha256 $PLAN_SHA \
    -- /home/nss-marker/yhr/Cry/platform-m4-20261016-6hRHRUxH/build-software-v3/platform_m4_measure_ct \
        --collect $COLLECT/R08/r08-perf-m4ct-b6/m4-ct.csv 20000 31337 r08-perf-m4ct-b6 --compare-bytes 32
mkdir -p $COLLECT/R08/r08-perf-m4ct-b7
sudo -n /usr/bin/python3 -I -B $CONTROL/controller.py run \
    --control-root $CONTROL --run-name r08-perf-m4ct-b7 --cpu 2 --timeout-seconds 600 \
    --plan $PLAN --plan-sha256 $PLAN_SHA \
    -- /home/nss-marker/yhr/Cry/platform-m4-20261016-6hRHRUxH/build-software-v3/platform_m4_measure_ct \
        --collect $COLLECT/R08/r08-perf-m4ct-b7/m4-ct.csv 20000 31337 r08-perf-m4ct-b7 --compare-bytes 32
mkdir -p $COLLECT/R08/r08-perf-m4vul-b8
sudo -n /usr/bin/python3 -I -B $CONTROL/controller.py run \
    --control-root $CONTROL --run-name r08-perf-m4vul-b8 --cpu 2 --timeout-seconds 600 \
    --plan $PLAN --plan-sha256 $PLAN_SHA \
    -- /home/nss-marker/yhr/Cry/platform-m4-20261016-6hRHRUxH/build-software-v3/platform_m4_measure_vulnerable \
        --collect $COLLECT/R08/r08-perf-m4vul-b8/m4-vulnerable.csv 20000 31337 r08-perf-m4vul-b8 --compare-bytes 32
mkdir -p $COLLECT/R08/r08-perf-m4vul-b9
sudo -n /usr/bin/python3 -I -B $CONTROL/controller.py run \
    --control-root $CONTROL --run-name r08-perf-m4vul-b9 --cpu 2 --timeout-seconds 600 \
    --plan $PLAN --plan-sha256 $PLAN_SHA \
    -- /home/nss-marker/yhr/Cry/platform-m4-20261016-6hRHRUxH/build-software-v3/platform_m4_measure_vulnerable \
        --collect $COLLECT/R08/r08-perf-m4vul-b9/m4-vulnerable.csv 20000 31337 r08-perf-m4vul-b9 --compare-bytes 32
mkdir -p $COLLECT/R08/r08-perf-m4ct-b10
sudo -n /usr/bin/python3 -I -B $CONTROL/controller.py run \
    --control-root $CONTROL --run-name r08-perf-m4ct-b10 --cpu 2 --timeout-seconds 600 \
    --plan $PLAN --plan-sha256 $PLAN_SHA \
    -- /home/nss-marker/yhr/Cry/platform-m4-20261016-6hRHRUxH/build-software-v3/platform_m4_measure_ct \
        --collect $COLLECT/R08/r08-perf-m4ct-b10/m4-ct.csv 20000 31337 r08-perf-m4ct-b10 --compare-bytes 32
mkdir -p $COLLECT/R08/r08-perf-m4ct-b11
sudo -n /usr/bin/python3 -I -B $CONTROL/controller.py run \
    --control-root $CONTROL --run-name r08-perf-m4ct-b11 --cpu 2 --timeout-seconds 600 \
    --plan $PLAN --plan-sha256 $PLAN_SHA \
    -- /home/nss-marker/yhr/Cry/platform-m4-20261016-6hRHRUxH/build-software-v3/platform_m4_measure_ct \
        --collect $COLLECT/R08/r08-perf-m4ct-b11/m4-ct.csv 20000 31337 r08-perf-m4ct-b11 --compare-bytes 32
mkdir -p $COLLECT/R08/r08-perf-m4vul-b12
sudo -n /usr/bin/python3 -I -B $CONTROL/controller.py run \
    --control-root $CONTROL --run-name r08-perf-m4vul-b12 --cpu 2 --timeout-seconds 600 \
    --plan $PLAN --plan-sha256 $PLAN_SHA \
    -- /home/nss-marker/yhr/Cry/platform-m4-20261016-6hRHRUxH/build-software-v3/platform_m4_measure_vulnerable \
        --collect $COLLECT/R08/r08-perf-m4vul-b12/m4-vulnerable.csv 20000 31337 r08-perf-m4vul-b12 --compare-bytes 32
# ------------------------------ P5 M5（mlkem-native b3ba7b3 reference，单臂 6 块） ------------------------------
mkdir -p $COLLECT/R08/r08-perf-m5ref-b1
sudo -n /usr/bin/python3 -I -B $CONTROL/controller.py run \
    --control-root $CONTROL --run-name r08-perf-m5ref-b1 --cpu 2 --timeout-seconds 600 \
    --plan $PLAN --plan-sha256 $PLAN_SHA \
    -- $R08/build/m5ref/perf_measure \
        --run-id r08-perf-m5ref-b1 --arm m5ref --seed 31337 --warmup 100 \
        --decaps-samples 25000 --keygen-samples 5000 --encaps-samples 5000 \
        --block-index 0 --block-count 12 --order-seed 20261016 \
        --raw $COLLECT/R08/r08-perf-m5ref-b1/r08-perf-m5ref-b1.csv \
        --meta $COLLECT/R08/r08-perf-m5ref-b1/r08-perf-m5ref-b1.meta
mkdir -p $COLLECT/R08/r08-perf-m5ref-b2
sudo -n /usr/bin/python3 -I -B $CONTROL/controller.py run \
    --control-root $CONTROL --run-name r08-perf-m5ref-b2 --cpu 2 --timeout-seconds 600 \
    --plan $PLAN --plan-sha256 $PLAN_SHA \
    -- $R08/build/m5ref/perf_measure \
        --run-id r08-perf-m5ref-b2 --arm m5ref --seed 31337 --warmup 100 \
        --decaps-samples 25000 --keygen-samples 5000 --encaps-samples 5000 \
        --block-index 1 --block-count 12 --order-seed 20261016 \
        --raw $COLLECT/R08/r08-perf-m5ref-b2/r08-perf-m5ref-b2.csv \
        --meta $COLLECT/R08/r08-perf-m5ref-b2/r08-perf-m5ref-b2.meta
mkdir -p $COLLECT/R08/r08-perf-m5ref-b3
sudo -n /usr/bin/python3 -I -B $CONTROL/controller.py run \
    --control-root $CONTROL --run-name r08-perf-m5ref-b3 --cpu 2 --timeout-seconds 600 \
    --plan $PLAN --plan-sha256 $PLAN_SHA \
    -- $R08/build/m5ref/perf_measure \
        --run-id r08-perf-m5ref-b3 --arm m5ref --seed 31337 --warmup 100 \
        --decaps-samples 25000 --keygen-samples 5000 --encaps-samples 5000 \
        --block-index 2 --block-count 12 --order-seed 20261016 \
        --raw $COLLECT/R08/r08-perf-m5ref-b3/r08-perf-m5ref-b3.csv \
        --meta $COLLECT/R08/r08-perf-m5ref-b3/r08-perf-m5ref-b3.meta
mkdir -p $COLLECT/R08/r08-perf-m5ref-b4
sudo -n /usr/bin/python3 -I -B $CONTROL/controller.py run \
    --control-root $CONTROL --run-name r08-perf-m5ref-b4 --cpu 2 --timeout-seconds 600 \
    --plan $PLAN --plan-sha256 $PLAN_SHA \
    -- $R08/build/m5ref/perf_measure \
        --run-id r08-perf-m5ref-b4 --arm m5ref --seed 31337 --warmup 100 \
        --decaps-samples 25000 --keygen-samples 5000 --encaps-samples 5000 \
        --block-index 3 --block-count 12 --order-seed 20261016 \
        --raw $COLLECT/R08/r08-perf-m5ref-b4/r08-perf-m5ref-b4.csv \
        --meta $COLLECT/R08/r08-perf-m5ref-b4/r08-perf-m5ref-b4.meta
mkdir -p $COLLECT/R08/r08-perf-m5ref-b5
sudo -n /usr/bin/python3 -I -B $CONTROL/controller.py run \
    --control-root $CONTROL --run-name r08-perf-m5ref-b5 --cpu 2 --timeout-seconds 600 \
    --plan $PLAN --plan-sha256 $PLAN_SHA \
    -- $R08/build/m5ref/perf_measure \
        --run-id r08-perf-m5ref-b5 --arm m5ref --seed 31337 --warmup 100 \
        --decaps-samples 25000 --keygen-samples 5000 --encaps-samples 5000 \
        --block-index 4 --block-count 12 --order-seed 20261016 \
        --raw $COLLECT/R08/r08-perf-m5ref-b5/r08-perf-m5ref-b5.csv \
        --meta $COLLECT/R08/r08-perf-m5ref-b5/r08-perf-m5ref-b5.meta
mkdir -p $COLLECT/R08/r08-perf-m5ref-b6
sudo -n /usr/bin/python3 -I -B $CONTROL/controller.py run \
    --control-root $CONTROL --run-name r08-perf-m5ref-b6 --cpu 2 --timeout-seconds 600 \
    --plan $PLAN --plan-sha256 $PLAN_SHA \
    -- $R08/build/m5ref/perf_measure \
        --run-id r08-perf-m5ref-b6 --arm m5ref --seed 31337 --warmup 100 \
        --decaps-samples 25000 --keygen-samples 5000 --encaps-samples 5000 \
        --block-index 5 --block-count 12 --order-seed 20261016 \
        --raw $COLLECT/R08/r08-perf-m5ref-b6/r08-perf-m5ref-b6.csv \
        --meta $COLLECT/R08/r08-perf-m5ref-b6/r08-perf-m5ref-b6.meta
# ------------------------------ 采集后只读核对（不需要 sudo） ------------------------------
# 逐 run 检查判据与 CSV/meta 一致性：
#   for run in $(grep -o 'r08-perf-[a-z0-9-]*' "$0" | sort -u); do
#       d=$COLLECT/R08/$run
#       printf '%s ' "$run"
#       python3 -c "import json,sys;t=json.load(open('$d/controller/terminal.json'));print(t.get('reason'),t.get('worker_exit_code'),t.get('worker_drained'),t.get('restore_match'))"
#   done
# 期望每一行都是：worker_finished 0 True yes
# CSV 解析（自带解析；--format measure 也能读，但性能表用逐操作分位数，见 PLAN §3.2）：
#   awk -F, 'NR>1{n[$3]++;s[$3]+=$5} END{for(k in n) printf "%s n=%d mean_ns=%.1f\n",k,n[k],s[k]/n[k]}' \
#       $COLLECT/R08/r08-perf-m5ref-b1/r08-perf-m5ref-b1.csv
