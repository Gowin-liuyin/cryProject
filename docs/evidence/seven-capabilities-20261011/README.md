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

Mac 到 `10.144.144.5:18012` 的直接连接没有完成。Ryzen 上该端口处于监听，本机 `nc` 退出码为 1。没有用隧道冒充这条路径。

正文在 `docs/research/seven-capabilities-20261011/CHAPTER.md`。协议在同目录的 `confirmation_protocol_v1.txt`。
