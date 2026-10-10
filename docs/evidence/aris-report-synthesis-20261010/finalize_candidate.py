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
REPORT = WORK / 'CACR2026EA16XZ-作品设计报告-四项研究整合候选版.docx'
NS = {'w': 'http://schemas.openxmlformats.org/wordprocessingml/2006/main',
      'ep': 'http://schemas.openxmlformats.org/officeDocument/2006/extended-properties'}


def norm(value):
    return re.sub(r'\s+', '', unicodedata.normalize('NFKC', value)).replace('−', '-')


def text(element):
    return ''.join(element.xpath('.//w:t/text()', namespaces=NS))


def sha(payload):
    return hashlib.sha256(payload).hexdigest()


def mapping(root, reader):
    raw = [p.extract_text() or '' for p in reader.pages]
    lines = [[norm(line) for line in p.splitlines()] for p in raw]
    chapters = [p for p in root.findall('./w:body/w:p', NS)
                if p.xpath('./w:pPr/w:pStyle/@w:val', namespaces=NS) == ['RWChapter']]
    title = norm(text(chapters[0]))
    first = next(i for i, page in enumerate(lines, 1)
                 if any(''.join(page[start:start+count]) == title
                        for start in range(len(page)) for count in [1, 2, 3]))
    entries = [p for p in root.findall('./w:body/w:p', NS)
               if p.xpath('./w:pPr/w:pStyle/@w:val', namespaces=NS) in [['RWTOC1'], ['RWTOC2']]]
    assert len(entries) == 45
    result = []
    for p in entries:
        texts = p.findall('.//w:t', NS)
        heading = ''.join(t.text or '' for t in texts[:-1])
        anchor = p.find('w:hyperlink', NS).get('{' + NS['w'] + '}anchor')
        physical = next(i for i, page in enumerate(raw, 1) if i >= first and norm(heading) in norm(page))
        result.append({'heading': heading, 'anchor': anchor, 'physical_page': physical,
                       'body_page': physical - first + 1, 'cached_page': int(texts[-1].text)})
    assert [r['physical_page'] for r in result] == sorted(r['physical_page'] for r in result)
    return entries, first, result


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--pdf', required=True, type=Path)
    parser.add_argument('--check', action='store_true')
    args = parser.parse_args()
    reader = PdfReader(args.pdf)
    before = sha(REPORT.read_bytes())
    with zipfile.ZipFile(REPORT) as source:
        parts = {n: source.read(n) for n in source.namelist()}
        root = etree.fromstring(parts['word/document.xml'])
        entries, first, rows = mapping(root, reader)
        if args.check:
            assert all(r['cached_page'] == r['body_page'] for r in rows)
        else:
            for p, row in zip(entries, rows):
                p.findall('.//w:t', NS)[-1].text = str(row['body_page'])
            app = etree.fromstring(parts['docProps/app.xml'])
            app.find('ep:Pages', NS).text = str(len(reader.pages))
            parts['word/document.xml'] = etree.tostring(root, xml_declaration=True, encoding='UTF-8', standalone=True)
            parts['docProps/app.xml'] = etree.tostring(app, xml_declaration=True, encoding='UTF-8', standalone=True)
            target = WORK / 'toc-patched.docx'
            with zipfile.ZipFile(target, 'w', compression=zipfile.ZIP_DEFLATED) as out:
                for info in source.infolist():
                    out.writestr(info, parts[info.filename])
    if not args.check:
        target.replace(REPORT)
    result = {'actual_pdf_pages': len(reader.pages), 'first_body_physical_page': first,
              'toc_entries': len(rows), 'check_only': args.check, 'mapping': rows,
              'docx_before_sha256': before, 'docx_after_sha256': sha(REPORT.read_bytes()),
              'pagination_pdf_sha256': sha(args.pdf.read_bytes())}
    (WORK / ('toc-final-check.json' if args.check else 'toc-map.json')).write_text(json.dumps(result, ensure_ascii=False, indent=2)+'\n')
    (WORK / 'pdf-page-texts.json').write_text(json.dumps([{'physical_page': i, 'text': p.extract_text()}
           for i, p in enumerate(reader.pages, 1)], ensure_ascii=False, indent=2)+'\n')
    print(json.dumps({k: v for k, v in result.items() if k != 'mapping'}))


if __name__ == '__main__':
    main()
