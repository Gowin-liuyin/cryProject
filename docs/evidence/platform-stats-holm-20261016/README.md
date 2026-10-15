# platform_stats / platform_holm 软件证据（2026-10-16）

**定位**：本目录记录新增 C11 工具 `platform_holm` 的软件实现与测试证据。该工具把逐成员 p 值
组成**预注册 Holm 家族**并做**固定效应合并**，只读已有 CSV，不采集硬件、不接触密码内核，
因此实现只依赖标准库（`libm` 之外无第三方依赖）。

**结论**：普通配置 CTest `1/1` 通过，ASan/UBSan 配置 CTest `1/1` 通过；`format-check` 通过。
手算对照（Holm 完整表、p=0/p=1/m=1 边界、"前面已不拒绝则其后不拒绝"、等权与不等权固定效应）
全部在 1e-9 内一致，另有一份独立 Python 复算对随机语料逐值核对通过。

**边界**：这是 macOS/ARM 上的**软件功能与数值对照**证据。它不产生任何时序样本，不构成
R02/R04 的统计确认，也不证明任何实现的恒时性。RTLF 与 dudect 一律族外，最大 t 不得转伪 p。

---

## 1. 环境

| 项 | 实际值 |
|---|---|
| 主机 | macOS 26.6.2，Apple Silicon（`arm64`） |
| 编译器 | Apple clang 21.0.0（clang-2100.3.34.2），`Target: arm64-apple-darwin25.6.0` |
| 构建系统 | CMake/CTest 4.3.2 |
| 格式工具 | Apple clang-format 21.0.0（`xcrun --find clang-format`） |
| 语言口径 | C11，`C_EXTENSIONS OFF`，`-Wall -Wextra -Wpedantic -Wshadow -Wconversion -Wstrict-prototypes -Werror` |
| 普通配置 | `-DBASELINE_ENABLE_PLATFORM=ON -DA113_ARCHIVED_CASE_ONLY=OFF`（默认 RelWithDebInfo） |
| sanitizer 配置 | 同上加 `-DBASELINE_SANITIZERS=ON -DCMAKE_BUILD_TYPE=Debug` |
| 工作区状态 | HEAD `efca8a17d2633b5e8cd8b5e5b9f23e89723f00f3`，含其他协作者未提交改动（129 项）；本工具自身的改动未提交 |

摘要（本机本次构建的实际产物，换机后必须重算）：

| 文件 | SHA-256 |
|---|---|
| `tools/platform_stats/holm.c` | `32a2ece33754aadc2609e0efa247d07b5bd29b499cf821f073ca0f308b6356bc` |
| `tests/test_platform_holm.c` | `a034d0f22984e08e880d119dfe3a1706be2a6579b4c6e040add8580df652f719` |
| `cmake/PlatformStats.cmake` | `c97f582c07d298f32e42ea28e03f0df89da3e0e17e1bf66fb296981238492f76` |
| `build/holm/platform_holm` | `b15e6f0d91c13ca4b4055ceb8e146ffa16530ec063d61ded89c03a0cf04d6972` |
| `build/holm-sanitize/platform_holm` | `bbd3669a5c16b061f2264a192bf86f3aac37824dd28b63bb2488fb84e1834111` |

`build/` 只供本机编译，不作为证据；上面的二进制摘要只说明本轮实际跑的是哪两个 ELF/Mach-O。

## 2. 命令行合同

```
platform_holm --input <members.csv> --output-dir <NEW_DIR> --alpha 0.05
```

`--flag value` 与 `--flag=value` 都接受；三个参数都必须给出，多给或未知参数报用法错误。
`--output-dir` 只接受**已存在父目录下的、尚未存在的单个相对名字**（不带 `/`），
避免隐式递归建树，也让"目录已存在即失败"的判据不含歧义。

输入 CSV 表头逐字固定为：

```
family_id,member_id,mean0_ns,mean1_ns,sd0_ns,sd1_ns,n0,n1,p_two_sided,ci95_low_ns,ci95_high_ns
```

拒绝：CRLF 行尾、缺列、多余列、空行、重复表头、非数字字段、`p` 越出 `[0,1]`、
`sd < 0`、`n0 == 0`、`n1 == 0`，以及数值位置上出现的 `nan`/`inf`/十六进制浮点
（十进制口径只接受 `[0-9+-.eE]` 字符集）。`mean0/mean1/sd0/sd1/p/ci95_low/ci95_high` 按十进制
浮点读入，`n0/n1` 按非负十进制整数读入。

退出码：数据类错误固定为 `2`（含 `se == 0`、`n0 == 0`、`n1 == 0`）；用法、I/O、
输出目录已存在、写出失败为 `1`。**任何错误都不留下输出目录**：目录在全部计算成功之后才创建，
写出中途失败则删除已建文件并退回 `rmdir`。

## 3. 计算口径

Holm **step-down**：组内 p 升序排名 `k = 1..m`，阈值 `alpha/(m-k+1)`，
`adjusted_p(k) = max_{j<=k} min(1, (m-j+1)*p_j)`（前缀最大值保证单调不减），
`reject` 当且仅当 `adjusted_p <= alpha` **且前面所有排名也都 reject**（一旦不拒绝，其后全部不拒绝）。

固定效应合并（每个 `family_id` 一行）：

```
theta = mean0 - mean1
se    = sqrt(sd0^2/n0 + sd1^2/n1)
w     = 1/se^2
pooled    = sum(w*theta) / sum(w)
pooled_se = 1 / sqrt(sum(w))
ci95      = pooled +- 1.96 * pooled_se
Q  = sum(w*(theta - pooled)^2)     df = m - 1
I2 = (Q > df) ? (Q - df) / Q * 100 : 0
```

`m = 1` 时 `df = 0`、`Q = 0`、`I2 = 0`，置信区间退化为该成员的正态区间。
`se == 0`（即 `sd0 == sd1 == 0`）在合并前整体拒绝，退出码 `2`，不跳过、不除零，
也不让 `inf`/`nan` 流进结果文件。

**并列 p 值的处理（稳定性）**：组内排序为**稳定插入排序**，比较条件严格写成
"后一项 p **小于** 前一项才前移"，因此 p 相同的成员保持**输入出现顺序**作为次级键，
`rank`、`threshold`、`adjusted_p` 与 `reject` 都按这个稳定次序给出。这样同一份输入
在任何一次运行、任何机器上都得到同一张表；换输入行序会改变并列成员的 rank 与阈值，
这是预注册家族里成员次序本身有意义的体现，不视为不稳定。

## 4. 输出文件

| 文件 | 列/内容 |
|---|---|
| `holm.csv` | `family_id,member_id,raw_p,rank,threshold,adjusted_p,reject` |
| `pooled.csv` | `family_id,m,pooled_effect_ns,pooled_se_ns,ci95_low_ns,ci95_high_ns,q_statistic,df,i2_percent` |
| `holm_summary.json` | `alpha`、每族 `m`/`reject_count`、逐项 `raw_p`/`threshold`/`adjusted_p`/`reject` |
| `RESULT.md` | 人类可读表 + 固定声明句 |

浮点一律用 `%.15g` 输出（最短且足够往返的十进制表示）；`reject` 在 CSV/JSON 中为 `0/1`，
在 `RESULT.md` 中为 `yes/no`。`family_id`、`member_id` 不允许含逗号或空白（CSV 无引号口径）。

## 5. 构建与测试

普通配置：

```sh
cmake -S . -B build/holm -DBASELINE_ENABLE_PLATFORM=ON -DA113_ARCHIVED_CASE_ONLY=OFF
cmake --build build/holm --parallel 4
ctest --test-dir build/holm -R holm --output-on-failure
```

sanitizer 配置：

```sh
cmake -S . -B build/holm-sanitize -DBASELINE_ENABLE_PLATFORM=ON -DA113_ARCHIVED_CASE_ONLY=OFF \
      -DBASELINE_SANITIZERS=ON -DCMAKE_BUILD_TYPE=Debug
cmake --build build/holm-sanitize --parallel 4
ctest --test-dir build/holm-sanitize -R holm --output-on-failure
```

| 配置 | `ctest -R holm` 结果 | 说明 |
|---|---|---|
| 普通 | **1/1 通过** | `platform_holm` 1.07 s |
| ASan/UBSan | **1/1 通过** | `platform_holm` 1.24 s；目标与测试都带 `-fsanitize=address,undefined -O1 -g` |

补充核对（同一次构建）：

- `ctest -L platform`：**14/14 通过**，未影响 M2/M3/M4/M5 与既有 platform_stats 目标。
- `cmake --build build/holm --target format-check`：通过（退出码 0）。

`platform_holm` 与 `test_platform_holm` 不链接 `baseline_options`（不读密码头文件），
所以 sanitizer 选项在 `cmake/PlatformStats.cmake` 内单独跟随 `BASELINE_SANITIZERS`；
否则 sanitizer 配置下这两个目标实际上没有被插桩。已核对实际编译/链接行为：

```
C_FLAGS = -g -std=c11 -arch arm64 -Wall -Wextra -Wpedantic -Wshadow -Wconversion
          -Wstrict-prototypes -Werror -O1 -g -fsanitize=address,undefined -fno-omit-frame-pointer
link    = ... -fsanitize=address,undefined ...
```

## 6. 手算对照（测试内注释的同一套算式，下面是实际输出）

测试 `tests/test_platform_holm.c` 是**黑盒**：写输入 CSV、以子进程运行工具、读回四个文件逐值比较。
它自己选临时根（优先 `A113_TEST_TMPDIR`，否则当前目录、`/tmp`），退出时删除自己建的目录。

### (a) m=3、p=0.001/0.02/0.04、alpha=0.05

阈值 `0.05/3, 0.05/2, 0.05/1`；`adjusted_p = 0.003, max(0.003,0.04)=0.04, max(0.04,0.04)=0.04`；
三项都不超过 0.05，全部 reject。合并侧：`theta = 1,2,3`，`se^2 = 1/100+1/100 = 0.02`，`w = 50`，
`sum(w) = 150`，`pooled = 2`，`pooled_se = 1/sqrt(150)`，`Q = 50*((1-2)^2+0+(3-2)^2) = 100`，
`df = 2`，`I2 = (100-2)/100*100 = 98`。

实际输出：

```
family_id,member_id,raw_p,rank,threshold,adjusted_p,reject
F1,m1,0.001,1,0.0166666666666667,0.003,1
F1,m2,0.02,2,0.025,0.04,1
F1,m3,0.04,3,0.05,0.04,1
family_id,m,pooled_effect_ns,pooled_se_ns,ci95_low_ns,ci95_high_ns,q_statistic,df,i2_percent
F1,3,2,0.0816496580927726,1.83996667013817,2.16003332986183,100,2,98
```

### (b) 边界与"前面不拒绝则其后不拒绝"

`F2`：p = 0、0.5、1，m = 3。`k=1` 的 `3*0 = 0 <= 0.05` 拒绝；`k=2` 的 `max(0,2*0.5) = 1 > 0.05`
不拒绝，`k=3` 即使单项 `1*1 = 1` 也保持不拒绝。
`F4`：p = 0.001、0.04、0.04；`k=3` 的单项 `1*0.04 = 0.04` 看着很小，
但 `k=2` 的 `max(0.003, 2*0.04) = 0.08 > 0.05` 已经不拒绝，因此 `k=3` 必须 `reject = 0`；
同时 `t2`/`t3` 的并列 p 由稳定排序保持输入次序。
`F3`：m = 1，`adjusted_p = 0.5 > 0.05` 不拒绝，`df = 0`、`Q = 0`、`I2 = 0`。

实际输出：

```
family_id,member_id,raw_p,rank,threshold,adjusted_p,reject
F2,z,0,1,0.0166666666666667,0,1
F2,mid,0.5,2,0.025,1,0
F2,one,1,3,0.05,1,0
F4,t1,0.001,1,0.0166666666666667,0.003,1
F4,t2,0.04,2,0.025,0.08,0
F4,t3,0.04,3,0.05,0.08,0
F3,solo,0.5,1,0.05,0.5,0
family_id,m,pooled_effect_ns,pooled_se_ns,ci95_low_ns,ci95_high_ns,q_statistic,df,i2_percent
F2,3,1,0.0816496580927726,0.839966670138166,1.16003332986183,0,2,0
F4,3,1,0.0816496580927726,0.839966670138166,1.16003332986183,0,2,0
F3,1,3.25,0.282842712474619,2.69562828354975,3.80437171645025,0,0,0
```

### (c) 固定效应等权与不等权

`EQ`（等权）：`n0=n1=100`、`sd0=sd1=0.5` ⇒ `se^2 = 0.005`，`w = 200`；
`theta = 0.2` 与 `0.2`；`pooled = 0.2`；`pooled_se = 1/sqrt(400) = 0.05`；
`ci95 = [0.102, 0.298]`；`Q = 0`、`I2 = 0`。

`UN`（不等权）：`a` 行 `se^2 = 1/100 + 4/400 = 0.02` ⇒ `w = 50`，`theta = 0.1`；
`b` 行 `se^2 = 2.25/200 + 6.25/100 = 0.07375` ⇒ `w = 800/59`，`theta = 1.0`；
`sum(w) = 50 + 800/59 = 3750/59`；
`pooled = (50*0.1 + (800/59)*1.0) / (3750/59) = 1095/3750 = 0.292`；
`pooled_se = sqrt(59/3750) = 0.125432584814845…`；
`Q = 50*(0.1-0.292)^2 + (800/59)*(1.0-0.292)^2 = 1.8432 + 6.7968 = 8.64 > df = 1`；
`I2 = (8.64-1)/8.64*100 = 88.4259259259259…`。

实际输出：

```
family_id,m,pooled_effect_ns,pooled_se_ns,ci95_low_ns,ci95_high_ns,q_statistic,df,i2_percent
EQ,2,0.2,0.05,0.102,0.298,0,1,0
UN,2,0.292,0.125432584814845,0.0461521337629035,0.537847866237097,8.64,1,88.4259259259259
```

### (d) 非法输入

`missing_column`、`non_numeric`、`zero_count`（`n0=0`）、`zero_se`（`sd0=sd1=0`）、
`duplicated_header`、`extra_column`、`crlf`、`blank_line`、`out_of_range_p` 九类数据错误
全部退出码 `2`，且**没有创建输出目录**；已存在的输出目录退出码 `1` 且目录内容不被改写；
缺 `--alpha`、`alpha=1.5`、输入文件不存在均非 `0` 退出。

## 7. 独立复算

除测试内的手算对照外，本轮还用一份临时 Python 复算脚本（不在仓库内，不参与交付）
对固定种子 `20261016` 的随机语料（4 族、每族 1–6 个成员、随机 `sd`/`n`/`p`）逐值核对
Holm 表与 `pooled`/`pooled_se`/`ci95`/`Q`/`df`/`I2`，列表一致。
这只是一次交叉检查，不替代测试内手算，也不构成统计确认。

## 8. 遗留项

- 本轮只做软件与数值验证，**没有**任何真实时序样本、锁频窗口或原生 Linux 运行。
- `cmake/Format.cmake` 的 `file(GLOB)` 目前不覆盖 `tools/**`，因此 `format-check`
  不会检查 `tools/platform_stats/holm.c`。本轮改用同版本 clang-format 21 直接
  `--dry-run --Werror` 核对两个新文件，结果干净；把 `tools/**` 纳入 `format-check`
  需要改 `cmake/Format.cmake`（或其常驻配置），不属于本次允许修改的文件清单。
- 家族规模上限为固定常量（100000 行 / 1000 族 / 每行 4096 字节），超限报用法错误；
  本阶段语料远小于上限，未做更大规模的性能与内存测量。
- `holm_summary.json` 由固定格式的 `fprintf` 生成并做了字段级核对，但**没有**引入 JSON
  解析器做往返验证；机器可读性只按本工具的输出合同声明。
- 证据不升级 R02/R04：这里仍是"工具准备好了"，不是"统计确认完成"。
