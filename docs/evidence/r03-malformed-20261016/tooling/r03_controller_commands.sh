#!/bin/sh
# r03 族外对照：9 条控制器采集命令（主控串行执行；本文件不被自动执行）。
#
# 预算：3 个种子（31337 / 424242 / 7）× 三臂；s1/s2 用 CPU2，s3 用 CPU6；
#       每类 10000 次、预热 100、--timeout-seconds 600。
# 有效判据（与主合同一致）：terminal.json 的 reason=worker_finished、
#       worker_exit_code=0、worker_drained=true、restore_match=yes 同时成立。
# 每个 run 一个新 run-name、一个新输出目录；CSV/meta 用 "wx" 新建，已存在即失败。
#
# 变量（主控机器上的实际值，逐字使用）：
#   COLLECT=/home/nss-marker/yhr/Cry/platform-collect-20261016-c011ec7a5e01
#   CTRL=/home/nss-marker/yhr/Cry/platform-control-20261016-c011ec7a5e01
#   PLAN=$COLLECT/plans/m5-completion-PLAN.md
#   PLAN_SHA=15738beea1e8d22ae58f83ed741636c2bcf7d9f49e16f0c5c0f2f8590c323e44
#
# 备选（语义更贴合的冻结计划，需主控决定后再用，一旦开跑不要中途改）：
#   /home/nss-marker/yhr/Cry/r03-malformed-20261016/plans/r03-PLAN.md
#   sha256=3ef882a976eb5e7ead5f055c51a3e4255bf48ab790ec1ec2ddff2e0d26ef9eb6
#
# 采数前每个 run 的输出目录必须先建好（控制器不建目录）：
#   mkdir -p "$COLLECT/R03/<run-name>"

# ------------------------------ M1 未修臂（liboqs 0.10.0 clangover） ------------------------------
mkdir -p /home/nss-marker/yhr/Cry/platform-collect-20261016-c011ec7a5e01/R03/r03-m1unfixed-s1
sudo -n /usr/bin/python3 -I -B /home/nss-marker/yhr/Cry/platform-control-20261016-c011ec7a5e01/controller.py run \
    --control-root /home/nss-marker/yhr/Cry/platform-control-20261016-c011ec7a5e01 \
    --run-name r03-m1unfixed-s1 --cpu 2 --timeout-seconds 600 \
    --plan /home/nss-marker/yhr/Cry/platform-collect-20261016-c011ec7a5e01/plans/m5-completion-PLAN.md \
    --plan-sha256 15738beea1e8d22ae58f83ed741636c2bcf7d9f49e16f0c5c0f2f8590c323e44 \
    -- /home/nss-marker/yhr/Cry/r03-malformed-20261016-29ea2774da23/build/m1unfixed/r03_malformed_measure \
        --class valid,malformed,truncated --samples 10000 --seed 31337 --warmup 100 \
        --raw /home/nss-marker/yhr/Cry/platform-collect-20261016-c011ec7a5e01/R03/r03-m1unfixed-s1/r03-m1unfixed-s1.csv \
        --meta /home/nss-marker/yhr/Cry/platform-collect-20261016-c011ec7a5e01/R03/r03-m1unfixed-s1/r03-m1unfixed-s1.meta \
        --run-id r03-m1unfixed-s1

mkdir -p /home/nss-marker/yhr/Cry/platform-collect-20261016-c011ec7a5e01/R03/r03-m1unfixed-s2
sudo -n /usr/bin/python3 -I -B /home/nss-marker/yhr/Cry/platform-control-20261016-c011ec7a5e01/controller.py run \
    --control-root /home/nss-marker/yhr/Cry/platform-control-20261016-c011ec7a5e01 \
    --run-name r03-m1unfixed-s2 --cpu 2 --timeout-seconds 600 \
    --plan /home/nss-marker/yhr/Cry/platform-collect-20261016-c011ec7a5e01/plans/m5-completion-PLAN.md \
    --plan-sha256 15738beea1e8d22ae58f83ed741636c2bcf7d9f49e16f0c5c0f2f8590c323e44 \
    -- /home/nss-marker/yhr/Cry/r03-malformed-20261016-29ea2774da23/build/m1unfixed/r03_malformed_measure \
        --class valid,malformed,truncated --samples 10000 --seed 424242 --warmup 100 \
        --raw /home/nss-marker/yhr/Cry/platform-collect-20261016-c011ec7a5e01/R03/r03-m1unfixed-s2/r03-m1unfixed-s2.csv \
        --meta /home/nss-marker/yhr/Cry/platform-collect-20261016-c011ec7a5e01/R03/r03-m1unfixed-s2/r03-m1unfixed-s2.meta \
        --run-id r03-m1unfixed-s2

mkdir -p /home/nss-marker/yhr/Cry/platform-collect-20261016-c011ec7a5e01/R03/r03-m1unfixed-s3
sudo -n /usr/bin/python3 -I -B /home/nss-marker/yhr/Cry/platform-control-20261016-c011ec7a5e01/controller.py run \
    --control-root /home/nss-marker/yhr/Cry/platform-control-20261016-c011ec7a5e01 \
    --run-name r03-m1unfixed-s3 --cpu 6 --timeout-seconds 600 \
    --plan /home/nss-marker/yhr/Cry/platform-collect-20261016-c011ec7a5e01/plans/m5-completion-PLAN.md \
    --plan-sha256 15738beea1e8d22ae58f83ed741636c2bcf7d9f49e16f0c5c0f2f8590c323e44 \
    -- /home/nss-marker/yhr/Cry/r03-malformed-20261016-29ea2774da23/build/m1unfixed/r03_malformed_measure \
        --class valid,malformed,truncated --samples 10000 --seed 7 --warmup 100 \
        --raw /home/nss-marker/yhr/Cry/platform-collect-20261016-c011ec7a5e01/R03/r03-m1unfixed-s3/r03-m1unfixed-s3.csv \
        --meta /home/nss-marker/yhr/Cry/platform-collect-20261016-c011ec7a5e01/R03/r03-m1unfixed-s3/r03-m1unfixed-s3.meta \
        --run-id r03-m1unfixed-s3

# ------------------------------ M1 已修臂（liboqs 0.10.0 + 982c762） ------------------------------
mkdir -p /home/nss-marker/yhr/Cry/platform-collect-20261016-c011ec7a5e01/R03/r03-m1fixed-s1
sudo -n /usr/bin/python3 -I -B /home/nss-marker/yhr/Cry/platform-control-20261016-c011ec7a5e01/controller.py run \
    --control-root /home/nss-marker/yhr/Cry/platform-control-20261016-c011ec7a5e01 \
    --run-name r03-m1fixed-s1 --cpu 2 --timeout-seconds 600 \
    --plan /home/nss-marker/yhr/Cry/platform-collect-20261016-c011ec7a5e01/plans/m5-completion-PLAN.md \
    --plan-sha256 15738beea1e8d22ae58f83ed741636c2bcf7d9f49e16f0c5c0f2f8590c323e44 \
    -- /home/nss-marker/yhr/Cry/r03-malformed-20261016-29ea2774da23/build/m1fixed/r03_malformed_measure \
        --class valid,malformed,truncated --samples 10000 --seed 31337 --warmup 100 \
        --raw /home/nss-marker/yhr/Cry/platform-collect-20261016-c011ec7a5e01/R03/r03-m1fixed-s1/r03-m1fixed-s1.csv \
        --meta /home/nss-marker/yhr/Cry/platform-collect-20261016-c011ec7a5e01/R03/r03-m1fixed-s1/r03-m1fixed-s1.meta \
        --run-id r03-m1fixed-s1

mkdir -p /home/nss-marker/yhr/Cry/platform-collect-20261016-c011ec7a5e01/R03/r03-m1fixed-s2
sudo -n /usr/bin/python3 -I -B /home/nss-marker/yhr/Cry/platform-control-20261016-c011ec7a5e01/controller.py run \
    --control-root /home/nss-marker/yhr/Cry/platform-control-20261016-c011ec7a5e01 \
    --run-name r03-m1fixed-s2 --cpu 2 --timeout-seconds 600 \
    --plan /home/nss-marker/yhr/Cry/platform-collect-20261016-c011ec7a5e01/plans/m5-completion-PLAN.md \
    --plan-sha256 15738beea1e8d22ae58f83ed741636c2bcf7d9f49e16f0c5c0f2f8590c323e44 \
    -- /home/nss-marker/yhr/Cry/r03-malformed-20261016-29ea2774da23/build/m1fixed/r03_malformed_measure \
        --class valid,malformed,truncated --samples 10000 --seed 424242 --warmup 100 \
        --raw /home/nss-marker/yhr/Cry/platform-collect-20261016-c011ec7a5e01/R03/r03-m1fixed-s2/r03-m1fixed-s2.csv \
        --meta /home/nss-marker/yhr/Cry/platform-collect-20261016-c011ec7a5e01/R03/r03-m1fixed-s2/r03-m1fixed-s2.meta \
        --run-id r03-m1fixed-s2

mkdir -p /home/nss-marker/yhr/Cry/platform-collect-20261016-c011ec7a5e01/R03/r03-m1fixed-s3
sudo -n /usr/bin/python3 -I -B /home/nss-marker/yhr/Cry/platform-control-20261016-c011ec7a5e01/controller.py run \
    --control-root /home/nss-marker/yhr/Cry/platform-control-20261016-c011ec7a5e01 \
    --run-name r03-m1fixed-s3 --cpu 6 --timeout-seconds 600 \
    --plan /home/nss-marker/yhr/Cry/platform-collect-20261016-c011ec7a5e01/plans/m5-completion-PLAN.md \
    --plan-sha256 15738beea1e8d22ae58f83ed741636c2bcf7d9f49e16f0c5c0f2f8590c323e44 \
    -- /home/nss-marker/yhr/Cry/r03-malformed-20261016-29ea2774da23/build/m1fixed/r03_malformed_measure \
        --class valid,malformed,truncated --samples 10000 --seed 7 --warmup 100 \
        --raw /home/nss-marker/yhr/Cry/platform-collect-20261016-c011ec7a5e01/R03/r03-m1fixed-s3/r03-m1fixed-s3.csv \
        --meta /home/nss-marker/yhr/Cry/platform-collect-20261016-c011ec7a5e01/R03/r03-m1fixed-s3/r03-m1fixed-s3.meta \
        --run-id r03-m1fixed-s3

# ------------------------------ M5 参考臂（mlkem-native b3ba7b3 reference） ------------------------------
mkdir -p /home/nss-marker/yhr/Cry/platform-collect-20261016-c011ec7a5e01/R03/r03-m5ref-s1
sudo -n /usr/bin/python3 -I -B /home/nss-marker/yhr/Cry/platform-control-20261016-c011ec7a5e01/controller.py run \
    --control-root /home/nss-marker/yhr/Cry/platform-control-20261016-c011ec7a5e01 \
    --run-name r03-m5ref-s1 --cpu 2 --timeout-seconds 600 \
    --plan /home/nss-marker/yhr/Cry/platform-collect-20261016-c011ec7a5e01/plans/m5-completion-PLAN.md \
    --plan-sha256 15738beea1e8d22ae58f83ed741636c2bcf7d9f49e16f0c5c0f2f8590c323e44 \
    -- /home/nss-marker/yhr/Cry/r03-malformed-20261016-29ea2774da23/build/m5ref/r03_malformed_measure \
        --class valid,malformed,truncated --samples 10000 --seed 31337 --warmup 100 \
        --raw /home/nss-marker/yhr/Cry/platform-collect-20261016-c011ec7a5e01/R03/r03-m5ref-s1/r03-m5ref-s1.csv \
        --meta /home/nss-marker/yhr/Cry/platform-collect-20261016-c011ec7a5e01/R03/r03-m5ref-s1/r03-m5ref-s1.meta \
        --run-id r03-m5ref-s1

mkdir -p /home/nss-marker/yhr/Cry/platform-collect-20261016-c011ec7a5e01/R03/r03-m5ref-s2
sudo -n /usr/bin/python3 -I -B /home/nss-marker/yhr/Cry/platform-control-20261016-c011ec7a5e01/controller.py run \
    --control-root /home/nss-marker/yhr/Cry/platform-control-20261016-c011ec7a5e01 \
    --run-name r03-m5ref-s2 --cpu 2 --timeout-seconds 600 \
    --plan /home/nss-marker/yhr/Cry/platform-collect-20261016-c011ec7a5e01/plans/m5-completion-PLAN.md \
    --plan-sha256 15738beea1e8d22ae58f83ed741636c2bcf7d9f49e16f0c5c0f2f8590c323e44 \
    -- /home/nss-marker/yhr/Cry/r03-malformed-20261016-29ea2774da23/build/m5ref/r03_malformed_measure \
        --class valid,malformed,truncated --samples 10000 --seed 424242 --warmup 100 \
        --raw /home/nss-marker/yhr/Cry/platform-collect-20261016-c011ec7a5e01/R03/r03-m5ref-s2/r03-m5ref-s2.csv \
        --meta /home/nss-marker/yhr/Cry/platform-collect-20261016-c011ec7a5e01/R03/r03-m5ref-s2/r03-m5ref-s2.meta \
        --run-id r03-m5ref-s2

mkdir -p /home/nss-marker/yhr/Cry/platform-collect-20261016-c011ec7a5e01/R03/r03-m5ref-s3
sudo -n /usr/bin/python3 -I -B /home/nss-marker/yhr/Cry/platform-control-20261016-c011ec7a5e01/controller.py run \
    --control-root /home/nss-marker/yhr/Cry/platform-control-20261016-c011ec7a5e01 \
    --run-name r03-m5ref-s3 --cpu 6 --timeout-seconds 600 \
    --plan /home/nss-marker/yhr/Cry/platform-collect-20261016-c011ec7a5e01/plans/m5-completion-PLAN.md \
    --plan-sha256 15738beea1e8d22ae58f83ed741636c2bcf7d9f49e16f0c5c0f2f8590c323e44 \
    -- /home/nss-marker/yhr/Cry/r03-malformed-20261016-29ea2774da23/build/m5ref/r03_malformed_measure \
        --class valid,malformed,truncated --samples 10000 --seed 7 --warmup 100 \
        --raw /home/nss-marker/yhr/Cry/platform-collect-20261016-c011ec7a5e01/R03/r03-m5ref-s3/r03-m5ref-s3.csv \
        --meta /home/nss-marker/yhr/Cry/platform-collect-20261016-c011ec7a5e01/R03/r03-m5ref-s3/r03-m5ref-s3.meta \
        --run-id r03-m5ref-s3

# ------------------------------ 族外 online dudect（每臂一次，21 批） ------------------------------
# M5：冻结树既有入口（--collect --seed N --raw NEW.csv）；每批 10000 次完整 decap，最多 21 批。
mkdir -p /home/nss-marker/yhr/Cry/platform-collect-20261016-c011ec7a5e01/R03/r03-m5ref-dud-s1
sudo -n /usr/bin/python3 -I -B /home/nss-marker/yhr/Cry/platform-control-20261016-c011ec7a5e01/controller.py run \
    --control-root /home/nss-marker/yhr/Cry/platform-control-20261016-c011ec7a5e01 \
    --run-name r03-m5ref-dud-s1 --cpu 2 --timeout-seconds 600 \
    --plan /home/nss-marker/yhr/Cry/platform-collect-20261016-c011ec7a5e01/plans/m5-completion-PLAN.md \
    --plan-sha256 15738beea1e8d22ae58f83ed741636c2bcf7d9f49e16f0c5c0f2f8590c323e44 \
    -- /home/nss-marker/yhr/Cry/platform-m5-20261016-30efdf66eb26/build-v2-ordinary/platform_m5_dudect \
        --collect --seed 31337 \
        --raw /home/nss-marker/yhr/Cry/platform-collect-20261016-c011ec7a5e01/R03/r03-m5ref-dud-s1/dudect-cycles.csv

# M1 未修 / 已修：新根内编译的等价入口（同一份 tools/historical_dudect.c，无参数）。
# 种子默认 31337（编译期常量）；换种子需在 sudo 后带环境变量赋值：
#   sudo -n HISTORICAL_DUDECT_SEED=424242 /usr/bin/python3 -I -B ... controller.py run ...
mkdir -p /home/nss-marker/yhr/Cry/platform-collect-20261016-c011ec7a5e01/R03/r03-m1unfixed-dud-s1
sudo -n /usr/bin/python3 -I -B /home/nss-marker/yhr/Cry/platform-control-20261016-c011ec7a5e01/controller.py run \
    --control-root /home/nss-marker/yhr/Cry/platform-control-20261016-c011ec7a5e01 \
    --run-name r03-m1unfixed-dud-s1 --cpu 2 --timeout-seconds 600 \
    --plan /home/nss-marker/yhr/Cry/platform-collect-20261016-c011ec7a5e01/plans/m5-completion-PLAN.md \
    --plan-sha256 15738beea1e8d22ae58f83ed741636c2bcf7d9f49e16f0c5c0f2f8590c323e44 \
    -- /home/nss-marker/yhr/Cry/r03-malformed-20261016-29ea2774da23/build/m1unfixed/r03_historical_dudect

mkdir -p /home/nss-marker/yhr/Cry/platform-collect-20261016-c011ec7a5e01/R03/r03-m1fixed-dud-s1
sudo -n /usr/bin/python3 -I -B /home/nss-marker/yhr/Cry/platform-control-20261016-c011ec7a5e01/controller.py run \
    --control-root /home/nss-marker/yhr/Cry/platform-control-20261016-c011ec7a5e01 \
    --run-name r03-m1fixed-dud-s1 --cpu 2 --timeout-seconds 600 \
    --plan /home/nss-marker/yhr/Cry/platform-collect-20261016-c011ec7a5e01/plans/m5-completion-PLAN.md \
    --plan-sha256 15738beea1e8d22ae58f83ed741636c2bcf7d9f49e16f0c5c0f2f8590c323e44 \
    -- /home/nss-marker/yhr/Cry/r03-malformed-20261016-29ea2774da23/build/m1fixed/r03_historical_dudect
