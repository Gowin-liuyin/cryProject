from copy import deepcopy
from pathlib import Path
import argparse
import hashlib
import json
import re
import zipfile

from lxml import etree as E
from pypdf import PdfReader


WORK = Path(__file__).resolve().parent
REPO = WORK.parent.parent
BASE = WORK / 'base-20261009.docx'
REPORT = WORK / 'CACR2026EA16XZ-作品设计报告-弱均值补充候选版.docx'
ORIGINAL = REPO / 'deliverables/research/aris-report-current-20261009/CACR2026EA16XZ-作品设计报告-匿名版.docx'
NS = {'w': 'http://schemas.openxmlformats.org/wordprocessingml/2006/main',
      'm': 'http://schemas.openxmlformats.org/officeDocument/2006/math'}
W = '{' + NS['w'] + '}'
parser = argparse.ArgumentParser()
parser.add_argument('--pdf', type=Path, required=True)
parser.add_argument('--png-dir', type=Path, required=True)
parser.add_argument('--visual-qa', type=Path)
arguments = parser.parse_args()
sha256 = lambda data: hashlib.sha256(data).hexdigest()
text = lambda paragraph: ''.join(paragraph.xpath('.//w:t/text()', namespaces=NS))
normalize = lambda value: re.sub(r'\s+', '', value)

with zipfile.ZipFile(BASE) as source, zipfile.ZipFile(REPORT) as candidate:
    before = E.fromstring(source.read('word/document.xml'))
    after = E.fromstring(candidate.read('word/document.xml'))
    features = {}
    for name, path, expected in [('tables', './/w:tbl', 22), ('native_math', './/m:oMath', 62),
                                 ('drawings', './/w:drawing', 18), ('sections', './/w:sectPr', 4)]:
        old = [sha256(E.tostring(node)) for node in before.findall(path, NS)]
        new = [sha256(E.tostring(node)) for node in after.findall(path, NS)]
        assert len(old) == expected and old == new, name
        features[name] = {'count': expected, 'all_original_xml_hashes_identical': True}
    changes = json.loads((WORK / 'authoring-edits.json').read_text())
    original_numbers = {row['base_direct_paragraph_1_based'] for row in changes
                        if 'base_direct_paragraph_1_based' in row}
    assert original_numbers == {22, 125, 164, 193, 206, 309}
    changed_text = {row['after'] for row in changes if 'after' in row}
    added_text = {row['added'] for row in changes if 'added' in row}
    old_paragraphs = before.findall('./w:body/w:p', NS)
    new_paragraphs = after.findall('./w:body/w:p', NS)

    def is_toc(paragraph):
        style = paragraph.find('w:pPr/w:pStyle', NS)
        return style is not None and style.get(W + 'val') in ('RWTOC1', 'RWTOC2')

    expected = [sha256(E.tostring(paragraph)) for number, paragraph in enumerate(old_paragraphs, 1)
                if number not in original_numbers and not is_toc(paragraph)]
    actual = [sha256(E.tostring(paragraph)) for paragraph in new_paragraphs
              if text(paragraph) not in changed_text | added_text and not is_toc(paragraph)]
    assert expected == actual
    for value in changed_text | added_text:
        assert sum(text(paragraph) == value for paragraph in new_paragraphs) == 1, value
    layout = next(row for row in changes if row.get('layout_only'))
    original_layout = old_paragraphs[205]
    candidate_layout = next(paragraph for paragraph in new_paragraphs if text(paragraph) == layout['after'])
    expected_layout = deepcopy(original_layout)
    properties = expected_layout.find('w:pPr', NS)
    keep_next = properties.find('w:keepNext', NS)
    if keep_next is None:
        keep_next = E.SubElement(properties, W + 'keepNext')
    keep_next.set(W + 'val', '1')
    assert E.tostring(expected_layout, method='c14n', exclusive=True) == E.tostring(
        candidate_layout, method='c14n', exclusive=True)
    assert [E.tostring(node) for node in original_layout if node.tag != W + 'pPr'] == [
        E.tostring(node) for node in candidate_layout if node.tag != W + 'pPr']
    changed_parts = [name for name in candidate.namelist() if sha256(candidate.read(name)) != sha256(source.read(name))]
    assert changed_parts == ['docProps/app.xml', 'word/document.xml'] or changed_parts == ['word/document.xml', 'docProps/app.xml']
    app = E.fromstring(candidate.read('docProps/app.xml'))
    app_pages = int(app.find('{http://schemas.openxmlformats.org/officeDocument/2006/extended-properties}Pages').text)

reader = PdfReader(arguments.pdf)
assert app_pages == len(reader.pages)
pngs = list(arguments.png_dir.glob('page-*.png'))
assert len(pngs) == len(reader.pages)
assert all((arguments.png_dir / f'page-{number}.png').is_file() for number in range(1, len(reader.pages) + 1))
lines = [[normalize(line) for line in (page.extract_text() or '').splitlines()] for page in reader.pages]
toc = json.loads((WORK / 'toc-map.json').read_text())
assert toc['actual_pdf_pages'] == len(reader.pages)
candidate_toc = [paragraph for paragraph in new_paragraphs if is_toc(paragraph)]
assert len(candidate_toc) == len(toc['mapping']) == 42
for row, paragraph in zip(toc['mapping'], candidate_toc):
    assert normalize(row['heading']) in lines[row['physical_page'] - 1]
    assert int(paragraph.findall('.//w:t', NS)[-1].text) == row['body_page']
pdf_text = ''.join(''.join(line) for line in lines)
for phrase in ['2026年10月10日', '无主导反事实方差条件可给渐近保守区间',
               '不把Wu与Ding的大层定理用于每层两时段', 'R04仍部分签收',
               '10.1002/sim.3337', '10.1080/01621459.2020.1750415', '10.1080/01621459.1963.10500830']:
    assert normalize(phrase) in pdf_text, phrase
assert sha256(ORIGINAL.read_bytes()) == sha256(BASE.read_bytes()) == '4c6ef7de4cfa681dd3550ec570d9a96b248e1a62885fccbdb4f0f6ea4421a7ca'
visual = None
if arguments.visual_qa:
    visual = json.loads(arguments.visual_qa.read_text())
    assert sorted(visual['reviewed_pages']) == list(range(1, len(reader.pages) + 1))
    assert visual['blocking_layout_findings'] == []
    assert visual['pdf_sha256'] == sha256(arguments.pdf.read_bytes())
result = {'source_docx_sha256': sha256(BASE.read_bytes()), 'original_source_unchanged': True,
          'candidate_docx': str(REPORT), 'candidate_docx_sha256': sha256(REPORT.read_bytes()),
          'candidate_pdf': str(arguments.pdf.resolve()), 'candidate_pdf_sha256': sha256(arguments.pdf.read_bytes()),
          'actual_pages': len(reader.pages), 'all_page_pngs_exist': True, 'toc_entries_verified': 42,
          'original_elements': features, 'original_text_or_date_paragraphs_changed': 5,
          'layout_only_original_paragraphs_changed': 1, 'layout_only_original_text_and_math_preserved': True,
          'unmodified_non_toc_original_paragraphs_verified': len(expected), 'new_paragraphs': 4,
          'changed_ooxml_parts': changed_parts, 'visual_qa_complete': visual is not None,
          'R04_remains_partial': True, 'new_cpu_execution_claims': 0,
          'old_archive_contains_new_proof_claims': 0,
          'status': 'reviewable_candidate' if visual else 'structural_pass_pending_visual'}
(WORK / 'candidate-verification.json').write_text(json.dumps(result, ensure_ascii=False, indent=2) + '\n')
print(json.dumps(result, ensure_ascii=False))
