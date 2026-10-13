#!/bin/bash
# 确认会话。覆盖率低于 0.99、窗口退出非 0 或墙钟超过 6 小时就停止，不换种子补抽。
set -u
run=/home/nss-marker/yhr/Cry/v4-confirmation-8709dfe
exec > "$run/log/confirm-wrapper.txt" 2>&1
window="$run/source/build/cmake/v4_window"
collector="$run/source/build/cmake/encoder_branch/v4_collect"
analyzer="$run/source/build/cmake/v4_analyze"
test -x "$window"
test -x "$collector"
test -x "$analyzer"
independent_sha=$(sha256sum "$collector" | awk 'NR==1 {print $1}')
recorded_sha=$(awk 'NR==1 {print $1}' "$run/log/binary-sha256.txt")
if [ "$independent_sha" != "$recorded_sha" ]; then
    echo "BINARY_SHA_MISMATCH $independent_sha $recorded_sha"
    exit 1
fi
date -u +confirm_start=%Y-%m-%dT%H:%M:%SZ > "$run/log/confirm-time.txt"
mkdir -p "$run/sessions"
: > "$run/sessions/manifest.txt"
: > "$run/log/confirm-exits.txt"
deadline=$((SECONDS + 6 * 60 * 60))
completed=0
for session_index in $(seq 1 40); do
    if [ "$SECONDS" -ge "$deadline" ]; then
        echo "stopped_wall_clock index=$session_index" | tee -a "$run/log/confirm-exits.txt"
        break
    fi
    session_id=$(printf 's%02d' "$session_index")
    session_seed=$((20261014000 + session_index))
    session_dir="$run/sessions/$session_id"
    mkdir -p "$session_dir"
    "$window" run "$session_dir" -- "$collector" confirm-8709dfe "$session_id" "$session_seed" 2 \
        "$session_dir/calls.csv" "$session_dir/meta.txt" "$session_dir/empty.csv"
    window_exit=$?
    printf '%s\n' "$independent_sha" > "$session_dir/binary.sha256"
    coverage_text=$(sed -n 's/^coverage_fraction=//p' "$session_dir/coverage.txt" 2>/dev/null || true)
    echo "$session_id seed=$session_seed window_exit=$window_exit coverage_fraction=${coverage_text:-missing}" \
        >> "$run/log/confirm-exits.txt"
    echo "$session_dir" >> "$run/sessions/manifest.txt"
    if [ "$window_exit" -ne 0 ]; then
        echo "stop_window_exit=$window_exit" >> "$run/log/confirm-exits.txt"
        break
    fi
    python3 - "$coverage_text" <<'PY'
import sys
try:
    fraction = float(sys.argv[1])
except ValueError:
    sys.exit(1)
sys.exit(0 if fraction >= 0.99 else 1)
PY
    if [ "$?" -ne 0 ]; then
        echo "stop_coverage" >> "$run/log/confirm-exits.txt"
        break
    fi
    completed=$((completed + 1))
done
echo "completed_coverage_pass=$completed" >> "$run/log/confirm-exits.txt"
date -u +confirm_end=%Y-%m-%dT%H:%M:%SZ >> "$run/log/confirm-time.txt"
mkdir -p "$run/analysis/confirm-run1" "$run/analysis/confirm-run2"
"$analyzer" confirm-sessions "$run/sessions/manifest.txt" "$run/analysis/confirm-run1" confirmation \
    > "$run/analysis/confirm-run1/stdout.txt" || echo "analyze1_exit=$?" >> "$run/log/confirm-exits.txt"
"$analyzer" confirm-sessions "$run/sessions/manifest.txt" "$run/analysis/confirm-run2" confirmation \
    > "$run/analysis/confirm-run2/stdout.txt" || echo "analyze2_exit=$?" >> "$run/log/confirm-exits.txt"
if cmp -s "$run/analysis/confirm-run1/conclusion.txt" "$run/analysis/confirm-run2/conclusion.txt"; then
    echo "conclusions_match=yes" >> "$run/log/confirm-exits.txt"
else
    echo "conclusions_match=no" >> "$run/log/confirm-exits.txt"
fi
echo CONFIRM_COLLECT_DONE
