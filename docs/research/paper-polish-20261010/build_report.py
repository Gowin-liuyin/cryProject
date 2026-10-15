from copy import deepcopy
from pathlib import Path
import hashlib
import json
import re
import zipfile

from lxml import etree
from PIL import Image


repository = Path(__file__).resolve().parents[3]
work_directory = repository / 'build/paper-polish-20261010'
source_directory = Path(__file__).resolve().parent
output_directory = repository / 'deliverables/research/paper-polish-20261010'
reference = repository / 'deliverables/research/aris-report-synthesis-20261010/CACR2026EA16XZ-作品设计报告-匿名版.docx'
output = output_directory / 'CACR2026EA16XZ-作品设计报告-论文修订版.docx'
expected_source = '95ffce23d02180117fb05ccf9ebc406b7b05ae20038f08042e25d13934e2983f'
assert hashlib.sha256(reference.read_bytes()).hexdigest() == expected_source
revisions = json.loads((source_directory / 'revisions.json').read_text())
additions = json.loads((source_directory / 'additions.json').read_text())
namespace = {
    'w': 'http://schemas.openxmlformats.org/wordprocessingml/2006/main',
    'm': 'http://schemas.openxmlformats.org/officeDocument/2006/math',
    'a': 'http://schemas.openxmlformats.org/drawingml/2006/main',
    'r': 'http://schemas.openxmlformats.org/officeDocument/2006/relationships',
    'wp': 'http://schemas.openxmlformats.org/drawingml/2006/wordprocessingDrawing',
}


def tag(prefix, name):
    return '{' + namespace[prefix] + '}' + name


def text(element):
    return ''.join(element.xpath('.//w:t/text()', namespaces=namespace))


def replace_paragraph(paragraph, value):
    properties = paragraph.find('w:pPr', namespace)
    run_properties = paragraph.find('w:r/w:rPr', namespace)
    for child in list(paragraph):
        if child is not properties:
            paragraph.remove(child)
    run = etree.SubElement(paragraph, tag('w', 'r'))
    if run_properties is not None:
        run.append(deepcopy(run_properties))
    etree.SubElement(run, tag('w', 't')).text = value


with zipfile.ZipFile(reference) as source:
    package = {name: source.read(name) for name in source.namelist()}
with zipfile.ZipFile(repository / 'docs/reference/official-2026/report-template-original.docx') as source:
    official_package = {name: source.read(name) for name in source.namelist()}
root = etree.fromstring(package['word/document.xml'])
body = root.find('w:body', namespace)
original_elements = list(body)
relationship_root = etree.fromstring(package['word/_rels/document.xml.rels'])
relationship_namespace = relationship_root.tag.split('}')[0] + '}'
relationships = {item.get('Id'): item.get('Target') for item in relationship_root}
edit_log = []
for index, value in revisions['paragraphs'].items():
    if value is None:
        continue
    paragraph = original_elements[int(index)]
    assert paragraph.tag == tag('w', 'p')
    edit_log.append({'source_body_index': int(index), 'before': text(paragraph), 'after': value})
    replace_paragraph(paragraph, value)

abstract_candidates = original_elements[24].xpath('.//w:p', namespaces=namespace)
abstract_paragraph = max(abstract_candidates, key=lambda paragraph: len(text(paragraph)))
replace_paragraph(abstract_paragraph, revisions['abstract'])
for element in original_elements[:25]:
    for node in element.findall('.//w:t', namespace):
        node.text = (node.text or '').replace('（暂定题名）', '').replace('证据资格', '置换检验')
for node in original_elements[21].findall('.//w:t', namespace):
    node.text = (node.text or '').replace('10 月 10 日', '10 月 11 日')

# 算法关系使用数学算子，保留原生公式结构。
for index in [108, 110]:
    for node in original_elements[index].findall('.//m:t', namespace):
        node.text = (node.text or '').replace('KeyGen', 'G').replace('Encaps', 'E').replace('Decaps', 'D')

term_replacements = [
    ('后赋标签条件拒绝数', '固定时间记录的拒绝标签数'),
    ('后赋标签控制', '固定时间记录的置换校验'),
    ('后赋标签', '采集后赋予的标签'),
    ('数据资格控制', '数据完整性与适用条件检查'),
    ('数据资格', '数据完整性与适用条件'),
    ('统计资格', '统计适用条件'),
    ('资格校验', '适用条件检查'),
    ('证据资格', '分析适用条件'),
    ('资格', '适用条件'),
    ('弱均值', '平均时间差'),
    ('成本边界', '计时范围'),
    ('纯主几何覆盖', '主阶段观测窗口覆盖率'),
    ('几何覆盖', '观测窗口覆盖率'),
    ('读取对齐区间', '异步读取引入的估计范围'),
    ('人工机制回归', '人工分支对照'),
    ('人工机制', '人工对照'),
    ('无秘密', '不含秘密数据的'),
    ('原生验收', '目标环境验证'),
    ('精确复算', '精确置换计算'),
    ('来源身份', '来源信息'),
    ('产物身份', '程序来源'),
    ('源码身份', '源码版本'),
    ('source身份', '源码版本'),
    ('计数与身份', '计数与来源'),
    ('清单身份', '清单版本'),
    ('父窗口', '外层计时窗口'),
    ('同语言函数对照', '同语言计算对照'),
    ('完整统计函数', '完整统计计算'),
    ('函数级', '局部'),
    ('目标函数', '目标处理'),
    ('reference', '参考实现'),
    ('vulnerable', '人工分支对照'),
    ('hardened', '掩码对照'),
    ('deployable', '正常优化对照'),
    ('equal', '等幅'),
    ('graded', '渐增幅'),
    ('E02', '第一期'),
    ('N01', '复核期'),
    ('G2', '受控窗口'),
    ('R07', '同机复测'),
    ('RAW-1', '空窗1'),
    ('RAW-2', '空窗2'),
    ('RAW-3', '空窗3'),
    ('E1-P1', '第一批1'), ('E1-P2', '第一批2'), ('E1-P3', '第一批3'),
    ('E2-P1', '第二批1'), ('E2-P2', '第二批2'), ('E2-P3', '第二批3'),
    ('open 失败传播', '随机源打开失败传播'),
    ('read / close 注入未执行', '读取及关闭失败注入未执行'),
    ('后端、include、值屏障、栈标记', '后端、编译来源与编译器防护设置'),
    ('历史标签', '对照实现'),
    ('主pair', '主观察区间'),
    ('跨界pair', '跨界区间'),
    ('纯主支持窗口', '完整位于主阶段的窗口'),
    ('context', '环境参考'),
    ('共同身份', '共同的运行标识'),
    ('运行身份', '运行标识'),
    ('采集身份', '采集记录'),
    ('文件身份', '文件来源'),
    ('核对身份', '核对来源'),
    ('核验身份', '核验来源'),
    ('接口口径', '接口要求'),
    ('标准口径', '标准版本'),
    ('数据完整性与适用条件与错误原因', '完整性及适用条件检查结果'),
    ('失配对照', '比较条件不一致的对照'),
    ('强基线', '对照基线'),
    ('计时口径', '计时方式'),
    ('CLOCK_MONOTONIC', '系统单调时钟'),
    ('外部 taskset 绑定 CPU2', '进程固定在逻辑CPU2'),
    ('RelWithDebInfo', '优化构建并保留调试信息'),
    ('-O2 -g -DNDEBUG；无 LTO；非 sanitizer', '二级优化；无链接时优化；无动态检查插桩'),
    ('纯主覆盖', '主阶段覆盖率'),
    ('完整落入纯支持区间的主调用', '完整位于观测窗口内的主阶段调用'),
]
for element in original_elements[77:461]:
    for node in element.findall('.//w:t', namespace):
        value = node.text or ''
        for old, new in term_replacements:
            value = value.replace(old, new)
        node.text = value

# 关键词和版本代号只在附录中保留技术映射。
for paragraph_index, value in {
    162: '第3章　系统设计与实验方法',
    164: '3.1　系统总体设计',
    174: '3.2　版本固定与对照实现',
    191: '3.4　运行记录与数据核对',
    178: '表3.2　四种对照实现及其用途',
    195: '表3.3　运行记录及检查目的',
    318: '5.4　精确置换计算效率与计时范围复核',
    281: '5.1　测试环境与验证方案',
    336: '5.5　有限样本数值验证中的第一类错误与功效',
    391: '表5.11　受控运行的调用数量与观测窗口覆盖率',
    400: '表5.12　受控运行的完整调用耗时',
    421: '第6章　作品特色与应用前景',
    465: '[3] Reparaz O, Balasch J, Verbauwhede I. Dude, is my code constant time? Design, Automation & Test in Europe, 2017:1697–1702. DOI:10.23919/DATE.2017.7927267.',
    467: '[5] Virtanen P, Gommers R, Oliphant T E, et al. SciPy 1.0: fundamental algorithms for scientific computing in Python. Nature Methods, 2020, 17:261–272. DOI:10.1038/s41592-019-0686-2. 本文对照环境为SciPy 1.16.3与NumPy 2.3.5，具体置换规则见正文与复现材料。',
}.items():
    if original_elements[paragraph_index].tag == tag('w', 'p'):
        replace_paragraph(original_elements[paragraph_index], value)
body.remove(original_elements[511])

image_locations = {112: '2-1', 121: '2-2', 144: '2-3', 166: '3-1', 185: '3-2',
                   193: '3-3', 203: '3-4', 213: '3-5', 225: '4-1', 283: '5-1',
                   302: '5-2', 311: '5-3', 323: '5-4', 342: '5-5', 355: '5-6',
                   376: '5-7', 394: '5-8'}


def resize_drawing(paragraph, figure_path):
    with Image.open(figure_path) as image:
        width, height = image.size
    drawing_width = 5688000
    drawing_height = round(drawing_width * height / width)
    for element in paragraph.findall('.//wp:extent', namespace) + paragraph.findall('.//a:xfrm/a:ext', namespace):
        element.set('cx', str(drawing_width))
        element.set('cy', str(drawing_height))
    for description in paragraph.findall('.//wp:docPr', namespace):
        description.set('descr', figure_path.stem)


for index, identifier in image_locations.items():
    figure_path = output_directory / 'figures' / f'figure-{identifier}.png'
    paragraph = original_elements[index]
    identifier_attribute = paragraph.find('.//a:blip', namespace).get(tag('r', 'embed'))
    package['word/' + relationships[identifier_attribute]] = figure_path.read_bytes()
    resize_drawing(paragraph, figure_path)


def paragraph(value, role='body'):
    template_index = {'body': 81, 'section': 79, 'chapter': 77, 'caption': 113, 'reference': 478}[role]
    result = deepcopy(original_elements[template_index])
    replace_paragraph(result, value)
    return result


bookmark_number = 9000
figure_number = 9000


def heading(value, chapter=False):
    global bookmark_number
    result = paragraph(value, 'chapter' if chapter else 'section')
    bookmark_number += 1
    start = etree.Element(tag('w', 'bookmarkStart'))
    start.set(tag('w', 'id'), str(bookmark_number))
    start.set(tag('w', 'name'), f'paper_heading_{bookmark_number}')
    result.insert(1, start)
    end = etree.SubElement(result, tag('w', 'bookmarkEnd'))
    end.set(tag('w', 'id'), str(bookmark_number))
    return result


def figure(identifier, caption):
    global figure_number
    result = deepcopy(original_elements[112])
    figure_number += 1
    relationship_id = f'rIdPaper{figure_number}'
    image_name = f'media/paper-{identifier}.png'
    image_path = output_directory / 'figures' / f'figure-{identifier}.png'
    result.find('.//a:blip', namespace).set(tag('r', 'embed'), relationship_id)
    for properties in result.findall('.//wp:docPr', namespace):
        properties.set('id', str(figure_number))
        properties.set('name', f'Figure {identifier}')
    relation = etree.SubElement(relationship_root, relationship_namespace + 'Relationship')
    relation.set('Id', relationship_id)
    relation.set('Type', namespace['r'] + '/image')
    relation.set('Target', image_name)
    package['word/' + image_name] = image_path.read_bytes()
    resize_drawing(result, image_path)
    return [result, paragraph(caption, 'caption')]


def table(rows):
    result = deepcopy(original_elements[94])
    row_template = deepcopy(result.findall('w:tr', namespace)[1])
    header_template = deepcopy(result.findall('w:tr', namespace)[0])
    for child in list(result):
        if child.tag == tag('w', 'tr'):
            result.remove(child)
    for row_index, values in enumerate(rows):
        new_row = deepcopy(header_template if row_index == 0 else row_template)
        cells = new_row.findall('w:tc', namespace)
        assert len(cells) == len(values)
        for cell, value in zip(cells, values):
            cell_paragraphs = cell.findall('w:p', namespace)
            replace_paragraph(cell_paragraphs[0], value)
            for extra in cell_paragraphs[1:]:
                cell.remove(extra)
        result.append(new_row)
    return result


for section in additions['sections']:
    elements = [heading(section['title'])]
    for index, value in enumerate(section['paragraphs']):
        elements.append(paragraph(value))
        if section['title'].startswith('3.7') and index == 1:
            elements.extend(figure(section['figure'], section['caption']))
        if section['title'].startswith('5.11') and index == 2:
            elements.extend(figure(section['figures'][0]['id'], section['figures'][0]['caption']))
        if section['title'].startswith('5.11') and index == 4:
            elements.extend(figure(section['figures'][1]['id'], section['figures'][1]['caption']))
    if 'table' in section:
        elements.append(paragraph(section['table']['caption'], 'caption'))
        elements.append(table(section['table']['rows']))
    if 'figure' in section and not section['title'].startswith('3.7'):
        elements.extend(figure(section['figure'], section['caption']))
    insert_index = body.index(original_elements[section['after']]) + 1
    for element in elements:
        body.insert(insert_index, element)
        insert_index += 1

insert_index = body.index(original_elements[478]) + 1
for value in additions['references']:
    body.insert(insert_index, paragraph(value, 'reference'))
    insert_index += 1

# 附录保留可复核的标识；新增截图栏不伪造运行画面。
appendix = additions['appendix']
appendix_elements = [heading(appendix['title'], chapter=True)]
appendix_elements.extend(paragraph(value) for value in appendix['paragraphs'])
for slot_index, (caption, value) in enumerate(appendix['screenshots']):
    if slot_index % 2 == 0:
        page_break = etree.Element(tag('w', 'p'))
        run = etree.SubElement(page_break, tag('w', 'r'))
        etree.SubElement(run, tag('w', 'br')).set(tag('w', 'type'), 'page')
        appendix_elements.append(page_break)
    placeholder = paragraph(value)
    properties = placeholder.find('w:pPr', namespace)
    spacing = properties.find('w:spacing', namespace)
    if spacing is None:
        spacing = etree.SubElement(properties, tag('w', 'spacing'))
    spacing.set(tag('w', 'before'), '1100')
    spacing.set(tag('w', 'after'), '1100')
    borders = etree.SubElement(properties, tag('w', 'pBdr'))
    for side in ['top', 'left', 'bottom', 'right']:
        border = etree.SubElement(borders, tag('w', side))
        for attribute, setting in [('val', 'single'), ('sz', '4'), ('color', 'B0B0B0'), ('space', '10')]:
            border.set(tag('w', attribute), setting)
    appendix_elements.extend([placeholder, paragraph(caption, 'caption')])
for element in appendix_elements:
    body.insert(body.index(original_elements[513]), element)

# 标题书签和目录重新对应，页码由最终PDF回填。
heading_elements = []
started_body = False
for element in list(body):
    if element is original_elements[77]:
        started_body = True
    if not started_body or element.tag != tag('w', 'p'):
        continue
    style = element.find('w:pPr/w:pStyle', namespace)
    if style is not None and style.get(tag('w', 'val')) in ['RWChapter', 'RWSection']:
        existing = element.find('w:bookmarkStart', namespace)
        if existing is None:
            bookmark_number += 1
            existing = etree.Element(tag('w', 'bookmarkStart'))
            existing.set(tag('w', 'id'), str(bookmark_number))
            existing.set(tag('w', 'name'), f'paper_heading_{bookmark_number}')
            element.insert(1, existing)
            end = etree.SubElement(element, tag('w', 'bookmarkEnd'))
            end.set(tag('w', 'id'), str(bookmark_number))
        heading_elements.append((element, style.get(tag('w', 'val')), existing.get(tag('w', 'name'))))
toc_elements = []
for index, (element, style, anchor) in enumerate(heading_elements):
    if index in [0, 25]:
        title_paragraph = deepcopy(original_elements[27])
        replace_paragraph(title_paragraph, '目　录' if index == 0 else '目　录（续）')
        if index == 25:
            properties = title_paragraph.find('w:pPr', namespace)
            etree.SubElement(properties, tag('w', 'pageBreakBefore'))
        toc_elements.append(title_paragraph)
    entry = deepcopy(original_elements[28 if style == 'RWChapter' else 29])
    hyperlink = entry.find('w:hyperlink', namespace)
    hyperlink.set(tag('w', 'anchor'), anchor)
    texts = hyperlink.findall('.//w:t', namespace)
    texts[0].text = text(element)
    for extra in texts[1:]:
        extra.text = ''
    entry.findall('.//w:t', namespace)[-1].text = '0'
    toc_elements.append(entry)
toc_start = body.index(original_elements[27])
for element in original_elements[27:75]:
    if element.getparent() is body:
        body.remove(element)
for element in reversed(toc_elements):
    body.insert(toc_start, element)

# 统一三线表和图注的分页约束，避免将整张长表锁在一页。
for table_element in body.findall('w:tbl', namespace)[1:]:
    rows = table_element.findall('w:tr', namespace)
    for row_index, row in enumerate(rows):
        properties = row.find('w:trPr', namespace)
        if properties is None:
            properties = etree.SubElement(row, tag('w', 'trPr'))
        if properties.find('w:cantSplit', namespace) is None:
            etree.SubElement(properties, tag('w', 'cantSplit'))
        if row_index == 0 and properties.find('w:tblHeader', namespace) is None:
            etree.SubElement(properties, tag('w', 'tblHeader'))
        for paragraph_element in row.findall('.//w:p', namespace):
            p_properties = paragraph_element.find('w:pPr', namespace)
            if p_properties is not None:
                for keep in p_properties.findall('w:keepNext', namespace):
                    p_properties.remove(keep)
                if row_index == 0 or (len(rows) <= 9 and row_index < len(rows) - 1):
                    etree.SubElement(p_properties, tag('w', 'keepNext'))

for caption in body.findall('w:p', namespace):
    value = text(caption)
    if re.match(r'表\d', value):
        properties = caption.find('w:pPr', namespace)
        if properties is not None and properties.find('w:keepNext', namespace) is None:
            etree.SubElement(properties, tag('w', 'keepNext'))

# 将官方模板的实际示例格式映射到各正文角色。
official_root = etree.fromstring(official_package['word/document.xml'])
official_body = official_root.find('w:body', namespace)
official_paragraphs = official_body.findall('w:p', namespace)
for source_index, template_index in [(0, 0), (2, 2), (3, 3), (10, 10), (14, 14), (21, 22), (22, 23)]:
    destination = original_elements[source_index]
    old_properties = destination.find('w:pPr', namespace)
    if old_properties is not None:
        destination.remove(old_properties)
    destination.insert(0, deepcopy(official_paragraphs[template_index].find('w:pPr', namespace)))
    if source_index == 14:
        template_runs = official_paragraphs[template_index].findall('w:r', namespace)
        for run_index, run in enumerate(destination.findall('w:r', namespace)):
            old_properties = run.find('w:rPr', namespace)
            if old_properties is not None:
                run.remove(old_properties)
            template_run = template_runs[0 if run_index == 0 else 1]
            run.insert(0, deepcopy(template_run.find('w:rPr', namespace)))
styles_root = etree.fromstring(package['word/styles.xml'])
official_styles = etree.fromstring(official_package['word/styles.xml'])
style_map = {item.get(tag('w', 'styleId')): item for item in styles_root.findall('w:style', namespace)}
official_style_map = {item.get(tag('w', 'styleId')): item for item in official_styles.findall('w:style', namespace)}
official_table = official_body.find('w:tbl', namespace)
for property_name in ['tblPr', 'tblGrid']:
    old = original_elements[24].find('w:' + property_name, namespace)
    if old is not None:
        original_elements[24].replace(old, deepcopy(official_table.find('w:' + property_name, namespace)))
for old_row, template_row in zip(original_elements[24].findall('w:tr', namespace), official_table.findall('w:tr', namespace)):
    old_properties = old_row.find('w:trPr', namespace)
    if old_properties is not None:
        old_row.remove(old_properties)
    template_properties = template_row.find('w:trPr', namespace)
    if template_properties is not None:
        old_row.insert(0, deepcopy(template_properties))
abstract_prototype = official_table.xpath('.//w:p[w:pPr/w:pStyle[@w:val="13"]]', namespaces=namespace)[0]
old_properties = abstract_paragraph.find('w:pPr', namespace)
abstract_paragraph.replace(old_properties, deepcopy(abstract_prototype.find('w:pPr', namespace)))
abstract_run = abstract_paragraph.find('w:r', namespace)
old_properties = abstract_run.find('w:rPr', namespace)
if old_properties is not None:
    abstract_run.remove(old_properties)
abstract_properties = deepcopy(official_style_map['1'].find('w:rPr', namespace))
abstract_fonts = abstract_properties.find('w:rFonts', namespace)
for attribute in ['ascii', 'hAnsi', 'eastAsia']:
    abstract_fonts.set(tag('w', attribute), '宋体')
abstract_run.insert(0, abstract_properties)


def set_role(style_name, prototype, bold=False, default_font=False):
    style = style_map[style_name]
    for child in list(style):
        if child.tag in [tag('w', 'pPr'), tag('w', 'rPr')]:
            style.remove(child)
    properties = deepcopy(prototype.find('w:pPr', namespace))
    for child in list(properties):
        if child.tag in [tag('w', 'pStyle'), tag('w', 'rPr'), tag('w', 'sectPr')]:
            properties.remove(child)
    run_properties = deepcopy(official_style_map['1'].find('w:rPr', namespace) if default_font else prototype.find('w:pPr/w:rPr', namespace))
    if bold:
        etree.SubElement(run_properties, tag('w', 'b'))
        etree.SubElement(properties, tag('w', 'keepNext'))
        etree.SubElement(properties, tag('w', 'keepLines'))
    style.extend([properties, run_properties])
    return properties, run_properties


body_properties, body_run_properties = set_role('RWBody', official_paragraphs[32])
chapter_properties, chapter_run_properties = set_role('RWChapter', official_paragraphs[27], bold=True)
section_properties, section_run_properties = set_role('RWSection', official_paragraphs[31], bold=True)
caption_properties, caption_run_properties = set_role('RWCaption', official_paragraphs[32], default_font=True)
for toc_role in ['RWTOC1', 'RWTOC2']:
    set_role(toc_role, official_paragraphs[32], default_font=True)
    if toc_role == 'RWTOC1':
        etree.SubElement(style_map[toc_role].find('w:rPr', namespace), tag('w', 'b'))
for element in toc_elements:
    style = element.find('w:pPr/w:pStyle', namespace)
    role = style.get(tag('w', 'val')) if style is not None else None
    if role in ['RWTOC1', 'RWTOC2']:
        for run in element.findall('.//w:r', namespace):
            old = run.find('w:rPr', namespace)
            if old is not None:
                run.remove(old)
            run.insert(0, deepcopy(style_map[role].find('w:rPr', namespace)))
        for spacing in element.findall('w:pPr/w:spacing', namespace):
            spacing.set(tag('w', 'line'), '480')
            spacing.set(tag('w', 'lineRule'), 'exact')
            spacing.set(tag('w', 'before'), '0')
            spacing.set(tag('w', 'after'), '0')
    else:
        for run in element.findall('w:r', namespace):
            old = run.find('w:rPr', namespace)
            if old is not None:
                run.remove(old)
            run.insert(0, deepcopy(chapter_run_properties))
for style_name, level in [('RWChapter', 0), ('RWSection', 1)]:
    etree.SubElement(style_map[style_name].find('w:pPr', namespace), tag('w', 'outlineLvl')).set(tag('w', 'val'), str(level))

started_body = False
for element in list(body):
    if element is original_elements[77]:
        started_body = True
    if not started_body or element.tag != tag('w', 'p'):
        continue
    properties = element.find('w:pPr', namespace)
    style_node = properties.find('w:pStyle', namespace) if properties is not None else None
    role = style_node.get(tag('w', 'val')) if style_node is not None else 'RWBody'
    has_drawing = bool(element.findall('.//w:drawing', namespace))
    has_math = bool(element.findall('m:oMath', namespace))
    is_placeholder = '待插入真实截图' in text(element)
    if not has_drawing and not has_math and not is_placeholder:
        role = role if role in ['RWBody', 'RWChapter', 'RWSection', 'RWCaption'] else 'RWBody'
        if properties is not None:
            element.remove(properties)
        properties = deepcopy(style_map[role].find('w:pPr', namespace))
        properties.insert(0, etree.Element(tag('w', 'pStyle')))
        properties[0].set(tag('w', 'val'), role)
        if role == 'RWCaption':
            etree.SubElement(properties, tag('w', 'jc')).set(tag('w', 'val'), 'center')
            if text(element).startswith('表'):
                etree.SubElement(properties, tag('w', 'keepNext'))
        if text(element).startswith('附录') or text(element) == '参考文献':
            etree.SubElement(properties, tag('w', 'pageBreakBefore'))
        element.insert(0, properties)
        run_properties = style_map[role].find('w:rPr', namespace)
        for run in element.findall('.//w:r', namespace):
            old = run.find('w:rPr', namespace)
            if old is not None:
                run.remove(old)
            run.insert(0, deepcopy(run_properties))
    if has_math:
        for tab in element.findall('w:pPr/w:tabs/w:tab', namespace):
            position = tab.get(tag('w', 'pos'))
            if position in ['4479', '8957']:
                tab.set(tag('w', 'pos'), '4819' if position == '4479' else '9638')
        for run in element.findall('.//m:r', namespace):
            properties_math = run.find('w:rPr', namespace)
            if properties_math is None:
                properties_math = etree.Element(tag('w', 'rPr'))
                run.insert(1 if run.find('m:rPr', namespace) is not None else 0, properties_math)
            size = properties_math.find('w:sz', namespace)
            if size is None:
                size = etree.SubElement(properties_math, tag('w', 'sz'))
            size.set(tag('w', 'val'), '28')

official_section = official_root.find('.//w:sectPr', namespace)
for section in root.findall('.//w:sectPr', namespace):
    for property_name in ['pgSz', 'pgMar', 'cols', 'docGrid']:
        old = section.find('w:' + property_name, namespace)
        if old is not None:
            section.remove(old)
        section.append(deepcopy(official_section.find('w:' + property_name, namespace)))
package['word/header2.xml'] = official_package['word/header1.xml']
package['word/footer2.xml'] = official_package['word/footer1.xml']
for table_element in body.findall('w:tbl', namespace)[1:]:
    for table_paragraph in table_element.findall('.//w:p', namespace):
        properties = table_paragraph.find('w:pPr', namespace)
        if properties is None:
            properties = etree.SubElement(table_paragraph, tag('w', 'pPr'))
        old_spacing = properties.find('w:spacing', namespace)
        if old_spacing is not None:
            properties.remove(old_spacing)
        spacing = etree.SubElement(properties, tag('w', 'spacing'))
        for attribute, value in [('before', '0'), ('after', '0'), ('line', '240'), ('lineRule', 'auto')]:
            spacing.set(tag('w', attribute), value)
    for run in table_element.findall('.//w:r', namespace):
        old = run.find('w:rPr', namespace)
        old_bold = old.find('w:b', namespace) if old is not None else None
        was_bold = old_bold is not None and old_bold.get(tag('w', 'val'), '1') not in ['0', 'false', 'off']
        if old is not None:
            run.remove(old)
        properties = deepcopy(official_style_map['1'].find('w:rPr', namespace))
        if was_bold:
            etree.SubElement(properties, tag('w', 'b'))
        run.insert(0, properties)
package['word/styles.xml'] = etree.tostring(styles_root, xml_declaration=True, encoding='UTF-8', standalone=True)

package['word/document.xml'] = etree.tostring(root, xml_declaration=True, encoding='UTF-8', standalone=True)
package['word/_rels/document.xml.rels'] = etree.tostring(relationship_root, xml_declaration=True, encoding='UTF-8', standalone=True)
with zipfile.ZipFile(output, 'w', compression=zipfile.ZIP_DEFLATED) as target:
    for name, payload in package.items():
        target.writestr(name, payload)
(work_directory / 'edit-log.json').write_text(json.dumps(edit_log, ensure_ascii=False, indent=2))
(work_directory / 'headings.json').write_text(json.dumps([{'title': text(element), 'style': style, 'anchor': anchor} for element, style, anchor in heading_elements], ensure_ascii=False, indent=2))
print(json.dumps({'output': str(output.relative_to(repository)), 'headings': len(heading_elements), 'rewritten_paragraphs': len(edit_log), 'new_sections': len(additions['sections']), 'figures': len(image_locations) + 3}, ensure_ascii=False))
