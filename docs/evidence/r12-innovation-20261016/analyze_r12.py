#!/usr/bin/env python3
"""R12 创新对照 (a)：锁频 vs 不锁频的方差比、所需样本量比、M5 假阳性计数。"""
import json
import math
import pathlib
import statistics
import sys

REPO = pathlib.Path('/Users/yin/code/cryProject')
ROOT = REPO / 'docs/evidence/r12-innovation-20261016/runs'

ARMS = ['m1unfixed', 'm1fixed', 'm5ref']
TAGS = ['s1', 's2', 's3']
CLASS0 = 'message-zero'
CLASS1 = 'message-ones'
Z_ALPHA = 1.959963984540054   # 双侧 alpha=0.05
Z_BETA = 0.8416212335729143   # 功效 80%


def read_classes(csv_path):
    xs, ys = [], []
    with csv_path.open() as handle:
        header = handle.readline().strip().split(',')
        idx_category = header.index('input_category')
        idx_value = header.index('elapsed_nanoseconds')
        for line in handle:
            parts = line.rstrip('\n').split(',')
            if parts[idx_category] == CLASS0:
                xs.append(int(parts[idx_value]))
            elif parts[idx_category] == CLASS1:
                ys.append(int(parts[idx_value]))
    return xs, ys


def mean_sd(values):
    n = len(values)
    mean = sum(values) / n
    variance = sum((v - mean) ** 2 for v in values) / (n - 1)
    return mean, math.sqrt(variance)


def welch(xs, ys):
    n0, n1 = len(xs), len(ys)
    m0, s0 = mean_sd(xs)
    m1, s1 = mean_sd(ys)
    se = math.sqrt(s0 * s0 / n0 + s1 * s1 / n1)
    delta = m0 - m1
    t_value = delta / se if se > 0 else 0.0
    p_value = math.erfc(abs(t_value) / math.sqrt(2.0))
    return delta, se, p_value, s0, s1, m0, m1


rows = []
for arm in ARMS:
    for tag in TAGS:
        for mode in ('locked', 'unlocked'):
            run = f'r12-{arm}-{mode}-{tag}'
            csv_path = ROOT / run / 'samples.csv'
            if not csv_path.exists() and (ROOT / run / 'samples.csv.gz').exists():
                csv_path = ROOT / run / 'samples.csv.gz'
                import gzip
                data = gzip.open(csv_path, 'rt')
                header = data.readline().strip().split(',')
                idx_category = header.index('input_category')
                idx_value = header.index('elapsed_nanoseconds')
                xs, ys = [], []
                for line in data:
                    parts = line.rstrip('\n').split(',')
                    if parts[idx_category] == CLASS0:
                        xs.append(int(parts[idx_value]))
                    elif parts[idx_category] == CLASS1:
                        ys.append(int(parts[idx_value]))
                data.close()
            elif csv_path.suffix == '.gz':
                raise SystemExit(f'missing {csv_path}')
            else:
                xs, ys = read_classes(csv_path)
            delta, se, p_value, s0, s1, m0, m1 = welch(xs, ys)
            rows.append(dict(arm=arm, tag=tag, mode=mode, run=run, n0=len(xs), n1=len(ys),
                             mean0=m0, mean1=m1, sd0=s0, sd1=s1, delta=delta, se=se, p=p_value))

print(f'{"arm":10s} {"tag":4s} {"mode":9s} {"n":>6s} {"Δ(ns)":>10s} {"sd0":>9s} {"sd1":>9s} {"p":>11s}')
for r in rows:
    print(f'{r["arm"]:10s} {r["tag"]:4s} {r["mode"]:9s} {r["n0"]:6d} {r["delta"]:10.2f} '
          f'{r["sd0"]:9.2f} {r["sd1"]:9.2f} {r["p"]:11.4g}')

print('\n== 合并 SD（同一臂同条件三次运行的加权 SD）与方差比 ==')
summary = {}
for arm in ARMS:
    for mode in ('locked', 'unlocked'):
        sds = [r['sd0'] for r in rows if r['arm'] == arm and r['mode'] == mode]
        pooled = math.sqrt(sum(s * s for s in sds) / len(sds))
        summary[(arm, mode)] = pooled
    locked = summary[(arm, 'locked')]
    unlocked = summary[(arm, 'unlocked')]
    ratio = unlocked / locked if locked > 0 else float('nan')
    print(f'{arm:10s} locked_SD={locked:9.2f}  unlocked_SD={unlocked:9.2f}  '
          f'unlocked/locked={ratio:6.3f}')

print('\n== 达到检出所需每类样本量（alpha=0.05 双侧、功效 80%）==')
print(f'{"arm":10s} {"Δ_locked(ns)":>13s} {"n_locked":>10s} {"n_unlocked":>12s} {"n比":>7s}')
for arm in ARMS:
    deltas = [r['delta'] for r in rows if r['arm'] == arm and r['mode'] == 'locked']
    delta_target = abs(statistics.mean(deltas))
    if delta_target == 0:
        print(f'{arm:10s} {"Δ 为 0，无法计算":>13s}')
        continue
    need = {}
    for mode in ('locked', 'unlocked'):
        sigma = summary[(arm, mode)]
        need[mode] = 2.0 * (Z_ALPHA + Z_BETA) ** 2 * sigma * sigma / (delta_target ** 2)
    print(f'{arm:10s} {delta_target:13.2f} {need["locked"]:10.0f} {need["unlocked"]:12.0f} '
          f'{need["unlocked"] / need["locked"]:7.3f}')

print('\n== 原始 p < 0.05 的运行（M5 为已知阴性对象；样本量极小，仅描述）==')
for arm in ARMS:
    for mode in ('locked', 'unlocked'):
        hits = [r['tag'] for r in rows if r['arm'] == arm and r['mode'] == mode and r['p'] < 0.05]
        print(f'{arm:10s} {mode:9s} p<0.05 次数 = {len(hits)}/3  {hits}')

pathlib.Path(REPO / 'docs/evidence/r12-innovation-20261016/innovation_a.csv').write_text(
    'arm,tag,mode,run,n0,n1,mean0_ns,mean1_ns,sd0_ns,sd1_ns,delta_ns,se_ns,welch_p\n' +
    ''.join(f'{r["arm"]},{r["tag"]},{r["mode"]},{r["run"]},{r["n0"]},{r["n1"]},{r["mean0"]!r},'
            f'{r["mean1"]!r},{r["sd0"]!r},{r["sd1"]!r},{r["delta"]!r},{r["se"]!r},{r["p"]!r}\n'
            for r in rows))
print('\nwrote innovation_a.csv')
