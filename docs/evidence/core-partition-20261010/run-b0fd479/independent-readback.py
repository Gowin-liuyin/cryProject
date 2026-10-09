from pathlib import Path
import json,hashlib,os,select,fcntl,stat,datetime
run=Path('/home/nss-marker/yhr/Cry/core-partition-20261010-44fee52e576a')
assert run.resolve()==run and run.stat().st_uid==0
manifest={}
for path in sorted(run.rglob('*')):
 assert not path.is_symlink()
 if path.is_file():
  metadata=path.stat()
  manifest[str(path.relative_to(run))]={'sha256':hashlib.sha256(path.read_bytes()).hexdigest(),'uid':metadata.st_uid,'mode':oct(stat.S_IMODE(metadata.st_mode))}
processes={}
for mode in ('normal','parent-loss'):
 for role in ('guard','controller'):
  identity=json.loads((run/mode/f'{role}.json').read_text())
  try:
   fd=os.pidfd_open(identity['pid'])
  except ProcessLookupError:
   state='absent'
  else:
   ended=bool(select.select([fd],[],[],0)[0])
   ticks=int(Path(f"/proc/{identity['pid']}/stat").read_text().rsplit(')',1)[1].split()[19])
   state='exited' if ended else ('pid_reused' if ticks!=identity['start_ticks'] else 'live_original')
   os.close(fd)
  processes[mode+'/'+role]=state
  assert state!='live_original'
root=Path('/sys/fs/cgroup')
owned=[path.name for path in root.iterdir() if path.is_dir() and path.name.startswith('a113part-')]
assert not owned
assert (root/'cpuset.cpus.effective').read_text().strip()=='0-31'
assert not (root/'cpuset.cpus.isolated').read_text().strip()
lock=os.open('/home/nss-marker/yhr/Cry/partition-admin.lock',os.O_RDONLY|os.O_NOFOLLOW)
fcntl.flock(lock,fcntl.LOCK_EX|fcntl.LOCK_NB)
os.close(lock)
print(json.dumps({'utc':datetime.datetime.now(datetime.timezone.utc).isoformat(),'effective_uid':os.geteuid(),'root_effective':'0-31','root_isolated':'','owned_groups':owned,'lock_available':True,'processes':processes,'original_files':manifest,'configuration_writes':0},indent=2))
