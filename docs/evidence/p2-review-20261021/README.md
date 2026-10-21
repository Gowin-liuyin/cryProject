# P2 收尾的独立复核记录（2026-10-21）

本目录记录 **2026-10-21 起对 P2 级最终交付物做的独立复核**：每一轮由独立审查员
（subagent）**从零开始**核查，不采信仓库里已有的「自检通过」结论，也不把上一轮
结论喂给下一轮；每一轮报出的问题位置由主控**逐条核实**，属实的修完并重出受影响产物，
不属实的写明理由；每轮的清单、处置与证据都落在这里。

**这些复核不构成竞赛方验收**：签字、盖章与官方平台上传仍须本人完成。

## 轮次索引

| 轮次 | 范围 | 问题数（阻断/应修/提示） | 状态 | 详见 |
|---|---|---|---|---|
| 第 1 轮 | 平台报告与证据一致性、官方报告 DOCX/PDF、附件三、截图说明 | 5 / 4 / 8 | 全部核实并处置（15 条属实已修、2 条按设计保留） | [ROUND-1.md](ROUND-1.md) |
| 第 2 轮 | 匿名性与包完整性、构建门禁可复跑性；文档间口径一致性与人工签收材料（两条线并行） | 10 / 22 / 6 | 全部核实并处置（2 条按设计保留） | [ROUND-2.md](ROUND-2.md) |
| 第 3 轮 | 证据链可复现性（预注册完整性、统计口径、证据是否被改写）；评审视角可读性（空图、源码进正文、表格断行、编号与图注）（两条线并行） | 5 / 10 / 17 | 全部核实并处置（8 条按设计保留或已先行修掉） | [ROUND-3.md](ROUND-3.md) |
| 第 4 轮 | 提交形态（三件套、匿名性、截图可信度、附件三）；陌生评审的可复现性（真的解包重跑）（两条线并行） | 8 / 14 / 24 | 全部核实并处置（少数提示项按设计保留） | [ROUND-4.md](ROUND-4.md) |
| 第 5 轮 | 冷读题面回答（逐条对题面）；红队反向验证（试图推翻每条「已满足 / 已核验」）（两条线并行） | 23 / 17 / 30 | 全部核实并处置（少数提示项按设计保留或部分不成立） | [ROUND-5.md](ROUND-5.md) |
| 第 6 轮 | 题面逐字对照（原文措辞 vs 回答）；只拿卷内数据独立复算（两条线并行） | 3 / 8 / 7 | 全部核实并处置（复算线 **29 项复算逐位吻合** ✓） | [ROUND-6.md](ROUND-6.md) |

## 每轮都要跑的核对（结果写在 `docs/evidence/platform-completion-20261016/final-audit-checks-20261020.json`）

```sh
python3 scripts/check_submission_consistency.py          # 交付物间一致性（页数、摘要、匿名、门禁）
python3 scripts/run_final_audit_checks.py \
    --csv docs/evidence/platform-completion-20261016/FINAL_AUDIT.csv \
    --out docs/evidence/platform-completion-20261016/final-audit-checks-20261020.json
python3 scripts/check_signoff_items.py                    # 签字清单的机器可核项
python3 scripts/check_report_r05_counts.py                # 报告与 R05 表格的计数一致性
python3 scripts/check_official_toc.py CACR2026EA16XZ-作品设计报告.pdf   # 目录页码与实际页码一致
python3 scripts/check_pdf_render.py CACR2026EA16XZ-作品设计报告.pdf    # 中文字形真的渲染出来
python3 deliverables/support/CACR2026EA16XZ-multi-leakage-platform-20261016/verify_package.py \
    deliverables/support/CACR2026EA16XZ-multi-leakage-platform-20261016/CACR2026EA16XZ-platform-<当前revision>.zip
```

## 复核过程中暴露的**结构性**教训（不只属于某一轮）

1. **「成包」不等于「成包可用」**：并行工作线出的 `final12-20261021` 里，报告的离线 HTML
   有一个坏链接（来源标记被写成 markdown 链接 `[E69](3)`），`verify_package.py` 直接失败。
   该包**从未通过自己的审计**，却已经躺在交付目录里——所以**每次成包后必须立刻跑
   `verify_package.py`**，并把失败的包明确标成作废（见支撑包 README）。
2. **文本层有内容 ≠ 字形能显示**：官方 PDF 曾整段丢汉字，而 `pdftotext` 仍能抽出中文。
   纯文本检查抓不到，必须有**渲染级**门禁（`check_pdf_render.py`）。
3. **目录页码要迭代到稳定**：无头导出不展开 TOC 域，静态目录与域的目录长度不同会让正文整体移位。
   必须「写目录 → 导出 → 再量页码」循环到稳定，再独立复核（`check_official_toc.py`）。
4. **并行改同一批文件时，审计不能硬写摘要**：审计的 T31/R-02 改成**不变量核对**
   （仓库报告与包内报告必须同源、页数与两遍 XeLaTeX 警告数必须与日志一致），
   审计脚本动态取「当前已通过包审计的最大 revision」，避免指向过期的包。
5. **改生成器，不要改生成结果**：`report-tables.json` 是 `emit_final5_tables.py` 的产物；
   直接改 JSON 会被下一次重跑覆盖（第 1 轮的 T22 修正就是这样被冲掉的）。
6. **「0 命中」必须带覆盖范围**：`direct_identity_markers: 0` 这类字段一度是**硬编码常量**，
   三个门禁在复核一个常量（假绿）。现在返回值里带 `identity_scan`（已扫后缀 / 未扫后缀 / 方法），
   并把 PDF 文字层纳入扫描——**包内 PDF 曾泄露裸主机名而门禁仍报 0**。
7. **官方件与平台报告要互为门禁**：平台报告改了而官方件没重出，两份文档会给出不同事实
   （本轮实测：网络预算量级 1/4/5/7 vs 1.3/4.5/5.7/7.7）。现由
   `scripts/check_official_vs_report.py` 自动抽取事实句逐字比对。
8. **核对命令会自指**：审计 P2-08 校验的是「上一遍实跑的明细」，改 CSV 后第一遍必然对不上。
   做法是记下 CSV 的 sha256 比对内容，并跑两遍；第二遍才是有效结果。
