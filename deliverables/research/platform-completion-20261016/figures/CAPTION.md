# 平台结果矩阵图注（2026-10-16）

**本图是结果图，不是计划图。** 每一格只写已有证据的实际状态：已执行的写执行范围与原文数字，
没有执行过的写“未运行”，锁频采数尚未回填的写 `«待主控数据»`。
图中不预填任何预期数值，也不把工具未报警、定位阳性或软件资格升级为统计或验收结论。

- 图源：[platform-evidence-matrix.svg](platform-evidence-matrix.svg)（原生矢量，文本可编辑，无 foreignObject）
- 预览：[platform-evidence-matrix.png](platform-evidence-matrix.png)（2984×1824，2 倍像素）
- 机器可读数据：[../EVIDENCE_MATRIX.csv](../EVIDENCE_MATRIX.csv)（含每行 `evidence_paths` 与 `filled_at`）
- 生成器：[render_matrix.py](render_matrix.py)（SVG）、[render_preview.py](render_preview.py)（PNG）

## 分类口径

| 分类带 | 模块 | 口径 |
|---|---|---|
| 真实历史案例 | M1、M2 | 固定上游提交的真实历史路径；不是本轮新造漏洞，也不重开 M1 已封存结论 |
| 人工构造校准 | M3、M4 | 明确标注的人工机制开关；用于校准检测器，**不计为新的真实 CVE** |
| 阴性对照候选 | M5 | 固定 mlkem-native portable reference；有限输入、固定工具范围内的观察 |

## 列与状态含义

- **软件资格与产物**：独立公开向量/边界/等价检查与普通、sanitizer 构建的实际通过数。
- **定位（工具与结论）**：动态秘密标记或反汇编的实际命中；“工具未运行”与“已执行且未检出”分列。
- **时间统计与复测**：锁频原始值、CI/Welch、参数族与 Holm、RTLF、在线 dudect 的实际状态；
  未执行时写 `未运行`，不给零效应或空白区间。
- **形式化 / 边界**：有界验证（含入口、边界、求解器状态）或“未运行/未主张”。
- 颜色只是辅助：灰色＝旧证据引用，蓝色＝已执行，橙色＝未运行（含 `«待主控数据»`）；
  状态词写在格内，不依赖颜色判读。

## 每格数字的证据路径（仓库相对路径）

| 模块 | 证据（相对仓库根） |
|---|---|
| M1 | [r02-r04-close-20261016/RESULT.md](../../../docs/evidence/r02-r04-close-20261016/RESULT.md)、[tooling-strengthen-20261015/RESULT.md](../../../docs/evidence/tooling-strengthen-20261015/RESULT.md)、[liboqs010-locked-20261015/README.md](../../../docs/evidence/liboqs010-locked-20261015/README.md) |
| M2 | [m2-kem-20261016/RESULT.md](../../../docs/evidence/m2-kem-20261016/RESULT.md)、[m2-kyberslash-20261016/RESULT.md](../../../docs/evidence/m2-kyberslash-20261016/RESULT.md)、[VERSION_AUDIT.md](../../../docs/evidence/m2-kyberslash-20261016/VERSION_AUDIT.md) |
| M3 | [m3-completion-20261016/RESULT.md](../../../docs/evidence/m3-completion-20261016/RESULT.md)、[NOTES.md](../../../docs/evidence/m3-completion-20261016/NOTES.md)、[m3-memaccess-20261016/RESULT.md](../../../docs/evidence/m3-memaccess-20261016/RESULT.md) |
| M4 | [m4-completion-20261016/RESULT.md](../../../docs/evidence/m4-completion-20261016/RESULT.md)、[formal-v1/](../../../docs/evidence/m4-completion-20261016/formal-v1/)、[m4-compare-20261016/RESULT.md](../../../docs/evidence/m4-compare-20261016/RESULT.md) |
| M5 | [m5-completion-20261016/RESULT.md](../../../docs/evidence/m5-completion-20261016/RESULT.md)、[PLAN.md](../../../docs/evidence/m5-completion-20261016/PLAN.md)、[m5-mlkem-native-20261016/RESULT.md](../../../docs/evidence/m5-mlkem-native-20261016/RESULT.md) |

## 图注边界

1. 格内数字是**工具错误次数 / 报警上下文数**（如 1280 errors / 2 contexts、32 / 1 对 0 / 0）或
   统计结论词，不是时间样本量、效应量、检出率或攻击成功率。
2. `«待主控数据»` 只表示锁频采数尚未回填；**不是阴性**，也不能读成“未检出”。
3. 定位阳性（含人工校准阳性）不等于已出现稳定物理时差；工具在有限输入内无报警不等于恒时证明，
   也不给出总体误报率为零。
4. M1 的时序数字（Δ +39.337 / +31.117 / +22.337 ns 对 -13.209 / +8.354 / -4.885 ns）是
   已封存原件的引用，不是本图生成时的新采集，其区间、预算与家族以原报告为准。
5. 完整交付条件与命令合同见 [COMPLETION_REQUIREMENTS.md](../../../docs/platform/COMPLETION_REQUIREMENTS.md)；
   本图不替代逐项验收。
