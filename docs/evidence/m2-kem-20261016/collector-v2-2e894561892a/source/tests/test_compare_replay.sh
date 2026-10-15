#!/bin/sh
set -eu
comparison_program=$1
generator_program=$2
test_directory=$(mktemp -d)
trap 'rm -rf "$test_directory"' EXIT
mkdir "$test_directory/data"
for task_index in 1 2 3 4 5 6 7 8; do
    "$generator_program" generate null "$task_index" \
        "$test_directory/data/task-$task_index.csv" "$test_directory/data/task-$task_index.plan"
done
if "$comparison_program" "$generator_program" /usr/bin/false unused \
    "$test_directory/data" "$test_directory/failure"; then
    exit 1
fi
if "$comparison_program" "$generator_program" /usr/bin/true unused \
    "$test_directory/data" "$test_directory/no-ready" preimported; then
    exit 1
fi
test ! -e "$test_directory/no-ready/comparison.report"
cat > "$test_directory/ready-fixture.sh" <<'EOF'
#!/bin/sh
set -eu
kill -STOP "$$"
exec "$COMPARE_TEST_ANALYZER" analyze "$1" "$2" "$3"
EOF
COMPARE_TEST_ANALYZER="$generator_program"
export COMPARE_TEST_ANALYZER
"$comparison_program" "$generator_program" /bin/sh "$test_directory/ready-fixture.sh" \
    "$test_directory/data" "$test_directory/ready" preimported
test "$(wc -l < "$test_directory/ready/attempts.tsv")" -eq 49
awk -F '\t' 'NR > 1 { if ($5 != 0 || $7 != 1048576 || ($3 == "baseline" && $8 <= 0) || ($3 == "candidate" && $8 != 0)) exit 1 }' \
    "$test_directory/ready/attempts.tsv"
test -s "$test_directory/ready/comparison.report"
test -s "$test_directory/failure/attempts.tsv"
test ! -e "$test_directory/failure/comparison.report"
if "$comparison_program" "$generator_program" /usr/bin/false unused \
    "$test_directory/data" "$test_directory/failure"; then
    exit 1
fi
