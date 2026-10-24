#!/bin/bash
# 应用第三章修改脚本

echo "开始修订第三章..."

# 由于ch3.tex中的内容已经大部分正确，我们重点检查PDF是否有OCR错误
# 根据修改建议，主要需要修正的是PDF中的OCR错误，而非LaTeX源文件

# 检查ch3.tex是否有需要修改的内容
echo "检查ch3.tex中可能的错误..."

# 1. 检查"划分检套"（应为"划分检验"）
if grep -q "划分检套" chapters/ch3.tex; then
    echo "发现：划分检套"
    sed -i.bak 's/划分检套/划分检验/g' chapters/ch3.tex
fi

# 2. 检查"清息"（应为"消息"）
if grep -q "清息" chapters/ch3.tex; then
    echo "发现：清息"
    sed -i.bak 's/清息/消息/g' chapters/ch3.tex
fi

# 3. 检查"吞被息攻"（应为"遭受攻击"）
if grep -q "吞被息攻" chapters/ch3.tex; then
    echo "发现：吞被息攻"
    sed -i.bak 's/吞被息攻/遭受攻击/g' chapters/ch3.tex
fi

# 4. 检查"方差因定"（应为"方差固定"）
if grep -q "方差因定" chapters/ch3.tex; then
    echo "发现：方差因定"
    sed -i.bak 's/方差因定/方差固定/g' chapters/ch3.tex
fi

# 5. 检查"家族成页"（应为"家族成员"）
if grep -q "家族成页" chapters/ch3.tex; then
    echo "发现：家族成页"
    sed -i.bak 's/家族成页/家族成员/g' chapters/ch3.tex
fi

# 编译检查
echo "编译检查..."
cd /Users/yin/code/cryProject/report
latexmk -xelatex -interaction=nonstopmode main.tex 2>&1 | tail -20

echo "第三章修订完成"
