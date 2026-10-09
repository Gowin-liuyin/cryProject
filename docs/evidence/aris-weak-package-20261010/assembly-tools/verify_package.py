import argparse
from collections import Counter
import hashlib
from html import unescape
from html.parser import HTMLParser
import io
import json
from pathlib import Path, PurePosixPath
import posixpath
import re
import stat
from urllib.parse import unquote, urlsplit
import zipfile

from lxml import etree
from pypdf import PdfReader


REPOSITORY = Path(__file__).resolve().parents[3]
OLD_ARCHIVE = REPOSITORY / 'deliverables/support/CACR2026EA16XZ-aris-current-20261009/CACR2026EA16XZ-当前研究报告与数学复核补充件.zip'
OLD_SHA256 = '327e5221d691e43f10eb85888a2021751ebdd3046769f710d4933c29e885b2eb'
HISTORY_PREFIX = 'historical/20261009/'
REPORT_ROOT = REPOSITORY / 'deliverables/research/aris-report-weak-mean-20261010'
PRIVATE_MAP = REPOSITORY / 'docs/evidence/aris-current-package-20261009/private-substitution-map.json'
PROOF_SOURCE = REPOSITORY / 'docs/research/aris-replication-20261009/WEAK_MEAN_PROOF_PACKAGE.md'
PROTOCOL_SOURCE = REPOSITORY / 'docs/research/aris-replication-20261009/NEXT_VALIDATION_PROTOCOL.md'
MAX_MEMBER_BYTES = 256 * 1024 * 1024
MAX_SCANNED_BYTES = 1024 * 1024 * 1024


def digest(contents):
    return hashlib.sha256(contents).hexdigest()


class Rejected(Exception):
    pass


def require(condition, label):
    if not condition:
        raise Rejected(label)


def safe_member(name):
    require(name and '\\' not in name and '\x00' not in name, 'unsafe_member_name')
    require(not any(ord(character) < 32 or ord(character) == 127 for character in name),
            'control_character_in_member')
    path = PurePosixPath(name)
    require(not path.is_absolute() and all(part not in ('', '.', '..') for part in name.split('/')),
            'unsafe_member_path')
    require(not re.match(r'^[A-Za-z]:', name), 'drive_member_path')


def protocol_view(private_records):
    retained_prefixes = {
        '当前恢复预检的Linux连接': '必须取得适合新目标的实际资源资格',
        '运行状态补记：': 'B1—B5的资源、目标、真值、有效方法及预算门槛保持',
        '2026-10-10补记：': '上述B1—B5的科学资格不由文件维护或软件自检替代',
    }
    source = PROTOCOL_SOURCE.read_text()
    paragraphs = []
    operations = []
    matched_prefixes = set()
    for paragraph in source.split('\n\n'):
        matched = next((prefix for prefix in retained_prefixes if paragraph.startswith(prefix)), None)
        if matched is None:
            paragraphs.append(paragraph)
            continue
        require(matched not in matched_prefixes, 'duplicate_administrative_source_paragraph')
        matched_prefixes.add(matched)
        marker = retained_prefixes[matched]
        require(paragraph.count(marker) == 1, 'scientific_suffix_boundary_changed')
        boundary = paragraph.index(marker)
        retained = paragraph[boundary:]
        paragraphs.append(retained)
        operations.append({'kind': 'omit_admin_prefix_keep_scientific_suffix',
                           'paragraph_sha256': digest(paragraph.encode()), 'keep_from': marker,
                           'removed_prefix_sha256': digest(paragraph[:boundary].encode()),
                           'retained_suffix_sha256': digest(retained.encode())})
    require(matched_prefixes == set(retained_prefixes), 'administrative_source_paragraphs_changed')
    view = '\n\n'.join(paragraphs)
    anchor = '# R02与R04下一阶段的防御性验证协议\n'
    notice = ('本文件为匿名公开技术视图，原件摘要另列；省略认证及存储维护历史，不把可登录机器当作资源或统计资格。'
              '科学对象、B1—B5、完整长尾、功效及预算门槛保持。')
    require(view.count(anchor) == 1, 'protocol_notice_anchor_changed')
    view = view.replace(anchor, anchor + '\n' + notice + '\n', 1)
    operations.append({'kind': 'insert_public_view_notice', 'after': anchor, 'text': notice,
                       'text_sha256': digest(notice.encode())})
    replacements = {
        '../aris-20261008/PROOF_PACKAGE.md': '../historical/20261009/research/PROOF_PACKAGE.md',
        '../aris-20261008/FINITE_REFERENCE_BOUNDARY.md': '../historical/20261009/research/FINITE_REFERENCE_BOUNDARY.md',
        '../aris-20261008/DEEP_READING.md': '../historical/20261009/research/DEEP_READING.md',
        '[旧研究合同](../aris-20261008/EXPERIMENT_PLAN.md)':
        '2026-10-08旧研究合同（原件未随本匿名技术视图新增；其停止路线和旧预算保持）',
    }
    for original, replacement in replacements.items():
        count = view.count(original)
        require(count > 0, 'protocol_link_source_changed')
        view = view.replace(original, replacement)
        operations.append({'kind': 'reading_link_or_explicit_omission', 'from': original,
                           'to': replacement, 'count': count})
    for record in private_records:
        pattern = re.escape(record['original'])
        if record['role'].startswith('own_source'):
            pattern = r'(?<![A-Za-z0-9])' + pattern + r'(?![A-Za-z0-9])'
        view, count = re.subn(pattern, lambda match: record['replacement'], view)
        if count:
            operations.append({'kind': 'anonymous_identity_view',
                               'marker_sha256': digest(record['original'].encode()),
                               'role': record['role'], 'replacement': record['replacement'], 'count': count})
    return view.encode(), operations


def formulas_and_prose(markdown):
    expressions = []

    def protect(match, display):
        index = len(expressions)
        expressions.append({'tex_sha256': digest(match.group(1).encode()), 'display': display})
        return '@@MATH_' + str(index) + '@@'

    protected = re.sub(r'\$\$(.*?)\$\$', lambda match: protect(match, True), markdown, flags=re.S)
    protected = re.sub(r'(?<!\\)\$([^$\n]+?)(?<!\\)\$', lambda match: protect(match, False), protected)
    return expressions, protected


def normalized_prose(value):
    return re.sub(r'\s+', '', unescape(value))


class Page(HTMLParser):
    def __init__(self):
        super().__init__(convert_charrefs=True)
        self.identifiers = set()
        self.references = []
        self.problems = []
        self.math_depth = 0
        self.style_depth = 0
        self.math_count = 0
        self.merror_count = 0
        self.visible_text = []

    def handle_starttag(self, tag, attributes):
        attributes = dict(attributes)
        if tag in ('script', 'iframe', 'object', 'embed', 'applet', 'base'):
            self.problems.append('active_or_base_element')
        if tag == 'meta' and attributes.get('http-equiv', '').lower() == 'refresh':
            self.problems.append('meta_refresh')
        if 'srcdoc' in attributes:
            self.problems.append('inline_subdocument')
        if tag == 'math':
            self.math_depth += 1
            self.math_count += 1
        if tag == 'merror':
            self.merror_count += 1
        if tag == 'style':
            self.style_depth += 1
        identifiers = {value for name, value in attributes.items()
                       if name == 'id' or (tag == 'a' and name == 'name')}
        for value in identifiers:
            if value in self.identifiers:
                self.problems.append('duplicate_identifier')
            self.identifiers.add(value)
        for name, value in attributes.items():
            if name.startswith('on'):
                self.problems.append('event_attribute')
            if name in ('href', 'src', 'poster', 'data', 'xlink:href') and value:
                self.references.append((value, tag == 'a' and name == 'href'))
            if name == 'srcset' and value:
                for candidate in value.split(','):
                    self.references.append((candidate.strip().split()[0], False))
            if name == 'style' and value and forbidden_css(value):
                self.problems.append('css_runtime_reference')

    def handle_startendtag(self, tag, attributes):
        self.handle_starttag(tag, attributes)
        self.handle_endtag(tag)

    def handle_endtag(self, tag):
        if tag == 'math':
            self.math_depth = max(0, self.math_depth - 1)
        if tag == 'style':
            self.style_depth = max(0, self.style_depth - 1)

    def handle_data(self, value):
        if self.style_depth and forbidden_css(value):
            self.problems.append('css_runtime_reference')
        if not self.math_depth and not self.style_depth:
            self.visible_text.append(value)


def forbidden_css(value):
    value = re.sub(r'/\*.*?\*/', '', value, flags=re.S)
    value = re.sub(r'\\([0-9a-fA-F]{1,6})\s?|\\([^\r\n])',
                   lambda match: chr(int(match.group(1), 16)) if match.group(1) else match.group(2),
                   value)
    return bool(re.search(r'@import\b|url\s*\(', value, re.I))


class Audit:
    def __init__(self):
        records = json.loads(PRIVATE_MAP.read_text())
        require(len(records) == 262, 'private_marker_count_changed')
        self.private_records = records
        self.markers = []
        for record in records:
            original = record['original']
            boundary = 'own_source' in record['role']
            expression = re.escape(original)
            if boundary:
                expression = r'(?<![A-Za-z0-9])' + expression + r'(?![A-Za-z0-9])'
            self.markers.append((original, re.compile(expression), digest(original.encode())))
        self.result = {'status': 'failed', 'whole_goal_complete': False,
                       'scope': 'offline_reading_closure_and_direct_string_privacy_only',
                       'private_markers_checked': len(self.markers), 'privacy_hits': [],
                       'errors': [], 'nested_archives_checked': 0, 'pdfs_scanned': 0,
                       'html_pages_checked': 0, 'native_mathml': 0, 'merror': 0,
                       'latex_residual_locations': [], 'local_links_checked': 0}
        self.scanned_bytes = 0

    def public_location(self, location):
        for original, expression, marker_sha256 in self.markers:
            if original in location:
                location = expression.sub('<marker-' + marker_sha256[:12] + '>', location)
        return location

    def error(self, label, location=''):
        self.result['errors'].append({'check': label, 'location': self.public_location(location)})

    def scan_text(self, value, location):
        variants = {value, unescape(unquote(value))}
        for original, expression, marker_sha256 in self.markers:
            if any(original in candidate and expression.search(candidate) for candidate in variants):
                hit = {'location': self.public_location(location), 'marker_sha256': marker_sha256}
                if hit not in self.result['privacy_hits']:
                    self.result['privacy_hits'].append(hit)

    def scan(self, contents, location, depth=0):
        require(depth <= 6, 'nested_archive_depth_exceeded')
        self.scanned_bytes += len(contents)
        require(self.scanned_bytes <= MAX_SCANNED_BYTES, 'scan_byte_budget_exceeded')
        self.scan_text(location, location + ':member_name')
        self.scan_text(contents.decode('utf-8', errors='ignore'), location + ':bytes')
        if contents.startswith(b'%PDF-'):
            reader = PdfReader(io.BytesIO(contents))
            require(not reader.is_encrypted, 'encrypted_pdf_cannot_scan')
            self.result['pdfs_scanned'] += 1
            self.scan_text(str(dict(reader.metadata or {})), location + ':pdf_metadata')
            metadata = reader.trailer['/Root'].get('/Metadata')
            if metadata is not None:
                self.scan_text(metadata.get_object().get_data().decode('utf-8', errors='replace'),
                               location + ':pdf_xmp_metadata')
            for number, page in enumerate(reader.pages, 1):
                self.scan_text(page.extract_text() or '', location + ':page_' + str(number))
        if zipfile.is_zipfile(io.BytesIO(contents)):
            self.result['nested_archives_checked'] += 1
            with zipfile.ZipFile(io.BytesIO(contents)) as archive:
                entries = archive.infolist()
                require(len(entries) == len({entry.filename for entry in entries}), 'nested_duplicate_member')
                require(all(entry.file_size <= MAX_MEMBER_BYTES for entry in entries),
                        'nested_member_too_large')
                require(sum(entry.file_size for entry in entries) <= MAX_SCANNED_BYTES - self.scanned_bytes,
                        'nested_scan_byte_budget_exceeded')
                require(archive.testzip() is None, 'nested_crc_failed')
                for entry in entries:
                    if entry.is_dir():
                        safe_member(entry.filename.rstrip('/'))
                        continue
                    safe_member(entry.filename)
                    require(entry.file_size <= MAX_MEMBER_BYTES, 'nested_member_too_large')
                    require(not stat.S_ISLNK(entry.external_attr >> 16), 'nested_symlink')
                    require(PurePosixPath(entry.filename).name not in
                            ('rehearse_partition.py', 'rehearse.py', 'run-interactive.sh',
                             'bootstrap.py', 'relocate.py', 'private-substitution-map.json'),
                            'embedded_private_or_root_helper')
                    self.scan(archive.read(entry), location + '!/' + entry.filename, depth + 1)

    def verify_manifest(self, members):
        manifest = json.loads(members['manifest.json'])
        rows = manifest['files']
        records = {row['distributed_path']: row for row in rows}
        require(len(rows) == len(records), 'duplicate_manifest_record')
        require(set(records) == set(members) - {'manifest.json', 'SHA256SUMS'}, 'manifest_coverage')
        for name, record in records.items():
            require(record['distributed_copy_sha256'] == digest(members[name]), 'manifest_digest')
            require(record['distributed_byte_count'] == len(members[name]), 'manifest_byte_count')
        checksum_rows = {}
        for line in members['SHA256SUMS'].decode().splitlines():
            match = re.fullmatch(r'([0-9a-f]{64})  (.+)', line)
            require(match is not None, 'checksum_syntax')
            expected, name = match.groups()
            require(name not in checksum_rows, 'duplicate_checksum_record')
            checksum_rows[name] = expected
        require(set(checksum_rows) == set(members) - {'SHA256SUMS'}, 'checksum_coverage')
        require(all(digest(members[name]) == expected for name, expected in checksum_rows.items()),
                'checksum_digest')
        self.result.update(manifest_records=len(records), checksum_records=len(checksum_rows))
        return records

    def verify_html(self, members):
        pages = {}
        edges = {}
        for name, contents in members.items():
            if name.lower().endswith(('.html', '.htm')):
                page = Page()
                page.feed(contents.decode('utf-8'))
                page.close()
                pages[name] = page
                for problem in page.problems:
                    self.error(problem, name)
                self.result['native_mathml'] += page.math_count
                self.result['merror'] += page.merror_count
                visible = ''.join(page.visible_text)
                if re.search(r'\\(?:[A-Za-z]{2,}|[\[\]()])|(?<!\\)\$[^$\n]{1,200}\$', visible):
                    self.result['latex_residual_locations'].append(self.public_location(name))
                    self.error('visible_non_math_latex', name)
            if name.lower().endswith('.css') and forbidden_css(contents.decode('utf-8')):
                self.error('css_runtime_reference', name)
        for name, page in pages.items():
            for raw_url, navigation in page.references:
                parsed = urlsplit(unescape(raw_url))
                if parsed.scheme or parsed.netloc:
                    if not (navigation and parsed.scheme in ('http', 'https', 'mailto')):
                        self.error('remote_or_unsafe_runtime_reference', name)
                    continue
                decoded = unquote(parsed.path)
                if '\\' in decoded or decoded.startswith('/') or '\x00' in decoded:
                    self.error('unsafe_local_url', name)
                    continue
                target = posixpath.normpath(posixpath.join(posixpath.dirname(name), decoded)) if decoded else name
                self.result['local_links_checked'] += 1
                if target.startswith('../') or target not in members:
                    self.error('missing_local_target', name + ' -> ' + target)
                    continue
                edges.setdefault(name, set()).add(target)
                fragment = unquote(parsed.fragment)
                if fragment and target in pages and fragment not in pages[target].identifiers:
                    self.error('missing_fragment_identifier', name + ' -> ' + target + '#' + fragment)
        self.result['html_pages_checked'] = len(pages)
        self.result['latex_residual_count'] = len(self.result['latex_residual_locations'])
        require(self.result['merror'] == 0, 'mathml_merror')
        return pages, edges

    def verify_navigation(self, members, pages, edges):
        require('index.html' in pages and 'README.md' in members, 'current_entrypoint_missing')
        reachable = {'index.html'}
        pending = ['index.html']
        while pending:
            for target in edges.get(pending.pop(), ()):
                if target not in reachable:
                    reachable.add(target)
                    pending.append(target)
        required = {'report/CACR2026EA16XZ-作品设计报告.pdf',
                    'report/CACR2026EA16XZ-作品设计报告.docx',
                    HISTORY_PREFIX + 'research/PROOF_PACKAGE.html',
                    HISTORY_PREFIX + 'research/FINITE_REFERENCE_BOUNDARY.html'}
        for basename in ('WEAK_MEAN_PROOF_PACKAGE.html', 'NEXT_VALIDATION_PROTOCOL.html'):
            matches = [name for name in pages if not name.startswith(HISTORY_PREFIX)
                       and PurePosixPath(name).name == basename]
            require(len(matches) == 1, 'current_theory_html_missing_or_ambiguous')
            required.add(matches[0])
            if basename == 'WEAK_MEAN_PROOF_PACKAGE.html':
                require(pages[matches[0]].math_count > 0, 'current_proof_has_no_native_mathml')
        require(required.issubset(reachable), 'current_entrypoint_reachability')
        require('47' in members['README.md'].decode(), 'current_readme_report_edition')
        self.result['required_reading_targets_reachable'] = len(required)

    def verify_reports(self, members):
        checks = {}
        for extension in ('docx', 'pdf'):
            target = 'report/CACR2026EA16XZ-作品设计报告.' + extension
            expected = REPORT_ROOT / ('CACR2026EA16XZ-作品设计报告-匿名版.' + extension)
            require(members[target] == expected.read_bytes(), 'current_report_byte_identity')
            checks[extension] = digest(members[target])
        with zipfile.ZipFile(io.BytesIO(members['report/CACR2026EA16XZ-作品设计报告.docx'])) as report:
            core = etree.fromstring(report.read('docProps/core.xml'))
            for name in ('{http://purl.org/dc/elements/1.1/}creator',
                         '{http://schemas.openxmlformats.org/package/2006/metadata/core-properties}lastModifiedBy'):
                require(not (core.findtext(name) or '').strip(), 'docx_author_metadata')
            if 'docProps/custom.xml' in report.namelist():
                require(len(etree.fromstring(report.read('docProps/custom.xml'))) == 0, 'docx_custom_properties')
            app = etree.fromstring(report.read('docProps/app.xml'))
            require(app.findtext('{http://schemas.openxmlformats.org/officeDocument/2006/extended-properties}Pages') == '47',
                    'docx_page_cache')
        reader = PdfReader(io.BytesIO(members['report/CACR2026EA16XZ-作品设计报告.pdf']))
        require(len(reader.pages) == 47, 'actual_pdf_page_count')
        require(not str((reader.metadata or {}).get('/Author', '')).strip(), 'pdf_author_metadata')
        xmp = reader.xmp_metadata
        require(xmp is None or not getattr(xmp, 'dc_creator', None), 'pdf_xmp_author_metadata')
        self.result.update(current_report_sha256=checks, current_report_pages=47,
                           report_author_metadata_empty=True)

    def verify_theory(self, members, records):
        proof_names = [name for name in members if not name.startswith(HISTORY_PREFIX)
                       and PurePosixPath(name).name == 'WEAK_MEAN_PROOF_PACKAGE.md']
        require(len(proof_names) == 1 and members[proof_names[0]] == PROOF_SOURCE.read_bytes(),
                'proof_markdown_identity')
        protocol_names = [name for name in members if not name.startswith(HISTORY_PREFIX)
                          and PurePosixPath(name).name == 'NEXT_VALIDATION_PROTOCOL.md']
        require(len(protocol_names) == 1, 'public_protocol_view_missing_or_ambiguous')
        name = protocol_names[0]
        view = members[name].decode('utf-8')
        expected_view, expected_operations = protocol_view(self.private_records)
        require(members[name] == expected_view, 'protocol_view_reconstruction')
        require(all(marker in view for marker in ('B1', 'B2', 'B3', 'B4', 'B5', 'NOT_READY_TO_RUN')),
                'protocol_required_gates')
        require('视图' in view and '原件' in view and '匿名' in view, 'protocol_view_role_not_declared')
        record = records[name]
        source_sha256 = record.get('source_sha256', record.get('original_archive_sha256'))
        require(source_sha256 == digest(PROTOCOL_SOURCE.read_bytes()), 'protocol_source_digest')
        require(record['distributed_copy_sha256'] == digest(members[name]), 'protocol_view_digest')
        require(record.get('operations') == expected_operations, 'protocol_manifest_operations')
        expected_transformations = [{'source_path': str(PROTOCOL_SOURCE.relative_to(REPOSITORY)),
                                     'source_sha256': digest(PROTOCOL_SOURCE.read_bytes()),
                                     'distributed_path': name, 'operations': expected_operations}]
        require(json.loads(members['verification/reading-transformations.json']) == expected_transformations,
                'protocol_public_operations')
        scientific_sentences = (
            '必须取得适合新目标的实际资源资格，不能把Mac换名成Linux，或因旧Linux曾成功便假定现在可用。',
            '校准分辨率不是精度，空窗经验分位数也不是确定性误差上界；时钟允许误差及资格比例须由目标精度和测量依据决定，不自动搬用M02的100倍规则。',
            'B1—B5的资源、目标、真值、有效方法及预算门槛保持，正式确认仍为NOT_READY_TO_RUN。',
            '上述B1—B5的科学资格不由文件维护或软件自检替代。',
        )
        require(all(sentence in view for sentence in scientific_sentences), 'protocol_scientific_gates_removed')
        for basename in ('WEAK_MEAN_REVIEW.md', 'weak-mean-references.bib'):
            require(members['research/' + basename] == (PROOF_SOURCE.parent / basename).read_bytes(),
                    'research_addendum_source_identity')
        self.result.update(proof_markdown_byte_identity=True, protocol_view_role_declared=True,
                           protocol_source_and_view_digests_verified=True,
                           protocol_view_independently_reconstructed=True,
                           protocol_scientific_sentences_preserved=True)

    def verify_theory_readers(self, members, records):
        conversion = json.loads(members['verification/formula-conversion.json'])
        expected_readers = {'research/' + basename + '.html' for basename in
                            ('WEAK_MEAN_PROOF_PACKAGE', 'NEXT_VALIDATION_PROTOCOL', 'WEAK_MEAN_REVIEW')}
        require(set(conversion) == expected_readers, 'formula_audit_reader_coverage')
        total = 0
        for reader_name in sorted(expected_readers):
            markdown_name = str(PurePosixPath(reader_name).with_suffix('.md'))
            expressions, protected = formulas_and_prose(members[markdown_name].decode())
            rows = conversion[reader_name]
            require(expressions == [{'tex_sha256': row['tex_sha256'], 'display': row['display']} for row in rows],
                    'formula_source_sequence')
            record = records[reader_name]
            require(record.get('derived_from') == markdown_name and
                    record.get('derived_from_sha256') == digest(members[markdown_name]),
                    'theory_html_source_digest')
            html_text = members[reader_name].decode()
            actual_math = re.findall(r'<math\b[^>]*>.*?</math>', html_text, flags=re.S)
            require(Counter(digest(value.encode()) for value in actual_math) ==
                    Counter(row['mathml_sha256'] for row in rows), 'actual_mathml_digest_multiset')
            document = etree.HTML(html_text)
            article = document.find('.//article')
            require(article is not None, 'theory_article_missing')
            for math in article.xpath('.//*[local-name()="math"]'):
                raw_math = actual_math.pop(0)
                require(''.join(math.itertext()).strip(), 'empty_mathml')
                for leaf in math.xpath('.//*[local-name()="mi" or local-name()="mo" or local-name()="mn" or local-name()="mtext"]'):
                    require(not re.search(r'\\[A-Za-z]{2,}|\$', ''.join(leaf.itertext())),
                            'visible_latex_inside_mathml')
                replacement = etree.Element('span')
                replacement.text = 'MATHEXPR_' + digest(raw_math.encode())
                replacement.tail = math.tail
                math.getparent().replace(math, replacement)
            require(not actual_math, 'mathml_outside_theory_article')
            for index, row in enumerate(rows):
                protected = protected.replace('@@MATH_' + str(index) + '@@', 'MATHEXPR_' + row['mathml_sha256'])
            prose = []
            for line in protected.splitlines():
                if line.startswith('|') and all(re.fullmatch(r'[:\-\s]+', cell)
                                               for cell in line.strip().strip('|').split('|')):
                    continue
                line = re.sub(r'^#{1,6}\s+', '', line)
                line = re.sub(r'\[([^\]]+)\]\(([^)]+)\)', r'\1', line)
                prose.append(line.replace('**', '').replace('`', '').replace('|', ''))
            require(normalized_prose('\n'.join(prose)) == normalized_prose(''.join(article.itertext())),
                    'theory_html_prose_or_formula_positions_changed')
            total += len(rows)
        require(total == 131, 'new_formula_count_changed')
        self.result.update(theory_html_source_bindings_verified=3, new_formula_sources_verified=total,
                           actual_mathml_digests_and_positions_verified=True,
                           formula_conversion_semantics_independently_certified=False)

    def verify(self, archive_path):
        require(digest(OLD_ARCHIVE.read_bytes()) == OLD_SHA256, 'old_archive_identity')
        with zipfile.ZipFile(archive_path) as archive:
            entries = archive.infolist()
            require(len(entries) == len({entry.filename for entry in entries}), 'duplicate_archive_member')
            require(all(entry.file_size <= MAX_MEMBER_BYTES for entry in entries),
                    'archive_member_too_large')
            require(sum(entry.file_size for entry in entries) <= MAX_SCANNED_BYTES,
                    'archive_scan_byte_budget_exceeded')
            require(archive.testzip() is None, 'archive_crc')
            members = {}
            for entry in entries:
                safe_member(entry.filename.rstrip('/') if entry.is_dir() else entry.filename)
                require(not stat.S_ISLNK(entry.external_attr >> 16), 'archive_symlink')
                if not entry.is_dir():
                    require(entry.file_size <= MAX_MEMBER_BYTES, 'archive_member_too_large')
                    members[entry.filename] = archive.read(entry)
        with zipfile.ZipFile(OLD_ARCHIVE) as old:
            require(len(old.namelist()) == 870, 'old_member_count')
            require(all(members.get(HISTORY_PREFIX + name) == old.read(name) for name in old.namelist()),
                    'legacy_member_byte_identity')
            require({name[len(HISTORY_PREFIX):] for name in members if name.startswith(HISTORY_PREFIX)}
                    == set(old.namelist()), 'legacy_subroot_membership')
        records = self.verify_manifest(members)
        self.verify_reports(members)
        self.verify_theory(members, records)
        self.verify_theory_readers(members, records)
        for name, contents in members.items():
            if not name.startswith(HISTORY_PREFIX):
                require(PurePosixPath(name).suffix.lower() not in ('.py', '.sh'), 'new_executable_script')
                require(not contents.startswith((b'\x7fELF', b'\xcf\xfa\xed\xfe', b'\xfe\xed\xfa\xcf')),
                        'new_executable_binary')
            self.scan(contents, name)
        pages, edges = self.verify_html(members)
        self.verify_navigation(members, pages, edges)
        self.result.update(archive_sha256=digest(archive_path.read_bytes()), archive_files=len(members),
                           legacy_members_preserved=870, legacy_prefix=HISTORY_PREFIX,
                           scanned_bytes=self.scanned_bytes, zip_crc_verified=True)
        if self.result['privacy_hits']:
            self.error('direct_private_marker_hits')
        if not self.result['errors']:
            self.result['status'] = 'passed_bounded_reading_and_direct_string_privacy'


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('archive', type=Path)
    parser.add_argument('output_json', type=Path)
    arguments = parser.parse_args()
    audit = None
    try:
        audit = Audit()
        audit.verify(arguments.archive)
    except Exception as error:
        if audit is None:
            result = {'status': 'failed', 'whole_goal_complete': False,
                      'errors': [{'check': 'audit_initialization', 'type': type(error).__name__}]}
        else:
            label = str(error) if isinstance(error, Rejected) else 'verification_exception'
            audit.error(label)
            result = audit.result
    else:
        result = audit.result
    require(arguments.output_json.resolve() != arguments.archive.resolve(), 'output_overwrites_archive')
    arguments.output_json.parent.mkdir(parents=True, exist_ok=True)
    with arguments.output_json.open('x') as output:
        json.dump(result, output, ensure_ascii=False, indent=2)
        output.write('\n')
    print(json.dumps({'status': result['status'], 'whole_goal_complete': False,
                      'errors': len(result.get('errors', [])),
                      'privacy_hits': len(result.get('privacy_hits', []))}))
    return 0 if result['status'] == 'passed_bounded_reading_and_direct_string_privacy' else 1


if __name__ == '__main__':
    raise SystemExit(main())
