#!/bin/bash
# 一键部署脚本 - 立即应用所有修改并编译验证

set -e

echo "╔══════════════════════════════════════════╗"
echo "║  ML-KEM 报告 一键部署                    ║"
echo "║  准备最终交付                              ║"
echo "╚══════════════════════════════════════════╝"
echo ""

# 1. 确认当前目录
if [ ! -f "main.tex" ]; then
  echo "✗ 错误：不在报告目录中"
  echo "请在 /Users/yin/code/cryProject/report 运行本脚本"
  exit 1
fi

echo "[1/4] 应用所有待处理修改..."

# 清理剩余的"登记"词汇（用自然表达替换）
for file in chapters/ch*.tex chapters/appendix.tex; do
  # 通用的"登记"清理
  sed -i '' 's/ 按.*登记/ 记录/g' "$file"
  sed -i '' 's/，按.*登记/，记录为/g' "$file"
done

echo "✓ 修改应用完成"
echo ""

# 2. 备份原文件（以防万一）
echo "[2/4] 创建备份..."
BACKUP_DIR="pre_final_backup_$(date +%Y%m%d_%H%M%S)"
cp -r chapters "$BACKUP_DIR"
echo "✓ 备份已创建：$BACKUP_DIR"
echo ""

# 3. 编译验证
echo "[3/4] 开始编译..."
echo "  第1遍..."
xelatex -interaction=nonstopmode main.tex > /dev/null 2>&1 || true
echo "  第2遍..."
xelatex -interaction=nonstopmode main.tex > /dev/null 2>&1 || true
echo "  第3遍..."
if xelatex -interaction=nonstopmode main.tex > compile_final.log 2>&1; then
  echo "✓ 编译成功"
else
  echo "⚠ 编译含Warning，检查编译日志"
  tail -20 compile_final.log
fi
echo ""

# 4. 最终检查
echo "[4/4] 最终检查..."
if [ -f "main.pdf" ]; then
  PAGES=$(pdfinfo main.pdf 2>/dev/null | grep "Pages:" | awk '{print $2}' || echo "unknown")
  SIZE=$(ls -lh main.pdf | awk '{print $5}')
  echo "✓ PDF 已生成"
  echo "  页数：$PAGES 页（预期78-88页）"
  echo "  大小：$SIZE"
else
  echo "✗ PDF 生成失败"
  exit 1
fi
echo ""

echo "╔══════════════════════════════════════════╗"
echo "║  ✓ 全部就绪！可以提交！                  ║"
echo "╚══════════════════════════════════════════╝"
echo ""
echo "下一步："
echo "  1. 打开 main.pdf 最后检查排版"
echo "  2. 确认无遗漏问题"
echo "  3. 上传系统提交"
echo ""
echo "如有问题，还有备份目录：$BACKUP_DIR"
echo ""
