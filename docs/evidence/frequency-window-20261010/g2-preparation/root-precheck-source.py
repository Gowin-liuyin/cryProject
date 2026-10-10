import os,json,stat,shutil
from pathlib import Path
root=Path('/home/nss-marker/yhr/Cry')
assert Path.cwd()==root and root.resolve()==root and os.geteuid()==0
status={}
for line in Path('/proc/self/status').read_text().splitlines():
 if ':' in line:
  k,v=line.split(':',1); status[k]=v.strip()
caps=int(status['CapEff'],16)
namespaces={k:{'self':os.readlink('/proc/self/ns/'+k),'init':os.readlink('/proc/1/ns/'+k)} for k in ('user','mnt','pid')}
assert all(x['self']==x['init'] for x in namespaces.values())
assert caps & (1<<19)
devices={}
for cpu in (2,18):
 p=Path('/dev/cpu/'+str(cpu)+'/msr'); m=p.stat(follow_symlinks=False)
 assert stat.S_ISCHR(m.st_mode) and m.st_uid==0 and os.major(m.st_rdev)==202 and os.minor(m.st_rdev)==cpu
 devices[str(cpu)]={'inode':m.st_ino,'device':m.st_dev,'owner_uid':m.st_uid,'mode':stat.S_IMODE(m.st_mode),'major':os.major(m.st_rdev),'minor':os.minor(m.st_rdev)}
disk=shutil.disk_usage(root)
assert disk.free>=2*1024**3
print(json.dumps({'effective_uid':os.geteuid(),'cap_eff':status['CapEff'],'cap_sys_ptrace':True,'namespaces':namespaces,'devices':devices,'disk_free_bytes':disk.free,'root_cpus':Path('/sys/fs/cgroup/cpuset.cpus.effective').read_text().strip(),'isolated':Path('/sys/fs/cgroup/cpuset.cpus.isolated').read_text().strip(),'configuration_writes':0,'msr_read_performed':False}))
