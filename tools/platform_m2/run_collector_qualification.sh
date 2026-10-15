#!/bin/sh
# collector-v2 资格运行：功能资格 + 采集冒烟 + 类顺序可重放 + 跨版本等价。
# 所有输出都落在 --output-dir 内；脚本不写该目录之外的任何路径，也不 fork 采集进程。
set -u

build_root=
output_dir=
key_seed=cryproject-m2-collector-v2-public-test-key-20261016
tag=qualification
kat_vector=

usage() {
    cat <<'USAGE'
usage: run_collector_qualification.sh --build-root DIR --output-dir DIR [options]
  --key-seed TEXT    夹具密钥的公开测试种子文本
  --tag NAME         本次资格标签，只写进日志
  --kat-vector PATH  官方 round3 .rsp 路径；给出且可读时才跑公开 KAT
  build-root 需含 collector/{unfixed,fixed}/m2_decaps_collector 与
  qualification/{unfixed,fixed}/{m2_collector_selftest,m2_make_keypair,
  m2_platform_functional,m2_platform_rng_failure}。
USAGE
}

while [ "$#" -gt 0 ]; do
    case "$1" in
        --build-root) build_root=${2:-}; shift 2 ;;
        --output-dir) output_dir=${2:-}; shift 2 ;;
        --key-seed) key_seed=${2:-}; shift 2 ;;
        --tag) tag=${2:-}; shift 2 ;;
        --kat-vector) kat_vector=${2:-}; shift 2 ;;
        --help|-h) usage; exit 0 ;;
        *) usage >&2; exit 2 ;;
    esac
done

if [ -z "${build_root}" ] || [ -z "${output_dir}" ]; then
    usage >&2
    exit 2
fi
if [ -e "${output_dir}" ]; then
    printf 'output-dir already exists: %s\n' "${output_dir}" >&2
    exit 2
fi

log_dir=${output_dir}/logs
fixture_dir=${output_dir}/fixtures
smoke_dir=${output_dir}/smoke
mkdir -p "${log_dir}" "${fixture_dir}" "${smoke_dir}" "${fixture_dir}/fixed-check"

failures=0
step_count=0

record_step() {
    step_name=$1
    shift
    step_count=$((step_count + 1))
    {
        printf 'command:'
        for step_argument in "$@"; do
            printf ' %s' "${step_argument}"
        done
        printf '\n'
    } > "${log_dir}/${step_name}.command"
    "$@" > "${log_dir}/${step_name}.stdout" 2> "${log_dir}/${step_name}.stderr"
    step_status=$?
    printf '%s\n' "${step_status}" > "${log_dir}/${step_name}.status"
    printf '%-46s exit=%s\n' "${step_name}" "${step_status}"
    if [ "${step_status}" -ne 0 ]; then
        failures=$((failures + 1))
    fi
}

report_pass() {
    printf 'check pass: %s\n' "$1"
}

report_fail() {
    printf 'check FAIL: %s\n' "$1"
    failures=$((failures + 1))
}

check_status() {
    check_label=$1
    shift
    if "$@"; then
        report_pass "${check_label}"
    else
        report_fail "${check_label}"
    fi
}

check_equal() {
    check_label=$1
    left_value=$2
    right_value=$3
    if [ -n "${left_value}" ] && [ "${left_value}" = "${right_value}" ]; then
        report_pass "${check_label}"
    else
        report_fail "${check_label} (left=${left_value} right=${right_value})"
    fi
}

check_files_equal() {
    check_label=$1
    left_file=$2
    right_file=$3
    if cmp -s "${left_file}" "${right_file}"; then
        report_pass "${check_label}"
    else
        report_fail "${check_label}"
    fi
}

check_files_different() {
    check_label=$1
    left_file=$2
    right_file=$3
    if cmp -s "${left_file}" "${right_file}"; then
        report_fail "${check_label}"
    else
        report_pass "${check_label}"
    fi
}

meta_field() {
    sed -n "s/^$2=//p" "$1" | head -n 1
}

check_meta_complete() {
    meta_path=$1
    check_status "meta run_status complete: ${meta_path}" \
        grep -q '^run_status=complete$' "${meta_path}"
    check_status "meta zero elapsed zero: ${meta_path}" \
        grep -q '^zero_elapsed_count=0$' "${meta_path}"
    check_status "meta no failed decapsulation: ${meta_path}" \
        grep -q '^failed_decapsulation_count=0$' "${meta_path}"
    check_status "meta no accept mismatch: ${meta_path}" \
        grep -q '^chosen_message_accept_mismatch_count=0$' "${meta_path}"
    check_status "meta clock monotonic: ${meta_path}" \
        grep -q '^clock=CLOCK_MONOTONIC$' "${meta_path}"
    check_status "meta time unit ns: ${meta_path}" grep -q '^time_unit=ns$' "${meta_path}"
    check_status "meta warmup 100: ${meta_path}" \
        grep -q '^warmup_decapsulations=100$' "${meta_path}"
    check_status "meta warmup completed 100: ${meta_path}" \
        grep -q '^warmup_completed_calls=100$' "${meta_path}"
    check_status "meta warmup attempted 100: ${meta_path}" \
        grep -q '^warmup_attempted_calls=100$' "${meta_path}"
    check_status "meta window is one complete decapsulation: ${meta_path}" \
        grep -q '^window_scope=one_complete_mlkem_decapsulate$' "${meta_path}"
}

collector_unfixed=${build_root}/collector/unfixed/m2_decaps_collector
collector_fixed=${build_root}/collector/fixed/m2_decaps_collector
qualification_unfixed=${build_root}/qualification/unfixed
qualification_fixed=${build_root}/qualification/fixed

{
    printf 'tag=%s\n' "${tag}"
    printf 'date_utc=%s\n' "$(date -u '+%Y-%m-%dT%H:%M:%SZ')"
    printf 'build_root=%s\n' "${build_root}"
    printf 'output_dir=%s\n' "${output_dir}"
    printf 'key_seed=%s\n' "${key_seed}"
    uname -a
    printf 'nproc=%s\n' "$(nproc)"
    /usr/bin/clang-18 --version | head -n 1
    cmake --version | head -n 1
    ls -l "${collector_unfixed}" "${collector_fixed}"
    sha256sum "${collector_unfixed}" "${collector_fixed}"
} > "${log_dir}/environment.txt" 2>&1

check_status "ordinary collector ELF exists (unfixed)" test -x "${collector_unfixed}"
check_status "ordinary collector ELF exists (fixed)" test -x "${collector_fixed}"

# 1) 夹具密钥：两个变体必须给出逐字节相同的 pk/sk。
record_step keypair-unfixed "${qualification_unfixed}/m2_make_keypair" --key-seed "${key_seed}" \
    --public-key "${fixture_dir}/pk.bin" --secret-key "${fixture_dir}/sk.bin"
record_step keypair-fixed "${qualification_fixed}/m2_make_keypair" --key-seed "${key_seed}" \
    --public-key "${fixture_dir}/fixed-check/pk.bin" --secret-key "${fixture_dir}/fixed-check/sk.bin"
check_files_equal "public key identical across variants" "${fixture_dir}/pk.bin" \
    "${fixture_dir}/fixed-check/pk.bin"
check_files_equal "secret key identical across variants" "${fixture_dir}/sk.bin" \
    "${fixture_dir}/fixed-check/sk.bin"
sha256sum "${fixture_dir}/pk.bin" "${fixture_dir}/sk.bin" > "${log_dir}/fixtures.sha256"

# 2) 功能资格：类语义、隐式拒绝公式、类顺序重放、CLI 准入、公开 KAT。
for variant in unfixed fixed; do
    qualification_dir=${build_root}/qualification/${variant}
    record_step "selftest-${variant}" "${qualification_dir}/m2_collector_selftest"
    record_step "selftest-transcript-${variant}" "${qualification_dir}/m2_collector_selftest" \
        --transcript
    record_step "platform-functional-${variant}" "${qualification_dir}/m2_platform_functional"
    record_step "platform-rng-failure-${variant}" "${qualification_dir}/m2_platform_rng_failure"
    if [ -n "${kat_vector}" ] && [ -r "${kat_vector}" ] && \
        [ -x "${qualification_dir}/m2_platform_kat" ]; then
        record_step "platform-public-kat-${variant}" "${qualification_dir}/m2_platform_kat" \
            "${kat_vector}"
    fi
done
cp "${log_dir}/selftest-transcript-unfixed.stdout" "${log_dir}/transcript-unfixed.txt"
cp "${log_dir}/selftest-transcript-fixed.stdout" "${log_dir}/transcript-fixed.txt"
check_files_equal "collector transcripts identical across variants" \
    "${log_dir}/transcript-unfixed.txt" "${log_dir}/transcript-fixed.txt"

# 3) 采集冒烟：四个类各 200 行，另有主类对 100 行；全部使用新输出路径。
run_collection() {
    run_name=$1
    run_variant=$2
    run_seed=$3
    run_class=$4
    run_samples=$5
    case "${run_variant}" in
        unfixed) run_collector=${collector_unfixed} ;;
        fixed) run_collector=${collector_fixed} ;;
    esac
    record_step "${run_name}" "${run_collector}" --class "${run_class}" --samples "${run_samples}" \
        --seed "${run_seed}" --raw "${smoke_dir}/${run_name}.csv" \
        --meta "${smoke_dir}/${run_name}.meta" --run-id "${run_name}" \
        --public-key "${fixture_dir}/pk.bin" --secret-key "${fixture_dir}/sk.bin"
}

run_collection smoke_u_seed31337 unfixed 31337 all 200
run_collection smoke_f_seed31337 fixed 31337 all 200
run_collection smoke_u_seed31337_replay unfixed 31337 all 200
run_collection smoke_u_seed424242 unfixed 424242 all 200
run_collection main_u_seed31337 unfixed 31337 message-zero,message-ones 100
run_collection main_f_seed31337 fixed 31337 message-zero,message-ones 100

for run_name in smoke_u_seed31337 smoke_f_seed31337 smoke_u_seed31337_replay \
    smoke_u_seed424242 main_u_seed31337 main_f_seed31337; do
    check_meta_complete "${smoke_dir}/${run_name}.meta"
    cut -d, -f3 "${smoke_dir}/${run_name}.csv" > "${smoke_dir}/${run_name}.classes"
    cut -d, -f5 "${smoke_dir}/${run_name}.csv" | tail -n +2 | sort -n | head -n 1 \
        > "${smoke_dir}/${run_name}.minimum_ns"
    sed -n 's/^minimum_elapsed_nanoseconds=//p' "${smoke_dir}/${run_name}.meta" \
        > "${smoke_dir}/${run_name}.meta_minimum_ns"
    check_files_equal "${run_name} keeps the smallest raw value" \
        "${smoke_dir}/${run_name}.minimum_ns" "${smoke_dir}/${run_name}.meta_minimum_ns"
done

check_equal "smoke data rows 800 (4 classes x 200)" \
    "$(($(wc -l < "${smoke_dir}/smoke_u_seed31337.csv") - 1))" "800"
check_equal "main-pair data rows 200 (2 classes x 100)" \
    "$(($(wc -l < "${smoke_dir}/main_u_seed31337.csv") - 1))" "200"
check_equal "per-class row counts all equal 200" \
    "$(cut -d, -f3 "${smoke_dir}/smoke_u_seed31337.csv" | tail -n +2 | sort | uniq -c | \
        awk '{print $1}' | sort -u | tr -d ' ')" "200"
check_equal "per-class row counts all equal 100" \
    "$(cut -d, -f3 "${smoke_dir}/main_u_seed31337.csv" | tail -n +2 | sort | uniq -c | \
        awk '{print $1}' | sort -u | tr -d ' ')" "100"
for run_name in smoke_u_seed31337 smoke_u_seed424242; do
    sort "${smoke_dir}/${run_name}.classes" > "${smoke_dir}/${run_name}.classes.sorted"
done
check_files_equal "same seed replays identical class order" \
    "${smoke_dir}/smoke_u_seed31337.classes" "${smoke_dir}/smoke_u_seed31337_replay.classes"
check_equal "same seed replays identical input digest" \
    "$(meta_field "${smoke_dir}/smoke_u_seed31337.meta" input_sequence_digest)" \
    "$(meta_field "${smoke_dir}/smoke_u_seed31337_replay.meta" input_sequence_digest)"
check_files_different "different seed changes class order" \
    "${smoke_dir}/smoke_u_seed31337.classes" "${smoke_dir}/smoke_u_seed424242.classes"
check_files_equal "different seed keeps the class multiset" \
    "${smoke_dir}/smoke_u_seed31337.classes.sorted" "${smoke_dir}/smoke_u_seed424242.classes.sorted"
check_files_equal "both variants share seed 31337 class order" \
    "${smoke_dir}/smoke_u_seed31337.classes" "${smoke_dir}/smoke_f_seed31337.classes"
check_equal "both variants share seed 31337 input digest" \
    "$(meta_field "${smoke_dir}/smoke_u_seed31337.meta" input_sequence_digest)" \
    "$(meta_field "${smoke_dir}/smoke_f_seed31337.meta" input_sequence_digest)"
check_files_equal "both variants share main-pair class order" \
    "${smoke_dir}/main_u_seed31337.classes" "${smoke_dir}/main_f_seed31337.classes"
check_equal "both variants share main-pair input digest" \
    "$(meta_field "${smoke_dir}/main_u_seed31337.meta" input_sequence_digest)" \
    "$(meta_field "${smoke_dir}/main_f_seed31337.meta" input_sequence_digest)"
check_equal "malformed classes present in control run" \
    "$(cut -d, -f3 "${smoke_dir}/smoke_u_seed31337.csv" | tail -n +2 | sort -u | tr '\n' ' ')" \
    "malformed-ff-tail malformed-zero-tail message-ones message-zero "

{
    printf 'collector_unfixed=%s\n' "${collector_unfixed}"
    sha256sum "${collector_unfixed}"
    printf 'collector_fixed=%s\n' "${collector_fixed}"
    sha256sum "${collector_fixed}"
    printf 'input_sequence_digest_unfixed_seed31337=%s\n' \
        "$(meta_field "${smoke_dir}/smoke_u_seed31337.meta" input_sequence_digest)"
    printf 'input_sequence_digest_fixed_seed31337=%s\n' \
        "$(meta_field "${smoke_dir}/smoke_f_seed31337.meta" input_sequence_digest)"
    printf 'input_sequence_digest_unfixed_main_seed31337=%s\n' \
        "$(meta_field "${smoke_dir}/main_u_seed31337.meta" input_sequence_digest)"
    printf 'input_sequence_digest_fixed_main_seed31337=%s\n' \
        "$(meta_field "${smoke_dir}/main_f_seed31337.meta" input_sequence_digest)"
} > "${log_dir}/collector-identity.txt"

printf 'steps=%s failures=%s\n' "${step_count}" "${failures}" | tee "${output_dir}/qualification-summary.txt"
if [ "${failures}" -ne 0 ]; then
    printf 'collector qualification FAILED with %s failing check(s)\n' "${failures}" >&2
    exit 1
fi
printf 'collector qualification passed\n'
