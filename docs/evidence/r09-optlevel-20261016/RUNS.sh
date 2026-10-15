#!/bin/sh
# R09 优化级别锁频计时：36 条控制器命令。**本文件不被自动执行**，由主控串行逐条复制执行。
#
# 合同见 docs/evidence/r09-optlevel-20261016/PLAN.md（本文件只给可直接复制的命令与判据）。
#   - 12 格 = m1unfixed / m1fixed / m5ref 三个臂 × -O0 / -O2 / -O3 / -Os 四个级别，每格 3 次运行
#   - 每格主类对 message-zero vs message-ones 各 10000 次；`--samples 10000` 是**每类**次数，
#     一次运行同时采 5 类（valid/bit-flipped/random/message-zero/message-ones）各 10000 次
#   - 种子：s1=31337（CPU2）、s2=424242（CPU2）、s3=7（CPU6）
#   - 有效判据：terminal.json 的 reason=worker_finished、worker_exit_code=0、
#     worker_drained=true、restore_match=yes **同时**成立；restore_match=yes 才算有效
#   - CSV 与冻结 --format measure 同形，可直接：
#       scripts/run_stats_battery.sh --input <csv> --format measure \
#           --classes message-zero message-ones --output-dir <新目录> --stats-bin <platform_stats>
#
# 执行前必须做两件事：
#   1) 上传 PLAN 并核对摘要（必须逐字等于下面的 PLAN_SHA）：
#        sha256sum /home/nss-marker/yhr/Cry/platform-collect-20261016-c011ec7a5e01/plans/r09-optlevel-PLAN.md
#   2) 确认控制根存在、controller.py 摘要为
#        4a0cf57a00c6802ff86ed410d2518bc56cc8e694422cbc4ea7a24a3f1cdd701
#      （若主控本轮另建控制根，把下面的 CONTROL 换成主控给的路径即可，其余不变）
#
# 失败处理：任一 run 判据不成立时立即停止后续采集，把该 run 目录整体归档到
#   /home/nss-marker/yhr/Cry/r09-optlevel-20261016-85e46c952887/failed/<run-name>-attempt<n>/ ，换新 run-name（-a2/-a3）重跑；
#   失败运行不计入结果，也不从记录里消失。

COLLECT=/home/nss-marker/yhr/Cry/platform-collect-20261016-c011ec7a5e01
CONTROL=/home/nss-marker/yhr/Cry/platform-control-20261016-53929b406f0d
PLAN=$COLLECT/plans/r09-optlevel-PLAN.md
PLAN_SHA=0106ee30d1512705f64d7ad7e64df9bd20a0ad1df6e3be5de92dc799291512a7
R09=/home/nss-marker/yhr/Cry/r09-optlevel-20261016-85e46c952887

# ------------------------------ m1unfixed-O0 : M1 未修（liboqs 0.10.0 historical-clangover） ------------------------------
mkdir -p $COLLECT/R09/r09-o0-m1unfixed-s1
sudo -n /usr/bin/python3 -I -B $CONTROL/controller.py run \
    --control-root $CONTROL --run-name r09-o0-m1unfixed-s1 --cpu 2 --timeout-seconds 900 \
    --plan $PLAN --plan-sha256 $PLAN_SHA \
    -- $R09/build/m1unfixed-O0/measure \
        r09-o0-m1unfixed-s1 31337 10000 $COLLECT/R09/r09-o0-m1unfixed-s1/r09-o0-m1unfixed-s1.csv $COLLECT/R09/r09-o0-m1unfixed-s1/r09-o0-m1unfixed-s1.meta
mkdir -p $COLLECT/R09/r09-o0-m1unfixed-s2
sudo -n /usr/bin/python3 -I -B $CONTROL/controller.py run \
    --control-root $CONTROL --run-name r09-o0-m1unfixed-s2 --cpu 2 --timeout-seconds 900 \
    --plan $PLAN --plan-sha256 $PLAN_SHA \
    -- $R09/build/m1unfixed-O0/measure \
        r09-o0-m1unfixed-s2 424242 10000 $COLLECT/R09/r09-o0-m1unfixed-s2/r09-o0-m1unfixed-s2.csv $COLLECT/R09/r09-o0-m1unfixed-s2/r09-o0-m1unfixed-s2.meta
mkdir -p $COLLECT/R09/r09-o0-m1unfixed-s3
sudo -n /usr/bin/python3 -I -B $CONTROL/controller.py run \
    --control-root $CONTROL --run-name r09-o0-m1unfixed-s3 --cpu 6 --timeout-seconds 900 \
    --plan $PLAN --plan-sha256 $PLAN_SHA \
    -- $R09/build/m1unfixed-O0/measure \
        r09-o0-m1unfixed-s3 7 10000 $COLLECT/R09/r09-o0-m1unfixed-s3/r09-o0-m1unfixed-s3.csv $COLLECT/R09/r09-o0-m1unfixed-s3/r09-o0-m1unfixed-s3.meta
# ------------------------------ m1fixed-O0 : M1 已修（+982c762） ------------------------------
mkdir -p $COLLECT/R09/r09-o0-m1fixed-s1
sudo -n /usr/bin/python3 -I -B $CONTROL/controller.py run \
    --control-root $CONTROL --run-name r09-o0-m1fixed-s1 --cpu 2 --timeout-seconds 900 \
    --plan $PLAN --plan-sha256 $PLAN_SHA \
    -- $R09/build/m1fixed-O0/measure \
        r09-o0-m1fixed-s1 31337 10000 $COLLECT/R09/r09-o0-m1fixed-s1/r09-o0-m1fixed-s1.csv $COLLECT/R09/r09-o0-m1fixed-s1/r09-o0-m1fixed-s1.meta
mkdir -p $COLLECT/R09/r09-o0-m1fixed-s2
sudo -n /usr/bin/python3 -I -B $CONTROL/controller.py run \
    --control-root $CONTROL --run-name r09-o0-m1fixed-s2 --cpu 2 --timeout-seconds 900 \
    --plan $PLAN --plan-sha256 $PLAN_SHA \
    -- $R09/build/m1fixed-O0/measure \
        r09-o0-m1fixed-s2 424242 10000 $COLLECT/R09/r09-o0-m1fixed-s2/r09-o0-m1fixed-s2.csv $COLLECT/R09/r09-o0-m1fixed-s2/r09-o0-m1fixed-s2.meta
mkdir -p $COLLECT/R09/r09-o0-m1fixed-s3
sudo -n /usr/bin/python3 -I -B $CONTROL/controller.py run \
    --control-root $CONTROL --run-name r09-o0-m1fixed-s3 --cpu 6 --timeout-seconds 900 \
    --plan $PLAN --plan-sha256 $PLAN_SHA \
    -- $R09/build/m1fixed-O0/measure \
        r09-o0-m1fixed-s3 7 10000 $COLLECT/R09/r09-o0-m1fixed-s3/r09-o0-m1fixed-s3.csv $COLLECT/R09/r09-o0-m1fixed-s3/r09-o0-m1fixed-s3.meta
# ------------------------------ m5ref-O0 : M5（mlkem-native b3ba7b3 portable reference） ------------------------------
mkdir -p $COLLECT/R09/r09-o0-m5ref-s1
sudo -n /usr/bin/python3 -I -B $CONTROL/controller.py run \
    --control-root $CONTROL --run-name r09-o0-m5ref-s1 --cpu 2 --timeout-seconds 900 \
    --plan $PLAN --plan-sha256 $PLAN_SHA \
    -- $R09/build/m5ref-O0/measure \
        r09-o0-m5ref-s1 31337 10000 $COLLECT/R09/r09-o0-m5ref-s1/r09-o0-m5ref-s1.csv $COLLECT/R09/r09-o0-m5ref-s1/r09-o0-m5ref-s1.meta
mkdir -p $COLLECT/R09/r09-o0-m5ref-s2
sudo -n /usr/bin/python3 -I -B $CONTROL/controller.py run \
    --control-root $CONTROL --run-name r09-o0-m5ref-s2 --cpu 2 --timeout-seconds 900 \
    --plan $PLAN --plan-sha256 $PLAN_SHA \
    -- $R09/build/m5ref-O0/measure \
        r09-o0-m5ref-s2 424242 10000 $COLLECT/R09/r09-o0-m5ref-s2/r09-o0-m5ref-s2.csv $COLLECT/R09/r09-o0-m5ref-s2/r09-o0-m5ref-s2.meta
mkdir -p $COLLECT/R09/r09-o0-m5ref-s3
sudo -n /usr/bin/python3 -I -B $CONTROL/controller.py run \
    --control-root $CONTROL --run-name r09-o0-m5ref-s3 --cpu 6 --timeout-seconds 900 \
    --plan $PLAN --plan-sha256 $PLAN_SHA \
    -- $R09/build/m5ref-O0/measure \
        r09-o0-m5ref-s3 7 10000 $COLLECT/R09/r09-o0-m5ref-s3/r09-o0-m5ref-s3.csv $COLLECT/R09/r09-o0-m5ref-s3/r09-o0-m5ref-s3.meta
# ------------------------------ m1unfixed-O2 : M1 未修（liboqs 0.10.0 historical-clangover） ------------------------------
mkdir -p $COLLECT/R09/r09-o2-m1unfixed-s1
sudo -n /usr/bin/python3 -I -B $CONTROL/controller.py run \
    --control-root $CONTROL --run-name r09-o2-m1unfixed-s1 --cpu 2 --timeout-seconds 900 \
    --plan $PLAN --plan-sha256 $PLAN_SHA \
    -- $R09/build/m1unfixed-O2/measure \
        r09-o2-m1unfixed-s1 31337 10000 $COLLECT/R09/r09-o2-m1unfixed-s1/r09-o2-m1unfixed-s1.csv $COLLECT/R09/r09-o2-m1unfixed-s1/r09-o2-m1unfixed-s1.meta
mkdir -p $COLLECT/R09/r09-o2-m1unfixed-s2
sudo -n /usr/bin/python3 -I -B $CONTROL/controller.py run \
    --control-root $CONTROL --run-name r09-o2-m1unfixed-s2 --cpu 2 --timeout-seconds 900 \
    --plan $PLAN --plan-sha256 $PLAN_SHA \
    -- $R09/build/m1unfixed-O2/measure \
        r09-o2-m1unfixed-s2 424242 10000 $COLLECT/R09/r09-o2-m1unfixed-s2/r09-o2-m1unfixed-s2.csv $COLLECT/R09/r09-o2-m1unfixed-s2/r09-o2-m1unfixed-s2.meta
mkdir -p $COLLECT/R09/r09-o2-m1unfixed-s3
sudo -n /usr/bin/python3 -I -B $CONTROL/controller.py run \
    --control-root $CONTROL --run-name r09-o2-m1unfixed-s3 --cpu 6 --timeout-seconds 900 \
    --plan $PLAN --plan-sha256 $PLAN_SHA \
    -- $R09/build/m1unfixed-O2/measure \
        r09-o2-m1unfixed-s3 7 10000 $COLLECT/R09/r09-o2-m1unfixed-s3/r09-o2-m1unfixed-s3.csv $COLLECT/R09/r09-o2-m1unfixed-s3/r09-o2-m1unfixed-s3.meta
# ------------------------------ m1fixed-O2 : M1 已修（+982c762） ------------------------------
mkdir -p $COLLECT/R09/r09-o2-m1fixed-s1
sudo -n /usr/bin/python3 -I -B $CONTROL/controller.py run \
    --control-root $CONTROL --run-name r09-o2-m1fixed-s1 --cpu 2 --timeout-seconds 900 \
    --plan $PLAN --plan-sha256 $PLAN_SHA \
    -- $R09/build/m1fixed-O2/measure \
        r09-o2-m1fixed-s1 31337 10000 $COLLECT/R09/r09-o2-m1fixed-s1/r09-o2-m1fixed-s1.csv $COLLECT/R09/r09-o2-m1fixed-s1/r09-o2-m1fixed-s1.meta
mkdir -p $COLLECT/R09/r09-o2-m1fixed-s2
sudo -n /usr/bin/python3 -I -B $CONTROL/controller.py run \
    --control-root $CONTROL --run-name r09-o2-m1fixed-s2 --cpu 2 --timeout-seconds 900 \
    --plan $PLAN --plan-sha256 $PLAN_SHA \
    -- $R09/build/m1fixed-O2/measure \
        r09-o2-m1fixed-s2 424242 10000 $COLLECT/R09/r09-o2-m1fixed-s2/r09-o2-m1fixed-s2.csv $COLLECT/R09/r09-o2-m1fixed-s2/r09-o2-m1fixed-s2.meta
mkdir -p $COLLECT/R09/r09-o2-m1fixed-s3
sudo -n /usr/bin/python3 -I -B $CONTROL/controller.py run \
    --control-root $CONTROL --run-name r09-o2-m1fixed-s3 --cpu 6 --timeout-seconds 900 \
    --plan $PLAN --plan-sha256 $PLAN_SHA \
    -- $R09/build/m1fixed-O2/measure \
        r09-o2-m1fixed-s3 7 10000 $COLLECT/R09/r09-o2-m1fixed-s3/r09-o2-m1fixed-s3.csv $COLLECT/R09/r09-o2-m1fixed-s3/r09-o2-m1fixed-s3.meta
# ------------------------------ m5ref-O2 : M5（mlkem-native b3ba7b3 portable reference） ------------------------------
mkdir -p $COLLECT/R09/r09-o2-m5ref-s1
sudo -n /usr/bin/python3 -I -B $CONTROL/controller.py run \
    --control-root $CONTROL --run-name r09-o2-m5ref-s1 --cpu 2 --timeout-seconds 900 \
    --plan $PLAN --plan-sha256 $PLAN_SHA \
    -- $R09/build/m5ref-O2/measure \
        r09-o2-m5ref-s1 31337 10000 $COLLECT/R09/r09-o2-m5ref-s1/r09-o2-m5ref-s1.csv $COLLECT/R09/r09-o2-m5ref-s1/r09-o2-m5ref-s1.meta
mkdir -p $COLLECT/R09/r09-o2-m5ref-s2
sudo -n /usr/bin/python3 -I -B $CONTROL/controller.py run \
    --control-root $CONTROL --run-name r09-o2-m5ref-s2 --cpu 2 --timeout-seconds 900 \
    --plan $PLAN --plan-sha256 $PLAN_SHA \
    -- $R09/build/m5ref-O2/measure \
        r09-o2-m5ref-s2 424242 10000 $COLLECT/R09/r09-o2-m5ref-s2/r09-o2-m5ref-s2.csv $COLLECT/R09/r09-o2-m5ref-s2/r09-o2-m5ref-s2.meta
mkdir -p $COLLECT/R09/r09-o2-m5ref-s3
sudo -n /usr/bin/python3 -I -B $CONTROL/controller.py run \
    --control-root $CONTROL --run-name r09-o2-m5ref-s3 --cpu 6 --timeout-seconds 900 \
    --plan $PLAN --plan-sha256 $PLAN_SHA \
    -- $R09/build/m5ref-O2/measure \
        r09-o2-m5ref-s3 7 10000 $COLLECT/R09/r09-o2-m5ref-s3/r09-o2-m5ref-s3.csv $COLLECT/R09/r09-o2-m5ref-s3/r09-o2-m5ref-s3.meta
# ------------------------------ m1unfixed-O3 : M1 未修（liboqs 0.10.0 historical-clangover） ------------------------------
mkdir -p $COLLECT/R09/r09-o3-m1unfixed-s1
sudo -n /usr/bin/python3 -I -B $CONTROL/controller.py run \
    --control-root $CONTROL --run-name r09-o3-m1unfixed-s1 --cpu 2 --timeout-seconds 900 \
    --plan $PLAN --plan-sha256 $PLAN_SHA \
    -- $R09/build/m1unfixed-O3/measure \
        r09-o3-m1unfixed-s1 31337 10000 $COLLECT/R09/r09-o3-m1unfixed-s1/r09-o3-m1unfixed-s1.csv $COLLECT/R09/r09-o3-m1unfixed-s1/r09-o3-m1unfixed-s1.meta
mkdir -p $COLLECT/R09/r09-o3-m1unfixed-s2
sudo -n /usr/bin/python3 -I -B $CONTROL/controller.py run \
    --control-root $CONTROL --run-name r09-o3-m1unfixed-s2 --cpu 2 --timeout-seconds 900 \
    --plan $PLAN --plan-sha256 $PLAN_SHA \
    -- $R09/build/m1unfixed-O3/measure \
        r09-o3-m1unfixed-s2 424242 10000 $COLLECT/R09/r09-o3-m1unfixed-s2/r09-o3-m1unfixed-s2.csv $COLLECT/R09/r09-o3-m1unfixed-s2/r09-o3-m1unfixed-s2.meta
mkdir -p $COLLECT/R09/r09-o3-m1unfixed-s3
sudo -n /usr/bin/python3 -I -B $CONTROL/controller.py run \
    --control-root $CONTROL --run-name r09-o3-m1unfixed-s3 --cpu 6 --timeout-seconds 900 \
    --plan $PLAN --plan-sha256 $PLAN_SHA \
    -- $R09/build/m1unfixed-O3/measure \
        r09-o3-m1unfixed-s3 7 10000 $COLLECT/R09/r09-o3-m1unfixed-s3/r09-o3-m1unfixed-s3.csv $COLLECT/R09/r09-o3-m1unfixed-s3/r09-o3-m1unfixed-s3.meta
# ------------------------------ m1fixed-O3 : M1 已修（+982c762） ------------------------------
mkdir -p $COLLECT/R09/r09-o3-m1fixed-s1
sudo -n /usr/bin/python3 -I -B $CONTROL/controller.py run \
    --control-root $CONTROL --run-name r09-o3-m1fixed-s1 --cpu 2 --timeout-seconds 900 \
    --plan $PLAN --plan-sha256 $PLAN_SHA \
    -- $R09/build/m1fixed-O3/measure \
        r09-o3-m1fixed-s1 31337 10000 $COLLECT/R09/r09-o3-m1fixed-s1/r09-o3-m1fixed-s1.csv $COLLECT/R09/r09-o3-m1fixed-s1/r09-o3-m1fixed-s1.meta
mkdir -p $COLLECT/R09/r09-o3-m1fixed-s2
sudo -n /usr/bin/python3 -I -B $CONTROL/controller.py run \
    --control-root $CONTROL --run-name r09-o3-m1fixed-s2 --cpu 2 --timeout-seconds 900 \
    --plan $PLAN --plan-sha256 $PLAN_SHA \
    -- $R09/build/m1fixed-O3/measure \
        r09-o3-m1fixed-s2 424242 10000 $COLLECT/R09/r09-o3-m1fixed-s2/r09-o3-m1fixed-s2.csv $COLLECT/R09/r09-o3-m1fixed-s2/r09-o3-m1fixed-s2.meta
mkdir -p $COLLECT/R09/r09-o3-m1fixed-s3
sudo -n /usr/bin/python3 -I -B $CONTROL/controller.py run \
    --control-root $CONTROL --run-name r09-o3-m1fixed-s3 --cpu 6 --timeout-seconds 900 \
    --plan $PLAN --plan-sha256 $PLAN_SHA \
    -- $R09/build/m1fixed-O3/measure \
        r09-o3-m1fixed-s3 7 10000 $COLLECT/R09/r09-o3-m1fixed-s3/r09-o3-m1fixed-s3.csv $COLLECT/R09/r09-o3-m1fixed-s3/r09-o3-m1fixed-s3.meta
# ------------------------------ m5ref-O3 : M5（mlkem-native b3ba7b3 portable reference） ------------------------------
mkdir -p $COLLECT/R09/r09-o3-m5ref-s1
sudo -n /usr/bin/python3 -I -B $CONTROL/controller.py run \
    --control-root $CONTROL --run-name r09-o3-m5ref-s1 --cpu 2 --timeout-seconds 900 \
    --plan $PLAN --plan-sha256 $PLAN_SHA \
    -- $R09/build/m5ref-O3/measure \
        r09-o3-m5ref-s1 31337 10000 $COLLECT/R09/r09-o3-m5ref-s1/r09-o3-m5ref-s1.csv $COLLECT/R09/r09-o3-m5ref-s1/r09-o3-m5ref-s1.meta
mkdir -p $COLLECT/R09/r09-o3-m5ref-s2
sudo -n /usr/bin/python3 -I -B $CONTROL/controller.py run \
    --control-root $CONTROL --run-name r09-o3-m5ref-s2 --cpu 2 --timeout-seconds 900 \
    --plan $PLAN --plan-sha256 $PLAN_SHA \
    -- $R09/build/m5ref-O3/measure \
        r09-o3-m5ref-s2 424242 10000 $COLLECT/R09/r09-o3-m5ref-s2/r09-o3-m5ref-s2.csv $COLLECT/R09/r09-o3-m5ref-s2/r09-o3-m5ref-s2.meta
mkdir -p $COLLECT/R09/r09-o3-m5ref-s3
sudo -n /usr/bin/python3 -I -B $CONTROL/controller.py run \
    --control-root $CONTROL --run-name r09-o3-m5ref-s3 --cpu 6 --timeout-seconds 900 \
    --plan $PLAN --plan-sha256 $PLAN_SHA \
    -- $R09/build/m5ref-O3/measure \
        r09-o3-m5ref-s3 7 10000 $COLLECT/R09/r09-o3-m5ref-s3/r09-o3-m5ref-s3.csv $COLLECT/R09/r09-o3-m5ref-s3/r09-o3-m5ref-s3.meta
# ------------------------------ m1unfixed-Os : M1 未修（liboqs 0.10.0 historical-clangover） ------------------------------
mkdir -p $COLLECT/R09/r09-os-m1unfixed-s1
sudo -n /usr/bin/python3 -I -B $CONTROL/controller.py run \
    --control-root $CONTROL --run-name r09-os-m1unfixed-s1 --cpu 2 --timeout-seconds 900 \
    --plan $PLAN --plan-sha256 $PLAN_SHA \
    -- $R09/build/m1unfixed-Os/measure \
        r09-os-m1unfixed-s1 31337 10000 $COLLECT/R09/r09-os-m1unfixed-s1/r09-os-m1unfixed-s1.csv $COLLECT/R09/r09-os-m1unfixed-s1/r09-os-m1unfixed-s1.meta
mkdir -p $COLLECT/R09/r09-os-m1unfixed-s2
sudo -n /usr/bin/python3 -I -B $CONTROL/controller.py run \
    --control-root $CONTROL --run-name r09-os-m1unfixed-s2 --cpu 2 --timeout-seconds 900 \
    --plan $PLAN --plan-sha256 $PLAN_SHA \
    -- $R09/build/m1unfixed-Os/measure \
        r09-os-m1unfixed-s2 424242 10000 $COLLECT/R09/r09-os-m1unfixed-s2/r09-os-m1unfixed-s2.csv $COLLECT/R09/r09-os-m1unfixed-s2/r09-os-m1unfixed-s2.meta
mkdir -p $COLLECT/R09/r09-os-m1unfixed-s3
sudo -n /usr/bin/python3 -I -B $CONTROL/controller.py run \
    --control-root $CONTROL --run-name r09-os-m1unfixed-s3 --cpu 6 --timeout-seconds 900 \
    --plan $PLAN --plan-sha256 $PLAN_SHA \
    -- $R09/build/m1unfixed-Os/measure \
        r09-os-m1unfixed-s3 7 10000 $COLLECT/R09/r09-os-m1unfixed-s3/r09-os-m1unfixed-s3.csv $COLLECT/R09/r09-os-m1unfixed-s3/r09-os-m1unfixed-s3.meta
# ------------------------------ m1fixed-Os : M1 已修（+982c762） ------------------------------
mkdir -p $COLLECT/R09/r09-os-m1fixed-s1
sudo -n /usr/bin/python3 -I -B $CONTROL/controller.py run \
    --control-root $CONTROL --run-name r09-os-m1fixed-s1 --cpu 2 --timeout-seconds 900 \
    --plan $PLAN --plan-sha256 $PLAN_SHA \
    -- $R09/build/m1fixed-Os/measure \
        r09-os-m1fixed-s1 31337 10000 $COLLECT/R09/r09-os-m1fixed-s1/r09-os-m1fixed-s1.csv $COLLECT/R09/r09-os-m1fixed-s1/r09-os-m1fixed-s1.meta
mkdir -p $COLLECT/R09/r09-os-m1fixed-s2
sudo -n /usr/bin/python3 -I -B $CONTROL/controller.py run \
    --control-root $CONTROL --run-name r09-os-m1fixed-s2 --cpu 2 --timeout-seconds 900 \
    --plan $PLAN --plan-sha256 $PLAN_SHA \
    -- $R09/build/m1fixed-Os/measure \
        r09-os-m1fixed-s2 424242 10000 $COLLECT/R09/r09-os-m1fixed-s2/r09-os-m1fixed-s2.csv $COLLECT/R09/r09-os-m1fixed-s2/r09-os-m1fixed-s2.meta
mkdir -p $COLLECT/R09/r09-os-m1fixed-s3
sudo -n /usr/bin/python3 -I -B $CONTROL/controller.py run \
    --control-root $CONTROL --run-name r09-os-m1fixed-s3 --cpu 6 --timeout-seconds 900 \
    --plan $PLAN --plan-sha256 $PLAN_SHA \
    -- $R09/build/m1fixed-Os/measure \
        r09-os-m1fixed-s3 7 10000 $COLLECT/R09/r09-os-m1fixed-s3/r09-os-m1fixed-s3.csv $COLLECT/R09/r09-os-m1fixed-s3/r09-os-m1fixed-s3.meta
# ------------------------------ m5ref-Os : M5（mlkem-native b3ba7b3 portable reference） ------------------------------
mkdir -p $COLLECT/R09/r09-os-m5ref-s1
sudo -n /usr/bin/python3 -I -B $CONTROL/controller.py run \
    --control-root $CONTROL --run-name r09-os-m5ref-s1 --cpu 2 --timeout-seconds 900 \
    --plan $PLAN --plan-sha256 $PLAN_SHA \
    -- $R09/build/m5ref-Os/measure \
        r09-os-m5ref-s1 31337 10000 $COLLECT/R09/r09-os-m5ref-s1/r09-os-m5ref-s1.csv $COLLECT/R09/r09-os-m5ref-s1/r09-os-m5ref-s1.meta
mkdir -p $COLLECT/R09/r09-os-m5ref-s2
sudo -n /usr/bin/python3 -I -B $CONTROL/controller.py run \
    --control-root $CONTROL --run-name r09-os-m5ref-s2 --cpu 2 --timeout-seconds 900 \
    --plan $PLAN --plan-sha256 $PLAN_SHA \
    -- $R09/build/m5ref-Os/measure \
        r09-os-m5ref-s2 424242 10000 $COLLECT/R09/r09-os-m5ref-s2/r09-os-m5ref-s2.csv $COLLECT/R09/r09-os-m5ref-s2/r09-os-m5ref-s2.meta
mkdir -p $COLLECT/R09/r09-os-m5ref-s3
sudo -n /usr/bin/python3 -I -B $CONTROL/controller.py run \
    --control-root $CONTROL --run-name r09-os-m5ref-s3 --cpu 6 --timeout-seconds 900 \
    --plan $PLAN --plan-sha256 $PLAN_SHA \
    -- $R09/build/m5ref-Os/measure \
        r09-os-m5ref-s3 7 10000 $COLLECT/R09/r09-os-m5ref-s3/r09-os-m5ref-s3.csv $COLLECT/R09/r09-os-m5ref-s3/r09-os-m5ref-s3.meta
# ------------------------------ 采集后只读核对（不需要 sudo） ------------------------------
# 逐 run 检查判据：
#   for run in r09-o0-m1unfixed-s1 r09-o0-m1unfixed-s2 r09-o0-m1unfixed-s3 ; do
#       python3 -c "import json;t=json.load(open('$COLLECT/R09/$run/controller/terminal.json'));print('$run',t.get('reason'),t.get('worker_exit_code'),t.get('worker_drained'),t.get('restore_match'))"
#   done
# 期望每一行都是：worker_finished 0 True yes
# 统计（每格每次运行一个**新**输出目录，冻结 platform_stats 与 RTLF）：
#   STATS_BIN=/home/nss-marker/yhr/Cry/platform-s5-20261016-b4cd8480318c/build-v2/platform_stats
#   RTLF=/home/nss-marker/yhr/Cry/platform-m5-20261016-30efdf66eb26/source-v2/third_party/RTLF/rtlf.R
#   sh scripts/run_stats_battery.sh \
#       --input $COLLECT/R09/r09-os-m1unfixed-s1/r09-os-m1unfixed-s1.csv --format measure \
#       --classes message-zero message-ones --output-dir $COLLECT/R09/analysis/r09-os-m1unfixed-s1 \
#       --stats-bin $STATS_BIN --rtlf-script $RTLF
