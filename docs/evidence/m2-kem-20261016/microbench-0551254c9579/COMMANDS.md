# M2 除法热点微基准：待 lead 执行的控制器命令

2026-10-16。子树 `/home/nss-marker/yhr/Cry/platform-m2micro-20261016-0551254c9579/`。
本文件只交命令与判据；微基准的**实际执行**由 lead 经唯一锁频控制器串行完成。
作者没有 sudo，因此没有自行运行控制器，也没有写任何频率、隔离或亲和性配置。

## 1. 触发与范围（按冻结 PLAN §5）

- 触发条件已满足：端到端主类对 Holm 家族 `m2_end_to_end_full_decaps_v1`（m = 6）全部不拒绝
  （见 `docs/evidence/m2-kem-20261016/RESULT.md` "本轮锁频端到端结果"一节）。
- 微基准**只包除法热点**：窗口内只执行一次 `pqcrystals_kyber768_ref_poly_tomsg`
  （PLAN §5.2 点名的"上游 poly_tomsg 的消息压缩除法"），不包完整解封装、不包其他函数。
- 微基准是**单独标记的探索族**：独立 Holm、α=0.05、RTLF 同 α=0.01，
  **不与端到端 p 合并**，也不得用微基准阳性冒充端到端阳性。

## 2. 固定对象

| 项 | 值 |
|---|---|
| 未修 ELF | `<MICRO>/build-ordinary/microbench/unfixed/m2_hotspot_microbench`，sha256 `984f6b071311b64d7872fa7b185e0e8096da4bc796347a7481b0729ddbbe3287` |
| 已修 ELF | `<MICRO>/build-ordinary/microbench/fixed/m2_hotspot_microbench`，sha256 `2daa017de53d6c139028fde8a6f4ce60a9c0ed0516c55384ee82f7420cde5289` |
| 热点符号 | `pqcrystals_kyber768_ref_poly_tomsg`（未修 1 个 `div`，已修 0 个；见 `disasm/`） |
| 源码 | `<MICRO>/source/`，是 `collector-v2-2e894561892a/source` 的逐字节副本（`diff -rq` 相同，`SOURCE_TREE.sha256` 593/594 项通过） |
| 编译器 | `/usr/bin/clang-18`（Ubuntu clang 18.1.3），`RelWithDebInfo`＝`-O2 -g -DNDEBUG`；vendor 另加 `-Oz -g -fno-vectorize -fno-slp-vectorize`，`-DKYBER_K=3` |
| 密钥夹具 | `<FROZEN>/qualification-ordinary/fixtures/{pk.bin,sk.bin}`（与端到端同一固定 key，只读） |

## 3. 运行表（顺序是预注册的一部分，不得改序）

| run-name | CPU | seed | 臂 | 顺序 |
|---|---:|---:|---|---|
| `m2-micro-s1-unfixed` | 2 | 31337 | unfixed | 1 |
| `m2-micro-s1-fixed` | 2 | 31337 | fixed | 2 |
| `m2-micro-s2-fixed` | 2 | 424242 | fixed | 3 |
| `m2-micro-s2-unfixed` | 2 | 424242 | unfixed | 4 |
| `m2-micro-s3-unfixed` | 6 | 31337 | unfixed | 5 |
| `m2-micro-s3-fixed` | 6 | 31337 | fixed | 6 |

每类 10000、预热 100；预算与 §3.2 一致。输出 CSV/meta 写在
`<MICRO>/runs/<run-name>/<arm>-main.{csv,meta}`（目录已建、文件必须不存在）。

## 4. 可直接复制的命令

六个 run 的完整命令在
`<MICRO>/run_controller_microbench.sh`（同一份内容的证据副本见本目录 `run_controller_microbench.sh`），整份复制执行即可。单个 run 的展开形态：

```sh
MICRO=/home/nss-marker/yhr/Cry/platform-m2micro-20261016-0551254c9579
FROZEN=/home/nss-marker/yhr/Cry/platform-m2kem-20261016-d75a4019/collector-v2-2e894561892a
FIXTURES=${FROZEN}/qualification-ordinary/fixtures
CONTROL=/home/nss-marker/yhr/Cry/platform-control-20261016-c011ec7a5e01
PLAN=/home/nss-marker/yhr/Cry/platform-collect-20261016-c011ec7a5e01/plans/m2-kem-PLAN.md
PLAN_SHA256=0f706455c6a8fde28ecd3dc18fb12ae4562c2f57dc7e2d991b5ff83c5cd07142

sudo -n /usr/bin/python3 -I -B ${CONTROL}/controller.py run \
    --control-root ${CONTROL} --run-name m2-micro-s1-unfixed --cpu 2 --timeout-seconds 300 \
    --plan ${PLAN} --plan-sha256 ${PLAN_SHA256} \
    -- ${MICRO}/build-ordinary/microbench/unfixed/m2_hotspot_microbench \
        --class message-zero,message-ones --samples 10000 --seed 31337 --warmup 100 \
        --raw ${MICRO}/runs/m2-micro-s1-unfixed/unfixed-main.csv \
        --meta ${MICRO}/runs/m2-micro-s1-unfixed/unfixed-main.meta \
        --run-id M2-micro-s1-unfixed-main \
        --public-key ${FIXTURES}/pk.bin --secret-key ${FIXTURES}/sk.bin
```

## 5. 运行后判据与核对

- 每个 run 有效 ⇔ `terminal.json` 满足 `reason=worker_finished`、`worker_exit_code=0`、
  `worker_drained=true`、`restore_match=yes`，且全局 active 指针消失（PLAN §7）。
- 另跑一次只读核对（不需要 sudo）：

```sh
sh ${MICRO}/verify_completed_micro_runs.sh ${MICRO}
```

它会逐份 CSV/meta 核对表头、行数、每类计数、`time_unit=ns`、`run_status=complete`、
`zero_elapsed_count=0`、热点不符计数 0、ELF 自哈希、以及同一 (seed, 类列表, 样本数) 下
`input_sequence_digest` 跨 run/跨臂一致。

### 已知注意项（如实记录，不隐藏）

1. **运行中频率采样条数会很少**：本微基准一次 run 的计时工作量只有
   20000 × ≈0.3 µs ≈ 6 ms（加输入摘要与写盘，worker 墙钟约 0.1 s 量级），
   而控制器按 50 ms 间隔采样，因此 `during.json` 只会拿到个位数样本。
   入窗前 20 次 50 ms 采样（`entry-probes.json`）与退出后快照不受影响，
   控制器的 ±2%/跨度放行判据也作用在入窗采样上。
   PLAN 明令禁止 sleep/随机延迟/空转，预算又是预注册固定的，
   因此**不得**为凑采样条数加长 worker；若 lead 判定采样条数不足，
   只能按 §6.2 走 PLAN 修订，不得改参数后重跑。
2. 微基准 CSV 与端到端 CSV **不可比**：窗口内容不同（一次热点 vs 一次完整解封装），
   两族 p 值也不得合并。
3. 已修臂 `poly_tomsg` 在 `poly_reduce` 之后仍可达的系数值 −2497 上与未修臂输出不一致
   （未修 bit=0、已修 bit=1，见 `disasm/NOTE-poly_tomsg-minus2497.txt`）。
   本微基准的两类输入（各 256 个系数）都不含该值，两臂输出逐字节相同，
   因此不影响本层结论；该观察只登记为固定产物上的机制事实。

## 6. 统计（微基准探索族，独立 Holm）

每份 CSV 一个**新**输出目录，冻结 `platform_stats` 与 RTLF：

```sh
STATS_BIN=/home/nss-marker/yhr/Cry/platform-s5-20261016-b4cd8480318c/build-v2/platform_stats
RTLF=/home/nss-marker/yhr/Cry/platform-m5-20261016-30efdf66eb26/source-v2/third_party/RTLF/rtlf.R
for run in m2-micro-s1-unfixed m2-micro-s1-fixed m2-micro-s2-unfixed m2-micro-s2-fixed \
           m2-micro-s3-unfixed m2-micro-s3-fixed; do
    arm=unfixed
    case "${run}" in *-fixed) arm=fixed ;; esac
    sh ${MICRO}/source/scripts/run_stats_battery.sh \
        --input ${MICRO}/runs/${run}/${arm}-main.csv --format measure \
        --classes message-zero message-ones --output-dir ${MICRO}/analysis/${run} \
        --stats-bin ${STATS_BIN} --rtlf-script ${RTLF}
done
```

Holm（m = 6、α 全族 0.05）与分层报告由 lead 按 PLAN §4.1/§5.2 汇总；
微基准族的 p 值与端到端族的 p 值**分开**保存，不合并。
