# quick 档干净 clone 复现记录（T30，2026-10-16）

本页记录 `scripts/reproduce_all.sh quick` 在**干净 clone**里的一次完整验证：配置、构建、
CTest 与每类 1000 次的小样本统计演练。原始日志按原字节留在同目录，未做删改。

## 1. 环境与身份

| 项 | 值 |
|---|---|
| clone 方式 | `git clone /Users/yin/code/cryProject /tmp/cryrepro-final2-20261016/cryProject`（临时解出目录，仅本机 `/tmp`） |
| clone HEAD | `8a95f64 test: 新增 R12 创新对照 (a) 锁频 vs 不锁频的计划（T29a，族外）` |
| 脚本 | `scripts/reproduce_all.sh`，sha256 `16562851a309ed40ee37b4b5deb3d1b54a4f44f70af01140cd235619c0117b97`（验证时尚未提交，测试前从工作区复制进 clone；该摘要与工作区当前文件一致） |
| 主机 | macOS 26.6.2 / Apple Silicon（arm64），Apple clang |
| 命令 | `sh scripts/reproduce_all.sh quick --work-dir /tmp/cryrepro-final2-20261016/quick --samples 1000 --runs 3` |
| 退出码 | `0` |
| 原始日志 | [reproduce-quick-clean-clone.log](reproduce-quick-clean-clone.log)，sha256 `5133e51e10ead20d6def233cd5a7dd47325579a95e6d8f49eb806ae6995a3c2a`（116136 字节） |
| 外层 stdout | [reproduce-quick-clean-clone.stdout.log](reproduce-quick-clean-clone.stdout.log)，sha256 `f824e39ace25973867290d8785466f8145385eff298a60bfa9a10d760aee22f6` |
| sudo | **未使用**；未写任何 sysfs 频率节点；未绑核 |
| OpenSSL | 脚本自动探测到 `/opt/homebrew/opt/openssl@3/bin/openssl` 并传给 `-DOPENSSL_EXECUTABLE=`，因此 `native_digest` 是真实运行而不是 Skipped |

## 2. 三个配置的配置 / 构建 / CTest

| 配置 | CMake 参数 | CTest 结果 |
|---|---|---|
| platform | `-DBASELINE_ENABLE_PLATFORM=ON -DA113_ARCHIVED_CASE_ONLY=OFF` | **80/80 通过，0 失败** |
| ordinary | 默认（`RelWithDebInfo`、`BUILD_TESTING=ON`） | **57/57 通过，0 失败** |
| sanitize | `-DBASELINE_SANITIZERS=ON -DCMAKE_BUILD_TYPE=Debug` | **57/57 通过，0 失败** |

三个配置的 CTest 合计 **194 项通过、0 失败**（80 + 57 + 57）。

## 3. 小样本统计演练（每类 1000 次 × 3 次运行，种子 31337 / 424242 / 31337）

演练按冻结 PLAN 的臂结构跑：M3 on/off、M4 vulnerable/ct、M5 reference 各 3 次运行；
每次运行先 `measure`/`m4_measure` 出 CSV，再用 `platform_stats` 做 Welch，最后用
`platform_holm --alpha 0.05` 做族内 Holm 与固定效应合并。

| 模块 | 成员数 m | Holm 拒绝 | 合并 Δ（ns）与 95% CI |
|---|---:|---:|---|
| M2 | 0 | 不适用 | 干净 clone 缺 `vendor/kyber-kyberslash-{unfixed,fixed}/`，M2 臂未构建，脚本打印跳过原因 |
| M3 | 6 | 1（`M3-on-r2`，adjusted p=0.0323） | +22.12 [−5.94, +50.17]，I²=71.3% |
| M4 | 6 | 0 | +0.56 [−4.22, +5.34]，I²=0% |
| M5 | 3 | 0 | −43.38 [−83.64, −3.12]，I²=0% |

**这不是任何模块的正式统计结论**，也不是对 ground truth 的检验：

- 演练不锁频、不绑核、每臂只 3 次运行、每类只 1000 次，而且跑在 macOS/ARM 上。
  这些正是各模块 PLAN 明确排除的条件，因此**三次演练的结果都不进任何家族、不改任何结论**。
- M3 演练出现 1 项拒绝、M5 演练的合并 CI 不含 0，这两个现象恰恰演示了「没有锁频协议时
  同一台机器会给出什么」：它们是演练条件下的观察，**不构成 M3 的端到端阳性，
  也不构成 M5 的阳性**。M5 的正式结论（m=3、Holm 拒绝 0、合并 Δ=−5.30 ns [−11.77, +1.16]）
  来自锁频采数，见 [../m5-completion-20261016/RESULT.md](../m5-completion-20261016/RESULT.md)。
- M4 在这个预算下没有拒绝，与「演练功效不足」一致，同样既不能当作 M4 的阴性证据，
  也不能反推正式锁频采数的结论（正式结果见
  [../m4-completion-20261016/RESULT.md](../m4-completion-20261016/RESULT.md)）。

演练的用途是证明流水线可跑通：采集 → `platform_stats` → `members.csv` → `platform_holm`
→ `holm.csv` / `pooled.csv` 四步都真实产出文件（演练产物根在日志末行给出）。

## 4. 干净 clone 里缺什么（如实）

| 缺件 | 后果 | 取件入口 |
|---|---|---|
| `vendor/liboqs-0.10.0/` | M1 历史阳性对照（`BASELINE_ENABLE_LIBOQS010`）不在 quick 档内，也未参与演练 | `tools/fetch_liboqs_0.10.0.sh` |
| `vendor/kyber-kyberslash-{unfixed,fixed}/` | M2 臂未构建，演练跳过（打印原因，不填「未检出」） | [../m2-kyberslash-20261016/VERSION_AUDIT.md](../m2-kyberslash-20261016/VERSION_AUDIT.md) |
| `third_party/{RTLF,dudect,Mona}/` | `platform_dudect_replay` 不启用，族外工具在 quick 档里没有入口；RTLF 只在 full 档统计步骤里出现 | [../tooling-strengthen-20261015/REPOS.md](../tooling-strengthen-20261015/REPOS.md) |

## 5. full 档 dry-run 验证

```
sh scripts/reproduce_all.sh full
```

默认只打印、不执行；本次打印 **27 条控制器命令**（M2 2 臂 ×3、M3 2 臂 ×3、
M4 2 臂 ×2 窗口 ×3、M5 1 臂 ×3），另逐模块给出 online dudect 入口。输出还包含：
串行与 sudo 提示、四个模块各自工作区 PLAN 的 sha256 与「执行版摘要不同」的说明、
`--plan-sha256 <执行版PLAN的sha256>` 占位、以及跑完后的 `run_stats_battery.sh` /
`platform_holm` / RTLF 统计入口。`--execute` 的两道闸门也实测过：控制根不在
`<...>/Cry` 之下、或控制根内没有 `controller.py`，都会在打印阶段就失败退出，
不会执行任何命令。参数总表见 [../../REPRODUCE-PARAMS.md](../../REPRODUCE-PARAMS.md)。

---

## 2026-10-21 更正（独立复核发现，原文不改）

①上文表格里「脚本 sha256 `16562851…`（验证时尚未提交……该摘要与工作区当前文件一致）」**后半句现已不成立**：`scripts/reproduce_all.sh` 在此���又改过，当前工作区的摘要是 **`002ab0be60373375f1ea871764bba1645bbe5946330561476cd94797abbabe75`**（报告表 T25 里的摘要**现算自当前工作区**，不再写死）。**产出 263/263 的那次运行用的正是当前这版脚本**，其日志 `docs/evidence/screenshots-20261020/reproduce-quick-terminal-p2b.log` 现已随匿名支撑卷分发。

②上文「原始日志按原字节留在同目录，未做删改」中的「同目录」指**仓库里的本证据目录**；匿名支撑卷里这两份日志镜像在 `evidence/files/<同一路径>` 下（路径一一对应），内容为**原字节副本**。
