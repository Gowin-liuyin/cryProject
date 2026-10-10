import sys,os,hashlib,json,tarfile,io,re
from pathlib import Path
base=Path('/home/nss-marker/yhr/Cry');root=Path('/home/nss-marker/yhr/Cry/raw-clock-aa43771-fe4ffb3f92f3630e')
assert root.parent==base and re.fullmatch(r'raw-clock-[0-9a-f]{7}-[0-9a-f]{16}',root.name)
assert base.resolve(strict=True)==base and base.is_dir()
assert not root.exists() and not root.is_symlink()
os.umask(0o077)
blob=sys.stdin.buffer.read(1048577)
assert len(blob)<=1048576 and hashlib.sha256(blob).hexdigest()=='ed7d049f6fe304b791b6d74aa16fcca78c4d4c92aa7bc6af3119f004872689de'
upload=Path(str(root)+'.upload.tar')
with upload.open('xb') as f:f.write(blob)
with tarfile.open(fileobj=io.BytesIO(blob),mode='r:') as archive:
 members=archive.getmembers();assert len(members)==4 and set(m.name for m in members)==set({'raw_clock_calibration.c': 'ed538f4322fba985aea9cfa78e0b2109f79caed49064e68eaa3884b4fa10f0dd', 'analyze_raw_clock.c': 'c67d1dbd89034a75600d3d13a28aa5c7fb4a163b5649fa910c7eea624c7544e0', 'CMakeLists.txt': '28d264a993558d1aad66dd6ffd2671c0a3ea18054fda6d6ec91b06a7c312816e', 'remote_run.py': 'bf34389f2cb39348ac1baa2a3c2b159ad69cb473414ff3b6b7b97850d0431d04'})
 payload={}
 for m in members:
  assert m.isfile() and m.name in {'raw_clock_calibration.c': 'ed538f4322fba985aea9cfa78e0b2109f79caed49064e68eaa3884b4fa10f0dd', 'analyze_raw_clock.c': 'c67d1dbd89034a75600d3d13a28aa5c7fb4a163b5649fa910c7eea624c7544e0', 'CMakeLists.txt': '28d264a993558d1aad66dd6ffd2671c0a3ea18054fda6d6ec91b06a7c312816e', 'remote_run.py': 'bf34389f2cb39348ac1baa2a3c2b159ad69cb473414ff3b6b7b97850d0431d04'} and 0<m.size<1048576
  value=archive.extractfile(m).read();assert hashlib.sha256(value).hexdigest()=={'raw_clock_calibration.c': 'ed538f4322fba985aea9cfa78e0b2109f79caed49064e68eaa3884b4fa10f0dd', 'analyze_raw_clock.c': 'c67d1dbd89034a75600d3d13a28aa5c7fb4a163b5649fa910c7eea624c7544e0', 'CMakeLists.txt': '28d264a993558d1aad66dd6ffd2671c0a3ea18054fda6d6ec91b06a7c312816e', 'remote_run.py': 'bf34389f2cb39348ac1baa2a3c2b159ad69cb473414ff3b6b7b97850d0431d04'}[m.name];payload[m.name]=value
root.mkdir(mode=0o700);source=root/'source';source.mkdir(mode=0o700)
for name,value in payload.items():
 with (source/name).open('xb') as f:f.write(value)
print(json.dumps({'status':'source_staged','root':str(root),'upload':str(upload),'upload_sha256':hashlib.sha256(upload.read_bytes()).hexdigest(),'files':{name:hashlib.sha256((source/name).read_bytes()).hexdigest() for name in payload}},separators=(',',':')))
