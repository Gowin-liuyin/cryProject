#!/bin/sh
# run_pair.sh：一次性拉起 "观测者 + 受害者 wrapper" 一对进程并 join 类别表。
# 只做进程编排与数据 join，不做统计；统计由 mde_budget.py（预研）与 C 件承担。
#
# 用法（smt，R18）：
#   run_pair.sh --protocol smt --observer <smt_observer> --victim <victim_wrapper> \
#     --outdir <dir> --run-id <id> --seed <n> --batches <n> \
#     [--cpu-victim 2 --cpu-observer 18 --div-batch 4096]
# 用法（cache，R19）：
#   run_pair.sh --protocol cache --observer <cache_observer> --victim <victim_wrapper> \
#     --outdir <dir> --run-id <id> --seed <n> --batches <n> --map <lut.bin> --layout <json> \
#     [--cpu-victim 2 --cpu-observer 18 --line-count 2]
# 说明：cache 的 --batches 传"样本数"；观测者 --samples 由本脚本换算为 样本数×line-count。
# 绑核经 taskset 实施（cache 观测者无 --cpu 参数；smt 观测者亦统一走 taskset）。
# mock 受害者读取 VICTIM_MOCK_LUT_PATH（cache 自检用），经 --mock-lut 传入。
set -eu

usage() {
    printf 'usage: run_pair.sh --protocol smt|cache --observer <elf> --victim <elf> --outdir <dir>\n' >&2
    printf '       --run-id <id> --seed <n> --batches <n> [--cpu-victim <n>] [--cpu-observer <n>]\n' >&2
    printf '       [--div-batch 4096] [--line-count 2] [--map <file>] [--layout <json>] [--mock-lut <file>]\n' >&2
    exit 1
}

PROTOCOL=
OBSERVER=
VICTIM=
OUTDIR=
RUN_ID=
SEED=
BATCHES=
CPU_VICTIM=
CPU_OBSERVER=
DIV_BATCH=4096
LINE_COUNT=2
MAP_FILE=
LAYOUT_FILE=
MOCK_LUT=

while [ $# -gt 0 ]; do
    case "$1" in
        --protocol) PROTOCOL=$2; shift 2 ;;
        --observer) OBSERVER=$2; shift 2 ;;
        --victim) VICTIM=$2; shift 2 ;;
        --outdir) OUTDIR=$2; shift 2 ;;
        --run-id) RUN_ID=$2; shift 2 ;;
        --seed) SEED=$2; shift 2 ;;
        --batches) BATCHES=$2; shift 2 ;;
        --cpu-victim) CPU_VICTIM=$2; shift 2 ;;
        --cpu-observer) CPU_OBSERVER=$2; shift 2 ;;
        --div-batch) DIV_BATCH=$2; shift 2 ;;
        --line-count) LINE_COUNT=$2; shift 2 ;;
        --map) MAP_FILE=$2; shift 2 ;;
        --layout) LAYOUT_FILE=$2; shift 2 ;;
        --mock-lut) MOCK_LUT=$2; shift 2 ;;
        *) usage ;;
    esac
done

[ -n "$PROTOCOL" ] && [ -n "$OBSERVER" ] && [ -n "$VICTIM" ] && [ -n "$OUTDIR" ] \
    && [ -n "$RUN_ID" ] && [ -n "$SEED" ] && [ -n "$BATCHES" ] || usage
case "$PROTOCOL" in
    smt|cache) ;;
    *) usage ;;
esac
REPO_ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/../.." && pwd)
JOINER="$REPO_ROOT/scripts/platform_stats/join_observer_classes.py"
PYTHON=${PYTHON3_EXECUTABLE:-python3}

RUN_DIR="$OUTDIR/runs/$RUN_ID"
SYNC_DIR="$OUTDIR/sync"
mkdir -p "$RUN_DIR" "$SYNC_DIR"
SYNC_FILE="$SYNC_DIR/$PROTOCOL-turn.bin"
rm -f "$SYNC_FILE" "$RUN_DIR"/*.csv "$RUN_DIR"/*.meta 2>/dev/null || true

VICTIM_TASKSET=""
[ -n "$CPU_VICTIM" ] && VICTIM_TASKSET="taskset -c $CPU_VICTIM"
OBSERVER_TASKSET=""
[ -n "$CPU_OBSERVER" ] && OBSERVER_TASKSET="taskset -c $CPU_OBSERVER"

if [ "$PROTOCOL" = smt ]; then
    OBSERVER_CSV_NAME=observer-batches.csv
    OBSERVER_ARGS="--cpu ${CPU_OBSERVER:-0} --div-batch $DIV_BATCH --batches $BATCHES \
--sync-file $SYNC_FILE --output $RUN_DIR/$OBSERVER_CSV_NAME --victim-run-id $RUN_ID"
else
    [ -n "$MAP_FILE" ] && [ -n "$LAYOUT_FILE" ] || usage
    OBSERVER_CSV_NAME=observer-reloads.csv
    # 观测者的 --samples 是外层样本数，其协议轮数 = samples×line_count，
    # 与 wrapper 的窗口数（batches×line_count）一比一咬合须传 batches 本身。
    OBSERVER_ARGS="--map $MAP_FILE --layout $LAYOUT_FILE --samples $BATCHES \
--sync-file $SYNC_FILE --output $RUN_DIR/$OBSERVER_CSV_NAME --victim-run-id $RUN_ID"
fi

MOCK_ENV=""
[ -n "$MOCK_LUT" ] && MOCK_ENV="VICTIM_MOCK_LUT_PATH=$MOCK_LUT"

# 先起受害者（创建同步文件并进入宽限），再起观测者（宽限期内 open）。
$VICTIM_TASKSET env $MOCK_ENV "$VICTIM" \
    --sync-file "$SYNC_FILE" --protocol "$PROTOCOL" --batches "$BATCHES" --seed "$SEED" \
    --run-id "$RUN_ID" --line-count "$LINE_COUNT" \
    --victim-csv "$RUN_DIR/victim.csv" --victim-meta "$RUN_DIR/victim.meta" \
    --classes-csv "$RUN_DIR/batch-classes.csv" >"$RUN_DIR/victim.stdout" 2>"$RUN_DIR/victim.stderr" &
VICTIM_PID=$!
sleep 0.3
$OBSERVER_TASKSET "$OBSERVER" $OBSERVER_ARGS >"$RUN_DIR/observer.stdout" 2>"$RUN_DIR/observer.stderr" &
OBSERVER_PID=$!

VICTIM_STATUS=0
OBSERVER_STATUS=0
wait "$VICTIM_PID" || VICTIM_STATUS=$?
wait "$OBSERVER_PID" || OBSERVER_STATUS=$?
printf 'victim_exit=%d observer_exit=%d\n' "$VICTIM_STATUS" "$OBSERVER_STATUS" | tee "$RUN_DIR/exit-status.txt"
if [ "$VICTIM_STATUS" -ne 0 ] || [ "$OBSERVER_STATUS" -ne 0 ]; then
    exit 2
fi

"$PYTHON" "$JOINER" \
    --observer-csv "$RUN_DIR/$OBSERVER_CSV_NAME" \
    --classes-csv "$RUN_DIR/batch-classes.csv" \
    --protocol "$PROTOCOL" --line-count "$LINE_COUNT" \
    --output "$RUN_DIR/class-pair.csv"
printf 'outputs: %s\n' "$RUN_DIR"
