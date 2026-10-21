#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""把真实终端输出渲染成终端风格的 PNG 截图。

用途：为人工签收材料提供「真实运行输出」的屏幕图。输入是**实际运行产生的日志文件**
（不生成、不改写日志内容），输出是按终端外观渲染的 PNG。

口径：
  * 文本先过一遍与匿名支撑包相同的身份替换规则（见 build_support.py 的 anonymous_text），
    避免截图把本机用户名、远端项目根目录等私有路径带进提交材料；替换规则逐条写进 SCREENSHOTS.md。
  * 除身份替换外，日志正文逐字保留，不裁剪、不美化、不补行。
  * 渲染用本机 Chrome 的无头模式截图，得到的是真实浏览器渲染结果。

用法：
  python3 tools/render_terminal_shot.py --input <日志> --output <PNG> \
      --title "<标题>" [--command "<命令>" ] [--max-lines N] [--width 1500]
"""

import argparse
import html
import re
import subprocess
import sys
from pathlib import Path

REPOSITORY = Path(__file__).resolve().parents[1]
SUPPORT_DIRECTORY = REPOSITORY / "deliverables/support/CACR2026EA16XZ-multi-leakage-platform-20261016"
CHROME = Path("/Applications/Google Chrome.app/Contents/MacOS/Google Chrome")

IDENTITY_REPLACEMENTS = [
    (str(REPOSITORY), "[REPOSITORY]"),
    ("/Users/yin", "[LOCAL_USER]"),
    ("/home/nss-marker/yhr/Cry", "[REMOTE_PROJECT]"),
    ("/home/nss-marker", "[REMOTE_USER]"),
    ("10.144.144.5", "[REMOTE_IP]"),
    ("10.144.144.3", "[REMOTE_IP]"),
    ("119.45.121.134", "[HISTORICAL_IP]"),
    ("yinhaoran0808@outlook.com", "[AUTHOR_EMAIL]"),
    ("Gowin-liuyin", "[PROJECT_AUTHOR]"),
    ("yindeMacBook-Air.local", "[LOCAL_HOST]"),
    ("nss-marker", "[REMOTE_USER]"),
    ("nss-m", "[LINUX_HOST]"),
]


def anonymize(text):
    """与匿名支撑包一致的身份替换；其余字符原样保留。"""
    for original, replacement in IDENTITY_REPLACEMENTS:
        text = text.replace(original, replacement)
    return re.sub(r"/(?:Users|home)/[A-Za-z0-9_.-]+", "[ANONYMOUS_HOME]", text)


def build_html(title, command, body_text):
    command_line = "" if not command else (
        '<div class="command"><span class="prompt">$</span> ' + html.escape(command) + "</div>")
    return (
        '<!doctype html><html lang="zh-CN"><head><meta charset="utf-8">'
        '<style>'
        'body{margin:0;background:#0b0f14;font:15px/1.55 "SF Mono",Menlo,Consolas,"Noto Sans Mono CJK SC",monospace;'
        'color:#d7dde5;padding:0}'
        '.window{margin:22px;border:1px solid #2b3440;border-radius:9px;overflow:hidden;background:#11161d}'
        '.titlebar{background:#1b222b;padding:9px 15px;font-size:13.5px;color:#9fb0c3;'
        'border-bottom:1px solid #2b3440;display:flex;gap:8px;align-items:center}'
        '.dot{width:11px;height:11px;border-radius:50%;display:inline-block}'
        '.titletext{margin-left:8px}'
        '.command{padding:11px 16px;background:#0e141a;color:#8fd18b;border-bottom:1px solid #222b35}'
        '.prompt{color:#6ec27a;font-weight:bold}'
        'pre{margin:0;padding:15px 17px;white-space:pre-wrap;overflow-wrap:anywhere;color:#d7dde5}'
        '.caption{padding:9px 17px;border-top:1px solid #222b35;background:#0e141a;color:#8b98a8;font-size:13px}'
        '</style></head><body><div class="window">'
        '<div class="titlebar"><span class="dot" style="background:#ff5f57"></span>'
        '<span class="dot" style="background:#febc2e"></span><span class="dot" style="background:#28c840"></span>'
        '<span class="titletext">' + html.escape(title) + "</span></div>"
        + command_line +
        "<pre>" + html.escape(body_text) + "</pre>"
        '<div class="caption">本图为真实运行输出的终端渲染：正文取自实际日志文件，仅按匿名包的同一套身份替换规则改写路径与主机名，其余逐字未改。</div>'
        "</div></body></html>"
    )


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--input", required=True)
    parser.add_argument("--output", required=True)
    parser.add_argument("--title", required=True)
    parser.add_argument("--command", default="")
    parser.add_argument("--max-lines", type=int, default=0)
    parser.add_argument("--tail", type=int, default=0)
    parser.add_argument("--width", type=int, default=1500)
    arguments = parser.parse_args()

    if not CHROME.is_file():
        raise SystemExit("未找到本机 Chrome：" + str(CHROME))

    source_path = Path(arguments.input)
    lines = source_path.read_text(encoding="utf-8", errors="replace").splitlines()
    total_lines = len(lines)
    if arguments.tail > 0 and total_lines > arguments.tail:
        lines = lines[-arguments.tail:]
        lines.insert(0, "...（本图只显示日志末尾 %d 行，完整日志共 %d 行，路径：%s）"
                     % (arguments.tail, total_lines, source_path))
    if arguments.max_lines > 0 and len(lines) > arguments.max_lines:
        lines = lines[:arguments.max_lines]
        lines.append("...（本图只显示前 %d 行，完整日志共 %d 行，路径：%s）"
                     % (arguments.max_lines, total_lines, source_path))
    body_text = anonymize("\n".join(lines))

    output_path = Path(arguments.output)
    output_path.parent.mkdir(parents=True, exist_ok=True)
    # 中间 HTML 放在 build/ 下，不留在产物目录里。
    intermediate_directory = REPOSITORY / "build/render-terminal-shot"
    intermediate_directory.mkdir(parents=True, exist_ok=True)
    html_path = intermediate_directory / (output_path.stem + ".html")
    html_path.write_text(build_html(arguments.title, arguments.command, body_text), encoding="utf-8")

    height = max(320, 340 + 24 * (body_text.count("\n") + 1))
    subprocess.run([
        str(CHROME), "--headless", "--disable-gpu", "--no-sandbox", "--hide-scrollbars",
        "--force-device-scale-factor=2",
        "--screenshot=" + str(output_path),
        "--window-size=%d,%d" % (arguments.width, height),
        "--default-background-color=0b0f14",
        html_path.resolve().as_uri(),
    ], check=True, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)

    print("已生成 %s（源日志 %d 行，渲染 %d 行）" % (output_path, total_lines, body_text.count("\n") + 1))
    return 0


if __name__ == "__main__":
    sys.exit(main())
