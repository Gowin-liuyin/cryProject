"""把矩阵 SVG 渲染为 2 倍预览 PNG。

本机 Chrome headless 截图在此环境不可用（只打印 GCM 错误，不产出文件），因此改用
macOS QuickLook（WebKit）渲染：QuickLook 的输出被裁成正方形，所以先在高斯方画布中
嵌入原 SVG（左上角对齐），再按 2 倍比例裁回真实尺寸。渲染器与比例记录在 RENDER_ENV.json。
"""
import shutil
import subprocess
from pathlib import Path

from PIL import Image

figure_directory = Path(__file__).resolve().parent
build_directory = figure_directory.parents[3] / "build/platform-report-s8/figure-preview-20261016"
svg_path = figure_directory / "platform-evidence-matrix.svg"
png_path = figure_directory / "platform-evidence-matrix.png"

svg_text = svg_path.read_text()
assert svg_text.startswith("<svg "), "unexpected SVG header"
width = int(svg_text.split('width="', 1)[1].split('"', 1)[0])
height = int(svg_text.split('height="', 1)[1].split('"', 1)[0])
inner = svg_text.split(">", 1)[1].rsplit("</svg>", 1)[0]
side = max(width, height)
wrapper = (
    f'<svg xmlns="http://www.w3.org/2000/svg" width="{side}" height="{side}" '
    f'viewBox="0 0 {side} {side}"><rect width="100%" height="100%" fill="#ffffff"/>'
    + inner
    + "</svg>"
)
build_directory.mkdir(parents=True, exist_ok=True)
wrapper_path = build_directory / "square-wrapper.svg"
wrapper_path.write_text(wrapper)
if not shutil.which("qlmanage"):
    raise SystemExit("qlmanage not available; cannot rasterize SVG preview")
subprocess.run(["qlmanage", "-t", "-s", str(side * 2), "-o", str(build_directory), str(wrapper_path)], check=True, capture_output=True)
rendered_path = build_directory / (wrapper_path.name + ".png")
image = Image.open(rendered_path).convert("RGB")
if image.size != (side * 2, side * 2):
    raise SystemExit(f"unexpected QuickLook output size {image.size}")
image.crop((0, 0, width * 2, height * 2)).save(png_path)
print(f"preview={png_path.name} {width * 2}x{height * 2} source_svg={width}x{height}")
