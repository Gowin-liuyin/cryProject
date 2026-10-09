import datetime,json,os,shutil,stat
from pathlib import Path
root=Path('/home/nss-marker/yhr/Cry')
assert root.resolve()==root and Path.cwd()==root
tables=Path('/sys/firmware/acpi/tables')
entries=[]
for path in sorted(tables.iterdir()):
 metadata=path.stat()
 entries.append({'name':path.name,'is_regular':stat.S_ISREG(metadata.st_mode),'size_bytes':metadata.st_size,'mode':oct(stat.S_IMODE(metadata.st_mode))})
print(json.dumps({'utc':datetime.datetime.now(datetime.timezone.utc).isoformat(),'uname':list(os.uname()),'effective_uid':os.geteuid(),'working_directory':str(Path.cwd()),'cpu_online':Path('/sys/devices/system/cpu/online').read_text().strip(),'affinity':sorted(os.sched_getaffinity(0)),'tools':{name:shutil.which(name) for name in ('iasl','acpidump','gcc','clang','cmake','ninja','dpkg-deb','curl','bison','flex')},'acpi_tables':entries,'project_file_writes':0,'configuration_writes':0},indent=2))
