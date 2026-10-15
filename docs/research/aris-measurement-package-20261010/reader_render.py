"""本次43份匿名研究文档的静态阅读器；只处理其已有Markdown写法。"""

import hashlib
import html
from html.parser import HTMLParser
import json
from pathlib import Path
import re
import subprocess
import sys
from urllib.parse import unquote, urlsplit
import xml.etree.ElementTree as element_tree
import zipfile


sys.dont_write_bytecode = True
ROOT = Path(__file__).resolve().parents[3]
DEPENDENCY = ROOT / 'build/aris-weak-package-20261010/dependency'
WHEEL_SHA256 = 'f089b6d75e85b937f99693c93e8c16c0804008672c3dd2a3d25affd36f238100'
HELPER = ROOT / 'docs/research/aris-weak-package-20261010/mathml.py'
HELPER_SHA256 = '3609788513b8f9c74c015d196492de9be2bf9e3b7105557f08797214f1e7c853'
MATH_NAMESPACE = 'http://www.w3.org/1998/Math/MathML'
VISIBLE_TEX = re.compile(r'\\[A-Za-z]{2,}|\$')
TOKEN = re.compile(r'@@(?:MATH|CODE|INLINE_CODE)_\d+@@')
LINK = re.compile(r'\[([^\]]+)\]\(([^)]+)\)')
element_tree.register_namespace('', MATH_NAMESPACE)


def digest(contents):
    if isinstance(contents, str):
        contents = contents.encode()
    return hashlib.sha256(contents).hexdigest()


def require(condition, label):
    if not condition:
        raise ValueError(label)


def safe_href(value, local_only=False):
    require(isinstance(value, str) and value, 'empty_reader_link')
    decoded = html.unescape(unquote(value))
    parsed = urlsplit(decoded)
    require(not any(character in decoded for character in ('\\', '\n', '\r', '\x00')),
            'unsafe_reader_link_character')
    if parsed.scheme or parsed.netloc:
        require(not local_only and parsed.scheme in ('https', 'http') and bool(parsed.netloc),
                'unsafe_or_external_reader_resource')
    else:
        require(not decoded.startswith('/'), 'absolute_reader_link')
    return html.escape(value, quote=True)


def extract(markdown):
    """先保护围栏及行内代码，再按原顺序登记数学片段。"""
    require(isinstance(markdown, str) and not TOKEN.search(markdown), 'invalid_markdown_or_token_collision')
    parts = []
    formulas = []
    codes = []
    source_index = 0
    while source_index < len(markdown):
        at_line_start = source_index == 0 or markdown[source_index - 1] == '\n'
        fence = re.match(r' {0,3}(`{3,}|~{3,})[^\n]*(?:\n|$)', markdown[source_index:]) if at_line_start else None
        if fence:
            content_start = source_index + fence.end()
            closing = re.compile(r'^ {0,3}' + re.escape(fence[1][0]) + '{' + str(len(fence[1]))
                                 + r',}[ \t]*(?:\n|$)', re.M).search(markdown, content_start)
            require(closing is not None, 'unterminated_code_fence')
            code_index = len(codes)
            codes.append({'kind': 'fenced', 'text': markdown[content_start:closing.start()]})
            parts.append(f'@@CODE_{code_index}@@\n')
            source_index = closing.end()
            continue
        if markdown[source_index] == '`':
            delimiter = re.match(r'`+', markdown[source_index:])[0]
            ending = markdown.find(delimiter, source_index + len(delimiter))
            require(ending >= 0, 'unterminated_inline_code')
            code_index = len(codes)
            codes.append({'kind': 'inline', 'text': markdown[source_index + len(delimiter):ending]})
            parts.append(f'@@INLINE_CODE_{code_index}@@')
            source_index = ending + len(delimiter)
            continue
        if markdown[source_index] == '$' and (source_index == 0 or markdown[source_index - 1] != '\\'):
            display = markdown.startswith('$$', source_index)
            delimiter = '$$' if display else '$'
            content_start = source_index + len(delimiter)
            ending = markdown.find(delimiter, content_start)
            while ending > 0 and markdown[ending - 1] == '\\':
                ending = markdown.find(delimiter, ending + len(delimiter))
            require(ending >= 0 and (display or '\n' not in markdown[content_start:ending]),
                    'unterminated_math_delimiter')
            tex = markdown[content_start:ending]
            require(bool(tex.strip()), 'empty_math_expression')
            formula_index = len(formulas)
            formulas.append({'index': formula_index, 'tex': tex, 'display': display,
                             'tex_sha256': digest(tex), 'source_start': source_index,
                             'source_end': ending + len(delimiter)})
            token = f'@@MATH_{formula_index}@@'
            parts.append('\n\n' + token + '\n\n' if display else token)
            source_index = ending + len(delimiter)
            continue
        parts.append(markdown[source_index])
        source_index += 1
    return ''.join(parts), formulas, codes


def validate_math(mathml):
    math = element_tree.fromstring(mathml)
    require(math.tag == '{' + MATH_NAMESPACE + '}math', 'incorrect_mathml_namespace')
    require(math.get('display') in ('block', 'inline'), 'incorrect_mathml_display')

    def walk(node):
        local_name = node.tag.rsplit('}', 1)[-1]
        require(local_name != 'merror', 'mathml_merror')
        if local_name in ('annotation', 'annotation-xml'):
            return
        require(not VISIBLE_TEX.search(node.text or ''), 'visible_tex_inside_mathml')
        for child in node:
            walk(child)
            require(not VISIBLE_TEX.search(child.tail or ''), 'visible_tex_inside_mathml')

    walk(math)
    return math


def conversion_source(tex):
    operations = []

    def label(match):
        replacement = r'\quad\text{(' + match[1] + ')}'
        operations.append({'kind': 'equation_tag_display', 'original': match[0],
                           'replacement': replacement})
        return replacement

    converted_tex = re.sub(r'\\tag\{([A-Za-z0-9]+)\}', label, tex)
    return converted_tex, operations


def convert(formulas, dependency_directory=None):
    wheel = DEPENDENCY / 'latex2mathml-3.78.1-py3-none-any.whl'
    unpacked = Path(dependency_directory) if dependency_directory is not None else DEPENDENCY / 'unpacked'
    require(unpacked.is_absolute() and unpacked.is_dir(), 'fixed_math_dependency_unavailable')
    require(not any(unpacked.rglob('*.pyc')), 'fixed_math_dependency_has_unbound_bytecode')
    require(wheel.is_file() and digest(wheel.read_bytes()) == WHEEL_SHA256, 'fixed_math_wheel_identity')
    with zipfile.ZipFile(wheel) as archive:
        for member in archive.infolist():
            require((unpacked / member.filename).is_file()
                    and (unpacked / member.filename).read_bytes() == archive.read(member),
                    'fixed_unpacked_math_dependency_identity')
    require(digest(HELPER.read_bytes()) == HELPER_SHA256, 'immutable_math_helper_changed')
    if not formulas:
        return []
    result = subprocess.run([sys.executable, '-I', '-B', str(HELPER), str(unpacked)],
                            input=json.dumps([{'tex': conversion_source(row['tex'])[0], 'display': row['display']}
                                              for row in formulas]),
                            text=True, capture_output=True, timeout=30)
    require(result.returncode == 0, 'fixed_math_conversion_rejected: ' + result.stderr.strip())
    converted = json.loads(result.stdout)
    require(isinstance(converted, list) and len(converted) == len(formulas), 'formula_conversion_count')
    for formula_index, (row, mathml) in enumerate(zip(formulas, converted)):
        math = validate_math(mathml)
        require(math.get('display') == ('block' if row['display'] else 'inline'), 'formula_display_changed')
        annotation = math.find('.//{' + MATH_NAMESPACE + '}annotation')
        require(annotation is not None, 'converter_tex_annotation_missing')
        annotation.text = row['tex']
        converted[formula_index] = element_tree.tostring(math, encoding='unicode')
    return converted


def plain_inline(value, codes):
    value = LINK.sub(lambda match: match[1], value)
    value = re.sub(r'\*\*([^*]+)\*\*', r'\1', value)
    for code_index, code in enumerate(codes):
        value = value.replace(f'@@INLINE_CODE_{code_index}@@', code['text'])
    return value


def source_sequence(protected, formulas, codes):
    prose = []
    for line in protected.splitlines():
        code = re.fullmatch(r'@@CODE_(\d+)@@', line)
        if code:
            prose.append(codes[int(code[1])]['text'])
            continue
        if line.startswith('|'):
            cells = line.strip().strip('|').split('|')
            if all(re.fullmatch(r'[:\-\s]+', cell) for cell in cells):
                continue
            line = ''.join(cells)
        line = re.sub(r'^#{1,6}\s+', '', line)
        line = plain_inline(line, codes)
        for row in formulas:
            line = line.replace(f'@@MATH_{row["index"]}@@', 'MATHEXPR_' + row['mathml_sha256'])
        prose.append(line)
    return re.sub(r'\s+', '', '\n'.join(prose))


def table_shapes(protected):
    shapes = []
    pending = []
    for line in protected.splitlines() + ['']:
        if line.startswith('|'):
            cells = line.strip().strip('|').split('|')
            if not all(re.fullmatch(r'[:\-\s]+', cell) for cell in cells):
                pending.append(len(cells))
            continue
        if pending:
            shapes.append([['th' if row_index == 0 else 'td'] * columns
                           for row_index, columns in enumerate(pending)])
            pending.clear()
    return shapes


def render(markdown, markdown_href, root_css='../../reader.css', root_index='../../index.html',
           dependency_directory=None):
    """返回HTML字节和逐公式、代码、正文顺序的绑定信息；不改写给定链接。"""
    protected, formulas, codes = extract(markdown)
    converted = convert(formulas, dependency_directory)
    for row, mathml in zip(formulas, converted):
        row['mathml_sha256'] = digest(mathml)
        converted_tex, operations = conversion_source(row['tex'])
        row['conversion_tex_sha256'] = digest(converted_tex)
        row['conversion_operations'] = operations

    def inline(value):
        value = html.escape(value)
        value = LINK.sub(lambda match: '<a href="' + safe_href(html.unescape(match[2]))
                         + '">' + match[1] + '</a>', value)
        value = re.sub(r'\*\*([^*]+)\*\*', r'<strong>\1</strong>', value)
        for code_index, code in enumerate(codes):
            value = value.replace(f'@@INLINE_CODE_{code_index}@@',
                                  '<code>' + html.escape(code['text']) + '</code>')
        for formula_index, mathml in enumerate(converted):
            value = value.replace(f'@@MATH_{formula_index}@@', mathml)
        return value

    parts = []
    paragraph = []
    table = []
    heading_count = 0

    def flush_paragraph():
        if paragraph:
            parts.append('<p>' + inline(' '.join(paragraph)) + '</p>')
            paragraph.clear()

    def flush_table():
        if not table:
            return
        rows = [line.strip().strip('|').split('|') for line in table]
        rows = [row for row in rows if not all(re.fullmatch(r'[:\-\s]+', cell) for cell in row)]
        require(bool(rows) and all(len(row) == len(rows[0]) for row in rows), 'inconsistent_markdown_table')
        parts.append('<div class="table-wrap"><table><thead><tr>'
                     + ''.join('<th>' + inline(cell.strip()) + '</th>' for cell in rows[0])
                     + '</tr></thead><tbody>'
                     + ''.join('<tr>' + ''.join('<td>' + inline(cell.strip()) + '</td>' for cell in row)
                               + '</tr>' for row in rows[1:]) + '</tbody></table></div>')
        table.clear()

    for line in protected.splitlines():
        if line.startswith('|'):
            flush_paragraph()
            table.append(line)
            continue
        flush_table()
        if not line.strip():
            flush_paragraph()
            continue
        code = re.fullmatch(r'@@CODE_(\d+)@@', line)
        if code:
            flush_paragraph()
            parts.append('<pre><code>' + html.escape(codes[int(code[1])]['text']) + '</code></pre>')
            continue
        heading = re.match(r'^(#{1,6})\s+(.*)', line)
        if heading:
            flush_paragraph()
            heading_count += 1
            parts.append(f'<h{len(heading[1])} id="section-{heading_count}">'
                         + inline(heading[2]) + f'</h{len(heading[1])}>')
        elif re.fullmatch(r'@@MATH_\d+@@', line):
            flush_paragraph()
            parts.append('<div class="math display">' + inline(line) + '</div>')
        else:
            paragraph.append(line)
    flush_paragraph()
    flush_table()
    title = markdown.splitlines()[0].lstrip('# ') if markdown.splitlines() else '研究材料'
    page = ('<!doctype html><html lang="zh-CN"><head><meta charset="utf-8">'
            '<meta name="viewport" content="width=device-width,initial-scale=1"><title>'
            + html.escape(title) + '</title><link rel="stylesheet" href="' + safe_href(root_css, True)
            + '"></head><body><main class="reading"><nav><a href="' + safe_href(root_index, True)
            + '">返回新版材料索引</a> · <a href="' + safe_href(markdown_href, True)
            + '">Markdown匿名视图</a></nav><article>' + ''.join(parts)
            + '</article></main></body></html>').encode()
    sequence = source_sequence(protected, formulas, codes)
    audit = {'format': 'offline_scientific_reader_v1', 'markdown_sha256': digest(markdown),
             'html_sha256': digest(page), 'formulas': formulas,
             'article_sequence_sha256': digest(sequence),
             'formula_sequence_sha256': digest(json.dumps([row['mathml_sha256'] for row in formulas])),
             'code_sequence': [{'kind': row['kind'], 'sha256': digest(row['text'])} for row in codes],
             'heading_levels': [len(match[1]) for match in re.finditer(r'^(#{1,6})\s+', protected, re.M)],
             'table_shapes': table_shapes(protected),
             'math_conversion_semantics_independently_certified': False}
    verify_reader(markdown, page, audit)
    return page, audit


class Article(HTMLParser):
    def __init__(self):
        super().__init__(convert_charrefs=True)
        self.in_article = False
        self.article_count = 0
        self.text = []
        self.heading_levels = []
        self.code_sequence = []
        self.code_text = None
        self.in_pre = False
        self.table_shapes = []
        self.table = None
        self.table_row = None

    def handle_starttag(self, tag, attributes):
        attributes = dict(attributes)
        require(tag not in ('script', 'iframe', 'object', 'embed', 'applet', 'base', 'style'),
                'active_reader_element')
        require(not any(name.startswith('on') for name in attributes), 'reader_event_attribute')
        require('srcdoc' not in attributes and 'style' not in attributes, 'reader_inline_runtime_or_style')
        require(not (tag == 'meta' and attributes.get('http-equiv', '').lower() == 'refresh'),
                'reader_refresh')
        for name in ('href', 'src', 'poster', 'data', 'xlink:href'):
            if name in attributes:
                safe_href(attributes[name], local_only=not (tag == 'a' and name == 'href'))
        if tag == 'article':
            require(not self.in_article, 'nested_reader_article')
            self.article_count += 1
            self.in_article = True
        if self.in_article:
            if re.fullmatch(r'h[1-6]', tag):
                self.heading_levels.append(int(tag[1]))
            if tag == 'pre':
                self.in_pre = True
            if tag == 'code':
                require(self.code_text is None, 'nested_reader_code')
                self.code_text = []
            if tag == 'table':
                require(self.table is None, 'nested_reader_table')
                self.table = []
            if tag == 'tr':
                require(self.table is not None and self.table_row is None, 'reader_table_row_outside_table')
                self.table_row = []
            if tag in ('th', 'td'):
                require(self.table_row is not None, 'reader_table_cell_outside_row')
                self.table_row.append(tag)

    def handle_endtag(self, tag):
        if tag == 'code' and self.in_article:
            require(self.code_text is not None, 'unmatched_reader_code')
            self.code_sequence.append({'kind': 'fenced' if self.in_pre else 'inline',
                                       'sha256': digest(''.join(self.code_text))})
            self.code_text = None
        if tag == 'pre':
            self.in_pre = False
        if tag == 'tr' and self.in_article:
            require(self.table_row is not None, 'unmatched_reader_table_row')
            self.table.append(self.table_row)
            self.table_row = None
        if tag == 'table' and self.in_article:
            require(self.table is not None and self.table_row is None, 'unmatched_reader_table')
            self.table_shapes.append(self.table)
            self.table = None
        if tag == 'article':
            self.in_article = False

    def handle_data(self, value):
        if self.in_article:
            self.text.append(value)
            if self.code_text is not None:
                self.code_text.append(value)
            else:
                require(not VISIBLE_TEX.search(value), 'visible_tex_outside_math_or_code')


def verify_reader(markdown, html_contents, audit):
    """独立核对源片段、实际MathML顺序、代码原值与完整正文序列。"""
    if isinstance(html_contents, bytes):
        html_contents = html_contents.decode()
    require(audit['markdown_sha256'] == digest(markdown) and audit['html_sha256'] == digest(html_contents),
            'reader_source_or_html_digest')
    protected, formulas, codes = extract(markdown)
    rows = audit['formulas']
    require(formulas == [{key: row[key] for key in ('index', 'tex', 'display', 'tex_sha256',
                                                   'source_start', 'source_end')} for row in rows],
            'reader_formula_source_sequence')
    actual_math = re.findall(r'<math\b[^>]*>.*?</math>', html_contents, flags=re.S)
    require(len(actual_math) == len(rows), 'reader_actual_math_count')
    for row, mathml in zip(rows, actual_math):
        math = validate_math(mathml)
        require(digest(mathml) == row['mathml_sha256'], 'reader_formula_digest_or_order')
        require(math.get('display') == ('block' if row['display'] else 'inline'), 'reader_formula_display')
        annotation = math.find('.//{' + MATH_NAMESPACE + '}annotation')
        require(annotation is not None and annotation.text == row['tex'], 'reader_formula_tex_annotation')
        converted_tex, operations = conversion_source(row['tex'])
        require(row['conversion_tex_sha256'] == digest(converted_tex)
                and row['conversion_operations'] == operations, 'reader_formula_conversion_operations')
    formula_hashes = [row['mathml_sha256'] for row in rows]
    require(audit['formula_sequence_sha256'] == digest(json.dumps(formula_hashes)),
            'reader_formula_sequence_digest')
    substituted = html_contents
    for row, mathml in zip(rows, actual_math):
        substituted = substituted.replace(mathml, '<span>MATHEXPR_' + row['mathml_sha256'] + '</span>', 1)
    parser = Article()
    parser.feed(substituted)
    parser.close()
    require(parser.article_count == 1 and not parser.in_article, 'reader_article_missing_or_unclosed')
    expected = source_sequence(protected, rows, codes)
    require(re.sub(r'\s+', '', ''.join(parser.text)) == expected
            and audit['article_sequence_sha256'] == digest(expected), 'reader_complete_prose_or_formula_position')
    expected_codes = [{'kind': row['kind'], 'sha256': digest(row['text'])} for row in codes]
    require(parser.code_sequence == audit['code_sequence'] == expected_codes, 'reader_code_changed')
    expected_headings = [len(match[1]) for match in re.finditer(r'^(#{1,6})\s+', protected, re.M)]
    require(parser.heading_levels == audit['heading_levels'] == expected_headings, 'reader_heading_order')
    require(parser.table_shapes == audit['table_shapes'] == table_shapes(protected), 'reader_table_shape_or_order')
    return {'status': 'passed', 'formulas': len(rows), 'code_spans_or_blocks': len(codes),
            'complete_prose_and_formula_positions_verified': True}


def self_check():
    fixture = ('# 阅读夹具\n\n首段$x$与`$unchanged$`。\n\n'
               '| 列 | 式 |\n|---|---|\n| 保留 | $|x|$ |\n\n'
               '$$\\frac{1}{2}\\tag{F1}$$\n\n'
               '```sh\nprintf \'$PWD $$ $x$ \\n\'\n```\n\n末段[来源](../source.html)。\n')
    page, audit = render(fixture, 'SOURCE.md')
    assert len(audit['formulas']) == 3
    assert [row['display'] for row in audit['formulas']] == [False, False, True]
    assert len(audit['code_sequence']) == 2
    assert audit['formulas'][2]['conversion_operations'][0]['original'] == r'\tag{F1}'
    assert '$unchanged$' in page.decode() and '$PWD $$ $x$' in page.decode()
    assert '<script' not in page.decode() and '<merror' not in page.decode()
    negative_checks = []
    actual_math = re.findall(r'<math\b[^>]*>.*?</math>', page.decode(), flags=re.S)
    swapped = page.decode().replace(actual_math[0], '@@SWAP@@', 1).replace(actual_math[1], actual_math[0], 1)
    swapped = swapped.replace('@@SWAP@@', actual_math[1], 1)
    for label, changed in (
            ('removed_prose', page.decode().replace('首段', '删段', 1)),
            ('active_html', page.decode().replace('</article>', '<script>bad()</script></article>', 1)),
            ('changed_code_dollar', page.decode().replace('$PWD', '$OTHER', 1)),
            ('changed_heading_level', page.decode().replace('<h1 ', '<h2 ', 1)),
            ('changed_table_cell_role', page.decode().replace('<th>', '<td>', 1)),
            ('swapped_math_position', swapped)):
        changed_audit = dict(audit, html_sha256=digest(changed))
        try:
            verify_reader(fixture, changed, changed_audit)
        except ValueError:
            negative_checks.append(label)
        else:
            raise AssertionError('accepted_negative_' + label)
    for label, value in (('unterminated_fence', '# X\n```sh\n$PWD\n'),
                         ('unterminated_math', '# X\n$x\n'),
                         ('javascript_link', '# X\n[bad](javascript:bad)\n')):
        try:
            render(value, 'SOURCE.md')
        except ValueError:
            negative_checks.append(label)
        else:
            raise AssertionError('accepted_negative_' + label)
    return {'self_check': 'passed', 'formula_count': 3, 'code_count': 2,
            'negative_checks': negative_checks, 'network_or_C_or_hardware_execution': False}


if __name__ == '__main__':
    require(sys.argv[1:] == ['--self-check'], 'usage_reader_render_py_self_check')
    print(json.dumps(self_check(), ensure_ascii=False))
