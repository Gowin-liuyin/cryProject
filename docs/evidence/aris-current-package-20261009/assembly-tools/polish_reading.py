from pathlib import Path
from urllib.parse import urlparse
import hashlib, html, json, os, re
root=Path('/Users/yin/code/cryProject'); work=root/'build/aris-current-package-20261009';payload=work/'payload'
manifest=json.loads((payload/'manifest.json').read_text()); records={r['distributed_path']:r for r in manifest['files']}
sha=lambda data:hashlib.sha256(data).hexdigest()
source_map={str((root/r['source_path']).resolve()):r['distributed_path'] for r in manifest['files'] if r['source_path']!='generated_current_package_document' and r['content_role'].endswith(('original_bytes','anonymous_view'))}
def inline(text,original,destination):
 escaped=html.escape(text)
 def link(match):
  label=match.group(1);target=html.unescape(match.group(2))
  if urlparse(target).scheme in ['http','https']:href=target
  else:
   original_target=(original.parent/target.split('#')[0]).resolve()
   mapped=source_map.get(str(original_target))
   if not mapped:return label
   href=os.path.relpath(payload/mapped,destination.parent)
  return '<a href="'+html.escape(href,quote=True)+'">'+label+'</a>'
 escaped=re.sub(r'\[([^\]]+)\]\(([^)]+)\)',link,escaped)
 escaped=re.sub(r'\*\*([^*]+)\*\*',r'<strong>\1</strong>',escaped)
 escaped=re.sub(r'`([^`]+)`',r'<code>\1</code>',escaped)
 return escaped
def readable(text,original,destination):
 parts=[];paragraph=[];table=[];code=[];in_code=False
 def flush():
  if paragraph:parts.append('<p>'+inline(' '.join(paragraph),original,destination)+'</p>');paragraph.clear()
 def flush_table():
  if table:
   cells=[line.strip().strip('|').split('|') for line in table]
   cells=[row for row in cells if not all(re.fullmatch(r'[:\-\s]+',cell) for cell in row)]
   parts.append('<div class="table-wrap"><table><thead><tr>'+''.join('<th>'+inline(c.strip(),original,destination)+'</th>' for c in cells[0])+'</tr></thead><tbody>'+''.join('<tr>'+''.join('<td>'+inline(c.strip(),original,destination)+'</td>' for c in row)+'</tr>' for row in cells[1:])+'</tbody></table></div>');table.clear()
 for line in text.splitlines():
  if line.startswith('```'):
   flush();flush_table()
   if in_code:parts.append('<pre><code>'+html.escape('\n'.join(code))+'</code></pre>');code=[]
   in_code=not in_code;continue
  if in_code:code.append(line);continue
  if line.startswith('|'):flush();table.append(line);continue
  flush_table()
  if not line.strip():flush();continue
  heading=re.match(r'^(#{1,6})\s+(.*)',line)
  if heading:flush();level=len(heading.group(1));parts.append(f'<h{level}>'+inline(heading.group(2),original,destination)+f'</h{level}>')
  elif line.startswith('- '):flush();parts.append('<p>• '+inline(line[2:],original,destination)+'</p>')
  else:paragraph.append(line)
 flush();flush_table();assert not in_code
 return ''.join(parts)
items=[('CURRENT_RESEARCH_NOTE.md','CURRENT_RESEARCH_NOTE.html','reader.css','index.html')]
items += [('data/M02_REPLICATION/research/'+name+'.md','data/M02_REPLICATION/research/'+name+'.html','../../../reader.css','../../../index.html') for name in ['REPLICATION_CONTRACT','RESULTS','RESULT_TO_CLAIM']]
items += [('official/official-source-check.md','official/official-source-check.html','../reader.css','../index.html')]
for src_rel,dst_rel,css,back in items:
 src=payload/src_rel;dst=payload/dst_rel
 original=root/records[src_rel]['source_path'] if records[src_rel]['source_path']!='generated_current_package_document' else src
 body=readable(src.read_text(),original,dst)
 text='<!doctype html><html lang="zh-CN"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>'+html.escape(src.read_text().splitlines()[0].lstrip('# '))+'</title><link rel="stylesheet" href="'+css+'"></head><body><main><p><a href="'+back+'">返回材料索引</a></p>'+body+'</main></body></html>'
 dst.write_text(text)
 records[dst_rel]['distributed_copy_sha256']=sha(dst.read_bytes());records[dst_rel]['distributed_byte_count']=len(dst.read_bytes())
 records[dst_rel]['derived_from_distributed_path']=src_rel;records[dst_rel]['derived_from_distributed_sha256']=sha(src.read_bytes())
manifest['files']=sorted(records.values(),key=lambda item:item['distributed_path'])
(payload/'manifest.json').write_text(json.dumps(manifest,ensure_ascii=False,indent=2)+'\n')
files=sorted(path for path in payload.rglob('*') if path.is_file() and path!=payload/'SHA256SUMS')
(payload/'SHA256SUMS').write_text(''.join(sha(path.read_bytes())+'  '+str(path.relative_to(payload))+'\n' for path in files))
print('Polished five current static reading pages; old MathML and all old data unchanged.')
