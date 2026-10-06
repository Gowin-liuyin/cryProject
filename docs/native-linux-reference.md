# 原生 x86_64 Linux 参考验收准备包

状态：**准备完成、尚未执行**。本轮没有用户提供且可访问的原生x86_64 Linux入口，
没有扫描网络、猜主机或创建远程资源。macOS本地结果与既有QEMU记录不填补这个缺口。

依赖：CMake ≥3.21、GNU GCC或Clang、Make（默认生成器）、Git、patch、POSIX sh、awk、
sed、Perl/shasum、OpenSSL（支持SHA3-256）、GNU objdump/binutils、file。
通常Linux开发工具包已带大部分依赖；例如Debian/Ubuntu可由管理员按需安装
`build-essential cmake git patch perl openssl binutils file`。脚本不安装工具、不下载库。

从含新入口的**完整固定提交**准备源码；提交对照见验收记录。本轮已找回先前直接邮箱
确认，按模块提交，但不得拿起始 `a07bbc1` 当作包含新增入口的源码。输出目录必须新建、其父目录已存在。
先由环境提供者写一份 `execution-note.txt`：真实宿主型号/架构、是否裸机、VM或容器、
宿主架构、虚拟化产品、是否使用QEMU用户态/系统仿真或架构翻译、可配置的亲和性及频率。
VM运行原生x86指令与QEMU模拟不能混称；若缺乏宿主确认，结果仍不能标成目标基线。

```sh
source_commit=$(git rev-parse HEAD)
NATIVE_X86_64_LINUX_CONFIRMED=yes sh tools/run_native_reference.sh \
    "$source_commit" /absolute/new-output-directory /absolute/execution-note.txt
```

`yes` 代表环境提供者已经核实执行方式，不是脚本检测出的事实。
脚本同时要求Linux/x86_64、HEAD精确匹配、构建与测试输入无未提交/未跟踪变动；
`.agents/` 不作为构建输入也不读取。新目录内的两套CMake构建隔离，参考功能5项和
普通入口/离线诊断2项分别执行。ASan/UBSan测试采集仅验证接口，正式三次性能记录只用
RelWithDebInfo且sanitizers=OFF产物，固定三类1:1:1、每类1000、每次预热100。

日志保留每步参数、开始UTC时间、退出码；任何步骤失败立刻传播非零并写partial状态。
保留失败输出，不能拿部分CSV进汇总。成功需核对 `status.txt`、全部step-exits、各meta的
complete与源码/产物摘要，再检查源CSV及总结中的摘要。空窗口和读钟原始值位于meta，
不扣开销。亲和性、频率及后台负载脚本默认不配置，有外部控制时在执行说明中如实记下。

`uname`只是一项环境记录：另存CPU、lscpu、虚拟化检测、binfmt状态及环境提供者说明。
反汇编保存实际正式产物全文，执行后仍需人工核对计时窗口内的完整解封装调用及输出消费。
脚本只计算普通负载描述值，不运行漏洞复现、其他变体计时或两轮历史显著性检验。

本机已经检查POSIX脚本语法和macOS拒绝路径（返回2、未创建目标输出），并实际执行过
相同CMake目标与普通负载流程。Linux平台分支、GNU反汇编、/proc宿主识别和真实性能
仍待执行；这些边界不能因为准备包存在而改成“跨平台实测完成”。
