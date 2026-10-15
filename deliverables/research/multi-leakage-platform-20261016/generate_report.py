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

DIRECTORY = Path(__file__).resolve().parent
REPOSITORY = DIRECTORY.parents[2]
LINK_PATTERN = re.compile(r"\[([^\]]+)\]\(([^)]+)\)")
MATH_REPLACEMENTS = [
    ("×10⁻⁵", r"\texorpdfstring{$\times 10^{-5}$}{x10^-5}"),
    ("«", "「"),
    ("»", "」"),
    ("①", "(1)"),
    ("②", "(2)"),
    ("③", "(3)"),
    ("④", "(4)"),
    ("×", r"\texorpdfstring{$\times$}{x}"),
    ("→", r"\texorpdfstring{$\rightarrow$}{->}"),
    ("−", r"\texorpdfstring{$-$}{-}"),
    ("α", r"\texorpdfstring{$\alpha$}{alpha}"),
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
            key = "@@MATH" + str(index) + "@@"
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
            "本轮冻结的家族口径：M2 与 M5 的家族成员为主类对 × 3 次运行 × 2 版；M3 与 M4 的家族成员为臂内主类对 × 3 次运行 × 2 臂 = m=6，跨臂 on/off 对比只作受控对照（含二进制级常数偏移），不进 Holm 家族；RTLF（α=.01、seed 2026101605、bootstrap 10000，只给二值结论）与 online dudect 一律族外、不进 Holm；RTLF 检验的是分布差异（含尾部与分位），Welch/CI 检验的是均值差，两者分列、互不替代。本轮 RTLF 42/42 完成、无 blocked/failed：no_difference_detected 30 项、difference_detected 12 项。M4 与其 Welch/Holm 方向一致（vulnerable 主类对与截断对照各 3/3 检出、ct 各 3/3 未检出），是两种方法在同一批数据上的独立印证；M2 主类对 6/6 检出，但**未修与已修两个臂都检出**，因此不可归因于除法变体，与 Welch/Holm 拒绝 0 的差异最一致的读法是类构造（message-zero 与 message-ones 各自是同一份确定性密文的 10000 次重复，而 bit-flipped 与 random 逐样本变化）加上未受控漂移，**不据此作任一方向的泄漏结论**；M3 12/12、M5 6/6 未检出。家族实际运行结果：M2 m=6 拒绝 0（合并 Δ +4.58 ns，CI [−3.08, +12.25]，I²=58.3%）；M3 m=6 拒绝 0（−0.73 ns，[−5.56, +4.10]，I²=12.5%）；M4 m=6 拒绝 3 且全在 vulnerable 臂（−3.74 ns，[−3.87, −3.62]，I²=98.6%）；M5 m=3 拒绝 0（−5.30 ns，[−11.77, +1.16]，I²=0%）。 [E01,E08,E19,E20]"
        ], []),
        ("检测—定位—修复—复测：四段链状态", [
            "检测段回答“不同类别的执行时间是否可区分”，必须给样本预算、描述统计、区间与检验族；定位段回答“差异对应源码或产物中的哪个机制”，必须给工具、命中位置与实际调用边界；修复段优先使用上游官方修复，人工校准使用明确标注的目标机制开关，并先核对功能等价与拒绝语义；复测段在同规程下独立再运行，比较修复或关闭前后的同向性与稳定性。",
            "四段不能互相顶替：定位阳性不能填统计格，统计未运行不能写阴性，官方修复存在也不等于本机统计已复现。下表逐模块给出四段链的实际状态；M1 为已封存原件的引用，本轮不重做。"
        ], ["T1"]),
        ("题面第 3 条对照：输入分类与测试", [
            "题面第 3 条要求至少两类具有明确区别的解封装输入、足够次数的重复实验并记录解封装时间，且不应只比较长度明显不同、路径完全不同的数据。平台的做法是：合法密文之间只改解密消息位（message-zero 与 message-ones，同为等长合法密文），异常输入使用同长度的位翻转、随机与验证失败密文；长度类拒绝在封装层先检查，不计入内核类别样本。",
            "重复次数与时间记录按模块分列：M1 已完成每类 10000 值 × 3 次独立运行；M2–M5 本轮同样完成每类 10000 次、预热 100（窗口外）与 r1/r2/r3 三次独立运行（换种子、换物理核），共 54 次控制器运行全部 restore_match=yes。定位层的 10 次完整标记调用（M3/M5）是有限动态检查，不作为统计样本。 [E19]"
        ], ["T2"]),
        ("题面第 4 条对照：侧信道统计检测", [
            "题面第 4 条要求用统计方法判断不同输入类别是否存在显著可区分性，可使用均值、方差、分位数、置信区间与适当的统计检验，且不能仅凭少量样本或单次测试结论。平台实现分三层：描述统计（均值、标准差、分位数）、参数推断（Welch 均值差与 95% 正态近似区间、Holm 逐步校正）与族外交叉（RTLF α=.01、在线 dudect、Mona 统计对照）。",
            "M1 三层均已执行，并在换种子、换物理核两次独立复测上复现；M2–M5 本轮完成参数层（Welch 95% 正态近似区间与 Holm）与族外 dudect：M2/M3/M5 未拒绝、M4 在 vulnerable 臂拒绝 3 项。工具自身的合成正负校准只证明软件接口，不填充密码实现的结果。 [E20]"
        ], ["T3"]),
        ("题面第 5 条对照：六类泄漏来源 × 解封装步骤", [
            "题面第 5 条列举六类泄漏来源——敏感条件分支、提前返回、可变时间比较函数、数据相关循环、数据相关内存访问、失败路径及异常处理——并要求说明其与 ML-KEM 解封装流程的对应关系。下表按四个步骤逐格给出“查了什么工具或方法、结果如何”：解密（indcpa_dec 与 poly_tomsg 消息解码）、重加密（indcpa_enc）、比较（verify ct 与 ct'）、隐式拒绝（J(z‖ct) 与统一错误路径）。",
            "表格只写已有证据：M1 为真实历史案例，已有 Valgrind、反汇编与三次独立统计；M2 为真实历史案例，静态除法差异与热点探针 varlat 已执行且为阳性，完整调用端到端统计已执行但未检出（Holm 拒绝 0，CI 含 0）；M3 与 M4 的阳性全部为人工构造校准；M5 的 0 errors/0 contexts 只覆盖固定源码、编译器与有限输入。没有证据的格子写“未执行”。KyberSlash 的秘密操作数除法不属于题面六类，单独列在末行以免与“可变时间比较函数”混淆。"
        ], ["T4"]),
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
            "复算入口分两层：(1) 统计与图形由仓库内显式数据文件重建（report-data.json、report-tables.json、EVIDENCE_MATRIX.csv）；(2) 匿名 ZIP 解出后在独立目录重新构建并执行包内 CTest，命令与通过数记录在 docs/evidence/platform-report-20261016/refresh-20261016/zip-recompute.log（刷新包）与 docs/evidence/platform-report-20261016/final-20261016/offline-reproduction.json（终版包），不复用仓库本体充当复算。离线复算只重算已有数据，不算新硬件实验；外部 RTLF、Mona、dudect 与 Binsec 不在该入口重执行。"
        ], ["T5"]),
        ("当前局限、占位符与后续验收", [
            data.get("remaining_summary", "完整 KEM 与人工挂载的适用资格已有新原生证据；各新模块的正式时序、在线 dudect 与复测须继续核对。"),
            "正式统计完成并不要求每个历史实现都在当前 x86_64 上出现阳性。若完整调用不可区分，应报告预算、区间与工具状态，并保留定位与微基准的分层结果；若阴性候选出现阳性，应调查噪声、样本结构与产物机制，不能为了满足预期删除普通长尾或改类。任何工具失败都不能自动归入安全阴性。",
            "本项目不做密钥恢复、不交付 exploit，不把历史 Kyber 等同于最终标准 ML-KEM，也不把人工夹具算作新漏洞。物理精度、逐调用恒频、所有输入下恒时与总体误报率均须单独证据；本报告没有增加这些主张。",
            "下表记录本轮已清空的两处占位项（RTLF 族外交叉、M2 除法热点微基准层）；报告内不再有 «待主控数据»，仍标“未执行”的只有题面第 5 条中结构性未做的单元格。最终验收以 [E01](../../../docs/platform/COMPLETION_REQUIREMENTS.md) 的逐项条件为准，而不是以文稿、图表或模块数量替代实验完成。 [E01]"
        ], ["T6"])
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
    summary = "真实历史案例与人工构造校准分列；检测、定位、修复、复测四段链逐模块给出实际状态，未运行不写成未检出。M2–M5 的锁频家族统计、Mona 对 M2 对照、RTLF 族外交叉（42/42）与 M2 除法热点微基准层均已回填，报告内已无 «待主控数据»；结构性未做的检查写“未执行”。"
    markdown = ["# " + data["title"], data["subtitle"], "日期：" + data["date"], "摘要：" + summary]
    tex = [r"\documentclass[UTF8,fontset=fandol,11pt,a4paper]{ctexart}", r"\usepackage[margin=23mm]{geometry}", r"\usepackage{booktabs,longtable,array,amsmath,xcolor,colortbl,pdflscape,hyperref,seqsplit,graphicx}", r"\definecolor{headergray}{gray}{0.88}", r"\hypersetup{colorlinks=true,linkcolor=blue,urlcolor=blue,pdfauthor={},pdftitle={多泄漏模块检测平台补充报告},pdfsubject={CACR2026EA16XZ},pdfcreator={XeLaTeX}}", r"\setlength{\parindent}{2em}\setlength{\parskip}{0.5em}\linespread{1.18}\raggedbottom\pagestyle{plain}\emergencystretch=2em", r"\begin{document}", r"\thispagestyle{empty}\vspace*{16mm}\begin{center}{\LARGE\bfseries " + tex_escape(data["title"]) + r"\par}\vspace{8mm}{\large " + tex_escape(data["subtitle"]) + r"\par}\vspace{9mm}参赛编号：CACR2026EA16XZ\par " + data["date"] + r"\end{center}\vspace{12mm}", r"\section*{摘要}", tex_escape(summary), r"本报告围绕统一检测、定位、修复与复测工程，整理五个模块的可追溯证据，并按题面第 3、4、5 条给出逐项对照表。固定历史真实路径用于真实案例，人工夹具用于机制校准，参考实现用于阴性对照候选。M2–M5 的锁频端到端家族统计已按各自 PLAN 执行并回填（M2/M3/M5 Holm 拒绝 0，M4 拒绝 3 项且全在 vulnerable 臂）；Mona 对 M2 的六份主类对对照、RTLF 族外交叉（42/42，二值、族外、不进 Holm）与 M2 除法热点微基准层（m=6，Holm 拒绝 0，Δ +0.044 ns）本轮亦已回填，报告内不再有 «待主控数据» 占位符；结构性未做的检查写“未执行”。", r"\par\vspace{6mm}\noindent\textbf{关键词：}侧信道检测；KyberSlash；秘密标记；人工机制校准；可复算证据", r"\vfill\noindent 版本性质：多机制平台补充载体。旧报告与原始证据保留；未运行项见正文、对照表与证据索引。"]
    html_sections = []
    for section_index, (title, paragraphs, table_ids) in enumerate(sections, 1):
        markdown.extend(["\n## " + str(section_index) + " " + title, *paragraphs])
        tex.extend([(r"\clearpage" if section_index == 1 else "") + r"\section{" + tex_escape(title) + "}"] + [tex_escape(paragraph) + "\n\n" for paragraph in paragraphs])
        html_sections.append('<section id="section-' + str(section_index) + '"><h2>' + str(section_index) + " " + html.escape(title) + "</h2>" + "".join("<p>" + render_text(paragraph, "html") + "</p>" for paragraph in paragraphs))
        for table_id in table_ids:
            if table_id == "FIGURE":
                markdown.append("![平台证据矩阵（结果图）](platform-matrix.svg)")
                tex.append(render_tex_matrix(data["modules"]))
                html_sections.append("<figure>" + matrix_svg + "<figcaption>图1：平台证据矩阵（结果图）。橙色格为未运行（not_run），不是阴性。</figcaption></figure>")
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
    state_labels = {"requirements_only": "验收条件", "frozen_reference": "封存引用", "localization_only": "定位层", "pinned_history": "历史钉版", "software_only": "前置软件", "software_contract": "软件协议", "offline_replay_only": "既有数据离线回放", "architecture": "架构", "source_inventory": "来源及许可", "software_contract_only": "软件合同", "native_functional_qualified_statistics_not_run": "原生功能资格；统计未运行", "native_functional_and_localization_statistics_not_run": "原生功能与定位；统计未运行", "native_limited_dynamic_negative_statistics_not_run": "有限原生标记无报警；统计未运行", "bounded_formal_complete_statistics_not_run": "小模型有界验证完成；统计未运行", "locked_reference": "锁频原始证据（封存引用）", "tool_cross_check": "开源检测器交叉印证"}
    for source in source_records:
        markdown.append("- [" + source["id"] + "] " + source["label"] + "；" + source["state"] + "；" + source["path"])
        tex.append(r"\begin{samepage}\noindent\textbf{" + tex_escape(source["id"] + " " + source["label"]) + r"}（" + tex_escape(state_labels.get(source["state"], source["state"])) + r"）\par\noindent\path{" + source["path"] + r"}\par\vspace{1.5mm}\end{samepage}")
        html_sections.append("<li><strong>" + html.escape(source["id"] + " " + source["label"]) + "</strong> · " + html.escape(source["state"]) + "<br><code>" + html.escape(source["path"]) + "</code></li>")
    html_sections.append("</ul></section>")
    tex.append(r"\endgroup\end{document}")
    (DIRECTORY / "report.md").write_text("\n\n".join(markdown) + "\n")
    (DIRECTORY / "report.tex").write_text("\n".join(tex) + "\n")
    html_document = '<!doctype html><html lang="zh-CN"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>' + html.escape(data["title"]) + '</title><style>body{font:17px/1.9 system-ui,sans-serif;color:#193248;background:#f3f5f6;margin:0}main{max-width:1100px;margin:0 auto;padding:55px 35px;background:white}h1{font-size:34px;line-height:1.3}h2{font-size:25px;margin-top:45px}p{max-width:62em}a{color:#185d85}code{overflow-wrap:anywhere;font-size:13px}li{margin:15px 0}svg{width:100%;height:auto}figcaption{font-size:14px;color:#536475}nav{border:1px solid #d9e1e5;padding:18px}footer{margin-top:50px;color:#536475}table{border-collapse:collapse;width:100%;font-size:14px;margin:12px 0}th,td{border:1px solid #cbd6dd;padding:7px 9px;vertical-align:top;text-align:left}th{background:#eef2f5}.table-title{font-weight:600;margin:26px 0 6px}.table-note{font-size:13.5px;color:#536475}</style><main><h1>' + html.escape(data["title"]) + "</h1><p>" + html.escape(data["subtitle"]) + " · " + data["date"] + "</p><p>" + html.escape(summary) + '</p><nav><a href="report.pdf">打开PDF</a> · <a href="report.tex">LaTeX源</a> · <a href="report-tables.json">对照表数据</a> · <a href="evidence-snapshot.json">状态与摘要</a> · <a href="#sources">证据索引</a></nav>' + "".join(html_sections) + "<footer>静态离线展示，无远端资源、脚本、遥测或新硬件采集。表内 «待主控数据» 表示锁频采数尚未回填，不是阴性结果。</footer></main></html>"
    (DIRECTORY / "index.html").write_text(html_document)
    print(json.dumps({"sources": len(source_records), "sections": len(sections), "tables": len(tables), "document_state": data["document_state"]}, ensure_ascii=False))


if __name__ == "__main__":
    main()
