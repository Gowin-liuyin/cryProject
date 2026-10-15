#!/bin/sh
set -eu

script_directory=$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd -P)
project_root=$(CDPATH='' cd -- "$script_directory/../../../.." && pwd -P)
fetch_root="$project_root/build/platform-s4/fetch-fixed-commits"
unfixed_root="$project_root/vendor/kyber-kyberslash-unfixed"
fixed_root="$project_root/vendor/kyber-kyberslash-fixed"

if [ -e "$unfixed_root" ] || [ -L "$unfixed_root" ] ||
    [ -e "$fixed_root" ] || [ -L "$fixed_root" ] || [ -e "$fetch_root" ]; then
    echo 'Refusing to overwrite an existing vendor tree or fetch directory' >&2
    exit 1
fi

mkdir -p "$fetch_root"
GIT_TERMINAL_PROMPT=0 git clone --mirror https://github.com/pq-crystals/kyber.git "$fetch_root/upstream.git"

fetch_snapshot()
{
    snapshot_name=$1
    snapshot_commit=$2
    expected_digest=$3
    archive_path="$fetch_root/$snapshot_name.tar"
    actual_commit=$(git --git-dir="$fetch_root/upstream.git" rev-parse "$snapshot_commit^{commit}")
    if [ "$actual_commit" != "$snapshot_commit" ]; then
        echo 'Unexpected upstream commit' >&2
        exit 1
    fi
    git --git-dir="$fetch_root/upstream.git" archive --format=tar "$snapshot_commit" > "$archive_path"
    actual_digest=$(shasum -a 256 "$archive_path" | awk '{print $1}')
    if [ "$actual_digest" != "$expected_digest" ]; then
        echo 'Archive digest mismatch; preserve fetch directory for inspection' >&2
        exit 1
    fi
    destination_root="$project_root/vendor/kyber-kyberslash-$snapshot_name"
    mkdir "$destination_root"
    tar -xf "$archive_path" -C "$destination_root"
    printf '%s %s %s\n' "$snapshot_name" "$snapshot_commit" "$actual_digest"
}

fetch_snapshot unfixed a621b8dde405cc507cbcfc5f794570a4f98d69cc 509548a1741473cab69fe403eb685282419bc2a42554d358f16b9e991c88ac08
fetch_snapshot fixed 272125f6acc8e8b6850fd68ceb901a660ff48196 e3d020a78c59fc7248f64a4ca774db5ca8c6bc537e8c682a9fd0049a09180803
