import csv, json, math, os, sys, glob, random, re
from collections import defaultdict
OUT = sys.argv[1]
def q(xs, p):  # 与仓库 reference-benchmark 相同的零基下标，不插值
    return xs[int(math.floor(p * (len(xs) - 1) + 0.5))]
def load(path, c0, c1):
    a, b = [], []
    with open(path) as f:
        for r in csv.DictReader(f):
            if r['input_category'] == c0: a.append(int(r['elapsed_nanoseconds']))
            elif r['input_category'] == c1: b.append(int(r['elapsed_nanoseconds']))
    return a, b
def mv(x):
    m = sum(x) / len(x); return m, sum((v - m) ** 2 for v in x) / (len(x) - 1)
lines = ["# WSL 复现统计汇总（自动生成）", "",
         "Δ = 类0 均值 − 类1 均值（M1/M2/M5：message-zero − message-ones；M4：mismatch-first − mismatch-last）。",
         "Welch 95% CI 为正态近似（z=1.96），与仓库 platform_stats 一致；每行同时给出仓库电池 ci_welch.json 的 Δ 以便核对。",
         "不锁频虚拟化环境：仅作跨环境描述，不进任何 Holm 家族。", "",
         "## 逐次运行", "", "| run | n/类 | Δ ns | 95% CI | Welch p | 电池 Δ | 中位数差 | p90 差 | p99 差 |", "|---|---|---|---|---|---|---|---|---|"]
groups = defaultdict(list)
for path in sorted(glob.glob(os.path.join(OUT, 'raw', '*.csv'))):
    run = os.path.basename(path)[:-4]
    if run.startswith('dudect'): continue
    c0, c1 = ('mismatch-first', 'mismatch-last') if run.startswith('m4-') else ('message-zero', 'message-ones')
    a, b = load(path, c0, c1)
    if len(a) < 2 or len(b) < 2: continue
    ma, va = mv(a); mb, vb = mv(b); d = ma - mb; se = math.sqrt(va / len(a) + vb / len(b))
    z = d / se if se > 0 else 0.0; p = math.erfc(abs(z) / math.sqrt(2))
    sa, sb = sorted(a), sorted(b)
    bat = ''
    j = os.path.join(OUT, 'stats', 'runs', run, 'ci_welch.json')
    if os.path.exists(j):
        bat = '%.2f' % json.load(open(j)).get('mean_difference_class0_minus_class1_ns', float('nan'))
    lines.append('| %s | %d | %.2f | [%.2f, %.2f] | %.3g | %s | %d | %d | %d |' % (run, len(a), d, d - 1.96 * se, d + 1.96 * se, p, bat,
                 q(sa, .5) - q(sb, .5), q(sa, .9) - q(sb, .9), q(sa, .99) - q(sb, .99)))
    groups[re.sub(r'-s\d+-r\d+$', '', run)].append((d, se))
lines += ["", "## 按臂固定效应合并（逆方差加权；同臂所有种子与重复）", "", "| 臂 | 运行数 | 合并 Δ ns | 95% CI | z | 同号运行数 |", "|---|---|---|---|---|---|"]
for g, rs in sorted(groups.items()):
    w = [1 / se ** 2 for _, se in rs if se > 0]
    if not w: continue
    m = sum(wi * d for wi, (d, _) in zip(w, rs)) / sum(w); s = 1 / math.sqrt(sum(w))
    pos = sum(1 for d, _ in rs if d > 0)
    lines.append('| %s | %d | %.2f | [%.2f, %.2f] | %.2f | +%d / −%d |' % (g, len(rs), m, m - 1.96 * s, m + 1.96 * s, m / s, pos, len(rs) - pos))
# 性能
perf = defaultdict(lambda: defaultdict(list))
for path in glob.glob(os.path.join(OUT, 'perf', 'perf-*.csv')):
    arm = re.sub(r'^perf-|-b\d+\.csv$', '', os.path.basename(path))
    with open(path) as f:
        for r in csv.DictReader(f):
            perf[arm][r['input_category']].append(int(r['elapsed_nanoseconds']))
if perf:
    lines += ["", "## 性能（ns；不锁频）", "", "| 臂 | 操作 | n | 均值 | 中位数 | p90 | p99 |", "|---|---|---|---|---|---|---|"]
    for arm in sorted(perf):
        for op in sorted(perf[arm]):
            x = sorted(perf[arm][op]); lines.append('| %s | %s | %d | %.1f | %d | %d | %d |' % (arm, op, len(x), sum(x) / len(x), q(x, .5), q(x, .9), q(x, .99)))
    if 'm1unfixed' in perf and 'm1fixed' in perf:
        a = perf['m1unfixed'].get('decaps', []); b = perf['m1fixed'].get('decaps', [])
        if a and b:
            rnd = random.Random(2026); sa, sb = sorted(a), sorted(b)
            ov_mean = (sum(b) / len(b)) / (sum(a) / len(a)) - 1; boots = []
            for _ in range(1000):
                ra = [a[rnd.randrange(len(a))] for _ in range(len(a))]; rb = [b[rnd.randrange(len(b))] for _ in range(len(b))]
                boots.append((sum(rb) / len(rb)) / (sum(ra) / len(ra)) - 1)
            boots.sort()
            lines += ["", "M1 decaps 防护开销（已修相对未修）：均值 %+.3f%%（bootstrap 1000 次 95%% CI [%+.3f%%, %+.3f%%]）；中位数 %+.3f%%；p90 %+.3f%%；p99 %+.3f%%" % (
                100 * ov_mean, 100 * boots[25], 100 * boots[974], 100 * (q(sb, .5) / q(sa, .5) - 1), 100 * (q(sb, .9) / q(sa, .9) - 1), 100 * (q(sb, .99) / q(sa, .99) - 1))]
# dudect
lines += ["", "## dudect（族外，阈值 t>10）", ""]
for path in sorted(glob.glob(os.path.join(OUT, 'raw', 'dudect-*.log'))):
    txt = open(path, errors='replace').read().strip().splitlines()
    ts = [float(m.group(1)) for l in txt for m in [re.search(r'max t:\s*([+-]?[\d.]+)', l)] if m]
    tail = [l for l in txt if l.startswith(('stopped_after', 'battery_dudect', 'completed_batches'))]
    lines.append('- %s：最后 max t = %s；%s' % (os.path.basename(path), ('%+.2f' % ts[-1]) if ts else 'n/a', '；'.join(tail)))
for name in ('disasm/SUMMARY.tsv', 'memcheck/SUMMARY.tsv'):
    p = os.path.join(OUT, name)
    if os.path.exists(p):
        lines += ["", "## " + name, "", "```", open(p).read().strip(), "```"]
open(os.path.join(OUT, 'stats', 'SUMMARY.md'), 'w').write('\n'.join(lines) + '\n')
print('\n'.join(lines))
