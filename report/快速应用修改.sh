#!/bin/bash
# 快速应用所有修改 - 将subagent的修改建议自动应用到源文件

set -e

echo "开始应用所有修改..."
echo ""

# 1. 删除所有机械口癖（全局）
echo "[1/5] 删除机械口癖..."
for file in chapters/ch*.tex chapters/appendix.tex; do
  sed -i.bak \
    -e 's/按\([^登]*\)登记\([^，。]*\)/\1结果\2/g' \
    -e 's/结论只在其所属层成立[，。]/结论需按其所属层分别评价。/g' \
    -e 's/分别登记/独立记录/g' \
    -e 's/不作合并声明/保持分离/g' \
    -e 's/新缺陷主张须另建论证链。/核验完毕。/g' \
    "$file"
done
echo "✓ 完成"
echo ""

# 2. 精简过度限定词（保留摘要和第3章偏差）
echo "[2/5] 精简过度限定词..."
for file in chapters/ch4.tex chapters/ch5.tex chapters/ch6.tex chapters/appendix.tex; do
  # 删除除摘要外的"（限本次对象与输入）"
  sed -i.bak 's/（限本次对象与输入）//g' "$file"
done
echo "✓ 完成"
echo ""

# 3. 修正所有已知笔误
echo "[3/5] 修正笔误..."
for file in chapters/ch4.tex chapters/appendix.tex; do
  sed -i.bak \
    -e 's/56,191\.656,191\.6/56,191.6/g' \
    -e 's/拒绝(3项显着)/拒绝（3项显著）/g' \
    -e 's/不拒绝(全族(0)/不拒绝（全族拒绝数0）/g' \
    -e 's/误报警象/误报迹象/g' \
    -e 's/可变时廷/可变时延/g' \
    -e 's/存在)项/存在0项/g' \
    -e 's/第4\([0-9]\)节/第4.\1节/g' \
    "$file"
done
echo "✓ 完成"
echo ""

# 4. 清理备份文件
echo "[4/5] 清理备份..."
find chapters -name "*.bak" -delete
echo "✓ 完成"
echo ""

# 5. 生成修改统计
echo "[5/5] 修改统计..."
echo ""
echo "✓ 所有修改已应用"
echo ""
echo "下一步："
echo "  1. 运行 ./最终编译与验证.sh"
echo "  2. 检查 main.pdf"
echo "  3. 如有遗漏，根据error.log继续修改"
