# 多泄漏平台报告准备件

审计时点：`main@ac46e62`，2026-10-16。**本目录是待填大纲和图源，不是已完成的正式报告。**
旧正式DOCX/PDF与旧证据保持原件；实测完成后另建新成稿，不把本目录的状态占位符当结果。

- [REPORT_OUTLINE.md](REPORT_OUTLINE.md)：逐章研究问题、现有证据、待填表图与允许结论。
- [EVIDENCE_MATRIX.csv](EVIDENCE_MATRIX.csv)：机器可读的基线结果层次，`not_run`不等于零或阴性。
- [figures/platform-evidence-matrix.svg](figures/platform-evidence-matrix.svg)：可直接编辑的原生矢量图源。
- [figures/platform-evidence-matrix.png](figures/platform-evidence-matrix.png)：2920×1620渲染预览。
- [figures/render_matrix.py](figures/render_matrix.py)：从CSV重建SVG，仅用于图源生成。
- [figures/REVIEW.md](figures/REVIEW.md)：实际渲染、逐格内容与视觉核验。

完整要求见 [COMPLETION_REQUIREMENTS](../../../docs/platform/COMPLETION_REQUIREMENTS.md)。
本准备件不新增时间样本，不运行密码算法，不改变M1结论，也不主张M2已统计可区分或M5已阴性通过。
后续每个实测单元需带上新证据路径、PLAN提交、源/ELF摘要、原始值、频率恢复与工具输出，
再由主控同步正文、表、图和总索引。

![ac46e62时点的平台证据矩阵](figures/platform-evidence-matrix.png)

图注：数字为工具错误次数/上下文数，不是样本量、效应量或攻击成功率。
缺口列是摘要，Microwalk条件降级及正式报告同步等仍须按完整要求验收。
最初Mermaid矩阵语法可渲染，但三轮图中文字仍被裁切，已停止该路线并采用原生SVG；
未交付裁切图，也未把该渲染器问题写成平台实验阻塞。
