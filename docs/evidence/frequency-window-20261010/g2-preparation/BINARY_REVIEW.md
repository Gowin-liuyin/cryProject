# G2 普通 worker 的产物入口与计时顺序

2026-10-10，指定裸金属以现有已核验 SSH 连接只读执行 `/usr/bin/objdump -d`
的 `--disassemble=main` 与 `--disassemble=run_workload`，目标均为
`Cry/window-source-c0e5990/build-normal/frequency_workload`。stdout 直接保存在本机，
没有执行该 ELF 或新增云端项目文件。两条命令均退出 0，之后远端 SHA-256 回读仍为
`023f56460a8dc4971e8132a22c5734ca0844314d3d71b8bc3b129a424e9ee69b`。
来源和本地四份 ELF 的完整核对见 [软件原件](../linux-c0e5990/README.md)。

[main 原反汇编](worker-main-disassembly.txt) 中，无参路径先在 0x132f 调用 prctl，
参数为 PR_SET_DUMPABLE（4）及 0；成功后在 0x13b1 调用 PR_GET_DUMPABLE（3）。
只有返回 0 且不是单独 safety-check 的路径，才在 0x13cf 跳转至 run_workload。
失败路径输出通用进程安全失败并返回，不进入工作负载。run_workload 的三个 calloc
位于 0x1f41、0x1f6d、0x1f8d；这支持实际产物中进程设置先于采集记录分配。

[run_workload 原反汇编](worker-run-disassembly.txt) 中，采集循环的
clock_gettime（0x2d9e）、完整 mlkem_decapsulate（0x2e01）和
clock_gettime（0x2e1a）按顺序保留。调用参数和记录消费位于其各自位置；未用
包装函数的自述替代对正式普通产物的检查。输入准备中的另一次解封装在 0x2c2b，
与采集循环分开，不把它计入逐次采集。

这是一份指定 ELF 的静态边界核对，不是编译器正确性证明、恒时证明或动态系统调用轨迹。
进入 C 前的加载器仍不在转储设置范围内；真实窗口、取消及恢复须由后续实际原件证明。
