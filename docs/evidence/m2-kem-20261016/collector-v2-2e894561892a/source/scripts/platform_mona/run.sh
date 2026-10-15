#!/bin/sh
set -eu

script_directory=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd -P)
repository_root=$(CDPATH= cd -- "${script_directory}/../.." && pwd -P)
input_csv=
output_directory=
class_directory="${repository_root}/build/cmake/platform-mona/classes"
upstream_directory="${repository_root}/third_party/mona-timing-report"
java_program=java

usage() {
    printf '%s\n' 'usage: run.sh --input CSV --output-dir NEW_DIRECTORY [--class-dir DIR] [--upstream-dir DIR] [--java PATH]'
}

while [ "$#" -gt 0 ]; do
    if [ "$1" = --help ]; then
        usage
        exit 0
    fi
    if [ "$#" -lt 2 ]; then
        usage >&2
        exit 2
    fi
    case "$1" in
        --input) input_csv=$2 ;;
        --output-dir) output_directory=$2 ;;
        --class-dir) class_directory=$2 ;;
        --upstream-dir) upstream_directory=$2 ;;
        --java) java_program=$2 ;;
        *) usage >&2; exit 2 ;;
    esac
    shift 2
done
if [ ! -f "${input_csv}" ] || [ -z "${output_directory}" ] ||
    [ ! -f "${class_directory}/MonaReplay.class" ] || [ ! -d "${upstream_directory}/lib" ]; then
    usage >&2
    exit 2
fi
if [ -e "${output_directory}" ] || [ -L "${output_directory}" ]; then
    printf '%s\n' 'Output directory must not exist.' >&2
    exit 2
fi
mkdir -p -- "$(dirname -- "${output_directory}")"
mkdir -- "${output_directory}"
output_directory=$(CDPATH= cd -- "${output_directory}" && pwd -P)
class_directory=$(CDPATH= cd -- "${class_directory}" && pwd -P)
upstream_directory=$(CDPATH= cd -- "${upstream_directory}" && pwd -P)
(
    cd -- "${upstream_directory}"
    shasum -a 256 -c "${script_directory}/upstream.sha256"
) > "${output_directory}/upstream-verification.log" 2>&1
cp -- "${input_csv}" "${output_directory}/input.csv"
shasum -a 256 "${output_directory}/input.csv" > "${output_directory}/input.sha256"
mkdir "${output_directory}/runtime" "${output_directory}/cache"
TMPDIR="${output_directory}/runtime"
TMP=${TMPDIR}
TEMP=${TMPDIR}
XDG_CACHE_HOME="${output_directory}/cache"
export TMPDIR TMP TEMP XDG_CACHE_HOME
"${java_program}" -XX:-UsePerfData -Djava.awt.headless=true -Djava.io.tmpdir="${TMPDIR}" \
    -version > "${output_directory}/java-version.log" 2>&1
shasum -a 256 "${class_directory}/MonaReplay.class" "${script_directory}/run.sh" \
    "${upstream_directory}"/lib/*.jar > "${output_directory}/tools.sha256"
find "${class_directory}" -name '*.class' -type f -exec shasum -a 256 {} \; \
    > "${output_directory}/bytecode.sha256"
find "${upstream_directory}/src" -name '*.java' -type f -exec shasum -a 256 {} \; \
    > "${output_directory}/upstream-sources.sha256"
uname -a > "${output_directory}/environment.txt"
set +e
"${java_program}" -XX:-UsePerfData -Djava.awt.headless=true -Djava.io.tmpdir="${TMPDIR}" \
    -cp "${class_directory}:${upstream_directory}/lib/*" MonaReplay \
    "${output_directory}/input.csv" "${output_directory}" \
    > "${output_directory}/mona.log" 2>&1
mona_exit_status=$?
set -e
printf '%s\n' "${mona_exit_status}" > "${output_directory}/exit-status.txt"
exit "${mona_exit_status}"
