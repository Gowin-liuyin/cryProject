from copy import deepcopy
from pathlib import Path
import hashlib
import json
import re
import zipfile
from lxml import etree

repository = Path(__file__).resolve().parents[3]
source_directory = Path(__file__).resolve().parent
work = repository / 'build/paper-revision-20261011'
delivery = repository / 'deliverables/research/paper-revision-20261011'
source = source_directory / 'input.docx'
output = delivery / 'CACR2026EA16XZ-作品设计报告-论文修订版.docx'
namespace = {'w': 'http://schemas.openxmlformats.org/wordprocessingml/2006/main',
             'a': 'http://schemas.openxmlformats.org/drawingml/2006/main',
             'r': 'http://schemas.openxmlformats.org/officeDocument/2006/relationships'}

def text(element):
    return ''.join(element.xpath('.//w:t/text()', namespaces=namespace))

def replace(paragraph, value):
    properties = paragraph.find('w:pPr', namespace)
    run_properties = paragraph.find('w:r/w:rPr', namespace)
    for child in list(paragraph):
        if child is not properties and child.tag not in [f'{{{namespace["w"]}}}bookmarkStart', f'{{{namespace["w"]}}}bookmarkEnd']:
            paragraph.remove(child)
    run = etree.SubElement(paragraph, f'{{{namespace["w"]}}}r')
    if run_properties is not None:
        run.append(deepcopy(run_properties))
    etree.SubElement(run, f'{{{namespace["w"]}}}t').text = value

with zipfile.ZipFile(source) as archive:
    package = {name: archive.read(name) for name in archive.namelist()}
root = etree.fromstring(package['word/document.xml'])
body = root.find('w:body', namespace)
paragraphs = body.findall('w:p', namespace)
changes = {
    87: '统计时间分析工具从测量结果中寻找不同输入条件下的时间差异。dudect采用Welch检验相关流程；RTLF研究如何在明确的概率假设下限制第一类错误，即零假设成立时错误拒绝它的概率[3][4]。这些研究表明，检验统计量与数据产生方式必须一起考虑。例如，连续调用可能受到相同运行状态的影响，将它们直接当作相互独立的样本，可能使显著性判断失去依据。',
    97: '1.4　关键问题与设计思路',
    98: '题目要求完成时间侧信道检测、定位、防护与验证。实际困难在于，测得的时间差既可能来自实现中的数据依赖，也可能来自输入处理、编译优化或运行环境。我们因此将研究分为相互衔接的两个层面：先确认被测对象和比较条件，再判断数据能够支持何种结论。前者依靠功能测试、实现检查与完整记录，后者依靠对照实验和满足适用条件的统计方法。',
    99: '比较对象的选择直接影响研究能否回答题目。输入长度不同时，外部检查可能提前返回，较大的时间差未必涉及密码内核。本文将正式比较中的密文长度保持一致，使观测覆盖完整解封装过程。编译设置同样影响可比性：局部关闭优化的对照有助于理解某种实现行为，但其结果还需要与正常优化条件分开解释。',
    101: '时间差的安全含义还取决于它与秘密数据之间的关系。常数时间研究关注的是，在指定执行模型下，秘密数据是否影响允许观察的执行行为[20]；这并不要求每次读钟得到完全相同的数值。本文据此结合程序检查与实验观察讨论防护效果，并保留从有限测试推广至其他输入和运行环境时的不确定性。',
    102: '另一个问题是重复核查的计算代价。完整置换计算能够避免随机抽样近似，但随着成对单位数增加，需要处理的状态数按指数增长。本文在限定规模内采用增量更新，减少相邻状态间的重复求和，并先核对结果一致性再比较耗时。这样，效率改进有明确的数学对象，也能够与密码防护效果分别评价。',
    192: '完整解封装计时与局部处理计时各有作用。局部计时便于研究某个步骤，完整调用则更接近使用者能够观察的处理过程。本作品以完整调用作为正式测量范围，包含外部接口检查与解封装计算；结果核对及文件写入均位于计时窗口之外。相应代价是总时间包含更多环境波动，需要结合实现检查和对照实验解释，不能将全部差异归因于某一条指令。',
    227: '秩检验对应的效应量也须计入并列值：它等于第一类观测严格较大所占的比例，加上两类观测相等比例的一半[22]。例如，两类观测均为1、1、2、2时，严格较大比例为0.25，相等比例为0.5，因而效应量为0.5。将其解释为严格大于的概率，会忽略并列值的贡献。',
    279: '这些结果表明，在所测试的固定任务中，专用实现能够减少重复统计分析的等待时间。其收益属于统计计算过程，不意味着ML-KEM解封装更快、检验更灵敏或防护更有效。当前结果未给出任务总体的耗时比置信区间，也未测量整个研发过程的总耗时。',
    305: '该校验同时要求逐次数据与运行开销记录一致，并检查时钟、程序版本、调用数量和完成状态，防止将不完整运行用于分析。计算约需0.209 s，包含读取、计算及输入文件关闭；最后的摘要生成与状态写入另计。原始时间和统计规则保持不变，本项结果用于验证分析流程，未增加新的密码测量。',
    309: '计划中的另一项有限批次比较未完成目标环境下的实验准备，因此没有形成可供分析的数据。本节只报告已经完成并保留原始记录的比较，不对该方案推断稳定性收益。',
    345: '完整调用实验固定使用同一个公开NIST用例，两次相邻连接批次各启动三个进程，共用同一普通程序和同一次系统启动。每个进程在一次设置调用后，分别计时25000次预热及25000次主阶段调用。计时覆盖外部接口检查与完整解封装；返回结果在结束读钟后与独立预期值核对，再作清理。内存分配与文件写入也位于窗口外。具体用例标识和程序信息见附录。',
    366: '这种改进适用于需要多次核查同一组统计结果的场景。统计量、置换集合及并列值处理规则保持不变，使两种计算方法回答同一个问题；输入范围检查则避免以整数溢出换取表面速度。验证的重点因此是相同工作量下能否更快得到相同结果，八个既定任务之外的性能与检出能力仍需另行评价。',
    386: '本作品将功能验证、实现检查和统计分析连接到同一组可追溯材料，使评审者能够从结论返回比较条件与原始记录。已完成的实验支持特定条件下的防护观察，以及固定置换任务的计算开销下降。早期仍有差异的测试、未完成的比较和均值区间尚未满足的前提，共同限定了这些结论的适用范围，也为后续实验确定了需要回答的问题。',
}
edit_log = []
for index, value in changes.items():
    edit_log.append({'paragraph': index, 'before': text(paragraphs[index]), 'after': value})
    replace(paragraphs[index], value)
for index in [100, 103, 364]:
    edit_log.append({'paragraph': index, 'removed': text(paragraphs[index])})
    body.remove(paragraphs[index])
removed = 0
for table in body.findall('w:tbl', namespace):
    if text(table).startswith('通行术语'):
        body.remove(table)
        removed += 1
assert removed == 1

replacements = {
    '1.4　研究问题与术语说明': '1.4　关键问题与设计思路',
    '不含秘密数据的成对数据的': '公开成对数据的',
    '不适用适用条件': '不满足适用条件的输入',
    '同一统计规则被反复核查': '同一统计结果被反复核查',
    '功能验收': '功能验证',
    '独立向量验收': '独立向量验证',
    '工程边界检查': '接口边界检查',
    '原生 Linux 测试环境': 'Linux实机测试环境',
    '原生解封装': '完整解封装',
    '身份': '来源',
    '实证增量': '实验结果',
    '完整函数成本': '完整计算耗时',
    '新产物适用条件': '新程序的检查结果',
    '就绪开销': '启动准备时间',
    '语义': '处理规则',
    '先验收功能与接口': '先验证功能与接口',
    '报告是否绑定正确产物': '报告是否对应被测程序',
    '固定快照': '固定版本',
    '秘密依赖': '对秘密数据的依赖',
    '参考实现 记录': '参考实现记录',
    '第一期 的': '第一期的',
    '复核期 的': '复核期的',
    '复核期 普通': '复核期普通',
    '复核期 两个': '复核期两个',
    '使用 第一期 的': '使用第一期的',
    '结合 第一期 与 复核期': '结合第一期与复核期',
    '尾规则': '尾部计数规则',
    '原有历史对照材料': '已有历史对照材料',
    'open 失败传播': '随机源打开失败时返回错误',
    'read / close 注入未执行': '读取及关闭失败的测试未执行',
    '-O2 -g -DNDEBUG；无 LTO；非 sanitizer': '二级优化；保留调试信息；关闭调试断言；无链接时优化和动态检查插桩',
    '外部 taskset 绑定 CPU2': '进程固定在逻辑CPU2',
    '原生 Linux': 'Linux实机',
    'RAW 空窗': '空窗口',
    '秘密归因或防护有效性': '差异来自秘密数据或防护有效',
    '默认交付流程不将旧主动机制计时作为普通入口': '普通使用流程不重复执行历史案例的专用测量',
    '已有直接先验': '已有相关研究',
    '主观察墙钟': '主阶段总时长',
    '主墙钟的整数账': '主阶段总时长的分解',
    '主均值的精确值': '主阶段平均耗时的精确值',
    '真实记录条件化控制': '固定时间记录的置换校验',
    '数据完整性与适用条件与数值分离': '数据检查与统计判断分别报告',
    '工程输入约束与解释边界': '输入限制与统计适用范围',
    '八任务对照及预导入复核': '八个任务对照及预先导入复核',
    'SciPy 就绪成本': 'SciPy启动准备时间',
    'H1 主比较': '主比较',
    'H2 人工回归': '分组比较：人工分支对照',
    'H2 参考实现 / 正常优化对照': '分组比较：参考及正常优化对照',
    'H2 掩码对照': '分组比较：掩码对照',
    '显著残差': '显著差异',
    '人工分支对照档案': '已归档的分支实现比较',

}
in_main = False
for element in body:
    value = text(element)
    if value.startswith('第1章') and element in list(body) and element.find('w:pPr/w:pStyle', namespace) is not None and element.find('w:pPr/w:pStyle', namespace).get(f'{{{namespace["w"]}}}val') == 'RWChapter':
        in_main = True
    if value == '参考文献':
        in_main = False
    if in_main:
        content_paragraphs = [element] if element.tag == f'{{{namespace["w"]}}}p' else element.findall('.//w:p', namespace)
        for content_paragraph in content_paragraphs:
            old_text = text(content_paragraph)
            new_text = old_text
            for old, new in replacements.items():
                new_text = new_text.replace(old, new)
            if new_text != old_text and not content_paragraph.xpath('.//*[local-name()="oMath" or local-name()="drawing"]'):
                replace(content_paragraph, new_text)
            else:
                for node in content_paragraph.findall('.//w:t', namespace):
                    for old, new in replacements.items():
                        node.text = (node.text or '').replace(old, new)
# 目录文字同步，最终页码以渲染结果为准。
for node in root.findall('.//w:t', namespace):
    if node.text:
        node.text = node.text.replace('1.4　研究问题与术语说明', '1.4　关键问题与设计思路').replace('5.2　独立向量验收与工程边界检查', '5.2　独立向量验证与接口边界检查')

relations = {node.get('Id'): node.get('Target') for node in etree.fromstring(package['word/_rels/document.xml.rels'])}
manifest = json.loads((source_directory / 'figure-manifest.json').read_text())
old_manifest = json.loads((source_directory / 'input-figure-manifest.json').read_text())
old_lookup = {entry['sha256']['png']: entry['figure'] for entry in old_manifest}
for blip in root.findall('.//a:blip', namespace):
    target = 'word/' + relations[blip.get(f'{{{namespace["r"]}}}embed')]
    digest = hashlib.sha256(package[target]).hexdigest()
    if digest in old_lookup:
        package[target] = (delivery / 'figures' / f'figure-{old_lookup[digest]}.png').read_bytes()

# 含行内公式的说明段也使用模板正文格式。
math_namespace = {'m': 'http://schemas.openxmlformats.org/officeDocument/2006/math', **namespace}
styles = etree.fromstring(package['word/styles.xml'])
body_style = styles.xpath('./w:style[@w:styleId="RWBody"]', namespaces=namespace)[0]
for paragraph in body.findall('w:p', namespace):
    if paragraph.findall('.//m:oMath', math_namespace) and len(text(paragraph).strip()) > 20:
        old_properties = paragraph.find('w:pPr', namespace)
        if old_properties is not None:
            paragraph.remove(old_properties)
        properties = deepcopy(body_style.find('w:pPr', namespace))
        style = etree.Element(f'{{{namespace["w"]}}}pStyle')
        style.set(f'{{{namespace["w"]}}}val', 'RWBody')
        properties.insert(0, style)
        paragraph.insert(0, properties)
        for run in paragraph.findall('.//w:r', namespace):
            old_properties = run.find('w:rPr', namespace)
            if old_properties is not None:
                run.remove(old_properties)
            run.insert(0, deepcopy(body_style.find('w:rPr', namespace)))

# 数值列统一居中，去除旧表复制时遗留的内部粗横线。
for table in body.findall('w:tbl', namespace)[1:]:
    rows = table.findall('w:tr', namespace)
    for row_index, row in enumerate(rows):
        for cell in row.findall('w:tc', namespace):
            cell_properties = cell.find('w:tcPr', namespace)
            if cell_properties is None:
                cell_properties = etree.SubElement(cell, f'{{{namespace["w"]}}}tcPr')
            borders = cell_properties.find('w:tcBorders', namespace)
            if borders is not None:
                cell_properties.remove(borders)
            borders = etree.SubElement(cell_properties, f'{{{namespace["w"]}}}tcBorders')
            for side in ['top', 'bottom']:
                border = etree.SubElement(borders, f'{{{namespace["w"]}}}{side}')
                visible = (side == 'top' and row_index == 0) or (side == 'bottom' and row_index in [0, len(rows)-1])
                border.set(f'{{{namespace["w"]}}}val', 'single' if visible else 'nil')
                border.set(f'{{{namespace["w"]}}}sz', '4' if row_index == 0 and side == 'bottom' else '10')
                border.set(f'{{{namespace["w"]}}}color', '000000')
            if re.fullmatch(r'[\d.−+\-%,/；：\[\]（）—\s]+', text(cell)) and re.search(r'\d', text(cell)):
                for paragraph in cell.findall('w:p', namespace):
                    properties = paragraph.find('w:pPr', namespace)
                    if properties is None:
                        properties = etree.SubElement(paragraph, f'{{{namespace["w"]}}}pPr')
                    alignment = properties.find('w:jc', namespace)
                    if alignment is None:
                        alignment = etree.SubElement(properties, f'{{{namespace["w"]}}}jc')
                    alignment.set(f'{{{namespace["w"]}}}val', 'center')

package['word/document.xml'] = etree.tostring(root, encoding='UTF-8', xml_declaration=True, standalone=True)
with zipfile.ZipFile(output, 'w', compression=zipfile.ZIP_DEFLATED) as archive:
    for name, payload in package.items():
        archive.writestr(name, payload)
headings = []
for paragraph in body.findall('w:p', namespace):
    style = paragraph.find('w:pPr/w:pStyle', namespace)
    if style is not None and style.get(f'{{{namespace["w"]}}}val') in ['RWChapter', 'RWSection']:
        bookmark = paragraph.find('w:bookmarkStart', namespace)
        headings.append({'title': text(paragraph), 'style': style.get(f'{{{namespace["w"]}}}val'), 'anchor': bookmark.get(f'{{{namespace["w"]}}}name')})
(work / 'headings.json').write_text(json.dumps(headings, ensure_ascii=False, indent=2))
(source_directory / 'edit-log.json').write_text(json.dumps(edit_log, ensure_ascii=False, indent=2))
(work / 'candidate-text.txt').write_text('\n'.join(text(element) for element in body))
print(output)
