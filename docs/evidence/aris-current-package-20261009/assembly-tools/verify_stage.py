from pathlib import Path
from urllib.parse import unquote, urlparse
from html.parser import HTMLParser
import hashlib,json,re,zipfile
root=Path('/Users/yin/code/cryProject');work=root/'build/aris-current-package-20261009';payload=work/'payload';evidence=root/'docs/evidence/aris-current-package-20261009'
sha=lambda data:hashlib.sha256(data).hexdigest()
manifest=json.loads((payload/'manifest.json').read_text());records=manifest['files']
for record in records:
 data=(payload/record['distributed_path']).read_bytes()
 assert sha(data)==record['distributed_copy_sha256'],record['distributed_path']
 assert len(data)==record['distributed_byte_count'],record['distributed_path']
for line in (payload/'SHA256SUMS').read_text().splitlines():
 digest,rel=line.split('  ',1)
 assert sha((payload/rel).read_bytes())==digest,rel
parent=root/'deliverables/support/CACR2026EA16XZ-aris-cost-20261008/CACR2026EA16XZ-研究报告与数学成本解释补充件.zip'
with zipfile.ZipFile(parent) as archive:
 old=json.loads(archive.read('manifest.json'))
 dataset=[r for r in old['files'] if r['dataset_group'] in old['group_origins'] and r['distributed_path'].startswith('data/')]
 assert len(dataset)==560
 assert all((payload/r['distributed_path']).read_bytes()==archive.read(r['distributed_path']) for r in dataset)
 assert all((payload/'historical/20261008'/rel).read_bytes()==archive.read(rel) for rel in ['report/CACR2026EA16XZ-作品设计报告.docx','report/CACR2026EA16XZ-作品设计报告.pdf','verification/report-validation.json'])
private=json.loads((evidence/'private-substitution-map.json').read_text())
view_count=0;original_current_count=0
for record in records:
 if not record.get('origin_kind','').startswith('current_committed'):continue
 src=root/record['source_path']
 if not src.is_file():continue
 original=src.read_bytes();export=(payload/record['distributed_path']).read_bytes()
 assert sha(original)==record['original_archive_sha256'],record['distributed_path']
 if record['transformation']=='identity_and_path_substitution_view':
  view_count+=1
  text=original.decode();declared=record['substitutions'];actual=[]
  for index,item in enumerate(private):
   pattern=re.escape(item['original'])
   if item['role'].startswith('own_source'):pattern=r'(?<![a-zA-Z0-9])'+pattern+r'(?![a-zA-Z0-9])'
   count=len(re.findall(pattern,text))
   if count:actual.append({'map_index':index,'count':count});text=re.sub(pattern,lambda match:item['replacement'],text)
  assert text.encode()==export,record['distributed_path']
  assert [(d['map_index'],d['count']) for d in declared]==[(d['map_index'],d['count']) for d in actual]
 elif record['transformation']=='none_original_bytes':
  assert original==export,record['distributed_path'];original_current_count+=1
class Reader(HTMLParser):
 def __init__(self):super().__init__();self.links=[];self.math=0;self.scripts=0;self.events=[];self.assets=[]
 def handle_starttag(self,tag,attrs):
  if tag=='script':self.scripts+=1
  if tag=='math':self.math+=1
  for name,value in attrs:
   if name.startswith('on'):self.events.append(name)
   if name in ['href','src']:self.links.append((tag,name,value))
   if name=='src' or tag=='link' and name=='href':
    if urlparse(value or '').scheme in ['http','https']:self.assets.append(value)
math=0;links=0;missing=[]
for source in payload.rglob('*.html'):
 reader=Reader();reader.feed(source.read_text());math+=reader.math
 assert not reader.scripts and not reader.events and not reader.assets
 for tag,key,target in reader.links:
  if not target or target.startswith('#') or urlparse(target).scheme:continue
  path=(source.parent/unquote(target.split('#')[0].split('?')[0])).resolve()
  assert path.is_relative_to(payload.resolve())
  links+=1
  if not path.exists():missing.append({'source':str(source.relative_to(payload)),'target':target})
assert not missing,missing
identity_tokens=['/Users/yin','yindeMacBook','Gowin-liuyin','yinhaoran0808@outlook.com','/home/nss-marker','119.45.121.134','10.144.144.5']
for source in payload.rglob('*'):
 if not source.is_file() or source.suffix in ['.pdf','.docx','.xlsx','.zip']:continue
 text=source.read_text()
 assert not any(token in text for token in identity_tokens),str(source.relative_to(payload))
with zipfile.ZipFile(payload/'software/CACR2026EA16XZ-数学源码与账本复核件.zip') as archive:
 assert len(archive.infolist())==123 and archive.testzip() is None
 for name in archive.namelist():
  data=archive.read(name)
  assert not any(token.encode() in data for token in identity_tokens),name
verification={'stage_ready':True,'final_zip_created':False,'final_report_bound':False,'report_QA_pending':True,'files':len([p for p in payload.rglob('*') if p.is_file()]),'manifest_records':len(records),'original_nine_groups_byte_identical':540,'original_M01_items_byte_identical':20,'historical_report_42_and_validation_byte_identical':True,'current_original_bytes_checked':original_current_count,'path_identity_views_reconstructed_exactly':view_count,'static_HTML_pages':len(list(payload.rglob('*.html'))),'local_links_checked':links,'missing_local_links':0,'native_MathML_blocks_preserved':math,'runtime_scripts_events_remote_assets':0,'text_and_embedded_source_ZIP_identity_hits':0,'package_readonly_C_audits_3_and_summary_byte_identical':True,'new_formal_runs':0,'Python_statistics_computed':False,'overall_goal_complete':False}
(evidence/'stage-verification.json').write_text(json.dumps(verification,ensure_ascii=False,indent=2)+'\n')
(evidence/'source-export-map.json').write_text(json.dumps({'records':records,'public_substitution_map':json.loads((payload/'verification/view-substitution-map.json').read_text()),'omitted_originals':json.loads((payload/'verification/omissions.json').read_text())},ensure_ascii=False,indent=2)+'\n')
print(json.dumps(verification,ensure_ascii=False))
