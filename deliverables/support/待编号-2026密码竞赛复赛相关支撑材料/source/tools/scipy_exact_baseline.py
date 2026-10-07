"""官方 SciPy 的离线强对照；不采集密码时间，不生成作品结论。"""

import csv
import hashlib
import sys

import numpy as np
import scipy
from scipy.stats import permutation_test


def main():
    csv_path, plan_path, report_path = sys.argv[1:]
    with open(csv_path, "rb") as source:
        csv_bytes = source.read()
    with open(plan_path, encoding="utf-8") as source:
        fields = dict(line.rstrip("\n").split("=", 1) for line in source)
    if hashlib.sha3_256(csv_bytes).hexdigest() != fields["data_digest"]:
        raise ValueError("data digest mismatch")
    with open(csv_path, newline="", encoding="utf-8") as source:
        rows = list(csv.DictReader(source))
    differences = []
    calls = None
    for pair_index, row in enumerate(rows):
        if int(row["pair_index"]) != pair_index:
            raise ValueError("pair order mismatch")
        pair_calls = int(row["call_count"])
        if calls is not None and pair_calls != calls:
            raise ValueError("unequal call counts")
        calls = pair_calls
        difference = int(row["first_total_ns"]) - int(row["second_total_ns"])
        if abs(difference) > 10**12:
            raise ValueError("difference out of range")
        differences.append(difference)
    if not 4 <= len(differences) <= 20 or not calls:
        raise ValueError("invalid pair count")
    values = np.array(differences, dtype=np.int64)

    def absolute_sum(sample, axis=-1):
        return np.abs(np.sum(sample, axis=axis))

    result = permutation_test(
        (values,), absolute_sum, permutation_type="samples", vectorized=True,
        n_resamples=np.inf, batch=4096, alternative="greater",
    )
    assignment_count = 2 ** len(values)
    tail_count = round(float(result.pvalue) * assignment_count)
    with open(report_path, "x", encoding="utf-8") as output:
        output.write(f"format=scipy_exact_baseline_v1\nscipy_version={scipy.__version__}\n")
        output.write(f"numpy_version={np.__version__}\nassignment_count={assignment_count}\n")
        output.write(f"tail_count={tail_count}\np_value={result.pvalue:.15f}\n")
        output.write("report_status=complete\n")


if __name__ == "__main__":
    main()
