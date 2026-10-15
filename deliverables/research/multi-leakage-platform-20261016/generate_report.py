#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""从显式状态、对照表和已存在证据生成文稿，不推断未运行实验的结果。

输入：report-data.json（模块状态与证据来源）、report-tables.json（题面第3/4/5条等对照表）。
输出：report.md、report.tex、index.html（离线展示）、platform-matrix.svg、evidence-snapshot.json。
实测数字必须能在 report-tables.json 或 report-data.json 指到的证据文件里逐字核对；
未执行写“未执行”，锁频采数未回填写 «待主控数据»。
"""
import hashlib
import html
import json
import re
import subprocess
from pathlib import Path

import r05_flowchart

DIRECTORY = Path(__file__).resolve().parent
REPOSITORY = DIRECTORY.parents[2]
R05_TABLE_PATH = "docs/R05-全流程排查表.md"
R05_FIGURE_TEX = "deliverables/research/multi-leakage-platform-20261016/r05-flowchart.png"
THREAT_TEX = "docs/evidence/r11-threat-20261016/threat-model.tex"
THREAT_POINTER = (
    "本章直接并入 T28 的威胁模型 LaTeX 片段（[E51](../../../docs/evidence/r11-threat-20261016/threat-model.tex)，"
    "已实测可独立编译：8 页、0 报错、0 缺字），本报告不改写其任何字节；独立中文稿见 "
    "[E50](../../../docs/evidence/r11-threat-20261016/THREAT_MODEL.md)。该章回答四件事：攻击者能控制什么、能看到什么、具备哪些能力；"
    "哪些内容明确不在本轮范围内以及为什么；本地高精度观测与远程网络之间的边界在哪里；以及本平台的结论如何分成"
    "「已执行且检出 / 已执行且未检出 / 未执行」三档。**网络路径未执行**：本轮没有任何网络采集产物，"
    "同机锁频结果不能外推远程可检出性。 [E50,E51,E58]"
)
FORBIDDEN_TOKENS = ["3.74", "3,74", "‑3.74"]
LINK_PATTERN = re.compile(r"\[([^\]]+)\]\(([^)]+)\)")
MATH_REPLACEMENTS = [
    ("×10⁻⁵", r"\texorpdfstring{$\times 10^{-5}$}{x10^-5}"),
    ("×10⁴", r"\texorpdfstring{$\times 10^{4}$}{x10^4}"),
    ("«", "「"),
    ("»", "」"),
    ("①", "(1)"),
    ("②", "(2)"),
    ("③", "(3)"),
    ("④", "(4)"),
    ("×", r"\texorpdfstring{$\times$}{x}"),
    ("→", r"\texorpdfstring{$\rightarrow$}{->}"),
    ("⇒", r"\texorpdfstring{$\Rightarrow$}{=>}"),
    ("↔", r"\texorpdfstring{$\leftrightarrow$}{<->}"),
    ("−", r"\texorpdfstring{$-$}{-}"),
    ("α", r"\texorpdfstring{$\alpha$}{alpha}"),
    ("β", r"\texorpdfstring{$\beta$}{beta}"),
    ("Δ", r"\texorpdfstring{$\Delta$}{Delta}"),
    ("≤", r"\texorpdfstring{$\le$}{<=}"),
    ("≥", r"\texorpdfstring{$\ge$}{>=}"),
    ("≈", r"\texorpdfstring{$\approx$}{~=}"),
    ("±", r"\texorpdfstring{$\pm$}{+-}"),
    ("‖", r"\texorpdfstring{$\|$}{||}"),
    ("÷", r"\texorpdfstring{$\div$}{/}"),
    ("·", r"\texorpdfstring{$\cdot$}{.}"),
    ("′", r"\texorpdfstring{$'$}{'}"),
    ("≠", r"\texorpdfstring{$\neq$}{!=}"),
]


def tex_escape(value):
    value = str(value)
    placeholders = {}
    for index, (symbol, replacement) in enumerate(MATH_REPLACEMENTS):
        if symbol in value:
            key = "\ue000" + str(index) + "\ue001"
            value = value.replace(symbol, key)
            placeholders[key] = replacement
    replacements = {"\\": r"\textbackslash{}", "&": r"\&", "%": r"\%", "$": r"\$", "#": r"\#", "_": r"\_", "{": r"\{", "}": r"\}", "~": r"\textasciitilde{}", "^": r"\textasciicircum{}"}
    long_token = r"[0-9a-f]{40,64}|[A-Za-z0-9_./%+~@=<>-]{18,}"
    parts = re.split(r"(" + long_token + r")", value)
    escaped = "".join(r"\texttt{\seqsplit{" + "".join(replacements.get(character, character) for character in part) + r"}}" if re.fullmatch(long_token, part) else "".join(replacements.get(character, character) for character in part) for part in parts)
    for key, replacement in placeholders.items():
        escaped = escaped.replace(key, replacement)
    return re.sub(r"\*\*([^*]+)\*\*", r"\\textbf{\1}", escaped)


def escape_plain(value, output_format):
    if output_format == "tex":
        return tex_escape(value)
    return html.escape(value)


def load_mermaid_source():
    """从 docs/R05-全流程排查表.md 原样取出 §5 的 mermaid 代码块；该文件一个字节也不改。"""
    text = (REPOSITORY / R05_TABLE_PATH).read_text()
    match = re.search(r"```mermaid\n(.*?)\n```", text, re.S)
    if match is None:
        raise ValueError("找不到 " + R05_TABLE_PATH + " 的 mermaid 代码块")
    return match.group(1)


def render_text(value, output_format):
    """按输出格式渲染单元格；markdown 链接在 tex 中降级为“标签（路径）”。"""
    value = str(value)
    fragments = []
    position = 0
    for match in LINK_PATTERN.finditer(value):
        fragments.append(escape_plain(value[position:match.start()], output_format))
        label, target = match.group(1), match.group(2)
        if output_format == "md":
            fragments.append("[" + label + "](" + target + ")")
        elif output_format == "tex":
            fragments.append(tex_escape(label) + r"（" + tex_escape(target) + r"）")
        else:
            fragments.append('<a href="' + html.escape(target) + '">' + html.escape(label) + "</a>")
        position = match.end()
    fragments.append(escape_plain(value[position:], output_format))
    return "".join(fragments)


def render_table(table, output_format, total_width=16.2):
    if output_format == "md":
        lines = ["**表 " + table["id"] + "　" + table["title"] + "**", "", "| " + " | ".join(table["columns"]) + " |", "|" + "---|" * len(table["columns"])]
        for row in table["rows"]:
            lines.append("| " + " | ".join(render_text(cell, "md") for cell in row) + " |")
        lines.append("")
        lines.append("注：" + render_text(table["note"], "md") + " [E01]")
        return "\n".join(lines)
    if output_format == "html":
        parts = ['<div class="table-block"><p class="table-title">表 ' + html.escape(table["id"]) + "　" + html.escape(table["title"]) + "</p><table><thead><tr>"]
        parts.extend("<th>" + html.escape(column) + "</th>" for column in table["columns"])
        parts.append("</tr></thead><tbody>")
        for row in table["rows"]:
            parts.append("<tr>" + "".join("<td>" + render_text(cell, "html") + "</td>" for cell in row) + "</tr>")
        parts.append('</tbody></table><p class="table-note">注：' + render_text(table["note"], "html") + ' <a href="#sources">[E01]</a></p></div>')
        return "".join(parts)
    column_count = len(table["columns"])
    first_width = 2.5
    available = total_width - 0.30 * column_count
    other_width = round((available - first_width) / (column_count - 1), 2)
    spec = "@{}>{\\raggedright\\arraybackslash}p{" + str(first_width) + "cm}" + "".join(">{\\raggedright\\arraybackslash}p{" + str(other_width) + "cm}" for _ in range(column_count - 1)) + "@{}"
    title_row = r"\multicolumn{" + str(column_count) + r"}{@{}l}{\textbf{表 " + table["id"] + r"　" + tex_escape(table["title"]) + r"}}\\"
    fragments = [r"\begingroup\small\setlength{\tabcolsep}{4pt}\renewcommand{\arraystretch}{1.25}", r"\begin{longtable}{" + spec + "}", title_row, r"\rowcolor{headergray}" + " & ".join(r"\textbf{" + tex_escape(column) + "}" for column in table["columns"]) + r"\\\hline", r"\endfirsthead", r"\rowcolor{headergray}" + " & ".join(r"\textbf{" + tex_escape(column) + "}" for column in table["columns"]) + r"\\\hline", r"\endhead"]
    for row in table["rows"]:
        fragments.append(" & ".join(render_text(cell, "tex") for cell in row) + r"\\\hline")
    fragments.extend([r"\end{longtable}", r"\noindent 注：" + render_text(table["note"], "tex") + r"\par\endgroup\vspace{3mm}"])
    return "\n".join(fragments)


def render_tex_matrix(modules, total_width=16.2):
    """PDF 内的矩阵用 longtable 画出：矢量、可换行、与 SVG 同一状态数据。"""
    first_width = 3.0
    other_width = round((total_width - 0.30 * 5 - first_width) / 4, 2)
    spec = "@{}>{\\raggedright\\arraybackslash}p{" + str(first_width) + "cm}" + "".join(">{\\raggedright\\arraybackslash}p{" + str(other_width) + "cm}" for _ in range(4)) + "@{}"
    fragments = [r"\begingroup\footnotesize\setlength{\tabcolsep}{4pt}\renewcommand{\arraystretch}{1.2}", r"\begin{longtable}{" + spec + "}", r"\rowcolor{headergray}" + " & ".join(r"\textbf{" + tex_escape(column) + "}" for column in ["模块 / 机制", "软件资格", "定位", "时间统计", "形式化 / 边界"]) + r"\\\hline", r"\endfirsthead", r"\rowcolor{headergray}" + " & ".join(r"\textbf{" + tex_escape(column) + "}" for column in ["模块 / 机制", "软件资格", "定位", "时间统计", "形式化 / 边界"]) + r"\\\hline", r"\endhead"]
    for category in ["真实历史案例", "人工构造校准", "阴性对照候选"]:
        fragments.append(r"\rowcolor{headergray}\multicolumn{5}{@{}l}{\textbf{" + tex_escape(category) + r"}}\\\hline")
        for module in [item for item in modules if item["category"] == category]:
            fragments.append(" & ".join(tex_escape(value) for value in [module["id"] + " " + module["name"], module["software"], module["localization"], module["statistics"], module["formal"]]) + r"\\\hline")
    fragments.extend([r"\end{longtable}", r"\noindent 图1：平台证据矩阵（结果图，不是计划图）。灰色为封存引用，蓝色为已执行，橙色为未运行（not run）；状态同时以文字显示。\par\endgroup\vspace{3mm}"])
    return "\n".join(fragments)


def get_sections(data, tables):
    modules = data["modules"]
    placeholder = "«待主控数据»"
    return [
        ("研究对象与证据口径", [
            "平台把编译器引入分支、秘密操作数除法、秘密访存地址和提前退出比较分开处理，并以固定参考实现作为阴性对照候选。统一接口的目的，是让不同机制接受相同的来源记录、调用窗口、数据格式与结果审查，而不是用模块数量代替安全结论。",
            "M1 与 M2 是固定提交的真实历史路径；M3 与 M4 是人工构造校准（前者为秘密下标查表，后者为提前退出比较），其阳性只能检验检测器能否识别目标机制，不计为新的真实 CVE；M5 是固定 mlkem-native 的阴性对照候选。四条证据链分列，不互相冒充。",
            "本报告把四种状态写全并区分：(1) 已执行且检出（含人工校准的目标机制）；(2) 已执行且未检出，必须带工具、输入范围与调用边界；(3) 未执行，一律写“未执行”或 not_run，不写成阴性或未检出；(4) 结构性未做的检查写“未执行”（如题面第 5 条中的“数据相关循环”），它不是占位符、也不是阴性。本轮 M2–M5 的锁频家族统计、Mona 对 M2 对照、RTLF 族外交叉（42/42）与 M2 除法热点微基准层都已实际执行并回填，**报告内已无 «待主控数据» 占位符**。软件资格、源与产物机制、工具定位、原始时间观察、正式统计与竞赛验收互相独立。",
            "完整完成条件与命令合同以 [E01](../../../docs/platform/COMPLETION_REQUIREMENTS.md) 为准；M1 的旧范围保持封存身份，本报告不重做、不改写。 [E01,E02,E10]"
        ], []),
        ("平台架构与机制矩阵", [
            "共享层记录公开输入、源与二进制身份、全调用测量窗口、类别乱序、逐次原值、环境和恢复；统计层输出均值差与区间、参数检验族、RTLF 与在线 dudect 的独立结果；动态层使用秘密标记、可变时指令检查和反汇编；有界验证层单独记录秘密模型、入口、边界与探索完成性。",
            "各层证据不可互相替代：静态存在除法不说明处理器已出现可测时差，工具报警次数不是采样量，功能测试通过也不表示统计阴性。下图按「真实历史案例 / 人工构造校准 / 阴性对照候选」分组并逐层显示状态，橙色格是结构性未运行（如“数据相关循环”未做专门检查）。本图是结果图，不是计划图：没有执行过的格子不预填数值。 [E03-E08,E10]"
        ], ["FIGURE"]),
        ("统一测量与统计方法", [
            "普通计时应覆盖声明的完整调用；输入生成、分配、日志、结果消费与 I/O 位于窗口外。热点微基准和独立夹具必须另标调用边界，不与完整解封装混合。普通长尾保留；动态检查产物与正式采集产物分开。源、未提交改动摘要、编译器、选项、ISA、时钟单位、种子、CPU 与二进制摘要共同限定结果。",
            "正式采数前须冻结并本地提交 PLAN，写明主类对、样本预算、停止条件、复测与参数假设族。锁频任务由主控在 CPU2/CPU6 串行调度：boost 关闭、performance、约 4.30 GHz、taskset，并保存进入、采中、退出记录；退出必须实际核对 restore_match。请求频率、可见回读与真实物理恒频是不同声明。本轮 M2–M5 的 54 次控制器运行全部 restore_match=yes，放行探针 20/20 落在 4300000 ±2% 且跨度 ≤50000 kHz；这是工程控制观测，不主张逐调用物理恒频或物理误差界。 [E19]",
            "现有 C 电池使用两组样本均值、样本方差、Welch t 与自由度；95% 区间与 p 值采用大样本正态近似（z=1.9599639845），不能称有限样本精确 Student-t。零方差、数据不足、缺工具或失败均单列状态。参数 p 按事前家族做 Holm；RTLF 固定 α=.01；dudect 最大 t、RTLF 二值结果与 Mona 结果不伪造为 p 纳入 Holm。",
            "本轮冻结的家族口径：M2 与 M5 的家族成员为主类对 × 3 次运行 × 2 版；M3 与 M4 的家族成员为臂内主类对 × 3 次运行 × 2 臂 = m=6，跨臂 on/off 对比只作受控对照（含二进制级常数偏移），不进 Holm 家族；RTLF（α=.01、seed 2026101605、bootstrap 10000，只给二值结论）与 online dudect 一律族外、不进 Holm；RTLF 检验的是分布差异（含尾部与分位），Welch/CI 检验的是均值差，两者分列、互不替代。本轮 RTLF 42/42 完成、无 blocked/failed：no_difference_detected 30 项、difference_detected 12 项。M4 与其 Welch/Holm 方向一致（vulnerable 主类对与截断对照各 3/3 检出、ct 各 3/3 未检出），是两种方法在同一批数据上的独立印证；M2 主类对 6/6 检出，但**未修与已修两个臂都检出**，因此不可归因于除法变体，与 Welch/Holm 拒绝 0 的差异最一致的读法是类构造（message-zero 与 message-ones 各自是同一份确定性密文的 10000 次重复，而 bit-flipped 与 random 逐样本变化）加上未受控漂移，**不据此作任一方向的泄漏结论**；M3 12/12、M5 6/6 未检出。家族实际运行结果：M2 m=6 拒绝 0（合并 Δ +4.58 ns，CI [−3.08, +12.25]，I²=58.3%）；M3 m=6 拒绝 0（−0.73 ns，[−5.56, +4.10]，I²=12.5%）；M4 m=6 拒绝 3 且全在 vulnerable 臂；M5 m=3 拒绝 0（−5.30 ns，[−11.77, +1.16]，I²=0%）。**M4 的家族窗口把泄漏臂与不泄漏臂混在一起（I²=98.6%），因此本报告只引用分臂数值：vulnerable 臂 Δ −4.089 ns、95% CI [−4.215, −3.963]；ct 臂 Δ +0.055 ns、95% CI [−0.363, +0.473]；家族窗口的合并 Δ 不在正文、表或图中出现。** [E01,E08,E19,E20]"
        ], []),
        ("题面第 1 条：向量来源与修复语义等价", [
            "题面第 1 条要求实现或接入符合规范的 ML-KEM 密钥生成、封装与解封装，并用公开或主办方提供的测试向量验证算法正确性，且不得通过修改密码算法安全语义的方式换取常数时间效果。本节把「跑过哪些向量」与「修复前后的密码语义是否等价」分列：前者只说明功能一致性，后者回答「常数时间改造有没有改变可观测输出」。",
            "下表逐行给出「模块 × 版本」实际跑过的公开向量例数、通过数、日志与来源标识。**不把文件里的例数当成通过数**：M1 两版各有 20 例密钥校验记「不适用」（该历史 liboqs 封装层没有输入校验入口），因此「例数 80 / 通过 35」必须连备注一起读。**M1 keygen 0/25 是 ipd 与最终稿的真实差异，不是本驱动或远端环境的问题，更不是向量装错**：liboqs 0.10.0 接入的是 FIPS 203 初始公开草案实现，其 K-PKE.KeyGen 的 `hash_g` 没有参数集域分隔字节，与最终稿参考的 `MLKEM_SYMBOLS + 1` 字节输入不同，keygen 期望值必然不同；而 encap（用向量给定的 ek 与 m）与 decap（用向量给定的 dk 与 ct）与最终稿一致，这正是 25/25 与 10/10 通过的原因。**M3 与 M4 是人工构造校准夹具**，其阳性只用于检验检测器能否识别目标机制，不计为新的真实 CVE。 [E32]",
            "等价性一节对每一对「未修 / 已修」实现，用同一份驱动、同一份公开输入在两版上分别运行并比较**逐例输出摘要文件**：三对摘要 diff 全空，另有 1000 例由公开确定性测试种子派生的额外输入（一半随机密文、一半逐字节篡改密文），以及按 FIPS 203 §7.3（M1、M3）或 Kyber round3 §1.4（M2）判定的隐式拒绝检查。**摘要文件按 32 字节/公开例 + 64 字节/额外例计，实际文件大小与例数一致**，说明每版都跑满了公开例与 1000 例额外输入，不是「少跑一部分所以看起来相同」。 [E33]"
        ], ["T12", "T13"]),
        ("题面第 2 条：测量环境、异常样本规则与稳健性", [
            "题面第 2 条要求建立可重复的高精度时间测量框架，说明处理器、操作系统、编译器、优化级别、CPU 频率管理、测试次数及异常样本处理方法，并尽可能降低系统调度、缓存和后台进程造成的随机干扰。本节按「登记了什么」「样本怎么处理」「结论对方法有多敏感」三段回答，并把限制一并写出来，不单独列成就。",
            "环境登记共 **28 项**，每一项都有原始命令与原始输出（长输出给摘录并指向 `raw/` 下的完整原文），含 5 组实际编译行与 ELF 摘要核验、计时源与 `clock_resolution_ns`、读钟开销实测、SMT 状态、`isolcpus`、IRQ 亲和、后台服务快照与频率节点回读。**必须一起读的两条限制**：(1) 本机 `isolcpus` 为空、SMT 未关闭、系统仍有 39 个 running service，`taskset` 亲和性加写频不是内核级 CPU 隔离；(2) 读钟开销均值 17.4–17.5 ns、最小步进 10 ns，而 M4 的比较步窗口只有 20–30 ns，**读钟开销与被测窗口同量级**，本批数据的**有效计时量化尺度约 10 ns**，与 M2/M3/M4/M5 关心的 4–30 ns 效应同量级。 [E34,E39]",
            "异常样本处理与主分析口径一致：**主分析保留全部样本，不删离群值、不裁尾、不插值、不平滑、不扣读钟开销**（与 `docs/timing.md:34` 逐字一致），冻结家族成员一律用全样本 `n0 = n1 = 10000` 原值。主分析之外只允许三种族外敏感性方法：p99.9 截尾均值差、中位数差与 Hodges–Lehmann 位置差；规则在写文件时已经执行完毕，不存在「看结果再定规则」。 [E35]",
            "稳健性分析在 **64 个类对**（含 21 个已冻结 Holm 家族成员与 43 个族外对照）上用四种方法重算，得到 **12 个「CI 含 0 / 不含 0」翻转**：其中 7 个属于已冻结家族成员、5 个属于族外对照。**如实写：没有任何翻转改变 Holm 判定**——家族与其 p 值在 `efca8a1` 已冻结，三种稳健方法一律族外，本页不重算 Holm、不改任何 p 值。翻转的性质是「均值型检验与位置型检验的功效差」或「约 10 ns 量化下秩方法失效」，**不是新的泄漏证据**；也不能用「12 个翻转」反推总体误报率（未校正、且各方法高度相关）。 [E36,E37]"
        ], ["T14", "T15"]),
        ("检测—定位—修复—复测：四段链状态", [
            "检测段回答“不同类别的执行时间是否可区分”，必须给样本预算、描述统计、区间与检验族；定位段回答“差异对应源码或产物中的哪个机制”，必须给工具、命中位置与实际调用边界；修复段优先使用上游官方修复，人工校准使用明确标注的目标机制开关，并先核对功能等价与拒绝语义；复测段在同规程下独立再运行，比较修复或关闭前后的同向性与稳定性。",
            "四段不能互相顶替：定位阳性不能填统计格，统计未运行不能写阴性，官方修复存在也不等于本机统计已复现。下表逐模块给出四段链的实际状态；M1 为已封存原件的引用，本轮不重做。"
        ], ["T1"]),
        ("题面第 3 条对照：输入分类与测试", [
            "题面第 3 条要求至少两类具有明确区别的解封装输入、足够次数的重复实验并记录解封装时间，且不应只比较长度明显不同、路径完全不同的数据。平台的做法是：合法密文之间只改解密消息位（message-zero 与 message-ones，同为等长合法密文），异常输入使用同长度的位翻转、随机与验证失败密文；长度类拒绝在封装层先检查，不计入内核类别样本。",
            "重复次数与时间记录按模块分列：M1 已完成每类 10000 值 × 3 次独立运行；M2–M5 本轮同样完成每类 10000 次、预热 100（窗口外）与 r1/r2/r3 三次独立运行（换种子、换物理核），共 54 次控制器运行全部 restore_match=yes。定位层的 10 次完整标记调用（M3/M5）是有限动态检查，不作为统计样本。此外，R03 另做了一组**族外**的异常输入对照（长度正确的破损密文与长度不足的截断密文对合法密文，3 臂 × 3 种子、每类 10000 次、18/18 restore_match=yes），用来回答「异常输入会不会引出额外的可区分路径」；它不进 Holm、不改任何既有判定，详见第 13 节。 [E19,E28]"
        ], ["T2"]),
        ("题面第 4 条对照：侧信道统计检测", [
            "题面第 4 条要求用统计方法判断不同输入类别是否存在显著可区分性，可使用均值、方差、分位数、置信区间与适当的统计检验，且不能仅凭少量样本或单次测试结论。平台实现分三层：描述统计（均值、标准差、分位数）、参数推断（Welch 均值差与 95% 正态近似区间、Holm 逐步校正）与族外交叉（RTLF α=.01、在线 dudect、Mona 统计对照）。",
            "M1 三层均已执行，并在换种子、换物理核两次独立复测上复现；M2–M5 本轮完成参数层（Welch 95% 正态近似区间与 Holm）与族外 dudect：M2/M3/M5 未拒绝、M4 在 vulnerable 臂拒绝 3 项。工具自身的合成正负校准只证明软件接口，不填充密码实现的结果。 [E20]"
        ], ["T3"]),
        ("题面第 4 条补充：功效 / MDE、分位数差与分布图", [
            '本节把题面第 4 条的统计方法再往前推两步：一是回答「这套预算能分辨多大的效应」（事后功效与最小可检测效应 MDE），二是回答「换一种位置型统计量，结论是否还站得住」（分位数差 bootstrap 区间、ECDF 与箱线图）。两项都是**只读复算**：输入全部是已提交的锁频采集 CSV，不重新采集、不改动任何已有证据文件、不做密钥恢复。',
            'MDE 按两样本双侧 α、功效 80%、等 n 的最小可检测效应公式计算，Holm 校正后的有效 α 取 α/m。**一句话结论**：M2/M3/M5「端到端未检出」的确切含义是，在本机、本编译产物、本类对与本次样本预算下，观测到的类间均值差小于本设计的最小可检测效应（**M2 约 25–67 ns、M3 约 18–34 ns、M5 约 14–28 ns**），所以这套预算**分辨不出**任何小于该量级的效应；**「未检出」= 观测效应 < MDE，不等于零效应**，也不构成恒时证明或物理泄漏界。MDE 用本次实测 SD，属事后（post hoc）功效描述，不改变任何已提交的 Holm 判定；M4 vulnerable 臂的 |Δ| 远大于其 MDE（最坏 1.47 ns 对 |Δ| ≈ 3.5–4.4 ns），这正是「该臂的效应大到这套预算足以分辨」与「该臂分辨不了」的分界。 [E38]',
            '分位数差用 p10/p50/p90/p99 的差（class0 − class1）与 bootstrap 百分位 95% 区间（B = 10000，两类各自独立有放回重抽样，固定种子）。41 个主类对 × 4 个分位数共 164 条判定：88 条同向、13 条方向反向、24 条判定翻转，全部逐条列出、不做选择性汇报。**两条必须一起读的限制**：(1) 本批数据的**有效计时量化尺度约 10 ns**（相邻不同取值间隔的中位数 9 ns、逐类对 9–10 ns），均值可以靠 n = 10000 平均出 1 ns 以下的差异，**分位数只能落在约 10 ns 的格点上**；(2) 因此 M4 vulnerable 出现「均值差 3/3 显著、分位差 p10/p90/p99 恰为 0」的分歧——**不能用 M4 的分位数差去复核 M4 的均值结论**，两边都只能用各自的口径表述。分位数差的翻折不改变 M2 家族 Holm 不拒绝的结论，也不构成泄漏声明。 [E39,E40]',
        ], ['T16', 'T17']),
        ("题面第 5 条对照：六类泄漏来源 × 解封装步骤", [
            "题面第 5 条列举六类泄漏来源——敏感条件分支、提前返回、可变时间比较函数、数据相关循环、数据相关内存访问、失败路径及异常处理——并要求说明其与 ML-KEM 解封装流程的对应关系。下表按四个步骤逐格给出“查了什么工具或方法、结果如何”：解密（indcpa_dec 与 poly_tomsg 消息解码）、重加密（indcpa_enc）、比较（verify ct 与 ct'）、隐式拒绝（J(z‖ct) 与统一错误路径）。",
            "表格只写已有证据：M1 为真实历史案例，已有 Valgrind、反汇编与三次独立统计；M2 为真实历史案例，静态除法差异与热点探针 varlat 已执行且为阳性，完整调用端到端统计已执行但未检出（Holm 拒绝 0，CI 含 0）；M3 与 M4 的阳性全部为人工构造校准；M5 的 0 errors/0 contexts 只覆盖固定源码、编译器与有限输入。没有证据的格子写“未执行”。KyberSlash 的秘密操作数除法不属于题面六类，单独列在末行以免与“可变时间比较函数”混淆。本表按四个步骤展开；R05 的 90 格排查表（3 实现 × 5 步骤 × 6 类）是同一批证据的逐格版本，见第 11 节，修复手段与审计见第 12 节。 [E30]"
        ], ["T4"]),
        ("题面第 5 条补充：R05 全流程六类来源排查表（90 格）", [
            "题面第 5 条除要求说明六类来源与解封装流程的对应关系外，还要逐格给出「查了什么、结果如何」。R05 排查表把对象定为 3 个实现（M1 liboqs 0.10.0 未修 / 982c762 已修、M2 pq-crystals kyber768 a621b8d / 272125f、M5 mlkem-native b3ba7b3 参考）× 5 个步骤（解密、哈希 G/H/J、重加密、密文比较、隐式拒绝 / cmov）× 6 类来源（提前返回、可变时间比较、数据相关循环、数据相关访存、失败路径、异常处理）＝ **90 格**；每格只写三件事：结论（存在 / 不存在 / 不适用 / 未检查）、证据（函数名 + 反汇编地址或行号，或工具输出路径）、修复点（上游提交或本项目补丁，没有就写“无”）。**阴性的含义被收窄为**：在下列固定源码、固定编译器与选项、固定产物上，已查工具没有报出该类来源；它不覆盖任意输入、任意编译器或微架构，**不是物理恒时、不是总体误报率、不是密钥恢复**。人工构造的夹具一律标注“人工构造校准”，不当作真实历史实现。 [E30]",
            "**90 格汇总：存在 5、不存在 74、不适用 10、未检查 1**（每格只计一次，计数由该文件正文 15 张表逐行程序化统计得到）。5 个「存在」格的归属是 M1 两个、M2 两个、M5 一个；10 个「不适用」全部是异常处理 × 该函数不可能失败；**唯一的「未检查」格是 M2 重加密 × 提前返回**——该实现的 `poly_frommsg` 与 M1 未修源码逐字相同，但本轮没有对它出反汇编，**不把“源码相同”当“产物相同”**，补做方式是对同一 ELF 运行 `objdump -d --disassemble=pqcrystals_kyber768_ref_poly_frommsg`。M5 的那个「存在」格是 `mlk_kem_check_sk` 在 sk 完整性检查失败时的提前返回，**只携带公开信息、不可利用**，属上游有意的 FIPS 203 §7.3 检查而非缺陷，已如实登记。 [E30]",
            "**修复点**：M1 的两处（重加密 / 提前返回、隐式拒绝 / 可变时间比较）由同一份官方补丁 **982c762** 覆盖（`setb` + `cmov_int16`，以及 `verify.c` 的值屏障）；M2 的两处由 **272125f** 覆盖（解密侧经中间提交 dda29cc 只修 KyberSlash1，完整修复才是 272125f）。 [E30]",
            "**必须一并记住的边界**：(1) 本轮 M4 的 Binsec 参数 -checkct-features **只开了 control-flow 与 memory-access 两项，未开乘法 / 除法检查**（工具帮助原文为 “Multiplication and division checks are experimental”），因此**现有 Binsec 结果不能用来判定 M2 的 `div` 类来源**，M2 第 2 类的判定全部来自反汇编与 varlat；(2) M1 隐式拒绝 × 可变时间比较是「机制存在、未在本产物上观测到分支」，证据是钉版 `cmov` 缺值屏障且 982c762 恰好补了它，不是在 M1 产物上看到了跳转；(3) M1 隐式拒绝 × 失败路径的强度弱于 M2 / M5，本轮没有出 `cmov` 调用点的反汇编；(4) M2 的除法机制只在 `-Oz` 产物成立，换优化级别会让它静默消失。这些边界都已写进该表本体。 [E30]",
            "下图是 R05 排查表 §5 mermaid 流程图的等价静态渲染（同一份节点文字、三条主链、同一套颜色语义；虚线箭头是修复映射，边标签原样写在图注里）。**mermaid 源码原样保留在 docs/R05-全流程排查表.md §5 与本报告的离线 HTML 中**；PDF 只能承载静态图，故此处用等价渲染，不改变任何一格结论。 [E30]"
        ], ["T10", "T11", "R05_FLOW"]),
        ("题面第 6 条：修复手段映射与泄露渠道审计", [
            '题面第 6 条有两条独立要求：一是针对已发现问题采用常数时间比较、掩码选择、固定循环次数、统一错误处理或消除敏感数据相关分支等方式修改；二是**防护过程中不得将私钥、中间敏感数据或验证结果通过日志、异常信息等其他渠道泄露**。本节把这两条分开回答，第一条用修复手段映射表，第二条用泄露渠道专项审计；**结论是前者满足、后者有一处低危缺口**。',
            '映射表按七个题面分类逐行给出「修复点（上游提交或本仓库补丁路径）↔ 方法分类 ↔ 证据路径 ↔ 是否人工夹具」。**覆盖 5 个模块**：M1 的三处由同一份官方补丁 `982c762` 覆盖（消除数据相关分支、`cmov` 掩码选择、`verify.c` 值屏障），M2 的两处由 `272125f` 覆盖（消除数据相关除法；中间提交 `dda29cc` 只修 KyberSlash1，不能当作完整修复），M3 的四处与 M4 的两处是**人工构造校准**补丁（成对的正反面对照），**M5 的四行不是修复**，是上游参考实现既有做法，表中逐行声明。M2 另有一行登记「未修复的缺口」：`poly_frommsg` 的数据相关分支在两个被测版本上都在，`272125f` 不碰它，如实登记而不是伪装成修复。 [E43]',
            '泄露渠道审计的对象是本工程自有实现与平台 harness（128 个 C 源/头文件、1048 个可能送出进程边界的调用点），其中 **122 条接触秘密相关标识符的调用点逐条人工判定**：**秘密内容泄露 0 条**——没有任何把共享密钥、私钥、拒绝种子或内部消息的字节写进 stdout、stderr、返回码或 errno 的语句。动态侧：7 种输入模式（1 合法 + 6 隐式拒绝）各 120 次，本机与远端两次独立运行，退出码唯一值均为 0、stdout/stderr 逐字节一致、`diff -u` 0 个差异块；Memcheck 的秘密标记下 **0 errors**（并给出能稳定报出 `Syscall param write(buf) points to uninitialised byte(s)` 的 canary 负对照，rc = 99，证明该通道有效）；**7/7 个计时 fence-to-fence 窗口通过白名单核对，窗口内无 I/O、无日志、无分配**。 [E42]',
            '**如实写的缺口（发现项 F1，低危）**：`tools/platform_m2/collector.c` 的功能门在失败时把批级的接受/拒绝汇总写进 stderr、进程退出码与 meta 的 `run_status`；该计数由内层重加密比较的通过/失败信息累加而来，因此「同一批输入在不同实现或不同构建下退出码不同」本身是一个可观察信号。**边界**：该路径只在门失败时可见（正常采集路径 rc 恒 0、stderr 恒空），且是本批所有行的汇总、不逐行不逐类；本轮**未构造门失败场景**，该失败分支只做了源码判定。因此题面第 6 条在本报告中记为**部分满足**，而不是满足：需按 R06 §1.3 的建议（把门失败信息降级为不含计数的固定文本，并把计数只写进调用方指定的 meta 文件）修复后重跑 R06 §2 的动态 diff 与 §3 的 Memcheck。**这不影响任何既有统计判定，也不影响「秘密内容泄露 0 条」的结论。** [E42,E58]',
            '审计明确列出的**未覆盖面**同样随结论一起读：未扫描上游 `vendor/`、`sources/`、`third_party/`；未执行网络路径的端到端差分；未检查进程名与命令行、打开的文件描述符、内存映射、core dump、`wait4` 资源用量、信号、`/proc/<pid>/stat`、子进程树、运行目录下的文件名与 mtime。这些都能成为侧信道，需要单独专项。**本审计不构成恒时证明，也不主张「零泄露」**，且所有实跑均为非锁频、仅功能性检查，不得引用为频率结论或统计结论。 [E42]',
        ], ['T18', 'T19']),
        ("题面第 3 条补充：R03 格式破损 / 截断族的族外对照", [
            "本节的对照对象是「长度正确但内容破损」与「长度不足」两类异常输入，与主检验的 message-zero / message-ones 不同：三臂（M1 未修 liboqs 0.10.0、M1 加官方修复 982c762、M5 mlkem-native b3ba7b3）× 三个种子（31337、424242、7），每类 10000 次、预热 100 在窗口外；三个输入类是 valid（一份固定合法 ML-KEM-768 密文 1088 B）、malformed（同一份密文 u 字段前 960 B 置 0xFF、v 字段后 128 B 置 0x00，长度仍为 1088）与 truncated（同一份密文只喂 1087 B）。采集由唯一锁频控制器串行调度（boost=0、governor/EPP=performance、min=max=4300000 kHz、taskset -c 2|6）：3 臂 × 3 种子 = 9 次 measure + 9 次族外 online dudect = 18 次控制器运行，**18/18 restore_match=yes**、worker_exit_code=0、放行探针全部在 ±2% 带内。证据路径：docs/evidence/r03-malformed-20261016/ 下的 PLAN.md、RESULT.md、R03/<run>/ 与 logs/status.log。 [E28,E29,E31]",
            "**对照 A（valid − malformed）**：9 个 Δ 全部落在 +9.8 ～ −3.2 ns 之间，**9/9 的 95% 正态近似 CI 含 0，9/9 的原始 p ≥ 0.28（最大 0.9552）**，方向在两臂之间来回摆动（未修臂 +7.9/+1.6/−3.2，已修臂 +4.7/+9.8/+0.5）。这与「隐式拒绝路径按设计就走完整重加密，破损密文与合法密文耗时一致」的预期相符：**未检出额外的可区分路径**。这**不是恒时证明**，只覆盖本机、本编译产物、本样本预算。 [E28]",
            "**对照 B（valid − truncated）**：截断路径在三臂上的实测均值是 **23.1–23.4 ns**，比完整解封装低约 3 个数量级；Δ ≈ 29.3 µs（M5）/ ≈ 55.1 µs（M1）。这里的原始 p 是双精度下溢后原样打印的 `0`，**是下溢，不得当作精确零**；差异本身已由 CI 说明（例如 M5 的 [29335.1, 29347.7] ns）。该耗时**与臂无关**，说明它在进入 KEM 之前就命中了封装层的**公开长度检查**——长度是公开输入，按固定路径常数时间拒绝本来就是正确行为，**这是接口语义，不是秘密相关泄漏**。 [E28]",
            "**族外 online dudect**（该入口自带的 message-zero vs message-ones 类对，因为 dudect 需要两个都能跑完的类）：M1 未修臂三次末批 max|t| = **10.78 / 11.43 / 12.02**（越过上游 >10 阈值），M1 已修臂 = 1.12 / 2.05 / 2.01，M5 = 1.35 / 1.52 / 2.00（均未越过）。它与 M1 既有定位结论（未修产物上 `poly_frommsg` 的消息位分支存在、982c762 后消失）**同向**，只作族外印证；**最大 t 不转伪 p、不进 Holm**。 [E28]",
            "**为什么不进主检验**（设计性理由，不是数据性理由）：(1) FIPS 203 §7.3 的隐式拒绝本来就不论密文是否合法都走完整 `Dec → Re-Enc → 常数时间比较 → J(z‖c)` 路径，所以「破损密文是否引出额外的可区分路径」本该由主类对回答，不需要一个长度维度去触发；(2) 该对照能回答的问题更小、更弱——它只需要证明「同样的调用序列、同样的路径集合被走到」，这是定性结论，不需要 p 值，写进主家族反而会被误读成时序恒时的证据；(3) 破损输入会改变输入生成本身的代价分布，与本仓库「输入生成在窗口外」的可加性模型不兼容；(4) 即使破损类对出现可区分，也无法区分「破损处理逻辑本身有时间差」与机器漂移，要定位仍须回到题面第 5 条的逐格排查。**因此本节只给原始 p、Δ 与 95% CI，不做 Holm、不做任何多重比较校正，不改变 efca8a1 冻结的家族口径，也不改变 M1/M5 的任何既有判定。** [E28,E30]",
            "**边界**：输入是人工构造的，这不是上游 CVE；「未检出」只说明在该机、该编译产物、该类对、该样本预算下没有额外的可区分路径，**不构成恒时证明**，也不给出总体误报率。本项目不做密钥恢复，不运行 exploit demo。 [E28]"
        ], ["T7", "T8", "T9"]),
        ("题面第 8 条：性能开销表", [
            '题面第 8 条要求分别给出防护前后 ML-KEM 解封装的平均运行时间、典型分位数及性能开销，并分析安全防护带来的效率代价。本节按「每个版本跑一次完整调用要多少时间」及其相对开销给出 25 行逐（模块, 臂, 操作）汇总与 11 行成对开销，**同时给纳秒与周期两种单位**。本组数据**族外**：不进任何 Holm 家族、不做多重比较校正，也不与 M1–M5 的秘密依赖性 p 值合并。',
            '覆盖 M1 两版、M2 两版、M3 两臂、M5 单臂的 decaps / keygen / encaps 完整调用，以及 M4 两臂的比较步。n：decaps 25000/块 × 6 块 = 150000，keygen 与 encaps 各 30000，M4 每类 120000。**同一次运行内的调用不是独立重复**（共享同一段频率与温度状态），因此表内的合并 CI 是把 6 个块的调用合并后的 bootstrap 10000 次区间，是**下界性质、偏广口径偏窄**；含块间漂移的口径在该文件的块间一致性一节。成对开销按交错块（ABAB）两两配对后先算每对的相对开销再取中位数，CI 同样用 bootstrap 10000 次。 [E44,E45,E46]',
            '**口径局限必须一起读**：(1) 周期按名义锁定基频换算（`cycles = ns × 4.3`，基频 4300000 kHz 来自控制器写死的目标 policy），**不是逐调用的实测频率**——本机实测会围绕它小幅波动（同类运行的历史快照见过 4282032–4336661 kHz）；现代 x86 的「周期」不是恒定工作量单位，换算值只用于跨机器粗对齐，**不得当成指令数或恒时性证据**。(2) 本轮 R08 拉回的副本里只有 CSV 与 meta，**没有 `during.json` / `entry-probes.json`**，所以「用该次运行 `cur_khz` 中位数换算的核对口径」本次无法给出——这不是「没差异」，而是「这次没有可核的逐运行频率记录」；同理这些 run 的副本没有 controller 目录，`restore_match` 等四条有效性判据本次无法从副本复核。(3) keygen 与 encaps 的窗口内包含公开 API 自身的随机源调用，decaps 不含，这两类的方差里含内核随机源开销。(4) M4 **不与完整解封装混比**，只在比较步内两臂互比（`comparison_scope = M4_compare_step_only`），且其计时源是 `CLOCK_MONOTONIC_RAW`，与其它臂不是同一个时钟。(5) 逐块重建时保留了两处异常运行如实登记、不剔除。**结论方向**：某一臂更快不等于它更安全，某一臂更慢不等于它泄漏——开销与恒时性是两个问题。 [E44]',
        ], ['T20', 'T21']),
        ("题面第 9 条：优化级别对照与跨环境范围", [
            '题面第 9 条的最低要求是「至少在一种软件运行环境完成完整实验」，高水平的加分项是不同编译优化级别、不同 CPU 架构或本地与网络场景下的对比。本节先把**必做部分**的结果给全，再逐项交代可选部分做与没做、为什么。',
            '**必做的优化级别对照已完成**：M1 两版 + M5 × {-O0, -O2, -O3, -Os} = **12 格**，逐格给产物判定（反汇编的秘密相关分支、`div` 计数、Memcheck 命中位置数/动态次数）与锁频实测（主类对 message-zero vs message-ones、每种子每类 10000 次完整解封装、3 个种子的 Δ、Δ̄ 与 bootstrap 95% 区间），并附图。**结论按数据说话**：教科书式 `bt` + `jae` 只在 `-Os` 出现；`-O2`/`-O3` 同样有秘密相关分支（形态是每比特一条 `testb` 加条件跳转，Memcheck 唯一位置数 8 / 15，比 `-Os` 的 1 更多），但本次端到端计时**没把它们分辨出来**；`-O0` 该级别下没有秘密相关分支（源码级算术掩码被原样保留）。修复版 `982c762` 在四个级别上都成立（产物 `helper_bt_jae` 四格全 no、Memcheck 四格 0/0、计时没有任何一级出现未修 `-Os` 那种三种子同向且合并 CI 不含 0 的形态）。M5 在四个级别上均未检出。**必须写明的两点**：(1) `-O2`/`-O3` 的「未检出」不等于安全——产物有分支、Memcheck 有命中，只是端到端计时没分辨出来；(2) 本次方法的可观测下限约 25–30 ns（`-Os` 的 Δ̄ ≈ −28.9 ns，相对 5.55×10⁴ ns 的解封装均值约 0.05%），而判为安全的 M5 参考路径在 `-O3` 也给 −2.42 [−3.93, −1.33]、在 `-Os` 给 −4.95 [−18.89, +4.85]，即 ±5 ns 量级的「显著」在本次设置里同样出现在没有该机制的格子上，属本实验残余水平。 [E47,E48,E49]',
            '**可选部分的逐项交代**：(1) **不同编译优化级别——已完成**（上面 12 格）。(2) **不同 CPU 架构——不做**。理由是本项目冻结范围为真实 x86_64 Linux 实测，本机 macOS/ARM、交叉编译或模拟器**不能冒充真实 x86_64 Linux 实测**，把两者混在一起会污染「跨环境稳定性」的读法；本轮时间预算优先给 DoD 必做路径。该决定与本仓库工作环境约定一致，属于**范围冻结**而不是数据缺失。(3) **本地与网络场景——未执行**。计划中的同机网络对照（T25：本地直调 / 回环 TCP / veth+netem 三档）是**可选**项，需要 netns/veth/netem 与 sudo，并要在 CPU2/CPU6 之外组织拓扑，本轮未开始，已登记为阻塞项。**影响**：威胁模型章的网络小节按「未执行」写、不写「未检出」；同机锁频结果**不能**外推网络可检出性；若后续执行，引用时必须标注「同机模拟、非真实远程」。 [E47,E58]',
            '**边界与可核性缺口（如实登记）**：本组数据族外，不进任何 Holm 家族，不改变 M1/M5 既有判定，任何「未检出」都不等于该级别安全；gcc 对照未做、`-O1` / `-Oz` / `-Og` 未做、其它架构未做，这些是「未执行」而不是「已执行且未检出」；每格 s1/s2 在 CPU2、s3 在 CPU6，因此 Δ̄ 混了两个物理核，**不是同核重复**；12 格没有一格出现 `div`/`idiv`，也没有 x86 `cmov` 指令（修复版的「cmov」是函数名 `cmov_int16`）；判定产物记的是 sha256、计时 meta 自报的是 SHA3-256，**算法不同、只能并列记录**，不能断言「计时用的就是被判定那一个二进制」；R09 的 RESULT.md（本轮读取时的版本）记载 36 个有效 run 的副本没有 controller 目录、四条判据无法从副本复核；**本轮写作时归档已补入控制器目录**（R09 36 个、R08 54 个，含 `terminal.json`、`entry-probes.json` 与 `during.json`），直接读取这些原始文件计数为 **R08 54/54、R09 36/36 四判据全部通过**（`restore_match=yes`、`worker_exit_code=0`、`worker_drained=true`）；但两份证据文件尚未同步这一更新，故本报告只作补充登记、不改写它们的结论；另有 1 次运行因频率探针 20 次采样的 `cur_khz` 跨度 54629 kHz 超过合同允许的 50000 kHz 被拒（20 个值都在 ±2% 带内，是跨度判据触发），worker 未启动、无 CSV，换名重跑后计入，已如实列出。 [E47]',
            '**与第 3 节锁频口径的关系**：第 3 节的「54 次控制器运行全部 restore_match 为 yes」指平台锁频采集（M2–M5 家族）那一批；本节 R08 与 R09 的额外运行不在该统计内，两者不可互相顶替。 [E19,E44,E47]',
        ], ['T22']),
        ("题面第 12 条：创新对照（锁频 vs 不锁频、多工具矩阵）", [
            '题面第 12 条要求至少在自动化侧信道检测、敏感路径定位、常数时间实现方法、统计检测方法、低开销防护或跨平台验证之一取得改进，并用可复现实验说明效果。本节给出两项**族外**创新对照：锁频与不锁频的 A/B 对照（回答「固定工作点到底买到了什么」），以及九工具 × 五模块的交叉矩阵（回答「单工具会漏掉什么、会错在哪里」）。两项都不进 Holm、不改任何既有判定。',
            '锁频 vs 不锁频：3 个臂（M1 未修、M1 已修、M5）× locked / unlocked 各 9 次运行、每类 10000 次。locked 臂由控制器写 boost=0、performance、min=max=4300000 kHz，有效性判据 `restore_match=yes`（9/9）；unlocked 臂**完全不写 sysfs**（默认 boost=1、powersave、min=2982259、max=5756452），有效性判据是运行前后全量频率快照逐字相同（9/9 `config_changed=no`）。**结果与直觉相反，如实报告**：在纳秒尺度上不锁频臂的标准差反而更低（SD 比 0.741 / 0.757 / 0.956），但把 SD 除以该臂均值得到变异系数 CV 后两者基本相等（**CV 比 0.964 / 1.006 / 1.089，跨臂方向不一致**）——ns 尺度上看到的不锁频「更稳」主要是频率更高、每次调用耗时更短造成的机械效应，不是噪声真的更小。**因此锁频控制器的价值应当表述为确定性、可核对与可恢复的固定工作点（boost=0、固定 min=max、进出快照加 restore_match），而不是「必然降低测量方差」。** 已知阴性对象 M5 在两种条件下都未被误报（0/3 与 0/3），真阳性对象 M1 未修在两种条件下都被检出（3/3 与 3/3）；样本量只有 3 vs 3，只作描述，不给「假阳性率 = x%」这类总体结论。 [E52]',
            '多工具矩阵：**9 个工具 × 5 个模块 = 45 格**，其中 **30 格有真实运行产物、15 格为未运行**（每一格都在逐格证据 CSV 里写了原因，工具缺失一律写「未运行 + 原因」而不写「未检出」）。在指定的阴性基准 M5 上真正运行过的 6 个工具全部给出阴性，**误报合计 0**；其余 3 个工具在 M5 未运行，不填阴性也不计误报。**只有 Welch + Holm 是预注册家族成员**，其余一律族外。交叉之后多出来的东西：M1 由反汇编、Memcheck、Welch+Holm、RTLF、dudect 五路同向；**M2 的「定位阳性 + 端到端未检出」这个分层结论只有交叉才成立**——单看 RTLF 会把 M2 读成「两臂都可区分」，单看 dudect 会把阳性读成「修复引入了泄漏」（其阳性落在已修臂）；M3 的定位结论有三个独立来源而同层端到端阴性也被明确分层；**M4 是唯一一个定位层与端到端都阳性、且 `ct` 对照臂在所有工具下都不报的模块**，构成「工具确实能检出」的对照；M5 由 6 个工具 6 路全阴，其阴性不是单一工具的产物。Mona 是唯一与既有方向不一致的工具（未修臂无分离、已修臂有分离），其 `Confidence Interval` 字段是批次成功百分比而非 p 值、`holm_member=false`，本轮**没有**用它推翻任何既有结论，也**没有**把它的「无分离」写成 M1/M2 的阴性证据。 [E53,E54]',
        ], ['T23', 'T24']),
        ("题面第 11 条：一键复现与复现参数总表", [
            '题面第 11 条要求提供测试程序、测试数据生成方法、实验参数、编译选项与统计分析过程，使评测人员能够复现实验结论。本节给出「一键入口 + 参数总表」两件交付物，并附一次**干净 clone 实测**；复现的边界（缺件、需 sudo 的部分、演练不是结论）一并写明。',
            '一键入口 `scripts/reproduce_all.sh` 分两档：`quick` 档做配置、构建、CTest（platform / ordinary / sanitize 三选一或全跑）与每类小样本统计演练，**全程不需要 sudo、不写任何 sysfs 频率节点、不绑核**；`full` 档按四份冻结 PLAN 生成完整采集命令，**默认 dry-run 只打印**，加 `--execute` 才真跑且必须给 `--control-root`（校验位于云端唯一存放根之下并含控制器）。参数总表逐模块列出**实际用过的**编译选项、种子、样本数、核与频率管理、统计脚本或工具、计划文件与证据目录，每一行的链接都指向仓库内真实存在的文件，没有落盘依据的参数不写进来。 [E55,E56]',
            '**干净 clone 实测**：在临时解出目录里跑 `quick` 档，退出码 0，三个配置的 CTest 分别为 platform 80/80、ordinary 57/57、sanitize 57/57，**合计 194 项通过、0 失败**。**同一处的三段边界**：(1) 演练产出的统计值（M3 m=6 拒绝 1、M4 m=6 拒绝 0、M5 m=3 拒绝 0）**不是任何模块的正式统计结论**——演练不锁频、不绑核、跑在 macOS/ARM、每类只 1000 次，只演示「没有锁频协议时同一台机器会给出什么」；(2) `vendor/liboqs-0.10.0`、`vendor/kyber-kyberslash-*` 与 `third_party` 都在 `.gitignore` 内，干净 clone 缺件时按「缺件即跳过并打印原因」处理，M2 演练因此跳过，要复现 M1 的历史阳性对照与 M2 两臂需先跑取件脚本；(3) 本轮 **final5 只重出报告**，匿名包与解出复算由主控另跑，报告内引用的解出复算产物仍是最后一次实际执行的 `final4-20261016`。 [E57,E58]',
        ], ['T25']),
        ("威胁模型（题面第 10 条）", [
        ], ['THREAT_INPUT']),
        ("M1 既有真实案例与 Mona 对照", [
            "既有 M1 针对固定 liboqs 0.10.0、Clang 18 与便携 C 路径，保留原源码、产物分支、工具、逐次数据与官方修复复测证据。本报告只引用 [E02](../../../docs/evidence/r02-r04-close-20261016/RESULT.md) 的限定结论，不修改旧 CSV、旧家族或原报告。",
            "原 E02 表中主类对三次未修均值差为 +39.337、+31.117、+22.337 ns；对应已修为 −13.209、+8.354、−4.885 ns。Holm 家族 m=6 只拒绝未修主检验（p=1.30×10⁻⁵ 对阈值 0.00833）。这些数字是封存引用，不是本报告生成时的新采集；区间、预算、环境与原族以 [E17](../../../docs/evidence/liboqs010-locked-20261015/README.md) 与 [E02](../../../docs/evidence/r02-r04-close-20261016/RESULT.md) 为准。",
            "工具交叉印证见 [E18](../../../docs/evidence/tooling-strengthen-20261015/RESULT.md)：Valgrind 只标记 indcpa 私钥前 1152 B 时，未修在 poly_frommsg（poly.c:179）报 1 个秘密条件跳转、已修 0 个；反汇编为 bt+jae 变为 setb 加 cmov_int16；同规程 RTLF 与在线 dudect 与 CI 方向一致。这不是端到端恒时证明。",
            "新增 Mona 对既有六份类对的真实离线回放并未与既有检测方向一致：三份 vulnerable 均无通过验证的箱体分离；primary 与 seed-424242 的 fixed 各有一个成功记录，CPU6 fixed 未找到最优箱体。两项成功都出现在扩展后只剩一个验证子集的末轮，不能解释为受控总体误报率或上游修复失效。Mona 是族外独立观察，不替换 CI/Welch、Holm、RTLF 或 dudect。本轮新增 Mona 对 M2 六份主类对的真实执行（工具身份 mona-timing-report@4c74fb7e，离线上游内核，六份原始 CSV 跑完后 sha256 6/6 未变）：**三个未修臂在 Mona 箱体规则下都没有通过验证的箱体分离（0/9 ×3），s1/s2 的已修臂同样无分离（0/9、0/7）；只有 s3 已修臂出现一次 validated_box_separation（1/8，X<Y 箱 0.27–0.34、5120 值、子集数 1），属该自适应实现「末轮只剩 1 个子集」的已知假阳性模式**（与 M1 两项 fixed 同型）。六批最高批次成功百分比依次为 74%、18%、34%、29%、34%、100%。这**不说明两臂等价或恒时，也不推翻 Welch CI + Holm、RTLF 或 dudect 的结论**；Mona 的 `holm_member=false`，`Confidence Interval` 字段是批次成功百分比而非 p 值或覆盖区间。 [E09,E24,E25]"
        ], []),
        ("M2 KyberSlash：真实历史案例", [
            modules[1]["summary"],
            "未修固定为 a621b8dde405cc507cbcfc5f794570a4f98d69cc，完整已修固定为 272125f6acc8e8b6850fd68ceb901a660ff48196；均以完整提交而非 exact tag 钉版。中间 dda29cc 只修 KyberSlash1，不能当作完整修复。对象是历史 Kyber768，不能冒称 FIPS 203 ML-KEM-768。",
            "定位实际在 x86_64 Linux、Clang 18.1.3、-Oz 且关闭向量化的固定产物中执行：poly_tomsg（解密段）与 polyvec_compress、poly_compress（重加密段）的秘密相关操作数数据流与各自一条 div 对应。varlat 默认上下文 PC 落在系数 load，不能直接把该 PC 当成静态 div 地址；归因来自同 ELF 数据流、源码、反汇编及 varlat 开关对照。",
            "完整 KEM 的适用独立 KAT、边界与原生产物资格见 [E13](../../../docs/evidence/m2-kem-20261016/RESULT.md)；完整调用软件合同 [E12](../../../docs/evidence/m2-kem-20261016/SOFTWARE_CONTRACT.md) 与实际结果分开。新生产 ELF 未重跑旧 varlat 探针，旧定位不倒写成新产物动态结果。完整调用的端到端统计已执行：家族 m2_end_to_end_full_decaps_v1（m=6）Holm 拒绝 0，合并 Δ +4.58 ns、95% CI [−3.08, +12.25]（含 0）、I²=58.3%，即未检出；按臂描述性方向相反（未修 +12.35、已修 −11.20）＝臂间漂移，不据此新增声明。族外 dudect 的阳性出现在已修臂，不可归因于除法变体。按冻结 PLAN，端到端未拒绝后启动了只包除法热点的微基准层：家族 m2_div_hotspot_microbench_v1（m = 3 次运行 × 2 臂 = 6）同样 Holm 拒绝 0，固定效应合并 Δ = +0.044 ns、95% CI [−0.430, +0.517]（含 0）、I²=68.7%，最显著单项 r01 未修 p=0.042 经校正后为 0.249；六个 run 全部 controller_exit=0、worker_exit_code=0、restore_match=yes。微基准窗口只包 pqcrystals_kyber768_ref_poly_tomsg，与完整解封装不可比，两族 p 值不合并。因此本模块按三层记录：**定位层阳性 / 除法热点微基准层未检出 / 完整解封装层未检出**，不改变端到端家族的 Holm 判定，也不用定位层阳性替代统计阳性。 [E03,E04,E12,E13,E19,E20]"
        ], []),
        ("M3 与 M4：人工机制校准", [
            modules[2]["summary"],
            "M3 初始独立夹具的 32/1 对 0/0 只按原产物引用。新增完整解封装挂载以同一消息位生成真实重加密系数，on 的秘密索引 load 与 off 的公开等价读取保留同样密码输出及隐式拒绝。每代产物分别绑定资格与定位，不能把新 1280/2 与旧 32/1 混作一次运行；人工构造校准的性质不变，未构成新 CVE。 [E05,E14]",
            modules[3]["summary"],
            "M4 两版本只返回相等性，不提供标准 memcmp 的正负排序语义。封装先检查长度与空指针，真实短数组不传给内核；每变体以标准库 memcmp(...) 等于 0 为 oracle，枚举长度、差异位置及替换字节。poison 只包住秘密输入到目标调用，结果消费前取消标记。",
            "新增 Binsec 只验证固定 i386 -O1 抽取内核：入口 m4_entry、终点 m4_halt，秘密数组 16 字节、候选数组与长度公开、长度 1–16；在消费允许公开的比较结果之前停止，两版所有路径均到达 halt，pending、cut、discontinued 与 solver unknown 均为零。反例 PC 0x8049047 对应 compare_early.c:9。有界 secure 不外推到 32 字节普通采集 ELF、任意长度、完整 KEM、其他编译条件或物理恒时。 [E06,E16]"
        ], []),
        ("M5：参考实现阴性对照候选", [
            modules[4]["summary"],
            "固定 mlkem-native 提交为 b3ba7b32773e657dd37f6f87bce82528459ad8a4；完整库及许可证共 126 文件复核一致。实际调用链为 reference_measure 到 mlkem_decapsulate，再到 baseline_native_dec；普通测量链接 reference/libmlkem.a，未混入历史 liboqs 或人工补丁变体。",
            "原生定位把 ML-KEM-768 解封装密钥的 PKE 秘密部分与拒绝秘密 z 标记为 undefined，内嵌公开 key、公开 hash 与密文保持 defined；发行版 Memcheck、固定补丁 varlat=no 与 varlat=yes 三模式下各 10 次完整调用均为 0 errors/0 contexts。这是已执行且未检出，只覆盖该源码、编译器、后端与有限输入，不构成恒时证明或总体误报率为零。",
            "在线 dudect 入口已构建并通过不读钟 callback 与合成 raw 写出自检，本轮完成正式采集：家族 m5_reference_end_to_end_v1（m=3）Holm 拒绝 0，合并 Δ −5.30 ns、95% CI [−11.77, +1.16]（含 0）、I²=0%；族外 dudect max|t| = 2.10/1.98/2.82、state=1。这是本预算内的未检出，不是恒时证明，也不给出总体误报率为零；族外 RTLF 对 M5 六项（主类对 3 + 对照 3）全部 no_difference_detected（α=.01）；这仍只覆盖本机、本类对、本预算与该工具设置，未检出不等于恒时证明。 [E07,E15,E19,E20]"
        ], []),
        ("实测数值、证据对照与复算入口", [
            "下表把本报告出现的每个实测数字指向具体证据文件；M1 各行是封存引用，其余为本轮新增产物的原文数字。任何数字不能回到文件字段的，一律不写。",
            "复算入口分两层：(1) 统计与图形由仓库内显式数据文件重建（report-data.json、report-tables.json、EVIDENCE_MATRIX.csv、r05_flowchart.py）；(2) 匿名 ZIP 解出后在独立目录重新构建并执行包内 CTest，命令与通过数记录在 docs/evidence/platform-report-20261016/refresh-20261016/zip-recompute-final4.log（本轮终版包）与 docs/evidence/platform-report-20261016/final4-20261016/offline-reproduction.json，不复用仓库本体充当复算。离线复算只重算已有数据，不算新硬件实验；外部 RTLF、Mona、dudect 与 Binsec 不在该入口重执行。"
        ], ["T5"]),
        ("当前局限、占位符与后续验收", [
            data.get("remaining_summary", "完整 KEM 与人工挂载的适用资格已有新原生证据；各新模块的正式时序、在线 dudect 与复测须继续核对。"),
            "正式统计完成并不要求每个历史实现都在当前 x86_64 上出现阳性。若完整调用不可区分，应报告预算、区间与工具状态，并保留定位与微基准的分层结果；若阴性候选出现阳性，应调查噪声、样本结构与产物机制，不能为了满足预期删除普通长尾或改类。任何工具失败都不能自动归入安全阴性。",
            "本项目不做密钥恢复、不交付 exploit，不把历史 Kyber 等同于最终标准 ML-KEM，也不把人工夹具算作新漏洞。物理精度、逐调用恒频、所有输入下恒时与总体误报率均须单独证据；本报告没有增加这些主张。",
            "**来源文件之间尚未对齐的三处，本报告不改判、按可核的一侧引用，并在这里如实登记**：(1) R06 修复手段映射表实际有 **16 个数据行**（M1 三、M2 三、M3 四、M4 两、M5 四），而该文件自述“表内行数 15”，两者不一致；(2) R04 功效文件 §1 已更正 M1 主类对属于预注册 Holm 家族（m = 6），但同文件 §5 的家族列仍把 M1 标为“族外”，本报告采用更正后的 M1 口径；(3) 「M5 × 可变时间比较」4 格在 R05 本体按产物与源码判“不存在”，而 `BLOCKERS.md` 把这一情形描述为“工具不适用型 unknown”，两处措辞不一致，本报告按 R05 本体的结论与计数（存在 5 / 不存在 75 / 不适用 10 / 未检查 0）引用，并保留该工具侧边界。三处都是文件表述层面的差异，不改变任何数字与判定。**第四处是归档与文稿的时间差**：R08 / R09 的控制器目录（含 `terminal.json`、`entry-probes.json`、`during.json`）在本报告写作时已补入归档，四判据原始计数为 R08 54/54、R09 36/36 全部通过，而 `PERF.md` 与 R09 的 `RESULT.md` 仍写着副本缺 controller 目录；本报告只作补充登记、不改写两份证据文件，并已在第 15 节与表 T21 的表注写明；两份文件同步更新后应回填并重新生成报告。",
            "仍以“未执行”登记的项：题面第 9 条可选的同机网络场景（T25）与不做第二架构的决定；R05 第 5 条 M5 重加密步骤的 Binsec `checkct` 为 unknown（带具体参数与三重阻塞）；R09 未做的 gcc 对照、`-O1` / `-Oz` / `-Og` 与其它架构；R06 未覆盖的上游快照、网络路径与进程级可观察面；R02 的 `isolcpus` / SMT / 后台服务未隔离。它们都不是阴性。",
            "下表记录本轮已清空的两处占位项（RTLF 族外交叉、M2 除法热点微基准层）；报告内不再有 «待主控数据»，仍标“未执行”的只有题面第 5 条中结构性未做的单元格与上面列出的可选项。本轮 final5 只重出报告：匿名包、包内解出复算与包审计由主控另跑，报告内引用的解出复算产物仍是最后一次实际执行的 final4-20261016。最终验收以 [E01](../../../docs/platform/COMPLETION_REQUIREMENTS.md) 的逐项条件为准，而不是以文稿、图表或模块数量替代实验完成。 [E01]"
        ], ["T6"]),
        ("附录 A：题面 12 条对照矩阵", [
            '下表是题面 12 条的逐条对照：条款号、一句要求、状态、报告章节号、证据路径（相对仓库根）与「缺什么 / 为什么 / 影响什么」。状态只取三种值——**满足 / 部分 / 未执行**；判据是仓库内可打开的证据文件，不用文稿措辞或模块数量替代实验完成。**11 条为满足、第 6 条为部分**；第 9 条按项目冻结范围把「必做」与「可选」拆开写，可选三项中 1 项完成、1 项不做、1 项未执行，理由与影响写在同行说明列。',
        ], ['T26']),
    ]


def wrap_text(text, capacity):
    tokens = re.findall(r"[A-Za-z0-9_./+\-]+|.", str(text))
    lines = []
    current = ""
    for token in tokens:
        if len(current) + len(token) > capacity and current.strip():
            lines.append(current.rstrip())
            current = "" if token == " " else token
        else:
            current += token
    if current.strip():
        lines.append(current.rstrip())
    return lines or [""]


def render_matrix_svg(modules):
    columns = ["模块 / 机制", "软件资格", "定位", "时间统计", "形式化 / 边界"]
    keys = [None, "software", "localization", "statistics", "formal"]
    widths = [190, 195, 215, 195, 195]
    x_positions = [30]
    for width in widths[:-1]:
        x_positions.append(x_positions[-1] + width + 10)
    total_width = x_positions[-1] + widths[-1] + 30
    row_height = 78
    fragments = ['<svg xmlns="http://www.w3.org/2000/svg" width="' + str(total_width) + '" height="{height}" viewBox="0 0 ' + str(total_width) + ' {height}"><rect width="100%" height="100%" fill="white"/><g font-family="Arial, PingFang SC, sans-serif" fill="#193248">']
    fragments.append('<text x="30" y="34" font-size="21" font-weight="600">平台证据矩阵（结果图）· 2026-10-16</text>')
    fragments.append('<text x="30" y="60" font-size="14">真实历史案例 / 人工构造校准 / 阴性对照候选分组；橙色为未运行（not_run），不是阴性。</text>')
    for column_index, column in enumerate(columns):
        fragments.append('<text x="' + str(x_positions[column_index] + 8) + '" y="110" font-size="15" font-weight="600">' + html.escape(column) + "</text>")
    current_y = 150
    for category in ["真实历史案例", "人工构造校准", "阴性对照候选"]:
        fragments.append('<rect x="30" y="' + str(current_y - 24) + '" width="' + str(total_width - 60) + '" height="28" fill="#dfe7ec"/><text x="38" y="' + str(current_y - 5) + '" font-size="14" font-weight="600">' + html.escape(category) + "</text>")
        current_y += 34
        for module in [item for item in modules if item["category"] == category]:
            for column_index, key in enumerate(keys):
                if key is None:
                    value = module["id"] + " " + module["name"]
                    fill = "#eef2f5"
                else:
                    value = module[key]
                    if str(value).startswith("未运行"):
                        fill = "#f9eddd"
                    elif "封存" in str(value):
                        fill = "#f0f2f4"
                    else:
                        fill = "#e6f1f8"
                fragments.append('<rect x="' + str(x_positions[column_index]) + '" y="' + str(current_y) + '" width="' + str(widths[column_index]) + '" height="' + str(row_height - 6) + '" rx="4" fill="' + fill + '"/>')
                for line_index, line in enumerate(wrap_text(value, int(widths[column_index] / 8.4))[:4]):
                    fragments.append('<text x="' + str(x_positions[column_index] + 8) + '" y="' + str(current_y + 20 + line_index * 15) + '" font-size="12.5">' + html.escape(line) + "</text>")
            current_y += row_height
    fragments.append('<text x="30" y="' + str(current_y + 14) + '" font-size="13">未运行不是零效应；工具报警次数或上下文数不是样本量；定位阳性不等于统计显著或恒时。</text>')
    fragments.append('<text x="30" y="' + str(current_y + 38) + '" font-size="13">本图为结果图，不是计划图；每格证据路径见 report-tables.json 与证据来源索引。</text></g></svg>')
    return "".join(fragments).replace("{height}", str(current_y + 60))


def main():
    data = json.loads((DIRECTORY / "report-data.json").read_text())
    tables_document = json.loads((DIRECTORY / "report-tables.json").read_text())
    tables = tables_document["tables"]
    table_map = {item["id"]: item for item in tables}
    source_records = []
    for source in data["sources"]:
        source_path = REPOSITORY / source["path"]
        content = source_path.read_bytes()
        source_records.append({**source, "sha256": hashlib.sha256(content).hexdigest(), "bytes": len(content)})
    sections = get_sections(data, tables)
    snapshot = {"date": data["date"], "document_state": data["document_state"], "baseline_commit": data["baseline_commit"], "worktree_head": subprocess.check_output(["git", "rev-parse", "HEAD"], cwd=REPOSITORY, text=True).strip(), "sources": source_records, "modules": data["modules"], "tables": [{"id": item["id"], "title": item["title"], "rows": len(item["rows"]), "columns": len(item["columns"])} for item in tables], "placeholder_token": tables_document["placeholder_token"]}
    (DIRECTORY / "evidence-snapshot.json").write_text(json.dumps(snapshot, ensure_ascii=False, indent=2) + "\n")
    matrix_svg = render_matrix_svg(data["modules"])
    (DIRECTORY / "platform-matrix.svg").write_text(matrix_svg)
    mermaid_source = load_mermaid_source()
    r05_plan = r05_flowchart.layout()
    r05_svg = r05_flowchart.render_svg(r05_plan)
    (DIRECTORY / "r05-flowchart.svg").write_text(r05_svg)
    r05_flowchart.render_png(DIRECTORY / "r05-flowchart.png", r05_plan)
    summary = "真实历史案例与人工构造校准分列；检测、定位、修复、复测四段链逐模块给出实际状态，未运行不写成未检出。M2–M5 的锁频家族统计、Mona 对 M2 对照、RTLF 族外交叉（42/42）与 M2 除法热点微基准层均已回填，报告内已无 «待主控数据»；结构性未做的检查写“未执行”。**本轮（final5）把 T31 的全部收尾证据并入正文：**R01 向量来源与修复语义等价、R02 环境总表与异常样本规则与稳健性（64 类对 × 4 方法，翻转 12/64，没有任何翻转改变 Holm 判定）、R04 功效与 MDE（M2 约 25–67 ns、M3 约 18–34 ns、M5 约 14–28 ns；未检出 = 观测效应 < MDE）与分位数差（有效计时量化尺度约 10 ns）、R05 补缺格与计数更新（3 实现 × 5 步骤 × 6 类 = 90 格：存在 5、不存在 75、不适用 10、未检查 0）、R06 修复手段映射与泄露渠道审计（秘密内容泄露 0 条，另有低危发现 F1）、R08 性能开销（25 行汇总 + 11 行成对开销）、R09 优化级别（12 格）、R11 威胁模型（以独立 LaTeX 片段直接并入）、R12 创新对照（锁频 vs 不锁频的 CV 比 0.96–1.09；多工具矩阵 9 × 5 = 45 格，30 格有产物）与 T30 一键复现（干净 clone CTest 194/194）。新增**附录 A 题面 12 条对照矩阵**：11 条满足、第 6 条部分（唯一缺口是 R06 的 F1）。M4 只引用分臂数值（vulnerable Δ −4.089 ns、ct Δ +0.055 ns），不引用混臂的家族合并 Δ。"
    markdown = ["# " + data["title"], data["subtitle"], "日期：" + data["date"], "摘要：" + summary]
    tex = [r"\documentclass[UTF8,fontset=fandol,11pt,a4paper]{ctexart}", r"\usepackage[margin=23mm]{geometry}", r"\usepackage{booktabs,longtable,array,amsmath,xcolor,colortbl,pdflscape,hyperref,seqsplit,graphicx}", r"\definecolor{headergray}{gray}{0.88}", r"\hypersetup{colorlinks=true,linkcolor=blue,urlcolor=blue,pdfauthor={},pdftitle={多泄漏模块检测平台补充报告},pdfsubject={CACR2026EA16XZ},pdfcreator={XeLaTeX}}", r"\setlength{\parindent}{2em}\setlength{\parskip}{0.5em}\linespread{1.18}\raggedbottom\pagestyle{plain}\emergencystretch=2em", r"\begin{document}", r"\thispagestyle{empty}\vspace*{16mm}\begin{center}{\LARGE\bfseries " + tex_escape(data["title"]) + r"\par}\vspace{8mm}{\large " + tex_escape(data["subtitle"]) + r"\par}\vspace{9mm}参赛编号：CACR2026EA16XZ\par " + data["date"] + r"\end{center}\vspace{12mm}", r"\section*{摘要}", tex_escape(summary),r"\par\vspace{6mm}\noindent\textbf{关键词：}侧信道检测；KyberSlash；秘密标记；人工机制校准；格式破损对照；六类来源排查；可复算证据", r"\par\vspace{6mm}\noindent 版本性质：多机制平台补充载体。旧报告与原始证据保留；未运行项见正文、对照表与证据索引。"]
    html_sections = []
    for section_index, (title, paragraphs, table_ids) in enumerate(sections, 1):
        if table_ids == ["THREAT_INPUT"]:
            markdown.extend(["\n## " + str(section_index) + " " + title, THREAT_POINTER])
            tex.append(r"\begingroup\sloppy\hbadness=2000\input{" + THREAT_TEX + r"}\endgroup")
            html_sections.append('<section id="section-' + str(section_index) + '"><h2>' + str(section_index) + " " + html.escape(title) + "</h2><p>" + render_text(THREAT_POINTER, "html") + "</p></section>")
            continue
        markdown.extend(["\n## " + str(section_index) + " " + title, *paragraphs])
        # 附录的表是 landscape，会强制分页；让附录整节从新页开始，避免导语被拆成两行尾页。
        tex.extend([(r"\clearpage" if section_index == 1 or title.startswith("附录") else "") + r"\section{" + tex_escape(title) + "}"] + [tex_escape(paragraph) + "\n\n" for paragraph in paragraphs])
        html_sections.append('<section id="section-' + str(section_index) + '"><h2>' + str(section_index) + " " + html.escape(title) + "</h2>" + "".join("<p>" + render_text(paragraph, "html") + "</p>" for paragraph in paragraphs))
        for table_id in table_ids:
            if table_id == "FIGURE":
                markdown.append("![平台证据矩阵（结果图）](platform-matrix.svg)")
                tex.append(render_tex_matrix(data["modules"]))
                html_sections.append("<figure>" + matrix_svg + "<figcaption>图1：平台证据矩阵（结果图）。橙色格为未运行（not_run），不是阴性。</figcaption></figure>")
                continue
            if table_id == "R05_FLOW":
                markdown.append("```mermaid\n" + mermaid_source + "\n```")
                tex.append(r"\begin{samepage}\noindent\includegraphics[width=0.94\textwidth]{" + R05_FIGURE_TEX + r"}\par\vspace{1mm}\noindent 图2：R05 全流程排查表 §5 mermaid 流程图的等价静态渲染（三实现泳道；红色＝本轮判定「存在」，绿色＝修复后的同一位置，黄色虚框＝人工构造校准或未检查项，蓝色＝无该类来源）。虚线箭头＝修复映射：982c762 修复（M1C2→M1C3）、982c762 verify.c 值屏障（M1E2→M1E3）、dda29cc → 272125f 修复（M2A2→M2A3）、272125f 修复（M2C2→M2C3）。\textbf{mermaid 源码原样保存在 docs/R05-全流程排查表.md 第 5 节}，本 PDF 只承载等价静态图（XeLaTeX 不渲染 mermaid），逐格证据见该文件 §4.2 与本节表 T11。\par\end{samepage}\vspace{3mm}")
                html_sections.append("<figure>" + r05_svg + '<figcaption>图2：R05 全流程排查表 §5 mermaid 流程图的等价静态渲染。虚线箭头＝修复映射（982c762 修复 M1C2→M1C3、982c762 verify.c 值屏障 M1E2→M1E3、dda29cc → 272125f 修复 M2A2→M2A3、272125f 修复 M2C2→M2C3）。</figcaption></figure>')
                html_sections.append('<p class="table-title">R05 排查表 §5 的 mermaid 源码（原样保留；同一来源见 <code>docs/R05-全流程排查表.md</code>）</p><pre class="mermaid-source">' + html.escape(mermaid_source) + "</pre>")
                continue
            table = table_map[table_id]
            markdown.append(render_table(table, "md"))
            if table.get("landscape"):
                tex.append(r"\begin{landscape}" + render_table(table, "tex", 24.4) + r"\end{landscape}")
            else:
                tex.append(render_table(table, "tex", 16.2))
            html_sections.append(render_table(table, "html"))
        if section_index == 3:
            tex.extend([r"\[\widehat\Delta=\bar x_0-\bar x_1,\quad SE=\sqrt{s_0^2/n_0+s_1^2/n_1},\quad CI_{95\%}=\widehat\Delta\pm1.9599639845\,SE.\]", r"\noindent 差值方向须与各数据合同中的 class0/class1 顺序一致；公式不填充尚不存在的观测值。"])
        html_sections.append("</section>")
    tex.extend([r"\clearpage\section*{证据来源索引}\begingroup\small\setlength{\parskip}{0.2em}", r"各来源的完整摘要见 evidence-snapshot.json。状态字段保留生成时点；来源为仓库相对路径。\par\vspace{2mm}"])
    markdown.append("\n## 证据来源索引")
    html_sections.append('<section id="sources"><h2>证据来源索引</h2><ul>')
    state_labels = {"requirements_only": "验收条件", "frozen_reference": "封存引用", "localization_only": "定位层", "pinned_history": "历史钉版", "software_only": "前置软件", "software_contract": "软件协议", "offline_replay_only": "既有数据离线回放", "architecture": "架构", "source_inventory": "来源及许可", "software_contract_only": "软件合同", "native_functional_qualified_statistics_not_run": "原生功能资格；统计未运行", "native_functional_and_localization_statistics_not_run": "原生功能与定位；统计未运行", "native_limited_dynamic_negative_statistics_not_run": "有限原生标记无报警；统计未运行", "bounded_formal_complete_statistics_not_run": "小模型有界验证完成；统计未运行", "locked_reference": "锁频原始证据（封存引用）", "tool_cross_check": "开源检测器交叉印证", "extra_family_descriptive": "族外描述性对照（不进 Holm）", "extra_family_plan": "族外对照采集计划", "flow_matrix_review": "解封装全流程逐格排查", "extra_family_controller_log": "族外对照控制器逐条状态", "vector_and_equivalence": "公开向量与修复语义等价", "environment_and_rules": "环境登记与样本规则", "robustness_descriptive": "稳健性敏感性分析（族外）", "power_analysis": "事后功效 / MDE（族外）", "quantile_descriptive": "分位数差与分布图（族外）", "localization_completion": "定位层补缺格（含 unknown 登记）", "leak_channel_audit": "日志 / 异常 / 返回码泄露专项审计", "remediation_mapping": "修复手段 → 方法分类映射", "performance_descriptive": "性能开销（族外描述）", "optlevel_descriptive": "优化级别对照（族外探索）", "threat_model": "威胁模型", "innovation_descriptive": "创新对照（族外）", "reproduce_entry": "一键复现入口与参数", "blockers": "本轮阻塞与降级登记"}
    for source in source_records:
        markdown.append("- [" + source["id"] + "] " + source["label"] + "；" + source["state"] + "；" + source["path"])
        # \path{} 不能断行：超长 ASCII 路径会撑出一行 badness 10000 的 Underfull，
        # 改走 tex_escape 的 \texttt{\seqsplit{}}（可在任意字符处断行）。阈值 70 只影响极长路径。
        path_tex = r"\path{" + source["path"] + r"}" if (source["path"].isascii() and len(source["path"]) <= 70) else tex_escape(source["path"])
        tex.append(r"\begin{samepage}\noindent\textbf{" + tex_escape(source["id"] + " " + source["label"]) + r"}（" + tex_escape(state_labels.get(source["state"], source["state"])) + r"）\par\noindent " + path_tex + r"\par\vspace{1.5mm}\end{samepage}")
        html_sections.append("<li><strong>" + html.escape(source["id"] + " " + source["label"]) + "</strong> · " + html.escape(source["state"]) + "<br><code>" + html.escape(source["path"]) + "</code></li>")
    html_sections.append("</ul></section>")
    tex.append(r"\endgroup\end{document}")
    (DIRECTORY / "report.md").write_text("\n\n".join(markdown) + "\n")
    (DIRECTORY / "report.tex").write_text("\n".join(tex) + "\n")
    html_document = '<!doctype html><html lang="zh-CN"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>' + html.escape(data["title"]) + '</title><style>body{font:17px/1.9 system-ui,sans-serif;color:#193248;background:#f3f5f6;margin:0}main{max-width:1100px;margin:0 auto;padding:55px 35px;background:white}h1{font-size:34px;line-height:1.3}h2{font-size:25px;margin-top:45px}p{max-width:62em}a{color:#185d85}code{overflow-wrap:anywhere;font-size:13px}li{margin:15px 0}svg{width:100%;height:auto}figcaption{font-size:14px;color:#536475}nav{border:1px solid #d9e1e5;padding:18px}footer{margin-top:50px;color:#536475}table{border-collapse:collapse;width:100%;font-size:14px;margin:12px 0}th,td{border:1px solid #cbd6dd;padding:7px 9px;vertical-align:top;text-align:left}th{background:#eef2f5}.table-title{font-weight:600;margin:26px 0 6px}.table-note{font-size:13.5px;color:#536475}</style><main><h1>' + html.escape(data["title"]) + "</h1><p>" + html.escape(data["subtitle"]) + " · " + data["date"] + "</p><p>" + html.escape(summary) + '</p><nav><a href="report.pdf">打开PDF</a> · <a href="report.tex">LaTeX源</a> · <a href="report-tables.json">对照表数据</a> · <a href="evidence-snapshot.json">状态与摘要</a> · <a href="#sources">证据索引</a></nav>' + "".join(html_sections) + "<footer>静态离线展示，无远端资源、脚本、遥测或新硬件采集。数据格内已无 «待主控数据» 占位符；标「未执行」的格子是结构性未做，不等于阴性，也不等于恒时。</footer></main></html>"
    (DIRECTORY / "index.html").write_text(html_document)
    guard_violations = []
    for name, content in [("report.md", "\n\n".join(markdown)), ("report.tex", "\n".join(tex)), ("index.html", html_document), ("platform-matrix.svg", matrix_svg), ("report-tables.json", (DIRECTORY / "report-tables.json").read_text()), ("report-data.json", (DIRECTORY / "report-data.json").read_text())]:
        for token in FORBIDDEN_TOKENS:
            if token in content:
                guard_violations.append(name + " 含禁用 token " + token)
    if guard_violations:
        raise SystemExit("口径守卫失败（M4 家族合并值不得出现）：" + "；".join(guard_violations))
    print(json.dumps({"sources": len(source_records), "sections": len(sections), "tables": len(tables), "document_state": data["document_state"], "forbidden_token_hits": 0}, ensure_ascii=False))


if __name__ == "__main__":
    main()
