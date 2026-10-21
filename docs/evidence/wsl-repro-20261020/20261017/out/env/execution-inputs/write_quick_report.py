#!/usr/bin/env python3
import json
import pathlib

out = pathlib.Path('/home/cryrepro/cry-wsl-quick/out')
v = json.loads((out/'audit/validation.json').read_text())
assert v['status'] == 'PASS'
text = '''# WSL QUICK 预检结果

执行者：Codex，按用户授权在本机运行。日期：2026-10-17，Asia/Shanghai。

QUICK 主流程从 22:55:54 至 23:07:06 完成；补齐 M2 公共向量测试的验证于 23:09:38 完成。全部采集阶段退出成功，未产生 `ERRORS.tsv`。本文件仅记录预检，正式结果在独立的 `cry-wsl/out/` 中，不与 QUICK 合并。

## 环境和参数

Windows 11 专业版 25H2 / WSL2 3.0.3.0 / Ubuntu 24.04.5 LTS / 内核 6.18.54.1-microsoft-standard-WSL2 / Ryzen 7 8845H / 16 vCPU / Clang 18.1.3。用户确认插电、正常模式、采集期间不进行其他操作；系统电源计划为平衡。**未锁频、未关闭 boost**。构建及采集位于 WSL ext4 的 `/home/cryrepro/cry-wsl-quick`，使用普通用户 `cryrepro`。外部 `taskset -c 15` 绑核，实际进程亲和性见 `env/observed-affinity.txt`。程序元数据中的 `cpu_affinity=not_pinned` 是程序内固定文案，并不检测外层 taskset。

仓库基线 `04baad45ebb5ea4dba8d143d64c5031c906503d2`；每类 2,000 个样本，种子 31337 / 424242 / 7，各重复 1 次。

## 完成与核验

- 51 个普通计时 CSV，共 474,000 行，每类样本完整；12 个性能 CSV，共 420,000 行；5 份在线 dudect 日志，另有 3 个 dudect 原始 CSV。
- 独立 Python 审计与仓库统计电池的 51 个均值差全部一致（最大绝对差 0 ns）；标准误最大绝对差小于 1e-12 ns。没有删尾或筛选运行。详见 `audit/validation.json` 和 `audit/raw-manifest.json`。
- 首轮 CTest 为平台 88/88、M1 两版各 61/61。平台因缺少 `libssl-dev` 未启用两项 M2 公共 KAT。已补装、重新配置平台并复验：平台 **90/90**，M1 未修/已修各 **61/61**，均 0 失败。原 88 项日志保存在 `logs/before-openssl-dev/`。
- 补建 KAT 后平台二进制身份发生变化；已采集的 M2 六次及 M5 默认 O2 三次运行使用旧二进制，原 `.meta` 不变。重建前已经完成全量数据及二进制摘要核对，且保存了 `env/build-evidence/binary-digests.json`。末次审计明确列出这 9 次历史摘要匹配；没有将重建后的摘要冒充采集时摘要。
- M1 未修复 `-Os/-O2/-O3` 均为 512 次 Memcheck 报告，分别来自 1/8/15 个上下文；未修复 `-O0` 为 0/0。修复版四级均为 0/0。`-Os` 未修复为 `bt+jae`；修复版为 `bt+setb+call cmov_int16`。这些确定性证据与文档参考一致。
- 所有计时、性能、在线 dudect 数值见 `stats/SUMMARY.md`；M4 必须按人工构造校准解读。QUICK 用于验证流程，不代替正式结果。

## 排障与审计记录

原脚本的依赖列表未包含启用 M2 公共 KAT 所需的 `libssl-dev`，已在执行副本补齐。第三方补丁树 `vendor/liboqs-0.10.0-982c762/` 在本基线中显示为未跟踪目录，属于文档要求的独立 vendor 副本；没有改动受跟踪源文件，也没有修改忽略规则来隐藏该目录。初次审计把这一预期目录当作脏工作区，修正审计规则后通过。

另一次重建后的审计识别到了上述 9 次二进制身份变化；随后用重建前已保存、已核验的摘要进行历史身份匹配。所有中间 `validation-before-*.json`（包括 FAIL）均保留，没有删除失败记录。正式全量从依赖完整的全新构建开始，要求元数据直接匹配当前实际二进制。

脚本实际运行 3 臂 × 4 块，即 12 次性能测试；执行文档所谓 QUICK“3 次性能”与脚本不一致，本次按脚本运行并按实际数量报告。RTLF 未运行：没有安装 R/相关包；逐次电池会明确标为 unavailable，不能据此推断统计结果。在线 dudect 保留上游预热、端点丢弃及多检验行为，与普通 ns 原始数据不删尾是不同口径。

## 解释边界

未锁频虚拟化环境，仅作跨环境描述，不进入任何 Holm 家族，不与裸金属或正式 WSL 样本合并。未检出不等于常数时间或安全。仅凭性能差值不能归因于修复；CPU 动态频率、布局和调度均可能影响结果。上游 dudect 日志中的 “maybe constant time” 原文只表示当前预算内尚无证据，不作为安全结论。
'''
(out/'RESULT.md').write_text(text)
print(out/'RESULT.md')
