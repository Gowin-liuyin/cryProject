#!/usr/bin/env python3
import hashlib
import json
import pathlib
import shutil
import subprocess
import sys

work = pathlib.Path(sys.argv[1])
dest = work/'out'/'env'/'build-evidence'
dest.mkdir(parents=True, exist_ok=True)
records = []
for path in sorted((work/'build').rglob('*')):
    if not path.is_file():
        continue
    relative = path.relative_to(work/'build')
    if path.name in {'CMakeCache.txt','compile_commands.json','configuration.txt','flags.make'}:
        # Skip transient compiler probes and fetched vendor sub-builds; retain top-level and target flags.
        if 'TryCompile' in str(relative) or 'CMakeScratch' in str(relative):
            continue
        target = dest/'configuration'/relative
        target.parent.mkdir(parents=True, exist_ok=True)
        shutil.copy2(path, target)
    if (path.name == 'measure' or path.name.startswith(('poison-','hdudect-','perf-','platform_m4_measure_','platform_m4_dudect_'))
            or path.name in {'platform_stats','platform_m5_dudect'}):
        data = path.read_bytes()
        if data.startswith(b'\x7fELF'):
            records.append({'path':str(path.relative_to(work)), 'bytes':len(data), 'sha256':hashlib.sha256(data).hexdigest(),'sha3_256':hashlib.sha3_256(data).hexdigest()})
(dest/'binary-digests.json').write_text(json.dumps(records,indent=2)+'\n')
for name, args in {
    'git-head.txt':['git','-C',str(work/'repo'),'rev-parse','HEAD'],
    'git-status.txt':['git','-C',str(work/'repo'),'status','--short'],
    'tracked-source-diff.txt':['git','-C',str(work/'repo'),'diff','HEAD','--'],
    'compiler.txt':['clang-18','--version'],
    'dependency-versions.txt':['dpkg-query','-W','clang-18','llvm-18','cmake','make','git','valgrind','openssl','libssl-dev','python3','binutils'],
}.items():
    result = subprocess.run(args, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True)
    (dest/name).write_text(result.stdout)
print(f'Build evidence saved; {len(records)} ELF digests.')
