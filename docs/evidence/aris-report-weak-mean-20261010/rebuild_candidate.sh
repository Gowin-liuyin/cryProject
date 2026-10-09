#!/bin/sh
set -eu

candidate_work_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
candidate_python=/Users/yin/.cache/codex-runtimes/codex-primary-runtime/dependencies/python/bin/python3
candidate_renderer=/Users/yin/.codex/plugins/cache/openai-primary-runtime/documents/26.1007.11041/skills/documents/render_docx.py
candidate_name=CACR2026EA16XZ-作品设计报告-弱均值补充候选版
export FONTCONFIG_FILE="$candidate_work_dir/fonts.conf"

"$candidate_python" "$candidate_work_dir/build_candidate.py"
"$candidate_python" "$candidate_renderer" "$candidate_work_dir/$candidate_name.docx" --output_dir "$candidate_work_dir/render-reproduce-initial" --emit_pdf
"$candidate_python" "$candidate_work_dir/finalize_candidate.py" --pdf "$candidate_work_dir/render-reproduce-initial/$candidate_name.pdf"
"$candidate_python" "$candidate_renderer" "$candidate_work_dir/$candidate_name.docx" --output_dir "$candidate_work_dir/render-reproduce-final" --emit_pdf
"$candidate_python" "$candidate_work_dir/verify_candidate.py" --pdf "$candidate_work_dir/render-reproduce-final/$candidate_name.pdf" --png-dir "$candidate_work_dir/render-reproduce-final"
