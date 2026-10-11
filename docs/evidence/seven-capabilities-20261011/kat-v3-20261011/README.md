# 三份 v3 二进制的公开 KAT

在 `nss-m` 上用仓库 `tests/test_mlkem.c` 链接采集时已经存在的 `libmlkem.a`。没有重编内核，也没有重链三份 `session_collect`。向量文件是远端 `window-source-90210/tests/vectors/mlkem768.txt`。2026-10-11T14:40:04Z 复跑三次，`kat_exit=0`。日志是 `kat-rerun.log`。驱动打印的名字来自所链库，所以 rollback 那一次打印 `vulnerable:`。

| 角色 | session_collect SHA-256 | SHA3-256 | 与 v3 s01 元数据 |
|---|---|---|---|
| `v3-vulnerable` | `bd5d432b29e740414bd422790cca362e288959c07cfd5880c1110baf492fe685` | `8b33e51b7eb79fabd464b81e1d96ded95699c8903c71f310527f04f101ad0118` | 一致 |
| `v3-hardened` | `09178f475e84f5a460068d023cb39f9343143565b33745057c20cd668e123a24` | `f0e2eab723e35e8df93fb95dbc06018f4bcdc3230d386da4d5c6c927b074fc91` | 一致 |
| `v3-rollback` | `c129978ef7525ae0bed9bb3d42e2c7da7a33ec5c58180524bc7c138e788b7e4d` | `2aa7439a26124313f772f047fd38f0c391a750ab38646d532fb6367ca5da473e` | 一致 |

每份日志都有 `5 implicit rejections, 5 accepted ciphertexts`，以及 `NIST FIPS203 KAT 25 keygen + 25 encaps + 10 decaps passed`。运行前后 `session_collect` 的 SHA-256 相同，见同目录的 `*.before.sha256` 与 `*.after.sha256`。

远端目录是 `/home/nss-marker/yhr/Cry/seven-capabilities-20261011/kat-v3-20261011/`。`iid_upgrade=refused`，`constant_time_upgrade=refused`。R02、R04 不因此升级。
