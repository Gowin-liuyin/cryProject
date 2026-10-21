#!/usr/bin/env bash
# 官方《作品设计报告》DOCX + 同名 PDF 的**迭代**构建。
#
# 为什么必须迭代：LibreOffice 无头导出不会展开 Word 的 TOC 域（目录只剩一行"打开时自动更新"），
# 第一遍量到的页码是按「目录占 1 行」算的；改成静态目录（33 条、占满一页）后正文整体后移，
# 打印出来的目录页码就整体差 1 页——文本层照样"有页码"，只有人翻页才发现。
# 因此这里循环「写静态目录 → 导出 → 再量页码」，直到页码不再变化（静态目录行数固定，一次即收敛），
# 最后用 scripts/check_official_toc.py 独立复核「目录打印页码 == 标题实际页码」。
#
# 字体口径（2026-10-20 起强制）：本机 LibreOffice 26.8.1.1 默认找不到 macOS 的
# 中文系统字体，导出的 PDF 里汉字整段不显示（文本层却还在，纯文本检查抓不到）。
# 因此导出前用仓库内的 scripts/libreoffice-fonts.conf 显式给出系统字体目录，
# 导出后再用 scripts/check_pdf_render.py 把关：没有中文字体或页面渲染全白即失败。
#
# 只用仓库内脚本与本机工具；不写仓库外的固定路径，临时产物都落在 build/ 下。
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "${REPO_ROOT}"

DOCX_NAME="CACR2026EA16XZ-作品设计报告.docx"
PDF_NAME="${DOCX_NAME%.docx}.pdf"
WORK_DIR="build/official-report"
SOFFICE="${SOFFICE:-/Applications/LibreOffice.app/Contents/MacOS/soffice}"
FONTCONFIG_FILE="${REPO_ROOT}/scripts/libreoffice-fonts.conf"
export FONTCONFIG_FILE
MAX_PASSES=5

if [ ! -x "${SOFFICE}" ]; then
    printf '未找到 LibreOffice 可执行文件：%s\n' "${SOFFICE}" >&2
    exit 1
fi

mkdir -p build/fonts-cache
rm -rf "${WORK_DIR}"
mkdir -p "${WORK_DIR}"

render_pdf() {
    local docx_path="$1"
    local out_dir="$2"
    rm -rf "${out_dir}"
    mkdir -p "${out_dir}"
    "${SOFFICE}" --headless --norestore \
        --convert-to 'pdf:writer_pdf_Export' \
        --outdir "${out_dir}" "${docx_path}" >/dev/null 2>&1
}

printf '[1] 生成 DOCX（含 TOC 域）并导出第一遍 PDF\n'
python3 scripts/build_official_docx.py
render_pdf "${DOCX_NAME}" "${WORK_DIR}/pass1"

printf '[2] 从第一遍 PDF 的书签取实测页码\n'
python3 scripts/build_official_docx_toc.py \
    --pdf "${WORK_DIR}/pass1/${PDF_NAME}" \
    --out "${WORK_DIR}/toc-pages.json"

printf '[3] 迭代：写静态目录 → 导出 → 再量页码，直到页码稳定\n'
pass=2
cp "${WORK_DIR}/toc-pages.json" "${WORK_DIR}/toc-pages-written.json"
while [ "${pass}" -le "${MAX_PASSES}" ]; do
    python3 scripts/build_official_docx.py --toc-pages "${WORK_DIR}/toc-pages-written.json" >/dev/null
    render_pdf "${DOCX_NAME}" "${WORK_DIR}/pass${pass}"
    python3 scripts/build_official_docx_toc.py \
        --pdf "${WORK_DIR}/pass${pass}/${PDF_NAME}" \
        --out "${WORK_DIR}/toc-pages-next.json" >/dev/null
    if cmp -s "${WORK_DIR}/toc-pages-written.json" "${WORK_DIR}/toc-pages-next.json"; then
        printf '  第 %d 遍：页码已稳定（收敛）\n' "${pass}"
        FINAL_PASS="${pass}"
        break
    fi
    printf '  第 %d 遍：页码有变化，按新页码重写目录\n' "${pass}"
    cp "${WORK_DIR}/toc-pages-next.json" "${WORK_DIR}/toc-pages-written.json"
    pass=$((pass + 1))
done

if [ -z "${FINAL_PASS:-}" ]; then
    printf '目录页码在 %d 遍内没有收敛，按失败返回。\n' "${MAX_PASSES}" >&2
    exit 1
fi

cp "${WORK_DIR}/pass${FINAL_PASS}/${PDF_NAME}" "${PDF_NAME}"

printf '[4] 独立复核目录打印页码与标题实际页码\n'
python3 scripts/check_official_toc.py "${PDF_NAME}"

printf '[5] 检查 PDF 的中文字形确实渲染出来\n'
# --max-overlaps 0：官方报告里**不允许有文字物理重叠**（组合符号或长片段顶到邻列）。
# 平台报告走 LaTeX，CJK 标点与数学符号的相邻 span 本就会轻微相交，故不套这道门禁。
python3 scripts/check_pdf_render.py "${PDF_NAME}" --max-overlaps 0

printf '完成：%s 与 %s（第 %d 遍收敛）\n' "${DOCX_NAME}" "${PDF_NAME}" "${FINAL_PASS}"
