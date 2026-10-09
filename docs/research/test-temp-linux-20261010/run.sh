#!/bin/sh
set -eu
umask 077
ulimit -c 0

work_root=/home/nss-marker/yhr/Cry/temp-check-1faf87d
cd "$work_root"
test "$(pwd -P)" = "$work_root"
test ! -L source
test ! -L compiler-tmp
test ! -L logs
test "$(sha256sum source.tar | cut -d ' ' -f 1)" = \
    689eb4913c054c0586da0bec44a5579d7b95f2dd69f4c6da512bec6a4b506603
export TMPDIR="$work_root/compiler-tmp"
export TMP="$TMPDIR"
export TEMP="$TMPDIR"

tar -xf source.tar -C source
uname -a > logs/uname.txt
/usr/bin/gcc --version > logs/gcc-version.txt
cmake --version > logs/cmake-version.txt
for build_name in build-gcc build-gcc-san; do
    test ! -e "$build_name"
    sanitizer_setting=OFF
    if test "$build_name" = build-gcc-san; then
        sanitizer_setting=ON
    fi
    cmake -S source -B "$build_name" -DCMAKE_C_COMPILER=/usr/bin/gcc \
        -DCMAKE_BUILD_TYPE=Debug -DBUILD_TESTING=ON \
        -DBASELINE_SANITIZERS="$sanitizer_setting" \
        > "logs/$build_name-configure.log" 2>&1
    cmake --build "$build_name" --target test_temp_directory --parallel 2 \
        > "logs/$build_name-build.log" 2>&1
    ctest --test-dir "$build_name" -R '^temp_directory$' -V \
        > "logs/$build_name-ctest.log" 2>&1
    ctest --test-dir "$build_name" -R '^temp_directory$' --show-only=json-v1 \
        > "logs/$build_name-registry.json"
done
