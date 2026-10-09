import datetime
import hashlib
import io
import json
import os
from pathlib import Path
import pwd
import re
import secrets
import stat
import struct
import tarfile


PROJECT_ROOT = Path('/home/nss-marker/yhr/Cry')
TABLE_ROOT = Path('/sys/firmware/acpi/tables')
MAX_TABLE_BYTES = 1024 * 1024
MAX_TOTAL_BYTES = 2 * MAX_TABLE_BYTES


def table_metadata(content):
    if len(content) < 36 or len(content) > MAX_TABLE_BYTES:
        raise ValueError('ACPI table size outside admitted range')
    signature, length = struct.unpack_from('<4sI', content)
    if signature not in (b'DSDT', b'SSDT') or length != len(content):
        raise ValueError('ACPI signature or declared length mismatch')
    if sum(content) % 256:
        raise ValueError('ACPI checksum mismatch')
    return {'signature': signature.decode('ascii'), 'length_bytes': length,
            'revision': content[8], 'checksum_modulo_256': 0,
            'sha256': hashlib.sha256(content).hexdigest(),
            'cpc_name_byte_occurrences': content.count(b'_CPC')}


def firmware_nodes():
    result = {}
    for cpu_index in (2, 18):
        node = Path('/sys/devices/system/cpu') / f'cpu{cpu_index}' / 'firmware_node'
        result[str(cpu_index)] = {'realpath': str(node.resolve()),
                                  **{name: (node / name).read_text().strip()
                                     for name in ('path', 'uid', 'hid')}}
    return result


def create_file(directory_descriptor, name, content):
    descriptor = os.open(name, os.O_WRONLY | os.O_CREAT | os.O_EXCL | os.O_NOFOLLOW,
                         0o600, dir_fd=directory_descriptor)
    with os.fdopen(descriptor, 'wb') as output:
        output.write(content)


def check_work(root_descriptor, account):
    metadata = os.fstat(root_descriptor)
    current = Path.cwd().stat()
    if Path(os.readlink(f'/proc/self/fd/{root_descriptor}')) != PROJECT_ROOT:
        raise RuntimeError('working root physical path changed')
    if metadata.st_uid != account.pw_uid or (metadata.st_dev, metadata.st_ino) != (
            current.st_dev, current.st_ino):
        raise RuntimeError('working directory identity mismatch')


def capture_into(root_descriptor, account):
    check_work(root_descriptor, account)
    tables = []
    for directory in (TABLE_ROOT, TABLE_ROOT / 'dynamic'):
        for path in sorted(directory.iterdir()):
            if re.fullmatch(r'DSDT|SSDT[0-9]*', path.name):
                if path.is_symlink() or not stat.S_ISREG(path.stat().st_mode):
                    raise RuntimeError('unexpected ACPI table object')
                prefix = '' if directory == TABLE_ROOT else 'dynamic__'
                tables.append((path, prefix + path.name + '.dat'))
    if not 1 <= len(tables) <= 64:
        raise RuntimeError('unexpected ACPI table count')
    payloads = {}
    descriptions = {}
    total_bytes = 0
    for path, filename in tables:
        with path.open('rb') as source:
            content = source.read(MAX_TABLE_BYTES + 1)
        total_bytes += len(content)
        if total_bytes > MAX_TOTAL_BYTES:
            raise RuntimeError('ACPI total size exceeds admitted budget')
        descriptions[filename] = {'sysfs_path': str(path), **table_metadata(content)}
        payloads[filename] = content
    if not any(entry['signature'] == 'DSDT' for entry in descriptions.values()):
        raise RuntimeError('DSDT missing')
    name = 'feedback-mapping-20261010-' + secrets.token_hex(6)
    metadata = {'utc': datetime.datetime.now(datetime.timezone.utc).isoformat(),
                'uname': list(os.uname()), 'effective_uid': os.geteuid(),
                'project_root': str(PROJECT_ROOT), 'capture_directory': name,
                'configuration_writes': 0, 'aml_evaluation_performed': False,
                'firmware_nodes': firmware_nodes(), 'tables': descriptions}
    payloads['metadata.json'] = (json.dumps(metadata, indent=2) + '\n').encode()
    check_work(root_descriptor, account)
    os.mkdir(name, mode=0o700, dir_fd=root_descriptor)
    created = os.stat(name, dir_fd=root_descriptor, follow_symlinks=False)
    store_descriptor = os.open(name, os.O_RDONLY | os.O_DIRECTORY | os.O_NOFOLLOW,
                               dir_fd=root_descriptor)
    try:
        actual = os.fstat(store_descriptor)
        if not stat.S_ISDIR(actual.st_mode) or actual.st_uid != 0 or stat.S_IMODE(
                actual.st_mode) != 0o700 or (actual.st_dev, actual.st_ino) != (
                    created.st_dev, created.st_ino):
            raise RuntimeError('new private directory identity mismatch')
        for filename, content in payloads.items():
            check_work(root_descriptor, account)
            if Path(os.readlink(f'/proc/self/fd/{store_descriptor}')) != PROJECT_ROOT / name:
                raise RuntimeError('private directory moved')
            create_file(store_descriptor, filename, content)
        for filename, content in payloads.items():
            descriptor = os.open(filename, os.O_RDONLY | os.O_NOFOLLOW, dir_fd=store_descriptor)
            with os.fdopen(descriptor, 'rb') as original:
                if original.read(MAX_TOTAL_BYTES + 1) != content:
                    raise RuntimeError('private original readback mismatch')
    finally:
        os.close(store_descriptor)
    check_work(root_descriptor, account)
    archive_name = name + '.tar'
    archive_descriptor = os.open(archive_name,
                                 os.O_RDWR | os.O_CREAT | os.O_EXCL | os.O_NOFOLLOW,
                                 0o600, dir_fd=root_descriptor)
    with os.fdopen(archive_descriptor, 'w+b') as archive_output:
        with tarfile.open(fileobj=archive_output, mode='w') as archive:
            for filename, content in payloads.items():
                member = tarfile.TarInfo(name + '/' + filename)
                member.mode = 0o600
                member.size = len(content)
                archive.addfile(member, io.BytesIO(content))
        archive_output.flush()
        archive_output.seek(0)
        with tarfile.open(fileobj=archive_output, mode='r') as archive:
            expected = {name + '/' + filename: content for filename, content in payloads.items()}
            if len(archive.getmembers()) != len(expected):
                raise RuntimeError('archive member count mismatch')
            for member in archive.getmembers():
                if not member.isfile() or member.name not in expected:
                    raise RuntimeError('unexpected archive member')
                with archive.extractfile(member) as source:
                    if source.read(MAX_TOTAL_BYTES + 1) != expected.pop(member.name):
                        raise RuntimeError('archive payload mismatch')
            if expected:
                raise RuntimeError('archive member missing')
        archive_output.seek(0)
        digest = hashlib.file_digest(archive_output, 'sha256').hexdigest()
        os.fchown(archive_output.fileno(), account.pw_uid, account.pw_gid)
    print(json.dumps({'archive': str(PROJECT_ROOT / archive_name), 'sha256': digest,
                      'table_count': len(tables), 'table_bytes': total_bytes,
                      'capture_directory': name, 'private_originals_and_archive_equal': True,
                      'configuration_writes': 0, 'aml_evaluation_performed': False}, indent=2))


def capture():
    if os.geteuid() != 0 or os.uname().sysname != 'Linux' or os.uname().nodename != 'nss-m':
        raise RuntimeError('root on the admitted Linux host is required')
    if Path.cwd() != PROJECT_ROOT or PROJECT_ROOT.resolve(strict=True) != PROJECT_ROOT:
        raise RuntimeError('working root is outside the admitted physical path')
    account = pwd.getpwnam('nss-marker')
    root_descriptor = os.open(PROJECT_ROOT,
                              os.O_RDONLY | os.O_DIRECTORY | os.O_NOFOLLOW | os.O_CLOEXEC)
    try:
        capture_into(root_descriptor, account)
    finally:
        os.close(root_descriptor)


if __name__ == '__main__':
    capture()
