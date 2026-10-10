#!/usr/bin/env python3
"""只读核对当前候选，不签目录页码、视觉或匿名实包。"""

import argparse
import csv
import hashlib
import ipaddress
import json
from pathlib import Path
import re
import sys
from xml.parsers import expat
import zipfile

from lxml import etree


WORK = Path(__file__).resolve().parent
REPO = WORK.parent.parent
NS = {
    "w": "http://schemas.openxmlformats.org/wordprocessingml/2006/main",
    "w14": "http://schemas.microsoft.com/office/word/2010/wordml",
    "m": "http://schemas.openxmlformats.org/officeDocument/2006/math",
    "r": "http://schemas.openxmlformats.org/officeDocument/2006/relationships",
}
SOURCE_SHA = "96e2de8af1238518f8d754cd9f969a4e82499d8b89552e143128aeba8da861e6"
CANDIDATE_SHA = "db7a06752acb743a6b0ef9cfbe25d66e7126ac315b1626eb5abe6b3a9fcebca0"
TARGETS = {24, 50, 90, 98, 131, 153, 185, 200, 249, 257, 259, 274, 415, 416, 422, 423, 448}
PUBLIC_COMMITS = {
    "b3ba7b32773e657dd37f6f87bce82528459ad8a4": "mlkem-native fixed upstream",
    "dc269651fb2567e46755cfb2a13d3875592968b5": "dudect fixed upstream",
    "7f4d5dc162b77c362a34a0d52949f7a3e1b16d81": "clangover fixed upstream",
}


def sha(value):
    return hashlib.sha256(value).hexdigest()


def serial(element):
    return etree.tostring(element)


def text(element):
    return "".join(element.xpath(".//w:t/text()", namespaces=NS))


def ordered_positions(needles, haystack):
    positions = []
    after = 0
    for needle in needles:
        found = next((index for index in range(after, len(haystack)) if haystack[index] == needle), None)
        if found is None:
            return None
        positions.append(found)
        after = found + 1
    return positions


def direct_body_bytes(xml_bytes):
    parser = expat.ParserCreate()
    depth = 0
    body_depth = None
    active = None
    result = []

    def opening_end(start):
        quote = None
        for index in range(start, len(xml_bytes)):
            char = xml_bytes[index]
            if quote is not None:
                if char == quote:
                    quote = None
            elif char in (34, 39):
                quote = char
            elif char == 62:
                return index + 1
        raise ValueError("unterminated XML tag")

    def begin(name, attrs):
        nonlocal depth, body_depth, active
        depth += 1
        if name == "w:body":
            body_depth = depth
        elif body_depth is not None and depth == body_depth + 1:
            start = parser.CurrentByteIndex
            end = opening_end(start)
            active = (start, end, xml_bytes[start:end].rstrip().endswith(b"/>"))

    def end(name):
        nonlocal depth, body_depth, active
        if body_depth is not None and depth == body_depth + 1:
            start, open_end, self_closed = active
            stop = open_end if self_closed else opening_end(parser.CurrentByteIndex)
            result.append(xml_bytes[start:stop])
            active = None
        if name == "w:body":
            body_depth = None
        depth -= 1

    parser.StartElementHandler = begin
    parser.EndElementHandler = end
    parser.Parse(xml_bytes, True)
    return result


def raw_features(xml_bytes, prefix, name):
    pattern = rb"<" + prefix + rb":" + name + rb"(?:\s[^>]*)?>.*?</" + prefix + rb":" + name + rb">"
    return re.findall(pattern, xml_bytes, re.DOTALL)


def enabled(element):
    return element is not None and element.get("{" + NS["w"] + "}val", "1") not in {"0", "false", "off"}


def table_rows(element):
    return [[text(cell) for cell in row.findall("w:tc", NS)] for row in element.findall("w:tr", NS)]


def csv_rows(path):
    with path.open(newline="") as stream:
        return list(csv.DictReader(stream))


def selfcheck():
    assert ordered_positions([b"a", b"a", b"b"], [b"a", b"x", b"a", b"b"]) == [0, 2, 3]
    assert ordered_positions([b"a", b"b"], [b"b", b"a"]) is None
    sample = b'<w:document xmlns:w="urn:w"><w:body><w:p/><w:p><w:r><w:t>x</w:t></w:r></w:p><w:bookmarkStart w:id="1"/></w:body></w:document>'
    assert direct_body_bytes(sample) == [b"<w:p/>", b"<w:p><w:r><w:t>x</w:t></w:r></w:p>", b'<w:bookmarkStart w:id="1"/>']
    assert table_rows(etree.fromstring(b'<w:tbl xmlns:w="' + NS["w"].encode() + b'"><w:tr><w:tc><w:p><w:r><w:t>20</w:t></w:r></w:p></w:tc></w:tr></w:tbl>')) == [["20"]]
    return {"ordered_duplicate_subsequence": "passed", "out_of_order_rejected": "passed", "literal_body_ranges_and_self_closing_nodes": "passed", "cell_extraction": "passed"}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--candidate", type=Path, default=WORK / "CACR2026EA16XZ-作品设计报告-四项研究整合候选版.docx")
    parser.add_argument("--expected-sha", default=CANDIDATE_SHA)
    parser.add_argument("--output", type=Path, default=WORK / "candidate-verification.json")
    args = parser.parse_args()
    if args.output.exists():
        raise SystemExit("refuse to overwrite earlier verification; choose a fresh --output")
    result = {"kind": "independent_read_only_candidate_verification", "selfcheck": selfcheck(), "checks": [], "failures": [], "scope": {"C_runs": 0, "SSH": False, "rendering": False, "DOCX_mutation": False, "page_numbers_signed_off": False, "visual_signed_off": False, "anonymous_distribution_signed_off": False, "external_peer_review": False}}

    def check(name, condition, details=None):
        result["checks"].append({"name": name, "passed": bool(condition), "details": details})
        if not condition:
            result["failures"].append(name)

    original = REPO / "deliverables/research/aris-report-g2-20261010/CACR2026EA16XZ-作品设计报告-匿名版.docx"
    source_bytes = original.read_bytes()
    candidate_bytes = args.candidate.read_bytes()
    result["source"] = {"path": str(original), "sha256": sha(source_bytes), "bytes": len(source_bytes)}
    result["candidate"] = {"path": str(args.candidate), "sha256": sha(candidate_bytes), "bytes": len(candidate_bytes)}
    result["verifier_sha256"] = sha(Path(__file__).read_bytes())
    check("49_page_source_identity", sha(source_bytes) == SOURCE_SHA)
    check("candidate_identity", sha(candidate_bytes) == args.expected_sha)
    snapshots = {}
    for role, path in [("source", original), ("candidate", args.candidate)]:
        with zipfile.ZipFile(path) as archive:
            names = archive.namelist()
            check(role + "_unique_safe_members", len(names) == len(set(names)) and all(not name.startswith("/") and ".." not in Path(name).parts for name in names))
            check(role + "_ZIP_CRC", archive.testzip() is None)
            snapshots[role] = {name: archive.read(name) for name in names}
    source_parts, candidate_parts = snapshots["source"], snapshots["candidate"]
    check("identical_package_member_names_and_order", list(source_parts) == list(candidate_parts))
    part_changes = [name for name in source_parts if source_parts[name] != candidate_parts.get(name)]
    check("only_document_and_app_may_change", set(part_changes) <= {"word/document.xml", "docProps/app.xml"}, part_changes)
    unchanged_parts = {name: sha(value) for name, value in source_parts.items() if name not in {"word/document.xml", "docProps/app.xml"}}
    result["unchanged_package_parts"] = unchanged_parts

    xml_parser = etree.XMLParser(resolve_entities=False, no_network=True)
    source_doc = etree.fromstring(source_parts["word/document.xml"], xml_parser)
    candidate_doc = etree.fromstring(candidate_parts["word/document.xml"], xml_parser)
    source_body = list(source_doc.find("w:body", NS))
    candidate_body = list(candidate_doc.find("w:body", NS))
    initial = json.loads((WORK / "initial-structure.json").read_text())
    edits = json.loads((WORK / "authoring-edits.json").read_text())
    result["contracts"] = {name: sha((WORK / name).read_bytes()) for name in ["initial-structure.json", "authoring-edits.json", "artifact.md", "NEW_EVIDENCE_FACT_CHECK.json"]}
    check("initial_source_hash_is_bound", initial["source_docx_sha256"] == SOURCE_SHA)
    check("initial_original_child_inventory_independently_reproduced", initial["original_body_child_hashes"] == [sha(serial(element)) for element in source_body])
    check("modified_targets_exactly_declared", set(initial["modified_base_body_indices"]) == TARGETS)
    expected_retained = sorted(set(range(len(source_body))) - TARGETS)
    check("retained_indices_are_exact_complement", initial["retained_base_body_indices"] == expected_retained)
    preserved = [serial(source_body[index]) for index in expected_retained]
    positions = ordered_positions(preserved, [serial(element) for element in candidate_body])
    check("all_non_target_body_children_preserved_in_order", positions is not None, {"count": len(preserved), "candidate_positions": positions})
    source_ranges = direct_body_bytes(source_parts["word/document.xml"])
    candidate_ranges = direct_body_bytes(candidate_parts["word/document.xml"])
    check("literal_body_range_parser_covers_direct_children", len(source_ranges) == len(source_body) and len(candidate_ranges) == len(candidate_body))
    raw_positions = ordered_positions([source_ranges[index] for index in expected_retained], candidate_ranges)
    check("non_target_direct_children_literal_XML_bytes_preserved", raw_positions is not None, {"count": len(expected_retained)})

    for name, xpath, expected_old, expected_new, prefix, local in [
        ("sections", ".//w:sectPr", 4, 4, b"w", b"sectPr"),
        ("drawings", ".//w:drawing", 19, 19, b"w", b"drawing"),
        ("math", ".//m:oMath", 64, 70, b"m", b"oMath"),
    ]:
        old = source_doc.findall(xpath, NS)
        new = candidate_doc.findall(xpath, NS)
        old_raw = raw_features(source_parts["word/document.xml"], prefix, local)
        new_raw = raw_features(candidate_parts["word/document.xml"], prefix, local)
        check(name + "_counts", len(old) == expected_old and len(new) == expected_new, {"source": len(old), "candidate": len(new)})
        check(name + "_source_inventory", initial["original_features"][name] == [sha(serial(element)) for element in old])
        preserved_positions = ordered_positions([serial(element) for element in old], [serial(element) for element in new])
        check(name + "_original_serializations_in_order", preserved_positions is not None, preserved_positions)
        check(name + "_literal_original_XML_bytes_in_order", len(old_raw) == expected_old and len(new_raw) == expected_new and ordered_positions(old_raw, new_raw) is not None)

    source_tables = source_doc.findall(".//w:tbl", NS)
    new_tables = candidate_doc.findall(".//w:tbl", NS)
    check("table_counts", len(source_tables) == 23 and len(new_tables) == 26, {"source": len(source_tables), "candidate": len(new_tables)})
    old_index_table = next(table for table in source_tables if table_rows(table)[0] == ["编号", "材料与位置", "本文使用范围"])
    new_index_table = next(table for table in new_tables if table_rows(table)[0] == ["编号", "材料与位置", "本文使用范围"])
    protected_tables = [table for table in source_tables if table is not source_tables[0] and table is not old_index_table]
    check("21_non_target_tables_preserved_in_order", ordered_positions([serial(table) for table in protected_tables], [serial(table) for table in new_tables]) is not None, len(protected_tables))
    old_rows = old_index_table.findall("w:tr", NS)
    index_rows = new_index_table.findall("w:tr", NS)
    check("old_index_rows_literal_serialization_preserved", len(index_rows) == len(old_rows) + 4 and all(serial(old) == serial(new) for old, new in zip(old_rows, index_rows)), {"old": len(old_rows), "new": len(index_rows)})
    check("new_index_rows_exact", table_rows(new_index_table)[-4:] == [
        ["G2-T", "docs/evidence/g2-timing-description-20261010", "表5.12；式5-7；54行原值描述"],
        ["W-F", "docs/research/aris-weak-mean-finite-20261010", "第4.5节；原区间有限下界与解析复核"],
        ["RAW-C", "docs/evidence/raw-clock-20261010", "表5.13；303000空pair及18行描述"],
        ["REP-6", "docs/evidence/ordinary-repeatability-20261010", "表5.14；两批六进程及36行描述"],
    ])
    old_abstract_rows = source_tables[0].findall("w:tr", NS)
    abstract_rows = new_tables[0].findall("w:tr", NS)
    check("only_summary_row_changes_in_abstract_table", len(old_abstract_rows) == len(abstract_rows) == 6 and all(serial(old_abstract_rows[index]) == serial(abstract_rows[index]) for index in [0, 1, 2, 3, 5]))

    for edit in edits:
        index = edit.get("base_body_index")
        if "old_xml_sha256" in edit:
            check("author_edit_old_" + edit["slot"], sha(serial(source_body[index])) == edit["old_xml_sha256"])
        if "new_xml_sha256" in edit:
            check("author_edit_new_" + edit["slot"], edit["new_xml_sha256"] in [sha(serial(element)) for element in candidate_body])
        if "paragraph_id" in edit:
            matches = candidate_doc.xpath(".//w:p[@w14:paraId=$value]", namespaces=NS, value=edit["paragraph_id"])
            check("author_added_paragraph_" + edit["paragraph_id"], len(matches) == 1 and ("added" not in edit or text(matches[0]) == edit["added"]))

    heading_names = {}
    for bookmark in candidate_doc.findall(".//w:bookmarkStart", NS):
        name = bookmark.get("{" + NS["w"] + "}name")
        heading_names.setdefault(name, []).append(bookmark)
    toc_records = []
    for link in candidate_doc.findall(".//w:hyperlink", NS):
        anchor = link.get("{" + NS["w"] + "}anchor")
        targets = heading_names.get(anchor, [])
        heading = None
        if len(targets) == 1:
            target = targets[0]
            parent = target.getparent()
            if parent.tag == "{" + NS["w"] + "}p":
                heading = text(parent)
            else:
                target = target.getnext()
                while target is not None and target.tag != "{" + NS["w"] + "}p":
                    target = target.getnext()
                heading = text(target) if target is not None else None
        toc_records.append({"anchor": anchor, "link_text": text(link), "target_text": heading, "valid": len(targets) == 1 and heading == text(link)})
    check("45_TOC_internal_links_resolve_to_correct_heading", len(toc_records) == 45 and all(record["valid"] for record in toc_records), toc_records)
    check("two_new_TOC_anchors_present_once", sum(record["anchor"] == "rw_heading_finite_20261010" for record in toc_records) == 1 and sum(record["anchor"] == "rw_heading_repeatability_20261010" for record in toc_records) == 1)

    g2 = csv_rows(REPO / "docs/evidence/g2-timing-description-20261010/run-6b9fa92/normal-timing.csv")
    expected_g2 = [["阶段", "调用数", "P50/ns", "P90/ns", "P99/ns", "最大/ns", "MAD/ns"]]
    for phase, title in [("warmup", "预热"), ("main", "主阶段")]:
        row = next(row for row in g2 if row["scope"] == "whole_phase" and row["phase"] == phase and row["input_index"] == "all")
        expected_g2.append([title] + [row[key] for key in ["count", "p50_ns", "p90_ns", "p99_ns", "max_ns", "mad_ns"]])
    expected_raw = [["进程", "最小/ns", "P50/ns", "P90/ns", "P99/ns", "最大/ns", "MAD/ns"]]
    for number in range(1, 4):
        rows = csv_rows(REPO / f"docs/evidence/raw-clock-20261010/run-aa43771/selected-originals/output/P{number}-analysis.csv")
        row = next(row for row in rows if row["phase"] == "main" and row["series"] == "within_pair_ns")
        expected_raw.append([f"RAW-{number}"] + [row[key] for key in ["min_ns", "p50_ns", "p90_ns", "p99_ns", "max_ns", "mad_ns"]])
    expected_ordinary = [["批次/进程", "P50/ns", "P90/ns", "P99/ns", "最大/ns", "MAD/ns"]]
    for batch in ["e1", "e2"]:
        for number in range(1, 4):
            rows = csv_rows(REPO / f"docs/evidence/ordinary-repeatability-20261010/run-7ca9320/selected-originals/batches/{batch}/output/P{number}-analysis.csv")
            row = next(row for row in rows if row["phase"] == "main" and row["series"] == "within_pair_ns")
            expected_ordinary.append([f"{batch.upper()}-P{number}"] + [row[key] for key in ["p50_ns", "p90_ns", "p99_ns", "max_ns", "mad_ns"]])
    for index, expected in [(18, expected_g2), (19, expected_raw), (20, expected_ordinary)]:
        table = new_tables[index]
        rows = table.findall("w:tr", NS)
        check(f"new_table_{index}_all_cells_match_original_C", table_rows(table) == expected, {"actual": table_rows(table), "expected": expected})
        check(f"new_table_{index}_every_row_cannot_split", all(enabled(row.find("w:trPr/w:cantSplit", NS)) for row in rows))
        check(f"new_table_{index}_repeat_first_row_only", enabled(rows[0].find("w:trPr/w:tblHeader", NS)) and not any(enabled(row.find("w:trPr/w:tblHeader", NS)) for row in rows[1:]))
        check(f"new_table_{index}_no_data_keepNext_chain", not any(enabled(p.find("w:pPr/w:keepNext", NS)) for row in rows[1:] for p in row.findall(".//w:p", NS)))
        grid = [int(column.get("{" + NS["w"] + "}w")) for column in table.findall("w:tblGrid/w:gridCol", NS)]
        check(f"new_table_{index}_grid_width_8957", sum(grid) == 8957 and len(grid) == len(expected[0]), grid)

    full_text = text(candidate_doc)
    keywords = next(value for value in table_rows(new_tables[0])[-1] if "关键词" in value).split("：", 1)[1]
    check("exactly_five_keywords", len(keywords.split("；")) == 5)
    check("known_system_number_present", "CACR2026EA16XZ" in full_text)
    xml_parts = {name: value.decode("utf-8") for name, value in candidate_parts.items() if name.endswith((".xml", ".rels"))}
    private_patterns = {
        "project_author": r"(?i)Gowin[-_]liuyin|yinhaoran0808|\byin\b",
        "cloud_user_or_host": r"(?i)nss-marker|\bnss-m\b|cryproject-native-x86|119\.45\.121\.134|10\.144\.144\.[35]",
        "absolute_personal_or_cloud_path": r"/Users/|/home/|(?i:yhr/Cry)|file://",
        "email": r"[A-Za-z0-9_.+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}",
    }
    identifier_hits = []
    for name, value in xml_parts.items():
        for kind, pattern in private_patterns.items():
            for match in re.finditer(pattern, value):
                identifier_hits.append({"part": name, "kind": kind, "match": match.group(0)})
    check("anonymous_XML_known_identity_path_email_scan", not identifier_hits, identifier_hits)
    commits = set(re.findall(r"(?<![0-9a-f])[0-9a-f]{40}(?![0-9a-f])", full_text))
    check("all_visible_full_commit_ids_are_public_third_party", commits <= set(PUBLIC_COMMITS), {value: PUBLIC_COMMITS.get(value, "UNKNOWN") for value in sorted(commits)})
    ip_hits = []
    for match in re.finditer(r"(?<![\d.])(?:\d{1,3}\.){3}\d{1,3}(?![\d.])", full_text):
        try:
            ip_hits.append(str(ipaddress.ip_address(match.group(0))))
        except ValueError:
            pass
    check("no_visible_IP_addresses", not ip_hits, ip_hits)
    core = etree.fromstring(candidate_parts["docProps/core.xml"], xml_parser)
    creator_fields = core.xpath("//*[local-name()='creator' or local-name()='lastModifiedBy']/text()")
    check("metadata_creator_and_modifier_empty", not any(value.strip() for value in creator_fields), creator_fields)
    company = etree.fromstring(candidate_parts["docProps/app.xml"], xml_parser).xpath("//*[local-name()='Company' or local-name()='Manager']/text()")
    check("metadata_company_and_manager_empty", not any(value.strip() for value in company), company)
    check("no_comments_or_tracked_identity_changes", not any("comments" in name.lower() for name in candidate_parts) and not candidate_doc.xpath(".//w:ins|.//w:del|.//w:commentRangeStart|.//w:commentReference", namespaces=NS))
    external_relationships = []
    for name, value in candidate_parts.items():
        if name.endswith(".rels"):
            for relationship in etree.fromstring(value, xml_parser):
                if relationship.get("TargetMode") == "External":
                    external_relationships.append({"part": name, "target": relationship.get("Target"), "type": relationship.get("Type")})
    check("no_external_relationship_identity_leaks", not external_relationships, external_relationships)
    result["anonymity_scope"] = "candidate DOCX XML/body/metadata/relationships only; public authors, upstream identities/licenses, host application and system number exempt; no packaged evidence or screenshots examined"
    check("source_and_candidate_files_unchanged_by_verifier", sha(original.read_bytes()) == result["source"]["sha256"] and sha(args.candidate.read_bytes()) == result["candidate"]["sha256"])
    result["status"] = "passed_with_page_visual_distribution_pending" if not result["failures"] else "failed"
    args.output.write_text(json.dumps(result, ensure_ascii=False, indent=2) + "\n")
    print(json.dumps({"status": result["status"], "checks": len(result["checks"]), "failures": result["failures"], "output": str(args.output)}, ensure_ascii=False))
    return 0 if not result["failures"] else 1


if __name__ == "__main__":
    sys.exit(main())
