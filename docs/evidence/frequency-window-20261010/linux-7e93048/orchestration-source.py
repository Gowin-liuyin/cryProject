from pathlib import Path,PurePosixPath
import datetime,hashlib,io,json,os,subprocess,tarfile,time
project=Path('/home/nss-marker/yhr/Cry')
root=project/'window-source-7e93048'
assert Path.cwd()==project and root.resolve()==root and os.geteuid()!=0 and os.uname().nodename=='nss-m'
data=(root/'window-source-7e93048.tar').read_bytes()
assert hashlib.sha256(data).hexdigest()=='9229b613ead32f49ee73285fa39dff6b060b20287e3fce3a6bb9db944d8e84a4'
with tarfile.open(fileobj=io.BytesIO(data)) as archive:
 members=archive.getmembers()
 assert len(members)<512 and sum(m.size for m in members)<8*1024*1024
 for member in members:
  name=PurePosixPath(member.name)
  assert not name.is_absolute() and '..' not in name.parts and name.parts[0]=='source'
  assert member.isdir() or member.isfile()
 for member in members:
  target=root/member.name
  if member.isdir(): target.mkdir(mode=0o700)
  else:
   with target.open('xb') as output: output.write(archive.extractfile(member).read())
source_root=root/'source/docs/research/aris-frequency-window-20261010'
assert hashlib.sha256((source_root/'frequency_workload.c').read_bytes()).hexdigest()=='ead1029864025047ca0df2bf1d7bea179040f151313589389c043e3a7b9ef68a'
for name in ('tmp','cache'): (root/name).mkdir(mode=0o700)
environment=os.environ.copy()
environment.update({'TMPDIR':str(root/'tmp'),'TMP':str(root/'tmp'),'TEMP':str(root/'tmp'),'XDG_CACHE_HOME':str(root/'cache'),'CCACHE_DIR':str(root/'cache'),'PYTHONDONTWRITEBYTECODE':'1','LC_ALL':'C'})
results=[]
for config,sanitizers in (('normal','OFF'),('sanitize','ON')):
 build=root/('build-'+config)
 steps=[('configure',['/usr/bin/cmake','-S',str(source_root),'-B',str(build),'-DCMAKE_C_COMPILER=/usr/bin/gcc','-DCMAKE_BUILD_TYPE=RelWithDebInfo','-DBUILD_TESTING=ON','-DFREQUENCY_WINDOW_SANITIZERS='+sanitizers]),('build',['/usr/bin/cmake','--build',str(build),'--parallel','2']),('test',['/usr/bin/ctest','--test-dir',str(build),'--output-on-failure'])]
 for step,arguments in steps:
  label=config+'-'+step
  started=time.monotonic()
  with (root/(label+'.log')).open('xb') as output:
   process=subprocess.Popen(arguments,cwd=root,env=environment,stdout=output,stderr=subprocess.STDOUT)
   record={'label':label,'arguments':arguments,'pid':process.pid}
   try: record['start_ticks']=Path(f'/proc/{process.pid}/stat').read_text().rpartition(')')[2].split()[19]
   except (OSError,IndexError) as error: record['identity_error']=type(error).__name__
   try: record['exit_code']=process.wait(timeout=60)
   except subprocess.TimeoutExpired:
    record.update({'observation_timeout':True,'process_exit_unconfirmed':True})
    with (root/(label+'-timeout.json')).open('x') as state: json.dump(record,state,indent=2)
    print(json.dumps(record),flush=True)
    raise
  record['wall_seconds']=time.monotonic()-started
  with (root/(label+'-result.json')).open('x') as state: json.dump(record,state,indent=2)
  results.append(record)
  print(json.dumps(record),flush=True)
  if record['exit_code']!=0: raise SystemExit(1)
artifacts={}
for config in ('normal','sanitize'):
 for filename in ('frequency_workload','frequency_reference_kat'):
  relative='build-'+config+'/'+filename
  binary=root/relative
  artifacts[relative]={'sha256':hashlib.sha256(binary.read_bytes()).hexdigest(),'bytes':binary.stat().st_size}
with (root/'artifact-digests.json').open('x') as output: json.dump(artifacts,output,indent=2)
with (root/'run.json').open('x') as output: json.dump({'utc':datetime.datetime.now(datetime.timezone.utc).isoformat(),'uname':list(os.uname()),'source_commit':'7e93048f3af885d14f1577b3a198bd3d52b8ee8e','steps':results,'ordinary_entry_run':False,'msr_read_performed':False,'configuration_writes':0,'temporary_environment':{name:environment[name] for name in ('TMPDIR','TMP','TEMP','XDG_CACHE_HOME','CCACHE_DIR','PYTHONDONTWRITEBYTECODE')}},output,indent=2)
paths=sorted(p for p in root.rglob('*') if p.is_file())
assert not any(p.is_symlink() for p in root.rglob('*'))
tree_bytes=sum(p.stat().st_size for p in paths)
assert tree_bytes<64*1024*1024
manifest={str(p.relative_to(root)):{'sha256':hashlib.sha256(p.read_bytes()).hexdigest(),'bytes':p.stat().st_size} for p in paths}
with (root/'export-manifest.json').open('x') as output: json.dump(manifest,output,indent=2)
paths.append(root/'export-manifest.json')
archive_name='window-source-7e93048-software.tar'
descriptor=os.open(project/archive_name,os.O_RDWR|os.O_CREAT|os.O_EXCL|os.O_NOFOLLOW,0o600)
with os.fdopen(descriptor,'w+b') as output:
 with tarfile.open(fileobj=output,mode='w') as saved:
  for path in paths:
   content=path.read_bytes()
   member=tarfile.TarInfo(root.name+'/'+str(path.relative_to(root)))
   member.mode=0o600
   member.size=len(content)
   saved.addfile(member,io.BytesIO(content))
 output.flush()
 output.seek(0)
 digest=hashlib.file_digest(output,'sha256').hexdigest()
print(json.dumps({'status':'linux_software_passed','archive':str(project/archive_name),'sha256':digest,'members':len(paths),'tree_bytes':tree_bytes,'artifacts':artifacts,'ordinary_entry_run':False,'msr_read_performed':False,'configuration_writes':0}),flush=True)
