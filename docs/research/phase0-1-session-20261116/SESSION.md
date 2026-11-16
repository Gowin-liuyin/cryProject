# P0 收尾 + P1 形状统计会话报告（2026-11-16）

## 1. 开工自检（原文）

```text
$ cd ~/cryProject-work && git branch --show-current
main

$ git status --porcelain | head -5
（无输出）

$ git log --oneline -3
896007ca build: 保留 .gitattributes 原有证据空白规则并与 LF 强制规则合并
153e264d build: 增加 .gitattributes 强制文本文件 LF 行尾（修复 WSL 下 patch 应用失败）
59537c03 docs(plan): 测评总树与分阶段任务书（含独立评审修订）

$ cmake --version | head -1
cmake version 4.3.1

$ /home/ubuntu/miniconda3/bin/clang-format --version
clang-format version 21.1.8

$ gcc --version | head -1
gcc (conda-forge gcc 14.3.0-18) 14.3.0
```

《任务书》§0/§3 复述：T1.1 产出 `tools/platform_stats/shape_stats.c` 与
`cmake/PlatformStats.cmake` 内的 `platform_shape_stats` 目标；T1.2 产出
`tests/test_shape_stats.c` 并注册 CTest；T1.3 产出
`scripts/platform_stats/run_shape_replay.sh`、只写
`docs/evidence/r20-shape-tests-20261116/` 的回放证据与固定声明。

## 2. 每任务状态与关键数字

### 提交 1｜T0.1 + T0.2：环境基线记录 —— 完成

- `cmake --build --preset baseline-wsl --parallel 8`：通过（增量 Built target）。
- `ctest --preset baseline-wsl`：**57/57 通过**（0 失败，12.18 s；提交前复跑 12.47 s）。
- `cmake --build --preset baseline-wsl --target format-check`：通过（0 diff），
  clang-format 21.1.8 经 `CLANG_FORMAT_EXECUTABLE` 钉版。
- 产出 `docs/research/p0-baseline-20261116/RESULT.md`（环境表 + 原样适配声明）。

### 提交 2｜T1.1 + T1.2：platform_shape_stats —— 完成

- 新增 `tools/platform_stats/shape_stats.c`：wide/long 两种输入、退出码 0/1/2、
  Brown–Forsythe、双样本 KS、类内对半二阶 Welch t；输出四行
  `test_name,statistic,p_value,n0,n1,verdict_exploratory`；meta 固定行
  `input_path/format/rows_class_zero/rows_class_ones/alpha/family/note`，另记
  `label=<相对路径>`；SHA-256 留给 T1.3 脚本。
- 新增 `tests/test_shape_stats.c`：确定性 LCG（种子写死，无随机源）A 均值同方差 1 vs 9、
  B 完全相同两组、C 格式/用法拒绝；另加长表合法与三类拒绝覆盖；临时目录经
  `tests/test_temp_directory.h` 走 CTest 的 `A113_TEST_TMPDIR`。
- 编译：`cmake --build build/cmake-platform --target platform_shape_stats test_shape_stats`
  通过，严格旗标 `-Wall -Wextra -Wpedantic -Wshadow -Wconversion -Wstrict-prototypes
  -Werror` 下 **0 警告**。
- CTest：`ctest --test-dir build/cmake-platform -R platform_shape_stats` 通过。
- 提交前 `ctest --preset baseline-wsl` 复跑 57/57、format-check 通过。

### 提交 3｜T1.3：既有数据回放 —— 完成

4 个输入（每类 10000 样本）的回放结果（p / flag）：

| 文件 | Brown–Forsythe | KS | 类内二阶 zero | 类内二阶 ones |
|---|---|---|---|---|
| cpu-6/csv/fixed-message-zero-ones.csv | 0.3931 / clear | 1 / clear | 1.43e-13 / flag | 4.32e-18 / flag |
| cpu-6/csv/vulnerable-message-zero-ones.csv | 0.4672 / clear | 7.09e-60 / flag | 9.95e-07 / flag | 2.91e-10 / flag |
| seed-424242/csv/fixed-message-zero-ones.csv | 0.6576 / clear | 0.2373 / clear | 2.51e-22 / flag | 2.96e-23 / flag |
| seed-424242/csv/vulnerable-message-zero-ones.csv | 0.5687 / clear | 8.56e-61 / flag | 0.0925 / clear | 0.0550 / clear |

- `docs/evidence/r20-shape-tests-20261116/`：4 个输出 CSV（表头 + 4 行）、4 个 meta
  （各含 `input_sha256=` 行，与 `sha256sum` 输入值逐一核对一致）、`RESULT.md`
  （每文件一行 + 逐字声明）。
- `docs/full-work-progress.md` 末尾追加 1 行台账（P0+P1 软件完成、R0a 复测采集留待主控），
  未改旧行。

## 3. 三个提交

| 提交 | 信息 |
|---|---|
| `c213c568` | `docs(p0): 记录 WSL 环境基线与本地构建适配` |
| `302f749f` | `feat(platform-stats): 新增 shape_stats 三检验与合成数据自检` |
| 本文件所在提交 | `test(platform-stats): 既有 M1 数据形状检验回放与证据落盘`（hash 见 `git log -1`，文件无法自引用自身提交号） |

均在本地 `main`，未 push。

## 4. 偏离项及理由

1. **平台目标构建口径**：仓库 `baseline-wsl` 预设未设置 `BASELINE_ENABLE_PLATFORM=ON`，
   而 `cmake/PlatformStats.cmake` 只在该开关开启时被根 CMake include；基线 57 条不含
   平台目标。为不改动已冻结预设、不改变 57 条基线计数，P1 用独立构建树
   `build/cmake-platform`（`-DBASELINE_ENABLE_PLATFORM=ON`，编译器、两条告警抑制与
   clang-format 钉版同 `baseline-wsl`）编译并运行新目标/新用例；`build/` 仅构建产物，
   不作证据。详见 `docs/research/p0-baseline-20261116/RESULT.md`。
2. **`--label` 落点**：规格列出 meta 固定行未含 label；为让 `--label` 可追溯，meta
   首行加 `label=<相对路径>`，其余行逐字按规格。RESULT.md 的固定声明逐字保留。
3. **单测覆盖扩展**：在规格 A/B/C 外增加长表（五列/六列合法、三类拒绝）用例，覆盖
   T1.1 的 long 契约；全部确定性、无随机源。
4. **类内二阶退化口径**：按提示词“两侧方差同为 0 输出 t=0、p=1”实现；半步只有 1 个
   样本时无法估方差，按 0 处理并落入同一退化分支。
5. **工具环境限制**：WSL 仓库内既有文件经 `\\wsl.localhost` 编辑时 `write/edit` 工具
   返回 `GetFileSecurityW EIO`，因此对 `cmake/PlatformStats.cmake`、回放脚本与台账
   采用“Windows 临时文件 + `cp`/追加”落地，`git diff` 与 `file` 核对为纯新增/纯追加、
   LF 行尾；未绕过任何评审或改动既有内容。
6. `SESSION.md` 内无法写入自身所在提交的 hash（自引用），最终会话消息给出完整三个
   hash。

## 5. 卡点

- 无阻塞性卡点。
- 边界提醒：本轮证据是既有 M1 数据的**探索性族外回放**，不构成方差齐性/恒时结论，
  不进 Holm、不改任何既有判定；R0a 复测采集留待主控。
