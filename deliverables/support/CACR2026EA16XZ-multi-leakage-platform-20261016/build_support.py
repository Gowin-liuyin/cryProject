#!/usr/bin/env python3
"""白名单组装新匿名副本；Python 只编排文件和文档，统计由原 C 工具执行。"""
import argparse
import hashlib
import html
import importlib.util
import json
import re
import shlex
import shutil
import subprocess
import zipfile
from pathlib import Path

DIRECTORY = Path(__file__).resolve().parent
REPOSITORY = DIRECTORY.parents[2]
REPORT = REPOSITORY/"deliverables/research/multi-leakage-platform-20261016"


def anonymous_text(text):
    replacements = [(str(REPOSITORY),"[REPOSITORY]"),("/Users/yin","[LOCAL_USER]"),("/home/nss-marker/yhr/Cry","[REMOTE_PROJECT]"),("/home/nss-marker","[REMOTE_USER]"),("10.144.144.5","[REMOTE_IP]"),("10.144.144.3","[REMOTE_IP]"),("119.45.121.134","[HISTORICAL_IP]"),("yinhaoran0808@outlook.com","[AUTHOR_EMAIL]"),("Gowin-liuyin","[PROJECT_AUTHOR]"),("yindeMacBook-Air.local","[LOCAL_HOST]"),("nss-marker","[REMOTE_USER]"),("nss-m","[LINUX_HOST]")]
    for original,replacement in replacements:
        text = text.replace(original,replacement)
    return re.sub(r"/(?:Users|home)/[A-Za-z0-9_.-]+", "[ANONYMOUS_HOME]", text)


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--revision",required=True)
    arguments = parser.parse_args()
    if not re.fullmatch(r"[a-zA-Z0-9-]+",arguments.revision):
        raise ValueError("invalid revision")
    staging = REPOSITORY/"build/platform-report-s8"/("support-"+arguments.revision)
    archive_path = DIRECTORY/("CACR2026EA16XZ-platform-"+arguments.revision+".zip")
    if staging.exists() or archive_path.exists():
        raise FileExistsError("new revision required")
    staging.mkdir(parents=True)
    provenance = []

    def copy_file(source_path,target,mode="text"):
        source_path = Path(source_path)
        if source_path.is_symlink() or not source_path.is_file():
            raise ValueError("not an ordinary source file: "+str(source_path))
        if any(part.startswith(".") for part in source_path.relative_to(REPOSITORY).parts):
            raise ValueError("hidden metadata excluded: "+str(source_path))
        original = source_path.read_bytes()
        copied = original
        if mode == "text":
            try:
                decoded = original.decode("utf-8")
            except UnicodeDecodeError:
                # 新增的图形产物（PDF/PNG 等）是二进制，不能按文本改写；
                # 原字节复制，匿名性由 verify_package.py 的字节/文本模式扫描兜底。
                decoded = None
            if decoded is None:
                mode = "binary"
        if mode == "text":
            text = anonymous_text(original.decode("utf-8"))
            if source_path.suffix == ".md":
                text = re.sub(r"!?\[([^\]]*)\]\((?!https?://)([^)]+)\)",r"\1（原仓库引用：\2）",text)
            copied = text.encode("utf-8")
        destination = staging/target
        destination.parent.mkdir(parents=True,exist_ok=True)
        destination.write_bytes(copied)
        destination.chmod(0o755 if source_path.suffix == ".sh" else 0o644)
        provenance.append({"source":str(source_path.relative_to(REPOSITORY)),"published":target,"source_sha256":hashlib.sha256(original).hexdigest(),"published_sha256":hashlib.sha256(copied).hexdigest(),"transform":"raw_bytes_preserved" if copied==original else "new_anonymous_text_copy_local_links_as_text"})

    data = json.loads((REPORT/"report-data.json").read_text())
    snapshot = json.loads((REPORT/"evidence-snapshot.json").read_text())
    for source in snapshot["sources"]:
        if hashlib.sha256((REPOSITORY/source["path"]).read_bytes()).hexdigest() != source["sha256"]:
            raise ValueError("source changed; refresh report before packaging: "+source["path"])
    for name in ["report.pdf","report.tex","report.md","report-data.json","report-tables.json","evidence-snapshot.json","platform-matrix.svg","index.html"]:
        copy_file(REPORT/name,"report/"+name,"binary" if name.endswith(".pdf") else "text")
    packaged_report_html=staging/"report"/"index.html"
    rewritten_html=packaged_report_html.read_text().replace('href="../../../','href="../evidence/files/')
    if rewritten_html != packaged_report_html.read_text():
        packaged_report_html.write_text(rewritten_html)
        for record in provenance:
            if record["published"]=="report/index.html":
                record["published_sha256"]=hashlib.sha256(packaged_report_html.read_bytes()).hexdigest()
                record["transform"]="new_anonymous_text_copy_local_links_rewritten_to_packaged_evidence"
    evidence_links=[]
    for source in data["sources"]:
        target="evidence/files/"+source["path"]
        copy_file(REPOSITORY/source["path"],target)
        viewer_name="evidence/"+source["id"]+".html"
        viewer=staging/viewer_name
        viewer.parent.mkdir(parents=True,exist_ok=True)
        try:
            safe_text=(staging/target).read_text()
            binary_note=""
        except UnicodeDecodeError:
            safe_text="（二进制产物，不内联展示；原字节随包发布，SHA-256 "
            binary_note=hashlib.sha256((staging/target).read_bytes()).hexdigest()+"）"

        viewer.write_text('<!doctype html><html lang="zh-CN"><meta charset="utf-8"><title>'+html.escape(source["label"])+'</title><style>body{font:16px/1.8 sans-serif;max-width:1100px;margin:45px auto;padding:0 20px}pre{white-space:pre-wrap;overflow-wrap:anywhere;font:14px/1.7 monospace}</style><a href="../index.html">返回索引</a><h1>'+html.escape(source["id"]+" "+source["label"])+'</h1><p>状态：'+html.escape(source["state"])+'</p><pre>'+html.escape(safe_text+binary_note)+'</pre></html>')
        evidence_links.append('<li><a href="'+viewer_name+'">'+html.escape(source["id"]+" "+source["label"])+'</a> · '+html.escape(source["state"])+'</li>')
    for extra_path in data.get("support_extra_paths",[]):
        copy_file(REPOSITORY/extra_path,"evidence/files/"+extra_path,"binary" if Path(extra_path).name in {"input.csv","samples.csv","normalized.csv"} else "text")
    own_sources=["scripts/platform_stats/stats_csv.c","scripts/run_stats_battery.sh","src/timing_statistics.c","src/kernel.c","src/mlkem.c","src/random.c","src/inputs.c","include/timing_statistics.h","include/inputs.h","include/mlkem.h","include/baseline_config.h","tests/test_stats_battery.sh"]
    for source_path in own_sources:
        copy_file(REPOSITORY/source_path,"source/"+source_path)
    for source_root in [REPOSITORY/"vendor/mlkem-native/mlkem",REPOSITORY/"fixtures/early_reject_memcmp",REPOSITORY/"tests/fixtures/platform_stats"]:
        for source_path in sorted(source_root.rglob("*")):
            if source_path.is_file() and "__pycache__" not in source_path.parts:
                copy_file(source_path,"source/"+str(source_path.relative_to(REPOSITORY)),"binary")
    copy_file(REPOSITORY/"vendor/mlkem-native/LICENSE","source/vendor/mlkem-native/LICENSE","binary")
    replay_inputs=[]
    for case_name in ["primary-vulnerable","primary-fixed","seed-424242-vulnerable","seed-424242-fixed","cpu-6-vulnerable","cpu-6-fixed"]:
        source_path="docs/evidence/mona-wire-20261016/local-qualification/m1/"+case_name+"/input.csv"
        replay_inputs.append({"name":"m1-"+case_name,"path":source_path,"format":"wide","class0":"class0_ns","class1":"class1_ns","reheader":True})
    replay_inputs.extend(data.get("replay_inputs",[]))
    for item in replay_inputs:
        if not re.fullmatch(r"[a-zA-Z0-9-]+",item["name"]):
            raise ValueError("unsafe replay name")
        copy_file(REPOSITORY/item["path"],"data/"+item["name"]+".csv","binary")
    cmake_text='''cmake_minimum_required(VERSION 3.21)
project(platform_offline_support LANGUAGES C)
include(CTest)
set(CMAKE_C_STANDARD 11)
set(CMAKE_C_STANDARD_REQUIRED ON)
set(CMAKE_C_EXTENSIONS OFF)
add_library(support_reference STATIC source/src/kernel.c source/src/mlkem.c source/src/random.c source/src/inputs.c)
target_include_directories(support_reference PUBLIC source/include source/vendor/mlkem-native/mlkem)
target_compile_definitions(support_reference PUBLIC MLK_CONFIG_FILE="baseline_config.h")
add_executable(platform_stats source/scripts/platform_stats/stats_csv.c source/src/timing_statistics.c)
target_link_libraries(platform_stats PRIVATE support_reference)
if(UNIX)
    target_link_libraries(platform_stats PRIVATE m)
endif()
add_subdirectory(source/fixtures/early_reject_memcmp)
file(CHMOD "${CMAKE_CURRENT_SOURCE_DIR}/source/scripts/run_stats_battery.sh" PERMISSIONS OWNER_READ OWNER_WRITE OWNER_EXECUTE GROUP_READ GROUP_EXECUTE WORLD_READ WORLD_EXECUTE)
add_test(NAME support_stats_qualification COMMAND sh "${CMAKE_CURRENT_SOURCE_DIR}/source/tests/test_stats_battery.sh" "$<TARGET_FILE:platform_stats>" "${CMAKE_CURRENT_SOURCE_DIR}/source" "-")
set_tests_properties(support_stats_qualification PROPERTIES ENVIRONMENT "A113_TEST_TMPDIR=${CMAKE_CURRENT_BINARY_DIR}/test-tmp")
'''
    (staging/"CMakeLists.txt").write_text(cmake_text)
    canonical_build=REPOSITORY/"build/platform-report-s8"/("canonical-"+arguments.revision)
    canonical_build.mkdir()
    with (canonical_build/"build.log").open("w") as log_file:
        for command in [["cmake","-S",str(staging),"-B",str(canonical_build),"-DCMAKE_BUILD_TYPE=RelWithDebInfo"],["cmake","--build",str(canonical_build),"--parallel","2"],["ctest","--test-dir",str(canonical_build),"--output-on-failure"]]:
            subprocess.run(command,check=True,stdout=log_file,stderr=subprocess.STDOUT)
    replay_lines=['#!/bin/sh','set -eu','package_root=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)','output_root=$1','if [ -e "$output_root" ]; then printf "%s\\n" "New output directory required" >&2; exit 2; fi','mkdir -p "$output_root"','output_root=$(CDPATH= cd -- "$output_root" && pwd -P)','cmake -S "$package_root" -B "$output_root/build" -DCMAKE_BUILD_TYPE=RelWithDebInfo','cmake --build "$output_root/build" --parallel 2','ctest --test-dir "$output_root/build" --output-on-failure']
    for item in replay_inputs:
        original=(staging/"data"/(item["name"]+".csv")).read_bytes()
        canonical_input=canonical_build/(item["name"]+".csv")
        canonical_input.write_bytes(b"class0_ns,class1_ns\n"+original.split(b"\n",1)[1] if item.get("reheader") else original)
        expected_dir=staging/"expected"/item["name"]
        expected_dir.mkdir(parents=True)
        subprocess.run([str(canonical_build/"platform_stats"),str(canonical_input),item["format"],item["class0"],item["class1"],str(expected_dir)],check=True)
        name=item["name"]
        replay_lines.append('mkdir "$output_root/'+name+'"')
        if item.get("reheader"):
            replay_lines.append('sed \'1s/.*/class0_ns,class1_ns/\' "$package_root/data/'+name+'.csv" > "$output_root/'+name+'/converted.csv"')
            input_argument='"$output_root/'+name+'/converted.csv"'
        else:
            input_argument='"$package_root/data/'+name+'.csv"'
        replay_lines.append('"$output_root/build/platform_stats" '+input_argument+' '+shlex.quote(item["format"])+" "+shlex.quote(item["class0"])+" "+shlex.quote(item["class1"])+ ' "$output_root/'+name+'"')
        for result_name in ["ci_welch.json","normalized.csv"]:
            replay_lines.append('cmp "$package_root/expected/'+name+'/'+result_name+'" "$output_root/'+name+'/'+result_name+'"')
    replay_lines.append('printf "%s\\n" "offline_replay=pass; hardware_collection=not_run; external_tools=not_reexecuted"')
    (staging/"reproduce.sh").write_text("\n".join(replay_lines)+"\n")
    (staging/"reproduce.sh").chmod(0o755)
    (staging/"REPRODUCE.md").write_text('# 离线复算\n\n运行 `sh reproduce.sh <不存在的新输出目录>`。只读取包内数据，构建现有 C11 统计工具并执行五项 CTest，再逐字比较 CI JSON 与归一化 CSV。原始数值 CSV 保持字节，M1 的派生宽表只在输出目录改表头以适配统计接口，不改数值。\n\n打包时 C 输出作为确定性复算参照，只检验打包/重建一致；统计功能另由已有手算 oracle 与拒绝测试检查，不能拿自产期望证明算法正确。外部 RTLF、Mona、dudect、Binsec 未在本入口重执行；不采硬件时间、不改频率、不需要联网。ML-KEM 依赖仅为原 C 统计共用代码的链接依赖，本入口不运行密码采集。\n\n需要 CMake>=3.21、C11 编译器、POSIX shell、awk、shasum、cmp、sed；报告重编译另需 XeLaTeX/ctex/Fandol。\n')
    (staging/"PROVENANCE.json").write_text(json.dumps({"policy":"new anonymous copies; originals untouched; numeric CSV raw bytes preserved; upstream license preserved","files":provenance},ensure_ascii=False,indent=2)+"\n")
    shutil.copyfile(DIRECTORY/"verify_package.py",staging/"verify_package.py")
    (staging/"index.html").write_text('<!doctype html><html lang="zh-CN"><meta charset="utf-8"><title>多泄漏平台匿名补充件</title><style>body{font:17px/1.9 sans-serif;max-width:1000px;margin:55px auto;padding:0 25px}li{margin:10px 0}</style><h1>多泄漏平台匿名补充件</h1><p>真实历史、人工校准、阴性候选分列；未运行不是未检出。</p><p><a href="report/index.html">离线报告</a> · <a href="report/report.pdf">PDF</a> · <a href="REPRODUCE.md">C 离线复算说明</a> · <a href="PROVENANCE.json">来源与匿名副本摘要</a> · <a href="MANIFEST.json">成员清单</a></p><ul>'+"".join(evidence_links)+'</ul><p>本包没有凭证、构建产物、活动脚本或远端依赖资源。许可不明确的统计工具源码未再分发。</p></html>')
    members=[]
    for path in sorted(staging.rglob("*")):
        if path.is_file():
            content=path.read_bytes()
            members.append({"path":str(path.relative_to(staging)),"bytes":len(content),"sha256":hashlib.sha256(content).hexdigest()})
    (staging/"MANIFEST.json").write_text(json.dumps({"revision":arguments.revision,"document_state":data["document_state"],"files":members},ensure_ascii=False,indent=2)+"\n")
    with zipfile.ZipFile(archive_path,"x",zipfile.ZIP_DEFLATED,compresslevel=9) as archive:
        for path in sorted(staging.rglob("*")):
            if path.is_file():
                entry=zipfile.ZipInfo(str(path.relative_to(staging)),date_time=(2026,10,16,0,0,0))
                entry.create_system=3
                entry.external_attr=(0o100755 if path.suffix==".sh" else 0o100644)<<16
                entry.compress_type=zipfile.ZIP_DEFLATED
                archive.writestr(entry,path.read_bytes())
    module_spec=importlib.util.spec_from_file_location("package_verifier",DIRECTORY/"verify_package.py")
    module=importlib.util.module_from_spec(module_spec)
    module_spec.loader.exec_module(module)
    verification=module.verify(archive_path)
    (DIRECTORY/(arguments.revision+"-verification.json")).write_text(json.dumps(verification,ensure_ascii=False,indent=2)+"\n")
    print(json.dumps({"zip":str(archive_path.relative_to(REPOSITORY)),**verification},ensure_ascii=False,indent=2))


if __name__ == "__main__":
    main()
