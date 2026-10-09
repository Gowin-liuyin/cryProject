from pathlib import Path
from urllib.parse import unquote, urlparse
import hashlib, html, json, re, subprocess, zipfile
from html.parser import HTMLParser

ROOT = Path('/Users/yin/code/cryProject')
WORK = ROOT / 'build/aris-current-package-20261009'
EVIDENCE = ROOT / 'docs/evidence/aris-current-package-20261009'
PAYLOAD = WORK / 'payload'
OLD = ROOT / 'deliverables/support/CACR2026EA16XZ-aris-cost-20261008/CACR2026EA16XZ-研究报告与数学成本解释补充件.zip'
OLD_SHA = '59b858391d21392e3725e01791b8b877f942599ccce46d323aacc22d109cf9ee'
MATH = ROOT / 'deliverables/support/CACR2026EA16XZ-math-reproduction-20261009/CACR2026EA16XZ-数学源码与账本复核件.zip'
MATH_SHA = '56ad7ece879df934c5be8b740729058063ae214f23081afb04ed1540102fcc24'
M02 = ROOT / 'docs/evidence/aris-replication-20261009'
RESEARCH = ROOT / 'docs/research/aris-replication-20261009'
OFFICIAL = ROOT / 'docs/evidence/aris-resume-20261009'
sha = lambda data: hashlib.sha256(data).hexdigest()
assert sha(OLD.read_bytes()) == OLD_SHA
assert sha(MATH.read_bytes()) == MATH_SHA
assert not PAYLOAD.exists(), 'New stage only; do not overwrite an existing payload'
PAYLOAD.mkdir()
with zipfile.ZipFile(OLD) as archive:
    assert archive.testzip() is None
    old_manifest = json.loads(archive.read('manifest.json'))
    for member in archive.infolist():
        target = Path(member.filename)
        assert not target.is_absolute() and '..' not in target.parts
        destination = PAYLOAD / target
        destination.parent.mkdir(parents=True, exist_ok=True)
        destination.write_bytes(archive.read(member.filename))
records = {item['distributed_path']: item for item in old_manifest['files']}
private_map = [
    (str(ROOT), 'ORIGINAL_REPOSITORY_ROOT', 'participant_repository_absolute_path'),
    ('/Users/yin', 'PARTICIPANT_HOME', 'participant_home_absolute_path'),
    ('yindeMacBook-Air.local', 'MEASUREMENT_HOST', 'participant_hostname'),
    ('Gowin-liuyin', 'PARTICIPANT_AUTHOR', 'participant_account_name'),
    ('yinhaoran0808@outlook.com', 'PARTICIPANT_EMAIL', 'participant_email'),
    ('https://github.com/Gowin-liuyin/cryProject.git', 'PARTICIPANT_REMOTE', 'participant_remote_url'),
]
commits = subprocess.check_output(['git', 'rev-list', '--all'], cwd=ROOT, text=True).splitlines()
known = {'96eba6d0b25d052a836a42b7ed5115615ee4a8d7': 'SOURCE-M02-CONTRACT-01',
         '1ac2033eb16057ee684eedefc6301a0ce6b5b7ed': 'SOURCE-M02-IMPLEMENTATION-01',
         '595cd4996b181ce2c9057b453047bc29eb222a02': 'SOURCE-RESEARCH-SEAL-01',
         '8470548a13b46cffc3e8ce54a320394d31d86848': 'SOURCE-RESUME-BASELINE-01'}
for index, commit in enumerate(commits, 1):
    alias = known.get(commit, 'SOURCE-LOCAL-COMMIT-%03d' % index)
    private_map.append((commit, alias, 'own_source_commit_alias_not_git_identity'))
    private_map.append((commit[:7], alias, 'own_source_short_commit_alias_not_git_identity'))
private_map.sort(key=lambda value: len(value[0]), reverse=True)
public_map = [{ 'source_token_sha256': sha(source.encode()), 'replacement': replacement, 'token_role': role}
              for source, replacement, role in private_map]
(EVIDENCE / 'private-substitution-map.json').write_text(json.dumps(
    [{'original': source, 'replacement': replacement, 'role': role} for source, replacement, role in private_map],
    ensure_ascii=False, indent=2) + '\n')


def sanitize(data):
    text = data.decode('utf-8')
    substitutions = []
    for index, (source, replacement, role) in enumerate(private_map):
        pattern = re.escape(source)
        if role.startswith('own_source'):
            pattern = r'(?<![a-zA-Z0-9])' + pattern + r'(?![a-zA-Z0-9])'
        count = len(re.findall(pattern, text))
        if count:
            text = re.sub(pattern, lambda match: replacement, text)
            substitutions.append({'map_index': index, 'count': count, **public_map[index]})
    return text.encode(), substitutions


def add(relative, data, group, role, source=None, transformation='generated_metadata_or_static_reading', substitutions=None):
    destination = PAYLOAD / relative
    destination.parent.mkdir(parents=True, exist_ok=True)
    destination.write_bytes(data)
    original = source.read_bytes() if source else None
    record = {'source_path': str(source.relative_to(ROOT)) if source else 'generated_current_package_document',
              'distributed_path': relative, 'dataset_group': group,
              'original_archive_sha256': sha(original) if original is not None else None,
              'distributed_copy_sha256': sha(data),
              'original_byte_count': len(original) if original is not None else None,
              'distributed_byte_count': len(data), 'content_role': role, 'transformation': transformation,
              'origin_kind': 'current_committed_M02_or_official_source_or_generated_reading'}
    if substitutions:
        record['substitutions'] = substitutions
        record['public_substitution_map'] = 'verification/view-substitution-map.json'
        record['scientific_values_modified'] = False
        record['participant_identity_view_not_original_bytes'] = True
    records[relative] = record


def copy_source(source, relative, group, role):
    original = source.read_bytes()
    data, substitutions = sanitize(original)
    add(relative, data, group, role + ('_anonymous_view' if substitutions else '_original_bytes'), source,
        'identity_and_path_substitution_view' if substitutions else 'none_original_bytes', substitutions)


# 原报告及旧核验另保留历史身份；当前报告在独立页面核验后才由根绑定。
for relative in ['report/CACR2026EA16XZ-作品设计报告.docx', 'report/CACR2026EA16XZ-作品设计报告.pdf', 'verification/report-validation.json']:
    old_data = (PAYLOAD / relative).read_bytes()
    backup = 'historical/20261008/' + relative
    add(backup, old_data, 'HISTORICAL_REPORT_42', 'unchanged_previous_42_page_report_or_its_validation')
    records[backup]['original_archive_sha256'] = sha(old_data)
    records[backup]['origin_kind'] = 'byte_identical_member_of_parent_59b_archive'

omitted = []
for source in sorted(M02.rglob('*')):
    if not source.is_file():
        continue
    rel = source.relative_to(M02)
    if rel.parts[:2] == ('preparation', 'artifacts'):
        omitted.append({'source_path': str(source.relative_to(ROOT)), 'sha256': sha(source.read_bytes()),
                        'reason': 'no_participant_path_containing_original_executable_in_anonymous_distribution'})
        continue
    if rel.parts[:2] == ('preparation', 'source-snapshot'):
        omitted.append({'source_path': str(source.relative_to(ROOT)), 'sha256': sha(source.read_bytes()),
                        'reason': 'same_fixed_C_sources_available_in_unchanged_56ad_math_source_archive'})
        continue
    if rel.name == 'SHA256SUMS':
        omitted.append({'source_path': str(source.relative_to(ROOT)), 'sha256': sha(source.read_bytes()),
                        'reason': 'original_root_manifest_not_reused_for_anonymous_path_views_new_manifest_generated'})
        continue
    if rel.name == 'collect_runs.py':
        omitted.append({'source_path': str(source.relative_to(ROOT)), 'sha256': sha(source.read_bytes()),
                        'reason': 'formal_launch_orchestrator_not_distributed_readonly_replay_only'})
        continue
    if rel.parts[:2] == ('preparation', 'summary-source'):
        role = 'fixed_C_summary_source_or_CMake_software_check_contract'
    elif rel.parts[0].startswith('run-') and rel.name != 'input-records.tsv':
        role = 'M02_raw_record_or_unchanged_fixed_input_copy'
    elif rel.parts[0] == 'independent-audits' or rel.name == 'process-summary.json':
        role = 'C_generated_existing_data_audit_or_summary_no_new_statistics'
    elif rel.parts[0] == 'execution':
        role = 'actual_execution_provenance_PID_UTC_returncode_and_hashes'
    else:
        role = 'software_or_artifact_review_preparation_historical_state'
    copy_source(source, 'data/M02_REPLICATION/' + str(rel), 'M02_REPLICATION', role)
for name in ['REPLICATION_CONTRACT.md', 'RESULTS.md', 'RESULT_TO_CLAIM.md', 'findings.md', 'TRACKER.md']:
    copy_source(RESEARCH / name, 'data/M02_REPLICATION/research/' + name, 'M02_REPLICATION', 'current_contract_result_claim_or_limit_explanation')

for name in ['official-source-check.md', 'official-source-check.json']:
    copy_source(OFFICIAL / name, 'official/' + name, 'OFFICIAL_CURRENT', 'bounded_official_workbook_and_fixed_portable_source_check')
for name in ['fips-203-potential-updates.xlsx', 'NIST.FIPS.203.pdf']:
    source = OFFICIAL / 'official-source' / name
    add('official/' + name, source.read_bytes(), 'OFFICIAL_CURRENT', 'unchanged_public_NIST_primary_source', source, 'none_original_bytes')
add('software/CACR2026EA16XZ-数学源码与账本复核件.zip', MATH.read_bytes(), 'MATH_SOURCE_56AD', 'unchanged_anonymous_pure_math_source_software_reproduction_archive_not_v3_replacement', MATH, 'none_original_bytes')
add('verification/view-substitution-map.json', (json.dumps(public_map, ensure_ascii=False, indent=2)+'\n').encode(), 'VERIFICATION', 'public_token_hash_and_replacement_role_map_without_participant_values')
add('verification/omissions.json', (json.dumps(omitted, ensure_ascii=False, indent=2)+'\n').encode(), 'VERIFICATION', 'explicit_original_binary_and_redundant_source_or_launcher_exclusion_roles')

NOTE = '''# 2026年10月9日当前研究补充说明

本版保存本轮取得的NIST官方潜在勘误工作簿及原PDF，并新增M02的一次干净重建、三个顺序新进程。固定六份非零输入的18个中位成本比均小于1，240/240对比较满足冻结时钟门槛。它加强同机固定任务的重复观察，不改变真实总体、恒时安全、可利用性或R02/R04签收状态。

原九组540份数据、M01全部20份材料和原42页报告保持历史字节身份。M01、C01/C03和M02分组展示，没有合并为更多独立任务；M02的八任务只有七种CSV和六份非零向量，3/7是相同全零CSV。各进程24份输入副本不是新数据集。

旧附件未取得的T09时点缺口已由本次摘要固定的官方工作簿两项记录及固定便携C静态核对关闭。它是潜在修正，尚不是已经实施的新标准要求；未签收全部标准、后端或认证。官方核对原笔记的临时保存措辞保留为当时记录，本分发件中的工作簿/PDF已逐字对应后来持久证据副本。提交邮箱核验事项也已由所有者确认，匿名分发不放入邮箱或该内部确认记录。

原记录的pending_external及C汇总awaiting_independent_process_audits_and_artifact_checks字段保持不变。当前资格由新bc61产物机器码复核、三份逐进程C审计和结果到主张审查共同给出，不回填原阶段状态。计数一致本身不证明枚举工作或统计假设。

M02源件的个人路径、主机名和自有Git身份只在明确标注的匿名视图中替换。每份视图单列原件SHA256、分发SHA256、替换字段角色和次数；公开映射保存原标记哈希，原字面映射与原件留在内部不可变证据。数值、PID、UTC、编译选项、原始时钟、尾数、失败和消费顺序未遮盖或改写。原始数值CSV、阶段meta及pending、输入副本和C审计/汇总JSON保持原字节。新普通二进制bc61及动态检查产物不随匿名包分发，其摘要、编译、链接和机器码资格视图仍保留。

纯数学重建及已有账本核验由原56ad匿名数学源码ZIP提供，新M02专用C汇总快照在本包中。它们不替代原软件v3，不运行新的密码或正式观察器。这里的离线HTML只用于阅读，不是软件运行画面截图。真实Linux权限、频率受控数据、真实总体统计前提及人员材料仍各有缺口，完整目标保持部分完成。
'''
add('CURRENT_RESEARCH_NOTE.md', NOTE.encode(), 'CURRENT_RESEARCH', 'current_resolution_and_scope_note')


def page(title, body, css='../reader.css', back='../index.html'):
    return ('<!doctype html><html lang="zh-CN"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1">'
            '<title>'+html.escape(title)+'</title><link rel="stylesheet" href="'+css+'"></head><body><main>'
            '<p><a href="'+back+'">返回材料索引</a></p>'+body+'</main></body></html>').encode()


def readable_md(text):
    # 仅将无新增公式的说明转成静态段落、标题和表；原数学论证沿用已核验MathML页面。
    lines = text.splitlines(); parts=[]; paragraph=[]; in_code=False; code=[]; table=[]
    def flush():
        if paragraph:
            parts.append('<p>'+html.escape(' '.join(paragraph))+'</p>'); paragraph.clear()
    def flush_table():
        if table:
            cells=[row.strip().strip('|').split('|') for row in table]
            cells=[row for row in cells if not all(re.fullmatch(r'[:\-\s]+',cell) for cell in row)]
            parts.append('<div class="table-wrap"><table><thead><tr>'+''.join('<th>'+html.escape(c.strip())+'</th>' for c in cells[0])+'</tr></thead><tbody>'+''.join('<tr>'+''.join('<td>'+html.escape(c.strip())+'</td>' for c in row)+'</tr>' for row in cells[1:])+'</tbody></table></div>'); table.clear()
    for line in lines:
        if line.startswith('```'):
            flush(); flush_table()
            if in_code:
                parts.append('<pre><code>'+html.escape('\n'.join(code))+'</code></pre>'); code=[]
            in_code=not in_code; continue
        if in_code: code.append(line); continue
        if line.startswith('|'): flush(); table.append(line); continue
        flush_table()
        if not line.strip(): flush(); continue
        heading = re.match(r'^(#{1,6})\s+(.*)',line)
        if heading: flush(); level=len(heading.group(1));parts.append(f'<h{level}>'+html.escape(heading.group(2))+f'</h{level}>')
        else: paragraph.append(line)
    flush(); flush_table()
    assert not in_code
    return ''.join(parts)

add('CURRENT_RESEARCH_NOTE.html', page('当前研究补充说明',readable_md(NOTE), 'reader.css','index.html'), 'CURRENT_RESEARCH','static_current_note_reader')
for name in ['REPLICATION_CONTRACT', 'RESULTS', 'RESULT_TO_CLAIM']:
    source = PAYLOAD / 'data/M02_REPLICATION/research' / (name+'.md')
    add('data/M02_REPLICATION/research/'+name+'.html',page(name,readable_md(source.read_text()), '../../../reader.css','../../../index.html'),'M02_REPLICATION','static_current_explanation_reading_view')
source = PAYLOAD / 'official/official-source-check.md'
add('official/official-source-check.html',page('官方潜在勘误工作簿核对',readable_md(source.read_text())), 'OFFICIAL_CURRENT','static_official_check_reading_view')

summary = json.loads((M02/'process-summary.json').read_text())
assert summary['nonzero_task_medians']==18 and summary['supporting_nonzero_task_medians']==18 and summary['clock_qualified_pairs']==240
rows=[]
for task in range(1,9):
    values=[row for row in summary['rows'] if row['task']==task]
    assert len(values)==3
    rows.append('<tr><td>'+str(task)+'</td><td>'+str(values[0]['nonzero_pair_count'])+'</td>'+''.join('<td>'+format(row['ratio_median'],'.12f')+'</td>' for row in values)+'<td>'+('非零主张' if task not in [3,7] else '重复全零，排除主判定')+'</td></tr>')
links=['research/REPLICATION_CONTRACT.html','research/RESULTS.html','research/RESULT_TO_CLAIM.html','process-summary.json','INDEPENDENT_RESULT_REVIEW.md','preparation/INDEPENDENT_REVIEW.md','execution/environment.json','execution/completed.json','execution/summary-command.json','preparation/source-input-manifest.json','preparation/new-artifacts.json','preparation/summary-source/CMakeLists.txt','preparation/summary-source/process_summary.c']
links += ['run-'+str(number)+'/'+name for number in [1,2,3] for name in ['raw-times.csv','raw-clock.csv','pairs.csv','summary.csv','failures.csv','initial-state.meta','final-state.meta','final-state.pending','input-records.tsv']]
links += ['independent-audits/process-'+str(number)+'.json' for number in [1,2,3]]
body='<h1>M02：一次重建、三个新进程的纯数学复核</h1><p>六份固定非零输入的18个中位条件均成立，全部240对满足既定时钟门槛。每进程16预热、160正式窗口、176次消费、512校准值及80比值保留；不删长尾、不扣开销，不合并旧M01。</p><table><thead><tr><th>任务</th><th>非零对</th><th>进程1</th><th>进程2</th><th>进程3</th><th>角色</th></tr></thead><tbody>'+''.join(rows)+'</tbody></table><p>这是Apple M5/macOS ARM64上的一次重建和三个紧邻进程，共享机器、输入及环境；不按18个独立任务或三个独立构建推断。原C汇总保留待独立核验字段，限定签收结合原始行、启动与退出身份和产物审查。</p><h2>原值、资格和来源</h2><ul>'+''.join('<li><a href="'+link+'">'+html.escape(link)+'</a></li>' for link in links)+'</ul><p><a href="../../software/CACR2026EA16XZ-数学源码与账本复核件.zip">56ad原匿名数学源码复核件</a> · <a href="REPLAY_PUBLIC.md">已有账本的只读重建核验</a> · <a href="../../verification/view-substitution-map.json">匿名视图字段角色</a></p>'
add('data/M02_REPLICATION/index.html',page('M02纯数学进程复核',body,'../../reader.css','../../index.html'),'M02_REPLICATION','static_current_raw_data_reader_index')

REPLAY = '''# 分发件中的已有M02账本只读核验

本页使用原56ad数学源码ZIP和本包M02专用C汇总快照；只编译工具、审计已有行和生成新JSON，不启动正式观察器。新产物不继承bc61计时资格。原独立C账本审计器要求所审原记录为Darwin/arm64，不能据此签收Linux测量。

在解压本包的根目录执行，使用一个新的工作目录。先逐项核对根SHA256SUMS和内嵌源码包固定摘要56ad7ece879df934c5be8b740729058063ae214f23081afb04ed1540102fcc24；任一不符停止，不给替换文件重新生成期待摘要。命令使用CMake/CTest来源，输出路径必须不存在。

```sh
set -eu
package_root=$(pwd -P)
shasum -a 256 -c SHA256SUMS
archive_path="$package_root/software/CACR2026EA16XZ-数学源码与账本复核件.zip"
actual_archive_digest=$(shasum -a 256 "$archive_path")
actual_archive_digest=${actual_archive_digest%% *}
test "$actual_archive_digest" = 56ad7ece879df934c5be8b740729058063ae214f23081afb04ed1540102fcc24
replay_root=$(mktemp -d "${TMPDIR:-/tmp}/m02-readonly.XXXXXX")
mkdir "$replay_root/source" "$replay_root/views" "$replay_root/outputs"
unzip -q "$archive_path" -d "$replay_root/source"
(cd "$replay_root/source" && shasum -a 256 -c SHA256SUMS)
cmake -S "$replay_root/source/audit" -B "$replay_root/audit" -DBUILD_TESTING=OFF
cmake --build "$replay_root/audit" --parallel 2
cmake -S "$package_root/data/M02_REPLICATION/preparation/summary-source" -B "$replay_root/summary" -DBUILD_TESTING=OFF -DSUMMARY_SANITIZERS=OFF
cmake --build "$replay_root/summary" --parallel 2
for process_number in 1 2 3; do
    mkdir "$replay_root/views/process-$process_number"
    ln -s "$package_root/data/M02_REPLICATION/run-$process_number" "$replay_root/views/process-$process_number/run"
    "$replay_root/audit/update_cost_result_review" "$replay_root/views/process-$process_number" "$package_root/data/M02_REPLICATION/preparation/fixed-inputs" "$replay_root/outputs/process-$process_number.json"
done
"$replay_root/summary/process_summary" "$package_root/data/M02_REPLICATION" "$replay_root/outputs/process-summary.json"
```

数值、meta、pending、输入副本和既有C审计JSON原字节保持。input-records.tsv是路径视图，原C审计器不读取该定位TSV；固定输入与run副本按实际字节核对。此只读步骤不独立枚举全部状态，不证明匿名路径视图原始运行身份，也不产生新成本样本。真正运行身份由执行UTC/PID、退出码、前后摘要和机器码审查原证据支持。
'''
add('data/M02_REPLICATION/REPLAY_PUBLIC.md',REPLAY.encode(),'M02_REPLICATION','distribution_readonly_rebuild_and_C_audit_instructions_no_formal_launch')

index=(PAYLOAD/'index.html').read_text()
old_start='<p>本版包含42页匿名研究报告'
start=index.index(old_start); finish=index.index('</p>',start)+4
index=index[:start]+'<p>本版增加2026年10月9日的官方工作簿补证和M02一次干净重建、三个新进程复核。当前报告将在最终页面核验后绑定；旧42页报告保留历史副本。原九组540项与M01保持，不新增密码测量，不替代软件v3，也不因此签收真实总体或R02/R04。</p>'+index[finish:]
index=index.replace('2026年10月8日','2026年10月9日')
extra='<h2>本轮新增与历史边界</h2><ul><li><a href="CURRENT_RESEARCH_NOTE.html">当前研究结论与匿名视图范围</a></li><li><a href="data/M02_REPLICATION/index.html">M02三进程原值、C审计及产物资格</a></li><li><a href="official/official-source-check.html">官方工作簿两项核对</a> · <a href="official/fips-203-potential-updates.xlsx">工作簿原件</a> · <a href="official/NIST.FIPS.203.pdf">FIPS原PDF</a></li><li><a href="software/CACR2026EA16XZ-数学源码与账本复核件.zip">原56ad匿名数学源码复核件</a></li><li><a href="historical/20261008/report/CACR2026EA16XZ-作品设计报告.pdf">旧42页匿名报告（历史）</a></li></ul>'
index=index.replace('<h2>研究论证</h2>',extra+'<h2>研究论证（2026年10月8日历史文档）</h2>')
index=index.replace('R02/R04、FIPS完整勘误适用性、裸金属动态构建失败及真实截图、审批和回执仍分别跟踪。','旧FIPS附件获取缺口已有上述具体工作簿补证；R02/R04真实总体、标准其他范围、裸金属动态失败及人员材料仍分别跟踪。')
add('index.html',index.encode(),'CURRENT_RESEARCH','current_offline_reader_index_awaiting_report_binding')
add('README.md',('# 当前研究报告与数据解释补充件\n\n本轮M02与官方来源补证见[当前说明](CURRENT_RESEARCH_NOTE.md)。原九组540项及M01字节身份保持。旧42页报告在historical/20261008保留；当前报告须经最终页面核验后另行绑定。原56ad数学源码ZIP及新C汇总快照用于已有账本只读核验，不替代软件v3。全部匿名视图须结合manifest.json与替换角色核对，原值不变。\n\n本阶段只有待核验payload，没有发布最终ZIP，不称已完成当前报告视觉签收。\n').encode(),'CURRENT_RESEARCH','current_stage_distribution_scope')

manifest=dict(old_manifest)
manifest['edition']='v4_current_M02_and_official_workbook_stage'
manifest['date']='2026-10-09'
manifest['parent_research_supplement_sha256']=OLD_SHA
manifest['group_origins']=dict(old_manifest['group_origins'])
manifest['group_origins']['M02_REPLICATION']='One clean rebuild bc61; Apple M5 macOS ARM64; three prespecified sequential processes; original C01 fixed tasks; no old M01 pooling; no cryptographic calls'
manifest['current_report_status']='awaiting_final_report_QA_and_root_binding'
manifest['original_M01_preserved']=True
manifest['original_nine_groups_540_preserved']=True
manifest['private_original_executables_distributed']=False
manifest['embedded_math_source_archive_sha256']=MATH_SHA
manifest['files']=sorted(records.values(),key=lambda item:item['distributed_path'])
(PAYLOAD/'manifest.json').write_text(json.dumps(manifest,ensure_ascii=False,indent=2)+'\n')
files=sorted(path for path in PAYLOAD.rglob('*') if path.is_file() and path.name!='SHA256SUMS')
# 每个目录中的旧SHA256SUMS也属于内容；这里只排除根自摘要文件。
files=sorted(path for path in PAYLOAD.rglob('*') if path.is_file() and path!=PAYLOAD/'SHA256SUMS')
(PAYLOAD/'SHA256SUMS').write_text(''.join(sha(path.read_bytes())+'  '+str(path.relative_to(PAYLOAD))+'\n' for path in files))

class Links(HTMLParser):
    def __init__(self): super().__init__(); self.links=[]; self.script=0;self.events=[];self.runtime=[];self.math=0
    def handle_starttag(self,tag,attrs):
        attrs=dict(attrs)
        if tag=='script':self.script+=1
        if tag=='math': self.math+=1
        for key,val in attrs.items():
            if key.lower().startswith('on'):self.events.append(key)
            if key in ['href','src']:self.links.append((tag,key,val))
            if key=='src' or (tag=='link' and key=='href'):
                if val and urlparse(val).scheme in ['http','https']:self.runtime.append(val)
missing=[];links_count=0;math_count=0
for source in sorted(PAYLOAD.rglob('*.html')):
    parser=Links();parser.feed(source.read_text())
    assert parser.script==0 and not parser.events and not parser.runtime
    math_count+=parser.math
    for tag,key,target in parser.links:
        if not target or target.startswith('#') or urlparse(target).scheme:continue
        path=(source.parent/unquote(target.split('#')[0].split('?')[0])).resolve()
        assert path.is_relative_to(PAYLOAD.resolve())
        links_count+=1
        if not path.exists():missing.append({'source':str(source.relative_to(PAYLOAD)),'target':target})
assert not missing,missing
identity_hits=[]
identity_tokens=['/Users/yin','yindeMacBook','Gowin-liuyin','yinhaoran0808@outlook.com','/home/nss-marker','119.45.121.134','10.144.144.5']
for source in PAYLOAD.rglob('*'):
    if not source.is_file() or source.suffix in ['.pdf','.docx','.xlsx','.zip']:continue
    text=source.read_text()
    for token in identity_tokens:
        if token in text:identity_hits.append({'path':str(source.relative_to(PAYLOAD)),'token_role':token})
assert not identity_hits,identity_hits
old_groups=set(old_manifest['group_origins'])-{'M01_UPDATE_COST'}
old_dataset=[item for item in old_manifest['files'] if item['dataset_group'] in old_groups and item['distributed_path'].startswith('data/')]
old_m01=[item for item in old_manifest['files'] if item['dataset_group']=='M01_UPDATE_COST']
with zipfile.ZipFile(OLD) as old_archive:
    assert all((PAYLOAD/item['distributed_path']).read_bytes()==old_archive.read(item['distributed_path']) for item in old_dataset+old_m01)
assert len(old_dataset)==540,(len(old_dataset))
assert len(old_m01)==20,len(old_m01)
verification={'stage_ready':True,'final_zip_created':False,'final_report_bound':False,'report_QA_pending':True,
              'parent_archive_sha256':OLD_SHA,'parent_archive_unchanged':sha(OLD.read_bytes())==OLD_SHA,
              'old_nine_groups_byte_identical':len(old_dataset),'old_M01_items_byte_identical':len(old_m01),
              'embedded_math_source_archive_sha256':sha((PAYLOAD/'software/CACR2026EA16XZ-数学源码与账本复核件.zip').read_bytes()),
              'files':len(files)+1,'manifest_records':len(records),'static_HTML_pages':len(list(PAYLOAD.rglob('*.html'))),
              'local_links_checked':links_count,'missing_local_links':len(missing),'native_MathML_blocks_preserved':math_count,
              'participant_identity_hits_text':identity_hits,'new_formal_runs':0,'Python_statistics_computed':False,
              'original_binary_omitted':True,'C_summary_values_rendered_without_recalculation':True,
              'overall_goal_complete':False}
(EVIDENCE/'stage-verification.json').write_text(json.dumps(verification,ensure_ascii=False,indent=2)+'\n')
(EVIDENCE/'STAGE_CONTRACT.md').write_text('# 当前匿名解释件阶段合同\n\n原59b件只读；旧九组540项及M01全部20项保持字节，旧42页报告保留历史身份。新增M02原行、时钟、C审计与资格；路径/身份视图单列摘要与替换角色。原二进制不分发；56ad匿名纯数学源码件保持原摘要，M02 C汇总快照不改。官方工作簿和PDF保持原字节。\n\n当前只建立待核验stage，最终新报告由根在页面QA完成后绑定，才允许生成新的分发ZIP。本模块没有新正式实验，也没有Python统计计算。\n')
(EVIDENCE/'source-export-map.json').write_text(json.dumps({'records':manifest['files'],'public_substitution_map':public_map,'omitted_originals':omitted},ensure_ascii=False,indent=2)+'\n')
print(json.dumps(verification,ensure_ascii=False))
