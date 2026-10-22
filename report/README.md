# 作品设计报告 LaTeX 模板

按 2026 年第十一届全国密码技术竞赛官方 Word 模板（附件二）复刻的 LaTeX 模板，用于 A1-13 复赛作品设计报告。

## 编译

```bash
latexmk -xelatex main.tex
```

只需要 XeLaTeX；最终成品是根目录的 `main.pdf`，中间产物已忽略，不提交。

## 字体

模板严格使用官方模板指定的字体，不自动替换；缺任一字体时编译直接报错。

| 用途 | 字体 |
| --- | --- |
| 正文 | 楷体_GB2312 四号 |
| 一级标题 | 华文楷体 小三 |
| 二级标题 | 黑体 四号 |
| 页眉、基本信息表 | 宋体 |
| 封面作品题目 | 华文中宋 |
| 西文、页码 | Times New Roman |

楷体_GB2312 未安装但手头有字体文件时，把字体文件放到 `report/assets/`，在 `main.tex` 的导言区取消这一行注释：

```latex
\reportbodyfont{assets/KaiTi_GB2312.ttf}
```

也可以直接把字体名传给 `\reportbodyfont{KaiTi_GB2312}`。其余字体需安装后再编译。

## 版式要点

- A4 纸，上下左右页边距 2 cm。
- 页眉为“全国密码技术竞赛作品设计报告”，9 pt 居中，下加 0.75 pt 横线；封面不显示页眉和页码，从基本信息表页起显示，页码在该页重新从 1 开始。
- 一级标题华文楷体小三加粗，二级标题黑体四号加粗，段前段后各 12 pt、1.5 倍行距。
- 最多只用到二级标题；误用 `\subsubsection` 会直接编译报错。
- 正文楷体四号、固定 24 pt 行距、首行缩进 2 字符。

## 填写

在 `main.tex` 顶部填写编号、题目与日期；摘要和关键词在 `chapters/abstract.tex`；正文按章放在 `chapters/ch1.tex`–`ch6.tex`，附录在 `chapters/appendix.tex`。封面“注意”段和文末的标题说明段在正式提交前删除。

- 封面徽标在 `assets/cacr_logo.jpg`，取自官方模板；如需换路径用 `\reportlogo{...}`。
- 修改版式时改 `a113_report.cls`；正文内容放在 `chapters/`，`main.tex` 只负责合稿、封面信息与文献表。
