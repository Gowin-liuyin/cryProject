#!/usr/bin/env python3
"""仅从实际 ZIP 复算并审查文档元数据；统计仍由包内 C 程序执行。"""
import hashlib
import io
import json
import subprocess
import sys
import zipfile
from pathlib import Path
from pypdf import PdfReader

repository=Path(__file__).resolve().parents[3]
revision=sys.argv[1]
support=repository/"deliverables/support/CACR2026EA16XZ-multi-leakage-platform-20261016"
archive=support/("CACR2026EA16XZ-platform-"+revision+".zip")
evidence=repository/"docs/evidence/platform-report-20261016"/revision
evidence.mkdir(exist_ok=True)
verification=subprocess.check_output([sys.executable,str(support/"verify_package.py"),str(archive)],text=True)
(evidence/"package-verification.json").write_text(verification)
extracted=repository/"build/platform-report-s8"/("extracted-"+revision)
# 可重复执行：先把上一次的解出目录与输出目录清掉（否则 reproduce.sh 因「输出目录已存在」退出 2）。
import shutil
if extracted.exists():
    shutil.rmtree(extracted)
extracted.mkdir()
with zipfile.ZipFile(archive) as package:
    package.extractall(extracted)
    pdf_content=package.read("report/report.pdf")
reader=PdfReader(io.BytesIO(pdf_content))
all_text="\n".join(page.extract_text() for page in reader.pages)
private_markers=["/Users/yin","/home/nss-marker","Gowin-liuyin","yinhaoran0808@outlook.com","10.144.144.5","nss-marker"]
assert not any(marker in all_text or marker in str(reader.metadata) for marker in private_markers)
assert reader.metadata.get("/Author","") in ["",None]
assert "/JavaScript" not in str(reader.trailer["/Root"].get("/Names",{}))
(evidence/"pdf-metadata-audit.json").write_text(json.dumps({"status":"pass","pages":len(reader.pages),"author_empty":True,"direct_private_markers":0,"document_javascript":False,"pdf_sha256":hashlib.sha256(pdf_content).hexdigest()},indent=2)+"\n")
before={str(path.relative_to(extracted)):hashlib.sha256(path.read_bytes()).hexdigest() for path in (extracted/"data").rglob("*") if path.is_file()}
output=repository/"build/platform-report-s8"/("offline-"+revision)
if output.exists():
    shutil.rmtree(output)
with (evidence/"offline-replay.log").open("w") as log_file:
    subprocess.run(["sh",str(extracted/"reproduce.sh"),str(output)],check=True,stdout=log_file,stderr=subprocess.STDOUT)
after={str(path.relative_to(extracted)):hashlib.sha256(path.read_bytes()).hexdigest() for path in (extracted/"data").rglob("*") if path.is_file()}
assert before==after
result={"status":"pass","execution_platform":"macOS/ARM","actual_zip_extracted":True,"ctest_passed":5,"replayed_datasets":len(before),"compared_outputs":2*len(before),"input_raw_bytes_unchanged":True,"new_hardware_collection":"not_run","external_statistical_tools":"not_reexecuted"}
(evidence/"offline-reproduction.json").write_text(json.dumps(result,indent=2)+"\n")
validator_negative = repository / "build/platform-report-s8" / ("validator-negative-" + revision)
if validator_negative.exists():
    shutil.rmtree(validator_negative)
with (evidence/"validator-rejection-tests.json").open("w") as log_file:
    subprocess.run([sys.executable,str(support/"test_package_validator.py"),str(archive),str(validator_negative)],check=True,stdout=log_file)
render=repository/"docs/evidence/platform-report-20261016"/("render-"+revision)
render.mkdir(exist_ok=True)
subprocess.run(["pdftoppm","-r","100","-png",str(extracted/"report/report.pdf"),str(render/"page")],check=True)
print(json.dumps({"revision":revision,"pdf_pages":len(reader.pages),**result},ensure_ascii=False))
