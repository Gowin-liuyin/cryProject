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
REPORT = WORK / 'CACR2026EA16XZ-作品设计报告-弱均值补充候选版.docx'
NS = {'w': 'http://schemas.openxmlformats.org/wordprocessingml/2006/main'}
parser = argparse.ArgumentParser()
parser.add_argument('--pdf', type=Path, required=True)
arguments = parser.parse_args()
reader = PdfReader(arguments.pdf)
normalize = lambda value: re.sub(r'\s+', '', value)
page_lines = [[normalize(line) for line in (page.extract_text() or '').splitlines()] for page in reader.pages]
with zipfile.ZipFile(REPORT) as source:
    root = E.fromstring(source.read('word/document.xml'))
    paragraphs = root.findall('./w:body/w:p', NS)
    chapter = next(paragraph for paragraph in paragraphs
                   if paragraph.find('w:pPr/w:pStyle', NS) is not None
                   and paragraph.find('w:pPr/w:pStyle', NS).get('{' + NS['w'] + '}val') == 'RWChapter')
    first_title = normalize(''.join(chapter.xpath('.//w:t/text()', namespaces=NS)))
    first_body_page = next(number for number, lines in enumerate(page_lines, 1) if first_title in lines)
    mapping = []
    for paragraph in paragraphs:
        style = paragraph.find('w:pPr/w:pStyle', NS)
        if style is None or style.get('{' + NS['w'] + '}val') not in ('RWTOC1', 'RWTOC2'):
            continue
        nodes = paragraph.findall('.//w:t', NS)
        assert nodes[-1].text.isdigit()
        heading = ''.join(node.text or '' for node in nodes[:-1])
        matches = [number for number, lines in enumerate(page_lines, 1)
                   if number >= first_body_page and normalize(heading) in lines]
        assert matches, heading
        physical_page = min(matches)
        logical_page = physical_page - first_body_page + 1
        mapping.append({'heading': heading, 'old_page': int(nodes[-1].text),
                        'physical_page': physical_page, 'body_page': logical_page})
        nodes[-1].text = str(logical_page)
    assert len(mapping) == 42
    app = E.fromstring(source.read('docProps/app.xml'))
    pages = app.find('{http://schemas.openxmlformats.org/officeDocument/2006/extended-properties}Pages')
    assert pages is not None
    old_pages = pages.text
    pages.text = str(len(reader.pages))
    replacements = {'word/document.xml': E.tostring(root, xml_declaration=True, encoding='UTF-8', standalone=True),
                    'docProps/app.xml': E.tostring(app, xml_declaration=True, encoding='UTF-8', standalone=True)}
    temporary = WORK / 'candidate-toc-updated.docx'
    with zipfile.ZipFile(temporary, 'w', compression=zipfile.ZIP_DEFLATED) as output:
        for info in source.infolist():
            output.writestr(info, replacements.get(info.filename, source.read(info.filename)))
temporary.replace(REPORT)
result = {'actual_pdf_pages': len(reader.pages), 'first_body_physical_page': first_body_page,
          'old_app_pages': old_pages, 'new_app_pages': str(len(reader.pages)), 'toc_entries': len(mapping),
          'changed_toc_numbers': sum(row['old_page'] != row['body_page'] for row in mapping),
          'dynamic_pagination': True, 'mapping': mapping}
(WORK / 'toc-map.json').write_text(json.dumps(result, ensure_ascii=False, indent=2) + '\n')
print(json.dumps({key: value for key, value in result.items() if key != 'mapping'}, ensure_ascii=False))
