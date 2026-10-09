from pathlib import Path
import hashlib
import json
import zipfile

root = Path('/Users/yin/code/cryProject')
payload = root / 'build/aris-current-package-20261009/payload'
evidence = root / 'docs/evidence/aris-current-package-20261009'
verification = json.loads((evidence / 'final-payload-verification.json').read_text())
assert verification['final_payload_passed']
output = root / 'deliverables/support/CACR2026EA16XZ-aris-current-20261009/CACR2026EA16XZ-当前研究报告与数学复核补充件.zip'
assert not output.exists()
files = sorted(path for path in payload.rglob('*') if path.is_file())
with zipfile.ZipFile(output, 'x', compression=zipfile.ZIP_DEFLATED, compresslevel=9) as archive:
    for source in files:
        archive.write(source, str(source.relative_to(payload)))
sha = lambda data: hashlib.sha256(data).hexdigest()
with zipfile.ZipFile(output) as archive:
    assert archive.testzip() is None
    assert len(archive.infolist()) == len(files) == 870
    assert len(set(archive.namelist())) == 870
    for member in archive.infolist():
        relative = Path(member.filename)
        assert not relative.is_absolute() and '..' not in relative.parts
        assert archive.read(member.filename) == (payload / member.filename).read_bytes()
    manifest = json.loads(archive.read('manifest.json'))
    for record in manifest['files']:
        assert sha(archive.read(record['distributed_path'])) == record['distributed_copy_sha256']
    for line in archive.read('SHA256SUMS').decode().splitlines():
        digest, relative = line.split('  ', 1)
        assert sha(archive.read(relative)) == digest
    assert sha(archive.read('report/CACR2026EA16XZ-作品设计报告.docx')) == verification['report_docx_sha256']
    assert sha(archive.read('report/CACR2026EA16XZ-作品设计报告.pdf')) == verification['report_pdf_sha256']
    final = {
        'final_archive_created': True,
        'archive_path': str(output.relative_to(root)),
        'archive_sha256': sha(output.read_bytes()),
        'archive_bytes': output.stat().st_size,
        'archive_entries': len(archive.infolist()),
        'unique_entries': len(set(archive.namelist())),
        'CRC': 'passed',
        'archive_member_bytes_exact_to_verified_payload': True,
        'all_manifest_and_SHA_entries_verified_from_actual_ZIP': True,
        'manifest_records': len(manifest['files']),
        'SHA_records': len(archive.read('SHA256SUMS').decode().splitlines()),
        'final_report_byte_identity': True,
        'old_nine_groups540_and_M01all20_identity_preserved': True,
        'final_zip_bound_to_verified_payload_only_not_pre_final860_stage': True,
        'independent_final_assembly_closure': 'pending_readonly_final_ZIP_check',
        'new_formal_runs': 0,
        'new_C_replay_for_archive_assembly': False,
        'software_v3_replacement': False,
        'full_goal_complete': False,
    }
(evidence / 'final-archive-verification.json').write_text(json.dumps(final, ensure_ascii=False, indent=2) + '\n')
(output.parent / 'SHA256SUMS').write_text(final['archive_sha256'] + '  ' + output.name + '\n')
print(json.dumps(final, ensure_ascii=False))
