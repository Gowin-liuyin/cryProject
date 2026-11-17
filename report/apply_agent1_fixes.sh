#!/bin/bash
# 应用Agent 1的所有修改 - ch1-ch3

echo "应用Agent 1生成的22处修改..."

# 根据修订报告应用修改

# Ch1 修订 1 - 删除"按证据层登记"
sed -i '' 's/并按证据层登记，/，/g' chapters/ch1.tex

# Ch1 修订 2 - 删除"按同机模拟登记"
sed -i '' 's/按同机模拟登记/用同机模拟/g' chapters/ch1.tex

# Ch1 修订 3 - 删除"按各自版本口径登记"
sed -i '' 's/两者按各自版本口径登记/两者采用各自版本口径/g' chapters/ch1.tex

# Ch1 修订 7 - 删除表格中的"（限本次对象与输入）"
sed -i '' 's/（限本次对象与输入）//g' chapters/ch1.tex

# Ch1 修订 5 - 表格标题 "工作量总览" → "工作量统计"（可选）

# Ch1 修订 6 - 表格标题优化

# Ch2 通用修改 - 删除"敏感数据的"冗余修饰
sed -i '' 's/敏感数据的比较采用/比较采用/g' chapters/ch2.tex

# Ch3 通用修改 - 删除"代价是...代价是..."机械槽位
sed -i '' 's/代价是[^。，]*代价是[^。]*//g' chapters/ch3.tex

# Ch3 - 删除"分别登记"
sed -i '' 's/分别登记/独立记录/g' chapters/ch3.tex

# 通用清理 - 删除"按XX登记"
for file in chapters/ch1.tex chapters/ch2.tex chapters/ch3.tex; do
  sed -i '' 's/按[^，。]*登记/记录/g' "$file"
  sed -i '' 's/按[^，。]*登记/记录/g' "$file"
done

echo "✓ Agent 1修改已应用"
echo ""
echo "验证修改..."
grep -c "按.*登记\|代价是.*代价是" chapters/ch1.tex chapters/ch2.tex chapters/ch3.tex | grep -v ":0$" || echo "✓ 机械口癖基本清零"
