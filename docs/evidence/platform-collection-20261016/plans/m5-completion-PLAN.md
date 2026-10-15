# M5 原生完整解封装时序采数合同（本轮冻结版 v1）

- 模块 / 验收项：M5 阴性对照 / `C03`（前置 `C01`、`C02`，后续 `C04`、可选 `C05`）。
- 冻结日期：2026-10-16（Asia/Shanghai）。
- 状态：**本轮冻结版**，待主控本地提交后生效。本文件在 `main` 上的提交是本轮采数的唯一授权前提（CMD07）。
- 上位文件：`docs/platform/COMPLETION_REQUIREMENTS.md`（G03–G09、C01–C05）、
  `docs/evidence/m5-completion-20261016/{REQUIREMENTS,ENV,RESULT}.md`、`vendor/mlkem-native/PIN.md`。
- 取代关系：本冻结版**取代**本目录 2026-10-16 早先的 PLAN 草案（"M5 原生定位与时序确认计划 v1"）。
  旧草案的资格/定位结论继续有效且不改字节，但其第 3 节"留给主控的正式采集合同"中与本文件冲突的
  家族成员数、控制类对与预算，一律以本文件为准。旧版本内容仍可从 Git 历史读取。

---

## 1. 固定对象

### 1.1 源码与身份

| 项 | 固定值 |
|---|---|
| 上游 | `pq-code-package/mlkem-native`，完整提交 `b3ba7b32773e657dd37f6f87bce82528459ad8a4`，根 Git tree `4cb8a67933a7f357e0f7b0dd45c0c6916050038d` |
| 上游归档 SHA-256 | `6a0dbe157c3cc94f79bc6a6c79ad53707600c40885f16107205a2a2836d81caa`（126/126 文件逐字核对通过） |
| 快照清单 SHA-256 | `b451e5ca0c897f7ae7249b954f4f10ab0863e6af509141a29fb3b65b125a377f` |
| 许可证 | 库源码 Apache-2.0 OR ISC OR MIT；文档 CC-BY-4.0；逐文件 SPDX 保持原件 |
| 本仓库基线提交 | `44c209af65546eb3df3bdf5b165f52a7ef76feab`（打包时 HEAD） |
| 源身份口径 | **工作区完整 verified source export**，413 个普通源/测试/构建/计划文件；**不能冒称单一 Git 提交** |
| 源码载体（实读） | `/home/nss-marker/yhr/Cry/platform-m5-20261016-30efdf66eb26/source-upload-v2.tar.gz`，SHA-256 `6c598f7ecfffac2d6737561af343dce9805da68b320fb8c595825d8a30bdc52d` |
| 使用命名空间 | `baseline_native`，`include/baseline_config.h` 不变；**不应用**任何 vulnerable/hardened/deployable 人工补丁 |
| 固定参数 | ML-KEM-768（FIPS 203）、portable C 后端、内置 portable FIPS202、关闭上游随机 API |

M5 是**阴性对照**：对象必须是**未打补丁的 portable reference 路径**。任何人工变体（`hardened`、
`deployable`、`encoder_branch`、`encoder_mask` 等）都**不是** M5，禁止混入本轮 M5 采集。

### 1.2 编译器与选项

- 编译器：Ubuntu Clang `18.1.3`，`/usr/bin/clang-18`；CMake `3.28.3`。
- 普通采集构建 `build-v2-ordinary`：C11、`RelWithDebInfo`、`-O2 -g -DNDEBUG`、无 LTO、portable reference。
- sanitizer 构建 `build-v2-sanitize`：ASan+UBSan、`-O1 -g`；**只作功能资格，不得作计时或 Valgrind 产物**。
- `build-ordinary`/`build-sanitize`（v1）为首次资格产物；本轮采集统一使用 **v2 普通产物**。
- 采集工具自身不写频率、不写亲和性、不写隔离配置。

### 1.3 采集用普通 ELF 的 SHA-256

| 角色 | 绝对路径（`<Cry>` = `/home/nss-marker/yhr/Cry`） | SHA-256 |
|---|---|---|
| **采集主 ELF** | `<Cry>/platform-m5-20261016-30efdf66eb26/build-v2-ordinary/reference/measure` | `4ff0956ac79550bc62caa0ea8d88968d3de8a926aebace9535481cb232145fa8` |
| 在线 dudect（族外工具） | `<Cry>/platform-m5-20261016-30efdf66eb26/build-v2-ordinary/platform_m5_dudect` | `3be8772155774ad7cbcdc3ca1633d282f6209bfc5a6964eb60d7d705f902f77d` |
| poison 定位（**非采集**） | `<Cry>/platform-m5-20261016-30efdf66eb26/build-v2-ordinary/platform_m5_poison` | `586c2d65bbb6d0ea04c4f027e29d3a2e9c8fe207965817bb67813061a6c4d6d0` |
| 参考静态库 | `<Cry>/.../build-v2-ordinary/reference/libmlkem.a` | `ed9a658183562a88a96a631602cdcdd137d4bb405bd224fc2ac8cf682514416a` |

**对照类对不需要额外 ELF**：它是同一次 `reference/measure` 调用所产出 CSV 中的
`bit-flipped`/`random` 两类子集（见 §2.2、§3.2）。**本模块没有待填的 ELF 占位符。**

采集 ELF `reference/measure` 的实读命令与原始输出见文末附录 A。
上游归档与快照清单摘要在 `docs/evidence/m5-mlkem-native-20261016/`，本文件不改其字节。

### 1.4 采集工具链（固定）

| 项 | 固定值 / 状态 |
|---|---|
| 频率/生命周期管理 | `tools/platform_control/controller.py`（唯一入口） |
| 统计电池 | `scripts/run_stats_battery.sh` |
| `platform_stats` | `<Cry>/platform-s5-20261016-b4cd8480318c/build-v2/platform_stats`，SHA-256 `ddc48b9ef92a010e9b804389cabc4089e042c814ac8af4b3fa89e541bf4ac9e2` |
| RTLF | `<Cry>/platform-m5-20261016-30efdf66eb26/source-v2/third_party/RTLF/rtlf.R`，SHA-256 `50e5d4e5239e492337a131afaf2d1e3c0fdcadbb902d5433d56eac2ead1bd04e` |
| 在线 dudect | 钉版上游 `third_party/dudect/src/dudect.h`；入口 `platform_m5_dudect --collect --seed N --raw NEW.csv` |
| 主机 | `nss-m`，Linux `6.17.0-35-generic`，x86_64，AMD Ryzen 9 9950X 16-Core / 32 逻辑 CPU |

动态定位（Memcheck/poison）结论只覆盖本固定路径、输入、编译器与工具能力；**无命中不等于恒时**，
且动态产物不得充当计时产物。

---

## 2. 类对

### 2.1 主类对（进入主检验）

**class0 = `message-zero`，class1 = `message-ones`**；效应量 `mean(message-zero) − mean(message-ones)`，双侧。
两类是同一固定测试 key 下两个显式选定消息的**合法 1088 字节密文**，由本仓库 reference 生成器制备；
每类重复同一密文（**不得**把 10000 次重复调用当作 10000 个不同密文或不同 key）。
`valid`/`bit-flipped`/`random` 三类作为功能/上下文数据完整保留，但**不进入本参数族**，也不因结果被替换。

### 2.2 对照类对（**不进主检验**）

**class0 = `bit-flipped`，class1 = `random`**（**原名使用，不得改名成 `malformed-*`**）。
两者都是共享 `measure` 已有的输入类：`bit-flipped` 是合法长度密文的内容被翻转，`random` 是随机内容密文；
两者都落进**隐式拒绝**路径。

**为什么不是"截断"**：本平台 ML-KEM-768 的密文在 API 层长度固定（1088 字节），
`mlkem_decapsulate` 入口先验长度，接口层**无法表达"截断密文"**——截断会在封装层被长度检查拒绝，
落不到完整解封装窗口。因此本轮对照条件取"**内容被破坏/随机的密文**"，不是截断。

**它不进主检验的理由**：该类对触发隐式拒绝/错误分支，其依赖来源是**密文内容被破坏**这一公开事实，
与主类对（重加密压缩路径上的**秘密消息编码**依赖）**不同源**；纳入同一 Holm 家族会用分支存在性/
噪声主导的对照项污染专门检验秘密依赖的家族，使全族 α=0.05 的 FWER 解释失效。
它只作**族外稳健性/链路灵敏度检查**，不进家族、不写进 `holm.csv`。

### 2.3 版（臂）

M5 只有**一个固定版本**：未打补丁的原生 portable reference（v2 普通产物）。

> **与主控通式的差异（需主控知悉）**：主控给出的通用预算式为"每模块 3 次运行 × **2 版** × 2 类 × 10000"，
> 该"2 版"适用于 M2（未修/已修）、M3（开/关）、M4（开/关）这类双臂模块。M5 按 `C01` 要求只保留
> 单一 reference 路径（阴性对照），**没有第二臂**；对应 `C05`（修后 liboqs ref 第二阴性）是**可选**项，
> 本轮不做，也不为凑"2 版"引入人工变体冒充阴性对照。因此本模块家族成员数为 **3**（见 §4.1）。

---

## 3. 三次运行与预算

### 3.1 复制（replication）表

| run | 测试 seed | CPU | 版本 |
|---|---:|---:|---|
| `m5_r01` | 31337 | 2 | reference（v2 普通） |
| `m5_r02` | 424242 | 2 | reference（v2 普通） |
| `m5_r03` | 31337 | 6 | reference（v2 普通） |

- 三个采集进程**顺序执行**，禁止并行占用 CPU2/CPU6；不得因观察结果改 seed/CPU/顺序。
- run1 与 run3 同 seed、不同 CPU，用于区分"seed 相关"与"CPU 相关"；**不得**把两个 CPU 称作两台独立机器。

### 3.2 预算

| 项 | 值 |
|---|---|
| CLI | `reference/measure RUN_ID SEED SAMPLES_PER_CATEGORY CSV_FILE META_FILE`（每类数量 1–20000） |
| 每类样本数 | **10000** |
| 每次运行产出 | **5 类 × 10000 = 50000** 行完整解封装（`valid/bit-flipped/random/message-zero/message-ones`） |
| 主类对用量 | 每 run 20000 行；3 run 共 **60000** 行 |
| 全轮正式调用 | **3 × 50000 = 150000** 次完整解封装 |
| 预热 | 每进程 **100 次**（`src/measure.c` 实读：计时循环前 100 次完整解封装），预热样本**不进 CSV**，meta 记 `warmup_decapsulations=100`；全轮 300 次 |
| 对照类对 | 同一 CSV 内的 `bit-flipped`/`random` 各 10000 行（**无需额外进程、无需额外 ELF**），族外分析 |

- **窗口只包一次完整 `mlkem_decapsulate`**：两个 `CLOCK_MONOTONIC` 纳秒读钟之间夹一次完整解封装，
  两侧 `atomic_signal_fence`；输入生成、分配、Fisher–Yates/SHAKE256 类别乱序、结果消费、日志与 I/O
  **全部在窗口外**。
- **全量保留长尾**：不截尾、不删普通长尾、不扣读钟开销、不把 ns 换算成 CPU cycles。
- CSV 表头固定 `run_id,implementation,input_category,sample_index,elapsed_nanoseconds,time_unit`，
  单位 `ns`；已存在文件必须失败（拒绝覆盖）。
- 同 seed 的输入与标签顺序可复现；不允许跨 run/seed/CPU 静默拼接 CSV。

---

## 4. 统计

### 4.1 独立 Holm 家族与 m 的推导

- 家族 ID：`m5_reference_end_to_end_v1`。
- 家族成员：**在一次 run 内**对主类对做一次双侧 Welch 大样本正态近似参数检验
  `H0: mean(message-zero) − mean(message-ones) = 0`。
- **m = 3 run × 1 版本 = 3**（r01、r02、r03 各一项）。推导：本模块只有单一 reference 臂（§2.3），
  每个 run 只产生一个主类对检验，故成员数等于运行次数 3。
- **α（全族）= 0.05**。Holm 逐步法：`p_(1) ≤ 0.05/3`、`p_(2) ≤ 0.05/2`、`p_(3) ≤ 0.05/1`，
  首次不拒绝即停止后续拒绝；原始 p、秩次、阈值、调整值、逐项判决全部保存。
- 每项报告：两类原均值/方差/样本数、SE、Welch t、自由度、**95% 大样本正态近似 CI**；
  明确为**正态近似口径，不是有限样本精确 Student-t**；CI 是单项描述区间，不冒称三项同时覆盖。
- 零方差/缺失 run/null p/下溢原样保留，**不得**缩小家族数或按零 p 伪造通过。
- 三项全部保留，不择取最显著的 seed/CPU。

### 4.2 明确写在 Holm 家族之外

- **RTLF：α = 0.01，bootstrap 种子 2026101605，族外。** 每份主类对 CSV 各执行一次；
  其**二值结果不转换成连续 p、不进 Holm**；零值导致 RTLF 阻塞时保留原值与明确状态，**不当阴性**。
- **online dudect：族外。** 每 run 一次、固定预算：每批 10000 次完整 decap、最多 **21 批**
  （首批为上游预热/分位阈值阶段，后 20 批正式），类顺序由公开 seed+batch 编号的 SHAKE256 独立域生成；
  保留上游原裁剪、二阶辅助检验与 `max|t| > 10` 阈值；**首个泄漏状态立即停止，不追加预算**。
  **最大 t 不得转换成伪 p，不得进入 Holm**；未交付/未执行即写 `blocked/not_run`。
- 对照类对（§2.2：`bit-flipped` vs `random`）同样**不进 Holm**，只作族外描述性检查；
  它取自同一份原 CSV，但必须单独输出、**不得**并入 `holm.csv`，也不得与主类对合并成一个家族。
- 离线回放与在线采集**严格分列**；若只做离线回放，不得称其为新的在线检验。

### 4.3 阴性一致性目标（事先固定，不是签收标准）

三项主 CI 均含 0 且 Holm 均不拒绝、RTLF 未检出、online dudect 预算内无证据、动态秘密标记/varlat
无未解释命中。任何阳性或失败都**如实保留并调查**，不得自动延长样本或更换类对。
该目标**不是**等价界、误报率或恒时认证。

---

## 5. 停止、复测与失败归档

### 5.1 停止规则（任一命中即停止，不进采数或立即中止）

- 本 PLAN 未提交，或提交后内容与执行清单不符；采集 ELF 的 sha256 与 §1.3 不符；
- 软件资格/独立 KAT 失败（NIST KAT、边界、随机源失败、CLI/向量拒绝、向量完整性）；
- 动态入口未实际 instrumented（必须报 `unavailable/77`，**不得**写 0 命中）；
- 链到人工变体（`hardened`/`deployable`/`encoder_*`）或非 reference 路径；
- 远端路径越出 `<Cry>` 物理边界或发现符号链接越界；
- 频率/恢复合同未成立（§7 任一硬条件不满足）；
- 数据不完整（行数、类别数、表头、`time_unit`、meta `run_status` 不符）或进程异常退出；
- 出现密钥恢复、exploit、外部秘密、sleep/延迟伪阳性类操作。

### 5.2 复测规则

- **不得**因显著性或未显著而增样、追加 seed、补跑或挑选成功进程；不得看结果后换类对、改顺序、改阈值。
- 复测只允许在"失败已归档 + 原因已定位 + PLAN 修订并重新提交"之后**另立新目录**进行。
- 复测数据不得与首轮合并成更大族来凑显著性；`C05`（第二阴性）属可选，不作为本模块复测借口。

### 5.3 失败归档规则

- 失败原件**先归档再重跑**：把原始 CSV、meta、日志、dudect 原日志、控制/恢复日志按**原字节**
  复制到 `failed/<run_id>/`，写 `MANIFEST`（来源路径、摘要、失败原因、时间）；归档完成才允许新运行。
- 失败运行**不计入**家族成员数，也不从结果里消失：RESULT 必须列出已归档的失败尝试。
- 部分完成数据一律标 `incomplete/failed`，不得当成功样本使用。

---

## 6. 频率与恢复（G05）

- 唯一串行任务：全程由 `tools/platform_control/controller.py run` 持有既有 `Cry/partition-admin.lock`
  与控制根 `collection.lock`；换 CPU、换控制根、`recover` 互斥。
- **boost = 0**（全局）；目标 singleton policy 的 **governor = performance、EPP = performance**、
  **min = max = 4300000 kHz**（CPU2 或 CPU6）。
- **taskset 亲和性**由控制器建立独立进程组并记录实际亲和性；worker 不得 fork/daemonize/自建 session。
- **三次频率快照**：**进入前**、**运行中**、**退出后**各一次，保存全部可见 policy 控制值与身份、全局快照
  与逐字段回读；运行中另有 20 次 50 ms 间隔采样（均须在目标 ±2% 且跨度 ≤ 50000 kHz 才放行 worker）。
- **`restore_match=yes` 才算有效**：`terminal.json` 成功需同时满足 `reason=worker_finished`、
  `worker_exit_code=0`、`worker_drained=true`、`restore_match=yes`，且全局 active 指针消失；任一不满足该 run 无效。
- 异常退出**必须恢复**原配置后才能继续；恢复失败保留 active 阻断，由主控走独立 `recover`，**不自动重跑**。
- 请求频率与可见配置匹配**不等于**逐调用恒频、隐藏 QoS 完整原状或物理误差界。
- 全部原件、缓存、临时目录、日志与分析只在 `<Cry>` 物理边界内；worker 用运行目录的 `worker/`、`tmp/`、`cache/`，
  不重设 HOME（`TMPDIR/TMP/TEMP/R_TMPDIR`、`XDG_CACHE_HOME` 已在 M5 根内）。

---

## 7. 执行入口（主控串行，固定形态）

```sh
sudo -n /usr/bin/python3 -I -B <控制根>/controller.py run \
    --control-root <控制根> --run-name m5-r01-ref --cpu 2 --timeout-seconds <T> \
    --plan <控制根>/PLAN.md --plan-sha256 <冻结PLAN的SHA256> \
    -- <Cry>/platform-m5-20261016-30efdf66eb26/build-v2-ordinary/reference/measure \
        m5_r01_reference 31337 10000 <新目录>/m5_r01_reference.csv <新目录>/m5_r01_reference.meta
```

```sh
scripts/run_stats_battery.sh --input <原CSV> --format measure \
  --classes message-zero message-ones --output-dir <新目录> \
  --stats-bin <§1.4 platform_stats> --rtlf-script <§1.4 rtlf.R>
```

族外对照（同一份原 CSV，**另一个**输出目录，结果不并入 `holm.csv`）：

```sh
scripts/run_stats_battery.sh --input <同一份原CSV> --format measure \
  --classes bit-flipped random --output-dir <对照新目录> \
  --stats-bin <§1.4 platform_stats> --rtlf-script <§1.4 rtlf.R>
```

- 每个 run 一个**新** run-name、一个**新**输出目录；已存在文件必须失败。
- `<T>` 由主控准入时按实测设定；单进程失败即按 §5.3 归档。
- **对照类对无需额外采集**：它取自同一份原 CSV 的 `bit-flipped`/`random` 两列类，
  用独立输出目录单独分析（族外），**不并入** `holm.csv`。

---

## 8. 三句结论模板（RESULT 必须逐字回答）

1. **定位**：本固定 reference 路径在动态秘密标记/varlat 与原生产物反汇编下是否出现未解释命中，范围与证据为何。
2. **统计**：本合同的 3 项主类对 Welch 检验与 Holm（α=0.05）**实际**给出什么（含未检出、含失败项），
   RTLF（α=0.01）与 online dudect 作为族外工具各给出什么。
3. **边界**：阴性只覆盖本固定输入、本机、本预算与本产物；**不可区分 ≠ 恒时证明**，
   未检出既不证明恒时也不证明总体误报率为零；M5 的阴性不能外推到人工变体或其他后端。

---

## 附录 A：ELF sha256 实读记录

实读时间：2026-10-16 02:0x（CST），操作者 `plans`（task-7），**只读，未写入远端**。

命令（原始，逐字）：

```sh
ssh -o ControlPath=/Users/yin/.ssh/cm-cry-nss.sock nss-marker@10.144.144.5 \
  'cd /home/nss-marker/yhr/Cry && sha256sum \
     platform-m5-20261016-30efdf66eb26/build-v2-ordinary/reference/measure \
     platform-m5-20261016-30efdf66eb26/build-v2-ordinary/platform_m5_dudect \
     platform-m5-20261016-30efdf66eb26/build-v2-ordinary/platform_m5_poison'
```

原始输出（逐字）：

```text
4ff0956ac79550bc62caa0ea8d88968d3de8a926aebace9535481cb232145fa8  platform-m5-20261016-30efdf66eb26/build-v2-ordinary/reference/measure
3be8772155774ad7cbcdc3ca1633d282f6209bfc5a6964eb60d7d705f902f77d  platform-m5-20261016-30efdf66eb26/build-v2-ordinary/platform_m5_dudect
586c2d65bbb6d0ea04c4f027e29d3a2e9c8fe207965817bb67813061a6c4d6d0  platform-m5-20261016-30efdf66eb26/build-v2-ordinary/platform_m5_poison
```

上述三项与 `docs/evidence/m5-completion-20261016/ENV.md` 记录的 v2 普通产物摘要逐一相符（独立复核）。
补充实读（源码载体与工具）：

```sh
sha256sum /home/nss-marker/yhr/Cry/platform-m5-20261016-30efdf66eb26/source-upload-v2.tar.gz
# 6c598f7ecfffac2d6737561af343dce9805da68b320fb8c595825d8a30bdc52d
sha256sum /home/nss-marker/yhr/Cry/platform-s5-20261016-b4cd8480318c/build-v2/platform_stats
# ddc48b9ef92a010e9b804389cabc4089e042c814ac8af4b3fa89e541bf4ac9e2
sha256sum /home/nss-marker/yhr/Cry/platform-m5-20261016-30efdf66eb26/source-v2/third_party/RTLF/rtlf.R
# 50e5d4e5239e492337a131afaf2d1e3c0fdcadbb902d5433d56eac2ead1bd04e
```

## 附录 B：待定项清单

| 项 | 状态 | 处置 |
|---|---|---|
| `<T>` | 待定 | 单进程管理上限（秒），主控准入时按实测设定 |
| 第二阴性臂（`C05`） | **本轮不做** | 可选；不引入人工变体充当 M5 对照 |

**本模块没有待填的 ELF sha256 占位符**：采集 ELF 与族外对照类对都已由 §1.3 的既有产物覆盖
（对照类对取自同一 CSV 的 `bit-flipped`/`random`）。
