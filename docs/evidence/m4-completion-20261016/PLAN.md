# M4 人工比较夹具采数合同（本轮冻结版 v1）

- 模块 / 验收项：M4 提前退出/恒时意图比较校准 + 有界验证 / `E04`（前置 `E01`、`E02`、`E03`，后续 `E05`，
  可选 `E06`）。
- 冻结日期：2026-10-16（Asia/Shanghai）。
- 状态：**待主控本地提交后生效**。本文件在 `main` 上的提交是本轮采数的唯一授权前提（CMD07）。
- 上位文件：`docs/platform/COMPLETION_REQUIREMENTS.md`（G03–G09、E01–E06）、
  `docs/evidence/m4-completion-20261016/{REQUIREMENTS,ENV,RESULT}.md`。
- 取代关系：本冻结版**取代**同目录 `STATISTICAL_PLAN_DRAFT.md` 中与之冲突的口径（该草案自述
  "未冻结、未采数"），特别是旧草案的"每变体 100000 次/类、三个进程、种子 2026101607/2026101707/
  2026101807、族 m=2"设计。旧草案文件保留原字节不改。
- 范围声明（`E04` 硬要求）：本夹具是**人工相等性比较夹具**，计时边界是
  **一次完整 `m4_compare_checked` 封装调用**（32 字节公开长度 + 内部内核），**不是完整 KEM**。
  报告不得把本夹具结果冒称 ML-KEM 端到端或完整解封装结论；`E06`（扩大 Binsec 到完整解封装）为可选。

---

## 1. 固定对象

### 1.1 源码与身份

| 项 | 固定值 |
|---|---|
| 本仓库基线提交 | `44c209af65546eb3df3bdf5b165f52a7ef76feab`（`main`，打包时 HEAD） |
| 被测夹具 | `fixtures/early_reject_memcmp/`（相对基线提交**无改动**）：`compare_early.c`（提前退出）、`compare_ct.c`（恒时意图）、`compare_checked.c`（封装边界）、`compare.h` |
| 采集工具 | `tools/platform_m4/measure.c`、`tools/platform_m4/inputs.c`、`tools/platform_m4/inputs.h` |
| 在线 dudect | `tools/platform_m4/dudect_online.c`（族外工具） |
| 形式 harness | `tools/platform_m4/binsec_harness.c`、`checkct_1_16.cfg`、`checkct_fixed16.cfg` |
| 源 v2 载体（实读） | `/home/nss-marker/yhr/Cry/platform-m4-20261016-6hRHRUxH/source-v2.tar.gz`，SHA-256 `860c49e9245e60a9854a894fc528760df62d5b29fa57f41deb9a13b8ce4ab057` |
| 源一致性 | 远端 `source-v2` 的 `measure.c`/`inputs.c`/`compare_early.c`/`compare_ct.c`/`compare_checked.c` 与当前本地工作树**逐字节相同**（T3 实读核对） |
| 工作物理根 | `<Cry>/platform-m4-20261016-6hRHRUxH`（`<Cry>` = `/home/nss-marker/yhr/Cry`） |

**语义要求**：两类公开人工输入的输出**同为"不相等"**，不得把返回值或日志分支差异当成泄漏；
不得跳过封装边界检查；不得添加 sleep、空转、随机延迟或运行期秘密输出。

### 1.2 编译器与选项

- 普通采集目标：ELF64/x86_64、`RelWithDebInfo`、`-O2 -g -DNDEBUG`、C11、**无 LTO**；
  CMakeCache 实读 `CMAKE_HOME_DIRECTORY=<旧根>/source-v2/tools/platform_m4`。
- 形式目标（`platform_m4_formal_{vulnerable,ct}`）：ELF32/i386、`-nostdlib`、freestanding，
  **只作分析件，绝不能当采集 ELF**。
- 构建/形式任务亲和性仅 CPU0/1（最多 j4）；CPU2/CPU6 仅由主控在采数时独占。
- 编译器：远端该树用 GCC 13.3.0（见 `ENV.md`），与 M2/M3/M5 的 Clang18 不同；本轮采集 ELF 由
  **T9 在 `source-v2` 上重建**（新增 `--compare-bytes N` 与 100 次预热），仍固定该编译器与
  `RelWithDebInfo -O2 -g -DNDEBUG`、C11、无 LTO，**不得**换编译器或换优化档后混用旧摘要。

### 1.3 采集用普通 ELF 的 SHA-256（实读）

| 角色 | 绝对路径（`<Cry>` = `/home/nss-marker/yhr/Cry`） | SHA-256 |
|---|---|---|
| **采集（开臂 `early-exit-memcmp-on`）** | `/home/nss-marker/yhr/Cry/platform-m4-20261016-6hRHRUxH/build-software-v3/platform_m4_measure_vulnerable` | `2686907893706372538855fa778bc7133cbed8fa0a8115c3dc57b124119b36c5` |
| **采集（关臂 `constant-time-compare-off`）** | `/home/nss-marker/yhr/Cry/platform-m4-20261016-6hRHRUxH/build-software-v3/platform_m4_measure_ct` | `90740bdf99125a2c37465c239617b6dadb344401e89b1830d24da88bd70be035` |
| 在线 dudect（族外工具） | `/home/nss-marker/yhr/Cry/platform-m4-20261016-6hRHRUxH/build-software-v3/platform_m4_dudect_vulnerable` | `42c64118b345fa1ffab3cbc5655aecb75b22aca9685724987d5e6a5ba619f7cf` |
| 在线 dudect（族外工具） | `/home/nss-marker/yhr/Cry/platform-m4-20261016-6hRHRUxH/build-software-v3/platform_m4_dudect_ct` | `3e9178668fece354beffa83431454bc64d0cf02c1ad379f72e508bc8f114a689` |
| 形式分析件（**禁止采集**） | `<Cry>/.../build-software-v2/platform_m4_formal_vulnerable` / `_ct` | `308190a7688f5757a1d354a8dffbb9c55cbbfaca027136befeabbae6e859180e` / `7f34c8764bffd07329db93edcb7f4564b5fbe1e686a7c0ee54468680d38c47c4` |
| **T9 前的只读基线（不用于采集）** | `<Cry>/.../build-software-v2/platform_m4_measure_vulnerable` / `_ct` | `2d311d38158dad66bdebf324b260e5b1be25be1d5477f611b9d87fae86bf7e0b` / `96e4ab3755c1d4bb13f97213d55bcc26958619fad0c72394bd168d0651a659fc` |

**T9 重建已完成（`build-software-v3/`，v2 未被覆盖）**：`tools/platform_m4/measure.c` 已加入
**`--compare-bytes N`（默认 32，取值 1..32）** 与**计时循环前固定 100 次预热（不计时、不写 CSV）**；
采集源码 `source-v3/tools/platform_m4/measure.c` SHA-256 `881ef2d2cb3f6f6a675c2495c1048a93436635c0e2c38aff0dce6d3f6b13f857`。
上表 v3 摘要由 `plans` 于 2026-10-16 远端**独立实读复核**（附录 A 有命令与原始输出）。
**dudect 摘要必须注明取自 v2 还是 v3 目录**：两目录整文件摘要不同（v2 `f674a5a0…`/`914d1ada…`
→ v3 `42c64118…`/`3e917866…`），但 `plans` 独立复核确认两臂 `.text` 节十六进制转储**逐字节相同**
（vulnerable `503ed601…`、ct `7427549b…`），即**代码未变、仅调试信息内嵌构建路径不同**
（source-v3 vs source-v2）；本合同统一**取 v3**，行为与 v2 无差别。
CTest：普通 7/7、sanitizer 7/7、0 failed（T9 实测）。

**`--compare-bytes` 的语义（已按本合同实现，`plans` 实读 v3 源码逐条复核）**：

1. `N` 是传给**内核** `m4_compare_bytes(secret, candidate, compare_length_bytes)` 的**比较窗口**；
   **ABI 长度恒 32**（数组仍 32 字节），没有把 16 当 ABI 长度传入，因此拿到的是**截断比较**，
   而不是"长度拒绝"（`compare_checked.c` 要求 ABI 长度恰为 32，否则返回 `-1`、不比较）。
2. `--describe` 已暴露 `abi_bytes=32`、`compare_bytes_default=32`、`compare_bytes_range=1..32`、
   `warmup_calls=100`、`truncation_rule=mismatch-last:equal_when_compare_bytes_lt_32`；
   meta 已写 `abi_bytes=32`、`compare_bytes=<N>`、`warmup_calls=100` 与每类**预期/实测相等次数**，
   且 `N != 32` 时 `boundary=truncated_compare_bytes`（`N=32` 仍为 `complete_checked_compare`），
   两条路径**可区分**。
3. 重建后采集相关 ELF（两臂 measure + 两臂 dudect）已全部重新实读，上表即为 v3 实读值。

**⚠️ 边界口径（必须写进 RESULT，不得省略）**：两条路径的**计时边界不同**——

- 主路径（`N=32`）：计时窗口是**完整 `m4_compare_checked`**（含入参校验）；
- 对照路径（`N<32`）：计时窗口是**内核 `m4_compare_bytes`**（不含封装层校验）——
  因为夹具的密码语义不允许改，截断只能在内核窗口上表达。

因此**跨长度/跨臂比较时间时不得当作"同一边界的两个长度"**：两者之差同时含"少一次封装层校验"
与"窗口变短"两个因素，只能作描述性说明（§2.3/§2.4），不得据此下泄漏结论。

实读命令与原始输出见文末附录 A。

### 1.4 采集工具链（固定）

| 项 | 固定值 |
|---|---|
| 频率/生命周期管理 | `tools/platform_control/controller.py`（唯一入口） |
| 统计电池 | `scripts/run_stats_battery.sh` |
| `platform_stats` | `<Cry>/platform-s5-20261016-b4cd8480318c/build-v2/platform_stats`，SHA-256 `ddc48b9ef92a010e9b804389cabc4089e042c814ac8af4b3fa89e541bf4ac9e2` |
| RTLF | `<Cry>/platform-m5-20261016-30efdf66eb26/source-v2/third_party/RTLF/rtlf.R`，SHA-256 `50e5d4e5239e492337a131afaf2d1e3c0fdcadbb902d5433d56eac2ead1bd04e` |
| Binsec | 0.11.3，commit `9749bd8aed7ee0a27959158b1e53e8789cb0e5ab`，SHA-256 `66700f833213d3c9a1eb6e5bc37dcd0cb6da3562d87b1601cb640c896c4f2183`（族外定位层） |
| Z3 | 4.15.3，SHA-256 `80ee070b8ffc2fa964b0b879250b2110c47f84c1256a1f9ab76fc7cf95e46292` |
| 主机 | `nss-m`，Linux `6.17.0-35-generic`，x86_64，AMD Ryzen 9 9950X 16-Core / 32 逻辑 CPU |

---

## 2. 类对与臂

### 2.1 臂（版）

| 臂名 | 定义（实读产物列 `implementation`） | 角色 |
|---|---|---|
| `early-exit-memcmp-on` | `platform_m4_measure_vulnerable`，CSV 列写 `m4-vulnerable`：`compare_early.c` 提前退出比较 | 被测机制臂 |
| `constant-time-compare-off` | `platform_m4_measure_ct`，CSV 列写 `m4-ct`：`compare_ct.c` 恒时意图比较 | **恒定控制臂**（constant control） |

两臂是**两个独立 ELF**；"开/关"不是同一 ELF 内的类开关。产物里**没有**这两个臂名字符串，
CSV 的 `implementation` 列是 `m4-vulnerable`/`m4-ct`；臂名只用于本合同的假设 ID 与报告。
关版是恒定控制：用于检验"目标机制被移除后同一类对是否仍出现同样差异"，把机制效应与环境漂移分开。
**两臂整体耗时差本身不是泄漏证据**（见 §2.4）。

### 2.2 主类对（进入主检验，**每臂各跑一次**）

**class0 = `mismatch-first`，class1 = `mismatch-last`**；效应量 `mean(mismatch-first) − mean(mismatch-last)`，双侧。

**选择依据（实读 `tools/platform_m4/inputs.c` / `measure.c --describe`）**：候选数组恒为 32 个 `0x5a`；
秘密数组仅第 0 字节（class 0）或第 31 字节（class 1）异或 1；两类输出同为"不相等"。
`--describe` 原文为
`module=M4 case=artificial_compare boundary=complete_checked_compare bytes=32 classes=mismatch-first,mismatch-last timing_collection=not_run`。
差异位置正是提前退出比较的**秘密相关**维度：第 0 字节差异走最短路径、第 31 字节差异走最长路径，
而恒时版本对两者应同样处理。每次调用前把 32 字节复制到**同一个工作数组**并使用**同一个候选数组**，
因此是"输入已触碰的同地址比较"合同，不把两套固定地址差异混入类对。

### 2.3 对照条件（**不进主检验**，每臂各跑一次）

M4 夹具**没有密文对象**，故 M2/M3 的尾部破坏构造在 M4 无对应物。主控裁定（2026-10-16）
T9 新增 `--compare-bytes N`，因此 M4 的对照条件是**真正的截断比较**：

- **对照条件 = `--compare-bytes 16`**：ABI 长度仍是 32（`m4_compare_checked` 的入口检查不变），
  但内核 `m4_compare_bytes` 的比较窗口截断到前 16 字节；**class0/class1 仍是
  `mismatch-first`/`mismatch-last`**（对照条件由**运行配置**区分，不引入新的类名）。
- **每个臂各跑一次**（开臂、关臂都要）。

**它不进主检验的理由**：`--compare-bytes 16` 改变的是**比较窗口这一公开配置**，
且 `mismatch-last` 的区别字节（第 31 字节）落在窗口之外，两类在窗口内的差异结构与主类对
（同一 32 字节窗口内由秘密差异位置决定提前退出路径长度）**不同源**；把它与主类对放进同一
Holm 家族，会用配置变更/窗口截断主导的效应污染专门检验秘密位置依赖的家族，使全族 α=0.05 的
FWER 解释失效。它只作**族外稳健性检查**，单独 CSV、单独目录、单独报告，不进 `holm.csv`。

> **阻断项已解除（T9 已实现并经 `plans` 实读复核）**：旧采集器对 `compare_status != 0 || is_equal != 0`
> 立即 break 并写 `collection_status=1`；在 `--compare-bytes 16` 下 `mismatch-last` 的区别字节
> （第 31 字节）落在窗口外、**预期就是相等**，旧语义会在第一个 `mismatch-last` 样本中止。
> T9 已把判据改为**「实际结果是否偏离本臂预期」**：`is_equal != expected_is_equal(class_label, N)`，
> 并补齐了本合同 §2.3 要求的可复核信息：
>
> - meta 写每类**预期/实测相等次数**：`expected_equal_count_{mismatch_first,mismatch_last}`、
>   `observed_equal_count_{mismatch_first,mismatch_last}`；
> - `--describe` 写 `truncation_rule=mismatch-last:equal_when_compare_bytes_lt_32`，
>   meta 写 `expected_result=mismatch-first:unequal,mismatch-last:equal|unequal`；
> - `N=32` 时两类预期都是"不等"，与旧判据**等价**（主路径默认行为不变）。
>
> T9 实测（`--compare-bytes 16`、100 calls/class、seed 20261016）：退出 0、`completed_calls=200`、
> **`collection_status=0`**、CSV 100+100 行、`observed_equal_count_mismatch_last=100/100`、
> `mismatch_first=0/0`；非法规格 `--compare-bytes 33`/`0` 退出 2 且不创建文件；同 seed 类序与旧版逐行相同。
> 因此对照臂**可以采数**，不再是 `not_implemented`。
> 不得把 `E03` 的 Binsec 分析模型边界（`0<length<17` / `=16`）当作采集对照臂。
> **时间对比必须带上 §1.3 的边界口径**：主路径量的是完整 `m4_compare_checked`，
> 对照路径量的是内核 `m4_compare_bytes`，两者边界不同，**不得当作"同一边界的两个长度"**。

### 2.4 跨臂对比（**家族外**，受控对照/工程一致性检验）

`early-exit-memcmp-on` 与 `constant-time-compare-off` 的整体耗时对比**单列为受控对照/工程一致性检验**：

- 它**含二进制级常数偏移**（两份 ELF 的代码布局、寄存器分配与指令序列不同），
  **不作为秘密相关泄漏的主证据**，**不进入任何 Holm 家族**；
- 它只回答"换臂后调用开销量级是否与定位/形式结论相容"这一工程问题；
- 不得用跨臂差异替代 §2.2 的臂内类对检验。

---

## 3. 三次运行与预算

### 3.1 复制（replication）表

| run | 类序种子（`SEED` 参数） | CPU | 臂顺序（合同的一部分） |
|---|---:|---:|---|
| `m4_r01` | 31337 | 2 | on → off |
| `m4_r02` | 424242 | 2 | off → on |
| `m4_r03` | 31337 | 6 | on → off |

- M4 的夹具输入**由构造固定**（候选恒 32×`0x5a`，秘密仅 1 字节不同），`--collect` 的 `SEED`
  是 **SplitMix64 类序种子**，不生成密码材料；本表的种子即该参数，取值范围 `[1, 2^64−1]`。
  该种子**不是**密码随机源，不得当作密钥/密文来源。
- 臂顺序交替是预注册的一部分，不得因观察结果改序；六个采集进程**顺序执行**，禁止并行占用 CPU2/CPU6。
- run1 与 run3 同种子、不同 CPU，用于区分"类序相关"与"CPU 相关"；**不得**把两个 CPU 称作两台独立机器。

### 3.2 预算

| 项 | 值 |
|---|---|
| CLI（T9 后） | `m4_measure --describe` \| `--collect NEW.csv CALLS_PER_CLASS SEED RUN_ID [--compare-bytes N]`（`N` 默认 32，取值 1..32） |
| 每类调用数 | **10000**（`CALLS_PER_CLASS ∈ [2, 1000000]`） |
| 每次采集产出 | **2 × 10000 = 20000** 行（相邻 pair 各含一类，成对平衡） |
| 主类对用量 | 每臂每 run 20000 行（`--compare-bytes 32`）；全轮 **3 run × 2 臂 × 2 类 × 10000 = 120000** 次完整封装调用 |
| 预热 | **100 次，T9 实现**：计时循环之前、窗口外执行，不计时、**不写 CSV**，meta 记预热次数（与平台协议一致） |
| 对照条件 | `--compare-bytes 16` 截断比较，每臂每 run 另跑 2 类 × 10000（族外；判定规则见 §2.3，**已由 T9 实现并实测通过**） |
| 输出 | `NEW.csv` + `NEW.csv.meta`；两者都用 `wx` 打开，**已存在即失败**（拒绝覆盖） |

- **窗口只包一次完整 `m4_compare_checked` 调用**：Linux 时钟 `CLOCK_MONOTONIC_RAW`、单位 `ns`；
  输入生成、分配、类序乱序、结果检查/消费、日志、CSV 保存与 I/O **全部在窗口外**；预热也在窗口外。
- **全量保留长尾**：不截尾、不删普通长尾、不扣读钟开销、不把 ns 换算成 CPU cycles。
- CSV 列固定 `run_id,implementation,input_category,sample_index,elapsed_nanoseconds,time_unit`，
  `implementation` 取 `M4_VARIANT_NAME`，实值 `m4-vulnerable` / `m4-ct`；对照运行的类名不变
  （仍 `mismatch-first`/`mismatch-last`），由 `--compare-bytes` 与 meta 区分。
- **中止语义（T9 v3 实读）**：判据是**「实际结果偏离本臂预期」**——
  `compare_status != 0 || is_equal != expected_is_equal(class_label, N)` 时立即 break、meta 写
  `collection_status=1`，部分完成数据**不得当成功**，必须按 §5.3 归档为失败。
  `N=32` 时两类预期都是"不等"，与旧判据等价，正常构造不会触发；
  `N<32` 时 `mismatch-last` 预期为"相等"，**预期的相等不是失败**（§2.3）。
- **边界口径（写进 RESULT）**：主路径窗口是完整 `m4_compare_checked`，对照路径窗口是内核
  `m4_compare_bytes`；两者边界不同，跨长度比较只能作描述，不得当作"同一边界的两个长度"（§1.3）。

---

## 4. 统计

### 4.1 独立 Holm 家族与 m 的推导

- 家族 ID：`m4_compare_arm_session_v1`。
- 家族成员：**在一次 run 的一个臂内**，对主类对做一次双侧 Welch 大样本正态近似参数检验
  `H0: mean(mismatch-first) − mean(mismatch-last) = 0`。
- **m = 3 run × 2 臂 = 6**（r01-on、r01-off、r02-off、r02-on、r03-on、r03-off）。
  推导：2 臂按 §2.1 定义，每臂在每次运行各产生一个主类对检验，故成员数 = 运行数 × 臂数 = 3 × 2。
- **α（全族）= 0.05**。Holm 逐步法：`p_(k) ≤ 0.05/(6 − k + 1)`，首次不拒绝即停止后续拒绝；
  原始 p、秩次、阈值、调整值与逐项判决全部保存。
- 每项报告：两类原均值/方差/样本数、SE、Welch t、自由度、**95% 大样本正态近似 CI**；
  明确为**正态近似口径，不是有限样本精确 Student-t**；CI 是单项描述区间，不冒称六项同时覆盖。
- 时序依赖/平稳性与独立采样前提必须另审：**未认证这些前提时只给条件性统计与同机描述**，
  不把名义 FWER 写成真实总体保证。零方差/缺失 run/null p/下溢原样保留，不得缩小家族数。
- 六项全部保留，**不得**只保留开臂、丢弃恒时控制臂。

### 4.2 明确写在 Holm 家族之外

- **RTLF：α = 0.01，bootstrap 种子 2026101605，族外。** 每份主类对 CSV 各执行一次；二值结果
  **不转换成连续 p、不进 Holm**；零值阻塞时保留原值与明确状态，**不当阴性**。
- **online dudect：族外。** `platform_m4_dudect_{vulnerable,ct}` 独立普通 ELF 与独立进程；
  调用钉版上游 `dudect_main`、真实 `MFENCE/RDTSC` 与原统计内核；固定预算（每批 20000 调用、
  固定 10 批、显式种子），**首个泄漏状态也继续到预算**并保留原日志；首批被上游用于预热/百分位。
  **最大 t 不得转换成伪 p，不得进入 Holm**；该窗口含上游计时/循环/回调边界，单列为工具交叉，
  **不与 ns CSV 混合**。离线回放与在线采集严格分列。
- **对照条件（§2.3：`--compare-bytes 16` 截断比较）与跨臂对比（§2.4）：一律族外**，
  只作描述性/工程一致性检查；对照运行单独 CSV、单独目录、**不并入** `holm.csv`，
  也不得与主类对合并成一个家族。
- **定位层与形式层**（Memcheck/ctgrind、Binsec）与统计层**分列，互不替代**：
  Binsec 结果只能在说明入口、长度、秘密/公开模型、探索边界与求解器状态的前提下写
  `insecure`/`secure`，且**不是**任意长度、完整算法或所有微架构上的恒时证明。

### 4.3 与旧草案的差异（需主控知悉）

旧 `STATISTICAL_PLAN_DRAFT.md` 拟"每变体 100000 次/类、三个进程、种子 2026101607/2026101707/
2026101807、正式族基于第一个预定进程（m=2）"。本冻结版按主控本轮固定参数改为
"**3 run（31337/CPU2、424242/CPU2、31337/CPU6）× 2 臂、每类 10000、族 m=6、族 α=0.05**"，
并新增家族外对照类对与跨臂受控对照。旧草案未执行、无样本，故不产生数据作废；其 m、α 与种子
不得与新合同混引。

---

## 5. 停止、复测与失败归档

### 5.1 停止规则（任一命中即停止，不进采数或立即中止）

- 本 PLAN 未提交，或提交后内容与执行清单不符；采集 ELF 的 sha256 与 §1.3 使用时的实读值不符；
- 把形式分析件（`platform_m4_formal_*`）当采集 ELF 使用；
- 软件资格失败：普通/ASan 各自 CTest、`--describe`、输入生成与参数拒绝；
- 夹具语义被破坏（跳过封装边界检查、让两类输出不等价、添加 sleep/空转/随机延迟/秘密输出）；
- **主路径**：`collection_status != 0`（实际结果偏离本臂预期）；
- **对照条件（`--compare-bytes 16`）**：实际结果偏离 T9 冻结的预期规则（§2.3），
  或 meta 缺 `expected_equal_count_*`/`observed_equal_count_*`/`boundary=` 字段；
- 远端路径越出 `<Cry>` 物理边界或符号链接越界；
- 频率/恢复合同未成立（§6 任一硬条件不满足）；
- 数据不完整（行数、类别数、表头、`time_unit` 不符）或进程异常退出；
- 出现密钥恢复、exploit、外部秘密类操作。

### 5.2 复测规则

- **不得**因显著性或未显著而增样、追加种子、补跑或挑选成功进程；不得看结果后换类对、改臂序、改阈值、
  或按旧草案的 3 进程/100000 方案混采。
- 复测只允许在"失败已归档 + 原因已定位 + PLAN 修订并重新提交"之后**另立新目录**进行；
  修订版必须写清新失败原因与新固定参数，不得改写旧结果。
- 复测数据不得与首轮合并成更大族凑显著性；`E06`（扩大 Binsec 到完整解封装或增加真实 TLS/KEM 案例）
  为**可选**，不作为复测借口，也不免除 `E03` 的小边界实跑。

### 5.3 失败归档规则

- 失败原件**先归档再重跑**：把原始 CSV、meta、日志、控制/恢复日志按**原字节**复制到
  `failed/<run_id>/`，写 `MANIFEST`（来源路径、摘要、失败原因、时间）；归档完成才允许启动新运行。
- 失败运行**不计入**家族成员数，也不从结果里消失：RESULT 必须列出已归档的失败尝试。
- 部分完成数据一律标 `incomplete/failed`（含 `collection_status=1` 的中止），不得当成功样本使用。

---

## 6. 频率与恢复（G05）

- 唯一串行任务：全程由 `tools/platform_control/controller.py run` 持有既有 `Cry/partition-admin.lock`
  与控制根 `collection.lock`；换 CPU、换控制根、`recover` 互斥；CPU2/CPU6 不与其他模块采数重叠。
- **boost = 0**（全局）；目标 singleton policy 的 **governor = performance、EPP = performance**、
  **min = max = 4300000 kHz**（CPU2 或 CPU6）。
- **taskset 亲和性**由控制器建立独立进程组并记录实际亲和性；worker 不得 fork/daemonize/自建 session。
- **三次频率快照**：**进入前**、**运行中**、**退出后**各一次，保存全部可见 policy 控制值与身份、
  全局快照与逐字段回读；运行中另有 20 次 50 ms 间隔采样（均须在目标 ±2% 且跨度 ≤ 50000 kHz 才放行）。
- **`restore_match=yes` 才算有效**：`terminal.json` 成功需同时满足 `reason=worker_finished`、
  `worker_exit_code=0`、`worker_drained=true`、`restore_match=yes`，且全局 active 指针消失；
  任一不满足该 run 无效。
- 异常退出**必须恢复**原配置后才能继续；恢复失败保留 active 阻断，由主控走独立 `recover`，**不自动重跑**。
- 请求频率与可见配置匹配**不等于**逐调用恒频或物理误差界；本模块 `restore_match` 对构建/形式阶段
  不适用（见 `ENV.md`），但**采数阶段必须满足**。
- 全部原件、缓存、临时目录、日志与分析只在 `<Cry>` 物理边界内。

---

## 7. 执行入口（主控串行，固定形态）

```sh
sudo -n /usr/bin/python3 -I -B <控制根>/controller.py run \
    --control-root <控制根> --run-name m4-r01-vulnerable --cpu 2 --timeout-seconds <T> \
    --plan <控制根>/PLAN.md --plan-sha256 <冻结PLAN的SHA256> \
    -- /home/nss-marker/yhr/Cry/platform-m4-20261016-6hRHRUxH/build-software-v3/platform_m4_measure_vulnerable \
        --collect <新目录>/m4_r01_vulnerable.csv 10000 31337 m4_r01_vulnerable --compare-bytes 32
```

族外对照臂（判定规则已由 T9 实现并实测通过，见 §2.3）同形，只改
`--run-name`/输出路径/`--compare-bytes 16`：

```sh
    -- /home/nss-marker/yhr/Cry/platform-m4-20261016-6hRHRUxH/build-software-v3/platform_m4_measure_vulnerable \
        --collect <新目录>/m4_r01_vulnerable_cmp16.csv 10000 31337 m4_r01_vulnerable_cmp16 \
        --compare-bytes 16
```

```sh
scripts/run_stats_battery.sh --input <原CSV> --format measure \
  --classes mismatch-first mismatch-last --output-dir <新目录> \
  --stats-bin <§1.4 platform_stats> --rtlf-script <§1.4 rtlf.R>
```

- 每个 (run, 臂) 一个**新** run-name、一个**新**输出目录；已存在文件必须失败。
- 主控另输出 `holm.csv`（假设 ID、原始 p、秩次、阈值、调整值、判决），不改写统计电池的单项结果。
- 跨臂对照另用独立目录与独立输出，**不并入** `holm.csv`。
- 对照条件（`--compare-bytes 16`）的 CSV 仍用同一对类名分析，但必须用**另一个**输出目录，
  且 **不并入** `holm.csv`：

```sh
scripts/run_stats_battery.sh --input <对照CSV> --format measure \
  --classes mismatch-first mismatch-last --output-dir <对照新目录> \
  --stats-bin <§1.4 platform_stats> --rtlf-script <§1.4 rtlf.R>
```
- 对照条件（`--compare-bytes 16`）单独采集、单独分析，**不并入**主族与 `holm.csv`；
  其 `--run-id`/输出路径必须与主路径不同，避免覆盖。
- `<T>` 由主控准入时按实测设定；若 CTest/资格失败或 `collection_status != 0`，按 §5.3 归档。

---

## 8. 三句结论模板（RESULT 必须逐字回答）

1. **定位**：本夹具在**定位层**（Memcheck/ctgrind 秘密标记、实际机器码）与**形式层**
   （Binsec `-checkct`：入口、32 字节/长度 1–16 模型、depth/timeout、halt/pending/截断/unknown、
   反例地址与源行）分别显示什么；明确 `secure` 的模型边界。
2. **统计**：本合同的 6 项臂内主类对 Welch 检验与 Holm（α=0.05）**实际**给出什么
   （开臂与恒时控制臂都必须逐项列出，含未检出与失败项）；RTLF（α=0.01）与 online dudect 作为
   族外工具各给出什么；跨臂受控对照的量级为何。
3. **边界**：本夹具**不是完整 KEM**，计时边界只是一次完整 `m4_compare_checked` 调用；
   结论只覆盖本固定输入、本机、本预算与本产物；**不可区分 ≠ 恒时证明**，
   Binsec 的 `secure` 不是任意长度/所有微架构的恒时证明，跨臂差异含二进制级常数偏移、不作泄漏主证据。

---

## 附录 A：ELF sha256 实读记录

实读时间：2026-10-16 02:0x–02:2x（CST），操作者 `plans`（task-7），**只读，未写入远端**。
本节含两段：(A) T9 之前的只读基线（v2）；(B) T9 重建后的 v3 **独立复核**（采集用 ELF 即取此段）。
两段都保留在同一棵物理根内，v2 未被覆盖。

**(A) T9 前基线（v2，不用于采集）** —— 命令（原始，逐字）：

```sh
ssh -o ControlPath=/Users/yin/.ssh/cm-cry-nss.sock nss-marker@10.144.144.5 \
  'cd /home/nss-marker/yhr/Cry && sha256sum \
     platform-m4-20261016-6hRHRUxH/build-software-v2/platform_m4_measure_vulnerable \
     platform-m4-20261016-6hRHRUxH/build-software-v2/platform_m4_measure_ct \
     platform-m4-20261016-6hRHRUxH/build-software-v2/platform_m4_dudect_vulnerable \
     platform-m4-20261016-6hRHRUxH/build-software-v2/platform_m4_dudect_ct'
```

原始输出（逐字）：

```text
2d311d38158dad66bdebf324b260e5b1be25be1d5477f611b9d87fae86bf7e0b  platform-m4-20261016-6hRHRUxH/build-software-v2/platform_m4_measure_vulnerable
96e4ab3755c1d4bb13f97213d55bcc26958619fad0c72394bd168d0651a659fc  platform-m4-20261016-6hRHRUxH/build-software-v2/platform_m4_measure_ct
f674a5a09d60cce58ace75c76055416e13948c7850b5cf0a96cc26cd43e600e4  platform-m4-20261016-6hRHRUxH/build-software-v2/platform_m4_dudect_vulnerable
914d1ada3ada89fc7457bf5474642718ad53d1a9ab3c2fe027baf435f521c5e4  platform-m4-20261016-6hRHRUxH/build-software-v2/platform_m4_dudect_ct
```

**(B) T9 v3 复核（采集用，`plans` 独立实读）** —— 命令（原始，逐字）：

```sh
ssh -o ControlPath=/Users/yin/.ssh/cm-cry-nss.sock nss-marker@10.144.144.5 \
  'cd /home/nss-marker/yhr/Cry/platform-m4-20261016-6hRHRUxH && sha256sum \
     build-software-v3/platform_m4_measure_vulnerable \
     build-software-v3/platform_m4_measure_ct \
     build-software-v3/platform_m4_dudect_vulnerable \
     build-software-v3/platform_m4_dudect_ct \
     source-v3/tools/platform_m4/measure.c; \
   echo "=== v2 dudect/original still present ==="; \
   sha256sum build-software-v2/platform_m4_dudect_vulnerable build-software-v2/platform_m4_dudect_ct \
             build-software-v2/platform_m4_measure_vulnerable'
```

原始输出（逐字）：

```text
2686907893706372538855fa778bc7133cbed8fa0a8115c3dc57b124119b36c5  build-software-v3/platform_m4_measure_vulnerable
90740bdf99125a2c37465c239617b6dadb344401e89b1830d24da88bd70be035  build-software-v3/platform_m4_measure_ct
42c64118b345fa1ffab3cbc5655aecb75b22aca9685724987d5e6a5ba619f7cf  build-software-v3/platform_m4_dudect_vulnerable
3e9178668fece354beffa83431454bc64d0cf02c1ad379f72e508bc8f114a689  build-software-v3/platform_m4_dudect_ct
881ef2d2cb3f6f6a675c2495c1048a93436635c0e2c38aff0dce6d3f6b13f857  source-v3/tools/platform_m4/measure.c
=== v2 dudect/original still present ===
f674a5a09d60cce58ace75c76055416e13948c7850b5cf0a96cc26cd43e600e4  build-software-v2/platform_m4_dudect_vulnerable
914d1ada3ada89fc7457bf5474642718ad53d1a9ab3c2fe027baf435f521c5e4  build-software-v2/platform_m4_dudect_ct
2d311d38158dad66bdebf324b260e5b1be25be1d5477f611b9d87fae86bf7e0b  build-software-v2/platform_m4_measure_vulnerable
```

**(C) dudect `.text` 不变性的独立复核**（用于支持"仅调试信息路径变化、代码未变"）：

```sh
ssh -o ControlPath=/Users/yin/.ssh/cm-cry-nss.sock nss-marker@10.144.144.5 \
  'cd /home/nss-marker/yhr/Cry/platform-m4-20261016-6hRHRUxH && for a in vulnerable ct; do \
     for v in v2 v3; do printf "%s %s .text hexdigest: " "$v" "$a"; \
       readelf -x .text build-software-$v/platform_m4_dudect_$a | grep -v "^$" \
         | sed "s/0x[0-9a-f]*//g" | sha256sum | cut -c1-32; done; done'
```

原始输出（逐字）：

```text
v2 vulnerable .text hexdigest: 503ed6015ada2ac313f141a197ea15a8
v3 vulnerable .text hexdigest: 503ed6015ada2ac313f141a197ea15a8
v2 ct .text hexdigest: 7427549b1f50cd7d65fa01c8cebd5063
v3 ct .text hexdigest: 7427549b1f50cd7d65fa01c8cebd5063
```

形式分析件摘要 `308190a7…`/`7f34c876…` 取自 `docs/evidence/m4-completion-20261016/ENV.md`
（本 PLAN 未直接复核）。补充实读（源载体与工具）：

```sh
sha256sum /home/nss-marker/yhr/Cry/platform-m4-20261016-6hRHRUxH/source-v2.tar.gz
# 860c49e9245e60a9854a894fc528760df62d5b29fa57f41deb9a13b8ce4ab057
sha256sum /home/nss-marker/yhr/Cry/platform-s5-20261016-b4cd8480318c/build-v2/platform_stats
# ddc48b9ef92a010e9b804389cabc4089e042c814ac8af4b3fa89e541bf4ac9e2
sha256sum /home/nss-marker/yhr/Cry/platform-m5-20261016-30efdf66eb26/source-v2/third_party/RTLF/rtlf.R
# 50e5d4e5239e492337a131afaf2d1e3c0fdcadbb902d5433d56eac2ead1bd04e
```

## 附录 B：待定项清单

| 项 | 状态 | 处置 |
|---|---|---|
| 采集两臂 ELF 摘要 | **已冻结（`plans` 独立复核）** | `build-software-v3/platform_m4_measure_{vulnerable,ct}`，`2686907893706372538855fa778bc7133cbed8fa0a8115c3dc57b124119b36c5` / `90740bdf99125a2c37465c239617b6dadb344401e89b1830d24da88bd70be035` |
| 对照条件 `--compare-bytes 16` 的判定规则 | **已实现并实测通过**（§2.3） | 判据 = 实际结果偏离本臂预期；meta 有预期/实测相等次数与 `boundary=`；**不再是 `not_implemented`** |
| `<T>` | 待定 | 单进程管理上限（秒），主控准入时按实测设定 |
| 在线 dudect 具体批次/种子 | 待主控确认 | 本 PLAN 只冻结"每批 20000、固定 10 批、族外、原日志保留"；显式种子由主控在准入时固定 |

**本模块待填 ELF 占位符共 0 个**：两臂采集 ELF、两臂 dudect 与采集源码摘要均已实读填实（附录 A），
对照条件所需能力已由同一 ELF 的 `--compare-bytes` 提供（无需额外产物）。

## 附录 C：被取代的旧 PLAN 原文（逐字保留，便于追溯）

本目录原 `PLAN.md`（"M4 完成轮：非计时验证与软件准备计划"）在本冻结版写入时**已被取代**。
该目录整棵为未跟踪新目录、无 Git 历史，故在此逐字保留原文；**其"不允许启动时间采样"的限定只适用于
旧的软件准备阶段，本轮采数授权以本文件正文为准**。

```markdown
# M4 完成轮：非计时验证与软件准备计划

日期：2026-10-16。基础提交 `ac46e625c5c8e0db239f95b2464c9eaa6f55bf72`。本轮新目录独立于上轮已提交证据，旧比较夹具保持原字节。

本路允许实际执行 Binsec 有界验证、构建和无计时输入/参数自检；**不允许启动时间采样、在线 dudect 的测量模式或调频**。统计合同在 `STATISTICAL_PLAN_DRAFT.md`，主控须冻结具体提交、源/产物摘要及控制器合同后另行采集。

形式验证目标为既有 `compare_early.c` 与 `compare_ct.c` 的 `m4_compare_bytes`。新无 libc 的 32 位 Linux ELF harness 以 `m4_entry` 为入口，在 `m4_halt` 入口停止；避免依赖未安装的 multilib libc 和 x86_64 解码插件。秘密为 16 字节 `m4_secret_input`，公开为 16 字节 `m4_public_input` 和 `m4_public_length`，具体栈指针。第一合同是公开长度 1–16；若工具或路径预算不足，独立执行固定长度 16 的备用合同，结果不互相替代。

Binsec 使用实际固定版本和求解器，记录源码提交、下载摘要、版本、license、入口、配置脚本、ELF/反汇编和完整输出。每份合同用 `-sse -checkct -sse-depth 10000 -sse-timeout 120 -smt-timeout 5`，每次保留新的输出目录。记录到达 halt 数、pending、深度截断、solver unknown/timeout；只有无泄漏且完整探索才允许写该模型内 secure。找到泄漏可以写 insecure，即便另有探索缺口也必须保留。

预期提前退出存在秘密控制流、归约版本在小边界通过，均为待检假设。结果不构成任意长度、完整 KEM 或物理时间恒定证明；不存在密钥恢复或 exploit。

所有远端项目文件、依赖源码、工具、日志、缓存、OPAMROOT、本地 switch、临时及恢复快照只存于真实物理根 `/home/nss-marker/yhr/Cry/platform-m4-20261016-6hRHRUxH`。不改 HOME，不安装系统包，不用默认 Docker 层，不关闭共享 SSH；构建/验证仅用 CPU0/1、最多 j4。CPU2/CPU6 的锁频采数只由主控串行安排。旧 M1 vendor、所有已提交证据和 `sources/` 只读。
```