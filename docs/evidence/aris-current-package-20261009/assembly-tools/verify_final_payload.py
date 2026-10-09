from pathlib import Path
from urllib.parse import unquote,urlparse
from html.parser import HTMLParser
from lxml import etree
from pypdf import PdfReader
import hashlib,json,re,zipfile
root=Path('/Users/yin/code/cryProject');work=root/'build/aris-current-package-20261009';payload=work/'payload';evidence=root/'docs/evidence/aris-current-package-20261009'
sha=lambda data:hashlib.sha256(data).hexdigest()
manifest=json.loads((payload/'manifest.json').read_text());records=manifest['files'];paths=set()
for record in records:
 rel=record['distributed_path'];assert rel not in paths;paths.add(rel)
 data=(payload/rel).read_bytes();assert sha(data)==record['distributed_copy_sha256'],rel;assert len(data)==record['distributed_byte_count'],rel
files={str(p.relative_to(payload)) for p in payload.rglob('*') if p.is_file()}
assert files==paths|{'manifest.json','SHA256SUMS'}
sums={}
for line in (payload/'SHA256SUMS').read_text().splitlines():
 digest,rel=line.split('  ',1);assert rel not in sums;sums[rel]=digest
 assert sha((payload/rel).read_bytes())==digest,rel
assert set(sums)==files-{'SHA256SUMS'}
parent=root/'deliverables/support/CACR2026EA16XZ-aris-cost-20261008/CACR2026EA16XZ-研究报告与数学成本解释补充件.zip'
assert sha(parent.read_bytes())=='59b858391d21392e3725e01791b8b877f942599ccce46d323aacc22d109cf9ee'
with zipfile.ZipFile(parent) as archive:
 old=json.loads(archive.read('manifest.json'))
 dataset=[record for record in old['files'] if record['dataset_group'] in old['group_origins'] and record['distributed_path'].startswith('data/')]
 assert len(dataset)==560
 assert all((payload/record['distributed_path']).read_bytes()==archive.read(record['distributed_path']) for record in dataset)
 for rel in ['report/CACR2026EA16XZ-作品设计报告.docx','report/CACR2026EA16XZ-作品设计报告.pdf','verification/report-validation.json']:
  assert (payload/'historical/20261008'/rel).read_bytes()==archive.read(rel)
private=json.loads((evidence/'private-substitution-map.json').read_text());public=json.loads((payload/'verification/view-substitution-map.json').read_text())
views=0;originals=0
for record in records:
 if not record.get('origin_kind','').startswith('current_committed'):continue
 source=root/record['source_path']
 if not source.is_file():continue
 original=source.read_bytes();export=(payload/record['distributed_path']).read_bytes()
 assert sha(original)==record['original_archive_sha256'],record['distributed_path']
 if record['transformation']=='identity_and_path_substitution_view':
  views+=1;text=original.decode();actual=[]
  for index,item in enumerate(private):
   pattern=re.escape(item['original'])
   if item['role'].startswith('own_source'):pattern=r'(?<![a-zA-Z0-9])'+pattern+r'(?![a-zA-Z0-9])'
   count=len(re.findall(pattern,text))
   if count:text=re.sub(pattern,lambda match:item['replacement'],text);actual.append({'map_index':index,'count':count,**public[index]})
  assert text.encode()==export and record['substitutions']==actual,record['distributed_path']
 elif record['transformation']=='none_original_bytes':assert original==export;originals+=1
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
links=0;math=0;missing=[]
for source in payload.rglob('*.html'):
 parser=Reader();parser.feed(source.read_text());math+=parser.math
 assert not parser.scripts and not parser.events and not parser.assets
 for tag,key,target in parser.links:
  if not target or target.startswith('#') or urlparse(target).scheme:continue
  path=(source.parent/unquote(target.split('#')[0].split('?')[0])).resolve();assert path.is_relative_to(payload.resolve());links+=1
  if not path.exists():missing.append({'source':str(source.relative_to(payload)),'target':target})
assert not missing,missing
identity_tokens=['/Users/yin','yindeMacBook','Gowin-liuyin','yinhaoran0808@outlook.com','/home/nss-marker','119.45.121.134','10.144.144.5']
for source in payload.rglob('*'):
 if not source.is_file() or source.suffix in ['.pdf','.docx','.xlsx','.zip']:continue
 data=source.read_bytes()
 assert not any(token.encode() in data for token in identity_tokens),str(source.relative_to(payload))
matharchive=payload/'software/CACR2026EA16XZ-数学源码与账本复核件.zip'
assert sha(matharchive.read_bytes())=='56ad7ece879df934c5be8b740729058063ae214f23081afb04ed1540102fcc24'
with zipfile.ZipFile(matharchive) as archive:
 assert len(archive.infolist())==123 and archive.testzip() is None
 for name in archive.namelist():assert not any(token.encode() in archive.read(name) for token in identity_tokens),name
reportdocx=payload/'report/CACR2026EA16XZ-作品设计报告.docx';reportpdf=payload/'report/CACR2026EA16XZ-作品设计报告.pdf'
assert sha(reportdocx.read_bytes())=='4c6ef7de4cfa681dd3550ec570d9a96b248e1a62885fccbdb4f0f6ea4421a7ca'
assert sha(reportpdf.read_bytes())=='a0a82ac3626ad1e35cb09430f00790e3120796ffe8a9f186eff1c119c3504f44'
with zipfile.ZipFile(reportdocx) as archive:
 assert archive.testzip() is None
 for name in archive.namelist():assert not any(token.encode() in archive.read(name) for token in identity_tokens),name
 core=etree.fromstring(archive.read('docProps/core.xml'));app=etree.fromstring(archive.read('docProps/app.xml'))
 ns={'dc':'http://purl.org/dc/elements/1.1/','cp':'http://schemas.openxmlformats.org/package/2006/metadata/core-properties','ep':'http://schemas.openxmlformats.org/officeDocument/2006/extended-properties'}
 assert not ''.join(core.xpath('dc:creator/text()|cp:lastModifiedBy/text()',namespaces=ns)).strip()
 pages=app.find('ep:Pages',ns);assert pages.text=='45'
 customprops=0
 if 'docProps/custom.xml' in archive.namelist():customprops=len(etree.fromstring(archive.read('docProps/custom.xml')));assert customprops==0
 document=etree.fromstring(archive.read('word/document.xml'))
 covertext=''.join(document.xpath('//*[local-name()="t"]/text()'))
 assert '2026年10月9日' in covertext
 reportmetadata={'creator_and_lastModifiedBy_empty':True,'custom_properties':customprops,'app_cached_pages':45,'core_sha256':sha(archive.read('docProps/core.xml')),'app_sha256':sha(archive.read('docProps/app.xml')),'native_OMML':len(document.xpath('//*[local-name()="oMath"]'))}
pdf=PdfReader(reportpdf);assert len(pdf.pages)==45 and not pdf.metadata.get('/Author')
metadata_text=str(pdf.metadata);pdftext='\n'.join(page.extract_text() or '' for page in pdf.pages)
assert not any(token in metadata_text+pdftext for token in identity_tokens)
reportmetadata['actual_pdf_pages']=45;reportmetadata['pdf_author_empty']=True;reportmetadata['pdf_public_metadata']={str(key):str(value) for key,value in pdf.metadata.items()}
workbook=payload/'official/fips-203-potential-updates.xlsx';nistpdf=payload/'official/NIST.FIPS.203.pdf'
assert sha(workbook.read_bytes())=='edf899c89762449f43d7713883caeefc2e4ae9ae98d5a76b339547db22cb3ac7'
assert sha(nistpdf.read_bytes())=='fe1f12f32a7e44ec9fdebbf400cda843a40b506dee676725234dc6f7923b6cac'
assert len(PdfReader(nistpdf).pages)==56
qa=json.loads((payload/'verification/report-validation.json').read_text())
assert qa['pages']==45 and qa['final_docx_sha256']==sha(reportdocx.read_bytes()) and qa['final_pdf_sha256']==sha(reportpdf.read_bytes())
verification={'final_payload_passed':True,'final_report_bound':True,'report_pages':45,'report_cover_date':'2026-10-09','report_docx_sha256':sha(reportdocx.read_bytes()),'report_pdf_sha256':sha(reportpdf.read_bytes()),'files':len(files),'manifest_records':len(records),'SHA256SUMS_records':len(sums),'old_nine_groups_byte_identical':540,'old_M01_items_byte_identical':20,'historical_42_report_and_validation_exact':True,'current_original_bytes_checked':originals,'path_identity_views_reconstructed_exactly':views,'static_HTML_pages':len(list(payload.rglob('*.html'))),'local_links_checked':links,'missing_local_links':0,'native_MathML_blocks_preserved':math,'runtime_scripts_events_remote_assets':0,'text_DOCX_PDF_and_embedded_source_ZIP_identity_hits':0,'report_metadata':reportmetadata,'unchanged_NIST_originals_verified':True,'unchanged56ad_source_ZIP_verified':True,'original_timing_executables_distributed':False,'package_readonly_C_audits_and_summary_original_output_identity_previously_verified':True,'new_C_replay_for_final_binding':False,'new_formal_runs':0,'Python_statistics_computed':False,'whole_goal_complete':False}
(evidence/'final-payload-verification.json').write_text(json.dumps(verification,ensure_ascii=False,indent=2)+'\n')
(evidence/'final-source-export-map.json').write_text(json.dumps({'records':records,'public_substitution_map':public,'omitted_originals':json.loads((payload/'verification/omissions.json').read_text())},ensure_ascii=False,indent=2)+'\n')
print(json.dumps(verification,ensure_ascii=False))
