import datetime
import hashlib
import io
import json
import os
from pathlib import Path
import pwd
import secrets
import signal
import stat
import subprocess
import tarfile
import time


PROJECT_ROOT = Path('/home/nss-marker/yhr/Cry')
RUN_ROOT = PROJECT_ROOT / 'feedback-reader-eed81a7'
BINARY_DIGEST = 'acfa346972dd79dc614927e89697632fe71c3d68b5e2829522faeaa93cc422a7'


def main():
    if os.geteuid() != 0 or tuple(os.uname())[:3] != ('Linux', 'nss-m', '6.17.0-35-generic'):
        raise RuntimeError('admitted root Linux environment required')
    account = pwd.getpwnam('nss-marker')
    root_descriptor = os.open(PROJECT_ROOT, os.O_RDONLY | os.O_DIRECTORY | os.O_NOFOLLOW)
    try:
        def check_root():
            metadata = os.fstat(root_descriptor)
            current = Path.cwd().stat()
            if Path(os.readlink(f'/proc/self/fd/{root_descriptor}')) != PROJECT_ROOT or metadata.st_uid != account.pw_uid:
                raise RuntimeError('working root physical path or owner mismatch')
            if (metadata.st_dev, metadata.st_ino) != (current.st_dev, current.st_ino):
                raise RuntimeError('working directory identity mismatch')

        check_root()
        source = RUN_ROOT / 'build-normal/msr_counter_snapshot'
        descriptor = os.open(source, os.O_RDONLY | os.O_NOFOLLOW)
        with os.fdopen(descriptor, 'rb') as source_file:
            metadata = os.fstat(source_file.fileno())
            if not stat.S_ISREG(metadata.st_mode) or metadata.st_uid != account.pw_uid:
                raise RuntimeError('binary source object rejected')
            if Path(os.readlink(f'/proc/self/fd/{source_file.fileno()}')) != source:
                raise RuntimeError('binary source physical path mismatch')
            binary = source_file.read(2 * 1024 * 1024 + 1)
        if len(binary) > 2 * 1024 * 1024 or hashlib.sha256(binary).hexdigest() != BINARY_DIGEST:
            raise RuntimeError('binary digest or size mismatch')
        name = 'feedback-counter-20261010-' + secrets.token_hex(6)
        check_root()
        os.mkdir(name, 0o700, dir_fd=root_descriptor)
        created = os.stat(name, dir_fd=root_descriptor, follow_symlinks=False)
        store_descriptor = os.open(name, os.O_RDONLY | os.O_DIRECTORY | os.O_NOFOLLOW,
                                   dir_fd=root_descriptor)
        try:
            actual = os.fstat(store_descriptor)
            if actual.st_uid != 0 or stat.S_IMODE(actual.st_mode) != 0o700 or (
                    actual.st_dev, actual.st_ino) != (created.st_dev, created.st_ino):
                raise RuntimeError('private directory identity mismatch')

            def save(filename, content, mode=0o600):
                check_root()
                if Path(os.readlink(f'/proc/self/fd/{store_descriptor}')) != PROJECT_ROOT / name:
                    raise RuntimeError('private store moved')
                descriptor = os.open(filename, os.O_WRONLY | os.O_CREAT | os.O_EXCL | os.O_NOFOLLOW,
                                     mode, dir_fd=store_descriptor)
                with os.fdopen(descriptor, 'wb') as output:
                    output.write(content)

            save('msr_counter_snapshot', binary, 0o500)
            executable = f'/proc/self/fd/{store_descriptor}/msr_counter_snapshot'
            record = {'utc': datetime.datetime.now(datetime.timezone.utc).isoformat(),
                      'uname': list(os.uname()), 'effective_uid': os.geteuid(),
                      'source_commit': 'eed81a7620a1c929c52e96acb203104917ec3b5d',
                      'binary_sha256': BINARY_DIGEST, 'working_directory': str(PROJECT_ROOT / name),
                      'configuration_writes': 0, 'frequency_converted': False}
            check_root()
            started = time.monotonic()
            signal.signal(signal.SIGCHLD, signal.SIG_DFL)
            process = subprocess.Popen([executable], cwd=f'/proc/self/fd/{store_descriptor}',
                                       pass_fds=(store_descriptor,), stdin=subprocess.DEVNULL,
                                       stdout=subprocess.PIPE, stderr=subprocess.PIPE,
                                       env={'PATH': '/usr/bin:/bin', 'LC_ALL': 'C'})
            record['pid'] = process.pid
            try:
                record['start_ticks'] = Path(f'/proc/{process.pid}/stat').read_text().rpartition(')')[2].split()[19]
            except (OSError, IndexError) as error:
                record['start_ticks'] = None
                record['identity_error'] = {'type': type(error).__name__,
                                             'errno': getattr(error, 'errno', None)}
            try:
                stdout, stderr = process.communicate(timeout=10)
                record['execution_deadline_exceeded'] = False
            except subprocess.TimeoutExpired:
                process.kill()
                stdout, stderr = process.communicate()
                record['execution_deadline_exceeded'] = True
            record.update({'exit_code': process.returncode, 'wall_seconds': time.monotonic() - started})
            payloads = {'msr_counter_snapshot': binary, 'stdout.json': stdout,
                        'stderr.log': stderr, 'execution.json': (json.dumps(record, indent=2) + '\n').encode()}
            for filename, content in payloads.items():
                if filename != 'msr_counter_snapshot':
                    save(filename, content)
                descriptor = os.open(filename, os.O_RDONLY | os.O_NOFOLLOW, dir_fd=store_descriptor)
                with os.fdopen(descriptor, 'rb') as original:
                    if original.read(2 * 1024 * 1024 + 1) != content:
                        raise RuntimeError('private original readback mismatch')
        finally:
            os.close(store_descriptor)
        check_root()
        archive_name = name + '.tar'
        descriptor = os.open(archive_name, os.O_RDWR | os.O_CREAT | os.O_EXCL | os.O_NOFOLLOW,
                             0o600, dir_fd=root_descriptor)
        with os.fdopen(descriptor, 'w+b') as output:
            with tarfile.open(fileobj=output, mode='w') as archive:
                for filename, content in payloads.items():
                    member = tarfile.TarInfo(name + '/' + filename)
                    member.mode = 0o500 if filename == 'msr_counter_snapshot' else 0o600
                    member.size = len(content)
                    archive.addfile(member, io.BytesIO(content))
            output.flush()
            output.seek(0)
            with tarfile.open(fileobj=output, mode='r') as archive:
                expected = {name + '/' + filename: content for filename, content in payloads.items()}
                if len(archive.getmembers()) != len(expected):
                    raise RuntimeError('archive member count mismatch')
                for member in archive.getmembers():
                    if not member.isfile() or member.name not in expected:
                        raise RuntimeError('archive member rejected')
                    with archive.extractfile(member) as archived:
                        if archived.read(2 * 1024 * 1024 + 1) != expected.pop(member.name):
                            raise RuntimeError('archive readback mismatch')
                if expected:
                    raise RuntimeError('archive member missing')
            output.seek(0)
            digest = hashlib.file_digest(output, 'sha256').hexdigest()
            os.fchown(output.fileno(), account.pw_uid, account.pw_gid)
        print(json.dumps({'archive': str(PROJECT_ROOT / archive_name), 'sha256': digest,
                          'reader_exit_code': record['exit_code'],
                          'private_originals_and_archive_equal': True,
                          'execution_deadline_exceeded': record['execution_deadline_exceeded']}, indent=2))
        if record['exit_code'] != 0:
            raise SystemExit(1)
    finally:
        os.close(root_descriptor)


if __name__ == '__main__':
    main()
