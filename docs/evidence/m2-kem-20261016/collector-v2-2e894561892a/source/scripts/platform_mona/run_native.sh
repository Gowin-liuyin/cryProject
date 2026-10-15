#!/bin/sh
set -eu
umask 077

if [ "$#" -ne 2 ]; then
    printf '%s\n' 'usage: run_native.sh SOURCE_ROOT NEW_RUN_ROOT' >&2
    exit 2
fi
source_root=$(CDPATH= cd -- "$1" && pwd -P)
run_root=$2
case "${source_root}" in
    /home/nss-marker/yhr/Cry/platform-mona-20261016-*/source) ;;
    *) printf '%s\n' 'Source is outside the assigned Mona tree.' >&2; exit 2 ;;
esac
if [ -e "${run_root}" ] || [ -L "${run_root}" ]; then
    printf '%s\n' 'Run root must not exist.' >&2
    exit 2
fi
run_parent=$(CDPATH= cd -- "$(dirname -- "${run_root}")" && pwd -P)
if [ "${run_parent}" != "$(dirname -- "${source_root}")" ]; then
    printf '%s\n' 'Source and run must belong to the same assigned root.' >&2
    exit 2
fi
case "${run_parent}/$(basename -- "${run_root}")" in
    /home/nss-marker/yhr/Cry/platform-mona-20261016-*/run) ;;
    *) printf '%s\n' 'Run is outside the assigned Mona tree.' >&2; exit 2 ;;
esac
mkdir -- "${run_root}"
run_root=$(CDPATH= cd -- "${run_root}" && pwd -P)
mkdir "${run_root}/runtime" "${run_root}/cache"
TMPDIR="${run_root}/runtime"
TMP=${TMPDIR}
TEMP=${TMPDIR}
XDG_CACHE_HOME="${run_root}/cache"
JAVA_TOOL_OPTIONS="-XX:-UsePerfData -Djava.awt.headless=true -Djava.io.tmpdir=${TMPDIR}"
export TMPDIR TMP TEMP XDG_CACHE_HOME JAVA_TOOL_OPTIONS
cd -- "${run_root}"
uname -a > environment.txt
java -version > java-version.log 2>&1
javac -version > javac-version.log 2>&1
cmake --version > cmake-version.log
printf '%s\n' "${source_root}" "${run_root}" > physical-paths.txt
cmake -S "${source_root}/scripts/platform_mona" -B "${run_root}/build" \
    -DBUILD_TESTING=ON > configure.log 2>&1
cmake --build "${run_root}/build" --target platform_mona > build.log 2>&1
taskset -c 0,1 ctest --test-dir "${run_root}/build" --output-on-failure \
    > ctest.log 2>&1
taskset -c 0,1 sh "${source_root}/scripts/platform_mona/run_m1.sh" "${source_root}" \
    "${run_root}/build/platform-mona/classes" "${run_root}/m1" > replay.log 2>&1
printf '%s\n' 'completed_offline_only' > completed.txt
