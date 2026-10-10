import hashlib
import io
import json
import os
from pathlib import Path, PurePosixPath
import re
import sys
import tarfile

BASE = Path('/home/nss-marker/yhr/Cry')
MODULE = 'docs/research/aris-ordinary-repeatability-20261010/'
MANIFEST_NAME = MODULE + 'SOURCE_MANIFEST.json'
RUNNER_NAME = MODULE + 'remote_run.py'
MANIFEST_SHA256 = 'c95d924d31e0c085724f89a97c5808c7706bcae22ec1bd683c5b45b8495f6552'
MAX_UPLOAD_BYTES = 8 * 1024 * 1024
if len(sys.argv) != 4:
    raise ValueError('ROOT ARCHIVE_SHA256 RUNNER_SHA256 required')
root = Path(sys.argv[1])
if not re.fullmatch(str(BASE) + r'/reference-repeatability-[0-9a-f]{7,40}-[0-9a-f]{8,32}', str(root)):
    raise ValueError('invalid project root')
if any(not re.fullmatch(r'[0-9a-f]{64}', value) for value in sys.argv[2:]):
    raise ValueError('invalid digest')
for ancestor in (BASE, *BASE.parents):
    if ancestor.is_symlink() or ancestor.resolve(strict=True) != ancestor:
        raise ValueError('nonphysical project ancestor')
upload = Path(str(root) + '.upload.tar')
if root.exists() or root.is_symlink() or upload.exists() or upload.is_symlink():
    raise ValueError('exclusive upload/root already exists')
blob = sys.stdin.buffer.read(MAX_UPLOAD_BYTES + 1)
if len(blob) > MAX_UPLOAD_BYTES or hashlib.sha256(blob).hexdigest() != sys.argv[2]:
    raise ValueError('source archive length or digest mismatch')
payload = {}
with tarfile.open(fileobj=io.BytesIO(blob), mode='r:') as archive:
    members = archive.getmembers()
    if len(members) != 142 or len({member.name for member in members}) != 142:
        raise ValueError('expected 142 unique regular source members')
    for member in members:
        name = PurePosixPath(member.name)
        if not member.isfile() or name.is_absolute() or '..' in name.parts or str(name) != member.name or not 0 < member.size <= MAX_UPLOAD_BYTES:
            raise ValueError('unsafe source member')
        content = archive.extractfile(member).read()
        if len(content) != member.size:
            raise ValueError('short source member')
        payload[member.name] = content
if hashlib.sha256(payload[MANIFEST_NAME]).hexdigest() != MANIFEST_SHA256:
    raise ValueError('fixed manifest mismatch')
manifest = json.loads(payload[MANIFEST_NAME])
if manifest.get('schema') != 'reference-repeatability-source-manifest-v1' or len(manifest['files']) != 140:
    raise ValueError('fixed manifest schema mismatch')
expected = {record['path']: record for record in manifest['files']}
if len(expected) != 140 or set(payload) != set(expected) | {MANIFEST_NAME, RUNNER_NAME}:
    raise ValueError('source coverage mismatch')
for name, record in expected.items():
    if len(payload[name]) != record['bytes'] or hashlib.sha256(payload[name]).hexdigest() != record['sha256']:
        raise ValueError('fixed source bytes mismatch: ' + name)
if hashlib.sha256(payload[RUNNER_NAME]).hexdigest() != sys.argv[3]:
    raise ValueError('runner digest mismatch')
os.umask(0o077)
with upload.open('xb') as output_file:
    if output_file.write(blob) != len(blob):
        raise OSError('short upload write')
root.mkdir(mode=0o700)
source = root / 'source'
source.mkdir(mode=0o700)
for name, content in payload.items():
    path = source / name
    path.parent.mkdir(mode=0o700, parents=True, exist_ok=True)
    with path.open('xb') as output_file:
        if output_file.write(content) != len(content):
            raise OSError('short source write')
    if path.is_symlink() or path.resolve(strict=True) != path or hashlib.sha256(path.read_bytes()).hexdigest() != hashlib.sha256(content).hexdigest():
        raise ValueError('staged source mismatch')
if hashlib.sha256(upload.read_bytes()).hexdigest() != sys.argv[2]:
    raise ValueError('saved carrier mismatch')
print(json.dumps({'status': 'source_staged', 'root': str(root), 'upload': str(upload),
                  'source_files': len(payload), 'upload_sha256': sys.argv[2],
                  'manifest_sha256': MANIFEST_SHA256, 'runner_sha256': sys.argv[3],
                  'project_paths_physical_under_Cry': True}, separators=(',', ':')))
