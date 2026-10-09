#!/bin/sh
set -eu
if [ "$#" -ne 2 ]; then
    printf '%s\n' 'usage: sh remote-run.sh ROOT_STAGE NEW_OUTPUT_ROOT' >&2
    exit 2
fi
command -v timeout >/dev/null 2>&1 || exit 2
script_root=$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd -P)
exec timeout --signal=TERM --kill-after=5s 595s \
    sh "$script_root/matrix-run.sh" "$@"
