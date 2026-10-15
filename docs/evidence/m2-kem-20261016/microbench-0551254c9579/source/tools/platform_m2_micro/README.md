# M2 除法热点微基准（poly_tomsg）

2026-10-16。本目录新增两个入口，用于冻结 PLAN §5 的条件微基准（`B06`）：

| 入口 | 作用 | 不做什么 |
|---|---|---|
| `m2_hotspot_microbench.c` | 逐次计时**一次** `pqcrystals_kyber768_ref_poly_tomsg`，按采集件协议落 CSV/meta | 不时间完整解封装、不做统计 |
| `m2_hotspot_qualification.c` | 证明微基准的热点输入/输出与"采集件同源码"的真实解密路径逐字节一致 | 不参与任何计时 |

构建模块是 `cmake/PlatformM2Micro.cmake`（独立模块；根构建不 `include()` 它，行为不变）。

## 1. 与冻结合同的关系

- 触发条件：端到端主类对 Holm 家族 m = 6 全部不拒绝（PLAN §5.1），已由主控记录在
  `docs/evidence/m2-kem-20261016/RESULT.md`。
- 窗口**只包除法热点**：`window_scope=one_poly_tomsg_call`（PLAN §5.2 点名的
  "上游 poly_tomsg 的消息压缩除法"）；不包 `mlkem_decapsulate`。
- 预算与三次运行表与 §3.1/§3.2 一致：每类 10000、预热 100、类对 `message-zero`/`message-ones`，
  输出六列表头与 `--format measure` 相同。
- 微基准是**单独标记的探索族**：独立 Holm、α = 0.05、RTLF 同 α = 0.01，
  不与端到端 p 合并，也不得用微基准阳性冒充端到端阳性（PLAN §5.3 分层报告）。

## 2. 命令行

```sh
m2_hotspot_microbench --class message-zero,message-ones --samples 10000 --seed 31337 \
    --warmup 100 --raw <新 CSV> [--meta <新 meta>] --run-id <id> \
    --public-key <pk.bin> --secret-key <sk.bin>
```

- `--class` 只接受已选消息类对 `message-zero` / `message-ones`（PLAN §2.1）；
  格式破坏密文类会被拒绝，避免落进别的分支。
- `--samples` 是**每类**行数，上限 20000；`--warmup` 默认 100、上限 10000。
- `--raw`/`--meta` 以 `wx` 新建，已存在即失败；`--meta` 缺省为 `<raw>.meta`。
- 进程不 fork、不 daemonize、不 setsid、不改 HOME、不写其它路径、不设 CPU 亲和性
  （meta 记 `cpu_affinity=not_pinned`、`frequency_control=not_configured`）。

## 3. 计时协议（与 collector-v2 同形）

```
clock_gettime(CLOCK_MONOTONIC) → atomic_signal_fence(memory_order_seq_cst)
    → 一次 pqcrystals_kyber768_ref_poly_tomsg(msg, poly) 
    → atomic_signal_fence(memory_order_seq_cst) → clock_gettime(CLOCK_MONOTONIC)
```

单位 ns，不扣读钟开销、不换算 cycles、不裁剪长尾。密钥读取、密文构造、热点输入推导、
类乱序（`SHAKE256(domain‖seed‖counter)` tag 4，与采集件同一份 `collector_inputs.c`）、
结果消费、CSV/meta 写盘、ELF 自哈希全部在窗口外。

## 4. 热点输入从哪里来，凭什么说它是真的

微基准的输入多项式由 **vendor `indcpa_dec` 的前缀逐调用一致**地推出（公开 API）：

```
polyvec_decompress(b, ct)                     // ct 前 960 字节
poly_decompress(v, ct + 960)                  // ct 后 128 字节
polyvec_frombytes(skpv, sk)                   // sk 前 1152 字节
polyvec_ntt(&b)
polyvec_basemul_acc_montgomery(&mp, &skpv, &b)
poly_invntt_tomont(&mp)
poly_sub(&mp, &v, &mp)
poly_reduce(&mp)                              // vendor indcpa_dec 在此处调用 poly_tomsg
```

资格入口用**链接期** `-Wl,--wrap=pqcrystals_kyber768_ref_poly_tomsg` 抓住
`mlkem_decapsulate` 真实路径喂给热点的那个多项式，与上面推导出的多项式
**逐字节比较**（512 B），并断言一次完整解封装只调用热点一次。
vendor 源文件保持只读：没有改名、没有补丁、没有重建。

另外两路交叉核对：

1. 公开 round3 KAT（`tests/vectors/kyber768_round3/PQCkemKAT_2400.rsp` 第一条
   `count = 0` 的 pk/sk/ct/ss）：`mlkem_decapsulate` 的共享秘密必须等于 KAT 的 `ss`，
   且该次解封装喂给热点的多项式与推导值逐字节一致。
2. 冻结采集件 `qualification-ordinary/smoke/main_u_seed31337.meta` 的
   `input_sequence_digest`（行序密文序列 SHA3-256）：用同一份 `collector_inputs.c`
   在同一 (seed, 类列表, 每类数量) 下重算，必须逐字节相同——即微基准测的输入序列
   与采集件当时的输入序列是同一批。

## 5. 构建

```sh
sh tools/platform_m2_micro/run_micro_build.sh <tree-root>
```

普通与 ASan/UBSan 两棵树；夹具、KAT 文件与冻结采集件 meta 的路径在脚本内固定为
`platform-m2kem-20261016-d75a4019/collector-v2-2e894561892a` 下的只读原件。
关键选项与采集件一致：`/usr/bin/clang-18`、`RelWithDebInfo`（`-O2 -g -DNDEBUG`），
vendor 另加 `-Oz -g -fno-vectorize -fno-slp-vectorize -DKYBER_K=3`。

> sanitizer 构建会把 vendor 的 `-Oz` 覆盖成 `-O1`，此时三个热点的 `div` 计数都变 0
> （与 `COLLECTOR_CONTRACT.md` §4 记录的限制相同）。sanitizer 产物只做内存/UB 资格，
> **不得**用于机制对照或计时。

## 6. 资格

```sh
sh tools/platform_m2_micro/run_micro_qualification.sh <tree-root>
```

覆盖：两臂 × 普通/动态的功能资格、跨臂转录逐字节一致、冻结采集件的公开 KAT、
12 条 CLI 准入（非法参数/未知类/格式破坏类/重复类/越界样本/错误密钥长度/已有输出路径）、
解锁冒烟与 `--format measure` 兼容性（用冻结 `platform_stats` 直接解析冒烟 CSV）。

冒烟数据在 `qualification-smoke/`，**未绑核、未锁频**（meta 记
`cpu_affinity=not_pinned`、`frequency_control=not_configured`），
其中的 ns 值不得用于任何统计、泄漏或性能结论，也不属于预注册家族。

## 7. 不构成的主张

- 微基准的 ns 差异只属于**微基准层**；它不能上推为端到端可区分性，也不能当作恒时性证明。
- 窗口只覆盖一次 `poly_tomsg`；`poly_compress` / `polyvec_compress` 虽在同一 ELF 里，
  但只在窗口外的输入构造阶段被调用一次。
- 未检出 ≠ 恒时；"两臂输出逐字节相同"只是本固定输入、本字节码上的等价，不是所有输入的一般等价。
