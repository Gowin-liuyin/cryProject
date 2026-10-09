from pathlib import Path
import datetime,hashlib,json,os,shutil,subprocess,time
root=Path('/home/nss-marker/yhr/Cry/feedback-reader-eed81a7')
assert os.geteuid()!=0 and root.resolve(strict=True)==root
iasl=root/'tools/iasl'
assert hashlib.sha256(iasl.read_bytes()).hexdigest()=='07f0c8166ff1a65f3d11484fc7597dd6f24a22befe77f1bde81d871367a08327'
metadata=json.loads((root/'decode/metadata.json').read_text())
destination=root/'decode-s01'
destination.mkdir(mode=0o700)
for name,record in metadata['tables'].items():
 data=(root/'decode'/name).read_bytes()
 assert hashlib.sha256(data).hexdigest()==record['sha256']
 with (destination/name).open('xb') as output: output.write(data)
inputs=sorted(p for p in destination.glob('*.dat') if p.name!='SSDT3.dat')
assert len(inputs)==13
arguments=[str(iasl),'-e',*[str(p) for p in inputs],'-d',str(destination/'SSDT3.dat')]
environment=os.environ.copy()
environment.update(json.loads((root/'environment.json').read_text()))
record={'label':'s01-fresh-target','arguments':arguments,'started_utc':datetime.datetime.now(datetime.timezone.utc).isoformat(),'input_sha256':{name:rec['sha256'] for name,rec in metadata['tables'].items()},'aml_evaluation_performed':False,'configuration_writes':0}
started=time.monotonic()
with (destination/'iasl.log').open('xb') as output:
 process=subprocess.Popen(arguments,cwd=destination,env=environment,stdout=output,stderr=subprocess.STDOUT)
 record.update({'pid':process.pid,'start_ticks':Path(f'/proc/{process.pid}/stat').read_text().rpartition(')')[2].split()[19]})
 with (destination/'started.json').open('x') as result: json.dump(record,result,indent=2)
 try: returncode=process.wait(timeout=60)
 except subprocess.TimeoutExpired:
  record.update({'observation_timeout':True,'process_exit_unconfirmed':True})
  with (destination/'timeout.json').open('x') as result: json.dump(record,result,indent=2)
  print(json.dumps(record),flush=True)
  raise
record.update({'exit_code':returncode,'wall_seconds':time.monotonic()-started})
dsl=destination/'SSDT3.dsl'
if dsl.exists(): record['dsl']={'bytes':dsl.stat().st_size,'sha256':hashlib.sha256(dsl.read_bytes()).hexdigest()}
with (destination/'result.json').open('x') as result: json.dump(record,result,indent=2)
print(json.dumps(record,indent=2))
if returncode!=0: raise SystemExit(1)
