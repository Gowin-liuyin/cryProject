from pathlib import Path
import hashlib
import json
import re
import zipfile
from lxml import etree


repository = Path(__file__).resolve().parents[3]
work = repository / 'build/paper-revision-20261011'
delivery = repository / 'deliverables/research/paper-revision-20261011'
namespace = {'w': 'http://schemas.openxmlformats.org/wordprocessingml/2006/main',
             'm': 'http://schemas.openxmlformats.org/officeDocument/2006/math',
             'a': 'http://schemas.openxmlformats.org/drawingml/2006/main',
             'r': 'http://schemas.openxmlformats.org/officeDocument/2006/relationships'}


def read_package(path):
    with zipfile.ZipFile(path) as source:
        return {name: source.read(name) for name in source.namelist()}


def text(element):
    return ''.join(element.xpath('.//w:t/text()', namespaces=namespace))


source_path = repository / 'deliverables/research/aris-report-synthesis-20261010/CACR2026EA16XZ-作品设计报告-匿名版.docx'
source = read_package(source_path)
candidate = read_package(delivery / 'CACR2026EA16XZ-作品设计报告-论文修订版.docx')
template = read_package(repository / 'docs/reference/official-2026/report-template-original.docx')
source_root = etree.fromstring(source['word/document.xml'])
root = etree.fromstring(candidate['word/document.xml'])
template_root = etree.fromstring(template['word/document.xml'])
checks = []


def check(name, condition):
    checks.append({'name': name, 'passed': bool(condition)})
    assert condition, name


check('source_unchanged', hashlib.sha256(source_path.read_bytes()).hexdigest() == '95ffce23d02180117fb05ccf9ebc406b7b05ae20038f08042e25d13934e2983f')
for index, section in enumerate(root.findall('.//w:sectPr', namespace)):
    template_section = template_root.find('.//w:sectPr', namespace)
    for property_name in ['pgSz', 'pgMar', 'cols', 'docGrid']:
        check(f'section_{index}_{property_name}', dict(section.find('w:' + property_name, namespace).attrib) == dict(template_section.find('w:' + property_name, namespace).attrib))
styles = etree.fromstring(candidate['word/styles.xml'])
for name, font, size, line, rule in [('RWBody', '楷体_GB2312', '28', '480', 'exact'),
                                    ('RWChapter', '华文楷体', '30', '360', 'auto'),
                                    ('RWSection', '黑体', '28', '360', 'auto')]:
    style = styles.xpath('./w:style[@w:styleId="' + name + '"]', namespaces=namespace)[0]
    check(name + '_font', style.find('w:rPr/w:rFonts', namespace).get('{' + namespace['w'] + '}eastAsia') == font)
    check(name + '_size', style.find('w:rPr/w:sz', namespace).get('{' + namespace['w'] + '}val') == size)
    check(name + '_spacing', style.find('w:pPr/w:spacing', namespace).get('{' + namespace['w'] + '}line') == line and style.find('w:pPr/w:spacing', namespace).get('{' + namespace['w'] + '}lineRule') == rule)
check('official_header', candidate['word/header2.xml'] == template['word/header1.xml'])
check('official_footer', candidate['word/footer2.xml'] == template['word/footer1.xml'])

source_tables = source_root.findall('./w:body/w:tbl', namespace)[1:]
tables = [table for table in root.findall('./w:body/w:tbl', namespace)[1:] if not text(table).startswith('通行术语')]
check('all_original_tables_retained', len(source_tables) == len(tables))
number_pattern = re.compile(r'[−-]?\d+(?:\.\d+)?')
numeric_cells = 0
for table_index, (original, updated) in enumerate(zip(source_tables, tables)):
    original_rows = original.findall('w:tr', namespace)
    updated_rows = updated.findall('w:tr', namespace)
    check(f'table_{table_index}_rows', len(original_rows) == len(updated_rows))
    for row_index, (original_row, updated_row) in enumerate(zip(original_rows[1:], updated_rows[1:]), 1):
        for column, (original_cell, updated_cell) in enumerate(zip(original_row.findall('w:tc', namespace), updated_row.findall('w:tc', namespace))):
            original_text = text(original_cell)
            if re.fullmatch(r'[\d.−+\-%,/；：\[\]（）—\s]+', original_text) and re.search(r'\d', original_text):
                check(f'table_{table_index}_row_{row_index}_column_{column}', number_pattern.findall(original_text) == number_pattern.findall(text(updated_cell)))
                numeric_cells += 1


def equations(document):
    result = {}
    for paragraph in document.findall('./w:body/w:p', namespace):
        match = re.search(r'\(([2-5]-\d+)\)$', text(paragraph))
        if match and paragraph.findall('m:oMath', namespace):
            result[match[1]] = paragraph.findall('m:oMath', namespace)
    return result


def math_tree(element, normalize_algorithms=False):
    value = element.text or ''
    if normalize_algorithms:
        value = value.replace('KeyGen', 'G').replace('Encaps', 'E').replace('Decaps', 'D')
    return (element.tag, sorted(element.attrib.items()), value,
            [math_tree(child, normalize_algorithms) for child in element if child.tag != '{' + namespace['w'] + '}rPr'])

original_equations = equations(source_root)
updated_equations = equations(root)
check('numbered_equations_retained', original_equations.keys() == updated_equations.keys())
for label in original_equations:
    check('equation_' + label, [math_tree(element, True) for element in original_equations[label]] == [math_tree(element) for element in updated_equations[label]])
blips = root.findall('.//a:blip', namespace)
check('20_figures_plus_official_logo', len(blips) == 21)
relations = {item.get('Id'): item.get('Target') for item in etree.fromstring(candidate['word/_rels/document.xml.rels'])}
embedded_hashes = [hashlib.sha256(candidate['word/' + relations[blip.get('{' + namespace['r'] + '}embed')]]).hexdigest() for blip in blips]
figure_manifest = json.loads((Path(__file__).parent / 'figure-manifest.json').read_text())
for figure in figure_manifest:
    check('embedded_figure_' + figure['figure'], figure['sha256']['png'] in embedded_hashes)
paragraphs = root.findall('./w:body/w:p', namespace)
main_paragraphs = []
in_main = False
for paragraph in root.find('w:body', namespace):
    if text(paragraph).startswith('第1章'):
        in_main = True
    if text(paragraph) == '参考文献':
        in_main = False
    if in_main:
        main_paragraphs.append(text(paragraph))
main = '\n'.join(main_paragraphs)
check('no_editorial_glossary', '主要术语及本文含义' not in main and '术语只在' not in main)
check('no_system_calls_or_shell_options_in_main', not re.search(r'\b(open|read|close|taskset)\b|\-O2|\-DNDEBUG', main))
check('no_code_functions_in_main', not re.search(r'\b[a-z]+_[a-z_]+\b|compute_interval|\bKeyGen\b|\bEncaps\b|\bDecaps\b|\bCLI\b', main))
check('retired_jargon_absent', not any(term in main for term in ['数据资格', '统计资格', '弱均值', '成本边界', '几何覆盖', '后赋标签', '部分签收']))
all_text = text(root)
check('anonymous_report', not re.search(r'/Users/|/home/nss|Gowin-liuyin|yinhaoran0808|10\.144\.144\.', all_text))
check('four_explicit_screenshot_placeholders', all_text.count('待插入真实截图') == 4)
references = [text(paragraph) for paragraph in paragraphs if re.match(r'^\[\d+\]', text(paragraph))]
check('reference_sequence', [int(re.match(r'^\[(\d+)\]', value)[1]) for value in references] == list(range(1, 23)))
bookmark_names = set(root.xpath('.//w:bookmarkStart/@w:name', namespaces=namespace))
anchors = root.xpath('.//w:hyperlink/@w:anchor', namespaces=namespace)
check('all_toc_links_resolve', len(anchors) == 50 and set(anchors) <= bookmark_names)
source_chars = len(text(source_root))
candidate_chars = len(all_text)
result = {'checks': checks, 'check_count': len(checks), 'numeric_cells': numeric_cells,
          'numbered_equations': len(original_equations), 'figures': len(figure_manifest),
          'source_characters': source_chars, 'candidate_characters': candidate_chars,
          'no_new_experiments': True, 'visual_review_separate': True}
(work / 'verification.json').write_text(json.dumps(result, ensure_ascii=False, indent=2))
print(json.dumps({key: value for key, value in result.items() if key != 'checks'}))
