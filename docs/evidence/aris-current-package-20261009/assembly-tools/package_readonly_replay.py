from pathlib import Path
import hashlib, json, subprocess, zipfile
root=Path('/Users/yin/code/cryProject')
work=root/'build/aris-current-package-20261009'
payload=work/'payload'
replay=work/'package-readonly-replay'
replay.mkdir()
source=replay/'source'; source.mkdir()
with zipfile.ZipFile(payload/'software/CACR2026EA16XZ-数学源码与账本复核件.zip') as archive:
 assert archive.testzip() is None
 archive.extractall(source)
logs=[]
def run(name,args,cwd=root):
 proc=subprocess.run(args,cwd=cwd,text=True,capture_output=True)
 (replay/(name+'.stdout.log')).write_text(proc.stdout)
 (replay/(name+'.stderr.log')).write_text(proc.stderr)
 logs.append({'name':name,'arguments':args,'returncode':proc.returncode})
 if proc.returncode: raise RuntimeError(name+': '+proc.stderr)
 return proc
run('source-digests',['shasum','-a','256','-c','SHA256SUMS'],source)
run('audit-configure',['cmake','-S',str(source/'audit'),'-B',str(replay/'audit'),'-DBUILD_TESTING=OFF'])
run('audit-build',['cmake','--build',str(replay/'audit'),'--parallel','2'])
run('summary-configure',['cmake','-S',str(payload/'data/M02_REPLICATION/preparation/summary-source'),'-B',str(replay/'summary'),'-DBUILD_TESTING=OFF','-DSUMMARY_SANITIZERS=OFF'])
run('summary-build',['cmake','--build',str(replay/'summary'),'--parallel','2'])
(replay/'views').mkdir();(replay/'outputs').mkdir()
results=[]
for number in [1,2,3]:
 view=replay/'views'/('process-'+str(number));view.mkdir()
 (view/'run').symlink_to(payload/'data/M02_REPLICATION'/('run-'+str(number)),target_is_directory=True)
 result_path=replay/'outputs'/('process-'+str(number)+'.json')
 run('audit-process-'+str(number),[str(replay/'audit/update_cost_result_review'),str(view),str(payload/'data/M02_REPLICATION/preparation/fixed-inputs'),str(result_path)])
 expected=payload/'data/M02_REPLICATION/independent-audits'/('process-'+str(number)+'.json')
 identical=result_path.read_bytes()==expected.read_bytes()
 assert identical
 results.append({'process':number,'C_audit_returncode':0,'output_byte_identical_to_original_C_audit':identical,'sha256':hashlib.sha256(result_path.read_bytes()).hexdigest()})
summary_path=replay/'outputs/process-summary.json'
run('summary-existing-records',[str(replay/'summary/process_summary'),str(payload/'data/M02_REPLICATION'),str(summary_path)])
assert summary_path.read_bytes()==(payload/'data/M02_REPLICATION/process-summary.json').read_bytes()
verification={'package_readonly_C_replay_passed':True,'per_process_audits':results,'summary_byte_identical_to_original':True,'new_formal_runs':0,'statistics_enumeration_reexecuted':False,'new_cryptographic_calls':0,'build_role':'readonly_audit_and_summary_tools_not_original_timing_artifact','commands':logs}
(root/'docs/evidence/aris-current-package-20261009/package-readonly-replay.json').write_text(json.dumps(verification,ensure_ascii=False,indent=2)+'\n')
print(json.dumps({k:v for k,v in verification.items() if k!='commands'},ensure_ascii=False))
