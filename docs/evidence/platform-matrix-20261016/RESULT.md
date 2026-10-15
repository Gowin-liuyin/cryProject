# 多泄漏模块平台矩阵（2026-10-16）

本页为本轮汇总入口。S1 交付空表后由主控独占更新；每路完成立即记录一行。
状态须区分软件就绪、工具已执行、定位、统计与验收，不把前置完成写成模块完成。
架构见 [ARCHITECTURE.md](../../platform/ARCHITECTURE.md)，模块结果使用
[MODULE_RESULT.md](../../../templates/MODULE_RESULT.md)。

## 模块结果

| 模块 | 机制 | 案例类型 | 软件 / 工具状态 | 定位工具与结论 | 统计阶段与结论 | 未修 / 夹具开 | 已修 / 夹具关 | 证据路径 | 缺口 |
|---|---|---|---|---|---|---|---|---|---|
| M1 | 编译器消息位分支 | 既有真实历史案例 | 只引用原件 | 见原结论 | 见原结论，本轮无新增 | 既有记录 | 既有记录 | [原 RESULT](../r02-r04-close-20261016/RESULT.md) | 本轮不重新签收 |
| M2 | 秘密相关除法 | 真实 KyberSlash 历史路径 | 两版本与 varlat 已接通 | Linux 三热点未修各有 div、已修各无；varlat 1280/3 vs 0/0 | 未采数；微基准/完整解封装/正式统计均未运行 | 定位阳性 | 对应目标定位消失 | [版本审计](../m2-kyberslash-20261016/VERSION_AUDIT.md) | 待冻结时序合同并串行采数 |
| M3 | 秘密下标 LUT | 人工构造校准 | 开/关可构建，功能等价资格通过 | Linux Memcheck 32/1 vs 0/0 | 未采数 | 秘密地址报警 | 公开扫描无命中 | [RESULT](../m3-memaccess-20261016/RESULT.md) | Pin/Microwalk 与统计未运行 |
| M4 | 提前退出比较 | 人工构造校准 | vulnerable/ct 可构建 | Linux Memcheck 32/1 vs 0/0 | 未采数 | 秘密条件跳转报警 | ct 无命中 | [RESULT](../m4-compare-20261016/RESULT.md) | Binsec 与统计未运行 |
| M5 | mlkem-native | 阴性对照候选 | 固定快照、完整解封装/measure 已接入，参考资格通过 | 本机调用链确认；秘密标记工具未运行 | 未采数，不能报告阴性 | 不适用 | 尚无统计阴性验收 | [RESULT](../m5-mlkem-native-20261016/RESULT.md) | 待原生定位与阴性统计 |

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
