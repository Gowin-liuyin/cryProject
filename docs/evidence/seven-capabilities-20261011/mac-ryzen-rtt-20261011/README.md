# Mac 到 10.144.144.5:18080 的直接 TCP RTT

2026-10-11 从这台 Mac 的现有 `build/cmake/network_client` 直接连接 `nss-m` 上的现有 `build-positive/network_server`。路径是 TCP 到 `10.144.144.5:18080`，没有使用 SSH 隧道，也没有给本地 CSV 加噪声。

连接前该端口没有监听，Mac 探测得到的是连接被拒绝。主机 ufw 里已有 `18080/tcp ALLOW IN Anywhere`，这次没有新增或删除防火墙规则。服务端在两次请求完成后退出，结束后端口不再监听。

种子 `90210`。客户端时钟是 `CLOCK_MONOTONIC`，`elapsed_clock_counts` 的单位是该时钟的纳秒计数。应答是 32 字节固定确认，前缀 `A113ACK`，其余为 0。

| run_id | 客户端行数 | 应答字节 | 服务端 |
|---|---:|---:|---|
| `mac-ryzen-18080` | 80 | 2560 | `completed_decapsulations=80` |
| `mac-ryzen-18080-one` | 1 | 32 | `completed_decapsulations=1` |

80 行的原始均值是 30189475 个纳秒计数。单次应答的计数是 26393000。这些 RTT 不用于宣布远程检出或不存在远程泄露。
