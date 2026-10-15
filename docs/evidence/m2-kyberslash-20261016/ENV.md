# M2 实际环境

日期：2026-10-16（用户时区 Asia/Shanghai）；原日志 UTC 时间戳保持原样。

| 项 | 本轮实际值 |
|---|---|
| 开发环境 | `/Users/yin/code/cryProject`，macOS/ARM；交叉探索不作为 Linux 执行证据 |
| 原生主机 | 已核验的 `nss-marker@10.144.144.5`，主机名 nss-m，AMD Ryzen 9 9950X，x86_64 |
| 内核 | Linux 6.17.0-35-generic，完整输出见 version-audit/environment.txt |
| 编译 | Ubuntu Clang 18.1.3，CMake 3.28.3，`KYBER_K=3`，`-Oz -g -fno-vectorize -fno-slp-vectorize`，无 LTO |
| 源身份 | 两份完整上游 commit、tree、归档摘要及清单见 VERSION_AUDIT.md 和目录外 PIN |
| 自有探针 | version-audit/poly_probe.c；执行时未提交，原包及清单保留精确字节，不能倒写成已提交执行 |
| 动态工具 | Valgrind 3.25.1，tag 解引用 commit `4441567fbec8c263e1624b49ba86572d4cccfccd`，两份原始 20250805 补丁 |
| 工具根 | `/home/nss-marker/yhr/Cry/platform-s3-20261016-cc79de28-2da` |
| 探针根 | `/home/nss-marker/yhr/Cry/platform-s4-20261016-7824` |
| ELF/源/日志摘要 | version-audit/SHA256SUMS、upstream-*-manifest.tsv、VERSION_AUDIT.md；工具摘要见 varlat-tool/ |
| 临时与缓存 | 各自 Cry 新物理子树，保留路径审查与环境；无 Cry 外项目工作目录 |
| 时钟、单位、类对、采样预算 | 不适用，未执行硬件计时 |
| 调频、boost、亲和性、隔离写入 | 本轮均无；不是锁频运行，不填 restore_match=yes |
| 密钥恢复 | 未执行；无真实秘密输出 |

首次密钥认证失败后由用户提供可用认证方式，经实际密码提示建立共享 SSH；
口令不写入仓库、脚本或证据。主控在各路结束后统一关闭共享通道，结束状态另记平台交接。
原包和原工具安装树保留，既有证据不覆盖。
