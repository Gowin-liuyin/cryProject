#!/bin/sh
set -eu

module_root=$1
compiler_path=$2
patched_valgrind=$3
case "$module_root" in
    /home/nss-marker/yhr/Cry/platform-m5-20261016-*) ;;
    *) printf '%s\n' 'Expected new M5 Cry root' >&2; exit 2 ;;
esac
if [ "$(realpath "$module_root")" != "$module_root" ]; then
    printf '%s\n' 'Physical root mismatch' >&2
    exit 2
fi
source_root="$module_root/source"
mkdir "$module_root/runtime" "$module_root/cache" "$module_root/logs"
TMPDIR="$module_root/runtime"
TMP=$TMPDIR
TEMP=$TMPDIR
R_TMPDIR=$TMPDIR
XDG_CACHE_HOME="$module_root/cache"
export TMPDIR TMP TEMP R_TMPDIR XDG_CACHE_HOME
cd "$source_root"
shasum -a 256 -c SOURCE_EXPORT.sha256 > "$module_root/logs/source-check.log"
if grep -nE '/tmp|/run/' tools/platform_m5/*.c tests/test_platform_m5* \
    > "$module_root/logs/explicit-temp-paths.log"; then
    printf '%s\n' 'Review explicit temporary paths before executing tests' >&2
    exit 2
fi
{
    date -u +%Y-%m-%dT%H:%M:%SZ
    uname -a
    "$compiler_path" --version
    cmake --version
    valgrind --version
    "$patched_valgrind" --version
    printf 'root=%s\nTMPDIR=%s\nR_TMPDIR=%s\nXDG_CACHE_HOME=%s\n' \
        "$module_root" "$TMPDIR" "$R_TMPDIR" "$XDG_CACHE_HOME"
    shasum -a 256 "$patched_valgrind"
} > "$module_root/logs/env.txt" 2>&1
"$patched_valgrind" --command-line-only=yes --tool=memcheck --help \
    > "$module_root/logs/patched-help.txt" 2>&1
if ! grep -q -- '--variable-latency-errors=no|yes' "$module_root/logs/patched-help.txt"; then
    printf '%s\n' 'Required patched variable-latency option missing' >&2
    exit 2
fi

for configuration in ordinary sanitize; do
    build_root="$module_root/build-$configuration"
    if [ "$configuration" = ordinary ]; then
        enable_sanitizers=OFF
    else
        enable_sanitizers=ON
    fi
    cmake -S "$source_root" -B "$build_root" -DCMAKE_C_COMPILER="$compiler_path" \
        -DBASELINE_ENABLE_PLATFORM=ON -DA113_ARCHIVED_CASE_ONLY=OFF \
        -DBASELINE_ENABLE_LIBOQS010=OFF -DCMAKE_BUILD_TYPE=RelWithDebInfo \
        -DBASELINE_SANITIZERS="$enable_sanitizers" \
        > "$module_root/logs/configure-$configuration.log" 2>&1
    cmake --build "$build_root" --parallel 4 --target platform_m5_poison platform_m5_dudect \
        reference_measure reference_baseline reference_test_mlkem reference_test_random_failure \
        > "$module_root/logs/build-$configuration.log" 2>&1
    ctest --test-dir "$build_root" --output-on-failure \
        -R '^(reference_kat|reference_random_failure|reference_cli|reference_vector_parser|vector_integrity|platform_m5_poison_functional|platform_m5_dudect_selftest)$' \
        > "$module_root/logs/ctest-$configuration.log" 2>&1
    shasum -a 256 "$build_root/platform_m5_poison" "$build_root/platform_m5_dudect" \
        "$build_root/reference/measure" > "$module_root/logs/elf-$configuration.sha256"
done

poison_program="$module_root/build-ordinary/platform_m5_poison"
for dynamic_mode in system varlat-no varlat-yes; do
    case "$dynamic_mode" in
        system) valgrind_program=valgrind; latency_option=; configuration_option= ;;
        varlat-no) valgrind_program=$patched_valgrind; latency_option=--variable-latency-errors=no; configuration_option=--command-line-only=yes ;;
        varlat-yes) valgrind_program=$patched_valgrind; latency_option=--variable-latency-errors=yes; configuration_option=--command-line-only=yes ;;
    esac
    set +e
    "$valgrind_program" ${configuration_option:+"$configuration_option"} --tool=memcheck --track-origins=yes --error-exitcode=99 --vgdb=no \
        --vgdb-prefix="$module_root/runtime/vgdb" \
        --log-file="$module_root/logs/$dynamic_mode.valgrind.log" ${latency_option:+"$latency_option"} \
        "$poison_program" --poison > "$module_root/logs/$dynamic_mode.stdout" 2>&1
    dynamic_status=$?
    set -e
    printf '%s\n' "$dynamic_status" > "$module_root/logs/$dynamic_mode.exit-status"
done
objdump -d "$poison_program" > "$module_root/logs/poison.disasm"
nm -n "$poison_program" > "$module_root/logs/poison.symbols"
cp "$module_root/build-ordinary/compile_commands.json" "$module_root/logs/compile_commands.json"
cp "$module_root/build-ordinary/CMakeFiles/platform_m5_poison.dir/link.txt" \
    "$module_root/logs/poison-link.txt"
cp "$module_root/build-ordinary/CMakeFiles/platform_m5_dudect.dir/link.txt" \
    "$module_root/logs/dudect-link.txt"
find "$module_root" -type l -print > "$module_root/logs/symlinks.txt"
while IFS= read -r link_path; do
    target_path=$(realpath "$link_path")
    case "$target_path" in
        "$module_root"/*) ;;
        *) printf '%s -> %s\n' "$link_path" "$target_path" >&2; exit 2 ;;
    esac
done < "$module_root/logs/symlinks.txt"
printf '%s\n' 'software qualification and non-timing dynamic checks finished; no collection invoked'
