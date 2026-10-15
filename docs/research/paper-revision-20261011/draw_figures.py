from pathlib import Path
import csv
import hashlib
import json
import re
import sys

import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt
from matplotlib.patches import FancyArrowPatch, Rectangle
from matplotlib import font_manager


repository = Path(__file__).resolve().parents[3]
source_directory = Path(__file__).resolve().parent
output_directory = repository / 'deliverables/research/paper-revision-20261011/figures'
output_directory.mkdir(parents=True, exist_ok=True)
data = json.loads((source_directory / 'figure-data.json').read_text())
tables = data['tables']
palette = ['#24577A', '#A95A22', '#347A64', '#785D8C']
markers = ['o', 's', '^', 'D']
font_manager.fontManager.addfont('/Applications/Microsoft Word.app/Contents/Resources/DFonts/Simsun.ttc')
plt.rcParams.update({
    'font.family': ['Times New Roman', 'SimSun', 'DejaVu Serif'], 'font.size': 10.5,
    'mathtext.fontset': 'stix',
    'axes.labelsize': 10.5, 'xtick.labelsize': 9.5, 'ytick.labelsize': 9.5,
    'legend.fontsize': 9.5, 'axes.spines.top': False, 'axes.spines.right': False,
    'xtick.direction': 'in', 'ytick.direction': 'in',
    'xtick.major.size': 4, 'ytick.major.size': 4,
    'xtick.minor.size': 2.3, 'ytick.minor.size': 2.3,
    'axes.unicode_minus': False, 'axes.linewidth': 0.7,
    'pdf.fonttype': 42, 'ps.fonttype': 42, 'savefig.dpi': 350,
    'lines.linewidth': 1.2,
})
manifest = []


def save(figure, identifier, provenance):
    for suffix in ['pdf', 'svg', 'png']:
        figure.savefig(output_directory / f'figure-{identifier}.{suffix}',
                       metadata={'Creator': 'Publication figure renderer'} if suffix != 'svg' else None)
    plt.close(figure)
    manifest.append({'figure': identifier, 'source': provenance})


def canvas(height=3.25):
    figure, axis = plt.subplots(figsize=(6.22, height))
    figure.subplots_adjust(left=0.14, right=0.97, bottom=0.22, top=0.80)
    axis.grid(axis='y', color='0.91', linewidth=0.55)
    axis.set_axisbelow(True)
    return figure, axis


def node(axis, x, y, width, height, title, detail='', color=palette[0]):
    axis.add_patch(Rectangle((x, y), width, height, facecolor='white',
                             edgecolor=color, linewidth=1))
    axis.text(x + width / 2, y + height * (0.67 if detail else 0.5), title,
              ha='center', va='center', fontsize=11, color=color, fontweight='bold')
    if detail:
        axis.text(x + width / 2, y + height * 0.28, detail,
                  ha='center', va='center', fontsize=9.5, linespacing=1.6)


def arrow(axis, start, end, label=None):
    axis.add_patch(FancyArrowPatch(start, end, arrowstyle='-|>',
                                  mutation_scale=10, linewidth=0.9, color='0.35'))
    if label:
        axis.text((start[0] + end[0]) / 2, (start[1] + end[1]) / 2 + 0.18,
                  label, ha='center', va='bottom', fontsize=9)


def diagram(identifier, items, note, rows=False):
    figure, axis = plt.subplots(figsize=(6.22, 3.05))
    figure.subplots_adjust(left=0.025, right=0.975, top=0.96, bottom=0.05)
    axis.set(xlim=(0, 10), ylim=(0, 5))
    axis.axis('off')
    if rows:
        for row_index, (title, detail, outcome) in enumerate(items):
            y = 3.65 - 1.3 * row_index
            node(axis, 0.1, y, 2.2, 1.05, title)
            arrow(axis, (2.35, y + 0.52), (2.8, y + 0.52))
            node(axis, 2.85, y, 3.45, 1.05, detail, color=palette[2])
            arrow(axis, (6.35, y + 0.52), (6.8, y + 0.52))
            node(axis, 6.85, y, 3.0, 1.05, outcome, color='0.3')
    else:
        count = len(items)
        width = (9.7 - (count - 1) * 0.35) / count
        for item_index, item in enumerate(items):
            x = 0.15 + item_index * (width + 0.35)
            node(axis, x, 1.75, width, 2.0, item[0], item[1])
            if item_index < count - 1:
                arrow(axis, (x + width + 0.02, 2.75), (x + width + 0.32, 2.75))
    axis.text(5, 0.4, note, ha='center', va='center', fontsize=10, color='0.25')
    save(figure, identifier, '按本文研究流程绘制的概念示意，无实测数据')


diagram('2-1', [('密钥生成', '封装密钥\n解封装密钥'), ('封装', '发送方生成\n密文与共享密钥'), ('解封装', '接收方由密文\n得到共享密钥')], '独立测试向量核对输出；有效输入满足标准正确性要求')
diagram('2-2', [('外部输入', '先检查长度\n及指针有效性'), ('结构检查', '不合格：拒绝访问内核\n合格：继续完整处理'), ('解封装处理', '保留隐式拒绝\n不公开内部验证标志')], '输入结构合格与密文有效是不同判断')
diagram('2-3', [('成对观测', '固定每对差值\n明确交换依据'), ('符号变换', '枚举允许的\n对内标签交换'), ('精确概率', '含等值的尾计数\n除以全部组合数')], '完整枚举保证计算精确；统计有效性仍取决于假设')
diagram('3-1', [('功能验证', '公开向量\n接口与错误处理'), ('时间采集', '完整解封装\n保存逐次观测'), ('统计分析', '检查数据与假设\n描述或置换计算'), ('结果复现', '核对输入及输出\n离线查看材料')], '版本、构建环境与原始数据贯穿整个评估流程')
diagram('3-2', [('窗口之前', '生成输入、分配内存\n完成预热'), ('计时窗口', '开始读钟 → 完整解封装\n→ 结束读钟'), ('窗口之后', '核对返回结果\n保存原始时间')], '每次测量包含完整解封装，不在窗口内生成输入或写日志')
diagram('3-3', [('被测程序', '固定源码与后端\n编译设置与程序摘要'), ('运行条件', '机器、时钟、输入\n运行次序与结束状态'), ('逐次记录', '调用序号与耗时\n单位与原始顺序')], '三类材料对应同一次运行，支持结果追溯与一致性检查')
diagram('3-4', [('记录完整吗', '数量、单位与来源\n是否相互一致'), ('方法适用吗', '样本单位、取值范围\n及统计假设'), ('可以报告什么', '描述结果或条件推断\n同时说明限制')], '不完整记录保留失败状态；已知假设不符时不作相应推断')
diagram('3-5', [('核对材料', '源码和数据清单\n匹配文件摘要'), ('重新构建', '新目录构建\n执行功能检查'), ('重新计算', '读取归档数据\n保持分析规则'), ('比较输出', '逐项检查一致性\n保留差异记录')], '重新得到相同结果验证计算复现，不自动证明原假设成立')
diagram('4-1', [('历史人工对照', '实现行为与既有时间差异', '特定机制的防护观察'), ('普通输入实验', '完整调用与运行开销', '当前条件下的性能'), ('统计计算实验', '相同数据和分析规则', '正确性与计算效率')], '三类实验分别评价防护观察、运行性能和计算效率', rows=True)
diagram('5-1', [('功能正确性', '独立向量与输出等价', '标准功能是否保持'), ('程序与测量', '接口、构建与原始时间', '记录来自什么对象'), ('统计与复现', '独立计数及材料重建', '结果能否重复得到')], '每层都有独立检查目的，不以通过项目数替代研究结论', rows=True)
diagram('3-6', [('防护观察', '同机防护前后对照', '时间分布有何变化'), ('运行开销', '普通输入性能实验', '均值与分位数如何'), ('分析效率', '同一置换任务对照', '相同结果需要多久')], '先确定研究问题，再选择与之对应的比较和指标', rows=True)

labels = ['参考实现', '掩码对照', '正常优化对照']
figure, axis = canvas()
for column, label in enumerate(labels, 1):
    axis.plot(range(1, 7), [float(row[column]) / 1000 for row in tables['305'][1:]],
              marker=markers[column - 1], color=palette[column - 1], label=label)
axis.set(xlabel='运行块', ylabel='完整解封装均值（μs）', xticks=range(1, 7), ylim=(45.8, 46.75))
axis.legend(loc='lower center', bbox_to_anchor=(0.5, 1.02), ncol=3, frameon=False)
save(figure, '5-2', f"{data['source']} 表5.3；ns换算为μs")

report_path = repository / 'docs/evidence/candidate-round-20261007/native/perf/performance.report'
series = {key: {} for key in ['reference', 'hardened', 'deployable']}
for line in report_path.read_text().splitlines():
    match = re.match(r'run=ordinary-(reference|hardened|deployable)-block(\d).*? mean_ns=([\d.]+)', line)
    if match:
        series[match[1]][int(match[2])] = float(match[3]) / 1000
assert all(len(values) == 6 for values in series.values())
figure, axis = canvas()
for column, (key, values) in enumerate(series.items()):
    axis.plot(range(1, 7), [values[block] for block in range(1, 7)],
              marker=markers[column], color=palette[column], label=labels[column])
axis.set(xlabel='运行块', ylabel='完整解封装均值（μs）', xticks=range(1, 7), ylim=(45.5, 48.5))
axis.legend(loc='lower center', bbox_to_anchor=(0.5, 1.02), ncol=3, frameon=False)
save(figure, '5-3', str(report_path.relative_to(repository)))

figure, axis = canvas()
rows = tables['326']
for group, x in enumerate([0, 1], 1):
    for offset, row_number, label, color in [(-0.17, 4, '专用C实现', palette[0]), (0.17, 3, 'SciPy基线', palette[1])]:
        value = float(rows[row_number][group])
        axis.scatter(x + offset, value, color=color, marker='o' if offset < 0 else 's', s=52,
                     label=label if group == 1 else None, zorder=3)
        axis.text(x + offset, value * 1.5, f'{value:.4f}', ha='center', fontsize=9)
axis.set_yscale('log')
axis.set(xlim=(-0.5, 1.5), ylim=(0.02, 150), xticks=[0, 1],
         xticklabels=['完整进程', '基线预先导入'], ylabel='每方法24次窗口的累计耗时（s）')
axis.legend(loc='lower center', bbox_to_anchor=(0.5, 1.02), ncol=2, frameon=False)
save(figure, '5-4', f"{data['source']} 表5.6；原始累计耗时，不计算新的统计量")

figure, axis = canvas()
effect_values = [float(row[0]) for row in tables['345'][1:]]
for column, label in enumerate(['等幅模型', '渐增幅模型'], 1):
    axis.plot(effect_values, [int(row[column]) / 4096 for row in tables['345'][1:]],
              marker=markers[column - 1], color=palette[column - 1], label=label)
axis.axhline(0.01, color='0.45', linestyle=':', linewidth=0.9, label='名义水平 0.01')
axis.set(xlabel='效应（合成ns）', ylabel='拒绝概率', ylim=(-0.04, 1.07), xticks=[0, 1, 2, 4, 8, 12])
axis.legend(loc='lower center', bbox_to_anchor=(0.5, 1.02), ncol=3, frameon=False)
save(figure, '5-5', f"{data['source']} 表5.7；完整计数除以4096")

figure, axis = canvas()
values = [int(row[2]) for row in tables['358'][1:]]
axis.bar(range(1, 7), values, width=0.5, color=palette[0], edgecolor='white')
axis.axhline(40, color=palette[1], linestyle='--', linewidth=1.1, label='最多40个拒绝标签')
for position, value in enumerate(values, 1):
    axis.text(position, value + 1.1, str(value), ha='center', fontsize=10)
axis.set(xlabel='原始运行块', ylabel='拒绝标签数 / 4096', ylim=(0, 47), xticks=range(1, 7))
axis.legend(loc='lower center', bbox_to_anchor=(0.5, 1.02), frameon=False)
save(figure, '5-6', f"{data['source']} 表5.8")

figure, axis = canvas(3.55)
figure.subplots_adjust(left=0.18, right=0.97, bottom=0.18, top=0.75)
for column, label in enumerate(['参考实现', '人工分支对照', '掩码对照', '正常优化对照'], 1):
    axis.scatter([float(row[column].replace('−', '-')) for row in tables['379'][1:]],
                 [position + (column - 2.5) * 0.15 for position in range(5)],
                 label=label, color=palette[column - 1], marker=markers[column - 1], s=26)
axis.axvline(0, color='0.5', linewidth=0.7, linestyle=':')
axis.set(xlabel='分组均值差（ns）', yticks=range(5),
         yticklabels=[row[0] for row in tables['379'][1:]], ylabel='公开种子', xlim=(-1500, 200))
axis.invert_yaxis()
axis.legend(loc='lower center', bbox_to_anchor=(0.5, 1.02), ncol=2, frameon=False)
save(figure, '5-7', f"{data['source']} 表5.10；全部种子与变体")

input_directory = repository / 'docs/evidence/frequency-window-20261010/run-0ba4cd7/analysis'
summary = json.loads((input_directory / 'normal-summary.json').read_text())
with (input_directory / 'normal-windows.csv').open() as handle:
    primary = [row for row in csv.DictReader(handle) if row['role'] == 'primary']
assert len(primary) == 200
figure, axes = plt.subplots(2, 1, figsize=(6.22, 4.0), gridspec_kw={'height_ratios': [3.4, 1], 'hspace': 0.75})
figure.subplots_adjust(left=0.17, right=0.97, bottom=0.15, top=0.92)
axis, coverage_axis = axes
axis.axhspan(4257, 4343, color='0.95')
axis.axhline(4300, color='0.5', linestyle=':', linewidth=0.8)
for row in primary:
    position = int(row['window_index']) + 1
    lower, upper = float(row['frequency_low_mhz_display']), float(row['frequency_high_mhz_display'])
    boundary = row['straddles_main_start'] == 'true'
    axis.vlines(position, lower, upper, color=palette[0], linewidth=0.8)
    axis.plot(position, (lower + upper) / 2, 'D' if boundary else '.',
              color=palette[1] if boundary else palette[0], markersize=4 if boundary else 2,
              markerfacecolor='white' if boundary else palette[0])
axis.set(xlim=(-3, 203), ylim=(4252, 4348), yticks=[4257, 4300, 4343],
         xlabel='主观察窗口序号', ylabel='平均频率估计范围（MHz）')
axis.text(-0.17, 1.06, '(a)', transform=axis.transAxes)
fraction = summary['pure_main_coverage_fraction']
coverage = 100 * int(fraction['numerator_ns']) / int(fraction['denominator_ns'])
coverage_axis.barh(0, coverage, color=palette[0], height=0.5)
coverage_axis.barh(0, 100 - coverage, left=coverage, color='0.8', hatch='////', height=0.5)
coverage_axis.text(50, 0, f'主阶段观测窗口覆盖率 {coverage:.4f}%', ha='center', va='center', color='white', fontsize=10)
coverage_axis.set(xlim=(0, 100), ylim=(-0.45, 0.45), yticks=[], xlabel='主观察时长占比（%）')
coverage_axis.text(-0.17, 1.1, '(b)', transform=coverage_axis.transAxes)
save(figure, '5-8', str(input_directory.relative_to(repository)) + '/normal-{windows.csv,summary.json}')

figure, axis = canvas(3.5)
figure.subplots_adjust(left=0.17, right=0.97, bottom=0.18, top=0.79)
for position, row in enumerate(tables['415'][1:]):
    median, percentile, maximum = [float(row[column]) / 1000 for column in [1, 3, 4]]
    axis.hlines(position, median, maximum, color='0.78', linewidth=1.4)
    for value, marker, color, label in zip([median, percentile, maximum], ['o', 's', '|'], palette, ['P50', 'P99', '最大值']):
        axis.scatter(value, position, marker=marker, color=color, s=45, label=label if position == 0 else None, zorder=3)
axis.set(yticks=range(6), yticklabels=['第一批·1', '第一批·2', '第一批·3', '第二批·1', '第二批·2', '第二批·3'],
         xlabel='完整解封装耗时（μs）', xlim=(28, 63))
axis.invert_yaxis()
axis.legend(loc='lower center', bbox_to_anchor=(0.5, 1.02), ncol=3, frameon=False)
save(figure, '5-9', f"{data['source']} 表5.14；ns换算为μs，不作置信区间")

figure, axis = canvas(3.5)
figure.subplots_adjust(left=0.12, right=0.95, bottom=0.19, top=0.80)
nonzero_rows = [row for row in tables['502'][1:] if '（20）' in row[0]]
assert len(nonzero_rows) == 6
for column in range(1, 4):
    axis.scatter([float(row[column]) for row in nonzero_rows],
                 [position + (column - 2) * 0.18 for position in range(6)],
                 marker=markers[column - 1], color=palette[column - 1], s=29, label=f'进程{column}')
axis.axvline(1, linestyle='--', color='0.5', linewidth=0.8)
axis.set(xlabel='增量计算 / 完整求和的耗时比', xlim=(0, 1.05),
         xticks=[0, 0.25, 0.5, 0.75, 1], yticks=range(6),
         yticklabels=['任务' + row[0].split('（')[0] for row in nonzero_rows])
axis.invert_yaxis()
axis.legend(loc='lower center', bbox_to_anchor=(0.5, 1.02), ncol=3, frameon=False)
save(figure, '5-10', f"{data['source']} 表A.3；预定六个非零任务")

assert len(manifest) == 20
for item in manifest:
    item['sha256'] = {suffix: hashlib.sha256((output_directory / f"figure-{item['figure']}.{suffix}").read_bytes()).hexdigest() for suffix in ['png', 'pdf', 'svg']}
(source_directory / 'figure-manifest.json').write_text(json.dumps(manifest, ensure_ascii=False, indent=2))
print(f'Created {len(manifest)} figures in PDF, SVG and PNG formats')
