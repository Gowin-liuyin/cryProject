import datetime
import hashlib
import json
import os
from pathlib import Path
import re
import shutil
import stat
import sys
import tempfile

WORK_ROOT = Path('/home/nss-marker/yhr/Cry')
SOURCE_NAMES = [
    'a113-performance-fixture.Ube0YZ', 'a113-performance-fixture.mM6kr1',
    'a113-performance-fixture.ry6crJ', 'cry-paired-data.4gbEam',
    'cry-paired-data.Kz5gk8', 'cry-paired-data.L1exDu',
    'cry-paired-prepare.WhKuQq', 'cry-paired-prepare.a4LK82',
    'cry-paired-prepare.e5zI5J', 'cry-paired-rejections.9WLIJt',
    'cry-paired-rejections.bhoJwL', 'cry-paired-rejections.nUa7nL',
    'cry-paired-runner.APN4Ql', 'cry-paired-runner.OxDtPJ', 'cry-paired-runner.WGetqP',
]


def file_digest(path):
    digest = hashlib.sha256()
    with path.open('rb') as stream:
        for chunk in iter(lambda: stream.read(1024 * 1024), b''):
            digest.update(chunk)
    return digest.hexdigest()


def snapshot(root, expected_uid=1000):
    if root.is_symlink() or root.resolve() != root or not root.is_dir():
        raise RuntimeError('Source must be a real directory')
    entries = {}
    identities = {}
    device = root.stat().st_dev
    for path in [root] + sorted(root.rglob('*')):
        metadata = path.lstat()
        if metadata.st_uid != expected_uid or metadata.st_dev != device:
            raise RuntimeError('Ownership or filesystem boundary differs')
        relative = str(path.relative_to(root))
        entry = {'uid': metadata.st_uid, 'gid': metadata.st_gid,
                 'mode': stat.S_IMODE(metadata.st_mode), 'mtime_ns': metadata.st_mtime_ns}
        if stat.S_ISDIR(metadata.st_mode):
            entry['kind'] = 'directory'
        elif stat.S_ISREG(metadata.st_mode):
            entry.update(kind='file', bytes=metadata.st_size, sha256=file_digest(path))
        elif stat.S_ISLNK(metadata.st_mode):
            real_target = path.resolve(strict=True)
            if not real_target.is_relative_to(WORK_ROOT.resolve()):
                raise RuntimeError('Symlink target is outside the approved project directory')
            entry.update(kind='symlink', link_target=os.readlink(path), real_target=str(real_target))
        else:
            raise RuntimeError('Special file requires separate review')
        entries[relative] = entry
        identities[relative] = [metadata.st_dev, metadata.st_ino]
    return {'entries': entries, 'identities': identities}


def active_references(sources):
    references = []
    errors = []
    process_count = 0
    thread_count = 0

    def record(pid, tid, kind, value):
        if any(value == str(source) or value.startswith(str(source) + '/') for source in sources):
            references.append({'pid': pid, 'tid': tid, 'kind': kind, 'path': value})

    for process in Path('/proc').iterdir():
        if not process.name.isdigit():
            continue
        try:
            process_count += 1
            tasks = list((process / 'task').iterdir())
            try:
                record(int(process.name), None, 'exe', os.readlink(process / 'exe'))
            except FileNotFoundError:
                pass
            with (process / 'maps').open(errors='replace') as stream:
                for line in stream:
                    fields = line.split(None, 5)
                    if len(fields) == 6:
                        record(int(process.name), None, 'mapping', fields[5].strip())
            for task in tasks:
                try:
                    record(int(process.name), int(task.name), 'cwd', os.readlink(task / 'cwd'))
                    for descriptor in (task / 'fd').iterdir():
                        try:
                            record(int(process.name), int(task.name), 'fd', os.readlink(descriptor))
                        except FileNotFoundError:
                            pass
                    thread_count += 1
                except (FileNotFoundError, ProcessLookupError):
                    pass
                except OSError as error:
                    errors.append({'pid': int(process.name), 'tid': int(task.name), 'errno': error.errno})
        except (FileNotFoundError, ProcessLookupError):
            pass
        except OSError as error:
            errors.append({'pid': int(process.name), 'errno': error.errno})
    return {'references': references, 'read_errors': errors,
            'processes_checked': process_count, 'threads_checked': thread_count}


def save_receipt(path, value):
    temporary = path.with_suffix('.new')
    with temporary.open('w') as stream:
        json.dump(value, stream, indent=2)
        stream.write('\n')
        stream.flush()
        os.fsync(stream.fileno())
    temporary.replace(path)
    os.chown(path, 1000, 1000)


def migrate(source_sha256):
    if os.geteuid() != 0 or WORK_ROOT.resolve() != WORK_ROOT:
        raise RuntimeError('Requires root and the exact approved real directory')
    if not re.fullmatch('[0-9a-f]{64}', source_sha256):
        raise RuntimeError('Missing administration source identity')
    sources = [Path('/tmp') / name for name in SOURCE_NAMES]
    mountpoints = []
    for line in Path('/proc/self/mountinfo').read_text().splitlines():
        value = line.split()[4]
        for escaped, decoded in [(r'\040', ' '), (r'\011', '\t'), (r'\012', '\n'), (r'\134', '\\')]:
            value = value.replace(escaped, decoded)
        mountpoints.append(Path(value))
    for source in sources:
        if source.stat().st_uid != 1000 or stat.S_IMODE(source.stat().st_mode) != 0o700:
            raise RuntimeError('Unexpected source ownership or permissions')
        if any(mount == source or mount.is_relative_to(source) for mount in mountpoints):
            raise RuntimeError('Source contains a mountpoint')
    live_before = active_references(sources)
    if live_before['references'] or live_before['read_errors']:
        raise RuntimeError('Source is in use or process inspection is incomplete')
    snapshots = {str(source): snapshot(source) for source in sources}
    required_bytes = sum(entry.get('bytes', 0) for tree in snapshots.values() for entry in tree['entries'].values())
    if shutil.disk_usage(WORK_ROOT).free < 2 * required_bytes + 1024 * 1024:
        raise RuntimeError('Insufficient copy and verification space')
    parent = WORK_ROOT / 'relocated'
    if not parent.exists():
        parent.mkdir(mode=0o700)
        os.chown(parent, 1000, 1000)
    if parent.resolve().parent != WORK_ROOT:
        raise RuntimeError('Destination parent escaped the approved directory')
    destination = parent / datetime.datetime.now(datetime.timezone.utc).strftime('%Y%m%dT%H%M%SZ')
    destination.mkdir(mode=0o700)
    os.chown(destination, 1000, 1000)
    receipt = {'administration_source_sha256': source_sha256, 'source_host': os.uname().nodename,
               'destination': str(destination), 'status': 'copy_started', 'live_before': live_before,
               'sources': snapshots, 'mappings': [], 'errors': []}
    receipt_path = destination / 'migration.json'
    save_receipt(receipt_path, receipt)
    try:
        for source in sources:
            target = destination / source.name
            shutil.copytree(source, target, symlinks=True)
            for relative, metadata in snapshots[str(source)]['entries'].items():
                os.chown(target / relative, metadata['uid'], metadata['gid'], follow_symlinks=False)
            if target.resolve().parent != destination or not target.resolve().is_relative_to(WORK_ROOT):
                raise RuntimeError('Destination real path escaped')
            if snapshot(target)['entries'] != snapshots[str(source)]['entries']:
                raise RuntimeError('Copied content or metadata differs')
            receipt['mappings'].append({'old': str(source), 'new': str(target),
                                        'copy_verified': True, 'old_removed': False})
        for source in sources:
            if snapshot(source) != snapshots[str(source)]:
                raise RuntimeError('Original source changed during copy')
        receipt['live_before_delete'] = active_references(sources)
        if receipt['live_before_delete']['references'] or receipt['live_before_delete']['read_errors']:
            raise RuntimeError('Source became active or inspection failed')
        receipt['status'] = 'all_copies_verified'
        save_receipt(receipt_path, receipt)
        os.sync()
        for mapping in receipt['mappings']:
            source, target = Path(mapping['old']), Path(mapping['new'])
            if snapshot(source) != snapshots[str(source)] or snapshot(target)['entries'] != snapshots[str(source)]['entries']:
                raise RuntimeError('Deletion precondition changed')
            shutil.rmtree(source)
            mapping['old_removed'] = not source.exists() and not source.is_symlink()
            save_receipt(receipt_path, receipt)
            if not mapping['old_removed']:
                raise RuntimeError('Old path remains or was recreated after deletion')
        receipt['status'] = 'complete'
        save_receipt(receipt_path, receipt)
    except Exception as error:
        receipt['status'] = 'incomplete'
        receipt['errors'].append(str(error))
        save_receipt(receipt_path, receipt)
        raise
    finally:
        print(json.dumps({'destination': str(destination), 'receipt': str(receipt_path),
                          'status': receipt['status'], 'directories': len(receipt['mappings']),
                          'files': sum(entry['kind'] == 'file' for tree in snapshots.values() for entry in tree['entries'].values()),
                          'symlinks': sum(entry['kind'] == 'symlink' for tree in snapshots.values() for entry in tree['entries'].values()),
                          'bytes': required_bytes, 'removed_old_directories': sum(row['old_removed'] for row in receipt['mappings']),
                          'errors': receipt['errors']}))


if __name__ == '__main__':
    if sys.argv[1:] == ['--selfcheck']:
        with tempfile.TemporaryDirectory(dir='/Users/yin/code/cryProject/build') as temporary:
            root = Path(temporary)
            source = root / 'source'
            source.mkdir()
            (source / 'data').write_bytes(b'fixture\x00unchanged')
            before = snapshot(source, os.getuid())
            target = root / 'target'
            shutil.copytree(source, target)
            assert snapshot(target, os.getuid())['entries'] == before['entries']
            (target / 'data').write_bytes(b'changed')
            assert snapshot(target, os.getuid())['entries'] != before['entries']
            (source / 'link').symlink_to('/etc/passwd')
            try:
                snapshot(source, os.getuid())
            except RuntimeError:
                pass
            else:
                raise AssertionError('Symlink accepted')
            (source / 'link').unlink()
            original_root = WORK_ROOT
            WORK_ROOT = root
            try:
                (source / 'link').symlink_to(source / 'data')
                assert snapshot(source, os.getuid())['entries']['link']['kind'] == 'symlink'
                link_copy = root / 'link-copy'
                shutil.copytree(source, link_copy, symlinks=True)
                assert snapshot(link_copy, os.getuid())['entries'] == snapshot(source, os.getuid())['entries']
            finally:
                WORK_ROOT = original_root
        print('relocation_selfcheck=pass;remote_actions=none')
    elif len(sys.argv) == 2:
        migrate(sys.argv[1])
    else:
        raise SystemExit('Expected source digest or --selfcheck')
