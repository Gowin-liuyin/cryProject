from pathlib import Path
import hashlib,html,json,re,subprocess,zipfile
root=Path('/Users/yin/code/cryProject');work=root/'build/aris-current-package-20261009';payload=work/'payload';evidence=root/'docs/evidence/aris-current-package-20261009'
manifest=json.loads((payload/'manifest.json').read_text());records={item['distributed_path']:item for item in manifest['files']}
sha=lambda data:hashlib.sha256(data).hexdigest()
private=json.loads((evidence/'private-substitution-map.json').read_text())
public=json.loads((payload/'verification/view-substitution-map.json').read_text())

def sanitize(data):
 text=data.decode();substitutions=[]
 for index,item in enumerate(private):
  pattern=re.escape(item['original'])
  if item['role'].startswith('own_source'):pattern=r'(?<![a-zA-Z0-9])'+pattern+r'(?![a-zA-Z0-9])'
  count=len(re.findall(pattern,text))
  if count:
   text=re.sub(pattern,lambda match:item['replacement'],text)
   substitutions.append({'map_index':index,'count':count,**public[index]})
 return text.encode(),substitutions

def add(relative,data,group,role,source=None,transformation='generated_metadata_or_static_reading',substitutions=None):
 dest=payload/relative;dest.parent.mkdir(parents=True,exist_ok=True);dest.write_bytes(data)
 original=source.read_bytes() if source else None
 record={'source_path':str(source.relative_to(root)) if source else 'generated_current_package_document','distributed_path':relative,'dataset_group':group,'original_archive_sha256':sha(original) if original is not None else None,'distributed_copy_sha256':sha(data),'original_byte_count':len(original) if original is not None else None,'distributed_byte_count':len(data),'content_role':role,'transformation':transformation,'origin_kind':'current_committed_report_or_current_internal_QA_or_generated_reading'}
 if substitutions:
  record['substitutions']=substitutions;record['public_substitution_map']='verification/view-substitution-map.json';record['scientific_values_modified']=False;record['participant_identity_view_not_original_bytes']=True
 records[relative]=record

reportroot=root/'deliverables/research/aris-report-current-20261009'
expect={'docx':'4c6ef7de4cfa681dd3550ec570d9a96b248e1a62885fccbdb4f0f6ea4421a7ca','pdf':'a0a82ac3626ad1e35cb09430f00790e3120796ffe8a9f186eff1c119c3504f44'}
for suffix,digest in expect.items():
 source=reportroot/('CACR2026EA16XZ-作品设计报告-匿名版.'+suffix)
 original=source.read_bytes();assert sha(original)==digest
 committed=subprocess.check_output(['git','show','2855ec3:'+str(source.relative_to(root))],cwd=root)
 assert original==committed
 add('report/CACR2026EA16XZ-作品设计报告.'+suffix,original,'REPORT_CURRENT_45','byte_exact_final_anonymous_45_page_report_science_visual_root_approved',source,'none_original_bytes')
qroot=root/'docs/evidence/aris-report-current-20261009'
qa=json.loads((qroot/'final-verification.json').read_text())
assert qa['pages']==45 and qa['cover_date']=='2026-10-09' and qa['final_docx_sha256']==expect['docx'] and qa['final_pdf_sha256']==expect['pdf']
report_sources={'final-verification.json':'verification/report-validation.json','final-file-map.json':'verification/report-current/final-file-map.json','scientific-review.md':'verification/report-current/scientific-review.md','visual-pages-1-13.md':'verification/report-current/visual-pages-1-13.md','visual-pages-14-30.md':'verification/report-current/visual-pages-14-30.md','visual-pages-31-45.md':'verification/report-current/visual-pages-31-45.md','visual-final-binding.md':'verification/report-current/visual-final-binding.md','cover-date-pixel-comparison.json':'verification/report-current/cover-date-pixel-comparison.json','cover-date-only-edit.json':'verification/report-current/cover-date-only-edit.json','root-final-cover-review.md':'verification/report-current/root-final-cover-review.md'}
for name,rel in report_sources.items():
 source=qroot/name;data,substitutions=sanitize(source.read_bytes())
 add(rel,data,'REPORT_CURRENT_45','actual_report_science_visual_or_anonymous_validation'+('_anonymous_view' if substitutions else '_original_bytes'),source,'identity_and_path_substitution_view' if substitutions else 'none_original_bytes',substitutions)
source=evidence/'package-readonly-replay.json';data,substitutions=sanitize(source.read_bytes())
add('verification/package-readonly-replay.json',data,'VERIFICATION','actual_package_only_C_audit_rebuild_and_output_identity'+('_anonymous_view' if substitutions else '_original_bytes'),source,'identity_and_path_substitution_view' if substitutions else 'none_original_bytes',substitutions)
index=(payload/'index.html').read_text()
old='当前报告将在最终页面核验后绑定；旧42页报告保留历史副本。'
assert old in index
index=index.replace(old,'本版绑定已通过科学及全页视觉核对的45页匿名报告，封面日期为10月9日；旧42页报告保留历史副本。')
index=index.replace('<h1>研究报告与数学成本核对</h1>','<h1>当前研究报告与数学复核材料</h1>')
index=index.replace('<a href="verification/report-validation.json">报告实际核验</a>','<a href="verification/report-validation.json">当前45页报告实际核验</a> · <a href="verification/report-current/visual-final-binding.md">全页视觉身份绑定</a> · <a href="verification/report-current/scientific-review.md">限定科学审查</a> · <a href="verification/package-readonly-replay.json">包内只读C复核</a>')
add('index.html',index.encode(),'CURRENT_RESEARCH','final_current_offline_reader_index')
readme='''# 2026年10月9日当前研究报告与数学复核补充件

打开[index.html](index.html)离线阅读当前45页匿名报告、官方来源补证、M02原值与核验。报告封面为2026年10月9日；科学审查及原分辨率全页视觉核对已通过。实际45页候选逐页审读，最终仅封面日期变化，另实际核对新封面，其余44页PNG字节和像素身份保持。旧42页报告和核验在historical/20261008保持原字节。

九组旧数据540项与M01全部20项保持59b包内身份。M02另保存一次干净重建、同机三个顺序新进程：六份既定非零输入的18个中位比均小于1，240对时钟资格全部满足。八任务只有七种CSV，3/7是相同全零输入；各进程24份输入副本不是新数据集。不合并M01、C01/C03和M02，不把三个进程当独立构建、独立同分布样本或任务总体。

NIST官方工作簿及原PDF逐字保持本轮公开下载摘要。工作簿只有两项潜在修正，固定便携C静态核对未指示这两项需要补丁；条目不是已实施的新标准要求，不覆盖全部标准、后端、认证或恒时。旧未取得附件的时点记录保留，当前补证见CURRENT_RESEARCH_NOTE。

原始数值CSV、meta、pending、输入副本和C审计/汇总JSON保留原字节。路径、主机名和自有Git身份只在声明的匿名视图中替换；清单给出原件/分发SHA256、字段角色和替换次数，公开映射只含原标记哈希。PID、UTC、数值、编译选项和失败没有改写。原普通/动态二进制不分发，bc61摘要及机器码资格视图保留。

原56ad匿名纯数学源码ZIP和M02专用C汇总快照提供已有账本只读重建及C核验。实际按包内路径构建后，三个审计输出及汇总与原JSON逐字一致，没有启动观察器或重新枚举统计空间。它们不替代原软件v3；静态HTML阅读不是软件执行截图。R02/R04、频率受控数据、真实总体前提、外部独立复现及真人材料继续保持未闭合，整体研究/竞赛目标不由本补充件签收。
'''
add('README.md',readme.encode(),'CURRENT_RESEARCH','final_distribution_scope_and_digest_role_explanation')
manifest['edition']='v4_current_45_page_report_M02_and_official_workbook'
manifest['current_report_status']='45_page_final_report_science_visual_root_approved_byte_exact_bound'
manifest['current_report_sha256']=expect
manifest['report_role']='current_anonymous_45_page_report_with_M02_and_official_workbook_integration_old_42_historical'
manifest['package_not_software_replacement']=True
manifest['package_readonly_C_replay_verified']=True
manifest['current_report_pages']=45
manifest['current_report_cover_date']='2026-10-09'
manifest['files']=sorted(records.values(),key=lambda item:item['distributed_path'])
(payload/'manifest.json').write_text(json.dumps(manifest,ensure_ascii=False,indent=2)+'\n')
files=sorted(path for path in payload.rglob('*') if path.is_file() and path!=payload/'SHA256SUMS')
(payload/'SHA256SUMS').write_text(''.join(sha(path.read_bytes())+'  '+str(path.relative_to(payload))+'\n' for path in files))
binding={'report_bound':True,'report_pages':45,'cover_date':'2026-10-09','report_digests':expect,'bound_byte_exact_to_actual_report_and_committed_2855ec3':True,'new_experiments':0,'old42_historical_backup_preserved':True,'final_archive_created':False,'root_authorized_final_package_binding':True}
(evidence/'final-report-binding.json').write_text(json.dumps(binding,ensure_ascii=False,indent=2)+'\n')
(evidence/'FINAL_ASSEMBLY_CONTRACT.md').write_text('# 当前解释件最终绑定合同\n\n根已核对并提交最终45页报告，授权本模块逐字绑定DOCX4c6ef7de/PDFa0a82ac3并制作新ZIP。原42页历史副本、九组540项及M01全部20项保持字节。本轮只更新当前报告槽与真实核验、当前索引/README、manifest/SHA；原M02数值和阶段状态不回填。正式ZIP在独立stage复核、全部闭包/匿名/摘要核对通过后新建，既有任何分发件不覆盖。\n\n准备阶段860项核验记录仍单独保留历史范围，不用来代签新最终包。新最终记录将绑定实际报告和ZIP身份；不重复C审计或启动正式观察器。\n')
print(json.dumps(binding,ensure_ascii=False))
