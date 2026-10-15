#!/bin/sh
set -eu
program=$1
analyze=$2
input_directory=$3
sealed_summary=$4
work_directory=$(mktemp -d)
trap 'rm -rf "$work_directory"' EXIT
sealed_before=$(shasum -a 256 "$sealed_summary")
"$program" --reference-labels-redraw "$input_directory" "$work_directory/run1" \
    > "$work_directory/stdout1"
"$program" --reference-labels-redraw "$input_directory" "$work_directory/run2" \
    > "$work_directory/stdout2"
cmp "$work_directory/stdout1" "$work_directory/stdout2"
cmp "$work_directory/stdout1" "$work_directory/run1/conclusion.txt"
cmp "$work_directory/run1/conclusion.txt" "$work_directory/run2/conclusion.txt"
cmp "$work_directory/run1/selected.csv" "$work_directory/run2/selected.csv"
cmp "$work_directory/run1/raw.csv" "$work_directory/run2/raw.csv"
grep -q '^rule_id=v4_label_redraw_20261013$' "$work_directory/run1/conclusion.txt"
grep -q '^label_seed=20261013$' "$work_directory/run1/conclusion.txt"
grep -q '^assignment_count=4096$' "$work_directory/run1/conclusion.txt"
grep -q '^denominator=4096$' "$work_directory/run1/conclusion.txt"
grep -q '^tail=upper_including_ties$' "$work_directory/run1/conclusion.txt"
grep -q '^statistic=c04_abs_sum$' "$work_directory/run1/conclusion.txt"
grep -q '^old_rule=original_order_0\.\.23$' "$work_directory/run1/conclusion.txt"
grep -q '^status=complete$' "$work_directory/run1/conclusion.txt"
grep -q '^mlkem_decapsulation_calls=0$' "$work_directory/run1/conclusion.txt"
test "$(grep -c '^block=' "$work_directory/run1/conclusion.txt")" -eq 6
test "$(wc -l < "$work_directory/run1/selected.csv")" -eq 145
test "$(wc -l < "$work_directory/run1/raw.csv")" -eq 24577
test "$(grep -F -c 'selected_indices=0..23' "$sealed_summary")" -eq 6
test "$(grep -F -c 'raw_rejections=40 ' "$sealed_summary")" -eq 4
test "$(grep -F -c 'raw_rejections=38 ' "$sealed_summary")" -eq 2
sealed_after=$(shasum -a 256 "$sealed_summary")
test "$sealed_before" = "$sealed_after"
block_number=1
while [ "$block_number" -le 6 ]; do
    "$analyze" label "$block_number" > "$work_directory/label"
    drawn=$(paste -s -d, "$work_directory/label")
    stanza=$(awk -v block="$block_number" '
        $0 == "block=" block {keep=1; next}
        keep && $0 ~ /^block=/ {exit}
        keep {print}
    ' "$work_directory/run1/conclusion.txt")
    printf '%s\n' "$stanza" | grep -F -x "indices=$drawn" >/dev/null
    reject_count=$(printf '%s\n' "$stanza" | awk -F= '/^raw_rejections=/ {print $2}')
    run_id="ordinary-reference-block$block_number"
    selected_indices=$(awk -F, -v run_id="$run_id" '
        NR > 1 && $1 == run_id {printf "%s%s", separator, $3; separator = ","}
    ' "$work_directory/run1/selected.csv")
    test "$selected_indices" = "$drawn"
    raw_count=$(awk -F, -v run_id="$run_id" 'NR > 1 && $1 == run_id {total += $NF} END {print total + 0}' \
        "$work_directory/run1/raw.csv")
    test "$reject_count" = "$raw_count"
    block_number=$((block_number + 1))
done
awk -F, -v input_directory="$input_directory" '
    NR == 1 {next}
    {
        path = input_directory "/" $1 ".csv"
        sample = $3
        elapsed = $4
        found = ""
        while ((getline line < path) > 0) {
            split(line, fields, ",")
            if (fields[4] == sample) {
                found = fields[5]
                break
            }
        }
        close(path)
        if (found != elapsed) {
            exit 1
        }
    }
' "$work_directory/run1/selected.csv"
if "$program" --reference-labels-redraw "$input_directory" "$work_directory/run1"; then
    exit 1
fi
