import csv
from fractions import Fraction
import json
from pathlib import Path

import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt

repository = Path(__file__).resolve().parents[4]
inputs = repository / 'docs/evidence/frequency-window-20261010/run-0ba4cd7/analysis'
outputs = Path(__file__).resolve().parent
summary = json.loads((inputs / 'normal-summary.json').read_text())
with (inputs / 'normal-windows.csv').open() as source:
    rows = list(csv.DictReader(source))
primary = [row for row in rows if row['role'] == 'primary']
assert len(primary) == summary['observed_main_pairs']
assert all(row['cpu_index'] == '2' for row in primary)
assert sum(row['straddles_main_start'] == 'true' for row in primary) == 1
assert len(rows) == 2 * len(primary)

plt.rcParams.update({'font.family': ['Songti SC', 'DejaVu Serif'], 'font.size': 10,
                     'axes.labelsize': 10, 'xtick.labelsize': 9, 'ytick.labelsize': 9,
                     'axes.spines.top': False, 'axes.spines.right': False,
                     'axes.unicode_minus': False, 'pdf.fonttype': 42, 'ps.fonttype': 42,
                     'savefig.dpi': 300})
figure, axes = plt.subplots(2, 1, figsize=(7.0, 4.6),
                            gridspec_kw={'height_ratios': [4, 1.2], 'hspace': 0.62})
frequency_axis, coverage_axis = axes
frequency_axis.axhspan(4257, 4343, color='0.94', label='事前工程带 ±1%')
for threshold in (4257, 4343):
    frequency_axis.axhline(threshold, color='0.55', linestyle='--', linewidth=0.65)
frequency_axis.axhline(4300, color='0.35', linestyle=':', linewidth=0.8)
for row_index, row in enumerate(primary):
    position = int(row['window_index']) + 1
    low = float(row['frequency_low_mhz_display'])
    high = float(row['frequency_high_mhz_display'])
    midpoint = (low + high) / 2
    boundary = row['straddles_main_start'] == 'true'
    color = '#a86400' if boundary else '#176496'
    frequency_axis.vlines(position, low, high, color=color, linewidth=0.9)
    frequency_axis.plot(position, midpoint, marker='D' if boundary else '.',
                        markersize=4.5 if boundary else 2.2, markerfacecolor='none' if boundary else color,
                        markeredgecolor=color, linestyle='none',
                        label='首个跨界窗口' if boundary else ('纯主阶段窗口' if row_index == 1 else None))
frequency_axis.set(xlim=(-2, 203), ylim=(4252, 4348), xlabel='主观察窗口序号',
                   ylabel='读取对齐区间（MHz 标尺）')
frequency_axis.set_yticks([4257, 4300, 4343])
frequency_axis.legend(loc='lower center', ncol=3, frameon=False, fontsize=9)
frequency_axis.text(-0.07, 1.02, '(a)', transform=frequency_axis.transAxes, fontsize=10)

numerator = int(summary['pure_main_coverage_fraction']['numerator_ns'])
denominator = int(summary['pure_main_coverage_fraction']['denominator_ns'])
covered_percent = float(100 * Fraction(numerator, denominator))
uncovered_percent = 100 - covered_percent
coverage_axis.barh(0, covered_percent, color='#176496', height=0.55,
                   label='纯主阶段平均窗口的几何覆盖')
coverage_axis.barh(0, uncovered_percent, left=covered_percent, color='0.8',
                   hatch='////', edgecolor='0.35', linewidth=0.6, height=0.55, label='其余缺口')
coverage_axis.text(covered_percent / 2, 0, f'几何覆盖 {covered_percent:.4f}%',
                   ha='center', va='center', color='white', fontsize=10)
coverage_axis.set(xlim=(0, 100), ylim=(-0.45, 0.45), xlabel='主观察墙钟占比（%）')
coverage_axis.set_yticks([])
coverage_axis.set_xticks([0, 25, 50, 75, 100])
coverage_axis.text(-0.07, 1.06, '(b)', transform=coverage_axis.transAxes, fontsize=10)
figure.subplots_adjust(left=0.13, right=0.98, bottom=0.13, top=0.93)
figure.savefig(outputs / 'fig-g2-window-qualification.pdf', metadata={'Title': 'G2 reference window qualification', 'Author': ''})
figure.savefig(outputs / 'fig-g2-window-qualification.png')
plt.close(figure)
caption = (
    f'图G2-1：一次普通reference进程的窗口工程观察。(a) 保留全部{len(primary)}个CPU2主观察pair，'
    '均落入事前4257—4343MHz工程带；点为区间中心，极窄竖线为读取对齐边界。空心标记为首个跨界窗口，仍参加判定。'
    f'(b) 纯主阶段平均窗口的几何覆盖为{numerator}/{denominator}ns，显示为{covered_percent:.4f}%，'
    '首个跨界pair不计入该分子。缺口包含边界、末帧及内部读取括号；此条为合计比例，不是时间线。'
    '读取对齐区间不是置信区间或完整物理误差界，几何覆盖不认证区间内逐时或每次调用恒频。'
    f'{len(primary)}窗来自一个进程，不能视为{len(primary)}个独立重复。CPU18为context_only，不充作第二独立样本；'
    'full_main_coverage_certified、physical_precision、R02/R04均未签收。\n'
)
(outputs / 'fig-g2-window-qualification.caption.md').write_text(caption)
print(json.dumps({'figure': 'G2-1', 'primary_rows': len(primary),
                  'covered_percent_display': f'{covered_percent:.4f}',
                  'source': 'frozen_C_outputs', 'display_of_C_results': True}))
