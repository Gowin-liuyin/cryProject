# M3 工具探测与剩余范围

系统 Valgrind 3.22.0 已实际用于 Linux x86_64 poison 定位；这是标准 Memcheck 的秘密地址检查方法，不是本轮 KyberSlash varlat 补丁验证。`--ctgrind-probe` 只对公开固定人工输入做未定义标记，不输出输入或变换结果。

本机 Darwin arm64 的 `valgrind`、`pin`、`microwalk`、`dotnet` 命令未找到；`docker` 命令存在。nss-m 的 `valgrind`、`docker` 命令存在，`pin`、`microwalk`、`dotnet` 未找到；原始探测见 `native-idAExSCX/logs/environment.txt`。没有探测或启动 Docker daemon，没有下载 Pin、镜像或运行容器。

S2 固定的 [Microwalk](https://github.com/microwalk-project/Microwalk) 为 `7760a921353eae5837b3c0d52c9c7abc7f0c530a`。其 README 指定 .NET 8 和完整 Intel Pin SDK，PinTracer 面向 x86；仓库内 `docker/README.md` 仍留有旧 .NET 6 示例，应按固定 Dockerfile 再核验。没有 Pin SDK、可用 Microwalk 主程序和适配 wrapper，因此本轮轨迹定位阻塞，不能将 clone 成功写成可运行。上游 [ctgrind](https://github.com/agl/ctgrind) 的旧补丁也没有被冒充为本轮系统 Valgrind 的组成部分。

Docker 备选还必须先解决云端持久层、镜像、容器临时层及工作挂载都落在 Cry 物理边界的问题；默认 daemon 存储位置不满足当前项目约定。只存在 `docker` 命令不足以解除阻塞。

后续两步：主控先将本独立子目录纳入顶层 CMake/CTest；再根据 M2 主线进度冻结独立 M3 时序 PLAN，决定是否接入真实解封装路径和 Microwalk wrapper。本轮没有实现这两项，也没有统计阳性或阴性结论。开、关读取工作量差异大，跨版本总耗时差异不能用作秘密类对泄漏证据。
