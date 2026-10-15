# M3 工具与解释边界

本轮已实现真实 ML-KEM 完整解封装路径的**人工**秘密访存夹具，不再用独立替换函数冒充
完整解封装接线。旧 `fixtures/mem_lut_leak` 与已提交证据保持原状。

补丁的 on/off 都替换为相同公开系数循环，只切换消息位的系数选择方式：
on 直接秘密索引 64 字节间隔的只读 volatile 表，off 采用上游值屏障/选择。没有空转；
表值就是本次重加密实际写入的 0 或 1665。原重加密验证与隐式拒绝保留。
`volatile` 不是恒时防护，而是防止这个人工机制被编译器消去。

原生 Memcheck 以未定义标记表示秘密：私钥前 1152 字节及最后 32 字节被标记，
嵌入公钥/公开哈希保持 defined。1280 是五次完整调用各 256 个消息位选择的总报警数，
两个 context 来自编译器在重加密调用者内展开的两个 load PC，不是两处独立上游漏洞。
运行 PC `0x10DCED/0x10DD15` 对应同 PIE 的静态偏移 `0x5CED/0x5D15`，
`addr2line` 与反汇编共同确认 `compress.c:714`，上层为 `indcpa.c:544`、`kem.c:443`。

这次报警是内存地址使用秘密标记，不是内存未初始化缺陷，不是 varlat，也不是物理时延采样。
off 的五次秘密标记调用与两版 defined 对照均 0/0，仅限该产物、标记模型和五类输入，
不能证明整库对所有输入/微架构恒时。

## Microwalk 按计划降级

本轮真实探测 `pin`、`dotnet`、`microwalk` 均未找到；Docker 存在，但
只读 `docker info` 返回 `DockerRootDir=/home/docker-data`，不在 Cry 物理边界内。
因此没有拉取镜像、创建容器、下载 Pin SDK 或运行 Microwalk；没有尝试把外部 Docker
持久层当作“临时文件”例外。原始输出见 `native-8b6f2d91/environment.log`。

按平台计划的无 Pin 降级路线，本轮采用标准 Memcheck 秘密地址定位及同 ELF 反汇编。
Microwalk 轨迹/量化仍为环境阻塞，没有将已克隆源码或 Docker 命令存在写成工具已运行。

## 补丁格式回归

主控在本路编辑中的一次中间版本遇到 malformed patch；该失败构建由主控保留，没有就地覆盖。
补丁重新从原 vendor 与完整替换函数自动生成后，在新 overlay 实际应用成功；新增独立
`platform_m3_patch_dry_run` CTest 使用 `patch --dry-run --fuzz=0`，本机和原生均通过。
普通/动态新构建都实际应用两版补丁；未以手写 hunk 计数代替资格验证。
