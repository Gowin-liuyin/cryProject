#!/bin/sh
# r03 采集件 CLI 拒绝资格：缺参 / 越界 / 已存在路径 / 非法类名 / 混合模式。
# 用法: r03_cli_rejection_check.sh <tool-elf> <scratch-dir>
# 判据：每条用例退出码必须非 0，且 scratch 目录本身不得留下任何文件；
#       预先存在的路径必须原字节保留（放在 scratch/preexisting 子目录里，不计入 leftover）。
set -u

tool_elf=$1
scratch_directory=$2
preexisting_directory=$scratch_directory/preexisting
case_index=0
failure_count=0

mkdir -p -- "$scratch_directory" "$preexisting_directory"
rm -f -- "$scratch_directory"/*.csv "$scratch_directory"/*.meta
: >"$preexisting_directory/raw.csv"
: >"$preexisting_directory/meta.meta"
: >"$preexisting_directory/short-key.bin"
printf 'r03-preexisting-raw-fixture\n' >"$preexisting_directory/raw-with-content.csv"
expected_preexisting_raw_bytes=$(wc -c <"$preexisting_directory/raw-with-content.csv" | tr -d ' ')
expected_preexisting_meta_bytes=$(wc -c <"$preexisting_directory/meta.meta" | tr -d ' ')

run_case() {
    case_name=$1
    shift
    case_index=$((case_index + 1))
    "$tool_elf" "$@" >"$scratch_directory/stdout.txt" 2>"$scratch_directory/stderr.txt"
    case_exit_status=$?
    leftover_count=$(find "$scratch_directory" -maxdepth 1 -type f ! -name stdout.txt ! -name stderr.txt |
        wc -l | tr -d ' ')
    if [ "$case_exit_status" -eq 0 ] || [ "$leftover_count" -ne 0 ]; then
        failure_count=$((failure_count + 1))
        printf 'case=%s exit=%s leftovers=%s FAIL\n' "$case_name" "$case_exit_status" "$leftover_count"
    else
        printf 'case=%s exit=%s leftovers=%s ok\n' "$case_name" "$case_exit_status" "$leftover_count"
    fi
    rm -f -- "$scratch_directory"/stdout.txt "$scratch_directory"/stderr.txt
}

run_case no_arguments
run_case describe_mixed_with_run --describe --class valid --samples 1 --seed 1 --warmup 1 \
    --raw "$scratch_directory/describe-mixed.csv" --meta "$scratch_directory/describe-mixed.meta" \
    --run-id mixed
run_case missing_meta --class valid,malformed,truncated --samples 10 --seed 31337 --warmup 100 \
    --raw "$scratch_directory/missing-meta.csv" --run-id missing-meta
run_case missing_class --samples 10 --seed 31337 --warmup 100 \
    --raw "$scratch_directory/missing-class.csv" --meta "$scratch_directory/missing-class.meta" \
    --run-id missing-class
run_case missing_warmup --class valid --samples 10 --seed 31337 \
    --raw "$scratch_directory/missing-warmup.csv" --meta "$scratch_directory/missing-warmup.meta" \
    --run-id missing-warmup
run_case missing_run_id --class valid --samples 10 --seed 31337 --warmup 100 \
    --raw "$scratch_directory/missing-run-id.csv" --meta "$scratch_directory/missing-run-id.meta"
run_case missing_seed --class valid --samples 10 --warmup 100 \
    --raw "$scratch_directory/missing-seed.csv" --meta "$scratch_directory/missing-seed.meta" \
    --run-id missing-seed
run_case samples_zero --class valid,malformed,truncated --samples 0 --seed 31337 --warmup 100 \
    --raw "$scratch_directory/samples-zero.csv" --meta "$scratch_directory/samples-zero.meta" \
    --run-id samples-zero
run_case samples_over_maximum --class valid,malformed,truncated --samples 20001 --seed 31337 \
    --warmup 100 --raw "$scratch_directory/samples-over.csv" \
    --meta "$scratch_directory/samples-over.meta" --run-id samples-over
run_case warmup_zero --class valid,malformed,truncated --samples 10 --seed 31337 --warmup 0 \
    --raw "$scratch_directory/warmup-zero.csv" --meta "$scratch_directory/warmup-zero.meta" \
    --run-id warmup-zero
run_case warmup_over_maximum --class valid,malformed,truncated --samples 10 --seed 31337 \
    --warmup 10001 --raw "$scratch_directory/warmup-over.csv" \
    --meta "$scratch_directory/warmup-over.meta" --run-id warmup-over
run_case seed_not_numeric --class valid,malformed,truncated --samples 10 --seed 3x337 --warmup 100 \
    --raw "$scratch_directory/seed-not-numeric.csv" --meta "$scratch_directory/seed-not-numeric.meta" \
    --run-id seed-not-numeric
run_case unknown_class --class valid,malformed,unseen --samples 10 --seed 31337 --warmup 100 \
    --raw "$scratch_directory/unknown-class.csv" --meta "$scratch_directory/unknown-class.meta" \
    --run-id unknown-class
run_case duplicated_class --class valid,valid --samples 10 --seed 31337 --warmup 100 \
    --raw "$scratch_directory/duplicated-class.csv" --meta "$scratch_directory/duplicated-class.meta" \
    --run-id duplicated-class
run_case empty_class_token --class valid,,truncated --samples 10 --seed 31337 --warmup 100 \
    --raw "$scratch_directory/empty-class-token.csv" --meta "$scratch_directory/empty-class-token.meta" \
    --run-id empty-class-token
run_case empty_class_list --class '' --samples 10 --seed 31337 --warmup 100 \
    --raw "$scratch_directory/empty-class-list.csv" --meta "$scratch_directory/empty-class-list.meta" \
    --run-id empty-class-list
run_case unknown_option --class valid --samples 10 --seed 31337 --warmup 100 \
    --raw "$scratch_directory/unknown-option.csv" --meta "$scratch_directory/unknown-option.meta" \
    --run-id unknown-option --bogus 1
run_case missing_option_value --class valid --samples 10 --seed 31337 --warmup 100 \
    --raw "$scratch_directory/missing-value.csv" --meta "$scratch_directory/missing-value.meta" \
    --run-id missing-value --seed
run_case invalid_run_id --class valid --samples 10 --seed 31337 --warmup 100 \
    --raw "$scratch_directory/invalid-run-id.csv" --meta "$scratch_directory/invalid-run-id.meta" \
    --run-id 'bad/id'
run_case public_key_without_secret_key --class valid --samples 10 --seed 31337 --warmup 100 \
    --raw "$scratch_directory/half-key.csv" --meta "$scratch_directory/half-key.meta" \
    --run-id half-key --public-key "$preexisting_directory/raw.csv"
run_case same_raw_and_meta_path --class valid --samples 10 --seed 31337 --warmup 100 \
    --raw "$scratch_directory/same-path.csv" --meta "$scratch_directory/same-path.csv" \
    --run-id same-path
run_case raw_path_exists --class valid,malformed,truncated --samples 10 --seed 31337 --warmup 100 \
    --raw "$preexisting_directory/raw-with-content.csv" --meta "$scratch_directory/raw-exists.meta" \
    --run-id raw-exists
run_case meta_path_exists --class valid,malformed,truncated --samples 10 --seed 31337 --warmup 100 \
    --raw "$scratch_directory/meta-exists.csv" --meta "$preexisting_directory/meta.meta" \
    --run-id meta-exists
run_case missing_output_directory --class valid,malformed,truncated --samples 10 --seed 31337 \
    --warmup 100 --raw "$scratch_directory/absent-dir/out.csv" \
    --meta "$scratch_directory/absent-dir/out.meta" --run-id absent-dir
run_case external_key_wrong_size --class valid --samples 10 --seed 31337 --warmup 100 \
    --raw "$scratch_directory/wrong-key.csv" --meta "$scratch_directory/wrong-key.meta" \
    --run-id wrong-key --public-key "$preexisting_directory/short-key.bin" \
    --secret-key "$preexisting_directory/short-key.bin"

preexisting_raw_bytes=$(wc -c <"$preexisting_directory/raw-with-content.csv" | tr -d ' ')
if [ "$preexisting_raw_bytes" -ne "$expected_preexisting_raw_bytes" ]; then
    failure_count=$((failure_count + 1))
    printf 'case=preexisting_raw_bytes_preserved bytes=%s FAIL\n' "$preexisting_raw_bytes"
else
    printf 'case=preexisting_raw_bytes_preserved bytes=%s ok\n' "$preexisting_raw_bytes"
fi
preexisting_meta_bytes=$(wc -c <"$preexisting_directory/meta.meta" | tr -d ' ')
if [ "$preexisting_meta_bytes" -ne "$expected_preexisting_meta_bytes" ]; then
    failure_count=$((failure_count + 1))
    printf 'case=preexisting_meta_bytes_preserved bytes=%s FAIL\n' "$preexisting_meta_bytes"
else
    printf 'case=preexisting_meta_bytes_preserved bytes=%s ok\n' "$preexisting_meta_bytes"
fi

leftover_files=$(find "$scratch_directory" -maxdepth 1 -type f | wc -l | tr -d ' ')
printf 'total_cases=%s failures=%s final_leftovers=%s\n' "$case_index" "$failure_count" "$leftover_files"
if [ "$failure_count" -eq 0 ] && [ "$leftover_files" -eq 0 ]; then
    printf 'cli_rejection_qualification=passed\n'
    exit 0
fi
printf 'cli_rejection_qualification=failed\n'
exit 1
