# 24 格的会话规模描述性计时

远端目录 `/home/nss-marker/yhr/Cry/seven-capabilities-20261011/matrix-sessions-20261011/`。复用 `run-matrix` 里已经合格的 `session_collect`，没有重编。二进制 SHA-256 与 `ryzen-matrix/*.manifest` 的 `binary_sha256` 一致。主机 `nss-m`，`taskset -c 2`。种子是开发种子 `31337`。无插桩，sanitizer 关闭。

八个外层 O2 格是 20 个会话、每类 5000 次。其余 16 格是 5 个会话、每类 5000 次。五类是 valid、bit-flipped、random、message-zero、message-ones。O0 编译行含 `-O0`，没有另一个 `-O2`。O2+LTO 链接行含 `-flto`。vulnerable 与 hardened 仍是外层 O2 加既有函数级约束，不是对目标函数的 O3 测试。

`matrix-sessions.txt` 给出逐格主效应。各格 `decision.txt` 是开发阶段分析器的原样输出，`phase=development`，`frozen_per_cell_test=no`。`matrix-session-vulnerable-gcc-O2` 的分析器行是 `holm_rejected_primary=yes`，p 为 `4.0590131124768774e-05`。`matrix-session-vulnerable-clang-O2` 也是 yes，p 为 `0.001259532563931612`。采集前没有按格冻结检验。不能由这些描述性效应宣布某一优化级防护成立或失效。

旧的每类 20 次基础文件仍在远端 `run-matrix/` 和仓库 `ryzen-matrix/`。合并后的大 CSV 留在远端。`iid_upgrade=refused`，`constant_time_upgrade=refused`。R02、R04 不因此升级。
