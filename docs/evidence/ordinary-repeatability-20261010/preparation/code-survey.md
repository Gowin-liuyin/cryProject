# 普通参考单一公开有效输入的重复性采集：只读代码调查

2026-10-10。调查时 HEAD 为 `22a7b9065984cb1f2c6361c4553b23589f88d1fb`、分支 main，远端及身份与 AGENTS 一致。只读现有源码、配置、来源记录及公开固定向量；没有 SSH、构建、CTest、采集、修改产品源码或提交。唯一新增是本调查笔记。知识图谱工具当前不可用，按父任务已确认的回退权限使用已知文件及 rg。未读取 `.agents/`。

## 结论

现有完整程序不能原样复用来测“同一公开有效密文、同一公开测试私钥、普通 reference 完整封装调用、多个新进程”。最小路线是新 purpose-built C11 collector，直接链接现有三对象参考库，复用既有 RAW 读钟、CPU2 自身亲和性、进程禁止转储、预分配及输出协议骨架。固定公开 NIST decapsulation tcId 86 作为唯一输入，每次都走 `mlkem_decapsulate` 的完整长度守卫及参考内核。普通源码和固定 vendor 无须改动，不需要密文分类、秘密差异输入、MSR、root、调频、cgroup 或变体构建。

这只是可实施的代码路线，不是此次采集已经通过资格或执行的证据，也不自动闭合运行间 iid、精度或安全等价界。

## 已有入口逐项适用性

| 入口 | 实际行为 | 对本次对象的适用性 |
|---|---|---|
| `docs/research/aris-frequency-window-20261010/frequency_workload.c` | 普通 reference；生成一把系统随机密钥和 8 个有效密文；按 call_count%8 轮转；1 秒预热/4 秒主期；必打开 CPU2/18 的 MSR 设备；同步 APERF/MPERF、thread clock 和 checkpoint | 两次 RAW read 与全调用边界、结果消费、安全 helper 可复用；整个程序不能直接运行。本次应删除 MSR/反馈及多输入/按时长协议，保留原工具封存身份 |
| `src/measure.c` 的 `BASELINE_ORDINARY_WORKLOAD` | CLOCK_MONOTONIC；公开测试种子生成 valid/bit-flipped/random 三类，乱序；100 次预热；同时测 empty/clock steps；输出新 CSV/meta/cost | 计时包含 `read_monotonic_nanoseconds` 的转换/检查，且输入对象与 RAW 不同；不能改标签冒充本次单输入 RAW。现有已封存协议继续保留 |
| `src/audit.c:safe_performance` | 6 blocks×reference/hardened/deployable；每程序 3000 formal+100 warmup，总计划 55800；调用上述 benchmark | 多实现比较与探索性 run-pair bootstrap 的既定协议，不适合本次单 reference 问题 |
| `docs/research/aris-raw-clock-20261010/raw_clock_calibration.c` | CPU2、自身亲和性、固定 warmup/main 次数、RAW 原始秒/纳秒与失败/null、没有密码操作 | 可复用采集/元数据骨架；不能原样充当完整解封装采集器，必须使用独立新目标、schema、合同和计数 |

## 最小参考库与实际 API

已有 `frequency_reference` 的配置可直接复制为此次单独目标：

- 编译对象仅 `src/kernel.c`、`src/mlkem.c`、`src/random.c`。`src/kernel.c` 只有 `#include "mlkem_native.c"`，通过 vendor 单编译单元纳入参考算法及 FIPS202。
- include 路径为仓库 `include/` 和 `vendor/mlkem-native/mlkem/`，编译定义仅 `MLK_CONFIG_FILE="baseline_config.h"`，C11、扩展关、IPO 关。不定义 `BASELINE_VULNERABLE`、`BASELINE_HARDENED`、`BASELINE_DEPLOYABLE`，不执行补丁目标。
- `include/baseline_config.h` 固定 `MLK_CONFIG_PARAMETER_SET 768`、`MLK_CONFIG_NAMESPACE_PREFIX baseline_native`、`MLK_CONFIG_NO_RANDOMIZED_API`。默认本项目没有开启 native arithmetic/FIPS202 后端；这是固定便携 C 参考构建，不等价于原生汇编优化后端。
- 被测入口为 `int mlkem_decapsulate(uint8_t *shared_secret, size_t shared_secret_byte_count, const uint8_t *ciphertext, size_t ciphertext_byte_count, const uint8_t *decapsulation_key, size_t decapsulation_key_byte_count)`。完整参数长度 32/1088/2400 字节。先检查 NULL 和精确长度，再调用 `baseline_native_dec`；不能绕过封装直测内核而仍称完整封装调用。
- `mlkem_implementation_name()` 必须为 `reference`，但字符串自述不能代替编译命令、实际链接及反汇编核查。保存完整普通 ELF、静态库、动态符号和反汇编，确认此次实调用落到 reference 路径且没有变体宏/overlay。
- `src/random.c` 是 `src/mlkem.c` 同对象内其他函数的外部依赖，保留即可；collector 单输入固定 NIST fixture 无需调用 `system_random_bytes` 或密钥/封装生成函数。`erase_secret_bytes` 提供 volatile 逐字节擦除，不被普通优化删除。
- 无需 `src/inputs.c` 才能运行新的单公开向量 collector；如果继续原样使用 `tests/test_mlkem.c` 做功能资格，则该测试使用 `parse_unsigned_integer`，须另外链接 `src/inputs.c`、包含 `include/inputs.h`。
- 最简单且保守的打包是带上完整固定 vendor `mlkem/` 125 个文件及 LICENSE；不手工剪裁供应商 include 依赖，也不改其文件。仅 portable C 真正进入此配置，实际预处理/编译命令与链接再核。

## 单输入的公开来源与独立答案

固定来源已有 `docs/reference-recheck.md` 和 `tests/vectors/SHA256SUMS`：

- mlkem-native 固定提交 `b3ba7b32773e657dd37f6f87bce82528459ad8a4`，库许可 `Apache-2.0 OR ISC OR MIT`；`vendor/mlkem-native/LICENSE` SHA256 为 `1c730e3c2cd4f70e058519ef3e910d8bdd4ed822ae2ce689f3c63d32fc52314b`。该来源说明是仓库既有固定记录，本调查未联网重新审计上游。
- NIST ACVP-Server 固定提交 `975de31eb83d87039ec88934fdc47d8c312b892d`。`encdec-prompt.json` SHA256=`998e22dfb12efb14ce9fdff911ca634b13612819a1806f25da69adba7e16db91`，`encdec-expected.json` SHA256=`9089ec6ff2424da9f2782b89b2f831a329a3e28d6e5e24b802b78ff36ac61cdf`；转换后 `tests/vectors/mlkem768.txt` SHA256=`c94dda2717eb370dddfe5b7ca7a7f58d789e0f63238a486e464ce40c673817f4`。
- 选择 `parameterSet=ML-KEM-768`、`function=decapsulation`、`tgId=5`、`tcId=86`。只读逐字节核对：转换记录的 dk、c 分别等于 prompt 中同 tcId 的 dk、c；预期共享值等于 expected JSON 中的 k。长度为 2400/1088/32 字节。
- tcId86 解码后的输入摘要：dk SHA256=`03eb53081c6f20e013ab6195bd2f18a25e02201c2fb5790687aa709bb2a48f35`；ciphertext SHA256=`3a1da6c03645a6b211942c58fe3b1fb7896cb8814de2a9e478a6faed8f20be23`；已公开 NIST expected k SHA256=`ca4b36ac6565fbe8993b8cd84495a09f7104201008f529f3bc3f57a5c13727d2`。本调查笔记未复制任何原始密钥/共享值字节。
- 静态外部 SHAKE256 核对 `J(z||c)` 不等于 tcId86 的 NIST expected k（此处只有公开固定测试字节）；因此在实际参考 decapsulation 与 expected 全 32 字节相符、并结合固定实现隐式拒绝源码时，可证明此固定样例不是隐式拒绝输出。单凭普通返回 0 不能分类接受，因为封装故意不公开内部重加密验证结果。
- 采集前一次或事先合同明确次数的完整解封装与 published expected 全字节核对须在窗口外且计入真实密码调用总账；每个采样后也可在窗口外全字节核对 expected，失败停止。不能先自产期望再用该期望自证。该公开 fixture 是明确测试场景；它不承载真实业务秘密，也不代表随机密文总体。
- 输入载入可使用 C 的严格定长文件读取（拒绝短/长/错误/尾随内容）或严格解析同 tcId 的固定向量，来源摘要及实际字节摘要在正式采样前绑定。不得依赖宽松 scanner 选出第一个“看似可用”记录。若生成独立 fixture/header，保存原 JSON→固定 tcId→新文件的逐字节映射，并把生成方法作为准备步骤而非密码正确性答案生成。

## 计时与进程安全的最小复用合同

`frequency_workload.c:record_call` 是准确边界参照：先读取前一份原始 timespec 并检查读取成功；`atomic_signal_fence(seq_cst)`；一次完整 `mlkem_decapsulate`；第二道 fence；后读；再转换两份 timespec、检查非降、记录状态、消费输出、擦除输出。不要替换为两次 `read_clock()`，因为那会在窗口中加入转换和顺序检查。新 ELF 必须重新检查该实际模式，不能用旧 ELF 的模式替代。

- 输出消费用 volatile sink，发生在后读之后；sink 不打印，不输出共享值或密钥。全输出比对和擦除也在窗口外。G2 当前仅消费 shared_secret[0]；新协议若用全 32 字节校验/消费，要如实记录不同循环间开销，不能宣称与旧 G2 相同。
- 数据数组一次预分配并触页，只有内存记录进入采样过程，不在窗口中分配、生成输入、日志、hash、I/O、读 proc/sysfs、查询 CPU 或读 MSR。完整原值逐行保存、不删普通长尾、失败/null 和未尝试分开。
- `frequency_workload.c:disable_process_dumping` 使用 Linux `prctl(PR_SET_DUMPABLE,0)` 并 `PR_GET_DUMPABLE==0` 回读；必须在固定输入/随机秘密载入和记录分配之前、由被测 C 入口自身执行，因为 exec 会重置。它只改变本进程 dumpable；外层 `RLIMIT_CORE=0` 是额外约束，不替代自身设置。
- 自身 CPU2 sched_setaffinity 后精确回读，可复用 RAW collector 前后 current CPU/affinity/clocksource/clock_getres 元数据。只设置自身亲和性，不称 CPU2 独占或恒频。
- 固定采样数及预算由新的事前合同定义；失败留存，不按结果补跑。固定输入跨进程可去掉输入组成差异，但三个或更多相邻进程仍不自动是独立会话/独立统计单位。

## 最小独立资格路线

可直接复用 frequency CMake 中参考资格目标：`tests/test_mlkem.c + src/inputs.c` 链接同一 `frequency_reference`，参数 `tests/vectors/mlkem768.txt`。该测试执行 25 keygen、25 encap、10 decap（既有记录含 5 implicit rejection）、10 ekcheck、10 dkcheck、公开长度/NULL 守卫及系统随机 roundtrip；它不是只测此次 tcId86。普通与 ASan/UBSan 配置分开，正式只跑普通 collector。所有 KAT/边界/roundtrip 的密码调用必须与正式采样分开列账，不能说本轮“只有正式次数”而忽略软件资格。

只读检查本次拟复用的 `tests/test_mlkem.c`、`src/inputs.c`、`src/measure.c`、frequency_workload 源/CMake，没有发现 `/tmp`/mkstemp/mkdtemp 硬编码。它们打开的 `/dev/urandom` 是系统随机源读取，不是边界外项目落盘。仍须对新打包树逐文件核对实际临时路径和六项 temp/cache 环境；不要顺手运行旧根的完整 CTest 或不适用旧快照。

## 源码字节绑定（本调查 HEAD）

| 文件 | SHA256 |
|---|---|
| src/kernel.c | `460df8a1ab60c699388fadf21f196adc03da833026b8d1fc7227a87695275432` |
| src/mlkem.c | `132857244937f7b75a95d3a4e1d785c6b50327913b274781d580785b4cb8739b` |
| src/random.c | `d5997d997ea6f28160670a2cc9d6a3d43b6661f3628e32804416e16881e8cc20` |
| include/mlkem.h | `d2370cd5d17703f64ddd8a1a315536804709998c39ea61178e9949b0abc5c4e5` |
| include/baseline_config.h | `862e311313ac2b7892665ada1c09c9ac03f43e6b42226b5ee2521ef1a4e4f477` |
| tests/test_mlkem.c | `280515c1231da8dd2b771fac916c3bc6db1b24da713557557bc25b03c53dece8` |
| src/inputs.c | `df082c0e37009db60d20d2e4059d33ac4ae845ffe1f4f97d8654bd28ae350474` |

这些绑定需由真正部署时的固定提交与上传载荷重新核对；只读调查不能当成软件或采集签收。
