# M4 采集件 v3：`--compare-bytes` 截断对照 + 固定 100 次预热

task-9 交付。本文件记录重建后的**普通（非 sanitizer）**采集件的路径、sha256、构建命令、CTest 结果与预热/截断语义。
本轮**未执行任何锁频采数**；下面的 `--collect` 只是普通环境下的小样本自检（每类 100 次），不是正式采集。

改动只落在 `tools/platform_m4/measure.c` 与 `tools/platform_m4/README.md`；`fixtures/early_reject_memcmp/`（含 compare 内核与
`m4_compare_checked`）、`cmake/`、`tests/` 与已封存的 `formal-v1/`、`formal-v2/`、`software-native/`、`runtime/` 均未改动。
仓库未 `git add/commit/push`。

## 1. 重建产物（普通 ELF，Linux x86_64）

| 项 | vulnerable | ct |
|---|---|---|
| 绝对路径 | `/home/nss-marker/yhr/Cry/platform-m4-20261016-6hRHRUxH/build-software-v3/platform_m4_measure_vulnerable` | `.../build-software-v3/platform_m4_measure_ct` |
| **sha256** | `2686907893706372538855fa778bc7133cbed8fa0a8115c3dc57b124119b36c5` | `90740bdf99125a2c37465c239617b6dadb344401e89b1830d24da88bd70be035` |
| BuildID | `be4bcbc0f250434c081d1e785af263fafbfe6874` | `1cbba4d38960edc85e46c2be61f762824986da36` |
| 类型 | ELF 64-bit LSB pie executable, x86-64, dynamically linked, with debug_info, not stripped | 同左 |
| 大小 / mtime | 34704 B / 2026-10-16 02:17:41.489908393 +0800 | 34824 B / 2026-10-16 02:17:41.500262390 +0800 |
| 源码 | `source-v3/tools/platform_m4/measure.c` sha256 `881ef2d2cb3f6f6a675c2495c1048a93436635c0e2c38aff0dce6d3f6b13f857` | 同一源码 |

**旧基线原样保留、未被覆盖**（仍是「T9 前只读基线」）：

| 产物 | sha256 | mtime |
|---|---|---|
| `build-software-v2/platform_m4_measure_vulnerable` | `2d311d38158dad66bdebf324b260e5b1be25be1d5477f611b9d87fae86bf7e0b` | 2026-10-16 01:49:43.210886087 +0800 |
| `build-software-v2/platform_m4_measure_ct` | `96e4ab3755c1d4bb13f97213d55bcc26958619fad0c72394bd168d0651a659fc` | 2026-10-16 01:49:43.426732199 +0800 |

没有原地覆盖 `build-software-v2/`：那里记录在 `software-native/software-logs-v2/binary-and-carrier-sha256.txt` 的摘要必须继续能与实物对上。
新产物因此放在**新目录** `build-software-v3/`，源码放新目录 `source-v3/`（v2 源树不动）。

### 构建命令（实跑）

```sh
OLD=/home/nss-marker/yhr/Cry/platform-m4-20261016-6hRHRUxH
cmake -S "$OLD/source-v3/tools/platform_m4" -B "$OLD/build-software-v3" \
      -DBUILD_TESTING=ON -DCMAKE_BUILD_TYPE=RelWithDebInfo
cmake --build "$OLD/build-software-v3" --parallel 8
ctest --test-dir "$OLD/build-software-v3" --output-on-failure

cmake -S "$OLD/source-v3/tools/platform_m4" -B "$OLD/build-sanitize-v3" \
      -DBUILD_TESTING=ON -DCMAKE_BUILD_TYPE=RelWithDebInfo -DPLATFORM_M4_SANITIZERS=ON
cmake --build "$OLD/build-sanitize-v3" --parallel 8
ctest --test-dir "$OLD/build-sanitize-v3" --output-on-failure
```

CMakeCache 实读：`CMAKE_BUILD_TYPE=RelWithDebInfo`、`CMAKE_C_FLAGS_RELWITHDEBINFO=-O2 -g -DNDEBUG`、
`CMAKE_HOME_DIRECTORY=<OLD>/source-v3/tools/platform_m4`。构建零 warning/error（`-Wall -Wextra -Wpedantic -Wshadow -Wconversion -Wstrict-prototypes -Werror`）。

## 2. CTest

| 配置 | 结果 | 日志 sha256 |
|---|---|---|
| 普通 `build-software-v3` | **7/7 passed, 0 failed** | `157340b852747bdddee0df859de006b2287a0b38319dc267255c220d2dc069bc` |
| sanitizer（ASan+UBSan）`build-sanitize-v3` | **7/7 passed, 0 failed** | `ba033c138030eda15fc7ddd7a776bf5353dabbdd63a40c22c2c8b5e97e865222` |

7 项：`platform_m4_{vulnerable,ct}_inputs`、`platform_m4_{vulnerable,ct}_describe`、
`platform_m4_{vulnerable,ct}_dudect_describe`、`platform_m4_cli_rejections`。构建/配置日志同在
`software-logs-v3/`（configure-ordinary/build-ordinary/configure-sanitize/build-sanitize）。

## 3. `--describe` 完整新输出（两臂逐字节相同）

```
module=M4 case=artificial_compare boundary=complete_checked_compare bytes=32 classes=mismatch-first,mismatch-last timing_collection=not_run compare_bytes_default=32 compare_bytes_range=1..32 abi_bytes=32 warmup_calls=100 truncation_rule=mismatch-last:equal_when_compare_bytes_lt_32
```

既有字段名一个未改、顺序未动，只在末尾追加：`compare_bytes_default=32`、`compare_bytes_range=1..32`、
`abi_bytes=32`（ABI/数组长度恒为 32）、`warmup_calls=100`、
`truncation_rule=mismatch-last:equal_when_compare_bytes_lt_32`。
已 grep 全仓库确认：除 `tests/test_platform_m4_cli.cmake` 只做 `timing_collection=not_run` 子串匹配外，
没有任何脚本按整串字面匹配 describe 输出。

## 4. 预热实现（固定 100 次）

- 位置：`fopen` 之后、**正式计时循环之前**，`M4_WARMUP_CALLS = 100U`。
- 类别：**两类交替、各 50 次**（`warmup_class = warmup_index % 2`），用的是本臂的比较形式（32 字节臂走
  `m4_compare_checked`，截断臂走内核）。
- 不计时：预热不调用 `read_nanoseconds`，不写 `elapsed_nanoseconds`，**不写 CSV**。
- 不消耗类序：预热**不触碰** `order_state`，也不调用 `m4_prepare_class_order`，所以同一 seed 的类序与
  `sample_index` 语义不变；`sample_index` 仍从 0 起、仍对应 CSV 第 0 行。
- 结果消费：预热结果异或进 `observed_result`，防止被优化掉。
- 预热失败（本路径实际不可达）会把 `collection_status` 置 1 并跳过计时循环，不产出伪成功。

## 5. `--compare-bytes N` 语义与每类预期值

**ABI 长度恒为 32**（数组仍是 32 字节，`.meta` 记 `abi_bytes=32`）；`N` 只作为**比较窗口**传给内核
`m4_compare_bytes(secret, candidate, N)`。`N=32` 走主路径，窗口仍是完整 `m4_compare_checked`（含入参校验）；
`N<32` 时 `m4_compare_checked` 只接受 32，改夹具会改动密码语义（禁止），因此该臂直接计内核，
`.meta` 记 `boundary=truncated_compare_bytes` 以示区分。

| 类（差异位置） | `N=32`（主路径） | `1 ≤ N ≤ 31`（截断臂） |
|---|---|---|
| `mismatch-first`（byte 0） | 不等（预期相等次数 0） | 不等（差异在窗口内，预期相等次数 0） |
| `mismatch-last`（byte 31） | 不等（预期 0） | **相等**（差异在窗口外，预期 = 每类调用数） |

这直接解掉 plans 报的阻断项：现有中止条件原为 `is_equal != 0`，在窗口 16 下会被 `mismatch-last` 的**预期相等**
误判为失败。现在判据是 `is_equal != expected_is_equal(class_label, compare_length_bytes)`：
**只有实际结果偏离本臂预期才置 `collection_status=1` 并中止**；截断臂里「预期相等」不是失败，因为差异字节确实落在
被比较前缀之外，这正是该对照要展示的截断效应。`N=32` 时 `expected_is_equal` 两类都为 0，与旧判据等价。

`--describe` 用 `truncation_rule=...` 暴露该规则；`.meta` 追加（既有字段一字未删未改名）：

```
compare_bytes=<窗口 N>
abi_bytes=32
warmup_calls=100
expected_equal_count_mismatch_first=<该类预期相等次数>
expected_equal_count_mismatch_last=<该类预期相等次数>
observed_equal_count_mismatch_first=<该类实际相等次数>
observed_equal_count_mismatch_last=<该类实际相等次数>
expected_result=mismatch-first:unequal,mismatch-last:<equal|unequal>
boundary=<complete_checked_compare|truncated_compare_bytes>
```

`N=32` 时 `.meta` 除上述追加字段外与旧版逐字相同（含 `boundary=complete_checked_compare`）。实测
`diff verify-v3/oldv2-default.csv.meta verify-v3/default-vulnerable.csv.meta`（旧 v2 二进制 vs 新 v3 二进制、同 seed 同参数）：
前 12 行**完全相同**，只多出最后 8 行追加字段。CSV 列名与列数未变：
`run_id,implementation,input_category,sample_index,elapsed_nanoseconds,time_unit`。

## 6. 实际验证（普通环境小样本，非锁频采数）

原始日志：`<OLD>/software-logs-v3/verify-v3.txt`（sha256 `26ae722c01c636b0731c90573129b9d67b4fe68bdae6991d1a85084f582b1cf3`）
与 `verify-v3-rejections.txt`（sha256 `e09d89a5511d2a9890d108fff228fb56767d980eda0e6e920b9d081e61c4d7ff`）；
样本 CSV/meta 在 `<OLD>/verify-v3/`。

| 检查 | 结果 |
|---|---|
| 默认采集（无新参数，100 次/类，seed 20261016） | 退出 0，`completed_calls=200`，`collection_status=0`，CSV 100+100 行；两类相等次数均 0 |
| `--compare-bytes 16` 采集（100 次/类，seed 20261016） | 退出 0，`completed_calls=200`，**`collection_status=0`**，CSV 100+100 行；`expected/observed_equal_count_mismatch_last=100/100`，`mismatch-first=0/0`；`boundary=truncated_compare_bytes` |
| ct 臂同样两项 | 默认 0 退出、截断 16 退出 0，计数同上 |
| `--compare-bytes 33 / 0 / 32.5 / abc / -1` | 全部退出 **2** 并打印 usage，**不创建任何文件** |
| `--bytes 16`（错旗标）/ 缺 N / `CALLS_PER_CLASS=0` | 全部退出 2，不创建文件 |
| 类序 A/B：旧 `build-software-v2` 默认 vs 新 v3 默认（同 seed） | `input_category,sample_index` 两列**逐行相同**（order sha256 `f5e837eee60943a08a44e7fde886f1ec135fecfcc0803e038e17f94b4d95e90a`） |
| 默认 vs 显式 `--compare-bytes 32` | 逐行相同（同上 sha256） |
| 默认 vs 截断 16 的类序 | 逐行相同（同上 sha256）→ 预热与窗口都不改类序 |

## 7. dudect 两臂：整文件摘要变了，但代码未变

`platform_m4_dudect_{vulnerable,ct}` 不链接 `measure.c`（它们链接 kernel 库 + `dudect_online.c`），源码未改动，
但重建到 `build-software-v3/` 后整文件 sha256 与 v2 不同 —— 原因是调试信息里内嵌的构建路径不同
（`source-v3` vs `source-v2`），不是代码变化：

| 产物 | v2 整文件 | v3 整文件 | `.text` v2 = v3 |
|---|---|---|---|
| `platform_m4_dudect_vulnerable` | `f674a5a09d60cce58ace75c76055416e13948c7850b5cf0a96cc26cd43e600e4` | `42c64118b345fa1ffab3cbc5655aecb75b22aca9685724987d5e6a5ba619f7cf` | 是（`36f5147b7bec25f469e077ecc6fe87dc119be2061e578efb1fcd098def822b3d`） |
| `platform_m4_dudect_ct` | `914d1ada3ada89fc7457bf5474642718ad53d1a9ab3c2fe027baf435f521c5e4` | `3e9178668fece354beffa83431454bc64d0cf02c1ad379f72e508bc8f114a689` | 是（`3897209009a592fdfe6324f46e8d18b8734c0d62b1437b6886777f9bf199e45e`） |

因此若 PLAN 要写 dudect 的整文件摘要，必须二选一并写清来源目录：沿用 `build-software-v2` 的旧值（字节未变、仍在），
或采用 `build-software-v3` 的新值。**两臂 dudect 的行为没有变化**。

## 8. 边界与遗留

- 本轮只做重建、CTest 与普通环境小样本自检；**没有**锁频、没有正式采集、没有统计结论。
- 截断臂的窗口是内核 `m4_compare_bytes`，主路径窗口是完整 `m4_compare_checked`——两者边界不同，已在 `.meta` 用
  `boundary=` 区分；跨臂比较时间时应按此口径说明，不能当作同一边界的两个长度。
- 若 PLAN 需要「两类差异都落在窗口内」的另一种对照（不触发预期相等），那要改输入构造（`inputs.c` 的差异位置），
  不在本任务写范围内，需主控另行派工。
- 本文件只描述软件与自检；`G4`/采数资格的判据仍按主控冻结的 PLAN 执行。
