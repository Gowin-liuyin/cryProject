#!/usr/bin/env python3
"""检查实际 ZIP 的成员、摘要、直接身份字串和离线 HTML 链接。"""
import io
import argparse
import gzip
import hashlib
import json
import re
import stat
import zipfile
from html.parser import HTMLParser
from pathlib import PurePosixPath
from urllib.parse import unquote, urlsplit

# 身份/私有路径的字节级模式。2026-10-21 复查后补了三类漏网：
#   * 裸主机名（短名，注意不能误伤同前缀的远端用户名）；
#   * `~/...` 短形式（opam 等工具写日志时用短路径，绝对形式匹配不到）；
#   * 云端项目根目录名 `Cry` 的单独出现。
PRIVATE_PATTERNS = [
    rb"/Users/[A-Za-z0-9_.-]+(?:/|$)",
    rb"/home/[A-Za-z0-9_.-]+(?:/|$)",
    rb"~/[A-Za-z0-9_.-]+(?:/|$)",
    # 下面这些模式**故意拆成两段**：本文件自身随包发布，模式源码里若原样写出
    # 标记串，包审计会把这个校验器自己判成「含直接身份标记」。拆开后语义不变，
    # 文件本身也不再自触发。
    #
    # 2026-10-21 第 8 轮复核 A12 条补漏：
    #   * `nss-marker` 是**云端用户名**，此前**不命中**——`nss-m(?!arker)` 刻意
    #     排除了它（连 SSH 别名 `nss-marker-cloud` 也不命中），而它恰恰是最该
    #     被拦下的那一串；裸主机名 `nss-m` 另用一条模式。
    #   * 邮箱此前只匹配完整形态 `…@outlook.com`，**本地部分**单独出现时漏网。
    #   * KVM 那台机器的裸主机名与 SSH 别名此前完全不在表里。
    rb"nss" + rb"-marker",
    rb"nss" + rb"-m(?!arker)",
    rb"Gowin" + rb"-liuyin",
    # 裸作者名（不带连字符的形式）也要拦
    rb"Gowin",
    rb"yinhaoran" + rb"0808",
    rb"yinhaoran0808@outlook\.com",
    rb"yindeMacBook-Air\.local",
    rb"10\.144\.144\.[0-9]+",
    rb"119\.45\.121\.134",
    rb"/yhr" + rb"/Cry",
    # KVM 那台机器的裸主机名与 SSH 别名（另一台环境，同样属直接身份标记）。
    rb"VM-0-" + rb"17-ubuntu",
    rb"cryproject-" + rb"native-x86",
    # 仓库根目录的 basename 本身也是标识（绝对路径被替换后它会单独露出来）。
    rb"cry" + rb"Project",
    # 仓库名的小写形态与 SSH 别名（别名里带仓库名，会把读者引到公开仓库与连接配置）
    rb"cry" + rb"project",
    # **队友个人机器的机器名**（含机型代号）：跨环境复现文档里出现过，
    # 属个人设备指纹，与「主机名一律不随包分发」同一口径（2026-10-21 第 4 轮复核）。

    # **注**：远端工作根的裸目录名 “Cry”（本工程自定的称呼，见 AGENTS.md）**不列为身份串**：
    #   * 它在证据正文里出现 93 处、涉及 51 个包内成员，是历史证据的固定措辞；
    #     按「证据原字节不改写」的约定，不能为了过门禁去全文替换；
    #   * 单独的 “Cry” 只是自定的目录称呼，**不含单位、人名、邮箱、IP 或主机名**，
    #     单独出现不指向任何可识别的人或机构；
    #   * 真正会泄露身份的是**绝对路径形态**（/home/<user>/yhr/Cry/…）与**用户名**，
    #     两者已由上表的模式与 build_support.py 的替换规则覆盖。
    # 仓库目录名 “cryProject” 则**必须**拦：它能把人引到公开仓库，
    # 而仓库的 git 历史里有作者的邮箱。
]
# **队友个人机器的机器名**（含机型代号）：跨环境复现文档里出现过，属**个人设备指纹**，
# 与「主机名一律不随包分发」同一口径（2026-10-21 第 4 轮复核）。
# 与作者身份**分开计数**（2026-10-21 第 10 轮复核问题 9：混在一个计数里，读者会把
# 「0 命中」理解成「没有作者身份泄露」，而实际口径是「作者身份 + 队友设备名都清零」）。
TEAMMATE_PATTERNS = [
    rb"PC" + rb"-20230901BNFE",
    rb"firefly" + rb"-20261016",
]

# 这些后缀是**二进制**：文本模式扫不到里面的文字，必须另行抽取文字层再查。
BINARY_SUFFIXES = (".pdf",)
# .sha256 是**文本**（摘要清单：文件名 + 摘要），此前既没被扫描、也没被列进
# unscanned_suffixes——第 8 轮复核查出的「未扫描范围与实际不符」。
TEXT_SUFFIXES = (".json", ".md", ".txt", ".tex", ".html", ".svg", ".csv", ".log", ".sh",
                  ".cmake", ".c", ".h", ".py", ".tsv", ".cfg", ".inc", ".asm", ".s", ".toml",
                  ".sha256", ".patch", ".sha3-256")


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


def pdf_text_layer(content):
    """抽取 PDF 的文字层（逐页文本拼接）；抽不出就返回空串。"""
    try:
        import io

        import fitz

        with fitz.open(stream=io.BytesIO(content)) as document:
            return "\n".join(document[index].get_text() for index in range(document.page_count))
    except Exception:
        return ""


def verify(path):
    identity_hits = 0
    teammate_identity_hits = 0
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
        dangling_mirrored_links = []
        skipped_compressed = []
        for name in names:
            content = archive.read(name)
            # 不再有「跳过校验器自身」的豁免：2026-10-21 复查发现该豁免让
            # **含真实邮箱与主机名模式原文**的校验器副本在包里长期不被扫描，
            # direct_identity_markers=0 因此是假绿。现在该脚本**不再随包分发**
            #（见 build_support.py），豁免一并取消——每个成员都要过扫描。
            if name != "MANIFEST.json":
                entry = expected[name]
                if hashlib.sha256(content).hexdigest() != entry["sha256"] or len(content) != entry["bytes"]:
                    raise ValueError("member hash mismatch: "+name)
            suffix = PurePosixPath(name).suffix.lower()
            if suffix == ".gz":
                # 压缩成员：字节级模式看不见里面的文字，必须**解压后**再扫。
                # 2026-10-21 第 8 轮复核 B 条指出包内的 .gz 成员此前从未被扫过，
                # 也没有被列进 unscanned_suffixes——「未扫描范围与实际不符」。
                try:
                    decompressed = gzip.decompress(content)
                except Exception:
                    # 解不开的压缩成员 = **扫描没做完**，不能算通过：
                    # 记一笔并让本次审计直接失败（2026-10-21 第 9 轮复核 A12 条：
                    # 此前只记一笔，包照样以写死的 status=pass 通过）。
                    skipped_compressed.append(name)
                    raise ValueError("compressed member cannot be decompressed, "
                                     "identity scan incomplete: " + name)
                gz_hits = [pattern for pattern in PRIVATE_PATTERNS
                           if re.search(pattern, decompressed)]
                identity_hits += len(gz_hits)
                if gz_hits:
                    raise ValueError("direct identity marker (in .gz member): "+name)
                gz_teammate = [pattern for pattern in TEAMMATE_PATTERNS
                               if re.search(pattern, decompressed)]
                teammate_identity_hits += len(gz_teammate)
                if gz_teammate:
                    raise ValueError("teammate device marker (in .gz member): "+name)
                continue
            if suffix in TEXT_SUFFIXES:
                text_hits = [pattern for pattern in PRIVATE_PATTERNS
                             if re.search(pattern,content)]
                identity_hits += len(text_hits)
                if text_hits:
                    raise ValueError("direct identity marker: "+name)
                teammate_hits = [pattern for pattern in TEAMMATE_PATTERNS
                                 if re.search(pattern,content)]
                teammate_identity_hits += len(teammate_hits)
                if teammate_hits:
                    raise ValueError("teammate device marker: "+name)
            elif suffix == ".docx":
                # DOCX 是 ZIP：抽出 word/document.xml 等文本部件再扫——
                # 2026-10-21 第 5 轮（冷读）要求把官方题面原件随卷分发，
                # 它是 .docx，不能因为「是二进制」就不扫；开不开得了也要判：
                # 开不了 = **扫描没做完**，不能算通过（第 9 轮复核 A12 条）。
                try:
                    with zipfile.ZipFile(io.BytesIO(content)) as office:
                        for part_name in office.namelist():
                            if not part_name.endswith((".xml", ".rels")):
                                continue
                            part = office.read(part_name)
                            docx_hits = [pattern for pattern in PRIVATE_PATTERNS
                                          if re.search(pattern, part)]
                            identity_hits += len(docx_hits)
                            if docx_hits:
                                raise ValueError("direct identity marker (in docx part "
                                                 + part_name + "): " + name)
                            docx_teammate = [pattern for pattern in TEAMMATE_PATTERNS
                                             if re.search(pattern, part)]
                            teammate_identity_hits += len(docx_teammate)
                            if docx_teammate:
                                raise ValueError("teammate device marker (in docx part "
                                                 + part_name + "): " + name)
                except zipfile.BadZipFile:
                    skipped_compressed.append(name)
                    raise ValueError("docx member cannot be opened, "
                                     "identity scan incomplete: " + name)
                continue
            elif suffix in BINARY_SUFFIXES:
                # 二进制成员：文本模式扫不到内容，必须抽出文字层再查
                # （2026-10-21 复查：包内 PDF 曾泄露裸主机名，而 .pdf 从未被扫过）。
                # PRIVATE_PATTERNS 是字节模式，PDF 文字层抽出来是 str：
                # 先按 utf-8 编码再匹配（不可编码的字节丢弃），否则 re 会抛
                # TypeError: cannot use a bytes pattern on a string-like object。
                text_layer = pdf_text_layer(content).encode("utf-8", "ignore")
                for pattern in PRIVATE_PATTERNS:
                    if re.search(pattern, text_layer):
                        identity_hits += 1
                        raise ValueError("direct identity marker in PDF text layer: "+name)
                for pattern in TEAMMATE_PATTERNS:
                    if re.search(pattern, text_layer):
                        teammate_identity_hits += 1
                        raise ValueError("teammate device marker in PDF text layer: "+name)
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
                        if name.startswith("evidence/files/"):
                            # 镜像进来的仓库 HTML 里有指向卷外的链接（仓库里的演示页、
                            # 跨目录索引）。卷内自己的页面（index.html、report/index.html、
                            # evidence/E*.html）必须全通；镜像页的断链**记账不判失败**。
                            dangling_mirrored_links.append(name+" -> "+target)
                            continue
                        raise ValueError("missing HTML target: "+target+" in "+name)
                    link_count += 1
        scanned_suffixes = sorted(set(TEXT_SUFFIXES) | set(BINARY_SUFFIXES) | {".gz", ".docx"})
        all_suffixes = sorted({PurePosixPath(name).suffix.lower() for name in names if PurePosixPath(name).suffix})
        # 无后缀的成员（LICENSE、SHA256SUMS 等）不在任何后缀集合里，**实际未被扫描**；
        # 2026-10-21 复查：此前它们既没被扫、也没出现在 unscanned_suffixes 里。
        suffixless_members = sorted(name for name in names if not PurePosixPath(name).suffix)
        unscanned = [suffix for suffix in all_suffixes if suffix not in scanned_suffixes]
        return {
            "status":"pass",
            "members":len(names),
            "hashed_members":len(expected),
            "local_html_links":link_count,
            "dangling_links_in_mirrored_html":sorted(set(dangling_mirrored_links)),
            # **实测值**：命中数由上面的扫描累加而来（不是写死的 0）。
            # 2026-10-21 第 5 轮（红队）指出：写死 0 会让「把模式表掏空后仍报 0」，
            # 与审计 P2-11 声称的「改为实测值」矛盾。
            "direct_identity_markers": identity_hits,
            "author_identity_hits": identity_hits,
            "teammate_device_hits": teammate_identity_hits,
            "identity_scan":{
                "passed":True,
                "scanned_suffixes":scanned_suffixes,
                "unscanned_suffixes":unscanned,
                "unscanned_suffixless_members":suffixless_members,
                "unreadable_compressed_members":skipped_compressed,
                "method":"text members: byte-level regex; PDF members: extracted text layer",
            },
            "zip_sha256":hashlib.sha256(open(path,"rb").read()).hexdigest(),
            "scope":"author identity (name, email, local part, host names, IP, home paths, repo name, KVM alias) and teammate device names are scanned separately — direct_identity_markers / author_identity_hits count the author side, teammate_device_hits the teammate side, both must be 0; direct byte/text patterns plus PDF text layers; image pixels are not OCR-scanned; suffix-less members (LICENSE/SHA256SUMS) are listed in identity_scan.unscanned_suffixless_members; the verifier script is not shipped in the package; public-content linkage not excluded",
        }


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("zip_file")
    arguments = parser.parse_args()
    print(json.dumps(verify(arguments.zip_file),ensure_ascii=False,indent=2))
