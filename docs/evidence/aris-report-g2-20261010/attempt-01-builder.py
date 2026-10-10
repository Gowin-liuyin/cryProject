from copy import deepcopy
from pathlib import Path
import hashlib
import json
import zipfile

from lxml import etree


WORK = Path(__file__).resolve().parent
REPO = WORK.parent.parent
ORIGINAL = REPO / 'deliverables/research/aris-report-weak-mean-20261010/CACR2026EA16XZ-作品设计报告-匿名版.docx'
BASE = WORK / 'base-47-page-20261010.docx'
OUTPUT = WORK / 'CACR2026EA16XZ-作品设计报告-G2补充候选版.docx'
FIGURE = REPO / 'docs/research/aris-frequency-window-20261010/figures/fig-g2-window-qualification.png'
EXPECTED_SHA256 = '9a2b7e92cebc8dc7b4aca677728a7ebb5d2b29c90b265e82d14b926bdb360c3a'
IMAGE_PART = 'word/media/figure-g2-20261010.png'
G2_HEADING = '5.9　单次普通参考负载的窗口观察与恢复'
G2_BOOKMARK = 'rw_heading_g2_20261010'
NS = {
    'w': 'http://schemas.openxmlformats.org/wordprocessingml/2006/main',
    'w14': 'http://schemas.microsoft.com/office/word/2010/wordml',
    'm': 'http://schemas.openxmlformats.org/officeDocument/2006/math',
    'r': 'http://schemas.openxmlformats.org/officeDocument/2006/relationships',
    'a': 'http://schemas.openxmlformats.org/drawingml/2006/main',
    'wp': 'http://schemas.openxmlformats.org/drawingml/2006/wordprocessingDrawing',
    'pic': 'http://schemas.openxmlformats.org/drawingml/2006/picture',
    'rel': 'http://schemas.openxmlformats.org/package/2006/relationships',
}


def sha256(payload):
    return hashlib.sha256(payload).hexdigest()


def xml_hash(element):
    return sha256(etree.tostring(element))


def text(element):
    return ''.join(element.xpath('.//w:t/text()', namespaces=NS))


def tag(prefix, name):
    return '{' + NS[prefix] + '}' + name


def math_run(value, plain=False):
    run = etree.Element(tag('m', 'r'))
    if plain:
        properties = etree.SubElement(run, tag('m', 'rPr'))
        etree.SubElement(properties, tag('m', 'sty')).set(tag('m', 'val'), 'p')
    etree.SubElement(run, tag('m', 't')).text = value
    return run


def math_subsup(base, subscript, superscript):
    element = etree.Element(tag('m', 'sSubSup'))
    etree.SubElement(element, tag('m', 'e')).append(math_run(base))
    etree.SubElement(element, tag('m', 'sub')).append(math_run(subscript, plain=True))
    etree.SubElement(element, tag('m', 'sup')).append(math_run(superscript, plain=True))
    return element


def math_fraction(numerator, denominator):
    element = etree.Element(tag('m', 'f'))
    properties = etree.SubElement(element, tag('m', 'fPr'))
    etree.SubElement(properties, tag('m', 'type')).set(tag('m', 'val'), 'bar')
    etree.SubElement(element, tag('m', 'num')).append(math_run(numerator))
    etree.SubElement(element, tag('m', 'den')).append(math_run(denominator))
    return element


def main():
    assert sha256(ORIGINAL.read_bytes()) == EXPECTED_SHA256
    if not BASE.exists():
        BASE.write_bytes(ORIGINAL.read_bytes())
    assert sha256(BASE.read_bytes()) == EXPECTED_SHA256
    figure_bytes = FIGURE.read_bytes()
    assert figure_bytes.startswith(b'\x89PNG\r\n\x1a\n')
    assert (int.from_bytes(figure_bytes[16:20], 'big'),
            int.from_bytes(figure_bytes[20:24], 'big')) == (2100, 1380)
    changes = []
    with zipfile.ZipFile(BASE) as source:
        original_parts = {name: sha256(source.read(name)) for name in source.namelist()}
        assert IMAGE_PART not in original_parts
        root = etree.fromstring(source.read('word/document.xml'))
        body = root.find('w:body', NS)
        original_paragraphs = list(body.findall('w:p', NS))
        original_positions = {paragraph: number for number, paragraph in enumerate(original_paragraphs, 1)}
        original_paragraph_hashes = {paragraph: xml_hash(paragraph) for paragraph in original_paragraphs}
        original_tables = list(root.findall('.//w:tbl', NS))
        original_abstract_table_text = text(original_tables[0])
        original_features = {
            'tables': [xml_hash(element) for element in original_tables],
            'native_math': [xml_hash(element) for element in root.findall('.//m:oMath', NS)],
            'drawings': [xml_hash(element) for element in root.findall('.//w:drawing', NS)],
            'sections': [xml_hash(element) for element in root.findall('.//w:sectPr', NS)],
        }
        assert len(original_paragraphs) == 349
        assert {name: len(values) for name, values in original_features.items()} == {
            'tables': 22, 'native_math': 62, 'drawings': 18, 'sections': 4,
        }
        used_ids = set(root.xpath('.//w:p/@w14:paraId', namespaces=NS))
        next_id = 0xCA160001
        added_direct_paragraphs = set()
        modified_original_paragraphs = set()
        new_math_nodes = []

        def new_id(paragraph):
            nonlocal next_id
            paragraph.attrib.pop(tag('w14', 'textId'), None)
            while f'{next_id:08X}' in used_ids:
                next_id += 1
            paragraph.set(tag('w14', 'paraId'), f'{next_id:08X}')
            used_ids.add(f'{next_id:08X}')
            next_id += 1

        def plain(value, template, keep_id=False):
            paragraph = deepcopy(template)
            if not keep_id or paragraph.get(tag('w14', 'paraId')) is None:
                new_id(paragraph)
            properties = paragraph.find('w:r/w:rPr', NS)
            properties = deepcopy(properties) if properties is not None else None
            for child in list(paragraph):
                if child.tag != tag('w', 'pPr'):
                    paragraph.remove(child)
            run = etree.SubElement(paragraph, tag('w', 'r'))
            if properties is not None:
                run.append(properties)
            value_node = etree.SubElement(run, tag('w', 't'))
            value_node.set('{http://www.w3.org/XML/1998/namespace}space', 'preserve')
            value_node.text = value
            return paragraph

        def record_added(paragraph, slot, **details):
            changes.append({'slot': slot, 'paragraph_id': paragraph.get(tag('w14', 'paraId')),
                            'added': text(paragraph), **details})
            added_direct_paragraphs.add(paragraph)

        def insert_after(anchor, value, slot, template=None):
            paragraph = plain(value, template if template is not None else anchor)
            anchor.addnext(paragraph)
            record_added(paragraph, slot,
                         inserted_after_base_direct_paragraph_1_based=original_positions.get(anchor))
            return paragraph

        def replace_original(number, value, slot):
            old = original_paragraphs[number - 1]
            assert not old.findall('.//m:oMath', NS) and not old.findall('.//w:drawing', NS)
            replacement = plain(value, old, keep_id=True)
            body.replace(old, replacement)
            modified_original_paragraphs.add(old)
            added_direct_paragraphs.add(replacement)
            changes.append({'slot': slot, 'base_direct_paragraph_1_based': number,
                            'paragraph_id': replacement.get(tag('w14', 'paraId')),
                            'before': text(old), 'after': value,
                            'old_xml_sha256': original_paragraph_hashes[old],
                            'new_xml_sha256': xml_hash(replacement)})

        body_template = original_paragraphs[287]
        abstract = original_tables[0].findall('w:tr', NS)[4].find('w:tc', NS).findall('w:p', NS)[1]
        assert abstract.get(tag('w14', 'paraId')) == 'CA140001'
        abstract_before = text(abstract)
        abstract_run_hashes = [xml_hash(run) for run in abstract.findall('w:r', NS)]
        abstract_addition = ('G2单次普通参考进程保存126528次调用，200个主窗口通过工程规则，'
                             '纯主平均窗口几何覆盖99.4948%；注册取消与可见恢复另核对，R02/R04仍部分签收。')
        abstract_run = deepcopy(abstract.findall('w:r', NS)[-1])
        for child in list(abstract_run):
            if child.tag != tag('w', 'rPr'):
                abstract_run.remove(child)
        etree.SubElement(abstract_run, tag('w', 't')).text = abstract_addition
        abstract.append(abstract_run)
        assert [xml_hash(run) for run in abstract.findall('w:r', NS)[:-1]] == abstract_run_hashes
        assert text(abstract) == abstract_before + abstract_addition
        changes.append({'slot': 'abstract_g2_append', 'table_1_based': 1, 'row_1_based': 5,
                        'cell_1_based': 1, 'cell_paragraph_1_based': 2,
                        'paragraph_id': 'CA140001', 'before': abstract_before,
                        'after': text(abstract), 'added': abstract_addition,
                        'all_original_abstract_run_hashes_preserved': True})

        assert text(original_paragraphs[216]).startswith('CPU 型号中的')
        insert_after(original_paragraphs[216],
                     '表5.1记录既有KVM材料的环境；2026年10月10日G2裸金属普通参考窗口另按第5.9节的机器、产物与观测范围解释。',
                     '5.1_environment_scope', body_template)

        chapter_end = body.xpath('./w:bookmarkEnd[@w:id="88"]', namespaces=NS)
        previous_section_end = body.xpath('./w:bookmarkEnd[@w:id="87"]', namespaces=NS)
        assert len(chapter_end) == len(previous_section_end) == 1
        assert previous_section_end[0].getnext() is chapter_end[0]
        assert G2_BOOKMARK not in root.xpath('.//w:bookmarkStart/@w:name', namespaces=NS)
        bookmark_id = str(max(map(int, root.xpath('.//w:bookmarkStart/@w:id', namespaces=NS))) + 1)
        bookmark_start = etree.Element(tag('w', 'bookmarkStart'))
        bookmark_start.set(tag('w', 'id'), bookmark_id)
        bookmark_start.set(tag('w', 'name'), G2_BOOKMARK)
        chapter_end[0].addprevious(bookmark_start)

        def section_paragraph(value, slot, template=None, new_page=False):
            paragraph = plain(value, template if template is not None else body_template)
            if new_page:
                properties = paragraph.find('w:pPr', NS)
                etree.SubElement(properties, tag('w', 'pageBreakBefore')).set(tag('w', 'val'), '1')
            chapter_end[0].addprevious(paragraph)
            record_added(paragraph, slot)
            return paragraph

        assert text(original_paragraphs[277]) == '5.8　同机人工机制的防护前后复测'
        section_paragraph(G2_HEADING, '5.9_heading', original_paragraphs[277], new_page=True)
        section_paragraph(
            '2026年10月10日，在Ryzen 9 9950X、Ubuntu 24.04.4和Linux 6.17/x86_64裸金属上，'
            '正常与运行中注册取消路径各执行一次，无补跑。仅临时分区CPU2/18，唯一普通reference进程固定CPU2，'
            '八个有效密文循环；1秒预热后以4秒为主观察目标。仅四个min/max请求4300000 kHz，'
            '不改boost、EPP、governor或IRQ。', '5.9_execution_scope')
        section_paragraph(
            'Linux固定源码说明APERF/MPERF比须结合参考性能标尺解释[15]；本次4300 MHz标尺来自另存的固件映射。'
            '令ΔA为相邻APERF增量，MPERF在APERF前后的读数为M⁻、M⁺，prev、next表示前后快照。'
            '在同一计数时期、单调且无回绕或重置条件下，'
            '读取对齐边界为：', '5.9_counter_conditions')

        formula_template = original_paragraphs[239]
        assert text(formula_template) == '(5-1)'

        def equation(math_nodes, label, slot):
            paragraph = plain('', formula_template)
            for child in list(paragraph):
                if child.tag != tag('w', 'pPr'):
                    paragraph.remove(child)
            tab_run = etree.SubElement(paragraph, tag('w', 'r'))
            etree.SubElement(tab_run, tag('w', 'tab'))
            math_node = etree.SubElement(paragraph, tag('m', 'oMath'))
            for node in math_nodes:
                math_node.append(node)
            label_run = deepcopy(formula_template.findall('w:r', NS)[-1])
            label_texts = label_run.findall('w:t', NS)
            assert len(label_texts) == 1
            label_texts[0].text = label
            paragraph.append(label_run)
            chapter_end[0].addprevious(paragraph)
            new_math_nodes.append(math_node)
            record_added(paragraph, slot, native_omml=True,
                         math_text=''.join(math_node.xpath('.//m:t/text()', namespaces=NS)))

        equation([
            math_run('L='), math_subsup('M', 'next', '−'), math_run('−'),
            math_subsup('M', 'prev', '+'), math_run(',   H='),
            math_subsup('M', 'next', '+'), math_run('−'), math_subsup('M', 'prev', '−'),
        ], '(5-5)', '5.9_formula_L_H')
        interval = etree.Element(tag('m', 'd'))
        delimiter_properties = etree.SubElement(interval, tag('m', 'dPr'))
        etree.SubElement(delimiter_properties, tag('m', 'begChr')).set(tag('m', 'val'), '[')
        etree.SubElement(delimiter_properties, tag('m', 'endChr')).set(tag('m', 'val'), ']')
        interval_content = etree.SubElement(interval, tag('m', 'e'))
        interval_content.append(math_fraction('4300ΔA', 'H'))
        interval_content.append(math_run(', '))
        interval_content.append(math_fraction('4300ΔA', 'L'))
        equation([math_run('I='), interval, math_run(' MHz,   L>0', plain=True)],
                 '(5-6)', '5.9_formula_interval')
        section_paragraph(
            '对应两次APERF读点的MPERF增量位于[L,H]；正分母取倒数给出式（5-6）。'
            '区间只处理读取错位，不是置信区间或完整物理误差界，解析自洽不认证上述条件。冻结C11分析以整数判定'
            '100ΔA≥99H且100ΔA≤101L，并要求CPU2保守线程CPU时间／RAW间隔代理至少80%、三读跨度至多1 ms、相邻快照至多40 ms。'
            '全部实际主pair和普通长尾保留；调用、快照、读钟及读取失败台账均为0。', '5.9_engineering_rules')
        section_paragraph('表5.11　G2正常进程的完整计数与几何覆盖',
                          '5.9_table_caption', original_paragraphs[215])

        table_source = original_tables[7]
        assert [int(element.get(tag('w', 'w'))) for element in table_source.findall('w:tblGrid/w:gridCol', NS)] == [2948, 6009]
        table = deepcopy(table_source)
        table_rows = table_source.findall('w:tr', NS)
        for row in list(table.findall('w:tr', NS)):
            table.remove(row)
        data_rows = [
            ('全部／主阶段调用', '126528／101248'),
            ('快照／检查点', '251／1977'),
            ('主观察墙钟', '4002203951 ns'),
            ('实际主pair／全部规则通过', '200／200；首个跨界pair 1个仍参加判定'),
            ('纯主支持窗口', '199个；跨界pair不计纯主覆盖'),
            ('纯主几何覆盖', '3981985286／4002203951 ns，99.4948%'),
            ('纯几何区间内主调用', '100736／101248'),
            ('首／尾／内部缺口', '20170432／13224／35009 ns'),
        ]
        for row_number, values in enumerate([('指标', '正常进程原值')] + data_rows):
            row_template = table_rows[0] if row_number == 0 else (
                table_rows[-1] if row_number == len(data_rows) else table_rows[1])
            row = deepcopy(row_template)
            row_properties = row.find('w:trPr', NS)
            height = row_properties.find('w:trHeight', NS)
            height.set(tag('w', 'hRule'), 'atLeast')
            if row_properties.find('w:cantSplit', NS) is None:
                etree.SubElement(row_properties, tag('w', 'cantSplit'))
            for repeated_header in list(row_properties.findall('w:tblHeader', NS)):
                row_properties.remove(repeated_header)
            if row_number == 0:
                etree.SubElement(row_properties, tag('w', 'tblHeader')).set(tag('w', 'val'), '1')
            for cell_number, cell in enumerate(row.findall('w:tc', NS)):
                old_cell_paragraph = cell.find('w:p', NS)
                new_cell_paragraph = plain(values[cell_number], old_cell_paragraph)
                if row_number > 0:
                    properties = new_cell_paragraph.find('w:pPr', NS)
                    for keep_next in list(properties.findall('w:keepNext', NS)):
                        properties.remove(keep_next)
                for paragraph in list(cell.findall('w:p', NS)):
                    cell.remove(paragraph)
                cell.append(new_cell_paragraph)
            table.append(row)
        chapter_end[0].addprevious(table)
        changes.append({'slot': '5.9_table', 'new_table_label': '5.11',
                        'source_table_1_based': 8, 'column_widths_twips': [2948, 6009],
                        'source_font_points': 11, 'data_rows': data_rows,
                        'new_table_xml_sha256': xml_hash(table),
                        'paragraph_ids': table.xpath('.//w:p/@w14:paraId', namespaces=NS),
                        'repeat_header': True, 'all_rows_at_least_and_cant_split': True,
                        'new_body_cell_keep_next_removed': True})

        section_paragraph('图5.8保留本次全部CPU2主观察窗口，并另列纯主阶段的平均窗口几何占比。',
                          '5.9_figure_intro', new_page=True)
        picture = deepcopy(original_paragraphs[97])
        assert picture.find('.//wp:inline', NS) is not None
        new_id(picture)
        picture_width_emu = 5688000
        picture_height_emu = picture_width_emu * 1380 // 2100
        extent = picture.find('.//wp:extent', NS)
        extent.set('cx', str(picture_width_emu))
        extent.set('cy', str(picture_height_emu))
        transform_extent = picture.find('.//a:xfrm/a:ext', NS)
        transform_extent.set('cx', str(picture_width_emu))
        transform_extent.set('cy', str(picture_height_emu))
        drawing_id_start = max(map(int, root.xpath('.//wp:docPr/@id|.//pic:cNvPr/@id', namespaces=NS))) + 1
        new_drawing_id = str(drawing_id_start)
        figure_description = '一次普通参考进程的CPU2主观察窗口及纯主阶段平均窗口几何覆盖比例'
        for property_index, drawing_properties in enumerate(picture.xpath('.//wp:docPr|.//pic:cNvPr', namespaces=NS)):
            drawing_properties.set('id', str(drawing_id_start + property_index))
            drawing_properties.set('name', 'G2窗口工程观察')
            drawing_properties.set('descr', figure_description)
            if 'title' in drawing_properties.attrib:
                drawing_properties.set('title', '')
        relationships = etree.fromstring(source.read('word/_rels/document.xml.rels'))
        relationship_id = 'rId' + str(max(int(element.get('Id')[3:]) for element in relationships) + 1)
        picture.find('.//a:blip', NS).set(tag('r', 'embed'), relationship_id)
        relationship = etree.SubElement(relationships, tag('rel', 'Relationship'))
        relationship.set('Id', relationship_id)
        relationship.set('Type', NS['r'] + '/image')
        relationship.set('Target', IMAGE_PART.removeprefix('word/'))
        chapter_end[0].addprevious(picture)
        record_added(picture, '5.9_figure', image_part=IMAGE_PART,
                     image_sha256=sha256(figure_bytes), relationship_id=relationship_id,
                     docPr_id=new_drawing_id, width_emu=picture_width_emu,
                     height_emu=picture_height_emu, alt_text=figure_description)
        new_drawing = picture.find('.//w:drawing', NS)
        section_paragraph('图5.8　单次普通参考进程的窗口工程观察与几何覆盖',
                          '5.9_figure_caption', original_paragraphs[283])
        section_paragraph(
            '全部200个CPU2主pair均通过工程规则。空心标记为首个跨界pair，仍参加判定；下条仅为合计几何比例，'
            '不是点态时间线。读取对齐区间不是置信区间，平均窗口不认证区间内逐时或逐调用恒频。'
            '200窗来自一个进程，不是200次独立重复。', '5.9_figure_boundary')
        section_paragraph(
            '纯主几何分子不含首个跨界pair；与表5.11三类缺口之和精确等于分母，没有补齐或改分母。'
            'CPU18的200个context区间均为边界重叠，仅作上下文，不是第二独立样本或实际高频证据。',
            '5.9_geometry_and_context')
        section_paragraph(
            '另一路径在放行后实际约0.255407秒发起预定的注册取消，该数不是恢复耗时。controller与worker均因SIGKILL终止（记录码−9），'
            'child已回收；stdout/stderr均0字节表示测量未知，不是零调用。两路径结束独立核对87份原件及归档一致、'
            '六原PID不存在、全部32策略及global可见对象等原基线、CPU0—31归还、隔离空、自有组删除且锁释放。'
            '回读不是全程原子快照，不证明隐藏QoS或固件内部逐位复原；guard自身死亡、整机及真实磁盘故障未测试。'
            '本次仅支持窄工程观察，完整研究与R02/R04仍部分签收。', '5.9_cancel_restore_and_claim')
        bookmark_end = etree.Element(tag('w', 'bookmarkEnd'))
        bookmark_end.set(tag('w', 'id'), bookmark_id)
        chapter_end[0].addprevious(bookmark_end)

        toc = deepcopy(original_paragraphs[60])
        new_id(toc)
        toc_hyperlink = toc.find('w:hyperlink', NS)
        toc_hyperlink.set(tag('w', 'anchor'), G2_BOOKMARK)
        toc_texts = toc.findall('.//w:t', NS)
        assert len(toc_texts) == 2
        toc_texts[0].text = G2_HEADING
        toc_texts[1].text = '34'
        original_paragraphs[60].addnext(toc)
        record_added(toc, 'toc_5.9', bookmark=G2_BOOKMARK, placeholder_page=34,
                     actual_pagination_pending=True)

        assert original_paragraphs[304].get(tag('w14', 'paraId')) == 'CA140006'
        insert_after(original_paragraphs[304],
                     'G2又在指定裸金属的一次普通参考进程中保存126528次调用，200个主pair全部通过事前工程规则，'
                     '纯主平均窗口几何覆盖99.4948%；另一路径的注册取消、原件保全与可见资源恢复独立核对通过。'
                     '该观察不扩大历史防护或统计结论。', '7.1_g2_summary', body_template)
        insert_after(original_paragraphs[309],
                     'G2尚需与拟区分时间差量级相匹配的读钟精度、运行间稳定性和有效统计前提。'
                     '完整主阶段或逐调用恒频、绝对物理频率界是更强声明的边界，不能由本次平均窗口几何覆盖推出；'
                     '所需控制应由拟检验的声明和可分辨量级决定。R02/R04仍部分签收，后续仅在新科学问题和事前合同明确后推进。',
                     '7.2_g2_limits', body_template)

        old_frequency = text(original_paragraphs[337])
        old_frequency_clause = 'R02 与 R04 仍为部分签收：没有锁定频率的数据集，也没有真实密文总体的误报率或检出率。'
        assert old_frequency.count(old_frequency_clause) == 1
        revised_frequency = old_frequency.replace(
            old_frequency_clause,
            '就2026年10月8日上述记录而言，没有锁定频率的数据集，也没有真实密文总体的误报率或检出率。'
            '2026年10月10日G2另取得第5.9节所述平均窗口工程观察，不追认旧数据，也不构成整段或逐调用恒频。'
            'R02与R04仍为部分签收。', 1)
        replace_original(338, revised_frequency, 'appendix_old_Ryzen_frequency_time_scope')
        old_figure_scope = text(original_paragraphs[338])
        old_figure_clause = '图源以独立 PowerPoint 文件交付，各数据图保留可编辑图表和工作簿，结构图保留原生图形与文字。'
        assert old_figure_scope.count(old_figure_clause) == 1
        revised_figure_scope = old_figure_scope.replace(
            old_figure_clause,
            '原有图源以独立 PowerPoint 文件交付，原有数据图保留可编辑图表和工作簿，结构图保留原生图形与文字。'
            '新增G2图以PNG和PDF单列，绘图源码另存作者归档，不称可编辑PowerPoint图表。', 1)
        replace_original(339, revised_figure_scope, 'appendix_original_figure_scope')
        assert original_paragraphs[344].get(tag('w14', 'paraId')) == 'CA14002E'
        insert_after(original_paragraphs[344],
                     'G2新增材料与旧记录分别封存：匿名分发包的data/g2/保存逐次原值、逐窗口CSV及C摘要；'
                     'research/g2/保存固定合同、结果到主张、生命周期和科学核对；code/g2-analysis/保存冻结C11离线分析源码。'
                     'code/g2-collector/为依赖完整固定参考目录的生产者审计源，不是独立离线运行入口。'
                     'G2-M、G2-C、G2-A分别是管理、普通生产者与分析来源别名，不是Git提交号；'
                     '源码、普通产物、输入和处理结果按各自清单摘要关联。原47页稿及既有软件和研究包保持原身份。',
                     'appendix_g2_sources', body_template)
        reference = original_paragraphs[325]
        assert text(reference).startswith('[14] Hoeffding W.')
        insert_after(reference,
                     '[15] Linux kernel contributors. arch/x86/kernel/cpu/aperfmperf.c, fixed tag v6.17. '
                     'https://raw.githubusercontent.com/torvalds/linux/v6.17/arch/x86/kernel/cpu/aperfmperf.c '
                     '(accessed 2026-10-10).', 'reference_15', reference)

        settings = etree.fromstring(source.read('word/settings.xml'))
        old_settings_children = [xml_hash(element) for element in settings]
        assert settings.find('w:updateFields', NS) is None
        update_fields = etree.Element(tag('w', 'updateFields'))
        update_fields.set(tag('w', 'val'), 'true')
        settings.find('w:compat', NS).addprevious(update_fields)
        assert [xml_hash(element) for element in settings if element is not update_fields] == old_settings_children
        changes.append({'slot': 'settings_update_fields', 'part': 'word/settings.xml',
                        'added': 'w:updateFields w:val=true',
                        'all_original_settings_children_preserved': True,
                        'cached_page_numbers_finalized_separately': True})

        actual_tables = [element for element in root.findall('.//w:tbl', NS) if element is not table]
        assert len(actual_tables) == 22
        assert [xml_hash(element) for element in actual_tables[1:]] == original_features['tables'][1:]
        assert original_abstract_table_text.count(abstract_before) == 1
        assert text(actual_tables[0]) == original_abstract_table_text.replace(
            abstract_before, abstract_before + abstract_addition, 1)
        for name, path, excluded in [
            ('native_math', './/m:oMath', set(new_math_nodes)),
            ('drawings', './/w:drawing', {new_drawing}),
            ('sections', './/w:sectPr', set()),
        ]:
            actual_hashes = [xml_hash(element) for element in root.findall(path, NS) if element not in excluded]
            assert actual_hashes == original_features[name], name
        expected_unchanged = [original_paragraph_hashes[paragraph] for paragraph in original_paragraphs
                              if paragraph not in modified_original_paragraphs]
        actual_unchanged = [xml_hash(paragraph) for paragraph in body.findall('w:p', NS)
                            if paragraph not in added_direct_paragraphs]
        assert expected_unchanged == actual_unchanged
        original_relationships = etree.fromstring(source.read('word/_rels/document.xml.rels'))
        assert [xml_hash(element) for element in list(relationships)[:-1]] == [
            xml_hash(element) for element in original_relationships]
        assert len(relationships) == len(original_relationships) + 1
        content_types = etree.fromstring(source.read('[Content_Types].xml'))
        assert any(element.get('Extension') == 'png' and element.get('ContentType') == 'image/png'
                   for element in content_types)
        toc_count = sum(paragraph.xpath('./w:pPr/w:pStyle/@w:val', namespaces=NS)
                        in [['RWTOC1'], ['RWTOC2']] for paragraph in body.findall('w:p', NS))
        assert toc_count == 43
        assert len(root.xpath('.//w:bookmarkStart[@w:name=$name]', namespaces=NS, name=G2_BOOKMARK)) == 1
        assert len(root.xpath('.//w:bookmarkEnd[@w:id=$value]', namespaces=NS, value=bookmark_id)) == 1
        all_paragraph_ids = root.xpath('.//w:p/@w14:paraId', namespaces=NS)
        assert len(all_paragraph_ids) == len(set(all_paragraph_ids))
        replacements = {
            'word/document.xml': etree.tostring(root, xml_declaration=True, encoding='UTF-8', standalone=True),
            'word/_rels/document.xml.rels': etree.tostring(relationships, xml_declaration=True,
                                                         encoding='UTF-8', standalone=True),
            'word/settings.xml': etree.tostring(settings, xml_declaration=True, encoding='UTF-8', standalone=True),
        }
        with zipfile.ZipFile(OUTPUT, 'w', compression=zipfile.ZIP_DEFLATED) as output:
            for info in source.infolist():
                output.writestr(info, replacements.get(info.filename, source.read(info.filename)))
            output.writestr(IMAGE_PART, figure_bytes)
        with zipfile.ZipFile(OUTPUT) as output:
            changed_parts = [name for name in source.namelist()
                             if sha256(output.read(name)) != original_parts[name]]
            new_parts = [name for name in output.namelist() if name not in original_parts]
            untouched_parts = [name for name in source.namelist() if name not in replacements]
            assert sorted(changed_parts) == sorted(replacements)
            assert new_parts == [IMAGE_PART]
            assert all(sha256(output.read(name)) == original_parts[name] for name in untouched_parts)
        assert sha256(ORIGINAL.read_bytes()) == EXPECTED_SHA256
        (WORK / 'authoring-edits.json').write_text(json.dumps(changes, ensure_ascii=False, indent=2) + '\n')
        proof = {
            'source_path': str(ORIGINAL), 'source_sha256': EXPECTED_SHA256,
            'candidate_path': str(OUTPUT), 'candidate_before_toc_sha256': sha256(OUTPUT.read_bytes()),
            'source_47_page_docx_unchanged': True, 'changed_parts_before_toc': changed_parts,
            'new_package_parts': new_parts, 'untouched_package_parts_verified': len(untouched_parts),
            'all_original_native_math_preserved_in_order': 62,
            'all_original_drawings_preserved_in_order': 18,
            'all_original_sections_preserved_in_order': 4,
            'all_original_tables_except_abstract_preserved_in_order': 21,
            'original_abstract_runs_preserved': len(abstract_run_hashes),
            'original_direct_paragraphs': len(original_paragraphs),
            'modified_original_direct_paragraph_numbers': sorted(
                original_positions[paragraph] for paragraph in modified_original_paragraphs),
            'unmodified_original_direct_paragraphs_verified_in_order': len(expected_unchanged),
            'new_direct_paragraphs': len(added_direct_paragraphs) - len(modified_original_paragraphs),
            'new_native_math': 2, 'new_drawings': 1, 'new_tables': 1,
            'resulting_counts': {'tables': 23, 'native_math': 64, 'drawings': 19, 'sections': 4},
            'toc_entries': toc_count, 'new_bookmark_id': bookmark_id, 'new_bookmark': G2_BOOKMARK,
            'image_sha256': sha256(figure_bytes), 'G2_completed_processes': 1,
            'G2_all_calls': 126528, 'G2_main_calls': 101248,
            'G2_observed_main_pairs': 200, 'G2_engineering_pass_pairs': 200,
            'G2_pure_geometry_numerator_ns': 3981985286,
            'G2_main_wall_denominator_ns': 4002203951,
            'G2_geometry_percent_display': '99.4948',
            'full_main_or_per_call_constant_frequency_claim': False,
            'physical_precision_certified': False, 'independent_window_samples_claim': False,
            'R02': 'partial', 'R04': 'partial',
            'external_review_status': 'pending Codex review',
            'pagination_and_all_page_visual_review_pending': True,
            'status': 'candidate_before_render_review',
        }
        (WORK / 'initial-structure.json').write_text(json.dumps(proof, ensure_ascii=False, indent=2) + '\n')
        print(json.dumps(proof, ensure_ascii=False))


if __name__ == '__main__':
    main()
