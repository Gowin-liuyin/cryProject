"""独立核对实际匿名ZIP；不构建或运行任何C、采集及管理入口。"""

import argparse
from collections import Counter
import hashlib
import html
from html.parser import HTMLParser
import io
import json
from pathlib import Path, PurePosixPath
import posixpath
import re
import stat
import subprocess
import sys
import tarfile
from urllib.parse import unquote, urlsplit
import xml.etree.ElementTree as element_tree
import zipfile

from pypdf import PdfReader

import reader_render


sys.dont_write_bytecode = True
ROOT = Path(__file__).resolve().parents[3]
WORK = ROOT / 'build/aris-measurement-package-20261010'
HISTORY = 'historical/20261010-g2-windows/'
CONTRACT_DIGESTS = {
    'DATA_CONTRACT.json': 'bed66374bf8fd63fed0ec19ac169d169c37787f95714d41d75342ba209a9cb89',
    'THEORY_CONTRACT.json': '7bb18c1fd0ee0e7896807b409be8bd0f8b1ff5095b018a6d227bc4cc259b1084',
}
READER_DIGEST = '2ee7f4399d23bf2ff9b809ce359df612dac6ca7b993f9baad2845659400daaad'
REPORT_DIGESTS = {
    'docx': '95ffce23d02180117fb05ccf9ebc406b7b05ae20038f08042e25d13934e2983f',
    'pdf': '27e8001b8a374be9636c83196c65295626551277b8aafd961f47e223c174d7f7',
}
MAX_MEMBER_BYTES = 128 * 1024 * 1024
MAX_ARCHIVE_BYTES = 1024 * 1024 * 1024
HEX_TOKEN = re.compile(r'(?<![A-Za-z0-9])[0-9a-f]{7,40}(?![A-Za-z0-9])')
MARKDOWN_LINK = re.compile(r'!?\[([^\]]*)\]\(([^)]+)\)')


class Rejected(ValueError):
    pass


def require(condition, label):
    if not condition:
        raise Rejected(label)


def digest(contents):
    return hashlib.sha256(contents).hexdigest()


def safe_member(name):
    require(isinstance(name, str) and bool(name), 'empty_member')
    require(not any(ord(character) < 32 or ord(character) == 127 for character in name),
            'control_character_member')
    require('\\' not in name and not name.startswith('/') and not re.match(r'^[A-Za-z]:', name),
            'absolute_or_windows_member')
    require(all(part not in ('', '.', '..') for part in name.split('/')), 'unsafe_member_path')


def read_zip(contents):
    source = io.BytesIO(contents) if isinstance(contents, bytes) else contents
    with zipfile.ZipFile(source) as archive:
        entries = archive.infolist()
        require(len(entries) == len({entry.filename for entry in entries}), 'duplicate_zip_member')
        require(sum(entry.file_size for entry in entries) <= MAX_ARCHIVE_BYTES, 'zip_byte_budget')
        for entry in entries:
            safe_member(entry.filename)
            mode = entry.external_attr >> 16
            require(not entry.is_dir() and entry.file_size <= MAX_MEMBER_BYTES, 'directory_or_large_member')
            require(not stat.S_ISLNK(mode) and stat.S_IFMT(mode) in (0, stat.S_IFREG), 'zip_link_or_special_file')
            require(not entry.flag_bits & 1, 'encrypted_zip_member')
        require(archive.testzip() is None, 'zip_crc')
        return {entry.filename: archive.read(entry) for entry in entries}


def records_index(value):
    if isinstance(value, dict):
        for key in ('members', 'files', 'sources', 'entries', 'records'):
            if key in value:
                value = value[key]
                break
    if isinstance(value, dict):
        rows = [dict(record, public_path=name) for name, record in value.items()]
    else:
        require(isinstance(value, list), 'record_array_missing')
        rows = value
    result = {}
    for row in rows:
        require(isinstance(row, dict), 'invalid_record')
        name = row.get('public_path', row.get('path', row.get('name')))
        safe_member(name)
        require(name not in result, 'duplicate_record_path')
        result[name] = row
    return result


def verify_manifest(members):
    require('MANIFEST.json' in members and 'SHA256SUMS' in members, 'manifest_missing')
    records = records_index(json.loads(members['MANIFEST.json']))
    require(set(records) == set(members) - {'MANIFEST.json', 'SHA256SUMS'}, 'manifest_exact_scope')
    for name, row in records.items():
        expected_digest = row.get('sha256', row.get('public_sha256'))
        expected_bytes = row.get('bytes', row.get('public_bytes', row.get('byte_count')))
        require(expected_digest == digest(members[name]) and expected_bytes == len(members[name]),
                'manifest_payload_digest_or_length')
    sums = {}
    for line in members['SHA256SUMS'].decode().splitlines():
        match = re.fullmatch(r'([0-9a-f]{64})  (.+)', line)
        require(match is not None, 'sha256sums_line')
        name = match[2]
        safe_member(name)
        require(name not in sums, 'sha256sums_duplicate')
        sums[name] = match[1]
    require(set(sums) == set(members) - {'SHA256SUMS'}, 'sha256sums_exact_scope')
    require(all(sums[name] == digest(members[name]) for name in sums), 'sha256sums_payload_digest')
    return records


def contracts():
    loaded = {}
    for name, expected_digest in CONTRACT_DIGESTS.items():
        payload = (WORK / name).read_bytes()
        require(digest(payload) == expected_digest, 'fixed_author_contract_changed_' + name)
        loaded[name] = json.loads(payload)
    require(digest(Path(reader_render.__file__).read_bytes()) == READER_DIGEST,
            'fixed_reader_verifier_changed')
    return loaded['DATA_CONTRACT.json'], loaded['THEORY_CONTRACT.json']


class Origins:
    def __init__(self, data_contract, theory_contract):
        self.trusted = {}
        self.archive_hashes = {}
        self.archive_members = {}
        self.cache = {}
        for row in data_contract['archive_audits']:
            self.archive_hashes[row['path']] = row['sha256']
        archive_paths = {row['source_id']: row['path'] for row in data_contract['archive_audits']}
        for row in data_contract['origin_member_inventory']:
            self.trusted[('tar_member', archive_paths[row['archive_id']], row['member'])] = row['sha256']
        for group in ('local_evidence_inventory', 'fixed_core_sources', 'g2_raw_inputs'):
            for row in data_contract[group]:
                self.trusted[('file', row['path'], None)] = row['sha256']
        qualification = data_contract['g2_qualification']
        self.archive_hashes[qualification['path']] = qualification['sha256']
        for row in qualification['members_inventory']:
            self.trusted[('zip_member', qualification['path'], row['member'])] = row['sha256']
        for row in theory_contract['source_documents']:
            self.trusted[('file', row['source_path_author_side_only'], None)] = row['source_sha256']
        finite = theory_contract['finite_original_verification']
        self.trusted[('file', finite['source_path_author_side_only'], None)] = finite['sha256']
        legacy = theory_contract['legacy']
        self.legacy_path = legacy['path_author_side_only']
        self.legacy_digest = legacy['sha256']
        self.archive_hashes[self.legacy_path] = self.legacy_digest
        old_bytes = (ROOT / self.legacy_path).read_bytes()
        require(digest(old_bytes) == self.legacy_digest, 'legacy_original_zip_digest')
        self.old = read_zip(old_bytes)
        require(len(self.old) == legacy['member_count'] == 925, 'legacy_925_member_count')
        for name, payload in self.old.items():
            self.trusted[('historical_member', self.legacy_path, name)] = digest(payload)
        for extension, expected_digest in REPORT_DIGESTS.items():
            path = 'deliverables/research/aris-report-synthesis-20261010/CACR2026EA16XZ-作品设计报告-匿名版.' + extension
            self.trusted[('file', path, None)] = expected_digest

    def key(self, origin):
        require(isinstance(origin, dict), 'source_origin_missing')
        kind = origin.get('kind')
        path = origin.get('path')
        require(kind in ('file', 'tar_member', 'zip_member', 'historical_member'), 'unknown_source_origin_kind')
        require(isinstance(path, str), 'source_origin_path')
        location = Path(path)
        if location.is_absolute():
            require(location.is_relative_to(ROOT), 'source_origin_outside_repository')
            path = str(location.relative_to(ROOT))
        safe_member(path)
        member = origin.get('member')
        if kind != 'file':
            safe_member(member)
        return kind, path, member

    def read(self, origin):
        key = self.key(origin)
        require(key in self.trusted, 'source_not_bound_to_independent_contract')
        kind, path, member = key
        if kind == 'file':
            payload = (ROOT / path).read_bytes()
        elif kind == 'historical_member':
            payload = self.old[member]
        else:
            if path not in self.cache:
                compressed = (ROOT / path).read_bytes()
                require(digest(compressed) == self.archive_hashes[path], 'original_archive_digest_changed')
                if kind == 'zip_member':
                    self.cache[path] = read_zip(compressed)
                else:
                    with tarfile.open(fileobj=io.BytesIO(compressed), mode='r:*') as archive:
                        entries = archive.getmembers()
                        require(len(entries) == len({entry.name for entry in entries}), 'original_tar_duplicate')
                        require(all(entry.isfile() for entry in entries), 'original_tar_nonregular')
                        for entry in entries:
                            safe_member(entry.name)
                        self.cache[path] = {entry.name: archive.extractfile(entry).read() for entry in entries}
            payload = self.cache[path][member]
        require(digest(payload) == self.trusted[key], 'original_source_contract_digest_changed')
        return payload


def allowed_replace(original, replacement, current, private_map):
    require(isinstance(original, str) and bool(original) and isinstance(replacement, str), 'replace_value')
    if any(original == row['original'] and replacement == row['replacement'] for row in private_map):
        return
    require(bool(replacement), 'scientific_deletion_operation')
    matches = list(MARKDOWN_LINK.finditer(current))
    if any(original == match[2] for match in matches):
        parsed_original = urlsplit(html.unescape(original))
        require(not parsed_original.scheme and not parsed_original.netloc, 'public_external_source_link_changed')
        require(not any(character.isspace() or character in '()[]<>`' for character in replacement),
                'reading_target_contains_prose_or_markdown_structure')
        parsed_replacement = urlsplit(html.unescape(replacement))
        require(not parsed_replacement.scheme and not parsed_replacement.netloc,
                'local_source_redirected_to_external_link')
        reader_render.safe_href(replacement)
        return
    if any(original == match[0] for match in matches):
        matched_link = next(match for match in matches if original == match[0])
        label = matched_link[1]
        parsed_original = urlsplit(html.unescape(matched_link[2]))
        require(not parsed_original.scheme and not parsed_original.netloc, 'public_external_source_link_changed')
        rewritten = MARKDOWN_LINK.fullmatch(replacement)
        approved_suffixes = ('', '（作者侧完整原件保留，公开数据见此视图）',
                             '（作者侧原件保留；公开数据视图）', '（作者侧原件保留）')
        if rewritten is not None:
            require(rewritten[1] in {label + suffix for suffix in approved_suffixes},
                    'original_link_label_or_neutral_notice_changed')
            reader_render.safe_href(rewritten[2])
            require(not any(character in '()[]<>`' for character in rewritten[2]), 'rewritten_link_structure')
            parsed_replacement = urlsplit(html.unescape(rewritten[2]))
            require(not parsed_replacement.scheme and not parsed_replacement.netloc,
                    'local_source_redirected_to_external_link')
        else:
            require(replacement == label + '（作者侧完整原件保留；本包未直接分发）',
                    'unapproved_link_omission_notice')
        return
    require(False, 'unregistered_scientific_text_replacement')


def reconstruct(original, operations, private_map, notices):
    if not operations:
        return original
    text = original.decode()
    for operation in operations:
        kind = operation.get('kind')
        replacement = operation.get('replacement')
        if kind == 'replace':
            source_token = operation.get('original')
            allowed_replace(source_token, replacement, text, private_map)
            own_token = any(row['original'] == source_token and row['role'].startswith('own_source')
                            for row in private_map)
            pattern = re.escape(source_token)
            if own_token:
                pattern = r'(?<![A-Za-z0-9])' + pattern + r'(?![A-Za-z0-9])'
            text, count = re.subn(pattern, lambda match: replacement, text)
            require(count > 0 and operation.get('count', count) == count, 'replace_count_changed')
        elif kind == 'insert_notice':
            require(replacement in notices, 'unapproved_public_notice')
            position = operation.get('position', 'after_first_heading')
            if position == 'after_first_heading':
                require(text.startswith('# ') and '\n' in text, 'notice_heading_missing')
                boundary = text.index('\n')
                text = text[:boundary] + '\n\n' + replacement + '\n' + text[boundary + 1:]
            elif position == 'before_original':
                text = replacement + '\n\n' + text
            else:
                require(False, 'unknown_notice_position')
        else:
            require(False, 'unknown_source_operation')
    return text.encode()


def verify_public_operations(public_operations, private_operations):
    require(isinstance(public_operations, list) and len(public_operations) == len(private_operations),
            'public_transformation_operation_count')
    for public, private in zip(public_operations, private_operations):
        require(public.get('kind') == private['kind'] and public.get('replacement') == private['replacement'],
                'public_transformation_kind_or_replacement')
        require('original' not in public, 'public_transformation_private_token')
        if private['kind'] == 'replace':
            require(public.get('old_token_sha256') == digest(private['original'].encode()),
                    'public_transformation_original_token_digest')
            require(public.get('count') == private.get('count'), 'public_transformation_replacement_count')
        elif 'position' in private:
            require(public.get('position') == private['position'], 'public_notice_position_changed')


def verify_private_map(private_map, theory_contract):
    require(isinstance(private_map, list), 'private_map_list')
    require(all(isinstance(row.get('original'), str) and row['original']
                and isinstance(row.get('replacement'), str) and row['replacement']
                and isinstance(row.get('role'), str) for row in private_map), 'private_map_record')
    originals = {row['original'] for row in private_map}
    require(len(originals) == len(private_map), 'private_map_duplicate')
    required = {row['original'] for row in theory_contract['identity_substitutions_to_merge_with_all_old_records']}
    old_map = json.loads((ROOT / 'docs/evidence/aris-current-package-20261009/private-substitution-map.json').read_bytes())
    required.update(row['original'] for row in old_map)
    data_map = json.loads((WORK / 'DATA_CONTRACT.json').read_bytes())['identity_policy']['private_author_map_records']
    approved = set(required) | {row['original'] for row in data_map}
    revisions = subprocess.run(['git', 'rev-list', '--all'], cwd=ROOT, capture_output=True,
                               text=True, check=True).stdout.splitlines()
    required.update(revision[:width] for revision in revisions for width in (40, 12, 8, 7))
    approved.update(required)
    require(required.issubset(originals), 'private_map_missing_independently_known_identity')
    require(originals.issubset(approved), 'private_map_unapproved_identity_or_scientific_text')
    allowed_replacements = {}
    for row in old_map + theory_contract['identity_substitutions_to_merge_with_all_old_records'] + data_map:
        allowed_replacements.setdefault(row['original'], set()).add(row['replacement'])
    for row in private_map:
        neutral_alias = re.fullmatch(
            r'(?:OWN_SOURCE|PARTICIPANT|MEASUREMENT|ORIGINAL|PRIVATE|HISTORICAL|RAW|ORDINARY|G2)_[A-Z0-9_]+',
            row['replacement'])
        require(row['replacement'] in allowed_replacements.get(row['original'], set()) or neutral_alias is not None,
                'private_map_unapproved_replacement_prose')
    own = {row['original'] for row in private_map if row['role'].startswith('own_source')}
    approved_own = {row['original'] for row in old_map + data_map if row['role'].startswith('own_source')}
    approved_own.update(revision[:width] for revision in revisions for width in (40, 12, 8, 7))
    require(own.issubset(approved_own) and all(re.fullmatch(r'[0-9a-f]{7,40}', token) for token in own),
            'direct_identity_disguised_as_own_commit')
    require(all(revision[:width] in own for revision in revisions for width in (40, 12, 8, 7)),
            'private_map_own_commit_role_missing')


def css_links(value):
    require('\\' not in value, 'css_escape_disallowed')
    value = re.sub(r'/\*.*?\*/', '', value, flags=re.S)
    require(not re.search(r'@import|javascript:|expression\s*\(|-moz-binding|image-set\s*\(', value, re.I),
            'active_or_untracked_css_resource')
    return [(match[1].strip(), False) for match in
            re.finditer(r'url\(\s*["\']?([^"\')]+)["\']?\s*\)', value, re.I)]


class Page(HTMLParser):
    def __init__(self):
        super().__init__(convert_charrefs=True)
        self.links = []
        self.identifiers = set()
        self.in_style = False

    def css(self, value):
        self.links.extend(css_links(value))

    def handle_starttag(self, tag, attributes):
        values = dict(attributes)
        require(tag not in ('script', 'iframe', 'object', 'embed', 'applet', 'base', 'form', 'frame'),
                'active_html_element')
        require(not any(name.startswith('on') for name in values) and 'srcdoc' not in values,
                'active_html_attribute')
        require(not any(name in values for name in ('ping', 'formaction', 'manifest')), 'html_remote_action')
        if tag == 'style':
            self.in_style = True
        if 'style' in values:
            self.css(values['style'])
        require(not (tag == 'meta' and values.get('http-equiv', '').lower() == 'refresh'), 'html_refresh')
        if 'id' in values:
            require(values['id'] not in self.identifiers, 'duplicate_html_anchor')
            self.identifiers.add(values['id'])
        if tag == 'a' and 'name' in values:
            self.identifiers.add(values['name'])
        for key in ('href', 'src', 'poster', 'data', 'xlink:href'):
            if key in values:
                self.links.append((values[key], tag == 'a' and key == 'href'))
        for key in ('srcset', 'imagesrcset'):
            if key in values:
                for candidate in values[key].split(','):
                    require(bool(candidate.strip()), 'empty_srcset_candidate')
                    self.links.append((candidate.split()[0], False))
        if 'background' in values:
            self.links.append((values['background'], False))

    def handle_endtag(self, tag):
        if tag == 'style':
            self.in_style = False

    def handle_data(self, value):
        if self.in_style:
            self.css(value)


def local_target(source, link, navigation=True):
    decoded = html.unescape(unquote(link))
    require(not any(character in decoded for character in ('\\', '\x00', '\n', '\r')), 'unsafe_link_character')
    parsed = urlsplit(decoded)
    if parsed.scheme or parsed.netloc:
        require(navigation and parsed.scheme in ('http', 'https') and bool(parsed.netloc),
                'unsafe_or_remote_resource')
        return None, None
    require(not parsed.path.startswith('/'), 'absolute_reading_link')
    target = source if not parsed.path else posixpath.normpath(posixpath.join(posixpath.dirname(source), parsed.path))
    safe_member(target)
    return target, unquote(parsed.fragment)


def verify_links(members, required_targets):
    pages = {}
    edges = {}
    for name, payload in members.items():
        if name.endswith('.html'):
            page = Page()
            page.feed(payload.decode())
            page.close()
            pages[name] = page
    checked = 0
    for name, payload in members.items():
        if name in pages:
            links = pages[name].links
        elif name.endswith('.md'):
            links = [(match[2], not match[0].startswith('!')) for match in MARKDOWN_LINK.finditer(payload.decode())]
        elif name.endswith('.css'):
            links = css_links(payload.decode())
        else:
            continue
        for raw, navigation in links:
            target, fragment = local_target(name, raw, navigation)
            if target is None:
                continue
            require(target in members, 'missing_local_reading_target: ' + name + ' -> ' + target)
            if fragment and target in pages:
                require(fragment in pages[target].identifiers, 'missing_local_reading_anchor')
            edges.setdefault(name, set()).add(target)
            checked += 1
    reachable = {'index.html'}
    pending = ['index.html']
    while pending:
        for target in edges.get(pending.pop(), ()):
            if target not in reachable:
                reachable.add(target)
                pending.append(target)
    require(set(required_targets).issubset(reachable), 'root_index_required_targets_unreachable: ' +
            ','.join(sorted(set(required_targets) - reachable)[:10]))
    return {'local_links_checked': checked, 'required_targets_reachable': len(required_targets),
            'html_pages_checked': len(pages)}


class Privacy:
    def __init__(self, private_map):
        require(isinstance(private_map, list), 'private_map_list')
        originals = [row['original'] for row in private_map]
        require(len(originals) == len(set(originals)), 'duplicate_private_map_token')
        self.own = {row['original'] for row in private_map if row['role'].startswith('own_source')}
        require(all(re.fullmatch(r'[0-9a-f]{7,40}', token) for token in self.own),
                'privacy_nonhex_identity_mislabelled_commit')
        direct = [row['original'] for row in private_map if not row['role'].startswith('own_source')]
        self.direct = re.compile('|'.join(re.escape(token) for token in sorted(direct, key=len, reverse=True)))
        self.scanned_bytes = 0
        self.nested = 0

    def text(self, value, name):
        for variant in {value, html.unescape(unquote(value))}:
            found = self.direct.search(variant)
            require(found is None, 'private_identity_marker: ' + name)
            require(not any(match[0] in self.own for match in HEX_TOKEN.finditer(variant)),
                    'own_source_commit_marker: ' + name)
            if not name.startswith(HISTORY):
                require(not re.search(r'/(?:Users|home)/[^/\s"<>]+(?:/|[\s"<>]|$)', variant),
                        'unregistered_private_absolute_path: ' + name)

    def scan(self, payload, name, depth=0):
        require(depth <= 8, 'nested_archive_depth')
        self.scanned_bytes += len(payload)
        require(self.scanned_bytes <= MAX_ARCHIVE_BYTES, 'privacy_byte_budget')
        self.text(name, name)
        self.text(payload.decode('utf-8', errors='ignore'), name)
        if payload.startswith(b'PK\x03\x04'):
            nested = read_zip(payload)
            self.nested += 1
            for member, contents in nested.items():
                self.scan(contents, name + '!' + member, depth + 1)
        elif payload.startswith(b'%PDF-'):
            reader = PdfReader(io.BytesIO(payload))
            self.text(str(reader.metadata or {}), name + ':metadata')
            for page in reader.pages:
                self.text(page.extract_text() or '', name + ':page')
            if reader.xmp_metadata is not None:
                self.text(reader.xmp_metadata.stream.get_data().decode('utf-8', errors='ignore'), name + ':xmp')
        elif payload and name.endswith('.json'):
            value = json.loads(payload)

            def walk(item):
                if isinstance(item, str):
                    self.text(item, name)
                elif isinstance(item, dict):
                    for key, child in item.items():
                        self.text(key, name)
                        walk(child)
                elif isinstance(item, list):
                    for child in item:
                        walk(child)

            walk(value)


def verify_reports(members):
    found = {}
    for extension, expected_digest in REPORT_DIGESTS.items():
        candidates = [name for name, payload in members.items()
                      if not name.startswith(HISTORY) and name.endswith('.' + extension)
                      and digest(payload) == expected_digest]
        require(len(candidates) == 1, 'approved_current_report_missing_or_duplicated')
        found[extension] = candidates[0]
    with zipfile.ZipFile(io.BytesIO(members[found['docx']])) as archive:
        core = element_tree.fromstring(archive.read('docProps/core.xml'))
        for name in ('{http://purl.org/dc/elements/1.1/}creator',
                     '{http://schemas.openxmlformats.org/package/2006/metadata/core-properties}lastModifiedBy'):
            require(not (core.findtext(name) or '').strip(), 'docx_author_metadata')
        app = element_tree.fromstring(archive.read('docProps/app.xml'))
        require(app.findtext('{http://schemas.openxmlformats.org/officeDocument/2006/extended-properties}Pages')
                == '54', 'docx_actual_page_cache')
        if 'docProps/custom.xml' in archive.namelist():
            require(len(element_tree.fromstring(archive.read('docProps/custom.xml'))) == 0, 'docx_custom_metadata')
    reader = PdfReader(io.BytesIO(members[found['pdf']]))
    require(len(reader.pages) == 54, 'actual_report_54_pages')
    require(not str((reader.metadata or {}).get('/Author', '')).strip(), 'pdf_author_metadata')
    require(reader.xmp_metadata is None or not reader.xmp_metadata.dc_creator, 'pdf_xmp_author_metadata')
    return found


def verify_offline_cmake(payload):
    text = re.sub(r'#[^\n]*', '', payload.decode())
    require(re.search(r'set\s*\(\s*CMAKE_C_STANDARD\s+11\s*\)', text, re.I), 'offline_C11_missing')
    forbidden = (r'\b(?:execute_process|add_custom_command|add_custom_target|add_subdirectory|file|add_library|'
                 r'FetchContent|ExternalProject|cmake_language|find_package|configure_file|try_compile|try_run)\s*\(')
    require(not re.search(forbidden, text, re.I), 'offline_cmake_execution_or_extra_project')
    require(all(value.strip() == 'CTest' for value in re.findall(r'include\s*\(([^)]*)\)', text, re.I)),
            'offline_cmake_unknown_include')
    executables = re.findall(r'add_executable\s*\(\s*([A-Za-z_][A-Za-z0-9_]*)\s+([^)]*)\)', text, re.I)
    expected = {'analyze_windows', 'analyze_raw_clock', 'analyze_reference_repeatability'}
    require(len(executables) == 3 and {row[0] for row in executables} == expected, 'offline_only_three_analyzers')
    require(len(re.findall(r'\badd_executable\s*\(', text, re.I)) == 3,
            'offline_cmake_hidden_executable')
    for target, sources in executables:
        source_tokens = sources.split()
        require(len(source_tokens) == 1 and PurePosixPath(source_tokens[0].strip('"')).name == target + '.c',
                'offline_analyzer_source_list')
    tests = re.findall(r'add_test\s*\(\s*NAME\s+\S+\s+COMMAND\s+(\S+)\s+(\S+)\s*\)', text, re.I)
    require(len(re.findall(r'\badd_test\s*\(', text, re.I)) == 4, 'offline_cmake_extra_test')
    require(Counter(tests) == Counter({('analyze_windows', '--selfcheck'): 1,
                                     ('analyze_windows', '--timing-selfcheck'): 1,
                                     ('analyze_raw_clock', '--selfcheck'): 1,
                                     ('analyze_reference_repeatability', '--selfcheck'): 1}),
            'offline_only_four_software_selfchecks')


def verify_package(archive_path, bindings_path, private_map_path):
    data_contract, theory_contract = contracts()
    origins = Origins(data_contract, theory_contract)
    members = read_zip(archive_path)
    verify_manifest(members)
    require({name[len(HISTORY):] for name in members if name.startswith(HISTORY)} == set(origins.old),
            'exact_925_historical_membership')
    require(all(members[HISTORY + name] == contents for name, contents in origins.old.items()),
            'all_925_historical_bytes_unchanged')
    bindings = json.loads(bindings_path.read_bytes())
    private_map = json.loads(private_map_path.read_bytes())
    require(isinstance(bindings, list), 'author_bindings_list')
    verify_private_map(private_map, theory_contract)
    public_sources = records_index(json.loads(members['provenance/sources.json']))
    notices = {theory_contract['proposed_notice'], theory_contract['proposed_finite_status_notice']}
    bound = {}
    source_paths = {}
    for binding in bindings:
        name = binding['public_path']
        safe_member(name)
        require(name not in bound and name in members, 'duplicate_or_missing_bound_member')
        require(binding['public_sha256'] == digest(members[name]), 'author_binding_public_digest')
        role = binding.get('role', '')
        if role == 'generated':
            require(not binding.get('origin') and not binding.get('operations'), 'generated_origin_disguised')
        else:
            original = origins.read(binding['origin'])
            require(digest(original) == binding['original_sha256'], 'author_binding_original_digest')
            expected = reconstruct(original, binding.get('operations', []), private_map, notices)
            require(expected == members[name], 'independent_full_source_reconstruction')
            source_paths[origins.key(binding['origin'])] = name
        bound[name] = binding
        if name in public_sources:
            public = public_sources[name]
            require(public.get('source_id') == binding['source_id'], 'public_source_id_binding')
            require(public.get('public_sha256', public.get('sha256')) == digest(members[name]),
                    'public_source_digest_binding')
            require(public.get('role') == role, 'public_source_role_binding')
            require(not any(key in public for key in ('origin', 'source_path', 'source_commit', 'original')),
                    'public_source_private_provenance')
            if role != 'generated':
                require(public.get('original_sha256', public.get('source_sha256')) == binding['original_sha256'],
                        'public_original_digest_binding')
                verify_public_operations(public.get('operations', []), binding.get('operations', []))
    new_names = {name for name in members if not name.startswith(HISTORY)}
    require(new_names - {'MANIFEST.json', 'SHA256SUMS'} == set(bound), 'new_members_author_binding_whitelist')
    require(set(public_sources).issubset(set(bound)), 'public_sources_unbound_member')
    require(set(public_sources) == set(bound) - {'provenance/sources.json'}, 'public_sources_complete_coverage')
    report_names = verify_reports(members)
    require(bound['code/CMakeLists.txt']['role'] == 'generated', 'adapted_cmake_mislabelled_original')
    verify_offline_cmake(members['code/CMakeLists.txt'])
    required = set(report_names.values()) | {'code/CMakeLists.txt'}
    for row in data_contract['fixed_core_sources']:
        if row['path'].endswith('.c'):
            key = ('file', row['path'], None)
            require(key in source_paths, 'required_fixed_analyzer_missing')
            require(members[source_paths[key]] == (ROOT / row['path']).read_bytes(), 'fixed_analyzer_original_bytes')
            required.add(source_paths[key])
    csv_count = 0
    archive_paths = {row['source_id']: row['path'] for row in data_contract['archive_audits']}
    for row in data_contract['csv_inventory']:
        if not row['count_once_in_scientific_total']:
            continue
        key = ('tar_member', archive_paths[row['archive_id']], row['member'])
        require(key in source_paths, 'required_raw_or_C_csv_missing')
        require(digest(members[source_paths[key]]) == row['sha256'], 'complete_raw_or_C_csv_changed')
        required.add(source_paths[key])
        if row['kind'] == 'raw_values':
            csv_count += 1
    require(csv_count == 9, 'nine_unique_raw_csv_required')
    def require_source_origin(origin_key, label):
        require(origin_key in source_paths, label)
        required.add(source_paths[origin_key])

    for row in data_contract['origin_member_inventory']:
        if row['archive_id'] == 'REFERENCE_E1_ORIGIN':
            continue
        name = row['member']
        if re.search(r'(?:^|/)output/P[123](?:-summary)?\.json$', name) or PurePosixPath(name).name in (
                'before-environment.json', 'after-environment.json', 'commands.json', 'run-state.json', 'run-claim.json'):
            require_source_origin(('tar_member', archive_paths[row['archive_id']], row['member']),
                                  'complete_collector_summary_metadata_or_management_missing')
    mandatory_local = {
        'normal-timing.csv', 'normal-timing-summary.json', 'parent-loss-timing.csv',
        'parent-loss-timing-summary.json', 'execution.json', 'source-bindings.json', 'verification.json',
        'deployment-before-count-correction.json', 'deployment-sidecar-correction.json', 'deployment.json',
        'upload.stderr', 'upload.stdout', 'upload-reauth.stdout', 'upload-reauth.stderr',
        'postcheck.json', 'postcheck.stdout', 'postcheck-verification.json', 'ssh-close.json',
        'e1-postcheck.json', 'final-postcheck.json', 'final-postcheck.stdout', 'e1-close.json', 'e2-close.json',
        'archive-byte-verification.json', 'e1-download-verification.json', 'e2-download-verification.json',
        'clock-context-addendum.json', 'elf-build-check.json', 'archive-source-check.json',
        'lifecycle-meta-check.json', 'draft-verification.json',
    }
    for row in data_contract['local_evidence_inventory']:
        if PurePosixPath(row['path']).name in mandatory_local:
            require_source_origin(('file', row['path'], None),
                                  'required_failure_correction_review_or_exit_record_missing')
    mandatory_qualification = set(next(row['qualification_members'] for row in
                                      data_contract['mandatory_failure_correction_records']
                                      if row['id'] == 'G2_ASAN_RUNTIME_FAILURE_AND_REPAIR'))
    mandatory_qualification.add('repair/readonly-stdout-target.bin')
    for row in data_contract['g2_qualification']['members_inventory']:
        if row['member'] in mandatory_qualification:
            require_source_origin(('zip_member', data_contract['g2_qualification']['path'], row['member']),
                                  'original_software_failure_or_repair_material_missing')
    require_source_origin(('file', theory_contract['finite_original_verification']['source_path_author_side_only'], None),
                          'finite_abstract_review_status_missing')
    for row in data_contract['g2_raw_inputs']:
        historical_name = HISTORY + row['historical_member']
        require(historical_name in members and digest(members[historical_name]) == row['sha256'],
                'historical_complete_G2_raw_input_changed')
        required.add(historical_name)
    reader_audits = json.loads(members['provenance/readers.json'])
    if isinstance(reader_audits, list):
        reader_audits = {row.get('markdown_path', row.get('public_path')): row.get('audit', row) for row in reader_audits}
    formulas = 0
    for row in theory_contract['source_documents']:
        source_key = ('file', row['source_path_author_side_only'], None)
        require(source_key in source_paths, 'complete_scientific_document_missing')
        markdown_name = source_paths[source_key]
        html_name = str(PurePosixPath(markdown_name).with_suffix('.html'))
        require(html_name in members and bound[html_name]['role'] == 'generated', 'scientific_reader_missing')
        audit = reader_audits[markdown_name]
        result = reader_render.verify_reader(members[markdown_name].decode(), members[html_name], audit)
        formulas += result['formulas']
        required.update((markdown_name, html_name))
    require(len(theory_contract['source_documents']) == 43, 'all_43_scientific_readers_required')
    required.update(theory_contract['historical_reading_targets'].values())
    for name in new_names:
        require(not name.endswith(('.py', '.sh', '.exe', '.o', '.a', '.zip', '.tar', '.tar.gz')) and not members[name].startswith(
            (b'\x7fELF', b'\xcf\xfa\xed\xfe', b'\xfe\xed\xfa\xcf')), 'new_executable_or_management_source')
        if bound.get(name, {}).get('role') == 'generated':
            require(name in {'index.html', 'README.md', 'reader.css', 'code/CMakeLists.txt'}
                    or name.startswith('provenance/') and name.endswith('.json')
                    or name.endswith(('/README.md', '/index.html'))
                    or name.endswith('.html') and name[:-5] + '.md' in bound,
                    'unlisted_generated_member')
    navigation = verify_links(members, required)
    privacy = Privacy(private_map)
    for name, contents in members.items():
        privacy.scan(contents, name)
    return {'status': 'passed_independent_actual_zip_source_and_reading_audit',
            'archive_sha256': digest(archive_path.read_bytes()), 'archive_members': len(members),
            'historical_members_byte_identical': 925, 'complete_scientific_markdown_and_html': 43,
            'native_mathml_formulas': formulas, 'unique_raw_csv': csv_count,
            'approved_report_pages': 54, 'fixed_original_analyzers': 3,
            'offline_cmake_software_tests': 4, 'independent_source_reconstruction': True,
            'private_scan_bytes': privacy.scanned_bytes, 'nested_archives_scanned': privacy.nested,
            'new_C_or_crypto_or_timing_or_SSH_execution': False, 'R02': 'partial', 'R04': 'partial',
            'external_peer_review': False, 'whole_goal_complete': False, **navigation}


def self_check():
    checked = []

    def rejected(label, callback):
        try:
            callback()
        except (Rejected, ValueError, KeyError, zipfile.BadZipFile):
            checked.append(label)
        else:
            raise AssertionError('negative_fixture_accepted_' + label)

    for name in ('../outside', '/absolute', 'a\\b', 'a//b', 'C:/outside', 'a/./b'):
        rejected('unsafe_path_' + name, lambda name=name: safe_member(name))
    rejected('active_html', lambda: Page().feed('<script>bad()</script>'))
    rejected('remote_resource', lambda: local_target('index.html', 'https://example.test/font.woff', False))
    rejected('javascript_link', lambda: local_target('index.html', 'javascript:bad()'))
    rejected('escaped_private_identity', lambda: Privacy([
        {'original': 'PRIVATE_PERSON', 'replacement': 'PARTICIPANT', 'role': 'identity'}
    ]).scan(b'{"value":"PRIVATE_%50ERSON"}', 'new.json'))
    rejected('unregistered_private_path', lambda: Privacy([
        {'original': 'UNRELATED', 'replacement': 'PUBLIC', 'role': 'identity'}
    ]).scan(b'/home/unknown/project', 'new.txt'))
    rejected('private_home_at_end_of_file', lambda: Privacy([
        {'original': 'UNRELATED', 'replacement': 'PUBLIC', 'role': 'identity'}
    ]).scan(b'/home/unregistered_user', 'new.txt'))
    rejected('own_commit_inside_path', lambda: Privacy([
        {'original': 'abcdef1', 'replacement': 'OWN_SOURCE', 'role': 'own_source_commit'}
    ]).scan(b'source-abcdef1/file', 'new.txt'))
    rejected('scientific_sentence_deletion', lambda: reconstruct(
        b'# Title\n\nAll tails and failures remain.\n',
        [{'kind': 'replace', 'original': 'All tails and failures remain.', 'replacement': '', 'count': 1}],
        [], set()))
    rejected('scientific_claim_grafted_into_link', lambda: reconstruct(
        b'[Complete proof](PROOF_PACKAGE.md)',
        [{'kind': 'replace', 'original': '[Complete proof](PROOF_PACKAGE.md)',
          'replacement': 'Complete proof certifies all real data and R04', 'count': 1}], [], set()))
    rejected('url_only_markdown_prose_injection', lambda: reconstruct(
        b'[Complete proof](PROOF_PACKAGE.md)',
        [{'kind': 'replace', 'original': 'PROOF_PACKAGE.md',
          'replacement': 'PROOF_PACKAGE.html)全部现实运行已认证。', 'count': 1}], [], set()))
    rejected('unapproved_notice', lambda: reconstruct(b'# Title\n',
        [{'kind': 'insert_notice', 'replacement': 'False certainty.'}], [], {'Approved notice.'}))
    rejected('missing_reading_target', lambda: verify_links(
        {'index.html': b'<a href="missing.html">Missing</a>'}, set()))
    rejected('missing_anchor', lambda: verify_links(
        {'index.html': b'<a href="other.html#absent">Missing</a>', 'other.html': b'<p>Body</p>'}, set()))
    rejected('unreachable_required', lambda: verify_links(
        {'index.html': b'<p>Home</p>', 'other.html': b'<p>Body</p>'}, {'other.html'}))
    for label, page in (
            ('remote_style_block', b'<style>body{background:url(https://example.test/x.png)}</style>'),
            ('remote_style_attribute', b'<p style="background:url(https://example.test/x.png)">x</p>'),
            ('remote_srcset', b'<img srcset="https://example.test/x.png 2x">'),
            ('escaped_css_url', b'<style>p{background:u\\72l(https://example.test/x.png)}</style>')):
        rejected(label, lambda page=page: verify_links({'index.html': page}, set()))
    rejected('uppercase_css_url', lambda: verify_links(
        {'index.html': b'<link rel="stylesheet" href="reader.css">',
         'reader.css': b'p{background:URL(https://example.test/x.png)}'}, set()))
    rejected('collector_cmake', lambda: verify_offline_cmake(
        b'set(CMAKE_C_STANDARD 11)\nadd_executable(raw_clock_calibration collector.c)\n'))
    rejected('public_source_operation_forgery', lambda: verify_public_operations(
        [{'kind': 'replace', 'old_token_sha256': '0' * 64, 'replacement': 'Public', 'count': 1}],
        [{'kind': 'replace', 'original': 'Private', 'replacement': 'Public', 'count': 1}]))
    rejected('public_source_private_token', lambda: verify_public_operations(
        [{'kind': 'replace', 'original': 'Private', 'old_token_sha256': digest(b'Private'),
          'replacement': 'Public', 'count': 1}],
        [{'kind': 'replace', 'original': 'Private', 'replacement': 'Public', 'count': 1}]))
    data_contract, theory_contract = contracts()
    approved_records = json.loads((ROOT / 'docs/evidence/aris-current-package-20261009/private-substitution-map.json').read_bytes())
    approved_records += theory_contract['identity_substitutions_to_merge_with_all_old_records']
    approved_records += data_contract['identity_policy']['private_author_map_records']
    approved_map = {row['original']: row for row in approved_records}
    verify_private_map(list(approved_map.values()), theory_contract)
    rejected('scientific_sentence_registered_as_identity', lambda: verify_private_map(
        list(approved_map.values()) + [{'original': 'Real-data qualification is unknown.',
                                      'replacement': 'Real-data qualification is certified.',
                                      'role': 'identity'}], theory_contract))
    disguised_map = [dict(row, role='own_source_identity') if row['original'] == 'nss-m' else row
                     for row in approved_map.values()]
    rejected('direct_identity_commit_role_disguise', lambda: verify_private_map(disguised_map, theory_contract))
    Privacy([{'original': 'UNRELATED', 'replacement': 'PUBLIC', 'role': 'identity'}]).scan(b'', 'empty.json')
    require(reconstruct(b'Owner [data](old.csv).',
        [{'kind': 'replace', 'original': 'Owner', 'replacement': 'Participant', 'count': 1},
         {'kind': 'replace', 'original': 'old.csv', 'replacement': 'data.csv', 'count': 1}],
        [{'original': 'Owner', 'replacement': 'Participant', 'role': 'identity'}], set()) == b'Participant [data](data.csv).',
        'positive_view_reconstruction')
    return {'self_check': 'passed', 'negative_fixtures_rejected': checked,
            'new_C_or_crypto_or_timing_or_SSH_execution': False}


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--archive', type=Path, default=WORK / 'candidate.zip')
    parser.add_argument('--bindings', type=Path, default=WORK / 'author-source-bindings.json')
    parser.add_argument('--private-map', type=Path, default=WORK / 'private-substitution-map.json')
    parser.add_argument('--output', type=Path)
    parser.add_argument('--self-check', action='store_true')
    arguments = parser.parse_args()
    try:
        result = self_check() if arguments.self_check else verify_package(
            arguments.archive, arguments.bindings, arguments.private_map)
    except (Rejected, ValueError, KeyError, OSError, zipfile.BadZipFile) as error:
        result = {'status': 'rejected', 'error': str(error),
                  'new_C_or_crypto_or_timing_or_SSH_execution': False}
    rendered = json.dumps(result, ensure_ascii=False, indent=2) + '\n'
    if arguments.output:
        require(arguments.output.resolve().is_relative_to(ROOT / 'build'), 'verification_output_outside_build')
        arguments.output.write_text(rendered)
    print(rendered, end='')
    return 0 if result.get('self_check') == 'passed' or result.get('status', '').startswith('passed_') else 1


if __name__ == '__main__':
    raise SystemExit(main())
