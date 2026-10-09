from pathlib import Path
import datetime,json,os,shutil,stat
root=Path('/home/nss-marker/yhr/Cry')
assert Path.cwd()==root and root.resolve(strict=True)==root
cpu_root=Path('/sys/devices/system/cpu')
fields=('affected_cpus','related_cpus','scaling_driver','scaling_governor','scaling_min_freq','scaling_max_freq','energy_performance_preference','boost')
policies={}
for directory in sorted((cpu_root/'cpufreq').glob('policy*')):
 metadata=directory.stat()
 policies[directory.name]={'realpath':str(directory.resolve()),'owner_uid':metadata.st_uid,'device':metadata.st_dev,'inode':metadata.st_ino,'controls':{name:(directory/name).read_text().strip() for name in fields}}
result={'utc':datetime.datetime.now(datetime.timezone.utc).isoformat(),'uname':list(os.uname()),'effective_uid':os.geteuid(),'working_directory':str(Path.cwd()),'cpu_online':(cpu_root/'online').read_text().strip(),'siblings':{str(cpu):(cpu_root/f'cpu{cpu}/topology/thread_siblings_list').read_text().strip() for cpu in (2,18)},'policies':policies,'global':{name:(cpu_root/name).read_text().strip() for name in ('amd_pstate/status','amd_pstate/prefcore','cpufreq/boost')},'cpuset_root':{name:(Path('/sys/fs/cgroup')/name).read_text().strip() for name in ('cpuset.cpus.effective','cpuset.cpus.isolated')},'tools':{name:shutil.which(name) for name in ('python3','cmake','gcc','clang')},'configuration_writes':0,'project_file_writes':0}
print(json.dumps(result,indent=2))
