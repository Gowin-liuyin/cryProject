"""一次性外部算术参照；不调用C程序、管理器、SSH或真实采样入口。"""

import csv
from fractions import Fraction
import hashlib
import io
import json
from pathlib import Path
import re
import statistics
import sys


review_directory = Path(__file__).resolve().parent
deployment_directory = review_directory.parent
original_directory = deployment_directory / "originals"
maximum_uint64 = 2**64 - 1
nanoseconds_per_second = 10**9
expected_archive_sha256 = "e6dfd03f03e1e2e4e28a4eb0c251a8f7d684745980727843263e4ad8ff1870e6"
expected_source_sha256 = {
    "raw_clock_calibration.c": "ed538f4322fba985aea9cfa78e0b2109f79caed49064e68eaa3884b4fa10f0dd",
    "analyze_raw_clock.c": "c67d1dbd89034a75600d3d13a28aa5c7fb4a163b5649fa910c7eea624c7544e0",
    "CMakeLists.txt": "28d264a993558d1aad66dd6ffd2671c0a3ea18054fda6d6ec91b06a7c312816e",
    "remote_run.py": "bf34389f2cb39348ac1baa2a3c2b159ad69cb473414ff3b6b7b97850d0431d04",
}
raw_fields = (
    "index,phase,before_attempted,before_has_timespec,before_seconds,before_fractional_ns,"
    "before_ns,before_errno,after_attempted,after_has_timespec,after_seconds,"
    "after_fractional_ns,after_ns,after_errno,elapsed_ns"
).split(",")
statistic_fields = (
    "phase,series,count,zero_count,sum_ns,min_ns,min_positive_ns,p50_ns,p90_ns,p99_ns,max_ns,mad_ns"
).split(",")
statistic_numbers = statistic_fields[2:]
bound_original_files = {}
checked_raw_records = 0
checked_metric_fields = 0


def require(condition, description):
    if not condition:
        raise AssertionError(description)


def digest_bytes(payload):
    return hashlib.sha256(payload).hexdigest()


def original_bytes(relative_path):
    path = original_directory / relative_path
    require(path.is_file() and not path.is_symlink(), "not regular: " + relative_path)
    payload = path.read_bytes()
    bound_original_files[relative_path] = {"bytes": len(payload), "sha256": digest_bytes(payload)}
    return payload


def reject_duplicates(pairs):
    result = {}
    for key, value in pairs:
        require(key not in result, "duplicate JSON key: " + key)
        result[key] = value
    return result


def load_json_bytes(payload):
    def reject_constant(value):
        raise ValueError("nonfinite JSON constant: " + value)
    return json.loads(payload, object_pairs_hook=reject_duplicates, parse_constant=reject_constant)


def original_json(relative_path, single_line=False):
    payload = original_bytes(relative_path)
    if single_line:
        require(payload.endswith(b"\n") and payload.count(b"\n") == 1 and b"\r" not in payload,
                "not one complete JSON line: " + relative_path)
    return load_json_bytes(payload)


def exact_csv_rows(payload, field_names):
    require(payload.endswith(b"\n") and b"\r" not in payload and b"\x00" not in payload,
            "CSV LF/NUL/CR failure")
    require(b'"' not in payload, "quoted CSV outside fixed contract")
    require(all(len(line) < 1023 for line in payload.splitlines()), "CSV input line capacity")
    reader = csv.reader(io.StringIO(payload.decode("ascii"), newline=""), strict=True)
    require(next(reader) == field_names, "CSV header")
    return reader


def unsigned_decimal(text):
    require(re.fullmatch(r"[0-9]+", text) is not None, "not unsigned decimal")
    value = int(text)
    require(value <= maximum_uint64, "uint64 overflow")
    return value


def read_raw_pairs(case_name):
    global checked_raw_records
    reader = exact_csv_rows(original_bytes("output/" + case_name + ".csv"), raw_fields)
    pairs = []
    previous_after_ns = None
    for record_index, row in enumerate(reader):
        require(len(row) == 15, "raw field count")
        require(record_index < 101000 and unsigned_decimal(row[0]) == record_index, "raw index/count")
        require(row[1] == ("warmup" if record_index < 1000 else "main"), "raw phase")
        clock_values_ns = []
        for first_field in (2, 8):
            require(row[first_field:first_field + 2] == ["1", "1"], "clock attempt/timespec")
            seconds, fractional_ns, recorded_ns, error_number = map(unsigned_decimal,
                row[first_field + 2:first_field + 6])
            require(error_number == 0, "clock error")
            require(fractional_ns < nanoseconds_per_second, "fractional range")
            converted_ns = seconds * nanoseconds_per_second + fractional_ns
            require(converted_ns <= maximum_uint64 and converted_ns == recorded_ns,
                    "timespec conversion")
            clock_values_ns.append(recorded_ns)
        before_ns, after_ns = clock_values_ns
        require(after_ns >= before_ns and unsigned_decimal(row[14]) == after_ns - before_ns,
                "pair interval")
        require(previous_after_ns is None or before_ns >= previous_after_ns, "full ordered reads")
        previous_after_ns = after_ns
        pairs.append((before_ns, after_ns))
        checked_raw_records += 1
    require(len(pairs) == 101000, "raw complete fixed count")
    return pairs


def position_quantile(ordered_values, percentile):
    fractional_position = Fraction((len(ordered_values) - 1) * percentile, 100)
    rounded_position = (fractional_position + Fraction(1, 2)).__floor__()
    require(0 <= rounded_position < len(ordered_values), "quantile position")
    return ordered_values[rounded_position], rounded_position


def independent_statistics(increments_ns):
    ordered_values = sorted(increments_ns)
    value_count = len(ordered_values)
    require(value_count > 0 and ordered_values[0] >= 0, "increments range")
    total_ns = sum(ordered_values)
    require(total_ns <= maximum_uint64, "sum uint64 overflow")
    percentile_values = {percentile: position_quantile(ordered_values, percentile)
                         for percentile in (0, 50, 90, 99, 100)}
    require(percentile_values[0][0] == ordered_values[0] and
            percentile_values[100][0] == ordered_values[-1], "quantile endpoints")
    upper_median_ns = statistics.median_high(ordered_values)
    require(percentile_values[50][0] == upper_median_ns, "upper median agreement")
    absolute_deviations_ns = [abs(value_ns - upper_median_ns) for value_ns in ordered_values]
    positive_values = [value_ns for value_ns in ordered_values if value_ns > 0]
    result = {
        "count": value_count,
        "zero_count": ordered_values.count(0),
        "sum_ns": total_ns,
        "min_ns": ordered_values[0],
        "min_positive_ns": positive_values[0] if positive_values else None,
        "p50_ns": percentile_values[50][0],
        "p90_ns": percentile_values[90][0],
        "p99_ns": percentile_values[99][0],
        "max_ns": ordered_values[-1],
        "mad_ns": statistics.median_high(absolute_deviations_ns),
    }
    exact_mean_ns = Fraction(total_ns, value_count)
    return result, {"quantile_positions": {str(key): value[1] for key, value in percentile_values.items()},
                    "exact_mean_ns": {"numerator": exact_mean_ns.numerator,
                                      "denominator": exact_mean_ns.denominator}}


def phase_statistics(phase_name, phase_pairs):
    within_ns = [after_ns - before_ns for before_ns, after_ns in phase_pairs]
    between_ns = [next_pair[0] - previous_pair[1]
                  for previous_pair, next_pair in zip(phase_pairs, phase_pairs[1:])]
    ordered_reads_ns = [value_ns for pair in phase_pairs for value_ns in pair]
    combined_ns = [right_ns - left_ns for left_ns, right_ns in zip(ordered_reads_ns, ordered_reads_ns[1:])]
    wall_ns = phase_pairs[-1][1] - phase_pairs[0][0]
    require(sum(within_ns) + sum(between_ns) == sum(combined_ns) == wall_ns,
            "phase integer conservation")
    rows = []
    details = []
    for series_name, values_ns in (("within_pair_ns", within_ns), ("between_pairs_ns", between_ns),
        ("combined_ordered_read_increment_ns", combined_ns)):
        values, extra = independent_statistics(values_ns)
        rows.append({"phase": phase_name, "series": series_name, **values})
        details.append({"phase": phase_name, "series": series_name, **extra})
    return rows, details, {"wall_ns": wall_ns, "within_sum_ns": sum(within_ns),
                           "between_sum_ns": sum(between_ns)}


def check_metadata(case_name, state, before_context):
    metadata = original_json("output/" + case_name + ".json", True)
    expected_integers = {"pid": state["pid"], "uid": 1000, "effective_uid": 1000, "uname_errno": 0,
        "target_cpu": 2, "original_affinity_errno": 0, "set_affinity_errno": 0,
        "planned_warmup_pairs": 1000, "planned_main_pairs": 100000, "record_count": 101000,
        "valid_warmup_pairs": 1000, "valid_main_pairs": 100000, "stop_errno": 0, "configuration_writes": 0}
    for key, value in expected_integers.items():
        require(type(metadata[key]) is int and metadata[key] == value, "collector metadata " + key)
    require(metadata["contract"] == "raw-empty-pair-v1" and metadata["clock"] == "CLOCK_MONOTONIC_RAW"
        and metadata["stop_reason"] == "completed" and metadata["partial_unknown"] is False
        and metadata["self_affinity_set"] is True, "collector completion/protocol")
    require(metadata["original_affinity"] == before_context["affinity"] == list(range(32)),
            "initial affinity metadata")
    require(list(metadata["uname"].values()) == before_context["uname"], "uname context binding")
    require(metadata["uname"]["sysname"] == "Linux" and metadata["uname"]["machine"] == "x86_64",
            "actual Linux source identity")
    for snapshot_name in ("before", "after"):
        snapshot = metadata[snapshot_name]
        require(snapshot["clocksource"] == "tsc" and snapshot["affinity"] == [2]
                and type(snapshot["observed_cpu"]) is int and snapshot["observed_cpu"] == 2
                and snapshot["cpu2_check"] is True and snapshot["resolution_has_timespec"] is True,
                "clocksource/CPU2 declaration")
        for key in ("clocksource_errno", "resolution_errno", "affinity_errno", "cpu_errno"):
            require(type(snapshot[key]) is int and snapshot[key] == 0, "metadata read error")
        for key in ("resolution_seconds", "resolution_fractional_ns", "resolution_ns"):
            require(type(snapshot[key]) is int and snapshot[key] >= 0, "metadata resolution type")
        require(snapshot["resolution_seconds"] * nanoseconds_per_second +
                snapshot["resolution_fractional_ns"] == snapshot["resolution_ns"] == 1,
                "RAW declared resolution")
    require(metadata["before"] == metadata["after"], "before/after metadata")
    return metadata


def compare_case(case_name, state_case, before_context, commands):
    global checked_metric_fields
    pairs = read_raw_pairs(case_name)
    metadata = check_metadata(case_name, state_case, before_context)
    warmup_rows, warmup_details, warmup_geometry = phase_statistics("warmup", pairs[:1000])
    main_rows, main_details, main_geometry = phase_statistics("main", pairs[1000:])
    expected_rows = warmup_rows + main_rows
    analysis_reader = exact_csv_rows(original_bytes("output/" + case_name + "-analysis.csv"), statistic_fields)
    actual_rows = list(analysis_reader)
    require(len(actual_rows) == 6, "six C rows")
    for row_number, (actual_row, expected_row) in enumerate(zip(actual_rows, expected_rows)):
        require(len(actual_row) == 12 and actual_row[:2] == [expected_row["phase"], expected_row["series"]],
                "C row identity")
        for field_name, text in zip(statistic_numbers, actual_row[2:]):
            actual_value = None if text == "null" else unsigned_decimal(text)
            require(actual_value == expected_row[field_name], case_name + " metric " + field_name)
            checked_metric_fields += 1
    boundary_gap_ns = pairs[1000][0] - pairs[999][1]
    total_wall_ns = pairs[-1][1] - pairs[0][0]
    require(warmup_geometry["wall_ns"] + boundary_gap_ns + main_geometry["wall_ns"] == total_wall_ns,
            "cross-phase integer conservation")
    expected_summary = {"status": "descriptive_only", "schema": "raw-clock-analysis-v1", "units": "ns",
        "record_count": 101000, "warmup_pair_count": 1000, "main_pair_count": 100000,
        "phase_boundary_gap_ns": boundary_gap_ns, "warmup_wall_ns": warmup_geometry["wall_ns"],
        "main_wall_ns": main_geometry["wall_ns"], "warmup_pair_sum_ns": warmup_geometry["within_sum_ns"],
        "warmup_between_sum_ns": warmup_geometry["between_sum_ns"],
        "main_pair_sum_ns": main_geometry["within_sum_ns"], "main_between_sum_ns": main_geometry["between_sum_ns"],
        "phase_conservation_valid": True, "cross_phase_conservation_valid": True,
        "clock_precision_certified": False, "iid_claimed": False, "collector_stderr_checked": False,
        "collector_exit_checked": False, "complete_metadata_acceptance": False,
        "r02_signed_off": False, "r04_signed_off": False}
    summary = original_json("output/" + case_name + "-summary.json", True)
    require(summary == expected_summary and all(type(summary[key]) is type(value)
            for key, value in expected_summary.items()), "full C summary")
    for suffix in ("", "-analysis"):
        command_record = next(record for record in commands if record["label"] == case_name + suffix)
        require(command_record["exit_code"] == 0 and command_record["leader_reaped"] is True
            and command_record["process_group_gone"] is True
            and command_record["cleanup_unconfirmed"] is False, "numeric command completion receipt")
        require(command_record["stdout_sha256"] == bound_original_files[command_record["stdout"]]["sha256"]
            and command_record["stderr_sha256"] == bound_original_files[command_record["stderr"]]["sha256"],
            "numeric command file binding")
    require(state_case["csv_sha256"] == bound_original_files["output/" + case_name + ".csv"]["sha256"]
        and state_case["metadata_sha256"] == bound_original_files["output/" + case_name + ".json"]["sha256"],
        "case original binding")
    require(state_case["status"] == "accepted" and state_case["partial_unknown"] is False
        and state_case["management_complete_metadata_acceptance"] is True, "case acceptance receipt")
    return {"name": case_name, "collector_pid": metadata["pid"], "raw_record_count": len(pairs),
        "sampling_clock_read_count": 2 * len(pairs), "clocksource": metadata["before"]["clocksource"],
        "declared_resolution_ns": metadata["before"]["resolution_ns"],
        "first_before_ns": pairs[0][0], "last_after_ns": pairs[-1][1],
        "rows": expected_rows, "quantile_positions_and_exact_means": warmup_details + main_details,
        "geometry": {"warmup": warmup_geometry, "main": main_geometry,
                     "phase_boundary_gap_ns": boundary_gap_ns, "total_wall_ns": total_wall_ns},
        "c_summary_fields_matched": len(expected_summary), "complete_metadata_checked_externally": True}


def main():
    archive_path = deployment_directory / "remote-originals.tar.gz"
    archive_bytes = archive_path.read_bytes()
    require(len(archive_bytes) == 4454198 and digest_bytes(archive_bytes) == expected_archive_sha256,
            "actual archive binding")
    run_state = original_json("run-state.json")
    commands = original_json("commands.json")
    before_context = original_json("before-environment.json")
    original_json("after-environment.json")
    original_json("run-claim.json")
    manifest = load_json_bytes(original_bytes("manifest.json"))
    require(run_state["status"] == "completed" and run_state["accepted_pairs"] == 303000
        and run_state["launched_supervisors"] == run_state["completed_processes"] == 3,
        "completed run receipt")
    require(run_state["source_commit"] == "aa437714e023e2aef8301a925c33949647790517"
        and run_state["frozen_plan_sha256"] == "7499b60b7a32b0a5e82e2acbc07144b6b0062b5d1f344aeb4af9ff4208e6927a",
        "frozen source/plan identity")
    for source_name, expected_digest in expected_source_sha256.items():
        require(digest_bytes(original_bytes("source/" + source_name)) == expected_digest, "fixed source digest")
    for binary_path, expected_digest in run_state["binary_sha256"].items():
        require(digest_bytes(original_bytes(binary_path)) == expected_digest, "actual binary digest")
    cases = [compare_case("P" + str(index), run_state["cases"][index - 1], before_context, commands)
             for index in (1, 2, 3)]
    require(len({case["collector_pid"] for case in cases}) == 3, "three distinct collector PIDs")
    require(checked_raw_records == 303000 and checked_metric_fields == 180, "full comparison counts")
    for relative_path, expected_binding in bound_original_files.items():
        if relative_path != "manifest.json":
            require(manifest[relative_path] == expected_binding, "manifest relevant-file binding")
        require(digest_bytes((original_directory / relative_path).read_bytes()) == expected_binding["sha256"],
                "input remained unchanged")
    result = {"schema": "independent-raw-clock-numeric-v1", "status": "all_checked_values_match",
        "reviewer": "raw_clock_design_review", "oracle_role": "one-off external arithmetic reference, not a product statistical entry point",
        "oracle_platform": sys.platform, "python_version": sys.version,
        "oracle_sha256": digest_bytes(Path(__file__).read_bytes()),
        "actual_archive": {"path": archive_path.name, "bytes": len(archive_bytes), "sha256": expected_archive_sha256},
        "bound_original_files": bound_original_files, "raw_records_checked": checked_raw_records,
        "raw_fields_checked": checked_raw_records * 15, "sampling_clock_reads_checked": checked_raw_records * 2,
        "output_rows_checked": 18, "output_metric_fields_checked": checked_metric_fields,
        "cases": cases, "input_bytes_unchanged": True, "mismatches": [],
        "primary_c_invocations_by_reviewer": 0, "collector_invocations_by_reviewer": 0,
        "ssh_invocations_by_reviewer": 0, "new_sampling_reads_by_reviewer": 0,
        "archive_member_audit_performed_here": False, "clock_precision_certified": False,
        "iid_claimed": False, "r02_signed_off": False, "r04_signed_off": False}
    with (review_directory / "verification.json").open("x") as output_file:
        json.dump(result, output_file, ensure_ascii=False, indent=2)
        output_file.write("\n")
    print(json.dumps({"status": result["status"], "records_checked": checked_raw_records,
        "metric_fields_checked": checked_metric_fields, "mismatches": [],
        "main_within_pairs": [{"name": case["name"], **case["rows"][3]} for case in cases]}))


if __name__ == "__main__":
    try:
        main()
    except BaseException as error:
        failure_path = review_directory / "verification-failure.json"
        if not failure_path.exists():
            with failure_path.open("x") as output_file:
                json.dump({"status": "verification_failed", "type": type(error).__name__,
                    "message": str(error), "oracle_sha256": digest_bytes(Path(__file__).read_bytes()),
                    "checked_raw_records": checked_raw_records,
                    "checked_metric_fields": checked_metric_fields}, output_file, indent=2)
                output_file.write("\n")
        raise
