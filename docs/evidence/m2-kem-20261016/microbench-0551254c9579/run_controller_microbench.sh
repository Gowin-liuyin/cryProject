#!/bin/sh
# M2 除法热点微基准（poly_tomsg）经唯一锁频控制器的六个预注册采集运行。
#
# 由 lead 以 root 串行执行；本文件不自己跑控制器、不写频率、不设亲和性。
# 顺序是预注册的一部分（PLAN §3.1：run1 未修→已修、run2 已修→未修、run3 未修→已修），
# 不得因观察结果改序。每个 run-name 只能执行一次（控制器拒绝已存在的运行目录）。
#
# 前置：本脚本所在的微基准子树内 runs/ 下六个目录已存在且为空。
set -eu

MICRO=/home/nss-marker/yhr/Cry/platform-m2micro-20261016-0551254c9579
FROZEN=/home/nss-marker/yhr/Cry/platform-m2kem-20261016-d75a4019/collector-v2-2e894561892a
FIXTURES=${FROZEN}/qualification-ordinary/fixtures
CONTROL=/home/nss-marker/yhr/Cry/platform-control-20261016-c011ec7a5e01
PLAN=/home/nss-marker/yhr/Cry/platform-collect-20261016-c011ec7a5e01/plans/m2-kem-PLAN.md
PLAN_SHA256=0f706455c6a8fde28ecd3dc18fb12ae4562c2f57dc7e2d991b5ff83c5cd07142

# run1: CPU2 / seed 31337，未修 → 已修
sudo -n /usr/bin/python3 -I -B ${CONTROL}/controller.py run \
    --control-root ${CONTROL} --run-name m2-micro-s1-unfixed --cpu 2 --timeout-seconds 300 \
    --plan ${PLAN} --plan-sha256 ${PLAN_SHA256} \
    -- ${MICRO}/build-ordinary/microbench/unfixed/m2_hotspot_microbench \
        --class message-zero,message-ones --samples 10000 --seed 31337 --warmup 100 \
        --raw ${MICRO}/runs/m2-micro-s1-unfixed/unfixed-main.csv \
        --meta ${MICRO}/runs/m2-micro-s1-unfixed/unfixed-main.meta \
        --run-id M2-micro-s1-unfixed-main \
        --public-key ${FIXTURES}/pk.bin --secret-key ${FIXTURES}/sk.bin

sudo -n /usr/bin/python3 -I -B ${CONTROL}/controller.py run \
    --control-root ${CONTROL} --run-name m2-micro-s1-fixed --cpu 2 --timeout-seconds 300 \
    --plan ${PLAN} --plan-sha256 ${PLAN_SHA256} \
    -- ${MICRO}/build-ordinary/microbench/fixed/m2_hotspot_microbench \
        --class message-zero,message-ones --samples 10000 --seed 31337 --warmup 100 \
        --raw ${MICRO}/runs/m2-micro-s1-fixed/fixed-main.csv \
        --meta ${MICRO}/runs/m2-micro-s1-fixed/fixed-main.meta \
        --run-id M2-micro-s1-fixed-main \
        --public-key ${FIXTURES}/pk.bin --secret-key ${FIXTURES}/sk.bin

# run2: CPU2 / seed 424242，已修 → 未修
sudo -n /usr/bin/python3 -I -B ${CONTROL}/controller.py run \
    --control-root ${CONTROL} --run-name m2-micro-s2-fixed --cpu 2 --timeout-seconds 300 \
    --plan ${PLAN} --plan-sha256 ${PLAN_SHA256} \
    -- ${MICRO}/build-ordinary/microbench/fixed/m2_hotspot_microbench \
        --class message-zero,message-ones --samples 10000 --seed 424242 --warmup 100 \
        --raw ${MICRO}/runs/m2-micro-s2-fixed/fixed-main.csv \
        --meta ${MICRO}/runs/m2-micro-s2-fixed/fixed-main.meta \
        --run-id M2-micro-s2-fixed-main \
        --public-key ${FIXTURES}/pk.bin --secret-key ${FIXTURES}/sk.bin

sudo -n /usr/bin/python3 -I -B ${CONTROL}/controller.py run \
    --control-root ${CONTROL} --run-name m2-micro-s2-unfixed --cpu 2 --timeout-seconds 300 \
    --plan ${PLAN} --plan-sha256 ${PLAN_SHA256} \
    -- ${MICRO}/build-ordinary/microbench/unfixed/m2_hotspot_microbench \
        --class message-zero,message-ones --samples 10000 --seed 424242 --warmup 100 \
        --raw ${MICRO}/runs/m2-micro-s2-unfixed/unfixed-main.csv \
        --meta ${MICRO}/runs/m2-micro-s2-unfixed/unfixed-main.meta \
        --run-id M2-micro-s2-unfixed-main \
        --public-key ${FIXTURES}/pk.bin --secret-key ${FIXTURES}/sk.bin

# run3: CPU6 / seed 31337，未修 → 已修
sudo -n /usr/bin/python3 -I -B ${CONTROL}/controller.py run \
    --control-root ${CONTROL} --run-name m2-micro-s3-unfixed --cpu 6 --timeout-seconds 300 \
    --plan ${PLAN} --plan-sha256 ${PLAN_SHA256} \
    -- ${MICRO}/build-ordinary/microbench/unfixed/m2_hotspot_microbench \
        --class message-zero,message-ones --samples 10000 --seed 31337 --warmup 100 \
        --raw ${MICRO}/runs/m2-micro-s3-unfixed/unfixed-main.csv \
        --meta ${MICRO}/runs/m2-micro-s3-unfixed/unfixed-main.meta \
        --run-id M2-micro-s3-unfixed-main \
        --public-key ${FIXTURES}/pk.bin --secret-key ${FIXTURES}/sk.bin

sudo -n /usr/bin/python3 -I -B ${CONTROL}/controller.py run \
    --control-root ${CONTROL} --run-name m2-micro-s3-fixed --cpu 6 --timeout-seconds 300 \
    --plan ${PLAN} --plan-sha256 ${PLAN_SHA256} \
    -- ${MICRO}/build-ordinary/microbench/fixed/m2_hotspot_microbench \
        --class message-zero,message-ones --samples 10000 --seed 31337 --warmup 100 \
        --raw ${MICRO}/runs/m2-micro-s3-fixed/fixed-main.csv \
        --meta ${MICRO}/runs/m2-micro-s3-fixed/fixed-main.meta \
        --run-id M2-micro-s3-fixed-main \
        --public-key ${FIXTURES}/pk.bin --secret-key ${FIXTURES}/sk.bin

# 每个 run 的有效性判据（PLAN §7）：terminal.json 中 reason=worker_finished、
# worker_exit_code=0、worker_drained=true、restore_match=yes，且全局 active 指针消失。
printf 'controller_commands_status=submitted\n'
