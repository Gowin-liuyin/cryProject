#!/bin/sh
set -eu
program=$1
temporary_root=$2
mkdir -p "$temporary_root"
work_directory=$(mktemp -d "$temporary_root/m5-dudect.XXXXXXXX")
trap 'rm -rf -- "$work_directory"' EXIT HUP INT TERM
"$program" --self-test
"$program" --self-test-raw "$work_directory/synthetic.csv"
awk -F, '
NR == 1 {if ($0 != "# SYNTHETIC SOFTWARE SELFTEST; NO HARDWARE CLOCKS") exit 1; next}
NR == 2 {if (NF != 9) exit 1; next}
NR > 2 {
    if (NF != 9 || $1 != 0 || $2 != NR-3 || $4 != 7*(NR-3) || $7 != "warmup" || $8 != 0 || $9 != "cycles") exit 1
    if (NR < 10002 && ($5 != $4+7 || $6 != 7)) exit 1
    if (NR == 10002 && ($5 != "" || $6 != "")) exit 1
}
END {if (NR != 10002) exit 1}
' "$work_directory/synthetic.csv"
if "$program" --self-test-raw "$work_directory/synthetic.csv"; then
    printf '%s\n' 'Raw self-test overwrote an existing file' >&2
    exit 1
fi
# 缺raw路径必须在进入任何计时前拒绝。
if "$program" --collect --seed 31337; then
    printf '%s\n' 'Collector accepted missing raw path' >&2
    exit 1
fi
