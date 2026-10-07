"""固定SciPy对有限模型的外部数值审计，作品校准计算仍由C完成。"""

import csv
import hashlib
import os
import signal
import sys

# 外部依赖导入也受审计预算约束。
signal.alarm(60)

import numpy as np
import scipy
from scipy.stats import permutation_test


def main():
    raw_path, report_path = sys.argv[1:]
    if scipy.__version__ != "1.16.3" or np.__version__ != "2.3.5":
        raise ValueError("frozen dependency versions required")
    with open(raw_path, "rb") as source:
        digest = hashlib.sha3_256(source.read()).hexdigest()
    with open(raw_path, newline="", encoding="utf-8") as source:
        rows = list(csv.DictReader(source))
    if len(rows) != 40964:
        raise ValueError("incomplete finite population")
    selected = [row for row in rows if int(row["model_assignment_count"]) == 2
                or int(row["assignment_index"]) in {0, 1, 2047, 4095}]
    if len(selected) != 44:
        raise ValueError("wrong frozen audit set")

    def absolute_sum(sample, axis=-1):
        return np.abs(np.sum(sample, axis=axis))

    partial_path = report_path + ".partial"
    with open(partial_path, "x", encoding="utf-8") as output:
        output.write("format=finite_calibration_scipy_audit_v1\n")
        output.write("external_audit_budget_seconds=60\n")
        output.write(f"scipy_version={scipy.__version__}\nnumpy_version={np.__version__}\n")
        output.write(f"raw_sha3_256={digest}\n")
        for row in selected:
            values = np.array([int(row[f"difference_{pair_index}_ns"])
                               for pair_index in range(12)], dtype=np.int64)
            result = permutation_test(
                (values,), absolute_sum, permutation_type="samples", vectorized=True,
                n_resamples=np.inf, batch=4096, alternative="greater",
            )
            assignments = len(result.null_distribution)
            tail_count = round(float(result.pvalue) * assignments)
            matches = (assignments == 4096 and tail_count == int(row["tail_count"])
                       and tail_count == int(row["oracle_tail_count"]))
            output.write(f"model={row['model']} effect_ns={row['effect_ns']} "
                         f"assignment={row['assignment_index']} tail_count={tail_count} "
                         f"assignments={assignments} matches={'yes' if matches else 'no'}\n")
            if not matches:
                raise ValueError("external tail count mismatch")
        output.write("audited_datasets=44\nall_counts_match=yes\n"
                     "result_scope=numeric_audit_only\nreport_status=complete\n")
    os.link(partial_path, report_path)
    os.unlink(partial_path)


if __name__ == "__main__":
    main()
