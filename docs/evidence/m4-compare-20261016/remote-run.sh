#!/bin/sh
set -eu
run_root=$1
case "$run_root" in /home/nss-marker/yhr/Cry/platform-s8-20261016-*) ;; *) exit 70 ;; esac
[ "$(readlink -f "$run_root")" = "$run_root" ]
mkdir -p "$run_root/tmp" "$run_root/cache" "$run_root/docker"
export TMPDIR="$run_root/tmp" TMP="$run_root/tmp" TEMP="$run_root/tmp"
export XDG_CACHE_HOME="$run_root/cache" DOCKER_CONFIG="$run_root/docker"
{
    uname -a
    cc --version
    cmake --version
    valgrind --version
    printf 'run_root=%s\nTMPDIR=%s\n' "$run_root" "$TMPDIR"
    for tool_name in binsec opam ocamlc dune z3 boolector bitwuzla docker; do
        tool_path=$(command -v "$tool_name" 2>/dev/null || true)
        printf '%s=%s\n' "$tool_name" "${tool_path:-not_found}"
    done
} > "$run_root/environment.log" 2>&1
set +e
timeout 15 docker version --format '{{json .}}' > "$run_root/docker-probe.log" 2>&1
docker_status=$?
set -e
printf 'docker_probe_exit=%s\n' "$docker_status" > "$run_root/status.txt"
cmake -S "$run_root/source/fixtures/early_reject_memcmp" -B "$run_root/build-poison" -DCMAKE_BUILD_TYPE=RelWithDebInfo -DM4_ENABLE_CTGRIND=ON > "$run_root/configure-poison.log" 2>&1
cmake --build "$run_root/build-poison" -j2 > "$run_root/build-poison.log" 2>&1
ctest --test-dir "$run_root/build-poison" --output-on-failure > "$run_root/ctest-poison.log" 2>&1
for compare_variant in vulnerable ct; do
    set +e
    valgrind --tool=memcheck --error-exitcode=99 --track-origins=yes --log-file="$run_root/valgrind-$compare_variant.log" "$run_root/build-poison/m4_compare_$compare_variant" --probe > "$run_root/probe-$compare_variant.stdout" 2>&1
    probe_status=$?
    set -e
    printf '%s_valgrind_exit=%s\n' "$compare_variant" "$probe_status" >> "$run_root/status.txt"
    objdump -d --disassemble=m4_compare_bytes "$run_root/build-poison/m4_compare_$compare_variant" > "$run_root/disasm-$compare_variant.txt"
done
find "$run_root/source" -type f -exec sha256sum {} + > "$run_root/source-sha256.txt"
find "$run_root/build-poison" -maxdepth 1 -type f -executable -exec sha256sum {} + > "$run_root/binaries-sha256.txt"
printf 'complete=yes\n' >> "$run_root/status.txt"
cat "$run_root/status.txt"
cat "$run_root/ctest-poison.log"
