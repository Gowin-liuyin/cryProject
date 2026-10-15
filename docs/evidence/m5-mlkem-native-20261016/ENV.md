# M5 环境记录与 nss-marker 草案

## 本轮实际环境

- 日期：2026-10-16（Asia/Shanghai）。实际执行主机为 `yindeMacBook-Air.local`，Darwin 25.6.0、
  arm64，Apple Clang 21.0.0 (`clang-2100.3.34.2`)、CMake 4.3.2、Unix Makefiles。
- 仓库：`/Users/yin/code/cryProject`，分支 main。功能初次构建嵌入的源提交为
  `4a3a4ab97d76f3317d68e64570a0c14318329a5b`，含并行任务产生的未跟踪文件；
  它不是干净封存构建。完整当时身份和输入摘要分别保存在普通/动态 identity 文本中。
- 普通构建：`build/platform-s6/ordinary`，RelWithDebInfo、C11、`-O2 -g -DNDEBUG`、无 LTO、
  sanitizer 关闭；`A113_ARCHIVED_CASE_ONLY=OFF` 只用于编出已有 measure，未执行采数。
- 动态构建：`build/platform-s6/sanitize`，Debug、ASan/UBSan、`-O1 -g -fno-omit-frame-pointer`；
  其运行结果只用于功能资格。
- 本次普通/动态参考资格各 5/5 通过；普通系统随机源往返通过。准确配置、编译与链接日志在本目录。
- 主控接线后增加 `BASELINE_ENABLE_PLATFORM=ON`，三聚合目标 `platform_m5`、`platform_m5_measure`、
  `platform_m5_check` 全部通过，check 再次通过 5/5；重链产物身份与摘要另存 `platform-*`，
  不覆盖初次普通/动态身份和摘要。
- 没有 SSH、root、MSR、taskset、频率或 boost 操作；未创建 raw 时间 CSV，没有统计假设检验。
- 初次构建身份读取时，其他并行新 vendor 的 `avx2/.gitignore` 自循环链接产生 Git 警告，
  原始日志保留。M5 126 文件核验不含该 vendor，功能资格均通过；上传前由其所有者核查。

## nss-marker 下一阶段待填

| 字段 | 当前值 |
|---|---|
| 机器与路径 | 预定 `nss-marker@10.144.144.5`；实际项目物理根必须在 `/home/nss-marker/yhr/Cry/` |
| OS/内核/CPU/微码 | 待本次实际预检；不沿用历史值冒充当前值 |
| 固定源提交、未提交摘要 | 待主控提交接线并冻结 |
| 编译器/选项/ELF 摘要/反汇编 | 待原生构建与资格；macOS Mach-O 不代替 ELF |
| 普通/动态分树 | 待在新 Cry 子树部署；临时、缓存、输入、日志、输出均不得越界 |
| 锁频与恢复 | 待主控独占调度；boost 关、performance、约 4.30 GHz、taskset，进出 restore_match，退出恢复 |
| 类对、样本量、种子/顺序、假设族 | 待新 M5 PLAN 冻结与提交；dudect 不进 Holm |
| ctgrind/varlat/统计电池 | 本轮均未运行；不得写成阴性或恒时结论 |

本记录只支持本机接线与功能通过，不支持真实 x86_64 时序、定位、统计阴性或恒时证明。
