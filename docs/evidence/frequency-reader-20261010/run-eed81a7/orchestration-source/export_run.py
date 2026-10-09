from pathlib import Path
import datetime,hashlib,io,json,os,tarfile
project=Path('/home/nss-marker/yhr/Cry')
root=project/'feedback-reader-eed81a7'
assert Path.cwd()==project and root.resolve()==root and os.geteuid()!=0
counter=project/'feedback-counter-20261010-16ec7cf0d5fb.tar'
data=counter.read_bytes()
assert hashlib.sha256(data).hexdigest()=='3457b6f8c729eac6209316f08f353486d5027eb17bc33489af84a8dc9ac2a601'
with (root/counter.name).open('xb') as output: output.write(data)
fields=('scaling_governor','scaling_min_freq','scaling_max_freq','energy_performance_preference','boost')
cpu_root=Path('/sys/devices/system/cpu')
policies={str(cpu):{name:(cpu_root/f'cpufreq/policy{cpu}'/name).read_text().strip() for name in fields} for cpu in (2,18)}
state={'utc':datetime.datetime.now(datetime.timezone.utc).isoformat(),'policies':policies,'amd_pstate_status':(cpu_root/'amd_pstate/status').read_text().strip(),'global_boost':(cpu_root/'cpufreq/boost').read_text().strip(),'cpuset_root':{name:(Path('/sys/fs/cgroup')/name).read_text().strip() for name in ('cpuset.cpus.effective','cpuset.cpus.isolated')}}
with (root/'final-visible-state.json').open('x') as output: json.dump(state,output,indent=2)
artifacts={name:{'sha256':hashlib.sha256((root/name).read_bytes()).hexdigest(),'bytes':(root/name).stat().st_size} for name in ('tools/iasl','tools/copyright','build-normal/msr_counter_snapshot','build-sanitize/msr_counter_snapshot')}
with (root/'artifact-digests.json').open('x') as output: json.dump(artifacts,output,indent=2)
paths=sorted(p for p in root.rglob('*') if p.is_file())
assert not any(p.is_symlink() for p in root.rglob('*'))
total=sum(p.stat().st_size for p in paths)
assert total<30*1024*1024
manifest={str(p.relative_to(root)):{'sha256':hashlib.sha256(p.read_bytes()).hexdigest(),'bytes':p.stat().st_size} for p in paths}
with (root/'export-manifest.json').open('x') as output: json.dump(manifest,output,indent=2)
paths.append(root/'export-manifest.json')
archive_name='feedback-reader-eed81a7-results.tar'
descriptor=os.open(project/archive_name,os.O_RDWR|os.O_CREAT|os.O_EXCL|os.O_NOFOLLOW,0o600)
with os.fdopen(descriptor,'w+b') as output:
 with tarfile.open(fileobj=output,mode='w') as archive:
  for path in paths:
   content=path.read_bytes()
   member=tarfile.TarInfo(root.name+'/'+str(path.relative_to(root)))
   member.mode=0o600
   member.size=len(content)
   archive.addfile(member,io.BytesIO(content))
 output.flush()
 output.seek(0)
 digest=hashlib.file_digest(output,'sha256').hexdigest()
print(json.dumps({'archive':str(project/archive_name),'sha256':digest,'members':len(paths),'tree_payload_bytes':total,'links':0,'visible_state':state,'artifacts':artifacts},indent=2))
