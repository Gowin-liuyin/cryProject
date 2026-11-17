#!/bin/bash
# fix_typos.sh - 快速修复剩余笔误
# 在 /Users/yin/code/cryProject/report 目录下运行

set -e

echo "========================================="
echo "  快速修复剩余笔误"
echo "========================================="
echo ""

# 备份
echo "[1/2] 创建备份..."
BACKUP_DIR="typos.backup.$(date +%Y%m%d_%H%M%S)"
cp chapters/ch4.tex "$BACKUP_DIR.ch4.tex"
cp chapters/appendix.tex "$BACKUP_DIR.appendix.tex"
echo "      已备份到: $BACKUP_DIR.*"
echo ""

echo "[2/2] 修复笔误..."

# 1. 表4.7数据重复
echo "  - 修复 56,191.656,191.6 → 56,191.6"
sed -i.tmp 's/56,191\.656,191\.6/56,191.6/g' chapters/ch4.tex

# 2. 附录C错别字
echo "  - 修复 拒绝(3项显着) → 拒绝（3项显著）"
sed -i.tmp 's/拒绝(3项显着)/拒绝（3项显著）/g' chapters/appendix.tex

echo "  - 修复 不拒绝(全族(0) → 不拒绝（全族拒绝数0）"
sed -i.tmp 's/不拒绝(全族(0)/不拒绝（全族拒绝数0）/g' chapters/appendix.tex

echo "  - 修复 误报警象 → 误报迹象"
sed -i.tmp 's/误报警象/误报迹象/g' chapters/appendix.tex

echo "  - 修复 可变时廷 → 可变时延"
sed -i.tmp 's/可变时廷/可变时延/g' chapters/appendix.tex

echo "  - 修复 存在)项 → 存在0项"
sed -i.tmp 's/存在)项/存在0项/g' chapters/appendix.tex

# 3. 节号缺小数点（第40节 → 第4.0节）
echo "  - 修复节号格式（第4X节 → 第4.X节）"
for i in 0 1 2 3 4 5 6 7 8 9; do
  sed -i.tmp "s/第4${i}节/第4.${i}节/g" chapters/appendix.tex
done

# 清理临时文件
rm -f chapters/*.tmp

echo ""
echo "========================================="
echo "  笔误修复完成！"
echo "========================================="
echo ""
echo "已修复的笔误："
echo "  1. 表4.7 数据重复"
echo "  2. 附录C 6处错别字"
echo "  3. 节号格式统一"
echo ""
echo "如需恢复，运行："
echo "  cp $BACKUP_DIR.ch4.tex chapters/ch4.tex"
echo "  cp $BACKUP_DIR.appendix.tex chapters/appendix.tex"
echo ""
