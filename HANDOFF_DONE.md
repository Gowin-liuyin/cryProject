# 多泄漏模块平台本轮交接（2026-10-16）

**8 路本轮工作项成功，0 路失败。M2 定位层完成；新模块时序采集与统计未运行。**
全部改动在本机 `/Users/yin/code/cryProject` 的 `main`，没有 push。
开工 `git pull --ff-only` 已确认包含 `4a3a4ab97d76f3317d68e64570a0c14318329a5b`。
本机是 macOS/ARM；以下原生定位实际在 nss-marker 的 x86_64 Linux 执行。

## 八路交付

| 路 | 本轮状态 | 主要产出与验证 |
|---|---|---|
| S1 docs-skeleton | 完成 | [架构](docs/platform/ARCHITECTURE.md)、[模板](templates/MODULE_RESULT.md)、[矩阵](docs/evidence/platform-matrix-20261016/RESULT.md)、独立只读整合审查 |
| S2 third-party-clone | 完成 | 六库 6/6，完整 commit/tree、fsck 与许可状态见 [REPOS](third_party/REPOS.md) |
| S3 valgrind-varlat | 完成 | 两份20250805原补丁、Valgrind3.25.1真实Linux构建，help有varlat开关；[工具记录](docs/evidence/m2-kyberslash-20261016/varlat-tool/README.md) |
| S4 kyberslash-version-audit | 完成定位层 | 独立未修/已修快照、PIN、重取脚本、Linux反汇编与varlat开/关对照；[版本审计](docs/evidence/m2-kyberslash-20261016/VERSION_AUDIT.md) |
| S5 stats-battery | 完成软件接口 | [入口](scripts/run_stats_battery.sh)、C统计、合成CSV/拒绝检查、Linux真RTLF与上游header离线dudect正负校准 |
| S6 m5-mlkem-native-wire | 完成前置接线 | [PIN](vendor/mlkem-native/PIN.md)、复用完整reference/measure，普通/动态各5/5，三聚合目标通过；[结果](docs/evidence/m5-mlkem-native-20261016/RESULT.md) |
| S7 m3-fixture-lut | 完成夹具与定位 | [人工LUT开/关](fixtures/mem_lut_leak/README.md)；本机2/2+2/2，Linux2/2；Memcheck开32/1、关0/0 |
| S8 m4-fixture-memcmp | 完成夹具与定位 | [人工比较夹具](fixtures/early_reject_memcmp/README.md)；本机4/4+4/4，Linux4/4；提前退出32/1、ct0/0；Binsec可用性笔记 |

“完成”对应用户分派的各路成功标准，不代表 M3/M4 的统计或 M5 阴性验收完成。
每路完整命令、路径、阻塞及回报在矩阵 `partials/S01.md` 至 `S08.md`。

## M2 当前结论

使用计划允许的 pq-crystals/kyber 降级路线，未改 M1 vendor。
历史 Kyber768 **不是 FIPS 203 ML-KEM-768**。

- 未修：`a621b8dde405cc507cbcfc5f794570a4f98d69cc`，无 exact tag。
- 完整已修：`272125f6acc8e8b6850fd68ceb901a660ff48196`，无 exact tag。
- 中间提交 `dda29cc63af721981ee2c831cf00822e69be3220` 只修 Slash1，本轮没有将它标作全修。
- nss-m、Clang18.1.3、`-Oz -g -fno-vectorize -fno-slp-vectorize`，三个目标函数未修各1个div、已修各0。
- 同一对秘密标记探针，varlat开启：未修1280 errors/3 contexts（exit99），已修0/0（exit0）；关闭：两者0/0（exit0）。
- 默认报警PC落在系数load，不能直接当成静态div地址；定位以同ELF数据流、源码、反汇编和开关对照共同支撑。

定位PLAN在执行前提交为 `4a44d7902a26e0482cae54820f9f2699ad99beb0`。
动态输入是公开人工定位夹具，直接调用未修改上游热点；没有完整KEM、独立KAT、密钥恢复或物理时延测量。
端到端、微基准、CI/Welch、Holm、RTLF及在线dudect在M2上均**未运行**，不能写成“本平台未检出”。
完整结果与环境见 [M2 RESULT](docs/evidence/m2-kyberslash-20261016/RESULT.md)。

## 集成与检查

根入口显式开启平台；默认OFF保留既有构建入口：

```sh
cmake -S . -B build/platform -DBASELINE_ENABLE_PLATFORM=ON -DA113_ARCHIVED_CASE_ONLY=OFF
cmake --build build/platform --target platform_stats platform_m5_measure mem_lut_leak_on mem_lut_leak_off m4_compare_vulnerable m4_compare_ct
ctest --test-dir build/platform --output-on-failure -R 'platform_stats_battery|mem_lut_.*_selftest|m4_.*'
```

主控集成验证：新增7项普通及ASan/UBSan各7/7；C format-check、新CMake片段格式、shell语法和diff检查通过。
原日志、编译选项、执行源摘要见 [integration](docs/evidence/platform-matrix-20261016/integration/ordinary-ctest.log)。
未重跑全仓库旧实验/完整Valgrind回归；根CMake已有整体格式差异未批量重排，新增接线保持固定风格。
独立整合审查见 [S01_REVIEW](docs/evidence/platform-matrix-20261016/partials/S01_REVIEW.md)。

统计口径：CI/p为大样本正态近似，非精确Student-t；RTLF固定α=.01。
dudect离线回放与新在线采集分列，最大t不转伪p进Holm；合成阳性不作为算法阳性。
原值保留，RTLF会过滤零值时显式阻塞；缺工具或数据不足不能写通过。

## 阻塞与下一轮

1. M2尚缺完整KEM适配/适用功能资格、具体采集PLAN、锁频原始时间数据与正式统计。
   本轮依最低交付收口于定位，没有跳过前置条件启动采数。
2. M5已有完整解封装二进制，仍待原生秘密标记工具与锁频阴性统计；当前不能声称“不误报”。
3. M3的Pin/Microwalk/.NET未就绪；M4的Binsec/opam/OCaml/solver缺失，只有有界合同与脚本，没有secure结果。
4. RTLF、ctgrind、Mona本体许可未明确，清单诚实记录；源码获取不等于再分发许可或工具已运行。

建议下一轮并行 **M2完整解封装与锁频统计**、**M5原生阴性验证**；构建/定位可并行，
CPU2/CPU6锁频采数严格串行。先提交采集PLAN，再boost关、performance、约4.30GHz、taskset，退出恢复并核对restore_match。

## 远端保全与结束

所有本轮远端项目文件均在 `/home/nss-marker/yhr/Cry` 新物理子树，原件保留：

- `platform-s3-20261016-cc79de28-2da`：补丁Valgrind工具。
- `platform-s4-20261016-7824`：M2普通/秘密标记探针与完整原件；同级原归档保留。
- `platform-s5-20261016-b4cd8480318c`：统计软件资格、合成输入/结果、两代源与载体。
- `platform-s7-20261016-idAExSCX`：M3原生定位。
- `platform-s8-20261016-250f424b`：M4原生定位。

本轮没有锁频采数或频率/隔离写入，restore_match不适用，不能填yes冒充锁频验收。
结束扫描仅见观察者自身，无本轮匹配worker；共享SSH退出，控制socket已不存在。
见 [结束核对](docs/evidence/platform-matrix-20261016/integration/remote-end-check.log)。
`vendor/liboqs-0.10.0/`和既有M1结论保持只读，保护范围相对4a3a4ab无diff；用户原有未提交文件保持。

## 本地提交（不push）

| commit | 内容 |
|---|---|
| `76a83cd` | 独立格式整理既有输入适配，无算法改动 |
| `4a44d79` | 平台骨架与M2定位PLAN冻结 |
| `1934047` | 六工具库固定清单 |
| `e92aa47` | M5固定快照与复用目标 |
| `49d0ebe` | Linux varlat工具与补丁证据 |
| `4346e70` | M3人工LUT与原生定位 |
| `af9bd12` | M4人工比较与原生定位 |
| `8be7734` | M2完整钉版与三热点定位 |
| `68efc4b` | C统计电池、RTLF与明确离线dudect |
| `aa4d920` | 根平台接线、格式覆盖及集成验证 |

本文件及最终矩阵/进度的收口提交不自引用hash；完整提交清单可执行
`git log --oneline 4a3a4ab..HEAD`。作者/提交者均为Gowin-liuyin，使用用户确认的已验证邮箱。
建议审阅本交接与diff后允许push；本轮未执行push。

---

## 2026-10-16 第二轮完成交接（主控）

上一节记录的是本轮启动时的 8 路分工（截至 `aa4d920`）。本节记录**本轮实际完成的内容**
与本地提交清单，取代"待办"表述；旧段落保留原字节作为历史时点。

### 完成范围

1. **根集成构建**：`make -j4` 的 jobserver 告警消除（recipe 清空 `MAKEFLAGS` + 显式
   `--parallel $(BUILD_JOBS)`，默认 4）。普通 **57/57**、ASan/UBSan **57/57**、
   平台开配置 **87/87**，`format-check` 通过；`native_digest` 的 OpenSSL 3 前置条件
   改为配置期能力探测（LibreSSL 会在配置期给出可操作错误，逃生开关下该测试明确 Skipped）。
2. **锁频控制器资格**：五条空任务全部通过（四条 `restore_match=yes`，q-contention 在
   共享锁上于任何频率写入之前被拒）。两次失败尝试的原件与根因分别保留在
   `failed-attempt-1/`、`failed-attempt-2/`。
3. **采数合同冻结**：M2/M5/M3/M4 四份 PLAN 由 `efca8a1` **一次提交冻结**；
   执行用 blob 摘要见 `docs/evidence/platform-collection-20261016/README.md` §1.0。
4. **锁频采数**：**54 次**控制器运行全部 `restore_match=yes`、放行探针 20/20 在 ±2% 带内
   （M2 18、M5 6、M3 12、M4 18）；另有 M2 微基准 **6 次**同条件运行。
5. **统计**：四个预注册 Holm 家族（α 全族 0.05）+ 固定效应合并；RTLF（α=0.01）42/42
   族外交叉；online dudect 族外；Mona 对 M1/M2 各六行对照。结论分层：
   **M4 vulnerable 臂端到端阳性（Holm 拒绝 3），M2/M3/M5 端到端未检出**；
   M2 定位层与 varlat 阳性、热点微基准层未检出，三层互不冒充。
6. **交付刷新**：23 页报告、平台矩阵图、离线 HTML 与匿名 ZIP（`final3-20261016`），
   并从 ZIP 解出后独立复算 CTest 5/5。

### 本地提交清单（本轮，自 `44c209a` 起）

详见 `git log --oneline 44c209a..HEAD`；按模块划分：
控制器白名单与沉降修复 → 构建并行度 → M2 KEM → M3 路径 → M4 Binsec/截断对照 → M5 工具 →
Mona → `platform_holm` → 根 CMake 与共享入口 → PLAN 冻结与采数证据 → 微基准 → RTLF →
报告/图/匿名包 → 完成条件与末次审计 → 进度与交接。

### 未做与不做

`git push` 未执行（等用户确认）。可选未做：C05（第二阴性）、D06（真实历史访存例）、
E06（Binsec 扩大范围）。比赛方的材料审核、本人签署与官方验收仍需人工完成。
