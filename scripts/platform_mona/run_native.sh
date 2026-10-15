#!/bin/sh
set -eu
umask 077

if [ "$#" -ne 2 ]; then
    printf '%s\n' 'usage: run_native.sh SOURCE_ROOT NEW_RUN_ROOT' >&2
    exit 2
fi
source_root=$(CDPATH= cd -- "$1" && pwd -P)
run_root=$2
assigned_root=$(dirname -- "${source_root}")
# 只接受主控分配的两代 Mona 物理根：v1 为任意后缀，v2 固定 12 位小写十六进制名。
case "${assigned_root}" in
    /home/nss-marker/yhr/Cry/platform-mona-20261016-*) ;;
    /home/nss-marker/yhr/Cry/platform-mona2-20261016-[0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f]) ;;
    *) printf '%s\n' 'Source is outside the assigned Mona tree.' >&2; exit 2 ;;
esac
if [ "$(basename -- "${source_root}")" != source ]; then
    printf '%s\n' 'Source is outside the assigned Mona tree.' >&2
    exit 2
fi
if [ -e "${run_root}" ] || [ -L "${run_root}" ]; then
    printf '%s\n' 'Run root must not exist.' >&2
    exit 2
fi
run_parent=$(CDPATH= cd -- "$(dirname -- "${run_root}")" && pwd -P)
if [ "${run_parent}" != "${assigned_root}" ]; then
    printf '%s\n' 'Source and run must belong to the same assigned root.' >&2
    exit 2
fi
if [ "$(basename -- "${run_root}")" != run ]; then
    printf '%s\n' 'Run is outside the assigned Mona tree.' >&2
    exit 2
fi
mkdir -- "${run_root}"
run_root=$(CDPATH= cd -- "${run_root}" && pwd -P)
mkdir "${run_root}/runtime" "${run_root}/cache"
TMPDIR="${run_root}/runtime"
TMP=${TMPDIR}
TEMP=${TMPDIR}
XDG_CACHE_HOME="${run_root}/cache"
JAVA_TOOL_OPTIONS="-XX:-UsePerfData -Djava.awt.headless=true -Djava.io.tmpdir=${TMPDIR}"
# 固定 C 区域设置：JUL 日志与工具消息否则随调用者 LANG 本地化，跨次无法逐字核对。
LC_ALL=C
LANG=C
export TMPDIR TMP TEMP XDG_CACHE_HOME JAVA_TOOL_OPTIONS LC_ALL LANG
cd -- "${run_root}"
uname -a > environment.txt
java -version > java-version.log 2>&1
if ! command -v javac >/dev/null 2>&1; then
    java -m jdk.compiler/com.sun.tools.javac.Main -version > compiler-module.log 2>&1
    mkdir "${run_root}/tools"
    cat > "${run_root}/tools/javac" <<'COMPILER'
#!/bin/sh
exec java -m jdk.compiler/com.sun.tools.javac.Main "$@"
COMPILER
    chmod 700 "${run_root}/tools/javac"
    PATH="${run_root}/tools:${PATH}"
    export PATH
fi
javac -version > javac-version.log 2>&1
cmake --version > cmake-version.log
printf '%s\n' "${source_root}" "${run_root}" > physical-paths.txt
cmake -S "${source_root}/scripts/platform_mona" -B "${run_root}/build" \
    -DBUILD_TESTING=ON -DJava_JAVAC_EXECUTABLE="$(command -v javac)" > configure.log 2>&1
cmake --build "${run_root}/build" --target platform_mona > build.log 2>&1
taskset -c 0,1 ctest --test-dir "${run_root}/build" --output-on-failure \
    > ctest.log 2>&1
taskset -c 0,1 sh "${source_root}/scripts/platform_mona/run_m1.sh" "${source_root}" \
    "${run_root}/build/platform-mona/classes" "${run_root}/m1" > replay.log 2>&1
printf '%s\n' 'completed_offline_only' > completed.txt
