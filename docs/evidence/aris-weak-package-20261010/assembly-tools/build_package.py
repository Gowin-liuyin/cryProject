from pathlib import Path
from urllib.parse import urlsplit
import hashlib
import html
import json
import os
import re
import subprocess
import sys
import zipfile


ROOT = Path(__file__).resolve().parents[3]
WORK = ROOT / 'build/aris-weak-package-20261010'
OLD_ZIP = ROOT / 'deliverables/support/CACR2026EA16XZ-aris-current-20261009/CACR2026EA16XZ-当前研究报告与数学复核补充件.zip'
OLD_SHA256 = '327e5221d691e43f10eb85888a2021751ebdd3046769f710d4933c29e885b2eb'
HISTORY = 'historical/20261009/'
RESEARCH = ROOT / 'docs/research/aris-replication-20261009'
REPORT = ROOT / 'deliverables/research/aris-report-weak-mean-20261010'
WHEEL_SHA256 = 'f089b6d75e85b937f99693c93e8c16c0804008672c3dd2a3d25affd36f238100'


def sha256(contents):
    return hashlib.sha256(contents).hexdigest()


def main():
    stage_name = sys.argv[1]
    assert re.fullmatch(r'payload-[a-z0-9-]+', stage_name)
    payload = WORK / stage_name
    payload.mkdir()
    assert sha256(OLD_ZIP.read_bytes()) == OLD_SHA256
    wheel = WORK / 'dependency/latex2mathml-3.78.1-py3-none-any.whl'
    assert sha256(wheel.read_bytes()) == WHEEL_SHA256
    with zipfile.ZipFile(wheel) as archive:
        for member in archive.infolist():
            assert (WORK / 'dependency/unpacked' / member.filename).read_bytes() == archive.read(member)
    private_map = json.loads((ROOT / 'docs/evidence/aris-current-package-20261009/private-substitution-map.json').read_text())
    records = {}
    transformations = []
    formula_audit = {}

    def put(name, contents, role, source=None, operations=None):
        assert name not in records
        target = payload / name
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_bytes(contents)
        record = {'distributed_path': name, 'distributed_copy_sha256': sha256(contents),
                  'distributed_byte_count': len(contents), 'content_role': role}
        if source is not None:
            original = source.read_bytes()
            record.update(source_path=str(source.relative_to(ROOT)), source_sha256=sha256(original),
                          original_byte_count=len(original),
                          transformation='none_original_bytes' if original == contents else 'declared_public_view')
        else:
            record['transformation'] = 'generated_reading_or_verification_metadata'
        if operations:
            record['operations'] = operations
        records[name] = record

    with zipfile.ZipFile(OLD_ZIP) as old:
        assert len(old.infolist()) == 870 and old.testzip() is None
        for member in old.infolist():
            path = Path(member.filename)
            assert member.is_dir() is False and not path.is_absolute() and '..' not in path.parts
            contents = old.read(member)
            name = HISTORY + member.filename
            put(name, contents, 'unchanged_historical_20261009_member')
            records[name].update(parent_archive_sha256=OLD_SHA256,
                                 parent_archive_member=member.filename,
                                 transformation='none_parent_archive_bytes')
        put('reader.css', old.read('reader.css'), 'static_local_stylesheet')

    proof_source = RESEARCH / 'WEAK_MEAN_PROOF_PACKAGE.md'
    review_source = RESEARCH / 'WEAK_MEAN_REVIEW.md'
    protocol_source = RESEARCH / 'NEXT_VALIDATION_PROTOCOL.md'
    protocol = protocol_source.read_text()
    paragraphs = protocol.split('\n\n')
    public_paragraphs = []
    removed_history = []
    retained_markers = {
        '当前恢复预检的Linux连接': '必须取得适合新目标的实际资源资格',
        '运行状态补记：': 'B1—B5的资源、目标、真值、有效方法及预算门槛保持',
        '2026-10-10补记：': '上述B1—B5的科学资格不由文件维护或软件自检替代',
    }
    for paragraph in paragraphs:
        marker = next((value for prefix, value in retained_markers.items() if paragraph.startswith(prefix)), None)
        if marker is not None:
            boundary = paragraph.index(marker)
            retained = paragraph[boundary:]
            public_paragraphs.append(retained)
            removed_history.append({'kind': 'omit_admin_prefix_keep_scientific_suffix',
                                    'paragraph_sha256': sha256(paragraph.encode()),
                                    'keep_from': marker,
                                    'removed_prefix_sha256': sha256(paragraph[:boundary].encode()),
                                    'retained_suffix_sha256': sha256(retained.encode())})
            continue
        public_paragraphs.append(paragraph)
    assert len(removed_history) == 3
    protocol = '\n\n'.join(public_paragraphs)
    notice = (
        '本文件为匿名公开技术视图，原件摘要另列；省略认证及存储维护历史，不把可登录机器当作资源或统计资格。'
        '科学对象、B1—B5、完整长尾、功效及预算门槛保持。')
    notice_anchor = '# R02与R04下一阶段的防御性验证协议\n'
    protocol = protocol.replace(notice_anchor, notice_anchor + '\n' + notice + '\n', 1)
    replacements = {
        '../aris-20261008/PROOF_PACKAGE.md': '../historical/20261009/research/PROOF_PACKAGE.md',
        '../aris-20261008/FINITE_REFERENCE_BOUNDARY.md': '../historical/20261009/research/FINITE_REFERENCE_BOUNDARY.md',
        '../aris-20261008/DEEP_READING.md': '../historical/20261009/research/DEEP_READING.md',
        '[旧研究合同](../aris-20261008/EXPERIMENT_PLAN.md)':
        '2026-10-08旧研究合同（原件未随本匿名技术视图新增；其停止路线和旧预算保持）',
    }
    operations = removed_history + [{'kind': 'insert_public_view_notice', 'after': notice_anchor,
                                     'text': notice, 'text_sha256': sha256(notice.encode())}]
    for old_target, new_target in replacements.items():
        count = protocol.count(old_target)
        assert count > 0
        protocol = protocol.replace(old_target, new_target)
        operations.append({'kind': 'reading_link_or_explicit_omission', 'from': old_target,
                           'to': new_target, 'count': count})
    for item in private_map:
        expression = re.escape(item['original'])
        if item['role'].startswith('own_source'):
            expression = r'(?<![A-Za-z0-9])' + expression + r'(?![A-Za-z0-9])'
        protocol, count = re.subn(expression, lambda match: item['replacement'], protocol)
        if count:
            operations.append({'kind': 'anonymous_identity_view', 'marker_sha256': sha256(item['original'].encode()),
                               'role': item['role'], 'replacement': item['replacement'], 'count': count})
    put('research/WEAK_MEAN_PROOF_PACKAGE.md', proof_source.read_bytes(), 'original_technical_proof', proof_source)
    put('research/WEAK_MEAN_REVIEW.md', review_source.read_bytes(), 'original_internal_review_note', review_source)
    put('research/NEXT_VALIDATION_PROTOCOL.md', protocol.encode(), 'anonymous_scientific_protocol_view', protocol_source, operations)
    bibliography = RESEARCH / 'weak-mean-references.bib'
    put('research/weak-mean-references.bib', bibliography.read_bytes(), 'original_bibliography_addendum', bibliography)
    transformations.append({'source_path': str(protocol_source.relative_to(ROOT)),
                            'source_sha256': sha256(protocol_source.read_bytes()),
                            'distributed_path': 'research/NEXT_VALIDATION_PROTOCOL.md', 'operations': operations})

    planned_readers = {'research/' + name for name in ('WEAK_MEAN_PROOF_PACKAGE.md',
                       'WEAK_MEAN_REVIEW.md', 'NEXT_VALIDATION_PROTOCOL.md')}

    def render(source_name):
        source_path = payload / source_name
        destination_name = str(Path(source_name).with_suffix('.html'))
        destination = payload / destination_name
        text = source_path.read_text()
        expressions = []

        def protect(match, display):
            index = len(expressions)
            expressions.append({'tex': match.group(1), 'display': display})
            token = f'@@MATH_{index}@@'
            return '\n\n' + token + '\n\n' if display else token

        text = re.sub(r'\$\$(.*?)\$\$', lambda match: protect(match, True), text, flags=re.S)
        text = re.sub(r'(?<!\\)\$([^$\n]+?)(?<!\\)\$', lambda match: protect(match, False), text)
        command = [sys.executable, '-I', '-B', str(Path(__file__).with_name('mathml.py')),
                   str(WORK / 'dependency/unpacked')]
        result = subprocess.run(command, input=json.dumps(expressions), text=True, capture_output=True, check=True)
        converted = json.loads(result.stdout)
        assert len(converted) == len(expressions)
        formula_audit[destination_name] = [{'tex_sha256': sha256(item['tex'].encode()), 'display': item['display'],
                                            'mathml_sha256': sha256(mml.encode())}
                                           for item, mml in zip(expressions, converted)]

        def inline(value):
            escaped = html.escape(value)

            def hyperlink(match):
                label, target = match.group(1), html.unescape(match.group(2))
                if not urlsplit(target).scheme:
                    resolved = (source_path.parent / target.split('#')[0]).resolve()
                    relative = str(resolved.relative_to(payload.resolve()))
                    if relative in planned_readers or (resolved.suffix == '.md' and resolved.with_suffix('.html').exists()):
                        target = str(Path(target).with_suffix('.html'))
                return '<a href="' + html.escape(target, quote=True) + '">' + label + '</a>'

            escaped = re.sub(r'\[([^\]]+)\]\(([^)]+)\)', hyperlink, escaped)
            escaped = re.sub(r'\*\*([^*]+)\*\*', r'<strong>\1</strong>', escaped)
            escaped = re.sub(r'`([^`]+)`', r'<code>\1</code>', escaped)
            for index, mml in enumerate(converted):
                escaped = escaped.replace(f'@@MATH_{index}@@', mml)
            return escaped

        parts, paragraph, table = [], [], []

        def flush():
            if paragraph:
                parts.append('<p>' + inline(' '.join(paragraph)) + '</p>')
                paragraph.clear()

        def flush_table():
            if not table:
                return
            rows = [row.strip().strip('|').split('|') for row in table]
            rows = [row for row in rows if not all(re.fullmatch(r'[:\-\s]+', cell) for cell in row)]
            parts.append('<div class="table-wrap"><table><thead><tr>' + ''.join('<th>' + inline(cell.strip()) + '</th>' for cell in rows[0]) + '</tr></thead><tbody>' + ''.join('<tr>' + ''.join('<td>' + inline(cell.strip()) + '</td>' for cell in row) + '</tr>' for row in rows[1:]) + '</tbody></table></div>')
            table.clear()

        heading_count = 0
        for line in text.splitlines():
            if line.startswith('|'):
                flush()
                table.append(line)
                continue
            flush_table()
            if not line.strip():
                flush()
                continue
            heading = re.match(r'^(#{1,6})\s+(.*)', line)
            if heading:
                flush()
                heading_count += 1
                level, title = len(heading[1]), heading[2]
                claim = re.match(r'^(W[1-4])[:：]', title)
                identifier = claim[1].lower() if claim else f'section-{heading_count}'
                parts.append(f'<h{level} id="{identifier}">' + inline(title) + f'</h{level}>')
            elif re.fullmatch(r'@@MATH_\d+@@', line):
                flush()
                parts.append('<div class="math display">' + inline(line) + '</div>')
            else:
                paragraph.append(line)
        flush()
        flush_table()
        title = source_path.read_text().splitlines()[0].lstrip('# ')
        page = '<!doctype html><html lang="zh-CN"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>' + html.escape(title) + '</title><link rel="stylesheet" href="../reader.css"></head><body><main class="reading"><nav><a href="../index.html">返回新版材料索引</a> · <a href="' + source_path.name + '">Markdown来源或视图</a></nav><article>' + ''.join(parts) + '</article></main></body></html>'
        put(destination_name, page.encode(), 'static_native_mathml_reader')
        records[destination_name].update(derived_from=source_name,
                                         derived_from_sha256=sha256(source_path.read_bytes()))

    for source_name in sorted(planned_readers):
        render(source_name)

    for extension in ('docx', 'pdf'):
        source = REPORT / ('CACR2026EA16XZ-作品设计报告-匿名版.' + extension)
        put('report/CACR2026EA16XZ-作品设计报告.' + extension, source.read_bytes(), 'current_47_page_report_original', source)
    delivery = ROOT / 'docs/evidence/aris-report-weak-mean-20261010/delivery-verification.json'
    put('verification/report-weak-mean/delivery-verification.json', delivery.read_bytes(), 'original_report_binding', delivery)
    put('verification/reading-transformations.json', (json.dumps(transformations, ensure_ascii=False, indent=2) + '\n').encode(), 'declared_public_view_transformations')
    put('verification/formula-conversion.json', (json.dumps(formula_audit, indent=2) + '\n').encode(), 'formula_source_to_mathml_digest_binding')

    readme = '''# 2026年10月10日均值推断与研究材料补充件

解压后打开[index.html](index.html)，阅读47页报告、W1—W4完整证明、三项增补书目及匿名科学协议视图。原报告的表图公式与原始数值保持；新理论不追认历史探索区间，4—20对没有因此获得有限覆盖，R02/R04仍部分签收。

旧327e包的870个条目全部原字节保存在historical/20261009，条目在旧子根内的相对路径也保持。该目录中的index、README、manifest、SHA及“当前45页”描述都属于2026年10月9日的历史身份；旧清单的payload根是该历史子目录，不能将其当成本包的新根。旧42页稿、M01/M02、官方原件与56ad数学源件继续保留各自角色。

W证明Markdown和增补BibTeX为原字节副本。NEXT是明确标注的匿名科学视图：保留估计对象、B1—B5、长尾、功效、预算及NOT_READY_TO_RUN；省略认证和存储维护历史，将旧证明链接映射到真实历史页，旧研究合同未新增分发并明确标注。HTML使用原生MathML，无JS/CDN/在线字体，外部论文链接只用于查源。Markdown保留TeX作为技术来源，正文公式请使用HTML阅读。

本包只供报告、数学论证及已有材料阅读，不替代软件v3，不包含新的密码或计时调用、管理员/SSH/恢复脚本，不冒充真实运行截图或本人审批。已有纯数学C核验的原记录保留，本次组包没有重跑它们。直接身份字串与元数据扫描不等于绝对不可关联作者。

主manifest列除自身和SHA清单外全部条目的来源及分发摘要；主SHA另覆盖manifest及其他全部项，只排除自身。历史子清单原字节保持，ZIP摘要放在包外，避免自摘要环。
'''
    put('README.md', readme.encode(), 'current_distribution_scope')
    index = '''<!doctype html><html lang="zh-CN"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>CACR2026EA16XZ 均值推断研究材料</title><link rel="stylesheet" href="reader.css"></head><body><main><h1>均值推断与研究材料</h1><p class="caption">CACR2026EA16XZ · 2026年10月10日</p><p>本版绑定47页报告，补齐平均时间差的条件推断依据。原数据和历史解释保留，新理论与原尖锐检验分别定位；R02/R04仍部分签收。</p><nav class="links"><a href="report/CACR2026EA16XZ-作品设计报告.pdf">47页报告 PDF</a><a href="report/CACR2026EA16XZ-作品设计报告.docx">可编辑报告 Word</a><a href="README.md">版本与摘要说明</a><a href="manifest.json">主来源清单</a></nav><h2>平均时间差的理论与执行门</h2><ul><li><a href="research/WEAK_MEAN_PROOF_PACKAGE.html#w1">W1 无偏均值与期望保守方差</a></li><li><a href="research/WEAK_MEAN_PROOF_PACKAGE.html#w2">W2 独立随机化下的小样本反例</a></li><li><a href="research/WEAK_MEAN_PROOF_PACKAGE.html#w3">W3 无主导单位条件下的渐近区间</a></li><li><a href="research/WEAK_MEAN_PROOF_PACKAGE.html#w4">W4 真实事前幅度界下的有限区间</a></li><li><a href="research/NEXT_VALIDATION_PROTOCOL.html">B1—B5匿名科学协议视图</a></li><li><a href="research/WEAK_MEAN_REVIEW.html">内部独立交叉审查</a> · <a href="research/weak-mean-references.bib">增补BibTeX与阅读深度</a></li></ul><h2>原始研究及历史材料</h2><p><a href="historical/20261009/index.html">2026年10月9日历史材料索引</a>保留45页稿、M01/M02原值、官方补证及旧数据。该旧索引中的“当前”只指其历史日期。</p><ul><li><a href="historical/20261009/research/PROOF_PACKAGE.html">旧P1—P5条件保证与反例</a></li><li><a href="historical/20261009/research/FINITE_REFERENCE_BOUNDARY.html">旧P6有限参考阈值边界</a></li><li><a href="historical/20261009/research/DEEP_READING.html">SILENT及统计适用性定向核查</a></li><li><a href="historical/20261009/data/M02_REPLICATION/index.html">原M02三进程数据与只读核验</a></li><li><a href="verification/report-weak-mean/delivery-verification.json">新报告身份与验收范围</a></li></ul><p>源文件、匿名视图和静态阅读页的角色分别登记。材料阅读闭包不签收真实统计前提、频率受控采集或完整竞赛要求。</p></main></body></html>'''
    put('index.html', index.encode(), 'current_offline_entry')
    manifest = {'format': 'anonymous_mean_inference_supplement_v1', 'date': '2026-10-10',
                'parent_archive_sha256': OLD_SHA256, 'parent_member_count': 870,
                'historical_subroot': HISTORY,
                'historical_manifest_scope': 'The old payload root is historical/20261009; old metadata are unchanged historical documents.',
                'current_report_pages': 47, 'new_cryptographic_calls': 0, 'new_timing_runs': 0,
                'new_C_replay': False, 'R02': 'partial', 'R04': 'partial', 'whole_goal_complete': False,
                'math_authoring_dependency': {'name': 'latex2mathml', 'version': '3.78.1',
                                             'wheel_sha256': WHEEL_SHA256, 'license': 'MIT',
                                             'runtime_dependency': False},
                'files': sorted(records.values(), key=lambda item: item['distributed_path'])}
    (payload / 'manifest.json').write_text(json.dumps(manifest, ensure_ascii=False, indent=2) + '\n')
    files = sorted(path for path in payload.rglob('*') if path.is_file())
    (payload / 'SHA256SUMS').write_text(''.join(sha256(path.read_bytes()) + '  ' + str(path.relative_to(payload)) + '\n' for path in files))
    archive_path = WORK / ('assembled-' + stage_name + '.zip')
    with zipfile.ZipFile(archive_path, 'x', zipfile.ZIP_DEFLATED, compresslevel=9) as archive:
        for path in sorted(payload.rglob('*')):
            if path.is_file():
                archive.write(path, str(path.relative_to(payload)))
    print(json.dumps({'archive': str(archive_path), 'archive_sha256': sha256(archive_path.read_bytes()),
                      'files': len(files) + 1, 'old_members_preserved': 870,
                      'new_mathml': sum(len(rows) for rows in formula_audit.values()),
                      'whole_goal_complete': False}))


if __name__ == '__main__':
    main()
