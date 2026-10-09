from copy import deepcopy
from pathlib import Path
import hashlib
import json
import zipfile

from lxml import etree as E


WORK = Path(__file__).resolve().parent
REPO = WORK.parent.parent
ORIGINAL = REPO / 'deliverables/research/aris-report-current-20261009/CACR2026EA16XZ-作品设计报告-匿名版.docx'
BASE = WORK / 'base-20261009.docx'
OUTPUT = WORK / 'CACR2026EA16XZ-作品设计报告-弱均值补充候选版.docx'
EXPECTED_SHA256 = '4c6ef7de4cfa681dd3550ec570d9a96b248e1a62885fccbdb4f0f6ea4421a7ca'
NS = {'w': 'http://schemas.openxmlformats.org/wordprocessingml/2006/main',
      'w14': 'http://schemas.microsoft.com/office/word/2010/wordml',
      'm': 'http://schemas.openxmlformats.org/officeDocument/2006/math'}


def sha256(data):
    return hashlib.sha256(data).hexdigest()


def text(paragraph):
    return ''.join(paragraph.xpath('.//w:t/text()', namespaces=NS))


def tag(prefix, name):
    return '{' + NS[prefix] + '}' + name


assert sha256(ORIGINAL.read_bytes()) == EXPECTED_SHA256
if not BASE.exists():
    BASE.write_bytes(ORIGINAL.read_bytes())
assert sha256(BASE.read_bytes()) == EXPECTED_SHA256
changes = []
with zipfile.ZipFile(BASE) as source:
    root = E.fromstring(source.read('word/document.xml'))
    body = root.find('w:body', NS)
    original_parts = {name: sha256(source.read(name)) for name in source.namelist()}
    feature_paths = {'tables': './/w:tbl', 'native_math': './/m:oMath',
                     'drawings': './/w:drawing', 'sections': './/w:sectPr'}
    features = {name: [sha256(E.tostring(node)) for node in root.findall(path, NS)]
                for name, path in feature_paths.items()}
    assert {name: len(values) for name, values in features.items()} == {
        'tables': 22, 'native_math': 62, 'drawings': 18, 'sections': 4}
    original_paragraphs = [(paragraph, sha256(E.tostring(paragraph)), text(paragraph))
                           for paragraph in body.findall('w:p', NS)]
    original_positions = {paragraph: number for number, (paragraph, _, _) in enumerate(original_paragraphs, 1)}
    modified_original = set()
    added_or_modified = set()
    ids = set(root.xpath('.//w:p/@w14:paraId', namespaces=NS))
    next_id = 0xCA150001

    def locate(prefix, exact=False):
        matches = [paragraph for paragraph in body.findall('w:p', NS)
                   if (text(paragraph) == prefix if exact else text(paragraph).startswith(prefix))]
        assert len(matches) == 1, (prefix, len(matches))
        return matches[0]

    def plain(value, template, keep_id=False):
        global next_id
        paragraph = deepcopy(template)
        if not keep_id:
            paragraph.attrib.pop(tag('w14', 'textId'), None)
            while f'{next_id:08X}' in ids:
                next_id += 1
            paragraph.set(tag('w14', 'paraId'), f'{next_id:08X}')
            ids.add(f'{next_id:08X}')
            next_id += 1
        run_properties = paragraph.find('w:r/w:rPr', NS)
        run_properties = deepcopy(run_properties) if run_properties is not None else None
        for child in list(paragraph):
            if child.tag != tag('w', 'pPr'):
                paragraph.remove(child)
        run = E.SubElement(paragraph, tag('w', 'r'))
        if run_properties is not None:
            run.append(run_properties)
        node = E.SubElement(run, tag('w', 't'))
        node.set('{http://www.w3.org/XML/1998/namespace}space', 'preserve')
        node.text = value
        return paragraph

    def replace(prefix, value, slot, exact=False):
        old = locate(prefix, exact)
        assert not old.findall('.//m:oMath', NS) and not old.findall('.//w:drawing', NS)
        position = original_positions[old]
        paragraph = plain(value, old, keep_id=True)
        body.replace(old, paragraph)
        modified_original.add(old)
        added_or_modified.add(paragraph)
        changes.append({'slot': slot, 'base_direct_paragraph_1_based': position,
                        'paragraph_id': paragraph.get(tag('w14', 'paraId')),
                        'before': text(old), 'after': value})

    replace('2026 年 10 月 9 日', '2026 年 10 月 10 日', 'cover_date', exact=True)
    value = ('精确枚举消除的是给定交换空间中的抽样误差，并不会自动消除数据产生过程的偏差。'
             '式（2-7）的有效性仍需交换依据与无后效条件。'
             '本报告历史bootstrap探索区间采用运行对独立同分布模型；新设计型均值区间另有前提，见第4.4节。'
             '程序核查声明与记录自洽，不能证明真实条件成立。')
    replace('精确枚举消除的是给定交换空间中的抽样误差', value, '2.4_historical_bootstrap_scope')

    paragraph = locate('分析模块先判断记录是否完整')
    old_clause = '图3.4给出了资格检查与结果输出的关系。'
    assert text(paragraph).count(old_clause) == 1
    value = text(paragraph).replace(old_clause,
        '此处资格限于可核查结构及声明，不能认证均值区间所需的反事实条件。' + old_clause, 1)
    replace('分析模块先判断记录是否完整', value, '3.5_qualification_boundary')

    paragraph = locate('零假设要求：给定交换轨道时')
    before = text(paragraph)
    old_clause = '在独立等概率对内交换及无后效条件成立时，包含等值的完整随机化概率具有离散检验的错误控制性质。'
    new_clause = ('对真实事前AB/BA运行，这须由尖锐零假设以及独立等概率赋值、无携带和干扰等前提支持。'
                  '包含等值的完整随机化概率在这些条件下具有离散检验的错误控制性质。')
    assert before.count(old_clause) == 1
    start = before.index(old_clause)
    end = start + len(old_clause)
    offset = 0
    inserted_replacement = False
    for node in paragraph.findall('.//w:t', NS):
        value = node.text or ''
        node_start, node_end = offset, offset + len(value)
        if node_start < end and node_end > start:
            left = value[:max(0, start - node_start)]
            right = value[max(0, end - node_start):]
            node.text = left + (new_clause if not inserted_replacement else '') + right
            inserted_replacement = True
        offset = node_end
    assert text(paragraph) == before.replace(old_clause, new_clause, 1)
    modified_original.add(paragraph)
    added_or_modified.add(paragraph)
    changes.append({'slot': '4.4_sharp_null_scope', 'base_direct_paragraph_1_based': original_positions[paragraph],
                    'paragraph_id': paragraph.get(tag('w14', 'paraId')), 'before': before, 'after': text(paragraph),
                    'existing_inline_native_math_preserved': True})

    value = ('平均时间差与尖锐零假设须分别推断[13]。对事前固定匹配对，独立等概率AB/BA且无携带或干扰时，'
             '成对均值无偏、方差估计期望保守[12]，仍不保证小样本覆盖。'
             '无主导反事实方差条件可给渐近保守区间；事前真实幅度上界可给有限覆盖[14]。'
             '自足证明另列新增技术资料，不把Wu与Ding的大层定理用于每层两时段。'
             '现有4—20对尚无渐近误差界；观测最大值和超时不能替代反事实界。'
             '等价还需预定容许界及区间严格内含。')
    anchor = locate('本作品以共同符号模型检查这一边界')
    inserted = plain(value, anchor)
    anchor.addnext(inserted)
    added_or_modified.add(inserted)
    changes.append({'slot': '4.4_conditional_mean_theory', 'inserted_after_base_prefix': '本作品以共同符号模型检查这一边界',
                    'paragraph_id': inserted.get(tag('w14', 'paraId')), 'characters': len(value), 'added': value})

    value = ('实质等价须预定对象、容许界及有效区间；未检出、低自相关或标签枚举均不构成证明。'
             '新均值路线仍缺真实前提与实现核验，R04仍部分签收。')
    replace('研究实质等价需事先规定估计对象', value, '7.2_conditional_mean_readiness')

    paragraph = locate('复现一致性关注同一材料和规则能否得到相同输出')
    before = text(paragraph)
    old_xml_sha256 = sha256(E.tostring(paragraph))
    properties = paragraph.find('w:pPr', NS)
    assert properties is not None
    keep_next = properties.find('w:keepNext', NS)
    if keep_next is None:
        keep_next = E.SubElement(properties, tag('w', 'keepNext'))
    keep_next.set(tag('w', 'val'), '1')
    assert text(paragraph) == before
    modified_original.add(paragraph)
    added_or_modified.add(paragraph)
    changes.append({'slot': '4.5_layout_only_keep_intro_with_formula',
                    'base_direct_paragraph_1_based': original_positions[paragraph],
                    'paragraph_id': paragraph.get(tag('w14', 'paraId')),
                    'before': before, 'after': text(paragraph), 'layout_only': True,
                    'old_paragraph_xml_sha256': old_xml_sha256,
                    'new_paragraph_xml_sha256': sha256(E.tostring(paragraph)),
                    'only_change': 'w:pPr/w:keepNext val=1',
                    'authorization': 'parent_explicitly_approved_P206_layout_only'})

    references = [
        '[12] Imai K. Variance identification and efficiency analysis in randomized experiments under the matched-pair design. Statistics in Medicine, 2008, 27(24):4857–4873. DOI:10.1002/sim.3337.',
        '[13] Wu J, Ding P. Randomization Tests for Weak Null Hypotheses in Randomized Experiments. Journal of the American Statistical Association, 2021, 116(536):1898–1913. DOI:10.1080/01621459.2020.1750415.',
        '[14] Hoeffding W. Probability Inequalities for Sums of Bounded Random Variables. Journal of the American Statistical Association, 1963, 58(301):13–30. DOI:10.1080/01621459.1963.10500830.',
    ]
    anchor = locate('[11] Schneider M, et al.')
    template = anchor
    for value in references:
        inserted = plain(value, template)
        anchor.addnext(inserted)
        anchor = inserted
        added_or_modified.add(inserted)
        changes.append({'slot': 'new_reference', 'paragraph_id': inserted.get(tag('w14', 'paraId')), 'added': value})

    for name, path in feature_paths.items():
        assert [sha256(E.tostring(node)) for node in root.findall(path, NS)] == features[name], name
    expected_unmodified = [digest for paragraph, digest, _ in original_paragraphs if paragraph not in modified_original]
    actual_unmodified = [sha256(E.tostring(paragraph)) for paragraph in body.findall('w:p', NS)
                         if paragraph not in added_or_modified]
    assert actual_unmodified == expected_unmodified
    unmodified_checked = len(expected_unmodified)
    payload = E.tostring(root, xml_declaration=True, encoding='UTF-8', standalone=True)
    with zipfile.ZipFile(OUTPUT, 'w', compression=zipfile.ZIP_DEFLATED) as output:
        for info in source.infolist():
            output.writestr(info, payload if info.filename == 'word/document.xml' else source.read(info.filename))
    with zipfile.ZipFile(OUTPUT) as output:
        changed_parts = [name for name in output.namelist() if sha256(output.read(name)) != original_parts[name]]
    assert changed_parts == ['word/document.xml']
    assert sha256(ORIGINAL.read_bytes()) == EXPECTED_SHA256
    (WORK / 'authoring-edits.json').write_text(json.dumps(changes, ensure_ascii=False, indent=2) + '\n')
    proof = {'source_path': str(ORIGINAL), 'source_sha256': EXPECTED_SHA256,
             'candidate_path': str(OUTPUT), 'candidate_before_toc_sha256': sha256(OUTPUT.read_bytes()),
             'changed_parts_before_toc': changed_parts,
             'all_original_tables_preserved': 22, 'all_original_native_math_preserved': 62,
             'all_original_drawings_preserved': 18, 'all_original_sections_preserved': 4,
             'unmodified_original_paragraphs_checked_in_order': unmodified_checked,
             'new_theory_is_conditional': True, 'R04_remains_partial': True,
             'new_cpu_execution_claims': 0, 'old_archive_contains_new_proof_claims': 0,
             'status': 'candidate_before_render_review'}
    (WORK / 'initial-structure.json').write_text(json.dumps(proof, ensure_ascii=False, indent=2) + '\n')
    print(json.dumps(proof, ensure_ascii=False))
