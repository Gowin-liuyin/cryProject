from copy import deepcopy
from pathlib import Path
import argparse
import json
import re
import zipfile

from lxml import etree
from pypdf import PdfReader

from finalize_candidate import (
    BASE, EXPECTED_SHA256, NS, ORIGINAL, REPORT, WORK,
    is_toc, normalize, pagination, sha256, text, toc_entries, xml_hash,
)


IMAGE_PART = 'word/media/figure-g2-20261010.png'
EXPECTED_IMAGE_SHA256 = 'ef47cae6a8767a4090c912ad6e317334b0d059b35946d80b8d2358e87e6cb014'
FIGURE = WORK.parent.parent / 'docs/research/aris-frequency-window-20261010/figures/fig-g2-window-qualification.png'
PUBLIC_COMMITS = {'b3ba7b32773e657dd37f6f87bce82528459ad8a4',
                  'dc269651fb2567e46755cfb2a13d3875592968b5',
                  '7f4d5dc162b77c362a34a0d52949f7a3e1b16d81'}


def by_id(root, paragraph_id, direct=False):
    path = './w:body/w:p' if direct else './/w:p'
    paragraphs = root.xpath(path + '[@w14:paraId=$value]', namespaces=NS, value=paragraph_id)
    assert len(paragraphs) == 1, ('paragraph_id', paragraph_id)
    return paragraphs[0]


def privacy_scan(value, scope):
    patterns = {
        'private_host_or_account': r'(?i)nss-marker|\bnss-m\b|VM-0-17-ubuntu|Gowin-liuyin|yinhaoran0808',
        'private_absolute_path': r'(?i)/Users/|/home/|/private/|/tmp/cryproject|[A-Z]:[\\/]Users[\\/]',
        'ipv4_address': r'(?<![\d.])(?:\d{1,3}\.){3}\d{1,3}(?![\d.])',
        'email_address': r'(?i)[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}',
    }
    for name, pattern in patterns.items():
        assert re.search(pattern, value) is None, ('privacy', scope, name)
    commits = set(re.findall(r'\b[0-9a-fA-F]{40}\b', value))
    assert {commit.lower() for commit in commits} <= PUBLIC_COMMITS, ('private_commit', scope)


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--pdf', type=Path, required=True)
    parser.add_argument('--png-dir', type=Path, required=True)
    parser.add_argument('--visual-qa', type=Path)
    arguments = parser.parse_args()
    assert sha256(ORIGINAL.read_bytes()) == sha256(BASE.read_bytes()) == EXPECTED_SHA256
    changes_bytes = (WORK / 'authoring-edits.json').read_bytes()
    changes = json.loads(changes_bytes)
    slots = {row['slot']: row for row in changes}
    assert len(slots) == len(changes)
    initial = json.loads((WORK / 'initial-structure.json').read_text())
    toc_map = json.loads((WORK / 'toc-map.json').read_text())
    assert toc_map['authoring_edits_sha256'] == sha256(changes_bytes)
    assert toc_map['candidate_before_toc_sha256'] == initial['candidate_before_toc_sha256']
    assert toc_map['candidate_after_toc_sha256'] == sha256(REPORT.read_bytes())
    changed_rows = [row for row in changes if 'base_direct_paragraph_1_based' in row and not row.get('removed')]
    assert {row['base_direct_paragraph_1_based'] for row in changed_rows} == {305, 338, 339}
    removed_rows = [row for row in changes if row.get('removed')]
    assert len(removed_rows) == 1 and removed_rows[0]['base_direct_paragraph_1_based'] == 311
    assert removed_rows[0]['relocated_to'] == 'authoring_log_and_delivery_README'
    assert {row['base_direct_paragraph_1_based'] for row in changes
            if 'base_direct_paragraph_1_based' in row} == {305, 311, 338, 339}
    assert initial['removed_original_direct_paragraph_numbers'] == [311]
    assert initial['removed_editorial_note_retained_verbatim_in_authoring_log'] is True
    new_rows = [row for row in changes if 'paragraph_id' in row
                and 'base_direct_paragraph_1_based' not in row and row['slot'] != 'abstract_g2_append']
    assert len(new_rows) == 19
    new_ids = {row['paragraph_id'] for row in new_rows}
    changed_ids = {row['paragraph_id'] for row in changed_rows}
    assert len(new_ids) == 19 and not new_ids & changed_ids
    features = {}
    with zipfile.ZipFile(BASE) as source, zipfile.ZipFile(REPORT) as candidate:
        before = etree.fromstring(source.read('word/document.xml'))
        after = etree.fromstring(candidate.read('word/document.xml'))
        old_paragraphs = before.findall('./w:body/w:p', NS)
        new_paragraphs = after.findall('./w:body/w:p', NS)
        assert len(old_paragraphs) == 349 and len(new_paragraphs) == 367
        all_ids = after.xpath('.//w:p/@w14:paraId', namespaces=NS)
        assert len(all_ids) == len(set(all_ids))
        registry = {row['paragraph_id']: row for row in toc_map['registered_new_paragraphs_before_toc']}
        assert set(registry) == new_ids
        comparison_root = deepcopy(after)
        for row in new_rows:
            paragraph = by_id(after, row['paragraph_id'], direct=True)
            check = by_id(comparison_root, row['paragraph_id'], direct=True)
            if row['slot'] == 'toc_5.9':
                check.findall('.//w:t', NS)[-1].text = str(row['placeholder_page'])
            assert xml_hash(check) == registry[row['paragraph_id']]['xml_sha256'], row['slot']
            assert text(check) == row['added'], row['slot']
        for row in changed_rows:
            old = old_paragraphs[row['base_direct_paragraph_1_based'] - 1]
            paragraph = by_id(after, row['paragraph_id'], direct=True)
            assert text(old) == row['before'] and xml_hash(old) == row['old_xml_sha256']
            assert text(paragraph) == row['after'] and xml_hash(paragraph) == row['new_xml_sha256']
        removed_note = old_paragraphs[310]
        assert text(removed_note) == removed_rows[0]['before']
        assert xml_hash(removed_note) == removed_rows[0]['old_xml_sha256']
        assert all(text(paragraph) != removed_rows[0]['before'] for paragraph in new_paragraphs)
        assert all(xml_hash(paragraph) != removed_rows[0]['old_xml_sha256'] for paragraph in new_paragraphs)
        expected_unchanged = [xml_hash(paragraph) for number, paragraph in enumerate(old_paragraphs, 1)
                              if number not in {305, 311, 338, 339} and not is_toc(paragraph)]
        actual_unchanged = [xml_hash(paragraph) for paragraph in new_paragraphs
                            if paragraph.get('{' + NS['w14'] + '}paraId') not in new_ids | changed_ids
                            and not is_toc(paragraph)]
        assert expected_unchanged == actual_unchanged
        assert len(expected_unchanged) + 42 == initial['unmodified_original_direct_paragraphs_verified_in_order'] == 345
        old_toc = [paragraph for paragraph in old_paragraphs if is_toc(paragraph)]
        unchanged_toc = [paragraph for paragraph in new_paragraphs
                         if is_toc(paragraph) and paragraph.get('{' + NS['w14'] + '}paraId') not in new_ids]
        assert len(old_toc) == len(unchanged_toc) == 42
        expected_root = deepcopy(before)
        expected_toc = [paragraph for paragraph in expected_root.findall('./w:body/w:p', NS) if is_toc(paragraph)]
        for expected, paragraph in zip(expected_toc, unchanged_toc):
            expected.findall('.//w:t', NS)[-1].text = paragraph.findall('.//w:t', NS)[-1].text
            assert xml_hash(expected) == xml_hash(paragraph)

        old_tables = before.findall('.//w:tbl', NS)
        all_tables = after.findall('.//w:tbl', NS)
        assert len(old_tables) == 22 and len(all_tables) == 23
        table_ids = slots['5.9_table']['paragraph_ids']
        table_matches = [table for table in all_tables
                         if table.xpath('.//w:p/@w14:paraId', namespaces=NS) == table_ids]
        assert len(table_matches) == 1
        table = table_matches[0]
        assert xml_hash(table) == slots['5.9_table']['new_table_xml_sha256']
        preserved_tables = [element for element in all_tables if element is not table]
        assert [xml_hash(element) for element in old_tables[1:]] == [
            xml_hash(element) for element in preserved_tables[1:]]
        expected_abstract_table = expected_root.findall('.//w:tbl', NS)[0]
        old_abstract = by_id(expected_abstract_table, 'CA140001')
        new_abstract = by_id(preserved_tables[0], 'CA140001')
        old_abstract_children = list(old_abstract)
        assert len(new_abstract) == len(old_abstract) + 1
        assert [xml_hash(element) for element in list(new_abstract)[:-1]] == [
            xml_hash(element) for element in old_abstract_children]
        appended_run = new_abstract[-1]
        assert appended_run.tag == '{' + NS['w'] + '}r'
        assert text(appended_run) == slots['abstract_g2_append']['added']
        old_abstract.append(deepcopy(appended_run))
        assert xml_hash(expected_abstract_table) == xml_hash(preserved_tables[0])
        features['tables'] = {'original_count': 22, 'unchanged_ordered_tables': 21,
                              'abstract_append_only_verified': True, 'new_count': 1, 'final_count': 23}
        rows = table.findall('w:tr', NS)
        assert len(rows) == 9
        assert slots['5.9_table']['data_rows'] == [
            ['全部／主阶段调用', '126528／101248'],
            ['快照／检查点', '251／1977'],
            ['主观察墙钟', '4002203951 ns'],
            ['实际主pair／全部规则通过', '200／200；首个跨界pair 1个仍参加判定'],
            ['纯主支持窗口', '199个；跨界pair不计纯主覆盖'],
            ['纯主几何覆盖', '3981985286／4002203951 ns，99.4948%'],
            ['完整落入纯支持区间的主调用', '100736／101248'],
            ['首／尾／内部缺口', '20170432／13224／35009 ns'],
        ]
        expected_values = [['指标', '正常进程原值']] + slots['5.9_table']['data_rows']
        assert [[text(cell) for cell in row.findall('w:tc', NS)] for row in rows] == expected_values
        assert table.xpath('./w:tblGrid/w:gridCol/@w:w', namespaces=NS) == ['2948', '6009']
        for number, row in enumerate(rows):
            assert row.xpath('./w:trPr/w:trHeight/@w:hRule', namespaces=NS) == ['atLeast']
            assert row.find('w:trPr/w:cantSplit', NS) is not None
            assert bool(row.findall('w:trPr/w:tblHeader', NS)) == (number == 0)
            if number > 0:
                assert row.findall('.//w:pPr/w:keepNext', NS) == []
        assert set(table.xpath('.//w:rPr/w:sz/@w:val', namespaces=NS)) == {'22'}

        new_math = [by_id(after, slots[slot]['paragraph_id'], direct=True).find('m:oMath', NS)
                    for slot in ['5.9_formula_L_H', '5.9_formula_interval']]
        assert all(element is not None for element in new_math)
        assert [(element.find('m:e/m:r/m:t', NS).text,
                 element.find('m:sub/m:r/m:t', NS).text,
                 element.find('m:sup/m:r/m:t', NS).text)
                for element in new_math[0].findall('m:sSubSup', NS)] == [
                    ('M', 'next', '−'), ('M', 'prev', '+'), ('M', 'next', '+'), ('M', 'prev', '−')]
        fractions = new_math[1].findall('.//m:f', NS)
        assert len(fractions) == 2
        assert [(''.join(element.xpath('./m:num//m:t/text()', namespaces=NS)),
                 ''.join(element.xpath('./m:den//m:t/text()', namespaces=NS)))
                for element in fractions] == [('4300ΔA', 'H'), ('4300ΔA', 'L')]
        assert new_math[1].xpath('./m:d/m:dPr/m:begChr/@m:val', namespaces=NS) == ['[']
        assert new_math[1].xpath('./m:d/m:dPr/m:endChr/@m:val', namespaces=NS) == [']']
        picture = by_id(after, slots['5.9_figure']['paragraph_id'], direct=True)
        new_drawing = picture.find('.//w:drawing', NS)
        assert new_drawing is not None and picture.find('.//wp:inline', NS) is not None
        assert sha256(candidate.read(IMAGE_PART)) == sha256(FIGURE.read_bytes()) == EXPECTED_IMAGE_SHA256
        assert picture.find('.//wp:extent', NS).attrib == {'cx': '5688000', 'cy': '3737828'}
        assert picture.find('.//a:xfrm/a:ext', NS).attrib == {'cx': '5688000', 'cy': '3737828'}
        drawing_properties = picture.find('.//wp:docPr', NS)
        drawing_id_start = max(map(int, before.xpath('.//wp:docPr/@id|.//pic:cNvPr/@id', namespaces=NS))) + 1
        assert int(drawing_properties.get('id')) == drawing_id_start
        assert drawing_properties.get('id') == slots['5.9_figure']['docPr_id']
        picture_properties = picture.find('.//pic:cNvPr', NS)
        assert int(picture_properties.get('id')) == drawing_id_start + 1
        assert picture_properties.get('descr') == slots['5.9_figure']['alt_text']
        assert drawing_properties.get('descr') == slots['5.9_figure']['alt_text']
        privacy_scan(drawing_properties.get('descr'), 'new_picture_alt')
        for name, path, excluded, old_count, new_count in [
            ('native_math', './/m:oMath', set(new_math), 62, 64),
            ('drawings', './/w:drawing', {new_drawing}, 18, 19),
            ('sections', './/w:sectPr', set(), 4, 4),
        ]:
            old = before.findall(path, NS)
            current = after.findall(path, NS)
            assert len(old) == old_count and len(current) == new_count
            assert [xml_hash(element) for element in old] == [
                xml_hash(element) for element in current if element not in excluded], name
            features[name] = {'original_count': old_count, 'final_count': new_count,
                              'all_original_xml_hashes_identical_in_order': True}

        old_relationships = etree.fromstring(source.read('word/_rels/document.xml.rels'))
        relationships = etree.fromstring(candidate.read('word/_rels/document.xml.rels'))
        assert len(relationships) == len(old_relationships) + 1
        assert [xml_hash(element) for element in old_relationships] == [
            xml_hash(element) for element in list(relationships)[:-1]]
        relationship = relationships[-1]
        figure_record = slots['5.9_figure']
        assert relationship.get('Id') == figure_record['relationship_id']
        assert relationship.get('Type') == NS['r'] + '/image'
        assert relationship.get('Target') == IMAGE_PART.removeprefix('word/')
        assert picture.find('.//a:blip', NS).get('{' + NS['r'] + '}embed') == relationship.get('Id')
        assert len({element.get('Id') for element in relationships}) == len(relationships)
        old_settings = etree.fromstring(source.read('word/settings.xml'))
        settings = etree.fromstring(candidate.read('word/settings.xml'))
        updates = settings.findall('w:updateFields', NS)
        assert len(updates) == 1 and updates[0].get('{' + NS['w'] + '}val') == 'true'
        assert [xml_hash(element) for element in old_settings] == [
            xml_hash(element) for element in settings if element is not updates[0]]
        changed_parts = [name for name in source.namelist()
                         if sha256(candidate.read(name)) != sha256(source.read(name))]
        allowed_parts = {'word/document.xml', 'docProps/app.xml', 'word/settings.xml',
                         'word/_rels/document.xml.rels'}
        assert set(changed_parts) == allowed_parts
        assert set(candidate.namelist()) - set(source.namelist()) == {IMAGE_PART}
        assert set(source.namelist()) <= set(candidate.namelist())
        app = etree.fromstring(candidate.read('docProps/app.xml'))
        app_pages = int(app.find('ep:Pages', NS).text)
        old_app = etree.fromstring(source.read('docProps/app.xml'))
        expected_app = deepcopy(old_app)
        expected_app.find('ep:Pages', NS).text = str(app_pages)
        assert xml_hash(expected_app) == xml_hash(app)
        core = etree.fromstring(candidate.read('docProps/core.xml'))
        author_fields = core.xpath('./*[local-name()="creator" or local-name()="lastModifiedBy"]')
        assert all(not ''.join(element.itertext()).strip() for element in author_fields)
        for name in candidate.namelist():
            if name.endswith('.xml') or name.endswith('.rels'):
                privacy_scan(candidate.read(name).decode('utf-8'), name)
        document_text = ''.join(after.xpath('.//w:t/text()|.//m:t/text()', namespaces=NS))

        restored = deepcopy(after)
        assert len(toc_entries(restored)) == len(toc_map['mapping']) == 43
        for (paragraph, heading, anchor), row in zip(toc_entries(restored), toc_map['mapping']):
            assert heading == row['heading'] and anchor == row['anchor']
            assert paragraph.findall('.//w:t', NS)[-1].text == str(row['body_page'])
            paragraph.findall('.//w:t', NS)[-1].text = str(row['old_page'])
        restored_xml = etree.tostring(restored, xml_declaration=True, encoding='UTF-8', standalone=True)
        assert sha256(restored_xml) == toc_map['before_document_xml_sha256']
        assert sha256(candidate.read('word/document.xml')) == toc_map['after_document_xml_sha256']

    reader = PdfReader(arguments.pdf)
    assert app_pages == len(reader.pages) == toc_map['actual_pdf_pages']
    first_body_page, actual_mapping = pagination(after, reader)
    assert first_body_page == toc_map['first_body_physical_page']
    for actual, stored in zip(actual_mapping, toc_map['mapping']):
        assert all(actual[key] == stored[key] for key in ['heading', 'anchor', 'physical_page', 'body_page'])
    pdf_text = ''.join(page.extract_text() or '' for page in reader.pages)
    for scope, value in [('docx', document_text), ('pdf', pdf_text)]:
        normalized = normalize(value)
        for required in ['126528', '101248', '4002203951', '3981985286', '100736', '200',
                         '99.4948%', '20170432', '13224', '35009', '251', '1977', '199',
                         '0.255407', '2026年10月10日', 'R02/R04仍部分签收',
                         '不是恢复耗时', '0字节表示测量未知，不是零调用',
                         '平均窗口不认证区间内逐时或逐调用恒频',
                         '200窗来自一个进程，不是200次独立重复',
                         'pair仅指相邻反馈快照对，不是AB/BA运行对',
                         '非精确C0比例', '不是置信区间或完整物理误差界',
                         '1秒预热后以4秒为主观察目标', '(5-5)', '(5-6)',
                         'data/g2/', 'research/g2/', 'code/g2-analysis/',
                         '10.1002/sim.3337', '10.1080/01621459.2020.1750415',
                         '10.1080/01621459.1963.10500830', '[15]', 'fixed tag v6.17']:
            assert normalize(required) in normalized, (scope, 'required_text', required)
        privacy_scan(value, scope)
    assert not ((reader.metadata or {}).get('/Author') or '').strip()
    for row in slots['5.9_table']['data_rows']:
        assert normalize(row[1]) in normalize(pdf_text), ('pdf_table_value', row)
    old_summary = slots['7.1_condense_redundant_history_summary']['before']
    for numeric_token in re.findall(r'\d+(?:\.\d+)*', old_summary):
        assert numeric_token in document_text and numeric_token in normalize(pdf_text)
    for field in ['full_main_or_per_call_constant_frequency_claim', 'physical_precision_certified',
                  'independent_window_samples_claim']:
        assert initial[field] is False
    assert initial['R02'] == initial['R04'] == 'partial'
    assert initial['external_review_status'] == 'pending Codex review'
    expected_pages = list(range(1, len(reader.pages) + 1))
    png_paths = {number: arguments.png_dir / f'page-{number}.png' for number in expected_pages}
    assert set(arguments.png_dir.glob('page-*.png')) == set(png_paths.values())
    page_hashes = {}
    for number, path in png_paths.items():
        payload = path.read_bytes()
        assert payload.startswith(b'\x89PNG\r\n\x1a\n') and len(payload) > 1000
        page_hashes[str(number)] = sha256(payload)
    visual = None
    if arguments.visual_qa:
        visual = json.loads(arguments.visual_qa.read_text())
        assert sorted(visual['reviewed_pages']) == expected_pages
        assert visual['page_count'] == len(reader.pages)
        assert visual['blocking_layout_findings'] == []
        assert visual['all_pages_individually_viewed'] is True
        assert visual['pdf_sha256'] == sha256(arguments.pdf.read_bytes())
        assert visual['page_png_sha256'] == page_hashes
    assert sha256(ORIGINAL.read_bytes()) == EXPECTED_SHA256
    result = {
        'source_docx_sha256': EXPECTED_SHA256, 'original_47_page_source_unchanged': True,
        'candidate_docx': str(REPORT), 'candidate_docx_sha256': sha256(REPORT.read_bytes()),
        'candidate_pdf': str(arguments.pdf.resolve()), 'candidate_pdf_sha256': sha256(arguments.pdf.read_bytes()),
        'actual_pages': len(reader.pages), 'all_page_pngs_exist': True, 'toc_entries_verified': 43,
        'original_elements': features, 'modified_original_direct_paragraphs': [305, 338, 339],
        'removed_original_direct_paragraphs': [311],
        'removed_editorial_note_retained_verbatim_in_authoring_log': True,
        'delivery_readme_relocation_recorded': 'authoring_log_and_delivery_README',
        'unmodified_non_toc_original_paragraphs_verified_in_order': len(expected_unchanged),
        'registered_new_direct_paragraphs_xml_verified': 19,
        'original_toc_only_cached_numbers_changed': 42,
        'original_relationships_preserved_append_only_one_image': True,
        'settings_original_children_preserved_update_fields_only': True,
        'changed_ooxml_parts': changed_parts,
        'untouched_original_package_parts_verified': len(source.namelist()) - len(changed_parts),
        'G2_primary_counts_docx_pdf_verified': True, 'G2_claim_boundaries_verified': True,
        'new_native_math_structure_verified': True, 'new_image_sha256': EXPECTED_IMAGE_SHA256,
        'anonymous_content_and_core_author_fields_verified': True,
        'visual_qa_complete': visual is not None,
        'visual_qa_sha256': sha256(arguments.visual_qa.read_bytes()) if arguments.visual_qa else None,
        'page_png_sha256': page_hashes, 'R02': 'partial', 'R04': 'partial',
        'external_review_status': 'pending Codex review',
        'status': 'reviewable_candidate' if visual else 'structural_pass_pending_visual',
    }
    (WORK / 'candidate-verification.json').write_text(json.dumps(result, ensure_ascii=False, indent=2) + '\n')
    print(json.dumps({key: value for key, value in result.items() if key != 'page_png_sha256'}, ensure_ascii=False))


if __name__ == '__main__':
    main()
