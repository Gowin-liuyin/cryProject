# S3：固定空任务命令白名单修复

2026-10-16，修复基线为 `44c209a`。按主控回报，首次 `q-normal` 用 PLAN 指定的 `/usr/bin/true`，没有额外 `--qualification` 时被生产 collector 的 Cry 路径限制拒绝，发生在任何频率写入之前。旧失败根和已提交资格证据保持原字节；本目录只保存新修复的软件检查，不替换旧材料。

旧实现只在显式 `--qualification` 时选择系统命令，未以冻结运行名识别资格，并会直接替换已传入的命令。新实现只允许以下精确运行名/命令对，按名称推导资格模式；显式资格模式必须相符，显式命令必须逐参数相等，不忽略参数差异：

| 固定运行名 | 唯一系统命令 | 推导模式 |
|---|---|---|
| q-normal | `/usr/bin/true` | normal |
| q-failure | `/usr/bin/false` | failure |
| q-timeout | `/usr/bin/sleep 20` | timeout |
| q-controller-loss | `/usr/bin/sleep 20` | controller-loss |
| q-contention | `/usr/bin/true` | normal |

兼容固定运行名加匹配 `--qualification`、省略命令的既有调用；凡已传命令一律精确校验。其他运行名禁止 `--qualification`，继续强制 Cry 内可执行 collector 和原参数路径限制。校验在进入 root 管理函数前执行，拒绝测试不会打开控制锁、创建运行根或访问频率配置。

本机 macOS/ARM、Python3.13，独立 CMake/CTest **1/1通过**。检查保留原9组模拟，并增加6组资格允许、9组白名单拒绝、4个真实CLI拒绝进程、1组 Cry collector 允许模拟，以及解析 `q-controller-loss` 自动选择对应故障模式的 mock。真实 CLI 拒绝覆盖：错误 true/false、sleep参数变化、生产外部系统命令、未冻结资格名。没有执行系统空任务或生产 collector，没有 root/远端配置调用。

首次新增测试因期望错误字符串漏了 `Cry` 前的空格而失败，原日志保留为 `software-ctest-initial.log`；更正测试字串后检查通过。`software-ctest.log`、`software-ctest-verbose.log` 记录最终实际输出；`SOURCES.sha256` 固定本次源和测试，`source.patch` 保留相对基线的改动。

定位：资格命令路由已按冻结名称和精确参数修复。统计：没有采数或统计结果。边界：这些软件检查不能代替真实 Linux root 空任务恢复资格；主控应新提交本修复，再使用全新控制根重新执行已冻结资格矩阵，旧失败根保留。不修改 M1 vendor、旧证据、旧计划或结论；未 stage/commit/push，未关闭共享SSH。
