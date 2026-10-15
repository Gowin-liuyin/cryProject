# 多泄漏模块平台矩阵（2026-10-16）

本页为本轮汇总入口。S1 交付空表后由主控独占更新；每路完成立即记录一行。
状态须区分软件就绪、工具已执行、定位、统计与验收，不把前置完成写成模块完成。
架构见 [ARCHITECTURE.md](../../platform/ARCHITECTURE.md)，模块结果使用
[MODULE_RESULT.md](../../../templates/MODULE_RESULT.md)。

## 模块结果

| 模块 | 机制 | 案例类型 | 软件 / 工具状态 | 定位工具与结论 | 统计阶段与结论 | 未修 / 夹具开 | 已修 / 夹具关 | 证据路径 | 缺口 |
|---|---|---|---|---|---|---|---|---|---|
| M1 | 编译器消息位分支 | 既有真实历史案例 | 只引用原件 | 见原结论 | 见原结论，本轮无新增 | 既有记录 | 既有记录 | [原 RESULT](../r02-r04-close-20261016/RESULT.md) | 本轮不重新签收 |
| M2 | 秘密相关除法 | 真实 KyberSlash 历史路径 | 两版本与 varlat 已接通；完整解封装与除法热点微基准采集件均已资格化 | 未修三热点各 1 个 `div`、已修 0；varlat 未修 1280/3 对已修 0/0 | **已采数**：家族 m=6，Holm 拒绝 0；合并 Δ=+4.58 ns CI[−3.08,+12.25] | 定位阳性，端到端未检出 | 目标定位消失 | [RESULT](../m2-kem-20261016/RESULT.md)、[原件](../platform-collection-20261016/README.md) | 定位阳性 / 微基准未检出 / 端到端未检出，三层分列 |
| M3 | 秘密下标 LUT | 人工构造校准 | on/off 同树可构建，功能等价资格通过 | 新树 Memcheck on 1280/2 对 off 0/0；Microwalk on 臂 MI 1.922 bits（全场最高） | **已采数**：家族 m=6，Holm 拒绝 0；合并 Δ=−0.73 ns CI[−5.56,+4.10] | 定位阳性 | 关臂 Memcheck 0/0 | [RESULT](../m3-completion-20261016/RESULT.md)、[原件](../platform-collection-20261016/README.md) | 端到端未检出；Microwalk 为源码自建替代官方镜像 |
| M4 | 提前退出比较 | 人工构造校准 | vulnerable/ct 已重建（含截断窗口与预热），CTest 7/7 两配置 | Memcheck 秘密跳转报警对 ct 0；Binsec 反例对 bounded secure | **已采数**：家族 m=6，**Holm 拒绝 3**（全在 vulnerable 臂）；臂内合并 −4.089 ns CI[−4.215,−3.963] | 定位阳性 + 端到端阳性 | ct 臂 p=0.386/0.438/0.399 不拒绝 | [RESULT](../m4-completion-20261016/RESULT.md)、[原件](../platform-collection-20261016/README.md) | Binsec secure 为有界结论 |
| M5 | mlkem-native | 阴性对照 | 固定快照、完整解封装/measure/dudect 已接入并资格化 | 本机调用链确认；poison/varlat 0 未解释命中 | **已采数**：家族 m=3，Holm 拒绝 0；合并 Δ=−5.30 ns CI[−11.77,+1.16]，I²=0 | 不适用 | 阴性一致（预算内未检出） | [RESULT](../m5-completion-20261016/RESULT.md)、[原件](../platform-collection-20261016/README.md) | 阴性仅限本预算，不证明恒时 |

## 并行路状态

| 路号 / 名称 | 状态 | 交付 | 检查 | 阻塞 / 下一步 | 本地提交 |
|---|---|---|---|---|---|
| S1 / docs-skeleton | 完成 | 架构、模板、矩阵 | 链接/接口核对 | 无 | `4a44d79` |
| S2 / third-party-clone | 完成 | 六库源码、REPOS、S02 | 6/6 fsck=0、工作区干净 | 运行资格另验；部分许可证未知 | `1934047` |
| S3 / valgrind-varlat | 完成 | 原补丁、Linux 工具与日志 | help 可见 varlat 开关 | 无 | `49d0ebe` |
| S4 / kyberslash-version-audit | 完成（定位层） | 两快照、Linux 反汇编、动态日志 | varlat 未修 1280/3、已修 0/0；关闭选项两者 0/0 | 完整 KEM 与统计下一轮 | `8be7734` |
| S5 / stats-battery | 完成（软件接口） | C 统计复用、RTLF、离线 dudect | 两环境 CTest 1/1；Linux 真 RTLF 合成 11/10、dudect 离线正负对照 | 没有新模块硬件时间数据 | `68efc4b` |
| S6 / m5-mlkem-native-wire | 完成（前置接线） | 复用 reference/measure，三聚合目标通过 | 普通/动态参考资格各 5/5 | 原生阴性定位与统计未运行 | `e92aa47` |
| S7 / m3-fixture-lut | 完成（夹具与定位） | 人工 LUT 开/关 | 本机 2/2+2/2；Linux 2/2；开报警/关 0 | Pin/Microwalk 未就绪，未采数 | `4346e70` |
| S8 / m4-fixture-memcmp | 完成（夹具与定位） | 人工比较开/关 | 本机 4/4+4/4；Linux 4/4；提前退出报警/ct 0 | Binsec/solver 缺失，未采数 | `af9bd12` |

8 路本轮工作项成功、0 路失败；不表示 5 个模块均已完整验收。
主控统一入口提交 `aa4d920`，新增 7 项集成 CTest 在本机普通与 ASan/UBSan 两配置各 7/7。
审查与来源核对见 [S01_REVIEW](partials/S01_REVIEW.md)，完整交接见
[HANDOFF_DONE.md](../../../HANDOFF_DONE.md)。

## 汇总口径

- M1 仅引用已有封存证据，不改 `vendor/liboqs-0.10.0/`、`liboqs010-*`、
  `tooling-strengthen-*`、`r02-r04-*` 结论；本页不重新签收 M1。
- M2 优先钉未修/已修，分别报告产物、varlat、微基准和完整解封装统计；
  定位阳性与端到端未检出可以并存。
- M3/M4 必须写“人工构造校准”，不能算作新增真实 CVE；M5 阴性也须有实跑证据。
- 先冻结并本地提交 PLAN 再正式采数；dudect 不进 Holm，RTLF 也作单独交叉结果。
- 未运行、工具缺失、超时和失败须明确写出；未检出不等于恒时证明。
- CPU2/CPU6 采数由主控串行调度，退出必恢复并核对 `restore_match`；不自动 push。

## 本轮锁频采数与统计（2026-10-16，提交 `efca8a1` 冻结的四份 PLAN）

| 模块 | 家族 / m | Holm 拒绝 | 家族合并 Δ（ns）与 95% CI | I² | 三次运行 restore_match | 族外 online dudect max\|t\| |
|---|---|---:|---|---:|---|---|
| M2 | `m2_end_to_end_full_decaps_v1` / 6 | 0 | +4.58 [−3.08, +12.25] | 58.3% | 18/18 yes | 未修 4.68/3.05/3.66；已修 36.27/30.94/61.91 |
| M5 | `m5_reference_end_to_end_v1` / 3 | 0 | −5.30 [−11.77, +1.16] | 0% | 6/6 yes | 2.10 / 1.98 / 2.82 |
| M3 | `m3_lut_arm_end_to_end_v1` / 6 | 0 | −0.73 [−5.56, +4.10] | 12.5% | 12/12 yes | on 1.93/3.41/2.81；off 2.24/3.37/3.03 |
| M4 | `m4_compare_arm_session_v1` / 6 | **3** | −3.74 [−3.87, −3.62] | 98.6% | 18/18 yes | vuln 356.6/396.9/395.6；ct 2.06/1.90/2.27 |

共 **54 次**正式控制器运行全部 `restore_match=yes`，放行探针 20/20 在 ±2% 带内。
原件与逐运行证据见 [platform-collection-20261016](../platform-collection-20261016/README.md)；
RTLF 族外结果见 [platform-rtlf-20261016](../platform-rtlf-20261016/RTLF_RESULT.md)。

**本轮明确写下的阴性/未检出**：M2 完整解封装未检出可归因泄漏（定位层与 varlat 仍阳性）；
M5 阴性一致；M3 端到端未检出（定位层阳性）；M4 vulnerable 臂端到端阳性、ct 臂不拒绝。
M2 的 online dudect 阳性出现在**已修**臂，**不可归因于除法变体**，不作泄漏结论。
