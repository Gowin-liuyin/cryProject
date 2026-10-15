#!/bin/sh
# M2 除法热点微基准已完成运行的只读核对（不需要 sudo，不写频率，不改任何原件）。
# 未执行的 run 记 status=pending；已执行的 run 逐份核对协议与自洽性。
# usage: verify_completed_micro_runs.sh <tree-root> [samples-per-class]
set -eu

if [ "$#" -lt 1 ] || [ "$#" -gt 2 ]; then
    echo "usage: verify_completed_micro_runs.sh <tree-root> [samples-per-class]" >&2
    exit 2
fi
tree_root=$1
samples=${2:-10000}
control_root=/home/nss-marker/yhr/Cry/platform-control-20261016-c011ec7a5e01
runs_dir=${tree_root}/runs
expected_rows=$((samples * 2 + 1))
failed_count=0
pending_count=0
verified_count=0

expect_equal() {
    check_name=$1
    expected_value=$2
    actual_value=$3
    if [ "${expected_value}" = "${actual_value}" ]; then
        printf '  check=%s status=PASS\n' "${check_name}"
    else
        printf '  check=%s status=FAIL expected=%s actual=%s\n' "${check_name}" \
            "${expected_value}" "${actual_value}"
        failed_count=$((failed_count + 1))
    fi
}

for run_name in m2-micro-s1-unfixed m2-micro-s1-fixed m2-micro-s2-unfixed m2-micro-s2-fixed \
    m2-micro-s3-unfixed m2-micro-s3-fixed; do
    case "${run_name}" in
        *-unfixed) variant=unfixed ;;
        *) variant=fixed ;;
    esac
    csv_path=${runs_dir}/${run_name}/${variant}-main.csv
    meta_path=${runs_dir}/${run_name}/${variant}-main.meta
    elf_path=${tree_root}/build-ordinary/microbench/${variant}/m2_hotspot_microbench
    printf 'run=%s variant=%s\n' "${run_name}" "${variant}"
    if [ ! -f "${csv_path}" ] || [ ! -f "${meta_path}" ]; then
        printf '  status=pending (no CSV/meta yet)\n'
        pending_count=$((pending_count + 1))
        continue
    fi
    verified_count=$((verified_count + 1))
    expect_equal csv_header \
        "run_id,implementation,input_category,sample_index,elapsed_nanoseconds,time_unit" \
        "$(head -1 "${csv_path}")"
    expect_equal csv_row_count "${expected_rows}" "$(wc -l <"${csv_path}")"
    expect_equal csv_classes \
        "message-ones=${samples} message-zero=${samples}" \
        "$(tail -n +2 "${csv_path}" | cut -d, -f3 | sort | uniq -c | awk '{printf "%s=%s ", $2, $1}' |
            sed 's/ $//')"
    expect_equal csv_units_ns "$((samples * 2))" \
        "$(tail -n +2 "${csv_path}" | cut -d, -f6 | grep -c '^ns$')"
    expect_equal csv_sample_index "$((samples * 2))" \
        "$(tail -n +2 "${csv_path}" | cut -d, -f4 | grep -c '^[0-9][0-9]*$')"
    expect_equal csv_unique_run_ids 1 "$(tail -n +2 "${csv_path}" | cut -d, -f1 | sort -u | wc -l)"
    expect_equal csv_unique_implementations 1 \
        "$(tail -n +2 "${csv_path}" | cut -d, -f2 | sort -u | wc -l)"
    expect_equal csv_implementation_value "m2-kyber768-round3-${variant}" \
        "$(tail -n +2 "${csv_path}" | cut -d, -f2 | sort -u)"
    expect_equal meta_run_status complete "$(sed -n 's/^run_status=//p' "${meta_path}")"
    expect_equal meta_warmup 100 "$(sed -n 's/^warmup_hotspot_calls=//p' "${meta_path}")"
    expect_equal meta_warmup_attempted 100 \
        "$(sed -n 's/^warmup_attempted_calls=//p' "${meta_path}")"
    expect_equal meta_warmup_completed 100 \
        "$(sed -n 's/^warmup_completed_calls=//p' "${meta_path}")"
    expect_equal meta_samples "${samples}" "$(sed -n 's/^samples_per_class=//p' "${meta_path}")"
    expect_equal meta_row_count "$((samples * 2))" "$(sed -n 's/^row_count=//p' "${meta_path}")"
    expect_equal meta_window_scope one_poly_tomsg_call \
        "$(sed -n 's/^window_scope=//p' "${meta_path}")"
    expect_equal meta_hotspot_symbol pqcrystals_kyber768_ref_poly_tomsg \
        "$(sed -n 's/^hotspot_symbol=//p' "${meta_path}")"
    expect_equal meta_no_zero_elapsed 0 "$(sed -n 's/^zero_elapsed_count=//p' "${meta_path}")"
    expect_equal meta_no_mismatch 0 \
        "$(sed -n 's/^chosen_message_hotspot_mismatch_count=//p' "${meta_path}")"
    expect_equal meta_no_failed_calls 0 \
        "$(sed -n 's/^failed_hotspot_call_count=//p' "${meta_path}")"
    expect_equal meta_affinity not_pinned "$(sed -n 's/^cpu_affinity=//p' "${meta_path}")"
    expect_equal meta_frequency_control not_configured \
        "$(sed -n 's/^frequency_control=//p' "${meta_path}")"
    expect_equal meta_self_hash "$(openssl dgst -sha3-256 "${elf_path}" | sed 's/.*= //')" \
        "$(sed -n 's/^executable_sha3_256=//p' "${meta_path}")"
    expect_equal meta_minimum "$(tail -n +2 "${csv_path}" | cut -d, -f5 | sort -n | head -1)" \
        "$(sed -n 's/^minimum_elapsed_nanoseconds=//p' "${meta_path}")"
    expect_equal meta_maximum "$(tail -n +2 "${csv_path}" | cut -d, -f5 | sort -n | tail -1)" \
        "$(sed -n 's/^maximum_elapsed_nanoseconds=//p' "${meta_path}")"
    terminal_path=${control_root}/runs/${run_name}/terminal.json
    if [ -r "${terminal_path}" ]; then
        expect_equal terminal_reason worker_finished \
            "$(sed -n 's/.*"reason": "\([a-z_]*\)".*/\1/p' "${terminal_path}")"
        expect_equal terminal_worker_exit_code 0 \
            "$(sed -n 's/.*"worker_exit_code": \([0-9]*\).*/\1/p' "${terminal_path}")"
        expect_equal terminal_worker_drained true \
            "$(sed -n 's/.*"worker_drained": \([a-z]*\).*/\1/p' "${terminal_path}")"
        expect_equal terminal_restore_match yes \
            "$(sed -n 's/.*"restore_match": "\([a-z]*\)".*/\1/p' "${terminal_path}")"
    else
        printf '  check=terminal_readable status=SKIPPED path=%s\n' "${terminal_path}"
    fi
done

# 同一 (seed, 类列表, 样本数) 的输入序列摘要在所有 run 上必须逐字节一致。
variant_of_run() {
    case "$1" in
        *-unfixed) printf 'unfixed\n' ;;
        *) printf 'fixed\n' ;;
    esac
}

collect_input_digests() {
    for digest_run_name in "$@"; do
        digest_variant=$(variant_of_run "${digest_run_name}")
        digest_meta_path=${runs_dir}/${digest_run_name}/${digest_variant}-main.meta
        if [ -f "${digest_meta_path}" ]; then
            sed -n 's/^input_sequence_digest=//p' "${digest_meta_path}"
        fi
    done
}

digest_31337=$(collect_input_digests m2-micro-s1-unfixed m2-micro-s1-fixed m2-micro-s3-unfixed \
    m2-micro-s3-fixed | sort -u | wc -l)
digest_424242=$(collect_input_digests m2-micro-s2-unfixed m2-micro-s2-fixed | sort -u | wc -l)
if [ "${verified_count}" -eq 6 ]; then
    expect_equal cross_run_digest_seed31337 1 "${digest_31337}"
    expect_equal cross_run_digest_seed424242 1 "${digest_424242}"
else
    printf 'check=cross_run_digest status=SKIPPED verified_runs=%s\n' "${verified_count}"
fi

printf 'verified_runs=%s pending_runs=%s failed_checks=%s\n' "${verified_count}" \
    "${pending_count}" "${failed_count}"
if [ "${failed_count}" -ne 0 ]; then
    printf 'micro_run_verification_status=FAIL\n'
    exit 1
fi
if [ "${verified_count}" -eq 0 ]; then
    printf 'micro_run_verification_status=pending\n'
    exit 0
fi
printf 'micro_run_verification_status=PASS\n'
