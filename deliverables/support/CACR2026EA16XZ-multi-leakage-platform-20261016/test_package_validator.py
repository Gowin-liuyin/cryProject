#!/usr/bin/env python3
"""以实际实包构造有限坏例，确认校验器拒绝损坏和活动内容。"""
import hashlib
import importlib.util
import json
import sys
import warnings
import zipfile
from pathlib import Path

directory=Path(__file__).resolve().parent
spec=importlib.util.spec_from_file_location("verify_package",directory/"verify_package.py")
verifier=importlib.util.module_from_spec(spec)
spec.loader.exec_module(verifier)
source=Path(sys.argv[1])
output=Path(sys.argv[2])
output.mkdir()
with zipfile.ZipFile(source) as archive:
    original={name:archive.read(name) for name in archive.namelist()}
assert verifier.verify(source)["status"]=="pass"
results=[]
for case_name in ["digest","missing","escape","duplicate","remote","active","private","anchor"]:
    files=dict(original)
    if case_name=="digest":
        files["report/report.md"]+=b"modified"
    elif case_name=="missing":
        del files["report/report.pdf"]
    elif case_name=="escape":
        files["../escape"]=b"bad"
    elif case_name in {"remote","active","private","anchor"}:
        name="report/report.md" if case_name=="private" else "report/index.html"
        additions={"remote":b'<img src="https://example.invalid/asset.png">',"active":b'<script>1</script>',"private":b'/Users/example-person/private',"anchor":b'<a href="#missing-target">broken</a>'}
        files[name]+=additions[case_name]
        manifest=json.loads(files["MANIFEST.json"])
        for entry in manifest["files"]:
            if entry["path"]==name:
                entry.update(bytes=len(files[name]),sha256=hashlib.sha256(files[name]).hexdigest())
        files["MANIFEST.json"]=json.dumps(manifest).encode()
    path=output/(case_name+".zip")
    with warnings.catch_warnings():
        warnings.simplefilter("ignore",UserWarning)
        with zipfile.ZipFile(path,"x",zipfile.ZIP_DEFLATED) as archive:
            for name,content in files.items(): archive.writestr(name,content)
            if case_name=="duplicate": archive.writestr("report/report.md",files["report/report.md"])
    try:
        verifier.verify(path)
    except ValueError as error:
        results.append({"case":case_name,"status":"rejected","reason":str(error)})
    else:
        raise AssertionError("accepted invalid package: "+case_name)
print(json.dumps({"status":"pass","actual_package_positive":True,"rejection_checks":results},indent=2))
