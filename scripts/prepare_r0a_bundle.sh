#!/bin/sh
# prepare_r0a_bundle.sh：从指定提交可复现地生成 R0a 复测上传包（最小集）。
# 内容 = git archive(commit) + 两棵 kyber vendor 树 + 精简后的证据目录
# （collector-v2 源码与合同）+ SOURCE_EXPORT.sha256（远端 build_identity 用）。
# 用法：sh scripts/prepare_r0a_bundle.sh <commit> <output.tar.gz>
set -eu

COMMIT=${1:?usage: prepare_r0a_bundle.sh <commit> <output.tar.gz>}
OUTPUT=${2:?usage: prepare_r0a_bundle.sh <commit> <output.tar.gz>}
REPO_ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)

for vendor_tree in kyber-kyberslash-unfixed kyber-kyberslash-fixed; do
    if [ ! -f "$REPO_ROOT/vendor/$vendor_tree/ref/kem.c" ]; then
        printf 'error: vendor/%s missing; run: sh tools/fetch_all_vendors.sh\n' \
            "$vendor_tree" >&2
        exit 3
    fi
done

STAGE=$(mktemp -d "${TMPDIR:-/tmp}/r0a-bundle.XXXXXX")
trap 'rm -rf "$STAGE"' EXIT
mkdir -p "$STAGE/tree"
git -C "$REPO_ROOT" archive --format=tar "$COMMIT" | tar -x -C "$STAGE/tree"
cp -r "$REPO_ROOT/vendor/kyber-kyberslash-unfixed" \
    "$REPO_ROOT/vendor/kyber-kyberslash-fixed" "$STAGE/tree/vendor/"

# 证据目录只保留 R0a 执行必需的五处；其余删去以控制包体。
KEEP="m2-kem-20261016 platform-collection-20261016 liboqs010-locked-20261015 r02-r04-close-20261016 r05-locate-20261016"
for entry in "$STAGE/tree"/docs/evidence/*/; do
    name=$(basename "$entry")
    keep=no
    for kept in $KEEP; do [ "$name" = "$kept" ] && keep=yes; done
    [ "$keep" = no ] && rm -rf "$entry"
done
rm -rf "$STAGE/tree/deliverables" "$STAGE/tree/report" "$STAGE/tree/docs/learning"

# build_identity 认两种身份之一：git 仓库根，或带 SOURCE_EXPORT.sha256 的导出。
( cd "$STAGE/tree" && find . -type f ! -name SOURCE_EXPORT.sha256 | LC_ALL=C sort \
    | xargs sha256sum > SOURCE_EXPORT.sha256 )

( cd "$STAGE" && tar -czf "$OUTPUT" tree )
sha256sum "$OUTPUT"
printf 'bundle ready: %s (from %s)\n' "$OUTPUT" "$COMMIT"
