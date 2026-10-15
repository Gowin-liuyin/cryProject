#!/bin/sh
set -eu
project_root=$1
case "$project_root" in
    /home/nss-marker/yhr/Cry/platform-m3-20261016-*) ;;
    *) exit 2 ;;
esac
test "$(realpath "$project_root")" = "$project_root"
export TMPDIR="$project_root/tmp"
export TMP="$TMPDIR"
export TEMP="$TMPDIR"
export XDG_CACHE_HOME="$project_root/cache"
export CCACHE_DIR="$project_root/cache/ccache"
mkdir -p "$TMPDIR" "$XDG_CACHE_HOME" "$CCACHE_DIR"
cd "$project_root/source"
sha256sum -c SOURCE_EXPORT.sha256 > "$project_root/logs/source-verification.log"
{
    hostname
    uname -a
    clang --version
    cmake --version
    valgrind --version
    printf 'project_root=%s\nTMPDIR=%s\nXDG_CACHE_HOME=%s\n' \
        "$project_root" "$TMPDIR" "$XDG_CACHE_HOME"
    printf 'pin='
    command -v pin || true
    printf 'dotnet='
    command -v dotnet || true
    printf 'microwalk='
    command -v microwalk || true
    printf 'docker='
    command -v docker || true
    docker info --format 'DockerRootDir={{.DockerRootDir}}' 2>&1 || true
} > "$project_root/logs/environment.log"
cmake -S . -B "$project_root/build-ordinary" -DCMAKE_C_COMPILER=clang \
    -DCMAKE_BUILD_TYPE=RelWithDebInfo -DBUILD_TESTING=ON -DBASELINE_SANITIZERS=OFF \
    -DBASELINE_ENABLE_PLATFORM=ON -DA113_ARCHIVED_CASE_ONLY=OFF -DPLATFORM_M3_CTGRIND=ON \
    > "$project_root/logs/configure-ordinary.log" 2>&1
cmake --build "$project_root/build-ordinary" --parallel 4 \
    --target platform_m3 platform_m3_check platform_m3_on_probe platform_m3_off_probe \
    > "$project_root/logs/build-ordinary.log" 2>&1
for fixture_mode in on off; do
    for marking in secret defined; do
        set +e
        valgrind --tool=memcheck --track-origins=yes --error-exitcode=97 \
            --log-file="$project_root/logs/$fixture_mode-$marking.memcheck.log" \
            "$project_root/build-ordinary/platform_m3_${fixture_mode}_probe" "--$marking" \
            > "$project_root/logs/$fixture_mode-$marking.stdout.log" 2>&1
        probe_status=$?
        set -e
        printf '%s\n' "$probe_status" > "$project_root/logs/$fixture_mode-$marking.exit"
    done
done
cmake -S . -B "$project_root/build-sanitize" -DCMAKE_C_COMPILER=clang \
    -DCMAKE_BUILD_TYPE=Debug -DBUILD_TESTING=ON -DBASELINE_SANITIZERS=ON \
    -DBASELINE_ENABLE_PLATFORM=ON -DA113_ARCHIVED_CASE_ONLY=OFF -DPLATFORM_M3_CTGRIND=OFF \
    > "$project_root/logs/configure-sanitize.log" 2>&1
cmake --build "$project_root/build-sanitize" --parallel 4 --target platform_m3 platform_m3_check \
    > "$project_root/logs/build-sanitize.log" 2>&1
for fixture_mode in on off; do
    executable="$project_root/build-ordinary/platform-m3/$fixture_mode/measure"
    sha256sum "$executable" >> "$project_root/logs/binary-SHA256SUMS"
    objdump -d --demangle "$executable" > "$project_root/logs/$fixture_mode.measure.disasm"
    objdump -d --demangle "$project_root/build-ordinary/platform_m3_${fixture_mode}_probe" \
        > "$project_root/logs/$fixture_mode.probe.disasm"
done
find "$project_root" -type l -print > "$project_root/logs/symlinks.txt"
printf 'native_m3_functional_and_localization_completed\n'
