# P3（编排器 MVP）会话报告（2026-11-16）

## 1. 开工自检（原文）

```text
$ cd ~/cryProject-work && git branch --show-current
main
$ git status --porcelain | head -5
（无输出）
$ git log --oneline -2
22733951 docs(r0a): 复测采集冻结计划
2e8e33e4 test(m2): 修复臂 KAT 与等价验证

$ python3 --version
Python 3.13.12
$ ls build/cmake-platform/platform_shape_stats
ls: cannot access 'build/cmake-platform/platform_shape_stats': No such file or directory
```

- 平台树在 P2 为启用 M2 目标重建为 clang 树，`platform_shape_stats` 未构建；本轮按需
  `cmake --build build/cmake-platform --target platform_shape_stats` 构建，遇
  `erfc/exp/sqrt` 未链接（clang 平台树 `find_library(m)` 为 NOTFOUND），
  在构建目录补 `-DMATH_LIBRARY=/usr/lib/x86_64-linux-gnu/libm.so` 后重配并构建成功
  （构建产物，未改仓库文件）。`build/cmake-platform/platform_shape_stats` 与
  `platform_holm` 均就绪。

《任务书》§5 复述：T3.1 产出 manifest/findings 两份 schema（自写校验，不依赖 jsonschema）；
T3.2 产出 `tools/pipeline/pipeline.py` 的 freeze/verify/run-local/report 四个子命令与两个
真实 manifest；T3.3 产出 `tests/test_pipeline_replay.sh` 端到端 CTest（合成 20 行 CSV fixture）。

## 2. 每任务状态与关键数字

### T3.1 + T3.2（提交 1）—— 完成

- `tools/pipeline/manifest.schema.json`、`findings.schema.json`：字段与枚举按《任务书》§5；
  `pipeline.py` 内置自写最小校验（类型/枚举/正则/键集合），不依赖 `jsonschema`。
- `pipeline.py` 四个子命令：
  - `freeze <manifest>`：规则段 = 除 `preregistration_sha256` 外的整个 manifest，
    以 `sort_keys` 紧凑 JSON 计算 SHA-256 后写入；冻结副本 `manifest.json`、`freeze.json`、
    `artifacts.sha256` 落 `build/pipeline-runs/<target_id>/`（gitignored）。
  - `verify <run_dir>`：重算 prereg、冻结 manifest、全部引用 artifact、
    run-local 输出（journal）与 findings 引用的 SHA-256；不符退出 **4**。
  - `run-local <run_dir>`：只调用既有 C 件 `platform_shape_stats`（`--platform-stats` 指定，
    默认 `build/cmake-platform/platform_shape_stats`）执行 shape 回放；读回其输出 CSV 的
    `verdict_exploratory` 汇编 findings；`external_evidence` stage 记
    `verdict=not_run, notes="deferred_hardware: ..."`。
  - `report <run_dir>`：渲染 manifest 摘要 + arms/class_pairs/stages + findings 表 + deferred 清单。
- 两个真实 manifest（引用值取自 `docs/R05-全流程排查表.md` §0 与既有 evidence 原文件）：
  - `m1-r0204-replay`：M1，arms = unfixed `bd84ee9c…` / fixed `1849821e…`；
    class pair `message-zero`/`message-ones`；stage 对
    `docs/evidence/r02-r04-close-20261016/raw/*/csv/*.csv` 做 wide shape 回放。
  - `m5-reference`：M5，arm = `586c2d65…`（platform_m5_poison）；两个
    `external_evidence` stage（定位层 Memcheck 原件、端到端统计记录）。
- 实跑结果：
  - `m1-r0204-replay`：prereg `b6abfabd…`、manifest `7fe4bf26…`、artifacts=4；
    run-local 产出 **16 findings（8 negative / 8 positive）**，均标
    `exploratory_shape_replay` + `exploratory replay only; not in any Holm family`；
    report.md 生成；verify 通过。
  - `m5-reference`：prereg `c94601f7…`、manifest `8c714583…`、artifacts=4；
    run-local 产出 **2 findings（全部 not_run / deferred_hardware）**；report.md 生成；
    verify 通过。
- 篡改演示：对 m1 的一个 run-local 输出 CSV 追加字节后 `verify` **内部退出码 4**
  （`stage output SHA-256 mismatch`）；恢复原字节后 `verify` 通过。
  注：`wsl.exe` 对非零退出会在宿主侧显示为 1，脚本内捕获的 pipeline 退出码为 4。

### T3.3（提交 2）—— 完成

- `tests/test_pipeline_replay.sh`：在 `A113_TEST_TMPDIR` 内生成 20 行合成宽表与微型
  mock shape 工具，构造 fixture manifest（1 个可跑 shape stage + 1 个必 deferred stage），
  跑 freeze → verify → run-local → verify → report；断言 report 含 findings 行
  （`| f-0001 |`、`| f-0005 |`）与 `deferred_hardware` 行，findings.json 为
  1 positive + 3 negative + 1 not_run；并断言篡改输出 artifact 后 verify 退出 4、
  恢复后通过。
- 注册在根 `CMakeLists.txt` BUILD_TESTING 段（仅 7 行新增，位于全局
  `A113_TEST_TMPDIR` 属性生效之前，自动获得临时根）。
- `ctest --preset baseline-wsl`：**58/58 通过**（原 57 + test_pipeline_replay）；
  format-check 通过。mock 只出现在测试夹具里，pipeline.py 不实现统计量。

## 3. 两个提交（本地 main，作者/提交者 `Gowin-liuyin`，未 push）

| hash | 信息 |
|---|---|
| `3ab852ae` | `feat(pipeline): manifest/findings 模式与 freeze/verify/run-local/report 编排器` |
| 本文件所在提交 | `test(pipeline): 回放端到端测试与会话记录`（hash 见 `git log -1`，文件无法自引用） |

## 4. 偏离项及理由

1. **真实 manifest 存放位置**：白名单未列出 manifest 目录，两个真实 manifest 放在
   `docs/research/phase3-session-20261116/manifests/`（whitelisted 会话目录）下，而不是
   `tools/pipeline/`；schema 与编排器本体仍在 `tools/pipeline/`。
2. **run 产物不提交**：按硬规则，`manifest.json`/`freeze.json`/`artifacts.sha256`/
   findings.json/report.md 全部只写 `build/pipeline-runs/`（gitignored），本报告记录
   其路径、摘要与关键数字；`docs/evidence/` 未新增任何文件。
3. **fixture 的 mock 工具**：CTest 在 `A113_TEST_TMPDIR` 内生成 mock 只验证编排链路
   （调用约定、输出解析、findings 汇编、verify 4 检测），不参与任何真实统计；
   真实 manifest 的 run-local 只调既有 C 件 `platform_shape_stats`。
4. **统计口径**：shape 回放的 flag/clear 只映射为 findings 的 positive/negative，
   notes 明示 exploratory 且不进 Holm；编排器不计算 p 值、不聚合家族。
5. **clang 平台树补 `MATH_LIBRARY`**：P2 为 M2 把 `build/cmake-platform` 重建为 clang 树，
   `find_library(m)` 未找到 libm；本轮仅在构建目录缓存里补
   `-DMATH_LIBRARY=/usr/lib/x86_64-linux-gnu/libm.so` 后构建统计 C 件，
   不修改仓库构建文件。
6. **工具环境限制**：WSL 既有文件经 `\\wsl.localhost` 编辑报 `GetFileSecurityW EIO`，
   对 `CMakeLists.txt` 与 `pipeline.py` 用“Windows 临时文件 + cp”落地，`git diff`
   核对为预期新增（CMakeLists 仅 +7 行）。

## 5. 卡点

- 无阻塞性卡点（纯离线，未取件、未联网、未采集）。
- 边界：编排器是**软件骨架**，两个真实 manifest 的 report 只重组既有证据与族外
  exploratory 回放；不新增统计判定、不改任何既有证据；P4 修复模式库与 MCP server
  留待后续阶段。
