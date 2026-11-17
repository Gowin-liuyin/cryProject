#!/bin/bash
# fix_tables.sh - 批量修复表格格式
# 在 /Users/yin/code/cryProject/report 目录下运行

set -e

echo "========================================="
echo "  表格与排版自动修复脚本"
echo "========================================="
echo ""

# 1. 备份
echo "[1/4] 备份原文件..."
BACKUP_DIR="chapters.backup.$(date +%Y%m%d_%H%M%S)"
cp -r chapters "$BACKUP_DIR"
echo "      已备份到: $BACKUP_DIR"
echo ""

# 2. 修复表格第一列居中
echo "[2/4] 修复表格第一列对齐方式..."
for file in chapters/*.tex; do
  # 常见的第一列宽度：3.0cm, 2.6cm, 2.7cm, 0.8cm, 0.6cm
  sed -i.tmp 's/{|>{\raggedright\arraybackslash}p{3\.0cm}|/{|>{\centering\arraybackslash}p{3.0cm}|/g' "$file"
  sed -i.tmp 's/{|>{\raggedright\arraybackslash}p{2\.6cm}|/{|>{\centering\arraybackslash}p{2.6cm}|/g' "$file"
  sed -i.tmp 's/{|>{\raggedright\arraybackslash}p{2\.7cm}|/{|>{\centering\arraybackslash}p{2.7cm}|/g' "$file"
  sed -i.tmp 's/{|>{\raggedright\arraybackslash}p{0\.8cm}|/{|>{\centering\arraybackslash}p{0.8cm}|/g' "$file"
  sed -i.tmp 's/{|>{\raggedright\arraybackslash}p{0\.6cm}|/{|>{\centering\arraybackslash}p{0.6cm}|/g' "$file"

  # 清理临时文件
  rm -f "$file.tmp"
done
echo "      ✓ 表格第一列已改为居中对齐"
echo ""

# 3. 查找所有表注位置
echo "[3/4] 扫描所有表注..."
grep -n "表注：" chapters/*.tex > _表注位置清单.txt 2>/dev/null || echo "      未找到表注（可能已删除）"
if [ -s _表注位置清单.txt ]; then
  echo "      找到 $(wc -l < _表注位置清单.txt) 处表注，已记录到：_表注位置清单.txt"
  echo "      请手动将这些表注内容融入正文"
else
  rm -f _表注位置清单.txt
  echo "      ✓ 无需处理表注"
fi
echo ""

# 4. 测试编译
echo "[4/4] 测试编译..."
if command -v latexmk &> /dev/null; then
  latexmk -xelatex -interaction=nonstopmode main.tex > _compile.log 2>&1

  if [ $? -eq 0 ]; then
    echo "      ✓ 编译成功！"
    pages=$(pdfinfo main.pdf 2>/dev/null | grep "Pages:" | awk '{print $2}')
    if [ -n "$pages" ]; then
      echo "      PDF 总页数: $pages"
    fi
  else
    echo "      ✗ 编译出错，请检查：_compile.log"
    tail -50 _compile.log
    exit 1
  fi
else
  echo "      ! latexmk 未安装，跳过编译测试"
fi
echo ""

echo "========================================="
echo "  修复完成！"
echo "========================================="
echo ""
echo "下一步："
echo "  1. 如有表注，请根据 _表注位置清单.txt 手动改写并融入正文"
echo "  2. 检查 PDF 输出：open main.pdf"
echo "  3. 如需恢复，运行：rm -r chapters && mv $BACKUP_DIR chapters"
echo ""
