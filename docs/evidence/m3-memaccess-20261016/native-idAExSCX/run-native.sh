#!/bin/sh
set -eu
run_root=/home/nss-marker/yhr/Cry/platform-s7-20261016-idAExSCX
test "$(readlink -f "$run_root")" = "$run_root"
umask 077
mkdir -p "$run_root/source" "$run_root/logs" "$run_root/tmp" "$run_root/cache"
export TMPDIR="$run_root/tmp"
export TMP="$TMPDIR"
export TEMP="$TMPDIR"
export XDG_CACHE_HOME="$run_root/cache"
export CCACHE_DIR="$run_root/cache/ccache"
tar -xf "$run_root/upload.tar" -C "$run_root/source"
if find "$run_root/source" -type l -print | read -r unexpected_symlink; then
    exit 1
fi
{
    date -u '+%Y-%m-%dT%H:%M:%SZ'
    uname -snrm
    cc --version
    cmake --version
    valgrind --version
    for tool_name in pin microwalk dotnet docker; do
        if command -v "$tool_name"; then
            :
        else
            printf '%s=not_found\n' "$tool_name"
        fi
    done
    printf 'run_root=%s\nTMPDIR=%s\nXDG_CACHE_HOME=%s\n' "$run_root" "$TMPDIR" "$XDG_CACHE_HOME"
} > "$run_root/logs/environment.txt" 2>&1
sha256sum "$run_root/upload.tar" "$run_root/source/fixtures/mem_lut_leak/"* > "$run_root/logs/source-sha256.txt"
cmake -S "$run_root/source/fixtures/mem_lut_leak" -B "$run_root/build-ordinary" -DCMAKE_BUILD_TYPE=RelWithDebInfo -DMEM_LUT_ENABLE_CTGRIND=ON > "$run_root/logs/configure.txt" 2>&1
cmake --build "$run_root/build-ordinary" --parallel 2 > "$run_root/logs/build.txt" 2>&1
ctest --test-dir "$run_root/build-ordinary" --output-on-failure > "$run_root/logs/ctest.txt" 2>&1
set +e
valgrind --tool=memcheck --track-origins=yes --error-exitcode=97 --log-file="$run_root/logs/on-valgrind.txt" "$run_root/build-ordinary/mem_lut_leak_on" --ctgrind-probe > "$run_root/logs/on-stdout.txt" 2> "$run_root/logs/on-stderr.txt"
on_status=$?
valgrind --tool=memcheck --track-origins=yes --error-exitcode=97 --log-file="$run_root/logs/off-valgrind.txt" "$run_root/build-ordinary/mem_lut_leak_off" --ctgrind-probe > "$run_root/logs/off-stdout.txt" 2> "$run_root/logs/off-stderr.txt"
off_status=$?
set -e
printf 'on_exit=%s\noff_exit=%s\n' "$on_status" "$off_status" > "$run_root/logs/probe-status.txt"
objdump -d --disassemble=mem_lut_apply "$run_root/build-ordinary/mem_lut_leak_on" > "$run_root/logs/on-disasm.txt"
objdump -d --disassemble=mem_lut_apply "$run_root/build-ordinary/mem_lut_leak_off" > "$run_root/logs/off-disasm.txt"
sha256sum "$run_root/build-ordinary/mem_lut_leak_on" "$run_root/build-ordinary/mem_lut_leak_off" > "$run_root/logs/binary-sha256.txt"
printf 'source_base_commit=4a3a4ab97d76f3317d68e64570a0c14318329a5b\nsource_state=uncommitted_new_S7_fixture\ntiming_collection=not_run\nfrequency_writes=none\n' > "$run_root/logs/scope.txt"
test "$on_status" -eq 97
test "$off_status" -eq 0
tar -czf "$run_root.evidence.tar.gz" -C "$run_root" source logs run-native.sh
sha256sum "$run_root.evidence.tar.gz"
cat "$run_root/logs/probe-status.txt"
