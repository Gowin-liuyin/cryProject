import argparse
import hashlib
import html
import json
from pathlib import Path
import re
import subprocess
import zipfile


ROOT = Path(__file__).resolve().parents[3]
WORK = ROOT / 'build/aris-g2-package-20261010'
OLD_ZIP = ROOT / 'deliverables/support/CACR2026EA16XZ-mean-inference-20261010/CACR2026EA16XZ-均值推断与研究材料补充件.zip'
OLD_SHA256 = 'ec076852eb68223eecbceb4ff5a60bcabbc08e8fce317d99f1b4014fd9bfe5c6'
OLD_MEMBER_COUNT = 887
HISTORY = 'historical/20261010-mean-inference/'
REPORT = ROOT / 'deliverables/research/aris-report-g2-20261010'
OLD_PRIVATE_MAP = ROOT / 'docs/evidence/aris-current-package-20261009/private-substitution-map.json'
SOURCE_ROOT = 'docs/research/aris-frequency-window-20261010/'
EVIDENCE_ROOT = 'docs/evidence/frequency-window-20261010/run-0ba4cd7/'
ANALYSIS_COMMIT = 'dd67390f1e41d76624bf3a8854feacacfb8d1f85'
COLLECTOR_COMMIT = 'c0e5990bd4d764fbb08ff6857a2cf6cf21c9b8a2'
COLLECTOR_NATIVE_ELF_SHA256 = '023f56460a8dc4971e8132a22c5734ca0844314d3d71b8bc3b129a424e9ee69b'
NOTICE = ('本文件为匿名公开技术视图，原件摘要及全部变换另列。只作身份、链接与阅读声明变换，'
          '原科学段落及准备／实际执行的历史时点保留；完整管理原件保留作者侧，'
          '本补充件的阅读闭包不认证物理精度、逐调用恒频或R02/R04。')

TEXT_SOURCES = {
    'G2_EXPERIMENT_PLAN': (SOURCE_ROOT + 'EXPERIMENT_PLAN.md',
                           '0c9261a50df9a55aa80e640ad6f746a56df0194c5763e79f52d68031bd94f67e'),
    'G2_RESULTS': (SOURCE_ROOT + 'RESULTS.md',
                   '823bcc32883191a1b6220e749ac8aeb783ec5121489941a8b782a218249495f9'),
    'G2_RESULT_TO_CLAIM': (SOURCE_ROOT + 'RESULT_TO_CLAIM.md',
                           '7a6067595e28c3408ab6b3fee96c301fb14829d1d8e12af72e1dff33a2142189'),
    'G2_TOOL_CONTRACT': (SOURCE_ROOT + 'README.md',
                         'a3bd75a9e616b1ff4487c8b0e7d526eb5aa87a7a52ff858b3ef4010b9ed38732'),
    'G2_SCIENTIFIC_REVIEW': (EVIDENCE_ROOT + 'SCIENTIFIC_REVIEW.md',
                             'a0a2ce23aba5387a22fc685a910857dad89401d19a62ae7862f40c25df30cba5'),
    'G2_ARTIFACT_REVIEW': (EVIDENCE_ROOT + 'ARTIFACT_REVIEW.md',
                           '0c7b4f509fa28e79e12de60026c58a8b636f7751cec2060e36e630f545f0e43c'),
    'G2_FIGURE_CAPTION': (SOURCE_ROOT + 'figures/fig-g2-window-qualification.caption.md',
                          '178b18b2baf5ae06708ed802838c634cba1b7b48a4d523591efd59455fefbc64'),
}
SOURCE_NAMES = {
    'G2_EXPERIMENT_PLAN': 'EXPERIMENT_PLAN', 'G2_RESULTS': 'RESULTS',
    'G2_RESULT_TO_CLAIM': 'RESULT_TO_CLAIM', 'G2_TOOL_CONTRACT': 'TOOL_CONTRACT',
    'G2_SCIENTIFIC_REVIEW': 'SCIENTIFIC_REVIEW', 'G2_ARTIFACT_REVIEW': 'ARTIFACT_REVIEW',
    'G2_FIGURE_CAPTION': 'FIGURE_CAPTION',
}
BYTE_SOURCES = {
    'G2_NORMAL_RAW': ('data/g2/normal.stdout.jsonl', EVIDENCE_ROOT + 'originals/normal/worker.stdout.jsonl',
                       'c29a9ca0e28ffad53aaeb0e0c0097fd560d048f5eee4803885cb56850a989028'),
    'G2_NORMAL_WINDOWS': ('data/g2/normal-windows.csv', EVIDENCE_ROOT + 'analysis/normal-windows.csv',
                           '9927e729dc3ccb64d8dbf658eea396d9e5258c80aecdf20b243395991a948a06'),
    'G2_NORMAL_SUMMARY': ('data/g2/normal-summary.json', EVIDENCE_ROOT + 'analysis/normal-summary.json',
                           '6f37ab32330c267898b6ff7e9f5ad2b326e9a0ecdde4164a50e69454dda4f518'),
    'G2_PARENT_LOSS_RAW': ('data/g2/parent-loss.stdout.jsonl', EVIDENCE_ROOT + 'originals/parent-loss/worker.stdout.jsonl',
                            'e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855'),
    'G2_PARENT_LOSS_WINDOWS': ('data/g2/parent-loss-windows.csv', EVIDENCE_ROOT + 'analysis/parent-loss-windows.csv',
                                'e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855'),
    'G2_PARENT_LOSS_SUMMARY': ('data/g2/parent-loss-summary.json', EVIDENCE_ROOT + 'analysis/parent-loss-summary.json',
                                '08550731ca7ab0bc91aff7925b13b3ae0314d8be7fbf2529ba5e48b4ae1728c0'),
    'G2_FIGURE_PDF': ('figures/G2-window-qualification.pdf', SOURCE_ROOT + 'figures/fig-g2-window-qualification.pdf',
                       'ff5735eded7807651a829a828c4615a34a17e4a0a6ec905c854940ee01e71906'),
    'G2_FIGURE_PNG': ('figures/G2-window-qualification.png', SOURCE_ROOT + 'figures/fig-g2-window-qualification.png',
                       'ef47cae6a8767a4090c912ad6e317334b0d059b35946d80b8d2358e87e6cb014'),
    'G2_A_ANALYZER': ('code/g2-analysis/analyze_windows.c',
                        'docs/research/aris-frequency-window-analysis-20261010/analyze_windows.c',
                        '5c028abf419df5b5459c167469f44724faba12542b446799c5c5fc6b02d5a9f4'),
    'G2_A_CMAKE': ('code/g2-analysis/CMakeLists.txt',
                     'docs/research/aris-frequency-window-analysis-20261010/CMakeLists.txt',
                     '77bf9057451b767cabef888e9d5acaeada64a76d6de292f7dfee6c8e64444c61'),
    'G2_C_COLLECTOR': ('code/g2-collector/frequency_workload.c', SOURCE_ROOT + 'frequency_workload.c',
                         '520bdc1bbcc1bbd805674a39c639e1cbcd13e66ae0b44dba78688115f02ef7f0'),
    'G2_C_CMAKE': ('code/g2-collector/CMakeLists.txt', SOURCE_ROOT + 'CMakeLists.txt',
                     'e4202fa76f6f82b04914096978ae18c7fc0db5255c43eced2c32fb3a9d45c792'),
}
LINK_REPLACEMENTS = {
    'G2_EXPERIMENT_PLAN': {
        '[G1](../aris-frequency-control-20261010/RESULTS.md)':
            'G1前置阶段（该阶段原件未随本补充件新增；下文完整保留冻结的衔接及分析条件）',
        '[README](README.md)': '[工具完整合同](TOOL_CONTRACT.html)',
    },
    'G2_RESULTS': {
        '[run-0ba4cd7](../../evidence/frequency-window-20261010/run-0ba4cd7/README.md)':
            '[实际采集、取消及恢复的独立复核](ARTIFACT_REVIEW.html)',
        'figures/fig-g2-window-qualification.pdf': '../../figures/G2-window-qualification.pdf',
        'figures/fig-g2-window-qualification.png': '../../figures/G2-window-qualification.png',
        'RESULT_TO_CLAIM.md': 'RESULT_TO_CLAIM.html',
    },
    'G2_RESULT_TO_CLAIM': {
        'EXPERIMENT_PLAN.md': 'EXPERIMENT_PLAN.html',
        '../../evidence/frequency-window-20261010/run-0ba4cd7/README.md': 'ARTIFACT_REVIEW.html',
        '../../evidence/frequency-window-20261010/run-0ba4cd7/SCIENTIFIC_REVIEW.md': 'SCIENTIFIC_REVIEW.html',
    },
    'G2_TOOL_CONTRACT': {
        '[RESULTS](RESULTS.md)': '[实际G2结果](RESULTS.html)',
        '[真实Linux软件预检](../../evidence/frequency-window-20261010/linux-7e93048/README.md)':
            '真实Linux软件预检（历史准备件，未随本补充件新增；本段保留其原时点）',
    },
    'G2_SCIENTIFIC_REVIEW': {
        'originals/normal/worker.stdout.jsonl': '../../data/g2/normal.stdout.jsonl',
        'analysis/normal-windows.csv': '../../data/g2/normal-windows.csv',
        'analysis/normal-summary.json': '../../data/g2/normal-summary.json',
    },
}
SCIENTIFIC_SENTENCES = {
    'G2_EXPERIMENT_PLAN': (
        '每路径最多一次，顺序执行。',
        '该路径可没有缓冲输出，\n   不从空文件重建调用数或测量结果。',
        '工程带固定 4257—4343 MHz；CPU2 保守线程 CPU/RAW 活动代理至少 80%，三读跨度至多\n1 ms，相邻快照至多 40 ms。',
        '即使所有观测窗口通过，\n`full_main_coverage_certified`、R02 总体及 R04 仍为 false；',
    ),
    'G2_RESULTS': (
        '所有逐次值和普通长尾保留；没有按窗口结果补采、筛选或合并其他运行。',
        '200个窗口来自一个完成进程，八个密文循环也不是独立同分布样本。',
        '不证明隐藏QoS或固件内部状态逐位复原。',
    ),
    'G2_TOOL_CONTRACT': (
        '它是调度活动代理，\n不换算精确 C0 占比。',
        '同类时钟出现逆序时保留原纳秒值并标记 ERANGE，停止负载，不裁成零或静默继续。',
        'SIGKILL、崩溃或断电会失去尚未输出的部分，不能由本工具\n声称已持久保存。',
    ),
    'G2_SCIENTIFIC_REVIEW': (
        '200 个 pair 来自 **一个完成进程**，不是 200 次独立重复。',
        '单调、同一计数时期与无重置的条件不能由解析成功单独证明。',
        '`3981985286 + 20170432 + 13224 + 35009 = 4002203951 ns`。',
        '**不表示执行了零次密码操作**',
    ),
    'G2_ARTIFACT_REVIEW': (
        '0 字节不等于执行了零次调用，也不证明进入或没有进入主观察。',
        '覆盖全部 32 策略、global、CPU links 和属性身份。',
        '不称跨整段原子快照',
    ),
    'G2_FIGURE_CAPTION': (
        '此条为合计比例，不是时间线。',
        '读取对齐区间不是置信区间或完整物理误差界',
        '200窗来自一个进程，不能视为200个独立重复。',
    ),
}


def digest(contents):
    return hashlib.sha256(contents).hexdigest()


def require(condition, label):
    if not condition:
        raise ValueError(label)


def marker_pattern(record):
    expression = re.escape(record['original'])
    if record['role'].startswith('own_source'):
        expression = r'(?<![A-Za-z0-9])' + expression + r'(?![A-Za-z0-9])'
    return expression


def private_records():
    records = json.loads(OLD_PRIVATE_MAP.read_text())
    present = {record['original'] for record in records}
    additions = {
        '/home/nss-marker/yhr/Cry': ('PRIVATE_PROJECT_ROOT', 'participant_current_project_root'),
        '/home/nss-marker/yhr': ('PRIVATE_PROJECT_PARENT', 'participant_current_project_parent'),
        '/home/nss-marker': ('PARTICIPANT_REMOTE_HOME', 'participant_current_remote_home'),
        'nss-marker': ('PARTICIPANT_REMOTE_ACCOUNT', 'participant_current_remote_account'),
        'nss-m': ('MEASUREMENT_HOST', 'participant_current_hostname'),
        '10.144.144.5': ('MEASUREMENT_ADDRESS', 'participant_current_address'),
        '10.144.144.3': ('HISTORICAL_REMOTE_ADDRESS', 'participant_configured_address'),
        '119.45.121.134': ('HISTORICAL_KVM_ADDRESS', 'participant_historical_address'),
        'core-window-20261010-51d37af52b90': ('G2_PRIVATE_ARCHIVE', 'participant_original_archive_token'),
    }
    for original, (replacement, role) in additions.items():
        if original not in present:
            records.append({'original': original, 'replacement': replacement, 'role': role})
            present.add(original)
    revisions = subprocess.run(['git', 'rev-list', '--all'], cwd=ROOT, text=True,
                               capture_output=True, check=True).stdout.splitlines()
    for number, revision in enumerate(sorted(revisions), 1):
        require(re.fullmatch('[0-9a-f]{40}', revision), 'invalid_own_revision')
        for size in (40, 12, 8, 7):
            original = revision[:size]
            if original not in present:
                records.append({'original': original,
                                'replacement': f'OWN_SOURCE_G2_{number:04d}',
                                'role': 'own_source_commit_alias_not_git_identity'})
                present.add(original)
    return sorted(records, key=lambda record: (-len(record['original']), record['original']))


def source_bytes(relative_path, expected_sha256):
    contents = (ROOT / relative_path).read_bytes()
    require(digest(contents) == expected_sha256, 'fixed_source_identity_changed')
    return contents


def public_view(source_id, contents, records):
    value = contents.decode('utf-8')
    operations = []
    for original, replacement in LINK_REPLACEMENTS.get(source_id, {}).items():
        count = value.count(original)
        require(count > 0, 'declared_link_source_changed')
        value = value.replace(original, replacement)
        operations.append({'kind': 'reading_link_or_explicit_omission',
                           'original_token_sha256': digest(original.encode()),
                           'replacement': replacement, 'count': count})
    for record in records:
        value, count = re.subn(marker_pattern(record), lambda match: record['replacement'], value)
        if count:
            operations.append({'kind': 'anonymous_identity_token',
                               'marker_sha256': digest(record['original'].encode()),
                               'replacement': record['replacement'], 'role': record['role'], 'count': count})
    lines = value.split('\n', 1)
    if value.startswith('# '):
        value = lines[0] + '\n\n' + NOTICE + '\n' + (lines[1] if len(lines) > 1 else '')
        position = 'after_first_heading'
    else:
        value = NOTICE + '\n\n' + value
        position = 'before_original_caption'
    operations.append({'kind': 'insert_public_view_notice', 'position': position,
                       'text': NOTICE, 'text_sha256': digest(NOTICE.encode())})
    require(all(sentence in value for sentence in SCIENTIFIC_SENTENCES.get(source_id, ())),
            'scientific_sentence_removed')
    return value.encode(), operations


def render(source_id, markdown):
    def inline(value):
        value = html.escape(value)
        value = re.sub(r'\[([^\]]+)\]\(([^)]+)\)',
                       lambda match: '<a href="' + html.escape(html.unescape(match[2]), quote=True)
                       + '">' + match[1] + '</a>', value)
        value = re.sub(r'\*\*([^*]+)\*\*', r'<strong>\1</strong>', value)
        return re.sub(r'`([^`]+)`', r'<code>\1</code>', value)

    parts = []
    paragraph = []
    table = []
    code = []
    in_code = False
    heading_count = 0

    def flush_paragraph():
        if paragraph:
            parts.append('<p>' + inline(' '.join(paragraph)) + '</p>')
            paragraph.clear()

    def flush_table():
        if table:
            rows = [line.strip().strip('|').split('|') for line in table]
            rows = [row for row in rows if not all(re.fullmatch(r'[:\-\s]+', cell) for cell in row)]
            parts.append('<div class="table-wrap"><table><thead><tr>'
                         + ''.join('<th>' + inline(cell.strip()) + '</th>' for cell in rows[0])
                         + '</tr></thead><tbody>'
                         + ''.join('<tr>' + ''.join('<td>' + inline(cell.strip()) + '</td>'
                                                   for cell in row) + '</tr>' for row in rows[1:])
                         + '</tbody></table></div>')
            table.clear()

    for line in markdown.splitlines():
        if line.startswith('```'):
            flush_paragraph()
            flush_table()
            if in_code:
                parts.append('<pre><code>' + html.escape('\n'.join(code)) + '</code></pre>')
                code.clear()
            in_code = not in_code
            continue
        if in_code:
            code.append(line)
            continue
        if line.startswith('|'):
            flush_paragraph()
            table.append(line)
            continue
        flush_table()
        if not line.strip():
            flush_paragraph()
            continue
        heading = re.match(r'^(#{1,6})\s+(.*)', line)
        if heading:
            flush_paragraph()
            heading_count += 1
            level = len(heading[1])
            parts.append(f'<h{level} id="section-{heading_count}">'
                         + inline(heading[2]) + f'</h{level}>')
        else:
            paragraph.append(line)
    require(not in_code, 'unterminated_markdown_code_block')
    flush_paragraph()
    flush_table()
    title = markdown.splitlines()[0].lstrip('# ')
    figure = ('<figure><img src="../../figures/G2-window-qualification.png" '
              'alt="一次普通参考进程的全部200个主窗口及合计几何覆盖" '
              'style="max-width:100%;height:auto"><p><a href="../../figures/G2-window-qualification.pdf">'
              '矢量PDF</a></p></figure>') if source_id == 'G2_FIGURE_CAPTION' else ''
    return ('<!doctype html><html lang="zh-CN"><head><meta charset="utf-8">'
            '<meta name="viewport" content="width=device-width,initial-scale=1"><title>'
            + html.escape(title) + '</title><link rel="stylesheet" href="../../reader.css"></head>'
            '<body><main class="reading"><nav><a href="../../index.html">返回新版材料索引</a> · '
            f'<a href="{SOURCE_NAMES[source_id]}.md">Markdown匿名视图</a></nav>' + figure
            + '<article>' + ''.join(parts) + '</article></main></body></html>').encode()


def report_binding(path):
    binding = json.loads(path.read_text())
    require(binding.get('approved_for_packaging') is True, 'report_not_approved_for_packaging')
    for extension in ('docx', 'pdf'):
        expected = binding.get(extension + '_sha256', '')
        require(re.fullmatch('[0-9a-f]{64}', expected), 'missing_report_digest')
        source = REPORT / ('CACR2026EA16XZ-作品设计报告-匿名版.' + extension)
        require(digest(source.read_bytes()) == expected, 'report_identity_changed')
    require(isinstance(binding.get('pdf_pages'), int) and binding['pdf_pages'] > 0,
            'missing_actual_report_page_count')
    return {key: binding[key] for key in ('docx_sha256', 'pdf_sha256', 'pdf_pages', 'approved_for_packaging')}


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('stage_name')
    parser.add_argument('--report-binding', type=Path, required=True)
    arguments = parser.parse_args()
    require(re.fullmatch(r'payload-[a-z0-9-]+', arguments.stage_name), 'invalid_stage_name')
    approved_report = report_binding(arguments.report_binding)
    require(digest(OLD_ZIP.read_bytes()) == OLD_SHA256, 'old_archive_identity_changed')
    payload = WORK / arguments.stage_name
    payload.mkdir(parents=True, exist_ok=False)
    records = {}
    private_map = private_records()
    author_map = WORK / (arguments.stage_name + '-private-substitution-map.json')
    author_sources = WORK / (arguments.stage_name + '-author-source-bindings.json')
    for path in (author_map, author_sources):
        require(not path.exists(), 'author_record_exists')
    author_map.write_text(json.dumps(private_map, ensure_ascii=False, indent=2) + '\n')
    author_bindings = []

    def put(name, contents, role, source_id=None, original=None, operations=None):
        require(name not in records, 'duplicate_distributed_member')
        destination = payload / name
        destination.parent.mkdir(parents=True, exist_ok=True)
        destination.write_bytes(contents)
        record = {'distributed_path': name, 'distributed_copy_sha256': digest(contents),
                  'distributed_byte_count': len(contents), 'content_role': role}
        if source_id is not None:
            record.update(source_id=source_id, source_sha256=digest(original),
                          original_byte_count=len(original),
                          transformation='none_original_bytes' if original == contents else 'declared_public_view')
        else:
            record['transformation'] = 'generated_reading_or_verification_metadata'
        if operations is not None:
            record['operations'] = operations
        records[name] = record

    with zipfile.ZipFile(OLD_ZIP) as old:
        require(len(old.infolist()) == OLD_MEMBER_COUNT and old.testzip() is None, 'old_archive_members_or_crc')
        for member in old.infolist():
            path = Path(member.filename)
            require(not member.is_dir() and not path.is_absolute() and '..' not in path.parts,
                    'unsafe_old_member')
            name = HISTORY + member.filename
            put(name, old.read(member), 'unchanged_historical_mean_inference_member')
            records[name].update(parent_archive_sha256=OLD_SHA256, parent_archive_member=member.filename,
                                 transformation='none_parent_archive_bytes')
        put('reader.css', old.read('reader.css'), 'static_local_stylesheet')

    transformations = []
    for source_id, (source_path, expected) in TEXT_SOURCES.items():
        original = source_bytes(source_path, expected)
        view, operations = public_view(source_id, original, private_map)
        markdown_name = 'research/g2/' + SOURCE_NAMES[source_id] + '.md'
        put(markdown_name, view, 'anonymous_complete_scientific_source_view', source_id, original, operations)
        reader_name = 'research/g2/' + SOURCE_NAMES[source_id] + '.html'
        put(reader_name, render(source_id, view.decode()), 'static_complete_scientific_reader')
        records[reader_name].update(derived_from=markdown_name, derived_from_sha256=digest(view))
        transformations.append({'source_id': source_id, 'source_sha256': digest(original),
                                'distributed_path': markdown_name, 'operations': operations})
        author_bindings.append({'source_id': source_id, 'source_path': source_path, 'source_sha256': digest(original)})
    for source_id, (distributed_path, source_path, expected) in BYTE_SOURCES.items():
        original = source_bytes(source_path, expected)
        is_analysis_source = source_id.startswith('G2_A_')
        is_collector_source = source_id.startswith('G2_C_')
        if is_analysis_source or is_collector_source:
            text = original.decode('utf-8')
            require(not any(re.search(marker_pattern(record), text) for record in private_map),
                    'original_C_source_has_private_marker')
            require(not re.search(r'/home/|/Users/', text), 'original_C_source_has_private_absolute_path')
        put(distributed_path, original,
            'original_offline_C_analysis_source' if is_analysis_source else
            ('original_collector_source_for_static_audit' if is_collector_source else 'original_sealed_G2_data_or_figure'),
            source_id, original)
        binding = {'source_id': source_id, 'source_path': source_path, 'source_sha256': digest(original)}
        if is_analysis_source or is_collector_source:
            origin = ANALYSIS_COMMIT if is_analysis_source else COLLECTOR_COMMIT
            committed = subprocess.run(['git', 'show', origin + ':' + source_path], cwd=ROOT,
                                       capture_output=True, check=True).stdout
            require(committed == original, 'fixed_C_source_commit_byte_identity')
            records[distributed_path]['source_alias'] = 'G2-A' if is_analysis_source else 'G2-C'
            binding['source_commit'] = origin
        author_bindings.append(binding)
    analysis_readme = '''# G2-A：已封存普通参考窗口的离线科学复算

本目录只分发原字节C11分析源与CMake配置，不包含采集worker、管理员、SSH或恢复程序，也不附可执行二进制。它只读取包内已经取得的JSONL；构建、CTest及以下复算不会访问硬件计数器、生成密钥或启动新的密码负载。原始normal的126528次调用来自已封存G2；中断stdout为空保持部分或未知，不能解释为零操作。

G2-A既有软件验证覆盖macOS/ARM和Linux/x86_64，以下离线构建及复算说明限于这两类环境；需要CMake3.21以上和GCC／Clang，分析源不需要第三方库。这是普通软件复算，动态检查须另建构建目录，不构成新的硬件采集或测时证据。

云端使用时，压缩包、解压目录、构建、临时文件、缓存与复算输出都必须实际位于已获授权的PRIVATE_PROJECT_ROOT子树内；不得通过符号链接让真实落盘路径越界。PRIVATE_PROJECT_ROOT是中性名称，实际目录由已有授权确定。本机复算在新的本地工作树内进行。先进入相应的新解压包根目录，再执行下面的相对命令；`reproduction`必须尚不存在，避免覆盖原件或旧复算。

```sh
mkdir reproduction
mkdir reproduction/tmp reproduction/cache
export TMPDIR="$PWD/reproduction/tmp"
export TMP="$TMPDIR"
export TEMP="$TMPDIR"
export XDG_CACHE_HOME="$PWD/reproduction/cache"
export CCACHE_DIR="$PWD/reproduction/cache/ccache"
cmake -S code/g2-analysis -B reproduction/g2-analysis -DBUILD_TESTING=ON
cmake --build reproduction/g2-analysis --parallel 4
ctest --test-dir reproduction/g2-analysis --output-on-failure
mkdir reproduction/g2-output
reproduction/g2-analysis/analyze_windows data/g2/normal.stdout.jsonl > reproduction/g2-output/normal-windows.csv 2> reproduction/g2-output/normal-summary.json
cmp data/g2/normal-windows.csv reproduction/g2-output/normal-windows.csv
cmp data/g2/normal-summary.json reproduction/g2-output/normal-summary.json
reproduction/g2-analysis/analyze_windows data/g2/parent-loss.stdout.jsonl > reproduction/g2-output/parent-loss-windows.csv 2> reproduction/g2-output/parent-loss-summary.json
```

最后一条命令预期退出1，CSV预期0字节，摘要应为missing_summary_or_count_mismatch和engineering_diagnostic=no；这是已保存的缺数据结果，不能当作复算失败后重跑采集的理由。分别与data/g2下同名两文件逐字比较。正常命令退出0，stdout为CSV、stderr为JSON摘要；不要把stderr摘要当作可删除日志。

正式判据、单进程依赖、时钟／物理标尺条件、完整长尾和覆盖缺口见[完整科学合同](../../research/g2/EXPERIMENT_PLAN.html)与[全量核对](../../research/g2/SCIENTIFIC_REVIEW.html)。所有false认证字段及R02/R04部分状态保持；可重算工程输出不证明真实统计前提或恒时。图按这两份固定正常C输出绘制，PNG/PDF与图注在本包，绘图源另存作者归档。
'''
    put('code/g2-analysis/README.md', analysis_readme.encode(), 'anonymous_offline_C_reproduction_instructions')
    collector_readme = '''# G2-C：普通参考生产者的原字节源码审计件

本目录提供已封存普通生产者的frequency_workload.c及其原始CMakeLists.txt，用于静态审计完整解封装的计时边界、预分配与后置缓冲、时钟／调度检查、E7/E8/E7只读MSR边界及统一状态。原C源码和构建配置未作匿名改写；公开设备接口/dev/cpu/%u/msr不是私有服务器路径。

这两份文件依赖完整固定参考仓库的include、src、vendor、tests布局，不是能在本补充件独立构建的采集程序。原CMake中的../../..按原仓库布局解释，不能按本包当前位置直接执行。不要把该目录当作离线复算入口；已有JSONL的独立离线复算请用[分析工具G2-A](../g2-analysis/README.md)。

Linux普通采集还依赖已冻结且另行审查的权限、父端管理、生命周期与恢复合同；这些管理／部署流程、管理员／SSH／root恢复代码和可执行二进制均未分发。本包没有放行硬件采集的运行命令。原生软件检查与正式ELF身份属于已封存来源，本次仅分发和核对原字节源，不重新执行密码、KAT、MSR或计时。

源对应的正式普通ELF摘要与原始数据身份由[实际原件独立核对](../../research/g2/ARTIFACT_REVIEW.html)保留。完整技术边界见[生产者合同匿名视图](../../research/g2/TOOL_CONTRACT.html)和[G2冻结合同](../../research/g2/EXPERIMENT_PLAN.html)。原字节源码可审计不代表每次短调用恒频、物理精度或R02/R04已完成。
'''
    put('code/g2-collector/README.md', collector_readme.encode(), 'anonymous_collector_static_source_audit_scope')
    for extension in ('docx', 'pdf'):
        source = REPORT / ('CACR2026EA16XZ-作品设计报告-匿名版.' + extension)
        original = source.read_bytes()
        put('report/CACR2026EA16XZ-作品设计报告.' + extension, original,
            'current_G2_report_original', 'CURRENT_REPORT_' + extension.upper(), original)
        author_bindings.append({'source_id': 'CURRENT_REPORT_' + extension.upper(),
                                'source_path': str(source.relative_to(ROOT)),
                                'source_sha256': digest(original)})
    put('verification/current-report.json', (json.dumps(approved_report, indent=2) + '\n').encode(),
        'approved_report_digest_and_page_binding')
    put('verification/reading-transformations.json',
        (json.dumps(transformations, ensure_ascii=False, indent=2) + '\n').encode(),
        'complete_declared_anonymous_view_operations')
    figure_binding = {'figure': 'G2-1', 'figure_pdf_sha256': BYTE_SOURCES['G2_FIGURE_PDF'][2],
                      'figure_png_sha256': BYTE_SOURCES['G2_FIGURE_PNG'][2],
                      'caption_source_sha256': TEXT_SOURCES['G2_FIGURE_CAPTION'][1],
                      'normal_csv_sha256': BYTE_SOURCES['G2_NORMAL_WINDOWS'][2],
                      'normal_summary_sha256': BYTE_SOURCES['G2_NORMAL_SUMMARY'][2],
                      'primary_pairs': 200, 'primary_processes': 1,
                      'pure_main_geometric_coverage': {'numerator_ns': '3981985286', 'denominator_ns': '4002203951'},
                      'is_pointwise_timeline': False, 'is_confidence_interval': False,
                      'full_main_coverage_certified': False, 'physical_precision_certified': False,
                      'cpu18_independent_sample': False, 'r02_signed_off': False, 'r04_signed_off': False}
    put('verification/figure-data-binding.json', (json.dumps(figure_binding, indent=2) + '\n').encode(),
        'existing_figure_to_frozen_C_output_binding')
    pages = approved_report['pdf_pages']
    readme = f'''# 2026年10月10日G2窗口与研究材料补充件

解压后打开[index.html](index.html)。本版绑定{pages}页G2更新报告，提供冻结合同、完整工具合同、实际结果、结果到主张、科学／生命周期独立核对、原图及完整图注的匿名技术视图。G2原始正常JSONL与四份固定C输出保持原字节，中断原始stdout及CSV为空同样保留；空输出保持partial_or_unknown，不表示零调用。

已完成的G2包含一次正常进程的126528次调用、200个CPU2主pair，以及另一次注册运行中取消与可见恢复。200窗来自一个完成进程，八输入循环不是iid。全部观测窗口满足事前工程规则，纯主平均窗口几何覆盖为3981985286/4002203951ns，显示99.4948%；这不是全段、逐时或逐调用恒频，不是物理精度或统计认证。CPU18为context_only。R02/R04仍部分签收。

旧ec076包全部887成员原字节保存在{HISTORY}；旧根的47页报告、索引、README及清单均属于其历史版本。该子根内更旧的20261009材料及全部相对路径继续保留。W1—W4、NEXT的B1—B5与完整时钟条件可由新索引直达；数学理论不追认历史探索区间，正式确认仍为NOT_READY_TO_RUN。

新Markdown是明确声明的匿名完整科学视图，公开清单只用中性source_id和原件摘要；所有身份、链接及notice变换均登记，无科学段落删除。作者侧保留私有映射、实际来源路径及完整管理原件。code/g2-analysis分发原字节G2-A离线C分析源、CMake配置及匿名复算说明；code/g2-collector分发原字节G2-C生产者C源与原CMake，仅供静态边界审计，依赖完整固定参考仓库，不是包内独立采集入口。没有管理员、SSH、恢复、采集worker部署脚本或ELF。准备记录保留原历史时点，不改写为当前未执行。直接身份字串与文档元数据核对不能保证无法通过公开内容关联作者。

本次组包新执行密码调用为0、新采集运行为0；126528次为导入的已封存G2正常调用，不能混写成组包执行。装配工具不运行C分析、密码或计时；离线复算步骤供读者检查已取得的普通原值。主manifest覆盖除自身和SHA外全部成员，SHA覆盖除自身全部成员；ZIP摘要在包外。阅读闭包不替代软件v3、真实截图、本人审批或竞赛接受回执。
'''
    put('README.md', readme.encode(), 'current_distribution_scope')
    links = ''.join(f'<li><a href="research/g2/{SOURCE_NAMES[source_id]}.html">{label}</a></li>' for source_id, label in (
        ('G2_EXPERIMENT_PLAN', '冻结G2执行与工程规则合同'), ('G2_TOOL_CONTRACT', '普通参考C11工具的完整合同'),
        ('G2_RESULTS', '实际G2结果与支持范围'), ('G2_RESULT_TO_CLAIM', '结果到主张及下一门槛'),
        ('G2_SCIENTIFIC_REVIEW', '全量原值科学核对'), ('G2_ARTIFACT_REVIEW', '采集、注册取消及可见恢复核对'),
        ('G2_FIGURE_CAPTION', 'G2-1原图及完整图注')))
    index = ('<!doctype html><html lang="zh-CN"><head><meta charset="utf-8">'
             '<meta name="viewport" content="width=device-width,initial-scale=1">'
             '<title>CACR2026EA16XZ G2窗口与研究材料</title><link rel="stylesheet" href="reader.css">'
             f'</head><body><main><h1>G2窗口与研究材料</h1><p>CACR2026EA16XZ · 2026年10月10日 · {pages}页更新报告</p>'
             '<p>单次普通进程的200个CPU2窗口通过冻结工程规则，纯主平均窗口几何覆盖99.4948%。'
             '注册取消及可见恢复另有真实路径原件；物理精度、逐调用恒频、正式统计和R02/R04仍未签收。</p>'
             '<nav class="links"><a href="report/CACR2026EA16XZ-作品设计报告.pdf">当前报告PDF</a>'
             '<a href="report/CACR2026EA16XZ-作品设计报告.docx">当前报告Word</a>'
             '<a href="README.md">版本及范围</a><a href="manifest.json">主来源清单</a></nav>'
             '<h2>G2完整科学来源与图</h2><ul>' + links + '</ul><h2>已封存原值</h2><ul>'
             + ''.join(f'<li><a href="{BYTE_SOURCES[source_id][0]}">{label}</a></li>' for source_id, label in (
                 ('G2_NORMAL_RAW', '正常原始JSONL：126528次完整调用'),
                 ('G2_NORMAL_WINDOWS', '正常逐窗口CSV：包含CPU2和CPU18全部400行'),
                 ('G2_NORMAL_SUMMARY', '正常固定C摘要'), ('G2_PARENT_LOSS_RAW', '中断原始stdout：0字节，部分或未知'),
                 ('G2_PARENT_LOSS_WINDOWS', '中断CSV：0字节'), ('G2_PARENT_LOSS_SUMMARY', '中断固定C拒绝摘要')))
             + '</ul><p><a href="code/g2-analysis/README.md">G2-A原字节C分析源与离线复算说明</a> · '
             '<a href="code/g2-analysis/analyze_windows.c">分析C源</a> · '
             '<a href="code/g2-analysis/CMakeLists.txt">唯一构建及CTest配置</a></p>'
             '<p><a href="code/g2-collector/README.md">G2-C生产者源码静态审计边界</a> · '
             '<a href="code/g2-collector/frequency_workload.c">原字节生产者C源</a> · '
             '<a href="code/g2-collector/CMakeLists.txt">原仓库构建配置：非包内独立入口</a></p>'
             '<h2>理论、前提与历史材料</h2><ul>'
             f'<li><a href="{HISTORY}research/WEAK_MEAN_PROOF_PACKAGE.html">W1—W4完整条件证明</a></li>'
             f'<li><a href="{HISTORY}research/NEXT_VALIDATION_PROTOCOL.html">B1—B5与完整时钟科学门槛</a></li>'
             f'<li><a href="{HISTORY}historical/20261009/research/PROOF_PACKAGE.html">P1—P5证明及反例</a></li>'
             f'<li><a href="{HISTORY}historical/20261009/research/FINITE_REFERENCE_BOUNDARY.html">P6有限参考边界</a></li>'
             f'<li><a href="{HISTORY}index.html">原47页均值推断材料历史索引</a></li></ul>'
             '<p>本次包装执行0次新密码调用与0次新计时运行；所列G2是已经取得并封存的实际证据。'
             '<a href="verification/current-report.json">报告身份</a> · '
             '<a href="verification/figure-data-binding.json">图与固定数据绑定</a> · '
             '<a href="verification/reading-transformations.json">全部匿名视图变换</a></p></main></body></html>')
    put('index.html', index.encode(), 'current_offline_entry')
    manifest = {'format': 'anonymous_g2_windows_supplement_v1', 'date': '2026-10-10',
                'parent_archive_sha256': OLD_SHA256, 'parent_member_count': OLD_MEMBER_COUNT,
                'historical_subroot': HISTORY,
                'historical_manifest_scope': 'Old metadata refer only to their unchanged historical payload roots.',
                'current_report_pages': pages, 'packaging_new_cryptographic_calls': 0,
                'packaging_new_timing_runs': 0, 'packaging_new_C_analysis': False,
                'imported_existing_G2_normal_call_records': 126528,
                'imported_existing_G2_completed_processes': 1,
                'offline_C_source_exception': {'source_alias': 'G2-A',
                                               'files': ['code/g2-analysis/analyze_windows.c',
                                                         'code/g2-analysis/CMakeLists.txt'],
                                               'binaries_distributed': False,
                                               'hardware_or_administrator_entrypoint': False},
                'collector_C_source_exception': {'source_alias': 'G2-C',
                                                 'files': ['code/g2-collector/frequency_workload.c',
                                                           'code/g2-collector/CMakeLists.txt'],
                                                 'purpose': 'static_source_audit',
                                                 'standalone_build_in_this_archive': False,
                                                 'privileged_management_or_deployment_shipped': False,
                                                 'binaries_distributed': False,
                                                 'sealed_native_regular_elf_sha256': COLLECTOR_NATIVE_ELF_SHA256,
                                                 'new_native_build_or_execution': False},
                'R02': 'partial', 'R04': 'partial', 'whole_goal_complete': False,
                'files': sorted(records.values(), key=lambda record: record['distributed_path'])}
    (payload / 'manifest.json').write_text(json.dumps(manifest, ensure_ascii=False, indent=2) + '\n')
    files = sorted(path for path in payload.rglob('*') if path.is_file())
    (payload / 'SHA256SUMS').write_text(''.join(digest(path.read_bytes()) + '  '
                                             + str(path.relative_to(payload)) + '\n' for path in files))
    author_sources.write_text(json.dumps(author_bindings, ensure_ascii=False, indent=2) + '\n')
    archive_path = WORK / ('assembled-' + arguments.stage_name + '.zip')
    with zipfile.ZipFile(archive_path, 'x', zipfile.ZIP_DEFLATED, compresslevel=9) as archive:
        for path in sorted(payload.rglob('*')):
            if path.is_file():
                archive.write(path, str(path.relative_to(payload)))
    print(json.dumps({'archive': str(archive_path), 'archive_sha256': digest(archive_path.read_bytes()),
                      'files': len(files) + 1, 'old_members_preserved': OLD_MEMBER_COUNT,
                      'private_map': str(author_map), 'author_sources': str(author_sources),
                      'packaging_new_cryptographic_calls': 0, 'packaging_new_timing_runs': 0,
                      'imported_existing_G2_normal_call_records': 126528, 'whole_goal_complete': False}))


if __name__ == '__main__':
    main()
