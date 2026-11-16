#!/bin/sh
# 由 build 工作副本生成三份候选补丁，并做应用自检（不改 vendor）。
set -eu

repository_root=$(CDPATH= cd -- "$(dirname -- "$0")/../.." && pwd)
work_root="$repository_root/build/m2-branchfix-work"
patches_dir="$repository_root/docs/patches"

for name in asm volatile ctselect; do
    case "$name" in
        asm) patch_name="m2-frommsg-barrier-asm.patch" ;;
        volatile) patch_name="m2-frommsg-barrier-volatile.patch" ;;
        ctselect) patch_name="m2-frommsg-ctselect.patch" ;;
    esac
    diff_status=0
    diff -u "$work_root/baseline/ref/poly.c" "$work_root/$name/ref/poly.c" \
        > "$work_root/$name.diff" || diff_status=$?
    if [ "$diff_status" -ne 1 ]; then
        printf 'unexpected diff status for %s: %s\n' "$name" "$diff_status" >&2
        exit 1
    fi
    sed -e '1s|.*|--- a/ref/poly.c|' -e '2s|.*|+++ b/ref/poly.c|' \
        "$work_root/$name.diff" > "$patches_dir/$patch_name"
    rm -rf "$work_root/apply-check-$name"
    cp -a "$work_root/baseline" "$work_root/apply-check-$name"
    (
        cd "$repository_root"
        git apply --directory="build/m2-branchfix-work/apply-check-$name" \
            "docs/patches/$patch_name"
        git apply --check --directory="vendor/kyber-kyberslash-fixed" \
            "docs/patches/$patch_name"
    )
    cmp "$work_root/apply-check-$name/ref/poly.c" "$work_root/$name/ref/poly.c"
    rm -rf "$work_root/apply-check-$name"
    printf 'patch ready: docs/patches/%s\n' "$patch_name"
done
