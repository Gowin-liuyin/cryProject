#!/bin/sh
set -eu

if [ "$#" -ne 3 ]; then
    echo "usage: test_attribution_v3.sh fixture|sealed BINARY SOURCE_ROOT" >&2
    exit 1
fi

mode=$1
binary=$2
source_root=$3

if [ -z "${A113_TEST_TMPDIR:-}" ]; then
    echo "A113_TEST_TMPDIR is required" >&2
    exit 1
fi

csv_header="schema,run_id,session_id,block_id,key_id,sample_index,predecessor_category,category,generator_label,elapsed_clock_counts,clock_path,ciphertext_sha256_hex"

fail() {
    echo "attribution_v3 test failed: $1" >&2
    exit 1
}

expect_line() {
    file=$1
    line=$2
    if ! grep -F -x -q -- "$line" "$file"; then
        echo "missing line: $line" >&2
        echo "in $file" >&2
        exit 1
    fi
}

write_decision() {
    output=$1
    shift
    count=0
    total=0
    for value in "$@"; do
        count=$((count + 1))
        total=$((total + value))
    done
    if [ "$count" -eq 0 ]; then
        fail "empty decision"
    fi
    mean=$((total / count))
    if [ $((mean * count)) -ne "$total" ]; then
        fail "fixture mean is not an integer"
    fi
    {
        printf 'phase=confirmation\n'
        printf 'primary_mean_difference_counts=%s\n' "$mean"
        index=1
        for value in "$@"; do
            printf 'session_effect session_id=s%s difference=%s\n' "$index" "$value"
            index=$((index + 1))
        done
    } >"$output"
}

hash_manifest_line() {
    role=$1
    path=$2
    hash=$(shasum -a 256 "$path" | awk 'NR == 1 { print $1 }')
    printf '%s %s %s\n' "$hash" "$role" "$path"
}

run_manifest() {
    manifest=$1
    output=$2
    expected_exit=$3
    mkdir -p "$output"
    set +e
    "$binary" "$manifest" "$output" >"$output/stdout.txt"
    status=$?
    set -e
    if [ "$status" -ne "$expected_exit" ]; then
        echo "exit $status, expected $expected_exit" >&2
        cat "$output/stdout.txt" >&2 || true
        exit 1
    fi
    if ! cmp -s "$output/stdout.txt" "$output/conclusion.txt"; then
        fail "stdout and conclusion.txt differ"
    fi
}

"$binary" --self-check

if [ "$mode" = "fixture" ]; then
    work="${A113_TEST_TMPDIR}/attribution-v3-fixture"
    rm -rf "$work"
    mkdir -p "$work/level" "$work/trend" "$work/partial" "$work/recompute" "$work/mismatch" "$work/digest"
    write_decision "$work/level/decision.txt" 10 10 10 10 10 10
    write_decision "$work/trend/decision.txt" -50 -30 -10 10 30 50
    write_decision "$work/partial/decision.txt" -15 -7 1 9 17 25
    hash_manifest_line decision:v3 "$work/level/decision.txt" >"$work/level/manifest.txt"
    hash_manifest_line decision:v3 "$work/trend/decision.txt" >"$work/trend/manifest.txt"
    hash_manifest_line decision:v3 "$work/partial/decision.txt" >"$work/partial/manifest.txt"
    run_manifest "$work/level/manifest.txt" "$work/level/out" 0
    run_manifest "$work/trend/manifest.txt" "$work/trend/out" 0
    run_manifest "$work/partial/manifest.txt" "$work/partial/out" 0
    expect_line "$work/level/out/conclusion.txt" "status=ok"
    expect_line "$work/level/out/conclusion.txt" "rule_id=v3_attribution_20261013"
    expect_line "$work/level/out/conclusion.txt" "v3_effect_explained_by_drift=no"
    expect_line "$work/trend/out/conclusion.txt" "v3_effect_explained_by_drift=yes_pure_trend"
    expect_line "$work/partial/out/conclusion.txt" "v3_effect_explained_by_drift=partial"

    {
        printf '%s\n' "$csv_header"
        printf '%s\n' "session_decapsulation_v1,fixture,s1,1,k,0,none,message-zero,g,100,CLOCK_MONOTONIC,aa"
        printf '%s\n' "session_decapsulation_v1,fixture,s1,1,k,1,message-zero,message-ones,g,90,CLOCK_MONOTONIC,bb"
    } >"$work/recompute/vulnerable-s1.csv"
    write_decision "$work/recompute/decision.txt" 10
    {
        hash_manifest_line decision:v1 "$work/recompute/decision.txt"
        hash_manifest_line csv:v1 "$work/recompute/vulnerable-s1.csv"
    } >"$work/recompute/manifest.txt"
    run_manifest "$work/recompute/manifest.txt" "$work/recompute/out" 0
    expect_line "$work/recompute/out/conclusion.txt" "recompute=matched"

    write_decision "$work/mismatch/decision.txt" 12
    cp "$work/recompute/vulnerable-s1.csv" "$work/mismatch/vulnerable-s1.csv"
    {
        hash_manifest_line decision:v1 "$work/mismatch/decision.txt"
        hash_manifest_line csv:v1 "$work/mismatch/vulnerable-s1.csv"
    } >"$work/mismatch/manifest.txt"
    run_manifest "$work/mismatch/manifest.txt" "$work/mismatch/out" 3
    expect_line "$work/mismatch/out/conclusion.txt" "status=stopped_recompute_mismatch"

    awk 'NR == 1 { prefix = (substr($1, 1, 1) == "a") ? "b" : "a"; $1 = prefix substr($1, 2) } { print }' \
        "$work/level/manifest.txt" >"$work/digest/manifest.txt"
    run_manifest "$work/digest/manifest.txt" "$work/digest/out" 2
    expect_line "$work/digest/out/conclusion.txt" "status=stopped_digest_mismatch"
    expect_line "$work/digest/out/conclusion.txt" "whether_minus_5_467_explained_by_drift=not_decided"
    exit 0
fi

if [ "$mode" != "sealed" ]; then
    fail "unknown mode"
fi

cd "$source_root"
manifest="docs/research/v3-attribution-20261013/INPUTS.sha256"
while read -r hash role path; do
    case "$hash" in
    "" | \#*)
        continue
        ;;
    esac
    actual=$(shasum -a 256 "$path" | awk 'NR == 1 { print $1 }')
    if [ "$actual" != "$hash" ]; then
        echo "sealed digest mismatch: $path" >&2
        exit 1
    fi
    unset role
done <"$manifest"

first="${A113_TEST_TMPDIR}/attribution-v3-sealed-1"
second="${A113_TEST_TMPDIR}/attribution-v3-sealed-2"
rm -rf "$first" "$second"
mkdir -p "$first" "$second"
set +e
"$binary" --expect-sealed "$manifest" "$first" >"$first/stdout.txt"
first_status=$?
"$binary" --expect-sealed "$manifest" "$second" >"$second/stdout.txt"
second_status=$?
set -e
if [ "$first_status" -ne 0 ] || [ "$second_status" -ne 0 ]; then
    echo "sealed run failed: $first_status $second_status" >&2
    cat "$first/stdout.txt" >&2 || true
    exit 1
fi
if ! cmp -s "$first/stdout.txt" "$first/conclusion.txt"; then
    fail "sealed stdout differs from conclusion"
fi
if ! cmp -s "$first/stdout.txt" "$second/stdout.txt"; then
    fail "sealed runs differ"
fi
expect_line "$first/conclusion.txt" "rule_id=v3_attribution_20261013"
expect_line "$first/conclusion.txt" "status=ok"
if ! grep -E -x -q 'whether_minus_5_467_explained_by_drift=(no|partial|not_linear|yes_pure_trend|inconclusive|not_decided|citation_not_matched)' \
    "$first/conclusion.txt"; then
    fail "missing whether line"
fi
if ! grep -E -x -q 'v3_effect_explained_by_drift=(no|partial|not_linear|yes_pure_trend|inconclusive|not_run)' \
    "$first/conclusion.txt"; then
    fail "missing v3 token"
fi
python3 - "$first/conclusion.txt" "$first/sessions-v3.csv" <<'PY'
import sys
conclusion = open(sys.argv[1], encoding="utf-8").read().splitlines()
mean = None
for line in conclusion:
    if line.startswith("v3_primary_mean_counts="):
        mean = float(line.split("=", 1)[1])
if mean is None:
    raise SystemExit("sealed conclusion has no v3 mean")
total = 0.0
count = 0
for line in open(sys.argv[2], encoding="utf-8"):
    if line.startswith("session_number"):
        continue
    total += float(line.split(",")[1])
    count += 1
if count != 20:
    raise SystemExit("expected 20 v3 sessions, got %s" % count)
if abs(total / count - mean) > 1e-9:
    raise SystemExit("session mean does not match printed primary mean")
PY
