#!/bin/bash
set -eu
run=/home/nss-marker/yhr/Cry/v4-confirmation-8709dfe
src=/home/nss-marker/yhr/Cry/v4-development-8709dfe
exec > "$run/log/build-wrapper.txt" 2>&1
set -x
echo CONFIRM_BUILD_START
export LC_ALL=C
export TMPDIR="$run/tmp"
export TMP="$run/tmp"
export TEMP="$run/tmp"
real_run=$(readlink -f "$run")
if [ "$real_run" != "$run" ]; then
    echo "PATH_ESCAPE $real_run"
    exit 1
fi
cp "$src/v4-source-8709dfe.tar" "$run/v4-source-8709dfe.tar"
cp "$src/SOURCE_EXPORT.sha256" "$run/SOURCE_EXPORT.sha256"
sha256sum "$run/v4-source-8709dfe.tar" "$run/SOURCE_EXPORT.sha256" > "$run/log/copied-sha256.txt"
mkdir -p "$run/source"
tar -xf "$run/v4-source-8709dfe.tar" -C "$run/source"
cp "$run/SOURCE_EXPORT.sha256" "$run/source/SOURCE_EXPORT.sha256"
if find "$run/source" -type l -print | grep -q .; then
    echo SYMLINK_PRESENT
    exit 1
fi
{
    echo "git_commit=8709dfe09955f44bf0e79311d9975f733069b752"
    echo "protocol_commit=9cf0be4c10ccc2a957bd123b7ab884ee5641d5e6"
    echo "development_evidence_commit=44601521238eb05de2d814e1cd05a0b565c54869"
    echo "exported_session_count=40"
    echo "exported_repeat_count=2"
    echo "frequency_writes=not_yet"
    hostname
    uname -a
    virt=$(systemd-detect-virt || true)
    echo "systemd-detect-virt=$virt"
    nproc
    gcc --version | head -1
    cmake --version | head -1
    echo "work_root=$real_run"
    echo -n "cpu2_thread_siblings_list="
    cat /sys/devices/system/cpu/cpu2/topology/thread_siblings_list
    date -u +start=%Y-%m-%dT%H:%M:%SZ
} > "$run/log/environment.txt"
cd "$run/source"
shasum -a 256 -c SOURCE_EXPORT.sha256 > "$run/log/source-manifest.txt"
cmake --preset baseline > "$run/log/configure.txt" 2>&1
cmake --build build/cmake --target encoder_branch_v4_collect v4_analyze v4_window -j 8 > "$run/log/build.txt" 2>&1
sha256sum build/cmake/encoder_branch/v4_collect build/cmake/v4_analyze build/cmake/v4_window > "$run/log/binary-sha256.txt"
if ! readelf -d build/cmake/encoder_branch/v4_collect | grep -q 'libm\.so'; then
    echo NEEDED_LIBM_MISSING
    exit 1
fi
# 写频率之前保存全部可见策略。这一步只读。
{
    echo "frequency_writes=none"
    for cpu_index in $(seq 0 31); do
        gov=/sys/devices/system/cpu/cpu${cpu_index}/cpufreq/scaling_governor
        min=/sys/devices/system/cpu/cpu${cpu_index}/cpufreq/scaling_min_freq
        max=/sys/devices/system/cpu/cpu${cpu_index}/cpufreq/scaling_max_freq
        if [ -r "$gov" ] && [ -r "$min" ] && [ -r "$max" ]; then
            printf 'cpu=%s governor=%s min=%s max=%s\n' "$cpu_index" "$(cat "$gov")" "$(cat "$min")" "$(cat "$max")"
        else
            echo "cpu=$cpu_index unreadable"
        fi
    done
} > "$run/log/frequency-machine-before.txt"
echo CONFIRM_BUILD_OK
