from pathlib import Path
import hashlib
import json
import platform
import re
import shutil
import sys
import zipfile

from pypdf import PdfReader


WORK = Path(__file__).resolve().parent
REPO = WORK.parent.parent
DEST = REPO / 'deliverables/research/aris-report-synthesis-20261010'
EVIDENCE = REPO / 'docs/evidence/aris-report-synthesis-20261010'
DOCX_SHA = '95ffce23d02180117fb05ccf9ebc406b7b05ae20038f08042e25d13934e2983f'
PDF_SHA = '27e8001b8a374be9636c83196c65295626551277b8aafd961f47e223c174d7f7'
STEM = 'CACR2026EA16XZ-作品设计报告-四项研究整合候选版'


def sha(payload):
    return hashlib.sha256(payload).hexdigest()


def write_json(path, data):
    assert not path.exists(), path
    path.write_text(json.dumps(data, ensure_ascii=False, indent=2)+'\n')


def main():
    docx = WORK / (STEM+'.docx')
    pdf = WORK / 'render-final-v2' / (STEM+'.pdf')
    assert sha(docx.read_bytes()) == DOCX_SHA and sha(pdf.read_bytes()) == PDF_SHA
    structure = json.loads((WORK / 'delivery-candidate-verification.json').read_text())
    assert len(structure['checks']) == 120 and not structure['failures']
    toc = json.loads((WORK / 'toc-final-check.json').read_text())
    assert toc['check_only'] and toc['actual_pdf_pages'] == 54 and toc['toc_entries'] == 45
    assert toc['docx_after_sha256'] == DOCX_SHA and toc['pagination_pdf_sha256'] == PDF_SHA
    receipts = ['visual-review-final-root.json', 'visual-review-final-pages5-20.json',
                'visual-review-final-pages21-37.json', 'visual-review-final-pages38-54.json']
    pages = []
    for name in receipts:
        receipt_bytes = (WORK / name).read_bytes()
        receipt = json.loads(receipt_bytes)
        assert DOCX_SHA in receipt_bytes.decode() and PDF_SHA in receipt_bytes.decode()
        for row in receipt['pages']:
            number = row['physical_page']
            expected = row.get('png_sha256', row.get('image_sha256', row.get('sha256')))
            path = WORK / 'render-final-v2' / f'page-{number}.png'
            assert sha(path.read_bytes()) == expected
            opened = (row.get('opened_original') or row.get('actual_full_page_opened_again')
                      or row.get('actually_reopened_after_orphan_fix') or row.get('actual_view_record', {}).get('viewed'))
            assert opened, (name, number)
            assert row.get('passed', True) and not row.get('blocking_issues', [])
            assert row.get('result', 'pass_visual') == 'pass_visual'
            assert not row.get('status', 'pass').startswith('needs')
            pages.append({'physical_page': number, 'png_sha256': expected, 'receipt': name,
                          'actual_original_opened': True})
    assert sorted(row['physical_page'] for row in pages) == list(range(1,55))
    reader = PdfReader(pdf)
    assert len(reader.pages) == 54
    all_text = '\n'.join(page.extract_text() or '' for page in reader.pages)
    private = r'(?i)Gowin[-_]liuyin|yinhaoran0808|nss-marker|/Users/|/home/|10\.144\.144\.[35]|119\.45\.121\.134|yhr/Cry'
    assert not re.search(private, all_text + str(dict(reader.metadata)))
    assert '\ufffd' not in all_text
    assert not reader.metadata.get('/Author', '')
    sizes = {(round(float(page.mediabox.width), 1), round(float(page.mediabox.height), 1)) for page in reader.pages}
    assert len(sizes) == 1
    for number, page in enumerate(reader.pages[4:], 1):
        assert str(number) in [line.strip() for line in (page.extract_text() or '').splitlines()]
    originals = {
        'deliverables/research/aris-report-g2-20261010/CACR2026EA16XZ-作品设计报告-匿名版.docx': '96e2de8af1238518f8d754cd9f969a4e82499d8b89552e143128aeba8da861e6',
        'deliverables/research/aris-report-g2-20261010/CACR2026EA16XZ-作品设计报告-匿名版.pdf': 'd5b65e65f66cd3ade42fee58502112be34ab97716b587657e41e2d246a1e60a4',
        'deliverables/support/CACR2026EA16XZ-g2-windows-20261010/CACR2026EA16XZ-G2窗口与研究材料补充件.zip': 'd5c7a05c0585890d0442431992ea1b09db459a05c445fb17dcb0c1092e429cd3',
    }
    for name, expected in originals.items():
        assert sha((REPO / name).read_bytes()) == expected, name
    files = [
        'artifact.md', 'template-inventory.json', 'OUTLINE_REVIEW.md', 'outline-review.json',
        'REQUIREMENTS_AUDIT.md', 'REQUIREMENTS_AUDIT.json', 'NEW_EVIDENCE_FACT_CHECK.md',
        'NEW_EVIDENCE_FACT_CHECK.json', 'NEW_REPORT_ACCEPTANCE_CHECKLIST.md', 'report-content-checklist.json',
        'build_candidate.py', 'finalize_candidate.py', 'verify_candidate.py', 'seal_delivery.py',
        'authoring-edits.json', 'initial-structure.json', 'round1-authoring-edits.json',
        'ROUND1_CONTENT_REVIEW.md', 'ROUND1_CONTENT_REVIEW.json', 'ROUND2_CONTENT_REVIEW.md',
        'ROUND2_CONTENT_REVIEW.json', 'FINAL_CONTENT_DELTA_REVIEW.md', 'FINAL_CONTENT_DELTA_REVIEW.json',
        'candidate-verification.json', 'final-candidate-verification-comparator-rejection.json',
        'delivery-candidate-verification.json', 'verify_candidate-initial.py', 'verify_candidate-before-range-fix.py',
        'toc-map.json', 'toc-final-check.json', 'fonts.conf',
        'attempt-01-builder.py', 'attempt-02-builder.py', 'attempt-03-builder-with-bookmark-fix.py', 'attempt-05-builder.py',
    ] + receipts
    for name in files:
        target = EVIDENCE / name
        assert not target.exists(), name
        shutil.copy2(WORK / name, target)
    history = WORK / 'review-before-orphan-fix'
    assert not (EVIDENCE / history.name).exists()
    shutil.copytree(history, EVIDENCE / history.name)
    attempts = {'hardware_collections': 0, 'C_runs': 0, 'SSH': False,
                'initial_build_failure': '作者脚本复用ZipInfo改变内存偏移，输出后置源读取校验报BadZipFile；源文件实际字节未改。改为写前读取摘要。',
                'first_candidate_issues': ['旧4.6 TOC书签丢失', 'RAW保护层级措辞', 'RAW小表跨页'],
                'verifier_comparator_rejection': '脱离根XML克隆命名空间差异误拒B144，改用原始XML范围比较，旧记录/脚本保留。',
                'visual_iterations': ['55页首稿附录A两行孤尾', '第一次精简后仍两行孤尾', '再次缩为不重复的身份说明，54页闭合'],
                'candidate_snapshots': []}
    for path in sorted(WORK.glob('attempt-*-candidate.docx')) + [WORK/'attempt-04-before-orphan-fix.docx']:
        if path.exists():
            attempts['candidate_snapshots'].append({'build_file': path.name, 'bytes': path.stat().st_size, 'sha256': sha(path.read_bytes()), 'distribution': False})
    write_json(EVIDENCE/'attempts.json', attempts)
    write_json(EVIDENCE/'visual-qa.json', {'pages': sorted(pages, key=lambda r:r['physical_page']),
               'total_pages':54,'actual_original_page_views':54,'docx_sha256':DOCX_SHA,'pdf_sha256':PDF_SHA,
               'status':'passed','scope':'最终每页实际观看；同模型内部复核，不是外部同行评审'})
    write_json(EVIDENCE/'render-environment.json', {'platform':platform.platform(),'python':sys.version,
               'renderer':'/Users/yin/.codex/plugins/cache/openai-primary-runtime/documents/26.1007.11041/skills/documents/render_docx.py',
               'bundled_soffice':'/Users/yin/.cache/codex-runtimes/codex-primary-runtime/dependencies/native/libreoffice-headless/libreoffice/LibreOfficeDev.app/Contents/MacOS/soffice',
               'bundled_soffice_version':'LibreOfficeDev 26.8.0.0.alpha0 2c87e51eeaa2b413ff4ae097b2705eea1995d8e5',
               'user_desktop_LibreOffice_used':False,'fontconfig_sha256':sha((WORK/'fonts.conf').read_bytes()),
               'rendered_page_dimensions_px':[1414,2000],'PDF_page_sizes_points':sorted(sizes)})
    with zipfile.ZipFile(EVIDENCE/'page-images.zip','w',compression=zipfile.ZIP_DEFLATED) as out:
        for number in range(1,55):
            info = zipfile.ZipInfo(f'page-{number}.png',date_time=(2026,10,10,0,0,0))
            info.compress_type = zipfile.ZIP_DEFLATED
            out.writestr(info,(WORK/'render-final-v2'/info.filename).read_bytes())
    for source, suffix in [(docx,'.docx'),(pdf,'.pdf')]:
        target = DEST/('CACR2026EA16XZ-作品设计报告-匿名版'+suffix)
        assert not target.exists()
        shutil.copy2(source,target)
        assert target.read_bytes() == source.read_bytes()
    write_json(EVIDENCE/'delivery-verification.json', {'docx_sha256':DOCX_SHA,'pdf_sha256':PDF_SHA,
        'pages':54,'TOC_entries':45,'native_math':70,'drawings':19,'tables':26,'sections':4,
        'structure_checks_passed':120,'actual_page_visual_checks_passed':54,
        'pdf_metadata':dict(reader.metadata),'pdf_identity_scan':'passed','originals_unchanged':originals,
        'no_new_C_or_hardware_or_SSH':True,'anonymous_support_closure':'pending_separate_module',
        'external_peer_review':False,'screenshots_signatures_platform_receipt':'pending_real_material'})
    for directory in [DEST,EVIDENCE]:
        paths = sorted(p for p in directory.rglob('*') if p.is_file() and p.name!='SHA256SUMS')
        (directory/'SHA256SUMS').write_text(''.join(f'{sha(p.read_bytes())}  {p.relative_to(directory).as_posix()}\n' for p in paths))
    print(json.dumps({'DOCX':str(DEST/('CACR2026EA16XZ-作品设计报告-匿名版.docx')),
                      'PDF':str(DEST/('CACR2026EA16XZ-作品设计报告-匿名版.pdf')),
                      'evidence_files':len(list(EVIDENCE.rglob('*'))),'pages':54},ensure_ascii=False))


if __name__ == '__main__':
    main()
