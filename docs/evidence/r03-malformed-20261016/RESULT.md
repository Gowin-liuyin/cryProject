# R03 格式破损 / 截断输入族外对照结果（2026-10-16）

**本结果是族外描述性对照**：不进入任何已冻结的 Holm 家族，不改变 `efca8a1` 与 M1/M5 的既有判定，
也不改动任何 PLAN。合同见 [PLAN.md](PLAN.md)。

## 0. 一句话结论

**格式破损密文（长度正确、u/v 字段被整体改写）与合法密文的解封装耗时在本机不可区分**
（9 个「臂 × 种子」组合的 Δ 全部落在 ±10 ns 内、95% CI 全部含 0、原始 p ≥ 0.28）；
**长度不足的密文在封装层被直接拒绝**，耗时约 23 ns，比完整解封装低约 3 个数量级
——这是接口语义，不是泄漏。两者都不进 Holm。

## 1. 采集条件与有效性

| 项 | 值 |
|---|---|
| 控制器 | `tools/platform_control/controller.py` sha256 `4a0cf57a00c6802ff86ed410d2518bc56cc8e694422cbc4ea7a24a3f1cdd701` |
| 控制根 | `Cry/platform-control-20261016-53929b406f0d` |
| 族外计划 | `Cry/r03-malformed-20261016/plans/r03-PLAN.md`，sha256 `79edb27f8339691f2f9e49c4ca9fdfffd47d03945297a358517caa2414ff284a`（由控制器 `--plan-sha256` 校验） |
| 频率合同 | `boost=0`、governor/EPP=`performance`、`min=max=4300000 kHz`、`taskset -c 2|6`；沉降 1.0 s 后 20×50 ms 放行探针全部在 ±2% 且跨度 ≤50000 kHz |
| 运行 | 3 臂 × 3 种子 = 9 次 measure + 9 次族外 online dudect = **18 次控制器运行** |
| 种子 / CPU | s1 = 31337 / CPU2；s2 = 424242 / CPU2；s3 = 7 / CPU6 |
| 样本 | 每类 10000，预热 100（窗口外） |
| 有效性 | **18/18 `restore_match=yes`**，`worker_exit_code=0`，放行探针全部在带内（逐条见 [logs/status.log](logs/status.log)） |

每次运行的进入/运行中/退出频率快照、`terminal.json`、`entry-probes.json`、`during.json`、
`0020-restored.json` 与逐写 intent/visible 序列都在 `R03/<run-name>/controller/` 下。
本轮**没有失败运行**，`failed/` 为空。

## 2. 采集件

| 臂 | 实现 | ELF sha256 |
|---|---|---|
| `m1unfixed` | liboqs 0.10.0，Clang 18 `-Os -fno-vectorize`，关 AVX2 分发 | `a3c94bc0048fd32b6e66a23a4113d3b80a363ea00c53d566fdc83c8b60586998` |
| `m1fixed` | 同上 + 官方修复 `982c762`（`setb` + `cmov_int16`） | `a93c2f60adaecc6458386594e028e2525c429d5d495d9f13a4f040fd742fecc8` |
| `m5ref` | mlkem-native `b3ba7b3` 参考路径 | `772cf099d240754d5781f231b89464543d5ccb6f98901c8385c241c306ec2934` |

三臂共用同一份 C 源 `0b442b995fd263ddc180fc9ebaaeeada9a695a4fe56ab4676a6cd82d437134bd`，
各自链接本树的实现（M1 两臂链接各自的 `historical/libmlkem.a` + `liboqs.a`，M5 链接
`build-v2-ordinary/reference/libmlkem.a`）。资格：`--describe` 3/3、CLI 拒绝 75/75、
`valid` 类输入与各树既有 `generate-test valid 31337` 逐字节相同、derand 回环 3/3、
反汇编确认未修 `bt/jae`、已修 `setb`+`call cmov_int16`、M5 纯掩码。细节见
[tooling/README.md](tooling/README.md) 与 [tooling/r03_controller_commands.sh](tooling/r03_controller_commands.sh)。

### 三个输入类（每类内部是同一份输入的重复）

| 类 | 构造 | 预期路径 | 实测均值 |
|---|---|---|---|
| `valid` | 一份固定的合法 ML-KEM-768 密文（1088 B） | 完整解封装，接受分支 | ~29.3 µs（M5）/ ~55.1 µs（M1） |
| `malformed` | 同一份密文，u 字段（前 960 B）置 `0xFF`、v 字段（后 128 B）置 `0x00`，长度仍 1088 | 完整解封装，**隐式拒绝** | 与 `valid` 同级 |
| `truncated` | 同一份密文只喂 **1087 B** | 封装层**长度检查**直接拒绝 | **~23.2 ns** |

`malformed` 三臂用的是**同一份**输入（sha3 `83c67b52…`）；`truncated` 是各臂 `valid` 的前 1087 字节。
meta 里显式记录 `identical_input_per_class=yes`、`input_repetition_rule`、
逐类 `zero_elapsed_rows`（本轮全为 0）与 `window_scope=one_mlkem_decapsulate_call`。

## 3. 对照 A：合法 vs 格式破损（`valid` − `malformed`）

只给原始量（**不做 Holm、不做任何多重比较校正**）：

| 臂 | 种子 | Δ（ns） | 95% 正态近似 CI（ns） | 原始 p | n0/n1 |
|---|---|---:|---|---:|---|
| m1unfixed | 31337 | +7.9 | [−6.6, +22.3] | 0.2849 | 10000/10000 |
| m1unfixed | 424242 | +1.6 | [−8.5, +11.6] | 0.7591 | 10000/10000 |
| m1unfixed | 7 | −3.2 | [−17.6, +11.1] | 0.6581 | 10000/10000 |
| m1fixed | 31337 | +4.7 | [−12.9, +22.2] | 0.6043 | 10000/10000 |
| m1fixed | 424242 | +9.8 | [−8.5, +28.1] | 0.2934 | 10000/10000 |
| m1fixed | 7 | +0.5 | [−15.9, +16.9] | 0.9552 | 10000/10000 |
| m5ref | 31337 | −2.2 | [−11.0, +6.5] | 0.6153 | 10000/10000 |
| m5ref | 424242 | −1.2 | [−12.1, +9.7] | 0.8280 | 10000/10000 |
| m5ref | 7 | −2.6 | [−9.5, +4.3] | 0.4648 | 10000/10000 |

**9/9 的 CI 含 0，9/9 的原始 p ≥ 0.28，方向在两臂之间来回摆动**（未修臂 +7.9/+1.6/−3.2，
已修臂 +4.7/+9.8/+0.5）——这与"隐式拒绝路径设计上就走完整重加密，破损密文与合法密文
耗时一致"的预期相符。**未检出额外的可区分路径**，但这**不是恒时证明**：
它只覆盖本机、本编译产物、本预算。

## 4. 对照 B：合法 vs 截断（`valid` − `truncated`）

| 臂 | 种子 | Δ（ns） | 95% CI（ns） | 原始 p | truncated 均值（ns） | truncated 零值行 |
|---|---|---:|---|---:|---:|---:|
| m1unfixed | 31337 | +55437.8 | [55427.9, 55447.8] | 下溢为 0 | 23.2 | 0 |
| m1unfixed | 424242 | +55232.5 | [55225.3, 55239.6] | 下溢为 0 | 23.2 | 0 |
| m1unfixed | 7 | +55100.7 | [55089.8, 55111.7] | 下溢为 0 | 23.2 | 0 |
| m1fixed | 31337 | +54767.8 | [54754.4, 54781.2] | 下溢为 0 | 23.2 | 0 |
| m1fixed | 424242 | +55117.1 | [55102.5, 55131.7] | 下溢为 0 | 23.4 | 0 |
| m1fixed | 7 | +54947.7 | [54936.3, 54959.1] | 下溢为 0 | 23.1 | 0 |
| m5ref | 31337 | +29341.4 | [29335.1, 29347.7] | 下溢为 0 | 23.2 | 0 |
| m5ref | 424242 | +29294.1 | [29286.0, 29302.1] | 下溢为 0 | 23.3 | 0 |
| m5ref | 7 | +29321.8 | [29317.0, 29326.7] | 下溢为 0 | 23.2 | 0 |

`p` 是双精度下溢后原样打印的 `0`，**不得**解释为"精确零"；CI 已足够说明差异。
`truncated` 的耗时与**臂无关**（三臂都是 23.1–23.4 ns），说明它走的是封装层的长度检查，
在进入 KEM 之前返回。**这是接口语义的一部分，不是秘密相关泄漏**：长度是公开输入，
长度检查本来就该在常数时间内以固定路径拒绝。

## 5. 族外 online dudect

dudect 需要两个"都能跑完"的类，因此它测的是该入口自带的 **`message-zero` vs `message-ones`**
类对（不是本文件的 malformed/truncated 类对）；`valid` vs `truncated` 的 3 个数量级差已由
Welch 给出，不需要也不适合用 dudect 复核。

| 臂 | 种子 | 末批 `max |t|` | 状态 | 解释 |
|---|---:|---:|---|---|
| m5ref | 31337 | 1.35 | 1 | 预算内无证据 |
| m5ref | 424242 | 1.52 | 1 | 预算内无证据 |
| m5ref | 7 | 2.00 | 1 | 预算内无证据 |
| m1unfixed | 31337 | **10.78** | **0** | 触发上游 `>10` 阈值 |
| m1unfixed | 424242 | **11.43** | **0** | 同上 |
| m1unfixed | 7 | **12.02** | **0** | 同上 |
| m1fixed | 31337 | 1.12 | 1 | 预算内无证据 |
| m1fixed | 424242 | 2.05 | 1 | 预算内无证据 |
| m1fixed | 7 | 2.01 | 1 | 预算内无证据 |

M1 未修臂三次都越过上游阈值、已修臂三次都在 2.05 以下——这与 M1 既有结论
（`poly_frommsg` 的消息位分支在未修产物上存在、`982c762` 后消失）**同向**，
是族外印证，**不进 Holm、最大 t 不转伪 p**。

M1 两臂的 dudect 入口是新根内用仓库 `tools/historical_dudect.c` + 钉版
`third_party/dudect/src/dudect.h` 重建的等价入口
（未修 `3dfbab6e8b0da0a895d7d8eeae40f3d90aba8d21c4870a0b49802ccb2c3b96f2`、
已修 `525c1766483c14cc2d9ddb26d00a59afa3c50fe52f73fa32629e54940de657bf`），
种子由启动时环境变量 `HISTORICAL_DUDECT_SEED` 指定；M5 用冻结树既有
`platform_m5_dudect`（`3be87721…`）。

## 6. 为什么不进主检验

1. ML-KEM 的隐式拒绝**在设计上**就对任何解封装失败走完整 `Dec → Re-enc → 常数时间比较 →
   J(z‖c)` 路径；"密文被破坏"本身不应改变控制流长度。这条对照衡量的是
   **异常输入是否被均匀处理**，而不是秘密相关的泄漏。
2. 把它并入按秘密依赖组织的 Holm 家族，会用一条"分支存在性/输入合法性"的项
   去污染全族 α=0.05 的 FWER 解释。
3. `truncated` 走的是公开长度检查，其耗时差是**接口语义**；把它当"泄漏"会得到
   一个既不可利用、也没有机制含义的结论。

因此本页只给原始 p、Δ 与 95% CI，**不做 Holm**，也不改变 M1/M5 的任何既有家族判定。

## 7. 边界

人工构造输入，**不是上游 CVE**。"未检出"只说明该机、该编译产物、该类对、该样本预算下
没有额外的可区分路径，**不构成恒时证明**，也不给出总体误报率。不做密钥恢复，不运行 exploit demo。

## 8. 原始件索引

- `R03/<run-name>/<run-name>.csv[.gz]`：标准 measure 长表（3 类 × 10000 行）。
- `R03/<run-name>/<run-name>.meta`：工具与实现身份、窗口范围、逐类零值行数、输入摘要。
- `R03/<run-name>/controller/`：控制器落盘的频率快照与终态。
- `R03/<run-name>/entry-snapshot.txt`、`exit-snapshot.txt`：32 policy + `global boost` 的独立前后快照。
- `logs/status.log`：18 次运行的逐条结果与放行探针摘要。
- `stats/<run-name>-<对照名>/`：统计电池产物（`ci_welch.json`、`RESULT.md`、`input.sha256`）。
