# M4 完成轮环境与身份

日期：2026-10-16（Asia/Shanghai）。基础提交 `ac46e625c5c8e0db239f95b2464c9eaa6f55bf72`；本轮新增 harness、采集工具、CMake 片段、测试和 PLAN 当时尚未提交，固定源载体在 `software-native/source-v2.tar.gz`。`fixtures/early_reject_memcmp/` 相对基础提交无改动。

| 项 | 实际身份 |
|---|---|
| 真实执行主机 | nss-m，Linux 6.17.0-35-generic，x86_64 |
| 工作物理根 | `/home/nss-marker/yhr/Cry/platform-m4-20261016-6hRHRUxH` |
| 编译/形式任务亲和性 | CPU0/1，最多 j4；未使用 CPU2/CPU6 采数合同 |
| 编译器 / CMake | GCC 13.3.0 / CMake 3.28.3 |
| 形式目标 | ELF32/i386、静态无 libc、`-O1 -g -ffreestanding -fno-pie -fno-stack-protector -fno-builtin`，无 LTO |
| 普通采集目标 | ELF64/x86_64，RelWithDebInfo `-O2 -g -DNDEBUG`、C11、无 LTO |
| Binsec | 0.11.3，源码 commit `9749bd8aed7ee0a27959158b1e53e8789cb0e5ab`，LGPL-2.1 |
| SMT | 官方 Z3 4.15.3 Linux 发行件，实际版本与 sat/unsat 自检通过 |
| 本机软件资格 | Darwin arm64，AppleClang 21，CMake 4.3.2；不作原生 Linux 证据 |

Binsec 源码在本机 `third_party/binsec/` 固定；工具使用 Cry 内隔离 opam/OCaml/GMP/m4 构建，不安装系统包。所有下载、构建、switch、`OPAMROOT`、缓存和临时文件都在本物理根，HOME 保持原值。Z3 依赖已有系统 glibc/libstdc++ 等动态库，不称完全静态；具体依赖与下载摘要见安装工人的 `runtime/` 原记录。

本次使用的可执行工具：

```text
Binsec: runtime/binsec-0.11.3/_opam/bin/binsec
SHA256 66700f833213d3c9a1eb6e5bc37dcd0cb6da3562d87b1601cb640c896c4f2183
Z3: runtime/z3-4.15.3-x64-glibc-2.39/bin/z3
SHA256 80ee070b8ffc2fa964b0b879250b2110c47f84c1256a1f9ab76fc7cf95e46292
```

形式 ELF（`build-software-v2/`）：

```text
vulnerable 308190a7688f5757a1d354a8dffbb9c55cbbfaca027136befeabbae6e859180e
ct         7f34c8764bffd07329db93edcb7f4564b5fbe1e686a7c0ee54468680d38c47c4
model      ed11c9391bedf3ad07ca94277109f47d55de8873ff9400bcc8c709be0ee38f2f
```

所有普通/在线 ELF 摘要、源载体摘要与编译/链接命令在 `software-native/software-logs-v2/`；形式化工具/ELF/模型身份分别在 `formal-v1/*/identity.txt`。本地与远端源载体摘要一致，未把 sanitizer 产物用于形式证明或计时。

原件归档在远端同根内保留，拉回本机 `build/platform-m4-s7/` 后核对 SHA-256，解包到当前证据目录：

| 归档 | SHA-256 |
|---|---|
| `software-evidence-v2.tar.gz` | `5cd6e6bdf20d4ad2264c3491af63527a528cc0816247a97745fb11d41032766e` |
| `formal-evidence-v1.tar.gz` | `984eabe8a32e48d27f1e03198f95f910698057c43c1816edea5af3238e547d85` |

源 v1、软件构建 v1 及其日志保留；v2 增加采集窗口前同地址输入复制和编译器屏障，并保留最终普通/动态资格，未覆盖 v1。正式形式结果全部使用 v2。完整安装树和缓存留远端，不为交接重复下载 1GB 以上依赖；可读安装元数据单独归档。

本路未启动 `--collect`、没有时间 CSV、没有频率/boost/governor/隔离写入；`restore_match` 对本路不适用。共享 SSH 由主控管理，本路不关闭。
