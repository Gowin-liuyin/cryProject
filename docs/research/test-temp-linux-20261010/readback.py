from pathlib import Path
import hashlib,json,os,platform,subprocess
root=Path('/home/nss-marker/yhr/Cry/temp-check-1faf87d')
cry=Path('/home/nss-marker/yhr/Cry')
assert root.resolve(strict=True).is_relative_to(cry)
def sha(p):
 return hashlib.sha256(p.read_bytes()).hexdigest()
result={'source_commit':'1faf87d87ecec7650cb64fac94228fdfbf3268d2','archive_sha256':sha(root/'source.tar'),'run_script_sha256':sha(root/'run.sh'),'machine':platform.uname()._asdict(),'cpu_count':os.cpu_count(),'root_realpath':str(root.resolve()),'builds':{},'source_files':{}}
for p in sorted((root/'source').rglob('*')):
 assert not p.is_symlink(),str(p)
 assert p.resolve().is_relative_to(root),str(p)
 if p.is_file(): result['source_files'][str(p.relative_to(root/'source'))]=sha(p)
for name in ('build-gcc','build-gcc-san'):
 b=root/name
 for p in (b,b/'test-tmp',root/'source',root/'compiler-tmp',root/'logs'):
  assert p.resolve(strict=True).is_relative_to(root),str(p)
 binary=b/'test_temp_directory'
 compilation=json.loads((b/'compile_commands.json').read_text())
 selected=[x for x in compilation if x['file'].endswith('/tests/test_temp_directory.c')]
 assert len(selected)==1
 registry=json.loads((root/'logs'/f'{name}-registry.json').read_text())
 assert [x['name'] for x in registry['tests']]==['temp_directory']
 environments=[x['value'] for x in registry['tests'][0]['properties'] if x['name']=='ENVIRONMENT'][0]
 assert set(environments)==set(f'{v}={b}/test-tmp' for v in ('A113_TEST_TMPDIR','TMPDIR','TMP','TEMP'))
 assert binary.read_bytes()[:4]==b'\x7fELF'
 assert not list(b.rglob('libmlkem.a'))
 assert not list(b.rglob('patched.stamp'))
 assert not list((b/'test-tmp').iterdir())
 result['builds'][name]={'binary_sha256':sha(binary),'binary_magic_hex':binary.read_bytes()[:20].hex(),'compile_command':selected[0],'link_command':(b/'CMakeFiles/test_temp_directory.dir/link.txt').read_text(),'test_names':['temp_directory'],'environment':environments,'test_tmp_remaining':[],'mlkem_archives':[],'patch_stamps':[]}
result['compiler_tmp_remaining']=[p.name for p in (root/'compiler-tmp').iterdir()]
assert not result['compiler_tmp_remaining']
result['symlinks_in_run']=[str(p.relative_to(root)) for p in root.rglob('*') if p.is_symlink()]
assert not result['symlinks_in_run']
(root/'readback.json').write_text(json.dumps(result,indent=2)+'\n')
print(json.dumps({'source_file_count':len(result['source_files']),'builds':{k:v['binary_sha256'] for k,v in result['builds'].items()},'compiler_tmp_remaining':result['compiler_tmp_remaining']}))
