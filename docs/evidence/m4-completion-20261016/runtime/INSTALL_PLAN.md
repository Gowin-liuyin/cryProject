# M4 Binsec 原生运行环境安装合同

本路仅安装并探测工具，不运行时序采样、不写频率或隔离配置，不执行密钥恢复或 exploit。
本机为 macOS/ARM；实际工具探测在 `nss-marker@10.144.144.5` 的 x86_64 Linux 执行。

- 唯一远端根：`/home/nss-marker/yhr/Cry/platform-m4-20261016-6hRHRUxH`。
- 本路独占 `runtime/`、`runtime-logs/`、`download/`、`opam/`、`tmp/`、`cache/`、`curl/`；所有实际路径须在该根内。
- 构建与探测固定 CPU0/1，最多两个构建任务；不占 CPU2/6，不关闭共享 SSH socket。
- 保留原 `HOME`，显式设置 `OPAMROOT`、`XDG_CACHE_HOME`、`CURL_HOME`、`TMPDIR/TMP/TEMP`；opam 不修改用户 shell、不使用系统包安装。
- 优先官方 Linux 发行件；Binsec 0.11.3 的唯一人工上传发行件为源码 tbz，故使用本根隔离 opam 构建。
- 固定 Binsec tag `0.11.3`、完整 commit `9749bd8aed7ee0a27959158b1e53e8789cb0e5ab`，保留上游 `LICENSE.md`。
- 工具成功标准为实际 `binsec -version`、`binsec -help`、`z3 --version`，记录 ELF 摘要、依赖清单、归档摘要及完整日志。
- 工具安装成功不等于夹具验证成功；有界 secure/insecure、完整路径覆盖和超时由主路单独审计。

本路不改 `vendor/liboqs-0.10.0`、已封存证据、`sources/` 或同伴文件；不 stage、commit、push。
