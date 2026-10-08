#!/usr/bin/env python3
"""把重写报告引用的记录打成匿名支撑包。

只读仓库里的原始证据，替换写进副本。封存 v3 不进入这个包。
"""

from __future__ import annotations

import hashlib
import posixpath
import re
import sys
import zipfile
from pathlib import Path

import check_materials

REPO_ROOT = check_materials.REPO_ROOT
ARCHIVE_DIR = REPO_ROOT / "deliverables/support/CACR2026EA16XZ-20261008"
ARCHIVE_NAME = "CACR2026EA16XZ-报告引用材料.zip"
BINARY_SUFFIXES = {
    ".png",
    ".pdf",
    ".zip",
    ".pptx",
    ".docx",
    ".jpg",
    ".jpeg",
    ".gif",
    ".webp",
    ".xls",
    ".xlsx",
}
REPLACEMENTS = (
    (b"/home/nss-marker/yhr/Cry", b"runner-01-work"),
    (b"/home/nss-marker", b"runner-01"),
    (b"/Users/yin/code/cryProject", b"runner-01-work"),
    (b"/Users/yin", b"runner-01"),
    (b"/home/ubuntu/cryproject-a113-20261007", b"runner-01-work"),
    (b"/home/ubuntu", b"runner-01"),
    (b"/tmp/cryproject-author-proxy-20261008.kSvlwt", b"runner-01-work"),
    (b"Linux nss-m ", b"Linux runner-01 "),
    (b"10.144.144.5", b"runner-01"),
    (b"yinhaoran0808@outlook.com", b"runner-01@example.invalid"),
    (b"Gowin-liuyin", b"runner-01"),
)
FORBIDDEN = (
    b"nss-marker",
    b"/home/nss-marker",
    b"/home/ubuntu",
    b"/Users/yin",
    b"yinhaoran",
    b"Gowin",
    b"10.144.144.5",
    b"nss@",
    b"Linux nss-m",
)
SUM_LINE = re.compile(r"^(\s*)([0-9a-f]{64})  (\S.*)$")


def is_manifest(path: Path) -> bool:
    name = path.name
    return name == "SHA256SUMS" or name.endswith(".SHA256SUMS")


def iter_records(cited: list[str]) -> list[Path]:
    records = []
    for cited_path in cited:
        source = REPO_ROOT / cited_path
        if source.is_file():
            records.append(source)
            continue
        for path in source.rglob("*"):
            if not path.is_file() or path.name.startswith(".") or path.name.startswith("~$"):
                continue
            records.append(path)
    return records


def anonymize(rel: str, payload: bytes) -> bytes:
    suffix = Path(rel).suffix.lower()
    if suffix in BINARY_SUFFIXES or b"\0" in payload[:4096]:
        for needle in FORBIDDEN:
            if needle in payload:
                raise RuntimeError(f"二进制文件含有身份信息，未改字节: {rel}")
        return payload
    rewritten = payload
    for old, new in REPLACEMENTS:
        rewritten = rewritten.replace(old, new)
    for needle in FORBIDDEN:
        if needle in rewritten:
            raise RuntimeError(f"匿名后仍有身份信息: {rel} {needle.decode()}")
    return rewritten


def resolve_listed(manifest_rel: str, listed: str, available: set[str]) -> str:
    if listed in available:
        return listed
    candidate = posixpath.normpath(posixpath.join(posixpath.dirname(manifest_rel), listed))
    if candidate in available:
        return candidate
    raise RuntimeError(f"{manifest_rel} 指向不在包内的文件: {listed}")


def rebuild_manifests(content: dict[str, bytes], manifests: dict[str, bytes]) -> None:
    available = set(content) | set(manifests)
    order = sorted(manifests, key=lambda rel: rel.count("/"), reverse=True)
    for rel in order:
        anonymized = anonymize(rel, manifests[rel]).decode("utf-8")
        newline = "\n" if anonymized.endswith("\n") else ""
        rebuilt = []
        for line in anonymized.splitlines():
            match = SUM_LINE.fullmatch(line)
            if match is None:
                if re.search(r"[0-9a-f]{64}", line):
                    raise RuntimeError(f"无法识别的摘要行: {rel}: {line}")
                rebuilt.append(line)
                continue
            prefix, _digest, listed = match.groups()
            if listed in available or posixpath.normpath(
                posixpath.join(posixpath.dirname(rel), listed)
            ) in available:
                target = resolve_listed(rel, listed, available)
                payload = content.get(target, manifests.get(target))
                if payload is None:
                    raise RuntimeError(f"缺少摘要目标: {target}")
                rebuilt.append(f"{prefix}{hashlib.sha256(payload).hexdigest()}  {listed}")
            elif listed.startswith("runner-01") or listed.startswith("/"):
                rebuilt.append(line)
            else:
                raise RuntimeError(f"{rel} 指向不在包内的文件: {listed}")
        manifests[rel] = ("\n".join(rebuilt) + newline).encode("utf-8")


def write_archive(entries: list[tuple[str, bytes]], destination: Path) -> None:
    destination.parent.mkdir(parents=True, exist_ok=True)
    with zipfile.ZipFile(destination, "w", compression=zipfile.ZIP_DEFLATED, compresslevel=6) as archive:
        for rel, payload in entries:
            info = zipfile.ZipInfo(rel, (2026, 10, 8, 0, 0, 0))
            info.compress_type = zipfile.ZIP_DEFLATED
            info.create_system = 3
            info.external_attr = 0o100644 << 16
            info.flag_bits = 0x800
            archive.writestr(info, payload)


def write_readme(destination: Path, digest: str, size: int, entry_count: int) -> None:
    text = f"""# CACR2026EA16XZ 报告引用材料

这个包是重写报告附录 A 点名记录的匿名副本，供报告复核。它不替换封存 v3，也不修改仓库里的原始证据。

- 文件：`{ARCHIVE_NAME}`
- SHA-256：`{digest}`
- 字节：{size}
- 条目：{entry_count}

包内路径与报告引用路径一致。文本里的本机账号路径已换成 `runner-01` / `runner-01-work`，与封存 v3 的匿名方式相同。个人路径替换之后，目录中的 SHA256SUMS 按匿名副本重新计算。原始证据目录的字节没有改动。

裸金属记录仍单独放在 `docs/evidence/baremetal-ryzen-20261008`，不并入 `docs/evidence/r07-linux-20261008`。调速器保持 powersave，频率没有锁定。这些记录不是频率锁定、恒时证明或竞赛签收。R02 与 R04 仍为部分签收。

包内没有 SSH 密码、审批意见、签名、盖章或运行界面截图。
"""
    (destination.parent / "README.md").write_text(text, encoding="utf-8")


def main() -> int:
    paragraphs = check_materials.extract_paragraphs(check_materials.DOCX)
    cited = check_materials.cited_records(paragraphs)
    content: dict[str, bytes] = {}
    manifests: dict[str, bytes] = {}
    for path in iter_records(cited):
        rel = path.relative_to(REPO_ROOT).as_posix()
        payload = path.read_bytes()
        if is_manifest(path):
            manifests[rel] = payload
        else:
            content[rel] = anonymize(rel, payload)
    rebuild_manifests(content, manifests)
    entries = sorted([*content.items(), *manifests.items()], key=lambda item: item[0])
    destination = ARCHIVE_DIR / ARCHIVE_NAME
    write_archive(entries, destination)
    digest = hashlib.sha256(destination.read_bytes()).hexdigest()
    write_readme(destination, digest, destination.stat().st_size, len(entries))
    print(f"archive={destination.relative_to(REPO_ROOT)}")
    print(f"sha256={digest}")
    print(f"bytes={destination.stat().st_size}")
    print(f"entries={len(entries)}")
    print(f"manifests={len(manifests)}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
