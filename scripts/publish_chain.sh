#!/bin/sh
# 把「报告 → 匿名包 → 解出复算 → 审计 → 门禁」这条发布链按**固定顺序**跑完。
#
# 为什么要有这个脚本（2026-10-21 第 5、6、7 轮复核的共同根因）：
#   报告 PDF 每次 xelatex 都因时间戳而变字节，匿名包又必须内嵌**同一份** report.pdf，
#   审计行又必须指向**当前有效包**的摘要与成员数。这三处的先后顺序一旦颠倒，
#   就会出现「包内报告 ≠ 仓库报告」「审计行写的是旧包的成员数」这类漂移，
#   而它们都只能靠人工记住顺序才能避免。
#
# 用法：
#   sh scripts/publish_chain.sh            # 用下一个可用 revision
#   sh scripts/publish_chain.sh final30-20261021
#
# 幂等性：不改动 sources/ 与已封存证据；只重写报告、支撑包、审计 CSV/MD、
# 三个门禁的产物。revision 必须递增（build_support.py 本身也拒绝重复 revision）。
set -eu

repository=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
cd "$repository"

# **互斥锁**：发布链会依次改写报告、官方件、匿名包与审计；两条工作线同时跑会互相
# 覆盖中间产物（2026-10-21 第 4 轮复核期间实测：成包后 10 秒报告又被另一条链重生成，
# 于是「包内报告 == 仓库报告」这条不变量当场失效）。锁用 mkdir 实现（原子）。
lock_dir="$repository/build/publish-chain.lock"
if ! mkdir "$lock_dir" 2>/dev/null; then
    printf '\n*** 另一条发布链正在运行（锁：%s）。***\n' "$lock_dir" >&2
    printf '*** 等它跑完再执行本链；不要并行跑。***\n\n' >&2
    exit 2
fi
trap 'rmdir "$lock_dir" 2>/dev/null || true' EXIT INT TERM

research=deliverables/research/multi-leakage-platform-20261016
support=deliverables/support/CACR2026EA16XZ-multi-leakage-platform-20261016
refresh=docs/evidence/platform-report-20261016/refresh-20261016

say() { printf '\n=== %s ===\n' "$1"; }

# 0) revision：默认取「已用过的最大序号 + 1」
revision=${1:-}

# 0a) 工作区里有未提交改动时**显著警告**：这条链会把当前工作区的报告内容
#     一路带进匿名包，未提交的改动也会被带进去。
if [ -n "$(git status --porcelain 2>/dev/null)" ]; then
    printf '\n*** 警告：工作区有未提交改动，本链会把它们一起带进报告与匿名包。***\n'
    printf '*** 提交前请确认这些改动是你要的（并行工作线的在制品尤其要注意）。***\n\n'
    git status --short | head -20
    printf '\n'
fi

if [ -z "$revision" ]; then
    highest=0
    for zip in "$support"/CACR2026EA16XZ-platform-final*.zip; do
        [ -e "$zip" ] || continue
        base=$(basename "$zip")
        number=${base#CACR2026EA16XZ-platform-final}
        number=${number%%-*}
        case "$number" in
            ''|*[!0-9]*) continue ;;
        esac
        [ "$number" -gt "$highest" ] && highest=$number
    done
    # 用**本地日期**：仓库里的历史包都以本地日期命名（-20261021），
    # 用 UTC 会在跨零点的时段产出 -20261020 的包名，与同批包名不一致。
    revision="final$((highest + 1))-$(date +%Y%m%d)"
fi
stem=$(printf '%s' "$revision" | sed 's/-[0-9]\{8\}$//')
printf '本次 revision：%s（stem=%s）\n' "$revision" "$stem"

# 1) 先生成报告正文与来源快照（快照变了才允许成包）
say "1  生成报告正文与证据快照"
( cd "$research" && python3 emit_final5_tables.py >/dev/null && python3 generate_report.py )

# 2) 再把报告编译成 PDF：连跑三遍，第二、三遍是收敛后的，日志留作 first/second
say "2  XeLaTeX 收敛（第二、三遍为归档用）"
# 在**报告目录里**编译：中间产物（.aux/.log/.out/.toc/.pdf）落在那里，
# 不会在仓库根留下未被 .gitignore 覆盖的散件（2026-10-21 第 9 轮复核 A5 条）。
# 在**本次运行专属的临时目录**里编译：并行工作线若同时在报告目录里跑 xelatex，
# 共用输出目录会互相覆盖——2026-10-21 第 4 轮复核期间出现过「复制到半截 PDF」
# （93 KB、0 页、缺 %%EOF），下游成包与审计随之失败。
compile_dir=$(mktemp -d "$repository/build/c-XXXXXX")
# **在仓库根编译**（不是报告目录）：报告 .tex 里的插图路径是仓库相对路径
# （`deliverables/research/.../r05-flowchart.png`），只有 CWD 在仓库根时才解析得到；
# 在报告目录里编译会「找不到图」并产出缺图的 PDF。
(
    cd "$repository"
    xelatex -interaction=nonstopmode -output-directory="$compile_dir" "$research/report.tex" > /tmp/publish_chain_xelatex_1.log 2>&1 || true
    xelatex -interaction=nonstopmode -output-directory="$compile_dir" "$research/report.tex" > /tmp/publish_chain_xelatex_2.log 2>&1 || true
    xelatex -interaction=nonstopmode -output-directory="$compile_dir" "$research/report.tex" > /tmp/publish_chain_xelatex_3.log 2>&1 || true
)
# 复制前先验 PDF 完整（能打开、页数 > 0、结尾有 %%EOF）
python3 - "$compile_dir/report.pdf" <<'PY'
import sys
import fitz

path = sys.argv[1]
with open(path, "rb") as handle:
    content = handle.read()
if not content.rstrip().endswith(b"%%EOF"):
    raise SystemExit("编译出的 PDF 不完整（缺 %%EOF），停止")
with fitz.open(path) as document:
    pages = document.page_count
if pages <= 0:
    raise SystemExit("编译出的 PDF 没有页面，停止")
print("PDF 完整：%d 页" % pages)
PY
cp "$compile_dir/report.pdf" "$research/report.pdf"
rm -rf "$compile_dir"
rm -f "$research"/report.aux "$research"/report.log "$research"/report.out \
      "$research"/report.toc "$research"/report.xdv
cp /tmp/publish_chain_xelatex_2.log "$refresh/xelatex-p2-closeout-first.log"
cp /tmp/publish_chain_xelatex_3.log "$refresh/xelatex-p2-closeout-second.log"
printf '警告数：第一遍归档 %s 遍、收敛遍 %s 遍（都应为 0）\n' \
    "$(grep -cE 'Overfull|Underfull|Missing character|LaTeX Warning|hyperref Warning' "$refresh/xelatex-p2-closeout-first.log")" \
    "$(grep -cE 'Overfull|Underfull|Missing character|LaTeX Warning|hyperref Warning' "$refresh/xelatex-p2-closeout-second.log")"

# 3) 官方报告（Word + PDF）也要与平台报告同源
say "3  重出官方作品设计报告（DOCX + PDF）"
sh scripts/build_official_report.sh

# 3a) 页数声明同步到实物（根 README / 交接文档 / 平台报告 README）。
#     统一走仓库已有的 scripts/sync_report_page_counts.py——它在五份文档里同步声明，
#     不要再在这里另写一套（两套口径会互相覆盖）。
#     此前这里被调用了两次（第 10 轮复核问题 10：say 标签与实际调用数对不上），
#     跑两次的结果一样，但会让「失败发生在第几步」读错。
say "3a 同步报告页数声明"
python3 scripts/sync_report_page_counts.py

# 3c) 成包前先确认报告 PDF **完整可读**（页数 > 0、pypdf 也能解析）。
#     并发写同一份 report.pdf 时，可能把写到一半的文件打进包里——
#     final43 就这样坏过（包内 report.pdf 只有 93 KB、pypdf 报 EOF marker not found）。
python3 - <<'PYEOF'
import sys
from pathlib import Path

pdf = Path("deliverables/research/multi-leakage-platform-20261016/report.pdf")
if not pdf.is_file():
    raise SystemExit("报告 PDF 不存在")
try:
    import fitz

    with fitz.open(str(pdf)) as document:
        pages = document.page_count
except Exception as error:
    raise SystemExit("报告 PDF 无法打开：%s" % error)
if pages <= 0:
    raise SystemExit("报告 PDF 页数为 0（多半是写到一半的文件）")
try:
    import io
    import pypdf

    reader = pypdf.PdfReader(str(pdf))
    if len(reader.pages) != pages:
        raise SystemExit("报告 PDF 页数不一致：fitz %d / pypdf %d" % (pages, len(reader.pages)))
except SystemExit:
    raise
except Exception as error:
    raise SystemExit("报告 PDF 无法被 pypdf 解析：%s" % error)
print("报告 PDF 完整：%d 页" % pages)
PYEOF

# 4) 按当前报告成包
say "4  成包 $revision"
rm -rf "build/platform-report-s8/support-$revision" "build/platform-report-s8/canonical-$revision"
rm -f "$support/CACR2026EA16XZ-platform-$revision.zip" "$support/$revision-verification.json"
python3 "$support/build_support.py" --revision "$revision"

# 5) 包审计（直接身份标记、成员数、摘要数、本地链接数）
say "5  包审计"
python3 "$support/verify_package.py" "$support/CACR2026EA16XZ-platform-$revision.zip" > /dev/null

# 6) 从**实际 ZIP** 解出复算（离线回放 + 包内 CTest）
say "6  解出复算"
python3 "$research/audit_revision.py" "$revision"
# 复算脚本由模板改写而成：包名、解出目录、日志名三处都要对上本 revision
sed -e "s#CACR2026EA16XZ-platform-final-[0-9]\{8\}\.zip#CACR2026EA16XZ-platform-$revision.zip#" \
    -e "s#build/zip-recompute-final-[0-9]\{8\}#build/zip-recompute-$stem#" \
    "$refresh/run_zip_recompute_final.sh" > "$refresh/run_zip_recompute_$stem.sh"
chmod +x "$refresh/run_zip_recompute_$stem.sh"
sh "$refresh/run_zip_recompute_$stem.sh" > "$refresh/zip-recompute-$stem.log" 2>&1
grep -q '100% tests passed, 0 tests failed out of 5' "$refresh/zip-recompute-$stem.log" \
    || { printf '解出复算未通过，停止\n' >&2; exit 1; }

# 7) 把「当前有效包」的声明指向本包，并重生成审计
say "7  指向当前有效包 + 重生成审计"
python3 scripts/point_current_package.py "$revision"
python3 scripts/build_final_audit_v91.py
python3 scripts/run_final_audit_checks.py \
    --csv docs/evidence/platform-completion-20261016/FINAL_AUDIT.csv \
    --out docs/evidence/platform-completion-20261016/final-audit-checks-20261020.json || true
python3 scripts/sync_final_audit_md_facts.py
# 审计 CSV 变了，证据路径与行数随之变，审计 JSON 要按新 CSV 再跑一遍才对得上
python3 scripts/run_final_audit_checks.py \
    --csv docs/evidence/platform-completion-20261016/FINAL_AUDIT.csv \
    --out docs/evidence/platform-completion-20261016/final-audit-checks-20261020.json

# 9) 三个门禁
say "8  刷新上传件、上传清单与支撑包 README 的历次成包表"
# 顺序要紧：提交一致性门禁会核对**被跟踪的**上传清单，刷新必须在门禁之前，
# 否则门禁失败会让链在这里中止、清单永远刷不到（2026-10-21 第 9 轮复核 A4 条）。
python3 scripts/make_upload_package.py
python3 scripts/refresh_support_readme_table.py

say "9  三个门禁"
python3 scripts/run_final_audit_checks.py \
    --csv docs/evidence/platform-completion-20261016/FINAL_AUDIT.csv \
    --out docs/evidence/platform-completion-20261016/final-audit-checks-20261020.json
python3 scripts/check_signoff_items.py
python3 scripts/check_submission_consistency.py

# 8a) 关键不变量：仓库里的 report.pdf 与包内的 report/report.pdf 必须逐字同源
say "10  核对「仓库报告 == 包内报告」"
python3 - "$revision" <<'PY'
import hashlib
import sys
import zipfile

revision = sys.argv[1]
support = "deliverables/support/CACR2026EA16XZ-multi-leakage-platform-20261016"
archive = "%s/CACR2026EA16XZ-platform-%s.zip" % (support, revision)
repository = hashlib.sha256(open("deliverables/research/multi-leakage-platform-20261016/report.pdf", "rb").read()).hexdigest()
with zipfile.ZipFile(archive) as package:
    packaged = hashlib.sha256(package.read("report/report.pdf")).hexdigest()
print("仓库 report.pdf :", repository)
print("包内 report.pdf :", packaged)
if repository != packaged:
    raise SystemExit("不变量被破坏：仓库报告与包内报告不是同一份")
print("同源 ✓")
PY

say "11 交付件终检（从证据原件重算，不复用派生审计表）"
# 终检是**独立**的一层：前面三个门禁核对的是产物里的命令，这一步直接读证据原件
# 重算关键数字（A 的检测预算与终态、B 的 checkct 结论、C 的精度数字、D 的清单项数、
# E 的 12 格、F 的包与三件交付物），避免「用产物验产物」。
python3 scripts/final_delivery_check.py

say "完成：当前有效包 $revision"
printf '提交前请确认：`git status` 里只有本链产生的改动。\n'
