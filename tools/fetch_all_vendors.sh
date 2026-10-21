#!/bin/sh
# 一键取件：把干净 clone 缺失的 vendor 树取齐，并逐项校验 SHA-256。
#
# 取件清单（上游标识与摘要全部钉死在脚本里，不依赖运行时下载内容自证）：
#   1. vendor/liboqs-0.10.0            liboqs 0.10.0（tag，commit 36be5744）——M1 未修阳性对照
#   2. vendor/liboqs-0.10.0-982c762    同一棵树 + 仓库内保存的官方补丁 982c762——M1 已修臂
#   3. vendor/kyber-kyberslash-unfixed  pq-crystals/kyber a621b8d——M2 未修臂
#   4. vendor/kyber-kyberslash-fixed    pq-crystals/kyber 272125f——M2 已修臂
#
# 幂等：已存在且摘要一致的树直接跳过；摘要不一致时拒绝覆盖并报错退出。
# 校验口径两层：
#   * 上游归档摘要——liboqs tag tar、两个 kyber git archive tar；
#   * 树摘要——对树内每个普通文件与符号链接各算一次 SHA-256，按相对路径排序后
#     再整体算一次 SHA-256。相对路径用 ./ 开头、排序用 LC_ALL=C，故跨平台稳定。
#     树摘要既能验证已存在的树，也能在取件后立刻复核落地结果。
#
# 用法：sh tools/fetch_all_vendors.sh
set -eu

repository_root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
vendor_root="${repository_root}/vendor"

liboqs_base_dir="${vendor_root}/liboqs-0.10.0"
liboqs_patched_dir="${vendor_root}/liboqs-0.10.0-982c762"
kyber_unfixed_dir="${vendor_root}/kyber-kyberslash-unfixed"
kyber_fixed_dir="${vendor_root}/kyber-kyberslash-fixed"

patch_file="${repository_root}/docs/patches/liboqs-982c762.patch"
patch_expected_sha256="d1879ac6aa52cfbd8fbe91a282e2f2696115fdec807d7f2f79543181edbe6376"

liboqs_base_tree_sha256="d3322945483983b45c60406127790107865706523c4e83a15e27c7211c776cdd"
liboqs_patched_tree_sha256="e27e55e5bdb59e89bfe26c8f82ddf8b162346537333c8b18b9e61c9d91093f14"
kyber_unfixed_tree_sha256="1898b727ed24e014cb731442b9a83cd4d82fc49e06899f9ab2d9364ecd60397f"
kyber_fixed_tree_sha256="8503134f538461c03820e13a0936024a46fff5d85ba334fb0a365f6378a49976"

# 打补丁后必须出现的三个标记：一个掩码选择调用、一个常量时间实现、一个声明。
patch_marker_poly="cmov_int16(r->coeffs+8*i+j, ((KYBER_Q+1)/2), (msg[i] >> j)&1);"
patch_marker_verify="void cmov_int16(int16_t *r, int16_t v, uint16_t b)"
patch_marker_header="void cmov_int16(int16_t *r, int16_t v, uint16_t b);"

log_line() {
    printf '%s\n' "$*"
}

fail() {
    printf '错误：%s\n' "$*" >&2
    exit 1
}

sha256_of_file() {
    if command -v sha256sum >/dev/null 2>&1; then
        sha256sum "$1" | awk '{print $1}'
    else
        shasum -a 256 "$1" | awk '{print $1}'
    fi
}

sha256_of_stream() {
    if command -v sha256sum >/dev/null 2>&1; then
        sha256sum | awk '{print $1}'
    else
        shasum -a 256 | awk '{print $1}'
    fi
}

# 树的逐项清单：普通文件记内容摘要，符号链接记目标，不记录目录（由路径隐含）。
tree_manifest() {
    target_root=$1
    (
        cd "$target_root" || exit 1
        find . -mindepth 1 \( -type f -o -type l \) -print | LC_ALL=C sort | while IFS= read -r entry; do
            if [ -L "$entry" ]; then
                printf 'link %s -> %s\n' "$entry" "$(readlink "$entry")"
            else
                printf 'file %s %s\n' "$entry" "$(sha256_of_file "$entry")"
            fi
        done
    )
}

tree_digest() {
    tree_manifest "$1" | sha256_of_stream
}

# 比较实际树摘要与期望值；相等返回 0，不等返回 1（不退出，便于调用方决定动作）。
tree_digest_matches() {
    target_root=$1
    expected_digest=$2
    [ -d "$target_root" ] || return 1
    actual_digest=$(tree_digest "$target_root")
    [ "$actual_digest" = "$expected_digest" ]
}

check_required_tools() {
    for tool_name in git tar patch find sort; do
        command -v "$tool_name" >/dev/null 2>&1 || fail "缺少命令：${tool_name}"
    done
    if ! command -v sha256sum >/dev/null 2>&1 && ! command -v shasum >/dev/null 2>&1; then
        fail "缺少 sha256sum 或 shasum，无法校验 SHA-256"
    fi
}

# 封存的 fetch_vendor.sh 用的是 shasum -a 256。精简 Linux 可能没有 perl 的
# shasum，这里做一个临时垫片（coreutils sha256sum 同语义），只在本机缺 shasum 时使用。
make_shasum_shim() {
    if command -v shasum >/dev/null 2>&1; then
        shim_directory=
        return 0
    fi
    command -v sha256sum >/dev/null 2>&1 || return 1
    shim_directory=$(mktemp -d "${TMPDIR:-/tmp}/shasum-shim.XXXXXX")
    cat >"${shim_directory}/shasum" <<'SHIM'
#!/bin/sh
# 兼容垫片：只实现 fetch_vendor.sh 用到的 `shasum -a 256 <file>` 形式。
if [ "${1:-}" = "-a" ] && [ "${2:-}" = "256" ]; then
    shift 2
else
    printf 'shim 只支持 -a 256 用法\n' >&2
    exit 2
fi
exec sha256sum "$@"
SHIM
    chmod +x "${shim_directory}/shasum"
    return 0
}

# 校验并打印一棵树的状态；摘要一致返回 0，不一致或缺失返回 1。
report_tree() {
    label=$1
    target_root=$2
    expected_digest=$3
    if tree_digest_matches "$target_root" "$expected_digest"; then
        log_line "  [一致] ${label}"
        log_line "         目录 ${target_root}"
        log_line "         树摘要 ${expected_digest}"
        return 0
    fi
    log_line "  [缺失或不一致] ${label}"
    log_line "         目录 ${target_root}"
    return 1
}

fetch_liboqs_base() {
    log_line ""
    log_line "=== 第 1 步：liboqs 0.10.0 未修阳性对照 ==="
    if tree_digest_matches "$liboqs_base_dir" "$liboqs_base_tree_sha256"; then
        log_line "已存在且摘要一致，跳过下载。"
    else
        if [ -d "$liboqs_base_dir" ]; then
            fail "${liboqs_base_dir} 已存在但摘要不符；不覆盖既有树，请人工核对后处理。"
        fi
        sh "${repository_root}/tools/fetch_liboqs_0.10.0.sh" ||
            fail "tools/fetch_liboqs_0.10.0.sh 失败"
    fi
    report_tree "liboqs 0.10.0（tag 0.10.0，commit 36be5744）" \
        "$liboqs_base_dir" "$liboqs_base_tree_sha256" ||
        fail "${liboqs_base_dir} 摘要校验未通过"
}

fetch_liboqs_patched() {
    log_line ""
    log_line "=== 第 2 步：liboqs 0.10.0 + 官方补丁 982c762 已修臂 ==="
    [ -f "$patch_file" ] || fail "缺少仓库内补丁副本 ${patch_file}"
    actual_patch_sha256=$(sha256_of_file "$patch_file")
    if [ "$actual_patch_sha256" != "$patch_expected_sha256" ]; then
        fail "仓库内补丁摘要不符
期望 ${patch_expected_sha256}
实际 ${actual_patch_sha256}"
    fi
    log_line "补丁文件 ${patch_file}"
    log_line "补丁摘要 ${actual_patch_sha256}（与记录一致）"

    if tree_digest_matches "$liboqs_patched_dir" "$liboqs_patched_tree_sha256"; then
        log_line "已存在且摘要一致，跳过打补丁。"
    else
        if [ -e "$liboqs_patched_dir" ]; then
            fail "${liboqs_patched_dir} 已存在但摘要不符；不覆盖既有树，请人工核对后处理。"
        fi
        tree_digest_matches "$liboqs_base_dir" "$liboqs_base_tree_sha256" ||
            fail "未修树缺失或摘要不符，无法生成已修副本"
        cp -a "$liboqs_base_dir" "$liboqs_patched_dir"
        # 用 patch 而不是 git apply：vendor 树位于本仓库工作树内，git apply 会把
        # 子目录之外的路径当作「仓库外」而整条忽略。补丁文件必须给绝对路径。
        patch -p1 -d "$liboqs_patched_dir" -i "$patch_file" ||
            fail "打补丁失败：patch -p1"
        if find "$liboqs_patched_dir" \( -name '*.orig' -o -name '*.rej' \) -print | grep -q .; then
            fail "打补丁留下了 .orig/.rej 文件，说明补丁没有干净应用"
        fi
    fi

    patched_poly="${liboqs_patched_dir}/src/kem/ml_kem/pqcrystals-kyber-standard_ml-kem-768-ipd_ref/poly.c"
    patched_verify="${liboqs_patched_dir}/src/kem/ml_kem/pqcrystals-kyber-standard_ml-kem-768-ipd_ref/verify.c"
    patched_header="${liboqs_patched_dir}/src/kem/ml_kem/pqcrystals-kyber-standard_ml-kem-768-ipd_ref/verify.h"
    grep -qF "$patch_marker_poly" "$patched_poly" ||
        fail "补丁效果未落到 poly.c（找不到 ${patch_marker_poly}）"
    grep -qF "$patch_marker_verify" "$patched_verify" ||
        fail "补丁效果未落到 verify.c（找不到 ${patch_marker_verify}）"
    grep -qF "$patch_marker_header" "$patched_header" ||
        fail "补丁效果未落到 verify.h（找不到 ${patch_marker_header}）"
    log_line "补丁效果标记三处齐备（poly.c 掩码选择、verify.c 常量时间实现、verify.h 声明）。"

    report_tree "liboqs 0.10.0-982c762（官方补丁已修）" \
        "$liboqs_patched_dir" "$liboqs_patched_tree_sha256" ||
        fail "${liboqs_patched_dir} 摘要校验未通过"
}

fetch_kyber_trees() {
    log_line ""
    log_line "=== 第 3 步：M2 KyberSlash 未修 / 已修两臂 ==="
    unfixed_present=0
    fixed_present=0
    if tree_digest_matches "$kyber_unfixed_dir" "$kyber_unfixed_tree_sha256"; then
        unfixed_present=1
    fi
    if tree_digest_matches "$kyber_fixed_dir" "$kyber_fixed_tree_sha256"; then
        fixed_present=1
    fi

    if [ "$unfixed_present" -eq 1 ] && [ "$fixed_present" -eq 1 ]; then
        log_line "两臂均已存在且摘要一致，跳过取件。"
    else
        if [ -e "$kyber_unfixed_dir" ] || [ -e "$kyber_fixed_dir" ]; then
            fail "M2 两臂只有一臂就绪且摘要一致；为避免覆盖既有树，停止取件，请人工核对后处理。"
        fi
        fetch_script="${repository_root}/docs/evidence/m2-kyberslash-20261016/version-audit/fetch_vendor.sh"
        [ -f "$fetch_script" ] || fail "缺少取件脚本 ${fetch_script}"
        # fetch_vendor.sh 在 fetch 目录已存在时拒绝运行；把残留的镜像目录挪到
        # build/ 下的时间戳目录，既不删除任何内容，也不让脚本因残留而中止。
        stale_fetch_root="${repository_root}/build/platform-s4/fetch-fixed-commits"
        if [ -e "$stale_fetch_root" ]; then
            stale_target="${repository_root}/build/fetch-stale-$(date -u +%Y%m%dT%H%M%SZ)"
            mkdir -p "$(dirname -- "$stale_target")"
            mv "$stale_fetch_root" "$stale_target"
            log_line "残留 fetch 目录已挪到 ${stale_target}（未删除任何内容）。"
        fi
        shim_directory=
        make_shasum_shim || true
        if [ -n "$shim_directory" ]; then
            PATH="${shim_directory}:${PATH}"
            export PATH
            log_line "本机没有 shasum，已用 sha256sum 兼容垫片顶上。"
        fi
        sh "$fetch_script" || fail "fetch_vendor.sh 失败"
    fi

    report_tree "M2 未修 a621b8d" "$kyber_unfixed_dir" "$kyber_unfixed_tree_sha256" ||
        fail "${kyber_unfixed_dir} 摘要校验未通过"
    report_tree "M2 已修 272125f" "$kyber_fixed_dir" "$kyber_fixed_tree_sha256" ||
        fail "${kyber_fixed_dir} 摘要校验未通过"
}

main() {
    check_required_tools
    trap 'if [ -n "${shim_directory:-}" ] && [ -d "${shim_directory}" ]; then rm -rf "${shim_directory}"; fi' EXIT INT TERM
    log_line "一键取件：仓库 ${repository_root}"
    log_line "校验口径：上游归档 SHA-256 + 树内逐文件 SHA-256 的整体摘要。"
    mkdir -p "$vendor_root"
    fetch_liboqs_base
    fetch_liboqs_patched
    fetch_kyber_trees
    log_line ""
    log_line "=== 取件完成：四棵 vendor 树的 SHA-256 全部一致 ==="
    log_line "  vendor/liboqs-0.10.0             ${liboqs_base_tree_sha256}"
    log_line "  vendor/liboqs-0.10.0-982c762     ${liboqs_patched_tree_sha256}"
    log_line "  vendor/kyber-kyberslash-unfixed  ${kyber_unfixed_tree_sha256}"
    log_line "  vendor/kyber-kyberslash-fixed    ${kyber_fixed_tree_sha256}"
    log_line ""
    log_line "下一步：sh scripts/reproduce_all.sh quick"
    log_line "已修臂需要在配置时把 -DLIBOQS010_SOURCE_DIR 指向 ${liboqs_patched_dir}。"
}

main "$@"
