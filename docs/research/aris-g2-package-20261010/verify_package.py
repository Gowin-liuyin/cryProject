import argparse
from collections import Counter
import csv
import hashlib
from html import unescape
import importlib.util
import io
import json
from pathlib import Path, PurePosixPath
import posixpath
import re
import stat
import subprocess
import sys
from urllib.parse import unquote, urlsplit
import zipfile

from lxml import etree
from pypdf import PdfReader


sys.dont_write_bytecode = True
REPOSITORY = Path(__file__).resolve().parents[3]
OLD_VERIFIER = REPOSITORY / 'docs/research/aris-weak-package-20261010/verify_package.py'
OLD_VERIFIER_SHA256 = '5ea0e5826ac4e89306ed2eddc9cdd4f995af289b74b81bc4316adc140a63403a'


def digest(contents):
    return hashlib.sha256(contents).hexdigest()


def load_module(name, path):
    specification = importlib.util.spec_from_file_location(name, path)
    module = importlib.util.module_from_spec(specification)
    specification.loader.exec_module(module)
    return module


if digest(OLD_VERIFIER.read_bytes()) != OLD_VERIFIER_SHA256:
    raise ValueError('immutable_base_verifier_changed')
base = load_module('bounded_mean_package_verifier', OLD_VERIFIER)
policy = load_module('g2_package_policy', Path(__file__).with_name('build_package.py'))
require = base.require
Rejected = base.Rejected


def reconstruct_view(source_id, original, private_records):
    value = original.decode('utf-8')
    operations = []
    for source_token, replacement in policy.LINK_REPLACEMENTS.get(source_id, {}).items():
        occurrences = value.count(source_token)
        require(occurrences > 0, 'source_link_whitelist_changed')
        value = value.replace(source_token, replacement)
        operations.append({'kind': 'reading_link_or_explicit_omission',
                           'original_token_sha256': digest(source_token.encode()),
                           'replacement': replacement, 'count': occurrences})
    for record in private_records:
        expression = re.escape(record['original'])
        if record['role'].startswith('own_source'):
            expression = r'(?<![A-Za-z0-9])' + expression + r'(?![A-Za-z0-9])'
        value, occurrences = re.subn(expression, lambda match: record['replacement'], value)
        if occurrences:
            operations.append({'kind': 'anonymous_identity_token',
                               'marker_sha256': digest(record['original'].encode()),
                               'replacement': record['replacement'], 'role': record['role'],
                               'count': occurrences})
    if value.startswith('# '):
        heading_end = value.find('\n')
        require(heading_end >= 0, 'source_heading_has_no_body')
        value = value[:heading_end] + '\n\n' + policy.NOTICE + '\n' + value[heading_end + 1:]
        position = 'after_first_heading'
    else:
        value = policy.NOTICE + '\n\n' + value
        position = 'before_original_caption'
    operations.append({'kind': 'insert_public_view_notice', 'position': position,
                       'text': policy.NOTICE, 'text_sha256': digest(policy.NOTICE.encode())})
    return value.encode(), operations


def normalized_markdown(markdown):
    prose = []
    for line in markdown.splitlines():
        if line.startswith('```'):
            continue
        if line.startswith('|') and all(re.fullmatch(r'[:\-\s]+', cell)
                                       for cell in line.strip().strip('|').split('|')):
            continue
        line = re.sub(r'^#{1,6}\s+', '', line)
        line = re.sub(r'\[([^\]]+)\]\(([^)]+)\)', r'\1', line)
        prose.append(line.replace('**', '').replace('`', '').replace('|', ''))
    return re.sub(r'\s+', '', unescape('\n'.join(prose)))


def verify_reader(markdown, html_contents):
    document = etree.HTML(html_contents)
    article = document.find('.//article')
    require(article is not None, 'complete_scientific_article_missing')
    actual = re.sub(r'\s+', '', ''.join(article.itertext()))
    require(normalized_markdown(markdown.decode()) == actual,
            'complete_scientific_prose_order_or_position_changed')


class Audit(base.Audit):
    def __init__(self, private_map, report_binding=None):
        records = json.loads(private_map.read_text()) if isinstance(private_map, Path) else private_map
        originals = [record['original'] for record in records]
        require(len(originals) == len(set(originals)), 'duplicate_private_marker')
        required = {'nss-marker', 'nss-m', '/home/nss-marker/yhr/Cry',
                    '10.144.144.5', '10.144.144.3', '119.45.121.134',
                    'c0e5990', 'dd67390', '0ba4cd7', '7ddcaf8'}
        require(required.issubset(originals), 'current_G2_private_markers_missing')
        old = json.loads(policy.OLD_PRIVATE_MAP.read_text())
        require(all(record in records for record in old), 'historical_private_markers_removed')
        self.private_records = records
        self.marker_digests = {record['original']: digest(record['original'].encode()) for record in records}
        self.own_markers = set()
        direct_expressions = []
        for record in records:
            if record['role'].startswith('own_source'):
                require(re.fullmatch('[0-9a-f]{7,40}', record['original']), 'invalid_own_commit_marker')
                self.own_markers.add(record['original'])
            else:
                direct_expressions.append(re.escape(record['original']))
        self.direct_expression = re.compile('|'.join(direct_expressions))
        self.own_expression = re.compile(r'(?<![A-Za-z0-9])[0-9a-f]{7,40}(?![A-Za-z0-9])')
        self.result = {'status': 'failed', 'whole_goal_complete': False,
                       'scope': 'offline_G2_reading_sources_and_direct_string_privacy_only',
                       'private_markers_checked': len(records), 'privacy_hits': [],
                       'generic_private_path_hits': [], 'errors': [], 'nested_archives_checked': 0,
                       'pdfs_scanned': 0, 'html_pages_checked': 0, 'native_mathml': 0, 'merror': 0,
                       'latex_residual_locations': [], 'local_links_checked': 0}
        self.scanned_bytes = 0
        self.approved_report = policy.report_binding(report_binding) if report_binding else None

    def public_location(self, location):
        location = self.direct_expression.sub(
            lambda match: '<marker-' + self.marker_digests[match.group()][:12] + '>', location)
        return self.own_expression.sub(
            lambda match: '<marker-' + self.marker_digests[match.group()][:12] + '>'
            if match.group() in self.own_markers else match.group(), location)

    def scan_text(self, value, location):
        for variant in {value, unescape(unquote(value))}:
            found = {match.group() for match in self.direct_expression.finditer(variant)}
            found.update(match.group() for match in self.own_expression.finditer(variant)
                         if match.group() in self.own_markers)
            for marker in found:
                hit = {'location': self.public_location(location),
                       'marker_sha256': self.marker_digests[marker]}
                if hit not in self.result['privacy_hits']:
                    self.result['privacy_hits'].append(hit)
            if not location.startswith(policy.HISTORY) and re.search(r'/Users/|/home/', variant):
                public = self.public_location(location)
                if public not in self.result['generic_private_path_hits']:
                    self.result['generic_private_path_hits'].append(public)

    def verify_reports(self, members, records):
        require(self.approved_report is not None, 'approved_report_binding_missing')
        pages = self.approved_report['pdf_pages']
        require(json.loads(members['verification/current-report.json']) == self.approved_report,
                'distributed_report_binding_changed')
        for extension in ('docx', 'pdf'):
            name = 'report/CACR2026EA16XZ-作品设计报告.' + extension
            expected = policy.REPORT / ('CACR2026EA16XZ-作品设计报告-匿名版.' + extension)
            require(members[name] == expected.read_bytes(), 'current_report_byte_identity')
            require(digest(members[name]) == self.approved_report[extension + '_sha256'],
                    'current_report_approved_digest')
            require(records[name].get('source_id') == 'CURRENT_REPORT_' + extension.upper()
                    and records[name].get('source_sha256') == digest(members[name])
                    and records[name].get('transformation') == 'none_original_bytes',
                    'current_report_neutral_source_binding')
        with zipfile.ZipFile(io.BytesIO(members['report/CACR2026EA16XZ-作品设计报告.docx'])) as report:
            core = etree.fromstring(report.read('docProps/core.xml'))
            for name in ('{http://purl.org/dc/elements/1.1/}creator',
                         '{http://schemas.openxmlformats.org/package/2006/metadata/core-properties}lastModifiedBy'):
                require(not (core.findtext(name) or '').strip(), 'docx_author_metadata')
            if 'docProps/custom.xml' in report.namelist():
                require(len(etree.fromstring(report.read('docProps/custom.xml'))) == 0,
                        'docx_custom_properties')
            app = etree.fromstring(report.read('docProps/app.xml'))
            require(app.findtext('{http://schemas.openxmlformats.org/officeDocument/2006/extended-properties}Pages')
                    == str(pages), 'docx_actual_page_cache')
        reader = PdfReader(io.BytesIO(members['report/CACR2026EA16XZ-作品设计报告.pdf']))
        require(len(reader.pages) == pages, 'actual_pdf_page_count')
        require(not str((reader.metadata or {}).get('/Author', '')).strip(), 'pdf_author_metadata')
        require(reader.xmp_metadata is None or not getattr(reader.xmp_metadata, 'dc_creator', None),
                'pdf_xmp_author_metadata')
        self.result.update(current_report_pages=pages, report_author_metadata_empty=True,
                           current_report_sha256={key: self.approved_report[key]
                                                  for key in ('docx_sha256', 'pdf_sha256')})

    def verify_scientific_sources(self, members, records):
        transformations = []
        for source_id, (source_path, expected_sha256) in policy.TEXT_SOURCES.items():
            original = (REPOSITORY / source_path).read_bytes()
            require(digest(original) == expected_sha256, 'fixed_text_source_changed')
            name = 'research/g2/' + policy.SOURCE_NAMES[source_id] + '.md'
            view, operations = reconstruct_view(source_id, original, self.private_records)
            require(members[name] == view, 'complete_anonymous_source_reconstruction')
            record = records[name]
            require(record.get('source_id') == source_id and record.get('source_sha256') == expected_sha256
                    and record.get('original_byte_count') == len(original), 'neutral_source_digest_binding')
            require(record.get('operations') == operations, 'public_view_operations_changed')
            require(all(sentence in view.decode() for sentence in policy.SCIENTIFIC_SENTENCES.get(source_id, ())),
                    'scientific_conditions_removed')
            reader_name = str(PurePosixPath(name).with_suffix('.html'))
            require(records[reader_name].get('derived_from') == name
                    and records[reader_name].get('derived_from_sha256') == digest(view),
                    'scientific_reader_source_binding')
            verify_reader(view, members[reader_name])
            transformations.append({'source_id': source_id, 'source_sha256': expected_sha256,
                                    'distributed_path': name, 'operations': operations})
        require(json.loads(members['verification/reading-transformations.json']) == transformations,
                'public_transformation_coverage_or_content')
        for source_id, (name, source_path, expected_sha256) in policy.BYTE_SOURCES.items():
            original = (REPOSITORY / source_path).read_bytes()
            require(digest(original) == expected_sha256 and members[name] == original,
                    'original_G2_data_figure_or_C_source_changed')
            require(records[name].get('source_id') == source_id
                    and records[name].get('source_sha256') == expected_sha256
                    and records[name].get('transformation') == 'none_original_bytes',
                    'original_G2_source_binding')
            if source_id.startswith(('G2_A_', 'G2_C_')):
                analysis = source_id.startswith('G2_A_')
                require(records[name].get('source_alias') == ('G2-A' if analysis else 'G2-C'),
                        'C_source_neutral_alias')
                origin = policy.ANALYSIS_COMMIT if analysis else policy.COLLECTOR_COMMIT
                committed = subprocess.run(['git', 'show', origin + ':' + source_path], cwd=REPOSITORY,
                                           capture_output=True, check=True).stdout
                require(committed == original, 'fixed_C_source_commit_byte_identity')
        inherited_protocol = members[policy.HISTORY + 'research/NEXT_VALIDATION_PROTOCOL.md'].decode()
        inherited_sentences = (
            '校准分辨率不是精度，空窗经验分位数也不是确定性误差上界；时钟允许误差及资格比例须由目标精度和测量依据决定，不自动搬用M02的100倍规则。',
            'B1—B5的资源、目标、真值、有效方法及预算门槛保持，正式确认仍为NOT_READY_TO_RUN。',
            '上述B1—B5的科学资格不由文件维护或软件自检替代。',
        )
        require(all(sentence in inherited_protocol for sentence in inherited_sentences),
                'inherited_complete_clock_or_statistical_conditions_removed')
        self.result.update(complete_scientific_views_verified=len(policy.TEXT_SOURCES),
                           original_G2_data_figures_and_offline_C_sources_verified=len(policy.BYTE_SOURCES),
                           source_reconstruction_independent_of_builder=True,
                           inherited_clock_and_B1_B5_conditions_preserved=True)

    def verify_G2_data_and_figure(self, members):
        summary = json.loads(members['data/g2/normal-summary.json'])
        expected = {'validation': 'passed', 'producer_status': 'completed', 'call_records': 126528,
                    'snapshot_records': 251, 'checkpoint_records': 1977, 'main_call_records': 101248,
                    'observed_main_pairs': 200, 'passing_main_pairs': 200, 'boundary_straddle_pairs': 1,
                    'engineering_diagnostic': 'yes', 'main_wall_ns': '4002203951'}
        require(all(summary.get(key) == value for key, value in expected.items()), 'fixed_G2_summary_values')
        require(summary['pure_main_coverage_fraction'] ==
                {'numerator_ns': '3981985286', 'denominator_ns': '4002203951'}, 'fixed_G2_geometric_coverage')
        require(3981985286 + int(summary['head_boundary_blind_ns']) + int(summary['tail_frame_blind_ns'])
                + int(summary['interior_bracket_or_uncovered_ns']) == 4002203951, 'coverage_conservation')
        require(all(summary.get(key) is False for key in
                    ('full_main_coverage_certified', 'frequency_interval_is_ci', 'physical_precision_certified',
                     'cpu18_independent_sample', 'r02_signed_off', 'r04_signed_off')), 'false_certifications_changed')
        require(all(value == 0 for value in summary['all_phase_failure_ledger'].values()), 'fixed_G2_failure_ledger')
        rows = list(csv.DictReader(io.StringIO(members['data/g2/normal-windows.csv'].decode())))
        primary = [row for row in rows if row['role'] == 'primary']
        context = [row for row in rows if row['role'] == 'context_only']
        require(len(rows) == 400 and len(primary) == len(context) == 200, 'all_CPU2_and_CPU18_windows_required')
        require(sum(row['straddles_main_start'] == 'true' for row in primary) == 1, 'first_straddle_required')
        for row in primary:
            delta = int(row['aperf_delta'])
            lower = int(row['mperf_L'])
            upper = int(row['mperf_H'])
            require(row['cpu_index'] == '2' and lower > 0 and 100 * delta >= 99 * upper
                    and 100 * delta <= 101 * lower and row['primary_rules_and_band_pass'] == 'true',
                    'all_200_primary_integer_band_results')
        require(all(row['cpu_index'] == '18' and row['exact_band'] == 'boundary_overlap' for row in context),
                'CPU18_context_not_independent_evidence')
        require(members['data/g2/parent-loss.stdout.jsonl'] == b''
                and members['data/g2/parent-loss-windows.csv'] == b'', 'partial_empty_originals_changed')
        partial = json.loads(members['data/g2/parent-loss-summary.json'])
        require(partial == {'validation': 'failed', 'reason': 'missing_summary_or_count_mismatch',
                            'line': 0, 'column': 0, 'engineering_diagnostic': 'no',
                            'r02_signed_off': False, 'r04_signed_off': False}, 'partial_unknown_rejection_changed')
        binding = json.loads(members['verification/figure-data-binding.json'])
        require(binding['primary_pairs'] == 200 and binding['primary_processes'] == 1
                and binding['pure_main_geometric_coverage'] == summary['pure_main_coverage_fraction'],
                'figure_count_and_coverage_binding')
        require(binding.get('caption_source_sha256') == policy.TEXT_SOURCES['G2_FIGURE_CAPTION'][1],
                'figure_original_caption_source_binding')
        for key, name in (('figure_pdf_sha256', 'figures/G2-window-qualification.pdf'),
                          ('figure_png_sha256', 'figures/G2-window-qualification.png'),
                          ('normal_csv_sha256', 'data/g2/normal-windows.csv'),
                          ('normal_summary_sha256', 'data/g2/normal-summary.json')):
            require(binding[key] == digest(members[name]), 'figure_artifact_or_data_binding')
        require(all(binding.get(key) is False for key in
                    ('is_pointwise_timeline', 'is_confidence_interval', 'full_main_coverage_certified',
                     'physical_precision_certified', 'cpu18_independent_sample', 'r02_signed_off', 'r04_signed_off')),
                'figure_scope_widened')
        guide = members['code/g2-analysis/README.md'].decode()
        require(all(token in guide for token in ('cmake -S code/g2-analysis', 'ctest --test-dir',
                    'data/g2/normal.stdout.jsonl', 'data/g2/parent-loss.stdout.jsonl',
                    '最后一条命令预期退出1', 'stdout为CSV、stderr为JSON摘要', '不包含采集worker',
                    'macOS/ARM和Linux/x86_64', 'PRIVATE_PROJECT_ROOT子树内',
                    '不得通过符号链接让真实落盘路径越界', 'mkdir reproduction/tmp reproduction/cache',
                    'export TMPDIR="$PWD/reproduction/tmp"', 'export TMP="$TMPDIR"',
                    'export TEMP="$TMPDIR"', 'export XDG_CACHE_HOME="$PWD/reproduction/cache"',
                    'export CCACHE_DIR="$PWD/reproduction/cache/ccache"')),
                'offline_reproduction_instructions_incomplete')
        collector_guide = members['code/g2-collector/README.md'].decode()
        require(all(token in collector_guide for token in ('完整固定参考仓库', '不是能在本补充件独立构建',
                    '../../..按原仓库布局解释', '本包没有放行硬件采集的运行命令', '可执行二进制均未分发')),
                'collector_static_audit_scope_incomplete')
        self.result.update(imported_existing_G2_normal_call_records=126528,
                           imported_existing_G2_completed_processes=1, primary_pairs=200,
                           pure_main_coverage_fraction=summary['pure_main_coverage_fraction'],
                           partial_unknown_and_all_four_C_outputs_preserved=True,
                           offline_C_analysis_source_exception_verified=True,
                           original_collector_static_source_exception_verified=True,
                           fixed_C_source_commit_byte_bindings_verified=4)

    def verify_navigation(self, members, pages, edges):
        reachable = {'index.html'}
        pending = ['index.html']
        while pending:
            for target in edges.get(pending.pop(), ()):
                if target not in reachable:
                    reachable.add(target)
                    pending.append(target)
        required = {'report/CACR2026EA16XZ-作品设计报告.pdf', 'report/CACR2026EA16XZ-作品设计报告.docx',
                    'code/g2-analysis/README.md', 'code/g2-analysis/analyze_windows.c',
                    'code/g2-analysis/CMakeLists.txt',
                    'code/g2-collector/README.md', 'code/g2-collector/frequency_workload.c',
                    'code/g2-collector/CMakeLists.txt',
                    policy.HISTORY + 'research/WEAK_MEAN_PROOF_PACKAGE.html',
                    policy.HISTORY + 'research/NEXT_VALIDATION_PROTOCOL.html',
                    policy.HISTORY + 'historical/20261009/research/PROOF_PACKAGE.html',
                    policy.HISTORY + 'historical/20261009/research/FINITE_REFERENCE_BOUNDARY.html'}
        required.update('research/g2/' + name + '.html' for name in policy.SOURCE_NAMES.values())
        required.update(row[0] for row in policy.BYTE_SOURCES.values())
        require(required.issubset(reachable), 'current_entrypoint_reading_or_reproduction_targets_unreachable')
        for name, contents in members.items():
            if name.startswith(policy.HISTORY) or not name.endswith('.md'):
                continue
            for raw in re.findall(r'\[[^\]]+\]\(([^)]+)\)', contents.decode()):
                parsed = urlsplit(raw)
                if parsed.scheme or parsed.netloc:
                    require(parsed.scheme in ('https', 'http'), 'unsafe_markdown_navigation')
                    continue
                target = posixpath.normpath(posixpath.join(posixpath.dirname(name), unquote(parsed.path)))
                require(target in members and not target.startswith('../'), 'new_markdown_target_missing')
                if parsed.fragment and target in pages:
                    require(unquote(parsed.fragment) in pages[target].identifiers, 'new_markdown_fragment_missing')
        self.result['required_reading_and_reproduction_targets_reachable'] = len(required)

    def verify(self, archive_path):
        require(digest(policy.OLD_ZIP.read_bytes()) == policy.OLD_SHA256, 'old_archive_identity')
        with zipfile.ZipFile(archive_path) as archive:
            entries = archive.infolist()
            require(len(entries) == len({entry.filename for entry in entries}), 'duplicate_archive_member')
            require(all(not entry.is_dir() and entry.file_size <= base.MAX_MEMBER_BYTES for entry in entries),
                    'archive_directory_or_large_member')
            require(sum(entry.file_size for entry in entries) <= base.MAX_SCANNED_BYTES, 'archive_byte_budget')
            require(archive.testzip() is None, 'archive_crc')
            members = {}
            for entry in entries:
                base.safe_member(entry.filename)
                require(not stat.S_ISLNK(entry.external_attr >> 16), 'archive_symlink')
                members[entry.filename] = archive.read(entry)
        with zipfile.ZipFile(policy.OLD_ZIP) as old:
            require(len(old.namelist()) == policy.OLD_MEMBER_COUNT, 'old_member_count')
            require(all(members.get(policy.HISTORY + name) == old.read(name) for name in old.namelist()),
                    'all_887_historical_member_bytes')
            require({name[len(policy.HISTORY):] for name in members if name.startswith(policy.HISTORY)}
                    == set(old.namelist()), 'historical_membership_exact')
        expected_new = {'index.html', 'README.md', 'reader.css', 'manifest.json', 'SHA256SUMS',
                        'verification/current-report.json', 'verification/reading-transformations.json',
                        'verification/figure-data-binding.json', 'report/CACR2026EA16XZ-作品设计报告.pdf',
                        'report/CACR2026EA16XZ-作品设计报告.docx', 'code/g2-analysis/README.md',
                        'code/g2-collector/README.md'}
        expected_new.update('research/g2/' + name + suffix
                            for name in policy.SOURCE_NAMES.values() for suffix in ('.md', '.html'))
        expected_new.update(row[0] for row in policy.BYTE_SOURCES.values())
        require({name for name in members if not name.startswith(policy.HISTORY)} == expected_new,
                'new_distribution_file_whitelist')
        records = self.verify_manifest(members)
        manifest = json.loads(members['manifest.json'])
        require(manifest.get('parent_archive_sha256') == policy.OLD_SHA256
                and manifest.get('parent_member_count') == 887
                and manifest.get('historical_subroot') == policy.HISTORY, 'new_manifest_historical_scope')
        require(manifest.get('packaging_new_cryptographic_calls') == 0
                and manifest.get('packaging_new_timing_runs') == 0
                and manifest.get('packaging_new_C_analysis') is False
                and manifest.get('imported_existing_G2_normal_call_records') == 126528
                and manifest.get('imported_existing_G2_completed_processes') == 1
                and manifest.get('R02') == manifest.get('R04') == 'partial'
                and manifest.get('whole_goal_complete') is False, 'packaging_and_imported_execution_roles')
        require(manifest.get('offline_C_source_exception') ==
                {'source_alias': 'G2-A', 'files': ['code/g2-analysis/analyze_windows.c',
                                                  'code/g2-analysis/CMakeLists.txt'],
                 'binaries_distributed': False, 'hardware_or_administrator_entrypoint': False},
                'offline_C_exception_scope_changed')
        require(manifest.get('collector_C_source_exception') ==
                {'source_alias': 'G2-C', 'files': ['code/g2-collector/frequency_workload.c',
                                                   'code/g2-collector/CMakeLists.txt'],
                 'purpose': 'static_source_audit', 'standalone_build_in_this_archive': False,
                 'privileged_management_or_deployment_shipped': False, 'binaries_distributed': False,
                 'sealed_native_regular_elf_sha256': policy.COLLECTOR_NATIVE_ELF_SHA256,
                 'new_native_build_or_execution': False}, 'collector_C_exception_or_native_provenance_changed')
        require(all('source_path' not in record for name, record in records.items()
                    if not name.startswith(policy.HISTORY)), 'public_actual_source_path_disallowed')
        require(manifest.get('current_report_pages') == self.approved_report['pdf_pages'],
                'manifest_current_report_page_binding')
        self.verify_reports(members, records)
        self.verify_scientific_sources(members, records)
        self.verify_G2_data_and_figure(members)
        for name, contents in members.items():
            if not name.startswith(policy.HISTORY):
                require(PurePosixPath(name).suffix.lower() not in ('.py', '.sh'), 'new_script_disallowed')
                require(not contents.startswith((b'\x7fELF', b'\xcf\xfa\xed\xfe', b'\xfe\xed\xfa\xcf')),
                        'new_executable_binary_disallowed')
            self.scan(contents, name)
        pages, edges = self.verify_html(members)
        self.verify_navigation(members, pages, edges)
        if self.result['privacy_hits'] or self.result['generic_private_path_hits']:
            self.error('direct_private_marker_or_private_absolute_path')
        self.result.update(archive_sha256=digest(archive_path.read_bytes()), archive_files=len(members),
                           legacy_members_preserved=887, legacy_prefix=policy.HISTORY,
                           scanned_bytes=self.scanned_bytes, zip_crc_verified=True,
                           packaging_new_cryptographic_calls=0, packaging_new_timing_runs=0,
                           current_report_approved_before_packaging=True)
        if not self.result['errors']:
            self.result['status'] = 'passed_bounded_G2_reading_sources_and_direct_string_privacy'


def self_check():
    records = policy.private_records()
    audit = Audit(records)
    fixtures = []
    for source_id, (source_path, expected) in policy.TEXT_SOURCES.items():
        original = (REPOSITORY / source_path).read_bytes()
        require(digest(original) == expected, 'selfcheck_fixed_source_identity')
        view, operations = reconstruct_view(source_id, original, records)
        built_view, built_operations = policy.public_view(source_id, original, records)
        require((view, operations) == (built_view, built_operations), 'independent_view_reconstruction_mismatch')
        verify_reader(view, policy.render(source_id, view.decode()))
        require(operations[-1]['kind'] == 'insert_public_view_notice', 'notice_operation_missing')
        if source_id in policy.SCIENTIFIC_SENTENCES:
            sentence = policy.SCIENTIFIC_SENTENCES[source_id][0]
            changed = view.decode().replace(sentence, '', 1).encode()
            require(changed != view, 'negative_scientific_fixture_not_changed')
            try:
                verify_reader(view, policy.render(source_id, changed.decode()))
            except Rejected:
                fixtures.append('reject_removed_scientific_sentence_' + source_id)
            else:
                raise Rejected('negative_scientific_reader_fixture_accepted')
        audit.scan_text(view.decode(), 'research/g2/' + source_id + '.md')
    require(not audit.result['privacy_hits'] and not audit.result['generic_private_path_hits'],
            'positive_source_views_have_private_identity')
    for source_id in ('G2_A_ANALYZER', 'G2_A_CMAKE', 'G2_C_COLLECTOR', 'G2_C_CMAKE'):
        name, source_path, expected = policy.BYTE_SOURCES[source_id]
        contents = (REPOSITORY / source_path).read_bytes()
        require(digest(contents) == expected, 'selfcheck_original_C_source_changed')
        origin = policy.ANALYSIS_COMMIT if source_id.startswith('G2_A_') else policy.COLLECTOR_COMMIT
        committed = subprocess.run(['git', 'show', origin + ':' + source_path], cwd=REPOSITORY,
                                   capture_output=True, check=True).stdout
        require(contents == committed, 'selfcheck_C_source_fixed_commit_identity')
        audit.scan_text(contents.decode(), name)
    require(not audit.result['privacy_hits'] and not audit.result['generic_private_path_hits'],
            'original_C_source_has_private_identity')
    audit.scan_text('path/run-0ba4cd7/record', 'negative_embedded_own_source_path')
    require(audit.result['privacy_hits'], 'embedded_own_source_marker_not_rejected')
    fixtures.append('reject_own_source_marker_embedded_in_path')
    audit.scan_text('/home/unregistered-private-account/project', 'negative_unknown_private_home')
    require(audit.result['generic_private_path_hits'], 'unknown_private_home_not_rejected')
    fixtures.append('reject_unregistered_private_absolute_home')
    page = base.Page()
    page.feed('<html><script>active()</script><p onclick="active()">x</p></html>')
    require('active_or_base_element' in page.problems and 'event_attribute' in page.problems,
            'active_html_fixture_accepted')
    fixtures.append('reject_active_HTML')
    print(json.dumps({'self_check': 'passed', 'positive_complete_source_views': len(policy.TEXT_SOURCES),
                      'original_offline_C_sources': 2, 'original_collector_static_sources': 2,
                      'fixed_C_source_commit_byte_bindings': 4, 'negative_fixtures': fixtures,
                      'final_archive_generated': False, 'report_assumptions_used': False,
                      'new_C_or_cryptographic_execution': False, 'whole_goal_complete': False}))


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('archive', type=Path, nargs='?')
    parser.add_argument('output_json', type=Path, nargs='?')
    parser.add_argument('--private-map', type=Path)
    parser.add_argument('--report-binding', type=Path)
    parser.add_argument('--self-check', action='store_true')
    arguments = parser.parse_args()
    if arguments.self_check:
        self_check()
        return 0
    if any(value is None for value in (arguments.archive, arguments.output_json,
                                       arguments.private_map, arguments.report_binding)):
        parser.error('archive, output_json, --private-map and --report-binding are required')
    audit = None
    try:
        audit = Audit(arguments.private_map, arguments.report_binding)
        audit.verify(arguments.archive)
    except Exception as error:
        if audit is None:
            result = {'status': 'failed', 'whole_goal_complete': False,
                      'errors': [{'check': 'audit_initialization', 'type': type(error).__name__}]}
        else:
            audit.error(str(error) if isinstance(error, Rejected) else 'verification_exception')
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
    return 0 if result['status'] == 'passed_bounded_G2_reading_sources_and_direct_string_privacy' else 1


if __name__ == '__main__':
    raise SystemExit(main())
