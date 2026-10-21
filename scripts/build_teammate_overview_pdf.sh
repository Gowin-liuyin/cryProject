#!/usr/bin/env bash
# 由 Markdown 生成《给队友的项目全景说明》PDF。
#
# 排版口径与仓库内其它中文 PDF 一致：ctexart + fandol 字体集、a4、
# 两遍 XeLaTeX 固定交叉引用与页码；中间产物落在 build/ 下，不写仓库外的固定路径。
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "${REPO_ROOT}"

SOURCE="docs/给队友的项目全景说明-20261016.md"
OUTPUT="docs/给队友的项目全景说明-20261016.pdf"
WORK_DIR="${REPO_ROOT}/build/teammate-overview"

if [ ! -f "${SOURCE}" ]; then
    printf '缺少输入：%s\n' "${SOURCE}" >&2
    exit 1
fi

rm -rf "${WORK_DIR}"
mkdir -p "${WORK_DIR}"

pandoc "${SOURCE}" \
    --standalone \
    --pdf-engine=xelatex \
    -V documentclass=ctexart \
    -V 'classoption:fontset=fandol' \
    -V papersize=a4 \
    -V geometry:margin=20mm \
    --toc \
    --toc-depth=2 \
    -o "${WORK_DIR}/teammate-overview.tex"

cd "${WORK_DIR}"
xelatex -interaction=nonstopmode -halt-on-error teammate-overview.tex >/dev/null
xelatex -interaction=nonstopmode -halt-on-error teammate-overview.tex >/dev/null

cp "${WORK_DIR}/teammate-overview.pdf" "${REPO_ROOT}/${OUTPUT}"
printf '完成：%s\n' "${OUTPUT}"