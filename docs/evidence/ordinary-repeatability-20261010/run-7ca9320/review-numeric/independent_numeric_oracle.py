"""一次性外部整数参照；不调用产品C、管理器、SSH或真实采集入口。"""

import argparse
from fractions import Fraction
import hashlib
import json
from pathlib import Path
import re
import statistics
import sys


SOURCE_COMMIT = "7ca9320f6aeb525daba6169ffb0135be0c31779a"
STUDY = "docs/research/aris-ordinary-repeatability-20261010/"
SOURCE_MANIFEST_SHA256 = "c95d924d31e0c085724f89a97c5808c7706bcae22ec1bd683c5b45b8495f6552"
RUNNER_SHA256 = "857d30a018662251cfdba7e9070a5dd1c9aa6132be1f2a86cee7b218a31e6ae7"
UINT64_MAXIMUM = 2**64 - 1
NS_PER_SECOND = 10**9
PHASE_COUNT = 25000
RAW_FIELDS = (
    "index,phase,before_attempted,before_has_timespec,before_seconds,before_fractional_ns,"
    "before_ns,before_errno,after_attempted,after_has_timespec,after_seconds,"
    "after_fractional_ns,after_ns,after_errno,elapsed_ns,operation_performed,"
    "operation_status,output_matches_fixture"
).split(",")
STATISTIC_FIELDS = (
    "phase,series,count,zero_count,sum_ns,min_ns,min_positive_ns,p50_ns,p90_ns,p99_ns,max_ns,mad_ns"
).split(",")


def require(condition, message):
    if not condition:
        raise AssertionError(message)


def sha256(payload):
    return hashlib.sha256(payload).hexdigest()


def no_duplicate_keys(pairs):
    result = {}
    for key, value in pairs:
        require(key not in result, "duplicate JSON key: " + key)
        result[key] = value
    return result


def read_json(payload):
    def reject_constant(value):
        raise ValueError("nonfinite JSON constant: " + value)
    return json.loads(payload, object_pairs_hook=no_duplicate_keys, parse_constant=reject_constant)


def decimal(text):
    require(re.fullmatch(r"[0-9]+", text) is not None, "invalid unsigned decimal")
    value = int(text)
    require(value <= UINT64_MAXIMUM, "uint64 overflow")
    return value


def exact_csv(payload, header):
    require(payload.endswith(b"\n") and b"\r" not in payload and b"\0" not in payload,
            "CSV framing")
    lines = payload.decode("ascii").split("\n")[:-1]
    require(lines and lines[0] == ",".join(header), "CSV header")
    rows = []
    for line in lines[1:]:
        row = line.split(",")
        require(len(row) == len(header) and all(row), "CSV fields")
        rows.append(row)
    return rows


def raw_pairs(payload):
    rows = exact_csv(payload, RAW_FIELDS)
    require(len(rows) == PHASE_COUNT * 2, "fixed raw row count")
    pairs = []
    previous_after_ns = None
    for record_index, row in enumerate(rows):
        require(decimal(row[0]) == record_index, "raw index")
        require(row[1] == ("warmup" if record_index < PHASE_COUNT else "main"), "raw phase")
        values_ns = []
        for offset in (2, 8):
            require(row[offset:offset + 2] == ["1", "1"], "clock attempted/has timespec")
            seconds, fractional_ns, recorded_ns, errno = map(decimal, row[offset + 2:offset + 6])
            require(errno == 0 and fractional_ns < NS_PER_SECOND, "clock range/errno")
            reconstructed_ns = seconds * NS_PER_SECOND + fractional_ns
            require(reconstructed_ns <= UINT64_MAXIMUM and reconstructed_ns == recorded_ns,
                    "clock timespec conversion")
            values_ns.append(recorded_ns)
        before_ns, after_ns = values_ns
        require(after_ns >= before_ns and decimal(row[14]) == after_ns - before_ns,
                "within-pair elapsed")
        require(previous_after_ns is None or before_ns >= previous_after_ns,
                "full ordered-read monotonicity")
        require(row[15:] == ["1", "0", "1"], "full operation/output integrity")
        previous_after_ns = after_ns
        pairs.append((before_ns, after_ns))
    return pairs


def quantile(ordered, percentile):
    position = (Fraction((len(ordered) - 1) * percentile, 100) + Fraction(1, 2)).__floor__()
    require(0 <= position < len(ordered), "quantile index")
    return ordered[position], position


def describe(increments):
    require(increments and all(type(value) is int and 0 <= value <= UINT64_MAXIMUM
                               for value in increments), "increment values")
    ordered = sorted(increments)
    value_count = len(ordered)
    total_ns = sum(ordered)
    require(total_ns <= UINT64_MAXIMUM, "sum overflow")
    percentiles = {percentile: quantile(ordered, percentile) for percentile in (0, 50, 90, 99, 100)}
    median_ns = statistics.median_high(ordered)
    require(percentiles[50][0] == median_ns, "upper median")
    deviations_ns = [abs(value - median_ns) for value in ordered]
    positive_values = [value for value in ordered if value > 0]
    result = {"count": value_count, "zero_count": ordered.count(0), "sum_ns": total_ns,
              "min_ns": ordered[0], "min_positive_ns": positive_values[0] if positive_values else None,
              "p50_ns": median_ns, "p90_ns": percentiles[90][0], "p99_ns": percentiles[99][0],
              "max_ns": ordered[-1], "mad_ns": statistics.median_high(deviations_ns)}
    exact_mean_ns = Fraction(total_ns, value_count)
    detail = {"quantile_positions": {str(key): item[1] for key, item in percentiles.items()},
              "exact_mean_ns": {"numerator": exact_mean_ns.numerator,
                                "denominator": exact_mean_ns.denominator}}
    return result, detail


def describe_phase(phase, pairs):
    within = [after - before for before, after in pairs]
    between = [right[0] - left[1] for left, right in zip(pairs, pairs[1:])]
    ordered_reads = [clock_ns for pair in pairs for clock_ns in pair]
    combined = [right - left for left, right in zip(ordered_reads, ordered_reads[1:])]
    wall_ns = pairs[-1][1] - pairs[0][0]
    require(sum(within) + sum(between) == sum(combined) == wall_ns, "phase conservation")
    rows, details = [], []
    for series, increments in (("within_pair_ns", within), ("between_pairs_ns", between),
                               ("combined_ordered_read_increment_ns", combined)):
        values, detail = describe(increments)
        rows.append({"phase": phase, "series": series, **values})
        details.append({"phase": phase, "series": series, **detail})
    return rows, details, {"wall_ns": wall_ns, "within_sum_ns": sum(within), "between_sum_ns": sum(between)}


def summary_from_geometry(warmup, main, boundary_gap_ns):
    return {"status": "descriptive_only", "schema": "reference-repeatability-analysis-v1", "units": "ns",
            "record_count": 50000, "warmup_call_count": 25000, "main_call_count": 25000,
            "phase_boundary_gap_ns": boundary_gap_ns, "warmup_wall_ns": warmup["wall_ns"],
            "main_wall_ns": main["wall_ns"], "warmup_pair_sum_ns": warmup["within_sum_ns"],
            "warmup_between_sum_ns": warmup["between_sum_ns"], "main_pair_sum_ns": main["within_sum_ns"],
            "main_between_sum_ns": main["between_sum_ns"], "phase_conservation_valid": True,
            "cross_phase_conservation_valid": True, "clock_precision_certified": False,
            "iid_claimed": False, "collector_stderr_checked": False, "collector_exit_checked": False,
            "complete_metadata_acceptance": False, "r02_signed_off": False, "r04_signed_off": False}


def csv_from_rows(rows):
    return (",".join(STATISTIC_FIELDS) + "\n" + "".join(
        ",".join("null" if row[field] is None else str(row[field]) for field in STATISTIC_FIELDS) + "\n"
        for row in rows)).encode("ascii")


class BatchReview:
    def __init__(self, spec):
        self.batch = spec["batch"]
        self.root = Path(spec["original_directory"]).resolve(strict=True)
        self.archive_path = Path(spec["archive_path"]).resolve(strict=True)
        require(self.root.is_dir() and not Path(spec["original_directory"]).is_symlink(), "original root")
        archive_payload = self.archive_path.read_bytes()
        require(sha256(archive_payload) == spec["archive_sha256"], "archive binding")
        self.archive_binding = {"path": str(self.archive_path), "bytes": len(archive_payload),
                                "sha256": sha256(archive_payload)}
        self.bindings = {}
        self.prefix = "batches/" + self.batch + "/"

    def original(self, relative):
        require(not relative.startswith("/") and all(part not in ("", ".", "..")
                for part in relative.split("/")), "noncanonical member")
        path = self.root / relative
        require(path.is_file() and not path.is_symlink() and path.resolve(strict=True).is_relative_to(self.root),
                "not physical regular original: " + relative)
        payload = path.read_bytes()
        self.bindings[relative] = {"bytes": len(payload), "sha256": sha256(payload)}
        return payload

    def object(self, relative, one_line=False):
        payload = self.original(relative)
        if one_line:
            require(payload.endswith(b"\n") and payload.count(b"\n") == 1, "one JSON line")
        return read_json(payload)

    def prepare(self):
        self.state = self.object(self.prefix + "run-state.json")
        self.commands = self.object(self.prefix + "commands.json")
        self.before = self.object(self.prefix + "before-environment.json")
        self.after = self.object(self.prefix + "after-environment.json")
        self.manifest = self.object(self.prefix + "manifest.json")
        require(self.state["status"] == "completed" and self.state["batch"] == self.batch
                and self.state["source_commit"] == SOURCE_COMMIT, "source/state identity")
        require(self.state["accepted_timed_calls"] == 150000 and
                self.state["confirmed_complete_collector_full_calls"] == 150003 and
                self.state["launched_supervisors"] == self.state["confirmed_collector_starts"] ==
                self.state["completed_processes"] == self.state["accepted_processes"] == 3,
                "batch counts")
        require(self.state["source_manifest_sha256"] == SOURCE_MANIFEST_SHA256 and
                self.state["runner_sha256"] == RUNNER_SHA256, "frozen source receipts")
        manifest_payload = self.original("source/" + STUDY + "SOURCE_MANIFEST.json")
        require(sha256(manifest_payload) == SOURCE_MANIFEST_SHA256, "fixed source manifest bytes")
        source_manifest = read_json(manifest_payload)
        require(len(source_manifest["files"]) == 140, "source membership count")
        for record in source_manifest["files"]:
            payload = self.original("source/" + record["path"])
            require(len(payload) == record["bytes"] and sha256(payload) == record["sha256"],
                    "fixed source pin: " + record["path"])
        require(sha256(self.original("source/" + STUDY + "remote_run.py")) == RUNNER_SHA256,
                "fixed runner bytes")
        require(self.state["binary_sha256"] == self.state["binary_sha256_before_sampling"] ==
                self.state["binary_sha256_after_sampling"], "binary sampling receipts")
        require(len(self.state["binary_sha256"]) == 6, "six qualified binaries")
        for relative, expected_sha in self.state["binary_sha256"].items():
            require(sha256(self.original(relative)) == expected_sha, "actual ELF binding")
        require(self.before["boot_id"] == self.after["boot_id"] == self.state["boot_id"], "boot context")

    def case(self, name):
        state_case = next(case for case in self.state["cases"] if case["name"] == name)
        prefix = self.prefix + "output/" + name
        pairs = raw_pairs(self.original(prefix + ".csv"))
        metadata = self.object(prefix + ".json", True)
        expected_numbers = {"pid": state_case["pid"], "record_count": 50000,
                            "planned_warmup_calls": 25000, "planned_main_calls": 25000,
                            "valid_warmup_calls": 25000, "valid_main_calls": 25000,
                            "attempted_call_count": 50000, "verified_output_call_count": 50000,
                            "setup_call_count": 1, "setup_operation_status": 0}
        require(all(type(metadata[key]) is int and metadata[key] == value
                    for key, value in expected_numbers.items()), "numeric metadata/counts")
        require(metadata["contract"] == "ordinary-reference-repeatability-v1" and
                metadata["clock"] == "CLOCK_MONOTONIC_RAW" and metadata["stop_reason"] == "completed"
                and metadata["partial_unknown"] is False and metadata["setup_verified"] is True
                and metadata["reference_identity_verified"] is True, "completed reference metadata")
        warmup_rows, warmup_details, warmup = describe_phase("warmup", pairs[:PHASE_COUNT])
        main_rows, main_details, main = describe_phase("main", pairs[PHASE_COUNT:])
        rows = warmup_rows + main_rows
        actual_table = self.original(prefix + "-analysis.csv")
        require(actual_table == csv_from_rows(rows), "full six-row C CSV byte equality")
        boundary_gap_ns = pairs[PHASE_COUNT][0] - pairs[PHASE_COUNT - 1][1]
        total_wall_ns = pairs[-1][1] - pairs[0][0]
        require(warmup["wall_ns"] + boundary_gap_ns + main["wall_ns"] == total_wall_ns,
                "cross-phase conservation")
        expected_summary = summary_from_geometry(warmup, main, boundary_gap_ns)
        summary_bytes = self.original(prefix + "-summary.json")
        require(summary_bytes == (json.dumps(expected_summary, separators=(",", ":")) + "\n").encode("ascii"),
                "full C summary byte equality")
        for field, suffix in (("csv", ".csv"), ("metadata", ".json"),
                              ("analysis", "-analysis.csv"), ("summary", "-summary.json")):
            require(state_case[field + "_sha256"] == self.bindings[prefix + suffix]["sha256"]
                    and state_case[field + "_bytes"] == self.bindings[prefix + suffix]["bytes"],
                    "accepted output pins")
        for label in (name, name + "-analysis"):
            matches = [command for command in self.commands if command["label"] == label]
            require(len(matches) == 1, "unique numeric command")
            command = matches[0]
            require(command["exit_code"] == 0 and command["leader_reaped"] is True and
                    command["process_group_gone"] is True and command["cleanup_unconfirmed"] is False,
                    "numeric command lifecycle receipt")
            for stream in ("stdout", "stderr"):
                relative = command[stream]
                require(relative in self.bindings and self.bindings[relative] ==
                        {"bytes": command[stream + "_bytes"], "sha256": command[stream + "_sha256"]},
                        "numeric command byte receipt")
        require(state_case["status"] == "accepted" and state_case["partial_unknown"] is False
                and state_case["management_complete_metadata_acceptance"] is True, "case receipt")
        return {"batch": self.batch, "name": name, "collector_pid": metadata["pid"],
                "raw_record_count": len(pairs), "raw_fields_checked": len(pairs) * 18,
                "sampling_clock_read_count": len(pairs) * 2, "first_before_ns": pairs[0][0],
                "last_after_ns": pairs[-1][1], "clocksource": metadata["before"]["clocksource"],
                "declared_resolution_ns": metadata["before"]["resolution_ns"], "rows": rows,
                "quantile_positions_and_exact_means": warmup_details + main_details,
                "geometry": {"warmup": warmup, "main": main, "phase_boundary_gap_ns": boundary_gap_ns,
                             "total_wall_ns": total_wall_ns}, "c_summary_fields_matched": len(expected_summary),
                "c_table_and_summary_byte_equal": True}

    def finish(self):
        for relative, binding in self.bindings.items():
            if relative != self.prefix + "manifest.json":
                require(self.manifest[relative] == binding, "manifest relevant-file binding")
            require(sha256((self.root / relative).read_bytes()) == binding["sha256"], "input unchanged")


def selfcheck():
    odd, _ = describe([10, 0, 4])
    require(odd == {"count": 3, "zero_count": 1, "sum_ns": 14, "min_ns": 0, "min_positive_ns": 4,
                    "p50_ns": 4, "p90_ns": 10, "p99_ns": 10, "max_ns": 10, "mad_ns": 4}, "odd fixture")
    even, _ = describe([8, 0, 2, 0])
    require(even["p50_ns"] == 2 and even["mad_ns"] == 2 and even["sum_ns"] == 10, "upper even fixture")
    zeros, _ = describe([0, 0])
    require(zeros["min_positive_ns"] is None and zeros["zero_count"] == 2, "zero fixture")
    require(quantile(list(range(6)), 90) == (5, 5) and quantile(list(range(101)), 99) == (99, 99),
            "fixed position fixtures")
    rows, _, geometry = describe_phase("warmup", [(10, 12), (12, 15), (20, 20)])
    require(geometry == {"wall_ns": 10, "within_sum_ns": 5, "between_sum_ns": 5} and
            rows[2]["count"] == 5 and rows[2]["zero_count"] == 2, "geometry fixture")
    for bad_value in ("-1", "+1", " 1", "", str(UINT64_MAXIMUM + 1)):
        try:
            decimal(bad_value)
        except AssertionError:
            continue
        raise AssertionError("invalid integer accepted")
    try:
        describe([UINT64_MAXIMUM, 1])
    except AssertionError:
        pass
    else:
        raise AssertionError("overflowing sum accepted")
    return {"selfcheck": "passed", "scope": "pure external integer/Fraction fixtures only",
            "input_archives_read": 0, "real_clock_reads": 0, "crypto_calls": 0,
            "product_c_invocations": 0, "collector_invocations": 0, "ssh_invocations": 0}


def verify(spec):
    require(spec["source_commit"] == SOURCE_COMMIT, "deployment commit pin")
    require([item["batch"] for item in spec["batches"]] == ["e1", "e2"], "exact two batches")
    reviews = [BatchReview(item) for item in spec["batches"]]
    cases = []
    for review in reviews:
        review.prepare()
        cases.extend(review.case(name) for name in ("P1", "P2", "P3"))
        review.finish()
    first, second = reviews
    require(first.state["boot_id"] == second.state["boot_id"] and
            first.state["binary_sha256"] == second.state["binary_sha256"], "same boot/binaries across batches")
    dependency = second.state["e1_dependency"]
    require(dependency["archive_sha256"] == first.archive_binding["sha256"] and
            dependency["state_sha256"] == first.bindings[first.prefix + "run-state.json"]["sha256"] and
            dependency["manifest_sha256"] == first.bindings[first.prefix + "manifest.json"]["sha256"],
            "actual E1-to-E2 dependency pins")
    require(len({case["collector_pid"] for case in cases}) == 6, "distinct collector PIDs")
    require(sum(case["raw_record_count"] for case in cases) == 300000, "six complete raw files")
    require(all(cases[index]["first_before_ns"] >= cases[index - 1]["last_after_ns"]
                for index in range(1, len(cases))), "cross-process ordered same-boot RAW boundaries")
    process_gaps = [{"from": cases[index - 1]["batch"] + "-" + cases[index - 1]["name"],
                     "to": cases[index]["batch"] + "-" + cases[index]["name"],
                     "gap_ns": cases[index]["first_before_ns"] - cases[index - 1]["last_after_ns"]}
                    for index in range(1, len(cases))]
    return {"schema": "independent-reference-repeatability-numeric-v1", "status": "all_checked_values_match",
            "reviewer": "ordinary_repeatability_numeric", "source_commit": SOURCE_COMMIT,
            "oracle_role": "one-off external arithmetic reference; product statistics remain C",
            "oracle_platform": sys.platform, "python_version": sys.version,
            "oracle_sha256": sha256(Path(__file__).read_bytes()), "source_manifest_sha256": SOURCE_MANIFEST_SHA256,
            "runner_sha256": RUNNER_SHA256, "raw_records_checked": 300000,
            "raw_fields_checked": 5400000, "sampling_clock_reads_checked": 600000,
            "output_rows_checked": 36, "output_metric_fields_checked": 360,
            "complete_c_summaries_byte_compared": 6, "batches": [
                {"batch": review.batch, "archive": review.archive_binding,
                 "bound_original_files": review.bindings} for review in reviews],
            "cases": cases, "between_process_sampling_gaps_ns": process_gaps,
            "input_bytes_unchanged": True, "mismatches": [], "archive_member_audit_performed_here": False,
            "complete_metadata_acceptance_audited_here": False,
            "primary_c_invocations_by_reviewer": 0, "collector_invocations_by_reviewer": 0,
            "ssh_invocations_by_reviewer": 0, "new_sampling_reads_by_reviewer": 0,
            "clock_precision_certified": False, "iid_claimed": False,
            "r02_signed_off": False, "r04_signed_off": False}


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--selfcheck", action="store_true")
    parser.add_argument("--spec", type=Path)
    parser.add_argument("--output-directory", type=Path)
    arguments = parser.parse_args()
    if arguments.selfcheck:
        require(arguments.spec is None and arguments.output_directory is None, "selfcheck arguments")
        print(json.dumps(selfcheck(), separators=(",", ":")))
        return
    require(arguments.spec is not None and arguments.output_directory is not None, "verification arguments")
    output_directory = arguments.output_directory.resolve(strict=True)
    spec_payload = arguments.spec.read_bytes()
    try:
        result = verify(read_json(spec_payload))
        result["input_spec_sha256"] = sha256(spec_payload)
        with (output_directory / "verification.json").open("x") as output_file:
            json.dump(result, output_file, ensure_ascii=False, indent=2)
            output_file.write("\n")
        print(json.dumps({"status": result["status"], "raw_records_checked": 300000,
                          "output_metric_fields_checked": 360, "complete_summaries": 6,
                          "mismatches": []}, separators=(",", ":")))
    except BaseException as error:
        with (output_directory / "verification-failure.json").open("x") as output_file:
            json.dump({"status": "verification_failed", "type": type(error).__name__, "message": str(error),
                       "oracle_sha256": sha256(Path(__file__).read_bytes()),
                       "input_spec_sha256": sha256(spec_payload)}, output_file, indent=2)
            output_file.write("\n")
        raise


if __name__ == "__main__":
    main()
