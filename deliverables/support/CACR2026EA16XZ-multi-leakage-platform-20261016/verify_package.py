#!/usr/bin/env python3
"""检查实际 ZIP 的成员、摘要、直接身份字串和离线 HTML 链接。"""
import argparse
import hashlib
import json
import re
import stat
import zipfile
from html.parser import HTMLParser
from pathlib import PurePosixPath
from urllib.parse import unquote, urlsplit

PRIVATE_PATTERNS = [rb"/Users/[A-Za-z0-9_.-]+(?:/|$)", rb"/home/[A-Za-z0-9_.-]+(?:/|$)"]


class LocalHtmlParser(HTMLParser):
    def __init__(self):
        super().__init__()
        self.links = []
        self.identifiers = set()
        self.in_style = False

    def handle_starttag(self,tag,attributes):
        if tag.lower() in ("script","iframe","object","embed"):
            raise ValueError("active HTML element")
        if tag.lower() == "style":
            self.in_style = True
        for name,value in attributes:
            if name.lower().startswith("on"):
                raise ValueError("active HTML attribute")
            if name.lower() in ("href","src") and value:
                self.links.append(value)
            if name.lower() == "id":
                self.identifiers.add(value)
            if name.lower() == "style" and re.search(r"url\(|@import",value or "",re.I):
                raise ValueError("external CSS dependency")

    def handle_endtag(self,tag):
        if tag.lower() == "style":
            self.in_style = False

    def handle_data(self,data):
        if self.in_style and re.search(r"url\(|@import",data,re.I):
            raise ValueError("external CSS dependency")


def verify(path):
    with zipfile.ZipFile(path) as archive:
        names = archive.namelist()
        if len(names) != len(set(names)):
            raise ValueError("duplicate ZIP members")
        for item in archive.infolist():
            member_path = PurePosixPath(item.filename)
            if member_path.is_absolute() or ".." in member_path.parts or "\\" in item.filename or item.is_dir() or stat.S_ISLNK(item.external_attr >> 16):
                raise ValueError("unsafe ZIP member: "+item.filename)
        if archive.testzip() is not None:
            raise ValueError("ZIP CRC mismatch")
        manifest = json.loads(archive.read("MANIFEST.json"))
        expected = {item["path"]:item for item in manifest["files"]}
        if set(names) != set(expected) | {"MANIFEST.json"}:
            raise ValueError("manifest member set mismatch")
        link_count = 0
        for name in names:
            content = archive.read(name)
            if name != "MANIFEST.json":
                entry = expected[name]
                if hashlib.sha256(content).hexdigest() != entry["sha256"] or len(content) != entry["bytes"]:
                    raise ValueError("member hash mismatch: "+name)
            if PurePosixPath(name).suffix.lower() in (".json",".md",".txt",".tex",".html",".svg",".csv",".log",".sh",".cmake",".c",".h",".py"):
                if any(re.search(pattern,content) for pattern in PRIVATE_PATTERNS):
                    raise ValueError("direct identity marker: "+name)
            if name.endswith(".html"):
                text = content.decode("utf-8")
                parsed_html = LocalHtmlParser()
                parsed_html.feed(text)
                for target in parsed_html.links:
                    parsed = urlsplit(target)
                    if parsed.scheme or parsed.netloc:
                        raise ValueError("remote HTML dependency: "+target)
                    if not parsed.path:
                        if parsed.fragment and unquote(parsed.fragment) not in parsed_html.identifiers:
                            raise ValueError("missing local HTML anchor")
                        continue
                    path_parts = list(PurePosixPath(name).parent.parts)
                    for path_part in PurePosixPath(unquote(parsed.path)).parts:
                        if path_part == "..":
                            if not path_parts:
                                raise ValueError("HTML link escapes root")
                            path_parts.pop()
                        elif path_part != ".":
                            path_parts.append(path_part)
                    if "/".join(path_parts) not in names:
                        raise ValueError("missing HTML target: "+target+" in "+name)
                    link_count += 1
        return {"status":"pass","members":len(names),"hashed_members":len(expected),"local_html_links":link_count,"direct_identity_markers":0,"zip_sha256":hashlib.sha256(open(path,"rb").read()).hexdigest(),"scope":"direct byte/text patterns; PDF semantic metadata audited separately; public-content linkage not excluded"}


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("zip_file")
    arguments = parser.parse_args()
    print(json.dumps(verify(arguments.zip_file),ensure_ascii=False,indent=2))
