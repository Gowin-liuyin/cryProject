#!/bin/sh
set -eu

if [ "$#" -ne 2 ]; then
    echo "usage: test_trace_overhead.sh SESSION_COLLECT DIAGNOSTIC_TRACE" >&2
    exit 1
fi
session_collect=$1
diagnostic_trace=$2
if [ -z "${A113_TEST_TMPDIR:-}" ]; then
    echo "A113_TEST_TMPDIR is required" >&2
    exit 1
fi
work_directory="${A113_TEST_TMPDIR}/trace-overhead"
rm -rf "${work_directory}"
mkdir -p "${work_directory}"

"${session_collect}" overhead-plain session-plain key-plain 31337 4 2 \
    "${work_directory}/plain.csv" "${work_directory}/plain.meta" \
    "${work_directory}/plain.empty"
"${diagnostic_trace}" --account 31337 2 \
    "${work_directory}/account-events.csv" "${work_directory}/account-summary.txt" \
    "${work_directory}/account-candidates.csv"
"${diagnostic_trace}" --timing 31337 2 \
    "${work_directory}/timing-events.csv" "${work_directory}/timing-summary.txt" \
    "${work_directory}/timing-candidates.csv"

plain_mean=$(awk -F, 'NR > 1 { sum += $10; count += 1 } END { if (count == 0) exit 1; printf "%.3f", sum / count }' \
    "${work_directory}/plain.csv")
account_mean=$(awk -F= '/^outer_mean_counts_valid=/ { print $2 }' \
    "${work_directory}/account-summary.txt")
timing_mean=$(awk -F= '/^outer_mean_counts_valid=/ { print $2 }' \
    "${work_directory}/timing-summary.txt")

grep -q 'hook_cost_not_subtracted=yes' "${work_directory}/account-summary.txt"
grep -q 'hook_cost_not_subtracted=yes' "${work_directory}/timing-summary.txt"
grep -q 'compiler_events=enter_exit' "${work_directory}/timing-summary.txt"
if grep -q 'shared_secret\|ground_truth\|verify_flag' \
    "${work_directory}/account-events.csv" "${work_directory}/timing-events.csv"; then
    echo "secret field appeared in trace events" >&2
    exit 1
fi

printf 'mode=plain outer_mean_counts=%s\n' "${plain_mean}"
printf 'mode=account outer_mean_counts_valid=%s\n' "${account_mean}"
printf 'mode=timing outer_mean_counts_valid=%s\n' "${timing_mean}"
printf 'hook_cost_not_subtracted=yes\n'
printf 'three_mode_recorded=yes\n'
