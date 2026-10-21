#!/bin/sh
# M5 重加密路径的 Binsec checkct 运行器。
#
# 用法：run_checkct_m5.sh BINSEC Z3 ELF CONFIG NEW_OUTPUT_DIRECTORY [WALL_TIMEOUT_SECONDS]
#
# 与 tools/platform_m4/run_checkct.sh 同一契约：输入与输出都必须在物理 Cry 之内，
# 输出目录必须是新建的，工具与被测产物的身份逐项落盘。
#
# 判据侧的三条硬约束（照抄 M4 的做法，不放宽）：
#   * 只开 control-flow 与 memory-access 两类检查（multiplication/division
#     在 Binsec 0.11.3 里是实验特性，且与 M2 的 div 类判定无关）。
#   * 深度上限、超时固定，不因结果不好而放宽或重试择优。
#   * 退出码与原始 stdout/stderr 原样保留；「secure/insecure」只以
#     **非零路径数、非零指令数** 的那次运行为准（0 路径的空结论不算阴性证据）。
set -eu

if [ "$#" -lt 5 ] || [ "$#" -gt 6 ]; then
    printf '%s\n' 'usage: run_checkct_m5.sh BINSEC Z3 ELF CONFIG NEW_OUTPUT_DIRECTORY [WALL_TIMEOUT_SECONDS]' >&2
    exit 2
fi
binsec_program=$(realpath "$1")
solver_program=$(realpath "$2")
elf_file=$(realpath "$3")
configuration_file=$(realpath "$4")
output_parent=$(realpath "$(dirname "$5")")
output_name=$(basename "$5")
wall_timeout_seconds=${6:-180}
case "$output_parent" in
    /home/nss-marker/yhr/Cry|/home/nss-marker/yhr/Cry/*) ;;
    *) printf '%s\n' 'Require physical output parent under Cry.' >&2; exit 2 ;;
esac
case "$output_name" in
    ''|.|..) printf '%s\n' 'Require a new output directory name.' >&2; exit 2 ;;
esac
output_directory="$output_parent/$output_name"
for input_path in "$binsec_program" "$solver_program" "$elf_file" "$configuration_file"; do
    case "$input_path" in
        /home/nss-marker/yhr/Cry/*) ;;
        *) printf '%s\n' 'Require every project/tool input under physical Cry.' >&2; exit 2 ;;
    esac
done
if [ -e "$output_directory" ] || [ -L "$output_directory" ]; then
    printf '%s\n' 'Output directory must be new.' >&2
    exit 2
fi
mkdir -- "$output_directory"
output_directory=$(realpath "$output_directory")
case "$output_directory" in
    /home/nss-marker/yhr/Cry/*) ;;
    *) printf '%s\n' 'Require physical output under Cry.' >&2; exit 2 ;;
esac
mkdir "$output_directory/tmp" "$output_directory/cache"
export TMPDIR="$output_directory/tmp"
export TMP="$TMPDIR"
export TEMP="$TMPDIR"
export XDG_CACHE_HOME="$output_directory/cache"
solver_directory=$(dirname "$solver_program")
export PATH="$solver_directory:$PATH"
{
    printf 'binsec=%s\nsolver=%s\nelf=%s\nconfiguration=%s\n' "$binsec_program" \
        "$solver_program" "$elf_file" "$configuration_file"
    "$binsec_program" -version
    "$solver_program" --version
    sha256sum "$binsec_program" "$solver_program" "$elf_file" "$configuration_file"
    file "$elf_file"
} > "$output_directory/identity.txt" 2>&1
cp "$configuration_file" "$output_directory/model.cfg"
objdump -d "$elf_file" > "$output_directory/disasm.txt"
set +e
taskset -c 0,1 timeout --signal=TERM --kill-after=15 "$wall_timeout_seconds" \
    "$binsec_program" -sse -checkct -smt-solver z3 -sse-script "$configuration_file" \
    -sse-depth 10000 -sse-timeout 120 -smt-timeout 5 \
    -checkct-features control-flow,memory-access \
    -checkct-stats-file "$output_directory/checkct.toml" "$elf_file" \
    > "$output_directory/stdout.txt" 2> "$output_directory/stderr.txt"
analysis_status=$?
set -e
printf 'exit_status=%s\ndepth=10000\nanalysis_timeout_seconds=120\nsolver_timeout_seconds=5\nwall_timeout_seconds=%s\n' \
    "$analysis_status" "$wall_timeout_seconds" > "$output_directory/status.txt"
cat "$output_directory/status.txt" "$output_directory/stdout.txt" "$output_directory/stderr.txt"
exit "$analysis_status"
