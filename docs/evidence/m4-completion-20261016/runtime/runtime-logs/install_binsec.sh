#!/usr/bin/env bash
set -euo pipefail

runtime_root=${1:?usage: install_binsec.sh NEW_CRY_ROOT}
case "$runtime_root" in
    /home/nss-marker/yhr/Cry/*) ;;
    *) printf 'runtime root must be below Cry\n' >&2; exit 2 ;;
esac
test -d "$runtime_root"
test "$(readlink -f "$runtime_root")" = "$runtime_root"
mkdir -p "$runtime_root"/{runtime,runtime-logs,download,tmp,cache,opam,curl}
export TMPDIR="$runtime_root/tmp" TEMP="$runtime_root/tmp" TMP="$runtime_root/tmp"
export XDG_CACHE_HOME="$runtime_root/cache" OPAMROOT="$runtime_root/opam"
export CURL_HOME="$runtime_root/curl"
export OPAMJOBS=2 DUNE_CACHE=disabled OPAMNOENVNOTICE=true
export PATH="$runtime_root/runtime/bin:$PATH"
mkdir -p "$runtime_root/runtime/bin"
ulimit -c 0

download_checked() {
    local file_name=$1
    local source_url=$2
    local expected_sha256=$3
    if ! test -f "$runtime_root/download/$file_name"; then
        curl -fL --retry 2 --connect-timeout 20 --max-time 240 "$source_url" \
            -o "$runtime_root/download/$file_name"
    fi
    printf '%s  %s\n' "$expected_sha256" "$runtime_root/download/$file_name" | sha256sum -c -
}

download_checked opam-2.6.1-x86_64-linux \
    https://github.com/ocaml/opam/releases/download/2.6.1/opam-2.6.1-x86_64-linux \
    b533d393a6967150d6ef41cb3d71e147e93ecbabeb59e921aa412c0ae79ebe3d
download_checked z3-4.15.3-x64-glibc-2.39.zip \
    https://github.com/Z3Prover/z3/releases/download/z3-4.15.3/z3-4.15.3-x64-glibc-2.39.zip \
    94549c5e31a75b9c543fe6eea8f32927054765c2e92e696d2d6dde0eedf348a1
download_checked binsec-0.11.3.tbz \
    https://github.com/binsec/binsec/releases/download/0.11.3/binsec-0.11.3.tbz \
    93f6fe439d486b166062ef6dd92c4ce3aa0947b5e18b1c3aa7de2fc3003aa6d9
download_checked gmp-6.3.0.tar.xz \
    https://ftp.gnu.org/gnu/gmp/gmp-6.3.0.tar.xz \
    a3c2b80201b89e68616f4ad30bc66aee4927c3ce50e33929ca819d5c43538898

install -m 755 "$runtime_root/download/opam-2.6.1-x86_64-linux" "$runtime_root/runtime/bin/opam"
if ! test -d "$runtime_root/runtime/z3-4.15.3-x64-glibc-2.39"; then
    unzip -q "$runtime_root/download/z3-4.15.3-x64-glibc-2.39.zip" -d "$runtime_root/runtime"
fi
ln -sfn ../z3-4.15.3-x64-glibc-2.39/bin/z3 "$runtime_root/runtime/bin/z3"
if ! test -d "$runtime_root/runtime/gmp-6.3.0"; then
    tar -xJf "$runtime_root/download/gmp-6.3.0.tar.xz" -C "$runtime_root/runtime"
fi
if ! test -f "$runtime_root/runtime/gmp-install/include/gmp.h"; then
    (
        cd "$runtime_root/runtime/gmp-6.3.0"
        ./configure --prefix="$runtime_root/runtime/gmp-install" --disable-shared
        make -j2
        make install
    )
fi
export CPATH="$runtime_root/runtime/gmp-install/include"
export LIBRARY_PATH="$runtime_root/runtime/gmp-install/lib"
export PKG_CONFIG_PATH="$runtime_root/runtime/gmp-install/lib/pkgconfig"
export CFLAGS="-I$CPATH" LDFLAGS="-L$LIBRARY_PATH"
if ! test -f "$OPAMROOT/config"; then
    opam init --bare --disable-sandboxing --no-setup --no-opamrc -y
fi
if ! test -d "$runtime_root/runtime/binsec-0.11.3"; then
    tar -xjf "$runtime_root/download/binsec-0.11.3.tbz" -C "$runtime_root/runtime"
fi
cd "$runtime_root/runtime/binsec-0.11.3"
if ! test -d _opam; then
    opam switch create . ocaml-base-compiler.4.14.3 -y --no-depexts
fi
eval "$(opam env --switch="$PWD" --set-switch)"
opam install . unisim_archisec --no-depexts -y --jobs=2
opam list --installed --columns=name,version > "$runtime_root/runtime-logs/opam-installed.txt"
opam switch export "$runtime_root/runtime-logs/binsec-switch.export"
binsec -version
binsec -help
z3 --version
sha256sum "$(command -v binsec)" "$(readlink -f "$(command -v z3)")"
