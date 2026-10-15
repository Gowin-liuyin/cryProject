# Binsec 探测与有界验证准备

2026-10-16，本轮状态：`binsec=not_run`。没有 secure/insecure 工具结果。

## 官方依据与固定参考

本轮只读查询 `git ls-remote https://github.com/binsec/binsec.git HEAD` 得到
`9749bd8aed7ee0a27959158b1e53e8789cb0e5ab`。这固定本轮参考文档身份，不表示已 clone、安装或运行该版本。

- [官方仓库](https://github.com/binsec/binsec/tree/9749bd8aed7ee0a27959158b1e53e8789cb0e5ab)，LGPL-2.1。
- [固定安装说明](https://github.com/binsec/binsec/blob/9749bd8aed7ee0a27959158b1e53e8789cb0e5ab/INSTALL.md)：源码路线依赖 OCaml/opam/dune 和 SMT 支持；x86_64 解码还需相应架构组件。
- [固定 CT 教程](https://github.com/binsec/binsec/blob/9749bd8aed7ee0a27959158b1e53e8789cb0e5ab/doc/sse/relse.md)：相等性夹具借用其秘密/公开输入、入口/终点和有界探索方法。工具检查秘密对控制流与访存地址的影响；完整探索、超时和深度截断必须区分。

## 实际探测

| 环境 | 实际可用 | 缺少或限制 |
|---|---|---|
| 本机 macOS/ARM | Apple clang 21、CMake 4.3.2、Docker ARM 客户端 29.3.1 | `binsec`、`opam`、`ocamlc`、`z3`、`boolector` 不在 PATH；Docker daemon socket 不存在 |
| nss-marker / x86_64 Linux | GCC 13.3.0、CMake 3.28.3、Valgrind 3.22.0、Docker 客户端及 daemon | `binsec`、`opam`、`ocamlc`、`dune`、`z3`、`boolector`、`bitwuzla` 不在 PATH |

Linux 原始只读探测见 `linux-run-250f424b/environment.log`、`docker-probe.log`。
本轮没有安装系统包、拉 Docker 镜像或启动容器。Docker daemon 可用不表示其镜像落盘路径符合
`/home/nss-marker/yhr/Cry` 的项目边界；daemon data-root 尚未审计，不能直接以默认 Docker 镜像仓库绕开边界。

## 下一轮安装/执行合同

1. 由主控选择已就绪的 Binsec，或先准备能把所有项目源码、`OPAMROOT`、本地 switch、缓存、临时及构建产物约束在 Cry 新子树的安装环境；当前因缺 opam，不执行安装命令。
2. 固定实际 Binsec 完整提交/摘要、solver、架构组件、编译器和选项。建议普通独立 Linux ELF、无 LTO、带符号；如用教程的 `-m32 -static` 路线，须先确认 multilib。当前 x86_64 动态 ELF 只是可调用候选，未验证 Binsec 的装载及 `exit` 符号解析。
3. 构建 `fixtures/early_reject_memcmp/binsec_harness.c`，使用同目录 `checkct.cfg`：秘密数组 16 字节，候选数组及长度公开，`1 <= length <= 16`，具体栈指针，入口 `main`，在 `exit` 入口终止。比较值本身允许返回；不把 exit 内部的结果消费分支算入目标性质。
4. 按夹具 README 的 `-sse -checkct -sse-depth 10000 -sse-timeout 120` 命令分别运行，保存完整 stdout/stderr、退出码、模型及 TOML。核对到达 halt、无 pending paths、无 solver unknown，再解释工具结果；超时、截断、装载失败和未运行都不能写 secure。
5. 本轮预期是提前退出版本可定位、全长度归约版本可通过该小边界；这只是待验证假设。即便有界验证通过，也不证明任意长度、KEM 整包、所有编译器/ISA 或物理时间恒定。

当前已有的是 Linux Valgrind poison 对照与对应函数反汇编，详见 `RESULT.md`。
未做密钥恢复、exploit、统计采数或频率配置。

---

> **状态更新（2026-10-16，主控）**：本文件是当时那一轮的**快照**，其中的"本轮未实现/未运行"
> 描述只对该时点成立，**已被后续完成版取代**，请以完成版为准：
> - M3 → [`../m3-completion-20261016/RESULT.md`](../m3-completion-20261016/RESULT.md) 与
>   [`../m3-completion-20261016/LOCATE_RESULT.md`](../m3-completion-20261016/LOCATE_RESULT.md)
>   （挂载到完整解封装、Memcheck 四组合 1280/2 对 0/0、Microwalk 真实运行、锁频端到端统计）。
> - M4 → [`../m4-completion-20261016/RESULT.md`](../m4-completion-20261016/RESULT.md) 与
>   [`../m4-completion-20261016/FORMAL_RESULT.md`](../m4-completion-20261016/FORMAL_RESULT.md)
>   （Binsec `-sse -checkct` 四次实跑、截断对照、锁频端到端统计）。
>
> 本文件的**原文一字未改**，包括当时的阻塞记录与降级说明，保留作为历史时点。
