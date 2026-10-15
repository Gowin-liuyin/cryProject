# M2 完整解封装统计预注册

状态：**待主控提交冻结，尚未执行采数**。本文件的新增时间不能替代 Git 提交冻结。
本轮先检测端到端，再按固定条件决定是否进入热点微基准；不做密钥恢复。

## 对象、测量与固定预算

历史 Kyber768 round3 SHAKE 版本，非 FIPS 203；源码和公开 KAT 资格见本目录软件合同。
只用 `native-qualification/ELF.sha256` 的普通构建，不用 sanitizer ELF 采数。

| 变体 | 普通 measure ELF SHA-256 |
|---|---|
| 未修 a621b8dde405cc507cbcfc5f794570a4f98d69cc | `dd4073ba38d9ba6b465fca9b6f2e94ef11d8ebc8948901e41f0ba9926ee674e7` |
| 已修 272125f6acc8e8b6850fd68ceb901a660ff48196 | `c48f89a5bc7f9bd8117a0319eacbc40bf9d061ecae2bad48812376d04745ada7` |

CLI 精确为 `measure RUN_ID SEED SAMPLES_PER_CATEGORY CSV_FILE META_FILE`，每类数量范围 1–20000。
每个进程实际生成 **5 类**：valid、bit-flipped、random、message-zero、message-ones；
`10000` 因而是 **50000 次正式完整解封装**，不是只采两类。另有 100 次预热，预热不入 CSV。
窗口是两个 `CLOCK_MONOTONIC` 纳秒读钟之间的一次 `mlkem_decapsulate`，两侧信号栅栏；
生成、分配、结果消费和输出在窗口外。全量保留普通长尾，不扣钟开销，不转成 CPU cycles。

三 run 固定如下，变体顺序也是合同的一部分。六个进程顺序执行，禁止并行占用 CPU2/CPU6。

| run | 测试 seed | CPU | 每类数量/每变体 | 先后顺序 |
|---|---:|---:|---:|---|
| r01 | 31337 | 2 | 10000 / 共50000行 | 未修 → 已修 |
| r02 | 424242 | 2 | 10000 / 共50000行 | 已修 → 未修 |
| r03 | 31337 | 6 | 10000 / 共50000行 | 未修 → 已修 |

总预算：300000 次正式解封装、600 次预热；主类对共120000行，其他180000行完整保留。
每进程输入数组约55.2MB；依据本轮7条软件测试总计约0.1–0.2秒的粗量级，
为规划保守预留每次完整操作1ms：每进程50秒解封装加至多40秒输入加密、其他开销，
六进程保留约15分钟运行预算。该估算不是性能结果或精度界。
单进程管理上限180秒、整轮18分钟；超时/资源错误后停止本轮、恢复配置并保留现场，
不因显著性或未显著而增样、追加 seed、补跑或挑选成功进程。

## 实际命令与输出

下列命令只能放进主控已验证的锁频/恢复控制器内部执行，不能代替控制器。
新 `M2_RUN_ROOT` 必须是 Cry 内不存在的物理目录，临时/缓存、日志、CSV 和分析输出全部落在其内。
`M2_BIN_ROOT` 固定为本轮已核验的普通产物目录；运行前重新核对上述两个摘要。

```sh
M2_BIN_ROOT=/home/nss-marker/yhr/Cry/platform-m2kem-20261016-d75a4019/build-ordinary/platform-m2
M2_RUN_ROOT=/home/nss-marker/yhr/Cry/platform-m2-stat-20261016-<nonce>
taskset -c 2 "$M2_BIN_ROOT/unfixed/measure" m2_r01_unfixed 31337 10000 "$M2_RUN_ROOT/raw/m2_r01_unfixed.csv" "$M2_RUN_ROOT/raw/m2_r01_unfixed.meta"
taskset -c 2 "$M2_BIN_ROOT/fixed/measure" m2_r01_fixed 31337 10000 "$M2_RUN_ROOT/raw/m2_r01_fixed.csv" "$M2_RUN_ROOT/raw/m2_r01_fixed.meta"
taskset -c 2 "$M2_BIN_ROOT/fixed/measure" m2_r02_fixed 424242 10000 "$M2_RUN_ROOT/raw/m2_r02_fixed.csv" "$M2_RUN_ROOT/raw/m2_r02_fixed.meta"
taskset -c 2 "$M2_BIN_ROOT/unfixed/measure" m2_r02_unfixed 424242 10000 "$M2_RUN_ROOT/raw/m2_r02_unfixed.csv" "$M2_RUN_ROOT/raw/m2_r02_unfixed.meta"
taskset -c 6 "$M2_BIN_ROOT/unfixed/measure" m2_r03_unfixed 31337 10000 "$M2_RUN_ROOT/raw/m2_r03_unfixed.csv" "$M2_RUN_ROOT/raw/m2_r03_unfixed.meta"
taskset -c 6 "$M2_BIN_ROOT/fixed/measure" m2_r03_fixed 31337 10000 "$M2_RUN_ROOT/raw/m2_r03_fixed.csv" "$M2_RUN_ROOT/raw/m2_r03_fixed.meta"
```

CSV 表头精确为
`run_id,implementation,input_category,sample_index,elapsed_nanoseconds,time_unit`。
每文件50000数据行，各类别10000、sample_index 0–49999；单位 `ns`。
同 seed 的输入和 Fisher–Yates/SHAKE256 标签顺序可复现。源代码对输出采用新建方式，已有文件必须失败。
所有六份 CSV 独立分析，不跨 run/seed/CPU/变体静默拼接。

主类对固定为 **class0=message-zero、class1=message-ones**，差定义为 mean0−mean1。
这两类是同一固定测试 key 下的两个已选消息密文，各类重复同一密文；r01/r03还复用同一 key。
不能把10000行称作10000个独立密文，也不能把两个CPU称作独立机器。
valid/bit-flipped/random只作明示的描述性辅助，不新增确认性比较。

## 主检验族与判定

预注册一个 **全局 M2 端到端族 m=6**：三 run × 未修/已修，每项均检验主类对均值差为0，双侧。
六项全部保留，不按观察结果拆成每 run 的 m=2，也不选择最显著 seed/CPU。

- CI/Welch 复用统计电池：原均值、方差、SE、Welch t/自由度、95%大样本正态近似区间。
- Holm 仅纳入六个 `erfc(|t|/sqrt(2))` 大样本近似 p，族 α=.05；按 p 升序以 `.05/(6−rank+1)` 逐步比较，首次不拒绝后停止拒绝。
- 95% CI 是单项描述区间，不冒称六项同时覆盖区间。零方差/null p/缺失 run 保留异常，不能缩小族数或按零 p 伪造通过。
- 浮点p下溢为0时保留原t/自由度和下溢说明，不声称数学p恰为0。
- RTLF 固定 α=.01，bootstrap种子2026101605，原上游脚本和工具摘要保存；其二值结果不转成连续p、不进 Holm。
- 独立在线 dudect 和离线回放均不进 Holm，不把最大 t 转成伪 p。

统计电池精确调用范式，每份原 CSV 使用不同的新输出目录：

```sh
scripts/run_stats_battery.sh --input "$M2_RUN_ROOT/raw/m2_r01_unfixed.csv" --format measure --classes message-zero message-ones --output-dir "$M2_RUN_ROOT/analysis/m2_r01_unfixed" --stats-bin /path/to/pinned/platform_stats --rtlf-script /path/to/pinned/RTLF/rtlf.R
```

对应输出为原输入副本/摘要、normalized.csv、ci_welch.json、RTLF原JSON/日志、summary.json 和 RESULT.md。
每CSV入选20000行、`excluded_other_category_count=30000`。主控另输出六项 `holm.csv`，
明确记录假设ID、原近似p、Holm次序/阈值/调整值/判决，不改写统计电池的单项结果。
20k行不足以使当前离线 dudect 在上游预热和门槛后给出完整判决，预计应如实记 insufficient_measurements，
不能用它代替下述在线流程。

未修三 run 经全族 Holm 均拒绝且方向一致，才称“本固定合同下端到端可重复检出”；
只在部分 run 检出则逐项列明，不能称三处重复。
已修不拒绝只写“本批未检出”，不作等价/恒时证明；已修仍拒绝须保留结果并调查共同机制或噪声。
同密文重复存在时间相关风险；以上单项p是大样本近似，Holm的误报保证依赖单项p有效，
不将机械校正称作已认证真实总体误报率、独立性或频率/时钟物理精度。

## 独立在线 dudect：族外辅助

由主控负责提供并冻结真正调用上游 `dudect_main` 的 M2 在线适配，不将离线回放冒充在线。
本次合同预留每版一次 CPU2/seed31337、相同实际消息0/FF类对，顺序未修→已修；
每批10000次回调，固定20批（每版200000次完整解封装），标签按公开seed和批号生成平衡且可复现的乱序。
首批10000只供上游预热/分位阈值，后19批保留原上游端点丢弃及裁剪/二阶辅助检查记账。
无论是否提前遇到阳性都保留20批，阳性状态粘滞；不得看到输出后续跑到“想要”的结果。
上游原阈值 `max|t|>10`（及其更高阈值）不改；未到有效样本门槛或工具异常明确写未完成。

回调只调完整解封装并在进程内消费输出，不输出秘密；输入生成与分配在回调外。
原工具的 RDTSC/cycles 窗口和回调开销与主采数ns窗口分别报告，绝不按4.30GHz直接换算/合并。
每版在线管理上限300秒，两版最多10分钟；中断保留进程/批次和配置恢复记录。
适配尚未存在的CLI不在本计划中虚构：须在实际执行前由主控固定入口、ELF/源摘要及原样命令。
若本轮未交付合格在线适配则写 blocked/not_run，不用离线样本补签。

## 条件微基准：触发与边界事先固定

仅在六份端到端run均通过管理资格、数据完整且分析完成后，以下任一条件出现时触发：
未修未达到“三run全族拒绝且方向一致”，或已修任一主项仍被拒绝。
行政/恢复失败或缺失run不能触发补救采样，应停止并保留未完成状态。
否则本轮不增加微基准。本条件不能用于增加或替代端到端样本。

微基准只包一次上游 `poly_tomsg`，两个固定公开规范多项式：256系数全0 vs 全1664；
功能先核对其输出消息分别全0/FF。使用相同普通Clang18 `-Oz` 源码、单调用ns窗口、
分配/输入/消费/日志均在窗口外；禁用sleep、随机延迟、空转或秘密输出。
三run/CPU/seed/变体顺序与主表一致，每类10000，另100次预热；只用单一热点，不再择取更显著函数。
若需实现新的微基准驱动，先完成其普通/sanitizer资格及代码/ELF摘要，不能在未审入口上直接采数。

微基准是单独标记的探索族 m=6，Holm只Welch近似p、α=.05，RTLF同α=.01，
不与端到端p合并、不主张两族合起来仍是总体α=.05；更不能用微基准阳性补签端到端。
微基准也未检出则报告“定位阳性，当前处理器/类对未检出时间差”，不伪造阳性。

## 控制器准入与终止

实际裸金属nss-m/x86_64；主控独占管理锁，boost关、performance、请求约4300000kHz，
核对当前CPU2/6及SMT sibling拓扑、外部亲和性、配置进出快照、退出必恢复且 `restore_match=yes`。
不得有另一采数任务占CPU2/CPU6；输入生成/R/RTLF/编译等噪声任务不与采样并行。
恢复失败、机型/ELF不符、时钟/计数错误或数据不完整即不得签收正式统计；原始文件及失败过程全部保留。
请求频率与可见配置匹配不等于逐调用恒频、隐藏QoS完整原状或物理时间误差界。

collector元数据中的 `cpu_affinity=not_pinned`、`frequency_control=not_configured` 是其内部未设置状态；
外部 taskset/频控控制器必须用独立sidecar记录实际进程亲和性、可见配置与恢复结果，原meta不改字。
原件、缓存、临时目录、控制/恢复日志、分析和归档只在 `/home/nss-marker/yhr/Cry` 物理边界内。
