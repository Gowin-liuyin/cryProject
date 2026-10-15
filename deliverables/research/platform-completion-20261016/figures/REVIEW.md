# 图源与视觉核验（结果矩阵，2026-10-16 刷新）

状态：**原生 SVG 结果图源与 2 倍 PNG 预览通过，10/10（M2–M5 锁频统计已回填后重渲染）；本图只表达当前已有证据的状态。**
本图是**结果图**，不是计划图；它不预填未运行项，也不把定位或软件资格升级为统计与验收。

## 实际生成命令

```sh
python3 deliverables/research/platform-completion-20261016/figures/render_matrix.py
python3 deliverables/research/platform-completion-20261016/figures/render_preview.py
```

第一行从 `../EVIDENCE_MATRIX.csv` 重建 `platform-evidence-matrix.svg`（1492×912，全部为可编辑
`text` 元素，无 foreignObject、无整图位图）；第二行把 SVG 包进正方形画布交给 macOS QuickLook
渲染 2 倍像素，再用 Pillow 裁回真实宽高，得到 `platform-evidence-matrix.png`（2984×1950）。

渲染器变更与失败保留：本机 Chrome headless 的 `--screenshot` 与 `--print-to-pdf` 在本次环境里
只输出 GCM 报错、不产出文件（超时 120–150 秒），因此不再把 Chrome 记为本图渲染器；改用
QuickLook（WebKit）并在 `RENDER_ENV.json` 中记录实际渲染器、版本与裁剪方式。
此前 Mermaid 路线的三轮裁切失败仍未交付，仍只留在本机 `build/platform-completion-s1/`。

## 图形结构与逐格内容

分层分组：3 条分类带（真实历史案例 / 人工构造校准 / 阴性对照候选）× 5 列 × 5 行。

| 行 | 分类带 | 软件与产物 | 定位 | 时间统计与复测 | 形式化 / 边界 |
|---|---|---|---|---|---|
| M1 | 真实历史案例 | 封存引用 | Valgrind poly_frommsg 秘密分支 1 对 0；bt+jae→setb+cmov_int16 | 10000/类×3 次独立复测；Δ +39.337/+31.117/+22.337 对 −13.209/+8.354/−4.885 ns；Holm m=6；RTLF；dudect | 未主张（官方修复 982c762 复测） |
| M2 | 真实历史案例 | 完整 KEM 两版各 7/7 | 静态 div 未修各 1、已修各 0；热点探针 varlat 1280/3 对 0/0 | 已执行：家族 m=6，Holm 拒绝 0；合并 Δ +4.58 ns，CI [−3.08, +12.25]，I²=58.3%；端到端未检出 | 微基准触发条件已满足，not_run |
| M3 | 人工构造校准 | 完整解封装人工挂载 on/off 各 6/6 | 挂载后 Memcheck on 1280/2 对 off 0/0；Microwalk MI 1.922 对 0.722 | 已执行：臂内主类对家族 m=6，Holm 拒绝 0；合并 Δ −0.73 ns，CI [−5.56, +4.10]，I²=12.5% | 未运行；Microwalk 换算后由源码自建补足 |
| M4 | 人工构造校准 | 独立夹具普通与 sanitizer 各 4/4 | Memcheck 提前退出 32/1 对 ct 0/0 | 已执行：臂内主类对家族 m=6，Holm 拒绝 3（全在 vulnerable 臂）；ct 臂 0.386/0.438/0.399 | Binsec insecure 对 bounded secure；-sse-depth 5 → unknown |
| M5 | 阴性对照候选 | 原生功能资格各 7/7 | 秘密标记 Memcheck 与 varlat=yes/no：10 次完整调用 0/0 | 已执行：家族 m=3，Holm 拒绝 0；合并 Δ −5.30 ns，CI [−11.77, +1.16]，I²=0%；dudect state=1 | 未主张 |

CSV 校验在生成时程序执行：模块顺序 M1–M5、`audit_commit=ac46e62`、三个分类带齐全；
任一断言失败即中止生成，不产出图。

## 实际目视结果

已按原尺寸查看最终 PNG（2984×1950）：标题 1 行、副标题 2 行、表头 5 格、分类带 3 条、
正文 25 格、底注 3 行全部可读，无裁切、无覆盖、无越界；正文没有跨词断行
（ASCII 词、数字与路径不再被拆开）。
M2–M5 的“时间统计与复测”格已回填实际家族结果；图中 `«待主控数据»` 只出现在图注说明的 RTLF（partial）一处，不是阴性。M5 的形式化格为“未主张”，没有被写成阴性通过。灰色＝封存引用、蓝色＝已执行、橙色＝未运行；状态词同时写在格内。

评分 10/10（本图范围）：内容与证据对应、分类与状态可读、无颜色依赖。
图注与每格证据路径见 [CAPTION.md](CAPTION.md)；机器可读来源见 [../EVIDENCE_MATRIX.csv](../EVIDENCE_MATRIX.csv)。
