#!/bin/bash
# 应用关键修复 - 针对最严重的问题

echo "应用关键修复..."

# 备份
cp -r chapters chapters.backup.$(date +%s)

# 1. 替换"结论只在其所属层成立" → 删除或改为自然表达
for file in chapters/ch*.tex; do
  sed -i '' 's/结论只在其所属层成立。/各层结论按其自身口径评价。/g' "$file"
  sed -i '' 's/，结论只在其所属层成立。/。/g' "$file"
done

# 2. 替换"按产物/按层/按预算登记" → 自然表达
for file in chapters/ch*.tex; do
  sed -i '' 's/按产物、按层、按预算登记/逐层、逐产物、按预算记录/g' "$file"
  sed -i '' 's/按环境分别登记/按环境独立记录/g' "$file"
  sed -i '' 's/按各自版本口径登记/按各自版本记录/g' "$file"
done

# 3. 替换"分别登记" → 删除或改为"独立"
for file in chapters/ch*.tex; do
  sed -i '' 's/分别登记/独立记录/g' "$file"
  sed -i '' 's/分别使用/各自使用/g' "$file"
done

echo "关键修复完成"
