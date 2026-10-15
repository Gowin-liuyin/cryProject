# BLOCKERS

记录本轮无法自行解决、按计划跳过或降级的项。格式：`编号 | 任务 | 现象 | 已尝试 | 影响的题面条款 | 建议`。

| 编号 | 任务 | 现象 | 已尝试 | 影响的题面条款 | 建议 |
|---|---|---|---|---|---|
| B01 | T25 | 同机网络场景（本地直调 / 回环 TCP / veth+netem 三档）**未执行** | 未开始（时间预算优先给 DoD 必做路径：T20/T23/T29a 采集、T21/T24 统计、T31 报告整合、T32 打包、T33 审计） | 第 9 条**可选**部分；第 10 条威胁模型的"远程边界"改为定性说明 | 需 netns/veth/netem 与 sudo，且要在 CPU2/CPU6 之外组织拓扑；建议下一轮单独排期。威胁模型章 C.6 与 D3 已按"未执行"写，并在稿末留了改法 |
| B02 | T15 | M5 重加密步骤的 Binsec `checkct` **仍为 unknown** | 三重阻塞实测：Binsec 0.11.3 无法解码 x86-64（`-isa amd64` 与默认 loader 都报 `Can not resolve decoder for x86-64`）；远端 clang 缺 32 位运行库；缺显式 `secret global` 时 checkct 在 0 路径也打印 secure（对 M4 已知脆弱内核假阴性）；32 字节消息路径数 2^256 | 第 5 条（M5 该格） | 需要新工程：i386 裸机驱动（`-ffreestanding -nostdlib`）+ 受约束域的显式 `secret global` 声明，并把"受约束模型 ≠ 完整步骤"写进结论。本轮按 unknown + 参数登记，未填"不存在" |
| B03 | T29b | Microwalk 官方镜像 `ghcr.io/microwalk-project/microwalk:pin` 未拉取/未运行 | 已实测 Docker 双重阻塞（`DockerRootDir` 越 Cry 边界 + 无 root 启 Cry 内 dockerd），ghcr 可达但层未下载 | 第 5 条的 Microwalk 行 | 已有替代：M3 用**源码自建** Microwalk 3.x + 自建 Pin 3.28 真跑通（互信息原件在案）。官方镜像可用性仍是阻塞 |
| B04 | T29b | ctgrind 上游补丁 `ca93f4f` 对 Valgrind 3.22 打不上 | 已改用发行版 memcheck 的 `VALGRIND_MAKE_MEM_UNDEFINED` 路线 | 第 5 条的 ctgrind 行 | 如要在原生环境复现上游补丁，需固定 Valgrind 3.25.1（既有 M1/M2 证据版本） |
| B05 | T05/T30 | 干净 clone 缺 `vendor/liboqs-0.10.0`、`vendor/kyber-kyberslash-*`、`third_party/`（均在 `.gitignore`） | quick 档已按"缺件即跳过并打印原因"处理，ctest 仍 194/194 通过 | 第 11 条的"一键复现" | 历史阳性对照与 M2 臂的复现需要先跑 `tools/fetch_liboqs_0.10.0.sh` 等取件脚本；已在 `REPRODUCE-PARAMS.md` 写明 |

## 未构成阻塞但需随结论一起读的事项

1. **M5 的 4 条"工具不适用型 unknown"**（解密/哈希/重加密/密文比较 × 可变时间比较）：
   该实现从上游起就用乘加/移位不用 `div`，varlat 在三模式 10 次完整解封装上 0 errors/0 contexts。
   这是"工具不适用"，不是"未检出泄漏"，R05 里未填成"不存在"。
2. **R06 发现项 F1（低危）**：`tools/platform_m2/collector.c` 在功能门失败时把
   `accept_mismatch_count` 汇总写进 stderr 与非 0 退出码；正常路径不触发（实测 rc 恒 0、stderr 恒空）。
   建议按 R06 §6 的修法处理，改后需重跑 R06 §2/§3。
3. **M3 的 1280 errors/2 contexts** 是人工夹具故意引入的秘密下标访存，不流向 syscall 参数。
4. **报告里仍标"未执行"的格**（如数据相关循环）是结构性未做项，不是占位符也不是阴性。
