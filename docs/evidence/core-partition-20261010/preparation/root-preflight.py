import json,os,pathlib,datetime
assert os.geteuid()==0
root=pathlib.Path('/sys/fs/cgroup')
rows=[]; errors=[]
for path in sorted(root.rglob('cpuset.cpus.partition')):
 try:
  group=path.parent
  rows.append({'path':str(group.relative_to(root)),'partition':path.read_text().strip(),'cpus':(group/'cpuset.cpus').read_text().strip(),'exclusive':(group/'cpuset.cpus.exclusive').read_text().strip()})
 except OSError as error: errors.append(str(error))
namespaces={name:{'self':os.readlink('/proc/self/ns/'+name),'init':os.readlink('/proc/1/ns/'+name)} for name in ('pid','cgroup','mnt')}
print(json.dumps({'utc':datetime.datetime.now(datetime.timezone.utc).isoformat(),'effective_uid':os.geteuid(),'namespaces':namespaces,'root_controllers':(root/'cgroup.subtree_control').read_text().strip(),'root_effective':(root/'cpuset.cpus.effective').read_text().strip(),'root_isolated':(root/'cpuset.cpus.isolated').read_text().strip(),'cpuset_group_count':len(rows),'nondefault_groups':[r for r in rows if r['partition']!='member' or r['cpus'] or r['exclusive']],'read_errors':errors,'configuration_writes':0},indent=2))
