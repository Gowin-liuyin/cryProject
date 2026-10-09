from pathlib import Path,PurePosixPath
import datetime,hashlib,io,json,os,subprocess,tarfile,time
project=Path('/home/nss-marker/yhr/Cry')
root=project/'frequency-source-991f154'
assert Path.cwd()==project and root.resolve()==root and os.geteuid()!=0
data=(root/'source-991f154.tar').read_bytes()
assert hashlib.sha256(data).hexdigest()=='51631f225bdcedb44440897d06192d3138dad3baa9b95ff59319fd1d5d7042cd'
with tarfile.open(fileobj=io.BytesIO(data)) as archive:
 members=archive.getmembers()
 assert len(members)<32 and sum(m.size for m in members)<1024*1024
 for member in members:
  path=PurePosixPath(member.name)
  assert not path.is_absolute() and '..' not in path.parts and path.parts[0]=='source'
  assert member.isdir() or member.isfile()
 for member in members:
  target=root/member.name
  if member.isdir(): target.mkdir(mode=0o700)
  else:
   with target.open('xb') as output: output.write(archive.extractfile(member).read())
source_root=root/'source/docs/research/aris-core-partition-20261010'
assert hashlib.sha256((source_root/'rehearse_partition.py').read_bytes()).hexdigest()=='b7057c2af9a32ac93491815756eaaf0d964745f56ef4f9c05b59c84ba36c7661'
for name in ('tmp','cache'): (root/name).mkdir(mode=0o700)
environment=os.environ.copy()
environment.update({'TMPDIR':str(root/'tmp'),'TMP':str(root/'tmp'),'TEMP':str(root/'tmp'),'XDG_CACHE_HOME':str(root/'cache'),'PYTHONPYCACHEPREFIX':str(root/'cache'),'PYTHONDONTWRITEBYTECODE':'1','LC_ALL':'C'})
steps=[('configure',['/usr/bin/cmake','-S',str(source_root),'-B',str(root/'build'),'-DPython3_EXECUTABLE=/usr/bin/python3']),('test',['/usr/bin/ctest','--test-dir',str(root/'build'),'--output-on-failure'])]
results=[]
for label,arguments in steps:
 with (root/(label+'.log')).open('xb') as output:
  started=time.monotonic()
  process=subprocess.Popen(arguments,cwd=root,env=environment,stdout=output,stderr=subprocess.STDOUT)
  record={'label':label,'arguments':arguments,'pid':process.pid,'start_ticks':Path(f'/proc/{process.pid}/stat').read_text().rpartition(')')[2].split()[19]}
  try: record['exit_code']=process.wait(timeout=60)
  except subprocess.TimeoutExpired:
   record.update({'observation_timeout':True,'process_exit_unconfirmed':True})
   with (root/(label+'-timeout.json')).open('x') as state: json.dump(record,state,indent=2)
   print(json.dumps(record),flush=True)
   raise
  record['wall_seconds']=time.monotonic()-started
 with (root/(label+'-result.json')).open('x') as state: json.dump(record,state,indent=2)
 results.append(record)
 if record['exit_code']!=0:
  print(json.dumps({'status':'failed','steps':results}),flush=True)
  raise SystemExit(1)
print(json.dumps({'status':'software_check_passed','utc':datetime.datetime.now(datetime.timezone.utc).isoformat(),'source_sha256':'b7057c2af9a32ac93491815756eaaf0d964745f56ef4f9c05b59c84ba36c7661','steps':results,'test_log':(root/'build/Testing/Temporary/LastTest.log').read_text(),'tmp_entries':list(p.name for p in (root/'tmp').iterdir()),'symlinks':[str(p.relative_to(root)) for p in root.rglob('*') if p.is_symlink()],'configuration_writes':0},indent=2))
