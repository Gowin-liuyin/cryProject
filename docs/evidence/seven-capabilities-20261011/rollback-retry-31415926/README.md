# 协议 v3 的第二次 vulnerable 回滚

新目录 `/home/nss-marker/yhr/Cry/seven-capabilities-20261011/run-rollback-retry-31415926/`，构建在同级 `build-v3-rollback-retry/`。没有覆盖 `run-confirm-31415926`，也没有重分析旧的 `v3-rollback`。

协议副本 SHA-256 是 `77e81746aa0f7c8768c71edd053ff2648f2cf68c46465708e75ddef1a7d0df2a`，见 `protocol.sha256`。`session_budget=20`，`sample_budget_per_class=5000`，种子 `31415926`，`taskset -c 2`。GCC 13.3.0，RelWithDebInfo，sanitizer 关闭。新 `session_collect` 的 SHA-256 是 `62ee2397863aef01792854e1298475579388cc7c5d32eefd499e774c2aef4e8a`，SHA3-256 是 `76054244cf14e7ad173806b65c83aa324a593cba6ed309013ece6ae7d72d6b4c`，与 `s01.meta` 一致。合并表 500001 行留在远端。

分析器原样输出在 `rollback-decision.txt`。主效应 −3.68244，t 为 −2.161，p 为 0.04363，`holm_rejected_primary=no`。Wald 区间是 −7.022 到 −0.343。没有为了拒绝而改 α、种子或分支。

旧 `v3-rollback` 仍是主效应 −2.976，p=0.026，Holm 不拒绝，决策文件 SHA-256 仍是 `44b8b21a5cce1f626eb8f2dfca1366a4683d0883865644993f3726d4edd0ea72`。两次回滚都没有恢复 Holm 拒绝。`iid_upgrade=refused`，`constant_time_upgrade=refused`。R02、R04 不因此升级。
