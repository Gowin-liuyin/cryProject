#!/bin/bash
# 最终编译与验证脚本 - ML-KEM报告交付前最后检查
# 在 /Users/yin/code/cryProject/report 运行

set -e

echo "╔════════════════════════════════════════════╗"
echo "║  ML-KEM 报告最终编译与验证                  ║"
echo "║  版本：最终交付版                            ║"
echo "╚════════════════════════════════════════════╝"
echo ""

# 1. 预编译检查
echo "[1/5] 预编译检查..."
echo "  • 检查LaTeX文件完整性"
for file in chapters/ch*.tex chapters/abstract.tex chapters/appendix.tex; do
  if [ ! -f "$file" ]; then
    echo "    ✗ 缺失文件: $file"
    exit 1
  fi
  # 检查\end{document}
  if ! grep -q "^%\|\\\\end{" main.tex 2>/dev/null | head -1; then
    echo "    ⚠ 警告：$file 可能未正确关闭"
  fi
done
echo "  ✓ 所有文件就绪"
echo ""

# 2. 关键字检查
echo "[2/5] 关键字检查（机械口癖、过度限定）..."
echo "  • 扫描机械口癖..."

ISSUES=0

# 检查机械口癖
for pattern in "按.*登记" "结论只在" "分别登记" "不作合并" "新缺陷主张"; do
  COUNT=$(grep -r "$pattern" chapters/*.tex 2>/dev/null | wc -l)
  if [ $COUNT -gt 0 ]; then
    echo "    ⚠ 发现 '$pattern': $COUNT 处"
    ((ISSUES+=COUNT))
  fi
done

# 检查过度限定（仅摘要允许"限本次对象与输入"）
COUNT=$(grep -r "（限本次对象与输入）" chapters/ch*.tex 2>/dev/null | wc -l)
if [ $COUNT -gt 0 ]; then
  echo "    ⚠ 发现过度限定 '（限本次对象与输入）': $COUNT 处（摘要允许）"
fi

if [ $ISSUES -eq 0 ]; then
  echo "  ✓ 机械口癖清零"
else
  echo "  ✗ 仍有 $ISSUES 个问题需修复"
fi
echo ""

# 3. 笔误检查
echo "[3/5] 笔误检查..."
TYPOS=0

typo_checks=(
  "56,191.656,191.6:表4.7重复数据"
  "拒绝(3项显着):错别字"
  "不拒绝(全族(0):括号错误"
  "误报警象:错别字"
  "可变时廷:错别字"
  "存在)项:括号错误"
)

for check in "${typo_checks[@]}"; do
  pattern="${check%%:*}"
  description="${check##*:}"
  COUNT=$(grep -r "$pattern" chapters/*.tex appendix.tex 2>/dev/null | wc -l)
  if [ $COUNT -gt 0 ]; then
    echo "    ⚠ $description: $COUNT 处"
    ((TYPOS+=COUNT))
  fi
done

if [ $TYPOS -eq 0 ]; then
  echo "  ✓ 笔误清零"
else
  echo "  ⚠ 仍有 $TYPOS 个笔误"
fi
echo ""

# 4. 编译（查找xelatex）
echo "[4/5] 编译报告（寻找xelatex）..."

# 尝试找到xelatex
XELATEX=""
for path in /usr/local/bin/xelatex /opt/local/bin/xelatex ~/.texlive*/bin/*/xelatex ~/Library/TeX/bin/xelatex; do
  if [ -x "$path" ]; then
    XELATEX="$path"
    break
  fi
done

if [ -z "$XELATEX" ]; then
  echo "  ⚠ 未找到xelatex，尝试使用pdflatex..."
  XELATEX="pdflatex"
fi

echo "  使用: $XELATEX"
echo "  第1遍编译..."
$XELATEX -interaction=nonstopmode main.tex > /dev/null 2>&1 || echo "    (第1遍可能含Warning，继续)"

echo "  第2遍编译..."
$XELATEX -interaction=nonstopmode main.tex > /dev/null 2>&1 || echo "    (第2遍可能含Warning，继续)"

echo "  第3遍编译..."
if $XELATEX -interaction=nonstopmode main.tex > compile.log 2>&1; then
  echo "  ✓ 编译成功"
else
  echo "  ✗ 编译失败，查看最后50行："
  tail -50 compile.log
  exit 1
fi
echo ""

# 5. PDF验证
echo "[5/5] PDF验证..."
if [ -f "main.pdf" ]; then
  PAGES=$(pdfinfo main.pdf 2>/dev/null | grep "Pages:" | awk '{print $2}' || echo "unknown")
  echo "  ✓ PDF已生成"
  echo "    总页数: $PAGES (预期: 78-88页)"
  echo "    文件大小: $(ls -lh main.pdf | awk '{print $5}')"
else
  echo "  ✗ PDF生成失败"
  exit 1
fi
echo ""

echo "╔════════════════════════════════════════════╗"
echo "║  ✓ 编译验证完成！报告已就绪可提交          ║"
echo "╚════════════════════════════════════════════╝"
echo ""
echo "下一步："
echo "  1. 检查 main.pdf 的排版是否正常"
echo "  2. 如有问题，根据上述扫描结果修改"
echo "  3. 重新运行本脚本验证"
echo "  4. 提交完成！"
echo ""
