#!/bin/sh
set -eu

run_root=$1
physical_root=$(readlink -f "$run_root")
case "$physical_root" in
    /home/nss-marker/yhr/Cry/platform-s3-20261016-*) ;;
    *) exit 2 ;;
esac
test "$physical_root" = "$run_root"
test "$(uname -sm)" = 'Linux x86_64'
mkdir -p "$run_root/tmp" "$run_root/cache" "$run_root/logs" "$run_root/build"
export TMPDIR="$run_root/tmp"
export TMP="$run_root/tmp"
export TEMP="$run_root/tmp"
export XDG_CACHE_HOME="$run_root/cache"
ulimit -c 0
cd "$run_root"
sha256sum incoming/* > logs/inputs.sha256
tar -xjf incoming/valgrind-3.25.1.tar.bz2
cp incoming/upstream.gitignore valgrind-3.25.1/.gitignore
patch --batch --dry-run -p1 -d valgrind-3.25.1 < incoming/valgrind-try-patch-20250805.txt > logs/try-patch-dry-run.txt 2>&1
patch --batch -p1 -d valgrind-3.25.1 < incoming/valgrind-try-patch-20250805.txt > logs/try-patch-apply.txt 2>&1
patch --batch --dry-run -p1 -d valgrind-3.25.1 < incoming/valgrind-varlat-patch-20250805.txt > logs/varlat-patch-dry-run.txt 2>&1
patch --batch -p1 -d valgrind-3.25.1 < incoming/valgrind-varlat-patch-20250805.txt > logs/varlat-patch-apply.txt 2>&1
{
    date -u '+%Y-%m-%dT%H:%M:%SZ'
    uname -a
    cc --version
    make --version
    printf 'physical_root=%s\nTMPDIR=%s\nXDG_CACHE_HOME=%s\n' "$physical_root" "$TMPDIR" "$XDG_CACHE_HOME"
} > logs/ENV.txt
cd build
../valgrind-3.25.1/configure --enable-only64bit --disable-maintainer-mode --disable-dependency-tracking --with-tmpdir="$run_root/tmp" --prefix="$run_root/install" > ../logs/configure.txt 2>&1
make -j4 > ../logs/make.txt 2>&1
make install > ../logs/install.txt 2>&1
"$run_root/install/bin/valgrind" --command-line-only=yes --tool=memcheck --help > ../logs/valgrind-help.txt 2>&1
grep -F -- '--variable-latency-errors=no|yes' ../logs/valgrind-help.txt > ../logs/varlat-option.txt
sha256sum "$run_root/install/bin/valgrind" "$run_root/install/libexec/valgrind/memcheck-amd64-linux" > ../logs/binaries.sha256
printf 'build_complete=yes\n'
