#!/bin/bash
# 批量清理"登记"和"结论只在"问题

echo "批量清理最常见问题..."

for file in chapters/ch*.tex chapters/appendix.tex; do
  # 删除或改写"结论只在..."
  sed -i '' 's/结论只在给定样本量、方差与检验水平下成立/阴性结果仅在给定条件下成立/g' "$file"
  sed -i '' 's/结论只在自身角色范围内成立/各角色结论独立评价/g' "$file"
  sed -i '' 's/结论只在其所属层成立/分层结论各自有效/g' "$file"
  
  # 改写"登记"（最常见的问题）
  sed -i '' 's/逐项登记/逐项记录/g' "$file"
  sed -i '' 's/均按.*登记/均已记录/g' "$file"
  sed -i '' 's/按机制观察登记/按机制观察记录/g' "$file"
  sed -i '' 's/按其所属层登记/按所属层记录/g' "$file"
  
  # 删除"不作合并声明"
  sed -i '' 's/，不作合并声明//g' "$file"
  sed -i '' 's/跨环境结论不作合并声明//g' "$file"
done

echo "✓ 批量清理完成"

# 统计剩余问题
echo ""
echo "剩余问题统计："
echo "剩余'结论只在':"
grep -r "结论只在" chapters/*.tex 2>/dev/null | wc -l
echo "剩余'登记'词汇:"
grep -r "登记" chapters/*.tex 2>/dev/null | wc -l
echo "剩余'分别登记':"
grep -r "分别登记" chapters/*.tex 2>/dev/null | wc -l
