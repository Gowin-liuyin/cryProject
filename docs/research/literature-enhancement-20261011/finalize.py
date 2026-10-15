from pathlib import Path
import json
import re
import unicodedata
import zipfile
import sys
from lxml import etree
from pypdf import PdfReader

root = Path(__file__).resolve().parents[3]
work = root / 'build/litqa'
report = root / 'deliverables/research/literature-enhancement-20261011/CACR2026EA16XZ-作品设计报告-文献增强版.docx'
pdf = Path(sys.argv[1])
check = '--check' in sys.argv
ns = {'w': 'http://schemas.openxmlformats.org/wordprocessingml/2006/main'}
normalize = lambda value: re.sub(r'\s+', '', unicodedata.normalize('NFKC', value)).replace('−', '-')
with zipfile.ZipFile(report) as source:
    package = {name: source.read(name) for name in source.namelist()}
xml = etree.fromstring(package['word/document.xml'])
pages = [page.extract_text() or '' for page in PdfReader(pdf).pages]
body = xml.find('w:body', ns)
text = lambda element: ''.join(element.xpath('.//w:t/text()', namespaces=ns))
headings = [text(e) for e in body if e.xpath('./w:pPr/w:pStyle[@w:val="RWChapter" or @w:val="RWSection"]', namespaces=ns)]
entries = body.xpath('./w:p[w:pPr/w:pStyle[@w:val="RWTOC1" or @w:val="RWTOC2"]]', namespaces=ns)
assert len(entries) == len(headings) == 50
first_body = next(number for number, page in enumerate(pages, 1) if any(normalize(line) == normalize(headings[0]) for line in page.splitlines()))
previous = first_body
mapping = []
for heading, entry in zip(headings, entries):
    page_number = next(number for number, page in enumerate(pages, 1) if number >= previous and normalize(heading) in normalize(page))
    nodes = entry.findall('.//w:t', ns)
    assert normalize(nodes[0].text) == normalize(heading)
    if check:
        assert nodes[-1].text == str(page_number - first_body + 1)
    else:
        nodes[-1].text = str(page_number - first_body + 1)
    mapping.append({'title': heading, 'physical_page': page_number, 'body_page': page_number - first_body + 1})
    previous = page_number
if not check:
    package['word/document.xml'] = etree.tostring(xml, xml_declaration=True, encoding='UTF-8', standalone=True)
    app = etree.fromstring(package['docProps/app.xml'])
    app.find('{http://schemas.openxmlformats.org/officeDocument/2006/extended-properties}Pages').text = str(len(pages))
    package['docProps/app.xml'] = etree.tostring(app, xml_declaration=True, encoding='UTF-8', standalone=True)
    with zipfile.ZipFile(report, 'w', compression=zipfile.ZIP_DEFLATED) as destination:
        for name, content in package.items():
            destination.writestr(name, content)
result = {'pages': len(pages), 'mapping': mapping, 'checked': check}
(work / ('toc-verified.json' if check else 'toc-map.json')).write_text(json.dumps(result, ensure_ascii=False, indent=2))
(work / 'page-texts.json').write_text(json.dumps(pages, ensure_ascii=False, indent=2))
print(json.dumps({'pages': len(pages), 'toc_entries': len(mapping), 'check': check}))
