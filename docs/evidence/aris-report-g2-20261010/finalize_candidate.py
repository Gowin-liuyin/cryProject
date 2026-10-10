from pathlib import Path
import argparse
import hashlib
import json
import re
import unicodedata
import zipfile

from lxml import etree
from pypdf import PdfReader


WORK = Path(__file__).resolve().parent
REPO = WORK.parent.parent
REPORT = WORK / 'CACR2026EA16XZ-作品设计报告-G2补充候选版.docx'
BASE = WORK / 'base-47-page-20261010.docx'
ORIGINAL = REPO / 'deliverables/research/aris-report-weak-mean-20261010/CACR2026EA16XZ-作品设计报告-匿名版.docx'
EXPECTED_SHA256 = '9a2b7e92cebc8dc7b4aca677728a7ebb5d2b29c90b265e82d14b926bdb360c3a'
NS = {
    'w': 'http://schemas.openxmlformats.org/wordprocessingml/2006/main',
    'w14': 'http://schemas.microsoft.com/office/word/2010/wordml',
    'm': 'http://schemas.openxmlformats.org/officeDocument/2006/math',
    'r': 'http://schemas.openxmlformats.org/officeDocument/2006/relationships',
    'wp': 'http://schemas.openxmlformats.org/drawingml/2006/wordprocessingDrawing',
    'a': 'http://schemas.openxmlformats.org/drawingml/2006/main',
    'pic': 'http://schemas.openxmlformats.org/drawingml/2006/picture',
    'rel': 'http://schemas.openxmlformats.org/package/2006/relationships',
    'ep': 'http://schemas.openxmlformats.org/officeDocument/2006/extended-properties',
}


def sha256(payload):
    return hashlib.sha256(payload).hexdigest()


def xml_hash(element):
    return sha256(etree.tostring(element))


def text(element):
    return ''.join(element.xpath('.//w:t/text()', namespaces=NS))


def normalize(value):
    return re.sub(r'\s+', '', unicodedata.normalize('NFKC', value)).replace('−', '-')


def is_toc(paragraph):
    return paragraph.xpath('./w:pPr/w:pStyle/@w:val', namespaces=NS) in [['RWTOC1'], ['RWTOC2']]


def toc_entries(root):
    entries = []
    for paragraph in root.findall('./w:body/w:p', NS):
        if not is_toc(paragraph):
            continue
        texts = paragraph.findall('.//w:t', NS)
        assert len(texts) >= 2 and (texts[-1].text or '').isdigit()
        heading = ''.join(node.text or '' for node in texts[:-1])
        hyperlinks = paragraph.findall('w:hyperlink', NS)
        assert len(hyperlinks) == 1
        anchor = hyperlinks[0].get('{' + NS['w'] + '}anchor')
        bookmarks = root.xpath('.//w:bookmarkStart[@w:name=$name]', namespaces=NS, name=anchor)
        assert len(bookmarks) == 1, (heading, anchor)
        bookmark = bookmarks[0]
        target = bookmark.getparent()
        if target.tag != '{' + NS['w'] + '}p':
            target = bookmark.getnext()
            while target is not None and target.tag != '{' + NS['w'] + '}p':
                target = target.getnext()
        assert target is not None and normalize(text(target)) == normalize(heading), (heading, anchor)
        assert target.xpath('./w:pPr/w:pStyle/@w:val', namespaces=NS) in [['RWChapter'], ['RWSection']]
        entries.append((paragraph, heading, anchor))
    assert len(entries) == 43
    return entries


def pagination(root, reader):
    page_texts = [page.extract_text() or '' for page in reader.pages]
    pages = [normalize(value) for value in page_texts]
    chapters = [paragraph for paragraph in root.findall('./w:body/w:p', NS)
                if paragraph.xpath('./w:pPr/w:pStyle/@w:val', namespaces=NS) == ['RWChapter']]
    assert chapters
    first_title = normalize(text(chapters[0]))
    page_lines = [[normalize(line) for line in value.splitlines()] for value in page_texts]
    # 目录行还带页码，不能把它当成正文第一页。
    first_body_page = next(number for number, lines in enumerate(page_lines, 1)
                           if any(''.join(lines[start:start + count]) == first_title
                                  for start in range(len(lines)) for count in [1, 2, 3]))
    mapping = []
    for entry_number, (paragraph, heading, anchor) in enumerate(toc_entries(root), 1):
        matches = [number for number, page in enumerate(pages, 1)
                   if number >= first_body_page and normalize(heading) in page]
        assert matches, ('heading_missing_from_pdf', heading)
        physical_page = min(matches)
        mapping.append({'entry_1_based': entry_number, 'heading': heading, 'anchor': anchor,
                        'paragraph_id': paragraph.get('{' + NS['w14'] + '}paraId'),
                        'old_page': int(paragraph.findall('.//w:t', NS)[-1].text),
                        'physical_page': physical_page,
                        'body_page': physical_page - first_body_page + 1})
    assert [row['physical_page'] for row in mapping] == sorted(row['physical_page'] for row in mapping)
    return first_body_page, mapping


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--pdf', type=Path, required=True)
    arguments = parser.parse_args()
    assert sha256(ORIGINAL.read_bytes()) == sha256(BASE.read_bytes()) == EXPECTED_SHA256
    initial = json.loads((WORK / 'initial-structure.json').read_text())
    before_sha256 = sha256(REPORT.read_bytes())
    assert before_sha256 == initial['candidate_before_toc_sha256'], 'run_on_fresh_builder_output'
    changes_bytes = (WORK / 'authoring-edits.json').read_bytes()
    changes = json.loads(changes_bytes)
    registered = [row for row in changes if 'paragraph_id' in row
                  and 'base_direct_paragraph_1_based' not in row and row['slot'] != 'abstract_g2_append']
    assert len(registered) == 19
    reader = PdfReader(arguments.pdf)
    with zipfile.ZipFile(REPORT) as source:
        original_parts = {name: sha256(source.read(name)) for name in source.namelist()}
        document_before = source.read('word/document.xml')
        root = etree.fromstring(document_before)
        first_body_page, mapping = pagination(root, reader)
        registered_hashes = []
        for row in registered:
            paragraphs = root.xpath('./w:body/w:p[@w14:paraId=$value]', namespaces=NS, value=row['paragraph_id'])
            assert len(paragraphs) == 1, row['slot']
            registered_hashes.append({'slot': row['slot'], 'paragraph_id': row['paragraph_id'],
                                      'xml_sha256': xml_hash(paragraphs[0])})
        for (paragraph, _, _), row in zip(toc_entries(root), mapping):
            paragraph.findall('.//w:t', NS)[-1].text = str(row['body_page'])
        app = etree.fromstring(source.read('docProps/app.xml'))
        page_count = app.find('ep:Pages', NS)
        assert page_count is not None
        old_pages = page_count.text
        page_count.text = str(len(reader.pages))
        replacements = {
            'word/document.xml': etree.tostring(root, xml_declaration=True, encoding='UTF-8', standalone=True),
            'docProps/app.xml': etree.tostring(app, xml_declaration=True, encoding='UTF-8', standalone=True),
        }
        temporary = WORK / 'candidate-toc-updated.docx'
        with zipfile.ZipFile(temporary, 'w', compression=zipfile.ZIP_DEFLATED) as output:
            for info in source.infolist():
                output.writestr(info, replacements.get(info.filename, source.read(info.filename)))
        with zipfile.ZipFile(temporary) as output:
            assert output.namelist() == source.namelist()
            changed_parts = [name for name in output.namelist()
                             if sha256(output.read(name)) != original_parts[name]]
            assert set(changed_parts) <= set(replacements)
            assert all(sha256(output.read(name)) == original_parts[name]
                       for name in output.namelist() if name not in replacements)
    temporary.replace(REPORT)
    assert sha256(ORIGINAL.read_bytes()) == EXPECTED_SHA256
    result = {
        'actual_pdf_pages': len(reader.pages), 'first_body_physical_page': first_body_page,
        'old_app_pages': old_pages, 'new_app_pages': str(len(reader.pages)), 'toc_entries': len(mapping),
        'changed_toc_numbers': sum(row['old_page'] != row['body_page'] for row in mapping),
        'dynamic_pagination': True, 'headings_joined_across_pdf_lines': True,
        'source_docx_sha256': EXPECTED_SHA256, 'candidate_before_toc_sha256': before_sha256,
        'candidate_after_toc_sha256': sha256(REPORT.read_bytes()),
        'authoring_edits_sha256': sha256(changes_bytes),
        'before_document_xml_sha256': sha256(document_before),
        'after_document_xml_sha256': sha256(replacements['word/document.xml']),
        'pagination_pdf_sha256': sha256(arguments.pdf.read_bytes()),
        'registered_new_paragraphs_before_toc': registered_hashes,
        'changed_parts': changed_parts, 'mapping': mapping,
    }
    (WORK / 'toc-map.json').write_text(json.dumps(result, ensure_ascii=False, indent=2) + '\n')
    print(json.dumps({key: value for key, value in result.items()
                      if key not in ['mapping', 'registered_new_paragraphs_before_toc']}, ensure_ascii=False))


if __name__ == '__main__':
    main()
