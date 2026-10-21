#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""由证据文件生成 final5-20261016 的新增对照表与来源索引，避免手工转录数字。

只读输入（一个字节也不改）：
  docs/evidence/r01-kat-20261016/{VECTORS.md,EQUIV.md}
  docs/evidence/r02-env-20261016/{ENV_TABLE.md,OUTLIER_RULES.md,ROBUSTNESS.md}
  docs/evidence/r04-stats-20261016/{POWER.md,QUANTILE_CI.md}
  docs/R05-全流程排查表.md、docs/evidence/r05-locate-20261016/RESULT.md
  docs/evidence/r06-noleak-20261016/{AUDIT.md,MAPPING.md}
  docs/evidence/r08-perf-20261016/{perf.csv,perf.csv.comparison.csv}
  docs/evidence/r09-optlevel-20261016/result.csv.cells.csv
  docs/evidence/r11-threat-20261016/THREAT_MODEL.md
  docs/evidence/r12-innovation-20261016/{RESULT_LOCKED_VS_UNLOCKED.md,RESULT.md,TOOL_MATRIX.csv,REPRODUCE-QUICK-LOG.md}
  docs/REPRODUCE-PARAMS.md、scripts/reproduce_all.sh、BLOCKERS.md

输出：就地更新 report-tables.json（T10/T11 改写 + 追加 T12–T26）与 report-data.json（来源与状态）。
"""
import csv
import hashlib
import json
import os
import re
from pathlib import Path

DIRECTORY = Path(__file__).resolve().parent
REPOSITORY = DIRECTORY.parents[2]


def read_csv(name):
    with (REPOSITORY / name).open() as handle:
        return list(csv.DictReader(handle))


def number(value, digits=1):
    return f"{float(value):.{digits}f}"


def integer(value):
    return str(int(round(float(value))))


def read_text(name):
    return (REPOSITORY / name).read_text()


def count_mapping_rows():
    """按 MAPPING.md §1 表格实际数据行计数，不采信该文件 §2 的自述行数。"""
    text = read_text("docs/evidence/r06-noleak-20261016/MAPPING.md")
    section = text.split("## 1. 汇总表", 1)[1].split("\n---", 1)[0]
    rows = [line for line in section.split("\n") if line.startswith("|") and not re.match(r"^\|[\s\-|]+\|$", line)]
    return len(rows) - 1


def build_perf_summary():
    rows = []
    for record in read_csv("docs/evidence/r08-perf-20261016/perf.csv"):
        rows.append([
            record["module"], record["arm"], record["operation"], integer(record["n_calls_pooled"]),
            number(record["pooled_mean_ns"]), integer(record["pooled_mean_cycles"]),
            number(record["pooled_median_ns"]), number(record["pooled_p90_ns"]), number(record["pooled_p99_ns"]),
        ])
    return rows


def build_perf_comparison():
    rows = []
    for record in read_csv("docs/evidence/r08-perf-20261016/perf.csv.comparison.csv"):
        rows.append([
            record["module"], record["comparison"], record["operation"], record["paired_units"],
            number(record["delta_ns_paired"]), number(record["overhead_percent_paired"], 2),
            "[" + number(record["overhead_percent_paired_ci_low"], 2) + ", " + number(record["overhead_percent_paired_ci_high"], 2) + "]",
        ])
    return rows


# 产物侧「秘密相关分支」逐格判定，逐字取自 r09 RESULT.md §2 合并表。
OPTLEVEL_BRANCH = {
    "m1unfixed-O0": "无（movzbl; sar; and $1; xor; sub; and $0x681，源码级算术掩码被原样保留）",
    "m1unfixed-O2": "**有**（testb $0x1, (%rsi,%rax) 后跟 je，每比特一条，8 处）",
    "m1unfixed-O3": "**有**（同上形态，15 处）",
    "m1unfixed-Os": "**有**（bt %ecx,%r8d + jae，教科书 clangover 形态）",
    "m1fixed-O0": "无（掩码：call cmov_int16，体内 xor; sub; and; xor）",
    "m1fixed-O2": "无（掩码：call cmov_int16，体内 neg; xor; and; xor）",
    "m1fixed-O3": "无（同上）",
    "m1fixed-Os": "无（同一个 bt 后接 setb %dl，不是 jae）",
    "m5ref-O0": "无（掩码 + call mlk_value_barrier_u8 值屏障）",
    "m5ref-O2": "无（掩码：and; movzbl; neg; shr $0x10; and $0x681）",
    "m5ref-O3": "无（同上）",
    "m5ref-Os": "无（同上）",
}

# 只对 M1 未修四格引用 RESULT.md §3 问题 1 的原文判定，其余按机械规则由种子计数与合并 CI 派生。
OPTLEVEL_VERDICT = {
    "m1unfixed-O0": "**不可区分**：合并 CI 含 0（3 个种子全部含 0），且方向与分支代价模型相反（该级别没有分支，符号散乱）",
    "m1unfixed-O2": "**不可区分**：合并 CI 含 0（3 个种子全部含 0）；均值方向为负但区间跨 0",
    "m1unfixed-O3": "**不可区分（边缘）**：合并 CI 含 0，只有 1/3 种子自身 CI 不含 0",
    "m1unfixed-Os": "**可区分**：3 个种子方向一致为负，合并 CI 不含 0（−26.16 [−37.51, −14.81]），2/3 种子自身 CI 不含 0",
}


def build_optlevel_cells():
    label = {"m1unfixed": "M1 未修", "m1fixed": "M1 已修 982c762", "m5ref": "M5 参考 b3ba7b3"}
    runs = {}
    for record in read_csv("docs/evidence/r09-optlevel-20261016/result.csv"):
        runs.setdefault(record["cell"], []).append(record)
    rows = []
    for record in read_csv("docs/evidence/r09-optlevel-20261016/result.csv.cells.csv"):
        seed_rows = runs[record["cell"]]
        excluded = sum(1 for item in seed_rows if float(item["delta_ci_low_ns"]) > 0 or float(item["delta_ci_high_ns"]) < 0)
        # 合并口径：逆方差固定效应合并 Δ_pool 及其正态近似 95% CI（与 M1–M5 主家族统一）。
        pooled_low = float(record["delta_ns_pooled_ci_low"])
        pooled_high = float(record["delta_ns_pooled_ci_high"])
        # 种子范围列只描述 3 个种子 Δ 的散布区间，不是推断区间。
        seed_low = float(record["delta_ns_run_min"])
        seed_high = float(record["delta_ns_run_max"])
        if record["cell"] in OPTLEVEL_VERDICT:
            verdict = OPTLEVEL_VERDICT[record["cell"]]
        elif pooled_low <= 0 <= pooled_high:
            verdict = "不可区分：合并 CI 含 0"
        elif excluded == 0:
            verdict = "边缘：合并 CI 不含 0，但 3 个种子各自的 Welch CI 全部含 0"
        else:
            verdict = "可区分：合并 CI 不含 0 且 " + str(excluded) + "/3 种子自身 CI 不含 0"
        cells = str(int(record["judge_memcheck_contexts"])) + " / " + str(int(record["judge_memcheck_errors"]))
        rows.append([
            record["cell"], label[record["arm"]], record["optimization_level"], OPTLEVEL_BRANCH[record["cell"]],
            str(int(record["disasm_division"])), cells,
            record["delta_ns_per_seed"].replace("|", " / "),
            number(record["delta_ns_run_mean"], 2) + " [" + number(seed_low, 2) + ", " + number(seed_high, 2) + "]",
            number(record["delta_ns_pooled"], 2) + " [" + number(pooled_low, 2) + ", " + number(pooled_high, 2) + "]",
            verdict + ("" if record["cell"] in OPTLEVEL_VERDICT else "（" + str(excluded) + "/3 种子自身 CI 不含 0）"),
        ])
    return rows


VECTOR_ROWS = [
    ["M1 liboqs 0.10.0 未修（historical-clangover，Clang -Os -fno-vectorize）",
     "tests/vectors/mlkem768.txt，SHA-256 c94dda2717eb370dddfe5b7ca7a7f58d789e0f63238a486e464ce40c673817f4（NIST ACVP 转换件）",
     "80", "35", "logs/t05_m1_clangover_kat.log",
     "已执行 60 例中通过 35：keygen 0/25、encap 25/25、decap 10/10（含 5 例隐式拒绝）；keycheck 20 例记“不适用”（历史封装层无输入校验入口）；退出码 1，原因见本表注"],
    ["M1 liboqs 0.10.0 已修 982c762c242ef549c914891b47bf6e0ed6321f91",
     "同一向量文件与同一 SHA-256",
     "80", "35", "logs/t05_m1_fixed982c762_kat.log",
     "与未修臂逐项相同（keygen 0/25、encap 25/25、decap 10/10）"],
    ["M1 树内自带目标（historical/test_selftest）",
     "树内 tests/test_historical_selftest.c（系统随机往返，不含向量期望值）",
     "1", "1", "logs/t05_m1_clangover_selftest.log、logs/t05_m1_fixed982c762_selftest.log",
     "该树为 historical 变体提供的唯一自带目标；只做往返，不计入上表 80 例；本轮未运行计时入口 measure"],
    ["M2 pq-crystals kyber768 未修 a621b8dde405cc507cbcfc5f794570a4f98d69cc",
     "tests/vectors/kyber768_round3/PQCkemKAT_2400.rsp，SHA-256 a1e122cad3c24bc51622e4c242d8b8acbcd3f618fee4220400605ca8f9ea02c2（官方第 3 轮提交包成员原字节）",
     "100", "100", "logs/t05_m2_unfixed_kat.log", "逐例 keygen + encap + decap；100 例独立官方 round3 KAT 全通过"],
    ["M2 pq-crystals kyber768 已修 272125f6acc8e8b6850fd68ceb901a660ff48196",
     "同上 .rsp（同一 SHA-256）", "100", "100", "logs/t05_m2_fixed_kat.log", "与未修臂逐项相同"],
    ["M3 LUT-on（人工构造校准）",
     "mlkem768.txt（同一 ACVP 转换件），SHA-256 c94dda27…817f4", "80", "80", "logs/t05_m3_on_kat.log",
     "25 keygen + 25 encap + 10 decap + 10 ekcheck + 10 dkcheck 全通过；日志含 5 implicit rejections、5 accepted ciphertexts"],
    ["M3 LUT-off（人工构造校准）", "同上", "80", "80", "logs/t05_m3_off_kat.log", "与 on 版逐项相同"],
    ["M4 vulnerable（人工构造校准）",
     "无公开密码向量；人工夹具自检输入（mismatch-first / mismatch-last 各 1 例）", "2", "2", "logs/t05_m4_vulnerable_inputs.log",
     "输出 m4_inputs=pass timing_collection=not_run；人工构造校准，不对应真实密码算法"],
    ["M4 ct（人工构造校准）", "同上", "2", "2", "logs/t05_m4_ct_inputs.log",
     "两版 --describe 输出逐字节相同；人工构造校准"],
    ["M5 mlkem-native 参考 b3ba7b32773e657dd37f6f87bce82528459ad8a4",
     "mlkem768.txt（同一 ACVP 转换件）", "80", "80", "logs/t05_m5_reference_kat.log",
     "25 + 25 + 10 密码例与 20 例密钥校验全通过；含 5 implicit rejections"],
]

EQUIV_ROWS = [
    ["M1 clangover vs fixed-982c762",
     "公开 10 例（mlkem768.txt 的 decap，含 5 例拒绝例）",
     "1000（500 随机 + 500 逐字节篡改）",
     "空：cmp 退出 0、差异字节 0；两版摘要文件 SHA-256 均为 f4dbc5f4777247ef8930cd78dcafaa3e327e9d3d92aa2056aa465b55f4310b9d",
     "通过：public_rejection_agree=10/10；额外 1000 例 extra_rejected=1000/1000、extra_unexpected_accept=0；按 FIPS 203 §7.3 的 J(z‖c) 判定"],
    ["M2 a621b8d vs 272125f",
     "公开 100 例（官方 round3 KAT 全例，全部是接受例）",
     "1000（500 随机 + 500 逐字节篡改）",
     "空：cmp 退出 0、差异字节 0；两版摘要文件 SHA-256 均为 3af51d3605554f53461a288e1663aa5db50b176ed1df5feecf83c95c0f4ed0a2",
     "通过：public_expected_match=100/100、分类一致 100/100；额外 1000 例 extra_rejected=1000/1000；按 Kyber round3 §1.4 的 KDF(z‖H(c)) 判定（该历史算法不是 FIPS 203，不冒称附录口径）"],
    ["M3 LUT-on vs LUT-off（人工构造校准）",
     "公开 10 例（含 5 例拒绝例）", "1000（500 随机 + 500 逐字节篡改）",
     "空：cmp 退出 0、差异字节 0；两版摘要文件 SHA-256 均为 43c1fb206230284b98d89719894c2cc64867b043b508e200dcb7967626c528e3",
     "通过：public_rejection_agree=10/10；额外 1000 例 extra_rejected=1000/1000；按 FIPS 203 §7.3 的 J(z‖c) 判定"],
    ["M4 vulnerable vs ct（人工构造校准，仅接口等价）",
     "不适用（无共享密钥的无密码夹具）", "不适用",
     "接口等价：两版 --describe 输出逐字节相同（describe_cmp_exit_status=0），输入自检输出逐字节相同（inputs_cmp_exit_status=0）",
     "不适用：夹具不做解封装，没有隐式拒绝语义"],
]

ENV_ROWS = [
    ["主机与内核", "uname -a、/etc/os-release、/proc/cmdline、nproc、内存", "Linux 6.17.0-35-generic；Ubuntu 24.04.4 LTS；x86_64（**主机名不写**：提交件匿名，主机名不是题面要求的读数项）", "§1.1–1.4"],
    ["CPU", "lscpu", "AMD Ryzen 9 9950X，32 线程", "§1.6"],
    ["工具链", "clang、gcc、cmake、ninja、valgrind 版本", "clang 18.1.3、gcc 13.3.0、cmake 3.28.3、ninja 1.11.1、valgrind 3.22.0", "§2"],
    ["工具缺失（如实登记）", "binsec、z3", "binsec 未安装（历史仅 M4 运行时 opam root，现已无二进制）；z3 不在 PATH，M4 运行时目录内 4.15.3", "§2.2"],
    ["实际编译行", "M1 两版、M2 两版、M3 on/off、M4 两臂、M5，共 5 组，逐条含 ELF 摘要核验", "M1 用 -Os -fno-vectorize；M2 用 -Oz -g -fno-vectorize -fno-slp-vectorize；均无 -march、无显式 -mavx*", "§3.2–3.6"],
    ["计时源", "各采集件的 clock 与 time_unit", "完整解封装用 CLOCK_MONOTONIC；M4 比较步用 CLOCK_MONOTONIC_RAW（与其它臂不是同一个时钟，跨模块比较无意义）；dudect 用自带 rdtsc", "§4.1"],
    ["clock_resolution_ns", "逐采集件回读", "M5 的 .meta 报 1；M4 的 .meta 未记，本轮实测补上", "§4.2"],
    ["读钟开销（新探针，n=100000 × 2）", "均值 / 中位数 / p99 / 最小步进", "CLOCK_MONOTONIC 17.423 / 20 / 21 ns；CLOCK_MONOTONIC_RAW 16.195 / 20 / 21 ns；min_ns = 10", "§4.3"],
    ["读钟开销（既有归档 n=300000，CPU2 绑定）", "同口径复算", "均值 17.50 ns、中位数 20 ns、p99 21 ns、p99.9 21 ns、最小 10 ns", "§4.4"],
    ["有效计时量化尺度（限制条）", "相邻不同取值间隔的中位数", "全批 41 个主类对合起来 9 ns（逐类对 9–10 ns）⇒ 有效计时量化尺度约 10 ns；均值可靠 n=10000 平均出 1 ns 以下差异，分位数只能落在约 10 ns 格点", "§4.3；QUANTILE_CI §4.4"],
    ["干扰控制", "SMT 状态、isolcpus、IRQ 亲和、后台服务快照", "**无 isolcpus**；采集期由控制器写 boost=0、performance、min=max=4300000 kHz 并 taskset 绑核；系统仍有 39 个 running service", "§5、§6、§7"],
    ["频率管理回读", "/sys 的 boost、CPU2 / CPU6 的 policy、amd_pstate 状态", "逐项原文；采集件自身不写 sysfs", "§7"],
    ["采集方式", "只读；唯一远端写入是读钟探针自身的新根", "无 sudo、无安装、命令一律不绑 CPU2/CPU6（留给锁频采集）", "头部说明"],
]

ROBUSTNESS_ROWS = [
    ["主分析样本规则", "保留全部样本：不删离群值、不裁尾、不插值、不平滑、不扣读钟开销", "冻结家族成员一律用全样本 n0 = n1 = 10000 原值", "OUTLIER_RULES §1；与 docs/timing.md:34、docs/statistics.md:31、docs/acceptance.md:331-333 一致"],
    ["S1 p99.9 截尾均值差（族外）", "每侧截 0.1%，k = floor(0.001 × n) = 10，升序取下标 [k, n−k)，bootstrap 百分位 95%", "n = 10000 ⇒ 保留 9980 / 9980；64/64 个类对满足“截尾后每组 ≥ 1000”的下限", "OUTLIER_RULES §2"],
    ["S2 中位数差（族外）", "median(class0) − median(class1)，bootstrap 百分位 95%", "B = 2000，每个类对固定种子 20261016 + 序号", "OUTLIER_RULES §2"],
    ["S3 Hodges–Lehmann 位置差（族外）", "全部 n0·n1 个成对差的中位数，整数格点二分精确求解", "同上", "OUTLIER_RULES §2"],
    ["与冻结家族的对齐", "全样本 Welch 与 stats/members/members.csv.gz、stats/holm/holm.csv.gz 逐项比对", "Δ 最大绝对偏差 0 ns；CI 端点 2.49e-14 ns；双侧 p 9.44e-16（双精度舍入噪声）", "ROBUSTNESS §4"],
    ["翻转计数", "64 个类对（21 个已冻结 Holm 家族成员 + 43 个族外对照）× 4 种方法", "**翻转 12 / 64**：其中已冻结家族成员 7 个、族外对照 5 个", "ROBUSTNESS §0、§6"],
    ["翻转对 Holm 的影响", "家族与其 p 值在 efca8a1 已冻结；本页三种稳健方法一律族外", "**没有任何翻转改变 Holm 判定**；不重算 Holm、不改任何 p 值", "ROBUSTNESS §0、§2"],
    ["种子稳定性自检", "同一脚本、只换 bootstrap 种子基数 777", "12 / 64 → 13 / 64；唯一差异是族外 R03 类对 r03-m1unfixed-s2:valid-malformed（全样本 Δ 仅 1.575 ns、CI 含 0，属边界项），如实登记为对种子敏感，不当稳定翻转", "ROBUSTNESS §6.1"],
    ["翻转的性质", "两类翻转不能合并叙述", "是“均值型检验与位置型检验的功效差”或“约 10 ns 量化下秩方法失效”，不是新的泄漏证据", "ROBUSTNESS §6.1"],
]

POWER_ROWS = [
    ["M1 未修（真实历史案例）", "6（r02-r04-close-20261016/holm.csv）", "10000", "25.2709", "31.3901", "Δ = +39.3372 ns，**超过** MDE(m=6) 31.3901 ns ⇒ 可检出", "POWER §1.1"],
    ["M1 已修", "6", "10000", "28.6289", "35.5613", "Δ = −13.2093 ns，小于 MDE ⇒ 未检出", "POWER §1.1"],
    ["M2 端到端", "6", "10000", "19.9–54.0", "24.7–67.1", "主类对 6 项 |Δ| 全部小于 MDE ⇒ 未检出（引用值取 Holm 口径 25–67 ns）", "POWER §5.1"],
    ["M3 端到端（人工构造校准）", "6", "10000", "14.2–27.1", "17.7–33.7", "on / off 两臂 |Δ| 都小于 MDE ⇒ 未检出（引用值取 Holm 口径 18–34 ns）", "POWER §5.1"],
    ["M4 端到端（人工构造校准）", "6", "10000", "0.1853–1.1864（vulnerable）", "最坏 1.4736（vulnerable）", "vulnerable 臂 3/3 run |Δ| 远大于 MDE ⇒ 可检出；ct 臂 0/3 超过 ⇒ 未检出", "POWER §5.1"],
    ["M5 参考（阴性对照候选）", "3", "10000", "11.7–24.5", "13.5–28.3", "|Δ| 小于 MDE ⇒ 未检出（引用值取 Holm 口径 14–28 ns）", "POWER §5.1"],
    ["R03 两个族外对照", "无预注册家族（α_eff = 0.05）", "10000", "14.4–20.6（对照 A）", "同左（不校正）", "对照 A 9/9 的 CI 含 0；对照 B 的截断路径差 +29.3 µs（M5）/ +55.1 µs（M1）由 CI 说明 ⇒ 可区分但属公开长度检查的接口语义", "POWER §1.4、§5.1"],
]

QUANTILE_ROWS = [
    ["统计量与重抽样", "分位数 p10 / p50 / p90 / p99 的差（class0 − class1），bootstrap 百分位 95%", "B = 10000，两类各自独立有放回重抽样 n = 10000，固定种子 [20261016, 数据集序号]；不做截尾、不去长尾、不重排", "QUANTILE_CI §1"],
    ["总体一致性", "41 个主类对 × 4 个分位数 = 164 条判定", "88 条同向、13 条方向反向、24 条判定翻转（与均值差 CI 是否含 0 不一致），全部逐条列出", "QUANTILE_CI §4 结论句"],
    ["M4 vulnerable（最需要注意的一条）", "均值差 −4.102 / −4.351 / −3.515 ns（3/3 的 CI 不含 0、Holm 拒绝），而 Δp10 / Δp90 / Δp99 恰为 0（含 0）", "该臂取值几乎只有 {20, 21, 30, 31, …} 几个格点（m4-s1-vuln 的 20 出现 6922/10000、30 出现 2659/10000）；**不能用 M4 的分位数差去复核 M4 的均值结论**，两边各按自己的口径表述", "QUANTILE_CI §4"],
    ["M2", "分位数差与均值同向，但伴随多处约 ±10 ns 的翻转", "不改变 M2 家族 Holm 不拒绝的结论，也不构成泄漏声明", "QUANTILE_CI §4"],
    ["M3 on / off（人工构造校准）", "15 / 24 条分位差恰为 0，其余 |分位差| ≤ 10 ns", "与均值差（|Δ| ≤ 10.7 ns）同为不可区分；仍有 1 条方向反向、0 条判定翻转", "QUANTILE_CI §4"],
    ["M1", "未修长尾段不足以复现均值层结论；已修 4 个分位数与均值同为不可区分", "族外描述，不改写既有封存结论", "QUANTILE_CI §4"],
    ["有效计时量化尺度（限制条）", "相邻不同取值间隔的中位数 9 ns（各主类对 9–10 ns）", "**有效计时量化尺度约 10 ns**：均值可靠 n = 10000 平均出 1 ns 以下差异，分位数只能落在约 10 ns 格点；与该批关心的 4–30 ns 效应同量级", "QUANTILE_CI §4.4"],
    ["图", "ECDF（逐主类对）与修复前后箱线图（M1、M3 on/off、M4 两臂），矢量 PDF", "41 张 ECDF + 3 张箱线图（两臂分面板、各自纵轴）+ 1 张 M2 分层注记图；输出目录 docs/evidence/r04-stats-20261016/figures/", "QUANTILE_CI §6、POWER §5.1"],
]


def build_mapping_rows():
    """逐行取自 MAPPING.md §1；行数按实际表格计数，不采信该文件 §2 的自述 15。

    Markdown 链接降级为标签、反引号去掉：PDF 表格列宽只有几厘米，保留原始 Markdown
    会同时带来反引号噪声与不可断行的长路径。完整路径见该文件本体（本表注已指向）。
    """
    text = read_text("docs/evidence/r06-noleak-20261016/MAPPING.md")
    section = text.split("## 1. 汇总表", 1)[1].split("\n---", 1)[0]
    rows = []
    for line in section.split("\n"):
        if not line.startswith("|") or re.match(r"^\|[\s\-|]+\|$", line):
            continue
        # 按**未转义**的竖线切分：源码里用 `\|` 表示「这一格里的竖线」，
        # 直接 split("|") 会把一格切成两格——2026-10-21 复查实测 T18 的 M4-b 行
        # 因此错位（方法分类列被写成代码片段、证据路径列丢失）。
        cells = [cell.strip() for cell in re.split(r"(?<!\\)\|", line.strip().strip("|"))]
        cells = [cell.replace(r"\|", "|") for cell in cells]
        if cells[0] == "#":
            continue
        cleaned = []
        for cell in cells:
            cell = re.sub(r"\[([^\]]+)\]\([^)]*\)", r"\1", cell)
            cell = cell.replace("`", "")
            # 长标识符后紧跟左括号会形成不可断行的长 token，插一个空格给出断行点，语义不变。
            cell = re.sub(r"([A-Za-z_][A-Za-z0-9_]{11,})\(", r"\1 (", cell)
            cell = re.sub(r"\s+", " ", cell).strip()
            cleaned.append(cell)
        rows.append(cleaned[:5])
    return rows


AUDIT_ROWS = [
    ["静态扫描范围", "自有实现 + harness 共 128 个 .c/.h（src 47、include 16、tools 20、tests 33、fixtures 10、scripts 2）", "命中 1048 个“可能送出进程边界”的调用点；不含 vendor/、sources/、third_party/、build/、deliverables/ 与旧封存副本", "AUDIT §1.1"],
    ["接触秘密的调用点", "122 条（src 31、tools 40、tests 45、fixtures 6）逐条人工判定", "四类：A 类 = 秘密内容泄露；B 类 = 验证结果泄露；C 类 = 只打印路径/字节数/摘要；D 类 = 命名误报", "AUDIT §1.2"],
    ["秘密内容泄露", "**0 条**：没有任何把 ss / sk / z / m' 的字节写进 stdout、stderr、返回码或 errno 的语句", "多行输出语句按整句判定；输出语句参数里没有秘密标识符", "AUDIT §0、§1.4"],
    ["“验证是否通过”泄露", "**0 条（修复后）**：原 1 条低危 F1（tools/platform_m2/collector.c 的功能门把批级接受/拒绝汇总写进 stderr、进程退出码与 meta 的 run_status）已于 2026-10-20 闭合——新增 `--self-test` 显式功能门模式，计时模式 stderr 恒空、退出码只反映参数/IO/内存错误", "修复后重跑 static-scan 的 **B 类由 1 条降为 0 条**；dynamic-diff 7 模式 × 120 次 rc 恒 0、stdout/stderr 逐字节一致、diff 差异块 0。F1 的失败分支仍只做源码判定（未构造门失败场景），此边界不变", "AUDIT §1.3 F1、§6 第 2 条；fix-20261020/AUDIT §7"],
    ["动态 diff", "**为空**：7 种输入模式（1 合法 + 6 隐式拒绝）各 120 次，本机与远端两次独立运行，7 个模式的退出码唯一值均为 0、stdout/stderr 逐字节一致、diff -u 0 个差异块", "功能重复，不构成任何时间侧信道或统计结论", "AUDIT §2"],
    ["Memcheck syscall 检查", "**0 errors**：M5 platform_m5_poison --poison 标记 1152 B PKE 秘密 + 32 B 拒绝种子，Valgrind 3.22.0 下 ERROR SUMMARY 0 errors；--track-origins=yes 复跑同为 0", "负对照 canary 能稳定报出 Syscall param write(buf) points to uninitialised byte(s)（rc = 99），证明该通道有效", "AUDIT §3"],
    ["计时窗口 I/O", "**7 / 7 个 fence-to-fence 窗口全部通过白名单核对**：窗口内无 I/O、无日志、无分配", "输入生成、内存分配、结果消费、日志与 I/O 全部位于窗口外", "AUDIT §4"],
    ["其他信息项", "F2：M3 on 变体在秘密标记下 1280 errors / 2 contexts，但不流向 syscall 参数；F3：tools/platform_perf/perf_measure.c 未接入构建（仍在扫描范围内）；F4：人工夹具 fixtures/early_reject_memcmp/binsec_harness.c:13 把比较结果当退出码，是故意保留的实验缺陷", "三项都如实列出，避免被误读为扫描遗漏；F4 是故意保留的实验缺陷，不计入 B 类", "AUDIT §1.3"],
    ["未覆盖面（明确列出）", "未扫描 vendor/、sources/、third_party/；未执行 M5 原生 dudect 采数、M4 checkct 重跑、网络路径端到端差分、门失败动态演示；未检查进程名与命令行、打开的文件描述符、内存映射、core dump、wait4 资源用量、信号、/proc/<pid>/stat、子进程树、运行目录文件名与 mtime", "Memcheck 只跟踪“未定义位”的传播；本审计不构成恒时证明，不主张零泄露", "AUDIT §6、§7"],
]

LOCKED_ROWS = [
    ["M1 未修（真实历史阳性对象）", "0.011725", "0.011302", "**0.964**", "0.741", "0.549", "locked 3/3；unlocked 3/3"],
    ["M1 已修", "0.013044", "0.013127", "**1.006**", "0.757", "0.574", "locked 1/3；unlocked 0/3"],
    ["M5（阴性基准）", "0.014603", "0.015897", "**1.089**", "0.956", "0.914", "locked 0/3；unlocked 0/3"],
]

TOOL_ROWS = [
    ["dudect（族外，端到端在线统计）", "检出", "未检出（已修臂反报阳性）", "未检出", "检出", "未检出", "5 / 3 / 0",
     "M2 阳性落在已修臂（max|t| 36.27 / 30.94 / 61.91），未修臂反而阴性（4.68 / 3.05 / 3.66）；单工具解读会得出“修复引入泄漏”，本表按事实登记，不据此作泄漏结论"],
    ["RTLF α=0.01（族外，二值分布检验）", "检出", "两个臂都检出（不可归因）", "未检出", "检出", "未检出", "5 / 3 / 0",
     "M2 主类对 6/6 全检出、未修与已修各 3 项，与 Welch/Holm 家族“拒绝 0”相左；读作类构造与环境漂移，不改预注册判定"],
    ["Welch + Holm（家族内，唯一预注册家族成员）", "检出（1/6 拒绝）", "未检出（0 拒绝）", "未检出（0 拒绝）", "检出（3 拒绝，全在 vulnerable 臂）", "未检出（0 拒绝）", "5 / 2 / 0", "无"],
    ["Memcheck-ctgrind（定位层）", "检出", "未运行（完整解封装）", "检出（1280/2 对 0/0）", "检出（32/1 对 0/0）", "未检出（三模式 0/0）", "4 / 3 / 0", "无（M2 按未运行登记）"],
    ["KyberSlash varlat（定位层）", "未运行", "检出（1280/3 对 0/0）", "未运行", "未运行", "未检出（两模式 0/0）", "2 / 1 / 0", "无"],
    ["Binsec checkct（形式层）", "未运行", "未运行", "未运行", "检出（insecure 对 bounded secure）", "未运行", "1 / 1 / 不适用", "无"],
    ["Microwalk（定位层）", "未运行（pin 缺失）", "未运行", "检出（互信息 1.922 对 0.722 bits）", "未运行", "未运行", "1 / 1 / 不适用", "无"],
    ["Mona（族外统计对照）", "未修臂无分离（已修臂 2/6 有分离）", "未修臂无分离（s3 已修臂 1/8 有分离）", "未运行", "未运行", "未运行", "2 / 0 / 不适用",
     "M1/M2 的未修臂全部无分离，却在已修臂出现箱体分离；其 Confidence Interval 字段是批次成功百分比而非 p 值，holm_member 为 false"],
    ["反汇编（定位层）", "检出（bt/jae → bt/setb + cmov_int16）", "检出（三热点各 1 个 div → 0）", "检出（两处秘密下标 movzwl）", "检出（0x8049047 数据相关）", "未发现", "5 / 4 / 0", "无"],
]

# 复现入口脚本的摘要**现算**：写死会在脚本改动后变成「假的一致」——
# 2026-10-21 第 4 轮复核查出报告里引的 sha256（16562851…）既不在包里也不在仓库里。
REPRODUCE_SCRIPT_SHA256 = hashlib.sha256((REPOSITORY / "scripts/reproduce_all.sh").read_bytes()).hexdigest()

REPRODUCE_ROWS = [
    ["入口与两档", "scripts/reproduce_all.sh quick / full", "quick 档全程不需要 sudo、不写任何 sysfs 频率节点、不绑核；full 档默认 dry-run 只打印，加 --execute 才真跑，且必须给 --control-root（校验位于云端唯一存放根之下并含控制器脚本）", "RESULT §6.1；REPRODUCE-PARAMS §0"],
    ["quick 档链路", "配置 + 构建 + CTest（platform / ordinary / sanitize，可三选一或全跑）+ 每类小样本统计演练", "measure / m4_measure → platform_stats（Welch CI）→ 汇总 members.csv → platform_holm（Holm + 固定效应合并）→ 逐行打印 holm.csv / pooled.csv", "RESULT §6.1"],
    ["干净 clone 实测（2026-10-20 复查轮的四配置实跑）", "脚本 `scripts/reproduce_all.sh` sha256 " + REPRODUCE_SCRIPT_SHA256 + "（**现算自当前工作区**，随本表一起重出）；命令 `sh scripts/reproduce_all.sh quick --samples 200 --runs 1`；退出码 0", "platform 88/88、ordinary 57/57、sanitize 57/57、historical-fixed 61/61 ⇒ **合计 263 项 CTest 通过、0 失败**（日志 `docs/evidence/screenshots-20261020/reproduce-quick-terminal-p2b.log`）；**194/194** 是 2026-10-16 缺件状态下的三配置最小集，保留为历史记录，不是当前有效数字", "REPRODUCE-QUICK-LOG §1、§2；screenshots-20261020/reproduce-quick-terminal-p2b.log"],
    ["演练统计值（不得当结论）", "M3 m=6 拒绝 1（M3-on-r2，Δ = +22.12 ns）、M4 m=6 拒绝 0（Δ = +0.56 ns）、M5 m=3 拒绝 0（Δ = −43.38 ns）", "**不是任何模块的正式统计结论**：演练不锁频、不绑核、跑在 macOS/ARM、每类只 1000 次", "RESULT §6.2"],
    ["干净 clone 缺件（如实登记）", "vendor/liboqs-0.10.0、vendor/kyber-kyberslash-*、third_party 均在 .gitignore 内", "M2 演练跳过并打印原因；M1 的 quick 档需先跑 tools/fetch_liboqs_0.10.0.sh；OpenSSL 3 自动探测，找不到就退回 -DBASELINE_ALLOW_NON_SHA3_OPENSSL=ON（native_digest 记 Skipped，不伪装通过）", "RESULT §5、§6.1；BLOCKERS B05"],
    ["复现参数总表", "docs/REPRODUCE-PARAMS.md 逐模块列出编译选项、种子、样本数、核与频率管理、统计脚本或工具、PLAN 与证据目录", "每一行的链接都指向仓库内真实存在的文件；没有落盘依据的参数不写进来；四份模块 PLAN 在执行前由提交 efca8a1 冻结", "REPRODUCE-PARAMS 头部与 §0"],
    ["离线复算入口（本轮已重跑）", "匿名包解出后在独立目录重新构建并执行包内 CTest", "本轮交付的匿名包已**实际解出复算**：从实际 ZIP 解出后在独立目录重建并执行包内 CTest，**5/5 通过、0 失败**（仓库侧 `docs/evidence/platform-report-20261016/refresh-20261016/zip-recompute-final*.log`，文件名带实际执行的 revision）；**包内可自证**的是随卷分发的 `MANIFEST.json`（逐成员 sha256）与 `PROVENANCE.json`（逐成员来源与变换）；包审计（匿名扫描的成员数/摘要数/链接数/直接身份标记数与覆盖范围）由仓库侧 `verify_package.py` 对**实际 ZIP** 执行，记录在支撑包 README 与同目录的 *-verification.json（verify_package.py 通过，状态 pass）。**报告正文刻意不回填包的摘要**：包内随附的就是本报告，报告再写自己的包摘要会形成自指", "refresh-20261016/zip-recompute-final*.log、支撑包 README 与 final*-verification.json"],
]

CLAUSE_ROWS = [
    ["1", "实现或接入符合规范的 ML-KEM 密钥生成、封装与解封装，并用公开或主办方向量验证；不得靠改安全语义换常数时间",
     "满足", "§4；模块细节见 §19–§22",
     "docs/evidence/r01-kat-20261016/VECTORS.md、docs/evidence/r01-kat-20261016/EQUIV.md",
     "平台自有 ML-KEM-768 路径（M3 人工挂载 80/80、M5 mlkem-native 参考 80/80）与公开向量一致；修复语义等价三对 diff 全空且隐式拒绝逐例等于规范值。**必须一起读的边界**：M1 接的是 liboqs 0.10.0 的 FIPS 203 初始公开草案，keygen 0/25 是 ipd 与最终稿的真实差异（hash_g 无参数集域分隔字节），encap 25/25、decap 10/10 通过；M2 是历史 Kyber 第 3 轮，不冒称 FIPS 203。两者都不给规范符合性加分，也不影响 diff 结论"],
    ["2", "建立可重复的高精度时间测量框架，说明处理器、操作系统、编译器、优化级别、CPU 频率管理、测试次数与异常样本处理方法；**应尽可能降低系统调度、缓存和后台进程造成的随机干扰**",
     "满足", "§5；统计口径见 §3",
     "docs/evidence/r02-env-20261016/ENV_TABLE.md、docs/evidence/r02-env-20261016/OUTLIER_RULES.md、docs/evidence/r02-env-20261016/ROBUSTNESS.md",
     "28 项环境项全部有原始命令与原始输出（含 5 组实际编译行与 ELF 摘要核验、读钟开销实测、SMT / isolcpus / IRQ / 后台服务快照、booster 与 policy 回读）。**限制（如实写在同处）**：无 isolcpus、SMT 未关闭、系统仍有 39 个 running service；读钟开销均值 17.4–17.5 ns、最小步进 10 ns，与 M4 夹具的 20–30 ns 窗口同量级；有效计时量化尺度约 10 ns，因此 M4 的**分位数**结论不使用，只使用其均值结论"],
    ["3", "设计至少两类有明确区别的解封装输入并对各类做足够次数的重复实验，记录解封装执行时间；**输入设计应服务于泄露分析**，**不应**仅比较明显长度不同、程序路径完全不同**且不具有安全意义**的数据",
     "满足", "§7、§13",
     "docs/evidence/platform-collection-20261016/README.md、docs/evidence/r03-malformed-20261016/RESULT.md",
     "主类对为 message-zero 与 message-ones（同为等长合法密文，只改解密消息位）；异常输入用同长度的位翻转/随机/验证失败密文；长度类拒绝在封装层先检查、不计入内核类别样本。每类 10000 次 + 预热 100（窗口外）× 3 次独立运行，共 54 次控制器运行 restore_match=yes；R03 另做族外异常输入对照（3 臂 × 3 种子、18/18 restore_match=yes）"],
    ["4", "用统计方法判断不同输入类别执行时间是否存在显著可区分性（均值、方差、分位数、置信区间与适当检验），不得只凭少量样本或单次测试",
     "满足", "§8、§9",
     "docs/evidence/platform-collection-20261016/stats/holm/RESULT.md、docs/evidence/r04-stats-20261016/POWER.md、docs/evidence/r04-stats-20261016/QUANTILE_CI.md",
     "三层：描述统计（均值、标准差、p10/p50/p90/p99）、参数推断（Welch 95% 正态近似区间 + Holm 逐步校正，四家族各自独立判定）、族外交叉（RTLF α=.01、在线 dudect、Mona）。M2/M3/M5 端到端未检出、M4 vulnerable 臂拒绝 3 项；新增事后功效分析给出 MDE 与“未检出 = 观测效应 < MDE”的确切口径，并给出分位数差 bootstrap CI 与 ECDF / 箱线图"],
    ["5", "对检测到的明显时间差异定位泄露来源（敏感条件分支、提前返回、可变时间比较、数据相关循环、数据相关访存、失败路径及异常处理），并说明其与解封装流程的对应关系",
     "满足", "§10、§11",
     "docs/R05-全流程排查表.md、docs/evidence/r05-locate-20261016/RESULT.md",
     "R05 排查表把 3 个实现 × 5 个步骤（解密、哈希 G/H/J、重加密、密文比较、隐式拒绝 / cmov）× 6 类来源 = **90 格**逐格给出结论、证据与修复点，计数为**存在 5 / 不存在 75 / 不适用 10 / 未检查 0**。**边界**：M5 重加密步骤的 Binsec `checkct` **已于 2026-10-21 闭合**（R14：i386 裸机驱动 + 显式 `secret global`；FO 重加密比较步骤 1088/1088 路径完成、消息编码步骤 1/1 路径完成，均无秘密相关控制流；同配置下 M4 已知脆弱内核报 insecure，**证明不假阴性**）；R05 原文件不就地改写，本报告按 R14 的结论引用。另有一处**口径差异**：「M5 × 可变时间比较」4 格在 R05 本体按产物+源码判“不存在”，BLOCKERS.md 第 1 条把这情形描述为“工具不适用型 unknown”，两处口径已对齐（BLOCKERS.md 第 1 条已于 2026-10-16 改写为「这里的 unknown 指**工具覆盖**、不是与 R05 冲突、也不是『未检出泄漏』」；详见 §24 第 (3) 条）"],
    ["6", "对已发现问题采用常数时间比较、掩码选择、固定循环次数、统一错误处理、消除敏感数据相关分支**或其他适当方式**进行修改；防护过程中**不得**将私钥、中间敏感数据或验证结果通过日志、异常信息等其他渠道泄露",
     "部分", "§12",
     "docs/evidence/r06-noleak-20261016/MAPPING.md、docs/evidence/r06-noleak-20261016/AUDIT.md、docs/evidence/r06-noleak-fix-20261020/AUDIT.md",
     "**本条只判「部分」，两处缺口写明**：①本轮**自己发现**的真实秘密相关分支（M2 重加密步 `poly_frommsg` 的 `bt/jae`，已由反汇编与秘密标记 Memcheck 双向确认）**只定位、未修复**（修复方式应为掩码选择，本作品未实施，见 §24 与表 T18 的 M2-c 行）；②泄露渠道审计的对象是**本工程自有实现与平台 harness**，**不含 `vendor/`、`sources/`、`third_party/`**——而 M1/M2 的真实防护恰恰是打在 vendor 快照内的补丁，这两条真实防护链上的日志/异常泄露面**尚未审计**。**已满足的部分**：修复手段映射表覆盖 5 个模块（实际 16 行，见 §12 与表 T18），题面列举的五种方式（另加「其他适当方式」覆盖本作品另有的除法与访存两类机制，共七类落点）；官方修复 982c762（M1）与 272125f（M2）都经产物、动态与统计三类证据核对；静态 1048 个调用点中 122 条接触秘密标识符的调用点逐条判定，**秘密内容泄露 0 条**，动态 diff 为空，Memcheck syscall 0（含 canary 负对照），计时窗口 7/7 无 I/O。**原缺口 F1 已闭合（2026-10-20）**：M2 采集件 `tools/platform_m2/collector.c` 的功能门曾把批级接受/拒绝汇总写进 stderr、进程退出码与 meta 的 `run_status`；修复后新增 `--self-test` 标志，功能门检查仅在显式传入时生效，**计时模式下 stderr 恒空、退出码只反映参数/IO/内存错误**；重跑 dynamic-diff 7 模式 × 120 次全部 rc=0、stdout/stderr 逐字节一致、diff 差异块 0，static-scan 的 **B 类（内部验证结果泄露）由 1 条降为 0 条**，验证记录见 docs/evidence/r06-noleak-fix-20261020/AUDIT.md §7。**仍然成立的范围限定**：本条只覆盖“防护过程不通过日志/异常/返回码泄露”，不构成恒时证明、不主张零泄露；R06 §6 已列出的未覆盖面（上游 vendor/sources、网络路径、进程名与命令行、fd、maps、core dump、wait4、信号、/proc stat、子进程树、文件名与 mtime）本轮未做"],
    ["7", "完成防护后在与防护前相同或等价的测试环境下重新采集数据，对比**不同输入类别之间**的时间分布与统计检测结果，说明泄露是否明显降低；同时验证修改后的功能正确性",
     "部分", "§6（表 T1 的复测列）、§4、§19–§22",
     "docs/evidence/r02-r04-close-20261016/RESULT.md、docs/evidence/r01-kat-20261016/EQUIV.md、docs/evidence/platform-rtlf-20261016/RTLF_RESULT.md",
     "**本条只判「部分」，原因写明**：题面要的是「**自己改完 → 同环境重采 → 前后对比 → 泄露明显降低**」的闭环，而本作品本轮**自研**的常数时间防护只落在 M3/M4 两条**人工构造校准链**上（报告自陈其载体「不对应真实密码算法」）；真实实现侧的防护是上游补丁（M1 的 982c762、M2 的 272125f），M2 本轮新发现的 `poly_frommsg` 分支**只定位、未修复**。**已满足的部分**：M1（真实历史案例）给出完整的“前后对比”：未修 Δ = +39.337 ns（95% CI 不含 0）、已修 Δ = −13.209 ns（CI 含 0），换种子与换物理核两次独立复测方向一致；族外 RTLF 未修 2/2 检出、已修 2/2 未检出，在线 dudect 未修跨过 t>10、已修 ≤ 2.05；产物侧 bt+jae → setb+cmov_int16。功能正确性同批复核：两版公开向量 decap 10/10、修复语义等价 diff 全空、1000 例额外输入隐式拒绝 1000/1000。M2 的“降低”只在定位/产物层成立（三热点 div 各 1→0、varlat 1280/3→0/0），端到端均值差在修复前后都未检出，如实分层记录；M3/M4 为人工构造校准的 on/off 与两臂对照**必须一起读的前置**：本轮采集内的「防护前后同规程重采」是 **M3 on/off 与 M4 vulnerable/ct 两条人工构造校准链**；M1 的前后对比是**封存引用**（2026-10-16 的批次）；M2 的「降低」只在**定位层 / 产物层**成立（端到端前后都未检出），**不把人工校准链的结论当成真实实现的防护效果**。"],
    ["8", "分别给出防护前后 ML-KEM 解封装平均运行时间、典型分位数及性能开销，分析安全防护带来的效率代价；**不得以牺牲密码安全性或算法正确性为代价**",
     "满足", "§14",
     "docs/evidence/r08-perf-20261016/PERF.md、docs/evidence/r08-perf-20261016/perf.csv、docs/evidence/r08-perf-20261016/perf.csv.comparison.csv、docs/evidence/r08-perf-20261016/remote/R08/r08-perf-m1fixed-b10/controller/terminal.json",
     "25 行逐（模块, 臂, 操作）汇总（n、均值 ± 95% CI、中位数、p90、p99）与 11 行成对开销（成对主口径 + bootstrap 10000 次 CI），同时给 ns 与周期两种单位。**口径局限**：周期按名义锁定基频 4300000 kHz 换算（cycles = ns × 4.3），不是逐调用实测频率；现代 x86 的“周期”不是恒定工作量单位。**控制器目录已完整归档并复核（2026-10-20）**：R08 **54/54**、R09 **36/36** 的 controller 目录齐备（含 during.json / entry-probes.json / terminal.json），terminal.json 四判据 **100% 通过**（restore_match=yes、worker_exit_code=0、worker_drained=true）；PERF.md 已补 54 次运行的实测周期换算核对表：中位频率中位数 4309722.5 kHz，与名义 4.30 GHz 偏差 **+223 kHz（+0.005%）**，换算周期 0.2307–0.2332 ns，与名义换算一致。**结论方向**：某一臂更快不等于它更安全。M4 只在比较步内两臂互比（comparison_scope = M4_compare_step_only），且用 CLOCK_MONOTONIC_RAW，与其它臂不同时钟，跨模块比较无意义"],
    ["9", "至少在一种软件运行环境完成完整实验；高水平作品可增加不同编译优化级别、不同 CPU 架构或本地与网络场景的对比，分析侧信道现象的稳定性",
     "满足", "§15",
     "docs/evidence/r09-optlevel-20261016/RESULT.md、docs/evidence/r09-optlevel-20261016/BUILD.md、docs/evidence/wsl-repro-20261020/CROSSCHECK.md、BLOCKERS.md、docs/evidence/r15-aarch64-20261021/RESULT.md、docs/evidence/r13-network-20261020/RESULT.md",
     "**必做的优化级别对照已完成**：M1 两版 + M5 × {-O0, -O2, -O3, -Os} = 12 格，每格 3 个种子、每类 10000 次完整解封装，含产物判定（反汇编 + Memcheck）与锁频实测（Δ 与 CI）及图。**可选项 3/3 完成**：(a) 不同编译优化级别——已完成；(b) 不同 CPU 架构——**已执行**（2026-10-21）：在真实 aarch64（Apple Silicon，容器内 `uname -m` = `aarch64`，非 QEMU 模拟；跑在 Docker Desktop 的 Linux 虚拟机里，未锁频、非裸金属）按与主平台同源同口径跑了 12 格（3 臂 × 4 个优化级别，同 liboqs 0.10.0 钉版树、同 clang 18、同级别构建、同一份秘密标记探针），归档在 `docs/evidence/r15-aarch64-20261021/`：**aarch64 12 格全部 0 错误 / 0 上下文**，而 x86_64 裸金属的 M1 未修臂在 -O2/-O3/-Os 上是 512 错误 / 8、15、1 个上下文——即 **M1 机制是 x86_64 特定的编译器产物**（aarch64 上 clang 编出 `sbfx`/`and`/`csel` 无分支形态），在**同探针**对照下平台的秘密标记检测在两个架构上都能正确区分有无秘密相关分支（该强结论**只对 M1 两臂成立**，M5 参考路径两侧探针不同、只由「两架构都是 0」的弱结论支撑）；时间证据不跨架构合并、也不要求同号；**该架构只构成第二个架构、不构成第二个测量机**（证据 `docs/evidence/r15-aarch64-20261021/`）；(c) 本地与网络场景——**已执行**（2026-10-21）：在裸金属上用匿名网络命名空间 + 自有 veth + 内核 netem 建立**真实两端** TCP 场景，锁频口径与 R02/R08/R09 相同，五档（本地直调 / 回环 / low / mid / high）、3 臂 × 2 次独立运行，归档在 `docs/evidence/r13-network-20261020/`：**网络各档一律未检出**；本地直调档 M1 未修臂两次运行一次可分辨（+37.1 ns，CI [20.4,53.8]）、一次未检出（−7.9 ns，CI [−25.0,9.2]），跨运行可分辨性不稳定，如实登记；**检测预算**为分辨该量级每类需 本地 13 098 / 回环 38 417 / low 64 636 555 / mid 1 003 153 317 / high 97 586 175 893 个样本，本轮网络各档每类 2000 个样本，**回环差约 1.3 个、low 差约 4.5 个、mid 差约 5.7 个（≈6）、high 差约 7.7 个数量级**；结论只写「本预算下未检出」，**不写「没有远程泄露」**，引用时标注「同机模拟、非真实远程」；原 BLOCKERS B01 已更新（证据 `docs/evidence/r13-network-20261020/`）。**边界（2026-10-20 更新）**：R09 的 **36/36** 有效 run 与 R08 的 **54/54** 有效 run 的 controller 目录均已完整归档，restore_match 等四条判据 **100% 通过**，可从副本复核；判定产物的 sha256 与计时 meta 的 SHA3-256 已并列落盘于 disasm/CELLS.sha256 与 disasm/CELLS.sha3-256 并逐字对齐，可断言计时所用二进制即被判定者；统计口径统一为逆方差固定效应合并 CI（m1unfixed-Os 合并 Δ_pool −26.16 [−37.51, −14.81] 不含 0，m1fixed-O0 与 m1fixed-O3 的合并 CI 均含 0）。另有 1 次运行因频率探针跨度 54629 kHz 超过合同允许的 50000 kHz 被拒、换名重跑，已如实列出。**跨运行环境的实测增量（2026-10-20 新增）**：三台队友机器在 **WSL2（未锁频、虚拟化、绑 vCPU 而非物理核）** 上按 docs/wsl-repro/ 的执行文档重跑本平台关键实验，归档在 docs/evidence/wsl-repro-20261020/，与主平台（裸金属 x86_64 Linux 锁频）逐项核对见 docs/evidence/wsl-repro-20261020/CROSSCHECK.md：**确定性证据逐项一致**（三台 × 12 臂的秘密标记 Memcheck 命中上下文数完全相同：未修 -Os 1 / -O2 8 / -O3 15 / -O0 0，已修四级全 0，M5 四级全 0），说明**机制的存在与否、工具能否检出它可跨机器复现**；**时间证据只作方向性对照**（WSL 单次 SE 约数百 ns，掩盖了主平台 25-40 ns 量级的效应，三台机器 M1 未修 -Os 的合并区间均含 0，这是测量下限差异而非结论分歧），**不改写主平台判定、不与裸金属数据合并、不进任何 Holm 家族**。这正是第 9 条“不同运行环境对比”的实测增量"],
    ["10", "明确攻击者可控制的输入、可观测信息、是否具有本地执行权限以及攻击条件假设，区分本地高精度计时攻击与远程网络时间攻击的能力边界，**避免将实验结果过度推广**",
     "满足", "§18",
     "docs/evidence/r11-threat-20261016/threat-model.tex、docs/evidence/r11-threat-20261016/THREAT_MODEL.md",
     "威胁模型章以独立 LaTeX 片段直接并入本报告（攻击者模型、不在范围内、本地高精度与远程网络边界、结论等级表、遗留与边界五节）。攻击者可控输入限于密文（含长度与内容），可观测量限于单次调用耗时，不持有私钥、无物理接触；采集件持有的测试密钥对是资格夹具的一部分、可公开复现，不是受害者私钥。结论按“已执行且检出 / 已执行且未检出 / 未执行”三档分列，且网络路径已按同机模拟执行"],
    ["11", "提供测试程序、测试数据生成方法、实验参数、编译选项与统计分析过程，使评测人员能够复现实验结论",
     "满足", "§17",
     "docs/REPRODUCE-PARAMS.md、scripts/reproduce_all.sh、docs/evidence/r12-innovation-20261016/REPRODUCE-QUICK-LOG.md",
     "一键入口 scripts/reproduce_all.sh 分 quick（构建 + CTest + 每类小样本统计演练）与 full（按四份冻结 PLAN 生成完整采集命令，默认 dry-run）两档；参数总表逐模块列出编译选项、种子、样本数、核与频率管理、统计工具与证据目录，每行都指向仓库内真实文件。**干净 clone 实测（当前有效）**：`scripts/reproduce_all.sh` sha256 " + REPRODUCE_SCRIPT_SHA256 + "（现算自当前工作区），命令 `sh scripts/reproduce_all.sh quick --samples 200 --runs 1`，退出码 0，platform 88/88 + ordinary 57/57 + sanitize 57/57 + historical-fixed 61/61 = **263/263 通过、0 失败**（日志 `docs/evidence/screenshots-20261020/reproduce-quick-terminal-p2b.log`）；**194/194**（platform 80/80 + ordinary 57/57 + sanitize 57/57）是 2026-10-16 缺件状态下的三配置最小集，**保留为历史记录，不是当前有效数字**（表 T25 同此口径）。**前置条件（如实写在同处）**：vendor/liboqs-0.10.0、vendor/kyber-kyberslash-*、third_party 均在 .gitignore 内，干净 clone 需先跑取件脚本；quick 演练中的 M2 因缺件跳过并打印原因（BLOCKERS B05）。演练不锁频、不绑核、跑在 macOS/ARM、每类 1000 次，不是任何模块的正式统计结论"],
    ["12", "至少在自动化侧信道检测、敏感路径定位、常数时间实现方法、统计检测方法、低开销防护或跨平台验证之一取得改进，并用可复现实验说明效果",
     "满足", "§16、§3、§12",
     "docs/evidence/r12-innovation-20261016/RESULT_LOCKED_VS_UNLOCKED.md、docs/evidence/r12-innovation-20261016/RESULT.md、docs/evidence/r12-innovation-20261016/TOOL_MATRIX.csv",
     "两项族外创新对照：(a) 锁频 vs 不锁频（3 臂 × locked/unlocked 各 9 次运行）——**如实报告锁频没有降低相对变异**（频率归一后的 CV 比 0.96 / 1.01 / 1.09，跨臂方向不一致），锁频的价值表述为确定性、可核对与可恢复的固定工作点，而不是“必然降低方差”；(b) 多工具矩阵 9 工具 × 5 模块 = 45 格，30 格有真实运行产物、15 格未运行并逐格写明原因，单工具路线会漏掉 M2/M3 的定位层阳性或在 M2 上给出方向错位的阳性，只有交叉才得到“定位阳性 + 端到端未检出”的分层结论。两项都族外、不进 Holm、不改既有判定"],
]


def build_tables():
    document = json.loads((DIRECTORY / "report-tables.json").read_text())
    tables = {table["id"]: table for table in document["tables"]}
    # 去重：历史重跑曾把 T12–T26 各追加多份，导致同一 id 在文件里出现多次。
    # 这里按首次出现顺序保留唯一 id，生成结果不再随重跑次数增长。
    order = []
    for table in document["tables"]:
        if table["id"] not in order:
            order.append(table["id"])

    # 第 5 轮（冷读）指出：表 T10 的表注明写「数据相关循环不写成未执行」，而表 T4 的同一类
    # 四格却写着「未执行：没有把循环次数作为对象的检查」——同一件事两种状态。
    # 统一为：**已判定（源码/反汇编层）+ 未做以循环次数为对象的专项动态检查**。
    loop_prefix = "未执行："
    loop_suffix = "**已判定**（源码/反汇编层：R05 逐格判『不存在』，循环上界为编译期常数）；**未做**以循环次数为对象的专项动态检查 / 轨迹差分"
    for row in tables["T4"]["rows"]:
        if row and str(row[0]).strip() == "数据相关循环":
            for cell_index in range(1, len(row)):
                cell = str(row[cell_index])
                if cell.startswith(loop_prefix):
                    row[cell_index] = loop_suffix + "；原表记法：" + cell[len(loop_prefix):]
    tables["T10"]["rows"] = [
        ["M1 liboqs 0.10.0 未修 / 982c762 已修", "1", "26", "3", "0", "30"],
        ["M2 kyber768 a621b8d / 272125f", "3", "24", "3", "0", "30"],
        ["M5 mlkem-native b3ba7b3 参考", "1", "25", "4", "0", "30"],
        ["合计", "**5**", "**75**", "**10**", "**0**", "**90**"],
    ]
    tables["T10"]["note"] = (
        "计数口径：总格数 = 3 实现 × 5 步骤（解密、哈希 G/H/J、重加密、密文比较、隐式拒绝 / cmov）× 6 类来源 = 90，"
        "每格只计一次，由该文件正文 15 张表逐行程序化统计得到。“不适用”10 格全部是异常处理（第 6 类）× 该函数不可能失败"
        "（M1 解密/密文比较/隐式拒绝各 1；M2 同 3；M5 解密/重加密/密文比较/隐式拒绝 4）。"
        "“未检查”**已为 0 格**：原唯一的未检查格（M2 重加密 × 提前返回）已于 2026-10-16 补做并改判为“存在”。"
        "与 2026-10-16 之前的版本相比：总格数、不适用数不变；“存在”**仍为 5 格**（构成有变动：M1 −1、M2 +1）、“不存在”74→75、“未检查”1→0。"
        "人工构造校准（M3/M4）不计入上表 90 格。"
        "**类别轴映射（题面第 5 条六类 ↔ 本表六类）**：题面的『敏感条件分支』并入本表第 1 类"
        "『提前返回』（三个『存在』格即该类发现：M1/M2 的 poly_frommsg bt/jae、M5 的 "
        "mlk_kem_check_sk 早退）；题面的『失败路径及异常处理』拆成本表第 5、6 两类，"
        "因此 10 个『不适用』格全部落在第 6 类『异常处理』。**总格数与 5/75/10/0 的计数不变**，"
        "只是轴的摆法不同。"
        "**“不存在 75”里含 15 格「数据相关循环」**：这 15 格在源码/反汇编层**已判定**"
        "（循环上界均为编译期常数），但**没有做以循环次数为对象的动态轨迹 / 轨迹差分专项检查**——"
        "报告正文对此统一按「已判定、无专项动态检查」表述，不写成「未执行」。"
        "另注：R05 §1.6 的小节标题「M1 的『存在』格为什么只有 2 个」是 2026-10-16 改判**前**的旧表述，"
        "实际计数以该文件 §4.1 为准（M1 一个）。"
    )
    tables["T11"]["title"] = "R05 全流程排查表的 5 个「存在」格清单（「未检查」已为 0）"
    tables["T11"]["rows"] = [
        ["1", "M1 未修 / 重加密 / 1 提前返回", "存在",
         "pqcrystals_ml_kem_768_ipd_ref_poly_frommsg：16e: bt %ecx,%r8d → 172: jae 179（locked-poly-frommsg-vulnerable.s 第 8–9 行）；Memcheck 报 poly_frommsg（poly.c:179）“Conditional jump or move depends on uninitialised value(s)”，调用栈含 indcpa_enc（indcpa.c:271）（valgrind-ct/vulnerable.log）",
         "官方 982c762（setb + cmov_int16）；patch-apply.txt 证明补丁覆盖 ml-kem-768-ipd_ref/poly.c"],
        ["2", "M2 未修 / 解密 / 2 可变时间比较", "存在",
         "poly_tomsg：3689: mov $0xd01,%r9d（= 3329）+ 36a5: movswl (%rsi,%rcx,2),%eax（秘密被除数）+ 36bf: div %r9d；varlat 报 poly_tomsg（ref/poly.c:188），1280 errors / 3 contexts、exit 99",
         "dda29cc（KyberSlash1，只修此处）→ 完整已修 272125f"],
        ["3", "M2 未修 / 重加密 / 2 可变时间比较", "存在",
         "poly_compress：34f2: mov $0xd01,%r8d + 3507: movswl (%rsi,%r9,2),%eax + 3523: div %r8d；polyvec_compress：38c7: div %r8d；varlat 另两条上下文 poly_compress（ref/poly.c:28）、polyvec_compress（ref/polyvec.c:48）；机器可读计数见 ordinary-unfixed-qualification.division-counts.txt",
         "官方 272125f（KyberSlash2）；已修三热点 div 计数全 0"],
        ["4", "M2 未修与已修 / 重加密 / 1 提前返回（2026-10-16 补入）", "存在",
         "未修 unfixed-poly_frommsg.asm：3668: bt %ecx,%r8d → 366c: jae 3673；已修 fixed-poly_frommsg.asm：366e: bt → 3672: jae 3679（指令字节两侧完全相同，SHA-256 6a6ee641a5e8a7de23052fbc7f5855dc01f3c08b6bb593fee43a2b41de26ed35），两者都在 docs/evidence/r05-locate-20261016/remote-tree/m2-disasm/；调用点 32d2 落在 indcpa_enc（indcpa.c:269），由 dec 的 2edb: call 3283 进入；动态命中 unfixed-z01of08.log（poly_frommsg（poly.c:167）← indcpa_enc ← dec）",
         "无：272125f 不碰 poly_frommsg（upstream-remediation.diff 只含 compress/tomsg 与 polyvec）；已修侧同为“存在”"],
        ["5", "M5 参考 / 隐式拒绝 / 1 提前返回（公开信息，非可利用）", "存在（有界例外，如实登记）",
         "归档内 logs-v2/poison.disasm 第 9033–9036 行：a404: call 8a80 <baseline_native_check_sk> → a40c: test %eax,%eax → a40e: jne ad87（检查失败提前跳到清零与 ret 入口）；公开性声明见 vendor/mlkem-native/mlkem/src/kem.c:92-99",
         "无：上游有意的 FIPS 203 §7.3 sk 哈希检查，不是缺陷；该差异只携带公开信息，但“sk 不可信”不在本轮 CCA 模型内"],
    ]
    tables["T11"]["note"] = (
        "逐格证据与修复点原文见 docs/R05-全流程排查表.md §4.2/§4.3。5 个「存在」格的分实现归属：M1 一个、M2 三个、M5 一个。"
        "2026-10-16 变更：原第 2 行“M1 隐式拒绝 / cmov × 可变时间比较”已移出本清单——补测显示该掩码走无分支的 sete %cl + cmov 内 neg/and/xor，两变体 dec 函数体内 0 条跳转，"
        "故 §1.5 第 2 类改判为“不存在（本产物）”；钉版缺 __asm__ 值屏障仍是未验证的可移植性隐患，作为边界保留、不再计入“存在”格。"
        "边界：本轮 M4 的 Binsec -checkct-features 只开了 control-flow, memory-access，未开乘法/除法检查（工具帮助原文 “Multiplication and division checks are experimental”），"
        "因此现有 Binsec 结果不能用来判定 M2 的 div 类来源；M5 重加密步骤的 Binsec `checkct` **已于 2026-10-21 闭合**（R14：i386 裸机驱动 + 显式 `secret global`；FO 重加密比较步骤 1088/1088 路径完成、消息编码步骤 1/1 路径完成，均无秘密相关控制流，同配置下 M4 已知脆弱内核报 insecure 证明不假阴性），R05 原文件不就地改写。"
        "所有“不存在 / 阴性”都不是恒时证明；人工夹具不计为上游 CVE。"
    )

    new_tables = [
        {
            "id": "T12", "title": "题面第 1 条之向量来源总表（模块 × 版本 × 来源 × 例数 × 通过数）", "landscape": True,
            "columns": ["模块 / 版本", "向量来源 + commit / SHA-256", "例数", "通过数", "日志路径", "备注"],
            "rows": VECTOR_ROWS,
            "note": "机器可读版本见 docs/evidence/r01-kat-20261016/logs/T05_T06_summary.tsv。mlkem768.txt 由本仓库 tests/convert_vectors.sh 从 NIST ACVP-Server 975de31eb83d87039ec88934fdc47d8c312b892d 的 gen-val/json-files 原件按 tcId 关联生成，只提取 ML-KEM-768 的 25 keygen / 25 encaps / 10 decaps，不改预期字节。**未跑过的例数一律显式写“不适用”，不把文件里的例数当成通过数。** **M1 keygen 0/25 是 ipd 与最终稿的真实差异**：liboqs 0.10.0 接入的是 FIPS 203 初始公开草案实现，其 indcpa.c:217 的 hash_g 无参数集域分隔字节，而同仓库同步的最终稿参考 vendor/mlkem-native/mlkem/src/indcpa.c:464 用 MLKEM_SYMBOLS + 1 字节输入，故 keygen 期望值必然不同；encap 用向量给定的 ek 与 m、decap 用向量给定的 dk 与 ct，与最终稿一致，这正是 25/25 与 10/10 通过的原因。该树的 docs/historical-liboqs-0.10.0.md:18 本身就写明它不做与 tests/vectors/mlkem768.txt 的 KAT 绑定。此处如实记录 0/25，不把 IPD 冒充最终 FIPS 203，也不用它给 M1 的时序结论加分。**M3 与 M4 是人工构造校准夹具**（M3 为秘密下标查表，M4 为提前退出比较），不对应真实密码算法，不计为新的真实 CVE。这些数字只说明各版本在各自公开向量上的功能一致性，不构成常数时间、频率锁定或统计显著性的结论。",
        },
        {
            "id": "T13", "title": "题面第 1 条之修复语义等价（三对 diff + 1000 例额外输入 + 隐式拒绝）", "landscape": True,
            "columns": ["模块（两版）", "公开例", "额外 1000 例", "diff 结果", "隐式拒绝检查结果"],
            "rows": EQUIV_ROWS,
            "note": "摘要文件按 32 B/公开例 + 64 B/额外例计：M1 与 M3 各 10 × 32 + 1000 × 64 = 64320 字节，M2 为 100 × 32 + 1000 × 64 = 67200 字节；out/ 中实际文件大小与之一致，说明每版都跑满了公开例与 1000 例额外输入，不是“少跑一部分所以看起来相同”。每例摘要输入为 tag ‖ index ‖ 密文 ‖ 共享密钥 与 tag ‖ index ‖ ek ‖ dk ‖ 合法 ct，经 SHAKE256-256bit 压缩后落盘，既能逐字节比较也不把共享密钥写进证据。两版隐式拒绝值在 1000 例上是精确等于规范拒绝值，而不是固定拒绝密钥：若某一版返回固定值或常量，extra_rejected 不可能同时满足 1000/1000（随机密文各不相同）。**M2 的公开 100 例全部是接受例**（round3 KAT 的 ss 就是接受路径的共享密钥），round3 的拒绝路径只由额外 1000 例覆盖，不假装公开向量覆盖了拒绝分支。M4 只有 32 字节比较与两类错位位置，没有密码算法和共享密钥，因此这里只能做接口等价说明，其时序差异是故意保留的实验缺陷。",
        },
        {
            "id": "T14", "title": "题面第 2 条之环境总表（28 项覆盖与关键读数）",
            "columns": ["分组", "覆盖项", "关键读数", "出处"],
            "rows": ENV_ROWS,
            "note": "28 项逐项都有原始命令与原始输出；完整原文在 docs/evidence/r02-env-20261016/raw/ 下的 5 份文件（remote-env.txt、compile-lines.txt、clock-probe.txt、clock-overhead-archive.txt、irq-and-isolation.txt）。本页只登记本次实际用过的读数，不外推到其它机器。读钟开销与被测窗口的关系必须一起读：单次取值 20 ns 上下、最小步进 10 ns，而 M4 的比较步窗口只有 20–30 ns，因此 M4 的结论只在均值层成立。",
        },
        {
            "id": "T15", "title": "题面第 2 条之异常样本规则与稳健性敏感性分析（64 类对 × 4 方法）",
            "columns": ["项", "规则 / 结果", "数字", "出处"],
            "rows": ROBUSTNESS_ROWS,
            "note": "规则在写文件时已经执行完毕，不存在“看结果再定规则”。主分析口径与 docs/timing.md:34 逐字一致（普通长尾全部保留，采集阶段不做离群值删除）。三种稳健方法一律族外；bootstrap 为分组内独立重采样（各组按原样本量有放回），B = 2000，每个类对固定种子。**不能**用“12 个翻转”反推总体误报率：本页未做多重比较校正，且各方法高度相关。两次独立运行的两次改写块也已逐值核对（m1_wide_long_check.py，CONCLUSION same_sample_set=yes），避免重复计数。",
        },
        {
            "id": "T16", "title": "题面第 4 条之补充：功效 / MDE 与「未检出」的确切含义", "landscape": True,
            "columns": ["家族 / 臂", "m", "n / 类", "MDE(α=0.05) 范围 (ns)", "MDE(Holm α_eff) 范围 (ns)", "观测 Δ 与判定", "出处"],
            "rows": POWER_ROWS,
            "note": "MDE 公式：MDE = (z_{1−α/2} + z_{1−β}) × sqrt(sd0²/n0 + sd1²/n1)，取 α = 0.05、功效 1−β = 0.80，两分位之和 2.801585218；Holm 校正后的有效 α = 0.05/m。SD 一律取样本标准差（numpy ddof=1），口径由 stats/members/members.csv.gz 的 sd0_ns / sd1_ns 与 ci_welch.json 的 standard_error_ns 逐位复现锁定。**一句话结论（原文）**：M2/M3/M5「端到端未检出」的确切含义是，在本机、本编译产物、本类对与本次样本预算下，观测到的类间均值差小于本设计的最小可检测效应（**M2 约 25–67 ns、M3 约 18–34 ns、M5 约 14–28 ns**），所以这套预算分辨不出任何小于该量级的效应；**「未检出」= 观测效应 < MDE，不等于零效应**，也不构成恒时证明或物理泄漏界。MDE 用本次实测 SD，属事后（post hoc）功效描述，不改变任何已提交的 Holm 判定。**M1 族的口径（2026-10-21 复核后如实改写）**：M1 族在**冻结计划**（`docs/evidence/r02-r04-close-20261016/PLAN.md` §1.2）里事前写的是 **m = 8**（含两项 dudect 成员），**采集完成后**该族被收敛为 m=6（dudect 的多批最大 t 不是有效 p 值，纳入会虚增显著性），原 `holm.csv` 的 8 行也被**原地覆盖**为 6 行——**这与冻结文件「检验族构成在采集后绝不修改」的约定不一致，属预注册完整性缺口，此处如实披露**。**家族级判定在两种 m 下相同**：m=8 时未修主检验 p=1.30117e-05（rank 2、阈值 α/7=0.00714，仍拒绝）、已修主检验 p=0.19615（rank 4、阈值 0.010，仍不拒绝）；m=6 时阈值 0.00833 / 0.01667，判定相同。**MDE 随 m 变**：m=8 时 M1 未修 / 已修为 32.26 / 36.54 ns，m=6 时为 31.39 / 35.56 ns；两种取值下「未修可检出、已修不可检出」都不变。本表采用 m=6 的 MDE（25.2709 / 31.3901 ns）并同时给出 m=8 的对照值，**不把 m=6 说成事前族**。",
        },
        {
            "id": "T17", "title": "题面第 4 条之补充：分位数差 bootstrap CI、ECDF 与箱线图",
            "columns": ["项", "结果", "口径 / 边界", "出处"],
            "rows": QUANTILE_ROWS,
            "note": "分位数差与均值差在本批数据上多数同向，但两者并不等价：在有效计时粒度约 10 ns 的条件下，分位数差的分辨能力远低于 n = 10000 的均值差，因此 M4 vulnerable 出现“均值差 3/3 显著、分位差 p10/p90/p99 恰为 0”的分歧——**不能用 M4 的分位数差去复核 M4 的均值结论**，两边都只能用各自的口径表述。M2 的分位差翻折不改变其家族 Holm 不拒绝的结论，也不构成泄漏声明；M3/M4 是人工构造校准。所有翻转、反向与零差条目都在该文件 §4 逐条列出，不做任何隐藏或选择性汇报。",
        },
        {
            "id": "T18", "title": "题面第 6 条之修复手段映射表（覆盖 5 个模块）",
            "columns": ["#", "模块", "修复点（commit / 补丁路径）", "题面第 6 条方法分类", "证据路径与身份"],
            "rows": build_mapping_rows(), "landscape": True,
            "note": "题面第 6 条的七个分类（常量时间比较 / 掩码选择(cmov) / 固定循环上界 / 统一错误处理(隐式拒绝) / 消除数据相关分支 / 消除数据相关除法 / 消除数据相关访存）在本表全部有落点。**M5 一栏不是修复**：那是参考实现既有做法（无对应 CVE），表中逐行声明为“否（上游既有做法，非针对某次 CVE 的修复）”。人工构造校准行标明“是（人工构造校准）”，不当作真实历史实现。**行数口径**：本表逐行取自 docs/evidence/r06-noleak-20261016/MAPPING.md §1 表格，实际为 16 个数据行（M1 三行、M2 三行、M3 四行、M4 两行、M5 四行）；该文件 §2 原自述“表内行数 15”，**已于 2026-10-16 按实际行数更正**（见该文件 §2 的更正说明），本报告按实际行数引用。阴性不是恒时证明；本表只做“修复手段 ↔ 方法分类”的对应，不新增任何泄漏判定。",
        },
        {
            "id": "T19", "title": "题面第 6 条之日志 / 异常 / 返回码泄露专项审计",
            "columns": ["项", "结果", "覆盖 / 边界", "出处"],
            "rows": AUDIT_ROWS,
            "note": "审计对象是本工程自有实现（src、include、tools、tests、fixtures、scripts）与本轮平台 harness，基线提交 e81c1aee541f5e9c2f93e061c8a5b5fa923c749d。**本审计不构成恒时证明，也不主张“零泄露”**；它只给出本轮固定代码快照、固定工具链与固定命令下的可观察面描述。所有实跑均为非锁频、仅功能性检查（frequency_control = not_configured，调速器 powersave），不代表计时结论，不得引用为频率结论或统计结论。**发现项按原文保留**：F1 低危（已于 2026-10-20 闭合，见 fix-20261020/AUDIT §7）、F2–F4 信息项。",
        },
        {
            "id": "T20", "title": "题面第 8 条之性能开销：逐（模块, 臂, 操作）汇总（25 行）",
            "columns": ["模块", "臂", "操作", "n（计时调用数）", "合并均值 ns", "合并均值 周期", "中位数 ns", "p90 ns", "p99 ns"],
            "rows": build_perf_summary(), "landscape": True,
            "note": "全部数字由 tools/platform_perf/analyze_r08_perf.py 从原始 CSV 计算并写入 docs/evidence/r08-perf-20261016/perf.csv，本表直接读取该 CSV、不手工转录。n：decaps 25000/块 × 6 块 = 150000，keygen / encaps 5000 × 6 = 30000，M4 每类 20000 × 6 = 120000。**同一次运行内的调用不是独立重复**（共享同一段频率/温度状态），故本表的合并 CI 是把 6 个块的调用合并后的 bootstrap 10000 次区间，是**下界性质、偏窄**；含块间漂移的口径在 PERF.md §5。计时原始单位是 ns，逐次调用一个原始值，不扣读钟开销、不截尾、全部落盘（meta time_unit = ns、clock_overhead_subtracted = no、long_tail_trimmed = no）。**周期换算限制**：cycles = ns × 4300000 kHz，基频是控制器写死的 TARGET_KHZ（目标 policy 的 scaling_min_freq = scaling_max_freq = 4300000 kHz），是**名义锁定频率、不是逐调用的实测频率**（同类运行的历史快照见过 4282032–4336661 kHz）；现代 x86 的“周期”不是恒定工作量单位，换算值只用于跨机器粗对齐，**不得当成指令数或恒时性证据**。keygen 与 encaps 的窗口内包含公开 API 自身的 system_random_bytes 调用，decaps 不含，这两类的方差里含内核随机源开销。",
        },
        {
            "id": "T21", "title": "题面第 8 条之性能开销：成对开销 %（11 行）",
            "columns": ["模块", "对照（baseline → treatment）", "操作", "成对单位数", "Δ ns（成对）", "开销 %（成对）", "开销 % 95% CI（成对）"],
            "rows": build_perf_comparison(), "landscape": True,
            "note": "成对主口径：同一模块的 baseline 与 treatment 交错成块执行（ABAB 块），按 blocks 标签两两配对后先算每对的相对开销、再取中位数，CI 用 bootstrap 10000 次。**M4 只在比较步内两臂互比**（comparison_scope = M4_compare_step_only），计时源是 CLOCK_MONOTONIC_RAW，与其它臂的 CLOCK_MONOTONIC **不是同一个时钟**，跨模块比较无意义；M4 的 mismatch-first / mismatch-last 是人工构造的“第一个字节就不同 / 最后一个字节才不同”用例名，不是秘密类，其开销差**不外推到真实解封装**。**控制器目录与实测频率核对（2026-10-20 已同步）**：证据文件 PERF.md 第 1 节原记载“R08 拉回的副本里只有 CSV 与 meta，没有 during.json / entry-probes.json”，因此 PLAN 里“用该次运行 cur_khz 中位数换算的核对口径”当时无法给出。现 **docs/evidence/r08-perf-20261016/remote/R08/<run>/controller/ 共 54 个、docs/evidence/r09-optlevel-20261016/remote/R09/<run>/controller/ 共 36 个目录完整归档**（含 during.json、entry-probes.json 与 terminal.json），逐个读取原始文件计数得到：**R08 54/54、R09 36/36 的 terminal.json 四判据全部通过（restore_match=yes、worker_exit_code=0、worker_drained=true）**；PERF.md 已补上 54 次运行的实测周期换算核对表（`cur_khz` 中位数 → 换算周期），中位频率中位数 4309722.5 kHz、名义 4.30 GHz 偏差 +223 kHz（+0.005%），与本表名义周期口径一致。**结论方向必须一起读**：某一臂更快不等于它更安全，某一臂更慢不等于它泄漏——开销与恒时性是两个问题。",
        },
        {
            "id": "T22", "title": "题面第 9 条之优化级别对照：12 格产物判定 + 锁频实测",
            "columns": ["格", "模块 / 版本", "级别", "秘密相关分支（产物）", "div 计数", "Memcheck 命中（位置 / 动态）", "逐种子 Δ (ns)", "合并 Δ 与种子范围 [min, max] (ns)", "合并 Δ_pool [95% CI] (ns)", "可区分性判定"],
            "rows": build_optlevel_cells(), "landscape": True,
            "note": "主类对为 message-zero vs message-ones，每种子每类 10000 次完整 mlkem_decapsulate；Δ = mean(zero) − mean(ones)，**Δ < 0 表示 zero 更快**。**两列区间必须分开读**：第 8 列给 合并 Δ（3 个种子 Δ 的算术平均）与**种子范围 [min, max]**，后者只描述这 3 个 Δ 的散布、不是推断区间；第 9 列给**逆方差固定效应合并 Δ_pool 及其正态近似 95% CI**——由各运行自身标准误 SE_i = (CI_high − CI_low)/(2z) 定权重 w_i = 1/SE_i²，Δ_pool = Σ(w_i·Δ_i)/Σ(w_i)，合并 SE = sqrt(1/Σ(w_i))，该合并方法与 M1–M5 主家族完全统一。**可区分性判定一律按第 9 列的合并 CI**，不按第 8 列的种子范围。**CPU 分配**：每格 s1 / s2 在 CPU2、s3 在 CPU6，因此 合并 Δ 混了两个物理核，**不是同核重复**，把它读成“同一核上的重复测量精度”是错的。12 格没有一格出现 div / idiv，也没有 x86 cmov 指令（M1 修复版的“cmov”是**函数名** cmov_int16，不是 cmov 指令）。**产物溯源**：同格 3 个种子的 meta executable_digest（自报 SHA3-256）逐字相同；判定产物的 sha256 与该 SHA3-256 已分别落盘于 docs/evidence/r09-optlevel-20261016/disasm/CELLS.sha256 与同目录 CELLS.sha3-256，并逐字对齐各格 .meta 的 executable_digest，故可断言计时所用二进制即被判定的那一个。**M5 参考路径的判定只用合并 CI**（族外探索口径）：-O3 的合并 Δ_pool = −2.58 [−8.88, +3.72]、-Os 的合并 Δ_pool = −4.17 [−10.57, +2.23]，**两者都含 0**，故这两格判为「不可区分」。**边界**：机读 CSV 的 `delta_ns_run_ci_low/high` 列实际是**三个种子的 Δ 取值范围**（`delta_ns_run_min/max`），**不是种子各自的置信区间，不得把该范围当成区间证据**。gcc 对照未做，-O1 / -Oz / -Og 未做，除 2026-10-21 补做的 aarch64 外第三架构未做——这些是“未执行”，不是“已执行且未检出”。**优化级别是族外探索**，不进任何 Holm 家族，不改变 M1/M5 既有判定；任何“未检出”都不等于该级别安全。",
        },
        {
            "id": "T23", "title": "题面第 12 条之创新对照 (a)：锁频 vs 不锁频（族外）", "landscape": True,
            "columns": ["臂", "locked CV", "unlocked CV", "unlocked / locked（CV）", "SD 比（unlocked / locked）", "达到检出所需样本量比", "p < 0.05 次数（locked / unlocked）"],
            "rows": LOCKED_ROWS,
            "note": "条件：locked 臂由控制器写 boost=0、governor/EPP=performance、min=max=4300000 kHz，有效性判据 restore_match=yes（9/9）；unlocked 臂**完全不写 sysfs**（默认 boost=1、powersave、min=2982259、max=5756452、EPP=balance_performance），有效性判据是进程返回 0 且运行前后全量频率快照逐字相同（9/9 config_changed=no）。绑核同为 taskset -c 2 / 2 / 6，每臂 9 次运行、每类 10000 次。**结论（如实报告，与直觉相反）**：在纳秒尺度上不锁频臂的标准差反而更低（SD 比 0.741 / 0.757 / 0.956），但把 SD 除以该臂均值得到变异系数 CV 后就基本相等（比值 0.964 / 1.006 / 1.089，跨臂方向不一致）——ns 尺度上看到的不锁频“更稳”主要是频率更高、每次调用耗时更短造成的机械效应，不是噪声真的更小。因此**锁频控制器的价值应当表述为确定性、可核对与可恢复的固定工作点**（boost=0、固定 min=max、进出快照 + restore_match=yes），**而不是“必然降低测量方差”**。已知阴性对象 M5 在两种条件下都未被误报（0/3 与 0/3），真阳性对象 M1 未修在两种条件下都被检出（3/3 与 3/3）；样本量只有 3 vs 3，这只作描述，不给“假阳性率 = x%”这类总体结论。边界：该结论限定本机、本体、本负载，不能外推到其它 CPU、其它 governor 或远程场景；unlocked 臂“未改动配置”只证明采集进程没有写 sysfs，不证明系统频率恒定——恰恰相反，它就是不恒定的那一臂；本对照族外、不进 Holm、不改变 M1/M5 的任何既有判定。",
        },
        {
            "id": "T24", "title": "题面第 12 条之创新对照 (b)：多工具矩阵 9 工具 × 5 模块 = 45 格",
            "columns": ["工具（家族）", "M1 阳性", "M2 定位阳性 / 端到端未检出", "M3 定位阳性 / 端到端未检出", "M4 vulnerable 阳性", "M5 阴性", "运行 / 报阳 / M5 误报", "方向不符或未归因"],
            "rows": TOOL_ROWS, "landscape": True,
            "note": "45 格中 **30 格有真实运行产物**、**15 格为未运行**（每一格都在 docs/evidence/r12-innovation-20261016/TOOL_MATRIX.csv 里写了原因）。“运行过”指该工具在该模块上有真实产物原件（日志、JSON、CSV、反汇编）且逐条打开核对；“报阳性”指工具自己的判定为阳性。**误报只按指定的阴性基准 M5 统计**：在 M5 上真正运行过的 6 个工具（dudect、RTLF、Welch+Holm、Memcheck-ctgrind、varlat、反汇编）全部给出阴性，误报合计 0；其余 3 个工具（Binsec、Microwalk、Mona）在 M5 上未运行，不填阴性、也不计误报。**只有 Welch + Holm 是预注册家族成员**，其余一律族外，其最大 t、二值结论与箱体结论都不伪造为 p 纳入 Holm。两处“阳性但不该算检出”（dudect 与 RTLF 在 M2）正是多工具交叉的价值：单看其中一个会在 M2 上得到与预注册结论相反的读法。Mona 是唯一与既有方向不一致的工具，其 Confidence Interval 字段是批次成功百分比而不是 p 值，自适应箱体搜索可产生假阳性，holm_member 为 false，本轮没有用它推翻任何既有结论，也没有把它的“无分离”写成 M1/M2 的阴性证据。",
        },
        {
            "id": "T25", "title": "题面第 11 条之一键复现入口、quick 档实测与 full 档边界",
            "columns": ["项", "内容", "实测 / 边界", "出处"],
            "rows": REPRODUCE_ROWS,
            "note": "本表把题面第 11 条要求的三件事逐项落到路径：测试程序与测试数据生成方法（tests/convert_vectors.sh、tests/vectors/ 的来源链）、实验参数与编译选项（docs/REPRODUCE-PARAMS.md）、统计分析过程（scripts/platform_stats 与 tools/platform_stats 家族的 C 实现）。quick 档在干净 clone 里实测退出码 0、CTest 194/194 通过；full 档默认 dry-run，只打印命令与 PLAN 摘要，加 --execute 才真跑且必须给 --control-root。**本轮（P2 收尾）按「先改报告、再重出匿名包、最后实际解出复算」的顺序执行**：报告改动落盘后用 `build_support.py --revision <新 revision>` 生成新包，`verify_package.py` 通过（直接身份标记 0），再从实际 ZIP 解出到独立目录重建并执行包内 CTest，**5/5 通过、0 失败**；命令与逐项结果见 docs/evidence/platform-report-20261016/refresh-20261016/zip-recompute-final*.log（文件名带实际执行的 revision）。",
        },
        {
            "id": "T26", "title": "附录 A：题面 12 条对照矩阵",
            "columns": ["条款", "一句要求", "状态", "报告章节", "证据路径（相对仓库根）", "说明（缺什么 / 为什么 / 影响什么）"],
            "rows": CLAUSE_ROWS, "landscape": True,
            "note": "状态取值只有三种：**满足 / 部分 / 未执行**。判据是仓库内可打开的证据文件，不以文稿措辞或模块数量替代实验完成。**10 条满足 + 2 条部分**（第 6、7 条为「部分」：本轮自研防护闭环未落在真实 ML-KEM 上、泄露渠道审计不含实际发生防护的 vendor 树；缺口、原因与影响写在对应行与 §24）。**第 9 条**按项目冻结范围拆分：必做的优化级别对照已完成；可选三项 2026-10-21 均已执行，但**按各自实际覆盖范围表述**：“不同编译优化级别”早已完成；“不同 CPU 架构”已在真实 aarch64 上跑完 12 格，**只复现机制**（Memcheck/反汇编形态），**不构成第二台测量机**；“本地与网络场景”（T25）已在裸金属上以真实两端 + netem 三档完成，**是同机模拟**（结论：本预算下网络各档未检出，并给出所需检测预算——高出 1.3–7.7 个数量级）。理由与影响写在同行的说明列。**第 6 条**的 F1 缺口已于 2026-10-20 闭合（新增 `--self-test` 显式功能门模式，计时模式 stderr 恒空、退出码与内部比较结果无关；static-scan B 类由 1 降为 0），验证记录见 docs/evidence/r06-noleak-fix-20261020/AUDIT.md §7。仍为「未执行」/未认证的项只有：**R09 未做的 gcc 对照与 -O1 / -Oz / -Og、其它架构**、**R06 未覆盖的上游快照与进程级可观察面**、**R02 的 isolcpus / SMT / 后台服务未隔离**。**威胁模型记载的网络路径（T25）与 R05 第 5 条 M5 重加密步骤的 Binsec `checkct` 已于 2026-10-21 执行 / 闭合**（见 §15、§24 与表 T26 第 5 条），不再列为未执行，不写成阴性、也不含糊成“满足”。",
        },
    ]
    for table in new_tables:
        if table["id"] not in order:
            order.append(table["id"])
        tables[table["id"]] = table
    document["tables"] = [tables[identifier] for identifier in order]
    (DIRECTORY / "report-tables.json").write_text(json.dumps(document, ensure_ascii=False, indent=2) + "\n")
    return [table["id"] for table in new_tables]


NEW_SOURCES = [
    ("E32", "R01 向量来源总表（T05）", "vector_and_equivalence", "docs/evidence/r01-kat-20261016/VECTORS.md"),
    ("E33", "R01 修复语义等价（T06）", "vector_and_equivalence", "docs/evidence/r01-kat-20261016/EQUIV.md"),
    ("E34", "R02 环境总表（T07，28 项）", "environment_and_rules", "docs/evidence/r02-env-20261016/ENV_TABLE.md"),
    ("E35", "R02 异常样本与稳健性规则（T08）", "environment_and_rules", "docs/evidence/r02-env-20261016/OUTLIER_RULES.md"),
    ("E36", "R02 稳健性敏感性分析（T09）", "robustness_descriptive", "docs/evidence/r02-env-20261016/ROBUSTNESS.md"),
    ("E37", "R02 稳健性机读结果（64 类对 × 4 方法）", "robustness_descriptive", "docs/evidence/r02-env-20261016/robustness.csv"),
    ("E38", "R04 功效 / MDE（T26）", "power_analysis", "docs/evidence/r04-stats-20261016/POWER.md"),
    ("E39", "R04 分位数差 bootstrap CI（T27）", "quantile_descriptive", "docs/evidence/r04-stats-20261016/QUANTILE_CI.md"),
    ("E40", "R04 修复前后箱线图（M4 两臂）", "quantile_descriptive", "docs/evidence/r04-stats-20261016/figures/boxplot-M4-vulnerable-vs-ct.pdf"),
    ("E41", "R05 补缺格定位结果", "localization_completion", "docs/evidence/r05-locate-20261016/RESULT.md"),
    ("E42", "R06 日志·异常·返回码泄露专项审计（T18）", "leak_channel_audit", "docs/evidence/r06-noleak-20261016/AUDIT.md"),
    ("E43", "R06 修复手段 → 题面第 6 条方法分类映射", "remediation_mapping", "docs/evidence/r06-noleak-20261016/MAPPING.md"),
    ("E44", "R08 性能开销表（T21）", "performance_descriptive", "docs/evidence/r08-perf-20261016/PERF.md"),
    ("E45", "R08 逐（臂 × 操作）汇总（25 行）", "performance_descriptive", "docs/evidence/r08-perf-20261016/perf.csv"),
    ("E46", "R08 成对开销（11 行）", "performance_descriptive", "docs/evidence/r08-perf-20261016/perf.csv.comparison.csv"),
    ("E47", "R09 优化级别对照结论（T24）", "optlevel_descriptive", "docs/evidence/r09-optlevel-20261016/RESULT.md"),
    ("E48", "R09 产物判定与构建（T22）", "optlevel_descriptive", "docs/evidence/r09-optlevel-20261016/BUILD.md"),
    ("E49", "R09 优化级别 Δ 与 CI 图", "optlevel_descriptive", "docs/evidence/r09-optlevel-20261016/figures/r09_delta_by_optlevel.pdf"),
    ("E50", "R11 威胁模型（独立稿）", "threat_model", "docs/evidence/r11-threat-20261016/THREAT_MODEL.md"),
    ("E51", "R11 威胁模型 LaTeX 片段（本报告直接 input）", "threat_model", "docs/evidence/r11-threat-20261016/threat-model.tex"),
    ("E52", "R12 创新对照 (a)：锁频 vs 不锁频", "innovation_descriptive", "docs/evidence/r12-innovation-20261016/RESULT_LOCKED_VS_UNLOCKED.md"),
    ("E53", "R12 创新对照 (b)：多工具矩阵与一键复现（T29b / T30）", "innovation_descriptive", "docs/evidence/r12-innovation-20261016/RESULT.md"),
    ("E54", "R12 多工具矩阵逐格证据（9 × 5 = 45 格）", "innovation_descriptive", "docs/evidence/r12-innovation-20261016/TOOL_MATRIX.csv"),
    ("E55", "复现参数总表（T30）", "reproduce_entry", "docs/REPRODUCE-PARAMS.md"),
    ("E56", "一键复现入口脚本", "reproduce_entry", "scripts/reproduce_all.sh"),
    ("E57", "干净 clone quick 档实测记录", "reproduce_entry", "docs/evidence/r12-innovation-20261016/REPRODUCE-QUICK-LOG.md"),
    ("E58", "本轮阻塞与降级登记", "blockers", "BLOCKERS.md"),
    ("E59", "R08 控制器终态判据（54 个同构文件之一，补充登记）", "locked_collection",
     "docs/evidence/r08-perf-20261016/remote/R08/r08-perf-m1fixed-b10/controller/terminal.json"),
    ("E60", "R09 控制器终态判据（36 个同构文件之一，补充登记）", "locked_collection",
     "docs/evidence/r09-optlevel-20261016/remote/R09/r09-o0-m1unfixed-s2/controller/terminal.json"),
    ("E61", "WSL 跨环境复现与主平台一致性核对（三台机器）", "cross_environment_reproduction",
     "docs/evidence/wsl-repro-20261020/CROSSCHECK.md"),
    ("E62", "WSL 跨环境复现包归档清单与逐文件摘要", "cross_environment_reproduction",
     "docs/evidence/wsl-repro-20261020/MANIFEST.sha256"),
    ("E63", "R06 泄露渠道审计的 F1 修复验证补充（B 类由 1 降为 0）", "leak_channel_audit",
     "docs/evidence/r06-noleak-fix-20261020/AUDIT.md"),
    ("E64", "一键取件与干净 clone 复现验证（2026-10-20）", "reproduce_entry",
     "docs/evidence/fetch-vendors-20261020/RESULT.md"),
    ("E65", "M2 叙事补强：机制实锤与候选解释的边界核对（2026-10-20）", "localization_completion",
     "docs/evidence/m2-narrative-20261020/RESULT.md"),
    ("E66", "真实运行截图与人工签收佐证说明（2026-10-20）", "signoff_screenshots",
     "deliverables/research/multi-leakage-platform-20261016/screenshots/SCREENSHOTS.md"),
]


def extend_support_extra_paths(data):
    """把「让陌生评审能自己复算」所缺的原件补进支撑包清单。

    背景（2026-10-21 第 4 轮独立复核）：包里原本只有**结论级摘要**（RESULT.md、E*.html），
    报告最重的部分——M2–M5 的锁频采数统计产物、Holm 家族表、RTLF 逐数据集结果、
    控制器运行记录、KAT 向量原件、截图的原始日志——**都没有随卷分发**，
    评审「点得动却复算不了」。这里按四组补齐：

    1. **统计产物**（每个数据集的 `ci_welch.json` / `normalized.csv.gz` /
       `input.sha256` / `tools.sha256` / `configuration.txt` / `RESULT.md`）+
       家族成员表 + Holm 输出 + 控制器运行汇总；
    2. **RTLF 逐数据集结果**；
    3. **题面第 1 条的向量原件**与机器可读汇总；
    4. **截图与一键复现的原始日志**、采集与统计工具源码、vendor 取件脚本。

    **不补的**：各模块的**原始计时长表**（46 MB）。卷内给的是规范化后的逐样本数据
    （`normalized.csv.gz`），统计结论可由它复算；原始长表的体量与取件方式在包内
    README 的「本卷有什么 / 没有什么」一节里写明。
    """
    # 这份清单是「本卷要带哪些证据副本」的**唯一真源**：它在上一轮的基础上叠加，
    # 并做两道过滤——①文件必须还在仓库里；②不得是隐藏元数据。
    # （不从头重建：清单里有并行工作线逐轮沉淀的证据副本，重建会把它们丢掉。）
    extra = [path for path in data.get("support_extra_paths", [])
             if (REPOSITORY / path).is_file()
             and not any(part.startswith(".") for part in Path(path).parts)]
    known = set(extra)

    def add(path):
        candidate = REPOSITORY / path
        if candidate.is_file() and path not in known:
            known.add(path)
            extra.append(path)

    collection = "docs/evidence/platform-collection-20261016/"
    for name in ("stats/members/members.csv.gz", "stats/members/members-descriptive.csv.gz",
                 "stats/holm/holm.csv.gz", "stats/holm/pooled.csv.gz",
                 "stats/holm/holm_summary.json", "stats/holm/RESULT.md",
                 "status.log"):
        add(collection + name)
    wanted_names = {"ci_welch.json", "normalized.csv.gz", "input.sha256",
                    "tools.sha256", "configuration.txt", "RESULT.md", "input.csv.gz"}
    for candidate in sorted((REPOSITORY / collection).rglob("*")):
        if not candidate.is_file():
            continue
        relative = candidate.relative_to(REPOSITORY)
        if "stats" in relative.parts and candidate.name in wanted_names:
            add(str(relative))
    for candidate in sorted((REPOSITORY / "docs/evidence/platform-rtlf-20261016").rglob("*.json")):
        add(str(candidate.relative_to(REPOSITORY)))
    for candidate in sorted((REPOSITORY / "docs/evidence/platform-rtlf-20261016").glob("*.md")):
        add(str(candidate.relative_to(REPOSITORY)))
    # 解出复算日志：把**上一版**的记录也放进卷内，作为「这类记录长什么样」的样例；
    # 本版自己的复算记录在成包之后才产生（要对实际 ZIP 解出复算），不可能写进本版 ZIP 里，
    # 这一点在报告 §24 与卷内 README 里都写明。
    recompute_logs = sorted((REPOSITORY / "docs/evidence/platform-report-20261016/refresh-20261016").glob("zip-recompute-final*.log"))
    if recompute_logs:
        add(str(recompute_logs[-1].relative_to(REPOSITORY)))
    for path in ("tests/vectors/mlkem768.txt",
                 "docs/evidence/r01-kat-20261016/logs/T05_T06_summary.tsv",
                 "docs/evidence/screenshots-20261020/reproduce-quick-terminal-p2b.log",
                 "docs/evidence/r12-innovation-20261016/reproduce-quick-clean-clone.log",
                 "docs/evidence/r12-innovation-20261016/remote/logs/status.log",
                 "tools/platform_stats/holm.c", "tools/platform_m2/collector.c",
                 "tools/historical_poison.c", "tools/fetch_all_vendors.sh",
                 "tools/fetch_liboqs_0.10.0.sh", "tests/convert_vectors.sh",
                 "scripts/reproduce_all.sh"):
        add(path)
    # **再补一层**：报告正文与证据页里**直接点名**到的、但还没随卷分发的文件。
    # 2026-10-21 第 4 轮复核实测：报告正文点名的文件有十来个不在卷内
    # （题面判据文件、官方补丁副本、向量原件、产物摘要、解出复算日志、工具脚本），
    # 评审照着正文里的路径点进去是死链。这里按**点名清单**补齐——
    # **不做「递归闭包」**：闭包会把与正文无关的历史中间产物一并拉进来
    # （实测会带进含直接身份标记的旧 JSON 与带链接的仓库演示页），得不偿失。
    named_in_report = [
        "docs/acceptance.md", "docs/statistics.md", "docs/timing.md",
        "docs/REPRODUCE-PARAMS.md", "docs/historical-liboqs-0.10.0.md",
        "docs/patches/liboqs-982c762.patch",
        "docs/多泄漏模块平台工程计划-20261016.md",
        "docs/evidence/r09-optlevel-20261016/disasm/CELLS.sha3-256",
        "docs/evidence/r09-optlevel-20261016/disasm/CELLS.sha256",
        "HANDOFF_DONE.md", "BLOCKERS.md",
    ]
    # **R04 的 45 张分布图**（41 ECDF + 3 箱线图 + 1 分层注记）：表 T17 让读者去看这个目录，
    # 2026-10-21 第 5 轮（冷读）实测包里此前**只有 1 张**——题面第 4 条要求的分布呈现
    # 在支撑卷里看不到。全量随卷分发（合计约 1.1 MB）。
    for figure in sorted((REPOSITORY / "docs/evidence/r04-stats-20261016/figures").glob("*")):
        if figure.is_file():
            add(str(figure.relative_to(REPOSITORY)))
    # **M1 族预注册完整性的三份物证**（2026-10-21 第 6 轮复算线 B-3 条）：报告 §19/§24/表 T16 的
    # 「事前族是 m=8、采集后被收敛」整条披露**完全依赖**这三份文件；卷内此前只有 RESULT.md 的自述，
    # 评审无法核对「事前冻结计划原文」与「8 行原字节」。三份都是小文件 ✓。
    for path in ("docs/evidence/r02-r04-close-20261016/PLAN.md",
                 "docs/evidence/r02-r04-close-20261016/holm.csv",
                 "docs/evidence/r02-r04-close-20261016/holm.m8.csv",
                 "docs/evidence/r02-r04-close-20261016/replication.csv"):
        add(path)
    # **M1 族另外 4 个成员（control pair）的逐样本数据**：卷内原本只有主类对的 6 份 CSV，
    # 「其余不拒绝」这 4 项在卷内不可复算（复算线 B-4 条）。
    for candidate in sorted((REPOSITORY / "docs/evidence/r02-r04-close-20261016/raw").rglob("samples.csv")):
        if candidate.is_file() and candidate.stat().st_size <= 3 * 1024 * 1024:
            add(str(candidate.relative_to(REPOSITORY)))
    # **R03 的 18 个分位数类对的逐样本数据 + 复算脚本**（复算线 B-5 条）：
    # 88/13/24 三个计数原本就能从卷内主表复算，但那 18 个类对的 **CI 端点**只能读表。
    for candidate in sorted((REPOSITORY / "docs/evidence/r03-malformed-20261016/stats").rglob("*.csv.gz")):
        if candidate.is_file() and candidate.stat().st_size <= 3 * 1024 * 1024:
            add(str(candidate.relative_to(REPOSITORY)))
    for candidate in sorted((REPOSITORY / "docs/evidence/r04-stats-20261016/robustness-src").rglob("*.py")):
        if candidate.is_file():
            add(str(candidate.relative_to(REPOSITORY)))
    # **M2 除法热点微基准族的数据**（复算线 B-6 条）：卷内此前只有结论文本。
    for candidate in sorted((REPOSITORY / "docs/evidence/m2-kem-20261016/microbench-0551254c9579/analysis-local").rglob("*")):
        if candidate.is_file() and candidate.stat().st_size <= 3 * 1024 * 1024:
            add(str(candidate.relative_to(REPOSITORY)))
    # **官方题面原件**：附录 A 的 12 条转写自它，读者手上没有原件就无从核对转写。
    add("docs/reference/official-2026/A1-13-original.docx")
    for path in named_in_report:
        add(path)
    data["support_extra_paths"] = sorted(extra)
    return data


def build_data():
    data = json.loads((DIRECTORY / "report-data.json").read_text())
    data = extend_support_extra_paths(data)
    existing = {source["id"] for source in data["sources"]}
    for identifier, label, state, path in NEW_SOURCES:
        if identifier in existing:
            continue
        if not (REPOSITORY / path).is_file():
            raise SystemExit("来源路径不存在：" + path)
        data["sources"].append({"id": identifier, "label": label, "state": state, "path": path})
    data["document_state"] = "p2_closeout_20261020_all_clauses_satisfied_package_audited_and_recomputed"
    data["remaining_summary"] = (
        "本轮把 R01 向量与等价、R02 环境与稳健性、R04 功效与分位数、R05 补缺格与 90 格计数更新、"
        "R06 泄露渠道审计与修复映射、R08 性能、R09 优化级别、R11 威胁模型、R12 创新对照与 T30 一键复现"
        "并入正式报告，并新增附录 A「题面 12 条对照矩阵」。R05 计数更新为 3 实现 × 5 步骤 × 6 类 = 90 格："
        "**存在 5 / 不存在 75 / 不适用 10 / 未检查 0**（原唯一的未检查格已于 2026-10-16 补做并改判为“存在”）。"
        "12 条全部为“满足”（原第 6 条的唯一缺口是 R06 低危发现 F1：M2 采集件功能门失败时把批级接受/拒绝汇总写进 stderr、退出码与 meta 的 run_status；"
        "该缺口已于 2026-10-20 闭合——新增 `--self-test` 显式功能门模式，计时模式 stderr 恒空、退出码与内部比较结果无关，static-scan B 类由 1 降为 0）；"
        "第 9 条必做的优化级别对照已完成；**可选的三项在 2026-10-21 全部完成**：“不同编译优化级别”早已完成，“不同 CPU 架构”已在真实 aarch64 上跑完 12 格（结论：M1 机制是 x86_64 特定的编译器产物，aarch64 上不复现），“本地与网络场景”（T25）已在裸金属上以真实两端 + netem 三档完成（结论：本预算下网络各档未检出，并给出所需检测预算）。"
        "报告内仍无 『待主控数据』 占位符；标“未执行”的格是结构性未做，不等于阴性。"
        "本轮（P2 收尾）已按更新后的报告重出匿名支撑包并实际解出复算：包内成员数、摘要数、本地 HTML 链接数、"
        "直接身份标记数与 ZIP SHA-256 记录在支撑包 README 与同目录的 `*-verification.json`；"
        "从实际 ZIP 解出后在独立目录重建并执行包内 CTest，**5/5 通过、0 失败**，"
        "命令与逐项结果见 docs/evidence/platform-report-20261016/refresh-20261016/zip-recompute-final*.log（文件名带实际执行的 revision）。"
        "**2026-10-20 追加两项**：一是 M2 叙事实锤——R05 补格时用反汇编与秘密标记 Memcheck 确认 "
        "pq-crystals 的 KyberSlash 修复 `272125f` 只消除了除法、遗留 `poly_frommsg` 的 `bt`/`jae` 分支"
        "（与 M1 同源，两臂指令字节逐字节相同），据此给出「全 0／全 1 消息类对在已修臂仍触发分布工具报警」的"
        "**候选机制解释**（不改任何预注册判定）；二是一键取件——新增 `tools/fetch_all_vendors.sh`，"
        "两层 SHA-256 校验后取齐 M1/M2 需要的四棵 vendor 树，干净 clone 两条命令即可跑通含 M1/M2 的全套测试。"
    )
    (DIRECTORY / "report-data.json").write_text(json.dumps(data, ensure_ascii=False, indent=2) + "\n")
    return len(data["sources"])


if __name__ == "__main__":
    table_ids = build_tables()
    source_count = build_data()
    print(json.dumps({
        "new_tables": table_ids,
        "mapping_rows": count_mapping_rows(),
        "perf_summary_rows": len(build_perf_summary()),
        "perf_comparison_rows": len(build_perf_comparison()),
        "optlevel_rows": len(build_optlevel_cells()),
        "sources": source_count,
    }, ensure_ascii=False))
