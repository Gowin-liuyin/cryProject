#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""把离线展示 HTML 渲染成真实浏览器截图。

用途：为人工签收材料提供离线展示页面的屏幕图。截图用本机 Chrome 的无头模式渲染，
得到的是真实浏览器渲染结果，不是图片拼贴。

口径：
  * 截图前先扫描页面里的私有身份串（本地用户路径、远端主机名与 IP 等）；
    命中就直接失败——匿名包与展示页都不应带这些串。
  * 只截首屏（窗口尺寸由参数给出），不做整页长图，避免一张图放不下正文。

用法：
  python3 tools/render_offline_html_shot.py --html <index.html> --output <PNG> [--width 1500] [--height 1100]
"""

import argparse
import re
import subprocess
import sys
from pathlib import Path

REPOSITORY = Path(__file__).resolve().parents[1]
CHROME = Path("/Applications/Google Chrome.app/Contents/MacOS/Google Chrome")

PRIVATE_MARKERS = [
    "/Users/", "/home/nss-marker", "/home/ubuntu", "10.144.144.", "119.45.121.",
    "yinhaoran0808@outlook.com", "Gowin-liuyin", "yindeMacBook-Air.local",
]


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--html", required=True)
    parser.add_argument("--output", required=True)
    parser.add_argument("--width", type=int, default=1500)
    parser.add_argument("--height", type=int, default=1100)
    arguments = parser.parse_args()

    if not CHROME.is_file():
        raise SystemExit("未找到本机 Chrome：" + str(CHROME))

    html_path = Path(arguments.html).resolve()
    if not html_path.is_file():
        raise SystemExit("缺少 HTML：" + str(html_path))
    content = html_path.read_text(encoding="utf-8", errors="replace")
    hits = [marker for marker in PRIVATE_MARKERS if marker in content]
    if hits:
        raise SystemExit("页面里出现私有身份串，拒绝截图：" + "、".join(hits))

    output_path = Path(arguments.output).resolve()
    output_path.parent.mkdir(parents=True, exist_ok=True)
    subprocess.run([
        str(CHROME), "--headless", "--disable-gpu", "--no-sandbox", "--hide-scrollbars",
        "--force-device-scale-factor=2",
        "--screenshot=" + str(output_path),
        "--window-size=%d,%d" % (arguments.width, arguments.height),
        html_path.as_uri(),
    ], check=True, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    print("已生成 " + str(output_path) + "（来源 " + str(html_path) + "）")
    return 0


if __name__ == "__main__":
    sys.exit(main())
