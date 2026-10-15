# M4 Binsec 原生 runtime 结果

2026-10-16，状态：**安装与工具资格完成**。本路没有执行 M4 夹具分析或采样，没有 secure/insecure 结果。

实际运行在 `nss-marker@10.144.144.5`、Linux x86_64 裸金属，所有安装与探测固定 CPU0/1。
GCC 13.3.0、glibc 2.39，普通用户安装；没有系统包、Docker、root、调频或隔离写入。

## 可执行文件

| 工具 | 绝对路径 | 实际版本 | ELF SHA-256 |
|---|---|---|---|
| Binsec | `/home/nss-marker/yhr/Cry/platform-m4-20261016-6hRHRUxH/runtime/binsec-0.11.3/_opam/bin/binsec` | `Binsec version 0.11.3` | `66700f833213d3c9a1eb6e5bc37dcd0cb6da3562d87b1601cb640c896c4f2183` |
| Z3 | `/home/nss-marker/yhr/Cry/platform-m4-20261016-6hRHRUxH/runtime/bin/z3`，链接目标在同树 | `Z3 version 4.15.3 - 64 bit` | `80ee070b8ffc2fa964b0b879250b2110c47f84c1256a1f9ab76fc7cf95e46292` |

`binsec -version`、`binsec -help`、`binsec -checkct-help`、`z3 --version` 均实际退出 0。
`binsec-help.log` 包含 `-checkct`、`-sse` 和外部 `z3` solver 选项；未安装可选 `unisim_archisec`。
主路的 freestanding ELF32/i386 夹具使用内建 32 位 x86 解码器。
Z3 的独立 QF_BV 小输入依次得到 `sat`、`unsat`，见 `z3-probe.log`。

调用时保留普通环境，并在 `PATH` 前加同根 `runtime/bin`，使 Binsec 能找到外部 Z3；
`TMPDIR/TMP/TEMP` 与缓存仍使用本根路径。不得把缺失 solver、装载错误或超时解释为 secure。

## 安装链与完整性

Binsec 官方 0.11.3 只有源码发行件，故在本根使用 opam 2.6.1、OCaml 4.14.3 构建；
系统缺少 m4 和 GMP 开发头，分别在本根编译 GNU m4 1.4.19、GMP 6.3.0。
GMP 最终为 `--disable-shared --with-pic`；Zarith 1.14 通过，完整依赖见 `runtime-logs/opam-installed.txt`。
`binsec-switch-full.export` 保存已安装包元数据与来源校验信息。
Binsec 实际动态依赖为系统 libc/libm；Z3 另依赖系统 libstdc++/libgcc；两者均未声称完全静态。

固定来源见 [PIN.md](PIN.md)，本机只读 checkout 在 `third_party/binsec/`。
下载摘要、二进制摘要、ELF 头、ldd、官方 release API 元数据与许可证均在 `runtime-logs/`。
远端原工具、依赖、源码、缓存及日志保留；没有把整棵约 1.2GB 工具树当作本地证据复制。

完整元数据归档 `runtime-metadata.tar.gz`：

```text
12d02f8e4275112a817924e4b79129a42f1db6558ec8b4fb2fce98c59424987c
```

远端与本机归档摘要一致，内部 `runtime-logs.sha256` 全部核对通过，见 `local-integrity-check.log`。
该归档包括工具探测和安装日志，未包括工具 ELF 与下载缓存；它不是可移植 runtime 包。

## 失败尝试与收尾

所有失败原日志均保留，不覆盖为成功记录：

1. 首次只读下载阶段曾把进程 `HOME` 指到本根空目录；发现不符合开发者约定后，终止确切进程组 `205107`，移除该赋值。最终全过程保留原 `HOME`，显式使用任务临时/缓存变量。
2. 首次 GMP configure 缺 m4，补入本根 m4 后继续。第一次独立 PIC 重建探测未加本根 m4 到 PATH，再次 configure 失败；最终脚本包含所需 PATH。
3. 第一次非 PIC GMP 导致 Zarith 的 `R_X86_64_PC32` 链接错误。失败输出保留在 `install-attempt3.log`；opam 的失败 switch 自动清理后，在独立 PIC 源树重建并重新安装。
4. 为遵从主路不装可选 unisim 的要求，暂停仅负责后续串联的控制进程 `211757`，让 opam 子进程 `241682` 自然结束后结束该控制进程。最后无 unisim 的安装链退出 0。

最终 `path-audit.json` 检查安装各目录的符号链接，越界为 0；默认用户 `.opam`、`.cache/dune`、`.ocamlinit` 均未出现。
这项路径检查不是系统调用级的全文件写入追踪。
`install-process-audit.json` 核对已知确切安装 PID 与进程组均不存在，未按模糊进程名结束任务；共享 SSH socket 保留。

下一步由主路对新 freestanding harness 执行有界 CheckCT，并单独核对 halt、pending paths、solver unknown 和超时。
