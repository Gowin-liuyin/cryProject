% a113_report.cls — 2026年第十一届全国密码技术竞赛作品设计报告模板
% 版式照官方 Word 模板（附件二）复刻：
% A4 纸、四边 2cm 页边距；页眉“全国密码技术竞赛作品设计报告”9pt 居中，下加 0.75pt 线；
% 封面无页眉和页码，基本信息表页起页码为 1；
% 一级标题华文楷体小三，二级标题黑体四号，最多只用到二级标题。
\NeedsTeXFormat{LaTeX2e}
\ProvidesClass{a113_report}[2026/10/21 A1-13 competition report template]

\LoadClass[a4paper,zihao=-4,fontset=none]{ctexart}

\RequirePackage[a4paper,top=2cm,bottom=2cm,left=2cm,right=2cm,
  headheight=12pt,headsep=3pt,footskip=0.6cm]{geometry}
\RequirePackage{graphicx}
\RequirePackage{array}
\RequirePackage{tabularx}
\RequirePackage{amsmath}
\RequirePackage{amssymb}
\RequirePackage{fancyhdr}
\RequirePackage[hidelinks,hypertexnames=false]{hyperref}

% 正文严格使用楷体_GB2312 四号，缺字体时中止编译，不自动替换。
% 字体未安装但手头有字体文件时，可在导言区用
% \reportbodyfont{assets/KaiTi_GB2312.ttf} 指定。
\setmainfont{Times New Roman}
\newif\ifaiv@bodyfontset
\newcommand{\reportbodyfont}[1]{%
  \setCJKmainfont[AutoFakeBold=2]{#1}%
  \aiv@bodyfontsettrue
}
\IfFontExistsTF{KaiTi_GB2312}{%
  \setCJKmainfont[AutoFakeBold=2]{KaiTi_GB2312}%
  \aiv@bodyfontsettrue
}{%
  \AtBeginDocument{%
    \ifaiv@bodyfontset\else
      \PackageError{a113_report}{未找到楷体_GB2312 字体，正文要求严格使用该字体}%
        {请安装楷体_GB2312（字体名 KaiTi_GB2312），或在导言区用 \string\reportbodyfont 指向字体文件，例如 \string\reportbodyfont{assets/KaiTi_GB2312.ttf}}%
    \fi
  }%
}

% 标题与特殊段落字体严格照模板：华文楷体、黑体、宋体、华文中宋，缺字即报错。
\IfFontExistsTF{STKaiti}{%
  \setCJKfamilyfont{zhhwkt}[AutoFakeBold=2]{STKaiti}%
  \newfontfamily\headingonefont{STKaiti}[AutoFakeBold=2]%
}{%
  \PackageError{a113_report}{未找到华文楷体（STKaiti），一级标题要求严格使用该字体}{请安装华文楷体后重新编译}%
}
\IfFontExistsTF{SimHei}{%
  \setCJKfamilyfont{zhhei}[AutoFakeBold=2]{SimHei}%
}{%
  \PackageError{a113_report}{未找到黑体（SimHei），二级标题要求严格使用该字体}{请安装黑体后重新编译}%
}
\IfFontExistsTF{SimSun}{%
  \setCJKfamilyfont{zhsong}[AutoFakeBold=2]{SimSun}%
}{%
  \PackageError{a113_report}{未找到宋体（SimSun），页眉和基本信息表要求严格使用该字体}{请安装宋体后重新编译}%
}
\IfFontExistsTF{STZhongsong}{%
  \setCJKfamilyfont{zhhwzs}{STZhongsong}%
}{%
  \PackageError{a113_report}{未找到华文中宋（STZhongsong），封面作品题目要求严格使用该字体}{请安装华文中宋后重新编译}%
}

\newcommand{\reportfontkai}{\CJKfamily{zhhwkt}}
\newcommand{\reportfonthei}{\CJKfamily{zhhei}}
\newcommand{\reportfontsong}{\CJKfamily{zhsong}}
\newcommand{\reportfontzhongsong}{\CJKfamily{zhhwzs}}

% 楷体四号按模板固定 24pt 行距（14pt × 1.2 × 1.42857 ≈ 24pt）。
\linespread{1.42857}

\ctexset{
  section = {
    format = {\centering\reportfontkai\headingonefont\bfseries\fontsize{15pt}{22.5pt}\selectfont},
    name = {,},
    number = 第\chinese{section}章,
    aftername = {\quad},
    beforeskip = 12pt,
    afterskip = 12pt,
  },
  subsection = {
    format = {\reportfonthei\bfseries\fontsize{14pt}{21pt}\selectfont},
    name = {,},
    number = \arabic{section}.\arabic{subsection},
    aftername = {\ },
    beforeskip = 12pt,
    afterskip = 12pt,
  },
}
\setcounter{secnumdepth}{2}

% 图表按章编号：图 1.1、表 1.1，每章重新计数。
\counterwithin{figure}{section}
\counterwithin{table}{section}
% 图表编号仍用阿拉伯数字的章号，不随“第一章”的中文标题变化。
\renewcommand{\thetable}{\arabic{section}.\arabic{table}}
\renewcommand{\thefigure}{\arabic{section}.\arabic{figure}}

% 模板规定最多到二级标题，误用三级标题时直接报错。
\AtBeginDocument{%
  \renewcommand{\subsubsection}[2][]{%
    \PackageError{a113_report}{本模板最多使用到二级标题}{请改用 \string\section 或 \string\subsection}%
  }%
}

% 图表题注使用全角空格分隔，避免“图 2.1: 标题：副标题”双冒号
\long\def\@makecaption#1#2{%
  \vskip\abovecaptionskip
  \sbox\@tempboxa{#1\quad #2}%
  \ifdim \wd\@tempboxa >\hsize
    #1\quad #2\par
  \else
    \global \@minipagefalse
    \hb@xt@\hsize{\hfil\box\@tempboxa\hfil}%
  \fi
  \vskip\belowcaptionskip}

% 页眉与页脚：页眉宋体 9pt 居中带下框线，页脚居中页码。
\fancypagestyle{a113report}{%
  \fancyhf{}%
  \fancyhead[C]{\reportfontsong\fontsize{9pt}{11pt}\selectfont 全国密码技术竞赛作品设计报告}%
  \fancyfoot[C]{\fontsize{9pt}{11pt}\selectfont\thepage}%
  \renewcommand{\headrulewidth}{0.75pt}%
  \renewcommand{\footrulewidth}{0pt}%
}
\pagestyle{a113report}

% 封面与基本信息表元数据。
\def\aiv@reportid{（必须填写系统自动分配的编号）}
\def\aiv@reporttitle{（在此填写作品题目）}
\def\aiv@reportcovertitle{\aiv@reporttitle}
\def\aiv@reportdate{年\quad 月\quad 日}
\def\aiv@abstract{}
\def\aiv@keywords{}
\def\aiv@logopath{assets/cacr_logo.jpg}

\newcommand{\reportid}[1]{\def\aiv@reportid{#1}}
\newcommand{\reporttitle}[1]{\def\aiv@reporttitle{#1}}
\newcommand{\reportcovertitle}[1]{\def\aiv@reportcovertitle{#1}}
\newcommand{\reportdate}[1]{\def\aiv@reportdate{#1}}
\newcommand{\reportabstract}[1]{\def\aiv@abstract{#1}}
\newcommand{\reportkeywords}[1]{\def\aiv@keywords{#1}}
\newcommand{\reportlogo}[1]{\def\aiv@logopath{#1}}

\newcommand{\makecover}{%
  \begin{titlepage}%
    \thispagestyle{empty}%
    \setlength{\parindent}{0pt}%
    \noindent
    \begin{minipage}[t]{0.60\textwidth}
      \vspace{0pt}%
      {\bfseries\fontsize{14pt}{24pt}\selectfont
       作品编号：\aiv@reportid\par}
    \end{minipage}\hfill
    \begin{minipage}[t]{4.26cm}
      \vspace{0pt}%
      \includegraphics[width=4.26cm]{\aiv@logopath}%
    \end{minipage}\par
    \vspace{0.5cm}
    {\reportfontsong\fontsize{14pt}{24pt}\selectfont
     作品类别：□软件设计\quad □硬件制作\quad ■工程实践\par
     \hspace*{7em}□密码应用技术\quad □其它\par}
    \vspace{2.8cm}
    {\centering
     \bfseries\fontsize{18pt}{24pt}\selectfont
     2026年第十一届全国密码技术竞赛作品设计报告\par}
    \vspace{0.55cm}
    \noindent\hspace*{1.5cm}\rule{13.6cm}{3pt}\par
    \vspace{1.9cm}
    {\reportfontzhongsong\fontsize{14pt}{24pt}\selectfont
     \hspace*{6em}作品题目：\parbox[t]{10.4cm}{\raggedright\aiv@reportcovertitle}\par}
    \vspace{1.5cm}
    {\centering
     \fontsize{14pt}{30pt}\selectfont
     \aiv@reportdate\par
     中国密码学会\par}
  \end{titlepage}%
}

\newcommand{\makeinfotable}{%
  \pagenumbering{arabic}%
  \thispagestyle{a113report}%
  \begin{center}
    \renewcommand{\arraystretch}{1.0}%
    \begin{tabularx}{15.72cm}{|X|}
      \hline
      \centering{\reportfontsong\fontsize{15pt}{20pt}\selectfont 基本信息表}\arraybackslash\\
      \hline
      \rule{0pt}{1.0cm}{\reportfontsong\fontsize{15pt}{22pt}\selectfont 编号：\aiv@reportid}\\
      \hline
      \rule{0pt}{1.0cm}{\reportfontsong\fontsize{15pt}{22pt}\selectfont
        作品题目：\parbox[t]{11.7cm}{\aiv@reportcovertitle}}\\
      \hline
      \rule{0pt}{0.9cm}{\reportfontsong\fontsize{12pt}{18pt}\selectfont
        作品类别：□软件设计\quad □硬件制作\quad ■工程实践\quad □密码应用技术\quad □其它}\\
      \hline
      {\reportfontsong\fontsize{15pt}{22pt}\selectfont 作品内容摘要：}
      \par\vspace{0.1cm}
      % 定稿摘要约 23 行，留一行余量后固定高度取 13.2cm。
      \parbox[t][13.2cm][t]{\linewidth}{%
        \reportfontsong\fontsize{12pt}{15pt}\selectfont
        \setlength{\parindent}{2em}%
        \aiv@abstract}\\
      \hline
      \rule{0pt}{1.0cm}{\reportfontsong\fontsize{15pt}{22pt}\selectfont
        关键词（五个）：\aiv@keywords}\\
      \hline
    \end{tabularx}
  \end{center}
  \newpage
}

\endinput
