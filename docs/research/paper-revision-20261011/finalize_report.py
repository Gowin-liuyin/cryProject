from pathlib import Path
import argparse
import hashlib
import json
import re
import unicodedata
import zipfile

from lxml import etree
from pypdf import PdfReader


repository = Path(__file__).resolve().parents[3]
work = repository / 'build/paper-revision-20261011'
report = repository / 'deliverables/research/paper-revision-20261011/CACR2026EA16XZ-作品设计报告-论文修订版.docx'
namespace = {'w': 'http://schemas.openxmlformats.org/wordprocessingml/2006/main',
             'ep': 'http://schemas.openxmlformats.org/officeDocument/2006/extended-properties'}


def normalize(value):
    return re.sub(r'\s+', '', unicodedata.normalize('NFKC', value)).replace('−', '-')


parser = argparse.ArgumentParser()
parser.add_argument('pdf', type=Path)
parser.add_argument('--check', action='store_true')
arguments = parser.parse_args()
reader = PdfReader(arguments.pdf)
pages = [page.extract_text() or '' for page in reader.pages]
with zipfile.ZipFile(report) as source:
    package = {name: source.read(name) for name in source.namelist()}
root = etree.fromstring(package['word/document.xml'])
headings = json.loads((work / 'headings.json').read_text())
first_title = normalize(headings[0]['title'])
first_body = next(index for index, page in enumerate(pages, 1)
                  if any(normalize(line) == first_title for line in page.splitlines()))
entries = root.xpath('./w:body/w:p[w:pPr/w:pStyle[@w:val="RWTOC1" or @w:val="RWTOC2"]]', namespaces=namespace)
assert len(entries) == len(headings) == 50
mapping = []
previous_page = first_body
for entry, heading in zip(entries, headings):
    title = heading['title']
    physical_page = next(index for index, page in enumerate(pages, 1)
                         if index >= previous_page and normalize(title) in normalize(page))
    body_page = physical_page - first_body + 1
    nodes = entry.findall('.//w:t', namespace)
    if not arguments.check:
        nodes[0].text = title
    else:
        assert nodes[0].text == title
    if arguments.check:
        assert nodes[-1].text == str(body_page), (title, nodes[-1].text, body_page)
    else:
        nodes[-1].text = str(body_page)
    mapping.append({'title': title, 'physical_page': physical_page, 'body_page': body_page})
    previous_page = physical_page
if not arguments.check:
    properties = etree.fromstring(package['docProps/app.xml'])
    properties.find('ep:Pages', namespace).text = str(len(pages))
    package['docProps/app.xml'] = etree.tostring(properties, xml_declaration=True, encoding='UTF-8', standalone=True)
    package['word/document.xml'] = etree.tostring(root, xml_declaration=True, encoding='UTF-8', standalone=True)
    with zipfile.ZipFile(report, 'w', compression=zipfile.ZIP_DEFLATED) as destination:
        for name, payload in package.items():
            destination.writestr(name, payload)
result = {'pages': len(pages), 'first_body_page': first_body, 'check_only': arguments.check,
          'docx_sha256': hashlib.sha256(report.read_bytes()).hexdigest(),
          'pdf_sha256': hashlib.sha256(arguments.pdf.read_bytes()).hexdigest(), 'mapping': mapping}
(work / ('toc-verified.json' if arguments.check else 'toc-map.json')).write_text(json.dumps(result, ensure_ascii=False, indent=2))
(work / 'final-page-texts.json').write_text(json.dumps(pages, ensure_ascii=False, indent=2))
print(json.dumps({key: value for key, value in result.items() if key != 'mapping'}))
