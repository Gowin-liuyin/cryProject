# Linux 纯软件预检实物独立复核

2026-10-10，`/root/cpu_isolation_review` 只读核查本地原始 tar、源归档、Git 对象、选取副本、编译命令、ELF 头及测试日志。没有 SSH、执行 ELF、重跑测试或修改既有证据；本次只新增本记录。

结论：原件支持“固定候选已在 Linux/x86_64 编译，普通和 ASan/UBSan 各两项软件检查通过”。G2 长 worker 生命周期、普通入口执行、真实活动窗口、频率资格及 R02/R04 均不在本次签收范围。

## 归档、来源与依赖

- 原档 [window-source-7e93048-software.tar](window-source-7e93048-software.tar) 为 9031680 字节，独立重算 SHA-256 为 `408931d4b09ba516e22fc01c3dc748ace7b69d527c456ad9d8251461853c2dbc`，与提供值一致。
- 618 个唯一常规成员均在 `window-source-7e93048/` 子根内；没有绝对路径、父目录跳转、符号链接或特殊成员。`export-manifest.json` 覆盖除自身以外的 617 项，逐项长度及 SHA-256 全部匹配。载荷连同清单共 8440528 字节。
- `selected/` 中实际保存的 28 份文件逐字节等于原 tar 对应成员，包含四个 ELF、两份原 LastTest 日志、编译参数、源 tar 与执行记录；未用规范化 JSON 对象相等代替这一步字节比较。
- 内层源 tar 摘要为 `9229b613ead32f49ee73285fa39dff6b060b20287e3fce3a6bb9db944d8e84a4`，含 167 项：29 目录、138 常规文件，路径及成员类型均通过核查。其 138 份常规文件与外层解包源码、提交 `7e93048f3af885d14f1577b3a198bd3d52b8ee8e` 的 Git blob 及当前工作区对应文件逐字节相同。
- 138 份源文件包含模块文件 3、头文件 3、原 `src/` 文件 4、测试及向量 2、vendor 文件 126。该提交相对其父提交没有改动 `src/`、`include/`、`vendor/` 或 `tests/`。NIST 向量摘要为 `c94dda2717eb370dddfe5b7ca7a7f58d789e0f63238a486e464ce40c673817f4`。
- 实际候选 C 源摘要为 `ead1029864025047ca0df2bf1d7bea179040f151313589389c043e3a7b9ef68a`，与前次源码审查的最终候选一致。

## 实际编译与产物

两份归档编译器配置均为 GNU 13.3.0，CMake 3.28.3；`run.json` 记录主机 `nss-m`、Linux `6.17.0-35-generic`、x86_64。每配置的 `compile_commands.json` 均恰有六条，分别为原 `kernel.c`、`mlkem.c`、`random.c`、候选 `frequency_workload.c`、原 `test_mlkem.c` 和 KAT 所需原 `inputs.c`。

命令均使用 `/usr/bin/gcc`、C11、严格警告及 Werror，唯一配置宏为 `MLK_CONFIG_FILE="baseline_config.h"`，两个 include 根均指向本次 source 树。普通参数为 `-O2 -g -DNDEBUG`；动态配置另外带 `-O1 -g -fsanitize=address,undefined -fno-omit-frame-pointer`，链接也带两种 sanitizer。未见变体宏、overlay、补丁构建路径或 LTO。两个目标均链接同一 `libfrequency_reference.a`。每配置的 `.o.d` 归一化后共 80 次本仓库依赖引用、41 个唯一依赖，全部存在于已逐字节核对的源归档。

四份产物的 ELF 头均为 64 位小端、`e_machine=62`（x86-64），解释器为 `/lib64/ld-linux-x86-64.so.2`，GNU ABI note 的 OS 为 Linux。note 中 3.2.0 是 ABI 标签，不能当成本次运行内核版本。实际解析两个 workload 的 ELF 符号表，均有导入的 `sched_setaffinity`、`clock_gettime` 及已定义的 `mlkem_decapsulate`、`baseline_native_dec` 函数；普通产物导入 `pread`，动态产物导入 glibc 检查入口 `__pread_chk`。这些产物支持普通 Linux 分支已完整编译和链接；没有据此声称该分支已执行，也没有混同两种读取入口。

| 配置／产物 | 字节数 | 独立重算 SHA-256 |
| --- | ---: | --- |
| normal / frequency_workload | 224288 | `a4cb64271735ff40a7a40c8bbf67ad5a08841c4f3e05fb9182bc7e1991de1cfc` |
| normal / frequency_reference_kat | 207496 | `6fa25c317e80c84ba836e1568fff2817ef8b02929095ab0e27679fd7db0fbf1c` |
| sanitize / frequency_workload | 569432 | `f783076bd7fe0e414a5ff293ed6921196861616179e2a63aaf77b5f3b7ce1703` |
| sanitize / frequency_reference_kat | 475864 | `37633cf148ff1251ae08b2cf7ff679af05ed2118d3733f4849c2ceb83c0ef615` |

四项摘要和长度均匹配归档 `artifact-digests.json`。动态 ELF 含 libasan/libubsan 依赖，普通 ELF 不含这些依赖；未混用两套产物。

## 原始执行记录与结论边界

实际读取两份原始 [normal LastTest](selected/build-normal/Testing/Temporary/LastTest.log) 和 [sanitize LastTest](selected/build-sanitize/Testing/Temporary/LastTest.log)。每份恰有两个 `Test Passed`：

1. `frequency_workload --selfcheck` 输出 `selfcheck=passed`，同时明确 `hardware_read_performed=false`、`crypto_workload_performed=false`。
2. `frequency_reference_kat` 使用本次固定向量，记录 25 keygen、25 encaps、10 decaps KAT、两类各 10 项密钥校验、公共参数边界及系统随机往返通过。

`run.json` 的普通／动态 configure、build、test 共六步，均有 PID、启动 ticks 和退出码 0，无超时记录。两个 test-result 对象与对应步骤一致。归档执行命令和两份 LastTest 中没有无参 workload 调用；编排源只运行配置、构建和这两项 CTest。`run.json` 登记普通入口未运行、MSR 未读取、配置写入为 0。这些结论由所保存命令、源码行为和结果支持，不是独立动态系统调用审计。

编排源摘要为 `e0a56943dbf31971a1d262aab17e2991c89e92ba60acd1cf315ae0cf47a1b7d3`。记录的源码、构建、临时、缓存及输出路径均在 `/home/nss-marker/yhr/Cry/window-source-7e93048`；临时环境与编排逻辑一致。本地静态核查没有冒称再次读取了远端目录或证明所有外部进程行为。

本次可登记 Linux 编译和上述软件检查通过；不能登记 G2 生命周期、1 秒预热／4 秒真实观察、MSR 窗口、频率带、测量精度或 R02/R04 通过。既有 Mac 2/2 与 G1 空任务恢复结果分别保留，不能替代这些未执行项目。
