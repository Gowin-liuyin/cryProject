import datetime,json,os,pathlib,stat,subprocess
cry=pathlib.Path('/home/nss-marker/yhr/Cry')
assert cry.resolve(strict=True)==cry
root=pathlib.Path('/sys/fs/cgroup')
fields=('cgroup.controllers','cgroup.subtree_control','cpuset.cpus','cpuset.cpus.effective','cpuset.cpus.exclusive','cpuset.cpus.exclusive.effective','cpuset.cpus.partition','cpuset.mems','cpuset.mems.effective')
def inspect(group):
 result={}
 for name in fields:
  path=group/name
  try:
   metadata=path.stat()
   result[name]={'value':path.read_text().strip(),'owner_uid':metadata.st_uid,'mode':oct(stat.S_IMODE(metadata.st_mode)),'caller_writable':os.access(path,os.W_OK)}
  except FileNotFoundError:
   result[name]={'missing':True}
  except OSError as error:
   result[name]={'error':str(error)}
 return result
result={'utc':datetime.datetime.now(datetime.timezone.utc).isoformat(),'uname':list(os.uname()),'effective_uid':os.geteuid(),'cry_realpath':str(cry.resolve()),'configuration_writes':0,'project_file_writes':0,'groups':{name:inspect(root/name) for name in ('','init.scope','system.slice','user.slice')},'current_cgroup':pathlib.Path('/proc/self/cgroup').read_text().splitlines(),'units':{}}
for unit in ('init.scope','system.slice','user.slice'):
 command=['systemctl','show',unit,'--no-pager','-p','Delegate','-p','DelegateControllers','-p','ControlGroup','-p','AllowedCPUs','-p','StartupAllowedCPUs','-p','AllowedMemoryNodes']
 process=subprocess.run(command,capture_output=True,text=True,timeout=5)
 result['units'][unit]={'exit_code':process.returncode,'stdout':process.stdout,'stderr':process.stderr}
result['top_level_group_count']=sum(path.is_dir() for path in root.iterdir())
result['cpu_online']=pathlib.Path('/sys/devices/system/cpu/online').read_text().strip()
result['reserved_candidate_siblings']={str(cpu):pathlib.Path(f'/sys/devices/system/cpu/cpu{cpu}/topology/thread_siblings_list').read_text().strip() for cpu in (2,18)}
print(json.dumps(result,indent=2))
