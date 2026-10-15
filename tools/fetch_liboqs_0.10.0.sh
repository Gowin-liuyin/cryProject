#!/bin/sh
# Fetch and verify the pinned Open Quantum Safe liboqs 0.10.0 source tree.
set -eu

repository_root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
pin_tag="0.10.0"
pin_commit="36be57445d8ca53f7095160fde548efe82ace09d"
archive_url="https://github.com/open-quantum-safe/liboqs/archive/refs/tags/${pin_tag}.tar.gz"
expected_sha256="2b7b4436be9825dd0adaf000ee4f322f06551e638a8a9c8d54eda48ed40e40a9"
vendor_dir="${repository_root}/vendor/liboqs-0.10.0"
archive_path="${repository_root}/vendor/liboqs-0.10.0.tar.gz"

if [ -f "${vendor_dir}/CMakeLists.txt" ]; then
    if grep -q 'set(OQS_VERSION_TEXT "0.10.0")' "${vendor_dir}/CMakeLists.txt"; then
        printf 'liboqs 0.10.0 already present at %s\n' "${vendor_dir}"
        exit 0
    fi
    printf 'refusing to overwrite unexpected tree at %s\n' "${vendor_dir}" >&2
    exit 1
fi

mkdir -p "${repository_root}/vendor"
printf 'downloading %s\n' "${archive_url}"
curl -fL --retry 3 -o "${archive_path}" "${archive_url}"
actual_sha256=$(shasum -a 256 "${archive_path}" | awk '{print $1}')
if [ "${actual_sha256}" != "${expected_sha256}" ]; then
    printf 'SHA-256 mismatch for liboqs archive\nexpected %s\nactual   %s\n' \
        "${expected_sha256}" "${actual_sha256}" >&2
    exit 1
fi

tmpdir=$(mktemp -d "${repository_root}/vendor/liboqs-fetch.XXXXXX")
trap 'rm -rf "${tmpdir}"' EXIT INT TERM
tar -xzf "${archive_path}" -C "${tmpdir}"
extracted=$(find "${tmpdir}" -mindepth 1 -maxdepth 1 -type d | head -n 1)
if [ -z "${extracted}" ] || [ ! -f "${extracted}/CMakeLists.txt" ]; then
    printf 'archive layout unexpected\n' >&2
    exit 1
fi
if ! grep -q 'set(OQS_VERSION_TEXT "0.10.0")' "${extracted}/CMakeLists.txt"; then
    printf 'extracted tree is not liboqs 0.10.0\n' >&2
    exit 1
fi
mv "${extracted}" "${vendor_dir}"
rm -f "${archive_path}"
printf 'installed %s (tag %s, commit %s)\n' "${vendor_dir}" "${pin_tag}" "${pin_commit}"
