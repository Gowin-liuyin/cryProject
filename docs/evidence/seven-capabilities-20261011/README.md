# 七项能力实测记录（2026-10-11）

这些目录是新采集。已封存证据没有改字节。R02、R04 不因本目录而升级。

| 目录 | run_id | 内容 |
|---|---|---|
| `ryzen-positive/` | `ryzen-vulnerable`、`ryzen-hardened`、`ryzen-rollback` | Ryzen 9 9950X 上确认种子 `20261111`，6 个会话，每类 1000 次完整解封装。冻结协议未拒绝主比较。 |
| `apple-silicon/` | `apple-v`、`apple-h` | 同一确认种子和同一预算的 Apple Silicon 记录，与 Ryzen 分开分析。 |
| `ryzen-network/` | `network-jitter-low`、`network-jitter-mid`、`network-jitter-high` | Cry 内 veth 加 netem 的客户端 RTT。每档 80 个请求。 |
| `ryzen-matrix/` | `matrix-<变体>-<编译器>-<优化>` | 24 个普通格子的资格、链接行和每类 20 次基础计时。 |
| `trace-overhead/` | `overhead-plain` | 本机参考构建的无插桩、记账钩子、计时插桩三组。 |
| `ryzen-confirm-v2/` | `v2-vulnerable`、`v2-hardened`、`v2-rollback` | 计划起点 20×5000，确认种子 `8675309`。协议在采集前冻结。Holm 仍未拒绝。 |
| `ryzen-dev-window-90210/` | `dev-window-90210`、`dev-window-90210-message` | 开发种子 `90210` 的窗口核对。每类 200 次。消息多项式有了单独的排他行。Holm 确认记录不改。 |
| `ryzen-confirm-v3/` | `v3-vulnerable`、`v3-hardened`、`v3-rollback` | 种子 `31415926`，20×5000。vulnerable 的 Holm 拒绝。掩码不再拒绝。回滚没有恢复拒绝。 |
| `kat-v3-20261011/` | 同上三份已有二进制 | 公开 KAT 通过，含 5 条隐式拒绝。`session_collect` 摘要未变。 |
| `trace20-31415926/` | `v3-vulnerable` 的 20 次诊断 | 重加密与 message 包装进入 Top-3 均为 20/20。`single_root_cause=not_asserted`。 |
| `rollback-retry-31415926/` | `v3-rollback-retry` | 新构建，同一协议。主效应 −3.682，p=0.0436，Holm 不拒绝。旧 p=0.026 不改。 |
| `mac-ryzen-direct-20261011/` | `mac-direct-20261011` | Mac 直接连接没有数据行。2730 个端口探测没有空闲可达端口。 |
| `matrix-sessions-20261011/` | `matrix-session-<格子>` | 开发种子 `31337`。外层 O2 为 20×5000，其余为 5×5000。描述性会话效应，`frozen_per_cell_test=no`。 |

Mac 到 `10.144.144.5:18012` 的直接连接没有完成。2026-10-11 对 `18021` 的再次直连也没有 RTT 数据行。没有用隧道冒充这条路径。

正文在 `docs/research/seven-capabilities-20261011/CHAPTER.md`。协议在同目录的 `confirmation_protocol_v1.txt`。
