# M4 完成轮软件

这是既有人工比较夹具的新增调用软件；原 `fixtures/early_reject_memcmp/` 和已提交证据不改。不是完整 KEM 或密码漏洞利用。

本路只执行输入/参数/描述检查与 Binsec 形式验证，未执行任何 `--collect`。采数前由主控提交冻结 PLAN 并串行使用频率控制器。

```sh
cmake -S tools/platform_m4 -B build/platform-m4/ordinary -DCMAKE_BUILD_TYPE=RelWithDebInfo
cmake --build build/platform-m4/ordinary --parallel 2
ctest --test-dir build/platform-m4/ordinary --output-on-failure
cmake -S tools/platform_m4 -B build/platform-m4/sanitize -DCMAKE_BUILD_TYPE=RelWithDebInfo -DPLATFORM_M4_SANITIZERS=ON
cmake --build build/platform-m4/sanitize --parallel 2
ctest --test-dir build/platform-m4/sanitize --output-on-failure
```

根工程由主控加入 `include(cmake/PlatformM4.cmake)`，本路不编辑根 CMake。

`platform_m4_measure_{vulnerable,ct}` 的 `--describe` 不读钟；实际入口为 `--collect NEW.csv CALLS_PER_CLASS SEED RUN_ID [--compare-bytes 1..32]`，默认 32。一次窗口覆盖完整 `m4_compare_checked`，Linux 使用 `CLOCK_MONOTONIC_RAW`、ns。输入预先固定为首字节不等与末字节不等，两类结果均不相等；每次在窗口前复制到同一个工作数组并使用同一个候选数组，限定为输入已触碰的同地址比较。每相邻 pair 各含一类，显式种子的 SplitMix64 只决定先后。生成、分配、结果检查/消费、日志及 I/O 在窗口外。CSV 保留逐调用原次序，直接兼容统计电池 `--format measure --classes mismatch-first mismatch-last`。新文件以 C11 `wx` 拒绝覆盖，部分完成或错误不冒充成功。

正式计时循环之前有**固定 100 次预热**（`warmup_calls=100`）：两类交替、各 50 次，不读钟、不写 CSV、不消耗类序种子，因此同一 seed 下的类序与 `sample_index` 结构与旧版逐行相同。预热同样用本臂的比较形式，同时用于消费结果防止优化掉。

`--compare-bytes N`（1..32，默认 32）构造**截断对照臂**：`N=32` 走主路径，窗口仍是完整 `m4_compare_checked`；`N<32` 时 `m4_compare_checked` 只接受 32 字节，改夹具会改动密码语义，因此该臂直接计内核 `m4_compare_bytes`，`.meta` 里 `boundary=truncated_compare_bytes`。注意 `mismatch-last` 的差异固定在第 31 字节：一旦被比较前缀短于 32 字节就落在窗口外，内核对该类必然返回相等，所以截断臂的预期结果写成 `expected_result=mismatch-first:unequal,mismatch-last:equal` 并在采集时校验（主路径仍是两类都不等，判据不变）。`0`、`>32`、非数字都返回 2 并打印 usage，且不创建任何文件。

`platform_m4_dudect_{vulnerable,ct}` 只在 x86 且固定上游 header 存在时构建。`--describe` 不测量；实际入口为 `--collect NEW_CYCLES.csv BATCHES SEED`。每批固定 20000 调用，调用原 `dudect_main`，保留真实 TSC 原值与类序；原上游首批百分位预热、统计时丢弃端点、裁剪和高阶检验仍存在，单列记账。首批排序不影响保存的 `ticks`，CSV 从原 ticks 恢复 19999 个相邻区间，包含上游未用于检验的区间。TSC tick 不是 ns，不能混入主 CSV 或 Holm。

采集程序是人工已知输入实验，显式种子仅用于复现类序；不生成密钥、不调用上游的 `/dev/urandom` 重试路径。两类输出不外泄，只在窗口后消费。完整 KEM 端到端没有在此接入。

Linux x86 同时构建 `platform_m4_formal_{vulnerable,ct}`：32 位、`-O1 -g -ffreestanding -fno-pie -fno-stack-protector -fno-builtin -nostdlib`，入口 `m4_entry`，分析终点 `m4_halt`。它们不作普通 CLI 执行，不能与 64 位采集 ELF 混为一份产物。脚本 `checkct_1_16.cfg` 与 `checkct_fixed16.cfg` 分别约束公开长度；16 字节秘密/公开数组模型与具体栈指针均显式写入。

`run_checkct.sh` 只在 Cry 内新目录运行固定 Binsec/Z3/ELF/配置，CPU0/1、深度10000、分析120秒、solver5秒，另有180秒墙钟上限；保存完整输出、TOML、身份和反汇编。未知、pending、截断、solver timeout 和装载失败都必须保留，不能仅凭进程退出0写 secure。

本轮合同与结果位于 `docs/evidence/m4-completion-20261016/`。统计草案未冻结，软件成功不代表统计已经执行或恒时性质已在硬件上证实。
