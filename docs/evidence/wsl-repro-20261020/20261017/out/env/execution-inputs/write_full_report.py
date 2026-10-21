#!/usr/bin/env python3
"""Assemble the report from completed, independently audited data."""
import datetime
import json
import pathlib
import re

out = pathlib.Path('/home/cryrepro/cry-wsl/out')
v = json.loads((out/'audit/validation.json').read_text())
assert v['status'] == 'PASS' and v['mode'] == 'full'
assert not v['historical_binary_matches']
summary = (out/'stats/SUMMARY.md').read_text()
manifest = json.loads((out/'audit/raw-manifest.json').read_text())
pooled = v['pooled']
now = datetime.datetime.now().astimezone().isoformat(timespec='seconds')
rows = []
for arm in sorted(pooled):
    r = pooled[arm]
    lo, hi = r['ci95']
    rows.append(f"| {arm} | {r['runs']} | {r['delta_ns']:+.2f} | [{lo:+.2f}, {hi:+.2f}] | +{r['positive_runs']} / −{r['negative_runs']} | {'含 0' if lo <= 0 <= hi else '不含 0'} |")
pooled_table = '\n'.join(rows)
memcheck = (out/'memcheck/SUMMARY.tsv').read_text().strip()
disasm = (out/'disasm/SUMMARY.tsv').read_text().strip()
performance_section = summary.split('## 性能（ns；不锁频）',1)[1].split('## dudect',1)[0].strip()
dudect_section = summary.split('## dudect（族外，阈值 t>10）',1)[1].split('## disasm',1)[0].strip()
block_rows = []
for b in range(1,5):
    block = {r['run']:r for r in manifest['performance']}
    u = block[f'perf-m1unfixed-b{b}']['means_ns']['decaps']
    f = block[f'perf-m1fixed-b{b}']['means_ns']['decaps']
    block_rows.append(f'| {b} | {u:.2f} | {f:.2f} | {(f/u-1)*100:+.3f}% |')
ordinary_max = max(max(r['max_ns'].values()) for r in manifest['ordinary'])
se_values = [r['se_ns'] for r in manifest['ordinary'] if r['run'].startswith('m1-unfixed-Os-')]
m1u = pooled['m1-unfixed-Os']
m1f = pooled['m1-fixed-Os']
direction = '与早期 +32.311 ns 同号、与 r09 −26.16 ns 反号' if m1u['delta_ns'] > 0 else '与早期 +32.311 ns 反号、与 r09 −26.16 ns 同号' if m1u['delta_ns'] < 0 else '等于 0，不能归为正或负方向'
def evidence_sentence(name, r):
    lo, hi = r['ci95']
    return f"{name}：合并 Δ={r['delta_ns']:+.2f} ns，95% CI [{lo:+.2f}, {hi:+.2f}]，{'包含' if lo <= 0 <= hi else '不包含'} 0；9 次运行中正/负号为 {r['positive_runs']}/{r['negative_runs']}。"

report = f'''# WSL2 跨环境复现正式报告

执行者：Codex，依用户授权在本机执行。报告生成：{now}。

正式流程启动于 2026-10-17 23:10:50；原始采集于 2026-10-18 00:10:40 完成（Asia/Shanghai），随后进行统计、独立审计和打包。目录/包名的 20261017 为本次任务启动日期。

**正式 P0/P1/P2 清单全部执行完成，数据审计 PASS。** 平台 CTest 90/90，M1 两版各 61/61，均 0 失败。共 153 个普通计时 CSV（14,220,000 行）、12 个性能 CSV（420,000 行）、5 份在线 dudect 日志。QUICK 另存，未混入本报告统计。

M1 的确定性证据复现了文档所述模式：未修复 `-Os/-O2/-O3` 的秘密标记 Memcheck 分别为 512 次报告、1/8/15 个上下文；修复版四级均为 0/0。计时结果需单独解释：{evidence_sentence('未修复 -Os',m1u)} {evidence_sentence('修复版 -Os',m1f)}

本轮 M1 两版各优化级别、M2 两版及 M5 所有臂的合并区间均包含 0，未获得稳定的端到端计时区分证据。M4 人工构造校准的 vulnerable 臂九次均为负，合并 Δ=−11.97 ns [−12.17, −11.78]，在线 dudect 最后 max t=309.46；ct 臂区间包含 0、在线未触发阈值。确定性证据与计时证据分别回答机制存在和本次环境下的可测性；未检出不能作为安全或常数时间证明。

## 1. 版本、环境和实验条件

| 项目 | 本机记录 |
|---|---|
| 仓库 | https://github.com/Gowin-liuyin/cryProject.git |
| 固定提交 | `04baad45ebb5ea4dba8d143d64c5031c906503d2` |
| Windows | Windows 11 专业版 25H2，10.0.26200.9711 |
| WSL / Ubuntu | WSL 3.0.3.0；Ubuntu-24.04，24.04.5 LTS |
| 实际内核 | 6.18.54.1-microsoft-standard-WSL2，x86_64 |
| CPU | AMD Ryzen 7 8845H；宿主 8 核 / 16 线程，WSL 可见 16 vCPU |
| 内存 | 宿主约 16 GB；WSL 7.4 GiB，交换空间 2 GiB |
| 工具链 | Clang 18.1.3、CMake 3.28.3、Valgrind 3.22.0、Python 3.12.3、OpenSSL 3.0.13 |
| 路径 / 用户 | `/home/cryrepro/cry-wsl`，ext4；普通用户 `cryrepro` |
| 电源与操作 | 用户确认插电、正常模式（非节能）、采集期间不做其他操作；系统读取为平衡电源计划、BatteryStatus=2 |
| 频率管理 | **未锁频、未关闭 boost**；WSL 中 cpufreq 目录不存在 |
| 绑核 | 外部 `taskset -c 15`；实测进程 `Cpus_allowed_list: 15` |
| 计时 | 普通/性能数据为 `CLOCK_MONOTONIC`、ns；Linux clocksource 为 `tsc`。在线 dudect 为上游 rdtsc/cycles/ticks，不能与 ns 数值混用 |

Clang 与文档参考机的 18.1.8 不同，本次如实使用 Ubuntu 的 18.1.3。没有更改 `.wslconfig`。`env/ENV.before.txt`、`env/ENV.txt` 分别保存采集前/末次环境，`env/freq_snapshots.txt` 保存采集周边快照；其 MHz 在 WSL 中不能作为物理频率锁定证明。Windows 互操作的部分中文输出有编码乱码，原文件保留；清晰的 Windows 环境与用户条件另见 `env/windows-before-experiments.json`、`env/user-conditions.json`。

程序 `.meta` 中的 `cpu_affinity=not_pinned` 是内部固定文案，不检测外部 taskset。实际亲和性证据见 `env/observed-affinity.txt`。仅核验了虚拟 CPU 绑定，不意味着宿主物理核心独占。

Windows 主仓库未修改、未 commit/push。WSL 受跟踪源码无变化；`git status` 唯一额外项为文档要求的独立补丁树 `vendor/liboqs-0.10.0-982c762/`，未通过修改忽略规则隐藏。第三方版本、补丁 SHA256、二进制 SHA256/SHA3-256 与编译配置见 `env/`、`env/build-evidence/`。

## 2. 正确性与采集完整性

| 构建 | CTest | 说明 |
|---|---|---|
| 平台 | 90/90 | 含 M2 未修/已修两项公共 Kyber round3 KAT |
| M1 未修复 -Os | 61/61 | 全部通过 |
| M1 修复版 -Os | 61/61 | 全部通过 |

正式清单采用种子 **31337 / 424242 / 7**，每种子 **3 次重复**，每类 **20,000 个样本**。17 个臂各 9 次，共 153 次普通采集；其中 15 个臂为五类，M4 两个臂为两类，总计 14,220,000 行。P0 的 M1 `-Os` 数据在 P1 复用，不重复计数。

| 完整性检查 | 实际结果 |
|---|---|
| 普通计时文件/行 | {v['ordinary_files']} / {v['ordinary_rows']:,} |
| 性能文件/行 | {v['performance_files']} / {v['performance_rows']:,} |
| 在线 dudect | {v['dudect_log_count']} 份终止日志；M5、M4 两臂有原始 CSV，M1 驱动按原设计只输出在线日志 |
| 独立重算与仓库电池 Δ 最大差 | {v['max_delta_difference_ns']:.12g} ns |
| 独立重算与仓库电池 SE 最大差 | {v['max_se_difference_ns']:.12g} ns（浮点舍入范围） |
| 二进制身份 | 正式普通/性能 `.meta` 均匹配实际当前二进制；未使用历史摘要代替 |
| 原始数据 | 样本数、类别、索引、单位、非负耗时、SHA256 均核验；不删尾 |

独立审计使用整数和/平方和计算样本方差，与仓库 C 统计及原脚本 Python 汇总交叉核对。审计结果见 `audit/validation.json`，逐文件类别计数、均值、SE、极值和哈希见 `audit/raw-manifest.json`。普通数据观察到的最大单条耗时为 {ordinary_max:,} ns，已原样保留。

## 3. P0/P1 确定性证据

`-Os` 未修复 `poly_frommsg` 为 `bt+jae`；修复版为 `bt+setb+call cmov_int16`。Memcheck 采用文档的秘密标记驱动，错误计数是实验观察结果，不是脚本执行失败。结果与文档参考的 1/8/15/0 个上下文模式一致。

```text
{memcheck}
```

反汇编完整汇总如下。条件跳转总数中可能包含公开循环控制，不能仅凭跳转总数判定常数时间；应结合秘密依赖标记与具体指令阅读。

```text
{disasm}
```

## 4. P0/P1/P2 普通计时结果

M1/M2/M5 的 Δ = mean(message-zero) − mean(message-ones)；M4 的 Δ = mean(mismatch-first) − mean(mismatch-last)。下表为同一 WSL 臂内九次运行的固定效应逆方差合并，95% 正态近似 CI。逐次值、中位数/p90/p99 差和正态近似双侧 p 见 `stats/SUMMARY.md`。这些都是探索性描述，不进入 Holm。

| 臂 | 次数 | 合并 Δ ns | 95% CI ns | 运行正号 / 负号 | 区间描述 |
|---|---:|---:|---|---|---|
{pooled_table}

M1 未修复 `-Os` 单次 SE 的实际范围为 {min(se_values):.2f}–{max(se_values):.2f} ns。判断需同时看全部种子/重复的方向、区间与噪声，不能把一次 p<0.05 写成“检出”。固定效应模型不消除虚拟机调度、自相关或运行间异质性；其区间不是跨机器泛化保证。

**与裸金属方向的对照：**执行文档列出的早期 M1 未修复 `-Os` 合并为 +32.311 ns，而 r09 重建结果为 −26.16 ns；本次主比较{direction}。文档另列 r09 未修复 `-O0` +26.25 ns，与本次 +331.30 ns 同号；已修复 `-O0` −25.75 ns、`-O3` −10.38 ns，分别与本次 +104.86 ns、+69.79 ns 反号，但这些 O0/O3 参照和本次对应区间均包含 0。参照数字引自执行文档，未在这里重算裸金属原始数据。

裸金属本身已随二进制变化而反号。方向只能与特定构建对照，不能用一个符号证明或否定机制；绝不把 WSL 与裸金属样本合并。未为缺少完整参照的臂强行判定一致。M5 是对照臂，其计时区间也不能解释为安全证明。M2 是历史 KyberSlash 平台 measure 臂；本次统计比较不等同于攻击或密钥恢复验证。

**M4 为人工构造校准。** vulnerable 和 ct 两臂仅按各自数值与在线结果报告；vulnerable 的机制预期是 mismatch-first 提前退出更快，即负 Δ。不能外推为真实库攻击结论。

## 5. 在线 dudect（独立于主 ns 统计）

{dudect_section}

M1/M5 预算为每批 10,000、最多 21 批，并按上游首次泄漏状态提前停止；M4 人工构造校准执行 10 批，每批 20,000 次，记录是否曾进入 leakage 状态。最大 t 是上游检验族内选出的统计量，阈值为 10，不能把其正号当作普通均值差方向。上游保留预热、端点丢弃、裁剪与高阶检验；原始导出和普通数据不删尾的口径分别记账。日志中的 “maybe constant time” 不构成常数时间证明。

## 6. P1 性能

驱动按脚本编译为 `-O2`；M1 静态库来自主比较的 `-Os -fno-vectorize`，M5 来自平台默认参考构建。三臂按未修复、已修复、M5 的固定顺序循环四块（实际是三臂循环，不是严格双臂 ABAB 随机交叉）。每臂 decaps=100,000、keygen=20,000、encaps=20,000。decaps 使用固定有效密文接受路径，不能与上节类别差混为一谈。

{performance_section}

分块 decaps 均值供漂移检查：

| 块 | M1 未修 ns | M1 已修 ns | 已修/未修 − 1 |
|---|---:|---:|---:|
{chr(10).join(block_rows)}

bootstrap 按原脚本对单条样本独立重采样 1,000 次、种子 2026，未对块内自相关/块间漂移建模。其 CI 只描述本次数据，不能把负开销解释为修复加速，也不能直接归因于补丁本身。

## 7. 未完成项、错误及执行副本调整

正式主清单全部完成，`ERRORS.tsv` {'不存在（未记录阶段失败）' if not v['recorded_errors'] else '原文如下：'+chr(10)+v['recorded_errors']}。RTLF 状态计数为 `{json.dumps(v['rtlf_status_counts'],ensure_ascii=False)}`：未安装 R/相关依赖，没有 RTLF 结果，不作推断。在线 dudect 已按清单运行；逐次电池未导入在线日志、未运行离线回放，不能把电池中的 unavailable 误读为在线检测缺失。

先执行 QUICK，发现依赖清单缺少 M2 公共 KAT 需要的 `libssl-dev`，补装后验证 90/61/61 全通过，再从独立目录开始正式构建。QUICK 的补建历史及两类中间审计告警单列在其报告中，失败审计记录全部保留。

执行副本修正了失败片段保留、失败阶段停止、CTest 缺结果拦截、零 SE 合并权重对应关系和 p 值名称；依赖已安装时允许普通用户核验后继续，并补齐 libssl-dev。没有改变算法 C/H 源码、种子、样本预算或普通计时方法。原脚本、执行文档及完整差异均保存在 `env/execution-inputs/`。

Windows/WSL 准备过程中，首次重启后的虚拟机平台安装因 VMware 通知 DLL 失效路径回退；备份注册项并只修正 DLL 路径后，第二次重启成功。Ubuntu 包下载的 HTTP 502 通过将相同官方软件源改为 HTTPS 解决。准备日志、旧配置和注册项备份在 Windows 交付目录的 `preflight/` 中；这些准备故障发生在正式采集之前。

## 8. 交付与复核

- `RESULT.md`：本报告；`stats/SUMMARY.md`：逐次统计、合并、性能和 dudect 汇总。
- `raw/`、`perf/`：普通与性能原始 CSV、可用的元数据、在线 dudect 输出。
- `disasm/`、`memcheck/`、`logs/`：反汇编、秘密标记检查、构建/CTest/运行日志。
- `audit/`、`env/`：独立审计、哈希、环境、实际编译配置与二进制身份。
- Windows `completed/` 提供正式完整包、正式精简包、独立 QUICK 包及 SHA256 清单。精简包省去 CSV；完整包保留原始 CSV，但省去统计目录里与原始数据重复的 input.csv/normalized.csv，可从 raw/ 重算。

这些结果只作**未锁频 WSL 跨环境描述**，不改变主仓库 M1–M5 的冻结判定、不进入任何 Holm 家族、不与裸金属或 QUICK 数据合并。未检出不等于安全或常数时间。
'''
(out/'RESULT.md').write_text(report)
print(out/'RESULT.md')
