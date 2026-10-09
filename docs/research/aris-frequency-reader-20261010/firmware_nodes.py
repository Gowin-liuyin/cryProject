from pathlib import Path
import datetime,hashlib,json,os,re,stat
root=Path('/home/nss-marker/yhr/Cry')
assert Path.cwd()==root and root.resolve()==root
result={'utc':datetime.datetime.now(datetime.timezone.utc).isoformat(),'effective_uid':os.geteuid(),'firmware_nodes':{},'configuration_writes':0,'project_file_writes':0}
for cpu_index in (2,18):
 link=Path('/sys/devices/system/cpu')/f'cpu{cpu_index}'/'firmware_node'
 values={'realpath':str(link.resolve())}
 for name in ('path','uid','hid'):
  try: values[name]={'value':(link/name).read_text().strip()}
  except OSError as error: values[name]={'errno':error.errno,'error_type':type(error).__name__}
 result['firmware_nodes'][str(cpu_index)]=values
print(json.dumps(result,indent=2))
